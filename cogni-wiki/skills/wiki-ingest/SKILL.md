---
name: wiki-ingest
description: "Ingest a source (file, URL, paste, paper, article) into a Karpathy-style wiki — writes a summary page with YAML frontmatter, updates wiki/index.md, appends to wiki/log.md, and runs a backlink audit. Trigger when the user says 'ingest this', 'add this to my wiki', 'summarise this into the wiki', 'wiki ingest', drops a file in raw/ and asks what to do with it, or asks to batch ingest multiple sources ('ingest these papers', 'batch ingest raw/', 'ingest everything in raw/')."
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

Exactly one of `--source` or `--batch-file` must be provided.

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source` | Yes (single-source mode) | Path to a file in `raw/`, a URL, or the literal string `--stdin` when the user pasted content. Mutually exclusive with `--batch-file` |
| `--batch-file` | Yes (batch mode) | Path to a JSON file listing multiple sources to ingest in one dispatch. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` for schema. Mutually exclusive with `--source` |
| `--title` | No | Override the page title; otherwise derive from the source (first heading, URL title, filename). Single-source mode only — in batch mode, titles are per-entry in the JSON |
| `--type` | No | Page type: `concept | entity | summary | decision | learning | note`. Defaults to `summary` for full-source ingests, `note` for short pastes. Single-source mode only |
| `--tags` | No | Comma-separated tags. Single-source mode only |

## Workflow

### 0. Dispatch: single-source vs batch

If `--batch-file` is present:

- Validate the JSON against the schema in `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` and abort before any write on schema, missing-source, or mutual-exclusion violations (see `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Input schema" and §"Error policy").
- Otherwise, run Steps 1–8 as a loop over `sources[]`. Each entry flows through Step 1's `mode: fresh | re-ingest` detection independently. Detect mode per entry; do not treat the batch as a mode-wide toggle.
- Fail-fast policy: if any per-source step errors, halt the loop and report what completed, what failed, and what was skipped in Step 9. The wiki stays consistent because every per-source step already writes atomically; see `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Error policy" for the details and resume procedure.
- In Step 9, emit one aggregated report instead of a per-source report.

If `--batch-file` is absent, run Steps 1–9 on the single `--source` as before. This is the existing path; nothing about it changes.

In both cases, the skill instructions and shared references load exactly once per dispatch — one context load, N sources, materially fewer tokens and lower latency than N single-source dispatches.

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
---
```

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

### 6. Run the backlink audit, then apply curated backlinks atomically

**6a. Audit.** Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py --wiki-root <wiki-root> --new-page {slug}`. The script returns JSON with candidate backlinks — existing pages that mention the new page's title, tags, or key entities. If the script exits non-zero or returns malformed JSON, report the error to the user and skip the backlink step — the page itself is already written.

**6b. Curate.** For each candidate, read the target page and decide whether a `[[{slug}]]` link would help the reader. Always add backlinks as natural inline references, not as dumps. For every target you pick, draft (i) a sentence containing `[[{slug}]]` and (ii) the heading line it should go under (or omit the heading to append at the end). This curation step stays human-in-the-loop — the script never auto-selects targets, to preserve the "never invent backlinks" discipline in the Failure modes section.

**6c. Apply atomically.** Re-invoke the same script with `--apply-plan -` and pipe the curated plan JSON on stdin:

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

- `mode: fresh` — increment `entries_count`. Leave all other fields untouched.
- `mode: re-ingest` — leave `entries_count` untouched. The field reflects distinct pages in `wiki/pages/`, not ingest invocations; `wiki-resume`, `wiki-dashboard`, and `wiki-lint` all treat it as a page count, so re-ingests must not inflate it.

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
