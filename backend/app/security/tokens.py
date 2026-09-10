import hmac
import secrets
from hashlib import sha256


def create_token() -> str:
    return secrets.token_urlsafe(32)


def hash_token(token: str) -> str:
    return sha256(token.encode()).hexdigest()


def token_matches(token: str | None, token_hash: str) -> bool:
    return token is not None and hmac.compare_digest(hash_token(token), token_hash)
