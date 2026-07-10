import uuid
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.semester import Semester
from app.models.academic.attendance_settings import AttendanceSettings, CriteriaMode
from app.schemas.academic.semester import SemesterCreate, SemesterUpdate
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.core.constants import DEFAULT_ATTENDANCE_GOAL
from app.core.exceptions import NotFoundException, ConflictException, ValidationException


class SemesterService:
    def __init__(
        self,
        db: AsyncSession,
        semester_repo: SemesterRepository,
        attendance_repo: AttendanceSettingsRepository
    ):
        self.db = db
        self.semester_repo = semester_repo
        self.attendance_repo = attendance_repo

    async def create_semester(self, semester_in: SemesterCreate) -> Semester:
        # Validate unique semester number
        existing = await self.semester_repo.get_by_number(semester_in.semester_number)
        if existing is not None:
            raise ConflictException(f"Semester number {semester_in.semester_number} already exists")

        # Validate no date overlap with existing semesters
        overlapping = await self.semester_repo.get_overlapping(
            start_date=semester_in.start_date,
            end_date=semester_in.end_date
        )
        if overlapping is not None:
            raise ConflictException(
                f"Date range overlaps with Semester {overlapping.semester_number} "
                f"({overlapping.start_date} to {overlapping.end_date})"
            )

        # Create Semester
        semester = Semester(
            semester_number=semester_in.semester_number,
            start_date=semester_in.start_date,
            end_date=semester_in.end_date
        )
        await self.semester_repo.create(semester)
        await self.db.flush()

        # Create default Attendance Settings
        attendance_settings = AttendanceSettings(
            semester_id=semester.semester_id,
            criteria_mode=CriteriaMode.OVERALL,
            overall_attendance_goal=DEFAULT_ATTENDANCE_GOAL
        )
        await self.attendance_repo.create(attendance_settings)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SEMESTER,
            entity_id=semester.semester_id,
            action_type=ActionType.CREATED,
            activity_message=f"Created Semester {semester.semester_number}."
        )

        await self.db.commit()
        refreshed = await self.semester_repo.get_by_id(semester.semester_id)
        assert refreshed is not None
        return refreshed

    async def update_semester(self, semester_id: uuid.UUID, semester_in: SemesterUpdate) -> Semester:
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")

        # Validate unique semester number if changed
        if semester_in.semester_number is not None and semester_in.semester_number != semester.semester_number:
            existing = await self.semester_repo.get_by_number(semester_in.semester_number)
            if existing is not None:
                raise ConflictException(f"Semester number {semester_in.semester_number} already exists")
            semester.semester_number = semester_in.semester_number

        # Validate consistent dates
        new_start = semester_in.start_date if semester_in.start_date is not None else semester.start_date
        new_end = semester_in.end_date if semester_in.end_date is not None else semester.end_date
        if new_start >= new_end:
            raise ValidationException("start_date must be before end_date")

        # Validate no date overlap with other semesters (exclude current)
        if semester_in.start_date is not None or semester_in.end_date is not None:
            overlapping = await self.semester_repo.get_overlapping(
                start_date=new_start,
                end_date=new_end,
                exclude_id=semester_id
            )
            if overlapping is not None:
                raise ConflictException(
                    f"Date range overlaps with Semester {overlapping.semester_number} "
                    f"({overlapping.start_date} to {overlapping.end_date})"
                )

        dates_changed = (
            (semester_in.start_date is not None and semester_in.start_date != semester.start_date) or
            (semester_in.end_date is not None and semester_in.end_date != semester.end_date)
        )

        if semester_in.start_date is not None:
            semester.start_date = semester_in.start_date
        if semester_in.end_date is not None:
            semester.end_date = semester_in.end_date

        await self.semester_repo.update(semester)

        if dates_changed:
            from datetime import timedelta
            from sqlalchemy import select, delete
            from app.models.academic.lecture_template import LectureTemplate
            from app.models.academic.subject import Subject
            from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus
            from app.models.academic.holiday import Holiday

            # 1. Delete holidays outside the new date range
            holiday_delete_stmt = (
                delete(Holiday)
                .where(Holiday.semester_id == semester_id)
                .where(
                    (Holiday.holiday_date < new_start) |
                    (Holiday.holiday_date > new_end)
                )
            )
            await self.db.execute(holiday_delete_stmt)

            # 2. Delete lecture instances outside the new date range
            instance_delete_stmt = (
                delete(LectureInstance)
                .where(
                    LectureInstance.lecture_template_id.in_(
                        select(LectureTemplate.lecture_template_id)
                        .join(Subject)
                        .where(Subject.semester_id == semester_id)
                    )
                )
                .where(
                    (LectureInstance.lecture_date < new_start) |
                    (LectureInstance.lecture_date > new_end)
                )
            )
            await self.db.execute(instance_delete_stmt)
            await self.db.flush()

            # 3. Fetch all templates for this semester
            templates_stmt = (
                select(LectureTemplate)
                .join(Subject)
                .where(Subject.semester_id == semester_id)
            )
            templates_res = await self.db.execute(templates_stmt)
            templates = templates_res.scalars().all()

            # 4. Fetch remaining holidays
            holidays_stmt = (
                select(Holiday.holiday_date)
                .where(Holiday.semester_id == semester_id)
            )
            holidays_res = await self.db.execute(holidays_stmt)
            holiday_dates = set(holidays_res.scalars().all())

            # 5. Generate new instances for each template
            # Fetch all existing lecture dates for all templates in this semester in a single query
            existing_stmt = (
                select(LectureInstance.lecture_template_id, LectureInstance.lecture_date)
                .join(LectureTemplate)
                .join(Subject)
                .where(Subject.semester_id == semester_id)
            )
            existing_res = await self.db.execute(existing_stmt)
            from collections import defaultdict
            existing_map = defaultdict(set)
            for template_id, l_date in existing_res:
                existing_map[template_id].add(l_date)

            for template in templates:
                existing_dates = existing_map[template.lecture_template_id]
                current_date = new_start
                new_instances = []
                while current_date <= new_end:
                    if current_date.isoweekday() == template.day_of_week:
                        if current_date not in existing_dates:
                            is_holiday = current_date in holiday_dates
                            new_instances.append(
                                LectureInstance(
                                    lecture_template_id=template.lecture_template_id,
                                    lecture_date=current_date,
                                    lecture_status=LectureStatus.HOLIDAY if is_holiday else LectureStatus.SCHEDULED,
                                    attendance_status=AttendanceStatus.UNMARKED,
                                )
                            )
                    current_date += timedelta(days=1)
                
                if new_instances:
                    self.db.add_all(new_instances)

            await self.db.flush()

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SEMESTER,
            entity_id=semester.semester_id,
            action_type=ActionType.UPDATED,
            activity_message=f"Updated Semester {semester.semester_number} details."
        )

        await self.db.commit()
        refreshed = await self.semester_repo.get_by_id(semester.semester_id)
        assert refreshed is not None
        return refreshed

    async def delete_semester(self, semester_id: uuid.UUID) -> None:
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")

        # Prevent deleting the active semester
        from app.repositories.settings.app_settings import AppSettingsRepository
        from app.core.exceptions import ConflictException
        settings_repo = AppSettingsRepository(self.db)
        settings = await settings_repo.get_settings()
        if settings and settings.active_semester_id == semester_id:
            raise ConflictException("Cannot delete the active semester. Please select another active semester first.")

        await self.semester_repo.delete(semester)

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SEMESTER,
            entity_id=semester_id,
            action_type=ActionType.DELETED,
            activity_message=f"Deleted Semester {semester.semester_number}."
        )

        await self.db.commit()

    async def get_semester(self, semester_id: uuid.UUID) -> Semester:
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")
        return semester

    async def list_semesters(self) -> Sequence[Semester]:
        return await self.semester_repo.list_all()
