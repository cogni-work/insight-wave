# Corporate Visions Story Arc

## Arc Metadata

**Arc ID:** `corporate-visions`
**Display Name:** Corporate Visions
**Display Name (German):** Corporate Visions

**Elements (Ordered):**
1. Why Change: The Unconsidered Need
2. Why Now: The Closing Window
3. Why You: Strategic Positioning
4. Why Pay: The Business Case

**Elements (German):**
1. Warum Veränderung: Der unberücksichtigte Bedarf
2. Warum jetzt: Das sich schließende Zeitfenster
3. Warum Sie: Strategische Positionierung
4. Geschäftliche Auswirkungen: Der Business Case

## Word Proportions

Section lengths are expressed as proportions of the total target length. This keeps the arc's rhetorical balance intact regardless of narrative length. To compute word ranges for a given `--target-length T`: apply +/-15% band to get `[T*0.85, T*1.15]`, then multiply each proportion.

| Element | English Header | German Header | Proportion | Default Range (T=1675) |
|---------|----------------|---------------|-----------|------------------------|
| Hook | *(Dynamic based on finding)* | *(Dynamic)* | 10% | 143-193 |
| Why Change | Why Change: The Unconsidered Need | Warum Veränderung: Der unberücksichtigte Bedarf | 27% | 384-519 |
| Why Now | Why Now: The Closing Window | Warum jetzt: Das sich schließende Zeitfenster | 21% | 299-404 |
| Why You | Why You: Strategic Positioning | Warum Sie: Strategische Positionierung | 27% | 384-519 |
| Why Pay | Why Pay: The Business Case | Geschäftliche Auswirkungen: Der Business Case | 15% | 213-290 |

**Proportions sum to 100%.** Default total: 1,675 words (customizable via `--target-length`). Tolerance: +/-10% of computed section midpoint.

## Detection Configuration

### Research Type Mapping

This arc is selected when:
- `research_type: "generic"`
- `research_type: "market"`
- **Default fallback** (when no other arc matches)

### Content Analysis Keywords

*(Not applicable - this is the default fallback arc)*

### Detection Threshold

N/A (default arc)

## Use Cases

**Best For:**
- Market research projects
- Competitive positioning analysis
- Sales enablement content
- B2B value proposition development
- Strategic business recommendations
- Executive decision-making support

**Typical Research Types:**
- Generic research (no specific domain focus)
- Market analysis and trends
- Business opportunity assessment
- Strategic initiative planning

## Element Definitions

### Element 1: Why Change (The Unconsidered Need)

**Purpose:**
Reframe research findings as an unconsidered need—a problem executives didn't know they had, or didn't realize was solvable.

**Source Content:**
- Executive Summary (primary)
- Cross-Dimensional Patterns (tensions, emergent implications)
- Megatrends (paradigm shifts)
- Dimension syntheses (counterintuitive findings)

**Transformation Approach:**
Use PSB (Problem-Solution-Benefit) structure:
- **Problem (150 words):** Current assumption/status quo and why it's incomplete
- **Solution (150 words):** Unconsidered reality revealed by research
- **Benefit (100-200 words):** Competitive advantage for early recognizers

**Key Techniques:**
- Contrast structure: "Most organizations think X. But research shows Y."
- Evidence-based reframing with citations
- End with competitive implication

**Pattern Reference:** `why-change-patterns.md`

---

### Element 2: Why Now (The Closing Window)

**Purpose:**
Establish urgency through forcing functions—external pressures, deadlines, tipping points that make action time-sensitive.

**Source Content:**
- **Trends in "Act" column (primary)** - Loaded from `content_map.trend_entities` (11-trends/data/), filtered to urgency="Act"
- Megatrends (macro forces) - NOT loaded for Corporate Visions arc
- Executive Summary (urgency indicators) - Fallback if trends not available
- Dimension syntheses (time-bound developments) - NOT loaded (redundant with Executive Summary)

**Source Content Mapping Example:**

```javascript
// Loaded from 11-trends/data/trend-001.md
{
  "trend_id": "trend-001",
  "title": "EU AI Act Compliance Deadline",
  "urgency": "Act",
  "timeline": "Q1 2027",
  "dimension": "regulatory",
  "body_preview": "Mandatory compliance for AI systems in healthcare by January 2027..."
}

// Maps to forcing function:
"The EU AI Act mandates compliance for all healthcare AI systems by Q1 2027,
with non-compliance penalties reaching €20M or 4% of global revenue—whichever
is higher. Organizations lacking certified AI governance frameworks face market
exclusion and legal liability."
```

**Transformation Approach:**
Stack 2-3 forcing functions from loaded Trends:
- **Forcing function (100 words):** External pressure from trend + specific deadline from trend.timeline
- **Quantified urgency (100-150 words):** Extract timeline from trend.timeline and cost implications from trend.body_preview
- **Window of opportunity (100-150 words):** Compare trends with urgency="Act" vs urgency="Plan" to show window closing

**Key Techniques:**
- Specific timelines from trend.timeline field ("Q2 2027" not "soon")
- Quantified consequences from trend.body_preview ("€420K penalties" not "financial risk")
- Before/after contrasts (early movers vs. late starters) by comparing trend confidence scores

**Pattern Reference:** `why-now-patterns.md`

---

### Element 3: Why You (Strategic Positioning)

**Purpose:**
Convert strategic recommendations into Power Positions—capabilities that create competitive advantage and are difficult to replicate.

**Source Content:**
- Strategic Recommendations (primary)
- Dimension syntheses (strategic implications)
- Executive Summary (positioning opportunities)

**Transformation Approach:**
Create 2-3 Power Positions using IS-DOES-MEANS structure:
- **IS (What it is):** Specific, concrete definition (1-2 sentences)
- **DOES (What it does for you):** Quantified outcomes with You-Phrasing
- **MEANS (Why competitors struggle):** Explain the moat/differentiation

**Key Techniques:**
- You-Phrasing throughout ("You reduce...", "Your systems...")
- Quantify DOES layer with Number Plays
- Explain competitive moat in MEANS (time, tacit knowledge, experience)

**Pattern Reference:** `why-you-patterns.md`

---

### Element 4: Why Pay (The Business Case)

**Purpose:**
Quantify the cost of inaction through compound impact calculation—stacking multiple cost dimensions to create undeniable financial case.

**Source Content:**
- Cross-Dimensional Patterns (risks, costs)
- Trends (cost implications)
- Strategic Recommendations (investment requirements)
- Executive Summary (financial impacts)

**Transformation Approach:**
Compound Impact Calculation:
```
Total Cost of Inaction =
  Regulatory Penalties +
  Talent Premium +
  Market Position Loss +
  Opportunity Cost
```

Each component: quantification + time horizon (3-year) + citation

**Key Techniques:**
- Stack 3-4 cost dimensions
- Use 3-year horizon (standard executive planning)
- Before/after contrast: "Delay costs X vs. Action costs Y"
- End with simple ratio: "Action costs less than inaction by 2-3x"

**Pattern Reference:** `why-pay-patterns.md`

## Narrative Flow

### Hook Construction

**Approach:**
Open with the most surprising finding from the research—a counterintuitive data point, an unexpected pattern, or a paradigm-shifting insight.

**Pattern:**
```markdown
[Quantified surprise] + [Challenge to conventional wisdom]

Example:
"Organizations investing 40% more in AI deployment achieve 60% lower adoption rates than minimal investors<sup>[1]</sup>. This inverse correlation reveals a counterintuitive truth: AI success depends less on technology spend and more on workflow redesign."
```

**Source:** Most surprising finding in Executive Summary

**Word Target:** 10% of target length

---

### Element Transitions

**Hook → Why Change:**
- Hook introduces surprising finding
- Why Change reframes finding as unconsidered need
- **Transition pattern:** "This gap between X and Y defines the challenge."

**Why Change → Why Now:**
- Why Change establishes the problem
- Why Now introduces forcing functions
- **Transition pattern:** "Three converging forces make action urgent."

**Why Now → Why You:**
- Why Now creates urgency
- Why You provides strategic response
- **Transition pattern:** "Organizations that thrive don't just react—they build capabilities."

**Why You → Why Pay:**
- Why You outlines positioning
- Why Pay quantifies inaction cost
- **Transition pattern:** "The cost of delay compounds."

---

### Closing Pattern

**Final Sentence:**
Simple, undeniable business case comparison.

**Examples:**
- "Action costs less than inaction by 2-3x."
- "The choice: invest €1.2M strategically, or lose €3.1M reactively."
- "Proactive positioning costs one-third the price of reactive catch-up."

## Citation Requirements

### Citation Density

**Target:** 15-25 total citations across the narrative (scale proportionally for longer targets)
**Ratio:** Approximately 1 citation per 60-100 words

### Citation Distribution

**Why Change (data-heavy):** 5-8 citations
**Why Now (forcing functions):** 6-10 citations (highest density)
**Why You (strategic recommendations):** 3-5 citations
**Why Pay (cost calculations):** 4-7 citations

### Citation Format

```markdown
Claim text<sup>[N](12-synthesis/synthesis-{dimension}.md)</sup>
```

**Required Citations:**
- ✓ Quantitative data (MUST)
- ✓ Strategic recommendations (MUST)
- ✓ Forcing functions (MUST)
- ✓ Cost calculations (MUST)
- ~ Unconsidered needs (Should have supporting citation)

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Why Change, Why Now, Why You, Why Pay)
- [ ] Hook present (within hook proportion of target)
- [ ] Word counts within computed proportional ranges (+/-10% tolerance)
- [ ] Smooth transitions between elements
- [ ] Each element serves distinct purpose (no overlap)

### Corporate Visions Techniques Applied

- [ ] **Why Change:** PSB structure used (Problem-Solution-Benefit)
- [ ] **Why Change:** Contrast structure applied ("Most think X, research shows Y")
- [ ] **Why Change:** Ends with competitive implication
- [ ] **Why Now:** 2-3 forcing functions stacked
- [ ] **Why Now:** Specific timelines (not vague "soon")
- [ ] **Why Now:** Before/after contrasts (early vs. late movers)
- [ ] **Why You:** 2-3 Power Positions created
- [ ] **Why You:** IS-DOES-MEANS structure applied to each position
- [ ] **Why You:** You-Phrasing used throughout DOES layer
- [ ] **Why Pay:** 3-4 cost dimensions stacked
- [ ] **Why Pay:** 3-year horizon used
- [ ] **Why Pay:** Ends with simple ratio comparison

### Evidence Quality

- [ ] Every major claim has citation
- [ ] Citations point to dimension syntheses (12-synthesis/)
- [ ] Quantitative data used throughout
- [ ] Number Plays applied (ratios, before/after, compound calculations)
- [ ] Citation density: 15-25 total citations

### Narrative Coherence

- [ ] Hook transitions naturally to Why Change
- [ ] Why Change establishes problem that Why Now makes urgent
- [ ] Why You provides strategic response to Why Change/Why Now
- [ ] Why Pay quantifies business case for Why You positioning
- [ ] Closing sentence provides undeniable comparison

### Executive Appeal

- [ ] Opening hook grabs attention (surprising data)
- [ ] Unconsidered need challenges assumptions
- [ ] Forcing functions create credible urgency
- [ ] Power Positions feel achievable yet differentiated
- [ ] Cost of inaction calculation is undeniable

## Common Pitfalls

### Why Change Pitfalls

❌ **Stating obvious problems:** "Organizations need to adopt AI"
✓ **Reframing to unconsidered:** "Organizations need to redesign decision-making for human-AI collaboration"

❌ **Academic tone:** "Our analysis reveals..."
✓ **Executive framing:** "Most executives view X as Y. This framing misses..."

❌ **Single perspective:** Only problem or only solution
✓ **PSB structure:** Problem → Solution → Benefit

### Why Now Pitfalls

❌ **Vague urgency:** "The market is changing rapidly"
✓ **Specific forcing function:** "EU AI Act provisions take effect January 2027"

❌ **Single force:** Only one urgency driver
✓ **Stacked forces:** 2-3 converging pressures

❌ **No quantification:** "There will be penalties"
✓ **Quantified consequence:** "€420K non-compliance penalties per violation"

### Why You Pitfalls

❌ **Generic recommendations:** "Invest in training"
✓ **Power Position:** "Clinical-AI Integration Design: A systematic approach to workflow redesign..."

❌ **Feature lists:** "The system has X, Y, Z"
✓ **IS-DOES-MEANS:** "What it is, What it does for YOU, Why competitors struggle to copy"

❌ **Weak differentiation:** "Be good at this"
✓ **Competitive moat:** "This requires 6-12 months of ethnographic observation—purchases are fast, wisdom is slow"

### Why Pay Pitfalls

❌ **Single cost factor:** "This will be expensive"
✓ **Compound calculation:** "Penalties €960K + Talent premium €1.2M + Lost revenue €60-90M"

❌ **Vague horizon:** "Over time"
✓ **Specific timeframe:** "Over 3 years"

❌ **Complex comparison:** Multiple percentages
✓ **Simple ratio:** "Action costs less than inaction by 2-3x"

## Version History

- **v1.0.0:** Original hard-coded implementation in story-arc-mapping.md
- **v2.0.0:** Restructured into arc-definition.md with separate pattern files

## See Also

- `../arc-registry.md` - Master index of all story arcs
- `why-change-patterns.md` - Unconsidered need transformation patterns
- `why-now-patterns.md` - Forcing function construction patterns
- `why-you-patterns.md` - Power Position (IS-DOES-MEANS) patterns
- `why-pay-patterns.md` - Cost of inaction calculation patterns
