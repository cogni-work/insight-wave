#!/usr/bin/env python3
"""ingest-integrity.py — post-wave integrity sweep for the ingest fan-out.

v0.1.0 inverted pipeline, Phase 4 (`knowledge-ingest` Step 3.5). The
deterministic detector that catches a cross-contaminated `wiki/sources/<slug>.md`
page before it reaches the index/backlink step (and therefore before compose/
verify ever see it).

The ingesters fan out in one single-message wave (`--batch-size`, default 25).
That wave is where two `source-ingester` dispatches can cross-talk: the agent
handling source A composes its page from source B's fetched body + frontmatter,
so A's page lands on disk carrying B's `id:`, `sources:` URL, claims, and body.
The contamination is LLM attention cross-talk — non-deterministic, not a code
path — so it cannot be prompted away. This sweep is the deterministic backstop:
the orchestrator holds the authoritative `(slug, url)` pairing it assigned at
dispatch time, and the sweep compares each on-disk page against THAT record,
never against the agent-returned batch JSON (which can itself be contaminated).

Subcommand:
  sweep   Read each dispatched page and assert its frontmatter `id:` equals the
          dispatched slug AND its `sources:` URL normalizes to the dispatched
          URL. Emit the violations the orchestrator quarantines.

Pure detector — read-only, never mutates the wiki. The orchestrator owns all
side effects (quarantine move, manifest edits), the established detect-in-script
/ act-in-orchestrator split (cf. cogni-wiki's `backlink_audit.py` audit mode).

Returns the insight-wave `{"success", "data", "error"}` envelope. Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import extract_page_id_and_url, normalize_url  # noqa: E402


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _violation(wiki_root: Path, slug: str, expected_url: str, reason: str,
               observed_id: str = "", observed_url: str = "") -> dict:
    """Assemble one violation record. `id_ok` / `url_ok` are derived from the
    observed-vs-expected comparison, so a `page_missing` entry (observed "")
    falls out as both-false without a separate code path."""
    return {
        "slug": slug,
        "expected_url": expected_url,
        "observed_id": observed_id,
        "observed_url": observed_url,
        "page_path": str(wiki_root / "wiki" / "sources" / f"{slug}.md"),
        "id_ok": observed_id == slug,
        "url_ok": normalize_url(observed_url) == normalize_url(expected_url),
        "reason": reason,
    }


def _read_dispatch(path_arg: str) -> list[dict]:
    raw = sys.stdin.read() if path_arg == "-" else Path(path_arg).read_text(encoding="utf-8")
    table = json.loads(raw)
    if not isinstance(table, list):
        raise ValueError("dispatch table must be a JSON array of {slug, url} objects")
    return table


def cmd_sweep(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root)
    table = _read_dispatch(args.dispatch)

    ok: list[str] = []
    violations: list[dict] = []
    for entry in table:
        slug = str(entry.get("slug", ""))
        expected_url = str(entry.get("url", ""))
        page_path = wiki_root / "wiki" / "sources" / f"{slug}.md"

        if not page_path.is_file():
            violations.append(_violation(wiki_root, slug, expected_url, "page_missing"))
            continue

        observed_id, observed_url = extract_page_id_and_url(page_path.read_text(encoding="utf-8"))
        id_ok = observed_id == slug
        url_ok = normalize_url(observed_url) == normalize_url(expected_url)
        if id_ok and url_ok:
            ok.append(slug)
            continue

        # When both legs are wrong (the cross-contamination signature) prefer the
        # id_mismatch reason — it is the conformance-gate name (`id_mismatch`)
        # and the loudest signal; url_mismatch covers a swapped sources: only.
        reason = "id_mismatch" if not id_ok else "url_mismatch"
        violations.append(_violation(wiki_root, slug, expected_url, reason,
                                     observed_id, observed_url))

    return _emit(True, data={"checked": len(table), "ok": ok, "violations": violations})


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_sweep = sub.add_parser(
        "sweep",
        help="Assert each dispatched page's id/sources match the dispatch record",
    )
    p_sweep.add_argument("--wiki-root", required=True)
    p_sweep.add_argument(
        "--dispatch", required=True,
        help='JSON array [{"slug","url"}, …]; "-" reads it from stdin',
    )
    p_sweep.set_defaults(func=cmd_sweep)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except Exception as exc:  # pragma: no cover - top-level guard
        return _emit(False, error=f"{type(exc).__name__}: {exc}")


if __name__ == "__main__":
    sys.exit(main())
