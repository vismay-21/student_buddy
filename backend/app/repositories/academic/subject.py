import uuid
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.subject import Subject


class SubjectRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, subject_id: uuid.UUID) -> Subject | None:
        stmt = select(Subject).where(Subject.subject_id == subject_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_name_in_semester(
        self, semester_id: uuid.UUID, subject_name: str
    ) -> Subject | None:
        stmt = (
            select(Subject)
            .where(Subject.semester_id == semester_id)
            .where(Subject.subject_name == subject_name)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_semester(self, semester_id: uuid.UUID) -> Sequence[Subject]:
        stmt = (
            select(Subject)
            .where(Subject.semester_id == semester_id)
            .order_by(Subject.subject_name.asc())
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def create(self, subject: Subject) -> Subject:
        self.db.add(subject)
        return subject

    async def update(self, subject: Subject) -> Subject:
        return subject

    async def delete(self, subject: Subject) -> None:
        await self.db.delete(subject)
