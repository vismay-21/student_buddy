import uuid
from typing import Sequence
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notes.notes_section import NotesSection


class NotesSectionRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, section: NotesSection) -> NotesSection:
        self.db.add(section)
        return section

    async def get_by_id(self, section_id: uuid.UUID) -> NotesSection | None:
        stmt = select(NotesSection).where(NotesSection.section_id == section_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_name_in_subject(
        self, notes_subject_id: uuid.UUID, section_name: str
    ) -> NotesSection | None:
        stmt = (
            select(NotesSection)
            .where(
                and_(
                    NotesSection.notes_subject_id == notes_subject_id,
                    NotesSection.section_name == section_name
                )
            )
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_subject(self, notes_subject_id: uuid.UUID) -> Sequence[NotesSection]:
        stmt = select(NotesSection).where(NotesSection.notes_subject_id == notes_subject_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, section: NotesSection) -> NotesSection:
        # Since SQLAlchemy tracks updates, this triggers flush/commit later
        return section

    async def delete(self, section: NotesSection) -> None:
        await self.db.delete(section)
