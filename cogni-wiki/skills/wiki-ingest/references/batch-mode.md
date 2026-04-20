# Batch mode: one dispatch, N sources

`wiki-ingest` normally runs the nine-step workflow against a single `--source`. On bulk rebuilds (e.g., Phase 2 of the pilot rebuild, ~164 skill+agent pages), re-dispatching the skill per source reloads `SKILL.md` + `references/karpathy-pattern.md` + `references/page-frontmatter.md` for every page — the cost is not in the per-page work but in the repeated instruction load.

Batch mode eliminates that redundancy. Pass `--batch-file <path>` to a JSON list of per-source entries. The skill loads its instructions and references once, then iterates Steps 1–8 per entry. Step 9 aggregates the results into a single report.

## When to use batch mode

- Bulk rebuilds of script-generated pages (e.g., every skill page, every agent page, every plugin page).
- Seeding a new wiki from a folder of raw sources in one go.
- Any operation where re-dispatching `wiki-ingest` per source would burn tokens on repeated skill loads.

Do **not** use batch mode when:

- You have one source to ingest. The single-source path is simpler and its Step 9 report is richer per page.
- The sources require different user-visible acknowledgments between them (each Step 3 takeaway synthesis still fires per source in batch mode, but a user looking for a decision point per source should run single-source ingests).

## Input schema

`--batch-file` accepts a path to a UTF-8 JSON file. Top-level shape:

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

If any per-source step (1–8) fails — script non-zero exit, malformed JSON, missing source file, write error — the batch halts immediately and Step 9 reports:

1. How many sources completed successfully (slugs, modes).
2. Which source failed and the error.
3. Which sources were skipped (never attempted).

The wiki is never left half-written because every per-source step already writes atomically (`wiki/pages/{slug}.md` is one write; `wiki_index_update.py` uses `tempfile + os.replace`; `backlink_audit.py --apply-plan` writes each target atomically; `wiki/log.md` append is one append; `.cogni-wiki/config.json` update is one write). A mid-batch crash leaves the wiki consistent for every source that had completed before the failure.

**To resume** after a failure: re-invoke with a new `--batch-file` containing only the failed source plus the ones that were skipped. The completed sources are already in the wiki and will naturally re-route through the `mode: re-ingest` branch if you re-submit them (harmless — they update in place).

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

## Worked example: 3-source batch

Say the user has seeded `raw/` with three new papers and wants them ingested in one shot. They write `batch.json`:

```json
{
  "sources": [
    { "source": "raw/bai-et-al-2022.pdf", "title": "Constitutional AI", "type": "summary", "tags": ["llms", "safety"] },
    { "source": "raw/bai-et-al-2024.pdf", "title": "Many-Shot Jailbreaking", "type": "summary", "tags": ["safety", "long-context"] },
    { "source": "raw/wei-et-al-2022.pdf", "title": "Chain-of-Thought Prompting", "type": "concept", "tags": ["reasoning"] }
  ]
}
```

They invoke `wiki-ingest --batch-file batch.json`. Execution:

1. **Step 0** — parse `batch.json`, validate the schema, confirm all three `source` paths exist. Load the skill instructions and references once.
2. **Per-source loop** — Steps 1–8 run per entry. The first source detects `constitutional-ai` already exists at the target slug and enters `mode: re-ingest` (emitting the verbatim re-ingest warning and leaving `entries_count` untouched for that entry). The other two are fresh.
3. **Step 9** — aggregate. Report 3/3 sources, the per-entry mode and backlink count, and the `entries_count` delta.

The skill+references loaded once (not three times); each page still went through Step 3's takeaway synthesis, Step 5's atomic index update, and Step 6's backlink audit — identical per-page behaviour to single-source mode.

## Related

- `./ingest-workflow.md` — the single-source worked example this mode layers above.
- `./page-frontmatter.md` — YAML schema; unchanged by batch mode.
- `../scripts/wiki_index_update.py` and `../scripts/backlink_audit.py` — already atomic and idempotent, so calling them in a loop is safe.
