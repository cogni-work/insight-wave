# cogni-consulting Development Guide

## Identity

cogni-consulting is a Double Diamond consulting orchestrator for the insight-wave ecosystem. It manages engagement state and steers the consulting process through four phases (Discover, Define, Develop, Deliver), dispatching to existing plugins rather than producing content itself.

## Architecture

```
consulting-setup skill       → Vision framing, engagement scaffolding
consulting-discover skill    → D1 diverge: cogni-research, cogni-trends, cogni-portfolio
consulting-define skill      → D1 converge: cogni-claims, guided synthesis
consulting-develop skill     → D2 diverge: cogni-trends value-modeler, cogni-portfolio propositions
consulting-deliver skill     → D2 converge: cogni-claims, business case, roadmap
consulting-resume skill      → Multi-session re-entry, status dashboard
consulting-export skill      → Deliverable package generation via cogni-visual + document-skills
phase-analyst agent       → Phase readiness assessment, method recommendation
```

## Design Principles

- **Orchestrator, not producer** — manages engagement state; content work done by existing plugins
- **Path references, not data copies** — cross-references via slugs/paths, no shared DB
- **Warn, not block** — phase gates are advisory; consultant can override. Exception: the Develop proposition quality gate (step 4b) blocks by default — propositions that fail on high-weight criteria are excluded from Option Synthesis unless the consultant explicitly reinstates them
- **Method library, not fixed playbook** — proposes methods per phase; consultant decides

## Data Model

Each engagement lives in `cogni-consulting/{slug}/` with:
- `consulting-project.json` — engagement config, vision, phase state, plugin refs
- `.metadata/` — execution-log, method-log, decision-log
- `discover/`, `define/`, `develop/`, `deliver/` — phase output directories
- `output/` — final deliverable package

## Plugin Orchestration

| Phase | Plugin | Skill Invoked |
|-------|--------|---------------|
| Discover | cogni-research | research-report |
| Discover | cogni-trends | trend-scout |
| Discover | cogni-portfolio | portfolio-scan, compete |
| Define | cogni-claims | claims (verify mode) |
| Develop | cogni-trends | value-modeler |
| Develop | cogni-portfolio | propositions, solutions |
| Deliver | cogni-claims | claims (verify mode) |
| Deliver | cogni-portfolio | portfolio-verify |
| Export | cogni-visual | story-to-slides, story-to-big-picture |

## Vision Classes

9 engagement types: strategic-options, business-case, gtm-roadmap, cost-optimization, digital-transformation, innovation-portfolio, market-entry, business-model-hypothesis, how-might-we. Each maps to recommended methods and deliverables via `references/vision-classes.md` and `references/deliverable-map.md`.

The `business-model-hypothesis` class uses Lean Canvas methods (authoring, refinement, stress-test) instead of traditional proposition modeling. Canvas reference materials live in `references/canvas-format.md`, `references/lean-canvas-sections.md`, and stress-test personas in `references/personas/canvas/`.

The `how-might-we` class supports a complexity spectrum from lightweight to heavy. Setup assesses three dimensions (domain knowledge needed, stakeholder complexity, reversibility) to recommend an engagement shape:
- **Lightweight** (workshop, exercise, meeting redesign): Phases collapse — Discover+Define and Develop+Deliver run as two conversations or a single session. No plugin dispatch. Guided ideation. Solution Brief + Action Plan.
- **Medium** (process redesign, training program): Standard 4 phases, lightweight. cogni-research recommended.
- **Heavy** (new product, market strategy, org change): Full 4 phases with cogni-research, cogni-trends, cogni-portfolio. Comparable to other vision classes but with HMW framing.
Each phase skill has a section describing the HMW-specific workflow scaled to complexity.

## Scripts

| Script | Purpose |
|--------|---------|
| `engagement-init.sh` | Create engagement directory structure |
| `engagement-status.sh` | Read consulting-project.json + plugin states → JSON |
| `update-phase.sh` | Transition phase state with validation |

All scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`.
All scripts are stdlib-only (bash + python3, no pip dependencies).

## Key Conventions

- Engagement slug in kebab-case, derived from engagement name
- Phase state tracks: pending → in-progress → complete
- Plugin refs store relative paths to projects created by other plugins
- Methods are stored as markdown files in `references/methods/` with YAML frontmatter
- Language field in consulting-project.json controls communication language (technical terms stay English)
