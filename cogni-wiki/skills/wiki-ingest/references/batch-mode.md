# Batch mode: one dispatch, N sources

`wiki-ingest` normally runs the nine-step workflow against a single `--source`. On bulk rebuilds (e.g., Phase 2 of the pilot rebuild, ~164 skill+agent pages), re-dispatching the skill per source reloads `SKILL.md` + `references/karpathy-pattern.md` + `references/page-frontmatter.md` for every page — the cost is not in the per-page work but in the repeated instruction load.

Batch mode eliminates that redundancy. The skill loads its instructions and references once, then iterates Steps 1–8 per entry. Step 9 aggregates the results into a single report.

There are two ways to feed it:

- **`--discover`** — the skill walks the filesystem (or the wiki's own backlog) and builds the batch itself. This is the right default for almost every bulk case. See §"Discovery" below.
- **`--batch-file`** — the caller supplies a pre-written JSON list. Use this when the batch is an ad-hoc selection the discovery modes can't express cleanly. See §"Advanced: hand-crafted batch files" at the bottom.

## When to use batch mode

- Bulk rebuilds of script-generated pages (e.g., every skill page, every agent page, every plugin page).
- Seeding a new wiki from a folder of raw sources in one go.
- Refreshing stub drafts that point at updated sources.
- Any operation where re-dispatching `wiki-ingest` per source would burn tokens on repeated skill loads.

Do **not** use batch mode when:

- You have one source to ingest. The single-source path is simpler and its Step 9 report is richer per page.
- The sources require different user-visible acknowledgments between them (each Step 3 takeaway synthesis still fires per source in batch mode, but a user looking for a decision point per source should run single-source ingests).

## Execution model

Batch mode does **not** run Steps 1–8 as an inline loop in the orchestrator context. Inline looping was the v0.0.8/0.0.9 design; it did not scale past a few dozen sources because each source consumed ~15–20k tokens of orchestrator context (source read + Step 3 synthesis + backlink audit JSON + curation). Issue #82 replaced it with per-source subagent fan-out.

**How fan-out works:**

1. `wiki-ingest` validates the batch schema (whether produced by `batch_builder.py` via `--discover` or supplied by `--batch-file`). Malformed input aborts before any worker fires.
2. The skill resolves `batch_size` from `<wiki-root>/.cogni-wiki/config.json` (key `batch_size`, range 2–8; default **5**). `batch_size` caps the number of concurrently dispatched workers.
3. `sources[]` is partitioned into order-preserving chunks of `batch_size` entries. For each chunk, one `ingest-worker` subagent is dispatched per source (`Task(subagent_type: "ingest-worker", run_in_background: true, …)`). The orchestrator waits for the whole chunk to complete before dispatching the next chunk — bounded concurrency.
4. Each worker owns Steps 1–8 for exactly one source. See `../../../agents/ingest-worker.md` for the agent contract.
5. Each worker returns a single fenced ` ```json ... ``` ` block as its final message. The orchestrator extracts these blocks and aggregates them into the Step 9 report. No source body, page body, or backlink audit JSON is ever loaded into the orchestrator.

**Worker return schema:**

| Field | Type | Notes |
|-------|------|-------|
| `source` | string | Echo of the input `source_entry.source`. Lets the orchestrator match returns to batch entries. |
| `slug` | string \| null | Resolved slug, or `null` if the worker failed before Step 1. |
| `mode` | `"fresh"` \| `"re-ingest"` \| `null` | Per-entry Step 1 detection. `null` if Step 1 did not complete. |
| `backlinks_added` | integer | Count from `data.applied` in the Step 6 `--apply-plan` response. `0` if Step 6 was skipped or failed. |
| `index_action` | `"inserted"` \| `"updated"` \| `null` | From Step 5 `wiki_index_update.py` output. `null` if Step 5 did not run. |
| `errors` | array | Empty on success. On failure: `[{"step": <1-8 or null>, "message": "<verbatim>"}]`. |

**Concurrency rationale.** Default `batch_size: 5` balances wall-clock on large rebuilds (the 179-source #80 scope) against model-cost burst and subagent dispatch ceilings. Override via `.cogni-wiki/config.json`:

- `batch_size: 2` — metered usage, quiet hosts, slow networks. Gentler on WebFetch rate limits for URL-heavy batches.
- `batch_size: 5` — default. Sweet spot for ~50–200 source rebuilds on typical developer workstations.
- `batch_size: 8` — aggressive. Only if you know the Anthropic subagent dispatch limits in your environment tolerate it; no guarantee higher is faster.

**Chunk wall-clock.** A chunk completes when every worker in it finishes, so chunk wall-clock is bounded by the slowest worker. A slow URL fetch in chunk `k` does not starve workers in chunks `k+1…` — they simply wait their turn. Step 3 synthesis inside a worker is visible inside that worker's subagent transcript, not interleaved in the parent; batch mode is reduced-interactivity by construction.

**Fan-out never runs in `--discover-dry-run`.** Workers only fire after the Step 0 confirmation gate; the dry-run prints the resolved batch JSON and exits with no writes.

## Discovery

`--discover <spec>` asks the skill to enumerate the batch itself instead of the user typing it out. Three specs are supported; pick the one that matches how the user described the job.

### `--discover orphans`

Files under `<wiki-root>/raw/` that no page cites in its `sources:` frontmatter. This is the direct answer to "I dropped a bunch of files in `raw/`, ingest them all".

```
wiki-ingest --discover orphans                       # interactive: shows batch, asks to confirm
wiki-ingest --discover orphans --discover-dry-run    # prints the batch JSON and exits
```

### `--discover stubs [--older-than-days N]`

Pages whose frontmatter has `status: draft`. Use this to refresh stub pages after their source documents changed. The re-ingest branch of Step 1 handles the overwrite; `entries_count` stays correct because re-ingests don't increment it.

```
wiki-ingest --discover stubs                            # every draft
wiki-ingest --discover stubs --older-than-days 180      # only stale drafts
```

### `--discover glob:<pattern>[:<root>]`

Any files matching a filesystem glob. This is the mode for cross-plugin monorepo rebuilds — e.g., "ingest every SKILL.md in insight-wave that isn't in the wiki yet". The pattern is resolved relative to the wiki root unless an absolute path or an explicit `:<root>` suffix is given.

```
# Every SKILL.md in every sibling cogni-* plugin, skipping ones already in the wiki,
# with titles that match the existing slug convention:
wiki-ingest --discover 'glob:../cogni-*/skills/**/SKILL.md' \
            --title-template 'skill-{parent3}-{parent}' \
            --exclude-ingested
```

### Shared flags (all discovery modes)

| Flag | Purpose |
|------|---------|
| `--discover-dry-run` | Print the resolved batch as JSON and exit. Review, then re-run without `--discover-dry-run`, or pipe the output into `--batch-file` |
| `--exclude-ingested` | Drop any source whose derived slug already exists as a page. Key dedupe — makes the command idempotent: rerun it until `count == 0` to be sure nothing new slipped in |
| `--title-template T` | Format string for per-entry titles when the wiki's slug convention isn't `{filename}`. Placeholders: `{stem}`, `{parent}`, `{parent2}`, `{parent3}`, `{parts[-N]}`. Example: for the insight-wave convention `skill-{plugin}-{skill}`, pass `--title-template 'skill-{parent3}-{parent}'` |
| `--older-than-days N` | `--discover stubs` only: restrict to drafts updated more than N days ago |
| `--type`, `--tags` | Apply as defaults to every discovered entry |
| `--limit N` | Cap the resolved batch at N entries; useful for incremental runs |

### Why discovery instead of hand-crafted JSON

Hand-typing a 163-entry JSON list is neither respectful of the user's time nor safe. Silent mistakes — a dropped entry, a wrong path, a duplicate — only surface mid-ingest or not at all. The discovery modes collapse the list-building task into one deterministic command, and `--discover-dry-run` preserves the "eyeball before write" discipline for anyone who wants it. Direct `--batch-file` remains available for custom selections, but it should be the exception, not the default.

## Input schema

Whether produced by `batch_builder.py` (the script behind `--discover`) or hand-crafted by the user, the payload is the same JSON:

```json
{
  "sources": [
    {
      "source": "raw/bai-et-al-2022.pdf",
      "title": "Constitutional AI",
      "type": "summary",
      "tags": ["llms", "safety"]
    },
    {
      "source": "raw/many-shot-jailbreak.pdf",
      "tags": ["safety"]
    },
    {
      "source": "https://arxiv.org/abs/2501.12345"
    }
  ]
}
```

Per-entry fields mirror the single-source CLI parameters exactly:

| Field | Required | Behaviour |
|-------|----------|-----------|
| `source` | Yes | Path (relative to the wiki root) or URL; matches today's `--source` parameter |
| `title` | No | Override; matches `--title` |
| `type` | No | `concept \| entity \| summary \| decision \| learning \| note`; matches `--type` |
| `tags` | No | List of strings; matches `--tags` (no comma splitting needed) |

Unknown top-level keys (siblings of `sources`) and unknown per-entry fields both cause the batch to abort before Step 1 of the first entry — malformed input never half-writes the wiki.

## Per-source mode resolution

The `mode: fresh | re-ingest` resolution from Step 1 runs **per entry**, not per batch. A single batch may mix fresh and re-ingest sources freely; each one hits Step 1's slug-existence check independently, emits the verbatim re-ingest warning if applicable, and honours the mode-specific branches in Step 7 (log line) and Step 8 (entry-count handling).

Batch mode does **not** accept a batch-wide mode toggle. Trying to force every source through one mode would be the wrong primitive: the pilot rebuild case explicitly mixes fresh new pages with re-syntheses of existing stubs, and a batch-wide flag would either double-count fresh entries or silently skip re-ingests.

## Error policy: fail-fast for Phase 1

Workers fail in two shapes; the orchestrator handles them the same way but distinguishes them in the Step 9 report.

**Graceful failure (worker returned a JSON block with populated `errors[]`).** The worker reached a per-source step (1–8), hit a failure (script non-zero exit, malformed JSON from a script, missing source file, WebFetch failure, write error), stopped at that step, and returned `{… "errors": [{"step": <1-8>, "message": "<verbatim>"}]}`. The per-source scripts' atomicity guarantees mean partial work that *had* completed before the failure is consistent on disk.

**Silent crash (worker returned no JSON block).** The subagent terminated without emitting the mandatory final fenced JSON block. The orchestrator synthesizes `{source, slug: null, mode: null, backlinks_added: 0, index_action: null, errors: [{step: null, message: "worker returned no JSON payload"}]}` and treats it as a failure. Do **not** retry — surface the crash so the user can diagnose (the worker's own transcript usually shows the cause).

Either shape triggers the same fail-fast behavior at chunk boundaries: the orchestrator **does not dispatch further chunks** after a chunk returns with any failure. Sources dispatched in the failing chunk that returned cleanly still count as completed (atomic per-source scripts make this safe). Sources in not-yet-dispatched chunks are **skipped** — never attempted.

Step 9 reports:

1. How many sources completed successfully (slugs, modes).
2. Which sources failed and the errors.
3. Which sources were skipped (never attempted because an earlier chunk halted the batch).

The wiki is never left half-written because every per-source step already writes atomically (`wiki/pages/{slug}.md` is one write; `wiki_index_update.py` uses `tempfile + os.replace`; `backlink_audit.py --apply-plan` writes each target atomically; `wiki/log.md` append is one append; `.cogni-wiki/config.json` update is one write). A mid-batch crash leaves the wiki consistent for every source that had completed before the failure.

**To resume** after a failure: re-run the same `--discover` command with `--exclude-ingested` and the script will drop every source that already has a page (every completed entry from the previous run). Or, if you used `--batch-file`, re-invoke with a trimmed batch containing only the failed source plus the ones that were skipped. The completed sources are already in the wiki and will naturally re-route through the `mode: re-ingest` branch if you re-submit them (harmless — they update in place).

Continue-on-error semantics (`--on-error continue`) are a deliberate Phase 2 follow-up: useful for the 164-page pilot rebuild once the fail-fast path proves stable.

## Step 9 in batch mode

Instead of a per-source report, Step 9 emits one aggregated block:

```
Batch complete: 3/3 sources
- constitutional-ai           (re-ingest)  — 2 backlinks applied
- many-shot-jailbreaking      (fresh)      — 1 backlink applied
- chain-of-thought-prompting  (fresh)      — 0 backlinks applied

entries_count: 42 → 44 (2 fresh, 1 re-ingest unchanged)
```

On failure:

```
Batch halted at source 2/3
- constitutional-ai           (re-ingest)  — 2 backlinks applied   ✓
- many-shot-jailbreaking                                            ✗  Step 5 (wiki_index_update.py exited non-zero): invalid category
- chain-of-thought-prompting                                        · skipped

entries_count: 42 → 42 (no fresh source completed)
```

## Worked example: discovering the Phase 2 rebuild

The user is doing the Phase 2 pilot rebuild and wants every SKILL.md across the sibling plugins in the monorepo into the wiki, minus the ones already there. From the wiki root:

```
wiki-ingest --discover 'glob:../cogni-*/skills/**/SKILL.md' \
            --title-template 'skill-{parent3}-{parent}' \
            --exclude-ingested \
            --discover-dry-run > /tmp/phase2-batch.json
```

Execution:

1. `batch_builder.py` walks the matching files, renders each title per the template (so `../cogni-claims/skills/claims/SKILL.md` becomes `skill-cogni-claims-claims`), and drops any whose slug already has a page.
2. The dry-run prints the `{"sources": [...]}` JSON on stdout. The user reviews it — e.g., spots one spurious `skill-snapshot-*` entry from a workspace directory and removes it by hand.
3. The user re-runs without `--discover-dry-run` (or equivalently, `wiki-ingest --batch-file /tmp/phase2-batch.json` after the manual trim).
4. Steps 1–8 loop over every entry; Step 9 reports the per-slug mode and backlink counts.

Contrast with the old path: the user (or Claude-on-behalf-of-the-user) hand-typed 160+ JSON entries, hoping no skill was missed or duplicated. Discovery makes the list-build step deterministic and auditable.

## Advanced: hand-crafted batch files

Some batches can't be expressed as a discovery mode — e.g., three specific papers the user drops into `raw/` at the same time with different tag sets, or a curated selection across unrelated directories. For those, write the JSON by hand and pass it with `--batch-file`:

```json
{
  "sources": [
    { "source": "raw/bai-et-al-2022.pdf", "title": "Constitutional AI", "type": "summary", "tags": ["llms", "safety"] },
    { "source": "raw/bai-et-al-2024.pdf", "title": "Many-Shot Jailbreaking", "type": "summary", "tags": ["safety", "long-context"] },
    { "source": "raw/wei-et-al-2022.pdf", "title": "Chain-of-Thought Prompting", "type": "concept", "tags": ["reasoning"] }
  ]
}
```

`wiki-ingest --batch-file batch.json` runs the same pipeline the discovery modes feed into — one instruction load, N per-source loops, one aggregated Step 9 report. Same schema, same atomicity, same fail-fast rules.

## Related

- `./ingest-workflow.md` — the single-source worked example this mode layers above.
- `./page-frontmatter.md` — YAML schema; unchanged by batch mode.
- `../scripts/batch_builder.py` — the discovery helper behind `--discover`; usable standalone to produce a batch JSON for review.
- `../scripts/wiki_index_update.py` and `../scripts/backlink_audit.py` — already atomic and idempotent, so calling them in a loop is safe.
- `../../../agents/ingest-worker.md` — per-source subagent dispatched from batch mode; owns Steps 1–8 for one source entry and returns the compact JSON payload described in §"Execution model".
