# Phase 4b: Arc-Specific Insight Summary (theme-thesis)

**Arc Framework:** Why Change -> Why Now -> Why You -> Why Pay
**Arc:** `theme-thesis` (Tier 2) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,675 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Why Change: The Unconsidered Need`
- `## Why Now: The Closing Window`
- `## Why You: The Portfolio Response`
- `## Why Pay: The Business Case`

**German (if `language: de`):**
- `## Warum Veränderung: Der unberücksichtigte Bedarf`
- `## Warum jetzt: Das sich schließende Zeitfenster`
- `## Warum Sie: Die Portfolio-Antwort`
- `## Geschäftliche Auswirkungen: Der Business Case`

---

## Step 4.1.1: Load Evidence Entities (Context Tier 2)

Before loading, understand what each entity type contributes to this arc:

- **Findings** ground the narrative in verified evidence. They answer "what did we discover?"
- **Sources** provide attribution credibility. They answer "who says so?"

**Load:**
- Top 20 findings from `04-findings/data/` (quality_score >= 0.65)
- Top 15 sources from `07-sources/data/` (reliability_score >= 0.8)

**After loading, categorize each entity by which arc element it serves:**
1. Which findings reveal an *unconsidered need* (counterintuitive or overlooked)? → **Why Change**
2. Which findings contain *timelines, deadlines, or urgency indicators*? → **Why Now**
3. Which findings suggest *strategic capabilities or portfolio responses*? → **Why You**
4. Which findings contain *cost data, risk quantification, or financial impact*? → **Why Pay**
5. Which sources are most authoritative (highest reliability_score)? Prioritize these for high-impact citations.

---

## Step 4.1.4: Extended Thinking Sub-steps

### Sub-step A: Internalize the Source Material

Read the source material carefully. Before writing anything:

1. What is the single most surprising or counterintuitive finding? (This becomes your narrative hook.)
2. What theme-level investment question does the evidence answer? (This frames the unconsidered need.)
3. What forcing functions create urgency? (Look for Act-horizon data with timelines.)
4. What capabilities or solutions does the evidence support? (These become Power Positions.)
5. What cost data supports the business case? (These feed compound impact.)

### Sub-step B: Map Evidence to Arc Elements

Create a mental (or written) mapping:

| Finding | Best Arc Element | Why |
|---------|-----------------|-----|
| [finding-1] | Why Change | Counterintuitive — challenges status quo |
| [finding-2] | Why Now | Contains Q1 2027 regulatory deadline |
| [finding-3] | Why You | Suggests capability that creates moat |
| [finding-4] | Why Pay | Contains cost/revenue data |

### Sub-step C: Draft in Arc Sequence

1. **Hook** (8%): Most surprising quantified finding + theme question reframed
2. **Why Change** (25%): PSB structure — status quo assumption, unconsidered reality, competitive shift
3. **Why Now** (20%): Stack 2-3 forcing functions with timeline math
4. **Why You** (30%): 1-3 Power Positions with IS-DOES-MEANS
5. **Why Pay** (17%): Compound impact calculation → ratio

### Sub-step D: Apply Techniques

Per element, check:
- Why Change: PSB applied? Contrast Structure? Competitive implication at end?
- Why Now: Specific timelines (not "soon")? Before/after contrast? Window closing?
- Why You: IS-DOES-MEANS? You-Phrasing in DOES? Moat in MEANS?
- Why Pay: 3+ cost dimensions? 3-year horizon? Simple ratio at end?

### Sub-step E: Validate

Run through the quality gates in `arc-definition.md`:
- All 4 elements present?
- Word proportions within +/-10%?
- Citation density 8-15 total?
- Transitions smooth between elements?
- Closing sentence is simple ratio?

---

## Special Considerations for theme-thesis Arc

**This arc is designed for theme-level narratives within TIPS trend reports.** When invoked standalone via `cogni-narrative:narrative --arc-id theme-thesis`, the input should contain theme-structured content with:
- Value chain evidence (T→I→P→S candidates)
- Solution templates or portfolio responses
- Quantitative claims with source citations

If the source content lacks theme structure, consider using `corporate-visions` instead — it handles generic research content better.

**The theme-thesis arc's key differentiator is the Why You element**, which frames solution templates as Power Positions using IS-DOES-MEANS. If the input lacks solution template data, the arc still works but Why You draws entirely from strategic possibility findings.

---

## Version History

- **v1.0.0:** Initial phase-4b workflow for theme-thesis arc
