# cogni-consult Data Model Reference

Action fields are the work-breakdown-structure (WBS) containers of an engagement:
every deliverable lives inside exactly one action field, and progress is tracked
per deliverable — not per global phase. This is the core structural difference
from cogni-consulting's fixed phase folders.

## Engagement Structure

```
cogni-consult/{engagement-slug}/
├── consult-project.json                   # Engagement config + scope state + plugin refs
├── .metadata/
│   ├── execution-log.json                 # Workflow-state transitions and timestamps
│   ├── method-log.json                    # Methods proposed and selected per deliverable
│   └── decision-log.json                  # Key decisions with rationale
├── scope/
│   └── key-question.md                    # SMART key question + 5 scoping dimensions
│                                          #   + derived action-field list (3-6 fields)
├── action-fields/
│   └── {field-slug}/                      # One directory per WBS action field
│       ├── field.json                     # Single source of truth for the field's deliverable states
│       └── {deliverable-slug}.md          # Deliverable artifacts (markdown + YAML frontmatter)
└── personas/
    └── {persona-slug}.json                # Acting stakeholder personas (partner, PM, ...)
```

There are no numbered phase directories. The engagement's shape is defined by
its action fields; skills iterate deliverables within fields, each deliverable
running its own design-thinking loop.

## State Ownership (single source of truth)

Deliverable `state` and `dt_stage` live in **exactly one place**:
`action-fields/{field-slug}/field.json`. Field and engagement completion are
**derived at read time** (a field is complete when all its deliverables are;
the engagement is complete when all fields are) — never stored. The engagement
root only stores the `scope` state, because scoping precedes the existence of
any field. This keeps every deliverable transition a one-file write and makes
drift between copies structurally impossible.

The scope transition itself is tracked only via `workflow_state.scope` and the
root `updated` date — it is not logged in `.metadata/execution-log.json`, whose
entries are addressed by `action_field` + `deliverable` (no field exists yet at
scope time).

## Entity Schemas

### consult-project.json (Engagement Root)

Central config file for the engagement. Holds scope, the ordered action-field
list, and cross-plugin project references — not per-deliverable state.

```json
{
  "slug": "dach-cloud-expansion",
  "name": "DACH Cloud Portfolio Expansion",
  "language": "de",
  "key_question": "How can ACME profitably expand its cloud portfolio in the DACH mid-market by 2027?",
  "action_fields": ["market-evidence", "portfolio-fit", "go-to-market"],
  "workflow_state": {
    "scope": "complete"
  },
  "plugin_refs": {
    "knowledge_base": "dach-cloud-expansion"
  },
  "created": "2026-06-11",
  "updated": "2026-06-11"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `slug` | Yes | Kebab-case identifier derived from engagement name |
| `name` | Yes | Human-readable engagement name |
| `language` | No | ISO 639-1 code (default: `en`). Controls communication language; technical terms stay English |
| `key_question` | Yes | The SMART key question framed during scoping |
| `action_fields` | Yes | Ordered list of action-field slugs (3-6); the WBS top level. Field/deliverable state lives in each field's `field.json`, not here |
| `workflow_state` | Yes | `scope` state only: `pending` → `in-progress` → `complete` |
| `plugin_refs` | No | Slugs/relative paths to projects created by other plugins. `plugin_refs.knowledge_base` binds one cogni-knowledge base per engagement — research compounds there across all deliverables |
| `created` | Yes | ISO date of engagement creation |
| `updated` | Yes | ISO date of last modification **of this root file** (scope edits, action-field list changes, plugin-ref binding). Deliverable work never touches it — engagement freshness derives from `.metadata/execution-log.json` timestamps |

### action-fields/{field-slug}/field.json (WBS Field)

One per action field. The single source of truth for the field's deliverables
and their states.

```json
{
  "slug": "market-evidence",
  "title": "Market Evidence",
  "framing": "What does the DACH mid-market actually buy, and from whom?",
  "deliverables": [
    {
      "slug": "market-sizing",
      "title": "Market sizing (TAM/SAM/SOM)",
      "state": "complete",
      "dt_stage": "test",
      "producing_route": "consult-design-thinking",
      "persona_review": "complete"
    },
    {
      "slug": "competitor-landscape",
      "title": "Competitor landscape",
      "state": "in-progress",
      "dt_stage": "ideate",
      "producing_route": "consult-design-thinking",
      "persona_review": "pending"
    }
  ]
}
```

`dt_stage` records where the deliverable stands in its design-thinking loop:
`empathize` → `define` → `ideate` → `prototype` → `test`. The loop may re-enter
earlier stages; `state` stays `in-progress` until `test` passes.

`producing_route` names the skill that produces the deliverable (default:
`consult-design-thinking`); `consult-action-fields` records and recommends the
route, it never dispatches it. `persona_review` tracks the acting-persona
challenge pass per deliverable: `pending` → `in-progress` (challenges start)
→ `complete` (every challenge dispositioned). `consult-action-fields` creates
both fields when the deliverable is planned; skills that run persona
challenges (consult-personas, and consult-design-thinking's test stage)
advance `persona_review` but never create it on an entry that lacks it —
when absent, persona `work_log` entries (and the artifact's challenge
section) are the challenge record. `engagement-status.sh` passes both fields
through unchanged (its rollup reads only `state`).

### Deliverable artifacts ({deliverable-slug}.md)

Obsidian-browsable markdown with YAML frontmatter. State is intentionally
absent from the frontmatter — it lives in `field.json` (see State Ownership).
`sources` entries carry the monorepo's source-lineage triple (plus an optional
knowledge-base page/claim ref) so cogni-claims corrections can cascade to
deliverables:

```markdown
---
slug: market-sizing
action_field: market-evidence
sources:
  - source_url: https://www.destatis.de/...
    entity_ref: cogni-consult/dach-cloud-expansion/action-fields/market-evidence/market-sizing
    propagated_at: 2026-06-11T09:00:00Z
    kb_ref: wiki/sources/destatis-cloud-2026
updated: 2026-06-11
---

# Market sizing (TAM/SAM/SOM)
...
```

### .metadata/ logs

All three logs address work by the same structured coordinates —
`action_field` + `deliverable` (the WBS replacement for cogni-consulting's
`phase` key):

- **execution-log.json** — workflow-state transitions: `{"transitions": [{"action_field": "...", "deliverable": "...", "from": "pending", "to": "in-progress", "timestamp": "...", "triggered_by": "<skill>"}]}`
- **method-log.json** — methods proposed/selected per deliverable: `{"methods": [{"action_field": "...", "deliverable": "...", "proposed": [...], "selected": [...], "rationale": "..."}]}`
- **decision-log.json** — key decisions with rationale and evidence refs: `{"decisions": [{"id": "d-001", "action_field": "...", "deliverable": "...", "decision": "...", "rationale": "...", "evidence_refs": [...], "timestamp": "..."}]}`

### personas/{slug}.json (Acting Stakeholder Personas)

Personas in cogni-consult are **acting** personas: the plugin speaks and
challenges as them during deliverable work (the shipped defaults are a
consulting partner and a project manager, copied from packaged templates in
`references/personas/`; engagements add client-side stakeholders). The schema
extends cogni-consulting's design-for persona shape with a `role` and `voice`
plus optional `capabilities[]` (what the persona can decide/access — grounds
what its challenge can credibly demand) and `wants[]` (desired outcomes —
distinct from `needs[]`, which are unmet requirements); the append-only trail
is a `work_log` addressed by WBS coordinates (not a phase log — this plugin
has no phases). Scope-seeded personas start both new arrays empty at
`hypothesis` maturity; the packaged defaults come pre-populated. Full
schema: `references/persona-schema.md`.

```json
{
  "slug": "consulting-partner",
  "name": "Consulting Partner",
  "role": "challenger",
  "voice": "Pushes for so-what clarity, client value, and commercial defensibility",
  "maturity": "hypothesis",
  "context": "Owns the client relationship and the engagement economics",
  "core_tension": "Wants depth but sells speed",
  "empathy_map": { "thinks": [], "feels": [], "says": [], "does": [] },
  "capabilities": [],
  "wants": [],
  "needs": [],
  "source": "setup-default",
  "work_log": [
    {"action_field": "market-evidence", "deliverable": "market-sizing", "action": "challenged", "date": "2026-06-11"}
  ]
}
```

## Workflow State Machine

Per deliverable (state stored in `field.json` only):

```
pending ──▶ in-progress ──▶ complete
              │                 │
              │                 └──▶ in-progress (iteration re-entry)
              └── (design-thinking loop: empathize→define→ideate→prototype→test)
```

Field and engagement completion are derived at read time from deliverable
states — see State Ownership above.

## Cross-Plugin Integration

| Plugin | Direction | Contract |
|--------|-----------|----------|
| cogni-knowledge | Orchestrates | Binds one knowledge base per engagement (`plugin_refs.knowledge_base`); every deliverable's research runs through the inverted pipeline and compounds in the same base. Deliverable `sources[].kb_ref` points back at knowledge-base pages |
| cogni-claims | Consumes | Deliverable `sources[]` carries the lineage triple (`source_url`, `entity_ref`, `propagated_at`) so claim corrections cascade to deliverables |
| cogni-visual / document-skills | Orchestrates | Deliverable export (slides, docs) from action-field artifacts |

## Conventions

- All slugs kebab-case, derived from names
- Entity outputs are Obsidian-browsable markdown with YAML frontmatter; state files are plain JSON
- Scripts are stdlib-only (bash + python3) and return `{"success": bool, "data": {...}, "error": "string"}`
