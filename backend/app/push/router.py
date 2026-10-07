from hashlib import sha256
from datetime import timedelta
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import delete, func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.config import settings
from app.identity.models import Session, User
from app.identity.service import AuthenticatedSession, require_authenticated
from app.push.models import PushSubscription, PushTestLimit
from app.push.queue import delivery_status, enqueue
from app.push.schemas import SubscriptionRequest
from app.security.csrf import require_csrf


router = APIRouter(prefix="/api/push", tags=["push"])


@router.get("/status")
async def push_status(
    response: Response,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_authenticated),
) -> dict:
    response.headers["Cache-Control"] = "no-store"
    return await delivery_status(database)


@router.get("/subscriptions/{installation_id}")
async def subscription_status(
    installation_id: UUID,
    response: Response,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_authenticated),
) -> dict:
    stored = await database.scalar(select(PushSubscription).where(
        PushSubscription.installation_id == installation_id,
        PushSubscription.user_id == authenticated.account.id,
    ))
    if stored is None:
        raise HTTPException(404, "Subscription not found")
    response.headers["Cache-Control"] = "no-store"
    return {"installationId": str(installation_id), "categories": stored.categories}


@router.put("/subscriptions/{installation_id}", status_code=204)
async def save_subscription(
    installation_id: UUID,
    payload: SubscriptionRequest,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> None:
    if settings.push_enabled and payload.vapidPublicKey != settings.push_vapid_public_key:
        raise HTTPException(409, "VAPID key changed; subscribe again")
    # Serialize with logout; recheck after waiting, since authentication happened
    # before acquiring this lock. Logout must not leave a concurrent opt-in alive.
    active = await database.scalar(select(Session).where(
        Session.id == authenticated.session.id,
        Session.revoked_at.is_(None),
        Session.expires_at > func.now(),
    ).with_for_update().execution_options(populate_existing=True))
    if active is None:
        raise HTTPException(401, "Authentication required")
    # This account lock makes the installation cap safe across API processes.
    await database.scalar(select(User.id).where(User.id == authenticated.account.id).with_for_update())
    stored = await database.scalar(select(PushSubscription).where(
        PushSubscription.installation_id == installation_id,
    ).with_for_update())
    if stored is not None and stored.user_id != authenticated.account.id:
        raise HTTPException(409, "Subscription unavailable")
    if stored is None:
        count = await database.scalar(select(func.count()).select_from(PushSubscription).where(
            PushSubscription.user_id == authenticated.account.id,
        ))
        if count >= 10:
            raise HTTPException(409, "Installation limit reached")
        stored = PushSubscription(installation_id=installation_id, user_id=authenticated.account.id)
        database.add(stored)
    stored.session_id = authenticated.session.id
    stored.endpoint = payload.endpoint
    stored.endpoint_hash = sha256(payload.endpoint.encode()).hexdigest()
    stored.p256dh = payload.keys.p256dh
    stored.auth = payload.keys.auth
    stored.vapid_public_key = settings.push_vapid_public_key
    stored.categories = payload.categories.model_dump()
    stored.updated_at = func.now()
    try:
        await database.commit()
    except IntegrityError:
        await database.rollback()
        # Never disclose a different account's subscription or provider token.
        raise HTTPException(409, "Subscription unavailable") from None


@router.delete("/subscriptions/{installation_id}", status_code=204)
async def remove_subscription(
    installation_id: UUID,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> None:
    await database.execute(delete(PushSubscription).where(
        PushSubscription.installation_id == installation_id,
        PushSubscription.user_id == authenticated.account.id,
    ))
    await database.commit()


@router.post("/subscriptions/{installation_id}/test", status_code=202)
async def test_subscription(
    installation_id: UUID,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> dict:
    if not (await delivery_status(database))["deliveryAvailable"]:
        raise HTTPException(503, "Push delivery unavailable")
    # Persisted per-user rate limit; cannot be bypassed by changing installations.
    await database.scalar(select(User.id).where(User.id == authenticated.account.id).with_for_update())
    stored = await database.scalar(select(PushSubscription).where(
        PushSubscription.installation_id == installation_id,
        PushSubscription.user_id == authenticated.account.id,
    ).with_for_update())
    if stored is None:
        raise HTTPException(404, "Subscription not found")
    now = await database.scalar(select(func.clock_timestamp()))
    if stored.vapid_public_key != settings.push_vapid_public_key:
        raise HTTPException(409, "VAPID key changed; subscribe again")
    limit = await database.get(PushTestLimit, authenticated.account.id)
    if limit is not None and now - limit.requested_at < timedelta(seconds=60):
        raise HTTPException(429, "Wait before another test", headers={"Retry-After": "60"})
    if limit is None:
        database.add(PushTestLimit(user_id=authenticated.account.id, requested_at=now))
    else:
        limit.requested_at = now
    event = f"test:{uuid4()}"
    await enqueue(database, stored, event, "test", now, now + timedelta(minutes=5))
    await database.commit()
    return {"queued": True}
