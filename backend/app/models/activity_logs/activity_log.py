import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Enum, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class ActorType(str, enum.Enum):
    USER = "user"
    BOT = "bot"
    REVIEW_QUEUE = "review_queue"
    SYSTEM = "system"


class EntityType(str, enum.Enum):
    SEMESTER = "semester"
    SUBJECT = "subject"
    ATTENDANCE = "attendance"
    HOLIDAY = "holiday"
    TODO = "todo"
    NOTES = "notes"
    REVIEW_QUEUE = "review_queue"
    FINANCE = "finance"
    SETTINGS = "settings"


class ActionType(str, enum.Enum):
    CREATED = "created"
    UPDATED = "updated"
    DELETED = "deleted"
    COMPLETED = "completed"
    RESOLVED = "resolved"
    DOWNLOADED = "downloaded"
    UPLOADED = "uploaded"
    MARKED_PRESENT = "marked_present"
    MARKED_ABSENT = "marked_absent"
    MARKED_HOLIDAY = "marked_holiday"


class ActivityLog(Base):
    __tablename__ = "activity_logs"

    activity_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        default=lambda: __import__("app.core.database", fromlist=["get_default_user_id"]).get_default_user_id()
    )
    actor_type: Mapped[ActorType] = mapped_column(
        Enum(ActorType, name="activity_actor_type"),
        nullable=False,
        index=True
    )
    entity_type: Mapped[EntityType] = mapped_column(
        Enum(EntityType, name="activity_entity_type"),
        nullable=False,
        index=True
    )
    entity_id: Mapped[uuid.UUID] = mapped_column(
        nullable=False,
        index=True
    )
    action_type: Mapped[ActionType] = mapped_column(
        Enum(ActionType, name="activity_action_type"),
        nullable=False,
        index=True
    )
    activity_message: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )
    correlation_id: Mapped[uuid.UUID | None] = mapped_column(
        nullable=True,
        index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True
    )

    user: Mapped["User"] = relationship("User", back_populates="activity_logs")
