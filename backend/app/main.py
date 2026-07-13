import logging
import sys
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.constants import API_V1_PREFIX, BACKEND_VERSION, SYNC_PROTOCOL_VERSION
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

logger = logging.getLogger("uvicorn")

# Conditional Swagger/ReDoc/OpenAPI URLs for production security
docs_url = "/docs" if settings.APP_ENV != "production" else None
redoc_url = "/redoc" if settings.APP_ENV != "production" else None
openapi_url = "/openapi.json" if settings.APP_ENV != "production" else None

# Instantiate FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="Offline-First Student Productivity Platform Backend",
    version=BACKEND_VERSION,
    docs_url=docs_url,
    redoc_url=redoc_url,
    openapi_url=openapi_url
)

# HTTP Security Headers Middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response: Response = await call_next(request)
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
    response.headers["Referrer-Policy"] = "no-referrer-when-downgrade"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    return response

@app.on_event("startup")
async def startup_event():
    logger.info(f"Sync Protocol Version: {SYNC_PROTOCOL_VERSION}")
    
    # Production environment validation
    if settings.APP_ENV == "production":
        logger.info("Running in production environment. Validating required secrets...")
        missing_vars = []
        
        # Check DATABASE_URL is not default or empty
        if not settings.DATABASE_URL or "localhost:5432" in settings.DATABASE_URL:
            missing_vars.append("DATABASE_URL")
            
        # Check JWT_SECRET is not default or empty
        if not settings.JWT_SECRET or settings.JWT_SECRET == "dev_fallback_jwt_secret_key_not_for_production":
            missing_vars.append("JWT_SECRET")
            
        # Check SUPABASE_URL
        if not settings.SUPABASE_URL:
            missing_vars.append("SUPABASE_URL")
            
        # Check SUPABASE_KEY
        if not settings.SUPABASE_KEY:
            missing_vars.append("SUPABASE_KEY")
            
        # Check ALLOWED_ORIGINS
        if not settings.ALLOWED_ORIGINS:
            missing_vars.append("ALLOWED_ORIGINS")
            
        if missing_vars:
            logger.error(f"CRITICAL STARTUP ERROR: The following required environment variables are missing or misconfigured for production: {', '.join(missing_vars)}")
            logger.error("Startup terminated to prevent partially configured deployments.")
            sys.exit(1)
            
        logger.info("All production required environment variables are validated successfully.")

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


