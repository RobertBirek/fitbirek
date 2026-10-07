"""Apple Health import tokens, durable rate limits and step replay digests."""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import ARRAY

revision = "0008"
down_revision = "0007"
branch_labels = depends_on = None


def upgrade():
    op.create_table(
        "apple_health_tokens",
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("token_hash", sa.String(64), nullable=True, unique=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_import_at", sa.DateTime(timezone=True)),
    )
    op.create_index("ix_apple_health_tokens_token_hash", "apple_health_tokens", ["token_hash"])
    op.create_table(
        "apple_health_import_limits",
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("window_started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("import_count", sa.Integer(), nullable=False),
        sa.Column("attempted_at", ARRAY(sa.DateTime(timezone=True)), nullable=False),
    )
    op.create_table(
        "apple_health_step_digests",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("day", sa.Date(), nullable=False),
        sa.Column("value_digest", sa.String(64), nullable=False),
        sa.UniqueConstraint("user_id", "day", "value_digest"),
    )


def downgrade():
    op.drop_index("ix_apple_health_tokens_token_hash", table_name="apple_health_tokens")
    for name in ("apple_health_step_digests", "apple_health_import_limits", "apple_health_tokens"):
        op.drop_table(name)
