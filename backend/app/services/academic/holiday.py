import uuid
import logging
from datetime import date
from typing import Sequence
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.holiday import Holiday
from app.models.academic.lecture_instance import LectureStatus
from app.schemas.academic.holiday import HolidayCreate, HolidayUpdate
from app.repositories.academic.holiday import HolidayRepository
from app.repositories.academic.semester import SemesterRepository
from app.core.exceptions import NotFoundException, ConflictException, ValidationException

logger = logging.getLogger("app.services.holiday")


class HolidayService:
    """
    Holidays never create or delete lecture instances.
    They only change lecture_status.

    Holidays never modify Lecture Templates.
    They only modify Lecture Instances.
    """
    def __init__(
        self,
        db: AsyncSession,
        holiday_repo: HolidayRepository,
        semester_repo: SemesterRepository,
    ):
        self.db = db
        self.holiday_repo = holiday_repo
        self.semester_repo = semester_repo

    async def get_holiday(self, holiday_id: uuid.UUID) -> Holiday:
        holiday = await self.holiday_repo.get_by_id(holiday_id)
        if holiday is None:
            raise NotFoundException(f"Holiday with ID {holiday_id} not found")
        return holiday

    async def list_holidays(self, semester_id: uuid.UUID | None = None) -> Sequence[Holiday]:
        if semester_id is not None:
            return await self.holiday_repo.get_by_semester_id(semester_id)
        # Default to listing all holidays (optional, but good practice for API endpoint)
        from sqlalchemy import select
        stmt = select(Holiday).order_by(Holiday.holiday_date.asc())
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_calendar(self, semester_id: uuid.UUID) -> Sequence[Holiday]:
        # Validate semester exists
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")
        return await self.holiday_repo.get_by_semester_id(semester_id)

    async def create_holiday(self, semester_id: uuid.UUID, holiday_in: HolidayCreate) -> Holiday:
        # Validate parent semester exists
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")

        # Validate that the holiday date falls within the semester duration
        if holiday_in.holiday_date < semester.start_date or holiday_in.holiday_date > semester.end_date:
            raise ValidationException(
                f"Holiday date {holiday_in.holiday_date} must be within the semester duration "
                f"({semester.start_date} to {semester.end_date})"
            )

        # Validate uniqueness of the holiday date
        existing = await self.holiday_repo.get_by_date_and_semester(semester_id, holiday_in.holiday_date)
        if existing is not None:
            raise ConflictException(
                f"Holiday on date {holiday_in.holiday_date} already exists in this semester"
            )

        try:
            async with self.db.begin_nested():
                # Create Holiday
                holiday = Holiday(
                    holiday_id=holiday_in.holiday_id or uuid.uuid4(),
                    semester_id=semester_id,
                    holiday_date=holiday_in.holiday_date,
                    holiday_name=holiday_in.holiday_name,
                )
                await self.holiday_repo.create(holiday)
                await self.db.flush()

                # Bulk update matching scheduled lecture instances
                await self._update_lecture_instances_status(
                    semester_id=semester_id,
                    target_date=holiday_in.holiday_date,
                    from_status=LectureStatus.SCHEDULED,
                    to_status=LectureStatus.HOLIDAY
                )

            # Log Activity (Sprint 11)
            from app.services.activity_logs import log_activity
            from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
            await log_activity(
                db=self.db,
                actor_type=ActorType.USER,
                entity_type=EntityType.HOLIDAY,
                entity_id=holiday.holiday_id,
                action_type=ActionType.CREATED,
                activity_message=f"Created holiday '{holiday.holiday_name}' on {holiday.holiday_date}."
            )

            await self.db.commit()
            return holiday
        except Exception as e:
            logger.error("Failed to create holiday. Transaction rolled back. Error: %s", e)
            await self.db.rollback()
            raise e

    async def update_holiday(self, holiday_id: uuid.UUID, update_in: HolidayUpdate) -> Holiday:
        holiday = await self.get_holiday(holiday_id)
        semester_id = holiday.semester_id
        old_date = holiday.holiday_date

        try:
            async with self.db.begin_nested():
                if update_in.holiday_date is not None and update_in.holiday_date != old_date:
                    # Validate date falls within semester bounds
                    semester = await self.semester_repo.get_by_id(semester_id)
                    if semester is None:
                        raise NotFoundException(f"Semester with ID {semester_id} not found")

                    if update_in.holiday_date < semester.start_date or update_in.holiday_date > semester.end_date:
                        raise ValidationException(
                            f"Holiday date {update_in.holiday_date} must be within the semester duration "
                            f"({semester.start_date} to {semester.end_date})"
                        )

                    # Validate date uniqueness
                    existing = await self.holiday_repo.get_by_date_and_semester(
                        semester_id, update_in.holiday_date
                    )
                    if existing is not None:
                        raise ConflictException(
                            f"Holiday on date {update_in.holiday_date} already exists in this semester"
                        )

                    # TODO (Future):
                    # If additional modules are allowed to modify lecture_status after a Holiday is created,
                    # restore only lecture instances that were originally modified by the Holiday module,
                    # rather than restoring every lecture currently marked as holiday.

                    # 1. Restore lecture instances on the old date to scheduled (only those that are HOLIDAY)
                    await self._update_lecture_instances_status(
                        semester_id=semester_id,
                        target_date=old_date,
                        from_status=LectureStatus.HOLIDAY,
                        to_status=LectureStatus.SCHEDULED
                    )

                    # 2. Update holiday date
                    holiday.holiday_date = update_in.holiday_date

                    # 3. Apply new date: set scheduled lecture instances to holiday (resetting attendance)
                    await self._update_lecture_instances_status(
                        semester_id=semester_id,
                        target_date=update_in.holiday_date,
                        from_status=LectureStatus.SCHEDULED,
                        to_status=LectureStatus.HOLIDAY
                    )

                if update_in.holiday_name is not None:
                    holiday.holiday_name = update_in.holiday_name

                await self.holiday_repo.update(holiday)
                await self.db.flush()

            # Log Activity (Sprint 11)
            from app.services.activity_logs import log_activity
            from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
            await log_activity(
                db=self.db,
                actor_type=ActorType.USER,
                entity_type=EntityType.HOLIDAY,
                entity_id=holiday.holiday_id,
                action_type=ActionType.UPDATED,
                activity_message=f"Updated holiday '{holiday.holiday_name}' on {holiday.holiday_date}."
            )

            await self.db.commit()
            return holiday
        except Exception as e:
            logger.error("Failed to update holiday. Transaction rolled back. Error: %s", e)
            await self.db.rollback()
            raise e

    async def delete_holiday(self, holiday_id: uuid.UUID) -> None:
        holiday = await self.get_holiday(holiday_id)
        semester_id = holiday.semester_id
        holiday_date = holiday.holiday_date

        try:
            async with self.db.begin_nested():
                # TODO (Future):
                # If additional modules are allowed to modify lecture_status after a Holiday is created,
                # restore only lecture instances that were originally modified by the Holiday module,
                # rather than restoring every lecture currently marked as holiday.

                # 1. Restore matching HOLIDAY lecture instances back to SCHEDULED
                await self._update_lecture_instances_status(
                    semester_id=semester_id,
                    target_date=holiday_date,
                    from_status=LectureStatus.HOLIDAY,
                    to_status=LectureStatus.SCHEDULED
                )

                # 2. Delete holiday record
                await self.holiday_repo.delete(holiday)
                await self.db.flush()

            # Log Activity (Sprint 11)
            from app.services.activity_logs import log_activity
            from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
            await log_activity(
                db=self.db,
                actor_type=ActorType.USER,
                entity_type=EntityType.HOLIDAY,
                entity_id=holiday_id,
                action_type=ActionType.DELETED,
                activity_message=f"Deleted holiday '{holiday.holiday_name}' on {holiday_date}."
            )

            await self.db.commit()
        except Exception as e:
            logger.error("Failed to delete holiday. Transaction rolled back. Error: %s", e)
            await self.db.rollback()
            raise e

    async def _update_lecture_instances_status(
        self,
        semester_id: uuid.UUID,
        target_date: date,
        from_status: LectureStatus,
        to_status: LectureStatus,
    ) -> None:
        """
        Bulk update lecture instances' status from from_status to to_status for the given date.
        If setting to HOLIDAY, also resets attendance.
        """
        from sqlalchemy import update, select
        from app.models.academic.lecture_template import LectureTemplate
        from app.models.academic.subject import Subject
        from app.models.academic.lecture_instance import LectureInstance, AttendanceStatus

        # Find all lecture template IDs in the given semester
        template_ids_subquery = (
            select(LectureTemplate.lecture_template_id)
            .join(Subject)
            .where(Subject.semester_id == semester_id)
        )

        if to_status == LectureStatus.HOLIDAY:
            # Consolidate updates: unconditionally set lecture_status to HOLIDAY and reset attendance info
            stmt = (
                update(LectureInstance)
                .where(
                    LectureInstance.lecture_template_id.in_(template_ids_subquery),
                    LectureInstance.lecture_date == target_date,
                    LectureInstance.lecture_status == from_status,
                )
                .values(
                    lecture_status=LectureStatus.HOLIDAY,
                    attendance_status=AttendanceStatus.UNMARKED,
                    marked_by=None,
                    marked_at=None
                )
            )
            await self.db.execute(stmt)
        else:
            stmt = (
                update(LectureInstance)
                .where(
                    LectureInstance.lecture_template_id.in_(template_ids_subquery),
                    LectureInstance.lecture_date == target_date,
                    LectureInstance.lecture_status == from_status
                )
                .values(
                    lecture_status=to_status
                )
            )
            await self.db.execute(stmt)
