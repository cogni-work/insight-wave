#!/usr/bin/env python3
"""
compose-coverage.py — knowledge-compose Step 5.5 / Step 7 coverage helper.

Offloads the three `_knowledge_lib`-delegating coverage snippets that used to
live inline in `skills/knowledge-compose/SKILL.md` (Step 5.5 coverage-deficit +
section selector, Step 7 per-sub-question breakdown) so the SKILL body stays
under the 500-line soft cap. Pure refactor — the logic is byte-for-byte the
former inline blocks.

Unlike the rest of the cogni-knowledge scripts, the three subcommands print the
**exact raw stdout shapes** the SKILL captures with `$(...)`, NOT the
`{"success","data","error"}` envelope — that is the behaviour-preserving
contract (the SKILL reads `$COVERAGE` as a raw JSON object, `$EXPAND_SECTIONS`
as a bare comma-list, and the per-sq lines verbatim):

  coverage-deficit  → one JSON object: {"uncited_evidence_sq_ids":[...],
                                        "zero_cited_sq_ids":[...]}
  expand-sections   → a bare comma-separated list of section indices ("" if none)
  per-sq-coverage   → a header line + one "  sq-NN: <cited>/<available> ..." line
                      per sub-question with ≥1 ingested source (nothing if none)

Fail-soft to match the SKILL's posture: coverage-deficit / expand-sections print
nothing and exit 1 on any error (the SKILL treats empty output as "no deficit,
skip expansion"); per-sq-coverage prints nothing and exits 0 (the SKILL wraps it
`2>/dev/null || true`). Stdlib only; imports `_knowledge_lib` from this script's
own directory.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import coverage_report  # noqa: E402


def _load(p: str) -> dict:
    return json.loads(Path(p).read_text(encoding="utf-8"))


def cmd_coverage_deficit(args) -> int:
    """Step 5.5 Block B — the per-sq deficit + zero-cited sets that drive selection."""
    rep = coverage_report(_load(args.plan), _load(args.ingest), _load(args.citation))
    zero_cited = [sq for sq, v in rep["per_sq"].items() if not v["cited"]]
    print(json.dumps({"uncited_evidence_sq_ids": rep["uncited_evidence_sq_ids"],
                      "zero_cited_sq_ids": zero_cited}))
    return 0


def cmd_expand_sections(args) -> int:
    """Step 5.5 Block C — the topical sections eligible to deepen (density-aware)."""
    o = _load(args.outline)
    cov = json.loads(args.coverage_json)
    density = args.density or "standard"
    deficit = set(cov["uncited_evidence_sq_ids"])
    zero = set(cov["zero_cited_sq_ids"])
    chosen = []
    for s in o.get("sections", []):
        covers = s.get("covers_sub_questions") or []
        budget = s.get("budget")
        if not covers or not isinstance(budget, int):
            continue  # References / structural section (covers_sub_questions: [])
        if not (deficit & set(covers)):
            continue  # no uncited evidence maps to this section — leave it alone
        covers_zero = bool(zero & set(covers))
        if density == "executive":
            # executive caps length: only a zero-cited section qualifies (never thin-but-cited)
            if covers_zero:
                chosen.append(str(s["index"]))
            continue
        drafted = s.get("drafted_words")
        thin = isinstance(drafted, int) and drafted < budget * 0.9
        if thin or covers_zero:
            chosen.append(str(s["index"]))
    print(",".join(chosen))
    return 0


def cmd_per_sq_coverage(args) -> int:
    """Step 7 Block D — the per-sub-question ingested-source cited/available breakdown."""
    rep = coverage_report(_load(args.plan), _load(args.ingest), _load(args.citation))
    out = []
    for sq, v in rep["per_sq"].items():
        a = len(v["available"])
        c = len(v["cited"])
        if a:
            out.append("  %s: %d/%d ingested sources cited" % (sq, c, a))
    if out:
        print("Per-sub-question source coverage (executive caps length, not breadth):")
        print("\n".join(out))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="knowledge-compose coverage helper (Step 5.5 / Step 7).")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_def = sub.add_parser("coverage-deficit", help="Step 5.5 deficit + zero-cited sq-id sets.")
    p_def.add_argument("--plan", required=True)
    p_def.add_argument("--ingest", required=True)
    p_def.add_argument("--citation", required=True)
    p_def.set_defaults(func=cmd_coverage_deficit, fail_soft_exit=1)

    p_exp = sub.add_parser("expand-sections", help="Step 5.5 EXPAND_SECTIONS selector (density-aware).")
    p_exp.add_argument("--outline", required=True)
    p_exp.add_argument("--coverage-json", required=True, dest="coverage_json")
    p_exp.add_argument("--density", default="standard")
    p_exp.set_defaults(func=cmd_expand_sections, fail_soft_exit=1)

    p_psq = sub.add_parser("per-sq-coverage", help="Step 7 per-sub-question source-coverage breakdown.")
    p_psq.add_argument("--plan", required=True)
    p_psq.add_argument("--ingest", required=True)
    p_psq.add_argument("--citation", required=True)
    p_psq.set_defaults(func=cmd_per_sq_coverage, fail_soft_exit=0)

    args = parser.parse_args()
    try:
        return args.func(args)
    except Exception:
        # Fail-soft: print nothing; the SKILL treats empty output as "no deficit"
        # (deficit/selector → exit 1) and swallows per-sq errors (exit 0).
        return args.fail_soft_exit


if __name__ == "__main__":
    sys.exit(main())
