# cogni-sales

B2B sales pitch generation using the Corporate Visions "Why Change" methodology. Creates customer-specific sales presentations and proposals from cogni-portfolio data with optional TIPS strategic enrichment.

## Architecture

cogni-sales applies story arcs from **cogni-narrative** to **named customers** using data from **cogni-portfolio**:

```
cogni-narrative (story arcs)     cogni-portfolio (IS/DOES/MEANS)     cogni-tips (trends)
         │                                │                                │
         └────────────── cogni-sales ─────┘────────────────────────────────┘
                              │
                    Named customer pitches
                              │
                 ┌────────────┴────────────┐
                 │                         │
       sales-presentation.md      sales-proposal.md
```

**cogni-sales** is for deal-specific pitches to named customers.
**cogni-marketing** is for reusable segment/market collateral.
Both share the same story arcs from cogni-narrative.

## Skills

| Skill | Description |
|-------|-------------|
| `why-change` | Create a Why Change pitch (acquisition) with 4-phase research workflow |

Future: `why-stay` (retention), `why-evolve` (expansion)

## Quick Start

```
/why-change
```

The skill walks you through:
1. **Setup** — Select portfolio, name the customer, match market, configure language
2. **Why Change** — Research unconsidered needs, disrupt status quo
3. **Why Now** — Establish urgency with forcing functions
4. **Why You** — Build Power Positions with IS/DOES/MEANS
5. **Why Pay** — Quantify business case, ROI vs cost of inaction
6. **Synthesize** — Assemble final deliverables

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
