# cogni-consult Project Plan Model Reference

A consultant running an engagement wants more than a list of deliverables and
their states — they want a *plan*: when each deliverable starts, when it is due,
how much effort it carries, who owns it, and which points are milestones. Today a
`field.json` deliverable entry records only execution state (`state`, `dt_stage`,
`persona_review`) and its `depends_on[]` edges; there is no place to record
schedule, and no documented read-model for a phased timeline. This reference
defines that contract: the scheduling fields the write side records on a
deliverable, and the roadmap read-model the read side derives from them. It ships
no behavior on its own — it is the foundation the plan-editing surface and the
critical-path scheduler both build against.

Nothing here requires a schema-enforcement or rollup change. The five scheduling
fields are **optional and additive** on the existing deliverable object, and
`scripts/engagement-status.sh` already passes every deliverable field through
verbatim (its rollup reads only `state`), so the new fields reach every read
surface with no script edit — exactly the discipline the sibling optional fields
(`chosen_framework`, `evidence_class`, `publish[]`) already follow in
`references/data-model.md`.

## Scheduling fields

Schedule is declared on the deliverable itself, inside its `field.json`
deliverable entry, alongside `state` and `depends_on[]`. All five fields are
optional and absent by default — a deliverable with no schedule is the norm, and
an unscheduled engagement is byte-identical to one authored before this contract
existed:

```json
{
  "slug": "market-sizing",
  "title": "Market sizing",
  "state": "pending",
  "dt_stage": "empathize",
  "producing_route": "consult-design-thinking",
  "persona_review": "pending",
  "depends_on": [],
  "start_date": "2026-03-02",
  "due_date": "2026-03-13",
  "duration": 8,
  "owner": "Lead consultant",
  "milestone": false
}
```

| Field | Type | Optional | Default | Description |
|-------|------|----------|---------|-------------|
| `start_date` | string (ISO 8601 date, `YYYY-MM-DD`) | Yes | absent | The planned start date of the deliverable. |
| `due_date` | string (ISO 8601 date, `YYYY-MM-DD`) | Yes | absent | The planned completion date of the deliverable. |
| `duration` | integer (effort, days) | Yes | absent | Estimated effort in whole days. Effort, not calendar span — the read-model, not this field, derives calendar placement from dependencies. |
| `owner` | string | Yes | absent | Free-text name or role of the accountable owner. |
| `milestone` | boolean | Yes | `false` | Marks the deliverable as a milestone (a plan-level checkpoint) rather than routine work. |

The fields are **single-sourced in `field.json`**, on the deliverable entry —
never on the engagement-root `consult-project.json`, which stores only scope, the
ordered `action_fields[]`, and `plugin_refs`. Storing schedule on the root would
split deliverable state across two files and violate the deliverable-state
single-source-of-truth (`references/data-model.md`, State Ownership). A read
surface that needs schedule reads it from the deliverable, the same place it
reads `state` and `depends_on[]`.

## Roadmap read-model

A phased timeline is **derived, never stored**. The read side computes it from the
`depends_on[]` edges (the dependency graph in `references/dependency-model.md`) and
the per-deliverable `duration`, grouping deliverables into **plan layers** the same
way the dependency model's `refresh-order` groups stale deliverables:

- Layer 0 = deliverables with no dependency inside the plan.
- Layer N = deliverables whose dependencies all sit in layers < N.

Each layer is a phase of the roadmap: every deliverable in a layer can begin once
its upstream layers are complete, so the layer index is the deliverable's earliest
phase. Calendar placement within a phase is a function of `start_date` / `due_date`
where authored and `duration` where not — a scheduler consuming this read-model can
lay durations along the topological order to produce earliest-start dates, and a
`milestone` deliverable anchors a checkpoint at its phase boundary. A cycle among
the plan's deliverables makes layering undefined and is surfaced as an error,
mirroring the dependency model's cycle handling.

Because phase is derived from `depends_on[]`, the plan stays correct without a
stored phase field: adding an edge re-layers the affected deliverables on the next
read, and no deliverable carries a phase number that could drift out of sync with
its edges. This is the read-model half of the same flag-not-rewrite discipline the
dependency model keeps — the plan view surfaces structure, it never rewrites a
deliverable's schedule.

## Recording a schedule edit

When the plan-editing surface changes one of the five scheduling fields on a
deliverable, it appends a `plan-schedule-edit` entry to the append-only
decision-log (`references/data-model.md`, decision-log catalog), addressed by the
deliverable's `(action_field, deliverable)` coordinates and naming the field and
its before/after value. The audit trail of schedule changes therefore lives beside
the other deliverable-stage decisions, discriminated by `"kind"`, so the roadmap's
provenance matches the discipline the rest of the model already keeps.
