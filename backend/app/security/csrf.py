from fastapi import Depends, HTTPException, Request, status

from app.config import settings
from app.identity.service import AuthenticatedSession, require_authenticated
from app.security.tokens import token_matches


async def require_csrf(
    request: Request,
    authenticated: AuthenticatedSession = Depends(require_authenticated),
) -> AuthenticatedSession:
    if request.headers.get("origin") != settings.trusted_origin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Untrusted origin")

    if not token_matches(request.headers.get("x-csrf-token"), authenticated.session.csrf_hash):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Invalid CSRF token")

    return authenticated
