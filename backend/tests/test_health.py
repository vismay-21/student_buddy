import pytest
from httpx import AsyncClient
from app.main import app
from app.dependencies.database import get_db

pytestmark = pytest.mark.asyncio


async def test_health_check(client: AsyncClient) -> None:
    response = await client.get("/api/v1/health")
    assert response.status_code == 200

    payload = response.json()
    assert payload["success"] is True
    assert "Student Buddy Backend Running" in payload["message"]
    assert payload["data"]["status"] == "healthy"
    assert payload["data"]["version"] == "1.0.0"
    assert payload["data"]["database"] == "connected"


async def test_health_check_database_offline(client: AsyncClient) -> None:
    from unittest.mock import AsyncMock
    from sqlalchemy.ext.asyncio import AsyncSession

    mock_db = AsyncMock(spec=AsyncSession)
    mock_db.execute.side_effect = Exception("Database Connection Refused")

    async def _mock_unhealthy_db():
        yield mock_db

    app.dependency_overrides[get_db] = _mock_unhealthy_db
    try:
        response = await client.get("/api/v1/health")
        assert response.status_code == 503

        payload = response.json()
        assert payload["success"] is False
        assert "Service Unhealthy" in payload["message"]
        assert payload["data"]["status"] == "unhealthy"
        assert payload["data"]["database"] == "disconnected"
    finally:
        # Clear specific override to avoid side effects
        if get_db in app.dependency_overrides:
            del app.dependency_overrides[get_db]


