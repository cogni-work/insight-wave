---
type: design-brief
version: "1.1"
target: web
language: en
arc_id: corporate-visions
arc_display_name: "Corporate Visions"
title: "The Maintenance Budget That Buys Downtime"
governing_thought: "Scheduled maintenance is buying downtime: the operators that spend most on it lose 11 percent more production hours than those that spend least [1]."
source_narrative: corporate-visions-en.md
density:
  profile: standard
  ceilings:
    hero_headline_words_max: 10
    hero_subline_words_max: 25
    section_headline_words_max: 12
    headline_chars_max: 70
    section_body_words_max: 50
    bullet_words_max: 8
    quote_words_max: 30
    attribution_words_max: 10
    sections_min: 6
    sections_max: 10
design:
  register: quiet-executive
  imagery: none
  variations: 1
key_figures:
  - "11 percent more production hours (src: [1])"
  - "23 percent decline in qualified industrial maintenance technicians (src: [4])"
  - "13.0 million euros (src: [1])"
  - "4.2 million euros (src: [2])"
climax: 6
---

# The Maintenance Budget That Buys Downtime

*How should European industrial operators respond to the shift from scheduled to condition-based maintenance?*

# Rendering Contract

- Copy is frozen: reproduce every headline, sentence, number and bullet verbatim — a renderer that rewrites a line has changed the deliverable, not styled it.
- Every section's body travels complete onto the page; nothing collapses into a tooltip, an accordion or a read-more.
- Citation markers `[N]` become footnote anchors, and a sources section built from the Sources block closes the page.
- Styling comes only from the theme or the renderer's own design system; the brief carries no color, font, or coordinate, and none may be inferred from its wording.
- Section `type` is a content shape: map each section to the nearest native pattern and never add a section to fix the rhythm.

hero:
  headline: The Maintenance Budget That Buys Downtime
  subline: the operators that spend most on it lose 11 percent more production hours than those that spend least [1]

## Section 1: Reliability is an information problem

type: bluf
body:
The evidence shows it is an information problem. The operators that spend most on scheduled maintenance lose 11 percent more production hours than those that spend least [1].

## Section 2: The constraint has moved from labour to signal

type: two-column
visual_intent:
  message_pattern: shift
  relationship: the constraint has moved from labour to signal
  focal_point: the move itself
  preferred_expression: comparison
  asset_signal: data-chart
body:
Operators already generate an average of 47 sensor formats per plant across drives, bearings, pumps and control systems [2], and the plants that convert those signals into a single asset-health view report 34 percent fewer unplanned stops than those that do not [1].

## Section 3: Three converging forces make action urgent

type: timeline
visual_intent:
  message_pattern: convergence
  relationship: three forces land inside the same window
  focal_point: the closing window
  preferred_expression: timeline
  asset_signal: diagram
body:
An operator that starts in 2026 meets the deadline. One that starts in 2027 does not, and pays the retrofit premium described below.
bullets:
- EU Machinery Regulation from January 2027 [2]
- 23 percent decline in qualified technicians [4]
- 8 to 12 percent insurance discounts [3]

## Section 4: Three Power Positions follow from the evidence

type: roles
body:
Organizations that thrive do not just react to these forces — they build capabilities.
bullets:
- Asset-Health Data Integration
- Compliance-by-Design Monitoring
- Technician Leverage

## Section 5: The compound cost of inaction is 17.4 million euros

type: table
body:
A compliance retrofit under deadline pressure adds 1.4 million euros against 0.6 million for a planned programme [2]. The compound cost of inaction is 17.4 million euros.
bullets:
- Unplanned downtime: 13.0 million euros [1]
- Technician wage premium: 2.1 million euros [4]
- Insurance surcharges: 0.9 million euros [3]

## Section 6: Action costs less than inaction by roughly 4x

type: metric
visual_intent:
  message_pattern: comparison
  relationship: acting costs a fraction of not acting
  focal_point: the gap between the two totals
  preferred_expression: metric
  asset_signal: data-chart
body:
A condition-based programme built on the three positions above costs 4.2 million euros over the same three years, including integration, documentation and the operating-model change [2].

cta: redirect the scheduled budget before the January 2027 regulation lands

note: copy is frozen — reproduce every line verbatim
note: render citations as footnotes and keep the URLs
note: attach theme.md only when no organization design system is configured
note: the sections and their order are the deliverable — ask before adding, merging or reordering

**Sources**

[1] source-01-fraunhofer.md — Fraunhofer IPA, "Instandhaltung 2025", 2025, https://www.ipa.fraunhofer.de/de/publikationen/instandhaltung-2025.html
[2] source-02-vdma.md — VDMA, "Condition-Monitoring-Studie 2025", 2025, https://www.vdma.org/condition-monitoring-studie-2025
[3] source-03-handelsblatt.md — Handelsblatt, "Predictive Maintenance, Fachkräfte und Versicherer 2025-2026", 2026, https://www.handelsblatt.com/unternehmen/industrie/
[4] source-04-destatis.md — Destatis, "Instandhaltung 2030", 2025, https://www.destatis.de/DE/Themen/Arbeit/Arbeitsmarkt/Erwerbstaetigkeit/instandhaltung-2030.html
