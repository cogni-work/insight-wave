#!/usr/bin/env python3
"""
wiki-grounding.py — the shared wiki-discovery primitive (#388 Phase 8 d2 core).

`cogni-wiki:wiki-query`'s index→select→read→synthesize discovery ("find the
relevant wiki pages for a question") was reimplemented twice inside
cogni-knowledge: once by the inverted-pipeline read-side (`wiki-coverage.py`'s
token-overlap scorer at `knowledge-curate` Step 0.5) and once it would be needed
by a re-homed query skill. Phase 8 deliverable 2 is explicit: the FMO ships ONE
discovery mechanism, not two. This module is that mechanism — `wiki-coverage.py`
is now a thin per-sub-question caller of `rank_pages` here, and the re-homed
query skill consumes the same primitive directly rather than dispatching
`cogni-wiki:wiki-query`.

It runs on the vendored engine, not cogni-wiki's installed copy: page reading
and frontmatter parsing go through `_knowledge_lib` (which itself resolves the
vendored `cogni-knowledge/scripts/vendor/cogni-wiki/` engine via
`resolve_wiki_scripts`), so this primitive has zero dependency on an installed
cogni-wiki. (Switching the page-walk from the local `_collect_pages` to the
vendored `_wikilib.iter_pages` for full 11-type sync is a deferred follow-up —
it needs a `FRONTMATTER_RE` reconciliation that must not disturb the bilingual
regression cases.)

  rank    Given a question (+ optional theme label) and a wiki root, return the
          ranked covering pages (index-first read order, highest overlap first).
          An empty / unreadable / fresh base yields no pages (fail-soft), so a
          first run behaves exactly like today.

Scoring is **language-robust weighted directional coverage** (#326): a
sub-question's tokens are matched against each page's tokens by directional
weighted recall. Numeric article numbers (13, 99, 101) are kept at any length
and weighted x3.0 — the only reliable cross-lingual bridge ("Artikel 99" <->
"Article 99"). Ubiquitous regulatory boilerplate is denylisted to zero weight.
German compounds match by a length-guarded common prefix (`bussgelder` ~
`bussgeldsystem`), never by substring. A page covers a sub-question only when
both the recall ratio AND an absolute matched-weight floor clear — the floor is
what keeps genuinely-novel sub-questions out of the covering set. Page signal =
title + index one-liner + tags + per-type claim text: `pre_extracted_claims[].text`
on source/synthesis pages, `distilled_claims[].text` on concept/entity pages.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _FRONTMATTER_RE,
    _unquote_scalar,
    compound_match,
    parse_distilled_claims,
    parse_pre_extracted_claims,
    token_weight,
    tokenize,
)

# Recall ratio a page must clear to count as covering. Recall (matched SQ weight
# over total SQ weight) is a stricter quantity than the old Jaccard-over-union,
# so the bar is lower than the original 0.30 (#326).
DEFAULT_THRESHOLD = 0.20
# Absolute matched-weight floor — the second half of the cover predicate. One
# matched article number (len>=1 -> 0.4*3.0 = 1.2) clears it; one weak 4-char
# content token (0.5) does not. This is what keeps a genuinely-novel
# sub-question out of the covering set even when its one accidental token match
# clears the ratio. Calibrated to stay <= 1.2 (a lone anchor must pass) and
# > 0.5 (a lone weak token must not). Do NOT raise above 1.2.
MIN_MATCHED_WEIGHT = 1.0
# Cap the emitted covering pages per sub-question. The verdict is computed on the
# FULL passing set first (so a 60-page base still reads `covered`); only the
# emitted list is truncated, so the caller isn't told to read 60 pages. K >= 2
# preserves the `covered` (>=2) invariant.
TOP_K = 8
# Max pre_extracted_claims[].text fields folded into a page's token signal.
MAX_CLAIMS_PER_PAGE = 8
# Page-type → wiki subdirectory. Plural of "synthesis" is "syntheses", NOT
# "synthesiss" — so emit the resolved relative path per page and never let a
# consumer pluralize `type` itself.
_TYPE_DIRS = {
    "source": "sources",
    "synthesis": "syntheses",
    "concept": "concepts",
    "entity": "entities",
}


# ---------------------------------------------------------------------------
# Coverage scoring (#326). The tokenization primitives this builds on
# (tokenize / token_weight / compound_match / STOPWORDS / GENERIC_DENYLIST) live
# in `_knowledge_lib.py` (#336) so this scorer and `concept-store.py`'s
# claim-dedup share ONE normalization source of truth; they are imported above.
# `coverage_score` is DIRECTIONAL recall (page coverage of a sub-question),
# distinct from `_knowledge_lib.claim_similarity`'s symmetric measure — do not
# conflate the two.
# ---------------------------------------------------------------------------


def coverage_score(sq_tokens: set, page_tokens: set) -> tuple:
    """Directional weighted recall: fraction of the sub-question's *weight*
    covered by the page. Returns (score, matched_weight). Extra page-side tokens
    do NOT dilute (the fix for cross-lingual union bloat). total == 0 (an
    all-boilerplate sub-question) guards to 0.0 rather than dividing by zero."""
    total = 0.0
    matched = 0.0
    for t in sq_tokens:
        w = token_weight(t)
        if w == 0.0:  # denylisted — contributes nothing and cannot match
            continue
        total += w
        if any(compound_match(t, p) for p in page_tokens):
            matched += w
    if total == 0.0:
        return 0.0, 0.0
    return matched / total, matched


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


def collect_pages(wiki_root: Path) -> list[dict]:
    """Gather source/synthesis/concept/entity pages with their title/tags/
    index-summary + per-type claim text (`pre_extracted_claims[].text` for
    source/synthesis, `distilled_claims[].text` for concept/entity).

    Returns a list of {slug, type, page_path (wiki-root-relative), title,
    tags, tokens}. A missing wiki/ dir (fresh base) yields []."""
    wiki_dir = wiki_root / "wiki"
    index_map = _index_summaries(_read_text(wiki_dir / "index.md"))
    pages: list[dict] = []
    for ptype, subdir in _TYPE_DIRS.items():
        d = wiki_dir / subdir
        if not d.is_dir():
            continue
        for page_file in sorted(d.glob("*.md")):
            slug = page_file.stem
            page_text = _read_text(page_file)
            title, tags = _page_title_tags(page_text)
            # Fall back to the slug when a page has no parseable title (block-scalar
            # title, leading-blank/BOM that defeats _FRONTMATTER_RE, or a genuinely
            # title-less page). The slug is descriptive kebab
            # (`eu-ai-act-high-risk-classification`), so it carries real signal;
            # without this a title-less page tokenizes to just its
            # `[source]`/`[synthesis]` tag and goes invisible to coverage.
            title = title or slug
            summary = index_map.get(slug, "")
            # Claim text is the richest TARGET-LANGUAGE signal — a German source
            # page keeps an English title but its claims are German (#326). Pull
            # only `.text` (skip the often-English `excerpt_quote`), capped so a
            # claim-heavy page doesn't swamp the token set. Per-type claim block:
            # source/synthesis carry `pre_extracted_claims:` (a per-source claim
            # list written by the ingester); concept/entity carry `distilled_claims:`
            # (cross-source-distilled facts written by concept-store.py, #336/#343).
            # Same fail-safe contract for both: a parse miss returns [] and the page
            # degrades to title+summary+tag signal only — never a false `covered`.
            if ptype in ("concept", "entity"):
                claims = parse_distilled_claims(page_text)
            else:
                claims = parse_pre_extracted_claims(page_text)
            claim_text = " ".join(
                str(c.get("text", "")) for c in claims[:MAX_CLAIMS_PER_PAGE]
            )
            pages.append({
                "slug": slug,
                "type": ptype,
                "page_path": f"wiki/{subdir}/{page_file.name}",
                "title": title,
                "tags": tags,
                "tokens": tokenize(title, summary, " ".join(tags), claim_text),
            })
    return pages


def sq_token_set(sq: dict) -> set:
    """Sub-question token set: query + theme_label (the target-language lexical
    intent). Two fields are intentionally excluded: `candidate_domains` are bare
    domains (`europa.eu`) with negligible title overlap; `search_guidance` is
    English coverage meta-commentary even on a target-language plan (e.g.
    "GPAI-specific — likely uncovered by the high-risk base"), so it leaks
    generic English tokens (`high`, `risk`, `base`) that match unrelated English
    pages and spuriously cover genuinely-novel sub-questions (#331)."""
    return tokenize(
        str(sq.get("query", "")),
        str(sq.get("theme_label", "")),
    )


def match_reasons(sq_tokens: set, page: dict) -> list[str]:
    """Up to 3 human-readable reasons (debuggability, not behavioural), derived
    from the SAME match function as the score so they never lie: article anchors
    first, then distinctive content terms by weight, then compound matches
    (`bussgeld~bussgeldsystem`). Deterministic — every key sorts to a unique
    token (#326)."""
    page_tokens = sorted(page["tokens"])  # sorted -> deterministic compound hit
    matched: list[tuple] = []  # (sq_token, page_hit, is_exact, weight)
    for t in sq_tokens:
        w = token_weight(t)
        if w == 0.0:
            continue
        hit = None
        for p in page_tokens:
            if compound_match(t, p):
                hit = p
                if t == p:
                    break  # prefer an exact hit over a later compound one
        if hit is not None:
            matched.append((t, hit, t == hit, w))

    reasons: list[str] = []
    anchors = sorted((m for m in matched if m[0].isdigit()), key=lambda m: m[0])
    if anchors:
        reasons.append("article anchor: " + ", ".join(m[0] for m in anchors[:3]))
    terms = sorted((m for m in matched if not m[0].isdigit() and m[2]),
                   key=lambda m: (-m[3], m[0]))
    if terms:
        reasons.append("terms: " + ", ".join(m[0] for m in terms[:3]))
    compounds = sorted((m for m in matched if not m[2] and not m[0].isdigit()),
                       key=lambda m: m[0])
    if compounds:
        reasons.append("compound: " + ", ".join(f"{m[0]}~{m[1]}" for m in compounds[:2]))
    return reasons[:3]


# ---------------------------------------------------------------------------
# The shared ranking primitive
# ---------------------------------------------------------------------------


def rank_pages(pages: list[dict], sq_tokens: set,
               threshold: float = DEFAULT_THRESHOLD, top_k: int = TOP_K) -> dict:
    """The one discovery primitive both call sites resolve to. Given a set of
    pre-collected pages (from `collect_pages`) and a sub-question token set,
    return the ranked covering pages (index-first: highest overlap first, stable
    tie-break by slug) with a coverage verdict.

    Returns {"verdict": "covered"|"partial"|"uncovered",
             "covered_pages": [{slug, type, page_path, title, overlap_score,
                                reasons}],  # capped at top_k
             "passing_count": int}        # the FULL passing set size (pre-cap)

    The cover predicate is BOTH halves: the recall ratio AND the absolute
    matched-weight floor. The floor is what stops a lone weak accidental token
    match (which can clear the ratio on a small sub-question) from flipping a
    genuinely-novel sub-question to `covered` (#326). The verdict is computed on
    the FULL passing set; only the emitted list is capped (top_k >= 2 so the
    `covered` invariant survives the truncation)."""
    scored = []
    for page in pages:
        score, matched_weight = coverage_score(sq_tokens, page["tokens"])
        if score >= threshold and matched_weight >= MIN_MATCHED_WEIGHT:
            scored.append((score, page))
    # Highest overlap first; stable tie-break by slug for determinism.
    scored.sort(key=lambda sp: (-sp[0], sp[1]["slug"]))

    if len(scored) >= 2:
        verdict = "covered"
    elif len(scored) == 1:
        verdict = "partial"
    else:
        verdict = "uncovered"

    covered_pages = [{
        "slug": page["slug"],
        "type": page["type"],
        "page_path": page["page_path"],
        "title": page["title"],
        "overlap_score": round(score, 4),
        "reasons": match_reasons(sq_tokens, page),
    } for score, page in scored[:top_k]]

    return {
        "verdict": verdict,
        "covered_pages": covered_pages,
        "passing_count": len(scored),
    }


# ---------------------------------------------------------------------------
# Envelope + CLI
# ---------------------------------------------------------------------------


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def cmd_rank(args: argparse.Namespace) -> int:
    threshold = args.threshold
    # Lower bound is EXCLUSIVE: coverage_score returns 0.0 for a page with no
    # matching tokens, so `score >= 0.0` would make every page "cover" the
    # question regardless of overlap. A coverage threshold of 0 is meaningless —
    # require a positive one.
    if not (0.0 < threshold <= 1.0):
        return _emit(False, error=f"--threshold must be in (0.0, 1.0], got {threshold}")
    if args.top_k < 1:
        return _emit(False, error=f"--top-k must be >= 1, got {args.top_k}")

    # Build the sub-question token set from --question (+ optional --theme-label),
    # so a caller can reproduce wiki-coverage.py's exact token set (query +
    # theme_label) when it wants per-sub-question parity.
    sq_tokens = sq_token_set({"query": args.question, "theme_label": args.theme_label or ""})

    wiki_root = Path(args.wiki_root)
    pages = collect_pages(wiki_root)  # [] on a fresh / unreadable base
    ranked = rank_pages(pages, sq_tokens, threshold, args.top_k)

    data = {
        "wiki_root": str(wiki_root),
        "threshold": threshold,
        "pages_scanned": len(pages),
        "coverage_verdict": ranked["verdict"],
        "pages": ranked["covered_pages"],
    }
    return _emit(True, data=data)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Shared wiki-grounding discovery primitive for the inverted pipeline (#388 Phase 8 d2).",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_rank = sub.add_parser(
        "rank",
        help="Rank the bound wiki's pages by coverage of a question (index-first).",
    )
    p_rank.add_argument("--wiki-root", required=True,
                        help="Absolute path to the bound wiki root (the dir containing wiki/).")
    p_rank.add_argument("--question", required=True,
                        help="The question / sub-question text to ground against the wiki.")
    p_rank.add_argument("--theme-label", default="",
                        help="Optional thematic label folded into the token set (parity with "
                             "wiki-coverage.py's query+theme_label sub-question tokens).")
    p_rank.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD,
                        help=f"Weighted-recall ratio a page must clear (alongside the matched-weight "
                             f"floor) to count as covering (default {DEFAULT_THRESHOLD}).")
    p_rank.add_argument("--top-k", type=int, default=TOP_K,
                        help=f"Max covering pages to emit (default {TOP_K}).")
    p_rank.set_defaults(func=cmd_rank)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
