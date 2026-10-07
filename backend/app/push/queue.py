from datetime import datetime, timedelta, timezone
from uuid import uuid4
from zoneinfo import ZoneInfo

from sqlalchemy import delete, func, select
from sqlalchemy.dialects.postgresql import insert

from app.config import settings
from app.push.models import PushDelivery, PushIncident, PushSenderState, PushSubscription


WARSAW = ZoneInfo("Europe/Warsaw")


async def delivery_status(database):
    if not settings.push_enabled or not settings.push_vapid_public_key:
        return {"deliveryAvailable": False, "reason": "disabled", "publicKey": None}
    heartbeat = await database.get(PushSenderState, 1, populate_existing=True)
    now = await database.scalar(select(func.clock_timestamp()))
    ready = heartbeat is not None and heartbeat.public_key == settings.push_vapid_public_key and now - heartbeat.heartbeat_at < timedelta(seconds=90)
    return {"deliveryAvailable": ready, "reason": "ready" if ready else "sender_unavailable", "publicKey": settings.push_vapid_public_key}


def due_events(now):
    local = now.astimezone(WARSAW)
    for category, hour, minute in (("karate", 19, 30), ("training", 18, 0), ("mood", 20, 30)):
        if category == "karate" and local.weekday() not in (1, 3):
            continue
        due = local.replace(hour=hour, minute=minute, second=0, microsecond=0)
        if timedelta(0) <= local - due < timedelta(minutes=15):
            yield category, f"{category}:{local.date().isoformat()}", due.astimezone(timezone.utc)


async def enqueue(database, subscription, event_key, category, now, expires_at, **extra):
    url = "/workout" if category == "training" else "/settings" if category in ("operations", "test") else "/today"
    payload = {"category": category, "eventId": event_key, "url": url,
               "installationId": str(subscription.installation_id),
               "expiresAt": int(expires_at.timestamp() * 1000), **extra}
    await database.execute(insert(PushDelivery).values(
        id=uuid4(), installation_id=subscription.installation_id, event_key=event_key,
        category=category, payload=payload, state="pending", attempts=0,
        available_at=now, expires_at=expires_at,
    ).on_conflict_do_nothing(index_elements=["installation_id", "event_key"]))


async def schedule(database, now=None):
    if not settings.push_enabled:
        return
    now = now or await database.scalar(select(func.clock_timestamp()))
    for category, key, due in due_events(now):
        subscriptions = await database.scalars(select(PushSubscription).where(
            PushSubscription.categories[category].as_boolean().is_(True),
            PushSubscription.vapid_public_key == settings.push_vapid_public_key,
        ))
        for subscription in subscriptions:
            await enqueue(database, subscription, key, category, now, due + timedelta(minutes=15))
    # Keep seven days of dedup tombstones; never catch up that far.
    await database.execute(delete(PushDelivery).where(PushDelivery.expires_at < now - timedelta(days=7)))
    await database.commit()


async def deliver_one(database, send):
    if not settings.push_enabled:
        return False
    now = await database.scalar(select(func.clock_timestamp()))
    # A transaction lock is the lease: crash rolls it back immediately, without
    # a second process concurrently sending the same job. Network time is bounded.
    due_jobs = select(PushDelivery.installation_id).where(
        PushDelivery.state == "pending", PushDelivery.available_at <= now,
    )
    # Lock subscription before its children, matching DELETE/logout cascade order.
    subscription = await database.scalar(select(PushSubscription).where(
        PushSubscription.installation_id.in_(due_jobs),
    ).with_for_update(skip_locked=True).execution_options(populate_existing=True).limit(1))
    if subscription is None:
        await database.rollback()
        return False
    job = await database.scalar(select(PushDelivery).where(
        PushDelivery.installation_id == subscription.installation_id,
        PushDelivery.state == "pending", PushDelivery.available_at <= now,
    ).order_by(PushDelivery.available_at).with_for_update().execution_options(populate_existing=True).limit(1))
    obsolete_incident = False
    if job.category == "operations":
        incident = await database.get(PushIncident, job.payload.get("incident"), populate_existing=True)
        obsolete_incident = incident is None or incident.generation != job.payload.get("incidentGeneration")
    if job.expires_at <= now:
        job.state = "expired"
    elif obsolete_incident or subscription.vapid_public_key != settings.push_vapid_public_key or (
        job.category != "test" and not subscription.categories.get(job.category, False)
    ):
        job.state = "cancelled"
    else:
        job.attempts += 1
        try:
            code = await send(subscription, job.payload, int((job.expires_at - now).total_seconds()))
        except (OSError, TimeoutError):
            code = 0
        except ValueError:
            code = 400
        job.last_status = code
        if code in (404, 410):
            await database.delete(subscription)
        elif 200 <= code < 300:
            job.state = "sent"
        elif (code in (0, 408, 429) or code >= 500) and job.attempts < 8:
            job.available_at = now + timedelta(seconds=min(900, 30 * 2 ** (job.attempts - 1)))
        else:
            job.state = "failed"
    await database.commit()
    return True
