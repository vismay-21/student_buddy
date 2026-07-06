import uuid
from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.models.academic.lecture_instance import LectureStatus, AttendanceStatus
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.services.academic.lecture_instance import LectureInstanceService
from app.services.academic.attendance_statistics import AttendanceStatisticsService
from app.schemas.academic.lecture_instance import (
    LectureInstanceDetailResponse,
    LectureInstanceUpdate,
    LectureInstanceBulkUpdate,
    LectureInstanceBulkUpdateResponse,
    AttendanceStatsResponse
)

router = APIRouter()


async def get_lecture_instance_repo(db: AsyncSession = Depends(get_db)) -> LectureInstanceRepository:
    return LectureInstanceRepository(db)


async def get_subject_repo(db: AsyncSession = Depends(get_db)) -> SubjectRepository:
    return SubjectRepository(db)


async def get_semester_repo(db: AsyncSession = Depends(get_db)) -> SemesterRepository:
    return SemesterRepository(db)


async def get_attendance_settings_repo(db: AsyncSession = Depends(get_db)) -> AttendanceSettingsRepository:
    return AttendanceSettingsRepository(db)


async def get_attendance_statistics_service(
    db: AsyncSession = Depends(get_db),
    lecture_instance_repo: LectureInstanceRepository = Depends(get_lecture_instance_repo),
    subject_repo: SubjectRepository = Depends(get_subject_repo),
    semester_repo: SemesterRepository = Depends(get_semester_repo),
    attendance_settings_repo: AttendanceSettingsRepository = Depends(get_attendance_settings_repo),
) -> AttendanceStatisticsService:
    return AttendanceStatisticsService(
        db=db,
        lecture_instance_repo=lecture_instance_repo,
        subject_repo=subject_repo,
        semester_repo=semester_repo,
        attendance_settings_repo=attendance_settings_repo,
    )


async def get_lecture_instance_service(
    db: AsyncSession = Depends(get_db),
    repo: LectureInstanceRepository = Depends(get_lecture_instance_repo),
    stats_service: AttendanceStatisticsService = Depends(get_attendance_statistics_service)
) -> LectureInstanceService:
    return LectureInstanceService(db, repo, stats_service)


@router.get(
    "",
    response_model=ApiResponse[list[LectureInstanceDetailResponse]],
    summary="List lecture instances",
    description="Retrieve lecture instances with options to filter by semester, subject, date ranges, and status."
)
async def list_instances(
    semester_id: uuid.UUID | None = Query(default=None, description="Filter by semester ID"),
    subject_id: uuid.UUID | None = Query(default=None, description="Filter by subject ID"),
    start_date: date | None = Query(default=None, description="Filter by start date (inclusive)"),
    end_date: date | None = Query(default=None, description="Filter by end date (inclusive)"),
    attendance_status: AttendanceStatus | None = Query(default=None, description="Filter by attendance status"),
    lecture_status: LectureStatus | None = Query(default=None, description="Filter by lecture status"),
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    instances = await service.list_instances(
        semester_id=semester_id,
        subject_id=subject_id,
        start_date=start_date,
        end_date=end_date,
        attendance_status=attendance_status,
        lecture_status=lecture_status
    )
    responses = [LectureInstanceDetailResponse.model_validate(inst) for inst in instances]
    return ApiResponse(
        success=True,
        message="Lecture instances retrieved successfully.",
        data=responses
    )


@router.get(
    "/today",
    response_model=ApiResponse[list[LectureInstanceDetailResponse]],
    summary="Get today's lectures",
    description="Retrieve scheduled classes for today (or a customized date), sorted chronologically."
)
async def get_today_lectures(
    date_val: date | None = Query(default=None, alias="date", description="Query date (defaults to today)"),
    semester_id: uuid.UUID | None = Query(default=None, description="Filter by semester ID"),
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    instances = await service.get_today_lectures(today_date=date_val, semester_id=semester_id)
    responses = [LectureInstanceDetailResponse.model_validate(inst) for inst in instances]
    return ApiResponse(
        success=True,
        message="Today's lecture instances retrieved successfully.",
        data=responses
    )


@router.get(
    "/{instance_id}",
    response_model=ApiResponse[LectureInstanceDetailResponse],
    summary="Get a lecture instance by ID",
    description="Retrieve details of a single lecture instance by its UUID."
)
async def get_instance(
    instance_id: uuid.UUID,
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    instance = await service.get_instance(instance_id)
    response = LectureInstanceDetailResponse.model_validate(instance)
    return ApiResponse(
        success=True,
        message="Lecture instance retrieved successfully.",
        data=response
    )


@router.put(
    "/day",
    response_model=ApiResponse[LectureInstanceBulkUpdateResponse],
    summary="Mark whole day attendance",
    description="Bulk update attendance status of all scheduled classes for a specific day."
)
async def mark_whole_day(
    bulk_in: LectureInstanceBulkUpdate,
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    result = await service.mark_whole_day(bulk_in)
    return ApiResponse(
        success=True,
        message="Whole day attendance updated successfully.",
        data=result
    )


@router.put(
    "/{instance_id}",
    response_model=ApiResponse[LectureInstanceDetailResponse],
    summary="Update lecture instance attendance or status",
    description="Update attendance and/or lecture status of an individual class. Business rules validate enforcements."
)
async def update_attendance(
    instance_id: uuid.UUID,
    update_in: LectureInstanceUpdate,
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    instance = await service.update_attendance(instance_id, update_in)
    response = LectureInstanceDetailResponse.model_validate(instance)
    return ApiResponse(
        success=True,
        message="Lecture instance updated successfully.",
        data=response
    )


@router.get(
    "/stats/subject/{subject_id}",
    response_model=ApiResponse[AttendanceStatsResponse],
    summary="Get subject attendance stats",
    description="Get runtime calculated attendance stats for a specific subject."
)
async def get_subject_stats(
    subject_id: uuid.UUID,
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    stats = await service.get_subject_attendance_stats(subject_id)
    return ApiResponse(
        success=True,
        message="Subject attendance statistics computed successfully.",
        data=stats
    )


@router.get(
    "/stats/semester/{semester_id}",
    response_model=ApiResponse[AttendanceStatsResponse],
    summary="Get semester attendance stats",
    description="Get runtime aggregated attendance stats for a specific semester."
)
async def get_semester_stats(
    semester_id: uuid.UUID,
    service: LectureInstanceService = Depends(get_lecture_instance_service)
):
    stats = await service.get_semester_attendance_stats(semester_id)
    return ApiResponse(
        success=True,
        message="Semester attendance statistics computed successfully.",
        data=stats
    )
