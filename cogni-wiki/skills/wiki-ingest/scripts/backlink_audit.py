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
    {"success": true, "data": {"candidates": [...]}, "error": ""}

Candidate object:
    {
      "page": "<slug>",
      "matched_terms": ["term1", "term2"],
      "confidence": "low" | "medium" | "high",
      "existing_backlink": true | false
    }

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


def extract_terms(page_text: str, fm: dict) -> set:
    """Build a set of search terms from a page's title and tags."""
    terms: set = set()
    title = fm.get("title", "")
    if isinstance(title, str) and title:
        terms.add(title.strip().lower())
        # Also add individual non-trivial words
        for word in re.findall(r"[a-zA-Z][a-zA-Z0-9\-]{3,}", title):
            terms.add(word.lower())
    tags = fm.get("tags", [])
    if isinstance(tags, list):
        for t in tags:
            if isinstance(t, str):
                terms.add(t.strip().lower())
    return {t for t in terms if len(t) >= 4}


def score_match(matched: list, body_len: int) -> str:
    n = len(matched)
    if n >= 3:
        return "high"
    if n == 2:
        return "medium"
    if n == 1 and body_len > 200:
        return "low"
    return "low"


def main() -> None:
    parser = argparse.ArgumentParser(description="Find candidate backlinks for a new wiki page")
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")
    parser.add_argument("--new-page", required=True, help="Slug of the newly ingested page")
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
    search_terms = extract_terms(new_text, new_fm)
    if not search_terms:
        ok({"candidates": [], "note": "new page has no extractable search terms"})

    # Always include the slug itself and the title lowercased
    search_terms.add(new_slug)
    search_terms.add(new_slug.replace("-", " "))

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
        matched = sorted({term for term in search_terms if term in body_lower})
        if not matched:
            continue
        existing_backlink = f"[[{new_slug}]]" in body_lower
        candidates.append(
            {
                "page": page.stem,
                "matched_terms": matched,
                "confidence": score_match(matched, body_len),
                "existing_backlink": existing_backlink,
            }
        )

    # Rank by confidence, then by number of matched terms, then alphabetically
    order = {"high": 0, "medium": 1, "low": 2}
    candidates.sort(
        key=lambda c: (order[c["confidence"]], -len(c["matched_terms"]), c["page"])
    )

    ok({"candidates": candidates, "search_terms": sorted(search_terms)})


if __name__ == "__main__":
    main()
