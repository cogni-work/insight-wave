#!/usr/bin/env python3
"""
synthesis-impact.py — flag existing syntheses a newly-ingested source may outdate.

When `knowledge-ingest-source` deposits ONE new source into a bound wiki, the
source/concept graph gains an edge but the *deliverables* built on it — the
research syntheses at `wiki/syntheses/<slug>.md` — get no signal. The dependency
edge is one-directional today: a synthesis records the slugs it cited in its
block-style `sources:` frontmatter, but nothing tells a synthesis "a newer source
related to your evidence just landed". This script computes that forward signal.

  scan   Given the bound wiki + a newly-ingested source slug (+ its neighborhood
         of related pages), find every existing synthesis whose cited slugs
         intersect that neighborhood AND whose `updated:` predates the new
         source's wiki-arrival `created:` date. Each match is a *refresh
         candidate* the caller persists into `binding.json::refresh_candidates[]`
         (via `knowledge-binding.py add-refresh-candidates`) for the next
         `knowledge-refresh` run to surface.

Candidate rule: synthesis S is a refresh candidate when
  (S's cited slugs ∩ new-source neighborhood) != ∅
  AND new_source.created > S.updated   (newer EVIDENCE in the wiki — `created` is
                                        the wiki-arrival date, not publication).

The neighborhood is the `knowledge-ingest-source` Step-3 dedup `wiki-grounding.py
rank` result, passed verbatim as `--related` (the cheap reuse path; it was
captured BEFORE the new page was written, so it never contains the new source
itself). Absent `--related`, the script self-computes the neighborhood via the
same shared `wiki-grounding` primitive (testability / non-skill callers),
excluding the new page's own slug.

Pure observability, fail-soft: a single unreadable synthesis is skipped, never
aborting the scan; a synthesis with an unparseable/missing `updated:` is skipped
(keep-on-doubt — don't flag). It never writes the wiki or the binding.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import importlib.util
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

# wiki-grounding.py is hyphenated (not an importable module name), so load it by
# path — the same pattern wiki-source-manifest.py / wiki-coverage.py use to
# resolve the shared discovery primitive.
_GROUNDING_PATH = HERE / "wiki-grounding.py"
_spec = importlib.util.spec_from_file_location("wiki_grounding", _GROUNDING_PATH)
wg = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(wg)  # type: ignore[union-attr]

from _knowledge_lib import (  # noqa: E402
    frontmatter_scalar,
    parse_pre_extracted_claims,
    parse_synthesis_sources,
)

# Confidence ranking. A candidate is `high` when at least one overlapping page is
# a SOURCE (source-mediated overlap — the strongest signal that the synthesis's
# evidence base just gained a sibling), else `medium` (only concept/entity-mediated
# overlap — the new source enriches a concept the synthesis leaned on). `--min-confidence`
# filters out candidates below the threshold.
_CONF_RANK = {"high": 2, "medium": 1, "low": 0}
# Wiki subdir → page type, for classifying an overlapping slug's mediation kind.
_TYPE_DIRS = {
    "sources": "source",
    "concepts": "concept",
    "entities": "entity",
    "syntheses": "synthesis",
    "interviews": "interview",
}


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def _resolve_new_page(wiki_dir: Path, slug: str) -> Path | None:
    """Locate the newly-ingested page by slug. Sources are the motivating case,
    but tolerate an interview note too — probe `wiki/sources/` first, then fall
    back to the first `wiki/*/<slug>.md` match."""
    direct = wiki_dir / "sources" / f"{slug}.md"
    if direct.is_file():
        return direct
    for match in sorted(wiki_dir.glob(f"*/{slug}.md")):
        if match.is_file():
            return match
    return None


def _slug_page_type(wiki_dir: Path, slug: str) -> str:
    """Classify a slug by the subdir its page lives in (source/concept/entity/…),
    or "" when no page resolves. Used to rank source-mediated overlaps above
    concept/entity-mediated ones."""
    for subdir, ptype in _TYPE_DIRS.items():
        if (wiki_dir / subdir / f"{slug}.md").is_file():
            return ptype
    return ""


def _parse_iso(value: str):
    # Callers always pass a str (frontmatter_scalar returns "" on a miss), so a
    # bad/empty value raises only ValueError.
    try:
        return _dt.date.fromisoformat(value.strip())
    except ValueError:
        return None


def _compute_neighborhood(wiki_root: Path, new_page_path: Path,
                          new_slug: str, top_k: int) -> list[str]:
    """Self-compute the new source's neighborhood via the shared wiki-grounding
    primitive: rank the wiki's pages against the new page's title + claim text,
    excluding the new page's own slug. The `--related` reuse path bypasses this."""
    page_text = _read_text(new_page_path)
    title = frontmatter_scalar(page_text, "title") or new_slug
    claim_text = " ".join(
        str(c.get("text", "")) for c in parse_pre_extracted_claims(page_text)
    )
    tokens = wg.sq_token_set({"query": f"{title} {claim_text}".strip(), "theme_label": ""})
    pages = wg.collect_pages(wiki_root)
    ranked = wg.rank_pages(pages, tokens, wg.DEFAULT_THRESHOLD, top_k)
    return [p["slug"] for p in ranked["covered_pages"] if p["slug"] != new_slug]


def cmd_scan(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root).resolve()
    wiki_dir = wiki_root / "wiki"
    new_slug = args.new_page.strip()
    if not new_slug:
        return _emit(False, error="--new-page is required and must be non-empty")

    min_conf = args.min_confidence
    if min_conf not in _CONF_RANK:
        return _emit(False, error=f"--min-confidence must be one of {sorted(_CONF_RANK)}")
    min_rank = _CONF_RANK[min_conf]

    new_page_path = _resolve_new_page(wiki_dir, new_slug)
    if new_page_path is None:
        # Fail-soft: nothing to scan against a page that isn't on disk.
        return _emit(True, data={
            "new_page": new_slug,
            "new_created": "",
            "neighborhood": [],
            "syntheses_scanned": 0,
            "refresh_candidates": [],
            "note": f"new page wiki/.../{new_slug}.md not found — nothing to scan",
        })

    new_created = frontmatter_scalar(_read_text(new_page_path), "created")
    new_created_d = _parse_iso(new_created)

    # Neighborhood: the explicit --related reuse path (captured pre-write, so it
    # excludes the new page), else self-compute (which excludes new_slug itself).
    if args.related is not None:
        neighborhood = [s.strip() for s in args.related.split(",") if s.strip()]
    else:
        neighborhood = _compute_neighborhood(wiki_root, new_page_path, new_slug, args.top_k)
    neighborhood_set = set(neighborhood)

    syntheses_dir = wiki_dir / "syntheses"
    candidates: list[dict] = []
    scanned = 0
    if syntheses_dir.is_dir() and neighborhood_set and new_created:
        for page_file in sorted(syntheses_dir.glob("*.md")):
            scanned += 1
            try:
                text = page_file.read_text(encoding="utf-8")
            except OSError:
                continue  # fail-soft: skip an unreadable synthesis
            cited = set(parse_synthesis_sources(text))
            overlap = cited & neighborhood_set
            if not overlap:
                continue
            updated = frontmatter_scalar(text, "updated")
            if not updated:
                continue  # keep-on-doubt: an unparseable date never flags
            # Strict newer-evidence gate. ISO `YYYY-MM-DD` strings compare
            # lexicographically the same as chronologically.
            if not (new_created > updated):
                continue
            via_pages = sorted(overlap)
            source_mediated = any(
                _slug_page_type(wiki_dir, s) == "source" for s in via_pages
            )
            confidence = "high" if source_mediated else "medium"
            if _CONF_RANK[confidence] < min_rank:
                continue
            updated_d = _parse_iso(updated)
            age_gap_days = (
                (new_created_d - updated_d).days
                if (new_created_d and updated_d) else None
            )
            candidates.append({
                "synthesis_slug": page_file.stem,
                "title": frontmatter_scalar(text, "title") or page_file.stem,
                "synthesis_updated": updated,
                "via_pages": via_pages,
                "age_gap_days": age_gap_days,
                "confidence": confidence,
            })

    # Rank: source-mediated (high) first, then widest evidence gap, then slug.
    candidates.sort(key=lambda c: (
        -_CONF_RANK[c["confidence"]],
        -(c["age_gap_days"] or 0),
        c["synthesis_slug"],
    ))

    return _emit(True, data={
        "new_page": new_slug,
        "new_created": new_created,
        "neighborhood": neighborhood,
        "syntheses_scanned": scanned,
        "refresh_candidates": candidates,
    })


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Flag existing syntheses a newly-ingested source may outdate.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_scan = sub.add_parser(
        "scan",
        help="Find syntheses whose cited slugs intersect a new source's "
             "neighborhood and predate its wiki-arrival date.",
    )
    p_scan.add_argument("--wiki-root", required=True,
                        help="Absolute path to the bound wiki root (the dir containing wiki/).")
    p_scan.add_argument("--new-page", required=True,
                        help="Slug of the newly-ingested source page.")
    p_scan.add_argument("--related", default=None,
                        help="Comma-separated neighborhood slugs (the Step-3 dedup "
                             "wiki-grounding rank result). Omit to self-compute via wiki-grounding.")
    p_scan.add_argument("--min-confidence", default="medium", choices=sorted(_CONF_RANK),
                        help="Drop candidates below this confidence (high = source-mediated "
                             "only; default medium = keep source- and concept/entity-mediated).")
    p_scan.add_argument("--top-k", type=int, default=wg.TOP_K,
                        help=f"Self-compute neighborhood cap (default {wg.TOP_K}); "
                             "ignored when --related is supplied.")
    p_scan.set_defaults(func=cmd_scan)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
