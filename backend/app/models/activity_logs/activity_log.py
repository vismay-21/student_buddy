import enum
import uuid
from datetime import datetime
from sqlalchemy import String, Enum, DateTime, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
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
        default=datetime.utcnow,
        nullable=False,
        index=True
    )
