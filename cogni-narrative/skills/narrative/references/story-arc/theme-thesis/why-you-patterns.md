# Why You: Portfolio Power Position Patterns (Theme Thesis)

## Element Purpose

Convert the theme's solution templates and strategic possibilities into **Power Positions** — capabilities backed by the value-modeler portfolio that create competitive advantage and are difficult to replicate.

**Word Target:** 30% of theme section target (largest element — this is the portfolio showcase)

## Source Content Mapping

Extract from theme data:

1. **Solution Templates** (primary) — `SOLUTION_TEMPLATES[]` from orchestrator
   - Each ST has `name`, `category`, `enabler_type`
   - These become the **IS layer** of Power Positions
   - If empty: construct Power Positions from P-candidates directly

2. **P-candidates** (Neue Horizonte) — `chain.possibilities[]` for each value chain
   - Strategic opportunities with quantified outcomes
   - `opportunities_md` from enriched-trends: the DOES layer evidence
   - How these capabilities change the organization's performance

3. **S-candidates** (Digitales Fundament) — `chain.foundation_requirements[]`
   - Capability prerequisites that take time to build
   - `evidence_md` from enriched-trends: the MEANS layer evidence
   - Why these capabilities create barriers to replication

4. **Claims** — filtered by P-candidate and S-candidate claims_refs
   - Quantitative outcomes for DOES layer
   - Capability gap costs for MEANS layer

## IS-DOES-MEANS Structure

### Creating Power Positions from Solution Templates

For each solution template (1-3 Power Positions per theme):

#### IS (What it is)

**Source:** Solution template `name` + `category` + `enabler_type`
**Expand with:** P-candidate context that explains what this capability actually does

**Pattern:**
```markdown
**What it is:** [Concrete definition expanding ST name]. A [category] capability that [core function from P-candidate opportunities_md].
```

**Requirements:**
- Specific enough that an executive knows what it is in 20 seconds
- Not abstract jargon — concrete capability description
- 1-2 sentences maximum

#### DOES (What it does for you)

**Source:** P-candidates `opportunities_md` + quantitative claims
**Apply:** You-Phrasing and Number Plays

**Pattern:**
```markdown
**What it does for you:** You [outcome 1 with quantification from claims]<sup>[citation]</sup>. Your [capability area] [outcome 2 with quantification]. This translates to [business metric improvement] because [P-candidate evidence].
```

**Requirements:**
- Use "You" and "Your" throughout
- 2-3 concrete, quantified outcomes
- Citations from enriched-trends evidence
- Number Plays applied (ratios, before/after, compound)

#### MEANS (Why competitors struggle to copy)

**Source:** S-candidates `evidence_md` + foundation requirements
**Focus:** Time moats, tacit knowledge, organizational maturity barriers

**Pattern:**
```markdown
**Why competitors struggle to copy:** This requires [timeframe from S-candidate evidence] of [capability building activity]<sup>[citation]</sup>. [Fast alternative] is fast; [slow advantage] is slow. Your [first-mover advantage description].
```

**Requirements:**
- Specific barrier type (time, tacit knowledge, network, experience)
- Timeframe for capability building
- Why purchasing/hiring can't shortcut the moat
- S-candidate evidence for the barrier

## Power Position When No Solution Templates

If `SOLUTION_TEMPLATES` is empty, construct Power Positions from P-candidates:

1. Group P-candidates by strategic opportunity type
2. Use the P-candidate's `name` as the IS basis
3. Use `opportunities_md` for DOES
4. Use S-candidates for MEANS (same as with STs)

## Solution Templates Table

If `SOLUTION_TEMPLATES` is non-empty, include inline after Power Position prose:

```markdown
| # | Solution | Category | Enabler Type |
|---|----------|----------|-------------|
| 1 | {st.name} | {st.category} | {st.enabler_type} |
```

Brief description of each ST and how it addresses the theme's strategic question. 1-2 sentences per ST.

## Quality Checkpoints

- [ ] 1-3 Power Positions created (from STs or P-candidates)
- [ ] IS layer: Concrete, 20-second definition (not abstract)
- [ ] DOES layer: You-Phrasing throughout
- [ ] DOES layer: 2-3 quantified outcomes with citations
- [ ] MEANS layer: Specific competitive barrier with timeframe
- [ ] MEANS layer: S-candidate evidence for capability moat
- [ ] Solution templates table included (if STs available)
- [ ] Word count within proportional range (+/-10% tolerance)
- [ ] Smooth transition from Why Now
- [ ] Smooth transition to Why Pay

## Common Mistakes

❌ **Feature list:** "The portfolio includes: Digital Twin Platform, Predictive Maintenance Suite, Customer Portal."
✓ **Power Position:** "**Digital Twin Platform** — IS: Real-time virtual grid replica integrating OT sensors with IT analytics. DOES: You reduce unplanned outages 34% and extend asset life by 12 years. MEANS: Accurate digital twins require 18 months of sensor calibration — off-the-shelf models miss site-specific failure patterns."

❌ **Missing You-Phrasing:** "Organizations that deploy predictive maintenance achieve 23% cost reduction."
✓ **You-Phrasing:** "You reduce maintenance costs 23% while competitors still schedule by calendar, not condition."

❌ **Weak MEANS:** "This is a difficult capability to build."
✓ **Specific moat:** "Building accurate grid digital twins requires 18 months of sensor calibration and domain model tuning. Technology purchases are fast. Calibration wisdom is slow. Your 18-month head start becomes your competitive moat."

## Language Variations

### German Style

```markdown
#### Position: Digitale Zwillingsplattform

**Was es ist:** Echtzeit-Virtualabbild der Netzinfrastruktur, das OT-Sensordaten mit IT-Analysen integriert. Ermöglicht prädiktive Wartung und Lastoptimierung in einem System.

**Was es für Sie leistet:** Sie reduzieren ungeplante Ausfälle um 34% und verlängern die Anlagenlebensdauer um 12 Jahre<sup>[1]</sup>. Ihre Netzplanung basiert auf Echtzeit-Zustandsdaten statt auf Kalenderintervallen. Resultat: 23% niedrigere Wartungskosten bei 2,3x höherer Prognosegüte<sup>[2]</sup>.

**Warum Wettbewerber nicht kopieren können:** Präzise digitale Zwillinge erfordern 18 Monate Sensorkalibrierung und Domänenmodell-Training<sup>[3]</sup>. Technologie-Kauf ist schnell. Kalibrierungswissen ist langsam. Ihr Vorsprung wird zum Wettbewerbsgraben.
```

## Related Patterns

- See `why-change-patterns.md` for the unconsidered need these positions address
- See `why-now-patterns.md` for the urgency that demands these capabilities
- See `why-pay-patterns.md` for the cost of NOT building these positions
