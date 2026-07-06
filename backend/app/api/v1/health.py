from fastapi import APIRouter
from app.core.constants import BACKEND_VERSION
from app.schemas.common import ApiResponse

router = APIRouter()


@router.get("/health", response_model=ApiResponse[dict[str, str]])
async def health_check() -> ApiResponse[dict[str, str]]:
    return ApiResponse(
        success=True,
        message="Student Buddy Backend Running",
        data={
            "status": "healthy",
            "version": BACKEND_VERSION
        }
    )
