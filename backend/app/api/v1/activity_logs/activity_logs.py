import uuid
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, Path
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
from app.schemas.activity_logs.activity_log import ActivityLogResponse
from app.repositories.activity_logs.activity_log import ActivityLogRepository
from app.services.activity_logs.activity_log import ActivityLogService

router = APIRouter()


async def get_activity_log_service(db: AsyncSession = Depends(get_db)) -> ActivityLogService:
    return ActivityLogService(
        db=db,
        activity_log_repo=ActivityLogRepository(db)
    )


@router.get("/", response_model=List[ActivityLogResponse])
async def list_activity_logs(
    actor_type: Optional[ActorType] = Query(None, description="Filter by actor type"),
    entity_type: Optional[EntityType] = Query(None, description="Filter by entity type"),
    action_type: Optional[ActionType] = Query(None, description="Filter by action type"),
    entity_id: Optional[uuid.UUID] = Query(None, description="Filter by entity ID"),
    correlation_id: Optional[uuid.UUID] = Query(None, description="Filter by correlation ID"),
    start_date: Optional[datetime] = Query(None, description="Filter by start date"),
    end_date: Optional[datetime] = Query(None, description="Filter by end date"),
    q: Optional[str] = Query(None, description="Case-insensitive search string"),
    limit: int = Query(50, ge=1, le=100, description="Page limit (1-100)"),
    offset: int = Query(0, ge=0, description="Page offset (>=0)"),
    service: ActivityLogService = Depends(get_activity_log_service)
) -> List[ActivityLogResponse]:
    """
    Retrieves the activity logs timeline based on query parameters and filters.
    """
    logs = await service.list_logs(
        actor_type=actor_type,
        entity_type=entity_type,
        action_type=action_type,
        entity_id=entity_id,
        correlation_id=correlation_id,
        start_date=start_date,
        end_date=end_date,
        q=q,
        limit=limit,
        offset=offset
    )
    return list(logs)


@router.get("/{activity_id}", response_model=ActivityLogResponse)
async def get_activity_log(
    activity_id: uuid.UUID = Path(..., description="The ID of the activity log to retrieve"),
    service: ActivityLogService = Depends(get_activity_log_service)
) -> ActivityLogResponse:
    """
    Retrieves a single activity log by its ID.
    """
    return await service.get_log(activity_id)
