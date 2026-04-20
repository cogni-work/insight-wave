---
name: wiki-ingest
description: "Ingest a source (file, URL, paste, paper, article) into a Karpathy-style wiki — writes a summary page with YAML frontmatter, updates wiki/index.md, appends to wiki/log.md, and runs a backlink audit. Also handles bulk ingests: point it at a folder, a glob, or the wiki's own orphan/stub backlog and it enumerates sources itself instead of asking the user for a hand-crafted batch file. Trigger when the user says 'ingest this', 'add this to my wiki', 'summarise this into the wiki', 'wiki ingest', drops a file in raw/ and asks what to do with it, OR when the user asks to bulk/batch ingest ('ingest all the SKILL.md files', 'batch ingest the monorepo', 'ingest everything in raw/', 'rebuild the wiki from the skills', 'ingest all orphan raws', 'refresh the stub pages')."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Wiki Ingest

Turn a raw source into a wiki page and weave it into the existing knowledge base. This is the core compounding operation: every ingest should leave the wiki denser and more interconnected than before.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start of every ingest session to re-anchor on the three-layer model and the compounding principle.

## When to run

- User explicitly asks to ingest, add, file, or summarise a source into the wiki
- User drops a file in `raw/` and asks Claude to process it
- User pastes text (an article, transcript, email, paper abstract) and asks to save it
- User shares a URL and asks to capture it into the wiki

## Never run when

- The wiki has not been set up — check for `.cogni-wiki/config.json`; if missing, offer `wiki-setup` first
- The source is already summarised under the same slug and the user wants a content-only edit — in that case offer `wiki-update` instead. Re-ingests of an existing slug (re-synthesising the page from an updated source) are allowed and handled by Step 1's `mode: re-ingest` branch — do not skip the ingest in that case.

## Parameters

Exactly one of `--source`, `--batch-file`, or `--discover` must be provided.

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source` | Yes (single-source mode) | Path to a file in `raw/`, a URL, or the literal string `--stdin` when the user pasted content. Mutually exclusive with `--batch-file` and `--discover` |
| `--batch-file` | Yes (batch mode) | Path to a JSON file listing multiple sources to ingest in one dispatch. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` for schema. Mutually exclusive with `--source` and `--discover` |
| `--discover` | Yes (discovery mode) | Produce the batch from the filesystem instead of a hand-written JSON file. Accepts `orphans` (raw/ files not yet cited by any page), `stubs` (pages with `status: draft`), or `glob:<pattern>` (any files matching the pattern). See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Discovery" for the full grammar. Mutually exclusive with `--source` and `--batch-file` |
| `--discover-dry-run` | No (discovery mode) | Print the resolved batch JSON and exit without ingesting. Use this to review the batch before committing to the writes. |
| `--title-template` | No (discovery mode) | Format string for per-entry titles so the discovered batch matches the wiki's existing slug convention (e.g., `skill-{parent3}-{parent}` turns `../cogni-claims/skills/claims/SKILL.md` into `skill-cogni-claims-claims`). Passed through to `batch_builder.py`; see its `--title-template` help for placeholders. Required with `--discover glob:` whenever the wiki uses anything other than plain filename slugs |
| `--older-than-days` | No (discovery mode) | For `--discover stubs`: restrict to drafts whose `updated:` date is older than N days |
| `--exclude-ingested` | No (discovery mode) | Drop any discovered source whose derived slug already exists as a wiki page. Use this to run `--discover` repeatedly and only ever ingest the deltas. |
| `--title` | No | Override the page title; otherwise derive from the source (first heading, URL title, filename). Single-source mode only — in batch/discovery mode, titles are per-entry |
| `--type` | No | Page type: `concept | entity | summary | decision | learning | note`. Defaults to `summary` for full-source ingests, `note` for short pastes. In discovery mode, applied as a default to every discovered entry |
| `--tags` | No | Comma-separated tags. In discovery mode, applied as a default to every discovered entry |
| `--auto-backlinks <K>` | No | Skip Step 6 hand-curation: auto-apply the top-K `confidence != low` candidates from `backlink_audit.py`. Mutually exclusive with `--review`. Default for batch/discover mode is `--auto-backlinks 5`; default for single-source mode is hand-curation. Pass explicitly (e.g. `--auto-backlinks 3` or `--auto-backlinks 8`) to tune the cap. |
| `--review` | No | Force Step 6 hand-curation, even in batch/discover mode. Mutually exclusive with `--auto-backlinks`. Default (and no-op) in single-source mode; the opt-out against the new batch/discover default. |

## Workflow

### 0. Dispatch: single-source vs batch vs discovery

The three input modes are mutually exclusive. Pick the one that matches the caller's inputs and follow the corresponding rule; everything from Step 1 onwards is identical across modes.

**Backlink-curation decision (once, at dispatch).** Resolve `auto_backlinks` before any Step 1 work so every worker receives a consistent instruction:

- Both `--auto-backlinks` and `--review` set → abort with `{"success": false, "error": "--auto-backlinks and --review are mutually exclusive"}` before any write.
- `--auto-backlinks <K>` set → `auto_backlinks = K`.
- `--review` set → `auto_backlinks = null` (force hand-curation).
- Neither set:
  - Single-source (`--source`): `auto_backlinks = null` (unchanged behaviour).
  - Batch (`--batch-file`) or discovery (`--discover`): `auto_backlinks = 5` (new default — bulk rebuilds skip per-target hand-curation unless the caller opts back in with `--review`).

The resolved value travels into Step 6 — either inline (single-source) or via the per-source worker prompt (batch/discover).

**If `--discover` is present** (discovery mode):

Discovery means "build the batch from the filesystem instead of asking the user to type it out". It exists because on a bulk rebuild — dozens of SKILL.md files across a monorepo, a folder of newly-dropped PDFs, a backlog of stub drafts — hand-crafting a JSON listing every entry is neither respectful of the user's time nor safe (typos silently drop sources). The skill should do the walk itself, let the user review, and then ingest.

1. Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/batch_builder.py` with the flags parsed from `--discover`, plus any of `--title-template`, `--older-than-days`, `--exclude-ingested`, `--type`, `--tags`, `--limit` that the user passed. The `--discover` argument maps as follows:
   - `--discover orphans` → `batch_builder.py --orphans`
   - `--discover stubs` → `batch_builder.py --stubs`
   - `--discover glob:<pattern>` → `batch_builder.py --glob '<pattern>'`
   - `--discover glob:<pattern>:<root>` → `batch_builder.py --glob '<pattern>' --root <root>` (the second colon-separated field is optional and overrides the default walk base).
2. Parse the script's JSON. On `success: false`, surface the error verbatim and stop.
3. **Present the resolved batch to the user before any write.** Print `data.count`, `data.skipped_existing` (when `--exclude-ingested` is set), and the first 10 `data.sources[]` entries. If `data.count == 0`, report "nothing to ingest" and stop — this is a normal outcome, not an error.
4. If `--discover-dry-run` is set, emit the full JSON on stdout and stop. No writes. This is the review hand-off: the user can redirect to a file, edit it, and pass it back as `--batch-file` later.
5. Otherwise, confirm with the user ("Ingest these N sources?") unless they passed a phrasing that implied "just do it" (e.g., "ingest all of them, no need to confirm"). On confirmation, feed `data.sources[]` into the batch-mode pipeline at the same entry point `--batch-file` uses. The rest of this step 0 (fail-fast, atomic per-source writes, aggregated Step 9 report) is identical.

Slug collisions in discovery mode are already handled by Step 1's `mode: fresh | re-ingest` detection — `--exclude-ingested` is an optimisation that skips known-existing slugs at discovery time so the user reviews a smaller, more actionable list. Both layers are safe; the re-ingest branch is the authoritative fallback.

**If `--batch-file` is present** (batch mode):

- Validate the JSON against the schema in `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` and abort before any write on schema, missing-source, or mutual-exclusion violations (see `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Input schema" and §"Error policy"). Malformed input never half-dispatches — no worker fires until the whole batch validates.
- Otherwise, execute `sources[]` via **per-source subagent fan-out**, not an inline loop. The orchestrator must not read page bodies or backlink audit JSON; each source's Steps 1–8 run inside a `cogni-wiki:ingest-worker` subagent with its own context window, and only a compact JSON payload returns here. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Execution model" for the full contract.
  1. Resolve `batch_size` from `<wiki-root>/.cogni-wiki/config.json` (key `batch_size`, range 2–8). Default **5** if absent. This caps the number of workers dispatched concurrently.
  2. Partition `sources[]` into order-preserving chunks of `batch_size` entries each (the last chunk may be shorter).
  3. For each chunk, **in order**:
     - Dispatch one `Task(subagent_type: "ingest-worker", run_in_background: true, prompt: "source_entry: <json>\nwiki_root: <abs path>\nauto_backlinks: <K or null>\n\nExecute Steps 1–8 per your agent instructions and return the JSON block.")` per source in the chunk. The per-source `source_entry` is the raw batch row (with its `source`, optional `title`, `type`, `tags`); `wiki_root` is the absolute path you resolved in Step 1; `auto_backlinks` is the dispatch-time resolution described in the "Backlink-curation decision" paragraph above — `5` by default in batch mode, `null` when the user passed `--review`, or the explicit `K` from `--auto-backlinks K`.
     - Wait for every Task in the chunk to complete before dispatching the next chunk. Do not stream across chunks — bounded concurrency is the whole point.
     - For each return, extract the final fenced ` ```json ... ``` ` block. If **no** block is present, synthesize `{source, slug: null, mode: null, backlinks_added: 0, index_action: null, errors: [{step: null, message: "worker returned no JSON payload"}]}` and treat as a failure. Do not retry; surface the crash.
  4. **Fail-fast across chunks.** If any result in a completed chunk has a non-empty `errors[]`, **halt** — do not dispatch further chunks. Sources dispatched in the failing chunk that returned cleanly still count as completed (the atomic per-source scripts guarantee the wiki is consistent for them). Sources in not-yet-dispatched chunks are reported as "skipped" in Step 9.
  5. After all chunks complete (or on halt), run Step 9 aggregation from the collected worker returns — the orchestrator never loads per-source bodies.
- Step 3 takeaway synthesis still fires **per source inside its worker** (autonomous-run semantics, SKILL.md Step 3 line 107). Workers' Step 3 output appears inside their subagent transcripts, not interleaved in the parent; the aggregated Step 9 report restates mode per slug so the user can correlate.
- In Step 9, emit one aggregated report instead of a per-source report, built from the worker return payloads.

**If neither `--batch-file` nor `--discover` is present**, run Steps 1–9 on the single `--source`. This is the existing path; nothing about it changes.

In all three cases, the skill instructions and shared references load exactly once per dispatch — one context load, N sources, materially fewer tokens and lower latency than N single-source dispatches.

### 1. Locate the wiki and detect ingest mode

Walk upward from the current working directory to find the nearest `.cogni-wiki/config.json`. If none found, stop and offer to run `wiki-setup`.

Derive the target slug from `--title` (or from the source filename / URL title / first heading if `--title` is absent). Then check whether `<wiki-root>/wiki/pages/{slug}.md` already exists:

- **Fresh ingest** (`mode: fresh`) — no page at that slug. Proceed normally.
- **Re-ingest** (`mode: re-ingest`) — a page at that slug exists. This is an explicit, allowed path (used by pilot rebuilds where the page is being re-synthesised from an updated source), but it is a different operation than a fresh ingest. Emit this warning verbatim to the user before proceeding:

  > Re-ingesting an existing slug (`{slug}`). For content-only tweaks, prefer `wiki-update`; this ingest will overwrite the page, log a `re-ingest` entry, and leave `entries_count` unchanged.

  Then proceed with the remaining steps — `mode` changes only Step 7 (log entry type) and Step 8 (entry count handling).

See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/ingest-workflow.md` §"Mode flag: fresh vs re-ingest" for when to pick `wiki-update` instead of re-ingest.

### 2. Read the source

- **File in `raw/`**: Read it directly. For PDFs, extract text with the Read tool's pages parameter.
- **URL**: Fetch via WebFetch, then write a local copy under `raw/` with a slug-named filename so the source is preserved even if the URL rots.
- **Pasted text**: Write the paste to `raw/paste-{YYYYMMDD-HHMMSS}.md` first, then proceed as a file ingest. Never ingest pasted content without persisting the raw.

Every wiki page must cite a file in `raw/` or a stable URL. This link to raw/ is what makes the wiki trustworthy — every claim traces through a page to its original source, and that chain breaks if any page floats without a raw anchor.

### 3. Surface key takeaways BEFORE writing the page

This is the most important step. Surface takeaways before writing — it prevents duplicate pages and keeps the wiki compounding rather than fragmenting. Before writing any page, state in plain prose:

1. **What the source is** — type, author, date, length
2. **Three to seven key takeaways** — the claims a future reader of the wiki would actually want
3. **Which existing wiki pages this source touches** — run `grep` / Glob over `wiki/pages/` for entity names, concept slugs, and tags that appear in the source
4. **Proposed page type and title**

Show this synthesis to the user before proceeding to write. For autonomous runs (when the user said "just ingest it"), still emit the synthesis in the response — but proceed to step 4 without waiting.

### 4. Write the new page

Path: `<wiki-root>/wiki/pages/{slug}.md` where `slug` is derived from the title.

Frontmatter (see `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/page-frontmatter.md` for the full schema):

```yaml
---
id: {slug}
title: {title}
type: {type}
tags: [{tag1}, {tag2}]
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
sources:
  - ../raw/{source-filename}
publisher_url: https://{publisher canonical URL, only if observable}
---
```

**On `publisher_url`**: populate it only when the canonical URL is observable — do not fabricate. URL ingest → set it to the source URL (same one passed to WebFetch). File ingest with a URL printed on the PDF cover / in PDF metadata / in source text → use that URL. File ingest with no observable URL → omit the `publisher_url` key entirely (the field is optional). A guessed URL that 404s costs more credibility than an unlinked citation downstream; cogni-research will fall back to the wiki's `publisher_base_url` if set.

Body structure:

1. **One-sentence summary** (the line that will appear in `index.md`)
2. **Key takeaways** — bulleted, each with a `[[wikilink]]` or source citation where applicable
3. **Details** — the actual distilled content, organized with `##` subheadings
4. **Sources** — markdown-linked list of raw files and URLs

Write the page file. Do not write anything else yet.

### 5. Update `wiki/index.md`

Decide which category heading the new page belongs under — that decision still belongs to the orchestrator, because it requires judgement about the taxonomy. Then hand the write itself to the helper script so *placement* becomes deterministic:

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/wiki_index_update.py \
    --wiki-root <wiki-root> \
    --slug {slug} \
    --summary "{one-sentence summary}" \
    --category "{category heading text}"
```

The script:

- inserts `- [[{slug}]] — {summary}` under the matching `##` or `###` heading, creating the heading at the end of the file if it does not yet exist;
- on re-ingest, **updates the existing line in place** rather than appending a duplicate — so `mode: re-ingest` from Step 1 is safe to chain through without extra orchestrator bookkeeping;
- keeps the category section alphabetised by slug after every insert;
- writes atomically via `tempfile + os.replace` (the same pattern used elsewhere in the plugin) so a crash mid-write cannot leave a half-updated index.

Output extends the standard `{success, data, error}` contract with `data.action` (`inserted` | `updated`), `data.category`, `data.category_created`, and the final `data.line` that was written. Surface the action to the user so they see whether this was a new line or an in-place refresh.

If the script exits non-zero or returns malformed JSON, report the error to the user and stop; the page write from Step 4 stays on disk, but the index is known-good because of the atomic `tempfile + os.replace`.

### 6. Run the backlink audit, then apply backlinks atomically

Two paths — hand-curation (`auto_backlinks = null`) or auto-mode (`auto_backlinks = K`) — resolved at Step 0 and branched here. Both paths end with the same `--apply-plan -` atomic-write call, so downstream reporting (Step 9) is uniform.

#### Path A — Hand-curation (when `auto_backlinks = null`)

**6a. Audit.** Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py --wiki-root <wiki-root> --new-page {slug}`. The script returns JSON with candidate backlinks — existing pages that mention the new page's title, tags, or key entities. If the script exits non-zero or returns malformed JSON, report the error to the user and skip the backlink step — the page itself is already written.

**6b. Curate.** For each candidate, read the target page and decide whether a `[[{slug}]]` link would help the reader. Always add backlinks as natural inline references, not as dumps. For every target you pick, draft (i) a sentence containing `[[{slug}]]` and (ii) the heading line it should go under (or omit the heading to append at the end). This curation step stays human-in-the-loop — the script never auto-selects targets, to preserve the "never invent backlinks" discipline in the Failure modes section.

#### Path B — Auto-mode (when `auto_backlinks = K` is an integer)

**6a'. Compact audit.** Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py --wiki-root <wiki-root> --new-page {slug} --top K --min-confidence medium`. This returns the top-K candidates already pre-filtered to `confidence ∈ {medium, high}` plus summary counters (`total_candidates`, `by_confidence`) so the orchestrator can log the shape without reading a full candidate dump. If the script exits non-zero or returns malformed JSON, report the error and skip the backlink step.

**6b'. Bulk-draft sentences.** For each returned candidate, read **only** the target page's title + first paragraph (do not read the full body — that defeats the point of auto-mode) and write one short sentence containing `[[{slug}]]` that would read naturally in that context. No heading is required — auto-mode always appends at the end of the target body so the draft does not collide with an existing heading the worker hasn't read.

The "never invent backlinks" discipline is preserved by two mechanisms: (i) `--min-confidence medium` drops the keyword-noise bucket at audit time; (ii) K is bounded by the dispatch-time cap (default 5). The sentence itself is drafted by the worker LLM from the target's title + first paragraph, keeping it anchored to real page content rather than pattern-matched phrasing. The tradeoff is explicit: auto-mode replaces "hand-curated-with-7-ideal-backlinks" with "auto-applied-with-up-to-K-decent-backlinks" — the right call for bulk rebuilds, not for single high-effort sources.

#### 6c. Apply atomically (both paths)

Re-invoke the same script with `--apply-plan -` and pipe the plan JSON on stdin:

```json
{
  "targets": [
    {
      "slug": "<target-slug>",
      "sentence": "…inline prose containing [[{slug}]]…",
      "insert_after_heading": "## <exact heading line>"
    }
  ]
}
```

The `--apply-plan` pass writes the backlink sentence and bumps the target page's `updated:` frontmatter field to today in a **single atomic write per page**. This replaces the older two-step flow where the orchestrator had to remember to edit `updated:` separately — a rule that worked at 7 pages but drifted silently at larger scale (issue #73). The apply pass is idempotent: targets that already contain `[[{slug}]]` are skipped, so re-running the same plan after a fix is safe.

Output extends the audit JSON with `data.applied[]`, `data.skipped_existing_backlink[]`, and `data.failed[]`. Surface these to the user in the Step 9 report so they can see exactly which pages changed.

### 7. Append to `wiki/log.md`

Append a single line.

Fresh ingest (`mode: fresh`):

```
## [{YYYY-MM-DD}] ingest    | {slug} — {title}
```

Re-ingest (`mode: re-ingest`):

```
## [{YYYY-MM-DD}] re-ingest | {slug} — {title}
```

The hyphenated `re-ingest` form parallels the existing lowercase verb grammar (`ingest`, `update`) and keeps the log greppable by operation type.

Never rewrite existing log lines.

### 8. Update `.cogni-wiki/config.json`

- `mode: fresh` — invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/config_bump.py --wiki-root <wiki-root> --key entries_count --delta 1`. The script grabs the shared `.cogni-wiki/.lock` before read-modify-write, so concurrent batch-mode workers cannot clobber each other (issue #84). Never edit `config.json` inline — the inline read-modify-write race produced silent under-counts before v0.0.12.
- `mode: re-ingest` — leave `entries_count` untouched. The field reflects distinct pages in `wiki/pages/`, not ingest invocations; `wiki-resume`, `wiki-dashboard`, and `wiki-lint` all treat it as a page count, so re-ingests must not inflate it.

If `config_bump.py` exits non-zero or returns malformed JSON, report the error but do not abort — the page, index, backlinks, and log are already consistent on disk. The script is idempotent-safe to re-run with a compensating `--delta` to reconcile drift.

### 9. Report to the user

**Single-source mode.** Tell the user, in ≤5 sentences:
- The new page slug and path
- How many existing pages got backlinks
- What to do next (usually: drop another source or run `wiki-query`)

**Batch mode.** Emit one aggregated block instead of a per-source report. For every entry that reached this step, print the slug, its resolved mode (`fresh` or `re-ingest`), and its backlink count. Report `entries_count` delta (fresh sources only; re-ingests never increment). On a fail-fast halt, also list the source that failed with its error and any sources that were skipped. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Step 9 in batch mode" for the exact format.

## Output

- One new file in `wiki/pages/`
- `wiki/index.md` updated
- N existing pages in `wiki/pages/` edited with new backlinks (where N ≥ 0)
- One appended line in `wiki/log.md`
- Updated `config.json`

## Failure modes and rules

- **Never summarise from memory.** The page's claims must all trace back to the source text. If the source is silent on a topic, the page is silent on it.
- **Never invent backlinks.** Only link to pages that actually exist in `wiki/pages/`.
- **Never overwrite a page silently.** Overwrites are only allowed through the explicit re-ingest path: Step 1 must detect the existing slug, set `mode: re-ingest`, and emit the re-ingest warning before any page write. Silent overwrites (writing to an existing slug without surfacing `mode: re-ingest` to the user) remain forbidden. For content-only edits that preserve the existing synthesis, use `wiki-update` rather than a re-ingest.
- **Raw first, page second.** Pasted content is persisted to `raw/` before any page work begins.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/page-frontmatter.md` — full frontmatter schema
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/ingest-workflow.md` — worked example
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` — `--batch-file` input schema, per-source mode rules, error policy, and worked example
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py` — candidate backlink finder
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/wiki_index_update.py` — deterministic `wiki/index.md` insert/update helper
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/batch_builder.py` — discovery helper; enumerates candidates for `--discover` and emits the batch-mode payload on stdout
- `${CLAUDE_PLUGIN_ROOT}/agents/ingest-worker.md` — per-source subagent dispatched from batch mode; owns Steps 1–8 for one source entry and returns a compact JSON payload to the orchestrator
