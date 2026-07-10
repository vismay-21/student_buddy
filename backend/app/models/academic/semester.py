import uuid
from datetime import datetime, date, timezone
from sqlalchemy import Integer, Date, DateTime, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Semester(Base):
    __tablename__ = "semesters"

    semester_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    semester_number: Mapped[int] = mapped_column(
        Integer,
        unique=True,
        nullable=False
    )
    start_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )
    end_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
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
        CheckConstraint("semester_number > 0", name="semester_number_positive"),
        CheckConstraint("start_date < end_date", name="semester_date_order"),
    )

    # Relationships
    attendance_settings: Mapped["AttendanceSettings"] = relationship(
        "AttendanceSettings",
        back_populates="semester",
        cascade="all, delete-orphan",
        uselist=False
    )
    subjects: Mapped[list["Subject"]] = relationship(
        "Subject",
        back_populates="semester",
        cascade="all, delete-orphan"
    )
    notes_subjects: Mapped[list["NotesSubject"]] = relationship(
        "NotesSubject",
        back_populates="semester",
        cascade="all, delete-orphan"
    )
    holidays: Mapped[list["Holiday"]] = relationship(
        "Holiday",
        back_populates="semester",
        cascade="all, delete-orphan"
    )
