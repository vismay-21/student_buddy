import uuid
from datetime import datetime, timezone
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        index=True,
        nullable=False
    )
    email: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        unique=True,
        index=True
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

    # Relationships
    semesters: Mapped[list["Semester"]] = relationship(
        "Semester",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    todos: Mapped[list["Todo"]] = relationship(
        "Todo",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    app_settings: Mapped["AppSettings"] = relationship(
        "AppSettings",
        back_populates="user",
        cascade="all, delete-orphan",
        uselist=False
    )
    review_queue: Mapped[list["ReviewQueue"]] = relationship(
        "ReviewQueue",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    activity_logs: Mapped[list["ActivityLog"]] = relationship(
        "ActivityLog",
        back_populates="user",
        cascade="all, delete-orphan"
    )
    notes_subjects: Mapped[list["NotesSubject"]] = relationship(
        "NotesSubject",
        back_populates="user",
        cascade="all, delete-orphan"
    )
