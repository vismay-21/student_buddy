import uuid
from datetime import date, datetime, timezone
from typing import Sequence

from sqlalchemy.ext.asyncio import AsyncSession
from app.core.exceptions import NotFoundException, ValidationException
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus, MarkedBy
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.schemas.academic.lecture_instance import (
    LectureInstanceUpdate,
    LectureInstanceBulkUpdate,
    LectureInstanceBulkUpdateResponse,
    AttendanceStatsResponse
)
from app.services.academic.attendance_statistics import AttendanceStatisticsService


class LectureInstanceService:
    def __init__(
        self,
        db: AsyncSession,
        lecture_instance_repo: LectureInstanceRepository,
        stats_service: AttendanceStatisticsService | None = None
    ):
        self.db = db
        self.lecture_instance_repo = lecture_instance_repo
        self.stats_service = stats_service

    async def get_instance(self, instance_id: uuid.UUID) -> LectureInstance:
        instance = await self.lecture_instance_repo.get_by_id(instance_id)
        if instance is None:
            raise NotFoundException(f"Lecture instance with ID {instance_id} not found")
        return instance

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
        return await self.lecture_instance_repo.list_instances(
            semester_id=semester_id,
            subject_id=subject_id,
            start_date=start_date,
            end_date=end_date,
            attendance_status=attendance_status,
            lecture_status=lecture_status,
            limit=limit,
            offset=offset
        )

    async def get_today_lectures(
        self, today_date: date | None = None, semester_id: uuid.UUID | None = None
    ) -> Sequence[LectureInstance]:
        query_date = today_date or date.today()
        return await self.lecture_instance_repo.get_by_date(lecture_date=query_date, semester_id=semester_id)

    async def update_attendance(self, instance_id: uuid.UUID, update_in: LectureInstanceUpdate) -> LectureInstance:
        instance = await self.lecture_instance_repo.get_by_id(instance_id)
        if instance is None:
            raise NotFoundException(f"Lecture instance with ID {instance_id} not found")

        # Business validations:
        # Holiday lectures cannot be marked Present or Absent.
        # But we do allow resetting back to Unmarked.
        target_status = update_in.attendance_status
        if target_status is not None:
            current_lecture_status = update_in.lecture_status or instance.lecture_status
            if current_lecture_status == LectureStatus.HOLIDAY:
                if target_status in [AttendanceStatus.PRESENT, AttendanceStatus.ABSENT]:
                    raise ValidationException("Cannot mark holiday lectures as present or absent.")

            instance.attendance_status = target_status
            if target_status == AttendanceStatus.UNMARKED:
                instance.marked_by = None
                instance.marked_at = None
            else:
                instance.marked_by = MarkedBy.USER
                instance.marked_at = datetime.now(timezone.utc)

        if update_in.lecture_status is not None:
            instance.lecture_status = update_in.lecture_status
            # If state is changed to holiday, reset attendance
            if update_in.lecture_status == LectureStatus.HOLIDAY:
                instance.attendance_status = AttendanceStatus.UNMARKED
                instance.marked_by = None
                instance.marked_at = None

        # Determine log details
        from app.models.activity_logs.activity_log import ActionType
        action_type = ActionType.UPDATED
        msg = f"Updated class on {instance.lecture_date}."
        if update_in.attendance_status is not None:
            if update_in.attendance_status == AttendanceStatus.PRESENT:
                action_type = ActionType.MARKED_PRESENT
                msg = f"Marked attendance as present for class on {instance.lecture_date}."
            elif update_in.attendance_status == AttendanceStatus.ABSENT:
                action_type = ActionType.MARKED_ABSENT
                msg = f"Marked attendance as absent for class on {instance.lecture_date}."
            elif update_in.attendance_status == AttendanceStatus.UNMARKED:
                msg = f"Reset attendance to unmarked for class on {instance.lecture_date}."
        elif update_in.lecture_status is not None:
            if update_in.lecture_status == LectureStatus.HOLIDAY:
                action_type = ActionType.MARKED_HOLIDAY
                msg = f"Marked class on {instance.lecture_date} as holiday."
            else:
                msg = f"Updated class status on {instance.lecture_date} to {update_in.lecture_status.value}."

        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.ATTENDANCE,
            entity_id=instance.lecture_instance_id,
            action_type=action_type,
            activity_message=msg
        )

        await self.db.commit()
        refreshed = await self.lecture_instance_repo.get_by_id(instance.lecture_instance_id)
        assert refreshed is not None
        return refreshed

    async def mark_whole_day(self, bulk_in: LectureInstanceBulkUpdate) -> LectureInstanceBulkUpdateResponse:
        # Get all instances on the date
        instances = await self.lecture_instance_repo.get_by_date(
            lecture_date=bulk_in.lecture_date,
            semester_id=bulk_in.semester_id
        )

        updated_count = 0
        skipped_count = 0

        for inst in instances:
            status_changed = False
            # 1. Update lecture_status if provided
            if bulk_in.lecture_status is not None:
                if inst.lecture_status != bulk_in.lecture_status:
                    inst.lecture_status = bulk_in.lecture_status
                    if bulk_in.lecture_status == LectureStatus.HOLIDAY:
                        inst.attendance_status = AttendanceStatus.UNMARKED
                        inst.marked_by = None
                        inst.marked_at = None
                    status_changed = True

            # 2. Update attendance_status if provided (only for scheduled instances)
            if bulk_in.attendance_status is not None:
                final_lecture_status = inst.lecture_status
                if final_lecture_status == LectureStatus.SCHEDULED:
                    if inst.attendance_status != bulk_in.attendance_status:
                        inst.attendance_status = bulk_in.attendance_status
                        if bulk_in.attendance_status == AttendanceStatus.UNMARKED:
                            inst.marked_by = None
                            inst.marked_at = None
                        else:
                            inst.marked_by = MarkedBy.USER
                            inst.marked_at = datetime.now(timezone.utc)
                        status_changed = True

            if status_changed:
                updated_count += 1
            else:
                skipped_count += 1

        # Log Activity (Sprint 11) - Single Summary Log
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        action_type = ActionType.UPDATED
        activity_parts = []
        if bulk_in.lecture_status is not None:
            activity_parts.append(f"status as {bulk_in.lecture_status.value}")
        if bulk_in.attendance_status is not None:
            activity_parts.append(f"attendance as {bulk_in.attendance_status.value}")
            if bulk_in.attendance_status == AttendanceStatus.PRESENT:
                action_type = ActionType.MARKED_PRESENT
            elif bulk_in.attendance_status == AttendanceStatus.ABSENT:
                action_type = ActionType.MARKED_ABSENT

        if not activity_parts:
            activity_msg = f"Bulk updated classes on {bulk_in.lecture_date}."
        else:
            activity_msg = f"Bulk marked {updated_count} classes on {bulk_in.lecture_date} as " + " and ".join(activity_parts) + "."

        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.ATTENDANCE,
            entity_id=bulk_in.semester_id,
            action_type=action_type,
            activity_message=activity_msg
        )

        await self.db.commit()
        return LectureInstanceBulkUpdateResponse(
            updated_count=updated_count,
            skipped_count=skipped_count
        )

    async def get_subject_attendance_stats(self, subject_id: uuid.UUID) -> AttendanceStatsResponse:
        service = self.stats_service or AttendanceStatisticsService(
            db=self.db,
            lecture_instance_repo=self.lecture_instance_repo,
            subject_repo=SubjectRepository(self.db),
            semester_repo=SemesterRepository(self.db),
            attendance_settings_repo=AttendanceSettingsRepository(self.db)
        )
        return await service.get_subject_attendance_stats(subject_id)

    async def get_semester_attendance_stats(self, semester_id: uuid.UUID) -> AttendanceStatsResponse:
        service = self.stats_service or AttendanceStatisticsService(
            db=self.db,
            lecture_instance_repo=self.lecture_instance_repo,
            subject_repo=SubjectRepository(self.db),
            semester_repo=SemesterRepository(self.db),
            attendance_settings_repo=AttendanceSettingsRepository(self.db)
        )
        return await service.get_semester_attendance_stats(semester_id)
