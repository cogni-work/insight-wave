#!/usr/bin/env python3
"""
rebuild_context_brief.py — emit `wiki/context_brief.md`, the canonical
"first read" for a fresh Claude Code session.

Auto-invoked by Step 8.5 of `wiki-ingest` once per dispatch (after the
per-source loop). Stdlib-only. `{success, data, error}` JSON on stdout.

Sections, in order:

  1. Header             — wiki name, schema version, generated timestamp,
                          total page count.
  2. Type counts        — one line per `_wikilib.PAGE_TYPE_DIRS` entry.
  3. Top entities       — top 10 by inbound `[[backlink]]` count.
  4. Recent activity    — last 30 days of `wiki/log.md`, verbatim.
  5. Open lints (cached)— from `.cogni-wiki/last_lint.json` if present
                          and ≤ 24 h old; degrades gracefully otherwise.
  6. Health snapshot    — invokes `health.py` once (zero-LLM, sub-second).

A hard 8000-byte cap is enforced. If the assembled body exceeds it, the
recent-activity section is truncated first (it is the only section that
grows unboundedly with wiki age); type counts, entities, lints, and
health are constant-bounded and never truncated.

Failure isolation: a non-zero exit or unparseable JSON from this script
must never roll back the ingest. The brief is a derived artefact — the
next ingest will rebuild it.
"""

from __future__ import annotations

import argparse
import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

# `_wikilib` lives in this same directory.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import (  # noqa: E402
    PAGE_TYPE_DIRS,
    WIKILINK_RE,
    atomic_write,
    build_slug_index,
    emit_json,
    fail_if_pre_migration,
)


CONTEXT_BRIEF_PATH = "wiki/context_brief.md"

def _meta_first(wiki_root, filename):
    """Meta-first control-file resolution (cogni-knowledge divergence).

    The curated layout keeps the visible control files under `wiki/meta/`.
    Prefer `wiki/meta/<filename>` when it exists; fall back to an EXISTING
    legacy flat `wiki/<filename>` (pre-migration bases keep working); default
    a file absent from both layouts to `wiki/meta/` — the canonical location.
    Mirrors cogni-knowledge's `_knowledge_lib._resolve_control_path` so the
    vendored side can never desync from the CK-side writers. Self-contained
    on purpose: vendored scripts never import from cogni-knowledge/scripts/.
    """
    meta = Path(wiki_root) / "wiki" / "meta" / filename
    if meta.exists():
        return meta
    flat = Path(wiki_root) / "wiki" / filename
    if flat.exists():
        return flat
    return meta

HARD_CAP_BYTES = 8000
RECENT_DAYS = 30
TOP_N_ENTITIES = 10
LINT_CACHE_TTL_HOURS = 24

LOG_DATE_RE = re.compile(r"^## \[(\d{4}-\d{2}-\d{2})\]")


def _now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _today() -> datetime.date:
    return datetime.datetime.now(datetime.timezone.utc).date()


def _section_header(title: str) -> str:
    return f"## {title}\n\n"


def _build_header(wiki_root: Path, total_pages: int) -> str:
    cfg_path = wiki_root / ".cogni-wiki" / "config.json"
    name = "(unknown)"
    schema_version = "(unknown)"
    try:
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
        name = cfg.get("name") or name
        schema_version = cfg.get("schema_version") or schema_version
    except (OSError, json.JSONDecodeError):
        pass
    return (
        f"# Context brief — {name}\n\n"
        f"_Generated_: {_now_iso()}  \n"
        f"_Schema_: {schema_version}  \n"
        f"_Total pages_: {total_pages}\n\n"
        "This file is auto-rebuilt by `wiki-ingest`. Read this first; "
        "the rest of the wiki is a delta on top of what's here.\n\n"
    )


def _build_type_counts(slug_index: dict) -> str:
    counts = {ptype: 0 for ptype in PAGE_TYPE_DIRS}
    for _slug, (_path, ptype) in slug_index.items():
        if ptype in counts:
            counts[ptype] += 1
    out = [_section_header("Type counts")]
    for ptype in PAGE_TYPE_DIRS:
        out.append(f"- {PAGE_TYPE_DIRS[ptype]}: {counts[ptype]}\n")
    out.append("\n")
    return "".join(out)


def _build_top_entities(slug_index: dict, top_n: int) -> str:
    """Top N pages by inbound [[wikilink]] count.

    One linear pass over each page's body. O(pages × avg-page-length);
    sub-second on 100-page wikis per the health.py performance contract.
    """
    inbound = {slug: 0 for slug in slug_index}
    for _slug, (path, _ptype) in slug_index.items():
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        for m in WIKILINK_RE.finditer(text):
            target = m.group(1)
            if target in inbound:
                inbound[target] += 1

    ranked = sorted(
        ((slug, n) for slug, n in inbound.items() if n > 0),
        key=lambda kv: (-kv[1], kv[0]),
    )[:top_n]

    out = [_section_header(f"Top entities (by inbound backlinks, top {top_n})")]
    if not ranked:
        out.append("_No backlinks yet — wiki may be young or hand-edited._\n\n")
        return "".join(out)
    for slug, n in ranked:
        out.append(f"- [[{slug}]] — {n} inbound\n")
    out.append("\n")
    return "".join(out)


def _read_recent_log(wiki_root: Path, days: int) -> list:
    """Lines of the wiki log whose ISO-date prefix is within the last `days`."""
    log_path = _meta_first(wiki_root, "log.md")
    if not log_path.is_file():
        return []
    cutoff = _today() - datetime.timedelta(days=days)
    keep = []
    try:
        for line in log_path.read_text(encoding="utf-8").splitlines():
            m = LOG_DATE_RE.match(line)
            if not m:
                continue
            try:
                d = datetime.date.fromisoformat(m.group(1))
            except ValueError:
                continue
            if d >= cutoff:
                keep.append(line)
    except OSError:
        return []
    return keep


def _build_recent_activity(lines: list, days: int) -> str:
    out = [_section_header(f"Recent activity (last {days} days)")]
    if not lines:
        out.append("_No activity._\n\n")
        return "".join(out)
    for line in lines:
        out.append(line + "\n")
    out.append("\n")
    return "".join(out)


def _build_open_lints(wiki_root: Path) -> str:
    """Read `.cogni-wiki/last_lint.json` if present and ≤ TTL; else skip note.

    This skill never invokes `lint_wiki.py` itself — keeping the ingest
    path token-free is the entire point. The cache write hook is a
    follow-up; until then the section degrades to an inline note.
    """
    cache_path = wiki_root / ".cogni-wiki" / "last_lint.json"
    out = [_section_header("Open lints (cached)")]
    if not cache_path.is_file():
        out.append(
            "_No cached lint result — run `/cogni-wiki:wiki-lint` to populate._\n\n"
        )
        return "".join(out)
    try:
        mtime = datetime.datetime.fromtimestamp(
            cache_path.stat().st_mtime, datetime.timezone.utc
        )
        age_hours = (datetime.datetime.now(datetime.timezone.utc) - mtime).total_seconds() / 3600.0
    except OSError:
        out.append("_Cached lint mtime unreadable._\n\n")
        return "".join(out)
    if age_hours > LINT_CACHE_TTL_HOURS:
        out.append(
            f"_Cached lint is stale ({age_hours:.0f}h old) — run `/cogni-wiki:wiki-lint`._\n\n"
        )
        return "".join(out)
    try:
        cache = json.loads(cache_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        out.append("_Cached lint unreadable._\n\n")
        return "".join(out)
    data = cache.get("data") or {}
    errors = data.get("errors") or []
    warnings = data.get("warnings") or []
    if not errors and not warnings:
        out.append(f"_Clean (cached {age_hours:.0f}h ago)._\n\n")
        return "".join(out)
    for ent in errors[:10]:
        out.append(
            f"- ERROR | {ent.get('class', '?')} | {ent.get('page', '?')} | {ent.get('message', '')}\n"
        )
    for ent in warnings[:10]:
        out.append(
            f"- WARN  | {ent.get('class', '?')} | {ent.get('page', '?')} | {ent.get('message', '')}\n"
        )
    out.append("\n")
    return "".join(out)


def _build_health_snapshot(wiki_root: Path) -> str:
    out = [_section_header("Health snapshot")]
    health_script = (
        Path(__file__).resolve().parents[2] / "wiki-health" / "scripts" / "health.py"
    )
    if not health_script.is_file():
        out.append("_health.py not found._\n\n")
        return "".join(out)
    try:
        proc = subprocess.run(
            [sys.executable, str(health_script), "--wiki-root", str(wiki_root)],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        out.append(f"_health invocation failed: {exc}._\n\n")
        return "".join(out)
    if not proc.stdout:
        out.append("_health emitted no JSON._\n\n")
        return "".join(out)
    try:
        # health.py emits one JSON line on stdout; take the last non-empty line.
        last_line = [ln for ln in proc.stdout.splitlines() if ln.strip()][-1]
        payload = json.loads(last_line)
    except (json.JSONDecodeError, IndexError):
        out.append("_health JSON unparseable._\n\n")
        return "".join(out)
    if not payload.get("success"):
        out.append(f"_health failed: {payload.get('error', '')}._\n\n")
        return "".join(out)
    stats = (payload.get("data") or {}).get("stats") or {}
    out.append(
        f"- errors: {stats.get('errors', 0)}\n"
        f"- warnings: {stats.get('warnings', 0)}\n"
        f"- entries_count_drift: {stats.get('entries_count_drift', 0)}\n"
        f"- claim_drift_count: {stats.get('claim_drift_count', 0)}\n\n"
    )
    return "".join(out)


def _truncate_to_cap(sections: dict, recent_key: str, cap: int):
    """Assemble sections in canonical order; truncate `recent_key` first if over cap."""
    order = ["header", "type_counts", "top_entities", "recent", "lints", "health"]
    body = "".join(sections[k] for k in order)
    if len(body.encode("utf-8")) <= cap:
        return body, False

    # Drop trailing lines from `recent` until we fit, then append a marker.
    head, _, _tail = sections[recent_key].partition("\n\n")
    lines = head.splitlines(keepends=True)
    while lines:
        lines.pop()
        sections[recent_key] = "".join(lines) + "\n…(truncated)\n\n"
        body = "".join(sections[k] for k in order)
        if len(body.encode("utf-8")) <= cap:
            return body, True
    # Even with `recent` empty we're over: fall back to header alone.
    return sections["header"] + "…(truncated; even minimal sections exceed cap)\n", True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Rebuild wiki/context_brief.md (cogni-wiki #219)."
    )
    parser.add_argument("--wiki-root", required=True)
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        emit_json(False, error=f"not a wiki root: {wiki_root}")
        return 1

    fail_if_pre_migration(wiki_root)

    slug_index = build_slug_index(wiki_root, include_audit=False)

    sections = {
        "header": _build_header(wiki_root, len(slug_index)),
        "type_counts": _build_type_counts(slug_index),
        "top_entities": _build_top_entities(slug_index, TOP_N_ENTITIES),
        "recent": _build_recent_activity(_read_recent_log(wiki_root, RECENT_DAYS), RECENT_DAYS),
        "lints": _build_open_lints(wiki_root),
        "health": _build_health_snapshot(wiki_root),
    }

    body, truncated = _truncate_to_cap(sections, "recent", HARD_CAP_BYTES)
    out_path = _meta_first(wiki_root, "context_brief.md")
    try:
        atomic_write(out_path, body)
    except OSError as exc:
        emit_json(False, error=f"atomic_write failed: {exc}")
        return 1

    emit_json(
        True,
        data={
            "path": str(out_path.relative_to(wiki_root)),
            "bytes": len(body.encode("utf-8")),
            "truncated": truncated,
            "sections": list(sections.keys()),
            "total_pages": len(slug_index),
        },
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
