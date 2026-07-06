import uuid
import logging
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.subject import Subject
from app.models.notes.notes_subject import NotesSubject
from app.schemas.academic.subject import SubjectCreate, SubjectUpdate
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.core.exceptions import NotFoundException, ConflictException

logger = logging.getLogger("app.services.subject")


class SubjectService:
    def __init__(
        self,
        db: AsyncSession,
        subject_repo: SubjectRepository,
        semester_repo: SemesterRepository,
        notes_subject_repo: NotesSubjectRepository,
    ):
        self.db = db
        self.subject_repo = subject_repo
        self.semester_repo = semester_repo
        self.notes_subject_repo = notes_subject_repo

    async def create_subject(self, subject_in: SubjectCreate) -> Subject:
        # Validate parent semester exists
        semester = await self.semester_repo.get_by_id(subject_in.semester_id)
        if semester is None:
            raise NotFoundException(
                f"Semester with ID {subject_in.semester_id} not found"
            )

        # Validate unique subject name within semester
        existing = await self.subject_repo.get_by_name_in_semester(
            subject_in.semester_id, subject_in.subject_name
        )
        if existing is not None:
            raise ConflictException(
                f"Subject '{subject_in.subject_name}' already exists in this semester"
            )

        # Create subject
        subject = Subject(
            semester_id=subject_in.semester_id,
            subject_name=subject_in.subject_name,
            faculty_name=subject_in.faculty_name,
            theme_color=subject_in.theme_color,
            attendance_goal=subject_in.attendance_goal,
        )
        await self.subject_repo.create(subject)
        await self.db.flush()

        # Automatically create corresponding Notes Subject
        notes_subject = NotesSubject(
            semester_id=subject_in.semester_id,
            notes_subject_name=subject_in.subject_name,
        )
        await self.notes_subject_repo.create(notes_subject)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SUBJECT,
            entity_id=subject.subject_id,
            action_type=ActionType.CREATED,
            activity_message=f"Created subject {subject.subject_name}."
        )

        await self.db.commit()

        logger.info(
            "Created subject '%s' (ID: %s) and corresponding notes_subject",
            subject.subject_name,
            subject.subject_id,
        )

        refreshed = await self.subject_repo.get_by_id(subject.subject_id)
        assert refreshed is not None
        return refreshed

    async def update_subject(
        self, subject_id: uuid.UUID, subject_in: SubjectUpdate
    ) -> Subject:
        subject = await self.subject_repo.get_by_id(subject_id)
        if subject is None:
            raise NotFoundException(f"Subject with ID {subject_id} not found")

        old_name = subject.subject_name

        # If subject_name is changing, validate uniqueness
        if (
            subject_in.subject_name is not None
            and subject_in.subject_name != subject.subject_name
        ):
            existing = await self.subject_repo.get_by_name_in_semester(
                subject.semester_id, subject_in.subject_name
            )
            if existing is not None:
                raise ConflictException(
                    f"Subject '{subject_in.subject_name}' already exists in this semester"
                )
            subject.subject_name = subject_in.subject_name

        if subject_in.faculty_name is not None:
            subject.faculty_name = subject_in.faculty_name
        if subject_in.theme_color is not None:
            subject.theme_color = subject_in.theme_color
        if subject_in.attendance_goal is not None:
            subject.attendance_goal = subject_in.attendance_goal

        await self.subject_repo.update(subject)

        # If name changed, update matching notes_subject
        if subject.subject_name != old_name:
            await self.notes_subject_repo.update_name(
                subject.semester_id, old_name, subject.subject_name
            )
            logger.info(
                "Renamed notes_subject '%s' → '%s' for semester %s",
                old_name,
                subject.subject_name,
                subject.semester_id,
            )

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SUBJECT,
            entity_id=subject.subject_id,
            action_type=ActionType.UPDATED,
            activity_message=f"Updated subject {subject.subject_name} details."
        )

        await self.db.commit()

        refreshed = await self.subject_repo.get_by_id(subject.subject_id)
        assert refreshed is not None
        return refreshed

    async def delete_subject(
        self,
        subject_id: uuid.UUID,
        delete_notes_subject: bool = False,
    ) -> None:
        subject = await self.subject_repo.get_by_id(subject_id)
        if subject is None:
            raise NotFoundException(f"Subject with ID {subject_id} not found")

        subject_name = subject.subject_name
        semester_id = subject.semester_id

        await self.subject_repo.delete(subject)

        # Optionally delete the matching notes_subject
        if delete_notes_subject:
            deleted = await self.notes_subject_repo.delete_by_name_in_semester(
                semester_id, subject_name
            )
            if deleted:
                logger.info(
                    "Deleted notes_subject '%s' for semester %s",
                    subject_name,
                    semester_id,
                )

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SUBJECT,
            entity_id=subject_id,
            action_type=ActionType.DELETED,
            activity_message=f"Deleted subject {subject_name}."
        )

        await self.db.commit()

        logger.info(
            "Deleted subject '%s' (ID: %s)",
            subject_name,
            subject_id,
        )

    async def get_subject(self, subject_id: uuid.UUID) -> Subject:
        subject = await self.subject_repo.get_by_id(subject_id)
        if subject is None:
            raise NotFoundException(f"Subject with ID {subject_id} not found")
        return subject

    async def list_subjects(self, semester_id: uuid.UUID) -> Sequence[Subject]:
        # Validate semester exists
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(
                f"Semester with ID {semester_id} not found"
            )
        return await self.subject_repo.list_by_semester(semester_id)
