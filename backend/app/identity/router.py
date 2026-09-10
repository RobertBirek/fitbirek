from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_session
from app.identity.schemas import LoginRequest, SessionResponse
from app.identity.service import (
    AuthenticatedSession,
    authenticate,
    issue_session,
    normalize_email,
    require_authenticated,
    revoke_session,
)
from app.security.csrf import require_csrf
from app.security.rate_limit import login_rate_limiter


router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/login", status_code=status.HTTP_204_NO_CONTENT)
async def login(
    payload: LoginRequest,
    request: Request,
    response: Response,
    database: AsyncSession = Depends(get_session),
) -> None:
    normalized_email = normalize_email(payload.email)
    client_ip = request.client.host if request.client is not None else "unknown"

    if not await login_rate_limiter.reserve_attempt(database, client_ip, normalized_email):
        raise HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Too many login attempts")

    account = await authenticate(database, normalized_email, payload.password)
    if account is None:
        await database.commit()
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    await login_rate_limiter.reset_failures(database, client_ip, normalized_email)
    issued_session = await issue_session(database, account)
    response.set_cookie(
        settings.session_cookie_name,
        issued_session.session_token,
        expires=issued_session.expires_at,
        httponly=True,
        secure=True,
        samesite="strict",
        path="/",
    )
    response.set_cookie(
        settings.csrf_cookie_name,
        issued_session.csrf_token,
        expires=issued_session.expires_at,
        secure=True,
        samesite="strict",
        path="/",
    )


@router.get("/session", response_model=SessionResponse)
async def current_account(
    authenticated: AuthenticatedSession = Depends(require_authenticated),
) -> SessionResponse:
    return SessionResponse(
        accountId=authenticated.account.id,
        email=authenticated.account.email,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    response: Response,
    database: AsyncSession = Depends(get_session),
    authenticated: AuthenticatedSession = Depends(require_csrf),
) -> None:
    await revoke_session(database, authenticated.session)
    response.delete_cookie(
        settings.session_cookie_name,
        httponly=True,
        secure=True,
        samesite="strict",
        path="/",
    )
    response.delete_cookie(
        settings.csrf_cookie_name,
        secure=True,
        samesite="strict",
        path="/",
    )
