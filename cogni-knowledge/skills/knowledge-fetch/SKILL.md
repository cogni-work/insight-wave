---
name: knowledge-fetch
description: "Phase 3 of the inverted pipeline. Builds fetch-manifest.json from the fetch results the curators already produced in Phase 2 (bodies are already fetched during curate). Cobrowse recovery of WebFetch misses is OPT-IN (--cobrowse): the skill walks the user through enabling the Claude-in-Chrome extension, then dispatches source-fetcher (cobrowse-only) sequentially. Use this skill whenever the user says 'fetch candidates for project X', 'build the fetch manifest', 'phase 3 of the knowledge pipeline', 'recover the failed sources', 'knowledge fetch'. After fetch, run knowledge-ingest to deposit per-URL wiki pages."
allowed-tools: Read, Write, Bash, Glob, Skill, Task, AskUserQuestion
---

# Knowledge Fetch

Phase 3 of the inverted pipeline. The WebFetch body-pull happens inside the Phase-2 curators, so this skill no longer fetches by default — it reads each candidate's `fetch` sub-object from `<project>/.metadata/candidates.json` and assembles the canonical `<project>/.metadata/fetch-manifest.json` directly. Its remaining active job is **opt-in cobrowse reconcile**: when the user passes `--cobrowse` (or accepts the interactive prompt), it walks them through enabling the Claude-in-Chrome browser extension and dispatches `source-fetcher` (cobrowse-only) **sequentially** over the WebFetch misses, merging any rescues back into the manifest.

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
| `--max-age-days` | No | Cache freshness window in days. Default: from `binding.curator_defaults.fetch_cache_max_age_days` (30). Forwarded to the cobrowse `source-fetcher`. |
| `--cobrowse` | No | Opt in to browser-assisted recovery of WebFetch misses. Default OFF (autonomous runs stay browser-free). |
| `--no-cobrowse` | No | Force cobrowse off even in an interactive session (suppresses the prompt). |
| `--batch-size` | No | Vestigial — the default WebFetch path no longer dispatches per batch (the curators already fetched). Cobrowse recovery is per-URL sequential through the single shared browser tab. Kept for backward-compat; ignored. |
| `--tier` | No | Restrict the cobrowse-retry set to a single tier (`primary`, `secondary`, `supporting`). Default: all tiers. No longer bounds WebFetch cost — that is the curator's `max_candidates_per_sq` (Phase 2). |
| `--dry-run` | No | Print the manifest plan (fetched / unavailable counts from the candidates' `fetch` sub-objects, cobrowse-eligible miss count) without dispatching cobrowse. |

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

### 1. Build the fetch manifest from the curators' results

The bodies were already fetched in Phase 2 — each candidate carries a `fetch` sub-object. Build `<project_path>/.metadata/fetch-manifest.json` directly from `candidates.json`; do **not** dispatch `source-fetcher` for the WebFetch results.

1. For each candidate with `fetch.status == "ok"` → a `fetched[]` entry: `{url, cache_key, content_hash, fetch_method, fetched_at, from_cache}` (carry `pdf_pages_read` / `pdf_truncated` if present).
2. For each candidate with `fetch.status == "unavailable"` (or no `fetch` at all — treat a missing sub-object as unavailable with `reason: "unfetched"`) → an `unavailable[]` entry: `{url, reason, attempted_at, fallback_attempted, from_cache}`. `unfetched` is a manifest-only sentinel for a candidate the curator never fetched (a legacy/partial curate) — it is **not** written to the fetch-cache via `fetch-cache.py store`, so it is exempt from the closed `VALID_REASONS` vocabulary; re-run `knowledge-curate` to populate bodies. Such candidates are not cobrowse-eligible (no `fetch.cobrowse_eligible`), so they are never offered for cobrowse recovery.
3. Collect the **cobrowse-eligible misses**: candidates with `fetch.status == "unavailable"` and `fetch.cobrowse_eligible == true`. Apply the `--tier` filter to this set if set.
4. Write the manifest atomically (`tempfile.mkstemp + os.replace`; inline `python3 -c` is fine — same pattern `fetch-cache.py` / `knowledge-binding.py` use). If a manifest already exists, merge rather than overwrite (dedup each array by URL, keep the newer `attempted_at`).

If `--dry-run`: print fetched / unavailable counts and the cobrowse-eligible miss count, and stop.

### 2. Cobrowse opt-in gate (default OFF)

Cobrowse is **never** auto-attempted — autonomous runs (`knowledge-refresh --mode push`) must stay deterministic and browser-free.

- No cobrowse-eligible misses → nothing to recover; go to Step 4 (regardless of flags).
- `--no-cobrowse` → skip cobrowse entirely; go to Step 4.
- `--cobrowse` → opt in; go to Step 3.
- Neither flag, **and** there are cobrowse-eligible misses, **and** the session is interactive → ask once via `AskUserQuestion`: "N source(s) failed WebFetch. Recover them via cobrowse? This opens your browser." (Yes → Step 3; No → Step 4.) Optionally persist the answer as `binding.curator_defaults.cobrowse_enabled` so future runs honour it without re-prompting (a persisted `true`/`false` is treated exactly like `--cobrowse`/`--no-cobrowse`).
- **Otherwise** (neither flag, misses exist, but the session is non-interactive — the autonomous path: `knowledge-refresh --mode push`) → **default OFF**: do NOT call `AskUserQuestion` (there is no one to answer), go to Step 4. The misses stay unavailable and the summary prints the `--cobrowse` hint. This is the catch-all that keeps autonomous runs browser-free and non-blocking.

### 3. Cobrowse setup + recovery (when opted in)

**Setup (mirror cogni-claims `skills/claims/SKILL.md` §"Pre-requisite: claude-in-chrome").** Probe `mcp__claude-in-chrome__tabs_context_mcp`.

- Succeeds → the extension is active; proceed to dispatch.
- Errors → tell the user (reuse cogni-claims' wording as the single source of truth): "Interactive cobrowsing requires the Claude-in-Chrome extension (your real Chrome browser). Please ensure it is active, then tell me to continue." Wait, then re-probe once. If it still errors → record each cobrowse-eligible miss as `cobrowse_unavailable` in the manifest (no agent dispatch) and go to Step 4.

`claude-in-chrome` is the **browser extension**, not a git/native MCP server — it is not in `cogni-workspace/references/mcp-git-registry.json` and does not route through `cogni-workspace:install-mcp`. Do not offer `install-mcp` here.

**Recovery.** Dispatch `source-fetcher` (cobrowse-only) **sequentially** over the cobrowse-eligible miss URLs (single shared browser tab — no parallelism). Batch them into one or a few dispatches as convenient:

```
Task(source-fetcher,
     CANDIDATES_PATH=<project_path>/.metadata/candidates.json,
     KNOWLEDGE_ROOT=<knowledge_root>,
     BATCH_URLS=<comma-separated cobrowse-eligible miss URLs>,
     MAX_AGE_DAYS=<max_age_days>,
     BATCH_OUTPUT_PATH=<project_path>/.metadata/.fetch.cobrowse.<NNN>.json)
```

After each returns, merge its batch JSON into `fetch-manifest.json`: a cobrowse `fetched[]` entry **upgrades** the matching `unavailable[]` entry (remove it from `unavailable[]`, add to `fetched[]`); a cobrowse `unavailable[]` entry overwrites the prior reason. On a `source-fetcher` failure (no batch file, `ok: false`), leave the misses as-is and continue.

### 4. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Fetched: `<count>` (`<cache_hits>` from cache) — from the Phase-2 curators
- Unavailable: `<count>` (`<reason_top_3>`)
- Cobrowse: `<recovered>` recovered of `<eligible>` eligible (or "skipped — run with `--cobrowse` to recover N misses" when off-path)
- Cost: `$X.XX` (sum of `cost_estimate.estimated_usd` across any cobrowse `source-fetcher` returns)
- Cache stats:
  ```
  python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py stat \
      --knowledge-root <knowledge_root>
  ```
  Print `entries`, `total_bytes`. (C1 check: `entries` == distinct normalized candidate URLs.)
- Next: run `knowledge-ingest --knowledge-slug <slug> --project-path <project_path>` (Phase 4) to deposit per-URL wiki pages.

If `unavailable_count / total_candidates > 0.3`, emit a non-blocking warning: "high unavailable rate (X%) — consider `--cobrowse` to recover misses, or evicting stale negative-cache entries via fetch-cache.py evict".

## Edge cases

- **Empty candidates list.** Nothing to manifest. Skip to summary with a note. Often means `knowledge-curate` failed silently — direct the user to re-run curate.
- **Candidates with no `fetch` sub-object.** A legacy or partial curate (pre-Option-B) left candidates unfetched. Treat them as `unavailable` with `reason: "unfetched"`; suggest re-running `knowledge-curate` to populate bodies.
- **Cache populated from a prior project.** The curators' Phase-1 cache lookups short-circuited, so those candidates carry `fetch.from_cache: true`. Cache is shared per-knowledge-base; this is the cross-project compounding win.
- **Re-fetch after eviction.** `fetch-cache.py evict --older-than-days N` removes stale entries. Re-running `knowledge-curate` re-fetches everything missing from cache; `knowledge-fetch` only rebuilds the manifest + offers cobrowse.
- **Cobrowse extension not enabled.** When the user opts in but the probe fails after the re-prompt, the misses record `cobrowse_unavailable` (operator-actionable: enable the extension and re-run with `--cobrowse`). Off-path (default), misses keep their `webfetch_*` reason and the summary prints the `--cobrowse` hint.

## Out of scope

- Does NOT WebFetch — the body-pull moved to Phase 2's `source-curator`. This skill only assembles the manifest and offers opt-in cobrowse recovery.
- Does NOT extract claims from fetched bodies — that is Phase 4 (`source-ingester`).
- Does NOT touch the wiki — Phase 4 (`knowledge-ingest`).
- Does NOT evict cache entries — that is `fetch-cache.py evict` (manual or via a future `knowledge-refresh --vacuum`).

## Output

- `<project_path>/.metadata/fetch-manifest.json` (schema 0.1.0; built from the curators' `fetch` sub-objects + any cobrowse rescues)
- `<project_path>/.metadata/.fetch.cobrowse.<NNN>.json` for each cobrowse dispatch (intermediate; only when `--cobrowse` opted in; kept for debugging)
- `<knowledge_root>/.cogni-knowledge/fetch-cache/<sha256>.json` — shared cache (written by the Phase-2 curators; cobrowse rescues overwrite negative entries here)

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 3 contract
- `${CLAUDE_PLUGIN_ROOT}/references/fetch-cache-design.md` — cache mechanics
- `${CLAUDE_PLUGIN_ROOT}/agents/source-fetcher.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py --help`
