# Phase 4b: Arc-Specific Insight Summary (technology-futures)

**Arc Framework:** What's Emerging -> Converging -> Possible -> Required
**Arc:** `technology-futures` (Tier 4) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,675 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## What's Emerging: Technology Horizon`
- `## What's Converging: Integration Points`
- `## What's Possible: Application Scenarios`
- `## What's Required: Capability Development`

**German (if `language: de`):**
- `## Was Entsteht: Technologie-Horizont`
- `## Was Konvergiert: Integrationspunkte`
- `## Was Möglich Ist: Anwendungsszenarien`
- `## Was Erforderlich Ist: Kompetenzentwicklung`

---

## Step 4.1.1: Load Evidence Entities (Context Tier 4)

This arc loads the RICHEST entity context of all arcs -- 4 entity types. Each serves a distinct purpose:

- **Findings** ground the narrative in verified evidence ("what did we discover?")
- **Sources** provide attribution credibility ("who says so?")
- **Trends (watch + act)** supply the temporal dimension essential to technology-futures ("what's moving and how fast?"). Only load trends with `planning_horizon` of "watch" or "act" -- exclude "monitor" horizon as too early-stage.
- **Concepts** provide domain vocabulary and definitional precision that distinguishes expert analysis from superficial commentary ("what exactly do we mean by X?")

**Load:**
- Top 20 findings from `04-findings/data/` (quality_score >= 0.65)
- Top 15 sources from `07-sources/data/` (reliability_score >= 0.8)
- Dimension-scoped trends from `11-trends/data/` (planning_horizon = "watch" or "act")
- Dimension-scoped concepts from `05-domain-concepts/data/`

**After loading, take stock:** Which findings are strongest? Which trends have the most narrative potential? Which concepts need to be woven in as precise vocabulary? This inventory feeds the transformation directly.

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Absorb the Source Material

Read `synthesis-cross-dimensional.md` in full. Before proceeding:

1. **Central thesis?** The single most important claim -- this becomes your narrative spine.
2. **2-3 strongest evidence threads?** Claims backed by the most findings. These receive deepest expansion.
3. **Tensions or contrasts?** Technology-futures narratives thrive on tension between emergence and maturity, possibility and constraint.
4. **Research question?** This becomes the subtitle and should echo in the hook.

---

### Sub-step B: Map Content to Arc Elements

Explicitly assign source material to each element before writing:

- **What's Emerging:** Which findings/trends describe NEW technologies or approaches? Look for `planning_horizon: "watch"` trends. Look for concepts defining novel technical vocabulary.
- **What's Converging:** Which findings show technologies COMBINING or reinforcing each other? Look for `planning_horizon: "act"` trends. Look for concepts bridging multiple domains.
- **What's Possible:** Which findings suggest CONCRETE applications or use cases? This element translates the abstract (emerging + converging) into the tangible.
- **What's Required:** Which findings identify GAPS, prerequisites, or capabilities that need building? This provides the strategic call-to-action.

**Decision rule:** If a finding could fit multiple elements, assign it where it provides the STRONGEST evidence. Each finding in exactly one element.

**Wikilink distribution:** Target 40-50 total, ~10-13 per element. Mix entity types within each element: at least 2 finding wikilinks, 1-2 source wikilinks, 1-2 trend wikilinks, and 1-2 concept wikilinks. The diversity of Tier 4 entity types is what makes this arc analytically rich.

---

### Sub-step C: Generate the Title

What makes this research DISTINCTIVE?
- Would a technology executive stop scrolling?
- Does it capture the core tension or opportunity?
- Is it specific to THIS research, or could it apply to any technology report?

Good titles often use a colon pattern: `{Specific Subject}: {Arc-Informed Angle}`.

---

### Sub-step D: Write the Hook Paragraph

The hook (~11% of target length) accomplishes three things:
1. **Create narrative tension** -- open with a concrete, surprising observation. Not a generic statement about technology change.
2. **Establish the research question** -- echo the subtitle naturally.
3. **Signal the arc trajectory** -- hint at the Emerging -> Converging -> Possible -> Required progression without naming it.

Lead with the single most compelling data point, trend, or contrast.

---

### Sub-step E: Expand Each Arc Element (~24% each for Emerging/Converging/Possible, ~17% for Required)

For each element, follow this micro-sequence:

1. **Lead with the element's core assertion** -- one sentence that captures the main point (Pyramid Principle).
2. **Ground it immediately** -- within the first 2-3 sentences, cite a finding with a wikilink. Do not let more than 50 words pass without evidence.
3. **Develop with evidence layering** -- weave in additional findings, trends, and concepts. Each point should BUILD on the previous, not merely list alongside it. Use transitions: "this convergence accelerates because...", "the emerging pattern becomes clearer when..."
4. **Integrate concepts as precision vocabulary** -- when you reference a domain concept, use its wikilink and briefly activate its meaning in context. Show why the precise term matters.
5. **Weave in trends for temporal grounding** -- "watch" trends belong primarily in What's Emerging; "act" trends in What's Converging and What's Required. Connect trends to the TIME dimension: how fast, how soon, how urgent.
6. **Close with a forward-facing sentence** -- each element should create momentum toward the next. What's Emerging ends by hinting at convergence; What's Converging at possibility; What's Possible at requirements.

**Journalistic techniques to apply:**
- Number Plays for specific metrics from findings
- Contrast Structure: "While X is emerging, Y remains..."
- You-Phrasing: "Organizations that..."
- Compound Impact: "This means not only X, but also Y, and ultimately Z"

---

### Sub-step F: Self-Review

Before finalizing:

1. **Narrative flow:** Does What's Emerging flow naturally into What's Converging? Does What's Possible set up What's Required?
2. **Evidence balance:** If any element has fewer than 8 wikilinks, add more. Total should be 40-50.
3. **Entity type diversity:** All 4 types (findings, sources, trends, concepts) should appear across the narrative. A technology-futures narrative citing only findings and sources operates at Tier 1 quality.
4. **Word count:** Within target length range. Hook ~11%, Emerging/Converging/Possible ~24% each, Required ~17%.
5. **Title check:** Specific and compelling? Works as a headline?

**Common failure mode:** Technology-futures narratives often run LONG because of the rich Tier 4 context. If over the target length ceiling, tighten the weakest element first.

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
