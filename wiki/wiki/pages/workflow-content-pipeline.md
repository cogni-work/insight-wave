---
id: workflow-content-pipeline
title: "Workflow: Content Pipeline (marketing → narrative → copywriting → visual)"
type: summary
tags: [workflow, content-pipeline, marketing, narrative, copywriting, visual]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/content-pipeline.md
status: stable
related: [plugin-cogni-marketing, plugin-cogni-workspace]
---

The end-to-end content production pipeline — from strategy to channel-ready deliverables.

## Pipeline

```
cogni-marketing (setup + content generation)
   ↓ raw content pieces
cogni-workspace `text-to-narrative` (story arc shaping, long-form only)
   ↓ narrative with arc_id
cogni-workspace `copywriter` (polish, arc-aware)
   ↓ polished prose
`text-to-narrative` Phase 7 → design-brief.md → Claude Design (slides / web)
```

## Duration

2–6 hours for a complete content batch, depending on format count and polish depth.

## End deliverable

A multi-channel marketing content package — polished articles, battle cards, email nurtures, and optionally a slide deck or web narrative.

## How it works

[[plugin-cogni-marketing]] generates content per the market × GTM-path × content-type matrix. Long-form pieces (whitepapers, thought-leadership articles, keynote outlines) flow into the `text-to-narrative` skill of [[plugin-cogni-workspace]] for arc shaping — the `arc_id` set here drives downstream polish and visual treatment.

Short-form content (LinkedIn posts, carousels, battle cards) skips narrative and goes straight to the `copywriter` skill of [[plugin-cogni-workspace]] for polish.

The `copywriter` skill applies messaging frameworks (BLUF, Pyramid, SCQA, STAR, PSB, FAB, Inverted Pyramid) per content type. When `arc_id` is present, polish preserves arc structure (the Why Change → Why Now → Why You → Why Pay sequence in a Corporate Visions narrative stays intact).

Optional final hop: the `design-brief.md` that `text-to-narrative` Phase 7 cuts from the finished narrative goes to Claude Design for a slide deck or web narrative, for distribution channels that need visual treatment. A presentation, web or infographic brief authored by hand against the brief templates of [[plugin-cogni-workspace]] still renders through its surviving renderers — see [[concept-brief-based-rendering]].

## Why this order

Each step adds value the previous can't: marketing knows the strategic positioning, narrative knows arc structure, copywriting knows messaging frameworks and polish, visual knows rendering. Bypassing a step works for the simple case but produces visibly weaker output for sophisticated channels.

## Steps

**1 — Set up the marketing project.** `/marketing-setup`. Takes a cogni-portfolio project and optionally a TIPS project from cogni-trends; writes `marketing-project.json` with brand voice, target markets, and the GTM-path-to-theme mapping. Tone, language and industry conventions are set here and apply to every generated piece. Without a TIPS project the engine falls back to generic themes — run `cogni-trends:trend-scout` first if you want strategy-connected content. For bilingual projects pick `de` or `en` as primary; content can be regenerated in the other language later.

**2 — Build the content strategy.** `/content-strategy`. Produces a three-dimensional matrix across markets × GTM paths × content types with priority sequencing. The matrix surfaces gaps — start at the intersection of your most important market and strongest theme. Treat it as a plan, not a target: you do not have to fill every cell to ship a campaign. Re-run after adding propositions; the diff shows where coverage changed.

**3 — Generate content.** One command per funnel stage:

| Funnel stage | Content type | Command |
|---|---|---|
| Awareness | Thought leadership | `/thought-leadership` |
| Engagement | Demand generation | `/demand-gen` |
| Conversion | Lead generation | `/lead-gen` |
| Decision | Sales enablement | `/sales-enablement` |
| Account-specific | ABM | `/abm` |

Output is raw content in up to sixteen formats. Content-writer agents run in parallel, so request several pieces in one prompt to generate a batch. Each piece records the TIPS claims and portfolio propositions it draws from, so sourced content traces back to data. For named-account work, skip steps 2–3 and go straight to `/abm` with the target account.

**4 — Polish.** `/copywrite <content-path>` per piece, or describe the batch. Applies Pyramid Principle, BLUF, active voice and readability scoring. For multi-stakeholder content run `/review-doc` afterwards — reader personas score and synthesize feedback. German content auto-detects and applies Wolf Schneider rules with Amstad readability scoring.

**5 — Render (optional).** Describe the output you want. cogni-workspace reads the polished narrative, detects the story arc, and maps content to layouts with assertion headlines. Prefer the web-narrative format over slides for a leave-behind or microsite. Stop at step 4 if the content stays in markdown — rendering is opt-in.

## Common pitfalls

- **Channel overload.** Sixteen formats is what the plugin supports, not a target for one sprint. Start with three or four priority channels and expand after the first batch performs.
- **Skipping the content strategy.** Without the matrix there is no coverage visibility, and you end up with content for the topics that felt interesting rather than the gaps that matter.
- **Polishing before the strategy is final.** Polish a post, then change the GTM path it targets, and the work is redone. Generate, validate strategy fit, then polish.
- **Generic inputs.** Shallow TIPS themes or propositions without market-specific DOES/MEANS produce filler. Invest in the input data before scaling generation.

**Source**: [docs/workflows/content-pipeline.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/content-pipeline.md)
