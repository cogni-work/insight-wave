#!/usr/bin/env python3
"""
wiki_queue.py — persistent ingest queue for cogni-wiki (T3.1, v0.0.35+).

Issue #212 Tier 3 spine: a file-based queue under `<wiki-root>/.cogni-wiki/queue/`
that decouples *when* an ingest fires from *who* is at the keyboard, without
breaking the Karpathy invariant ("source N+1 must see source N's just-written
page"). Single-worker semantics by construction: `--next` refuses to advance
while any job sits in `running/`, so a queue-driven ingest stays strictly
sequential. The decoupling is in scheduling, not in concurrency.

Five operations, one dispatcher:

    --enqueue   --source <s> [--type T] [--tags ...] [--title ...]
                [--auto-backlinks K] [--no-convert] [--priority N]
                [--scheduled-at ISO]
                Write a fresh job under pending/. No LLM. Logs `queue | enqueued`.

    --next      Atomic pending → running pick. Emits the job payload (or
                action: "noop", reason: "queue_empty" | "running_busy"
                | "all_scheduled_future"). Refuses to pick while running/ is
                non-empty. Stamps started_at on the picked job. No LLM.

    --complete  --job-id <id> --success | --failure --error <msg>
                Move running/<id>.json → done/ or failed/ atomically; stamp
                finished_at and (on failure) last_error. On failure, append
                a `queue | failed` line to wiki/log.md. No LLM.

    --status    [--limit N]
                Read-only counts + oldest pending + running_started_at +
                last N failures (default 5). No LLM.

    --retry     --job-id <id> [--scheduled-at ISO]
                Move failed/<id>.json → pending/<id>.json; increment attempts;
                clear last_error; optionally rewrite scheduled_at. Logs
                `queue | retried`. No LLM.

Concurrency contract:

    Every state-dir transition (rename + stamp) is wrapped in
    `_wiki_lock(wiki_root)` from `_wikilib.py` so two `--next` calls from
    separate sessions cannot pick the same job. Job-file *bodies* are unique
    by construction (one writer per job_id) and don't need additional
    locking. The slow LLM-driven ingest itself runs **outside** the queue
    lock between `--next` and `--complete`, so the lock window stays small.

`os.rename` between `pending/`, `running/`, `done/`, `failed/` is POSIX-atomic
because all four dirs are siblings under `.cogni-wiki/queue/`, on the same
filesystem by construction (we created them).

Output: standard `{success, data, error}` JSON on stdout via `_wikilib.emit_json`.
Exits 0 on `success: true` (including action: "noop" for --next), non-zero
on `success: false` so scheduled drainers (T3.2) treat empty/busy as quiet
no-ops while genuine failures still page.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _wikilib import (  # noqa: E402
    _wiki_lock,
    atomic_write,
    emit_json,
    fail_if_pre_migration,
)


JOB_VERSION = 1
QUEUE_STATES = ("pending", "running", "done", "failed")
DEFAULT_PRIORITY = 50
DEFAULT_FAILURES_LIMIT = 5
ID_RE = re.compile(r"^\d{10}-[0-9a-f]{8}$")
ISO_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")


def fail(msg: str) -> None:
    emit_json(False, {}, msg)
    sys.exit(1)


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_iso(s: str) -> dt.datetime:
    return dt.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)


def queue_root(wiki_root: Path) -> Path:
    return wiki_root / ".cogni-wiki" / "queue"


def state_dir(wiki_root: Path, state: str) -> Path:
    return queue_root(wiki_root) / state


def ensure_queue_dirs(wiki_root: Path) -> None:
    """Lazy-create the four state dirs on first use. Cheap, idempotent."""
    for state in QUEUE_STATES:
        state_dir(wiki_root, state).mkdir(parents=True, exist_ok=True)


def make_job_id(source: str) -> str:
    """{enqueued_at_unix:010d}-{sha1(source + nanos)[:8]} — lex-sortable, unique."""
    enqueued = int(time.time())
    nanos = time.time_ns()
    digest = hashlib.sha1(f"{source}|{nanos}".encode("utf-8")).hexdigest()[:8]
    return f"{enqueued:010d}-{digest}"


def find_job(wiki_root: Path, job_id: str) -> tuple[str, Path] | tuple[None, None]:
    """Locate `<id>.json` across all four state dirs. Returns (state, path) or (None, None)."""
    for state in QUEUE_STATES:
        p = state_dir(wiki_root, state) / f"{job_id}.json"
        if p.is_file():
            return state, p
    return None, None


def read_job(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_job(path: Path, job: dict) -> None:
    atomic_write(path, json.dumps(job, ensure_ascii=False, indent=2) + "\n")


def append_log(wiki_root: Path, line: str) -> None:
    """Append a `## [date] queue | …` line to wiki/log.md. Append-only,
    no read-modify-write — same pattern every other operation log line uses."""
    log_path = wiki_root / "wiki" / "log.md"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    today = dt.date.today().isoformat()
    with open(log_path, "a", encoding="utf-8") as f:
        f.write(f"## [{today}] queue | {line}\n")


# ---------------------------------------------------------------------------
# enqueue
# ---------------------------------------------------------------------------


def cmd_enqueue(args, wiki_root: Path) -> None:
    if not args.source:
        fail("--enqueue requires --source")
    if args.priority is not None and not (0 <= args.priority <= 100):
        fail(f"--priority must be in [0, 100] (got {args.priority})")
    if args.scheduled_at and not ISO_RE.match(args.scheduled_at):
        fail(f"--scheduled-at must be ISO 8601 UTC (YYYY-MM-DDTHH:MM:SSZ); got {args.scheduled_at!r}")
    if args.auto_backlinks is not None and args.auto_backlinks < 0:
        fail(f"--auto-backlinks must be >= 0 (got {args.auto_backlinks})")

    ensure_queue_dirs(wiki_root)

    enqueued = now_iso()
    scheduled = args.scheduled_at or enqueued
    job_id = make_job_id(args.source)
    job = {
        "version": JOB_VERSION,
        "id": job_id,
        "source": args.source,
        "type": args.type,
        "tags": args.tags or [],
        "title": args.title,
        "auto_backlinks": args.auto_backlinks,
        "no_convert": bool(args.no_convert),
        "priority": args.priority if args.priority is not None else DEFAULT_PRIORITY,
        "attempts": 0,
        "last_error": None,
        "enqueued_at": enqueued,
        "scheduled_at": scheduled,
        "started_at": None,
        "finished_at": None,
    }

    target = state_dir(wiki_root, "pending") / f"{job_id}.json"
    with _wiki_lock(wiki_root):
        if target.exists():
            # Astronomically unlikely (sha1 + nanos), but be honest about it.
            fail(f"job id collision: {job_id} already exists")
        write_job(target, job)
        append_log(wiki_root, f"enqueued {job_id} source={args.source}")

    emit_json(True, {"action": "enqueued", "job": job, "path": str(target)})


# ---------------------------------------------------------------------------
# next
# ---------------------------------------------------------------------------


def _list_pending_sorted(wiki_root: Path) -> list[Path]:
    """Sort pending/ jobs by (-priority, enqueued_at). The id prefix is the
    Unix-second timestamp, so lex-ordering on id resolves ties to FIFO."""
    pending = state_dir(wiki_root, "pending")
    if not pending.is_dir():
        return []
    paths = sorted(pending.glob("*.json"))
    if not paths:
        return []
    decorated = []
    for p in paths:
        try:
            job = read_job(p)
        except (OSError, json.JSONDecodeError):
            continue
        priority = int(job.get("priority", DEFAULT_PRIORITY))
        decorated.append((-priority, p.stem, p, job))
    decorated.sort(key=lambda t: (t[0], t[1]))
    return [(p, job) for _, _, p, job in decorated]


def cmd_next(args, wiki_root: Path) -> None:
    ensure_queue_dirs(wiki_root)

    with _wiki_lock(wiki_root):
        running_dir = state_dir(wiki_root, "running")
        running_jobs = list(running_dir.glob("*.json"))
        if running_jobs:
            emit_json(True, {
                "action": "noop",
                "reason": "running_busy",
                "running_count": len(running_jobs),
            })
            return

        candidates = _list_pending_sorted(wiki_root)
        if not candidates:
            emit_json(True, {"action": "noop", "reason": "queue_empty"})
            return

        # Pick the first candidate whose scheduled_at <= now.
        now = dt.datetime.now(dt.timezone.utc)
        picked_path = None
        picked_job = None
        for path, job in candidates:
            scheduled_raw = job.get("scheduled_at") or job.get("enqueued_at")
            try:
                scheduled = parse_iso(scheduled_raw)
            except (TypeError, ValueError):
                # Treat unparseable as "ready now"; better than skipping forever.
                scheduled = now
            if scheduled <= now:
                picked_path, picked_job = path, job
                break

        if picked_path is None:
            emit_json(True, {
                "action": "noop",
                "reason": "all_scheduled_future",
                "pending_count": len(candidates),
            })
            return

        # Stamp started_at, then atomic move pending → running.
        picked_job["started_at"] = now_iso()
        target = running_dir / picked_path.name
        # os.rename across sibling dirs of .cogni-wiki/queue/ is POSIX-atomic
        # because all four state dirs live on the same filesystem (we created
        # them under one root). See man 2 rename: atomic when target name is
        # fresh, which is the case here — the same id only ever lives in one
        # of pending/running/done/failed.
        write_job(picked_path, picked_job)
        os.rename(str(picked_path), str(target))

    emit_json(True, {"action": "pick", "job": picked_job, "path": str(target)})


# ---------------------------------------------------------------------------
# complete
# ---------------------------------------------------------------------------


def cmd_complete(args, wiki_root: Path) -> None:
    if not args.job_id:
        fail("--complete requires --job-id")
    if bool(args.success) == bool(args.failure):
        fail("--complete requires exactly one of --success or --failure")
    if args.failure and not args.error:
        fail("--complete --failure requires --error <msg>")

    ensure_queue_dirs(wiki_root)

    src_path = state_dir(wiki_root, "running") / f"{args.job_id}.json"
    target_state = "done" if args.success else "failed"
    target_path = state_dir(wiki_root, target_state) / f"{args.job_id}.json"

    with _wiki_lock(wiki_root):
        if not src_path.is_file():
            # Locate the actual current state for a useful error.
            actual_state, _ = find_job(wiki_root, args.job_id)
            if actual_state is None:
                fail(f"job {args.job_id!r} not found in any queue state")
            else:
                fail(f"job {args.job_id!r} is in {actual_state}/, not running/ — cannot complete")
            return

        job = read_job(src_path)
        job["finished_at"] = now_iso()
        if args.failure:
            job["last_error"] = args.error
        write_job(src_path, job)
        os.rename(str(src_path), str(target_path))

        if args.failure:
            # Truncate very long error messages so log.md stays greppable.
            err_short = (args.error or "").splitlines()[0][:200]
            append_log(wiki_root, f"failed {args.job_id} error={err_short}")

    emit_json(True, {
        "action": "completed",
        "outcome": target_state,
        "job": job,
        "path": str(target_path),
    })


# ---------------------------------------------------------------------------
# retry
# ---------------------------------------------------------------------------


def cmd_retry(args, wiki_root: Path) -> None:
    if not args.job_id:
        fail("--retry requires --job-id")
    if args.scheduled_at and not ISO_RE.match(args.scheduled_at):
        fail(f"--scheduled-at must be ISO 8601 UTC; got {args.scheduled_at!r}")

    ensure_queue_dirs(wiki_root)

    src_path = state_dir(wiki_root, "failed") / f"{args.job_id}.json"
    target_path = state_dir(wiki_root, "pending") / f"{args.job_id}.json"

    with _wiki_lock(wiki_root):
        if not src_path.is_file():
            actual_state, _ = find_job(wiki_root, args.job_id)
            if actual_state is None:
                fail(f"job {args.job_id!r} not found in any queue state")
            else:
                fail(f"job {args.job_id!r} is in {actual_state}/, not failed/ — cannot retry")
            return

        job = read_job(src_path)
        job["attempts"] = int(job.get("attempts", 0)) + 1
        job["last_error"] = None
        job["started_at"] = None
        job["finished_at"] = None
        if args.scheduled_at:
            job["scheduled_at"] = args.scheduled_at
        write_job(src_path, job)
        os.rename(str(src_path), str(target_path))
        append_log(wiki_root, f"retried {args.job_id} from=failed attempts={job['attempts']}")

    emit_json(True, {"action": "retried", "job": job, "path": str(target_path)})


# ---------------------------------------------------------------------------
# status
# ---------------------------------------------------------------------------


def _count_done_recent(wiki_root: Path, days: int = 30) -> int:
    """Count done/<id>.json files whose id-timestamp prefix is within `days`.
    The id prefix is the Unix second at enqueue time — close enough to
    "recent finish" for a status-block bucket without re-reading every body."""
    done = state_dir(wiki_root, "done")
    if not done.is_dir():
        return 0
    cutoff = int(time.time()) - days * 86400
    n = 0
    for p in done.glob("*.json"):
        m = ID_RE.match(p.stem)
        if not m:
            continue
        try:
            ts = int(p.stem.split("-", 1)[0])
        except ValueError:
            continue
        if ts >= cutoff:
            n += 1
    return n


def _oldest_pending(wiki_root: Path) -> tuple[str | None, str | None]:
    """(oldest_id, oldest_enqueued_at_iso) for the lex-smallest pending id."""
    pending = state_dir(wiki_root, "pending")
    if not pending.is_dir():
        return None, None
    paths = sorted(pending.glob("*.json"))
    if not paths:
        return None, None
    try:
        job = read_job(paths[0])
    except (OSError, json.JSONDecodeError):
        return paths[0].stem, None
    return job.get("id", paths[0].stem), job.get("enqueued_at")


def _next_scheduled_at(wiki_root: Path) -> str | None:
    """Soonest scheduled_at across pending jobs (None if pending is empty)."""
    pending = state_dir(wiki_root, "pending")
    if not pending.is_dir():
        return None
    soonest = None
    for p in sorted(pending.glob("*.json")):
        try:
            job = read_job(p)
        except (OSError, json.JSONDecodeError):
            continue
        when = job.get("scheduled_at") or job.get("enqueued_at")
        if when and (soonest is None or when < soonest):
            soonest = when
    return soonest


def _running_started_at(wiki_root: Path) -> str | None:
    """started_at of the oldest job currently in running/, or None."""
    running = state_dir(wiki_root, "running")
    if not running.is_dir():
        return None
    paths = sorted(running.glob("*.json"))
    if not paths:
        return None
    try:
        job = read_job(paths[0])
    except (OSError, json.JSONDecodeError):
        return None
    return job.get("started_at")


def _recent_failures(wiki_root: Path, limit: int) -> list[dict]:
    failed = state_dir(wiki_root, "failed")
    if not failed.is_dir():
        return []
    paths = sorted(failed.glob("*.json"), reverse=True)[:limit]
    out = []
    for p in paths:
        try:
            job = read_job(p)
        except (OSError, json.JSONDecodeError):
            continue
        out.append({
            "id": job.get("id", p.stem),
            "source": job.get("source"),
            "last_error": job.get("last_error"),
            "attempts": job.get("attempts", 0),
            "finished_at": job.get("finished_at"),
        })
    return out


def cmd_status(args, wiki_root: Path) -> None:
    qroot = queue_root(wiki_root)
    if not qroot.is_dir():
        emit_json(True, {
            "available": False,
            "pending": 0, "running": 0, "done_recent": 0, "failed": 0,
        })
        return

    counts = {}
    for state in QUEUE_STATES:
        d = state_dir(wiki_root, state)
        counts[state] = len(list(d.glob("*.json"))) if d.is_dir() else 0

    oldest_id, oldest_at = _oldest_pending(wiki_root)
    data = {
        "available": True,
        "pending": counts["pending"],
        "running": counts["running"],
        "done_recent": _count_done_recent(wiki_root),
        "done_total": counts["done"],
        "failed": counts["failed"],
        "oldest_pending_id": oldest_id,
        "oldest_pending_enqueued_at": oldest_at,
        "next_scheduled_at": _next_scheduled_at(wiki_root),
        "running_started_at": _running_started_at(wiki_root),
        "recent_failures": _recent_failures(wiki_root, args.limit or DEFAULT_FAILURES_LIMIT),
    }
    emit_json(True, data)


# ---------------------------------------------------------------------------
# dispatcher
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Persistent ingest queue for cogni-wiki (T3.1)",
    )
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")

    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--enqueue", action="store_true", help="Add a job to pending/")
    mode.add_argument("--next", dest="next_", action="store_true", help="Pick the next pending job")
    mode.add_argument("--complete", action="store_true", help="Move a running/ job to done/ or failed/")
    mode.add_argument("--retry", action="store_true", help="Move a failed/ job back to pending/")
    mode.add_argument("--status", action="store_true", help="Read-only status JSON")

    # --enqueue flags
    parser.add_argument("--source", help="Source path or URL (--enqueue)")
    parser.add_argument("--type", help="Page type override (--enqueue)")
    parser.add_argument("--tags", help="Comma-separated tag list (--enqueue)")
    parser.add_argument("--title", help="Title override (--enqueue)")
    parser.add_argument("--auto-backlinks", type=int, help="Auto-backlinks K (--enqueue)")
    parser.add_argument("--no-convert", action="store_true", help="Skip Step 2a auto-conversion (--enqueue)")
    parser.add_argument("--priority", type=int, help="Priority 0-100, higher is picked first (--enqueue, default 50)")
    parser.add_argument("--scheduled-at", help="ISO 8601 UTC YYYY-MM-DDTHH:MM:SSZ (--enqueue, --retry)")

    # --complete / --retry flags
    parser.add_argument("--job-id", help="Job id (--complete, --retry)")
    parser.add_argument("--success", action="store_true", help="--complete outcome: success")
    parser.add_argument("--failure", action="store_true", help="--complete outcome: failure")
    parser.add_argument("--error", help="Error message (--complete --failure)")

    # --status flags
    parser.add_argument("--limit", type=int, help="Max recent failures to return (--status)")

    args = parser.parse_args()

    # Normalise --tags → list (strip whitespace, drop empties).
    if isinstance(args.tags, str):
        args.tags = [t.strip() for t in args.tags.split(",") if t.strip()]

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    if not (wiki_root / ".cogni-wiki" / "config.json").is_file():
        fail(f"not a cogni-wiki: {wiki_root}/.cogni-wiki/config.json not found")
    fail_if_pre_migration(wiki_root)

    if args.enqueue:
        cmd_enqueue(args, wiki_root)
    elif args.next_:
        cmd_next(args, wiki_root)
    elif args.complete:
        cmd_complete(args, wiki_root)
    elif args.retry:
        cmd_retry(args, wiki_root)
    elif args.status:
        cmd_status(args, wiki_root)


if __name__ == "__main__":
    main()
