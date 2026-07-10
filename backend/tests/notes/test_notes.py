from tests.conftest import TEST_USER_ID
import pytest
import pytest_asyncio
import uuid
from datetime import date
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.notes.notes_subject import NotesSubject
from app.models.notes.notes_section import NotesSection
from app.models.notes.notes_resource import NotesResource
from app.repositories.academic.semester import SemesterRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.services.academic.subject import SubjectService
from app.schemas.academic.subject import SubjectCreate


@pytest_asyncio.fixture(scope="function")
async def sample_semester(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=1,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 6, 30)
    )
    await semester_repo.create(sem)
    await db_session.flush()
    return sem


@pytest_asyncio.fixture(scope="function")
async def sample_semester_two(db_session: AsyncSession) -> Semester:
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    sem = Semester(
        user_id=TEST_USER_ID,
        semester_number=2,
        start_date=date(2026, 7, 1),
        end_date=date(2026, 12, 31)
    )
    await semester_repo.create(sem)
    await db_session.flush()
    return sem


@pytest_asyncio.fixture(scope="function")
async def sample_subject(db_session: AsyncSession, sample_semester: Semester) -> Subject:
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session, TEST_USER_ID)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    subject_in = SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Physics",
        faculty_name="Dr. Feynman",
        theme_color="#FF0000",
        attendance_goal=75
    )
    sub = await service.create_subject(subject_in)
    return sub


# ==========================================
# 1. Notes Subjects (Read-only endpoints)
# ==========================================

@pytest.mark.asyncio
async def test_notes_subject_read_only(client: AsyncClient, sample_semester: Semester, sample_subject: Subject):
    # GET list
    list_res = await client.get(f"/api/v1/notes/subjects?semester_id={sample_semester.semester_id}")
    assert list_res.status_code == 200
    body = list_res.json()
    assert body["success"] is True
    assert len(body["data"]) == 1
    assert body["data"][0]["notes_subject_name"] == "Physics"
    notes_subject_id = body["data"][0]["notes_subject_id"]

    # GET detail
    detail_res = await client.get(f"/api/v1/notes/subjects/{notes_subject_id}")
    assert detail_res.status_code == 200
    assert detail_res.json()["data"]["notes_subject_name"] == "Physics"

    # POST (Not allowed / does not exist)
    post_res = await client.post("/api/v1/notes/subjects", json={"notes_subject_name": "Chemistry"})
    assert post_res.status_code in (404, 405)

    # PUT (Not allowed / does not exist)
    put_res = await client.put(f"/api/v1/notes/subjects/{notes_subject_id}", json={"notes_subject_name": "Bio"})
    assert put_res.status_code in (404, 405)

    # DELETE (Not allowed / does not exist)
    del_res = await client.delete(f"/api/v1/notes/subjects/{notes_subject_id}")
    assert del_res.status_code in (404, 405)


# ==========================================
# 2. Sections CRUD & Validations
# ==========================================

@pytest.mark.asyncio
async def test_sections_crud(client: AsyncClient, sample_semester: Semester, sample_subject: Subject):
    # Retrieve notes subject ID
    sub_res = await client.get(f"/api/v1/notes/subjects?semester_id={sample_semester.semester_id}")
    notes_subject_id = sub_res.json()["data"][0]["notes_subject_id"]

    # CREATE Section
    payload = {
        "notes_subject_id": notes_subject_id,
        "section_name": "Unit 1"
    }
    create_res = await client.post("/api/v1/notes/sections", json=payload)
    assert create_res.status_code == 201
    body = create_res.json()
    assert body["success"] is True
    section_id = body["data"]["section_id"]
    assert body["data"]["section_name"] == "Unit 1"

    # Duplicate name validation inside same subject
    dup_res = await client.post("/api/v1/notes/sections", json=payload)
    assert dup_res.status_code == 409
    assert "already exists" in dup_res.json()["message"]

    # GET list
    list_res = await client.get(f"/api/v1/notes/sections?notes_subject_id={notes_subject_id}")
    assert list_res.status_code == 200
    assert len(list_res.json()["data"]) == 1

    # UPDATE Section
    update_res = await client.put(f"/api/v1/notes/sections/{section_id}", json={"section_name": "Unit 1 Renamed"})
    assert update_res.status_code == 200
    assert update_res.json()["data"]["section_name"] == "Unit 1 Renamed"

    # Create another to test duplicate rename validation
    await client.post("/api/v1/notes/sections", json={"notes_subject_id": notes_subject_id, "section_name": "Unit 2"})
    dup_rename = await client.put(f"/api/v1/notes/sections/{section_id}", json={"section_name": "Unit 2"})
    assert dup_rename.status_code == 409

    # DELETE Section
    del_res = await client.delete(f"/api/v1/notes/sections/{section_id}")
    assert del_res.status_code == 200

    # Retrieve again should fail
    get_res = await client.get(f"/api/v1/notes/sections/{section_id}")
    assert get_res.status_code == 404


# ==========================================
# 3. Resources CRUD & Validations
# ==========================================

@pytest.mark.asyncio
async def test_resources_crud_and_validators(client: AsyncClient, sample_semester: Semester, sample_subject: Subject):
    # 1. Setup section
    sub_res = await client.get(f"/api/v1/notes/subjects?semester_id={sample_semester.semester_id}")
    notes_subject_id = sub_res.json()["data"][0]["notes_subject_id"]
    sec_res = await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": notes_subject_id,
        "section_name": "Unit 1"
    })
    section_id = sec_res.json()["data"]["section_id"]

    # 2. Reject negative file size
    payload_neg = {
        "section_id": section_id,
        "resource_name": "Intro to Physics",
        "file_name": "intro.pdf",
        "mime_type": "application/pdf",
        "file_size_bytes": -50,
        "storage_path": "files/intro.pdf",
        "uploaded_via": "app"
    }
    neg_res = await client.post("/api/v1/notes/resources", json=payload_neg)
    assert neg_res.status_code == 422

    # 3. Reject zero-byte file size
    payload_zero = payload_neg.copy()
    payload_zero["file_size_bytes"] = 0
    zero_res = await client.post("/api/v1/notes/resources", json=payload_zero)
    assert zero_res.status_code == 422

    # 4. Reject unsupported MIME type
    payload_mime = payload_neg.copy()
    payload_mime["file_size_bytes"] = 1000
    payload_mime["mime_type"] = "application/x-executable"
    mime_res = await client.post("/api/v1/notes/resources", json=payload_mime)
    assert mime_res.status_code == 422

    # 5. Create valid resource
    payload_valid = payload_neg.copy()
    payload_valid["file_size_bytes"] = 2048
    create_res = await client.post("/api/v1/notes/resources", json=payload_valid)
    assert create_res.status_code == 201
    resource_id = create_res.json()["data"]["resource_id"]
    assert create_res.json()["data"]["file_extension"] == ".pdf"

    # 6. Reject duplicate file name
    payload_dup_file = payload_valid.copy()
    payload_dup_file["resource_name"] = "Different Name"
    dup_file_res = await client.post("/api/v1/notes/resources", json=payload_dup_file)
    assert dup_file_res.status_code == 409

    # 7. Reject duplicate resource name
    payload_dup_name = payload_valid.copy()
    payload_dup_name["file_name"] = "different.pdf"
    dup_name_res = await client.post("/api/v1/notes/resources", json=payload_dup_name)
    assert dup_name_res.status_code == 409

    # 8. GET Resource by ID
    get_res = await client.get(f"/api/v1/notes/resources/{resource_id}")
    assert get_res.status_code == 200
    assert get_res.json()["data"]["resource_name"] == "Intro to Physics"

    # 9. UPDATE Resource
    update_res = await client.put(f"/api/v1/notes/resources/{resource_id}", json={
        "resource_name": "Updated Intro Name",
        "file_size_bytes": 4096
    })
    assert update_res.status_code == 200
    assert update_res.json()["data"]["resource_name"] == "Updated Intro Name"
    assert update_res.json()["data"]["file_size_bytes"] == 4096

    # 10. DELETE Resource
    del_res = await client.delete(f"/api/v1/notes/resources/{resource_id}")
    assert del_res.status_code == 200

    # Retrieve again should fail
    get_fail = await client.get(f"/api/v1/notes/resources/{resource_id}")
    assert get_fail.status_code == 404


# ==========================================
# 4. Alphabetical Hierarchy Ordering
# ==========================================

@pytest.mark.asyncio
async def test_notes_hierarchy_ordering(db_session: AsyncSession, client: AsyncClient, sample_semester: Semester):
    # Setup multiple Notes Subjects under same semester
    # (By creating academic subjects, which sync notes subjects)
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session, TEST_USER_ID)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    sub_b = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Chemistry",
        attendance_goal=75
    ))
    sub_a = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Biology",
        attendance_goal=75
    ))

    # Retrieve notes subjects
    notes_subjects = await notes_repo.list_by_semester(sample_semester.semester_id)
    ns_chem = next(ns for ns in notes_subjects if ns.notes_subject_name == "Chemistry")
    ns_bio = next(ns for ns in notes_subjects if ns.notes_subject_name == "Biology")

    # Add sections under Chemistry in non-alphabetical order
    # (Creating via API to verify full stack integration)
    await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": str(ns_chem.notes_subject_id),
        "section_name": "Z Section"
    })
    sec_res_m = await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": str(ns_chem.notes_subject_id),
        "section_name": "M Section"
    })
    sec_id_m = sec_res_m.json()["data"]["section_id"]

    # Add resources under M Section in non-alphabetical order
    await client.post("/api/v1/notes/resources", json={
        "section_id": sec_id_m,
        "resource_name": "Gamma Resource",
        "file_name": "gamma.pdf",
        "mime_type": "application/pdf",
        "file_size_bytes": 100,
        "storage_path": "gamma.pdf",
        "uploaded_via": "app"
    })
    await client.post("/api/v1/notes/resources", json={
        "section_id": sec_id_m,
        "resource_name": "Alpha Resource",
        "file_name": "alpha.pdf",
        "mime_type": "application/pdf",
        "file_size_bytes": 100,
        "storage_path": "alpha.pdf",
        "uploaded_via": "app"
    })

    # Fetch Hierarchy
    hierarchy_res = await client.get(f"/api/v1/notes/hierarchy/{sample_semester.semester_id}")
    assert hierarchy_res.status_code == 200
    hierarchy = hierarchy_res.json()["data"]

    # 1. Subjects must be sorted alphabetically: Biology first, then Chemistry
    assert len(hierarchy) == 2
    assert hierarchy[0]["notes_subject_name"] == "Biology"
    assert hierarchy[1]["notes_subject_name"] == "Chemistry"

    # 2. Sections under Chemistry must be sorted alphabetically: M Section, then Z Section
    chem_sections = hierarchy[1]["sections"]
    assert len(chem_sections) == 2
    assert chem_sections[0]["section_name"] == "M Section"
    assert chem_sections[1]["section_name"] == "Z Section"

    # 3. Resources under M Section must be sorted alphabetically: Alpha Resource, then Gamma Resource
    m_resources = chem_sections[0]["resources"]
    assert len(m_resources) == 2
    assert m_resources[0]["resource_name"] == "Alpha Resource"
    assert m_resources[1]["resource_name"] == "Gamma Resource"


# ==========================================
# 5. Joint Search and Ordering
# ==========================================

@pytest.mark.asyncio
async def test_resources_joint_search_and_ordering(
    db_session: AsyncSession, client: AsyncClient, sample_semester: Semester, sample_semester_two: Semester
):
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session, TEST_USER_ID)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    # 1. Semester 1 (2026-A) -> Subject Physics -> Unit 1 -> "Advanced Physics Notes.pdf"
    sub_phys = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Physics",
        attendance_goal=75
    ))
    ns_phys = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "Physics")
    sec_phys = await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": str(ns_phys.notes_subject_id),
        "section_name": "Unit 1"
    })
    sec_phys_id = sec_phys.json()["data"]["section_id"]
    await client.post("/api/v1/notes/resources", json={
        "section_id": sec_phys_id,
        "resource_name": "Advanced Physics Notes",
        "file_name": "adv_phys.pdf",
        "mime_type": "application/pdf",
        "file_size_bytes": 100,
        "storage_path": "path1",
        "uploaded_via": "app"
    })

    # 2. Semester 2 (2026-B) -> Subject Calculus -> Unit 1 -> "Calculus Physics Engine.pdf"
    sub_calc = await service.create_subject(SubjectCreate(
        semester_id=sample_semester_two.semester_id,
        subject_name="Calculus",
        attendance_goal=75
    ))
    ns_calc = await notes_repo.get_by_name_in_semester(sample_semester_two.semester_id, "Calculus")
    sec_calc = await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": str(ns_calc.notes_subject_id),
        "section_name": "Unit 1"
    })
    sec_calc_id = sec_calc.json()["data"]["section_id"]
    await client.post("/api/v1/notes/resources", json={
        "section_id": sec_calc_id,
        "resource_name": "Calculus Physics Engine",
        "file_name": "calc_phys.pdf",
        "mime_type": "application/pdf",
        "file_size_bytes": 100,
        "storage_path": "path2",
        "uploaded_via": "app"
    })

    # 3. Semester 1 (2026-A) -> Subject Chemistry -> Unit 1 -> "Basic Chemistry.pdf" (should not match search for 'physics')
    sub_chem = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Chemistry",
        attendance_goal=75
    ))
    ns_chem = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "Chemistry")
    sec_chem = await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": str(ns_chem.notes_subject_id),
        "section_name": "Unit 1"
    })
    sec_chem_id = sec_chem.json()["data"]["section_id"]
    await client.post("/api/v1/notes/resources", json={
        "section_id": sec_chem_id,
        "resource_name": "Basic Chemistry",
        "file_name": "basic_chem.pdf",
        "mime_type": "application/pdf",
        "file_size_bytes": 100,
        "storage_path": "path3",
        "uploaded_via": "app"
    })

    # Perform Search: query 'physics' (should match 1 and 2, but not 3)
    search_res = await client.get("/api/v1/notes/resources?q=physics")
    assert search_res.status_code == 200
    results = search_res.json()["data"]
    assert len(results) == 2

    # Verify search ordering:
    # 1. Semester Name (Semester 2026-A before Semester 2026-B)
    # So "Advanced Physics Notes" must be first, followed by "Calculus Physics Engine"
    assert results[0]["resource_name"] == "Advanced Physics Notes"
    assert results[1]["resource_name"] == "Calculus Physics Engine"

    # Search with semester filter: query 'physics' + semester 2026-B only
    filtered_res = await client.get(f"/api/v1/notes/resources?q=physics&semester_id={sample_semester_two.semester_id}")
    assert filtered_res.status_code == 200
    filtered_data = filtered_res.json()["data"]
    assert len(filtered_data) == 1
    assert filtered_data[0]["resource_name"] == "Calculus Physics Engine"


# ==========================================
# 6. Pagination & Pagination Validation Tests
# ==========================================

@pytest.mark.asyncio
async def test_resources_pagination(
    db_session: AsyncSession, client: AsyncClient, sample_semester: Semester
):
    semester_repo = SemesterRepository(db_session, TEST_USER_ID)
    subject_repo = SubjectRepository(db_session)
    notes_repo = NotesSubjectRepository(db_session, TEST_USER_ID)
    service = SubjectService(db_session, subject_repo, semester_repo, notes_repo)

    sub_phys = await service.create_subject(SubjectCreate(
        semester_id=sample_semester.semester_id,
        subject_name="Physics",
        attendance_goal=75
    ))
    ns_phys = await notes_repo.get_by_name_in_semester(sample_semester.semester_id, "Physics")
    sec_phys = await client.post("/api/v1/notes/sections", json={
        "notes_subject_id": str(ns_phys.notes_subject_id),
        "section_name": "Unit 1"
    })
    sec_phys_id = sec_phys.json()["data"]["section_id"]

    # Create 5 resources in non-alphabetical insert order to verify ordering and pagination
    resource_names = ["Resource E", "Resource A", "Resource C", "Resource B", "Resource D"]
    for name in resource_names:
        file_name = f"{name.lower().replace(' ', '_')}.pdf"
        await client.post("/api/v1/notes/resources", json={
            "section_id": sec_phys_id,
            "resource_name": name,
            "file_name": file_name,
            "mime_type": "application/pdf",
            "file_size_bytes": 100,
            "storage_path": f"path_{file_name}",
            "uploaded_via": "app"
        })

    # Test default pagination: Should return all 5 in alphabetical order
    default_res = await client.get("/api/v1/notes/resources")
    assert default_res.status_code == 200
    data = default_res.json()["data"]
    assert len(data) == 5
    assert [r["resource_name"] for r in data] == ["Resource A", "Resource B", "Resource C", "Resource D", "Resource E"]

    # Test limit=3: Should return first 3 in alphabetical order
    limit_res = await client.get("/api/v1/notes/resources?limit=3")
    assert limit_res.status_code == 200
    data_limit = limit_res.json()["data"]
    assert len(data_limit) == 3
    assert [r["resource_name"] for r in data_limit] == ["Resource A", "Resource B", "Resource C"]

    # Test limit=2, offset=2: Should return 3rd and 4th resources ("Resource C", "Resource D")
    offset_res = await client.get("/api/v1/notes/resources?limit=2&offset=2")
    assert offset_res.status_code == 200
    data_offset = offset_res.json()["data"]
    assert len(data_offset) == 2
    assert [r["resource_name"] for r in data_offset] == ["Resource C", "Resource D"]

    # Test invalid limit: limit=0 (should return 422)
    invalid_limit_zero = await client.get("/api/v1/notes/resources?limit=0")
    assert invalid_limit_zero.status_code == 422

    # Test invalid limit: limit=101 (should return 422)
    invalid_limit_too_high = await client.get("/api/v1/notes/resources?limit=101")
    assert invalid_limit_too_high.status_code == 422

    # Test invalid offset: offset=-1 (should return 422)
    invalid_offset_neg = await client.get("/api/v1/notes/resources?offset=-1")
    assert invalid_offset_neg.status_code == 422
