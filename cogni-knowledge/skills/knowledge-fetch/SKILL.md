---
name: knowledge-fetch
description: "Phase 3 of the v0.1.0 inverted pipeline. Reads candidates.json, dispatches source-fetcher agents in batches to WebFetch each URL (with cobrowse fallback) and store bodies through fetch-cache.py. Merges per-batch results into fetch-manifest.json. Cache hits short-circuit; unavailable URLs are negatively cached. Use this skill whenever the user says 'fetch candidates for project X', 'materialize sources for the eu-ai-act plan', 'phase 3 of the knowledge pipeline', 'run the fetchers', 'knowledge fetch'. After fetch, the next slice (M5+M6) will run knowledge-ingest to deposit per-URL wiki pages."
allowed-tools: Read, Write, Bash, Glob, Skill
---

# Knowledge Fetch

Phase 3 of the v0.1.0 inverted pipeline. Reads `<project>/.metadata/candidates.json`, fans out `source-fetcher` dispatches over batches of URLs, and merges per-batch results into the canonical `<project>/.metadata/fetch-manifest.json`. Successful fetches land in the shared `<knowledge-root>/.cogni-knowledge/fetch-cache/`; unavailable URLs are negatively cached so a re-run within the freshness window does not re-attempt.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 3 — `knowledge-fetch`" and `references/fetch-cache-design.md` once to anchor on the contract.

## When to run

- `candidates.json` exists for the project (Phase 2 has run) AND either `fetch-manifest.json` does not yet exist OR the user explicitly wants to re-fetch (e.g., after evicting stale cache entries)
- User explicitly invokes `/cogni-knowledge:knowledge-fetch`

## Never run when

- No `candidates.json` exists at `<project_path>/.metadata/` — offer `knowledge-curate` first.
- No `binding.json` exists at the resolved knowledge root.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--max-age-days` | No | Cache freshness window in days. Default: from `binding.curator_defaults.fetch_cache_max_age_days` (30). |
| `--batch-size` | No | Number of URLs each `source-fetcher` dispatch handles. Default 8. Advisory; the dispatcher controls real concurrency. |
| `--tier` | No | Restrict fetch to a single tier (`primary`, `secondary`, `supporting`). Default: all tiers. Useful for spending the WebFetch budget on the most authoritative URLs first. |
| `--dry-run` | No | Print the dispatch plan (batch count, total URLs, cache-hit projection) without running fetchers. |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break):

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

Abort with the standard missing-plugin message on `no`.

**Binding + candidates.** Resolve `knowledge_root`. Read the binding (`knowledge-binding.py read`) and parse `curator_defaults.fetch_cache_max_age_days` (default 30 if absent — legacy bindings).

Read `<project_path>/.metadata/candidates.json` via:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py read \
    --project-path <project_path>
```

Abort if `success: false` — offer `knowledge-curate` first.

### 1. Build batch plan

1. Apply `--tier` filter (if set) to the candidates list.
2. Sort by `fetch_priority` ascending (primary tier first, highest score within tier first — see `candidate-store.py _recompute_priorities`).
3. Split into batches of size `--batch-size` (default 8). Carry the URL list and the candidate metadata (publisher) per batch.

If `--dry-run`: print batch count, total URLs, estimated WebFetch calls (assuming worst case — no cache hits), and stop.

### 2. Initialize fetch-manifest.json

Create `<project_path>/.metadata/fetch-manifest.json` if absent, with the empty payload:

```json
{
  "schema_version": "0.1.0",
  "fetched": [],
  "unavailable": []
}
```

If it exists, leave it — the orchestrator merges into the existing arrays so a re-fetch builds on prior results (cache hits will be marked `from_cache: true`).

### 3. Dispatch source-fetcher per batch

For each batch:

1. Define the batch output path: `<project_path>/.metadata/.fetch.batch.<NNN>.json` (e.g., `.fetch.batch.001.json`).

2. Dispatch:
   ```
   Skill("cogni-knowledge:source-fetcher",
         args="CANDIDATES_PATH=<project_path>/.metadata/candidates.json \
               KNOWLEDGE_ROOT=<knowledge_root> \
               BATCH_URLS=<comma-separated URLs from the batch> \
               MAX_AGE_DAYS=<max_age_days> \
               BATCH_OUTPUT_PATH=<batch_path>")
   ```

3. Default cadence: dispatch batches **sequentially** at v0.0.17 (WebFetch rate-limit awareness, and `fetch-manifest.json` writes happen between batches). Future tuning may parallelize once the rate-limit behaviour is characterised in the alpha re-run (M12).

4. After each fetcher returns, merge its batch JSON into `fetch-manifest.json` in the orchestrator:
   - Read the batch file's `fetched[]` and `unavailable[]`.
   - Append to the corresponding arrays in `fetch-manifest.json`.
   - Dedup within each array by URL (in case a re-run hits a URL the prior run also recorded — keep the newer `attempted_at` entry).
   - Atomic write via `tempfile.mkstemp + os.replace` (mirror the pattern `fetch-cache.py` and `knowledge-binding.py` use). Inline `python3 -c` is fine — this is one short atomic-write helper, no need for a dedicated script yet.

5. On fetcher failure (no batch file written, or summary `ok: false`), record the batch index in `failed_batches[]` and continue. Re-runnable via `--tier` + a manual `candidates.json` slice.

### 4. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Batches: `<count>` dispatched (failed: `<failed_count>`)
- Fetched: `<count>` (`<cache_hits>` from cache, `<fresh_fetches>` new)
- Unavailable: `<count>` (`<reason_top_3>`)
- Cost: `$X.XX` (sum of `cost_estimate.estimated_usd` across fetcher return summaries)
- Cache stats:
  ```
  python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py stat \
      --knowledge-root <knowledge_root>
  ```
  Print `entries`, `total_bytes`.
- Next: M5+M6 will land `knowledge-ingest`. For v0.0.17, end here — `fetch-manifest.json` + the populated cache are this slice's deliverable.

If `unavailable_count / total_candidates > 0.3`, emit a non-blocking warning: "high unavailable rate (X%) — consider checking network/cobrowse availability or evicting stale negative-cache entries via fetch-cache.py evict".

## Edge cases

- **Empty candidates list.** Nothing to fetch. Skip to summary with a note. Often means `knowledge-curate` failed silently — direct the user to re-run curate.
- **Cache populated from a prior project.** Cache hits short-circuit. Cache is shared per-knowledge-base; this is the cross-project compounding win.
- **Re-fetch after eviction.** `fetch-cache.py evict --older-than-days N` removes stale entries. A subsequent `knowledge-fetch` will re-fetch everything that's missing from cache.
- **Cobrowse unavailable.** `source-fetcher` skips Step 3 silently. The unavailable rate climbs; the orchestrator's warning surfaces it.

## Out of scope

- Does NOT extract claims from fetched bodies — that is Phase 4 (`source-ingester`, M5).
- Does NOT touch the wiki — Phase 4 (`knowledge-ingest`, M6).
- Does NOT evict cache entries — that is `fetch-cache.py evict` (manual or via a future `knowledge-refresh --vacuum`).

## Output

- `<project_path>/.metadata/fetch-manifest.json` (schema 0.1.0)
- `<project_path>/.metadata/.fetch.batch.<NNN>.json` for each dispatched batch (intermediate; kept for debugging)
- `<knowledge_root>/.cogni-knowledge/fetch-cache/<sha256>.json` for each fetched URL (shared cache; lifecycle per `fetch-cache-design.md`)

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 3 contract
- `${CLAUDE_PLUGIN_ROOT}/references/fetch-cache-design.md` — cache mechanics
- `${CLAUDE_PLUGIN_ROOT}/agents/source-fetcher.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py --help`
