import uuid
import logging
from datetime import datetime
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException, ValidationException
from app.models.review_queue.review_queue import ReviewQueue, ReviewStatus, ResolvedBy
from app.schemas.review_queue.review_queue import ReviewQueueCreate, ReviewQueueResolve
from app.repositories.review_queue.review_queue import ReviewQueueRepository
from app.services.review_queue.resolvers.registry import RESOLVERS

logger = logging.getLogger("app.services.review_queue")


class ReviewQueueService:
    def __init__(
        self,
        db: AsyncSession,
        review_queue_repo: ReviewQueueRepository
    ):
        self.db = db
        self.review_queue_repo = review_queue_repo

    async def _populate_summary(self, item: ReviewQueue) -> None:
        """
        Dynamically sets the entity_summary attribute on a ReviewQueue model instance.
        """
        resolver_cls = RESOLVERS.get(item.entity_type)
        if resolver_cls:
            resolver = resolver_cls(self.db)
            item.entity_summary = await resolver.get_summary(item.entity_id)
        else:
            item.entity_summary = "Unknown Entity"

    async def get_item(self, review_id: uuid.UUID) -> ReviewQueue:
        """
        Retrieves a single review queue item by ID, raising a NotFoundException if not found.
        """
        item = await self.review_queue_repo.get_by_id(review_id)
        if item is None:
            raise NotFoundException(f"Review item with ID {review_id} not found")
        await self._populate_summary(item)
        return item

    async def list_items(
        self,
        status: ReviewStatus | None = None,
        q: str | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> Sequence[ReviewQueue]:
        """
        Retrieves review queue items supporting pagination and search, and resolves their dynamic summaries.
        """
        items = await self.review_queue_repo.list_items(status=status, q=q, limit=limit, offset=offset)
        for item in items:
            await self._populate_summary(item)
        return items

    async def create_item(self, review_in: ReviewQueueCreate) -> ReviewQueue:
        """
        Creates a new review queue item, validating the referenced entity exists using the resolver.
        """
        resolver_cls = RESOLVERS.get(review_in.entity_type)
        if not resolver_cls:
            raise ValidationException(f"Unsupported entity type: {review_in.entity_type}")

        # Check if entity exists
        resolver = resolver_cls(self.db)
        summary = await resolver.get_summary(review_in.entity_id)
        if summary.startswith("Unknown"):
            raise NotFoundException(f"Referenced {review_in.entity_type.value} with ID {review_in.entity_id} not found")

        item = ReviewQueue(
            review_type=review_in.review_type,
            entity_type=review_in.entity_type,
            entity_id=review_in.entity_id,
            review_message=review_in.review_message,
            review_status=ReviewStatus.PENDING,
            resolved_by=ResolvedBy.USER,
            created_at=datetime.utcnow(),
            resolved_at=None
        )
        await self.review_queue_repo.create(item)
        await self.db.flush()

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.SYSTEM,
            entity_type=EntityType.REVIEW_QUEUE,
            entity_id=item.review_id,
            action_type=ActionType.CREATED,
            activity_message=f"Created review item: '{item.review_message}'."
        )

        await self.db.commit()

        item.entity_summary = summary
        logger.info("Created review queue item (ID: %s, Type: %s)", item.review_id, item.review_type)
        return item

    async def resolve_item(self, review_id: uuid.UUID, resolve_in: ReviewQueueResolve) -> ReviewQueue:
        """
        Resolves a pending review item. Updates the original referenced entity via resolvers
        and marks the review status as resolved in a single transaction.
        """
        item = await self.get_item(review_id)
        if item.review_status == ReviewStatus.RESOLVED:
            raise ValidationException("Review item is already resolved")

        resolver_cls = RESOLVERS.get(item.entity_type)
        if not resolver_cls:
            raise ValidationException(f"Unsupported entity type for resolution: {item.entity_type}")

        # Execute resolver
        resolver = resolver_cls(self.db)
        await resolver.resolve(item.entity_id, resolve_in.resolution_data)

        # Mark review as resolved
        item.review_status = ReviewStatus.RESOLVED
        item.resolved_by = resolve_in.resolved_by
        item.resolved_at = datetime.utcnow()
        await self.review_queue_repo.update(item)
        await self.db.flush()

        # Update summary for response
        item.entity_summary = await resolver.get_summary(item.entity_id)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        actor_map = {
            ResolvedBy.USER: ActorType.USER,
            ResolvedBy.SYSTEM: ActorType.SYSTEM,
            ResolvedBy.ADMIN: ActorType.USER
        }
        actor = actor_map.get(item.resolved_by, ActorType.USER)
        await log_activity(
            db=self.db,
            actor_type=actor,
            entity_type=EntityType.REVIEW_QUEUE,
            entity_id=item.review_id,
            action_type=ActionType.RESOLVED,
            activity_message=f"Resolved review item: '{item.review_message}'."
        )

        await self.db.commit()
        logger.info("Resolved review queue item (ID: %s by %s)", item.review_id, item.resolved_by)
        return item
