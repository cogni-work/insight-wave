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
│   ├── concepts/
│   ├── entities/
│   ├── summaries/
│   ├── decisions/
│   ├── interviews/
│   ├── meetings/
│   ├── learnings/
│   ├── syntheses/
│   ├── notes/
│   └── audits/
└── .cogni-wiki/
```

The nine type directories mirror the `type:` frontmatter enum (concept,
entity, summary, decision, interview, meeting, learning, synthesis, note).
`audits/` holds the `lint-YYYY-MM-DD.md` and `health-YYYY-MM-DD.md` reports
that are exempt from the forward→reverse link contract (SCHEMA.md R3). Each
type dir is created empty; `wiki-ingest` writes new pages directly into the
matching dir based on the page's `type:`.

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
  "schema_version": "0.0.5",
  "publisher_base_url": "{{publisher_base_url_or_empty}}"
}
```

Use the current date via `date +%Y-%m-%d`. Omit `publisher_base_url` (do not emit the key at all) when `--publisher-base-url` was not provided — an empty string is acceptable but a missing key reads more cleanly in single-publisher wikis where the field is unused. `schema_version` `"0.0.5"` marks the per-type-page-directory layout (v0.0.28+); `"0.0.4"` (which added the `synthesis` and `health` log prefixes plus the `R3_audit_report` exemption broadening), `"0.0.3"` (which added the SCHEMA "Forward → reverse link contract" table), `"0.0.2"` (which added `publisher_base_url`), and `"0.0.1"` configs are read by the migrator but every other skill hard-fails on `< 0.0.5` until migration runs.

### 5. Migrate an existing wiki (schema_version < 0.0.5)

cogni-wiki v0.0.28 promoted page types from a `type:` frontmatter field into per-type subdirectories (`wiki/concepts/`, `wiki/decisions/`, …). Existing wikis still on the flat `wiki/pages/<slug>.md` layout are surfaced by `wiki-resume`'s `schema_migration_pending: true` field; every other `wiki-*` skill hard-fails with the migration nudge until the layout is upgraded.

Run the migrator once per wiki:

```
python ${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/scripts/migrate_layout.py \
    --wiki-root <wiki-root> --apply
```

The migrator is locked, idempotent, and fails fast on missing/invalid frontmatter `type:` values. Default invocation without `--apply` is a dry-run that lists the planned moves. After a successful run:

- Pages live under `wiki/<type>/<slug>.md` (per-type dirs).
- `lint-YYYY-MM-DD.md` and `health-YYYY-MM-DD.md` audit reports live under `wiki/audits/`.
- `.cogni-wiki/config.json::schema_version` is bumped to `"0.0.5"` via `config_bump.py --set-string` (locked).
- A summary log line `## [YYYY-MM-DD] migrate | moved N pages to per-type dirs` is appended to `wiki/log.md`.
- The empty `wiki/pages/` shell is removed if no junk remains.

For wikis at `schema_version < 0.0.4`, the `SCHEMA.md` body inside the wiki is also missing one or both pre-v0.0.4 sections — apply the missing pieces by reading the differences against `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/references/SCHEMA.md.template`, then re-run the migrator (which only bumps `schema_version` once it sees `< 0.0.5`):

- **`< 0.0.3`:** append the `## Forward → reverse link contract` section between the existing `## Linking` and `## Log format` sections.
- **`< 0.0.4`:** in the `## Log format` block, broaden the operation enum to `{ingest|query|synthesis|lint|health|update|setup|migrate}`. In the forward→reverse contract table, rename row `R3_lint_report` to `R3_audit_report` and broaden its exemption text to cover both `[[lint-YYYY-MM-DD]]` and `[[health-YYYY-MM-DD]]` filenames.
- **`< 0.0.5`:** update the directory-layout block to show the per-type directories (concepts/, entities/, summaries/, decisions/, interviews/, meetings/, learnings/, syntheses/, notes/, audits/) in place of the single `wiki/pages/` line.

The SCHEMA.md edits are idempotent and offline-safe. `wiki-lint`'s deterministic checks work whether or not the SCHEMA sections match the in-plugin template — the edits only ensure the contract is auditable when reading the wiki on its own.

### 6. Confirm to the user

Report in plain prose:
- Where the wiki was created (absolute path)
- Next recommended action — usually `drop a source document in raw/ and run /cogni-wiki:wiki-ingest`
- Available body templates so the user knows which `--type` values trigger a domain-specific scaffold. Source of truth: `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/templates/`. Surface as a single short list:
  - `default` — generic source ingest (`--type summary | concept | entity`)
  - `interview` — captured conversation (`--type interview`)
  - `customer-call` — sales / customer-success variant (`--type interview --tags customer-call`)
  - `meeting` — meeting notes (`--type meeting`)
  - `decision` — ADR-shaped record (`--type decision`)
  - `retro` — retrospective variant (`--type learning --tags retro`)
  - `learning` — generalised lesson (`--type learning`)

  Point the user at `references/templates/README.md` for the per-template required `[[wikilinks]]` and authoring conventions when they want to dig deeper.
- Gentle reminder that Claude will never answer `wiki-query` calls from memory — only from the wiki

Do not create example pages or sample sources. An empty wiki is the correct starting state.

## Output

The wiki directory, populated as above. No file is created anywhere else in the user's environment.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/directory-layout.md` — detailed field-by-field layout
- `./references/SCHEMA.md.template` — the file copied into every new wiki
