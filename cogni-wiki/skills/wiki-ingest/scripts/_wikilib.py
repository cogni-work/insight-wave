#!/usr/bin/env python3
"""
_wikilib.py — shared helpers for cogni-wiki scripts.

Two responsibilities, scoped to this module so the per-type-directory
migration (v0.0.28) doesn't double the surface area for review:

1. The advisory lock context manager `_wiki_lock(wiki_root)`. Previously
   duplicated byte-for-byte in `backlink_audit.py`, `wiki_index_update.py`,
   and `config_bump.py` — see CLAUDE.md "Concurrency Invariant" tech debt
   note. Consolidating here removes the drift risk.

2. The per-type page directory contract (v0.0.28+). Every script that used
   to glob `wiki/pages/*.md` now goes through `iter_pages()` so the layout
   is owned in exactly one place. `resolve_page_path(slug)` is the canonical
   slug → filesystem path lookup; it is cached per `iter_pages()` build so
   reverse lookups inside a `_wiki_lock` block stay O(1).

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import fcntl
import json
import os
import re
import sys
from contextlib import contextmanager
from pathlib import Path


# Ordered so iter_pages() yields a stable per-type traversal regardless of
# filesystem listing order. The 9 valid `type:` values plus the audit dir.
PAGE_TYPE_DIRS = {
    "concept": "concepts",
    "entity": "entities",
    "summary": "summaries",
    "decision": "decisions",
    "interview": "interviews",
    "meeting": "meetings",
    "learning": "learnings",
    "synthesis": "syntheses",
    "note": "notes",
}

# `lint-YYYY-MM-DD.md` and `health-YYYY-MM-DD.md` audit reports live here.
# Directory name is plural to match the page-type pattern (`concepts/` etc).
AUDIT_DIR = "audits"

# Valid `type:` values mirror health.py's VALID_TYPES — kept here so the
# slug→type lookup can validate without importing health.
VALID_TYPES = frozenset(PAGE_TYPE_DIRS.keys())

# Schema version that introduced per-type directories. Wikis with a strictly
# lower version need to run `migrate_layout.py` before any other skill works.
SCHEMA_VERSION_PER_TYPE_DIRS = "0.0.5"

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


@contextmanager
def _wiki_lock(wiki_root: Path):
    """Serialise shared-state writes across concurrent wiki-ingest invocations.

    Issue #84: two batch-mode workers can both apply-plan into the same target
    page, each read-modify-writing without knowing about the other. The later
    `os.replace` silently overwrites the earlier write. This lock serialises
    apply_plan, index updates, and config bumps across workers sharing a wiki
    root; separate wikis do not block each other.

    Identical semantics to the per-script copies it replaces — the lock file
    is `<wiki-root>/.cogni-wiki/.lock`, advisory `fcntl.flock(LOCK_EX)`.
    """
    lock_dir = wiki_root / ".cogni-wiki"
    lock_dir.mkdir(parents=True, exist_ok=True)
    lock_path = lock_dir / ".lock"
    fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            os.close(fd)


def _read_schema_version(wiki_root: Path) -> str:
    p = wiki_root / ".cogni-wiki" / "config.json"
    try:
        cfg = json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return ""
    v = cfg.get("schema_version")
    return str(v) if isinstance(v, str) else ""


def _legacy_pages_present(wiki_root: Path) -> bool:
    """Return True iff the legacy flat `wiki/pages/<slug>.md` layout exists.

    Treats any *.md file directly under `wiki/pages/` as evidence of the
    pre-migration layout. The migrator removes the directory once empty;
    a stray junk file is still surfaced so we never silently operate on a
    half-migrated wiki.
    """
    pages_dir = wiki_root / "wiki" / "pages"
    if not pages_dir.is_dir():
        return False
    try:
        for child in pages_dir.iterdir():
            if child.is_file() and child.suffix == ".md":
                return True
    except OSError:
        return False
    return False


def fail_if_pre_migration(wiki_root: Path) -> None:
    """Hard-fail with the standard `{success, data, error}` JSON if the wiki
    is on the legacy flat layout.

    Every consumer script calls this immediately after resolving `--wiki-root`.
    Graceful-degrade is the wrong call — a half-migrated wiki silently breaks
    the regression-watchlist invariants by giving two truths for "where does
    slug X live."
    """
    if _legacy_pages_present(wiki_root):
        msg = (
            "wiki layout pre-migration: pages found under wiki/pages/ "
            "(per-type directories required since schema_version 0.0.5). "
            "Run: python "
            "<plugin>/skills/wiki-setup/scripts/migrate_layout.py "
            f"--wiki-root {wiki_root} --apply"
        )
        print(json.dumps({"success": False, "data": {}, "error": msg}))
        sys.exit(1)


def type_dir_for(ptype: str) -> str:
    """Return the directory name for a given `type:` value.

    Unknown types raise `KeyError`. Audit reports (`lint-*.md` / `health-*.md`)
    are routed via `AUDIT_DIR` directly by callers — they don't have a
    frontmatter type.
    """
    return PAGE_TYPE_DIRS[ptype]


def resolve_page_path(wiki_root: Path, slug: str, ptype: str) -> Path:
    """Slug + type → filesystem path under the per-type layout."""
    return wiki_root / "wiki" / type_dir_for(ptype) / f"{slug}.md"


def audit_page_path(wiki_root: Path, slug: str) -> Path:
    """Path for a `lint-*.md` or `health-*.md` audit report."""
    return wiki_root / "wiki" / AUDIT_DIR / f"{slug}.md"


def is_audit_slug(slug: str) -> bool:
    return slug.startswith("lint-") or slug.startswith("health-")


def _parse_frontmatter_minimal(text: str) -> dict:
    """Just enough YAML-subset parsing to extract `id` and `type` for the
    in-memory index. Mirrors lint_wiki.py / health.py / extract_page_claims.py
    parsers — kept here to avoid a circular import dependency."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" in line and not line.startswith(" "):
            k, _, v = line.partition(":")
            out[k.strip()] = v.strip()
    return out


def iter_pages(wiki_root: Path, include_audit: bool = False):
    """Yield `(slug, path, ptype)` for every page in the per-type layout.

    Order is stable: dirs traversed in the `PAGE_TYPE_DIRS` declaration order,
    files within each dir sorted by slug. Missing dirs are silently skipped
    (a young wiki may not yet contain every type). When `include_audit=True`,
    `wiki/audits/*.md` is yielded last with `ptype="audit"`.
    """
    wiki_dir = wiki_root / "wiki"
    for ptype, dirname in PAGE_TYPE_DIRS.items():
        d = wiki_dir / dirname
        if not d.is_dir():
            continue
        for path in sorted(d.glob("*.md")):
            yield path.stem, path, ptype
    if include_audit:
        d = wiki_dir / AUDIT_DIR
        if d.is_dir():
            for path in sorted(d.glob("*.md")):
                yield path.stem, path, "audit"


def build_slug_index(wiki_root: Path, include_audit: bool = False) -> dict:
    """One-shot `{slug: (path, ptype)}` map from `iter_pages()`.

    Callers that need many slug→path lookups in one run (backlink_audit,
    health, lint) build this once at start and reuse it. Sub-second on
    100-page wikis (matches health.py's performance contract).
    """
    return {slug: (path, ptype) for slug, path, ptype in iter_pages(wiki_root, include_audit=include_audit)}
