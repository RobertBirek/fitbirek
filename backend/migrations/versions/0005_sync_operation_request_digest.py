"""Store accepted sync operation request digests.

Revision ID: 0005
Revises: 0004
Create Date: 2026-09-09
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "0005"
down_revision: Union[str, Sequence[str], None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("sync_operations", sa.Column("request_digest", sa.String(length=64), nullable=True))


def downgrade() -> None:
    op.drop_column("sync_operations", "request_digest")
