import os
import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field, field_validator, computed_field
from app.models.notes.notes_resource import UploadedVia

SUPPORTED_MIME_TYPES = {
    "application/pdf",
    "application/vnd.ms-powerpoint",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "image/jpeg",
    "image/png",
    "image/gif",
    "image/webp",
    "text/plain"
}


class NotesResourceBase(BaseModel):
    resource_name: str = Field(..., min_length=1, max_length=255, description="Display name of the resource")
    file_name: str = Field(..., min_length=1, max_length=255, description="Actual file name")
    mime_type: str = Field(..., min_length=1, max_length=100, description="MIME type of the file")
    file_size_bytes: int = Field(..., description="Size of the file in bytes")
    storage_path: str = Field(..., min_length=1, description="Path where file is stored")
    uploaded_via: UploadedVia = Field(..., description="Origin source of upload")

    @field_validator("file_size_bytes")
    @classmethod
    def validate_file_size(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("File size must be greater than 0 bytes")
        return v

    @field_validator("mime_type")
    @classmethod
    def validate_mime_type(cls, v: str) -> str:
        if v not in SUPPORTED_MIME_TYPES:
            raise ValueError(f"MIME type '{v}' is not supported")
        return v


class NotesResourceCreate(NotesResourceBase):
    section_id: uuid.UUID = Field(..., description="UUID of the parent notes section")


class NotesResourceUpdate(BaseModel):
    resource_name: str | None = Field(None, min_length=1, max_length=255)
    file_name: str | None = Field(None, min_length=1, max_length=255)
    mime_type: str | None = Field(None, min_length=1, max_length=100)
    file_size_bytes: int | None = Field(None)
    storage_path: str | None = Field(None, min_length=1)
    uploaded_via: UploadedVia | None = Field(None)

    @field_validator("file_size_bytes")
    @classmethod
    def validate_file_size(cls, v: int | None) -> int | None:
        if v is not None and v <= 0:
            raise ValueError("File size must be greater than 0 bytes")
        return v

    @field_validator("mime_type")
    @classmethod
    def validate_mime_type(cls, v: str | None) -> str | None:
        if v is not None and v not in SUPPORTED_MIME_TYPES:
            raise ValueError(f"MIME type '{v}' is not supported")
        return v


class NotesResourceResponse(NotesResourceBase):
    model_config = ConfigDict(from_attributes=True)

    resource_id: uuid.UUID
    section_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def file_extension(self) -> str:
        _, ext = os.path.splitext(self.file_name)
        return ext
