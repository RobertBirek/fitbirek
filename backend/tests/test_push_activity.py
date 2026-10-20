from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4, uuid5
from copy import deepcopy

import pytest
from sqlalchemy import select

from test_push_subscriptions import owner, payload
from test_push_delivery import enable

pytestmark = pytest.mark.asyncio


def moved_override(entry, target, *, wall='00:00', lead=30):
    original = '2026-10-20'
    snapshot = {k: v for k, v in entry.items()
                if k not in ('kind', 'id', 'name', 'createdAtUtc', 'updatedAtUtc')}
    snapshot.update(time=wall, reminderMinutesBefore=lead, effectiveFromDate='0001-01-01')
    return dict(id=str(uuid5(UUID(entry['id']), original)), name=entry['name'], kind='activityOverride',
                ruleId=entry['id'], originalDate=original, movedDate=target, state='planned',
                ruleSnapshot=snapshot, createdAtUtc=entry['createdAtUtc'], updatedAtUtc=entry['updatedAtUtc'])


@pytest.mark.parametrize('target', ['0001-01-01', '0001-01-02', '9999-12-30', '9999-12-31'])
@pytest.mark.parametrize('lead', [0, 30, 1440])
async def test_boundary_override_isolated_without_losing_marker_or_valid_rule(target, lead):
    from types import SimpleNamespace
    from app.push.activity_schedule import events, validate
    profile_id = uuid4()
    bad = rule(id=str(uuid5(profile_id, 'FitBirek/activity/legacyKarate')))
    good = rule(name='Independent')
    raw = {'version': 1, 'entries': [bad, moved_override(bad, target, lead=lead), good]}
    validate(raw)  # These are valid calendar dates, not corrupt JSON to quarantine.
    suppressed, due = events(SimpleNamespace(entity_id=profile_id, payload={'weeklySchedule': raw}),
                             datetime(2026, 10, 19, 16, tzinfo=timezone.utc))
    assert suppressed == {'karate'}
    assert sorted(e['title'] for e in due) == ['Basen', 'Independent']


@pytest.mark.parametrize('now', [datetime(1, 1, 1, 12, tzinfo=timezone.utc),
                                 datetime(9999, 12, 31, 12, tzinfo=timezone.utc)])
async def test_representable_boundary_clock_clips_candidate_days(now):
    from types import SimpleNamespace
    from app.push.activity_schedule import events, WARSAW
    local = now.astimezone(WARSAW)
    entry = rule(time=f'{local.hour:02}:{local.minute:02}', effectiveFromDate='0001-01-01')
    record = SimpleNamespace(entity_id=uuid4(), payload={'weeklySchedule': {'version': 1, 'entries': [entry]}})
    assert len(events(record, now)[1]) == 1


@pytest.mark.parametrize('lead', [30, 1440])
async def test_lead_from_lower_boundary_crosses_previous_calendar_day_safely(lead):
    from types import SimpleNamespace
    from app.push.activity_schedule import events, WARSAW
    # 0001 Warsaw has a historical +01:24 offset, not modern CET.
    start = datetime(1, 1, 2, 12, tzinfo=WARSAW)
    now = start.astimezone(timezone.utc) - timedelta(minutes=lead)
    entry = rule(time='12:00', reminderMinutesBefore=lead, effectiveFromDate='0001-01-01')
    record = SimpleNamespace(entity_id=uuid4(), payload={'weeklySchedule': {'version': 1, 'entries': [entry]}})
    assert len(events(record, now)[1]) == 1


async def test_one_users_boundary_override_cannot_abort_schedule_or_delivery_of_other_user(client, owner, session, monkeypatch):
    import httpx
    from zoneinfo import ZoneInfo
    from app.identity.models import User, Session
    from app.sync.models import SyncRecord
    from app.push.models import PushSubscription, PushDelivery
    from app.push.queue import schedule, deliver_one
    now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    entry = rule(time=now.astimezone(ZoneInfo('Europe/Warsaw')).strftime('%H:%M'))
    record = await setup_profile(client, owner, session, monkeypatch, [entry])
    entry['id'] = str(uuid5(record.entity_id, 'FitBirek/activity/legacyKarate'))
    record.payload = {'weeklySchedule': {'version': 1, 'entries': [deepcopy(entry)]}}
    sub = await session.scalar(select(PushSubscription))
    sub.categories = dict(karate=True, training=False, mood=False, operations=False)
    other = User(email='boundary-push@example.com', password_hash='unused')
    session.add(other)
    await session.flush()
    login = Session(user_id=other.id, token_hash=str(uuid4()), csrf_hash=str(uuid4()), expires_at=now+timedelta(days=1))
    session.add(login)
    await session.flush()
    installation = uuid4()
    session.add(PushSubscription(installation_id=installation, user_id=other.id, session_id=login.id,
        endpoint='https://web.push.apple.com/boundary', endpoint_hash=str(uuid4()), p256dh=sub.p256dh,
        auth=sub.auth, vapid_public_key=sub.vapid_public_key, categories=dict(sub.categories)))
    session.add(SyncRecord(user_id=other.id, entity_type='profile', entity_id=uuid4(), version=1,
        payload={'weeklySchedule': {'version': 1, 'entries': [rule(name='Independent', time=entry['time'])]}}, updated_at=now))
    await session.commit()
    await schedule(session, now)
    assert len(list(await session.scalars(select(PushDelivery)))) == 2
    entry['time'] = (now + timedelta(hours=1)).astimezone(ZoneInfo('Europe/Warsaw')).strftime('%H:%M')
    record.payload = {'weeklySchedule': {'version': 1, 'entries': [entry, moved_override(entry, '0001-01-01')]}}
    await session.commit()
    before = deepcopy(record.payload)
    await schedule(session, now)
    calls = []
    def provider(request):
        calls.append(request)
        return httpx.Response(201)
    async with httpx.AsyncClient(transport=httpx.MockTransport(provider)) as http:
        async def send(subscription, message, ttl):
            assert subscription.user_id == other.id
            return (await http.post('https://push.invalid', json=message)).status_code
        for _ in range(2):
            assert await deliver_one(session, send)
    jobs = list(await session.scalars(select(PushDelivery)))
    assert sorted(j.state for j in jobs) == ['cancelled', 'sent']
    assert len(calls) == 1
    assert all(not j.event_key.startswith('karate:') for j in jobs)
    await session.refresh(record)
    assert record.payload == before


def rule(**changes):
    entry = dict(id=str(uuid4()), name='Basen', kind='activityRule',
                createdAtUtc='2026-01-01T00:00:00.000Z', updatedAtUtc='2026-01-01T00:00:00.000Z',
                activityType='external', weekdays=[1, 2, 3, 4, 5, 6, 7], time='18:00',
                timeZone='Europe/Warsaw', effectiveFromDate='2026-01-01', enabled=True,
                reminderEnabled=True, reminderMinutesBefore=0)
    entry.update(changes)
    return entry


async def setup_profile(client, owner, session, monkeypatch, entries):
    from app.push.models import PushSubscription
    from app.sync.models import SyncRecord
    await enable(monkeypatch, session)
    body = payload()
    body['categories'] = dict(karate=True, training=True, mood=False, operations=False)
    await client.put(f'/api/push/subscriptions/{uuid4()}', json=body, headers=owner[1])
    sub = await session.scalar(select(PushSubscription))
    record = SyncRecord(user_id=sub.user_id, entity_type='profile', entity_id=uuid4(), version=1,
                        payload={'weeklySchedule': {'version': 1, 'entries': deepcopy(entries)}},
                        updated_at=datetime.now(timezone.utc))
    session.add(record)
    await session.commit()
    return record


async def test_two_dynamic_rules_same_day_dedup_and_ttl(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery
    from app.push.queue import schedule
    await setup_profile(client, owner, session, monkeypatch, [rule(), rule()])
    now = datetime(2026, 10, 19, 16, 0, tzinfo=timezone.utc)
    await schedule(session, now)
    await schedule(session, now + timedelta(minutes=1))
    jobs = list(await session.scalars(select(PushDelivery).where(PushDelivery.category == 'karate')))
    assert len(jobs) == 2
    assert len({j.event_key for j in jobs}) == 2
    assert all(j.payload['title'] == 'Basen' and j.payload['body'] == '18:00 · Europe/Warsaw' for j in jobs)
    assert all(j.expires_at == now + timedelta(minutes=15) for j in jobs)


async def test_marker_tombstone_suppresses_only_corresponding_legacy(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery
    from app.push.queue import schedule
    entry = rule()
    record = await setup_profile(client, owner, session, monkeypatch, [entry])
    entry['id'] = str(uuid5(record.entity_id, 'FitBirek/activity/legacyKarate'))
    entry['deletedAtUtc'] = entry['updatedAtUtc']
    record.payload = {'weeklySchedule': {'version': 1, 'entries': [entry]}}
    await session.commit()
    await schedule(session, datetime(2026, 10, 20, 17, 30, tzinfo=timezone.utc))
    assert list(await session.scalars(select(PushDelivery))) == []


@pytest.mark.parametrize('change', [{'enabled': False}, {'reminderEnabled': False}, {'time': '11:11'},
                                    {'updatedAtUtc': '2026-10-19T12:01:01.000Z'},
                                    {'deletedAtUtc': '2026-01-01T00:00:00.000Z'}])
async def test_queued_dynamic_revalidated_before_send(client, owner, session, monkeypatch, change):
    from app.push.models import PushDelivery
    from app.push.queue import schedule, deliver_one
    entry = rule()
    now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    from zoneinfo import ZoneInfo
    entry['time'] = now.astimezone(ZoneInfo('Europe/Warsaw')).strftime('%H:%M')
    record = await setup_profile(client, owner, session, monkeypatch, [entry])
    await schedule(session, now)
    jobs = list(await session.scalars(select(PushDelivery).where(PushDelivery.category == 'karate')))
    assert len(jobs) == 1
    entry.update(change)
    record.payload = {'weeklySchedule': {'version': 1, 'entries': [entry]}}
    await session.commit()
    async def never(*args):
        pytest.fail('stale reminder must not reach transport')
    await deliver_one(session, never)
    await session.refresh(jobs[0])
    assert jobs[0].state == 'cancelled'


@pytest.mark.parametrize('mutation', ['completed', 'moved', 'disabled_snapshot'])
async def test_override_cancels_queued_event(client, owner, session, monkeypatch, mutation):
    from zoneinfo import ZoneInfo
    from app.push.models import PushDelivery
    from app.push.queue import schedule, deliver_one
    now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    local = now.astimezone(ZoneInfo('Europe/Warsaw'))
    entry = rule(time=local.strftime('%H:%M'))
    record = await setup_profile(client, owner, session, monkeypatch, [entry])
    await schedule(session, now)
    original = local.date().isoformat()
    snapshot = {k: v for k, v in entry.items() if k not in ('kind', 'id', 'name', 'createdAtUtc', 'updatedAtUtc')}
    override = dict(id=str(uuid5(UUID(entry['id']), original)),
                    name='Basen', kind='activityOverride', ruleId=entry['id'], originalDate=original,
                    movedDate=original, state='planned', ruleSnapshot=snapshot,
                    createdAtUtc=entry['createdAtUtc'], updatedAtUtc=entry['updatedAtUtc'])
    if mutation == 'completed':
        override['state'] = 'completed'
    elif mutation == 'moved':
        override['movedDate'] = (local.date() + timedelta(days=1)).isoformat()
    else:
        snapshot['reminderEnabled'] = False
    record.payload = {'weeklySchedule': {'version': 1, 'entries': [entry, override]}}
    await session.commit()
    async def never(*args):
        pytest.fail('stale override reminder')
    await deliver_one(session, never)
    row = await session.scalar(select(PushDelivery).where(PushDelivery.category == 'karate'))
    assert row.state == 'cancelled'


@pytest.mark.parametrize('changes', [dict(time='24:00'), dict(weekdays=[True]), dict(reminderMinutesBefore=1441),
                                  dict(name='x'*81), dict(name='bad\ntext'), dict(timeZone='UTC'), dict(enabled=1),
                                  dict(effectiveFromDate='2026-02-30'), dict(activityType='unknown'), dict(kind='future')])
async def test_malformed_profile_never_sends_dynamic(client, owner, session, monkeypatch, changes):
    from app.push.models import PushDelivery
    from app.push.queue import schedule
    await setup_profile(client, owner, session, monkeypatch, [rule(**changes)])
    await schedule(session, datetime(2026, 10, 19, 16, 0, tzinfo=timezone.utc))
    assert list(await session.scalars(select(PushDelivery).where(PushDelivery.event_key.like('activity:%')))) == []


@pytest.mark.parametrize('instant,wall,lead,expected', [
    ('2026-10-19T21:45:00+00:00', '00:15', 30, 1),
    ('2027-03-28T01:30:00+00:00', '02:30', 0, 0),
    ('2026-10-25T00:30:00+00:00', '02:30', 0, 1),
    ('2026-10-25T01:30:00+00:00', '02:30', 0, 0),
])
async def test_dynamic_warsaw_dst_and_cross_midnight(instant, wall, lead, expected):
    from types import SimpleNamespace
    from app.push.activity_schedule import events
    record = SimpleNamespace(entity_id=uuid4(), payload={'weeklySchedule': {'version': 1,
        'entries': [rule(time=wall, reminderMinutesBefore=lead)]}})
    assert len(events(record, datetime.fromisoformat(instant))[1]) == expected


async def test_other_users_profile_and_category_false_never_leak(client, owner, session, monkeypatch):
    from app.push.models import PushSubscription, PushDelivery
    from app.push.queue import schedule
    record = await setup_profile(client, owner, session, monkeypatch, [rule()])
    from app.identity.models import User
    # Existing authenticated user's record becomes inaccessible when subscription
    # belongs to a different valid user, not a query supplied profile UUID.
    other = User(email='other-push@example.com', password_hash='unused')
    session.add(other)
    await session.flush()
    subscription = await session.scalar(select(PushSubscription))
    subscription.user_id = other.id
    await session.commit()
    await schedule(session, datetime(2026, 10, 19, 16, 0, tzinfo=timezone.utc))
    assert list(await session.scalars(select(PushDelivery).where(PushDelivery.event_key.like('activity:%')))) == []
    subscription.user_id = record.user_id
    subscription.categories = dict(karate=False, training=False, mood=False, operations=False)
    await session.commit()
    await schedule(session, datetime(2026, 10, 19, 16, 0, tzinfo=timezone.utc))
    assert list(await session.scalars(select(PushDelivery).where(PushDelivery.event_key.like('activity:%')))) == []


async def test_dynamic_delivery_uses_mock_http_transport(client, owner, session, monkeypatch):
    import httpx
    from zoneinfo import ZoneInfo
    from app.push.queue import schedule, deliver_one
    from app.push.models import PushDelivery
    now = datetime.now(timezone.utc).replace(second=0, microsecond=0)
    await setup_profile(client, owner, session, monkeypatch,
                        [rule(time=now.astimezone(ZoneInfo('Europe/Warsaw')).strftime('%H:%M'))])
    await schedule(session, now)
    requests = []
    def provider(request):
        requests.append(request)
        assert request.url.host == 'push.invalid'
        assert 0 < int(request.headers['TTL']) <= 900
        return httpx.Response(201)
    async with httpx.AsyncClient(transport=httpx.MockTransport(provider)) as http:
        async def send(subscription, message, ttl):
            assert message['title'] == 'Basen'
            return (await http.post('https://push.invalid/send', json=message, headers={'TTL': str(ttl)})).status_code
        await deliver_one(session, send)
    assert len(requests) == 1
    row = await session.scalar(select(PushDelivery).where(PushDelivery.category == 'karate'))
    assert row.state == 'sent'
