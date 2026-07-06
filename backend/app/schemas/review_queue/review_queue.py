import uuid
from datetime import datetime
from typing import Any, Dict
from pydantic import BaseModel, Field, ConfigDict
from app.models.review_queue.review_queue import ReviewType, EntityType, ReviewStatus, ResolvedBy


class ReviewQueueBase(BaseModel):
    review_type: ReviewType = Field(
        ...,
        description="Type of the review item (missing_information, confirmation_required, manual_review)"
    )
    entity_type: EntityType = Field(
        ...,
        description="Type of the referenced entity (attendance, todo, finance)"
    )
    entity_id: uuid.UUID = Field(
        ...,
        description="UUID of the referenced entity"
    )
    review_message: str = Field(
        ...,
        min_length=1,
        description="Details about the decision/verification required"
    )


class ReviewQueueCreate(ReviewQueueBase):
    pass


class ReviewQueueResolve(BaseModel):
    resolution_data: Dict[str, Any] = Field(
        ...,
        description="The data payload used to resolve the referenced entity"
    )
    resolved_by: ResolvedBy = Field(
        default=ResolvedBy.USER,
        description="Who resolved this review item (user, system, admin)"
    )


class ReviewQueueResponse(ReviewQueueBase):
    model_config = ConfigDict(from_attributes=True)

    review_id: uuid.UUID
    review_status: ReviewStatus
    resolved_by: ResolvedBy
    created_at: datetime
    resolved_at: datetime | None
    entity_summary: str = Field(
        default="",
        description="A short runtime-generated human-readable summary of the referenced entity (not stored in DB)"
    )
