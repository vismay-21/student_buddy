import uuid
from typing import Sequence
from sqlalchemy import select, case, nulls_last
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.todo.todo import Todo, TodoPriority, TodoStatus


class TodoRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, todo_id: uuid.UUID) -> Todo | None:
        """
        Retrieves a single todo by its ID.
        """
        stmt = select(Todo).where(Todo.todo_id == todo_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_todos(
        self,
        status: TodoStatus | None = None,
        priority: TodoPriority | None = None,
        q: str | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> Sequence[Todo]:
        """
        Retrieves all todos, optionally filtered by status, priority,
        and query string `q` for a case-insensitive match on the title.

        Default Ordering Rules:
        1. Pending todos first.
        2. Priority (High -> Medium -> Low).
        3. Earliest due_datetime first (NULL values last).
        4. Newest created_at first.
        """
        stmt = select(Todo)

        if status is not None:
            stmt = stmt.where(Todo.status == status)
        if priority is not None:
            stmt = stmt.where(Todo.priority == priority)
        if q is not None and q.strip() != "":
            stmt = stmt.where(Todo.title.ilike(f"%{q.strip()}%"))

        order_pending = case((Todo.status == TodoStatus.PENDING, 0), else_=1)
        order_priority = case(
            (Todo.priority == TodoPriority.HIGH, 0),
            (Todo.priority == TodoPriority.MEDIUM, 1),
            else_=2
        )
        order_due = nulls_last(Todo.due_datetime.asc())
        order_created = Todo.created_at.desc()

        stmt = stmt.order_by(order_pending, order_priority, order_due, order_created)
        stmt = stmt.limit(limit).offset(offset)

        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def create(self, todo: Todo) -> Todo:
        """
        Saves a new todo instance to the database.
        """
        self.db.add(todo)
        return todo

    async def update(self, todo: Todo) -> Todo:
        """
        Updates an existing todo instance.
        """
        return todo

    async def delete(self, todo: Todo) -> None:
        """
        Deletes a todo instance from the database.
        """
        await self.db.delete(todo)
