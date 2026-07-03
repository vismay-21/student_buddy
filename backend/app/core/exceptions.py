import logging
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

logger = logging.getLogger("app.exceptions")


class AppException(Exception):
    def __init__(self, message: str, status_code: int = 400):
        super().__init__(message)
        self.message = message
        self.status_code = status_code


class NotFoundException(AppException):
    def __init__(self, message: str = "Resource not found"):
        super().__init__(message, 404)


class ConflictException(AppException):
    def __init__(self, message: str = "Resource conflict occurred"):
        super().__init__(message, 409)


class ValidationException(AppException):
    def __init__(self, message: str = "Validation error occurred"):
        super().__init__(message, 400)


class InternalServerException(AppException):
    def __init__(self, message: str = "Internal server error"):
        super().__init__(message, 500)


def register_exception_handlers(app: FastAPI) -> None:
    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "message": exc.message,
                "errors": []
            }
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        errors = []
        for error in exc.errors():
            loc = ".".join(str(x) for x in error["loc"])
            msg = error["msg"]
            errors.append(f"{loc}: {msg}")

        return JSONResponse(
            status_code=422,
            content={
                "success": False,
                "message": "Validation failed.",
                "errors": errors
            }
        )

    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        logger.error(f"Unhandled exception: {str(exc)}", exc_info=True)
        # Check environment to determine if detail should be returned
        from app.core.config import settings
        show_details = settings.APP_ENV == "development"
        
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": "Internal server error",
                "errors": [str(exc)] if show_details else []
            }
        )
