import os
import uuid
from datetime import datetime
from pydantic import BaseModel, field_validator, ConfigDict
from app.models.settings.app_settings import ThemeMode


class AppSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    settings_id: int
    active_semester_id: uuid.UUID | None
    theme_mode: ThemeMode
    finance_enabled: bool
    morning_digest_enabled: bool
    night_digest_enabled: bool
    attendance_prompt_enabled: bool
    notes_download_directory: str | None
    created_at: datetime
    updated_at: datetime


class AppSettingsUpdate(BaseModel):
    active_semester_id: uuid.UUID | None = None
    theme_mode: str | None = None
    finance_enabled: bool | None = None
    morning_digest_enabled: bool | None = None
    night_digest_enabled: bool | None = None
    attendance_prompt_enabled: bool | None = None
    notes_download_directory: str | None = None

    @field_validator("theme_mode", mode="before")
    @classmethod
    def normalize_theme_mode(cls, v: str | None) -> str | None:
        if v is None:
            return v
        if not isinstance(v, str):
            raise ValueError("theme_mode must be a string")
        norm = v.strip().lower()
        if norm not in [t.value for t in ThemeMode]:
            raise ValueError(f"Invalid theme_mode: {norm}. Must be one of light, dark, system.")
        return norm

    @field_validator("notes_download_directory", mode="before")
    @classmethod
    def normalize_notes_directory(cls, v: str | None) -> str | None:
        if v is None:
            return v
        if not isinstance(v, str):
            raise ValueError("notes_download_directory must be a string")
        val = v.strip()
        if not val:
            return None
        # Normalize path to store consistently
        return os.path.normpath(val)
