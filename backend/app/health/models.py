from datetime import date, datetime
from uuid import UUID, uuid4

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import ARRAY

from app.models import Base


class AppleHealthToken(Base):
    """Hashed import token for the Apple Health integration, one per account.

    The cleartext token is only returned to the client when issued. The
    server stores SHA-256(token) exclusively, mirroring session token
    handling.
    """

    __tablename__ = "apple_health_tokens"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    token_hash: Mapped[str | None] = mapped_column(String(64), unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    last_import_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class AppleHealthImportLimit(Base):
    """Durable per-token import rate window; survives API restarts."""

    __tablename__ = "apple_health_import_limits"

    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    window_started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    import_count: Mapped[int] = mapped_column(Integer, default=0)
    attempted_at: Mapped[list[datetime]] = mapped_column(ARRAY(DateTime(timezone=True)), default=list)


class AppleHealthStepDigest(Base):
    """Durable ledger of accepted step totals, blocking older replays."""

    __tablename__ = "apple_health_step_digests"
    __table_args__ = (UniqueConstraint("user_id", "day", "value_digest"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    day: Mapped[date] = mapped_column(Date)
    value_digest: Mapped[str] = mapped_column(String(64))
