# cogni-research

Multi-agent research report generator with parallel web research, structural review, and claims verification against cited source URLs.

For the canonical IS/DOES/MEANS positioning of this plugin, see the [cogni-research README](../../cogni-research/README.md).

---

## Overview

cogni-research automates the research pipeline from topic to verified, sourced report. The core problem it addresses: LLM-generated reports cite sources confidently, but citation hallucination rates range from 14% to 95% in published studies. Reports that look well-sourced may have no verifiable backing at all.

The plugin separates research from verification across two skills and context windows. `research-report` runs a six-phase orchestration pipeline ending in a structurally reviewed draft. `verify-report` then loads only the draft and source entities — without competing for context with research data — and runs a claims verification loop via cogni-claims.

Research runs in parallel. A basic report dispatches 5–7 section-researcher agents concurrently. A deep report runs 15–25 agents in recursive tree exploration mode. All agents report cost estimates; all phases write to disk so interrupted runs resume from the first incomplete phase.

Entities are stored as Markdown files with YAML frontmatter — Obsidian-browsable with wikilink graph navigation. Every claim in the draft links to a source entity; every source entity links to the claims it backs.

---

## Key Concepts

### Two-Skill Architecture

The two-skill split is intentional:

- **research-report** saturates context with sub-questions, research contexts, source entities, and the report draft. After Phase 6, context is full.
- **verify-report** runs in a fresh context window, loading only the draft and source files. This gives claims verification the full attention it needs — without competing with 50,000 words of research data.

Never run verify-report in the same session as a long research-report run without first compacting context.

### Three Report Depths

| Type | Sub-questions | Agents | Words | Use case |
|------|--------------|--------|-------|----------|
| Basic | 5 | 7–9 | 3,000–5,000 | Quick overview, single topic |
| Detailed | 5–10 | 10–15 | 5,000–10,000 | Multi-section report with outline |
| Deep | 10–20 (tree) | 15–25 | 8,000–15,000 | Recursive exploration, maximum depth |

### Three Source Modes

| Mode | What it researches |
|------|--------------------|
| web | Live web search via WebSearch + WebFetch (default) |
| local | User-provided documents (PDF, MD, TXT, CSV, JSON) via Read + Glob + Grep |
| hybrid | Both web and local researchers in parallel, merged in aggregation |

### Entity Model

Four typed entities, all Markdown with YAML frontmatter and Obsidian wikilinks:

| # | Entity | Directory | Purpose |
|---|--------|-----------|---------|
| 00 | SubQuestion | `00-sub-questions/data/` | Decomposed research sub-questions |
| 01 | Context | `01-contexts/data/` | Per-sub-question research findings |
| 02 | Source | `02-sources/data/` | Deduplicated source registry |
| 03 | ReportClaim | `03-report-claims/data/` | Claims extracted from report draft |

Entities are created only via `scripts/create-entity.sh` — a hook blocks direct file writes to enforce schema consistency.

### Claims Verification Loop

`verify-report` extracts 10–30 verifiable claims from the draft, submits them to cogni-claims for source URL verification, presents results, and runs up to 3 review-revision iterations to fix factual deviations. Deviation types include: misquotation, unsupported conclusion, selective omission, and number transposition.

### Project Directory Structure

```
cogni-research-{slug}/
├── 00-sub-questions/data/     # Decomposed questions (sq-*.md)
├── 01-contexts/data/          # Research findings (ctx-*.md)
├── 02-sources/data/           # Source registry (src-*.md)
├── 03-report-claims/data/     # Verified claims (rc-*.md)
├── output/
│   ├── draft-v1.md            # First draft
│   ├── draft-v2.md            # Post-review revision
│   └── report.md              # Final accepted report
└── .metadata/
    ├── execution-log.json     # Phase state for resumability
    └── review-verdicts/       # Reviewer decisions per iteration
```

---

## Getting Started

**First prompt:**

> Write a detailed research report on AI regulation in the EU

What happens:

1. `research-report` initializes the project directory with `project-config.json`
2. Phase 0: preliminary web searches to ground the topic decomposition
3. Phase 1: decomposes into 5–10 orthogonal sub-questions with search guidance
4. Phase 2: dispatches `section-researcher` agents in batches of 4–5 — each runs 5–7 web searches, curates sources, creates context and source entities
5. Phase 3: aggregates contexts, deduplicates sources, enforces 25,000-word context limit
6. Phase 4: `writer` agent produces a structured draft with inline citations
7. Phase 5: `reviewer` agent scores structure and coherence, issues verdict
8. Phase 6: accepted draft copied to `output/report.md`

**Then, in a fresh session:**

> Verify the EU AI regulation report

`verify-report` loads the draft and source entities, extracts 10–30 claims, checks each against its cited URL via cogni-claims, and presents verification results with deviation types.

---

## Capabilities

### research-report

Main orchestration skill — six-phase pipeline from topic to structurally reviewed draft. Supports three depths (basic/detailed/deep), three source modes (web/local/hybrid), and configurable options for market localization, output language, tone, citation format, researcher role, source URL pre-fetch, domain filtering, and sub-question count.

**Example prompt:** "Write a deep research report on quantum computing's impact on post-quantum cryptography, focus on NIST standardization"

**Example with options:**

> Research the state of industrial AI adoption in Germany. Use detailed depth, output in German, restrict to DACH sources.

This sets `market: dach`, `output_language: de`, generating German-language search queries targeting VDMA, BITKOM, Fraunhofer, and other DACH institutional sources.

---

### verify-report

Claims verification in a fresh context window. Extracts verifiable factual claims from the draft, submits to cogni-claims for source URL checking, runs up to 3 review-revision cycles to fix deviations. Works on both cogni-research project directories (auto-detected) and standalone Markdown reports with inline citations.

**Example prompt:** "Verify claims in the quantum computing report"

**Example standalone:** "Fact-check this report" (with a Markdown report containing `[Source: Publisher](URL)` citations)

---

### export-report (deprecated)

> **Superseded by cogni-visual:enrich-report**, which produces superior themed HTML with interactive charts and now supports PDF/DOCX export via the `formats` parameter. Use `/enrich-report` instead.

---

## Integration Points

### Upstream (what cogni-research consumes)

| Plugin | What is consumed |
|--------|-----------------|
| cogni-claims | Source URL verification in verify-report (primary dependency) |
| cogni-visual | enrich-report for themed HTML/PDF/DOCX output (replaces export-report) |
| cogni-workspace | Theme selection for visual exports |

cogni-claims is a soft dependency — research-report runs without it, but verify-report requires it for claims checking.

### Downstream (what cogni-research produces for others)

| Plugin | Skill | What is provided |
|--------|-------|-----------------|
| cogni-narrative | `/narrative` | `output/report.md` as narrative source — cogni-narrative auto-bridges `[Source: Publisher](URL)` citations into per-source files |
| cogni-copywriting | `/copywrite` | Narrative output for executive polish (invoke after cogni-narrative) |
| cogni-visual | `/story-to-slides` | Polished narrative for presentation brief generation |
| cogni-claims | verify-report | Claims submitted for source URL verification |

---

## Common Workflows

### Workflow 1: Full Research-to-Verified-Report Pipeline

The standard sequence for a sourced, verified report.

1. `/research-report` — topic, depth, source mode
2. Review the draft in `output/report.md`
3. Start a new session: `/verify-report`
4. Review verification results — accept, revise, or flag for manual review
5. `output/report.md` is updated with verified content

For extending this into a narrative and slides, see [../workflows/research-to-deliverables.md](../workflows/research-to-deliverables.md).

---

### Workflow 2: Document-Grounded Research (Hybrid Mode)

Use this when you have internal documents that should inform the research alongside web sources.

1. Place documents in a known directory (e.g., `./documents/`)
2. Run: "Write a detailed research report on our competitive landscape, using these documents plus web research"
   - The skill detects hybrid mode from your prompt or you specify `report_source: hybrid`
   - `local-researcher` and `section-researcher` agents run in parallel, results merged in Phase 3
3. `/verify-report` — checks web-sourced claims; local document claims are flagged differently

---

### Workflow 3: Research into Trend-Informed Narrative

Use this to feed a research report into the cogni-trends or cogni-narrative pipeline.

1. `/research-report` — research the industry or technology topic
2. `/verify-report` — verify claims before downstream use
3. cogni-narrative `/narrative` — transform the verified report into an arc-driven narrative
4. cogni-visual `/story-to-slides` or `/story-to-big-picture` — produce visual deliverables

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Research-report stops mid-phase | Context window exhausted during large deep run | Resume in a new session — `/research-report` auto-detects phase state from `.metadata/execution-log.json` and continues from the first incomplete phase |
| Verify-report can't find sources | run in the same session as a long research run | Always run verify-report in a new session so it gets a fresh context window |
| "cogni-claims not found" | cogni-claims plugin not installed | Install cogni-claims from the marketplace; verify-report requires it |
| Draft has thin sections | Sub-questions were too broad | Use detailed depth and specify the section outline in your prompt, or increase `max_subtopics` |
| Sources are all from one domain | Web search too narrow | Use the `query_domains` option to diversify, or add `source_urls` for specific sources to prioritize |
| Claims verification shows high deviation rate | Draft was written with training knowledge rather than source content | This is the expected catch — the revisor agent will fix deviations in up to 3 iterations |
| Report in wrong language | `market` setting defaulted to global | Specify market explicitly: "research in German" or use `market: dach` in project-config.json |
| Hook blocks entity creation | Trying to create entity files with Write tool | Entity files must be created via `scripts/create-entity.sh` — this is enforced by the `block-entity-writes` PreToolUse hook |

---

## Extending This Plugin

cogni-research accepts contributions in several areas:

- **Report types** — new depth modes or specialized report templates (e.g., patent landscape, regulatory analysis)
- **Research strategies** — new sub-question decomposition heuristics, specialized agent roles
- **Citation formats** — additional citation styles beyond APA/MLA/Chicago/Harvard/IEEE/wikilink
- **Market sources** — curated authority source lists for additional regions beyond the current set

See the [insight-wave contribution guide](../../CONTRIBUTING.md) for guidelines.
