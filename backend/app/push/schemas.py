import base64
import re
from urllib.parse import urlsplit

from pydantic import BaseModel, ConfigDict, Field, StrictBool, field_validator


# Exact hosts only: expanding this list requires a provider/security review.
PUSH_HOSTS = frozenset({
    "fcm.googleapis.com",
    "updates.push.services.mozilla.com",
    "web.push.apple.com",
})


def validate_endpoint(value: str) -> str:
    """Validate stored endpoint syntax; this performs no network requests.

    A future sender MUST additionally enforce public DNS/IPs at connection
    time and refuse redirects. This allowlist alone is not a safe transport.
    """
    if not value.isascii() or re.search(r"[\s\\\x00-\x1f\x7f]|%(?:0[0-9a-f]|1[0-9a-f]|7f)", value, re.I):
        raise ValueError("Invalid push endpoint")
    try:
        url = urlsplit(value)
        valid = (
            url.scheme == "https"
            and url.netloc in PUSH_HOSTS
            and url.hostname in PUSH_HOSTS
            and url.path not in ("", "/")
            and not url.fragment
            and "#" not in value
        )
    except ValueError:
        valid = False
    if not valid:
        raise ValueError("Unsupported push endpoint")
    return value


def decode_key(value: str, size: int) -> bytes:
    if not re.fullmatch(r"[A-Za-z0-9_-]+", value):
        raise ValueError("Invalid push key encoding")
    raw = base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))
    if len(raw) != size or base64.urlsafe_b64encode(raw).decode().rstrip("=") != value:
        raise ValueError("Invalid push key length or encoding")
    return raw


class PushKeys(BaseModel):
    model_config = ConfigDict(extra="forbid")

    p256dh: str = Field(min_length=87, max_length=87)
    auth: str = Field(min_length=22, max_length=22)

    @field_validator("p256dh")
    @classmethod
    def public_key(cls, value: str) -> str:
        raw = decode_key(value, 65)
        x, y = int.from_bytes(raw[1:33]), int.from_bytes(raw[33:])
        prime = 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffff
        b = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b
        if raw[0] != 4 or x >= prime or y >= prime or (y * y - (x * x * x - 3 * x + b)) % prime:
            raise ValueError("Invalid P-256 public key")
        return value

    @field_validator("auth")
    @classmethod
    def auth_key(cls, value: str) -> str:
        decode_key(value, 16)
        return value


class PushCategories(BaseModel):
    model_config = ConfigDict(extra="forbid")

    karate: StrictBool = False
    training: StrictBool = False
    mood: StrictBool = False
    operations: StrictBool = False


class SubscriptionRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    endpoint: str = Field(max_length=2048)
    keys: PushKeys
    categories: PushCategories = Field(default_factory=PushCategories)
    vapidPublicKey: str | None = Field(default=None, max_length=87)

    @field_validator("endpoint")
    @classmethod
    def endpoint_url(cls, value: str) -> str:
        return validate_endpoint(value)
