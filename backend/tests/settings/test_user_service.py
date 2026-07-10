import pytest
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.services.users.user import UserService
from app.models.user import User
from app.models.settings.app_settings import AppSettings

pytestmark = pytest.mark.asyncio


async def test_initialize_user_new(db_session: AsyncSession) -> None:
    service = UserService(db_session)
    user_id = uuid.uuid4()
    email = "new_user_test@example.com"
    
    # 1. Initialize user for the first time
    user = await service.initialize_user(user_id, email)
    assert user.id == user_id
    assert user.email == email
    
    # Verify settings are also created
    res = await db_session.execute(select(AppSettings).where(AppSettings.user_id == user_id))
    settings = res.scalar_one_or_none()
    assert settings is not None
    assert settings.user_id == user_id


async def test_initialize_user_idempotent(db_session: AsyncSession) -> None:
    service = UserService(db_session)
    user_id = uuid.uuid4()
    email = "idempotent_test@example.com"
    
    # 1. First initialization
    user1 = await service.initialize_user(user_id, email)
    
    # 2. Second initialization (idempotent)
    user2 = await service.initialize_user(user_id, email)
    
    assert user1.id == user2.id
    assert user1.email == user2.email


async def test_initialize_user_stale_collision(db_session: AsyncSession) -> None:
    service = UserService(db_session)
    email = "collision_test@example.com"
    
    old_user_id = uuid.uuid4()
    new_user_id = uuid.uuid4()
    
    # 1. Initialize with old UUID
    await service.initialize_user(old_user_id, email)
    
    # Verify old user exists in DB
    res = await db_session.execute(select(User).where(User.id == old_user_id))
    assert res.scalar_one_or_none() is not None
    
    # 2. Initialize with new UUID (stale email collision)
    new_user = await service.initialize_user(new_user_id, email)
    assert new_user.id == new_user_id
    assert new_user.email == email
    
    # Verify old user is deleted
    res_old = await db_session.execute(select(User).where(User.id == old_user_id))
    assert res_old.scalar_one_or_none() is None
    
    # Verify new user settings exist
    res_settings = await db_session.execute(select(AppSettings).where(AppSettings.user_id == new_user_id))
    assert res_settings.scalar_one_or_none() is not None


async def test_initialize_user_email_update(db_session: AsyncSession) -> None:
    service = UserService(db_session)
    user_id = uuid.uuid4()
    old_email = "old_email@example.com"
    new_email = "new_email@example.com"
    
    # 1. Initialize user
    await service.initialize_user(user_id, old_email)
    
    # 2. Re-initialize with new email
    updated_user = await service.initialize_user(user_id, new_email)
    assert updated_user.id == user_id
    assert updated_user.email == new_email
