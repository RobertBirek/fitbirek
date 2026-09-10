from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import re

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError
from fastapi import Depends, HTTPException, Request, status
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_session
from app.identity.models import Session, User
from app.security.tokens import create_token, hash_token, token_matches


password_hasher = PasswordHasher()
dummy_password_hash = password_hasher.hash("FitBirek dummy password")
session_issue_attempts = 3
email_pattern = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class InitialAccountAlreadyExistsError(Exception):
    pass


@dataclass
class AuthenticatedSession:
    account: User
    session: Session


@dataclass
class IssuedSession:
    session_token: str
    csrf_token: str
    expires_at: datetime


def normalize_email(email: str) -> str:
    return email.strip().casefold()


def validate_and_normalize_email(email: str) -> str:
    normalized_email = normalize_email(email)
    if len(normalized_email) > 320 or not email_pattern.fullmatch(normalized_email):
        raise ValueError("Email must be a valid email address")
    return normalized_email


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


async def create_initial_account(database: AsyncSession, email: str, password: str) -> User:
    normalized_email = validate_and_normalize_email(email)
    async with database.begin():
        await database.execute(text("LOCK TABLE users IN ACCESS EXCLUSIVE MODE"))
        if await database.scalar(select(User.id).limit(1)) is not None:
            raise InitialAccountAlreadyExistsError
        account = User(email=normalized_email, password_hash=hash_password(password))
        database.add(account)
    return account


def password_is_valid(password_hash: str, password: str) -> bool:
    try:
        return password_hasher.verify(password_hash, password)
    except (InvalidHashError, VerificationError):
        return False


async def authenticate(database: AsyncSession, email: str, password: str) -> User | None:
    account = await database.scalar(select(User).where(User.email == email))
    if account is None:
        password_is_valid(dummy_password_hash, password)
        return None
    if not password_is_valid(account.password_hash, password):
        return None
    return account


async def issue_session(database: AsyncSession, account: User) -> IssuedSession:
    account_id = account.id
    for _ in range(session_issue_attempts):
        session_token = create_token()
        csrf_token = create_token()
        expires_at = datetime.now(timezone.utc) + timedelta(hours=settings.session_lifetime_hours)
        database.add(
            Session(
                user_id=account_id,
                token_hash=hash_token(session_token),
                csrf_hash=hash_token(csrf_token),
                expires_at=expires_at,
            )
        )
        try:
            await database.commit()
        except IntegrityError:
            await database.rollback()
        else:
            return IssuedSession(session_token=session_token, csrf_token=csrf_token, expires_at=expires_at)
    raise RuntimeError("Unable to issue a unique session token")


async def authenticated_session(database: AsyncSession, session_token: str | None) -> AuthenticatedSession | None:
    if session_token is None:
        return None

    result = await database.execute(
        select(Session, User).join(User, User.id == Session.user_id).where(Session.token_hash == hash_token(session_token))
    )
    row = result.one_or_none()
    if row is None:
        return None

    stored_session, account = row
    if not token_matches(session_token, stored_session.token_hash):
        return None
    if stored_session.revoked_at is not None or stored_session.expires_at <= datetime.now(timezone.utc):
        return None
    return AuthenticatedSession(account=account, session=stored_session)


async def revoke_session(database: AsyncSession, active_session: Session) -> None:
    active_session.revoked_at = datetime.now(timezone.utc)
    await database.commit()


async def require_authenticated(
    request: Request,
    database: AsyncSession = Depends(get_session),
) -> AuthenticatedSession:
    active_session = await authenticated_session(database, request.cookies.get(settings.session_cookie_name))
    if active_session is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required")
    return active_session
