---
name: knowledge-curate
description: "Phase 2 of the v0.1.0 inverted pipeline. Reads plan.json, dispatches one source-curator agent per sub-question to WebSearch + score candidate sources AND fetch each survivor's body via WebFetch (Option B, #292) into the shared fetch-cache, then merges the per-sub-question batches into candidates.json via candidate-store.py. Each candidate carries a fetch sub-object. Use this skill whenever the user says 'curate sources for the eu-ai-act plan', 'discover candidates for project X', 'run the curators on plan.json', 'knowledge curate', 'phase 2 of the knowledge pipeline'. After curate, run knowledge-fetch (cobrowse reconcile; a near no-op unless --cobrowse)."
allowed-tools: Read, Write, Bash, Glob, Skill, Task
---

# Knowledge Curate

Phase 2 of the v0.1.0 inverted pipeline. Reads `<project>/.metadata/plan.json`, fans out one `source-curator` dispatch per sub-question (WebSearch + scoring, then a WebFetch body-pull of each survivor into the shared fetch-cache — Option B, #292), and merges the per-sub-question candidate batches into the canonical `<project>/.metadata/candidates.json` via `candidate-store.py append-batch`. Each merged candidate carries a `fetch` sub-object recording cache key / content hash on success or the unavailable reason on a WebFetch miss.

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

**Resolve the market config ONCE (orchestrator-owned, #304).** Each `source-curator` used to resolve the market config itself via an env-gated glob (`WORKSPACE_PLUGIN_ROOT` is usually unset in a subagent, so the resolution was flaky — one shard could silently fall back to `_default` while siblings loaded the real market). Resolve it here instead, in skill context where the env is consistent, and pass the result to every curator. Locate cogni-workspace's `get-market-config.py` with the same three-layer fallback the script uses internally (`get-market-config.py::_resolve_sibling_plugin`) and that sibling skills use for `resolve_wiki_ingest_scripts`:

```
resolve_market_config_script() {
  # 1. Explicit env (skill context may have it; subagents usually don't).
  if [ -n "${WORKSPACE_PLUGIN_ROOT:-}" ] && \
     [ -f "${WORKSPACE_PLUGIN_ROOT}/scripts/get-market-config.py" ]; then
    echo "${WORKSPACE_PLUGIN_ROOT}/scripts/get-market-config.py"; return 0
  fi
  # 2. Monorepo sibling.
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-workspace/scripts/get-market-config.py"
  [ -f "$sib" ] && { echo "$sib"; return 0; }
  # 3. Cache: newest installed cogni-workspace (mtime; lex-sort mis-ranks 0.6.10 < 0.6.9).
  local newest
  newest=$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-workspace/*/scripts/get-market-config.py 2>/dev/null | head -1)
  [ -n "$newest" ] && { echo "$newest"; return 0; }
  return 1
}
MARKET_CONFIG_SCRIPT=$(resolve_market_config_script) || abort "cogni-workspace get-market-config.py not found — fix the workspace install before curating"
```

Run it **once** for this run's `<market>` and capture the full stdout envelope:

```
python3 "$MARKET_CONFIG_SCRIPT" --plugin research --market <market>
```

The envelope is `{"success", "data", "error"}`; on success `data` is the merged market config (it carries `data.code == "<market>"` and a populated `data.authority_sources[]`).

**Fail loudly — abort on either condition (do NOT proceed with `_default`):**

1. The script exec fails / output is not parseable JSON, **or** the envelope's `success` is `false` → abort.
2. The envelope's `success` is `true` **but** `data` is the `_default` fallback. The cogni-research overlay carries a `_default` entry, so an unknown / unsupported market resolves to `success: true` with the `_default` config (empty `authority_sources: []`, a `_note` key, and **no `code` field**) — a bare `success` check would silently accept it. Detect `_default` by the **absence of a non-empty `data.code`** (every real registry/overlay market carries `code`; `_default` does not) and abort.

Abort message: `could not resolve market config for '<market>' (script failed, or the market resolved to the _default fallback) — fix the workspace install or correct the market code in plan.json before curating`. A wrong authority list degrades the whole run's scoring, so this is a hard stop, not per-curator partial coverage.

On success, write the **full stdout envelope verbatim** to `<project_path>/.metadata/market-config.json` (`.metadata/` already exists — `plan.json` lives there). This is the single resolution every curator reads. In `--dry-run`, resolve + validate (so a bad market / missing workspace is still caught early), print `MARKET=<market> AUTHORITY_SOURCES=<count from data.authority_sources>` plus the per-sub-question dispatch plan, then **stop** — do **not** write `market-config.json` and do **not** dispatch curators (this is `--dry-run`'s "print the dispatch plan without running curators" contract; stopping here is also what keeps the not-written file from being referenced by a Step 3 dispatch).

### 1. Read curator defaults

From the binding envelope above, parse `data.binding.curator_defaults`. Apply per-field fallbacks for legacy bindings (pre-v0.0.3 had no `curator_defaults` block; the consumer-side `.get(..., DEFAULT)` requirement is documented in `CLAUDE.md` §"Data model"):

| Field | Default |
|---|---|
| `max_candidates_per_sq` | 12 |
| `score_threshold` | 0.5 |
| `fetch_cache_max_age_days` | 30 (forwarded to each curator's Phase-4 fetch as `MAX_AGE_DAYS`) |

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
        MARKET_CONFIG_PATH=<project_path>/.metadata/market-config.json,
        MAX_CANDIDATES=<max_candidates_per_sq>,
        SCORE_THRESHOLD=<score_threshold>,
        KNOWLEDGE_ROOT=<knowledge_root>,
        MAX_AGE_DAYS=<fetch_cache_max_age_days>)
   ```

   `source-curator` lives at `${CLAUDE_PLUGIN_ROOT}/agents/source-curator.md` — agents are dispatched via `Task`, not `Skill` (which is for sibling skills). `KNOWLEDGE_ROOT` + `MAX_AGE_DAYS` drive the curator's Phase-4 fetch through `fetch-cache.py`. `MARKET_CONFIG_PATH` points at the single market config resolved in Step 0 — every curator in this run reads the **same** authority list (#304); `MARKET` stays as the informational region label for query localization.

3. Default cadence: dispatch sub-questions in parallel **when 3 or fewer**; otherwise sequential. Parallelism helps wall-clock but each curator now does its own WebSearch **and** WebFetch — three concurrent curators is the rate-limit-friendly ceiling. Folding the fetch into this parallel round is exactly the Option-B win (#292): the fetch wall-clock collapses to the slowest curator wave instead of a strictly-sequential Phase-3 batch loop.

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
- Fetched: `<fetched>` (`<cache_hits>` from cache) / Unavailable: `<unavailable>` (`<reason_top_3>`) — summed across curator returns
- Cost: `$X.XX` (sum of `cost_estimate.estimated_usd` across curator return summaries)
- Failed sub-questions (if any): `sq-NN, sq-MM` — re-run with `--sub-question-ids sq-NN,sq-MM`
- Next: run `knowledge-fetch --knowledge-slug <slug> --project-path <project_path>` to build the fetch manifest (a near no-op — bodies are already cached; add `--cobrowse` only if you want to recover WebFetch misses via your browser)

## Edge cases

- **Re-curate of an existing project.** `candidates.json` already exists. `candidate-store.py init` is idempotent (no overwrite). Curators dispatched again will re-emit batches; the merge step dedupes by URL, unions sub-question refs, keeps the higher score, and prefers the side whose `fetch.status == "ok"` so a good body survives the dedup. Re-fetches short-circuit on the fetch-cache (Phase-4 Step 1), so a re-curate is cheap.
- **Same-wave cross-SQ duplicate (C1 note).** Because the fetch now lives inside the per-sub-question curators (which run before the merge), two curators in the same concurrency wave can both miss the cache on a URL they both discovered and each WebFetch it. The fetch-cache is content-addressed by URL, so both writes collapse to **one** entry (last-write-wins) — C1 still holds when measured as `fetch-cache.py stat` entries == distinct normalized URLs. This is an accepted, bounded cost of Option B (#292).
- **Curator emits zero candidates.** Either the topic is too obscure for web sources or the score threshold is too high. Surface as a warning; the operator can re-run with `--sub-question-ids <id>` after adjusting `binding.curator_defaults.score_threshold` (manual edit, no skill yet).
- **Plan has a sub-question id the user did not pass.** Skip — only dispatch the explicitly requested subset. The skipped sq-ids will not appear in `candidates.json`'s `sub_question_refs` until re-run.

## Out of scope

- Does NOT cobrowse — browser-assisted recovery of WebFetch misses is Phase 3 (`knowledge-fetch --cobrowse`, opt-in). The curators have no claude-in-chrome MCP tools.
- Does NOT touch the wiki — wiki ingest is Phase 4 (`knowledge-ingest`).
- Does NOT modify `plan.json` or `binding.json`.
- Does NOT support tuning of scoring weights via CLI (forked composite weights are local to `agents/source-curator.md`; edit there).

## Output

- `<project_path>/.metadata/market-config.json` — the merged market config resolved once in Step 0 (verbatim `get-market-config.py` envelope), read by every `source-curator` so the run uses one authority list (#304). Not written in `--dry-run`.
- `<project_path>/.metadata/candidates.json` (schema 0.1.0; merged + tier-stamped + priority-assigned; each candidate carries an optional `fetch` sub-object from the curator's Phase-4 fetch)
- `<knowledge_root>/.cogni-knowledge/fetch-cache/<sha256>.json` for each fetched URL (shared cache; written by the curators' Phase-4 fetch)
- `<project_path>/.metadata/.candidates.batch.<sq-id>.json` for each dispatched sub-question (intermediate; safe to clean up but kept for debugging)

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 2 contract
- `${CLAUDE_PLUGIN_ROOT}/agents/source-curator.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
