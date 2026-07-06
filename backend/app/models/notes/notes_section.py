import uuid
from datetime import datetime
from sqlalchemy import ForeignKey, String, DateTime, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class NotesSection(Base):
    __tablename__ = "notes_sections"

    section_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    notes_subject_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("notes_subjects.notes_subject_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    section_name: Mapped[str] = mapped_column(
        String(100),
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
        UniqueConstraint("notes_subject_id", "section_name", name="uq_notes_section_per_subject"),
    )

    # Relationships
    notes_subject: Mapped["NotesSubject"] = relationship(
        "NotesSubject",
        back_populates="sections"
    )
    resources: Mapped[list["NotesResource"]] = relationship(
        "NotesResource",
        back_populates="section",
        cascade="all, delete-orphan",
        passive_deletes=True
    )
