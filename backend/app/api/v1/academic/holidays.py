import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.academic.holiday import (
    HolidayCreate,
    HolidayUpdate,
    HolidayResponse,
    HolidayCalendarItem,
)
from app.repositories.academic.holiday import HolidayRepository
from app.repositories.academic.semester import SemesterRepository
from app.services.academic.holiday import HolidayService
from app.dependencies.auth import get_current_user
from app.services.auth.authentication_service import CurrentUser

router = APIRouter()


async def get_holiday_service(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
) -> HolidayService:
    return HolidayService(
        db=db,
        holiday_repo=HolidayRepository(db),
        semester_repo=SemesterRepository(db, current_user.id),
    )


@router.post(
    "",
    response_model=ApiResponse[HolidayResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new holiday",
    description="Create a new university holiday within a semester. "
                "Holidays never create or delete lecture instances. They only change lecture_status. "
                "Matching lecture instances on this holiday date in the same semester will be updated to "
                "holiday status, and their attendance status will be reset to unmarked. "
                "Returns 404 if the semester does not exist, "
                "or 409 if a holiday already exists on this date in the semester.",
    response_description="The newly created holiday.",
)
async def create_holiday(
    holiday_in: HolidayCreate,
    service: HolidayService = Depends(get_holiday_service),
):
    holiday = await service.create_holiday(holiday_in.semester_id, holiday_in)
    return ApiResponse(
        success=True,
        message="Holiday created successfully.",
        data=HolidayResponse.model_validate(holiday),
    )


@router.get(
    "",
    response_model=ApiResponse[list[HolidayResponse]],
    summary="List holidays",
    description="Retrieve all holidays, optionally filtered by semester_id. "
                "Holidays are ordered chronologically by date. "
                "Holidays never create or delete lecture instances. They only change lecture_status.",
    response_description="List of holidays.",
)
async def list_holidays(
    semester_id: uuid.UUID | None = Query(
        default=None,
        description="Optional semester UUID to filter holidays."
    ),
    service: HolidayService = Depends(get_holiday_service),
):
    holidays = await service.list_holidays(semester_id)
    responses = [HolidayResponse.model_validate(h) for h in holidays]
    return ApiResponse(
        success=True,
        message="Holidays retrieved successfully.",
        data=responses,
    )


@router.get(
    "/calendar/{semester_id}",
    response_model=ApiResponse[list[HolidayCalendarItem]],
    summary="Get holiday calendar for a semester",
    description="Retrieve a list of holidays for the specified semester. "
                "Returns only holiday_date and holiday_name ordered chronologically. "
                "Designed for Flutter calendar rendering.",
    response_description="List of holiday calendar items.",
)
async def get_holiday_calendar(
    semester_id: uuid.UUID,
    service: HolidayService = Depends(get_holiday_service),
):
    holidays = await service.get_calendar(semester_id)
    responses = [HolidayCalendarItem.model_validate(h) for h in holidays]
    return ApiResponse(
        success=True,
        message="Holiday calendar retrieved successfully.",
        data=responses,
    )


@router.get(
    "/{holiday_id}",
    response_model=ApiResponse[HolidayResponse],
    summary="Get a holiday by ID",
    description="Retrieve details of a specific holiday by its UUID. "
                "Returns 404 if the holiday does not exist.",
    response_description="The requested holiday.",
)
async def get_holiday(
    holiday_id: uuid.UUID,
    service: HolidayService = Depends(get_holiday_service),
):
    holiday = await service.get_holiday(holiday_id)
    return ApiResponse(
        success=True,
        message="Holiday retrieved successfully.",
        data=HolidayResponse.model_validate(holiday),
    )


@router.put(
    "/{holiday_id}",
    response_model=ApiResponse[HolidayResponse],
    summary="Update a holiday",
    description="Update a holiday's date and/or name. "
                "Holidays never create or delete lecture instances. They only change lecture_status. "
                "If the date is updated, matching lecture instances on the old date are restored to scheduled, "
                "and instances on the new date are updated to holiday status. "
                "Returns 404 if the holiday does not exist, "
                "or 409 if the new date conflicts with another holiday in the semester.",
    response_description="The updated holiday.",
)
async def update_holiday(
    holiday_id: uuid.UUID,
    holiday_in: HolidayUpdate,
    service: HolidayService = Depends(get_holiday_service),
):
    holiday = await service.update_holiday(holiday_id, holiday_in)
    return ApiResponse(
        success=True,
        message="Holiday updated successfully.",
        data=HolidayResponse.model_validate(holiday),
    )


@router.delete(
    "/{holiday_id}",
    response_model=ApiResponse[None],
    summary="Delete a holiday",
    description="Permanently delete a holiday. "
                "Holidays never create or delete lecture instances. They only change lecture_status. "
                "Lecture instances occurring on the holiday date that were previously marked holiday are restored to scheduled. "
                "Returns 404 if the holiday does not exist.",
    response_description="Confirmation of successful deletion.",
)
async def delete_holiday(
    holiday_id: uuid.UUID,
    service: HolidayService = Depends(get_holiday_service),
):
    await service.delete_holiday(holiday_id)
    return ApiResponse(
        success=True,
        message="Holiday deleted successfully.",
        data=None,
    )
