# GitHub Actions drainer (recommended)

The recommended scheduled-drainer shape when the wiki is hosted in a git
repository on GitHub. Two templates ship here:

- **`wiki-daily-ingest.yml`** — the drainer itself. Fires on a cron schedule,
  pulls the latest queue state, runs `wiki-ingest --next`, commits and pushes
  any changes. **In scope for T3.2.**
- **`wiki-daily-discover.yml`** — a placeholder for the future T3.7 discovery
  → enqueue bridge (an automated `--discover orphans --discover-dry-run`-style
  scan that auto-enqueues newly-arrived orphan raw files). **Out of scope
  until T3.7 lands.**

## Why this is the recommended shape

`git push` is the cross-runner coordination primitive. Two runners racing
each other for the same job is harmless: the loser's push fails, and on
the next tick it pulls the winner's commit and finds the job already in
`done/`. No new lock primitive on top of `_wiki_lock`. Portability claim
survives — the wiki is still plain markdown, it just happens to live in a
git remote. Bonus durability + audit trail come free from the commit log.

## Prerequisites

- Wiki lives at the root of a GitHub repo (or in a subdirectory you can
  `cd` into; adjust paths accordingly).
- The repo has Claude Code billing configured (Actions calls the Claude
  Code CLI which needs API access).
- The Actions runner has write access to the repo (`contents: write`
  permission) so it can `git push` queue state changes.

## Drainer template: `wiki-daily-ingest.yml`

Copy this into your wiki repo at `.github/workflows/wiki-daily-ingest.yml`:

```yaml
name: wiki-daily-ingest

on:
  schedule:
    # Tick hourly. 5-min cadence is also viable — see "Picking a cadence" below.
    - cron: '0 * * * *'
  workflow_dispatch:  # allow manual trigger from the Actions tab

# Re-entrant runs cancel each other rather than queue up. The queue's own
# single-worker semantics make queued workflow runs harmless but wasteful.
concurrency:
  group: ${{ github.workflow }}
  cancel-in-progress: false  # don't kill an in-flight ingest mid-write

permissions:
  contents: write  # needed to commit queue state changes back

jobs:
  drain:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # 5–10x the slowest expected ingest

    steps:
      - name: Checkout wiki repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 1
          # token: ${{ secrets.GITHUB_TOKEN }} is implicit

      - name: Install Claude Code CLI
        run: |
          curl -fsSL https://claude.ai/install.sh | sh
          echo "$HOME/.local/bin" >> "$GITHUB_PATH"

      - name: Authenticate Claude Code
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # ANTHROPIC_API_KEY is read by the CLI at invocation time;
          # no separate `claude login` step is needed for non-interactive use.
          echo "Claude Code CLI ready ($(claude --version))"

      - name: Drain one queue job
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # --bare suppresses interactive prompts and produces machine-readable output.
          # The dispatcher exits 0 on noop (queue_empty / running_busy / all_scheduled_future)
          # so we never page the operator for normal "nothing to do" outcomes.
          claude -p --bare "/cogni-wiki:wiki-ingest --next"

      - name: Commit and push queue state changes
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          # If --next was a noop, there's nothing to commit. `git diff --quiet`
          # returns 0 when there are no changes; we treat that as success.
          if git diff --quiet && git diff --cached --quiet; then
            echo "No queue state changes — nothing to commit."
            exit 0
          fi

          git add -A
          git commit -m "wiki-ingest: drain one queue job

Auto-commit from .github/workflows/wiki-daily-ingest.yml

[skip ci]"
          # Retry once on rebase race — another runner may have just pushed.
          git pull --rebase origin "${{ github.ref_name }}" || true
          git push origin "HEAD:${{ github.ref_name }}"
```

### What this workflow does, step by step

1. **Checkout** — pulls the latest queue state from the repo. If another
   runner just landed a commit, this pulls it in, so we don't race against
   stale state.
2. **Install + auth** — installs the Claude Code CLI and authenticates
   via the `ANTHROPIC_API_KEY` repo secret.
3. **Drain one** — runs `wiki-ingest --next` exactly once. If the queue
   has work, the picked job moves to `running/`, the full ingest pipeline
   (Steps 1–8 + 8.5) runs, and the result moves to `done/` (or `failed/`).
   If the queue is empty or busy, the dispatcher returns a noop and exits 0.
4. **Commit + push** — if queue state changed (any of `pending/`,
   `running/`, `done/`, `failed/`, or the wiki pages themselves moved),
   commit and push. The `git pull --rebase` before push handles the case
   where two runners fired close enough together that one of them lost.

### Picking a cadence

| Cadence | When | Notes |
|---|---|---|
| `*/5 * * * *` (5 min) | High-volume wiki, queue is rarely empty | More cost (more runs), faster drain. Most ticks will be noops once you catch up. |
| `0 * * * *` (hourly) | **Default**, sane for most wikis | Recommended starting point. Adjust if backlog grows. |
| `0 */6 * * *` (every 6h) | Low-volume, mostly-empty wiki | Lower cost; backlog can grow to ~6h. |
| `0 9 * * *` (daily 9am) | Very low volume, batch-style | Treat the wiki as a daily-batch system. |

The dispatcher exits 0 on `noop`, so over-ticking is harmless — every tick
that finds the queue empty (or running busy) is a quiet no-op. Under-tick
only if cost matters.

### Two runners on the same repo

Safe. The losing push gets a non-fast-forward error, the workflow retries
once via `git pull --rebase`, and either lands or finds the job already
done on the next tick. The queue dispatcher's `_wiki_lock` is a local
filesystem lock and does not coordinate across hosts — but it doesn't need
to, because `git push` does.

If you need horizontal scale beyond what a single repo can handle, you
should be questioning whether cogni-wiki is the right primitive for that
load, not adding more runners.

## Discovery template (future T3.7): `wiki-daily-discover.yml`

**Out of scope until T3.7 lands.** Sketch of the eventual shape:

```yaml
name: wiki-daily-discover

on:
  schedule:
    - cron: '0 6 * * *'  # daily at 06:00 UTC
  workflow_dispatch:

permissions:
  contents: write

jobs:
  discover:
    runs-on: ubuntu-latest
    timeout-minutes: 10

    steps:
      - uses: actions/checkout@v4

      - name: Install Claude Code CLI
        run: curl -fsSL https://claude.ai/install.sh | sh

      - name: Discover orphans and auto-enqueue
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # T3.7 will define the exact --discover invocation that auto-enqueues
          # rather than auto-ingests. Until then this workflow does nothing.
          echo "T3.7 discovery → enqueue bridge — not yet implemented."

      - name: Commit any newly-enqueued jobs
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          if git diff --quiet && git diff --cached --quiet; then
            exit 0
          fi
          git add -A
          git commit -m "wiki-discover: auto-enqueue orphans [skip ci]"
          git push origin "HEAD:${{ github.ref_name }}"
```

The discovery bridge fires less often than the drainer because newly-arrived
raw files don't need to be picked up the same minute they land — daily is
fine, weekly might be fine. T3.7 will pin the cadence and the exact flag
shape on the `wiki-ingest --discover` side.

## Troubleshooting

- **`git push` rejected on every run** — another workflow run is also
  pushing. Confirm `concurrency:` is set to `cancel-in-progress: false`
  (kills in-flight ingests) — the current template has it that way. If you
  intentionally want only one workflow run at a time, set `cancel-in-progress: true`,
  but be aware that you'll lose any partial state from cancelled runs.
- **Backlog grows even though the workflow runs** — confirm the workflow
  is actually finding work. If every run logs `action: "noop", reason: "queue_empty"`
  but the queue has jobs, you're probably checking out the wrong branch or
  the queue dir is `.gitignore`d (it should not be — the queue is shared
  state).
- **`--next` keeps returning `running_busy`** — a prior run crashed
  mid-ingest and left a job in `running/`. Use `wiki-resume` to surface
  the stuck job, then `wiki-ingest --queue-retry <id>` to recycle it.

## References

- `cogni-wiki/skills/wiki-ingest/SKILL.md` — Mode D dispatcher contract
- `cogni-wiki/references/scheduled-drainer/README.md` — selector + rationale
- Parent rationale: cogni-work/insight-wave#212#issuecomment-4407279057
