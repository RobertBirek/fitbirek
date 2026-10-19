import copy
import json
from uuid import uuid4

import httpx
import pytest
from fastapi import HTTPException
from sqlalchemy import func, select

from test_mentor import mentor, enable_chat


def proposal():
    from app.mentor.templates import candidate_pool
    entry = candidate_pool('Poranne rozciąganie ogólne 15 min')[0]
    return {'kind': 'create_template', 'name': 'Poranne rozciąganie', 'minutes': 15,
            'exercises': [{'exercise_id': entry['id'], 'sets': 2,
                           'reps': 8 if entry['tracking'] == 'reps' else None,
                           'seconds': 30 if entry['tracking'] == 'time' else None,
                           'rest_seconds': 15, 'weight_kg': None}]}


@pytest.mark.asyncio
async def test_template_real_vendor_ledger_and_no_domain_writes(client, mentor, session, monkeypatch):
    from app.mentor import vendor
    from app.mentor.models import MentorRequest
    from app.sync.models import SyncRecord
    sid = await enable_chat(client, mentor)
    calls = []
    before = await session.scalar(select(func.count()).select_from(SyncRecord))

    async def handler(request):
        calls.append(json.loads(request.content))
        # Reservation must be durable BEFORE the actual provider transport.
        await session.rollback()
        row = await session.scalar(select(MentorRequest).where(MentorRequest.request_id == rid))
        assert row.state == 'reserved'
        return httpx.Response(200, json={'status': 'completed', 'output': [
            {'type': 'message', 'role': 'assistant', 'status': 'completed', 'content': [
                {'type': 'output_text', 'text': json.dumps({'text': 'Edytuj propozycję, nic nie zapisano.', 'proposal': proposal()})}]}],
            'usage': {'input_tokens': 10, 'output_tokens': 100}})

    monkeypatch.setattr(vendor, '_transport', httpx.MockTransport(handler))
    rid = uuid4()
    body = {'request_id': str(rid), 'text': 'Ułóż szablon: Poranne rozciąganie ogólne 15 min'}
    url = f'/api/mentor/sessions/{sid}/messages'
    first = await client.post(url, json=body, headers=mentor)
    assert first.status_code == 200, first.text
    assert first.json()['proposal']['kind'] == 'create_template'
    second = await client.post(url, json=body, headers=mentor)
    assert first.json() == second.json()
    assert len(calls) == 1
    payload = calls[0]
    assert 'mock-private-key' not in json.dumps(payload)
    assert 'CATALOG' in json.dumps(payload)
    assert payload['store'] is False
    assert await session.scalar(select(func.count()).select_from(SyncRecord)) == before


@pytest.mark.parametrize('mutation', [
    lambda p: p['exercises'][0].update(exercise_id='cw999999'),
    lambda p: p['exercises'][0].update(exercise_id='cw001'),  # Known, outside stretching pool.
    lambda p: p['exercises'][0].update(sets=True),
    lambda p: p['exercises'][0].update(sets=2**62),
    lambda p: p['exercises'][0].update(weight_kg=float('inf')),
    lambda p: p['exercises'][0].update(weight_kg=2**1024),
    lambda p: p['exercises'][0].update(rest_seconds=-1),
    lambda p: p.update(minutes=91),
    lambda p: p.update(exercises=p['exercises'] * 11),
    lambda p: p.update(name='x' * 121),
    lambda p: p.update(name=' ' * 121 + 'ok'),
    lambda p: p.update(health='private'),
    lambda p: p['exercises'][0].update(seconds=5400, sets=10),
])
def test_template_validation_rejects_untrusted_values(mutation):
    from app.mentor.templates import validate_template
    p = copy.deepcopy(proposal())
    mutation(p)
    with pytest.raises(HTTPException):
        validate_template(p, 'Poranne rozciąganie ogólne 15 min')


def test_catalog_is_reproducible_and_pool_is_bounded():
    from app.mentor.templates import candidate_pool, CATALOG
    from pathlib import Path
    source = json.loads((Path(__file__).parents[2] / 'assets/data/exercises.json').read_text())
    assert set(CATALOG) == {e['id'] for e in source}
    pool = candidate_pool('Poranne rozciąganie ogólne 15 min')
    assert 1 <= len(pool) <= 10
    assert all('rozciągan' in e['type'].lower() for e in pool)
    from app.mentor.templates import catalog_message
    projected = catalog_message('Poranne rozciąganie 15 min PRIVATE-HEALTH sk-private-key')
    assert 'PRIVATE' not in projected and 'sk-private-key' not in projected
    assert len(projected.encode()) < 2000
    import subprocess
    import sys
    subprocess.run([sys.executable, str(Path(__file__).parents[1] / 'tools/generate_mentor_catalog.py'), '--check'], check=True)


def test_template_contract_is_opt_in_and_preserves_normal_context_budget():
    from app.mentor.templates import template_requested, catalog_message
    from app.mentor.vendor import _contract
    assert template_requested('Poranne rozciąganie ogólne15min')
    assert template_requested('Ułóż szablon całego ciała')
    assert not template_requested('Ułóż spokojny plan.')
    normal = [{'role': 'user', 'content': 'Ułóż spokojny plan.'}]
    instructions, schema = _contract(normal)
    assert 'create_template' not in json.dumps(schema)
    assert 'create_template' not in instructions
    template = [{'role': 'developer', 'content': catalog_message('rozciąganie 15min')}, *normal]
    instructions, schema = _contract(template)
    assert 'create_template' in json.dumps(schema) and 'create_template' in instructions


@pytest.mark.asyncio
@pytest.mark.parametrize('bad', ['unknown_id', 'too_large', 'invalid_schema'])
async def test_invalid_vendor_templates_fail_once_without_domain_writes(client, mentor, session, monkeypatch, bad):
    from app.mentor import vendor
    from app.mentor.models import MentorRequest
    from app.sync.models import SyncRecord
    sid = await enable_chat(client, mentor)
    p = proposal()
    if bad == 'unknown_id':
        p['exercises'][0]['exercise_id'] = 'cw999'
    elif bad == 'too_large':
        p['exercises'] *= 11
    else:
        p['exercises'][0]['sets'] = '2'
    calls = []
    def handler(request):
        calls.append(request)
        return httpx.Response(200, json={'status': 'completed', 'output': [
            {'type': 'message', 'role': 'assistant', 'status': 'completed', 'content': [
                {'type': 'output_text', 'text': json.dumps({'text': 'Propozycja', 'proposal': p})}]}],
            'usage': {'input_tokens': 10, 'output_tokens': 100}})
    monkeypatch.setattr(vendor, '_transport', httpx.MockTransport(handler))
    rid = uuid4()
    body = {'request_id': str(rid), 'text': 'Poranne rozciąganie ogólne 15 min'}
    url = f'/api/mentor/sessions/{sid}/messages'
    assert (await client.post(url, json=body, headers=mentor)).status_code == 502
    assert (await client.post(url, json=body, headers=mentor)).status_code == 409
    assert len(calls) == 1
    await session.rollback()
    row = await session.scalar(select(MentorRequest).where(MentorRequest.request_id == rid))
    assert row.state == 'failed'
    from app.mentor.models import MentorUsage
    usage = await session.scalar(select(MentorUsage).where(MentorUsage.user_id == row.user_id))
    assert usage.output_tokens > 0  # Bad output does not refund the reservation.
    assert await session.scalar(select(func.count()).select_from(SyncRecord)) == 0
