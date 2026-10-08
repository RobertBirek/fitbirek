"""Bounded, consented Mentor context built only in memory."""
import base64
import hashlib
import json
import math
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from cryptography.fernet import Fernet, InvalidToken
from fastapi import HTTPException
from sqlalchemy import select

from app.config import settings
from app.sync.models import SyncRecord

# Checked-in identifiers and public Polish names from assets/data/exercises.json.
CATALOGUE = {
    "cw001": "Pompki klasyczne",
    "cw007": "Pompki hindu",
    "cw012": "Wyciskanie hantli leżąc płasko",
    "cw031": "Podciąganie nachwytem szerokie",
    "cw032": "Podciąganie podchwytem",
    "cw061": "Reverse snow angel",
    "cw091": "Empty can raise",
    "cw121": "Towel pull-up",
    "cw125": "Przysiad goblet",
    "cw151": "Deadlift sumo hantlem",
    "cw154": "Glute bridge",
    "cw169": "Plank klasyczny na przedramionach",
}


def _timestamp(value: Any) -> str | None:
    if not isinstance(value, str) or len(value) > 40:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return None
    return parsed.astimezone(timezone.utc).isoformat()


def _number(value: Any, minimum: float, maximum: float) -> int | float | None:
    if not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isfinite(value) or not minimum <= value <= maximum:
        return None
    return value


def _selector_cipher() -> Fernet:
    try:
        with open(settings.mentor_master_key_file, "rb") as source:
            material = source.read(100).strip()
        # A purpose-derived key prevents an opaque selector from being accepted
        # as an encrypted provider credential (or vice versa).
        key = base64.urlsafe_b64encode(hashlib.sha256(b"mentor-context-v1\0" + material).digest())
        return Fernet(key)
    except (OSError, ValueError):
        raise HTTPException(503, "Mentor unavailable") from None


def _selector(user_id, record_id, category: str, revision: int, source: str | None = None) -> str:
    payload = {"u": str(user_id), "r": str(record_id), "c": category, "v": revision, "s": source}
    return _selector_cipher().encrypt(json.dumps(payload, sort_keys=True, separators=(",", ":")).encode()).decode().rstrip("=")


def _selected_record_id(user_id, selection_id: str, category: str, revision: int, source: str | None = None) -> UUID:
    try:
        if not isinstance(selection_id, str) or len(selection_id) > 512:
            raise ValueError()
        padded = selection_id + "=" * (-len(selection_id) % 4)
        payload = json.loads(_selector_cipher().decrypt(padded.encode(), ttl=None))
        if payload != {"u": str(user_id), "r": payload.get("r"), "c": category, "v": revision, "s": source}:
            raise ValueError()
        return UUID(payload["r"])
    except (InvalidToken, UnicodeError, ValueError, TypeError, KeyError, json.JSONDecodeError):
        raise HTTPException(409, "Context selection unavailable") from None


def _profile(payload: Any) -> dict | None:
    if not isinstance(payload, dict):
        return None
    age = _number(payload.get("wiek"), 13, 120)
    goal = payload.get("cel")
    height = _number(payload.get("wzrostCm"), 100, 250)
    if not isinstance(age, int) or not isinstance(goal, str) or goal not in {"redukcja", "sila", "masa", "kondycja", "mix"}:
        return None
    result = {"age": age, "goal": goal}
    if height is not None:
        result["height_cm"] = height
    return result


def _manual_weight(payload: Any) -> tuple[str, int | float] | None:
    if not isinstance(payload, dict):
        return None
    measured_at = _timestamp(payload.get("data"))
    value = _number(payload.get("wagaKg"), 1, 500)
    return (measured_at, value) if measured_at is not None and value is not None else None


def _apple_weight(payload: Any) -> tuple[str, int | float] | None:
    if not isinstance(payload, dict) or payload.get("kind") != "weight":
        return None
    measured_at = _timestamp(payload.get("measuredAt"))
    value = _number(payload.get("value"), 1, 500)
    return (measured_at, value) if measured_at is not None and value is not None else None


def _workout_note(payload: Any) -> tuple[str, str] | None:
    if not isinstance(payload, dict):
        return None
    started_at = _timestamp(payload.get("dataStart"))
    note = payload.get("notatka")
    if started_at is None or not isinstance(note, str):
        return None
    note = note.strip()
    if not note:
        return None
    return started_at, note[:500]


async def context_options(db, user_id, revision: int) -> dict:
    """Return UI previews only; this never calls a provider or stores state."""
    profile_row = await db.scalar(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "profile",
    ).order_by(SyncRecord.updated_at.desc()).limit(1))
    profile = _profile(profile_row.payload) if profile_row is not None else None

    measurement_rows = list((await db.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "measurement",
    ).order_by(SyncRecord.updated_at.desc()).limit(20))).all())
    health_rows = list((await db.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "healthSample",
    ).order_by(SyncRecord.updated_at.desc()).limit(100))).all())
    note_rows = list((await db.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "workoutSession",
    ).order_by(SyncRecord.updated_at.desc()).limit(20))).all())

    weights = []
    for row in measurement_rows:
        value = _manual_weight(row.payload)
        if value is not None:
            measured_at, weight = value
            weights.append({"selection_id": _selector(user_id, row.entity_id, "weight", revision, "measurement"),
                            "source": "measurement", "summary": f"{weight:g} kg · {measured_at[:10]}"})
    for row in health_rows:
        value = _apple_weight(row.payload)
        if value is not None:
            measured_at, weight = value
            weights.append({"selection_id": _selector(user_id, row.entity_id, "weight", revision, "apple_health"),
                            "source": "apple_health", "summary": f"{weight:g} kg · {measured_at[:10]}"})
    weights.sort(key=lambda item: item["summary"], reverse=True)

    notes = []
    for row in note_rows:
        value = _workout_note(row.payload)
        if value is not None:
            started_at, note = value
            notes.append({"selection_id": _selector(user_id, row.entity_id, "note", revision),
                          "summary": started_at[:10], "preview": note})

    return {"settings_revision": revision, "options": {
        "training": {"available": any(_timestamp(row.payload.get("dataStart")) is not None for row in note_rows if isinstance(row.payload, dict)), "summary": "Ostatnie 12 tygodni"},
        "profile": {"available": profile is not None},
        "weight": weights[:20],
        "workout_notes": notes[:20],
        "apple_health": {"available": any(_apple_weight(row.payload) is not None or isinstance(row.payload, dict) and row.payload.get("kind") == "steps" for row in health_rows)},
    }}


async def _selected_row(db, user_id, selection_id, category, revision, source, entity_type):
    entity_id = _selected_record_id(user_id, selection_id, category, revision, source)
    row = await db.scalar(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.entity_id == entity_id,
        SyncRecord.entity_type == entity_type, SyncRecord.deleted_at.is_(None),
    ))
    if row is None:
        raise HTTPException(409, "Context selection unavailable")
    return row


async def _training_projection(db, user_id) -> dict:
    cutoff = datetime.now(timezone.utc) - timedelta(weeks=12)
    rows = list((await db.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "workoutSession",
    ).order_by(SyncRecord.updated_at.desc()).limit(200))).all())
    selected = []
    for row in rows:
        payload = row.payload if isinstance(row.payload, dict) else {}
        started_at = _timestamp(payload.get("dataStart"))
        ended_at = _timestamp(payload.get("dataKoniec"))
        if (started_at is None or ended_at is None
                or datetime.fromisoformat(started_at) < cutoff
                or datetime.fromisoformat(ended_at) < datetime.fromisoformat(started_at)):
            continue
        selected.append((row.entity_id, started_at, payload))
    selected.sort(key=lambda item: item[1], reverse=True)
    # Twelve compact sessions leave room for the user-selected categories under
    # every currently enabled profile's conservative input reservation.
    selected = selected[:12]
    ids = [str(item[0]) for item in selected]
    if not ids:
        return {"sessions": []}
    set_rows = list((await db.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "workoutSet", SyncRecord.payload["sessionSyncId"].astext.in_(ids),
    ).order_by(SyncRecord.updated_at.desc()).limit(12 * 12))).all())
    sets_by_session: dict[str, list[dict]] = {item: [] for item in ids}
    progress_by_session: dict[str, dict[str, float]] = {item: {} for item in ids}
    for row in set_rows:
        payload = row.payload if isinstance(row.payload, dict) else {}
        session_id, exercise_id = payload.get("sessionSyncId"), payload.get("cwiczenieId")
        if session_id not in sets_by_session or exercise_id not in CATALOGUE:
            continue
        set_number = _number(payload.get("numerSerii"), 1, 100)
        reps = _number(payload.get("powtorzenia"), 1, 1000)
        weight = _number(payload.get("ciezarKg"), 0, 1000)
        if not isinstance(set_number, int):
            continue
        item = {"exercise": CATALOGUE[exercise_id], "set_number": set_number}
        if isinstance(reps, int):
            item["reps"] = reps
        if weight is not None:
            item["weight_kg"] = weight
        if len(sets_by_session[session_id]) < 4:
            sets_by_session[session_id].append(item)
        if isinstance(reps, int) and weight is not None:
            score = float(weight) * reps
            previous = progress_by_session[session_id].get(exercise_id)
            if previous is None or score > previous:
                progress_by_session[session_id][exercise_id] = score
    sessions = []
    for entity_id, started_at, payload in selected:
        item = {"started_at": started_at, "sets": sets_by_session[str(entity_id)]}
        sessions.append(item)
    trend = []
    for exercise_id, exercise in CATALOGUE.items():
        values = [progress_by_session[str(entity_id)][exercise_id] for entity_id, _, _ in reversed(selected)
                  if exercise_id in progress_by_session[str(entity_id)]]
        if len(values) < 2:
            continue
        change = values[-1] - values[0]
        trend.append({"exercise": exercise,
                      "direction": "up" if change > 0 else "down" if change < 0 else "stable"})
    return {"sessions": sessions, "progress_trend": {
        "completed_sessions": len(sessions), "by_exercise": trend[:5],
    }}


async def _apple_projection(db, user_id) -> dict | None:
    cutoff = datetime.now(timezone.utc) - timedelta(days=7)
    rows = list((await db.scalars(select(SyncRecord).where(
        SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
        SyncRecord.entity_type == "healthSample",
    ).order_by(SyncRecord.updated_at.desc()).limit(100))).all())
    steps_by_day: dict[str, int] = {}
    weights = []
    for row in rows:
        payload = row.payload if isinstance(row.payload, dict) else {}
        if payload.get("kind") == "steps":
            day = _timestamp(str(payload.get("day")) + "T00:00:00+00:00")
            value = _number(payload.get("value"), 0, 100000)
            if day is not None and value is not None and datetime.fromisoformat(day) >= cutoff:
                steps_by_day[day[:10]] = int(value)
        else:
            weight = _apple_weight(payload)
            if weight is not None and datetime.fromisoformat(weight[0]) >= cutoff:
                weights.append(weight)
    result = {"steps_7_days": {"total": sum(steps_by_day.values()), "days_with_data": len(steps_by_day)}}
    if len(weights) >= 2:
        weights.sort()
        change = round(float(weights[-1][1]) - float(weights[0][1]), 1)
        result["weight_trend"] = {"direction": "up" if change > 0.1 else "down" if change < -0.1 else "stable", "change_kg": change}
    return result if steps_by_day or weights else None


async def project_context(db, user_id, selection, revision: int) -> dict:
    """Project selected, owned source records into a short-lived provider value."""
    result = {}
    if selection.training:
        result["training"] = await _training_projection(db, user_id)
    if selection.profile:
        row = await db.scalar(select(SyncRecord).where(
            SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None),
            SyncRecord.entity_type == "profile",
        ).order_by(SyncRecord.updated_at.desc()).limit(1))
        profile = _profile(row.payload) if row is not None else None
        if profile is not None:
            result["profile"] = profile
    if selection.weight is not None:
        source = selection.weight.source
        row = await _selected_row(db, user_id, selection.weight.selection_id, "weight", revision, source,
                                  "measurement" if source == "measurement" else "healthSample")
        value = _manual_weight(row.payload) if source == "measurement" else _apple_weight(row.payload)
        if value is None:
            raise HTTPException(409, "Context selection unavailable")
        measured_at, weight = value
        result["weight"] = {"measured_at": measured_at, "value_kg": weight, "source": source}
    if selection.note is not None:
        row = await _selected_row(db, user_id, selection.note.selection_id, "note", revision, None, "workoutSession")
        value = _workout_note(row.payload)
        if value is None:
            raise HTTPException(409, "Context selection unavailable")
        result["workout_note"] = value[1]
    if selection.apple_health:
        apple = await _apple_projection(db, user_id)
        if apple is not None:
            result["apple_health"] = apple
    return result


async def training_context(db, user_id) -> dict:
    sessions_query = select(SyncRecord).where(SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None), SyncRecord.entity_type == "workoutSession").order_by(SyncRecord.updated_at.desc()).limit(3)
    session_rows = list((await db.scalars(sessions_query)).all())
    sessions: list[dict] = []
    session_ids: set[str] = set()
    for row in session_rows:
        payload = row.payload if isinstance(row.payload, dict) else {}
        started_at = _timestamp(payload.get("dataStart"))
        if started_at is None:
            continue
        session_id = str(row.entity_id)
        session_ids.add(session_id)
        item = {"id": session_id, "started_at": started_at}
        ended_at = _timestamp(payload.get("dataKoniec"))
        duration = _number(payload.get("czasTrwaniaSekund"), 0, 24 * 60 * 60)
        if ended_at is not None: item["ended_at"] = ended_at
        if duration is not None: item["duration_seconds"] = duration
        sessions.append(item)
    if not session_ids:
        return {"sessions": [], "sets": [], "catalogue": CATALOGUE}
    sets_query = select(SyncRecord).where(SyncRecord.user_id == user_id, SyncRecord.deleted_at.is_(None), SyncRecord.entity_type == "workoutSet").order_by(SyncRecord.updated_at.desc()).limit(20)
    set_rows = list((await db.scalars(sets_query)).all())
    sets: list[dict] = []
    for row in set_rows:
        payload = row.payload if isinstance(row.payload, dict) else {}
        session_id, exercise_id = payload.get("sessionSyncId"), payload.get("cwiczenieId")
        if not isinstance(session_id, str) or session_id not in session_ids or not isinstance(exercise_id, str) or exercise_id not in CATALOGUE:
            continue
        set_number = _number(payload.get("numerSerii"), 1, 100)
        reps = _number(payload.get("powtorzenia"), 1, 1000)
        weight = _number(payload.get("ciezarKg"), 0, 1000)
        if not isinstance(set_number, int) or isinstance(set_number, bool):
            continue
        item = {"session_id": session_id, "exercise_id": exercise_id, "set_number": set_number}
        if weight is not None: item["weight_kg"] = weight
        if isinstance(reps, int) and not isinstance(reps, bool): item["reps"] = reps
        sets.append(item)
    return {"sessions": sessions, "sets": sets[:20], "catalogue": CATALOGUE}
