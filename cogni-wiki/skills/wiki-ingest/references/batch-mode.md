# Batch mode: one dispatch, N sources, sequential

`wiki-ingest` normally runs the nine-step workflow against a single `--source`. On bulk rebuilds (a folder of newly-dropped sources, every SKILL.md across a monorepo, a completed cogni-research project), re-dispatching the skill per source reloads `SKILL.md` + `references/karpathy-pattern.md` + `references/page-frontmatter.md` for every page — the cost is not in the per-page work but in the repeated instruction load.

Batch mode eliminates that redundancy. The skill loads its instructions and references once, then **iterates Steps 1–8 per entry sequentially**. Step 9 aggregates the results into a single report. Sequential is non-negotiable: source N+1 must see the page source N just created, otherwise the wiki fragments instead of compounds (see §"Execution model" below for the history of why an earlier parallel-fan-out design was removed).

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

Batch mode runs Steps 1–8 as a **strict sequential loop in the orchestrator's own context** — one source at a time, in input order, with every page write, index update, backlink apply, log line, and config bump committed to disk before the next iteration starts.

This was not always so. The v0.0.10–v0.0.21 design used per-source subagent fan-out (`Task(subagent_type: "ingest-worker", run_in_background: true)`) with chunked concurrency (`batch_size`, default 5). Fan-out was originally introduced (issue #82) to keep the orchestrator's context small on 100+ source rebuilds. It was removed because it broke the load-bearing property of the Karpathy pattern: **a new ingest must see the pages prior ingests in the same run just created**. Source N+1's Step 3 ("which existing wiki pages does this source touch?") greps the wiki for entity matches and Step 6 (`backlink_audit.py`) proposes candidate cross-references. Both run against on-disk state. With concurrent workers, every worker in a chunk reads the wiki as it existed *before* the chunk started, so two workers can independently create pages for the same entity (slug-collision detection only catches *exact* slug matches, not near-duplicates), and a new entity page from worker A is invisible to workers B…E ingesting siblings that mention it. The wiki ends up with disconnected fragments where it should compound.

**How sequential iteration works:**

1. `wiki-ingest` validates the batch schema (whether produced by `batch_builder.py` via `--discover` or supplied by `--batch-file`). Malformed input aborts before any source is touched.
2. For each `source_entry` in `sources[]`, in input order:
   - Run Steps 1–8 of `SKILL.md` inline in this context: locate wiki + detect mode, read source, surface takeaways, write the new page, update `wiki/index.md` via `wiki_index_update.py`, run `backlink_audit.py` and apply the curated/auto plan via `--apply-plan -`, append to `wiki/log.md`, bump `entries_count` via `config_bump.py` (fresh only).
   - Wait for every script invocation to return cleanly before moving to the next source. There is no concurrent I/O within a batch.
3. After the loop completes (or halts on failure), run Step 9 once to emit the aggregated report.

**Per-source result row:** captured in the orchestrator's own state across the loop iterations. Schema mirrors the old worker return for continuity in Step 9 reporting:

| Field | Type | Notes |
|-------|------|-------|
| `source` | string | Echo of the input `source_entry.source`. Lets the Step 9 report match rows to batch entries. |
| `slug` | string \| null | Resolved slug, or `null` if Step 1 did not complete. |
| `mode` | `"fresh"` \| `"re-ingest"` \| `null` | Per-entry Step 1 detection. `null` if Step 1 did not complete. |
| `backlinks_added` | integer | Count from `data.applied` in the Step 6 `--apply-plan` response. `0` if Step 6 was skipped or failed. |
| `index_action` | `"inserted"` \| `"updated"` \| `null` | From Step 5 `wiki_index_update.py` output. `null` if Step 5 did not run. |
| `errors` | array | Empty on success. On failure: `[{"step": <1-8 or null>, "message": "<verbatim>"}]`. |

**Throughput.** Sequential iteration is materially slower than the removed fan-out for large rebuilds (a 100-source batch that took ~20 chunk-rounds of 5 workers each will now run as 100 strictly-ordered iterations). This cost is accepted: the wiki's value is the cross-source interconnection, and parallel dispatch traded that interconnection for wall-clock — the wrong direction for a knowledge engine whose entire premise is compounding. If a user's bulk rebuild is too slow, the right fix is fewer sources per batch (split by topic, run one batch per session), not concurrent ingestion.

**No `batch_size` config key.** The previous `.cogni-wiki/config.json` `batch_size` field is ignored if present (legacy wikis with the key are harmless; nothing reads it). New wikis from `wiki-setup` no longer write the key.

**Step 3 synthesis is visible.** Each iteration's Step 3 takeaways (source type, 3–7 takeaways, existing pages this source touches, proposed type/title) are printed in the orchestrator's own transcript before the page write, exactly as in single-source mode. Batch mode is autonomous-run by construction (the user said "ingest all of them"), so the synthesis is emitted and the iteration proceeds without confirmation — but the synthesis itself is never skipped, and a user reading the run can correlate each takeaway block to its slug.

**Discover-dry-run still gates writes.** No iteration starts until the user confirms the resolved batch (or skipped that confirmation by phrasing). `--discover-dry-run` prints the JSON and exits with zero writes, exactly as before.

## Backlink curation defaults

Hand-curation is the default in **all** modes (single, batch, discover). To opt into auto-mode for a batch, pass `--auto-backlinks K`:

```
wiki-ingest --discover orphans --auto-backlinks 3       # auto-apply up to 3 medium/high-confidence backlinks per source
wiki-ingest --batch-file batch.json --auto-backlinks 5  # auto-apply up to 5 per source
```

Each per-source iteration then invokes `backlink_audit.py --top K --min-confidence medium` and drafts a one-sentence backlink for each returned candidate from the target page's title + first paragraph. The "never invent backlinks" discipline is preserved by two mechanisms: (i) `--min-confidence medium` drops the keyword-noise bucket at audit time; (ii) K is bounded by the explicit cap. You are still selecting from a pre-filtered set of real textual matches, not generating links from thin air.

`--review` remains as a no-op (kept for backwards-compat with scripts that pass it explicitly to force hand-curation); since hand-curation is the default, passing it has no effect beyond intent-signalling.

### Auto-backlinks tradeoff

Auto-applied backlinks are keyword-driven (tag/term overlap filtered by the IDF-weighted `confidence` score), not reader-value-driven. A human curator catches cases where a high-score candidate is actually a poor link target (e.g., two pages sharing four generic tags but orthogonal topics). When the user opts into auto-mode for a bulk rebuild, the trade is explicit: faster per-source iteration in exchange for keyword-driven instead of reader-value-driven backlinks. The default landed back on hand-curation because the parallel-fan-out throughput pressure that originally motivated `--auto-backlinks 5` as a default is gone now that batches are sequential.

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

### `--discover research:<project-slug>[:<research-root>]`

Cogni-research projects produce one or more sub-questions, each backed by contexts, sources, and (post-`verify-report`) verified report-claims. This mode emits **one batch entry per sub-question** with a synthesised raw file that bundles the findings, verified claims, and source list — the natural unit for an Option-B (sub-question-centric) deposit pattern.

```
wiki-ingest --discover research:quantum-cryptography     # auto-locate sibling project
wiki-ingest --discover research:quantum-cryptography:/path/to/cogni-research-quantum-cryptography
```

**Project location.** Without the optional `:<research-root>` suffix, the script tries `<workspace>/cogni-research-<slug>/` (workspace = wiki root's parent), then `<wiki-root>/cogni-research-<slug>/`. Use the `:<root>` suffix to point at a non-standard layout.

**This is the one discovery mode that writes to the wiki.** Cogni-research spreads each sub-question's evidence across four entity types and each per-source iteration of `wiki-ingest` reads exactly one file. The script materialises one synthesised markdown file per sub-question at `<wiki-root>/raw/research-<project-slug>/sq-NN-<short>.md` before emitting the batch. Materialisation is deterministic (same entities → byte-identical output), idempotent across re-runs, and confined to a single subdirectory you can `git rm -rf` if you change your mind. Pair with `--discover-dry-run` to inspect the planned batch without writes (the SKILL passes `--no-materialize` to the script under the hood).

**What lands in each synthesised file:**

```markdown
# <sub-question text>

*Synthesised from cogni-research project `<slug>` (topic: <parent_topic>, sub-question NN).*

## Findings
<context bodies for this sub-question>

## Verified claims
- <statement> ([source](<url>)) — verified <date>

## Sources
- [<title>](<url>) — <publisher>
```

**Verified-claim filtering.** Only `verification_status: verified` claims are included; `pending`, `deviated`, and `source_unavailable` claims are skipped because the wiki's "every claim citable" discipline (`wiki-update` SKILL §"What it means for you") would otherwise admit unsupported assertions. Run `verify-report` before ingest to maximise yield.

**Sub-question ↔ claim join.** A verified claim is attached to a sub-question when its `source_ref` overlaps any source cited by the sub-question's contexts. This is a structural join, not a section-name match — section labels in `report-claim.section` are writer-chosen and unstable across drafts.

**Per-entry defaults.** `type: concept`, `tags: ["research", "<project-slug>"]`. Override with `--type` and `--tags` like any other discovery mode.

**`--title-template` is rejected** in research mode — titles come from the sub-question text. The slug derives from the title via the standard rule (Step 1 of each per-source iteration), capped at 40 chars in the filename.

**Empty result.** A project with zero sub-questions emits `count: 0` (graceful) rather than failing.

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
| `--research-root P` | `--discover research:` only: override auto-located project root. Equivalent to the `:<research-root>` suffix on the discover spec — pass whichever reads more naturally. |
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
| `type` | No | `concept \| entity \| summary \| decision \| interview \| meeting \| learning \| note`; matches `--type`. See `./page-frontmatter.md` §"Type → body template mapping" for which template each type dispatches to |
| `tags` | No | List of strings; matches `--tags` (no comma splitting needed) |

Unknown top-level keys (siblings of `sources`) and unknown per-entry fields both cause the batch to abort before Step 1 of the first entry — malformed input never half-writes the wiki.

## Per-source mode resolution

The `mode: fresh | re-ingest` resolution from Step 1 runs **per entry**, not per batch. A single batch may mix fresh and re-ingest sources freely; each one hits Step 1's slug-existence check independently, emits the verbatim re-ingest warning if applicable, and honours the mode-specific branches in Step 7 (log line) and Step 8 (entry-count handling).

Batch mode does **not** accept a batch-wide mode toggle. Trying to force every source through one mode would be the wrong primitive: the pilot rebuild case explicitly mixes fresh new pages with re-syntheses of existing stubs, and a batch-wide flag would either double-count fresh entries or silently skip re-ingests.

## Error policy: fail-fast

The loop halts on the first iteration that fails any of Steps 1–8. The orchestrator records the failed entry's error (`{step: <1-8>, message: "<verbatim>"}`), counts every entry processed before the failure as completed (the per-source scripts' atomicity guarantees mean their writes are consistent on disk), and lists every entry after the failure as skipped (never attempted).

Failures look like one of:

- **Script non-zero exit or malformed JSON** from `wiki_index_update.py`, `backlink_audit.py`, or `config_bump.py`.
- **Missing source file** at the path in `source_entry.source` (after the dispatch-time validation; e.g., the file existed when the batch was built but was moved before its iteration).
- **WebFetch failure** for URL sources.
- **Write error** (disk full, permission denied) on `wiki/<type>/{slug}.md` or `wiki/log.md`.

Step 9 reports:

1. How many sources completed successfully (slugs, modes).
2. Which source failed and the error.
3. Which sources were skipped (the tail of `sources[]` after the failure).

The wiki is never left half-written: every per-source step writes atomically (`wiki/<type>/{slug}.md` is one write; `wiki_index_update.py` uses `tempfile + os.replace`; `backlink_audit.py --apply-plan` writes each target atomically; `wiki/log.md` append is one append; `.cogni-wiki/config.json` update is one locked write). A mid-batch failure leaves the wiki consistent for every source that had completed before it.

**To resume** after a failure: re-run the same `--discover` command with `--exclude-ingested` and the script will drop every source that already has a page (every completed entry from the previous run). Or, if you used `--batch-file`, re-invoke with a trimmed batch containing only the failed source plus the ones that were skipped. Completed sources already in the wiki will re-route through the `mode: re-ingest` branch if re-submitted (harmless — they update in place).

Continue-on-error semantics (`--on-error continue`) remain a deferred follow-up.

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
