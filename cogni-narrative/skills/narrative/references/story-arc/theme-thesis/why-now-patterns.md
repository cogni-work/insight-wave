# Why Now: Forcing Function Patterns (Theme Thesis)

## Element Purpose

Establish urgency through **forcing functions** from Act-horizon candidates — external deadlines, market tipping points, and regulatory pressures specific to this theme that make action time-sensitive.

**Word Target:** 20% of theme section target

## Source Content Mapping

Extract from theme's value chains:

1. **Act-horizon candidates** (primary) — any candidate where `horizon == "act"`
   - T-candidates with regulatory deadlines from `evidence_md`
   - I-candidates with market shift timelines
   - `evidence_md` fields containing dates, deadlines, growth rates

2. **Claims with timeline data** — filtered from claims files
   - Claims containing specific dates, percentages, or cost figures
   - Growth rates that create time pressure

3. **Plan-horizon candidates** (fallback) — if <2 Act-horizon candidates available
   - Use candidates with the most urgent timelines from evidence_md

## Forcing Function Construction

### Stack 2-3 Forcing Functions

**Why stack:** A single forcing function is easy to dismiss ("that might not happen"). Multiple converging forces create undeniable urgency.

### Forcing Function (~35% of element each, 2 functions)

**Pattern:**
```markdown
**[Category]:** [Specific deadline or tipping point from candidate evidence]<sup>[citation]</sup>. [Implementation timeframe from evidence]. [Timeline math: deadline minus implementation = start date]. [Consequence if missed].
```

**Categories to draw from (prioritize diversity):**
1. **Regulatory/Compliance** — deadlines from T-candidates (NIS2, EU AI Act, ESG reporting)
2. **Market Expectation** — customer/partner expectation shifts from I-candidates
3. **Technology Tipping Point** — maturity inflections from enriched-trends evidence
4. **Competitive Momentum** — adoption rates creating pressure

### Window Statement (~30% of element)

**Pattern:**
```markdown
**Window:** Organizations acting by [specific date] gain [quantified advantage from claims]. Organizations delaying past [date] face [quantified consequence]. The window for strategic positioning closes [timeframe].
```

## Timeline Math Pattern

Make the urgency calculation explicit:

```markdown
Deadline: [date from evidence]
Implementation requires: [timeframe from evidence]
Available time if starting now: [calculation]
Available time if starting [6 months later]: [insufficient — show why]
```

## Quality Checkpoints

- [ ] 2-3 forcing functions identified and stacked
- [ ] Each forcing function has specific deadline from enriched-trends evidence
- [ ] Each forcing function quantified (costs, timelines, percentages)
- [ ] Forcing functions come from different categories (not all regulatory)
- [ ] Citations for all deadlines and cost figures
- [ ] Before/after comparison (early vs. late movers)
- [ ] Window closing statement with specific date
- [ ] Act-horizon candidates used (not arbitrary urgency)
- [ ] Word count within proportional range (+/-10% tolerance)

## Common Mistakes

❌ **Vague urgency:** "The market is changing rapidly and organizations need to act."
✓ **Specific forcing function:** "NIS2 compliance deadline January 2027. Implementation: 18 months. Starting now: barely sufficient. Starting Q3 2026: impossible without €2.1M penalty exposure."

❌ **Single force:** "Regulation creates urgency."
✓ **Stacked forces:** "Two forces converge: NIS2 compliance (Jan 2027) AND 40% datacenter energy threshold triggering mandatory carbon reporting (Q2 2026)."

❌ **No timeline math:** "AI regulations take effect in 2027 and implementation takes time."
✓ **Explicit math:** "EU AI Act: January 2027. Compliant system development: 18-24 months. Organizations starting today: 22 months available. Starting Q3 2025: 14 months — insufficient."

## Language Variations

### German Style

```markdown
Zwei Kräfte konvergieren.

**Regulierung:** NIS2-Compliance-Frist Januar 2027<sup>[1]</sup>. Implementierung: 18 Monate. Start heute: knapp ausreichend. Start Q3 2026: nicht machbar ohne Strafrisiko von €2,1M.

**Markt:** 40% Rechenzentrum-Energieschwelle löst Pflicht-CO2-Berichterstattung aus (Q2 2026)<sup>[2]</sup>. Versorger ohne automatisiertes Reporting: 6-8 Monate Nachrüstung.

Strategisches Fenster schließt Q4 2026. Danach: Aufholmodus.
```

## Related Patterns

- See `why-change-patterns.md` for the unconsidered need that these forcing functions make urgent
- See `why-you-patterns.md` for the strategic response to this urgency
- See `why-pay-patterns.md` for quantifying the compound cost of delay
