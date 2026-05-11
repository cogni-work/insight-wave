# `/loop` drainer (dev / iteration only)

The thinnest scheduled-drainer shape — fires `wiki-ingest --next`
periodically inside the current Claude Code session.

> **Not for production.** `/loop` dies when the Claude Code session ends.
> It is not durable across session restarts, laptop sleep, machine reboot,
> or anything else. Use it to iterate; promote to one of the other three
> shapes when the source set is stable.

## When to use `/loop`

- **Smoke-testing a new ingest source set.** You just dropped 30 files in
  `raw/`, you ran `wiki-ingest --enqueue raw/*.pdf`, and now you want to
  watch them drain in real time without typing `--next` thirty times.
- **Iterating on ingest config or templates.** Changing a frontmatter
  template? Updating a backlink rule? Run `/loop`, watch a few drain
  cycles, refine the template, repeat.
- **Debugging a stuck job.** Run `/loop 30s wiki-ingest --next` and
  watch the dispatcher's noop reasons until you understand why nothing's
  advancing.
- **Smoke test fixture** (`cogni-wiki/tests/test_scheduled_drainer.sh`) —
  this is the only shape in-process-testable, so it's the one the smoke
  test exercises.

## When **not** to use `/loop`

- **Production automation.** Anything you want to keep running when you
  close your laptop. → Use [GitHub Actions](github-actions.md),
  [Cloud Routine](cloud-routine.md), or [local cron / launchd / timer](local-cron.md).
- **Multi-user wikis.** `/loop` runs in one user's one session. If the
  wiki needs to drain on behalf of a team, you need a shared scheduler.
- **Anything you'll forget about.** `/loop` is silent inside an otherwise-active
  session; it's easy to forget you've left one running and find it still
  draining hours later (or, worse, find it died with the session and the
  queue silently piled up).

## Invocation

```
/loop 5m wiki-ingest --next
```

This fires `/cogni-wiki:wiki-ingest --next` every 5 minutes from inside
the current Claude Code session, until you stop it (Ctrl+C, exit the
session, or `/loop stop`).

Common cadences:

| Cadence | When |
|---|---|
| `30s` | Active iteration on a fresh source batch |
| `5m` | Default for "watch this drain over the next while" |
| `15m` | Slower iteration, keeping the session warm for other work |

Faster than `30s` is wasteful — most ingests take longer than that, so
you'll just stack `running_busy` noops.

## What you'll see

Each tick prints the dispatcher's JSON output to the session:

```
{"success": true, "data": {"action": "pick", "job": {"id": "...", ...}}}
```

…or:

```
{"success": true, "data": {"action": "noop", "reason": "queue_empty"}}
```

`pick` lines are the interesting ones; `noop` lines are normal (the queue
is empty, busy, or all-future).

## Promoting to a production shape

When the source set is stable and you want the drainer to keep running:

1. Stop the `/loop` (`/loop stop` or Ctrl+C).
2. Pick a production shape:
   - Wiki is git-hosted on GitHub? → [GitHub Actions](github-actions.md).
   - Wiki is local but Cloud Routine is available? → [Cloud Routine](cloud-routine.md).
   - On-box only? → [local cron / launchd / timer](local-cron.md).
3. Copy the relevant template, adjust paths and cadence, deploy.

The queue files don't need to change. The runner is purely the dispatch
mechanism — the queue itself is the source of truth.

## References

- `/loop` skill — the in-session repeating-task primitive
- `cogni-wiki/tests/test_scheduled_drainer.sh` — the smoke test that
  exercises the `/loop`-equivalent dispatch path in-process
- `cogni-wiki/skills/wiki-ingest/SKILL.md` — Mode D dispatcher contract
- `cogni-wiki/references/scheduled-drainer/README.md` — selector + rationale
