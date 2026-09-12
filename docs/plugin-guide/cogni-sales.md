# cogni-sales

Corporate Visions Why Change pitch generation for B2B sales.

> For the canonical IS/DOES/MEANS positioning and installation instructions, see the [cogni-sales README](../../cogni-sales/README.md).

---

## Overview

cogni-sales generates sales presentations and proposals using the Corporate Visions Why Change methodology. The four-phase framework — Why Change, Why Now, Why You, Why Pay — structures a pitch as a sequential argument: first, challenge the buyer's status quo; then, create urgency; then, differentiate your solution; finally, justify the investment.

The plugin handles two modes. Customer mode produces a deal-specific pitch for a named account, grounded in web research about that company's current situation, industry pressures, and competitive exposure. Segment mode produces a reusable pitch for a market vertical — same methodology, industry-level evidence rather than company-specific.

For each phase, a dedicated researcher agent (running on Claude Opus) conducts web research, gathers evidence, writes narrative prose following the arc element's requirements, and registers claims with source URLs. At the end of all four phases, a synthesiser agent assembles the phase outputs into two deliverables: `sales-presentation.md` and `sales-proposal.md`.

### When to reach for this plugin

- You have a named prospect and need a tailored pitch in hours rather than days
- You are building a reusable pitch for a new market segment
- You need to resume an interrupted pitch from a previous session
- You want a pitch that is provably grounded — every factual claim linked to a source

### Prerequisites

- **cogni-portfolio** (required) — provides products, features, propositions, solutions, markets, competitors, and customer profiles
- **cogni-workspace** (required) — its `text-to-narrative` skill bundles the Corporate Visions arc contract that the researcher agent reads and follows
- Web access enabled — the researcher agent conducts live web research for each phase
- Optional: cogni-trends (TIPS strategic theme enrichment); further cogni-workspace features (source verification via `claims`, executive polish via the `copywriter` skill, a Claude Design slides brief via `text-to-narrative`)

---

## Key Concepts

### The Corporate Visions Why Change arc

The pitch follows four arc elements in sequence. Each element has a defined rhetorical role, evidence type, and writing pattern defined in the `text-to-narrative` arc contract file (`arc-corporate-visions.md`):

| Phase | Arc element | Rhetorical role | Evidence type |
|-------|-------------|----------------|---------------|
| 1 | Why Change | Disrupt the status quo — surface unconsidered needs | Industry disruptions, regulatory shifts, competitive pressure |
| 2 | Why Now | Create urgency — cost of inaction | Regulatory deadlines, competitive moves, market windows, technology tipping points |
| 3 | Why You | Differentiate — unique capabilities and proof | IS/DOES/MEANS propositions, competitive gaps, customer evidence |
| 4 | Why Pay | Build the business case | ROI models, TCO comparisons, risk quantification, value timelines |

The arc contract is read from `text-to-narrative` at generation time, so the pitch aligns with whatever arc version that skill currently bundles. This dependency is intentional — it means the pitch methodology stays in sync with the narrative layer.

### Customer mode vs. segment mode

| | Customer mode | Segment mode |
|-|--------------|-------------|
| Target | Named account (e.g., Siemens Manufacturing) | Market vertical (e.g., Enterprise Manufacturing DACH) |
| Research scope | Company-specific: news, financials, industry position | Industry-level: sector trends, regulatory landscape, benchmark data |
| Output reuse | Single-deal artefact | Reusable template for any organisation in the segment |
| When to use | Active deal with a specific company | Pre-pipeline; new segment entry; repeatable pitch motion |

### Pitch project structure

Each pitch project lives in its own directory:

```
cogni-sales/{pitch-slug}/
├── 01-why-change/
│   ├── research.json             Structured findings with evidence
│   └── narrative.md              Prose following the arc element's requirements
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
    └── claims.json               All registered claims with source URLs
```

The phase separation is not just organisational — it enables resumability. If a session is interrupted after Why Change and Why Now, the next session reads `pitch-log.json`, sees the completed phases, and resumes from Why You.

### Buying center configuration

During setup, you configure the buying center roles relevant to the deal:

- Economic buyer — the financial decision maker
- Technical evaluator — the IT or operations stakeholder
- End users — the practitioners who will use the solution
- Champion — the internal advocate

The researcher agent tailors evidence and framing in each phase to address the concerns of these roles.

---

## Getting Started

Start a new pitch with:

```
/why-change
```

Or in natural language:

```
Create a Why Change pitch for Siemens Manufacturing
```

Expected interaction:

1. The skill runs the portfolio discovery script and lists available cogni-portfolio projects
2. You confirm which portfolio to use and select a market
3. You choose customer mode or segment mode
4. If customer mode: you provide the company name and industry
5. You configure buying center roles, language (DE/EN), and solution focus
6. The researcher agent begins Phase 1 (Why Change): researches the web, writes findings to `research.json` and narrative prose to `narrative.md`
7. It presents the Why Change narrative for your review before proceeding to Phase 2
8. Phases 2-4 follow the same pattern
9. After Phase 4, the synthesiser agent assembles the two output files

The pitch runs sequentially — each phase is reviewed before the next begins. You can steer the research direction at each review point.

---

## Capabilities

### why-change — Run the full four-phase pitch pipeline

The single skill in cogni-sales orchestrates the entire pipeline: setup, four research phases, and synthesis. It is the entry point for both new pitches and resuming existing ones.

**Starting a new pitch:**
```
/why-change
```

**Resuming an interrupted pitch:**
```
/why-change --project-path cogni-sales/siemens-manufacturing-2026/
```

Or:
```
Resume the Bechtle pitch
```

The skill reads `pitch-log.json` to determine the last completed phase and picks up from there.

**Segment pitch:**
```
Build a segment pitch for mid-market cloud migration in DACH
```

The skill detects segment mode from the request and adjusts the research scope accordingly.

Key parameters:

| Parameter | Description |
|-----------|-------------|
| `--project-path` | Path to an existing pitch project (triggers resume mode) |
| Mode | Customer vs. segment (selected interactively during setup) |
| `--language` | `en` or `de` (configured during setup) |

Aliases: `/pitch`, `/sales-pitch`, `/segment-pitch` all invoke the same skill.

---

## Integration Points

### Upstream inputs (required)

| Plugin | What cogni-sales reads |
|--------|----------------------|
| cogni-portfolio | Products, features, propositions, solutions, markets, competitors, customers |
| cogni-workspace (`text-to-narrative`) | Corporate Visions arc contract (arc element requirements, evidence patterns, writing rules) |

### Upstream inputs (optional enrichment)

| Plugin | Purpose |
|--------|---------|
| cogni-trends | Enriches Why Change and Why Now phases with TIPS strategic theme data, regulatory timelines, and gap analysis |
| cogni-workspace | Verifies web-sourced claims in `claims.json` against their source URLs before the pitch ships |

### Downstream consumers

| Plugin | How it uses cogni-sales output |
|--------|-------------------------------|
| the `copywriter` skill | Polishes `sales-presentation.md` and `sales-proposal.md` for executive voice before distribution |
| cogni-workspace | Turns `sales-presentation.md` into a Claude Design slides brief via `text-to-narrative`; an existing `presentation-brief.md` still renders through `render-html-slides` or the `pptx` agent |
| cogni-marketing | ABM content for named accounts often reuses Why Change and Why Now evidence from a customer-mode pitch |

---

## Common Workflows

### Deal-specific pitch in one session

For a new opportunity with a named account:

1. `/why-change` — select customer mode; provide company name and industry
2. Review and steer each phase as it completes (four review points)
3. After synthesis: review `output/sales-presentation.md` and `output/sales-proposal.md`
4. Optional: `/copywrite output/sales-presentation.md` (the `copywriter` skill) for executive polish
5. Optional: `/cogni-workspace:text-to-narrative output/sales-presentation.md --target slides`, then hand the design brief to Claude Design

### Building a reusable segment pitch

For a new market vertical where no pitch template exists yet:

1. `/why-change` — select segment mode; specify the vertical (e.g., "enterprise manufacturing DACH")
2. The researcher uses industry-level evidence rather than company-specific data
3. Review and approve each phase
4. Store the completed pitch project as a reference for future customer-mode pitches in the same segment — the Why Change and Why Now phases carry over well

### Resuming an interrupted pitch

When a session ends before synthesis is complete:

1. `/why-change --project-path cogni-sales/{pitch-slug}/` — the skill reads `pitch-log.json` and identifies the last completed phase
2. Confirm the resume summary: "Phases 1 and 2 complete. Resuming from Why You."
3. The remaining phases run as normal

See [../workflows/portfolio-to-pitch.md](../workflows/portfolio-to-pitch.md) for the full portfolio-to-pitch-to-deck pipeline including cogni-workspace rendering.

---

## Troubleshooting

| Symptom | Likely cause | Resolution |
|---------|-------------|------------|
| Portfolio discovery finds nothing | cogni-portfolio project not in workspace | Run cogni-portfolio setup first; ensure `portfolio.json` exists in the workspace |
| Research phase produces thin evidence | Company is small or web presence is limited | Switch to segment mode for small/private companies; use industry-level evidence instead |
| Why You phase misses key differentiators | Portfolio propositions not fully populated | Complete cogni-portfolio's propositions phase before running the pitch |
| Resume fails to find completed phases | `pitch-log.json` missing or corrupted | Check the `.metadata/` directory; if `pitch-log.json` is absent, the pitch cannot be resumed — restart from the last completed phase manually |
| Claims.json is empty after research | Web access not enabled | Verify that web search is enabled in your Claude Code environment |
| German output has English framing | Language not set to DE during setup | Edit `pitch-log.json` to set `language: de` and re-run the affected phases |
| Synthesis produces a generic narrative | Phase narratives lack specificity | At each review point, add specific steering: company names, deal context, proof point priorities; the researcher reads your feedback before writing |

---

## Extending This Plugin

cogni-sales currently implements one methodology (Why Change). The architecture supports additional methodologies as separate skills:

- **why-stay** — retention-focused pitch for renewal situations (planned)
- **why-evolve** — expansion pitch for existing customers (planned)

Each new methodology would follow the same pattern: a skill file with phase definitions, a researcher agent configured for that arc's evidence types, and a synthesiser that assembles phase outputs into delivery formats.

Other contribution areas:

- **Evidence strategies** — Add phase-specific web research patterns to `skills/why-change/references/` for new verticals (healthcare, public sector, financial services)
- **Output templates** — Extend the output formats beyond `sales-presentation.md` and `sales-proposal.md` (e.g., RFP response template, executive briefing format)
- **CRM integration** — A new script could push pitch metadata and phase summaries to Salesforce or HubSpot opportunity records

See [../../CONTRIBUTING.md](../../CONTRIBUTING.md) and [../../cogni-sales/CONTRIBUTING.md](../../cogni-sales/CONTRIBUTING.md) for contribution guidelines.
