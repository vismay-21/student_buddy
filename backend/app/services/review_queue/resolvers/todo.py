import uuid
from typing import Any, Dict
from datetime import datetime, timezone
from app.core.exceptions import NotFoundException, ValidationException
from app.models.todo.todo import TodoStatus
from app.schemas.todo.todo import TodoUpdate
from app.repositories.todo.todo import TodoRepository
from app.services.review_queue.resolvers.base import BaseResolver


class TodoResolver(BaseResolver):
    async def resolve(self, entity_id: uuid.UUID, resolution_data: Dict[str, Any]) -> None:
        todo_repo = TodoRepository(self.db)
        todo = await todo_repo.get_by_id(entity_id)
        if todo is None:
            raise NotFoundException(f"Referenced Todo with ID {entity_id} not found")

        # Validate resolution data using TodoUpdate schema
        try:
            todo_update = TodoUpdate(**resolution_data)
        except Exception as e:
            raise ValidationException(f"Invalid resolution data for Todo: {str(e)}")

        # Apply updates
        if todo_update.title is not None:
            todo.title = todo_update.title
        if todo_update.category is not None:
            todo.category = todo_update.category
        if todo_update.priority is not None:
            todo.priority = todo_update.priority
        if todo_update.due_datetime is not None:
            todo.due_datetime = todo_update.due_datetime
        elif "due_datetime" in todo_update.model_fields_set and todo_update.due_datetime is None:
            todo.due_datetime = None

        if todo_update.status is not None:
            if todo_update.status == TodoStatus.COMPLETED:
                if todo.status != TodoStatus.COMPLETED:
                    todo.completed_at = datetime.now(timezone.utc)
            elif todo_update.status == TodoStatus.PENDING:
                if todo.status != TodoStatus.PENDING:
                    todo.completed_at = None
            todo.status = todo_update.status

        await todo_repo.update(todo)

    async def get_summary(self, entity_id: uuid.UUID) -> str:
        todo_repo = TodoRepository(self.db)
        todo = await todo_repo.get_by_id(entity_id)
        if todo is None:
            return "Unknown Todo"
        return todo.title
