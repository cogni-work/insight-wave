# Slide Copywriting

## Purpose

Define how to transform narrative prose into slide-optimized copy: assertion headlines, number plays for visual impact, bullet point consolidation, evidence selection, and hero number isolation. This reference bridges the gap between message architecture (what each slide should say) and YAML specification (the exact text in each field).

## Core Principle

> Slides are scanned, not read. Every word must earn its place.
> The audience spends 3-5 seconds scanning a slide before the presenter speaks.
> In that window: headline = message, numbers = proof, bullets = structure.

---

## Headline Optimization

### The Assertion Headline Rule

Every slide title must be a **complete assertion** — a sentence that makes a claim, not a label that names a topic.

**Why this matters:** If you cover the slide body and read only the titles in sequence, you should understand the entire presentation argument. Topic labels ("Revenue", "Challenges", "Next Steps") communicate nothing. Assertions tell the story.

### Transformation Patterns

| Topic Label (BAD) | Assertion Headline (GOOD) | What Changed |
|--------------------|---------------------------|--------------|
| Revenue Overview | Q3 Revenue Grew 23% Driven by Enterprise | Added: verb, number, cause |
| Security Challenges | 688 Lives Lost Annually to Preventable Rail Incidents | Added: specific number, emotional weight |
| Our Solution | AI Video Analytics Cuts Response Time by 87% | Added: subject, verb, specific result |
| Cost Analysis | Investment of €280K Returns €1.2M in Year One | Added: specific numbers, ROI framing |
| Implementation Plan | 4-Phase Rollout Achieves Full Coverage in 6 Months | Added: specificity, outcome, timeline |
| Team | 47 Engineers Across 3 Time Zones Ensure 24/7 Support | Added: numbers, capability claim |
| Market Opportunity | €200M Addressable Market Growing at 15% CAGR | Added: quantified opportunity |

### Reasoning Approach

Headline writing is NOT mechanical reformatting — it is message distillation. The goal is to compress the slide's entire argument into one scannable line that advances the presentation's case.

Before writing each headline, reason through what the audience must take away:

```text
REASON through headline construction for each slide:

  1. RECALL the slide's message sentence from Step 4b
     → This sentence IS the headline draft — it already contains a claim
     → If the message sentence is a topic label, STOP: return to Step 4b
       and re-extract. A topic label here means the message was never properly
       distilled.

  2. ASK: "What is the ONE thing the audience must remember from this slide?"
     → If the answer is a NUMBER → lead with the number
       "688 Lives Lost..." not "Rail Safety Crisis..."
     → If the answer is an OUTCOME → lead with the outcome verb
       "AI Cuts Downtime 73%..." not "Our AI Platform..."
     → If the answer is a CONTRAST → frame as transformation
       "From 48 Hours to 15 Minutes" not "Improved Response Time"
     → If the answer is an ACTION → lead with the imperative
       "Schedule Discovery Session This Quarter" not "Next Steps"

  3. INJECT a number (if the slide has data)
     → Scan the slide's evidence inventory from Step 4b
     → Select the single most impactful statistic
     → Weave it into the headline naturally:
       × "Our platform is effective" (vague)
       ✓ "Platform Detects 97% of Incidents in Real Time" (specific)
     → If no number exists: use a strong verb + specific claim instead
       × "Good customer satisfaction" (vague)
       ✓ "Customers Rate Service Best-in-Class" (specific without number)

  4. ACTIVATE the verb
     → Headlines with passive voice lose 40% of impact at scanning speed
     → Test: is the subject DOING something, or having something done TO it?
       × "Costs are reduced by 40%" (passive — who reduces?)
       ✓ "AI Reduces Costs by 40%" (active — AI does the work)
     → Test: is there a verb at all?
       × "€280K investment, 4.3x return" (noun phrase — no verb)
       ✓ "€280K Investment Returns 4.3x in Year One" (verb: returns)

  5. TRIM to 60 characters maximum
     → Count characters. If over 60:
       - Cut redundant modifiers ("advanced", "innovative", "comprehensive")
       - Replace clauses with numbers ("which leads to a 40% reduction" → "40% reduction")
       - Use symbols where natural ("€" not "EUR", "%" not "percent")
     → The 60-char limit ensures the headline fits on one title line without wrapping

  6. VERIFY the headline tells the story without the body
     → Cover the slide body. Read ONLY the headline.
     → Does the audience understand the claim? (YES → proceed)
     → Read ALL headlines in sequence. Does the argument flow?
       (YES → proceed | NO → adjust the headline that breaks the chain)
```

### Headline Patterns by Section Role

| Role | Headline Pattern | Example |
|------|-----------------|---------|
| `hook` | [Shocking number] + [consequence] | "688 Deaths. Zero Automated Prevention." |
| `problem` | [Number] + [problem verb] + [impact] | "42% of Systems Exceed 18-Year Lifespan" |
| `urgency` | "Every [period], [cost accumulates]" | "Every Month of Delay Costs €230K" |
| `evidence` | [Data point] + [proves claim] | "3 of 4 Incidents Go Undetected" |
| `solution` | [Solution] + [achieves result] | "AI Monitoring Detects 97% of Incidents" |
| `proof` | [Customer/metric] + [validates result] | "Pilot Site Reduced Incidents by 73%" |
| `options` | [N options] + [comparison frame] | "3 Rollout Strategies: Pilot to National" |
| `roadmap` | [Timeline] + [achieves milestone] | "6 Months from Pilot to Full Operations" |
| `investment` | [Investment] + [returns/delivers] + [value] | "€280K Investment Returns 4.3x in Year One" |
| `call-to-action` | [Action verb] + [specific next step] | "Schedule Discovery Session This Quarter" |

---

## Number Plays for Slides

Adapted from the Copywriter's number plays, optimized for the visual slide medium.

### Reasoning Approach

Number play selection is NOT random decoration — it is strategic reframing. The goal is to make data FELT, not just seen. Every statistic has a natural presentation form that maximizes emotional impact for the slide medium.

Before applying any technique, reason through the data:

```text
REASON through number play selection for each slide:

  1. INVENTORY all numbers in the narrative section
     → List every statistic, metric, cost, percentage, count
     → Note for each: value, unit, context, source
     → Example inventory:
       - 688 (deaths/year, from Federal Rail Report)
       - 2,661 (attacks/year, from BKA)
       - 42% (outdated systems, from infrastructure audit)
       - €2.8M (emergency costs/year, from DB internal)

  2. RANK by emotional impact
     → Deaths > injuries > incidents > costs > percentages > counts
     → Absolute numbers often hit harder than relative:
       "688 deaths" > "12% increase in incidents"
     → EXCEPTION: when the percentage IS the story:
       "97% detection rate" (percentage is the proof)
       "1 in 8 projects fail" (ratio is more visceral than 12%)
     → EXCEPTION: when the euro amount IS the story:
       "€2.8M wasted annually" (cost is the pain point)

  3. SELECT the hero number (ONE per slide — this is non-negotiable)
     → Ask: "Which number would I put on a billboard?"
     → The hero number gets 36pt bold treatment on the slide
     → All other numbers become supporting evidence (sublabel, bullets, notes)
     → If two numbers feel equally important:
       - Which connects more directly to the slide's MESSAGE?
       - Which is more surprising to the AUDIENCE?
       - Use that one. Move the other to sublabel.

  4. CHOOSE the right technique for each number
     → For the HERO number:
       - Is it a percentage under 50%? → Try ratio framing ("1 in 8")
       - Is it an absolute count with emotional weight? → Hero isolation
       - Is it a cost with a comparison? → Before/after contrast
     → For SUPPORTING numbers:
       - Can a per-unit figure compound? → Compound impact (10 hrs/wk → €130K/yr)
       - Is a claim vague? → Specific quantification ("many" → "2,847")
       - Does a raw number lack context? → Comparative anchoring ($36K → $100/day)
     → For ALL numbers:
       - Would the audience understand the scale without context?
       - If NO → anchor to something familiar (comparative anchoring)

  5. VERIFY the reframing is honest
     → Does the reframed number mean the same thing as the original?
     → Would a skeptical audience member accept this framing?
     → If the reframing distorts (e.g., cherry-picked timeframe) → keep original
     → Rule: number plays amplify impact, they never manufacture it
```

### Hero Number Isolation

Every stat-card needs ONE dominant number. When the narrative contains multiple numbers, isolate the hero:

```text
NARRATIVE: "688 Schienensuizide jährlich + 2.661 Übergriffe auf Bahnhöfen"

HERO: 688
SUBLABEL: + 2,661 attacks on stations

WHY: 688 is more shocking (deaths > attacks)
     The hero number gets 36pt bold treatment
     Supporting numbers get 10-13pt sublabel treatment
```

**Hero number selection criteria:**
1. Most emotionally impactful (deaths > incidents > costs)
2. Largest in absolute terms (688 > 42%)
3. Most relevant to the audience's concerns
4. Most specific (€2.8M > "millions")

### Slide-Adapted Number Techniques

#### 1. Ratio Framing (for hero stats)

```text
NARRATIVE: "12% failure rate across all projects"
SLIDE:     Hero: "1 in 8" / Label: "projects fail"

NARRATIVE: "25% of infrastructure is outdated"
SLIDE:     Hero: "1 in 4" / Label: "systems past end-of-life"
```

**When to use:** Percentages under 50% that represent risk or failure. Ratios feel more personal ("1 in 8" means "it could be yours").

#### 2. Before/After Contrast (for comparison slides)

```text
FORMAT: [Metric]: [Before] → [After] ([Improvement])

EXAMPLES:
  Response time: 48 hours → 15 minutes (192x faster)
  Error rate: 12% → 0.3% (40x improvement)
  Cost per incident: €45K → €12K (73% reduction)
```

**Slide placement:** Left column = Before, Right column = After, Banner = Improvement

#### 3. Compound Impact (for investment slides)

```text
NARRATIVE: "Saves 10 hours per week per analyst"
SLIDE:
  Hero: "€130K"
  Label: "annual productivity recovered"
  Context bullets:
    - 10 hours saved per analyst per week
    - × 52 weeks × 5 analysts
    - = 2,600 hours at €50/hr
```

**When to use:** When a unit-level saving can be compounded to an impressive total.

#### 4. Specific Quantification (replacing vague language)

```text
NARRATIVE: "significant cost savings"     → "€127K saved per quarter"
NARRATIVE: "many customers"               → "2,847 customers"
NARRATIVE: "fast implementation"          → "deployed in 14 days"
NARRATIVE: "high accuracy"               → "97.3% accuracy rate"
```

**Rule:** Every "significant", "many", "fast", "high", "large" in the narrative must be replaced with a specific number on the slide. If no specific number exists in the source, flag for manual review.

#### 5. Comparative Anchoring (for context)

```text
NARRATIVE: "saves 480 hours annually"
SLIDE:
  Hero: "12 weeks"
  Label: "recovered per year"
  Sublabel: "That's a full quarter back"

NARRATIVE: "$36,000 annual cost"
SLIDE:
  Hero: "$100/day"
  Label: "less than a contractor's hourly rate"
```

**When to use:** When raw numbers lack emotional context. Anchor to something the audience already understands.

### Number Play Decision Matrix

| Data Type | Best Technique | Example |
|-----------|---------------|---------|
| Single large number | Hero isolation | 688 rail suicides |
| Percentage < 50% | Ratio framing | 12% → 1 in 8 |
| Before/after metric | B/A contrast | 5 days → 4 hours |
| Per-unit savings | Compound impact | 10 hrs/wk → €130K/yr |
| Vague claim | Specific quantification | "many" → "2,847" |
| Raw cost/time | Comparative anchoring | $36K → $100/day |
| Multiple related stats | Quadrant layout | 4 stats in 2×2 grid |
| Growth percentage | Year-over-year | "+23% YoY" |

---

## Bullet Point Consolidation

### Why Consolidation is Needed

Narratives contain 8-15 points per section. Slides need 3-5 bullets maximum. The audience cannot process more than 5 items on a slide while also listening to the presenter.

### Reasoning Approach

Bullet consolidation is NOT summarization — it is strategic compression. The goal is to reduce 8-15 narrative points to 3-5 scannable bullets without losing the argument's force. Each bullet must earn its place by advancing the slide's message.

Before consolidating, reason through the content:

```text
REASON through bullet consolidation for each slide:

  1. LIST all points from the narrative section (uncensored — capture everything)
     → Typically 8-15 points
     → Tag each with its core FUNCTION:
       - DATA: a statistic or metric ("24/7 monitoring", "97% accuracy")
       - MECHANISM: how something works ("uses ML trained on historical data")
       - BENEFIT: what the audience gains ("reduces incidents by 73%")
       - CONTEXT: background information ("founded in 2018")
       - PROOF: evidence it works ("deployed at 12 sites")
     → This tagging reveals which points are slide-worthy and which are notes-worthy

  2. IDENTIFY duplicates — points that say the SAME thing differently
     → These are the easiest wins: merge without information loss
     → Example: "24/7 monitoring" + "continuous surveillance" + "round-the-clock coverage"
       → All three = same point → keep strongest formulation: "24/7 automated monitoring"
     → Example: "scales across locations" + "no proportional staff increase"
       → Same underlying claim (scalability) → merge: "Scales without staff increase"
     → ASK for each pair: "If I remove one, does the audience lose a UNIQUE insight?"
       → NO: merge them. YES: keep both as separate bullets.

  3. GROUP remaining points by FUNCTION into 3-5 clusters
     → Each cluster becomes ONE bullet
     → Typical grouping patterns:
       CAPABILITY cluster: what it does (DATA + MECHANISM points)
       RESULT cluster: what you get (BENEFIT + PROOF points)
       SCALE cluster: how far it reaches (DATA + CONTEXT points)
     → CONTEXT-only points → move to speaker notes (not bullet-worthy)
     → MECHANISM-only points → fold into the capability they enable
       × Standalone: "Uses ML trained on historical data"
       ✓ Folded: "ML-powered pattern detection in real time"

  4. WRITE each bullet leading with its conclusion
     → The audience reads the FIRST 3 WORDS of each bullet
     → If those 3 words communicate the point → bullet works
     → If those 3 words are preamble → rewrite to lead with impact
       × "By leveraging machine learning algorithms..." (preamble → reader stops)
       ✓ "ML-powered detection catches..." (impact first → reader continues)
     → ASK: "If the audience reads ONLY the first 3 words of each bullet,
       do they get 80% of the message?" (YES → good bullets)

  5. ENFORCE parallel structure
     → All bullets must follow the same grammatical form
     → Choose ONE pattern and apply to all:
       - Verb-first: "Reduces...", "Enables...", "Integrates..."
       - Number-first: "24/7 monitoring", "97% accuracy", "12 sites deployed"
       - Noun-first: "ML-powered detection", "Standard API integration"
     → Mixing forms creates cognitive friction:
       × "Reduces costs" / "24/7 monitoring" / "Integration is available"
       ✓ "Reduces costs by 60%" / "Monitors 24/7 without staff scaling" / "Integrates via standard APIs"

  6. TRIM each bullet to 8-10 words maximum
     → Read each bullet at SCANNING speed (3-second test)
     → If you must re-read → it's too long or too complex
     → Cut: articles ("the", "a"), hedging ("can", "may", "potentially"),
       filler ("in order to", "with the ability to", "by leveraging")
     → Keep: numbers, verbs, specifics
       × "The system provides continuous 24/7 monitoring capability across all stations" (12 words)
       ✓ "24/7 automated monitoring across all stations" (6 words)

  7. VERIFY the final set tells the slide's story
     → Read ONLY the bullets (ignore headline, ignore speaker notes)
     → Do they support the headline's claim?
     → Is there redundancy between bullets? (if yes → merge further)
     → Is there a gap the headline claims but bullets don't support? (if yes → add)
```

### Consolidation Process

```text
Step 1: LIST all points from the narrative section (8-15 items)

Step 2: GROUP into MECE categories (typically 3-5 groups)
  Each group becomes one bullet

Step 3: LEAD with the conclusion
  × "By using machine learning algorithms trained on historical data..."
  ✓ "ML-powered pattern detection in real time"

Step 4: TRIM to 8-10 words per bullet
  × "The system provides continuous 24/7 monitoring capability across all stations"
  ✓ "24/7 automated monitoring across all stations"

Step 5: REMOVE hedging language
  × "can potentially help reduce"    → "reduces"
  × "it is possible to achieve"      → "achieves"
  × "may contribute to improvements" → "improves"

Step 6: START with action verbs or impact words
  × "There is a reduction in costs"  → "Cuts costs by 60%"
  × "Integration is available"       → "Integrates with existing systems"
```

### Before/After Examples

**Narrative (8 points):**
```
- The system provides continuous 24/7 monitoring capability
- It uses advanced machine learning to detect patterns
- Models are trained on historical incident data
- Real-time alerts are sent to operators when incidents are detected
- The platform scales across multiple locations
- No proportional staff increase is needed for scaling
- Integration with existing infrastructure is possible
- Standard APIs enable connections to legacy systems
```

**Slide (4 bullets):**
```
- 24/7 automated monitoring — no staff scaling needed
- ML-powered pattern detection in real time
- Instant operator alerts on incident detection
- Standard API integration with existing systems
```

**What happened:**
- Points 1, 5, 6 merged → "24/7 automated monitoring — no staff scaling"
- Points 2, 3 merged → "ML-powered pattern detection"
- Point 4 simplified → "Instant operator alerts"
- Points 7, 8 merged → "Standard API integration"

### Bullet Style Rules

| Rule | Example |
|------|---------|
| Start with verb or impact word | "Reduces", "Enables", "24/7", "97%" |
| No articles at start | ~~"The system provides"~~ → "Provides" |
| No hedging | ~~"Can help improve"~~ → "Improves" |
| Parallel structure | All bullets same grammatical form |
| One idea per bullet | No "and" connecting two ideas |
| Number first when possible | "60% cost reduction" not "Cost reduction of 60%" |

---

## Evidence Selection

### Reasoning Approach

Evidence selection is NOT collecting everything available — it is strategic curation. The goal is to include only the evidence that PROVES the headline's claim, nothing more. Excess evidence dilutes impact; missing evidence undermines credibility.

Before selecting evidence, reason through what this specific slide needs:

```text
REASON through evidence selection for each slide:

  1. INVENTORY all evidence available for this slide's message
     → List every data point, case study, testimonial, benchmark from the narrative
     → Tag each with its tier:
       Tier 1: Quantified proof with source (€2.8M verified by audit)
       Tier 2: Demonstrated result (customer achieved 73% reduction)
       Tier 3: Logical argument (if A then B reasoning)
       Tier 4: Context (background, methodology, history)

  2. ASK: "Which single piece of evidence would convince the primary decision-maker?"
     → This is the hero evidence — it goes in the headline or hero stat
     → Criteria: most specific, most surprising, most relevant to THIS audience

     IF Audience Model available (Rich mode):
       → Rank evidence by alignment with primary decision-maker's top priority:
         EB priority "ROI" → financial evidence ranks highest (€2.8M > 688 deaths)
         TE priority "integration" → technical compatibility evidence ranks highest
         EU priority "workflow" → usability/efficiency evidence ranks highest
       → Per-slide: if narrative contains buyer role tags ([ECONOMIC-BUYER], [TECH-EVAL], etc.),
         select hero evidence matching the tagged stakeholder for that section

     IF no Audience Model (Lean mode):
       → Use heuristic reasoning:
         For an executive audience: €2.8M savings > 688 deaths
         For a safety officer audience: 688 deaths > €2.8M savings
       → The inferred audience type determines which evidence is "strongest"

  3. SELECT 2-4 supporting evidence points
     → Each must directly support the headline's claim (not a related claim)
     → Prefer VARIETY: one number + one comparison + one outcome
       × Three percentages proving the same thing (redundancy fatigues)
       ✓ One percentage + one case study + one before/after (triangulated proof)
     → ASK per candidate: "Does this evidence PROVE the headline, or just relate to it?"
       Proves → include. Relates → speaker notes or discard.

  4. DECIDE placement for each piece of evidence
     → Hero evidence → headline number or stat-card hero
     → Top 3-5 Tier 1-2 → slide body (bullets, context box)
     → Tier 3-4 → speaker notes ("WHAT YOU NEED TO KNOW")
     → Duplicate of a stronger point → discard entirely
     → Evidence with no source → flag for manual review

  5. VERIFY the evidence-headline alignment
     → Read the headline. Read the evidence. Does the evidence PROVE the headline?
       × Headline: "688 Lives Lost Annually"
         Evidence: "Platform has 99.9% uptime" ← wrong slide
       ✓ Headline: "688 Lives Lost Annually"
         Evidence: "3-year average: 612, 679, 773 — trend rising" ← proves the claim
     → If evidence supports a DIFFERENT message → move to that slide
     → If no matching slide → either create one or discard the evidence

  6. CHECK the density is appropriate
     → Target: 2-4 data points per slide (enough to convince, not enough to overwhelm)
     → If < 2: the slide feels unsubstantiated → find more Tier 1-2 evidence or merge slides
     → If > 5: the slide feels cluttered → demote weakest to speaker notes
```

### Evidence Hierarchy

When a narrative section contains more evidence than fits on a slide, select based on this hierarchy (strongest first):

```text
TIER 1 — QUANTIFIED PROOF (always include if available)
  Specific numbers with sources (€2.8M verified by audit)
  Before/after contrasts with percentages (5 days → 4 hours, 97% faster)
  Third-party validation (Gartner report, industry benchmark)

TIER 2 — DEMONSTRATED RESULTS (include when Tier 1 is thin)
  Case study outcomes (Customer X achieved Y in Z months)
  Pilot/trial results (73% incident reduction at test site)
  Customer testimonials with metrics

TIER 3 — LOGICAL ARGUMENTS (include only if no data available)
  If A then B reasoning
  Industry analogies
  Expert opinions

TIER 4 — CONTEXTUAL (move to speaker notes)
  Background information
  Methodology explanations
  Detailed technical specifications
  Historical context
```

### Selection Rules

```text
PER SLIDE:
  - Include: Top 3-5 Tier 1-2 evidence points
  - Move to speaker notes: Tier 3-4 evidence
  - Discard: Evidence that duplicates a stronger point

PER DECK:
  - Every argument must have at least one Tier 1 evidence point
  - If an argument has no Tier 1 evidence, flag for manual review
  - Total evidence density: ~2-4 data points per slide average
```

---

## Source Attribution

When narrative evidence comes with a source URL, embed it as an inline clickable link.

### Source Field (Per-Slide Attribution)

```text
FORMAT: Source: "[Report Name Year](URL)"

EXAMPLES:
  Source: "[Federal Rail Safety Report 2024](https://eba.bund.de/report)"
  Source: "[Gartner Magic Quadrant 2024](https://gartner.com/mq-rail)"
  Source: "[Bundesbericht Schienensicherheit 2024](https://eba.bund.de/report) | [EBA Statistik](https://eba.bund.de/stats)"
```

### Speaker-Notes Inline Links

The `>> WHAT YOU NEED TO KNOW` section uses inline markdown links for source attribution:

```text
- Source: 688 is a 3-year average (2021-2023) from the
  [Federal Rail Safety Report 2024](https://eba.bund.de/report), Section 4.2.
```

### Rules

- Use the shortest meaningful label (report name + year, not full URL or title)
- Maximum 2 sources in the Source field per slide
- Always use markdown link format `[label](url)` — never bare URLs
- German report names stay in German: `[Bundesbericht Schienensicherheit 2024](url)`
- Only generate Source field when the narrative actually provides a URL — never invent or guess URLs
- If no URL is available for a cited source, omit the Source field entirely

---

## Inline Citations in Body Text

### Purpose

Preserve claim-to-source traceability directly in slide body content so that PPTX audiences can trace any quantitative claim to its source. Inline citations complement the Source field (slide-level) with claim-level granularity.

### Citation Format

After renumbering (see SKILL.md Step 2 Preservation Rule), inline citations in **slide body text** use superscript format: `<sup>[N](url)</sup>`

Where N is the sequential citation number and url is the original source URL. The `<sup>` tag signals the PPTX skill to render the citation as a small raised clickable hyperlink (display text: N, link target: url).

**Speaker-Notes** use regular inline links: `[N](url)` — NO superscript. Notes are text-only and do not need visual formatting.

### Placement Rules

1. Place the superscript citation immediately after the claim it supports, within the same bullet or sentence
2. Do NOT move a citation from one bullet to another — it stays with its claim
3. If a bullet contains multiple claims with different sources, place each citation after its respective claim
4. Maximum 2 inline citations per bullet (if more — move extras to Speaker-Notes)

### Inclusion Zones (fields that accept superscript inline citations)

| Layout | Fields |
|--------|--------|
| stat-card-with-context | Context-Box Bullets |
| two-columns-equal | Left-Column Bullets, Right-Column Bullets |
| is-does-means | IS-Box Text, DOES-Box Text, MEANS-Box Text |
| three-options | Option Features |
| four-quadrants | Quadrant Sublabel (if evidence-bearing) |
| timeline-steps | Step Description (if evidence-bearing) |

### Exclusion Zones (keep clean — no citations)

- Slide-Title (assertion headlines)
- Context-Box Headline, Left/Right Column Headlines
- Hero-Stat-Box Number, Label, Sublabel
- Bottom-Banner Text
- Step Labels, Step Numbers
- Option Names, Option Prices

### Example

**Narrative input:**
```text
Sicherheitspersonal kann nicht alle Bereiche 24/7 abdecken [P1-1](https://eba.bund.de/report).
Kritische Ereignisse werden zu spät erkannt [P1-2](https://railsafety.eu/study).
```

**After renumbering (P1-1 -> 1, P1-2 -> 2) — slide body text (superscript):**
```yaml
Context-Box:
  Headline: Why manual monitoring fails
  Bullets:
    - "Security staff cannot cover all areas 24/7 <sup>[1](https://eba.bund.de/report)</sup>"
    - "Critical events detected too late to intervene <sup>[2](https://railsafety.eu/study)</sup>"

Source: "[Federal Rail Safety Report 2024](https://eba.bund.de/report)"
```

**In Speaker-Notes (regular links, no superscript):**
```yaml
Speaker-Notes: |
  >> WHAT YOU NEED TO KNOW
  - Source: 688 is from the [Federal Rail Safety Report 2024](https://eba.bund.de/report)
  - The 2,661 attacks figure comes from [BKA Statistics](https://bka.de/stats)
```

### Interaction with Source Field

The Source field and inline citations serve different purposes:
- **Source field**: Slide-level "at a glance" attribution (1-2 primary sources per slide)
- **Inline citations**: Claim-level traceability (specific claim -> specific source)

Both are generated. The Source field uses the descriptive label format `[Report Name Year](url)`. Inline citations in body text use superscript `<sup>[N](url)</sup>`. Speaker-Notes use regular `[N](url)`.

---

## Layout-Specific Copywriting

### Reasoning Approach

Each layout has different fields with different functions. Populating fields is NOT copying content into slots — it is adapting the message to the visual structure's strengths. The same data looks different in a stat-card vs. a two-columns-equal because the EMPHASIS changes.

Before populating any layout, reason through what each field should accomplish:

```text
REASON through field population for each slide:

  1. RECALL the layout selected in Step 6
     → What fields does this layout have? (from pptx-layouts.md)
     → What is each field's FUNCTION?
       Hero-Stat-Box.Number: stop the audience with one figure
       Context-Box.Bullets: explain WHY the hero number matters
       Bottom-Banner.Text: leave a parting impact statement

  2. ASSIGN content to fields by function — not by order of appearance
     → The headline always gets the assertion message (from Step 4b)
     → The hero element gets the strongest evidence
     → Supporting elements get context and proof
     → The banner gets the "so what" takeaway
     → ASK per field: "What is the audience looking for in THIS position?"

  3. CHECK for field-content mismatch
     → A paragraph in a hero-stat field → wrong: needs ONE number
     → A topic label in a headline field → wrong: needs an assertion
     → A source URL in a banner field → wrong: banner is for impact, not attribution
     → Six bullets in a context box → wrong: max 5, consolidate further

  4. VERIFY the slide reads correctly in scanning order
     → The audience scans: headline → hero → bullets → banner (3-5 seconds)
     → Each element should ADD to the previous, not repeat it
       × Headline: "688 Deaths" + Hero: "688" (redundant)
       ✓ Headline: "688 Lives Lost Annually" + Hero: "688" + Label: "per year" (headline = claim, hero = anchor)
     → The banner should leave the audience with a forward-looking thought:
       × Banner: "Source: Federal Rail Report" (attribution, not impact)
       ✓ Banner: "Germany leads EU statistics in rail incidents" (impact)
```

### stat-card-with-context

```text
Hero-Stat-Box:
  Number: [HERO NUMBER — one dominant figure]
  Label:  [4-6 words — what the number represents]
  Sublabel: [Optional — secondary metric or "+X additional"]

Context-Box:
  Headline: [WHY headline — "Why [thing] fails/matters/works"]
  Bullets:  [3-5 consolidated points, 8-10 words each]

Bottom-Banner:
  Text: [Impact statement — NOT source attribution]

Source: "[Report Name Year](URL)"  ← only when narrative provides URL
```

### two-columns-equal

```text
Left-Column:
  Headline: [Label for BEFORE / OLD / PROBLEM side]
  Bullets:  [3-5 points describing the inferior state]

Right-Column:
  Headline: [Label for AFTER / NEW / SOLUTION side]
  Bullets:  [3-5 parallel points showing improvement]

Bottom-Banner:
  Text: [Summary comparison — "X delivers [improvement] vs. Y"]
```

### four-quadrants

```text
Each Quadrant:
  Number: [ONE metric — the most important for this category]
  Label:  [2-3 word category name]
  Sublabel: [Optional context — units, timeframe]

Keep all quadrants consistent:
  - Same type of metric (all costs, all percentages, all counts)
  - OR same meaning level (all representing different crisis areas)
```

### is-does-means

```text
IS-Box:
  Text: [What the solution IS — positioning statement, 1-2 sentences]
  RULE: Foundation layer. Keep factual and specific.

DOES-Box:
  Text: [What it DOES — capabilities with quantified outcomes]
  RULE: This is where number plays go. "Reduces X by Y%"

MEANS-Box:
  Text: [HOW it works — technology/methodology proof]
  RULE: Technical credibility layer. Specifics, not buzzwords.

Bottom-Banner:
  Text: [Proof statement — strongest evidence point]
```

### timeline-steps

```text
Each Step:
  Number: [Sequential — "1", "2", "3", "4"]
  Label:  [Phase name — 1-2 words]
  Description: [What happens — 10-15 words max]
  Duration: [Specific — "4 weeks", "Q2 2026"]

RULE: Max 4-6 steps on one slide.
      If more, split into two timeline slides or compress.
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Fix |
|-------------|--------------|-----|
| Topic label headline | Communicates nothing | Rewrite as assertion with verb + number |
| More than 5 bullets | Audience stops reading | Consolidate to 3-5 |
| Bullets > 12 words | Not scannable | Trim to 8-10 words |
| Hedging language | Weakens the claim | Remove: "can", "may", "potentially" |
| Two hero numbers | Dilutes impact | Pick one, move other to sublabel |
| Paragraph in a slide field | Wrong medium | Break into bullets or trim to 1-2 sentences |
| "Overview" or "Summary" as title | Wasted headline | Replace with the actual conclusion |
| Same layout 3+ times in a row | Visual monotony | Vary layouts to maintain interest |

---

## End-to-End Worked Example

Complete copywriting transformation for one narrative section, showing all reasoning steps:

```text
═══════════════════════════════════════════════
INPUT: Narrative section from Why Change pitch
═══════════════════════════════════════════════

Section from narrative (role: problem, from Step 3c):

  "Die Deutsche Bahn verzeichnet jährlich 688 Schienensuizide [P1-1](https://eba.bund.de/report).
   Hinzu kommen 2.661 Übergriffe auf Bahnhöfen [P1-2](https://bka.de/stats) und
   42% veraltete Überwachungssysteme, die das Ende ihrer Lebensdauer überschritten haben.
   Allein die Notfall-Einsatzkosten belaufen sich auf €2,8 Mio. jährlich.
   Sicherheitspersonal kann nicht alle Bereiche 24/7 abdecken.
   Kritische Ereignisse werden häufig zu spät erkannt.
   Das Streckennetz ist zu weitläufig für punktuelle Überwachung.
   Manuelle Prozesse führen zu inkonsistenter Datenerfassung."

Slide message from Step 4b:
  "688 Lives Lost Annually to Preventable Rail Incidents"
Layout from Step 6: stat-card-with-context

═══════════════════════════════════════════════
STEP 5a: HEADLINE REASONING
═══════════════════════════════════════════════

  1. RECALL message: "688 Lives Lost Annually to Preventable Rail Incidents"
     → Already an assertion, not a topic label ✓

  2. ASK: What must the audience remember?
     → The NUMBER: 688 deaths. This is the emotional anchor.
     → Lead with the number: "688 Lives Lost..."

  3. INJECT number: Already present (688) ✓

  4. ACTIVATE verb: "Lost" is passive-ish but works emotionally here.
     Alternative: "688 Preventable Deaths on German Rails Every Year"
     → "Lost" evokes more emotion than "Deaths" → keep original

  5. TRIM: "688 Lives Lost Annually to Preventable Rail Incidents" = 52 chars ✓

  6. VERIFY: Reading only this headline — does the audience understand the claim?
     → YES: there's a crisis (688 deaths), it's ongoing (annually),
       and it's solvable (preventable). ✓

  HEADLINE: "688 Lives Lost Annually to Preventable Rail Incidents"

═══════════════════════════════════════════════
STEP 5b: NUMBER PLAY REASONING
═══════════════════════════════════════════════

  1. INVENTORY numbers:
     - 688 (deaths/year, from Federal Rail Report [P1-1])
     - 2,661 (attacks/year, from BKA [P1-2])
     - 42% (outdated systems, from infrastructure audit)
     - €2.8M (emergency costs/year, from DB internal)

  2. RANK by emotional impact:
     688 deaths > 2,661 attacks > €2.8M costs > 42% outdated
     (deaths are the most visceral for any audience)

  3. SELECT hero: 688
     → Billboard test: "688" stops anyone. It demands explanation.
     → Supporting: 2,661 as sublabel (related crisis dimension)
     → 42% and €2.8M are candidates for a second slide or four-quadrants

  4. CHOOSE technique:
     → 688 → Hero isolation (absolute number, emotional weight)
     → 2,661 → Sublabel ("+ 2,661 attacks on stations")
     → Not using ratio framing because 688 is not a percentage
     → Not compounding because this is a count, not a rate

  5. VERIFY honesty:
     → 688 is from the Federal Rail Report — verified source ✓
     → No distortion in framing ✓

  HERO: 688 / LABEL: rail suicides per year / SUBLABEL: + 2,661 attacks on stations

═══════════════════════════════════════════════
STEP 5c: BULLET CONSOLIDATION REASONING
═══════════════════════════════════════════════

  1. LIST all points (8 items):
     a. 688 Schienensuizide jährlich [DATA]
     b. 2,661 Übergriffe auf Bahnhöfen [DATA]
     c. 42% veraltete Überwachungssysteme [DATA]
     d. €2.8M Notfall-Einsatzkosten [DATA]
     e. Personal kann nicht 24/7 abdecken [MECHANISM — explains WHY]
     f. Ereignisse werden zu spät erkannt [BENEFIT gap — explains IMPACT]
     g. Netz zu weitläufig für Überwachung [MECHANISM — explains SCALE]
     h. Manuelle Prozesse → inkonsistente Daten [MECHANISM — explains QUALITY]

  2. IDENTIFY duplicates:
     → a, b already captured as hero + sublabel → not needed as bullets
     → c, d are additional crisis metrics → could be bullets OR second slide
     → e, g say similar things (can't cover everything) → merge
     → f, h say similar things (quality suffers) → merge

  3. GROUP into clusters:
     → Coverage gap: e + g → "Security staff cannot cover all areas 24/7"
     → Detection failure: f + h → "Critical events detected too late to intervene"
     → Scale problem: c → "42% of monitoring systems past end-of-life"
     → (a, b = hero stat; d = promoted to another slide or banner)

  4. WRITE leading with conclusions:
     → "Security staff cannot cover all areas 24/7" ✓ (starts with subject)
     → "Critical events detected too late to intervene" ✓ (starts with subject)
     → "Network too large for point-based surveillance" ✓ (starts with subject)

  5. ENFORCE parallel structure:
     → All three start with noun-phrase subject → consistent ✓

  6. TRIM:
     → "Security staff cannot cover all areas 24/7" = 8 words ✓
     → "Critical events detected too late to intervene" = 7 words ✓
     → "Network too large for point-based surveillance" = 7 words ✓

  7. VERIFY: Do the 3 bullets explain WHY 688 deaths happen? YES ✓

  BULLETS:
    - Security staff cannot cover all areas 24/7
    - Critical events detected too late to intervene
    - Network too large for point-based surveillance

═══════════════════════════════════════════════
STEP 5d: EVIDENCE SELECTION REASONING
═══════════════════════════════════════════════

  1. INVENTORY:
     → Tier 1: 688 deaths (Federal Rail Report [P1-1])
     → Tier 1: 2,661 attacks (BKA [P1-2])
     → Tier 1: 42% outdated systems (infrastructure audit)
     → Tier 1: €2.8M emergency costs (DB internal)
     → Tier 3: "cannot cover 24/7" (logical argument)
     → Tier 3: "detected too late" (logical argument)

  2. HERO evidence: 688 deaths → most convincing for any audience

  3. SELECT supporting: 2,661 (sublabel), remaining Tier 3 points as context bullets
     → 42% and €2.8M are strong but serve different slide messages
     → Save for four-quadrants slide or investment slide

  4. PLACEMENT:
     → 688 → Hero-Stat-Box Number
     → 2,661 → Sublabel
     → Tier 3 arguments → Context-Box bullets
     → 42%, €2.8M → separate slide (second crisis slide)
     → Citation <sup>[1](url)</sup> preserved in Context-Box bullets where claims appear

  5. VERIFY alignment:
     → Headline: "688 Lives Lost Annually..."
     → Evidence: 688 as hero, reasons WHY as bullets → proves the claim ✓

═══════════════════════════════════════════════
STEP 5 OUTPUT: COMPLETE SLIDE COPY
═══════════════════════════════════════════════

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
      - "Security staff cannot cover all areas 24/7 <sup>[1](https://eba.bund.de/report)</sup>"
      - "Critical events detected too late to intervene <sup>[2](https://bka.de/stats)</sup>"
      - "Network too large for point-based surveillance"

  Bottom-Banner:
    Text: Germany leads EU statistics in rail incidents

  Speaker-Notes: |
    >> WHAT YOU SAY
    [Opening]: "Ask: 'How many preventable deaths on German rails annually?'"
    [Key point]: "688 is a 3-year average — trend rising: 612, 679, now 773."
    [Pause]: Let the number sink in.
    [Transition]: "These numbers make the 'why now' question unavoidable..."

    >> WHAT YOU NEED TO KNOW
    - Source: 688 is a 3-year average (2021-2023) from the
      [Federal Rail Safety Report 2024](https://eba.bund.de/report), Section 4.2.
    - 2,661 attacks figure comes from [BKA Statistics](https://bka.de/stats), not rail safety data
    - If asked about regional variance: Bavaria = 23% of incidents
    - €2.8M emergency costs addressed separately in the investment slide

  Source: "[Federal Rail Safety Report 2024](https://eba.bund.de/report)"
```

---
