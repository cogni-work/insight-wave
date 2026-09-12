---
name: consult-action-fields
description: |
  This skill should be used when the user wants to manage the WBS of a
  cogni-consult engagement — listing each action field's deliverables and
  their status, planning a field's deliverable set, picking the next
  deliverable to work, adding/splitting/merging action fields after
  scoping, or setting a deliverable's schedule (due date, effort, owner,
  milestone). Trigger on: "show the WBS", "action fields dashboard", "what
  deliverables are open", "plan the deliverables", "next deliverable",
  "add an action field", "split this field", "merge two action fields",
  "set a deliverable's due date", "set the start date/effort/owner",
  "mark a deliverable as a milestone", "schedule the deliverables",
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

### 0. Resolve the Interaction Language

Before any user-facing output, resolve the **interaction language** — the
workspace default, overridden by the user's message language — per
`$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`, which owns the
resolution ladder. Conduct the entire conversation in the resolved language.
It is independent of the engagement's `language` field, which is the
deliverable axis. This contract holds on the default path: it does not depend
on an output style being active.

The `description` of a Bash tool call is rendered to the consultant, so it is
user copy — write it in the interaction language, outcome-shaped, at most 6
words, with no script, file, or skill names, and never derived from the
script's filename or header comment. Worked pair:
`Discover cogni-consult engagements` → `Laufende Engagements holen`.
Section (f) of the canonical ecosystem register owns these five constraints —
edit them there first, then mirror into
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md` and here.

The register that output follows has two tiers. The overlay
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md` carries this plugin's own
state lexicon, coinages and German step vocabulary, and opens with the command
that reads the canonical ecosystem register behind it — which owns scope, the
table contract, step announcements and brevity budgets, and the executive
register. Read the overlay and follow that command; table cells and headers are
user copy too, not an exemption.

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

Present one table, fields in `action_fields[]` order (the WBS priority),
deliverables in manifest order:

```
| Handlungsfeld | Deliverable | Stand | Framework | Persona-Prüfung |
|---|---|---|---|---|
| market-evidence | market-sizing | fertig | pyramid-principle | fertig |
| market-evidence | competitor-landscape | in Arbeit · Ideate | — | offen |
| portfolio-fit | — (keine Deliverables geplant) | | | |
| go-to-market | ⚠ field.json nicht lesbar (siehe Warnungen) | | | |

Route: gtm-onepager · text-to-narrative
```

That is a German session. `Deliverable` and `Framework` are the same token in
both header rows.

`Stand` merges the stored `state` and `dt_stage` into one value, the stage
cased per `references/user-facing-output.md` (c) note 4. A `complete` or
`pending` deliverable renders no stage — a **render-time** suppression, so
`dt_stage` stays in `field.json`.

`Route` is not a column: when a deliverable's `producing_route` differs from
the default `consult-design-thinking`, note it beneath the table, never a
sixth cell: `Route: <deliverable> · <producing_route>`, e.g.
`Route: gtm-onepager · text-to-narrative`.

An English session renders the same table: header
`| Action field | Deliverable | Status | Framework | Persona review |`, values
`complete` / `in progress · Ideate` / `pending`, the no-deliverables row
`— (no deliverables planned)`, the unreadable-field row
`⚠ field.json not readable (see warnings)`, and the same `Route:` note line.

`Framework` shows the stored `chosen_framework` read-only — a registry slug
verbatim, a `combo:<slugA>+<slugB>` pairing rendered `<slugA> + <slugB>` (the
stored `combo:` prefix dropped), or `—` when none is stored. Never inferred or
chosen here.

Close the dashboard with the **next-deliverable recommendation**. Check for
stale deliverables first: any deliverable carrying `lineage_status.status:
"stale"` was invalidated upstream, and refreshing it outranks fresh work,
which a stale foundation would waste. When stale deliverables exist, run
`deliverable-graph.py <engagement-dir> refresh-order` and recommend refreshing
them in **topological order — upstream before dependents**: layer-0 first,
deeper layers only once the layer above is refreshed. Route to
`knowledge-refresh`, then `consult-design-thinking` to re-run the loop.

Only when nothing is stale, fall through to the first deliverable with
`state: "pending"`, walking in that same order. When a field has an empty
`deliverables[]`, recommend planning that field's set (step 4) instead — an
empty container outranks a half-done one. Skip unreadable fields — surface
their warning rather than a planning recommendation that would `Edit` a
malformed `field.json`. When every deliverable is `complete` and current, say
so — completion is derived, nothing is stored.

**Offer the visual dashboard.** This text table is the quick check; for a
themed, browsable view, offer `/cogni-consult:consult-dashboard`. When the
engagement already has `output/design-variables.json` and the WBS
structure changed this session (a field's deliverable set was planned in step 4,
or a field was added/split/merged), regenerate the HTML snapshot without
prompting by delegating to the `consult-dashboard-refresher` agent with
`engagement_dir: <engagement-dir>` and `plugin_root: $CLAUDE_PLUGIN_ROOT`.

**Milestone README refresh.** Whenever the WBS structure changed this session,
also run `python3 $CLAUDE_PLUGIN_ROOT/scripts/generate-engagement-readme.py "<engagement-dir>"`
to refresh the engagement-root README front door — no theme gate, and
non-fatal: on failure, warn and continue.

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
consultant names one (e.g. a `text-to-narrative` design brief built from an
existing artifact). `persona_review` tracks the acting-persona
challenge pass:
`pending` → `in-progress` → `complete`. Both fields are manifest metadata —
recommend the route, never dispatch it from here. `chosen_framework` records
the deliverable's structuring framework and is selected per
`$CLAUDE_PLUGIN_ROOT/references/framework-selection.md` (default `null` until
chosen). `evidence_class` records the provenance class of
the deliverable's evidence base — left `null` at planning and set during the
deliverable's design-thinking loop (the completion gate requires a provenance
record naming it); see `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.

**Select the structuring framework for each deliverable.** Before writing each
entry, choose its `chosen_framework` — the shape the deliverable's argument will
take — per `$CLAUDE_PLUGIN_ROOT/references/framework-selection.md`, which is
authoritative for the top-5 shortlist, the consulting-partner recommendation and
consultant confirmation, the `combo:<slugA>+<slugB>` storage form, the
`framework-selection` decision-log entry, and its write-once idempotency guard.

**Auto-wire solution-field deliverables to the diagnostic field-0 gate.** A
mandated diagnostic field-0 is only load-bearing if solution work actually
depends on it — otherwise the diagnostic is a token the consultant can ignore.
So whenever the field being planned is a *solution* field — any field whose slug
is **not** `diagnostic-as-is` — gate each of its deliverables on the diagnostic.
Before writing the deliverable entries, read
`action-fields/diagnostic-as-is/field.json`, take the **terminal deliverable**
(the last entry in its `deliverables[]` array — terminal is positional, there is
no separate marker), and add a `depends_on[]` entry pointing at it to every
deliverable being planned in this solution field:

```json
  "depends_on": [
    { "action_field": "diagnostic-as-is", "deliverable": "<terminal-slug>" }
  ]
```

Two skips keep the auto-wire safe and silent:

- **Diagnostic present but unplanned** — `diagnostic-as-is` is in
  `consult-project.json` `action_fields[]` but its `field.json` `deliverables[]`
  is empty (its planning was deferred). Skip the wire and note to the consultant
  that the gating edge can be added once field-0 is planned.
- **No diagnostic field** — `diagnostic-as-is` is absent from
  `consult-project.json` `action_fields[]` (the engagement recorded a
  diagnostic-field-0 opt-out waiver, or predates the mandated field-0). Skip
  silently — there is no gate target.

The auto-wired edge is the same `{action_field, deliverable}` coordinate as any
other dependency below (no new schema, no new field type), and it is covered by
the same `validate` mandate at the end of this step — run the validator once
after planning, not a second time for the auto-wire.

Write the auto-wired edge once, when the solution field's deliverables are first
planned. On a re-run over an already-planned solution field, if a deliverable
already carries a `depends_on[]` entry to a `diagnostic-as-is` deliverable, leave
it — do not add a duplicate edge and do not silently re-point it at a now-changed
terminal — the same leave-prior-session-edges-alone discipline the framework
idempotency guard above applies (`validate` would not flag a duplicate edge to a
still-valid target, so the discipline is the only guard against drift).

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
runs through the engagement's bound knowledge base per
`$CLAUDE_PLUGIN_ROOT/references/research-routing.md` — never raw web search —
with syntheses landing in this field's `research/` directory
(`action-fields/<field-slug>/research/<topic-slug>.md`), which the producing
route reads.

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

### 6. Set Deliverable Schedule

A deliverable can carry five optional scheduling fields — `start_date`,
`due_date`, `duration` (effort-days), `owner`, `milestone` — that feed the
roadmap read-model (`deliverable-graph.py schedule`). The field contract and the
derived timeline are defined in
`$CLAUDE_PLUGIN_ROOT/references/project-plan-model.md`; do not hand-edit
`field.json` to set them. Use `schedule-edit.py`, which validates the value,
edits `field.json` in place preserving every sibling key, and appends a
`plan-schedule-edit` entry to the decision-log for the audit trail:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/schedule-edit.py <engagement-dir> \
  set <action_field>/<deliverable> --field due_date --value 2026-05-01 \
  [--rationale "<why>"]
python3 $CLAUDE_PLUGIN_ROOT/scripts/schedule-edit.py <engagement-dir> \
  show <action_field>/<deliverable>
```

One `--field` per `set` (the decision-log records one edit per field). Dates
must be ISO-8601 `YYYY-MM-DD`, `duration` a non-negative integer (`0` is valid),
`milestone` a boolean. An invalid value returns `success:false` and writes
nothing. `set` never touches `state`, `dt_stage`, or `depends_on[]`. `show`
reads back the deliverable's current five scheduling values (or their absence)
without writing — use it to confirm a value before or after a `set`.

### 7. Close the Session

If steps 4-5 changed the WBS after the dashboard was rendered, run the
milestone README refresh from step 3 now, before closing.

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
- **Research routing**: this skill plans the work; the producing route runs
  the research through the bound knowledge base (step 4).
