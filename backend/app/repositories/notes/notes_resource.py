import uuid
from typing import Sequence
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notes.notes_resource import NotesResource
from app.models.notes.notes_section import NotesSection
from app.models.notes.notes_subject import NotesSubject
from app.models.academic import Semester


class NotesResourceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, resource: NotesResource) -> NotesResource:
        self.db.add(resource)
        return resource

    async def get_by_id(self, resource_id: uuid.UUID) -> NotesResource | None:
        stmt = select(NotesResource).where(NotesResource.resource_id == resource_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_file_name_in_section(
        self, section_id: uuid.UUID, file_name: str
    ) -> NotesResource | None:
        stmt = (
            select(NotesResource)
            .where(
                and_(
                    NotesResource.section_id == section_id,
                    NotesResource.file_name == file_name
                )
            )
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_resource_name_in_section(
        self, section_id: uuid.UUID, resource_name: str
    ) -> NotesResource | None:
        stmt = (
            select(NotesResource)
            .where(
                and_(
                    NotesResource.section_id == section_id,
                    NotesResource.resource_name == resource_name
                )
            )
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_section(
        self, section_id: uuid.UUID, limit: int = 50, offset: int = 0
    ) -> Sequence[NotesResource]:
        stmt = (
            select(NotesResource)
            .where(NotesResource.section_id == section_id)
            .order_by(NotesResource.resource_name.asc())
            .limit(limit)
            .offset(offset)
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def search_resources(
        self,
        q: str | None = None,
        semester_id: uuid.UUID | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> Sequence[NotesResource]:
        stmt = (
            select(NotesResource)
            .join(NotesSection, NotesResource.section_id == NotesSection.section_id)
            .join(NotesSubject, NotesSection.notes_subject_id == NotesSubject.notes_subject_id)
            .join(Semester, NotesSubject.semester_id == Semester.semester_id)
        )

        filters = []
        if q:
            search_pattern = f"%{q}%"
            filters.append(
                or_(
                    NotesResource.resource_name.ilike(search_pattern),
                    NotesResource.file_name.ilike(search_pattern)
                )
            )
        if semester_id:
            filters.append(NotesSubject.semester_id == semester_id)

        if filters:
            stmt = stmt.where(and_(*filters))

        # Ordering alphabetically: Semester -> Notes Subject -> Section -> Resource Name
        stmt = stmt.order_by(
            Semester.semester_number.asc(),
            NotesSubject.notes_subject_name.asc(),
            NotesSection.section_name.asc(),
            NotesResource.resource_name.asc()
        )

        stmt = stmt.limit(limit).offset(offset)

        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, resource: NotesResource) -> NotesResource:
        return resource

    async def delete(self, resource: NotesResource) -> None:
        await self.db.delete(resource)
