import pytest
import pytest_asyncio
import uuid
from datetime import date
from httpx import AsyncClient
from fastapi import status
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.semester import Semester
from app.models.settings.app_settings import AppSettings, ThemeMode
from app.repositories.academic.semester import SemesterRepository
from app.services.academic.semester import SemesterService
from app.repositories.settings.app_settings import AppSettingsRepository
from app.services.settings.app_settings import AppSettingsService


@pytest_asyncio.fixture(scope="function")
async def test_semester(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session)
    sem = Semester(
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 1, 15)
    )
    created = await semester_repo.create(sem)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def settings_service(db_session: AsyncSession) -> AppSettingsService:
    from app.repositories.settings.app_settings import AppSettingsRepository
    from app.repositories.academic.semester import SemesterRepository
    return AppSettingsService(
        db=db_session,
        settings_repo=AppSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )


@pytest.mark.asyncio
async def test_seeding_verification(db_session: AsyncSession):
    # Verify that the singleton settings row exists (seeded via migration)
    stmt = select(AppSettings).where(AppSettings.settings_id == 1)
    result = await db_session.execute(stmt)
    settings = result.scalar_one_or_none()
    assert settings is not None
    assert settings.settings_id == 1
    assert settings.theme_mode == ThemeMode.SYSTEM
    assert settings.finance_enabled is False
    assert settings.morning_digest_enabled is True
    assert settings.night_digest_enabled is True
    assert settings.attendance_prompt_enabled is True
    assert settings.notes_download_directory is None


@pytest.mark.asyncio
async def test_get_settings_api(client: AsyncClient):
    response = await client.get("/api/v1/app-settings")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert data["data"]["settings_id"] == 1
    assert data["data"]["theme_mode"] == "system"


@pytest.mark.asyncio
async def test_update_settings_multiple_fields(client: AsyncClient):
    payload = {
        "theme_mode": "dark",
        "finance_enabled": True,
        "morning_digest_enabled": False,
        "notes_download_directory": "/my/custom/path/"
    }
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert data["theme_mode"] == "dark"
    assert data["finance_enabled"] is True
    assert data["morning_digest_enabled"] is False
    assert data["notes_download_directory"] == "/my/custom/path"


@pytest.mark.asyncio
async def test_partial_update(client: AsyncClient):
    # Perform update of single field
    payload = {
        "finance_enabled": True
    }
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert data["finance_enabled"] is True
    # Verify other fields are unaffected (defaults remain)
    assert data["theme_mode"] == "system"
    assert data["morning_digest_enabled"] is True


@pytest.mark.asyncio
async def test_theme_casing_normalization(client: AsyncClient):
    # Test uppercase and trailing spaces
    payload = {
        "theme_mode": "  LIGHT  "
    }
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert data["theme_mode"] == "light"


@pytest.mark.asyncio
async def test_path_normalization(client: AsyncClient):
    payload = {
        "notes_download_directory": "  /folder/subfolder/../another/  "
    }
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    # Path should be stripped and normalized
    assert data["notes_download_directory"] == "/folder/another"


@pytest.mark.asyncio
async def test_active_semester_clear_and_set(client: AsyncClient, test_semester: Semester):
    # 1. Set active semester to our test semester
    payload = {
        "active_semester_id": str(test_semester.semester_id)
    }
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()["data"]
    assert data["active_semester_id"] == str(test_semester.semester_id)

    # 2. Clear active semester by setting it to null
    payload_clear = {
        "active_semester_id": None
    }
    response_clear = await client.put("/api/v1/app-settings", json=payload_clear)
    assert response_clear.status_code == status.HTTP_200_OK
    data_clear = response_clear.json()["data"]
    assert data_clear["active_semester_id"] is None


@pytest.mark.asyncio
async def test_active_semester_invalid_uuid(client: AsyncClient):
    # Invalid UUID format
    payload = {
        "active_semester_id": "not-a-valid-uuid"
    }
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_CONTENT

    # Valid UUID structure but non-existent semester
    random_uuid = str(uuid.uuid4())
    payload_non_existent = {
        "active_semester_id": random_uuid
    }
    response_non_existent = await client.put("/api/v1/app-settings", json=payload_non_existent)
    assert response_non_existent.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.asyncio
async def test_delete_active_semester_protection(
    db_session: AsyncSession,
    settings_service: AppSettingsService,
    test_semester: Semester
):
    from app.core.exceptions import ConflictException
    from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
    # Create SemesterService
    sem_service = SemesterService(
        db=db_session,
        semester_repo=SemesterRepository(db_session),
        attendance_repo=AttendanceSettingsRepository(db_session)
    )

    # Make the semester active
    from app.schemas.settings.app_settings import AppSettingsUpdate
    await settings_service.update_settings(AppSettingsUpdate(active_semester_id=test_semester.semester_id))

    # Try deleting active semester - should raise ConflictException
    with pytest.raises(ConflictException) as exc_info:
        await sem_service.delete_semester(test_semester.semester_id)
    assert "Cannot delete the active semester" in str(exc_info.value)

    # Deactive the semester
    await settings_service.update_settings(AppSettingsUpdate(active_semester_id=None))

    # Now delete should succeed
    await sem_service.delete_semester(test_semester.semester_id)


@pytest.mark.asyncio
async def test_singleton_row_missing(db_session: AsyncSession, client: AsyncClient):
    # 1. Delete singleton row from database
    await db_session.execute(delete(AppSettings))
    await db_session.flush()

    # 2. Verify API returns 500
    response = await client.get("/api/v1/app-settings")
    assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
    assert "missing" in response.json()["detail"]

    # 3. Verify updating also fails with 500
    payload = {"theme_mode": "dark"}
    response_put = await client.put("/api/v1/app-settings", json=payload)
    assert response_put.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR


@pytest.mark.asyncio
async def test_update_settings_creates_activity_log(client: AsyncClient, db_session: AsyncSession):
    from app.core.constants import SYSTEM_SETTINGS_UUID
    from app.models.activity_logs.activity_log import ActivityLog, EntityType, ActionType
    from sqlalchemy import select

    # 1. Update settings
    payload = {"theme_mode": "dark"}
    response = await client.put("/api/v1/app-settings", json=payload)
    assert response.status_code == status.HTTP_200_OK

    # 2. Query ActivityLog directly
    stmt = select(ActivityLog).where(
        ActivityLog.entity_type == EntityType.SETTINGS,
        ActivityLog.entity_id == SYSTEM_SETTINGS_UUID,
        ActivityLog.action_type == ActionType.UPDATED
    )
    result = await db_session.execute(stmt)
    logs = result.scalars().all()
    assert len(logs) > 0
    assert logs[0].activity_message == "Updated global application settings."

