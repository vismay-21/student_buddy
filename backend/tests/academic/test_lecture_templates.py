from tests.conftest import TEST_USER_ID
import pytest
import pytest_asyncio
import uuid
from unittest.mock import patch
from datetime import date, time, datetime, timedelta
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.services.academic.lecture_template import LectureTemplateService
from app.schemas.academic.lecture_template import LectureTemplateCreate, LectureTemplateUpdate
from app.core.exceptions import ConflictException, NotFoundException
from app.core.constants import DEFAULT_ATTENDANCE_GOAL


@pytest_asyncio.fixture(scope="function")
async def sample_semester(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=10,
        start_date=date(2026, 9, 1),
        end_date=date(2026, 9, 30)  # exactly 30 days
    )
    created = await semester_repo.create(sem)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def sample_subject(db_session: AsyncSession, sample_semester: Semester) -> Subject:
    subject_repo = SubjectRepository(db_session)
    sub = Subject(
        semester_id=sample_semester.semester_id,
        subject_name="Software Engineering",
        faculty_name="Dr. Winston",
        theme_color="#6A5ACD",
        attendance_goal=DEFAULT_ATTENDANCE_GOAL
    )
    created = await subject_repo.create(sub)
    await db_session.flush()
    return created


# ---------------------------------------------------------------------------
# Repository Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_lecture_template_repo_create(db_session: AsyncSession, sample_subject: Subject):
    repo = LectureTemplateRepository(db_session)
    template = LectureTemplate(
        subject_id=sample_subject.subject_id,
        day_of_week=1,  # Monday
        start_time=time(9, 0),
        end_time=time(10, 0),
        room="LH-1"
    )
    created = await repo.create(template)
    await db_session.flush()

    assert created.lecture_template_id is not None
    assert created.day_of_week == 1
    assert created.start_time == time(9, 0)
    assert created.end_time == time(10, 0)
    assert created.room == "LH-1"


@pytest.mark.asyncio
async def test_lecture_template_repo_unique_constraint(db_session: AsyncSession, sample_subject: Subject):
    repo = LectureTemplateRepository(db_session)
    template1 = LectureTemplate(
        subject_id=sample_subject.subject_id,
        day_of_week=1,
        start_time=time(9, 0),
        end_time=time(10, 0),
        room="LH-1"
    )
    await repo.create(template1)
    await db_session.flush()

    template2 = LectureTemplate(
        subject_id=sample_subject.subject_id,
        day_of_week=1,
        start_time=time(9, 0),
        end_time=time(10, 30),
        room="LH-2"
    )
    await repo.create(template2)

    with pytest.raises(IntegrityError):
        await db_session.flush()


# ---------------------------------------------------------------------------
# Service & Overlap Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_lecture_template_service_create_generates_instances(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    template_in = LectureTemplateCreate(
        subject_id=sample_subject.subject_id,
        day_of_week=1,  # Mondays
        start_time=time(9, 0),
        end_time=time(10, 0),
        room="LH-1"
    )

    template = await service.create_template(template_in)
    assert template.lecture_template_id is not None

    # Sept 1, 2026 is Tuesday.
    # Mondays: Sept 7, 14, 21, 28 (exactly 4 Mondays)
    instance_repo = LectureInstanceRepository(db_session)
    instances = await instance_repo.list_by_template(template.lecture_template_id)
    assert len(instances) == 4

    expected_dates = [date(2026, 9, 7), date(2026, 9, 14), date(2026, 9, 21), date(2026, 9, 28)]
    for inst, expected in zip(instances, expected_dates):
        assert inst.lecture_date == expected
        assert inst.lecture_status == LectureStatus.SCHEDULED
        assert inst.attendance_status == AttendanceStatus.UNMARKED


@pytest.mark.asyncio
async def test_timetable_overlap_validation_create(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # 1. Create a class from 09:00 to 10:00 on Monday (Day 1)
    await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    # 2. Try to create another class from 09:30 to 10:30 on Monday (overlaps) -> expect ConflictException
    with pytest.raises(ConflictException):
        await service.create_template(
            LectureTemplateCreate(
                subject_id=sample_subject.subject_id,
                day_of_week=1,
                start_time=time(9, 30),
                end_time=time(10, 30),
                room="LH-2"
            )
        )

    # 3. Create a class from 10:00 to 11:00 (adjacent start/end times do not overlap) -> success
    adjacent = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(10, 0),
            end_time=time(11, 0),
            room="LH-3"
        )
    )
    assert adjacent.lecture_template_id is not None


@pytest.mark.asyncio
async def test_timetable_overlap_validation_update(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # 1. Create Template A: Monday 09:00 - 10:00
    t_a = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    # 2. Create Template B: Monday 11:00 - 12:00
    t_b = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(11, 0),
            end_time=time(12, 0),
            room="LH-2"
        )
    )

    # 3. Try to update Template B to overlap with Template A (e.g., set start_time=09:30, end_time=10:30)
    with pytest.raises(ConflictException):
        await service.update_template(
            t_b.lecture_template_id,
            LectureTemplateUpdate(start_time=time(9, 30), end_time=time(10, 30))
        )


@pytest.mark.asyncio
async def test_semester_with_zero_matching_weekdays(
    db_session: AsyncSession, sample_subject: Subject
):
    # Create a very short 3-day semester: Sept 1 (Tue) to Sept 3 (Thu) 2026
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=11,
        start_date=date(2026, 9, 1),
        end_date=date(2026, 9, 3),
    )
    await semester_repo.create(sem)
    await db_session.flush()

    sub = Subject(
        semester_id=sem.semester_id,
        subject_name="Microprocessors",
        faculty_name="Dr. Winston",
        theme_color="#FF5733",
        attendance_goal=75
    )
    await SubjectRepository(db_session).create(sub)
    await db_session.flush()

    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # Create template on Monday (Day 1). Since there are no Mondays between Sept 1 and Sept 3, 0 instances should be created.
    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sub.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )
    
    instances = await LectureInstanceRepository(db_session).list_by_template(template.lecture_template_id)
    assert len(instances) == 0


@pytest.mark.asyncio
async def test_semester_boundary_generation(
    db_session: AsyncSession, sample_subject: Subject
):
    # Semester starts Monday Sept 7 and ends Monday Sept 14 (exactly 8 days)
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=12,
        start_date=date(2026, 9, 7),
        end_date=date(2026, 9, 14),
    )
    await semester_repo.create(sem)
    await db_session.flush()

    sub = Subject(
        semester_id=sem.semester_id,
        subject_name="Compiler Design",
        faculty_name="Dr. Winston",
        theme_color="#33FF57",
        attendance_goal=75
    )
    await SubjectRepository(db_session).create(sub)
    await db_session.flush()

    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # Template on Monday (Day 1)
    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sub.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    # Generation should include boundary dates Sept 7 and Sept 14 (exactly 2 instances)
    instances = await LectureInstanceRepository(db_session).list_by_template(template.lecture_template_id)
    assert len(instances) == 2
    dates = {inst.lecture_date for inst in instances}
    assert date(2026, 9, 7) in dates
    assert date(2026, 9, 14) in dates


@pytest.mark.asyncio
async def test_leap_year_generation(
    db_session: AsyncSession, sample_subject: Subject
):
    # Leap year semester: Feb 1, 2028 (Tuesday) to Feb 29, 2028 (Tuesday)
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=13,
        start_date=date(2028, 2, 1),
        end_date=date(2028, 2, 29),
    )
    await semester_repo.create(sem)
    await db_session.flush()

    sub = Subject(
        semester_id=sem.semester_id,
        subject_name="Data Structures",
        faculty_name="Dr. Winston",
        theme_color="#3357FF",
        attendance_goal=75
    )
    await SubjectRepository(db_session).create(sub)
    await db_session.flush()

    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # Template on Tuesday (Day 2)
    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sub.subject_id,
            day_of_week=2,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    # Tuesdays in Feb 2028: 1, 8, 15, 22, 29 (exactly 5 Tuesdays)
    instances = await LectureInstanceRepository(db_session).list_by_template(template.lecture_template_id)
    assert len(instances) == 5
    dates = {inst.lecture_date for inst in instances}
    assert date(2028, 2, 29) in dates


@pytest.mark.asyncio
async def test_update_only_room_does_not_regenerate(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    instance_repo = LectureInstanceRepository(db_session)
    instances_before = await instance_repo.list_by_template(template.lecture_template_id)
    assert len(instances_before) == 4

    # We patch delete_future_instances to make sure it is NOT called
    with patch.object(instance_repo, "delete_future_instances") as mock_delete:
        updated = await service.update_template(
            template.lecture_template_id,
            LectureTemplateUpdate(room="LH-2")
        )
        assert updated.room == "LH-2"
        mock_delete.assert_not_called()


@pytest.mark.asyncio
async def test_update_start_time_regenerates(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    with patch.object(service.lecture_instance_repo, "delete_future_instances", wraps=service.lecture_instance_repo.delete_future_instances) as mock_delete:
        updated = await service.update_template(
            template.lecture_template_id,
            LectureTemplateUpdate(start_time=time(9, 15))
        )
        assert updated.start_time == time(9, 15)
        mock_delete.assert_called_once()


@pytest.mark.asyncio
async def test_update_end_time_regenerates(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    with patch.object(service.lecture_instance_repo, "delete_future_instances", wraps=service.lecture_instance_repo.delete_future_instances) as mock_delete:
        updated = await service.update_template(
            template.lecture_template_id,
            LectureTemplateUpdate(end_time=time(10, 30))
        )
        assert updated.end_time == time(10, 30)
        mock_delete.assert_called_once()


@pytest.mark.asyncio
async def test_transaction_rollback_on_failed_regeneration(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    template_id = template.lecture_template_id

    # Mock create_all to raise exception during update, making regeneration fail
    with patch.object(service.lecture_instance_repo, "create_all", side_effect=Exception("DB Failure")):
        with pytest.raises(Exception, match="DB Failure"):
            await service.update_template(
                template_id,
                LectureTemplateUpdate(day_of_week=2)  # changes scheduling attribute
            )

        from sqlalchemy import select
        db_val = await db_session.scalar(
            select(LectureTemplate.day_of_week).where(LectureTemplate.lecture_template_id == template_id)
        )
        assert db_val == 1  # Should stay 1 in the database, not 2!


# ---------------------------------------------------------------------------
# API Routing Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_api_create_lecture_template(client: AsyncClient, sample_subject: Subject):
    payload = {
        "subject_id": str(sample_subject.subject_id),
        "day_of_week": 3,  # Wednesday
        "start_time": "14:15:00",
        "end_time": "15:45:00",
        "room": "Seminar Hall"
    }

    response = await client.post("/api/v1/academic/lecture-templates", json=payload)
    assert response.status_code == 201

    data = response.json()
    assert data["success"] is True
    assert data["data"]["day_of_week"] == 3
    assert data["data"]["start_time"] == "14:15:00"
    assert data["data"]["end_time"] == "15:45:00"
    assert data["data"]["room"] == "Seminar Hall"


@pytest.mark.asyncio
async def test_api_create_lecture_template_invalid_times(client: AsyncClient, sample_subject: Subject):
    payload = {
        "subject_id": str(sample_subject.subject_id),
        "day_of_week": 3,
        "start_time": "15:00:00",
        "end_time": "14:00:00",  # start_time >= end_time
        "room": "Seminar Hall"
    }

    response = await client.post("/api/v1/academic/lecture-templates", json=payload)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_api_list_lecture_templates(client: AsyncClient, sample_subject: Subject):
    # Create template
    payload = {
        "subject_id": str(sample_subject.subject_id),
        "day_of_week": 4,  # Thursday
        "start_time": "10:00:00",
        "end_time": "11:00:00",
        "room": "LH-4"
    }
    await client.post("/api/v1/academic/lecture-templates", json=payload)

    # List templates
    response = await client.get(f"/api/v1/academic/lecture-templates?subject_id={sample_subject.subject_id}")
    assert response.status_code == 200
    
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) == 1
    assert data["data"][0]["day_of_week"] == 4


@pytest.mark.asyncio
async def test_api_get_lecture_template(client: AsyncClient, sample_subject: Subject):
    payload = {
        "subject_id": str(sample_subject.subject_id),
        "day_of_week": 4,
        "start_time": "10:00:00",
        "end_time": "11:00:00",
        "room": "LH-4"
    }
    create_res = await client.post("/api/v1/academic/lecture-templates", json=payload)
    template_id = create_res.json()["data"]["lecture_template_id"]

    response = await client.get(f"/api/v1/academic/lecture-templates/{template_id}")
    assert response.status_code == 200

    data = response.json()
    assert data["success"] is True
    assert data["data"]["lecture_template_id"] == template_id


@pytest.mark.asyncio
async def test_api_update_lecture_template(client: AsyncClient, sample_subject: Subject):
    payload = {
        "subject_id": str(sample_subject.subject_id),
        "day_of_week": 4,
        "start_time": "10:00:00",
        "end_time": "11:00:00",
        "room": "LH-4"
    }
    create_res = await client.post("/api/v1/academic/lecture-templates", json=payload)
    template_id = create_res.json()["data"]["lecture_template_id"]

    update_payload = {
        "room": "LH-10",
        "start_time": "10:15:00"
    }
    response = await client.put(f"/api/v1/academic/lecture-templates/{template_id}", json=update_payload)
    assert response.status_code == 200

    data = response.json()
    assert data["success"] is True
    assert data["data"]["room"] == "LH-10"
    assert data["data"]["start_time"] == "10:15:00"


@pytest.mark.asyncio
async def test_api_delete_lecture_template(client: AsyncClient, sample_subject: Subject):
    payload = {
        "subject_id": str(sample_subject.subject_id),
        "day_of_week": 4,
        "start_time": "10:00:00",
        "end_time": "11:00:00",
        "room": "LH-4"
    }
    create_res = await client.post("/api/v1/academic/lecture-templates", json=payload)
    template_id = create_res.json()["data"]["lecture_template_id"]

    response = await client.delete(f"/api/v1/academic/lecture-templates/{template_id}")
    assert response.status_code == 200

    # Try to GET it and assert 404
    get_res = await client.get(f"/api/v1/academic/lecture-templates/{template_id}")
    assert get_res.status_code == 404


@pytest.mark.asyncio
async def test_update_template_conflict_with_retained_instance(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # Create template: Monday 09:00 - 10:00
    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    # Fetch future generated instances
    instance_repo = LectureInstanceRepository(db_session)
    instances = await instance_repo.list_by_template(template.lecture_template_id)
    assert len(instances) > 0

    # Mark one of the instances as present (simulate user action) so it is retained during rescheduling
    retained_instance = instances[-1]
    retained_instance.attendance_status = AttendanceStatus.PRESENT
    await instance_repo.update(retained_instance)
    await db_session.flush()

    # Now update template schedule (start_time to 09:15)
    # Without the fix, this would fail due to UniqueConstraint violation on the retained instance's date.
    updated = await service.update_template(
        template.lecture_template_id,
        LectureTemplateUpdate(start_time=time(9, 15))
    )
    assert updated.start_time == time(9, 15)


@pytest.mark.asyncio
async def test_update_template_time_inversion(
    db_session: AsyncSession, sample_semester: Semester, sample_subject: Subject
):
    service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session, TEST_USER_ID),
    )

    # Create template: Monday 09:00 - 10:00
    template = await service.create_template(
        LectureTemplateCreate(
            subject_id=sample_subject.subject_id,
            day_of_week=1,
            start_time=time(9, 0),
            end_time=time(10, 0),
            room="LH-1"
        )
    )

    # Try updating only start_time to 11:00 (which is after end_time 10:00) -> expect ValidationException
    from app.core.exceptions import ValidationException
    with pytest.raises(ValidationException):
        await service.update_template(
            template.lecture_template_id,
            LectureTemplateUpdate(start_time=time(11, 0))
        )

