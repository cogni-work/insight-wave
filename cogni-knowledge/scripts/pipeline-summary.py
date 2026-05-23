#!/usr/bin/env python3
"""
pipeline-summary.py — read-side summaries of the v0.1.0 inverted pipeline.

The read-side skills (knowledge-query / knowledge-dashboard / knowledge-resume)
need two views the binding alone cannot give them:

  project       Per-project inverted-pipeline state, derived from the six
                manifests under <project>/.metadata/. Counts sub-questions,
                candidates, fetched/unavailable, ingested/skipped, citations,
                and the latest verify round's verdict tallies.

  cache-health  Knowledge-base-global fetch-cache health: entry count,
                negative-cache ratio, oldest-entry age vs the binding's
                curator_defaults.fetch_cache_max_age_days, and a verdict.
                Reuses `fetch-cache.py stat` rather than re-walking the cache.

Both degrade gracefully: a legacy v0.0.x project (cogni-research layout, no
inverted-pipeline manifests) returns zeros + phase_reached="none" rather than
crashing — same posture as cmd_read in knowledge-binding.py. Every manifest
read uses `.get(..., DEFAULT)`.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

METADATA_DIRNAME = ".metadata"
BINDING_DIRNAME = ".cogni-knowledge"
BINDING_FILENAME = "binding.json"
# Default fetch-cache freshness window — mirrors knowledge-binding.py's
# DEFAULT_CURATOR_DEFAULTS so a pre-0.0.3 binding (no curator_defaults block)
# still produces a verdict instead of None.
DEFAULT_FETCH_CACHE_MAX_AGE_DAYS = 30

# Furthest-phase ordering. A phase is "reached" when its manifest is present.
# `finalize` is not manifest-backed at the project level (it deposits to the
# wiki + binding), so the deepest project-local phase is `verify`.
_PHASE_ORDER = ["plan", "curate", "fetch", "ingest", "compose", "verify"]
_VERIFY_RE = re.compile(r"^verify-v(\d+)\.json$")


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _load_json(path: Path) -> dict | None:
    """Read a JSON object, or None if absent / unparseable.

    A malformed manifest is treated as absent rather than fatal — the
    read-side skills must still render the rest of the summary.
    """
    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, NotADirectoryError, json.JSONDecodeError):
        return None
    return loaded if isinstance(loaded, dict) else None


def _count(obj: dict | None, key: str) -> int:
    if not obj:
        return 0
    val = obj.get(key)
    return len(val) if isinstance(val, list) else 0


def _latest_verify(metadata: Path) -> tuple[int, dict] | None:
    """Return (N, parsed) for the highest verify-vN.json, or None."""
    best: tuple[int, dict] | None = None
    if not metadata.is_dir():
        return None
    for entry in metadata.iterdir():
        m = _VERIFY_RE.match(entry.name)
        if not m:
            continue
        parsed = _load_json(entry)
        if parsed is None:
            continue
        n = int(m.group(1))
        if best is None or n > best[0]:
            best = (n, parsed)
    return best


def cmd_project(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    metadata = project_path / METADATA_DIRNAME

    plan = _load_json(metadata / "plan.json")
    candidates = _load_json(metadata / "candidates.json")
    fetch = _load_json(metadata / "fetch-manifest.json")
    ingest = _load_json(metadata / "ingest-manifest.json")
    citation = _load_json(metadata / "citation-manifest.json")
    verify = _latest_verify(metadata)

    # phase_reached = deepest phase whose manifest is present on disk.
    present = {
        "plan": plan is not None,
        "curate": candidates is not None,
        "fetch": fetch is not None,
        "ingest": ingest is not None,
        "compose": citation is not None,
        "verify": verify is not None,
    }
    phase_reached = "none"
    for phase in _PHASE_ORDER:
        if present[phase]:
            phase_reached = phase

    verify_counts = {
        "verbatim": 0,
        "paraphrase": 0,
        "synthesis": 0,
        "unsupported": 0,
        "total": 0,
    }
    revision_round = 0
    verify_version = None
    if verify is not None:
        verify_version, verify_obj = verify
        raw_counts = verify_obj.get("counts")
        if isinstance(raw_counts, dict):
            for key in verify_counts:
                got = raw_counts.get(key, 0)
                verify_counts[key] = got if isinstance(got, int) else 0
        revision_round = verify_obj.get("revision_round", 0)
        if not isinstance(revision_round, int):
            revision_round = 0

    data = {
        "project_path": str(project_path),
        "topic": (plan or {}).get("topic", ""),
        "sub_questions": _count(plan, "sub_questions"),
        "candidates": _count(candidates, "candidates"),
        "fetched": _count(fetch, "fetched"),
        "unavailable": _count(fetch, "unavailable"),
        "ingested": _count(ingest, "ingested"),
        "skipped": _count(ingest, "skipped"),
        "citations": _count(citation, "citations"),
        "draft_version": (citation or {}).get("draft_version", 0),
        "verify_version": verify_version,
        "verify_counts": verify_counts,
        "revision_round": revision_round,
        "phase_reached": phase_reached,
    }
    return _emit(True, data=data)


def _read_max_age_days(knowledge_root: Path) -> float:
    """Pull curator_defaults.fetch_cache_max_age_days from the binding.

    Falls back to the default when the binding is missing the field (pre-0.0.3
    schema) or unreadable — the cache health view should never hard-fail on a
    binding quirk.
    """
    binding = _load_json(knowledge_root / BINDING_DIRNAME / BINDING_FILENAME)
    if not binding:
        return float(DEFAULT_FETCH_CACHE_MAX_AGE_DAYS)
    defaults = binding.get("curator_defaults")
    if not isinstance(defaults, dict):
        return float(DEFAULT_FETCH_CACHE_MAX_AGE_DAYS)
    val = defaults.get("fetch_cache_max_age_days", DEFAULT_FETCH_CACHE_MAX_AGE_DAYS)
    try:
        return float(val)
    except (TypeError, ValueError):
        return float(DEFAULT_FETCH_CACHE_MAX_AGE_DAYS)


def cmd_cache_health(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    if not knowledge_root.is_dir():
        return _emit(False, error=f"knowledge_root does not exist: {knowledge_root}")

    # Reuse fetch-cache.py's stat rather than re-walking the cache — it is the
    # single source of truth for entry/age accounting.
    stat_script = Path(__file__).resolve().parent / "fetch-cache.py"
    try:
        proc = subprocess.run(
            [
                sys.executable,
                str(stat_script),
                "stat",
                "--knowledge-root",
                str(knowledge_root),
            ],
            capture_output=True,
            text=True,
        )
    except OSError as exc:
        return _emit(False, error=f"failed to invoke fetch-cache.py stat: {exc}")

    try:
        envelope = json.loads(proc.stdout)
    except json.JSONDecodeError:
        return _emit(
            False,
            error=f"fetch-cache.py stat returned non-JSON output: {proc.stdout!r}",
        )
    if not envelope.get("success"):
        return _emit(False, error=f"fetch-cache.py stat failed: {envelope.get('error')}")

    stat = envelope.get("data", {})
    entries = stat.get("entries", 0) or 0
    ok = stat.get("ok", 0) or 0
    unavailable = stat.get("unavailable", 0) or 0
    oldest_age_days = stat.get("oldest_age_days")
    max_age_days = _read_max_age_days(knowledge_root)

    negative_ratio = round(unavailable / entries, 3) if entries else 0.0

    if entries == 0:
        verdict = "empty"
    elif oldest_age_days is not None and oldest_age_days > max_age_days:
        verdict = "stale"
    else:
        verdict = "healthy"

    return _emit(
        True,
        data={
            "scope": "knowledge-base-global",
            "entries": entries,
            "ok": ok,
            "unavailable": unavailable,
            "negative_ratio": negative_ratio,
            "oldest_age_days": oldest_age_days,
            "max_age_days": max_age_days,
            "verdict": verdict,
        },
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read-side summaries of the v0.1.0 inverted pipeline.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_project = sub.add_parser("project", help="Per-project inverted-pipeline state.")
    p_project.add_argument("--project-path", required=True)
    p_project.set_defaults(func=cmd_project)

    p_cache = sub.add_parser("cache-health", help="Knowledge-base-global fetch-cache health.")
    p_cache.add_argument("--knowledge-root", required=True)
    p_cache.set_defaults(func=cmd_cache_health)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
