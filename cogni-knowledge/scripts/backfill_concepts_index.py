#!/usr/bin/env python3
"""
backfill_concepts_index.py — one-shot /concepts outline backfill driver.

`wiki/concepts/index.md` (the standalone /concepts domain concept map) is a
brand-new page that only materialises as a side effect of a *pipeline run* —
the `knowledge-finalize` concepts sub-step calls `concepts_index.py render`.
So an **already-finalized base** that has concept pages but no research queued
has no /concepts outline and no on-demand way to get one. This driver is the
analog of `migrate-question-index.py` (the question-node index migration): run
it once, post-deploy, against an existing base to bring it up to the new layout
without waiting for the next finalize.

What it does: makes ONE subprocess call to the sibling `concepts_index.py
render`, which writes the deterministic grouped outline — every `## <theme>`
section with its per-concept summary + `[[slug]]` bullets and an empty,
placeholder `MACHINE-OWNED:CONCEPTS-LEADIN` span per theme. After this the page
exists and is browsable.

RENDER-ONLY. Narrating the lead-in spans requires dispatching the
`concepts-outliner` agent, which only an orchestrator (not a stdlib script) can
do. So this driver leaves the lead-in spans empty; they are narrated in place
by the **next** `knowledge-finalize` concepts sub-step (or a
`knowledge-refresh --mode push` cycle), exactly per the renderer/narrator
ownership split. The output states plainly that the outline is structural-only
until the next finalize narrates it.

Idempotent + non-destructive: re-running on a built outline is a byte-identical
no-op (the renderer's idempotence + no-clobber contract carries this); it never
touches an existing engine-owned lead-in it did not author and never touches a
human (non-sentineled) page. A base with no `wiki/concepts/*.md` pages is a
clean `action: noop`, not an abort.

Run once by an operator post-deploy against a base that lives outside the repo;
the live-base run is intentionally NOT part of any PR diff (same posture as
`migrate-question-index.py`).

Envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. Python 3.8+.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import resolve_wiki_scripts  # noqa: E402

# The structural-only disclaimer surfaced on every render, so an operator never
# mistakes the empty lead-in spans for a finished, narrated portal.
RENDER_ONLY_NOTE = (
    "Outline is structural-only: the per-theme lead-in spans are empty "
    "placeholders until the next knowledge-finalize (or knowledge-refresh "
    "--mode push) narrates them via the concepts-outliner agent."
)


def _emit(success: bool, data: "dict | None" = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _concept_count(concepts_dir: Path) -> int:
    """Count of concept pages (excluding the index.md the renderer owns).

    Mirrors `concepts_index.py::_gather_count` so the dry-run probe agrees with
    what the renderer will see."""
    if not concepts_dir.is_dir():
        return 0
    return sum(1 for p in concepts_dir.glob("*.md") if p.name != "index.md")


def _derive_action(render_data: dict, concept_count: int) -> str:
    """Map the renderer envelope (which carries no `action` field) to this
    driver's `action`. Precedence: a skipped human page wins, then an empty base
    is always a no-op (the header-only page the renderer writes is harmless but
    not a meaningful backfill), then the renderer's `changed` flag decides."""
    if render_data.get("skipped_human_page"):
        return "skipped_human_page"
    if concept_count == 0:
        return "noop"
    return "rendered" if render_data.get("changed") else "noop"


def cmd_backfill(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root).expanduser().resolve()
    concepts_dir = wiki_root / "wiki" / "concepts"
    concept_count = _concept_count(concepts_dir)

    # --dry-run short-circuits before any subprocess (the renderer is never
    # called) — report what would happen from the concept-page probe alone.
    if args.dry_run:
        return _emit(True, data={
            "wiki_root": str(wiki_root),
            "dry_run": True,
            "concept_count": concept_count,
            "action": "noop" if concept_count == 0 else "would_render",
            "render_only": True,
            "note": RENDER_ONLY_NOTE,
        })

    # Resolve the cogni-wiki scripts dir the renderer needs for `_wiki_lock`
    # (imported from _wikilib.py). Pass the entry-point this driver actually
    # needs so a partial vendor (dir present, script absent) falls through to a
    # complete copy instead of resolving here and failing the check below.
    if args.wiki_scripts_dir:
        scripts_dir = Path(args.wiki_scripts_dir).expanduser().resolve()
    else:
        try:
            scripts_dir = resolve_wiki_scripts("wiki-ingest", expected_script="_wikilib.py")
        except FileNotFoundError as exc:
            return _emit(False, error=str(exc))
    if not (scripts_dir / "_wikilib.py").is_file():
        return _emit(False, error=f"_wikilib.py not found at: {scripts_dir / '_wikilib.py'}")

    renderer = Path(__file__).resolve().parent / "concepts_index.py"
    if not renderer.is_file():
        return _emit(False, error=f"concepts_index.py not found at: {renderer}")

    cmd = [
        sys.executable, str(renderer), "render",
        "--wiki-root", str(wiki_root),
        "--wiki-scripts-dir", str(scripts_dir),
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    except OSError as exc:
        return _emit(False, error=f"failed to invoke concepts_index.py render: {exc}")

    try:
        result = json.loads(proc.stdout)
    except (json.JSONDecodeError, ValueError):
        return _emit(
            False,
            error=(
                f"concepts_index.py render returned non-JSON "
                f"(exit {proc.returncode}): {proc.stdout.strip() or proc.stderr.strip()}"
            ),
        )

    if proc.returncode != 0 or not result.get("success"):
        return _emit(
            False,
            error=f"concepts_index.py render failed: {result.get('error') or proc.stderr.strip()}",
        )

    render_data = result.get("data", {})
    action = _derive_action(render_data, concept_count)
    return _emit(True, data={
        "wiki_root": str(wiki_root),
        "path": render_data.get("path"),
        "action": action,
        "changed": bool(render_data.get("changed", False)),
        "concept_count": concept_count,
        "theme_count": render_data.get("theme_count"),
        "skipped_human_page": bool(render_data.get("skipped_human_page", False)),
        "render_only": True,
        "note": RENDER_ONLY_NOTE,
    })


def main(argv: "list[str] | None" = None) -> int:
    parser = argparse.ArgumentParser(
        allow_abbrev=False,
        description="One-shot render-only /concepts outline backfill driver "
                    "(wraps concepts_index.py render for an already-finalized base).",
    )
    parser.add_argument("--wiki-root", required=True,
                        help="Path to the wiki root (the dir containing wiki/ and .cogni-wiki/).")
    parser.add_argument("--wiki-scripts-dir", default="",
                        help="Override the cogni-wiki wiki-ingest/scripts dir (for _wiki_lock). "
                             "Self-resolved when omitted.")
    parser.add_argument("--dry-run", action="store_true",
                        help="Probe the concept-page count and report what would happen "
                             "without invoking the renderer.")
    args = parser.parse_args(argv)
    return cmd_backfill(args)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
