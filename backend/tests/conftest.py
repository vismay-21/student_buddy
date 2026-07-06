import asyncio
from typing import AsyncGenerator, Generator
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession
from app.main import app
from app.core.database import get_db, engine


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def clean_database():
    """Truncates database tables before running the test suite to ensure a clean state."""
    # Dispose of engine first to bind to the session loop
    await engine.dispose()
    async with engine.begin() as conn:
        await conn.execute(
            text("TRUNCATE TABLE semesters, attendance_settings, subjects, notes_subjects, notes_sections, notes_resources, lecture_templates, lecture_instances, holidays, todos, review_queue, activity_logs RESTART IDENTITY CASCADE;")
        )
        await conn.execute(
            text(
                "INSERT INTO app_settings (settings_id, theme_mode, finance_enabled, morning_digest_enabled, night_digest_enabled, attendance_prompt_enabled, created_at, updated_at) "
                "VALUES (1, 'SYSTEM', false, true, true, true, NOW(), NOW()) "
                "ON CONFLICT (settings_id) DO NOTHING;"
            )
        )
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Provides a transaction-isolated database session for tests.
    Commits are redirected to flushes so that the entire test runs in a single transaction
    which is rolled back at the end of the test.
    """
    # Dispose engine to ensure connection pool binds to the current test event loop
    await engine.dispose()
    
    connection = await engine.connect()
    transaction = await connection.begin()
    
    # Create session bound to this connection
    session = AsyncSession(bind=connection, expire_on_commit=False)
    
    # Mock commit to prevent closing the transaction, keeping it flush-only
    async def mock_commit():
        await session.flush()
        
    session.commit = mock_commit

    try:
        yield session
    finally:
        await session.close()
        await transaction.rollback()
        await connection.close()
        # Dispose of engine to release connection pool bound to current event loop
        await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Provides an HTTP test client that uses the transaction-isolated database session."""
    async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    try:
        async with AsyncClient(
            transport=ASGITransport(app=app),
            base_url="http://test"
        ) as ac:
            yield ac
    finally:
        app.dependency_overrides.clear()
