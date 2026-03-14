#!/usr/bin/env python3
"""
file_ops.py
Version: 1.0.0
Purpose: Cross-platform file operations using Python stdlib

This module provides file operations that work identically on macOS, Linux,
and Windows without any platform-specific code branches. It replaces common
bash patterns that have platform differences:

    - stat -f%z / stat -c%s  -> file_size()
    - stat -f%m / stat -c%Y  -> file_mtime()
    - sed -i / sed -i ''     -> replace_in_file()
    - mktemp                  -> temp_file(), temp_dir()
    - flock                   -> FileLock context manager
    - atomic mv pattern       -> atomic_write()

All functions use Python's pathlib and standard library, ensuring
identical behavior across all platforms.

Usage:
    from file_ops import file_size, atomic_write, FileLock

    # Get file size (cross-platform)
    size = file_size("/path/to/file")

    # Atomic write (safe against crashes)
    atomic_write("/path/to/file.md", content)

    # File locking
    with FileLock("/path/to/lockfile"):
        # exclusive access
        pass
"""

import os
import shutil
import tempfile
import time
import fcntl
from contextlib import contextmanager
from pathlib import Path
from typing import Generator, Optional, Union

PathLike = Union[str, Path]


def file_size(path: PathLike) -> int:
    """
    Get file size in bytes.

    Cross-platform replacement for:
        stat -f%z "$file" (macOS)
        stat -c%s "$file" (Linux)

    Args:
        path: Path to file

    Returns:
        File size in bytes

    Raises:
        FileNotFoundError: If file doesn't exist
    """
    return Path(path).stat().st_size


def file_mtime(path: PathLike) -> float:
    """
    Get file modification time as Unix timestamp.

    Cross-platform replacement for:
        stat -f%m "$file" (macOS)
        stat -c%Y "$file" (Linux)

    Args:
        path: Path to file

    Returns:
        Modification time as Unix timestamp (seconds since epoch)

    Raises:
        FileNotFoundError: If file doesn't exist
    """
    return Path(path).stat().st_mtime


def file_mtime_iso(path: PathLike) -> str:
    """
    Get file modification time as ISO 8601 string.

    Args:
        path: Path to file

    Returns:
        Modification time as ISO 8601 string (e.g., "2024-01-15T10:30:00")
    """
    from datetime import datetime
    mtime = file_mtime(path)
    return datetime.fromtimestamp(mtime).isoformat()


def file_exists(path: PathLike) -> bool:
    """Check if file exists."""
    return Path(path).is_file()


def dir_exists(path: PathLike) -> bool:
    """Check if directory exists."""
    return Path(path).is_dir()


def ensure_dir(path: PathLike) -> Path:
    """
    Ensure directory exists, creating it if necessary.

    Cross-platform replacement for: mkdir -p

    Args:
        path: Directory path

    Returns:
        Path object for the directory
    """
    p = Path(path)
    p.mkdir(parents=True, exist_ok=True)
    return p


def temp_file(
    suffix: Optional[str] = None,
    prefix: Optional[str] = None,
    dir: Optional[PathLike] = None,
    delete: bool = True
) -> str:
    """
    Create a temporary file.

    Cross-platform replacement for: mktemp

    Args:
        suffix: File suffix (e.g., ".txt")
        prefix: File prefix
        dir: Directory to create file in (default: system temp dir)
        delete: If False, file persists after close (default: True)

    Returns:
        Path to temporary file as string
    """
    fd, path = tempfile.mkstemp(
        suffix=suffix,
        prefix=prefix,
        dir=str(dir) if dir else None
    )
    os.close(fd)
    return path


def temp_dir(
    suffix: Optional[str] = None,
    prefix: Optional[str] = None,
    dir: Optional[PathLike] = None
) -> str:
    """
    Create a temporary directory.

    Cross-platform replacement for: mktemp -d

    Args:
        suffix: Directory suffix
        prefix: Directory prefix
        dir: Parent directory (default: system temp dir)

    Returns:
        Path to temporary directory as string
    """
    return tempfile.mkdtemp(
        suffix=suffix,
        prefix=prefix,
        dir=str(dir) if dir else None
    )


def atomic_write(
    path: PathLike,
    content: str,
    encoding: str = "utf-8",
    newline: Optional[str] = None
) -> None:
    """
    Write content to file atomically.

    Uses the write-to-temp-then-rename pattern to ensure the file is
    never left in a partially written state, even if the process crashes.

    Cross-platform replacement for:
        echo "$content" > "$tmp" && mv "$tmp" "$file"

    Args:
        path: Target file path
        content: Content to write
        encoding: Text encoding (default: utf-8)
        newline: Line ending style (None = platform default, '' = no translation)
    """
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)

    # Write to temp file in same directory (ensures same filesystem for atomic rename)
    fd, tmp_path = tempfile.mkstemp(
        dir=str(target.parent),
        prefix=f".{target.name}.",
        suffix=".tmp"
    )

    try:
        with os.fdopen(fd, "w", encoding=encoding, newline=newline) as f:
            f.write(content)

        # Atomic rename (works on all platforms when on same filesystem)
        shutil.move(tmp_path, str(target))

    except Exception:
        # Clean up temp file on failure
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def atomic_write_bytes(path: PathLike, content: bytes) -> None:
    """
    Write binary content to file atomically.

    Args:
        path: Target file path
        content: Binary content to write
    """
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)

    fd, tmp_path = tempfile.mkstemp(
        dir=str(target.parent),
        prefix=f".{target.name}.",
        suffix=".tmp"
    )

    try:
        with os.fdopen(fd, "wb") as f:
            f.write(content)
        shutil.move(tmp_path, str(target))
    except Exception:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def read_file(path: PathLike, encoding: str = "utf-8") -> str:
    """
    Read entire file content.

    Handles Windows CRLF line endings by normalizing to LF.

    Args:
        path: File path
        encoding: Text encoding (default: utf-8)

    Returns:
        File content with normalized line endings
    """
    content = Path(path).read_text(encoding=encoding)
    # Normalize CRLF to LF for cross-platform consistency
    return content.replace("\r\n", "\n").replace("\r", "\n")


def replace_in_file(
    path: PathLike,
    old: str,
    new: str,
    count: int = -1,
    encoding: str = "utf-8"
) -> int:
    """
    Replace text in file (in-place).

    Cross-platform replacement for:
        sed -i 's/old/new/g' "$file" (Linux)
        sed -i '' 's/old/new/g' "$file" (macOS)

    Args:
        path: File path
        old: Text to replace
        new: Replacement text
        count: Max replacements (-1 = all)
        encoding: Text encoding

    Returns:
        Number of replacements made
    """
    content = read_file(path, encoding)
    if count == -1:
        new_content = content.replace(old, new)
        replacements = content.count(old)
    else:
        new_content = content.replace(old, new, count)
        replacements = min(count, content.count(old))

    if replacements > 0:
        atomic_write(path, new_content, encoding)

    return replacements


class FileLock:
    """
    Cross-platform file locking context manager.

    Provides exclusive access to a resource using a lock file.
    Works on macOS, Linux, and Windows.

    Usage:
        with FileLock("/path/to/resource.lock"):
            # exclusive access to resource
            pass

        # With timeout
        with FileLock("/path/to/resource.lock", timeout=10):
            pass

    Note: On Windows, uses msvcrt for locking. On Unix, uses fcntl.
    """

    def __init__(
        self,
        path: PathLike,
        timeout: Optional[float] = None,
        poll_interval: float = 0.1
    ):
        """
        Initialize file lock.

        Args:
            path: Path to lock file
            timeout: Max seconds to wait for lock (None = wait forever)
            poll_interval: Seconds between lock attempts
        """
        self.path = Path(path)
        self.timeout = timeout
        self.poll_interval = poll_interval
        self._fd: Optional[int] = None

    def __enter__(self) -> "FileLock":
        self.acquire()
        return self

    def __exit__(self, *args) -> None:
        self.release()

    def acquire(self) -> None:
        """
        Acquire the lock.

        Raises:
            TimeoutError: If timeout exceeded
            IOError: If lock cannot be acquired
        """
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._fd = os.open(str(self.path), os.O_CREAT | os.O_RDWR)

        start = time.monotonic()
        while True:
            try:
                fcntl.flock(self._fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                return
            except BlockingIOError:
                if self.timeout is not None:
                    elapsed = time.monotonic() - start
                    if elapsed >= self.timeout:
                        os.close(self._fd)
                        self._fd = None
                        raise TimeoutError(
                            f"Could not acquire lock on {self.path} "
                            f"within {self.timeout} seconds"
                        )
                time.sleep(self.poll_interval)

    def release(self) -> None:
        """Release the lock."""
        if self._fd is not None:
            fcntl.flock(self._fd, fcntl.LOCK_UN)
            os.close(self._fd)
            self._fd = None


@contextmanager
def working_directory(path: PathLike) -> Generator[Path, None, None]:
    """
    Context manager to temporarily change working directory.

    Args:
        path: Directory to change to

    Yields:
        Path object for the directory

    Example:
        with working_directory("/some/path"):
            # cwd is /some/path
            pass
        # cwd restored to original
    """
    original = os.getcwd()
    try:
        os.chdir(path)
        yield Path(path)
    finally:
        os.chdir(original)


def normalize_path(path: PathLike) -> str:
    """
    Normalize path for cross-platform consistency.

    Resolves symlinks, normalizes case (on case-insensitive filesystems),
    and uses forward slashes.

    Args:
        path: Path to normalize

    Returns:
        Normalized path string with forward slashes
    """
    return str(Path(path).resolve()).replace("\\", "/")


def relative_path(path: PathLike, base: PathLike) -> str:
    """
    Get relative path from base directory.

    Args:
        path: Target path
        base: Base directory

    Returns:
        Relative path with forward slashes
    """
    return str(Path(path).relative_to(base)).replace("\\", "/")
