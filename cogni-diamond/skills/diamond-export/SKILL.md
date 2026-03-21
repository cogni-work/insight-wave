---
name: diamond-export
description: |
  Generate the final deliverable package for a Double Diamond engagement. Produces formatted
  outputs (PPTX, DOCX, XLSX, Excalidraw) by dispatching to cogni-visual and document-skills.
  Use whenever the user wants to produce engagement outputs — even partially or for a single
  deliverable. Trigger on: "generate deliverables", "export engagement", "create the deck",
  "produce the report", "final package", "export diamond", "create the slides",
  "I need to present to [audience]", "package it up", "generate the business case document",
  "make the roadmap visual", "export to PowerPoint", "output the results",
  or any request to render engagement content into a specific format.
  Also trigger when the user asks for a single deliverable (e.g., "just the executive summary
  as a PPTX") — this skill handles both full packages and individual deliverable generation.
---

# Diamond Export — Generate Deliverables

Produce the final deliverable package by dispatching to cogni-visual and document-skills plugins. This skill reads all engagement outputs and generates formatted deliverables matched to the engagement vision.

## Core Concept

Every diamond engagement promises specific deliverables (defined during setup). Export assembles the raw phase outputs into polished, client-ready formats. It acts as a dispatcher — not a renderer — delegating format-specific work to the ecosystem's visual and document plugins.

## Prerequisites

- Deliver phase should be complete (or substantially complete)
- Engagement deliverables list defined in diamond-project.json

## Workflow

### 1. Load Context

Read diamond-project.json. Extract the deliverables list from `vision.deliverables`.

If the user requests a single specific deliverable rather than the full package, extract just that deliverable from the list and proceed with it alone.

### 2. Map Deliverables to Sources

For each deliverable, identify the source content and rendering plugin:

| Deliverable | Source | Renderer |
|---|---|---|
| Strategic Options Brief | `deliver/option-scoring.md` + `develop/options/` | document-skills:docx or document-skills:pptx |
| Business Case | `deliver/business-case.md` | document-skills:xlsx (financials) + document-skills:docx (narrative) |
| Decision Board | `develop/options/option-synthesis.md` + `deliver/option-scoring.md` | Excalidraw (via cogni-visual story-to-big-picture) |
| Executive Summary | `deliver/executive-summary.md` | document-skills:pptx (one-pager) |
| Action Roadmap | `deliver/roadmap.md` | document-skills:pptx or document-skills:xlsx |
| TIPS Landscape | plugin_refs.tips_project output | cogni-tips tips-dashboard or Excalidraw (via cogni-visual story-to-big-picture) |
| Portfolio Snapshot | plugin_refs.portfolio_project output | cogni-portfolio portfolio-dashboard |
| Claim Verification Log | `deliver/claims-verification.md` | document-skills:xlsx or markdown |

### 3. Generate Each Deliverable

For each deliverable in the list:

1. **Check source exists**: If the source file is missing, check whether the content exists in an alternative location or format (e.g., the business case might be in `deliver/business-case.md` or assembled from `deliver/option-scoring.md` + `deliver/roadmap.md`). If the content genuinely doesn't exist, skip the deliverable and tell the consultant which phase would produce it: "The Decision Board requires option synthesis from the Develop phase. Run `diamond-develop` to generate it."
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
