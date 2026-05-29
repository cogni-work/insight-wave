#!/usr/bin/env python3
"""
_knowledge_lib.py — shared primitives for cogni-knowledge scripts.

Single source of truth for URL identity in the v0.1.0 inverted pipeline.
`candidate-store.py` (curator-side merge into `candidates.json`) and
`fetch-cache.py` (fetcher-side cache lookup keyed by `sha256(normalize_url(url))`)
must agree byte-for-byte on the canonical form of any URL — otherwise the
curator-side dedup and the fetch-cache hit/miss decision drift, and a URL
present in `candidates.json` can silently miss in the cache (or vice versa).

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import json
import os
import re
import tempfile
import unicodedata
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode

# Tracking-param prefixes/names stripped during URL normalization. Covers
# the common cases seen in EU regulatory crawls; conservative on purpose —
# only well-known tracking params are dropped to avoid breaking URLs that
# rely on a query string for content identity.
_STRIP_QUERY_PREFIXES = ("utm_",)
_STRIP_QUERY_EXACT = frozenset({"ref", "fbclid", "gclid"})


def normalize_url(url: str) -> str:
    """Canonicalize a URL for dedup purposes.

    - Lowercase scheme + host (path case preserved — RFC 3986 §6.2.2.1).
    - Strip trailing `/` from path unless the path is just `/`.
    - Drop query params whose name starts with any _STRIP_QUERY_PREFIXES
      or is in _STRIP_QUERY_EXACT. Remaining params keep their order.
    - Drop fragment.

    Whitespace-only or empty input returns the input unchanged so callers
    surface the bad value rather than silently coalescing distinct entries.
    """
    if not url or not url.strip():
        return url
    parts = urlsplit(url.strip())
    scheme = parts.scheme.lower()
    netloc = parts.netloc.lower()
    path = parts.path
    if path.endswith("/") and path != "/":
        path = path.rstrip("/")
    kept = [
        (k, v)
        for k, v in parse_qsl(parts.query, keep_blank_values=True)
        if not (k.startswith(_STRIP_QUERY_PREFIXES) or k in _STRIP_QUERY_EXACT)
    ]
    query = urlencode(kept)
    return urlunsplit((scheme, netloc, path, query, ""))


def _atomic_write_via(path: Path, writer):
    """Shared core for `atomic_write` (JSON) and `atomic_write_text` (UTF-8).

    `tempfile.mkstemp` so two concurrent writers to the same target cannot
    collide on a predictable `.tmp` suffix; `os.replace` for the atomic
    swap; tmp-file unlink on exception so failures don't leave debris.
    The temp file lives in the same directory as the target so the
    `os.replace` cannot cross devices.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            writer(fh)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    return path


def atomic_write(path: Path, payload: dict) -> Path:
    """Atomically write `payload` as pretty-printed JSON to `path`."""

    def _dump_json(fh):
        json.dump(payload, fh, indent=2, ensure_ascii=False)
        fh.write("\n")

    return _atomic_write_via(path, _dump_json)


def atomic_write_text(path: Path, text: str) -> Path:
    """Atomically write `text` as a UTF-8 file to `path`.

    Sibling of `atomic_write` for non-JSON payloads (markdown pages, log
    entries written by a single writer).
    """
    return _atomic_write_via(path, lambda fh: fh.write(text))


# Slug grammar matches cogni-wiki's wikilink regex
# (cogni-wiki/.../wiki-ingest/scripts/_wikilib.py:WIKILINK_RE), so a slug
# emitted here is a legal `[[wikilink]]` target without further translation.
_SLUG_KEEP_RE = re.compile(r"[^a-z0-9]+")
_SLUG_DASH_RUN_RE = re.compile(r"-+")

# Manual transliteration applied (on NFC-composed, lowercased text) BEFORE the
# NFKD de-accent. NFKD alone is insufficient for two reasons: (1) it strips the
# umlaut diaeresis (ü→u, giving `fur`) where the German convention expands it
# (ü→ue, giving `fuer`); (2) some precomposed Latin letters have NO NFKD
# decomposition (Polish ł) and NFKD would drop them entirely — ł→l keeps the
# supported PL market legible. Capital forms are covered by the prior `.lower()`
# (Ä→ä, ẞ→ß, Ł→ł), so only lowercase keys are needed.
_MANUAL_TRANSLITERATION = (
    ("ä", "ae"), ("ö", "oe"), ("ü", "ue"), ("ß", "ss"), ("ł", "l"),
)


def slugify(text: str, max_len: int = 80) -> str:
    """Canonical lower-kebab slug for wiki pages.

    Single source of truth for slug derivation in the inverted pipeline.
    `knowledge-ingest` calls this once per fetched source (Step 1.2);
    `source-ingester` only sanity-checks the result (`[a-z0-9][a-z0-9-]{0,79}`)
    rather than re-deriving — keeps the orchestrator authoritative.

    Transliterates non-ASCII text before the keep-regex strip so localized
    topics survive: German umlauts expand by convention (`für`→`fuer`,
    `Geschäftsidee`→`geschaeftsidee`), then NFKD + combining-mark removal
    de-accents the remaining Latin scripts (`Café`→`cafe`, `ñ`→`n`, `ç`→`c`).
    Without this pass the keep-regex turns every non-`[a-z0-9]` run into a dash
    (`für`→`f-r`). This intentionally **diverges** from the point-in-time lift
    in `cogni-research/scripts/create-entity.py::slugify` and
    `cogni-wiki/.../batch_builder.py::derive_slug` — drift acceptable per the
    clean-break commitment.

    Empty / non-alnum / whitespace-only input returns "" so callers can
    detect the no-slug case and apply their own fallback (e.g.,
    `src-<short-hash-of-url>`).
    """
    if not text:
        return ""
    # Lowercase, then COMPOSE (NFC) so decomposed input (NFD: u + combining
    # diaeresis — common from macOS paths and some web/clipboard sources)
    # presents as a single `ü` the transliteration map can match. Transliterate,
    # then NFKD-decompose + drop combining marks to de-accent the rest
    # (é→e, ñ→n), then lowercase AGAIN: NFKD compatibility decomposition can emit
    # UPPERCASE ASCII (№→No, ™→TM) that the first `.lower()` never saw.
    lowered = unicodedata.normalize("NFC", text.lower())
    for src, dst in _MANUAL_TRANSLITERATION:
        lowered = lowered.replace(src, dst)
    decomposed = unicodedata.normalize("NFKD", lowered)
    lowered = "".join(ch for ch in decomposed if not unicodedata.combining(ch)).lower()
    dashed = _SLUG_KEEP_RE.sub("-", lowered)
    collapsed = _SLUG_DASH_RUN_RE.sub("-", dashed).strip("-")
    if not collapsed:
        return ""
    if len(collapsed) > max_len:
        collapsed = collapsed[:max_len].rstrip("-")
    return collapsed


# Localized heading for the synthesis-page reference section. Single source of
# truth for the finalize Python side (which imports this module); the
# wiki-composer agent — an LLM, not Python — restates the same mapping in its
# prose. Keyed on the project's `output_language` (ISO 639-1, from plan.json).
# Unknown / unmapped codes fall back to the English word, matching the
# default-to-en posture used elsewhere in the pipeline.
REF_HEADING = {
    "en": "References",
    "de": "Referenzen",
    "fr": "Références",
    "it": "Bibliografia",
    "pl": "Bibliografia",
    "nl": "Referenties",
    "es": "Referencias",
}


def ref_heading(lang: str | None) -> str:
    """Reference-section heading word for `lang` (default/unknown → English).

    `str(...)` coerces a non-str `lang` (e.g. a number from a malformed
    plan.json) to a harmless lookup miss → English, rather than crashing on
    `.lower()`.
    """
    return REF_HEADING.get(str(lang or "en").lower(), REF_HEADING["en"])


# --- Synthesis-page composition helpers (used by knowledge-finalize) ---------
# These are the intricate, regression-prone transforms knowledge-finalize runs
# when it deposits a synthesis page: pulling a source URL out of frontmatter,
# rendering a safe markdown link destination, stripping the composer's own
# reference section, and renumbering the body's inline citation markers. They
# live here (not inline in the SKILL heredoc) so they are unit-testable.

# Matches an inline numbered citation marker's `<sup>[N]` prefix. The trailing
# `(url)</sup>` (or bare `</sup>` for a synthesis citation) is intentionally
# NOT captured — renumbering rewrites only the number.
_SUP_CITATION_RE = re.compile(r"<sup>\[(\d+)\]")

# Matches a WHOLE inline citation marker — `<sup>[N](url)</sup>` or the bare
# `<sup>[N]</sup>` synthesis form. `[^<]*` covers the `(url)` (URLs carry no `<`).
_SUP_MARKER_RE = re.compile(r"<sup>\[\d+\][^<]*</sup>")


def strip_inline_citation_markers(text: str) -> str:
    """Remove every inline `<sup>[N](url)</sup>` / `<sup>[N]</sup>` marker, leaving
    the surrounding prose. Used to compare a draft sentence's actual text against a
    source claim without the citation markers getting in the way."""
    return _SUP_MARKER_RE.sub("", text)


def first_url(fm_value: str) -> str:
    """First http(s) URL in a frontmatter `sources:` value, else "".

    A source page carries the inline-list shape `["<URL>"]`; a synthesis page
    carries a block-style `sources:` (its `wiki://…` entries live on indented
    lines that the top-level frontmatter parse never surfaces), so this returns
    "" for synthesis pages — correctly, they have no external URL.
    """
    if not fm_value:
        return ""
    try:
        parsed = json.loads(fm_value)
        if isinstance(parsed, list) and parsed and isinstance(parsed[0], str):
            parsed = parsed[0]
        if isinstance(parsed, str) and parsed.startswith(("http://", "https://")):
            return parsed
    except (ValueError, TypeError):
        pass
    # Fallback only (non-JSON value). Strip trailing quotes and at most one
    # leaked list-closer `]` — NOT a whole `]"'` charset, which would also eat a
    # URL legitimately ending in `]`.
    m = re.search(r"https?://\S+", fm_value)
    if not m:
        return ""
    url = m.group(0).rstrip("\"'")
    return url[:-1] if url.endswith("]") else url


def md_link_dest(url: str) -> str:
    """Markdown link destination for `url`, angle-bracketed when needed.

    A raw URL containing `(`/`)`/space truncates at the first `)` in many
    renderers (Obsidian included), breaking the citation link. CommonMark allows
    an angle-bracketed destination `<url>` for exactly this — except it forbids
    `<`/`>` inside, so fall back to the bare URL if those appear (vanishingly
    rare in an http URL).
    """
    if ("(" in url or ")" in url or " " in url) and "<" not in url and ">" not in url:
        return "<" + url + ">"
    return url


def strip_reference_section(body: str, heading: str) -> str:
    """Remove the composer's trailing reference section from a draft body.

    `knowledge-finalize` re-composes a canonical numbered reference list, so the
    composer's own section must be stripped first to avoid depositing two. The
    strip is LANGUAGE-INDEPENDENT: it matches the localized `heading` AND the
    English `References` (covers a mixed-state draft), anchored on
    `(?:\\A|\\n)…(?:\\n|\\Z)` so the heading is found even as the first/last line
    of `body` (a bare `\\n##…\\n` would miss both — the #301 duplicate bug).
    Strips from the LAST such heading to EOF.

    Safety net (no recognized heading — composer used a synonym like
    `## Quellen`): strip the last H2 ONLY when its whole body is a genuine
    reference list, i.e. every non-blank line is a wikilink entry
    (`[[sources/` / `[[syntheses/`) or a numbered `**[N]**` entry. A generic
    trailing bullet list (Recommendations / Conclusions) is NOT a reference list
    and is preserved — stripping it was silent content loss.
    """
    strip_words = [heading] + ([] if heading == "References" else ["References"])
    ref_re = re.compile(
        r"(?:\A|\n)##[ \t]+(?:" + "|".join(re.escape(w) for w in strip_words) + r")[ \t]*(?:\n|\Z)",
        re.IGNORECASE,
    )
    matches = list(ref_re.finditer(body))
    if matches:
        return body[: matches[-1].start()]
    h2s = list(re.finditer(r"(?:\A|\n)##[ \t]+.*(?:\n|\Z)", body))
    if h2s:
        tail = body[h2s[-1].end():]
        tail_lines = [ln.strip() for ln in tail.splitlines() if ln.strip()]
        if tail_lines and all(
            ("[[sources/" in ln) or ("[[syntheses/" in ln) or ln.startswith("**[")
            for ln in tail_lines
        ):
            return body[: h2s[-1].start()]
    return body


def renumber_inline_citations(body: str) -> str:
    """Remap the body's inline `<sup>[N]` markers to a contiguous 1..K.

    The composer numbers markers in first-appearance order; a revisor that drops
    every citation of one source leaves a gap (body keeps `[1][3]` while the
    re-derived reference list re-packs to `[1][2]`). Remap by the MARKER NUMBER
    itself (ascending == first-appearance == cited-slug order), NOT by URL: this
    is robust to two slugs sharing one URL, to URL normalization drift, and to
    synthesis markers that carry no URL. Rewrites only the `<sup>[N]` prefix; any
    trailing `(url)</sup>` is untouched. A no-op when markers are already
    contiguous (the common case).
    """
    present = sorted({int(m.group(1)) for m in _SUP_CITATION_RE.finditer(body)})
    if present and present != list(range(1, len(present) + 1)):
        remap = {old: new for new, old in enumerate(present, start=1)}
        body = _SUP_CITATION_RE.sub(
            lambda m: "<sup>[" + str(remap[int(m.group(1))]) + "]", body
        )
    return body


# --- pre_extracted_claims block-list parser (used by verify-store.py prefilter) -
# `pre_extracted_claims:` is a nested YAML block-list of dicts whose
# `text` / `excerpt_quote` values are free text (colons, quotes, commas). The
# flat-scalar frontmatter parsers elsewhere in the monorepo
# (`cycle-guard.py::_parse_frontmatter`, cogni-wiki's `_wikilib.parse_frontmatter`)
# cannot reconstruct it, and this package is stdlib-only (no PyYAML). So this is a
# narrow, FAIL-SAFE extractor: it pulls only `{id, text, excerpt_quote}` per item
# and silently skips anything it cannot confidently parse. The single consumer
# (the verify prefilter) only ever uses a successful parse to ADD a `verbatim`
# verdict it is certain of; a parse miss simply leaves the citation for the LLM
# verifier. Correctness is therefore independent of this parser's completeness.
# The same parser (`_parse_claim_block`) also backs `parse_distilled_claims` for
# the `distilled_claims:` block on concept/entity pages — there only the `text`
# field is wanted, because the coverage scorer (its single outside reader) does not
# need the writer-side metadata that concept-store.py keeps private.

_FRONTMATTER_RE = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", re.DOTALL)
_CLAIMS_KEY_RE = re.compile(r"^pre_extracted_claims[ \t]*:[ \t]*$")
_WANTED_CLAIM_KEYS = ("id", "text", "excerpt_quote")
# concept/entity pages (written by concept-store.py) carry `distilled_claims:`
# instead — the coverage scorer reads only `text` from it (see parse_distilled_claims).
_DISTILLED_KEY_RE = re.compile(r"^distilled_claims[ \t]*:[ \t]*$")
_DISTILLED_WANTED_KEYS = ("text",)
# A YAML block-scalar header: `|` / `>` with an optional indent digit and/or
# chomping indicator (`-`/`+`). The actual text lives on the following indented
# lines, which this single-line parser does not assemble.
_BLOCK_SCALAR_RE = re.compile(r"^[|>][0-9]*[+-]?$")


def _unquote_scalar(v: str) -> str:
    """Best-effort YAML scalar unquoting. A value that is not cleanly quoted
    (e.g. a quoted string whose close-quote is on a later line) is returned
    as-is — it simply won't substring-match downstream, which is the safe
    outcome."""
    if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
        # The source-ingester writes these via json.dumps(…, ensure_ascii=False),
        # so json.loads is the correct, complete decoder (handles \n, \t, \", \\,
        # \uXXXX). Fall back to a minimal manual unescape for a value that is
        # double-quoted but not valid JSON.
        try:
            decoded = json.loads(v)
            if isinstance(decoded, str):
                return decoded
        except ValueError:
            pass
        return v[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    if len(v) >= 2 and v[0] == "'" and v[-1] == "'":
        return v[1:-1].replace("''", "'")
    return v


def _absorb_claim_kv(item: dict, kv: str, wanted_keys: tuple) -> None:
    if ":" not in kv:
        return
    key, _, value = kv.partition(":")  # first colon only — free-text values may contain ':'
    key = key.strip()
    if key not in wanted_keys:
        return
    value = value.strip()
    # A block-scalar header (`|` / `>`) is NOT a value — capturing the bare
    # indicator would yield a 1-char needle (`>` / `|`) that substring-matches
    # almost any draft sentence (every IEEE marker contains `>`). Skip the field
    # so the claim simply lacks it → the prefilter falls through to the LLM,
    # never a wrong `verbatim`.
    if _BLOCK_SCALAR_RE.match(value):
        return
    # Strip a YAML inline comment from an UNQUOTED plain scalar (a comment needs
    # leading whitespace before `#`). Quoted values keep `#` verbatim.
    if value[:1] not in ('"', "'"):
        hash_pos = value.find(" #")
        if hash_pos != -1:
            value = value[:hash_pos].rstrip()
    item[key] = _unquote_scalar(value)


def _parse_claim_block(page_text: str, key_re, wanted_keys: tuple) -> list[dict]:
    """Single-line YAML block-list parser shared by `parse_pre_extracted_claims`
    (`pre_extracted_claims:`) and `parse_distilled_claims` (`distilled_claims:`).
    Walks the frontmatter for `key_re`, reads the run of blank / indented / bullet
    lines after it, and absorbs only `wanted_keys` per `- ` item. Returns [] for any
    page without a parseable block. Tolerant of indent width, of the first key
    sitting inline after the `- ` bullet, and of block sequences whose `- ` bullets
    sit at the parent key's column; only single-line `key: value` scalars are read."""
    if not page_text:
        return []
    m = _FRONTMATTER_RE.match(page_text)
    if not m:
        return []
    lines = m.group(1).splitlines()
    start = None
    for i, line in enumerate(lines):
        if key_re.match(line):
            start = i + 1
            break
    if start is None:
        return []
    # The block is the run of blank / indented / bullet lines after the key, up
    # to the next top-level key. Bullet lines (`- …`) are included even at
    # column 0 — a YAML block sequence may sit at the parent key's indent.
    block: list[str] = []
    for line in lines[start:]:
        stripped = line.strip()
        if stripped == "" or line[:1] in (" ", "\t") or stripped == "-" or stripped.startswith("- "):
            block.append(line)
        else:
            break
    claims: list[dict] = []
    current: dict | None = None
    for line in block:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped == "-" or stripped.startswith("- "):
            if current is not None:
                claims.append(current)
            current = {}
            rest = stripped[1:].strip()
            if rest:
                _absorb_claim_kv(current, rest, wanted_keys)
        elif current is not None:
            _absorb_claim_kv(current, stripped, wanted_keys)
    if current is not None:
        claims.append(current)
    return claims


def parse_pre_extracted_claims(page_text: str) -> list[dict]:
    """Extract `[{id, text, excerpt_quote}, …]` from a wiki page's
    `pre_extracted_claims:` frontmatter block (source/synthesis pages). Returns []
    for any page without a parseable block."""
    return _parse_claim_block(page_text, _CLAIMS_KEY_RE, _WANTED_CLAIM_KEYS)


def parse_distilled_claims(page_text: str) -> list[dict]:
    """Extract `[{text}, …]` from a wiki page's `distilled_claims:` frontmatter
    block (concept/entity pages, written by concept-store.py). Only `text` is
    absorbed; the writer-side metadata (claim_id / norm_key / backlinks /
    source_claim_refs / dates) is concept-store-private and ignored here. Returns []
    for any page without a parseable block — including the inline `distilled_claims:
    []` empty form, which `_DISTILLED_KEY_RE` (key-on-its-own-line) deliberately does
    not match."""
    return _parse_claim_block(page_text, _DISTILLED_KEY_RE, _DISTILLED_WANTED_KEYS)


# --- Tokenization + token weighting (shared by wiki-coverage.py and -----------
# concept-store.py) ------------------------------------------------------------
# Lifted verbatim from wiki-coverage.py (#326/#331) so the read-before-web
# coverage scorer and the Phase-4.5 claim-dedup engine share ONE normalization
# source of truth. `wiki-coverage.py` imports `tokenize` / `token_weight` /
# `compound_match` / `GENERIC_DENYLIST` / `STOPWORDS` from here; `concept-store.py`
# builds `norm_key` + `claim_similarity` on the same primitives. See
# wiki-coverage.py's module docstring for the full rationale behind each tuning
# choice (digit anchors x3.0, regulatory-boilerplate denylist, German-compound
# prefix matching). When editing these, `tests/test_wiki_coverage_bilingual.sh`
# is the regression guard.

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

    NFD, NOT NFKD (which `slugify` uses): NFKD *compatibility* decomposition
    fabricates ASCII digits from typographic glyphs (`½` → `1` `2`, superscript
    `²` → `2`, fullwidth `９` → `9`), which `tokenize` would then keep as
    pure-numeric tokens and weight ×3.0 as article-number anchors — a typographic
    footnote marker or fraction in a page's claim text would inject a spurious
    cross-lingual anchor and falsely cover an unrelated sub-question. NFD's
    *canonical* decomposition still de-accents every supported-market letter
    (é→e, ñ→n, Polish ł handled by the manual map) but leaves ½/²/№ intact so the
    `[a-z0-9]` split discards them."""
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
    side never match (#326). Symmetric: `_common_prefix_len` and every guard are
    order-independent, so `compound_match(a, b) == compound_match(b, a)` — which
    is what lets `claim_similarity` reuse it for a symmetric measure."""
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


# --- Claim-level dedup (Finding H, #336) — symmetric, deterministic -----------
# concept-store.py decides "do two claims assert the same fact?" — NEVER the LLM.
# Two-stage predicate: an exact `norm_key` match (fast path), then a symmetric
# weighted-Jaccard `claim_similarity` >= threshold. Fail-safe = keep both when
# uncertain (a wrong merge silently destroys a distinct fact and is
# unrecoverable; a missed merge is a visible, measurable duplicate). Built on the
# same tokenization primitives above so dedup and coverage normalize identically.


def norm_key(text: str) -> str:
    """Deterministic exact-dedup key: the discriminative (weight > 0) token set,
    sorted and space-joined. Two claim texts with the SAME non-empty norm_key
    assert the same fact (the cheap exact path before `claim_similarity`).

    Denylisted/boilerplate tokens are dropped (they carry no discriminative
    signal), so two claims differing only in regulatory boilerplate collapse to
    the same key. An all-boilerplate / empty claim yields `""` — callers MUST
    treat an empty key as "no exact match" (never merge two empty keys), or
    distinct all-boilerplate claims would false-merge."""
    toks = sorted(t for t in tokenize(text) if token_weight(t) > 0.0)
    return " ".join(toks)


def claim_similarity(a: str, b: str) -> float:
    """Symmetric weighted-Jaccard similarity of two claim texts in [0.0, 1.0].

    Intersection-weight / union-weight over `token_weight`, with `compound_match`
    handling German compounds. This is the NEAR-match half of the dedup
    predicate (the exact half is `norm_key`). It is deliberately **symmetric** —
    NOT `wiki-coverage.py::coverage_score`, which is *directional recall* (page
    coverage of a sub-question). Returns 0.0 when either side has no
    discriminative token (an all-boilerplate claim), the safe "keep both"
    direction. A score >= the caller's threshold inherently requires >= 1 shared
    discriminative token, so it already encodes the "shared content token" gate."""
    ta = {t for t in tokenize(a) if token_weight(t) > 0.0}
    tb = {t for t in tokenize(b) if token_weight(t) > 0.0}
    if not ta or not tb:
        return 0.0
    wa = sum(token_weight(t) for t in ta)
    wb = sum(token_weight(t) for t in tb)
    matched_a = [t for t in ta if any(compound_match(t, p) for p in tb)]
    matched_b = [p for p in tb if any(compound_match(t, p) for t in ta)]
    # Average the two sides' matched weight — for exact matches the two sums are
    # equal, so this reduces to the standard weighted Jaccard; for compound hits
    # the matched tokens differ in length (hence weight) on each side, and the
    # average keeps the measure symmetric (claim_similarity(a, b) == (b, a)).
    inter = (sum(token_weight(t) for t in matched_a)
             + sum(token_weight(p) for p in matched_b)) / 2.0
    union = wa + wb - inter
    if union <= 0.0:
        return 0.0
    return inter / union


# --- concept-records parser (used by concept-store.py / knowledge-distill) -----
# The `concept-distiller` agent has no Bash and MUST NOT hand-build JSON/YAML
# (same #325 constraint as wiki-composer). It writes raw-text concept records;
# `concept-store.py` parses them via this function and owns all serialization.
# Format mirrors `parse_citation_records` — a labeled, line-oriented block list,
# one `- title:` bullet per concept/entity, with repeatable `claim:` lines. The
# `type` line is `concept` | `entity`; `claim:` value is
# `<source_slug>#<claim_id> | <claim text>`.


def _absorb_concept_kv(item: dict, kv: str) -> None:
    if ":" not in kv:
        return
    key, _, value = kv.partition(":")  # first colon only — summaries/claims contain ':'
    key = key.strip().lower()
    value = value.strip()
    if key == "title":
        item["title"] = value
    elif key == "type":
        item["type"] = value.lower()
    elif key == "summary":
        item["summary"] = value
    elif key == "related":
        item["related"] = [r.strip() for r in value.split(",") if r.strip()]
    elif key == "claim":
        # Provenance + text. Two accepted forms, disambiguated by whether the
        # FIRST `|`-segment carries a `#` (slugs/claim-ids never contain `#`, so
        # its presence unambiguously marks the ref form). We split on `#`/`|`
        # positionally — NOT `split("|", 2)` — so a claim text containing ` | `
        # (common in regulatory prose: "Article 6 | paragraph 2") is preserved
        # verbatim in BOTH forms rather than mis-split into the provenance fields.
        #   `<source_slug>#<claim_id> | <text…>`     (2-part ref form)
        #   `<source_slug> | <claim_id> | <text…>`   (documented 3-part form)
        first, sep, rest = value.partition("|")
        if "#" in first:
            src_slug, _, cid = first.partition("#")
            ctext = rest if sep else ""
        else:
            src_slug = first
            cid_part, sep2, ctext = rest.partition("|")
            cid = cid_part
            if not sep2:
                ctext = ""  # only one `|` and no `#` → no text field → reject downstream
        item["claims"].append({
            "source_slug": src_slug.strip(),
            "source_claim_id": cid.strip(),
            "text": ctext.strip(),
        })
    # Unknown keys (e.g. the advisory `update:` flag) are ignored — the
    # created-vs-updated decision is made on-disk under the lock, not here.


def parse_concept_records(text: str) -> list[dict]:
    """Parse a concept-distiller records file into a list of
    `{title, type, summary, related[], claims[]}` dicts (each claim
    `{source_slug, source_claim_id, text}`). A `- ` bullet starts a record; the
    first field may sit inline after the bullet. Repeatable `claim:` lines
    accumulate. Blank and `#`-comment lines are skipped. Indent-tolerant. A
    record missing its `title:` is emitted with an empty title (NOT dropped) so
    `concept-store.py` can surface it rather than silently lose a concept."""
    records: list[dict] = []
    current: dict | None = None
    for raw in (text or "").split("\n"):
        if raw.endswith("\r"):
            raw = raw[:-1]
        lstripped = raw.lstrip()
        if not lstripped or lstripped.startswith("#"):
            continue
        if lstripped == "-" or lstripped.startswith("- "):
            if current is not None:
                records.append(current)
            current = {"title": "", "type": "", "summary": "", "related": [], "claims": []}
            rest = lstripped[1:].strip()
            if rest:
                _absorb_concept_kv(current, rest)
        elif current is not None:
            _absorb_concept_kv(current, lstripped)
    if current is not None:
        records.append(current)
    return records


# --- citation-records parser (used by citation-store.py build) ----------------
# wiki-composer has no Bash and cannot run a JSON serializer, so it MUST NOT
# hand-build citation-manifest.json — a draft_sentence with a straight `"`
# (routine in German/FR/IT/ES/PL prose) broke json.loads downstream and killed
# the verify→finalize tail (#325). Instead the composer writes citation RECORDS
# as raw text through the byte-safe `Write` channel, and `citation-store.py build`
# json.dumps the manifest. This parser reads that records file. The format is a
# labeled, line-oriented block list — deliberately the same idiom the composer
# already authors for `pre_extracted_claims:` frontmatter, so no new authoring
# format is introduced and the LLM never emits JSON or escapes a quote.

# Short keys are the documented authoring form; the long aliases are accepted
# defensively because the composer also sees the manifest field names
# (draft_position / wiki_slug / claim_id / draft_sentence) in the same step and
# could conflate the two — "be liberal in what you accept".
_CITATION_RECORD_KEYS = {
    "id": "id",
    "pos": "draft_position",
    "draft_position": "draft_position",
    "slug": "wiki_slug",
    "wiki_slug": "wiki_slug",
    "claim": "claim_id",
    "claim_id": "claim_id",
    "sentence": "draft_sentence",
    "draft_sentence": "draft_sentence",
}


def _absorb_citation_kv(item: dict, kv: str) -> None:
    if ":" not in kv:
        return
    key, _, value = kv.partition(":")  # first colon only — sentences contain ':'
    field = _CITATION_RECORD_KEYS.get(key.strip())
    if field is None:
        return
    if field == "draft_sentence":
        # Strip the conventional leading space(s) after the colon — a prose
        # sentence never begins with a space, so this stays byte-exact while
        # forgiving an extra space. No trailing strip — preserve verbatim.
        item[field] = value.lstrip(" ")
    else:
        item[field] = value.strip()


def _finalize_citation_record(item: dict) -> dict:
    claim = item.get("claim_id")
    claim_id = None if claim in (None, "", "null") else claim
    return {
        "id": item.get("id", ""),
        "draft_position": item.get("draft_position", ""),
        "draft_sentence": item.get("draft_sentence", ""),
        "wiki_slug": item.get("wiki_slug", ""),
        "claim_id": claim_id,
    }


def parse_citation_records(text: str) -> list[dict]:
    """Parse a wiki-composer citation-records file into a list of
    `{id, draft_position, draft_sentence, wiki_slug, claim_id}` dicts.

    Each record is a `- id:` bullet followed by `pos:` / `slug:` / `claim:` /
    `sentence:` lines (indent-tolerant). `sentence` is the LAST field and its
    value is the rest of the line VERBATIM — raw text (quotes, backslashes,
    colons, Unicode) passes through unescaped; `citation-store.py build` then
    `json.dumps` it, so escaping is owned by the serializer, never the agent.
    `claim` literal `null`/empty → None (synthesis citations). Blank and
    `#`-comment lines are skipped. draft_sentence is assumed single-line — the
    same invariant the verifier's `draft_sentence in draft` check already relies
    on. Lines are split on `\\n` only (NOT `str.splitlines()`, which also breaks
    on U+2028/U+2029/NEL/VT/FF and would truncate a sentence that contains one);
    a trailing `\\r` from CRLF is stripped (though `Path.read_text` normally
    normalizes it before this runs).

    A `-` bullet block missing its `id:` line is emitted with an empty id (NOT
    silently dropped), so `citation-store.py build`'s empty-id guard surfaces it
    as `write_failed` instead of losing a citation with `success: true`."""
    records: list[dict] = []
    current: dict | None = None
    for raw in (text or "").split("\n"):
        if raw.endswith("\r"):
            raw = raw[:-1]
        lstripped = raw.lstrip()
        if not lstripped or lstripped.startswith("#"):
            continue
        if lstripped == "-" or lstripped.startswith("- "):
            if current is not None:
                records.append(_finalize_citation_record(current))
            current = {}
            rest = lstripped[1:].strip()
            if rest:
                _absorb_citation_kv(current, rest)
        elif current is not None:
            _absorb_citation_kv(current, lstripped)
    if current is not None:
        records.append(_finalize_citation_record(current))
    return records


def is_pdf_response(content_type: str | None, url: str) -> bool:
    """True if a fetched response looks like a PDF.

    Pure detection — no I/O. Two signals are accepted (either triggers
    the PDF branch in source-fetcher Step 2):
      - Content-Type starts with `application/pdf` (case-insensitive,
        allows `;` parameters such as `application/pdf; charset=binary`).
      - Normalised URL path ends with `.pdf` (case-insensitive).

    The URL suffix path covers WebFetch responses that don't surface a
    Content-Type header (the saved-binary line is the only signal in
    that case). The MIME path covers servers that respond `200 OK` with
    `application/pdf` against a `.html`-suffixed URL (rare but real on
    some EU portals).
    """
    if content_type:
        if content_type.strip().lower().split(";", 1)[0].strip() == "application/pdf":
            return True
    if not url or not url.strip():
        return False
    parts = urlsplit(normalize_url(url))
    return parts.path.lower().endswith(".pdf")


# ---------------------------------------------------------------------------
# Research-time gap streaming (#354) — read <project>/.metadata/wiki-coverage.json
# and turn `uncovered`/`partial` sub-questions into open_questions.md findings.
# ---------------------------------------------------------------------------

# A sub-question id must be regex-safe: it ends up inside a backtick-quoted
# token (`sq:<sq_id>`) in open_questions.md and inside the `sqs=` log-line
# suffix. knowledge-plan always emits `sq-01`, `sq-02`, … — anything that
# does not match this shape is dropped defensively (R6).
_SQ_ID_RE = re.compile(r"^[\w\-]+$")

# verdict → open_questions.md tracked class.
_COVERAGE_GAP_CLASS = {
    "uncovered": "research_uncovered",
    "partial": "research_partial",
}


def _read_metadata_json(project_path, name: str) -> dict:
    """Read `<project_path>/.metadata/<name>`; return {} on any failure."""
    p = Path(project_path) / ".metadata" / name
    if not p.is_file():
        return {}
    try:
        obj = json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return obj if isinstance(obj, dict) else {}


def _coverage_sub_questions(project_path) -> list:
    """Return wiki-coverage.json's `data.sub_questions[]` (or [] on any failure)."""
    cov = _read_metadata_json(project_path, "wiki-coverage.json")
    data = cov.get("data") if isinstance(cov.get("data"), dict) else {}
    sqs = data.get("sub_questions")
    return sqs if isinstance(sqs, list) else []


def _sanitize_gap_message(msg: str) -> str:
    """Collapse whitespace and strip characters that would break the
    open_questions.md line regexes (backticks delimit the id; `~~` wraps a
    closed line)."""
    msg = " ".join(str(msg).split())
    return msg.replace("`", "").replace("~~", "")


def _plan_message_index(project_path) -> dict:
    """Map plan.json sub-question id → a one-line gap message.

    plan.json keys sub-questions by `id` (e.g. `sq-04`); wiki-coverage.json
    keys them by `sq_id`. They share the same value, so this index joins the
    two. Message = "<theme_label> — <query truncated>".
    """
    plan = _read_metadata_json(project_path, "plan.json")
    out: dict = {}
    sqs = plan.get("sub_questions")
    if not isinstance(sqs, list):
        return out
    for sq in sqs:
        if not isinstance(sq, dict):
            continue
        sid = str(sq.get("id", ""))
        if not sid:
            continue
        theme = str(sq.get("theme_label", "")).strip()
        query = str(sq.get("query", "")).strip()
        if len(query) > 140:
            query = query[:139].rstrip() + "…"
        if theme and query:
            msg = f"{theme} — {query}"
        else:
            msg = theme or query
        out[sid] = _sanitize_gap_message(msg)
    return out


def _iter_coverage_gaps(project_path):
    """Yield `(sq_id, verdict)` for every regex-safe sub-question scored a gap
    (`uncovered`/`partial`) in `<project>/.metadata/wiki-coverage.json`, in
    coverage-manifest order. The single source of truth for the gap filter +
    sq_id validation shared by the two public helpers below."""
    for sq in _coverage_sub_questions(project_path):
        if not isinstance(sq, dict):
            continue
        verdict = sq.get("coverage_verdict")
        if verdict not in _COVERAGE_GAP_CLASS:
            continue
        sid = str(sq.get("sq_id", ""))
        if sid and _SQ_ID_RE.match(sid):
            yield sid, verdict


def gap_sq_ids_from_coverage(project_path) -> list:
    """Bare `sq_id` list (no `sq:` prefix) for sub-questions scored
    `uncovered`/`partial` in `<project>/.metadata/wiki-coverage.json`.

    Used by knowledge-finalize Step 10 to build the `sqs=sq-01,sq-04` suffix on
    the `wiki/log.md` finalize line. Preserves coverage-manifest order. Returns
    [] when the manifest is absent/malformed (degraded but valid). Ids that are
    not regex-safe are dropped.
    """
    return [sid for sid, _ in _iter_coverage_gaps(project_path)]


def load_wiki_coverage_findings(project_path) -> list:
    """Turn research-time gaps into open_questions.md `--findings -` entries.

    Reads `<project>/.metadata/wiki-coverage.json`; for each sub-question scored
    `uncovered`/`partial`, emits
    `{"class": "research_uncovered"|"research_partial", "id": "sq:<sq_id>",
      "message": "<theme_label> — <query>"}`. The message text is read from
    plan.json (wiki-coverage.json carries only sq_id + verdict); falls back to a
    bare `sub-question <sq_id> (<verdict>)` when plan.json is missing.

    Returns [] on a missing/malformed coverage manifest (fail-soft, matching the
    SKILL's posture). Regex-unsafe sq_ids are dropped.
    """
    messages = _plan_message_index(project_path)
    out = []
    for sid, verdict in _iter_coverage_gaps(project_path):
        msg = messages.get(sid) or f"sub-question {sid} ({verdict})"
        out.append({"class": _COVERAGE_GAP_CLASS[verdict], "id": f"sq:{sid}", "message": msg})
    return out
