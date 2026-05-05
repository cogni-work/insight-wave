# cogni-wiki

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop recommended)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

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
| Compounding over time | No — same effort per query | Yes — wiki gets denser each ingest, and queries themselves can be filed back as `type: synthesis` pages |

**Where RAG still wins:** Scale beyond ~50K–100K tokens of compiled content; rapidly changing data (daily feeds, inventory); strict source-level attribution for legal/compliance; multi-domain enterprise with role-based access. For those cases, use RAG — or combine both (the hybrid approach [never lost a single round](references/claude-research-karparthy.md) in head-to-head benchmarks).

## What it is

**IS:** A compile-time knowledge engine based on [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). Where other insight-wave plugins *generate* knowledge artifacts (research reports, trend analyses, portfolio propositions), cogni-wiki *preserves* them — compiling sources into interlinked markdown pages that Claude reads directly instead of re-deriving from scratch. Eleven skills cover the full lifecycle: setup, ingest, query, health, lint, update, resume, dashboard, plus three integration skills (cold-start from research, refresh stale pages, re-verify cited URLs).

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

Page types: `concept`, `entity`, `summary`, `decision`, `interview`, `meeting`, `learning`, `synthesis`, `note`. The `synthesis` type (v0.0.23) is reserved for LLM-derived answers that `wiki-query --file-back yes` files back into the wiki; sources for these pages are `wiki://<slug>` references rather than raw files. The `interview` and `meeting` types (v0.0.24) drive `wiki-ingest`'s body-template dispatch — `customer-call` and `retro` are tag variants of `interview` and `learning`, not new types.

## What it does

1. **Bootstrap** a new wiki with directory layout, SCHEMA.md contract, and seed files → `.cogni-wiki/config.json` + `wiki/index.md` + `wiki/log.md` + `wiki/overview.md` → wiki-ingest, wiki-query, wiki-health, wiki-lint, wiki-update, wiki-resume, wiki-dashboard
2. **Ingest** source documents into structured wiki pages with YAML frontmatter, backlink audit, and index updates → `wiki/pages/*.md` → wiki-query, wiki-health, wiki-lint, wiki-update, wiki-dashboard
3. **Query** the wiki to answer questions — reads pages directly, never from model memory, with `[[wikilink]]` citations; optionally files the answer back as a `type: synthesis` page (introduced in v0.0.23) so explorations compound rather than evaporating into chat history → `wiki/pages/*.md` → wiki-query, wiki-health, wiki-lint, wiki-update, wiki-dashboard
4. **Health-check** structural integrity in seconds — broken wikilinks, missing frontmatter, broken raw/`wiki://` sources, id mismatches, invalid types, stub pages, `entries_count` drift between config and filesystem, index/filesystem drift; zero LLM calls; runs automatically every session via `wiki-resume` (introduced in v0.0.27)  → prose summary + `## [YYYY-MM-DD] health | ...` log line
5. **Lint** the wiki with a tokenful semantic pass — contradictions, type drift, undercited claims, missing concept pages, plus the deterministic warnings that need narrative (orphans, stale dates, tag typos, reverse-link gaps, claim-drift severity from the latest re-verify sweep). Calls `wiki-health` first as a free preflight; refuses to run while structural errors are pending  → `wiki/pages/lint-*.md` → wiki-update, wiki-query, wiki-claims-resweep
6. **Update** existing pages with diff-before-write discipline, source citation requirements, and stale-sweep of related pages → `wiki/pages/*.md` → wiki-query, wiki-health, wiki-lint, wiki-dashboard
7. **Resume** with status, activity summary, health snapshot, and recommended next action; runs `wiki-health` automatically and surfaces structural-integrity counts before any other recommendation (v0.0.27)
8. **Dashboard** as a self-contained HTML overview — pages by type (incl. synthesis), tag cloud, backlink graph, and activity histograms → `wiki-dashboard.html` (self-contained HTML dashboard)
9. **Cold-start from research** — chains `cogni-research:research-setup` → `research-report` → `wiki-setup` → `wiki-ingest --discover research:<slug>` in one dispatch (Mode A from a topic, Mode B from an existing research slug) → populated wiki seeded with sub-question-sized pages → wiki-query, wiki-health, wiki-lint, wiki-refresh
10. **Refresh stale pages from research** — matches lint-flagged stale pages to sub-questions of an existing cogni-research project via Jaccard token overlap, materialises one synthesis per match, and dispatches wiki-update sequentially → updated `wiki/pages/*.md` with bumped `updated:` and refreshed sources → wiki-query, wiki-lint
11. **Re-verify wiki citations** — extracts inline-cited statements from existing pages deterministically, dispatches them through cogni-claims for source re-verification, and writes a sweep report plus a lint-bridge JSON; report-only, never mutates `wiki/pages/` → `<wiki-root>/raw/claims-resweep-<date>/report.md` + `.cogni-wiki/last-resweep.json` → wiki-health (claim_drift count), wiki-lint (`claim_drift` warning), wiki-update (manual stale-marker)

## What it means for you

- **Compound your knowledge, not your effort.** Each ingest aims to leave the wiki denser and more interconnected than before — up to 95% token reduction vs re-loading full documents per query, with every source compiled once rather than re-synthesized on demand. As of v0.0.23, **queries themselves compound** too: `wiki-query --file-back yes` files the answer as a `type: synthesis` page that future queries read directly.
- **Catch broken structure for free, every session.** As of v0.0.27, `wiki-resume` runs a zero-LLM `wiki-health` preflight on every status call — broken wikilinks, missing frontmatter, broken sources, id mismatches, and `entries_count` drift surface immediately, with no token cost. The tokenful semantic `wiki-lint` pass refuses to run while structural errors are pending, so you never burn lint tokens reasoning about a broken graph.
- **Ground every answer in curated sources.** `wiki-query` reads the wiki before answering — never from model memory. If the wiki has no page on a topic, the answer says so rather than filling the gap with hallucinated filler.
- **Keep your knowledge portable across any tool, indefinitely.** `SCHEMA.md` ships inside every wiki directory, so the wiki aims to remain fully readable even if cogni-wiki is uninstalled or replaced — plain markdown, plain backlinks, zero lock-in. Open it in Obsidian, VS Code, or `grep` today; hand it off in 5 years.
- **Keep every wiki page trustworthy.** `wiki-update` shows the diff before modifying any page and requires a source citation for every new claim — zero silent writes across all eleven skills, so the wiki stays citable. Synthesis pages additionally cite `wiki://` provenance, validated by `wiki-health` (existence) and `wiki-lint` (file-back discipline).

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note**: Wikis are created under `cogni-wiki/{slug}/` in your current workspace by default, following the standard cogni-plugin convention. Use `--wiki-root` to override the location.

## Quick start

```
/cogni-wiki:wiki-setup                                         # Bootstrap a new wiki
# (drop a paper in cogni-wiki/primary/raw/)
/cogni-wiki:wiki-ingest                                        # Summarise + cross-link
/cogni-wiki:wiki-query "what did I learn about X?" --file-back yes  # Answer + file as type: synthesis
/cogni-wiki:wiki-health                                        # Free zero-LLM structural preflight (also auto-run by wiki-resume)
/cogni-wiki:wiki-lint                                          # Tokenful semantic pass after every 5–10 ingests
/cogni-wiki:wiki-update --page <slug>                          # Revise a page with new evidence
/cogni-wiki:wiki-dashboard                                     # Visual HTML overview (incl. synthesis bucket)
/cogni-wiki:wiki-resume                                        # "Where was I?" (with health snapshot + synthesis_count_30d)
/cogni-wiki:wiki-from-research                                 # Cold-start: research → wiki in one dispatch
/cogni-wiki:wiki-refresh --from-research <slug>                # Refresh stale pages from a research project
/cogni-wiki:wiki-claims-resweep                                # Re-verify cited URLs against current source content
```

Or just describe what you want in natural language:

- "Set up a wiki for my AI safety research"
- "Ingest this paper into the wiki"
- "What does my wiki say about constitutional AI? Save the answer as a synthesis."
- "Is my wiki broken?" (→ wiki-health, free)
- "Audit my wiki for contradictions" (→ wiki-lint, tokenful)
- "Show me the wiki as a dashboard"
- "Cold-start a wiki from research on agent economy"
- "Refresh stale pages from the new agent-economy research"
- "Re-verify wiki citations against current sources"

## Relationship to Claude Code auto-memory

Claude Code already has an auto-memory system at `~/.claude/projects/.../memory/` — that layer is **Claude's learning about you** (feedback, preferences, session-spanning patterns). cogni-wiki is the complementary primitive: **your learning about your domain** — explicitly curated, portable across projects, queryable. No duplication; different intent.

## Components

| Component | Type | Description |
|-----------|------|-------------|
| wiki-setup | Skill | Bootstrap a new Karpathy-style LLM wiki at a user-chosen directory |
| wiki-ingest | Skill | Ingest a source document into the wiki with summary, frontmatter, and backlink audit |
| wiki-query | Skill | Answer a question by reading the wiki — never from memory; optionally files the answer back as a `type: synthesis` page |
| wiki-health | Skill | Zero-LLM structural integrity preflight — broken wikilinks, missing frontmatter, broken raw/`wiki://` sources, id mismatch, invalid type, stub pages, `entries_count` drift, index/filesystem drift, claim_drift count. Runs automatically every session via wiki-resume (v0.0.27) |
| wiki-lint | Skill | Tokenful semantic audit — contradictions, type drift, undercited claims, missing concept pages, plus deterministic warnings that need narrative (orphans, stale, tag typos, reverse links, claim_drift severity). Refuses to run while wiki-health reports errors |
| wiki-update | Skill | Revise an existing wiki page with diff-before-write discipline and source citations |
| wiki-resume | Skill | Show status, activity (incl. synthesis count + health snapshot), and recommended next action for the wiki |
| wiki-dashboard | Skill | Generate a self-contained HTML dashboard with tag cloud, backlink graph, type bars (incl. synthesis), and histograms |
| wiki-from-research | Skill | Cold-start orchestrator: chains cogni-research's setup + report into wiki-setup + wiki-ingest in one dispatch (Mode A from a topic, Mode B from an existing research slug) |
| wiki-refresh | Skill | Refresh stale wiki pages with fresh evidence from a completed cogni-research project; Jaccard match, batch-confirmed, sequential wiki-update dispatch |
| wiki-claims-resweep | Skill | Re-verify inline-cited URLs in existing wiki pages against current source content via cogni-claims; report-only, writes a sweep report and a lint-bridge JSON |

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
└── skills/                          11 wiki skills
    ├── wiki-setup/                  Bootstrap a new wiki
    ├── wiki-ingest/                 Ingest sources into wiki pages
    ├── wiki-query/                  Answer questions from wiki content; file back as type: synthesis
    ├── wiki-health/                 Zero-LLM structural preflight (broken links, frontmatter, sources, drift)
    ├── wiki-lint/                   Tokenful semantic audit (contradictions, type drift, undercited, missing concepts) + deterministic narrative warnings
    ├── wiki-update/                 Diff-gated page revisions
    ├── wiki-resume/                 Status and next-action dashboard (auto-runs wiki-health)
    ├── wiki-dashboard/              Self-contained HTML overview
    ├── wiki-from-research/          Cold-start: research → wiki orchestrator
    ├── wiki-refresh/                Stale-page refresh from a research project
    └── wiki-claims-resweep/         Re-verify inline-cited URLs against current source content
```

## Dependencies

cogni-wiki runs standalone for the core ingest/query/health/lint/update loop. Three skills opt into cross-plugin integrations:

| Skill | Depends on | Used for |
|-------|-----------|----------|
| `wiki-from-research`, `wiki-refresh`, `wiki-ingest --discover research:<slug>` | `cogni-research` | Cold-start a wiki, refresh stale pages, or deposit a completed research project as sub-question-sized pages |
| `wiki-claims-resweep` | `cogni-claims` | Re-verify inline-cited URLs against current source content (`submit` + `verify` modes) |
| `wiki-lint` (`claim_drift` warning), `wiki-health` (`claim_drift_count`) | none — read `.cogni-wiki/last-resweep.json` written by `wiki-claims-resweep` | Surface drift findings as warnings during regular health/lint audits |

Integrations with `cogni-narrative` and `cogni-consulting` remain planned for v0.1.x; see [CLAUDE.md](CLAUDE.md) "Cross-Plugin Integration" and "Future Integration Points".

## Optional dependencies

cogni-wiki is stdlib-only by default. One skill step lights up additional capabilities when an optional CLI is present; absence is never a hard error for the formats stdlib already covers.

| Tool | Skill / step | What it enables | Install |
|---|---|---|---|
| `markitdown` | `wiki-ingest` Step 2a (`scripts/convert_to_md.py`) | Auto-conversion of binary office formats (`.docx`, `.pptx`, `.xlsx`, `.epub`) and richer extraction for `.html` / `.txt` / `.csv` / `.json` / `.ipynb` so consulting sources (interviews, decks, financial models) ingest without manual pre-conversion | `pip install markitdown` (or `pipx install markitdown` for a sandboxed install) |

When `markitdown` is not installed, `wiki-ingest` still handles `.md`, `.pdf` (via the Read tool's `pages` parameter), `.html` (stdlib `html.parser` fallback), `.txt` (verbatim), URL ingest (via WebFetch), and pasted text. Binary office formats short-circuit with a clear error pointing back at this section, so the failure mode is never silent half-extraction. See `skills/wiki-ingest/SKILL.md` §2a for the full backend table and the `--no-convert` opt-out.

## Credits

- **Andrej Karpathy** — [LLM Wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). The pattern this plugin implements.
- **kfchou/wiki-skills** — [reference Claude Code implementation](https://github.com/kfchou/wiki-skills). The five-skill shape (`wiki-init`, `wiki-ingest`, `wiki-query`, `wiki-lint`, `wiki-update`) that inspired this plugin's layout. cogni-wiki adds `wiki-health`, `wiki-resume`, `wiki-dashboard`, `wiki-from-research`, `wiki-refresh`, and `wiki-claims-resweep` to match cogni-* ecosystem conventions and to close the structural-preflight, research → wiki, and citation re-verify loops.
- **sdh07/llm-wiki-agent** and **sdh07/omegawiki** — reference implementations of the Karpathy pattern that informed the v0.0.23 / v0.0.27 audits (see tracking issue #212): the synthesis page type, `wiki://` source convention, the `health` vs `lint` boundary, and the structural-integrity-as-pre-flight discipline all draw on patterns these projects pioneered.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
