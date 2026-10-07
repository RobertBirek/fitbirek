from uuid import uuid4
import asyncio

import pytest
import pytest_asyncio


@pytest_asyncio.fixture
async def mentor(client, session, monkeypatch, tmp_path):
    from cryptography.fernet import Fernet
    from app.config import settings
    from app.identity.models import User
    from app.identity.service import issue_session

    key_file = tmp_path / "mentor.key"
    key_file.write_bytes(Fernet.generate_key())
    monkeypatch.setattr(settings, "mentor_master_key_file", str(key_file), raising=False)
    user = User(email=f"{uuid4()}@example.com", password_hash="unused")
    session.add(user)
    await session.commit()
    issued = await issue_session(session, user)
    client.cookies.set("fit_session", issued.session_token)
    return {"Origin": "https://fit.birek.online", "X-CSRF-Token": issued.csrf_token}


@pytest.mark.asyncio
async def test_settings_keys_and_sessions_are_authenticated_and_private(client, mentor):
    settings = await client.get("/api/mentor/settings")
    assert settings.status_code == 200
    assert settings.headers["cache-control"] == "no-store"
    assert settings.json()["available"] is True
    assert settings.json()["openai_configured"] is False

    key = "sk-test-private-key"
    saved = await client.put("/api/mentor/keys/openai", json={"key": key}, headers=mentor)
    assert saved.status_code == 200
    assert saved.json() == {"configured": True}
    assert key not in saved.text
    assert (await client.get("/api/mentor/settings")).json()["openai_configured"] is True

    session_id = str(uuid4())
    created = await client.post("/api/mentor/sessions", json={"id": session_id}, headers=mentor)
    assert created.status_code == 200
    assert created.json()["id"] == session_id
    assert (await client.get("/api/mentor/sessions")).json()["sessions"][0]["id"] == session_id


@pytest.mark.asyncio
async def test_message_is_idempotent_and_vendor_is_mocked(client, mentor, monkeypatch):
    from app.mentor import service

    calls = []
    async def fake_reply(*args, **kwargs):
        calls.append(args)
        return {"text": "Zrób dziś spokojny trening.", "proposal": None, "tokens": 12}
    monkeypatch.setattr(service, "openai_reply", fake_reply)
    await client.put("/api/mentor/keys/openai", json={"key": "mock-key"}, headers=mentor)
    await client.put("/api/mentor/settings", json={"consent_text": True, "consent_voice": False, "memory": "", "model": "gpt-4.1-mini-2025-04-14", "tts_model": "eleven_multilingual_v2", "stt_model": "scribe_v2", "voice_id": "JBFqnCBsd6RMkjVDRZzb"}, headers=mentor)
    session_id, request_id = str(uuid4()), str(uuid4())
    await client.post("/api/mentor/sessions", json={"id": session_id}, headers=mentor)
    body = {"request_id": request_id, "text": "Co robić?"}
    first = await client.post(f"/api/mentor/sessions/{session_id}/messages", json=body, headers=mentor)
    second = await client.post(f"/api/mentor/sessions/{session_id}/messages", json=body, headers=mentor)
    assert first.status_code == second.status_code == 200
    assert first.json() == second.json()
    assert len(calls) == 1


@pytest.mark.asyncio
async def test_privacy_boundary_rejects_oversized_body_before_json(client, mentor):
    response = await client.put('/api/mentor/keys/openai', content=b'x' * 32769,
                                headers={**mentor, 'Content-Type': 'application/json'})
    assert response.status_code == 413
    assert response.headers['cache-control'] == 'no-store'


@pytest.mark.asyncio
async def test_missing_master_file_reports_disabled(client, mentor, monkeypatch):
    from app.config import settings
    monkeypatch.setattr(settings, 'mentor_master_key_file', '/nonexistent/mentor-key')
    assert (await client.get('/api/mentor/settings')).json()['available'] is False


async def enable_chat(client, headers):
    await client.put('/api/mentor/keys/openai', json={'key': 'mock-private-key'}, headers=headers)
    config = (await client.get('/api/mentor/settings')).json()
    fields = ('consent_text', 'consent_voice', 'memory', 'model', 'tts_model', 'stt_model', 'voice_id')
    body = {key: config[key] for key in fields}
    body['consent_text'] = True
    body['consent_voice'] = True
    assert (await client.put('/api/mentor/settings', json=body, headers=headers)).status_code == 200
    sid = str(uuid4())
    await client.post('/api/mentor/sessions', json={'id': sid}, headers=headers)
    return sid


@pytest.mark.asyncio
async def test_delete_during_generation_discards_reply(client, mentor, monkeypatch):
    from app.mentor import service
    entered, release = asyncio.Event(), asyncio.Event()
    async def waiting(*args, **kwargs):
        entered.set()
        await release.wait()
        return {'text': 'private answer', 'proposal': None, 'tokens': 12}
    monkeypatch.setattr(service, 'openai_reply', waiting)
    sid = await enable_chat(client, mentor)
    task = asyncio.create_task(client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'private question'}, headers=mentor))
    await asyncio.wait_for(entered.wait(), 5)
    assert (await client.delete(f'/api/mentor/sessions/{sid}', headers=mentor)).status_code == 200
    release.set()
    assert (await task).status_code == 409
    assert (await client.get(f'/api/mentor/sessions/{sid}/messages')).status_code == 404


@pytest.mark.asyncio
async def test_no_pasted_credentials_in_prompt(client, mentor, monkeypatch):
    from app.mentor import service
    called = False
    async def forbidden(*args, **kwargs):
        nonlocal called
        called = True
        return {'text': 'answer', 'proposal': None, 'tokens': 1}
    monkeypatch.setattr(service, 'openai_reply', forbidden)
    sid = await enable_chat(client, mentor)
    result = await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Here is mock-private-key'}, headers=mentor)
    assert result.status_code == 422
    assert not called


@pytest.mark.asyncio
async def test_voice_endpoints_call_mock_vendor_and_count_caps(client, mentor, monkeypatch):
    from app.mentor import service
    async def voices(*args, **kwargs):
        return [{'voice_id': 'SafeVoice', 'name': 'Test'}]
    monkeypatch.setattr(service, 'list_voices', voices, raising=False)
    await enable_chat(client, mentor)
    await client.put('/api/mentor/keys/elevenlabs', json={'key': 'mock-voice-key'}, headers=mentor)
    result = await client.post('/api/mentor/voices', json={'request_id': str(uuid4())}, headers=mentor)
    assert result.status_code == 200
    assert result.json()['voices'][0]['voice_id'] == 'SafeVoice'
    status = (await client.get('/api/mentor/settings')).json()
    assert status['usage']['requests'] == 1
    assert any(v['voice_id'] == 'SafeVoice' for v in status['voices'])


@pytest.mark.asyncio
async def test_concurrent_generation_is_reserved_once_and_replay_is_bound(client, mentor, monkeypatch):
    from app.mentor import service
    entered, release = asyncio.Event(), asyncio.Event()
    calls = 0
    async def waiting(*args, **kwargs):
        nonlocal calls
        calls += 1
        entered.set()
        await release.wait()
        return {'text': 'Spokojny plan.', 'proposal': None, 'tokens': 12}
    monkeypatch.setattr(service, 'openai_reply', waiting)
    sid = await enable_chat(client, mentor)
    rid = str(uuid4())
    url = f'/api/mentor/sessions/{sid}/messages'
    first = asyncio.create_task(client.post(url, json={'request_id': rid, 'text': 'Plan'}, headers=mentor))
    await asyncio.wait_for(entered.wait(), 5)
    duplicate = await client.post(url, json={'request_id': rid, 'text': 'Plan'}, headers=mentor)
    other = await client.post(url, json={'request_id': str(uuid4()), 'text': 'Inny plan'}, headers=mentor)
    assert duplicate.status_code == 409
    assert other.status_code == 429
    release.set()
    assert (await first).status_code == 200
    assert calls == 1
    collision = await client.post(url, json={'request_id': rid, 'text': 'Different body'}, headers=mentor)
    assert collision.status_code == 409
    status = (await client.get('/api/mentor/settings')).json()
    assert status['usage']['requests'] == 1
    assert status['usage']['output_tokens'] == 12


@pytest.mark.asyncio
async def test_ambiguous_failure_never_retries_or_refunds_reserved_tokens(client, mentor, monkeypatch):
    from app.mentor import service
    calls = 0
    async def timeout(*args, **kwargs):
        nonlocal calls
        calls += 1
        raise TimeoutError('provider private error body')
    monkeypatch.setattr(service, 'openai_reply', timeout)
    sid = await enable_chat(client, mentor)
    body = {'request_id': str(uuid4()), 'text': 'Plan'}
    result = await client.post(f'/api/mentor/sessions/{sid}/messages', json=body, headers=mentor)
    assert result.status_code == 502
    assert 'private' not in result.text
    again = await client.post(f'/api/mentor/sessions/{sid}/messages', json=body, headers=mentor)
    assert again.status_code == 409
    assert calls == 1
    assert (await client.get('/api/mentor/settings')).json()['usage']['output_tokens'] == 800


@pytest.mark.asyncio
async def test_daily_cap_prevents_vendor_call(client, mentor, session, monkeypatch):
    from app.mentor import service
    from app.mentor.models import MentorUsage
    from sqlalchemy import update
    sid = await enable_chat(client, mentor)
    await session.execute(update(MentorUsage).values(requests=60))
    await session.commit()
    async def forbidden(*args, **kwargs):
        pytest.fail('cap must be checked before provider')
    monkeypatch.setattr(service, 'openai_reply', forbidden)
    result = await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor)
    assert result.status_code == 429


@pytest.mark.asyncio
async def test_key_change_discards_inflight_answer(client, mentor, monkeypatch):
    from app.mentor import service
    entered, release = asyncio.Event(), asyncio.Event()
    async def waiting(*args, **kwargs):
        entered.set()
        await release.wait()
        return {'text': 'Old generation', 'proposal': None, 'tokens': 12}
    monkeypatch.setattr(service, 'openai_reply', waiting)
    sid = await enable_chat(client, mentor)
    task = asyncio.create_task(client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor))
    await asyncio.wait_for(entered.wait(), 5)
    await client.delete('/api/mentor/keys/openai', headers=mentor)
    release.set()
    assert (await task).status_code == 409
    assert all(m['role'] != 'assistant' for m in (await client.get(f'/api/mentor/sessions/{sid}/messages')).json()['messages'])


@pytest.mark.asyncio
async def test_owned_assistant_only_tts_and_idempotent_bytes(client, mentor, monkeypatch):
    from app.mentor import service
    async def answer(*args, **kwargs):
        return {'text': 'Spokojny plan.', 'proposal': None, 'tokens': 12}
    captured = []
    async def speech(key, model, voice, text):
        captured.append(text)
        return b'mocked-mp3'
    monkeypatch.setattr(service, 'openai_reply', answer)
    monkeypatch.setattr(service, 'speak', speech)
    sid = await enable_chat(client, mentor)
    await client.put('/api/mentor/keys/elevenlabs', json={'key': 'mock-eleven-key'}, headers=mentor)
    msg = (await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor)).json()
    rid = {'request_id': str(uuid4())}
    audio = await client.post(f'/api/mentor/messages/{msg["id"]}/tts', json=rid, headers=mentor)
    assert audio.status_code == 200 and audio.content == b'mocked-mp3'
    assert audio.headers['cache-control'] == 'no-store'
    assert (await client.post(f'/api/mentor/messages/{msg["id"]}/tts', json=rid, headers=mentor)).status_code == 409
    user_msg = (await client.get(f'/api/mentor/sessions/{sid}/messages')).json()['messages'][0]
    assert (await client.post(f'/api/mentor/messages/{user_msg["id"]}/tts', json={'request_id': str(uuid4())}, headers=mentor)).status_code == 404
    assert captured == ['Spokojny plan.']
    assert (await client.get('/api/mentor/settings')).json()['usage']['tts_chars'] == len('Spokojny plan.')


@pytest.mark.asyncio
async def test_auth_csrf_and_other_account_ownership(client, mentor, session):
    from app.identity.models import User
    from app.identity.service import issue_session
    sid = await enable_chat(client, mentor)
    assert (await client.put('/api/mentor/keys/openai', json={'key': 'x'})).status_code == 403
    other = User(email=f'{uuid4()}@example.com', password_hash='unused')
    session.add(other)
    await session.commit()
    issued = await issue_session(session, other)
    client.cookies.set('fit_session', issued.session_token)
    headers = {'Origin': 'https://fit.birek.online', 'X-CSRF-Token': issued.csrf_token}
    assert (await client.get(f'/api/mentor/sessions/{sid}/messages')).status_code == 404
    assert (await client.delete(f'/api/mentor/sessions/{sid}', headers=headers)).status_code == 404
    assert (await client.post('/api/mentor/sessions', json={'id': sid}, headers=headers)).status_code == 404
    assert (await client.get('/api/mentor/settings')).json()['openai_configured'] is False
    client.cookies.clear()
    assert (await client.get('/api/mentor/settings')).status_code == 401


@pytest.mark.asyncio
async def test_credentials_encrypted_bound_and_validation_errors_generic(client, mentor, session):
    from app.mentor.models import MentorCredential
    from sqlalchemy import select
    await client.put('/api/mentor/keys/openai', json={'key': 'private-test-key'}, headers=mentor)
    row = await session.scalar(select(MentorCredential))
    assert b'private-test-key' not in row.encrypted_key
    row.encrypted_key = b'corrupt encrypted record'
    await session.commit()
    config = (await client.get('/api/mentor/settings')).json()
    fields = ('consent_text', 'consent_voice', 'memory', 'model', 'tts_model', 'stt_model', 'voice_id')
    assert (await client.put('/api/mentor/settings', json={k: config[k] for k in fields}, headers=mentor)).status_code == 503
    response = await client.put('/api/mentor/keys/openai', json={'key': 'key\nprivate', 'secret': 'not-for-errors'}, headers=mentor)
    assert response.status_code == 422
    assert 'private' not in response.text and 'not-for-errors' not in response.text


@pytest.mark.asyncio
async def test_chunked_body_limit_and_https(client, mentor):
    async def chunks():
        yield b'x' * 20000
        yield b'x' * 20000
    response = await client.put('/api/mentor/keys/openai', content=chunks(), headers=mentor)
    assert response.status_code == 413
    response = await client.get('http://test/api/mentor/settings')
    assert response.status_code == 403 and response.headers['cache-control'] == 'no-store'


@pytest.mark.asyncio
async def test_stt_is_editable_transcript_only_and_reserves_full_duration(client, mentor, monkeypatch):
    from app.mentor import audio, service
    monkeypatch.setattr(audio, 'validate_audio', lambda *_: 1.2)
    seen = []
    async def transcribe(key, model, data, mime):
        seen.append((data, mime))
        return '10 kg × 8'
    monkeypatch.setattr(service, 'transcribe', transcribe)
    sid = await enable_chat(client, mentor)
    await client.put('/api/mentor/keys/elevenlabs', json={'key': 'mock-eleven-key'}, headers=mentor)
    rid = str(uuid4())
    headers = {**mentor, 'Content-Type': 'audio/webm', 'X-Request-ID': rid, 'X-Audio-Duration': '1.2'}
    response = await client.post('/api/mentor/stt', content=b'fake-container', headers=headers)
    assert response.status_code == 200 and response.json() == {'text': '10 kg × 8'}
    assert seen == [(b'fake-container', 'audio/webm')]
    assert (await client.get(f'/api/mentor/sessions/{sid}/messages')).json()['messages'] == []
    assert (await client.post('/api/mentor/stt', content=b'fake-container', headers=headers)).status_code == 409
    status = (await client.get('/api/mentor/settings')).json()
    assert status['usage']['stt_seconds'] == 30
    assert status['usage']['stt_bytes'] == len(b'fake-container')


@pytest.mark.asyncio
@pytest.mark.parametrize('dimension,operation', [('tts_chars', 'tts'), ('stt_bytes', 'stt'), ('stt_seconds', 'stt'), ('output_tokens', 'test_openai')])
async def test_all_usage_dimensions_are_enforced(client, mentor, session, monkeypatch, dimension, operation):
    from app.mentor import audio, service
    from app.mentor.models import MentorUsage
    from sqlalchemy import update
    monkeypatch.setattr(audio, 'validate_audio', lambda *_: 1.2)
    async def reply(*args, **kwargs):
        return {'text': 'Plan', 'proposal': None, 'tokens': 12}
    async def forbidden(*args, **kwargs):
        pytest.fail('cap must be checked before provider')
    monkeypatch.setattr(service, 'openai_reply', reply)
    sid = await enable_chat(client, mentor)
    await client.put('/api/mentor/keys/elevenlabs', json={'key': 'mock-eleven-key'}, headers=mentor)
    message = (await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor)).json()
    await session.execute(update(MentorUsage).values(**{dimension: service.LIMITS[dimension]}))
    await session.commit()
    monkeypatch.setattr(service, 'openai_reply', forbidden)
    monkeypatch.setattr(service, 'speak', forbidden)
    monkeypatch.setattr(service, 'transcribe', forbidden)
    if operation == 'tts':
        response = await client.post(f'/api/mentor/messages/{message["id"]}/tts',
            json={'request_id': str(uuid4())}, headers=mentor)
    elif operation == 'stt':
        response = await client.post('/api/mentor/stt', content=b'audio', headers={
            **mentor, 'Content-Type': 'audio/webm', 'X-Request-ID': str(uuid4()), 'X-Audio-Duration': '1.2'})
    else:
        response = await client.post('/api/mentor/test/openai', json={'request_id': str(uuid4())}, headers=mentor)
    assert response.status_code == 429


@pytest.mark.asyncio
async def test_set_proposal_is_bounded_clarifies_ambiguity_and_never_writes_training(client, mentor, monkeypatch, session):
    from app.mentor import service
    from app.sync.models import SyncRecord
    from sqlalchemy import func, select
    async def proposal(*args, **kwargs):
        return {'text': 'Propozycja serii.', 'proposal': {'kind': 'log_set', 'exercise_id': 'cw001', 'weight_kg': 10, 'reps': 8}, 'tokens': 12}
    monkeypatch.setattr(service, 'openai_reply', proposal)
    sid = await enable_chat(client, mentor)
    ambiguous = await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Zrobiłem pompki 10'}, headers=mentor)
    assert ambiguous.status_code == 200
    assert ambiguous.json()['proposal'] is None and 'Doprecyzuj' in ambiguous.json()['text']
    request_id = str(uuid4())
    clear = await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': request_id, 'text': 'Pompki 10 kg × 8'}, headers=mentor)
    assert clear.status_code == 200 and clear.json()['proposal']['kind'] == 'log_set'
    assert 'id' in clear.json()['proposal'] and 'rpe' not in clear.json()['proposal']
    assert await session.scalar(select(func.count()).select_from(SyncRecord)) == 0


@pytest.mark.asyncio
async def test_real_db_context_excludes_private_health_and_foreign_workouts(client, mentor, monkeypatch, session):
    from app.mentor import service
    from app.identity.models import User
    from app.sync.models import SyncRecord
    from sqlalchemy import select
    import json
    owner = await session.scalar(select(User.id))
    other = User(email=f'{uuid4()}@example.com', password_hash='unused')
    session.add(other)
    await session.flush()
    workout_id = uuid4()
    rows = [
        (owner, 'workoutSession', workout_id, {'dataStart': '2026-09-01T10:00:00Z', 'notatka': 'PRIVATE-NOTE'}),
        (owner, 'workoutSet', uuid4(), {'sessionSyncId': str(workout_id), 'cwiczenieId': 'cw001', 'numerSerii': 1, 'ciezarKg': 10, 'powtorzenia': 8, 'nazwaCwiczeniaPl': 'PRIVATE-NAME'}),
        (owner, 'healthSample', uuid4(), {'value': 'PRIVATE-HEALTH'}),
        (owner, 'profile', uuid4(), {'wagaKg': 999, 'imie': 'PRIVATE-PROFILE'}),
        (other.id, 'workoutSession', uuid4(), {'dataStart': '2026-09-02T10:00:00Z', 'notatka': 'PRIVATE-FOREIGN'}),
    ]
    for uid, kind, eid, payload in rows:
        session.add(SyncRecord(user_id=uid, entity_type=kind, entity_id=eid, version=1,
                               payload=payload, deleted_at=None, updated_at=service.now()))
    await session.commit()
    sent = []
    async def reply(key, model, messages, **kwargs):
        sent.append(messages)
        return {'text': 'Plan.', 'proposal': None, 'tokens': 12}
    monkeypatch.setattr(service, 'openai_reply', reply)
    sid = await enable_chat(client, mentor)
    assert (await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor)).status_code == 200
    rendered = json.dumps(sent)
    assert 'PRIVATE' not in rendered and '999' not in rendered and str(other.id) not in rendered
    assert 'cw001' in rendered and str(workout_id) in rendered


@pytest.mark.asyncio
async def test_logout_during_generation_discards_late_reply(client, mentor, monkeypatch, session):
    from app.mentor import service
    from app.mentor.models import MentorMessage
    from sqlalchemy import select
    entered, release = asyncio.Event(), asyncio.Event()
    async def waiting(*args, **kwargs):
        entered.set()
        await release.wait()
        return {'text': 'late reply', 'proposal': None, 'tokens': 12}
    monkeypatch.setattr(service, 'openai_reply', waiting)
    sid = await enable_chat(client, mentor)
    task = asyncio.create_task(client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor))
    await asyncio.wait_for(entered.wait(), 5)
    assert (await client.post('/api/auth/logout', headers=mentor)).status_code in (200, 204)
    release.set()
    assert (await task).status_code == 401
    assert await session.scalar(select(MentorMessage).where(MentorMessage.role == 'assistant')) is None
