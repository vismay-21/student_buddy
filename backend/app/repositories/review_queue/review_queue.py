import uuid
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.review_queue.review_queue import ReviewQueue, ReviewStatus


class ReviewQueueRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, review_id: uuid.UUID) -> ReviewQueue | None:
        """
        Retrieves a single review queue item by its UUID.
        """
        stmt = select(ReviewQueue).where(ReviewQueue.review_id == review_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_items(
        self,
        status: ReviewStatus | None = None,
        q: str | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> Sequence[ReviewQueue]:
        """
        Retrieves review queue items supporting pagination and search.
        If status is PENDING, sorts by created_at descending.
        If status is RESOLVED, sorts by resolved_at descending.
        If status is None, returns all items sorted by created_at descending.
        """
        stmt = select(ReviewQueue)

        # Apply status filter and sorting
        if status is not None:
            stmt = stmt.where(ReviewQueue.review_status == status)
            if status == ReviewStatus.RESOLVED:
                stmt = stmt.order_by(ReviewQueue.resolved_at.desc())
            else:
                stmt = stmt.order_by(ReviewQueue.created_at.desc())
        else:
            stmt = stmt.order_by(ReviewQueue.created_at.desc())

        # Apply search filter
        if q is not None and q.strip() != "":
            stmt = stmt.where(ReviewQueue.review_message.ilike(f"%{q}%"))

        # Apply pagination
        stmt = stmt.limit(limit).offset(offset)

        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def create(self, review_item: ReviewQueue) -> ReviewQueue:
        """
        Saves a new review queue item instance to the database.
        """
        self.db.add(review_item)
        return review_item

    async def update(self, review_item: ReviewQueue) -> ReviewQueue:
        """
        Updates an existing review queue item instance.
        """
        return review_item

    async def delete(self, review_item: ReviewQueue) -> None:
        """
        Deletes a review queue item instance from the database.
        """
        await self.db.delete(review_item)
