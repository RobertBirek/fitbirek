import asyncio

import pytest
import pytest_asyncio
from alembic import command
from alembic.config import Config
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from testcontainers.community.postgres import PostgresContainer


@pytest.fixture(scope="session")
def database_url():
    with PostgresContainer(
        "postgres:16-alpine",
        username="fit_test",
        password="fit_test",
        dbname="fit_test",
        driver="asyncpg",
    ) as postgres:
        yield postgres.get_connection_url()


@pytest_asyncio.fixture(autouse=True)
async def reset_database(database_url):
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", database_url)
    await asyncio.to_thread(command.upgrade, config, "head")

    engine = create_async_engine(database_url)
    try:
        async with engine.begin() as connection:
            await connection.execute(
                text(
                    "TRUNCATE TABLE login_attempts, sync_changes, sync_operations, sync_records, sessions, users RESTART IDENTITY CASCADE"
                )
            )
        yield
    finally:
        await engine.dispose()


@pytest_asyncio.fixture
async def client(database_url, monkeypatch, reset_database):
    monkeypatch.setenv("DATABASE_URL", database_url)

    from app.database import engine
    from app.main import app

    transport = ASGITransport(app=app)
    try:
        async with AsyncClient(transport=transport, base_url="https://test") as test_client:
            yield test_client
    finally:
        await engine.dispose()


@pytest_asyncio.fixture
async def session(database_url, reset_database):
    engine = create_async_engine(database_url)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    try:
        async with session_factory() as database_session:
            yield database_session
    finally:
        await engine.dispose()
