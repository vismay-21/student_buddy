from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.settings.app_settings import AppSettings


class AppSettingsRepository:
    """
    Repository for interacting with the singleton app_settings table.
    Exposes only get_settings and update.
    """
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_settings(self) -> AppSettings | None:
        stmt = select(AppSettings).where(AppSettings.settings_id == 1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def update(self, settings: AppSettings) -> AppSettings:
        return settings
