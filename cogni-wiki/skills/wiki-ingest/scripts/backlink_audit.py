#!/usr/bin/env python3
"""
backlink_audit.py — find candidate backlinks for a newly ingested wiki page.

Given a wiki root and a newly created page, scan existing pages for textual
references that could justify adding a `[[new-page]]` backlink. Returns a
ranked list of candidates as JSON on stdout so the calling skill can decide
which links to actually insert.

Usage:
    backlink_audit.py --wiki-root <path> --new-page <slug>

Output contract:
    {
      "success": true,
      "data": {
        "candidates": [...],
        "search_terms": [...],
        "total_pages_scanned": <int>
      },
      "error": ""
    }

Candidate object:
    {
      "page": "<slug>",
      "matched_terms": ["term1", "term2"],
      "matched_score": 1.73,            # IDF-weighted sum of matched terms
      "confidence": "low" | "medium" | "high",
      "existing_backlink": true | false
    }

Flags:
    --top-n <N>           After ranking, keep only the top N candidates.
    --min-confidence X    Drop candidates below confidence X (low|medium|high).

Ranking is stable: candidates are sorted by confidence bucket (high > medium >
low), then by matched_score descending, then by page slug alphabetically. Terms
derived from the page title always have weight 1.0; tag-derived terms are
weighted by inverse document frequency across wiki/pages/ so common tags like
`agent` (present on most pages) contribute near-zero signal while rare tags
like `claim-verification` dominate the score.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


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
                out[k] = [x.strip() for x in v[1:-1].split(",") if x.strip()]
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def extract_terms(page_text: str, fm: dict) -> tuple:
    """Build title-derived and tag-derived search term sets from a page.

    Returns (title_terms, tag_terms) so callers can weight them independently:
    title terms are inherently specific; tag terms need IDF weighting because
    common tags like `agent` blow up false-positive candidate counts.
    """
    title_terms: set = set()
    title = fm.get("title", "")
    if isinstance(title, str) and title:
        title_terms.add(title.strip().lower())
        for word in re.findall(r"[a-zA-Z][a-zA-Z0-9\-]{3,}", title):
            title_terms.add(word.lower())
    tag_terms: set = set()
    tags = fm.get("tags", [])
    if isinstance(tags, list):
        for t in tags:
            if isinstance(t, str):
                tag_terms.add(t.strip().lower())
    title_terms = {t for t in title_terms if len(t) >= 4}
    tag_terms = {t for t in tag_terms if len(t) >= 4}
    return title_terms, tag_terms


def compute_tag_document_frequency(pages_dir: Path) -> tuple:
    """Scan all wiki pages to count how many pages carry each tag.

    Returns (tag_df, total_pages). Callers turn this into an inverse-document-
    frequency weight: weight(tag) = 1 - (tag_df[tag] / total_pages), clamped to
    a small floor so a tag present on literally every page still contributes a
    sliver of signal (otherwise the algorithm loses its ability to fall back
    on tag matches when the title has no hits).
    """
    tag_df: dict = {}
    total = 0
    for page in pages_dir.glob("*.md"):
        if page.name.startswith("lint-"):
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        _title, tags = extract_terms(text, fm)
        if not tags:
            # Tagless pages are intentionally counted toward total_pages to
            # reflect true corpus size; this keeps the IDF denominator honest
            # so rare tags don't get artificially inflated weights.
            total += 1
            continue
        total += 1
        for tag in tags:
            tag_df[tag] = tag_df.get(tag, 0) + 1
    return tag_df, total


def tag_weight(tag: str, tag_df: dict, total_pages: int) -> float:
    """Return the IDF-style weight for a tag: rare tags score high, common low."""
    if total_pages <= 0:
        return 0.5
    df = tag_df.get(tag, 0)
    # Clamp to [0.05, 1.0] — a tag on every page still contributes a sliver so
    # pure-tag matches aren't silently dropped to zero score.
    raw = 1.0 - (df / total_pages)
    return max(0.05, min(1.0, raw))


def score_match(matched_score: float, match_count: int, body_len: int) -> str:
    """Bucket the weighted score into confidence tiers.

    The thresholds are chosen empirically against the pilot: a single title-
    derived term hit (weight 1.0) on a page longer than 200 chars is `medium`;
    two title hits, or one title hit plus high-weight tag hits summing past
    1.5, is `high`; everything else (thin tag-only matches) is `low`.
    """
    if matched_score >= 1.5 or match_count >= 3:
        return "high"
    if matched_score >= 0.9 or match_count == 2:
        return "medium"
    if match_count >= 1 and body_len > 200:
        return "low"
    return "low"


def main() -> None:
    parser = argparse.ArgumentParser(description="Find candidate backlinks for a new wiki page")
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")
    parser.add_argument("--new-page", required=True, help="Slug of the newly ingested page")
    parser.add_argument("--top-n", type=int, default=0,
                        help="After ranking, keep only the top N candidates (0 = no limit)")
    parser.add_argument("--min-confidence", choices=["low", "medium", "high"],
                        default="low",
                        help="Drop candidates below this confidence tier")
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    pages_dir = wiki_root / "wiki" / "pages"
    new_slug = args.new_page.strip().lower()

    if not pages_dir.is_dir():
        fail(f"wiki/pages/ not found under {wiki_root}")

    new_page_path = pages_dir / f"{new_slug}.md"
    if not new_page_path.is_file():
        fail(f"new page not found: {new_page_path}")

    try:
        new_text = new_page_path.read_text(encoding="utf-8")
    except OSError as e:
        fail(f"could not read new page: {e}")
        return

    new_fm = parse_frontmatter(new_text)
    title_terms, tag_terms = extract_terms(new_text, new_fm)
    if not title_terms and not tag_terms:
        ok({"candidates": [], "note": "new page has no extractable search terms"})

    # Always include the slug itself and the title lowercased as title-weighted terms.
    title_terms.add(new_slug)
    title_terms.add(new_slug.replace("-", " "))

    # Compute tag-IDF once across the whole wiki so common tags like `agent`
    # contribute near-zero weight and rare tags like `claim-verification` dominate.
    tag_df, total_pages = compute_tag_document_frequency(pages_dir)

    # Any term that also appears as a tag in the corpus gets IDF-weighted —
    # even if it came from the title. This catches the failure mode where a
    # title word like "agent" in "Claim Verifier Agent" would otherwise get
    # weight 1.0 and drown out the rare tag matches that actually matter.
    term_weights: dict = {}
    for t in title_terms | tag_terms:
        if t in tag_df:
            term_weights[t] = tag_weight(t, tag_df, total_pages)
        else:
            term_weights[t] = 1.0

    candidates = []
    for page in sorted(pages_dir.glob("*.md")):
        if page.name == f"{new_slug}.md":
            continue
        if page.name.startswith("lint-"):
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        body_lower = text.lower()
        body_len = len(text)
        matched = sorted({term for term in term_weights if term in body_lower})
        if not matched:
            continue
        matched_score = sum(term_weights[term] for term in matched)
        existing_backlink = f"[[{new_slug}]]" in body_lower
        candidates.append(
            {
                "page": page.stem,
                "matched_terms": matched,
                "matched_score": round(matched_score, 3),
                "confidence": score_match(matched_score, len(matched), body_len),
                "existing_backlink": existing_backlink,
            }
        )

    # Rank by confidence bucket, then by weighted score (desc), then by slug.
    order = {"high": 0, "medium": 1, "low": 2}
    candidates.sort(
        key=lambda c: (order[c["confidence"]], -c["matched_score"], c["page"])
    )

    # Apply --min-confidence filter, then --top-n cap.
    if args.min_confidence != "low":
        cutoff = order[args.min_confidence]
        candidates = [c for c in candidates if order[c["confidence"]] <= cutoff]
    if args.top_n > 0:
        candidates = candidates[: args.top_n]

    ok({
        "candidates": candidates,
        "search_terms": sorted(term_weights.keys()),
        "total_pages_scanned": total_pages,
    })


if __name__ == "__main__":
    main()
