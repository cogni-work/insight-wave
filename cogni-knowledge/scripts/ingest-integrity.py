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
          URL. When `--knowledge-root` is given, a third leg also asserts the
          page's frontmatter `content_hash:` equals the fetch-cache entry's
          `content_hash` for the dispatched URL — catching the body-only variant
          where an agent kept its own id/sources but emitted a sibling's body
          (and the sibling's `content_hash:` line) under wave cross-talk. Emit
          the violations the orchestrator quarantines.

Pure detector — read-only, never mutates the wiki. The orchestrator owns all
side effects (quarantine move, manifest edits), the established detect-in-script
/ act-in-orchestrator split (cf. cogni-wiki's `backlink_audit.py` audit mode).

Returns the insight-wave `{"success", "data", "error"}` envelope. Stdlib only.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    extract_page_content_hash,
    extract_page_id_and_url,
    normalize_url,
)


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _violation(wiki_root: Path, slug: str, expected_url: str, reason: str,
               observed_id: str = "", observed_url: str = "",
               observed_content_hash: str = "", expected_content_hash: str = "",
               content_hash_ok: bool = True) -> dict:
    """Assemble one violation record. `id_ok` / `url_ok` are derived from the
    observed-vs-expected comparison, so a `page_missing` entry (observed "")
    falls out as both-false without a separate code path. `content_hash_ok` is
    passed in (not derived) because its "leg not checked / cache miss / either
    side empty" cases must read True regardless of the bare string comparison;
    its three keys default to the no-`--knowledge-root` shape so that path emits
    the same record plus harmless extra keys."""
    return {
        "slug": slug,
        "expected_url": expected_url,
        "observed_id": observed_id,
        "observed_url": observed_url,
        "observed_content_hash": observed_content_hash,
        "expected_content_hash": expected_content_hash,
        "page_path": str(wiki_root / "wiki" / "sources" / f"{slug}.md"),
        "id_ok": observed_id == slug,
        "url_ok": normalize_url(observed_url) == normalize_url(expected_url),
        "content_hash_ok": content_hash_ok,
        "reason": reason,
    }


def _cache_content_hash(knowledge_root: str, url: str) -> str:
    """The authoritative `content_hash` (`sha256:<hex>`) for `url` from the
    knowledge base's fetch-cache, by shelling to `fetch-cache.py fetch` (which
    owns the cache layout — we never re-inline that, per the delegation
    contract). Returns "" on any cache miss / non-zero exit / unparseable
    envelope / missing field, so the content_hash leg simply skips rather than
    false-flagging. No `--max-age-days` — a stale-but-present entry is still the
    authoritative body hash; staleness must not suppress the integrity check."""
    fetch_cache = Path(__file__).resolve().parent / "fetch-cache.py"
    try:
        proc = subprocess.run(
            [sys.executable, str(fetch_cache), "fetch",
             "--knowledge-root", knowledge_root, "--url", url],
            capture_output=True, text=True,
        )
        if proc.returncode != 0:
            return ""
        entry = json.loads(proc.stdout).get("data", {}).get("entry", {})
    except (OSError, json.JSONDecodeError):
        return ""
    return str(entry.get("content_hash", "") or "")


def _read_dispatch(path_arg: str) -> list[dict]:
    raw = sys.stdin.read() if path_arg == "-" else Path(path_arg).read_text(encoding="utf-8")
    table = json.loads(raw)
    if not isinstance(table, list):
        raise ValueError("dispatch table must be a JSON array of {slug, url} objects")
    return table


def cmd_sweep(args: argparse.Namespace) -> int:
    wiki_root = Path(args.wiki_root)
    knowledge_root = args.knowledge_root  # optional; None → content_hash leg off
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

        page_text = page_path.read_text(encoding="utf-8")
        observed_id, observed_url = extract_page_id_and_url(page_text)
        id_ok = observed_id == slug
        url_ok = normalize_url(observed_url) == normalize_url(expected_url)

        # content_hash leg — additive, only when --knowledge-root is given. Skip
        # (== ok) on a cache miss / empty hash on either side, so it never
        # produces a false positive; compares the cache entry's authoritative
        # body hash against the page's frontmatter content_hash, NOT a recomputed
        # on-disk hash (which diverges by design once trailers are appended).
        observed_ch = ""
        expected_ch = ""
        content_hash_ok = True
        if knowledge_root:
            observed_ch = extract_page_content_hash(page_text)
            expected_ch = _cache_content_hash(knowledge_root, expected_url)
            content_hash_ok = (
                not observed_ch or not expected_ch or observed_ch == expected_ch
            )

        if id_ok and url_ok and content_hash_ok:
            ok.append(slug)
            continue

        # Reason precedence: id/url are the loud wholesale signals; content_hash
        # is the narrow body-only one a page that passes id+url can still fail.
        # When both id+url are wrong (the cross-contamination signature) prefer
        # id_mismatch — it is the conformance-gate name and the loudest signal.
        if not id_ok:
            reason = "id_mismatch"
        elif not url_ok:
            reason = "url_mismatch"
        else:
            reason = "content_hash_mismatch"
        violations.append(_violation(wiki_root, slug, expected_url, reason,
                                     observed_id, observed_url,
                                     observed_ch, expected_ch, content_hash_ok))

    return _emit(True, data={"checked": len(table), "ok": ok, "violations": violations})


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_sweep = sub.add_parser(
        "sweep",
        help="Assert each dispatched page's id/sources (and, with "
             "--knowledge-root, content_hash) match the dispatch record",
    )
    p_sweep.add_argument("--wiki-root", required=True)
    p_sweep.add_argument(
        "--dispatch", required=True,
        help='JSON array [{"slug","url"}, …]; "-" reads it from stdin',
    )
    p_sweep.add_argument(
        "--knowledge-root", default=None,
        help="Knowledge-base root (the dir holding .cogni-knowledge/). When set, "
             "enables the content_hash leg: each page's frontmatter content_hash "
             "is asserted against the fetch-cache entry for the dispatched URL. "
             "Omit for the id/sources-only sweep (unchanged behavior).",
    )
    p_sweep.set_defaults(func=cmd_sweep)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except Exception as exc:  # pragma: no cover - top-level guard
        return _emit(False, error=f"{type(exc).__name__}: {exc}")


if __name__ == "__main__":
    sys.exit(main())
