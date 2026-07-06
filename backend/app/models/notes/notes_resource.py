import enum
import uuid
from datetime import datetime
from sqlalchemy import ForeignKey, String, DateTime, UniqueConstraint, BigInteger, Enum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class UploadedVia(str, enum.Enum):
    APP = "app"
    WHATSAPP = "whatsapp"
    OCR = "ocr"
    REVIEW_QUEUE = "review_queue"
    API = "api"


class NotesResource(Base):
    __tablename__ = "notes_resources"

    resource_id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
        index=True
    )
    section_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("notes_sections.section_id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    resource_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        index=True
    )
    file_name: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        index=True
    )
    mime_type: Mapped[str] = mapped_column(
        String(100),
        nullable=False
    )
    file_size_bytes: Mapped[int] = mapped_column(
        BigInteger,
        nullable=False
    )
    storage_path: Mapped[str] = mapped_column(
        String,
        nullable=False
    )
    uploaded_via: Mapped[UploadedVia] = mapped_column(
        Enum(UploadedVia, name="uploaded_via"),
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
        UniqueConstraint("section_id", "file_name", name="uq_notes_resource_per_section"),
    )

    # Relationships
    section: Mapped["NotesSection"] = relationship(
        "NotesSection",
        back_populates="resources"
    )
