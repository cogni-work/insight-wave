---
name: consult-design-thinking
description: |
  This skill should be used when the user wants to produce a deliverable of a
  cogni-consult engagement by running its design-thinking loop —
  empathize→define→ideate→prototype→test on one deliverable inside an action
  field. Trigger on: "work the deliverable", "run design thinking on
  <deliverable>", "produce the <deliverable> deliverable", "start the DT loop",
  "draft the deliverable", "continue the deliverable", or when a WBS
  dashboard recommendation hands off the next unstarted deliverable. Global
  phase phrasing ("discover phase", "develop phase", "diamond") refers to a
  legacy engagement model no longer in the ecosystem — do not run
  this loop against legacy engagement directories; cogni-consult has no
  engagement-level phases; design thinking runs per deliverable.
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

## The framework lens

Each deliverable's `field.json` entry carries `chosen_framework` — the
structuring framework its argument takes, set once at creation and read-only
thereafter (schema in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`). Its
value is one of: a stable `slug` from
`$CLAUDE_PLUGIN_ROOT/references/frameworks-registry.md` (e.g.
`pyramid-principle`), a `"combo:<slugA>+<slugB>"` pairing of two, or `null`.

The Prerequisite Gate (step 1) already reads `field.json`, so the value is in
hand — no extra read is needed. When it is non-`null`, resolve its one-line
**Structure signature** from the registry's framework table (for a `combo:`,
resolve both and apply them together) and carry that signature into the
**Define** and **Prototype** stages below: it shapes how the problem is framed
and how the artifact body is organized. The registry is thin by design — it
pins the signature and the stable key; supply the framework's depth at runtime:
where the registry `slug` cell links to a first-party page, follow it for the
framework's substance; otherwise supply that substance from your own knowledge.

When `chosen_framework` is `null` — a legacy deliverable created before a
framework was chosen, or a deliberate no-framework choice — run those stages
exactly as written below, with no framework structuring. The framework only
adds shape when present; it never blocks production when absent.

## Workflow

### Interaction mode

By default this loop runs as an **auto-walk**: it writes each stage's artifact
and log entry as it goes, surfacing the resulting entries — fast, and right for
an obvious-shape deliverable. A consultant who wants to steer the work can
instead opt into **interactive mode** (also *transparent mode*): trigger it at
loop entry with a phrase such as "run it interactively", "transparent mode", or
"with confirmation gates", or set it as a per-engagement default the consultant
states at the start. Interaction mode is **ephemeral** — it governs only this
session's conversation flow and is never written to `field.json`,
`consult-project.json`, or any log; the state-write ownership and the logging
contract below are identical in both modes.

In interactive mode, at each stage gate marked **Interactive mode** below (end
of Define, end of Ideate, start of Prototype, Test), before the stage's write:
surface the *reasoning* behind the stage decision (why this HMW spec, why this
ideation method, why this prototype shape, why these persona dispositions) ahead
of the log entry, name exactly what is about to be written, and pause for the
consultant's explicit confirmation — revise on feedback, then write. In
auto-walk mode, skip the pauses and proceed directly through each gate. The
gates only add confirmation seams and reasoning narration around the existing
writes; they never change what gets written or who owns it.

### Advancing the stage

Every `dt_stage` boundary below — in both auto-walk and interactive mode — moves
the stage through the guarded helper rather than a free-text `Edit` of
`field.json`. The helper validates the transition (rejects an unknown stage name
and a forward jump that skips a stage), writes `dt_stage` via an idempotent
read-modify-write, and appends a per-stage move to `.metadata/stage-log.json` so
the loop's iterations leave a trail (the execution log keeps recording *state*
transitions only, never per-stage moves):

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/dt-stage-advance.sh \
    <engagement-dir> <field-slug> <deliverable-slug> <target-stage>
```

A single-step forward advance, an idempotent same-stage re-set, and a re-entry
to any earlier stage (the loop may iterate) are all permitted; a forward jump
that skips a stage is refused with `success: false`. The helper degrades
gracefully on a legacy `field.json` whose deliverable has no `dt_stage` (it logs
the move with `from: null`). On a `success: false` (a refused jump, a missing
deliverable, an unreadable manifest) do not proceed past the boundary — surface
the error and resolve it before retrying, since an unwritten `dt_stage` leaves
the loop state inconsistent. Should the helper be absent (an older install),
fall back to a free-text `Edit` of `field.json` setting `dt_stage` directly.
Where a stage below says "advance `dt_stage` → `"X"`", run this helper with
`<target-stage>` `X`.

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
to `"in-progress"`, advance `dt_stage` → `"empathize"` via the helper (see
*Advancing the stage* above), and one `Edit` of
`.metadata/execution-log.json` appends to its `transitions[]` array the entry
`{"action_field": "<field-slug>", "deliverable": "<deliverable-slug>",
"from": "pending", "to": "in-progress", "timestamp": "<ISO>",
"triggered_by": "consult-design-thinking"}`.

If the deliverable is already `in-progress`, resume at its current `dt_stage`
— re-entering an earlier stage is normal (the loop may iterate); just keep
`dt_stage` honest at each boundary.

If the deliverable is `complete` and the consultant wants rework ("continue
the deliverable", a revision request), confirm the re-entry first, then one
`Edit` of `field.json` sets `state` back to `"in-progress"`, advance `dt_stage`
to the stage the rework needs (often `define` or `ideate`) via the helper (see
*Advancing the stage* above — a re-entry to an earlier stage is permitted), and
one `Edit` of `.metadata/execution-log.json` appends the `complete` →
`in-progress` transition to `transitions[]`.

Because the deliverable's content is about to change, flag its downstream
dependents stale now — before the rework begins — so the consultant sees the
blast radius up front:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
    cascade-stale <field-slug>/<deliverable-slug> --trigger deliverable_update
```

Surface `data.newly_flagged` (the deliverables now marked stale). A
`"success": false` (node not found, bad dir) is non-blocking — surface the
error and proceed with the rework.

### 3. Empathize

Read `$CLAUDE_PLUGIN_ROOT/references/methods/empathy-mapping.md` and run it
for the personas that matter to this deliverable (`personas/*.json`). When the
directory is empty, say so and continue with the consultant's own stakeholder
knowledge — persona files can be added later without redoing the loop.

Research for this stage follows the Research Routing Rule in
`$CLAUDE_PLUGIN_ROOT/references/research-routing.md` — the canonical
contract for every research run in the engagement. Start with the gap-check
rung: dispatch `Skill("cogni-knowledge:knowledge-query")` with
`--knowledge-slug <plugin_refs.knowledge_base>` for the deliverable's topic.
Record each gap-check per the Gap-Check Recording contract in the Research
Routing Rule — append one entry to `.metadata/decision-log.json`'s
`decisions[]` array tagged `"kind": "gap-check"`, carrying the **verbatim**
question plus the coverage outcome as discrete keys (never fold the verdict
or overlap scores into a prose `decision` string):
`{"id": "d-NNN", "kind": "gap-check", "action_field": ..., "deliverable":
..., "question": "<verbatim --question>", "theme_label": <label-or-null>,
"verdict": "covered"|"partial"|"uncovered", "top_hit": "<page-slug>"|null,
"top_score": <score>|null, "timestamp": ...}`. Use `kind` (not `type`) and
emit `verdict`/`top_hit`/`top_score` as their own keys — no `decision`
prose, no `evidence_refs` — so gap-checks stay filterable and the routing
decision replays programmatically.
When the base has no coverage, escalate to the full inverted pipeline (or
the `--source wiki` re-run on a populated base) per the rule, and copy the
finalized synthesis to `action-fields/<field-slug>/research/<topic-slug>.md`
so this deliverable — and later ones — find it at a stable path. Evidence
comes from the knowledge base, never from raw web search.

Close the stage by advancing `dt_stage` → `"define"` via the helper (see
*Advancing the stage* above).

### 4. Define

Read `$CLAUDE_PLUGIN_ROOT/references/methods/hmw-synthesis.md` and sharpen
the deliverable's problem spec from the empathize outputs plus the field's
`framing`. Lock 1-3 HMW questions with the consultant. When a framework lens
is in play (see *The framework lens* above), let its Structure signature frame
how you organize the problem and the approach — e.g. a `mece-issue-tree`
signature decomposes the problem into mutually-exclusive, collectively-
exhaustive branches before drafting, while a `pyramid-principle` signature
pushes you to lead with the answer and group the supporting arguments beneath
it. For a `combo:` choice, let the first signature frame the problem and the
second the approach. When `chosen_framework` is `null`, frame the spec as you
would by default.
When sharpening the spec surfaces an evidence gap (an assumption the
consultant cannot ground),
route the research per
`$CLAUDE_PLUGIN_ROOT/references/research-routing.md` before locking — a
spec built on an unverified assumption fails at the test stage anyway.

**Interactive mode:** before logging, present the locked 1-3 HMW questions and
the framing reasoning that produced them (including how the framework lens, if
any, shaped them), and confirm them with the consultant; revise until accepted,
then write.

Append the locked spec to `.metadata/decision-log.json`'s `decisions[]` array as a decision
(`{"id": "d-NNN", "action_field": ..., "deliverable": ..., "decision":
"<locked problem framing>", "rationale": ..., "evidence_refs": [...],
"timestamp": ...}`). Then advance `dt_stage` → `"ideate"` via the helper.

### 5. Ideate

Read `$CLAUDE_PLUGIN_ROOT/references/methods/guided-ideation.md` and run the
diverge→cluster→converge→sketch flow against the locked spec. Keep it
proportionate — a deliverable with an obvious shape needs one quick pass, not
a full workshop.

**Interactive mode:** before logging, surface the chosen ideation method and why
it fits this spec (proportionate to the deliverable's shape — one quick pass vs.
a full workshop), and confirm it with the consultant before writing.

Append the method selection to `.metadata/method-log.json`'s `methods[]` array
(`{"action_field": ..., "deliverable": ..., "proposed": [...], "selected":
[...], "rationale": ...}`). Then advance `dt_stage` → `"prototype"` via the
helper.

### 6. Prototype

**Interactive mode:** before drafting, surface the prototype direction — the
chosen approach and how the framework lens (if any) will shape the artifact body
— and confirm it with the consultant; revise the direction on feedback, then
draft.

Draft the deliverable artifact at
`action-fields/<field-slug>/<deliverable-slug>.md` — Obsidian markdown with
YAML frontmatter exactly per the data model: `slug`, `action_field`,
`sources[]` (each entry the lineage triple `source_url`, `entity_ref`,
`propagated_at`, plus `kb_ref` when the claim came from the knowledge base),
and `updated`. State is intentionally absent from the frontmatter — it lives
in `field.json` only.

Structure the body from the loop's outputs: the problem (define), options
considered (ideate), the chosen approach, and the content itself. When a
framework lens is in play (see *The framework lens* above), organize the
artifact body to its Structure signature rather than that default outline —
e.g. `pyramid-principle` → lead with the answer, then MECE-grouped supporting
arguments; `scqa` → Situation → Complication → Question → Answer;
`journey-process` → sequential stages along the path. For a `combo:` choice,
apply both signatures together (typically one frames the opening, the other
the body). When `chosen_framework` is `null`, use the default outline above.
Every evidence-backed claim carries a `sources[]` entry. Then advance
`dt_stage` → `"test"` via the helper.

### 7. Test

**Interactive mode:** before challenging, surface the persona dispositions you
intend to apply — which personas will challenge and the objections each is likely
to raise — so the consultant can steer the challenge before it runs; then proceed.

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
transition to `transitions[]`. Then run the dependency cascade so every
downstream deliverable that listed this one in its `depends_on[]` is flagged
stale:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
    cascade-stale <field-slug>/<deliverable-slug> --trigger deliverable_update
```

Surface `data.newly_flagged` in the session summary so the consultant knows
which deliverables now need revisiting. A `"success": false` (node not found,
bad dir) is non-blocking — the completion stands; surface the error and
continue. If it does not survive, loop back — advance `dt_stage` to the stage
the revision needs (often `define` or `ideate`) via the helper (a re-entry to
an earlier stage is permitted) and continue; `state` stays `in-progress`.

### 8. Close the Session

Summarize: the deliverable's final state, the artifact path, key decisions
logged, and which personas challenged it. Recommend the next step — the next
unstarted deliverable in the WBS (via the WBS dashboard skill when present in
the plugin, or by reading the field manifests directly).

**Milestone dashboard refresh.** When this session moved the deliverable's
`state` to `"complete"` (or closed its `persona_review`), the engagement's
status changed — offer the consultant a fresh visual dashboard. If the
engagement already has `output/design-variables.json` (a prior
`consult-dashboard` run set up a theme), regenerate the HTML without prompting
by delegating to the `consult-dashboard-refresher` agent with
`engagement_dir: <engagement-dir>` and `plugin_root: $CLAUDE_PLUGIN_ROOT`; the
agent runs the read-only generator and opens `output/dashboard.html`. If no
theme is configured yet, point the consultant at `/cogni-consult:consult-dashboard`
to set one up. This is a lightweight snapshot — the dashboard reflects the
engagement state at this checkpoint, which is exactly what the consultant wants
to see before picking the next deliverable.

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
  knowledge base per the Research Routing Rule
  (`$CLAUDE_PLUGIN_ROOT/references/research-routing.md`), never raw web
  search; every evidence-backed claim in the artifact carries the
  `sources[]` lineage triple so corrections can cascade.
- **Claims-correction cascade**: when the consultant surfaces a cogni-claims
  correction that reaches a deliverable through its `sources[]` lineage (a
  cited claim was deviated and resolved upstream), flag that deliverable's
  downstream dependents stale so the corrected ground propagates:

  ```bash
  python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
      cascade-stale <field-slug>/<deliverable-slug> --trigger claims_correction
  ```

  Run it on the deliverable whose artifact cites the corrected source; the
  flagged dependents' `lineage_status.trigger` reads `claims_correction` so
  the reason stays traceable. A `"success": false` (node not found, bad dir)
  is non-blocking here too — surface the error and continue. There is no
  automated cogni-claims callback into cogni-consult — this is a
  consultant-initiated step when a correction is noticed.
- **Loop, not gate**: stages may re-enter earlier stages; `state` stays
  `in-progress` until the test stage passes. State transitions go in the
  execution log; per-stage `dt_stage` moves are logged separately to
  `.metadata/stage-log.json` by the stage-advance helper (see *Advancing the
  stage*) — the two logs never mix.
