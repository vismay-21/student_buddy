import pytest
import pytest_asyncio
import uuid
from datetime import datetime, timezone, timedelta
from httpx import AsyncClient
from fastapi import status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.todo.todo import Todo, TodoPriority, TodoStatus, TodoCreatedBy
from app.repositories.todo.todo import TodoRepository
from app.services.todo.todo import TodoService


@pytest_asyncio.fixture(scope="function")
async def todo_service(db_session: AsyncSession) -> TodoService:
    return TodoService(
        db=db_session,
        todo_repo=TodoRepository(db_session),
    )


@pytest.mark.asyncio
async def test_create_todo_success(client: AsyncClient):
    payload = {
        "title": "Clean room",
        "priority": "high",
        "due_datetime": "2026-08-15T10:00:00Z"
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["success"] is True
    todo = data["data"]
    assert todo["title"] == "Clean room"
    assert todo["priority"] == "high"
    assert todo["status"] == "pending"
    assert todo["created_by"] == "user"
    dt = datetime.fromisoformat(todo["due_datetime"].replace("Z", "+00:00"))
    assert dt.astimezone(timezone.utc) == datetime(2026, 8, 15, 10, 0, 0, tzinfo=timezone.utc)
    assert todo["completed_at"] is None
    assert todo["is_overdue"] is False
    assert todo["days_overdue"] is None


@pytest.mark.asyncio
async def test_create_todo_defaults(client: AsyncClient):
    payload = {
        "title": "Minimal todo"
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    todo = response.json()["data"]
    assert todo["priority"] == "medium"
    assert todo["status"] == "pending"
    assert todo["created_by"] == "user"
    assert todo["due_datetime"] is None


@pytest.mark.asyncio
async def test_create_todo_invalid_title(client: AsyncClient):
    payload = {
        "title": ""  # empty
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

    payload = {
        "title": "A" * 256  # too long
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT


@pytest.mark.asyncio
async def test_due_date_validation(client: AsyncClient):
    # Valid years are 2000 to 2100
    payload = {
        "title": "Invalid due date past",
        "due_datetime": "1999-12-31T23:59:59Z"
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

    payload = {
        "title": "Invalid due date future",
        "due_datetime": "2101-01-01T00:00:00Z"
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

    # Permitted past due date (e.g. year 2024 is permitted since 2000 <= 2024 <= 2100)
    payload = {
        "title": "Valid past due date",
        "due_datetime": "2024-05-01T12:00:00Z"
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_201_CREATED


@pytest.mark.asyncio
async def test_get_todo_by_id(client: AsyncClient, db_session: AsyncSession):
    # Insert a todo directly
    todo = Todo(
        title="Check details",
        priority=TodoPriority.LOW,
        status=TodoStatus.PENDING
    )
    db_session.add(todo)
    await db_session.commit()

    response = await client.get(f"/api/v1/todos/{todo.todo_id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert data["todo_id"] == str(todo.todo_id)
    assert data["title"] == "Check details"


@pytest.mark.asyncio
async def test_get_todo_not_found(client: AsyncClient):
    random_uuid = uuid.uuid4()
    response = await client.get(f"/api/v1/todos/{random_uuid}")
    assert response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.asyncio
async def test_delete_todo(client: AsyncClient, db_session: AsyncSession):
    todo = Todo(title="To delete")
    db_session.add(todo)
    await db_session.commit()

    response = await client.delete(f"/api/v1/todos/{todo.todo_id}")
    assert response.status_code == status.HTTP_200_OK
    
    # Confirm deletion
    check_stmt = select(Todo).where(Todo.todo_id == todo.todo_id)
    res = await db_session.execute(check_stmt)
    assert res.scalar_one_or_none() is None


@pytest.mark.asyncio
async def test_title_search(client: AsyncClient, db_session: AsyncSession):
    todo1 = Todo(title="Learn Python Programming")
    todo2 = Todo(title="Build a mobile App")
    todo3 = Todo(title="python script review")
    db_session.add_all([todo1, todo2, todo3])
    await db_session.commit()

    # Search for "python" case-insensitive
    response = await client.get("/api/v1/todos?q=python")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert len(data) == 2
    titles = [t["title"] for t in data]
    assert "Learn Python Programming" in titles
    assert "python script review" in titles


@pytest.mark.asyncio
async def test_list_filtering(client: AsyncClient, db_session: AsyncSession):
    todo1 = Todo(title="T1", priority=TodoPriority.HIGH, status=TodoStatus.PENDING)
    todo2 = Todo(title="T2", priority=TodoPriority.LOW, status=TodoStatus.COMPLETED)
    todo3 = Todo(title="T3", priority=TodoPriority.MEDIUM, status=TodoStatus.PENDING)
    db_session.add_all([todo1, todo2, todo3])
    await db_session.commit()

    # Filter by status
    response = await client.get("/api/v1/todos?status=completed")
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["title"] == "T2"

    # Filter by priority
    response = await client.get("/api/v1/todos?priority=high")
    data = response.json()["data"]
    assert len(data) == 1
    assert data[0]["title"] == "T1"


@pytest.mark.asyncio
async def test_default_ordering(client: AsyncClient, db_session: AsyncSession):
    # Rules:
    # 1. Pending first.
    # 2. Priority: High -> Medium -> Low.
    # 3. Earliest due_datetime first (NULL last).
    # 4. Newest created_at first.
    now = datetime.now(timezone.utc)
    
    # We create them in a specific way and check sorted output
    # Let's create:
    # T1: Completed, High priority, due today
    t1 = Todo(title="T1", status=TodoStatus.COMPLETED, priority=TodoPriority.HIGH, due_datetime=now, created_at=now - timedelta(days=1))
    
    # T2: Pending, Low priority, due tomorrow
    t2 = Todo(title="T2", status=TodoStatus.PENDING, priority=TodoPriority.LOW, due_datetime=now + timedelta(days=1), created_at=now)
    
    # T3: Pending, High priority, due in 2 days
    t3 = Todo(title="T3", status=TodoStatus.PENDING, priority=TodoPriority.HIGH, due_datetime=now + timedelta(days=2), created_at=now)
    
    # T4: Pending, High priority, due today
    t4 = Todo(title="T4", status=TodoStatus.PENDING, priority=TodoPriority.HIGH, due_datetime=now, created_at=now)
    
    # T5: Pending, High priority, null due date, created yesterday
    t5 = Todo(title="T5", status=TodoStatus.PENDING, priority=TodoPriority.HIGH, due_datetime=None, created_at=now - timedelta(days=1))
    
    # T6: Pending, High priority, null due date, created today (newer)
    t6 = Todo(title="T6", status=TodoStatus.PENDING, priority=TodoPriority.HIGH, due_datetime=None, created_at=now)

    db_session.add_all([t1, t2, t3, t4, t5, t6])
    await db_session.commit()

    response = await client.get("/api/v1/todos")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    
    # Expected order:
    # 1. Pending tasks first: T4, T3, T6, T5, T2 (T1 is completed, so it is last).
    # 2. Within pending: High priority first (T4, T3, T6, T5) before Low priority (T2).
    # 3. Within High priority pending: Earliest due date (T4 due today -> T3 due in 2 days -> T6/T5 nulls last).
    # 4. Within High priority pending nulls: Newest created_at first (T6 created today -> T5 created yesterday).
    # 5. So the total pending order should be: T4, T3, T6, T5, T2.
    # 6. Completed task last: T1.
    # Expected sequence of titles: T4, T3, T6, T5, T2, T1
    titles = [t["title"] for t in data]
    assert titles == ["T4", "T3", "T6", "T5", "T2", "T1"]


@pytest.mark.asyncio
async def test_state_transitions(client: AsyncClient, db_session: AsyncSession):
    # 1. Create a pending task
    todo = Todo(title="Transition task", status=TodoStatus.PENDING, completed_at=None)
    db_session.add(todo)
    await db_session.commit()

    # 2. Mark completed
    response = await client.put(f"/api/v1/todos/{todo.todo_id}", json={"status": "completed"})
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert data["status"] == "completed"
    assert data["completed_at"] is not None
    first_completion_time = data["completed_at"]

    # 3. Mark completed again (should preserve timestamp)
    response2 = await client.put(f"/api/v1/todos/{todo.todo_id}", json={"status": "completed"})
    data2 = response2.json()["data"]
    assert data2["completed_at"] == first_completion_time

    # 4. Revert to pending
    response3 = await client.put(f"/api/v1/todos/{todo.todo_id}", json={"status": "pending"})
    data3 = response3.json()["data"]
    assert data3["status"] == "pending"
    assert data3["completed_at"] is None

    # 5. Revert to pending again (should remain null)
    response4 = await client.put(f"/api/v1/todos/{todo.todo_id}", json={"status": "pending"})
    data4 = response4.json()["data"]
    assert data4["status"] == "pending"
    assert data4["completed_at"] is None


@pytest.mark.asyncio
async def test_overdue_calculations(client: AsyncClient, db_session: AsyncSession):
    now = datetime.now(timezone.utc)
    
    # 1. Future due date (pending) -> not overdue
    todo_future = Todo(title="Future task", status=TodoStatus.PENDING, due_datetime=now + timedelta(days=2))
    
    # 2. Past due date (pending) -> overdue by 2.5 days (floors to 2)
    todo_past = Todo(title="Past task", status=TodoStatus.PENDING, due_datetime=now - timedelta(days=2, hours=12))
    
    # 3. Past due date (completed) -> not overdue
    todo_completed = Todo(title="Completed past task", status=TodoStatus.COMPLETED, due_datetime=now - timedelta(days=5))
    
    # 4. Null due date (pending) -> not overdue
    todo_null = Todo(title="Null task", status=TodoStatus.PENDING, due_datetime=None)

    db_session.add_all([todo_future, todo_past, todo_completed, todo_null])
    await db_session.commit()

    # Get Future Task
    res = await client.get(f"/api/v1/todos/{todo_future.todo_id}")
    d = res.json()["data"]
    assert d["is_overdue"] is False
    assert d["days_overdue"] is None

    # Get Past Task
    res = await client.get(f"/api/v1/todos/{todo_past.todo_id}")
    d = res.json()["data"]
    assert d["is_overdue"] is True
    assert d["days_overdue"] == 2

    # Get Completed Past Task
    res = await client.get(f"/api/v1/todos/{todo_completed.todo_id}")
    d = res.json()["data"]
    assert d["is_overdue"] is False
    assert d["days_overdue"] is None

    # Get Null Task
    res = await client.get(f"/api/v1/todos/{todo_null.todo_id}")
    d = res.json()["data"]
    assert d["is_overdue"] is False
    assert d["days_overdue"] is None


@pytest.mark.asyncio
async def test_timezone_aware_due_dates(client: AsyncClient, db_session: AsyncSession):
    # Indian Standard Time (UTC+5:30)
    ist_tz = timezone(timedelta(hours=5, minutes=30))
    ist_due = datetime(2026, 9, 10, 15, 30, 0, tzinfo=ist_tz)
    
    payload = {
        "title": "IST Due Date Task",
        "due_datetime": ist_due.isoformat()
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()["data"]
    
    todo_id = data["todo_id"]
    
    # Retrieve it back to verify it was stored/retrieved correctly as UTC
    get_res = await client.get(f"/api/v1/todos/{todo_id}")
    assert get_res.status_code == status.HTTP_200_OK
    get_data = get_res.json()["data"]
    
    dt = datetime.fromisoformat(get_data["due_datetime"].replace("Z", "+00:00"))
    assert dt.astimezone(timezone.utc) == datetime(2026, 9, 10, 10, 0, 0, tzinfo=timezone.utc)


@pytest.mark.asyncio
async def test_timezone_naive_due_dates(client: AsyncClient):
    # Timezone naive due date (like Flutter sends: 2026-07-08T18:21:00.000)
    naive_due = "2026-07-08T18:21:00.000"
    
    payload = {
        "title": "Naive Due Date Task",
        "due_datetime": naive_due
    }
    response = await client.post("/api/v1/todos", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()["data"]
    
    assert data["title"] == "Naive Due Date Task"
    assert data["due_datetime"].startswith("2026-07-08T18:21:00")


@pytest.mark.asyncio
async def test_api_todos_pagination(client: AsyncClient, db_session: AsyncSession):
    # Create 5 todos
    todos = [
        Todo(title=f"Task {i}", priority=TodoPriority.HIGH, status=TodoStatus.PENDING)
        for i in range(1, 6)
    ]
    db_session.add_all(todos)
    await db_session.commit()

    # Query first 2 items
    response = await client.get("/api/v1/todos?limit=2&offset=0")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert len(data) == 2
    assert data[0]["title"] == "Task 5"
    assert data[1]["title"] == "Task 4"

    # Query next 2 items
    response = await client.get("/api/v1/todos?limit=2&offset=2")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert len(data) == 2
    assert data[0]["title"] == "Task 3"
    assert data[1]["title"] == "Task 2"


@pytest.mark.asyncio
async def test_api_todos_search_empty_or_whitespace(client: AsyncClient, db_session: AsyncSession):
    # 1. Create a couple of todos
    todo1 = Todo(title="First Task", priority=TodoPriority.HIGH, status=TodoStatus.PENDING)
    todo2 = Todo(title="Second Task", priority=TodoPriority.LOW, status=TodoStatus.PENDING)
    db_session.add_all([todo1, todo2])
    await db_session.commit()

    # 2. Search with empty query -> should return all (2 items)
    response_empty = await client.get("/api/v1/todos?q=")
    assert response_empty.status_code == status.HTTP_200_OK
    assert len(response_empty.json()["data"]) == 2

    # 3. Search with whitespace query -> should strip and return all (2 items)
    response_whitespace = await client.get("/api/v1/todos?q=   ")
    assert response_whitespace.status_code == status.HTTP_200_OK
    assert len(response_whitespace.json()["data"]) == 2


