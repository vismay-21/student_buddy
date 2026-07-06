import uuid
from datetime import datetime
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity_logs.activity_log import ActivityLog, ActorType, EntityType, ActionType
from app.repositories.activity_logs.activity_log import ActivityLogRepository
from app.core.exceptions import NotFoundException
from app.services.activity_logs.summary import get_activity_entity_summary


class ActivityLogService:
    def __init__(self, db: AsyncSession, activity_log_repo: ActivityLogRepository):
        self.db = db
        self.activity_log_repo = activity_log_repo

    async def get_log(self, activity_id: uuid.UUID) -> ActivityLog:
        """
        Retrieves a single activity log by ID and populates its dynamic entity summary.
        """
        log = await self.activity_log_repo.get_by_id(activity_id)
        if log is None:
            raise NotFoundException(f"Activity log with ID {activity_id} not found")
        log.entity_summary = await get_activity_entity_summary(self.db, log.entity_type, log.entity_id)
        return log

    async def list_logs(
        self,
        actor_type: ActorType | None = None,
        entity_type: EntityType | None = None,
        action_type: ActionType | None = None,
        entity_id: uuid.UUID | None = None,
        correlation_id: uuid.UUID | None = None,
        start_date: datetime | None = None,
        end_date: datetime | None = None,
        q: str | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> Sequence[ActivityLog]:
        """
        Retrieves a list of activity logs based on queries and filters,
        and dynamically populates the entity summary for each.
        """
        logs = await self.activity_log_repo.list_logs(
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
        for log in logs:
            log.entity_summary = await get_activity_entity_summary(self.db, log.entity_type, log.entity_id)
        return logs
