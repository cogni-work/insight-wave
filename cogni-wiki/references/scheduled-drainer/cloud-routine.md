# Cloud Routine drainer

The recommended scheduled-drainer shape when the wiki is **not** hosted in
a GitHub repo (corporate-banned, GitLab-only, local-only with internet
access, etc.) but you still want durable, API-triggerable, sleep-surviving
automation.

Cloud Routine is the Anthropic-managed scheduled-agent primitive. It runs
on Anthropic infrastructure, fires on a cron schedule (or one-off date),
and invokes a Claude Code prompt — perfect for `/cogni-wiki:wiki-ingest --next`.

## Why this shape

- **Survives laptop sleep.** Unlike `/loop`, the schedule runs in the
  cloud, so it ticks even when your machine is closed.
- **API-triggerable.** You can fire the drainer on demand from a
  separate workflow (e.g. after dropping a batch of files in `raw/`).
- **No GitHub required.** Works against any wiki path Claude Code can
  reach — including local paths if the routine is configured to operate
  on your machine, or remote paths if you've set up the appropriate
  workspace bindings.
- **No new state machinery.** Like GitHub Actions, Cloud Routine is just
  a re-entrant invocation of `wiki-ingest --next`; T3.1's queue files +
  `_wiki_lock` handle correctness.

## Trade-offs vs GitHub Actions

| | GitHub Actions | Cloud Routine |
|---|---|---|
| Durability | Free (commit log) | Anthropic-managed |
| Cross-runner coordination | `git push` | `_wiki_lock` only (single-runner per wiki) |
| Audit trail | Commit log | Routine run history |
| Setup complexity | Workflow YAML + repo secret | One `/schedule` invocation |
| Multi-runner safe | Yes (git rebase-and-retry) | No — single routine per wiki |
| Requires GitHub | Yes | No |

If you have GitHub access, prefer GitHub Actions. If you don't, Cloud
Routine is the natural next step.

## Creating the routine

Use the `/schedule` skill (or its `cron` variant) to create the routine:

```
/schedule "every 1h: claude -p --bare '/cogni-wiki:wiki-ingest --next' --cwd /path/to/your/wiki"
```

Or, equivalently:

```
/schedule create \
  --name "wiki-drain" \
  --cron "0 * * * *" \
  --prompt "/cogni-wiki:wiki-ingest --next" \
  --cwd /path/to/your/wiki
```

The `--cwd` argument tells Claude Code where to find the wiki —
`wiki-ingest` walks upward from the current working directory to locate
the nearest `.cogni-wiki/config.json`, so the cwd must be inside the
wiki tree.

## Picking a cadence

Same trade-off as GitHub Actions:

| Cadence | When | Notes |
|---|---|---|
| `*/5 * * * *` | High-volume wiki | Faster drain, more Cloud Routine invocations. |
| `0 * * * *` | **Default**, sane for most wikis | Recommended starting point. |
| `0 */6 * * *` | Low-volume | Lower cost; up to 6h backlog. |
| `0 9 * * *` | Very low volume | Daily-batch style. |

`--next` is exit-0 on `noop`, so over-ticking is harmless.

## Monitoring

```
/schedule list                    # see all your routines
/schedule status wiki-drain       # check last N runs of this routine
/schedule logs wiki-drain         # full log output
```

If the routine starts returning `running_busy` repeatedly, a prior tick
crashed mid-ingest and left a job in `running/`. Run `wiki-resume` to
surface the stuck job, then `wiki-ingest --queue-retry <id>` to recycle
it (manual one-shot; Cloud Routine cannot do this for you because it
would need to inspect queue state directly, which is out of the runner's
contract).

## Pausing or stopping

```
/schedule pause wiki-drain
/schedule resume wiki-drain
/schedule delete wiki-drain
```

Pausing leaves the queue intact — it just stops new `--next` ticks. Any
job currently in `running/` continues until the current invocation
completes (or crashes).

## Multi-wiki setups

Create one routine per wiki:

```
/schedule create --name "wiki-drain-research" --cron "0 * * * *" \
  --prompt "/cogni-wiki:wiki-ingest --next" --cwd /path/to/research-wiki

/schedule create --name "wiki-drain-consulting" --cron "15 * * * *" \
  --prompt "/cogni-wiki:wiki-ingest --next" --cwd /path/to/consulting-wiki
```

Stagger the cron expressions (`0 * * * *` and `15 * * * *` above) if
running them at the same minute would otherwise contend for the same
API quota or local resource. The queues themselves are per-wiki and
don't interfere with each other.

## When **not** to use Cloud Routine

- The wiki is already in a GitHub repo. → Use GitHub Actions (free durability,
  free audit trail, multi-runner safe).
- The wiki is on a machine with no external network access (air-gapped).
  → Use [local cron / launchd / systemd-timer](local-cron.md) instead.
- You want to iterate on a new ingest source set in real time while a
  Claude Code session is open. → Use [`/loop`](loop.md) for the iteration
  phase, then promote to Cloud Routine (or GitHub Actions) once the source
  set is stable.

## References

- `/schedule` skill — the Cloud Routine entry point
- `cogni-wiki/skills/wiki-ingest/SKILL.md` — Mode D dispatcher contract
- `cogni-wiki/references/scheduled-drainer/README.md` — selector + rationale
