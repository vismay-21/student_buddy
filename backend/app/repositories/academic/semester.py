import uuid
from datetime import date
from typing import Sequence
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from app.models.academic.semester import Semester


class SemesterRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, semester_id: uuid.UUID) -> Semester | None:
        stmt = (
            select(Semester)
            .where(Semester.semester_id == semester_id)
            .options(selectinload(Semester.attendance_settings))
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_number(self, semester_number: int) -> Semester | None:
        stmt = (
            select(Semester)
            .where(Semester.semester_number == semester_number)
            .options(selectinload(Semester.attendance_settings))
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_overlapping(
        self,
        start_date: date,
        end_date: date,
        exclude_id: uuid.UUID | None = None
    ) -> Semester | None:
        """Return the first semester whose date range overlaps [start_date, end_date).
        Adjacent semesters (one ends the day before the other starts) are allowed.
        Optionally exclude a semester by ID (used during updates).
        """
        conditions = [
            Semester.start_date < end_date,
            Semester.end_date > start_date,
        ]
        if exclude_id is not None:
            conditions.append(Semester.semester_id != exclude_id)

        stmt = select(Semester).where(and_(*conditions)).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_all(self) -> Sequence[Semester]:
        stmt = (
            select(Semester)
            .order_by(Semester.semester_number.asc())
            .options(selectinload(Semester.attendance_settings))
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def create(self, semester: Semester) -> Semester:
        self.db.add(semester)
        return semester

    async def update(self, semester: Semester) -> Semester:
        # Object is already attached to session, returns it directly
        return semester

    async def delete(self, semester: Semester) -> None:
        await self.db.delete(semester)
