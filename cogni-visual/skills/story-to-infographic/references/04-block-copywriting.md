# Block Copywriting Rules

Per-block-type copy rules for infographic briefs. These rules enforce the "less is more"
principle at the block level — every word earns its place.

## Universal Rules

### Assertion Headlines

Every headline in the infographic must be an assertion — a statement that contains a verb
and makes a claim. Topic labels ("Sicherheit", "KI-Videoanalytik") waste the most valuable
real estate on the page.

| Good (assertion) | Bad (topic label) |
|-------------------|-------------------|
| "KI senkt Vorfälle um 73%" | "Sicherheitsanalyse" |
| "Pilotstart in 12 Wochen" | "Implementierung" |
| "500 Kameras ohne Mehraufwand" | "Skalierbarkeit" |
| "Manuelle Überwachung versagt" | "Status Quo" |

### Number Plays

Numbers are the visual anchors of infographics. Format them for maximum impact:

1. **Hero isolation**: The most important number gets its own kpi-card with large display.
   Never bury a hero number in a sentence.

2. **Ratio framing**: "73% weniger" is more impactful than "von 172 auf 47". Choose the
   framing that creates the strongest visceral reaction.

3. **Before/after contrast**: When showing change, make the delta explicit.
   "172 → 47 Vorfälle (−73%)" is stronger than either number alone.

4. **Dot-separated thousands** (German): 2.661, not 2,661 or 2661.

5. **Unit proximity**: Keep the unit immediately adjacent to the number.
   "73%" not "73 %". "< 2s" not "weniger als 2 Sekunden".

### Icon Prompts

Icon prompts are dispatched to the concept-diagram-svg agent, which generates small SVG
icons (48-64px). Write prompts that are specific and conceptual:

| Good prompts | Bad prompts |
|-------------|-------------|
| "shield with downward arrow, security" | "security icon" |
| "brain with circuit lines, AI processing" | "AI" |
| "stopwatch with motion lines, speed" | "fast" |
| "camera with network nodes, surveillance" | "camera" |

**Prompt structure:** `[primary object] with [distinctive detail], [concept keyword]`

Icons should be recognizable at small sizes. Avoid:
- Text in icons (it won't render legibly at 48px)
- Complex scenes (keep to 1-2 objects)
- Abstract concepts without visual anchors ("innovation", "synergy")

---

## Per-Block-Type Rules

### title

| Field | Max Words | Rule |
|-------|-----------|------|
| Headline | 12 | Assertion with verb + quantified consequence. This IS the infographic's message. |
| Subline | 15 | Supporting context — who, when, why this matters. Optional. |
| Metadata | — | Format: "Customer | Provider | Date". No word limit. |

**The headline carries the entire infographic.** Spend disproportionate effort here. Test: if
someone sees only the title, do they understand the core message and why it matters?

### kpi-card

| Field | Max Words | Rule |
|-------|-----------|------|
| Hero-Number | — | Formatted for display: "73%", "< 2s", "12 Wochen", "2.661" |
| Hero-Label | 4 | What the number measures: "weniger Vorfälle", "Erkennungszeit" |
| Sublabel | 8 | Context: "nach 6 Monaten Pilot", "schlüsselfertige Implementierung" |
| Source | — | Attribution. Short: "Pilotdaten 2025" |

**Total word limit: 15 words** across all fields (excluding number and source).

Hero-Number formatting:
- Percentages: "73%" (no space before %)
- Durations: "< 2s", "12 Wochen", "24/7"
- Counts: "2.661" (German dot separator), "500+"
- Currency: "1,2 Mio. EUR"

### stat-row

| Field | Max Words | Rule |
|-------|-----------|------|
| number | — | Formatted for display (same rules as Hero-Number) |
| label | 4 | What the number measures |
| icon-prompt | — | Optional SVG icon prompt |

**2-4 stats per row.** Stat rows are supporting evidence — they reinforce the hero numbers,
not compete with them. If a stat is important enough to stand alone, promote it to a kpi-card.

### chart

| Field | Max Words | Rule |
|-------|-----------|------|
| Chart-Title | 6 | Descriptive, not assertive (the chart speaks for itself) |
| Data | — | JSON-compatible data structure for Chart.js |

**Max 2 charts per infographic.** Charts should reveal a trend, comparison, or distribution
that text can't convey. If the insight can be expressed as a number, use a kpi-card instead.

Chart type selection:
- Trend over time → `bar` or `line`
- Part of whole → `doughnut`
- Multi-dimensional comparison → `radar`
- Category comparison → `bar`
- Stacked composition → `stacked-bar`

### process-strip

| Field | Max Words | Rule |
|-------|-----------|------|
| label | 3 | Action verb preferred: "Erfassen", "Analysieren", "Alarmieren" |
| icon-prompt | — | Descriptive SVG icon prompt for each step |

**4-8 steps.** Each step is a verb + object or a concise noun. Connector arrows rendered
automatically by the HTML generator — do not describe them in the brief.

### text-block

| Field | Max Words | Rule |
|-------|-----------|------|
| Headline | 8 | Assertion with verb |
| Body | 40 | Short supporting text. 2-3 sentences maximum. |
| Icon-Prompt | — | Optional |

**Use sparingly.** Text blocks are the least "infographic" element — they're prose in a visual
medium. If the content can be expressed as numbers, icons, or a chart, use those instead.
Reserve text blocks for annotations and context that has no visual equivalent.

### comparison-pair

| Field | Max Words | Rule |
|-------|-----------|------|
| Left/Right label | 3 | Concise label: "Heute", "Mit KI", "Ohne Aktion" |
| Bullets (each) | 6 | Parallel structure. Same grammatical form on both sides. |

**3-5 bullets per side.** Structural parallelism is mandatory — if the left side uses noun
phrases, the right side uses noun phrases. If left uses "-X", right uses "+Y".

### icon-grid

| Field | Max Words | Rule |
|-------|-----------|------|
| label | 3 | Concise concept label |
| sublabel | 15 | Brief description or supporting evidence |
| icon-prompt | — | Descriptive SVG icon prompt |

**4-8 items.** All items must be structurally parallel (same fields, similar length). The grid
implies equal weight — don't use it for items of different importance.

### cta

| Field | Max Words | Rule |
|-------|-----------|------|
| Headline | 8 | Imperative verb + outcome: "Pilot in 12 Wochen starten" |
| CTA-Text | 4 | Action button text: "Erstgespräch buchen", "Demo anfordern" |

### footer

No word limits. Include: customer name, provider name, date, source line (consolidated
citations from the narrative).
