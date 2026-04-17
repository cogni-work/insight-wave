# cogni-consulting

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

A [Claude Cowork](https://claude.ai/cowork) plugin that orchestrates consulting engagements through the Double Diamond framework — diverge to explore, converge to decide, twice. Includes Lean Canvas authoring via business-model-hypothesis, and lightweight how-might-we engagements for bounded challenges using guided ideation.

## Why this exists

Consulting engagements often stall in either analysis paralysis (endless research, no decisions) or premature convergence (jumping to solutions before understanding the problem). The Double Diamond provides structure — but without tooling, it's just a poster on the wall:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No structured methodology | Consultants improvise engagement flow, skip phases, or mix divergent and convergent work | Deliverables lack rigor; clients question the process |
| Manual plugin coordination | Research, trend scouting, portfolio analysis, and claims verification run as disconnected tasks | Context lost between phases; insights don't compound |
| No engagement state | Multi-session consulting work has no persistent record of what phase you're in, what's been decided, or why | Teams restart conversations; decisions get revisited without new evidence |

## What it is

A process orchestrator for the insight-wave ecosystem. cogni-consulting doesn't produce content itself — it manages engagement state and dispatches to existing plugins (cogni-research, cogni-trends, cogni-portfolio, cogni-claims, cogni-visual) at the right phase. Think of it as the senior partner who runs the engagement while specialists do the analysis.

## What it does

1. **Frame the vision** — select from 9 vision classes (strategic options, business case, GTM roadmap, cost optimization, digital transformation, innovation portfolio, market entry, business model hypothesis, how-might-we) and define engagement scope → `consulting-project.json` → consulting-discover
2. **Discover** (D1 diverge) — launch desk research, trend scouting, and competitive baseline via cogni-research, cogni-trends, and cogni-portfolio → `discover/synthesis.md` → consulting-define
3. **Define** (D1 converge) — verify assumptions via cogni-claims, cluster findings, synthesize the core problem statement → `define/problem-statement.md` + `define/hmw-questions.md` → consulting-develop
4. **Develop** (D2 diverge) — generate solution options via cogni-trends value-modeler and cogni-portfolio proposition modeling → `develop/options/option-synthesis.md` → consulting-deliver
5. **Deliver** (D2 converge) — score opportunities, verify final claims, construct business case and roadmap → `deliver/business-case.md` + `deliver/roadmap.md` → consulting-export
6. **Export** — generate the deliverable package (slides, diagrams, documents) via cogni-visual and document-skills → `exports/*.pptx` (PPTX/DOCX/XLSX deliverables)

## What it means for you

- **Run Big-5 engagements with a boutique team.** A structured methodology coordinating 6 plugins means a full strategic options analysis — research, trend synthesis, portfolio modeling, verified deliverables — that would take a 4-person team 3-4 weeks completes in days.
- **Resume — or refine — any engagement with full context.** Engagement state, 40+ decisions, and method selections persist in `consulting-project.json`. Pick up weeks later without re-reading notes, or re-enter a completed phase to refine it — the Diamond Coach reads your existing artifacts and focuses the iteration on what you want to improve.
- **Phase gates protect quality, Diamond Coach explains why.** Each diamond transition blocks by default when required inputs are missing or inadequate — checking content quality, not just file existence. The Diamond Coach opens every phase with its intent and what good looks like, guides you through a task list, and closes with an accomplishment summary. You can override any gate explicitly when you're ready to proceed.

## Install

Install insight-wave via Claude Code desktop:

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

## Quick start

```
/consulting-setup         # frame the vision and scaffold the engagement
/consulting-discover      # D1 diverge: research, trends, competitive baseline
/consulting-define        # D1 converge: assumption verification, problem synthesis
/consulting-develop       # D2 diverge: option generation, proposition modeling
/consulting-deliver       # D2 converge: business case, roadmap, final verification
/consulting-export        # generate the deliverable package
```

Or just describe what you need in natural language:

- "I need to evaluate strategic options for expanding our cloud portfolio in the DACH market"
- "where are we on the Acme engagement?"
- "let's move to the Define phase — I think we have enough research"
- "generate the final deliverable package as slides and a Word doc"

## Try it

After installing, type one prompt:

> I need to evaluate strategic options for expanding our cloud services portfolio in the DACH mid-market

Claude frames the vision as a `strategic-options` engagement, scaffolds the project, and guides you through Discover — launching research, trend scouting, and competitive analysis in parallel.

## Data model

Engagement state with phase tracking, method selection, and decision audit trail:

| Entity | Key fields | Description |
|--------|-----------|-------------|
| `consulting-project.json` | slug, vision_class, phase_state, engagement_weight, plugin_refs | Engagement config and phase state machine: `pending` → `in-progress` → `complete` (→ `in-progress` for iteration re-entry). Each phase tracks `iteration_count`. |
| `execution-log.json` | transitions[] | Phase transition timestamps and triggers |
| `method-log.json` | phases.{phase}.proposed/selected | Methods proposed by phase-analyst and selected by consultant |
| `decision-log.json` | decisions[] | Key decisions with rationale and evidence references |

See [references/data-model.md](references/data-model.md) for the full schema.

## How it works

Each engagement lives in `cogni-consulting/{slug}/` with phase output directories (discover/, define/, develop/, deliver/) and a final output/ package. The **phase-analyst** agent assesses readiness at each gate and recommends methods from a 16-method library. Plugin refs in `consulting-project.json` store paths to projects created by other plugins — no data is copied, only referenced.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `consulting-setup` | skill | Initialize a new Double Diamond consulting engagement with vision framing and project scaffolding. |
| `consulting-discover` | skill | Execute the Discover phase of a Double Diamond engagement — diverge to build a rich understanding of the problem landscape. |
| `consulting-define` | skill | Execute the Define phase of a Double Diamond engagement — converge from discovery insights to a clear problem statement. |
| `consulting-develop` | skill | Execute the Develop phase of a Double Diamond engagement — diverge to generate and explore solution options. |
| `consulting-deliver` | skill | Execute the Deliver phase of a Double Diamond engagement — converge on validated, actionable outcomes. |
| `consulting-resume` | skill | Resume, continue, or check status of a Double Diamond consulting engagement. |
| `consulting-export` | skill | Generate the final deliverable package for a Double Diamond engagement. |
| `phase-analyst` | agent | Analyze diamond engagement state and assess phase readiness. |
| `phase-gate-guard` | hook (PreToolUse) | Warns if consulting phase prerequisites are incomplete before allowing phase skills to execute. |

## Architecture

```
cogni-consulting/
├── .claude-plugin/
│   └── plugin.json               Plugin manifest
├── skills/                       7 engagement skills
│   ├── consulting-setup/
│   ├── consulting-discover/
│   ├── consulting-define/
│   ├── consulting-define-workspace/ Dev workspace (evals, iterations — not a skill)
│   ├── consulting-develop/
│   ├── consulting-deliver/
│   ├── consulting-resume/
│   └── consulting-export/
├── agents/
│   └── phase-analyst.md          Phase readiness assessment and method recommendation
├── hooks/
│   ├── hooks.json
│   └── phase-gate-guard.sh       Phase gate enforcement
├── references/                   Method library, vision classes, and data model
│   ├── data-model.md
│   ├── diamond-coach.md
│   ├── vision-classes.md
│   ├── vision-class-summary.md
│   ├── deliverable-map.md
│   ├── canvas-format.md
│   ├── lean-canvas-sections.md
│   ├── persona-schema.md
│   ├── methods/                  16 consulting methods
│   │   ├── affinity-clustering.md
│   │   ├── assumption-mapping.md
│   │   ├── business-case-canvas.md
│   │   ├── customer-journey-analysis.md
│   │   ├── data-audit.md
│   │   ├── desk-research-framing.md
│   │   ├── empathy-mapping.md
│   │   ├── guided-ideation.md
│   │   ├── hmw-synthesis.md
│   │   ├── lean-canvas-authoring.md
│   │   ├── lean-canvas-refinement.md
│   │   ├── lean-canvas-stress-test.md
│   │   ├── lean-canvas-synthesis-protocol.md
│   │   ├── opportunity-scoring.md
│   │   ├── scenario-planning.md
│   │   └── stakeholder-mapping.md
│   └── personas/                 Stress-test persona library
│       └── canvas/               Lean Canvas stress-test personas
│           ├── investor.md
│           ├── operations-finance.md
│           ├── target-customer.md
│           └── technical-cofounder.md
└── scripts/                      Engagement management scripts
    ├── engagement-init.sh
    ├── engagement-status.sh
    └── update-phase.sh
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-research | No | Desk research during Discover phase |
| cogni-trends | No | Trend scouting (Discover) and value modeling (Develop) |
| cogni-portfolio | No | Competitive baseline (Discover), proposition modeling (Develop), verification (Deliver) |
| cogni-claims | No | Assumption verification (Define) and final quality gate (Deliver) |
| cogni-visual | No | Slide decks and diagrams during Export |
| cogni-workspace | No | Branded theming in `consulting-export` — applies active theme to all deliverable outputs |
| document-skills | No | PPTX, DOCX, XLSX formatting during Export |

cogni-consulting is standalone as an orchestrator — it provides value even without other plugins by structuring the engagement methodology. Each plugin integration adds depth to the corresponding phase.

## Contributing

Contributions welcome — consulting methods, vision classes, deliverable templates, and documentation. See the [insight-wave contribution guide](https://github.com/cogni-work/insight-wave/blob/main/CONTRIBUTING.md) for guidelines.

## Custom development

Need a custom engagement methodology, additional vision classes, or integration with your internal project management tools? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
