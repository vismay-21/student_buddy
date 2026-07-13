import uuid
import logging
from datetime import datetime, timezone
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException, ValidationException
from app.models.review_queue.review_queue import ReviewQueue, ReviewStatus, ResolvedBy, EntityType
from app.schemas.review_queue.review_queue import ReviewQueueCreate, ReviewQueueResolve
from app.repositories.review_queue.review_queue import ReviewQueueRepository
from app.services.review_queue.resolvers.registry import RESOLVERS

logger = logging.getLogger("app.services.review_queue")


class ReviewQueueService:
    def __init__(
        self,
        db: AsyncSession,
        review_queue_repo: ReviewQueueRepository,
        user_id: uuid.UUID | None = None
    ):
        self.db = db
        self.review_queue_repo = review_queue_repo
        self.user_id = user_id

    async def _populate_summary(self, item: ReviewQueue) -> None:
        """
        Dynamically sets the entity_summary attribute on a ReviewQueue model instance.
        """
        resolver_cls = RESOLVERS.get(item.entity_type)
        if resolver_cls:
            resolver = resolver_cls(self.db, self.user_id)
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

    async def _bulk_populate_summaries(self, items: Sequence[ReviewQueue]) -> None:
        """
        Bulk populates entity_summary on a list of ReviewQueue items.
        Reduces query counts from N+1 to exactly one query per entity type.
        """
        if not items:
            return

        from collections import defaultdict
        grouped = defaultdict(list)
        for item in items:
            grouped[item.entity_type].append(item.entity_id)

        summaries = {}  # (entity_type, entity_id) -> summary_str

        # 1. TODO
        todo_ids = grouped.get(EntityType.TODO)
        if todo_ids:
            from app.models.todo.todo import Todo
            from sqlalchemy import select
            stmt = select(Todo).where(Todo.todo_id.in_(todo_ids))
            res = await self.db.execute(stmt)
            todos = res.scalars().all()
            todo_map = {t.todo_id: t.title for t in todos}
            for tid in todo_ids:
                summaries[(EntityType.TODO, tid)] = todo_map.get(tid, "Unknown Todo")

        # 2. ATTENDANCE (LectureInstance)
        attendance_ids = grouped.get(EntityType.ATTENDANCE)
        if attendance_ids:
            from app.models.academic.lecture_instance import LectureInstance
            from app.models.academic.lecture_template import LectureTemplate
            from app.models.academic.subject import Subject
            from sqlalchemy import select
            from sqlalchemy.orm import joinedload
            stmt = (
                select(LectureInstance)
                .options(
                    joinedload(LectureInstance.lecture_template)
                    .joinedload(LectureTemplate.subject)
                )
                .where(LectureInstance.lecture_instance_id.in_(attendance_ids))
            )
            res = await self.db.execute(stmt)
            instances = res.scalars().all()

            days = {
                1: "Monday", 2: "Tuesday", 3: "Wednesday", 4: "Thursday",
                5: "Friday", 6: "Saturday", 7: "Sunday"
            }
            instance_map = {}
            for inst in instances:
                subject_name = "Unknown"
                day_str = "Unknown Day"
                time_str = "00:00"
                if inst.lecture_template:
                    template = inst.lecture_template
                    if template.subject:
                        subject_name = template.subject.subject_name
                    day_str = days.get(template.day_of_week, "Unknown Day")
                    if template.start_time:
                        time_str = template.start_time.strftime("%H:%M")
                instance_map[inst.lecture_instance_id] = f"{subject_name} • {day_str} • {time_str}"

            for aid in attendance_ids:
                summaries[(EntityType.ATTENDANCE, aid)] = instance_map.get(aid, "Unknown Lecture")

        # 3. FINANCE
        finance_ids = grouped.get(EntityType.FINANCE)
        if finance_ids:
            for fid in finance_ids:
                summaries[(EntityType.FINANCE, fid)] = "Finance Record"

        # Assign summaries back to items
        for item in items:
            item.entity_summary = summaries.get(
                (item.entity_type, item.entity_id),
                "Unknown Entity"
            )

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
        await self._bulk_populate_summaries(items)
        return items

    async def create_item(self, review_in: ReviewQueueCreate) -> ReviewQueue:
        """
        Creates a new review queue item, validating the referenced entity exists using the resolver.
        """
        resolver_cls = RESOLVERS.get(review_in.entity_type)
        if not resolver_cls:
            raise ValidationException(f"Unsupported entity type: {review_in.entity_type}")

        # Check if entity exists
        resolver = resolver_cls(self.db, self.user_id)
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
            created_at=datetime.now(timezone.utc),
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
        resolver = resolver_cls(self.db, self.user_id)
        await resolver.resolve(item.entity_id, resolve_in.resolution_data)

        # Mark review as resolved
        item.review_status = ReviewStatus.RESOLVED
        item.resolved_by = resolve_in.resolved_by
        item.resolved_at = datetime.now(timezone.utc)
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
