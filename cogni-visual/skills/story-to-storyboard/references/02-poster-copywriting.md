# Poster Copywriting

## Purpose

Define copywriting rules for storyboard poster text. Storyboard posters reuse web copywriting conventions (from `story-to-web/references/03-section-copywriting.md`) with print-specific adaptations. Each poster is viewed from 1-2 meters at executive walkthroughs.

**Key principle:** The skill reads `story-to-web/references/03-section-copywriting.md` for base web copywriting rules. This file defines ONLY the print-specific overrides and additions.

---

## Print Overrides vs Web Defaults

| Dimension | Web Default | Storyboard Override | Reason |
|-----------|-----------|---------------------|--------|
| Headline max | 70 chars | 70 chars | Same — poster width matches web width (1440px) |
| Body text max | 50 words | 50 words | Same — constrained by section height |
| Reading distance | Screen (0.5m) | Poster (1-2m) | Larger fonts needed |
| Font scaling | Fixed (1440px) | Scale factor per DIN format | Print size varies |
| Image prompts | Web resolution | "print resolution, high detail" suffix | Print quality |

---

## Poster-Level Governing Headline

Each poster has a **governing headline** that appears in the header strip as the arc station label. This is distinct from the section headlines within the poster.

```
Poster governing headline:
  - Source: arc element name (from arc_definition_path) or arc station name
  - Max: 30 characters
  - Style: uppercase, bold, accent color
  - Example: "WHY NOW" or "KRÄFTE" or "EVOLUTION"
  - Appears in: header strip (right of sequence number)
```

---

## Headline Rules

### Assertion Headlines

Every section headline within a poster must be an **assertion** — a claim with a verb that the viewer can evaluate.

**BAD (topic labels):**
- "Market Overview"
- "Our Solution"
- "Implementation Plan"

**GOOD (assertions):**
- "23 Tage Stillstand kosten 874.000 Euro"
- "Sensoren liefern 14 Tage Vorwarnung"
- "Pilotlinie senkt Stillstand um 73%"

### Headline Constraints

- **Max 70 characters** (same as web)
- **One verb, one number** where possible
- **Active voice** only
- **Readable at 1-2m** on A1 poster
- **German:** Preserve umlauts, use native word order

### Headline Templates by Arc Role

| Arc Role | Template | Example |
|----------|----------|---------|
| `hook` | "{Transformation promise}" | "Predictive Maintenance macht Ihre Fertigung unaufhaltsam" |
| `problem` | "{Number} {negative outcome} {cost}" | "23 Tage Stillstand kosten 874K Euro" |
| `urgency` | "{Quantity} {scarce resource} {deadline}" | "Drei Krisen treffen den Maschinenbau gleichzeitig" |
| `solution` | "{Subject} {delivers} {specific benefit}" | "Sensoren liefern 14 Tage Vorwarnung" |
| `proof` | "{Metric} {improved by} {percentage}" | "73% weniger Stillstand in der Pilotlinie bewiesen" |
| `roadmap` | "In {timeframe} {to milestone}" | "In 12 Wochen zur intelligenten Fertigung" |
| `call-to-action` | "{Action verb} {your/Ihre} {outcome}" | "Starten Sie Ihren Predictive-Maintenance-Piloten" |

---

## Body Text Rules

Same as web defaults:
- **Maximum 50 words** per section
- **2-3 sentences** (prose style)
- **One key message** per section
- **No jargon** unless audience is technical
- **Present tense** for solutions; past tense for evidence

---

## Number Play Techniques

Reuse web number play patterns. Statistics are reframed for visual impact:

| Technique | Raw Data | Reframed |
|-----------|----------|----------|
| Ratio framing | "20% failure rate" | "1:5 Reklamationen" |
| Cost anchoring | "23 days downtime" | "874.000 Euro Verlust/Jahr" |
| Before/after | "reduced to 6 days" | "73% weniger Stillstand" |
| Time compression | "quarterly savings" | "12 Wochen bis zum Rollout" |
| Scale amplification | "64,000 gap" | "64.000 fehlende Fachkräfte" |

---

## Language Rules

### German

- Preserve umlauts: ä, ö, ü, Ä, Ö, Ü, ß
- Use Hauptsatz-first structure for scannability
- Numbers: German formatting (2.661 not 2,661; 38.000 not 38,000)
- Compound nouns: hyphenate for readability if over 20 characters

### English

- Active voice, short sentences (15-20 words max)
- No hedging ("might", "could", "potentially")
- Numbers: use digits, not words

---

## Copywriting Checklist per Section

- [ ] Headline is an assertion (contains a verb)?
- [ ] Headline under 70 characters?
- [ ] Body text under 50 words?
- [ ] Body text is 2-3 complete sentences?
- [ ] Stat numbers reframed with number plays?
- [ ] No hedging language?
- [ ] Active voice throughout?
- [ ] Language-consistent (all en or all de)?
- [ ] Content contributes to the poster's arc station message?
