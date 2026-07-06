import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict
from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType


class ActivityLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    activity_id: uuid.UUID
    actor_type: ActorType
    entity_type: EntityType
    entity_id: uuid.UUID
    action_type: ActionType
    activity_message: str
    correlation_id: Optional[uuid.UUID]
    created_at: datetime
    entity_summary: str = ""
