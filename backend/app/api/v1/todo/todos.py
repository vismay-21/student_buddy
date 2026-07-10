import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.schemas.common import ApiResponse
from app.schemas.todo.todo import (
    TodoCreate,
    TodoUpdate,
    TodoResponse,
)
from app.models.todo.todo import TodoPriority, TodoStatus
from app.repositories.todo.todo import TodoRepository
from app.services.todo.todo import TodoService

router = APIRouter()


async def get_todo_service(
    db: AsyncSession = Depends(get_db),
) -> TodoService:
    return TodoService(
        db=db,
        todo_repo=TodoRepository(db),
    )


@router.post(
    "",
    response_model=ApiResponse[TodoResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create a new todo task",
    description="Create a new todo task. Todos are completely independent of semesters, "
                "subjects, attendance, notes, and all academic modules.",
    response_description="The newly created todo.",
)
async def create_todo(
    todo_in: TodoCreate,
    service: TodoService = Depends(get_todo_service),
):
    todo = await service.create_todo(todo_in)
    return ApiResponse(
        success=True,
        message="Todo created successfully.",
        data=TodoResponse.model_validate(todo),
    )


@router.get(
    "",
    response_model=ApiResponse[list[TodoResponse]],
    summary="List todo tasks",
    description="Retrieve all todo tasks matching the optional filters. "
                "Results are ordered by: 1. Pending first, 2. Priority High->Med->Low, "
                "3. Earliest due_datetime first (NULL last), 4. Newest created_at first. "
                "Todos are completely independent of semesters, subjects, attendance, notes, "
                "and all academic modules.",
    response_description="List of matching todo tasks.",
)
async def list_todos(
    status: TodoStatus | None = Query(default=None, description="Filter by task status."),
    priority: TodoPriority | None = Query(default=None, description="Filter by task priority."),
    q: str | None = Query(default=None, description="Case-insensitive title search query."),
    limit: int = Query(50, ge=1, le=100, description="Limit of items returned (1-100)"),
    offset: int = Query(0, ge=0, description="Offset for pagination"),
    service: TodoService = Depends(get_todo_service),
):
    todos = await service.list_todos(status=status, priority=priority, q=q, limit=limit, offset=offset)
    responses = [TodoResponse.model_validate(t) for t in todos]
    return ApiResponse(
        success=True,
        message="Todos retrieved successfully.",
        data=responses,
    )


@router.get(
    "/{todo_id}",
    response_model=ApiResponse[TodoResponse],
    summary="Get a todo task by ID",
    description="Retrieve details of a specific todo task by its UUID. "
                "Todos are completely independent of semesters, subjects, attendance, notes, "
                "and all academic modules.",
    response_description="The requested todo.",
)
async def get_todo(
    todo_id: uuid.UUID,
    service: TodoService = Depends(get_todo_service),
):
    todo = await service.get_todo(todo_id)
    return ApiResponse(
        success=True,
        message="Todo retrieved successfully.",
        data=TodoResponse.model_validate(todo),
    )


@router.put(
    "/{todo_id}",
    response_model=ApiResponse[TodoResponse],
    summary="Update a todo task",
    description="Update a todo task's title, priority, status, or due date. "
                "Todos are completely independent of semesters, subjects, attendance, notes, "
                "and all academic modules.",
    response_description="The updated todo.",
)
async def update_todo(
    todo_id: uuid.UUID,
    todo_in: TodoUpdate,
    service: TodoService = Depends(get_todo_service),
):
    todo = await service.update_todo(todo_id, todo_in)
    return ApiResponse(
        success=True,
        message="Todo updated successfully.",
        data=TodoResponse.model_validate(todo),
    )


@router.delete(
    "/{todo_id}",
    response_model=ApiResponse[None],
    summary="Delete a todo task",
    description="Permanently delete a todo task. "
                "Todos are completely independent of semesters, subjects, attendance, notes, "
                "and all academic modules.",
    response_description="Confirmation of successful deletion.",
)
async def delete_todo(
    todo_id: uuid.UUID,
    service: TodoService = Depends(get_todo_service),
):
    await service.delete_todo(todo_id)
    return ApiResponse(
        success=True,
        message="Todo deleted successfully.",
        data=None,
    )
