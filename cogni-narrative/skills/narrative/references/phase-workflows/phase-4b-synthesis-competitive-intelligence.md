# Phase 4b: Arc-Specific Insight Summary (competitive-intelligence)

**Arc Framework:** Landscape -> Shifts -> Positioning -> Implications
**Arc:** `competitive-intelligence` (Tier 1) | **Output:** `insight-summary.md` at project root (1,450-1,900 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Landscape: Competitive Overview`
- `## Shifts: Market Dynamics`
- `## Positioning: Strategic Options`
- `## Implications: Action Priorities`

**German (if `language: de`):**
- `## Landschaft: Wettbewerbsübersicht`
- `## Verschiebungen: Marktdynamik`
- `## Positionierung: Strategische Optionen`
- `## Implikationen: Handlungsprioritäten`

---

## Step 4.1.1: Load Evidence Entities (Context Tier 1)

This arc uses minimal entity types (findings + sources only). No trends, megatrends, or concepts are loaded. Every finding and source must work harder to provide evidence grounding across all 4 elements.

**Load:**
- Top 20 findings from `04-findings/data/` (quality_score >= 0.65)
- Top 15 sources from `07-sources/data/` (reliability_score >= 0.8)

If directories contain fewer files than requested, load all available.

**After loading, inventory what you have:**
- How many findings? Which dimensions do they cover?
- How many sources? What types (academic, industry, news)?
- Any gaps -- dimensions with no findings coverage? Flag these now; you'll need to rely on synthesis content for those dimensions.

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Read and Decompose the Source

Read `synthesis-cross-dimensional.md` in full. Before writing:

1. **Core competitive insight?** State it in one sentence.
2. **Market structure?** Fragmented, concentrated, oligopoly, duopoly?
3. **Which competitors or competitive forces are mentioned?**
4. **What shifts in competitive dynamics are identified?**
5. **What strategic recommendations or positioning opportunities emerge?**
6. **Most surprising finding?** (Seeds your hook.)

Map source content to elements:
- **Landscape:** market structure, current positions, competitive bases, established moats
- **Shifts:** momentum indicators, strategic moves, capability races, emerging/declining threats
- **Positioning:** uncontested spaces, capability gaps, timing advantages, differentiation axes
- **Implications:** action items, urgency indicators, timelines, response scenarios

Note content gaps. If the synthesis provides strong Landscape/Shifts material but thin Positioning/Implications material, you'll need to reason more deeply from evidence entities.

---

### Sub-step B: Plan the Evidence Distribution

You have findings and sources as your only entity types (Tier 1). Plan the distribution:

1. **Assign findings to elements.** Findings about market structure -> Landscape. Changes/momentum -> Shifts. Gaps/opportunities -> Positioning. Actions/urgency -> Implications.
2. **Target at least 2 finding citations per element** (8+ total).
3. **Target 10-13 wikilinks per element** (40-50 total). Every wikilink must correspond to an actually loaded entity.
4. **Identify your strongest evidence.** Which 3-5 findings contain quantified data? Mark these for Number Plays and Comparative Anchoring.

---

### Sub-step C: Craft the Title and Hook

**Title:** Frame it as a tension or paradox (e.g., "The Fragmentation Paradox: How Market Leaders Are Losing by Winning"). It must signal the Landscape -> Implications progression and be specific to this research domain.

**Hook (150-200 words):**
- Open with a surprising competitive shift or market structure change
- Challenge conventional wisdom about the competitive landscape
- Pattern: "[Established player/assumption] [surprising data point] signals [structural shift]."
- Ground with at least 1 citation
- Preview the arc progression without naming elements

---

### Sub-step D: Draft Each Arc Element

**D1. Landscape: Competitive Overview (350-450 words)**

Think: What market structure? Who leads? What competitive bases operate? What moats exist?

Write:
- Open with competitive structure overview (Pyramid Principle: answer first)
- Decompose aggregate numbers into segment-level detail (key Landscape technique: top-line to segment divergence)
- Identify competitive clusters and explain their logic
- Apply Number Plays: Specific Quantification and Comparative Anchoring
- Ground every quantitative claim with a citation

*Transition:* "Three [momentum shifts / strategic moves] are reshaping this landscape."

**D2. Shifts: Market Dynamics (350-450 words)**

Think: What momentum indicators? Strategic moves underway? Which threats emerging/declining? Rate of change?

Write:
- Contrast static metrics with dynamic segment trajectories (key technique: velocity analysis)
- Show momentum attribution: where is growth coming from?
- Project future trajectory using evidence data (Compound Impact where data supports)
- Identify the competitive logic shift (breadth -> specialization, cost -> value, scale -> agility)
- Apply Forcing Functions: what external pressures accelerate these shifts?

*Transition:* "These shifts create strategic gaps in [specific areas]."

**D3. Positioning: Strategic Options (350-450 words)**

Think: Uncontested spaces? Capability gaps? Timing advantages? Differentiation axes?

Write:
- Connect shifts to the gaps they create (build on Shifts, don't repeat)
- Apply IS-DOES-MEANS for each positioning option:
  - IS: What the option concretely is
  - DOES: Quantified advantage (You-Phrasing: "Your organization gains...")
  - MEANS: Why competitors struggle to replicate
- Apply PSB for at least one unconsidered positioning opportunity
- Use Contrast Structure: "Most organizations pursue X. Evidence suggests Y creates advantage."

*Transition:* "Capturing these [gaps / positions] requires time-bound action."

**D4. Implications: Action Priorities (350-450 words)**

Think: Immediate actions (0-6 months)? Near-term moves (6-18 months)? Capability building (18-36 months)? Competitive response scenarios?

Write:
- Structure around time horizons: immediate, near-term, capability-building
- Apply Forcing Functions: link each action to its timing pressure
- Use Compound Impact: cost of inaction if delayed
- Include competitive response scenarios: "If [competitor action], then [required response]"
- Close with: "Strategic gaps close by [timeframe]. Organizations moving by [date] capture positions."

---

### Sub-step E: Self-Review

1. **Word count:** 1,450-1,900 total? Each element 350-450?
2. **Arc coherence:** Landscape -> Shifts -> Positioning -> Implications builds logically? "What is" -> "what's changing" -> "where to play" -> "what to do"?
3. **Evidence:** >= 8 finding citations distributed across elements?
4. **Wikilinks:** 40-50 total? Every slug references a loaded entity?
5. **Techniques applied:** Number Plays (3+ instances), Contrast Structure (2+), Forcing Functions (1+ in Shifts or Implications), You-Phrasing (2+ in Positioning/Implications)?
6. **Tier 1 quality:** Did you maximize insight from limited entity types? Any loaded findings unused?

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
