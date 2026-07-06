import uuid
from datetime import datetime
from sqlalchemy import ForeignKey, Integer, SmallInteger, String, DateTime, CheckConstraint, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Subject(Base):
    __tablename__ = "subjects"

    subject_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    semester_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("semesters.semester_id", ondelete="CASCADE"),
        nullable=False
    )
    subject_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )
    faculty_name: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True
    )
    theme_color: Mapped[str | None] = mapped_column(
        String(7),
        nullable=True
    )
    attendance_goal: Mapped[int] = mapped_column(
        SmallInteger,
        nullable=False
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

    __table_args__ = (
        UniqueConstraint("semester_id", "subject_name", name="uq_subject_per_semester"),
        CheckConstraint(
            "attendance_goal >= 1 AND attendance_goal <= 100",
            name="attendance_goal_range_subjects"
        ),
    )

    # Relationships
    semester: Mapped["Semester"] = relationship(
        "Semester",
        back_populates="subjects"
    )
    lecture_templates: Mapped[list["LectureTemplate"]] = relationship(
        "LectureTemplate",
        back_populates="subject",
        cascade="all, delete-orphan"
    )
