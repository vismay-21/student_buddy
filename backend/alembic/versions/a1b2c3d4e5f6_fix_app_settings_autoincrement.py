"""fix_app_settings_autoincrement

Revision ID: a1b2c3d4e5f6
Revises: 317f52aca7c2
Create Date: 2026-07-14 07:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = '317f52aca7c2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Drop the singleton CHECK constraint (settings_id = 1) which is no
    # longer valid in the multi-tenant design where each user has their own row.
    if op.get_bind().dialect.name == 'postgresql':
        op.execute("ALTER TABLE app_settings DROP CONSTRAINT IF EXISTS app_settings_single_row")

        # Convert settings_id to a SERIAL (auto-incrementing) primary key.
        op.execute("CREATE SEQUENCE IF NOT EXISTS app_settings_settings_id_seq")
        op.execute(
            "ALTER TABLE app_settings ALTER COLUMN settings_id "
            "SET DEFAULT nextval('app_settings_settings_id_seq')"
        )
        op.execute(
            "ALTER SEQUENCE app_settings_settings_id_seq OWNED BY app_settings.settings_id"
        )
    else:
        # SQLite handles autoincrement natively via SQLAlchemy create_all in tests.
        pass


def downgrade() -> None:
    if op.get_bind().dialect.name == 'postgresql':
        op.execute(
            "ALTER TABLE app_settings ALTER COLUMN settings_id DROP DEFAULT"
        )
        op.execute("DROP SEQUENCE IF EXISTS app_settings_settings_id_seq")
        op.execute(
            "ALTER TABLE app_settings ADD CONSTRAINT app_settings_single_row "
            "CHECK (settings_id = 1)"
        )
