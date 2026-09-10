from datetime import datetime, timedelta

from sqlalchemy import delete, func, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.identity.models import LoginAttempt


async def database_now(database: AsyncSession) -> datetime:
    return await database.scalar(select(func.clock_timestamp()))


class LoginRateLimiter:
    def __init__(
        self,
        maximum_attempts: int = 5,
        window_minutes: int = 15,
        cleanup_batch_size: int = 100,
    ) -> None:
        self.maximum_attempts = maximum_attempts
        self.window = timedelta(minutes=window_minutes)
        self.cleanup_batch_size = cleanup_batch_size

    async def purge_stale_attempts(self, database: AsyncSession, now: datetime | None = None) -> int:
        if now is None:
            now = await database_now(database)
        cutoff = now - self.window
        stale_attempts = (
            select(LoginAttempt.id)
            .where(LoginAttempt.last_failed_at <= cutoff)
            .order_by(LoginAttempt.last_failed_at)
            .with_for_update(skip_locked=True)
            .limit(self.cleanup_batch_size)
            .cte("stale_attempts")
        )
        result = await database.execute(
            delete(LoginAttempt)
            .where(LoginAttempt.id.in_(select(stale_attempts.c.id)))
            .where(LoginAttempt.last_failed_at <= cutoff)
        )
        await database.commit()
        return result.rowcount

    async def record_failure(self, database: AsyncSession, client_ip: str, email: str) -> bool:
        permitted = await self.reserve_attempt(database, client_ip, email)
        await database.commit()
        return permitted

    async def reserve_attempt(self, database: AsyncSession, client_ip: str, email: str) -> bool:
        """Check and reserve before verification, retaining the row lock.

        The caller must commit a failed attempt or reset on success before
        releasing the transaction. This serializes verification and reset for
        the same IP/email, including across API workers.
        """
        await self.purge_stale_attempts(database)
        await database.execute(
            insert(LoginAttempt)
            .values(client_ip=client_ip, email=email, failed_at=[], last_failed_at=func.clock_timestamp())
            .on_conflict_do_nothing(index_elements=[LoginAttempt.client_ip, LoginAttempt.email])
        )
        attempt = await database.scalar(
            select(LoginAttempt)
            .where(LoginAttempt.client_ip == client_ip, LoginAttempt.email == email)
            .with_for_update()
        )
        if attempt is None:
            await database.rollback()
            return await self.reserve_attempt(database, client_ip, email)

        now = await database_now(database)
        cutoff = now - self.window
        active_failures = [failed_at for failed_at in attempt.failed_at if failed_at > cutoff]
        if len(active_failures) >= self.maximum_attempts:
            attempt.failed_at = active_failures
            attempt.last_failed_at = active_failures[-1]
            await database.commit()
            return False

        attempt.failed_at = [*active_failures, now]
        attempt.last_failed_at = now
        return True

    async def reset_failures(self, database: AsyncSession, client_ip: str, email: str) -> None:
        await database.execute(
            insert(LoginAttempt)
            .values(client_ip=client_ip, email=email, failed_at=[], last_failed_at=func.clock_timestamp())
            .on_conflict_do_nothing(index_elements=[LoginAttempt.client_ip, LoginAttempt.email])
        )
        attempt = await database.scalar(
            select(LoginAttempt)
            .where(LoginAttempt.client_ip == client_ip, LoginAttempt.email == email)
            .with_for_update()
        )
        if attempt is None:
            await database.rollback()
            await self.reset_failures(database, client_ip, email)
            return
        now = await database_now(database)
        attempt.failed_at = []
        attempt.last_failed_at = now
        await database.commit()


login_rate_limiter = LoginRateLimiter()
