---
name: wiki-setup
description: "Bootstrap a new Karpathy-style LLM wiki at a user-chosen directory — creates the raw/, wiki/, assets/, and .cogni-wiki/ layout, seeds SCHEMA.md/index.md/log.md/overview.md, and registers the wiki in plugin configuration. Use this skill whenever the user says 'set up a wiki', 'initialize a wiki', 'create a new wiki', 'bootstrap my knowledge base', 'start a Karpathy wiki', 'wiki init', 'wiki setup', 'new wiki for <topic>', or drops into an empty directory and asks Claude to begin a compounding knowledge base. Also trigger the first time any other wiki-* skill is invoked in a directory that doesn't yet contain a .cogni-wiki/config.json — offer to run setup first."
allowed-tools: Read, Write, Edit, Bash, Glob, AskUserQuestion
---

# Wiki Setup

Bootstrap a fresh LLM wiki at a directory the user chooses. After this skill runs the directory is self-describing: future invocations of any `wiki-*` skill can detect the wiki by the presence of `.cogni-wiki/config.json` and operate on it without further configuration.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once before proceeding — it defines the three-layer model (raw sources / wiki / schema) that every decision below depends on.

## When to run

- User explicitly asks to create, initialize, set up, bootstrap, or start a wiki
- Another `wiki-*` skill is invoked in a directory that has no `.cogni-wiki/config.json` — offer to run setup first, then hand control back
- User wants a second wiki for a different domain (each wiki is a separate directory)

## Never run when

- The target directory already contains `.cogni-wiki/config.json` — report the existing wiki instead and ask if the user wants to operate on it
- The target directory contains non-empty `raw/` or `wiki/` dirs from a different knowledge system — stop and ask rather than overwriting

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--wiki-root` | No | Absolute or relative path to the wiki directory. Defaults to `cogni-wiki/{slug}` relative to the current working directory, where `{slug}` is derived from the wiki name. Use this to place a wiki outside the standard workspace layout. |
| `--name` | Yes (prompted) | Human-readable wiki name, e.g. `"Primary Knowledge Base"` or `"AI-Safety Research Wiki"`. Used for the slug and for `.cogni-wiki/config.json`. |
| `--description` | No | One-sentence description of the wiki's scope and purpose. Seeded into `overview.md`. |
| `--publisher-base-url` | No | Canonical landing URL for the publisher this wiki represents, e.g. `https://www.smarter-service.com/studien/`. Recorded in `.cogni-wiki/config.json` as `publisher_base_url`. Used by downstream readers (notably cogni-research wiki-researcher) as a last-resort fallback URL when a page was ingested from a local file and has no per-page `publisher_url`. Leave unset for general-purpose wikis that span many publishers. |

If parameters are missing, ask the user once with AskUserQuestion. Do not invent a wiki name silently.

## Workflow

### 1. Resolve the wiki root

1. If `--wiki-root` was passed, use it as-is (absolute or relative).
2. Otherwise, compute `cogni-wiki/{slug}` relative to the current working directory, where `slug = kebab-case(name)`. This follows the standard cogni-plugin convention (`cogni-{plugin}/{project-slug}/`).
3. If the resolved path already exists and contains `.cogni-wiki/config.json`, stop — this wiki is already set up. Report the path and exit.
4. If the path exists but is not a wiki, ask the user whether to proceed inside it before creating files.

### 2. Create the directory layout

Create (with `mkdir -p`):

```
<wiki-root>/
├── raw/
├── assets/
├── wiki/
│   └── pages/
└── .cogni-wiki/
```

### 3. Seed the top-level files

Copy `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/references/SCHEMA.md.template` to `<wiki-root>/SCHEMA.md`, replacing `{{wiki_name}}` and `{{created_date}}` placeholders.

Write `wiki/index.md`:

```markdown
# Index

This is the content catalog for **{{wiki_name}}**. Every wiki page is listed here with a one-line summary. Claude consults this file before drilling into specific pages.

## Categories

_No pages yet. Run `wiki-ingest` to add your first source._
```

Write `wiki/log.md`:

```markdown
# Log

Append-only record of every wiki operation. Never rewritten.

## [{{created_date}}] setup | wiki initialized
```

Write `wiki/overview.md`:

```markdown
# Overview

**{{wiki_name}}** — {{description or "an evolving knowledge base"}}

This page is the high-level synthesis of what the wiki has learned. It is rewritten periodically by `wiki-update` as understanding shifts. On day one it contains only this placeholder.
```

### 4. Write the config file

Write `<wiki-root>/.cogni-wiki/config.json` with JSON:

```json
{
  "name": "{{wiki_name}}",
  "slug": "{{slug}}",
  "description": "{{description}}",
  "created": "{{YYYY-MM-DD}}",
  "entries_count": 0,
  "last_lint": null,
  "schema_version": "0.0.2",
  "publisher_base_url": "{{publisher_base_url_or_empty}}"
}
```

Use the current date via `date +%Y-%m-%d`. Omit `publisher_base_url` (do not emit the key at all) when `--publisher-base-url` was not provided — an empty string is acceptable but a missing key reads more cleanly in single-publisher wikis where the field is unused. Bump `schema_version` to `"0.0.2"` to mark the addition of `publisher_base_url`; earlier `"0.0.1"` configs remain valid (the field is optional on read).

### 5. Confirm to the user

Report in plain prose:
- Where the wiki was created (absolute path)
- Next recommended action — usually `drop a source document in raw/ and run /cogni-wiki:wiki-ingest`
- Gentle reminder that Claude will never answer `wiki-query` calls from memory — only from the wiki

Do not create example pages or sample sources. An empty wiki is the correct starting state.

## Output

The wiki directory, populated as above. No file is created anywhere else in the user's environment.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/directory-layout.md` — detailed field-by-field layout
- `./references/SCHEMA.md.template` — the file copied into every new wiki
