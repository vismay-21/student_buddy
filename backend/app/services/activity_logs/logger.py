import logging
import uuid
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity_logs.activity_log import ActivityLog, ActorType, EntityType, ActionType
from app.repositories.activity_logs.activity_log import ActivityLogRepository

logger = logging.getLogger("app.services.activity_logs.logger")


async def log_activity(
    db: AsyncSession,
    actor_type: ActorType,
    entity_type: EntityType,
    entity_id: uuid.UUID,
    action_type: ActionType,
    activity_message: str,
    correlation_id: Optional[uuid.UUID] = None,
    user_id: Optional[uuid.UUID] = None
) -> Optional[ActivityLog]:
    """
    Records an application activity log in a best-effort, isolated transaction block.
    If activity logging fails, only the savepoint is rolled back; the parent transaction
    continues successfully, and the error is logged to the application logger.
    """
    try:
        async with db.begin_nested():
            log = ActivityLog(
                actor_type=actor_type,
                entity_type=entity_type,
                entity_id=entity_id,
                action_type=action_type,
                activity_message=activity_message,
                correlation_id=correlation_id,
                user_id=user_id
            )
            repo = ActivityLogRepository(db, user_id=user_id)
            await repo.create(log)
            await db.flush()
            return log
    except Exception as err:
        logger.error("Failed to log activity: %s", err, exc_info=True)
        return None

