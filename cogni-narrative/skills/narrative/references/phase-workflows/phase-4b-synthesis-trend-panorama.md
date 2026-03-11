# Phase 4b: Arc-Specific Insight Summary (trend-panorama)

**Arc Framework:** Forces -> Impact -> Horizons -> Foundations (TIPS: T -> I -> P -> S)
**Arc:** `trend-panorama` (Tier 4) | **Output:** `insight-summary.md` at project root (1,450-1,900 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

**Trend-panorama additions to shared template:** Add `total_trends` and `horizon_distribution` (act/plan/observe counts) to the YAML frontmatter.

---

## Arc-Specific Headers

**English:**
- `## Forces: External Pressures & Market Signals`
- `## Impact: Value Chain Disruption`
- `## Horizons: Strategic Possibilities`
- `## Foundations: Capability Requirements`

**German (if `language: de`):**
- `## Kräfte: Externe Einflüsse & Marktsignale`
- `## Wirkung: Wertschöpfungsdynamik`
- `## Horizonte: Strategische Möglichkeiten`
- `## Fundamente: Kompetenzanforderungen`

---

## Step 4.1.1: Load Trend Evidence (Context Tier 4)

This arc loads the RICHEST source context because it synthesizes an entire trend landscape. Each source type has a distinct purpose:

- **Trend-scout output** provides structured candidate data with scores, horizons, dimensions, and confidence tiers. It is the BACKBONE -- every narrative claim traces back to a trend candidate.
- **Trend entities** (11-trends/data/) provide detailed trend narratives with evidence and implications. The EVIDENCE layer.
- **TIPS trend report** (tips-trend-report.md) provides pre-synthesized TIPS dimension narratives. If available, extract rather than construct.
- **Dimension syntheses** (12-synthesis/data/) reveal emergent insights beyond individual trends.
- **Executive Summary** (research-hub.md or synthesis-cross-dimensional.md) provides cross-dimensional context for hook and transitions.

**Key challenge:** This arc processes ~52 trends across 4 dimensions. At 1,450-1,900 words (~30 words per trend), you cannot give each individual attention. The key skill is SYNTHESIS -- clustering trends into force narratives, impact stories, opportunity portfolios, and capability roadmaps.

**Loading priority:**
1. `trend-scout-output.json` from `.metadata/` or source directory (REQUIRED)
2. `tips-trend-report.md` from source/project directory (HIGH VALUE if exists)
3. Dimension syntheses from `12-synthesis/data/`
4. Top trend entities from `11-trends/data/` by dimension and horizon (up to 20)
5. `research-hub.md` or `synthesis-cross-dimensional.md` for executive context

**After loading, build TREND INVENTORY** for each TIPS dimension:
- Trends per horizon (Act/Plan/Observe)
- Top 3 trends by score per horizon
- Subcategory distribution
- Average confidence tier
- Key cross-trend themes

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Build the Trend Inventory

From loaded trend-scout output, construct a mental map:

1. **Per TIPS dimension (T, I, P, S):** How many trends per horizon? Top 3 by score? What subcategory patterns?
2. **Cross-dimensional patterns:** Which Act-horizon trends reinforce each other? Which Plan-horizon trends build on Act foundations? What Observe signals connect across dimensions?
3. **Narrative spine:** What single cross-dimensional insight makes this landscape DISTINCTIVE? This becomes the hook and the thread connecting all 4 elements.

---

### Sub-step B: Map Trend Clusters to Elements

Do NOT plan to mention all trends individually. Instead, cluster into narrative themes:

- **Forces (T):** 3-4 force clusters from externe-effekte trends. Example: "regulatory convergence" (3 regulatory trends), "economic pressure" (2 economic trends). Remaining trends provide supporting evidence.
- **Impact (I):** 3-4 disruption themes from digitale-wertetreiber trends. Show cascading effects between subcategories (CX -> products -> processes).
- **Horizons (P):** 3-4 opportunity portfolios from neue-horizonte trends. Quantify opportunity windows.
- **Foundations (S):** Capability roadmap from digitales-fundament trends. Show dependency chain: culture -> workforce -> technology. Fewer clusters, more sequencing logic.

**Decision rule:** Each trend contributes to exactly one cluster. High-scoring trends (>0.75) get explicit mention; lower-scoring trends strengthen cluster evidence without individual citation.

---

### Sub-step C: Generate the Title

What makes this trend landscape DISTINCTIVE?
- What industry/sector?
- What's the dominant cross-dimensional pattern?
- What would make a strategic executive stop and read?

Title must NOT be "Trend Panorama" or "Trend Analysis." It must reflect the specific industry/topic.

Good patterns:
- "{Industry}: {Number} Trends Reshaping {Specific Area}"
- "{Sector} {Year}: Where Forces Converge"

---

### Sub-step D: Write the Hook Paragraph

The hook (150-200 words) accomplishes:
1. **Establish panoramic scale** -- reference total trend count and dimension breadth
2. **Create urgency** -- highlight Act-horizon trend concentration
3. **Reveal cross-dimensional insight** -- the narrative spine from Sub-step A
4. **Signal the TIPS progression** -- hint at Forces -> Impact -> Horizons -> Foundations

Lead with the single most surprising cross-dimensional finding.

---

### Sub-step E: Synthesize Each Arc Element

For each element, follow this micro-sequence:

1. **Lead with the element's core assertion** -- the dominant pattern across this TIPS dimension. Answer first (Pyramid Principle).

2. **Cascade through horizons:**
   - **Act (lead, ~40% of words):** Highest-scoring, highest-confidence trends. What demands immediate response?
   - **Plan (bridge, ~35% of words):** Emerging trends building on Act foundations. What to prepare for?
   - **Observe (close, ~25% of words):** Weak signals worth monitoring. What could change everything?

3. **Synthesize, don't list.** Each cluster should be a narrative thread, not a bullet point. Show interactions between trends.

4. **Ground in trend data.** Use scores, confidence tiers, and signal intensities as narrative anchors. "Score: 0.84, confidence: high" is more compelling than "very important."

5. **Connect forward:** Each element's closing creates momentum toward the next:
   - Forces -> "These forces translate into..."
   - Impact -> "Disruption creates openings..."
   - Horizons -> "Capturing these requires..."

6. **Apply arc-specific techniques:**
   - Forces: PSB, Forcing Functions, Contrast Structure
   - Impact: Contrast Structure, Compound Impact, Before/After
   - Horizons: You-Phrasing, IS-DOES-MEANS, Opportunity Windows
   - Foundations: IS-DOES-MEANS, Compound Impact, Dependency Sequencing

**Word count targets:**
- Forces: 350-450 words
- Impact: 350-450 words
- Horizons: 350-450 words
- Foundations: 250-350 words

---

### Sub-step F: Self-Review

1. **TIPS coherence:** Forces -> Impact -> Horizons -> Foundations tells a connected story? Clear causal chain? (Forces CAUSE Impact, Impact CREATES Horizons, Horizons REQUIRE Foundations)
2. **Horizon cascade consistency:** Each element follows Act -> Plan -> Observe? Act given most weight?
3. **Synthesis quality:** Count individually named trends. Target: 12-18 out of 52. If >25, you're listing. If <8, you're abstracting too much.
4. **Score/confidence usage:** Trend data used as narrative evidence, not a data dump?
5. **Evidence balance:** Forces 5-8 citations, Impact 4-7, Horizons 4-6, Foundations 3-5. Total: 15-25.
6. **Word count:** 1,450-1,900 total. Per-element within targets.

**Common failure modes:**
- Over-listing: 52 trends tempt enumeration. If it reads like a catalog, replace individual mentions with cluster synthesis.
- Forces/Impact blur: maintain distinction -- Forces = external pressures ON the organization; Impact = changes WITHIN the value chain.
- Mechanical horizon cascade: vary transition language between Act/Plan/Observe across elements.

**Arc-specific validation additions** (beyond shared-steps.md gates):
- TIPS dimensions correctly mapped (T->Forces, I->Impact, P->Horizons, S->Foundations)
- Horizon cascade present in each element
- Trend synthesis (not listing): <= 18 individually named trends
- Frontmatter includes `total_trends` and `horizon_distribution`

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
