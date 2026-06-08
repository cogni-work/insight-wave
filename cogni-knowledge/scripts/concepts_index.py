#!/usr/bin/env python3
"""concepts_index.py — deterministic renderer for wiki/concepts/index.md.

The standalone `/concepts` outline page: a browsable domain concept map that
enumerates the wiki's concept pages, groups them by theme, and emits one
`## <theme>` section per theme — each with an engine-owned, narrator-authored
lead-in span and a bullet per concept (one-line summary + `[[slug]]` wikilink).

This is the DETERMINISTIC SPINE only. The renderer writes the structure and the
bullets; it never writes lead-in PROSE — it lays down an empty/placeholder
`MACHINE-OWNED:CONCEPTS-LEADIN:<theme>` span that the concepts-outliner agent
fills in later, and it carries an already-authored lead-in forward verbatim on
every re-render so it never clobbers the narrator's prose.

Theme derivation is wiki-resident — it never reads `plan.json` (which lives
per-research-project under `<project>/.metadata/` and is not wiki-resident,
while a concept page accretes claims across many projects). Instead each
concept's backing SOURCE slugs (its `sources:` frontmatter — exactly the union
of its claims' backlinks, per concept-store.py) are looked up in
`wiki/index.md`, where every source bullet sits under its `## <theme>` heading
(filed at ingest via `wiki_index_update.py --category`). A concept is assigned
the MAJORITY theme across its backing sources (ties broken by `wiki/index.md`
heading order); concepts with no resolvable theme go into a single trailing
`## Uncategorized` group so none are dropped.

Subcommands:

  - `render` — write `wiki/concepts/index.md` live, under `_wiki_lock` +
               `atomic_write_text`, only when the full proposed text differs
               byte-for-byte (idempotent: re-running an unchanged wiki is a
               no-op with no stamp/date churn — the lead-in spans are
               stamp-free and there is no date field on the page).
  - `stage`  — write the proposed page to `<wiki-root>/.cogni-wiki/
               concepts-index-proposed.md` WITHOUT the lock and WITHOUT
               touching the live file (single-writer staging area, paralleling
               `portal-proposed.md`).

`_wiki_lock` is imported from cogni-wiki's `_wikilib` via `--wiki-scripts-dir`
(the `concept-store.py` / `overview_update.py` posture) so the live write
serialises on the same `<wiki-root>/.cogni-wiki/.lock` as every other
shared-state wiki write. The transform helpers (`extract_machine_block`,
`upsert_machine_block`, `atomic_write_text`, `frontmatter_scalar`, `slugify`)
are reused verbatim from `_knowledge_lib`.

Fail-soft posture: a missing wiki-scripts dir, a `_wikilib` import failure, a
non-wiki `--wiki-root`, or any write error returns a `{"success": false, ...}`
envelope and writes nothing partial — the caller logs it loudly and never
rolls back.

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
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write_text,
    extract_machine_block,
    frontmatter_scalar,
    parse_distilled_claims,
    slugify,
)

CONCEPTS_DIR_REL = ("wiki", "concepts")
INDEX_REL = ("wiki", "concepts", "index.md")
PORTAL_INDEX_REL = ("wiki", "index.md")
STAGE_REL = (".cogni-wiki", "concepts-index-proposed.md")

PAGE_H1 = "# Concepts"
# Single stable ownership marker emitted right after the H1. Its ABSENCE on an
# existing, non-empty index.md is how the renderer recognises a human-authored
# page and refuses to touch it (mirrors concept-store.py's skipped_human_page
# guard, which keys on the absence of the SUMMARY sentinel).
OWNERSHIP_MARKER = "<!-- MACHINE-OWNED:CONCEPTS-INDEX -->"
INTRO_LINE = (
    "_Auto-generated concept map. Per-theme lead-ins are narrated by the "
    "concepts-outliner; concept bullets are regenerated on each finalize._"
)
LEADIN_PREFIX = "CONCEPTS-LEADIN:"
LEADIN_PLACEHOLDER = "_(theme lead-in pending narration)_"
UNCATEGORIZED = "Uncategorized"

# A source bullet in wiki/index.md: a list item whose first wikilink names the
# source slug, e.g. `- [[some-source]] — title`. Anchored to a list line so a
# `[[wikilink]]` inside a PORTAL-LEADIN prose span is never mistaken for a
# source membership.
_SOURCE_BULLET_RE = re.compile(r"^\s*-\s.*?\[\[([a-z0-9][a-z0-9\-]*)\]\]")
# A level-2 heading line (`## <theme label>`); level-1 (`# `) and level-3+ are
# not theme sections in the portal layout.
_THEME_HEADING_RE = re.compile(r"^##[ \t]+(.+?)[ \t]*$")
# `sources:` frontmatter list entries: `  - wiki://<slug>` (concept-store.py
# renders the backing-source union exactly this way).
_SOURCE_FM_RE = re.compile(r"^\s*-\s*wiki://([a-z0-9][a-z0-9\-]*)\s*$")


def _emit(success: bool, data: Optional[dict] = None, error: str = "") -> int:
    """Print the `{success, data, error}` envelope; return a shell exit code."""
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _import_wiki_lock(wiki_scripts_dir: str):
    """Import `_wiki_lock` from cogni-wiki's `_wikilib`, or return an error.

    Mirrors concept-store.py / overview_update.py: resolve the dir, push it on
    `sys.path`, import. Returns `(_wiki_lock, None)` on success or
    `(None, error_message)` so the caller emits a fail-soft envelope instead of
    crashing.
    """
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

    Splits the portal into `## <theme>` sections (document order) and records,
    per section, the source slugs named by its bullet list items. The theme
    order list preserves the order themes appear in the portal — the concepts
    index renders its sections in the same order. Only sections that actually
    contain ≥1 source bullet contribute a theme (a non-theme `## ` heading with
    no source bullets — e.g. an intro — is naturally skipped). The FIRST theme a
    source is seen under wins, so a stray duplicate bullet can't flip a source's
    theme.
    """
    source_theme: dict = {}
    theme_order: list = []
    current_theme: Optional[str] = None
    for line in (portal_text or "").splitlines():
        hm = _THEME_HEADING_RE.match(line)
        if hm:
            current_theme = hm.group(1).strip()
            continue
        if current_theme is None:
            continue
        sm = _SOURCE_BULLET_RE.match(line)
        if sm:
            slug = sm.group(1)
            if slug not in source_theme:
                source_theme[slug] = current_theme
            if current_theme not in theme_order:
                theme_order.append(current_theme)
    return source_theme, theme_order


def _concept_sources(concept_text: str) -> "list[str]":
    """Backing source slugs for a concept page: its `sources:` frontmatter list
    (`- wiki://<slug>`), which concept-store.py renders as exactly the union of
    the page's claims' backlinks. Returns [] when the block is absent."""
    m = re.match(
        r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)",
        concept_text or "",
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


def _assign_theme(
    source_slugs: "list[str]",
    source_theme: dict,
    theme_order: "list[str]",
) -> Optional[str]:
    """Majority theme across a concept's backing sources; ties broken by portal
    heading order (the theme that appears earliest in `wiki/index.md` wins).
    Returns None when no backing source resolves to a theme (→ Uncategorized)."""
    counts: dict = {}
    for slug in source_slugs:
        theme = source_theme.get(slug)
        if theme:
            counts[theme] = counts.get(theme, 0) + 1
    if not counts:
        return None
    best_n = max(counts.values())
    tied = [t for t, n in counts.items() if n == best_n]
    if len(tied) == 1:
        return tied[0]
    # Tie → earliest by portal heading order; themes absent from theme_order
    # (shouldn't happen, since counts keys come from source_theme values) sort
    # last but stably.
    return min(tied, key=lambda t: (theme_order.index(t) if t in theme_order else len(theme_order), t))


# --- one-line concept summary -------------------------------------------------


def _summary_oneline(concept_text: str, title: str) -> str:
    """One-line summary for a concept bullet: the first non-heading prose line
    of the SUMMARY machine block, else the first distilled claim's text, else
    the title. Whitespace/newlines are collapsed to a single line."""
    inner = extract_machine_block(concept_text, "SUMMARY")
    if inner:
        for raw in inner.splitlines():
            line = raw.strip()
            if line and not line.startswith("#"):
                return _collapse(line)
    claims = parse_distilled_claims(concept_text)
    if claims:
        text = (claims[0].get("text") or "").strip()
        if text:
            return _collapse(text)
    return _collapse(title) if title else ""


def _collapse(text: str) -> str:
    """Collapse internal whitespace runs (incl. newlines) to single spaces."""
    return re.sub(r"\s+", " ", text).strip()


# --- page assembly ------------------------------------------------------------


def _gather_concepts(concepts_dir: Path) -> "list[dict]":
    """Read every `wiki/concepts/*.md` except `index.md`, returning
    `[{slug, title, sources, summary}, ...]` sorted by slug (deterministic)."""
    out: list = []
    for page in sorted(concepts_dir.glob("*.md")):
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
            "sources": _concept_sources(text),
            "summary": _summary_oneline(text, title),
        })
    out.sort(key=lambda c: c["slug"])
    return out


def _leadin_name(theme_label: str, used: "dict") -> str:
    """Stable per-theme lead-in block name `CONCEPTS-LEADIN:<theme-slug>`,
    de-duplicated if two labels slugify the same."""
    base = slugify(theme_label) or "theme"
    name = base
    n = 2
    while name in used:
        name = f"{base}-{n}"
        n += 1
    used[name] = theme_label
    return LEADIN_PREFIX + name


def _render_leadin(name: str, inner: str) -> str:
    """A stamp-free `MACHINE-OWNED:<name>` lead-in span (idempotent: no date)."""
    return (
        f"<!-- MACHINE-OWNED:{name}:START -->\n"
        f"{inner}\n"
        f"<!-- MACHINE-OWNED:{name}:END -->"
    )


def _build_page(
    concepts: "list[dict]",
    source_theme: dict,
    theme_order: "list[str]",
    existing_text: str,
) -> str:
    """Assemble the full proposed `wiki/concepts/index.md` text.

    Themes render in portal order; a trailing `## Uncategorized` collects
    concepts with no resolvable theme. Each section carries a per-theme lead-in
    span whose inner is CARRIED FORWARD verbatim from `existing_text` when
    already present (so the narrator's prose is never clobbered) and a stable
    placeholder otherwise. Concept bullets within a section are sorted by slug.
    """
    # Bucket concepts by theme.
    buckets: dict = {}
    for c in concepts:
        theme = _assign_theme(c["sources"], source_theme, theme_order) or UNCATEGORIZED
        buckets.setdefault(theme, []).append(c)

    # Section order: portal theme order (only themes that have concepts), then
    # any concept-only themes not in the portal (defensive; alpha), then
    # Uncategorized last.
    ordered: list = [t for t in theme_order if t in buckets and t != UNCATEGORIZED]
    extras = sorted(t for t in buckets if t not in theme_order and t != UNCATEGORIZED)
    ordered.extend(extras)
    if UNCATEGORIZED in buckets:
        ordered.append(UNCATEGORIZED)

    used_names: dict = {}
    parts: list = [PAGE_H1, OWNERSHIP_MARKER, "", INTRO_LINE, ""]
    for theme in ordered:
        name = _leadin_name(theme, used_names)
        carried = extract_machine_block(existing_text, name)
        inner = carried if carried is not None else LEADIN_PLACEHOLDER
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


def _is_human_page(existing_text: str) -> bool:
    """An existing index.md with content but NO ownership marker is a
    hand-authored page the renderer must not touch."""
    return bool(existing_text.strip()) and OWNERSHIP_MARKER not in existing_text


def _assemble(wiki_root: Path, existing_text: str) -> str:
    """Pure read+build: parse the portal themes and concept pages off disk and
    assemble the full proposed `index.md` text against `existing_text` (so an
    already-authored lead-in is carried forward). The single assembly path used
    by both the unlocked `_prepare` read and the locked re-read in `cmd_render`."""
    portal_path = wiki_root.joinpath(*PORTAL_INDEX_REL)
    portal_text = portal_path.read_text(encoding="utf-8") if portal_path.is_file() else ""
    source_theme, theme_order = _parse_portal_themes(portal_text)
    concepts_dir = wiki_root.joinpath(*CONCEPTS_DIR_REL)
    concepts = _gather_concepts(concepts_dir) if concepts_dir.is_dir() else []
    return _build_page(concepts, source_theme, theme_order, existing_text)


def _prepare(args) -> "tuple[Optional[dict], Optional[str]]":
    """Shared read+assemble for both subcommands. Returns `(payload, error)`
    where payload carries `wiki_root`, `index_path`, `existing_text`,
    `proposed`, `concept_count`, `theme_count`. Never writes."""
    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return None, f"wiki_root has no wiki/ dir: {wiki_root}"
    index_path = wiki_root.joinpath(*INDEX_REL)

    existing_text = ""
    if index_path.is_file():
        try:
            existing_text = index_path.read_text(encoding="utf-8")
        except OSError as exc:
            return None, f"concepts index not readable: {exc}"

    concepts_dir = wiki_root.joinpath(*CONCEPTS_DIR_REL)
    proposed = _assemble(wiki_root, existing_text)
    theme_count = proposed.count("\n## ") + (1 if proposed.startswith("## ") else 0)
    return {
        "wiki_root": wiki_root,
        "index_path": index_path,
        "existing_text": existing_text,
        "proposed": proposed,
        "concept_count": _gather_count(concepts_dir),
        "theme_count": theme_count,
    }, None


def _gather_count(concepts_dir: Path) -> int:
    """Count of concept pages (excluding the index.md the renderer owns)."""
    if not concepts_dir.is_dir():
        return 0
    return sum(1 for p in concepts_dir.glob("*.md") if p.name != "index.md")


def cmd_render(args) -> int:
    _wiki_lock, err = _import_wiki_lock(args.wiki_scripts_dir)
    if err:
        return _emit(False, error=err)
    payload, err = _prepare(args)
    if err:
        return _emit(False, error=err)
    index_path = payload["index_path"]
    existing_text = payload["existing_text"]
    proposed = payload["proposed"]

    if _is_human_page(existing_text):
        return _emit(True, data={
            "path": str(index_path),
            "subcommand": "render",
            "changed": False,
            "skipped_human_page": True,
        })

    try:
        with _wiki_lock(payload["wiki_root"]):
            # Re-read under the lock so a concurrent writer can't be clobbered.
            current = ""
            if index_path.is_file():
                current = index_path.read_text(encoding="utf-8")
            if _is_human_page(current):
                return _emit(True, data={
                    "path": str(index_path),
                    "subcommand": "render",
                    "changed": False,
                    "skipped_human_page": True,
                })
            # Rebuild against the locked-read text so a lead-in authored between
            # the unlocked _prepare read and now is still carried forward.
            if current != existing_text:
                proposed = _assemble(payload["wiki_root"], current)
            changed = proposed != current
            if changed:
                index_path.parent.mkdir(parents=True, exist_ok=True)
                atomic_write_text(index_path, proposed)
    except OSError as exc:
        return _emit(False, error=f"concepts index write failed: {exc}")

    return _emit(True, data={
        "path": str(index_path),
        "subcommand": "render",
        "changed": changed,
        "concept_count": payload["concept_count"],
        "theme_count": payload["theme_count"],
    })


def cmd_stage(args) -> int:
    payload, err = _prepare(args)
    if err:
        return _emit(False, error=err)
    stage_path = payload["wiki_root"].joinpath(*STAGE_REL)
    live = payload["existing_text"]
    proposed = payload["proposed"]
    would_change = (not _is_human_page(live)) and (proposed != live)
    header = (
        "<!-- staged proposal for wiki/concepts/index.md — written by "
        "concepts_index.py stage; NOT the live page -->\n"
        f"<!-- status: {'would-update' if would_change else 'no-change'}; "
        f"concepts={payload['concept_count']}; themes={payload['theme_count']}; "
        f"live-is-human-page={str(_is_human_page(live)).lower()} -->\n\n"
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
        "concept_count": payload["concept_count"],
        "theme_count": payload["theme_count"],
    })


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Deterministic renderer for wiki/concepts/index.md "
                    "(the standalone /concepts domain concept map).",
    )
    sub = parser.add_subparsers(dest="subcommand", required=True)

    rn = sub.add_parser(
        "render",
        help="Write wiki/concepts/index.md live (locked, atomic, idempotent, "
             "no-clobber).",
    )
    rn.add_argument("--wiki-root", required=True)
    rn.add_argument("--wiki-scripts-dir", required=True,
                    help="cogni-wiki wiki-ingest/scripts dir (for _wiki_lock).")
    rn.set_defaults(func=cmd_render)

    st = sub.add_parser(
        "stage",
        help="Write the proposed page to "
             "<wiki-root>/.cogni-wiki/concepts-index-proposed.md without the "
             "lock and without touching the live page.",
    )
    st.add_argument("--wiki-root", required=True)
    st.set_defaults(func=cmd_stage)

    return parser


def main(argv: Optional["list[str]"] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
