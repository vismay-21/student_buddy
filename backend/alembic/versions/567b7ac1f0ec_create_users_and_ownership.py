"""create_users_and_ownership

Revision ID: 567b7ac1f0ec
Revises: 905f6a12361e
Create Date: 2026-07-10 12:47:10.217565

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '567b7ac1f0ec'
down_revision: Union[str, None] = '905f6a12361e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
