import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.academic.attendance_settings import AttendanceSettingsResponse, AttendanceSettingsUpdate
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.repositories.academic.semester import SemesterRepository
from app.services.academic.attendance_settings import AttendanceSettingsService

router = APIRouter()


async def get_attendance_repo(db: AsyncSession = Depends(get_db)) -> AttendanceSettingsRepository:
    return AttendanceSettingsRepository(db)


async def get_semester_repo(db: AsyncSession = Depends(get_db)) -> SemesterRepository:
    return SemesterRepository(db)


async def get_attendance_settings_service(
    db: AsyncSession = Depends(get_db),
    attendance_repo: AttendanceSettingsRepository = Depends(get_attendance_repo),
    semester_repo: SemesterRepository = Depends(get_semester_repo),
) -> AttendanceSettingsService:
    return AttendanceSettingsService(
        db=db,
        attendance_repo=attendance_repo,
        semester_repo=semester_repo,
    )


@router.get(
    "/{semester_id}",
    response_model=ApiResponse[AttendanceSettingsResponse],
    summary="Get attendance settings by semester",
    description="Retrieve the unique attendance settings configured for a semester."
)
async def get_settings(
    semester_id: uuid.UUID,
    service: AttendanceSettingsService = Depends(get_attendance_settings_service)
):
    settings = await service.get_settings_by_semester(semester_id)
    return ApiResponse(
        success=True,
        message="Attendance settings retrieved successfully.",
        data=AttendanceSettingsResponse.model_validate(settings)
    )


@router.put(
    "/{semester_id}",
    response_model=ApiResponse[AttendanceSettingsResponse],
    summary="Update attendance settings",
    description="Update criteria mode and/or overall attendance goal for a semester."
)
async def update_settings(
    semester_id: uuid.UUID,
    update_in: AttendanceSettingsUpdate,
    service: AttendanceSettingsService = Depends(get_attendance_settings_service)
):
    settings = await service.update_attendance_settings(semester_id, update_in)
    return ApiResponse(
        success=True,
        message="Attendance settings updated successfully.",
        data=AttendanceSettingsResponse.model_validate(settings)
    )
