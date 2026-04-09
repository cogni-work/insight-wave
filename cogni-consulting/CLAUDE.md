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

- **Diamond Coach** — every phase opens with a coaching introduction (intent + what good looks like), checks prerequisites, creates a task list, and closes with an accomplishment summary. The coach is defined in `references/diamond-coach.md` and calibrated to engagement weight (brief for lightweight HMW, structured for full engagements)
- **Orchestrator, not producer** — manages engagement state; content work done by existing plugins
- **Path references, not data copies** — cross-references via slugs/paths, no shared DB
- **Gate, then guide** — phase gates block by default when required inputs are missing or inadequate (not just file existence, but content quality). Consultant can override explicitly. Exception: the Develop proposition quality gate additionally blocks individual propositions
- **Iteration support** — phases can be re-entered after completion. `iteration_count` tracks revisions. Re-entry reads existing artifacts and refines rather than starting from scratch
- **Method library, not fixed playbook** — proposes methods per phase; consultant decides

## Data Model

Each engagement lives in `cogni-consulting/{slug}/` with:
- `consulting-project.json` — engagement config, vision, phase state, plugin refs, persona index
- `.metadata/` — execution-log, method-log, decision-log
- `personas/` — design-for personas (the people we design for, distinct from quality-gate personas)
- `discover/`, `define/`, `develop/`, `deliver/` — phase output directories
- `output/` — final deliverable package

### Design-For Personas vs. Quality-Gate Personas

The plugin uses two kinds of personas:
- **Design-for personas** (`personas/{slug}.json`) represent the people affected by the engagement — created during Setup as hypotheses, enriched in Discover, referenced throughout Define/Develop/Deliver. Schema in `references/persona-schema.md`.
- **Quality-gate personas** (Engagement Sponsor, Solution Architect, End-User Advocate, etc.) evaluate deliverable quality from organizational perspectives. When design-for personas exist, quality-gate personas (especially End-User Advocate and End-User Proxy) cross-reference them to make evaluations concrete.

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
- Phase state tracks: pending → in-progress → complete (→ in-progress for iteration re-entry)
- Each phase has `iteration_count` (default 0, incremented on re-entry)
- `engagement_weight` field (`lightweight`/`medium`/`heavy`/null) set during setup for HMW engagements
- Plugin refs store relative paths to projects created by other plugins
- Methods are stored as markdown files in `references/methods/` with YAML frontmatter
- Language field in consulting-project.json controls communication language (technical terms stay English)
