from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.identity.models import User, Session
from app.health.models import AppleHealthToken
from app.security.rate_limit import database_now

from app.database import get_session
from app.health.contract import MAX_BATCH_BYTES
from app.health.schemas import ConsentRequest, ImportRequest
from app.health.service import (
    ImportPrincipal,
    current_token,
    integration_status_dict,
    process_import,
    require_import_token,
    revoke_token,
    rotate_token,
    reserve_import_attempt,
)
from app.identity.service import AuthenticatedSession, require_authenticated
from app.security.csrf import require_csrf


router = APIRouter(prefix="/api/integrations/apple-health", tags=["health"])


@router.get("")
async def integration_status(
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_authenticated),
) -> dict:
    return integration_status_dict(await current_token(database, authenticated.account.id))


@router.post("/token")
async def rotate(
    payload: ConsentRequest,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> dict:
    active = await database.scalar(select(Session.id).where(Session.id == authenticated.session.id, Session.revoked_at.is_(None), Session.expires_at > await database_now(database)).with_for_update())
    if active is None:
        raise HTTPException(401, "Authentication required")
    token, cleartext = await rotate_token(database, authenticated.account.id)
    return {**integration_status_dict(token), "token": cleartext}


@router.delete("/token")
async def revoke(
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> dict:
    active = await database.scalar(select(Session.id).where(Session.id == authenticated.session.id, Session.revoked_at.is_(None), Session.expires_at > await database_now(database)).with_for_update())
    if active is None:
        raise HTTPException(401, "Authentication required")
    await revoke_token(database, authenticated.account.id)
    return integration_status_dict(await current_token(database, authenticated.account.id))


async def bounded_import_payload(request: Request) -> ImportRequest:
    """Read a strictly bounded request body before validation."""
    content_type = request.headers.get("content-type")
    if content_type is None or content_type.split(";")[0].strip() != "application/json":
        raise HTTPException(status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, "Content-Type must be application/json")
    consumed = bytearray()
    async for chunk in request.stream():
        if len(consumed) + len(chunk) > MAX_BATCH_BYTES:
            raise HTTPException(status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, "Request body too large")
        consumed.extend(chunk)
    try:
        return ImportRequest.model_validate_json(bytes(consumed))
    except (ValidationError, UnicodeError, RecursionError, ValueError):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "Request body does not match the import schema") from None


@router.post("/import")
async def import_batch(
    request: Request,
    response: Response,
    database: AsyncSession = Depends(get_session),
    principal: ImportPrincipal = Depends(require_import_token),
) -> dict:
    # Count authenticated attempts, including malformed batches, in a separate
    # committed transaction before body parsing. Import rechecks after parsing.
    await database.scalar(select(User.id).where(User.id == principal.account.id).with_for_update(key_share=True))
    current_hash = await database.scalar(select(AppleHealthToken.token_hash).where(AppleHealthToken.user_id == principal.account.id))
    if current_hash != principal.token_hash:
        raise HTTPException(401, "Authentication required")
    await reserve_import_attempt(database, principal.account.id)
    await database.commit()
    payload = await bounded_import_payload(request)
    response.headers["Cache-Control"] = "no-store"
    return await process_import(database, principal, payload)
