"""Private mentor state, encrypted credentials and durable usage reservations."""
from alembic import op
import sqlalchemy as sa

revision = "0009"
down_revision = "0008"
branch_labels = depends_on = None


def user_column(primary_key=False):
    return sa.Column("user_id", sa.Uuid(), sa.ForeignKey("users.id", ondelete="CASCADE"),
                     primary_key=primary_key, nullable=False)


def upgrade():
    op.create_table("mentor_settings", user_column(True),
        sa.Column("consent_text", sa.Boolean(), nullable=False),
        sa.Column("consent_voice", sa.Boolean(), nullable=False),
        sa.Column("memory", sa.Text(), nullable=False),
        sa.Column("model", sa.String(64), nullable=False),
        sa.Column("tts_model", sa.String(64), nullable=False),
        sa.Column("stt_model", sa.String(64), nullable=False),
        sa.Column("voice_id", sa.String(64), nullable=False),
        sa.Column("voices", sa.JSON(), nullable=False),
        sa.Column("revision", sa.Integer(), nullable=False))
    op.create_table("mentor_credentials", user_column(True),
        sa.Column("provider", sa.String(16), primary_key=True),
        sa.Column("encrypted_key", sa.LargeBinary(), nullable=False))
    op.create_table("mentor_sessions",
        sa.Column("id", sa.Uuid(), primary_key=True), user_column(),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True)))
    op.create_index("ix_mentor_sessions_user_id", "mentor_sessions", ["user_id"])
    op.create_table("mentor_messages",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("session_id", sa.Uuid(), sa.ForeignKey("mentor_sessions.id", ondelete="CASCADE"), nullable=False),
        sa.Column("role", sa.String(16), nullable=False),
        sa.Column("text", sa.Text(), nullable=False),
        sa.Column("proposal", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False))
    op.create_index("ix_mentor_messages_session_id", "mentor_messages", ["session_id"])
    op.create_table("mentor_requests",
        sa.Column("id", sa.Uuid(), primary_key=True), user_column(),
        sa.Column("request_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.String(16), nullable=False),
        sa.Column("payload_digest", sa.String(64), nullable=False),
        sa.Column("session_id", sa.Uuid()),
        sa.Column("subject_id", sa.Uuid()),
        sa.Column("state", sa.String(16), nullable=False),
        sa.Column("response", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("user_id", "request_id"))
    op.create_table("mentor_usage", user_column(True),
        sa.Column("day", sa.Date(), primary_key=True),
        *(sa.Column(name, sa.Integer(), nullable=False) for name in (
            "requests", "tts_chars", "stt_bytes", "stt_seconds", "output_tokens")))
    op.create_table("mentor_leases", user_column(True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("request_id", sa.Uuid(), nullable=False))


def downgrade():
    for table in ("mentor_leases", "mentor_usage", "mentor_requests", "mentor_messages",
                  "mentor_sessions", "mentor_credentials", "mentor_settings"):
        op.drop_table(table)
