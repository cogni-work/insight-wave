---
name: consult-action-fields
description: |
  This skill should be used when the user wants to manage the WBS of a
  cogni-consult engagement — listing each action field's deliverables and
  their status, planning a field's deliverable set, picking the next
  deliverable to work, or adding/splitting/merging action fields after
  scoping. Trigger on: "show the WBS", "action fields dashboard", "what
  deliverables are open", "plan the deliverables", "next deliverable",
  "add an action field", "split this field", "merge two action fields",
  or when consult-scope hands off a freshly scoped engagement. Route
  Double Diamond phasing ("discover phase", "deliver phase status") to
  cogni-consulting:consulting-resume instead.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Action-Field WBS Management

Manage the engagement's work-breakdown structure: each action field named
during scoping is a container whose `field.json` manifests the deliverables
that complete it. This skill renders the WBS dashboard (fields × deliverables
× status), plans each field's deliverable set from
`$CLAUDE_PLUGIN_ROOT/references/deliverable-types.md`, recommends the next
unstarted deliverable, and keeps `consult-project.json` and the
`action-fields/` tree consistent when fields are added, split, or merged.
It manages the manifest layer only — producing a deliverable is the work of
its producing route (a `consult-design-thinking` run by default).

## Workflow

### 1. Prerequisite Gate

When arriving via an in-session `consult-scope` handoff, the engagement
directory is already known — skip discovery. Otherwise locate the engagement:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

and confirm the intended engagement with the user when more than one is
registered.

Read `<engagement-dir>/consult-project.json`. If it is missing, redirect to
`consult-setup`; if `workflow_state.scope` is not `"complete"`, redirect:
"Scoping isn't closed yet — the action fields come from `consult-scope`."
Then dispatch `Skill("cogni-consult:consult-scope")` and stop — write
nothing. The WBS exists only once scoping has named the fields.

### 2. Read the Current WBS State

Run the status rollup first — it derives field and engagement completion at
read time and passes every `field.json` deliverable entry through verbatim:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh <engagement-dir>
```

On `"success": false`, stop and surface the error. For any field listed in
`action_fields[]` whose `field.json` is missing (a scaffold gap), `Write` the
stub per the data model before proceeding — never leave the root list and the
directory tree inconsistent.

### 3. Render the WBS Dashboard

Present one table, fields in `action_fields[]` order (that order is the WBS
priority), deliverables in manifest order:

```
| Action field | Deliverable | State | DT stage | Route | Persona review |
|---|---|---|---|---|---|
| market-evidence | market-sizing | complete | test | consult-design-thinking | complete |
| market-evidence | competitor-landscape | in-progress | ideate | consult-design-thinking | pending |
| portfolio-fit | — (no deliverables planned) | | | | |
```

Close the dashboard with the **next-deliverable recommendation**: the first
deliverable with `state: "pending"`, walking fields in `action_fields[]`
order and deliverables in manifest order. When a field has an empty
`deliverables[]`, recommend planning that field's set (step 4) instead —
an empty container outranks a half-done one. When every deliverable is
`complete`, say so: the engagement is complete by derivation, there is
nothing to store.

### 4. Plan a Field's Deliverable Set

For a field with no (or too few) deliverables, read
`$CLAUDE_PLUGIN_ROOT/references/deliverable-types.md` (once per session — it
covers every field), judge the field's type from its `framing`, and propose
1-3 deliverables by affinity. Confirm with the consultant, then `Edit` the
field's `field.json` once, appending all agreed entries, each shaped:

```json
{
  "slug": "<deliverable-slug>",
  "title": "<Deliverable Title>",
  "state": "pending",
  "dt_stage": "empathize",
  "producing_route": "consult-design-thinking",
  "persona_review": "pending"
}
```

`producing_route` names the skill that will produce the deliverable —
default `consult-design-thinking`; use another route only when the
consultant names one (e.g. a direct `cogni-visual` export of an existing
artifact). `persona_review` tracks the acting-persona challenge pass:
`pending` → `in-progress` → `complete`. Both fields are manifest metadata —
recommend the route, never dispatch it from here.

Removing or renaming a deliverable is also an `Edit` of `field.json` — but
never silently drop an entry whose `state` is not `pending`; started work is
the consultant's to discard.

### 5. Add, Split, or Merge Action Fields

Field-set changes touch two places, always both, in this order:

1. `Edit` `consult-project.json`: update `action_fields[]` to the new ordered
   list of **slug strings only**, and set `updated` to today's ISO date (the
   root `updated` covers action-field list changes; deliverable edits in
   step 4 never touch it).
2. Reconcile the directory tree under `action-fields/`:
   - **Add**: `Write` the new field's `field.json` stub (`slug`, `title`,
     `framing`, `deliverables: []`).
   - **Split**: create stubs for the new fields, then move each surviving
     deliverable entry into exactly one successor manifest (an `Edit` per
     manifest) — entries move, they are never duplicated, so each
     deliverable keeps living in exactly one field.
   - **Merge**: append the absorbed field's `deliverables[]` entries to the
     surviving field's manifest, then treat the absorbed field as dropped.
   - **Drop** (and the leftover side of split/merge): honor the re-run
     guard from `consult-scope` — leave the field's directory and
     `field.json` in place and note the removal in the summary; deleting
     deliverable history is the consultant's call, not the skill's.

Never overwrite an existing `field.json` — it is the single source of truth
for that field's deliverable states.

### 6. Close the Session

Summarize what changed (fields added/split/merged, deliverables planned) and
re-state the next-deliverable recommendation with its producing route — e.g.
"Next: `competitor-landscape` in `market-evidence`, via
`consult-design-thinking` once it ships." Until that skill ships, point the
consultant at the deliverable's markdown artifact under the field directory
as the working surface.

## Important Notes

- **State ownership**: deliverable `state`, `dt_stage`, `producing_route`,
  and `persona_review` live only in the field's `field.json`; field and
  engagement completion are derived at read time. See
  `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
- **Edit, never rewrite**: all `consult-project.json` changes go through
  `Edit` so setup-owned fields (`created`, `plugin_refs`, `language`)
  survive; root `updated` changes only when `action_fields[]` itself does.
- **Slug discipline**: `action_fields[]` holds kebab-case slug strings only —
  `engagement-status.sh` rejects non-string entries as malformed.
