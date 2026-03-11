# Phase 4b: Arc-Specific Insight Summary (industry-transformation)

**Arc Framework:** Forces -> Friction -> Evolution -> Leadership
**Arc:** `industry-transformation` (Tier 3) | **Output:** `insight-summary.md` at project root (1,450-1,900 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Forces: Transformation Drivers`
- `## Friction: Barriers to Change`
- `## Evolution: Pathway Forward`
- `## Leadership: Strategic Imperatives`

**German (if `language: de`):**
- `## Kräfte: Makro-Treiber`
- `## Reibung: Widerstandspunkte`
- `## Evolution: Strukturelle Veränderungen`
- `## Führung: Positionierungsstrategien`

---

## Step 4.1.1: Load Evidence Entities (Context Tier 3)

Tier 3 uses ALL planning horizons for trends plus megatrends. Each entity type contributes differently:

- **Findings** ground claims in evidence -- these become inline citations
- **Sources** establish credibility
- **Trends (all horizons)** feed Forces and Friction -- short-horizon trends reveal immediate friction, long-horizon trends reveal structural forces
- **Megatrends** are primary inputs for Forces -- they define macro-level drivers reshaping the industry

**Load:**
- Top 20 findings from `04-findings/data/` (quality_score >= 0.65)
- Top 15 sources from `07-sources/data/` (reliability_score >= 0.8)
- Dimension-scoped trends from `11-trends/data/` (all planning horizons)
- Megatrends from `06-megatrends/data/` (if present)

**After loading, categorize each entity:**
- Macro driver or external pressure? -> Forces
- Barrier, resistance, or adoption challenge? -> Friction
- Structural change, new models, or future state? -> Evolution
- Positioning, strategy, or competitive advantage? -> Leadership
- Some entities serve multiple elements -- note these as cross-element connectors

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Absorb the Source Material

Read `synthesis-cross-dimensional.md`. Before writing:

1. **Central thesis?** One sentence.
2. **3-5 most important claims or patterns?**
3. **What evidence from loaded entities supports or challenges these claims?**

---

### Sub-step B: Map Content to Arc Elements

**Forces (Transformation Drivers):**
- What macro-level forces (regulatory, technological, social, economic) does the evidence reveal?
- Which 2-3 megatrends define the scope and magnitude?
- Which trends across horizons show force timing? (short = imminent, long = structural)
- How do forces interact -- reinforce (convergent) or create tensions (divergent)?

**Friction (Barriers to Change):**
- What barriers emerge? Consider: incumbents, regulations, infrastructure gaps, cultural inertia, capital requirements, timing mismatches
- For each: temporary (will dissolve) or structural (will persist)?
- What workarounds or navigation strategies does evidence suggest?
- How does friction interact with forces -- slow, distort, or redirect them?

**Evolution (Pathway Forward):**
- What new industry structure emerges once forces overcome friction?
- Who gains power? Who loses?
- How does value creation change -- new business models, competitive dynamics?
- Realistic timeline to the new equilibrium?

**Leadership (Strategic Imperatives):**
- Given the evolved structure, what positioning creates advantage?
- What differentiates leaders from survivors?
- What timing decisions are critical?
- What transition strategy connects current state to future positioning?

---

### Sub-step C: Design the Narrative Arc

1. **Title:** Generate 3 candidates. Each specific to this industry/topic (never generic). Choose the most compelling -- it should create curiosity or tension.
2. **Hook:** What is the single most surprising data point? Open with it. Pattern: [Surprising fact] -> [Why it matters] -> [What this summary reveals].
3. **Element flow:** Verify the logic:
   - Forces establishes *what is driving change*
   - Friction establishes *what resists change* (the tension)
   - Evolution resolves the tension by showing *what emerges*
   - Leadership converts understanding into *action*
   - Each transition should feel inevitable, not abrupt

---

### Sub-step D: Plan Evidence Distribution

- Target 40-50 total entity wikilinks
- Minimum 8 finding citations (aim for 10-12)
- No element fewer than 8 wikilinks or more than 15
- Each element references at least 2 different entity types
- Wikilink format: `[[entity-filename]]`

---

### Sub-step E: Write Each Element

**Forces: Transformation Drivers (350-450 words)**
- Open with the dominant macro force -- frame as structural and irreversible
- Quantify magnitude using megatrend scope and trend data
- Show force interactions (how 2-3 converge or conflict)
- Ground every major claim in a citation
- 8-12 wikilinks to megatrends, trends, and findings

**Friction: Barriers to Change (350-450 words)**
- Open with the most critical friction point -- the one most directly opposing the dominant force
- Distinguish temporary from structural friction
- Show timing mismatches between forces and industry readiness
- Describe workarounds or navigation strategies
- 8-12 wikilinks

**Evolution: Pathway Forward (350-450 words)**
- Open with the new equilibrium -- what the industry looks like after transformation
- Describe power shifts (who gains, who loses)
- Explain new business models or value creation patterns
- Provide a timeline to new equilibrium
- 8-12 wikilinks

**Leadership: Strategic Imperatives (350-450 words)**
- Open with the core positioning question
- Specify differentiation sources in the new equilibrium
- Define timing strategy (when to commit, what to sequence)
- Close with forward-looking statement about positioning for the new structure (not defending the old)
- 8-12 wikilinks

---

### Sub-step F: Self-Review

1. **Word count:** 1,450-1,900 total? Each element 350-450?
2. **Transformation narrative:** Forces -> Friction -> Evolution -> Leadership tells a connected story?
3. **Evidence grounding:** >= 8 finding citations? Every major claim grounded?
4. **Wikilinks:** 40-50 total, distributed across elements?
5. **Journalistic style?** Not academic report style?

**Common failure modes:**
- Word count under 1,450: usually thin Evolution or Leadership -- expand with evidence
- Wikilinks under 40: usually concentrated in Forces -- redistribute
- Forces and Friction blur: maintain distinction -- Forces = external pressures, Friction = internal/structural resistance

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
