# cogni-diamond

A [Claude Cowork](https://claude.ai/cowork) plugin that orchestrates consulting engagements through the Double Diamond framework — diverge to explore, converge to decide, twice.

## Why this exists

Consulting engagements often stall in either analysis paralysis (endless research, no decisions) or premature convergence (jumping to solutions before understanding the problem). The Double Diamond provides structure — but without tooling, it's just a poster on the wall:

| Problem | What happens | Impact |
|---------|-------------|--------|
| No structured methodology | Consultants improvise engagement flow, skip phases, or mix divergent and convergent work | Deliverables lack rigor; clients question the process |
| Manual plugin coordination | Research, trend scouting, portfolio analysis, and claims verification run as disconnected tasks | Context lost between phases; insights don't compound |
| No engagement state | Multi-session consulting work has no persistent record of what phase you're in, what's been decided, or why | Teams restart conversations; decisions get revisited without new evidence |

## What it is

A process orchestrator for the cogni-works ecosystem. cogni-diamond doesn't produce content itself — it manages engagement state and dispatches to existing plugins (cogni-gpt-researcher, cogni-tips, cogni-portfolio, cogni-claims, cogni-visual) at the right phase. Think of it as the senior partner who runs the engagement while specialists do the analysis.

## What it does

1. **Frame the vision** — define the desired outcome class (strategic options, business case, GTM roadmap, etc.) and engagement scope
2. **Discover** (D1 diverge) — launch desk research, trend scouting, and competitive baseline via cogni-gpt-researcher, cogni-tips, and cogni-portfolio
3. **Define** (D1 converge) — verify assumptions via cogni-claims, cluster findings, synthesize the core problem statement
4. **Develop** (D2 diverge) — generate solution options via cogni-tips value-modeler and cogni-portfolio proposition modeling
5. **Deliver** (D2 converge) — score opportunities, verify final claims, construct business case and roadmap
6. **Export** — generate the deliverable package (slides, diagrams, documents) via cogni-visual and document-skills

## What it means for you

- **Compete on Big-5 complexity with a boutique team.** A structured engagement methodology that coordinates 6 plugins means you can run a full strategic options analysis — from research through deliverables — without the headcount.
- **Never lose context between sessions.** Engagement state, decisions, and method selections persist in `diamond-project.json`. Resume any engagement weeks later with full continuity.
- **Stay in control.** Phase gates are advisory — the plugin recommends when a phase is ready to close, but you decide. Your consulting judgment drives the process, not a rigid checklist.

## Installation

This plugin is part of the [cogni-works monorepo](https://github.com/cogni-work/cogni-works) and is installed automatically with the marketplace.

## Quick start

```
diamond-setup                              # frame the vision and scaffold the engagement
diamond-discover                           # D1 diverge: research, trends, competitive baseline
diamond-define                             # D1 converge: assumption verification, problem synthesis
diamond-develop                            # D2 diverge: option generation, proposition modeling
diamond-deliver                            # D2 converge: business case, roadmap, final verification
diamond-export                             # generate the deliverable package
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
| `diamond-project.json` | slug, vision_class, phase_state, plugin_refs | Engagement config and phase state machine: `pending` → `in-progress` → `complete` |
| `execution-log.json` | transitions[] | Phase transition timestamps and triggers |
| `method-log.json` | phases.{phase}.proposed/selected | Methods proposed by phase-analyst and selected by consultant |
| `decision-log.json` | decisions[] | Key decisions with rationale and evidence references |

See [references/data-model.md](references/data-model.md) for the full schema.

## How it works

Each engagement lives in `cogni-diamond/{slug}/` with phase output directories (discover/, define/, develop/, deliver/) and a final output/ package. The **phase-analyst** agent assesses readiness at each gate and recommends methods from a 10-method library. Plugin refs in `diamond-project.json` store paths to projects created by other plugins — no data is copied, only referenced.

## Components

| Component | Type | What it does |
|-----------|------|--------------|
| `diamond-setup` | skill | Vision framing and engagement scaffolding |
| `diamond-discover` | skill | D1 diverge: dispatches research, trends, competitive baseline |
| `diamond-define` | skill | D1 converge: assumption verification, problem statement synthesis |
| `diamond-develop` | skill | D2 diverge: option generation, proposition modeling |
| `diamond-deliver` | skill | D2 converge: opportunity scoring, business case, roadmap |
| `diamond-resume` | skill | Multi-session re-entry and status dashboard |
| `diamond-export` | skill | Final deliverable package generation |
| `phase-analyst` | agent | Phase readiness assessment and method recommendation |

## Architecture

```
cogni-diamond/
├── .claude-plugin/plugin.json    Plugin manifest
├── skills/                       7 engagement skills
│   ├── diamond-setup/
│   ├── diamond-discover/
│   ├── diamond-define/
│   ├── diamond-develop/
│   ├── diamond-deliver/
│   ├── diamond-resume/
│   └── diamond-export/
├── agents/                       1 advisory agent
│   └── phase-analyst.md
├── hooks/                        Phase gate enforcement
│   ├── hooks.json
│   └── phase-gate-guard.sh
├── references/                   Method library and vision classes
│   ├── data-model.md
│   ├── vision-classes.md
│   ├── vision-class-summary.md
│   ├── deliverable-map.md
│   └── methods/                  10 consulting methods
└── scripts/                      3 engagement management scripts
    ├── engagement-init.sh
    ├── engagement-status.sh
    └── update-phase.sh
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-gpt-researcher | No | Desk research during Discover phase |
| cogni-tips | No | Trend scouting (Discover) and value modeling (Develop) |
| cogni-portfolio | No | Competitive baseline (Discover), proposition modeling (Develop), verification (Deliver) |
| cogni-claims | No | Assumption verification (Define) and final quality gate (Deliver) |
| cogni-visual | No | Slide decks and diagrams during Export |
| document-skills | No | PPTX, DOCX, XLSX formatting during Export |

cogni-diamond is standalone as an orchestrator — it provides value even without other plugins by structuring the engagement methodology. Each plugin integration adds depth to the corresponding phase.

## Custom development

Need a custom engagement methodology, additional vision classes, or integration with your internal project management tools? Contact [stephan@cogni-work.ai](mailto:stephan@cogni-work.ai).

## License

[AGPL-3.0](LICENSE)
