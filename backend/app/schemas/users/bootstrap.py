from datetime import datetime
from app.schemas.common import ApiResponse

class SyncBootstrapResponse(ApiResponse[dict]):
    sync_version: int
    generated_at: datetime
