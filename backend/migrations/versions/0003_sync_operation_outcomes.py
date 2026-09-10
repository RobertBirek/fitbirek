"""Store accepted sync operation outcomes.

Revision ID: 0003
Revises: 0002
Create Date: 2026-09-09
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0003"
down_revision: Union[str, Sequence[str], None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "sync_operations",
        sa.Column("version", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "sync_operations",
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
    )
    op.alter_column("sync_operations", "version", server_default=None)
    op.alter_column("sync_operations", "updated_at", server_default=None)


def downgrade() -> None:
    op.drop_column("sync_operations", "updated_at")
    op.drop_column("sync_operations", "version")
