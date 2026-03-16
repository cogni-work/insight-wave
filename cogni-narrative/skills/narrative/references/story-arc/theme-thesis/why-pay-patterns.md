# Why Pay: Cost of Inaction Patterns (Theme Thesis)

## Element Purpose

Quantify the **cost of inaction** through compound impact calculation — stacking multiple cost dimensions from the theme's evidence to create an undeniable financial case for investment.

**Word Target:** 17% of theme section target

## Source Content Mapping

Extract from theme's value chains:

1. **I-candidates** (primary) — `chain.implications[]`
   - Value chain disruption costs from `evidence_md`
   - Revenue impact, efficiency losses, customer migration risks
   - `implications_md` for specific business process cost data

2. **S-candidates** (secondary) — `chain.foundation_requirements[]`
   - Capability gap costs from `evidence_md`
   - What happens when prerequisites aren't met: operational failures, integration costs
   - Talent premium data for delayed capability building

3. **Claims with financial data** — from claims files
   - Cost figures, revenue data, penalty amounts
   - Growth rates that compound over time

4. **Act-horizon evidence** — timeline-specific costs
   - Costs that escalate with delay (regulatory penalties, talent premiums)

## Compound Impact Calculation

### Formula

```
Total Cost of Inaction (3-year) =
  Cost Dimension 1 (largest: regulatory OR market loss) +
  Cost Dimension 2 (talent/capability premium) +
  Cost Dimension 3 (operational opportunity cost) +
  → Proactive investment comparison
  → Simple ratio
```

### Cost Dimensions

**Dimension 1 (~25%): Regulatory/Market Loss** (whichever is strongest in evidence)

```markdown
**[Label]:** [Specific cost from I-candidate or T-candidate evidence]<sup>[citation]</sup>. Over 3 years: [calculated total]. [Early movers comparison].
```

**Dimension 2 (~25%): Talent/Capability Premium**

```markdown
**Talent premium:** Building [capability from S-candidates] in [future year] vs. now: [premium percentage from evidence]<sup>[citation]</sup>. For [team/capability scope]: [total excess cost]. Starting now enables building at current rates.
```

**Dimension 3 (~25%): Operational/Efficiency Opportunity Cost**

```markdown
**Opportunity cost:** [Efficiency gains from P-candidates] compound at [rate from evidence]<sup>[citation]</sup>. [Timeframe] delay results in [foregone value]. Organizations acting now capture [advantage window].
```

**Synthesis (~25%):**

```markdown
**Compound calculation:** Delay costs [total range] over 3 years. Proactive investment: [cost range]. Action costs less than inaction by a factor of [ratio]x.
```

## 3-Year Horizon Standard

Use 3-year horizon for all calculations:
- Short enough to feel immediate to CxOs
- Long enough to show compound effects
- Standard executive planning cycle

If evidence supports different timeframes, normalize to 3 years for comparison.

## Quality Checkpoints

- [ ] 3 cost dimensions identified and quantified
- [ ] Each dimension has specific € or $ amount from evidence
- [ ] 3-year horizon used consistently
- [ ] Citations for all cost figures from enriched-trends or claims
- [ ] Before/after comparison (proactive vs. reactive)
- [ ] Simple ratio comparison at end
- [ ] Evidence traces to actual I-candidate or S-candidate data
- [ ] Word count within proportional range (+/-10% tolerance)
- [ ] Smooth transition from Why You

## Common Mistakes

❌ **Vague costs:** "Delaying will increase costs significantly."
✓ **Quantified compound:** "Delay costs €6.96M over 3 years: NIS2 penalties €960K + talent premium €1.2M + preventable outage losses €4.8M. Proactive investment: €2.3M. Factor: 3x."

❌ **Single cost dimension:** "Non-compliance penalties will be €420K."
✓ **Stacked dimensions:** "Three cost dimensions compound: (1) Penalties €960K, (2) Talent €1.2M, (3) Operational losses €4.8M = Total €6.96M vs. €2.3M proactive."

❌ **No ratio:** "Organizations should invest €2.3M proactively to avoid €6.96M in losses."
✓ **Simple ratio:** "Action costs less than inaction by a factor of 3x."

❌ **Fabricated numbers:** Inventing cost figures not in the evidence.
✓ **Evidence-grounded:** Every number traces to enriched-trends `evidence_md` or claims data. If evidence doesn't support specific figures, use qualitative framing.

## Language Variations

### German Style

```markdown
### Geschäftliche Auswirkungen: Der Business Case

Verzögerung kostet in drei Dimensionen.

**Regulatorische Strafen:** NIS2-Nichtkonformität: €420K initial plus €180K jährlich<sup>[1]</sup>. Über 3 Jahre: €960K vermeidbar.

**Talent-Premium:** OT-KI-Spezialisten 2027-2028: 47% Gehaltsaufschlag<sup>[2]</sup>. Für 10 Positionen: €1,2M Mehrkosten.

**Operative Verluste:** Vermeidbare Netzausfälle ohne prädiktive Wartung: €4,8M über 3 Jahre<sup>[3]</sup>.

**Gesamtrechnung:** Verzögerung: €6,96M. Proaktive Investition: €2,3M. Aktion kostet Faktor 3x weniger als Inaktivität.
```

## Related Patterns

- See `why-change-patterns.md` for the unconsidered need that creates these costs
- See `why-now-patterns.md` for the forcing functions that accelerate costs
- See `why-you-patterns.md` for the capabilities that avoid these costs
