"""Run with python -m app.push.worker, independently of Uvicorn."""
import asyncio
import logging

from sqlalchemy import func
from sqlalchemy.dialects.postgresql import insert

from app.config import settings
from app.database import session_factory
from app.push.models import PushSenderState
from app.push.queue import deliver_one, schedule
from app.push.transport import PushTransport

logger = logging.getLogger("fit.push")


async def run():
    while True:
        if not settings.push_enabled:
            await asyncio.sleep(30)
            continue
        try:
            # Reload on each cycle: bad/missing/rotated secrets fail closed.
            transport = PushTransport(settings)
            async with session_factory() as database:
                await database.execute(insert(PushSenderState).values(
                    id=1, public_key=settings.push_vapid_public_key, heartbeat_at=func.clock_timestamp(),
                ).on_conflict_do_update(index_elements=["id"], set_={
                    "public_key": settings.push_vapid_public_key, "heartbeat_at": func.clock_timestamp(),
                }))
                await database.commit()
                await schedule(database)
                for _ in range(3):
                    if not await deliver_one(database, transport):
                        break
        except Exception as error:
            # Provider exceptions/DB errors can contain credentials or endpoints.
            # Log only the class, never exception strings or a traceback.
            logger.error("Push cycle failed (%s)", type(error).__name__)
        await asyncio.sleep(5)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(run())
