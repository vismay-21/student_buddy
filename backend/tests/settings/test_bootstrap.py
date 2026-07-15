import pytest
import uuid
from datetime import date, time, datetime, timezone
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance, LectureStatus, AttendanceStatus
from app.models.academic.holiday import Holiday
from app.models.academic.attendance_settings import AttendanceSettings, CriteriaMode
from app.models.todo.todo import Todo, TodoPriority, TodoStatus, TodoCreatedBy
from app.models.notes.notes_subject import NotesSubject
from app.models.notes.notes_section import NotesSection
from app.models.notes.notes_resource import NotesResource, UploadedVia
from app.models.review_queue.review_queue import ReviewQueue, ReviewType, EntityType, ReviewStatus, ResolvedBy
from app.models.activity_logs.activity_log import ActivityLog, ActorType, EntityType as LogEntityType, ActionType
from tests.conftest import TEST_USER_ID

pytestmark = pytest.mark.asyncio


async def test_bootstrap_endpoint(client: AsyncClient, db_session: AsyncSession) -> None:
    # 1. Seed Semester and Attendance Settings
    semester_id = uuid.uuid4()
    semester = Semester(
        semester_id=semester_id,
        user_id=TEST_USER_ID,
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 1),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(semester)

    attendance_settings = AttendanceSettings(
        attendance_settings_id=uuid.uuid4(),
        semester_id=semester_id,
        criteria_mode=CriteriaMode.OVERALL,
        overall_attendance_goal=75,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(attendance_settings)

    # 2. Seed Subject
    subject_id = uuid.uuid4()
    subject = Subject(
        subject_id=subject_id,
        semester_id=semester_id,
        subject_name="Operating Systems",
        faculty_name="Dr. Tanenbaum",
        theme_color="#0000FF",
        attendance_goal=80,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(subject)

    # 3. Seed Lecture Template
    template_id = uuid.uuid4()
    template = LectureTemplate(
        lecture_template_id=template_id,
        subject_id=subject_id,
        day_of_week=1,  # Monday
        start_time=time(10, 0, 0),
        end_time=time(11, 30, 0),
        room="Room 401",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(template)

    # 4. Seed Lecture Instance
    instance_id = uuid.uuid4()
    instance = LectureInstance(
        lecture_instance_id=instance_id,
        lecture_template_id=template_id,
        lecture_date=date(2026, 1, 5),
        lecture_status=LectureStatus.SCHEDULED,
        attendance_status=AttendanceStatus.UNMARKED,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(instance)

    # 5. Seed Holiday
    holiday_id = uuid.uuid4()
    holiday = Holiday(
        holiday_id=holiday_id,
        semester_id=semester_id,
        holiday_date=date(2026, 1, 1),
        holiday_name="New Year",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(holiday)

    # 6. Seed Todo
    todo_id = uuid.uuid4()
    todo = Todo(
        todo_id=todo_id,
        user_id=TEST_USER_ID,
        title="Submit OS Project",
        priority=TodoPriority.HIGH,
        status=TodoStatus.PENDING,
        created_by=TodoCreatedBy.USER,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(todo)

    # 7. Seed Notes Hierarchy
    notes_subject_id = uuid.uuid4()
    notes_subject = NotesSubject(
        notes_subject_id=notes_subject_id,
        user_id=TEST_USER_ID,
        semester_id=semester_id,
        notes_subject_name="OS Notes",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(notes_subject)

    section_id = uuid.uuid4()
    section = NotesSection(
        section_id=section_id,
        notes_subject_id=notes_subject_id,
        section_name="Unit 1",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(section)

    resource_id = uuid.uuid4()
    resource = NotesResource(
        resource_id=resource_id,
        section_id=section_id,
        resource_name="Processes Lecture",
        file_name="processes.pdf",
        mime_type="application/pdf",
        file_size_bytes=1024,
        storage_path="/notes/processes.pdf",
        uploaded_via=UploadedVia.APP,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(resource)

    # 8. Seed Review Queue Item
    review_id = uuid.uuid4()
    review_item = ReviewQueue(
        review_id=review_id,
        user_id=TEST_USER_ID,
        review_type=ReviewType.MISSING_INFORMATION,
        entity_type=EntityType.TODO,
        entity_id=todo_id,
        review_message="Clarify priority",
        review_status=ReviewStatus.PENDING,
        resolved_by=ResolvedBy.USER,
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(review_item)

    # 9. Seed Activity Log
    activity_id = uuid.uuid4()
    activity_log = ActivityLog(
        activity_id=activity_id,
        user_id=TEST_USER_ID,
        actor_type=ActorType.USER,
        entity_type=LogEntityType.TODO,
        entity_id=todo_id,
        action_type=ActionType.CREATED,
        activity_message="Created todo Submit OS Project",
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(activity_log)

    await db_session.flush()

    # Call bootstrap API
    response = await client.get("/api/v1/users/me/bootstrap")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["sync_version"] == 1
    assert body["generated_at"] is not None
    # Verify generated_at is timezone-aware
    parsed_dt = datetime.fromisoformat(body["generated_at"])
    assert parsed_dt.tzinfo is not None
    
    payload = body["data"]
    
    # Assert App settings exists (created in conftest clean_database fixture)
    assert payload["app_settings"] is not None
    assert payload["app_settings"]["theme_mode"] == "system"

    # Assert Semesters
    assert len(payload["semesters"]) == 1
    assert payload["semesters"][0]["semester_id"] == str(semester_id)

    # Assert Subjects
    assert len(payload["subjects"]) == 1
    assert payload["subjects"][0]["subject_id"] == str(subject_id)

    # Assert Lecture Templates
    assert len(payload["lecture_templates"]) == 1
    assert payload["lecture_templates"][0]["lecture_template_id"] == str(template_id)

    # Assert Lecture Instances
    assert len(payload["lecture_instances"]) == 1
    assert payload["lecture_instances"][0]["lecture_instance_id"] == str(instance_id)

    # Assert Holidays
    assert len(payload["holidays"]) == 1
    assert payload["holidays"][0]["holiday_id"] == str(holiday_id)

    # Assert Attendance Settings
    assert len(payload["attendance_settings"]) == 1
    assert payload["attendance_settings"][0]["overall_attendance_goal"] == 75

    # Assert Todos
    assert len(payload["todos"]) == 1
    assert payload["todos"][0]["todo_id"] == str(todo_id)

    # Assert Notes hierarchy
    assert len(payload["notes_subjects"]) == 1
    notes_sub = payload["notes_subjects"][0]
    assert notes_sub["notes_subject_id"] == str(notes_subject_id)
    assert len(notes_sub["sections"]) == 1
    assert notes_sub["sections"][0]["section_id"] == str(section_id)
    assert len(notes_sub["sections"][0]["resources"]) == 1
    assert notes_sub["sections"][0]["resources"][0]["resource_id"] == str(resource_id)

    # Assert Review Queue
    assert len(payload["review_queue"]) == 1
    assert payload["review_queue"][0]["review_id"] == str(review_id)
    assert payload["review_queue"][0]["entity_summary"] == "Submit OS Project"

    # Assert Activity Logs
    assert len(payload["activity_logs"]) == 1
    assert payload["activity_logs"][0]["activity_id"] == str(activity_id)
    assert payload["activity_logs"][0]["entity_summary"] == "Submit OS Project"


async def test_bootstrap_since_parameter(client: AsyncClient, db_session: AsyncSession) -> None:
    semester_id = uuid.uuid4()
    semester = Semester(
        semester_id=semester_id,
        user_id=TEST_USER_ID,
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 1),
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(semester)

    notes_subject_id = uuid.uuid4()
    notes_subject = NotesSubject(
        notes_subject_id=notes_subject_id,
        user_id=TEST_USER_ID,
        semester_id=semester_id,
        notes_subject_name="OS Notes",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(notes_subject)
    await db_session.flush()

    since_str = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    response = await client.get(f"/api/v1/users/me/bootstrap?since={since_str}")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
