import asyncio
from datetime import datetime, timedelta, timezone
from hashlib import sha256
from http.cookies import SimpleCookie
from email.utils import parsedate_to_datetime
from uuid import uuid4

import pytest_asyncio
import pytest
from argon2 import PasswordHasher
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.identity.models import LoginAttempt, Session, User


PASSWORD = "correct horse battery staple"
pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def account(session):
    account = User(
        email=f"account-{uuid4()}@example.com",
        password_hash=PasswordHasher().hash(PASSWORD),
    )
    session.add(account)
    await session.commit()
    return account


async def login(client, account, password=PASSWORD):
    return await client.post(
        "/api/auth/login",
        json={"email": account.email.upper(), "password": password},
    )


async def test_login_accepts_correct_password_and_sets_secure_cookies(client, account):
    response = await login(client, account)

    assert response.status_code == 204
    cookies = response.headers.get_list("set-cookie")
    assert len(cookies) == 2
    assert any("fit_session=" in cookie and "HttpOnly" in cookie for cookie in cookies)
    assert any("fit_csrf=" in cookie and "HttpOnly" not in cookie for cookie in cookies)
    assert all("Secure" in cookie and "SameSite=strict" in cookie and "Path=/" in cookie for cookie in cookies)


async def test_login_rejects_an_incorrect_password(client, account):
    response = await login(client, account, "incorrect")

    assert response.status_code == 401


async def test_cookie_expiry_matches_the_persisted_session_lifetime(client, account, session, monkeypatch):
    from app.config import settings

    monkeypatch.setattr(settings, "session_lifetime_hours", 2)
    response = await login(client, account)
    assert response.status_code == 204
    stored = await session.scalar(select(Session).where(Session.user_id == account.id))
    assert stored is not None
    for header in response.headers.get_list("set-cookie"):
        cookie = next(iter(SimpleCookie(header).values()))
        assert cookie["expires"], "Native clients need the server's absolute cookie expiry"
        assert parsedate_to_datetime(cookie["expires"]) == stored.expires_at.replace(microsecond=0)
    assert timedelta(hours=1, minutes=59) < stored.expires_at - datetime.now(timezone.utc) <= timedelta(hours=2)


async def test_login_rejects_an_invalid_argon2_hash(client, account, session):
    account.password_hash = "not-an-argon2-hash"
    await session.commit()

    response = await login(client, account)

    assert response.status_code == 401


async def test_login_persists_only_hashes_of_opaque_tokens(client, account, session):
    response = await login(client, account)

    stored_session = await session.scalar(select(Session).where(Session.user_id == account.id))

    assert stored_session is not None
    assert stored_session.token_hash != response.cookies.get("fit_session")
    assert stored_session.csrf_hash != response.cookies.get("fit_csrf")
    assert len(stored_session.token_hash) == 64
    assert len(stored_session.csrf_hash) == 64


async def test_session_restores_the_authenticated_account(client, account):
    await login(client, account)

    response = await client.get("/api/auth/session")

    assert response.status_code == 200
    assert response.json() == {"accountId": str(account.id), "email": account.email}


async def test_session_rejects_expired_credentials(client, account, session):
    token = "expired-session-token"
    session.add(
        Session(
            user_id=account.id,
            token_hash=sha256(token.encode()).hexdigest(),
            csrf_hash="e" * 64,
            expires_at=datetime.now(timezone.utc) - timedelta(seconds=1),
        )
    )
    await session.commit()

    response = await client.get("/api/auth/session", headers={"Cookie": f"fit_session={token}"})

    assert response.status_code == 401


async def test_logout_revokes_the_session_and_clears_cookies(client, account):
    login_response = await login(client, account)
    session_token = login_response.cookies.get("fit_session")

    response = await client.post(
        "/api/auth/logout",
        headers={
            "Origin": "https://fit.birek.online",
            "X-CSRF-Token": login_response.cookies.get("fit_csrf"),
        },
    )

    assert response.status_code == 204
    assert all("Max-Age=0" in cookie for cookie in response.headers.get_list("set-cookie"))
    assert (await client.get("/api/auth/session")).status_code == 401
    assert (
        await client.get("/api/auth/session", headers={"Cookie": f"fit_session={session_token}"})
    ).status_code == 401


async def test_logout_rejects_missing_csrf_protection(client, account):
    await login(client, account)

    response = await client.post("/api/auth/logout")

    assert response.status_code == 403


async def test_logout_rejects_an_untrusted_origin(client, account):
    login_response = await login(client, account)

    response = await client.post(
        "/api/auth/logout",
        headers={
            "Origin": "https://attacker.example",
            "X-CSRF-Token": login_response.cookies.get("fit_csrf"),
        },
    )

    assert response.status_code == 403


async def test_login_retries_a_duplicate_session_token(client, account, session, monkeypatch):
    from app.identity import service

    session.add(
        Session(
            user_id=account.id,
            token_hash=sha256(b"duplicate-token").hexdigest(),
            csrf_hash="e" * 64,
            expires_at=datetime.now(timezone.utc) + timedelta(days=1),
        )
    )
    await session.commit()
    generated_tokens = iter(
        ["duplicate-token", "discarded-csrf", "fresh-session-token", "fresh-csrf-token"]
    )
    monkeypatch.setattr(service, "create_token", lambda: next(generated_tokens))

    issued_session = await service.issue_session(session, account)

    assert issued_session.session_token == "fresh-session-token"
    assert issued_session.csrf_token == "fresh-csrf-token"


async def test_sync_mutation_rejects_missing_csrf_token(client, account):
    await login(client, account)

    response = await client.post("/api/sync/push", json={"operations": []})

    assert response.status_code == 403


async def test_sync_mutation_rejects_a_non_matching_csrf_token(client, account):
    await login(client, account)

    response = await client.post(
        "/api/sync/push",
        json={"operations": []},
        headers={"Origin": "https://fit.birek.online", "X-CSRF-Token": "incorrect"},
    )

    assert response.status_code == 403


async def test_sync_mutation_accepts_matching_csrf_token_from_trusted_origin(client, account):
    login_response = await login(client, account)

    response = await client.post(
        "/api/sync/push",
        json={"operations": []},
        headers={
            "Origin": "https://fit.birek.online",
            "X-CSRF-Token": login_response.cookies.get("fit_csrf"),
        },
    )

    assert response.status_code == 200
    assert response.json() == {"accepted": [], "conflicts": []}


async def test_sync_mutation_rejects_an_untrusted_origin(client, account):
    login_response = await login(client, account)

    response = await client.post(
        "/api/sync/push",
        json={"operations": []},
        headers={
            "Origin": "https://attacker.example",
            "X-CSRF-Token": login_response.cookies.get("fit_csrf"),
        },
    )

    assert response.status_code == 403


async def test_login_rate_limits_attempts_by_normalized_email_and_client_ip(client):
    payload = {"email": "RATE-LIMIT@example.com", "password": "incorrect"}

    for attempt in range(5):
        payload["email"] = "RATE-LIMIT@example.com" if attempt % 2 == 0 else "rate-limit@example.com"
        assert (await client.post("/api/auth/login", json=payload)).status_code == 401

    response = await client.post("/api/auth/login", json=payload)

    assert response.status_code == 429


async def test_successful_login_resets_failed_attempt_state(client, account):
    for _ in range(4):
        assert (await login(client, account, "incorrect")).status_code == 401

    assert (await login(client, account)).status_code == 204

    for _ in range(5):
        assert (await login(client, account, "incorrect")).status_code == 401
    assert (await login(client, account, "incorrect")).status_code == 429


@pytest.mark.parametrize("password", [PASSWORD, "incorrect"])
async def test_exhausted_login_never_verifies_password_or_sets_cookies(client, account, session, monkeypatch, password):
    from app.identity import service

    for _ in range(5):
        assert (await login(client, account, "incorrect")).status_code == 401
    verified = []
    original = service.password_is_valid

    def observe_verify(*args):
        verified.append(True)
        return original(*args)

    monkeypatch.setattr(service, "password_is_valid", observe_verify)
    response = await login(client, account, password)
    assert response.status_code == 429
    assert verified == []
    assert response.headers.get_list("set-cookie") == []
    assert await session.scalar(select(Session)) is None


async def test_login_window_expires_individual_attempts_without_extending_on_block(client, account, session, monkeypatch):
    from app.identity import service
    from app.security import rate_limit

    now = datetime.now(timezone.utc)

    async def controlled_now(_database):
        return now

    monkeypatch.setattr(rate_limit, "database_now", controlled_now)
    for minute in range(5):
        now = now.replace(second=0, microsecond=0) if minute == 0 else now + timedelta(minutes=1)
        assert (await login(client, account, "incorrect")).status_code == 401
    first = now - timedelta(minutes=4)
    now = first + timedelta(minutes=15, microseconds=-1)
    verified = []
    original = service.password_is_valid

    def observe_verify(*args):
        verified.append(True)
        return original(*args)

    monkeypatch.setattr(service, "password_is_valid", observe_verify)
    assert (await login(client, account)).status_code == 429
    assert verified == []
    now = first + timedelta(minutes=15)
    assert (await login(client, account, "incorrect")).status_code == 401
    assert (await login(client, account)).status_code == 429
    assert len(verified) == 1
    now = first + timedelta(minutes=16)
    assert (await login(client, account)).status_code == 204
    attempt = await session.scalar(select(LoginAttempt).where(LoginAttempt.email == account.email))
    assert attempt.failed_at == []


async def test_concurrent_login_requests_verify_at_most_five_passwords(client, account, monkeypatch):
    from app.identity import service

    verified = []
    original = service.password_is_valid

    def observe_verify(*args):
        verified.append(True)
        return original(*args)

    monkeypatch.setattr(service, "password_is_valid", observe_verify)
    responses = await asyncio.wait_for(
        asyncio.gather(*(login(client, account, "incorrect") for _ in range(12))), timeout=20
    )
    assert sorted(response.status_code for response in responses) == [401] * 5 + [429] * 7
    assert len(verified) == 5
    assert all(not response.headers.get_list("set-cookie") for response in responses)


async def test_final_permitted_success_holds_lock_until_reset(client, account, session, monkeypatch):
    from app.identity import router

    for _ in range(4):
        assert (await login(client, account, "incorrect")).status_code == 401
    verifying = asyncio.Event()
    release = asyncio.Event()
    original = router.authenticate
    verified = []

    async def paused_authenticate(database, email, password):
        verified.append(password)
        if password == PASSWORD:
            verifying.set()
            await release.wait()
        return await original(database, email, password)

    monkeypatch.setattr(router, "authenticate", paused_authenticate)
    success = asyncio.create_task(login(client, account))
    await asyncio.wait_for(verifying.wait(), timeout=5)
    failures = [asyncio.create_task(login(client, account, "incorrect")) for _ in range(6)]

    async def wait_for_competitors():
        while True:
            blocked = await session.scalar(text(
                "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() "
                "AND wait_event_type = 'Lock' AND query LIKE '%login_attempts%'"
            ))
            await session.commit()  # Refresh PostgreSQL's activity snapshot on each poll.
            if blocked == 6 or len(verified) > 1:
                return
            await asyncio.sleep(0.01)

    try:
        await asyncio.wait_for(wait_for_competitors(), timeout=5)
        assert verified == [PASSWORD]
    finally:
        release.set()
        responses = await asyncio.wait_for(asyncio.gather(success, *failures), timeout=20)
    assert responses[0].status_code == 204
    assert sorted(response.status_code for response in responses[1:]) == [401] * 5 + [429]


async def test_reset_password_rehashes_password_revokes_only_account_sessions_and_removes_push_subscription(
    client, session, account
):
    from app.identity.service import authenticated_session, hash_token, reset_password
    from app.push.models import PushSubscription

    other_account = User(
        email=f"other-{uuid4()}@example.com",
        password_hash=PasswordHasher().hash(PASSWORD),
    )
    first_token = "first-session-token"
    second_token = "second-session-token"
    other_token = "other-session-token"
    first_session = Session(
        user_id=account.id,
        token_hash=hash_token(first_token),
        csrf_hash="a" * 64,
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
    )
    second_session = Session(
        user_id=account.id,
        token_hash=hash_token(second_token),
        csrf_hash="b" * 64,
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
    )
    session.add(other_account)
    await session.flush()
    other_session = Session(
        user_id=other_account.id,
        token_hash=hash_token(other_token),
        csrf_hash="c" * 64,
        expires_at=datetime.now(timezone.utc) + timedelta(days=1),
    )
    session.add_all([first_session, second_session, other_session])
    await session.flush()
    session.add_all(
        [
            PushSubscription(
                installation_id=uuid4(),
                user_id=account.id,
                session_id=first_session.id,
                endpoint="https://push.example/account-subscription",
                endpoint_hash="d" * 64,
                p256dh="e" * 87,
                auth="f" * 22,
                categories={},
            ),
            PushSubscription(
                installation_id=uuid4(),
                user_id=account.id,
                session_id=second_session.id,
                endpoint="https://push.example/second-account-subscription",
                endpoint_hash="g" * 64,
                p256dh="h" * 87,
                auth="i" * 22,
                categories={},
            ),
            PushSubscription(
                installation_id=uuid4(),
                user_id=other_account.id,
                session_id=other_session.id,
                endpoint="https://push.example/other-subscription",
                endpoint_hash="j" * 64,
                p256dh="k" * 87,
                auth="l" * 22,
                categories={},
            ),
        ]
    )
    await session.commit()

    reset_account = await reset_password(session, account.email.upper(), "new password")

    await session.refresh(account)
    assert reset_account.id == account.id
    assert PasswordHasher().verify(account.password_hash, "new password")
    assert await authenticated_session(session, first_token) is None
    assert await authenticated_session(session, second_token) is None
    assert await authenticated_session(session, other_token) is not None
    assert await session.scalar(select(PushSubscription).where(PushSubscription.session_id == first_session.id)) is None
    assert await session.scalar(select(PushSubscription).where(PushSubscription.session_id == second_session.id)) is None
    assert await session.scalar(select(PushSubscription).where(PushSubscription.session_id == other_session.id)) is not None


async def test_reset_password_rejects_a_missing_account(client, session):
    from app.identity.service import AccountNotFoundError, reset_password

    with pytest.raises(AccountNotFoundError):
        await reset_password(session, "missing@example.com", "new password")


async def test_reset_revokes_a_session_issued_by_a_concurrent_old_password_login(
    client, database_url, account, monkeypatch
):
    from app.identity import service
    from app.identity.service import authenticate, authenticated_session, issue_session, reset_password

    engine = create_async_engine(database_url)
    database_sessions = async_sessionmaker(engine, expire_on_commit=False)
    verified = asyncio.Event()
    reset_database_created = asyncio.Event()
    reset_user_lock_attempted = asyncio.Event()
    issue_allowed = asyncio.Event()
    reset_database = None
    original_scalar = service.AsyncSession.scalar

    async def observe_reset_user_lock(database, statement, *args, **kwargs):
        if (
            database is reset_database
            and statement._for_update_arg is not None
            and statement.column_descriptions[0]["entity"] is User
        ):
            reset_user_lock_attempted.set()
        return await original_scalar(database, statement, *args, **kwargs)

    monkeypatch.setattr(service.AsyncSession, "scalar", observe_reset_user_lock)

    async def login():
        async with database_sessions() as database:
            authenticated_account = await authenticate(database, account.email, PASSWORD)
            assert authenticated_account is not None
            verified.set()
            await issue_allowed.wait()
            issued_session = await issue_session(
                database,
                authenticated_account,
                verified_password_hash=authenticated_account.password_hash,
                commit=False,
            )
            assert issued_session is not None
            await database.commit()
            return issued_session

    async def reset():
        nonlocal reset_database

        await verified.wait()
        async with database_sessions() as database:
            reset_database = database
            reset_database_created.set()
            await reset_password(database, account.email, "new password")

    login_task = None
    reset_task = None
    try:
        login_task = asyncio.create_task(login())
        reset_task = asyncio.create_task(reset())
        await asyncio.wait_for(verified.wait(), timeout=5)
        await asyncio.wait_for(reset_database_created.wait(), timeout=5)
        await asyncio.wait_for(reset_user_lock_attempted.wait(), timeout=5)
        issue_allowed.set()
        issued_session = await asyncio.wait_for(login_task, timeout=5)
        await asyncio.wait_for(reset_task, timeout=5)
        async with database_sessions() as database:
            assert await authenticated_session(database, issued_session.session_token) is None
    finally:
        for task in (login_task, reset_task):
            if task is not None and not task.done():
                task.cancel()
        await asyncio.gather(*(task for task in (login_task, reset_task) if task is not None), return_exceptions=True)
        await engine.dispose()


async def test_reset_and_push_subscription_write_follow_the_same_lock_order(client, database_url, account, session):
    from app.identity.service import AuthenticatedSession, authenticated_session, issue_session, reset_password
    from app.push.models import PushSubscription
    from app.push.router import save_subscription
    from app.push.schemas import SubscriptionRequest

    issued_session = await issue_session(session, account)
    active_session = await session.scalar(select(Session).where(Session.user_id == account.id))
    assert active_session is not None
    engine = create_async_engine(database_url)
    database_sessions = async_sessionmaker(engine, expire_on_commit=False)
    session_locked = asyncio.Event()
    reset_started = asyncio.Event()
    reset_can_continue = asyncio.Event()
    subscription = SubscriptionRequest.model_validate(
        {
            "endpoint": "https://fcm.googleapis.com/reset-interleaving",
            "keys": {
                "p256dh": (
                    "BGsX0fLhLEJH-Lzm5WOkQPJ3A32BLeszoPShOUXYmMKWT-NC4v4af5uO5-t"
                    "KfA-eFivOM1drMV7Oy7ZAaDe_UfU"
                ),
                "auth": "AAAAAAAAAAAAAAAAAAAAAA",
            },
            "categories": {"karate": True},
        }
    )

    async def write_subscription():
        async with database_sessions() as database:
            stored_account = await database.get(User, account.id)
            stored_session = await database.get(Session, active_session.id)
            assert stored_account is not None and stored_session is not None
            await database.scalar(select(Session).where(Session.id == stored_session.id).with_for_update())
            session_locked.set()
            await reset_can_continue.wait()
            await save_subscription(
                uuid4(),
                subscription,
                database,
                AuthenticatedSession(account=stored_account, session=stored_session),
            )

    async def reset():
        await session_locked.wait()
        reset_started.set()
        async with database_sessions() as database:
            await reset_password(database, account.email, "new password")

    async def wait_for_reset_to_wait_on_sessions():
        while True:
            async with database_sessions() as database:
                waiting = await database.scalar(
                    text(
                        "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() "
                        "AND wait_event_type = 'Lock' AND query LIKE '%sessions%'"
                    )
                )
            if waiting:
                return
            await asyncio.sleep(0.01)

    write_task = asyncio.create_task(write_subscription())
    reset_task = asyncio.create_task(reset())
    try:
        await session_locked.wait()
        await reset_started.wait()
        await asyncio.wait_for(wait_for_reset_to_wait_on_sessions(), timeout=5)
        reset_can_continue.set()
        await asyncio.wait_for(asyncio.gather(write_task, reset_task), timeout=10)
        async with database_sessions() as database:
            assert await authenticated_session(database, issued_session.session_token) is None
            assert await database.scalar(select(PushSubscription).where(PushSubscription.user_id == account.id)) is None
    finally:
        for task in (write_task, reset_task):
            if not task.done():
                task.cancel()
        await asyncio.gather(write_task, reset_task, return_exceptions=True)
        await engine.dispose()
