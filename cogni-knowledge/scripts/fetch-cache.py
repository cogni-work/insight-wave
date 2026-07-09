#!/usr/bin/env python3
"""
fetch-cache.py — content-addressed URL→body cache for the inverted pipeline.

One canonical cache per knowledge base under
`<knowledge-root>/.cogni-knowledge/fetch-cache/<sha256-of-url>.json`. Every
URL the inverted pipeline touches goes through here; nothing reaches the
wiki or the composer without a cache entry.

The cache is addressed by URL (not by body) so re-fetches overwrite in
place, freshness checks are a function of `fetched_at`, and unavailable
URLs are negatively cached.

Actions:
  store    Write a cache entry for a URL.
  fetch    Read a cache entry; honour --max-age-days to short-circuit on
           stale entries; emit success: false with reason="stale" or
           "miss" when not usable.
  evict    Remove entries older than --older-than-days.
  stat     Cache-wide summary (entry count, total bytes, oldest/newest).
  key      Helper: print sha256(url) — useful for shell pipelines.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.

See `references/fetch-cache-design.md` for the contract this implements.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import hashlib
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write,
    normalize_url,
)

SCHEMA_VERSION = "0.1.0"
FETCH_CACHE_DIRNAME = "fetch-cache"
BINDING_DIRNAME = ".cogni-knowledge"
# Matches cogni-claims' fetch_method enum (cogni-claims/CLAUDE.md:111,
# skills/claims/SKILL.md) so a future shared verifier can read either cache's
# entries without translation. `webfetch` / `cobrowse_interactive` are the two
# standard web-fetch outcomes; `webfetch_fulltext` is the fuller-body web-fetch
# outcome — a second, deeper WebFetch extraction the source-curator takes for
# high-authority primary-tier sources (dense legal/regulatory normative text)
# where the standard `webfetch` extract may omit sections; like `webfetch` it
# is always paired with status `ok`. `direct` records a non-web source (a local
# file / pasted text / local PDF / interview note) whose bytes are already in
# hand — it is always paired with status `ok` and never carries a negative-cache
# `reason`. cogni-claims recognizes `webfetch_fulltext` and `direct` but emits
# neither (it has no fuller-body fetch and no local-ingest path); cogni-knowledge
# writes both. Adding a value here is a cross-plugin contract change: keep it
# additive and mirror it in the cogni-claims prose above.
VALID_FETCH_METHODS = {"webfetch", "webfetch_fulltext", "cobrowse_interactive", "direct"}
VALID_STATUSES = {"ok", "unavailable"}
# Closed vocabulary for unavailable-entry `reason`. Single source of truth
# for the `webfetch_error_class` enum that `source-fetcher.md` Step 4
# documents and `references/fetch-cache-design.md` §"Reason semantics"
# describes — keeping it as a constant here makes the constraint
# script-enforced at `--reason` parse time rather than convention.
# Additions require an additive coordinated change in those two files.
VALID_REASONS = {
    "webfetch_timeout",
    "webfetch_4xx",
    "webfetch_5xx",
    "webfetch_blocked",
    "webfetch_refused",
    # WebFetch returned HTTP 200 but the body was empty or whitespace-only
    # — effectively unavailable (a JS-rendered or soft-paywalled page that
    # acknowledged the request but served no extractable content). Recorded
    # at fetch time so the failure surfaces in Phase 2, not late at ingest;
    # cobrowse_eligible: true, since a browser fetch may render the page.
    "webfetch_empty_body",
    "pdf_extraction_failed",
    # A saved PDF file WAS surfaced, but the Read tool could not render it
    # in this runtime (its page->image rasterization has no PDF-rendering
    # support here). Environmental / operator-actionable — NOT URL-fatal:
    # re-run where the Read tool can render PDFs and the URL resolves.
    # Distinct from pdf_extraction_failed (no saved-file path at all).
    "pdf_render_unavailable",
    "cobrowse_unavailable",
    "cobrowse_failed",
    # Local-error reasons emitted by source-fetcher itself when the cache
    # write fails (disk full, permission denied) — see source-fetcher.md
    # §"Failure-mode invariants". These never travel through WebFetch but
    # share the negative-cache codepath, so they live in the same set.
    "cache_write_failed",
}

# Pipeline-internal control tokens a genuine external source body can never
# legitimately contain: a sub-question label (`sq-06`) or first-person pipeline
# framing ("this session" / "this curator" / "this sub-question"). Their
# presence in a would-be-verbatim body flags a cached body whose "verbatim"
# text bled the pipeline's own framing at the fetch step — e.g. an LLM-mediated
# WebFetch summarization run with the curator's sq-NN dispatch context live in
# session. This is a store-time tripwire, not a store-time gate.
_PIPELINE_TOKEN_RE = re.compile(
    r"\bsq-\d{2}\b"
    r"|\bthis (?:curator|session|sub-question)\b"
    r"|\bthis same session\b",
    re.IGNORECASE,
)


def _scan_pipeline_contamination(body: str) -> str | None:
    """Return the first pipeline-internal token found in `body`, else None.

    Detection only — the caller flags the persisted entry and stores it anyway
    (flag-and-store, fail-soft), matching the plugin's detect-in-script /
    act-in-orchestrator posture. It never rejects a fetch: a false positive
    must not lose a legitimately-fetched body.
    """
    if not body:
        return None
    m = _PIPELINE_TOKEN_RE.search(body)
    return m.group(0) if m else None


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _cache_dir(knowledge_root: Path) -> Path:
    return knowledge_root / BINDING_DIRNAME / FETCH_CACHE_DIRNAME


def _url_key(url: str) -> str:
    return hashlib.sha256(normalize_url(url).encode("utf-8")).hexdigest()


def _entry_path(knowledge_root: Path, url: str) -> Path:
    return _cache_dir(knowledge_root) / f"{_url_key(url)}.json"


def _content_hash(body: str) -> str:
    return "sha256:" + hashlib.sha256(body.encode("utf-8")).hexdigest()


def _parse_iso(stamp: str) -> _dt.datetime | None:
    if not stamp:
        return None
    try:
        return _dt.datetime.strptime(stamp, "%Y-%m-%dT%H:%M:%SZ").replace(
            tzinfo=_dt.timezone.utc
        )
    except ValueError:
        return None


def _age_days(stamp: str) -> float | None:
    parsed = _parse_iso(stamp)
    if parsed is None:
        return None
    delta = _dt.datetime.now(_dt.timezone.utc) - parsed
    return delta.total_seconds() / 86400.0


def cmd_store(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()

    if not args.url or not args.url.strip():
        return _emit(False, error="--url must be a non-empty, non-whitespace string")

    if args.status == "ok" and args.reason:
        return _emit(False, error="--reason is only valid with --status unavailable")
    if args.status == "unavailable" and not args.reason:
        return _emit(False, error="--reason is required when --status is unavailable")
    if args.reason and args.reason not in VALID_REASONS:
        return _emit(
            False,
            error=(
                f"--reason {args.reason!r} is not in the closed vocabulary "
                f"{sorted(VALID_REASONS)}; see references/fetch-cache-design.md "
                "§'Reason semantics'"
            ),
        )

    if args.body and args.body_file:
        return _emit(False, error="--body and --body-file are mutually exclusive")
    if args.body_file:
        try:
            body = Path(args.body_file).read_text(encoding="utf-8")
        except FileNotFoundError:
            return _emit(False, error=f"--body-file does not exist: {args.body_file}")
    else:
        body = args.body or ""

    # Store-time contamination tripwire (flag-and-store, fail-soft): a body
    # carrying pipeline-internal tokens is still persisted, but the flag rides
    # on the entry so every downstream consumer (cmd_fetch returns the whole
    # payload as data.entry) sees it before the body feeds claims.
    contamination_match = _scan_pipeline_contamination(body)

    payload = {
        "schema_version": SCHEMA_VERSION,
        "url": args.url,
        "fetched_at": args.fetched_at or _now(),
        "content_hash": _content_hash(body) if body else "",
        "fetch_method": args.fetch_method,
        "status": args.status,
        "body": body,
        "publisher": args.publisher or "",
        "http_status": args.http_status if args.http_status is not None else None,
        "etag": args.etag or "",
        "last_modified": args.last_modified or "",
        "contamination_suspected": contamination_match is not None,
        "contamination_match": contamination_match or "",
    }
    if args.status == "unavailable":
        payload["reason"] = args.reason

    target = _entry_path(knowledge_root, args.url)
    try:
        atomic_write(target, payload)
    except (FileNotFoundError, NotADirectoryError) as exc:
        return _emit(False, error=f"knowledge_root is not a usable directory: {exc}")
    return _emit(
        True,
        data={
            "path": str(target),
            "cache_key": _url_key(args.url),
            "content_hash": payload["content_hash"],
            "status": payload["status"],
            "contamination_suspected": payload["contamination_suspected"],
            "contamination_match": payload["contamination_match"],
        },
    )


def cmd_fetch(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    if not knowledge_root.is_dir():
        return _emit(False, error=f"knowledge_root does not exist: {knowledge_root}")

    target = _entry_path(knowledge_root, args.url)
    try:
        entry = json.loads(target.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return _emit(
            False,
            data={"cache_key": _url_key(args.url), "reason": "miss"},
            error="cache miss",
        )
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"cache entry is not valid JSON: {exc}")

    age = _age_days(entry.get("fetched_at", ""))
    if args.max_age_days is not None and age is not None and age > args.max_age_days:
        return _emit(
            False,
            data={
                "cache_key": _url_key(args.url),
                "reason": "stale",
                "age_days": round(age, 3),
                "max_age_days": args.max_age_days,
                "entry": entry,
            },
            error="cache entry is older than --max-age-days",
        )

    return _emit(
        True,
        data={
            "path": str(target),
            "cache_key": _url_key(args.url),
            "age_days": round(age, 3) if age is not None else None,
            "entry": entry,
        },
    )


def cmd_evict(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    cache = _cache_dir(knowledge_root)
    if not cache.is_dir():
        return _emit(True, data={"evicted": [], "kept": 0, "reason": "cache_dir_missing"})

    evicted: list[dict] = []
    kept = 0
    for entry_path in cache.glob("*.json"):
        try:
            entry = json.loads(entry_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            # Malformed entries can't serve a future hit, so evict unconditionally.
            if not args.dry_run:
                entry_path.unlink()
            evicted.append({"path": str(entry_path), "reason": "malformed"})
            continue

        age = _age_days(entry.get("fetched_at", ""))
        if age is not None and age > args.older_than_days:
            if not args.dry_run:
                entry_path.unlink()
            evicted.append(
                {
                    "path": str(entry_path),
                    "url": entry.get("url", ""),
                    "age_days": round(age, 3),
                }
            )
        else:
            kept += 1

    return _emit(
        True,
        data={
            "evicted": evicted,
            "evicted_count": len(evicted),
            "kept": kept,
            "older_than_days": args.older_than_days,
            "dry_run": args.dry_run,
        },
    )


def cmd_stat(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    cache = _cache_dir(knowledge_root)
    if not cache.is_dir():
        return _emit(True, data={"entries": 0, "total_bytes": 0, "reason": "cache_dir_missing"})

    entries = 0
    total_bytes = 0
    ok = 0
    unavailable = 0
    oldest: tuple[float, str] | None = None
    newest: tuple[float, str] | None = None
    for entry_path in cache.glob("*.json"):
        try:
            entry = json.loads(entry_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        entries += 1
        total_bytes += entry_path.stat().st_size
        status = entry.get("status", "")
        if status == "ok":
            ok += 1
        elif status == "unavailable":
            unavailable += 1
        age = _age_days(entry.get("fetched_at", ""))
        if age is None:
            continue
        url = entry.get("url", "")
        if oldest is None or age > oldest[0]:
            oldest = (age, url)
        if newest is None or age < newest[0]:
            newest = (age, url)

    return _emit(
        True,
        data={
            "entries": entries,
            "ok": ok,
            "unavailable": unavailable,
            "total_bytes": total_bytes,
            "oldest_age_days": round(oldest[0], 3) if oldest else None,
            "oldest_url": oldest[1] if oldest else "",
            "newest_age_days": round(newest[0], 3) if newest else None,
            "newest_url": newest[1] if newest else "",
        },
    )


def cmd_key(args: argparse.Namespace) -> int:
    if args.bare:
        sys.stdout.write(_url_key(args.url))
        sys.stdout.write("\n")
        return 0
    return _emit(True, data={"url": args.url, "cache_key": _url_key(args.url)})


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Content-addressed URL→body cache for the inverted pipeline.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_store = sub.add_parser("store", help="Write a cache entry.")
    p_store.add_argument("--knowledge-root", required=True)
    p_store.add_argument("--url", required=True)
    p_store.add_argument("--fetch-method", required=True, choices=sorted(VALID_FETCH_METHODS))
    p_store.add_argument("--status", required=True, choices=sorted(VALID_STATUSES))
    p_store.add_argument("--body", default="", help="Inline body string. Use --body-file for non-trivial content.")
    p_store.add_argument("--body-file", default="", help="Path to a file whose contents become the cached body.")
    p_store.add_argument("--fetched-at", default="", help="ISO 8601 UTC timestamp; default now().")
    p_store.add_argument("--publisher", default="")
    p_store.add_argument("--http-status", type=int, default=None)
    p_store.add_argument("--etag", default="")
    p_store.add_argument("--last-modified", default="")
    p_store.add_argument(
        "--reason",
        default="",
        help=(
            "Closed-vocabulary reason for status=unavailable. Must be one of "
            f"{sorted(VALID_REASONS)} — see references/fetch-cache-design.md "
            "§'Reason semantics'."
        ),
    )
    p_store.set_defaults(func=cmd_store)

    p_fetch = sub.add_parser("fetch", help="Read a cache entry.")
    p_fetch.add_argument("--knowledge-root", required=True)
    p_fetch.add_argument("--url", required=True)
    p_fetch.add_argument("--max-age-days", type=float, default=None)
    p_fetch.set_defaults(func=cmd_fetch)

    p_evict = sub.add_parser("evict", help="Remove entries older than --older-than-days.")
    p_evict.add_argument("--knowledge-root", required=True)
    p_evict.add_argument("--older-than-days", type=float, required=True)
    p_evict.add_argument("--dry-run", action="store_true")
    p_evict.set_defaults(func=cmd_evict)

    p_stat = sub.add_parser("stat", help="Cache-wide summary.")
    p_stat.add_argument("--knowledge-root", required=True)
    p_stat.set_defaults(func=cmd_stat)

    p_key = sub.add_parser("key", help="Print sha256(url).")
    p_key.add_argument("--url", required=True)
    p_key.add_argument("--bare", action="store_true", help="Print just the hex; no JSON envelope.")
    p_key.set_defaults(func=cmd_key)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
