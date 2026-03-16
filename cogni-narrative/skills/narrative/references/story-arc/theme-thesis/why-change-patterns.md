# Why Change: Unconsidered Need Patterns (Theme Thesis)

## Element Purpose

Reframe the theme's external trends (T-candidates) and value chain implications (I-candidates) as an **unconsidered need** — a problem executives didn't know they had, or didn't realize was solvable in this way.

**Word Target:** 25% of theme section target

## Source Content Mapping

Extract from theme's value chains:

1. **T-candidates** (primary) — `chain.trend` for each value chain
   - External forces that most organizations underestimate or misframe
   - `evidence_md` from enriched-trends: quantitative proof the force is real
   - Filter to this theme's candidate_refs from `enriched-trends-externe-effekte.json`

2. **I-candidates** (secondary) — `chain.implications[]` for each value chain
   - How value chains are actually affected
   - `implications_md` from enriched-trends: specific business impact data
   - Makes the unconsidered need concrete and tangible

3. **Claims** — filtered from `claims-{dimension}.json` by candidate claims_refs
   - Quantitative evidence for problem reframing

## PSB Structure (Problem-Solution-Benefit)

### Problem (~33% of element)

**What to extract from T-candidates:**
- The conventional framing of the external force
- What most organizations in this industry assume about this trend
- What they're currently optimizing for (and why it feels reasonable)

**Pattern:**
```markdown
**The status quo assumption:** Most [industry] organizations view [T-candidate theme] as [conventional framing]<sup>[citation]</sup>. This framing makes intuitive sense: [why it seems reasonable]. Organizations respond by [conventional actions].
```

### Solution (~33% of element)

**What to extract from T-candidates + I-candidates:**
- What evidence_md actually reveals (counterintuitive or overlooked)
- How I-candidates show value chain impact that contradicts assumptions
- The reframing that research evidence demands

**Pattern:**
```markdown
**The unconsidered reality:** [What enriched evidence shows]<sup>[citation]</sup>. [Specific I-candidate impact that makes this concrete]. [Why conventional approach misses this].
```

### Benefit (~33% of element)

**What to extract:**
- Competitive advantage for organizations that recognize the unconsidered need
- What changes when the problem is framed correctly
- Bridge to Why Now (urgency becomes apparent once the need is seen)

**Pattern:**
```markdown
**The competitive shift:** Organizations that recognize [unconsidered need] gain [quantified advantage]<sup>[citation]</sup>. The competitive advantage shifts from "[old framing]" to "[new framing]." [Bridge sentence to urgency].
```

## Transformation Patterns

### Pattern 1: Misclassification Reframe

**When to use:** T-candidates reveal the domain is fundamentally different than assumed

**Structure:**
```markdown
[Industry] classifies [theme domain] as [Category A].
Evidence shows it behaves as [Category B]<sup>[citation]</sup>.
Applying [Category B] approaches yields [quantified improvement] over [Category A] approaches.
```

### Pattern 2: Scale Surprise

**When to use:** Evidence reveals unexpected magnitude in I-candidate impact

**Structure:**
```markdown
Most estimate [metric] at [conventional estimate].
Enriched evidence shows [actual metric]: [N]x larger<sup>[citation]</sup>.
This scale difference transforms the strategic calculus from [minor adjustment] to [fundamental repositioning].
```

### Pattern 3: Cross-Chain Convergence

**When to use:** Multiple value chains within the theme reinforce the same unconsidered need

**Structure:**
```markdown
Across [N] value chains, the same pattern emerges: [convergent finding]<sup>[citation]</sup>.
[Chain 1] shows [evidence]. [Chain 2] confirms [evidence]. [Chain 3] extends to [evidence].
This convergence signals not isolated trends but a systemic shift.
```

## Quality Checkpoints

- [ ] PSB structure followed (Problem ~33%, Solution ~33%, Benefit ~33%)
- [ ] Status quo assumption clearly stated with evidence
- [ ] Research evidence contradicts assumption with citations from enriched-trends
- [ ] Benefit articulates competitive advantage with quantification
- [ ] Contrast Structure used ("Most think X. Evidence shows Y.")
- [ ] T-candidates provide the external force
- [ ] I-candidates make the value chain impact concrete
- [ ] Ends with competitive implication that bridges to Why Now
- [ ] At least 3 citations to enriched-trends evidence
- [ ] Word count within proportional range (+/-10% tolerance)

## Common Mistakes

❌ **Trend catalog:** "This theme encompasses trends in regulation, technology, and customer expectations."
✓ **Unconsidered need:** "Most utilities view the 945 TWh datacenter consumption growth as an infrastructure challenge. Evidence shows it's actually a business model opportunity — and the organizations treating it as 'just more load' are optimizing for the wrong problem."

❌ **No I-candidate grounding:** "External forces are reshaping the industry" (abstract)
✓ **Concrete I-candidate impact:** "This external force translates directly to value chain disruption: processing costs drop 73% while data volume grows 12x, inverting the traditional cost-quality tradeoff."

## Language Variations

### German Style

```markdown
**Die Annahme:** Die meisten Versorger betrachten den Anstieg des Rechenzentrum-Stromverbrauchs auf 945 TWh als Infrastrukturproblem<sup>[1]</sup>.

**Die Realität:** Erfolgreiche Versorger nutzen diesen Anstieg als Geschäftsmodell-Transformation<sup>[2]</sup>. Der Datenverkehr, nicht die Kilowattstunde, wird zum Wertschöpfungstreiber.

**Der Vorteil:** Wer die Transformation als Plattform-Chance begreift, erschließt 2,3x höhere Margen<sup>[3]</sup>.
```

## Related Patterns

- See `why-now-patterns.md` for converting urgency from Why Change into forcing functions
- See `why-you-patterns.md` for the portfolio response to the unconsidered need
- See `why-pay-patterns.md` for quantifying the cost of ignoring the need
