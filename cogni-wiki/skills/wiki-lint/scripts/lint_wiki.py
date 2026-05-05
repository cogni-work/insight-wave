#!/usr/bin/env python3
"""
lint_wiki.py — mechanical health audit for a Karpathy-style wiki.

Emits JSON on stdout with three severity tiers:
    {"success": true,
     "data": {
       "errors":   [{"class": "...", "page": "...", "message": "..."}, ...],
       "warnings": [...],
       "info":     [...],
       "stats":    { ... }
     },
     "error": ""}

Detects:
    - Broken [[wikilinks]]
    - Filename / id mismatches
    - Missing required frontmatter fields
    - Invalid type values
    - Missing source files under raw/
    - Broken wiki:// sources (target page does not exist)
    - Synthesis pages missing wiki:// sources
    - Orphan pages (no inbound wikilinks)
    - Stale drafts / stale pages
    - Tag typos (edit distance ≤ TAG_TYPO_MAX_DIST with ≥ TAG_TYPO_RATIO usage ratio)
    - Pages missing sources when type requires them

Semantic checks (contradictions, type drift) are NOT handled here — they
are performed by the calling Claude skill with this script's output as a
starting point.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path


STALE_DRAFT_DAYS = 180
STALE_PAGE_DAYS = 365
TAG_TYPO_MAX_DIST = 2
TAG_TYPO_RATIO = 3
VALID_TYPES = {"concept", "entity", "summary", "decision", "learning", "synthesis", "note"}
TYPES_REQUIRING_SOURCES = {"concept", "entity", "summary", "learning", "synthesis"}
REQUIRED_FRONTMATTER = {"id", "title", "type", "created", "updated"}

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
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    pages_dir = wiki_root / "wiki" / "pages"
    raw_dir = wiki_root / "raw"

    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki (no .cogni-wiki/config.json under {wiki_root})")
    if not pages_dir.is_dir():
        fail(f"wiki/pages/ not found under {wiki_root}")

    errors: list = []
    warnings: list = []
    info: list = []

    all_pages: dict = {}
    tag_counts: dict = {}
    type_counts: dict = {}
    inbound_links: dict = {}
    sources_per_page: list = []
    today = dt.date.today()

    for page in sorted(pages_dir.glob("*.md")):
        slug = page.stem
        try:
            text = page.read_text(encoding="utf-8")
        except OSError as e:
            errors.append({"class": "read_error", "page": slug, "message": str(e)})
            continue
        fm = parse_frontmatter(text)
        all_pages[slug] = {"fm": fm, "text": text}

        if slug.startswith("lint-"):
            continue

        # Required frontmatter
        for field in REQUIRED_FRONTMATTER:
            if field not in fm or fm[field] in (None, "", []):
                errors.append(
                    {
                        "class": "missing_frontmatter",
                        "page": slug,
                        "message": f"missing required field '{field}'",
                    }
                )

        # id matches filename
        if fm.get("id") and fm["id"] != slug:
            errors.append(
                {
                    "class": "id_mismatch",
                    "page": slug,
                    "message": f"frontmatter id '{fm['id']}' != filename '{slug}'",
                }
            )

        # valid type
        ptype = fm.get("type")
        if ptype and ptype not in VALID_TYPES:
            errors.append(
                {
                    "class": "invalid_type",
                    "page": slug,
                    "message": f"type '{ptype}' not in {sorted(VALID_TYPES)}",
                }
            )
        if ptype:
            type_counts[ptype] = type_counts.get(ptype, 0) + 1

        # sources required for some types
        sources = fm.get("sources", [])
        if isinstance(sources, list):
            sources_per_page.append(len(sources))
            if ptype in TYPES_REQUIRING_SOURCES and len(sources) == 0:
                warnings.append(
                    {
                        "class": "no_sources",
                        "page": slug,
                        "message": f"type '{ptype}' but no sources field",
                    }
                )
            # Validate per-source: missing raw files, broken wiki:// targets,
            # and remember whether any wiki:// source was seen (for synthesis).
            has_wiki_source = False
            for src in sources:
                if isinstance(src, str) and src.startswith("../raw/"):
                    rel = src[len("../raw/") :]
                    if not (raw_dir / rel).exists():
                        errors.append(
                            {
                                "class": "missing_source",
                                "page": slug,
                                "message": f"source file not found: raw/{rel}",
                            }
                        )
                elif isinstance(src, str) and src.startswith("wiki://"):
                    has_wiki_source = True
                    target = src[len("wiki://") :].strip()
                    if not target or not (pages_dir / f"{target}.md").is_file():
                        errors.append(
                            {
                                "class": "broken_wiki_source",
                                "page": slug,
                                "message": f"wiki:// source not found: wiki://{target}",
                            }
                        )

            # Synthesis pages must cite at least one wiki:// source. Empty
            # sources is already covered by the no_sources warning above; this
            # catches the case where sources are present but only ../raw/ or URL
            # entries — a synthesis without wiki provenance is suspicious.
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

        # stale checks
        updated = parse_date(fm.get("updated", ""))
        status = fm.get("status", "").strip().lower() if isinstance(fm.get("status"), str) else ""
        if updated:
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

    # broken links + orphans pass 2
    existing_slugs = set(all_pages.keys())
    for slug, bag in inbound_links.items():
        if slug not in existing_slugs:
            for source_slug in sorted(bag):
                errors.append(
                    {
                        "class": "broken_wikilink",
                        "page": source_slug,
                        "message": f"[[{slug}]] target does not exist",
                    }
                )

    for slug in existing_slugs:
        if slug.startswith("lint-"):
            continue
        if slug not in inbound_links or not inbound_links[slug]:
            warnings.append(
                {"class": "orphan_page", "page": slug, "message": "no inbound wikilinks"}
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
    non_lint_pages = [s for s in all_pages if not s.startswith("lint-")]
    avg_sources = (
        round(sum(sources_per_page) / len(sources_per_page), 2) if sources_per_page else 0
    )
    most_linked = sorted(
        ((slug, len(bag)) for slug, bag in inbound_links.items() if slug in existing_slugs),
        key=lambda kv: (-kv[1], kv[0]),
    )[:10]
    info.append({"class": "total_pages", "message": f"{len(non_lint_pages)} pages (excluding lint reports)"})
    info.append({"class": "by_type", "message": json.dumps(type_counts, sort_keys=True)})
    info.append({"class": "avg_sources", "message": f"{avg_sources} sources per page"})
    info.append({"class": "top_tags", "message": json.dumps(dict(tag_items[:10]))})
    info.append({"class": "most_linked", "message": json.dumps(dict(most_linked))})

    ok(
        {
            "errors": errors,
            "warnings": warnings,
            "info": info,
            "stats": {
                "pages_audited": len(non_lint_pages),
                "errors": len(errors),
                "warnings": len(warnings),
                "info": len(info),
                "type_counts": type_counts,
                "avg_sources_per_page": avg_sources,
            },
        }
    )


if __name__ == "__main__":
    main()
