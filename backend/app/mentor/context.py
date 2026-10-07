"""Explicitly projected workout context; never expose stored free text."""
from datetime import datetime, timezone
import math
from typing import Any

from sqlalchemy import select

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
