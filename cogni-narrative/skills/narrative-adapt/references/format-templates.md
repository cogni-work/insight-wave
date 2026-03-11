# Format Templates

Detailed guidelines and edge cases for each derivative format.

## General Principles

1. **Fidelity over creativity** -- Derivative formats condense; they do not embellish
2. **Arc integrity** -- All 4 elements preserved in every format, in order
3. **Evidence priority** -- Quantitative claims are the last thing to cut
4. **Language inheritance** -- Derivative matches source language exactly

---

## Executive Brief

### Template Structure

```markdown
---
type: executive-brief
source: "{source filename}"
arc_id: "{arc_id}"
word_count: {300-500}
language: "{en|de}"
date_created: "{ISO 8601}"
---

# {Title}

*{Subtitle}*

{Condensed hook -- 2-3 sentences distilling the opening tension}

---

## {Element 1 Header}

{75-125 words: core claim + 1-2 key evidence points with citations}

## {Element 2 Header}

{60-100 words: core claim + 1-2 key evidence points with citations}

## {Element 3 Header}

{75-125 words: core claim + 1-2 key evidence points with citations}

## {Element 4 Header}

{50-80 words: core claim + call to action with citations}
```

**Rules:**
- Preserve all 4 `##` headers using exact arc element names
- Maintain citation format `<sup>[N](file.md)</sup>` -- renumber sequentially
- Keep the arc's rhetorical progression intact
- Prioritize quantitative evidence over qualitative description

### Word Budget

| Component | Words |
|-----------|-------|
| Hook (condensed) | 30-50 |
| Element 1 | 75-125 |
| Element 2 | 60-100 |
| Element 3 | 75-125 |
| Element 4 | 50-80 |
| **Total** | **300-500** |

### Condensation Strategy

For each arc element:

1. **Identify the lead claim** -- Usually the first or second sentence of the original section
2. **Select top 2 evidence points** -- Prefer quantitative over qualitative
3. **Compress supporting text** -- Remove examples, analogies, and extended explanations
4. **Preserve transitions** -- Keep 1-sentence transition logic between sections
5. **Renumber citations** -- Sequential from 1, only citations that survive condensation

### Citation Handling

- Keep `<sup>[N](file.md)</sup>` format
- Renumber sequentially starting from 1
- Only include citations that accompany evidence retained in the brief
- Target: 8-12 citations (roughly half of full narrative)

### Common Pitfalls

- **All assertion, no evidence:** Cutting every number and leaving only generic claims. Readers skim for quantitative anchors -- a brief without numbers reads like opinion.
- **Uneven distribution:** Spending 150 words on Element 1 and 30 on Element 4. Each element carries part of the arc's argument; starving one weakens the whole progression.
- **Broken rhetorical flow:** Each element should still feel like it leads to the next. If you remove the transitions entirely, the brief reads as 4 disconnected paragraphs instead of a compressed argument.
- **Missing hook:** The brief still needs an opening frame. Two sentences is enough -- but zero sentences leaves the reader without context.
- **Citation drift:** Keeping a citation but rewording the claim it supports changes the meaning. If the source says "EUR 47B by 2028" and the brief says "nearly EUR 50B," the citation no longer supports the claim.

### Condensation Example

**Source (Element 2, ~400 words):**
> The convergence of regulatory pressure and accelerating market demand has created a narrow window of opportunity. European Commission directives now mandate comprehensive ESG reporting for enterprises with more than 250 employees<sup>[7](regulations.md)</sup>, while consumer preference data shows 73% of B2B buyers actively evaluating sustainability credentials<sup>[8](market-trends.md)</sup>. Organizations that delay risk...
> [continues with examples, case studies, extended analysis]

**Condensed (Element 2, ~80 words):**
> EU regulatory mandates now require ESG reporting for enterprises above 250 employees<sup>[4](regulations.md)</sup>, while 73% of B2B buyers actively evaluate sustainability credentials<sup>[5](market-trends.md)</sup>. This convergence creates a 12-18 month first-mover window. Organizations that move now can establish market positioning before compliance deadlines force reactive adoption, while those that delay face both regulatory penalties and competitive disadvantage.

Note: the core claim, two strongest evidence points, and the transition to Element 3 survive. Extended examples and case studies were cut.

---

## Talking Points

### Template Structure

```markdown
---
type: talking-points
source: "{source filename}"
arc_id: "{arc_id}"
language: "{en|de}"
date_created: "{ISO 8601}"
---

# Talking Points: {Title}

**Arc:** {Arc Display Name} | **Source:** {source filename}

---

## {Element 1 Header}

- {Core message -- 1 sentence}
- {Supporting evidence with number/stat}
- {Supporting evidence with number/stat}

## {Element 2 Header}

- {Core message -- 1 sentence}
- {Supporting evidence with number/stat}
- {Supporting evidence with number/stat}

## {Element 3 Header}

- {Core message -- 1 sentence}
- {Supporting evidence with number/stat}
- {Supporting evidence with number/stat}
- {Key differentiator or capability}

## {Element 4 Header}

- {Core message -- 1 sentence}
- {Key metric or ROI point}
- {Call to action}

---

**Key Numbers:**

- {Most impactful stat from element 1}
- {Most impactful stat from element 2}
- {Most impactful stat from element 3}
- {ROI or payoff stat from element 4}
```

**Rules:**
- Each element gets 3-4 bullets maximum
- Lead each element with the core message (answer-first)
- Include the strongest quantitative evidence per element
- End with "Key Numbers" section pulling the hero stats
- No citations in bullets -- keep clean for verbal delivery
- End element 4 with an actionable call-to-action bullet

### Structure Rules

- **3-4 bullets per element** (no more)
- **Lead bullet = core message** (answer-first, one complete sentence)
- **Supporting bullets = evidence** (stat + context, not full sentences)
- **No citations** -- bullets are for verbal delivery
- **Key Numbers section** pulls 4 hero stats (one per element)

### Bullet Writing Guidelines

**Core message bullets:**
- Start with the insight, not the background
- One sentence, **maximum 25 words** -- this is a hard limit. If a bullet runs longer, split it into two bullets or cut subordinate clauses. Bullets are for scanning, not reading.
- Active voice, direct
- Example (24 words): "Digital transformation spending will exceed $3.4 trillion by 2026, yet 70% of initiatives fail to meet objectives."
- Too long (31 words): "European mid-market manufacturers with EUR 50M-500M revenue combine the resources to invest with the agility to deploy quickly, unlike large enterprises or small firms." → Split into core claim + evidence bullet.

**Evidence bullets:**
- Lead with the number
- Provide just enough context
- 8-15 words per bullet
- Example: "70% failure rate in digital transformation initiatives (McKinsey 2024)"

**Call-to-action bullet (Element 4 only):**
- Imperative form
- Specific and time-bound where possible
- Example: "Pilot the integrated monitoring approach in Q3 with 2 business units"

### Key Numbers Section

Select the single most impactful statistic from each element. Criteria:
1. **Surprising** -- challenges assumptions
2. **Specific** -- exact number, not "many" or "significant"
3. **Relevant** -- directly supports the element's core message
4. **Memorable** -- easy to quote in conversation

### Common Pitfalls

- **Prose disguised as bullets:** Writing full paragraphs with a dash in front. Bullets should be scannable at a glance -- if a bullet needs more than 25 words, it's not a bullet.
- **Generic lead bullets:** "This section discusses..." or "The analysis shows..." are filler. Lead with the insight: "Digital transformation ROI averages 3.2x within 12 months."
- **Missing the answer-first pattern:** Each element's first bullet is the takeaway, not the setup. The audience will hear these in order -- give them the conclusion first, then the evidence.
- **Key Numbers that aren't numbers:** "Significant growth" or "Major improvement" in the Key Numbers section defeats its purpose. Every entry should be a specific, quotable figure.
- **Accidental citations:** Talking points are for verbal delivery -- inline citation markers (`<sup>[N]...</sup>`) break the flow. Source attribution goes in parentheses after the stat: "(McKinsey 2024)".

---

## One-Pager

### Template Structure

```markdown
---
type: one-pager
source: "{source filename}"
arc_id: "{arc_id}"
word_count: {400-600}
language: "{en|de}"
date_created: "{ISO 8601}"
---

# {Title}

> {1-2 sentence executive summary distilling the entire narrative}

---

| Key Metric | Value |
|------------|-------|
| {Metric 1 label} | {Value with unit} |
| {Metric 2 label} | {Value with unit} |
| {Metric 3 label} | {Value with unit} |
| {Metric 4 label} | {Value with unit} |

---

## {Element 1 Header}

{2-3 sentences: core finding and primary evidence}

## {Element 2 Header}

{2-3 sentences: core finding and primary evidence}

## {Element 3 Header}

{2-3 sentences: core finding and primary evidence}

## {Element 4 Header}

{2-3 sentences: core finding with call to action}

---

**Next Steps:**

1. {Concrete action item derived from the narrative}
2. {Concrete action item derived from the narrative}
3. {Concrete action item derived from the narrative}

---

*Source: {source filename} | Arc: {Arc Display Name} | Generated: {date}*
```

**Rules:**
- Executive summary is the single most important sentence
- Key metrics table pulls the 4 strongest numbers (one per element)
- Each element section is exactly 2-3 sentences
- "Next Steps" provides 3 actionable items
- Citations are omitted for clean print layout
- Footer references the source for traceability

### Layout Constraints

Designed for a single printed page (approximately 400-600 words with table and formatting). The 400-word minimum matters -- a one-pager that's too short looks sparse on paper and fails to convey enough substance for a standalone reference document. If you're under 400 words after drafting, expand each element section to its full 3-sentence allowance (What + How much + So what) rather than adding new sections.

### Key Metrics Table

| Rule | Detail |
|------|--------|
| Exactly 4 rows | One metric per arc element |
| Metric label | Short (2-5 words), descriptive |
| Value | Number + unit, no sentences |
| Source | Drawn from source narrative's cited evidence |

**Example table:**

| Key Metric | Value |
|------------|-------|
| Market opportunity | EUR 47B by 2028 |
| Implementation timeline | 6-8 months |
| Competitive advantage window | 18 months |
| Expected ROI | 3.2x in year 1 |

### Section Writing

Each element section: exactly 2-3 sentences. Prefer 3 sentences to ensure the one-pager reaches its 400-word minimum -- the third sentence (implication) adds the "so what" that makes findings actionable.

- Sentence 1: Core finding (what)
- Sentence 2: Key evidence (how much / how fast)
- Sentence 3: Implication (so what) -- include this for all 4 elements unless word count is already at the upper bound

### Next Steps

Derive 3 action items from the narrative's fourth element (the action/decision element in every arc):
- Concrete and specific
- Time-bound where possible
- Progressively scoped (quick win, medium effort, strategic investment)

### Footer

Always include source attribution:
```
*Source: {filename} | Arc: {Arc Display Name} | Generated: {YYYY-MM-DD}*
```

### Common Pitfalls

- **Metrics table with vague values:** "Large market" or "Fast growth" in the Value column. Each row needs a specific number with a unit (EUR 47B, 6-8 months, 3.2x ROI).
- **Overloaded sections:** Each element section is exactly 2-3 sentences. Going to 4-5 sentences breaks the one-page layout and defeats the purpose of a quick-reference format.
- **Next Steps that are too abstract:** "Consider digital transformation" is not actionable. Each step should specify what to do, at what scope, and ideally by when: "Pilot the monitoring approach in Q3 with 2 business units."
- **Missing progressive scoping in Next Steps:** The 3 action items should escalate: (1) quick win, (2) medium effort, (3) strategic investment. Three items at the same ambition level don't help the reader prioritize.
- **Inline citations:** The one-pager is designed for clean print layout. Citations clutter the page -- traceability is handled by the footer's source attribution instead.
