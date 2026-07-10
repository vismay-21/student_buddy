import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.notes.notes_subject import NotesSubjectResponse, NotesSubjectDetailResponse
from app.schemas.notes.notes_section import NotesSectionCreate, NotesSectionUpdate, NotesSectionResponse
from app.schemas.notes.notes_resource import NotesResourceCreate, NotesResourceUpdate, NotesResourceResponse
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.repositories.notes.notes_section import NotesSectionRepository
from app.repositories.notes.notes_resource import NotesResourceRepository
from app.repositories.academic.semester import SemesterRepository
from app.services.notes.notes import NotesService
from app.dependencies.auth import get_current_user
from app.services.auth.authentication_service import CurrentUser

router = APIRouter()


async def get_notes_service(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user)
) -> NotesService:
    return NotesService(
        db=db,
        notes_subject_repo=NotesSubjectRepository(db, current_user.id),
        notes_section_repo=NotesSectionRepository(db),
        notes_resource_repo=NotesResourceRepository(db),
        semester_repo=SemesterRepository(db, current_user.id)
    )


# ==========================================
# Notes Subjects (Read-Only)
# ==========================================
@router.get(
    "/subjects",
    response_model=ApiResponse[list[NotesSubjectResponse]],
    summary="List notes subjects",
    description="Retrieve all notes subjects for a specific semester.",
)
async def list_subjects(
    semester_id: uuid.UUID = Query(..., description="UUID of the semester"),
    service: NotesService = Depends(get_notes_service)
):
    subjects = await service.list_subjects(semester_id)
    responses = [NotesSubjectResponse.model_validate(s) for s in subjects]
    return ApiResponse(
        success=True,
        message="Notes subjects retrieved successfully.",
        data=responses
    )


@router.get(
    "/subjects/{notes_subject_id}",
    response_model=ApiResponse[NotesSubjectResponse],
    summary="Get notes subject by ID",
    description="Retrieve a single notes subject by its UUID.",
)
async def get_subject(
    notes_subject_id: uuid.UUID,
    service: NotesService = Depends(get_notes_service)
):
    subject = await service.get_subject(notes_subject_id)
    return ApiResponse(
        success=True,
        message="Notes subject retrieved successfully.",
        data=NotesSubjectResponse.model_validate(subject)
    )


# ==========================================
# Notes Sections (CRUD)
# ==========================================
@router.get(
    "/sections",
    response_model=ApiResponse[list[NotesSectionResponse]],
    summary="List sections by subject",
    description="Retrieve all notes sections belonging to a specific notes subject.",
)
async def list_sections(
    notes_subject_id: uuid.UUID = Query(..., description="UUID of the parent notes subject"),
    service: NotesService = Depends(get_notes_service)
):
    sections = await service.list_sections(notes_subject_id)
    responses = [NotesSectionResponse.model_validate(s) for s in sections]
    return ApiResponse(
        success=True,
        message="Notes sections retrieved successfully.",
        data=responses
    )


@router.get(
    "/sections/{section_id}",
    response_model=ApiResponse[NotesSectionResponse],
    summary="Get section by ID",
)
async def get_section(
    section_id: uuid.UUID,
    service: NotesService = Depends(get_notes_service)
):
    section = await service.get_section(section_id)
    return ApiResponse(
        success=True,
        message="Notes section retrieved successfully.",
        data=NotesSectionResponse.model_validate(section)
    )


@router.post(
    "/sections",
    response_model=ApiResponse[NotesSectionResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a notes section",
)
async def create_section(
    section_in: NotesSectionCreate,
    service: NotesService = Depends(get_notes_service)
):
    section = await service.create_section(section_in)
    return ApiResponse(
        success=True,
        message="Notes section created successfully.",
        data=NotesSectionResponse.model_validate(section)
    )


@router.put(
    "/sections/{section_id}",
    response_model=ApiResponse[NotesSectionResponse],
    summary="Update section details",
)
async def update_section(
    section_id: uuid.UUID,
    section_in: NotesSectionUpdate,
    service: NotesService = Depends(get_notes_service)
):
    section = await service.update_section(section_id, section_in)
    return ApiResponse(
        success=True,
        message="Notes section updated successfully.",
        data=NotesSectionResponse.model_validate(section)
    )


@router.delete(
    "/sections/{section_id}",
    response_model=ApiResponse[None],
    summary="Delete a section",
)
async def delete_section(
    section_id: uuid.UUID,
    service: NotesService = Depends(get_notes_service)
):
    await service.delete_section(section_id)
    return ApiResponse(
        success=True,
        message="Notes section deleted successfully.",
        data=None
    )


# ==========================================
# Notes Resources (CRUD & Search)
# ==========================================
@router.get(
    "/resources",
    response_model=ApiResponse[list[NotesResourceResponse]],
    summary="List or search resources",
    description="Retrieve all resources in a section, or search across them with optional filters.",
)
async def list_or_search_resources(
    section_id: uuid.UUID | None = Query(None, description="UUID of the section"),
    q: str | None = Query(None, description="Case-insensitive search query"),
    semester_id: uuid.UUID | None = Query(None, description="Optional semester filter for search"),
    limit: int = Query(50, ge=1, le=100, description="Max number of records to return"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    service: NotesService = Depends(get_notes_service)
):
    if q is not None or semester_id is not None:
        resources = await service.search_resources(
            q=q, semester_id=semester_id, limit=limit, offset=offset
        )
    elif section_id is not None:
        resources = await service.list_resources(section_id, limit=limit, offset=offset)
    else:
        # Defaults to empty search query to return all items deterministically ordered
        resources = await service.search_resources(
            q=None, semester_id=None, limit=limit, offset=offset
        )

    responses = [NotesResourceResponse.model_validate(r) for r in resources]
    return ApiResponse(
        success=True,
        message="Resources retrieved successfully.",
        data=responses
    )


@router.get(
    "/resources/{resource_id}",
    response_model=ApiResponse[NotesResourceResponse],
    summary="Get resource by ID",
)
async def get_resource(
    resource_id: uuid.UUID,
    service: NotesService = Depends(get_notes_service)
):
    resource = await service.get_resource(resource_id)
    return ApiResponse(
        success=True,
        message="Resource retrieved successfully.",
        data=NotesResourceResponse.model_validate(resource)
    )


@router.post(
    "/resources",
    response_model=ApiResponse[NotesResourceResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Upload metadata for a resource",
)
async def create_resource(
    resource_in: NotesResourceCreate,
    service: NotesService = Depends(get_notes_service)
):
    resource = await service.create_resource(resource_in)
    return ApiResponse(
        success=True,
        message="Resource created successfully.",
        data=NotesResourceResponse.model_validate(resource)
    )


@router.put(
    "/resources/{resource_id}",
    response_model=ApiResponse[NotesResourceResponse],
    summary="Update resource details",
)
async def update_resource(
    resource_id: uuid.UUID,
    resource_in: NotesResourceUpdate,
    service: NotesService = Depends(get_notes_service)
):
    resource = await service.update_resource(resource_id, resource_in)
    return ApiResponse(
        success=True,
        message="Resource updated successfully.",
        data=NotesResourceResponse.model_validate(resource)
    )


@router.delete(
    "/resources/{resource_id}",
    response_model=ApiResponse[None],
    summary="Delete resource metadata",
)
async def delete_resource(
    resource_id: uuid.UUID,
    service: NotesService = Depends(get_notes_service)
):
    await service.delete_resource(resource_id)
    return ApiResponse(
        success=True,
        message="Resource deleted successfully.",
        data=None
    )


# ==========================================
# Complete Hierarchy
# ==========================================
@router.get(
    "/hierarchy/{semester_id}",
    response_model=ApiResponse[list[NotesSubjectDetailResponse]],
    summary="Get complete notes hierarchy for a semester",
    description="Retrieve all subjects, nested sections, and nested resource files alphabetically ordered.",
)
async def get_hierarchy(
    semester_id: uuid.UUID,
    service: NotesService = Depends(get_notes_service)
):
    hierarchy = await service.get_notes_hierarchy(semester_id)
    responses = [NotesSubjectDetailResponse.model_validate(s) for s in hierarchy]
    return ApiResponse(
        success=True,
        message="Notes hierarchy retrieved successfully.",
        data=responses
    )
