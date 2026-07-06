import uuid
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.academic.attendance_settings import AttendanceSettings, CriteriaMode
from app.schemas.academic.attendance_settings import AttendanceSettingsUpdate
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.repositories.academic.semester import SemesterRepository
from app.core.exceptions import NotFoundException, ValidationException


class AttendanceSettingsService:
    def __init__(
        self,
        db: AsyncSession,
        attendance_repo: AttendanceSettingsRepository,
        semester_repo: SemesterRepository
    ):
        self.db = db
        self.attendance_repo = attendance_repo
        self.semester_repo = semester_repo

    async def get_settings_by_semester(self, semester_id: uuid.UUID) -> AttendanceSettings:
        # Check if semester exists first
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")
        
        settings = await self.attendance_repo.get_by_semester_id(semester_id)
        if settings is None:
            raise NotFoundException(f"Attendance settings for Semester ID {semester_id} not found")
        return settings

    async def update_attendance_settings(
        self, semester_id: uuid.UUID, update_in: AttendanceSettingsUpdate
    ) -> AttendanceSettings:
        # Check if semester exists
        semester = await self.semester_repo.get_by_id(semester_id)
        if semester is None:
            raise NotFoundException(f"Semester with ID {semester_id} not found")

        settings = await self.attendance_repo.get_by_semester_id(semester_id)
        if settings is None:
            raise NotFoundException(f"Attendance settings for Semester ID {semester_id} not found")

        # Determine target mode and goal
        target_mode = update_in.criteria_mode if update_in.criteria_mode is not None else settings.criteria_mode
        if "overall_attendance_goal" in update_in.model_fields_set:
            target_goal = update_in.overall_attendance_goal
        else:
            target_goal = settings.overall_attendance_goal

        # Validation rules:
        # - overall and subject modes require an effective semester goal.
        if target_mode in [CriteriaMode.OVERALL, CriteriaMode.SUBJECT]:
            if target_goal is None:
                raise ValidationException(
                    f"overall_attendance_goal is required when criteria_mode is '{target_mode.value}'"
                )
            if not (1 <= target_goal <= 100):
                raise ValidationException("overall_attendance_goal must be between 1 and 100")
        
        # Apply changes
        if update_in.criteria_mode is not None:
            settings.criteria_mode = update_in.criteria_mode
        if "overall_attendance_goal" in update_in.model_fields_set:
            settings.overall_attendance_goal = update_in.overall_attendance_goal

        # Update settings
        await self.attendance_repo.update(settings)
        
        # Log Activity (Sprint 11)
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SETTINGS,
            entity_id=settings.attendance_settings_id,
            action_type=ActionType.UPDATED,
            activity_message=f"Updated attendance settings (mode: {settings.criteria_mode.value}, goal: {settings.overall_attendance_goal}%)."
        )

        # TODO (Sprint 13): Mark record as pending synchronization after local update
        
        await self.db.commit()
        return settings
