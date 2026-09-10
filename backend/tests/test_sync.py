import asyncio
import json
from datetime import datetime, timezone
from uuid import uuid4

import pytest
import pytest_asyncio
from argon2 import PasswordHasher
from httpx import ASGITransport, AsyncClient
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.identity.models import User
from app.sync import service as sync_service
from app.sync.models import SyncChange, SyncOperation, SyncRecord
from app.sync.schemas import PushOperation


PASSWORD = "correct horse battery staple"
pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def account(session):
    account = User(
        email=f"account-{uuid4()}@example.com",
        password_hash=PasswordHasher().hash(PASSWORD),
    )
    session.add(account)
    await session.commit()
    return account


@pytest_asyncio.fixture
async def transaction_session_factory(database_url):
    engine = create_async_engine(database_url)
    try:
        yield async_sessionmaker(engine, expire_on_commit=False)
    finally:
        await engine.dispose()


async def authenticate(client, account):
    response = await client.post(
        "/api/auth/login",
        json={"email": account.email, "password": PASSWORD},
    )
    assert response.status_code == 204
    return {
        "Origin": "https://fit.birek.online",
        "X-CSRF-Token": response.cookies.get("fit_csrf"),
    }


def operation(
    *,
    operation_id=None,
    entity_id=None,
    base_version=0,
    payload=None,
    deleted=False,
):
    return {
        "operationId": str(operation_id or uuid4()),
        "entityType": "mood",
        "entityId": str(entity_id or uuid4()),
        "baseVersion": base_version,
        "payload": payload or {"mood": "good"},
        "deleted": deleted,
    }


def parsed_operation(**kwargs):
    return PushOperation.model_validate_json(json.dumps(operation(**kwargs)))


async def cancel_tasks(tasks):
    for task in tasks:
        if not task.done():
            task.cancel()
    await asyncio.gather(*tasks, return_exceptions=True)


async def wait_for_publisher_waiter(session_factory, push_task):
    try:
        async with asyncio.timeout(3):
            while not push_task.done():
                async with session_factory() as observer:
                    waiting = await observer.scalar(
                        text("SELECT EXISTS (SELECT 1 FROM pg_locks WHERE locktype = 'advisory' AND NOT granted)")
                    )
                if waiting:
                    return True
                await asyncio.sleep(0.01)
            return False
    except (TimeoutError, asyncio.CancelledError):
        await cancel_tasks([push_task])
        raise AssertionError("Timed out waiting for publisher lock") from None


async def wait_for_advisory_waiters(session_factory, tasks, expected_waiters):
    try:
        async with asyncio.timeout(3):
            while not all(task.done() for task in tasks):
                async with session_factory() as observer:
                    waiting = await observer.scalar(
                        text("SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND NOT granted")
                    )
                if waiting >= expected_waiters:
                    return True
                await asyncio.sleep(0.01)
            return False
    except (TimeoutError, asyncio.CancelledError):
        await cancel_tasks(tasks)
        raise AssertionError("Timed out waiting for advisory locks") from None


async def test_advisory_wait_synchronization_cancels_tasks_on_timeout(transaction_session_factory):
    blocked_task = asyncio.create_task(asyncio.Event().wait())

    try:
        with pytest.raises(AssertionError, match="Timed out waiting for advisory locks"):
            await asyncio.wait_for(
                wait_for_advisory_waiters(
                    transaction_session_factory,
                    [blocked_task],
                    expected_waiters=1,
                ),
                timeout=0.05,
            )
        assert blocked_task.cancelled()
    finally:
        if not blocked_task.done():
            blocked_task.cancel()
            await asyncio.gather(blocked_task, return_exceptions=True)


async def test_repeated_operation_is_applied_once(client, account, session):
    csrf_headers = await authenticate(client, account)
    body = {"operations": [operation()]}

    first = await client.post("/api/sync/push", json=body, headers=csrf_headers)
    second = await client.post("/api/sync/push", json=body, headers=csrf_headers)

    assert first.status_code == 200
    assert first.json()["accepted"][0]["duplicate"] is False
    assert second.status_code == 200
    assert second.json() == {
        "accepted": [
            {
                **first.json()["accepted"][0],
                "duplicate": True,
            }
        ],
        "conflicts": [],
    }
    assert await session.scalar(select(func.count()).select_from(SyncChange)) == 1


async def test_legacy_operation_without_an_outcome_is_reserved_and_indeterminate(account, session):
    operation_id = uuid4()
    entity_id = uuid4()
    session.add(
        SyncOperation(
            user_id=account.id,
            operation_id=operation_id,
            version=0,
            updated_at=datetime(2026, 9, 9, tzinfo=timezone.utc),
        )
    )
    await session.commit()

    response = await sync_service.push_operations(
        session,
        account.id,
        [parsed_operation(operation_id=operation_id, entity_id=entity_id)],
    )

    assert response.accepted == []
    assert len(response.conflicts) == 1
    assert type(response.conflicts[0]).__name__ == "IndeterminateOperationConflict"
    stored_operation = await session.scalar(select(SyncOperation).where(SyncOperation.operation_id == operation_id))
    assert stored_operation is not None
    assert stored_operation.outcome_known is False
    assert await session.scalar(select(func.count()).select_from(SyncRecord)) == 0
    assert await session.scalar(select(func.count()).select_from(SyncChange)) == 0


async def test_rejected_batch_returns_the_pre_batch_conflict_snapshot(account, session):
    entity_id = uuid4()
    committed_at = datetime.now(timezone.utc)
    session.add(
        SyncRecord(
            user_id=account.id,
            entity_type="mood",
            entity_id=entity_id,
            version=1,
            payload={"mood": "committed"},
            updated_at=committed_at,
        )
    )
    await session.commit()

    response = await sync_service.push_operations(
        session,
        account.id,
        [
            parsed_operation(entity_id=entity_id, base_version=1, payload={"mood": "planned"}),
            parsed_operation(entity_id=entity_id, base_version=1, payload={"mood": "stale"}),
        ],
    )

    assert response.accepted == []
    assert response.conflicts[0].record.version == 1
    assert response.conflicts[0].record.payload == {"mood": "committed"}
    assert response.conflicts[0].record.updated_at == committed_at
    assert await session.scalar(select(func.count()).select_from(SyncOperation)) == 0
    assert await session.scalar(select(func.count()).select_from(SyncChange)) == 0
    stored_record = await session.scalar(select(SyncRecord).where(SyncRecord.entity_id == entity_id))
    assert stored_record is not None
    assert stored_record.version == 1
    assert stored_record.payload == {"mood": "committed"}
    assert stored_record.updated_at == committed_at


async def test_dependent_same_entity_operations_accept_in_server_order(account, session):
    entity_id = uuid4()
    session.add(
        SyncRecord(
            user_id=account.id,
            entity_type="mood",
            entity_id=entity_id,
            version=1,
            payload={"mood": "committed"},
            updated_at=datetime.now(timezone.utc),
        )
    )
    await session.commit()

    response = await sync_service.push_operations(
        session,
        account.id,
        [
            parsed_operation(entity_id=entity_id, base_version=1, payload={"mood": "second"}),
            parsed_operation(entity_id=entity_id, base_version=2, payload={"mood": "third"}),
        ],
    )

    assert [accepted.version for accepted in response.accepted] == [2, 3]
    record = await session.scalar(select(SyncRecord).where(SyncRecord.entity_id == entity_id))
    assert record is not None
    assert record.version == 3
    assert record.payload == {"mood": "third"}


async def test_change_cursors_are_not_published_before_an_earlier_transaction_commits(
    account,
    transaction_session_factory,
):
    async with transaction_session_factory() as first_session, transaction_session_factory() as second_session:
        await first_session.execute(
            text("SELECT pg_advisory_xact_lock(hashtextextended('sync-change-publisher', 0))")
        )
        first_session.add(
            SyncChange(
                user_id=account.id,
                entity_type="mood",
                entity_id=uuid4(),
                version=1,
                payload={"source": "first"},
                updated_at=datetime.now(timezone.utc),
            )
        )
        await first_session.flush()
        push_task = asyncio.create_task(
            sync_service.push_operations(
                second_session,
                account.id,
                [parsed_operation(payload={"source": "second"})],
            )
        )

        waiting = await wait_for_publisher_waiter(transaction_session_factory, push_task)
        if not waiting:
            await first_session.rollback()
            await push_task
        assert waiting

        async with transaction_session_factory() as observer:
            assert (await observer.scalars(select(SyncChange).where(SyncChange.user_id == account.id))).all() == []

        await first_session.commit()
        await push_task

    async with transaction_session_factory() as observer:
        changes = (await observer.scalars(select(SyncChange).order_by(SyncChange.cursor))).all()
    assert [change.payload["source"] for change in changes] == ["first", "second"]
    assert [change.cursor for change in changes] == [changes[0].cursor, changes[0].cursor + 1]


async def test_batch_with_a_later_stale_operation_persists_no_new_data(account, session):
    stale_entity_id = uuid4()
    session.add(
        SyncRecord(
            user_id=account.id,
            entity_type="mood",
            entity_id=stale_entity_id,
            version=1,
            payload={"mood": "current"},
            updated_at=datetime.now(timezone.utc),
        )
    )
    await session.commit()

    response = await sync_service.push_operations(
        session,
        account.id,
        [
            parsed_operation(payload={"mood": "valid"}),
            parsed_operation(entity_id=stale_entity_id, payload={"mood": "stale"}),
        ],
    )

    assert response.accepted == []
    assert len(response.conflicts) == 1
    assert await session.scalar(select(func.count()).select_from(SyncOperation)) == 0
    assert await session.scalar(select(func.count()).select_from(SyncChange)) == 0
    assert await session.scalar(select(func.count()).select_from(SyncRecord)) == 1


async def test_opposite_order_record_batches_complete_without_a_deadlock(
    account,
    session,
    transaction_session_factory,
):
    first_entity_id = uuid4()
    second_entity_id = uuid4()
    now = datetime.now(timezone.utc)
    session.add_all(
        [
            SyncRecord(
                user_id=account.id,
                entity_type="mood",
                entity_id=entity_id,
                version=1,
                payload={"mood": "current"},
                updated_at=now,
            )
            for entity_id in (first_entity_id, second_entity_id)
        ]
    )
    await session.commit()

    async def push_batch(operations):
        async with transaction_session_factory() as database:
            return await sync_service.push_operations(database, account.id, operations)

    async with transaction_session_factory() as blocker:
        await blocker.execute(
            text(
                "SELECT pg_advisory_xact_lock(hashtextextended(:lock_key, 0))"
            ),
            {"lock_key": f"record:{account.id}:mood:{first_entity_id}"},
        )
        first_task = asyncio.create_task(
            push_batch(
                [
                    parsed_operation(entity_id=first_entity_id, base_version=1),
                    parsed_operation(entity_id=second_entity_id, base_version=1),
                ]
            )
        )
        second_task = asyncio.create_task(
            push_batch(
                [
                    parsed_operation(entity_id=second_entity_id, base_version=1),
                    parsed_operation(entity_id=first_entity_id, base_version=1),
                ]
            )
        )
        waiting = await wait_for_advisory_waiters(
            transaction_session_factory,
            [first_task, second_task],
            expected_waiters=2,
        )
        if not waiting:
            await blocker.rollback()
            await asyncio.gather(first_task, second_task, return_exceptions=True)
        assert waiting
        await blocker.commit()

    done, pending = await asyncio.wait({first_task, second_task}, timeout=3)
    for task in pending:
        task.cancel()
    if pending:
        await asyncio.gather(*pending, return_exceptions=True)

    assert not pending
    assert all(task.exception() is None for task in done)


async def test_sync_changes_are_isolated_per_authenticated_user(client, account, session):
    csrf_headers = await authenticate(client, account)
    other_account = User(
        email=f"other-{uuid4()}@example.com",
        password_hash=PasswordHasher().hash(PASSWORD),
    )
    session.add(other_account)
    await session.commit()

    from app.main import app

    async with AsyncClient(transport=ASGITransport(app=app), base_url="https://test") as other_client:
        other_csrf_headers = await authenticate(other_client, other_account)
        first_operation = operation(payload={"mood": "good"})
        second_operation = operation(payload={"mood": "great"})

        assert (await client.post("/api/sync/push", json={"operations": [first_operation]}, headers=csrf_headers)).status_code == 200
        assert (
            await other_client.post(
                "/api/sync/push",
                json={"operations": [second_operation]},
                headers=other_csrf_headers,
            )
        ).status_code == 200
        first_changes = (await client.get("/api/sync/pull?cursor=0")).json()["changes"]
        second_changes = (await other_client.get("/api/sync/pull?cursor=0")).json()["changes"]
        assert len(first_changes) == 1
        assert first_changes[0]["payload"] == {"mood": "good"}
        assert len(second_changes) == 1
        assert second_changes[0]["payload"] == {"mood": "great"}

    changes = (await session.scalars(select(SyncChange).order_by(SyncChange.cursor))).all()
    assert {change.user_id for change in changes} == {account.id, other_account.id}
    assert len(changes) == 2


async def test_stale_base_version_returns_the_current_record(client, account):
    csrf_headers = await authenticate(client, account)
    entity_id = uuid4()

    accepted = await client.post(
        "/api/sync/push",
        json={"operations": [operation(entity_id=entity_id, payload={"mood": "good"})]},
        headers=csrf_headers,
    )
    conflict = await client.post(
        "/api/sync/push",
        json={"operations": [operation(entity_id=entity_id, payload={"mood": "great"})]},
        headers=csrf_headers,
    )

    assert accepted.status_code == 200
    assert conflict.status_code == 200
    assert conflict.json()["accepted"] == []
    assert conflict.json()["conflicts"] == [
        {
            "operationId": conflict.json()["conflicts"][0]["operationId"],
            "record": {
                "entityType": "mood",
                "entityId": str(entity_id),
                "version": 1,
                "payload": {"mood": "good"},
                "deletedAt": None,
                "updatedAt": accepted.json()["accepted"][0]["updatedAt"],
            },
        }
    ]


async def test_modern_operation_replays_its_durable_outcome_after_later_record_changes(client, account):
    csrf_headers = await authenticate(client, account)
    operation_id = uuid4()
    entity_id = uuid4()
    original = operation(operation_id=operation_id, entity_id=entity_id, payload={"mood": "first"})
    first = await client.post("/api/sync/push", json={"operations": [original]}, headers=csrf_headers)
    later = await client.post(
        "/api/sync/push",
        json={"operations": [operation(entity_id=entity_id, base_version=1, payload={"mood": "later"})]},
        headers=csrf_headers,
    )
    replay = await client.post("/api/sync/push", json={"operations": [original]}, headers=csrf_headers)

    assert first.status_code == 200
    assert later.status_code == 200
    assert replay.json() == {
        "accepted": [{**first.json()["accepted"][0], "duplicate": True}],
        "conflicts": [],
    }


async def test_reusing_a_modern_operation_id_with_a_different_digest_is_rejected(client, account):
    csrf_headers = await authenticate(client, account)
    operation_id = uuid4()
    entity_id = uuid4()
    assert (
        await client.post(
            "/api/sync/push",
            json={"operations": [operation(operation_id=operation_id, entity_id=entity_id)]},
            headers=csrf_headers,
        )
    ).status_code == 200

    response = await client.post(
        "/api/sync/push",
        json={
            "operations": [
                operation(
                    operation_id=operation_id,
                    entity_id=entity_id,
                    base_version=1,
                    payload={"mood": "different"},
                )
            ]
        },
        headers=csrf_headers,
    )

    assert response.status_code == 200
    assert response.json()["accepted"] == []
    assert response.json()["conflicts"] == [{"operationId": str(operation_id), "kind": "operationReuse"}]


async def test_deleted_records_return_their_tombstone_timestamp(client, account):
    csrf_headers = await authenticate(client, account)
    entity_id = uuid4()

    pushed = await client.post(
        "/api/sync/push",
        json={"operations": [operation(entity_id=entity_id, deleted=True)]},
        headers=csrf_headers,
    )
    pulled = await client.get("/api/sync/pull?cursor=0")

    assert pushed.status_code == 200
    change = pulled.json()["changes"][0]
    assert change["entityId"] == str(entity_id)
    assert change["deletedAt"] == pushed.json()["accepted"][0]["updatedAt"]
    assert change["updatedAt"] == pushed.json()["accepted"][0]["updatedAt"]


async def test_pull_orders_changes_and_respects_cursor_boundaries(client, account, session):
    csrf_headers = await authenticate(client, account)
    now = datetime.now(timezone.utc)
    session.add_all(
        [
            SyncChange(
                user_id=account.id,
                entity_type="mood",
                entity_id=uuid4(),
                version=1,
                payload={"position": number},
                updated_at=now,
            )
            for number in range(501)
        ]
    )
    await session.commit()

    first = await client.get("/api/sync/pull?cursor=0")
    second = await client.get(f"/api/sync/pull?cursor={first.json()['cursor']}")
    final = await client.get(f"/api/sync/pull?cursor={second.json()['cursor']}")

    assert first.status_code == 200
    assert len(first.json()["changes"]) == 500
    assert [change["cursor"] for change in first.json()["changes"]] == sorted(
        change["cursor"] for change in first.json()["changes"]
    )
    assert first.json()["cursor"] == first.json()["changes"][-1]["cursor"]
    assert len(second.json()["changes"]) == 1
    assert second.json()["cursor"] == second.json()["changes"][0]["cursor"]
    assert final.json() == {"cursor": second.json()["cursor"], "changes": []}


async def test_pull_rejects_a_cursor_larger_than_postgresql_bigint(client, account):
    await authenticate(client, account)

    response = await client.get("/api/sync/pull?cursor=9223372036854775808")

    assert response.status_code == 422


async def test_push_request_forbids_unknown_envelope_fields(client, account):
    csrf_headers = await authenticate(client, account)

    response = await client.post(
        "/api/sync/push",
        json={"operations": [], "unexpected": True},
        headers=csrf_headers,
    )

    assert response.status_code == 422


async def test_push_operation_forbids_unknown_fields_and_type_coercion(client, account):
    csrf_headers = await authenticate(client, account)
    unknown_field = await client.post(
        "/api/sync/push",
        json={"operations": [{**operation(), "unexpected": True}]},
        headers=csrf_headers,
    )
    coerced_version = await client.post(
        "/api/sync/push",
        json={"operations": [{**operation(), "baseVersion": "0"}]},
        headers=csrf_headers,
    )

    assert unknown_field.status_code == 422
    assert coerced_version.status_code == 422


@pytest.mark.parametrize("non_finite", [float("nan"), float("inf"), float("-inf")])
async def test_push_rejects_non_finite_numbers_at_any_payload_depth(client, account, non_finite):
    csrf_headers = await authenticate(client, account)

    nested_object = await client.post(
        "/api/sync/push",
        content=json.dumps({"operations": [operation(payload={"nested": {"value": non_finite}})]}),
        headers={**csrf_headers, "Content-Type": "application/json"},
    )
    nested_array = await client.post(
        "/api/sync/push",
        content=json.dumps({"operations": [operation(payload={"nested": ["value", {"value": non_finite}]})]}),
        headers={**csrf_headers, "Content-Type": "application/json"},
    )

    assert nested_object.status_code == 422
    assert nested_array.status_code == 422


async def test_push_accepts_valid_nested_json_payload(client, account):
    csrf_headers = await authenticate(client, account)
    payload = {
        "object": {"boolean": True, "null": None, "integer": 1, "number": 1.5},
        "array": ["text", 2, False, {"nested": [3.25, None]}],
    }

    response = await client.post(
        "/api/sync/push",
        json={"operations": [operation(payload=payload)]},
        headers=csrf_headers,
    )

    assert response.status_code == 200


async def test_push_rejects_more_than_one_hundred_operations(client, account):
    csrf_headers = await authenticate(client, account)

    response = await client.post(
        "/api/sync/push",
        json={"operations": [operation() for _ in range(101)]},
        headers=csrf_headers,
    )

    assert response.status_code == 422


async def test_invalid_operation_rolls_back_the_entire_push_batch(client, account):
    csrf_headers = await authenticate(client, account)
    valid_operation = operation()
    invalid_operation = operation()
    del invalid_operation["payload"]

    response = await client.post(
        "/api/sync/push",
        json={"operations": [valid_operation, invalid_operation]},
        headers=csrf_headers,
    )

    assert response.status_code == 422
    assert (await client.get("/api/sync/pull?cursor=0")).json() == {"cursor": 0, "changes": []}
