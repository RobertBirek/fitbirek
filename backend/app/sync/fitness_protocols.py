"""Strict v1 custom fitness extensions; no catalog or cross-record dependencies."""
from datetime import datetime
import json
from math import isfinite
import re


class FitnessValidationError(ValueError):
    pass


def require(condition: bool, field: str) -> None:
    if not condition:
        raise FitnessValidationError(f"Invalid fitness extension: {field}")


def fields(value, required: set[str], optional: set[str], label: str) -> None:
    require(isinstance(value, dict), label)
    require(required <= value.keys() and value.keys() <= required | optional, label + " fields")


def text(value, maximum: int, label: str, nonempty: bool = True) -> None:
    require(isinstance(value, str) and len(value) <= maximum
            and (not nonempty or bool(value.strip())), label)


def uuid(value, label: str) -> None:
    require(isinstance(value, str) and re.fullmatch(
        r"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}", value) is not None, label)


def number(value, low, high, label: str, integer: bool = False) -> None:
    require(type(value) is int if integer else type(value) in (int, float), label)
    require(low <= value <= high and (not isinstance(value, float) or isfinite(value)), label)


def timestamp(value, label: str) -> datetime:
    require(isinstance(value, str) and re.fullmatch(
        r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,6})?Z", value) is not None, label)
    try:
        return datetime.fromisoformat(value)
    except ValueError as exc:
        raise FitnessValidationError(f"Invalid fitness extension: {label}") from exc


def timestamps(entry) -> None:
    created = timestamp(entry["createdAtUtc"], "createdAtUtc")
    updated = timestamp(entry["updatedAtUtc"], "updatedAtUtc")
    require(updated >= created, "updatedAtUtc before creation")
    if entry.get("deletedAtUtc") is not None:
        require(timestamp(entry["deletedAtUtc"], "deletedAtUtc") <= updated, "deletedAtUtc after update")


def byte_limit(value, maximum: int, label: str) -> None:
    try:
        size = len(canonical(value).encode("utf-8"))
    except (UnicodeError, ValueError) as exc:
        raise FitnessValidationError(f"Invalid fitness extension: {label}") from exc
    require(size <= maximum, label)


def canonical(value) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)


def variant(entry, exercise_id: str) -> None:
    fields(entry, {"id", "name", "exerciseId", "createdAtUtc", "updatedAtUtc"},
           {"deletedAtUtc", "tempo", "pauseSeconds", "loadKg", "rangeOfMotion", "cue"}, "variantSnapshot")
    uuid(entry["id"], "variant id")
    text(entry["name"], 80, "variant name")
    require(entry["exerciseId"] == exercise_id, "variant exerciseId")
    timestamps(entry)
    for key in ("tempo", "rangeOfMotion", "cue"):
        if entry.get(key) is not None:
            text(entry[key], 1000, key, nonempty=False)
    if entry.get("loadKg") is not None:
        number(entry["loadKg"], 0, 1000, "variant loadKg")
        require(entry["loadKg"] > 0, "variant loadKg")
    if entry.get("pauseSeconds") is not None:
        number(entry["pauseSeconds"], 0, 3600, "pauseSeconds", integer=True)


PROTOCOL_FIELDS = {"id", "familyId", "supersedesId", "name", "exerciseId", "exerciseName",
                   "metric", "direction", "loadKg", "loadBasis", "side", "variantSnapshot",
                   "timeLimitSeconds", "instructions", "createdAtUtc", "updatedAtUtc"}
NULLABLE_PROTOCOL_FIELDS = {"supersedesId", "loadKg", "loadBasis", "side", "variantSnapshot", "timeLimitSeconds"}


def protocol(entry) -> None:
    fields(entry, PROTOCOL_FIELDS - NULLABLE_PROTOCOL_FIELDS,
           NULLABLE_PROTOCOL_FIELDS | {"deletedAtUtc"}, "protocol")
    byte_limit(entry, 32768, "protocol snapshot bytes")
    # Local validation/comparison copy only. Preserve raw wire/request digests.
    entry = normalized_protocol(entry)
    uuid(entry["id"], "protocol id")
    uuid(entry["familyId"], "familyId")
    if entry["supersedesId"] is not None:
        uuid(entry["supersedesId"], "supersedesId")
        require(entry["supersedesId"].lower() != entry["id"].lower(), "self supersedesId")
    for key, maximum in (("name", 80), ("exerciseId", 64), ("exerciseName", 200)):
        text(entry[key], maximum, key)
    text(entry["instructions"], 4000, "instructions", nonempty=False)
    require(entry["metric"] in ("reps", "time", "distance"), "metric")
    require(entry["direction"] in ("higher", "lower"), "direction")
    require(entry["side"] in (None, "left", "right", "both"), "side")
    if entry["loadKg"] is None:
        require(entry["loadBasis"] is None, "loadBasis without loadKg")
    else:
        number(entry["loadKg"], 0, 1000, "loadKg")
        require(entry["loadBasis"] in ("total", "perImplement"), "loadBasis")
    if entry["timeLimitSeconds"] is not None:
        number(entry["timeLimitSeconds"], 1, 86400, "timeLimitSeconds", integer=True)
    timestamps(entry)
    if entry["variantSnapshot"] is not None:
        variant(entry["variantSnapshot"], entry["exerciseId"])


def collection(value) -> dict:
    fields(value, {"version", "entries"}, set(), "fitnessProtocols")
    require(type(value["version"]) is int and value["version"] == 1, "fitnessProtocols version")
    require(isinstance(value["entries"], list) and len(value["entries"]) <= 500, "fitnessProtocols entries")
    byte_limit(value, 262144, "fitnessProtocols bytes")
    entries = {}
    for entry in value["entries"]:
        protocol(entry)
        key = entry["id"].lower()
        require(key not in entries, "duplicate fitnessProtocols id")
        entries[key] = entry
    return entries


def semantic(entry) -> dict:
    return {k: v for k, v in normalized_protocol(entry).items() if k not in ("updatedAtUtc", "deletedAtUtc")}


def normalized_protocol(entry) -> dict:
    return {**dict.fromkeys(NULLABLE_PROTOCOL_FIELDS), **entry}


def frozen_wrapper(value):
    if isinstance(value, dict) and isinstance(value.get("snapshot"), dict):
        return {**value, "snapshot": normalized_protocol(value["snapshot"])}
    return value


def validate_fitness_payload(entity_type: str, payload: dict, previous: dict, *, live: bool, deleted: bool) -> None:
    # Deletion is the recovery path for unreadable historical extensions. The
    # generic request schema still checks the finite JSON envelope.
    if deleted:
        return
    if entity_type == "profile":
        current = payload.get("fitnessProtocols")
        old = previous.get("fitnessProtocols") if live else None
        incoming = collection(current) if current is not None else {}
        if old is not None:
            existing = collection(old)
            require(existing.keys() <= incoming.keys(), "fitnessProtocols cannot prune revisions")
            for key, entry in existing.items():
                require(canonical(semantic(entry)) == canonical(semantic(incoming[key])), "fitnessProtocols immutable revision")
    elif entity_type == "fitnessTest":
        old_custom = live and (previous.get("typ") == "customFitnessTestV1" or "customProtocol" in previous)
        custom = payload.get("typ") == "customFitnessTestV1" or "customProtocol" in payload
        if old_custom:
            require(custom and canonical(frozen_wrapper(payload.get("customProtocol")))
                    == canonical(frozen_wrapper(previous.get("customProtocol"))), "fitness snapshot immutable")
        if not custom:
            return  # Deliberately preserve all legacy/generic acceptance semantics.
        fields(payload, {"typ", "data", "wynik", "score", "customProtocol"}, set(), "fitness result")
        require(payload["typ"] == "customFitnessTestV1", "fitness typ")
        number(payload["score"], 0, 0, "fitness score")
        timestamp(payload["data"], "fitness data")
        wrapper = payload["customProtocol"]
        fields(wrapper, {"version", "protocolId", "familyId", "snapshot"}, set(), "customProtocol")
        require(type(wrapper["version"]) is int and wrapper["version"] == 1, "customProtocol version")
        uuid(wrapper["protocolId"], "protocolId")
        uuid(wrapper["familyId"], "familyId")
        snapshot = wrapper["snapshot"]
        protocol(snapshot)
        require(wrapper["protocolId"] == snapshot["id"] and wrapper["familyId"] == snapshot["familyId"], "fitness snapshot identity")
        number(payload["wynik"], 0, 10**9, "fitness wynik")
        if snapshot["metric"] == "reps":
            require(payload["wynik"] % 1 == 0, "fitness reps must be integral")
