import uuid
from datetime import datetime, date, time
from pydantic import BaseModel, ConfigDict, Field
from app.models.academic.lecture_instance import LectureStatus, AttendanceStatus, MarkedBy
from app.models.academic.attendance_settings import CriteriaMode
from app.schemas.academic.subject import SubjectResponse


class LectureInstanceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    lecture_instance_id: uuid.UUID
    lecture_template_id: uuid.UUID
    lecture_date: date
    lecture_status: LectureStatus
    attendance_status: AttendanceStatus
    marked_by: MarkedBy | None
    marked_at: datetime | None
    created_at: datetime
    updated_at: datetime


class LectureTemplateNested(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    lecture_template_id: uuid.UUID
    subject_id: uuid.UUID
    day_of_week: int
    start_time: time
    end_time: time
    room: str | None
    subject: SubjectResponse


class LectureInstanceDetailResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    lecture_instance_id: uuid.UUID
    lecture_template_id: uuid.UUID
    lecture_date: date
    lecture_status: LectureStatus
    attendance_status: AttendanceStatus
    marked_by: MarkedBy | None
    marked_at: datetime | None
    created_at: datetime
    updated_at: datetime
    lecture_template: LectureTemplateNested


class LectureInstanceUpdate(BaseModel):
    attendance_status: AttendanceStatus | None = Field(
        default=None,
        description="Updated attendance status (unmarked, present, absent)."
    )
    lecture_status: LectureStatus | None = Field(
        default=None,
        description="Updated lecture status (scheduled, holiday, cancelled)."
    )


class LectureInstanceBulkUpdate(BaseModel):
    lecture_date: date = Field(
        ...,
        description="Date of the classes to bulk mark."
    )
    attendance_status: AttendanceStatus = Field(
        ...,
        description="Attendance status to apply (present, absent)."
    )
    semester_id: uuid.UUID | None = Field(
        default=None,
        description="Optional filter for specific semester."
    )


class LectureInstanceBulkUpdateResponse(BaseModel):
    updated_count: int = Field(
        ...,
        description="Number of lecture instances successfully updated."
    )
    skipped_count: int = Field(
        ...,
        description="Number of lecture instances skipped (holidays, cancelled classes)."
    )


class AttendanceStatsResponse(BaseModel):
    total_lectures: int = Field(
        ...,
        description="Total scheduled lectures."
    )
    present_lectures: int = Field(
        ...,
        description="Number of lectures attended."
    )
    absent_lectures: int = Field(
        ...,
        description="Number of lectures missed."
    )
    attendance_percentage: float = Field(
        ...,
        description="Runtime calculated attendance percentage."
    )
    remaining_lectures: int = Field(
        ...,
        description="Number of future scheduled classes."
    )
    safe_skip_count: int = Field(
        ...,
        description="Number of classes that can be safely skipped while staying above/at target."
    )
    status_message: str = Field(
        ...,
        description="Dynamic user guidance message (e.g. 'can skip X lectures')."
    )
    # TODO (Sprint 5): Populate this field from Attendance Settings.
    criteria_mode: CriteriaMode | None = Field(
        default=None,
        description="Attendance settings criteria mode (overall, subject, custom)."
    )
