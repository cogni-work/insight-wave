---
name: wiki-ingest
description: "Ingest a source (file, URL, paste, paper, article) into a Karpathy-style wiki — writes a summary page with YAML frontmatter, updates wiki/index.md, appends to wiki/log.md, and runs a backlink audit. Also handles bulk ingests: point it at a folder, a glob, the wiki's own orphan/stub backlog, or a completed cogni-research project and it enumerates sources itself instead of asking the user for a hand-crafted batch file. Trigger when the user says 'ingest this', 'add this to my wiki', 'summarise this into the wiki', 'wiki ingest', drops a file in raw/ and asks what to do with it, OR when the user asks to bulk/batch ingest ('ingest all the SKILL.md files', 'batch ingest the monorepo', 'ingest everything in raw/', 'rebuild the wiki from the skills', 'ingest all orphan raws', 'refresh the stub pages', 'deposit the research report into the wiki', 'turn the research project into wiki pages')."
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
| `--discover` | Yes (discovery mode) | Produce the batch from the filesystem instead of a hand-written JSON file. Accepts `orphans` (raw/ files not yet cited by any page), `stubs` (pages with `status: draft`), `glob:<pattern>` (any files matching the pattern), or `research:<project-slug>` (one batch entry per sub-question of a cogni-research project, with synthesised raw files materialised under `raw/research-<slug>/`). See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Discovery" for the full grammar. Mutually exclusive with `--source` and `--batch-file` |
| `--discover-dry-run` | No (discovery mode) | Print the resolved batch JSON and exit without ingesting. Use this to review the batch before committing to the writes. |
| `--title-template` | No (discovery mode) | Format string for per-entry titles so the discovered batch matches the wiki's existing slug convention (e.g., `skill-{parent3}-{parent}` turns `../cogni-claims/skills/claims/SKILL.md` into `skill-cogni-claims-claims`). Passed through to `batch_builder.py`; see its `--title-template` help for placeholders. Required with `--discover glob:` whenever the wiki uses anything other than plain filename slugs |
| `--older-than-days` | No (discovery mode) | For `--discover stubs`: restrict to drafts whose `updated:` date is older than N days |
| `--exclude-ingested` | No (discovery mode) | Drop any discovered source whose derived slug already exists as a wiki page. Use this to run `--discover` repeatedly and only ever ingest the deltas. |
| `--title` | No | Override the page title; otherwise derive from the source (first heading, URL title, filename). Single-source mode only — in batch/discovery mode, titles are per-entry |
| `--type` | No | Page type: `concept | entity | summary | decision | interview | meeting | learning | note`. Defaults to `summary` for full-source ingests, `note` for short pastes. Also selects the body template Step 4 uses — see Step 4 for the type→template map. In discovery mode, applied as a default to every discovered entry |
| `--tags` | No | Comma-separated tags. In discovery mode, applied as a default to every discovered entry |
| `--no-convert` | No | Skip Step 2's auto-conversion branch even if the source is a non-markdown format (`.docx`, `.pptx`, `.html`, …). Use this when you have already pre-converted the source to markdown and want the existing path to be read verbatim. Single-source mode and per-entry in batch/discovery mode (set `no_convert: true` on the entry); ignored when the source is `.md`, `.pdf`, or a URL because Step 2 already short-circuits those. |
| `--auto-backlinks <K>` | No | Skip Step 6 hand-curation: auto-apply the top-K `confidence != low` candidates from `backlink_audit.py`. Mutually exclusive with `--review`. Default for batch/discover mode is `--auto-backlinks 5`; default for single-source mode is hand-curation. Pass explicitly (e.g. `--auto-backlinks 3` or `--auto-backlinks 8`) to tune the cap. |
| `--review` | No | Force Step 6 hand-curation, even in batch/discover mode. Mutually exclusive with `--auto-backlinks`. Default (and no-op) in single-source mode; the opt-out against the new batch/discover default. |

## Workflow

### 0. Dispatch: single-source vs batch vs discovery

The three input modes are mutually exclusive. Pick the one that matches the caller's inputs and follow the corresponding rule; everything from Step 1 onwards is identical across modes.

**Sequential by design.** Batch and discovery modes execute Steps 1–8 as a strict sequential loop in the orchestrator's own context — one source at a time, in input order, with every page write, index update, backlink apply, log line, and config bump committed to disk before the next iteration begins. This is load-bearing: source N+1's Step 3 ("which existing pages does this source touch") and Step 6 (backlink audit) must see the page that source N just created, otherwise the wiki fragments instead of compounds. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Execution model" for the rationale and the history of why an earlier per-source subagent fan-out was removed. Step 8.5 (context brief rebuild, v0.0.29+) runs **once per dispatch** after the loop completes, not per source.

**Backlink-curation decision (once, at dispatch).** Resolve `auto_backlinks` before any Step 1 work so every iteration applies the same rule:

- Both `--auto-backlinks` and `--review` set → abort with `{"success": false, "error": "--auto-backlinks and --review are mutually exclusive"}` before any write.
- `--auto-backlinks <K>` set → `auto_backlinks = K` (auto-mode opt-in).
- `--review` set → `auto_backlinks = null` (force hand-curation; this is the default in all modes — `--review` is a no-op kept for backwards compatibility).
- Neither set: `auto_backlinks = null` in all modes — single-source, batch, and discovery alike. Hand-curation is the Karpathy-aligned default; auto-mode is an explicit opt-in via `--auto-backlinks K`.

The resolved value travels into Step 6.

**If `--discover` is present** (discovery mode):

Discovery means "build the batch from the filesystem instead of asking the user to type it out". It exists because on a bulk rebuild — dozens of SKILL.md files across a monorepo, a folder of newly-dropped PDFs, a backlog of stub drafts — hand-crafting a JSON listing every entry is neither respectful of the user's time nor safe (typos silently drop sources). The skill should do the walk itself, let the user review, and then ingest.

1. Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/batch_builder.py` with the flags parsed from `--discover`, plus any of `--title-template`, `--older-than-days`, `--exclude-ingested`, `--type`, `--tags`, `--limit` that the user passed. The `--discover` argument maps as follows:
   - `--discover orphans` → `batch_builder.py --orphans`
   - `--discover stubs` → `batch_builder.py --stubs`
   - `--discover glob:<pattern>` → `batch_builder.py --glob '<pattern>'`
   - `--discover glob:<pattern>:<root>` → `batch_builder.py --glob '<pattern>' --root <root>` (the second colon-separated field is optional and overrides the default walk base).
   - `--discover research:<project-slug>` → `batch_builder.py --research <project-slug>`. **In dry-run** (`--discover-dry-run` is set) **also pass `--no-materialize`** so the script enumerates without writing the per-sub-question raw files. The user can then re-run without `--discover-dry-run` to commit the materialisation as part of the real batch dispatch.
   - `--discover research:<project-slug>:<research-root>` → `batch_builder.py --research <project-slug> --research-root <research-root>`. The optional second colon-separated field overrides the auto-located project directory.
2. Parse the script's JSON. On `success: false`, surface the error verbatim and stop.
3. **Present the resolved batch to the user before any wiki-page write.** Print `data.count`, `data.skipped_existing` (when `--exclude-ingested` is set), and the first 10 `data.sources[]` entries. For `--discover research:`, also surface the `data.research` block (sub-question / context / source / verified-claim counts) so the user knows the deposit shape — and note that the per-sub-question synthesis files have already been materialised under `raw/research-<slug>/` (or were not, if `--discover-dry-run` triggered `--no-materialize`). If `data.count == 0`, report "nothing to ingest" and stop — this is a normal outcome, not an error.
4. If `--discover-dry-run` is set, emit the full JSON on stdout and stop. No writes. This is the review hand-off: the user can redirect to a file, edit it, and pass it back as `--batch-file` later.
5. Otherwise, confirm with the user ("Ingest these N sources?") unless they passed a phrasing that implied "just do it" (e.g., "ingest all of them, no need to confirm"). On confirmation, feed `data.sources[]` into the same sequential pipeline `--batch-file` uses.

Slug collisions in discovery mode are already handled by Step 1's `mode: fresh | re-ingest` detection — `--exclude-ingested` is an optimisation that skips known-existing slugs at discovery time so the user reviews a smaller, more actionable list. Both layers are safe; the re-ingest branch is the authoritative fallback.

**If `--batch-file` is present** (batch mode):

- Validate the JSON against the schema in `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` and abort before any write on schema, missing-source, or mutual-exclusion violations (see `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Input schema" and §"Error policy"). Malformed input never half-writes — no source is touched until the whole batch validates.
- Otherwise, execute `sources[]` as a **strict sequential loop**. For each `source_entry` in input order, run Steps 1–8 inline in this orchestrator's context (read source → Step 3 takeaway synthesis → write page → update index → backlink audit + apply → log → config bump), passing `auto_backlinks` resolved above into Step 6. Only after all per-source scripts have returned and their writes committed do you advance to the next entry.
- **Fail-fast.** If any iteration's step (1–8) fails, halt the loop immediately. Sources processed before the failure are atomically consistent on disk (per-page writes use `tempfile + os.replace`; shared-state writes go through the locked scripts). Record the failed entry's error and the list of un-attempted entries for the Step 9 report.
- **Step 3 in batch mode.** Surface the takeaway synthesis to the user transcript exactly as in single-source mode. Batch mode is autonomous-run by construction (the user said "ingest all of them"), so emit the synthesis and proceed to Step 4 without waiting for confirmation — the discipline is "synthesis is visible", not "the user must approve every page".
- Once the loop completes (or fail-fast halts it), run Step 8.5 once for the dispatch, then emit the aggregated Step 9 report.

**If neither `--batch-file` nor `--discover` is present**, run Steps 1–9 on the single `--source`. This is the existing path; nothing about it changes.

In all three cases, the skill instructions and shared references load exactly once per dispatch — one context load, N sources, materially fewer tokens than N single-source dispatches. The throughput cost vs the removed parallel fan-out is real and accepted: knowledge accumulation must be sequential for source N+1 to see source N's page, which is the whole point of a compounding wiki.

### 1. Locate the wiki and detect ingest mode

Walk upward from the current working directory to find the nearest `.cogni-wiki/config.json`. If none found, stop and offer to run `wiki-setup`.

Derive the target slug from `--title` (or from the source filename / URL title / first heading if `--title` is absent). Then check whether `{slug}` is already present in any of the per-type page directories under `<wiki-root>/wiki/` (search across `concepts/`, `entities/`, `summaries/`, `decisions/`, `interviews/`, `meetings/`, `learnings/`, `syntheses/`, `notes/` — the slug is globally unique, so the page lives in at most one of them):

- **Fresh ingest** (`mode: fresh`) — no page at that slug. Proceed normally.
- **Re-ingest** (`mode: re-ingest`) — a page at that slug exists. This is an explicit, allowed path (used by pilot rebuilds where the page is being re-synthesised from an updated source), but it is a different operation than a fresh ingest. Emit this warning verbatim to the user before proceeding:

  > Re-ingesting an existing slug (`{slug}`). For content-only tweaks, prefer `wiki-update`; this ingest will overwrite the page, log a `re-ingest` entry, and leave `entries_count` unchanged.

  Then proceed with the remaining steps — `mode` changes only Step 7 (log entry type) and Step 8 (entry count handling).

See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/ingest-workflow.md` §"Mode flag: fresh vs re-ingest" for when to pick `wiki-update` instead of re-ingest.

### 2. Read the source

The source-reading branch picks one of four paths and, for non-markdown files, can chain through an auto-conversion sub-step before the rest of the pipeline runs. The original under `raw/` always remains the ground-truth artefact — frontmatter `sources:` points at it, never at the converted markdown — so re-ingest can re-convert if a future tooling release improves extraction.

- **File in `raw/`**:
  - `.md` / `.markdown` → read directly.
  - `.pdf` → extract text with the Read tool's `pages` parameter, exactly as before.
  - **Any other extension** (`.docx`, `.pptx`, `.xlsx`, `.html`, `.epub`, `.txt`, …) → run the auto-conversion sub-step below, then read the converted markdown the script returned. Skip the sub-step entirely when the user passed `--no-convert` (or set `no_convert: true` on the batch entry); in that case, treat the source as opaque and only the orchestrator's own reading discipline applies.
- **URL**: Fetch via WebFetch, then write a local copy under `raw/` with a slug-named filename so the source is preserved even if the URL rots. WebFetch already returns markdown-ish content, so there is no auto-conversion sub-step here; `--no-convert` is a no-op.
- **Pasted text**: Write the paste to `raw/paste-{YYYYMMDD-HHMMSS}.md` first, then proceed as a markdown file ingest. Never ingest pasted content without persisting the raw.

Every wiki page must cite a file in `raw/` or a stable URL. This link to raw/ is what makes the wiki trustworthy — every claim traces through a page to its original source, and that chain breaks if any page floats without a raw anchor.

#### 2a. Auto-conversion sub-step (non-markdown `raw/` files only)

Invoke the helper, parse the JSON, branch on `data.backend`:

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/convert_to_md.py --source <source-path>
```

The script preserves the original under `raw/` and writes converted markdown alongside as `<source>.converted.md`. Conversion is idempotent: a `.converted.md` whose mtime is newer than (or equal to) the source's mtime is re-used unchanged (`backend: cache-hit`); pass `--force` to override when deliberately re-converting.

| `data.backend` | What it means | What to do |
|---|---|---|
| `noop-markdown` | Source was `.md` / `.markdown` | Read `data.converted_path` (== source); no surfacing needed |
| `noop-pdf` | Source was `.pdf` | Use the existing Read-tool pages flow; ignore `data.converted_path` |
| `stdlib-passthrough` | `.txt` copied verbatim by stdlib | Read `data.converted_path`; surface `[backend: stdlib-passthrough]` |
| `stdlib-html` | `.html` / `.htm` stripped via stdlib `html.parser` | Read `data.converted_path`; surface `[backend: stdlib-html]` |
| `markitdown` | Shelled out to the optional `markitdown` CLI | Read `data.converted_path`; surface `[backend: markitdown]` |
| `cache-hit` | `<source>.converted.md` was up-to-date and re-used | Read `data.converted_path`; surface `[backend: cache-hit]` |

Surface the backend in the user transcript next to the source line so the operator can see which conversion path ran (e.g. `Source: raw/q1-customer-call.docx [backend: markitdown]`). This makes pre-conversion failures and quality drift visible without forcing a separate diagnostic.

If the script returns `success: false`, surface the error verbatim and offer two paths to the user:

- For `backend: unsupported` (a binary office format with no markitdown installed): point them at the README's "Optional dependencies" section so they can install `markitdown`, or ask them to convert to `.md` manually and re-invoke. Do not invent a fallback — half-extracted text from a `.docx` is worse than no ingest.
- For `backend: markitdown-error` (markitdown is installed but failed on this file): surface the stderr and ask whether to retry with `--no-convert` (skip the helper entirely and pass the binary path through unchanged) or hand-convert.

In batch / discovery mode, treat a non-zero `convert_to_md.py` exit as the entry's Step 2 failure and let the fail-fast policy in §0 halt the loop. Sources processed before the failure are already consistent on disk; nothing about the converted-file caching changes that — `.converted.md` writes go through `tempfile + os.replace` so a crash mid-script cannot leave a half-written cache.

`--no-convert` (or `no_convert: true` on a batch entry) skips this entire sub-step. Use it when the user has already pre-converted the source and dropped both the original and the markdown copy in `raw/`, or when investigating a markitdown extraction bug and you want the orchestrator to read the binary path directly. The script is idempotent enough that re-enabling auto-conversion on a later run still produces the right state.

### 3. Surface key takeaways BEFORE writing the page

This is the most important step. Surface takeaways before writing — it prevents duplicate pages and keeps the wiki compounding rather than fragmenting. Before writing any page, state in plain prose:

1. **What the source is** — type, author, date, length
2. **Three to seven key takeaways** — the claims a future reader of the wiki would actually want
3. **Which existing wiki pages this source touches** — run `grep -r` / Glob over `wiki/` (recursing through every per-type page dir) for entity names, concept slugs, and tags that appear in the source
4. **Proposed page type and title**

Show this synthesis to the user before proceeding to write. For autonomous runs (when the user said "just ingest it"), still emit the synthesis in the response — but proceed to step 4 without waiting.

### 4. Write the new page

Path: `<wiki-root>/wiki/{type}/{slug}.md` where `slug` is derived from the title and `{type}` is the directory matching the resolved `type:` frontmatter value (`concepts/` for `type: concept`, `decisions/` for `type: decision`, etc. — see `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/references/directory-layout.md` for the full map).

#### 4a. Select the body template

Domain-specific scaffolds live under `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/templates/` — one markdown file per `type` (plus two tag-driven variants). Pick the template **before** drafting the body so the page conforms to the per-type heading shape and required `[[wikilinks]]`. The map (also documented in `references/page-frontmatter.md`):

| Resolved type | Template |
|---|---|
| `summary`, `concept`, `entity` | `default.md` |
| `interview` (default) | `interview.md` |
| `interview` + tag `customer-call` | `customer-call.md` |
| `meeting` | `meeting.md` |
| `decision` | `decision.md` |
| `learning` (default) | `learning.md` |
| `learning` + tag `retro` | `retro.md` |
| `synthesis`, `note` | no template — write the body directly |

Resolution order:

1. **Explicit `--type T`.** Use `T`. If the user also passed `--tags` containing `customer-call` (with `--type interview`) or `retro` (with `--type learning`), pick the matching variant. Otherwise pick the default for `T`.
2. **No `--type` was passed.** Infer from the source using these heuristics, in order — first hit wins:
   - Source is a transcript with named speakers → `type: interview`. If the speakers include a customer / account context (the source is in a `customer-calls/` folder, or the user prompt mentions an account name), pick the `customer-call` variant via tag.
   - Source has agenda + attendees + action items → `type: meeting`.
   - Source is an ADR-shaped document (Context / Options / Decision / Consequences) → `type: decision`.
   - Source is a retrospective board / "what went well, what didn't, actions" → `type: learning` with the `retro` tag.
   - Source is a generalised lesson distilled across multiple inputs (no one-source anchor) → `type: learning`.
   - Source is a paper, article, blog post, or report → `type: summary`.
   - Source is a freeform paste under ~500 chars → `type: note`.
   - Otherwise → `type: summary` with `default.md`.
3. **Re-ingest mode.** Read the existing page's `type` (and any variant-defining tag like `customer-call` or `retro`) from frontmatter and pick the matching template. Do **not** silently switch templates on re-ingest — if the source has shifted shape, surface it in Step 3's takeaway synthesis and ask the user to confirm a type change before writing.
4. **Surface the choice.** Step 3's takeaway block already names "Proposed page type and title"; extend that line to include the resolved template (e.g. `Proposed: type=interview, template=customer-call.md`). Autonomous runs proceed without confirmation; otherwise wait for the user.

If a required `[[wikilink]]` declared in the template's header comment is unresolvable (the entity / concept / engagement page does not exist yet), file a stub at `wiki/{stub-type}/{stub-slug}.md` (frontmatter only, body is the one-line summary) before linking — never link to a page that doesn't exist (`SKILL.md` Failure modes: "Never invent backlinks").

#### 4b. Compose the page

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

**On `sources:` after auto-conversion.** When Step 2a converted the source, point `sources:` at the **original** (`../raw/{source-filename.docx}`), not the `.converted.md` cache file. The cache is a derived artefact — re-ingest can rebuild it from the original if a markitdown release improves extraction, and a pinned cache path would silently rot the citation chain.

Body structure (the template selected in Step 4a sets the per-type heading shape inside `Details`; the four top-level sections below are constant):

1. **One-sentence summary** (the line that will appear in `index.md`)
2. **Key takeaways** — bulleted, each with a `[[wikilink]]` or source citation where applicable
3. **Details** — the actual distilled content. Use the headings the template prescribes (e.g. `Interviewee / Context / Topics covered / Notable quotes / Open questions raised` for `interview.md`). Drop sections the source genuinely doesn't support — empty scaffolds are noise. Add type-specific sections only when the template invites them.
4. **Sources** — markdown-linked list of raw files and URLs

Verify the body contains every required `[[wikilink]]` listed in the template's header comment before writing. A template-required link that points at a non-existent page is the trigger to file a stub per Step 4a — write the stub first, then write this page.

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

The audit enforces the wiki's SCHEMA `R1_bidirectional_wikilink` rule (forward `[[B]]` from A ⇒ reverse `[[A]]` in B). Each candidate `backlink_audit.py` returns carries a `rule_id` field — today always `R1_bidirectional_wikilink` — so the contract row in `<wiki-root>/SCHEMA.md` is auditable against the script. See `<wiki-root>/SCHEMA.md` §"Forward → reverse link contract" for the table.

Two paths — hand-curation (`auto_backlinks = null`) or auto-mode (`auto_backlinks = K`) — resolved at Step 0 and branched here. Both paths end with the same `--apply-plan -` atomic-write call, so downstream reporting (Step 9) is uniform.

#### Path A — Hand-curation (when `auto_backlinks = null`)

**6a. Audit.** Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py --wiki-root <wiki-root> --new-page {slug}`. The script returns JSON with candidate backlinks — existing pages that mention the new page's title, tags, or key entities. If the script exits non-zero or returns malformed JSON, report the error to the user and skip the backlink step — the page itself is already written.

**6b. Curate.** For each candidate, read the target page and decide whether a `[[{slug}]]` link would help the reader. Always add backlinks as natural inline references, not as dumps. For every target you pick, draft (i) a sentence containing `[[{slug}]]` and (ii) the heading line it should go under (or omit the heading to append at the end). This curation step stays human-in-the-loop — the script never auto-selects targets, to preserve the "never invent backlinks" discipline in the Failure modes section.

#### Path B — Auto-mode (when `auto_backlinks = K` is an integer)

**6a'. Compact audit.** Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py --wiki-root <wiki-root> --new-page {slug} --top K --min-confidence medium`. This returns the top-K candidates already pre-filtered to `confidence ∈ {medium, high}` plus summary counters (`total_candidates`, `by_confidence`) so the orchestrator can log the shape without reading a full candidate dump. If the script exits non-zero or returns malformed JSON, report the error and skip the backlink step.

**6b'. Bulk-draft sentences.** For each returned candidate, read **only** the target page's title + first paragraph (do not read the full body — that defeats the point of auto-mode) and write one short sentence containing `[[{slug}]]` that would read naturally in that context. No heading is required — auto-mode always appends at the end of the target body so the draft does not collide with an existing heading you haven't read.

The "never invent backlinks" discipline is preserved by two mechanisms: (i) `--min-confidence medium` drops the keyword-noise bucket at audit time; (ii) K is bounded by the explicit `--auto-backlinks K` cap. The sentence itself is drafted by you from the target's title + first paragraph, keeping it anchored to real page content rather than pattern-matched phrasing. The tradeoff is explicit: auto-mode replaces "hand-curated-with-7-ideal-backlinks" with "auto-applied-with-up-to-K-decent-backlinks" — useful for bulk rebuilds where the user explicitly opts in via `--auto-backlinks K`, not the default for any mode.

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

- `mode: fresh` — invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/config_bump.py --wiki-root <wiki-root> --key entries_count --delta 1`. The script grabs the shared `.cogni-wiki/.lock` before read-modify-write — defence-in-depth for users who run two `wiki-ingest` invocations against the same wiki from separate sessions (the original concurrency hazard fixed by issue #84 in v0.0.12). Never edit `config.json` inline — the inline read-modify-write race produced silent under-counts before v0.0.12 and the lock contract is the established way to keep `entries_count` correct.
- `mode: re-ingest` — leave `entries_count` untouched. The field reflects distinct knowledge pages across the per-type directories, not ingest invocations; `wiki-resume`, `wiki-dashboard`, and `wiki-lint` all treat it as a page count, so re-ingests must not inflate it.

If `config_bump.py` exits non-zero or returns malformed JSON, report the error but do not abort — the page, index, backlinks, and log are already consistent on disk. The script is idempotent-safe to re-run with a compensating `--delta` to reconcile drift.

### 8.5. Rebuild `wiki/context_brief.md` (v0.0.29+)

Run **once per dispatch**, after the per-source loop has completed (single-source mode: after Step 8 of the only source; batch / discovery mode: after the last entry's Step 8 has committed). The brief is the canonical "first read" for a fresh Claude Code session — it summarises the wiki's current shape (type counts, top entities by inbound backlinks, last 30 days of activity, cached open lints, fresh `health.py` snapshot) in ≤ 8 KiB so a new session can orient without opening `index.md`, every per-type page directory, and `log.md`.

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/rebuild_context_brief.py --wiki-root <wiki-root>
```

The script is read-only against pages, runs `health.py` once internally, and atomically replaces `wiki/context_brief.md` via `tempfile + os.replace` (through `_wikilib.atomic_write`). No lock is needed — the brief has a single writer, and reads are snapshot-only. A hard 8000-byte cap is enforced; if the assembled body exceeds it, the script truncates the "recent activity" section first (constant-bounded sections like type counts, top entities, lints, and health are never truncated).

**Failure isolation.** A non-zero exit or malformed JSON from `rebuild_context_brief.py` MUST NOT roll back the ingest. The page write, index update, backlinks, log line, and `entries_count` bump from Steps 4–8 are already on disk. Surface the error to the user as part of the Step 9 report and continue — the brief is a derived artefact that the next ingest will rebuild.

**Out of scope, deliberately.** The "Open lints" section reads `.cogni-wiki/last_lint.json` if present and ≤ 24 h old; otherwise it renders an inline "not yet cached" note. This step does not invoke `lint_wiki.py` — keeping the ingest path token-free is the entire point of the brief. The lint-cache writer hook (so a `wiki-lint` run populates `last_lint.json`) is a deliberate follow-up; until it lands, the lints section degrades gracefully and the rest of the brief is unaffected.

### 9. Report to the user

**Single-source mode.** Tell the user, in ≤5 sentences:
- The new page slug and path
- How many existing pages got backlinks
- Whether the context brief was rebuilt cleanly (one line: "context_brief.md: {bytes}B" or the failure mode)
- What to do next (usually: drop another source or run `wiki-query`)

**Batch mode.** Emit one aggregated block instead of a per-source report. For every entry that reached this step, print the slug, its resolved mode (`fresh` or `re-ingest`), and its backlink count. Report `entries_count` delta (fresh sources only; re-ingests never increment) and the Step 8.5 brief-rebuild result. On a fail-fast halt, also list the source that failed with its error and any sources that were skipped. See `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` §"Step 9 in batch mode" for the exact format.

## Output

- One new file under the matching `wiki/{type}/` directory
- `wiki/index.md` updated
- N existing pages (across the per-type dirs under `wiki/`) edited with new backlinks (where N ≥ 0)
- One appended line in `wiki/log.md`
- Updated `config.json`
- `wiki/context_brief.md` rebuilt once per dispatch (≤ 8 KiB; deterministic; never blocks the ingest on failure) — v0.0.29+
- Optionally, one `<source>.converted.md` cache file in `raw/` next to a non-markdown source (Step 2a). Re-used on idempotent re-ingest; safe to delete to force re-conversion.

## Failure modes and rules

- **Never summarise from memory.** The page's claims must all trace back to the source text. If the source is silent on a topic, the page is silent on it.
- **Never invent backlinks.** Only link to pages that actually exist under one of the per-type page dirs.
- **Never overwrite a page silently.** Overwrites are only allowed through the explicit re-ingest path: Step 1 must detect the existing slug, set `mode: re-ingest`, and emit the re-ingest warning before any page write. Silent overwrites (writing to an existing slug without surfacing `mode: re-ingest` to the user) remain forbidden. For content-only edits that preserve the existing synthesis, use `wiki-update` rather than a re-ingest.
- **Raw first, page second.** Pasted content is persisted to `raw/` before any page work begins.
- **Original source is the citation, not the cache.** When Step 2a writes a `.converted.md`, frontmatter `sources:` still points at the original. The cache is a derived artefact — re-ingest may rebuild it; nothing in the wiki should depend on its path.
- **Brief failures never roll back the ingest.** Step 8.5 is fail-soft by contract — the rest of the dispatch is committed before it runs.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/page-frontmatter.md` — full frontmatter schema, type enum, type→template map
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/templates/` — body scaffolds per type (`default`, `interview`, `customer-call`, `meeting`, `decision`, `retro`, `learning`); see `templates/README.md` for selection rules
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/ingest-workflow.md` — worked example, including a `.docx` ingest end-to-end (Step 2a auto-conversion)
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` — `--batch-file` input schema, per-source mode rules, error policy, and worked example
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py` — candidate backlink finder
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/wiki_index_update.py` — deterministic `wiki/index.md` insert/update helper
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/batch_builder.py` — discovery helper; enumerates candidates for `--discover` and emits the batch-mode payload on stdout
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/convert_to_md.py` — multi-format auto-conversion helper used by Step 2a (`.docx`, `.pptx`, `.xlsx`, `.html`, `.epub`, …); stdlib-first with optional `markitdown` shell-out
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/rebuild_context_brief.py` — Step 8.5: writes `wiki/context_brief.md` (≤ 8 KiB; auto-rebuilt once per dispatch as of v0.0.29)
