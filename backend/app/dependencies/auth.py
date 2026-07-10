from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security_scheme = HTTPBearer(auto_error=False)

async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security_scheme)
) -> dict | None:
    """
    Stub dependency for future JWT authentication.
    In Sprint 13, this will decode the token and return user details.
    Currently it acts as a pass-through returning a mock user dict if a bearer token is present.
    """
    if not credentials:
        return None
    # Mock payload
    return {"sub": "mock-user-id", "role": "student"}
