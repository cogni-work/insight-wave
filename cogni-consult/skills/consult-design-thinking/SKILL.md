---
name: consult-design-thinking
description: |
  This skill should be used when the user wants to produce a deliverable of a
  cogni-consult engagement by running its design-thinking loop —
  empathize→define→ideate→prototype→test on one deliverable inside an action
  field. Trigger on: "work the deliverable", "run design thinking on
  <deliverable>", "produce the <deliverable> deliverable", "start the DT loop",
  "draft the deliverable", "continue the deliverable", or when a WBS
  dashboard recommendation hands off the next unstarted deliverable. Starting
  a fresh (not-yet-in-progress) deliverable requires a satisfied personas gate:
  when it is unsatisfied the loop routes to consult-personas first before
  opening, so a fresh start may bounce to persona seeding or a waiver. Global
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

In interactive mode, at each stage gate marked **Interactive mode** below (start
of Empathize, the Empathize pre-write merge confirmation, end of Define, end of
Ideate, start of Prototype, Test), before
the stage's write: surface the *reasoning* behind the stage decision (why this
HMW spec, why this ideation method, why this prototype shape, why these persona
dispositions) ahead of the log entry, name exactly what is about to be written,
and pause for the consultant's explicit confirmation — revise on feedback, then
write. The start-of-Empathize gate is the exception in kind: it pauses to gather
input material to ground the deliverable rather than to narrate a write (see
Empathize below). In auto-walk mode, skip the pauses and proceed directly
through each gate. The
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

Conduct the conversation in the resolved **interaction language** (workspace
default, overridden by the user's message language) — independent of the
engagement's `language` field, which is the deliverable axis. See
`$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`.

**Personas gate (fresh starts only).** Before opening the loop for a deliverable
whose `state` is `pending` (a fresh start — not a resume or rework), the
engagement's personas gate must be satisfied, so Empathize (which maps personas)
and Test (which challenges *as* personas) operate on real stakeholders rather
than the degraded fallback. Read the derived rollup — this gate does not
otherwise call it:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/engagement-status.sh <engagement-dir>
```

and branch on `data.personas_gate`:

- If `"pending"` (no `source: "scope-seeded"` persona and no
  `personas/.gate-waiver` marker — the seeded default advisors alone do not
  satisfy it): do **not** open the loop. Dispatch
  `Skill("cogni-consult:consult-personas")` and stop — write nothing. Explain
  that the engagement's personas gate is unsatisfied, and that it flips to
  `satisfied` once scope-specific stakeholders are seeded (define mode) or an
  explicit waiver is recorded (for engagements with no external stakeholders);
  the consultant returns here once it is satisfied.
- If `"satisfied"`: proceed to *Open the Loop* as usual.

This guard applies only to the `pending` (fresh-start) branch below. A
deliverable that is already `in-progress` (resume) or being reopened from
`complete` (rework) is never blocked — the gate is a start-of-loop check, and
once satisfied it stays satisfied, so in practice it only ever gates the
engagement's first deliverable. The Empathize/Test fallbacks remain as a
last-resort safety net but do not trigger for the scope-seeded flow.

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

The empathize-stage per-persona empathy mapping runs as a **read-only fan-out**:
one `consult-empathy-mapper` dispatch per relevant `personas/*.json`, merged and
written by this stage (the agent never writes). It embodies
`$CLAUDE_PLUGIN_ROOT/references/methods/empathy-mapping.md`; the full fan-out,
envelope, merge, write, and idempotency contract is authoritative in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/empathize-empathy-mapping.md`.
Define and Ideate stay fully inline — only this per-persona mapping is delegated.
When `personas/` is empty, say so and continue with the consultant's own
stakeholder knowledge — persona files can be added later without redoing the loop.

**Interactive mode — input material first.** Before the gap-check, run the
Empathize source-material intake rung — the pre-gap-check intake of
consultant-supplied files, pasted text, and URLs, the ingest-into-bound-base
vs. read-direct-first-party sink choice, and its re-entry idempotency — per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/empathize-intake.md`. In
auto-walk mode, skip this prompt and proceed directly to the gap-check on the
scope-time material.

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

**Run the fan-out.** With the evidence context in hand from the rung above,
dispatch `consult-empathy-mapper` once per relevant `personas/*.json` (inputs
`engagement_dir`, `field_slug`, `deliverable_slug`, `persona_slug`,
`plugin_root`, and `evidence_refs` — the research-synthesis and prior-deliverable
paths gathered above). Merge the `success: true` envelopes and apply this stage's
write contract per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/empathize-empathy-mapping.md`: per
persona, `Edit` `personas/<slug>.json` to populate `empathy_map` and `needs`,
promote `maturity` to `"researched"` when the envelope recommends it, and append
one idempotent `empathy-mapped` `work_log` entry keyed by `(action_field,
deliverable)`. Surface the cross-persona overlaps and tensions — they feed the
Define spec. **Interactive mode:** before these writes, present the merged maps
and each persona's key insight, confirm with the consultant, then write.

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
`propagated_at`, plus `kb_ref` when the claim came from the knowledge base —
or, for read-direct first-party material carried in from the Empathize intake
rung, a `file://` `source_url` with `evidence_class: first-party` and no
`kb_ref`; canonical shape in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`),
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
intend to apply — which personas will challenge (per the relevance rule in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-persona-challenge.md`:
shipped advisors plus context-matching personas) and the objections each is
likely to raise — so the consultant can steer the challenge before it runs;
then proceed.

Challenge the draft as the stakeholder personas by **delegating to the
write-contract owner** — do not reimplement the persona-challenge writes inline
here. Dispatch `Skill("cogni-consult:consult-personas")` in challenge mode,
naming this deliverable (its artifact path under `action-fields/<field-slug>/`)
as the in-session handoff. consult-personas fans out the per-persona in-voice
objections (one read-only `consult-persona-challenger` dispatch per relevant
`personas/*.json`), merges the returned `{success, data, error}` envelopes, and
owns the single append-`work_log` / append-`## Persona Challenges` /
advance-`persona_review` write contract — so that contract lives in exactly one
place. The full fan-out, merge, idempotency, and zero-personas fallback contract
is authoritative in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-persona-challenge.md`. Revise
the artifact where a challenge lands; the challenge is advisory and never blocks
completion — the consultant decides what to revise.

If the draft survives (consultant accepts): first record the deliverable's
evidence provenance per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-provenance-gate.md` — no
deliverable completes without a provenance record: reuse the Empathize
`gap-check` decision-log entry when present, otherwise append an
`evidence-provenance-waiver`, and set the resulting `evidence_class` on the
`field.json` deliverable entry. Then, when the deliverable's `chosen_framework`
is non-`null` (already in hand from the Prerequisite Gate), run the
framework-adherence review per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-adherence-review.md` —
dispatch the read-only `consult-framework-adherence-reviewer` agent (inputs
`engagement_dir`, `field_slug`, `deliverable_slug`, `plugin_root`), surface its
advisory `adherence` band and drift findings to the consultant, and record the
outcome as an `adherence-review` decision-log entry keyed by
`(action_field, deliverable)`. This is the framework-adherence rung of the
Three-Layer Quality Gate — advisory, never blocking (auto-walk proceeds to
completion; interactive mode may elect to loop back). A `null`-framework
deliverable skips it entirely and completes with no adherence stop.
Then: one `Edit` of `field.json` sets
`state` → `"complete"` (keep `dt_stage` at `"test"`) and the `evidence_class`,
and one `Edit` of `.metadata/execution-log.json` appends the `in-progress` →
`complete` transition to `transitions[]`. Then run the dependency cascade so every
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
`state` to `"complete"` (or the delegated persona challenge closed its
`persona_review`), the engagement's
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

**Knowledge-base deposit is elected, not automatic.** When this session moved
the deliverable to `complete`, offer to deposit the completed artifact into the
engagement's bound knowledge base (default-on: deposit without pausing in
auto-walk mode, confirm first in interactive mode, never auto-fire without
offering) so future gap-checks and research reuse its findings; the consultant
may decline only on the record via a `kb-deposit-waiver`. The full deposit
signature (reusing `cogni-knowledge:knowledge-ingest-source` verbatim), the
provenance carried into the deposit context, and the waiver shape + idempotency
are in `$CLAUDE_PLUGIN_ROOT/references/orchestration/close-kb-deposit.md`.

**Publishing is elected, not automatic.** When this session moved the
deliverable to `complete`, the consultant *may* now turn it into a
presentation-ready brief for Claude Design with `/cogni-consult:consult-publish`
(slides, web-poster, report, or infographic). Mention it as an available next
step only — never auto-fire it from this loop. Publishing is a deliberate
consultant judgment call about which deliverables are presentation-worthy and
which format fits; the design-thinking loop ends at `complete`.

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
