from datetime import datetime, timedelta, timezone
import json
from uuid import uuid4

import pytest
import pytest_asyncio
from pydantic import ValidationError


def test_message_context_selection_is_strict_and_never_accepts_raw_record_ids():
    from app.mentor.schemas import MessageInput

    with pytest.raises(ValidationError):
        MessageInput.model_validate({
            "request_id": str(uuid4()), "text": "Plan", "settings_revision": 0,
            "context": {"weight": {"source": "measurement", "selection_id": str(uuid4())}},
        })
    with pytest.raises(ValidationError):
        MessageInput.model_validate({
            "request_id": str(uuid4()), "text": "Plan",
            "context": {"training": 1},
        })
    with pytest.raises(ValidationError):
        MessageInput.model_validate({
            "request_id": str(uuid4()), "text": "Plan",
            "context": {"training": True, "payload": {"raw": "data"}},
        })


@pytest_asyncio.fixture
async def context_account(client, session, monkeypatch, tmp_path):
    from cryptography.fernet import Fernet

    from app.config import settings
    from app.identity.models import User
    from app.identity.service import issue_session

    key_file = tmp_path / "mentor.key"
    key_file.write_bytes(Fernet.generate_key())
    monkeypatch.setattr(settings, "mentor_master_key_file", str(key_file), raising=False)
    monkeypatch.setitem(settings.__dict__, "mentor_context_generation", "A" * 32)
    account = User(email=f"{uuid4()}@example.com", password_hash="unused")
    session.add(account)
    await session.commit()
    issued = await issue_session(session, account)
    client.cookies.set("fit_session", issued.session_token)
    return account, {"Origin": "https://fit.birek.online", "X-CSRF-Token": issued.csrf_token}, issued.session_token


@pytest.mark.asyncio
async def test_context_options_are_private_and_provider_free(client, context_account, session, monkeypatch):
    from app.identity.models import User
    from app.mentor import service
    from app.sync.models import SyncRecord

    account, _, session_token = context_account
    other = User(email=f"{uuid4()}@example.com", password_hash="unused")
    session.add(other)
    await session.flush()
    own_weight, own_note = uuid4(), uuid4()
    session.add_all([
        SyncRecord(
            user_id=account.id, entity_type="profile", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=datetime.now(timezone.utc),
            payload={"wiek": 34, "cel": "sila", "wzrostCm": 181, "imie": "PRIVATE-NAME"},
        ),
        SyncRecord(
            user_id=account.id, entity_type="measurement", entity_id=own_weight, version=1,
            deleted_at=None, updated_at=datetime.now(timezone.utc),
            payload={"data": "2026-10-01T08:00:00Z", "wagaKg": 80.5, "notatka": "PRIVATE-MEASUREMENT"},
        ),
        SyncRecord(
            user_id=account.id, entity_type="workoutSession", entity_id=own_note, version=1,
            deleted_at=None, updated_at=datetime.now(timezone.utc),
            payload={"dataStart": "2026-10-01T10:00:00Z", "notatka": "Wybrana notatka"},
        ),
        SyncRecord(
            user_id=account.id, entity_type="healthSample", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=datetime.now(timezone.utc),
            payload={"kind": "steps", "day": "2026-10-01", "value": 7123, "source": "Apple Health", "importedAt": "PRIVATE-APPLE-TOKEN"},
        ),
        SyncRecord(
            user_id=other.id, entity_type="measurement", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=datetime.now(timezone.utc),
            payload={"data": "2026-10-02T08:00:00Z", "wagaKg": 12.3, "notatka": "PRIVATE-FOREIGN"},
        ),
    ])
    await session.commit()

    called = False

    async def forbidden_provider(*_args, **_kwargs):
        nonlocal called
        called = True
        raise AssertionError("context preview must not call the provider")

    monkeypatch.setattr(service, "openai_reply", forbidden_provider)

    client.cookies.clear()
    assert (await client.get("/api/mentor/context-options")).status_code == 401
    client.cookies.set("fit_session", session_token)

    response = await client.get("/api/mentor/context-options")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["settings_revision"] == 0
    options = body["options"]
    assert options["training"] == {"available": True, "summary": "Ostatnie 12 tygodni"}
    assert options["profile"]["available"] is True
    assert options["weight"][0]["selection_id"]
    assert options["workout_notes"][0]["selection_id"]
    assert options["apple_health"]["available"] is True
    rendered = response.text
    assert str(own_weight) not in rendered and str(own_note) not in rendered
    assert "PRIVATE" not in rendered and str(other.id) not in rendered
    assert not called


@pytest.mark.asyncio
async def test_selected_context_is_bounded_consented_and_never_persisted(client, context_account, session, monkeypatch):
    from app.mentor import service
    from app.mentor.models import MentorMessage, MentorRequest
    from app.sync.models import SyncRecord
    from sqlalchemy import select

    account, headers, _ = context_account
    instant = service.now()
    session_ids = []
    for index in range(25):
        entity_id = uuid4()
        session_ids.append(entity_id)
        session.add(SyncRecord(
            user_id=account.id, entity_type="workoutSession", entity_id=entity_id, version=1,
            deleted_at=None, updated_at=instant,
            payload={"dataStart": (instant.replace(microsecond=0)).isoformat(),
                     "dataKoniec": (instant.replace(microsecond=0) + timedelta(minutes=30)).isoformat(),
                     "notatka": "PRIVATE-TRAINING-NOTE"},
        ))
        session.add(SyncRecord(
            user_id=account.id, entity_type="workoutSet", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=instant,
            payload={"sessionSyncId": str(entity_id), "cwiczenieId": "cw001", "numerSerii": 1, "ciezarKg": 10, "powtorzenia": 8, "private": "PRIVATE-SET"},
        ))
    selected_note = uuid4()
    selected_weight = uuid4()
    session.add_all([
        SyncRecord(
            user_id=account.id, entity_type="profile", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=instant,
            payload={"wiek": 34, "cel": "sila", "wzrostCm": 181, "imie": "PRIVATE-PROFILE"},
        ),
        SyncRecord(
            user_id=account.id, entity_type="measurement", entity_id=selected_weight, version=1,
            deleted_at=None, updated_at=instant,
            payload={"data": instant.replace(microsecond=0).isoformat(), "wagaKg": 81, "notatka": "PRIVATE-WEIGHT"},
        ),
        SyncRecord(
            user_id=account.id, entity_type="workoutSession", entity_id=selected_note, version=1,
            deleted_at=None, updated_at=instant + timedelta(seconds=1),
            payload={"dataStart": instant.replace(microsecond=0).isoformat(),
                     "dataKoniec": (instant.replace(microsecond=0) + timedelta(minutes=30)).isoformat(),
                     "notatka": "Wybrana notatka " + "x" * 600},
        ),
    ])
    for days_ago in range(7):
        day = (instant - timedelta(days=days_ago)).date().isoformat()
        session.add(SyncRecord(
            user_id=account.id, entity_type="healthSample", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=instant,
            payload={"kind": "steps", "day": day, "value": 7000 + days_ago,
                     "source": "Apple Health", "importedAt": "PRIVATE-APPLE-TOKEN"},
        ))
    for days_ago, value in ((6, 80), (0, 81)):
        session.add(SyncRecord(
            user_id=account.id, entity_type="healthSample", entity_id=uuid4(), version=1,
            deleted_at=None, updated_at=instant,
            payload={"kind": "weight", "measuredAt": (instant - timedelta(days=days_ago)).replace(microsecond=0).isoformat(),
                     "value": value, "source": "Apple Health", "importedAt": "PRIVATE-APPLE-TOKEN"},
        ))
    await session.commit()

    captured = []

    async def provider(_key, _profile, messages):
        captured.append(messages)
        return {"text": "Gotowe.", "proposal": None, "input_tokens": 4, "output_tokens": 12}

    monkeypatch.setattr(service, "openai_reply", provider)
    assert (await client.put("/api/mentor/keys/openai", json={"key": "mock-key"}, headers=headers)).status_code == 200
    configured = await client.put("/api/mentor/settings", json={
            "consent_text": True, "model_profile_key": "legacy-gpt-4.1-mini-2025-04-14",
            "context_policy_version": 1,
            "context_consents": {"training": True, "profile": True, "weight": True, "note": True, "apple_health": True},
    }, headers=headers)
    assert configured.status_code == 200
    revision = configured.json()["revision"]
    mentor_session = str(uuid4())
    assert (await client.post("/api/mentor/sessions", json={"id": mentor_session}, headers=headers)).status_code == 200
    options = (await client.get("/api/mentor/context-options")).json()["options"]
    weight = next(option for option in options["weight"] if option["source"] == "measurement")
    note = next(option for option in options["workout_notes"] if option["preview"].startswith("Wybrana"))

    response = await client.post(f"/api/mentor/sessions/{mentor_session}/messages", json={
        "request_id": str(uuid4()), "text": "Ułóż spokojny plan.", "settings_revision": revision,
        "context": {"training": True, "profile": True, "apple_health": True,
                    "weight": {"source": weight["source"], "selection_id": weight["selection_id"]},
                    "note": {"selection_id": note["selection_id"]}},
    }, headers=headers)

    assert response.status_code == 200, response.text
    context_message = next(item["content"] for item in captured[0] if item["content"].startswith("Wybrany kontekst"))
    projected = json.loads(context_message.partition(": ")[2])
    assert len(projected["training"]["sessions"]) == 12
    assert projected["profile"] == {"age": 34, "goal": "sila", "height_cm": 181}
    assert projected["weight"]["value_kg"] == 81
    assert len(projected["workout_note"]) == 500
    assert projected["apple_health"]["steps_7_days"] == {"total": sum(7000 + day for day in range(7)), "days_with_data": 7}
    rendered = json.dumps(projected)
    assert "PRIVATE" not in rendered
    assert str(selected_note) not in rendered and str(selected_weight) not in rendered
    assert all(str(value) not in rendered for value in session_ids)
    assert "session_id" not in rendered and "exercise_id" not in rendered and "catalogue" not in rendered
    persisted = (await session.scalars(select(MentorMessage))).all()
    request = await session.scalar(select(MentorRequest))
    assert "Wybrany kontekst" not in json.dumps([row.text for row in persisted])
    assert note["selection_id"] not in json.dumps(request.response) + request.payload_digest


@pytest.mark.asyncio
@pytest.mark.parametrize("context", [
    {"training": True},
    {"profile": True},
    {"apple_health": True},
    {"weight": {"source": "measurement", "selection_id": "A" * 100}},
    {"note": {"selection_id": "A" * 100}},
])
async def test_every_context_category_requires_stored_consent_before_provider(client, context_account, monkeypatch, context):
    from app.mentor import service

    _, headers, _ = context_account
    called = False

    async def forbidden(*_args, **_kwargs):
        nonlocal called
        called = True
        raise AssertionError("consent must be checked before provider")

    monkeypatch.setattr(service, "openai_reply", forbidden)
    assert (await client.put("/api/mentor/keys/openai", json={"key": "mock-key"}, headers=headers)).status_code == 200
    saved = await client.put("/api/mentor/settings", json={
        "consent_text": True, "model_profile_key": "legacy-gpt-4.1-mini-2025-04-14",
    }, headers=headers)
    session_id = str(uuid4())
    assert (await client.post("/api/mentor/sessions", json={"id": session_id}, headers=headers)).status_code == 200

    response = await client.post(f"/api/mentor/sessions/{session_id}/messages", json={
        "request_id": str(uuid4()), "text": "Plan", "settings_revision": saved.json()["revision"], "context": context,
    }, headers=headers)

    assert response.status_code == 409
    assert not called


@pytest.mark.asyncio
async def test_context_rejects_stale_settings_revision_before_provider(client, context_account, monkeypatch):
    from app.mentor import service

    _, headers, _ = context_account
    called = False

    async def forbidden(*_args, **_kwargs):
        nonlocal called
        called = True
        raise AssertionError("stale context must not call the provider")

    monkeypatch.setattr(service, "openai_reply", forbidden)
    assert (await client.put("/api/mentor/keys/openai", json={"key": "mock-key"}, headers=headers)).status_code == 200
    saved = await client.put("/api/mentor/settings", json={
            "consent_text": True, "model_profile_key": "legacy-gpt-4.1-mini-2025-04-14",
            "context_policy_version": 1,
            "context_consents": {"training": True, "profile": False, "weight": False,
                                 "note": False, "apple_health": False},
    }, headers=headers)
    stale_revision = saved.json()["revision"]
    assert (await client.put("/api/mentor/settings", json={"persona": "Nowa persona"}, headers=headers)).status_code == 200
    session_id = str(uuid4())
    assert (await client.post("/api/mentor/sessions", json={"id": session_id}, headers=headers)).status_code == 200

    response = await client.post(f"/api/mentor/sessions/{session_id}/messages", json={
        "request_id": str(uuid4()), "text": "Plan", "settings_revision": stale_revision,
        "context": {"training": True},
    }, headers=headers)

    assert response.status_code == 409
    assert not called


@pytest.mark.asyncio
async def test_context_consent_requires_current_operator_generation_after_restore(
    client, context_account, monkeypatch,
):
    """A restored database cannot reactivate context consents by itself."""
    from app.config import settings
    from app.mentor import service

    _, headers, _ = context_account
    calls = []

    async def provider(*_args, **_kwargs):
        calls.append(True)
        return {"text": "Gotowe.", "proposal": None, "input_tokens": 4, "output_tokens": 4}

    monkeypatch.setattr(service, "openai_reply", provider)
    assert (await client.put("/api/mentor/keys/openai", json={"key": "mock-key"}, headers=headers)).status_code == 200
    initial = await client.put("/api/mentor/settings", json={
        "consent_text": True,
        "model_profile_key": "legacy-gpt-4.1-mini-2025-04-14",
        "context_policy_version": 1,
        "context_consents": {
            "training": True, "profile": False, "weight": False,
            "note": False, "apple_health": False,
        },
    }, headers=headers)
    assert initial.status_code == 200, initial.text
    mentor_session = str(uuid4())
    assert (await client.post("/api/mentor/sessions", json={"id": mentor_session}, headers=headers)).status_code == 200

    first = await client.post(f"/api/mentor/sessions/{mentor_session}/messages", json={
        "request_id": str(uuid4()), "text": "Plan", "settings_revision": initial.json()["revision"],
        "context": {"training": True},
    }, headers=headers)
    assert first.status_code == 200, first.text
    assert calls == [True]

    monkeypatch.setitem(settings.__dict__, "mentor_context_generation", "B" * 32)
    unavailable = await client.get("/api/mentor/settings")
    assert unavailable.json()["context_consents"]["training"] is False
    blocked = await client.post(f"/api/mentor/sessions/{mentor_session}/messages", json={
        "request_id": str(uuid4()), "text": "Plan", "settings_revision": initial.json()["revision"],
        "context": {"training": True},
    }, headers=headers)
    assert blocked.status_code == 409
    assert calls == [True]

    renewed = await client.put("/api/mentor/settings", json={
        "context_policy_version": 1,
        "context_consents": {
            "training": True, "profile": False, "weight": False,
            "note": False, "apple_health": False,
        },
    }, headers=headers)
    assert renewed.status_code == 200, renewed.text
    resumed = await client.post(f"/api/mentor/sessions/{mentor_session}/messages", json={
        "request_id": str(uuid4()), "text": "Plan", "settings_revision": renewed.json()["revision"],
        "context": {"training": True},
    }, headers=headers)
    assert resumed.status_code == 200, resumed.text
    assert calls == [True, True]


@pytest.mark.asyncio
async def test_training_projection_excludes_open_sessions_and_aggregates_progress(client):
    from app.mentor.context import _training_projection
    from app.sync.models import SyncRecord

    user_id = uuid4()
    now = datetime.now(timezone.utc).replace(microsecond=0)
    open_id, early_id, recent_id = uuid4(), uuid4(), uuid4()
    records = [
        SyncRecord(user_id=user_id, entity_type="workoutSession", entity_id=open_id, version=1,
                   deleted_at=None, updated_at=now,
                   payload={"dataStart": now.isoformat()}),
        SyncRecord(user_id=user_id, entity_type="workoutSession", entity_id=early_id, version=1,
                   deleted_at=None, updated_at=now,
                   payload={"dataStart": (now - timedelta(days=7)).isoformat(),
                            "dataKoniec": (now - timedelta(days=7) + timedelta(minutes=30)).isoformat()}),
        SyncRecord(user_id=user_id, entity_type="workoutSession", entity_id=recent_id, version=1,
                   deleted_at=None, updated_at=now,
                   payload={"dataStart": (now - timedelta(days=1)).isoformat(),
                            "dataKoniec": (now - timedelta(days=1) + timedelta(minutes=30)).isoformat()}),
        SyncRecord(user_id=user_id, entity_type="workoutSet", entity_id=uuid4(), version=1,
                   deleted_at=None, updated_at=now,
                   payload={"sessionSyncId": str(early_id), "cwiczenieId": "cw001", "numerSerii": 1,
                            "ciezarKg": 10, "powtorzenia": 8}),
        SyncRecord(user_id=user_id, entity_type="workoutSet", entity_id=uuid4(), version=1,
                   deleted_at=None, updated_at=now,
                   payload={"sessionSyncId": str(recent_id), "cwiczenieId": "cw001", "numerSerii": 1,
                            "ciezarKg": 12, "powtorzenia": 8}),
    ]

    class Result:
        def all(self):
            return records

    class Db:
        async def scalars(self, _query):
            return Result()

    projected = await _training_projection(Db(), user_id)

    assert len(projected["sessions"]) == 2
    assert projected["progress_trend"] == {
        "completed_sessions": 2,
        "by_exercise": [{"exercise": "Pompki klasyczne", "direction": "up"}],
    }
    rendered = json.dumps(projected)
    assert str(open_id) not in rendered and str(early_id) not in rendered and str(recent_id) not in rendered
    trend_rendered = json.dumps(projected["progress_trend"])
    assert "10" not in trend_rendered and "12" not in trend_rendered and "started_at" not in trend_rendered
