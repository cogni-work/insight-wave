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
from typing import NamedTuple
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


# ---------------------------------------------------------------------------
# Control-file path indirection (curated wiki-output layout, schema 0.0.8).
#
# The three wiki control files (`log.md`, `context_brief.md`,
# `open_questions.md`) are migrating from the flat `wiki/` root into a
# `wiki/meta/` subtree. Routing every cogni-knowledge reader/writer through
# these helpers makes that relocation a one-line change here instead of a
# call-site sweep.
#
# Resolution rule: prefer `wiki/meta/<file>` when it exists; an existing
# legacy flat `wiki/<file>` still resolves; a file absent from both layouts
# defaults to `wiki/meta/` (the canonical location). The vendored cogni-wiki
# readers/writers carry a matching self-contained meta-first fallback, so the
# CK side and the vendored side always agree on one path per file.
# ---------------------------------------------------------------------------

# True: `wiki/meta/` is the canonical control-file location. Resolution
# prefers `wiki/meta/<file>`; an EXISTING legacy flat `wiki/<file>` still
# resolves (so pre-migration bases keep working, read AND write); a file
# absent from both layouts defaults to `wiki/meta/` — the canonical target
# for anything newly created. The vendored readers/writers carry a matching
# self-contained meta-first fallback, so the two sides cannot desync.
_CANONICAL_META = True

_CONTROL_FILES = {
    "log": "log.md",
    "context-brief": "context_brief.md",
    "open-questions": "open_questions.md",
}


def meta_dir(wiki_root) -> Path:
    """The curated control-file directory: `<wiki_root>/wiki/meta`."""
    return Path(wiki_root) / "wiki" / "meta"


def _resolve_control_path(wiki_root, name: str) -> Path:
    """Resolve a control file's path under `wiki_root`.

    `name` is one of `_CONTROL_FILES`' keys (`log`, `context-brief`,
    `open-questions`). Prefers `wiki/meta/<file>` when it exists on disk; an
    EXISTING legacy flat `wiki/<file>` still resolves (pre-migration bases keep
    working); with `_CANONICAL_META` flipped, a file absent from both layouts
    defaults to `wiki/meta/<file>` (the canonical target for new files) instead
    of the legacy flat path. Path-only — never creates, opens, or locks the
    file.
    """
    if name not in _CONTROL_FILES:
        raise ValueError(f"unknown control file: {name!r}")
    filename = _CONTROL_FILES[name]
    root = Path(wiki_root)
    meta_candidate = root / "wiki" / "meta" / filename
    if meta_candidate.exists():
        return meta_candidate
    flat_candidate = root / "wiki" / filename
    if _CANONICAL_META and not flat_candidate.exists():
        return meta_candidate
    return flat_candidate


def log_path(wiki_root) -> Path:
    """Resolved path to the wiki activity log (`log.md`)."""
    return _resolve_control_path(wiki_root, "log")


def context_brief_path(wiki_root) -> Path:
    """Resolved path to the orientation brief (`context_brief.md`)."""
    return _resolve_control_path(wiki_root, "context-brief")


def open_questions_path(wiki_root) -> Path:
    """Resolved path to the open-questions register (`open_questions.md`)."""
    return _resolve_control_path(wiki_root, "open-questions")


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


# --- Writer-quality knob validation (#309 P2) ---------------------------------
# The four knobs (prose_density / tone / citation_format / target_words) are
# resolved LLM-side in knowledge-plan Step 0.5 and threaded to wiki-composer /
# wiki-reviewer. These normalizers keep the resolution precedence robust to a
# malformed binding default or a typo'd flag — a bad value never reaches the
# composer, it falls through to the safe default. Single source of truth so the
# skill prose and any future script agree byte-for-byte. Kept here (not in the
# skill markdown) so they are unit-testable in tests/test_knowledge_lib.sh.

# The 15-tone catalog from references/writing-tones.md, default `objective`.
VALID_TONES = frozenset({
    "objective", "formal", "analytical", "persuasive", "informative",
    "explanatory", "descriptive", "critical", "comparative", "speculative",
    "narrative", "optimistic", "simple", "casual", "executive",
})

# Prose-density modes (references/absorption-roadmap.md #309 P2; mirrors
# cogni-research writer.md). `standard` treats target_words as a floor;
# `executive` as a ceiling with BLUF + Pyramid + one-citation-per-claim.
VALID_PROSE_DENSITIES = frozenset({"standard", "executive"})

# Citation formats from references/citation-formats.md. `ieee` / `chicago` are
# wired end-to-end (both render the numbered `<sup>[N](url)</sup>` inline shape,
# differing only in the reference-list string); `apa` / `mla` / `harvard` are
# the staged author-date follow-up (parsed + accepted here so a base can persist
# the choice, but the composer falls back to numbered rendering until the
# format-aware finalize rework lands). `wikilink` is the deprecated alias for
# `ieee`. Default `ieee`.
VALID_CITATION_FORMATS = frozenset({
    "ieee", "chicago", "apa", "mla", "harvard",
})

# Citation family — numbered (superscript `<sup>[N](url)</sup>`, renumber-safe in
# finalize) vs author_date (`([Author, Year](url))`, NOT yet wired into finalize's
# numbered renumber pass). The author_date branch is the named P2 follow-up.
CITATION_FAMILY = {
    "ieee": "numbered",
    "chicago": "numbered",
    "apa": "author_date",
    "mla": "author_date",
    "harvard": "author_date",
}


def _normalize_choice(value: str | None, valid: frozenset, default: str) -> str:
    """Lowercase + strip a free-text choice and validate it against `valid`;
    unknown/empty → `default`. The shared rule behind the writer-quality
    string normalizers below."""
    v = str(value or "").strip().lower()
    return v if v in valid else default


def normalize_tone(value: str | None) -> str:
    """Lowercase + validate a tone against VALID_TONES; unknown/empty → objective."""
    return _normalize_choice(value, VALID_TONES, "objective")


def normalize_prose_density(value: str | None) -> str:
    """Lowercase + validate a prose density; unknown/empty → executive."""
    return _normalize_choice(value, VALID_PROSE_DENSITIES, "executive")


def normalize_citation_format(value: str | None) -> str:
    """Lowercase + validate a citation format; `wikilink` aliases to `ieee`;
    unknown/empty → ieee (the numbered default the pipeline renders end-to-end).
    The alias is mapped explicitly so it survives any future change to the
    default or the valid set, even though `wikilink` would also fall through."""
    if str(value or "").strip().lower() == "wikilink":
        return "ieee"
    return _normalize_choice(value, VALID_CITATION_FORMATS, "ieee")


def normalize_target_words(value, default: int = 2000) -> int:
    """Coerce a target-word value to a positive int; non-positive/unparseable →
    `default`. Tolerates a string from a flag or a number from a binding/plan."""
    try:
        n = int(value)
    except (TypeError, ValueError):
        return default
    return n if n > 0 else default


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


# The http(s)/file:// link target inside a numbered inline marker
# `<sup>[N](url)</sup>`. Two shapes are emitted by the composer: a plain `(url)`
# and the angle-bracketed `(<url>)` that `md_link_dest` produces when the URL
# itself contains `(`/`)`/space. The alternation captures the bracketed form
# FIRST (so a URL legitimately containing `)` — the exact reason `md_link_dest`
# brackets it — is not truncated at that inner `)`); the unbracketed branch stops
# at the first `)`. `file:` is a first-class scheme alongside `http(s)` so a local
# source ingested via `knowledge-ingest-source --file` (provenance
# `file://<abspath>`) is extracted, not silently dropped; both branches match on
# `[^>]`/`[^)]`, so a `file://` path containing a literal space (e.g. a filename
# with a space) is captured whole instead of truncating at the space. A bare
# `<sup>[N]</sup>` marker (synthesis / distilled page, no external URL) has no
# `(...)` and matches neither branch → it contributes no URL.
_INLINE_CITATION_URL_RE = re.compile(
    r"<sup>\[\d+\]\((?:<((?:https?|file)://[^>]+)>|((?:https?|file)://[^)]+?))\)</sup>"
)


def extract_inline_citation_urls(text: str) -> list[str]:
    """Every http(s) or file:// URL inside a `<sup>[N](url)</sup>` inline citation
    marker in `text`, in appearance order (raw — the caller normalizes for
    comparison).

    Handles both the plain `(url)` and the angle-bracketed `(<url>)` forms, and
    treats `file:` as first-class (a local-file source carries `file://<abspath>`
    provenance, tolerated whole even when the path contains a literal space); a
    bare `<sup>[N]</sup>` marker (no external URL) contributes nothing. Used by
    `citation-store.py build`'s `--ingest-manifest` gate (#383) to assert every
    inline URL is a known ingested-source URL, catching a slug-derived URL the
    composer reconstructed instead of copying the cited page's `sources:` value."""
    if not text:
        return []
    return [a or b for a, b in _INLINE_CITATION_URL_RE.findall(text)]


def first_url(fm_value: str) -> str:
    """First http(s) or file:// URL in a frontmatter `sources:` value, else "".

    A source page carries the inline-list shape `["<URL>"]`; a synthesis page
    carries a block-style `sources:` (its `wiki://…` entries live on indented
    lines that the top-level frontmatter parse never surfaces), so this returns
    "" for synthesis pages — correctly, they have no external URL.

    `file:` is first-class: a local source ingested via
    `knowledge-ingest-source --file` is stored honestly as `file://<abspath>`,
    and the citation tooling that reads this (the source-ingester Phase-3
    integrity check via `extract_page_id_and_url`, the `ingest-integrity.py`
    sweep) must see the real URL, not "". A `file://` path may contain a literal
    space, so the non-JSON fallback below does not stop at whitespace for the
    `file:` scheme (it does for http(s), where a space never appears in a URL).
    """
    if not fm_value:
        return ""
    try:
        parsed = json.loads(fm_value)
        if isinstance(parsed, list) and parsed and isinstance(parsed[0], str):
            parsed = parsed[0]
        if isinstance(parsed, str) and parsed.startswith(
            ("http://", "https://", "file://")
        ):
            return parsed.strip()
    except (ValueError, TypeError):
        pass
    # Fallback only (non-JSON value). http(s) URLs never contain a space, so
    # `\S+` is right for them; a `file://` path can, so match the rest of the
    # value (sans a leaked closing quote / list-closer) and rstrip trailing
    # whitespace. Strip trailing quotes and at most one leaked list-closer `]` —
    # NOT a whole `]"'` charset, which would also eat a URL legitimately ending
    # in `]`.
    m = re.search(r"https?://\S+|file://[^\"'\]]+", fm_value)
    if not m:
        return ""
    url = m.group(0).rstrip().rstrip("\"'").rstrip()
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


def body_word_count(draft: str, lang: str | None) -> int:
    """Word count of a draft's BODY — the reference section excluded.

    The single canonical definition of the "body word" surface that both the
    `knowledge-compose` Step 7 executive over-ceiling warning and the `wiki-reviewer`
    advisory Word-Count Gate (executive excess + standard truncation check) measure:
    strip the localized reference section
    (`ref_heading(lang)` → `strip_reference_section`) and split on whitespace.
    Lives here (not inline in the skill markdown) so the gate's measured surface
    is unit-testable and the two gates can never drift on what "words" means.

    Section-heading tokens and inline `<sup>[N](url)</sup>` citation markers that
    survive the strip ARE counted by design — `.split()` is whitespace-only. That
    is a handful of words against the ~1.1k-word reference list this excludes, so
    the load-bearing surface (body vs. body+bibliography) is what stays aligned
    with the reviewer; do not assume byte-parity with the reviewer's per-section
    count.
    """
    return len(strip_reference_section(draft, ref_heading(lang)).split())


def coverage_report(plan: dict, ingest_manifest: dict, citation_manifest: dict) -> dict:
    """Per-sub-question coverage of the wiki's ingested evidence by the draft's citations.

    The deterministic signal behind `knowledge-compose` Step 5.5's coverage-gated
    expansion (replacing the retired word-floor `target × 0.85` trigger): a draft is
    "incomplete" not when it is short, but when a sub-question's ingested evidence holds
    sources the draft never cited. Pure stdlib, no I/O — the orchestrator reads the three
    `.metadata/` JSON files and passes the parsed dicts in, exactly as the Step 5.5
    `body_word_count` snippet does — so it is unit-testable in `tests/test_knowledge_lib.sh`.

    Inputs (all already on disk by Step 5):
      - `plan["sub_questions"]`            — each `{id, query, theme_label, …}` (the reference set).
      - `ingest_manifest["ingested"]`      — each `{slug, sub_question_refs[], …}` (evidence→sq map).
      - `citation_manifest["citations"]`   — each `{wiki_slug, …}` (what the draft actually cited).

    Returns, per sub-question id:
      `available` — ingested SOURCE slugs whose `sub_question_refs` include the sq;
      `cited`     — those that appear as a citation `wiki_slug` (available ∩ cited-slugs);
      `uncited`   — available − cited.
    plus `uncited_evidence_sq_ids` — the sq ids with ≥1 uncited available source (the
    expansion-eligible set: a real coverage deficit WITH evidence on hand to close it).

    Bias note (deliberate, fenced by the accept check): "cited" is a DIRECT source-slug
    intersection. A source whose claim was cited only *through* a distilled page or question
    node (keyed by a `dcl-`/`acl-` slug, never a source slug) is therefore counted as
    uncited — so on a compounding base the intersection can *under*-count real coverage and
    *over*-flag a sub-question as a deficit, firing one extra expansion for a sq already
    covered via aggregation. This is bounded and never ships padding: Step 5.5's citation-count
    accept check keeps `v{N+1}` only when the expansion adds a *new* grounded citation, so an
    over-flagged expansion that finds nothing fresh to cite is discarded and `vN` is restored.
    On a base with no distilled/question-node citations the intersection is exact. Resolving
    cited `dcl-`/`acl-` slugs back to their backing source slugs would tighten this, at the
    cost of reading each distilled/question page's backlinks here — a deferred refinement.

    Fail-soft: a missing/empty `sub_questions` or `ingested`, or a non-dict input, yields
    an empty `uncited_evidence_sq_ids` (no deficit) — never raises.
    """
    sub_questions = (plan or {}).get("sub_questions") or []
    ingested = (ingest_manifest or {}).get("ingested") or []
    citations = (citation_manifest or {}).get("citations") or []
    cited_slugs = {c.get("wiki_slug") for c in citations
                   if isinstance(c, dict) and c.get("wiki_slug")}

    per_sq: dict = {}
    uncited_evidence_sq_ids: list = []
    for sq in sub_questions:
        if not isinstance(sq, dict):
            continue
        sq_id = sq.get("id")
        if not sq_id:
            continue
        available = [
            src.get("slug")
            for src in ingested
            if isinstance(src, dict)
            and src.get("slug")
            and sq_id in (src.get("sub_question_refs") or [])
        ]
        cited = [s for s in available if s in cited_slugs]
        uncited = [s for s in available if s not in cited_slugs]
        per_sq[sq_id] = {"available": available, "cited": cited, "uncited": uncited}
        if uncited:
            uncited_evidence_sq_ids.append(sq_id)

    return {"per_sq": per_sq, "uncited_evidence_sq_ids": uncited_evidence_sq_ids}


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
# The same parser (`_parse_claim_block`) also backs `parse_distilled_claims` /
# `parse_distilled_claims_with_id` for the `distilled_claims:` block on
# concept/entity/summary/learning pages — the coverage scorer wants only `text`,
# the verify-store prefilter (#362) also wants `claim_id` to key the claim; neither
# needs the rest of the writer-side metadata that concept-store.py keeps private.

_FRONTMATTER_RE = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", re.DOTALL)
_CLAIMS_KEY_RE = re.compile(r"^pre_extracted_claims[ \t]*:[ \t]*$")
_WANTED_CLAIM_KEYS = ("id", "text", "excerpt_quote")
# concept/entity pages (written by concept-store.py) carry `distilled_claims:`
# instead — the coverage scorer reads only `text` from it (see parse_distilled_claims).
_DISTILLED_KEY_RE = re.compile(r"^distilled_claims[ \t]*:[ \t]*$")
_DISTILLED_WANTED_KEYS = ("text",)
# verify-store.py's prefilter (#362) also needs the `claim_id` to KEY a distilled
# citation to its claim — `parse_distilled_claims_with_id` adds it. A distilled
# claim has NO `excerpt_quote`, so the prefilter needle is `text` only.
_DISTILLED_ID_WANTED_KEYS = ("claim_id", "text")
# question nodes (written by question-store.py) carry `answer_claims:` — the same
# per-claim shape as `distilled_claims:` (claim_id `acl-NNN`, text, plus writer-side
# norm_key/backlinks/source_claim_refs/dates the readers ignore), so the citable
# answer surface reuses the distilled wanted-keys and block parser wholesale (#432).
_ANSWER_CLAIMS_KEY_RE = re.compile(r"^answer_claims[ \t]*:[ \t]*$")
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


_PAGE_ID_RE = re.compile(r"^id[ \t]*:[ \t]*(.+?)[ \t]*$")
_PAGE_SOURCES_RE = re.compile(r"^sources[ \t]*:[ \t]*(.+?)[ \t]*$")
_PAGE_CONTENT_HASH_RE = re.compile(r"^content_hash[ \t]*:[ \t]*(.+?)[ \t]*$")


def extract_page_id_and_url(page_text: str) -> tuple[str, str]:
    """Pull frontmatter `id` + the first `sources:` URL from a wiki source page.

    The single frontmatter read behind the ingest integrity check — shared by
    `ingest-integrity.py` (the post-wave sweep) and `source-ingester`'s Phase 3
    pre-write assertion so the two can never drift. Mirrors `wiki-coverage.py::
    _page_title_tags`: reuses `_FRONTMATTER_RE` for the block, strips a YAML inline
    comment from an UNQUOTED scalar, `_unquote_scalar` for quoted values, and hands
    the raw `sources:` value to `first_url`. Returns ("", "") for anything it cannot
    read — the caller surfaces the mismatch rather than masking it."""
    observed_id = ""
    observed_url = ""
    m = _FRONTMATTER_RE.match(page_text or "")
    if not m:
        return observed_id, observed_url
    for line in m.group(1).splitlines():
        im = _PAGE_ID_RE.match(line)
        if im and not observed_id:
            raw = im.group(1).strip()
            # Strip a YAML inline comment from an UNQUOTED scalar only — mirrors
            # _absorb_claim_kv / wiki-coverage._page_title_tags.
            if raw[:1] not in ('"', "'"):
                hash_pos = raw.find(" #")
                if hash_pos != -1:
                    raw = raw[:hash_pos].rstrip()
            observed_id = _unquote_scalar(raw)
            continue
        sm = _PAGE_SOURCES_RE.match(line)
        if sm and not observed_url:
            observed_url = first_url(sm.group(1).strip())
    return observed_id, observed_url


def extract_page_content_hash(page_text: str) -> str:
    """Pull the frontmatter `content_hash` (the fetched source body's provenance
    hash, `sha256:<hex>`) from a wiki source page, or "" when absent.

    The body-only-cross-talk leg of the ingest integrity check — shared by
    `ingest-integrity.py` (the post-wave sweep) and `source-ingester`'s Phase 3
    pre-write assertion so the two can never drift, exactly like
    `extract_page_id_and_url`. The id/sources legs catch a page whose identity
    frontmatter was crossed wholesale; this catches the narrower variant where a
    page keeps its own `id:`/`sources:` but carries a sibling's body **and** the
    sibling's `content_hash:` line. The value is compared against the cache
    `entry.content_hash` for the dispatched URL — NEVER a recomputed hash of the
    on-disk markdown, which diverges by design once the `# <title>` H1 and
    `## See also` backlink trailers are appended.

    Reuses `_FRONTMATTER_RE` for the block and `_unquote_scalar` for the value
    (the page emits it quoted, `content_hash: "sha256:…"`, via `json.dumps`).
    Returns "" for anything it cannot read so the caller skips the leg rather
    than false-flagging."""
    m = _FRONTMATTER_RE.match(page_text or "")
    if not m:
        return ""
    for line in m.group(1).splitlines():
        cm = _PAGE_CONTENT_HASH_RE.match(line)
        if cm:
            raw = cm.group(1).strip()
            # Strip a YAML inline comment from an UNQUOTED scalar only — mirrors
            # the id branch in extract_page_id_and_url.
            if raw[:1] not in ('"', "'"):
                hash_pos = raw.find(" #")
                if hash_pos != -1:
                    raw = raw[:hash_pos].rstrip()
            return _unquote_scalar(raw)
    return ""


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


# A block-style `sources:` key on its own line (synthesis pages: the value lives on
# the following indented `  - wiki://<slug>` lines). The INLINE source-page form
# `sources: ["<URL>"]` carries a value on the same line and so does NOT match — that
# is deliberate: a source page cites no wiki slugs, only `first_url` reads its URL.
_SOURCES_BLOCK_KEY_RE = re.compile(r"^sources[ \t]*:[ \t]*$")


def parse_synthesis_sources(page_text: str) -> list[str]:
    """Extract the cited page slugs from a synthesis page's block-style `sources:`
    frontmatter (each entry a bare `  - wiki://<slug>` line — the shape
    `knowledge-finalize` writes). Returns slugs in document order.

    The flat-scalar readers (`first_url` / `_PAGE_SOURCES_RE`) deliberately return
    "" for a synthesis page because its `sources:` value lives on indented lines a
    top-level scalar parse never surfaces — so this block-list parser is the only
    way to read a synthesis's cited edges. A source page's INLINE `sources:
    ["<URL>"]` scalar does not match `_SOURCES_BLOCK_KEY_RE` (key-on-its-own-line)
    → [] (correct: a source cites no wiki slugs).

    Tolerates a legacy `wiki://<wiki-slug>/<page-slug>` composite by taking the
    last path segment (the page slug); current finalize writes bare `wiki://<slug>`.
    Returns [] for any page with no parseable block. Block-bounding mirrors
    `_parse_claim_block`: the run of blank / indented / bullet lines after the key,
    up to the next top-level key."""
    if not page_text:
        return []
    m = _FRONTMATTER_RE.match(page_text)
    if not m:
        return []
    lines = m.group(1).splitlines()
    start = None
    for i, line in enumerate(lines):
        if _SOURCES_BLOCK_KEY_RE.match(line):
            start = i + 1
            break
    if start is None:
        return []
    slugs: list[str] = []
    for line in lines[start:]:
        stripped = line.strip()
        if stripped == "":
            continue  # a blank line inside the block is tolerated
        # The block ends at the next top-level key (non-indented, non-bullet).
        if not (line[:1] in (" ", "\t") or stripped == "-" or stripped.startswith("- ")):
            break
        if stripped.startswith("#"):
            continue  # a YAML comment line
        if stripped == "-" or stripped.startswith("- "):
            val = stripped[1:].strip()
            if val.startswith("wiki://"):
                target = val[len("wiki://"):].strip()
                # legacy composite `wiki://<wiki>/<slug>` → take the page slug
                slug = target.rsplit("/", 1)[-1] if target else ""
                if slug:
                    slugs.append(slug)
    return slugs


_FM_SCALAR_KEY_RE_CACHE: dict = {}


def _fm_scalar_key_re(key: str):
    """Compiled `^<key>:<value>$` matcher for `frontmatter_scalar`, cached per key
    so a hot-loop caller (e.g. synthesis-impact's per-synthesis `updated`/`title`
    reads) does not recompile the same handful of patterns on every call."""
    cached = _FM_SCALAR_KEY_RE_CACHE.get(key)
    if cached is None:
        cached = re.compile(r"^" + re.escape(key) + r"[ \t]*:[ \t]*(.*?)[ \t]*$")
        _FM_SCALAR_KEY_RE_CACHE[key] = cached
    return cached


def frontmatter_scalar(page_text: str, key: str) -> str:
    """Read a single flat frontmatter scalar by `key` (e.g. `created` / `updated`),
    or "" when absent / unparseable. Generalizes the id-reading half of
    `extract_page_id_and_url`: `_FRONTMATTER_RE` for the block, an inline-comment
    strip on an UNQUOTED scalar, `_unquote_scalar` for a quoted value. Only the
    FIRST matching column-0 key is returned; indented/nested keys never match (the
    pattern anchors at column 0), so a `created:` inside a claim block is ignored."""
    if not page_text or not key:
        return ""
    m = _FRONTMATTER_RE.match(page_text)
    if not m:
        return ""
    key_re = _fm_scalar_key_re(key)
    for line in m.group(1).splitlines():
        km = key_re.match(line)
        if km:
            raw = km.group(1).strip()
            if raw == "":
                return ""
            # Strip a YAML inline comment from an UNQUOTED scalar only.
            if raw[:1] not in ('"', "'"):
                hash_pos = raw.find(" #")
                if hash_pos != -1:
                    raw = raw[:hash_pos].rstrip()
            return _unquote_scalar(raw)
    return ""


def parse_distilled_claims(page_text: str) -> list[dict]:
    """Extract `[{text}, …]` from a wiki page's `distilled_claims:` frontmatter
    block (concept/entity pages, written by concept-store.py). Only `text` is
    absorbed; the writer-side metadata (claim_id / norm_key / backlinks /
    source_claim_refs / dates) is concept-store-private and ignored here. Returns []
    for any page without a parseable block — including the inline `distilled_claims:
    []` empty form, which `_DISTILLED_KEY_RE` (key-on-its-own-line) deliberately does
    not match."""
    return _parse_claim_block(page_text, _DISTILLED_KEY_RE, _DISTILLED_WANTED_KEYS)


def parse_distilled_claims_with_id(page_text: str) -> list[dict]:
    """Extract `[{claim_id, text}, …]` from a distilled page's `distilled_claims:`
    block. Same block as `parse_distilled_claims`, but also absorbs `claim_id`
    (`dcl-NNN`) so a reader can KEY a claim by id — verify-store.py's prefilter
    (#362) needs this to look up the cited distilled claim. The remaining
    writer-side metadata (norm_key / backlinks / source_claim_refs / dates) stays
    concept-store-private and is ignored. A distilled claim has no `excerpt_quote`,
    so callers using this for substring matching must take `text` as the needle.
    Returns [] for any page without a parseable block (same fail-safe contract)."""
    return _parse_claim_block(page_text, _DISTILLED_KEY_RE, _DISTILLED_ID_WANTED_KEYS)


def parse_answer_claims_with_id(page_text: str) -> list[dict]:
    """Extract `[{claim_id, text}, …]` from a question node's `answer_claims:`
    frontmatter block (written by question-store.py, #432). Byte-symmetric with
    `parse_distilled_claims_with_id` — same block parser, same wanted-keys — only the
    block key differs (`answer_claims:` vs `distilled_claims:`). The `claim_id` is an
    `acl-NNN` (distinct from distilled `dcl-NNN` / source `clm-NNN`, so it never
    collides), and an answer claim has NO `excerpt_quote`, so a caller using this for
    substring matching takes `text` as the needle. The remaining writer-side metadata
    (norm_key / backlinks / source_claim_refs / dates) stays question-store-private and
    is ignored. Returns [] for any page without a parseable block (same fail-safe)."""
    return _parse_claim_block(page_text, _ANSWER_CLAIMS_KEY_RE, _DISTILLED_ID_WANTED_KEYS)


def classify_claim_kind(claim_id: str | None) -> str:
    """Classify a citation by its `claim_id` prefix — the per-kind measurement
    behind the distilled-citation rate. The prefix is the established, single-mint
    discriminator in this codebase: `concept-store.py` is the only producer of
    `dcl-NNN` ids (distilled cross-source claims, citable since #344), and source
    pages carry `clm-NNN` from the claim extractor; a synthesis citation has no
    claim. Shared by `citation-store.py build` (write-time, on its return envelope)
    and `pipeline-summary.py` (read-time, across runs) so both report the same
    breakdown buckets:

      - `dcl-…` → `distilled`   - `clm-…` → `source`
      - `acl-…` → `answer`      - empty/None → `null`
      - anything else → `other`

    `acl-NNN` (answer-claim) ids are minted by `question-store.py answer-merge` for the
    citable question-node answer surface (#432). Forward-ready: no `acl-` citation exists
    until the composer is taught to prefer them (Slice 2), so this bucket reads 0 today.
    """
    if not claim_id:
        return "null"
    if claim_id.startswith("dcl-"):
        return "distilled"
    if claim_id.startswith("clm-"):
        return "source"
    if claim_id.startswith("acl-"):
        return "answer"
    return "other"


# --- machine-owned body blocks ------------------------------------------------
# concept/entity pages (written by concept-store.py) wrap each regenerated body
# region in `<!-- MACHINE-OWNED:NAME:START/END -->` sentinels (SUMMARY / CLAIMS /
# RELATED / SOURCES). The single source of truth for reading a block's inner text
# lives here so concept-store.py (the writer) AND knowledge-distill's bundle
# builder (the reader, Step 6.7) parse it the same way — a future tweak (CRLF,
# whitespace tolerance) applies everywhere at once.


def extract_machine_block(page_text: str, name: str) -> str | None:
    """Inner text between `<!-- MACHINE-OWNED:NAME:START -->` and `:END -->`, or
    None when the named block is absent. CRLF-tolerant; the inner is returned
    verbatim (it includes the block's own `## Heading`)."""
    pat = re.compile(
        r"<!--\s*MACHINE-OWNED:" + re.escape(name) + r":START\s*-->\r?\n(.*?)"
        r"\r?\n?<!--\s*MACHINE-OWNED:" + re.escape(name) + r":END\s*-->",
        re.DOTALL,
    )
    m = pat.search(page_text or "")
    return m.group(1) if m else None


def replace_machine_block(page_text: str, name: str, new_inner: str) -> str:
    """Return `page_text` with the named MACHINE-OWNED block's inner replaced by
    `new_inner`, leaving every other byte untouched. The START/END sentinels and
    surrounding bytes are preserved verbatim; the match mirrors
    `extract_machine_block` so reader and writer stay symmetric. No-op (returns
    the input unchanged) when the named block is absent — use
    `upsert_machine_block` to insert one. Single source of truth: `concept-store.py`
    (`renarrate` SUMMARY splice) and `knowledge-finalize` (OVERVIEW-NARRATIVE
    splice) both go through here so a future tweak applies everywhere."""
    pat = re.compile(
        r"(<!--\s*MACHINE-OWNED:" + re.escape(name) + r":START\s*-->\r?\n)(.*?)"
        r"(\r?\n?<!--\s*MACHINE-OWNED:" + re.escape(name) + r":END\s*-->)",
        re.DOTALL,
    )
    return pat.sub(lambda m: m.group(1) + new_inner + m.group(3), page_text or "", count=1)


def upsert_machine_block(page_text: str, name: str, new_inner: str) -> str:
    """Replace the named MACHINE-OWNED block's inner if present, else INSERT a
    fresh `<!-- :START -->\\n<inner>\\n<!-- :END -->` block right after the body's
    leading H1 (`# …`) — or at the very top when there is no H1. Used by
    `knowledge-finalize` to upsert the `OVERVIEW-NARRATIVE` block on `wiki/overview.md`
    (first finalize inserts it; later finalizes replace only its inner). Every
    other byte is preserved."""
    if extract_machine_block(page_text, name) is not None:
        return replace_machine_block(page_text, name, new_inner)
    block = (
        "<!-- MACHINE-OWNED:" + name + ":START -->\n"
        + new_inner
        + "\n<!-- MACHINE-OWNED:" + name + ":END -->\n"
    )
    text = page_text or ""
    lines = text.splitlines(keepends=True)
    # Insert after the first H1 (and a single following blank line, if any).
    for i, line in enumerate(lines):
        if line.lstrip().startswith("# "):
            insert_at = i + 1
            if insert_at < len(lines) and lines[insert_at].strip() == "":
                insert_at += 1
            head = "".join(lines[:insert_at])
            tail = "".join(lines[insert_at:])
            if head and not head.endswith("\n"):
                head += "\n"
            return head + block + ("\n" + tail if tail else "")
    # No H1 — prepend the block.
    return block + ("\n" + text if text else "")


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


# Typographic substitutes an LLM may emit where a normal space belongs. They
# render oddly in the reader-facing wiki/index.md one-liner (§†30, Dezember†2025)
# and dirty the German-text quality bar (#387). Map each back to U+0020.
#   U+2020 DAGGER, U+2021 DOUBLE DAGGER, U+00A0 NBSP, U+202F NARROW NBSP, U+2009 THIN SPACE
_SUMMARY_SPACE_SUBSTITUTES = "†‡   "
_SUMMARY_SUBSTITUTE_RE = re.compile("[" + _SUMMARY_SPACE_SUBSTITUTES + "]")


def sanitize_summary(text: str) -> str:
    """Normalize stray typographic substitutes in an LLM-authored index one-liner
    back to regular spaces before it reaches wiki/index.md (#387).

    Maps U+2020/U+2021 (daggers, emitted where a space belongs) and the exotic
    spaces U+00A0/U+202F/U+2009 to U+0020, then collapses the resulting whitespace
    runs and strips the ends. Cosmetic, deterministic, valid-UTF-8 in/out. This is
    NOT slugify — accents and non-ASCII letters are preserved verbatim; only the
    substitute glyphs change.

    The daggers are not whitespace, so the explicit regex sub is load-bearing; the
    exotic spaces are belt-and-suspenders (str.split() already treats them as
    separators). Empty/falsy input returns unchanged so callers surface a bad value
    rather than coalescing it to "".
    """
    if not text:
        return text
    swapped = _SUMMARY_SUBSTITUTE_RE.sub(" ", text)
    return " ".join(swapped.split())


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


def theme_norm_key(text: str) -> str:
    """Order- and stopword-independent token-set key for a theme_label.

    The lineage-match key behind question-node cross-run accumulation (#409):
    two theme_labels with the SAME non-empty key name the same recurring theme,
    so a variant phrasing routes to the existing question node. Built on
    `tokenize` (the SSOT fold/stopword/stem path) so DE/FR labels normalize
    identically ("Pflichten für Risikoklassen" == "Risikoklassen Pflichten").

    Deliberately NOT `norm_key`: that drops GENERIC_DENYLIST tokens (regulatory
    boilerplate tuned for coverage scoring), which would FALSE-MERGE distinct
    themes — "AI Act Scope" and "AI System Scope" both collapse to "scope".
    `tokenize` keeps act/system, so the two stay separate (keep-on-doubt).

    Empty / stopword-only input -> "" so the caller falls back to slugify and
    NEVER records an empty key (which would match every empty-theme label)."""
    return " ".join(sorted(tokenize(text)))


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


def digit_anchor_tokens(text: str) -> set:
    """The cross-lingual article-number anchors in a claim text: pure-numeric
    tokens that still carry weight (so the GENERIC_DENYLIST years 2024–2026 are
    excluded — `token_weight` zeroes them BEFORE the digit ×3.0 boost). These are
    the only deterministic DE↔EN bridge — "Artikel 99" and "Article 99" share the
    token `99` and nothing else. concept-store.py's cross-lingual candidate gate
    (#345) uses this on BOTH sides — candidate generation AND the server-side
    re-validation that bounds the LLM to script-flagged pairs — so the anchor
    predicate is computed in exactly one place."""
    return {t for t in tokenize(text) if t.isdigit() and token_weight(t) > 0.0}


# --- concept-records parser (used by concept-store.py / knowledge-distill) -----
# The `concept-distiller` agent has no Bash and MUST NOT hand-build JSON/YAML
# (same #325 constraint as wiki-composer). It writes raw-text concept records;
# `concept-store.py` parses them via this function and owns all serialization.
# Format mirrors `parse_citation_records` — a labeled, line-oriented block list,
# one `- title:` bullet per concept/entity, with repeatable `claim:` lines. The
# `type` line is `concept` | `entity`; `claim:` value is
# `<source_slug>#<claim_id> | <claim text>`.


def _split_claim_ref(value: str) -> dict:
    """Split a provenance+text claim-ref line into `{source_slug, source_claim_id,
    text}`. Two accepted forms, disambiguated by whether the FIRST `|`-segment carries
    a `#` (slugs/claim-ids never contain `#`, so its presence unambiguously marks the
    ref form). We split on `#`/`|` positionally — NOT `split("|", 2)` — so a claim text
    containing ` | ` (common in regulatory prose: "Article 6 | paragraph 2") is
    preserved verbatim in BOTH forms rather than mis-split into the provenance fields.
        `<source_slug>#<claim_id> | <text…>`     (2-part ref form)
        `<source_slug> | <claim_id> | <text…>`   (documented 3-part form)
    Shared by `_absorb_concept_kv` (`claim:`) and `_absorb_answer_kv` (`answer_claim:`,
    #432) so the partition discipline lives in exactly one place."""
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
    return {
        "source_slug": src_slug.strip(),
        "source_claim_id": cid.strip(),
        "text": ctext.strip(),
    }


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
        item["claims"].append(_split_claim_ref(value))
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


# --- answer-records parser (used by question-store.py answer-merge, #432) ------
# The `answer-distiller` agent (like concept-distiller / wiki-composer) has no Bash
# and MUST NOT hand-build JSON/YAML. It writes raw-text answer records — one
# `- question: <slug>` bullet per question node, with repeatable `answer_claim:` lines
# whose value is the same `<source_slug> | <claim_id> | <text>` triple the claim bundle
# carries. `question-store.py answer-merge` parses them via `parse_answer_records` and
# owns all serialization + claim-dedup. Mirrors `parse_concept_records` exactly except
# the grouping key is `question:` (the existing question slug, NOT a title to slugify).


def _absorb_answer_kv(item: dict, kv: str) -> None:
    if ":" not in kv:
        return
    key, _, value = kv.partition(":")  # first colon only — claim text contains ':'
    key = key.strip().lower()
    value = value.strip()
    if key == "question":
        item["slug"] = value
    elif key == "answer_claim":
        item["claims"].append(_split_claim_ref(value))
    # Unknown keys are ignored — the answer slug is the existing question slug
    # (never derived here) and dedup is question-store.py's job, not the parser's.


def parse_answer_records(text: str) -> list[dict]:
    """Parse an answer-distiller records file into a list of `{slug, claims[]}` dicts
    (each claim `{source_slug, source_claim_id, text}`). A `- ` bullet starts a record;
    the `question:` field may sit inline after the bullet. Repeatable `answer_claim:`
    lines accumulate. Blank and `#`-comment lines are skipped. Indent-tolerant. A record
    missing its `question:` is emitted with an empty slug (NOT dropped) so
    `question-store.py` can surface it rather than silently lose an answer (#432)."""
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
            current = {"slug": "", "claims": []}
            rest = lstripped[1:].strip()
            if rest:
                _absorb_answer_kv(current, rest)
        elif current is not None:
            _absorb_answer_kv(current, lstripped)
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
    "url": "url",
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
    # `url` (#395) is the cited page's `sources:` value, copied byte-for-byte by
    # the composer/revisor. It defaults to "" — synthesis/distilled citations carry
    # no external URL, and legacy records (pre-#395) omit the `url:` line entirely,
    # so the structured per-citation slug→URL binding gate in citation-store.py only
    # fires when this is non-empty.
    return {
        "id": item.get("id", ""),
        "draft_position": item.get("draft_position", ""),
        "draft_sentence": item.get("draft_sentence", ""),
        "wiki_slug": item.get("wiki_slug", ""),
        "claim_id": claim_id,
        "url": item.get("url", ""),
    }


def parse_citation_records(text: str) -> list[dict]:
    """Parse a wiki-composer citation-records file into a list of
    `{id, draft_position, draft_sentence, wiki_slug, claim_id, url}` dicts.

    Each record is a `- id:` bullet followed by `pos:` / `slug:` / `claim:` /
    `url:` (optional, #395) / `sentence:` lines (indent-tolerant). `url` is the
    cited page's `sources:` value, copied byte-for-byte; it defaults to "" when
    the line is absent (legacy records) or empty (synthesis/distilled citations).
    `sentence` is the LAST field and its
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


# --- renarrate-records parser (used by concept-store.py renarrate) ------------
# The concept-summary-narrator (#341) re-writes a concept/entity page's `##
# Summary` prose from the merged `distilled_claims[]`. Like every other Phase-4.5
# agent it has no Bash and writes RAW TEXT only — never JSON/YAML — because a
# straight `"` in a German „…" summary would break a hand-built structure (#325).
# Summaries are multi-line prose, so a single-line `key: value` record (the
# citation/concept idiom) won't do; instead each record fences its prose between
# a `<<<SUMMARY` opener and a closing line that is exactly `SUMMARY`. concept-
# store.py `renarrate` parses this, then owns all serialization + the page write.

_RENARRATE_SLUG_RE = re.compile(r"^-\s*slug\s*:\s*(.+?)\s*$")
_RENARRATE_OPEN = "<<<SUMMARY"
_RENARRATE_CLOSE = "SUMMARY"


def parse_renarrate_records(text: str) -> dict:
    """Parse a concept-summary-narrator records file into `{slug: new_prose}`.

    Format (one block per slug)::

        - slug: high-risk-classification
          <<<SUMMARY
          Re-narrated prose, possibly
          multiple lines, in OUTPUT_LANGUAGE.
          SUMMARY

    The prose between `<<<SUMMARY` and a line that is exactly `SUMMARY` (stripped)
    is captured verbatim, dedented to the block's common left margin, joined with
    `\\n`, and trailing/leading blank lines trimmed. A slug whose prose is empty
    is omitted (the script then leaves that page untouched). A later block for the
    same slug wins. CRLF-tolerant; lines split on `\\n` so an embedded U+2028 in
    prose is preserved. A `<<<SUMMARY` with no closing `SUMMARY` runs to EOF."""
    out: dict[str, str] = {}
    slug: str | None = None
    capturing = False
    buf: list[str] = []

    def _flush() -> None:
        nonlocal slug, buf
        if slug is not None:
            prose = _dedent_join(buf)
            if prose:
                out[slug] = prose
        buf = []

    for raw in (text or "").split("\n"):
        if raw.endswith("\r"):
            raw = raw[:-1]
        stripped = raw.strip()
        if capturing:
            if stripped == _RENARRATE_CLOSE:
                capturing = False
                _flush()
                slug = None
                continue
            buf.append(raw)
            continue
        m = _RENARRATE_SLUG_RE.match(raw.lstrip())
        if m:
            # A new slug bullet — flush any open (unterminated) prior block first.
            _flush()
            slug = m.group(1).strip()
            continue
        if stripped == _RENARRATE_OPEN and slug is not None:
            capturing = True
            buf = []
    # Trailing unterminated block (no closing `SUMMARY` before EOF).
    if capturing:
        _flush()
    return out


def _dedent_join(lines: list[str]) -> str:
    """Strip leading/trailing blank lines, remove the common leading-whitespace
    margin, and join with `\\n`. Empty / all-blank input → empty string."""
    body = list(lines)
    while body and not body[0].strip():
        body.pop(0)
    while body and not body[-1].strip():
        body.pop()
    if not body:
        return ""
    margins = [len(ln) - len(ln.lstrip()) for ln in body if ln.strip()]
    cut = min(margins) if margins else 0
    return "\n".join(ln[cut:] if len(ln) >= cut else ln for ln in body)


# --- portal-narrator records (#491) ------------------------------------------
# The portal-narrator (knowledge-finalize Step 10.5 sub-step 3.5) proposes
# per-theme lead-ins + one overview narrative as a raw-text records file, the
# same fenced-block idiom as the concept-summary-narrator (parse_renarrate_records
# above). Two block kinds:
#
#     - theme: Syntheses
#       <<<LEADIN
#       Why this theme matters, what to read first.
#       LEADIN
#     - overview:
#       <<<NARRATIVE
#       The state-of-the-wiki prose.
#       NARRATIVE
_PORTAL_THEME_RE = re.compile(r"^-\s*theme\s*:\s*(.+?)\s*$")
_PORTAL_OVERVIEW_RE = re.compile(r"^-\s*overview\s*:\s*$")
_PORTAL_LEADIN_OPEN = "<<<LEADIN"
_PORTAL_LEADIN_CLOSE = "LEADIN"
_PORTAL_NARRATIVE_OPEN = "<<<NARRATIVE"
_PORTAL_NARRATIVE_CLOSE = "NARRATIVE"


def parse_portal_records(text: str) -> dict:
    """Parse a portal-narrator records file into
    `{"theme_leadins": {theme: prose}, "overview": prose_or_None}`.

    A `- theme: <heading>` bullet opens a lead-in block fenced by `<<<LEADIN` …
    `LEADIN`; a `- overview:` bullet opens the narrative block fenced by
    `<<<NARRATIVE` … `NARRATIVE`. Prose is dedented + blank-trimmed via
    `_dedent_join`. An empty block is dropped (the engine then leaves that
    target untouched). A later block for the same theme wins; a later overview
    wins. CRLF-tolerant. An unterminated trailing block runs to EOF."""
    theme_leadins: dict[str, str] = {}
    overview: str | None = None
    key: str | None = None          # the current theme heading, or "__overview__"
    fence_close: str | None = None  # which CLOSE token ends the current capture
    capturing = False
    buf: list[str] = []

    def _flush() -> None:
        nonlocal key, buf, overview
        if key is not None:
            prose = _dedent_join(buf)
            if prose:
                if key == "__overview__":
                    overview = prose
                else:
                    theme_leadins[key] = prose
        buf = []

    for raw in (text or "").split("\n"):
        if raw.endswith("\r"):
            raw = raw[:-1]
        stripped = raw.strip()
        if capturing:
            if stripped == fence_close:
                capturing = False
                _flush()
                key = None
                continue
            buf.append(raw)
            continue
        mt = _PORTAL_THEME_RE.match(raw.lstrip())
        if mt:
            _flush()
            key = mt.group(1).strip()
            continue
        if _PORTAL_OVERVIEW_RE.match(raw.lstrip()):
            _flush()
            key = "__overview__"
            continue
        if key is not None and stripped in (_PORTAL_LEADIN_OPEN, _PORTAL_NARRATIVE_OPEN):
            capturing = True
            fence_close = (
                _PORTAL_LEADIN_CLOSE if stripped == _PORTAL_LEADIN_OPEN
                else _PORTAL_NARRATIVE_CLOSE
            )
            buf = []
    if capturing:
        _flush()
    return {"theme_leadins": theme_leadins, "overview": overview}


# --- crossmerge-records parser (used by concept-store.py crossmerge, #345) -----
# The cross-lingual-claim-merger agent (#345) has no Bash and writes RAW TEXT only
# — same #325 constraint as every other Phase-4.5 agent. It confirms cross-lingual
# (DE↔EN) twin claims the script already flagged as candidates; each confirmation
# is ONE line. concept-store.py `crossmerge` parses these, re-validates the
# candidate gate server-side (so the LLM can never widen scope), and UNIONs the
# absorbed claim's provenance onto the survivor under the lock.

_CROSSMERGE_RE = re.compile(r"^\s*merge\s*:\s*(.+)$")


def parse_crossmerge_records(text: str) -> list[dict]:
    """Parse a cross-lingual-claim-merger records file into a list of
    `{slug, survivor_id, absorbed_id}` dicts.

    Format — one confirmed union per line::

        merge: high-risk-classification | dcl-003 | dcl-007

    Three pipe-delimited fields after the `merge:` label: the page slug, the
    survivor claim id (kept), and the absorbed claim id (folds into the survivor
    and is removed). Blank and `#`-comment lines are skipped. A line with the
    wrong arity or an empty field is dropped silently — `crossmerge` re-validates
    every id against the on-disk page anyway, so a malformed line must never abort
    the batch. CRLF-tolerant; split on `\\n` only."""
    out: list[dict] = []
    for raw in (text or "").split("\n"):
        if raw.endswith("\r"):
            raw = raw[:-1]
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = _CROSSMERGE_RE.match(line)
        if not m:
            continue
        parts = [p.strip() for p in m.group(1).split("|")]
        if len(parts) != 3 or not all(parts):
            continue
        out.append({"slug": parts[0], "survivor_id": parts[1], "absorbed_id": parts[2]})
    return out


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


def load_pypdf():
    """Import pypdf from the **current interpreter**. Returns the module, or ``None``.

    pypdf is the source-curator's pure-Python text-layer PDF fallback for a
    poppler-less host (where the Read tool cannot rasterize a saved PDF). It is
    NOT vendored — it is an optional dependency under the repo's "stdlib-only /
    no pip" exception (optional dependency + graceful degradation, the same shape
    as cogni-wiki's `markitdown` and cogni-visual's `cairosvg`).

    This resolves pypdf only from the interpreter actually running this code — the
    host's site-packages (`pip install pypdf`), or, when ``pdf-extract.py`` re-execs
    itself under a ``COGNI_WORKSPACE_PYTHON_VENV`` workspace venv, that venv's own
    site-packages. It deliberately does NOT bolt a foreign venv's site-packages
    onto the host ``sys.path``: pypdf optionally imports the compiled
    ``cryptography`` package, and mixing a venv's pure-Python pypdf with a host's
    (possibly broken) compiled deps can raise a non-``Exception`` ``BaseException``
    (e.g. a pyo3 ``PanicException``). Running pypdf inside its own venv interpreter
    keeps ``sys.path`` clean; see ``pdf-extract.py``'s re-exec.

    Returns ``None`` (never raises) when pypdf is not importable here, so the caller
    can record the honest `pdf_render_unavailable` outcome. The broad ``BaseException``
    guard (interrupts re-raised) is intentional: a broken optional compiled
    dependency must degrade, never crash the curator.
    """
    try:
        import pypdf  # type: ignore

        return pypdf
    except (KeyboardInterrupt, SystemExit):
        raise
    except BaseException:
        return None


class PdfExtractResult(NamedTuple):
    """Outcome of a text-layer extraction.

    ``reason`` is the closed vocabulary the pdf-extract CLI / source-curator branch
    on; ``error`` is a human-readable detail (empty on success).
    """

    text: str | None  # extracted text when reason == "ok", else None
    pages: int | None  # page count when the PDF parsed, else None
    reason: str  # "ok" | "pypdf_unavailable" | "no_text_layer" | "extract_failed"
    error: str = ""


def extract_pdf_text(path, min_chars: int = 200) -> PdfExtractResult:
    """Extract a PDF's text layer via the optional pypdf dependency (in-process).

    The single text-layer extraction mechanism for the poppler-less fallback: the
    `pdf-extract.py` CLI formats this result as a JSON envelope and the
    source-curator branches on ``reason``. Returns the concatenated page text (with
    the page count) when it clears the non-trivial-text gate (`min_chars`), or a
    failure reason — ``pypdf_unavailable`` (dep absent in this interpreter),
    ``no_text_layer`` (image-only / scanned), or ``extract_failed`` (parse raised).

    Fail-soft by design: never raises. pypdf is resolved via ``load_pypdf`` (the
    current interpreter only) — no pip dependency at runtime, no vendored copy. The
    workspace-venv fallback lives in ``pdf-extract.py`` (it re-runs the CLI under
    the venv interpreter when ``reason == "pypdf_unavailable"``).
    """
    pypdf = load_pypdf()
    if pypdf is None:
        return PdfExtractResult(None, None, "pypdf_unavailable")
    try:
        reader = pypdf.PdfReader(str(path))
        pages = len(reader.pages)
        parts: list[str] = []
        for page in reader.pages:
            try:
                parts.append(page.extract_text() or "")
            except Exception:
                continue
        text = "\n".join(parts).strip()
    except Exception as exc:
        return PdfExtractResult(None, None, "extract_failed", f"pypdf parse failed: {exc}")

    if len(text) < int(min_chars):
        return PdfExtractResult(
            None, pages, "no_text_layer", "No usable text layer extracted (image-only / scanned PDF)."
        )
    return PdfExtractResult(text, pages, "ok")


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


def _coverage_sub_questions(project_path, coverage_name: str = "wiki-coverage.json") -> list:
    """Return the coverage manifest's `data.sub_questions[]` (or [] on any failure).

    `coverage_name` selects which `.metadata/` coverage file to read. It defaults
    to the curate-time `wiki-coverage.json` (written pre-research at
    knowledge-curate Step 0.5), so the curate consumers stay byte-identical;
    knowledge-finalize passes `wiki-coverage-finalize.json` (a POST-ingest
    re-score) so a sub-question the run actually covered no longer reads as an
    uncovered research-time gap.
    """
    cov = _read_metadata_json(project_path, coverage_name)
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
            # Clamp to 140 chars *including* the ellipsis (139 of query + "…").
            query = query[:139].rstrip() + "…"
        if theme and query:
            msg = f"{theme} — {query}"
        else:
            msg = theme or query
        out[sid] = _sanitize_gap_message(msg)
    return out


def _iter_coverage_gaps(project_path, coverage_name: str = "wiki-coverage.json"):
    """Yield `(sq_id, verdict)` for every regex-safe sub-question scored a gap
    (`uncovered`/`partial`) in the `<project>/.metadata/` coverage manifest named
    by `coverage_name` (default the curate-time `wiki-coverage.json`), in
    coverage-manifest order. The single source of truth for the gap filter +
    sq_id validation shared by the two public helpers below."""
    for sq in _coverage_sub_questions(project_path, coverage_name):
        if not isinstance(sq, dict):
            continue
        verdict = sq.get("coverage_verdict")
        if verdict not in _COVERAGE_GAP_CLASS:
            continue
        sid = str(sq.get("sq_id", ""))
        if sid and _SQ_ID_RE.match(sid):
            yield sid, verdict


def gap_sq_ids_from_coverage(project_path, coverage_name: str = "wiki-coverage.json") -> list:
    """Bare `sq_id` list (no `sq:` prefix) for sub-questions scored
    `uncovered`/`partial` in the `<project>/.metadata/` coverage manifest named by
    `coverage_name` (default the curate-time `wiki-coverage.json`).

    Used by knowledge-finalize Step 10 to build the `sqs=sq-01,sq-04` suffix on
    the `wiki/log.md` finalize line. Preserves coverage-manifest order. Returns
    [] when the manifest is absent/malformed (degraded but valid). Ids that are
    not regex-safe are dropped.
    """
    return [sid for sid, _ in _iter_coverage_gaps(project_path, coverage_name)]


def load_wiki_coverage_findings(project_path, coverage_name: str = "wiki-coverage.json") -> list:
    """Turn research-time gaps into open_questions.md `--findings -` entries.

    Reads the `<project>/.metadata/` coverage manifest named by `coverage_name`
    (default the curate-time `wiki-coverage.json`; knowledge-finalize passes the
    POST-ingest `wiki-coverage-finalize.json` so a covered sub-question is not
    deposited as a false uncovered gap). For each sub-question scored
    `uncovered`/`partial`, emits
    `{"class": "research_uncovered"|"research_partial", "id": "sq:<sq_id>",
      "message": "<theme_label> — <query>"}`. The message text is read from
    plan.json (the coverage manifest carries only sq_id + verdict); falls back to
    a bare `sub-question <sq_id> (<verdict>)` when plan.json is missing.

    Returns [] on a missing/malformed coverage manifest (fail-soft, matching the
    SKILL's posture). Regex-unsafe sq_ids are dropped.
    """
    messages = _plan_message_index(project_path)
    out = []
    for sid, verdict in _iter_coverage_gaps(project_path, coverage_name):
        msg = messages.get(sid) or f"sub-question {sid} ({verdict})"
        out.append({"class": _COVERAGE_GAP_CLASS[verdict], "id": f"sq:{sid}", "message": msg})
    return out


# A dotted-numeric version dir name, e.g. `0.1.74` — mirrors the shell probe's
# `case "$ver" in ''|*[!0-9.]*) continue` numeric guard so a branch/`main`
# checkout dir never outranks a real semver. Slightly stricter than the shell
# case (rejects empty/leading/trailing/doubled `.` segments too), which only
# matters for malformed dirs and lets the sort key skip an empty-segment guard.
_NUMERIC_VERSION_RE = re.compile(r"^[0-9]+(\.[0-9]+)*$")


def resolve_wiki_scripts(skill: str, base_dir: "Path | None" = None, expected_script: "str | None" = None) -> Path:
    """Locate `cogni-wiki/skills/<skill>/scripts/`, the single Python definition
    of the shell `resolve_wiki_scripts <skill>` probe in the knowledge-* SKILLs.

    Generalises the per-skill wiki-scripts lookup so a standalone, operator-run
    Python driver (e.g. migrate-question-index.py) self-resolves the dir without
    carrying its own copy of the ranking rule. The locked-writer scripts
    (question-store.py, concept-store.py) deliberately keep requiring
    `--wiki-scripts-dir` from the orchestrator and never call this.

    Probe order (highest-priority first):
      0. Vendored copy — `<this-file's dir>/vendor/cogni-wiki/skills/<skill>/scripts`,
         the byte-identical engine cogni-knowledge ships in-tree (Phase 7). Probed
         first so the plugin is self-contained; the external probes below are the
         fallback that keeps both plugins installable until cogni-wiki is archived.
         Gated to the production path (base_dir is None) so the base_dir test seam
         still exercises the versioned-cache ranking branch hermetically.
      1. Sibling checkout — `<repo-root>/cogni-wiki/skills/<skill>/scripts`,
         where <repo-root> is two levels up from this file
         (scripts/ -> cogni-knowledge/ -> <repo-root>).
      2. Versioned-cache install — newest NUMERIC version dir matching
         `<repo-root>/../cogni-wiki/*/skills/<skill>/scripts` (a non-numeric
         dir name — a branch/`main` checkout — never outranks a real semver).

    `base_dir` is a TEST-ONLY injection seam: when None (the production default)
    <repo-root> is derived from this file's location, so every real caller is
    byte-identical to the no-arg form; a test passes an explicit synthetic root
    to exercise the versioned-cache ranking branch hermetically (the real
    sibling checkout would otherwise short-circuit branch 1 in the monorepo).
    The base_dir seam also bypasses branch 0 (the vendored copy lives next to the
    real file, not under a synthetic root).

    `expected_script`, when given, hardens every probe branch: a directory wins
    only when it BOTH exists AND contains that entry-point file. This stops a
    partial/botched vendor (the dir is present but the needed script was never
    copied) from short-circuiting the working sibling/cache fallback and
    surfacing later as a FileNotFoundError on the missing script. None (the
    default) preserves the historic dir-only behaviour byte-for-byte.

    Raises FileNotFoundError when neither branch resolves.
    """
    def _has_entrypoint(d: "Path") -> bool:
        return expected_script is None or (d / expected_script).is_file()

    if base_dir is None:
        vendored = Path(__file__).resolve().parent / "vendor" / "cogni-wiki" / "skills" / skill / "scripts"
        if vendored.is_dir() and _has_entrypoint(vendored):
            return vendored

    repo_root = Path(base_dir) if base_dir is not None else Path(__file__).resolve().parents[2]
    sib = repo_root / "cogni-wiki" / "skills" / skill / "scripts"
    if sib.is_dir() and _has_entrypoint(sib):
        return sib

    candidates: "list[tuple[tuple[int, ...], Path]]" = []
    for d in (repo_root.parent / "cogni-wiki").glob(f"*/skills/{skill}/scripts"):
        if not d.is_dir():
            continue
        if not _has_entrypoint(d):
            continue
        ver = d.parents[2].name  # the <semver> segment
        if _NUMERIC_VERSION_RE.match(ver):
            # Sort key: `0.0.9 < 0.0.16`. The regex guarantees every segment is a
            # non-empty digit run, so no empty-segment filter is needed.
            candidates.append((tuple(int(p) for p in ver.split(".")), d))
    if candidates:
        return max(candidates)[1]

    raise FileNotFoundError(
        f"cogni-wiki {skill} scripts not found — install cogni-wiki, run "
        f"from inside the monorepo, or pass --wiki-scripts-dir"
    )
