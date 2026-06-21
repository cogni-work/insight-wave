#!/usr/bin/env python3
"""
contradiction-finalize-store.py — derive the synthesis-side **consistency rate**
from the finalize-time `wiki-contradictor` output (`contradictor-vN.json`).

The contradiction track ships its *ingest-time* coverage (`contradiction-ingest.py`
+ `contradiction-ingest-store.py`, surfaced as `resolution_coverage`), but the
metric the engagement named as proof-of-value — "is the finished synthesis
internally consistent?" — lives at the synthesis surface, not the ingest surface.
This store closes that gap: it reads the just-deposited synthesis's
`contradictor-vN.json` (one envelope per synthesis per finalize run, written by
the `wiki-contradictor` agent) and reports a `consistency_rate` block alongside
the same `resolution_coverage` the ingest store already computes.

A synthesis is **clean** when it carries zero *unresolved high-severity*
contradiction — a `contradiction`-kind finding with `severity == "high"` whose
`resolution.survivor_claim_id` is absent/null (a high-severity contradiction the
recency annotation could not resolve). High-severity is the bar because that is
the band `wiki-contradictor` reserves for outright numeric / named-entity flips;
a `medium`/`low` finding, or a `high` one the recency annotation resolved, does
not break consistency. The rate is `100.0 * clean / total` over the syntheses in
scope (one per `record` run).

  init    Write an empty canonical `contradiction-finalize.json` (zeroed
          consistency_rate + resolution_coverage). Lets the finalize orchestrator
          stamp a clean artifact on a run whose contradictor was skipped.
  record  Read the project's latest `contradictor-v*.json` (or an explicit
          --contradictor path), compute the consistency_rate + resolution_coverage
          for that synthesis, and atomic-write the canonical file (overwritten on
          re-finalize — idempotent, the same posture the ingest store uses).

This is a **pure-observability** artifact: it never gates finalize, never mutates
a wiki page, drives no downstream behaviour. A missing / unreadable / schema-
mismatched contradictor file degrades to an empty (zeroed) artifact with a
recorded reason rather than failing the finalize run — the synthesis already
landed before Step 10.6 runs.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import glob as globmod
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import atomic_write  # noqa: E402

SCHEMA_VERSION = "0.1.0"
# The contradictor envelope this store reads is schema 0.1.0 (wiki-contradictor).
CONTRADICTOR_SCHEMA_VERSION = "0.1.0"


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _resolution_coverage(findings: list[dict]) -> dict:
    """Share of `contradiction` findings carrying a non-null recency-survivor
    suggestion (`resolution.survivor_claim_id`). Identical semantics to
    `contradiction-ingest-store.py::_resolution_coverage` — kept in lockstep so the
    ingest-time and finalize-time coverage numbers mean the same thing. A finding
    whose both sides carried no usable timestamp (`survivor_claim_id: null`), or a
    pre-annotation contradictor (no `resolution` key), counts as uncovered."""
    contradictions = [f for f in findings if f.get("kind") == "contradiction"]
    resolved = sum(
        1
        for f in contradictions
        if isinstance(f.get("resolution"), dict) and f["resolution"].get("survivor_claim_id")
    )
    total = len(contradictions)
    pct = round(100.0 * resolved / total, 1) if total else 0.0
    return {"resolved": resolved, "contradictions": total, "pct": pct}


def _unresolved_high(findings: list[dict]) -> int:
    """Count `contradiction` findings at `severity == "high"` whose recency
    annotation did NOT resolve them (`resolution.survivor_claim_id` absent/null).
    A synthesis is `clean` iff this is 0."""
    n = 0
    for f in findings:
        if f.get("kind") != "contradiction" or f.get("severity") != "high":
            continue
        res = f.get("resolution")
        if not (isinstance(res, dict) and res.get("survivor_claim_id")):
            n += 1
    return n


def _consistency_rate(syntheses: list[dict]) -> dict:
    """Aggregate the per-synthesis clean/total into a wiki-wide-shaped rate. Each
    entry is `{synthesis_slug, draft_version, findings, unresolved_high, clean}`.
    `clean` = `unresolved_high == 0`. `pct` = `100.0 * clean / total`."""
    total = len(syntheses)
    clean = sum(1 for s in syntheses if s.get("clean"))
    pct = round(100.0 * clean / total, 1) if total else 0.0
    return {"syntheses_total": total, "syntheses_clean": clean, "pct": pct}


def _canonical(output_language: str, syntheses: list[dict], all_findings: list[dict]) -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "output_language": output_language,
        "syntheses": syntheses,
        "consistency_rate": _consistency_rate(syntheses),
        "resolution_coverage": _resolution_coverage(all_findings),
    }


def cmd_init(args: argparse.Namespace) -> int:
    out_path = Path(args.out).resolve()
    payload = _canonical(args.output_language, [], [])
    atomic_write(out_path, payload)
    return _emit(True, data={
        "out_path": str(out_path),
        "consistency_rate": payload["consistency_rate"],
        "resolution_coverage": payload["resolution_coverage"],
    })


def _latest_contradictor(project_path: Path) -> Path | None:
    """The highest-N `contradictor-vN.json` under <project>/.metadata/ (the latest
    finalize round). Returns None when none exist."""
    meta = project_path / ".metadata"
    best: tuple[int, Path] | None = None
    for hit in globmod.glob(str(meta / "contradictor-v*.json")):
        m = re.search(r"contradictor-v(\d+)\.json$", hit)
        if not m:
            continue
        n = int(m.group(1))
        if best is None or n > best[0]:
            best = (n, Path(hit))
    return best[1] if best else None


def cmd_record(args: argparse.Namespace) -> int:
    out_path = Path(args.out).resolve()

    # Resolve the contradictor envelope: explicit --contradictor wins, else the
    # latest contradictor-vN.json under the project.
    if args.contradictor:
        cpath: Path | None = Path(args.contradictor).resolve()
    elif args.project_path:
        cpath = _latest_contradictor(Path(args.project_path).resolve())
    else:
        return _emit(False, error="record requires --project-path or --contradictor")

    # Fail-soft: a missing / unreadable / schema-mismatched contradictor file
    # writes an empty artifact with a recorded reason — never aborts finalize.
    skipped_reason = ""
    syntheses: list[dict] = []
    all_findings: list[dict] = []

    if cpath is None or not cpath.exists():
        skipped_reason = "no contradictor-vN.json found (contradictor skipped or no synthesis)"
    else:
        try:
            env = json.loads(cpath.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            env = None
            skipped_reason = f"unreadable contradictor file: {exc}"
        if env is not None:
            if not isinstance(env, dict):
                skipped_reason = "contradictor file top-level is not a JSON object"
            elif env.get("schema_version") != CONTRADICTOR_SCHEMA_VERSION:
                skipped_reason = f"contradictor schema_version != {CONTRADICTOR_SCHEMA_VERSION}"
            elif not isinstance(env.get("findings"), list):
                skipped_reason = "contradictor file missing findings list"
            else:
                findings = [f for f in env["findings"] if isinstance(f, dict)]
                unresolved_high = _unresolved_high(findings)
                syntheses = [{
                    "synthesis_slug": env.get("synthesis_slug", cpath.stem),
                    "draft_version": env.get("draft_version"),
                    "findings": len(findings),
                    "unresolved_high": unresolved_high,
                    "clean": unresolved_high == 0,
                }]
                all_findings = findings

    payload = _canonical(args.output_language, syntheses, all_findings)
    atomic_write(out_path, payload)
    data = {
        "out_path": str(out_path),
        "consistency_rate": payload["consistency_rate"],
        "resolution_coverage": payload["resolution_coverage"],
        "syntheses": syntheses,
    }
    if skipped_reason:
        data["skipped_reason"] = skipped_reason
    return _emit(True, data=data)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Derive the synthesis-side consistency rate from contradictor-vN.json",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_init = sub.add_parser("init", help="Write an empty canonical contradiction-finalize.json")
    p_init.add_argument("--out", required=True, help="Path to the canonical contradiction-finalize.json")
    p_init.add_argument("--output-language", default="en", help="Output language tag (default en)")
    p_init.set_defaults(func=cmd_init)

    p_record = sub.add_parser("record", help="Compute the consistency rate from the project's contradictor-vN.json")
    p_record.add_argument("--project-path", help="Project root; uses the latest .metadata/contradictor-v*.json")
    p_record.add_argument("--contradictor", help="Explicit path to a contradictor-vN.json (overrides --project-path)")
    p_record.add_argument("--out", required=True, help="Path to the canonical contradiction-finalize.json")
    p_record.add_argument("--output-language", default="en", help="Output language tag (default en)")
    p_record.set_defaults(func=cmd_record)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
