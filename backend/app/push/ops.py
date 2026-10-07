"""Privileged local CLI: JSON observations on stdin, never a public HTTP route."""
import asyncio
from datetime import datetime, timedelta, timezone
import json
import sys

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert

from app.config import settings
from app.database import session_factory
from app.push.models import PushIncident, PushSubscription
from app.push.queue import enqueue

INCIDENTS = frozenset({"backup", "restore", "stale_backup", "api"})


async def observe(database, name, failing, observed_at):
    if name not in INCIDENTS or type(failing) is not bool or observed_at.tzinfo is None:
        raise ValueError("Invalid observation")
    if not settings.push_enabled:
        return
    await database.execute(insert(PushIncident).values(
        name=name, failing=False, generation=0, observed_at=datetime(1970, 1, 1, tzinfo=timezone.utc),
    ).on_conflict_do_nothing(index_elements=["name"]))
    incident = await database.scalar(select(PushIncident).where(PushIncident.name == name).with_for_update().execution_options(populate_existing=True))
    if observed_at <= incident.observed_at:
        return
    incident.observed_at = observed_at
    if incident.failing != failing:
        incident.failing = failing
        incident.generation += 1
        key = f"ops:{name}:{incident.generation}:{'failure' if failing else 'recovery'}"
        subscriptions = await database.scalars(select(PushSubscription).where(
            PushSubscription.categories["operations"].as_boolean().is_(True),
            PushSubscription.vapid_public_key == settings.push_vapid_public_key,
        ))
        for subscription in subscriptions:
            await enqueue(database, subscription, key, "operations", observed_at,
                          observed_at + timedelta(hours=1), incident=name, recovery=not failing,
                          incidentGeneration=incident.generation)


async def main():
    observations = json.loads(sys.stdin.read(8192))
    if not isinstance(observations, list) or len(observations) > 4:
        raise ValueError("Invalid observations")
    async with session_factory() as database:
        for item in sorted(observations, key=lambda item: item["name"]):
            await observe(database, item["name"], item["failing"], datetime.fromisoformat(item["observedAt"]))
        await database.commit()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception:
        print("Push observation could not be persisted; inspect DB/sender availability", file=sys.stderr)
        sys.exit(1)
