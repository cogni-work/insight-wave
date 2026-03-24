# cogni-sales

B2B sales pitch generation for [Claude Cowork](https://claude.ai/cowork) using Corporate Visions Why Change methodology. Creates sales presentations and proposals for named customers (deal-specific) or market segments (reusable). Builds on cogni-portfolio data with optional TIPS strategic enrichment. Bilingual DE/EN.

## Why this exists

Generic pitch decks don't win deals. Buyers expect sellers to understand their specific situation — yet building a tailored pitch takes days of research, narrative framing, and slide crafting per opportunity:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Generic pitches | Same slides for every customer, no industry or account context | Buyers disengage — "you don't understand my business" |
| Manual research | Hours spent finding company news, industry trends, competitive landscape | Outdated by the time the pitch ships |
| Methodology drift | Why Change structure gets diluted without discipline — phases blur, evidence thins | Weaker narrative arc, lower win rates |
| No claim traceability | Market stats and competitor assertions cited without source verification | Credibility risk when buyers check the numbers |

This plugin automates the research-heavy parts of the Corporate Visions Why Change framework — web research, evidence gathering, narrative framing — while keeping strategic judgment with you.

## What it does

1. **Setup** — select a portfolio, market, and customer (or segment). Configure language, solution focus, and buying center roles
2. **Why Change** — research the customer's unconsidered needs: industry disruptions, regulatory shifts, competitive pressure. Build the case for why the status quo is unsafe
3. **Why Now** — research urgency drivers: regulatory deadlines, competitive moves, market windows, technology tipping points
4. **Why You** — research differentiation: unique capabilities, competitive gaps, proof points, customer evidence
5. **Why Pay** — research business impact: ROI models, TCO comparisons, risk quantification, value realization timelines
6. **Synthesize** — assemble all phases into a `sales-presentation.md` and `sales-proposal.md` with sequential citations

## What it means for you

- **Deal-specific in hours, not days.** The researcher agent handles web research, company analysis, and evidence gathering — you review and steer.
- **Methodology-disciplined.** Every pitch follows the four Why Change phases with proper evidence structure. No phase gets skipped or diluted.
- **Two modes.** Customer mode for named accounts (company-specific research). Segment mode for reusable pitches across a market vertical.
- **Claims-verified.** Every factual claim is registered with source URLs. Optional cogni-claims integration verifies them before you present.
- **Resumable.** Interrupted pitches resume from the last completed phase. No lost work.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

**Prerequisites:**
- Web access enabled (for customer and industry research)
- **cogni-portfolio** (required — provides products, propositions, markets, competitors)
- **cogni-narrative** (required — provides Corporate Visions story arc patterns)
- Optional: **cogni-trends** (TIPS strategic theme enrichment), **cogni-claims** (source verification), **cogni-copywriting** (executive polish), **cogni-visual** (PPTX generation)

## Quick start

```
/why-change                       # start a new pitch (aliases: /pitch, /sales-pitch, /segment-pitch)
/why-change --project-path <path> # resume an existing pitch
```

Or describe what you want in natural language:

- "Create a Why Change pitch for Siemens Manufacturing"
- "Build a segment pitch for mid-market cloud migration in DACH"
- "Resume the Bechtle pitch"
- "Generate a sales presentation for our IoT portfolio targeting energy utilities"

## Try it

After installing, type one prompt:

> Create a Why Change pitch for a cloud services customer

Claude discovers your portfolio, asks for customer details, then works through all four phases — researching the web, building evidence, and writing narrative prose for each. At the end, you get two deliverables ready for review.

Results land in your project directory:

```
cogni-sales/{pitch-slug}/
├── 01-why-change/
│   ├── research.json             Structured findings with evidence
│   └── narrative.md              Prose following Corporate Visions arc
├── 02-why-now/
│   ├── research.json
│   └── narrative.md
├── 03-why-you/
│   ├── research.json
│   └── narrative.md
├── 04-why-pay/
│   ├── research.json
│   └── narrative.md
├── output/
│   ├── sales-presentation.md     Executive presentation structure
│   └── sales-proposal.md         Detailed proposal document
└── .metadata/
    ├── pitch-log.json            Workflow state + buying center config
    └── claims.json               Registered claims with source URLs
```

## Data model

Each pitch project tracks state in `pitch-log.json` with pitch mode (customer/segment), workflow phase, buying center roles (economic buyer, technical evaluator, end users, champion), portfolio references, and language config. Per-phase bridge files split structured research (`research.json`) from prose output (`narrative.md`). See [skills/why-change/references/pitch-data-model.md](skills/why-change/references/pitch-data-model.md) for the full schema.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `why-change` | skill | Main orchestrator — 6-phase pipeline from setup through all four Why Change phases to synthesis |
| `why-change-researcher` | agent (opus) | Research specialist for all 4 content phases — web research, evidence gathering, narrative writing, claims registration |
| `pitch-synthesizer` | agent (sonnet) | Assembles final deliverables from completed phase research into presentation and proposal formats |
| `/why-change` | command | Slash command entry point (aliases: `/pitch`, `/sales-pitch`, `/segment-pitch`) |
| `discover-portfolio.sh` | script | Find available cogni-portfolio projects in workspace |
| `init-pitch-project.sh` | script | Initialize pitch project directory structure |
| `pitch-status.sh` | script | Check status of an existing pitch project for resume workflow |

## Architecture

```
cogni-sales/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       1 pitch skill (why-stay, why-evolve planned)
│   └── why-change/
│       ├── SKILL.md
│       └── references/           Pitch data model + output specs
├── agents/                       2 pitch agents
│   ├── why-change-researcher.md
│   └── pitch-synthesizer.md
├── commands/                     1 slash command
│   └── why-change.md
└── scripts/                      3 project utilities
    ├── discover-portfolio.sh
    ├── init-pitch-project.sh
    └── pitch-status.sh
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-portfolio | Yes | Products, features, propositions, solutions, markets, competitors, customers |
| cogni-narrative | Yes | Corporate Visions story arc patterns (why-change, why-now, why-you, why-pay) |
| cogni-trends | No | TIPS strategic theme enrichment — value-modeler themes, regulatory timelines, gap analysis |
| cogni-claims | No | Source verification for web-sourced claims |
| cogni-copywriting | No | Executive polish on final deliverables |
| cogni-visual | No | PPTX generation from sales presentation |

## Custom development

Need a custom sales methodology, CRM integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
