import uuid
from datetime import datetime, date, timezone
from sqlalchemy import ForeignKey, Date, String, DateTime, UniqueConstraint, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class Holiday(Base):
    __tablename__ = "holidays"

    holiday_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    semester_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("semesters.semester_id", ondelete="CASCADE"),
        nullable=False
    )
    holiday_date: Mapped[date] = mapped_column(
        Date,
        nullable=False
    )
    holiday_name: Mapped[str] = mapped_column(
        String(100),
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
        UniqueConstraint("semester_id", "holiday_date", name="uq_holiday_per_semester"),
        Index("ix_holidays_semester_id_holiday_date", "semester_id", "holiday_date"),
    )

    # Relationships
    semester: Mapped["Semester"] = relationship(
        "Semester",
        back_populates="holidays"
    )
