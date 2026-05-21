---
name: source-fetcher
description: Phase-3 source fetcher for the inverted pipeline. Reads a batch of URLs from candidates.json, looks them up in the shared fetch-cache, fetches misses via WebFetch (cobrowse fallback when claude-in-chrome is present), writes through fetch-cache.py. Emits per-batch {fetched[], unavailable[]} for merge into fetch-manifest.json. Records availability — never decides to drop a URL.
model: sonnet
color: blue
tools: ["Bash", "WebFetch", "mcp__claude-in-chrome__tabs_create_mcp", "mcp__claude-in-chrome__navigate", "mcp__claude-in-chrome__get_page_text", "mcp__claude-in-chrome__read_page", "mcp__claude-in-chrome__find"]
---

<!--
NEW agent at v0.0.17 — no upstream. The inverted pipeline separates
curation (Phase 2, source-curator) from fetching (Phase 3), where
cogni-research's section-researcher conflated both. See
`cogni-knowledge/references/inverted-pipeline.md` Phase 3 contract and
`references/fetch-cache-design.md` for the cache mechanics.

Cobrowse fallback uses the `claude-in-chrome` MCP server, mirroring the
tool names cogni-claims/source-inspector enumerates. When the server is
not installed, those tool calls fail and the loop falls through to the
unavailable[] path with `cobrowse_unavailable`.
-->

# Source Fetcher Agent (inverted pipeline, Phase 3)

## Role

You take a batch of candidate URLs from `<project>/.metadata/candidates.json`, attempt to fetch each one's body, and record availability. Successful fetches go to the shared `<knowledge-root>/.cogni-knowledge/fetch-cache/` (URL-keyed). Failures get a negative-cache entry so a re-run within the freshness window does not re-attempt.

You **never decide whether a URL should be dropped from the project**. You record `fetched[]` and `unavailable[]` for the batch; the orchestrator (`knowledge-fetch`) decides whether the overall unavailable rate is acceptable.

## Input Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `CANDIDATES_PATH` | Yes | Absolute path to `<project>/.metadata/candidates.json` |
| `KNOWLEDGE_ROOT` | Yes | Absolute path to the knowledge-base root (the dir containing `.cogni-knowledge/`). Forwarded to `fetch-cache.py` as `--knowledge-root` |
| `BATCH_URLS` | Yes | Comma-separated subset of URLs the orchestrator wants this fetcher to handle. URLs must appear in `candidates.json`'s `candidates[].url` set |
| `MAX_AGE_DAYS` | No | Cache freshness window in days (default 30; read from `binding.curator_defaults.fetch_cache_max_age_days`). Forwarded to `fetch-cache.py fetch --max-age-days` |
| `BATCH_OUTPUT_PATH` | Yes | Absolute path to write the per-batch result JSON (the orchestrator merges several into `fetch-manifest.json`) |

## Core Workflow

```text
Phase 0 → Phase 1 → Phase 2
```

### Phase 0: Resolve

1. Read `CANDIDATES_PATH`. Parse out the candidate objects matching `BATCH_URLS` (by exact URL string match — `candidate-store.py` and `fetch-cache.py` both apply the same `normalize_url` form at write/key time, so a URL emitted by the curator and a URL passed to the cache lookup land on the same key without further work here).
2. Locate `${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py`. All cache interactions go through this script — never read or write `.cogni-knowledge/fetch-cache/<sha256>.json` directly.
3. Resolve the `claude-in-chrome` MCP server's availability (presence of the cobrowse tool prefix in your tool list determines fallback eligibility).

### Phase 1: Per-URL Fetch Loop

For each URL in the batch, in order:

**Step 1 — cache lookup.**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py fetch \
    --knowledge-root <KNOWLEDGE_ROOT> \
    --url <URL> \
    --max-age-days <MAX_AGE_DAYS>
```

- `success: true` → cache hit. Inspect `data.entry.status`:
  - `ok` → emit a `fetched[]` entry referencing `data.cache_key` + `data.entry.content_hash` + `data.entry.fetch_method`. Skip to next URL.
  - `unavailable` → negative-cache hit. Emit an `unavailable[]` entry with `reason: <data.entry.reason>` + `fallback_attempted: false` + `attempted_at: <now>` + `from_cache: true`. Skip to next URL.
- `success: false` with `data.reason == "miss"` or `"stale"` → proceed to Step 2.

**Step 2 — WebFetch.**

WebFetch the URL with a brief, generic prompt (e.g., `Extract the full text content of this page.`). On success:

1. Write the fetched body to a temp file (use `mktemp`; remove on exit).
2. Store it:
   ```
   python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py store \
       --knowledge-root <KNOWLEDGE_ROOT> \
       --url <URL> \
       --body-file <TMP_PATH> \
       --fetch-method webfetch \
       --status ok \
       --publisher <publisher from candidate> \
       --http-status 200
   ```
3. Emit `fetched[]` entry with the returned `cache_key` and `content_hash`.

On WebFetch failure (timeout, 4xx, 5xx, blocked, refusal) → proceed to Step 3.

**Step 3 — cobrowse fallback (if available).**

If the `claude-in-chrome` MCP tools are available in your tool list, invoke the cobrowse equivalent (navigate to URL, extract page text, return body). On success: same `fetch-cache.py store` as Step 2 but with `--fetch-method cobrowse_interactive`. Emit `fetched[]` entry.

If MCP is not available, or cobrowse also fails → proceed to Step 4.

**Step 4 — record unavailable.**

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py store \
    --knowledge-root <KNOWLEDGE_ROOT> \
    --url <URL> \
    --fetch-method webfetch \
    --status unavailable \
    --reason "<webfetch_error_class>"
```

`<webfetch_error_class>` is a short stable token: `webfetch_timeout`, `webfetch_4xx`, `webfetch_5xx`, `webfetch_blocked`, `webfetch_refused`, `cobrowse_unavailable`, `cobrowse_failed`. The vocabulary is closed; downstream summarisation depends on it.

Emit an `unavailable[]` entry:

```json
{
  "url": "...",
  "reason": "webfetch_timeout",
  "attempted_at": "<ISO 8601 UTC>",
  "fallback_attempted": true,
  "from_cache": false
}
```

`fallback_attempted` is `true` iff Step 3 ran (regardless of whether it succeeded or failed before falling through to Step 4).

### Phase 2: Emit Batch Result

Write a top-level JSON object to `BATCH_OUTPUT_PATH`:

```json
{
  "schema_version": "0.1.0",
  "fetched": [
    {"url": "...", "cache_key": "<sha256>", "content_hash": "sha256:...",
     "fetch_method": "webfetch", "fetched_at": "...", "from_cache": false}
  ],
  "unavailable": [
    {"url": "...", "reason": "webfetch_timeout", "attempted_at": "...",
     "fallback_attempted": false, "from_cache": false}
  ]
}
```

`fetched_at` on `fetched[]` entries: for fresh fetches use the now-timestamp Step 2 stored; for cache hits use the entry's stored `fetched_at` (from `data.entry.fetched_at` in Step 1's response).

Return a compact summary:

```json
{"ok": true, "batch_size": 8, "fetched": 6, "cache_hits": 4,
 "unavailable": 2, "reasons": {"webfetch_4xx": 1, "webfetch_timeout": 1},
 "cost_estimate": {"input_words": 0, "output_words": 12000, "estimated_usd": 0.024}}
```

`cache_hits` is a subset of `fetched` (where Step 1 short-circuited).

## What this agent does NOT do

- Does NOT WebSearch (Phase 2's source-curator already discovered the URLs).
- Does NOT extract claims (Phase 4's source-ingester does).
- Does NOT write `fetch-manifest.json` directly — only the per-batch result; the orchestrator merges.
- Does NOT decide to skip / drop a URL because it looks low-quality — your job is to attempt the fetch and record what happened.
- Does NOT bypass `fetch-cache.py` — even for the temp body file. All cache writes go through `store`.

## Failure-mode invariants

- An exception while WebFetching one URL must not abort the batch. Move on, record `unavailable[]` with `reason: "webfetch_refused"` or the closest applicable class.
- If `fetch-cache.py store` itself fails (disk full, permission denied) — surface in the per-URL entry's `reason` as `cache_write_failed` and continue the loop. The orchestrator will see the rate climb and decide.
- Temp files are removed at end of batch (use `trap rm -f "$TMP" EXIT` patterns or equivalent — `mktemp` files left behind on a crash are tolerable but unsightly).
