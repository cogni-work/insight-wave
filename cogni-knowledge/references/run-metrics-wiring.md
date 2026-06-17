# Run-metrics ledger — phase-exit wiring contract

Each pipeline phase (`knowledge-plan` … `knowledge-finalize`) persists one row to
`<project_path>/.metadata/run-metrics.json` at phase exit via
`scripts/run-metrics.py record`, so a research run leaves a **durable per-phase
timing + cost ledger** the read-side skills (`knowledge-resume`,
`knowledge-dashboard`) and any perf study can read without hand-instrumenting the
pipeline. The phases already compute cost + agent counts in their final summary;
this just persists them — the only new work is capturing the phase's start time.

`knowledge-setup` is **excluded**: it is a one-time base bootstrap that runs
*before* any project directory exists, so it has no `<project_path>/.metadata/`
to write into. The ledger spans `plan → finalize`, which is the actual research
run.

## The contract (each phase skill)

1. **At the top of the workflow** (pre-flight / Step 0), capture the phase start:

   ```
   PHASE_START=$(date -u +%FT%TZ)
   ```

2. **At phase exit** (immediately after the Final summary step), record the row.
   The phase name is fixed per skill; `--agent-count` is the number of subagents
   this phase dispatched (0 for the script-only phases — `fetch`); `--cost-usd`
   is the sum of `cost_estimate.estimated_usd` across this phase's agent returns
   (the same numbers the Final summary already prints):

   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" record \
       --project-path "<project_path>" \
       --phase <plan|curate|fetch|ingest|compose|verify|finalize> \
       --started-at "$PHASE_START" --ended-at "$(date -u +%FT%TZ)" \
       --agent-count <N> \
       --cost-usd <summed estimated_usd, default 0>
   ```

   The script computes `elapsed_s` from the two timestamps and appends the row.

**Fail-soft, always.** A `run-metrics.py record` failure (missing `.metadata/`,
unreadable ledger, etc.) **never blocks the phase** — the ledger is observability
only, and `record` already degrades gracefully (a corrupt ledger is reset, not
fatal). Surface a one-line warning at most.

**Append-only.** A re-run of a phase appends a new row rather than overwriting;
`run-metrics.py report` sums all rows, so retries stay visible.

## Reading it back

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" report --project-path "<project_path>"
```

returns the per-phase rows, `totals {elapsed_s, elapsed_min, cost_estimate_usd,
agent_count}`, and a rendered table — the read surface for a `knowledge-resume`
timeline view or a perf study.
