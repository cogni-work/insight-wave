#!/usr/bin/env python3
"""
lint_wiki.py — semantic / narrative deterministic warnings for a Karpathy-style wiki.

Emits JSON on stdout with three severity tiers plus optional fix/suggest blocks:
    {"success": true,
     "data": {
       "errors":      [],                          # always empty as of v0.0.31
       "warnings":    [{"class": "...", "page": "...", "message": "..."}, ...],
       "info":        [...],
       "stats":       { ... },
       "fixed":       [{"class": "...", "page": "...", "applied": bool, "change": "..."}],   # v0.0.32+, --fix
       "failed":      [{"class": "...", "page": "...", "error": "..."}],                     # v0.0.32+, --fix
       "suggestions": [{"class": "...", "page": "...", "proposed_action": "...", ...}]       # v0.0.32+, --suggest
     },
     "error": ""}

Detects:
    - Synthesis pages missing wiki:// sources       (synthesis_no_wiki_source)
    - Pages missing sources when type requires them (no_sources)
    - Orphan pages (no inbound wikilinks)            (orphan_page)
    - Stale drafts / stale pages                     (stale_draft, stale_page)
    - Tag typos (edit distance ≤ TAG_TYPO_MAX_DIST)  (tag_typo)
    - Reverse link missing — SCHEMA R1               (reverse_link_missing)
    - Claim-drift bridge from wiki-claims-resweep   (claim_drift)

Semantic checks (contradictions, type drift, missing concept pages,
undercited claims) are NOT handled here — they run from the calling Claude
skill with this script's output as a starting point.

**Structural integrity is owned by `wiki-health` (v0.0.27+).** As of
v0.0.31, the deterministic structural checks that pre-dated the split
(`broken_wikilink`, `missing_frontmatter`, `id_mismatch`, `invalid_type`,
`missing_source`, `broken_wiki_source`, `read_error`) have been removed
from this script. Run `health.py` for those — both scripts use the same
`{success, data, error}` JSON contract and the same severity vocabulary,
so consumers (lint reports, `wiki-refresh`, `rebuild_open_questions.py`)
that need a unified picture can read both. Closes #212 Tier 2 item #6
(#223); deferred from #217 to give `wiki-refresh` time to settle.

**Auto-fix and suggestion modes (v0.0.32+, #222).** The deterministic
fixers that prior PRs (#213, #216, #217) explicitly deferred are now
folded in behind opt-in flags:

    --fix=<class>         apply the deterministic fix for one or more lint
                          classes (composes; --fix=all enables every safe
                          class). Supported: reverse_link_missing,
                          synthesis_no_wiki_source, entries_count_drift,
                          frontmatter_defaults, alphabetisation.
    --suggest             emit `data.suggestions[]` — structured proposals
                          for prose-shaped findings (orphan_page, stale_*,
                          claim_drift, tag_typo). Schema is documented in
                          SKILL.md; no consumer wires it yet, the schema
                          ships first.
    --dry-run             pair with --fix and/or --suggest: compute the
                          plan but do not write. `applied: false` on every
                          `data.fixed[]` entry.

Page-body fixers (reverse_link_missing, synthesis_no_wiki_source,
frontmatter_defaults) run inside one `_wiki_lock(wiki_root)` block so they
serialise against concurrent `wiki-ingest` runs. The two scripted fixers
(`entries_count_drift` → `config_bump.py --set-int`, `alphabetisation` →
`wiki_index_update.py --reflow-only`) run after the lock is released and
acquire their own.

Layout: as of v0.0.28 pages live under per-type subdirectories
(`wiki/concepts/`, `wiki/decisions/`, …) plus `wiki/audits/` for `lint-*.md`
and `health-*.md` reports. The traversal is owned by `_wikilib.iter_pages()`.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "wiki-ingest" / "scripts"))
from _wikilib import (  # noqa: E402
    _wiki_lock,
    atomic_write,
    build_slug_index,
    fail_if_pre_migration,
    is_audit_slug,
    iter_pages,
)


WIKI_INGEST_SCRIPTS = (
    Path(__file__).resolve().parent.parent.parent / "wiki-ingest" / "scripts"
)
CONFIG_BUMP_SCRIPT = WIKI_INGEST_SCRIPTS / "config_bump.py"
WIKI_INDEX_UPDATE_SCRIPT = WIKI_INGEST_SCRIPTS / "wiki_index_update.py"

FIX_CLASSES = (
    "reverse_link_missing",
    "synthesis_no_wiki_source",
    "entries_count_drift",
    "frontmatter_defaults",
    "alphabetisation",
)
FIX_CHOICES = (*FIX_CLASSES, "all")

# Date formats accepted by --fix=frontmatter_defaults when normalising
# `updated:` to ISO. Order matters — the first matching format wins.
DATE_NORMALIZE_FORMATS = (
    "%Y/%m/%d",
    "%d-%m-%Y",
    "%d/%m/%Y",
    "%m/%d/%Y",
    "%B %d, %Y",
    "%b %d, %Y",
    "%d %B %Y",
    "%d %b %Y",
)

REVERSE_LINK_SOURCE_RE = re.compile(r"\[\[([a-z0-9][a-z0-9\-]*)\]\] links here")
TAG_TYPO_MSG_RE = re.compile(
    r"^'(?P<bad>[^']+)' \(\d+x\) likely typo of '(?P<good>[^']+)'"
)
ID_LINE_RE = re.compile(r"^id\s*:")
UPDATED_LINE_RE = re.compile(r"^updated\s*:\s*(.*?)\s*$")
SOURCES_LINE_RE = re.compile(r"^sources\s*:(.*)$")


STALE_DRAFT_DAYS = 180
STALE_PAGE_DAYS = 365
TAG_TYPO_MAX_DIST = 2
TAG_TYPO_RATIO = 3
TYPES_REQUIRING_SOURCES = {"concept", "entity", "summary", "learning", "synthesis"}

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
WIKILINK_RE = re.compile(r"\[\[([a-z0-9][a-z0-9\-]*)\]\]")


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def parse_frontmatter(text: str) -> dict:
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    current_key = None
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and current_key:
            out.setdefault(current_key, []).append(line[4:].strip())
            continue
        if ":" in line:
            k, _, v = line.partition(":")
            k = k.strip()
            v = v.strip()
            current_key = k
            if v.startswith("[") and v.endswith("]"):
                inside = v[1:-1].strip()
                if not inside:
                    out[k] = []
                else:
                    out[k] = [x.strip() for x in inside.split(",") if x.strip()]
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def parse_date(s: str):
    try:
        return dt.datetime.strptime(s.strip(), "%Y-%m-%d").date()
    except (ValueError, AttributeError):
        return None


def edit_distance(a: str, b: str) -> int:
    if a == b:
        return 0
    if abs(len(a) - len(b)) > TAG_TYPO_MAX_DIST:
        return TAG_TYPO_MAX_DIST + 1
    # Small DP; cheap for tag-length strings.
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        curr = [i]
        for j, cb in enumerate(b, 1):
            cost = 0 if ca == cb else 1
            curr.append(min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost))
        prev = curr
    return prev[-1]


def _load_last_resweep(wiki_root: Path) -> dict | None:
    """Best-effort read of the wiki-claims-resweep lint-bridge JSON.

    Returns None when the file is absent or malformed — a wiki that was never
    swept produces no claim_drift findings, exactly like before this hook
    existed.
    """
    p = wiki_root / ".cogni-wiki" / "last-resweep.json"
    if not p.is_file():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Mechanical lint pass for a cogni-wiki")
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument(
        "--fix",
        action="append",
        default=[],
        choices=FIX_CHOICES,
        help=(
            "Apply the deterministic auto-fix for one or more lint classes. "
            "Repeatable; --fix=all enables every safe class. v0.0.32+ (#222)."
        ),
    )
    parser.add_argument(
        "--suggest",
        action="store_true",
        help=(
            "Emit data.suggestions[] — structured proposals for prose-shaped "
            "findings (orphan_page, stale_*, claim_drift, tag_typo). v0.0.32+."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "Pair with --fix: compute the plan but do not write. Every "
            "data.fixed[] entry has applied=false."
        ),
    )
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    fix_classes = _expand_fix_classes(args.fix)
    if args.dry_run and not (fix_classes or args.suggest):
        # --dry-run alone is harmless but a no-op; document the noop in stats.
        pass

    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki (no .cogni-wiki/config.json under {wiki_root})")
    fail_if_pre_migration(wiki_root)

    # `errors` is retained as an empty list in the JSON output for backwards
    # compatibility with consumers (`wiki-refresh`, `rebuild_open_questions.py`,
    # the lint-report composer) that key on `data.errors`. As of v0.0.31 lint
    # itself never appends to it — structural errors are owned by `health.py`.
    errors: list = []
    warnings: list = []
    info: list = []

    slug_index = build_slug_index(wiki_root, include_audit=True)
    all_pages: dict = {}
    tag_counts: dict = {}
    type_counts: dict = {}
    inbound_links: dict = {}
    sources_per_page: list = []
    # Foundation pages (`foundation: true` in frontmatter, seeded by
    # `wiki-prefill`) are terminal — orphan / no-sources / staleness
    # warnings do not apply to canonical textbook concepts. Track the slugs
    # so the orphan pass can skip them too. Issue #224.
    foundation_slugs: set = set()
    today = dt.date.today()

    for slug, page_path, ptype_dir in iter_pages(wiki_root, include_audit=True):
        try:
            text = page_path.read_text(encoding="utf-8")
        except OSError:
            # health.py owns read-error reporting (`read_error` class).
            # Skip silently here so a single unreadable page doesn't suppress
            # lint findings on the other pages.
            continue
        fm = parse_frontmatter(text)
        all_pages[slug] = {"fm": fm, "text": text, "type_dir": ptype_dir}

        # Audit reports get scanned for outbound wikilinks (so reverse-link
        # checks can ignore them on both ends per R3) but skip every other
        # sources / staleness check.
        if ptype_dir == "audit" or is_audit_slug(slug):
            for target in WIKILINK_RE.findall(text):
                inbound_links.setdefault(target, set()).add(slug)
            continue

        ptype = fm.get("type")
        if ptype:
            type_counts[ptype] = type_counts.get(ptype, 0) + 1

        # `foundation: true` pages (seeded by wiki-prefill) are terminal —
        # they don't trigger orphan / no-sources / staleness warnings because
        # they are canonical textbook concepts, not per-wiki synthesis.
        is_foundation = str(fm.get("foundation", "")).strip().lower() == "true"
        if is_foundation:
            foundation_slugs.add(slug)

        # sources required for some types
        sources = fm.get("sources", [])
        if isinstance(sources, list):
            sources_per_page.append(len(sources))
            if (
                ptype in TYPES_REQUIRING_SOURCES
                and len(sources) == 0
                and not is_foundation
            ):
                warnings.append(
                    {
                        "class": "no_sources",
                        "page": slug,
                        "message": f"type '{ptype}' but no sources field",
                    }
                )
            # Synthesis pages must cite at least one wiki:// source. Empty
            # sources is already covered by the no_sources warning above; this
            # catches the case where sources are present but only ../raw/ or URL
            # entries — a synthesis without wiki provenance is suspicious.
            # Per-source target validation (missing raw file, broken wiki://
            # target) is owned by health.py as of v0.0.31.
            has_wiki_source = any(
                isinstance(src, str) and src.startswith("wiki://")
                for src in sources
            )
            if (
                ptype == "synthesis"
                and len(sources) > 0
                and not has_wiki_source
            ):
                warnings.append(
                    {
                        "class": "synthesis_no_wiki_source",
                        "page": slug,
                        "message": "type 'synthesis' but no wiki:// source — synthesis pages must cite the wiki pages they derive from",
                    }
                )

        # tag counts
        tags = fm.get("tags", [])
        if isinstance(tags, list):
            for t in tags:
                if isinstance(t, str):
                    tag_counts[t] = tag_counts.get(t, 0) + 1

        # stale checks (foundations are terminal — staleness does not apply)
        updated = parse_date(fm.get("updated", ""))
        status = fm.get("status", "").strip().lower() if isinstance(fm.get("status"), str) else ""
        if updated and not is_foundation:
            age = (today - updated).days
            if status == "draft" and age > STALE_DRAFT_DAYS:
                warnings.append(
                    {
                        "class": "stale_draft",
                        "page": slug,
                        "message": f"draft updated {age} days ago",
                    }
                )
            elif age > STALE_PAGE_DAYS:
                warnings.append(
                    {
                        "class": "stale_page",
                        "page": slug,
                        "message": f"page updated {age} days ago",
                    }
                )

        # wikilinks
        for target in WIKILINK_RE.findall(text):
            inbound_links.setdefault(target, set()).add(slug)

    # orphans pass 2 — broken_wikilink reporting moved to health.py in v0.0.31.
    existing_slugs = set(all_pages.keys())

    for slug in existing_slugs:
        if is_audit_slug(slug):
            continue
        if slug in foundation_slugs:
            # Foundations are terminal: they ship without inbound links and
            # gain them only as downstream pages cite them. An orphan
            # foundation is the expected day-1 state, not a defect. #224.
            continue
        if slug not in inbound_links or not inbound_links[slug]:
            warnings.append(
                {"class": "orphan_page", "page": slug, "message": "no inbound wikilinks"}
            )

    # reverse_link_missing — SCHEMA.md rule R1_bidirectional_wikilink.
    # For every forward edge A → B (A's body contains `[[B]]`), the reverse
    # edge B → A should also exist. Audit reports (`lint-*` / `health-*`)
    # are exempt on both ends per rule R3.
    #
    # `inbound_links[t]` is the set of source slugs S such that S contains
    # `[[t]]`. To test "does A reverse-link B?" we ask "is A in
    # inbound_links[B]?". If A links to B but A is *not* in inbound_links[B]'s
    # reverse direction (i.e., B does not link back to A), that's a violation.
    # Targets that don't exist are quietly skipped — health.py owns
    # `broken_wikilink` reporting as of v0.0.31.
    for target_slug, source_slugs in sorted(inbound_links.items()):
        if target_slug not in existing_slugs:
            continue
        if is_audit_slug(target_slug):
            continue
        for source_slug in sorted(source_slugs):
            if source_slug == target_slug:
                continue  # self-link is its own reverse
            if is_audit_slug(source_slug):
                continue
            # Does source_slug appear in target's outbound? Equivalent to:
            # is source_slug a target of inbound_links keyed at source_slug
            # whose source is target_slug?
            target_outbound_to_source = source_slug in inbound_links and (
                target_slug in inbound_links[source_slug]
            )
            if not target_outbound_to_source:
                warnings.append(
                    {
                        "class": "reverse_link_missing",
                        "page": target_slug,
                        "message": (
                            f"[[{source_slug}]] links here but this page does "
                            f"not link back to [[{source_slug}]] "
                            f"(SCHEMA.md R1_bidirectional_wikilink)"
                        ),
                    }
                )

    # tag typos
    tag_items = sorted(tag_counts.items(), key=lambda kv: -kv[1])
    for i, (tag_a, count_a) in enumerate(tag_items):
        for tag_b, count_b in tag_items[i + 1 :]:
            if count_a == 0 or count_b == 0:
                continue
            dist = edit_distance(tag_a, tag_b)
            if dist == 0 or dist > TAG_TYPO_MAX_DIST:
                continue
            ratio = count_a / count_b if count_b else float("inf")
            if ratio >= TAG_TYPO_RATIO:
                warnings.append(
                    {
                        "class": "tag_typo",
                        "page": "*",
                        "message": f"'{tag_b}' ({count_b}x) likely typo of '{tag_a}' ({count_a}x)",
                    }
                )

    # claim_drift bridge — read the last wiki-claims-resweep summary if present.
    # Pages flagged there get a warning each. Sweep itself gets one info line.
    resweep = _load_last_resweep(wiki_root)
    if resweep:
        sweep_date = str(resweep.get("sweep_date", "")).strip()
        mode = str(resweep.get("mode", "")).strip() or "?"
        report_path = str(resweep.get("report_path", "")).strip()
        deviated = resweep.get("deviated_pages") or []
        unavailable = resweep.get("unavailable_pages") or []
        sweep_dt = parse_date(sweep_date) if sweep_date else None
        age_str = (
            f"({(today - sweep_dt).days}d ago)" if sweep_dt else "(date unknown)"
        )
        info.append(
            {
                "class": "last_resweep",
                "message": f"{sweep_date or 'unknown'} {age_str} — mode: {mode}",
            }
        )
        suffix = f"; see {report_path}" if report_path else ""
        for slug in deviated:
            if slug not in existing_slugs:
                continue
            warnings.append(
                {
                    "class": "claim_drift",
                    "page": slug,
                    "message": f"deviated claim(s) from sweep {sweep_date or 'unknown'}{suffix}",
                }
            )
        for slug in unavailable:
            if slug not in existing_slugs:
                continue
            warnings.append(
                {
                    "class": "claim_drift",
                    "page": slug,
                    "message": f"source_unavailable claim(s) from sweep {sweep_date or 'unknown'}{suffix}",
                }
            )

    # info stats
    knowledge_pages = [s for s, info_d in all_pages.items() if not is_audit_slug(s) and info_d.get("type_dir") != "audit"]
    avg_sources = (
        round(sum(sources_per_page) / len(sources_per_page), 2) if sources_per_page else 0
    )
    most_linked = sorted(
        ((slug, len(bag)) for slug, bag in inbound_links.items() if slug in existing_slugs),
        key=lambda kv: (-kv[1], kv[0]),
    )[:10]
    info.append({"class": "total_pages", "message": f"{len(knowledge_pages)} pages (excluding audit reports)"})
    info.append({"class": "by_type", "message": json.dumps(type_counts, sort_keys=True)})
    info.append({"class": "avg_sources", "message": f"{avg_sources} sources per page"})
    info.append({"class": "top_tags", "message": json.dumps(dict(tag_items[:10]))})
    info.append({"class": "most_linked", "message": json.dumps(dict(most_linked))})

    # ----------------------------------------------------------------------
    # v0.0.32 (#222): optional --fix and --suggest phases.
    #
    # Findings produced above are the input to fixers. The fix phase serialises
    # against concurrent wiki-ingest invocations via _wiki_lock for the
    # in-process page-body fixers; the two scripted fixers acquire their own
    # locks after we release ours.
    # ----------------------------------------------------------------------
    fixed: list = []
    failed: list = []
    suggestions: list = []

    if fix_classes:
        in_proc = {
            "reverse_link_missing",
            "synthesis_no_wiki_source",
            "frontmatter_defaults",
        } & fix_classes
        if in_proc:
            with _wiki_lock(wiki_root):
                if "reverse_link_missing" in fix_classes:
                    f, fl = fix_reverse_link_missing(
                        warnings, slug_index, args.dry_run
                    )
                    fixed += f
                    failed += fl
                if "synthesis_no_wiki_source" in fix_classes:
                    f, fl = fix_synthesis_no_wiki_source(
                        warnings, all_pages, slug_index, args.dry_run
                    )
                    fixed += f
                    failed += fl
                if "frontmatter_defaults" in fix_classes:
                    f, fl = fix_frontmatter_defaults(
                        all_pages, slug_index, args.dry_run
                    )
                    fixed += f
                    failed += fl
        if "entries_count_drift" in fix_classes:
            f, fl = fix_entries_count_drift(wiki_root, args.dry_run)
            fixed += f
            failed += fl
        if "alphabetisation" in fix_classes:
            f, fl = fix_alphabetisation(wiki_root, args.dry_run)
            fixed += f
            failed += fl

    if args.suggest:
        suggestions = build_suggestions(warnings, all_pages)

    out = {
        "errors": errors,
        "warnings": warnings,
        "info": info,
        "stats": {
            "pages_audited": len(knowledge_pages),
            "errors": len(errors),
            "warnings": len(warnings),
            "info": len(info),
            "type_counts": type_counts,
            "foundation_count": len(foundation_slugs),
            "avg_sources_per_page": avg_sources,
            "fixes_applied": sum(1 for x in fixed if x.get("applied")),
            "fixes_planned": sum(1 for x in fixed if not x.get("applied")),
            "fixes_failed": len(failed),
            "suggestions_emitted": len(suggestions),
        },
        "fixed": fixed,
        "failed": failed,
        "suggestions": suggestions,
    }
    ok(out)


# ===========================================================================
# v0.0.32 (#222) — fixers and suggestion builders.
#
# Each fixer returns (fixed_entries, failed_entries) lists of dicts. The
# `applied` flag distinguishes wet runs from --dry-run plans; lint's stats
# block surfaces both counts so consumers can tell the difference without
# parsing the entries.
# ===========================================================================


def _expand_fix_classes(raw: list) -> set:
    """Resolve the repeatable --fix list (incl. `all`) into a set."""
    out: set = set()
    for v in raw or []:
        if v == "all":
            out.update(FIX_CLASSES)
        else:
            out.add(v)
    return out


def _split_frontmatter(text: str) -> tuple:
    """Return (frontmatter_lines: list, body: str) or (None, original_text)."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return None, text
    return m.group(1).splitlines(), text[m.end():]


def _join_frontmatter(fm_lines: list, body: str) -> str:
    return "---\n" + "\n".join(fm_lines) + "\n---\n" + body


def _try_normalize_date(raw: str) -> str:
    """Best-effort ISO-8601 normalisation. Returns ISO string or empty."""
    if not raw:
        return ""
    if parse_date(raw) is not None:
        return raw  # already YYYY-MM-DD
    for fmt in DATE_NORMALIZE_FORMATS:
        try:
            return dt.datetime.strptime(raw, fmt).date().isoformat()
        except ValueError:
            continue
    return ""


def _add_to_sources(fm_lines: list, new_entries: list) -> list:
    """Append entries to the `sources:` field. Handles three shapes:

      A. block list — `sources:` followed by `  - …` lines.
      B. inline list — `sources: [a, b]`.
      C. single scalar — `sources: foo`. Converted to block + appended.

    Returns the new fm_lines list, or None if the field is absent (the
    caller should treat that as a fail-soft case rather than silently
    inventing a brand-new field).
    """
    src_idx = -1
    for i, line in enumerate(fm_lines):
        if SOURCES_LINE_RE.match(line):
            src_idx = i
            break
    if src_idx == -1:
        return None
    rest = SOURCES_LINE_RE.match(fm_lines[src_idx]).group(1).strip()

    if rest.startswith("[") and rest.endswith("]"):
        inside = rest[1:-1].strip()
        items = [x.strip() for x in inside.split(",") if x.strip()] if inside else []
        items.extend(new_entries)
        new_line = "sources: [" + ", ".join(items) + "]"
        return fm_lines[:src_idx] + [new_line] + fm_lines[src_idx + 1:]

    if not rest:
        # Block list (possibly empty). Walk forward to find the last
        # `  - ...` line directly under sources:; insert after it.
        last_block = src_idx
        for j in range(src_idx + 1, len(fm_lines)):
            if fm_lines[j].startswith("  -"):
                last_block = j
                continue
            if fm_lines[j].strip() == "":
                continue
            break
        added = ["  - " + e for e in new_entries]
        return fm_lines[:last_block + 1] + added + fm_lines[last_block + 1:]

    # Single-scalar form — promote to block list with the existing scalar
    # preserved as the first item.
    converted = ["sources:", "  - " + rest]
    converted.extend("  - " + e for e in new_entries)
    return fm_lines[:src_idx] + converted + fm_lines[src_idx + 1:]


def _append_see_also(text: str, slugs: list) -> str:
    """Append `[[slug]]` entries under `## See also`. Reuses an existing
    section when present; otherwise appends a fresh one at end-of-file.
    The fixer only calls this with slugs not already linked from `text`,
    so duplication checks live in the caller.
    """
    new_items = "\n".join(f"- [[{s}]]" for s in slugs)
    pat = re.compile(r"^##\s+See also\s*$", re.MULTILINE | re.IGNORECASE)
    m = pat.search(text)
    if m:
        section_start = m.end()
        next_heading = re.search(r"^##\s", text[section_start:], re.MULTILINE)
        section_end = (
            section_start + next_heading.start() if next_heading else len(text)
        )
        body = text[section_start:section_end].rstrip("\n") + "\n"
        new_section = body + new_items + "\n"
        if section_end < len(text):
            new_section += "\n"
        return text[:section_start] + new_section + text[section_end:]
    sep = "" if text.endswith("\n") else "\n"
    return text + sep + "\n## See also\n\n" + new_items + "\n"


def fix_reverse_link_missing(
    warnings: list, slug_index: dict, dry_run: bool
) -> tuple:
    """Backfill missing reverse `[[link]]`s per SCHEMA R1.

    Groups by target page so a target with multiple missing reverse links
    gets one batched edit. Idempotent: a re-run with the same warnings is
    a no-op because the second pass sees the link already present.
    """
    fixed: list = []
    failed: list = []
    by_target: dict = {}
    for w in warnings:
        if w.get("class") != "reverse_link_missing":
            continue
        target = w.get("page")
        msg = w.get("message", "")
        m = REVERSE_LINK_SOURCE_RE.search(msg)
        if not target or not m:
            failed.append({
                "class": "reverse_link_missing",
                "page": target or "(unknown)",
                "error": "could not parse source slug from warning message",
            })
            continue
        by_target.setdefault(target, set()).add(m.group(1))

    for target in sorted(by_target):
        sources = by_target[target]
        try:
            entry = slug_index.get(target)
            if not entry:
                failed.append({
                    "class": "reverse_link_missing",
                    "page": target,
                    "error": "target page not found in slug index",
                })
                continue
            path, _ptype = entry
            text = path.read_text(encoding="utf-8")
            existing = set(WIKILINK_RE.findall(text))
            to_add = sorted(s for s in sources if s not in existing)
            if not to_add:
                continue  # already in sync — idempotent no-op
            new_text = _append_see_also(text, to_add)
            if not dry_run:
                atomic_write(path, new_text)
            fixed.append({
                "class": "reverse_link_missing",
                "page": target,
                "applied": not dry_run,
                "change": f"+{len(to_add)} reverse link(s): "
                          + ", ".join(f"[[{s}]]" for s in to_add),
            })
        except Exception as e:  # noqa: BLE001 — fail-soft per item
            failed.append({
                "class": "reverse_link_missing",
                "page": target,
                "error": f"{type(e).__name__}: {e}",
            })
    return fixed, failed


def fix_synthesis_no_wiki_source(
    warnings: list, all_pages: dict, slug_index: dict, dry_run: bool
) -> tuple:
    """Backfill `wiki://<slug>` source entries for synthesis pages.

    Strategy: scan the body for `[[slug]]` mentions whose target exists in
    the wiki, then add `wiki://<slug>` to the page's `sources:` block.
    Pages whose existing sources already cover every body slug are skipped
    silently.
    """
    fixed: list = []
    failed: list = []
    for w in warnings:
        if w.get("class") != "synthesis_no_wiki_source":
            continue
        slug = w.get("page")
        try:
            page_data = all_pages.get(slug)
            if not page_data:
                failed.append({
                    "class": "synthesis_no_wiki_source",
                    "page": slug,
                    "error": "page not in lint state",
                })
                continue
            text = page_data["text"]
            fm_dict = page_data["fm"]
            body_slugs = sorted({
                s for s in WIKILINK_RE.findall(text)
                if s in slug_index and not is_audit_slug(s) and s != slug
            })
            if not body_slugs:
                failed.append({
                    "class": "synthesis_no_wiki_source",
                    "page": slug,
                    "error": "no in-wiki [[slug]] found in body to source from",
                })
                continue
            existing_sources = fm_dict.get("sources", []) or []
            if not isinstance(existing_sources, list):
                existing_sources = [existing_sources]
            already = {
                src[len("wiki://"):]
                for src in existing_sources
                if isinstance(src, str) and src.startswith("wiki://")
            }
            to_add = [s for s in body_slugs if s not in already]
            if not to_add:
                continue
            new_entries = ["wiki://" + s for s in to_add]
            fm_lines, body = _split_frontmatter(text)
            if fm_lines is None:
                failed.append({
                    "class": "synthesis_no_wiki_source",
                    "page": slug,
                    "error": "no frontmatter",
                })
                continue
            new_fm = _add_to_sources(fm_lines, new_entries)
            if new_fm is None:
                failed.append({
                    "class": "synthesis_no_wiki_source",
                    "page": slug,
                    "error": "no `sources:` field to extend",
                })
                continue
            new_text = _join_frontmatter(new_fm, body)
            entry = slug_index.get(slug)
            if not entry:
                failed.append({
                    "class": "synthesis_no_wiki_source",
                    "page": slug,
                    "error": "slug not in index",
                })
                continue
            path, _ = entry
            if not dry_run:
                atomic_write(path, new_text)
            fixed.append({
                "class": "synthesis_no_wiki_source",
                "page": slug,
                "applied": not dry_run,
                "change": f"+{len(to_add)} wiki:// source(s): "
                          + ", ".join(new_entries),
            })
        except Exception as e:  # noqa: BLE001 — fail-soft per item
            failed.append({
                "class": "synthesis_no_wiki_source",
                "page": slug,
                "error": f"{type(e).__name__}: {e}",
            })
    return fixed, failed


def fix_frontmatter_defaults(
    all_pages: dict, slug_index: dict, dry_run: bool
) -> tuple:
    """Backfill missing `id:` (= filename stem) and normalise non-ISO
    `updated:` dates. Pages without frontmatter at all are left to
    `health.py`'s `missing_frontmatter` error.
    """
    fixed: list = []
    failed: list = []
    for slug in sorted(all_pages):
        page_data = all_pages[slug]
        if page_data.get("type_dir") == "audit":
            continue
        try:
            text = page_data["text"]
            fm_lines, body = _split_frontmatter(text)
            if fm_lines is None:
                continue
            new_fm = list(fm_lines)
            changes: list = []

            if not any(ID_LINE_RE.match(L) for L in new_fm):
                new_fm = ["id: " + slug] + new_fm
                changes.append("+id")

            for i, L in enumerate(new_fm):
                m = UPDATED_LINE_RE.match(L)
                if not m:
                    continue
                raw = m.group(1).strip()
                if not raw:
                    break
                if parse_date(raw) is not None:
                    break
                iso = _try_normalize_date(raw)
                if iso:
                    new_fm[i] = f"updated: {iso}"
                    changes.append(f"updated: {raw} → {iso}")
                break

            if not changes:
                continue
            new_text = _join_frontmatter(new_fm, body)
            entry = slug_index.get(slug)
            if not entry:
                failed.append({
                    "class": "frontmatter_defaults",
                    "page": slug,
                    "error": "slug not in index",
                })
                continue
            path, _ = entry
            if not dry_run:
                atomic_write(path, new_text)
            fixed.append({
                "class": "frontmatter_defaults",
                "page": slug,
                "applied": not dry_run,
                "change": "; ".join(changes),
            })
        except Exception as e:  # noqa: BLE001 — fail-soft per item
            failed.append({
                "class": "frontmatter_defaults",
                "page": slug,
                "error": f"{type(e).__name__}: {e}",
            })
    return fixed, failed


def fix_entries_count_drift(wiki_root: Path, dry_run: bool) -> tuple:
    """Reconcile `.cogni-wiki/config.json::entries_count` to the
    filesystem-counted truth (non-audit pages). Routes the write through
    `config_bump.py --set-int` so the locked-script convention holds.
    """
    fixed: list = []
    failed: list = []
    try:
        count = sum(1 for _ in iter_pages(wiki_root, include_audit=False))
        config_path = wiki_root / ".cogni-wiki" / "config.json"
        cfg = json.loads(config_path.read_text(encoding="utf-8"))
        current = cfg.get("entries_count")
        if current == count:
            return fixed, failed
        change = f"entries_count: {current} → {count}"
        if dry_run:
            fixed.append({
                "class": "entries_count_drift",
                "page": "(.cogni-wiki/config.json)",
                "applied": False,
                "change": change,
            })
            return fixed, failed
        result = subprocess.run(
            [
                sys.executable,
                str(CONFIG_BUMP_SCRIPT),
                "--wiki-root",
                str(wiki_root),
                "--key",
                "entries_count",
                "--set-int",
                str(count),
            ],
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            failed.append({
                "class": "entries_count_drift",
                "page": "(.cogni-wiki/config.json)",
                "error": (result.stderr or result.stdout or "").strip()
                          or f"config_bump exit {result.returncode}",
            })
            return fixed, failed
        fixed.append({
            "class": "entries_count_drift",
            "page": "(.cogni-wiki/config.json)",
            "applied": True,
            "change": change,
        })
    except Exception as e:  # noqa: BLE001 — fail-soft on the whole fixer
        failed.append({
            "class": "entries_count_drift",
            "page": "(.cogni-wiki/config.json)",
            "error": f"{type(e).__name__}: {e}",
        })
    return fixed, failed


def fix_alphabetisation(wiki_root: Path, dry_run: bool) -> tuple:
    """Re-sort `wiki/index.md` bullet ordering within each category by
    delegating to `wiki_index_update.py --reflow-only`. The reflow is a
    pure function in that module; the subprocess hop preserves the
    "every shared write goes through its locked script" contract.
    """
    fixed: list = []
    failed: list = []
    try:
        cmd = [
            sys.executable,
            str(WIKI_INDEX_UPDATE_SCRIPT),
            "--wiki-root",
            str(wiki_root),
            "--reflow-only",
        ]
        if dry_run:
            cmd.append("--dry-run")
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        if result.returncode != 0:
            failed.append({
                "class": "alphabetisation",
                "page": "(wiki/index.md)",
                "error": (result.stderr or result.stdout or "").strip()
                          or f"wiki_index_update exit {result.returncode}",
            })
            return fixed, failed
        try:
            payload = json.loads(result.stdout)
        except json.JSONDecodeError:
            failed.append({
                "class": "alphabetisation",
                "page": "(wiki/index.md)",
                "error": "non-JSON output from wiki_index_update.py",
            })
            return fixed, failed
        if not payload.get("success"):
            failed.append({
                "class": "alphabetisation",
                "page": "(wiki/index.md)",
                "error": payload.get("error") or "unknown error",
            })
            return fixed, failed
        data = payload.get("data") or {}
        if data.get("changed"):
            fixed.append({
                "class": "alphabetisation",
                "page": "(wiki/index.md)",
                "applied": bool(data.get("applied")),
                "change": "reflowed bullet ordering within categor"
                          + ("ies" if data.get("changed") else "y"),
            })
    except Exception as e:  # noqa: BLE001 — fail-soft on the whole fixer
        failed.append({
            "class": "alphabetisation",
            "page": "(wiki/index.md)",
            "error": f"{type(e).__name__}: {e}",
        })
    return fixed, failed


# ---------------------------------------------------------------------------
# Suggestion mode (--suggest). v0.0.32+ ships the schema; no consumer wires
# it yet. SKILL.md documents the per-class proposed_action vocabulary.
# ---------------------------------------------------------------------------


def build_suggestions(warnings: list, all_pages: dict) -> list:
    """Map prose-shaped warnings to structured proposals.

    Coverage:
      orphan_page    → link_from (top tag-overlap candidates) | tag_for_audit
      stale_*        → review_or_retire
      claim_drift    → invoke_wiki_update --reason refinement --slug <page>
      tag_typo       → rename_tag (parses canonical form from message)
    """
    tag_to_slugs: dict = {}
    for slug, data in all_pages.items():
        for t in data["fm"].get("tags") or []:
            if isinstance(t, str):
                tag_to_slugs.setdefault(t, set()).add(slug)

    out: list = []
    for w in warnings:
        cls = w.get("class")
        page = w.get("page")
        msg = w.get("message", "")
        if cls == "orphan_page":
            page_data = all_pages.get(page) or {}
            page_tags = set(page_data.get("fm", {}).get("tags") or [])
            overlap: dict = {}
            for t in page_tags:
                for other in tag_to_slugs.get(t, set()):
                    if other == page or is_audit_slug(other):
                        continue
                    overlap[other] = overlap.get(other, 0) + 1
            if overlap:
                top = sorted(overlap.items(), key=lambda kv: (-kv[1], kv[0]))[:3]
                out.append({
                    "class": cls,
                    "page": page,
                    "proposed_action": "link_from",
                    "candidates": [c for c, _ in top],
                    "justification": (
                        f"shares tag(s) with {len(overlap)} candidate(s); "
                        f"top overlap: {top[0][1]} tag(s) with [[{top[0][0]}]]"
                    ),
                })
            else:
                out.append({
                    "class": cls,
                    "page": page,
                    "proposed_action": "tag_for_audit",
                    "candidates": [],
                    "justification": "no tag-overlap candidates; flag for human review",
                })
        elif cls in ("stale_draft", "stale_page"):
            out.append({
                "class": cls,
                "page": page,
                "proposed_action": "review_or_retire",
                "justification": msg,
            })
        elif cls == "claim_drift":
            out.append({
                "class": cls,
                "page": page,
                "proposed_action": "invoke_wiki_update",
                "wiki_update_args": {"reason": "refinement", "slug": page},
                "justification": msg,
            })
        elif cls == "tag_typo":
            m = TAG_TYPO_MSG_RE.match(msg)
            if m:
                out.append({
                    "class": cls,
                    "page": page,
                    "proposed_action": "rename_tag",
                    "from_tag": m.group("bad"),
                    "to_tag": m.group("good"),
                    "justification": msg,
                })
    return out


if __name__ == "__main__":
    main()
