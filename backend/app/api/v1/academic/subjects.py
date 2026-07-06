import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.academic.subject import SubjectCreate, SubjectUpdate, SubjectResponse
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.repositories.notes.notes_subject import NotesSubjectRepository
from app.services.academic.subject import SubjectService

router = APIRouter()


async def get_subject_service(
    db: AsyncSession = Depends(get_db),
) -> SubjectService:
    return SubjectService(
        db=db,
        subject_repo=SubjectRepository(db),
        semester_repo=SemesterRepository(db),
        notes_subject_repo=NotesSubjectRepository(db),
    )


@router.get(
    "",
    response_model=ApiResponse[list[SubjectResponse]],
    summary="List subjects by semester",
    description="Retrieve all subjects belonging to a specific semester, "
                "ordered alphabetically by subject name. "
                "The semester_id query parameter is required.",
    response_description="List of subjects for the given semester.",
)
async def list_subjects(
    semester_id: uuid.UUID = Query(
        ..., description="UUID of the semester to list subjects for."
    ),
    service: SubjectService = Depends(get_subject_service),
):
    subjects = await service.list_subjects(semester_id)
    responses = [SubjectResponse.model_validate(s) for s in subjects]
    return ApiResponse(
        success=True,
        message="Subjects retrieved successfully.",
        data=responses,
    )


@router.get(
    "/{subject_id}",
    response_model=ApiResponse[SubjectResponse],
    summary="Get a subject by ID",
    description="Retrieve a single subject by its UUID. "
                "Returns 404 if the subject does not exist.",
    response_description="The requested subject.",
)
async def get_subject(
    subject_id: uuid.UUID,
    service: SubjectService = Depends(get_subject_service),
):
    subject = await service.get_subject(subject_id)
    return ApiResponse(
        success=True,
        message="Subject retrieved successfully.",
        data=SubjectResponse.model_validate(subject),
    )


@router.post(
    "",
    response_model=ApiResponse[SubjectResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new subject",
    description="Create a new academic subject within a semester. "
                "A corresponding Notes Subject is automatically created "
                "with the same name and semester. "
                "Returns 404 if the semester does not exist, "
                "or 409 if the subject name already exists in the semester.",
    response_description="The newly created subject.",
)
async def create_subject(
    subject_in: SubjectCreate,
    service: SubjectService = Depends(get_subject_service),
):
    subject = await service.create_subject(subject_in)
    return ApiResponse(
        success=True,
        message="Subject created successfully.",
        data=SubjectResponse.model_validate(subject),
    )


@router.put(
    "/{subject_id}",
    response_model=ApiResponse[SubjectResponse],
    summary="Update an existing subject",
    description="Partially update a subject's name, faculty, color, or attendance goal. "
                "If the subject name changes, the corresponding Notes Subject "
                "is automatically renamed. "
                "Returns 404 if the subject does not exist, "
                "or 409 if the new name conflicts with another subject.",
    response_description="The updated subject.",
)
async def update_subject(
    subject_id: uuid.UUID,
    subject_in: SubjectUpdate,
    service: SubjectService = Depends(get_subject_service),
):
    subject = await service.update_subject(subject_id, subject_in)
    return ApiResponse(
        success=True,
        message="Subject updated successfully.",
        data=SubjectResponse.model_validate(subject),
    )


@router.delete(
    "/{subject_id}",
    response_model=ApiResponse[None],
    summary="Delete a subject",
    description="Permanently delete a subject and its associated lecture templates "
                "and instances (cascade). Optionally delete the corresponding "
                "Notes Subject by setting delete_notes_subject=true. "
                "Returns 404 if the subject does not exist.",
    response_description="Confirmation of successful deletion.",
)
async def delete_subject(
    subject_id: uuid.UUID,
    delete_notes_subject: bool = Query(
        default=False,
        description="If true, also delete the matching Notes Subject.",
    ),
    service: SubjectService = Depends(get_subject_service),
):
    await service.delete_subject(subject_id, delete_notes_subject)
    return ApiResponse(
        success=True,
        message="Subject deleted successfully.",
        data=None,
    )
