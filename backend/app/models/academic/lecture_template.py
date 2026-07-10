import uuid
from datetime import datetime, time, timezone
from sqlalchemy import ForeignKey, SmallInteger, String, DateTime, Time, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class LectureTemplate(Base):
    __tablename__ = "lecture_templates"

    lecture_template_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    subject_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("subjects.subject_id", ondelete="CASCADE"),
        nullable=False
    )
    day_of_week: Mapped[int] = mapped_column(
        SmallInteger,
        nullable=False
    )
    start_time: Mapped[time] = mapped_column(
        Time,
        nullable=False
    )
    end_time: Mapped[time] = mapped_column(
        Time,
        nullable=False
    )
    room: Mapped[str | None] = mapped_column(
        String(50),
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

    __table_args__ = (
        UniqueConstraint("subject_id", "day_of_week", "start_time", name="uq_lecture_template_schedule"),
        CheckConstraint("day_of_week >= 1 AND day_of_week <= 7", name="day_of_week_range"),
        CheckConstraint("start_time < end_time", name="start_time_before_end_time"),
    )

    # Relationships
    subject: Mapped["Subject"] = relationship(
        "Subject",
        back_populates="lecture_templates"
    )
    lecture_instances: Mapped[list["LectureInstance"]] = relationship(
        "LectureInstance",
        back_populates="lecture_template",
        cascade="all, delete-orphan"
    )
