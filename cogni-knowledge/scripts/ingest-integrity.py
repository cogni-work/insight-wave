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
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _FRONTMATTER_RE,
    _unquote_scalar,
    first_url,
    normalize_url,
)

_ID_RE = re.compile(r"^id[ \t]*:[ \t]*(.+?)[ \t]*$")
_SOURCES_RE = re.compile(r"^sources[ \t]*:[ \t]*(.+?)[ \t]*$")


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _page_id_and_url(page_text: str) -> tuple[str, str]:
    """Pull frontmatter `id` + the first `sources:` URL from a wiki page.

    Mirrors `wiki-coverage.py::_page_title_tags` — reuses `_FRONTMATTER_RE` for
    the block and `_unquote_scalar` for quoted scalars, then hands the raw
    `sources:` value to `_knowledge_lib.first_url` (which understands both the
    inline `["<URL>"]` source-page shape and a bare URL). Anything it cannot
    read returns "" — the sweep then surfaces the mismatch rather than masking
    it."""
    observed_id = ""
    observed_url = ""
    m = _FRONTMATTER_RE.match(page_text or "")
    if not m:
        return observed_id, observed_url
    for line in m.group(1).splitlines():
        im = _ID_RE.match(line)
        if im and not observed_id:
            raw = im.group(1).strip()
            # Strip a YAML inline comment from an UNQUOTED scalar only — mirrors
            # _knowledge_lib._absorb_claim_kv / wiki-coverage._page_title_tags.
            if raw[:1] not in ('"', "'"):
                hash_pos = raw.find(" #")
                if hash_pos != -1:
                    raw = raw[:hash_pos].rstrip()
            observed_id = _unquote_scalar(raw)
            continue
        sm = _SOURCES_RE.match(line)
        if sm and not observed_url:
            observed_url = first_url(sm.group(1).strip())
    return observed_id, observed_url


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
            violations.append({
                "slug": slug,
                "expected_url": expected_url,
                "observed_id": "",
                "observed_url": "",
                "page_path": str(page_path),
                "id_ok": False,
                "url_ok": False,
                "reason": "page_missing",
            })
            continue

        observed_id, observed_url = _page_id_and_url(page_path.read_text(encoding="utf-8"))
        id_ok = observed_id == slug
        url_ok = normalize_url(observed_url) == normalize_url(expected_url)
        if id_ok and url_ok:
            ok.append(slug)
            continue

        # When both legs are wrong (the cross-contamination signature) prefer the
        # id_mismatch reason — it is the conformance-gate name (`id_mismatch`)
        # and the loudest signal; url_mismatch covers a swapped sources: only.
        reason = "id_mismatch" if not id_ok else "url_mismatch"
        violations.append({
            "slug": slug,
            "expected_url": expected_url,
            "observed_id": observed_id,
            "observed_url": observed_url,
            "page_path": str(page_path),
            "id_ok": id_ok,
            "url_ok": url_ok,
            "reason": reason,
        })

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
