"""Recovery never starts a provider operation or exposes another account's state."""
import asyncio
from uuid import UUID, uuid4

import pytest
from sqlalchemy import select

from test_mentor import mentor, enable_chat


@pytest.mark.asyncio
async def test_subject_recovery_keeps_legacy_unknown_tts_before_list_limit(client, mentor, session):
    from app.identity.models import User
    from app.mentor.models import MentorRequest
    from app.mentor.service import now
    uid = await session.scalar(select(User.id))
    rid = uuid4()
    session.add(MentorRequest(user_id=uid, request_id=rid, kind='tts', subject_id=None,
        session_id=None, state='complete', response=None, payload_digest='0' * 64, created_at=now()))
    for _ in range(105):
        session.add(MentorRequest(user_id=uid, request_id=uuid4(), kind='voices',
            state='complete', response=None, payload_digest='0' * 64, created_at=now()))
    await session.commit()
    result = (await client.get('/api/mentor/operations', params={
        'subject_id': str(uuid4()), 'kind': 'tts'})).json()['operations']
    assert len(result) == 1 and result[0]['request_id'] == str(rid)


@pytest.mark.asyncio
async def test_chat_result_recovered_after_lost_response_without_new_call(client, mentor, monkeypatch):
    from app.mentor import service
    calls = []
    async def reply(*args, **kwargs):
        calls.append(1)
        return {'text': 'Recovered answer', 'proposal': None, 'tokens': 5}
    monkeypatch.setattr(service, 'openai_reply', reply)
    sid = await enable_chat(client, mentor)
    rid = str(uuid4())
    first = await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': rid, 'text': 'Private typed body'}, headers=mentor)
    assert first.status_code == 200
    # Browser loses first response and its private draft; operation is server-owned.
    lookup = await client.get(f'/api/mentor/operations/{rid}')
    assert lookup.status_code == 200
    assert lookup.headers['cache-control'] == 'no-store'
    op = lookup.json()
    assert op['state'] == 'complete' and op['response'] == first.json()
    assert op['user_text'] == 'Private typed body'
    listing = await client.get('/api/mentor/operations', params={'session_id': sid})
    assert listing.json()['operations'][0]['request_id'] == rid
    assert len(calls) == 1
    await client.delete(f'/api/mentor/sessions/{sid}', headers=mentor)
    deleted = (await client.get(f'/api/mentor/operations/{rid}')).json()
    assert deleted['state'] == 'cancelled' and deleted['user_text'] is None and deleted['response'] is None


@pytest.mark.asyncio
async def test_lost_tts_response_is_unavailable_and_retry_never_rebills(client, mentor, monkeypatch):
    from app.mentor import service
    async def reply(*args, **kwargs):
        return {'text': 'Assistant speech', 'proposal': None, 'tokens': 5}
    debits = []
    async def speak(*args, **kwargs):
        debits.append(1)
        return b'fake-audio'
    monkeypatch.setattr(service, 'openai_reply', reply)
    monkeypatch.setattr(service, 'speak', speak)
    sid = await enable_chat(client, mentor)
    await client.put('/api/mentor/keys/elevenlabs', json={'key': 'test-eleven-key'}, headers=mentor)
    msg = (await client.post(f'/api/mentor/sessions/{sid}/messages',
        json={'request_id': str(uuid4()), 'text': 'Plan'}, headers=mentor)).json()
    rid = str(uuid4())
    path = f'/api/mentor/messages/{msg["id"]}/tts'
    assert (await client.post(path, json={'request_id': rid}, headers=mentor)).status_code == 200
    replay = await client.post(path, json={'request_id': rid}, headers=mentor)
    assert replay.status_code == 409 and replay.json()['code'] == 'result_unavailable'
    operations = (await client.get('/api/mentor/operations', params={
        'subject_id': msg['id'], 'kind': 'tts'})).json()['operations']
    assert len(operations) == 1 and operations[0]['subject_id'] == msg['id']
    assert operations[0]['response'] is None and operations[0]['user_text'] is None
    assert len(debits) == 1
    # Only a separately confirmed new logical generation uses a new request id.
    assert (await client.post(path, json={'request_id': str(uuid4())}, headers=mentor)).status_code == 200
    assert len(debits) == 2


@pytest.mark.asyncio
async def test_operation_pending_and_failed_codes_are_distinguishable(client, mentor, monkeypatch):
    from app.mentor import service
    entered, release = asyncio.Event(), asyncio.Event()
    async def waiting(*args, **kwargs):
        entered.set()
        await release.wait()
        raise TimeoutError()
    monkeypatch.setattr(service, 'openai_reply', waiting)
    sid = await enable_chat(client, mentor)
    rid = str(uuid4())
    body = {'request_id': rid, 'text': 'Plan'}
    path = f'/api/mentor/sessions/{sid}/messages'
    task = asyncio.create_task(client.post(path, json=body, headers=mentor))
    await asyncio.wait_for(entered.wait(), 5)
    assert (await client.get(f'/api/mentor/operations/{rid}')).json()['state'] == 'reserved'
    assert (await client.post(path, json=body, headers=mentor)).json()['code'] == 'operation_pending'
    release.set()
    assert (await task).status_code == 502
    assert (await client.get(f'/api/mentor/operations/{rid}')).json()['state'] == 'failed'
    assert (await client.post(path, json=body, headers=mentor)).json()['code'] == 'operation_failed'


@pytest.mark.asyncio
async def test_operation_lookup_is_authenticated_and_user_scoped(client, mentor, monkeypatch, session):
    from app.identity.models import User
    from app.identity.service import issue_session
    from app.mentor import service
    async def reply(*args, **kwargs):
        return {'text': 'Private response', 'proposal': None, 'tokens': 5}
    monkeypatch.setattr(service, 'openai_reply', reply)
    sid = await enable_chat(client, mentor)
    rid = str(uuid4())
    await client.post(f'/api/mentor/sessions/{sid}/messages', json={'request_id': rid, 'text': 'Private'}, headers=mentor)
    other = User(email=f'{uuid4()}@example.com', password_hash='unused')
    session.add(other)
    await session.commit()
    issued = await issue_session(session, other)
    client.cookies.set('fit_session', issued.session_token)
    assert (await client.get(f'/api/mentor/operations/{rid}')).status_code == 404
    assert (await client.get('/api/mentor/operations')).json() == {'operations': []}
    client.cookies.clear()
    assert (await client.get(f'/api/mentor/operations/{rid}')).status_code == 401
