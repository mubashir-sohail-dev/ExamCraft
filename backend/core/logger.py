# core/logger.py
"""
ExamCraft AI - Application Logging Configuration
Configures structured application logging without shadowing Python's built-in `logging` module.
"""
import logging
import sys


def setup_logging(level: int = logging.INFO) -> None:
    """Configures structured application-wide logging."""
    log_format = (
        "%(asctime)s | %(levelname)-8s | %(name)s:%(funcName)s:%(lineno)d - %(message)s"
    )
    logging.basicConfig(
        level=level,
        format=log_format,
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    # Silence noisy third-party loggers if necessary
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("qdrant_client").setLevel(logging.INFO)


def get_logger(name: str) -> logging.Logger:
    """Returns a named logger instance."""
    return logging.getLogger(name)
