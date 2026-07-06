import pytest
import pytest_asyncio
import uuid
from datetime import date, time, datetime, timezone, timedelta
from httpx import AsyncClient
from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus, MarkedBy
from app.models.academic.attendance_settings import AttendanceSettings, CriteriaMode
from app.models.todo.todo import Todo, TodoCategory, TodoPriority, TodoStatus, TodoCreatedBy
from app.models.review_queue.review_queue import ReviewQueue, ReviewType, EntityType, ReviewStatus, ResolvedBy
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.todo.todo import TodoRepository
from app.repositories.review_queue.review_queue import ReviewQueueRepository
from app.services.review_queue.review_queue import ReviewQueueService
from app.services.review_queue.resolvers import RESOLVERS, TodoResolver, LectureInstanceResolver, FinanceResolver
from app.core.exceptions import NotFoundException, ValidationException


# ===========================================================================
# Fixtures
# ===========================================================================

@pytest_asyncio.fixture(scope="function")
async def test_semester(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session)
    sem = Semester(
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 1, 31)
    )
    created = await semester_repo.create(sem)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_subject(db_session: AsyncSession, test_semester: Semester) -> Subject:
    subject_repo = SubjectRepository(db_session)
    sub = Subject(
        semester_id=test_semester.semester_id,
        subject_name="Operating Systems",
        faculty_name="Prof. Bob",
        theme_color="#00FF00",
        attendance_goal=75
    )
    created = await subject_repo.create(sub)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_template(db_session: AsyncSession, test_subject: Subject) -> LectureTemplate:
    template_repo = LectureTemplateRepository(db_session)
    temp = LectureTemplate(
        subject_id=test_subject.subject_id,
        day_of_week=2,  # Tuesday
        start_time=time(10, 0),
        end_time=time(11, 0),
        room="LH-102"
    )
    created = await template_repo.create(temp)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_lecture_instance(db_session: AsyncSession, test_template: LectureTemplate) -> LectureInstance:
    repo = LectureInstanceRepository(db_session)
    inst = LectureInstance(
        lecture_template_id=test_template.lecture_template_id,
        lecture_date=date(2026, 1, 6),  # Tuesday
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED,
        marked_by=None,
        marked_at=None
    )
    created = (await repo.create_all([inst]))[0]
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_todo(db_session: AsyncSession) -> Todo:
    repo = TodoRepository(db_session)
    todo = Todo(
        title="Study Virtual Memory",
        category=TodoCategory.ACADEMIC,
        priority=TodoPriority.HIGH,
        status=TodoStatus.PENDING,
        created_by=TodoCreatedBy.USER,
        due_datetime=datetime(2026, 1, 15, 12, 0, 0, tzinfo=timezone.utc),
        completed_at=None
    )
    created = await repo.create(todo)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def review_queue_service(db_session: AsyncSession) -> ReviewQueueService:
    return ReviewQueueService(
        db=db_session,
        review_queue_repo=ReviewQueueRepository(db_session)
    )


def make_review(entity_type: EntityType, entity_id: uuid.UUID, message: str, **kwargs) -> ReviewQueue:
    defaults = dict(
        review_type=ReviewType.MISSING_INFORMATION,
        entity_type=entity_type,
        entity_id=entity_id,
        review_message=message,
        review_status=ReviewStatus.PENDING,
        resolved_by=ResolvedBy.USER,
        created_at=datetime.utcnow(),
    )
    defaults.update(kwargs)
    return ReviewQueue(**defaults)


# ===========================================================================
# 1. Resolver Dispatch Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_resolver_registry_has_all_types():
    assert EntityType.TODO in RESOLVERS
    assert EntityType.ATTENDANCE in RESOLVERS
    assert EntityType.FINANCE in RESOLVERS
    assert RESOLVERS[EntityType.TODO] is TodoResolver
    assert RESOLVERS[EntityType.ATTENDANCE] is LectureInstanceResolver
    assert RESOLVERS[EntityType.FINANCE] is FinanceResolver


@pytest.mark.asyncio
async def test_todo_resolver_get_summary(db_session: AsyncSession, test_todo: Todo):
    resolver = TodoResolver(db_session)
    summary = await resolver.get_summary(test_todo.todo_id)
    assert summary == "Study Virtual Memory"


@pytest.mark.asyncio
async def test_todo_resolver_get_summary_unknown(db_session: AsyncSession):
    resolver = TodoResolver(db_session)
    summary = await resolver.get_summary(uuid.uuid4())
    assert summary == "Unknown Todo"


@pytest.mark.asyncio
async def test_lecture_instance_resolver_get_summary(
    db_session: AsyncSession, test_lecture_instance: LectureInstance
):
    resolver = LectureInstanceResolver(db_session)
    summary = await resolver.get_summary(test_lecture_instance.lecture_instance_id)
    # Should be: "Operating Systems • Tuesday • 10:00"
    assert "Operating Systems" in summary
    assert "Tuesday" in summary
    assert "10:00" in summary


@pytest.mark.asyncio
async def test_lecture_instance_resolver_get_summary_unknown(db_session: AsyncSession):
    resolver = LectureInstanceResolver(db_session)
    summary = await resolver.get_summary(uuid.uuid4())
    assert summary == "Unknown Lecture"


@pytest.mark.asyncio
async def test_finance_resolver_get_summary(db_session: AsyncSession):
    resolver = FinanceResolver(db_session)
    summary = await resolver.get_summary(uuid.uuid4())
    assert summary == "Finance Record"


# ===========================================================================
# 2. Resolver Resolution Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_todo_resolver_resolve_success(db_session: AsyncSession, test_todo: Todo):
    resolver = TodoResolver(db_session)
    await resolver.resolve(test_todo.todo_id, {
        "title": "Study Virtual Memory (Updated)",
        "status": "completed"
    })
    todo_repo = TodoRepository(db_session)
    todo = await todo_repo.get_by_id(test_todo.todo_id)
    assert todo.title == "Study Virtual Memory (Updated)"
    assert todo.status == TodoStatus.COMPLETED
    assert todo.completed_at is not None


@pytest.mark.asyncio
async def test_todo_resolver_resolve_not_found(db_session: AsyncSession):
    resolver = TodoResolver(db_session)
    with pytest.raises(NotFoundException):
        await resolver.resolve(uuid.uuid4(), {"title": "Ghost"})


@pytest.mark.asyncio
async def test_todo_resolver_resolve_malformed_data(db_session: AsyncSession, test_todo: Todo):
    """Resolution data with an invalid field value should raise ValidationException."""
    resolver = TodoResolver(db_session)
    with pytest.raises(ValidationException) as exc:
        await resolver.resolve(test_todo.todo_id, {"priority": "ultra"})  # invalid enum value
    assert "Invalid resolution data" in str(exc.value)


@pytest.mark.asyncio
async def test_lecture_instance_resolver_resolve_success(
    db_session: AsyncSession, test_lecture_instance: LectureInstance
):
    resolver = LectureInstanceResolver(db_session)
    await resolver.resolve(test_lecture_instance.lecture_instance_id, {
        "attendance_status": "present"
    })
    li_repo = LectureInstanceRepository(db_session)
    inst = await li_repo.get_by_id(test_lecture_instance.lecture_instance_id)
    assert inst.attendance_status == AttendanceStatus.PRESENT
    assert inst.marked_by == MarkedBy.USER


@pytest.mark.asyncio
async def test_lecture_instance_resolver_rejects_present_on_cancelled(
    db_session: AsyncSession, test_lecture_instance: LectureInstance
):
    test_lecture_instance.lecture_status = LectureStatus.CANCELLED
    await LectureInstanceRepository(db_session).update(test_lecture_instance)
    await db_session.flush()

    resolver = LectureInstanceResolver(db_session)
    with pytest.raises(ValidationException):
        await resolver.resolve(test_lecture_instance.lecture_instance_id, {"attendance_status": "present"})


# ===========================================================================
# 3. Service — entity_summary Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_get_item_returns_entity_summary(
    db_session: AsyncSession, review_queue_service: ReviewQueueService, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Missing todo category")
    await repo.create(r)
    await db_session.flush()

    item = await review_queue_service.get_item(r.review_id)
    assert hasattr(item, "entity_summary")
    assert item.entity_summary == "Study Virtual Memory"


@pytest.mark.asyncio
async def test_list_items_returns_entity_summary(
    db_session: AsyncSession, review_queue_service: ReviewQueueService, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Check this")
    await repo.create(r)
    await db_session.flush()

    items = await review_queue_service.list_items()
    assert len(items) >= 1
    for item in items:
        assert hasattr(item, "entity_summary")
        assert isinstance(item.entity_summary, str)


# ===========================================================================
# 4. Service — resolved_by Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_resolve_item_sets_resolved_by_user(
    db_session: AsyncSession, review_queue_service: ReviewQueueService, test_todo: Todo
):
    from app.schemas.review_queue.review_queue import ReviewQueueResolve
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Missing info")
    await repo.create(r)
    await db_session.flush()

    resolved = await review_queue_service.resolve_item(
        r.review_id,
        ReviewQueueResolve(resolution_data={"title": "Updated"}, resolved_by=ResolvedBy.USER)
    )
    assert resolved.resolved_by == ResolvedBy.USER


@pytest.mark.asyncio
async def test_resolve_item_sets_resolved_by_admin(
    db_session: AsyncSession, review_queue_service: ReviewQueueService, test_todo: Todo
):
    from app.schemas.review_queue.review_queue import ReviewQueueResolve
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Admin review")
    await repo.create(r)
    await db_session.flush()

    resolved = await review_queue_service.resolve_item(
        r.review_id,
        ReviewQueueResolve(resolution_data={}, resolved_by=ResolvedBy.ADMIN)
    )
    assert resolved.resolved_by == ResolvedBy.ADMIN


# ===========================================================================
# 5. Repository — Pagination Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_list_pagination_limit(db_session: AsyncSession, test_todo: Todo):
    repo = ReviewQueueRepository(db_session)
    for i in range(5):
        r = make_review(EntityType.TODO, test_todo.todo_id, f"Item {i}")
        await repo.create(r)
    await db_session.flush()

    items = await repo.list_items(limit=3, offset=0)
    assert len(items) == 3


@pytest.mark.asyncio
async def test_list_pagination_offset(db_session: AsyncSession, test_todo: Todo):
    repo = ReviewQueueRepository(db_session)
    for i in range(5):
        r = make_review(
            EntityType.TODO,
            test_todo.todo_id,
            f"Offset Item {i}",
            created_at=datetime.utcnow() - timedelta(minutes=10 - i)
        )
        await repo.create(r)
    await db_session.flush()

    all_items = await repo.list_items(limit=100, offset=0)
    page2 = await repo.list_items(limit=100, offset=3)
    assert len(page2) == len(all_items) - 3


# ===========================================================================
# 6. Repository — Search Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_list_search_matches_substring(db_session: AsyncSession, test_todo: Todo):
    repo = ReviewQueueRepository(db_session)
    r1 = make_review(EntityType.TODO, test_todo.todo_id, "verify the ATTENDANCE record")
    r2 = make_review(EntityType.TODO, test_todo.todo_id, "check the FINANCE data")
    await repo.create(r1)
    await repo.create(r2)
    await db_session.flush()

    results = await repo.list_items(q="attendance")
    assert len(results) >= 1
    assert all("attendance" in item.review_message.lower() for item in results)


@pytest.mark.asyncio
async def test_list_search_is_case_insensitive(db_session: AsyncSession, test_todo: Todo):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Verify The Attendance Record")
    await repo.create(r)
    await db_session.flush()

    results_upper = await repo.list_items(q="VERIFY")
    results_lower = await repo.list_items(q="verify")
    assert len(results_upper) >= 1
    assert len(results_lower) >= 1


@pytest.mark.asyncio
async def test_list_search_no_match_returns_empty(db_session: AsyncSession, test_todo: Todo):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Check attendance")
    await repo.create(r)
    await db_session.flush()

    results = await repo.list_items(q="xyznotfound")
    assert len(results) == 0


# ===========================================================================
# 7. Service — resolve already resolved throws
# ===========================================================================

@pytest.mark.asyncio
async def test_resolve_already_resolved_throws(
    db_session: AsyncSession, review_queue_service: ReviewQueueService, test_todo: Todo
):
    from app.schemas.review_queue.review_queue import ReviewQueueResolve
    repo = ReviewQueueRepository(db_session)
    r = ReviewQueue(
        review_type=ReviewType.MISSING_INFORMATION,
        entity_type=EntityType.TODO,
        entity_id=test_todo.todo_id,
        review_message="Study help",
        review_status=ReviewStatus.RESOLVED,
        resolved_by=ResolvedBy.USER,
        created_at=datetime.utcnow(),
        resolved_at=datetime.utcnow()
    )
    await repo.create(r)
    await db_session.flush()

    with pytest.raises(ValidationException) as exc:
        await review_queue_service.resolve_item(
            r.review_id,
            ReviewQueueResolve(resolution_data={})
        )
    assert "already resolved" in str(exc.value)


# ===========================================================================
# 8. API Endpoint Integration Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_api_list_includes_entity_summary(
    client: AsyncClient, db_session: AsyncSession, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Need details")
    await repo.create(r)
    await db_session.flush()

    response = await client.get("/api/v1/review-queue")
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert len(body["data"]) >= 1
    for item in body["data"]:
        assert "entity_summary" in item
        assert isinstance(item["entity_summary"], str)


@pytest.mark.asyncio
async def test_api_list_search_filter(
    client: AsyncClient, db_session: AsyncSession, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    await repo.create(make_review(EntityType.TODO, test_todo.todo_id, "verify attendance status"))
    await repo.create(make_review(EntityType.TODO, test_todo.todo_id, "check finance details"))
    await db_session.flush()

    response = await client.get("/api/v1/review-queue?q=verify")
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert all("verify" in item["review_message"].lower() for item in body["data"])


@pytest.mark.asyncio
async def test_api_list_pagination(
    client: AsyncClient, db_session: AsyncSession, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    for i in range(5):
        await repo.create(make_review(EntityType.TODO, test_todo.todo_id, f"Pagination item {i}"))
    await db_session.flush()

    response_page1 = await client.get("/api/v1/review-queue?limit=2&offset=0")
    assert response_page1.status_code == status.HTTP_200_OK
    assert len(response_page1.json()["data"]) == 2

    response_page2 = await client.get("/api/v1/review-queue?limit=2&offset=2")
    assert response_page2.status_code == status.HTTP_200_OK
    page1_ids = {i["review_id"] for i in response_page1.json()["data"]}
    page2_ids = {i["review_id"] for i in response_page2.json()["data"]}
    assert page1_ids.isdisjoint(page2_ids)


@pytest.mark.asyncio
async def test_api_list_limit_out_of_range(client: AsyncClient):
    response = await client.get("/api/v1/review-queue?limit=200")
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    response = await client.get("/api/v1/review-queue?limit=0")
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_api_list_negative_offset(client: AsyncClient):
    response = await client.get("/api/v1/review-queue?offset=-1")
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
async def test_api_resolve_with_resolved_by_admin(
    client: AsyncClient, db_session: AsyncSession, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Admin resolution test")
    await repo.create(r)
    await db_session.flush()

    response = await client.put(
        f"/api/v1/review-queue/{r.review_id}",
        json={
            "resolution_data": {"title": "Resolved by Admin"},
            "resolved_by": "admin"
        }
    )
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["data"]["resolved_by"] == "admin"
    assert body["data"]["review_status"] == "resolved"


@pytest.mark.asyncio
async def test_api_resolve_todo_includes_entity_summary(
    client: AsyncClient, db_session: AsyncSession, test_todo: Todo
):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.TODO, test_todo.todo_id, "Missing info")
    await repo.create(r)
    await db_session.flush()

    response = await client.put(
        f"/api/v1/review-queue/{r.review_id}",
        json={"resolution_data": {"title": "Updated Title"}}
    )
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["data"]["entity_summary"] == "Updated Title"


@pytest.mark.asyncio
async def test_api_resolve_lecture_includes_entity_summary(
    client: AsyncClient, db_session: AsyncSession, test_lecture_instance: LectureInstance
):
    repo = ReviewQueueRepository(db_session)
    r = make_review(EntityType.ATTENDANCE, test_lecture_instance.lecture_instance_id, "Verify attendance")
    await repo.create(r)
    await db_session.flush()

    response = await client.put(
        f"/api/v1/review-queue/{r.review_id}",
        json={"resolution_data": {"attendance_status": "present"}}
    )
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    summary = body["data"]["entity_summary"]
    assert "Operating Systems" in summary
    assert "Tuesday" in summary


@pytest.mark.asyncio
async def test_api_get_not_found(client: AsyncClient):
    response = await client.get(f"/api/v1/review-queue/{uuid.uuid4()}")
    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.asyncio
async def test_api_resolve_non_existent(client: AsyncClient):
    response = await client.put(
        f"/api/v1/review-queue/{uuid.uuid4()}",
        json={"resolution_data": {}}
    )
    assert response.status_code == status.HTTP_404_NOT_FOUND
