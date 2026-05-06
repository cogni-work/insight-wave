#!/usr/bin/env python3
"""
config_bump.py — atomically mutate fields in .cogni-wiki/config.json.

Issue #84: wiki-ingest batch mode workers race on `entries_count`. When two
fresh-ingest workers read the file, compute `current + 1`, and write back,
the second worker's write silently clobbers the first. Net drift: +1 on
disk per concurrent fresh pair, instead of +2.

This script performs a locked read-modify-write. The lock file is
`<wiki-root>/.cogni-wiki/.lock`, the same advisory lock used by
`wiki_index_update.py` and `backlink_audit.py --apply-plan`, so all three
shared-state writers serialise against each other.

Two operations:

    Numeric bump (default):
        config_bump.py --wiki-root <path> --key entries_count --delta 1

    String set (v0.0.28+):
        config_bump.py --wiki-root <path> --key schema_version \\
                       --set-string 0.0.5

    The string-set form exists for the per-type-directory migrator, which
    needs to bump `schema_version` from `"0.0.4"` to `"0.0.5"` through the
    same locked code path that handles `entries_count`. Inlining that write
    in `migrate_layout.py` would re-introduce the duplicate-lock tech debt
    we just removed.

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

    Non-numeric current value (for --delta), missing key (when bumping a
    pre-existing field), or type mismatch returns success=false with a
    descriptive error. The atomic `os.replace` guarantees the file is
    either fully updated or untouched — no partial writes.

stdlib-only. Python 3.8+. bash 3.2 / macOS / Linux compatible.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import _wiki_lock  # noqa: E402


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


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
        description="Atomically mutate a field in .cogni-wiki/config.json"
    )
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")
    parser.add_argument("--key", required=True, help="Field name to mutate (e.g., entries_count, schema_version)")
    parser.add_argument("--delta", type=int, default=None, help="Signed integer to add (numeric bump)")
    parser.add_argument(
        "--set-string",
        default=None,
        help=(
            "Replace the field with this string value. Mutually exclusive with --delta. "
            "Used by the layout migrator to bump schema_version."
        ),
    )
    args = parser.parse_args()

    if args.delta is not None and args.set_string is not None:
        fail("--delta and --set-string are mutually exclusive")
    if args.delta is None and args.set_string is None:
        # Preserve legacy default: entries_count semantics implied --delta=1.
        args.delta = 1

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

        if args.set_string is not None:
            old = cfg.get(args.key)
            cfg[args.key] = args.set_string
            new_value = args.set_string
            current = old
        else:
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
