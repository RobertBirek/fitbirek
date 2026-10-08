from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, SecretStr, StrictBool, StrictInt, StrictStr, field_validator


class Strict(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ContextConsentsPatch(Strict):
    training: bool | None = None
    profile: bool | None = None
    weight: bool | None = None
    note: bool | None = None
    apple_health: bool | None = None

    @field_validator("training", "profile", "weight", "note", "apple_health")
    @classmethod
    def reject_explicit_null(cls, value):
        if value is None:
            raise ValueError("Context consent values cannot be null")
        return value


class SettingsPatch(Strict):
    expected_revision: int | None = Field(default=None, ge=0)
    context_policy_version: StrictInt | None = Field(default=None, ge=0)
    persona: str | None = Field(default=None, max_length=800)
    model_profile_key: str | None = Field(default=None, max_length=64)
    consent_text: bool | None = None
    consent_voice: bool | None = None
    memory: str | None = Field(default=None, max_length=2000)
    model: Literal["gpt-4.1-mini", "gpt-4.1-mini-2025-04-14"] | None = None
    tts_model: Literal["eleven_multilingual_v2"] | None = None
    stt_model: Literal["scribe_v2"] | None = None
    voice_id: str | None = Field(default=None, pattern=r"^[A-Za-z0-9]{1,64}$")
    context_consents: ContextConsentsPatch | None = None

    @field_validator("persona", mode="before")
    @classmethod
    def trim_persona(cls, value):
        return value.strip() if isinstance(value, str) else value

    @field_validator(
        "context_policy_version", "persona", "model_profile_key", "consent_text", "consent_voice", "memory",
        "model", "tts_model", "stt_model", "voice_id", "context_consents",
    )
    @classmethod
    def reject_explicit_null(cls, value):
        if value is None:
            raise ValueError("Settings values cannot be null")
        return value


class KeyInput(Strict):
    key: SecretStr

    @field_validator("key")
    @classmethod
    def bounded_key(cls, value):
        key = value.get_secret_value()
        if not 1 <= len(key) <= 512 or any(c.isspace() for c in key) or not key.isascii():
            raise ValueError("Invalid key")
        return value


class SessionInput(Strict):
    id: UUID


class RequestInput(Strict):
    request_id: UUID


class WeightSelection(Strict):
    source: Literal["measurement", "apple_health"]
    selection_id: StrictStr = Field(min_length=32, max_length=512, pattern=r"^[A-Za-z0-9_-]+$")

    @field_validator("selection_id")
    @classmethod
    def opaque_selector_only(cls, value):
        try:
            UUID(value)
        except ValueError:
            return value
        raise ValueError("Raw record identifiers are not context selections")


class NoteSelection(Strict):
    selection_id: StrictStr = Field(min_length=32, max_length=512, pattern=r"^[A-Za-z0-9_-]+$")

    @field_validator("selection_id")
    @classmethod
    def opaque_selector_only(cls, value):
        try:
            UUID(value)
        except ValueError:
            return value
        raise ValueError("Raw record identifiers are not context selections")


class ContextSelection(Strict):
    training: StrictBool = False
    profile: StrictBool = False
    apple_health: StrictBool = False
    weight: WeightSelection | None = None
    note: NoteSelection | None = None

    @field_validator("weight", "note")
    @classmethod
    def reject_explicit_null(cls, value):
        if value is None:
            raise ValueError("Context selections cannot be null")
        return value


class MessageInput(RequestInput):
    text: str = Field(min_length=1, max_length=2000)
    settings_revision: StrictInt | None = Field(default=None, ge=0)
    context: ContextSelection | None = None

    @field_validator("text")
    @classmethod
    def nonblank(cls, value):
        if not value.strip():
            raise ValueError("Empty message")
        return value.strip()
