# cogni-consult Data Model Reference

Action fields are the work-breakdown-structure (WBS) containers of an engagement:
every deliverable lives inside exactly one action field, and progress is tracked
per deliverable — not per global phase. This is the core structural difference
from the legacy phase-folder model.

## Engagement Structure

```
cogni-consult/{engagement-slug}/
├── consult-project.json                   # Engagement config + scope state + plugin refs
├── .metadata/
│   ├── execution-log.json                 # Workflow-state transitions and timestamps
│   ├── method-log.json                    # Methods proposed and selected per deliverable
│   └── decision-log.json                  # Key decisions with rationale
├── scope/
│   ├── key-question.md                    # SMART key question + 5 scoping dimensions
│   │                                      #   + derived action-field list (3-6 fields)
│   └── research/
│       └── {topic-slug}.md                # Scoping-stage research syntheses (see
│                                          #   references/research-routing.md)
├── action-fields/
│   └── {field-slug}/                      # One directory per WBS action field
│       ├── field.json                     # Single source of truth for the field's deliverable states
│       ├── {deliverable-slug}.md          # Deliverable artifacts (markdown + YAML frontmatter)
│       └── research/
│           └── {topic-slug}.md            # Research syntheses copied from the knowledge
│                                          #   base after knowledge-finalize (see
│                                          #   references/research-routing.md)
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

The deliverable dependency graph extends the same discipline. A deliverable's
`depends_on[]` edges are stored on the dependent, but `blocks[]` (the inverse) is
**derived at read time** by inverting `depends_on` across all `field.json` — never
stored, so the two directions cannot drift. The one exception is `lineage_status`:
staleness records a *past upstream-change event* that current state cannot
reconstruct, so it **is** stored. Even then the contract is **flag-not-rewrite** —
`scripts/deliverable-graph.py cascade-stale` only raises the flag on dependents; it
never rewrites a deliverable's `state` or artifact. Reworking a stale deliverable is
human work. Full model: `references/dependency-model.md`.

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
| `language` | No | ISO 639-1 code (default: `en`). The **deliverable/output** language for the engagement's artifacts; technical terms stay English. Not the conversation language — that interaction axis is runtime-derived, never stored (see `references/interaction-language.md`) |
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
      "chosen_framework": "pyramid-principle",
      "persona_review": "complete",
      "evidence_class": "desk-research"
    },
    {
      "slug": "competitor-landscape",
      "title": "Competitor landscape",
      "state": "in-progress",
      "dt_stage": "ideate",
      "producing_route": "consult-design-thinking",
      "chosen_framework": null,
      "persona_review": "pending",
      "depends_on": [
        { "action_field": "market-evidence", "deliverable": "market-sizing" }
      ],
      "lineage_status": null
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

`chosen_framework` (optional, default `null`) records the structuring framework
the deliverable's argument takes — a stable `slug` from
`references/frameworks-registry.md` (e.g. `pyramid-principle`),
`"combo:<slugA>+<slugB>"` for a recommended combination of two, or `null` when
no framework has been chosen yet. It is written once at deliverable creation
(its selection recorded in the decision-log as a `framework-selection` entry,
below) and read-only thereafter. Like `producing_route` and `persona_review`,
it needs no script change to reach read surfaces: `engagement-status.sh` passes
every deliverable field through verbatim (its rollup reads only `state`), so the
stored slug is visible to every consumer that reads the deliverable entry.

`evidence_class` (optional, default `null`) records the provenance class of the
evidence the deliverable rests on — a short free-text classification (e.g.
`"desk-research"`, `"primary-research"`, `"expert-interview"`, `"internal-data"`,
`"first-party"`, `"assumption"`) that makes the deliverable's evidence base machine-checkable
rather than buried in prose. It pairs with the deliverable's provenance record in
the decision-log: at completion the design-thinking loop requires either a
recorded `gap-check` verdict or an explicit `evidence-provenance-waiver` naming
this class (see the completion gate in `consult-design-thinking`), and
`engagement-status.sh` warns when a `complete` deliverable has neither. Like
`chosen_framework`, `producing_route`, and `persona_review`, it needs no script
change to reach read surfaces: `engagement-status.sh` passes every deliverable
field through verbatim (its rollup reads only `state`). The same `evidence_class`
vocabulary also appears as YAML frontmatter on first-party research artifacts —
the diagnostic field-0's `research/as-is-seed.md`, authored by `consult-scope`
from the as-is scoping dimensions, carries `evidence_class: first-party` on the
file itself (see `references/research-routing.md`).

`depends_on[]` (optional, default absent/empty) declares this deliverable's
dependencies as an array of `{action_field, deliverable}` WBS-coordinate objects,
declared **on the dependent**. Edges may cross fields. The inverse — `blocks[]`,
"what this deliverable blocks" — is **not stored**; it is derived at read time by
inverting `depends_on` across every `field.json` (see State Ownership). `lineage_status`
(optional, `null` when current) is the one stored staleness flag —
`{status:"stale", reason, flagged_at, trigger}`, orthogonal to `state`: a `complete`
deliverable can also be `stale`, meaning an upstream change may have invalidated its
ground while the artifact and DT stage stay intact until a human reworks (or clears)
it. The graph engine `scripts/deliverable-graph.py` reads these fields (validate /
trace / impact / refresh-order) and `cascade-stale` writes `lineage_status` on
dependents via read-modify-write — flag-and-recommend only, never auto-rewriting a
deliverable. Full edge schema, cycle/dangling rules, and cascade + topological-refresh
semantics: `references/dependency-model.md`.

`publish[]` (optional, default absent/empty) records the deliverable's publish
lineage — one entry per format the consultant has published it to via
`consult-publish`. Each entry is
`{format, brief_path, route_steps, source_deliverable, published_at}`, where
`format` ∈ `{slides, web-poster, report, infographic}` and `brief_path` is a
**path reference** to the produced brief (the consult-native outline for
slides/web-poster, or the route's output path for the visual formats) — brief
content is never copied into `field.json`, mirroring the source-lineage
discipline so an upstream correction stays visible downstream without
duplication. `route_steps[]` records the dispatch chain actually run. The array
**appends** per published format, so publishing a deliverable to a second format
never overwrites the first. Like the other optional deliverable fields it needs
no script change to reach read surfaces — `engagement-status.sh` passes it
through verbatim. The routing each format resolves to is the canonical contract
in `references/publish-routing.md`.

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
`action_field` + `deliverable` (the WBS replacement for the legacy `phase` key):

- **execution-log.json** — workflow-state transitions: `{"transitions": [{"action_field": "...", "deliverable": "...", "from": "pending", "to": "in-progress", "timestamp": "...", "triggered_by": "<skill>"}]}`
- **method-log.json** — methods proposed/selected per deliverable: `{"methods": [{"action_field": "...", "deliverable": "...", "proposed": [...], "selected": [...], "rationale": "..."}]}`
- **decision-log.json** — key decisions with rationale and evidence refs: `{"decisions": [{"id": "d-001", "action_field": "...", "deliverable": "...", "decision": "...", "rationale": "...", "evidence_refs": [...], "timestamp": "..."}]}`. Gap-check entries share the same array, discriminated by `"kind": "gap-check"`: `{"id": "d-002", "kind": "gap-check", "action_field": "...", "deliverable": "...", "question": "<verbatim --question>", "theme_label": null, "verdict": "covered", "top_hit": "<page-slug>", "top_score": 0.36, "timestamp": "..."}` (recording contract: `references/research-routing.md`, Gap-Check Recording). Framework-selection entries likewise share the array, discriminated by `"kind": "framework-selection"`: `{"id": "d-003", "kind": "framework-selection", "action_field": "...", "deliverable": "...", "candidates_presented": ["pyramid-principle", "scqa", "..."], "chosen": "pyramid-principle", "is_combination": false, "rationale": "...", "timestamp": "..."}` — `candidates_presented[]` is the top-5 framework slugs shown at deliverable creation, `chosen` is the value stored in the deliverable's `chosen_framework` (a registry slug, a `"combo:<slugA>+<slugB>"` string, or `null`), and `is_combination` is `true` when `chosen` is a combo. Evidence-provenance-waiver entries likewise share the array, discriminated by `"kind": "evidence-provenance-waiver"`: `{"id": "d-004", "kind": "evidence-provenance-waiver", "action_field": "...", "deliverable": "...", "evidence_class": "<provenance class>", "rationale": "...", "timestamp": "..."}` — appended at deliverable completion when no `gap-check` verdict covers the deliverable, naming the `evidence_class` (mirrored to the deliverable entry) and the consultant's rationale for completing without a recorded gap-check. A `gap-check` OR an `evidence-provenance-waiver` for the deliverable's `(action_field, deliverable)` coordinates is the provenance record `engagement-status.sh` checks for. Diagnostic-field-0-waiver entries also share the array, discriminated by `"kind": "diagnostic-field-0-waiver"`: `{"id": "d-005", "kind": "diagnostic-field-0-waiver", "rationale": "...", "timestamp": "..."}` — appended by `consult-scope` at WBS-close when the consultant opts the engagement out of the default diagnostic field-0 (whose canonical default slug is `diagnostic-as-is`). Unlike the deliverable-stage kinds above it carries **no** `action_field`/`deliverable` coordinates, because it is recorded at scope close before any field or deliverable exists; the `rationale` is the consultant's stated reason for scoping without a diagnostic field-0. Key-question-grounding entries also share the array, discriminated by `"kind": "key-question-grounding"`: `{"id": "d-006", "kind": "key-question-grounding", "verdict": "grounded", "rationale": "...", "timestamp": "..."}` — appended by `consult-scope` at the Touch-2 re-validation step (after the five scoping dimensions are gathered) recording whether the key question was re-confirmed grounded in the diagnosed as-is problem; `verdict` is `"grounded"` when the original question held or `"reframed"` when it was rewritten against the as-is material. Like the diagnostic-field-0-waiver it carries **no** `action_field`/`deliverable` coordinates — it is recorded at scope time before any field exists. Kb-deposit-waiver entries also share the array, discriminated by `"kind": "kb-deposit-waiver"`: `{"id": "d-007", "kind": "kb-deposit-waiver", "action_field": "...", "deliverable": "...", "evidence_class": "<provenance class>", "rationale": "...", "timestamp": "..."}` — appended by `consult-design-thinking` at the Step 8 close-the-session gate when the consultant declines the elective deposit of a completed deliverable into the engagement's bound knowledge base (the default-on `cogni-knowledge:knowledge-ingest-source` deposit). Like the deliverable-stage kinds above it carries the `(action_field, deliverable)` coordinates and the deliverable's `evidence_class`; it is append-once per deliverable (check `decisions[]` for an existing `kb-deposit-waiver` with the same coordinates before appending, mirroring the evidence-provenance-waiver "if none exists, append" discipline), so a Step-8 re-run on resume neither double-deposits nor double-logs.

### personas/{slug}.json (Acting Stakeholder Personas)

Personas in cogni-consult are **acting** personas: the plugin speaks and
challenges as them during deliverable work (the shipped defaults are a
consulting partner and a project manager, copied from packaged templates in
`references/personas/`; engagements add client-side stakeholders). The schema
extends the legacy design-for persona shape with a `role` and `voice`
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
| cogni-knowledge | Orchestrates | Binds one knowledge base per engagement (`plugin_refs.knowledge_base`); every deliverable's research runs through the inverted pipeline and compounds in the same base (canonical rule: `references/research-routing.md`). Finalized syntheses are copied to `action-fields/{field-slug}/research/{topic-slug}.md`; deliverable `sources[].kb_ref` points back at knowledge-base pages |
| cogni-claims | Consumes | Deliverable `sources[]` carries the lineage triple (`source_url`, `entity_ref`, `propagated_at`) so claim corrections cascade to deliverables |
| cogni-visual / document-skills | Optional | Opt-in local-render fallback for publish briefs — the standard `consult-publish` path builds every format as a consult-native brief and hands it to Claude Design to render, so cogni-visual is no longer the export route |

## Conventions

- All slugs kebab-case, derived from names
- Entity outputs are Obsidian-browsable markdown with YAML frontmatter; state files are plain JSON
- Scripts are stdlib-only (bash + python3) and return `{"success": bool, "data": {...}, "error": "string"}`
