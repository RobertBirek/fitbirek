import json
import pytest
import pytest_asyncio
from uuid import uuid4
from app.health.schemas import ConsentRequest, ImportRequest
from pydantic import ValidationError

def batch():
    return {"version": 1, "weights": [{"measuredAt": "2026-09-10T08:00:00+02:00", "value": 80.5, "unit": "kg", "source": "Apple Health"}], "steps": [{"day": "2026-09-10", "value": 7500, "method": "manual_verified_total"}]}

def test_contract_json():
    assert len(ImportRequest.model_validate_json(json.dumps(batch())).weights) == 1

@pytest.mark.parametrize("value", [1, "true", False])
def test_literal_consent(value):
    with pytest.raises(ValidationError):
        ConsentRequest.model_validate({"consent": value})

@pytest_asyncio.fixture
async def integration(client, session):
    from app.identity.models import User
    from app.identity.service import issue_session
    user = User(email=f"{uuid4()}@example.com", password_hash="unused")
    session.add(user)
    await session.commit()
    issued = await issue_session(session, user)
    client.cookies.set("fit_session", issued.session_token)
    headers = {"Origin": "https://fit.birek.online", "X-CSRF-Token": issued.csrf_token}
    root = "/api/integrations/apple-health"
    created = await client.post(root + "/token", json={"consent": True}, headers=headers)
    assert created.status_code == 200, created.text
    assert created.headers["cache-control"] == "no-store"
    return root, headers, {"Authorization": "Bearer " + created.json()["token"]}

@pytest.mark.asyncio
async def test_import_replay_rotation_and_deletion(client, integration):
    root, headers, bearer = integration
    first = await client.post(root + "/import", json=batch(), headers=bearer)
    assert first.status_code == 200, first.text
    assert first.json()["imported"] == 2
    again = await client.post(root + "/import", json=batch(), headers=bearer)
    assert again.json()["duplicates"] == 2
    corrected = batch()
    corrected["steps"][0]["value"] = 500
    assert (await client.post(root + "/import", json=corrected, headers=bearer)).json()["imported"] == 1
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).json()["duplicates"] == 2
    changes = (await client.get("/api/sync/pull?include_health=true")).json()["changes"]
    record = changes[0]
    operation = {"operationId": str(uuid4()), "entityType": "healthSample", "entityId": record["entityId"], "baseVersion": 1, "payload": {}, "deleted": True}
    deleted = await client.post("/api/sync/push", json={"operations": [operation]}, headers=headers)
    assert len(deleted.json()["accepted"]) == 1
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).json()["ignoredDeleted"] == 1
    revoked = await client.delete(root + "/token", headers=headers)
    assert revoked.json()["enabled"] is False
    assert revoked.json()["lastImportAt"] is not None
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).status_code == 401

@pytest.mark.asyncio
async def test_offsets_and_cookie_fallback(client, integration):
    root, headers, bearer = integration
    assert (await client.post(root + "/import", json=batch())).status_code == 401
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).json()["imported"] == 2
    body = batch()
    body["weights"][0]["measuredAt"] = "2026-09-10T06:00:00Z"
    assert (await client.post(root + "/import", json=body, headers=bearer)).json()["duplicates"] == 2
    await client.post(root + "/token", json={"consent": True}, headers=headers)
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).status_code == 401

@pytest.mark.asyncio
async def test_invalid_requests_consume_persisted_rate(client, integration):
    root, _, bearer = integration
    for _ in range(30):
        result = await client.post(root + "/import", content=b"{", headers={**bearer, "Content-Type": "application/json"})
        assert result.status_code == 422
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).status_code == 429

@pytest.mark.asyncio
async def test_stream_limit_and_tls(client, integration):
    root, _, bearer = integration
    async def chunks():
        yield b" " * 32768
        yield b" " * 32769
        raise AssertionError("must stop consuming")
    result = await client.post(root + "/import", content=chunks(), headers={**bearer, "Content-Type": "application/json"})
    assert result.status_code == 413
    result = await client.post("http://test" + root + "/import", json=batch(), headers={**bearer, "X-Forwarded-Proto": "https"})
    assert result.status_code == 403

@pytest.mark.parametrize("update", [{"version": True}, {"weights": [] , "steps": []}, {"extra": "secret"}])
def test_strict_envelope(update):
    with pytest.raises(ValidationError):
        ImportRequest.model_validate_json(json.dumps(batch() | update))

@pytest.mark.asyncio
async def test_stale_principal_after_rotation_and_revoke(client, integration, database_url):
    from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
    from sqlalchemy import select
    from app.health.models import AppleHealthToken
    from app.health.service import ImportPrincipal, process_import
    from app.identity.models import User
    from fastapi import HTTPException
    root, headers, _ = integration
    engine = create_async_engine(database_url)
    try:
        factory = async_sessionmaker(engine, expire_on_commit=False)
        for action in ("rotate", "revoke"):
            async with factory() as stale:
                token = await stale.scalar(select(AppleHealthToken))
                user = await stale.get(User, token.user_id)
                principal = ImportPrincipal(user, token.token_hash)
                if action == "rotate":
                    await client.post(root + "/token", json={"consent": True}, headers=headers)
                else:
                    await client.delete(root + "/token", headers=headers)
                with pytest.raises(HTTPException) as error:
                    await process_import(stale, principal, ImportRequest.model_validate_json(json.dumps(batch())))
                assert error.value.status_code == 401
    finally:
        await engine.dispose()

@pytest.mark.asyncio
async def test_concurrent_imports_are_idempotent(client, integration):
    import asyncio
    root, _, bearer = integration
    results = await asyncio.wait_for(asyncio.gather(*[
        client.post(root + "/import", json=batch(), headers=bearer) for _ in range(8)
    ]), timeout=15)
    assert all(result.status_code == 200 for result in results)
    assert sum(result.json()["imported"] for result in results) == 2
    assert sum(result.json()["duplicates"] for result in results) == 14

@pytest.mark.asyncio
async def test_health_sync_cannot_create_modify_or_revive(client, integration):
    root, csrf, bearer = integration
    operation = {"operationId": str(uuid4()), "entityType": "healthSample", "entityId": str(uuid4()), "baseVersion": 0, "payload": {}, "deleted": False}
    for deleted in (False, True):
        response = await client.post("/api/sync/push", json={"operations": [operation | {"deleted": deleted}]}, headers=csrf)
        assert response.json()["accepted"] == []
        assert len(response.json()["conflicts"]) == 1
    await client.post(root + "/import", json=batch(), headers=bearer)
    record = (await client.get("/api/sync/pull?include_health=true")).json()["changes"][0]
    operation.update(entityId=record["entityId"], baseVersion=1)
    response = await client.post("/api/sync/push", json={"operations": [operation]}, headers=csrf)
    assert response.json()["accepted"] == []
    operation["deleted"] = True
    assert len((await client.post("/api/sync/push", json={"operations": [operation]}, headers=csrf)).json()["accepted"]) == 1
    operation.update(operationId=str(uuid4()), baseVersion=2, deleted=False)
    assert (await client.post("/api/sync/push", json={"operations": [operation]}, headers=csrf)).json()["accepted"] == []

@pytest.mark.parametrize("field,value", [("value", True), ("value", "80"), ("value", 0), ("value", 501), ("value", float("nan")), ("measuredAt", "2026-09-10T08:00:00"), ("measuredAt", "1999-01-01T00:00:00Z"), ("source", ""), ("source", "x" * 101), ("unit", "lb")])
def test_weight_validation(field, value):
    body = batch()
    body["weights"][0][field] = value
    with pytest.raises(ValidationError):
        ImportRequest.model_validate_json(json.dumps(body))

@pytest.mark.parametrize("field,value", [("value", True), ("value", 1.5), ("value", -1), ("value", 100001), ("day", "1999-12-31"), ("day", "2999-01-01"), ("method", "sum")])
def test_steps_validation(field, value):
    body = batch()
    body["steps"][0][field] = value
    with pytest.raises(ValidationError):
        ImportRequest.model_validate_json(json.dumps(body))

@pytest.mark.asyncio
async def test_import_publisher_lock_is_atomic(client, integration, database_url, monkeypatch):
    import asyncio
    from sqlalchemy import select, func
    from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
    from app.health import service
    from app.sync.models import SyncRecord, SyncChange
    from app.sync.service import acquire_advisory_locks, publisher_lock_key
    root, _, bearer = integration
    reached = asyncio.Event()
    async def observe(database, keys):
        if publisher_lock_key in keys:
            reached.set()
        await acquire_advisory_locks(database, keys)
    monkeypatch.setattr(service, "acquire_advisory_locks", observe)
    engine = create_async_engine(database_url)
    factory = async_sessionmaker(engine)
    task = None
    try:
        async with factory() as blocker:
            await acquire_advisory_locks(blocker, [publisher_lock_key])
            task = asyncio.create_task(client.post(root + "/import", json=batch(), headers=bearer))
            await asyncio.wait_for(reached.wait(), 5)
            async with factory() as observer:
                assert await observer.scalar(select(func.count()).select_from(SyncRecord)) == 0
                assert await observer.scalar(select(func.count()).select_from(SyncChange)) == 0
            assert not task.done()
            await blocker.commit()
            assert (await asyncio.wait_for(task, 5)).json()["imported"] == 2
    finally:
        if task is not None and not task.done():
            task.cancel()
            await asyncio.gather(task, return_exceptions=True)
        await engine.dispose()

@pytest.mark.asyncio
async def test_import_and_reverse_order_sync_delete_do_not_deadlock(client, integration):
    import asyncio
    root, csrf, bearer = integration
    await client.post(root + "/import", json=batch(), headers=bearer)
    records = (await client.get("/api/sync/pull?include_health=true")).json()["changes"]
    operations = [{"operationId": str(uuid4()), "entityType": "healthSample", "entityId": record["entityId"], "baseVersion": 1, "payload": {}, "deleted": True} for record in reversed(records)]
    imported, deleted = await asyncio.wait_for(asyncio.gather(
        client.post(root + "/import", json=batch(), headers=bearer),
        client.post("/api/sync/push", json={"operations": operations}, headers=csrf),
    ), 10)
    assert imported.status_code == deleted.status_code == 200
    assert len(deleted.json()["accepted"]) == 2
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).json()["ignoredDeleted"] == 2

@pytest.mark.asyncio
async def test_parallel_rate_limit_and_hashed_token(client, integration, session):
    import asyncio
    from sqlalchemy import select
    from app.health.models import AppleHealthToken
    from app.security.tokens import hash_token
    root, csrf, bearer = integration
    stored = await session.scalar(select(AppleHealthToken))
    raw = bearer["Authorization"].removeprefix("Bearer ")
    assert stored.token_hash == hash_token(raw)
    assert stored.token_hash != raw
    assert (await client.post(root + "/token", json={"consent": True})).status_code == 403
    assert (await client.delete(root + "/token")).status_code == 403
    responses = await asyncio.wait_for(asyncio.gather(*[
        client.post(root + "/import", json=batch(), headers=bearer) for _ in range(32)
    ]), 20)
    assert sum(response.status_code == 200 for response in responses) == 30
    assert sum(response.status_code == 429 for response in responses) == 2

@pytest.mark.asyncio
async def test_second_client_delete_rebases_existing_tombstone(client, integration):
    root, csrf, bearer = integration
    await client.post(root + "/import", json=batch(), headers=bearer)
    record = (await client.get("/api/sync/pull?include_health=true")).json()["changes"][0]
    first = {"operationId": str(uuid4()), "entityType": "healthSample", "entityId": record["entityId"], "baseVersion": 1, "payload": {"forged": True}, "deleted": True}
    second = first | {"operationId": str(uuid4())}
    assert len((await client.post("/api/sync/push", json={"operations": [first]}, headers=csrf)).json()["accepted"]) == 1
    stale = (await client.post("/api/sync/push", json={"operations": [second]}, headers=csrf)).json()
    assert stale["conflicts"][0]["record"]["version"] == 2
    second.update(baseVersion=2, operationId=str(uuid4()))
    rebased = (await client.post("/api/sync/push", json={"operations": [second]}, headers=csrf)).json()
    assert len(rebased["accepted"]) == 1
    assert rebased["conflicts"] == []
    replay = (await client.post("/api/sync/push", json={"operations": [second]}, headers=csrf)).json()
    assert replay["accepted"][0]["duplicate"] is True
    assert (await client.post(root + "/import", json=batch(), headers=bearer)).json()["ignoredDeleted"] == 1
    final = (await client.get("/api/sync/pull?include_health=true")).json()["changes"][-1]
    assert final["deletedAt"] is not None
    assert final["payload"] == record["payload"]

@pytest.mark.asyncio
async def test_bearer_is_import_only_and_manual_measurements_are_untouched(client, integration, session):
    from httpx import ASGITransport, AsyncClient
    from app.main import app
    from app.identity.models import User
    from app.identity.service import issue_session
    root, csrf, bearer = integration
    manual = {"operationId": str(uuid4()), "entityType": "measurement", "entityId": str(uuid4()), "baseVersion": 0, "payload": {"weight": 85}, "deleted": False}
    assert len((await client.post("/api/sync/push", json={"operations": [manual]}, headers=csrf)).json()["accepted"]) == 1
    async with AsyncClient(transport=ASGITransport(app=app), base_url="https://test") as isolated:
        assert len(isolated.cookies) == 0
        assert (await isolated.post(root + "/import", json=batch(), headers=bearer)).json()["imported"] == 2
        for path in (root, "/api/auth/session", "/api/sync/pull"):
            assert (await isolated.get(path, headers=bearer)).status_code == 401
        assert (await isolated.post(root + "/token", json={"consent": True}, headers=bearer)).status_code == 401
        assert (await isolated.delete(root + "/token", headers=bearer)).status_code == 401
        other = User(email=f"{uuid4()}@example.com", password_hash="unused")
        session.add(other)
        await session.commit()
        issued = await issue_session(session, other)
        isolated.cookies.set("fit_session", issued.session_token)
        assert (await isolated.get("/api/sync/pull?include_health=true")).json()["changes"] == []
        assert (await isolated.get(root)).json()["enabled"] is False
    changes = (await client.get("/api/sync/pull?include_health=true")).json()["changes"]
    measurements = [change for change in changes if change["entityType"] == "measurement"]
    assert len(measurements) == 1
    assert measurements[0]["payload"] == {"weight": 85}
    assert measurements[0]["version"] == 1

@pytest.mark.asyncio
async def test_errors_never_echo_health_data_or_token(client, integration, caplog, monkeypatch):
    from app.health import router
    root, _, bearer = integration
    marker = "private-health-payload-unique-marker"
    body = batch()
    body["weights"][0]["source"] = marker
    body["weights"] *= 101
    response = await client.post(root + "/import", json=body, headers=bearer)
    assert response.status_code == 422
    assert marker not in response.text
    async def fail(*args):
        raise RuntimeError(marker + bearer["Authorization"])
    monkeypatch.setattr(router, "process_import", fail)
    response = await client.post(root + "/import", json=batch(), headers=bearer)
    assert response.status_code == 500
    assert marker not in response.text
    assert bearer["Authorization"] not in response.text
    assert marker not in caplog.text
    assert bearer["Authorization"] not in caplog.text

@pytest.mark.asyncio
async def test_forced_sync_fk_flush_does_not_deadlock_import(client, integration, database_url, monkeypatch):
    import asyncio
    from sqlalchemy import select
    from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
    from app.health import service as health
    from app.sync import service as sync
    from app.sync.schemas import PushOperation
    from app.sync.models import SyncRecord
    from app.identity.models import User
    from app.health.models import AppleHealthToken
    root, _, bearer = integration
    await client.post(root + "/import", json=batch(), headers=bearer)
    engine = create_async_engine(database_url)
    factory = async_sessionmaker(engine, expire_on_commit=False)
    sync_owns_record = asyncio.Event()
    import_owns_user = asyncio.Event()
    original = sync.acquire_advisory_locks
    async def sync_hook(database, keys):
        await original(database, keys)
        if any(key.startswith("record:") for key in keys):
            sync_owns_record.set()
            await asyncio.wait_for(import_owns_user.wait(), 5)
    async def health_hook(database, keys):
        if any(key.startswith("record:") for key in keys):
            import_owns_user.set()
        await original(database, keys)
    monkeypatch.setattr(sync, "acquire_advisory_locks", sync_hook)
    monkeypatch.setattr(health, "acquire_advisory_locks", health_hook)
    tasks = []
    try:
        async with factory() as deleting, factory() as importing:
            record = await deleting.scalar(select(SyncRecord).limit(1))
            user = await importing.get(User, record.user_id)
            token = await importing.get(AppleHealthToken, user.id)
            operation = PushOperation(operationId=uuid4(), entityType="healthSample", entityId=record.entity_id, baseVersion=1, payload={}, deleted=True)
            tasks.append(asyncio.create_task(sync.push_operations(deleting, user.id, [operation])))
            await asyncio.wait_for(sync_owns_record.wait(), 5)
            tasks.append(asyncio.create_task(health.process_import(importing, health.ImportPrincipal(user, token.token_hash), ImportRequest.model_validate_json(json.dumps(batch())))))
            results = await asyncio.wait_for(asyncio.gather(*tasks, return_exceptions=True), 8)
            assert not any(isinstance(result, BaseException) for result in results), [type(result).__name__ for result in results]
            assert len(results[0].accepted) == 1
            assert results[1]["ignoredDeleted"] == 1
    finally:
        for task in tasks:
            if not task.done():
                task.cancel()
        await asyncio.gather(*tasks, return_exceptions=True)
        await engine.dispose()

@pytest.mark.asyncio
@pytest.mark.parametrize("action", ["rotate", "revoke", "import"])
async def test_health_owner_mutex_serializes_but_allows_fk_key_share(client, integration, database_url, action):
    import asyncio
    from sqlalchemy import select, text
    from sqlalchemy.dialects import postgresql
    from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
    from app.identity.models import User
    from app.health import service
    root, csrf, bearer = integration
    statement = select(User.id).with_for_update(key_share=True, read=False)
    assert str(statement.compile(dialect=postgresql.dialect())).endswith("FOR NO KEY UPDATE")
    engine = create_async_engine(database_url)
    factory = async_sessionmaker(engine)
    task = None
    try:
        async with factory() as owner, factory() as observer:
            user_id = await owner.scalar(statement)
            # Actual FK-compatible lock succeeds while owner mutex is held.
            await asyncio.wait_for(observer.scalar(select(User.id).where(User.id == user_id).with_for_update(key_share=True, read=True)), 2)
            await observer.rollback()
            if action == "rotate":
                request = client.post(root + "/token", json={"consent": True}, headers=csrf)
            elif action == "revoke":
                request = client.delete(root + "/token", headers=csrf)
            else:
                request = client.post(root + "/import", json=batch(), headers=bearer)
            task = asyncio.create_task(request)
            async with asyncio.timeout(5):
                while True:
                    waiting = await observer.scalar(text("SELECT EXISTS (SELECT 1 FROM pg_stat_activity WHERE datname=current_database() AND wait_event_type='Lock' AND query LIKE '%users%' AND query LIKE '%FOR NO KEY UPDATE%')"))
                    if waiting:
                        break
                    assert not task.done()
                    await observer.rollback()
                    await asyncio.sleep(0.01)
            assert not task.done()
            await owner.commit()
            assert (await asyncio.wait_for(task, 5)).status_code == 200
    finally:
        if task is not None and not task.done():
            task.cancel()
            await asyncio.gather(task, return_exceptions=True)
        await engine.dispose()
