import uuid
from datetime import datetime, timezone
from pydantic import BaseModel, Field, ConfigDict, field_validator, model_validator
from app.models.todo.todo import TodoPriority, TodoStatus, TodoCreatedBy


class TodoBase(BaseModel):
    title: str = Field(
        ...,
        min_length=1,
        max_length=255,
        description="The title of the To-Do item.",
        examples=["Complete Math Assignment", "Buy Groceries"]
    )
    priority: TodoPriority = Field(
        default=TodoPriority.MEDIUM,
        description="Priority level of the task."
    )
    due_datetime: datetime | None = Field(
        default=None,
        description="Optional due date and time for the task (TIMESTAMPTZ)."
    )

    @field_validator("due_datetime")
    @classmethod
    def validate_due_datetime(cls, v: datetime | None) -> datetime | None:
        """
        Due Date Validation:
        Due dates are permitted to be in the past to allow logging historical
        or already overdue tasks (intentionally relaxed rule).
        However, to prevent obviously invalid dates, they must fall within
        a reasonable range (between the years 2000 and 2100).
        """
        if v is not None:
            if v.year < 2000 or v.year > 2100:
                raise ValueError("due_datetime must be between the years 2000 and 2100")
        return v


class TodoCreate(TodoBase):
    created_by: TodoCreatedBy = Field(
        default=TodoCreatedBy.USER,
        description="Source of the task creation."
    )


class TodoUpdate(BaseModel):
    title: str | None = Field(
        None,
        min_length=1,
        max_length=255,
        description="Updated title of the task."
    )
    priority: TodoPriority | None = Field(
        None,
        description="Updated priority of the task."
    )
    due_datetime: datetime | None = Field(
        None,
        description="Updated due date/time of the task."
    )
    status: TodoStatus | None = Field(
        None,
        description="Updated status of the task."
    )

    @field_validator("due_datetime")
    @classmethod
    def validate_due_datetime(cls, v: datetime | None) -> datetime | None:
        if v is not None:
            if v.year < 2000 or v.year > 2100:
                raise ValueError("due_datetime must be between the years 2000 and 2100")
        return v


class TodoResponse(TodoBase):
    model_config = ConfigDict(from_attributes=True)

    todo_id: uuid.UUID
    status: TodoStatus
    created_by: TodoCreatedBy
    completed_at: datetime | None
    created_at: datetime
    updated_at: datetime
    is_overdue: bool = False
    days_overdue: int | None = None

    @model_validator(mode="after")
    def calculate_overdue_fields(self) -> "TodoResponse":
        """
        Computes `is_overdue` and `days_overdue` at runtime.
        These fields are not persisted in the database.
        """
        if self.status == TodoStatus.PENDING and self.due_datetime is not None:
            due_dt = self.due_datetime
            if due_dt.tzinfo is None:
                due_dt = due_dt.replace(tzinfo=timezone.utc)
            now = datetime.now(timezone.utc)
            if due_dt < now:
                self.is_overdue = True
                diff = now - due_dt
                # Compute floor number of days elapsed since the due date
                self.days_overdue = max(0, int(diff.total_seconds() // 86400))
            else:
                self.is_overdue = False
                self.days_overdue = None
        else:
            self.is_overdue = False
            self.days_overdue = None
        return self
