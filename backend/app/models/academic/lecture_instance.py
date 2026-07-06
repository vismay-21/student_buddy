import enum
import uuid
from datetime import datetime, date
from sqlalchemy import ForeignKey, Date, DateTime, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class LectureStatus(str, enum.Enum):
    SCHEDULED = "scheduled"
    HOLIDAY = "holiday"
    CANCELLED = "cancelled"


class AttendanceStatus(str, enum.Enum):
    UNMARKED = "unmarked"
    PRESENT = "present"
    ABSENT = "absent"


class MarkedBy(str, enum.Enum):
    USER = "user"
    BOT = "bot"
    REVIEW_QUEUE = "review_queue"


class LectureInstance(Base):
    __tablename__ = "lecture_instances"

    lecture_instance_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    lecture_template_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("lecture_templates.lecture_template_id", ondelete="CASCADE"),
        nullable=False
    )
    lecture_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )
    lecture_status: Mapped[LectureStatus] = mapped_column(
        Enum(LectureStatus, name="lecture_status"),
        default=LectureStatus.SCHEDULED,
        nullable=False
    )
    attendance_status: Mapped[AttendanceStatus] = mapped_column(
        Enum(AttendanceStatus, name="attendance_status"),
        default=AttendanceStatus.UNMARKED,
        nullable=False
    )
    marked_by: Mapped[MarkedBy | None] = mapped_column(
        Enum(MarkedBy, name="marked_by"),
        nullable=True
    )
    marked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False
    )

    # Relationships
    lecture_template: Mapped["LectureTemplate"] = relationship(
        "LectureTemplate",
        back_populates="lecture_instances"
    )
