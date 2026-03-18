# cogni-sales

B2B sales pitch generation using the Corporate Visions "Why Change" methodology. Creates sales presentations and proposals from cogni-portfolio data with optional TIPS strategic enrichment. Supports both named-customer pitches and reusable segment pitches.

## Architecture

cogni-sales applies story arcs from **cogni-narrative** using data from **cogni-portfolio**:

```
cogni-narrative (story arcs)     cogni-portfolio (IS/DOES/MEANS)     cogni-tips (trends)
         │                                │                                │
         └────────────── cogni-sales ─────┘────────────────────────────────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
        Named customer pitches    Segment pitches (reusable)
                 │                         │
          ┌──────┴──────┐           ┌──────┴──────┐
          │             │           │             │
  sales-presentation  sales-proposal  sales-presentation  sales-proposal
```

**cogni-sales** is for the full Why Change arc — both deal-specific (named customer) and reusable (market segment).
**cogni-marketing** is for channel-ready content: battle cards, one-pagers, campaigns, ABM.
Both share the same story arcs from cogni-narrative.

## Skills

| Skill | Description |
|-------|-------------|
| `why-change` | Create a Why Change pitch (acquisition) — customer mode or segment mode, with 4-phase research workflow |

Future: `why-stay` (retention), `why-evolve` (expansion)

## Quick Start

```
/why-change
```

The skill walks you through:
1. **Setup** — Select portfolio, choose mode (customer or segment), configure language
2. **Why Change** — Research unconsidered needs, disrupt status quo
3. **Why Now** — Establish urgency with forcing functions
4. **Why You** — Build Key Differentiators with IS/DOES/MEANS
5. **Why Pay** — Quantify business case, ROI vs cost of inaction
6. **Synthesize** — Assemble final deliverables

### Customer Mode

For a named customer like Siemens — includes company-specific web research, personalized framing.

### Segment Mode

For a market segment like "Enterprise Manufacturing DACH" — produces reusable pitch materials with industry-level research that work for any organization in the segment.

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-portfolio | Yes | Products, features, propositions, solutions, markets, competitors |
| cogni-narrative | Yes | Corporate Visions story arc patterns |
| cogni-tips | No | TIPS trend evidence enrichment |
| cogni-claims | No | Source verification for web-sourced claims |
| cogni-copywriting | No | Polish final output |
| cogni-visual | No | Generate PPTX from presentation |

## License

AGPL-3.0-only — see [LICENSE](LICENSE).
