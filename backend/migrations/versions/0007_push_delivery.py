"""Durable push outbox, rate limits, sender heartbeat and incident transitions."""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "0007"
down_revision = "0006"
branch_labels = depends_on = None


def upgrade():
    op.add_column("push_subscriptions", sa.Column("vapid_public_key", sa.String(87), nullable=False, server_default=""))
    op.create_table("push_deliveries",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("installation_id", sa.Uuid(), sa.ForeignKey("push_subscriptions.installation_id", ondelete="CASCADE"), nullable=False),
        sa.Column("event_key", sa.String(160), nullable=False),
        sa.Column("category", sa.String(20), nullable=False),
        sa.Column("payload", JSONB(), nullable=False),
        sa.Column("state", sa.String(16), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False),
        sa.Column("available_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_status", sa.Integer()),
        sa.UniqueConstraint("installation_id", "event_key"),
    )
    op.create_index("ix_push_deliveries_available_at", "push_deliveries", ["available_at"])
    op.create_index("ix_push_deliveries_expires_at", "push_deliveries", ["expires_at"])
    op.create_table("push_test_limits",
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("requested_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table("push_sender_state",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("public_key", sa.String(87), nullable=False),
        sa.Column("heartbeat_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_table("push_incidents",
        sa.Column("name", sa.String(40), primary_key=True),
        sa.Column("failing", sa.Boolean(), nullable=False),
        sa.Column("generation", sa.Integer(), nullable=False),
        sa.Column("observed_at", sa.DateTime(timezone=True), nullable=False),
    )


def downgrade():
    for name in ("push_incidents", "push_sender_state", "push_test_limits", "push_deliveries"):
        op.drop_table(name)
    op.drop_column("push_subscriptions", "vapid_public_key")
