---
id: workflow-trends-to-solutions
title: "Workflow: Trends to Solutions (trends → portfolio → visual)"
type: summary
tags: [workflow, trends, solutions, portfolio, tips, value-modeler]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/trends-to-solutions.md
status: stable
related: [plugin-cogni-trends, plugin-cogni-portfolio, plugin-cogni-workspace, concept-trends-portfolio-bridge]
---

Turn scouted trends into ranked solution blueprints with visual deliverables.

## Pipeline

```
cogni-trends:trend-scout                  (60 scored candidates per dimension)
   ↓ scored candidates
cogni-trends:value-modeler                (TIPS network + investment themes + solution templates)
   ↓ tips-value-model.json
cogni-portfolio:trends-bridge             (import templates as portfolio features)
   ↓ portfolio features + propositions
cogni-workspace:text-to-narrative → Claude Design | enrich-report   (visual deliverables)
   ↓
slide deck or enriched HTML report
```

## Duration

4–8 hours for a complete trends-to-solutions analysis.

## End deliverable

Ranked solution blueprints with visual deliverables (slide deck or enriched HTML report).

## How it works

[[plugin-cogni-trends]] runs `trend-scout` to surface 60 scored trend candidates across the 4 Smarter Service Trendradar dimensions. Candidates are sourced strictly from web research — no padding from LLM training knowledge. The trend-candidate-reviewer applies stakeholder review ([[concept-quality-gates]]) before promotion.

`value-modeler` then takes agreed candidates and builds the TIPS network: **T**rends → **I**mplications → **P**ossibilities → **S**olutions. Solution templates are ranked by Business Relevance (BR) score and bundled into investment themes (Handlungsfelder).

The bridge to [[plugin-cogni-portfolio]] is the most complex single integration in the ecosystem — see [[concept-trends-portfolio-bridge]]. `tips-value-model.json` flows from cogni-trends to cogni-portfolio; `portfolio-context.json` flows back. cogni-portfolio's `trends-bridge` skill imports solution templates as portfolio features and stubs the matching FxM propositions.

[[plugin-cogni-workspace]] produces the deliverables — `text-to-narrative` with the `slides` target for a CxO presentation (one design brief handed to Claude Design), `enrich-report` for a themed HTML report with Chart.js visualizations of the TIPS network and BR scoring.

## Where TIPS comes from

The TIPS framework comes with cogni-trends — Trends, Implications, Possibilities, Solutions — and is the canonical structure for investment theme reports. See [[plugin-cogni-trends]] for framework details.

## Two scenarios

The pipeline branches at value modeling and reconverges at the visual deliverable.

- **A — Standalone.** No cogni-portfolio project. `value-modeler` anchors on the bundled generic B2B ICT portfolio (7 products, 51 features with taxonomy mappings) and generates DOES/MEANS from the research context. Taxonomy-grounded but not company-specific. Right for new-industry scouting, discovery engagements, or a CxO point of view without a defined product set.
- **B — With portfolio connected.** `trends-bridge` exports portfolio context so Solution Templates map to real products and features, and ranked solutions can flow back into the portfolio. Right when trend signals must drive an actual roadmap.

You can start in A and re-enter B later against the same scout output.

## Steps

**1 — Scout trends.** `cogni-trends:trend-scout`. Produces 60 scored candidates mapped to the Trendradar dimensions (4 dimensions × 3 action horizons). Set the region correctly for DACH/EU — the scout uses regional authority sources (Fraunhofer, BITKOM, VDMA, destatis) that an EN/US default would miss; see [[concept-multilingual-support]]. Cull 60 candidates down to 15–25 before value modeling: the quality of everything downstream depends on this step. Optionally run `trend-research` in parallel for a written CxO report.

**2 — Model investment themes and solution blueprints.** `cogni-trends:value-modeler` directly for scenario A; for scenario B run `cogni-portfolio:trends-bridge` in the portfolio-to-tips direction first, which writes `portfolio-context.json` into the pursuit, then `value-modeler`. Output is investment themes with T→I→P→S value chains, ranked Solution Templates, SPIs, success metrics and Business Relevance scoring. In scenario B, readiness scoring reflects actual portfolio gaps. Review the Business Relevance weights in either scenario — the defaults rarely match a client's strategic priorities. Three to seven themes is the producible range; narrow to three or four before generating visuals.

**3 — Backflow to the portfolio (scenario B only).** `cogni-portfolio:trends-bridge` in the tips-to-portfolio direction. Produces new features, proposition variants, evidence entries and `portfolio-opportunities.json`. Curate the generated entities in cogni-portfolio (`features`, `propositions`, `solutions`) before they propagate into pitches and marketing. This is the step that closes the loop — trend signals become portfolio mutations the team can build against. See [[concept-trends-portfolio-bridge]].

**4 — Produce visual deliverables.** `cogni-workspace:text-to-narrative` for a deck (its `design-brief.md` goes to Claude Design), or `cogni-workspace:enrich-report` for an interactive HTML report with Chart.js visualizations. Both work for either scenario — the underlying value-model JSON has the same shape. Generate the trend report before running `enrich-report`, and pick the workspace theme before rendering so visuals match brand.

## Common pitfalls

- **Weak trend selection.** Generic trends produce generic solutions. The cull in step 1 is the quality gate for the entire downstream pipeline.
- **Too many themes.** Up to seven are producible; client decks land better with three or four. Narrow before rendering.
- **Skipping Business Relevance scoring.** Default weights are not client-specific. Adjust before generating blueprints, in either scenario.
- **Mistaking generic blueprints for company-specific advice (A).** The bundled portfolio is a taxonomy scaffold — useful for framing what to do about a trend, not a substitute for grounding solutions in real capabilities.
- **Forgetting the export step (B).** Without the portfolio-to-tips bridge, `value-modeler` silently falls back to scenario A. The run "works" and the solutions reference nothing real.

**Source**: [docs/workflows/trends-to-solutions.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/docs/workflows/trends-to-solutions.md)
