---
name: consulting-export
description: |
  Generate the final deliverable package for a Double Diamond engagement. Produces formatted
  outputs (PPTX, DOCX, XLSX, Excalidraw, themed HTML) by dispatching to cogni-visual and
  document-skills. The themed HTML deliverable combines all engagement content into one
  navigable document with concept diagrams and data charts via cogni-visual:enrich-report.
  Use whenever the user wants to produce engagement outputs — even partially or for a single
  deliverable. Trigger on: "generate deliverables", "export engagement", "create the deck",
  "produce the report", "final package", "export diamond", "create the slides",
  "I need to present to [audience]", "package it up", "generate the business case document",
  "make the roadmap visual", "export to PowerPoint", "output the results",
  "themed HTML", "HTML version", "visual report", "engagement report",
  or any request to render engagement content into a specific format.
  Also trigger when the user asks for a single deliverable (e.g., "just the executive summary
  as a PPTX") — this skill handles both full packages and individual deliverable generation.
allowed-tools: Read, Write, Edit, Glob, Grep, Skill
---

# Diamond Export — Generate Deliverables

Produce the final deliverable package by dispatching to cogni-visual and document-skills plugins. This skill reads all engagement outputs and generates formatted deliverables matched to the engagement vision. The **Engagement HTML Report** is a first-class output format: a single themed, navigable HTML document combining all deliverable content with concept diagrams (process flows, relationship maps, TIPS flows) and data charts — produced by composing a unified markdown and dispatching to `cogni-visual:enrich-report`.

## Diamond Coach Protocol

Read `$CLAUDE_PLUGIN_ROOT/references/diamond-coach.md` and adopt the Diamond Coach persona (brief mode — Export is mechanical).

**Export opening**: "Time to package everything up. Let me check what source content is available and map it to your deliverables."

**Prerequisite gate**: For each deliverable in the engagement's deliverable list, verify that the source content exists. Present a readiness summary:

> **Deliverable readiness:**
> - Solution Brief: `4-deliver/solution-brief.md` — ready
> - Action Plan: `4-deliver/action-plan.md` — ready
> - Business Case: `4-deliver/business-case.md` — **missing** (requires Deliver phase)

If critical deliverables are missing, explain which phase would produce them and offer to proceed with what's available or redirect to the missing phase.

## Core Concept

Every diamond engagement promises specific deliverables (defined during setup). Export assembles the raw phase outputs into polished, client-ready formats. It acts as a dispatcher — not a renderer — delegating format-specific work to the ecosystem's visual and document plugins.

## Workflow

### 1. Load Context

Read consulting-project.json. Extract the deliverables list from `vision.deliverables`.

If the user requests a single specific deliverable rather than the full package, extract just that deliverable from the list and proceed with it alone.

### 2. Map Deliverables to Sources

For each deliverable, identify the source content and rendering plugin:

| Deliverable | Source | Renderer |
|---|---|---|
| Strategic Options Brief | `4-deliver/option-scoring.md` + `3-develop/options/` | document-skills:docx or document-skills:pptx |
| Business Case | `4-deliver/business-case.md` | document-skills:xlsx (financials) + document-skills:docx (narrative) |
| Decision Board | `3-develop/options/option-synthesis.md` + `4-deliver/option-scoring.md` | cogni-visual:story-to-slides or enrich-report |
| Executive Summary | `4-deliver/executive-summary.md` | document-skills:pptx (one-pager) |
| Action Roadmap | `4-deliver/roadmap.md` | document-skills:pptx or document-skills:xlsx |
| TIPS Landscape | plugin_refs.tips_project output | cogni-trends trends-dashboard or cogni-visual:enrich-report |
| Portfolio Snapshot | plugin_refs.portfolio_project output | cogni-portfolio portfolio-dashboard |
| Claim Verification Log | `4-deliver/claims-verification.md` | document-skills:xlsx or markdown |
| Solution Brief | `4-deliver/solution-brief.md` | document-skills:docx or markdown |
| Action Plan | `4-deliver/action-plan.md` | document-skills:xlsx or markdown |
| **Engagement HTML Report** | All deliverable markdowns (composed) | cogni-visual:enrich-report |

**Themed HTML deliverable:** The Engagement HTML Report combines all engagement deliverables into a single themed, navigable HTML document with concept diagrams and data charts. This is a first-class output format — offer it alongside PPTX/DOCX/XLSX when presenting format options to the consultant: "Formats available: PPTX slides, DOCX documents, XLSX spreadsheets, and a **themed HTML report** combining everything into one navigable document with concept diagrams and charts."

The HTML report is produced by composing all deliverable markdowns into one unified document (Step 2.5) and dispatching to `/enrich-report`, which handles theming, concept diagram generation (via the `cogni-visual:concept-diagram` agent — process flows, relationship maps, TIPS flows, 2x2 matrices), Chart.js data visualizations, and responsive HTML assembly.

**Individual enrichment:** Any single markdown deliverable can also be post-processed with `/enrich-report` independently. This is additive — the original format rendering still applies.

### 2.5. Compose Engagement HTML Source

If the consultant wants the Engagement HTML Report (offer this proactively as a format option), compose all deliverable markdowns into a single unified document before dispatching to enrich-report.

**Composition steps:**

1. **Collect sources**: Read all markdown deliverable files that exist in the engagement directory (`4-deliver/`, `2-define/`, `3-develop/`). Skip missing files gracefully — note them in a comment block at the top of the composed document.

2. **Order by narrative flow**: Arrange sections in engagement narrative order, not directory order. The ordering depends on the vision class — follow the deliverable sequence from `$CLAUDE_PLUGIN_ROOT/references/deliverable-map.md`. Default ordering for all vision classes:
   1. Executive Summary (`4-deliver/executive-summary.md`)
   2. Problem Context (`2-define/problem-statement.md`)
   3. Strategic Options / Option Synthesis (`3-develop/options/option-synthesis.md`)
   4. Option Scoring (`4-deliver/option-scoring.md`)
   5. Business Case (`4-deliver/business-case.md`)
   6. Roadmap / Action Plan (`4-deliver/roadmap.md` or `4-deliver/action-plan.md`)
   7. Solution Brief (`4-deliver/solution-brief.md`)
   8. Claims Verification (`4-deliver/claims-verification.md`)

3. **Write `output/engagement-report.md`** with this structure:

   ```markdown
   ---
   title: "{engagement_name} — Engagement Report"
   client: "{client_name}"
   vision_class: "{vision_class}"
   date: "{date}"
   language: "{language}"
   generated_by: consulting-export
   ---

   # {Engagement Name}

   **Client:** {client} | **Vision:** {vision_class} | **Date:** {date}

   ---

   ## Executive Summary

   {content from 4-deliver/executive-summary.md, stripped of its own H1/frontmatter}

   ## Problem Context

   {content from 2-define/problem-statement.md}

   ## Strategic Options

   {content from 3-develop/options/option-synthesis.md}

   ...each deliverable as an H2 section...
   ```

4. **Preserve data structures**: Keep all tables, numeric data, bullet lists, and process descriptions verbatim — these are what enrich-report's content pattern detection uses to decide where to place charts and concept diagrams. Specifically:
   - Tables with numeric columns → trigger `comparison-bar` or `stat-chart`
   - Sequential steps with "leads to" / "results in" language → trigger `process-flow` concept diagrams
   - Scoring matrices → trigger chart visualizations
   - T→I→P→S chain references → trigger `tips-flow` concept diagrams
   - Stakeholder or theme interconnections → trigger `relationship-map` concept diagrams

5. **Dispatch to enrich-report**: Invoke `/enrich-report` with:
   - `source_path`: `{engagement_dir}/output/engagement-report.md`
   - `density`: `balanced` (default — consultant can request `minimal` or `rich`)
   - `language`: from `consulting-project.json`
   - `theme`: pass the workspace theme if already resolved in this session, otherwise let enrich-report invoke `pick-theme`

   The enrich-report skill handles everything from here: theme derivation, content analysis, enrichment planning (with interactive review), concept diagram generation via the `concept-diagram` agent, Chart.js chart generation, and HTML assembly. The output lands at `output/engagement-report-enriched.html`.

### 3. Generate Each Deliverable

For each deliverable in the list:

1. **Check source exists**: If the source file is missing, check whether the content exists in an alternative location or format (e.g., the business case might be in `4-deliver/business-case.md` or assembled from `4-deliver/option-scoring.md` + `4-deliver/roadmap.md`). If the content genuinely doesn't exist, skip the deliverable and tell the consultant which phase would produce it: "The Decision Board requires option synthesis from the Develop phase. Run `consulting-develop` to generate it."
2. Read the source content
3. Dispatch to the appropriate renderer
4. Save output to `output/` directory with descriptive filename
5. Note success/failure

Between deliverables, check with the consultant if they want to review before continuing.

**Theme support**: If a cogni-workspace theme is active, pass the theme to visual/document plugins for consistent branding across all deliverables. Theme consistency matters because deliverables go to the client as a set — mismatched branding signals sloppiness.

### 4. Assemble Package Index

Create `output/README.md` as an index of all generated deliverables:

**Example** (market-entry engagement for French market):

```markdown
# EuroTech France Entry — Deliverable Package

**Client**: EuroTech GmbH
**Vision**: market-entry
**Date**: 2026-03-21

## Deliverables

| # | Deliverable | Format | File |
|---|---|---|---|
| 1 | Executive Summary | PPTX | executive-summary.pptx |
| 2 | Market Feasibility Report | DOCX | market-feasibility.docx |
| 3 | Business Case | XLSX + DOCX | business-case.xlsx, business-case.docx |
| 4 | Action Roadmap | PPTX | entry-roadmap.pptx |
| 5 | Claim Verification Log | XLSX | claims-verification.xlsx |
| 6 | Engagement HTML Report | HTML | engagement-report-enriched.html |
```

### 5. Present Summary

> **Deliverable package generated.**
> - N deliverables produced in `output/`
> - [list files with formats]
>
> Review the package and let me know if any deliverable needs refinement.

## Important Notes

- Prefer the theme from the workspace if available — consistent branding across all deliverables matters for client perception
- Large deliverables (detailed PPTX decks) may need the consultant to provide additional guidance on structure and narrative flow
- The package index is always generated as markdown, regardless of other format choices
- If a renderer plugin fails, note the error and offer alternatives (e.g., "PPTX generation failed — want me to produce a DOCX instead?")
