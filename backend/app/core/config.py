import os
from typing import Literal
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )

    APP_NAME: str = "Student Buddy"
    APP_ENV: Literal["development", "staging", "production"] = "development"
    LOG_LEVEL: str = "INFO"

    # Database Configuration
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/student_buddy"
    DB_POOL_SIZE: int = 5
    DB_MAX_OVERFLOW: int = 10
    DB_POOL_RECYCLE: int = 1800

    # CORS Configuration
    ALLOWED_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8000",
        "http://localhost:5000",
    ]

    # JWT Authentication Configuration (for Sprint 13 compatibility)
    JWT_SECRET: str = "dev_fallback_jwt_secret_key_not_for_production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    # Supabase Configuration (for Sprint 13 compatibility)
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""

    # Logging Configuration
    ENABLE_FILE_LOGGING: bool = False




# Instantiate settings instance
settings = Settings()
