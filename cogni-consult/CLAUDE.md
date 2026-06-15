# cogni-consult Development Guide

## Identity

cogni-consult is a consulting engagement orchestrator for the insight-wave ecosystem built on three structural bets: **action fields are the work-breakdown-structure containers** for every deliverable (no fixed phase folders), **each deliverable runs its own design-thinking loop** (empathize→define→ideate→prototype→test), and **cogni-knowledge is the central research tool** bound once per engagement and compounding across all deliverables. It was selected after a side-by-side dogfood evaluation of two consulting-orchestration approaches (record: `docs/contributing/cogni-consult-evaluation.md`).

## Architecture

```
cogni-consult/
├── .claude-plugin/plugin.json     Plugin manifest (v0.x, Preview)
├── CLAUDE.md                      This developer guide
├── README.md                      Plugin documentation
├── references/
│   ├── data-model.md              Engagement structure + entity schemas
│   ├── dependency-model.md        Deliverable dependency graph: edge schema,
│   │                              validation, cascade + topological refresh
│   ├── deliverable-types.md       Deliverable-type catalog (field-type affinity)
│   ├── evaluation-criteria.md     Six criteria from the replacement evaluation,
│   │                              each with a concrete pass signal
│   ├── persona-schema.md          Acting-persona schema + acting contract
│   ├── research-routing.md        Canonical cogni-knowledge research rule (binding,
│   │                              pipeline rungs, depth framing, storage contract)
│   ├── personas/                  Packaged default advisors (consulting-partner,
│   │                              project-manager)
│   └── methods/
│       ├── scope-dimensions.md    SMART key question + 5 dimensions + WBS-close method
│       ├── empathy-mapping.md     Empathize-stage persona quadrant mapping
│       ├── hmw-synthesis.md       Define-stage HMW problem-spec synthesis
│       └── guided-ideation.md     Ideate-stage diverge→converge facilitation
├── output-styles/
│   └── strategy-advisor.md        Executive-advisory voice register (opt-in,
│                                  auto-discovered in the /config picker)
├── agents/
│   └── consult-dashboard-refresher.md  Milestone HTML dashboard refresh (haiku,
│                                  read-only, no theme prompt)
├── scripts/
│   ├── engagement-init.sh         Create engagement directory skeleton
│   ├── engagement-status.sh       Read consult-project.json state → JSON
│   ├── deliverable-graph.py       Deliverable dependency-graph engine: validate /
│   │                              trace / impact / refresh-order / cascade-stale
│   ├── discover-projects.sh       Thin wrapper over the cogni-workspace discovery helper
│   └── _discover_extractor.py     Per-engagement field extractor for the wrapper
└── skills/
    ├── consult-setup/SKILL.md     Engagement entry point: scaffold + knowledge-base bind
    │                              + registry
    ├── consult-scope/SKILL.md     SMART key question + 5 scoping dimensions
    │                              + 3-6 action fields as the WBS
    ├── consult-action-fields/SKILL.md  WBS dashboard + per-field deliverable
    │                              manifests + next-deliverable recommendation
    ├── consult-design-thinking/SKILL.md  Per-deliverable DT loop (empathize→define
    │                              →ideate→prototype→test) + artifact + state writes
    ├── consult-personas/SKILL.md  Acting personas: define from scope, enrich,
    │                              act-as challenge against deliverables
    ├── consult-resume/SKILL.md    Engagement re-entry point: discovery + WBS
    │                              dashboard + workflow-state next-action routing
    └── consult-dashboard/         Themed HTML engagement dashboard (read-only)
        ├── SKILL.md               pick-theme → design-variables → generate → open
        ├── scripts/generate-dashboard.py  Render dashboard.html from project + field.json
        ├── schemas/               design-variables.schema.json (theme contract)
        └── examples/              design-variables example
```

## Design Principles

- **Action fields as WBS** — scoping derives 3-6 action fields from the key question; every deliverable lives inside exactly one field. Progress is tracked per deliverable, not per global phase
- **Design thinking per deliverable** — each deliverable iterates empathize→define→ideate→prototype→test on its own clock; fields complete when their deliverables do
- **Acting personas** — stakeholder personas (shipped defaults: consulting partner, project manager) actively challenge deliverable work in their voice, not just describe users
- **Knowledge base as the research spine** — one cogni-knowledge base bound at setup (`plugin_refs.knowledge_base`); all deliverable research runs through it and compounds
- **Orchestrator, not producer** — manages engagement state; content work dispatches to existing plugins
- **Path references, not data copies** — cross-references via slugs/paths, no shared DB
- **Voice in the output style, phase discipline in the skills** — the always-on executive-advisory *voice* lives in the `output-styles/strategy-advisor.md` output style (opt-in, fixed at session start); the diverge/converge *phase discipline* stays in the consult-* skills, which load contextually so they never fire outside an active engagement

## Data Model

Each engagement lives in `cogni-consult/{slug}/` with:
- `consult-project.json` — engagement config, key question, action-field list, scope state, plugin refs
- `scope/` — key question + 5 scoping dimensions + derived action-field list
- `action-fields/{field-slug}/` — one directory per WBS field: `field.json` (single source of truth for the field's deliverable states) + deliverable markdown artifacts
- `personas/` — acting stakeholder personas (JSON)
- `.metadata/` — execution-log, method-log, decision-log (all addressed by `action_field` + `deliverable`)

Full schemas: `references/data-model.md`.

## Scripts

| Script | Purpose |
|--------|---------|
| `engagement-init.sh` | Create the engagement directory skeleton + consult-project.json |
| `engagement-status.sh` | Read consult-project.json + derive field/deliverable rollups from `field.json` files → JSON |
| `deliverable-graph.py` | Deliverable dependency-graph engine over all `field.json` files: `validate` (cycles + dangling refs), `trace` (upstream lineage), `impact` (downstream blast radius), `refresh-order` (topological layering of stale deliverables), `cascade-stale` (flag downstream `lineage_status` via idempotent RMW). Full model: `references/dependency-model.md` |
| `discover-projects.sh` | Thin wrapper delegating to `cogni-workspace/scripts/discover-plugin-projects.sh` (registry: `$HOME/.claude/cogni-consult-projects.json`) |
| `_discover_extractor.py` | Per-engagement JSON field extractor consumed by the discovery wrapper (reads the flat consult-project.json schema) |

All scripts use JSON output: `{"success": bool, "data": {...}, "error": "string"}`.
All scripts are stdlib-only (bash + python3, no pip dependencies).

## Key Conventions

- Engagement and entity slugs in kebab-case, derived from names
- Workflow state per deliverable: `pending` → `in-progress` → `complete` (→ `in-progress` on iteration re-entry); stored only in `field.json`, field and engagement completion derived at read time
- `dt_stage` tracks the design-thinking stage per deliverable (`empathize`/`define`/`ideate`/`prototype`/`test`)
- Entity outputs are Obsidian-browsable markdown with YAML frontmatter; state files are plain JSON
- `language` field in consult-project.json controls communication language (technical terms stay English)
- **Research routing**: every research run goes through the engagement's bound knowledge base per `references/research-routing.md` — the canonical rule all deliverable-producing skills point at (binding via `plugin_refs.knowledge_base`, pipeline rungs, depth framing, syntheses copied to `action-fields/<field-slug>/research/<topic-slug>.md`); raw WebSearch only for a single trivial fact-check
