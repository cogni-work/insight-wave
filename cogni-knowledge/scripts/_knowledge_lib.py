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
