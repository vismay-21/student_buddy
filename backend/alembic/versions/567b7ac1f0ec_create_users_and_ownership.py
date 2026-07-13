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
    # 1. Create users table
    op.create_table(
        'users',
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
    op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)

    # 2. Add user_id to semesters and update unique constraints
    op.add_column('semesters', sa.Column('user_id', sa.Uuid(), nullable=False))
    op.create_foreign_key('fk_semesters_user_id_users', 'semesters', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    
    # Try dropping various names of unique constraint on semester_number using DROP CONSTRAINT IF EXISTS
    # to avoid aborting the transaction in PostgreSQL when a constraint doesn't exist.
    # Otherwise fallback to try-except for SQLite/other databases.
    if op.get_bind().dialect.name == 'postgresql':
        op.execute("ALTER TABLE semesters DROP CONSTRAINT IF EXISTS uq_semesters_semester_number")
        op.execute("ALTER TABLE semesters DROP CONSTRAINT IF EXISTS semesters_semester_number_key")
        op.execute("ALTER TABLE semesters DROP CONSTRAINT IF EXISTS semesters_semester_number_uq")
    else:
        try:
            op.drop_constraint('uq_semesters_semester_number', 'semesters', type_='unique')
        except Exception:
            try:
                op.drop_constraint('semesters_semester_number_key', 'semesters', type_='unique')
            except Exception:
                pass
            
    op.create_unique_constraint('uq_semester_per_user', 'semesters', ['user_id', 'semester_number'])

    # 3. Add user_id to other tables
    # todos
    op.add_column('todos', sa.Column('user_id', sa.Uuid(), nullable=False))
    op.create_foreign_key('fk_todos_user_id_users', 'todos', 'users', ['user_id'], ['id'], ondelete='CASCADE')

    # app_settings
    op.add_column('app_settings', sa.Column('user_id', sa.Uuid(), nullable=False))
    op.create_foreign_key('fk_app_settings_user_id_users', 'app_settings', 'users', ['user_id'], ['id'], ondelete='CASCADE')
    op.create_unique_constraint('uq_app_settings_user_id', 'app_settings', ['user_id'])

    # review_queue
    op.add_column('review_queue', sa.Column('user_id', sa.Uuid(), nullable=False))
    op.create_foreign_key('fk_review_queue_user_id_users', 'review_queue', 'users', ['user_id'], ['id'], ondelete='CASCADE')

    # activity_logs
    op.add_column('activity_logs', sa.Column('user_id', sa.Uuid(), nullable=False))
    op.create_foreign_key('fk_activity_logs_user_id_users', 'activity_logs', 'users', ['user_id'], ['id'], ondelete='CASCADE')

    # notes_subjects
    op.add_column('notes_subjects', sa.Column('user_id', sa.Uuid(), nullable=False))
    op.create_foreign_key('fk_notes_subjects_user_id_users', 'notes_subjects', 'users', ['user_id'], ['id'], ondelete='CASCADE')


def downgrade() -> None:
    # Drop foreign keys and columns in reverse order
    try:
        op.drop_constraint('fk_notes_subjects_user_id_users', 'notes_subjects', type_='foreignkey')
        op.drop_column('notes_subjects', 'user_id')
    except Exception:
        pass

    try:
        op.drop_constraint('fk_activity_logs_user_id_users', 'activity_logs', type_='foreignkey')
        op.drop_column('activity_logs', 'user_id')
    except Exception:
        pass

    try:
        op.drop_constraint('fk_review_queue_user_id_users', 'review_queue', type_='foreignkey')
        op.drop_column('review_queue', 'user_id')
    except Exception:
        pass

    try:
        op.drop_constraint('uq_app_settings_user_id', 'app_settings', type_='unique')
        op.drop_constraint('fk_app_settings_user_id_users', 'app_settings', type_='foreignkey')
        op.drop_column('app_settings', 'user_id')
    except Exception:
        pass

    try:
        op.drop_constraint('fk_todos_user_id_users', 'todos', type_='foreignkey')
        op.drop_column('todos', 'user_id')
    except Exception:
        pass

    try:
        op.drop_constraint('uq_semester_per_user', 'semesters', type_='unique')
        op.drop_constraint('fk_semesters_user_id_users', 'semesters', type_='foreignkey')
        op.drop_column('semesters', 'user_id')
    except Exception:
        pass

    try:
        op.drop_index(op.f('ix_users_id'), table_name='users')
        op.drop_index(op.f('ix_users_email'), table_name='users')
        op.drop_table('users')
    except Exception:
        pass
