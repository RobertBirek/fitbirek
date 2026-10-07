import json
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from hashlib import sha256
from uuid import UUID, uuid5

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.health.contract import (
    HEALTH_SAMPLE_ENTITY_TYPE,
    IMPORT_MAX_PER_WINDOW,
    IMPORT_WINDOW_SECONDS,
    STEPS_METHOD_MANUAL_VERIFIED_TOTAL,
    STEPS_SOURCE,
    WARSAW_ZONE,
    WEIGHT_METHOD_HEALTH_SAMPLE,
    WEIGHT_SAMPLE_KIND,
    STEPS_SAMPLE_KIND,
)
from app.health.models import AppleHealthImportLimit, AppleHealthStepDigest, AppleHealthToken
from app.health.schemas import ImportRequest, StepsSampleInput, WeightSampleInput
from app.identity.models import User
from app.security.tokens import create_token, hash_token
from app.security.rate_limit import database_now
from app.sync.models import SyncChange, SyncRecord
from app.sync.service import acquire_advisory_locks, publisher_lock_key


@dataclass
class ImportPrincipal:
    account: User
    token_hash: str


@dataclass
class PlannedChange:
    entity_id: UUID
    version: int
    payload: dict
    updated_at: datetime


def integration_status_dict(token: AppleHealthToken | None) -> dict[str, object]:
    return {
        "enabled": token is not None and token.token_hash is not None,
        "createdAt": token.created_at if token is not None else None,
        "lastImportAt": token.last_import_at if token is not None else None,
    }


async def current_token(database: AsyncSession, user_id: UUID) -> AppleHealthToken | None:
    return await database.scalar(select(AppleHealthToken).where(AppleHealthToken.user_id == user_id))


async def rotate_token(database: AsyncSession, user_id: UUID) -> tuple[AppleHealthToken, str]:
    # Serialize with revoke and imports through the account row lock.
    await database.scalar(select(User.id).where(User.id == user_id).with_for_update(key_share=True))
    now = datetime.now(timezone.utc)
    stored = await database.scalar(
        select(AppleHealthToken).where(AppleHealthToken.user_id == user_id).with_for_update()
    )
    cleartext = create_token()
    if stored is None:
        stored = AppleHealthToken(user_id=user_id, token_hash=hash_token(cleartext), created_at=now)
        database.add(stored)
    else:
        stored.token_hash = hash_token(cleartext)
        stored.created_at = now
    await database.execute(delete(AppleHealthImportLimit).where(AppleHealthImportLimit.user_id == user_id))
    await database.commit()
    return stored, cleartext


async def revoke_token(database: AsyncSession, user_id: UUID) -> None:
    await database.scalar(select(User.id).where(User.id == user_id).with_for_update(key_share=True))
    stored = await current_token(database, user_id)
    if stored is not None:
        stored.token_hash = None
    await database.commit()


async def require_import_token(
    request: Request,
    database: AsyncSession = Depends(get_session),
) -> ImportPrincipal:
    """Bearer-token authentication for imports. Cookies are never consulted."""
    header = request.headers.get("authorization")
    credentials_token = None
    if header is not None and len(header) <= 128:
        scheme, _, value = header.strip().partition(" ")
        if scheme == "Bearer" and value:
            credentials_token = value
    if credentials_token is not None:
        row = (
            await database.execute(
                select(AppleHealthToken, User)
                .join(User, User.id == AppleHealthToken.user_id)
                .where(AppleHealthToken.token_hash == hash_token(credentials_token))
            )
        ).one_or_none()
        if row is not None:
            token, account = row
            return ImportPrincipal(account=account, token_hash=token.token_hash)
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required")


def weight_entity_id(account_id: UUID, sample: WeightSampleInput) -> UUID:
    measured_utc = sample.measured_at.astimezone(timezone.utc).isoformat()
    return uuid5(account_id, f"weight|{measured_utc}|{sample.source}|{json.dumps(sample.value)}")


def steps_entity_id(account_id: UUID, day) -> UUID:
    return uuid5(account_id, f"steps|{day.isoformat()}")


def steps_value_digest(value: int) -> str:
    return sha256(str(value).encode()).hexdigest()


def payload_without_received_at(payload: dict) -> dict:
    comparable = {key: value for key, value in payload.items() if key != "importedAt"}
    return comparable


def weight_payload(sample: WeightSampleInput, imported_at: datetime) -> dict:
    return {
        "kind": WEIGHT_SAMPLE_KIND,
        "day": sample.measured_at.astimezone(WARSAW_ZONE).date().isoformat(),
        "measuredAt": sample.measured_at.astimezone(timezone.utc).isoformat(),
        "value": sample.value,
        "source": sample.source,
        "method": WEIGHT_METHOD_HEALTH_SAMPLE,
        "importedAt": imported_at.isoformat(),
    }


def steps_payload(sample: StepsSampleInput, imported_at: datetime) -> dict:
    return {
        "kind": STEPS_SAMPLE_KIND,
        "day": sample.day.isoformat(),
        "measuredAt": None,
        "value": sample.value,
        "source": STEPS_SOURCE,
        "method": STEPS_METHOD_MANUAL_VERIFIED_TOTAL,
        "importedAt": imported_at.isoformat(),
    }


async def reserve_import_attempt(database: AsyncSession, user_id: UUID) -> None:
    """Durable per-token window accounting under the account lock."""
    now = await database_now(database)
    stored = await database.scalar(select(AppleHealthImportLimit).where(AppleHealthImportLimit.user_id == user_id).with_for_update().execution_options(populate_existing=True))
    if stored is None:
        database.add(AppleHealthImportLimit(user_id=user_id, window_started_at=now, import_count=1, attempted_at=[now]))
        return
    attempts = [instant for instant in stored.attempted_at if instant > now - timedelta(seconds=IMPORT_WINDOW_SECONDS)]
    if len(attempts) >= IMPORT_MAX_PER_WINDOW:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many imports",
            headers={"Retry-After": str(IMPORT_WINDOW_SECONDS)},
        )
    stored.attempted_at = [*attempts, now]
    stored.import_count = len(stored.attempted_at)
    stored.window_started_at = stored.attempted_at[0]


async def process_import(database: AsyncSession, principal: ImportPrincipal, payload: ImportRequest) -> dict:
    user_id = principal.account.id
    # Serialize imports, token rotation and revoke through the account row lock.
    # NO KEY UPDATE serializes health writers while allowing sync's FK KEY
    # SHARE checks; FOR UPDATE here would invert the record/user lock order.
    owner = await database.scalar(select(User.id).where(User.id == user_id).with_for_update(key_share=True))
    if owner is None:
        raise HTTPException(401, "Authentication required")
    # Re-check the token after locking: a concurrent revoke may have won.
    token = await database.scalar(select(AppleHealthToken).where(AppleHealthToken.user_id == user_id).execution_options(populate_existing=True))
    if token is None or token.token_hash != principal.token_hash:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required")

    imported_at = datetime.now(timezone.utc)
    imported = 0
    duplicates = 0
    tombstoned = 0
    pending: list[PlannedChange] = []

    candidates: list[tuple[UUID, dict]] = []
    candidates.extend(
        (weight_entity_id(user_id, sample), weight_payload(sample, imported_at)) for sample in payload.weights
    )
    candidates.extend(
        (steps_entity_id(user_id, sample.day), steps_payload(sample, imported_at)) for sample in payload.steps
    )

    await acquire_advisory_locks(database, [f"record:{user_id}:{HEALTH_SAMPLE_ENTITY_TYPE}:{entity_id}" for entity_id, _ in candidates])
    for entity_id, planned_payload in candidates:
        record = await database.scalar(
            select(SyncRecord)
            .where(
                SyncRecord.user_id == user_id,
                SyncRecord.entity_type == HEALTH_SAMPLE_ENTITY_TYPE,
                SyncRecord.entity_id == entity_id,
            )
            .with_for_update()
        )
        if record is not None and record.deleted_at is not None:
            tombstoned += 1
            continue
        if record is not None and payload_without_received_at(record.payload) == payload_without_received_at(
            planned_payload
        ):
            duplicates += 1
            continue
        if planned_payload["kind"] == STEPS_SAMPLE_KIND:
            # Accept the newer manual total only when its digest was never accepted.
            value_digest = steps_value_digest(planned_payload["value"])
            known_digest = await database.scalar(
                select(AppleHealthStepDigest).where(
                    AppleHealthStepDigest.user_id == user_id,
                    AppleHealthStepDigest.day == date.fromisoformat(planned_payload["day"]),
                    AppleHealthStepDigest.value_digest == value_digest,
                )
            )
            if known_digest is not None:
                duplicates += 1
                continue
            database.add(
                AppleHealthStepDigest(
                    user_id=user_id,
                    day=date.fromisoformat(planned_payload["day"]),
                    value_digest=value_digest,
                )
            )

        version = 1 if record is None else record.version + 1
        if record is None:
            persisted = SyncRecord(
                user_id=user_id,
                entity_type=HEALTH_SAMPLE_ENTITY_TYPE,
                entity_id=entity_id,
                version=version,
                payload=planned_payload,
                deleted_at=None,
                updated_at=imported_at,
            )
            database.add(persisted)
        else:
            record.version = version
            record.payload = planned_payload
            record.deleted_at = None
            record.updated_at = imported_at
        pending.append(
            PlannedChange(
                entity_id=entity_id,
                version=version,
                payload=planned_payload,
                updated_at=imported_at,
            )
        )
        await database.flush()
        imported += 1

    if pending:
        # Enter the global publisher lock strictly after record locks, matching
        # the sync push writer ordering.
        await acquire_advisory_locks(database, [publisher_lock_key])
        for change in pending:
            database.add(
                SyncChange(
                    user_id=user_id,
                    entity_type=HEALTH_SAMPLE_ENTITY_TYPE,
                    entity_id=change.entity_id,
                    version=change.version,
                    payload=change.payload,
                    deleted_at=None,
                    updated_at=change.updated_at,
                )
            )
        await database.flush()

    token.last_import_at = imported_at
    await database.commit()
    return {
        "imported": imported,
        "duplicates": duplicates,
        "ignoredDeleted": tombstoned,
        "lastImportAt": imported_at,
    }
