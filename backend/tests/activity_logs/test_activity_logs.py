from tests.conftest import TEST_USER_ID
import uuid
from datetime import datetime, timezone, timedelta
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.activity_logs.activity_log import ActivityLog, ActorType, EntityType, ActionType
from app.models.todo.todo import Todo, TodoStatus
from app.models.academic.semester import Semester
from app.services.activity_logs.logger import log_activity
from app.services.activity_logs.summary import get_activity_entity_summary, bulk_populate_activity_summaries
from app.repositories.activity_logs.activity_log import ActivityLogRepository


@pytest.mark.asyncio
async def test_log_activity_success(db_session: AsyncSession):
    # Log a valid activity
    entity_id = uuid.uuid4()
    log = await log_activity(
        db=db_session,
        actor_type=ActorType.USER,
        entity_type=EntityType.TODO,
        entity_id=entity_id,
        action_type=ActionType.CREATED,
        activity_message="Test message",
        correlation_id=uuid.uuid4()
    )
    assert log is not None
    assert log.activity_id is not None
    assert log.actor_type == ActorType.USER
    assert log.activity_message == "Test message"


@pytest.mark.asyncio
async def test_log_activity_best_effort_isolation(db_session: AsyncSession):
    # Test that logging failure does not roll back the parent transaction.
    # We first create a Semester in the parent transaction.
    semester = Semester(
        user_id=TEST_USER_ID,
        semester_number=1,
        start_date=datetime.now().date(),
        end_date=(datetime.now() + timedelta(days=90)).date()
    )
    db_session.add(semester)
    await db_session.flush()

    # Attempt to log an invalid activity (e.g. violating nullable constraint on actor_type by passing None)
    # Wait, log_activity takes ActorType. If we pass None (or bypass type checker via casting),
    # it will trigger a database error.
    log = await log_activity(
        db=db_session,
        actor_type=None,  # Invalid to trigger DB error
        entity_type=EntityType.TODO,
        entity_id=uuid.uuid4(),
        action_type=ActionType.CREATED,
        activity_message="This should fail"
    )
    assert log is None  # Fails gracefully and returns None

    # Verify that the parent transaction was NOT rolled back and the semester is still there
    stmt = select(Semester).where(Semester.semester_id == semester.semester_id)
    result = await db_session.execute(stmt)
    fetched_semester = result.scalar_one_or_none()
    assert fetched_semester is not None
    assert fetched_semester.semester_number == 1


@pytest.mark.asyncio
async def test_get_activity_entity_summary_todo(db_session: AsyncSession):
    # Create a Todo item
    todo = Todo(
        user_id=TEST_USER_ID,
        title="Check activity log summary",
        status=TodoStatus.PENDING
    )
    db_session.add(todo)
    await db_session.flush()

    summary = await get_activity_entity_summary(
        db=db_session,
        entity_type=EntityType.TODO,
        entity_id=todo.todo_id
    )
    assert summary == "Check activity log summary"


@pytest.mark.asyncio
async def test_api_list_activity_logs(client: AsyncClient, db_session: AsyncSession):
    # Seed a couple of logs
    correlation_id = uuid.uuid4()
    todo_id = uuid.uuid4()

    # Log 1
    await log_activity(
        db=db_session,
        actor_type=ActorType.USER,
        entity_type=EntityType.TODO,
        entity_id=todo_id,
        action_type=ActionType.CREATED,
        activity_message="First Log Message",
        correlation_id=correlation_id
    )

    # Log 2
    await log_activity(
        db=db_session,
        actor_type=ActorType.SYSTEM,
        entity_type=EntityType.SETTINGS,
        entity_id=uuid.uuid4(),
        action_type=ActionType.UPDATED,
        activity_message="Second Log Message"
    )
    await db_session.commit()

    # Query API list all
    response = await client.get("/api/v1/activity-logs")
    assert response.status_code == 200
    res_json = response.json()
    assert res_json["success"] is True
    data = res_json["data"]
    assert len(data) >= 2

    # Query API with filter by actor_type
    response = await client.get("/api/v1/activity-logs?actor_type=system")
    assert response.status_code == 200
    res_json = response.json()
    assert res_json["success"] is True
    data = res_json["data"]
    assert all(item["actor_type"] == "system" for item in data)

    # Query API with filter by correlation_id
    response = await client.get(f"/api/v1/activity-logs?correlation_id={correlation_id}")
    assert response.status_code == 200
    res_json = response.json()
    assert res_json["success"] is True
    data = res_json["data"]
    assert len(data) == 1
    assert data[0]["activity_message"] == "First Log Message"

    # Query API search q
    response = await client.get("/api/v1/activity-logs?q=second")
    assert response.status_code == 200
    res_json = response.json()
    assert res_json["success"] is True
    data = res_json["data"]
    assert len(data) == 1
    assert data[0]["activity_message"] == "Second Log Message"


@pytest.mark.asyncio
async def test_api_get_activity_log_by_id(client: AsyncClient, db_session: AsyncSession):
    # Log one entry
    log = await log_activity(
        db=db_session,
        actor_type=ActorType.BOT,
        entity_type=EntityType.SETTINGS,
        entity_id=uuid.uuid4(),
        action_type=ActionType.UPDATED,
        activity_message="API Details Log"
    )
    await db_session.commit()

    # Get by ID
    response = await client.get(f"/api/v1/activity-logs/{log.activity_id}")
    assert response.status_code == 200
    res_json = response.json()
    assert res_json["success"] is True
    data = res_json["data"]
    assert data["activity_id"] == str(log.activity_id)
    assert data["actor_type"] == "bot"
    assert data["activity_message"] == "API Details Log"
    assert data["entity_summary"] == "App Settings"


@pytest.mark.asyncio
async def test_bulk_populate_activity_summaries(db_session: AsyncSession):
    # 1. Create a Todo
    todo = Todo(
        user_id=TEST_USER_ID,
        title="Todo Task for bulk log test",
        status=TodoStatus.PENDING
    )
    db_session.add(todo)
    await db_session.flush()

    # 2. Create some ActivityLog mock objects (not committed to DB, just in memory)
    log_todo = ActivityLog(
        actor_type=ActorType.USER,
        entity_type=EntityType.TODO,
        entity_id=todo.todo_id,
        action_type=ActionType.CREATED,
        activity_message="Created todo"
    )
    log_settings = ActivityLog(
        actor_type=ActorType.SYSTEM,
        entity_type=EntityType.SETTINGS,
        entity_id=uuid.uuid4(),
        action_type=ActionType.UPDATED,
        activity_message="Updated settings"
    )
    log_finance = ActivityLog(
        actor_type=ActorType.USER,
        entity_type=EntityType.FINANCE,
        entity_id=uuid.uuid4(),
        action_type=ActionType.CREATED,
        activity_message="Finance log"
    )

    logs = [log_todo, log_settings, log_finance]

    # Verify summaries are not yet set
    for l in logs:
        assert not hasattr(l, "entity_summary")

    # Run bulk populate
    await bulk_populate_activity_summaries(db_session, logs)

    # Verify summaries are populated correctly
    assert log_todo.entity_summary == "Todo Task for bulk log test"
    assert log_settings.entity_summary == "App Settings"
    assert log_finance.entity_summary == "Finance Record"

