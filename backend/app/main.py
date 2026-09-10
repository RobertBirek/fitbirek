import asyncio
import logging
from contextlib import asynccontextmanager, suppress

from fastapi import Depends, FastAPI, Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from .database import get_session, session_factory
from .identity.router import router as identity_router
from .security.rate_limit import login_rate_limiter
from .sync.router import router as sync_router


logger = logging.getLogger(__name__)
login_attempt_cleanup_interval_seconds = 300


async def purge_stale_login_attempts() -> None:
    try:
        async with session_factory() as session:
            await login_rate_limiter.purge_stale_attempts(session)
    except Exception:
        logger.exception("Failed to purge stale login attempts")


async def run_login_attempt_cleanup() -> None:
    while True:
        await asyncio.sleep(login_attempt_cleanup_interval_seconds)
        await purge_stale_login_attempts()


@asynccontextmanager
async def lifespan(_app: FastAPI):
    await purge_stale_login_attempts()
    cleanup_task = asyncio.create_task(run_login_attempt_cleanup())
    try:
        yield
    finally:
        cleanup_task.cancel()
        with suppress(asyncio.CancelledError):
            await cleanup_task


app = FastAPI(lifespan=lifespan)
app.include_router(identity_router)
app.include_router(sync_router)


@app.exception_handler(RequestValidationError)
async def validation_error_response(_request: Request, error: RequestValidationError) -> JSONResponse:
    details = [{key: value for key, value in detail.items() if key != "input"} for detail in error.errors()]
    return JSONResponse(status_code=422, content=jsonable_encoder({"detail": details}))


@app.get("/api/health")
async def health(session: AsyncSession = Depends(get_session)) -> dict[str, str]:
    await session.execute(text("SELECT 1"))
    return {"status": "ok"}
