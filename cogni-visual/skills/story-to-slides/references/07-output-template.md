# Output Template Reference

## Slide YAML Example

Every slide follows this content-only YAML pattern. No color fields (`Background:`, `Text-Color:`, `Icon-Color:`, `Role:`, `Intensity:`, `Mood:`) — the PPTX skill reads the theme directly.

```yaml
## Slide 3: 688 Lives Lost Annually to Preventable Rail Incidents

Layout: stat-card-with-context

Slide-Title: 688 Lives Lost Annually to Preventable Rail Incidents

Hero-Stat-Box:
  Number: 688
  Label: rail suicides per year
  Sublabel: + 2,661 attacks on stations
  Icon: shield

Context-Box:
  Headline: Why manual monitoring fails
  Bullets:
    - Security staff cannot cover all areas 24/7 <sup>[1](https://eba.bund.de/report)</sup>
    - Critical events detected too late to intervene <sup>[2](https://railsafety.eu/study)</sup>
    - Network too large for point-based surveillance

Bottom-Banner:
  Text: Germany leads EU statistics in rail incidents

Speaker-Notes: |
  >> WHAT YOU SAY
  [Opening]: "Ask: 'How many preventable deaths on German rails annually?'"
  [Key point]: "688 is a 3-year average — trend rising: 612, 679, now 773."
  [Pause]: Let the number sink in.
  [Transition]: "These numbers make the 'why now' question unavoidable..."

  >> WHAT YOU NEED TO KNOW
  - Source: [Federal Rail Safety Report 2024](https://eba.bund.de/report)
  - If asked about regional variance: Bavaria = 23% of incidents
  - The 2,661 attacks figure comes from [BKA Statistics](https://bka.de/stats), not rail safety data

Source: "[Federal Rail Safety Report 2024](https://eba.bund.de/sicherheitsbericht-2024)"
```

The slide heading (`## Slide N: ...`) contains the **assertion headline**, not a topic label.

---

## Brief Output Template

The final brief uses this structure. Read it before writing Step 9 output.

```yaml
---
type: presentation-brief
version: "4.0"
theme: {theme_context.theme_id}
theme_path: "{theme_context.theme_path}"
customer: "{customer_name}"
provider: "{provider_name}"
language: "{language}"
generated: "{date}"
arc_type: "{detected_or_specified_arc}"
arc_id: "{arc_id if resolved, omit if not}"
governing_thought: "{single-sentence argument}"
confidence_score: {avg_confidence}
transformation_notes: |
  Story-to-slides transformation.
  Theme: {theme_id}. Arc: {arc_type}.
  {N} slides, {avg}% avg confidence.
  {number_plays} number plays, {headlines_optimized} headlines optimized.
---

# Presentation Brief: {title}

{governing_thought}

# PPTX Rendering Requirements
{IF language == "en":}
- All text and numbers are user-approved and must be reproduced exactly; deviations produce an incorrect presentation.
- Speaker notes must be included completely; truncated notes produce an incorrect presentation.
- Source citations must be preserved with working links; a presentation without source links is incorrect.
- Superscript links like <sup>[1](url)</sup> must be rendered as PPTX hyperlinks with the number as display text in superscript; unresolved links are errors.
{IF language == "de":}
- Texte und Zahlen sind freigegeben und exakt zu übernehmen; Abweichungen führen zu einer fehlerhaften Präsentation.
- Notizen für Slides müssen vollständig übernommen werden; gekürzte Notizen führen zu einer fehlerhaften Präsentation.
- Quellenangaben müssen mit funktionierenden Links erhalten bleiben; eine Präsentation ohne Quellenlinks ist fehlerhaft.
- Hochgestellte Links wie <sup>[1](url)</sup> müssen als PPTX-Hyperlinks mit der Zahl als Anzeigetext in Hochstellung erstellt werden; nicht umgesetzte Links sind Fehler.

---

## Slide 1: {message headline}
Layout: title-slide
Title: {title}
Subtitle: {subtitle}
Metadata: {customer} | {provider} | {date}

---

## Slide 2: {methodology_headline}
Layout: process-flow
Diagram: |
  graph LR
    P0["{phase_0}"] --> P1["{phase_1}"] --> P2["{phase_2}"] --> P3["{phase_3}"] --> P4["{phase_4}"]
Detail-Grid:
  P0: [... key concepts ...]
  P1: [... key concepts ...]
  {... etc ...}
Bottom-Banner:
  Text: "{INTERNAL_WARNING}"
Speaker-Notes: |
  {... comprehensive coaching on delivery arc and pacing ...}

---

## Slide 3: {buying_center_headline}
Layout: four-quadrants
{... text-card mode: Q1-Q4 with Label, Sublabel, Bullets per stakeholder, conditional on Rich audience mode ...}
Bottom-Banner:
  Text: "{INTERNAL_WARNING}"
Speaker-Notes: |
  {... comprehensive coaching on stakeholder analysis ...}

---

## Slide 4: {first content slide headline}
Layout: {layout}
[... content-only YAML, no color or annotation fields ...]

---

[... problem and urgency slides ...]

---

<!-- WHY-CHANGE ARC: Solution Overview slide (MANDATORY) — placed between urgency and Power Positions -->
## Slide N: {solution_concept_assertion_headline}
Layout: two-columns-equal

Slide-Title: {Assertion headline describing the overall solution concept}

Left-Column:
  Headline: {localized: "What We Propose" / "Unser Ansatz"}
  Bullets:
    - {High-level solution approach}
    - {Key architectural principle}
    - {Overall platform concept}

Right-Column:
  Headline: {localized: "How It Maps to Your Needs" / "Bezug zu Ihren Anforderungen"}
  Bullets:
    - {Maps to first unconsidered need}
    - {Maps to second unconsidered need}
    - {Overall business impact promise}

Bottom-Banner:
  Text: {Summarizing statement connecting solution to identified needs}

Speaker-Notes: |
  >> {WHAT YOU SAY / WAS SIE SAGEN}
  [Energy: Medium-High — RELEASE moment. Shift tone from crisis to confidence.]
  [Opening]: "Here is what we propose..."
  [Key point]: "{Solution is a platform, not a point product}"
  [Transition]: "Let me show you how each component delivers on this promise..."

  >> {WHAT YOU NEED TO KNOW / WAS SIE WISSEN MUESSEN}
  - This overview orients the audience BEFORE Power Position detail
  - Source: 03-why-you/narrative.md Executive Summary

---

## Slide N+1: {first_power_position_headline}
Layout: is-does-means
[... Power Position slides follow ...]

---

[... investment, references, closing slides ...]

---

## Generation Metadata

**Story Arc:** {arc_type}
**Governing Thought:** {governing_thought}

**Message Architecture:**
- Slides: {N} | Arguments: {N} | Consolidation: {yes/no}

**Copywriting Applied:**
- Number plays: {count} | Headlines optimized: {count}
- Bullets consolidated: {count} | Speaker notes: {count} slides
- Source links: {count} | Internal prep: {count}

**Layout Distribution:** {layout_type}: {count} [...]
**Average Confidence:** {score}
**Manual Review:** {slide list if any}

**Validation:** Schema: {p/f} | Messages: {p/f} | Copy: {p/f} | Logic: {p/f} | Integrity: {p/f}
```

---

## Citation Handling Rules

### Source field generation priority (per slide)

1. Inline citation with URL `[label](url)` — use directly as Source value
2. Superscript `<sup>[N]</sup>` — resolve footnote URL at bottom of narrative, then generate Source
3. Shortform `[P1-1]` without URL — omit Source field (no clickable link possible)
4. No citation at all — omit Source field

**Label formatting:** Use the shortest meaningful label — report name + year, not the full title. German report names stay in German.

### Preservation rules

- NEVER modify citation URLs — pass through unchanged
- RENUMBER citation IDs sequentially across all slides: original `[P1-1](url)`, `[P2-3](url)` become `[1](url)`, `[2](url)`, `[3](url)` etc. Apply the renumber map consistently to body text, Source fields, and Speaker-Notes
- PRESERVE inline citations as **superscript** in slide body text fields where claims appear: Context-Box Bullets, Left/Right Column Bullets, IS/DOES/MEANS Box Text, Option Features. Format: `<sup>[N](url)</sup>` placed immediately after the claim it supports.
- **Exclusion zones** — these fields must NOT contain citation markers:
  - Headlines (Slide-Title, Context-Box Headline, Column Headlines)
  - Bottom-Banner Text
  - Hero-Stat-Box Number, Label, and Sublabel
  - Step Labels and Step Numbers (timeline-steps)
- Generate `Source` field per slide using the primary citation URL (supplementary slide-level attribution)
- Include citations as regular inline markdown links `[N](url)` in Speaker-Notes "WHAT YOU NEED TO KNOW" section (NO superscript in notes — notes are text-only)
- Build a consolidated citation registry during extraction for the References slide (Step 7b)

### Why-Change Arc: Solution Overview Slide

For why-change arcs, a Solution Overview slide is MANDATORY between urgency and Power Position slides. It uses `two-columns-equal` layout with "What We Propose" / "How It Maps to Your Needs" columns. This slide orients the audience before detailed Power Position slides.
