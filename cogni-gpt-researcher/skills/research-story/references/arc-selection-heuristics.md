---
title: Arc Selection Heuristics
type: reference
category: pipeline
tags: [arc-selection, auto-detection, story-arc, research-story]
---

# Arc Selection Heuristics

When `--arc-id` is not provided, auto-detect the best arc from the research report content. The detection algorithm analyzes section headers, key phrases, and topic signals to match against arc profiles.

## Signal Table

Each arc has a set of keyword signals. Count matches in the report's section headers and first 500 words. The arc with the highest weighted match wins.

| Arc ID | Primary Signals (weight 2x) | Secondary Signals (weight 1x) | Typical Research Types |
|--------|----------------------------|------------------------------|----------------------|
| `corporate-visions` | ROI, business case, value proposition, cost reduction, revenue, pricing, B2B, sales | market opportunity, customer, adoption, investment, TCO, competitive advantage | Market research, sales enablement, business justification |
| `technology-futures` | emerging technology, innovation, R&D, prototype, AI, quantum, biotech, breakthrough | roadmap, maturity, adoption curve, proof of concept, technical feasibility | Technology scouting, R&D strategy, innovation analysis |
| `competitive-intelligence` | competitor, market share, vendor, benchmark, positioning, SWOT, rivalry | pricing strategy, product comparison, market entry, differentiation, win rate | Vendor analysis, competitive landscape, market positioning |
| `strategic-foresight` | scenario, uncertainty, forecast, future, risk, resilience, disruption | planning horizon, strategic options, contingency, probability, wildcard | Scenario planning, risk analysis, long-range strategy |
| `industry-transformation` | regulation, compliance, DORA, GDPR, digital transformation, disruption, mandate | industry shift, workforce, standardization, policy, ecosystem change | Regulatory impact, industry analysis, transformation roadmaps |
| `trend-panorama` | trend, megatrend, signal, horizon, TIPS, macro, shift, trajectory | forces, convergence, implications, time horizon, adoption wave | Trend reports, market outlook, strategic radar |

## Detection Algorithm

1. Extract report section headers (all `##` and `###` lines)
2. Extract first 500 words of report body (below any frontmatter)
3. For each arc, count:
   - Primary signal matches × 2
   - Secondary signal matches × 1
4. Normalize by total signals per arc (some arcs have more signals)
5. Select the arc with the highest normalized score
6. If highest score < 0.1 (weak match), fall back to `corporate-visions`

## Report Type Boosters

Certain `--type` values boost specific arcs:

| Report Type | Arc Boost (+0.3 to normalized score) |
|-------------|--------------------------------------|
| `basic` + B2B topic | `corporate-visions` |
| `detailed` + technology topic | `technology-futures` |
| `deep` + multi-sector | `strategic-foresight` |

## Language Consideration

For `--language de`, also check German equivalents of signals:
- "Wettbewerb" → competitive-intelligence
- "Regulierung", "Verordnung" → industry-transformation
- "Innovation", "Forschung" → technology-futures
- "Geschäftsfall", "Rendite" → corporate-visions
- "Trend", "Megatrend" → trend-panorama
- "Szenario", "Zukunft" → strategic-foresight
