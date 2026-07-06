import uuid
import logging
from datetime import datetime, timezone
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.todo.todo import Todo, TodoCategory, TodoPriority, TodoStatus
from app.schemas.todo.todo import TodoCreate, TodoUpdate
from app.repositories.todo.todo import TodoRepository
from app.core.exceptions import NotFoundException

logger = logging.getLogger("app.services.todo")


class TodoService:
    """
    Todos are completely independent of semesters, subjects, attendance, notes,
    and all academic modules.
    """
    def __init__(self, db: AsyncSession, todo_repo: TodoRepository):
        self.db = db
        self.todo_repo = todo_repo

    async def get_todo(self, todo_id: uuid.UUID) -> Todo:
        """
        Retrieves a single todo, raising a NotFoundException if not found.
        """
        todo = await self.todo_repo.get_by_id(todo_id)
        if todo is None:
            raise NotFoundException(f"Todo with ID {todo_id} not found")
        return todo

    async def list_todos(
        self,
        status: TodoStatus | None = None,
        category: TodoCategory | None = None,
        priority: TodoPriority | None = None,
        q: str | None = None
    ) -> Sequence[Todo]:
        """
        Lists all todos with optional status, category, priority filters and title search.
        Delegates the sorting logic directly to the repository.
        """
        return await self.todo_repo.list_todos(
            status=status,
            category=category,
            priority=priority,
            q=q
        )

    async def create_todo(self, todo_in: TodoCreate) -> Todo:
        """
        Creates a new todo task. If status is set (unlikely for new tasks),
        handles completed_at appropriately.
        """
        todo = Todo(
            title=todo_in.title,
            category=todo_in.category,
            priority=todo_in.priority,
            due_datetime=todo_in.due_datetime,
            created_by=todo_in.created_by,
            status=TodoStatus.PENDING,  # Always defaults to pending on creation
            completed_at=None
        )

        await self.todo_repo.create(todo)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        actor_map = {
            "user": ActorType.USER,
            "bot": ActorType.BOT,
            "review_queue": ActorType.REVIEW_QUEUE
        }
        actor = actor_map.get(todo.created_by.value, ActorType.USER)
        await log_activity(
            db=self.db,
            actor_type=actor,
            entity_type=EntityType.TODO,
            entity_id=todo.todo_id,
            action_type=ActionType.CREATED,
            activity_message=f"Created todo task: '{todo.title}'."
        )

        await self.db.commit()

        logger.info("Created todo task '%s' (ID: %s)", todo.title, todo.todo_id)
        return todo

    async def update_todo(self, todo_id: uuid.UUID, todo_in: TodoUpdate) -> Todo:
        """
        Updates an existing todo task. Manages completed_at timestamps
        automatically based on status transitions.
        """
        todo = await self.get_todo(todo_id)

        # Apply basic updates
        if todo_in.title is not None:
            todo.title = todo_in.title
        if todo_in.category is not None:
            todo.category = todo_in.category
        if todo_in.priority is not None:
            todo.priority = todo_in.priority
        if todo_in.due_datetime is not None:
            todo.due_datetime = todo_in.due_datetime
        elif "due_datetime" in todo_in.model_fields_set and todo_in.due_datetime is None:
            todo.due_datetime = None

        # Manage status transitions and completed_at
        was_completed = False
        if todo_in.status is not None:
            if todo_in.status == TodoStatus.COMPLETED:
                if todo.status != TodoStatus.COMPLETED:
                    todo.completed_at = datetime.now(timezone.utc)
                    was_completed = True
            elif todo_in.status == TodoStatus.PENDING:
                if todo.status != TodoStatus.PENDING:
                    todo.completed_at = None
            todo.status = todo_in.status

        await self.todo_repo.update(todo)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        action_type = ActionType.COMPLETED if was_completed else ActionType.UPDATED
        msg = f"Completed todo task: '{todo.title}'." if was_completed else f"Updated todo task details: '{todo.title}'."
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.TODO,
            entity_id=todo.todo_id,
            action_type=action_type,
            activity_message=msg
        )

        await self.db.commit()

        logger.info("Updated todo task (ID: %s)", todo.todo_id)
        return todo

    async def delete_todo(self, todo_id: uuid.UUID) -> None:
        """
        Permanently deletes a todo task.
        """
        todo = await self.get_todo(todo_id)
        await self.todo_repo.delete(todo)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.TODO,
            entity_id=todo_id,
            action_type=ActionType.DELETED,
            activity_message=f"Deleted todo task: '{todo.title}'."
        )

        await self.db.commit()

        logger.info("Deleted todo task (ID: %s)", todo_id)
