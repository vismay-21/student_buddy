import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity_logs.activity_log import EntityType


async def get_activity_entity_summary(
    db: AsyncSession,
    entity_type: EntityType,
    entity_id: uuid.UUID
) -> str:
    """
    Resolves the human-readable entity summary for the given entity ID and type dynamically.
    Delegates to resolvers for polymorphic entities and queries repositories for other types.
    """
    try:
        if entity_type == EntityType.TODO:
            from app.services.review_queue.resolvers.todo import TodoResolver
            return await TodoResolver(db).get_summary(entity_id)

        elif entity_type == EntityType.ATTENDANCE:
            from app.services.review_queue.resolvers.lecture_instance import LectureInstanceResolver
            return await LectureInstanceResolver(db).get_summary(entity_id)

        elif entity_type == EntityType.FINANCE:
            from app.services.review_queue.resolvers.finance import FinanceResolver
            return await FinanceResolver(db).get_summary(entity_id)

        elif entity_type == EntityType.SEMESTER:
            from app.repositories.academic.semester import SemesterRepository
            semester = await SemesterRepository(db).get_by_id(entity_id)
            if semester:
                return f"Semester {semester.semester_number}"

        elif entity_type == EntityType.SUBJECT:
            from app.repositories.academic.subject import SubjectRepository
            subject = await SubjectRepository(db).get_by_id(entity_id)
            if subject:
                return subject.subject_name

        elif entity_type == EntityType.HOLIDAY:
            from app.repositories.academic.holiday import HolidayRepository
            holiday = await HolidayRepository(db).get_by_id(entity_id)
            if holiday:
                return holiday.holiday_name

        elif entity_type == EntityType.SETTINGS:
            return "App Settings"

        elif entity_type == EntityType.REVIEW_QUEUE:
            from app.repositories.review_queue.review_queue import ReviewQueueRepository
            item = await ReviewQueueRepository(db).get_by_id(entity_id)
            if item:
                return f"Review: {item.review_message}"

        elif entity_type == EntityType.NOTES:
            from app.repositories.notes.notes import NotesResourceRepository, NotesSectionRepository
            # Check resource
            res_repo = NotesResourceRepository(db)
            resource = await res_repo.get_by_id(entity_id)
            if resource:
                return resource.resource_name
            # Check section
            sec_repo = NotesSectionRepository(db)
            section = await sec_repo.get_by_id(entity_id)
            if section:
                return section.section_name
    except Exception:
        pass

    return f"Unknown {entity_type.value.capitalize()}"
