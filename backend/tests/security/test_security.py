import pytest
import jwt
import uuid
from datetime import datetime, timezone, timedelta
from httpx import AsyncClient
from fastapi import HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from app.dependencies.auth import get_current_user
from app.core.config import settings
from tests.conftest import TEST_USER_ID

pytestmark = pytest.mark.asyncio


async def test_cors_headers(client: AsyncClient) -> None:
    # Send a request with a valid Origin header from ALLOWED_ORIGINS
    origin = settings.ALLOWED_ORIGINS[0]
    response = await client.options(
        "/api/v1/health",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "GET"
        }
    )
    # Options requests for CORS preflight return 200 or 204
    assert response.status_code in (200, 204)
    assert response.headers.get("access-control-allow-origin") == origin


async def test_cors_invalid_origin(client: AsyncClient) -> None:
    # If the origin is not in allowed origins, we shouldn't get access-control-allow-origin
    response = await client.options(
        "/api/v1/health",
        headers={
            "Origin": "https://malicious-site.com",
            "Access-Control-Request-Method": "GET"
        }
    )
    assert response.headers.get("access-control-allow-origin") is None


async def test_auth_dependency_no_credentials() -> None:
    # Without credentials, get_current_user raises 401
    with pytest.raises(HTTPException) as exc_info:
        await get_current_user(credentials=None)
    assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
    assert exc_info.value.detail == "Authorization header is missing"


async def test_auth_dependency_invalid_token() -> None:
    # With invalid credentials, get_current_user raises 401
    mock_credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="invalid_token")
    with pytest.raises(HTTPException) as exc_info:
        await get_current_user(credentials=mock_credentials)
    assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED
    assert "Invalid token" in exc_info.value.detail


async def test_auth_dependency_valid_token() -> None:
    # With a valid token signed with JWT_SECRET, get_current_user returns CurrentUser
    payload = {
        "sub": str(TEST_USER_ID),
        "email": "test@example.com",
        "exp": int((datetime.now(timezone.utc) + timedelta(hours=1)).timestamp())
    }
    token = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    
    mock_credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)
    current_user = await get_current_user(credentials=mock_credentials)
    
    assert current_user.id == TEST_USER_ID
    assert current_user.email == "test@example.com"
