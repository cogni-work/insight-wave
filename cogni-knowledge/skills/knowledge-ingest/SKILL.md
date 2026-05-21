---
name: knowledge-ingest
description: "Phase 4 of the v0.1.0 inverted pipeline. Reads fetch-manifest.json, dispatches source-ingester per fetched source to write wiki/sources/<slug>.md pages with pre_extracted_claims:, merges per-source results into ingest-manifest.json, then runs cogni-wiki's backlink_audit.py + wiki_index_update.py per new slug. The wiki becomes populated before any draft runs — the F6 fix from the alpha. Use this skill whenever the user says 'ingest the fetched sources', 'deposit fetched pages into the wiki', 'phase 4 of the knowledge pipeline', 'run the ingesters', 'knowledge ingest'. After ingest, the next slice (M7) will run knowledge-compose to draft the report."
allowed-tools: Read, Write, Bash, Glob, Skill, Task
---

# Knowledge Ingest

Phase 4 of the v0.1.0 inverted pipeline. Reads `<project>/.metadata/fetch-manifest.json`, dispatches `source-ingester` per fetched source to write `wiki/sources/<slug>.md` pages, and merges per-source results into the canonical `<project>/.metadata/ingest-manifest.json`. After per-source emission, runs cogni-wiki's `backlink_audit.py` + `wiki_index_update.py` directly at script level per new slug, and appends one ingest summary line to `wiki/log.md`.

By the end of this phase the wiki is populated with one `type: source` page per `fetched[]` entry, each carrying `pre_extracted_claims:` in its frontmatter. The composer (M7) reads these pages; verification (M8) string-matches draft sentences against the pre-extracted claims with **zero network calls** — the structural win.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 4 — `knowledge-ingest`" and `references/claim-at-ingest.md` once to anchor on the contract.

## When to run

- `fetch-manifest.json` exists for the project (Phase 3 has run) AND either `ingest-manifest.json` does not yet exist OR the user explicitly wants to re-ingest.
- User explicitly invokes `/cogni-knowledge:knowledge-ingest`.

## Never run when

- No `fetch-manifest.json` exists at `<project_path>/.metadata/` — offer `knowledge-fetch` first.
- No `binding.json` exists at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--batch-size` | No | Number of fetched sources each batch dispatches. Default 8. Advisory. |
| `--dry-run` | No | Print the dispatch plan (batch count, total sources, expected new pages) without running ingesters. |

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
probe_plugin cogni-wiki wiki-ingest && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK=no`, abort with the standard missing-plugin message.

**Resolve `WIKI_INGEST_SCRIPTS`.** Same probe shape — find `cogni-wiki/skills/wiki-ingest/scripts/` so Step 5 below can call `backlink_audit.py` and `wiki_index_update.py` directly:

```
resolve_wiki_ingest_scripts() {
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-wiki/skills/wiki-ingest/scripts"
  test -d "$sib" && { echo "$sib"; return 0; }
  for d in "${CLAUDE_PLUGIN_ROOT}/../../cogni-wiki/"*/skills/wiki-ingest/scripts; do
    [ -d "$d" ] && { echo "$d"; return 0; }
  done
  return 1
}
WIKI_INGEST_SCRIPTS=$(resolve_wiki_ingest_scripts) || abort "cogni-wiki wiki-ingest scripts not found"
```

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-fetch`). Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`.

Parse `data.binding.wiki_path` as `WIKI_ROOT`. Confirm `<WIKI_ROOT>/.cogni-wiki/config.json` exists; abort otherwise. Confirm `<WIKI_ROOT>/wiki/` exists and is writeable.

**Fetch manifest + candidates.** Read `<project_path>/.metadata/fetch-manifest.json`. Abort with "run knowledge-fetch first" if absent or `fetched[]` is empty.

Read `<project_path>/.metadata/candidates.json` via `candidate-store.py read --project-path <project_path>` so each fetched URL's `sub_question_refs[]`, `title`, and `publisher` are available to pass into the ingester.

### 1. Build batch plan

1. Filter `fetched[]` to entries with `cache_key` populated and a positive cache hit confirmed (skip entries whose cache file has gone missing — surface in the summary).
2. Derive a slug per entry from the candidate title (lower-kebab, dash-collapsed, 80-char cap; fall back to `src-<first-12-of-sha256(normalize_url(URL))>` via `python3 ${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py key --url <URL> --bare`).
3. **Dedupe by slug.** If two URLs map to the same slug (rare; URL dedup should have caught it earlier), keep the first occurrence and surface the collision as a non-blocking warning. Continue.
4. Split into batches of size `--batch-size` (default 8).

If `--dry-run`: print the batch count, total sources, expected new pages, and stop.

### 2. Initialize ingest-manifest.json

Create `<project_path>/.metadata/ingest-manifest.json` if absent:

```json
{
  "schema_version": "0.1.0",
  "ingested": [],
  "skipped": []
}
```

If it exists, leave it — the orchestrator appends to the existing arrays on a re-run.

### 3. Dispatch source-ingester per batch (sequential at v0.0.20)

For each batch:

1. Per-source batch output paths: `<project_path>/.metadata/.ingest.batch.<NNN>.<NN>.json` (batch index + per-source index inside the batch).

2. Dispatch via the `Task` tool (matches the upstream `knowledge-curate` / `knowledge-fetch` agent-dispatch convention):
   ```
   Task(source-ingester,
        KNOWLEDGE_ROOT=<knowledge_root>,
        WIKI_ROOT=<wiki_root>,
        URL=<url>,
        SLUG_HINT=<derived slug>,
        SUB_QUESTION_REFS=<comma-separated sq-NN list from candidates.json>,
        PUBLISHER=<from candidates.json>,
        TITLE_HINT=<from candidates.json>,
        BATCH_OUTPUT_PATH=<batch_path>)
   ```

   `source-ingester` lives at `${CLAUDE_PLUGIN_ROOT}/agents/source-ingester.md` — dispatched via `Task`, not `Skill`.

3. **Sequential cadence at v0.0.20.** Each ingester writes a unique `wiki/sources/<slug>.md` page (unique-by-slug-construction; no contention there), but cogni-wiki's `wiki/index.md` is shared and the cogni-wiki helpers (`wiki_index_update.py`, `backlink_audit.py --apply-plan`) are lock-wrapped at their own write sites. Parallel fan-out adds no correctness win and complicates summary aggregation. Future tuning may parallelise once the cadence is characterised.

4. After each ingester returns, read its batch JSON and merge into `ingest-manifest.json`:
   - On `ok: true`: append to `ingested[]`.
   - On `ok: false` / skipped: append to `skipped[]` with the `reason`.
   - Dedup within each array by URL.
   - Atomic write via `tempfile.mkstemp + os.replace` (inline `python3 -c`, mirroring `knowledge-fetch` Step 4). No file lock needed — sequential merge after each Task return.

5. On dispatcher failure (no batch file written, or summary `ok: false`), record the source URL in `failed_ingesters[]` and continue. Re-runnable by re-invoking the skill (the orchestrator skips entries already in `ingested[]`).

### 4. Per-new-slug cogni-wiki integration (sequential, after all ingesters return)

For each entry in `ingested[]` written this run, in deterministic slug order:

1. **Backlink audit (audit-only at v0.0.20):**
   ```
   python3 "$WIKI_INGEST_SCRIPTS/backlink_audit.py" \
       --wiki-root <WIKI_ROOT> \
       --new-page <slug> \
       --top 8 \
       --min-confidence medium
   ```
   Capture the JSON envelope. Surface the candidate count in the final summary (the operator can apply backlinks manually via `wiki-update`). **No `--apply-plan` at v0.0.20** — auto-curating which candidates to write requires an LLM pass not in this skill's scope; deferred to a follow-up slice.

2. **Index update:**
   ```
   python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
       --wiki-root <WIKI_ROOT> \
       --slug <slug> \
       --summary "<per-source summary, ≤180 chars>" \
       --category "Sources"
   ```
   `--category "Sources"` creates a top-level `## Sources` heading in `wiki/index.md` on first ingest and appends to it on subsequent ingests. Both helpers are lock-wrapped at their own write sites (`_wiki_lock` on `<WIKI_ROOT>/.cogni-wiki/.lock`), so concurrent `wiki-*` invocations from other sessions are safely serialised.

3. On any helper failure, record in `failed_index_updates[]` and continue. The page itself is already on disk; only the discoverability is incomplete.

### 5. Append wiki/log.md

Append one summary line (Bash `>>` append; `wiki/log.md` is append-only by cogni-wiki convention — see `cogni-wiki/CLAUDE.md` §"Key Conventions"):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from plan.json>
N_INGESTED=<len(ingested[]) written this run>
N_CLAIMS=<sum of claims_extracted across this-run ingested[]>
echo "## [${DATE_STAMP}] ingest | project=${TOPIC} sources=${N_INGESTED} claims=${N_CLAIMS}" >> "${WIKI_ROOT}/wiki/log.md"
```

The `ingest` prefix is already in cogni-wiki's log-format enum (see `cogni-wiki/CLAUDE.md`).

### 6. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Batches: `<count>` dispatched (failed: `<failed_count>`)
- Ingested: `<count>` new pages (`<total_claims>` total claims extracted)
- Skipped: `<count>` (reason breakdown: `cache_miss=<n>, unavailable=<n>, slug_collision=<n>`)
- Backlink audit candidates surfaced: `<n>` (apply manually via `wiki-update`)
- Cost: `$X.XX` (sum of `cost_estimate.estimated_usd` across ingester + claim-extractor)
- Next: M7 will land `knowledge-compose`. For v0.0.20, end here — `wiki/sources/*.md` populated + `ingest-manifest.json` is this slice's deliverable.

If `len(ingested) == 0` and `len(skipped) > 0`, emit a warning: "no new pages written this run — every fetched source was already in ingest-manifest.json or skipped; check the skipped breakdown".

## Edge cases

- **Re-ingest of an existing project.** `ingest-manifest.json` already exists; the orchestrator skips entries already in `ingested[]` (URL-keyed). Manual cleanup (delete page + remove from manifest) is the path to force a re-ingest of a specific URL.
- **Cache file gone missing between fetch and ingest.** Surface in `skipped[]` with `reason: cache_miss` and continue. The user can re-run `knowledge-fetch` to repopulate.
- **Slug collision across batches.** Step 1.3 dedupes before dispatch; defence-in-depth check inside `source-ingester` refuses to overwrite an existing page. Surfaces as `reason: slug_collision` in `skipped[]`.
- **First ingest into an empty wiki.** `wiki/index.md` may exist with only the wiki-setup header. `wiki_index_update.py` creates the `## Sources` category on first call; subsequent calls append.
- **Wiki schema < 0.0.6 (`type: source` not yet allowlisted).** cogni-wiki v0.0.44's `_wikilib.PAGE_TYPE_DIRS` includes `"source": "sources"`; older wikis hard-fail in `wiki-health` until migrated. The skill does not auto-migrate; surface the error and direct the user to upgrade cogni-wiki.

## Out of scope

- Does NOT compose the draft — that is Phase 5 (`knowledge-compose`, M7).
- Does NOT verify claims — Phase 6 (`knowledge-verify`, M8).
- Does NOT auto-apply backlink candidates — audit-only at v0.0.20; `--apply-plan` integration is a follow-up slice.
- Does NOT modify `binding.json` — Phase 7 (`knowledge-finalize`) appends the project entry.
- Does NOT re-run fetch — that is `knowledge-fetch`.

## Output

- `<WIKI_ROOT>/wiki/sources/<slug>.md` per fetched source (one file per `ingested[]` entry).
- `<WIKI_ROOT>/wiki/index.md` updated (new `## Sources` category on first ingest; appended otherwise).
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] ingest | …` line.
- `<project_path>/.metadata/ingest-manifest.json` (schema 0.1.0).
- `<project_path>/.metadata/.ingest.batch.<NNN>.<NN>.json` per ingester dispatch (intermediate; kept for debugging).

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 4 contract
- `${CLAUDE_PLUGIN_ROOT}/references/claim-at-ingest.md` — why claims at ingest, claim shape
- `${CLAUDE_PLUGIN_ROOT}/agents/source-ingester.md` — dispatched agent
- `${CLAUDE_PLUGIN_ROOT}/agents/claim-extractor.md` — dispatched by source-ingester
- `${CLAUDE_PLUGIN_ROOT}/scripts/fetch-cache.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/candidate-store.py --help`
