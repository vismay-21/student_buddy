import logging
from sqlalchemy.ext.asyncio import AsyncSession
from app.repositories.settings.app_settings import AppSettingsRepository
from app.repositories.academic.semester import SemesterRepository
from app.schemas.settings.app_settings import AppSettingsUpdate
from app.models.settings.app_settings import AppSettings
from app.core.exceptions import NotFoundException

logger = logging.getLogger(__name__)


class AppSettingsService:
    """
    App Settings store only global application preferences.
    They never store academic or attendance data.
    """
    def __init__(
        self,
        db: AsyncSession,
        settings_repo: AppSettingsRepository,
        semester_repo: SemesterRepository
    ):
        self.db = db
        self.settings_repo = settings_repo
        self.semester_repo = semester_repo

    async def get_settings(self) -> AppSettings:
        """
        Retrieve global application settings.
        Raises RuntimeError if the singleton row is missing.
        """
        settings = await self.settings_repo.get_settings()
        if settings is None:
            logger.error("App Settings singleton row is missing in the database.")
            raise RuntimeError("App Settings singleton row is missing in the database.")
        return settings

    async def update_settings(self, update_in: AppSettingsUpdate) -> AppSettings:
        """
        Update global application settings.
        Validates active semester existence if provided.
        """
        settings = await self.get_settings()
        fields_to_update = update_in.model_fields_set

        if "active_semester_id" in fields_to_update:
            semester_id = update_in.active_semester_id
            if semester_id is not None:
                semester = await self.semester_repo.get_by_id(semester_id)
                if semester is None:
                    raise NotFoundException(f"Semester with ID {semester_id} not found")
                settings.active_semester_id = semester_id
            else:
                settings.active_semester_id = None

        if "theme_mode" in fields_to_update and update_in.theme_mode is not None:
            settings.theme_mode = update_in.theme_mode

        if "finance_enabled" in fields_to_update and update_in.finance_enabled is not None:
            settings.finance_enabled = update_in.finance_enabled

        if "morning_digest_enabled" in fields_to_update and update_in.morning_digest_enabled is not None:
            settings.morning_digest_enabled = update_in.morning_digest_enabled

        if "night_digest_enabled" in fields_to_update and update_in.night_digest_enabled is not None:
            settings.night_digest_enabled = update_in.night_digest_enabled

        if "attendance_prompt_enabled" in fields_to_update and update_in.attendance_prompt_enabled is not None:
            settings.attendance_prompt_enabled = update_in.attendance_prompt_enabled

        if "notes_download_directory" in fields_to_update:
            settings.notes_download_directory = update_in.notes_download_directory

        await self.settings_repo.update(settings)

        # Log Activity (Audit 08)
        from app.core.constants import SYSTEM_SETTINGS_UUID
        from app.services.activity_logs import log_activity
        from app.models.activity_logs.activity_log import ActorType, EntityType, ActionType
        await log_activity(
            db=self.db,
            actor_type=ActorType.USER,
            entity_type=EntityType.SETTINGS,
            entity_id=SYSTEM_SETTINGS_UUID,
            action_type=ActionType.UPDATED,
            activity_message="Updated global application settings."
        )

        await self.db.commit()
        return settings
