from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.identity.service import AuthenticatedSession, require_authenticated
from app.security.csrf import require_csrf
from app.sync.schemas import PullResponse, PushRequest, PushResponse
from app.sync.service import pull_changes, push_operations


router = APIRouter(prefix="/api/sync", tags=["sync"])
postgres_bigint_maximum = 2**63 - 1


@router.post("/push", response_model=PushResponse)
async def push(
    payload: PushRequest,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> PushResponse:
    return await push_operations(database, authenticated.account.id, payload.operations)


@router.get("/pull", response_model=PullResponse)
async def pull(
    cursor: int = Query(default=0, ge=0, le=postgres_bigint_maximum),
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_authenticated),
) -> PullResponse:
    return await pull_changes(database, authenticated.account.id, cursor)
