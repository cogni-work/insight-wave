---
name: wiki-ingest
description: "Ingest a source document (file, URL, pasted text, transcript, paper, article) into a Karpathy-style wiki — Claude reads the source, surfaces key takeaways, writes a summary page with YAML frontmatter, updates wiki/index.md, appends to wiki/log.md, and runs a backlink audit to weave the new page into existing knowledge. Use this skill whenever the user says 'ingest this', 'add this to my wiki', 'summarise this paper into the wiki', 'file this source', 'wiki ingest', 'wiki add', drops a document and asks Claude to process it, or pastes content with a request to save it as a wiki page. Also trigger when the user moves a new file into raw/ and asks 'what should I do with this?' — offer to ingest it."
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
- The source is already summarised in `wiki/pages/` — detect by `grep -l` for the source path or URL in frontmatter; offer `wiki-update` instead

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--source` | Yes | Path to a file in `raw/`, a URL, or the literal string `--stdin` when the user pasted content |
| `--title` | No | Override the page title; otherwise derive from the source (first heading, URL title, filename) |
| `--type` | No | Page type: `concept | entity | summary | decision | learning | note`. Defaults to `summary` for full-source ingests, `note` for short pastes |
| `--tags` | No | Comma-separated tags |

## Workflow

### 1. Locate the wiki

Walk upward from the current working directory to find the nearest `.cogni-wiki/config.json`. If none found, stop and offer to run `wiki-setup`.

### 2. Read the source

- **File in `raw/`**: Read it directly. For PDFs, extract text with the Read tool's pages parameter.
- **URL**: Fetch via WebFetch, then write a local copy under `raw/` with a slug-named filename so the source is preserved even if the URL rots.
- **Pasted text**: Write the paste to `raw/paste-{YYYYMMDD-HHMMSS}.md` first, then proceed as a file ingest. Never ingest pasted content without persisting the raw.

Mandatory: every wiki page cites a file in `raw/` or a stable URL. No exceptions.

### 3. Surface key takeaways BEFORE writing the page

This is the most important step. Do not skip. Before writing any page, state in plain prose:

1. **What the source is** — type, author, date, length
2. **Three to seven key takeaways** — the claims a future reader of the wiki would actually want
3. **Which existing wiki pages this source touches** — run `grep` / Glob over `wiki/pages/` for entity names, concept slugs, and tags that appear in the source
4. **Proposed page type and title**

Show this synthesis to the user before proceeding to write. For autonomous runs (when the user said "just ingest it"), still emit the synthesis in the response — but proceed to step 4 without waiting.

### 4. Write the new page

Path: `<wiki-root>/wiki/pages/{slug}.md` where `slug` is derived from the title.

Frontmatter (see `./references/page-frontmatter.md` for the full schema):

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

Read `wiki/index.md`. Decide which category heading the new page belongs under (create a new `##` heading if needed). Insert the line:

```
- [[{slug}]] — {one-sentence summary}
```

Keep the category list alphabetized within its section.

### 6. Run the backlink audit

Invoke `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/backlink_audit.py --wiki-root <wiki-root> --new-page {slug}`. The script returns JSON with candidate backlinks — existing pages that mention the new page's title, tags, or key entities.

For each candidate, read the target page, decide whether a `[[{slug}]]` link would help the reader, and if so add it in an appropriate sentence (not as a dangling "See also" unless the page already has a See-also section). Always add backlinks as natural inline references, not as dumps.

Edit each page that gains a backlink, updating its `updated:` frontmatter field to today.

### 7. Append to `wiki/log.md`

Append a single line:

```
## [{YYYY-MM-DD}] ingest | {slug} — {title}
```

Never rewrite existing log lines.

### 8. Update `.cogni-wiki/config.json`

Increment `entries_count`. Leave all other fields untouched.

### 9. Report to the user

Tell the user, in ≤5 sentences:
- The new page slug and path
- How many existing pages got backlinks
- What to do next (usually: drop another source or run `wiki-query`)

## Output

- One new file in `wiki/pages/`
- `wiki/index.md` updated
- N existing pages in `wiki/pages/` edited with new backlinks (where N ≥ 0)
- One appended line in `wiki/log.md`
- Updated `config.json`

## Failure modes and rules

- **Never summarise from memory.** The page's claims must all trace back to the source text. If the source is silent on a topic, the page is silent on it.
- **Never invent backlinks.** Only link to pages that actually exist in `wiki/pages/`.
- **Never overwrite a page silently.** If `{slug}.md` already exists, stop and offer `wiki-update` instead.
- **Raw first, page second.** Pasted content is persisted to `raw/` before any page work begins.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/page-frontmatter.md` — full frontmatter schema
- `./references/ingest-workflow.md` — worked example
- `./scripts/backlink_audit.py` — candidate backlink finder
