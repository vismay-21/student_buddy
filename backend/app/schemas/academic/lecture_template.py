import uuid
from datetime import datetime, time
from typing import Self
from pydantic import BaseModel, Field, model_validator, ConfigDict


class LectureTemplateBase(BaseModel):
    day_of_week: int = Field(
        ...,
        ge=1,
        le=7,
        description="Day of week (1 = Monday, 7 = Sunday)"
    )
    start_time: time = Field(
        ...,
        description="Start time of the recurring lecture"
    )
    end_time: time = Field(
        ...,
        description="End time of the recurring lecture"
    )
    room: str | None = Field(
        default=None,
        max_length=50,
        description="Room number or location (optional)"
    )


class LectureTemplateCreate(LectureTemplateBase):
    lecture_template_id: uuid.UUID | None = None
    subject_id: uuid.UUID = Field(
        ...,
        description="UUID of the subject this template belongs to"
    )

    @model_validator(mode="after")
    def validate_times(self) -> Self:
        if self.start_time >= self.end_time:
            raise ValueError("start_time must be strictly before end_time")
        return self


class LectureTemplateUpdate(BaseModel):
    day_of_week: int | None = Field(
        default=None,
        ge=1,
        le=7,
        description="Day of week (1 = Monday, 7 = Sunday)"
    )
    start_time: time | None = Field(
        default=None,
        description="Start time"
    )
    end_time: time | None = Field(
        default=None,
        description="End time"
    )
    room: str | None = Field(
        default=None,
        max_length=50,
        description="Room number or location"
    )

    @model_validator(mode="after")
    def validate_times(self) -> Self:
        st = self.start_time
        et = self.end_time
        if st is not None and et is not None:
            if st >= et:
                raise ValueError("start_time must be strictly before end_time")
        return self


class LectureTemplateResponse(LectureTemplateBase):
    model_config = ConfigDict(from_attributes=True)

    lecture_template_id: uuid.UUID
    subject_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
