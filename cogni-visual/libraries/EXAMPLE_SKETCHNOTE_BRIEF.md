---
type: infographic-brief
version: "1.1"
theme: smarter-service
theme_path: "/cogni-workspace/themes/smarter-service/theme.md"
customer: "Raiffeisen Regional"
provider: "Cogni Work"
language: "de"
generated: "2026-04-11"
layout_type: "timeline-flow"
style_preset: "sketchnote"
orientation: "landscape"
dimensions: "1528x1080"
arc_type: "journey"
arc_id: "problem-solution"
governing_thought: "Ein 6-Wochen-Workshop verwandelt ein zerfasertes Kundenteam in eine gemeinsame Stimme am Markt."
voice_tone: "playful"
palette_override: "theme"
confidence_score: 0.87
transformation_notes: |
  Story-to-infographic transformation.
  Theme: smarter-service. Style: sketchnote. Layout: timeline-flow.
  Source: Workshop-Retrospektive (1800 Wörter) → 5 Schritte + 1 Pull-Quote + 2 KPI-Karten.
  Hand-drawn family — Mike Rohde graphic recording tradition. Voice: playful (Workshop-Rückschau).
---

# Infographic Brief: Vom Team-Silo zur gemeinsamen Marktstimme

This reference brief demonstrates the v1.1 infographic-brief schema for the **sketchnote**
style preset — the hand-drawn family, Mike Rohde / graphic recording tradition. Notice:

- `style_preset: sketchnote` routes to `render-infographic-sketchnote` via
  `/render-infographic` or the direct `/render-infographic-handdrawn` command.
- `voice_tone: playful` signals the renderer to use warmer, looser hand-lettering.
- A `pull-quote` block carries a verbatim workshop participant voice — a natural fit for
  sketchnote's speech-bubble treatment.
- `layout_type: timeline-flow` carries the 5-week workshop journey as connected steps.

---

## Title Block

```yaml
Block-Type: title
Headline: "Aus sechs Wochen wird eine Stimme am Markt"
Subline: "Wie ein Workshop das Regional-Team neu ausrichtet"
Metadata: "Raiffeisen Regional | Cogni Work | April 2026"
```

---

## Block 1: Ausgangssituation (Hero KPI)

```yaml
Block-Type: kpi-card
Hero-Number: "14"
Hero-Label: "unterschiedliche Pitches"
Sublabel: "bevor der Workshop startete"
Icon-Prompt: "tangled lines, scattered voices"
Source: "Team-Audit Februar 2026"
```

---

## Block 2: Workshop-Reise (Prozess-Strip)

```yaml
Block-Type: process-strip
Steps:
  - label: "Zuhören"
    icon-prompt: "ear with soundwaves"
  - label: "Sortieren"
    icon-prompt: "hand with sticky notes"
  - label: "Zuspitzen"
    icon-prompt: "arrow converging to point"
  - label: "Erproben"
    icon-prompt: "rocket taking off"
  - label: "Vereinbaren"
    icon-prompt: "handshake with heart"
```

---

## Block 3: Stimme aus dem Team (Pull-Quote)

```yaml
Block-Type: pull-quote
Quote-Text: "Zum ersten Mal sage ich dasselbe wie mein Kollege aus der Nachbargruppe."
Attribution: "Vertriebsberaterin, Woche 5"
Emphasis: "dasselbe wie mein Kollege"
Source: "Workshop-Feedback, März 2026"
```

---

## Block 4: Ergebnis (zweiter Hero-KPI)

```yaml
Block-Type: kpi-card
Hero-Number: "1"
Hero-Label: "gemeinsame Kernbotschaft"
Sublabel: "von allen 14 Beratern verwendet"
Icon-Prompt: "many dots merging into one star"
Source: "Messung Kalenderwoche 14, 2026"
```

---

## CTA Block

```yaml
Block-Type: cta
Headline: "Nächsten Workshop planen"
CTA-Text: "Termin finden"
CTA-Type: commit
CTA-Urgency: medium
```

---

## Footer Block

```yaml
Block-Type: footer
Left: "Raiffeisen Regional"
Center: "April 2026"
Right: "Cogni Work"
Source-Line: "Quelle: Workshop-Retrospektive und Team-Messungen, Raiffeisen Regional 2026"
```

---

## Generation Metadata

```yaml
blocks_total: 7
blocks_content: 4
number_plays: 2
icon_prompts: 7
pull_quotes: 1
word_count_total: 58
distillation_ratio: "1800 words → 58 words (96.8% reduction)"
layout_confidence: 0.91
style_confidence: 0.88
voice_tone_confidence: 0.82
```
