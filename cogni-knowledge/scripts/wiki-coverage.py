#!/usr/bin/env python3
"""
wiki-coverage.py — read-before-web coverage scorer (P1.3, #309).

The differentiation thesis (`references/differentiation-thesis.md`) promises
"the next research run reads the base before going to the web." Before this
script existed, `knowledge-curate` (Phase 2) fanned one `source-curator` per
sub-question and each one WebSearched immediately — never consulting the bound
wiki. Every run was therefore a full web run and the promised decreasing
cost-per-run never materialized.

This script is the deterministic half of the fix. The orchestrator
(`knowledge-curate`) runs it ONCE per run (mirroring the #304
resolve-market-config-once pattern), and threads the resulting manifest to each
curator, which makes the LLM judgment of how to narrow its search. Division of
labour: this script *surfaces candidate already-covering wiki pages* by token
overlap; the curator agent *reads those pages and decides query/fetch
narrowing*.

  score   For each sub-question in plan.json, score the bound wiki's source +
          synthesis pages by token (Jaccard) overlap and emit a per-sub-question
          coverage verdict (covered / partial / uncovered) plus the covering
          pages. An empty / unreadable / fresh base yields all-`uncovered`, so
          run 1 behaves exactly like today (no regression).

Fail-soft by contract: coverage is an OPTIMIZATION, not a correctness gate
(unlike #304's market config, where a wrong authority list corrupts scoring and
hard-aborts). A malformed plan is the one hard error (the caller cannot proceed
without sub-questions); a missing / unreadable wiki is NOT — it degrades to
all-`uncovered`.

The `tokenize()` / `_stem()` / `jaccard()` / STOPWORDS below are a point-in-time
replica of `cogni-wiki/skills/wiki-refresh/scripts/refresh_planner.py:92-198`
(the proven stale-page→sub-question matcher). Replicating rather than importing
cogni-wiki is the established clean-break pattern — exactly how
`_knowledge_lib.slugify` / `normalize_url` already diverge from their upstream
lifts by design. Frontmatter scalar parsing reuses `_knowledge_lib`.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import _FRONTMATTER_RE, _MANUAL_TRANSLITERATION, _unquote_scalar  # noqa: E402

SCHEMA_VERSION = "0.1.0"
DEFAULT_THRESHOLD = 0.30
# Page-type → wiki subdirectory. Plural of "synthesis" is "syntheses", NOT
# "synthesiss" — so emit the resolved relative path per page and never let a
# consumer pluralize `type` itself.
_TYPE_DIRS = {"source": "sources", "synthesis": "syntheses"}


# ---------------------------------------------------------------------------
# Tokenization — point-in-time replica of refresh_planner.py:92-198 (cogni-wiki).
# ---------------------------------------------------------------------------

TOKEN_SPLIT_RE = re.compile(r"[^a-z0-9]+")
STOPWORDS = frozenset({
    "a", "an", "the", "of", "in", "on", "for", "with", "and", "or", "to", "is", "are", "was", "were",
    "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "should", "can",
    "could", "may", "might", "must", "what", "how", "why", "when", "where", "which", "who", "whom",
    "this", "that", "these", "those", "it", "its", "their", "they", "them", "we", "us", "our",
    "vs", "into", "from", "about", "as", "by", "if", "any", "all", "some", "more", "most",
})


def _stem(token: str) -> str:
    for suffix in ("ing", "ed", "es", "s"):
        if token.endswith(suffix) and len(token) - len(suffix) >= 3:
            return token[: -len(suffix)]
    return token


def _fold(text: str) -> str:
    """De-accent so non-ASCII tokens survive the `[^a-z0-9]+` split instead of
    fragmenting (German `Geschäftsidee` → `geschaeftsidee`, not `gesch`+`ftsidee`;
    `Künstliche` → `kuenstliche`). Mirrors `_knowledge_lib.slugify`'s
    normalization — lowercase, NFC, the manual umlaut/ß transliteration, then
    NFKD + combining-mark removal. Applied identically to both the sub-question
    and page sides, so Jaccard matching stays symmetric. This intentionally
    DIVERGES from the `refresh_planner` replica (which is ASCII-only) because
    cogni-knowledge targets German/EU content — the same reason `slugify`
    already diverges from its own upstream lift."""
    lowered = unicodedata.normalize("NFC", text.lower())
    for src, dst in _MANUAL_TRANSLITERATION:
        lowered = lowered.replace(src, dst)
    decomposed = unicodedata.normalize("NFKD", lowered)
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def tokenize(*parts: str) -> set:
    text = _fold(" ".join(p for p in parts if p))
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


# ---------------------------------------------------------------------------
# Envelope
# ---------------------------------------------------------------------------


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


# ---------------------------------------------------------------------------
# Frontmatter + index parsing
# ---------------------------------------------------------------------------

_TITLE_RE = re.compile(r"^title[ \t]*:[ \t]*(.+?)[ \t]*$")
_TAGS_RE = re.compile(r"^tags[ \t]*:[ \t]*\[(.*)\][ \t]*$")
# An index catalog line: `- [[<slug>]] — <summary>` (em-dash or hyphen). The
# summary is best-effort enrichment; a bare `- [[<slug>]]` is fine (no summary).
_INDEX_LINE_RE = re.compile(r"^\s*-\s*\[\[([^\]]+)\]\]\s*(?:[—–-]\s*(.*))?$")


def _page_title_tags(page_text: str) -> tuple[str, list[str]]:
    """Pull `title` (str) + `tags` (list[str]) from a wiki page's flat
    frontmatter scalars. Reuses `_knowledge_lib._FRONTMATTER_RE` for the block
    and `_unquote_scalar` for quoted values. Anything it cannot read returns
    empty — coverage simply leans toward `uncovered`, never an error."""
    title = ""
    tags: list[str] = []
    m = _FRONTMATTER_RE.match(page_text or "")
    if not m:
        return title, tags
    for line in m.group(1).splitlines():
        tm = _TITLE_RE.match(line)
        if tm and not title:
            raw = tm.group(1).strip()
            # Strip a YAML inline comment from an UNQUOTED scalar only (a quoted
            # title keeps `#` verbatim) — mirrors _knowledge_lib._absorb_claim_kv.
            if raw[:1] not in ('"', "'"):
                hash_pos = raw.find(" #")
                if hash_pos != -1:
                    raw = raw[:hash_pos].rstrip()
            title = _unquote_scalar(raw)
            continue
        gm = _TAGS_RE.match(line)
        if gm and not tags:
            inner = gm.group(1).strip()
            if inner:
                tags = [_unquote_scalar(t.strip()) for t in inner.split(",") if t.strip()]
    return title, tags


def _index_summaries(index_text: str) -> dict:
    """Map `slug → one-line summary` from `wiki/index.md`'s catalog lines
    (`- [[<slug>]] — <summary>`). The summary is the ingester's distilled
    description and the richest per-page signal (page `tags` default to
    `[source]` / `[synthesis]`, so they carry almost no discriminating signal)."""
    out: dict = {}
    for line in (index_text or "").splitlines():
        m = _INDEX_LINE_RE.match(line)
        if not m:
            continue
        slug = m.group(1).strip()
        summary = (m.group(2) or "").strip()
        if slug and slug not in out:
            out[slug] = summary
    return out


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return ""


def _collect_pages(wiki_root: Path) -> list[dict]:
    """Gather source + synthesis pages with their title/tags/index-summary.

    Returns a list of {slug, type, page_path (wiki-root-relative), title,
    tokens}. A missing wiki/ dir (fresh base) yields []."""
    wiki_dir = wiki_root / "wiki"
    index_map = _index_summaries(_read_text(wiki_dir / "index.md"))
    pages: list[dict] = []
    for ptype, subdir in _TYPE_DIRS.items():
        d = wiki_dir / subdir
        if not d.is_dir():
            continue
        for page_file in sorted(d.glob("*.md")):
            slug = page_file.stem
            title, tags = _page_title_tags(_read_text(page_file))
            # Fall back to the slug when a page has no parseable title (block-scalar
            # title, leading-blank/BOM that defeats _FRONTMATTER_RE, or a genuinely
            # title-less page) — mirrors refresh_planner's `title or slug`. The slug
            # is descriptive kebab (`eu-ai-act-high-risk-classification`), so it
            # carries real signal; without this a title-less page tokenizes to just
            # its `[source]`/`[synthesis]` tag and goes invisible to coverage.
            title = title or slug
            summary = index_map.get(slug, "")
            pages.append({
                "slug": slug,
                "type": ptype,
                "page_path": f"wiki/{subdir}/{page_file.name}",
                "title": title,
                "tags": tags,
                "tokens": tokenize(title, summary, " ".join(tags)),
            })
    return pages


def _sq_tokens(sq: dict) -> set:
    """Sub-question token set: query + theme_label + search_guidance (all free
    text — the strong lexical signal). `candidate_domains` are bare domains
    (`europa.eu`) with negligible title overlap, so they are intentionally
    excluded."""
    return tokenize(
        str(sq.get("query", "")),
        str(sq.get("theme_label", "")),
        str(sq.get("search_guidance", "")),
    )


def _match_reasons(sq_tokens: set, page: dict) -> list[str]:
    """Up to 3 human-readable reasons (debuggability, not behavioural).
    Deterministic — sorted token iteration. Mirrors
    refresh_planner.explain_match."""
    reasons: list[str] = []
    tag_tokens = tokenize(" ".join(page["tags"]))
    overlap_tags = sorted(t for t in tag_tokens if t in sq_tokens)
    if overlap_tags:
        reasons.append(f"tag overlap: {overlap_tags[:3]}")
    title_tokens = tokenize(page["title"])
    title_hits = sorted(t for t in title_tokens if t in sq_tokens)
    if title_hits:
        reasons.append(f"title term: '{title_hits[0]}'")
    return reasons[:3]


def cmd_score(args: argparse.Namespace) -> int:
    threshold = args.threshold
    # Lower bound is EXCLUSIVE: jaccard returns 0.0 for disjoint/empty token sets,
    # so `score >= 0.0` would make every page "cover" every sub-question regardless
    # of overlap. A coverage threshold of 0 is meaningless — require a positive one.
    if not (0.0 < threshold <= 1.0):
        return _emit(False, error=f"--threshold must be in (0.0, 1.0], got {threshold}")

    # plan.json is the one HARD input — without sub-questions there is nothing
    # to score. A malformed plan is a clean success:false (the caller writes an
    # all-uncovered manifest itself; see knowledge-curate Step 0.5).
    plan_path = Path(args.plan)
    try:
        plan = json.loads(plan_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return _emit(False, error=f"could not read plan.json at {plan_path}: {exc}")
    if not isinstance(plan, dict) or not isinstance(plan.get("sub_questions"), list):
        return _emit(False, error=f"plan.json at {plan_path} has no sub_questions[] list")

    wiki_root = Path(args.wiki_root)
    pages = _collect_pages(wiki_root)  # [] on a fresh / unreadable base

    sub_questions: list[dict] = []
    for sq in plan["sub_questions"]:
        if not isinstance(sq, dict):
            continue
        sq_id = str(sq.get("id", ""))
        sq_tokens = _sq_tokens(sq)
        scored = []
        for page in pages:
            score = jaccard(sq_tokens, page["tokens"])
            if score >= threshold:
                scored.append((score, page))
        # Highest overlap first; stable tie-break by slug for determinism.
        scored.sort(key=lambda sp: (-sp[0], sp[1]["slug"]))
        covered_pages = [{
            "slug": page["slug"],
            "type": page["type"],
            "page_path": page["page_path"],
            "title": page["title"],
            "overlap_score": round(score, 4),
            "reasons": _match_reasons(sq_tokens, page),
        } for score, page in scored]

        if len(covered_pages) >= 2:
            verdict = "covered"
        elif len(covered_pages) == 1:
            verdict = "partial"
        else:
            verdict = "uncovered"

        sub_questions.append({
            "sq_id": sq_id,
            "coverage_verdict": verdict,
            "covered_pages": covered_pages,
        })

    data = {
        "schema_version": SCHEMA_VERSION,
        "wiki_root": str(wiki_root),
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "threshold": threshold,
        "pages_scanned": len(pages),
        "sub_questions": sub_questions,
    }
    return _emit(True, data=data)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read-before-web coverage scorer for the inverted pipeline (P1.3, #309).",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_score = sub.add_parser(
        "score",
        help="Score the bound wiki's coverage of each plan.json sub-question.",
    )
    p_score.add_argument("--wiki-root", required=True,
                         help="Absolute path to the bound wiki root (the dir containing wiki/).")
    p_score.add_argument("--plan", required=True,
                         help="Absolute path to <project>/.metadata/plan.json.")
    p_score.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD,
                         help=f"Jaccard overlap a page must clear to count as covering (default {DEFAULT_THRESHOLD}).")
    p_score.set_defaults(func=cmd_score)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
