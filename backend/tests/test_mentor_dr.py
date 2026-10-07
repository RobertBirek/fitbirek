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
    }
    assert not re.search(r"mentor|credential|encrypted_key|master_key|SharedPreferences", export, re.I)


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
