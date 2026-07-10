import enum
import uuid
from datetime import datetime, timezone
from sqlalchemy import SmallInteger, Boolean, String, ForeignKey, DateTime, Enum, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.database import Base


class ThemeMode(str, enum.Enum):
    LIGHT = "light"
    DARK = "dark"
    SYSTEM = "system"


class AppSettings(Base):
    """
    App Settings store only global application preferences.
    They never store academic or attendance data.
    """
    __tablename__ = "app_settings"

    settings_id: Mapped[int] = mapped_column(
        SmallInteger,
        primary_key=True,
        nullable=False
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
        index=True,
        default=lambda: __import__("app.core.database", fromlist=["get_default_user_id"]).get_default_user_id()
    )
    active_semester_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("semesters.semester_id", ondelete="RESTRICT"),
        nullable=True
    )
    theme_mode: Mapped[ThemeMode] = mapped_column(
        Enum(ThemeMode, name="theme_mode"),
        default=ThemeMode.SYSTEM,
        nullable=False
    )
    finance_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False
    )
    morning_digest_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
    night_digest_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
    attendance_prompt_enabled: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False
    )
    notes_download_directory: Mapped[str | None] = mapped_column(
        String,
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

    # Relationship
    user: Mapped["User"] = relationship("User", back_populates="app_settings")
    active_semester = relationship("Semester")

