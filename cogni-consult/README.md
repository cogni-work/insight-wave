# cogni-consult

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-consult:consult-resume` for engagement status and the next recommended action, or `/cogni-consult:consult-setup` to start a new engagement.

Consulting engagement orchestrator for [Claude Code](https://claude.com/claude-code) / [Claude Cowork](https://claude.ai) where **action fields are the work-breakdown-structure containers** for every deliverable: each deliverable runs its own design-thinking loop (empathize→define→ideate→prototype→test), acting stakeholder personas challenge the work in their own voice, and one cogni-knowledge base per engagement is the central research tool that compounds across all deliverables.

## Why this exists

| Problem | What happens | Impact |
|---|---|---|
| Engagement work is organized by fixed process phases | Deliverables wait on phase gates even when they could move on their own | Ready work stalls behind unrelated deliverables; the engagement runs at the speed of its slowest phase |
| One design-thinking pass covers the whole engagement | Every deliverable is flattened into the same rhythm regardless of its shape | Simple deliverables are over-processed and complex ones under-explored |
| Stakeholder perspectives live in a slide nobody reads | Deliverables ship without being challenged in the buyer's or PM's voice | Blind spots surface late — in front of the client, not before |
| Research is a throwaway per-question web search | Each question starts from zero and earlier findings evaporate | Effort is repeated and later deliverables can't build on earlier syntheses |

## What it is

A consulting engagement orchestrator built on three structural bets:

- **Action fields as WBS** — scoping derives 3-6 action fields from one SMART key question; every deliverable lives inside exactly one field, and progress is tracked per deliverable, not per global phase.
- **Design thinking per deliverable** — each deliverable iterates its own loop; fields complete when their deliverables do, and the engagement is complete by derivation.
- **Knowledge base as the research spine** — one cogni-knowledge base is bound once at setup (`plugin_refs.knowledge_base`); all research routes through it per the canonical Research Routing Rule and compounds across the engagement.

It is an orchestrator, not a producer: it manages engagement state and dispatches content work to the plugins that own it. It was selected after a side-by-side dogfood evaluation of two consulting-orchestration approaches; the comparison record lives in [docs/contributing/cogni-consult-evaluation.md](../docs/contributing/cogni-consult-evaluation.md).

## What it does

1. **Scaffold an engagement** — directory skeleton, cogni-knowledge base binding, and cross-session registry (`consult-setup`)
2. **Scope the engagement** — frame the SMART key question, work the five scoping dimensions, derive 3-6 action fields as the WBS (`consult-scope`)
3. **Manage the WBS** — per-field deliverable manifests, a fields × deliverables dashboard, next-deliverable recommendations, add/split/merge fields (`consult-action-fields`)
4. **Produce deliverables** — run the empathize→define→ideate→prototype→test loop on one deliverable at a time, with evidence from the bound knowledge base (`consult-design-thinking`)
5. **Challenge with acting personas** — define stakeholder personas from the scope, enrich them with evidence, and have them push back on deliverables in their own voice (`consult-personas`)
6. **Resume across sessions** — discover engagements, show WBS progress, and route to the most valuable next action (`consult-resume`)
7. **See engagement status visually** — generate a themed, browsable HTML dashboard of the action-field WBS, deliverable states, design-thinking stages, and persona-review progress (`consult-dashboard`)

## What it means for you

- **Research compounds instead of evaporating** — every deliverable's evidence lands in one refinable cogni-knowledge base, so the tenth deliverable starts smarter than the first instead of re-running the same searches
- **Always know the next move** — deliverable-level state across the engagement's 3-6 action fields shows at a glance what is mid-loop, what awaits persona review, and what to pick up next, with no waiting on a global phase gate
- **Catch objections while change is cheap** — acting personas (consulting partner, project manager) push back on each deliverable in their own voice at the prototype stage, surfacing the concerns that usually only land at the final readout
- **Resume across sessions without re-briefing** — `consult-resume` rebuilds engagement status and routes to the most valuable next action, so a multi-week engagement never loses its thread between sessions
- **See the whole engagement at a glance** — `consult-dashboard` renders a themed HTML view of the action-field WBS, deliverable states, design-thinking stages, and persona-review coverage, so progress and stuck deliverables are visible without reading JSON

## Install

- **5-minute walkthrough** — [From Install to Infographic](../docs/workflows/install-to-infographic.md)
- **Full setup reference** — [Claude Code desktop](../docs/claude-code-desktop.md)
- **Enterprise / compliance setup** — [Deployment guide](../docs/deployment-guide.md)

This plugin is part of the [insight-wave ecosystem](../docs/ecosystem-overview.md).

> **Note**: cogni-knowledge is the one required companion — the engagement binds a knowledge base at setup and every research run routes through it.

## Quick start

```
/cogni-consult:consult-resume       # ← entry point: status dashboard + next action
/cogni-consult:consult-setup        # scaffold an engagement + bind the knowledge base
/cogni-consult:consult-scope        # key question, five dimensions, action-field WBS
/cogni-consult:consult-action-fields # plan deliverable sets, pick the next deliverable
/cogni-consult:consult-design-thinking # run the DT loop on one deliverable
/cogni-consult:consult-personas     # define/enrich personas, challenge a deliverable
/cogni-consult:consult-dashboard    # themed HTML engagement status dashboard
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

The plugin also ships a **Strategy Advisor output style** that turns Claude Code into an executive advisor rather than a coder — answer-first (Pyramid Principle), hypothesis-driven, MECE options with explicit tradeoffs, and a fluff-free compression discipline (DE/EN). Enable it from the `/config` output-style picker once cogni-consult is installed; it is opt-in (never auto-applied) and fixed at session start, so switching styles mid-engagement needs `/clear` or a new session.

## Components

| Component | Type | Description |
|---|---|---|
| `consult-resume` | Skill | Cross-session re-entry point: engagement discovery, WBS dashboard, workflow-state next-action routing |
| `consult-setup` | Skill | New-engagement scaffolding: directory skeleton, cogni-knowledge base binding, global registry |
| `consult-scope` | Skill | SMART key question + five scoping dimensions + 3-6 action fields as the WBS |
| `consult-action-fields` | Skill | WBS dashboard, per-field deliverable manifests, next-deliverable recommendation, add/split/merge |
| `consult-design-thinking` | Skill | Per-deliverable design-thinking loop with artifact + state writes |
| `consult-personas` | Skill | Acting personas: define from scope, enrich with evidence, act-as challenge against deliverables |
| `consult-dashboard` | Skill | Themed HTML engagement dashboard: action-field WBS, deliverable state, design-thinking stage, persona-review progress |
| `consult-dashboard-refresher` | Agent | Regenerate the engagement dashboard HTML at a milestone (haiku, read-only, no theme prompt) |
| `engagement-init.sh` | Script | Create the engagement directory skeleton + `consult-project.json` |
| `engagement-status.sh` | Script | Derive field/deliverable rollups from `field.json` files → JSON |
| `discover-projects.sh` | Script | Engagement discovery (delegates to the cogni-workspace helper) |
| `consult-dashboard/scripts/generate-dashboard.py` | Script | Render the engagement HTML dashboard from `consult-project.json` + `field.json` files (read-only) |

## Architecture

```
cogni-consult/
├── .claude-plugin/plugin.json     Plugin manifest (v0.x, Preview)
├── CLAUDE.md                      Developer guide
├── README.md                      This file
├── references/
│   ├── data-model.md              Engagement structure + entity schemas
│   ├── deliverable-types.md       Deliverable-type catalog (field-type affinity)
│   ├── evaluation-criteria.md     Six criteria from the dogfood replacement evaluation
│   ├── persona-schema.md          Acting-persona schema + acting contract
│   ├── research-routing.md        Canonical cogni-knowledge research rule
│   ├── personas/                  Packaged default advisors (partner, PM)
│   └── methods/                   Stage methods (scope dimensions, empathy mapping,
│                                  HMW synthesis, guided ideation)
├── agents/                        consult-dashboard-refresher (milestone HTML refresh)
├── scripts/                       Engagement init/status/discovery (stdlib-only)
└── skills/                        The seven skills listed under Components
                                   (consult-dashboard bundles its generator + theme schema)
```

## Dependencies

| Plugin | Required | Purpose |
|--------|----------|---------|
| cogni-knowledge | Yes | Bound once at setup (`plugin_refs.knowledge_base`) — the research spine every deliverable's evidence routes through |
| cogni-workspace | No | Cross-session engagement discovery (`discover-projects.sh` delegates to its helper); `pick-theme` themes the `consult-dashboard` HTML (falls back to a built-in theme) |
| cogni-visual / document-skills | No | Deliverable export (slides, documents) when a deliverable names an export route |

cogni-consult is standalone as an orchestrator — it structures the engagement, the WBS, and the design-thinking loops on its own. cogni-knowledge is the one required integration: without it, deliverable research has no compounding base.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
