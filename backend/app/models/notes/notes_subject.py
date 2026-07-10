import uuid
from datetime import datetime, timezone
from sqlalchemy import ForeignKey, String, DateTime, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class NotesSubject(Base):
    __tablename__ = "notes_subjects"

    notes_subject_id: Mapped[uuid.UUID] = mapped_column(
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
    semester_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("semesters.semester_id", ondelete="CASCADE"),
        nullable=False
    )
    notes_subject_name: Mapped[str] = mapped_column(
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
        UniqueConstraint("semester_id", "notes_subject_name", name="uq_notes_subject_per_semester"),
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="notes_subjects"
    )
    semester: Mapped["Semester"] = relationship(
        "Semester",
        back_populates="notes_subjects"
    )
    sections: Mapped[list["NotesSection"]] = relationship(
        "NotesSection",
        back_populates="notes_subject",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
