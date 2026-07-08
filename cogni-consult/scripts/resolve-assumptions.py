#!/usr/bin/env python3
"""Render-time resolver for {{asm:id}} assumption placeholders.

Usage:
  python3 resolve-assumptions.py <engagement-dir> resolve <file> [--in-place]

Reads the engagement's assumptions.json registry (the single source of truth
for assumption values — see references/data-model.md) and replaces every
`{{asm:<suffix>}}` placeholder in the target file with the `value` of the
registry entry whose id is `asm-<suffix>`. Without --in-place the resolved
text is returned in the envelope (a dry-run); with it, the file is rewritten.
Read-only toward the registry and toward field.json.

Fail-loud contract: an unknown placeholder id, a duplicate registry id, or a
missing registry when placeholders exist all return success:false with a
data.failed_check discriminator and exit 1 — a placeholder is never silently
left in, and never silently dropped. All offending ids are listed at once so
a consultant can fix every typo in one pass.

Output: single-line JSON envelope {"success": bool, "data": {...}, "error": str}.
Stdlib-only.
"""

import argparse
import json
import os
import re
import sys

PLACEHOLDER_RE = re.compile(r"\{\{asm:([a-z0-9][a-z0-9-]*)\}\}")
ID_PREFIX = "asm-"


def _emit(success, data, error):
    print(json.dumps({"success": success, "data": data, "error": error}))
    sys.exit(0 if success else 1)


def load_registry(engagement_dir):
    """Return {id: entry} from assumptions.json, failing loudly on any defect."""
    path = os.path.join(engagement_dir, "assumptions.json")
    if not os.path.isfile(path):
        _emit(False, {"failed_check": "registry_missing", "path": path},
              "assumptions.json not found at engagement root — placeholders exist "
              "but there is no registry to resolve them against")
    try:
        with open(path) as f:
            raw = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        _emit(False, {"failed_check": "registry_unreadable", "path": path},
              "assumptions.json could not be read/parsed: %s" % exc)
    registry = {}
    duplicates = []
    for entry in raw.get("assumptions", []):
        asm_id = entry.get("id", "")
        if asm_id in registry:
            duplicates.append(asm_id)
        registry[asm_id] = entry
    if duplicates:
        _emit(False, {"failed_check": "duplicate_assumption_id", "ids": sorted(set(duplicates))},
              "duplicate assumption id(s) in registry — the single-source contract "
              "requires exactly one entry per id")
    return registry


def cmd_resolve(args):
    try:
        with open(args.file) as f:
            text = f.read()
    except OSError as exc:
        _emit(False, {"failed_check": "file_unreadable", "path": args.file},
              "target file could not be read: %s" % exc)

    suffixes = PLACEHOLDER_RE.findall(text)
    if not suffixes:
        # Nothing to resolve — a registry-less or placeholder-free brief passes.
        _emit(True, {"file": args.file, "placeholders_found": 0, "output": None}, "")

    unique_ids = sorted({ID_PREFIX + s for s in suffixes})
    registry = load_registry(args.engagement_dir)
    missing = [i for i in unique_ids if i not in registry]
    if missing:
        _emit(False, {"failed_check": "unknown_assumption_id", "ids": missing},
              "unknown assumption id(s): %s — define them in assumptions.json "
              "or fix the placeholder(s)" % ", ".join(missing))

    resolved = PLACEHOLDER_RE.sub(
        lambda m: str(registry[ID_PREFIX + m.group(1)]["value"]), text)

    data = {
        "file": args.file,
        "placeholders_found": len(suffixes),
        "unique_ids": unique_ids,
        "output": args.file if args.in_place else None,
    }
    if args.in_place:
        with open(args.file, "w") as f:
            f.write(resolved)
    else:
        data["resolved_text"] = resolved
    _emit(True, data, "")


def main():
    parser = argparse.ArgumentParser(
        description="Resolve {{asm:id}} placeholders against the engagement's assumptions.json")
    parser.add_argument("engagement_dir", help="engagement root (directory holding consult-project.json)")
    sub = parser.add_subparsers(dest="action", required=True)

    p_resolve = sub.add_parser("resolve", help="resolve placeholders in a file")
    p_resolve.add_argument("file", help="file containing {{asm:id}} placeholders")
    p_resolve.add_argument("--in-place", action="store_true",
                           help="write resolved text back to the file (omit for a dry-run envelope)")
    p_resolve.set_defaults(func=cmd_resolve)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
