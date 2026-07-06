import pytest
import pytest_asyncio
import uuid
from datetime import date, time, datetime, timezone
from httpx import AsyncClient
from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus, MarkedBy
from app.models.academic.attendance_settings import AttendanceSettings, CriteriaMode
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.attendance_settings import AttendanceSettingsRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.services.academic.attendance_settings import AttendanceSettingsService
from app.services.academic.attendance_statistics import AttendanceStatisticsService
from app.schemas.academic.attendance_settings import AttendanceSettingsUpdate
from app.core.exceptions import NotFoundException, ValidationException


@pytest_asyncio.fixture(scope="function")
async def test_semester(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session)
    sem = Semester(
        semester_number=10,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 1, 10)
    )
    created = await semester_repo.create(sem)
    await db_session.flush()

    settings = AttendanceSettings(
        semester_id=created.semester_id,
        criteria_mode=CriteriaMode.OVERALL,
        overall_attendance_goal=75
    )
    db_session.add(settings)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_subjects(db_session: AsyncSession, test_semester: Semester) -> list[Subject]:
    subject_repo = SubjectRepository(db_session)
    sub1 = Subject(
        semester_id=test_semester.semester_id,
        subject_name="Math",
        faculty_name="Dr. Euler",
        theme_color="#0000FF",
        attendance_goal=80
    )
    sub2 = Subject(
        semester_id=test_semester.semester_id,
        subject_name="Physics",
        faculty_name="Dr. Newton",
        theme_color="#FF0000",
        attendance_goal=70
    )
    await subject_repo.create(sub1)
    await subject_repo.create(sub2)
    await db_session.flush()
    return [sub1, sub2]


# ---------------------------------------------------------------------------
# Repository Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_repo_get_and_update(db_session: AsyncSession, test_semester: Semester):
    repo = AttendanceSettingsRepository(db_session)
    settings = await repo.get_by_semester_id(test_semester.semester_id)
    assert settings is not None
    assert settings.criteria_mode == CriteriaMode.OVERALL
    assert settings.overall_attendance_goal == 75

    settings.criteria_mode = CriteriaMode.SUBJECT
    settings.overall_attendance_goal = 85
    updated = await repo.update(settings)
    await db_session.flush()

    assert updated.criteria_mode == CriteriaMode.SUBJECT
    assert updated.overall_attendance_goal == 85


# ---------------------------------------------------------------------------
# Service Validation Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_service_validation_goal_range(db_session: AsyncSession, test_semester: Semester):
    service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )

    # Goal > 100 should raise ValidationException
    with pytest.raises(ValidationException):
        await service.update_attendance_settings(
            test_semester.semester_id,
            AttendanceSettingsUpdate.model_construct(
                criteria_mode=CriteriaMode.OVERALL,
                overall_attendance_goal=101,
                model_fields_set={"criteria_mode", "overall_attendance_goal"}
            )
        )

    # Goal < 1 should raise ValidationException
    with pytest.raises(ValidationException):
        await service.update_attendance_settings(
            test_semester.semester_id,
            AttendanceSettingsUpdate.model_construct(
                criteria_mode=CriteriaMode.OVERALL,
                overall_attendance_goal=0,
                model_fields_set={"criteria_mode", "overall_attendance_goal"}
            )
        )


@pytest.mark.asyncio
async def test_service_validation_missing_goal(db_session: AsyncSession, test_semester: Semester):
    service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )

    # If updating to overall or subject mode, and the goal is None
    # We must raise ValidationException
    # First set it to custom mode (which allows goal to be None)
    await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.CUSTOM, overall_attendance_goal=None)
    )

    with pytest.raises(ValidationException):
        await service.update_attendance_settings(
            test_semester.semester_id,
            AttendanceSettingsUpdate.model_construct(
                criteria_mode=CriteriaMode.OVERALL,
                overall_attendance_goal=None,
                model_fields_set={"criteria_mode", "overall_attendance_goal"}
            )
        )


@pytest.mark.asyncio
async def test_service_custom_mode_ignores_semester_goal(db_session: AsyncSession, test_semester: Semester):
    service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )

    # Custom mode allows goal to be None
    settings = await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.CUSTOM, overall_attendance_goal=None)
    )
    assert settings.criteria_mode == CriteriaMode.CUSTOM
    assert settings.overall_attendance_goal is None


# ---------------------------------------------------------------------------
# Transition Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_service_transitions(db_session: AsyncSession, test_semester: Semester):
    service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )

    # 1. overall -> subject
    settings = await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.SUBJECT)
    )
    assert settings.criteria_mode == CriteriaMode.SUBJECT

    # 2. subject -> custom
    settings = await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.CUSTOM)
    )
    assert settings.criteria_mode == CriteriaMode.CUSTOM

    # 3. custom -> overall
    settings = await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.OVERALL, overall_attendance_goal=80)
    )
    assert settings.criteria_mode == CriteriaMode.OVERALL
    assert settings.overall_attendance_goal == 80


# ---------------------------------------------------------------------------
# Partial Update Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_service_partial_updates(db_session: AsyncSession, test_semester: Semester):
    service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )

    # Update goal only
    settings = await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(overall_attendance_goal=90)
    )
    assert settings.criteria_mode == CriteriaMode.OVERALL
    assert settings.overall_attendance_goal == 90

    # Update criteria only
    settings = await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.SUBJECT)
    )
    assert settings.criteria_mode == CriteriaMode.SUBJECT
    assert settings.overall_attendance_goal == 90


# ---------------------------------------------------------------------------
# Boundary & Stats Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_stats_semester_without_subjects(db_session: AsyncSession, test_semester: Semester):
    stats_service = AttendanceStatisticsService(
        db=db_session,
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session),
        attendance_settings_repo=AttendanceSettingsRepository(db_session)
    )

    # Semester has no subjects. Subject/Custom Mode should return aggregated 100.0% and default messages
    settings_service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )
    await settings_service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.SUBJECT)
    )

    stats = await stats_service.get_semester_attendance_stats(test_semester.semester_id)
    assert stats.total_lectures == 0
    assert stats.attendance_percentage == 100.0
    assert stats.safe_skip_count == 0
    assert stats.status_message == "can't skip next lecture"


@pytest.mark.asyncio
async def test_stats_semester_no_marked_lectures(
    db_session: AsyncSession, test_semester: Semester, test_subjects: list[Subject]
):
    stats_service = AttendanceStatisticsService(
        db=db_session,
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session),
        attendance_settings_repo=AttendanceSettingsRepository(db_session)
    )

    # Add unmarked lecture instances for both subjects
    inst1 = LectureInstance(
        lecture_template_id=None,  # Not strictly required for stats calculation helper
        lecture_date=date(2026, 1, 2),
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED
    )
    inst2 = LectureInstance(
        lecture_template_id=None,
        lecture_date=date(2026, 1, 3),
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED
    )
    # Associate by injecting subject relationships if needed, or by hacking repository get_by_subject mocks
    # Let's see: how does get_by_subject query? It uses Subject.subject_id and joins template.
    # To keep it completely standard, let's create a template for each subject and point instances to them.
    t1 = LectureTemplate(subject_id=test_subjects[0].subject_id, day_of_week=1, start_time=time(9,0), end_time=time(10,0))
    t2 = LectureTemplate(subject_id=test_subjects[1].subject_id, day_of_week=2, start_time=time(10,0), end_time=time(11,0))
    db_session.add_all([t1, t2])
    await db_session.flush()

    inst1.lecture_template_id = t1.lecture_template_id
    inst2.lecture_template_id = t2.lecture_template_id
    db_session.add_all([inst1, inst2])
    await db_session.flush()

    stats = await stats_service.get_semester_attendance_stats(test_semester.semester_id)
    assert stats.total_lectures == 2
    assert stats.present_lectures == 0
    assert stats.absent_lectures == 0
    assert stats.attendance_percentage == 100.0
    assert stats.safe_skip_count == 0


@pytest.mark.asyncio
async def test_stats_immutability_of_history(
    db_session: AsyncSession, test_semester: Semester, test_subjects: list[Subject]
):
    # Set settings, mark lectures, change settings, assert lectures have the exact same attendance status.
    t1 = LectureTemplate(subject_id=test_subjects[0].subject_id, day_of_week=1, start_time=time(9,0), end_time=time(10,0))
    db_session.add(t1)
    await db_session.flush()

    inst = LectureInstance(
        lecture_template_id=t1.lecture_template_id,
        lecture_date=date(2026, 1, 2),
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.PRESENT
    )
    db_session.add(inst)
    await db_session.flush()

    service = AttendanceSettingsService(
        db=db_session,
        attendance_repo=AttendanceSettingsRepository(db_session),
        semester_repo=SemesterRepository(db_session)
    )

    # Change settings
    await service.update_attendance_settings(
        test_semester.semester_id,
        AttendanceSettingsUpdate(criteria_mode=CriteriaMode.CUSTOM, overall_attendance_goal=None)
    )

    # Assert historical instance is completely unchanged
    inst_id = inst.lecture_instance_id
    db_session.expire(inst)
    stmt = select(LectureInstance).where(LectureInstance.lecture_instance_id == inst_id)
    res = await db_session.execute(stmt)
    refreshed_inst = res.scalar_one()
    assert refreshed_inst.attendance_status == AttendanceStatus.PRESENT


# ---------------------------------------------------------------------------
# API Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_api_get_settings_success(client: AsyncClient, test_semester: Semester):
    response = await client.get(f"/api/v1/academic/attendance-settings/{test_semester.semester_id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert data["data"]["criteria_mode"] == "overall"
    assert data["data"]["overall_attendance_goal"] == 75


@pytest.mark.asyncio
async def test_api_get_settings_not_found(client: AsyncClient):
    random_id = uuid.uuid4()
    response = await client.get(f"/api/v1/academic/attendance-settings/{random_id}")
    assert response.status_code == status.HTTP_404_NOT_FOUND
    data = response.json()
    assert data["success"] is False


@pytest.mark.asyncio
async def test_api_update_settings_success(client: AsyncClient, test_semester: Semester):
    payload = {
        "criteria_mode": "subject",
        "overall_attendance_goal": 85
    }
    response = await client.put(
        f"/api/v1/academic/attendance-settings/{test_semester.semester_id}",
        json=payload
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert data["data"]["criteria_mode"] == "subject"
    assert data["data"]["overall_attendance_goal"] == 85


@pytest.mark.asyncio
async def test_api_update_settings_validation_error(client: AsyncClient, test_semester: Semester):
    # Goal out of range
    payload = {
        "criteria_mode": "overall",
        "overall_attendance_goal": 150
    }
    response = await client.put(
        f"/api/v1/academic/attendance-settings/{test_semester.semester_id}",
        json=payload
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
