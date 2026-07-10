from tests.conftest import TEST_USER_ID
import pytest
from datetime import date
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError
from app.models.academic.semester import Semester
from app.models.academic.attendance_settings import CriteriaMode
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.services.academic.semester import SemesterService
from app.schemas.academic.semester import SemesterCreate, SemesterUpdate
from app.core.constants import DEFAULT_ATTENDANCE_GOAL
from app.core.exceptions import ConflictException, ValidationException


# ---------------------------------------------------------------------------
# Repository Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_semester_repo_create(db_session: AsyncSession):
    repo = SemesterRepository(db_session)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 30)
    )
    created = await repo.create(sem)
    await db_session.flush()

    assert created.semester_id is not None
    assert created.semester_number == 1
    assert created.start_date == date(2026, 1, 1)
    assert created.end_date == date(2026, 6, 30)


@pytest.mark.asyncio
async def test_semester_repo_unique_constraint(db_session: AsyncSession):
    repo = SemesterRepository(db_session)
    sem1 = Semester(
        user_id=TEST_USER_ID,
        semester_number=2,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 30)
    )
    sem2 = Semester(
        user_id=TEST_USER_ID,
        semester_number=2,
        start_date=date(2026, 7, 1),
        end_date=date(2026, 12, 31)
    )
    await repo.create(sem1)
    await repo.create(sem2)

    with pytest.raises(IntegrityError):
        await db_session.flush()
    await db_session.rollback()


@pytest.mark.asyncio
async def test_semester_repo_date_order_constraint(db_session: AsyncSession):
    repo = SemesterRepository(db_session)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=999,
        start_date=date(2026, 6, 30),
        end_date=date(2026, 6, 1)  # Invalid: start_date >= end_date
    )
    await repo.create(sem)
    with pytest.raises(IntegrityError):
        await db_session.flush()
    await db_session.rollback()


# ---------------------------------------------------------------------------
# Service Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_semester_service_create(db_session: AsyncSession):
    sem_repo = SemesterRepository(db_session)
    att_repo = AttendanceSettingsRepository(db_session)
    service = SemesterService(db_session, sem_repo, att_repo)

    semester_in = SemesterCreate(
        semester_number=3,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 30)
    )
    created = await service.create_semester(semester_in)

    assert created.semester_id is not None
    assert created.semester_number == 3
    # Check default attendance settings generated automatically
    assert created.attendance_settings is not None
    assert created.attendance_settings.criteria_mode == CriteriaMode.OVERALL
    assert created.attendance_settings.overall_attendance_goal == DEFAULT_ATTENDANCE_GOAL


@pytest.mark.asyncio
async def test_semester_service_duplicate_number(db_session: AsyncSession):
    sem_repo = SemesterRepository(db_session)
    att_repo = AttendanceSettingsRepository(db_session)
    service = SemesterService(db_session, sem_repo, att_repo)

    semester_in1 = SemesterCreate(
        semester_number=4,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 3, 31)
    )
    semester_in2 = SemesterCreate(
        semester_number=4,
        start_date=date(2026, 7, 1),
        end_date=date(2026, 12, 31)
    )

    await service.create_semester(semester_in1)
    with pytest.raises(ConflictException):
        await service.create_semester(semester_in2)


@pytest.mark.asyncio
async def test_semester_service_invalid_dates(db_session: AsyncSession):
    sem_repo = SemesterRepository(db_session)
    att_repo = AttendanceSettingsRepository(db_session)
    service = SemesterService(db_session, sem_repo, att_repo)

    # First create a valid semester
    semester_in = SemesterCreate(
        semester_number=5,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 30)
    )
    created = await service.create_semester(semester_in)

    # Try updating start_date to be after existing end_date (2026-06-30)
    update_in = SemesterUpdate(start_date=date(2026, 7, 1))
    with pytest.raises(ValidationException):
        await service.update_semester(created.semester_id, update_in)


@pytest.mark.asyncio
async def test_semester_service_overlapping_create(db_session: AsyncSession):
    """Creating a semester whose dates overlap an existing one must raise ConflictException."""
    sem_repo = SemesterRepository(db_session)
    att_repo = AttendanceSettingsRepository(db_session)
    service = SemesterService(db_session, sem_repo, att_repo)

    await service.create_semester(SemesterCreate(
        semester_number=20,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 5, 31)
    ))

    # Overlaps: starts before existing ends
    with pytest.raises(ConflictException, match="overlaps"):
        await service.create_semester(SemesterCreate(
            semester_number=21,
            start_date=date(2026, 3, 15),
            end_date=date(2026, 7, 30)
        ))


@pytest.mark.asyncio
async def test_semester_service_adjacent_create(db_session: AsyncSession):
    """Adjacent semesters (one ends the day the other starts) must be allowed."""
    sem_repo = SemesterRepository(db_session)
    att_repo = AttendanceSettingsRepository(db_session)
    service = SemesterService(db_session, sem_repo, att_repo)

    await service.create_semester(SemesterCreate(
        semester_number=30,
        start_date=date(2027, 1, 1),
        end_date=date(2027, 5, 31)
    ))

    # Adjacent: starts exactly when the other ends — should succeed
    created = await service.create_semester(SemesterCreate(
        semester_number=31,
        start_date=date(2027, 5, 31),
        end_date=date(2027, 10, 31)
    ))
    assert created.semester_number == 31


@pytest.mark.asyncio
async def test_semester_service_overlapping_update(db_session: AsyncSession):
    """Updating a semester's dates so they overlap another must raise ConflictException."""
    sem_repo = SemesterRepository(db_session)
    att_repo = AttendanceSettingsRepository(db_session)
    service = SemesterService(db_session, sem_repo, att_repo)

    sem_a = await service.create_semester(SemesterCreate(
        semester_number=40,
        start_date=date(2028, 1, 1),
        end_date=date(2028, 5, 31)
    ))
    await service.create_semester(SemesterCreate(
        semester_number=41,
        start_date=date(2028, 6, 1),
        end_date=date(2028, 10, 31)
    ))

    # Extend sem_a's end_date into sem 41's range
    with pytest.raises(ConflictException, match="overlaps"):
        await service.update_semester(sem_a.semester_id, SemesterUpdate(
            end_date=date(2028, 7, 1)
        ))


# ---------------------------------------------------------------------------
# API Integration Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_api_create_semester(client: AsyncClient):
    payload = {
        "semester_number": 6,
        "start_date": "2030-01-01",
        "end_date": "2030-06-30"
    }
    response = await client.post("/api/v1/academic/semesters", json=payload)
    assert response.status_code == 201

    body = response.json()
    assert body["success"] is True
    assert body["data"]["semester_number"] == 6
    assert body["data"]["attendance_settings"]["overall_attendance_goal"] == DEFAULT_ATTENDANCE_GOAL


@pytest.mark.asyncio
async def test_api_get_semester(client: AsyncClient):
    payload = {
        "semester_number": 7,
        "start_date": "2031-01-01",
        "end_date": "2031-06-30"
    }
    create_res = await client.post("/api/v1/academic/semesters", json=payload)
    sem_id = create_res.json()["data"]["semester_id"]

    get_res = await client.get(f"/api/v1/academic/semesters/{sem_id}")
    assert get_res.status_code == 200
    assert get_res.json()["success"] is True
    assert get_res.json()["data"]["semester_id"] == sem_id


@pytest.mark.asyncio
async def test_api_list_semesters(client: AsyncClient):
    await client.post("/api/v1/academic/semesters", json={
        "semester_number": 8,
        "start_date": "2032-01-01",
        "end_date": "2032-06-30"
    })

    list_res = await client.get("/api/v1/academic/semesters")
    assert list_res.status_code == 200
    assert list_res.json()["success"] is True
    assert len(list_res.json()["data"]) >= 1


@pytest.mark.asyncio
async def test_api_update_semester(client: AsyncClient):
    payload = {
        "semester_number": 9,
        "start_date": "2033-01-01",
        "end_date": "2033-06-30"
    }
    create_res = await client.post("/api/v1/academic/semesters", json=payload)
    sem_id = create_res.json()["data"]["semester_id"]

    update_res = await client.put(f"/api/v1/academic/semesters/{sem_id}", json={
        "semester_number": 10
    })
    assert update_res.status_code == 200
    assert update_res.json()["data"]["semester_number"] == 10


@pytest.mark.asyncio
async def test_api_delete_semester(client: AsyncClient):
    payload = {
        "semester_number": 11,
        "start_date": "2034-01-01",
        "end_date": "2034-06-30"
    }
    create_res = await client.post("/api/v1/academic/semesters", json=payload)
    sem_id = create_res.json()["data"]["semester_id"]

    delete_res = await client.delete(f"/api/v1/academic/semesters/{sem_id}")
    assert delete_res.status_code == 200
    assert delete_res.json()["success"] is True

    # Retrieve again should fail
    get_res = await client.get(f"/api/v1/academic/semesters/{sem_id}")
    assert get_res.status_code == 404


@pytest.mark.asyncio
async def test_api_create_overlapping_semester(client: AsyncClient):
    """API must return 409 for overlapping semester date ranges."""
    await client.post("/api/v1/academic/semesters", json={
        "semester_number": 50,
        "start_date": "2040-01-01",
        "end_date": "2040-05-31"
    })
    overlap_res = await client.post("/api/v1/academic/semesters", json={
        "semester_number": 51,
        "start_date": "2040-03-01",
        "end_date": "2040-08-31"
    })
    assert overlap_res.status_code == 409
    assert overlap_res.json()["success"] is False


@pytest.mark.asyncio
async def test_api_update_semester_dates_regenerates_instances(client: AsyncClient, db_session: AsyncSession):
    # 1. Create a semester (June 1 to June 15, 2026)
    sem_res = await client.post("/api/v1/academic/semesters", json={
        "semester_number": 99,
        "start_date": "2026-06-01",
        "end_date": "2026-06-15"
    })
    assert sem_res.status_code == 201
    sem = sem_res.json()["data"]
    sem_id = sem["semester_id"]

    # 2. Create a subject
    sub_res = await client.post("/api/v1/academic/subjects", json={
        "semester_id": sem_id,
        "subject_name": "Dynamic Sync Subject",
        "faculty_name": "Dr. Sync",
        "theme_color": "#FF0000",
        "attendance_goal": 75
    })
    assert sub_res.status_code == 201
    sub_id = sub_res.json()["data"]["subject_id"]

    # 3. Create a template for Monday (day_of_week=1, 9:00 - 10:00)
    # June 1, 2026 is Monday
    # June 8, 2026 is Monday
    # June 15, 2026 is Monday
    tmpl_res = await client.post("/api/v1/academic/lecture-templates", json={
        "subject_id": sub_id,
        "day_of_week": 1,
        "start_time": "09:00:00",
        "end_time": "10:00:00",
        "room": "Room 99"
    })
    assert tmpl_res.status_code == 201

    # 4. Verify count of instances is 3
    from app.models.academic.lecture_instance import LectureInstance
    from sqlalchemy import select, func
    res = await db_session.execute(select(func.count()).select_from(LectureInstance))
    count = res.scalar()
    assert count == 3

    # 5. Extend semester to June 25, 2026 (adds June 22, 2026 - Monday)
    update_res = await client.put(f"/api/v1/academic/semesters/{sem_id}", json={
        "end_date": "2026-06-25"
    })
    assert update_res.status_code == 200

    # Verify count is now 4
    res = await db_session.execute(select(func.count()).select_from(LectureInstance))
    count = res.scalar()
    assert count == 4

    # 6. Shrink semester to June 5 to June 15, 2026 (deletes June 1, 2026 - Monday)
    # Remaining should be: June 8, June 15 (2 instances)
    update_res = await client.put(f"/api/v1/academic/semesters/{sem_id}", json={
        "start_date": "2026-06-05",
        "end_date": "2026-06-15"
    })
    assert update_res.status_code == 200

    # Verify count is now 2
    res = await db_session.execute(select(func.count()).select_from(LectureInstance))
    count = res.scalar()
    assert count == 2


