import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Enum, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class TodoPriority(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class TodoStatus(str, enum.Enum):
    PENDING = "pending"
    COMPLETED = "completed"


class TodoCreatedBy(str, enum.Enum):
    USER = "user"
    BOT = "bot"
    REVIEW_QUEUE = "review_queue"


class Todo(Base):
    """
    Todos are completely independent of semesters, subjects, attendance, notes,
    and all academic modules.
    """
    __tablename__ = "todos"

    todo_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False
    )
    priority: Mapped[TodoPriority] = mapped_column(
        Enum(TodoPriority, name="todo_priority"),
        default=TodoPriority.MEDIUM,
        nullable=False
    )
    status: Mapped[TodoStatus] = mapped_column(
        Enum(TodoStatus, name="todo_status"),
        default=TodoStatus.PENDING,
        nullable=False,
        index=True
    )
    created_by: Mapped[TodoCreatedBy] = mapped_column(
        Enum(TodoCreatedBy, name="todo_created_by"),
        default=TodoCreatedBy.USER,
        nullable=False
    )
    due_datetime: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        index=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False
    )
