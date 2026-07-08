# cogni-consult

> **Preview** (v0.x) — core skills defined but may change. Feedback welcome.

> **insight-wave readiness (Claude Code desktop)** — Claude Code desktop is the recommended interface for insight-wave today. Cowork is a secondary path and is not yet production-ready for insight-wave workflows because of context-window and Pencil-MCP fidelity gaps — see the [deployment guide](../docs/deployment-guide.md) for detail. This guidance will flip when those gaps close upstream.

> **Start here.** Run `/cogni-consult:consult-resume` for engagement status and the next recommended action, or `/cogni-consult:consult-setup` to start a new engagement.

A [Claude Code](https://claude.com/claude-code) / [Claude Cowork](https://claude.ai) consulting orchestrator where action fields are the work-breakdown-structure and each deliverable runs its own design-thinking loop on one shared cogni-knowledge base.

## Why this exists

| Problem | What happens | Impact |
|---|---|---|
| Engagement work is organized by fixed process phases | Deliverables wait on phase gates even when they could move on their own | Ready work stalls behind unrelated deliverables; the engagement runs at the speed of its slowest phase |
| One design-thinking pass covers the whole engagement | Every deliverable is flattened into the same rhythm regardless of its shape | Simple deliverables are over-processed and complex ones under-explored |
| Stakeholder perspectives live in a slide nobody reads | Deliverables ship without being challenged in the buyer's or PM's voice | Blind spots surface late — in front of the client, not before |
| Research is a throwaway per-question web search | Each question starts from zero and earlier findings evaporate | Effort is repeated and later deliverables can't build on earlier syntheses |

A consulting engagement managed as one rigid phase pipeline runs at the pace of its slowest gate, flattens deliverables into a single rhythm, and re-researches what it already knew — the engagement costs more hours and ships its blind spots to the client instead of catching them first.

## What it is

A consulting engagement orchestrator that treats action fields as the work-breakdown-structure, design thinking as a per-deliverable loop, and one cogni-knowledge base as the shared research spine. It is an orchestrator, not a producer — it manages engagement state and dispatches content work to the plugins that own it. It was selected over an alternative approach in a side-by-side dogfood evaluation (record: [docs/contributing/cogni-consult-evaluation.md](../docs/contributing/cogni-consult-evaluation.md)).

## What it does

1. **Scaffold an engagement** — directory skeleton, cogni-knowledge base binding, and cross-session registry (`consult-setup`)
2. **Scope the engagement** — frame the SMART key question, work the five scoping dimensions, derive 3-6 action fields as the WBS (`consult-scope`)
3. **Manage the WBS** — per-field deliverable manifests, a fields × deliverables dashboard, next-deliverable recommendations, add/split/merge fields (`consult-action-fields`)
4. **Produce deliverables** — run the empathize→define→ideate→prototype→test loop on one deliverable at a time, with evidence from the bound knowledge base (`consult-design-thinking`)
5. **Seed and challenge with acting personas** — seed stakeholder personas from the scope *before* the first deliverable starts (the `personas_gate`), enrich them with evidence, and have them push back on deliverables in their own voice; when there are no external stakeholders worth modelling, take the defaults-only waiver instead (`consult-personas`)
6. **Resume across sessions** — discover engagements, show WBS progress, and route to the most valuable next action (`consult-resume`)
7. **See engagement status visually** — generate a themed, browsable HTML dashboard of the action-field WBS, deliverable states, design-thinking stages, and persona-review progress (`consult-dashboard`)

## What it means for you

- **Compound your research instead of repeating it.** Every deliverable's evidence lands in one refinable cogni-knowledge base, so the tenth deliverable starts from what the first nine already found instead of re-running the same searches.
- **Move ready work without waiting on a phase gate.** Deliverable-level state across the engagement's 3-6 action fields shows what is mid-loop, what awaits persona review, and what to pick up next — no deliverable stalls behind an unrelated one.
- **Catch objections while change is cheap.** Acting personas are seeded from the scope before the first deliverable begins — a gate, not an afterthought — then push back on each deliverable in their own voice, surfacing concerns that otherwise land at the final readout. No external stakeholders to model? A one-step defaults-only waiver clears the gate.
- **Resume across sessions without re-briefing.** `consult-resume` rebuilds engagement status and routes to the next action, so a multi-week engagement never loses its thread between sessions.

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

## Try it

Scaffold an engagement and bind its knowledge base:

> Run `/cogni-consult:consult-setup`

This writes `cogni-consult/{slug}/consult-project.json` and the engagement skeleton. Then frame the key question and derive the work-breakdown-structure:

> Run `/cogni-consult:consult-scope`

You get 3-6 action fields, each with its own `action-fields/{field-slug}/field.json`. Pick a deliverable and run its design-thinking loop:

> Run `/cogni-consult:consult-design-thinking`

The deliverable artifact lands at `action-fields/{field-slug}/{deliverable-slug}.md` with `sources[]` lineage and its state advanced in `field.json`. Coming back later? Re-enter from the top:

> Run `/cogni-consult:consult-resume`

You'll see the WBS dashboard — every field, every deliverable's state and design-thinking stage — and the single next action to take.

When a deliverable is complete, publish it into a presentation-ready brief:

> Run `/cogni-consult:consult-publish`

You elect a format — `slides`, `web-poster`, `report`, or `infographic` — and get a brief written alongside the deliverable. Hand that brief to Claude Design (claude.ai/design) to render it in your own design system. Publishing is consultant-elected and never fires on its own.

## Data model

| Entity | Lives in | Owns |
|---|---|---|
| Engagement | `cogni-consult/{slug}/consult-project.json` | Key question, action-field slug list, `workflow_state.scope`, `plugin_refs.knowledge_base`, language |
| Action field | `action-fields/{field-slug}/field.json` | The field's deliverable states — single source of truth (`state`, `dt_stage`, `producing_route`, `persona_review`) |
| Deliverable artifact | `action-fields/{field-slug}/{deliverable-slug}.md` | Markdown + YAML frontmatter with `sources[]` lineage triples (`kb_ref` for knowledge-base claims) |
| Research synthesis | `action-fields/{field-slug}/research/{topic-slug}.md` | Finalized cogni-knowledge syntheses copied per the Research Routing Rule |
| Persona | `personas/{persona-slug}.json` | Acting stakeholder persona (role, core tension, empathy map, work log) |
| Source inbox | `sources/` | Documented drop location for raw consultant-supplied material (LOI, specs, transcripts); the Empathize stage ingests it into the bound base or reads it into a deliverable's `sources[]` |
| Logs | `.metadata/` | Execution, method, and decision logs addressed by field + deliverable |

Field and engagement completion are derived at read time — never stored. Full schemas: `references/data-model.md`.

## How it works

Setup comes first because everything downstream is path-addressed against the engagement skeleton it writes, and the knowledge base it binds is the spine every later research run reaches. Scoping then converts one SMART key question into 3-6 action fields — the work-breakdown-structure — so the rest of the engagement is organized by *what the work is about*, not by which process phase it sits in.

```
consult-setup ─→ consult-scope ─→ consult-personas ─→ consult-action-fields ─→ consult-design-thinking
 (scaffold +      (key question +   (seed from scope:       (plan deliverable       (empathize→define→ideate
  kb binding)      5 dimensions +    personas_gate, or       sets, pick next)         →prototype→test; the
                   3-6 action        defaults-only waiver          │                  seeded personas challenge
                   fields)           — gates deliverable 1)        │                  each draft in their voice)
                                                                   ▼
                                                            consult-resume
                                                            (re-entry: dashboard + next
                                                             action; routes to persona-
                                                             seeding before deliverable 1)

cogni-knowledge (bound once at setup) ←── every research run, per references/research-routing.md
```

Acting personas gate the first deliverable: before design thinking starts, personas are seeded from the scope (or the defaults-only waiver is taken) so the stakeholder voices that will challenge the work are in place from the outset — `consult-design-thinking` hard-blocks a not-started deliverable and `consult-resume` routes to persona-seeding first until the `personas_gate` is satisfied. Each deliverable then runs its own empathize→define→ideate→prototype→test loop on its own clock — a field completes when its deliverables do, and the engagement completes by derivation rather than by a global gate. That is why ready work never blocks: deliverable state lives in each `field.json`, and completion is computed at read time, never stored. The seeded personas push back on each draft in their own voice while it is still cheap to change.

Research never goes to raw web search: the engagement's bound knowledge base serves quick gap-checks (`knowledge-query`), full inverted-pipeline runs for new topics, and `--source wiki` re-runs on covered topics — with finalized syntheses copied to the owning action field's `research/` directory. Routing every run through one base is what lets later deliverables build on earlier findings instead of paying to rediscover them.

The plugin also ships a **Strategy Advisor output style** that turns Claude Code into an executive advisor rather than a coder — answer-first (Pyramid Principle), hypothesis-driven, MECE options with explicit tradeoffs, and a fluff-free compression discipline (DE/EN). Enable it from the `/config` output-style picker once cogni-consult is installed; it is opt-in (never auto-applied) and fixed at session start, so switching styles mid-engagement needs `/clear` or a new session.

## Publishing deliverables

A deliverable is finished when its design-thinking loop closes — but a finished markdown artifact is not yet something you put in front of a client. `consult-publish` turns a completed deliverable into a **presentation-ready brief**: the consultant elects one of four formats — `slides`, `web-poster`, `report`, or `infographic` — and the skill builds the matching brief. Slides and web-poster derive a consult-native outline straight from the deliverable's framework structure (Pyramid / SCQA / MECE); report routes through `cogni-visual:enrich-report` and infographic through `cogni-visual:story-to-infographic`, with an optional `cogni-copywriting` pass to polish the voice first. The canonical format-to-route contract lives in `references/publish-routing.md`.

Publishing is **consultant-elected and never automatic** — it does not fire at the end of a deliverable's loop, only when you ask for it. Every route terminates in a brief file, and that brief's path *is* the handoff: it is recorded in the deliverable's `publish[]` lineage as a path reference (never copied into engagement state), so a correction upstream stays visible downstream. The consultant takes the brief to **Claude Design (claude.ai/design)** and renders it in their own design system — cogni-consult produces the brief, Claude Design produces the rendered artifact; rendering and brand are out of plugin scope. The step degrades gracefully: when `cogni-visual` is absent the report/infographic routes fall back to a consult-native outline, and when `cogni-copywriting` is absent the polish step is skipped — either way the run completes with a valid brief.

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
| `consult-framework-adherence-reviewer` | Agent | Score a completed deliverable against its stored `chosen_framework` and report structural drift (sonnet, read-only) — the framework-adherence rung of the design-thinking Test gate |
| `consult-persona-challenger` | Agent | Challenge a deliverable as one acting stakeholder persona in voice and return a structured objection envelope (sonnet, read-only) — the per-persona fan-out consult-personas merges at the design-thinking Test gate |
| `consult-empathy-mapper` | Agent | Map one acting stakeholder persona's empathize-stage empathy map (thinks/feels/says/does) and extract their needs, returning a structured envelope (sonnet, read-only) — the per-persona fan-out consult-design-thinking merges at the Empathize stage |
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
│   ├── methods/                   Stage methods (scope dimensions, empathy mapping,
│   │                              HMW synthesis, guided ideation)
│   └── orchestration/             DT orchestration contracts (Empathize intake
│                                  + empathy mapping, Test provenance gate +
│                                  adherence review + persona challenge,
│                                  Close KB deposit)
├── agents/                        consult-dashboard-refresher (milestone HTML refresh),
│                                  consult-framework-adherence-reviewer (Test-stage
│                                  framework drift),
│                                  consult-persona-challenger (per-persona Test
│                                  challenge fan-out),
│                                  consult-empathy-mapper (per-persona Empathize
│                                  mapping fan-out)
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

## Custom development

Need a tailored deliverable type, a custom acting persona, or this orchestrator wired into your own engagement stack? [cogni-work.ai](https://cogni-work.ai) builds and maintains bespoke Claude Code automation for consulting teams.

## License

[AGPL-3.0](LICENSE) — see [CONTRIBUTING.md](CONTRIBUTING.md) for contribution terms.

---

Built by [cogni-work](https://cogni-work.ai) — open-source tools for consulting intelligence.
