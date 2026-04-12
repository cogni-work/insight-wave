# cogni-wiki

Compile-time knowledge engine for personal and small-team knowledge work — a better-RAG alternative where Claude maintains a persistent, interlinked markdown wiki across sessions. Based on Karpathy's LLM Wiki pattern.

## Plugin Architecture

```
skills/                         7 wiki skills
  wiki-setup/                     Bootstrap a new wiki at a user-chosen root
    references/
      SCHEMA.md.template          Copied into the wiki at setup time
      directory-layout.md         raw/, wiki/pages/, assets/, .cogni-wiki/
  wiki-ingest/                    Add sources → summary page → backlink audit → log
    scripts/
      backlink_audit.py           Scans pages/, proposes bidirectional [[links]]
    references/
      page-frontmatter.md         YAML schema (id, title, tags, type, sources, ...)
      ingest-workflow.md          Step-by-step ingest behavior
  wiki-query/                     Ask questions; answer from wiki, never from memory
    references/
      query-patterns.md           Read-before-answer, citation discipline
  wiki-lint/                      Severity-tiered health audit
    scripts/
      lint_wiki.py                Orphans, broken links, stale dates, frontmatter check
    references/
      severity-tiers.md           Error / warn / info classification
  wiki-update/                    Diff-gated page revisions with stale-sweep
    references/
      update-discipline.md        Citation-required, diff-before-write rules
  wiki-resume/                    Status dashboard — entry count, last-lint age, next action
    scripts/
      wiki_status.sh              Emits {success, data, error} JSON
  wiki-dashboard/                 Self-contained HTML overview (pages, tags, backlink graph)
    scripts/
      render_dashboard.py         Reads wiki/ → writes wiki-dashboard.html (stdlib only)

references/
  karpathy-pattern.md             Shared Karpathy-pattern reference, cited by all skills
```

## Component Inventory

| Type | Count | Items |
|------|-------|-------|
| Skills | 7 | wiki-setup, wiki-ingest, wiki-query, wiki-lint, wiki-update, wiki-resume, wiki-dashboard |
| Agents | 0 | — (skills are self-contained in MVP) |
| Commands | 0 | — (skills serve as slash commands per plugin-dev guidance) |
| Hooks | 0 | — (all bookkeeping lives inside skills) |
| Scripts | 4 | backlink_audit.py, lint_wiki.py, wiki_status.sh, render_dashboard.py |

## Wiki Data Layout (outside the plugin)

Created by `wiki-setup` at the user-chosen root (default `~/cogni-wikis/{slug}/`):

```
<wiki-root>/
├── SCHEMA.md                  Conventions + active wiki metadata
├── raw/                       Immutable source documents (user drops files here)
├── assets/                    Images, PDFs, attachments
├── wiki/
│   ├── index.md               LLM-maintained catalog, one-line summary per page
│   ├── log.md                 Append-only operation log
│   ├── overview.md            Evolving synthesis / "state of the wiki"
│   └── pages/                 Flat, slug-named markdown with YAML frontmatter
└── .cogni-wiki/
    └── config.json            { "name", "slug", "created", "entries_count", "last_lint" }
```

## Page Frontmatter

```yaml
---
id: <slug>
title: <human-readable>
type: concept | entity | summary | decision | learning | note
tags: [tag1, tag2]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: [../raw/paper-xyz.pdf, https://...]
---
```

## Key Conventions

- **Wiki is LLM-maintained, human-curated sources.** The user drops documents in `raw/`; Claude does all the summarising, linking, and bookkeeping.
- **Always read the wiki for queries — never answer from memory.** Skills enforce this discipline in every SKILL.md.
- **Append-only log.** Every ingest, query, lint, and update writes a line to `wiki/log.md` with an ISO date prefix.
- **Bidirectional links.** `[[wikilinks]]` are audited after every ingest; related pages get backlink updates.
- **Diff before write.** `wiki-update` shows the planned change before modifying a page and requires a source citation for any new claim.
- **Stdlib-only scripts.** bash 3.2 + python3 stdlib, no pip or npm dependencies. JSON output format `{success, data, error}`.
- **No hooks.** All index/log maintenance lives inside the skills for debuggability.

## Distinction from Auto-Memory

insight-wave already uses Claude Code's auto-memory system at `~/.claude/projects/.../memory/` for **Claude's learning about the user** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **the user's learning about their domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Future Integration Points

Deferred to post-MVP, documented here so the contract stays visible:

- **cogni-research → cogni-wiki** — research reports deposit verified findings as wiki pages
- **cogni-narrative ← cogni-wiki** — narrative skill reads wiki pages as structured input
- **cogni-consulting → cogni-wiki** — engagement knowledge (interviews, decisions, constraints) persists beyond the engagement slug
- **cogni-claims ↔ cogni-wiki** — wiki claim extraction and verification via cogni-claims

## Pipeline Position

```
raw sources (user-curated) ──→ cogni-wiki (LLM-maintained pages) ──→ downstream plugins
```

Standalone in v0.0.x. Integration contracts land in v0.1.x.
