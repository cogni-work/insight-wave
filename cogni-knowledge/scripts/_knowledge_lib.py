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

_FRONTMATTER_RE = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", re.DOTALL)
_CLAIMS_KEY_RE = re.compile(r"^pre_extracted_claims[ \t]*:[ \t]*$")
_WANTED_CLAIM_KEYS = ("id", "text", "excerpt_quote")
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


def _absorb_claim_kv(item: dict, kv: str) -> None:
    if ":" not in kv:
        return
    key, _, value = kv.partition(":")  # first colon only — free-text values may contain ':'
    key = key.strip()
    if key not in _WANTED_CLAIM_KEYS:
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


def parse_pre_extracted_claims(page_text: str) -> list[dict]:
    """Extract `[{id, text, excerpt_quote}, …]` from a wiki page's
    `pre_extracted_claims:` frontmatter block. Returns [] for any page without a
    parseable block. Tolerant of indent width, of the first key sitting inline
    after the `- ` bullet, and of block sequences whose `- ` bullets sit at the
    same column as the parent key; only single-line `key: value` scalars are
    read."""
    if not page_text:
        return []
    m = _FRONTMATTER_RE.match(page_text)
    if not m:
        return []
    lines = m.group(1).splitlines()
    start = None
    for i, line in enumerate(lines):
        if _CLAIMS_KEY_RE.match(line):
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
                _absorb_claim_kv(current, rest)
        elif current is not None:
            _absorb_claim_kv(current, stripped)
    if current is not None:
        claims.append(current)
    return claims


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
