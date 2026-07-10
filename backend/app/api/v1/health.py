from fastapi import APIRouter, Depends, status
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.constants import BACKEND_VERSION
from app.schemas.common import ApiResponse
from app.dependencies.database import get_db

router = APIRouter()


@router.get("/health", response_model=ApiResponse[dict[str, str]])
async def health_check(
    db: AsyncSession = Depends(get_db)
) -> JSONResponse:
    try:
        # Perform a lightweight SELECT 1 query to verify database connection
        await db.execute(text("SELECT 1"))
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "success": True,
                "message": "Student Buddy Backend Running",
                "data": {
                    "status": "healthy",
                    "version": BACKEND_VERSION,
                    "database": "connected"
                }
            }
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "success": False,
                "message": "Student Buddy Backend Service Unhealthy",
                "data": {
                    "status": "unhealthy",
                    "version": BACKEND_VERSION,
                    "database": "disconnected"
                }
            }
        )

