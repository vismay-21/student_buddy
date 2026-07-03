from typing import Any, Generic, TypeVar, Optional
from pydantic import BaseModel

T = TypeVar("T")


class ApiResponse(BaseModel, Generic[T]):
    success: bool = True
    message: str = "Operation completed successfully."
    data: Optional[T] = None


class ApiErrorResponse(BaseModel):
    success: bool = False
    message: str
    errors: list[str] = []
