from datetime import date, datetime
from uuid import UUID, uuid4
from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Integer, JSON, String, Text, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column
from app.models import Base
from app.mentor.catalog import DEFAULT_PERSONA

class MentorSettings(Base):
    __tablename__ = "mentor_settings"
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    consent_text: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_voice: Mapped[bool] = mapped_column(Boolean, default=False)
    memory: Mapped[str] = mapped_column(Text, default="")
    model: Mapped[str] = mapped_column(String(64), default="gpt-4.1-mini-2025-04-14")
    persona: Mapped[str] = mapped_column(Text, default=DEFAULT_PERSONA)
    model_profile_key: Mapped[str | None] = mapped_column(String(64), nullable=True)
    context_policy_version: Mapped[int] = mapped_column(Integer, default=0)
    context_generation_digest: Mapped[str] = mapped_column(String(64), default="")
    consent_context_training: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_context_profile: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_context_weight: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_context_note: Mapped[bool] = mapped_column(Boolean, default=False)
    consent_context_apple_health: Mapped[bool] = mapped_column(Boolean, default=False)
    tts_model: Mapped[str] = mapped_column(String(64), default="eleven_multilingual_v2")
    stt_model: Mapped[str] = mapped_column(String(64), default="scribe_v2")
    voice_id: Mapped[str] = mapped_column(String(64), default="JBFqnCBsd6RMkjVDRZzb")
    voices: Mapped[list] = mapped_column(JSON, default=list)
    revision: Mapped[int] = mapped_column(Integer, default=0)
class MentorCredential(Base):
    __tablename__ = "mentor_credentials"
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    provider: Mapped[str] = mapped_column(String(16), primary_key=True)
    encrypted_key: Mapped[bytes] = mapped_column()
class MentorSession(Base):
    __tablename__ = "mentor_sessions"
    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
class MentorMessage(Base):
    __tablename__ = "mentor_messages"
    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    session_id: Mapped[UUID] = mapped_column(ForeignKey("mentor_sessions.id", ondelete="CASCADE"), index=True)
    role: Mapped[str] = mapped_column(String(16))
    text: Mapped[str] = mapped_column(Text)
    proposal: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
class MentorRequest(Base):
    __tablename__ = "mentor_requests"
    __table_args__ = (UniqueConstraint("user_id", "request_id"),)
    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    request_id: Mapped[UUID] = mapped_column(Uuid)
    kind: Mapped[str] = mapped_column(String(16))
    payload_digest: Mapped[str] = mapped_column(String(64))
    session_id: Mapped[UUID | None] = mapped_column(Uuid)
    subject_id: Mapped[UUID | None] = mapped_column(Uuid)
    state: Mapped[str] = mapped_column(String(16), default="reserved")
    response: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
class MentorUsage(Base):
    __tablename__ = "mentor_usage"
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    day: Mapped[date] = mapped_column(Date, primary_key=True)
    requests: Mapped[int] = mapped_column(Integer, default=0)
    tts_chars: Mapped[int] = mapped_column(Integer, default=0)
    stt_bytes: Mapped[int] = mapped_column(Integer, default=0)
    stt_seconds: Mapped[int] = mapped_column(Integer, default=0)
    input_tokens: Mapped[int] = mapped_column(Integer, default=0)
    output_tokens: Mapped[int] = mapped_column(Integer, default=0)
class MentorLease(Base):
    __tablename__ = "mentor_leases"
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    request_id: Mapped[UUID] = mapped_column(Uuid)
