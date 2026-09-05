---
id: workflow-research-to-report
title: "Workflow: Research to Report (knowledge → narrative → visual)"
type: summary
tags: [workflow, research-to-report, knowledge, narrative, visual, claims]
created: 2026-08-13
updated: 2026-08-20
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/research-to-report.md
status: stable
related: [plugin-cogni-knowledge, plugin-cogni-workspace]
---

Original research turned into a presentation — the pipeline an analyst runs to get from a question to a deck without losing the evidence trail.

## Pipeline

```
cogni-knowledge (plan → curate → fetch → ingest → distill → compose → verify → finalize)
   ↓ cited synthesis, deposited into the bound wiki
cogni-workspace:narrative (story arc shaping)
   ↓ executive narrative
cogni-workspace:story-to-slides → render-html-slides (brief → rendered deck)
   ↓ slides
```

## Duration

2–4 hours, depending on research depth.

## End deliverable

A slide deck (or web narrative) whose every substantive claim traces back to a source the pipeline actually read.

## Steps

**1 — Research.** `cogni-knowledge:knowledge-run`, or describe the topic and let the plan phase decompose it. Input is a research question or topic brief; output is a cited synthesis, verified zero-network against each source's extracted claims and deposited into the bound wiki. The plan decomposes the topic into 3–7 sub-questions, and deeper runs ingest more sources. Citations are verified during `knowledge-verify`; for a live-source re-check run `knowledge-refresh` with a resweep, which dispatches [[plugin-cogni-workspace]]. Every run deposits its synthesis back into the wiki, so the next run reads it as prior framing.

**2 — Narrative.** `/narrative` (or `cogni-workspace:narrative`). Takes the synthesis in, hands back an executive narrative shaped by a story arc. Choose the arc for the audience: SCQA for problem-solution, Minto Pyramid for recommendation-first, Hero's Journey for transformation. Review before proceeding — this is where the story takes shape.

**3 — Visual.** `cogni-workspace:story-to-slides` produces the presentation brief; `/render-html-slides` renders it. The theme comes from workspace settings — see [[concept-theme-inheritance]]. State a slide count up front if you are time-constrained. For web delivery use `cogni-workspace:story-to-web` instead.

## Common pitfalls

- **Skipping the narrative step.** Going straight from research to slides produces data-heavy, story-light presentations. The narrative step is where the insight emerges.
- **Mismatched research depth.** Deep research for a five-slide deck wastes hours. Match depth to deliverable scope.
- **Unverified imported content.** If you bring your own material instead of letting cogni-knowledge produce it, run `/claims` before the narrative step — nothing else in the chain will check it.

## Why this order

Research first because the arc should be chosen against what the evidence actually supports, not the reverse. Narrative before visual because [[concept-brief-based-rendering]] means the renderer consumes a brief, and a brief built from an unshaped synthesis inherits its shapelessness.

**Source**: [research-to-report workflow guide](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/research-to-report.md)
