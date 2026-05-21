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
import tempfile
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


def atomic_write(path: Path, payload: dict) -> Path:
    """Atomically write `payload` as pretty-printed JSON to `path`.

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
            json.dump(payload, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    return path


def atomic_write_text(path: Path, text: str) -> Path:
    """Atomically write `text` as a UTF-8 file to `path`.

    Sibling of `atomic_write` for non-JSON payloads (markdown pages, log
    entries written by a single writer). Same tempfile+os.replace pattern;
    kept separate so the three-way identity invariant on `atomic_write`
    (asserted by tests/test_knowledge_lib.sh) is undisturbed by markdown
    consumers.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(text)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    return path


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
