import uuid
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict
from app.models.academic.attendance_settings import CriteriaMode


class AttendanceSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    attendance_settings_id: uuid.UUID
    semester_id: uuid.UUID
    criteria_mode: CriteriaMode
    overall_attendance_goal: int | None = Field(default=None, ge=1, le=100)
    created_at: datetime
    updated_at: datetime


class AttendanceSettingsUpdate(BaseModel):
    criteria_mode: CriteriaMode | None = Field(default=None, description="Criteria mode for attendance calculations.")
    overall_attendance_goal: int | None = Field(default=None, ge=1, le=100, description="Overall goal (1-100). Ignored in custom mode.")
