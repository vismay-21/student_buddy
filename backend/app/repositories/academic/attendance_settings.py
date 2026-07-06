import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.attendance_settings import AttendanceSettings


class AttendanceSettingsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, settings: AttendanceSettings) -> AttendanceSettings:
        self.db.add(settings)
        return settings

    async def get_by_semester_id(self, semester_id: uuid.UUID) -> AttendanceSettings | None:
        stmt = select(AttendanceSettings).where(AttendanceSettings.semester_id == semester_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def update(self, settings: AttendanceSettings) -> AttendanceSettings:
        self.db.add(settings)
        return settings
