import uuid
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.academic.semester import SemesterCreate, SemesterUpdate, SemesterResponse
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.services.academic.semester import SemesterService

router = APIRouter()


async def get_semester_repo(db: AsyncSession = Depends(get_db)) -> SemesterRepository:
    return SemesterRepository(db)


async def get_attendance_repo(db: AsyncSession = Depends(get_db)) -> AttendanceSettingsRepository:
    return AttendanceSettingsRepository(db)


async def get_semester_service(
    db: AsyncSession = Depends(get_db),
    semester_repo: SemesterRepository = Depends(get_semester_repo),
    attendance_repo: AttendanceSettingsRepository = Depends(get_attendance_repo)
) -> SemesterService:
    return SemesterService(db, semester_repo, attendance_repo)


@router.get(
    "",
    response_model=ApiResponse[list[SemesterResponse]],
    summary="List all semesters",
    description="Retrieve all semesters ordered by semester number ascending. "
                "Each semester includes its associated attendance settings.",
    response_description="List of all semesters with attendance settings."
)
async def list_semesters(service: SemesterService = Depends(get_semester_service)):
    semesters = await service.list_semesters()
    responses = [SemesterResponse.model_validate(sem) for sem in semesters]
    return ApiResponse(
        success=True,
        message="Semesters retrieved successfully.",
        data=responses
    )


@router.get(
    "/{semester_id}",
    response_model=ApiResponse[SemesterResponse],
    summary="Get a semester by ID",
    description="Retrieve a single semester by its UUID. "
                "Returns 404 if the semester does not exist.",
    response_description="The requested semester with attendance settings."
)
async def get_semester(
    semester_id: uuid.UUID,
    service: SemesterService = Depends(get_semester_service)
):
    semester = await service.get_semester(semester_id)
    return ApiResponse(
        success=True,
        message="Semester retrieved successfully.",
        data=SemesterResponse.model_validate(semester)
    )


@router.post(
    "",
    response_model=ApiResponse[SemesterResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new semester",
    description="Create a new semester with a unique number and non-overlapping date range. "
                "Default attendance settings (criteria mode: overall, goal: 75%) "
                "are automatically created. "
                "Returns 409 if the semester number already exists or the date range "
                "overlaps with an existing semester.",
    response_description="The newly created semester with default attendance settings."
)
async def create_semester(
    semester_in: SemesterCreate,
    service: SemesterService = Depends(get_semester_service)
):
    semester = await service.create_semester(semester_in)
    return ApiResponse(
        success=True,
        message="Semester created successfully.",
        data=SemesterResponse.model_validate(semester)
    )


@router.put(
    "/{semester_id}",
    response_model=ApiResponse[SemesterResponse],
    summary="Update an existing semester",
    description="Partially update a semester's number, start date, or end date. "
                "Validates that the updated date range does not overlap with other semesters "
                "and that start_date remains before end_date. "
                "Returns 404 if the semester does not exist, "
                "409 if the number conflicts or dates overlap, "
                "or 400 if dates are inconsistent.",
    response_description="The updated semester with attendance settings."
)
async def update_semester(
    semester_id: uuid.UUID,
    semester_in: SemesterUpdate,
    service: SemesterService = Depends(get_semester_service)
):
    semester = await service.update_semester(semester_id, semester_in)
    return ApiResponse(
        success=True,
        message="Semester updated successfully.",
        data=SemesterResponse.model_validate(semester)
    )


@router.delete(
    "/{semester_id}",
    response_model=ApiResponse[None],
    summary="Delete a semester",
    description="Permanently delete a semester and its associated attendance settings "
                "(cascade). Returns 404 if the semester does not exist.",
    response_description="Confirmation of successful deletion."
)
async def delete_semester(
    semester_id: uuid.UUID,
    service: SemesterService = Depends(get_semester_service)
):
    await service.delete_semester(semester_id)
    return ApiResponse(
        success=True,
        message="Semester deleted successfully.",
        data=None
    )
