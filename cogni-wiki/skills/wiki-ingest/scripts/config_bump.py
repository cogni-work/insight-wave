#!/usr/bin/env python3
"""
config_bump.py — atomically increment a numeric field in .cogni-wiki/config.json.

Issue #84: wiki-ingest batch mode workers race on `entries_count`. When two
fresh-ingest workers read the file, compute `current + 1`, and write back,
the second worker's write silently clobbers the first. Net drift: +1 on
disk per concurrent fresh pair, instead of +2.

This script performs a locked read-modify-write. The lock file is
`<wiki-root>/.cogni-wiki/.lock`, the same advisory lock used by
`wiki_index_update.py` and `backlink_audit.py --apply-plan`, so all three
shared-state writers serialise against each other.

Usage:
    config_bump.py --wiki-root <path> --key entries_count --delta 1

Output contract:
    {
      "success": true,
      "data": {
        "key": "entries_count",
        "old_value": N,
        "new_value": N+delta,
        "wrote": true
      },
      "error": ""
    }

    Non-numeric current value or missing key returns success=false with a
    descriptive error. The atomic `os.replace` guarantees the file is either
    fully updated or untouched — no partial writes.

stdlib-only. Python 3.8+. bash 3.2 / macOS / Linux compatible.
"""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


@contextmanager
def _wiki_lock(wiki_root: Path):
    lock_dir = wiki_root / ".cogni-wiki"
    lock_dir.mkdir(parents=True, exist_ok=True)
    lock_path = lock_dir / ".lock"
    fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            os.close(fd)


def _atomic_write(path: Path, content: str) -> None:
    parent = path.parent
    fd, tmp = tempfile.mkstemp(prefix=".config-bump-", dir=str(parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Atomically bump a numeric field in .cogni-wiki/config.json"
    )
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")
    parser.add_argument("--key", required=True, help="Field name to bump (e.g., entries_count)")
    parser.add_argument("--delta", type=int, default=1, help="Signed integer to add (default: 1)")
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    config_path = wiki_root / ".cogni-wiki" / "config.json"

    if not config_path.is_file():
        fail(f"config.json not found at {config_path}")

    with _wiki_lock(wiki_root):
        try:
            text = config_path.read_text(encoding="utf-8")
        except OSError as e:
            fail(f"could not read config.json: {e}")
            return

        try:
            cfg = json.loads(text)
        except json.JSONDecodeError as e:
            fail(f"config.json is not valid JSON: {e}")
            return

        if args.key not in cfg:
            fail(f"key {args.key!r} not present in config.json")
            return

        current = cfg[args.key]
        if not isinstance(current, int):
            fail(f"key {args.key!r} is not an integer (got {type(current).__name__})")
            return

        new_value = current + args.delta
        cfg[args.key] = new_value

        new_text = json.dumps(cfg, ensure_ascii=False, indent=2) + "\n"
        _atomic_write(config_path, new_text)

    ok({
        "key": args.key,
        "old_value": current,
        "new_value": new_value,
        "wrote": True,
    })


if __name__ == "__main__":
    main()
