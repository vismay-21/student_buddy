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
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus
from app.models.academic.holiday import Holiday
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.holiday import HolidayRepository
from app.services.academic.holiday import HolidayService
from app.core.exceptions import NotFoundException, ValidationException, ConflictException
from app.schemas.academic.holiday import HolidayCreate, HolidayUpdate


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
async def test_subject(db_session: AsyncSession, test_semester: Semester) -> Subject:
    subject_repo = SubjectRepository(db_session)
    sub = Subject(
        semester_id=test_semester.semester_id,
        subject_name="Computer Science",
        faculty_name="Dr. Turing",
        theme_color="#4B0082",
        attendance_goal=75
    )
    created = await subject_repo.create(sub)
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def test_lecture_template(
    db_session: AsyncSession, test_subject: Subject
) -> LectureTemplate:
    # Friday is weekday 5. Let's schedule it at 10:00 - 11:00.
    template_repo = LectureTemplateRepository(db_session)
    template = LectureTemplate(
        subject_id=test_subject.subject_id,
        day_of_week=5,
        start_time=time(10, 0),
        end_time=time(11, 0),
        room="Lab 3"
    )
    created = await template_repo.create(template)
    await db_session.flush()

    # Generate instances manually for Friday Jan 2nd and Jan 9th
    lecture_instance_repo = LectureInstanceRepository(db_session)
    inst1 = LectureInstance(
        lecture_template_id=created.lecture_template_id,
        lecture_date=date(2026, 1, 2),  # Friday
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED,
    )
    inst2 = LectureInstance(
        lecture_template_id=created.lecture_template_id,
        lecture_date=date(2026, 1, 9),  # Friday
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED,
    )
    await lecture_instance_repo.create_all([inst1, inst2])
    await db_session.flush()
    return created


@pytest_asyncio.fixture(scope="function")
async def holiday_service(db_session: AsyncSession) -> HolidayService:
    return HolidayService(
        db=db_session,
        holiday_repo=HolidayRepository(db_session),
        semester_repo=SemesterRepository(db_session),
    )


@pytest.mark.asyncio
async def test_create_holiday_success(
    db_session: AsyncSession,
    holiday_service: HolidayService,
    test_semester: Semester,
    test_lecture_template: LectureTemplate
):
    # Verify Friday Jan 2nd is initially scheduled
    stmt = select(LectureInstance).where(LectureInstance.lecture_date == date(2026, 1, 2))
    result = await db_session.execute(stmt)
    inst = result.scalar_one()
    assert inst.lecture_status == LectureStatus.SCHEDULED

    # Create Holiday on Jan 2nd
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="New Year Holiday"
    )
    holiday = await holiday_service.create_holiday(test_semester.semester_id, holiday_in)
    assert holiday.holiday_name == "New Year Holiday"
    assert holiday.holiday_date == date(2026, 1, 2)

    # Verify lecture status is updated to HOLIDAY
    await db_session.refresh(inst)
    assert inst.lecture_status == LectureStatus.HOLIDAY
    assert inst.attendance_status == AttendanceStatus.UNMARKED


@pytest.mark.asyncio
async def test_create_holiday_outside_semester_bounds(
    holiday_service: HolidayService,
    test_semester: Semester
):
    # Semester is Jan 1st to Jan 15th. Jan 20th is outside.
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 20),
        holiday_name="Out of bounds holiday"
    )
    with pytest.raises(ValidationException):
        await holiday_service.create_holiday(test_semester.semester_id, holiday_in)


@pytest.mark.asyncio
async def test_create_duplicate_holiday(
    holiday_service: HolidayService,
    test_semester: Semester
):
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="Holiday 1"
    )
    await holiday_service.create_holiday(test_semester.semester_id, holiday_in)

    # Try creating again on same date
    holiday_in2 = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="Holiday 2"
    )
    with pytest.raises(ConflictException):
        await holiday_service.create_holiday(test_semester.semester_id, holiday_in2)


@pytest.mark.asyncio
async def test_multiple_holidays_in_one_semester(
    holiday_service: HolidayService,
    test_semester: Semester
):
    holiday1 = HolidayCreate(semester_id=test_semester.semester_id, holiday_date=date(2026, 1, 2), holiday_name="First")
    holiday2 = HolidayCreate(semester_id=test_semester.semester_id, holiday_date=date(2026, 1, 5), holiday_name="Second")

    h1 = await holiday_service.create_holiday(test_semester.semester_id, holiday1)
    h2 = await holiday_service.create_holiday(test_semester.semester_id, holiday2)

    assert h1.holiday_name == "First"
    assert h2.holiday_name == "Second"

    holidays = await holiday_service.list_holidays(test_semester.semester_id)
    assert len(holidays) == 2


@pytest.mark.asyncio
async def test_holiday_on_day_with_no_lectures(
    holiday_service: HolidayService,
    test_semester: Semester
):
    # Jan 3rd is Saturday, no lectures generated in fixture.
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 3),
        holiday_name="Weekend Holiday"
    )
    holiday = await holiday_service.create_holiday(test_semester.semester_id, holiday_in)
    assert holiday.holiday_date == date(2026, 1, 3)


@pytest.mark.asyncio
async def test_delete_holiday_restores_status(
    db_session: AsyncSession,
    holiday_service: HolidayService,
    test_semester: Semester,
    test_lecture_template: LectureTemplate
):
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="Holiday to delete"
    )
    holiday = await holiday_service.create_holiday(test_semester.semester_id, holiday_in)

    # Verify set to HOLIDAY
    stmt = select(LectureInstance).where(LectureInstance.lecture_date == date(2026, 1, 2))
    result = await db_session.execute(stmt)
    inst = result.scalar_one()
    assert inst.lecture_status == LectureStatus.HOLIDAY

    # Delete Holiday
    await holiday_service.delete_holiday(holiday.holiday_id)

    # Verify restored to SCHEDULED
    await db_session.refresh(inst)
    assert inst.lecture_status == LectureStatus.SCHEDULED


@pytest.mark.asyncio
async def test_delete_holiday_with_no_lectures(
    holiday_service: HolidayService,
    test_semester: Semester
):
    # Saturday holiday, no lectures on this date
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 3),
        holiday_name="Saturday Holiday"
    )
    holiday = await holiday_service.create_holiday(test_semester.semester_id, holiday_in)
    # Delete it
    await holiday_service.delete_holiday(holiday.holiday_id)


@pytest.mark.asyncio
async def test_update_holiday_date_changes_instances(
    db_session: AsyncSession,
    holiday_service: HolidayService,
    test_semester: Semester,
    test_lecture_template: LectureTemplate
):
    # Friday Jan 2nd and Jan 9th are scheduled.
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="Friday Holiday"
    )
    holiday = await holiday_service.create_holiday(test_semester.semester_id, holiday_in)

    # Jan 2nd is HOLIDAY, Jan 9th is SCHEDULED
    stmt1 = select(LectureInstance).where(LectureInstance.lecture_date == date(2026, 1, 2))
    inst1 = (await db_session.execute(stmt1)).scalar_one()
    stmt2 = select(LectureInstance).where(LectureInstance.lecture_date == date(2026, 1, 9))
    inst2 = (await db_session.execute(stmt2)).scalar_one()

    assert inst1.lecture_status == LectureStatus.HOLIDAY
    assert inst2.lecture_status == LectureStatus.SCHEDULED

    # Move holiday to Jan 9th
    update_in = HolidayUpdate(holiday_date=date(2026, 1, 9))
    await holiday_service.update_holiday(holiday.holiday_id, update_in)

    # Verify Jan 2nd restored to SCHEDULED, Jan 9th set to HOLIDAY
    await db_session.refresh(inst1)
    await db_session.refresh(inst2)
    assert inst1.lecture_status == LectureStatus.SCHEDULED
    assert inst2.lecture_status == LectureStatus.HOLIDAY


@pytest.mark.asyncio
async def test_update_holiday_to_same_date(
    holiday_service: HolidayService,
    test_semester: Semester
):
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="Holiday"
    )
    holiday = await holiday_service.create_holiday(test_semester.semester_id, holiday_in)

    # Update name and same date
    update_in = HolidayUpdate(holiday_date=date(2026, 1, 2), holiday_name="New Name")
    updated = await holiday_service.update_holiday(holiday.holiday_id, update_in)
    assert updated.holiday_name == "New Name"
    assert updated.holiday_date == date(2026, 1, 2)


@pytest.mark.asyncio
async def test_update_holiday_to_existing_holiday_date(
    holiday_service: HolidayService,
    test_semester: Semester
):
    h1 = await holiday_service.create_holiday(
        test_semester.semester_id, HolidayCreate(semester_id=test_semester.semester_id, holiday_date=date(2026, 1, 2), holiday_name="H1")
    )
    h2 = await holiday_service.create_holiday(
        test_semester.semester_id, HolidayCreate(semester_id=test_semester.semester_id, holiday_date=date(2026, 1, 5), holiday_name="H2")
    )

    # Try updating h1's date to h2's date (Jan 5th)
    update_in = HolidayUpdate(holiday_date=date(2026, 1, 5))
    with pytest.raises(ConflictException):
        await holiday_service.update_holiday(h1.holiday_id, update_in)



# --- API ROUTE INTEGRATION TESTS ---

@pytest.mark.asyncio
async def test_api_create_holiday(client: AsyncClient, test_semester: Semester):
    payload = {
        "semester_id": str(test_semester.semester_id),
        "holiday_date": "2026-01-02",
        "holiday_name": "New Year Day"
    }
    response = await client.post("/api/v1/academic/holidays", json=payload)
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["success"] is True
    assert data["data"]["holiday_name"] == "New Year Day"
    assert data["data"]["holiday_date"] == "2026-01-02"


@pytest.mark.asyncio
async def test_api_list_holidays(client: AsyncClient, test_semester: Semester):
    # Add a holiday
    payload = {
        "semester_id": str(test_semester.semester_id),
        "holiday_date": "2026-01-02",
        "holiday_name": "Holiday A"
    }
    await client.post("/api/v1/academic/holidays", json=payload)

    response = await client.get(f"/api/v1/academic/holidays?semester_id={test_semester.semester_id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) == 1
    assert data["data"][0]["holiday_name"] == "Holiday A"


@pytest.mark.asyncio
async def test_api_holiday_calendar(client: AsyncClient, test_semester: Semester):
    # Create two holidays out of order chronologically
    payload2 = {
        "semester_id": str(test_semester.semester_id),
        "holiday_date": "2026-01-05",
        "holiday_name": "Jan 5th Holiday"
    }
    payload1 = {
        "semester_id": str(test_semester.semester_id),
        "holiday_date": "2026-01-02",
        "holiday_name": "Jan 2nd Holiday"
    }
    await client.post("/api/v1/academic/holidays", json=payload2)
    await client.post("/api/v1/academic/holidays", json=payload1)

    # Get calendar
    response = await client.get(f"/api/v1/academic/holidays/calendar/{test_semester.semester_id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) == 2
    # Verify chronological order
    assert data["data"][0]["holiday_date"] == "2026-01-02"
    assert data["data"][0]["holiday_name"] == "Jan 2nd Holiday"
    assert data["data"][1]["holiday_date"] == "2026-01-05"
    assert data["data"][1]["holiday_name"] == "Jan 5th Holiday"


@pytest.mark.asyncio
async def test_api_update_holiday(client: AsyncClient, test_semester: Semester):
    # Create first
    payload = {
        "semester_id": str(test_semester.semester_id),
        "holiday_date": "2026-01-02",
        "holiday_name": "Holiday"
    }
    created = await client.post("/api/v1/academic/holidays", json=payload)
    holiday_id = created.json()["data"]["holiday_id"]

    # Update date & name
    update_payload = {
        "holiday_date": "2026-01-09",
        "holiday_name": "Updated Holiday"
    }
    response = await client.put(f"/api/v1/academic/holidays/{holiday_id}", json=update_payload)
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert data["data"]["holiday_name"] == "Updated Holiday"
    assert data["data"]["holiday_date"] == "2026-01-09"


@pytest.mark.asyncio
async def test_api_delete_holiday(client: AsyncClient, test_semester: Semester):
    # Create
    payload = {
        "semester_id": str(test_semester.semester_id),
        "holiday_date": "2026-01-02",
        "holiday_name": "Holiday"
    }
    created = await client.post("/api/v1/academic/holidays", json=payload)
    holiday_id = created.json()["data"]["holiday_id"]

    # Delete
    response = await client.delete(f"/api/v1/academic/holidays/{holiday_id}")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert data["message"] == "Holiday deleted successfully."

    # Try GETting deleted
    get_response = await client.get(f"/api/v1/academic/holidays/{holiday_id}")
    assert get_response.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.asyncio
async def test_create_lecture_template_after_holiday_creation(
    db_session: AsyncSession,
    holiday_service: HolidayService,
    test_semester: Semester,
    test_subject: Subject
):
    # 1. Create a holiday on Friday Jan 2nd
    holiday_in = HolidayCreate(
        semester_id=test_semester.semester_id,
        holiday_date=date(2026, 1, 2),
        holiday_name="Early Holiday"
    )
    await holiday_service.create_holiday(test_semester.semester_id, holiday_in)

    # 2. Create a Lecture Template for Friday (weekday 5)
    from app.services.academic.lecture_template import LectureTemplateService
    from app.repositories.academic.lecture_template import LectureTemplateRepository
    from app.repositories.academic.lecture_instance import LectureInstanceRepository
    from app.schemas.academic.lecture_template import LectureTemplateCreate

    lt_service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session),
    )

    template_in = LectureTemplateCreate(
        subject_id=test_subject.subject_id,
        day_of_week=5,
        start_time=time(10, 0),
        end_time=time(11, 0),
        room="Lab 3"
    )
    # This generates Friday Jan 2nd and Jan 9th lecture instances
    template = await lt_service.create_template(template_in)

    # 3. Verify newly generated Lecture Instance on Jan 2nd (holiday date) is HOLIDAY
    stmt1 = select(LectureInstance).where(
        LectureInstance.lecture_template_id == template.lecture_template_id,
        LectureInstance.lecture_date == date(2026, 1, 2)
    )
    inst1 = (await db_session.execute(stmt1)).scalar_one()
    assert inst1.lecture_status == LectureStatus.HOLIDAY
    assert inst1.attendance_status == AttendanceStatus.UNMARKED

    # 4. Verify newly generated Lecture Instance on Jan 9th (non-holiday) is SCHEDULED
    stmt2 = select(LectureInstance).where(
        LectureInstance.lecture_template_id == template.lecture_template_id,
        LectureInstance.lecture_date == date(2026, 1, 9)
    )
    inst2 = (await db_session.execute(stmt2)).scalar_one()
    assert inst2.lecture_status == LectureStatus.SCHEDULED
    assert inst2.attendance_status == AttendanceStatus.UNMARKED


@pytest.mark.asyncio
async def test_leap_year_holiday_boundary(
    db_session: AsyncSession,
    holiday_service: HolidayService
):
    # 1. Create a semester spanning a leap day (Feb 29, 2028)
    sem_repo = SemesterRepository(db_session)
    # Feb 29, 2028 is a Tuesday (day_of_week=2)
    sem = Semester(
        semester_number=2028,
        start_date=date(2028, 2, 1),
        end_date=date(2028, 3, 15)
    )
    await sem_repo.create(sem)
    await db_session.flush()

    # 2. Create subject
    from app.repositories.academic.subject import SubjectRepository
    sub_repo = SubjectRepository(db_session)
    subject = Subject(
        semester_id=sem.semester_id,
        subject_name="Leap Sub",
        theme_color="#00FF00",
        attendance_goal=75
    )
    await sub_repo.create(subject)
    await db_session.flush()

    # 3. Create Tuesday Template
    from app.repositories.academic.lecture_template import LectureTemplateRepository
    from app.repositories.academic.lecture_instance import LectureInstanceRepository
    from app.repositories.academic.subject import SubjectRepository
    from app.services.academic.lecture_template import LectureTemplateService
    lt_service = LectureTemplateService(
        db=db_session,
        lecture_template_repo=LectureTemplateRepository(db_session),
        lecture_instance_repo=LectureInstanceRepository(db_session),
        subject_repo=SubjectRepository(db_session),
        semester_repo=SemesterRepository(db_session),
    )
    # Create Tuesday Template
    from app.schemas.academic.lecture_template import LectureTemplateCreate
    template = await lt_service.create_template(
        LectureTemplateCreate(
            subject_id=subject.subject_id,
            day_of_week=2,
            start_time=time(10, 0),
            end_time=time(11, 0),
            room="Room Leap"
        )
    )

    # 4. Verify lecture instance on leap day exists and is SCHEDULED
    leap_date = date(2028, 2, 29)
    stmt = select(LectureInstance).where(
        LectureInstance.lecture_template_id == template.lecture_template_id,
        LectureInstance.lecture_date == leap_date
    )
    inst = (await db_session.execute(stmt)).scalar_one()
    assert inst.lecture_status == LectureStatus.SCHEDULED

    # 5. Create Holiday on Feb 29, 2028
    holiday = await holiday_service.create_holiday(
        sem.semester_id,
        HolidayCreate(
            semester_id=sem.semester_id,
            holiday_date=leap_date,
            holiday_name="Leap Day Holiday"
        )
    )
    assert holiday.holiday_id is not None

    # Verify instance transitions to HOLIDAY
    db_session.expire(inst)
    inst = (await db_session.execute(stmt)).scalar_one()
    assert inst.lecture_status == LectureStatus.HOLIDAY

    # 6. Delete Holiday on Feb 29, 2028
    await holiday_service.delete_holiday(holiday.holiday_id)

    # Verify instance reverts to SCHEDULED
    db_session.expire(inst)
    inst = (await db_session.execute(stmt)).scalar_one()
    assert inst.lecture_status == LectureStatus.SCHEDULED


