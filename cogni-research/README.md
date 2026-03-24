# cogni-research

Multi-agent research report generator for [Claude Cowork](https://claude.ai/cowork). Native re-implementation of GPT-Researcher's STORM-inspired editorial workflow using Claude Code plugin primitives.

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

## What it does

1. **Decompose** your topic into orthogonal sub-questions grounded by preliminary web search
2. **Research** in parallel — one agent per sub-question, searching the web and extracting findings
3. **Aggregate** sources across all sub-questions, deduplicate, and enforce quality thresholds
4. **Write** a structured report with inline citations linking every claim to its source
5. **Review** structurally — automated quality gate checks completeness, coherence, depth, and clarity
6. **Verify** (separate step) — extract claims and check each against its source URL via cogni-claims in a dedicated context window

## What it means for you

If you produce research, analysis, or any content that needs to be both sourced and correct, this is your end-to-end pipeline.

- **Fast and parallel.** Basic reports dispatch 5–7 agents concurrently; deep reports run 15–25. Research that would take hours completes in minutes.
- **Claims-verified, not vibes-verified.** Every factual claim is extracted, matched to its source URL, and checked for deviations — misquotation, unsupported conclusions, selective omission.
- **Resumable.** Interrupted runs pick up from the first incomplete phase. No lost work.
- **Traceable.** Every finding links to a source, every claim links to a verification result. The full workspace is Obsidian-browsable.
- **Three depth levels.** Quick overview (basic), multi-section report (detailed), or recursive tree exploration (deep) — matched to your needs.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- Web access enabled (for research)
- bash, python3 (stdlib only — no pip dependencies)
- **cogni-claims** plugin (recommended — enables claims-verified review loop)
- Optional: **cogni-narrative** (story arc polish), **cogni-copywriting** (executive polish), **cogni-visual** (presentation generation)

## Quick start

Describe what you want in natural language:

- "Write a research report on quantum computing's impact on cryptography"
- "Write a detailed research report on AI adoption in healthcare"
- "Deep research on the future of autonomous vehicles"
- "Resume the research on autonomous vehicles"

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

## How it works

The pipeline uses two skills that split the work across separate context windows:

**research-report** orchestrates six phases. Phase 0 initializes the project workspace and runs preliminary web searches to ground the research. Phase 1 decomposes the topic into orthogonal sub-questions with search guidance for each. Phase 2 dispatches **section-researcher** agents (sonnet) in batches of 4–5 — each agent runs 5–7 web searches, fetches top results, curates sources with quality scores, and creates context + source entities. For deep reports, **deep-researcher** agents (sonnet) perform recursive tree exploration instead. Phase 3 aggregates all contexts, deduplicates sources, and enforces a 25,000-word context limit. Phase 4 hands the aggregated context to the **writer** agent (sonnet), which produces a structured draft with inline citations. Phase 5 runs a structural-only review (completeness, coherence, source diversity, depth, clarity). Phase 6 copies the accepted draft to `output/report.md`.

**verify-report** then runs in a fresh context window — loading only the draft and source entities, not the research data. It extracts 10–30 verifiable claims from the draft, submits them to cogni-claims for source URL verification, presents results to the user, and runs up to 3 review-revision iterations to fix any factual deviations found. This architectural split ensures claims verification gets full context attention.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `research-report` | skill | Main orchestrator — six-phase pipeline from topic to structurally reviewed report |
| `verify-report` | skill | Claims verification — extracts claims, verifies against sources via cogni-claims, revises deviations |
| `export-report` | skill | Export finalized report to HTML, PDF, or Markdown |
| `research-report-workspace` | skill | Workspace-aware research orchestration for integrated project environments |
| `section-researcher` | agent (sonnet) | Parallel web researcher for a single sub-question |
| `local-researcher` | agent (sonnet) | Parallel document analyst for local/hybrid research mode |
| `deep-researcher` | agent (sonnet) | Recursive tree explorer for deep research mode |
| `source-curator` | agent (sonnet) | Auto-curates sources for detailed/deep reports with 8+ sources — deduplication, quality scoring, relevance ranking |
| `writer` | agent (sonnet) | Compiles aggregated context into a structured, cited report |
| `claim-extractor` | agent (sonnet) | Extracts 10–30 verifiable claims from draft for verification |
| `reviewer` | agent (sonnet) | Quality gate — scores structure and factual accuracy, issues verdict |
| `revisor` | agent (sonnet) | Incorporates reviewer feedback and claims deviations into revised draft |
| `block-entity-writes` | hook (PreToolUse) | Forces entity creation via scripts for consistency and validation |
| `review-loop-guard` | hook (PostToolUse) | Caps review iterations at 3 to prevent infinite loops |

## Architecture

```
cogni-research/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       4 orchestration skills
│   ├── research-report/
│   │   ├── SKILL.md
│   │   └── references/           4 reference guides
│   ├── verify-report/
│   │   ├── SKILL.md
│   │   └── references/           3 reference guides (incl. claims-integration)
│   ├── export-report/
│   │   ├── SKILL.md
│   │   └── references/
│   └── research-report-workspace/
│       └── SKILL.md
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
├── schemas/                      4 entity JSON schemas
├── scripts/                      Entity + project utilities
└── references/                   Model strategy documentation
```

## Attribution

This plugin is an **independent reimplementation** — no source code from the original projects is used.

- **GPT-Researcher** by [Assaf Elovic / Tavily](https://github.com/assafelovic/gpt-researcher) (Apache-2.0) — multi-agent research architecture that inspired this plugin's parallel research and iterative review design.
- **STORM** by [Stanford OVAL](https://arxiv.org/abs/2402.14207) — perspective-driven article generation framework. GPT-Researcher's editorial workflow builds on STORM's multi-perspective synthesis approach.

## Custom development

Need custom research workflows, internal knowledge base integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
