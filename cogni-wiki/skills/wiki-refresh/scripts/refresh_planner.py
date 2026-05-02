#!/usr/bin/env python3
"""
refresh_planner.py — match stale wiki pages to cogni-research sub-questions
and emit a refresh plan on stdout. The wiki-refresh skill consumes this
plan: it materialises one refresh markdown per matched (page, sub-question)
pair and dispatches wiki-update to apply each.

Boundary: this script does NOT write to the wiki. It only reads and emits
JSON. Materialisation lives in the SKILL.md (Step 5), which keeps the
script idempotent and dry-run-safe.

Match algorithm: Jaccard on token sets, page-side = title + tags + type,
sub-question-side = query + parent_topic. Stopword-filtered, lightly
suffix-stripped. Symmetric and deterministic. Threshold default 0.30.

Stdlib-only, Python 3.8+. Output contract:

    {
      "success": true,
      "data": {
        "matches": [
          {
            "page": "<slug>",
            "page_title": "...",
            "page_age_days": <int>,
            "page_type": "<type>",
            "page_tags": [...],
            "sub_question": "<sq-id>",
            "sub_question_query": "...",
            "sub_question_section_index": <int>,
            "score": <float>,
            "reasons": ["tag overlap: [...]", "title term: '<t>'", ...]
          }
        ],
        "unmatched_pages": ["<slug>", ...],
        "stats": {
          "stale_pages_total": <int>,
          "matched": <int>,
          "below_threshold": <int>,
          "sub_questions_total": <int>
        }
      },
      "error": ""
    }

    On failure: {"success": false, "data": {}, "error": "..."} with exit 1.

Note on duplication: lines 100–230 (frontmatter parser, wikilink stripper,
entity loaders) mirror equivalent helpers in
`cogni-wiki/skills/wiki-ingest/scripts/batch_builder.py`. The duplication
is acknowledged tech debt — both targets share the same cogni-research
entity contract (`schemas/{sub-question,context,source,report-claim}.schema.json`),
and a schema change would touch both consumers anyway. Refactor is non-urgent
(parallel to the `_wiki_lock` situation described in cogni-wiki/CLAUDE.md).
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path


# Staleness thresholds — must match cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py
STALE_DRAFT_DAYS = 180
STALE_PAGE_DAYS = 365

DEFAULT_THRESHOLD = 0.30

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
SLUG_CLEAN_RE = re.compile(r"[^a-z0-9]+")
TOKEN_SPLIT_RE = re.compile(r"[^a-z0-9]+")

STOPWORDS = frozenset({
    "a", "an", "the", "of", "in", "on", "for", "with", "and", "or", "to", "is", "are", "was", "were",
    "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "should", "can",
    "could", "may", "might", "must", "what", "how", "why", "when", "where", "which", "who", "whom",
    "this", "that", "these", "those", "it", "its", "their", "they", "them", "we", "us", "our",
    "vs", "into", "from", "about", "as", "by", "if", "any", "all", "some", "more", "most",
})


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


# ---------------------------------------------------------------------------
# Frontmatter / wikilink helpers (mirror batch_builder.py)
# ---------------------------------------------------------------------------


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
                out[k] = [x.strip() for x in inside.split(",") if x.strip()] if inside else []
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def _unquote(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def _strip_wikilink(ref: str) -> str:
    inner = _unquote(ref)
    if inner.startswith("[[") and inner.endswith("]]"):
        inner = inner[2:-2]
    return inner.rsplit("/", 1)[-1]


def parse_date(s: str):
    try:
        return dt.datetime.strptime(s.strip(), "%Y-%m-%d").date()
    except (ValueError, AttributeError):
        return None


# ---------------------------------------------------------------------------
# Wiki side: stale page enumeration
# ---------------------------------------------------------------------------


def find_wiki_root(start: Path) -> Path:
    current = start.resolve()
    while True:
        if (current / ".cogni-wiki" / "config.json").is_file():
            return current
        if current.parent == current:
            fail(f"not inside a cogni-wiki (no .cogni-wiki/config.json at or above {start})")
        current = current.parent


def load_wiki_pages(wiki_root: Path) -> list[dict]:
    """Return all wiki pages with parsed frontmatter and computed age."""
    pages_dir = wiki_root / "wiki" / "pages"
    if not pages_dir.is_dir():
        return []
    today = dt.date.today()
    pages: list[dict] = []
    for path in sorted(pages_dir.iterdir()):
        if not (path.is_file() and path.suffix == ".md"):
            continue
        if path.name.startswith("lint-"):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        slug = path.stem
        title = _unquote(fm.get("title", "")) or slug
        page_type = _unquote(fm.get("type", "")) or "summary"
        tags = fm.get("tags", []) if isinstance(fm.get("tags"), list) else []
        tags = [_unquote(t) for t in tags if isinstance(t, str)]
        sources = fm.get("sources", []) if isinstance(fm.get("sources"), list) else []
        sources = [_unquote(s) for s in sources if isinstance(s, str)]
        status = _unquote(fm.get("status", "")).lower()
        updated_str = _unquote(fm.get("updated", ""))
        updated = parse_date(updated_str)
        age_days = (today - updated).days if updated else None
        pages.append({
            "slug": slug,
            "title": title,
            "type": page_type,
            "tags": tags,
            "sources": sources,
            "status": status,
            "updated": updated_str,
            "age_days": age_days,
            "path": path,
        })
    return pages


def filter_stale(pages: list[dict], days_override: int | None) -> list[dict]:
    """Apply lint's staleness rule (or --days override) to the page list."""
    out = []
    for p in pages:
        age = p.get("age_days")
        if age is None:
            # No valid `updated:` — lint flags as a frontmatter warning, not stale.
            # Skip here; stale-by-age is the only signal this script consumes.
            continue
        if days_override is not None:
            if age > days_override:
                out.append(p)
        else:
            if p["status"] == "draft" and age > STALE_DRAFT_DAYS:
                out.append(p)
            elif age > STALE_PAGE_DAYS:
                out.append(p)
    return out


# ---------------------------------------------------------------------------
# Research side: entity loaders (mirrors batch_builder.py)
# ---------------------------------------------------------------------------


def locate_research_project(slug_or_path: str, wiki_root: Path, override: str | None) -> Path:
    if override:
        project = Path(override).resolve()
        if not project.is_dir():
            fail(f"--research-root not a directory: {project}")
        return project
    if "/" in slug_or_path or slug_or_path.startswith("."):
        candidate = Path(slug_or_path).resolve()
        if candidate.is_dir():
            return candidate
        fail(f"--research path not found: {candidate}")
    candidates = [
        wiki_root.parent / f"cogni-research-{slug_or_path}",
        wiki_root / f"cogni-research-{slug_or_path}",
    ]
    for c in candidates:
        if c.is_dir():
            return c.resolve()
    fail(
        "cogni-research project not found. Tried: "
        + ", ".join(str(c) for c in candidates)
        + ". Pass --research-root to override."
    )
    return Path()  # unreachable


def load_sub_questions(project: Path) -> list[dict]:
    sq_dir = project / "00-sub-questions" / "data"
    if not sq_dir.is_dir():
        fail(f"sub-questions dir missing: {sq_dir}")
    items: list[dict] = []
    for path in sorted(sq_dir.glob("sq-*.md")):
        text = path.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        if not fm.get("query"):
            continue
        try:
            section_index = int(fm.get("section_index", 0))
        except (TypeError, ValueError):
            section_index = 0
        items.append({
            "id": _unquote(fm.get("dc:identifier") or path.stem),
            "query": _unquote(fm["query"]),
            "parent_topic": _unquote(fm.get("parent_topic", "")),
            "section_index": section_index,
            "status": _unquote(fm.get("status", "")),
        })
    items.sort(key=lambda x: (x["section_index"], x["id"]))
    return items


# ---------------------------------------------------------------------------
# Tokenizer
# ---------------------------------------------------------------------------


def _stem(token: str) -> str:
    """Mini suffix-stripper. Order matters: longest suffix first."""
    if len(token) < 4:
        return token
    if token.endswith("ies") and len(token) > 4:
        return token[:-3] + "y"
    for suffix in ("ing", "ed", "es", "s"):
        if token.endswith(suffix) and len(token) - len(suffix) >= 3:
            return token[: -len(suffix)]
    return token


def tokenize(*parts: str) -> set:
    text = " ".join(p for p in parts if p)
    text = text.lower()
    raw_tokens = TOKEN_SPLIT_RE.split(text)
    out: set = set()
    for t in raw_tokens:
        if len(t) < 3:
            continue
        if t in STOPWORDS:
            continue
        out.add(_stem(t))
    return out


def jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 0.0
    union = a | b
    if not union:
        return 0.0
    return len(a & b) / len(union)


def explain_match(page: dict, sq: dict, page_tokens: set, sq_tokens: set) -> list[str]:
    """Up to 3 human-readable reasons. Debuggability, not behavioural.

    Deterministic — sorted token iteration so reruns produce identical reasons.
    """
    reasons: list[str] = []
    page_tag_tokens = tokenize(" ".join(page["tags"]))
    overlap_tags = sorted(t for t in page_tag_tokens if t in sq_tokens)
    if overlap_tags:
        reasons.append(f"tag overlap: {overlap_tags[:3]}")
    title_tokens = tokenize(page["title"])
    title_hits = sorted(t for t in title_tokens if t in sq_tokens)
    if title_hits:
        reasons.append(f"title term: '{title_hits[0]}'")
    type_token = tokenize(page["type"])
    if type_token and any(t in sq_tokens for t in type_token):
        reasons.append("type match")
    return reasons[:3]


# ---------------------------------------------------------------------------
# Match planner
# ---------------------------------------------------------------------------


def build_plan(
    stale_pages: list[dict],
    sub_questions: list[dict],
    threshold: float,
    force: bool,
    limit: int | None,
) -> dict:
    matches: list[dict] = []
    unmatched: list[str] = []
    below_threshold = 0

    sq_token_cache: dict = {}
    for sq in sub_questions:
        sq_token_cache[sq["id"]] = tokenize(sq["query"], sq["parent_topic"])

    for page in stale_pages:
        page_tokens = tokenize(page["title"], " ".join(page["tags"]), page["type"])
        best: dict | None = None
        for sq in sub_questions:
            score = jaccard(page_tokens, sq_token_cache[sq["id"]])
            if best is None or (score, -sq["section_index"], sq["id"]) > (
                best["score"], -best["sub_question_section_index"], best["sub_question"]
            ):
                # Tie-break: higher score wins; on tie, lower section_index wins;
                # on tie, lex sub-question id wins. We invert section_index so
                # max-tuple compare picks the lower one.
                best = {
                    "score": score,
                    "sub_question": sq["id"],
                    "sub_question_query": sq["query"],
                    "sub_question_section_index": sq["section_index"],
                    "_sq_obj": sq,
                    "_page_tokens": page_tokens,
                }
        if best is None:
            unmatched.append(page["slug"])
            continue
        if best["score"] < threshold and not force:
            below_threshold += 1
            unmatched.append(page["slug"])
            continue
        reasons = explain_match(page, best["_sq_obj"], best["_page_tokens"], sq_token_cache[best["sub_question"]])
        matches.append({
            "page": page["slug"],
            "page_title": page["title"],
            "page_age_days": page["age_days"],
            "page_type": page["type"],
            "page_tags": page["tags"],
            "sub_question": best["sub_question"],
            "sub_question_query": best["sub_question_query"],
            "sub_question_section_index": best["sub_question_section_index"],
            "score": round(best["score"], 4),
            "reasons": reasons,
        })

    # Sort matches by score desc for plan readability and --limit.
    matches.sort(key=lambda m: (-m["score"], m["sub_question_section_index"], m["page"]))

    if limit is not None and limit >= 0:
        if len(matches) > limit:
            dropped = matches[limit:]
            matches = matches[:limit]
            for m in dropped:
                unmatched.append(m["page"])

    return {
        "matches": matches,
        "unmatched_pages": sorted(set(unmatched)),
        "stats": {
            "stale_pages_total": len(stale_pages),
            "matched": len(matches),
            "below_threshold": below_threshold,
            "sub_questions_total": len(sub_questions),
        },
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Match stale wiki pages to cogni-research sub-questions; emit refresh plan as JSON.",
    )
    parser.add_argument("--research-slug", required=True, help="cogni-research project slug or path.")
    parser.add_argument("--research-root", help="Override auto-located project root.")
    parser.add_argument("--wiki-root", help="Override auto-detected wiki root.")
    parser.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD,
                        help=f"Jaccard threshold for matching (default {DEFAULT_THRESHOLD}).")
    parser.add_argument("--days", type=int, default=None,
                        help="Override staleness threshold (collapses STALE_PAGE_DAYS+STALE_DRAFT_DAYS to N).")
    parser.add_argument("--pages", help="Comma-separated page slug list; bypasses staleness filter.")
    parser.add_argument("--limit", type=int, default=None, help="Cap matches at N after ranking.")
    parser.add_argument("--force", action="store_true",
                        help="With --pages: include sub-threshold matches.")
    args = parser.parse_args()

    if args.pages and args.days is not None:
        fail("--pages and --days are mutually exclusive")
    if args.threshold < 0.0 or args.threshold > 1.0:
        fail(f"--threshold must be in [0.0, 1.0], got {args.threshold}")

    return args


def main() -> None:
    args = parse_args()

    wiki_root = Path(args.wiki_root).resolve() if args.wiki_root else find_wiki_root(Path.cwd())
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki: {wiki_root}/.cogni-wiki/config.json not found")

    project = locate_research_project(args.research_slug, wiki_root, args.research_root)
    if not (project / "project-config.json").is_file():
        fail(f"not a cogni-research project (missing project-config.json): {project}")

    sub_questions = load_sub_questions(project)
    if not sub_questions:
        ok({
            "matches": [],
            "unmatched_pages": [],
            "stats": {"stale_pages_total": 0, "matched": 0, "below_threshold": 0, "sub_questions_total": 0},
        })

    all_pages = load_wiki_pages(wiki_root)
    if args.pages:
        wanted = {s.strip() for s in args.pages.split(",") if s.strip()}
        stale_pages = [p for p in all_pages if p["slug"] in wanted]
        # Note: we do NOT filter by age here — explicit --pages bypasses staleness.
        missing = wanted - {p["slug"] for p in stale_pages}
        # Missing slugs are not fatal; they're surfaced via the SKILL's pre-flight,
        # not here. The planner just doesn't include them.
        del missing
    else:
        stale_pages = filter_stale(all_pages, args.days)

    plan = build_plan(stale_pages, sub_questions, args.threshold, args.force, args.limit)
    ok(plan)


if __name__ == "__main__":
    main()
