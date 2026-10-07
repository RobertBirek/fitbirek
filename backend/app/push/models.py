from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, UniqueConstraint, Uuid, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models import Base


class PushSubscription(Base):
    __tablename__ = "push_subscriptions"

    installation_id: Mapped[UUID] = mapped_column(Uuid, primary_key=True)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    session_id: Mapped[UUID] = mapped_column(ForeignKey("sessions.id", ondelete="CASCADE"), index=True)
    endpoint: Mapped[str] = mapped_column(String(2048))
    endpoint_hash: Mapped[str] = mapped_column(String(64), unique=True)
    p256dh: Mapped[str] = mapped_column(String(87))
    auth: Mapped[str] = mapped_column(String(22))
    categories: Mapped[dict[str, bool]] = mapped_column(JSONB)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    vapid_public_key: Mapped[str] = mapped_column(String(87), server_default="")


class PushDelivery(Base):
    __tablename__ = "push_deliveries"
    __table_args__ = (UniqueConstraint("installation_id", "event_key"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    installation_id: Mapped[UUID] = mapped_column(ForeignKey("push_subscriptions.installation_id", ondelete="CASCADE"))
    event_key: Mapped[str] = mapped_column(String(160))
    category: Mapped[str] = mapped_column(String(20))
    payload: Mapped[dict] = mapped_column(JSONB)
    state: Mapped[str] = mapped_column(String(16), default="pending")
    attempts: Mapped[int] = mapped_column(Integer, default=0)
    available_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    last_status: Mapped[int | None] = mapped_column(Integer)


class PushTestLimit(Base):
    __tablename__ = "push_test_limits"
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    requested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class PushSenderState(Base):
    __tablename__ = "push_sender_state"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    public_key: Mapped[str] = mapped_column(String(87))
    heartbeat_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))


class PushIncident(Base):
    __tablename__ = "push_incidents"
    name: Mapped[str] = mapped_column(String(40), primary_key=True)
    failing: Mapped[bool] = mapped_column(Boolean)
    generation: Mapped[int] = mapped_column(Integer, default=0)
    observed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
