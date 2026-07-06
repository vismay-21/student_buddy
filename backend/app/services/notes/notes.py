import logging
import uuid
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundException, ConflictException
from app.models.notes.notes_subject import NotesSubject
from app.models.notes.notes_section import NotesSection
from app.models.notes.notes_resource import NotesResource
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.repositories.notes.notes_section import NotesSectionRepository
from app.repositories.notes.notes_resource import NotesResourceRepository
from app.repositories.academic.semester import SemesterRepository
from app.schemas.notes.notes_section import NotesSectionCreate, NotesSectionUpdate
from app.schemas.notes.notes_resource import NotesResourceCreate, NotesResourceUpdate

logger = logging.getLogger(__name__)


class NotesService:
    def __init__(
        self,
        db: AsyncSession,
        notes_subject_repo: NotesSubjectRepository,
        notes_section_repo: NotesSectionRepository,
        notes_resource_repo: NotesResourceRepository,
        semester_repo: SemesterRepository
    ):
        self.db = db
        self.notes_subject_repo = notes_subject_repo
        self.notes_section_repo = notes_section_repo
        self.notes_resource_repo = notes_resource_repo
        self.semester_repo = semester_repo

    # ==========================================
    # Notes Subjects (Read-Only)
    # ==========================================
    async def get_subject(self, notes_subject_id: uuid.UUID) -> NotesSubject:
        subject = await self.notes_subject_repo.get_by_id(notes_subject_id)
        if subject is None:
            raise NotFoundException(f"Notes Subject with ID {notes_subject_id} not found")
        return subject

    async def list_subjects(self, semester_id: uuid.UUID) -> Sequence[NotesSubject]:
        # Validate semester exists
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")
        return await self.notes_subject_repo.list_by_semester(semester_id)

    # ==========================================
    # Notes Sections (CRUD)
    # ==========================================
    async def get_section(self, section_id: uuid.UUID) -> NotesSection:
        section = await self.notes_section_repo.get_by_id(section_id)
        if section is None:
            raise NotFoundException(f"Notes Section with ID {section_id} not found")
        return section

    async def list_sections(self, notes_subject_id: uuid.UUID) -> Sequence[NotesSection]:
        # Validate notes subject exists
        await self.get_subject(notes_subject_id)
        return await self.notes_section_repo.list_by_subject(notes_subject_id)

    async def create_section(self, section_in: NotesSectionCreate) -> NotesSection:
        # Validate parent notes subject exists
        await self.get_subject(section_in.notes_subject_id)

        # Enforce unique section name within Notes Subject
        existing = await self.notes_section_repo.get_by_name_in_subject(
            section_in.notes_subject_id, section_in.section_name
        )
        if existing is not None:
            raise ConflictException(
                f"Section with name '{section_in.section_name}' already exists in this subject"
            )

        section = NotesSection(
            notes_subject_id=section_in.notes_subject_id,
            section_name=section_in.section_name
        )
        await self.notes_section_repo.create(section)
        await self.db.flush()

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.NOTES,
            entity_id=section.section_id,
            action_type=ActionType.CREATED,
            activity_message=f"Created notes section '{section.section_name}'."
        )

        await self.db.commit()
        return section

    async def update_section(self, section_id: uuid.UUID, section_in: NotesSectionUpdate) -> NotesSection:
        section = await self.get_section(section_id)

        # If name is changing, enforce unique section name within Notes Subject
        if section.section_name != section_in.section_name:
            existing = await self.notes_section_repo.get_by_name_in_subject(
                section.notes_subject_id, section_in.section_name
            )
            if existing is not None:
                raise ConflictException(
                    f"Section with name '{section_in.section_name}' already exists in this subject"
                )
            section.section_name = section_in.section_name

        await self.notes_section_repo.update(section)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.NOTES,
            entity_id=section.section_id,
            action_type=ActionType.UPDATED,
            activity_message=f"Updated notes section name to '{section.section_name}'."
        )

        await self.db.commit()
        return section

    async def delete_section(self, section_id: uuid.UUID) -> None:
        section = await self.get_section(section_id)
        await self.notes_section_repo.delete(section)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.NOTES,
            entity_id=section_id,
            action_type=ActionType.DELETED,
            activity_message=f"Deleted notes section '{section.section_name}'."
        )

        await self.db.commit()

    # ==========================================
    # Notes Resources (CRUD)
    # ==========================================
    async def get_resource(self, resource_id: uuid.UUID) -> NotesResource:
        resource = await self.notes_resource_repo.get_by_id(resource_id)
        if resource is None:
            raise NotFoundException(f"Resource with ID {resource_id} not found")
        return resource

    async def list_resources(
        self, section_id: uuid.UUID, limit: int = 50, offset: int = 0
    ) -> Sequence[NotesResource]:
        # Validate section exists
        await self.get_section(section_id)
        return await self.notes_resource_repo.list_by_section(section_id, limit=limit, offset=offset)

    async def create_resource(self, resource_in: NotesResourceCreate) -> NotesResource:
        # TODO (Sprint 12):
        # When physical uploads are implemented:
        # - Verify the uploaded file exists.
        # - Detect MIME type server-side.
        # - Compare detected MIME type against the client-provided MIME type.
        # - Reject mismatches.
        # - Store metadata only after successful upload.

        # Validate section exists
        await self.get_section(resource_in.section_id)

        # Enforce unique file_name per section
        existing_file = await self.notes_resource_repo.get_by_file_name_in_section(
            resource_in.section_id, resource_in.file_name
        )
        if existing_file is not None:
            raise ConflictException(
                f"Resource with file name '{resource_in.file_name}' already exists in this section"
            )

        # Enforce unique resource_name per section
        existing_res = await self.notes_resource_repo.get_by_resource_name_in_section(
            resource_in.section_id, resource_in.resource_name
        )
        if existing_res is not None:
            raise ConflictException(
                f"Resource with name '{resource_in.resource_name}' already exists in this section"
            )

        resource = NotesResource(
            section_id=resource_in.section_id,
            resource_name=resource_in.resource_name,
            file_name=resource_in.file_name,
            mime_type=resource_in.mime_type,
            file_size_bytes=resource_in.file_size_bytes,
            storage_path=resource_in.storage_path,
            uploaded_via=resource_in.uploaded_via
        )
        await self.notes_resource_repo.create(resource)
        await self.db.flush()

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.NOTES,
            entity_id=resource.resource_id,
            action_type=ActionType.UPLOADED,
            activity_message=f"Uploaded resource '{resource.resource_name}'."
        )

        await self.db.commit()

        return resource

    async def update_resource(self, resource_id: uuid.UUID, resource_in: NotesResourceUpdate) -> NotesResource:
        resource = await self.get_resource(resource_id)

        # If file_name is changing, validate uniqueness in section
        if resource_in.file_name is not None and resource.file_name != resource_in.file_name:
            existing_file = await self.notes_resource_repo.get_by_file_name_in_section(
                resource.section_id, resource_in.file_name
            )
            if existing_file is not None:
                raise ConflictException(
                    f"Resource with file name '{resource_in.file_name}' already exists in this section"
                )
            resource.file_name = resource_in.file_name

        # If resource_name is changing, validate uniqueness in section
        if resource_in.resource_name is not None and resource.resource_name != resource_in.resource_name:
            existing_res = await self.notes_resource_repo.get_by_resource_name_in_section(
                resource.section_id, resource_in.resource_name
            )
            if existing_res is not None:
                raise ConflictException(
                    f"Resource with name '{resource_in.resource_name}' already exists in this section"
                )
            resource.resource_name = resource_in.resource_name

        # Update other fields
        if resource_in.mime_type is not None:
            resource.mime_type = resource_in.mime_type
        if resource_in.file_size_bytes is not None:
            resource.file_size_bytes = resource_in.file_size_bytes
        if resource_in.storage_path is not None:
            resource.storage_path = resource_in.storage_path
        if resource_in.uploaded_via is not None:
            resource.uploaded_via = resource_in.uploaded_via

        await self.notes_resource_repo.update(resource)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.NOTES,
            entity_id=resource.resource_id,
            action_type=ActionType.UPDATED,
            activity_message=f"Updated resource details for '{resource.resource_name}'."
        )

        await self.db.commit()

        return resource

    async def delete_resource(self, resource_id: uuid.UUID) -> None:
        resource = await self.get_resource(resource_id)

        # TODO (Sprint 12): Deletion flow:
        # 1. Delete file from Supabase Storage.
        # 2. If deletion succeeds:
        #    delete metadata row.
        # 3. If storage deletion fails:
        #    rollback transaction.
        # 4. Log Activity in Sprint 11.

        await self.notes_resource_repo.delete(resource)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.NOTES,
            entity_id=resource_id,
            action_type=ActionType.DELETED,
            activity_message=f"Deleted resource '{resource.resource_name}'."
        )

        await self.db.commit()

    # ==========================================
    # Hierarchy & Search
    # ==========================================
    async def get_notes_hierarchy(self, semester_id: uuid.UUID) -> Sequence[NotesSubject]:
        # Validate semester exists
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")

        subjects = list(await self.notes_subject_repo.get_hierarchy(semester_id))

        # Alphabetically sort (case-insensitive) Subjects, Sections, and Resources
        subjects.sort(key=lambda s: s.notes_subject_name.lower())
        for s in subjects:
            s.sections.sort(key=lambda sec: sec.section_name.lower())
            for sec in s.sections:
                sec.resources.sort(key=lambda res: res.resource_name.lower())

        return subjects

    async def search_resources(
        self,
        q: str | None = None,
        semester_id: uuid.UUID | None = None,
        limit: int = 50,
        offset: int = 0
    ) -> Sequence[NotesResource]:
        if semester_id is not None:
            # Validate semester exists
            semester = await self.semester_repo.get_by_id(semester_id)
            if semester is None:
                raise NotFoundException(f"Semester with ID {semester_id} not found")

        return await self.notes_resource_repo.search_resources(
            q=q, semester_id=semester_id, limit=limit, offset=offset
        )
