# cogni-wiki

> **Incubating** (v0.0.3) — skills, data formats, and workflows may change at any time.

**A better RAG for personal and small-team knowledge work.** Instead of re-discovering the same information every query through embedding similarity, cogni-wiki has Claude compile sources once into a persistent, interlinked markdown wiki — no vector store, no chunking heuristics, no opaque retrieval. Knowledge compounds with every ingest; answers trace to readable markdown files, not vector math. Plain files, plain backlinks, plain Unix tools.

Based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) and the reference implementation by [kfchou/wiki-skills](https://github.com/kfchou/wiki-skills).

## Why this exists

RAG promised to give LLMs access to your private knowledge. In practice, every query re-discovers the same ground — embeddings silently miss semantic matches, synthesis happens from scratch each time, and nothing compounds across sessions. You pay a "synthesis tax" on every question, and when an answer is wrong, tracing which chunks were retrieved and why requires reverse-engineering opaque vector math.

Karpathy's insight: what if knowledge was **compiled once at ingestion** instead of **retrieved per query**? The LLM reads your sources, writes structured summaries, cross-references them, flags contradictions — and then every future query reads pre-synthesized articles directly. The wiki gets denser with each ingest. RAG stays flat.

| Problem | RAG | cogni-wiki |
|---------|-----|------------|
| Summarising a new source | On-the-fly each query | Compiled once, filed forever |
| Cross-references | Vector similarity (ephemeral, can miss) | Explicit `[[wikilinks]]` (audited) |
| Contradictions between sources | Hidden in retrieval noise | Surfaced by `wiki-lint` at ingest |
| Stale claims | Still retrievable, silently | Flagged and reconciled |
| Debugging wrong answers | Reverse-engineer vector math | Read the markdown file |
| Token efficiency | 2K–5K chunks re-retrieved per query | Pre-synthesized; up to 95% reduction vs full-doc loading |
| Compounding over time | No — same effort per query | Yes — wiki gets denser each ingest |

**Where RAG still wins:** Scale beyond ~50K–100K tokens of compiled content; rapidly changing data (daily feeds, inventory); strict source-level attribution for legal/compliance; multi-domain enterprise with role-based access. For those cases, use RAG — or combine both (the hybrid approach [never lost a single round](references/claude-research-karparthy.md) in head-to-head benchmarks).

## What it is

**IS:** A compile-time knowledge engine based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). Where other insight-wave plugins *generate* knowledge artifacts (research reports, trend analyses, portfolio propositions), cogni-wiki *preserves* them — compiling sources into interlinked markdown pages that Claude reads directly instead of re-deriving from scratch. Seven skills cover the full lifecycle: setup, ingest, query, lint, update, resume, and dashboard.

## Data model

**Wiki layout** (created by `wiki-setup`):

```
<wiki-root>/
├── SCHEMA.md                 The contract — conventions, frontmatter, linking rules
├── raw/                      Your immutable source documents
├── assets/                   Attachments
├── wiki/
│   ├── index.md              One-line summary of every page
│   ├── log.md                Append-only operation log
│   ├── overview.md           Evolving synthesis
│   └── pages/                Flat, slug-named markdown pages
└── .cogni-wiki/config.json   Plugin metadata
```

**Page frontmatter** (YAML):

```yaml
---
id: constitutional-ai
title: Constitutional AI
type: concept
tags: [llms, safety, karpathy]
created: 2026-04-12
updated: 2026-04-12
sources: [../raw/bai-et-al-2022.pdf]
---
```

## What it does

1. **Bootstrap** a new wiki with directory layout, SCHEMA.md contract, and seed files → `.cogni-wiki/config.json` + `wiki/index.md` + `wiki/log.md` + `wiki/overview.md` → wiki-ingest, wiki-query, wiki-lint, wiki-update, wiki-resume, wiki-dashboard
2. **Ingest** source documents into structured wiki pages with YAML frontmatter, backlink audit, and index updates → `wiki/pages/*.md` → wiki-query, wiki-lint, wiki-update, wiki-dashboard
3. **Query** the wiki to answer questions — reads pages directly, never from model memory, with `[[wikilink]]` citations → `wiki/pages/*.md` → wiki-query, wiki-lint, wiki-update, wiki-dashboard
4. **Lint** the wiki for health problems — broken wikilinks, orphan pages, stale dates, frontmatter gaps, contradictions → `wiki/pages/lint-*.md` → wiki-update, wiki-query
5. **Update** existing pages with diff-before-write discipline, source citation requirements, and stale-sweep of related pages → `wiki/pages/*.md` → wiki-query, wiki-lint, wiki-dashboard
6. **Resume** with status, activity summary, and recommended next action
7. **Dashboard** as a self-contained HTML overview — pages by type, tag cloud, backlink graph, and activity histograms → `wiki-dashboard.html` (self-contained HTML dashboard)

## What it means for you

- **Compound your knowledge, not your effort.** Each ingest aims to leave the wiki denser and more interconnected than before — up to 95% token reduction vs re-loading full documents per query, with every source compiled once rather than re-synthesized on demand.
- **Ground every answer in curated sources.** `wiki-query` reads the wiki before answering — never from model memory. If the wiki has no page on a topic, the answer says so rather than filling the gap with hallucinated filler.
- **Keep your knowledge portable across any tool, indefinitely.** `SCHEMA.md` ships inside every wiki directory, so the wiki aims to remain fully readable even if cogni-wiki is uninstalled or replaced — plain markdown, plain backlinks, zero lock-in. Open it in Obsidian, VS Code, or `grep` today; hand it off in 5 years.
- **Keep every wiki page trustworthy.** `wiki-update` shows the diff before modifying any page and requires a source citation for every new claim — zero silent writes across all 7 skills, so the wiki stays citable.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

> **Note**: Wikis are created under `cogni-wiki/{slug}/` in your current workspace by default, following the standard cogni-plugin convention. Use `--wiki-root` to override the location.

## Quick start

```
/cogni-wiki:wiki-setup                    # Bootstrap a new wiki
# (drop a paper in cogni-wiki/primary/raw/)
/cogni-wiki:wiki-ingest                   # Summarise + cross-link
/cogni-wiki:wiki-query "what did I learn about X?"
/cogni-wiki:wiki-lint                     # After every 5–10 ingests
/cogni-wiki:wiki-update --page <slug>     # Revise a page with new evidence
/cogni-wiki:wiki-dashboard                # Visual HTML overview
/cogni-wiki:wiki-resume                   # "Where was I?"
```

Or just describe what you want in natural language:

- "Set up a wiki for my AI safety research"
- "Ingest this paper into the wiki"
- "What does my wiki say about constitutional AI?"
- "Is my wiki healthy?"
- "Show me the wiki as a dashboard"

## Relationship to Claude Code auto-memory

Claude Code already has an auto-memory system at `~/.claude/projects/.../memory/` — that layer is **Claude's learning about you** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **your learning about your domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Components

| Component | Type | Description |
|-----------|------|-------------|
| wiki-setup | Skill | Bootstrap a new Karpathy-style LLM wiki at a user-chosen directory |
| wiki-ingest | Skill | Ingest a source document into the wiki with summary, frontmatter, and backlink audit |
| wiki-query | Skill | Answer a question by reading the wiki — never from memory |
| wiki-lint | Skill | Audit the wiki for broken wikilinks, orphan pages, stale dates, and contradictions |
| wiki-update | Skill | Revise an existing wiki page with diff-before-write discipline and source citations |
| wiki-resume | Skill | Show status, activity, and recommended next action for the wiki |
| wiki-dashboard | Skill | Generate a self-contained HTML dashboard with tag cloud, backlink graph, and histograms |

## Architecture

```
cogni-wiki/
├── .claude-plugin/plugin.json       Plugin manifest
├── README.md                        Plugin documentation
├── CLAUDE.md                        Developer guide
├── LICENSE                          AGPL-3.0
├── references/                      Shared reference material
│   ├── karpathy-pattern.md          Karpathy LLM Wiki pattern
│   └── claude-research-karparthy.md RAG vs wiki benchmark research
└── skills/                          7 wiki skills
    ├── wiki-setup/                  Bootstrap a new wiki
    ├── wiki-ingest/                 Ingest sources into wiki pages
    ├── wiki-query/                  Answer questions from wiki content
    ├── wiki-lint/                   Health audit with severity tiers
    ├── wiki-update/                 Diff-gated page revisions
    ├── wiki-resume/                 Status and next-action dashboard
    └── wiki-dashboard/              Self-contained HTML overview
```

## Dependencies

cogni-wiki is standalone — no required or optional cross-plugin dependencies in v0.0.x. Integration contracts with cogni-research, cogni-narrative, cogni-consulting, and cogni-claims are planned for v0.1.x; see [CLAUDE.md](CLAUDE.md) "Future Integration Points".

## Credits

- **Andrej Karpathy** — [LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The pattern this plugin implements.
- **kfchou/wiki-skills** — [reference Claude Code implementation](https://github.com/kfchou/wiki-skills). The five-skill shape (`wiki-init`, `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-update`) that inspired this plugin's layout. cogni-wiki adds `wiki-resume` and `wiki-dashboard` to match cogni-* ecosystem conventions.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
