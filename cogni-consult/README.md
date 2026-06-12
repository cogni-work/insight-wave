# cogni-consult

> **Incubating** (v0.0.x) — skills, data formats, and workflows may change at any time.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-consult:consult-resume` for engagement status and the next recommended action, or `/cogni-consult:consult-setup` to start a new engagement.

Consulting engagement orchestrator for [Claude Code](https://claude.com/claude-code) / [Claude Cowork](https://claude.ai) where **action fields are the work-breakdown-structure containers** for every deliverable: each deliverable runs its own design-thinking loop (empathize→define→ideate→prototype→test), acting stakeholder personas challenge the work in their own voice, and one cogni-knowledge base per engagement is the central research tool that compounds across all deliverables.

## Why this exists

| Without cogni-consult | With cogni-consult |
|---|---|
| Engagement work is organized by fixed process phases, so deliverables wait on phase gates even when they could move | Action fields are the WBS — each deliverable progresses on its own clock inside its field |
| One design-thinking pass for the whole engagement flattens every deliverable into the same rhythm | Every deliverable runs its own empathize→define→ideate→prototype→test loop, proportionate to its shape |
| Stakeholder perspectives live in a slide nobody reads | Acting personas (shipped defaults: consulting partner, project manager) challenge each deliverable in their own voice before it counts as done |
| Research is a throwaway per-question web search | One cogni-knowledge base bound at setup compounds across all deliverables — later research builds on earlier syntheses |

## What it is

A consulting engagement orchestrator built on three structural bets:

- **Action fields as WBS** — scoping derives 3-6 action fields from one SMART key question; every deliverable lives inside exactly one field, and progress is tracked per deliverable, not per global phase.
- **Design thinking per deliverable** — each deliverable iterates its own loop; fields complete when their deliverables do, and the engagement is complete by derivation.
- **Knowledge base as the research spine** — one cogni-knowledge base is bound once at setup (`plugin_refs.knowledge_base`); all research routes through it per the canonical Research Routing Rule and compounds across the engagement.

It is an orchestrator, not a producer: it manages engagement state and dispatches content work to the plugins that own it. It is also the evaluation candidate alongside cogni-consulting (Double Diamond), which stays untouched during the comparison.

## What it does

1. **Scaffold an engagement** — directory skeleton, cogni-knowledge base binding, and cross-session registry (`consult-setup`)
2. **Scope the engagement** — frame the SMART key question, work the five scoping dimensions, derive 3-6 action fields as the WBS (`consult-scope`)
3. **Manage the WBS** — per-field deliverable manifests, a fields × deliverables dashboard, next-deliverable recommendations, add/split/merge fields (`consult-action-fields`)
4. **Produce deliverables** — run the empathize→define→ideate→prototype→test loop on one deliverable at a time, with evidence from the bound knowledge base (`consult-design-thinking`)
5. **Challenge with acting personas** — define stakeholder personas from the scope, enrich them with evidence, and have them push back on deliverables in their own voice (`consult-personas`)
6. **Resume across sessions** — discover engagements, show WBS progress, and route to the most valuable next action (`consult-resume`)

## What it means for you

- **Research compounds instead of evaporating** — every deliverable's evidence lands in one refinable knowledge base, so the tenth deliverable starts smarter than the first
- **Progress where the work actually is** — deliverable-level state means you always know what is mid-loop, what awaits persona review, and what to pick up next
- **Built-in challenge before delivery** — acting personas surface the partner's and PM's objections while the artifact is still cheap to change
- **A fair comparison** — the plugin exists to be evaluated against cogni-consulting on real engagements; the two never share engagement directories

## Install

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note**: cogni-knowledge is the one required companion — the engagement binds a knowledge base at setup and every research run routes through it.

## Quick start

```
/cogni-consult:consult-setup        # scaffold an engagement + bind the knowledge base
/cogni-consult:consult-scope        # key question, five dimensions, action-field WBS
/cogni-consult:consult-action-fields # plan deliverable sets, pick the next deliverable
/cogni-consult:consult-design-thinking # run the DT loop on one deliverable
/cogni-consult:consult-personas     # define/enrich personas, challenge a deliverable
/cogni-consult:consult-resume       # re-enter: status dashboard + next action
```

Natural language works too: "start a consulting engagement for ACME's DACH cloud expansion", "scope the engagement", "work the competitor-map deliverable", "have the partner persona challenge the draft", "where was I with the engagement?".

## Data model

| Entity | Lives in | Owns |
|---|---|---|
| Engagement | `cogni-consult/{slug}/consult-project.json` | Key question, action-field slug list, `workflow_state.scope`, `plugin_refs.knowledge_base`, language |
| Action field | `action-fields/{field-slug}/field.json` | The field's deliverable states — single source of truth (`state`, `dt_stage`, `producing_route`, `persona_review`) |
| Deliverable artifact | `action-fields/{field-slug}/{deliverable-slug}.md` | Markdown + YAML frontmatter with `sources[]` lineage triples (`kb_ref` for knowledge-base claims) |
| Research synthesis | `action-fields/{field-slug}/research/{topic-slug}.md` | Finalized cogni-knowledge syntheses copied per the Research Routing Rule |
| Persona | `personas/{persona-slug}.json` | Acting stakeholder persona (role, core tension, empathy map, work log) |
| Logs | `.metadata/` | Execution, method, and decision logs addressed by field + deliverable |

Field and engagement completion are derived at read time — never stored. Full schemas: `references/data-model.md`.

## How it works

```
consult-setup ──→ consult-scope ──→ consult-action-fields ──→ consult-design-thinking
 (scaffold +        (key question +     (plan deliverable        (empathize→define→ideate
  kb binding)        5 dimensions +      sets, pick next)          →prototype→test per
                     3-6 action fields)        │                    deliverable)
                                               │                         │
                                               ▼                         ▼
                                        consult-resume  ←──────  consult-personas
                                        (re-entry: dashboard      (acting personas
                                         + next action)            challenge the draft)

cogni-knowledge (bound once at setup) ←── every research run, per references/research-routing.md
```

Research never goes to raw web search: the engagement's bound knowledge base serves quick gap-checks (`knowledge-query`), full inverted-pipeline runs for new topics, and `--source wiki` re-runs on covered topics — with finalized syntheses copied to the owning action field's `research/` directory.

## Components

| Component | Type | Description |
|---|---|---|
| `consult-setup` | Skill | Engagement entry point: scaffold, cogni-knowledge base binding, global registry |
| `consult-scope` | Skill | SMART key question + five scoping dimensions + 3-6 action fields as the WBS |
| `consult-action-fields` | Skill | WBS dashboard, per-field deliverable manifests, next-deliverable recommendation, add/split/merge |
| `consult-design-thinking` | Skill | Per-deliverable design-thinking loop with artifact + state writes |
| `consult-personas` | Skill | Acting personas: define from scope, enrich with evidence, act-as challenge against deliverables |
| `consult-resume` | Skill | Cross-session re-entry: engagement discovery, WBS dashboard, workflow-state next-action routing |
| `engagement-init.sh` | Script | Create the engagement directory skeleton + `consult-project.json` |
| `engagement-status.sh` | Script | Derive field/deliverable rollups from `field.json` files → JSON |
| `discover-projects.sh` | Script | Engagement discovery (delegates to the cogni-workspace helper) |

## Architecture

```
cogni-consult/
├── .claude-plugin/plugin.json     Plugin manifest (v0.0.x, Incubating)
├── CLAUDE.md                      Developer guide
├── README.md                      This file
├── references/
│   ├── data-model.md              Engagement structure + entity schemas
│   ├── deliverable-types.md       Deliverable-type catalog (field-type affinity)
│   ├── evaluation-criteria.md     Six comparison criteria vs cogni-consulting
│   ├── persona-schema.md          Acting-persona schema + acting contract
│   ├── research-routing.md        Canonical cogni-knowledge research rule
│   ├── personas/                  Packaged default advisors (partner, PM)
│   └── methods/                   Stage methods (scope dimensions, empathy mapping,
│                                  HMW synthesis, guided ideation)
├── scripts/                       Engagement init/status/discovery (stdlib-only)
└── skills/                        The six skills listed under Components
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-knowledge | Yes | Bound once at setup (`plugin_refs.knowledge_base`) — the research spine every deliverable's evidence routes through |
| cogni-workspace | No | Cross-session engagement discovery (`discover-projects.sh` delegates to its helper) |
| cogni-visual / document-skills | No | Deliverable export (slides, documents) when a deliverable names an export route |

cogni-consult is standalone as an orchestrator — it structures the engagement, the WBS, and the design-thinking loops on its own. cogni-knowledge is the one required integration: without it, deliverable research has no compounding base.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
