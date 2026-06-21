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
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import classify_claim_kind  # noqa: E402

METADATA_DIRNAME = ".metadata"
BINDING_DIRNAME = ".cogni-knowledge"
BINDING_FILENAME = "binding.json"
# Default fetch-cache freshness window — mirrors knowledge-binding.py's
# DEFAULT_CURATOR_DEFAULTS so a pre-0.0.3 binding (no curator_defaults block)
# still produces a verdict instead of None.
DEFAULT_FETCH_CACHE_MAX_AGE_DAYS = 30

# Furthest-phase ordering. A phase is "reached" when its manifest is present.
# `finalize` deposits to the wiki + binding rather than a `.metadata/` manifest,
# so it is detected from two deterministic on-disk artifacts instead: a
# `run-metrics.json` row with `phase == "finalize"` (the durable per-phase
# ledger) OR a `binding.json::research_projects[]` entry whose `project_path`
# matches this project — see `_finalize_reached`. Both must be added to
# `_PHASE_ORDER` and the `cmd_project` `present{}` dict in lockstep: the
# `phase_reached` loop indexes `present[phase]`, so a `_PHASE_ORDER` entry with
# no matching `present` key would raise `KeyError`.
_PHASE_ORDER = ["plan", "curate", "fetch", "ingest", "distill", "compose", "verify", "finalize"]
_VERIFY_RE = re.compile(r"^verify-v(\d+)\.json$")


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _load_json(path: Path) -> dict | None:
    """Read a JSON object, or None if absent / unreadable / unparseable.

    A manifest that is missing, is a directory, is unreadable, or holds
    invalid JSON is treated as absent rather than fatal — the read-side
    skills must still render the rest of the summary. `OSError` covers the
    full family of read failures (FileNotFoundError, NotADirectoryError,
    IsADirectoryError, PermissionError); `JSONDecodeError` covers bad bytes.
    """
    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    return loaded if isinstance(loaded, dict) else None


def _count(obj: dict | None, key: str) -> int:
    if not obj:
        return 0
    val = obj.get(key)
    return len(val) if isinstance(val, list) else 0


def _as_int(value) -> int:
    """Coerce a manifest value to a non-negative int, else 0.

    `bool` is a subclass of `int` in Python, so a JSON `true`/`false` would
    pass a bare `isinstance(x, int)` check and surface as `True`/`False`;
    exclude it explicitly so a malformed manifest degrades to 0 rather than
    leaking a boolean into the count fields.
    """
    return value if isinstance(value, int) and not isinstance(value, bool) else 0


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


def _finalize_reached(project_path: Path, knowledge_root: Path | None) -> bool:
    """True when the project has been finalized (synthesis deposited).

    Finalize leaves no `.metadata/` manifest, so it is detected from two
    deterministic on-disk artifacts, OR'd so either alone suffices:

    1. **run-metrics ledger** — `<project>/.metadata/run-metrics.json` carries a
       `phases[]` row with `phase == "finalize"`. Self-contained (needs only
       `project_path`), present on any run on the run-metrics-ledger line.
    2. **binding deposit record** — the bound `binding.json::research_projects[]`
       carries an entry whose `project_path` matches this project. The canonical
       finalize artifact, independent of the run-metrics ledger (covers a
       project finalized before the ledger landed). The binding sits at
       `<knowledge_root>/.cogni-knowledge/binding.json`; `knowledge_root`
       defaults to `project_path.parent` by the `<knowledge_root>/<slug>/`
       layout convention when `--knowledge-root` is not supplied.

    Both legs are fail-soft reads — a missing/unreadable ledger or binding
    simply contributes `False`, never an exception.
    """
    ledger = _load_json(project_path / METADATA_DIRNAME / "run-metrics.json")
    if ledger and isinstance(ledger.get("phases"), list):
        if any(
            isinstance(p, dict) and p.get("phase") == "finalize"
            for p in ledger["phases"]
        ):
            return True

    root = knowledge_root if knowledge_root is not None else project_path.parent
    binding = _load_json(root / BINDING_DIRNAME / BINDING_FILENAME)
    if binding and isinstance(binding.get("research_projects"), list):
        target = str(project_path)
        if any(
            isinstance(p, dict) and p.get("project_path") == target
            for p in binding["research_projects"]
        ):
            return True

    return False


def cmd_project(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    metadata = project_path / METADATA_DIRNAME
    knowledge_root = (
        Path(args.knowledge_root).resolve()
        if getattr(args, "knowledge_root", None)
        else None
    )

    plan = _load_json(metadata / "plan.json")
    candidates = _load_json(metadata / "candidates.json")
    fetch = _load_json(metadata / "fetch-manifest.json")
    ingest = _load_json(metadata / "ingest-manifest.json")
    distill = _load_json(metadata / "distill-manifest.json")
    citation = _load_json(metadata / "citation-manifest.json")
    verify = _latest_verify(metadata)

    # phase_reached = deepest phase whose manifest is present on disk. Distill
    # (Phase 4.5) is optional + fail-soft, so its manifest may be absent on a
    # run that skipped it — present=False simply leaves phase_reached at the last
    # phase that did run (the deeper compose/verify still advance it).
    present = {
        "plan": plan is not None,
        "curate": candidates is not None,
        "fetch": fetch is not None,
        "ingest": ingest is not None,
        "distill": distill is not None,
        "compose": citation is not None,
        "verify": verify is not None,
        "finalize": _finalize_reached(project_path, knowledge_root),
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
    # Additive at verify-vN.json schema 0.1.1 (grounding L3): the headline
    # draft<->excerpt grounding rate. None on a legacy 0.1.0 file (no block) or
    # when nothing was scorable — fail-soft, read via .get like verify_counts.
    grounding_rate = None
    if verify is not None:
        verify_version, verify_obj = verify
        raw_counts = verify_obj.get("counts")
        if isinstance(raw_counts, dict):
            for key in verify_counts:
                verify_counts[key] = _as_int(raw_counts.get(key, 0))
        revision_round = _as_int(verify_obj.get("revision_round", 0))
        raw_grounding = verify_obj.get("grounding_metrics")
        if isinstance(raw_grounding, dict):
            grounding_rate = raw_grounding.get("grounding_rate")

    # Distill (Phase 4.5) read-side counts — concept/entity pages created/updated
    # this run + the claim-dedup ratio (the Finding-H success metric, #336).
    concepts = (distill or {}).get("concepts", [])
    if not isinstance(concepts, list):
        concepts = []
    distill_actions = {"created": 0, "updated": 0, "unchanged": 0, "skipped": 0}
    for c in concepts:
        a = c.get("action") if isinstance(c, dict) else None
        if a in distill_actions:
            distill_actions[a] += 1

    # Per-kind citation breakdown across runs (#385): derive the distilled (dcl-) /
    # source (clm-) / null split from the persisted manifest so the read-side
    # summary (knowledge-resume / knowledge-dashboard) surfaces the distilled-
    # citation rate over time, not just in the ephemeral compose summary. Uses the
    # same `classify_claim_kind` the write-side `citation-store.py build` reports,
    # so both sides bucket identically. Degrades to {} on a missing/legacy manifest.
    cits = (citation or {}).get("citations", [])
    citation_kinds = (
        Counter(classify_claim_kind(c.get("claim_id")) for c in cits if isinstance(c, dict))
        if isinstance(cits, list)
        else Counter()
    )

    # Contradiction track read-side (#908): surface the ingest-time recency coverage
    # AND the finalize-time synthesis consistency rate so the read-side summary
    # (knowledge-resume / knowledge-dashboard) shows the contradiction scoreboard,
    # not just the per-run finalize line. Both are fail-soft reads (missing file ->
    # None), matching every other manifest read in this function.
    ingest_contra = _load_json(metadata / "contradiction-ingest.json")
    finalize_contra = _load_json(metadata / "contradiction-finalize.json")
    resolution_coverage = (ingest_contra or {}).get("resolution_coverage")
    consistency_rate = (finalize_contra or {}).get("consistency_rate")

    data = {
        "project_path": str(project_path),
        "topic": (plan or {}).get("topic", ""),
        "sub_questions": _count(plan, "sub_questions"),
        "candidates": _count(candidates, "candidates"),
        "fetched": _count(fetch, "fetched"),
        "unavailable": _count(fetch, "unavailable"),
        "ingested": _count(ingest, "ingested"),
        "skipped": _count(ingest, "skipped"),
        "concepts_created": distill_actions["created"],
        "concepts_updated": distill_actions["updated"],
        "concepts_total": len(concepts),
        "claims_attached": _as_int((distill or {}).get("claims_attached_total", 0)),
        "claims_deduped": _as_int((distill or {}).get("claims_deduped_total", 0)),
        "citations": _count(citation, "citations"),
        "citation_kinds": citation_kinds,
        "draft_version": (citation or {}).get("draft_version", 0),
        "verify_version": verify_version,
        "verify_counts": verify_counts,
        "grounding_rate": grounding_rate,
        "resolution_coverage": resolution_coverage,
        "consistency_rate": consistency_rate,
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
            timeout=30,
        )
    except subprocess.TimeoutExpired:
        return _emit(False, error="fetch-cache.py stat timed out after 30s")
    except OSError as exc:
        return _emit(False, error=f"failed to invoke fetch-cache.py stat: {exc}")

    # Surface the child's exit code + stderr on failure — otherwise a crash in
    # fetch-cache.py (traceback to stderr, empty stdout) is reported only as an
    # opaque "non-JSON output: ''", hiding the real diagnostic.
    stderr_tail = (proc.stderr or "").strip()[:500]
    if proc.returncode != 0 and not proc.stdout.strip():
        return _emit(
            False,
            error=f"fetch-cache.py stat exited {proc.returncode}: {stderr_tail or '(no output)'}",
        )

    try:
        envelope = json.loads(proc.stdout)
    except json.JSONDecodeError:
        suffix = f" (stderr: {stderr_tail})" if stderr_tail else ""
        return _emit(
            False,
            error=f"fetch-cache.py stat returned non-JSON output: {proc.stdout!r}{suffix}",
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


# --- portal-staleness ---------------------------------------------------------
# Reads the curated-portal staleness stamp the #491 auto-refresh writes but
# nothing read yet. `wiki_index_update.py --set-leadin` stamps each engine-owned
# lead-in span with `MACHINE-OWNED:PORTAL-LEADIN:START refreshed:<date> bullets:<N>`,
# where <N> is the slug-bullet count under that theme at stamp time. Drift = the
# theme's CURRENT slug-bullet count exceeds the stamped <N> by more than the
# threshold (the lead-in prose no longer reflects what's accumulated under it).
#
# The section/heading/sentinel regexes mirror cogni-wiki's wiki_index_update.py
# (HEADING_RE, _LEADIN_START_RE) so this reader stays in lockstep with the
# producer. They are reimplemented locally on purpose: the dependency direction
# is cogni-knowledge -> cogni-wiki only, and this is a read-only script.
DEFAULT_PORTAL_STALENESS_THRESHOLD = 2
_HEADING_RE = re.compile(r"^(#{2,3})\s+(.*?)\s*$")
_LEADIN_START_RE = re.compile(
    r"^\s*<!--\s*MACHINE-OWNED:PORTAL-LEADIN:START\b[^>]*-->\s*$"
)
_LEADIN_END_RE = re.compile(r"^\s*<!--\s*MACHINE-OWNED:PORTAL-LEADIN:END\s*-->\s*$")
_LEADIN_BULLETS_RE = re.compile(r"\bbullets:(\d+)\b")
# A slug-bullet is an index row: a `- ` list item carrying a `[[<slug>]]`
# wikilink. Sufficient to count rows the way `_extract_slug_from_line` does
# producer-side, without importing it.
_SLUG_BULLET_RE = re.compile(r"^\s*-\s.*\[\[[^\]]+\]\]")


def _portal_stale_themes(index_text: str, threshold: int) -> list[dict]:
    """Return per-theme drift records for themes whose machine lead-in is stale
    by more than `threshold`. A theme with no machine lead-in span carries no
    stamp and is skipped; a theme whose START stamp lacks a parseable
    `bullets:<N>` is also skipped (nothing to compare against)."""
    lines = index_text.splitlines()
    # Section bounds: each `## `/`### ` heading opens a section that runs to the
    # next heading (or EOF).
    sections: list[tuple[str, int, int]] = []  # (theme, body_start, body_end_excl)
    cur_theme: str | None = None
    cur_start = 0
    for i, line in enumerate(lines):
        m = _HEADING_RE.match(line)
        if m:
            if cur_theme is not None:
                sections.append((cur_theme, cur_start, i))
            cur_theme = m.group(2).strip()
            cur_start = i + 1
    if cur_theme is not None:
        sections.append((cur_theme, cur_start, len(lines)))

    stale: list[dict] = []
    for theme, start, end in sections:
        stamped: int | None = None
        live = 0
        in_leadin = False
        for line in lines[start:end]:
            if _LEADIN_START_RE.match(line):
                in_leadin = True
                mb = _LEADIN_BULLETS_RE.search(line)
                if mb:
                    stamped = int(mb.group(1))
                continue
            if _LEADIN_END_RE.match(line):
                in_leadin = False
                continue
            if in_leadin:
                continue  # lead-in prose never carries slug-bullets
            if _SLUG_BULLET_RE.match(line):
                live += 1
        if stamped is None:
            continue  # no engine-owned stamp -> not a drift candidate
        delta = live - stamped
        if delta > threshold:
            stale.append({
                "theme": theme,
                "stamped_bullets": stamped,
                "live_bullets": live,
                "delta": delta,
            })
    return stale


def cmd_portal_staleness(args: argparse.Namespace) -> int:
    threshold = args.threshold
    index_path = Path(args.wiki_root) / "wiki" / "index.md"
    # Fail-soft: a base with no portal (or an unreadable index) is not an error;
    # it simply has nothing stale to report. Mirrors cmd_cache_health's degrade.
    try:
        index_text = index_path.read_text(encoding="utf-8")
    except OSError:
        return _emit(True, {"stale_count": 0, "threshold": threshold, "stale_themes": []})
    stale = _portal_stale_themes(index_text, threshold)
    return _emit(True, {
        "stale_count": len(stale),
        "threshold": threshold,
        "stale_themes": stale,
    })


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read-side summaries of the v0.1.0 inverted pipeline.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_project = sub.add_parser("project", help="Per-project inverted-pipeline state.")
    p_project.add_argument("--project-path", required=True)
    p_project.add_argument(
        "--knowledge-root",
        default=None,
        help="Knowledge-base root (dir holding .cogni-knowledge/binding.json) for the "
             "finalize binding-deposit check. Defaults to the project-path parent by the "
             "<knowledge_root>/<slug>/ layout convention.",
    )
    p_project.set_defaults(func=cmd_project)

    p_cache = sub.add_parser("cache-health", help="Knowledge-base-global fetch-cache health.")
    p_cache.add_argument("--knowledge-root", required=True)
    p_cache.set_defaults(func=cmd_cache_health)

    p_portal = sub.add_parser(
        "portal-staleness",
        help="Per-theme curated-portal lead-in drift (live slug-bullets vs the "
             "stamped bullets:<N>); silent on zero drift.",
    )
    p_portal.add_argument("--wiki-root", required=True)
    p_portal.add_argument(
        "--threshold", type=int, default=DEFAULT_PORTAL_STALENESS_THRESHOLD,
        help="A theme is stale when live - stamped exceeds this (default %(default)s).",
    )
    p_portal.set_defaults(func=cmd_portal_staleness)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
