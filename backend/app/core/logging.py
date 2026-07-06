import logging
import sys
from app.core.config import settings


def setup_logging(enable_file_logging: bool = False) -> None:
    # Clear existing handlers to prevent duplicate logs
    logging.root.handlers = []

    # Get log level from config
    log_level_str = settings.LOG_LEVEL.upper()
    log_level = getattr(logging, log_level_str, logging.INFO)

    # Format pattern
    log_format = "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"

    # Base handlers list (stdout by default)
    handlers: list[logging.Handler] = [logging.StreamHandler(sys.stdout)]

    # Future extension: Easy toggle/enablement of file logging
    if enable_file_logging:
        import os
        from logging.handlers import RotatingFileHandler
        # Ensure log directory exists
        log_dir = "logs"
        os.makedirs(log_dir, exist_ok=True)
        file_handler = RotatingFileHandler(
            os.path.join(log_dir, "backend.log"),
            maxBytes=10 * 1024 * 1024,  # 10MB limit
            backupCount=5,
            encoding="utf-8"
        )
        file_formatter = logging.Formatter(log_format, datefmt=date_format)
        file_handler.setFormatter(file_formatter)
        handlers.append(file_handler)

    # Configure root logger
    logging.basicConfig(
        level=log_level,
        format=log_format,
        datefmt=date_format,
        handlers=handlers
    )

    # Configure specific logs to avoid noise
    logging.getLogger("uvicorn.error").setLevel(logging.INFO)
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
