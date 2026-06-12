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
  belongs to legacy engagements of the archived cogni-consulting plugin —
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

When `language` is set, hold the conversation in that language; technical
terms, slugs, and file names stay English.

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

When scope is not complete, say so and offer the defaults-only path — do not
dispatch consult-scope unless the consultant wants to scope now.

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
deliverable's topic:

1. Read the persona file and the deliverable artifact.
2. Adopt the persona: speak in its `voice`, bounded by its `capabilities`,
   aiming at its `wants`, holding the work to its `needs`, colored by its
   `core_tension`.
3. Return the structured challenge, in character:
   - **What's missing** — gaps the persona would spot first
   - **Push-backs** — claims or choices they would contest, and why
   - **Acceptance bar** — what would make this persona accept the deliverable
4. Record it: append a `work_log` entry to that persona's
   `personas/<slug>.json` (`{"action_field": "<field-slug>", "deliverable":
   "<deliverable-slug>", "action": "challenged", "date": "<ISO date>"}`) via
   `Edit`, and append (or update) a `## Persona Challenges` section in the
   deliverable artifact summarizing each persona's challenge and the
   consultant's disposition (accepted / revised / rejected with reason).
5. When the field's manifest entry carries a `persona_review` field, advance
   it (`pending` → `in-progress` when challenges start, → `complete` when the
   consultant has dispositioned every challenge); when it doesn't, the
   `work_log` entries and the artifact section are the record — never create
   the field on an entry that lacks it.

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
- **WBS coordinates everywhere**: `work_log` entries are addressed by
  `action_field` + `deliverable`, like every log in the plugin — there are
  no phases.
