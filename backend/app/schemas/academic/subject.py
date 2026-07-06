import uuid
from datetime import datetime
from typing import Self
from pydantic import BaseModel, Field, field_validator, model_validator, ConfigDict
from app.core.constants import DEFAULT_ATTENDANCE_GOAL
import re


class SubjectBase(BaseModel):
    subject_name: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Name of the academic subject."
    )
    faculty_name: str | None = Field(
        default=None,
        max_length=100,
        description="Name of the faculty member teaching this subject."
    )
    theme_color: str | None = Field(
        default=None,
        max_length=7,
        description="HEX color code for the subject card (e.g. #FF5733)."
    )
    attendance_goal: int = Field(
        default=DEFAULT_ATTENDANCE_GOAL,
        ge=1,
        le=100,
        description="Subject-level attendance goal percentage (1-100)."
    )

    @field_validator("theme_color")
    @classmethod
    def validate_hex_color(cls, v: str | None) -> str | None:
        if v is not None and not re.match(r"^#[0-9A-Fa-f]{6}$", v):
            raise ValueError("theme_color must be a valid HEX color (e.g. #FF5733)")
        return v


class SubjectCreate(SubjectBase):
    semester_id: uuid.UUID = Field(
        ...,
        description="UUID of the semester this subject belongs to."
    )


class SubjectUpdate(BaseModel):
    subject_name: str | None = Field(
        default=None,
        min_length=1,
        max_length=100,
        description="Updated subject name."
    )
    faculty_name: str | None = Field(
        default=None,
        max_length=100,
        description="Updated faculty name."
    )
    theme_color: str | None = Field(
        default=None,
        max_length=7,
        description="Updated HEX color code."
    )
    attendance_goal: int | None = Field(
        default=None,
        ge=1,
        le=100,
        description="Updated attendance goal percentage."
    )

    @field_validator("theme_color")
    @classmethod
    def validate_hex_color(cls, v: str | None) -> str | None:
        if v is not None and not re.match(r"^#[0-9A-Fa-f]{6}$", v):
            raise ValueError("theme_color must be a valid HEX color (e.g. #FF5733)")
        return v


class SubjectResponse(SubjectBase):
    model_config = ConfigDict(from_attributes=True)

    subject_id: uuid.UUID
    semester_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
