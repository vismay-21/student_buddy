import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.academic.lecture_template import (
    LectureTemplateCreate,
    LectureTemplateUpdate,
    LectureTemplateResponse,
)
from app.repositories.academic.lecture_template import LectureTemplateRepository
from app.repositories.academic.lecture_instance import LectureInstanceRepository
from app.repositories.academic.subject import SubjectRepository
from app.repositories.academic.semester import SemesterRepository
from app.services.academic.lecture_template import LectureTemplateService

router = APIRouter()


async def get_lecture_template_service(
    db: AsyncSession = Depends(get_db),
) -> LectureTemplateService:
    return LectureTemplateService(
        db=db,
        lecture_template_repo=LectureTemplateRepository(db),
        lecture_instance_repo=LectureInstanceRepository(db),
        subject_repo=SubjectRepository(db),
        semester_repo=SemesterRepository(db),
    )


@router.get(
    "",
    response_model=ApiResponse[list[LectureTemplateResponse]],
    summary="List lecture templates by subject",
    description="Retrieve all recurring lecture templates belonging to a specific subject, "
                "ordered by day of the week and start time.",
    response_description="List of lecture templates for the given subject.",
)
async def list_lecture_templates(
    subject_id: uuid.UUID = Query(
        ..., description="UUID of the subject to list templates for."
    ),
    service: LectureTemplateService = Depends(get_lecture_template_service),
):
    templates = await service.list_templates_by_subject(subject_id)
    responses = [LectureTemplateResponse.model_validate(t) for t in templates]
    return ApiResponse(
        success=True,
        message="Lecture templates retrieved successfully.",
        data=responses,
    )


@router.get(
    "/{template_id}",
    response_model=ApiResponse[LectureTemplateResponse],
    summary="Get a lecture template by ID",
    description="Retrieve a single lecture template by its UUID. Returns 404 if not found.",
    response_description="The requested lecture template.",
)
async def get_lecture_template(
    template_id: uuid.UUID,
    service: LectureTemplateService = Depends(get_lecture_template_service),
):
    template = await service.get_template(template_id)
    return ApiResponse(
        success=True,
        message="Lecture template retrieved successfully.",
        data=LectureTemplateResponse.model_validate(template),
    )


@router.post(
    "",
    response_model=ApiResponse[LectureTemplateResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new lecture template",
    description="Create a recurring lecture template. "
                "Automatically generates matching Lecture Instances across the entire duration "
                "of the subject's semester, excluding any active holiday dates. "
                "Returns 404 if the subject does not exist, or 409 if the schedule conflicts "
                "with an existing template for this subject.",
    response_description="The newly created lecture template.",
)
async def create_lecture_template(
    template_in: LectureTemplateCreate,
    service: LectureTemplateService = Depends(get_lecture_template_service),
):
    template = await service.create_template(template_in)
    return ApiResponse(
        success=True,
        message="Lecture template created successfully.",
        data=LectureTemplateResponse.model_validate(template),
    )


@router.put(
    "/{template_id}",
    response_model=ApiResponse[LectureTemplateResponse],
    summary="Update an existing lecture template",
    description="Partially update day of the week, start/end time, or room for a template. "
                "If the day of the week changes, future scheduled unmarked instances "
                "are automatically recreated on the new day of the week. Past instances and "
                "future marked instances are left untouched. "
                "Returns 404 if the template does not exist, or 409 if the updated schedule "
                "conflicts with another template for the subject.",
    response_description="The updated lecture template.",
)
async def update_lecture_template(
    template_id: uuid.UUID,
    template_in: LectureTemplateUpdate,
    service: LectureTemplateService = Depends(get_lecture_template_service),
):
    template = await service.update_template(template_id, template_in)
    return ApiResponse(
        success=True,
        message="Lecture template updated successfully.",
        data=LectureTemplateResponse.model_validate(template),
    )


@router.delete(
    "/{template_id}",
    response_model=ApiResponse[None],
    summary="Delete a lecture template",
    description="Permanently delete a lecture template. Automatically deletes all associated "
                "lecture instances via database foreign key cascade settings. "
                "Returns 404 if the template does not exist.",
    response_description="Confirmation of successful deletion.",
)
async def delete_lecture_template(
    template_id: uuid.UUID,
    service: LectureTemplateService = Depends(get_lecture_template_service),
):
    await service.delete_template(template_id)
    return ApiResponse(
        success=True,
        message="Lecture template deleted successfully.",
        data=None,
    )
