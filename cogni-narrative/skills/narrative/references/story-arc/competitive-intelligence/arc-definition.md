# Competitive Intelligence Story Arc

## Arc Metadata

**Arc ID:** `competitive-intelligence`
**Display Name:** Competitive Intelligence
**Display Name (German):** Wettbewerbsanalyse

**Elements (Ordered):**
1. Landscape: Current Competitive Positioning
2. Shifts: Momentum Changes and Strategic Moves
3. Positioning: Strategic Gaps and Opportunities
4. Implications: Time-Bound Actions

**Elements (German):**
1. Landschaft: Aktuelle Wettbewerbspositionierung
2. Verschiebungen: Momentum-Änderungen und strategische Züge
3. Positionierung: Strategische Lücken und Chancen
4. Implikationen: Zeitgebundene Handlungen

## Word Targets

| Element | English Header | German Header | Word Target |
|---------|----------------|---------------|-------------|
| Hook | *(Dynamic based on finding)* | *(Dynamic)* | 150-200 |
| Landscape | Landscape: Current State | Landschaft: Aktueller Stand | 350-450 |
| Shifts | Shifts: Momentum Changes | Verschiebungen: Momentum-Änderungen | 300-400 |
| Positioning | Positioning: Strategic Gaps | Positionierung: Strategische Lücken | 400-500 |
| Implications | Implications: Required Actions | Implikationen: Erforderliche Handlungen | 250-350 |

**Total Target:** 1,450-1,900 words

## Detection Configuration

### Research Type Mapping

This arc is selected when:
- `research_type: "competitive"`

### Content Analysis Keywords

When `research_type` doesn't match, analyze Executive Summary for keyword density:
- **Keywords:** "competitor", "market share", "positioning", "differentiation", "threat", "rivalry", "strategic move", "competitive advantage"
- **Threshold:** ≥12% keyword density

### Use Cases

**Best For:**
- Competitive analysis projects
- Market positioning studies
- Threat assessment
- Strategic differentiation planning
- Competitive response strategy
- Market share analysis

## Element Definitions

### Element 1: Landscape (Current State)

**Purpose:**
Map current competitive positions, market structure, and established power dynamics.

**Source Content:**
- Executive Summary (competitive overview)
- Dimension syntheses (market structure analysis)
- Trends (current state indicators)

**Transformation Approach:**
- Market structure (fragmented, concentrated, oligopoly)
- Current leader positions and share
- Competitive bases (cost, differentiation, focus)
- Established moats and barriers

**Pattern Reference:** `landscape-patterns.md`

---

### Element 2: Shifts (Momentum Changes)

**Purpose:**
Identify momentum changes, strategic moves, and competitive repositioning underway.

**Source Content:**
- Trends (especially "Act" column with competitive moves)
- Executive Summary (strategic shift indicators)
- Dimension syntheses (competitive dynamics)

**Transformation Approach:**
- Momentum indicators (market share trends, investment patterns)
- Strategic moves (M&A, partnerships, pivots)
- Capability building races
- Emerging threats vs. declining threats

**Pattern Reference:** `shifts-patterns.md`

---

### Element 3: Positioning (Strategic Gaps)

**Purpose:**
Identify strategic gaps, white spaces, and positioning opportunities emerging from landscape + shifts.

**Source Content:**
- Strategic Recommendations (primary)
- Cross-Dimensional Patterns (opportunity intersections)
- Executive Summary (positioning insights)

**Transformation Approach:**
- Uncontested spaces (where competitors aren't playing)
- Capability gaps (what competitors lack)
- Timing advantages (windows before competitors move)
- Differentiation axes (how to compete differently)

**Pattern Reference:** `positioning-patterns.md`

---

### Element 4: Implications (Time-Bound Actions)

**Purpose:**
Specify time-bound actions to exploit gaps before they close or competitors fill them.

**Source Content:**
- Strategic Recommendations (action items)
- Trends (urgency indicators)
- Dimension syntheses (implementation timelines)

**Transformation Approach:**
- Immediate actions (0-6 months)
- Near-term moves (6-18 months)
- Capability building (18-36 months)
- Competitive response scenarios

**Pattern Reference:** `implications-patterns.md`

## Narrative Flow

### Hook Construction

**Approach:**
Open with a surprising competitive shift or market structure change that challenges conventional wisdom about the competitive landscape.

**Pattern:**
```markdown
[Established player] losing [market share %] to [unexpected competitor] signals [structural shift]<sup>[1]</sup>. [Conventional wisdom] no longer predicts [competitive outcome].
```

---

### Element Transitions

**Hook → Landscape:**
- Hook introduces surprising competitive shift
- Landscape explains current state that makes shift surprising
- **Transition pattern:** "This shift emerges from a competitive landscape defined by [structure]."

**Landscape → Shifts:**
- Landscape establishes current positions
- Shifts shows how positions are changing
- **Transition pattern:** "Three momentum shifts are reshaping this landscape."

**Shifts → Positioning:**
- Shifts identifies what's changing
- Positioning identifies gaps created by changes
- **Transition pattern:** "These shifts create strategic gaps in [areas]."

**Positioning → Implications:**
- Positioning identifies where to compete
- Implications specifies when and how to move
- **Transition pattern:** "Capturing these gaps requires time-bound action."

---

### Closing Pattern

**Final Sentence:**
Clear timeline for competitive window closing.

**Examples:**
- "Strategic gaps close by [quarter]. Organizations moving by [date] capture positions. Delay means competing for crowded spaces."
- "The competitive window is [timeframe]. Required moves take [duration]. Action deadline: [date]."

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Landscape, Shifts, Positioning, Implications)
- [ ] Hook present (150-200 words)
- [ ] Word counts in target ranges
- [ ] Smooth transitions between elements
- [ ] Each element serves distinct purpose

### Competitive Intelligence Techniques Applied

- [ ] **Landscape:** Market structure identified (fragmented/concentrated)
- [ ] **Landscape:** Current positions quantified (market share, capabilities)
- [ ] **Landscape:** Competitive bases mapped (cost/differentiation/focus)
- [ ] **Shifts:** Momentum indicators quantified (share trends, investment rates)
- [ ] **Shifts:** Strategic moves cataloged with timelines
- [ ] **Shifts:** Threat assessment (emerging vs. declining)
- [ ] **Positioning:** Uncontested spaces identified
- [ ] **Positioning:** Capability gaps specified
- [ ] **Positioning:** Timing advantages quantified
- [ ] **Implications:** Time-bound actions (0-6mo, 6-18mo, 18-36mo)
- [ ] **Implications:** Competitive response scenarios considered

## Example Transformation

This section demonstrates the Landscape → Shifts transformation using the Cloud Infrastructure Provider test case.

### Source: Executive Summary (Landscape Signal)

> Current market share shows AWS maintaining 32% leadership, Azure growing to 24% (+3pp YoY), Google Cloud at 11% (+2pp YoY), while other providers collectively hold 33%<sup>[1](12-synthesis/synthesis-market.md)</sup>. However, segment-level analysis reveals divergent trajectories: AWS dominates compute and storage (38% share), Azure leads in enterprise SaaS integration (41%), Google Cloud captures AI/ML workloads (47%)<sup>[2](12-synthesis/synthesis-segments.md)</sup>.

### Landscape Transformation (350-450 words)

The hyperscale cloud market appears consolidated at first glance—three providers control 67% of overall demand<sup>[1](12-synthesis/synthesis-market.md)</sup>. But this top-line view masks fundamental competitive fragmentation at the segment level.

AWS holds 32% overall market share yet dominates compute and storage workloads at 38%<sup>[1](12-synthesis/synthesis-market.md)</sup><sup>[2](12-synthesis/synthesis-segments.md)</sup>. This reflects AWS's first-mover positioning in infrastructure-as-a-service, where commodity pricing and operational scale create winner-take-most dynamics. Azure's 24% overall share disguises its 41% dominance in enterprise SaaS integration workloads<sup>[2](12-synthesis/synthesis-segments.md)</sup>—a strategic moat built on Microsoft 365 ecosystem lock-in rather than infrastructure economics. Google Cloud's modest 11% overall share obscures its 47% capture of AI/ML workloads<sup>[2](12-synthesis/synthesis-segments.md)</sup>, where TPU architecture and TensorFlow integration create technical differentiation.

This segmentation reveals three distinct competitive clusters: infrastructure generalists (AWS, commodity position), enterprise integrators (Azure, ecosystem lock-in), and workload specialists (Google Cloud, technical differentiation). Each cluster operates under different competitive logic.

*Technique: Move from aggregate statistics to segment-level detail. Show divergence ("masks fundamental fragmentation"). Connect positioning to business model (AWS scale, Azure ecosystem, Google tech).*

### Shifts Transformation (300-400 words)

While AWS maintains static overall share (32%), its segment-level momentum diverges. Compute/storage growth at 14% annually lags specialized workloads growing 35-47%—a velocity gap that compounds into strategic vulnerability.

Azure's +3pp annual gain comes entirely from enterprise SaaS integration, where Microsoft 365 co-selling creates a flywheel effect<sup>[2](12-synthesis/synthesis-segments.md)</sup>. This isn't market share gain through competitive displacement; it's category creation through ecosystem leverage.

Google Cloud's +2pp growth masks 47% capture of the fastest-growing segment (AI/ML workloads)<sup>[2](12-synthesis/synthesis-segments.md)</sup>. The shift isn't visible in top-line share but becomes decisive as AI infrastructure spending accelerates from $89B (2026) to projected $210B by 2028.

The momentum indicators point to positioning shift: infrastructure breadth → specialized capabilities. Winners in high-growth segments achieve 3x premium pricing by solving specific compliance, performance, or integration challenges<sup>[3](synthesis-positioning.md)</sup>.

*Technique: Contrast static top-line (32% AWS) with dynamic segment trajectories (14% vs. 35-47%). Use "velocity gap" and "compounds into vulnerability" language. Reference future projections ($89B → $210B) to show momentum.*

### Key Transformation Patterns

**Landscape techniques:**
- Segment-level decomposition (overall 32% → compute 38%, SaaS 41%, AI/ML 47%)
- Competitive clustering (generalists, integrators, specialists)
- Business model identification (scale, ecosystem, technical differentiation)

**Shifts techniques:**
- Velocity analysis (14% vs. 35-47% growth rates)
- Momentum attribution (where is growth coming from?)
- Future trajectory projection ($89B → $210B)
- Competitive logic shift (breadth → specialized capabilities)

## See Also

- `../arc-registry.md` - Master index of all story arcs
- `landscape-patterns.md` - Current state mapping patterns
- `shifts-patterns.md` - Momentum change identification patterns
- `positioning-patterns.md` - Strategic gap analysis patterns
- `implications-patterns.md` - Time-bound action specification patterns
