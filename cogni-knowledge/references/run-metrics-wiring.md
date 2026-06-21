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
   (the same numbers the Final summary already prints); `--max-agent-duration-ms`
   (optional, default 0) is the slowest single agent's wall-clock milliseconds in
   this phase — pass it for a fan-out phase whose agents self-report a
   `duration_ms` (e.g. `ingest`, where every `source-ingester` returns one):

   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" record \
       --project-path "<project_path>" \
       --phase <plan|curate|fetch|ingest|compose|verify|finalize> \
       --started-at "$PHASE_START" --ended-at "$(date -u +%FT%TZ)" \
       --agent-count <N> \
       --cost-usd <summed estimated_usd, default 0> \
       --max-agent-duration-ms <slowest agent's duration_ms, default 0>
   ```

   The script computes `elapsed_s` from the two timestamps and appends the row.
   Recording `max_agent_duration_ms` makes the orchestrator **serial tail**
   directly readable from the ledger — `serial_tail ≈ elapsed_s −
   max_agent_duration_ms/1000` separates the concurrent agent wave from the
   sequential orchestration after it, instead of having to infer it. A phase
   whose agents do not report a per-agent duration simply omits the flag (the
   row stores `max_agent_duration_ms: 0`).

**Fail-soft, always.** A `run-metrics.py record` failure (missing `.metadata/`,
unreadable ledger, etc.) **never blocks the phase** — the ledger is observability
only, and `record` already degrades gracefully (a corrupt ledger is reset, not
fatal). Surface a one-line warning at most.

**Append-only.** A re-run of a phase appends a new row rather than overwriting;
`run-metrics.py report` sums all rows, so retries stay visible.

## Computing `MAX_DURATION_MS` per fan-out phase

`--max-agent-duration-ms` is only as good as the per-agent `duration_ms` the
phase can see. For a fan-out phase the pattern is **init → accumulate → pass**:

1. **Init** — at the top of the workflow (Step 0), alongside `PHASE_START`,
   initialise a run-level accumulator `MAX_DURATION_MS=0`.
2. **Accumulate** — wherever the orchestrator reads each dispatched agent's
   return summary (the same place it sums `cost_estimate.estimated_usd`), fold
   the agent's reported `duration_ms` in: `MAX_DURATION_MS = max(MAX_DURATION_MS,
   duration_ms)`. **Fail-soft** — an agent return without a `duration_ms` (an
   older envelope, or an early abort that returned before its start clock was
   captured) contributes `0` and never breaks the accumulation.
3. **Pass** — at phase exit, pass `--max-agent-duration-ms <MAX_DURATION_MS>` to
   `run-metrics.py record`.

### Option A — agent self-reports `duration_ms`

An agent self-captures a start timestamp only if it has the `Bash` tool — e.g.
`START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')` in its load
phase, then `duration_ms = int(time.time()*1000) - START_MS` in its return
envelope. `source-ingester` (the `ingest` phase) and `source-curator` (the
`curate` phase) follow this pattern and are the live examples. Under Option A the
orchestrator's **accumulate** step (above) reads each agent's reported
`duration_ms` directly.

### Option B — orchestrator measures each dispatch's wall clock

A fan-out phase whose agents lack the `Bash` tool cannot self-capture a start
clock, so the orchestrator (which already has `Bash`) measures each dispatched
`Task`'s wall clock itself. This is the chosen mechanism for the **`compose`**
and **`verify`** phases — `wiki-composer` / `wiki-verifier` / `revisor` have no
`Bash` tool (the `revisor` dropped it deliberately for its zero-network
contract), so giving them the tool just to instrument a metric was rejected in
favour of orchestrator-side timing. The init → accumulate → pass shape is
identical; only the *source* of each `duration_ms` differs.

- **Per-dispatch (serial)** — stamp immediately before each `Task` and fold
  immediately after it returns:

  ```
  START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')
  # … Task(agent, …) …
  MAX_DURATION_MS=$(python3 -c "import time; print(max($MAX_DURATION_MS, int(time.time()*1000) - $START_MS))")
  ```

  `knowledge-compose` (the single composer dispatch + the optional Step 5.5
  expansion re-dispatch) and `knowledge-verify`'s serial revisor rounds use this
  form.

- **Per-wave (parallel fan-out)** — stamp once before the single-message batch
  of N `Task` calls, and fold the **batch** wall-clock once after all N return:

  ```
  WAVE_START_MS=$(python3 -c 'import time; print(int(time.time()*1000))')
  # … one message: Task(agent, shard 1) … Task(agent, shard N) … (all return) …
  MAX_DURATION_MS=$(python3 -c "import time; print(max($MAX_DURATION_MS, int(time.time()*1000) - $WAVE_START_MS))")
  ```

  `knowledge-verify`'s parallel `wiki-verifier` shard wave (Step 3.1c) uses this
  form. The batch elapsed is **one timing sample for the whole wave** — an upper
  bound on the slowest individual shard, not a per-shard max — but because a
  parallel wave's wall-clock *is* the slowest shard's wall-clock, it is exactly
  the per-phase `max` the serial-tail figure needs. Fail-soft throughout: an
  unset `START_MS`/`WAVE_START_MS` contributes `0` and never aborts the phase.

A phase whose agents lack `Bash` and that has **not yet** adopted Option B
contributes `0` and the row stores `max_agent_duration_ms: 0` — honest, not
misleading.

## Reading it back

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" report --project-path "<project_path>"
```

returns the per-phase rows, `totals {elapsed_s, elapsed_min, cost_estimate_usd,
agent_count, max_agent_duration_ms}`, and a rendered table (with a per-phase
`max_agent_s` column) — the read surface for a `knowledge-resume` timeline view
or a perf study. The `totals.max_agent_duration_ms` is the max across phases (the
longest single agent of the run, not a sum — a slowest-agent figure does not add).
