import uuid
import logging
from datetime import date, time, timedelta
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus
from app.schemas.academic.lecture_template import LectureTemplateCreate, LectureTemplateUpdate
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.holiday import HolidayRepository
from app.core.exceptions import NotFoundException, ConflictException, ValidationException

logger = logging.getLogger("app.services.lecture_template")


class LectureTemplateService:
    def __init__(
        self,
        db: AsyncSession,
        lecture_template_repo: LectureTemplateRepository,
        lecture_instance_repo: LectureInstanceRepository,
        subject_repo: SubjectRepository,
        semester_repo: SemesterRepository,
        holiday_repo: HolidayRepository | None = None,
    ):
        self.db = db
        self.lecture_template_repo = lecture_template_repo
        self.lecture_instance_repo = lecture_instance_repo
        self.subject_repo = subject_repo
        self.semester_repo = semester_repo
        self.holiday_repo = holiday_repo or HolidayRepository(db)

    async def _validate_timetable_conflict(
        self,
        semester_id: uuid.UUID,
        day_of_week: int,
        start_time: time,
        end_time: time,
        exclude_template_id: uuid.UUID | None = None,
    ) -> None:
        """
        Enforce the timetable conflict validation rule:
        Within the same semester, two lecture templates must never overlap in time on the same weekday.
        Overlap condition: start_time_1 < end_time_2 AND start_time_2 < end_time_1
        """
        stmt = (
            select(LectureTemplate)
            .join(Subject, LectureTemplate.subject_id == Subject.subject_id)
            .where(Subject.semester_id == semester_id)
            .where(LectureTemplate.day_of_week == day_of_week)
            .options(selectinload(LectureTemplate.subject))
        )
        result = await self.db.execute(stmt)
        existing_templates = result.scalars().all()

        for ext in existing_templates:
            if exclude_template_id is not None and ext.lecture_template_id == exclude_template_id:
                continue
            # Overlap check: start_time < ext.end_time AND ext.start_time < end_time
            if start_time < ext.end_time and ext.start_time < end_time:
                raise ConflictException(
                    f"Lecture template overlaps in time with existing class '{ext.subject.subject_name}' "
                    f"({ext.start_time.strftime('%H:%M')} - {ext.end_time.strftime('%H:%M')}) on day {day_of_week}."
                )

    async def create_template(self, template_in: LectureTemplateCreate) -> LectureTemplate:
        # Validate subject exists
        subject = await self.subject_repo.get_by_id(template_in.subject_id)
        if subject is None:
            raise NotFoundException(f"Subject with ID {template_in.subject_id} not found")

        # Validate parent semester exists
        semester = await self.semester_repo.get_by_id(subject.semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {subject.semester_id} not found")

        # Validate unique schedule (subject_id, day_of_week, start_time)
        existing = await self.lecture_template_repo.get_by_schedule(
            template_in.subject_id, template_in.day_of_week, template_in.start_time
        )
        if existing is not None:
            raise ConflictException(
                f"A lecture template already exists for subject on day {template_in.day_of_week} at {template_in.start_time}"
            )

        # Timetable Conflict Validation
        await self._validate_timetable_conflict(
            semester.semester_id,
            template_in.day_of_week,
            template_in.start_time,
            template_in.end_time,
        )

        # Create lecture template
        template = LectureTemplate(
            subject_id=template_in.subject_id,
            day_of_week=template_in.day_of_week,
            start_time=template_in.start_time,
            end_time=template_in.end_time,
            room=template_in.room,
        )
        await self.lecture_template_repo.create(template)
        await self.db.flush()

        # Semester Lecture Generation
        # Holidays never create or delete lecture instances. They only change lecture_status.
        holidays = await self.holiday_repo.get_by_semester_id(semester.semester_id)
        holiday_dates = {h.holiday_date for h in holidays}

        instances = []
        current_date = semester.start_date
        while current_date <= semester.end_date:
            if current_date.isoweekday() == template.day_of_week:
                is_holiday = current_date in holiday_dates
                instances.append(
                    LectureInstance(
                        lecture_template_id=template.lecture_template_id,
                        lecture_date=current_date,
                        lecture_status=LectureStatus.HOLIDAY if is_holiday else LectureStatus.SCHEDULED,
                        attendance_status=AttendanceStatus.UNMARKED,
                    )
                )
            current_date += timedelta(days=1)

        if instances:
            await self.lecture_instance_repo.create_all(instances)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SUBJECT,
            entity_id=template.subject_id,
            action_type=ActionType.CREATED,
            activity_message=f"Created lecture template for subject '{subject.subject_name}' on day {template.day_of_week} at {template.start_time}."
        )

        await self.db.commit()

        logger.info(
            "Created LectureTemplate %s for subject %s and generated %d instances.",
            template.lecture_template_id,
            template.subject_id,
            len(instances),
        )

        refreshed = await self.lecture_template_repo.get_by_id(template.lecture_template_id)
        assert refreshed is not None
        return refreshed

    async def get_template(self, template_id: uuid.UUID) -> LectureTemplate:
        template = await self.lecture_template_repo.get_by_id(template_id)
        if template is None:
            raise NotFoundException(f"Lecture template with ID {template_id} not found")
        return template

    async def list_templates_by_subject(self, subject_id: uuid.UUID) -> Sequence[LectureTemplate]:
        subject = await self.subject_repo.get_by_id(subject_id)
        if subject is None:
            raise NotFoundException(f"Subject with ID {subject_id} not found")
        return await self.lecture_template_repo.list_by_subject(subject_id)

    async def update_template(
        self, template_id: uuid.UUID, template_in: LectureTemplateUpdate
    ) -> LectureTemplate:
        template = await self.lecture_template_repo.get_by_id(template_id)
        if template is None:
            raise NotFoundException(f"Lecture template with ID {template_id} not found")

        subject = await self.subject_repo.get_by_id(template.subject_id)
        assert subject is not None
        semester = await self.semester_repo.get_by_id(subject.semester_id)
        assert semester is not None

        old_day = template.day_of_week
        old_start = template.start_time
        old_end = template.end_time

        new_day = template_in.day_of_week if template_in.day_of_week is not None else old_day
        new_start = template_in.start_time if template_in.start_time is not None else old_start
        new_end = template_in.end_time if template_in.end_time is not None else old_end

        if new_start >= new_end:
            raise ValidationException("start_time must be strictly before end_time")

        # Validate schedule uniqueness if day or start_time is changing
        if new_day != old_day or new_start != old_start:
            existing = await self.lecture_template_repo.get_by_schedule(
                template.subject_id, new_day, new_start
            )
            if existing is not None and existing.lecture_template_id != template_id:
                raise ConflictException(
                    f"A lecture template already exists for subject on day {new_day} at {new_start}"
                )

        # Timetable Conflict Validation
        if new_day != old_day or new_start != old_start or new_end != old_end:
            await self._validate_timetable_conflict(
                semester.semester_id,
                new_day,
                new_start,
                new_end,
                exclude_template_id=template_id,
            )

        # Check if any scheduling attribute changed
        scheduling_changed = (new_day != old_day) or (new_start != old_start) or (new_end != old_end)

        # Update future scheduled unmarked instances if scheduling attributes changed
        if scheduling_changed:
            today = date.today()
            try:
                # BEGIN TRANSACTION / ATOMIC REGENERATION BLOCK
                async with self.db.begin_nested():
                    if template_in.day_of_week is not None:
                        template.day_of_week = template_in.day_of_week
                    if template_in.start_time is not None:
                        template.start_time = template_in.start_time
                    if template_in.end_time is not None:
                        template.end_time = template_in.end_time
                    if template_in.room is not None:
                        template.room = template_in.room

                    await self.lecture_template_repo.update(template)

                    await self.lecture_instance_repo.delete_future_instances(template_id, today)

                    # Fetch remaining future instances to avoid duplicate generation conflict
                    existing_instances = await self.lecture_instance_repo.list_by_template(template_id)
                    existing_dates = {inst.lecture_date for inst in existing_instances}

                    # Holidays never create or delete lecture instances. They only change lecture_status.
                    holidays = await self.holiday_repo.get_by_semester_id(semester.semester_id)
                    holiday_dates = {h.holiday_date for h in holidays}

                    generation_start = max(today + timedelta(days=1), semester.start_date)
                    instances = []
                    current_date = generation_start
                    while current_date <= semester.end_date:
                        if current_date.isoweekday() == template.day_of_week:
                            if current_date not in existing_dates:
                                is_holiday = current_date in holiday_dates
                                instances.append(
                                    LectureInstance(
                                        lecture_template_id=template.lecture_template_id,
                                        lecture_date=current_date,
                                        lecture_status=LectureStatus.HOLIDAY if is_holiday else LectureStatus.SCHEDULED,
                                        attendance_status=AttendanceStatus.UNMARKED,
                                    )
                                )
                        current_date += timedelta(days=1)

                    if instances:
                        await self.lecture_instance_repo.create_all(instances)
            except Exception as e:
                logger.error("Failed to regenerate future instances. Rolled back transaction. Error: %s", e)
                raise e

            logger.info(
                "Updated LectureTemplate %s schedule, recreated %d future instances.",
                template_id,
                len(instances),
            )
        else:
            if template_in.room is not None:
                template.room = template_in.room
            await self.lecture_template_repo.update(template)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SUBJECT,
            entity_id=template.subject_id,
            action_type=ActionType.UPDATED,
            activity_message=f"Updated lecture template for subject '{subject.subject_name}'."
        )

        await self.db.commit()

        refreshed = await self.lecture_template_repo.get_by_id(template_id)
        assert refreshed is not None
        return refreshed

    async def delete_template(self, template_id: uuid.UUID) -> None:
        template = await self.lecture_template_repo.get_by_id(template_id)
        if template is None:
            raise NotFoundException(f"Lecture template with ID {template_id} not found")

        # Get subject first so we can log it
        subject = await self.subject_repo.get_by_id(template.subject_id)
        subject_name = subject.subject_name if subject else "Unknown Subject"

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SUBJECT,
            entity_id=template.subject_id,
            action_type=ActionType.DELETED,
            activity_message=f"Deleted lecture template for subject '{subject_name}' on day {template.day_of_week} at {template.start_time}."
        )

        await self.lecture_template_repo.delete(template)
        await self.db.commit()

        logger.info("Deleted LectureTemplate %s (and all associated instances via cascade).", template_id)
