---
name: consult-personas
description: |
  This skill should be used when the user wants to manage or invoke the acting
  stakeholder personas of a cogni-consult engagement — defining personas from
  the scope's Stakeholder dimension, enriching one with evidence, or having a
  persona challenge a deliverable in its own voice. Trigger on: "set up the
  personas", "add a stakeholder persona", "enrich the persona", "challenge
  this deliverable as the partner", "act as the project manager", "persona
  review", "what would the partner say", or when a design-thinking test stage
  requests a persona challenge. Design-for persona phrasing tied to Double
  Diamond phases ("discover personas", "persona for the define phase")
  belongs to a legacy engagement model no longer in the ecosystem —
  cogni-consult personas act and challenge, they are not phase artifacts.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Acting Stakeholder Personas

Define, enrich, and act as the engagement's stakeholder personas. Personas in
cogni-consult are advisors and critics in the room: every engagement carries
the two shipped defaults — the consulting partner (frameworks and commercial
defensibility) and the project manager (delivery realism) — plus client-side
stakeholders seeded from scoping. The schema and acting contract live in
`$CLAUDE_PLUGIN_ROOT/references/persona-schema.md`; the packaged default
templates live in `$CLAUDE_PLUGIN_ROOT/references/personas/`.

## Workflow

Modes: define (step 3), waive (step 3a), enrich (step 4), challenge (step 5).

### 1. Prerequisite Gate

When arriving via an in-session handoff (e.g. a design-thinking test stage
naming the deliverable), the engagement directory is already known — skip
discovery. Otherwise locate the engagement:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/discover-projects.sh --json
```

and confirm the intended engagement with the user when more than one is
registered. Read `<engagement-dir>/consult-project.json`. If it is missing
(or discovery returned zero engagements): dispatch
`Skill("cogni-consult:consult-setup")` and stop — write nothing. Scoping is
NOT a prerequisite — the two default advisors are useful from day one; only
scope-seeding (step 3) needs a completed scope.

Conduct the conversation in the resolved **interaction language** (workspace
default, overridden by the user's message language) — independent of the
engagement's `language` field, which is the deliverable axis. See
`$CLAUDE_PLUGIN_ROOT/references/interaction-language.md`.

### 2. Ensure the Default Advisors Exist

Check `personas/consulting-partner.json` and `personas/project-manager.json`.
For each that is absent, copy the packaged template:

```bash
cp $CLAUDE_PLUGIN_ROOT/references/personas/consulting-partner.json <engagement-dir>/personas/
cp $CLAUDE_PLUGIN_ROOT/references/personas/project-manager.json <engagement-dir>/personas/
```

Never overwrite an existing persona file — an engagement may have enriched
its defaults, and that history is the consultant's. This step is idempotent;
run it on every invocation.

### 3. Define Personas from the Scope (mode: define)

When the consultant wants engagement-specific stakeholders and
`workflow_state.scope` is `"complete"`: read `scope/key-question.md`, take the
`## Stakeholder` section's prose, and propose 1-4 persona candidates — each
with a kebab-case slug, name, one-line `context`, and a `core_tension`
hypothesis. Confirm with the consultant (names, count, tensions), then
`Write` each confirmed persona to `personas/<slug>.json` per the schema:
`maturity: "hypothesis"`, `source: "scope-seeded"`, a drafted `role` and
`voice`, empty `empathy_map`/`capabilities`/`wants`/`needs`/`work_log`.

Writing at least one `source: "scope-seeded"` persona satisfies the
engagement's `personas_gate` (derived by `engagement-status.sh`) — tell the
consultant the gate has flipped to `satisfied`, so the first design-thinking
deliverable is unblocked.

When scope is not complete, say so and offer the **defaults-only waiver**
(step 3a) — do not dispatch consult-scope unless the consultant wants to scope
now.

### 3a. Defaults-Only Waiver Path (mode: waive)

Some engagements have no external stakeholders worth modelling — the two
shipped advisors are enough. For these, seeding scope personas would only
invent fiction, yet the `personas_gate` still needs a legitimate way to reach
`satisfied` so the first design-thinking deliverable is not deadlocked. The
waiver is that escape, and it is a deliberate, confirmed decision — never a
silent default.

Only take this path when the consultant explicitly confirms it. Ask, in the
resolved interaction language (see step 1), whether the engagement genuinely
has no external stakeholders to model beyond the shipped advisors. Do **not**
write the marker on silence, on ambiguity, or as a fallback when scope-seeding
merely hasn't happened yet — a *pending* gate and a *waived* gate are
different states.

On explicit confirmation, `Write` a `personas/.gate-waiver` marker under the
engagement's `personas/` directory — a small JSON stamp recording who waived,
when, and why:

```json
{
  "waived_by": "<consultant name or handle>",
  "waived_at": "<ISO date>",
  "reason": "No external stakeholders to model; the shipped advisors suffice."
}
```

The gate keys on the marker's **presence** (`engagement-status.sh` does not
parse its contents), so any valid stamp satisfies it — the fields are for the
human audit trail. The extensionless `.gate-waiver` name is deliberate: it is a
presence marker, not a parsed persona file, so it is never mistaken for a
persona slug when scanning `personas/` — keep the literal name (the gate
contract keys on it exactly). Never overwrite an existing `.gate-waiver` or
persona file, and never invent a persona to stand in for the waiver. Confirm to the
consultant that `personas_gate` is now `satisfied`.

### 4. Enrich a Persona (mode: enrich)

Given a persona slug and evidence (consultant knowledge, knowledge-base
synthesis, stakeholder conversations): `Edit` the persona file to populate
`empathy_map`, `needs`, `capabilities`, and `wants`, and advance `maturity`
to `"researched"` when at least two quadrants carry evidence-based entries
(`"validated"` only when the consultant confirms against the real
stakeholder). Append a `work_log` entry
(`{"action_field": ..., "deliverable": ..., "action": "enriched", "date": ...}`)
when the enrichment happened in service of a specific deliverable; omit the
entry for general enrichment.

### 5. Act as a Persona (mode: challenge)

Given a deliverable (its artifact path under
`action-fields/<field-slug>/`) and one or more persona slugs — default to
both shipped advisors plus any persona whose `context` touches the
deliverable's topic — run the challenge as a **per-persona fan-out** and own
its writes:

1. **Fan out the objections (read-only).** For each relevant persona, dispatch
   the read-only `consult-persona-challenger` agent (inputs `engagement_dir`,
   `field_slug`, `deliverable_slug`, `persona_slug`, `plugin_root`); it adopts
   that persona's `voice` bounded by its `capabilities`/`wants`/`needs`/
   `core_tension` and returns the standard `{success, data, error}` envelope
   carrying the structured challenge (`missing[]`, `pushbacks[]`,
   `acceptance_bar[]`). The agent never writes. The fan-out, envelope, and
   merge convention is authoritative in
   `$CLAUDE_PLUGIN_ROOT/references/orchestration/test-persona-challenge.md`.
2. **Merge and present.** Merge the per-persona envelopes and surface each
   persona's challenge in character (what's missing, push-backs, acceptance
   bar). The challenge informs — it never blocks.
3. **Own the write contract (single owner).** This is the one place the
   persona-challenge writes live: append one `work_log` entry per persona
   challenged to that persona's `personas/<slug>.json` `work_log` array via
   `Edit` (`{"action_field": "<field-slug>", "deliverable":
   "<deliverable-slug>", "action": "challenged", "date": "<ISO date>"}`) —
   idempotent: skip a persona already carrying a `challenged` entry for these
   `(action_field, deliverable)` coordinates; append (or update) a consolidated
   `## Persona Challenges` section in the deliverable artifact summarizing each
   persona's challenge and the consultant's disposition (accepted / revised /
   rejected with reason); when the field's manifest entry carries a
   `persona_review` field, advance it (`pending` → `in-progress` when
   challenges start, → `complete` only once the consultant has dispositioned
   every challenge) — never create the field on an entry that lacks it.
4. **Zero personas on disk.** When no persona files exist at all (step 2's
   seeding normally prevents this), run the challenge against the consultant
   directly ("what would your engagement partner push back on?") and note the
   acting-persona pass deepens once personas exist; no agent is dispatched.

The challenge informs — it never blocks. The consultant decides what to
revise; revision itself belongs to the deliverable's producing route, not to
this skill.

### 6. Close the Session

Summarize what changed: personas created/enriched, deliverables challenged
and by whom, and any challenge the consultant still needs to disposition.
When a challenged deliverable needs rework, point at its producing route as
the next step.

## Important Notes

- **Acting, not gating**: personas challenge in their own voice and ground
  every demand in their `capabilities`/`wants`/`needs`; they advise the
  consultant, who decides. See the Acting Contract in
  `$CLAUDE_PLUGIN_ROOT/references/persona-schema.md`.
- **Never overwrite**: existing `personas/*.json` files are enriched via
  `Edit`, never re-copied from templates — enrichment history survives.
- **State ownership**: persona files own persona state; deliverable state
  stays in the field's `field.json`. This skill never edits
  `consult-project.json`.
- **Personas gate**: writing any `source: "scope-seeded"` persona (step 3) or
  an explicit `personas/.gate-waiver` marker (step 3a) satisfies the
  engagement's `personas_gate`; the two shipped advisors alone never do. The
  waiver is the deliberate alternative for engagements with no external
  stakeholders — it distinguishes a gate that is *pending* (not seeded, no
  waiver) from one *deliberately waived*. Like every write here, the marker
  lives under `personas/`, never in `consult-project.json`.
- **WBS coordinates everywhere**: `work_log` entries are addressed by
  `action_field` + `deliverable`, like every log in the plugin — there are
  no phases.
