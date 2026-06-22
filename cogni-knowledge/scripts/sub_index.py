#!/usr/bin/env python3
"""sub_index.py — generic deterministic renderer for wiki/<type>/index.md.

The generalization of `concepts_index.py`: one shared renderer that produces a
curated, machine-owned per-type sub-index for ANY of the six cogni-knowledge
wiki page types — `concepts`, `entities`, `people`, `sources`, `questions`,
`syntheses`. `concepts_index.py` is now a thin type-config wrapper
that delegates here, preserving its byte-stable CLI (so `test_concepts_index.sh`
passes unchanged).

Each sub-index enumerates the wiki pages of one type, groups them by theme, and
emits one `## <theme>` section per theme — each with an engine-owned,
narrator-authored lead-in span (`MACHINE-OWNED:<TYPE>-LEADIN:<theme>`) and a
bullet per page (one-line summary + `[[slug]]` wikilink). This is the
DETERMINISTIC SPINE only: the renderer writes the structure and the bullets; it
never writes lead-in PROSE — it lays down an empty/placeholder lead-in span that
a narrator fills in later, and it carries an already-authored lead-in forward
verbatim on every re-render so it never clobbers the narrator's prose.

Theme handling is wiki-resident — it never reads `plan.json`. Section ORDER for
every type comes from `wiki/index.md`'s `## <theme>` heading order (the portal,
filed at ingest via `wiki_index_update.py --category`). Per-page theme
ASSIGNMENT is the one axis that varies by type, expressed as a `theme_fn`:

  - `theme_via_backing_sources` (concept/entity/person/summary/learning/synthesis) —
    look up each backing SOURCE slug from the page's `sources:` frontmatter in
    the portal and take the MAJORITY theme (ties broken by portal order).
  - `theme_via_own_slug` (source) — a source page carries an authoritative
    `theme_label:` frontmatter field (written at ingest), so its theme is a
    direct read of its OWN page; legacy pages fall back to the portal-bullet map.
  - `theme_via_frontmatter` (question) — the page carries an authoritative
    `theme_label:` frontmatter field (the cleanest signal, no portal round-trip).

A page with no resolvable theme goes into a single trailing `## Uncategorized`
group so none are dropped.

Subcommands (both take `--type <type>`):

  - `render` — write `wiki/<type>/index.md` live, under `_wiki_lock` +
               `atomic_write_text`, only when the proposed text differs
               byte-for-byte (idempotent: re-running an unchanged wiki is a
               no-op with no stamp/date churn).
  - `stage`  — write the proposed page to the type's `<wiki-root>/.cogni-wiki/
               <type>-index-proposed.md` WITHOUT the lock and WITHOUT touching
               the live file.

`_wiki_lock` is imported from cogni-wiki's `_wikilib` via `--wiki-scripts-dir`
(the `concept-store.py` posture) so the live write serialises on the same
`<wiki-root>/.cogni-wiki/.lock` as every other shared-state wiki write. The
transform helpers (`extract_machine_block`, `atomic_write_text`,
`frontmatter_scalar`, `parse_distilled_claims`, `slugify`) are reused verbatim
from `_knowledge_lib`.

Fail-soft posture: a missing wiki-scripts dir, a `_wikilib` import failure, a
non-wiki `--wiki-root`, an unknown `--type`, or any write error returns a
`{"success": false, ...}` envelope and writes nothing partial.

Stdlib only. No pip dependencies. POSIX only on `render` (`_wiki_lock` uses
`fcntl.flock`); `stage` is lock-free. Python 3.9 floor (the `from __future__
import annotations` below lets the `X | None` / `list[dict]` annotations parse
on 3.9, matching `_knowledge_lib`).

Output is a `{"success": bool, "data": {...}, "error": "..."}` JSON envelope
(pretty-printed with `indent=2`), per the cross-plugin script convention.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write_text,
    extract_machine_block,
    frontmatter_scalar,
    parse_distilled_claims,
    parse_pre_extracted_claims,
    slugify,
)

PORTAL_INDEX_REL = ("wiki", "index.md")

# A source bullet in wiki/index.md: a list item whose first wikilink names the
# source slug, e.g. `- [[some-source]] — title`. Anchored to a list line so a
# `[[wikilink]]` inside a *-LEADIN prose span is never mistaken for a source
# membership.
_SOURCE_BULLET_RE = re.compile(r"^\s*-\s.*?\[\[([a-z0-9][a-z0-9\-]*)\]\]")
# A level-2 heading line (`## <theme label>`); level-1 (`# `) and level-3+ are
# not theme sections in the portal layout.
_THEME_HEADING_RE = re.compile(r"^##[ \t]+(.+?)[ \t]*$")
# `sources:` frontmatter list entries: `  - wiki://<slug>` (concept-store.py
# renders the backing-source union exactly this way).
_SOURCE_FM_RE = re.compile(r"^\s*-\s*wiki://([a-z0-9][a-z0-9\-]*)\s*$")


# --- per-type configuration ---------------------------------------------------


@dataclass(frozen=True)
class TypeConfig:
    """The 10 per-type knobs that were module-level constants in
    `concepts_index.py`, plus the two callables that capture per-type variation
    (theme assignment + one-line summary). Everything else in this module is
    type-agnostic and reads these fields."""

    type_name: str
    dir_rel: tuple
    index_rel: tuple
    stage_rel: tuple
    page_h1: str
    ownership_marker: str
    intro_line: str
    leadin_prefix: str
    leadin_placeholder: str
    uncategorized: str
    count_key: str          # envelope data key for the page count
    count_label: str        # stage-header label (`<label>=<n>`)
    index_display: str      # human path in the stage header
    writer_name: str        # script name in the stage header (byte-stable)
    theme_fn: Callable      # (slug, text, source_theme, theme_order) -> theme|None
    summary_fn: Callable     # (text, title) -> str


def _collapse(text: str) -> str:
    """Collapse internal whitespace runs (incl. newlines) to single spaces."""
    return re.sub(r"\s+", " ", text).strip()


# --- theme assignment strategies ----------------------------------------------


def _concept_sources(page_text: str) -> "list[str]":
    """Backing source slugs for a page: its `sources:` frontmatter list
    (`- wiki://<slug>`), which concept-store.py renders as exactly the union of
    the page's claims' backlinks. Returns [] when the block is absent."""
    m = re.match(
        r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)",
        page_text or "",
        re.DOTALL,
    )
    if not m:
        return []
    slugs: list = []
    in_sources = False
    for line in m.group(1).splitlines():
        if re.match(r"^sources:[ \t]*$", line):
            in_sources = True
            continue
        if in_sources:
            sm = _SOURCE_FM_RE.match(line)
            if sm:
                if sm.group(1) not in slugs:
                    slugs.append(sm.group(1))
                continue
            # A non-list, non-blank line at column 0 ends the block.
            if line[:1] not in (" ", "\t") and line.strip() != "":
                in_sources = False
    return slugs


def theme_via_backing_sources(
    slug: str,
    text: str,
    source_theme: dict,
    theme_order: "list[str]",
) -> Optional[str]:
    """Majority theme across a page's backing sources; ties broken by portal
    heading order (earliest in `wiki/index.md` wins). Returns None when no
    backing source resolves to a theme (→ Uncategorized). Used by the four
    distilled types + synthesis (all of which carry a `sources:` wiki:// list)."""
    counts: dict = {}
    for s in _concept_sources(text):
        theme = source_theme.get(s)
        if theme:
            counts[theme] = counts.get(theme, 0) + 1
    if not counts:
        return None
    best_n = max(counts.values())
    tied = [t for t, n in counts.items() if n == best_n]
    if len(tied) == 1:
        return tied[0]
    return min(
        tied,
        key=lambda t: (theme_order.index(t) if t in theme_order else len(theme_order), t),
    )


def theme_via_own_slug(
    slug: str,
    text: str,
    source_theme: dict,
    theme_order: "list[str]",
) -> Optional[str]:
    """A source page carries an authoritative `theme_label:` frontmatter field
    (written at ingest), so its theme is a direct read of its OWN page — no
    portal round-trip, mirroring `theme_via_frontmatter`. Falls back to the
    portal/`source_theme` map for legacy source pages finalized before the
    curated-root migration (when membership lived in root portal bullets). Used
    by the `source` type."""
    label = frontmatter_scalar(text, "theme_label")
    if label and label.strip():
        return _collapse(label)
    return source_theme.get(slug)


def theme_via_frontmatter(
    slug: str,
    text: str,
    source_theme: dict,
    theme_order: "list[str]",
) -> Optional[str]:
    """The page carries an authoritative `theme_label:` frontmatter field
    (question-store.py writes it on every `type: question` node) — the cleanest
    theme signal, no portal round-trip. Used by the `question` type."""
    label = frontmatter_scalar(text, "theme_label")
    return _collapse(label) if label and label.strip() else None


# --- one-line summary strategies ----------------------------------------------


def summary_distilled(text: str, title: str) -> str:
    """One-line summary for a concept/entity/summary/learning bullet: the first
    non-heading prose line of the SUMMARY machine block, else the first distilled
    claim's text, else the title."""
    inner = extract_machine_block(text, "SUMMARY")
    if inner:
        for raw in inner.splitlines():
            line = raw.strip()
            if line and not line.startswith("#"):
                return _collapse(line)
    claims = parse_distilled_claims(text)
    if claims:
        ctext = (claims[0].get("text") or "").strip()
        if ctext:
            return _collapse(ctext)
    return _collapse(title) if title else ""


def summary_source(text: str, title: str) -> str:
    """One-line summary for a source bullet: the first pre-extracted claim's
    text (the most informative one-liner, since the title already renders via
    the `[[slug]]` wikilink), else the title."""
    claims = parse_pre_extracted_claims(text)
    if claims:
        ctext = (claims[0].get("text") or "").strip()
        if ctext:
            return _collapse(ctext)
    return _collapse(title) if title else ""


def summary_title(text: str, title: str) -> str:
    """One-line summary = the page title. Used by `question` (the title IS the
    query text) and `synthesis` (the title IS the research topic)."""
    return _collapse(title) if title else ""


# --- the six type configs -----------------------------------------------------


def _make_cfg(
    type_name: str,
    page_h1: str,
    intro_line: str,
    theme_fn: Callable,
    summary_fn: Callable,
    *,
    count_key: str = "page_count",
    writer_name: str = "sub_index.py",
) -> TypeConfig:
    """Build a TypeConfig, deriving the eight mechanical fields from `type_name`
    (the wiki dir == the type name for all six types): the dir/index/stage
    paths, the `MACHINE-OWNED:<TYPE>-INDEX` marker, the `<TYPE>-LEADIN:` prefix,
    the lead-in placeholder + Uncategorized label, the stage-header display path,
    and the count label. Only the genuinely per-type values are passed in;
    `concepts` additionally overrides `count_key`/`writer_name` to stay
    byte-stable with the legacy concepts_index.py (envelope key `concept_count`,
    stage header naming `concepts_index.py`)."""
    upper = type_name.upper()
    return TypeConfig(
        type_name=type_name,
        dir_rel=("wiki", type_name),
        index_rel=("wiki", type_name, "index.md"),
        stage_rel=(".cogni-wiki", f"{type_name}-index-proposed.md"),
        page_h1=page_h1,
        ownership_marker=f"<!-- MACHINE-OWNED:{upper}-INDEX -->",
        intro_line=intro_line,
        leadin_prefix=f"{upper}-LEADIN:",
        leadin_placeholder=f"_This theme groups the {type_name} below._",
        uncategorized="Uncategorized",
        count_key=count_key,
        count_label=type_name,
        index_display=f"wiki/{type_name}/index.md",
        writer_name=writer_name,
        theme_fn=theme_fn,
        summary_fn=summary_fn,
    )


REGISTRY: "dict[str, TypeConfig]" = {
    # `concepts` is byte-stable with the legacy concepts_index.py output via the
    # two explicit overrides (the derived marker/prefix/paths already match).
    "concepts": _make_cfg(
        "concepts", "# Concepts",
        "_Auto-generated concept map. Per-theme lead-ins are narrated by the "
        "concepts-outliner; concept bullets are regenerated on each finalize._",
        theme_via_backing_sources, summary_distilled,
        count_key="concept_count", writer_name="concepts_index.py",
    ),
    "entities": _make_cfg(
        "entities", "# Entities",
        "_Auto-generated entity map. Per-theme lead-ins are narrated by the "
        "engine; entity bullets are regenerated on each finalize._",
        theme_via_backing_sources, summary_distilled,
    ),
    "people": _make_cfg(
        "people", "# People",
        "_Auto-generated people map. Per-theme lead-ins are narrated by the "
        "engine; person bullets are regenerated on each finalize._",
        theme_via_backing_sources, summary_distilled,
    ),
    "sources": _make_cfg(
        "sources", "# Sources",
        "_Auto-generated source map. Per-theme lead-ins are narrated by the "
        "engine; source bullets are regenerated on each ingest._",
        theme_via_own_slug, summary_source,
    ),
    "questions": _make_cfg(
        "questions", "# Research questions",
        "_Auto-generated research-question map. Per-theme lead-ins are narrated "
        "by the engine; question bullets are regenerated on each ingest._",
        theme_via_frontmatter, summary_title,
    ),
    "syntheses": _make_cfg(
        "syntheses", "# Syntheses",
        "_Auto-generated synthesis map. Per-theme lead-ins are narrated by the "
        "engine; synthesis bullets are regenerated on each finalize._",
        theme_via_backing_sources, summary_title,
    ),
}


# --- envelope + lock ----------------------------------------------------------


def _emit(success: bool, data: Optional[dict] = None, error: str = "") -> int:
    """Print the `{success, data, error}` envelope; return a shell exit code."""
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _import_wiki_lock(wiki_scripts_dir: str):
    """Import `_wiki_lock` from cogni-wiki's `_wikilib`, or return an error.
    Returns `(_wiki_lock, None)` on success or `(None, error_message)` so the
    caller emits a fail-soft envelope instead of crashing."""
    wiki_scripts = Path(wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return None, f"wiki-scripts dir not found: {wiki_scripts}"
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock  # noqa: E402
    except Exception as exc:  # ImportError or anything the module raises
        return None, f"could not import _wiki_lock from {wiki_scripts}: {exc}"
    return _wiki_lock, None


# --- theme membership from wiki/index.md --------------------------------------


def _parse_portal_themes(portal_text: str) -> "tuple[dict, list]":
    """Walk `wiki/index.md`, returning `(source_slug -> theme_label,
    [theme_label, ...])`.

    `theme_order` is EVERY `## <theme>` heading in document order — the curated
    root map keeps its theme headings even after the per-page bullets move into
    the sub-indexes, so section ORDER is read from the surviving headings rather
    than from bullet presence. `source_theme` records the source slugs named by
    any per-theme bullet list items still present — the LEGACY membership signal
    for bases finalized before the curated-root migration (a curated root has no
    such bullets, so this map comes back empty and frontmatter membership takes
    over; see `_source_themes_from_frontmatter`). The FIRST theme a source is
    seen under wins."""
    source_theme: dict = {}
    theme_order: list = []
    current_theme: Optional[str] = None
    for line in (portal_text or "").splitlines():
        hm = _THEME_HEADING_RE.match(line)
        if hm:
            current_theme = _collapse(hm.group(1))
            if current_theme not in theme_order:
                theme_order.append(current_theme)
            continue
        if current_theme is None:
            continue
        sm = _SOURCE_BULLET_RE.match(line)
        if sm:
            slug = sm.group(1)
            if slug not in source_theme:
                source_theme[slug] = current_theme
    return source_theme, theme_order


def _source_themes_from_frontmatter(wiki_root: Path) -> dict:
    """Build `source_slug -> theme_label` by reading each `wiki/sources/<slug>.md`
    page's authoritative `theme_label:` frontmatter — the curated-root membership
    signal (the per-page bullets that used to carry it have moved off the root
    portal into the sub-indexes). Returns `{}` when the sources dir is absent or
    no page carries the field (a fully-legacy base, where the portal-bullet
    fallback in `_parse_portal_themes` still applies). This is the source side of
    the same on-page signal `theme_via_backing_sources` consumes for the
    distilled types."""
    out: dict = {}
    sources_dir = wiki_root.joinpath("wiki", "sources")
    if not sources_dir.is_dir():
        return out
    for page in sorted(sources_dir.glob("*.md")):
        if page.name == "index.md":
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        label = frontmatter_scalar(text, "theme_label")
        if label and label.strip():
            out[page.stem] = _collapse(label)
    return out


# --- page assembly ------------------------------------------------------------


def _gather_pages(
    cfg: TypeConfig,
    pages_dir: Path,
    source_theme: dict,
    theme_order: "list[str]",
) -> "list[dict]":
    """Read every `wiki/<type>/*.md` except `index.md`, returning
    `[{slug, title, theme, summary}, ...]` sorted by slug (deterministic). The
    per-type `theme_fn` / `summary_fn` capture the only axes that vary by type."""
    out: list = []
    for page in sorted(pages_dir.glob("*.md")):
        if page.name == "index.md":
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        slug = page.stem
        title = frontmatter_scalar(text, "title") or slug
        out.append({
            "slug": slug,
            "title": title,
            "theme": cfg.theme_fn(slug, text, source_theme, theme_order),
            "summary": cfg.summary_fn(text, title),
        })
    out.sort(key=lambda c: c["slug"])
    return out


def _leadin_name(cfg: TypeConfig, theme_label: str, used: "dict") -> str:
    """Stable per-theme lead-in block name `<TYPE>-LEADIN:<theme-slug>`,
    de-duplicated if two labels slugify the same."""
    base = slugify(theme_label) or "theme"
    name = base
    n = 2
    while name in used:
        name = f"{base}-{n}"
        n += 1
    used[name] = theme_label
    return cfg.leadin_prefix + name


def _render_leadin(name: str, inner: str) -> str:
    """A stamp-free `MACHINE-OWNED:<name>` lead-in span (idempotent: no date)."""
    return (
        f"<!-- MACHINE-OWNED:{name}:START -->\n"
        f"{inner}\n"
        f"<!-- MACHINE-OWNED:{name}:END -->"
    )


def _build_page(
    cfg: TypeConfig,
    pages: "list[dict]",
    theme_order: "list[str]",
    existing_text: str,
) -> str:
    """Assemble the full proposed `wiki/<type>/index.md` text.

    Themes render in portal order; a trailing `## Uncategorized` collects pages
    with no resolvable theme. Each section carries a per-theme lead-in span whose
    inner is CARRIED FORWARD verbatim from `existing_text` when already present
    (so the narrator's prose is never clobbered) and a stable placeholder
    otherwise. Bullets within a section are sorted by slug."""
    buckets: dict = {}
    for c in pages:
        theme = c["theme"] or cfg.uncategorized
        buckets.setdefault(theme, []).append(c)

    ordered: list = [t for t in theme_order if t in buckets and t != cfg.uncategorized]
    extras = sorted(t for t in buckets if t not in theme_order and t != cfg.uncategorized)
    ordered.extend(extras)
    if cfg.uncategorized in buckets:
        ordered.append(cfg.uncategorized)

    used_names: dict = {}
    parts: list = [cfg.page_h1, cfg.ownership_marker, "", cfg.intro_line, ""]
    for theme in ordered:
        name = _leadin_name(cfg, theme, used_names)
        carried = extract_machine_block(existing_text, name)
        inner = carried if carried is not None else cfg.leadin_placeholder
        parts.append(f"## {theme}")
        parts.append("")
        parts.append(_render_leadin(name, inner))
        parts.append("")
        for c in sorted(buckets[theme], key=lambda x: x["slug"]):
            summary = c["summary"]
            bullet = f"- {summary} [[{c['slug']}]]" if summary else f"- [[{c['slug']}]]"
            parts.append(bullet)
        parts.append("")
    return "\n".join(parts).rstrip() + "\n"


def _is_human_page(cfg: TypeConfig, existing_text: str) -> bool:
    """An existing index.md with content but NO ownership marker is a
    hand-authored page the renderer must not touch."""
    return bool(existing_text.strip()) and cfg.ownership_marker not in existing_text


def _assemble(cfg: TypeConfig, wiki_root: Path, existing_text: str) -> str:
    """Pure read+build: parse the portal themes and pages off disk and assemble
    the full proposed `index.md` text against `existing_text` (so an
    already-authored lead-in is carried forward)."""
    portal_path = wiki_root.joinpath(*PORTAL_INDEX_REL)
    portal_text = portal_path.read_text(encoding="utf-8") if portal_path.is_file() else ""
    portal_source_theme, theme_order = _parse_portal_themes(portal_text)
    # Frontmatter-resident membership is authoritative; the portal-bullet map is
    # the legacy fallback for source pages written before the curated-root
    # migration. A curated root carries no per-page bullets, so `portal_source_theme`
    # is empty there and the frontmatter map is the only signal.
    source_theme = dict(portal_source_theme)
    source_theme.update(_source_themes_from_frontmatter(wiki_root))
    pages_dir = wiki_root.joinpath(*cfg.dir_rel)
    pages = _gather_pages(cfg, pages_dir, source_theme, theme_order) if pages_dir.is_dir() else []
    return _build_page(cfg, pages, theme_order, existing_text)


def _gather_count(pages_dir: Path) -> int:
    """Count of pages (excluding the index.md the renderer owns)."""
    if not pages_dir.is_dir():
        return 0
    return sum(1 for p in pages_dir.glob("*.md") if p.name != "index.md")


def theme_counts(cfg: TypeConfig, wiki_root: Path) -> "dict[str, int]":
    """Per-theme page counts `{theme_label: n}` for one type, themes in the same
    order `_build_page` renders them (portal heading order, then alphabetical
    extras, then a trailing `Uncategorized`); only themes with ≥1 page appear.

    This reads the portal + pages and buckets via the SAME `cfg.theme_fn` the
    renderer uses, so the count the curated root MAP shows for a (theme, type)
    pair can never drift from the bullets `render`/`stage` would file under that
    theme in `wiki/<type>/index.md`. The root-index renderer consumes this
    directly (in-process import) and the `counts` subcommand exposes it on the
    CLI for testing."""
    portal_path = wiki_root.joinpath(*PORTAL_INDEX_REL)
    portal_text = portal_path.read_text(encoding="utf-8") if portal_path.is_file() else ""
    portal_source_theme, theme_order = _parse_portal_themes(portal_text)
    source_theme = dict(portal_source_theme)
    source_theme.update(_source_themes_from_frontmatter(wiki_root))
    pages_dir = wiki_root.joinpath(*cfg.dir_rel)
    pages = _gather_pages(cfg, pages_dir, source_theme, theme_order) if pages_dir.is_dir() else []

    buckets: dict = {}
    for c in pages:
        theme = c["theme"] or cfg.uncategorized
        buckets[theme] = buckets.get(theme, 0) + 1

    ordered: list = [t for t in theme_order if t in buckets and t != cfg.uncategorized]
    ordered.extend(sorted(t for t in buckets if t not in theme_order and t != cfg.uncategorized))
    if cfg.uncategorized in buckets:
        ordered.append(cfg.uncategorized)
    return {t: buckets[t] for t in ordered}


def _prepare(cfg: TypeConfig, wiki_root_arg: str) -> "tuple[Optional[dict], Optional[str]]":
    """Shared read+assemble for both subcommands. Returns `(payload, error)`
    where payload carries `wiki_root`, `index_path`, `existing_text`,
    `proposed`, `page_count`, `theme_count`. Never writes."""
    wiki_root = Path(wiki_root_arg).resolve()
    if not (wiki_root / "wiki").is_dir():
        return None, f"wiki_root has no wiki/ dir: {wiki_root}"
    index_path = wiki_root.joinpath(*cfg.index_rel)

    existing_text = ""
    if index_path.is_file():
        try:
            existing_text = index_path.read_text(encoding="utf-8")
        except OSError as exc:
            return None, f"{cfg.type_name} index not readable: {exc}"

    pages_dir = wiki_root.joinpath(*cfg.dir_rel)
    proposed = _assemble(cfg, wiki_root, existing_text)
    theme_count = proposed.count("\n## ") + (1 if proposed.startswith("## ") else 0)
    return {
        "wiki_root": wiki_root,
        "index_path": index_path,
        "existing_text": existing_text,
        "proposed": proposed,
        "page_count": _gather_count(pages_dir),
        "theme_count": theme_count,
    }, None


# --- public render / stage entry points (called by concepts_index.py too) -----


def render_index(cfg: TypeConfig, wiki_root_arg: str, wiki_scripts_dir: str) -> int:
    """`render` subcommand body for one type. Locked, atomic, idempotent,
    no-clobber. Returns a shell exit code (and prints the envelope)."""
    _wiki_lock, err = _import_wiki_lock(wiki_scripts_dir)
    if err:
        return _emit(False, error=err)
    payload, err = _prepare(cfg, wiki_root_arg)
    if err:
        return _emit(False, error=err)
    index_path = payload["index_path"]
    existing_text = payload["existing_text"]
    proposed = payload["proposed"]

    if _is_human_page(cfg, existing_text):
        return _emit(True, data={
            "path": str(index_path),
            "subcommand": "render",
            "changed": False,
            "skipped_human_page": True,
        })

    changed = False
    try:
        with _wiki_lock(payload["wiki_root"]):
            # Re-read under the lock so a concurrent writer can't be clobbered.
            current = ""
            if index_path.is_file():
                current = index_path.read_text(encoding="utf-8")
            if _is_human_page(cfg, current):
                return _emit(True, data={
                    "path": str(index_path),
                    "subcommand": "render",
                    "changed": False,
                    "skipped_human_page": True,
                })
            # Rebuild against the locked-read text so a lead-in authored between
            # the unlocked _prepare read and now is still carried forward.
            if current != existing_text:
                proposed = _assemble(cfg, payload["wiki_root"], current)
            changed = proposed != current
            if changed:
                index_path.parent.mkdir(parents=True, exist_ok=True)
                atomic_write_text(index_path, proposed)
    except OSError as exc:
        return _emit(False, error=f"{cfg.type_name} index write failed: {exc}")

    return _emit(True, data={
        "path": str(index_path),
        "subcommand": "render",
        "changed": changed,
        cfg.count_key: payload["page_count"],
        "theme_count": payload["theme_count"],
    })


def stage_index(cfg: TypeConfig, wiki_root_arg: str) -> int:
    """`stage` subcommand body for one type. Lock-free; never touches the live
    page. Returns a shell exit code (and prints the envelope)."""
    payload, err = _prepare(cfg, wiki_root_arg)
    if err:
        return _emit(False, error=err)
    stage_path = payload["wiki_root"].joinpath(*cfg.stage_rel)
    live = payload["existing_text"]
    proposed = payload["proposed"]
    would_change = (not _is_human_page(cfg, live)) and (proposed != live)
    header = (
        f"<!-- staged proposal for {cfg.index_display} — written by "
        f"{cfg.writer_name} stage; NOT the live page -->\n"
        f"<!-- status: {'would-update' if would_change else 'no-change'}; "
        f"{cfg.count_label}={payload['page_count']}; themes={payload['theme_count']}; "
        f"live-is-human-page={str(_is_human_page(cfg, live)).lower()} -->\n\n"
    )
    try:
        stage_path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_text(stage_path, header + proposed)
    except OSError as exc:
        return _emit(False, error=f"staged proposal write failed: {exc}")
    return _emit(True, data={
        "path": str(stage_path),
        "subcommand": "stage",
        "would_change": would_change,
        cfg.count_key: payload["page_count"],
        "theme_count": payload["theme_count"],
    })


# --- CLI ----------------------------------------------------------------------


def _resolve_cfg(type_name: str) -> "tuple[Optional[TypeConfig], Optional[str]]":
    cfg = REGISTRY.get(type_name)
    if cfg is None:
        known = ", ".join(sorted(REGISTRY))
        return None, f"unknown --type {type_name!r}; known types: {known}"
    return cfg, None


def cmd_render(args) -> int:
    cfg, err = _resolve_cfg(args.type)
    if err:
        return _emit(False, error=err)
    return render_index(cfg, args.wiki_root, args.wiki_scripts_dir)


def cmd_stage(args) -> int:
    cfg, err = _resolve_cfg(args.type)
    if err:
        return _emit(False, error=err)
    return stage_index(cfg, args.wiki_root)


def cmd_counts(args) -> int:
    cfg, err = _resolve_cfg(args.type)
    if err:
        return _emit(False, error=err)
    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")
    counts = theme_counts(cfg, wiki_root)
    return _emit(True, data={
        "type": cfg.type_name,
        "counts": counts,
        "themes": list(counts.keys()),
        "total": sum(counts.values()),
    })


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generic deterministic renderer for wiki/<type>/index.md "
                    "(the per-type machine-owned sub-indexes).",
    )
    sub = parser.add_subparsers(dest="subcommand", required=True)

    rn = sub.add_parser(
        "render",
        help="Write wiki/<type>/index.md live (locked, atomic, idempotent, "
             "no-clobber).",
    )
    rn.add_argument("--type", required=True, choices=sorted(REGISTRY),
                    help="The wiki page type to render an index for.")
    rn.add_argument("--wiki-root", required=True)
    rn.add_argument("--wiki-scripts-dir", required=True,
                    help="cogni-wiki wiki-ingest/scripts dir (for _wiki_lock).")
    rn.set_defaults(func=cmd_render)

    st = sub.add_parser(
        "stage",
        help="Write the proposed page to "
             "<wiki-root>/.cogni-wiki/<type>-index-proposed.md without the lock "
             "and without touching the live page.",
    )
    st.add_argument("--type", required=True, choices=sorted(REGISTRY),
                    help="The wiki page type to stage an index for.")
    st.add_argument("--wiki-root", required=True)
    st.set_defaults(func=cmd_stage)

    ct = sub.add_parser(
        "counts",
        help="Emit per-theme {theme: n} page counts for one type as JSON "
             "(the curated root MAP's count source; same theme assignment as "
             "render/stage, so the root counts can't drift from the sub-index).",
    )
    ct.add_argument("--type", required=True, choices=sorted(REGISTRY),
                    help="The wiki page type to count pages per theme for.")
    ct.add_argument("--wiki-root", required=True)
    ct.set_defaults(func=cmd_counts)

    return parser


def main(argv: Optional["list[str]"] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
