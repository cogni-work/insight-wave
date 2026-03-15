# Foundations: Capability Requirements Patterns

## Element Purpose

Synthesize S-dimension (Digitales Fundament) trends into a narrative of required capabilities. Specify what organizations must build across culture, workforce, and technology to capture the opportunities identified in Element 3--with dependency-aware sequencing across Act/Plan/Observe horizons.

**TIPS Dimension:** S -- Solutions (Digitales Fundament)
**Word Target:** 18% of target length

## Source Content Mapping

Extract from:
1. **Trend entities with `dimension: "digitales-fundament"`** (primary source)
   - Group by subcategory: kultur, mitarbeitende, technologie
   - Cascade by horizon: act, plan, observe

2. **Trend Report S-Section** (if available)
   - From `tips-trend-report.md`, section "S -- Solutions: Digitales Fundament"

3. **Dimension Synthesis**
   - From `12-synthesis/data/synthesis-digitales-fundament.md`

4. **Horizons Element** (internal reference)
   - Connect capability requirements to opportunities identified in Element 3

## Horizon Cascade Structure

### Act Horizon (Lead -- 100-130 words)

**What to extract:**
- 5 trends with `horizon: "act"` showing immediate capability needs
- Culture shifts needed now (psychological safety, change readiness)
- Workforce skills demanding immediate investment
- Technology infrastructure requiring immediate deployment

**Questions to answer:**
- What capabilities must be in place within 0-2 years?
- What's the cost of NOT building these capabilities now?
- What dependency chains start with Act-horizon foundations?

**Example:**
```markdown
Capturing Act-horizon opportunities requires three immediate foundation investments. Workforce digital literacy (score: 0.81, Act) represents the critical bottleneck: 68% of operational staff require upskilling in data-driven decision-making within 18 months<sup>[1]</sup>. Cybersecurity infrastructure modernization (0.79) must precede any expansion of digital touchpoints--the biometric processing opportunity (Horizons) collapses without end-to-end security certification<sup>[2]</sup>.

Cultural foundation: psychological safety for AI-augmented work environments. Organizations where employees trust AI recommendations show 2.3x higher adoption rates and 40% faster capability building<sup>[3]</sup>.
```

---

### Plan Horizon (Bridge -- 80-120 words)

**What to extract:**
- 5 trends with `horizon: "plan"` showing emerging capability requirements
- How Act-horizon foundations enable Plan-horizon capabilities
- Advanced skills, deeper cultural transformation, platform infrastructure

**Example:**
```markdown
Plan-horizon capabilities build on Act-horizon foundations. Advanced analytics competency (signal intensity 3) requires the data literacy base established in Act<sup>[4]</sup>. Platform architecture skills emerge as the critical differentiator: organizations must develop or acquire ecosystem orchestration capabilities within 3 years to capture Plan-horizon strategic opportunities<sup>[5]</sup>.

Cultural deepening: from AI acceptance (Act) to AI co-creation (Plan), where workforce actively designs AI-augmented workflows rather than passively adopting them<sup>[6]</sup>.
```

---

### Observe Horizon (Close -- 60-90 words)

**What to extract:**
- 3 trends with `horizon: "observe"` as future capability signals
- Capabilities that don't yet have clear requirements
- Experimental investments worth monitoring

**Example:**
```markdown
Observe-horizon capability signals remain speculative but directionally important: quantum computing literacy (signal intensity 1) and autonomous systems governance expertise (intensity 2) represent emerging competency areas<sup>[7]</sup>. Current investment: awareness-level only. The trigger for escalation: when corresponding Observe-horizon forces (Element 1) strengthen to Plan-horizon status<sup>[8]</sup>.
```

## Transformation Patterns

### Pattern 1: Opportunity-to-Requirement Chain

**When to use:** Connecting Horizons opportunities to specific capability needs

**Structure:**
```markdown
[Opportunity from Element 3] requires [specific capability]:
[Capability description with quantified gap]<sup>[citation]</sup>.
[Build timeline and investment estimate]<sup>[citation]</sup>.
```

**Example:**
```markdown
AI-augmented operations leadership (Horizons element) requires workforce upskilling in data-driven decision-making: current capability covers 32% of operational roles, target is 80% within 18 months<sup>[1]</sup>. Investment: 2,400 training hours across 3 competency levels, estimated €1.2M for a 500-person operational unit<sup>[2]</sup>.
```

---

### Pattern 2: Dependency-Aware Sequencing

**When to use:** Showing build order across culture, workforce, and technology

**Structure:**
```markdown
**Sequence matters.** [Subcategory A] enables [Subcategory B], which enables [Subcategory C]:
1. **[First]:** [Foundation capability with timeline]<sup>[citation]</sup>
2. **[Second]:** [Dependent capability with timeline]<sup>[citation]</sup>
3. **[Third]:** [Top-layer capability with timeline]<sup>[citation]</sup>

**Reverse order fails:** [Evidence of failure when sequence is violated]<sup>[citation]</sup>.
```

**Example:**
```markdown
**Sequence matters.** Culture enables workforce, workforce enables technology:
1. **Culture (months 0-6):** Psychological safety for AI-augmented work<sup>[1]</sup>
2. **Workforce (months 3-12):** Data literacy and AI collaboration skills<sup>[2]</sup>
3. **Technology (months 6-18):** Platform infrastructure and integration<sup>[3]</sup>

**Reverse order fails:** Technology without trained operators produces 60% lower utilization; training without cultural readiness yields 45% dropout rates<sup>[4]</sup>.
```

---

### Pattern 3: Capability Gap Quantification

**When to use:** Measuring the distance between current state and required state

**Structure:**
```markdown
**Capability:** [Name]
**Current state:** [Measured level]<sup>[citation]</sup>
**Required state:** [Target level for opportunity capture]<sup>[citation]</sup>
**Gap:** [Quantified distance]
**Close timeline:** [Duration and investment]
```

---

### Pattern 4: Readiness Cost-Benefit

**When to use:** Justifying capability investment with opportunity value

**Structure:**
```markdown
[Capability investment: cost and timeline]<sup>[citation]</sup>.
[Opportunity enabled: value and advantage duration]<sup>[citation]</sup>.
**Ratio:** [Investment:Return ratio over planning horizon].
**Inaction cost:** [What happens without the capability]<sup>[citation]</sup>.
```

**Example:**
```markdown
Workforce digital literacy: €1.2M investment, 18-month program<sup>[1]</sup>.
Enables: AI-augmented operations (2.4x efficiency, 24-month first-mover advantage)<sup>[2]</sup>.
**Ratio:** 1:8.5 over 3-year horizon.
**Inaction cost:** Competitor achieves operations advantage; catch-up costs 3x initial investment plus 18-month delay penalty<sup>[3]</sup>.
```

---

### Pattern 5: Horizon-Aligned Capability Roadmap

**When to use:** Presenting a structured build plan across horizons

**Structure:**
```markdown
**Act (0-2 years):** [Capabilities to build immediately]<sup>[citation]</sup>
**Plan (2-5 years):** [Capabilities requiring foundational investment first]<sup>[citation]</sup>
**Observe (5+ years):** [Capabilities to monitor and experiment with]<sup>[citation]</sup>
```

## Techniques Checklist

### Opportunity-to-Requirement Connection

- [ ] **Every capability links to Horizons element opportunity**
  - V "AI operations leadership requires workforce data literacy"
  - V "Platform strategy requires ecosystem orchestration skills"
  - X Capability requirements appear without strategic justification

---

### Dependency Sequencing

- [ ] **Build order explicitly stated**
  - V "Culture -> Workforce -> Technology sequence"
  - V "Phase 1 enables Phase 2 enables Phase 3"
  - X "Invest in culture, workforce, and technology" (no order)

---

### IS-DOES-MEANS for Key Capabilities

- [ ] **At least 1 capability articulated as Power Position**
  - V IS: "Cross-functional data literacy program"
  - V DOES: "Enables 80% of operational staff to make data-driven decisions"
  - V MEANS: "18-month investment creates workforce moat competitors need 2+ years to replicate"

---

### Compound Impact for Inaction Cost

- [ ] **Cost of NOT building capabilities quantified**
  - V "60% lower technology utilization without trained workforce"
  - V "3x catch-up cost plus 18-month delay penalty"
  - X "Organizations should invest in capabilities"

## Quality Checkpoints

### Content Requirements

- [ ] Opportunity-to-requirement chains explicit
- [ ] 3 subcategories covered: culture, workforce, technology
- [ ] Dependency sequencing stated (what enables what)
- [ ] Gap quantification for at least 1 major capability
- [ ] 3-5 citations to trend entities and sources

### Structure Requirements

- [ ] Word count: within proportional range for this element (+/-10% tolerance)
- [ ] Smooth transition from Horizons
- [ ] Strong closing with Act/Plan/Observe framework reference
- [ ] Horizon cascade maintained (shorter due to word constraint)
- [ ] Actionable recommendations (not abstract)

## Common Mistakes

### X Mistake 1: Vague Capability Recommendations

**Bad:**
> "Organizations should build digital capabilities and invest in workforce development."

**Good:**
> "Workforce digital literacy: 68% of operational staff require upskilling within 18 months. Investment: 2,400 training hours, €1.2M per 500-person unit. Without this: AI technology utilization drops 60%<sup>[1]</sup>."

### X Mistake 2: Missing Dependency Sequencing

**Bad:**
> "Required capabilities include cultural transformation, workforce upskilling, and technology modernization."

**Good:**
> "Culture enables workforce, workforce enables technology. Reversing the order fails: technology without trained operators yields 60% lower utilization<sup>[1]</sup>."

### X Mistake 3: Capabilities Without Strategic Justification

**Bad:**
> "Organizations need cybersecurity infrastructure modernization."

**Good:**
> "Biometric processing opportunity (Horizons: 18-month first-mover window) collapses without cybersecurity certification. Infrastructure modernization (score: 0.79, Act) is not optional improvement--it's the gate to a €240M revenue opportunity<sup>[1]</sup>."

## Language Variations

### German Adjustments

**Capability terminology:**
- "Kompetenzanforderungen", "Fähigkeitslücke", "Aufbaureihenfolge"
- Subcategories: "Kultur", "Mitarbeitende", "Technologie"

**Dependency language:**
- "Kultur ermöglicht Mitarbeitende, Mitarbeitende ermöglichen Technologie"
- "Umgekehrte Reihenfolge scheitert"

**Example (German style):**
```markdown
## Fundamente: Kompetenzanforderungen

Die Act-Horizont-Chancen erfordern drei sofortige Grundlageninvestitionen. Digitale Kompetenz der Belegschaft (Score: 0,81, Act) stellt den kritischen Engpass dar: 68% des operativen Personals benötigen Weiterbildung in datengetriebener Entscheidungsfindung innerhalb von 18 Monaten<sup>[1]</sup>.

**Reihenfolge entscheidet.** Kultur ermöglicht Mitarbeitende, Mitarbeitende ermöglichen Technologie. Umgekehrt scheitert es: Technologie ohne geschulte Bediener erzielt 60% geringere Auslastung<sup>[2]</sup>.
```

## Related Patterns

- See `forces-patterns.md` for external pressures driving capability urgency
- See `impact-patterns.md` for disruptions requiring capability response
- See `horizons-patterns.md` for opportunities that capabilities must enable
