---
name: consult-design-thinking
description: |
  This skill should be used when the user wants to produce a deliverable of a
  cogni-consult engagement by running its design-thinking loop —
  empathize→define→ideate→prototype→test on one deliverable inside an action
  field. Trigger on: "work the deliverable", "run design thinking on
  <deliverable>", "produce the <deliverable> deliverable", "start the DT loop",
  "draft the deliverable", "continue the deliverable", or when a WBS
  dashboard recommendation hands off the next unstarted deliverable. Route global
  phase phrasing ("discover phase", "develop phase", "diamond") to the
  cogni-consulting plugin instead — cogni-consult has no engagement-level
  phases; design thinking runs per deliverable.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Per-Deliverable Design Thinking

Produce one deliverable by walking it through its own design-thinking loop:
empathize → define → ideate → prototype → test. The loop is scoped to a single
deliverable inside one action field — there is no engagement-level phase
machine. The stage methods live in `$CLAUDE_PLUGIN_ROOT/references/methods/`
(`empathy-mapping.md`, `hmw-synthesis.md`, `guided-ideation.md`); this skill
owns the conversation flow, the artifact, and the state writes. Schemas:
`$CLAUDE_PLUGIN_ROOT/references/data-model.md`.

## Workflow

### 1. Prerequisite Gate

When arriving via an in-session handoff (e.g. from a WBS dashboard
recommendation), the engagement directory and target deliverable are already
known — skip discovery. Otherwise locate the engagement:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

and confirm the intended engagement with the user when more than one is
registered. When discovery returns zero engagements, treat it the same as a
missing `consult-project.json`.

Read `<engagement-dir>/consult-project.json`. Branch explicitly:

- If it is missing (or discovery returned zero engagements): dispatch
  `Skill("cogni-consult:consult-setup")` and stop — write nothing.
- If `workflow_state.scope` is not `"complete"`: dispatch
  `Skill("cogni-consult:consult-scope")` and stop — write nothing. The WBS
  must exist before deliverable work starts.

Then identify the target deliverable: the consultant names it, or pick the
recommendation handed in. Read the field's
`action-fields/<field-slug>/field.json` and confirm the deliverable entry
exists (slug, title, `state`, `dt_stage`). If the entry is missing, stop —
this skill produces deliverables, it never invents manifest entries.
Dispatch `Skill("cogni-consult:consult-action-fields")` to plan the field's
deliverable set (it writes the full planned-entry shape, including
`producing_route` and `persona_review`), then resume here with the planned
entry.

When `language` is set in `consult-project.json`, hold the conversation in
that language; technical terms, slugs, and file names stay English.

### 2. Open the Loop

If the deliverable's `state` is `pending`: one `Edit` of `field.json` sets it
to `"in-progress"` and `dt_stage` to `"empathize"`, and one `Edit` of
`.metadata/execution-log.json` appends to its `transitions[]` array the entry
`{"action_field": "<field-slug>", "deliverable": "<deliverable-slug>",
"from": "pending", "to": "in-progress", "timestamp": "<ISO>",
"triggered_by": "consult-design-thinking"}`.

If the deliverable is already `in-progress`, resume at its current `dt_stage`
— re-entering an earlier stage is normal (the loop may iterate); just keep
`dt_stage` honest at each boundary.

If the deliverable is `complete` and the consultant wants rework ("continue
the deliverable", a revision request), confirm the re-entry first, then one
`Edit` of `field.json` sets `state` back to `"in-progress"` with `dt_stage`
at the stage the rework needs (often `define` or `ideate`), and one `Edit` of
`.metadata/execution-log.json` appends the `complete` → `in-progress`
transition to `transitions[]`.

### 3. Empathize

Read `$CLAUDE_PLUGIN_ROOT/references/methods/empathy-mapping.md` and run it
for the personas that matter to this deliverable (`personas/*.json`). When the
directory is empty, say so and continue with the consultant's own stakeholder
knowledge — persona files can be added later without redoing the loop.

When the engagement has a bound knowledge base
(`plugin_refs.knowledge_base`), recommend pulling existing synthesis first —
dispatch `Skill("cogni-knowledge:knowledge-query")` with
`--knowledge-slug <plugin_refs.knowledge_base>` for the deliverable's topic.
Evidence comes from the knowledge base, never from raw web search; when the
base has no coverage, note the gap as a research need rather than
improvising sources.

Close the stage with one `Edit` of `field.json`: `dt_stage` → `"define"`.

### 4. Define

Read `$CLAUDE_PLUGIN_ROOT/references/methods/hmw-synthesis.md` and sharpen
the deliverable's problem spec from the empathize outputs plus the field's
`framing`. Lock 1-3 HMW questions with the consultant.

Append the locked spec to `.metadata/decision-log.json`'s `decisions[]` array as a decision
(`{"id": "d-NNN", "action_field": ..., "deliverable": ..., "decision":
"<locked problem framing>", "rationale": ..., "evidence_refs": [...],
"timestamp": ...}`). Then `Edit` `field.json`: `dt_stage` → `"ideate"`.

### 5. Ideate

Read `$CLAUDE_PLUGIN_ROOT/references/methods/guided-ideation.md` and run the
diverge→cluster→converge→sketch flow against the locked spec. Keep it
proportionate — a deliverable with an obvious shape needs one quick pass, not
a full workshop.

Append the method selection to `.metadata/method-log.json`'s `methods[]` array
(`{"action_field": ..., "deliverable": ..., "proposed": [...], "selected":
[...], "rationale": ...}`). Then `Edit` `field.json`: `dt_stage` →
`"prototype"`.

### 6. Prototype

Draft the deliverable artifact at
`action-fields/<field-slug>/<deliverable-slug>.md` — Obsidian markdown with
YAML frontmatter exactly per the data model: `slug`, `action_field`,
`sources[]` (each entry the lineage triple `source_url`, `entity_ref`,
`propagated_at`, plus `kb_ref` when the claim came from the knowledge base),
and `updated`. State is intentionally absent from the frontmatter — it lives
in `field.json` only.

Structure the body from the loop's outputs: the problem (define), options
considered (ideate), the chosen approach, and the content itself. Every
evidence-backed claim carries a `sources[]` entry. Then `Edit` `field.json`:
`dt_stage` → `"test"`.

### 7. Test

Challenge the draft as the stakeholder personas, in their voice: for each
relevant `personas/*.json`, pose the objections that persona's `role`,
`core_tension`, and `empathy_map` imply, and revise the artifact where a
challenge lands. Append one `work_log` entry per persona challenged to that
persona's `personas/<persona-slug>.json` `work_log` array via `Edit`
(`{"action_field": ..., "deliverable": ..., "action": "challenged",
"date": ...}`), and append (or update) a `## Persona Challenges` section in
the deliverable artifact summarizing each persona's challenge and the
consultant's disposition (accepted / revised / rejected with reason). When
the manifest entry carries a `persona_review` field, advance it (`pending` →
`in-progress` when challenges start, → `complete` only once every challenge
is dispositioned); when it doesn't, the work_log entries and the artifact
section are the record. With no personas on disk, run the challenge against the consultant
directly ("what would your engagement partner push back on?") and say the
acting-persona pass will deepen once personas exist.

If the draft survives (consultant accepts): one `Edit` of `field.json` sets
`state` → `"complete"` (keep `dt_stage` at `"test"`), and one `Edit` of
`.metadata/execution-log.json` appends the `in-progress` → `complete`
transition to `transitions[]`. If it does not survive, loop back — set `dt_stage` to the stage
the revision needs (often `define` or `ideate`) and continue; `state` stays
`in-progress`.

### 8. Close the Session

Summarize: the deliverable's final state, the artifact path, key decisions
logged, and which personas challenged it. Recommend the next step — the next
unstarted deliverable in the WBS (via the WBS dashboard skill when present in
the plugin, or by reading the field manifests directly).

## Important Notes

- **State ownership**: deliverable `state` and `dt_stage` live only in the
  field's `field.json`; the artifact frontmatter never carries state. Field
  and engagement completion are derived at read time. See
  `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
- **Edit, never rewrite**: `field.json`, `consult-project.json`,
  `personas/*.json`, and the `.metadata/` logs are all edited surgically;
  the root `consult-project.json` is never touched by deliverable work (its
  `updated` covers root-file changes only).
- **Evidence discipline**: research goes through the engagement's bound
  knowledge base (`cogni-knowledge:knowledge-query`), never raw web search;
  every evidence-backed claim in the artifact carries the `sources[]`
  lineage triple so corrections can cascade.
- **Loop, not gate**: stages may re-enter earlier stages; `state` stays
  `in-progress` until the test stage passes. Log state transitions (not
  per-stage moves) in the execution log.
