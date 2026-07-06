import uuid
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict


class HolidayBase(BaseModel):
    holiday_date: date = Field(..., description="The date of the university holiday.")
    holiday_name: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Name or description of the holiday.",
        examples=["Independence Day", "Winter Break"]
    )


class HolidayCreate(HolidayBase):
    semester_id: uuid.UUID = Field(..., description="ID of the semester this holiday belongs to.")


class HolidayUpdate(BaseModel):
    holiday_date: date | None = Field(None, description="Updated date of the holiday.")
    holiday_name: str | None = Field(
        None,
        min_length=1,
        max_length=100,
        description="Updated name of the holiday."
    )


class HolidayResponse(HolidayBase):
    model_config = ConfigDict(from_attributes=True)

    holiday_id: uuid.UUID
    semester_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class HolidayCalendarItem(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    holiday_date: date
    holiday_name: str
