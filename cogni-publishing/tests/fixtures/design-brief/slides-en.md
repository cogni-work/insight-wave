---
type: design-brief
version: "1.1"
target: slides
language: en
arc_id: corporate-visions
arc_display_name: "Corporate Visions"
title: "The Maintenance Budget That Buys Downtime"
governing_thought: "Scheduled maintenance is buying downtime: the operators that spend most on it lose 11 percent more production hours than those that spend least [1]."
source_narrative: corporate-visions-en.md
density:
  profile: standard
  ceilings:
    headline_chars_max: 110
    slide_points_max_lines: 4
    slide_point_words_max: 10
    slide_point_words_max_table: 20
    talk_track_words_min: 150
    talk_track_words_max: 450
    units_min: 5
    units_max_default: 15
design:
  register: quiet-executive
  dark_slides: [1, 7]
  speaker_notes: full-script
  imagery: none
  variations: 1
key_figures:
  - "11 percent more production hours (src: [1])"
  - "71 percent of those cases the data existed but was not read (src: [1])"
  - "23 percent decline in qualified industrial maintenance technicians (src: [4])"
  - "13.0 million euros (src: [1])"
  - "4.2 million euros (src: [2])"
climax: 7
---

# The Maintenance Budget That Buys Downtime

*How should European industrial operators respond to the shift from scheduled to condition-based maintenance?*

# Rendering Contract

- Copy is frozen: reproduce every headline, bullet, number and label verbatim — a renderer that rewrites a line has changed the deliverable, not styled it.
- The talk track travels complete into the renderer's native notes channel; truncated or summarized notes are an incorrect rendering.
- Citation markers `[N]` become hyperlink runs on the number, and a sources slide built from the Sources block stays last in the deck.
- Styling comes only from the theme or the renderer's own design system; the brief carries no color, font, or coordinate, and none may be inferred from its wording.
- `type` is a content shape: map each unit to the nearest native layout and never invent content to fill one.

## Slide 1: The Maintenance Budget That Buys Downtime

type: bluf
visual_intent:
  message_pattern: decision
  relationship: the maintenance budget and the lost production hours move together
  focal_point: the redirect of the budget before the deadline
  preferred_expression: metric
  asset_signal: none
slide_points:
- lose 11 percent more production hours [1]
- 71 percent of the failures had a readable sensor precursor [1]
- The constraint is signal, not labour
- costs roughly a quarter of what inaction costs

talk_track:
How should European industrial operators respond to the shift from scheduled to condition-based maintenance? Scheduled maintenance is buying downtime: the operators that spend most on it lose 11 percent more production hours than those that spend least [1]. The reason is that 71 percent of the failures had a readable sensor precursor nobody read [1], so the constraint is signal, not labour. Operators should redirect the scheduled budget into one asset-health view and a compliance-by-design monitoring process before the January 2027 regulation lands. Over three years that costs roughly a quarter of what inaction costs.

## Slide 2: Reliability is an information problem, not a spending problem

type: two-column
element: 1
visual_intent:
  message_pattern: shift
  relationship: the constraint has moved from spending to information
  focal_point: the move from spending to information
  preferred_expression: comparison
  asset_signal: data-chart
slide_points:
- Spend buys interventions that land on the wrong asset [1]
- 62 percent of unplanned stops had a measurable precursor [1]
- 47 sensor formats per plant already exist [2]
- 34 percent fewer unplanned stops [1]

talk_track:
Most operators think reliability is a spending problem: more inspections, shorter intervals, larger spare inventories. The evidence shows it is an information problem. The operators that spend most on scheduled maintenance lose 11 percent more production hours than those that spend least [1]. In the same sample, 62 percent of unplanned stops had a measurable precursor in sensor data at least 48 hours before failure, and in 71 percent of those cases the data existed but was not read [1]. Scheduled work replaces parts on a calendar rather than on evidence of wear, so budget flows to components that were not failing while the components that were failing go unmonitored [2]. The unconsidered reality is that the constraint has moved from labour to signal. Operators already generate an average of 47 sensor formats per plant across drives, bearings, pumps and control systems [2], and the plants that convert those signals into a single asset-health view report 34 percent fewer unplanned stops than those that do not [1]. Early recognizers gain twice. They redirect the scheduled-maintenance budget that was buying downtime, and they build an operational data asset competitors cannot buy retroactively — three years of labelled failure history is worth more than any platform licence [3].

## Slide 3: Three converging forces make action urgent

type: timeline
element: 2
visual_intent:
  message_pattern: convergence
  relationship: three independent forces land inside the same window
  focal_point: the closing window
  preferred_expression: timeline
  asset_signal: diagram
slide_points:
- EU Machinery Regulation applies in full from January 2027 [2]
- 23 percent decline in qualified maintenance technicians by 2030 [4]
- Insurers price condition monitoring: 8 to 12 percent discounts [3]

talk_track:
Three converging forces make action urgent. First, the EU Machinery Regulation applies in full from January 2027 and requires operators of connected industrial equipment to demonstrate a documented condition-monitoring process for safety-relevant assets; the VDMA estimates the average compliance gap at 14 months of implementation work [2]. An operator that starts in 2026 meets the deadline. One that starts in 2027 does not, and pays the retrofit premium described below. Second, the maintenance workforce is leaving faster than it is replaced. Destatis projects a 23 percent decline in qualified industrial maintenance technicians in Germany between 2025 and 2030 [4], and the wage premium for those who remain has already risen 18 percent in two years [3]. Third, the insurance market has started pricing the difference. Two of the three largest industrial insurers in the DACH region introduced condition-monitoring discounts of 8 to 12 percent on business-interruption cover in 2025 and have announced surcharges for unmonitored critical assets from 2027 [3]. The window is closing from both sides: early movers lock in the discount while late starters absorb the surcharge on top of the compliance scramble.

## Slide 4: Three Power Positions follow from the evidence

type: roles
element: 3
visual_intent:
  message_pattern: composition
  relationship: three positions that hold together as one capability
  focal_point: the set of three rather than any one
  preferred_expression: matrix
  asset_signal: none
  avoid: vendor-logo-wall
slide_points:
- Asset-Health Data Integration
- Compliance-by-Design Monitoring
- Technician Leverage

talk_track:
Organizations that thrive do not just react to these forces — they build capabilities. Three Power Positions follow from the evidence. Asset-Health Data Integration is a single asset-health model that ingests every sensor format a plant already produces, built on the plant's own failure history rather than a vendor's generic library. You detect degradation patterns 48 to 72 hours before failure and schedule the intervention in the next planned shift window instead of the next emergency [1]. Competitors struggle to copy it because the 47-format ingestion layer and the labelled failure history take 18 to 24 months to accumulate, and monitoring products that read 8 to 12 formats miss the long tail where 60 percent of failure signals originate [2]. Compliance-by-Design Monitoring is a condition-monitoring process documented against the 2027 regulation from the first asset onward, rather than retrofitted before an audit. You clear the regulatory requirement as a by-product of the reliability programme, and your audit evidence is the same data your planners already use [2]. Technician Leverage is a maintenance operating model in which scarce technicians act on ranked asset-health alerts rather than on interval lists. You cut unnecessary interventions by roughly a third and redirect that capacity to the failures that matter [1].

## Slide 5: The compound cost of inaction is 17.4 million euros

type: table
element: 4
visual_intent:
  message_pattern: distribution
  relationship: four stacked costs on one horizon
  focal_point: the total they add to
  preferred_expression: table
  asset_signal: data-chart
slide_points:
- Unplanned downtime: 13.0 million euros [1]
- Technician wage premium: 2.1 million euros [4]
- Insurance surcharges: 0.9 million euros [3]
- Compliance retrofit: 1.4 million euros against 0.6 million planned [2]

talk_track:
The cost of delay compounds. Over a three-year horizon a mid-sized operator with 40 critical assets faces four stacked costs of inaction, each on the same horizon so they can be added. Unplanned downtime at the sample average of 180,000 euros per lost production hour and 24 hours per year adds up to 13.0 million euros [1]. The technician wage premium on a 60-person maintenance team adds 2.1 million euros [4]. Insurance surcharges on unmonitored critical assets from 2027 add 0.9 million euros [3]. A compliance retrofit under deadline pressure adds 1.4 million euros against 0.6 million for a planned programme [2]. The compound cost of inaction is 17.4 million euros. A condition-based programme built on the three positions above costs 4.2 million euros over the same three years, including integration, documentation and the operating-model change [2]. Set against 17.4 million, the comparison needs no explanation. Action costs less than inaction by roughly 4x.

## Slide 6: Action costs less than inaction by roughly 4x

type: metric
visual_intent:
  message_pattern: comparison
  relationship: acting costs a fraction of not acting
  focal_point: the gap between the two totals
  preferred_expression: metric
  asset_signal: data-chart
slide_points:
- 17.4 million euros: the compound cost of inaction
- 4.2 million euros: a condition-based programme [2]
- 4x

talk_track:
A condition-based programme built on the three positions above costs 4.2 million euros over the same three years, including integration, documentation and the operating-model change [2]. Set against 17.4 million, the comparison needs no explanation.

## Slide 7: Redirect the scheduled budget before January 2027

type: bluf
visual_intent:
  message_pattern: decision
  relationship: one decision taken before the deadline
  focal_point: the decision itself
  preferred_expression: none
  asset_signal: none
slide_points:
- Redirect the scheduled budget into one asset-health view
- Build a compliance-by-design monitoring process
- Act before the January 2027 regulation lands

talk_track:
Operators should redirect the scheduled budget into one asset-health view and a compliance-by-design monitoring process before the January 2027 regulation lands. Over three years that costs roughly a quarter of what inaction costs.

## Slide 8: Sources

type: sources

talk_track:
The deck's source register, built by the renderer from the trailing Sources block verbatim. Every citation marker on the preceding slides resolves here.

note: copy is frozen — reproduce every line verbatim
note: render citations as footnotes and keep the URLs
note: attach theme.md only when no organization design system is configured
note: the units and their order are the deliverable — ask before adding, merging or reordering

**Sources**

[1] source-01-fraunhofer.md — Fraunhofer IPA, "Instandhaltung 2025", 2025, https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html
[2] source-02-vdma.md — VDMA, "Condition-Monitoring-Studie 2025", 2025, https://www.vdma.org/condition-monitoring-studie-2025
[3] source-03-handelsblatt.md — Handelsblatt, "Predictive Maintenance, Fachkräfte und Versicherer 2025-2026", 2026, https://www.handelsblatt.com/unternehmen/industrie/
[4] source-04-destatis.md — Destatis, "Instandhaltung 2030", 2025, https://www.destatis.de/DE/Themen/Arbeit/Arbeitsmarkt/Erwerbstaetigkeit/instandhaltung-2030.html
