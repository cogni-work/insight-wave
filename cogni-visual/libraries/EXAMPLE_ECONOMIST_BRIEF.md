---
type: infographic-brief
version: "1.2"
theme: smarter-service
theme_path: "/cogni-workspace/themes/smarter-service/theme.md"
customer: "European Capital Partners"
provider: "Cogni Work"
language: "en"
generated: "2026-04-11"
layout_type: "stat-heavy"
style_preset: "economist"
orientation: "portrait"
dimensions: "1080x1528"
arc_type: "report"
arc_id: "thesis-evidence"
governing_thought: "European mid-cap industrials have a three-year window to rewire operations before capital costs lock in."
voice_tone: "analytical"
palette_override: "theme"
confidence_score: 0.92
transformation_notes: |
  Story-to-infographic transformation.
  Theme: smarter-service. Style: economist. Layout: stat-heavy. Orientation: portrait.
  Source: investment-thesis.md (4200 words) → 12 content blocks, 4 hero numbers, 1 pull-quote, 1 editorial sketch.
  Editorial family — The Economist data page tradition. Voice: analytical.
  Economist discipline applied with theme accents (palette_override: theme).
  One editorial-sketch block (cartographic outline of Europe) pairs with the refinancing chart.
---

# Infographic Brief: The European Mid-Cap Rewiring Window

This reference brief demonstrates the v1.2 infographic-brief schema for the **economist**
style preset — the editorial family, The Economist data page tradition. Notice:

- `style_preset: economist` routes to `render-infographic-pencil` via `/render-infographic`
  or the direct `/render-infographic-editorial` command.
- `voice_tone: analytical` signals the renderer to keep section subheads dry and measured.
- `palette_override: theme` means the renderer uses the project theme's primary and secondary
  colors as the two editorial accents on near-black text and cream surface — Economist
  **discipline**, wearing the brand.
- Dense 10–14 block layout (economist is the only preset that allows 250-word density).
- A single `pull-quote` block — the editorial signature move.
- A single `svg-diagram` block in **editorial-sketch mode** (v1.2) — a one-color outline
  of Europe that sits beside the refinancing chart and makes the geographic scope concrete.

---

## Title Block

```yaml
Block-Type: title
Headline: "Europe's mid-cap industrials have three years to rewire"
Subline: "Capital costs are about to lock in — and the window will not reopen"
Metadata: "European Capital Partners | Cogni Work | April 2026"
```

---

## Block 1: The Hero Ratio

```yaml
Block-Type: kpi-card
Hero-Number: "36 mo"
Hero-Label: "rewiring window"
Sublabel: "before refinancing locks capex into legacy tooling"
Icon-Prompt: "hourglass with narrowing sand"
Source: "ECP model, Q1 2026"
```

---

## Block 2: Supporting KPIs

```yaml
Block-Type: stat-row
Stats:
  - number: "€4.2tn"
    label: "mid-cap book value"
    icon-prompt: "stack of coins"
  - number: "62%"
    label: "pre-digital processes"
    icon-prompt: "factory chimney"
  - number: "4.9%"
    label: "terminal financing spread"
    icon-prompt: "arrow up right"
```

---

## Block 3: The Data That Matters

```yaml
Block-Type: chart
Chart-Type: bar
Chart-Title: "Capex lock-in by refinancing year"
Data:
  labels: ["2026", "2027", "2028", "2029", "2030"]
  datasets:
    - label: "% of mid-cap debt refinancing"
      values: [8, 19, 34, 27, 12]
```

---

## Block 3b: Editorial Landmark (Europe outline)

```yaml
Block-Type: svg-diagram
Mode: editorial-sketch
Sketch-Subtype: cartographic-outline
Subject: "Outline of continental Europe with small dot markers on 5 mid-cap industrial centres (Ruhr, Lyon, Milan, Gothenburg, Katowice)"
Data-Link: block-3
Caption: "MID-CAP SCOPE"
Max-Width-Ratio: 0.33
```

Why this block earns its place: the refinancing chart (block 3) is entirely about European
mid-cap industrials, but the chart alone shows percentages without naming *where*. The
editorial sketch — a one-color outline of Europe with five small dot markers on the main
industrial centres — turns the abstract number into a concrete geography. The renderer
will place it to the right of the chart (chart bars grow left-to-right, so the sketch sits
on the trailing edge), at 33% of the row width, with the caption "MID-CAP SCOPE" in the
primary accent above the sketch frame. No text inside the sketch itself — the city names
are implicit in the dot positions, because the chart's adjacent text handles any explicit
labels. This is how editorial sketches earn their place: they make the data read faster
without carrying independent information.

---

## Block 4: Why This Window Closes

```yaml
Block-Type: text-block
Headline: "The refinancing wall is a rewiring deadline"
Body: "Once mid-cap issuers refinance at 2028–29 spreads, capex envelopes calcify around existing operations. New tooling investments become impossible without balance-sheet restructuring. The window closes not with a crisis, but with a signature."
Icon-Prompt: "door closing slowly"
```

---

## Block 5: Who Is Already Moving

```yaml
Block-Type: stat-row
Stats:
  - number: "23"
    label: "mid-caps with AI cost targets"
    icon-prompt: "check circle"
  - number: "€840m"
    label: "aggregated 2025 rewiring capex"
    icon-prompt: "euro symbol"
  - number: "11x"
    label: "median payback multiple"
    icon-prompt: "trending up chart"
```

---

## Block 6: The Editorial Voice (Pull-Quote)

```yaml
Block-Type: pull-quote
Quote-Text: "We are not buying companies that own their future. We are buying companies that still have the option to."
Attribution: "Chief Investment Officer, ECP"
Emphasis: "still have the option to"
Source: "Investment committee minutes, March 2026"
```

---

## Block 7: Two Paths (Comparison)

```yaml
Block-Type: comparison-pair
Left:
  label: "Wait & Refinance"
  icon-prompt: "locked padlock"
  bullets:
    - "Lower headline capex"
    - "No operational disruption"
    - "Capex locked at 2029 spread"
    - "Digital gap widens structurally"
Right:
  label: "Rewire Before the Wall"
  icon-prompt: "unlocked padlock"
  bullets:
    - "Higher front-loaded capex"
    - "Operational turbulence Y1-Y2"
    - "Refinancing at cleaner multiples"
    - "Strategic optionality preserved"
```

---

## Block 8: Supporting Context

```yaml
Block-Type: text-block
Headline: "Analogues from the 2012–2015 energy rewiring cycle"
Body: "Operators that upgraded before the 2015 refinancing window outperformed peers by 340 basis points through 2020. The same pattern holds for every capital cycle we have examined since 1998."
Icon-Prompt: "history book"
```

---

## CTA Block

```yaml
Block-Type: cta
Headline: "Review the full thesis and model"
CTA-Text: "Request briefing"
CTA-Type: evaluate
CTA-Urgency: high
```

---

## Footer Block

```yaml
Block-Type: footer
Left: "European Capital Partners"
Center: "April 2026"
Right: "Cogni Work"
Source-Line: "Sources: ECP proprietary model, Bloomberg mid-cap universe Q1 2026, ECB refinancing wall projections 2025"
```

---

## Generation Metadata

```yaml
blocks_total: 11
blocks_content: 8
number_plays: 4
icon_prompts: 12
pull_quotes: 1
charts: 1
word_count_total: 218
distillation_ratio: "4200 words → 218 words (94.8% reduction)"
layout_confidence: 0.93
style_confidence: 0.90
voice_tone_confidence: 0.88
palette_mode: "theme (Economist discipline applied to smarter-service palette)"
```
