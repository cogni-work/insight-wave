#!/usr/bin/env python3
"""
prefill_foundations.py — copy curated foundation pages into a wiki's
`wiki/concepts/` directory.

Issue #224 / cogni-wiki Tier 2 item #4. Foundations are canonical concept
pages (Porter's Five Forces, Jobs-to-be-Done, MECE, …) that every wiki
re-derives today from whatever source the user happens to drop in `raw/`
first. Pre-seeding them stops concept duplication for textbook material
and gives downstream pages a stable target slug to link into.

The plugin-side library lives at `${CLAUDE_PLUGIN_ROOT}/foundations/`. Each
file is a `type: concept` page with `foundation: true` frontmatter and
literal `{{PREFILL_DATE}}` placeholders for `created:` / `updated:`. This
script substitutes today's ISO date at copy time, then never rewrites the
page on idempotent re-runs.

Output contract (standard {success, data, error} JSON line on stdout):

    {"success": true,
     "data": {
       "wiki_root": "<abs path>",
       "filter": "all" | "consulting" | "product" | "strategy" | "list",
       "available": [{"slug": "...", "title": "...", "tags": [...]}, ...],
       "copied":   ["porters-five-forces", ...],
       "skipped_existing": ["mece", ...],
       "failed":   [{"slug": "...", "error": "..."}],
       "entries_count_delta": N,
       "dry_run": false
     },
     "error": ""}

stdlib-only. Python 3.8+. Uses `_wikilib._wiki_lock` to serialise the
existence-check + write loop against concurrent `wiki-ingest` runs sharing
the same wiki root, and routes the `entries_count` bump through
`config_bump.py --delta N` (the same locked code path every other writer
uses).
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "wiki-ingest" / "scripts"))
from _wikilib import (  # noqa: E402
    _wiki_lock,
    atomic_write,
    emit_json,
    fail_if_pre_migration,
)


PLUGIN_ROOT = Path(__file__).resolve().parent.parent.parent.parent
FOUNDATIONS_DIR = PLUGIN_ROOT / "foundations"
CONFIG_BUMP_SCRIPT = (
    PLUGIN_ROOT / "skills" / "wiki-ingest" / "scripts" / "config_bump.py"
)

# Filter sets are tag-based. A foundation belongs to set X iff its frontmatter
# `tags:` contains the matching keyword. `all` accepts everything.
FILTER_TAGS = {
    "consulting": "consulting",
    "product": "product",
    "strategy": "strategy",
}

DATE_PLACEHOLDER = "{{PREFILL_DATE}}"
FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def fail(msg: str) -> None:
    emit_json(False, {}, msg)
    sys.exit(1)


def parse_minimal_frontmatter(text: str) -> dict:
    """Extract `id`, `title`, `type`, and `tags` from a foundation file.

    Foundation files are plugin-authored and follow a fixed shape, so we
    only need a strict subset of YAML — same parser shape as
    `_wikilib._parse_frontmatter_minimal` extended to handle the
    `tags: [a, b]` inline list. Anything else falls through to an empty
    list, which is fine for the filter logic.
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    for line in m.group(1).splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        if ":" not in line or line.startswith(" "):
            continue
        k, _, v = line.partition(":")
        k = k.strip()
        v = v.strip()
        if k == "tags" and v.startswith("[") and v.endswith("]"):
            inner = v[1:-1].strip()
            if inner:
                out[k] = [t.strip() for t in inner.split(",") if t.strip()]
            else:
                out[k] = []
        else:
            out[k] = v
    return out


def list_foundations(foundations_dir: Path) -> list:
    """Return [{slug, title, tags, path}] for every *.md file under
    `foundations/` other than README.md.
    """
    out: list = []
    if not foundations_dir.is_dir():
        return out
    for path in sorted(foundations_dir.glob("*.md")):
        if path.name.lower() == "readme.md":
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as e:
            out.append({"slug": path.stem, "title": path.stem, "tags": [], "path": str(path), "_error": str(e)})
            continue
        fm = parse_minimal_frontmatter(text)
        tags = fm.get("tags") if isinstance(fm.get("tags"), list) else []
        out.append({
            "slug": fm.get("id") or path.stem,
            "title": fm.get("title") or path.stem,
            "tags": tags,
            "path": str(path),
        })
    return out


def filter_foundations(items: list, flt: str) -> list:
    if flt == "all":
        return list(items)
    tag = FILTER_TAGS.get(flt)
    if tag is None:
        return []
    return [it for it in items if tag in (it.get("tags") or [])]


def render_for_target(text: str, prefill_date: str) -> str:
    """Substitute `{{PREFILL_DATE}}` placeholders with today's ISO date."""
    return text.replace(DATE_PLACEHOLDER, prefill_date)


def main() -> None:
    p = argparse.ArgumentParser(
        description="Prefill curated foundation concept pages into a wiki."
    )
    p.add_argument("--wiki-root", help="Path to the wiki root (required unless --list).")
    p.add_argument(
        "--filter",
        default="all",
        choices=["all", "consulting", "product", "strategy"],
        help="Which subset to copy (default: all).",
    )
    p.add_argument(
        "--list",
        action="store_true",
        help="Print the available foundations under the chosen --filter and exit. "
             "No wiki is touched; --wiki-root is optional in this mode.",
    )
    p.add_argument(
        "--dry-run",
        action="store_true",
        help="Compute the plan without writing any file or bumping entries_count.",
    )
    p.add_argument(
        "--foundations-dir",
        help="Override the plugin-side foundations directory (test hook).",
    )
    args = p.parse_args()

    foundations_dir = Path(args.foundations_dir) if args.foundations_dir else FOUNDATIONS_DIR
    if not foundations_dir.is_dir():
        fail(f"foundations directory not found: {foundations_dir}")

    available = list_foundations(foundations_dir)
    selected = filter_foundations(available, args.filter)

    if args.list:
        emit_json(
            True,
            {
                "wiki_root": str(Path(args.wiki_root).resolve()) if args.wiki_root else "",
                "filter": args.filter,
                "available": [
                    {"slug": it["slug"], "title": it["title"], "tags": it["tags"]}
                    for it in selected
                ],
                "copied": [],
                "skipped_existing": [],
                "failed": [],
                "entries_count_delta": 0,
                "dry_run": True,
            },
        )
        return

    if not args.wiki_root:
        fail("--wiki-root is required unless --list is set")

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a wiki: {wiki_root} (missing .cogni-wiki/config.json)")
    fail_if_pre_migration(wiki_root)

    concepts_dir = wiki_root / "wiki" / "concepts"
    concepts_dir.mkdir(parents=True, exist_ok=True)

    today = dt.date.today().isoformat()
    copied: list = []
    skipped: list = []
    failed: list = []

    # Existence check + write loop go inside the wiki lock so a concurrent
    # `wiki-ingest` from another session can't sneak a same-slug page in
    # between our check and our write. The lock is released before
    # config_bump.py runs (it acquires its own).
    with _wiki_lock(wiki_root):
        for it in selected:
            slug = it["slug"]
            target = concepts_dir / f"{slug}.md"
            if target.exists():
                skipped.append(slug)
                continue
            try:
                src_text = Path(it["path"]).read_text(encoding="utf-8")
                rendered = render_for_target(src_text, today)
                if not args.dry_run:
                    atomic_write(target, rendered)
                copied.append(slug)
            except Exception as e:
                failed.append({"slug": slug, "error": str(e)})

    delta = 0 if args.dry_run else len(copied)
    if delta > 0:
        try:
            cb = subprocess.run(
                [
                    sys.executable,
                    str(CONFIG_BUMP_SCRIPT),
                    "--wiki-root",
                    str(wiki_root),
                    "--key",
                    "entries_count",
                    "--delta",
                    str(delta),
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            try:
                cb_json = json.loads(cb.stdout.strip().splitlines()[-1]) if cb.stdout.strip() else {}
            except (ValueError, IndexError):
                cb_json = {}
            if cb.returncode != 0 or not cb_json.get("success"):
                # The pages are already on disk; surface the bump failure but
                # don't unwind. A follow-up `--fix=entries_count_drift` lint
                # run reconciles the count.
                failed.append({
                    "slug": "(entries_count_bump)",
                    "error": cb_json.get("error") or cb.stderr.strip() or "config_bump failed",
                })
                delta = 0
        except OSError as e:
            failed.append({"slug": "(entries_count_bump)", "error": str(e)})
            delta = 0

    emit_json(
        True,
        {
            "wiki_root": str(wiki_root),
            "filter": args.filter,
            "available": [
                {"slug": it["slug"], "title": it["title"], "tags": it["tags"]}
                for it in selected
            ],
            "copied": copied,
            "skipped_existing": skipped,
            "failed": failed,
            "entries_count_delta": delta,
            "dry_run": bool(args.dry_run),
        },
    )


if __name__ == "__main__":
    main()
