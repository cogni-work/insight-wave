# Directory Layout — Field Reference

Detailed semantics for every file and directory created by `wiki-setup`. Skills consult this file when they need to locate a specific artifact without re-parsing `SCHEMA.md`.

## Top-level paths

| Path | Purpose | Who writes it |
|------|---------|---------------|
| `<wiki-root>/SCHEMA.md` | Contract copied from `wiki-setup/references/SCHEMA.md.template` | `wiki-setup` (once), `wiki-update` (rare schema revisions) |
| `<wiki-root>/raw/` | Immutable source documents — user-curated | **user only** — Claude never writes here |
| `<wiki-root>/assets/` | Images, PDFs, exported charts referenced from pages | user or `wiki-ingest` when saving pasted images |
| `<wiki-root>/wiki/index.md` | Catalog of all pages with one-line summaries | `wiki-ingest`, `wiki-update`, `wiki-lint` |
| `<wiki-root>/wiki/log.md` | Append-only operation log | every `wiki-*` skill — one line per invocation |
| `<wiki-root>/wiki/overview.md` | Evolving synthesis of what the wiki has learned | `wiki-update` (primarily) |
| `<wiki-root>/wiki/pages/*.md` | Individual wiki pages, slug-named, flat | `wiki-ingest` (create), `wiki-update` (revise), `wiki-lint` (writes `lint-YYYY-MM-DD.md`) |
| `<wiki-root>/.cogni-wiki/config.json` | Plugin-managed metadata | `wiki-setup` (create), every other skill (update counts) |

## `.cogni-wiki/config.json` schema

```json
{
  "name": "Primary Knowledge Base",
  "slug": "primary-knowledge-base",
  "description": "Personal compounding wiki for AI safety research",
  "created": "2026-04-12",
  "entries_count": 0,
  "last_lint": null,
  "schema_version": "0.0.1"
}
```

- `entries_count` is a cached count of files in `wiki/pages/` excluding `lint-*.md`. Each `wiki-ingest` and `wiki-update` increments or recalculates it.
- `last_lint` is the ISO date of the most recent `wiki-lint` run, or `null`. `wiki-resume` uses it to surface "wiki has not been linted in N days" reminders.
- `schema_version` tracks the frontmatter and layout contract version. Future migrations can detect old wikis and upgrade them.

## Slug derivation rule

`slug = kebab-case(name)` — lowercase, alphanumeric + hyphens only, spaces → hyphens, unicode → ASCII transliteration where possible. Example: `"AI-Safety Research Wiki"` → `ai-safety-research-wiki`.

## Wiki detection

A directory is a wiki if and only if `.cogni-wiki/config.json` exists. All other `wiki-*` skills use this as the detection test. The working directory is walked upward (to `$HOME`) looking for the first ancestor that is a wiki, so the user can invoke skills from inside `wiki/pages/` or `raw/` without having to `cd` first.

## Empty-state invariants

Immediately after `wiki-setup`:
- `raw/` — empty
- `assets/` — empty
- `wiki/pages/` — empty
- `wiki/index.md` — present, contains only the "no pages yet" placeholder
- `wiki/log.md` — present, contains only the setup log line
- `wiki/overview.md` — present, contains only the placeholder
- `.cogni-wiki/config.json` — present, `entries_count: 0`, `last_lint: null`
