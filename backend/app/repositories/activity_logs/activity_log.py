import uuid
from datetime import datetime
from typing import Sequence
from sqlalchemy import select, or_, cast, String
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity_logs.activity_log import ActivityLog, ActorType, EntityType, ActionType


class ActivityLogRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, activity_id: uuid.UUID) -> ActivityLog | None:
        """
        Retrieves a single activity log by its ID.
        """
        stmt = select(ActivityLog).where(ActivityLog.activity_id == activity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, log: ActivityLog) -> ActivityLog:
        """
        Persists a new activity log.
        """
        self.db.add(log)
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
        Queries activity logs with pagination, filters, and expanded search `q`.
        Search matches message, entity_type, and action_type case-insensitively.
        """
        stmt = select(ActivityLog)

        if actor_type is not None:
            stmt = stmt.where(ActivityLog.actor_type == actor_type)
        if entity_type is not None:
            stmt = stmt.where(ActivityLog.entity_type == entity_type)
        if action_type is not None:
            stmt = stmt.where(ActivityLog.action_type == action_type)
        if entity_id is not None:
            stmt = stmt.where(ActivityLog.entity_id == entity_id)
        if correlation_id is not None:
            stmt = stmt.where(ActivityLog.correlation_id == correlation_id)
        if start_date is not None:
            stmt = stmt.where(ActivityLog.created_at >= start_date)
        if end_date is not None:
            stmt = stmt.where(ActivityLog.created_at <= end_date)

        if q is not None and q.strip() != "":
            q_clean = q.strip()
            # Expanded search to message, entity_type and action_type
            stmt = stmt.where(
                or_(
                    ActivityLog.activity_message.ilike(f"%{q_clean}%"),
                    cast(ActivityLog.entity_type, String).ilike(f"%{q_clean}%"),
                    cast(ActivityLog.action_type, String).ilike(f"%{q_clean}%")
                )
            )

        # Default ordering: newest first (created_at DESC)
        stmt = stmt.order_by(ActivityLog.created_at.desc())
        stmt = stmt.limit(limit).offset(offset)

        result = await self.db.execute(stmt)
        return result.scalars().all()
