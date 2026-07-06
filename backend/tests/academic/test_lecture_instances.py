import pytest
import pytest_asyncio
import uuid
from datetime import date, time, datetime, timedelta, timezone
from httpx import AsyncClient
from fastapi import status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.academic.lecture_instance import (
    LectureInstanceUpdate,
    LectureInstanceBulkUpdate,
    LectureInstanceBulkUpdateResponse,
    AttendanceStatsResponse
)

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus, MarkedBy
from app.models.academic.attendance_settings import AttendanceSettings, CriteriaMode
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.services.academic.lecture_instance import LectureInstanceService
from app.core.exceptions import NotFoundException, ValidationException
from app.core.constants import DEFAULT_ATTENDANCE_GOAL


@pytest_asyncio.fixture(scope="function")
async def test_semester(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session)
    sem = Semester(
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 1, 31)
    )
    created = await semester_repo.create(sem)
    await db_session.flush()
    
    # Create default attendance settings
    settings = AttendanceSettings(
        semester_id=created.semester_id,
        criteria_mode=CriteriaMode.OVERALL,
        overall_attendance_goal=75
    )
    db_session.add(settings)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_subject(db_session: AsyncSession, test_semester: Semester) -> Subject:
    subject_repo = SubjectRepository(db_session)
    sub = Subject(
        semester_id=test_semester.semester_id,
        subject_name="Database Systems",
        faculty_name="Prof. Alice",
        theme_color="#FF5733",
        attendance_goal=75
    )
    created = await subject_repo.create(sub)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_template(db_session: AsyncSession, test_subject: Subject) -> LectureTemplate:
    template_repo = LectureTemplateRepository(db_session)
    temp = LectureTemplate(
        subject_id=test_subject.subject_id,
        day_of_week=1,  # Monday
        start_time=time(9, 0),
        end_time=time(10, 0),
        room="LH-101"
    )
    created = await template_repo.create(temp)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def sample_instances(
    db_session: AsyncSession, test_template: LectureTemplate
) -> list[LectureInstance]:
    repo = LectureInstanceRepository(db_session)
    insts = [
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 5),  # Monday
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.PRESENT,
            marked_by=MarkedBy.USER,
            marked_at=datetime.now(timezone.utc)
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 12),  # Monday
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.ABSENT,
            marked_by=MarkedBy.USER,
            marked_at=datetime.now(timezone.utc)
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 19),  # Monday
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.UNMARKED,
            marked_by=None,
            marked_at=None
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 26),  # Monday
            lecture_status=LectureStatus.CANCELLED,
            attendance_status=AttendanceStatus.UNMARKED,
            marked_by=None,
            marked_at=None
        )
    ]
    created = await repo.create_all(insts)
    await db_session.flush()
    return created


# ===========================================================================
# Repository Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_repo_get_by_id(db_session: AsyncSession, sample_instances: list[LectureInstance]):
    repo = LectureInstanceRepository(db_session)
    instance_id = sample_instances[0].lecture_instance_id
    inst = await repo.get_by_id(instance_id)
    assert inst is not None
    assert inst.lecture_instance_id == instance_id
    assert inst.lecture_template is not None
    assert inst.lecture_template.subject is not None
    assert inst.lecture_template.subject.subject_name == "Database Systems"


@pytest.mark.asyncio
async def test_repo_get_by_date(
    db_session: AsyncSession, test_semester: Semester, sample_instances: list[LectureInstance]
):
    repo = LectureInstanceRepository(db_session)
    insts = await repo.get_by_date(lecture_date=date(2026, 1, 5), semester_id=test_semester.semester_id)
    assert len(insts) == 1
    assert insts[0].lecture_date == date(2026, 1, 5)


@pytest.mark.asyncio
async def test_repo_get_by_subject(
    db_session: AsyncSession, test_subject: Subject, sample_instances: list[LectureInstance]
):
    repo = LectureInstanceRepository(db_session)
    insts = await repo.get_by_subject(
        subject_id=test_subject.subject_id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 1, 15)
    )
    assert len(insts) == 2
    # Ordered asc by date
    assert insts[0].lecture_date == date(2026, 1, 5)
    assert insts[1].lecture_date == date(2026, 1, 12)


@pytest.mark.asyncio
async def test_repo_list_instances(
    db_session: AsyncSession, test_semester: Semester, sample_instances: list[LectureInstance]
):
    repo = LectureInstanceRepository(db_session)
    insts = await repo.list_instances(
        semester_id=test_semester.semester_id,
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.PRESENT
    )
    assert len(insts) == 1
    assert insts[0].lecture_date == date(2026, 1, 5)


# ===========================================================================
# Service Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_service_get_instance_not_found(db_session: AsyncSession):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)
    with pytest.raises(NotFoundException):
        await service.get_instance(uuid.uuid4())


@pytest.mark.asyncio
async def test_service_update_attendance_valid(db_session: AsyncSession, sample_instances: list[LectureInstance]):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)
    inst = sample_instances[2]  # Unmarked scheduled instance

    updated = await service.update_attendance(
        inst.lecture_instance_id,
        LectureInstanceUpdate(attendance_status=AttendanceStatus.PRESENT)
    )
    assert updated.attendance_status == AttendanceStatus.PRESENT
    assert updated.marked_by == MarkedBy.USER
    assert updated.marked_at is not None


@pytest.mark.asyncio
async def test_service_update_attendance_reset_unmarked(db_session: AsyncSession, sample_instances: list[LectureInstance]):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)
    inst = sample_instances[0]  # Present marked instance

    updated = await service.update_attendance(
        inst.lecture_instance_id,
        LectureInstanceUpdate(attendance_status=AttendanceStatus.UNMARKED)
    )
    assert updated.attendance_status == AttendanceStatus.UNMARKED
    assert updated.marked_by is None
    assert updated.marked_at is None


@pytest.mark.asyncio
async def test_service_update_attendance_rejects_on_cancelled_or_holiday(
    db_session: AsyncSession, sample_instances: list[LectureInstance]
):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)
    cancelled_inst = sample_instances[3]  # Cancelled

    with pytest.raises(ValidationException):
        await service.update_attendance(
            cancelled_inst.lecture_instance_id,
            LectureInstanceUpdate(attendance_status=AttendanceStatus.PRESENT)
        )


@pytest.mark.asyncio
async def test_service_update_status_resets_attendance(
    db_session: AsyncSession, sample_instances: list[LectureInstance]
):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)
    inst = sample_instances[0]  # Present

    updated = await service.update_attendance(
        inst.lecture_instance_id,
        LectureInstanceUpdate(lecture_status=LectureStatus.CANCELLED)
    )
    assert updated.lecture_status == LectureStatus.CANCELLED
    assert updated.attendance_status == AttendanceStatus.UNMARKED
    assert updated.marked_by is None
    assert updated.marked_at is None


@pytest.mark.asyncio
async def test_service_mark_whole_day(
    db_session: AsyncSession, test_semester: Semester, sample_instances: list[LectureInstance]
):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)

    # Date 2026-01-26 has one cancelled class (sample_instances[3])
    # Let's add a scheduled unmarked class on 2026-01-26
    new_inst = LectureInstance(
        lecture_template_id=sample_instances[3].lecture_template_id,
        lecture_date=date(2026, 1, 26),
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED
    )
    db_session.add(new_inst)
    await db_session.flush()

    bulk_in = LectureInstanceBulkUpdate(
        lecture_date=date(2026, 1, 26),
        attendance_status=AttendanceStatus.PRESENT,
        semester_id=test_semester.semester_id
    )
    res = await service.mark_whole_day(bulk_in)
    
    assert res.updated_count == 1  # only new_inst is scheduled
    assert res.skipped_count == 1  # sample_instances[3] is cancelled
    
    # Reload new_inst and verify
    await db_session.refresh(new_inst)
    assert new_inst.attendance_status == AttendanceStatus.PRESENT


@pytest.mark.asyncio
async def test_service_runtime_stats_can_skip(
    db_session: AsyncSession, test_subject: Subject, test_template: LectureTemplate
):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)

    # Goal is 75%. If we have 4 present out of 4, we can skip classes.
    # Present count: 4, Absent: 0, Goal: 75%
    # k <= (100 * P - G * T) / G = (400 - 300) / 75 = 100 / 75 = 1.33 -> 1 class.
    insts = [
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 5) + timedelta(days=7 * i),
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.PRESENT
        )
        for i in range(4)
    ]
    await repo.create_all(insts)
    await db_session.flush()

    stats = await service.get_subject_attendance_stats(test_subject.subject_id)
    assert stats.total_lectures == 4
    assert stats.present_lectures == 4
    assert stats.absent_lectures == 0
    assert stats.attendance_percentage == 100.0
    assert stats.safe_skip_count == 1
    assert stats.status_message == "can skip 1 lectures"


@pytest.mark.asyncio
async def test_service_runtime_stats_cant_skip(
    db_session: AsyncSession, test_subject: Subject, test_template: LectureTemplate
):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)

    # Goal is 75%. If we have 3 present, 1 absent (total 4), attendance is 75%.
    # k <= (100 * 3 - 75 * 4) / 75 = (300 - 300) / 75 = 0.
    insts = [
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 5),
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.ABSENT
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 12),
            attendance_status=AttendanceStatus.PRESENT
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 19),
            attendance_status=AttendanceStatus.PRESENT
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 26),
            attendance_status=AttendanceStatus.PRESENT
        )
    ]
    await repo.create_all(insts)
    await db_session.flush()

    stats = await service.get_subject_attendance_stats(test_subject.subject_id)
    assert stats.attendance_percentage == 75.0
    assert stats.safe_skip_count == 0
    assert stats.status_message == "can't skip next lecture"


@pytest.mark.asyncio
async def test_service_runtime_stats_need_attend(
    db_session: AsyncSession, test_subject: Subject, test_template: LectureTemplate
):
    repo = LectureInstanceRepository(db_session)
    service = LectureInstanceService(db_session, repo)

    # Goal is 75%. If we have 1 present, 2 absent (total 3), attendance is 33.3%.
    # m >= (75 * 3 - 100 * 1) / 25 = 125 / 25 = 5.
    insts = [
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 5),
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.ABSENT
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 12),
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.ABSENT
        ),
        LectureInstance(
            lecture_template_id=test_template.lecture_template_id,
            lecture_date=date(2026, 1, 19),
            lecture_status=LectureStatus.SCHEDULED,
            attendance_status=AttendanceStatus.PRESENT
        )
    ]
    await repo.create_all(insts)
    await db_session.flush()

    stats = await service.get_subject_attendance_stats(test_subject.subject_id)
    assert stats.safe_skip_count == 0
    assert stats.status_message == "need to attend next 5 lectures"


# ===========================================================================
# API Integration Tests
# ===========================================================================

@pytest.mark.asyncio
async def test_api_list_instances(
    client: AsyncClient, test_semester: Semester, sample_instances: list[LectureInstance]
):
    response = await client.get(f"/api/v1/academic/lecture-instances?semester_id={test_semester.semester_id}")
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert len(body["data"]) == 4


@pytest.mark.asyncio
async def test_api_get_today(
    client: AsyncClient, test_semester: Semester, sample_instances: list[LectureInstance]
):
    response = await client.get(
        f"/api/v1/academic/lecture-instances/today?date=2026-01-05&semester_id={test_semester.semester_id}"
    )
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert len(body["data"]) == 1
    assert body["data"][0]["lecture_date"] == "2026-01-05"


@pytest.mark.asyncio
async def test_api_get_by_id(client: AsyncClient, sample_instances: list[LectureInstance]):
    inst_id = sample_instances[0].lecture_instance_id
    response = await client.get(f"/api/v1/academic/lecture-instances/{inst_id}")
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert body["data"]["lecture_instance_id"] == str(inst_id)


@pytest.mark.asyncio
async def test_api_update_attendance(client: AsyncClient, sample_instances: list[LectureInstance]):
    inst_id = sample_instances[2].lecture_instance_id  # scheduled unmarked
    response = await client.put(
        f"/api/v1/academic/lecture-instances/{inst_id}",
        json={"attendance_status": "present"}
    )
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert body["data"]["attendance_status"] == "present"


@pytest.mark.asyncio
async def test_api_mark_whole_day(
    client: AsyncClient, test_semester: Semester, sample_instances: list[LectureInstance]
):
    response = await client.put(
        "/api/v1/academic/lecture-instances/day",
        json={
            "lecture_date": "2026-01-19",
            "attendance_status": "absent",
            "semester_id": str(test_semester.semester_id)
        }
    )
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert body["data"]["updated_count"] == 1
    assert body["data"]["skipped_count"] == 0


@pytest.mark.asyncio
async def test_api_stats_subject(client: AsyncClient, test_subject: Subject, sample_instances: list[LectureInstance]):
    response = await client.get(f"/api/v1/academic/lecture-instances/stats/subject/{test_subject.subject_id}")
    assert response.status_code == status.HTTP_200_OK
    body = response.json()
    assert body["success"] is True
    assert "attendance_percentage" in body["data"]
    assert "safe_skip_count" in body["data"]
    assert "status_message" in body["data"]
