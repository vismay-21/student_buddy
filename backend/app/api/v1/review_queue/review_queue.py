import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.review_queue.review_queue import ReviewQueueResolve, ReviewQueueResponse
from app.repositories.review_queue.review_queue import ReviewQueueRepository
from app.services.review_queue.review_queue import ReviewQueueService
from app.dependencies.auth import get_current_user
from app.services.auth.authentication_service import CurrentUser
from app.models.review_queue.review_queue import ReviewStatus

router = APIRouter()


async def get_review_queue_service(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
) -> ReviewQueueService:
    return ReviewQueueService(
        db=db,
        review_queue_repo=ReviewQueueRepository(db, current_user.id),
        user_id=current_user.id
    )


@router.get(
    "",
    response_model=ApiResponse[list[ReviewQueueResponse]],
    summary="List review queue items",
    description="Retrieve all review queue items supporting case-insensitive search and pagination."
)
async def list_review_queue(
    status: ReviewStatus | None = Query(None, description="Filter items by status"),
    q: str | None = Query(None, description="Search string against review_message"),
    limit: int = Query(50, ge=1, le=100, description="Limit of items returned (1-100)"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    service: ReviewQueueService = Depends(get_review_queue_service)
):
    items = await service.list_items(status=status, q=q, limit=limit, offset=offset)
    responses = [ReviewQueueResponse.model_validate(item) for item in items]
    return ApiResponse(
        success=True,
        message="Review queue items retrieved successfully.",
        data=responses
    )


@router.get(
    "/{review_id}",
    response_model=ApiResponse[ReviewQueueResponse],
    summary="Get review queue item detail",
    description="Retrieve a single review queue item by its ID."
)
async def get_review_queue_item(
    review_id: uuid.UUID,
    service: ReviewQueueService = Depends(get_review_queue_service)
):
    item = await service.get_item(review_id)
    return ApiResponse(
        success=True,
        message="Review queue item retrieved successfully.",
        data=ReviewQueueResponse.model_validate(item)
    )


@router.put(
    "/{review_id}",
    response_model=ApiResponse[ReviewQueueResponse],
    summary="Resolve review queue item",
    description="Resolve a pending review queue item by providing updates for the referenced entity."
)
async def resolve_review_queue_item(
    review_id: uuid.UUID,
    resolve_in: ReviewQueueResolve,
    service: ReviewQueueService = Depends(get_review_queue_service)
):
    resolved_item = await service.resolve_item(review_id, resolve_in)
    return ApiResponse(
        success=True,
        message="Review queue item resolved successfully.",
        data=ReviewQueueResponse.model_validate(resolved_item)
    )
