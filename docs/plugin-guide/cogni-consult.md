# cogni-consult

Consulting engagement orchestrator where action fields are the work-breakdown-structure containers for every deliverable, each deliverable runs its own design-thinking loop, acting personas challenge the work, and one cogni-knowledge base per engagement is the research spine. For canonical positioning see the [README](../../cogni-consult/README.md).

---

## Overview

cogni-consult structures a consulting engagement without fixed process phases. Scoping converges on one SMART key question and derives 3-6 **action fields** — thematic containers that together form the engagement's work-breakdown structure. Every deliverable lives inside exactly one field and walks its own **design-thinking loop** (empathize → define → ideate → prototype → test) at its own pace; a field is complete when its deliverables are, and the engagement is complete by derivation. Nothing waits on a phase gate.

Two further mechanisms keep quality and evidence honest. **Acting personas** — stakeholder profiles such as the shipped consulting-partner and project-manager defaults — challenge each deliverable in their own voice at the test stage, so the partner's objections surface while the artifact is still cheap to change. And **one cogni-knowledge base per engagement**, bound at setup, is the only sanctioned research tool: every evidence run routes through it per the canonical Research Routing Rule, so the tenth deliverable's research builds on the first nine instead of starting cold.

cogni-consult is the **evaluation candidate** alongside cogni-consulting (Double Diamond). The two plugins never share engagement directories, and cogni-consulting stays untouched while the comparison runs.

---

## Key Concepts

| Term | Meaning |
|---|---|
| Key question | One SMART question the whole engagement answers; framed in scoping |
| Scoping dimensions | Five guided lenses — Strategic Context, Scope, Stakeholder, Constraints/Barriers, Success factors |
| Action field | A WBS container derived from the key question; owns a set of deliverables via its `field.json` manifest |
| Deliverable | One artifact inside a field, produced by its own design-thinking loop; state is `pending` → `in-progress` → `complete` |
| `dt_stage` | The deliverable's position in the loop: `empathize` / `define` / `ideate` / `prototype` / `test` |
| Acting persona | A stakeholder profile that actively challenges deliverables in its own voice; tracked per deliverable via `persona_review` |
| Knowledge base | The engagement's bound cogni-knowledge wiki (`plugin_refs.knowledge_base`); all research compounds there |

### Engagement layout

```
cogni-consult/{engagement-slug}/
├── consult-project.json        # config + scope state + plugin refs
├── scope/key-question.md       # key question + dimensions + field list
├── action-fields/{field-slug}/ # field.json + deliverable artifacts + research/
├── personas/{persona-slug}.json
└── .metadata/                  # execution / method / decision logs
```

State ownership is strict: deliverable state lives only in `field.json`; field and engagement completion are derived at read time, never stored.

---

## Getting Started

Say something like:

> "Start a consulting engagement for ACME's DACH cloud portfolio expansion."

1. **`consult-setup`** scaffolds the engagement directory, binds a cogni-knowledge base (one per engagement), and registers the engagement for cross-session discovery.
2. **`consult-scope`** frames the SMART key question, walks the five scoping dimensions, and derives 3-6 action fields — the WBS every later skill works inside.
3. **`consult-action-fields`** plans each field's deliverable set and recommends the next deliverable to work.
4. **`consult-design-thinking`** produces that deliverable through its loop, pulling evidence from the bound knowledge base.
5. **`consult-personas`** lets the partner and PM personas challenge the draft before it counts as complete.
6. In any later session, **`consult-resume`** shows the WBS dashboard and routes to the most valuable next action.

---

## Capabilities

### `consult-setup` — engagement entry point

Scaffolds `cogni-consult/{slug}/` via `engagement-init.sh`, captures the desired outcome and language, dispatches `cogni-knowledge:knowledge-setup` to bind the engagement's knowledge base (recorded in `plugin_refs.knowledge_base`), and registers the engagement in the global discovery registry. Idempotent: an already-initialized engagement routes to `consult-resume` instead of overwriting.

### `consult-scope` — key question, dimensions, WBS

The keystone conversation. Drafts the SMART key question collaboratively, walks Strategic Context, Scope, Stakeholder, Constraints/Barriers, and Success factors, then closes by naming 3-6 action fields (slug, title, one-line framing) persisted as `field.json` stubs. Produces one deliverable: `scope/key-question.md`. Dimension evidence the consultant cannot supply routes through the knowledge base per the Research Routing Rule, landing in `scope/research/`.

### `consult-action-fields` — the WBS manager

Renders the fields × deliverables dashboard from `engagement-status.sh`, plans a field's deliverable set from the deliverable-type catalog (1-3 per field, each with a `producing_route` and `persona_review` tracker), recommends the next deliverable, and handles add/split/merge of fields — always keeping each deliverable in exactly one field. It plans the work; the producing route runs it.

### `consult-design-thinking` — the per-deliverable loop

Walks one deliverable through empathize (persona empathy mapping + knowledge-base recall), define (HMW problem spec, locked as a logged decision), ideate (guided diverge→converge), prototype (the artifact, with `sources[]` lineage on every evidence-backed claim), and test (persona challenges + consultant acceptance). Stages may re-enter earlier stages; `state` stays `in-progress` until test passes. Evidence gaps escalate through the Research Routing Rule — never raw web search.

### `consult-personas` — acting stakeholders

Defines personas from the scope's Stakeholder dimension (or enriches the shipped partner/PM defaults with engagement evidence), and acts as a persona to challenge a deliverable in its voice — objections from its role, core tension, and empathy map, each dispositioned (accepted / revised / rejected with reason) and logged to the persona's `work_log`.

### `consult-resume` — cross-session re-entry

Discovers engagements (registry-backed, works from any directory), renders the action-fields × deliverables × status dashboard, surfaces manifest warnings, and recommends exactly one next action keyed on derived state — scope not done → `consult-scope`; unplanned field → `consult-action-fields`; deliverable mid-loop → `consult-design-thinking`; challenge pass open → `consult-personas`. Read-only: it never writes engagement state.

---

## Integration Points

| Plugin | Direction | What flows |
|---|---|---|
| cogni-knowledge | Orchestrates (required) | One base bound at setup; all research runs through the inverted pipeline / `knowledge-query`; finalized syntheses copied to `action-fields/{field}/research/` |
| cogni-workspace | Consumes | Cross-session engagement discovery via the shared registry helper |
| cogni-claims | Consumes | Deliverable `sources[]` lineage triples let claim corrections cascade into artifacts |
| cogni-visual / document-skills | Orchestrates (optional) | Deliverable export when a deliverable's `producing_route` names an export path |

cogni-consult is standalone as a methodology orchestrator; cogni-knowledge is the one integration it requires to deliver its compounding-research promise.

---

## Common Workflows

**1. New engagement, first deliverable**

1. `consult-setup` → scaffold + bind knowledge base
2. `consult-scope` → key question, dimensions, 3-6 fields
3. `consult-action-fields` → plan the first field's deliverables, pick one
4. `consult-design-thinking` → run the loop to a tested artifact

**2. Multi-session continuation**

1. `consult-resume` → dashboard + one recommended next action
2. Confirm → the named skill picks up with the engagement path handed off in-session (no rediscovery)

**3. Research-heavy deliverable**

1. Empathize surfaces a coverage gap → `knowledge-query` confirms the base is silent
2. Full inverted pipeline runs against the bound base (`--knowledge-slug` from `plugin_refs.knowledge_base`)
3. Finalized synthesis copied to the field's `research/` directory; the artifact cites it via `sources[].kb_ref`

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "There's no engagement yet" on every skill | Setup never ran, or the engagement isn't registered | Run `consult-setup`; for an existing directory, register it via the discovery script's `--register` |
| A field shows `unreadable` in the dashboard | Corrupt or hand-edited `field.json` | Inspect and fix the manifest before routing — the surfaced warning names the file |
| Research recommendations ignore earlier syntheses | Engagement bound to the wrong knowledge slug, or a second base was created | Check `plugin_refs.knowledge_base` in `consult-project.json`; one base per engagement, always |
| Persona challenges feel generic | Personas not yet enriched with engagement evidence | Run `consult-personas` enrichment against the scope and knowledge base first |
| Double Diamond phase language gets routed here | Wrong plugin — phases belong to cogni-consulting | Use `cogni-consulting:consulting-*` skills; the two plugins never share engagements |

---

## Extending This Plugin

- **Deliverable types** — extend `references/deliverable-types.md` with new types and field-type affinities
- **Personas** — add JSON personas under `references/personas/` (schema: `references/persona-schema.md`)
- **Stage methods** — add or refine method references under `references/methods/`
- **Research routing** — the canonical rule lives in `references/research-routing.md`; skills point at it, so extend it there, not per-skill
