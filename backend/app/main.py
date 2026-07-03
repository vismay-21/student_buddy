from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import setup_logging
from app.core.exceptions import register_exception_handlers
from app.api.v1.health import router as health_router

# Setup structured logging
setup_logging()

# Instantiate FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    description="Offline-First Student Productivity Platform Backend",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Register custom and global exception handlers
register_exception_handlers(app)

# Configure CORS middleware for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health_router, prefix=settings.API_V1_PREFIX, tags=["Health"])
