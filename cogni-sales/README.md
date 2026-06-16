# cogni-sales

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

A B2B pitch-generation pipeline built on the Corporate Visions Why Change methodology, turning cogni-portfolio data into deal-specific or reusable segment sales narratives.

> **Multi-market & multilingual.** Pitch setup matches the deal to one of the platform's supported markets — European-first across DACH/DE/FR/IT/ES/NL/PL plus UK/US — with multilingual output (EN / DE / PT-BR). See [Supported markets & languages](../cogni-workspace/README.md#supported-markets--languages).

## Why this exists

Generic pitch decks don't win deals. Buyers expect sellers to understand their specific situation — yet building a tailored pitch takes days of research, narrative framing, and slide crafting per opportunity:

| Problem | What happens | Impact |
|---------|-------------|--------|
| Generic pitches | Same slides for every customer, no industry or account context | Buyers disengage — "you don't understand my business" |
| Manual research | Hours spent finding company news, industry trends, competitive landscape | Outdated by the time the pitch ships |
| Methodology drift | Why Change structure gets diluted without discipline — phases blur, evidence thins | Weaker narrative arc, lower win rates |
| No claim traceability | Market stats and competitor assertions cited without source verification | Credibility risk when buyers check the numbers |

A pitch that lands a week late, leans on stale numbers, or drifts off the Why Change arc is a deal the seller is already losing — and the cost compounds across every opportunity in the pipeline.

## What it is

A pitch-generation pipeline organized around the Corporate Visions Why Change methodology — the four-question arc of Why Change, Why Now, Why You, and Why Pay. It treats your portfolio as the source of truth: cogni-portfolio supplies the product data, cogni-narrative supplies the story-arc patterns, and cogni-trends optionally layers in strategic themes. Other plugins generate content; this one shapes that content into a buyer-ready sales narrative.

## What it does

1. **Setup** — select a portfolio, market, and customer (or segment). Configure language, solution focus, and buying center roles
2. **Why Change** — research the customer's unconsidered needs: industry disruptions, regulatory shifts, competitive pressure. Build the case for why the status quo is unsafe
3. **Why Now** — research urgency drivers: regulatory deadlines, competitive moves, market windows, technology tipping points
4. **Why You** — research differentiation: unique capabilities, competitive gaps, proof points, customer evidence
5. **Why Pay** — research business impact: ROI models, TCO comparisons, risk quantification, value realization timelines
6. **Synthesize** — assemble all phases into a `sales-presentation.md` and `sales-proposal.md` with sequential citations → `sales-presentation.md` + `sales-proposal.md` → story-to-slides, copywriter (presentation deck)
7. **Review** — closed stakeholder loop: buyer, sales director, and marketing director perspectives evaluate the pitch; automated revision if needed (max 2 passes)

## What it means for you

- **Pitch in hours, not days.** The researcher agent runs the web research, company analysis, and evidence gathering across all four phases — you review and steer instead of starting from a blank deck.
- **Stay on-method every time.** Every pitch follows all four Why Change phases with structured evidence — no phase skipped, no message diluted, even under deadline pressure.
- **Serve 1:1 and 1:many from one engine.** Customer mode researches the named account; segment mode produces a reusable template for the whole vertical — zero pipeline rebuild between deal-specific and market pitches.
- **Present numbers you can defend.** Every factual claim is registered with a source URL, and optional cogni-claims verification checks them in one pass — no unsourced statistics in front of the buyer.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

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

Start a pitch with the command:

> Run `/cogni-sales:why-change`

Claude discovers your cogni-portfolio projects, asks whether this is a named-customer or a segment pitch, matches the market, and then works through all four phases in sequence — researching the web, gathering evidence, and writing narrative prose for each. A quality gate after every phase lets you approve or revise before the next one runs, so you steer the strategy while the agent does the legwork.

Every claim the research surfaces is registered with its source URL, so you can verify the evidence before the pitch ever reaches a prospect. When the run finishes, the two deliverables land under your project directory:

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

## How it works

The pipeline runs the four Why Change questions in a fixed order — `setup → why-change → why-now → why-you → why-pay → synthesize → review` — because each phase builds on the case the previous one established. Setup grounds everything: it discovers a cogni-portfolio project, fixes the pitch mode (customer vs. segment), matches the market, and records the buying-center roles, so every later phase researches against the right account and audience.

The four research phases each dispatch the `why-change-researcher` agent. The researcher reasons backwards from portfolio capabilities to strategic themes first, then runs guided web research — Why Change establishes the unsafe status quo, Why Now adds time-bound urgency, Why You differentiates, and Why Pay quantifies the business impact. Each phase writes a structured `research.json` (evidence, buyer-role tags, claims) separately from its `narrative.md` prose, so findings and writing stay independently revisable.

`synthesize` then assembles all four phases into `sales-presentation.md` and `sales-proposal.md` with sequentially renumbered citations. Synthesis comes last because renumbering and cross-phase arc continuity only make sense once every phase is final. A closed `review` loop follows: the `pitch-review-assessor` evaluates the result from buyer, sales-director, and marketing-director perspectives, and the `pitch-revisor` applies surgical fixes if needed (capped at two passes). Because state lives in `pitch-log.json`, an interrupted pitch resumes from the last completed phase rather than re-running research.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `why-change` | skill | Create a Why Change sales pitch for a named customer or a reusable segment pitch for a market. |
| `why-change-researcher` | agent (opus) | Research and generate content for a specific phase of the Why Change pitch workflow. |
| `pitch-synthesizer` | agent (sonnet) | Assemble final sales-presentation.md and sales-proposal.md from phase research. |
| `pitch-review-assessor` | agent (haiku) | Assess sales pitch quality from three stakeholder perspectives (buyer, sales, marketing). |
| `pitch-revisor` | agent (sonnet) | Revise sales pitch deliverables based on pitch-review-assessor feedback. |
| `/why-change` | command | Create a Why Change sales pitch for a named customer or market segment (aliases: `/pitch`, `/sales-pitch`, `/segment-pitch`) |
| `discover-portfolio.sh` | script | Scan workspace for cogni-portfolio projects and return JSON metadata |
| `init-pitch-project.sh` | script | Scaffold pitch project directory under cogni-sales/{slug}/ |
| `pitch-status.sh` | script | Report pitch state: mode, phase, claims count, and deliverable readiness |

## Architecture

```
cogni-sales/
├── .claude-plugin/               Plugin manifest (v0.4.2)
├── skills/                       1 pitch skill
│   └── why-change/
│       ├── SKILL.md
│       ├── references/
│       ├── evals/                Eval definitions and baselines
│       └── why-change-workspace/ Iteration workspace (iteration-0 through iteration-3)
├── agents/                       4 pitch agents
│   ├── why-change-researcher.md
│   ├── pitch-synthesizer.md
│   ├── pitch-review-assessor.md
│   └── pitch-revisor.md
├── commands/                     1 slash command
│   └── why-change.md
├── scripts/                      3 project utilities
│   ├── discover-portfolio.sh
│   ├── init-pitch-project.sh
│   └── pitch-status.sh
└── references/                   Shared reference files
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

## Contributing

Contributions welcome — sales methodologies, pitch templates, evidence strategies, and documentation. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom sales methodology beyond Why Change, a CRM integration, or a new plugin tailored to your domain? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for sales and consulting teams.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
