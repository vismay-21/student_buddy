from fastapi import APIRouter
from app.schemas.common import ApiResponse

router = APIRouter()


@router.get("/health", response_model=ApiResponse[dict[str, str]])
async def health_check() -> ApiResponse[dict[str, str]]:
    return ApiResponse(
        success=True,
        message="Student Buddy Backend Running",
        data={
            "status": "healthy",
            "version": "1.0.0"
        }
    )
