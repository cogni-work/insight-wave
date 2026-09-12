---
id: workflow-portfolio-to-pitch
title: "Workflow: Portfolio to Pitch (portfolio → sales → visual)"
type: summary
tags: [workflow, sales, pitch, why-change, portfolio]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-pitch.md
status: stable
related: [plugin-cogni-portfolio, plugin-cogni-sales, plugin-cogni-workspace]
---

Generate a deal-specific or segment-reusable sales pitch from existing portfolio data.

## Pipeline

```
cogni-portfolio                            (Feature × Market propositions, customers, competitors)
   ↓ portfolio entities
cogni-sales:why-change                     (Corporate Visions arc composition)
   ↓ sales-presentation.md + sales-proposal.md
cogni-workspace:text-to-narrative → design-brief.md → Claude Design   (slides)
   ↓
slide deck + proposal document
```

## Duration

3–6 hours for a complete deal-specific pitch deck.

## End deliverable

A customer-tailored sales presentation as a slide deck, with a supporting proposal document.

## How it works

Pre-requisite: [[plugin-cogni-portfolio]] has populated the relevant Feature × Market intersection (proposition with IS/DOES/MEANS, customer profile for the buyer, competitive analysis against likely alternatives). See [[concept-data-model-patterns]] for the FxM join.

[[plugin-cogni-sales]] composes the pitch using the Corporate Visions Why Change arc:

- **Why Change** — surface the buyer's status quo cost (loss aversion)
- **Why Now** — sharpen urgency with timing-specific evidence
- **Why You** — differentiate against the buyer's likely alternatives (pulled from cogni-portfolio's competitive analysis)
- **Why Pay** — justify investment with quantified business case (pulled from cogni-portfolio's solution pricing tiers)

Output: `sales-presentation.md` (slide narrative) and `sales-proposal.md` (long-form). Both pass through the `copywriter` skill of [[plugin-cogni-workspace]] for Power Positions polish before final rendering.

Final hop through [[plugin-cogni-workspace]]: `text-to-narrative` runs the arc pipeline over the slide narrative and hands one `design-brief.md` to Claude Design for the deck. A presentation brief authored by hand still renders to HTML slides or PPTX — see [[concept-brief-based-rendering]].

## Two pitch modes

- **Deal-specific** — for a named account; `why-change` researches the customer's specific decision makers and current state
- **Segment-reusable** — for a market segment; reusable across many accounts in the same Feature × Market

## Steps

**1 — Portfolio data.** `cogni-portfolio:portfolio-resume` if the project already exists, otherwise `portfolio-setup` → the entity skills → `portfolio-communicate`. Output is propositions with IS/DOES/MEANS, competitor analysis and market sizing. Skip to step 2 if you already have portfolio data. `portfolio-architecture` visualizes the product-feature structure and catches gaps before they reach the pitch narrative. Focus on the propositions relevant to this customer or segment; the competitor analysis is what carries the "why us".

**2 — Narrative arc.** `/text-to-narrative`. Shapes portfolio propositions and customer context into a story arc — SCQA works well for sales. This step is skippable when you are using the Why Change methodology, since that arc is built into cogni-sales directly. For complex enterprise deals it adds strategic depth worth the extra pass.

**3 — Sales pitch.** `/why-change`. Takes narrative, portfolio data and customer specifics; produces structured pitch content covering unconsidered needs, the business case and the proposal. Named-customer pitches are deal-specific and want customer research; segment pitches are reusable across similar accounts. Optionally enrich with TIPS trends to carry the "why now".

**4 — Visual delivery.** `cogni-workspace:text-to-narrative` on the sales presentation with the `slides` target; hand its `design-brief.md` to Claude Design for the deck. Sales decks live on visual flow — review and adjust after generation. For a customer meeting, fewer slides with more impact beats a comprehensive deck. Consider also generating a leave-behind with the `web` target.

## Common pitfalls

- **Generic propositions.** A customer-specific pitch needs customer-specific value statements; reusing segment-level DOES/MEANS reads as boilerplate.
- **Missing the "why change".** The methodology needs a compelling reason the status quo is untenable. Without it the deck argues why you are good, not why they should move.
- **Skipping competitor analysis.** "Why us" is unanswerable without it, and it is the question that decides the deal.

**Source**: [docs/workflows/portfolio-to-pitch.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/portfolio-to-pitch.md)
