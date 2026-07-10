from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.constants import API_V1_PREFIX, BACKEND_VERSION
from app.core.logging import setup_logging
from app.core.exceptions import register_exception_handlers
from app.api.v1.health import router as health_router
from app.api.v1.academic.semesters import router as semesters_router
from app.api.v1.academic.subjects import router as subjects_router
from app.api.v1.academic.lecture_templates import router as lecture_templates_router
from app.api.v1.academic.lecture_instances import router as lecture_instances_router
from app.api.v1.academic.attendance_settings import router as attendance_settings_router
from app.api.v1.academic.holidays import router as holidays_router
from app.api.v1.settings.app_settings import router as app_settings_router
from app.api.v1.todo.todos import router as todos_router
from app.api.v1.notes.notes import router as notes_router
from app.api.v1.review_queue.review_queue import router as review_queue_router
from app.api.v1.activity_logs.activity_logs import router as activity_logs_router
from app.api.v1.users.users import router as users_router

# Setup structured logging
setup_logging(enable_file_logging=settings.ENABLE_FILE_LOGGING)

# Conditional Swagger/ReDoc URLs for production security
docs_url = "/docs" if settings.APP_ENV != "production" else None
redoc_url = "/redoc" if settings.APP_ENV != "production" else None

# Instantiate FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="Offline-First Student Productivity Platform Backend",
    version=BACKEND_VERSION,
    docs_url=docs_url,
    redoc_url=redoc_url
)

# Register custom and global exception handlers
register_exception_handlers(app)

# Configure CORS middleware
allow_origins = settings.ALLOWED_ORIGINS
allow_credentials = True
if "*" in allow_origins:
    allow_credentials = False

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health_router, prefix=API_V1_PREFIX, tags=["Health"])
app.include_router(users_router, prefix=f"{API_V1_PREFIX}/users", tags=["Users"])
app.include_router(semesters_router, prefix=f"{API_V1_PREFIX}/academic/semesters", tags=["Semesters"])
app.include_router(subjects_router, prefix=f"{API_V1_PREFIX}/academic/subjects", tags=["Subjects"])
app.include_router(lecture_templates_router, prefix=f"{API_V1_PREFIX}/academic/lecture-templates", tags=["Lecture Templates"])
app.include_router(lecture_instances_router, prefix=f"{API_V1_PREFIX}/academic/lecture-instances", tags=["Lecture Instances"])
app.include_router(attendance_settings_router, prefix=f"{API_V1_PREFIX}/academic/attendance-settings", tags=["Attendance Settings"])
app.include_router(holidays_router, prefix=f"{API_V1_PREFIX}/academic/holidays", tags=["Holidays"])
app.include_router(app_settings_router, prefix=f"{API_V1_PREFIX}/app-settings", tags=["App Settings"])
app.include_router(todos_router, prefix=f"{API_V1_PREFIX}/todos", tags=["Todos"])
app.include_router(notes_router, prefix=f"{API_V1_PREFIX}/notes", tags=["Notes"])
app.include_router(review_queue_router, prefix=f"{API_V1_PREFIX}/review-queue", tags=["Review Queue"])
app.include_router(activity_logs_router, prefix=f"{API_V1_PREFIX}/activity-logs", tags=["Activity Logs"])


