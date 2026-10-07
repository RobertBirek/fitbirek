import asyncio
import base64
import json
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import http_ece
import pytest
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from sqlalchemy import func, select

from test_push_subscriptions import owner, payload, PUBLIC_KEY

pytestmark = pytest.mark.asyncio


async def test_test_push_is_disabled_and_requires_csrf(client, owner):
    path = f'/api/push/subscriptions/{uuid4()}/test'
    assert (await client.post(path)).status_code == 403
    assert (await client.post(path, headers=owner[1])).status_code == 503


async def enable(monkeypatch, session):
    from app.config import settings
    from app.push.models import PushSenderState
    monkeypatch.setattr(settings, 'push_enabled', True)
    monkeypatch.setattr(settings, 'push_vapid_public_key', PUBLIC_KEY)
    session.add(PushSenderState(id=1, public_key=PUBLIC_KEY, heartbeat_at=datetime.now(timezone.utc)))
    await session.commit()


async def test_test_push_rate_limit_is_durable_per_user_and_concurrent(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.put(path, json=payload(), headers=owner[1])).status_code == 204
    responses = await asyncio.gather(*(client.post(path + '/test', headers=owner[1]) for _ in range(6)))
    assert sorted(r.status_code for r in responses) == [202] + [429] * 5
    assert await session.scalar(select(func.count()).select_from(PushDelivery)) == 1
    other = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.put(other, json=payload('https://web.push.apple.com/other'), headers=owner[1])).status_code == 204
    assert (await client.post(other + '/test', headers=owner[1])).status_code == 429


async def test_scheduler_warsaw_dedup_and_no_stale_catchup(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery
    from app.push.queue import schedule
    await enable(monkeypatch, session)
    body = payload()
    body['categories'] = dict(karate=True, training=True, mood=True, operations=False)
    assert (await client.put(f'/api/push/subscriptions/{uuid4()}', json=body, headers=owner[1])).status_code == 204
    # Thursday, CEST: 17:30 UTC = 19:30 Warsaw.
    now = datetime(2026, 9, 10, 17, 30, tzinfo=timezone.utc)
    await schedule(session, now)
    await schedule(session, now + timedelta(minutes=1))
    assert await session.scalar(select(func.count()).select_from(PushDelivery)) == 1
    row = await session.scalar(select(PushDelivery))
    assert row.category == 'karate'
    await schedule(session, now + timedelta(minutes=40))
    assert await session.scalar(select(func.count()).select_from(PushDelivery)) == 1


async def test_two_schedulers_share_a_durable_event_key(client, owner, session, monkeypatch):
    from sqlalchemy.ext.asyncio import async_sessionmaker
    from app.push.models import PushDelivery
    from app.push.queue import schedule
    await enable(monkeypatch, session)
    await client.put(f'/api/push/subscriptions/{uuid4()}', json=payload(), headers=owner[1])
    factory = async_sessionmaker(session.bind, expire_on_commit=False)
    now = datetime(2026, 9, 10, 17, 30, tzinfo=timezone.utc)
    async with factory() as first, factory() as second:
        await asyncio.gather(schedule(first, now), schedule(second, now))
    assert await session.scalar(select(func.count()).select_from(PushDelivery)) == 1


async def test_rotated_subscription_cannot_queue_a_misleading_test(client, owner, session, monkeypatch):
    from app.config import settings
    from app.push.models import PushSenderState, PushTestLimit
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    await client.put(path, json=payload(), headers=owner[1])
    new_key = PUBLIC_KEY[:-1] + 'A'
    monkeypatch.setattr(settings, 'push_vapid_public_key', new_key)
    heartbeat = await session.get(PushSenderState, 1)
    heartbeat.public_key = new_key
    await session.commit()
    assert (await client.post(path + '/test', headers=owner[1])).status_code == 409
    assert await session.scalar(select(func.count()).select_from(PushTestLimit)) == 0


@pytest.mark.parametrize('utc_hour,date', [(17, (2026, 3, 28)), (16, (2026, 3, 29)), (16, (2026, 10, 24)), (17, (2026, 10, 25))])
async def test_schedule_tracks_dst(utc_hour, date):
    from app.push.queue import due_events
    events = due_events(datetime(*date, utc_hour, 0, tzinfo=timezone.utc))
    assert [event[0] for event in events] == ['training']


@pytest.mark.parametrize('code,state', [(201, 'sent'), (429, 'pending'), (503, 'pending'), (403, 'failed'), (302, 'failed')])
async def test_delivery_outcomes_retry_and_recheck_optin(client, owner, session, monkeypatch, code, state):
    from app.push.models import PushDelivery
    from app.push.queue import deliver_one
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    await client.put(path, json=payload(), headers=owner[1])
    await client.post(path + '/test', headers=owner[1])
    calls = []
    async def send(subscription, message, ttl):
        calls.append((message, ttl))
        return code
    assert await deliver_one(session, send)
    row = await session.scalar(select(PushDelivery))
    assert row.state == state and row.attempts == 1
    assert len(calls) == 1 and 0 < calls[0][1] <= 300
    assert not await deliver_one(session, send)


@pytest.mark.parametrize('code', [404, 410])
async def test_gone_subscription_is_deleted(client, owner, session, monkeypatch, code):
    from app.push.models import PushSubscription, PushDelivery
    from app.push.queue import deliver_one
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    await client.put(path, json=payload(), headers=owner[1])
    await client.post(path + '/test', headers=owner[1])
    async def send(*args):
        return code
    await deliver_one(session, send)
    assert await session.scalar(select(func.count()).select_from(PushSubscription)) == 0
    assert await session.scalar(select(func.count()).select_from(PushDelivery)) == 0


async def test_expired_and_disabled_jobs_are_not_sent(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery
    from app.push.queue import deliver_one
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    await client.put(path, json=payload(), headers=owner[1])
    await client.post(path + '/test', headers=owner[1])
    row = await session.scalar(select(PushDelivery))
    row.expires_at = datetime.now(timezone.utc) - timedelta(seconds=1)
    await session.commit()
    async def never(*args):
        pytest.fail('must not send expired push')
    await deliver_one(session, never)
    await session.refresh(row)
    assert row.state == 'expired'


async def test_encrypted_payload_can_be_decrypted_by_browser_key():
    from app.push.transport import encrypt_payload
    private = ec.generate_private_key(ec.SECP256R1())
    public = private.public_key().public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)
    key = base64.urlsafe_b64encode(public).decode().rstrip('=')
    encrypted = encrypt_payload(key, 'AAAAAAAAAAAAAAAAAAAAAA', {'category': 'mood'})
    plain = http_ece.decrypt(encrypted, private_key=private, auth_secret=bytes(16), version='aes128gcm')
    assert json.loads(plain) == {'category': 'mood'}


@pytest.mark.parametrize('ip', ['127.0.0.1', '10.0.0.1', '169.254.169.254', '::1', 'fc00::1', '::ffff:127.0.0.1', '2002:7f00:1::', 'fec0::1', '64:ff9b::a00:1'])
async def test_transport_refuses_non_public_dns_answers(ip):
    from app.push.transport import validate_addresses
    with pytest.raises(ValueError):
        validate_addresses(['142.250.1.1', ip])
