import uuid
from datetime import date
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.holiday import Holiday


class HolidayRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, holiday_id: uuid.UUID) -> Holiday | None:
        stmt = select(Holiday).where(Holiday.holiday_id == holiday_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_semester_id(self, semester_id: uuid.UUID) -> Sequence[Holiday]:
        stmt = (
            select(Holiday)
            .where(Holiday.semester_id == semester_id)
            .order_by(Holiday.holiday_date.asc())
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_by_date_and_semester(self, semester_id: uuid.UUID, holiday_date: date) -> Holiday | None:
        stmt = (
            select(Holiday)
            .where(Holiday.semester_id == semester_id)
            .where(Holiday.holiday_date == holiday_date)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def create(self, holiday: Holiday) -> Holiday:
        self.db.add(holiday)
        return holiday

    async def update(self, holiday: Holiday) -> Holiday:
        return holiday

    async def delete(self, holiday: Holiday) -> None:
        await self.db.delete(holiday)
