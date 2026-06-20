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
  or when consult-scope hands off a freshly scoped engagement. Double
  Diamond phase phrasing ("discover phase", "deliver phase status")
  refers to a legacy engagement model no longer in the ecosystem; new
  consulting work lives in cogni-consult (this skill owns its WBS and
  deliverable management).
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
registered. When discovery returns zero engagements, treat it the same as a
missing `consult-project.json`.

Read `<engagement-dir>/consult-project.json`. Branch explicitly:

- If it is missing (or discovery returned zero engagements): dispatch
  `Skill("cogni-consult:consult-setup")` and stop — write nothing.
- If `workflow_state.scope` is not `"complete"`: redirect — "Scoping isn't
  closed yet — the action fields come from `consult-scope`." — then dispatch
  `Skill("cogni-consult:consult-scope")` and stop — write nothing. The WBS
  exists only once scoping has named the fields.

### 2. Read the Current WBS State

Run the status rollup first — it derives field and engagement completion at
read time and passes every `field.json` deliverable entry through verbatim:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh <engagement-dir>
```

On `"success": false`, stop and surface the error. On success, also read
`data.warnings[]` — the script reports fields it could not parse there and
marks them `state: "unreadable"`; surface those warnings with the dashboard.

The rollup cannot distinguish a missing `field.json` from an existing stub
with an empty `deliverables[]` (both report `pending` with no deliverables),
so for each gap candidate — a field the rollup lists with no deliverables —
attempt to `Read` `action-fields/<field-slug>/field.json` before considering
a repair. Only when the file genuinely does not exist, `Write` the stub per
the data model (sourcing `title` and `framing` from `scope/key-question.md`'s
action-field list) — never leave the root list and the directory tree
inconsistent, and never `Write` a stub for a field that is merely empty or
`unreadable` (an unreadable file is the consultant's to inspect, not the
skill's to replace).

### 3. Render the WBS Dashboard

Present one table, fields in `action_fields[]` order (that order is the WBS
priority), deliverables in manifest order:

```
| Action field | Deliverable | State | DT stage | Framework | Route | Persona review |
|---|---|---|---|---|---|---|
| market-evidence | market-sizing | complete | test | pyramid-principle | consult-design-thinking | complete |
| market-evidence | competitor-landscape | in-progress | ideate | — | consult-design-thinking | pending |
| portfolio-fit | — (no deliverables planned) | | | | | |
| go-to-market | ⚠ unreadable field.json (see warnings) | | | | | |
```

`Framework` shows the deliverable's stored `chosen_framework` read-only — a
registry slug verbatim, or for a `combo:<slugA>+<slugB>` pairing the two slugs
joined as `<slugA> + <slugB>` (the stored `combo:` prefix dropped for display),
or `—` when none is stored (legacy deliverables, or one created before a
framework was chosen). The value is never inferred or chosen here.

Close the dashboard with the **next-deliverable recommendation**. Check for
stale deliverables first: any deliverable carrying `lineage_status.status:
"stale"` has been invalidated by an upstream change, and refreshing it outranks
starting fresh pending work (new work built on a stale foundation is wasted).
When stale deliverables exist, run `deliverable-graph.py <engagement-dir>
refresh-order` and recommend refreshing them in **topological order — upstream
before dependents**: the layer-0 deliverable(s) first (nothing else stale
depends on them, so they are safe to refresh now), deeper layers only once the
layer above is refreshed. Route to `knowledge-refresh`, then
`consult-design-thinking` to re-run the deliverable's loop.

Only when nothing is stale, fall through to the first deliverable with
`state: "pending"`, walking fields in `action_fields[]` order and deliverables
in manifest order. When a field has an empty `deliverables[]`, recommend
planning that field's set (step 4) instead — an empty container outranks a
half-done one. Skip unreadable fields in this walk — the rollup reports them
with an empty `deliverables[]` too, but the right response is surfacing their
warning, not a planning recommendation that would `Edit` a malformed
`field.json`. When every deliverable is `complete` and current, say so: the
engagement is complete by derivation, there is nothing to store.

**Offer the visual dashboard.** This text table is the quick check; for a
themed, browsable view of the same WBS — deliverable states, design-thinking
stages, and persona-review coverage — offer `/cogni-consult:consult-dashboard`.
When the engagement already has `output/design-variables.json` and the WBS
structure changed this session (a field's deliverable set was planned in step 4,
or a field was added/split/merged), regenerate the HTML snapshot without
prompting by delegating to the `consult-dashboard-refresher` agent with
`engagement_dir: <engagement-dir>` and `plugin_root: $CLAUDE_PLUGIN_ROOT`.

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
  "chosen_framework": null,
  "persona_review": "pending",
  "evidence_class": null
}
```

`producing_route` names the skill that will produce the deliverable —
default `consult-design-thinking`; use another route only when the
consultant names one (e.g. a direct `cogni-visual` export of an existing
artifact). `persona_review` tracks the acting-persona challenge pass:
`pending` → `in-progress` → `complete`. Both fields are manifest metadata —
recommend the route, never dispatch it from here. `chosen_framework` records
the deliverable's structuring framework and is selected per the sub-step below
(default `null` until chosen). `evidence_class` records the provenance class of
the deliverable's evidence base — left `null` at planning and set during the
deliverable's design-thinking loop (the completion gate requires a provenance
record naming it); see `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.

**Select the structuring framework for each deliverable.** Before writing each
entry, choose its `chosen_framework` — the shape the deliverable's argument will
take. Read `$CLAUDE_PLUGIN_ROOT/references/frameworks-registry.md` (once per
session — it covers every deliverable), then for each deliverable being planned:

1. **Shortlist the top-5.** For each deliverable being planned, rank the
   applicable frameworks and take the five strongest — this top-5 is per
   deliverable, not the `1-3 deliverables` count from the start of this step.
   Rank by combining the registry's deliverable-type and field-type
   **affinity** columns with your own judgment of the field's `framing` and the
   engagement's key question (from `scope/` / `consult-project.json`).
2. **Present each candidate** with its one-line structure signature from the
   registry's `Structure signature` column, so the consultant sees what each
   shape commits the deliverable to.
3. **Recommend in the consulting-partner's voice.** Act as the
   `consulting-partner` persona
   (`$CLAUDE_PLUGIN_ROOT/references/personas/consulting-partner.json`) — the
   advisor who knows which frameworks fit which problem shape — and recommend one
   framework, or a combination of two, **with an explicit rationale** tying the
   choice to the field's so-what. A combination is stored as
   `combo:<slugA>+<slugB>`.
4. **Confirm with the consultant** before storing — the recommendation is a
   starting point, not a constraint; the consultant may pick any registry slug,
   or name a new structure (give it a clear kebab-case slug like any other).
5. **Store the choice.** Set `chosen_framework` on the deliverable's `field.json`
   entry to the chosen registry slug, the `combo:<slugA>+<slugB>` string, or
   `null` if the consultant defers, and append a `framework-selection` entry to
   the engagement's `.metadata/decision-log.json` `decisions[]` array (the same
   array that already holds gap-check entries), discriminated by
   `"kind": "framework-selection"`:

```json
{
  "id": "<next decision id>",
  "kind": "framework-selection",
  "action_field": "<field-slug>",
  "deliverable": "<deliverable-slug>",
  "candidates_presented": ["pyramid-principle", "scqa", "..."],
  "chosen": "pyramid-principle",
  "is_combination": false,
  "rationale": "<why this framework fits the field's so-what>",
  "timestamp": "<ISO timestamp>"
}
```

`candidates_presented[]` is the top-5 slugs you shortlisted, `chosen` mirrors the
value written to `chosen_framework`, and `is_combination` is `true` only when
`chosen` is a `combo:` string.

**Idempotency — never silently overwrite a chosen framework.** `chosen_framework`
is written once at creation and read-only thereafter. On a re-run over a
deliverable whose entry already carries a non-null `chosen_framework`, surface the
existing choice and require explicit reconfirmation from the consultant before
changing it — never overwrite it silently, and append no new decision-log entry
unless the consultant explicitly chooses to change it. When the consultant does
change it, append a fresh `framework-selection` entry (the decision-log is
append-only) so both the prior choice and the change stay on the trail.

Most deliverables have no upstream dependency — the entry above is the
default shape, so leave it as is. Only when a deliverable being planned
builds on earlier work (e.g. "this proposition assumes the market-sizing is
done") elicit the upstream WBS coordinates from the consultant — which
action-field slug and deliverable slug each dependency points at — and add a
`depends_on[]` array of `{action_field, deliverable}` objects to that
dependent entry:

```json
  "depends_on": [
    { "action_field": "market-evidence", "deliverable": "market-sizing" }
  ]
```

Edges may cross fields. Never write placeholder or empty-string coordinates —
omit `depends_on[]` entirely when there is no real dependency (an empty/`[]`
array is also fine), since `validate` rejects a coordinate that names no
existing deliverable as a dangling reference. This is the only place
dependencies are declared — the inverse ("what does this block?") is derived
at read time, never stored. Full edge schema:
`$CLAUDE_PLUGIN_ROOT/references/dependency-model.md`.

Whenever this session added or changed any `depends_on[]` entry, run the
dependency validator before considering the field planned — cycles and
dangling references are hard errors that must block planning:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> validate
```

On `"success": false`, surface the `error` string together with `data.cycles`
and `data.dangling`, and ask the consultant to correct the dependency
declarations. Do not close the session with an unresolved `validate` failure
when dependencies were declared this session.

When planning surfaces a research-heavy deliverable, note that its evidence
will run through the engagement's bound knowledge base per
`$CLAUDE_PLUGIN_ROOT/references/research-routing.md`, with syntheses landing
in this field's `research/` directory
(`action-fields/<field-slug>/research/<topic-slug>.md`) — the producing
route reads them from there.

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
     deliverable entry into exactly one successor manifest — an `Edit` per
     receiving manifest plus an `Edit` removing the moved entries from the
     source manifest. Entries move, they are never duplicated, so each
     deliverable keeps living in exactly one field.
   - **Merge**: append the absorbed field's `deliverables[]` entries to the
     surviving field's manifest, `Edit` the absorbed field's retained
     manifest to empty its `deliverables[]` — the session summary records
     where each entry moved — then treat the absorbed field as dropped.
   - **Drop** (and the leftover side of split/merge): honor the re-run
     guard from `consult-scope` — leave the field's directory and
     `field.json` in place and note the removal in the summary; deleting
     deliverable history is the consultant's call, not the skill's.

A split or merge changes the owning action-field slug of every entry it
moves, so any `depends_on` coordinate elsewhere in the engagement that
pointed at a moved deliverable now references a field that no longer owns it
— a dangling reference. After reconciling the directory tree, run the
validator to enumerate exactly which coordinates broke — each entry in
`data.dangling[]` names the dependent and the now-orphaned coordinate:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> validate
```

Repoint each dangling `depends_on` entry to the moved deliverable's new
`{action_field}`, then re-run `validate` to confirm the reshape leaves no
dangling edges.

Never overwrite an existing `field.json` — it is the single source of truth
for that field's deliverable states.

### 6. Close the Session

Summarize what changed (fields added/split/merged, deliverables planned) and
re-state the next-deliverable recommendation with its producing route — e.g.
"Next: `competitor-landscape` in `market-evidence`, via
`consult-design-thinking`." Offer to run that route now; the deliverable's
markdown artifact lands under the field directory either way.

## Important Notes

- **State ownership**: deliverable `state`, `dt_stage`, `producing_route`,
  `persona_review`, and `evidence_class` live only in the field's `field.json`;
  field and engagement completion are derived at read time. See
  `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
- **Edit, never rewrite**: all `consult-project.json` changes go through
  `Edit` so setup-owned fields (`created`, `plugin_refs`, `language`)
  survive; root `updated` changes only when `action_fields[]` itself does.
- **Slug discipline**: `action_fields[]` holds kebab-case slug strings only —
  `engagement-status.sh` rejects non-string entries as malformed.
- **Research routing**: deliverable research always runs through the
  engagement's bound knowledge base per
  `$CLAUDE_PLUGIN_ROOT/references/research-routing.md` — never raw web
  search; this skill plans the work, the producing route runs the research.
