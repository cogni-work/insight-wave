#!/usr/bin/env python3
"""
control-path.py — resolve a wiki control-file path for cogni-knowledge flows.

The three wiki control files (`log.md`, `context_brief.md`,
`open_questions.md`) are migrating from the flat `wiki/` root into a
`wiki/meta/` subtree (curated wiki-output layout, schema 0.0.8). This CLI is
the single grep-able resolution point SKILL.md prose calls instead of
hardcoding `"${WIKI_ROOT}/wiki/log.md"`, so the eventual relocation is a
one-line change in `_knowledge_lib` rather than a ~100-call-site sweep:

    LOG=$(python3 .../control-path.py log --wiki-root "$WIKI_ROOT")
    echo "..." >> "$LOG"

Prints ONLY the resolved absolute path to stdout (so the shell can capture it
with `$(...)`); diagnostics and the JSON error envelope go to stderr. Resolves
`wiki/meta/<file>` when it already exists on disk (read-side fallback), else
legacy `wiki/<file>` — delegating to the `_knowledge_lib` helpers so the
script and any Python importer share one source of truth.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import _knowledge_lib as kl  # noqa: E402


_RESOLVERS = {
    "log": kl.log_path,
    "context-brief": kl.context_brief_path,
    "open-questions": kl.open_questions_path,
}


def _fail(error: str) -> int:
    """Emit a JSON error envelope on stderr and return exit code 1."""
    json.dump({"success": False, "data": {}, "error": error}, sys.stderr)
    sys.stderr.write("\n")
    return 1


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Resolve a wiki control-file path (prefer wiki/meta/, "
        "fall back to legacy wiki/).",
    )
    parser.add_argument(
        "control_file",
        choices=sorted(_RESOLVERS),
        help="Which control file to resolve.",
    )
    parser.add_argument(
        "--wiki-root",
        required=True,
        help="Absolute path to the wiki root (the directory containing wiki/).",
    )
    args = parser.parse_args(argv)

    wiki_root = Path(args.wiki_root)
    if not wiki_root.is_dir():
        return _fail(f"--wiki-root is not a directory: {args.wiki_root}")

    resolved = _RESOLVERS[args.control_file](wiki_root)
    # Print only the resolved path so `$(...)` captures it cleanly.
    sys.stdout.write(str(resolved.resolve()) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
