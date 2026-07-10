import uuid
from datetime import date
from typing import Sequence
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.subject import Subject


class LectureInstanceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_all(self, instances: list[LectureInstance]) -> list[LectureInstance]:
        self.db.add_all(instances)
        return instances

    async def delete_future_instances(self, template_id: uuid.UUID, current_date: date) -> None:
        """Deletes future scheduled unmarked instances for a given template."""
        stmt = (
            delete(LectureInstance)
            .where(LectureInstance.lecture_template_id == template_id)
            .where(LectureInstance.lecture_date > current_date)
            .where(LectureInstance.lecture_status == LectureStatus.SCHEDULED)
            .where(LectureInstance.attendance_status == AttendanceStatus.UNMARKED)
        )
        await self.db.execute(stmt)

    async def list_by_template(self, template_id: uuid.UUID) -> Sequence[LectureInstance]:
        stmt = (
            select(LectureInstance)
            .where(LectureInstance.lecture_template_id == template_id)
            .order_by(LectureInstance.lecture_date.asc())
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_by_id(self, instance_id: uuid.UUID) -> LectureInstance | None:
        stmt = (
            select(LectureInstance)
            .options(
                joinedload(LectureInstance.lecture_template)
                .joinedload(LectureTemplate.subject)
            )
            .where(LectureInstance.lecture_instance_id == instance_id)
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_date(self, lecture_date: date, semester_id: uuid.UUID | None = None) -> Sequence[LectureInstance]:
        stmt = (
            select(LectureInstance)
            .join(LectureInstance.lecture_template)
            .join(LectureTemplate.subject)
            .options(
                joinedload(LectureInstance.lecture_template)
                .joinedload(LectureTemplate.subject)
            )
            .where(LectureInstance.lecture_date == lecture_date)
        )
        if semester_id is not None:
            stmt = stmt.where(Subject.semester_id == semester_id)
        stmt = stmt.order_by(LectureTemplate.start_time.asc())
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_by_subject(
        self, subject_id: uuid.UUID, start_date: date | None = None, end_date: date | None = None
    ) -> Sequence[LectureInstance]:
        stmt = (
            select(LectureInstance)
            .join(LectureInstance.lecture_template)
            .options(
                joinedload(LectureInstance.lecture_template)
                .joinedload(LectureTemplate.subject)
            )
            .where(LectureTemplate.subject_id == subject_id)
        )
        if start_date is not None:
            stmt = stmt.where(LectureInstance.lecture_date >= start_date)
        if end_date is not None:
            stmt = stmt.where(LectureInstance.lecture_date <= end_date)
        stmt = stmt.order_by(LectureInstance.lecture_date.asc(), LectureTemplate.start_time.asc())
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def list_instances(
        self,
        semester_id: uuid.UUID | None = None,
        subject_id: uuid.UUID | None = None,
        start_date: date | None = None,
        end_date: date | None = None,
        attendance_status: AttendanceStatus | None = None,
        lecture_status: LectureStatus | None = None,
        limit: int | None = None,
        offset: int | None = None
    ) -> Sequence[LectureInstance]:
        stmt = (
            select(LectureInstance)
            .join(LectureInstance.lecture_template)
            .join(LectureTemplate.subject)
            .options(
                joinedload(LectureInstance.lecture_template)
                .joinedload(LectureTemplate.subject)
            )
        )
        if semester_id is not None:
            stmt = stmt.where(Subject.semester_id == semester_id)
        if subject_id is not None:
            stmt = stmt.where(LectureTemplate.subject_id == subject_id)
        if start_date is not None:
            stmt = stmt.where(LectureInstance.lecture_date >= start_date)
        if end_date is not None:
            stmt = stmt.where(LectureInstance.lecture_date <= end_date)
        if attendance_status is not None:
            stmt = stmt.where(LectureInstance.attendance_status == attendance_status)
        if lecture_status is not None:
            stmt = stmt.where(LectureInstance.lecture_status == lecture_status)
        stmt = stmt.order_by(LectureInstance.lecture_date.asc(), LectureTemplate.start_time.asc())
        
        if limit is not None:
            stmt = stmt.limit(limit)
        if offset is not None:
            stmt = stmt.offset(offset)
            
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, instance: LectureInstance) -> LectureInstance:
        return instance
