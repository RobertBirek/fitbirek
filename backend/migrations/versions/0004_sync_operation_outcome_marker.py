"""Mark sync operations with durable accepted outcomes.

Revision ID: 0004
Revises: 0003
Create Date: 2026-09-09
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0004"
down_revision: Union[str, Sequence[str], None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "sync_operations",
        sa.Column("outcome_known", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.execute("UPDATE sync_operations SET outcome_known = TRUE WHERE version > 0")
    op.alter_column("sync_operations", "outcome_known", server_default=None)


def downgrade() -> None:
    op.drop_column("sync_operations", "outcome_known")
