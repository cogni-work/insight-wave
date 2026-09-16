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

The Prerequisite Gate (step 1) already reads `field.json`, so no extra read is
needed. When it is non-`null`, resolve its one-line **Structure signature** from
the registry's framework table (for a `combo:`, resolve both) and carry it into
the **Define** and **Prototype** stages below: it shapes how the problem is
framed and how the artifact body is organized. The registry is thin by design —
it pins the signature and the stable key; supply the framework's depth at
runtime, following the registry `slug` cell's first-party link where it has one
and otherwise drawing on your own knowledge.

When `chosen_framework` is `null` — a legacy deliverable created before a
framework was chosen, or a deliberate no-framework choice — run Define and
Prototype exactly as written below, on their default framing and outline, with
no framework structuring. Those stages do not restate this rule. The framework
only adds shape when present; it never blocks production when absent.

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

### Interaction mode

By default this loop runs as an **auto-walk**: it writes each stage's artifact
and log entry as it goes, surfacing the resulting entries — fast, and right for
an obvious-shape deliverable. To steer the work, the consultant opts into
**interactive mode** (also *transparent mode*) at loop entry ("run it
interactively", "transparent mode", "with confirmation gates") or as a
per-engagement default stated at the start. That auto-walk default stands for a
fresh start (`pending`) and a plain resume (`in-progress`). A **rework re-entry**
(Step 2's `complete` → `in-progress` branch) opens in **interactive mode**
instead — a reopened deliverable's intent is unsettled — though the consultant
may opt back to auto-walk for the pass by saying so at re-entry. That default is
derived at re-entry from the stored `state`, never stored as a mode. Interaction
mode is **ephemeral** — it governs only this session's conversation flow and is
never written to `field.json`, `consult-project.json`,
or any log; state-write ownership and the logging contract are identical in both
modes.

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

Every `dt_stage` boundary below moves the stage through the guarded helper
rather than a free-text `Edit` of `field.json`. The helper validates the
transition (rejecting an unknown stage name and a forward jump that skips a
stage), writes `dt_stage` via an idempotent read-modify-write, and appends a
per-stage move to `.metadata/stage-log.json` so the loop's iterations leave a
trail:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/dt-stage-advance.sh \
    <engagement-dir> <field-slug> <deliverable-slug> <target-stage>
```

A single-step forward advance, an idempotent same-stage re-set, and a re-entry
to any earlier stage (the loop may iterate) are all permitted; a forward jump
that skips a stage is refused with `success: false`. On a legacy `field.json`
whose deliverable has no `dt_stage`, the helper degrades gracefully and logs the
move with `from: null`. On a `success: false` (a refused jump, a missing
deliverable, an unreadable manifest) do not proceed past the boundary — an
unwritten `dt_stage` leaves the loop state inconsistent; surface the error and
resolve it before retrying. Should the helper be absent (an older install), fall
back to a free-text `Edit` of `field.json` setting `dt_stage` directly. Where a
stage below says "advance `dt_stage` → `"X"`", run this helper with
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
the deliverable", a revision request), confirm the re-entry first — including
the stage the rework needs — then capture the improvement intent as a
`rework-intent` entry (below), then one `Edit` of
`field.json` sets `state` back to `"in-progress"`, advance `dt_stage` to the
stage the rework needs (often `define` or `ideate`) via the helper, and one
`Edit` of `.metadata/execution-log.json` appends the `complete` →
`in-progress` transition to `transitions[]`.

**Capture the improvement intent.** Ask a short question of the shape "what
should this deliverable do better that it does not do today?" and append the
consultant's verbatim answer to `.metadata/decision-log.json`'s `decisions[]` as
`{"id": "d-NNN", "kind": "rework-intent", "action_field": "<field-slug>",
"deliverable": "<deliverable-slug>", "intent": "<consultant's verbatim answer>",
"target_stage": "<stage the rework re-enters>", "timestamp": "<ISO>"}` —
discrete keys, no prose `decision` string, mirroring the gap-check and
adherence-review shapes; `target_stage` is the value passed to
`dt-stage-advance.sh`, so record and write cannot drift. The append is
idempotent *within one reopen*, not across reopens: look for the most recent
`rework-intent` entry in `decisions[]` for these `(action_field, deliverable)`
coordinates — the same entry Define reads — then read `.metadata/execution-log.json`'s `transitions[]` for the
same coordinates. When no `"to": "complete"` transition carries a `timestamp`
later than that entry's, the entry belongs to this same open episode — reuse it
rather than appending a second. Match on `"to"`, not on the word *complete*: the
reopen's own `complete` → `in-progress` transition is a `"from": "complete"`, and
it is appended moments after the intent entry, so reading it as an episode close
would defeat the guard on every re-run. A `"to": "complete"` transition does
close the episode, so the next reopen keys a fresh entry: successive reworks
carry successive intents.
That is what separates this kind from the append-once waiver kinds, which stay
at one entry per deliverable for the engagement's life. The ordering is
load-bearing: capture before both the `field.json` state `Edit` and the
`dt-stage-advance.sh` call, so an abandoned re-entry never leaves an advanced
stage with no recorded intent. It runs in both modes — a write input, not a
confirmation gate: opting back to auto-walk drops the stage pauses, never this
question.

Because the deliverable's content is about to change, flag its downstream
dependents stale now — before the rework begins — so the consultant sees the
blast radius up front:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
    cascade-stale <field-slug>/<deliverable-slug> --trigger deliverable_update
```

Name the `data.newly_flagged` deliverables in plain words, not by slug path. An
empty list means nothing became stale *this run* — `data.already_stale` and
`data.downstream_count` say whether dependents are still waiting, so check them
before sounding an all-clear. A `"success": false` (node not found, bad dir) is
non-blocking — surface the error and proceed with the rework.

### 3. Empathize

The empathize-stage per-persona empathy mapping runs as a **read-only fan-out**
(the agent never writes; this stage merges and writes), embodying
`$CLAUDE_PLUGIN_ROOT/references/methods/empathy-mapping.md`. Define and Ideate
stay fully inline — only this per-persona mapping is delegated. When `personas/`
is empty, say so and continue with the consultant's own stakeholder knowledge —
persona files can be added later without redoing the loop.

**Interactive mode — input material first.** Before the gap-check, run the
Empathize source-material intake rung — consultant-supplied files, pasted text,
and URLs, the ingest-into-bound-base vs. read-direct-first-party sink choice,
and its re-entry idempotency — per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/empathize-intake.md`. In
auto-walk mode, skip this prompt and proceed directly to the gap-check on the
scope-time material.

Research for this stage follows the Research Routing Rule in
`$CLAUDE_PLUGIN_ROOT/references/research-routing.md` — the canonical
contract for every research run in the engagement. Start with the gap-check
rung: dispatch `Skill("cogni-knowledge:knowledge-query")` with
`--knowledge-slug <plugin_refs.knowledge_base>` for the deliverable's topic.
Record each gap-check per the Gap-Check Recording contract in the Research
Routing Rule — append one entry to `.metadata/decision-log.json`'s `decisions[]`
array tagged `"kind": "gap-check"` (`kind`, not `type`), carrying the
**verbatim** question plus the coverage outcome as discrete keys, never folded
into a prose `decision` string and with no `evidence_refs`, so gap-checks stay
filterable and the routing decision replays programmatically:
`{"id": "d-NNN", "kind": "gap-check", "action_field": ..., "deliverable":
..., "question": "<verbatim --question>", "theme_label": <label-or-null>,
"verdict": "covered"|"partial"|"uncovered", "top_hit": "<page-slug>"|null,
"top_score": <score>|null, "timestamp": ...}`.
When the base has no coverage, escalate to the full inverted pipeline (or
the `--source wiki` re-run on a populated base) per the rule, and copy the
finalized synthesis to `action-fields/<field-slug>/research/<topic-slug>.md`
so this deliverable — and later ones — find it at a stable path.

**Run the fan-out.** With the evidence context in hand from the rung above,
dispatch `consult-empathy-mapper` once per relevant `personas/*.json` (inputs
`engagement_dir`, `field_slug`, `deliverable_slug`, `persona_slug`,
`plugin_root`, `interaction_language` — the language resolved in step 0, as an
ISO 639-1 code — and `evidence_refs`, the research-synthesis and prior-deliverable
paths gathered above). Merge the `success: true` envelopes and apply this
stage's write contract — fan-out, envelope, merge, write, and idempotency all
authoritative in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/empathize-empathy-mapping.md`: per
persona, `Edit` `personas/<slug>.json` to populate `empathy_map` and `needs`,
promote `maturity` to `"researched"` when the envelope recommends it, and append
one idempotent `empathy-mapped` `work_log` entry keyed by `(action_field,
deliverable)`. Surface the cross-persona overlaps and tensions — they feed the
Define spec. **Interactive mode:** before these writes, present the merged maps
and each persona's key insight, confirm with the consultant, then write.

Close the stage by advancing `dt_stage` → `"define"` via the helper.

### 4. Define

Read `$CLAUDE_PLUGIN_ROOT/references/methods/hmw-synthesis.md` and sharpen the
deliverable's problem spec from the empathize outputs plus the field's `framing`.
On a rework re-entry both of those stay in play, joined by the most recent
`rework-intent` entry for this deliverable's `(action_field, deliverable)`
coordinates, recorded in Step 2 — which ranks first among the three, since the
consultant reopened the deliverable for a stated reason. It re-ranks the inputs,
it does not replace them: the empathize outputs still describe the stakeholders
and the field's `framing` still bounds the work. Where that intent conflicts with
an inherited persona objection from the previous pass, the consultant's stated
intent wins; name the conflict in the locked spec's `rationale` below. Lock 1-3
HMW questions with the consultant. When a framework lens is in play (see *The
framework lens* above), let its Structure signature frame how you organize the
problem and the approach — e.g. `mece-issue-tree` decomposes the problem into
mutually-exclusive, collectively-exhaustive branches before drafting, while
`pyramid-principle` leads with the answer and groups the supporting arguments
beneath it. For a `combo:` choice, let the first signature frame the problem and
the second the approach. When sharpening the spec surfaces an evidence gap (an
assumption the consultant cannot ground), route the research per
`$CLAUDE_PLUGIN_ROOT/references/research-routing.md` before locking — a spec
built on an unverified assumption fails at the test stage anyway.

**Interactive mode:** before logging, present the locked 1-3 HMW questions and
the framing reasoning that produced them, including how the framework lens (if
any) shaped them.

Append the locked spec to `.metadata/decision-log.json`'s `decisions[]` array
(`{"id": "d-NNN", "action_field": ..., "deliverable": ..., "decision":
"<locked problem framing>", "rationale": ..., "evidence_refs": [...],
"timestamp": ...}`). Then advance `dt_stage` → `"ideate"` via the helper.

### 5. Ideate

Read `$CLAUDE_PLUGIN_ROOT/references/methods/guided-ideation.md` and run the
diverge→cluster→converge→sketch flow against the locked spec. Keep it
proportionate — a deliverable with an obvious shape needs one quick pass, not
a full workshop.

**Interactive mode:** before logging, surface the chosen ideation method and why
it fits this spec at the proportion above.

Append the method selection to `.metadata/method-log.json`'s `methods[]` array
(`{"action_field": ..., "deliverable": ..., "proposed": [...], "selected":
[...], "rationale": ...}`). Then advance `dt_stage` → `"prototype"` via the
helper.

### 6. Prototype

**Interactive mode:** before drafting, surface the prototype direction — the
chosen approach and how the framework lens (if any) will shape the artifact
body.

Draft the deliverable artifact at
`action-fields/<field-slug>/<deliverable-slug>.md` — Obsidian markdown with
YAML frontmatter exactly per the data model: `slug`, `action_field`,
`sources[]` (each entry the lineage triple `source_url`, `entity_ref`,
`propagated_at`, plus `kb_ref` when the claim came from the knowledge base —
or, for read-direct first-party material carried in from the Empathize intake
rung, a `file://` `source_url` with `evidence_class: first-party` and no
`kb_ref`; canonical shape in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`),
and `updated`.

Structure the body from the loop's outputs: the problem (define), options
considered (ideate), the chosen approach, and the content itself. When a
framework lens is in play (see *The framework lens* above), organize the
artifact body to its Structure signature rather than that default outline —
e.g. `pyramid-principle` → lead with the answer, then MECE-grouped supporting
arguments; `scqa` → Situation → Complication → Question → Answer;
`journey-process` → sequential stages along the path. For a `combo:` choice,
apply both signatures together (typically one frames the opening, the other the
body). Every evidence-backed claim carries a `sources[]` entry. Then advance
`dt_stage` → `"test"` via the helper.

### 7. Test

**Interactive mode:** before challenging, surface the persona dispositions you
intend to apply — which personas will challenge (per the relevance rule in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-persona-challenge.md`:
shipped advisors plus context-matching personas) and the objections each is
likely to raise — so the consultant can steer the challenge before it runs.

Challenge the draft as the stakeholder personas by **delegating to the
write-contract owner** — do not reimplement the persona-challenge writes inline
here. Dispatch `Skill("cogni-consult:consult-personas")` in challenge mode,
naming this deliverable (its artifact path under `action-fields/<field-slug>/`)
as the in-session handoff. consult-personas fans out the per-persona in-voice
objections (one read-only `consult-persona-challenger` dispatch per relevant
`personas/*.json`), merges the returned `{success, data, error}` envelopes, and
owns the single append-`work_log` / append-`## Persona Challenges` /
advance-`persona_review` write contract, so that contract lives in one place;
the full fan-out, merge, idempotency, and zero-personas fallback contract is
authoritative in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-persona-challenge.md`. Revise
the artifact where a challenge lands — advisory, never blocking: the consultant
decides what to revise.

If the draft survives (consultant accepts): first record the deliverable's
evidence provenance per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-provenance-gate.md` — no
deliverable completes without a provenance record: reuse the Empathize
`gap-check` decision-log entry when present, otherwise append an
`evidence-provenance-waiver`, and set the resulting `evidence_class` on the
`field.json` deliverable entry. The three rungs that follow are the Three-Layer
Quality Gate's advisory tiers: each records its outcome as a decision-log entry
keyed by `(action_field, deliverable)`, and none of them blocks completion.

Then, when the deliverable's `chosen_framework` is non-`null` (already in hand
from the Prerequisite Gate), run the framework-adherence review per
`$CLAUDE_PLUGIN_ROOT/references/orchestration/test-adherence-review.md` —
dispatch the read-only `consult-framework-adherence-reviewer` agent (inputs
`engagement_dir`, `field_slug`, `deliverable_slug`, `plugin_root`,
`interaction_language`), surface its advisory `adherence` band and drift
findings to the consultant, and record the outcome as an `adherence-review`
entry. Auto-walk proceeds to completion; interactive mode may elect to loop
back. A `null`-framework deliverable skips this rung entirely.

Next, the language-polish rung — the register-quality tier. Dispatch
`Skill("cogni-publishing:copywriter")` over the deliverable artifact with
`FILE_PATH=<engagement-dir>/action-fields/<field-slug>/<deliverable-slug>.md`
and `--scope=tone` — register-only, so it skips restructuring and never
re-imposes the framework structure; only the prose register is polished (clause
length, Floskel and Denglish reduction per the copywriter's German style rules).
It natively freezes every `{{asm:<slug>}}` placeholder and the `## Persona
Challenges` table byte-identical and excludes the frontmatter `sources[]`
lineage, so the tone pass cannot corrupt a resolver-critical token. It **writes
the polish in place**, backing the original up to
`<engagement-dir>/action-fields/<field-slug>/.<deliverable-slug>.md`, so surface
the resulting diff to the consultant **after** the write and let them **accept
or reject** — the `chosen_framework` headings are that gate's safeguard against
any heading rewording. On reject, restore the deliverable from that backup
dotfile so a rejected polish never lingers on disk; on accept (and on
skip/error, where no polish was written) the dotfile is redundant and may be
removed — the next polish run overwrites it either way. Record the outcome as a
`copywriter-polish` entry (`{"id": "d-NNN", "kind": "copywriter-polish",
"action_field": <field-slug>, "deliverable": <deliverable-slug>, "outcome":
"accepted" | "rejected" | "skipped" | "error", "timestamp": <iso8601>}`).
Whether the polish runs, is skipped, is rejected, or errors, the loop proceeds
unchanged — a copywriter failure is swallowed as a WARN, never a halt — and the
rung is `output_language`-agnostic: it polishes whatever language the
deliverable is written in.

Next, the promote-check rung — the assumption-registration tier that keeps
load-bearing planning numbers in the engagement's single source of truth. Run it
per `$CLAUDE_PLUGIN_ROOT/references/orchestration/test-promote-check.md`: scan
the finished artifact for bare quantified planning literals (market sizes, rates,
headcounts, price points) written directly rather than cited as a
`{{asm:<slug>}}` placeholder backed by the engagement-root `assumptions.json`
registry; propose registry entries (`provenance_type` + capped `status`), convert
accepted occurrences to their placeholders, verify with a `resolve-assumptions.py`
dry-run (fail-loud), and record an `assumption-promotion` entry. This rung
**acts by default** — it promotes rather than only warning — but the consultant
may opt out on the record, and it is idempotent on a Step-7 resume.

Then: one `Edit` of `field.json` sets `state` → `"complete"` (keep `dt_stage` at
`"test"`) and the `evidence_class`, and one `Edit` of
`.metadata/execution-log.json` appends the `in-progress` → `complete` transition
to `transitions[]`. Then run the dependency cascade over the deliverables that
listed this one in `depends_on[]`:

```bash
python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
    cascade-stale <field-slug>/<deliverable-slug> --trigger deliverable_update
```

Report the result in the session summary on the Step 2 cascade terms above —
plain-word names, `data.already_stale` alongside an empty `newly_flagged`, a
`"success": false` non-blocking against the completion — then
continue. If it does not survive, loop back — advance `dt_stage` to the stage
the revision needs (often `define` or `ideate`) via the helper (a re-entry to
an earlier stage is permitted) and continue; `state` stays `in-progress`.

### 8. Close the Session

Summarize in business terms, not raw state values or log ids: the deliverable is
finished, the artifact path (kept as a path), what was decided and why, which
personas challenged it, and the Test-stage promote-check outcome (assumptions
promoted to the registry, or a recorded opt-out). Recommend the next step — the
next unstarted deliverable in the WBS (via the WBS dashboard skill when present,
or by reading the field manifests directly).

**Close budget: at most six lines** — one result, at most three substance, one
artifact, one next-step. Six is the ceiling on the whole close: a trailing offer
spends one of the substance lines rather than adding a seventh, so a close that
makes an offer carries at most two other substance lines. At most one table, and
only at four or five rows — canonical (d), reached through the overlay
`$CLAUDE_PLUGIN_ROOT/references/user-facing-output.md`; anything smaller is
prose, and its overflow line spends a substance line too. Announce before *or* report after, never both — canonical (e) of
that same register. The next-step line carries exactly one recommendation,
generalizing `$CLAUDE_PLUGIN_ROOT/skills/consult-resume/SKILL.md`
`## Important Notes` ("One recommendation") to every close.

**Milestone actions.** When this session moved the deliverable's `state` to
`"complete"` (or the delegated persona challenge closed its `persona_review`),
refresh the two derived views below. The two elective rungs after them fire only
on the `state` → `"complete"` leg, never on a persona-review close.

**One offer per close.** A consultant-facing *offer* is a trailing item asking
the consultant to decide this turn — at most one per close. Rank the available
offers and emit the top-ranked one: 1. knowledge-base deposit, 2. publishing, 3.
dashboard theme setup — because a deferred deposit stops compounding into the
next deliverable's gap-check, while publishing loses nothing by waiting. The
rest go unmentioned and surface next turn if the emitted one is declined; an
offer already declined on the record (a logged `kb-deposit-waiver`) leaves the
ranking rather than resurfacing every close. An item that fires without asking
is a result, not an offer, and belongs on the artifact line. Rank from the live
conversation only, never from a stored field — `### Interaction mode` keeps the
mode ephemeral. The next-deliverable recommendation is the next-step line, not
an offer.

**Milestone dashboard refresh.** If the engagement already has
`output/design-variables.json` (a theme is configured), regenerate the HTML
without prompting: delegate to the `consult-dashboard-refresher` agent with
`engagement_dir: <engagement-dir>` and `plugin_root: $CLAUDE_PLUGIN_ROOT`; it
runs the read-only generator and opens `output/dashboard.html`. If no theme is
configured yet, pointing the consultant at `/cogni-consult:consult-dashboard` to
set one up is the rank-3 offer.

**Milestone README refresh.** Also run
`python3 $CLAUDE_PLUGIN_ROOT/scripts/generate-engagement-readme.py "<engagement-dir>"` —
unconditional within these milestone actions, not theme-gated and
non-fatal: on failure,
warn and continue. It emits nothing to the consultant, so it is never an offer
and never counts against the offer budget.

**Knowledge-base deposit is elected, not automatic** (rank 1). Offer to deposit
the completed artifact into the engagement's bound knowledge base (default-on:
deposit without pausing in auto-walk mode, confirm first in interactive mode,
never auto-fire without offering) so future gap-checks reuse its findings; the
consultant may decline only on the record via a `kb-deposit-waiver`. The deposit
signature (reusing `cogni-knowledge:knowledge-ingest-source` verbatim), the
provenance it carries, and the waiver shape + idempotency are in
`$CLAUDE_PLUGIN_ROOT/references/orchestration/close-kb-deposit.md`.

**Publishing is elected, not automatic** (rank 2). The consultant *may* now turn
the deliverable into a
presentation-ready brief for Claude Design with `/cogni-consult:consult-publish`
(slides, web-poster, report, or infographic).
Mention it as an available next step only — never auto-fire it: format choice
is the consultant's judgment call, and the loop ends at `complete`.

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
- **Claims-correction cascade**: when the consultant surfaces a resolved
  `cogni-workspace:claims` correction, propagate the corrected ground — the script depends
  on what the correction touched:

  *A deliverable's cited source* (a claim in its `sources[]` lineage was
  deviated then resolved upstream) — flag that deliverable's downstream
  dependents stale, so its `lineage_status.trigger` reads `claims_correction`:

  ```bash
  python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
      cascade-stale <field-slug>/<deliverable-slug> --trigger claims_correction
  ```

  *A claim-type assumption's value* (its ClaimRecord is `resolved` with
  `resolution.action: corrected`) — write the corrected value back, then fan
  staleness to every deliverable citing that assumption:

  ```bash
  python3 $CLAUDE_PLUGIN_ROOT/scripts/submit-assumption-claim.py <engagement-dir> \
      resolve-propagate <asm-id> --corrected-value <value> [--claim-id <id>]
  python3 $CLAUDE_PLUGIN_ROOT/scripts/deliverable-graph.py <engagement-dir> \
      cascade-stale --assumption <asm-id> --trigger assumption_update
  ```

  `resolve-propagate` mutates the assumption of record (demotes `verified` →
  `reviewed`) and is **fail-loud** (`"success": false` / exit 1) — surface
  `data.failed_check` and STOP, don't cascade a value that never changed. Every
  `cascade-stale` form is non-blocking (exit 0). `cogni-workspace:claims` has no push
  callback into cogni-consult, so this stays a consultant-initiated step.
- **Loop, not gate**: stages may re-enter earlier stages; `state` stays
  `in-progress` until the test stage passes. State transitions go in the
  execution log; per-stage `dt_stage` moves are logged separately to
  `.metadata/stage-log.json` by the stage-advance helper (see *Advancing the
  stage*) — the two logs never mix.
