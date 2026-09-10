"""Add durable login failure rate limiting.

Revision ID: 0002
Revises: 0001
Create Date: 2026-09-08
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "0002"
down_revision: Union[str, Sequence[str], None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "login_attempts",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("client_ip", sa.String(length=45), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=False),
        sa.Column("failed_at", postgresql.ARRAY(sa.DateTime(timezone=True)), nullable=False),
        sa.Column("last_failed_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("client_ip", "email"),
    )
    op.create_index("ix_login_attempts_last_failed_at", "login_attempts", ["last_failed_at"])


def downgrade() -> None:
    op.drop_index("ix_login_attempts_last_failed_at", table_name="login_attempts")
    op.drop_table("login_attempts")
