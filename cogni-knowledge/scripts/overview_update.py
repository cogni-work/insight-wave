#!/usr/bin/env python3
"""overview_update.py — lock-wrapped, atomic writes to wiki/overview.md.

knowledge-finalize Step 10.5 writes `wiki/overview.md` in two places:

  - sub-step 3   — the `## Recent syntheses` dated bullet (always runs).
  - sub-step 3.5 — the `MACHINE-OWNED:OVERVIEW-NARRATIVE` splice, on
                   `--apply-portal` only.

Both were inline `python3` read-modify-writes that were neither serialised
against concurrent finalizes nor atomic, so two sessions finalizing against
the same base (or a crash mid-write) could corrupt the file. `overview.md` is
a derived narrative artefact (regenerated next dispatch), so this was correctly
left non-blocking — but the two writes shared the gap.

This script routes both writes through ONE shared body:

    with _wiki_lock(wiki_root):
        text = read(overview.md)
        new  = transform(text)            # bullet refresh OR narrative splice
        atomic_write_text(overview.md, new)   # temp-file + os.replace

`_wiki_lock` is imported from cogni-wiki's `_wikilib` via `--wiki-scripts-dir`
(the `concept-store.py` posture) so `overview.md` serialises on the same
`<wiki-root>/.cogni-wiki/.lock` as every other shared-state wiki write. The
transform helpers (`upsert_machine_block`) and the atomic writer
(`atomic_write_text`) are reused verbatim from `_knowledge_lib`, so the
happy-path output is byte-for-byte identical to the prior inline writes.

Fail-soft posture: a missing wiki-scripts dir, a `_wikilib` import failure, or
any write error returns a `{"success": false, ...}` envelope and writes
nothing partial — the caller logs it loudly and never rolls back the synthesis.

Stdlib only. No pip dependencies. POSIX only (`_wiki_lock` uses `fcntl.flock`).

Output is a single-line `{"success": bool, "data": {...}, "error": "..."}`
JSON envelope, per the cross-plugin script convention.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write_text,
    upsert_machine_block,
)

OVERVIEW_REL = ("wiki", "overview.md")
DEFAULT_OVERVIEW = "# Overview\n"
RECENT_HEADING = "## Recent syntheses"
OVERVIEW_NARRATIVE_BLOCK = "OVERVIEW-NARRATIVE"


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    """Print the `{success, data, error}` envelope; return a shell exit code."""
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _import_wiki_lock(wiki_scripts_dir: str):
    """Import `_wiki_lock` from cogni-wiki's `_wikilib`, or return an error.

    Mirrors concept-store.py: resolve the dir, push it on `sys.path`, import.
    Returns `(_wiki_lock, None)` on success or `(None, error_message)` so the
    caller can emit a fail-soft envelope instead of crashing.
    """
    wiki_scripts = Path(wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return None, f"--wiki-scripts-dir does not exist: {wiki_scripts}"
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock  # noqa: E402
    except ImportError as exc:
        return None, f"could not import cogni-wiki _wikilib from {wiki_scripts}: {exc}"
    return _wiki_lock, None


def _overview_path(wiki_root: Path) -> Path:
    return wiki_root.joinpath(*OVERVIEW_REL)


def _read_overview(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.is_file() else DEFAULT_OVERVIEW


def _recent_bullet_text(text: str, slug: str, topic_raw: str, date_stamp: str) -> str:
    """Return overview text with this slug's `## Recent syntheses` bullet refreshed.

    Byte-for-byte port of knowledge-finalize Step 10.5 sub-step 3:
      - drop ONLY a prior `- … [[slug]] …` list item (never prose that merely
        references the wikilink),
      - insert a fresh dated bullet under an exact-line `## Recent syntheses`
        heading (creating the heading at the tail when absent),
      - normalise to a single trailing newline.
    """
    marker = "[[" + slug + "]]"
    topic = " ".join(topic_raw.split())
    bullet = "- [" + date_stamp + "] " + marker + " — " + topic
    lines = [
        ln for ln in text.splitlines()
        if not (ln.lstrip().startswith("- ") and marker in ln)
    ]
    if RECENT_HEADING in lines:  # exact line match, not substring
        lines.insert(lines.index(RECENT_HEADING) + 1, bullet)
    else:
        if lines and lines[-1].strip():
            lines.append("")
        lines += [RECENT_HEADING, "", bullet]
    return "\n".join(lines).rstrip() + "\n"


def cmd_recent_bullet(args: argparse.Namespace) -> int:
    _wiki_lock, err = _import_wiki_lock(args.wiki_scripts_dir)
    if err:
        return _emit(False, error=err)
    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")
    path = _overview_path(wiki_root)
    try:
        with _wiki_lock(wiki_root):
            before = _read_overview(path)
            after = _recent_bullet_text(before, args.slug, args.topic, args.date)
            changed = after != before
            if changed:
                atomic_write_text(path, after)
    except OSError as exc:
        return _emit(False, error=f"overview.md write failed: {exc}")
    return _emit(True, data={
        "path": str(path),
        "subcommand": "recent-bullet",
        "changed": changed,
        "slug": args.slug,
    })


def cmd_narrative_splice(args: argparse.Namespace) -> int:
    _wiki_lock, err = _import_wiki_lock(args.wiki_scripts_dir)
    if err:
        return _emit(False, error=err)
    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")
    prose_path = Path(args.prose_file).resolve()
    try:
        prose = prose_path.read_text(encoding="utf-8")
    except OSError as exc:
        return _emit(False, error=f"prose file not readable: {exc}")
    path = _overview_path(wiki_root)
    try:
        with _wiki_lock(wiki_root):
            before = _read_overview(path)
            # Splice the OVERVIEW-NARRATIVE machine block: insert after the H1
            # on the first finalize, replace only its inner thereafter. Every
            # other byte (the ## Recent syntheses bullets sub-step 3 wrote, and
            # all human prose) is preserved.
            after = upsert_machine_block(before, OVERVIEW_NARRATIVE_BLOCK, prose)
            changed = after != before
            if changed:
                atomic_write_text(path, after)
    except OSError as exc:
        return _emit(False, error=f"overview.md write failed: {exc}")
    return _emit(True, data={
        "path": str(path),
        "subcommand": "narrative-splice",
        "changed": changed,
    })


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Lock-wrapped, atomic writes to wiki/overview.md "
                    "(knowledge-finalize Step 10.5 sub-steps 3 and 3.5).",
    )
    sub = parser.add_subparsers(dest="subcommand", required=True)

    rb = sub.add_parser(
        "recent-bullet",
        help="Refresh this synthesis's '## Recent syntheses' dated bullet "
             "(sub-step 3; always runs).",
    )
    rb.add_argument("--wiki-root", required=True)
    rb.add_argument("--slug", required=True, help="Synthesis slug (the [[wikilink]] target).")
    rb.add_argument("--topic", required=True, help="Raw topic text for the bullet tail.")
    rb.add_argument("--date", required=True, help="Date stamp, e.g. $(date -u +%%F).")
    rb.add_argument("--wiki-scripts-dir", required=True,
                    help="cogni-wiki wiki-ingest/scripts dir (for _wiki_lock).")
    rb.set_defaults(func=cmd_recent_bullet)

    ns = sub.add_parser(
        "narrative-splice",
        help="Splice the OVERVIEW-NARRATIVE machine block into overview.md "
             "(sub-step 3.5 APPLY; --apply-portal only).",
    )
    ns.add_argument("--wiki-root", required=True)
    ns.add_argument("--prose-file", required=True, dest="prose_file",
                    help="File holding the overview-narrative inner prose.")
    ns.add_argument("--wiki-scripts-dir", required=True,
                    help="cogni-wiki wiki-ingest/scripts dir (for _wiki_lock).")
    ns.set_defaults(func=cmd_narrative_splice)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
