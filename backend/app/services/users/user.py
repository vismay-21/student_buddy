import logging
import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from app.models.settings.app_settings import AppSettings, ThemeMode

logger = logging.getLogger(__name__)


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def initialize_user(self, user_id: uuid.UUID, email: str) -> User:
        """
        Idempotently initializes a user in the local database.
        1. Creates the user record if it doesn't exist.
        2. Creates the default AppSettings if they don't exist.
        """
        # 1. Get or create User
        stmt = select(User).where(User.id == user_id)
        res = await self.db.execute(stmt)
        user = res.scalar_one_or_none()
        
        if not user:
            # Check if a user with the same email already exists (stale user from previous signup)
            if email:
                stmt_email = select(User).where(User.email == email)
                res_email = await self.db.execute(stmt_email)
                stale_user = res_email.scalar_one_or_none()
                if stale_user:
                    logger.info(f"User with email {email} exists under different ID {stale_user.id}. Deleting stale user record.")
                    await self.db.delete(stale_user)
                    await self.db.flush()
            
            logger.info(f"Initializing new user {user_id} ({email})")
            user = User(id=user_id, email=email)
            self.db.add(user)
            await self.db.flush()
        else:
            # Update email if it changed in Supabase
            if email and user.email != email:
                stmt_email = select(User).where(User.email == email, User.id != user_id)
                res_email = await self.db.execute(stmt_email)
                conflicting_user = res_email.scalar_one_or_none()
                if conflicting_user:
                    logger.info(f"Deleting conflicting stale user {conflicting_user.id} with email {email}")
                    await self.db.delete(conflicting_user)
                    await self.db.flush()
                
                logger.info(f"Updating email for user {user_id} to {email}")
                user.email = email
                await self.db.flush()
            else:
                logger.info(f"User {user_id} already exists, checking settings...")
            
        # 2. Get or create AppSettings
        stmt_settings = select(AppSettings).where(AppSettings.user_id == user_id)
        res_settings = await self.db.execute(stmt_settings)
        settings = res_settings.scalar_one_or_none()
        
        if not settings:
            logger.info(f"Creating default app settings for user {user_id}")
            settings = AppSettings(
                user_id=user_id,
                theme_mode=ThemeMode.SYSTEM,
                finance_enabled=False,
                morning_digest_enabled=True,
                night_digest_enabled=True,
                attendance_prompt_enabled=True
            )
            self.db.add(settings)
            await self.db.flush()
            
        await self.db.commit()
        return user
