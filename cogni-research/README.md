# Research Pipeline Plugin

A Claude Code plugin that transforms research questions into traceable, source-backed syntheses through a 12-phase pipeline with anti-hallucination controls, parallel execution, and Obsidian wikilink integration.

> **Important**: This plugin generates research syntheses from web sources and LLM knowledge. All outputs should be reviewed by qualified professionals before use in decision-making, publications, or regulatory contexts. Claims include confidence scores and source traceability, but independent verification is recommended.

## Why this exists

LLM-assisted research is fast but fragile. The gap between "AI-generated summary" and "trustworthy synthesis" is large enough to be dangerous:

| Problem | What goes wrong |
|---------|-----------------|
| Shallow research | Surface-level answers that miss nuance, edge cases, and conflicting evidence |
| Hallucinated citations | Sources that don't exist, DOIs that resolve nowhere, quotes that never appeared |
| Manual effort | Hours spent organizing findings, cross-referencing sources, and building bibliographies |
| No provenance | No way to trace a conclusion back through the evidence chain to its original source |

This plugin exists because research worth acting on needs to be traceable from conclusion to source.

## What it means for you

- **Depth without the grind.** A 12-phase pipeline handles dimension planning, parallel web search, citation extraction, claim verification, and trend synthesis — you guide the questions.
- **Every claim traces to its source.** Obsidian wikilinks create an unbroken chain from synthesis conclusions through trends, claims, citations, and findings back to the original source URL.
- **Interruption-safe.** Each phase scans for completed work and resumes from where it left off — rate limits and session timeouts don't lose progress.
- **Export-ready.** Interactive HTML reports, formal PDF documents, and RAG-optimized markdown — all from the same research base.

## Installation

```bash
claude plugins add cogni-work/cogni-research
```

## Quick start

```
Use the deeper-research-0 skill to research innovations in collaborative robotics
```

That single prompt initializes a project, refines your question into research dimensions, and generates query batches. Then continue through the pipeline:

```
Use deeper-research-1 to create findings
Use deeper-research-2 to enrich the research
Use deeper-research-3 to synthesize the research
Use export-html-report to create an interactive HTML report
```

Or describe what you want in natural language:

- "research the impact of AI on supply chain logistics"
- "continue the research — create findings for all dimensions"
- "enrich with citations and verify claims"
- "export as a PDF report for the board presentation"

## Skills

| Skill | Description |
|-------|-------------|
| `deeper-research-0` | Research planning — initialize project, refine questions, create dimensions, generate query batches |
| `deeper-research-1` | Parallel findings creation — web search and LLM-based evidence gathering across dimensions |
| `deeper-research-2` | Research enrichment — source extraction, knowledge mapping, citation generation, claim verification |
| `deeper-research-3` | Research synthesis — trend generation, evidence catalog, cross-dimensional report generation |
| `export-html-report` | Export research as a self-contained interactive HTML report with theme support |
| `export-pdf-report` | Export research as a formal A4 PDF report with cover page and source index |
| `export-rag` | Export research entities as flat markdown files optimized for RAG in Claude Projects |
| `polish-research` | Parallel copywriting across synthesis documents, trends, and megatrends |
| `portfolio-mapping` | Map IT service portfolios to research dimensions via web research |
| `fact-checker` | Standalone claim verification with dual-layer confidence scoring |

## Agents

| Agent | Description |
|-------|-------------|
| `batch-creator` | Generate query batches from research dimensions for parallel execution |
| `citation-generator` | Extract and format citations from findings with source attribution |
| `dimension-planner` | Plan research dimensions from refined questions |
| `evidence-synthesizer` | Synthesize evidence across findings into coherent trend narratives |
| `fact-checker` | Verify individual claims against their cited sources |
| `findings-creator` | Orchestrate parallel findings creation across dimensions |
| `findings-creator-file` | Create findings from file-based sources |
| `findings-creator-llm` | Create findings using LLM knowledge with confidence scoring |
| `knowledge-extractor` | Extract domain concepts and knowledge graphs from findings |
| `knowledge-merger` | Merge and deduplicate extracted knowledge across dimensions |
| `pdf-report-writer` | Generate formal PDF report sections with proper formatting |
| `portfolio-web-researcher` | Research IT service portfolio mappings via web search |
| `publisher-generator` | Generate publisher profiles from source metadata |
| `source-creator` | Extract and validate source metadata from findings |
| `synthesis-dimension` | Synthesize a single research dimension into narrative form |
| `synthesis-hub` | Orchestrate cross-dimensional synthesis and final report assembly |
| `trends-creator` | Identify and describe trends from evidence patterns |

## Example Workflows

### Deep Research on a Topic

1. Start with `Use the deeper-research-0 skill to research innovations in collaborative robotics`
2. Continue with `Use deeper-research-1 to create findings` — parallel web search across all dimensions
3. Run `Use deeper-research-2 to enrich the research` — sources, citations, knowledge extraction, claims
4. Finish with `Use deeper-research-3 to synthesize the research` — trends, evidence catalog, final report

### Export and Polish

1. Run `Use export-html-report to create an interactive HTML report` for web viewing
2. Run `Use export-pdf-report to generate a formal PDF report` for print
3. Run `Use polish-research to improve the writing quality` for executive-ready prose
4. Run `Use export-rag to prepare research for Claude Projects` for RAG integration

## Components

| Component | Type | Count |
|-----------|------|-------|
| Skills | User-facing pipeline stages and export tools | 10 |
| Agents | Internal sub-processors orchestrated by skills | 17 |
| Hooks | Pre/post validation for entity operations | 8 |

## How It Works

### Pipeline Phases

The research pipeline runs in four stages, each as a separate skill invocation:

```
deeper-research-0    Phases 0-2.5    Planning: init, questions, dimensions, batches
deeper-research-1    Phase 3         Discovery: parallel findings from web + LLM
deeper-research-2    Phases 4-7      Enrichment: sources, knowledge, citations, claims
deeper-research-3    Phases 8-13     Synthesis: trends, evidence, report generation
```

Each stage writes its output as entity files (structured markdown with YAML frontmatter) that the next stage consumes. Rate-limit interruptions are handled automatically — each stage scans for completed work and resumes from where it left off.

### Entity Types

The pipeline produces 13 entity types across numbered directories:

```
00-initial-question     01-research-dimensions    02-refined-questions
03-query-batches        04-findings               05-domain-concepts
06-megatrends           07-sources                08-publishers
09-citations            10-claims                 11-trends
12-synthesis
```

### Anti-Hallucination

Every claim traces back to its original source through Obsidian wikilinks. The pipeline enforces source attribution, confidence scoring, validation gates, and grounding requirements. Hooks auto-detect and block hallucinated entity references.

## Architecture

```
cogni-research/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       10 pipeline and export skills
│   ├── deeper-research-0/
│   ├── deeper-research-1/
│   ├── deeper-research-2/
│   ├── deeper-research-3/
│   ├── export-html-report/
│   ├── export-pdf-report/
│   ├── export-rag/
│   ├── polish-research/
│   ├── portfolio-mapping/
│   └── fact-checker/
├── agents/                       17 internal sub-processors
│   ├── batch-creator.md
│   ├── citation-generator.md
│   ├── dimension-planner.md
│   └── ...
├── hooks/                        8 validation hooks
│   ├── hooks.json
│   ├── block-entity-writes.sh
│   └── ...
├── scripts/                      Pipeline utilities
├── config/                       Entity schemas
└── shared_utils/                 Python utilities (stdlib only)
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- macOS, Linux, or Windows with WSL
- `python3` (3.8+, stdlib only — no pip dependencies)
- `jq` for JSON processing

## Configuration

### Companion Plugins

This plugin works standalone. For extended capabilities, install these companion plugins:

- **[cogni-workspace](https://github.com/cogni-work/cogni-workplace)** — workspace scaffolding, themes, copywriting, diagrams, document processing
- **[cogni-sales](../cogni-sales)** — research-backed B2B sales proposals using Corporate Visions methodologies

### Environment Variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `CLAUDE_PLUGIN_ROOT` | Auto | Plugin root directory (set automatically) |
| `COGNI_RESEARCH_ROOT` | No | Research workspace root for multi-project setups |
| `OBSIDIAN_VAULT_ROOT` | No | Obsidian vault root for wikilink resolution |
| `DEBUG_MODE` | No | Enable verbose logging |

## License

[CogniWorks Pro License](./LICENSE) — paid subscription required.

Contact stephan@cogni-work.ai for licensing inquiries.

## Author

**Stephan de Haas** — Consulting Engineer for AI Digitalization
stephan@cogni-work.ai
