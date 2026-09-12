---
library_id: references-slide
version: 1.0.0
created: 2026-09-07
---

# References Slide Generation

## Purpose

Define how to generate a consolidated References slide from inline citations, placed after the closing slide as the last slide in the deck.

---

## Construction

Using the citation renumber map from Step 2:

```text
1. COLLECT all citations from the renumber map that appear in at least one slide body text field
2. SORT by sequential number (1, 2, 3...)
3. SPLIT into two columns (left: 1 to N/2, right: N/2+1 to N)
4. FORMAT each entry as: "[N] {source_label} — {full_url}" where:
   - N is the sequential number
   - source_label is the shortest meaningful report name (from Source field labels or narrative context)
5. Each entry shows the full URL as plain text (always visible regardless of PPTX rendering)

IF total citations <= 3: Use single column (Left-Column only, Right-Column empty or omitted)
IF total citations > 12: Split across two References slides
```

---

## Output Format

**Layout:** `two-columns-equal`

## Slide N: Sources & References

```yaml
Layout: two-columns-equal
Slide-Kind: references

intent:
  role: evidence
  emphasis: none

visual:
  kind: table

Slide-Title: Sources & References

Left-Column:
  Headline: Sources 1-4
  Bullets:
    - "[1] Federal Rail Safety Report 2024 — https://eba.bund.de/report"
    - "[2] EU Rail Safety Statistics — https://railsafety.eu/study"
    - "[3] Gartner Infrastructure Report 2024 — https://gartner.com/mq"
    - "[4] BKA Crime Statistics — https://bka.de/stats"

Right-Column:
  Headline: Sources 5-8
  Bullets:
    - "[5] Deloitte ROI Analysis — https://deloitte.com/rail"
    - "[6] McKinsey Digital Rail Report — https://mckinsey.com/rail"
    - "[7] IEEE Computer Vision Review — https://ieee.org/cv-review"
    - "[8] DB Infrastruktur Bericht 2024 — https://db.com/infra"

Speaker-Notes: |
  >> WHAT YOU SAY

  [Opening]: "This slide consolidates all sources cited in the presentation."
  [Key point]: "Every quantitative claim traces back to a numbered source."
  [Transition]: "Let's move to next steps."

  >> WHAT YOU NEED TO KNOW

  - All claims were verified through the claim verification pipeline before presentation generation.
  - Citation numbers correspond to the superscript <sup>[N]</sup> markers in slide body text.
  - Full URLs are shown as plain text — always visible regardless of PPTX rendering.
```

---

## Positioning

This slide is placed AFTER the closing-slide as the **last slide in the deck**.

Since schema 4.1 it also carries `Slide-Kind: references`, so a renderer identifies it from the brief rather than inferring it from banner text or slide position.
