import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import ForeignKey, SmallInteger, DateTime, Enum, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class CriteriaMode(str, enum.Enum):
    OVERALL = "overall"
    SUBJECT = "subject"
    CUSTOM = "custom"


class AttendanceSettings(Base):
    __tablename__ = "attendance_settings"

    attendance_settings_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    semester_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("semesters.semester_id", ondelete="CASCADE"),
        unique=True,
        nullable=False
    )
    criteria_mode: Mapped[CriteriaMode] = mapped_column(
        Enum(CriteriaMode, name="criteria_mode"),
        default=CriteriaMode.OVERALL,
        nullable=False
    )
    overall_attendance_goal: Mapped[int | None] = mapped_column(
        SmallInteger,
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
        CheckConstraint(
            "overall_attendance_goal IS NULL OR (overall_attendance_goal >= 1 AND overall_attendance_goal <= 100)",
            name="attendance_goal_range"
        ),
    )

    # Relationships
    semester: Mapped["Semester"] = relationship(
        "Semester",
        back_populates="attendance_settings"
    )
