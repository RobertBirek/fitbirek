import asyncio
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.identity.models import LoginAttempt


pytestmark = pytest.mark.asyncio


async def test_failed_attempts_persist_across_fresh_limiter_instances(session):
    from app.security.rate_limit import LoginRateLimiter

    first_limiter = LoginRateLimiter()
    for _ in range(5):
        assert await first_limiter.record_failure(session, "127.0.0.1", "person@example.com")

    fresh_limiter = LoginRateLimiter()

    assert not await fresh_limiter.record_failure(session, "127.0.0.1", "person@example.com")


async def test_failed_attempts_are_limited_atomically_under_concurrency(database_url):
    from app.security.rate_limit import LoginRateLimiter

    engine = create_async_engine(database_url)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    async def record_failure() -> bool:
        async with session_factory() as database_session:
            return await LoginRateLimiter().record_failure(
                database_session, "127.0.0.1", "concurrent@example.com"
            )

    try:
        results = await asyncio.gather(*(record_failure() for _ in range(10)))
    finally:
        await engine.dispose()

    assert sum(results) == 5


async def test_high_distinct_email_attempt_volume_does_not_deny_another_ip(session):
    from app.security.rate_limit import LoginRateLimiter

    limiter = LoginRateLimiter()
    for number in range(100):
        assert await limiter.record_failure(session, "127.0.0.1", f"attacker-{number}@example.com")

    assert await limiter.record_failure(session, "127.0.0.2", "person@example.com")


async def test_record_failure_uses_database_time_after_waiting_for_the_row_lock(database_url, monkeypatch):
    from app.security import rate_limit

    earlier = datetime(2026, 9, 8, 12, 0, tzinfo=timezone.utc)
    before_lock = earlier + timedelta(minutes=10)
    after_lock = earlier + timedelta(minutes=20)
    clock_values = iter([before_lock, after_lock])

    async def controlled_database_now(_database):
        return next(clock_values)

    monkeypatch.setattr(rate_limit, "database_now", controlled_database_now)
    engine = create_async_engine(database_url)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    class LockObservedSession:
        def __init__(self, database):
            self.database = database
            self.lock_requested = asyncio.Event()

        async def execute(self, statement):
            return await self.database.execute(statement)

        async def scalar(self, statement):
            if statement._for_update_arg is not None:
                self.lock_requested.set()
            return await self.database.scalar(statement)

        async def commit(self):
            await self.database.commit()

        async def rollback(self):
            await self.database.rollback()

    try:
        async with session_factory() as seed_session:
            seed_session.add(
                LoginAttempt(
                    client_ip="127.0.0.1",
                    email="locked@example.com",
                    failed_at=[earlier],
                    last_failed_at=earlier,
                )
            )
            await seed_session.commit()

        async with session_factory() as locking_session, session_factory() as waiting_session:
            await locking_session.execute(
                select(LoginAttempt)
                .where(LoginAttempt.client_ip == "127.0.0.1", LoginAttempt.email == "locked@example.com")
                .with_for_update()
            )
            observed_session = LockObservedSession(waiting_session)
            record_task = asyncio.create_task(
                rate_limit.LoginRateLimiter().record_failure(
                    observed_session, "127.0.0.1", "locked@example.com"
                )
            )
            await observed_session.lock_requested.wait()
            await locking_session.commit()
            assert await record_task

        async with session_factory() as assertion_session:
            attempt = await assertion_session.scalar(
                select(LoginAttempt).where(
                    LoginAttempt.client_ip == "127.0.0.1", LoginAttempt.email == "locked@example.com"
                )
            )
            assert attempt is not None
            assert attempt.failed_at == [after_lock]
    finally:
        await engine.dispose()


async def test_purge_stale_attempts_removes_rows_in_bounded_batches(session):
    from app.security.rate_limit import LoginRateLimiter

    now = datetime(2026, 9, 8, 12, 0, tzinfo=timezone.utc)
    stale = now - timedelta(minutes=16)
    session.add_all(
        [
            LoginAttempt(client_ip="127.0.0.1", email=f"stale-{number}@example.com", failed_at=[stale], last_failed_at=stale)
            for number in range(3)
        ]
        + [LoginAttempt(client_ip="127.0.0.1", email="active@example.com", failed_at=[now], last_failed_at=now)]
    )
    await session.commit()
    limiter = LoginRateLimiter(cleanup_batch_size=2)

    assert await limiter.purge_stale_attempts(session, now=now) == 2
    assert await limiter.purge_stale_attempts(session, now=now) == 1
    remaining = (await session.scalars(select(LoginAttempt.email))).all()
    assert remaining == ["active@example.com"]


async def test_purge_skips_a_stale_row_locked_for_a_concurrent_refresh(database_url):
    from app.security.rate_limit import LoginRateLimiter

    now = datetime(2026, 9, 8, 12, 0, tzinfo=timezone.utc)
    stale = now - timedelta(minutes=16)
    engine = create_async_engine(database_url)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    try:
        async with session_factory() as seed_session:
            seed_session.add(
                LoginAttempt(
                    client_ip="127.0.0.1",
                    email="refreshing@example.com",
                    failed_at=[stale],
                    last_failed_at=stale,
                )
            )
            await seed_session.commit()

        async with session_factory() as refresh_session, session_factory() as cleanup_session:
            attempt = await refresh_session.scalar(
                select(LoginAttempt)
                .where(LoginAttempt.client_ip == "127.0.0.1", LoginAttempt.email == "refreshing@example.com")
                .with_for_update()
            )
            assert attempt is not None

            deleted = await asyncio.wait_for(
                LoginRateLimiter().purge_stale_attempts(cleanup_session, now=now), timeout=1
            )

            attempt.failed_at = [now]
            attempt.last_failed_at = now
            await refresh_session.commit()

        async with session_factory() as assertion_session:
            refreshed_attempt = await assertion_session.scalar(
                select(LoginAttempt).where(
                    LoginAttempt.client_ip == "127.0.0.1", LoginAttempt.email == "refreshing@example.com"
                )
            )
            assert deleted == 0
            assert refreshed_attempt is not None
            assert refreshed_attempt.last_failed_at == now
    finally:
        await engine.dispose()


async def test_api_lifespan_purges_stale_attempts_before_serving(client, session):
    from app.main import app

    stale = datetime.now(timezone.utc) - timedelta(minutes=16)
    session.add(
        LoginAttempt(
            client_ip="127.0.0.1",
            email="stale@example.com",
            failed_at=[stale],
            last_failed_at=stale,
        )
    )
    await session.commit()

    async with app.router.lifespan_context(app):
        assert await session.scalar(select(LoginAttempt)) is None


async def test_recurring_cleanup_runs_a_purge_after_each_interval(monkeypatch):
    from app import main

    first_interval_started = asyncio.Event()
    second_interval_started = asyncio.Event()
    allow_first_interval_to_finish = asyncio.Event()
    allow_second_interval_to_finish = asyncio.Event()
    second_purge_completed = asyncio.Event()
    sleep_calls = 0
    purge_calls = 0

    async def controlled_sleep(_seconds):
        nonlocal sleep_calls
        sleep_calls += 1
        if sleep_calls == 1:
            first_interval_started.set()
            await allow_first_interval_to_finish.wait()
        elif sleep_calls == 2:
            second_interval_started.set()
            await allow_second_interval_to_finish.wait()
        else:
            await asyncio.Event().wait()

    async def controlled_purge():
        nonlocal purge_calls
        purge_calls += 1
        if purge_calls == 2:
            second_purge_completed.set()

    monkeypatch.setattr(main.asyncio, "sleep", controlled_sleep)
    monkeypatch.setattr(main, "purge_stale_login_attempts", controlled_purge)
    cleanup_task = asyncio.create_task(main.run_login_attempt_cleanup())

    try:
        await first_interval_started.wait()
        allow_first_interval_to_finish.set()
        await asyncio.wait_for(second_interval_started.wait(), timeout=1)
        assert purge_calls == 1
        allow_second_interval_to_finish.set()
        await asyncio.wait_for(second_purge_completed.wait(), timeout=1)
        assert purge_calls == 2
    finally:
        cleanup_task.cancel()
        with pytest.raises(asyncio.CancelledError):
            await cleanup_task
