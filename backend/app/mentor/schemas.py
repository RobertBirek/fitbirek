from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, SecretStr, field_validator


class Strict(BaseModel):
    model_config = ConfigDict(extra="forbid")


class SettingsUpdate(Strict):
    consent_text: bool
    consent_voice: bool
    memory: str = Field(max_length=2000)
    model: Literal["gpt-4.1-mini", "gpt-4.1-mini-2025-04-14"]
    tts_model: Literal["eleven_multilingual_v2"]
    stt_model: Literal["scribe_v2"]
    voice_id: str = Field(pattern=r"^[A-Za-z0-9]{1,64}$")


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


class MessageInput(RequestInput):
    text: str = Field(min_length=1, max_length=2000)

    @field_validator("text")
    @classmethod
    def nonblank(cls, value):
        if not value.strip():
            raise ValueError("Empty message")
        return value.strip()
