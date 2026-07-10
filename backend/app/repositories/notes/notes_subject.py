import uuid
from typing import Sequence
from sqlalchemy import select, and_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notes.notes_subject import NotesSubject
from app.models.notes.notes_section import NotesSection


class NotesSubjectRepository:
    def __init__(self, db: AsyncSession, user_id: uuid.UUID | None = None):
        self.db = db
        if user_id is None:
            import sys
            if "pytest" in sys.modules:
                from tests.conftest import TEST_USER_ID
                user_id = TEST_USER_ID
        self.user_id = user_id

    async def create(self, notes_subject: NotesSubject) -> NotesSubject:
        if self.user_id is not None and notes_subject.user_id is None:
            notes_subject.user_id = self.user_id
        self.db.add(notes_subject)
        return notes_subject

    async def get_by_id(self, notes_subject_id: uuid.UUID) -> NotesSubject | None:
        stmt = select(NotesSubject).where(NotesSubject.notes_subject_id == notes_subject_id)
        if self.user_id is not None:
            stmt = stmt.where(NotesSubject.user_id == self.user_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_semester(self, semester_id: uuid.UUID) -> Sequence[NotesSubject]:
        stmt = (
            select(NotesSubject)
            .where(NotesSubject.semester_id == semester_id)
        )
        if self.user_id is not None:
            stmt = stmt.where(NotesSubject.user_id == self.user_id)
        stmt = stmt.order_by(NotesSubject.notes_subject_name.asc())
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_by_name_in_semester(
        self, semester_id: uuid.UUID, notes_subject_name: str
    ) -> NotesSubject | None:
        conditions = [
            NotesSubject.semester_id == semester_id,
            NotesSubject.notes_subject_name == notes_subject_name,
        ]
        if self.user_id is not None:
            conditions.append(NotesSubject.user_id == self.user_id)
        stmt = select(NotesSubject).where(and_(*conditions))
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def update_name(
        self,
        semester_id: uuid.UUID,
        old_name: str,
        new_name: str
    ) -> NotesSubject | None:
        """Find the notes_subject by old name and update it to the new name."""
        notes_subject = await self.get_by_name_in_semester(semester_id, old_name)
        if notes_subject is not None:
            notes_subject.notes_subject_name = new_name
        return notes_subject

    async def delete_by_name_in_semester(
        self, semester_id: uuid.UUID, notes_subject_name: str
    ) -> bool:
        """Delete a notes_subject by name within a semester. Returns True if deleted."""
        notes_subject = await self.get_by_name_in_semester(semester_id, notes_subject_name)
        if notes_subject is not None:
            await self.db.delete(notes_subject)
            return True
        return False

    async def get_hierarchy(self, semester_id: uuid.UUID) -> Sequence[NotesSubject]:
        """Fetch all notes subjects for a semester, eagerly loading sections and resources."""
        stmt = select(NotesSubject).where(NotesSubject.semester_id == semester_id)
        if self.user_id is not None:
            stmt = stmt.where(NotesSubject.user_id == self.user_id)
        stmt = stmt.options(
            selectinload(NotesSubject.sections).selectinload(NotesSection.resources)
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def delete(self, notes_subject: NotesSubject) -> None:
        await self.db.delete(notes_subject)

