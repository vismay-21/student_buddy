from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.settings.app_settings import AppSettingsResponse, AppSettingsUpdate
from app.repositories.settings.app_settings import AppSettingsRepository
from app.repositories.academic.semester import SemesterRepository
from app.services.settings.app_settings import AppSettingsService
from app.dependencies.auth import get_current_user
from app.services.auth.authentication_service import CurrentUser

router = APIRouter()


async def get_settings_service(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
) -> AppSettingsService:
    return AppSettingsService(
        db=db,
        settings_repo=AppSettingsRepository(db, current_user.id),
        semester_repo=SemesterRepository(db, current_user.id),
    )


@router.get(
    "",
    response_model=ApiResponse[AppSettingsResponse],
    summary="Get global application settings",
    description="Retrieve the single global application settings record."
)
async def get_settings(
    service: AppSettingsService = Depends(get_settings_service)
):
    """
    App Settings store only global application preferences.
    They never store academic or attendance data.
    """
    try:
        settings = await service.get_settings()
        return ApiResponse(
            success=True,
            message="App settings retrieved successfully.",
            data=AppSettingsResponse.model_validate(settings)
        )
    except RuntimeError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )


@router.put(
    "",
    response_model=ApiResponse[AppSettingsResponse],
    summary="Update global application settings",
    description="Update global application settings (theme, toggles, active semester, folders)."
)
async def update_settings(
    update_in: AppSettingsUpdate,
    service: AppSettingsService = Depends(get_settings_service)
):
    """
    App Settings store only global application preferences.
    They never store academic or attendance data.
    """
    try:
        settings = await service.update_settings(update_in)
        return ApiResponse(
            success=True,
            message="App settings updated successfully.",
            data=AppSettingsResponse.model_validate(settings)
        )
    except RuntimeError as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
