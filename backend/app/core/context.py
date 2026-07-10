import contextvars
import uuid
from typing import Optional

request_user_id: contextvars.ContextVar[Optional[uuid.UUID]] = contextvars.ContextVar("request_user_id", default=None)
