"""Protected DR is a full database backup, not the key-free Flutter export."""
import asyncio
import importlib.util
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from subprocess import CompletedProcess, run
from uuid import uuid4
from unittest import TestCase

import pytest
from cryptography.fernet import Fernet, InvalidToken
from sqlalchemy import select
from sqlalchemy.engine import make_url
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from testcontainers.community.postgres import PostgresContainer


def test_flutter_export_schema_has_no_server_credential_source():
    """Source-boundary guard, not a substitute for Flutter export runtime tests."""
    root = Path(__file__).resolve().parents[2]
    source = (root / "lib/core/services/backup_service.dart").read_text()
    export = source.split("Future<Uint8List> exportToBytes() async {", 1)[1].split(
        "return Uint8List.fromList", 1
    )[0]
    assert set(re.findall(r"db\.select\(db\.(\w+)\)", export)) == {
        "userProfiles", "exercises", "workoutSessions", "setsLog", "moodEntries",
        "measurements", "fitnessTestResults", "personalRecords", "workoutPlans",
        "exerciseFavorites", "healthSamples",
        # Backup4 preserves raw sync evidence, not Mentor state or auth storage.
        # These two row codecs have their own field/source boundary guard below.
        "syncDeferredRecords", "syncOutbox",
    }
    assert not re.search(r"mentor|credential|encrypted_key|master_key|SharedPreferences", export, re.I)
    imports = "\n".join(re.findall(r"^import .+;", source, re.M))
    assert not re.search(r"mentor|credential|SharedPreferences", imports, re.I)


@pytest.mark.parametrize("table,row_class,fields", [
    ("SyncOutbox", "SyncOutboxData", {
        "operationId": "String", "entityType": "String", "entityId": "String",
        "baseVersion": "int", "payloadJson": "String", "attempted": "bool",
        "preserveLocal": "bool", "deleted": "bool", "createdAtUtc": "DateTime",
    }),
    ("SyncDeferredRecords", "SyncDeferredRecordData", {
        "entityType": "String", "entityId": "String", "version": "int",
        "recordJson": "String",
    }),
])
def test_flutter_recovery_row_codecs_have_no_server_credential_sources(table, row_class, fields):
    """Guard the newly exported row sources, not the contents of opaque JSON.

    A credential column/lookup in either codec must fail this guard. Raw strings
    stay direct String fields: filtering their keys would lose recovery evidence.
    Flutter runtime tests remain responsible for archive/restore byte fidelity.
    """
    root = Path(__file__).resolve().parents[2]
    tables = (root / "lib/core/database/tables/sync_tables.dart").read_text()
    declaration = tables.split(f"class {table} extends Table {{", 1)[1].split("\n}", 1)[0]
    assert set(re.findall(r"\w+Column get (\w+)\s*=>", declaration)) == set(fields)

    generated = (root / "lib/core/database/app_database.g.dart").read_text()
    row = generated.split(f"class {row_class} extends DataClass", 1)[1].split("\nclass ", 1)[0]
    codec = row.split("Map<String, dynamic> toJson(", 1)[1].split("\n  }", 1)[0]
    assert set(re.findall(r"^\s*'(\w+)':", codec, re.M)) == set(fields)
    assert set(re.findall(r"'(\w+)': serializer\.toJson<(\w+)>\((\w+)\)", codec)) == {
        (name, kind, name) for name, kind in fields.items()
    }
    assert not re.search(
        r"mentor|credential|encrypted_?key|master_?key|SharedPreferences|ApiClient|Dio",
        declaration + row, re.I,
    )


@pytest.mark.asyncio
async def test_sync_recovery_sources_exclude_server_mentor_state_without_filtering_raw(session):
    """Pull/CAS feed deferred recovery; neither may join server-only Mentor data."""
    from app.identity.models import User
    from app.mentor.models import MentorCredential, MentorMessage, MentorSession, MentorSettings
    from app.sync.schemas import PushOperation
    from app.sync.service import pull_changes, push_operations

    owner = User(email=f"{uuid4()}@example.com", password_hash="test-only")
    session.add(owner)
    await session.flush()
    now = datetime.now(timezone.utc)
    mentor_id = uuid4()
    # Synthetic sentinels only; no runtime key files, providers or real data.
    cipher_marker = "test-only-server-ciphertext"
    memory_marker = "test-only-server-memory"
    persona_marker = "test-only-server-persona"
    message_marker = "test-only-server-conversation"
    session.add_all([
        MentorCredential(user_id=owner.id, provider="openai", encrypted_key=cipher_marker.encode()),
        MentorSettings(user_id=owner.id, memory=memory_marker, persona=persona_marker, consent_text=True),
        MentorSession(id=mentor_id, user_id=owner.id, created_at=now, deleted_at=None),
    ])
    await session.flush()
    session.add(MentorMessage(session_id=mentor_id, role="user", text=message_marker, created_at=now))
    await session.commit()
    assert (await pull_changes(session, owner.id, 0, include_health=True)).changes == []

    # Unknown future JSON must remain lossless, even with security-related words
    # supplied by the user. Key-free means no credential SOURCE, not redaction.
    payload = {"trainingPrograms": {"version": 999, "raw": [
        {"label": "mentor credential encrypted_key master_key SharedPreferences", "value": None},
        "  attempted raw evidence  ",
    ]}}
    operation = PushOperation(
        operationId=uuid4(), entityType="profile", entityId=uuid4(),
        baseVersion=0, payload=payload, deleted=False,
    )
    accepted = await push_operations(session, owner.id, [operation])
    assert len(accepted.accepted) == 1
    assert not accepted.conflicts
    pulled = (await pull_changes(session, owner.id, 0, include_health=True)).model_dump(mode="json", by_alias=True)
    change, = pulled["changes"]
    assert change["entityType"] == "profile"
    assert change["entityId"] == str(operation.entity_id)
    assert change["payload"] == payload
    assert set(change) == {"cursor", "entityType", "entityId", "version", "payload", "deletedAt", "updatedAt"}

    stale = operation.model_copy(update={"operation_id": uuid4(), "payload": {"trainingPrograms": None}})
    conflict = await push_operations(session, owner.id, [stale])
    assert not conflict.accepted
    conflict_record = conflict.model_dump(mode="json", by_alias=True)["conflicts"][0]["record"]
    assert conflict_record == {key: value for key, value in change.items() if key != "cursor"}
    serialized = json.dumps({"pull": pulled, "cas": conflict_record})
    assert all(marker not in serialized for marker in (
        cipher_marker, memory_marker, persona_marker, message_marker, str(mentor_id),
    ))


@pytest.mark.asyncio
async def test_full_protected_dump_restores_account_workout_and_bound_credentials(
    database_url, session, tmp_path, monkeypatch,
):
    from app.identity.models import User
    from app.mentor.models import MentorCredential, MentorSession
    from app.sync.models import SyncRecord

    master_key = Fernet.generate_key()  # Ephemeral test key, never a runtime secret.
    owner = User(email=f"{uuid4()}@example.com", password_hash="test-only")
    session.add(owner)
    await session.flush()
    workout_id, mentor_id = uuid4(), uuid4()
    payload = {"dataStart": "2026-09-01T10:00:00Z", "notatka": "DR fixture"}
    workout = SyncRecord(user_id=owner.id, entity_type="workoutSession",
                         entity_id=workout_id, version=7, payload=payload,
                         deleted_at=None, updated_at=datetime.now(timezone.utc))
    envelope = {"user": str(owner.id), "provider": "openai", "key": "synthetic-dr-key"}
    ciphertext = Fernet(master_key).encrypt(json.dumps(envelope).encode())
    session.add_all([workout, MentorCredential(user_id=owner.id, provider="openai",
                                              encrypted_key=ciphertext),
                     MentorSession(id=mentor_id, user_id=owner.id,
                                   created_at=datetime.now(timezone.utc), deleted_at=None)])
    await session.commit()

    # Run the real bundle writer; redirect all external commands to test-only DBs.
    script = Path(__file__).resolve().parents[2] / "deploy/ops/database-backup.py"
    spec = importlib.util.spec_from_file_location("dr_backup_under_test", script)
    backup = importlib.util.module_from_spec(spec)
    with monkeypatch.context() as isolated:
        isolated.setattr(Path, "is_file", lambda _: False)  # No installed overlay reads.
        spec.loader.exec_module(backup)
    backup.ROOT = tmp_path
    source = make_url(database_url)
    assert source.username == source.database == "fit_test"

    def pg_command(url, tool, options, **kwargs):
        result = run(["docker", "run", "--rm", "--network", "host", "-i",
                      "-e", "PGPASSWORD=fit_test", "postgres:16-alpine", tool,
                      "-h", url.host, "-p", str(url.port), "-U", "fit_test",
                      "-d", url.database, *options], stderr=-1, **kwargs)
        if result.returncode:
            pytest.fail(f"Isolated {tool} failed (output deliberately suppressed)")
        return result

    def isolated_run(arguments, **kwargs):
        if "pg_dump" in arguments:
            options = arguments[arguments.index("pg_dump") + 5:]
            return pg_command(source, "pg_dump", options, **kwargs)
        if arguments[:2] == ["git", "-C"]:
            return CompletedProcess(arguments, 0, stdout="test-only\n")
        if arguments[:3] == ["docker", "image", "inspect"]:
            return CompletedProcess(arguments, 0, stdout="test-api\ntest-migration\n")
        raise AssertionError("Unexpected external backup command")

    monkeypatch.setattr(backup, "run", isolated_run)
    monkeypatch.setattr(backup, "sql", lambda _: "0009")
    previous_umask = os.umask(0o077)
    try:
        await asyncio.to_thread(backup.backup)
    finally:
        os.umask(previous_umask)
    bundle, = tmp_path.glob("20*")
    dump = bundle / "database.dump"
    assert bundle.stat().st_mode & 0o777 == 0o700
    assert dump.stat().st_mode & 0o777 == 0o600
    assert (bundle / "manifest.json").stat().st_mode & 0o777 == 0o600
    assert json.loads((bundle / "manifest.json").read_text())["sha256"] == backup.digest(dump)

    # Separate ephemeral destination container, never fit/fit_restore runtime DBs.
    with PostgresContainer("postgres:16-alpine", username="fit_test", password="fit_test",
                           dbname="fit_dr_test", driver="asyncpg") as target:
        target_url = target.get_connection_url()
        with dump.open("rb") as stream:
            await asyncio.to_thread(pg_command, make_url(target_url), "pg_restore",
                                    ["--exit-on-error", "--single-transaction", "--no-owner", "--no-acl"],
                                    stdin=stream, stdout=-1)
        engine = create_async_engine(target_url)
        try:
            async with async_sessionmaker(engine)() as restored:
                assert (await restored.get(User, owner.id)).email == owner.email
                row = await restored.scalar(select(SyncRecord).where(SyncRecord.entity_id == workout_id))
                assert (row.id, row.user_id, row.version, row.payload) == (workout.id, owner.id, 7, payload)
                assert (await restored.get(MentorSession, mentor_id)).user_id == owner.id
                credential = await restored.get(MentorCredential, (owner.id, "openai"))
                assert credential is not None, "Full DR must preserve mentor credential rows"
                # unittest's boolean assertion never renders secret operands on failure.
                TestCase().assertTrue(credential.encrypted_key == ciphertext,
                                      "Restored credential ciphertext differs")
                # Decrypt only in assertions; original key and binding are required.
                TestCase().assertTrue(
                    json.loads(Fernet(master_key).decrypt(credential.encrypted_key)) == envelope,
                    "Original master key must recover the account/provider-bound envelope",
                )
                with pytest.raises(InvalidToken):
                    Fernet(Fernet.generate_key()).decrypt(credential.encrypted_key)
        finally:
            await engine.dispose()
