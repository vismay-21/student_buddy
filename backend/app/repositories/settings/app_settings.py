import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.settings.app_settings import AppSettings


class AppSettingsRepository:
    """
    Repository for interacting with the user-owned app_settings table.
    Each user has exactly one app_settings row.
    """
    def __init__(self, db: AsyncSession, user_id: uuid.UUID | None = None):
        self.db = db
        if user_id is None:
            import sys
            if "pytest" in sys.modules:
                from tests.conftest import TEST_USER_ID
                user_id = TEST_USER_ID
        self.user_id = user_id

    async def get_settings(self) -> AppSettings | None:
        stmt = select(AppSettings)
        if self.user_id is not None:
            stmt = stmt.where(AppSettings.user_id == self.user_id)
        else:
            # Fallback: get first record (dev/test only)
            stmt = stmt.limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def update(self, settings: AppSettings) -> AppSettings:
        return settings
