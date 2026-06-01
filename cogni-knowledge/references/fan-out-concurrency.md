# Fan-out concurrency posture (cogni-knowledge)

Why `knowledge-ingest` defaults `--batch-size` to **25**, dispatched as **one wave per batch**, and how
that sits alongside the other fan-out phases. This is the reasoned answer to #323 — formalized from the
existing #311 live data, not a fresh benchmark.

The single live data point this rests on: the #311 German bake-in run dispatched **67 ingesters as two
waves of 25/26 with no issue** (`references/alpha-findings.md` F30/#323). ~25 concurrent ran clean.

## 1. The Claude Code concurrent-subagent ceiling

A phase fans out by issuing N `Task` dispatches in **one assistant message with multiple tool calls**.
Claude Code self-throttles the actual concurrency: dispatches beyond its internal ceiling are queued and
run as slots free, but **all of them complete and return**. So a single-message wave of 25 is not 25
simultaneous agents — it is "submit 25, let CC schedule them" — and the operator does not have to hand-size
the wave to the runtime's ceiling. The #311 run is the proof: 25/26 per wave, clean, end-to-end.

The consequence for ingest: the old "parallel within batch, **sequential across batches**" cadence with
`--batch-size 8` was not protecting against a concurrency limit — CC already throttles. It was paying a
**per-wave barrier** (each wave gated by its slowest ingester) far more often than necessary. A 67-source
run was 9 sequential barriers; at a 25-wide wave it is ~3. The barrier, not concurrency, was the cost.

## 2. Where returns / observability degrade

What grows with wave width is **per-message return volume**, not total work. cogni-knowledge's ingester
keeps that flat by design: `source-ingester` returns only a tiny envelope, and the substantive result
(the per-source merge record) lands in its own `BATCH_OUTPUT_PATH` file that Step 3.4 reads off disk. So a
wider wave does not bloat what the orchestrator has to hold in-context, and ingest fan-out stays
observable at 25. The per-batch barrier is retained only so the Step 3.4 merge stays incremental and a
crashed wave re-runs from `ingested[]` (the re-run no-op) — it is a checkpoint boundary, not a throttle.

## 3. The right default

**25.** It is the widest wave with live evidence of running clean, it collapses the common case (≤25
sources) to a single wave / single barrier, and it cuts a large run's barrier count by ~3×. Going wider
has no live evidence and only widens the merge checkpoint; staying at 8 keeps paying barriers for no
concurrency benefit. `--batch-size` remains advisory — an operator can lower it to checkpoint more often,
or raise it once a larger wave is proven.

## 4. Derived vs guessed — the cross-phase posture

Each fan-out phase sizes its wave from the most honest basis available to it:

| Phase | Fan-out unit | Default | Basis |
|---|---|---|---|
| `knowledge-curate` (Phase 2) | one `source-curator` per sub-question | N ≤ 7 | **plan-cap-derived** — `knowledge-plan` caps a plan at 3–7 sub-questions, so one wave always covers the plan (#299). |
| `knowledge-ingest` (Phase 4) | one `source-ingester` per fetched source | `--batch-size` 25 | **live-observation-calibrated** — N is *unbounded* (a run can fetch dozens of sources), so it cannot be plan-capped; 25 is the proven live wave (#311 / #323). |
| `knowledge-verify` (Phase 6) | one `wiki-verifier` per citation shard | `--shard-size` 40 | **wall-clock-calibrated** — shard width tuned so a shard verifies in ≤ ~5 min (`verify-store.py`, #286). |

Ingest is the only phase with an unbounded N and no natural per-unit time budget, so live observation is
its closest honest analog to curate's "derived, not guessed" — hence 25, with this doc as the record.

## 5. The correctness counterweight to a wider wave

A wider wave widens one risk the barrier was incidentally masking: with many `source-ingester` dispatches
live in a single message, two can cross-talk and one composes its page from a sibling's fetched body, so a
page lands on disk carrying the wrong source's `id:` / `sources:` URL / claims. This is non-deterministic
LLM attention cross-talk, not a code path, so it cannot be prompted away or sized away. It is held by a
deterministic post-wave check, not by shrinking the wave back to 8: `knowledge-ingest` Step 3.5 runs an
integrity sweep (`ingest-integrity.py`) after each batch's merge, comparing every on-disk page against the
orchestrator's authoritative dispatch record (`(slug, url)` assigned at dispatch time), and quarantines any
page whose `id:` ≠ slug or whose `sources:` URL ≠ the dispatched URL before Step 4 indexes it (a
`source-ingester` Phase 3 pre-write assertion is the cheap in-agent first line). The sweep is what keeps
batch-size 25 safe: throughput from the wider wave, correctness from the deterministic check — the two are
orthogonal, so neither has to be traded for the other.
