#!/usr/bin/env python3
"""concepts_index.py — deterministic renderer for wiki/concepts/index.md.

The standalone `/concepts` outline page: a browsable domain concept map that
enumerates the wiki's concept pages, groups them by theme, and emits one
`## <theme>` section per theme — each with an engine-owned, narrator-authored
lead-in span and a bullet per concept (one-line summary + `[[slug]]` wikilink).

This is now a thin **type-config wrapper** around the generic `sub_index.py`
renderer (the per-type machine-owned sub-index for any of the seven wiki page
types). All the rendering logic — wiki-resident theme derivation, the
`MACHINE-OWNED:CONCEPTS-LEADIN` carry-forward, the locked/atomic/idempotent
`render` vs lock-free `stage` subcommands, the human-page guard, and the
`{success, data, error}` envelope — lives in `sub_index.py`; this file pins the
`concepts` configuration (`sub_index.REGISTRY["concepts"]`) and keeps the
byte-stable CLI (`render --wiki-root --wiki-scripts-dir` / `stage --wiki-root`,
envelope key `concept_count`) so existing callers and `test_concepts_index.sh`
are unaffected.

Subcommands:

  - `render` — write `wiki/concepts/index.md` live, under `_wiki_lock` +
               `atomic_write_text`, only when the proposed text differs
               byte-for-byte (idempotent: re-running an unchanged wiki is a
               no-op).
  - `stage`  — write the proposed page to `<wiki-root>/.cogni-wiki/
               concepts-index-proposed.md` WITHOUT the lock and WITHOUT touching
               the live file.

Stdlib only. No pip dependencies. POSIX only on `render` (`_wiki_lock` uses
`fcntl.flock`); `stage` is lock-free. Python 3.9 floor (the `from __future__
import annotations` below matches `_knowledge_lib` / `sub_index`).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Optional

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sub_index import (  # noqa: E402
    REGISTRY,
    render_index,
    stage_index,
)

# The concepts type config — byte-stable with the legacy constants this file
# used to declare inline (dir `wiki/concepts/`, H1 `# Concepts`, ownership marker
# `MACHINE-OWNED:CONCEPTS-INDEX`, lead-in prefix `CONCEPTS-LEADIN:`, envelope
# count key `concept_count`).
CONCEPTS_CONFIG = REGISTRY["concepts"]


def cmd_render(args) -> int:
    return render_index(CONCEPTS_CONFIG, args.wiki_root, args.wiki_scripts_dir, args.lang)


def cmd_stage(args) -> int:
    return stage_index(CONCEPTS_CONFIG, args.wiki_root, args.lang)


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
    rn.add_argument("--lang", default="en",
                    help="output_language (ISO 639-1) for the per-theme lead-in "
                         "placeholder fallback; unknown/absent → English.")
    rn.set_defaults(func=cmd_render)

    st = sub.add_parser(
        "stage",
        help="Write the proposed page to "
             "<wiki-root>/.cogni-wiki/concepts-index-proposed.md without the "
             "lock and without touching the live page.",
    )
    st.add_argument("--wiki-root", required=True)
    st.add_argument("--lang", default="en",
                    help="output_language (ISO 639-1) for the per-theme lead-in "
                         "placeholder fallback; unknown/absent → English.")
    st.set_defaults(func=cmd_stage)

    return parser


def main(argv: Optional["list[str]"] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
