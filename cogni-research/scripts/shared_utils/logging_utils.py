"""
Enhanced Logging Utilities for Claude Code Plugins
==================================================

Cross-platform logging with DEBUG_MODE and QUIET_MODE awareness.
Replaces enhanced-logging.sh with identical functionality.

Environment Variables:
    DEBUG_MODE    Controls stderr verbosity (true/false, default: false)
                  - true: All levels to stderr (ERROR, WARN, INFO, DEBUG, TRACE)
                  - false: Only ERROR and WARN to stderr
    QUIET_MODE    Suppresses ALL stderr output when true (default: false)
                  - true: No stderr output at all (for JSON mode)
                  - false: Normal DEBUG_MODE-based output
    LOG_FILE      Optional file path for log output (if unset, skip file writes)

Functions:
    log_conditional(level, message) - DEBUG_MODE-aware logging
    log_phase(phase_name, status)   - Phase transition logging
    log_metric(name, value, unit)   - Structured performance metrics
    get_timestamp()                 - ISO 8601 UTC timestamp

Example:
    from logging_utils import log_conditional, log_phase, log_metric

    log_phase("Entity Creation", "start")
    log_conditional("INFO", "Processing 10 entities")
    log_metric("entities_created", 10, "count")
    log_phase("Entity Creation", "complete")
"""

import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

__version__ = "1.0.0"

# Cache environment variable lookups
_debug_mode: Optional[bool] = None
_quiet_mode: Optional[bool] = None


def _get_debug_mode() -> bool:
    """Get DEBUG_MODE environment variable (cached)."""
    global _debug_mode
    if _debug_mode is None:
        _debug_mode = os.environ.get("DEBUG_MODE", "false").lower() == "true"
    return _debug_mode


def _get_quiet_mode() -> bool:
    """Get QUIET_MODE environment variable (cached)."""
    global _quiet_mode
    if _quiet_mode is None:
        _quiet_mode = os.environ.get("QUIET_MODE", "false").lower() == "true"
    return _quiet_mode


def reset_mode_cache() -> None:
    """Reset cached DEBUG_MODE and QUIET_MODE values.

    Call this if environment variables change during execution.
    """
    global _debug_mode, _quiet_mode
    _debug_mode = None
    _quiet_mode = None


def get_timestamp() -> str:
    """Get current timestamp in ISO 8601 UTC format.

    Returns:
        Timestamp string like "2025-12-19T10:30:45Z"
    """
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _should_output_to_stderr(level: str) -> bool:
    """Determine if level should output to stderr based on DEBUG_MODE.

    Args:
        level: Log level (ERROR, WARN, INFO, DEBUG, TRACE)

    Returns:
        True if level should be output to stderr
    """
    # If DEBUG_MODE is true, output all levels
    if _get_debug_mode():
        return True

    # If DEBUG_MODE is false, only output ERROR and WARN
    return level.upper() in ("ERROR", "WARN")


def log_conditional(level: str, message: str) -> None:
    """Log with conditional stderr output based on DEBUG_MODE.

    Always writes to LOG_FILE if set.
    Conditionally writes to stderr based on DEBUG_MODE and level.

    Args:
        level: Log level (ERROR, WARN, INFO, DEBUG, TRACE)
        message: Log message

    Example:
        log_conditional("INFO", "Processing started")
        log_conditional("ERROR", "Failed to process file")
    """
    timestamp = get_timestamp()
    log_line = f"[{timestamp}] [{level.upper()}] {message}"

    # Write to LOG_FILE if set
    log_file = os.environ.get("LOG_FILE")
    if log_file:
        try:
            Path(log_file).parent.mkdir(parents=True, exist_ok=True)
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(log_line + "\n")
        except OSError:
            pass  # Silently ignore file write errors

    # Conditionally write to stderr based on QUIET_MODE and DEBUG_MODE
    if not _get_quiet_mode() and _should_output_to_stderr(level):
        print(log_line, file=sys.stderr)


def log_phase(phase_name: str, status: str, todo_update: bool = False) -> None:
    """Log phase transitions with special formatting.

    Args:
        phase_name: Name of the phase (e.g., "Entity Creation")
        status: Phase status - "start" or "complete"
        todo_update: Enable TodoWrite reminder logging (optional)

    Example:
        log_phase("Entity Creation", "start")
        # ... do work ...
        log_phase("Entity Creation", "complete")

    Output format:
        [2025-12-19T10:30:45Z] [PHASE] ========== Entity Creation [start] ==========
    """
    timestamp = get_timestamp()
    log_line = f"[{timestamp}] [PHASE] ========== {phase_name} [{status}] =========="

    # Write to LOG_FILE if set
    log_file = os.environ.get("LOG_FILE")
    if log_file:
        try:
            Path(log_file).parent.mkdir(parents=True, exist_ok=True)
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(log_line + "\n")
        except OSError:
            pass

    # Phase logs go to stderr unless QUIET_MODE is enabled
    if not _get_quiet_mode():
        print(log_line, file=sys.stderr)

    # Optional TodoWrite integration
    if todo_update and status == "complete":
        todo_marker = f"[TODO_UPDATE_NEEDED] Phase: {phase_name} | Status: completed"
        if log_file:
            try:
                with open(log_file, "a", encoding="utf-8") as f:
                    f.write(f"[{timestamp}] {todo_marker}\n")
            except OSError:
                pass
        if not _get_quiet_mode() and _get_debug_mode():
            print(f"[{timestamp}] {todo_marker}", file=sys.stderr)


def log_metric(metric_name: str, value: any, unit: str) -> None:
    """Log performance metrics in structured format.

    Args:
        metric_name: Name of the metric (e.g., "entities_created")
        value: Metric value (number or string)
        unit: Unit of measurement (e.g., "count", "seconds", "bytes")

    Example:
        log_metric("entities_created", 42, "count")
        log_metric("processing_time", 1.5, "seconds")

    Output format:
        [2025-12-19T10:30:45Z] [METRIC] entities_created=42 unit=count
    """
    timestamp = get_timestamp()
    log_line = f"[{timestamp}] [METRIC] {metric_name}={value} unit={unit}"

    # Write to LOG_FILE if set
    log_file = os.environ.get("LOG_FILE")
    if log_file:
        try:
            Path(log_file).parent.mkdir(parents=True, exist_ok=True)
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(log_line + "\n")
        except OSError:
            pass

    # Metrics go to stderr unless QUIET_MODE is enabled
    if not _get_quiet_mode():
        print(log_line, file=sys.stderr)


# Convenience aliases for shorter code
debug = lambda msg: log_conditional("DEBUG", msg)
info = lambda msg: log_conditional("INFO", msg)
warn = lambda msg: log_conditional("WARN", msg)
error = lambda msg: log_conditional("ERROR", msg)
trace = lambda msg: log_conditional("TRACE", msg)
