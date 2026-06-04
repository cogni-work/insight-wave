#!/usr/bin/env python3
"""
migrate-question-index.py — one-shot question-node index migration driver.

Question nodes (`wiki/questions/<slug>.md`) carry an authoritative `theme_label:`
in their frontmatter, written by `question-store.py emit`. Historically the
index bullet for each node could land under a flat `## Research questions`
heading instead of under the node's `theme_label` heading. cogni-wiki's locked
`wiki_index_update.py --move-slug` mode (Part A) relocates a single bullet
non-destructively; this driver is the cogni-knowledge half (Part B) that walks
every question node in a base and re-files it once.

For each `wiki/questions/*.md`:
  - Read the page's `theme_label:` frontmatter (always a JSON-quoted scalar on
    disk; decoded with `_knowledge_lib._unquote_scalar`).
  - Skip a node whose `theme_label` is empty (legacy / stopword-only) — passing
    an empty `--to-category` is rejected by the locked script, and there is no
    target heading to move to.
  - Call `wiki_index_update.py --move-slug <slug> --to-category "<theme_label>"`
    where `slug` is the filename stem (the `id == stem` invariant enforced by
    wiki-health). The move preserves the bullet's existing summary verbatim and
    never adds or drops a wikilink.

Idempotent: once a node sits under its `theme_label` heading the move returns
`action: noop`, so a repeat run is a safe no-op. Non-destructive: only existing
bullets are relocated. A node whose slug is not yet in `index.md` (never
indexed) is recorded under `skipped` with the underlying error rather than
aborting the whole run.

`--dry-run` short-circuits before any subprocess call and reports what *would*
move — the locked script's own `--dry-run` applies only to `--reflow-only`, not
to move mode, so the driver cannot delegate the dry run downstream.

The cogni-wiki scripts dir is self-resolved by a Python port of the
`knowledge-ingest` probe (sibling checkout first, else newest numeric version
dir under a versioned-cache install). `--wiki-scripts-dir` overrides the probe
(used by the test for a hermetic in-repo path).

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _FRONTMATTER_RE,
    _unquote_scalar,
)

# Numeric-only version segment, e.g. 0.1.74 — mirrors the shell probe's
# `case "$ver" in ''|*[!0-9.]*) continue` numeric guard so a branch/`main`
# checkout dir never outranks a real semver.
_NUMERIC_VERSION_RE = re.compile(r"^[0-9][0-9.]*$")
_THEME_LABEL_RE = re.compile(r"^theme_label[ \t]*:[ \t]*(.+?)[ \t]*$")


def _emit(success: bool, data: "dict | None" = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _version_key(ver: str) -> "tuple[int, ...]":
    """Sort key for a numeric-only version dir name (`0.0.9 < 0.0.16`)."""
    return tuple(int(p) for p in ver.split(".") if p != "")


def resolve_wiki_ingest_scripts() -> Path:
    """Locate `cogni-wiki/skills/wiki-ingest/scripts/`, mirroring the shell
    `resolve_wiki_scripts wiki-ingest` probe in knowledge-ingest/SKILL.md.

    Probe order:
      1. Sibling checkout — `<repo-root>/cogni-wiki/skills/wiki-ingest/scripts`,
         where <repo-root> is three levels up from this file
         (scripts/ -> cogni-knowledge/ -> <repo-root>).
      2. Versioned-cache install — newest NUMERIC version dir matching
         `<repo-root>/../cogni-wiki/*/skills/wiki-ingest/scripts`.
    """
    repo_root = Path(__file__).resolve().parents[2]
    sib = repo_root / "cogni-wiki" / "skills" / "wiki-ingest" / "scripts"
    if sib.is_dir():
        return sib

    candidates: "list[tuple[tuple[int, ...], Path]]" = []
    for d in (repo_root.parent / "cogni-wiki").glob("*/skills/wiki-ingest/scripts"):
        if not d.is_dir():
            continue
        ver = d.parents[2].name  # the <semver> segment
        if _NUMERIC_VERSION_RE.match(ver):
            candidates.append((_version_key(ver), d))
    if candidates:
        return max(candidates)[1]

    raise FileNotFoundError(
        "cogni-wiki wiki-ingest scripts not found — install cogni-wiki, run "
        "from inside the monorepo, or pass --wiki-scripts-dir"
    )


def read_theme_label(page_path: Path) -> str:
    """Return the decoded `theme_label` frontmatter value, or "" when absent /
    empty / the page has no frontmatter block."""
    try:
        text = page_path.read_text(encoding="utf-8")
    except OSError:
        return ""
    m = _FRONTMATTER_RE.match(text)
    if not m:
        return ""
    for line in m.group(1).splitlines():
        lm = _THEME_LABEL_RE.match(line)
        if lm:
            return _unquote_scalar(lm.group(1).strip()).strip()
    return ""


def cmd_migrate(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root).expanduser().resolve()
    questions_dir = wiki_root / "wiki" / "questions"
    if not questions_dir.is_dir():
        return _emit(
            False,
            error=f"no wiki/questions directory under wiki-root: {questions_dir}",
        )

    # Resolve the wiki scripts dir up front (skipped on dry-run — no subprocess).
    update_script: "Path | None" = None
    if not args.dry_run:
        if args.wiki_scripts_dir:
            scripts_dir = Path(args.wiki_scripts_dir).expanduser().resolve()
        else:
            try:
                scripts_dir = resolve_wiki_ingest_scripts()
            except FileNotFoundError as exc:
                return _emit(False, error=str(exc))
        update_script = scripts_dir / "wiki_index_update.py"
        if not update_script.is_file():
            return _emit(
                False,
                error=f"wiki_index_update.py not found at: {update_script}",
            )

    moved: "list[dict]" = []
    noop: "list[dict]" = []
    skipped: "list[dict]" = []

    for page in sorted(questions_dir.glob("*.md")):
        slug = page.stem
        theme = read_theme_label(page)
        if not theme:
            skipped.append({"slug": slug, "reason": "empty_theme_label"})
            continue

        if args.dry_run:
            moved.append({"slug": slug, "to_category": theme, "dry_run": True})
            continue

        proc = subprocess.run(
            [
                sys.executable,
                str(update_script),
                "--wiki-root",
                str(wiki_root),
                "--move-slug",
                slug,
                "--to-category",
                theme,
            ],
            capture_output=True,
            text=True,
        )
        try:
            result = json.loads(proc.stdout)
        except (ValueError, json.JSONDecodeError):
            skipped.append(
                {
                    "slug": slug,
                    "reason": "unparseable_output",
                    "stderr": (proc.stderr or "").strip()[:500],
                }
            )
            continue

        if not result.get("success"):
            # Most common: "slug not found in index" (node never indexed). Record
            # and continue — never abort the whole base on one un-indexed node.
            skipped.append(
                {"slug": slug, "reason": result.get("error", "move_failed")}
            )
            continue

        action = (result.get("data") or {}).get("action")
        entry = {"slug": slug, "to_category": theme, "action": action}
        if action == "noop":
            noop.append(entry)
        else:
            moved.append(entry)

    return _emit(
        True,
        data={
            "wiki_root": str(wiki_root),
            "dry_run": bool(args.dry_run),
            "questions_scanned": len(moved) + len(noop) + len(skipped),
            "moved": moved,
            "noop": noop,
            "skipped": skipped,
        },
    )


def main(argv: "list[str]") -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Re-file each wiki/questions/*.md node under its theme_label index "
            "heading via wiki_index_update.py --move-slug. Idempotent and "
            "non-destructive."
        ),
        allow_abbrev=False,
    )
    parser.add_argument(
        "--wiki-root",
        required=True,
        help="Absolute path to the wiki root (the dir containing wiki/questions/).",
    )
    parser.add_argument(
        "--wiki-scripts-dir",
        help=(
            "Override path to cogni-wiki's wiki-ingest scripts dir (containing "
            "wiki_index_update.py). When omitted, self-resolves via the "
            "knowledge-ingest probe."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help=(
            "Report which nodes WOULD be relocated without invoking "
            "wiki_index_update.py. Does not touch wiki/index.md."
        ),
    )
    args = parser.parse_args(argv)
    return cmd_migrate(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
