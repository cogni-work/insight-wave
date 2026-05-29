#!/usr/bin/env python3
"""
build_open_questions_payload.py — merge cogni-wiki's `lint_wiki.py` output with
research-time gap findings from `<project>/.metadata/wiki-coverage.json` into a
single payload for `rebuild_open_questions.py --findings -` (#354).

Called by `cogni-knowledge:knowledge-finalize` Step 10.5 sub-step 5. It keeps
the SKILL's shell small: one process invokes lint, reads the coverage manifest,
and emits one envelope, instead of two `python3 -c` heredocs.

Inputs:
  --wiki-root          path to the bound wiki root (passed through to lint_wiki.py)
  --project            path to the knowledge-finalize project (reads
                       .metadata/wiki-coverage.json + plan.json)
  --wiki-lint          absolute path to cogni-wiki's lint_wiki.py
  --no-research-gaps   emit only the lint findings (skip the coverage stream)

Output (stdout, single-line `{success, data, error}` envelope per the in-repo
script convention):
  {"success": true,
   "data": {"errors": [...], "warnings": [...], "info": [...]},
   "meta": {"lint_findings": <N>, "research_findings": <N>, "degraded": [...]}}

`rebuild_open_questions.py --findings -` unwraps `data` and only reads the three
finding buckets; the `meta` block is diagnostic for the finalize Step 11 line.

Fail-soft: a lint crash NEVER blocks the research-gap stream. The envelope is
always valid JSON with `success: true` (the lint failure is recorded in
`meta.degraded`); a non-zero exit is reserved for a genuine parse-stage crash so
the SKILL's `OPEN_Q_EXIT` defence-in-depth can still fire.

Stdlib only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import load_wiki_coverage_findings  # noqa: E402


def _emit(data: dict, meta: dict) -> int:
    payload = {"success": True, "data": data, "error": "", "meta": meta}
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def _run_lint(wiki_lint: Path, wiki_root: Path) -> tuple[dict, str]:
    """Return (lint_data, degraded_reason). lint_data is `{errors, warnings,
    info}`; degraded_reason is "" on success, else a short description."""
    empty = {"errors": [], "warnings": [], "info": []}
    if not wiki_lint.is_file():
        return empty, f"lint_wiki.py not found at {wiki_lint}"
    try:
        proc = subprocess.run(
            [sys.executable, str(wiki_lint), "--wiki-root", str(wiki_root)],
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        return empty, f"lint_wiki.py invocation failed: {exc}"
    if not proc.stdout:
        return empty, "lint_wiki.py emitted no stdout"
    try:
        last = [ln for ln in proc.stdout.splitlines() if ln.strip()][-1]
        env = json.loads(last)
    except (json.JSONDecodeError, IndexError) as exc:
        return empty, f"lint_wiki.py JSON unparseable: {exc}"
    if not env.get("success"):
        return empty, f"lint_wiki.py reported failure: {env.get('error', '')}"
    data = env.get("data") or {}
    return {k: list(data.get(k) or []) for k in ("errors", "warnings", "info")}, ""


def main(argv: list) -> int:
    parser = argparse.ArgumentParser(
        description="Merge lint_wiki.py output + wiki-coverage research gaps (#354).",
        allow_abbrev=False,
    )
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--wiki-lint", required=True)
    parser.add_argument("--no-research-gaps", action="store_true",
                        help="Emit lint findings only; skip the coverage stream.")
    args = parser.parse_args(argv)

    wiki_root = Path(args.wiki_root).resolve()
    project = Path(args.project).resolve()
    wiki_lint = Path(args.wiki_lint)

    data, lint_degraded = _run_lint(wiki_lint, wiki_root)
    lint_count = len(data["errors"]) + len(data["warnings"]) + len(data["info"])

    research = [] if args.no_research_gaps else load_wiki_coverage_findings(project)
    # Research-time gaps are warnings (they do not fail the gate), and they
    # carry an `id` (not a `page`) which rebuild_open_questions.py's _flatten
    # understands.
    data["warnings"].extend(research)

    meta = {
        "lint_findings": lint_count,
        "research_findings": len(research),
        "degraded": [lint_degraded] if lint_degraded else [],
    }
    return _emit(data, meta)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception as exc:  # genuine parse-stage crash → non-zero exit (never via _emit)
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        sys.exit(1)
