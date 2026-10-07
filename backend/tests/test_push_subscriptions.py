import asyncio
import base64
from uuid import uuid4

import pytest
import pytest_asyncio
from argon2 import PasswordHasher
from sqlalchemy import func, select

from app.identity.models import User


pytestmark = pytest.mark.asyncio
hash_password = PasswordHasher().hash

# The standard P-256 generator, encoded as an uncompressed public key.
PUBLIC_KEY = base64.urlsafe_b64encode(bytes.fromhex(
    '046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296'
    '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5'
)).decode().rstrip('=')


def payload(endpoint='https://fcm.googleapis.com/fcm/send/test-token'):
    return {
        'endpoint': endpoint,
        'keys': {'p256dh': PUBLIC_KEY, 'auth': 'AAAAAAAAAAAAAAAAAAAAAA'},
        'vapidPublicKey': PUBLIC_KEY,
        'categories': {'karate': True, 'training': False, 'mood': True, 'operations': False},
    }


@pytest_asyncio.fixture
async def owner(client, session):
    user = User(email=f'push-{uuid4()}@example.com', password_hash=hash_password('password'))
    session.add(user)
    await session.commit()
    response = await client.post('/api/auth/login', json={'email': user.email, 'password': 'password'})
    assert response.status_code == 204
    return user, {'Origin': 'https://fit.birek.online', 'X-CSRF-Token': response.cookies['fit_csrf']}


async def test_registry_requires_authentication(client):
    path = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.get(path)).status_code == 401
    assert (await client.put(path, json=payload())).status_code == 401
    assert (await client.delete(path)).status_code == 401


async def test_registry_requires_csrf_and_exact_origin(client, owner):
    _, headers = owner
    path = f'/api/push/subscriptions/{uuid4()}'
    for invalid in ({}, headers | {'Origin': 'https://evil.example'}, headers | {'X-CSRF-Token': 'wrong'}):
        assert (await client.put(path, json=payload(), headers=invalid)).status_code == 403
        assert (await client.delete(path, headers=invalid)).status_code == 403


async def test_registry_upsert_status_and_delete(client, owner, session):
    from app.push.models import PushSubscription

    user, headers = owner
    installation = uuid4()
    path = f'/api/push/subscriptions/{installation}'
    assert (await client.get(path)).status_code == 404
    assert (await client.put(path, json=payload(), headers=headers)).status_code == 204
    changed = payload('https://web.push.apple.com/new-token')
    changed['categories']['training'] = True
    assert (await client.put(path, json=changed, headers=headers)).status_code == 204
    response = await client.get(path)
    assert response.status_code == 200
    assert response.headers['cache-control'] == 'no-store'
    assert response.json() == {'installationId': str(installation), 'categories': changed['categories']}
    assert 'endpoint' not in response.text and PUBLIC_KEY not in response.text
    assert await session.scalar(select(func.count()).select_from(PushSubscription)) == 1
    stored = await session.scalar(select(PushSubscription))
    assert stored.user_id == user.id and stored.endpoint == changed['endpoint']
    for _ in range(2):
        assert (await client.delete(path, headers=headers)).status_code == 204
    assert (await client.get(path)).status_code == 404


@pytest.mark.parametrize('endpoint', [
    'http://fcm.googleapis.com/token', 'https://127.0.0.1/token',
    'https://[::1]/token', 'https://169.254.169.254/latest/meta-data',
    'https://fcm.googleapis.com.evil.example/token', 'https://evilfcm.googleapis.com/token',
    'https://fcm.googleapis.com@localhost/token', 'https://user@fcm.googleapis.com/token',
    'https://fcm.googleapis.com:444/token', 'https://fcm.googleapis.com./token',
    'https://fcm.googleapis.com/token#fragment', 'https://fcm.googleapis.com/',
    'https://fcm.googleapis.com/\nsecret', 'https://fcm.googleapis.com\\@localhost/token',
    'https://fcm.googleapis.com/%0d%0aheader',
])
async def test_registry_rejects_untrusted_endpoints(client, owner, endpoint):
    response = await client.put(f'/api/push/subscriptions/{uuid4()}', json=payload(endpoint), headers=owner[1])
    assert response.status_code == 422
    assert endpoint not in response.text


@pytest.mark.parametrize('host', ['fcm.googleapis.com', 'updates.push.services.mozilla.com', 'web.push.apple.com'])
async def test_registry_accepts_known_providers(client, owner, host):
    assert (await client.put(f'/api/push/subscriptions/{uuid4()}', json=payload(f'https://{host}/token'), headers=owner[1])).status_code == 204


@pytest.mark.parametrize('changes', [
    {'keys': {'p256dh': PUBLIC_KEY, 'auth': 'bad'}},
    {'keys': {'p256dh': 'A' * 87, 'auth': 'AAAAAAAAAAAAAAAAAAAAAA'}},
    {'categories': {'karate': 'true'}},
    {'categories': {'unknown': True}},
    {'userId': str(uuid4())},
])
async def test_registry_rejects_malformed_keys_and_preferences(client, owner, changes):
    response = await client.put(f'/api/push/subscriptions/{uuid4()}', json=payload() | changes, headers=owner[1])
    assert response.status_code == 422


async def test_categories_default_to_opted_out(client, owner):
    body = payload()
    del body['categories']
    path = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.put(path, json=body, headers=owner[1])).status_code == 204
    assert not any((await client.get(path)).json()['categories'].values())


async def test_other_account_cannot_read_replace_or_delete_installation(client, owner, session):
    path = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.put(path, json=payload(), headers=owner[1])).status_code == 204
    other = User(email='other@example.com', password_hash=hash_password('password'))
    session.add(other)
    await session.commit()
    response = await client.post('/api/auth/login', json={'email': other.email, 'password': 'password'})
    headers = owner[1] | {'X-CSRF-Token': response.cookies['fit_csrf']}
    assert (await client.get(path)).status_code == 404
    assert (await client.put(path, json=payload(), headers=headers)).status_code == 409
    assert (await client.delete(path, headers=headers)).status_code == 204
    assert (await client.put(f'/api/push/subscriptions/{uuid4()}', json=payload(), headers=headers)).status_code == 409


async def test_logout_deletes_only_subscriptions_bound_to_current_session(client, owner, session):
    from app.push.models import PushSubscription

    path = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.put(path, json=payload(), headers=owner[1])).status_code == 204
    second = await client.post('/api/auth/login', json={'email': owner[0].email, 'password': 'password'})
    headers = owner[1] | {'X-CSRF-Token': second.cookies['fit_csrf']}
    second_path = f'/api/push/subscriptions/{uuid4()}'
    assert (await client.put(second_path, json=payload('https://web.push.apple.com/second'), headers=headers)).status_code == 204
    assert (await client.post('/api/auth/logout', headers=headers)).status_code == 204
    assert await session.scalar(select(func.count()).select_from(PushSubscription)) == 1


async def test_registry_limits_installations_per_account(client, owner):
    for index in range(10):
        body = payload(f'https://fcm.googleapis.com/token-{index}')
        assert (await client.put(f'/api/push/subscriptions/{uuid4()}', json=body, headers=owner[1])).status_code == 204
    response = await client.put(f'/api/push/subscriptions/{uuid4()}', json=payload(), headers=owner[1])
    assert response.status_code == 409


async def test_push_status_is_disabled_without_vapid(client, owner):
    response = await client.get('/api/push/status')
    assert response.status_code == 200
    assert response.json() == {'deliveryAvailable': False, 'reason': 'disabled', 'publicKey': None}


async def test_concurrent_registrations_cannot_bypass_installation_limit(client, owner):
    responses = await asyncio.gather(*(
        client.put(f'/api/push/subscriptions/{uuid4()}',
                   json=payload(f'https://fcm.googleapis.com/concurrent-{index}'), headers=owner[1])
        for index in range(12)
    ))
    assert sorted(response.status_code for response in responses) == [204] * 10 + [409] * 2


async def test_concurrent_logout_and_registration_leave_no_subscription(client, owner, session):
    from app.push.models import PushSubscription

    responses = await asyncio.gather(
        client.put(f'/api/push/subscriptions/{uuid4()}', json=payload(), headers=owner[1]),
        client.post('/api/auth/logout', headers=owner[1]),
    )
    assert responses[0].status_code in (204, 401)
    assert responses[1].status_code == 204
    assert await session.scalar(select(func.count()).select_from(PushSubscription)) == 0
