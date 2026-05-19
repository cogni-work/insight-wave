#!/usr/bin/env python3
"""
lineage-stamp.py — add `derived_from_research: <slug>` to YAML frontmatter
of wiki pages whose `sources:` list points into `raw/research-<slug>/`.

Idempotent: pages that already carry the field are skipped.

Input:
  --wiki-root      absolute path to a cogni-wiki root (the dir holding wiki/ and raw/)
  --research-slug  the cogni-research project slug whose deposit we are stamping

Output (insight-wave envelope):
  {"success": bool, "data": {"stamped": [...], "skipped": [...], "scanned": N}, "error": "..."}

Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

FRONTMATTER_DELIM = "---"
WIKI_DIRNAME = ".cogni-wiki"
WIKI_CONFIG_FILENAME = "config.json"
RESEARCH_RAW_PREFIX = "raw/research-"


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _split_frontmatter(text: str) -> tuple[str, str] | None:
    """Return (frontmatter_block, body) if the file opens with `---\\n...\\n---\\n`.
    Returns None if no frontmatter is present."""
    if not text.startswith(FRONTMATTER_DELIM):
        return None
    # Match opening `---` line, content, closing `---` line. Only the closing
    # line's terminator is consumed — any blank line(s) between frontmatter and
    # body are preserved verbatim in `body`.
    pattern = re.compile(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n", re.DOTALL)
    m = pattern.match(text)
    if not m:
        return None
    fm = m.group(1)
    body = text[m.end():]
    return fm, body


def _frontmatter_has_field(fm: str, field: str) -> bool:
    # Match a top-level key (no leading whitespace).
    return re.search(rf"(?m)^{re.escape(field)}\s*:", fm) is not None


def _sources_reference_research(fm: str, research_dir_token: str) -> bool:
    """Heuristic: any line in the frontmatter contains the token
    `raw/research-<slug>/`. Robust enough for the canonical YAML shapes
    that cogni-wiki emits (`sources:` list-of-strings, list-of-dicts with
    `path:`, or inline strings). We deliberately do not parse YAML to keep
    this stdlib-only and tolerant of cogni-wiki's evolving frontmatter."""
    return research_dir_token in fm


def _insert_lineage_field(fm: str, research_slug: str) -> str:
    """Append `derived_from_research: <slug>` to the frontmatter block."""
    fm_stripped = fm.rstrip("\n")
    return f"{fm_stripped}\nderived_from_research: {research_slug}\n"


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Stamp derived_from_research into deposited wiki page frontmatter.",
        allow_abbrev=False,
    )
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument("--research-slug", required=True)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report what would be stamped without writing.",
    )
    args = parser.parse_args(argv)

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / WIKI_DIRNAME / WIKI_CONFIG_FILENAME).is_file():
        return _emit(False, error=f"not a cogni-wiki root: {wiki_root}")

    research_slug = args.research_slug.strip()
    if not research_slug:
        return _emit(False, error="--research-slug must be non-empty")

    research_dir_token = f"{RESEARCH_RAW_PREFIX}{research_slug}/"
    wiki_dir = wiki_root / "wiki"
    if not wiki_dir.is_dir():
        return _emit(False, error=f"wiki/ subdir missing under {wiki_root}")

    stamped: list[str] = []
    skipped_already: list[str] = []
    skipped_unrelated: list[str] = []
    skipped_no_frontmatter: list[str] = []
    scanned = 0

    for md_path in sorted(wiki_dir.rglob("*.md")):
        if not md_path.is_file():
            continue
        scanned += 1
        rel = md_path.relative_to(wiki_root).as_posix()

        text = md_path.read_text(encoding="utf-8")
        split = _split_frontmatter(text)
        if split is None:
            skipped_no_frontmatter.append(rel)
            continue
        fm, body = split

        if not _sources_reference_research(fm, research_dir_token):
            skipped_unrelated.append(rel)
            continue

        if _frontmatter_has_field(fm, "derived_from_research"):
            # Already stamped (possibly with a different slug — leave alone;
            # multi-research-derived pages are surfaced by Phase 2 cycle-guard).
            skipped_already.append(rel)
            continue

        new_fm = _insert_lineage_field(fm, research_slug)
        new_text = f"{FRONTMATTER_DELIM}\n{new_fm}{FRONTMATTER_DELIM}\n{body}"

        if not args.dry_run:
            md_path.write_text(new_text, encoding="utf-8")
        stamped.append(rel)

    return _emit(
        True,
        data={
            "wiki_root": str(wiki_root),
            "research_slug": research_slug,
            "scanned": scanned,
            "stamped": stamped,
            "skipped_already_stamped": skipped_already,
            "skipped_unrelated": len(skipped_unrelated),
            "skipped_no_frontmatter": len(skipped_no_frontmatter),
            "dry_run": args.dry_run,
        },
    )


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
