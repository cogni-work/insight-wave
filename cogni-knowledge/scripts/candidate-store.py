#!/usr/bin/env python3
"""
candidate-store.py — file-locked merge of parallel source-curator output
batches into `<project>/.metadata/candidates.json`.

The Phase 2 (`knowledge-curate`) skill fans out one `source-curator` agent
per sub-question. Each curator writes a JSON array of candidate objects to
a per-sub-question batch file; the skill then calls this script's
`append-batch` to merge that batch into the canonical project-local
`candidates.json` under an `fcntl.flock` lock so parallel merges cannot
race.

Subcommands:
  init           Create an empty `candidates.json` (schema 0.1.0). Idempotent.
  append-batch   Read a JSON array of candidate objects from --batch-file,
                 merge into candidates.json under lock, write atomically.
                 Dedup key is the URL-normalized form (see normalize_url).
                 On collision: union sub_question_refs, keep higher score,
                 keep earlier discovered_at, recompute tier + fetch_priority
                 on the merged entry.
  read           Emit the current candidates.json content in the envelope.

The dedup helper `normalize_url` is the source of truth for URL identity in
the inverted pipeline. `source-fetcher` uses it too at lookup time so the
curator-side merge and the fetcher-side cache lookup agree.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. fcntl.flock — posix only (consistent
with the existing tests/README.md bash 3.2 + Linux/macOS posture).

See `references/inverted-pipeline.md` Phase 2 contract for the candidates.json
schema this script enforces.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import fcntl
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _STRIP_QUERY_EXACT,
    _STRIP_QUERY_PREFIXES,
    atomic_write,
    normalize_url,
)

SCHEMA_VERSION = "0.1.0"
CANDIDATES_FILENAME = "candidates.json"
LOCK_SUFFIX = ".lock"
METADATA_DIRNAME = ".metadata"

# Score → tier thresholds. Match the upstream source-curator (kept identical
# at fork time per the plan's "fork discipline" note). See
# `cogni-knowledge/agents/source-curator.md` Phase 3.
TIER_PRIMARY_MIN = 0.80
TIER_SECONDARY_MIN = 0.50


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _metadata_dir(project_path: Path) -> Path:
    return project_path / METADATA_DIRNAME


def _candidates_path(project_path: Path) -> Path:
    return _metadata_dir(project_path) / CANDIDATES_FILENAME


def _lock_path(project_path: Path) -> Path:
    return _metadata_dir(project_path) / (CANDIDATES_FILENAME + LOCK_SUFFIX)


def _tier_for(score: float) -> str:
    if score >= TIER_PRIMARY_MIN:
        return "primary"
    if score >= TIER_SECONDARY_MIN:
        return "secondary"
    return "supporting"


def _recompute_priorities(candidates: list[dict]) -> None:
    # Tie-break on original list position so re-merges produce a stable
    # priority assignment instead of shuffling on equal scores.
    tier_order = {"primary": 0, "secondary": 1, "supporting": 2}
    indexed = list(enumerate(candidates))
    indexed.sort(
        key=lambda pair: (
            tier_order.get(pair[1].get("tier", "supporting"), 2),
            -float(pair[1].get("score", 0.0)),
            pair[0],
        )
    )
    for new_priority, (_orig_idx, entry) in enumerate(indexed, start=1):
        entry["fetch_priority"] = new_priority


def _empty_payload() -> dict:
    return {"schema_version": SCHEMA_VERSION, "candidates": []}


def _validate_candidate(entry: dict) -> str | None:
    if not isinstance(entry, dict):
        return f"candidate is not an object: {entry!r}"
    url = entry.get("url")
    if not isinstance(url, str) or not url.strip():
        return "candidate missing non-empty 'url'"
    score = entry.get("score")
    if not isinstance(score, (int, float)):
        return f"candidate {url}: 'score' must be a number, got {type(score).__name__}"
    if not 0.0 <= float(score) <= 1.0:
        return f"candidate {url}: 'score' must be in [0.0, 1.0], got {score}"
    refs = entry.get("sub_question_refs", [])
    if not isinstance(refs, list) or not all(isinstance(r, str) for r in refs):
        return f"candidate {url}: 'sub_question_refs' must be a list of strings"
    return None


def _merge_entry(existing: dict, incoming: dict) -> dict:
    """Merge an incoming candidate with an existing entry for the same URL.

    - Higher score wins; non-URL fields come from the winner.
    - Earlier discovered_at wins (curator emits ISO 8601 UTC).
    - sub_question_refs are unioned (existing first, then new refs).
    - tier + fetch_priority recomputed by the caller after all merges.
    """
    if float(incoming.get("score", 0.0)) > float(existing.get("score", 0.0)):
        winner = incoming
    else:
        winner = existing
    merged = dict(winner)
    existing_at = existing.get("discovered_at") or ""
    incoming_at = incoming.get("discovered_at") or ""
    if existing_at and incoming_at:
        merged["discovered_at"] = min(existing_at, incoming_at)
    else:
        merged["discovered_at"] = existing_at or incoming_at
    union: list[str] = []
    seen: set[str] = set()
    for ref in list(existing.get("sub_question_refs", [])) + list(
        incoming.get("sub_question_refs", [])
    ):
        if ref not in seen:
            seen.add(ref)
            union.append(ref)
    merged["sub_question_refs"] = union
    merged["score"] = float(winner.get("score", 0.0))
    merged["tier"] = _tier_for(merged["score"])
    return merged


def cmd_init(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    try:
        _metadata_dir(project_path).mkdir(parents=True, exist_ok=True)
    except (FileNotFoundError, NotADirectoryError) as exc:
        return _emit(False, error=f"project_path is not a usable directory: {exc}")
    target = _candidates_path(project_path)
    try:
        existing = json.loads(target.read_text(encoding="utf-8"))
    except FileNotFoundError:
        atomic_write(target, _empty_payload())
        return _emit(True, data={"path": str(target), "candidates_count": 0, "created": True})
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"existing candidates.json is malformed: {exc}")
    return _emit(
        True,
        data={
            "path": str(target),
            "candidates_count": len(existing.get("candidates", [])),
            "created": False,
        },
    )


def cmd_append_batch(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    batch_file = Path(args.batch_file).resolve()

    try:
        batch = json.loads(batch_file.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return _emit(False, error=f"batch_file does not exist: {batch_file}")
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"batch_file is not valid JSON: {exc}")

    if not isinstance(batch, list):
        return _emit(
            False,
            error=f"batch_file must contain a JSON array of candidate objects, got {type(batch).__name__}",
        )

    for entry in batch:
        err = _validate_candidate(entry)
        if err:
            return _emit(False, error=err)

    target = _candidates_path(project_path)
    # Skip the lock + rewrite cycle when the batch contributes nothing —
    # otherwise an empty curator batch still incurs an atomic-write.
    if not batch:
        try:
            payload = json.loads(target.read_text(encoding="utf-8"))
            count = len(payload.get("candidates", []))
        except FileNotFoundError:
            count = 0
        except json.JSONDecodeError as exc:
            return _emit(False, error=f"existing candidates.json is malformed: {exc}")
        return _emit(True, data={"path": str(target), "added": 0, "merged": 0, "candidates_count": count})

    try:
        _metadata_dir(project_path).mkdir(parents=True, exist_ok=True)
    except (FileNotFoundError, NotADirectoryError) as exc:
        return _emit(False, error=f"project_path is not a usable directory: {exc}")
    # Lock file is created lazily and never deleted — unlinking it would
    # race the next acquirer's flock against a different inode.
    lock = _lock_path(project_path)

    with open(lock, "a+", encoding="utf-8") as lock_fh:
        fcntl.flock(lock_fh.fileno(), fcntl.LOCK_EX)
        try:
            try:
                payload = json.loads(target.read_text(encoding="utf-8"))
            except FileNotFoundError:
                payload = _empty_payload()
            except json.JSONDecodeError as exc:
                return _emit(False, error=f"existing candidates.json is malformed: {exc}")

            existing = payload.setdefault("candidates", [])
            payload.setdefault("schema_version", SCHEMA_VERSION)

            index: dict[str, int] = {
                normalize_url(entry.get("url", "")): idx
                for idx, entry in enumerate(existing)
            }

            added = 0
            merged = 0
            for incoming in batch:
                if "tier" not in incoming:
                    incoming["tier"] = _tier_for(float(incoming.get("score", 0.0)))
                key = normalize_url(incoming.get("url", ""))
                if key in index:
                    pos = index[key]
                    existing[pos] = _merge_entry(existing[pos], incoming)
                    merged += 1
                else:
                    new_entry = dict(incoming)
                    new_entry["tier"] = _tier_for(float(new_entry.get("score", 0.0)))
                    existing.append(new_entry)
                    index[key] = len(existing) - 1
                    added += 1

            _recompute_priorities(existing)
            atomic_write(target, payload)
        finally:
            fcntl.flock(lock_fh.fileno(), fcntl.LOCK_UN)

    return _emit(
        True,
        data={
            "path": str(target),
            "added": added,
            "merged": merged,
            "candidates_count": len(existing),
        },
    )


def cmd_read(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    target = _candidates_path(project_path)
    if not target.is_file():
        return _emit(False, data={"path": str(target)}, error="candidates.json does not exist")
    try:
        payload = json.loads(target.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"candidates.json is not valid JSON: {exc}")
    return _emit(
        True,
        data={
            "path": str(target),
            "candidates": payload.get("candidates", []),
            "schema_version": payload.get("schema_version", ""),
            "candidates_count": len(payload.get("candidates", [])),
        },
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="File-locked merge of source-curator output batches into <project>/.metadata/candidates.json",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_init = sub.add_parser("init", help="Create empty candidates.json (idempotent)")
    p_init.add_argument("--project-path", required=True)
    p_init.set_defaults(func=cmd_init)

    p_append = sub.add_parser("append-batch", help="Merge a curator batch under lock")
    p_append.add_argument("--project-path", required=True)
    p_append.add_argument(
        "--batch-file",
        required=True,
        help="Path to a JSON file containing an array of candidate objects",
    )
    p_append.set_defaults(func=cmd_append_batch)

    p_read = sub.add_parser("read", help="Emit candidates.json content")
    p_read.add_argument("--project-path", required=True)
    p_read.set_defaults(func=cmd_read)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
