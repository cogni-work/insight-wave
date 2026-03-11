# Text Station Copywriting

## Purpose

Define copywriting rules for big picture station text. Station copy must be more concise than slide copy because it shares canvas space with illustrations, landscape, and other stations. Every word must earn its place.

---

## Key Differences from Slide Copywriting

| Dimension | Slide (story-to-slides) | Station (big picture) |
|-----------|------------------------|-----------------------|
| Headline max | 60 chars | 50 chars |
| Body text | 3-5 bullets, 10 words each | 4-6 sentences, 100-120 words total |
| Hero number | Prominent stat card | Integrated into body or callout |
| Reading distance | Projected screen (2-5m) | Printed poster (0.5-2m) or screen |
| Context | Full slide devoted to one message | One of 4-8 stations sharing a canvas |
| Scanning | Sequential (slide by slide) | Spatial (eye wanders, lands on stations) |

---

## Headline Rules

### Assertion Headlines (Same Principle as Slides)

Every station headline must be an **assertion** -- a claim the viewer can evaluate.

**BAD (topic labels):**
- "Market Overview"
- "Our Solution"
- "Next Steps"

**GOOD (assertions):**
- "Market Grew 23% in Q3"
- "AI Cuts Detection Time by 87%"
- "Pilot Launches in 6 Weeks"

### Big Picture Headline Constraints

- **Max 50 characters** (shorter than slides for visual legibility at poster scale)
- **One verb, one number** where possible
- **Active voice** only
- **German:** Preserve umlauts, use native word order

### Headline Templates by Arc Role

| Arc Role | Template | Example |
|----------|----------|---------|
| `problem` | "{Number} {negative outcome}" | "688 Lives Lost Annually" |
| `urgency` | "{Deadline/trend} {consequence}" | "EU Deadline Closes in 2026" |
| `evidence` | "{Data point} {reveals/shows}" | "42% of Systems Outdated" |
| `solution` | "{Subject} {positive verb} {outcome}" | "AI Cuts Response to 15 Min" |
| `proof` | "{Result} {achieved/demonstrated}" | "87% Accuracy in Pilot" |
| `roadmap` | "{Timeframe} to {milestone}" | "6 Months to Full Rollout" |
| `investment` | "{Value} for {cost}" | "€2.8M Saved per Year" |
| `call-to-action` | "{Action verb} {now/today}" | "Start Your Pilot Today" |

---

## Body Text Rules

### Constraints

- **Target 100-120 words** per station (hard range)
- **4-6 sentences** (not bullets -- big pictures use prose for warmth and depth)
- **One key message** per station (same principle as one-message-per-slide)
- **No jargon** unless the audience is technical
- **Present tense** for solutions and future states
- **Past tense** for evidence and proof

### Body Text Formula

```
Sentence 1: STATE the situation or claim (what)
Sentence 2: PROVE with a key data point or evidence (how much)
Sentence 3: EXPLAIN the mechanism or root cause (how/why)
Sentence 4: IMPACT — what happens if nothing changes, or what the benefit is (so what)
Sentence 5: CONNECT to next station or broader implication (what's next)
```

Not every station needs all 5 sentences — aim for 4-6 depending on content density.

### What Goes Wrong: Short Bodies

The most common failure is writing compressed fact-list bodies of ~40-50 words instead of 100-120. This happens when the model treats station copy like bullet points rather than prose paragraphs. The result: station text areas look half-empty on the printed poster, the argumentative chain breaks, and the viewer gets fragments instead of a coherent message.

**BAD — 43 words (compressed fact list, no formula):**

```
50 % aller Passagiere nutzten 2025 biometrische Verfahren — ein Anstieg
um 20 Prozentpunkte seit 2022. Generative KI in der Wartung wächst
mit 45 % CAGR auf 171 Milliarden USD bis 2033. Biometrie, KI-Wartung
und Seamless Travel schaffen Kapazität, ohne zu bauen.
```

This body has 3 disconnected facts and a summary sentence. No argument chain, no mechanism, no impact, no connection to the next station. It reads like a compressed data dump.

**GOOD — 112 words (5-part formula with connective prose):**

```
Die Hälfte aller Passagiere nutzte 2025 bereits biometrische Verfahren
— ein Anstieg um 20 Prozentpunkte seit 2022, der die Abfertigungszeit
pro Passagier messbar verkürzt. Am Frankfurter Flughafen ermöglicht die
SITA-NEC-Lösung „Smart Path" sämtliche Kontrollpunkte mit einem einzigen
biometrischen Scan. Parallel wächst der KI-in-der-Luftfahrt-Markt mit
einer CAGR von 45 % auf 171 Milliarden USD bis 2033, wobei Predictive
Maintenance den größten Segmentanteil hält. Für Flughäfen mit eigenen
Technikzentren bedeutet das: Wer Wartungsslots präziser plant, reduziert
Gate-Blockierungen und schafft zusätzliche Kapazität ohne physischen
Ausbau. Diese digitalen Effizienzgewinne bilden die wirtschaftliche
Grundlage für die neuen Geschäftsmodelle am Horizont.
```

This body follows state/prove/explain/impact/connect, weaves in 5 data points with connective tissue, names a specific airport example, and bridges to the next station.

### Worked Example (English)

**Station: "688 Lives Lost Annually"**

```
Every year, 688 people die in preventable rail incidents across Germany.
That translates to nearly two fatalities every single day — a rate that
has barely improved in the last decade despite rising passenger volumes.
Manual monitoring cannot cover 33,000 km of track around the clock,
leaving critical blind spots on rural stretches and unmanned crossings.
The gap between surveillance capacity and network scale is widening
as infrastructure ages faster than budgets allow for modernization.
```

Word count: 102 (within 100-120 target)

### Self-Check After Writing Each Body

After writing each station body:
1. Count the words. Record the count.
2. If under 100: go back to the source section and weave in an additional data point, a named example, or a before/after comparison. Do not just append a sentence — integrate it into the prose flow.
3. If over 120: identify the weakest sentence (least specific, most generic) and cut it.
4. Verify the 5-part formula: does the body state, prove, explain, impact, and connect? If any part is missing, the body needs revision even if word count is met.

---

## Number Plays for Stations

Apply the same number play techniques as story-to-slides, but optimized for visual display:

### Hero Number Treatment

When a station has a hero number, it gets special visual treatment:

```yaml
hero_number: "688"
hero_label: "lives lost per year"
```

The renderer places this as a large, eye-catching element near the station illustration.

### Number Play Techniques (Same as Slides)

| Technique | Before | After |
|-----------|--------|-------|
| Ratio framing | "12% failure rate" | "1 in 8 projects fail" |
| Specific quantification | "significant savings" | "€127K saved per quarter" |
| Before/after contrast | "improved response time" | "48h to 15min (97% faster)" |
| Comparative anchoring | "480 hours saved/year" | "12 full work weeks recovered" |

### Station-Specific Rules

- **One hero number per station** (max) -- unlike slides which can have sublabels
- **Prefer round numbers** for visual impact (688 is fine, 687.3 is not)
- **Context in body text** -- the hero number catches the eye, body text explains
- **Unit always included** -- "688 lives" not just "688"

---

## Language Rules

### English
- Use active voice
- Short sentences (15-20 words max per sentence)
- No hedging ("might", "could", "potentially")
- Numbers: use digits, not words (688 not "six hundred eighty-eight")

### German
- **ALWAYS use real Unicode umlauts: ä ö ü Ä Ö Ü ß — NEVER substitute ae/oe/ue/ss.** The source narrative contains correct umlauts; copy them faithfully. This applies to every text field in the brief: frontmatter `governing_thought`, `station_label`, headlines, body text, CTAs, footer content, metadata. ASCII-ification destroys print quality and reads as unprofessional.
- Use Hauptsatz-first structure for scannability
- Numbers: use German formatting (2.661 not 2,661)
- Compound nouns: hyphenate for readability if over 20 chars

---

## Copywriting Checklist per Station

- [ ] Headline is an assertion (not a topic label)?
- [ ] Headline under 50 characters?
- [ ] Body text is 100-120 words?
- [ ] Body text is 4-6 complete sentences (not bullets)?
- [ ] Hero number reframed with a number play (if applicable)?
- [ ] No hedging language?
- [ ] Active voice throughout?
- [ ] Language-consistent (all en or all de)?
- [ ] Station message connects to the overall governing thought?
