# cogni-consult Development Guide

## Identity

cogni-consult is a consulting engagement orchestrator for the insight-wave ecosystem built on three structural bets: **action fields are the work-breakdown-structure containers** for every deliverable (no fixed phase folders), **each deliverable runs its own design-thinking loop** (empathize→define→ideate→prototype→test), and **cogni-knowledge is the central research tool** bound once per engagement and compounding across all deliverables. It is the evaluation candidate alongside cogni-consulting (Double Diamond), which stays untouched during the comparison.

## Architecture

```
cogni-consult/
├── .claude-plugin/plugin.json     Plugin manifest (v0.0.x, Incubating)
├── CLAUDE.md                      This developer guide
├── README.md                      User documentation (stub; full README is planned work)
├── references/
│   ├── data-model.md              Engagement structure + entity schemas
│   └── methods/
│       └── scope-dimensions.md    SMART key question + 5 dimensions + WBS-close method
├── scripts/
│   ├── engagement-init.sh         Create engagement directory skeleton
│   ├── engagement-status.sh       Read consult-project.json state → JSON
│   ├── discover-projects.sh       Thin wrapper over the cogni-workspace discovery helper
│   └── _discover_extractor.py     Per-engagement field extractor for the wrapper
└── skills/
    ├── consult-setup/SKILL.md     Engagement entry point: scaffold + knowledge-base bind
    │                              + registry
    └── consult-scope/SKILL.md     SMART key question + 5 scoping dimensions
                                   + 3-6 action fields as the WBS
```

Later work: consult-action-fields, consult-design-thinking, consult-personas, consult-resume skills.

## Design Principles

- **Action fields as WBS** — scoping derives 3-6 action fields from the key question; every deliverable lives inside exactly one field. Progress is tracked per deliverable, not per global phase
- **Design thinking per deliverable** — each deliverable iterates empathize→define→ideate→prototype→test on its own clock; fields complete when their deliverables do
- **Acting personas** — stakeholder personas (shipped defaults: engagement partner, project manager) actively challenge deliverable work in their voice, not just describe users
- **Knowledge base as the research spine** — one cogni-knowledge base bound at setup (`plugin_refs.knowledge_base`); all deliverable research runs through it and compounds
- **Orchestrator, not producer** — manages engagement state; content work dispatches to existing plugins
- **Path references, not data copies** — cross-references via slugs/paths, no shared DB

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
- cogni-consulting remains untouched during the evaluation; the two plugins never share engagement directories
