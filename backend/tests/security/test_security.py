import pytest
from httpx import AsyncClient
from fastapi.security import HTTPAuthorizationCredentials
from app.dependencies.auth import get_current_user
from app.core.config import settings

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
    # Without credentials, get_current_user returns None
    result = await get_current_user(credentials=None)
    assert result is None

async def test_auth_dependency_with_credentials() -> None:
    # With credentials, get_current_user returns mock payload
    mock_credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="mock_token")
    result = await get_current_user(credentials=mock_credentials)
    assert result == {"sub": "mock-user-id", "role": "student"}
