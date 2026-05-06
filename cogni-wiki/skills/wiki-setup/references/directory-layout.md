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
| `<wiki-root>/wiki/concepts/*.md` | Pages with `type: concept` — ideas, frameworks, models | `wiki-ingest` (create), `wiki-update` (revise) |
| `<wiki-root>/wiki/entities/*.md` | Pages with `type: entity` — people, orgs, products, places | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/summaries/*.md` | Pages with `type: summary` — condensed raw sources | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/decisions/*.md` | Pages with `type: decision` — choices and reasoning | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/interviews/*.md` | Pages with `type: interview` — captured conversations (incl. tag:customer-call) | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/meetings/*.md` | Pages with `type: meeting` — meeting notes | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/learnings/*.md` | Pages with `type: learning` — generalised takeaways (incl. tag:retro) | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/syntheses/*.md` | Pages with `type: synthesis` — filed-back query answers | `wiki-query --file-back` |
| `<wiki-root>/wiki/notes/*.md` | Pages with `type: note` — loose observations | `wiki-ingest`, `wiki-update` |
| `<wiki-root>/wiki/audits/*.md` | Audit reports — `lint-YYYY-MM-DD.md` and `health-YYYY-MM-DD.md` (R3-exempt from forward→reverse links) | `wiki-lint` (writes `lint-*.md`); `wiki-health` log line only today |
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
  "schema_version": "0.0.5",
  "publisher_base_url": "https://www.smarter-service.com/studien/"
}
```

- `entries_count` is a cached count of knowledge pages across the per-type dirs (excludes `wiki/audits/`). Each `wiki-ingest` and `wiki-update` increments or recalculates it.
- `last_lint` is the ISO date of the most recent `wiki-lint` run, or `null`. `wiki-resume` uses it to surface "wiki has not been linted in N days" reminders.
- `schema_version` tracks the frontmatter and layout contract version. Migrations detect old wikis and upgrade them. `0.0.5` (v0.0.28+) promoted page types from a frontmatter field into per-type directories (`wiki/concepts/`, `wiki/decisions/`, …) plus `wiki/audits/` for R3-exempt audit reports — apply via `wiki-setup/scripts/migrate_layout.py`. `0.0.4` added the `synthesis` and `health` log prefixes plus the broadened `R3_audit_report` exemption. `0.0.3` codified the SCHEMA forward→reverse link contract. `0.0.2` added `publisher_base_url`. `0.0.1` configs remain valid on read.
- `publisher_base_url` is optional. Set it to the publisher's landing URL when every source in the wiki comes from the same publisher (e.g. an analyst firm's study catalog). **cogni-research wiki-researcher** uses it as a last-resort fallback when a cited page has no per-page `publisher_url` in its frontmatter and no `https://` URL in its `sources:` array — so citations still resolve to the publisher's site rather than landing unlinked. Leave the field unset for wikis that span multiple publishers (fabricating a shared landing page there would mislead readers).

## Slug derivation rule

`slug = kebab-case(name)` — lowercase, alphanumeric + hyphens only, spaces → hyphens, unicode → ASCII transliteration where possible. Example: `"AI-Safety Research Wiki"` → `ai-safety-research-wiki`.

## Wiki detection

A directory is a wiki if and only if `.cogni-wiki/config.json` exists. All other `wiki-*` skills use this as the detection test. The working directory is walked upward (to `$HOME`) looking for the first ancestor that is a wiki, so the user can invoke skills from inside any per-type page dir (`wiki/concepts/`, etc.) or `raw/` without having to `cd` first.

## Empty-state invariants

Immediately after `wiki-setup`:
- `raw/` — empty
- `assets/` — empty
- All ten of `wiki/{concepts,entities,summaries,decisions,interviews,meetings,learnings,syntheses,notes,audits}/` — present and empty
- `wiki/index.md` — present, contains only the "no pages yet" placeholder
- `wiki/log.md` — present, contains only the setup log line
- `wiki/overview.md` — present, contains only the placeholder
- `.cogni-wiki/config.json` — present, `entries_count: 0`, `last_lint: null`, `schema_version: "0.0.5"`
