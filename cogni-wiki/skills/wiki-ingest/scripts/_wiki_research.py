#!/usr/bin/env python3
"""
_wiki_research.py — shared helpers for reading cogni-research projects from
cogni-wiki scripts.

Both `wiki-ingest/scripts/batch_builder.py` (discovery → research mode) and
`wiki-refresh/scripts/refresh_planner.py` (stale-page refresh loop) need the
same primitives:

  - resolve a research project from a slug or absolute path,
  - read the sub-question manifest,
  - read a single cogni-research entity file,
  - unquote YAML scalars and strip wikilink syntax,
  - parse ISO dates.

Lifting them here removes the byte-for-byte duplication CLAUDE.md called out
under §"wiki-refresh stale-page loop" ("The entity-loading helpers in
refresh_planner.py mirror those in batch_builder.py — known tech debt").

stdlib-only.
"""

from __future__ import annotations

import datetime as dt
from pathlib import Path

# `parse_frontmatter` and `fail` live in `_wikilib`. Importing them keeps this
# module self-contained for callers who only need the research helpers.
from _wikilib import fail, parse_frontmatter, split_frontmatter


def unquote(s: str) -> str:
    """Strip surrounding single or double quotes from a YAML scalar."""
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in ('"', "'"):
        return s[1:-1]
    return s


def strip_wikilink(ref: str) -> str:
    """`[[01-contexts/data/ctx-foo-12345678]]` → `ctx-foo-12345678`.

    Tolerant of surrounding quotes — cogni-research's create-entity.py emits
    quoted wikilinks because YAML treats `[[…]]` as a flow-sequence start
    otherwise. The frontmatter parser keeps the quotes verbatim.
    """
    inner = unquote(ref)
    if inner.startswith("[[") and inner.endswith("]]"):
        inner = inner[2:-2]
    return inner.rsplit("/", 1)[-1]


def parse_date(s: str):
    """ISO `YYYY-MM-DD` → `date`; returns `None` on any parse failure."""
    try:
        return dt.datetime.strptime(s.strip(), "%Y-%m-%d").date()
    except (ValueError, AttributeError):
        return None


def read_research_entity(path: Path) -> "tuple[dict, str]":
    """Read a cogni-research entity .md → (frontmatter dict, body text).

    cogni-research entities use the same YAML-subset shape as wiki pages
    (top-level scalars + `- ` list items), so `_wikilib.parse_frontmatter`
    handles the shapes that matter here.
    """
    text = path.read_text(encoding="utf-8")
    fm, body = split_frontmatter(text)
    return fm, body.lstrip("\n")


def locate_research_project(slug_or_path: str, wiki_root: Path, override: str | None) -> Path:
    """Resolve a research slug or path to a project directory.

    Lookup order:
      1. `override` if given (must point at the project dir directly).
      2. `slug_or_path` itself if it contains a path separator (relative to
         cwd, then absolute).
      3. `<workspace>/cogni-research-<slug>/` where workspace = wiki_root.parent.
      4. `<wiki_root>/cogni-research-<slug>/` (e.g. wiki sits at workspace root).
    On failure: emits the candidates checked so the user can correct the
    layout, then `fail()`s (which exits — `return Path()` is unreachable).
    """
    if override:
        project = Path(override).resolve()
        if not project.is_dir():
            fail(f"--research-root not a directory: {project}")
        return project

    if "/" in slug_or_path or slug_or_path.startswith("."):
        candidate = Path(slug_or_path).resolve()
        if candidate.is_dir():
            return candidate
        fail(f"--research path not found: {candidate}")

    candidates = [
        wiki_root.parent / f"cogni-research-{slug_or_path}",
        wiki_root / f"cogni-research-{slug_or_path}",
    ]
    for c in candidates:
        if c.is_dir():
            return c.resolve()
    fail(
        "cogni-research project not found. Tried: "
        + ", ".join(str(c) for c in candidates)
        + ". Pass --research-root to override."
    )
    return Path()  # unreachable


def load_sub_questions(project: Path) -> "list[dict]":
    """Read all `00-sub-questions/data/sq-*.md` → list ordered by section_index.

    Each entry: `{id, query, parent_topic, section_index, status}` — the
    minimum surface both batch_builder (synthesis materialisation) and
    refresh_planner (stale-page matching) consume.
    """
    sq_dir = project / "00-sub-questions" / "data"
    if not sq_dir.is_dir():
        fail(f"sub-questions dir missing: {sq_dir}")
    items: list = []
    for path in sorted(sq_dir.glob("sq-*.md")):
        text = path.read_text(encoding="utf-8")
        fm = parse_frontmatter(text)
        if not fm.get("query"):
            continue
        try:
            section_index = int(fm.get("section_index", 0))
        except (TypeError, ValueError):
            section_index = 0
        items.append({
            "id": unquote(fm.get("dc:identifier") or path.stem),
            "query": unquote(fm["query"]),
            "parent_topic": unquote(fm.get("parent_topic", "")),
            "section_index": section_index,
            "status": unquote(fm.get("status", "")),
        })
    items.sort(key=lambda x: (x["section_index"], x["id"]))
    return items


def find_wiki_root(start: Path) -> Path:
    """Walk up from `start` looking for `.cogni-wiki/config.json`."""
    current = start.resolve()
    while True:
        if (current / ".cogni-wiki" / "config.json").is_file():
            return current
        if current.parent == current:
            fail(
                f"not inside a cogni-wiki (no .cogni-wiki/config.json at or above {start})"
            )
        current = current.parent
