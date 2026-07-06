import uuid
from datetime import date, datetime
from typing import Self
from pydantic import BaseModel, Field, model_validator, ConfigDict
from app.schemas.academic.attendance_settings import AttendanceSettingsResponse



class SemesterBase(BaseModel):
    semester_number: int = Field(..., gt=0, description="The sequence number of the semester.")
    start_date: date
    end_date: date


class SemesterCreate(SemesterBase):
    @model_validator(mode="after")
    def validate_dates(self) -> Self:
        if self.start_date >= self.end_date:
            raise ValueError("start_date must be before end_date")
        return self


class SemesterUpdate(BaseModel):
    semester_number: int | None = Field(default=None, gt=0)
    start_date: date | None = None
    end_date: date | None = None

    @model_validator(mode="after")
    def validate_dates(self) -> Self:
        if self.start_date is not None and self.end_date is not None:
            if self.start_date >= self.end_date:
                raise ValueError("start_date must be before end_date")
        return self


class SemesterResponse(SemesterBase):
    model_config = ConfigDict(from_attributes=True)

    semester_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
    attendance_settings: AttendanceSettingsResponse | None = None

