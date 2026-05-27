#!/usr/bin/env python3
"""
wiki-coverage.py — read-before-web coverage scorer (P1.3, #309; #326).

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
          synthesis pages by language-robust weighted coverage and emit a
          per-sub-question verdict (covered / partial / uncovered) plus the
          covering pages. An empty / unreadable / fresh base yields
          all-`uncovered`, so run 1 behaves exactly like today (no regression).

Fail-soft by contract: coverage is an OPTIMIZATION, not a correctness gate
(unlike #304's market config, where a wrong authority list corrupts scoring and
hard-aborts). A malformed plan is the one hard error (the caller cannot proceed
without sub-questions); a missing / unreadable wiki is NOT — it degrades to
all-`uncovered`.

Scoring (#326 — language-robust, replaces the original symmetric Jaccard that
was a no-op on every non-English base): a sub-question's tokens are matched
against each page's tokens by *directional weighted recall*. Numeric article
numbers (13, 99, 101) are kept at any length and weighted x3.0 — they are the
only reliable cross-lingual bridge ("Artikel 99" <-> "Article 99"). Ubiquitous
regulatory boilerplate (`verordnung`, `artikel`, `system`, `hochrisiko`, …) is
denylisted to zero weight so it can't dominate ranking. German compounds match
by a length-guarded common prefix (`bussgelder` ~ `bussgeldsystem`), never by
substring (which would re-introduce `system`-inside-`…system` false matches).
A page covers a sub-question only when both the recall ratio AND an absolute
matched-weight floor clear — the floor is what keeps genuinely-novel
sub-questions `uncovered`. Page signal = title + index one-liner + tags +
`pre_extracted_claims[].text` (the richest target-language content). Frontmatter
scalar + claims parsing reuse `_knowledge_lib`.

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
from _knowledge_lib import (  # noqa: E402
    _FRONTMATTER_RE,
    _MANUAL_TRANSLITERATION,
    _unquote_scalar,
    parse_pre_extracted_claims,
)

SCHEMA_VERSION = "0.1.0"
# Recall ratio a page must clear to count as covering. Recall (matched SQ weight
# over total SQ weight) is a stricter quantity than the old Jaccard-over-union,
# so the bar is lower than the original 0.30 (#326).
DEFAULT_THRESHOLD = 0.20
# Absolute matched-weight floor — the second half of the cover predicate. One
# matched article number (len>=1 -> 0.4*3.0 = 1.2) clears it; one weak 4-char
# content token (0.5) does not. This is what keeps a genuinely-novel
# sub-question `uncovered` even when its one accidental token match clears the
# ratio. Calibrated to stay <= 1.2 (a lone anchor must pass) and > 0.5 (a lone
# weak token must not). Do NOT raise above 1.2.
MIN_MATCHED_WEIGHT = 1.0
# Cap the emitted covering pages per sub-question. The verdict is computed on the
# FULL passing set first (so a 60-page base still reads `covered`); only the
# emitted list is truncated, so the curator isn't told to read 60 pages. K >= 2
# preserves the `covered` (>=2) invariant.
TOP_K = 8
# Max pre_extracted_claims[].text fields folded into a page's token signal.
MAX_CLAIMS_PER_PAGE = 8
# Page-type → wiki subdirectory. Plural of "synthesis" is "syntheses", NOT
# "synthesiss" — so emit the resolved relative path per page and never let a
# consumer pluralize `type` itself.
_TYPE_DIRS = {"source": "sources", "synthesis": "syntheses"}


# ---------------------------------------------------------------------------
# Tokenization + deterministic token weighting (#326).
# ---------------------------------------------------------------------------

TOKEN_SPLIT_RE = re.compile(r"[^a-z0-9]+")
STOPWORDS = frozenset({
    # English function words.
    "a", "an", "the", "of", "in", "on", "for", "with", "and", "or", "to", "is", "are", "was", "were",
    "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "should", "can",
    "could", "may", "might", "must", "what", "how", "why", "when", "where", "which", "who", "whom",
    "this", "that", "these", "those", "it", "its", "their", "they", "them", "we", "us", "our",
    "vs", "into", "from", "about", "as", "by", "if", "any", "all", "some", "more", "most",
    # German function words (folded form: umlaut/ß de-accented, lowercase — see
    # _fold). Most are exactly 3 chars (der/die/das/und/von/mit/…), so the <3
    # length-drop does NOT shed them — they must be stopworded explicitly or
    # German queries/pages would score on this noise (#326).
    "und", "der", "die", "das", "den", "dem", "des", "ein", "eine", "einer", "eines", "einem", "einen",
    "fuer", "von", "mit", "auf", "aus", "ist", "sind", "war", "waren", "wird", "werden",
    "nicht", "auch", "oder", "aber", "als", "durch", "bei", "bis", "nach", "vor", "ueber", "unter",
    "zwischen", "dass", "diese", "dieser", "dieses", "diesen", "wie", "was", "wenn", "sowie", "bzw",
})

# Regulatory boilerplate that appears on nearly every page of a regulation wiki
# — zero discriminative value. Without zeroing these, ~60/68 pages share them
# and they dominate ranking, surfacing the wrong pages on top (the #326 defect-5
# failure). Folded (umlaut/ß de-accented, lowercase) to match tokenize() output.
# CRITICAL: this list MUST NOT contain topic-discriminating tokens — on the EN
# side `high`/`risk`/`classification`/`scope` (the only signal the existing
# fixtures match on), on the DE side `bussgeld`/`transparenz`/`governance`/
# `aufsicht`/`sanktion` (what the bilingual regression test relies on). `act` IS
# denylisted: "AI Act" is near-boilerplate on an EU-AI-Act base (like
# `regulation`/`verordnung`), and at 3 chars it can never be a compound prefix
# (compound_match needs cpl>=5), so denylisting it only zeros exact matches (#331).
GENERIC_DENYLIST = frozenset({
    "verordnung", "gesetz", "artikel", "article", "regulation", "act",
    "ki", "ai", "system", "hochrisiko", "eu",
    "anbieter", "betreiber", "anforderung", "anforderungen",
    # Ubiquitous years masquerade as numeric anchors; deny so the digit x3.0
    # boost (token_weight) can't fire on them — denylist is checked first.
    "2024", "2025", "2026",
})


def _stem(token: str) -> str:
    for suffix in ("ing", "ed", "es", "s"):
        if token.endswith(suffix) and len(token) - len(suffix) >= 3:
            return token[: -len(suffix)]
    return token


def _fold(text: str) -> str:
    """De-accent so non-ASCII tokens survive the `[^a-z0-9]+` split instead of
    fragmenting (German `Geschäftsidee` → `geschaeftsidee`, not `gesch`+`ftsidee`;
    `Künstliche` → `kuenstliche`). Lowercase, NFC, the manual umlaut/ß
    transliteration, then **NFD** (canonical) + combining-mark removal. Applied
    identically to both the sub-question and page sides, and to STOPWORDS /
    GENERIC_DENYLIST membership (those are written in folded form), so matching
    stays consistent across languages.

    NFD, NOT NFKD (which `_knowledge_lib.slugify` uses): NFKD *compatibility*
    decomposition fabricates ASCII digits from typographic glyphs (`½` → `1` `2`,
    superscript `²` → `2`, fullwidth `９` → `9`), which `tokenize` would then keep
    as pure-numeric tokens and weight ×3.0 as article-number anchors — a
    typographic footnote marker or fraction in a page's claim text would inject a
    spurious cross-lingual anchor and falsely cover an unrelated sub-question.
    NFD's *canonical* decomposition still de-accents every supported-market
    letter (é→e, ñ→n, Polish ł handled by the manual map) but leaves ½/²/№
    intact so the `[a-z0-9]` split discards them."""
    lowered = unicodedata.normalize("NFC", text.lower())
    for src, dst in _MANUAL_TRANSLITERATION:
        lowered = lowered.replace(src, dst)
    decomposed = unicodedata.normalize("NFD", lowered)
    return "".join(ch for ch in decomposed if not unicodedata.combining(ch))


def tokenize(*parts: str) -> set:
    text = _fold(" ".join(p for p in parts if p))
    raw_tokens = TOKEN_SPLIT_RE.split(text)
    out: set = set()
    for t in raw_tokens:
        if not t or t in STOPWORDS:
            continue
        # Keep all-digit tokens at ANY length — article numbers (13, 99, 101) are
        # the cross-lingual anchors ("Artikel 99" <-> "Article 99"). Every other
        # token keeps the original <3-char drop, which sheds eu/ki/ai-style
        # 2-char boilerplate and split fragments (#326).
        if not t.isdigit() and len(t) < 3:
            continue
        out.add(_stem(t))
    return out


def token_weight(token: str) -> float:
    """Deterministic discriminativeness weight in [0, 3.0].

    Boilerplate -> 0.0 (checked first, so a denylisted *year* never gets the
    numeric x3.0 boost). Otherwise base = clamp(len/8, 0.4, 1.0) rewards longer,
    more-specific tokens, times a x3.0 anchor multiplier for pure article numbers
    (the cross-lingual bridge) and x1.0 for everything else. NOT corpus-IDF:
    IDF amplifies rare tokens and would inflate accidental matches on a
    genuinely-novel sub-question, and degenerates on a 1-page base (#326)."""
    if token in GENERIC_DENYLIST:
        return 0.0
    base = len(token) / 8.0
    base = 0.4 if base < 0.4 else (1.0 if base > 1.0 else base)
    return base * (3.0 if token.isdigit() else 1.0)


def _common_prefix_len(a: str, b: str) -> int:
    n = 0
    for ca, cb in zip(a, b):
        if ca != cb:
            break
        n += 1
    return n


def compound_match(t_sq: str, t_pg: str) -> bool:
    """True if a sub-question token covers a page token. Exact match is the
    trivial case; otherwise a length-guarded common *prefix* handles German
    compounds (`bussgelder` ~ `bussgeldsystem`, prefix `bussgeld`=8). Prefix-only
    (never substring) is deliberate: it rejects `system` inside
    `risikomanagementsystem` (a suffix; common prefix "") and short `art` against
    `artikel` (prefix `art`=3 < 5). The 0.6-of-shorter-length guard rejects
    shared-generic-prefix false matches (`risiko…`). Denylisted tokens on either
    side never match (#326)."""
    if t_sq in GENERIC_DENYLIST or t_pg in GENERIC_DENYLIST:
        return False
    if t_sq == t_pg:
        return True
    cpl = _common_prefix_len(t_sq, t_pg)
    if cpl < 5 or cpl < 0.6 * min(len(t_sq), len(t_pg)):
        return False
    # The shared head must itself be discriminative. Two compounds that merely
    # share a boilerplate stem (`systemverwaltung` ~ `systeme`, common prefix
    # `system`; `hochrisikobereich` ~ `hochrisikosystem`, common prefix
    # `hochrisiko`) are NOT a real topical match — reject when the common prefix
    # is a denylisted token. `bussgelder` ~ `bussgeldsystem` (prefix `bussgeld`)
    # and `aufsichtsbehoerde` ~ `aufsicht` (prefix `aufsicht`) survive (#326).
    return t_sq[:cpl] not in GENERIC_DENYLIST


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
    """Gather source + synthesis pages with their title/tags/index-summary +
    pre-extracted claim text.

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
            # claim-heavy page doesn't swamp the token set. Reuses
            # _knowledge_lib.parse_pre_extracted_claims on the already-read text.
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


def _sq_tokens(sq: dict) -> set:
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


def _match_reasons(sq_tokens: set, page: dict) -> list[str]:
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


def cmd_score(args: argparse.Namespace) -> int:
    threshold = args.threshold
    # Lower bound is EXCLUSIVE: coverage_score returns 0.0 for a page with no
    # matching tokens, so `score >= 0.0` would make every page "cover" every
    # sub-question regardless of overlap. A coverage threshold of 0 is
    # meaningless — require a positive one.
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
            score, matched_weight = coverage_score(sq_tokens, page["tokens"])
            # Cover predicate is BOTH halves: the recall ratio AND the absolute
            # matched-weight floor. The floor is what stops a lone weak accidental
            # token match (which can clear the ratio on a small sub-question) from
            # flipping a genuinely-novel sub-question to `covered` (#326).
            if score >= threshold and matched_weight >= MIN_MATCHED_WEIGHT:
                scored.append((score, page))
        # Highest overlap first; stable tie-break by slug for determinism.
        scored.sort(key=lambda sp: (-sp[0], sp[1]["slug"]))

        # Verdict is computed on the FULL passing set; only the emitted list is
        # capped (TOP_K >= 2, so the `covered` invariant survives the truncation).
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
            "reasons": _match_reasons(sq_tokens, page),
        } for score, page in scored[:TOP_K]]

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
                         help=f"Weighted-recall ratio a page must clear (alongside the matched-weight "
                              f"floor) to count as covering (default {DEFAULT_THRESHOLD}).")
    p_score.set_defaults(func=cmd_score)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
