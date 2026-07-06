import uuid
from typing import Any, Dict
from app.services.review_queue.resolvers.base import BaseResolver


class FinanceResolver(BaseResolver):
    async def resolve(self, entity_id: uuid.UUID, resolution_data: Dict[str, Any]) -> None:
        # Finance module is frozen, do nothing
        pass

    async def get_summary(self, entity_id: uuid.UUID) -> str:
        return "Finance Record"
