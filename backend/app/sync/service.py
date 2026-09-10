from datetime import datetime, timezone
from dataclasses import dataclass
from copy import deepcopy
from hashlib import sha256
import json
from uuid import UUID

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.sync.models import SyncChange, SyncOperation, SyncRecord
from app.sync.schemas import (
    AcceptedOperation,
    PullResponse,
    IndeterminateOperationConflict,
    OperationReuseConflict,
    PushOperation,
    PushResponse,
    SyncChangeResponse,
    SyncConflict,
    SyncRecordResponse,
)


pull_limit = 500
publisher_lock_key = "sync-change-publisher"


@dataclass
class PlannedRecord:
    entity_type: str
    entity_id: UUID
    version: int
    payload: dict
    deleted_at: datetime | None
    updated_at: datetime
    persisted: SyncRecord | None


@dataclass
class PlannedWrite:
    operation: PushOperation
    record_key: str
    version: int
    deleted_at: datetime | None
    updated_at: datetime
    request_digest: str


def operation_lock_key(user_id: UUID, operation_id: UUID) -> str:
    return f"operation:{user_id}:{operation_id}"


def record_lock_key(user_id: UUID, operation: PushOperation) -> str:
    return f"record:{user_id}:{operation.entity_type}:{operation.entity_id}"


def request_digest(operation: PushOperation) -> str:
    canonical_operation = {
        "operationId": str(operation.operation_id),
        "entityType": operation.entity_type,
        "entityId": str(operation.entity_id),
        "baseVersion": operation.base_version,
        "payload": operation.payload,
        "deleted": operation.deleted,
    }
    return sha256(json.dumps(canonical_operation, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


async def acquire_advisory_locks(database: AsyncSession, lock_keys: list[str]) -> None:
    for lock_key in sorted(set(lock_keys)):
        await database.execute(
            text("SELECT pg_advisory_xact_lock(hashtextextended(:lock_key, 0))"),
            {"lock_key": lock_key},
        )


def planned_record_response(record: PlannedRecord) -> SyncRecordResponse:
    return SyncRecordResponse(
        entity_type=record.entity_type,
        entity_id=record.entity_id,
        version=record.version,
        payload=record.payload,
        deleted_at=record.deleted_at,
        updated_at=record.updated_at,
    )


def copy_planned_record(record: PlannedRecord) -> PlannedRecord:
    return PlannedRecord(
        entity_type=record.entity_type,
        entity_id=record.entity_id,
        version=record.version,
        payload=deepcopy(record.payload),
        deleted_at=record.deleted_at,
        updated_at=record.updated_at,
        persisted=record.persisted,
    )


async def push_operations(
    database: AsyncSession,
    user_id: UUID,
    operations: list[PushOperation],
) -> PushResponse:
    accepted: list[AcceptedOperation] = []
    persisted_duplicates: list[AcceptedOperation] = []
    conflicts: list[SyncConflict | IndeterminateOperationConflict | OperationReuseConflict] = []
    operation_keys = {
        operation_lock_key(user_id, operation.operation_id): operation.operation_id for operation in operations
    }
    record_operations = {
        record_lock_key(user_id, operation): operation for operation in operations
    }
    loaded_operations: dict[UUID, SyncOperation] = {}
    committed_records: dict[str, PlannedRecord] = {}
    records: dict[str, PlannedRecord] = {}
    planned_operations: dict[UUID, AcceptedOperation] = {}
    planned_digests: dict[UUID, str] = {}
    writes: list[PlannedWrite] = []

    try:
        canonical_locks = [*operation_keys, *record_operations]
        await acquire_advisory_locks(database, canonical_locks)

        for lock_key in sorted(canonical_locks):
            if lock_key in operation_keys:
                operation_id = operation_keys[lock_key]
                previous = await database.scalar(
                    select(SyncOperation)
                    .where(SyncOperation.user_id == user_id, SyncOperation.operation_id == operation_id)
                    .with_for_update()
                )
                if previous is not None:
                    loaded_operations[operation_id] = previous
                continue

            operation = record_operations[lock_key]
            record = await database.scalar(
                select(SyncRecord)
                .where(
                    SyncRecord.user_id == user_id,
                    SyncRecord.entity_type == operation.entity_type,
                    SyncRecord.entity_id == operation.entity_id,
                )
                .with_for_update()
            )
            if record is None:
                committed_records[lock_key] = PlannedRecord(
                    entity_type=operation.entity_type,
                    entity_id=operation.entity_id,
                    version=0,
                    payload={},
                    deleted_at=None,
                    updated_at=datetime.now(timezone.utc),
                    persisted=None,
                )
                records[lock_key] = copy_planned_record(committed_records[lock_key])
            else:
                committed_records[lock_key] = PlannedRecord(
                    entity_type=record.entity_type,
                    entity_id=record.entity_id,
                    version=record.version,
                    payload=deepcopy(record.payload),
                    deleted_at=record.deleted_at,
                    updated_at=record.updated_at,
                    persisted=record,
                )
                records[lock_key] = copy_planned_record(committed_records[lock_key])

        for operation in operations:
            previous = loaded_operations.get(operation.operation_id)
            if previous is not None:
                if not previous.outcome_known or previous.request_digest is None:
                    conflicts.append(IndeterminateOperationConflict(operation_id=operation.operation_id))
                    continue
                if previous.request_digest != request_digest(operation):
                    conflicts.append(OperationReuseConflict(operation_id=operation.operation_id))
                    continue
                duplicate = AcceptedOperation(
                    operation_id=operation.operation_id,
                    version=previous.version,
                    updated_at=previous.updated_at,
                    duplicate=True,
                )
                accepted.append(duplicate)
                persisted_duplicates.append(duplicate)
                continue
            if operation.operation_id in planned_operations:
                previous = planned_operations[operation.operation_id]
                if planned_digests[operation.operation_id] == request_digest(operation):
                    accepted.append(previous.model_copy(update={"duplicate": True}))
                else:
                    conflicts.append(OperationReuseConflict(operation_id=operation.operation_id))
                continue

            record_key = record_lock_key(user_id, operation)
            record = records[record_key]
            if operation.base_version != record.version:
                conflicts.append(
                    SyncConflict(
                        operation_id=operation.operation_id,
                        record=planned_record_response(committed_records[record_key]),
                    )
                )
                continue

            updated_at = datetime.now(timezone.utc)
            deleted_at = updated_at if operation.deleted else None
            record.version += 1
            record.payload = operation.payload
            record.deleted_at = deleted_at
            record.updated_at = updated_at
            outcome = AcceptedOperation(
                operation_id=operation.operation_id,
                version=record.version,
                updated_at=updated_at,
                duplicate=False,
            )
            planned_operations[operation.operation_id] = outcome
            planned_digests[operation.operation_id] = request_digest(operation)
            accepted.append(outcome)
            writes.append(
                PlannedWrite(
                    operation=operation,
                    record_key=record_key,
                    version=record.version,
                    deleted_at=deleted_at,
                    updated_at=updated_at,
                    request_digest=planned_digests[operation.operation_id],
                )
            )

        if conflicts:
            await database.rollback()
            return PushResponse(accepted=persisted_duplicates, conflicts=conflicts)

        written_record_keys = {write.record_key for write in writes}
        for record_key in written_record_keys:
            record = records[record_key]
            if record.persisted is None:
                record.persisted = SyncRecord(
                    user_id=user_id,
                    entity_type=record.entity_type,
                    entity_id=record.entity_id,
                    version=record.version,
                    payload=record.payload,
                    deleted_at=record.deleted_at,
                    updated_at=record.updated_at,
                )
                database.add(record.persisted)
            else:
                record.persisted.version = record.version
                record.persisted.payload = record.payload
                record.persisted.deleted_at = record.deleted_at
                record.persisted.updated_at = record.updated_at

        for write in writes:
            database.add(
                SyncOperation(
                    user_id=user_id,
                    operation_id=write.operation.operation_id,
                    version=write.version,
                    updated_at=write.updated_at,
                    outcome_known=True,
                    request_digest=write.request_digest,
                )
            )
        await database.flush()
        await acquire_advisory_locks(database, [publisher_lock_key])
        for write in writes:
            database.add(
                SyncChange(
                    user_id=user_id,
                    entity_type=write.operation.entity_type,
                    entity_id=write.operation.entity_id,
                    version=write.version,
                    payload=write.operation.payload,
                    deleted_at=write.deleted_at,
                    updated_at=write.updated_at,
                )
            )
        await database.flush()
        await database.commit()
    except Exception:
        await database.rollback()
        raise

    return PushResponse(accepted=accepted, conflicts=conflicts)


async def pull_changes(database: AsyncSession, user_id: UUID, cursor: int) -> PullResponse:
    changes = (
        await database.scalars(
            select(SyncChange)
            .where(SyncChange.user_id == user_id, SyncChange.cursor > cursor)
            .order_by(SyncChange.cursor)
            .limit(pull_limit)
        )
    ).all()
    response_changes = [
        SyncChangeResponse(
            cursor=change.cursor,
            entity_type=change.entity_type,
            entity_id=change.entity_id,
            version=change.version,
            payload=change.payload,
            deleted_at=change.deleted_at,
            updated_at=change.updated_at,
        )
        for change in changes
    ]
    return PullResponse(cursor=response_changes[-1].cursor if response_changes else cursor, changes=response_changes)
