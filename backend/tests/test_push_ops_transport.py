import asyncio
import base64
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from uuid import uuid4

import pytest
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.serialization import Encoding, NoEncryption, PrivateFormat, PublicFormat
from py_vapid import Vapid02
from sqlalchemy import func, select

from test_push_subscriptions import owner, payload
from test_push_delivery import enable

pytestmark = pytest.mark.asyncio


async def test_vapid_loads_only_explicit_matching_private_file(tmp_path):
    from app.push.transport import load_vapid
    key = ec.generate_private_key(ec.SECP256R1())
    path = tmp_path / 'test-only.pem'
    path.write_bytes(key.private_bytes(Encoding.PEM, PrivateFormat.PKCS8, NoEncryption()))
    public = base64.urlsafe_b64encode(key.public_key().public_bytes(Encoding.X962, PublicFormat.UncompressedPoint)).decode().rstrip('=')
    settings = SimpleNamespace(push_enabled=True, push_vapid_private_key_file=str(path),
                               push_vapid_public_key=public, push_vapid_subject='mailto:test@example.com')
    vapid = load_vapid(settings)
    auth = vapid.sign({'aud': 'https://fcm.googleapis.com', 'sub': settings.push_vapid_subject})
    assert Vapid02.verify(auth['Authorization'])
    settings.push_vapid_public_key = 'wrong'
    with pytest.raises(ValueError):
        load_vapid(settings)
    settings.push_enabled = False
    settings.push_vapid_private_key_file = str(tmp_path / 'must-not-be-created.pem')
    with pytest.raises(ValueError):
        load_vapid(settings)
    assert not (tmp_path / 'must-not-be-created.pem').exists()


async def test_transport_pins_dns_and_never_follows_redirect(monkeypatch):
    import ssl
    from app.push import transport
    loop = asyncio.get_running_loop()
    resolutions, connects, written = [], [], []
    async def resolve(host, port, **kwargs):
        resolutions.append(host)
        return [(2, 1, 6, '', ('142.250.1.1', 443))]
    async def connect(sock, address):
        connects.append(address)
    class Socket:
        def setblocking(self, value): pass
        def close(self): pass
    class Writer:
        def write(self, data): written.append(data)
        async def drain(self): pass
        def close(self): pass
        async def wait_closed(self): pass
    class Reader:
        async def readline(self): return b'HTTP/1.1 302 Found\r\n'
    async def open_connection(**kwargs):
        assert kwargs['server_hostname'] == 'fcm.googleapis.com'
        assert kwargs['ssl'].check_hostname
        assert kwargs['ssl'].verify_mode == ssl.CERT_REQUIRED
        return Reader(), Writer()
    monkeypatch.setattr(loop, 'getaddrinfo', resolve)
    monkeypatch.setattr(loop, 'sock_connect', connect)
    monkeypatch.setattr(transport.socket, 'socket', lambda *args: Socket())
    monkeypatch.setattr(transport.asyncio, 'open_connection', open_connection)
    result = await transport.post_pinned('https://fcm.googleapis.com/token', {'TTL': '60'}, b'encrypted')
    assert result == 302
    assert resolutions == ['fcm.googleapis.com']
    assert connects == [('142.250.1.1', 443)]
    assert b'Host: fcm.googleapis.com\r\n' in written[0]


@pytest.mark.parametrize('failure_phase', ['connect', 'tls', 'connect_timeout', 'tls_timeout', 'write', 'drain', 'read'])
async def test_transport_falls_back_only_before_post(monkeypatch, failure_phase):
    import ssl
    from app.push import transport
    loop = asyncio.get_running_loop()
    addresses = [('2607:f8b0:4001::1', 443, 0, 0), ('142.250.1.1', 443)]
    resolutions, connects, sockets, writes = [], [], [], []
    async def resolve(host, port, **kwargs):
        resolutions.append((host, port))
        return [(10, 1, 6, '', addresses[0]), (2, 1, 6, '', addresses[1])]
    class Socket:
        def __init__(self, *args):
            self.closed = False
            sockets.append(self)
        def setblocking(self, value): pass
        def close(self): self.closed = True
    async def connect(sock, address):
        connects.append(address)
        if failure_phase == 'connect' and len(connects) == 1:
            raise OSError('first address unreachable')
        if failure_phase == 'connect_timeout' and len(connects) == 1:
            await asyncio.Future()
    class Writer:
        def __init__(self, sock): self.sock = sock
        def write(self, data):
            writes.append(data)
            if failure_phase == 'write': raise OSError('ambiguous write')
        async def drain(self):
            if failure_phase == 'drain': raise OSError('ambiguous send')
        def close(self): self.sock.close()
        async def wait_closed(self): pass
    class Reader:
        async def readline(self):
            if failure_phase == 'read': raise OSError('response lost after POST')
            return b'HTTP/1.1 201 Created\r\n'
    async def open_connection(**kwargs):
        assert kwargs['server_hostname'] == 'fcm.googleapis.com'
        assert kwargs['ssl'].check_hostname
        assert kwargs['ssl'].verify_mode == ssl.CERT_REQUIRED
        if failure_phase == 'tls' and len(connects) == 1:
            raise ssl.SSLError('first TLS handshake failed')
        if failure_phase == 'tls_timeout' and len(connects) == 1:
            await asyncio.Future()
        return Reader(), Writer(kwargs['sock'])
    monkeypatch.setattr(loop, 'getaddrinfo', resolve)
    monkeypatch.setattr(loop, 'sock_connect', connect)
    monkeypatch.setattr(transport.socket, 'socket', Socket)
    monkeypatch.setattr(transport.asyncio, 'open_connection', open_connection)
    monkeypatch.setattr(transport, 'CONNECT_TIMEOUT_SECONDS', 0.02)
    if failure_phase in ('connect', 'tls', 'connect_timeout', 'tls_timeout'):
        assert await transport.post_pinned('https://fcm.googleapis.com/token', {'TTL': '60'}, b'encrypted') == 201
        assert connects == addresses
    else:
        with pytest.raises(OSError):
            await transport.post_pinned('https://fcm.googleapis.com/token', {'TTL': '60'}, b'encrypted')
        assert connects == addresses[:1]
    assert resolutions == [('fcm.googleapis.com', 443)]
    assert len(writes) == 1
    assert all(sock.closed for sock in sockets)


async def test_transport_total_deadline_includes_all_connection_attempts(monkeypatch):
    import ssl
    from app.push import transport
    loop = asyncio.get_running_loop()
    context = ssl.create_default_context()
    connects, sockets = [], []
    async def resolve(*args, **kwargs):
        return [(2, 1, 6, '', ('142.250.1.1', 443)), (2, 1, 6, '', ('142.250.1.2', 443))]
    class Socket:
        def __init__(self, *args):
            self.closed = False
            sockets.append(self)
        def setblocking(self, value): pass
        def close(self): self.closed = True
    async def connect(sock, address):
        connects.append(address)
        if len(connects) == 1: raise OSError('unreachable')
        await asyncio.Future()  # Remaining attempts cannot extend the deadline.
    monkeypatch.setattr(loop, 'getaddrinfo', resolve)
    monkeypatch.setattr(loop, 'sock_connect', connect)
    monkeypatch.setattr(transport.socket, 'socket', Socket)
    monkeypatch.setattr(transport.ssl, 'create_default_context', lambda: context)
    monkeypatch.setattr(transport, 'TOTAL_TIMEOUT_SECONDS', 0.05, raising=False)
    started = loop.time()
    with pytest.raises(TimeoutError):
        await asyncio.wait_for(transport.post_pinned('https://fcm.googleapis.com/token', {}, b'body'), 1)
    assert loop.time() - started < 0.5
    assert len(connects) == 2
    assert all(sock.closed for sock in sockets)


async def test_ops_failure_recovery_and_observation_order_dedup(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery, PushIncident
    from app.push.ops import observe
    await enable(monkeypatch, session)
    body = payload()
    body['categories']['operations'] = True
    await client.put(f'/api/push/subscriptions/{uuid4()}', json=body, headers=owner[1])
    now = datetime.now(timezone.utc)
    for failing, offset in [(False, 0), (True, 1), (True, 2), (False, 3), (True, 1), (False, 4)]:
        await observe(session, 'api', failing, now + timedelta(seconds=offset))
        await session.commit()
    rows = list(await session.scalars(select(PushDelivery).order_by(PushDelivery.event_key)))
    assert len(rows) == 2
    assert [r.payload['recovery'] for r in rows] == [False, True]
    assert (await session.get(PushIncident, 'api')).failing is False
    from app.push.queue import deliver_one
    sent = []
    async def send(subscription, message, ttl):
        sent.append(message)
        return 201
    # Make future observations due for this delivery check.
    for row in rows:
        row.available_at = now
    await session.commit()
    while await deliver_one(session, send):
        pass
    assert len(sent) == 1 and sent[0]['recovery'] is True


async def test_delivery_concurrency_and_crash_rollback(client, owner, session, monkeypatch):
    from sqlalchemy.ext.asyncio import async_sessionmaker
    from app.push.models import PushDelivery
    from app.push.queue import deliver_one
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    await client.put(path, json=payload(), headers=owner[1])
    await client.post(path + '/test', headers=owner[1])
    factory = async_sessionmaker(session.bind, expire_on_commit=False)
    entered, release = asyncio.Event(), asyncio.Event()
    async def crash(*args):
        entered.set()
        await release.wait()
        raise RuntimeError('simulated worker crash before commit')
    async with factory() as first, factory() as second:
        work = asyncio.create_task(deliver_one(first, crash))
        await asyncio.wait_for(entered.wait(), 5)
        assert not await deliver_one(second, crash)
        release.set()
        with pytest.raises(RuntimeError):
            await work
        await first.rollback()
        async def succeed(*args): return 201
        assert await deliver_one(second, succeed)
    job = await session.scalar(select(PushDelivery))
    assert job.state == 'sent' and job.attempts == 1


async def test_category_optout_cancels_pending_reminder(client, owner, session, monkeypatch):
    from app.push.models import PushDelivery, PushSubscription
    from app.push.queue import deliver_one, enqueue
    await enable(monkeypatch, session)
    path = f'/api/push/subscriptions/{uuid4()}'
    await client.put(path, json=payload(), headers=owner[1])
    sub = await session.scalar(select(PushSubscription))
    now = datetime.now(timezone.utc)
    await enqueue(session, sub, 'karate:pending', 'karate', now, now + timedelta(minutes=5))
    await session.commit()
    changed = payload()
    changed['categories']['karate'] = False
    await client.put(path, json=changed, headers=owner[1])
    async def never(*args): pytest.fail('opted-out category was sent')
    await deliver_one(session, never)
    assert (await session.scalar(select(PushDelivery))).state == 'cancelled'


async def test_stale_sender_is_not_advertised_as_ready(client, owner, session, monkeypatch):
    from app.push.models import PushSenderState
    await enable(monkeypatch, session)
    assert (await client.get('/api/push/status')).json()['deliveryAvailable']
    heartbeat = await session.get(PushSenderState, 1)
    heartbeat.heartbeat_at -= timedelta(minutes=2)
    await session.commit()
    assert not (await client.get('/api/push/status')).json()['deliveryAvailable']
