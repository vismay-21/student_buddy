import pytest
from httpx import AsyncClient

pytestmark = pytest.mark.asyncio


async def test_health_check(client: AsyncClient) -> None:
    response = await client.get("/api/v1/health")
    assert response.status_code == 200

    payload = response.json()
    assert payload["success"] is True
    assert "Student Buddy Backend Running" in payload["message"]
    assert payload["data"]["status"] == "healthy"
    assert payload["data"]["version"] == "1.0.0"
