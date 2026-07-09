---
name: consult-project-plan
description: |
  This skill should be used when the user wants a phased roadmap or timeline of a
  cogni-consult engagement's own WBS deliverables — sequenced from the dependency
  graph and durations and written as an Obsidian-browsable markdown artifact.
  Trigger on: "project plan", "engagement timeline", "roadmap", "show the
  roadmap", "gantt", "gantt chart", "schedule the engagement", "when does the
  engagement finish", "plan the timeline", "render the project plan", or when a
  WBS/dashboard view hands off a request for the sequenced plan — even if the user
  doesn't say "project plan" explicitly. This is an INTERNAL engagement-management
  view (a read-mostly sibling of consult-dashboard and consult-resume), not a
  client-facing content producer. Double Diamond phase phrasing ("discover phase",
  "deliver phase timeline") refers to a legacy engagement model no longer in the
  ecosystem; cogni-consult engagements have no phases — the roadmap phases here are
  the derived topological layers of the deliverable graph, not engagement stages.
allowed-tools: Read, Write, Bash, Skill
---

# Consult Project Plan

Render a phased roadmap of the engagement's work-breakdown structure — when each
deliverable can start, how much effort it carries, who owns it, which points are
milestones, and which deliverables sit on the critical path — as a persisted
`project-plan.md` markdown artifact at the engagement root. It is the timeline
sibling of `consult-dashboard` (visual status) and `consult-resume` (next-action
recommender): a read-mostly view that turns the deliverable graph plus the
scheduling fields into a sequenced plan a consultant can browse in Obsidian.

## Core Concept

Schedule lives on each deliverable inside its `field.json` entry — the five
optional scheduling fields `start_date`, `due_date`, `duration`, `owner`,
`milestone` (see `$CLAUDE_PLUGIN_ROOT/references/project-plan-model.md`). A phased
timeline is **derived, never stored**: the roadmap phases are the topological
layers of the `depends_on[]` graph (layer 0 = deliverables with no in-plan
dependency; layer N = deliverables whose dependencies all sit in layers < N), and
the duration-weighted forward pass + critical path come from
`deliverable-graph.py <engagement-dir> schedule`. This skill only reads that state
and writes `project-plan.md`; it never mutates a `field.json`, never writes a
`duration`-derived date back into engagement state, and never edits a deliverable's
schedule. Populating the scheduling fields is the job of `consult-action-fields`
(the plan-editing surface), not this skill.

## Workflow

### 1. Prerequisite Gate

When arriving via an in-session handoff that already resolved the engagement
directory, skip discovery. Otherwise locate the engagement:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

Confirm the intended engagement with the user when more than one is registered.
When discovery returns zero engagements, treat it the same as a missing
`consult-project.json`.

Read `<engagement-dir>/consult-project.json` and branch explicitly:

- If it is missing (or discovery returned zero engagements): dispatch
  `Skill("cogni-consult:consult-setup")` and stop — write nothing. Setup owns
  scaffolding and the knowledge-base binding.
- If `workflow_state.scope` is not `"complete"`: redirect — "Scoping isn't closed
  yet — the action fields and their deliverables come from `consult-scope`." —
  then dispatch `Skill("cogni-consult:consult-scope")` and stop — write nothing.
  There is no plan to render until scoping has named the fields and their
  deliverables.

Store the resolved engagement directory path and the engagement `slug`, `name`,
and `language` (for the artifact frontmatter). Everything below reads state only.

### 2. Read the Schedule and Deliverable State

Run the duration-weighted schedule read first — it is also the cycle gate:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> schedule
```

- On `"success": false` (a cycle in the deliverable graph makes layering and the
  forward pass undefined), **stop and surface the error** — report the cycle from
  `data.cycles` and do **not** write `project-plan.md`. A partial plan over a
  cyclic graph would be misleading. Recommend the user resolve the cycle (fix the
  offending `depends_on[]` edge via `consult-action-fields`) and re-run.
- On `"success": true`, keep `data.schedule[]` (per-deliverable
  `{key, action_field, deliverable, duration, earliest_start, earliest_finish,
  unscheduled}`), `data.critical_path[]` (ordered keys on the longest
  duration-weighted chain), `data.project_earliest_finish` (effort-days), and
  `data.unscheduled[]` (keys with no valid non-negative authored `duration`).

The `schedule` read does **not** emit `owner`, `start_date`, `due_date`, or
`milestone` — read those from state. For each action field listed in
`consult-project.json`'s `action_fields[]`, read
`<engagement-dir>/action-fields/<slug>/field.json` and collect, per deliverable
entry: its `slug`, `title`, `depends_on[]` (each an `{action_field, deliverable}`
WBS coordinate), and the scheduling fields `owner`, `start_date`, `due_date`,
`milestone`. The deliverable's schedule `key` is `<action_field_slug>/<deliverable_slug>`
— join it to the matching `data.schedule[]` entry by that key.

Surface any `field.json` that fails to parse as a warning alongside the plan
rather than aborting — a plan over the readable fields is still useful. (An
unreadable field means its deliverables are absent from the schedule read too.)

### 3. Derive the Phased Roadmap (topological layers)

Compute each deliverable's plan layer from the `depends_on[]` edges collected in
Step 2. The `schedule` read has already confirmed the graph is acyclic, so
layering is well-defined:

1. Let `K` be the set of all deliverable keys `<action_field>/<deliverable>` read
   in Step 2. For each deliverable, its **in-plan dependencies** are the
   `depends_on[]` entries whose `<action_field>/<deliverable>` key is in `K`
   (ignore any edge pointing outside the plan).
2. `layer(k) = 0` when the deliverable has no in-plan dependency; otherwise
   `layer(k) = 1 + max(layer(d))` over its in-plan dependencies. This is the
   deliverable's earliest phase — every deliverable in a layer can begin once its
   upstream layers complete.
3. Group deliverables by layer. **Phase N** of the roadmap is layer `N-1` (Phase 1
   = layer 0). Within a phase, order deliverables by `earliest_start`, then by key
   for a deterministic tie-break.

A deliverable is **on the critical path** iff its key is in `data.critical_path[]`.
A deliverable is a **milestone** iff its `field.json` `milestone` is `true` — a
milestone anchors a checkpoint at its phase boundary.

### 4. Render `project-plan.md`

Write `<engagement-dir>/project-plan.md` (overwriting any prior run — the plan is
derived-at-read-time, so a re-render always reflects current state). Use this
shape:

**YAML frontmatter** (Obsidian-browsable):

```yaml
---
type: project-plan
engagement: <slug>
engagement_name: <name>
lang: <language>
generated: <YYYY-MM-DD>          # today's date
project_earliest_finish: <data.project_earliest_finish>   # effort-days
phase_count: <number of layers>
critical_path: [<key>, ...]      # data.critical_path verbatim, [] when empty
unscheduled_count: <len(data.unscheduled)>
---
```

**Body** — a short lead-in sentence (in the interaction language; see Important
Notes), then one `## Phase N` heading per layer, each with a table:

| Deliverable | Action field | Owner | Start | Due | Duration (d) | Milestone | Critical path |
|-------------|--------------|-------|-------|-----|--------------|-----------|---------------|

- **Deliverable** — the deliverable `title` (fall back to its slug).
- **Owner / Start / Due** — the `field.json` `owner` / `start_date` / `due_date`,
  or `—` when absent.
- **Duration (d)** — the authored `duration` (effort-days); render `—` for a
  deliverable in `data.unscheduled[]` (no valid estimate), and `0` for an authored
  zero.
- **Milestone** — `◆` when `milestone` is true, else blank.
- **Critical path** — `●` when the key is in `data.critical_path[]`, else blank.

After the phase tables, add a one-line **Summary**: project earliest finish
(`project_earliest_finish` effort-days), the critical-path deliverable count, and
the number of unscheduled deliverables (so the reader knows how much of the plan is
estimated).

**Optional Mermaid `gantt` block** (emit only when at least one deliverable
carries a duration, i.e. `data.unscheduled[]` does **not** cover every deliverable;
omit the whole block gracefully, with a one-line note that no durations are
authored yet, when none do):

- Use `` ```mermaid `` fenced ` gantt` with `dateFormat YYYY-MM-DD` and
  `axisFormat %Y-%m-%d`, one `section Phase N` per layer, in phase order.
- Pick an **anchor date**: the earliest authored `start_date` across all
  deliverables, or — when none is authored — today's date, noting in the lead-in
  that dates are a relative baseline derived from the topological order.
- Each deliverable is a task: start at its authored `start_date` when present, else
  `anchor + earliest_start` days (laying durations along the topological order, as
  the read-model describes); length is its authored `duration` in days
  (`<duration>d`), or `1d` for an unscheduled/zero deliverable so the bar renders.
  Tag critical-path tasks `crit` and milestone tasks `milestone`.
- Keep task ids simple and unique (e.g. the deliverable key with `/` → `_`).

The full scheduling-field schema, the roadmap read-model, and the `schedule`
envelope live in `$CLAUDE_PLUGIN_ROOT/references/project-plan-model.md` — cite it
rather than restating it.

### 5. Confirm and Report

Tell the user (in the interaction language) that the plan was written to
`<engagement-dir>/project-plan.md`, and give a one-line takeaway: the phase count,
the project earliest finish in effort-days, and — when any exist — how many
deliverables are still unscheduled (a prompt to set durations via
`consult-action-fields` for a sharper timeline). Do not open a browser; the
artifact is markdown for Obsidian.

## Important Notes

- This skill is **read-only over engagement state** — it renders `project-plan.md`
  from `field.json` schedule fields and the `schedule` read; it never modifies a
  `field.json`, `consult-project.json`, or any deliverable's schedule. Populating
  the five scheduling fields is `consult-action-fields`' job.
- The roadmap is **derived, never stored**: re-running the skill re-layers and
  re-schedules from current `depends_on[]` and durations, so `project-plan.md` is
  always overwritten to match state. No phase number or derived date is ever
  written back into engagement state.
- A **cycle** in the deliverable graph makes layering and the schedule undefined —
  Step 2 stops and surfaces it rather than writing a misleading partial plan.
- The roadmap **phases** are topological layers of the deliverable graph, not
  engagement stages (cogni-consult engagements have no phases).
- **Interaction language**: communicate with the user (status messages,
  instructions, recommendations, questions) in the resolved interaction language —
  the workspace default, overridden by the user's message language — not the
  engagement's `language` field, which is the deliverable axis (it controls the
  artifact's `lang` frontmatter, not how you address the user). Technical terms,
  skill names, and CLI commands remain in English. See
  `$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`.
