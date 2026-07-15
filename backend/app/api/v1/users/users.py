import uuid
from typing import Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, exists
from sqlalchemy.orm import selectinload, joinedload

from app.core.database import get_db
from app.dependencies.auth import get_current_user
from app.services.auth.authentication_service import CurrentUser
from app.services.users.user import UserService
from app.schemas.common import ApiResponse
from app.core.constants import SYNC_PROTOCOL_VERSION
from app.schemas.users.bootstrap import SyncBootstrapResponse

# SQLAlchemy Models
from app.models.settings.app_settings import AppSettings
from app.models.academic.semester import Semester
from app.models.academic.subject import Subject
from app.models.academic.lecture_template import LectureTemplate
from app.models.academic.lecture_instance import LectureInstance
from app.models.academic.holiday import Holiday
from app.models.academic.attendance_settings import AttendanceSettings
from app.models.todo.todo import Todo
from app.models.notes.notes_subject import NotesSubject
from app.models.notes.notes_section import NotesSection
from app.models.notes.notes_resource import NotesResource
from app.models.review_queue.review_queue import ReviewQueue
from app.models.activity_logs.activity_log import ActivityLog, ActionType

# Response Schemas
from app.schemas.academic.semester import SemesterResponse
from app.schemas.academic.subject import SubjectResponse
from app.schemas.academic.lecture_template import LectureTemplateResponse
from app.schemas.academic.lecture_instance import LectureInstanceDetailResponse
from app.schemas.academic.holiday import HolidayResponse
from app.schemas.academic.attendance_settings import AttendanceSettingsResponse
from app.schemas.settings.app_settings import AppSettingsResponse
from app.schemas.todo.todo import TodoResponse
from app.schemas.notes.notes_subject import NotesSubjectDetailResponse
from app.schemas.review_queue.review_queue import ReviewQueueResponse
from app.schemas.activity_logs.activity_log import ActivityLogResponse

# Service / Helpers for dynamic summaries
from app.repositories.review_queue.review_queue import ReviewQueueRepository
from app.services.review_queue.review_queue import ReviewQueueService
from app.repositories.activity_logs.activity_log import ActivityLogRepository
from app.services.activity_logs.summary import bulk_populate_activity_summaries

router = APIRouter()


@router.post(
    "/me/initialize",
    response_model=ApiResponse[dict],
    status_code=status.HTTP_200_OK,
    summary="Initialize user profile and default settings",
    description="Idempotently create user and app_settings rows on first login."
)
async def initialize_user(
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user)
):
    service = UserService(db)
    user = await service.initialize_user(current_user.id, current_user.email)
    
    return ApiResponse(
        success=True,
        message="User initialized successfully.",
        data={
            "id": str(user.id),
            "email": user.email
        }
    )


@router.get(
    "/me/bootstrap",
    response_model=SyncBootstrapResponse,
    status_code=status.HTTP_200_OK,
    summary="Get complete user workspace snapshot",
    description="Retrieve all user-owned data from PostgreSQL to seed the local SQLite database."
)
async def bootstrap_user(
    since: Optional[datetime] = Query(None, description="Only fetch changes since this timestamp"),
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user)
):
    # 1. Fetch App Settings
    app_settings_stmt = select(AppSettings).where(AppSettings.user_id == current_user.id)
    if since:
        app_settings_stmt = app_settings_stmt.where(AppSettings.updated_at > since)
    app_settings_row = await db.scalar(app_settings_stmt)
    app_settings_data = AppSettingsResponse.model_validate(app_settings_row) if app_settings_row else None

    # 2. Fetch Semesters
    semesters_stmt = (
        select(Semester)
        .where(Semester.user_id == current_user.id)
        .options(selectinload(Semester.attendance_settings))
        .order_by(Semester.semester_number.asc())
    )
    if since:
        semesters_stmt = semesters_stmt.where(Semester.updated_at > since)
    semesters = (await db.scalars(semesters_stmt)).all()
    semesters_data = [SemesterResponse.model_validate(sem) for sem in semesters]

    # 3. Fetch Attendance Settings
    attendance_stmt = (
        select(AttendanceSettings)
        .join(Semester)
        .where(Semester.user_id == current_user.id)
    )
    if since:
        attendance_stmt = attendance_stmt.where(AttendanceSettings.updated_at > since)
    attendance_settings = (await db.scalars(attendance_stmt)).all()
    attendance_settings_data = [
        AttendanceSettingsResponse.model_validate(att) for att in attendance_settings
    ]

    # 4. Fetch Subjects
    subjects_stmt = (
        select(Subject)
        .join(Semester)
        .where(Semester.user_id == current_user.id)
        .order_by(Subject.subject_name.asc())
    )
    if since:
        subjects_stmt = subjects_stmt.where(Subject.updated_at > since)
    subjects = (await db.scalars(subjects_stmt)).all()
    subjects_data = [SubjectResponse.model_validate(sub) for sub in subjects]

    # 5. Fetch Lecture Templates
    lecture_templates_stmt = (
        select(LectureTemplate)
        .join(Subject)
        .join(Semester)
        .where(Semester.user_id == current_user.id)
    )
    if since:
        lecture_templates_stmt = lecture_templates_stmt.where(LectureTemplate.updated_at > since)
    lecture_templates = (await db.scalars(lecture_templates_stmt)).all()
    lecture_templates_data = [LectureTemplateResponse.model_validate(lt) for lt in lecture_templates]

    # 6. Fetch Lecture Instances
    lecture_instances_stmt = (
        select(LectureInstance)
        .join(LectureInstance.lecture_template)
        .join(LectureTemplate.subject)
        .join(Subject.semester)
        .options(
            joinedload(LectureInstance.lecture_template)
            .joinedload(LectureTemplate.subject)
        )
        .where(Semester.user_id == current_user.id)
    )
    if since:
        lecture_instances_stmt = lecture_instances_stmt.where(LectureInstance.updated_at > since)
    lecture_instances_stmt = lecture_instances_stmt.order_by(
        LectureInstance.lecture_date.asc(),
        LectureTemplate.start_time.asc()
    )
    lecture_instances = (await db.scalars(lecture_instances_stmt)).all()
    lecture_instances_data = [LectureInstanceDetailResponse.model_validate(li) for li in lecture_instances]

    # 7. Fetch Holidays
    holidays_stmt = (
        select(Holiday)
        .join(Semester)
        .where(Semester.user_id == current_user.id)
        .order_by(Holiday.holiday_date.asc())
    )
    if since:
        holidays_stmt = holidays_stmt.where(Holiday.updated_at > since)
    holidays = (await db.scalars(holidays_stmt)).all()
    holidays_data = [HolidayResponse.model_validate(h) for h in holidays]

    # 8. Fetch Todos
    todos_stmt = (
        select(Todo)
        .where(Todo.user_id == current_user.id)
        .order_by(Todo.created_at.desc())
    )
    if since:
        todos_stmt = todos_stmt.where(Todo.updated_at > since)
    todos = (await db.scalars(todos_stmt)).all()
    todos_data = [TodoResponse.model_validate(t) for t in todos]

    # 9. Fetch Notes Hierarchy
    notes_stmt = (
        select(NotesSubject)
        .join(Semester)
        .where(Semester.user_id == current_user.id)
        .options(
            selectinload(NotesSubject.sections)
            .selectinload(NotesSection.resources)
        )
    )
    if since:
        has_updated_section = exists(
            select(1)
            .select_from(NotesSection)
            .where(
                NotesSection.notes_subject_id == NotesSubject.notes_subject_id,
                NotesSection.updated_at > since
            )
        )
        has_updated_resource = exists(
            select(1)
            .select_from(NotesResource)
            .join(NotesSection, NotesResource.section_id == NotesSection.section_id)
            .where(
                NotesSection.notes_subject_id == NotesSubject.notes_subject_id,
                NotesResource.updated_at > since
            )
        )
        notes_stmt = notes_stmt.where(
            (NotesSubject.updated_at > since) |
            has_updated_section |
            has_updated_resource
        )
    notes_subjects = (await db.scalars(notes_stmt)).all()
    notes_subjects_data = [NotesSubjectDetailResponse.model_validate(ns) for ns in notes_subjects]

    review_stmt = select(ReviewQueue).where(ReviewQueue.user_id == current_user.id)
    if since:
        review_stmt = review_stmt.where(
            (ReviewQueue.created_at > since) | (ReviewQueue.resolved_at > since)
        )
    review_queue_items = (await db.scalars(review_stmt)).all()
    review_service = ReviewQueueService(db, ReviewQueueRepository(db, current_user.id))
    await review_service._bulk_populate_summaries(review_queue_items)
    review_queue_data = [ReviewQueueResponse.model_validate(rq) for rq in review_queue_items]

    # 11. Fetch Activity Logs
    activity_stmt = select(ActivityLog).where(ActivityLog.user_id == current_user.id)
    if since:
        activity_stmt = activity_stmt.where(ActivityLog.created_at > since)
    logs = (await db.scalars(activity_stmt)).all()
    await bulk_populate_activity_summaries(db, logs)
    activity_logs_data = [ActivityLogResponse.model_validate(l) for l in logs]

    # 12. Fetch Deletion Logs
    deletions_data = []
    if since:
        del_stmt = select(ActivityLog).where(
            ActivityLog.user_id == current_user.id,
            ActivityLog.action_type == ActionType.DELETED,
            ActivityLog.created_at > since
        )
        deletion_logs = (await db.scalars(del_stmt)).all()
        deletions_data = [
            {
                "entity_type": log.entity_type.value if hasattr(log.entity_type, 'value') else str(log.entity_type),
                "entity_id": str(log.entity_id),
                "deleted_at": log.created_at.isoformat()
            }
            for log in deletion_logs
        ]

    bootstrap_payload = {
        "app_settings": app_settings_data,
        "semesters": semesters_data,
        "subjects": subjects_data,
        "lecture_templates": lecture_templates_data,
        "lecture_instances": lecture_instances_data,
        "holidays": holidays_data,
        "attendance_settings": attendance_settings_data,
        "todos": todos_data,
        "notes_subjects": notes_subjects_data,
        "review_queue": review_queue_data,
        "activity_logs": activity_logs_data,
        "deletions": deletions_data
    }

    return SyncBootstrapResponse(
        success=True,
        message="Workspace bootstrap snapshot generated successfully.",
        sync_version=SYNC_PROTOCOL_VERSION,
        generated_at=datetime.now(timezone.utc),
        data=bootstrap_payload
    )
