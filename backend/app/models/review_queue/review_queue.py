import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Enum, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column
from app.core.database import Base


class ReviewType(str, enum.Enum):
    MISSING_INFORMATION = "missing_information"
    CONFIRMATION_REQUIRED = "confirmation_required"
    MANUAL_REVIEW = "manual_review"


class EntityType(str, enum.Enum):
    ATTENDANCE = "attendance"
    TODO = "todo"
    FINANCE = "finance"


class ReviewStatus(str, enum.Enum):
    PENDING = "pending"
    RESOLVED = "resolved"


class ResolvedBy(str, enum.Enum):
    USER = "user"
    SYSTEM = "system"
    ADMIN = "admin"


class ReviewQueue(Base):
    __tablename__ = "review_queue"

    review_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    review_type: Mapped[ReviewType] = mapped_column(
        Enum(ReviewType, name="review_type"),
        nullable=False
    )
    entity_type: Mapped[EntityType] = mapped_column(
        Enum(EntityType, name="entity_type"),
        nullable=False
    )
    entity_id: Mapped[uuid.UUID] = mapped_column(
        nullable=False,
        index=True
    )
    review_message: Mapped[str] = mapped_column(
        Text,
        nullable=False
    )
    review_status: Mapped[ReviewStatus] = mapped_column(
        Enum(ReviewStatus, name="review_status"),
        default=ReviewStatus.PENDING,
        nullable=False,
        index=True
    )
    resolved_by: Mapped[ResolvedBy] = mapped_column(
        Enum(ResolvedBy, name="resolved_by"),
        default=ResolvedBy.USER,
        nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
