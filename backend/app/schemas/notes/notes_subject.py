import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict
from app.schemas.notes.notes_resource import NotesResourceResponse
from app.schemas.notes.notes_section import NotesSectionResponse


class NotesSubjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    notes_subject_id: uuid.UUID
    semester_id: uuid.UUID
    notes_subject_name: str
    created_at: datetime
    updated_at: datetime


class NotesSectionDetailResponse(NotesSectionResponse):
    resources: list[NotesResourceResponse] = []


class NotesSubjectDetailResponse(NotesSubjectResponse):
    sections: list[NotesSectionDetailResponse] = []
