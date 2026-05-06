#!/usr/bin/env python3
"""
migrate_layout.py — one-shot migration of a flat-layout cogni-wiki to per-type
page directories.

Issue #212 Tier 2: cogni-wiki v0.0.27 stored every page flat under
`<wiki-root>/wiki/pages/<slug>.md` and carried the page's role only in the
frontmatter `type:` field. v0.0.28 promotes the type to a directory:

    wiki/concepts/<slug>.md      type: concept
    wiki/entities/<slug>.md      type: entity
    wiki/summaries/<slug>.md     type: summary
    wiki/decisions/<slug>.md     type: decision
    wiki/interviews/<slug>.md    type: interview
    wiki/meetings/<slug>.md      type: meeting
    wiki/learnings/<slug>.md     type: learning
    wiki/syntheses/<slug>.md     type: synthesis
    wiki/notes/<slug>.md         type: note
    wiki/audits/<slug>.md        lint-YYYY-MM-DD.md / health-YYYY-MM-DD.md

This is a forced cutover: every wiki-* skill in v0.0.28+ hard-fails when it
sees a flat `wiki/pages/*.md` layout. Run this script once per existing wiki.

Behaviour:

    - Default is dry-run. Pass `--apply` to actually move files.
    - Acquires `<wiki-root>/.cogni-wiki/.lock` for the entire run so a
      concurrent ingest cannot interleave.
    - For each `wiki/pages/*.md`:
        * `lint-*.md` / `health-*.md` → `wiki/audits/<name>` (R3 audit reports
          per SCHEMA.md).
        * Otherwise: parse frontmatter `type:`, route to `wiki/<dir>/<slug>.md`.
          Missing/invalid type aborts that file and records an error; other
          files keep migrating (partial success > no success at scale).
    - Atomic per-file move via `os.replace` (same filesystem guaranteed).
    - On success bumps `.cogni-wiki/config.json::schema_version` to `"0.0.5"`
      via `config_bump.py --set-string` (locked).
    - Appends one summary line to `wiki/log.md`:
          ## [YYYY-MM-DD] migrate | moved N pages to per-type dirs
    - Tries `rmdir wiki/pages` after the moves. Silently leaves the dir if
      non-empty (user-dropped junk is preserved, not deleted).

Idempotence: a second run sees `schema_version >= 0.0.5` and exits success
with `{moved: []}`.

Output contract:
    {
      "success": true,
      "data": {
        "wiki_root": "...",
        "applied": true | false,
        "schema_version_before": "0.0.4",
        "schema_version_after": "0.0.5",
        "moved":   [{"slug": "...", "from": "wiki/pages/x.md", "to": "wiki/concepts/x.md", "type": "concept"}],
        "skipped": [{"slug": "...", "reason": "..."}],
        "errors":  [{"slug": "...", "error": "..."}],
        "stats":   {"moved": N, "skipped": N, "errors": N}
      },
      "error": ""
    }

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
from pathlib import Path

# Reach over to wiki-ingest/scripts/ for the shared helpers.
_HERE = Path(__file__).resolve().parent
_INGEST_SCRIPTS = _HERE.parent.parent / "wiki-ingest" / "scripts"
sys.path.insert(0, str(_INGEST_SCRIPTS))
from _wikilib import (  # noqa: E402
    _wiki_lock,
    AUDIT_DIR,
    PAGE_TYPE_DIRS,
    SCHEMA_VERSION_PER_TYPE_DIRS,
    VALID_TYPES,
    _parse_frontmatter_minimal,
    _read_schema_version,
)

CONFIG_BUMP = _INGEST_SCRIPTS / "config_bump.py"


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def _route_target(wiki_root: Path, slug: str, ptype: str) -> Path:
    if slug.startswith("lint-") or slug.startswith("health-"):
        return wiki_root / "wiki" / AUDIT_DIR / f"{slug}.md"
    return wiki_root / "wiki" / PAGE_TYPE_DIRS[ptype] / f"{slug}.md"


def _is_version_at_least(have: str, target: str) -> bool:
    """Compare dotted-int version strings like '0.0.5'. Returns True iff
    `have >= target` componentwise. Empty / unparseable `have` is treated as
    "older than any target" so the migrator still runs."""
    try:
        a = [int(x) for x in have.split(".")]
        b = [int(x) for x in target.split(".")]
    except (AttributeError, ValueError):
        return False
    while len(a) < len(b):
        a.append(0)
    while len(b) < len(a):
        b.append(0)
    return a >= b


def _append_log(wiki_root: Path, line: str) -> None:
    log = wiki_root / "wiki" / "log.md"
    try:
        with log.open("a", encoding="utf-8") as f:
            if log.stat().st_size > 0:
                f.write("\n")
            f.write(line + "\n")
    except OSError:
        pass  # log append is best-effort; never abort the migration


def _bump_schema_version(wiki_root: Path) -> None:
    subprocess.run(
        [
            sys.executable,
            str(CONFIG_BUMP),
            "--wiki-root", str(wiki_root),
            "--key", "schema_version",
            "--set-string", SCHEMA_VERSION_PER_TYPE_DIRS,
        ],
        check=True,
        capture_output=True,
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Migrate a cogni-wiki from flat wiki/pages/ to per-type dirs"
    )
    parser.add_argument("--wiki-root", required=True)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually perform moves. Without this flag the run is dry — paths are "
             "computed and reported but no file is touched and schema_version is not bumped.",
    )
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki (no .cogni-wiki/config.json under {wiki_root})")

    schema_before = _read_schema_version(wiki_root)
    if _is_version_at_least(schema_before, SCHEMA_VERSION_PER_TYPE_DIRS):
        # Idempotent re-run: nothing to do.
        ok({
            "wiki_root": str(wiki_root),
            "applied": args.apply,
            "schema_version_before": schema_before,
            "schema_version_after": schema_before,
            "moved": [],
            "skipped": [{"slug": "*", "reason": f"schema_version {schema_before} already >= {SCHEMA_VERSION_PER_TYPE_DIRS}"}],
            "errors": [],
            "stats": {"moved": 0, "skipped": 1, "errors": 0},
        })

    pages_dir = wiki_root / "wiki" / "pages"
    if not pages_dir.is_dir():
        fail(f"wiki/pages/ not found under {wiki_root} — nothing to migrate")

    moved: list = []
    skipped: list = []
    errors: list = []

    with _wiki_lock(wiki_root):
        # Top-level *.md only. Skips any subdirectory that happens to exist
        # under wiki/pages/ (no-op on well-formed wikis).
        for src in sorted(pages_dir.glob("*.md")):
            if not src.is_file():
                continue
            slug = src.stem

            if slug.startswith("lint-") or slug.startswith("health-"):
                target = _route_target(wiki_root, slug, ptype="audit")
                ptype = "audit"
            else:
                try:
                    text = src.read_text(encoding="utf-8")
                except OSError as e:
                    errors.append({"slug": slug, "error": f"read failed: {e}"})
                    continue
                fm = _parse_frontmatter_minimal(text)
                ptype = fm.get("type", "")
                if ptype not in VALID_TYPES:
                    errors.append({"slug": slug, "error": f"invalid or missing type: {ptype!r}"})
                    continue
                target = _route_target(wiki_root, slug, ptype)

            entry = {
                "slug": slug,
                "from": str(src.relative_to(wiki_root)),
                "to": str(target.relative_to(wiki_root)),
                "type": ptype,
            }

            if target.exists():
                # Don't overwrite a pre-existing per-type page (would mean a
                # half-migrated wiki). Record and continue.
                skipped.append({"slug": slug, "reason": f"target already exists: {entry['to']}"})
                continue

            if not args.apply:
                moved.append(entry)
                continue

            try:
                target.parent.mkdir(parents=True, exist_ok=True)
                os.replace(str(src), str(target))
            except OSError as e:
                errors.append({"slug": slug, "error": f"move failed: {e}"})
                continue

            moved.append(entry)

        if args.apply and not errors:
            # Best-effort: drop the empty wiki/pages/ shell. Leave junk alone.
            try:
                pages_dir.rmdir()
            except OSError:
                pass

    schema_after = schema_before
    if args.apply and not errors and moved:
        try:
            _bump_schema_version(wiki_root)
            schema_after = SCHEMA_VERSION_PER_TYPE_DIRS
            _append_log(
                wiki_root,
                f"## [{dt.date.today().isoformat()}] migrate | moved {len(moved)} pages to per-type dirs",
            )
        except subprocess.CalledProcessError as e:
            errors.append({"slug": "*", "error": f"schema_version bump failed: {e}"})

    ok({
        "wiki_root": str(wiki_root),
        "applied": args.apply,
        "schema_version_before": schema_before,
        "schema_version_after": schema_after,
        "moved": moved,
        "skipped": skipped,
        "errors": errors,
        "stats": {"moved": len(moved), "skipped": len(skipped), "errors": len(errors)},
    })


if __name__ == "__main__":
    main()
