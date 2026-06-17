#!/usr/bin/env python3
"""
run-metrics.py — persistent per-phase timing + cost ledger for the inverted
pipeline (the B1 observability primitive).

Every phase skill (knowledge-setup … knowledge-finalize) records one row at
phase exit, so a run leaves a durable `<project>/.metadata/run-metrics.json`
the read-side skills (knowledge-resume / knowledge-dashboard) and any perf
study can read without hand-instrumenting the pipeline. Phases already compute
their own cost + agent counts in their final summary; this just persists them.

  record   Append one phase row to run-metrics.json. Append-only — a re-run of
           a phase appends a new row (a real event), and `report` sums them, so
           retries are visible rather than silently overwritten.

  report   Read run-metrics.json and emit the phase rows plus totals
           (elapsed_s, cost_estimate_usd, agent_count) and a rendered table.
           This is the read surface knowledge-resume / a perf study consume.

Both degrade gracefully: `report` on a project with no ledger yet returns an
empty-but-valid envelope rather than crashing (same posture as
pipeline-summary.py cmd_project on a legacy project).

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import atomic_write  # noqa: E402

SCHEMA_VERSION = "0.1.0"
METADATA_DIRNAME = ".metadata"
LEDGER_FILENAME = "run-metrics.json"

# Canonical phase order for the rendered report. An unknown phase still records
# and reports — it simply sorts after the known phases (stable by insertion).
_PHASE_ORDER = [
    "setup", "plan", "curate", "fetch", "ingest",
    "distill", "compose", "verify", "finalize",
]


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _now_iso() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _ledger_path(project_path: str) -> Path:
    return Path(project_path) / METADATA_DIRNAME / LEDGER_FILENAME


def _load(path: Path) -> dict:
    if not path.exists():
        return {"schema_version": SCHEMA_VERSION, "phases": []}
    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        # Corrupt / unreadable ledger: start fresh rather than abort a phase
        # exit on an observability artifact. The lost rows are non-critical.
        return {"schema_version": SCHEMA_VERSION, "phases": []}
    if not isinstance(doc, dict) or not isinstance(doc.get("phases"), list):
        return {"schema_version": SCHEMA_VERSION, "phases": []}
    doc.setdefault("schema_version", SCHEMA_VERSION)
    return doc


def cmd_record(args: argparse.Namespace) -> int:
    meta_dir = Path(args.project_path) / METADATA_DIRNAME
    if not meta_dir.is_dir():
        return _emit(False, error=f"no .metadata/ under project path: {args.project_path}")

    elapsed = args.elapsed_s
    if elapsed is None and args.started_at and args.ended_at:
        try:
            t0 = _dt.datetime.strptime(args.started_at, "%Y-%m-%dT%H:%M:%SZ")
            t1 = _dt.datetime.strptime(args.ended_at, "%Y-%m-%dT%H:%M:%SZ")
            elapsed = round((t1 - t0).total_seconds(), 1)
        except ValueError:
            elapsed = None

    row = {
        "phase": args.phase,
        "started_at": args.started_at or "",
        "ended_at": args.ended_at or "",
        "elapsed_s": elapsed,
        "agent_count": args.agent_count,
        "cost_estimate_usd": round(args.cost_usd, 4),
        "recorded_at": _now_iso(),
    }

    path = _ledger_path(args.project_path)
    doc = _load(path)
    doc["phases"].append(row)
    atomic_write(path, doc)
    return _emit(True, data={"recorded": row, "phases_total": len(doc["phases"]), "path": str(path)})


def _phase_sort_key(phase: str):
    try:
        return (0, _PHASE_ORDER.index(phase))
    except ValueError:
        return (1, 0)  # unknown phases after known, stable insertion otherwise


def cmd_report(args: argparse.Namespace) -> int:
    path = _ledger_path(args.project_path)
    doc = _load(path)
    phases = doc.get("phases", [])

    total_elapsed = round(sum((p.get("elapsed_s") or 0.0) for p in phases), 1)
    total_cost = round(sum((p.get("cost_estimate_usd") or 0.0) for p in phases), 4)
    total_agents = sum(int(p.get("agent_count") or 0) for p in phases)

    ordered = sorted(phases, key=lambda p: _phase_sort_key(p.get("phase", "")))

    lines = ["phase        elapsed_s     %   agents    cost_usd"]
    for p in ordered:
        el = p.get("elapsed_s") or 0.0
        pct = (100.0 * el / total_elapsed) if total_elapsed else 0.0
        lines.append(
            f"{str(p.get('phase','?'))[:12]:12s} {el:9.1f} {pct:5.1f}% "
            f"{int(p.get('agent_count') or 0):6d}   ${p.get('cost_estimate_usd') or 0.0:.4f}"
        )
    lines.append(
        f"{'TOTAL':12s} {total_elapsed:9.1f} {100.0 if total_elapsed else 0.0:5.1f}% "
        f"{total_agents:6d}   ${total_cost:.4f}"
    )

    return _emit(True, data={
        "phases": ordered,
        "totals": {
            "elapsed_s": total_elapsed,
            "elapsed_min": round(total_elapsed / 60.0, 1),
            "cost_estimate_usd": total_cost,
            "agent_count": total_agents,
        },
        "rendered": "\n".join(lines),
        "ledger_present": path.exists(),
    })


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Persistent per-phase timing + cost ledger for the inverted pipeline.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_rec = sub.add_parser("record", help="Append one phase row at phase exit.")
    p_rec.add_argument("--project-path", required=True)
    p_rec.add_argument("--phase", required=True,
                       help="Phase name, e.g. setup|plan|curate|fetch|ingest|distill|compose|verify|finalize.")
    p_rec.add_argument("--elapsed-s", type=float, default=None,
                       help="Wall-clock seconds for the phase. If omitted but --started-at/--ended-at are given, computed.")
    p_rec.add_argument("--started-at", default="", help="ISO 8601 UTC (YYYY-MM-DDThh:mm:ssZ).")
    p_rec.add_argument("--ended-at", default="", help="ISO 8601 UTC (YYYY-MM-DDThh:mm:ssZ).")
    p_rec.add_argument("--agent-count", type=int, default=0, help="Subagents dispatched in this phase.")
    p_rec.add_argument("--cost-usd", type=float, default=0.0,
                       help="Summed cost_estimate.estimated_usd across this phase's agents.")
    p_rec.set_defaults(func=cmd_record)

    p_rep = sub.add_parser("report", help="Read the ledger; emit phase rows + totals + a rendered table.")
    p_rep.add_argument("--project-path", required=True)
    p_rep.set_defaults(func=cmd_report)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
