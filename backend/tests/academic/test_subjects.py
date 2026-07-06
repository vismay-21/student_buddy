import pytest
import pytest_asyncio
import uuid
from datetime import date
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import IntegrityError

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.notes.notes_subject import NotesSubject
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.services.academic.subject import SubjectService
from app.schemas.academic.subject import SubjectCreate, SubjectUpdate
from app.core.exceptions import ConflictException, NotFoundException
from app.core.constants import DEFAULT_ATTENDANCE_GOAL


@pytest_asyncio.fixture(scope="function")
async def sample_semester(db_session: AsyncSession) -> Semester:
    """Helper fixture to create a valid semester for subject tests."""
    semester_repo = SemesterRepository(db_session)
    sem = Semester(
        semester_number=100,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 30)
    )
    await semester_repo.create(sem)
    await db_session.flush()
    return sem


# ---------------------------------------------------------------------------
# Repository Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_subject_repo_create(db_session: AsyncSession, sample_semester: Semester):
    repo = SubjectRepository(db_session)
    subject = Subject(
        semester_id=sample_semester.semester_id,
        subject_name="Maths",
        faculty_name="Dr. Smith",
        theme_color="#FF5733",
        attendance_goal=80
    )
    created = await repo.create(subject)
    await db_session.flush()

    assert created.subject_id is not None
    assert created.subject_name == "Maths"
    assert created.faculty_name == "Dr. Smith"
    assert created.theme_color == "#FF5733"
    assert created.attendance_goal == 80


@pytest.mark.asyncio
async def test_subject_repo_unique_constraint(db_session: AsyncSession, sample_semester: Semester):
    repo = SubjectRepository(db_session)
    sub1 = Subject(
        semester_id=sample_semester.semester_id,
        subject_name="Physics",
        attendance_goal=75
    )
    sub2 = Subject(
        semester_id=sample_semester.semester_id,
        subject_name="Physics",
        attendance_goal=75
    )
    await repo.create(sub1)
    await repo.create(sub2)

    with pytest.raises(IntegrityError):
        await db_session.flush()
    await db_session.rollback()


# ---------------------------------------------------------------------------
# Service Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_subject_service_create_sync_notes(db_session: AsyncSession, sample_semester: Semester):
    semester_repo = SemesterRepository(db_session)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    subject_in = SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Chemistry",
        faculty_name="Prof. Harrison",
        theme_color="#00FF00",
        attendance_goal=85
    )
    
    created = await service.create_subject(subject_in)
    assert created.subject_id is not None
    assert created.subject_name == "Chemistry"

    # Verify corresponding NotesSubject was created automatically
    notes_sub = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "Chemistry")
    assert notes_sub is not None
    assert notes_sub.notes_subject_name == "Chemistry"
    assert notes_sub.semester_id == sample_semester.semester_id


@pytest.mark.asyncio
async def test_subject_service_create_duplicate_name(db_session: AsyncSession, sample_semester: Semester):
    semester_repo = SemesterRepository(db_session)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    subject_in = SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Biology",
        attendance_goal=75
    )
    await service.create_subject(subject_in)

    with pytest.raises(ConflictException):
        await service.create_subject(subject_in)


@pytest.mark.asyncio
async def test_subject_service_create_invalid_semester(db_session: AsyncSession):
    semester_repo = SemesterRepository(db_session)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    subject_in = SubjectCreate(
        semester_id=uuid.uuid4(),
        subject_name="History",
        attendance_goal=75
    )
    with pytest.raises(NotFoundException):
        await service.create_subject(subject_in)


@pytest.mark.asyncio
async def test_subject_service_update_rename_notes(db_session: AsyncSession, sample_semester: Semester):
    semester_repo = SemesterRepository(db_session)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    # Create subject
    subject_in = SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="English Lit",
        attendance_goal=75
    )
    created = await service.create_subject(subject_in)

    # Update subject name
    update_in = SubjectUpdate(subject_name="English Literature")
    updated = await service.update_subject(created.subject_id, update_in)
    assert updated.subject_name == "English Literature"

    # Verify notes subject was automatically updated/renamed
    old_notes_sub = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "English Lit")
    assert old_notes_sub is None

    new_notes_sub = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "English Literature")
    assert new_notes_sub is not None


@pytest.mark.asyncio
async def test_subject_service_delete_with_notes(db_session: AsyncSession, sample_semester: Semester):
    semester_repo = SemesterRepository(db_session)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    # Create
    created = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="History",
        attendance_goal=75
    ))

    # Delete with notes
    await service.delete_subject(created.subject_id, delete_notes_subject=True)

    # Verify subject deleted
    with pytest.raises(NotFoundException):
        await service.get_subject(created.subject_id)

    # Verify notes subject deleted
    notes_sub = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "History")
    assert notes_sub is None


@pytest.mark.asyncio
async def test_subject_service_delete_without_notes(db_session: AsyncSession, sample_semester: Semester):
    semester_repo = SemesterRepository(db_session)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    # Create
    created = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Geography",
        attendance_goal=75
    ))

    # Delete without notes (default or false)
    await service.delete_subject(created.subject_id, delete_notes_subject=False)

    # Verify subject deleted
    with pytest.raises(NotFoundException):
        await service.get_subject(created.subject_id)

    # Verify notes subject STILL exists
    notes_sub = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "Geography")
    assert notes_sub is not None


# ---------------------------------------------------------------------------
# API Integration Tests
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_api_create_subject(client: AsyncClient, sample_semester: Semester):
    payload = {
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "Web Dev",
        "faculty_name": "Prof. Alan",
        "theme_color": "#1A2B3C",
        "attendance_goal": 80
    }
    response = await client.post("/api/v1/academic/subjects", json=payload)
    assert response.status_code == 201
    
    body = response.json()
    assert body["success"] is True
    assert body["data"]["subject_name"] == "Web Dev"
    assert body["data"]["attendance_goal"] == 80


@pytest.mark.asyncio
async def test_api_create_subject_validation(client: AsyncClient, sample_semester: Semester):
    # Invalid HEX color
    payload = {
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "Web Dev",
        "theme_color": "1A2B3C",  # missing hash
        "attendance_goal": 80
    }
    response = await client.post("/api/v1/academic/subjects", json=payload)
    assert response.status_code == 422

    # Invalid attendance goal (105)
    payload = {
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "Web Dev",
        "theme_color": "#1A2B3C",
        "attendance_goal": 105
    }
    response = await client.post("/api/v1/academic/subjects", json=payload)
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_api_list_subjects(client: AsyncClient, sample_semester: Semester):
    # Create two subjects
    await client.post("/api/v1/academic/subjects", json={
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "B Subject",
        "attendance_goal": 75
    })
    await client.post("/api/v1/academic/subjects", json={
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "A Subject",
        "attendance_goal": 75
    })

    # Retrieve
    response = await client.get(f"/api/v1/academic/subjects?semester_id={sample_semester.semester_id}")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    data = body["data"]
    assert len(data) >= 2
    # Should be sorted alphabetically: "A Subject" first, then "B Subject"
    subject_names = [sub["subject_name"] for sub in data]
    # Check that A Subject appears before B Subject
    a_index = subject_names.index("A Subject")
    b_index = subject_names.index("B Subject")
    assert a_index < b_index


@pytest.mark.asyncio
async def test_api_update_subject(client: AsyncClient, sample_semester: Semester):
    # Create
    create_res = await client.post("/api/v1/academic/subjects", json={
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "Old Name",
        "attendance_goal": 75
    })
    subject_id = create_res.json()["data"]["subject_id"]

    # Update
    update_res = await client.put(f"/api/v1/academic/subjects/{subject_id}", json={
        "subject_name": "New Name",
        "attendance_goal": 90
    })
    assert update_res.status_code == 200
    assert update_res.json()["data"]["subject_name"] == "New Name"
    assert update_res.json()["data"]["attendance_goal"] == 90


@pytest.mark.asyncio
async def test_api_delete_subject(client: AsyncClient, sample_semester: Semester):
    # Create
    create_res = await client.post("/api/v1/academic/subjects", json={
        "semester_id": str(sample_semester.semester_id),
        "subject_name": "Delete Me",
        "attendance_goal": 75
    })
    subject_id = create_res.json()["data"]["subject_id"]

    # Delete
    delete_res = await client.delete(f"/api/v1/academic/subjects/{subject_id}?delete_notes_subject=true")
    assert delete_res.status_code == 200
    assert delete_res.json()["success"] is True

    # Retrieve again should fail
    get_res = await client.get(f"/api/v1/academic/subjects/{subject_id}")
    assert get_res.status_code == 404
