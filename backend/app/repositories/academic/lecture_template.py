import uuid
from datetime import time
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.lecture_template import LectureTemplate


class LectureTemplateRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, template_id: uuid.UUID) -> LectureTemplate | None:
        stmt = select(LectureTemplate).where(LectureTemplate.lecture_template_id == template_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_schedule(
        self, subject_id: uuid.UUID, day_of_week: int, start_time: time
    ) -> LectureTemplate | None:
        stmt = (
            select(LectureTemplate)
            .where(LectureTemplate.subject_id == subject_id)
            .where(LectureTemplate.day_of_week == day_of_week)
            .where(LectureTemplate.start_time == start_time)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_subject(self, subject_id: uuid.UUID) -> Sequence[LectureTemplate]:
        stmt = (
            select(LectureTemplate)
            .where(LectureTemplate.subject_id == subject_id)
            .order_by(LectureTemplate.day_of_week.asc(), LectureTemplate.start_time.asc())
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def create(self, template: LectureTemplate) -> LectureTemplate:
        self.db.add(template)
        return template

    async def update(self, template: LectureTemplate) -> LectureTemplate:
        return template

    async def delete(self, template: LectureTemplate) -> None:
        await self.db.delete(template)
