import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class NotesSectionBase(BaseModel):
    section_name: str = Field(..., min_length=1, max_length=100, description="Name of the section")


class NotesSectionCreate(NotesSectionBase):
    section_id: uuid.UUID | None = None
    notes_subject_id: uuid.UUID = Field(..., description="UUID of the parent notes subject")


class NotesSectionUpdate(NotesSectionBase):
    pass


class NotesSectionResponse(NotesSectionBase):
    model_config = ConfigDict(from_attributes=True)

    section_id: uuid.UUID
    notes_subject_id: uuid.UUID
    created_at: datetime
    updated_at: datetime
