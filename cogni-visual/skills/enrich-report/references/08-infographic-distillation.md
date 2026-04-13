# Infographic Distillation

How to distill a complete markdown report into a structured infographic data payload for the enriched report's header zone. Adapts story-to-infographic's editorial-preset distillation principles for the enrich-report context.

The infographic header is not a second report — it is a 60-second visual executive summary. Every element earns its place by making the report's core argument visible at a glance. The rest of the report (the prose body below) carries the depth.

## Distillation Process

### Step 1: Extract Governing Assertion

Read the executive summary (or introduction if no executive summary). Find the single strongest claim — the sentence that, if the reader remembers nothing else, captures the report's thesis.

**Requirements:**
- Must contain a verb (an assertion, not a topic label)
- Must include a quantified consequence when possible
- Must be self-contained — understandable without reading the report

**Bad:** "KI-Adoption im Maschinenbau" (topic label, no verb)
**Bad:** "Über den aktuellen Stand der KI-Nutzung..." (descriptive, no assertion)
**Good:** "KI-Adoption stagniert bei 9 % Integration — trotz 28 Mrd. € Gewinnpotenzial"

This becomes the infographic `title`. Add a `subtitle` (max 15 words) providing report context: scope, date, source count.

### Step 2: Select 3-5 Hero Numbers

Scan the entire report for the most impactful quantitative claims. Priority order:

1. **Transformation magnitudes** — before/after deltas, percentage changes, multiples. "73 % Reduktion" beats "47 Vorfälle" because it implies change.
2. **Scale indicators** — numbers establishing problem or opportunity size. "28 Mrd. €", "1,4 Mio. Beschäftigte".
3. **Time markers** — durations creating urgency. "bis August 2028", "100 Tage".
4. **Unique specifics** — numbers only this report contains, not generic industry averages.

**Exclusion criteria:**
- Round estimated numbers ("about 50%") — find the exact number or drop it
- Numbers needing 2+ sentences to contextualize — if the label can't explain in 6 words, too complex
- Redundant numbers — keep the more impactful one

**Number play techniques:**
- Hero isolation: one number gets maximum visual prominence (largest card)
- Ratio framing: "1 von 12 Piloten" is more visceral than "8 %"
- Before/after contrast: show the delta, not just the after state
- Contrast pairs: when the report presents Handeln-vs-Nichthandeln costs, ALWAYS include both values as adjacent KPI cards — this contrast is typically the report's central argument

**Cap at 5 KPI cards.** More becomes noise in the infographic header.

### Step 3: Select Pull-Quote (0-1)

Find the strongest qualitative insight — a sentence that crystallizes the report's "so what" in human terms. Look for:
- Blockquotes in the source markdown (often contain the report's sharpest assertions)
- Sentences prefixed with "Kernbotschaft:", "Zentrale These:", "Critically:"
- The most surprising or counterintuitive finding

**Requirements:**
- Max 25 words
- Must be quotable without surrounding context
- Include attribution if from a named source (person, institution, study)

If no strong quote exists, omit this element — a weak pull-quote is worse than none.

### Step 4: Select Comparison Pair (0-1)

Look for the report's strongest two-sided contrast:
- Handeln vs. Nichthandeln (cost of action vs. cost of inaction)
- Before/after (current state vs. target state)
- International comparison (Germany vs. competitors)
- Top performers vs. laggards

**Requirements:**
- 3-5 parallel items per side, max 6 words each
- Structural parallelism (same grammatical form on both sides)
- `left_label` and `right_label` clearly name each side

If no strong contrast exists, omit. Not every report has a clear two-sided argument.

### Step 5: Select Chart Candidates (1-2)

Identify the 1-2 most impactful data visualizations across all sections. These are charts that would lose impact as text but gain clarity as visuals.

**Selection criteria:**
- Prefer comparison data (rankings, distributions) over single-value data (already captured by KPI cards)
- Prefer data with 4+ items (charts earn their space when text comparison is cognitively expensive)
- Prefer data from the report's strongest section

**For each chart, extract structured data:**
```json
{
  "type": "comparison-bar | distribution-doughnut | stat-chart | timeline-chart",
  "title": "Chart title (assertion, not topic)",
  "data": {
    "labels": ["Item 1", "Item 2", ...],
    "values": [83, 76, 71, ...],
    "unit": "%" 
  }
}
```

The Python script generates the full Chart.js config from this structured data — do NOT produce Chart.js configs.

### Step 6: Apply 60-Second Read Test

Mentally scan the assembled infographic data:
1. **Title** — do I know the topic and main claim? (2 sec)
2. **Hero number** — is there a number anchoring the claim? (2 sec)
3. **Supporting elements** — do 2-3 blocks reinforce the message? (4 sec)
4. **"So what?"** — do I understand the implication? (2 sec)

If any step fails, revisit the distillation. The infographic must communicate the report's thesis without requiring the reader to scroll down to the prose.

### Step 7: Discard Everything Else

Everything that didn't make the cut stays in the report body below. The infographic is an assertion medium — nuance, caveats, methodology, and full citations live in the prose. Do not try to compress the entire report into the infographic. 8-12 data points maximum.

## Output Schema

Write `infographic-data.json` to `{source_dir}/cogni-visual/infographic-data.json`:

```json
{
  "title": "Governing assertion (verb + quantified consequence)",
  "subtitle": "Report scope, date, source count (max 15 words)",
  "kpis": [
    {
      "value": "28 Mrd. €",
      "label": "Zusatzgewinn-Potenzial",
      "source": "PwC/VDMA",
      "source_url": "https://..."
    }
  ],
  "charts": [
    {
      "type": "comparison-bar",
      "title": "Chart title as assertion",
      "data": {
        "labels": ["Item 1", "Item 2"],
        "values": [83, 76],
        "unit": "%"
      }
    }
  ],
  "pullquote": {
    "text": "Quote text, max 25 words",
    "attribution": "Source name or institution"
  },
  "comparison": {
    "left_label": "Handeln",
    "right_label": "Nichthandeln",
    "left_items": ["Item 1 (max 6 words)", "Item 2"],
    "right_items": ["Item 1 (max 6 words)", "Item 2"]
  },
  "sources": "30+ Primärquellen | April 2026 | cogni-research"
}
```

**Null/empty rules:** `pullquote` and `comparison` may be `null` if no strong candidate exists. `kpis` must have 3-5 items. `charts` must have 1-2 items. `title` and `subtitle` are required.

## Report-Type Adaptations

### Research Reports

- Governing assertion: typically in the executive summary's blockquote or bold opening sentence
- Hero numbers: scan all sections — research reports spread key data across sections rather than concentrating in a theme table
- Pull-quote: look for the "Kernbotschaft" or "Zentrale These" blockquote
- Comparison: Handeln-vs-Nichthandeln if present, otherwise strongest international comparison or before/after transformation
- Charts: the section with the densest data table (often barriers, adoption rates, or efficiency effects)

### Trend Reports

- Governing assertion: from the executive summary's headline evidence
- Hero numbers: the headline evidence numbers (already curated by the trend-report skill)
- Pull-quote: from the synthesis section's bridge paragraph
- Comparison: investment comparison across Handlungsfelder, or act/plan/observe distribution
- Charts: horizon distribution or theme radar (these are structural and highly visual)

### Generic Reports

- Governing assertion: first bold sentence or first blockquote
- Hero numbers: scan for the 3-5 most frequently cited or most impactful numbers
- Fall back to simpler infographic: KPI cards + 1 chart, skip comparison/pull-quote if unclear
