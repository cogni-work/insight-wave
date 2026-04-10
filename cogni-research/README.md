# cogni-research

Multi-agent research report generator for [Claude Cowork](https://claude.ai/cowork). STORM-inspired editorial workflow with parallel section research and claims-verified review loops. Five report types (basic, detailed, deep, outline, resource) and three source modes (web, local documents, hybrid) — from quick overviews to deep recursive explorations.

## Why this exists

LLMs can research and write — but the reports they produce have real problems that undermine trust and usefulness:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Unverified citations | Reports cite sources confidently, but 14–95% of LLM citations are hallucinated ([GhostCite, 2025](https://arxiv.org/html/2602.06718)) | Readers trust claims that sources don't actually support |
| Shallow outputs | Most AI research tools produce single-pass summaries from a handful of searches | Surface-level analysis that misses nuance and depth |
| No traceability | Generated reports have no audit trail from claim to source | Impossible to verify or update findings later |
| Manual effort | Deep, multi-source research reports still take days of desk research | Outdated by the time they ship |
| No quality gates | Reports go from draft to final with no systematic review | Errors, gaps, and unsupported conclusions slip through |

This plugin automates the research-heavy parts — parallel web search, source aggregation, claims verification, iterative review — while keeping strategic judgment where it belongs: with you.

## What it is

A STORM-inspired editorial research pipeline for the insight-wave ecosystem. Parallel web research agents decompose topics and gather evidence; a source curator ranks quality and diversity; a writer compiles the draft with inline citations; a structural reviewer gates quality before acceptance. Five report types — basic, detailed, deep, outline, and resource — match research intensity to the question. Upstream of cogni-narrative (narrative composition) and cogni-visual (visual enrichment); downstream of cogni-claims for source-level verification of every factual assertion.

## What it does

1. **Decompose** your topic into orthogonal sub-questions grounded by preliminary web search
2. **Research** in parallel — one agent per sub-question, searching the web and extracting findings
3. **Aggregate** sources across all sub-questions, deduplicate, and enforce quality thresholds
4. **Write** a structured report with inline citations linking every claim to its source → `research-report.md` optionally enriched into themed HTML with interactive charts and diagrams via `cogni-visual:enrich-report`, then polished by `cogni-claims` claim verification and `cogni-copywriting` copywriter
5. **Review** structurally — automated quality gate checks completeness, coherence, depth, and clarity
6. **Verify** (separate step via `verify-report`) — extract claims and check each against its source URL via cogni-claims in a dedicated context window

## What it means for you

If you produce research, analysis, or any content that needs to be both sourced and correct, this is your end-to-end pipeline.

- **Ship reports in minutes, not hours.** Basic reports dispatch 5–7 agents concurrently; deep reports run 15–25. Research that would take hours completes in minutes.
- **Verify every factual claim against its source URL.** Every claim is extracted, matched to its source URL, and checked for deviations — misquotation, unsupported conclusions, selective omission.
- **Deliver reports as themed, interactive HTML.** Reports finish with data visualizations — not just markdown. Optional PDF and DOCX export included.
- **Resume interrupted runs from the last completed phase.** Interrupted runs pick up from the first incomplete phase. No lost work.
- **Trace every finding back to a source.** Every finding links to a source, every claim links to a verification result. The full workspace is Obsidian-browsable.
- **Match research intensity to the question.** Quick overview (basic), multi-section report (detailed), recursive tree exploration (deep), structured framework (outline), or annotated bibliography (resource) — matched to your needs.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- Web access enabled (for research)
- bash, python3 (stdlib only — no pip dependencies)
- **cogni-claims** plugin (recommended — enables claims-verified review loop)
- Optional: **cogni-narrative** (story arc polish), **cogni-copywriting** (executive polish), **cogni-visual** (presentation generation)

## Quick start

Describe what you want in natural language — no slash commands needed. Claude detects the request and loads the skill automatically:

- "Write a research report on quantum computing's impact on cryptography"
- "Write a detailed research report on AI adoption in healthcare"
- "Deep research on the future of autonomous vehicles"
- "Resume the research on autonomous vehicles"
- "Verify the report" (after research completes — runs `verify-report` in a fresh context)

## Try it

After installing, type one prompt:

> Research the state of AI regulation in the EU

Claude decomposes the topic, dispatches parallel web researchers, compiles a sourced report, and runs a structural review. Then run `/verify-report` to extract and verify every factual claim against its cited source — you'll see which claims check out and which don't, and the review loop will revise until quality standards are met.

Results land in your project directory:

```
cogni-research-<slug>/
├── 00-sub-questions/data/       Decomposed research questions
├── 01-contexts/data/            Per-question research findings
├── 02-sources/data/             Deduplicated source registry
├── 03-report-claims/data/       Extracted claims with verification status
├── output/
│   ├── draft-v1.md              First draft
│   ├── draft-v2.md              Post-review revision (if needed)
│   └── report.md                Final accepted report
└── .metadata/
    ├── execution-log.json       Phase state for resumability
    └── review-verdicts/         Reviewer decisions per iteration
```

## Data model

Four entity types with Dublin Core metadata, wikilink cross-references, and ISO 8601 timestamps:

| Entity | Storage | Key Fields |
|--------|---------|------------|
| `SubQuestion` | `00-sub-questions/data/sq-*.md` | query, parent_topic, section_index, status (pending → researched / failed) |
| `Context` | `01-contexts/data/ctx-*.md` | sub_question_ref, source_refs[], key_findings[], search_queries_used[] |
| `Source` | `02-sources/data/src-*.md` | url, title, fetch_method, content_hash, cited_by[] |
| `ReportClaim` | `03-report-claims/data/rc-*.md` | statement, source_ref, verification_status, deviation_type |

All entities are markdown with YAML frontmatter — Obsidian-browsable with wikilink graph navigation. See [references/data-model.md](references/data-model.md) for the full schema.

## Report types

| Type | Sub-questions | Agents | Words | Use case |
|------|--------------|--------|-------|----------|
| Basic | 5 | 7–9 | 3,000–5,000 | Quick overview, single topic |
| Detailed | 5–10 | 10–15 | 5,000–10,000 | Multi-section report with outline |
| Deep | 10–20 (tree) | 15–25 | 8,000–15,000 | Recursive exploration, maximum depth |
| Outline | 5 | 5–7 | 1,000–2,000 | Structured framework only, no prose |
| Resource | 5 | 5–7 | 1,500–3,000 | Annotated bibliography / reading list |

## How it works

The pipeline uses two skills that split the work across separate context windows:

**research-report** orchestrates six phases. Phase 0 initializes the project workspace and runs preliminary web searches to ground the research. Phase 1 decomposes the topic into orthogonal sub-questions with search guidance for each. Phase 2 dispatches **section-researcher** agents (sonnet) in batches of 4–5 — each agent runs 5–7 web searches, fetches top results, curates sources with quality scores, and creates context + source entities. For deep reports, **deep-researcher** agents (sonnet) perform recursive tree exploration instead. Phase 3 aggregates all contexts, deduplicates sources, and enforces a 25,000-word context limit. Phase 4 hands the aggregated context to the **writer** agent (sonnet), which produces a structured draft with inline citations. Phase 5 runs a structural-only review (completeness, coherence, source diversity, depth, clarity). Phase 6 copies the accepted draft to `output/report.md`.

**verify-report** then runs in a fresh context window — loading only the draft and source entities, not the research data. It extracts 10–30 verifiable claims from the draft, submits them to cogni-claims for source URL verification, presents results to the user, and runs up to 3 review-revision iterations to fix any factual deviations found. This architectural split ensures claims verification gets full context attention.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `research-report` | skill | Generate a multi-agent research report using parallel web research with structural review |
| `verify-report` | skill | Verify claims in a research report against cited sources using cogni-claims |
| `section-researcher` | agent (sonnet) | Parallel web researcher for a single sub-question or report section |
| `local-researcher` | agent (sonnet) | Parallel document analyst for a single sub-question from local files (PDF, DOCX, TXT, MD, CSV) |
| `deep-researcher` | agent (sonnet) | Recursive tree explorer for deep research mode |
| `source-curator` | agent (sonnet) | Ranks, filters, and annotates research sources by quality, relevance, and diversity |
| `writer` | agent (sonnet) | Compiles aggregated research context and source entities into a cohesive, well-structured report |
| `claim-extractor` | agent (sonnet) | Extracts verifiable claims from a report draft for downstream verification via cogni-claims |
| `reviewer` | agent (sonnet) | Evaluates report drafts against structural review criteria and claims verification data |
| `revisor` | agent (sonnet) | Incorporates reviewer feedback and claims deviation data into a revised draft |
| `block-entity-writes` | hook (PreToolUse) | Blocks Write/Edit to entity directories — forces entity creation via scripts for consistency |
| `review-loop-guard` | hook (PostToolUse) | Enforces max 3 review iterations — signals forced acceptance when limit is reached |

## Architecture

```
cogni-research/
├── .claude-plugin/               Plugin manifest
├── skills/                       2 orchestration skills
│   ├── research-report/
│   │   ├── SKILL.md
│   │   └── references/           Report types, sub-questions, review criteria, agent roles
│   ├── research-report-workspace/ Dev workspace (evals, iterations — not a skill)
│   └── verify-report/
│       ├── SKILL.md
│       └── references/           Claims integration, standalone mode, review criteria
├── agents/                       8 research agents
│   ├── section-researcher.md
│   ├── local-researcher.md
│   ├── deep-researcher.md
│   ├── source-curator.md
│   ├── writer.md
│   ├── claim-extractor.md
│   ├── reviewer.md
│   └── revisor.md
├── hooks/                        2 guardrail hooks
│   ├── hooks.json
│   ├── block-entity-writes.sh
│   └── review-loop-guard.sh
├── evals/                        Evaluation test cases
│   └── evals.json
├── schemas/                      4 entity JSON schemas
├── scripts/                      Entity creation and project utilities
└── references/                   Model strategy and shared documentation
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-claims | No | Claims verification loop in `verify-report` — extracts and checks claims against source URLs |
| cogni-visual | No | Visual enrichment and format export via `enrich-report` — themed HTML with charts, optional PDF/DOCX |
| cogni-workspace | No | Theme selection for visual exports (indirect — consumed via cogni-visual:enrich-report) |
| cogni-narrative | No | Downstream — user invokes `/narrative` on research output for arc-driven executive summary |
| cogni-copywriting | No | Downstream — user invokes copywriter on narrative output for arc-aware executive polish |

## Attribution

This plugin is an **independent reimplementation** — no source code from the original projects is used.

- **GPT-Researcher** by [Assaf Elovic / Tavily](https://github.com/assafelovic/gpt-researcher) (Apache-2.0) — multi-agent research architecture that inspired this plugin's parallel research and iterative review design.
- **STORM** by [Stanford OVAL](https://arxiv.org/abs/2402.14207) — perspective-driven article generation framework. GPT-Researcher's editorial workflow builds on STORM's multi-perspective synthesis approach.

## Contributing

Contributions welcome — report types, research strategies, citation formats, and documentation. See the [insight-wave contribution guide](https://github.com/cogni-work/insight-wave/blob/main/CONTRIBUTING.md) for guidelines.

## Custom development

Need custom research workflows, internal knowledge base integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
