# cogni-consulting Development Guide

## Identity

cogni-consulting is a Double Diamond consulting orchestrator for the cogni-works ecosystem. It manages engagement state and steers the consulting process through four phases (Discover, Define, Develop, Deliver), dispatching to existing plugins rather than producing content itself.

## Architecture

```
consulting-setup skill       → Vision framing, engagement scaffolding
consulting-discover skill    → D1 diverge: cogni-gpt-researcher, cogni-tips, cogni-portfolio
consulting-define skill      → D1 converge: cogni-claims, guided synthesis
consulting-develop skill     → D2 diverge: cogni-tips value-modeler, cogni-portfolio propositions
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
| Discover | cogni-gpt-researcher | research-report |
| Discover | cogni-tips | trend-scout |
| Discover | cogni-portfolio | portfolio-scan, compete |
| Define | cogni-claims | claims (verify mode) |
| Develop | cogni-tips | value-modeler |
| Develop | cogni-portfolio | propositions, solutions |
| Deliver | cogni-claims | claims (verify mode) |
| Deliver | cogni-portfolio | portfolio-verify |
| Export | cogni-visual | story-to-slides, story-to-big-picture |

## Vision Classes

7 engagement types: strategic-options, business-case, gtm-roadmap, cost-optimization, digital-transformation, innovation-portfolio, market-entry. Each maps to recommended methods and deliverables via `references/vision-classes.md` and `references/deliverable-map.md`.

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
