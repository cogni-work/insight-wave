# Trend Panorama Story Arc

## Arc Metadata

**Arc ID:** `trend-panorama`
**Display Name:** Trend Panorama
**Display Name (German):** Trend-Panorama

**Elements (Ordered):**
1. Forces: External Pressures & Market Signals
2. Impact: Value Chain Disruption
3. Horizons: Strategic Possibilities
4. Foundations: Capability Requirements

**Elements (German):**
1. Kräfte: Externe Einflüsse & Marktsignale
2. Wirkung: Wertschöpfungsdynamik
3. Horizonte: Strategische Möglichkeiten
4. Fundamente: Kompetenzanforderungen

## TIPS Dimension Mapping

This arc is purpose-built for cogni-research trend-scout output. Each element maps to one TIPS dimension:

| Element | TIPS Letter | Dimension Slug | Dimension Name (EN) | Dimension Name (DE) |
|---------|-------------|----------------|---------------------|---------------------|
| Forces | **T** | `externe-effekte` | External Effects | Externe Effekte |
| Impact | **I** | `digitale-wertetreiber` | Digital Value Drivers | Digitale Wertetreiber |
| Horizons | **P** | `neue-horizonte` | New Horizons | Neue Horizonte |
| Foundations | **S** | `digitales-fundament` | Digital Foundation | Digitales Fundament |

### Horizon Cascade (Within Each Element)

Each element synthesizes trends across three planning horizons, creating an urgency gradient:

| Horizon | Timeframe | Signal Intensity | Narrative Role |
|---------|-----------|-----------------|----------------|
| **Act** | 0-2 years | Levels 4-5 | Lead with urgency -- what demands immediate response |
| **Plan** | 2-5 years | Levels 2-4 | Bridge to preparation -- what to build capability for |
| **Observe** | 5+ years | Levels 1-2 | Close with foresight -- what weak signals to monitor |

**Distribution per element:** ~13 trends (5 Act + 5 Plan + 3 Observe), but the narrative SYNTHESIZES clusters, not lists individual trends.

## Word Targets

| Element | English Header | German Header | Word Target |
|---------|----------------|---------------|-------------|
| Hook | *(Dynamic based on cross-dimensional insight)* | *(Dynamic)* | 150-200 |
| Forces | Forces: External Pressures & Market Signals | Kräfte: Externe Einflüsse & Marktsignale | 350-450 |
| Impact | Impact: Value Chain Disruption | Wirkung: Wertschöpfungsdynamik | 350-450 |
| Horizons | Horizons: Strategic Possibilities | Horizonte: Strategische Möglichkeiten | 350-450 |
| Foundations | Foundations: Capability Requirements | Fundamente: Kompetenzanforderungen | 250-350 |

**Total Target:** 1,450-1,900 words

## Detection Configuration

### Research Type Mapping

This arc is selected when:
- `research_type: "smarter-service"` (trend-scout output)
- `content_type: "trend"` or `"trends"` or `"tips"`
- `synthesis_format: "TIPS"` in source metadata

### Content Analysis Keywords

When `research_type` or `content_type` doesn't match, analyze input content for keyword density:
- **Keywords:** "trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "trend-scout", "dimension", "subcategory"
- **Threshold:** >=12% keyword density

### Structural Detection

Strongest auto-detection signals (check before keyword density):
- Presence of `trend-scout-output.json` in source directory or `.metadata/`
- Presence of `tips-trend-report.md` in source directory
- Source files containing YAML frontmatter with `planning_horizon` and `dimension` fields
- Files tagged with `entity-type/trend` in frontmatter tags

### Use Cases

**Best For:**
- Trend-scout output summarization (52 trend candidates)
- TIPS trend report narratives
- Multi-horizon trend landscape overviews
- Industry-specific trend panoramas
- Strategic planning input from trend research

**Typical Research Types:**
- Smarter Service trend scouting
- TIPS-formatted trend analysis
- Multi-dimensional trend landscape mapping
- Horizon-based strategic foresight from trend data

## Element Definitions

### Element 1: Forces (External Pressures & Market Signals)

**Purpose:**
Synthesize the T-dimension (Externe Effekte) trends into a narrative of external forces reshaping the landscape. Cover economy, regulation, and society subcategories across Act/Plan/Observe horizons.

**TIPS Dimension:** T -- Trends (Externe Effekte)
**Subcategories:** wirtschaft (Economy), regulierung (Regulation), gesellschaft (Society)

**Source Content:**
- **Trend entities with `dimension: "externe-effekte"`** (primary) -- filtered from `trend-scout-output.json` or `11-trends/data/`
- **Trend report T-section** -- from `tips-trend-report.md` if available
- **Dimension synthesis** -- from `12-synthesis/data/synthesis-externe-effekte.md` if available
- **Executive Summary** -- cross-dimensional context

**Source Content Mapping Example:**

```javascript
// From trend-scout-output.json, dimension: "externe-effekte"
{
  "dimension": "externe-effekte",
  "horizon": "act",
  "trend_name": "EU AI Act Compliance",
  "trend_statement": "EU AI Act August 2026 deadline for high-risk AI systems...",
  "score": 0.84,
  "confidence_tier": "high",
  "signal_intensity": 5,
  "keywords": ["regulation", "compliance", "ai-act"]
}

// Synthesized narrative:
"Regulatory pressure crystallizes around the EU AI Act's August 2026 deadline
for high-risk AI systems<sup>[1]</sup>. With signal intensity at level 5 and
high confidence, this demands immediate organizational response..."
```

**Transformation Approach:**
1. **Group by subcategory:** Cluster externe-effekte trends into economy, regulation, society
2. **Cascade by horizon:** Within each cluster, lead with Act trends (immediate pressure), bridge to Plan trends (emerging forces), close with Observe trends (weak signals)
3. **Identify force interactions:** Show how economic, regulatory, and societal forces reinforce or counteract each other
4. **Quantify magnitude:** Use trend scores and confidence tiers to signal force strength

**Key Techniques:**
- PSB for reframing the dominant force as an unconsidered need
- Forcing Functions for Act-horizon trends with regulatory or market deadlines
- Contrast Structure for tensions between subcategory forces
- Number Plays for trend scores, signal intensities, and quantitative evidence

**Pattern Reference:** `forces-patterns.md`

---

### Element 2: Impact (Value Chain Disruption)

**Purpose:**
Synthesize the I-dimension (Digitale Wertetreiber) trends into a narrative of how external forces reshape value creation. Cover customer experience, products/services, and business processes across horizons.

**TIPS Dimension:** I -- Implications (Digitale Wertetreiber)
**Subcategories:** customer-experience, produkte-services, geschaeftsprozesse (Business Processes)

**Source Content:**
- **Trend entities with `dimension: "digitale-wertetreiber"`** (primary)
- **Trend report I-section** -- from `tips-trend-report.md` if available
- **Dimension synthesis** -- from `12-synthesis/data/synthesis-digitale-wertetreiber.md`
- **Executive Summary** -- value chain transformation patterns

**Transformation Approach:**
1. **Map force-to-impact chain:** Connect Forces element insights to value chain disruption
2. **Cascade by horizon:** Act impacts (disruption happening now), Plan impacts (emerging value shifts), Observe impacts (potential future disruptions)
3. **Show cascading effects:** How customer experience changes drive product/service evolution, which forces process transformation
4. **Quantify disruption:** Revenue impact, cost structure changes, market share shifts from trend evidence

**Key Techniques:**
- Contrast Structure for before/after value chain comparisons
- Compound Impact for stacking disruption across customer, product, process
- Number Plays for quantified value chain metrics
- Forcing Functions for Act-horizon disruptions demanding immediate response

**Pattern Reference:** `impact-patterns.md`

---

### Element 3: Horizons (Strategic Possibilities)

**Purpose:**
Synthesize the P-dimension (Neue Horizonte) trends into a narrative of strategic opportunities. Cover strategy, leadership, and governance approaches across horizons.

**TIPS Dimension:** P -- Possibilities (Neue Horizonte)
**Subcategories:** strategie (Strategy), fuehrung (Leadership), steuerung (Governance)

**Source Content:**
- **Trend entities with `dimension: "neue-horizonte"`** (primary)
- **Trend report P-section** -- from `tips-trend-report.md` if available
- **Dimension synthesis** -- from `12-synthesis/data/synthesis-neue-horizonte.md`
- **Executive Summary** -- strategic opportunity statements

**Transformation Approach:**
1. **Connect impact-to-opportunity:** Show how value chain disruptions (Element 2) create strategic openings
2. **Cascade by horizon:** Act opportunities (seize now), Plan opportunities (build toward), Observe opportunities (position for)
3. **Differentiate by subcategory:** Strategy opportunities vs. leadership model shifts vs. governance innovations
4. **Quantify opportunity windows:** Use horizon timelines and confidence scores to size windows

**Key Techniques:**
- You-Phrasing for direct reader engagement with opportunities
- IS-DOES-MEANS for articulating strategic positions
- Number Plays for opportunity sizing and timing
- Contrast Structure for conventional vs. emerging strategic approaches

**Pattern Reference:** `horizons-patterns.md`

---

### Element 4: Foundations (Capability Requirements)

**Purpose:**
Synthesize the S-dimension (Digitales Fundament) trends into a narrative of required capabilities. Cover culture, workforce, and technology infrastructure across horizons.

**TIPS Dimension:** S -- Solutions (Digitales Fundament)
**Subcategories:** kultur (Culture), mitarbeitende (Workforce), technologie (Technology)

**Source Content:**
- **Trend entities with `dimension: "digitales-fundament"`** (primary)
- **Trend report S-section** -- from `tips-trend-report.md` if available
- **Dimension synthesis** -- from `12-synthesis/data/synthesis-digitales-fundament.md`
- **Executive Summary** -- capability building recommendations

**Transformation Approach:**
1. **Connect opportunities-to-requirements:** Show which capabilities enable the possibilities from Element 3
2. **Cascade by horizon:** Act requirements (build now), Plan requirements (start developing), Observe requirements (begin experimenting)
3. **Sequence dependencies:** Culture enables workforce, workforce enables technology -- show build order
4. **Quantify readiness gaps:** Use trend evidence to assess current vs. required capability levels

**Key Techniques:**
- IS-DOES-MEANS for defining each capability requirement
- Compound Impact for cost of capability gaps (stacked across culture, workforce, tech)
- Forcing Functions for capability deadlines driven by Act-horizon requirements
- You-Phrasing for actionable capability building recommendations

**Pattern Reference:** `foundations-patterns.md`

## Narrative Flow

### Hook Construction

**Approach:**
Open with a cross-dimensional insight that reveals the SCALE and URGENCY of the trend landscape. The hook should synthesize across all 4 TIPS dimensions to show the panoramic view.

**Pattern:**
```markdown
[Industry/sector] faces [number] converging trends across [N] dimensions—from [T-dimension insight] through [I-dimension insight] to [P-dimension insight], demanding [S-dimension implication]<sup>[1]</sup>. [Quantified urgency from Act-horizon trends]. [Surprising cross-dimensional finding].
```

**Example:**
```markdown
Aviation faces 52 converging digital transformation trends that reshape everything from regulatory compliance to passenger experience<sup>[1]</sup>. Thirteen trends demand immediate action within 24 months—biometric processing alone reaches 70% airline adoption while drone delivery moves from pilot to production at 40% of major cargo hubs<sup>[2]</sup>. Yet the most disruptive patterns emerge not from individual trends but from their interaction: regulatory pressure on AI systems accelerates the very automation it seeks to govern<sup>[3]</sup>.
```

---

### Element Transitions

**Hook -> Forces:**
- Hook reveals the panoramic landscape
- Forces drills into the first dimension: external pressures
- **Transition pattern:** "The trend landscape begins with external forces reshaping [industry/sector]."

**Forces -> Impact:**
- Forces establishes macro pressures
- Impact shows how those forces disrupt value creation
- **Transition pattern:** "These external forces translate into measurable disruption across the value chain."

**Impact -> Horizons:**
- Impact describes current and emerging disruption
- Horizons reframes disruption as strategic opportunity
- **Transition pattern:** "Disruption creates openings. The strategic question shifts from 'how to defend' to 'where to position.'"

**Horizons -> Foundations:**
- Horizons describes strategic possibilities
- Foundations specifies what's needed to capture them
- **Transition pattern:** "Capturing these opportunities requires specific capabilities across culture, workforce, and technology."

---

### Closing Pattern

**Final Sentence:**
Urgency-to-action close that references the Act/Plan/Observe framework.

**Examples:**
- "Thirteen trends demand action now. Thirteen more require active preparation. The remaining signals will define the competitive landscape beyond 2028. Organizations reading this panorama have the map -- the question is speed of navigation."
- "The trend panorama reveals not just what's changing, but how fast. Act-horizon trends set the pace. Plan-horizon trends set the direction. Observe-horizon trends set the destination."
- "[Number] converging trends across [N] dimensions compress the decision window. Those who act on today's signals build tomorrow's advantages."

## Citation Requirements

### Citation Density

**Target:** 15-25 total citations across 1,450-1,900 words
**Ratio:** Approximately 1 citation per 60-100 words

### Citation Distribution

**Forces (T -- evidence-heavy, external data):** 5-8 citations
**Impact (I -- value chain evidence):** 4-7 citations
**Horizons (P -- opportunity sizing):** 4-6 citations
**Foundations (S -- capability evidence):** 3-5 citations

### Citation Format

```markdown
Claim text<sup>[N](source-file.md)</sup>
```

**When citing trend entities:**
```markdown
Claim text<sup>[N](11-trends/data/trend-{id}.md)</sup>
```

**When citing trend-report sections:**
```markdown
Claim text<sup>[N](tips-trend-report.md)</sup>
```

**Required Citations:**
- Every Act-horizon trend claim (MUST)
- Trend scores and confidence tiers (MUST)
- Quantitative evidence from trend statements (MUST)
- Cross-dimensional pattern claims (Should have)
- Observe-horizon weak signals (Should have)

## Quality Gates

### Arc Completeness

- [ ] All 4 elements present (Forces, Impact, Horizons, Foundations)
- [ ] Hook present (150-200 words)
- [ ] Word counts in target ranges (+/-50 words tolerance)
- [ ] Smooth transitions between elements
- [ ] Each element maps to exactly one TIPS dimension

### TIPS Framework Adherence

- [ ] **Forces** covers Externe Effekte dimension (economy, regulation, society)
- [ ] **Impact** covers Digitale Wertetreiber dimension (CX, products, processes)
- [ ] **Horizons** covers Neue Horizonte dimension (strategy, leadership, governance)
- [ ] **Foundations** covers Digitales Fundament dimension (culture, workforce, technology)
- [ ] Each element references trends from its mapped dimension

### Horizon Cascade Applied

- [ ] **Each element** contains Act -> Plan -> Observe progression
- [ ] Act-horizon trends lead with urgency (immediate actions)
- [ ] Plan-horizon trends bridge to preparation (capability building)
- [ ] Observe-horizon trends close with foresight (weak signals to monitor)
- [ ] Horizon distribution roughly matches 5:5:3 ratio (Act:Plan:Observe)

### Trend Synthesis Quality

- [ ] Trends are SYNTHESIZED into patterns (not listed individually)
- [ ] Cross-trend interactions identified within each dimension
- [ ] Subcategory coverage balanced (not dominated by one subcategory)
- [ ] Trend confidence and score data used to weight narrative emphasis
- [ ] High-confidence Act trends receive deepest treatment

### Evidence Quality

- [ ] Every quantitative claim has citation to trend entity or source
- [ ] Trend scores and horizons accurately represented
- [ ] No fabricated trends or evidence beyond loaded source
- [ ] Citation density: 15-25 total citations
- [ ] Signal intensity and confidence correctly characterized

### Narrative Coherence

- [ ] Hook showcases the panoramic cross-dimensional landscape
- [ ] Forces establishes external pressures that drive the remaining elements
- [ ] Impact shows how forces translate to value chain disruption
- [ ] Horizons reframes disruption as strategic opportunity
- [ ] Foundations specifies capabilities needed to capture opportunities
- [ ] Closing creates action urgency referencing Act/Plan/Observe framework

### Executive Appeal

- [ ] Opening hook demonstrates strategic urgency (not trend listing)
- [ ] Each element delivers actionable insight (not observation)
- [ ] Horizon cascade creates natural urgency gradient
- [ ] Specific timelines and deadlines from Act-horizon trends
- [ ] Quantified opportunity and risk from trend evidence
- [ ] Foundations element provides clear capability roadmap

## Common Pitfalls

### Forces Pitfalls

X **Trend listing:** "Trend 1: EU AI Act. Trend 2: Biometric processing. Trend 3: ..."
V **Synthesized forces:** "Regulatory pressure crystallizes around three converging mandates: AI compliance deadlines, data sovereignty requirements, and environmental reporting standards--each reinforcing the others<sup>[1]</sup>."

X **Missing horizon cascade:** Jumping between Act and Observe without logical progression
V **Clear cascade:** Start with Act urgency, bridge through Plan preparation, close with Observe signals

### Impact Pitfalls

X **Disconnected from Forces:** "Customer experience is changing because of technology"
V **Force-linked impact:** "The regulatory pressure identified in Forces translates directly to customer-facing compliance: biometric systems must now serve dual purposes--seamless experience AND privacy documentation<sup>[1]</sup>."

X **Abstract disruption:** "Value chains are being disrupted"
V **Specific disruption:** "Passenger processing time drops from 45 to 12 seconds with biometric gates, but each transaction generates 3x the compliance data<sup>[1]</sup>."

### Horizons Pitfalls

X **Generic opportunities:** "Organizations should leverage digital transformation"
V **Specific possibilities:** "The 18-month window before autonomous baggage handling reaches mainstream creates first-mover advantage worth 40% operational cost reduction for early adopters<sup>[1]</sup>."

X **Missing opportunity windows:** "There are opportunities in AI"
V **Timed opportunities:** "Act-horizon opportunities (0-2 years) in biometric processing yield 3.2x ROI. Plan-horizon opportunities (2-5 years) in autonomous operations require 18-month preparation<sup>[1]</sup>."

### Foundations Pitfalls

X **Vague capability recommendations:** "Build digital capabilities"
V **Specific requirements:** "Workforce reskilling for AI oversight requires 2,400 training hours across 3 competency levels--Act-horizon foundation that enables Plan-horizon autonomous operations<sup>[1]</sup>."

X **Missing sequencing:** "Invest in culture, workforce, and technology"
V **Dependency-aware sequencing:** "Culture transformation (psychological safety for AI adoption) enables workforce upskilling, which enables technology deployment. Reverse order fails--technology without trained operators produces 60% lower utilization<sup>[1]</sup>."

## Language Variations

### German Adjustments

**TIPS terminology:**
- Keep "TIPS" as English framework name (per localization rules)
- Translate dimension names: "Externe Effekte", "Digitale Wertetreiber", "Neue Horizonte", "Digitales Fundament"
- Keep horizon labels in English: "Act", "Plan", "Observe" (framework terms)

**Horizon cascade language:**
- "Act-Horizont: Sofortiger Handlungsbedarf (0-2 Jahre)"
- "Plan-Horizont: Mittelfristige Vorbereitung (2-5 Jahre)"
- "Observe-Horizont: Schwache Signale im Blick (5+ Jahre)"

**German precision requirements:**
- Use proper umlauts throughout: Kräfte, Möglichkeiten, Fähigkeiten
- Precise metric formatting: "3,2x" (German decimal comma), "2.400 Stunden" (German thousand separator)
- Quarter/year format: "Q2 2026", "2026-2027" (same as English)

**Example (German style):**
```markdown
## Kräfte: Externe Einflüsse & Marktsignale

Der regulatorische Druck kristallisiert sich um drei konvergierende Mandate: Die EU AI Act-Frist im August 2026 für Hochrisiko-KI-Systeme<sup>[1]</sup>, verschärfte Datensouveränitätsanforderungen unter NIS2<sup>[2]</sup>, und neue ESG-Berichtspflichten ab 2025<sup>[3]</sup>. Mit Signal-Intensitäten auf Level 4-5 und hoher Konfidenz erfordern diese Act-Horizont-Trends sofortige organisatorische Reaktion.

Die wirtschaftlichen Kräfte verstärken den regulatorischen Druck: Investitionszyklen verkürzen sich von 36 auf 18 Monate<sup>[4]</sup>, während gleichzeitig ROI-Anforderungen steigen...
```

## Version History

- **v1.0.0:** Initial Trend Panorama arc definition (TIPS-native story arc for trend-scout output)

## See Also

- `../arc-registry.md` - Master index of all story arcs
- `forces-patterns.md` - External pressure synthesis patterns (T-dimension)
- `impact-patterns.md` - Value chain disruption patterns (I-dimension)
- `horizons-patterns.md` - Strategic possibility patterns (P-dimension)
- `foundations-patterns.md` - Capability requirement patterns (S-dimension)
