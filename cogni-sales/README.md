# cogni-sales

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

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

## What it is

A pitch generation pipeline built on the Corporate Visions Why Change methodology. Four research phases — Why Change, Why Now, Why You, Why Pay — each backed by dedicated web research agents that gather company-specific or industry-level evidence. cogni-portfolio provides the product data (propositions, solutions, competitors); cogni-trends optionally enriches with strategic themes. The output is a sales-presentation.md and sales-proposal.md with sequential citations — ready for cogni-visual to render into slides.

## What it does

1. **Setup** — select a portfolio, market, and customer (or segment). Configure language, solution focus, and buying center roles
2. **Why Change** — research the customer's unconsidered needs: industry disruptions, regulatory shifts, competitive pressure. Build the case for why the status quo is unsafe
3. **Why Now** — research urgency drivers: regulatory deadlines, competitive moves, market windows, technology tipping points
4. **Why You** — research differentiation: unique capabilities, competitive gaps, proof points, customer evidence
5. **Why Pay** — research business impact: ROI models, TCO comparisons, risk quantification, value realization timelines
6. **Synthesize** — assemble all phases into a `sales-presentation.md` and `sales-proposal.md` with sequential citations → `sales-presentation.md` + `sales-proposal.md` → story-to-slides, copywriter (presentation deck)
7. **Review** — closed stakeholder loop: buyer, sales director, and marketing director perspectives evaluate the pitch; automated revision if needed (max 2 passes)

## What it means for you

- **Deal-specific in hours, not days.** The researcher agent handles web research, company analysis, and evidence gathering — you review and steer.
- **Methodology-disciplined across 100% of pitches.** Every deck follows all four Why Change phases (Why Change → Why Now → Why You → Why Pay) with proper evidence structure — no phase skipped, no message diluted.
- **Cover both 1:1 and 1:many sales motions without rebuilding the pipeline.** Customer mode researches the named account; segment mode produces a reusable template for any organization in the vertical — one engine, zero duplication effort per new pitch.
- **Claims-verified before you present.** Every factual claim in the deck is registered with a source URL; optional cogni-claims integration verifies all of them in one pass — zero unsourced statistics in front of the customer.
- **Keep multi-day deals moving without rework.** Interrupted pitches resume from the last completed phase — no research lost, no phase reruns, no pipeline stall when a conversation ends mid-workflow.

## Installation

This plugin is part of the [insight-wave monorepo](https://github.com/cogni-work/insight-wave) and is installed automatically with the marketplace.

### Claude Code desktop (recommended for insight-wave)

Install Claude Code via the native installer, then register the insight-wave marketplace and install this plugin:

```bash
# 1. Install Claude Code (macOS — other platforms: https://code.claude.com/docs/en/setup)
curl -fsSL https://claude.ai/install.sh | bash

# 2. Register the insight-wave marketplace
/plugin marketplace add cogni-work/insight-wave

# 3. Install this plugin
/plugin install cogni-sales@insight-wave
```

### Claude Cowork (short text-only tasks)

Cowork runs in Claude Desktop and is available on paid plans (Pro, Max, Team, Enterprise). For insight-wave, prefer Claude Code desktop — Cowork has two caveats that affect this plugin's workflows:

- **Context window**: Cowork caps context at ~200K tokens; long multi-agent flows trigger mid-session compressions.
- **Pencil MCP fidelity**: lower visual fidelity in Cowork than in Claude Code desktop.

See the [consultant install guide](../docs/claude-code-desktop.md) and the [repo-level deployment guide](../docs/deployment-guide.md) for the full path-by-path walkthrough.

> **insight-wave readiness**: Claude Code desktop is the recommended interface for insight-wave today. This guidance will flip when Cowork closes the context-window and Pencil-fidelity gaps.

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
| `why-change` | skill | Create a Why Change sales pitch for a named customer or a reusable segment pitch for a market. |
| `why-change-researcher` | agent (opus) | Research and generate content for a specific phase of the Why Change pitch workflow. |
| `pitch-synthesizer` | agent (sonnet) | Assemble final sales-presentation.md and sales-proposal.md from phase research. |
| `pitch-review-assessor` | agent (haiku) | Assess completed sales pitch quality from three stakeholder perspectives: target buyer, sales director, and marketing director. |
| `pitch-revisor` | agent (sonnet) | Revise sales pitch deliverables based on pitch-review-assessor feedback. |
| `/why-change` | command | Create a Why Change sales pitch for a named customer or market segment (aliases: `/pitch`, `/sales-pitch`, `/segment-pitch`) |
| `discover-portfolio.sh` | script | Scan workspace for cogni-portfolio projects and return JSON metadata |
| `init-pitch-project.sh` | script | Scaffold pitch project directory under cogni-sales/{slug}/ |
| `pitch-status.sh` | script | Report pitch state: mode, phase, claims count, and deliverable readiness |

## Architecture

```
cogni-sales/
├── .claude-plugin/               Plugin manifest (v0.4.1)
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

Need a custom sales methodology, CRM integration, or a new plugin for your domain? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
