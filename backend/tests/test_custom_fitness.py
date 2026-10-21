"""Contract tests using the authoritative cross-client fixture."""
from copy import deepcopy
from datetime import datetime, timezone
import json
from pathlib import Path
from uuid import uuid4

import pytest
from sqlalchemy import select

from app.sync import service
from app.sync.models import SyncRecord, SyncOperation, SyncChange
from app.sync.schemas import PushOperation
from app.sync.fitness_protocols import FitnessValidationError, validate_fitness_payload
from tests.test_sync import account, authenticate


FIXTURE = json.loads((Path(__file__).resolve().parents[2] / "tests/fixtures/fitness_protocol_v1.json").read_text())


def op(payload, kind="fitnessTest", base=0, entity=None, deleted=False):
    return PushOperation.model_validate(dict(operationId=uuid4(), entityType=kind,
        entityId=entity or uuid4(), baseVersion=base, payload=deepcopy(payload), deleted=deleted))


def collection(entry=None):
    return {"version": 1, "entries": [deepcopy(entry or FIXTURE["protocol"])]}


@pytest.mark.asyncio
@pytest.mark.parametrize("field,value", [
    ("metric", "unknown"), ("direction", "up"), ("name", ""), ("name", "😀" * 81),
    ("exerciseId", ""), ("exerciseName", "x" * 201), ("familyId", "bad"),
    ("supersedesId", FIXTURE["protocol"]["id"]), ("loadKg", True), ("loadKg", -1),
    ("loadKg", 1001), ("loadBasis", "total"), ("side", "center"),
    ("timeLimitSeconds", True), ("timeLimitSeconds", 60.0), ("timeLimitSeconds", 0), ("timeLimitSeconds", 86401),
    ("instructions", "x" * 4001), ("createdAtUtc", "2026-01-01"),
    ("updatedAtUtc", "2020-01-01T00:00:00Z"), ("unknown", 1),
])
async def test_invalid_protocol_rejected(session, account, field, value):
    entry = deepcopy(FIXTURE["protocol"])
    entry[field] = value
    with pytest.raises(ValueError, match="fitness"):
        await service.push_operations(session, account.id, [op({"fitnessProtocols": collection(entry)}, "profile")])


@pytest.mark.asyncio
@pytest.mark.parametrize("field,value", [("wynik", True), ("wynik", -1), ("wynik", 1.5),
    ("wynik", 1000000001), ("score", 2), ("score", False), ("data", "2026-01-01"),
    ("typ", "legacy"), ("customProtocol", None)])
async def test_invalid_custom_result_rejected(session, account, field, value):
    payload = deepcopy(FIXTURE["result"])
    payload[field] = value
    with pytest.raises(ValueError, match="fitness"):
        await service.push_operations(session, account.id, [op(payload)])


@pytest.mark.asyncio
@pytest.mark.parametrize("kind", ["profile", "fitnessTest"])
async def test_omission_preserves_without_mutating_attempt_or_digest(session, account, kind):
    payload = {"fitnessProtocols": collection()} if kind == "profile" else FIXTURE["result"]
    first = op(payload, kind)
    await service.push_operations(session, account.id, [first])
    edit_payload = {"name": "edit"} if kind == "profile" else {k: v for k, v in payload.items() if k != "customProtocol"}
    if kind == "fitnessTest":
        edit_payload["wynik"] = 20
    edit = op(edit_payload, kind, 1, first.entity_id)
    attempted, digest = deepcopy(edit.payload), service.request_digest(edit)
    assert not (await service.push_operations(session, account.id, [edit])).conflicts
    row = await session.scalar(select(SyncRecord).where(SyncRecord.entity_id == first.entity_id))
    key = "fitnessProtocols" if kind == "profile" else "customProtocol"
    assert row.payload[key] == payload[key]
    assert edit.payload == attempted and service.request_digest(edit) == digest
    assert (await service.push_operations(session, account.id, [edit])).accepted[0].duplicate
    stored = await session.scalar(select(SyncOperation).where(SyncOperation.operation_id == edit.operation_id))
    assert stored.request_digest == digest


@pytest.mark.asyncio
@pytest.mark.parametrize("replacement", [None, {"version": 1, "entries": []}, "changed"])
async def test_profile_cannot_prune_or_change_revision(session, account, replacement):
    first = op({"fitnessProtocols": collection()}, "profile")
    await service.push_operations(session, account.id, [first])
    if replacement == "changed":
        replacement = collection()
        replacement["entries"][0]["name"] = "Other rules"
    with pytest.raises(ValueError, match="fitness"):
        await service.push_operations(session, account.id, [op({"fitnessProtocols": replacement}, "profile", 1, first.entity_id)])


@pytest.mark.asyncio
@pytest.mark.parametrize("change", ["legacy", "null", "snapshot"])
async def test_custom_result_frozen_on_live_update(session, account, change):
    first = op(FIXTURE["result"])
    await service.push_operations(session, account.id, [first])
    payload = deepcopy(FIXTURE["result"])
    if change == "legacy":
        payload = {"typ": "skokWdal", "wynik": 42, "score": 3, "data": "old"}
    elif change == "null":
        payload["customProtocol"] = None
    else:
        payload["customProtocol"]["snapshot"]["name"] = "Changed"
    with pytest.raises(ValueError, match="fitness"):
        await service.push_operations(session, account.id, [op(payload, base=1, entity=first.entity_id)])


@pytest.mark.asyncio
async def test_http_422_and_batch_atomicity(client, session, account):
    headers = await authenticate(client, account)
    good = op({"anything": 1}, "mood")
    bad = op({**FIXTURE["result"], "wynik": -1})
    response = await client.post("/api/sync/push", headers=headers,
        json={"operations": [x.model_dump(mode="json", by_alias=True) for x in [good, bad]]})
    assert response.status_code == 422
    assert "fitness" in response.text
    assert await session.scalar(select(SyncRecord).where(SyncRecord.entity_id == good.entity_id)) is None


@pytest.mark.asyncio
@pytest.mark.parametrize("kind,key", [("profile", "fitnessProtocols"), ("fitnessTest", "customProtocol")])
async def test_unreadable_history_can_be_deleted(session, account, kind, key):
    entity = uuid4()
    session.add(SyncRecord(user_id=account.id, entity_type=kind, entity_id=entity, version=1,
        payload={key: {"version": 999}}, updated_at=datetime.now(timezone.utc)))
    await session.commit()
    result = await service.push_operations(session, account.id, [op({key: {"broken": True}}, kind, 1, entity, True)])
    assert not result.conflicts


def validate(payload, kind="fitnessTest", previous=None):
    validate_fitness_payload(kind, payload, previous or {}, live=previous is not None, deleted=False)


@pytest.mark.parametrize("path,value", [
    ("version", 2), ("version", True), ("version", 1.0), ("protocolId", str(uuid4())),
    ("familyId", str(uuid4())), ("extra", 0), ("snapshot", {}),
])
def test_wrapper_is_strict(path, value):
    payload = deepcopy(FIXTURE["result"])
    payload["customProtocol"][path] = value
    with pytest.raises(FitnessValidationError):
        validate(payload)


@pytest.mark.parametrize("metric,value", [("reps", 0), ("reps", 10**9),
    ("time", 0.25), ("distance", 10**9), ("time", 10**9)])
def test_metrics_and_historical_date_without_catalog_or_profile(metric, value):
    payload = deepcopy(FIXTURE["result"])
    payload["customProtocol"]["snapshot"]["metric"] = metric
    payload["wynik"] = value
    payload["data"] = "1901-01-01T12:00:00Z"
    validate(payload)


@pytest.mark.parametrize("payload", [{}, {"typ": "skokWdal", "wynik": -4},
    {"typ": "sitAndReach", "wynik": 2.5, "score": 45, "data": "legacy"},
    {"typ": "unknownFutureLegacy", "extra": {"opaque": True}}])
def test_legacy_acceptance_unchanged(payload):
    validate(payload)


@pytest.mark.parametrize("change", ["duplicate", "501", "bytes", "unknown", "version", "boolVersion", "floatVersion"])
def test_collection_strict_limits(change):
    value = collection()
    if change == "duplicate":
        value["entries"] *= 2
    elif change == "501":
        value["entries"] *= 501
    elif change == "bytes":
        value["entries"] = [{**FIXTURE["protocol"], "id": str(uuid4()), "instructions": "😀" * 4000} for _ in range(17)]
    elif change == "unknown":
        value["future"] = 1
    else:
        value["version"] = True if change == "boolVersion" else 1.0 if change == "floatVersion" else 2
    with pytest.raises(FitnessValidationError):
        validate({"fitnessProtocols": value}, "profile")


def variant_snapshot():
    return dict(id=str(uuid4()), name="Wariant", exerciseId="cw001",
        createdAtUtc="2026-10-21T10:00:00Z", updatedAtUtc="2026-10-21T10:00:00Z")


@pytest.mark.parametrize("field,value", [("name", ""), ("id", "bad"),
    ("exerciseId", "cwOther"), ("tempo", "x" * 1001), ("rangeOfMotion", False),
    ("cue", 3), ("pauseSeconds", 1.5), ("pauseSeconds", True),
    ("pauseSeconds", 3601), ("loadKg", 0), ("loadKg", 1001), ("unknown", "future"),
    ("deletedAtUtc", "2027-01-01T00:00:00Z")])
def test_variant_snapshot_uses_existing_limits_and_known_fields(field, value):
    entry = deepcopy(FIXTURE["protocol"])
    entry["variantSnapshot"] = {**variant_snapshot(), field: value}
    with pytest.raises(FitnessValidationError):
        validate({"fitnessProtocols": collection(entry)}, "profile")


def test_boundary_unicode_load_side_and_optional_variant_attributes():
    entry = deepcopy(FIXTURE["protocol"])
    entry.update(name="😀" * 80, loadKg=0, loadBasis="perImplement", side="both",
        instructions="", supersedesId=str(uuid4()), familyId=str(uuid4()))
    entry["variantSnapshot"] = {**variant_snapshot(), "loadKg": 1000, "pauseSeconds": 3600,
        "tempo": "", "rangeOfMotion": None, "cue": "😀" * 1000, "deletedAtUtc": None}
    validate({"fitnessProtocols": collection(entry)}, "profile")


def test_profile_metadata_only_archive_and_independent_branch_ids():
    previous = {"fitnessProtocols": collection()}
    payload = deepcopy(previous)
    payload["fitnessProtocols"]["entries"][0].update(updatedAtUtc="2026-10-22T00:00:00Z", deletedAtUtc="2026-10-22T00:00:00Z")
    branch = {**FIXTURE["protocol"], "id": str(uuid4()), "supersedesId": str(uuid4()), "name": "Another branch"}
    payload["fitnessProtocols"]["entries"].append(branch)
    validate(payload, "profile", previous)


@pytest.mark.parametrize("kind", ["profile", "fitnessTest"])
def test_unpaired_unicode_rejected_as_custom_validation_error(kind):
    payload = {"fitnessProtocols": collection()} if kind == "profile" else deepcopy(FIXTURE["result"])
    snapshot = payload["fitnessProtocols"]["entries"][0] if kind == "profile" else payload["customProtocol"]["snapshot"]
    snapshot["name"] = "\ud800"
    with pytest.raises(FitnessValidationError):
        validate(payload, kind)


def test_live_snapshot_cannot_change_numeric_canonical_representation():
    previous = deepcopy(FIXTURE["result"])
    previous["customProtocol"]["snapshot"].update(loadKg=10, loadBasis="total")
    payload = deepcopy(previous)
    payload["customProtocol"]["snapshot"]["loadKg"] = 10.0
    with pytest.raises(FitnessValidationError):
        validate(payload, previous=previous)


@pytest.mark.asyncio
async def test_stale_cas_does_not_validate_unaccepted_extension(session, account):
    first = op(FIXTURE["result"])
    await service.push_operations(session, account.id, [first])
    malformed = op({"typ": "customFitnessTestV1"}, entity=first.entity_id)
    assert (await service.push_operations(session, account.id, [malformed])).conflicts


@pytest.mark.asyncio
async def test_chained_batch_revision_and_correction_changes_are_independent_snapshots(session, account):
    first = op(FIXTURE["result"])
    corrected = deepcopy(FIXTURE["result"])
    corrected.pop("customProtocol")
    corrected.update(data="1901-01-01T00:00:00Z", wynik=19)
    second = op(corrected, base=1, entity=first.entity_id)
    response = await service.push_operations(session, account.id, [first, second])
    assert len(response.accepted) == 2
    changes = (await session.scalars(select(SyncChange).where(SyncChange.entity_id == first.entity_id).order_by(SyncChange.version))).all()
    assert changes[0].payload == FIXTURE["result"]
    assert changes[1].payload["wynik"] == 19
    assert changes[1].payload["customProtocol"] == FIXTURE["result"]["customProtocol"]


NULLABLE_PROTOCOL_FIELDS = ("supersedesId", "loadKg", "loadBasis", "side", "variantSnapshot", "timeLimitSeconds")


@pytest.mark.parametrize("kind", ["profile", "fitnessTest"])
@pytest.mark.parametrize("reverse", [False, True])
def test_nullable_protocol_omission_equals_explicit_null_without_mutation(kind, reverse):
    entry = deepcopy(FIXTURE["protocol"])
    entry["timeLimitSeconds"] = None
    omitted = {k: v for k, v in entry.items() if k not in NULLABLE_PROTOCOL_FIELDS}
    before, after = (entry, omitted) if not reverse else (omitted, entry)
    if kind == "profile":
        previous, payload = {"fitnessProtocols": collection(before)}, {"fitnessProtocols": collection(after)}
    else:
        previous = deepcopy(FIXTURE["result"])
        previous["customProtocol"]["snapshot"] = before
        payload = deepcopy(previous)
        payload["customProtocol"]["snapshot"] = after
    untouched = deepcopy(payload)
    validate(payload, kind, previous)
    assert payload == untouched


@pytest.mark.parametrize("date", ["2026-02-30T00:00:00Z", "2026-01-01T00:00:60Z",
    "2026-01-01", "2026-01-01T00:00:00", "0000-01-01T00:00:00Z",
    "10000-01-01T00:00:00Z", "2026-01-01T00:00:00.1234567Z"])
def test_custom_timestamp_strict_gregorian_fraction_precision(date):
    payload = deepcopy(FIXTURE["result"])
    payload["data"] = date
    with pytest.raises(FitnessValidationError):
        validate(payload)


@pytest.mark.parametrize("metric,value", [(True, 1), ("reps", 1.5), ("time", True), ("distance", False)])
def test_metric_and_integer_types_are_not_coerced(metric, value):
    payload = deepcopy(FIXTURE["result"])
    payload["customProtocol"]["snapshot"]["metric"] = metric
    payload["wynik"] = value
    with pytest.raises(FitnessValidationError):
        validate(payload)


@pytest.mark.asyncio
@pytest.mark.parametrize("kind", ["profile", "fitnessTest"])
async def test_normalized_null_semantics_preserve_raw_attempt_digest(session, account, kind):
    payload = {"fitnessProtocols": collection()} if kind == "profile" else deepcopy(FIXTURE["result"])
    first = op(payload, kind)
    await service.push_operations(session, account.id, [first])
    entry = payload["fitnessProtocols"]["entries"][0] if kind == "profile" else payload["customProtocol"]["snapshot"]
    for key in NULLABLE_PROTOCOL_FIELDS:
        if entry.get(key) is None:
            entry.pop(key, None)
    edit = op(payload, kind, 1, first.entity_id)
    attempted, digest = deepcopy(edit.payload), service.request_digest(edit)
    assert not (await service.push_operations(session, account.id, [edit])).conflicts
    assert edit.payload == attempted and service.request_digest(edit) == digest
    row = await session.scalar(select(SyncRecord).where(SyncRecord.entity_id == first.entity_id))
    assert row.payload == attempted
    assert (await service.push_operations(session, account.id, [edit])).accepted[0].duplicate


@pytest.mark.parametrize("fraction", ["", ".1", ".123456"])
def test_allowed_timestamp_precisions(fraction):
    payload = deepcopy(FIXTURE["result"])
    payload["data"] = f"2024-02-29T23:59:59{fraction}Z"
    validate(payload)


@pytest.mark.parametrize("value", [0.0, 18.0, 1000000000.0])
def test_reps_integral_double_matches_sqlite_real_roundtrip(value):
    payload = deepcopy(FIXTURE["result"])
    payload["wynik"] = value
    validate(payload)
    assert type(payload["wynik"]) is float


@pytest.mark.asyncio
async def test_reps_integral_double_sync_roundtrip_preserves_attempt_and_digest(session, account):
    first = op(FIXTURE["result"])
    await service.push_operations(session, account.id, [first])
    payload = deepcopy(FIXTURE["result"])
    payload["wynik"] = 18.0
    edit = op(payload, base=1, entity=first.entity_id)
    attempted, digest = deepcopy(edit.payload), service.request_digest(edit)
    assert not (await service.push_operations(session, account.id, [edit])).conflicts
    row = await session.scalar(select(SyncRecord).where(SyncRecord.entity_id == first.entity_id))
    assert row.payload["wynik"] == 18
    assert type(edit.payload["wynik"]) is float
    assert edit.payload == attempted and service.request_digest(edit) == digest
    assert (await service.push_operations(session, account.id, [edit])).accepted[0].duplicate
