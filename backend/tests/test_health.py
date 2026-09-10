import pytest


@pytest.mark.asyncio
async def test_health_requires_a_ready_database(client, database_url):
    assert database_url.startswith("postgresql+asyncpg://")

    response = await client.get("/api/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
