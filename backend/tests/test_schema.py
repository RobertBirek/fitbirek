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
from pydantic import ValidationError
from sqlalchemy import inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import create_async_engine

from app.identity.models import Session, User
from app.mentor.catalog import PROFILES, profile_for_key, public_profiles
from app.mentor.schemas import SettingsPatch
from app.sync.models import SyncChange, SyncOperation, SyncRecord


DEFAULT_MENTOR_PERSONA = (
    "Jesteś Mentorem FitBirek, wspierającym i rzeczowym trenerem dla osoby ćwiczącej "
    "rekreacyjnie. Odpowiadaj po polsku, prosto i zwięźle. Najpierw pomagaj określić "
    "najbliższy bezpieczny krok; gdy brakuje danych, zadaj jedno konkretne pytanie. "
    "Zachęcaj bez oceniania i bez presji. Nie diagnozuj ani nie zastępuj lekarza lub "
    "fizjoterapeuty; przy bólu, urazie lub niepokojących objawach zalecaj przerwanie "
    "ćwiczeń i konsultację ze specjalistą. Propozycje treningu lub serii przedstawiaj "
    "jasno, ale nigdy nie zakładaj ich wykonania ani nie zapisuj bez potwierdzenia użytkownika."
)


def test_mentor_model_catalog_exposes_only_enabled_public_profiles():
    profiles = public_profiles()

    assert profiles == [
        {
            "key": "legacy-gpt-4.1-mini-2025-04-14",
            "identifier": "gpt-4.1-mini-2025-04-14",
            "label": "GPT-4.1 mini",
            "quality_class": "sprawdzony",
            "cost_warning": "Profil legacy o niskim koszcie.",
        },
        {
            "key": "gpt-6-luna",
            "identifier": "gpt-6-luna",
            "label": "GPT-6 Luna",
            "quality_class": "ekonomiczny",
            "cost_warning": "Niski koszt; model do codziennych rozmów.",
        },
        {
            "key": "gpt-6.1-sol",
            "identifier": "gpt-6.1-sol",
            "label": "GPT-6.1 Sol",
            "quality_class": "zrównoważony",
            "cost_warning": "Wyższy koszt niż Luna; używaj świadomie.",
        },
        {
            "key": "gpt-6-astra",
            "identifier": "gpt-6-astra",
            "label": "GPT-6 Astra",
            "quality_class": "najwyższa jakość",
            "cost_warning": "Najwyższy koszt; używaj tylko do złożonych pytań.",
        },
    ]
    assert all("provider_model_id" not in profile for profile in profiles)
    assert all("reasoning_effort" not in profile for profile in profiles)
    assert all("max_input_tokens" not in profile for profile in profiles)
    assert all("max_output_tokens" not in profile for profile in profiles)


def test_mentor_model_catalog_resolves_only_enabled_profiles():
    profile = profile_for_key("legacy-gpt-4.1-mini-2025-04-14")

    assert profile == PROFILES["legacy-gpt-4.1-mini-2025-04-14"]
    assert profile.provider_model_id == "gpt-4.1-mini-2025-04-14"
    assert profile_for_key("gpt-6-luna") == PROFILES["gpt-6-luna"]
    assert profile_for_key("unknown-profile") is None


def test_mentor_model_catalog_defines_enabled_gpt_six_profiles():
    assert [
        (
            profile.key,
            profile.reasoning_effort,
            profile.max_input_tokens,
            profile.max_output_tokens,
            profile.enabled,
        )
        for profile in (
            PROFILES["gpt-6-luna"],
            PROFILES["gpt-6.1-sol"],
            PROFILES["gpt-6-astra"],
        )
    ] == [
        ("gpt-6-luna", "none", 6000, 800, True),
        ("gpt-6.1-sol", "low", 6000, 1600, True),
        ("gpt-6-astra", "low", 6000, 1600, True),
    ]


def test_settings_patch_accepts_only_partial_strict_context_consents():
    patch = SettingsPatch(context_consents={"training": True, "note": False})

    assert patch.model_fields_set == {"context_consents"}
    assert patch.context_consents.model_fields_set == {"training", "note"}
    assert patch.context_consents.training is True
    assert patch.context_consents.note is False
    with pytest.raises(ValidationError):
        SettingsPatch(context_consents={"unknown": True})
    with pytest.raises(ValidationError):
        SettingsPatch(context_consents={"training": None})


@pytest.mark.asyncio
async def test_mentor_0009_upgrade_adds_customization_defaults(database_url):
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", database_url)
    await asyncio.to_thread(command.downgrade, config, "0009")

    engine = create_async_engine(database_url)
    models = (
        "gpt-4.1-mini-2025-04-14",
        "gpt-4.1-mini",
        "unknown-model",
    )
    try:
        async with engine.begin() as connection:
            for index, model in enumerate(models):
                mentor_user_id = uuid4()
                await connection.execute(
                    text("INSERT INTO users (id, email, password_hash) VALUES (:id, :email, :password_hash)"),
                    {
                        "id": mentor_user_id,
                        "email": f"mentor-migration-{index}@example.com",
                        "password_hash": "hash",
                    },
                )
                await connection.execute(
                    text(
                        "INSERT INTO mentor_settings "
                        "(user_id, consent_text, consent_voice, memory, model, tts_model, stt_model, "
                        "voice_id, voices, revision) "
                        "VALUES (:user_id, false, false, '', :model, 'tts', 'stt', 'voice', '[]', 0)"
                    ),
                    {"user_id": mentor_user_id, "model": model},
                )

        await asyncio.to_thread(command.upgrade, config, "0010")

        async with engine.connect() as connection:
            rows = (
                await connection.execute(
                    text(
                        "SELECT model, model_profile_key, persona, context_policy_version, context_generation_digest, "
                        "consent_context_training, consent_context_profile, consent_context_weight, "
                        "consent_context_note, consent_context_apple_health "
                        "FROM mentor_settings ORDER BY model"
                    )
                )
            ).mappings().all()
    finally:
        await engine.dispose()

    rows_by_model = {row["model"]: row for row in rows}
    for model in models[:2]:
        assert rows_by_model[model]["model_profile_key"] == "legacy-gpt-4.1-mini-2025-04-14"
    assert rows_by_model["unknown-model"]["model_profile_key"] is None
    for row in rows:
        assert row["persona"] == DEFAULT_MENTOR_PERSONA
        assert row["context_policy_version"] == 0
        assert row["context_generation_digest"] == ""
        assert row["consent_context_training"] is False
        assert row["consent_context_profile"] is False
        assert row["consent_context_weight"] is False
        assert row["consent_context_note"] is False
        assert row["consent_context_apple_health"] is False


@pytest.mark.asyncio
async def test_mentor_0010_backfill_uses_frozen_persona(database_url, monkeypatch):
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", database_url)
    await asyncio.to_thread(command.downgrade, config, "0009")

    engine = create_async_engine(database_url)
    user_id = uuid4()
    try:
        async with engine.begin() as connection:
            await connection.execute(
                text("INSERT INTO users (id, email, password_hash) VALUES (:id, :email, :password_hash)"),
                {"id": user_id, "email": "mentor-frozen-persona@example.com", "password_hash": "hash"},
            )
            await connection.execute(
                text(
                    "INSERT INTO mentor_settings "
                    "(user_id, consent_text, consent_voice, memory, model, tts_model, stt_model, "
                    "voice_id, voices, revision) "
                    "VALUES (:user_id, false, false, '', 'unknown-model', 'tts', 'stt', 'voice', '[]', 0)"
                ),
                {"user_id": user_id},
            )

        from app.mentor import catalog

        monkeypatch.setattr(catalog, "DEFAULT_PERSONA", "Bieżący domyślny tekst nie może zmienić migracji.")
        await asyncio.to_thread(command.upgrade, config, "0010")

        async with engine.connect() as connection:
            persona = (
                await connection.execute(
                    text("SELECT persona FROM mentor_settings WHERE user_id = :user_id"),
                    {"user_id": user_id},
                )
            ).scalar_one()
    finally:
        await engine.dispose()

    assert persona == DEFAULT_MENTOR_PERSONA


@pytest.mark.asyncio
async def test_mentor_0010_keeps_legacy_settings_insert_compatible(database_url):
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", database_url)
    await asyncio.to_thread(command.downgrade, config, "0009")
    await asyncio.to_thread(command.upgrade, config, "0010")

    engine = create_async_engine(database_url)
    user_id = uuid4()
    try:
        async with engine.begin() as connection:
            await connection.execute(
                text("INSERT INTO users (id, email, password_hash) VALUES (:id, :email, :password_hash)"),
                {"id": user_id, "email": "mentor-legacy-insert@example.com", "password_hash": "hash"},
            )
            await connection.execute(
                text(
                    "INSERT INTO mentor_settings "
                    "(user_id, consent_text, consent_voice, memory, model, tts_model, stt_model, "
                    "voice_id, voices, revision) "
                    "VALUES (:user_id, false, false, '', 'gpt-4.1-mini-2025-04-14', "
                    "'tts', 'stt', 'voice', '[]', 0)"
                ),
                {"user_id": user_id},
            )
            row = (
                await connection.execute(
                    text(
                        "SELECT persona, context_policy_version, context_generation_digest, consent_context_training, "
                        "consent_context_profile, consent_context_weight, consent_context_note, "
                        "consent_context_apple_health FROM mentor_settings WHERE user_id = :user_id"
                    ),
                    {"user_id": user_id},
                )
            ).mappings().one()
    finally:
        await engine.dispose()

    assert row["persona"] == DEFAULT_MENTOR_PERSONA
    assert row["context_policy_version"] == 0
    assert row["context_generation_digest"] == ""
    assert row["consent_context_training"] is False
    assert row["consent_context_profile"] is False
    assert row["consent_context_weight"] is False
    assert row["consent_context_note"] is False
    assert row["consent_context_apple_health"] is False


@pytest.mark.asyncio
async def test_mentor_0010_downgrade_removes_customization_columns(database_url):
    config = Config("alembic.ini")
    config.set_main_option("sqlalchemy.url", database_url)

    engine = create_async_engine(database_url)
    user_id = uuid4()
    try:
        async with engine.begin() as connection:
            await connection.execute(
                text("INSERT INTO users (id, email, password_hash) VALUES (:id, :email, :password_hash)"),
                {"id": user_id, "email": "mentor-downgrade@example.com", "password_hash": "hash"},
            )
            await connection.execute(
                text(
                    "INSERT INTO mentor_settings "
                    "(user_id, consent_text, consent_voice, memory, model, tts_model, stt_model, "
                    "voice_id, voices, revision, persona, model_profile_key, context_policy_version, "
                    "consent_context_training, consent_context_profile, consent_context_weight, "
                    "consent_context_note, consent_context_apple_health) "
                    "VALUES (:user_id, false, false, '', :model, 'tts', 'stt', 'voice', '[]', 0, "
                    ":persona, 'legacy-gpt-4.1-mini-2025-04-14', 1, false, false, false, false, false)"
                ),
                {
                    "user_id": user_id,
                    "model": "gpt-4.1-mini-2025-04-14",
                    "persona": DEFAULT_MENTOR_PERSONA,
                },
            )

        await asyncio.to_thread(command.downgrade, config, "0009")

        async with engine.connect() as connection:
            columns = await connection.run_sync(
                lambda sync_connection: {
                    column["name"] for column in inspect(sync_connection).get_columns("mentor_settings")
                }
            )
            model = (
                await connection.execute(
                    text("SELECT model FROM mentor_settings WHERE user_id = :user_id"),
                    {"user_id": user_id},
                )
            ).scalar_one()
    finally:
        await engine.dispose()

    assert columns.isdisjoint(
        {
            "persona",
            "model_profile_key",
            "context_policy_version",
            "context_generation_digest",
            "consent_context_training",
            "consent_context_profile",
            "consent_context_weight",
            "consent_context_note",
            "consent_context_apple_health",
        }
    )
    assert model == "gpt-4.1-mini-2025-04-14"


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
