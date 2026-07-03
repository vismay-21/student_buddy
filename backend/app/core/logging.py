import logging
import sys
from app.core.config import settings


def setup_logging() -> None:
    # Clear existing handlers to prevent duplicate logs
    logging.root.handlers = []

    # Get log level from config
    log_level_str = settings.LOG_LEVEL.upper()
    log_level = getattr(logging, log_level_str, logging.INFO)

    # Format pattern
    log_format = "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"

    # Configure root logger
    logging.basicConfig(
        level=log_level,
        format=log_format,
        datefmt=date_format,
        handlers=[logging.StreamHandler(sys.stdout)]
    )

    # Configure specific logs to avoid noise
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
