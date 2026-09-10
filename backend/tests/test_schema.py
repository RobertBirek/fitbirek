import asyncio
import os
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import create_async_engine

from app.identity.models import Session, User
from app.sync.models import SyncChange, SyncOperation, SyncRecord


def test_alembic_cli_upgrades_from_outside_backend(database_url, tmp_path):
    backend_directory = Path(__file__).parents[1]
    environment = os.environ | {"DATABASE_URL": "postgresql+asyncpg://ambient:ambient@127.0.0.1:1/ambient"}
    environment.pop("PYTHONPATH", None)

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "alembic",
            "-c",
            str(backend_directory / "alembic.ini"),
            "-x",
            f"database_url={database_url}",
            "upgrade",
            "head",
        ],
        cwd=tmp_path,
        env=environment,
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 0, result.stderr


@pytest.mark.asyncio
async def test_pre_0003_sync_operation_migrates_to_an_indeterminate_state(database_url):
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", database_url)
    await asyncio.to_thread(command.downgrade, config, "0002")

    user_id = uuid4()
    operation_id = uuid4()
    engine = create_async_engine(database_url)
    try:
        async with engine.begin() as connection:
            await connection.execute(
                text("INSERT INTO users (id, email, password_hash) VALUES (:id, :email, :password_hash)"),
                {"id": user_id, "email": "legacy-migration@example.com", "password_hash": "hash"},
            )
            await connection.execute(
                text("INSERT INTO sync_operations (id, user_id, operation_id) VALUES (:id, :user_id, :operation_id)"),
                {"id": uuid4(), "user_id": user_id, "operation_id": operation_id},
            )

        await asyncio.to_thread(command.upgrade, config, "head")

        async with engine.connect() as connection:
            columns = await connection.run_sync(
                lambda sync_connection: {
                    column["name"] for column in inspect(sync_connection).get_columns("sync_operations")
                }
            )
            assert "request_digest" in columns
            result = await connection.execute(
                text(
                    "SELECT version, outcome_known, request_digest "
                    "FROM sync_operations WHERE operation_id = :operation_id"
                ),
                {"operation_id": operation_id},
            )
            version, outcome_known, request_digest = result.one()
    finally:
        await engine.dispose()

    assert version == 0
    assert outcome_known is False
    assert request_digest is None


@pytest.mark.asyncio
async def test_operation_id_is_unique_per_user(session):
    user = User(email="operation@example.com", password_hash="hash")
    session.add(user)
    await session.flush()

    session.add_all(
        [
            SyncOperation(user_id=user.id, operation_id=uuid4()),
            SyncOperation(user_id=user.id, operation_id=uuid4()),
        ]
    )
    await session.flush()

    duplicate_operation_id = uuid4()
    session.add_all(
        [
            SyncOperation(user_id=user.id, operation_id=duplicate_operation_id),
            SyncOperation(user_id=user.id, operation_id=duplicate_operation_id),
        ]
    )

    with pytest.raises(IntegrityError):
        await session.flush()
    await session.rollback()


@pytest.mark.asyncio
async def test_user_email_is_unique(session):
    session.add_all(
        [
            User(email="duplicate-email@example.com", password_hash="hash"),
            User(email="duplicate-email@example.com", password_hash="hash"),
        ]
    )

    with pytest.raises(IntegrityError):
        await session.commit()
    await session.rollback()

    session.add(User(email="recovered-email@example.com", password_hash="hash"))
    await session.commit()


@pytest.mark.asyncio
async def test_session_token_hash_is_unique(session):
    user = User(email="session-token@example.com", password_hash="hash")
    session.add(user)
    await session.flush()
    expires_at = datetime.now(timezone.utc) + timedelta(days=1)
    session.add_all(
        [
            Session(user_id=user.id, token_hash="a" * 64, csrf_hash="b" * 64, expires_at=expires_at),
            Session(user_id=user.id, token_hash="a" * 64, csrf_hash="c" * 64, expires_at=expires_at),
        ]
    )

    with pytest.raises(IntegrityError):
        await session.flush()
    await session.rollback()


@pytest.mark.asyncio
async def test_sync_record_is_unique_per_user_and_entity(session):
    user = User(email="record@example.com", password_hash="hash")
    session.add(user)
    await session.commit()

    user_id = user.id
    entity_id = uuid4()
    updated_at = datetime.now(timezone.utc)
    session.add_all(
        [
            SyncRecord(
                user_id=user_id,
                entity_type="mood",
                entity_id=entity_id,
                version=1,
                payload={"mood": "good"},
                updated_at=updated_at,
            ),
            SyncRecord(
                user_id=user_id,
                entity_type="mood",
                entity_id=entity_id,
                version=1,
                payload={"mood": "good"},
                updated_at=updated_at,
            ),
        ]
    )

    with pytest.raises(IntegrityError):
        await session.commit()
    await session.rollback()

    session.add(
        SyncRecord(
            user_id=user_id,
            entity_type="mood",
            entity_id=uuid4(),
            version=1,
            payload={"mood": "good"},
            updated_at=updated_at,
        )
    )
    await session.commit()


@pytest.mark.asyncio
async def test_schema_persists_sessions_generic_records_and_ordered_changes(session):
    user = User(email="schema@example.com", password_hash="hash")
    session.add(user)
    await session.flush()

    session.add(
        Session(
            user_id=user.id,
            token_hash="a" * 64,
            csrf_hash="b" * 64,
            expires_at=datetime.now(timezone.utc) + timedelta(days=1),
        )
    )
    entity_id = uuid4()
    session.add(
        SyncRecord(
            user_id=user.id,
            entity_type="mood",
            entity_id=entity_id,
            version=1,
            payload={"mood": "good"},
            updated_at=datetime.now(timezone.utc),
        )
    )
    updated_at = datetime.now(timezone.utc)
    first_change = SyncChange(
        user_id=user.id,
        entity_type="mood",
        entity_id=entity_id,
        version=1,
        payload={"mood": "good"},
        updated_at=updated_at,
    )
    second_change = SyncChange(
        user_id=user.id,
        entity_type="mood",
        entity_id=entity_id,
        version=2,
        payload={"mood": "great"},
        updated_at=updated_at,
    )
    session.add_all([first_change, second_change])
    await session.commit()

    assert first_change.cursor < second_change.cursor

    connection = await session.connection()
    indexes = await connection.run_sync(
        lambda sync_connection: {
            table: {index["name"] for index in inspect(sync_connection).get_indexes(table)}
            for table in ("sessions", "sync_changes", "sync_records")
        }
    )
    assert "ix_sessions_token_hash" in indexes["sessions"]
    assert "ix_sync_changes_user_cursor" in indexes["sync_changes"]
    assert "ix_sync_records_user_entity" not in indexes["sync_records"]
