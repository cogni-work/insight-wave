"""
Entity Lock Utilities for Claude Code Plugins
==============================================

Directory-based advisory locks for atomic entity creation operations.
Replaces entity-lock-utils.sh with cross-platform Python implementation.

Lock Pattern:
    Uses mkdir for atomic lock creation - works identically on all platforms.
    Lock is created as empty directory, released via rmdir.

Environment Variables:
    QUIET_MODE - Set to "true" to suppress all logging output (default: false)

Functions:
    acquire_entity_lock(entity_type, project_path, timeout=30)
    release_entity_lock(entity_type, project_path)
    acquire_lock(lock_path, timeout=30)
    release_lock(lock_path)
    cleanup_stale_locks(project_path, max_age=300)

Context Manager:
    EntityLock - Use with 'with' statement for automatic lock release

Example:
    # Method 1: Context manager (recommended)
    from entity_lock import EntityLock

    with EntityLock("05-sources", "/path/to/project"):
        # Critical section - lock automatically released
        create_entity(...)

    # Method 2: Manual acquire/release
    from entity_lock import acquire_entity_lock, release_entity_lock

    if acquire_entity_lock("05-sources", "/path/to/project"):
        try:
            create_entity(...)
        finally:
            release_entity_lock("05-sources", "/path/to/project")
"""

import os
import sys
import time
from pathlib import Path
from typing import Optional

__version__ = "1.0.0"

# Default timeout and stale lock settings
DEFAULT_TIMEOUT = 30.0  # seconds
POLL_INTERVAL = 0.1     # seconds between retries
STALE_THRESHOLD = 60    # seconds - lock considered stale if older
CLEANUP_THRESHOLD = 300 # seconds (5 minutes) for cleanup_stale_locks


def _get_quiet_mode() -> bool:
    """Check if QUIET_MODE is enabled."""
    return os.environ.get("QUIET_MODE", "false").lower() == "true"


def _log(level: str, message: str) -> None:
    """Log message to stderr if not in quiet mode."""
    if not _get_quiet_mode():
        print(f"{level}: {message}", file=sys.stderr)


def _get_mtime(path: Path) -> Optional[float]:
    """Get modification time of path, returns None if not accessible."""
    try:
        return path.stat().st_mtime
    except OSError:
        return None


def acquire_entity_lock(
    entity_type: str,
    project_path: str,
    timeout: float = DEFAULT_TIMEOUT
) -> bool:
    """Acquire advisory lock for entity type with timeout.

    Args:
        entity_type: String identifier for entity (e.g., "05-sources")
        project_path: Absolute path to project root
        timeout: Maximum seconds to wait (default: 30)

    Returns:
        True if lock acquired, False on timeout

    Lock Path:
        {project_path}/.metadata/locks/{entity_type}/
    """
    # Validate arguments
    if not entity_type:
        _log("ERROR", "entity_type required")
        return False

    if not project_path:
        _log("ERROR", "project_path required")
        return False

    project = Path(project_path)
    if not project.is_dir():
        _log("ERROR", f"project_path does not exist: {project_path}")
        return False

    # Create locks directory structure if missing
    locks_base = project / ".metadata" / "locks"
    try:
        locks_base.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        _log("ERROR", f"Cannot create locks directory: {locks_base} ({e})")
        return False

    lock_path = locks_base / entity_type
    _log("INFO", f"Attempting to acquire lock for entity type: {entity_type}")

    # Try to acquire lock with timeout
    start_time = time.time()
    while True:
        try:
            # mkdir is atomic - either succeeds or fails
            lock_path.mkdir()
            elapsed = time.time() - start_time
            _log("INFO", f"Lock acquired for entity type: {entity_type} (elapsed: {elapsed:.1f}s)")
            return True
        except FileExistsError:
            pass  # Lock exists, will retry
        except OSError as e:
            _log("ERROR", f"Failed to create lock directory: {e}")
            return False

        # Check timeout
        elapsed = time.time() - start_time
        if elapsed >= timeout:
            break

        # Lock exists, wait and retry
        time.sleep(POLL_INTERVAL)

    # Timeout reached - check if lock is stale before failing
    _log("WARN", f"Lock acquisition timeout for entity type: {entity_type} (waited: {timeout}s)")

    if lock_path.is_dir():
        mtime = _get_mtime(lock_path)
        if mtime is not None:
            lock_age = time.time() - mtime
            if lock_age > STALE_THRESHOLD:
                _log("WARN", f"Detected stale lock (>{STALE_THRESHOLD}s old), attempting emergency cleanup: {lock_path}")

                # Emergency cleanup of stale lock
                try:
                    lock_path.rmdir()
                    _log("INFO", f"Successfully cleaned up stale lock: {entity_type}")

                    # Retry acquisition once after cleanup
                    try:
                        lock_path.mkdir()
                        _log("INFO", f"Lock acquired after stale lock cleanup: {entity_type}")
                        return True
                    except FileExistsError:
                        _log("ERROR", f"Failed to acquire lock even after stale lock cleanup: {entity_type}")
                except OSError:
                    _log("ERROR", f"Failed to remove stale lock (may contain files): {lock_path}")

    # Final failure after timeout and stale lock check
    _log("ERROR", f"Failed to acquire lock after {timeout}s timeout: {entity_type}")
    return False


def release_entity_lock(entity_type: str, project_path: str) -> bool:
    """Release advisory lock for entity type.

    Args:
        entity_type: String identifier for entity
        project_path: Absolute path to project root

    Returns:
        True always (safe even if lock doesn't exist)
    """
    # Validate arguments (silent failure for release is acceptable)
    if not entity_type or not project_path:
        return True

    lock_path = Path(project_path) / ".metadata" / "locks" / entity_type

    # Remove lock directory (rmdir only succeeds if empty, which is what we want)
    try:
        lock_path.rmdir()
    except OSError:
        pass  # Safe even if lock doesn't exist

    return True


def acquire_lock(lock_path: str, timeout: float = DEFAULT_TIMEOUT) -> bool:
    """Acquire advisory lock for arbitrary resource path with timeout.

    Args:
        lock_path: Absolute path to lock directory (e.g., /path/.locks/resource-name)
        timeout: Maximum seconds to wait (default: 30)

    Returns:
        True if lock acquired, False on timeout

    Notes:
        - Parent directory of lock_path must exist
        - Lock is created as empty directory using atomic mkdir
        - Includes stale lock cleanup (locks older than 60 seconds)
    """
    # Validate arguments
    if not lock_path:
        _log("ERROR", "lock_path required")
        return False

    lock = Path(lock_path)
    lock_parent = lock.parent
    lock_name = lock.name

    if not lock_parent.is_dir():
        _log("ERROR", f"lock parent directory does not exist: {lock_parent}")
        return False

    _log("INFO", f"Attempting to acquire lock: {lock_name}")

    # Try to acquire lock with timeout
    start_time = time.time()
    while True:
        try:
            # mkdir is atomic - either succeeds or fails
            lock.mkdir()
            elapsed = time.time() - start_time
            _log("INFO", f"Lock acquired: {lock_name} (elapsed: {elapsed:.1f}s)")
            return True
        except FileExistsError:
            pass  # Lock exists, will retry
        except OSError as e:
            _log("ERROR", f"Failed to create lock directory: {e}")
            return False

        # Check timeout
        elapsed = time.time() - start_time
        if elapsed >= timeout:
            break

        # Lock exists, wait and retry
        time.sleep(POLL_INTERVAL)

    # Timeout reached - check if lock is stale before failing
    _log("WARN", f"Lock acquisition timeout: {lock_name} (waited: {timeout}s)")

    if lock.is_dir():
        mtime = _get_mtime(lock)
        if mtime is not None:
            lock_age = time.time() - mtime
            if lock_age > STALE_THRESHOLD:
                _log("WARN", f"Detected stale lock (>{STALE_THRESHOLD}s old), attempting emergency cleanup: {lock_path}")

                # Emergency cleanup of stale lock
                try:
                    lock.rmdir()
                    _log("INFO", f"Successfully cleaned up stale lock: {lock_name}")

                    # Retry acquisition once after cleanup
                    try:
                        lock.mkdir()
                        _log("INFO", f"Lock acquired after stale lock cleanup: {lock_name}")
                        return True
                    except FileExistsError:
                        _log("ERROR", f"Failed to acquire lock even after stale lock cleanup: {lock_name}")
                except OSError:
                    _log("ERROR", f"Failed to remove stale lock (may contain files): {lock_path}")

    # Final failure after timeout and stale lock check
    _log("ERROR", f"Failed to acquire lock after {timeout}s timeout: {lock_name}")
    return False


def release_lock(lock_path: str) -> bool:
    """Release advisory lock for arbitrary resource path.

    Args:
        lock_path: Absolute path to lock directory

    Returns:
        True always (safe even if lock doesn't exist)

    Notes:
        - Silent operation (no logging)
        - Safe to call even if lock doesn't exist
        - Uses rmdir for atomic cleanup
    """
    # Validate arguments (silent failure for release is acceptable)
    if not lock_path:
        return True

    # Remove lock directory
    try:
        Path(lock_path).rmdir()
    except OSError:
        pass  # Safe even if lock doesn't exist

    return True


def cleanup_stale_locks(
    project_path: str,
    max_age: int = CLEANUP_THRESHOLD
) -> int:
    """Remove locks older than max_age seconds.

    Args:
        project_path: Absolute path to project root
        max_age: Maximum age in seconds (default: 300 = 5 minutes)

    Returns:
        Number of locks cleaned up, -1 on error
    """
    # Validate arguments
    if not project_path:
        _log("ERROR", "project_path required")
        return -1

    project = Path(project_path)
    if not project.is_dir():
        _log("ERROR", f"project_path does not exist: {project_path}")
        return -1

    locks_base = project / ".metadata" / "locks"

    # If locks directory doesn't exist, nothing to clean
    if not locks_base.is_dir():
        return 0

    current_time = time.time()
    cleaned_count = 0

    # Find all lock directories
    try:
        for lock_dir in locks_base.iterdir():
            if not lock_dir.is_dir():
                continue

            mtime = _get_mtime(lock_dir)
            if mtime is None:
                continue

            lock_age = current_time - mtime

            # Remove if stale
            if lock_age > max_age:
                entity_type = lock_dir.name
                try:
                    lock_dir.rmdir()
                    _log("INFO", f"Cleaned stale lock: {entity_type} (age: {lock_age:.0f}s)")
                    cleaned_count += 1
                except OSError:
                    _log("WARN", f"Could not remove stale lock: {lock_dir}")
    except OSError as e:
        _log("ERROR", f"Error iterating locks: {e}")
        return -1

    if cleaned_count > 0:
        _log("INFO", f"Cleaned {cleaned_count} stale lock(s)")

    return cleaned_count


class EntityLock:
    """Context manager for entity-type locks.

    Usage:
        with EntityLock("05-sources", "/path/to/project") as lock:
            if lock.acquired:
                # Critical section
                create_entity(...)
            else:
                # Lock acquisition failed
                handle_failure()

    Or simpler (raises exception on failure):
        with EntityLock("05-sources", "/path/to/project", raise_on_fail=True):
            create_entity(...)
    """

    def __init__(
        self,
        entity_type: str,
        project_path: str,
        timeout: float = DEFAULT_TIMEOUT,
        raise_on_fail: bool = False
    ):
        """Initialize EntityLock.

        Args:
            entity_type: String identifier for entity
            project_path: Absolute path to project root
            timeout: Maximum seconds to wait (default: 30)
            raise_on_fail: Raise RuntimeError if lock acquisition fails
        """
        self.entity_type = entity_type
        self.project_path = project_path
        self.timeout = timeout
        self.raise_on_fail = raise_on_fail
        self.acquired = False

    def __enter__(self) -> "EntityLock":
        """Acquire lock on context entry."""
        self.acquired = acquire_entity_lock(
            self.entity_type,
            self.project_path,
            self.timeout
        )
        if self.raise_on_fail and not self.acquired:
            raise RuntimeError(
                f"Failed to acquire lock for entity type: {self.entity_type}"
            )
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Release lock on context exit."""
        if self.acquired:
            release_entity_lock(self.entity_type, self.project_path)
            self.acquired = False
        return None  # Don't suppress exceptions


class Lock:
    """Context manager for generic path-based locks.

    Usage:
        with Lock("/path/to/project/.locks/entity-index-global") as lock:
            if lock.acquired:
                # Critical section
                update_index(...)

    Or simpler (raises exception on failure):
        with Lock("/path/.locks/resource", raise_on_fail=True):
            update_resource(...)
    """

    def __init__(
        self,
        lock_path: str,
        timeout: float = DEFAULT_TIMEOUT,
        raise_on_fail: bool = False
    ):
        """Initialize Lock.

        Args:
            lock_path: Absolute path to lock directory
            timeout: Maximum seconds to wait (default: 30)
            raise_on_fail: Raise RuntimeError if lock acquisition fails
        """
        self.lock_path = lock_path
        self.timeout = timeout
        self.raise_on_fail = raise_on_fail
        self.acquired = False

    def __enter__(self) -> "Lock":
        """Acquire lock on context entry."""
        self.acquired = acquire_lock(self.lock_path, self.timeout)
        if self.raise_on_fail and not self.acquired:
            raise RuntimeError(f"Failed to acquire lock: {self.lock_path}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Release lock on context exit."""
        if self.acquired:
            release_lock(self.lock_path)
            self.acquired = False
        return None  # Don't suppress exceptions
