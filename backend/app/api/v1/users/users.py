from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.services.auth.authentication_service import CurrentUser
from app.services.users.user import UserService
from app.schemas.common import ApiResponse

router = APIRouter()


@router.post(
    "/me/initialize",
    response_model=ApiResponse[dict],
    status_code=status.HTTP_200_OK,
    summary="Initialize user profile and default settings",
    description="Idempotently create user and app_settings rows on first login."
)
async def initialize_user(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user)
):
    service = UserService(db)
    user = await service.initialize_user(current_user.id, current_user.email)
    
    return ApiResponse(
        success=True,
        message="User initialized successfully.",
        data={
            "id": str(user.id),
            "email": user.email
        }
    )
