# Scheduled drainer — deployment-shape selector (T3.2)

Reference configurations for the four scheduled-runner shapes that drive
`/cogni-wiki:wiki-ingest --next` on a recurring cadence so the persistent
ingest queue (T3.1, `.cogni-wiki/queue/{pending,running,done,failed}/`)
drains without a human at the keyboard.

The queue itself is state. The runner is **just** a periodic invocation of
`wiki-ingest --next` against that state — it owns nothing, holds no locks,
remembers nothing across ticks. Single-worker semantics are enforced by T3.1
(`_wiki_lock` + `os.rename` between sibling state dirs); the runner can be
re-entrant, can race against itself across hosts, and the queue stays
correct by construction. The runner choice is therefore a portability /
operational-environment question, not a correctness one.

## The Karpathy invariant the queue preserves

From issue #212:

> A persistent file-based queue with a single-worker drainer fired by a
> Cloud Routine keeps [the sequential] invariant literally intact while
> removing the only friction the gist actually complains about — that
> ingest requires a human in the loop.

T3.1 keeps the invariant literally true: `--next` refuses to advance while
any job sits in `running/`, so source N+1 cannot pick up before source N's
page has landed. T3.2's job is to make `--next` fire on a cadence.

## When to pick which shape

| If the wiki is… | …and you want… | Use | Why |
|---|---|---|---|
| **Hosted in a git repo (GitHub)** | Free durability + audit trail + zero extra state machinery | **[GitHub Actions](github-actions.md)** — recommended | `git push` is the cross-runner coordination primitive; multi-runner contention solves itself (rebase-and-retry). Unlocks Claude Code on the web because the path is just `git pull → wiki-ingest --next → commit → push`. |
| **Remote but no GitHub** (corporate-banned, GitLab-only, etc.) | API-triggerable, survives laptop sleep | **[Cloud Routine](cloud-routine.md)** | Anthropic-managed schedule; runs against any local or remote wiki path Claude Code can reach. |
| **On-box only** (air-gapped, GitHub-banned without remote alternative) | Fully local automation, no external service | **[local cron / launchd / systemd-timer](local-cron.md)** | Pure OS scheduler firing `claude -p --bare …`. The queue files are already portable so nothing else changes. |
| **Dev / local iteration** | In-process drainer while a Claude Code session is live | **[`/loop`](loop.md)** | Smoke-tests a new source set, fast iteration. Not a production answer — dies with the session. |

## Recommendation rationale

The recommended shape is **GitHub Actions** when the wiki is git-hosted.
The argument, lifted from the parent issue's deferred-suggestion comment
(#212#issuecomment-4407279057):

> This is what unlocks Claude Code on the web (claude.ai/code), and it
> makes GitHub Actions a viable runner shape for T3.2 with **zero extra
> state machinery** — the runner is just `git pull` → `wiki-ingest --next`
> → commit → push. Wins: Free durability + free notifications + free
> audit trail (the commit log). Multi-runner contention solved by git
> itself: the second pusher rebases or retries. No new lock primitive on
> top of `_wiki_lock`. Portability claim survives — the wiki is still
> plain markdown, it just happens to live in a git remote.

For wikis that are not git-hosted, Cloud Routine is the obvious next step
(API-triggerable, no remote required). For wikis on machines that have no
external connectivity at all, the local cron / launchd / systemd-timer
shape is the honest answer — the queue files are local, the runner is
local, nothing leaves the box.

`/loop` is dev-only; it does not survive a session restart and is therefore
not a production drainer. It exists in this directory because it is the
only shape that is exercised by an in-process smoke test
(`cogni-wiki/tests/test_scheduled_drainer.sh`), and because it remains a
useful tool for iterating on a new ingest source set before committing to
a longer-running deployment shape.

## What a scheduled drainer is allowed to do

Exactly one thing per tick: call `wiki-ingest --next`. The dispatcher does
the rest:

- If there's a job in `pending/` and nothing in `running/`, it picks one,
  moves it to `running/`, runs the full ingest pipeline (Steps 1–8 + 8.5),
  moves the result to `done/` (or `failed/`), and returns `{action: "pick", …}`.
- If there's already a job in `running/`, it returns `{action: "noop", reason: "running_busy"}`
  with exit 0. **This is the normal scheduled-drainer outcome and must
  not page operators.**
- If the queue is empty, it returns `{action: "noop", reason: "queue_empty"}`
  with exit 0. Also normal.
- If every pending job has a future `scheduled_at`, it returns
  `{action: "noop", reason: "all_scheduled_future"}`. Also normal.

A scheduled drainer never reads or writes queue files directly. It never
calls `--complete`, `--retry`, or `--enqueue`. It calls `--next` and
walks away.

## What a scheduled drainer is **not** allowed to do

- Touch `.cogni-wiki/queue/` directly. Use the dispatcher.
- Call `--next` faster than the slowest expected ingest. If your ingests
  take 90 seconds and you tick every 30 seconds, you'll just pile up `running_busy`
  noops — harmless, but wasteful. A 5–10× margin is fine.
- Run multiple drainers against the same wiki without a way for them to
  observe each other's commits (the GitHub Actions shape uses `git push`
  for this; Cloud Routine relies on the file lock; local cron is implicitly
  single-runner; `/loop` runs in one session). If you need a multi-runner
  setup that isn't git-hosted, talk to T3.2 first — that's not in scope.

## Drainer-hint nudge in wiki-resume

`wiki-resume` (v0.0.39+) surfaces a "set up a scheduled drainer" hint
when:

- `queue.pending > 0` (there's work queued)
- `queue.running == 0` (nothing is currently draining)
- `queue.oldest_pending_age_hours > drainer_hint_threshold_hours` (the
  oldest pending job has been sitting longer than the configured threshold,
  default 24h)
- `queue.last_next_at is null` OR `queue.last_next_age_hours > drainer_hint_threshold_hours`
  (no `--next` has completed within the threshold window)

The threshold is configurable per wiki via `drainer_hint_threshold_hours`
in `.cogni-wiki/config.json`; the default is 24. The combination prevents
nagging a user who is actively draining manually — the hint only fires
when the queue is genuinely *stalled*.

When the hint fires, `wiki-resume` points the user back at this directory.

## References

- `cogni-wiki/skills/wiki-ingest/SKILL.md` — Mode D dispatcher contract
- `cogni-wiki/skills/wiki-ingest/scripts/wiki_queue.py` — the queue script
- `cogni-wiki/skills/wiki-resume/SKILL.md` — Rule 5a (the drainer hint)
- Parent tracking issue: cogni-work/insight-wave#212
- T3.1 spine PR: cogni-work/insight-wave#231
- T3.2 issue (this work): cogni-work/insight-wave#232
