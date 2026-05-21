---
name: knowledge-curate
description: "Phase 2 of the v0.1.0 inverted pipeline. Reads plan.json, dispatches one source-curator agent per sub-question to WebSearch + score candidate sources, merges the per-sub-question batches into candidates.json via candidate-store.py. Does NOT fetch URL bodies — that is Phase 3 (knowledge-fetch). Use this skill whenever the user says 'curate sources for the eu-ai-act plan', 'discover candidates for project X', 'run the curators on plan.json', 'knowledge curate', 'phase 2 of the knowledge pipeline'. After curate, run knowledge-fetch to materialize bodies into the shared fetch-cache."
allowed-tools: Read, Write, Bash, Glob, Skill, Task
---

# Knowledge Curate

Phase 2 of the v0.1.0 inverted pipeline. Reads `<project>/.metadata/plan.json`, fans out one `source-curator` dispatch per sub-question (WebSearch + scoring, no fetching), and merges the per-sub-question candidate batches into the canonical `<project>/.metadata/candidates.json` via `candidate-store.py append-batch`.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 2 — `knowledge-curate`" once to anchor on the contract.

## When to run

- `plan.json` exists for the project (Phase 1 has run) AND `candidates.json` does not yet exist (or the user explicitly wants a re-curate)
- User explicitly invokes `/cogni-knowledge:knowledge-curate`

## Never run when

- No `plan.json` exists at `<project_path>/.metadata/` — offer `knowledge-plan` first.
- No `binding.json` exists at the resolved knowledge root — offer `knowledge-setup` first.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory (produced by `knowledge-plan`). |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--sub-question-ids` | No | Comma-separated subset of sub-question ids to curate (e.g. `sq-01,sq-03`). Default: all from `plan.json`. Useful for resuming a partial curate. |
| `--dry-run` | No | Print the dispatch plan without running curators. |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break — no cogni-research dispatch):

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK=no`, abort with the standard missing-plugin message.

**Binding + plan.** Resolve `knowledge_root` (same logic as `knowledge-plan`). Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`.

Read `<project_path>/.metadata/plan.json`. Parse `topic`, `market`, `output_language`, `sub_questions[]`. If `--sub-question-ids` was passed, filter to that subset (reject ids not present).

### 1. Read curator defaults

From the binding envelope above, parse `data.binding.curator_defaults`. Apply per-field fallbacks for legacy bindings (pre-v0.0.3 had no `curator_defaults` block; the consumer-side `.get(..., DEFAULT)` requirement is documented in `CLAUDE.md` §"Data model"):

| Field | Default |
|---|---|
| `max_candidates_per_sq` | 12 |
| `score_threshold` | 0.5 |
| `fetch_cache_max_age_days` | 30 (not used here; carries through for Phase 3) |

### 2. Initialize candidates.json

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py init \
    --project-path <project_path>
```

Idempotent — safe to re-run after a partial curate.

### 3. Dispatch source-curator per sub-question

For each sub-question id selected in Step 0:

1. Define the batch output path: `<project_path>/.metadata/.candidates.batch.<sq-id>.json` (leading dot keeps it out of casual ls; the file is intermediate state).

2. Dispatch via the `Task` tool (matches the upstream `cogni-research/skills/research-report` agent-dispatch convention at lines 408, 559):
   ```
   Task(source-curator,
        PROJECT_PATH=<project_path>,
        SUB_QUESTION_ID=<sq-id>,
        BATCH_OUTPUT_PATH=<batch_path>,
        MARKET=<market>,
        MAX_CANDIDATES=<max_candidates_per_sq>,
        SCORE_THRESHOLD=<score_threshold>)
   ```

   `source-curator` lives at `${CLAUDE_PLUGIN_ROOT}/agents/source-curator.md` — agents are dispatched via `Task`, not `Skill` (which is for sibling skills).

3. Default cadence: dispatch sub-questions in parallel **when 3 or fewer**; otherwise sequential. Parallelism helps wall-clock but each curator does its own WebSearch — three concurrent curators is the rate-limit-friendly ceiling. (Phase 3 / `knowledge-fetch` runs batches strictly sequentially for a related but stricter reason — see that skill's Step 3 for the rationale.)

4. After each curator returns successfully, merge the batch:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py append-batch \
       --project-path <project_path> \
       --batch-file <batch_path>
   ```

   `append-batch` is file-locked (`fcntl.flock`) so concurrent merges from parallel curators are safe.

5. On a curator failure (`{"ok": false, …}` summary, or a missing batch file), record the sq-id in a `failed_curators[]` collection and continue. Do not abort the skill — partial coverage is better than zero coverage.

### 4. Final read + summary

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py read \
    --project-path <project_path>
```

Parse the result for the final summary. Print ≤ 8 lines:

- Project: `<topic>` at `<project_path>`
- Curators dispatched: `<count>` (failed: `<failed_count>`)
- Candidates: `<total>` (`<primary_count>` primary / `<secondary_count>` secondary / `<supporting_count>` supporting)
- Cost: `$X.XX` (sum of `cost_estimate.estimated_usd` across curator return summaries)
- Failed sub-questions (if any): `sq-NN, sq-MM` — re-run with `--sub-question-ids sq-NN,sq-MM`
- Next: run `knowledge-fetch --knowledge-slug <slug> --project-path <project_path>` to materialize bodies

## Edge cases

- **Re-curate of an existing project.** `candidates.json` already exists. `candidate-store.py init` is idempotent (no overwrite). Curators dispatched again will re-emit batches; the merge step dedupes by URL, unions sub-question refs, and keeps the higher score. Pre-existing entries from other sub-questions are preserved.
- **Curator emits zero candidates.** Either the topic is too obscure for web sources or the score threshold is too high. Surface as a warning; the operator can re-run with `--sub-question-ids <id>` after adjusting `binding.curator_defaults.score_threshold` (manual edit, no skill yet).
- **Plan has a sub-question id the user did not pass.** Skip — only dispatch the explicitly requested subset. The skipped sq-ids will not appear in `candidates.json`'s `sub_question_refs` until re-run.

## Out of scope

- Does NOT WebFetch (Phase 3 / `source-fetcher`).
- Does NOT touch the wiki — wiki ingest is Phase 4 (`knowledge-ingest`, not yet shipped).
- Does NOT modify `plan.json` or `binding.json`.
- Does NOT support tuning of scoring weights via CLI (forked composite weights are local to `agents/source-curator.md`; edit there).

## Output

- `<project_path>/.metadata/candidates.json` (schema 0.1.0; merged + tier-stamped + priority-assigned)
- `<project_path>/.metadata/.candidates.batch.<sq-id>.json` for each dispatched sub-question (intermediate; safe to clean up but kept for debugging)

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 2 contract
- `${CLAUDE_PLUGIN_ROOT}/agents/source-curator.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
