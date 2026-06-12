# cogni-wiki

**Plugin guide** — for canonical positioning see the [cogni-wiki README](../../cogni-wiki/README.md).

---

## Overview

cogni-wiki turns source documents into a persistent, interlinked markdown wiki that Claude maintains across sessions. Instead of re-discovering the same information every query through embedding similarity (the RAG approach), cogni-wiki has Claude compile sources once at ingestion — writing structured summaries, cross-referencing related pages via `[[wikilinks]]`, and flagging contradictions. Every future query reads pre-synthesized articles directly rather than re-deriving answers from scratch.

The plugin implements [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f): knowledge compounds with every ingest, answers trace to readable markdown files, and the wiki is fully portable — plain files, plain backlinks, plain Unix tools.

---

## Key Concepts

| Term | What it means in practice |
|------|--------------------------|
| **Wiki** | A directory of interlinked markdown pages with YAML frontmatter, maintained by Claude and readable by humans |
| **Ingest** | The act of reading a source document, writing a structured wiki page from it, and weaving it into existing knowledge via backlinks |
| **`[[wikilink]]`** | A bidirectional reference between wiki pages — audited after every ingest to keep the knowledge graph connected |
| **SCHEMA.md** | The contract file shipped inside every wiki — defines conventions, frontmatter fields, and linking rules so the wiki is self-describing |
| **Compile-time knowledge** | Karpathy's core insight: synthesize once at ingest, not per query. The wiki gets denser over time instead of re-discovering the same ground |
| **Page type** | Classification of a wiki page: `concept`, `entity`, `summary`, `decision`, `interview`, `meeting`, `learning`, `synthesis`, `note`, or `source`. The directory the page lives in must match its `type:` frontmatter field |
| **Health check** | A zero-LLM structural integrity preflight (broken wikilinks, missing frontmatter, id mismatches, stub pages, layout drift) — fast enough to run every session automatically via `wiki-resume` |
| **Lint** | A tokenful semantic audit — contradictions, type drift, undercited claims, missing concept pages. Runs periodically; refuses to start while the health check reports errors |

---

## Getting Started

Bootstrap a new wiki and ingest your first source:

```
/cogni-wiki:wiki-setup
```

The setup skill asks for a wiki name (e.g., "AI Safety Research") and creates the directory layout:

```
cogni-wiki/ai-safety-research/
├── SCHEMA.md              Conventions and linking rules
├── raw/                   Drop your source documents here
├── wiki/
│   ├── index.md           One-line summary per page
│   ├── log.md             Append-only operation log
│   ├── overview.md        Evolving synthesis
│   ├── concepts/          type: concept pages
│   ├── entities/          type: entity pages
│   ├── summaries/         type: summary pages
│   ├── decisions/         type: decision pages
│   ├── interviews/        type: interview pages
│   ├── meetings/          type: meeting pages
│   ├── learnings/         type: learning pages
│   ├── syntheses/         type: synthesis pages (filed-back query answers)
│   ├── notes/             type: note pages
│   ├── sources/           type: source pages
│   └── audits/            lint and health audit reports
└── .cogni-wiki/config.json
```

Drop a PDF, article, or paper into `raw/`, then:

```
/cogni-wiki:wiki-ingest
```

Claude reads the source, writes a structured summary page with YAML frontmatter, updates the index, and runs a backlink audit to connect the new page to existing knowledge. After 5-10 ingests, run `/cogni-wiki:wiki-lint` to catch any health issues.

---

## Capabilities

### wiki-resume — Session entry point

Run `wiki-resume` at the start of every session. It automatically runs a zero-LLM `wiki-health` preflight, surfaces the structural-integrity counts (broken links, missing frontmatter, stub pages, layout drift), shows page counts by type, days since last lint, and recommends a concrete next action. If the wiki needs a schema migration, `wiki-resume` surfaces that nudge before anything else.

**Example:**
> "Where was I with my wiki?"

### wiki-setup — Bootstrap a new wiki

Run `wiki-setup` to create a fresh wiki at a directory you choose. The skill creates the full per-type directory layout (raw/, wiki/concepts/, wiki/entities/, wiki/summaries/, ..., wiki/audits/, assets/, .cogni-wiki/) and seeds the contract files — SCHEMA.md, index.md, log.md, and overview.md. After setup, the wiki is immediately ready to receive sources. Setup also prompts to prefill the consulting foundations subset via `wiki-prefill`.

**Example:**
> "Set up a wiki for my AI safety research"

### wiki-ingest — Add sources to the wiki

Run `wiki-ingest` after dropping a source document (PDF, URL, pasted text, transcript) into `raw/`. Claude reads the source, surfaces key takeaways, writes a summary page with YAML frontmatter (id, title, type, tags, sources) into the appropriate per-type subdirectory, updates `wiki/index.md`, appends to `wiki/log.md`, and runs a backlink audit to weave the new page into existing knowledge. For deferred draining, `--enqueue` / `--next` / `--queue-status` / `--queue-retry` operate a persistent file-based ingest queue.

**Example:**
> "Ingest this paper into the wiki"

### wiki-query — Ask questions from the wiki

Run `wiki-query` to ask a question that Claude answers by reading the wiki — never from model memory. The skill consults `wiki/index.md` to find relevant pages, reads them, and synthesizes an answer with `[[wikilink]]` citations. If the wiki doesn't contain the answer, Claude says so rather than hallucinating. Pass `--file-back yes` to file the answer as a `type: synthesis` page in `wiki/syntheses/` so the exploration compounds rather than evaporating into chat history.

**Example:**
> "What does my wiki say about constitutional AI? Save the answer as a synthesis."

### wiki-health — Zero-LLM structural preflight

Run `wiki-health` (or let `wiki-resume` run it automatically every session) for a free structural integrity scan: broken `[[wikilinks]]`, missing frontmatter fields, broken raw/`wiki://` sources, id mismatches, invalid page types, stub pages, `entries_count` drift between config and filesystem, index/filesystem drift, and the count of citation-drift findings from the last `wiki-claims-resweep`. Zero LLM calls — safe to run before any other work.

**Example:**
> "Is my wiki structurally sound?" (or just run `wiki-resume`)

### wiki-lint — Tokenful semantic audit

Run `wiki-lint` after every 5-10 ingests as a periodic maintenance pass. The audit checks for contradictions between pages, type drift, undercited claims, missing concept pages, and the deterministic warnings that need narrative — orphans, stale dates, tag typos, reverse-link gaps, claim-drift severity from the latest resweep. Lint calls `wiki-health` as a free preflight and refuses to run while structural errors are pending, so you never burn tokens reasoning about a broken graph. Results are written to `wiki/audits/lint-YYYY-MM-DD.md`.

**Example:**
> "Audit my wiki for contradictions"

### wiki-update — Revise existing pages

Run `wiki-update` when knowledge has changed and a page needs correction. The skill shows you the planned diff before writing (diff-before-write discipline), requires a source citation for every new claim, and sweeps related pages for now-stale statements that the update contradicts.

**Example:**
> "Update the constitutional-ai page with findings from this new paper"

### wiki-dashboard — Visual HTML overview

Run `wiki-dashboard` to generate a self-contained HTML file with pages by type (including synthesis), a tag cloud, a backlink graph, recent activity, and size/age histograms. The file has no external CDN calls — safe to open offline or share with collaborators. Add `--graph yes` for the two-pass interactive graph view.

**Example:**
> "Show me the wiki as a dashboard"

### wiki-from-research — Cold-start from a research project

Run `wiki-from-research` to bootstrap a new wiki directly from a cogni-research project in one dispatch. Mode A (`--topic`) starts fresh — it chains `cogni-research:research-setup` → `research-report` → `wiki-setup` → `wiki-ingest --discover research:<slug>`. Mode B (`--research-slug`) starts from an existing research project and skips straight to setup and ingest. Pre-flight detects wiki-target collisions before any research budget is spent.

**Example:**
> "Cold-start a wiki from research on agent economy"

### wiki-refresh — Refresh stale pages from research

Run `wiki-refresh --from-research <slug>` to pull fresh evidence from a completed cogni-research project into stale wiki pages. The skill calls `lint_wiki.py` to enumerate `stale_page` (>365 days) and `stale_draft` (>180 days) findings, uses Jaccard token overlap to match each stale page to the most relevant research sub-question, prints the batch plan for one user confirmation, then dispatches `wiki-update` sequentially per matched page.

**Example:**
> "Refresh stale pages from the agent-economy research"

### wiki-claims-resweep — Re-verify cited URLs

Run `wiki-claims-resweep` to check whether the sources cited in existing wiki pages still support the claims made. The skill walks every per-type page directory, extracts inline-cited statements deterministically, dispatches them through `cogni-claims` for re-verification, and writes a sweep report to `raw/claims-resweep-<date>/report.md` plus a lint-bridge JSON at `.cogni-wiki/last-resweep.json`. Report-only: it never modifies wiki pages directly. Stale-marker decisions go through `wiki-update` manually after reviewing the report.

**Example:**
> "Re-verify wiki citations against current sources"

### wiki-prefill — Seed foundation concept pages

Run `wiki-prefill` to seed `wiki/concepts/` with curated `foundation: true` concept pages — Porter's Five Forces, Jobs-to-be-Done, MECE, Pyramid Principle, OODA Loop, SWOT, BCG Matrix, Value Chain, Lean Canvas, Wardley Mapping, Double Diamond. The skill is idempotent and locked; existing foundation pages are never overwritten. Pass `--filter consulting|product|strategy|all` to select a subset, `--list` to preview, or `--dry-run` to plan without writing.

**Example:**
> "Seed my wiki with consulting framework foundations"

---

## Integration Points

### cogni-research (live)

Three skills connect cogni-wiki to cogni-research:

- **wiki-from-research** bootstraps a new wiki directly from a cogni-research project — either from a free-text topic (Mode A) or an existing project slug (Mode B). This is the fastest path from "I want a wiki on X" to a populated, queryable knowledge base.
- **wiki-refresh** pulls fresh research evidence into stale wiki pages. After running a new research cycle on a topic your wiki already covers, `wiki-refresh --from-research <slug>` matches the stale pages to relevant sub-questions and dispatches `wiki-update` per match.
- **wiki-ingest --discover research:\<slug\>** can also be run standalone to deposit a completed research project's sub-question findings into an existing wiki without the full cold-start orchestration.

### cogni-claims (live)

**wiki-claims-resweep** closes the citation-drift loop. It extracts inline-cited statements from every wiki page, dispatches them through cogni-claims for source re-verification, and writes a sweep report. The findings feed back into `wiki-health` (which surfaces a `claim_drift_count`) and `wiki-lint` (which surfaces `claim_drift` warnings with severity), so regular health checks give you a running signal on citation freshness without re-running the full resweep.

The reverse direction — cogni-claims propagating corrections back into wiki pages — remains deferred. Current workflow: review the resweep report, then run `wiki-update` manually on flagged pages.

### cogni-knowledge (live)

cogni-knowledge uses cogni-wiki as its substrate. When `cogni-knowledge:knowledge-ingest` processes sources, it writes `type: source` pages into `wiki/sources/`. When `cogni-knowledge:knowledge-compose` and `knowledge-finalize` run, they write `type: synthesis` pages into `wiki/syntheses/`. cogni-wiki recognizes these page types and routes them correctly; the per-type semantics (e.g., `pre_extracted_claims:` frontmatter on source pages) are owned by cogni-knowledge, not by cogni-wiki's schema.

### Planned integrations

| Plugin | Status | Integration direction |
|--------|--------|-----------------------|
| cogni-narrative | Planned (v0.1.x) | Narrative skill reads wiki pages as structured input |
| cogni-consult | Planned (v0.1.x) | Engagement knowledge (interviews, decisions, constraints) persists beyond the engagement slug |

---

## Common Workflows

### Workflow 1: Build a knowledge base from a paper collection

**Goal:** Compile 10-20 papers on a topic into a queryable, cross-referenced wiki.

**Steps:**
1. Run `/cogni-wiki:wiki-setup` — name the wiki after your research domain
2. Drop all papers into `raw/`
3. Run `/cogni-wiki:wiki-ingest` for each paper — Claude summarizes, cross-links, and indexes
4. After every 5-10 ingests, run `/cogni-wiki:wiki-lint` to catch orphan pages and contradictions
5. Query freely: "What are the main approaches to constitutional AI?" — answers come from the wiki, not model memory

**Result:** A dense, interlinked knowledge base where every answer traces to a readable markdown file.

### Workflow 2: Maintain a living knowledge base across sessions

**Goal:** Keep a wiki growing over weeks or months as you encounter new sources.

**Steps:**
1. Start each session with `/cogni-wiki:wiki-resume` to see status and recommended next action
2. Drop new sources into `raw/` and ingest them
3. When a page is outdated, run `/cogni-wiki:wiki-update --page <slug>` — review the diff, cite the new source
4. Periodically run `/cogni-wiki:wiki-dashboard` for a visual overview of growth and connectivity

**Result:** A knowledge base that compounds over time — each session leaves it denser than before.

### Workflow 3: Quick-reference lookup during other work

**Goal:** Use your wiki as a reference while working in another plugin.

**Steps:**
1. While working in cogni-research, cogni-consult, or any other context, ask a question naturally: "What does my wiki say about X?"
2. wiki-query reads the wiki, synthesizes an answer with `[[wikilink]]` citations
3. If the wiki is silent on the topic, Claude says so — you know the gap exists

**Result:** Grounded answers from your own compiled knowledge, not from model training data.

---

## Data Model

Wiki pages are plain markdown with YAML frontmatter:

```yaml
---
id: constitutional-ai
title: Constitutional AI
type: concept
tags: [llms, safety, alignment]
created: 2026-04-12
updated: 2026-04-12
sources: [../raw/bai-et-al-2022.pdf]
---

Constitutional AI (CAI) is a method for training AI systems to be
helpful, harmless, and honest using a set of principles...

## Related
- [[rlhf]] — CAI builds on RLHF but replaces human feedback with...
- [[ai-safety-overview]] — broader context for alignment approaches
```

This page lives at `wiki/concepts/constitutional-ai.md` because its `type:` is `concept`. The `type:` frontmatter field must match the directory — `wiki-health`'s `type_directory_mismatch` check catches any drift.

**Page types and their directories:**

| type | directory | notes |
|------|-----------|-------|
| `concept` | `wiki/concepts/` | Framework definitions, foundational ideas |
| `entity` | `wiki/entities/` | Named actors, organizations, products |
| `summary` | `wiki/summaries/` | Source document summaries |
| `decision` | `wiki/decisions/` | Recorded decisions with rationale |
| `interview` | `wiki/interviews/` | Customer calls, expert interviews |
| `meeting` | `wiki/meetings/` | Meeting notes |
| `learning` | `wiki/learnings/` | Retrospectives and lessons learned |
| `synthesis` | `wiki/syntheses/` | LLM-derived answers filed back by `wiki-query --file-back yes`; cite `wiki://` provenance |
| `note` | `wiki/notes/` | Unstructured notes |
| `source` | `wiki/sources/` | Raw source bodies written by cogni-knowledge |

Audit reports (`lint-YYYY-MM-DD.md`, `health-YYYY-MM-DD.md`) live in `wiki/audits/`.

`[[wikilinks]]` use slugs only — no path component — so they work regardless of which directory a page lives in. Slugs must be globally unique across all page types.

The wiki's metadata lives in `.cogni-wiki/config.json`:

```json
{
  "name": "AI Safety Research",
  "slug": "ai-safety-research",
  "created": "2026-04-12",
  "entries_count": 23,
  "last_lint": "2026-04-12",
  "schema_version": "0.0.6"
}
```

---

## Relationship to Claude Code Auto-Memory

Claude Code has its own memory system at `~/.claude/projects/.../memory/` — that layer is Claude's learning about *you* (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: *your* learning about *your domain* — explicitly curated, portable across projects, queryable. Different intent, no duplication.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| "No wiki found" when running any wiki skill | No `.cogni-wiki/config.json` in the current directory or its parents | Run `/cogni-wiki:wiki-setup` first, or `cd` into the wiki directory |
| wiki-query answers from model memory instead of the wiki | The query didn't match any index entries | Check `wiki/index.md` for coverage gaps; ingest more sources on the topic |
| Broken `[[wikilinks]]` reported by lint | A page was renamed or deleted without updating references | Run `/cogni-wiki:wiki-update` on the pages that contain the broken links |
| wiki-ingest creates a page but no backlinks appear | The new page's topic doesn't overlap with existing pages | This is expected for the first few ingests — backlink density grows as the wiki gets denser |
| Dashboard HTML won't open | Browser blocking local file access | Open the HTML file directly from Finder/Explorer, or serve it with `python3 -m http.server` |

---

## Extending This Plugin

cogni-wiki is open-source under AGPL-3.0. The most useful contribution areas are:

- **New page types** — the current taxonomy covers concept, entity, summary, decision, learning, and note. Domain-specific types (e.g., `experiment`, `protocol`, `glossary-entry`) would help specialized wikis.
- **Cross-plugin integration** — cogni-research and cogni-claims integrations are live (`wiki-from-research`, `wiki-refresh`, `wiki-claims-resweep`). The next open frontier is the cogni-narrative and cogni-consult directions (planned for v0.1.x) — contributions that surface wiki pages as structured narrative input or persist consulting engagement knowledge are high-value.
- **Lint rules** — new health checks (e.g., detecting circular wikilink chains, flagging pages with no sources, or checking citation freshness) expand the quality audit.

See [CONTRIBUTING.md](../../cogni-wiki/CONTRIBUTING.md) for guidelines and the [plugin development guide](../contributing/plugin-development.md) for the plugin standard.
