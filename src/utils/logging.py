"""
Logging utilities for BlockBench.
"""

import logging
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional


# Color codes for terminal output
COLORS = {
    "DEBUG": "\033[36m",     # Cyan
    "INFO": "\033[32m",      # Green
    "WARNING": "\033[33m",   # Yellow
    "ERROR": "\033[31m",     # Red
    "CRITICAL": "\033[35m",  # Magenta
    "RESET": "\033[0m"
}


class ColoredFormatter(logging.Formatter):
    """Formatter that adds colors to log levels."""

    def format(self, record):
        levelname = record.levelname
        if levelname in COLORS:
            record.levelname = f"{COLORS[levelname]}{levelname}{COLORS['RESET']}"
        return super().format(record)


def setup_logging(
    level: int = logging.INFO,
    log_file: Optional[Path] = None,
    name: str = "blockbench"
) -> logging.Logger:
    """
    Set up logging for BlockBench.

    Args:
        level: Logging level
        log_file: Optional file to write logs to
        name: Logger name

    Returns:
        Configured logger
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)

    # Clear existing handlers
    logger.handlers = []

    # Console handler with colors
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    console_format = ColoredFormatter(
        "%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%H:%M:%S"
    )
    console_handler.setFormatter(console_format)
    logger.addHandler(console_handler)

    # File handler (no colors)
    if log_file:
        log_file = Path(log_file)
        log_file.parent.mkdir(parents=True, exist_ok=True)

        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(level)
        file_format = logging.Formatter(
            "%(asctime)s | %(levelname)s | %(name)s | %(message)s",
            datefmt="%Y-%m-%d %H:%M:%S"
        )
        file_handler.setFormatter(file_format)
        logger.addHandler(file_handler)

    return logger


def get_logger(name: str = "blockbench") -> logging.Logger:
    """Get a logger instance."""
    return logging.getLogger(name)


class ProgressLogger:
    """
    Simple progress logger for batch operations.
    """

    def __init__(
        self,
        total: int,
        description: str = "Processing",
        logger: Optional[logging.Logger] = None
    ):
        self.total = total
        self.current = 0
        self.description = description
        self.logger = logger or get_logger()
        self.start_time = datetime.now()

    def update(self, n: int = 1) -> None:
        """Update progress by n items."""
        self.current += n
        self._log_progress()

    def _log_progress(self) -> None:
        """Log current progress."""
        percent = (self.current / self.total) * 100 if self.total > 0 else 0
        elapsed = datetime.now() - self.start_time

        if self.current > 0:
            eta = elapsed * (self.total - self.current) / self.current
            eta_str = str(eta).split('.')[0]
        else:
            eta_str = "..."

        self.logger.info(
            f"{self.description}: {self.current}/{self.total} "
            f"({percent:.1f}%) - ETA: {eta_str}"
        )

    def complete(self) -> None:
        """Mark progress as complete."""
        elapsed = datetime.now() - self.start_time
        self.logger.info(
            f"{self.description}: Complete! "
            f"Processed {self.total} items in {str(elapsed).split('.')[0]}"
        )
