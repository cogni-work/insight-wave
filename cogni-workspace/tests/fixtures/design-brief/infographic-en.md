---
type: design-brief
version: "1.1"
target: infographic
language: en
arc_id: corporate-visions
arc_display_name: "Corporate Visions"
title: "The Maintenance Budget That Buys Downtime"
governing_thought: "Scheduled maintenance is buying downtime: the operators that spend most on it lose 11 percent more production hours than those that spend least [1]."
source_narrative: corporate-visions-en.md
density:
  profile: standard
  ceilings:
    headline_words_max: 12
    subline_words_max: 15
    hero_numbers_min: 3
    hero_numbers_max: 5
    hero_label_words_max: 4
    blocks_min: 3
    blocks_max: 8
    blocks_max_dense: 14
    point_words_max: 6
    words_max: 150
    words_max_dense: 250
climax: 4
---

# The Maintenance Budget That Buys Downtime

*How should European industrial operators respond to the shift from scheduled to condition-based maintenance?*

# Rendering Contract

- Copy is frozen: reproduce every headline, label, number and point verbatim — a renderer that rewrites a line has changed the deliverable, not styled it.
- Nothing on this brief is renderer guidance to be paraphrased; every line is canvas copy, and a line that does not fit is dropped with the author, never shortened.
- Citation markers `[N]` collapse into one sources footer built from the Sources block; none stays inline on the canvas.
- Styling comes only from the theme or the renderer's own design system; the brief carries no color, font, or coordinate, and none may be inferred from its wording.
- Block `type` is a content shape: map each block to the nearest native arrangement and never split or pad a block to fill a grid.

headline: The Maintenance Budget That Buys Downtime
subline: the constraint is signal, not labour
hero_numbers:
- 11 percent — more production hours (src: [1])
- 71 percent — precursor nobody read (src: [1])
- 13.0 million euros — unplanned downtime (src: [1])
- 4.2 million euros — condition-based programme (src: [2])
- 23 percent — fewer technicians by 2030 (src: [4])

## Block 1: Reliability is an information problem

type: two-column
points:
- 62 percent had a measurable precursor [1]
- 47 sensor formats per plant [2]
- 34 percent fewer unplanned stops [1]

## Block 2: Three converging forces make action urgent

type: timeline
visual_intent:
  message_pattern: convergence
  relationship: three forces land inside the same window
  focal_point: the closing window
  preferred_expression: timeline
  asset_signal: diagram
points:
- EU Machinery Regulation from January 2027 [2]
- 23 percent fewer technicians [4]
- 8 to 12 percent insurance discounts [3]

## Block 3: Three Power Positions follow from the evidence

type: roles
points:
- Asset-Health Data Integration
- Compliance-by-Design Monitoring
- Technician Leverage

## Block 4: Action costs less than inaction by roughly 4x

type: metric
visual_intent:
  message_pattern: comparison
  relationship: acting costs a fraction of not acting
  focal_point: the gap between the two totals
  preferred_expression: metric
  asset_signal: data-chart
points:
- 17.4 million euros
- 4.2 million euros [2]
- roughly 4x

cta: redirect the scheduled budget before the January 2027 regulation lands

note: copy is frozen — reproduce every line verbatim
note: render citations as one sources footer and keep the URLs
note: attach theme.md only when no organization design system is configured
note: the blocks and their order are the deliverable — ask before adding, merging or reordering

**Sources**

[1] source-01-fraunhofer.md — Fraunhofer IPA, "Instandhaltung 2025", 2025, https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html
[2] source-02-vdma.md — VDMA, "Condition-Monitoring-Studie 2025", 2025, https://www.vdma.org/condition-monitoring-studie-2025
[3] source-03-handelsblatt.md — Handelsblatt, "Predictive Maintenance, Fachkräfte und Versicherer 2025-2026", 2026, https://www.handelsblatt.com/unternehmen/industrie/
[4] source-04-destatis.md — Destatis, "Instandhaltung 2030", 2025, https://www.destatis.de/DE/Themen/Arbeit/Arbeitsmarkt/Erwerbstaetigkeit/instandhaltung-2030.html
