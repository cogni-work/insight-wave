#!/usr/bin/env python3
"""
wiki-coverage.py — read-before-web coverage scorer (P1.3, #309; #326).

The differentiation thesis (`references/differentiation-thesis.md`) promises
"the next research run reads the base before going to the web." Before this
script existed, `knowledge-curate` (Phase 2) fanned one `source-curator` per
sub-question and each one WebSearched immediately — never consulting the bound
wiki. Every run was therefore a full web run and the promised decreasing
cost-per-run never materialized.

This script is the deterministic half of the fix. The orchestrator
(`knowledge-curate`) runs it ONCE per run (mirroring the #304
resolve-market-config-once pattern), and threads the resulting manifest to each
curator, which makes the LLM judgment of how to narrow its search. Division of
labour: this script *surfaces candidate already-covering wiki pages* by token
overlap; the curator agent *reads those pages and decides query/fetch
narrowing*.

  score   For each sub-question in plan.json, score the bound wiki's source +
          synthesis pages by language-robust weighted coverage and emit a
          per-sub-question verdict (covered / partial / uncovered) plus the
          covering pages. An empty / unreadable / fresh base yields
          all-`uncovered`, so run 1 behaves exactly like today (no regression).

**Discovery is no longer implemented here.** The index→select→read→score logic
moved to the shared `wiki-grounding.py` primitive (#388 Phase 8 d2 core) so the
FMO ships ONE discovery mechanism consumed by both this read-side scorer and the
re-homed query skill. This module is now the thin per-sub-question caller: it
reads `plan.json`, fans each sub-question through `wiki_grounding.rank_pages`,
and assembles the coverage manifest. The CLI, JSON envelope, fail-soft
all-`uncovered` degradation, and bilingual handling are unchanged — the scoring
moved, the contract did not.

Fail-soft by contract: coverage is an OPTIMIZATION, not a correctness gate
(unlike #304's market config, where a wrong authority list corrupts scoring and
hard-aborts). A malformed plan is the one hard error (the caller cannot proceed
without sub-questions); a missing / unreadable wiki is NOT — it degrades to
all-`uncovered`.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.8+.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

# wiki-grounding.py is hyphenated (not an importable module name), so load it by
# path — the stdlib-only way the cogni-knowledge scripts reference one another.
# It owns the shared discovery primitive (collect_pages / sq_token_set /
# rank_pages); this scorer is now a thin caller over it.
_GROUNDING_PATH = Path(__file__).resolve().parent / "wiki-grounding.py"
_spec = importlib.util.spec_from_file_location("wiki_grounding", _GROUNDING_PATH)
wiki_grounding = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(wiki_grounding)  # type: ignore[union-attr]

SCHEMA_VERSION = "0.1.0"
# The recall ratio + emitted-page cap defaults live with the primitive in
# wiki-grounding.py; re-export the threshold default for the CLI help string.
DEFAULT_THRESHOLD = wiki_grounding.DEFAULT_THRESHOLD


# ---------------------------------------------------------------------------
# Envelope
# ---------------------------------------------------------------------------


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def cmd_score(args: argparse.Namespace) -> int:
    threshold = args.threshold
    # Lower bound is EXCLUSIVE: coverage_score returns 0.0 for a page with no
    # matching tokens, so `score >= 0.0` would make every page "cover" every
    # sub-question regardless of overlap. A coverage threshold of 0 is
    # meaningless — require a positive one.
    if not (0.0 < threshold <= 1.0):
        return _emit(False, error=f"--threshold must be in (0.0, 1.0], got {threshold}")

    # plan.json is the one HARD input — without sub-questions there is nothing
    # to score. A malformed plan is a clean success:false (the caller writes an
    # all-uncovered manifest itself; see knowledge-curate Step 0.5).
    plan_path = Path(args.plan)
    try:
        plan = json.loads(plan_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return _emit(False, error=f"could not read plan.json at {plan_path}: {exc}")
    if not isinstance(plan, dict) or not isinstance(plan.get("sub_questions"), list):
        return _emit(False, error=f"plan.json at {plan_path} has no sub_questions[] list")

    wiki_root = Path(args.wiki_root)
    # Collect pages ONCE (resolve-once posture), then rank each sub-question
    # against the shared discovery primitive. [] on a fresh / unreadable base.
    # include_interviews=True: interviews are source-class evidence on the read
    # side (mirrors verify-store.py's _SOURCE_SUBDIRS), so read-before-web
    # coverage must see wiki/interviews/. The shared primitive's default stays
    # False; this importer opts in (see CLAUDE.md "Interview read-side policy").
    pages = wiki_grounding.collect_pages(wiki_root, include_interviews=True)

    sub_questions: list[dict] = []
    for sq in plan["sub_questions"]:
        if not isinstance(sq, dict):
            continue
        sq_id = str(sq.get("id", ""))
        sq_tokens = wiki_grounding.sq_token_set(sq)
        ranked = wiki_grounding.rank_pages(pages, sq_tokens, threshold)
        sub_questions.append({
            "sq_id": sq_id,
            "coverage_verdict": ranked["verdict"],
            "covered_pages": ranked["covered_pages"],
        })

    data = {
        "schema_version": SCHEMA_VERSION,
        "wiki_root": str(wiki_root),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "threshold": threshold,
        "pages_scanned": len(pages),
        "sub_questions": sub_questions,
    }
    return _emit(True, data=data)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read-before-web coverage scorer for the inverted pipeline (P1.3, #309).",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_score = sub.add_parser(
        "score",
        help="Score the bound wiki's coverage of each plan.json sub-question.",
    )
    p_score.add_argument("--wiki-root", required=True,
                         help="Absolute path to the bound wiki root (the dir containing wiki/).")
    p_score.add_argument("--plan", required=True,
                         help="Absolute path to <project>/.metadata/plan.json.")
    p_score.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD,
                         help=f"Weighted-recall ratio a page must clear (alongside the matched-weight "
                              f"floor) to count as covering (default {DEFAULT_THRESHOLD}).")
    p_score.set_defaults(func=cmd_score)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
