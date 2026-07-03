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
    API_V1_PREFIX: str = "/api/v1"

    # Database Configuration
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/student_buddy"


# Instantiate settings instance
settings = Settings()
