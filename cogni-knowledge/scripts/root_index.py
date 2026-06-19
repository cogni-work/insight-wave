#!/usr/bin/env python3
"""root_index.py — curated MAP renderer for the root wiki/index.md portal.

The root-portal sibling of `sub_index.py`. Where `sub_index.py` renders the
per-type sub-indexes (`wiki/<type>/index.md`), this renders the curated **root**
`wiki/index.md` as a progressively-disclosed MAP rather than a flat per-page
bullet dump:

  # <knowledge title>

  <!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START --> … <!-- …:END -->   (the intro)

  <!-- MACHINE-OWNED:ROOT-INDEX -->

  _Curated map …_

  ## <theme>
  <carried PORTAL-LEADIN span or human lead-in, verbatim>
  <!-- MACHINE-OWNED:ROOT-LINKS:START -->
  **Explore:** [Sources (40)](sources/index.md) · [Concepts (12)](concepts/index.md) · …
  <!-- MACHINE-OWNED:ROOT-LINKS:END -->

One section per **real theme** — the union of every page type's theme
membership (`sub_index.theme_counts`, frontmatter-resident since the curated-root
foundation), ordered by the surviving `## <theme>` heading order, then
alphabetical extras, then a trailing `Uncategorized`. Each section drops the
per-page `- [[slug]]` bullets (they live in the per-type sub-indexes now) and
shows a single count-link line linking each per-type sub-index WITH its count
for that theme. Synthesis pages appear as `Syntheses (n)` *within* each theme's
count line (grouped by their backing-source theme, like every distilled type);
the legacy `## Syntheses` and seed `## Categories` container headings are not
themes (no page carries them as a `theme_label`), so they fall away naturally.

**Option A — the vendored engine is never touched.** This is a NEW
cogni-knowledge script; the vendored `wiki_index_update.py` (the per-slug
incremental bullet editor) stays byte-identical, so `test_vendored_engine_parity.sh`
needs no exemption. Per-page bullets are TRANSIENT per run: `knowledge-ingest`
files them under `## <theme>` during ingest, and this renderer drops them as the
final root-shaping step at `knowledge-finalize`. The curated MAP is the resting
state between runs.

**Counts can't drift from the sub-indexes.** The per-(theme, type) counts come
from `sub_index.theme_counts`, the SAME theme-assignment code (`cfg.theme_fn`)
that decides which bullets `render`/`stage` file under each theme in
`wiki/<type>/index.md` — so `Concepts (12)` on the root always matches the 12
concepts the concepts sub-index lists under that theme.

**Idempotent + reflow/collapse-stable.** Re-rendering an unchanged wiki is a
byte-identical no-op (the carried `PORTAL-LEADIN` machine spans — which carry a
date — are preserved verbatim, never regenerated; the `ROOT-LINKS` count spans
are deterministic from disk). The curated MAP carries NO `- [[slug]]` bullets
(so `wiki_index_update.py --reflow-only` has nothing to sort) and unique `##`
headings (so `--collapse-only` has nothing to merge) — it is a fixpoint of the
Step 10.5 `lint --fix=all` passes.

Subcommands:

  - `render` — write `wiki/index.md` live, under `_wiki_lock` + `atomic_write_text`,
               only when the proposed text differs byte-for-byte (no stamp churn).
  - `stage`  — write the proposed page to `<wiki-root>/.cogni-wiki/root-index-proposed.md`
               WITHOUT the lock and WITHOUT touching the live file.

`_wiki_lock` / `_emit` / `_import_wiki_lock` / `theme_counts` / `_parse_portal_themes`
are reused from `sub_index.py`; the transform helpers (`atomic_write_text`,
`extract_machine_block`) from `_knowledge_lib`. Stdlib only, POSIX `render`
(`_wiki_lock` uses `fcntl.flock`); `stage` is lock-free. Python 3.9 floor.

Output is a `{"success": bool, "data": {...}, "error": "..."}` JSON envelope
(pretty-printed with `indent=2`), per the cross-plugin script convention.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write_text,
    extract_machine_block,
)
from sub_index import (  # noqa: E402
    PORTAL_INDEX_REL,
    REGISTRY,
    _emit,
    _import_wiki_lock,
    _parse_portal_themes,
    _SOURCE_BULLET_RE,
    theme_counts,
)

ROOT_INDEX_MARKER = "<!-- MACHINE-OWNED:ROOT-INDEX -->"
ROOT_LINKS_NAME = "ROOT-LINKS"
OVERVIEW_NARRATIVE_NAME = "OVERVIEW-NARRATIVE"
UNCATEGORIZED = "Uncategorized"
DEFAULT_H1 = "# Knowledge Base"
INTRO_LINE = (
    "_Curated map of this knowledge base. Each theme below links to its per-type "
    "sub-indexes with live counts — open one to read the pages._"
)
# A constant cross-theme preamble line linking the derived 5W1H overlay
# (perspectives_index.py renders wiki/perspectives.md). Not a per-theme link, so
# it lives in the preamble, not in TYPE_DISPLAY / the per-theme ROOT-LINKS span.
PERSPECTIVES_LINK_LINE = "_See also: [Perspectives (5W1H)](perspectives.md) — the same pages, re-projected by perspective._"

# Per-theme count line: which types to show, in reading order, with their labels.
# The link target is the per-type sub-index, relative to wiki/index.md.
TYPE_DISPLAY = (
    ("sources", "Sources"),
    ("questions", "Questions"),
    ("concepts", "Concepts"),
    ("entities", "Entities"),
    ("people", "People"),
    ("syntheses", "Syntheses"),
)

_H2_RE = re.compile(r"^##[ \t]+(.+?)[ \t]*$")
# A whole MACHINE-OWNED:ROOT-LINKS span — stripped from a carried section before
# the lead-in is preserved (the span is regenerated deterministically).
_ROOT_LINKS_SPAN_RE = re.compile(
    r"[ \t]*<!--\s*MACHINE-OWNED:ROOT-LINKS:START\s*-->.*?"
    r"<!--\s*MACHINE-OWNED:ROOT-LINKS:END\s*-->[ \t]*\n?",
    re.DOTALL,
)


def _render_span(name: str, inner: str) -> str:
    """A stamp-free `MACHINE-OWNED:<name>` span (idempotent: no date)."""
    return (
        f"<!-- MACHINE-OWNED:{name}:START -->\n"
        f"{inner}\n"
        f"<!-- MACHINE-OWNED:{name}:END -->"
    )


def _split_sections(text: str) -> "tuple[list, list]":
    """Split portal text into `(preamble_lines, [(heading, body_lines), ...])`.

    The preamble is everything before the first `## ` heading (the H1, the
    intro, the OVERVIEW-NARRATIVE block, the ROOT-INDEX marker). Each section is
    a `## <heading>` and its body lines up to the next `## ` (or EOF)."""
    preamble: list = []
    sections: list = []
    cur_head: Optional[str] = None
    cur_body: list = []
    for ln in (text or "").splitlines():
        hm = _H2_RE.match(ln)
        if hm:
            if cur_head is not None:
                sections.append((cur_head, cur_body))
            cur_head = hm.group(1).strip()
            cur_body = []
        elif cur_head is None:
            preamble.append(ln)
        else:
            cur_body.append(ln)
    if cur_head is not None:
        sections.append((cur_head, cur_body))
    return preamble, sections


def _carry_leadin(body_lines: "list[str]") -> "list[str]":
    """The lead-in to preserve for a theme section: the PORTAL-LEADIN machine
    span (carried verbatim, date and all — never regenerated) and/or any human
    lead-in prose, with the regenerated ROOT-LINKS span and every per-page
    `- [[slug]]` source bullet removed. Leading/trailing blank lines trimmed."""
    text = "\n".join(body_lines)
    text = _ROOT_LINKS_SPAN_RE.sub("", text)
    kept = [ln for ln in text.splitlines() if not _SOURCE_BULLET_RE.match(ln)]
    while kept and not kept[0].strip():
        kept.pop(0)
    while kept and not kept[-1].strip():
        kept.pop()
    return kept


def _h1_line(preamble_lines: "list[str]") -> str:
    """The existing `# <title>` H1 (the knowledge title), verbatim, or a
    default. `## ` headings are excluded (already consumed as sections)."""
    for ln in preamble_lines:
        stripped = ln.lstrip()
        if stripped.startswith("# ") and not stripped.startswith("## "):
            return ln.rstrip()
    return DEFAULT_H1


def _is_human_root(existing_text: str) -> bool:
    """A non-empty `index.md` with NO `## ` heading AND no MACHINE-OWNED span at
    all is a hand-authored portal the renderer must not touch. The legacy engine
    root (theme headings + PORTAL-LEADIN spans, no ROOT-INDEX marker yet) is NOT
    a human page — it has both — so it migrates normally."""
    if not existing_text.strip():
        return False
    if ROOT_INDEX_MARKER in existing_text:
        return False
    has_h2 = any(_H2_RE.match(ln) for ln in existing_text.splitlines())
    has_machine = "MACHINE-OWNED:" in existing_text
    return not has_h2 and not has_machine


def _heading_anchor(theme: str) -> str:
    """In-page anchor for a sub-index `## {theme}` heading.

    Each theme's Explore links deep-link into the matching `## <theme>`
    section the sub-indexes render (`sub_index._build_page` emits the raw
    `## {theme}` label). The fragment must match the anchor a Markdown
    renderer derives from that literal heading — lowercase, drop punctuation,
    spaces→hyphens — and NOT `slugify`, which transliterates
    (`Überwachung`→`ueberwachung`, `ß`→`ss`) and so would resolve to no
    heading for non-ASCII (German/European) themes. Unicode letters are kept
    verbatim, matching the GitHub-flavoured-Markdown / Obsidian heading-anchor
    convention. Deterministic, so the curated MAP re-renders byte-identically.
    """
    lowered = (theme or "").strip().lower()
    # Keep Unicode word chars / whitespace / hyphen; drop other punctuation.
    cleaned = re.sub(r"[^\w\s-]", "", lowered, flags=re.UNICODE)
    return re.sub(r"\s+", "-", cleaned).strip("-")


def _build_map(wiki_root: Path, existing_text: str) -> str:
    """Assemble the full proposed curated-MAP `wiki/index.md` text."""
    # Per-(theme, type) counts from the SAME theme assignment as the sub-indexes.
    per_type_counts = {
        tname: theme_counts(REGISTRY[tname], wiki_root) for tname, _ in TYPE_DISPLAY
    }
    theme_set: set = set()
    for counts in per_type_counts.values():
        theme_set |= set(counts)

    _, heading_order = _parse_portal_themes(existing_text)
    ordered = [t for t in heading_order if t in theme_set and t != UNCATEGORIZED]
    ordered += sorted(t for t in theme_set if t not in heading_order and t != UNCATEGORIZED)
    if UNCATEGORIZED in theme_set:
        ordered.append(UNCATEGORIZED)

    preamble, sections = _split_sections(existing_text)
    # Last heading wins on a duplicate (collapse merges those upstream anyway).
    sec_body = {h: b for h, b in sections}

    parts: list = [_h1_line(preamble), ""]
    narrative_inner = extract_machine_block(existing_text, OVERVIEW_NARRATIVE_NAME)
    if narrative_inner is not None:
        parts.append(_render_span(OVERVIEW_NARRATIVE_NAME, narrative_inner))
        parts.append("")
    parts.append(ROOT_INDEX_MARKER)
    parts.append("")
    parts.append(INTRO_LINE)
    parts.append("")
    # Cross-theme link to the derived 5W1H overlay. A constant preamble line (no
    # `- [[slug]]` bullet, no `## ` heading) so it stays a reflow/collapse fixpoint.
    parts.append(PERSPECTIVES_LINK_LINE)
    parts.append("")

    for theme in ordered:
        parts.append(f"## {theme}")
        parts.append("")
        leadin = _carry_leadin(sec_body.get(theme, []))
        if leadin:
            parts.extend(leadin)
            parts.append("")
        # Deep-link each type into THIS theme's `## <theme>` section of the
        # sub-index, so the per-theme Explore line is distinct per theme rather
        # than the shared unfiltered links. Counts still come from theme_counts
        # (no count drift); the anchor is deterministic (idempotent re-render).
        anchor = _heading_anchor(theme)
        links = []
        for tname, label in TYPE_DISPLAY:
            n = per_type_counts[tname].get(theme, 0)
            if n > 0:
                links.append(f"[{label} ({n})]({tname}/index.md#{anchor})")
        link_line = "**Explore:** " + " · ".join(links) if links else "_(no pages yet)_"
        parts.append(_render_span(ROOT_LINKS_NAME, link_line))
        parts.append("")
    return "\n".join(parts).rstrip() + "\n"


def _theme_total(wiki_root: Path, existing_text: str) -> int:
    """Count of `## <theme>` sections the MAP would render (for the envelope)."""
    proposed = _build_map(wiki_root, existing_text)
    return proposed.count("\n## ") + (1 if proposed.startswith("## ") else 0)


def _prepare(wiki_root_arg: str) -> "tuple[Optional[dict], Optional[str]]":
    wiki_root = Path(wiki_root_arg).resolve()
    if not (wiki_root / "wiki").is_dir():
        return None, f"wiki_root has no wiki/ dir: {wiki_root}"
    index_path = wiki_root.joinpath(*PORTAL_INDEX_REL)
    existing = ""
    if index_path.is_file():
        try:
            existing = index_path.read_text(encoding="utf-8")
        except OSError as exc:
            return None, f"root index not readable: {exc}"
    return {
        "wiki_root": wiki_root,
        "index_path": index_path,
        "existing": existing,
        "proposed": _build_map(wiki_root, existing),
    }, None


def cmd_render(args) -> int:
    """`render`: write wiki/index.md live (locked, atomic, idempotent, no-clobber)."""
    _wiki_lock, err = _import_wiki_lock(args.wiki_scripts_dir)
    if err:
        return _emit(False, error=err)
    payload, err = _prepare(args.wiki_root)
    if err:
        return _emit(False, error=err)
    index_path = payload["index_path"]
    wiki_root = payload["wiki_root"]

    if _is_human_root(payload["existing"]):
        return _emit(True, data={
            "path": str(index_path),
            "subcommand": "render",
            "changed": False,
            "skipped_human_page": True,
        })

    changed = False
    theme_total = 0
    try:
        with _wiki_lock(wiki_root):
            current = index_path.read_text(encoding="utf-8") if index_path.is_file() else ""
            if _is_human_root(current):
                return _emit(True, data={
                    "path": str(index_path),
                    "subcommand": "render",
                    "changed": False,
                    "skipped_human_page": True,
                })
            # Rebuild against the locked-read text so a span authored between the
            # unlocked _prepare read and now is carried forward, not clobbered.
            proposed = _build_map(wiki_root, current)
            theme_total = proposed.count("\n## ") + (1 if proposed.startswith("## ") else 0)
            changed = proposed != current
            if changed:
                index_path.parent.mkdir(parents=True, exist_ok=True)
                atomic_write_text(index_path, proposed)
    except OSError as exc:
        return _emit(False, error=f"root index write failed: {exc}")

    return _emit(True, data={
        "path": str(index_path),
        "subcommand": "render",
        "changed": changed,
        "theme_count": theme_total,
    })


def cmd_stage(args) -> int:
    """`stage`: write the proposed root MAP to .cogni-wiki/root-index-proposed.md;
    lock-free, never touches the live page."""
    payload, err = _prepare(args.wiki_root)
    if err:
        return _emit(False, error=err)
    stage_path = payload["wiki_root"].joinpath(".cogni-wiki", "root-index-proposed.md")
    live = payload["existing"]
    proposed = payload["proposed"]
    is_human = _is_human_root(live)
    would_change = (not is_human) and (proposed != live)
    theme_total = proposed.count("\n## ") + (1 if proposed.startswith("## ") else 0)
    header = (
        "<!-- staged proposal for wiki/index.md — written by root_index.py stage; "
        "NOT the live page -->\n"
        f"<!-- status: {'would-update' if would_change else 'no-change'}; "
        f"themes={theme_total}; live-is-human-page={str(is_human).lower()} -->\n\n"
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
        "theme_count": theme_total,
    })


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Curated MAP renderer for the root wiki/index.md portal "
                    "(per-theme sub-index links with counts; no per-page bullets).",
    )
    sub = parser.add_subparsers(dest="subcommand", required=True)

    rn = sub.add_parser(
        "render",
        help="Write wiki/index.md live as a curated MAP (locked, atomic, "
             "idempotent, no-clobber).",
    )
    rn.add_argument("--wiki-root", required=True)
    rn.add_argument("--wiki-scripts-dir", required=True,
                    help="cogni-wiki wiki-ingest/scripts dir (for _wiki_lock).")
    rn.set_defaults(func=cmd_render)

    st = sub.add_parser(
        "stage",
        help="Write the proposed root MAP to "
             "<wiki-root>/.cogni-wiki/root-index-proposed.md without the lock "
             "and without touching the live page.",
    )
    st.add_argument("--wiki-root", required=True)
    st.set_defaults(func=cmd_stage)

    return parser


def main(argv: "Optional[list[str]]" = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
