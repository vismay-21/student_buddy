import uuid
from typing import Any, Dict
from sqlalchemy.ext.asyncio import AsyncSession


class BaseResolver:
    def __init__(self, db: AsyncSession, user_id: uuid.UUID | None = None):
        self.db = db
        self.user_id = user_id

    async def resolve(self, entity_id: uuid.UUID, resolution_data: Dict[str, Any]) -> None:
        """
        Executes the resolution logic for the given entity using resolution_data.
        Modifies and updates the target entity inside the current transaction.
        """
        raise NotImplementedError

    async def get_summary(self, entity_id: uuid.UUID) -> str:
        """
        Returns a short human-readable summary description of the referenced entity.
        Used at runtime to populate ReviewQueueResponse.entity_summary dynamically.
        """
        raise NotImplementedError
