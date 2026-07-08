# Test-Stage Persona Challenge — Fan-Out + Merge

The persona-challenge contract for the design-thinking Test stage. The
design-thinking loop delegates the challenge here rather than reimplementing it,
and `consult-personas` (mode: challenge) executes it — so the persona-challenge
write contract lives in exactly one owner. This document is authoritative for the
*fan-out, envelope, and merge* mechanics; the *writes* are owned by
`consult-personas` step 5 (Act as a Persona).

## Who owns what

- **`consult-design-thinking` Test stage** dispatches
  `Skill("cogni-consult:consult-personas")` in challenge mode as an in-session
  handoff naming the deliverable. It does not reimplement any persona write.
- **`consult-personas` step 5** runs the fan-out below, merges the results, and
  performs the three writes (the single write owner).
- **`consult-persona-challenger` agent** generates one persona's objections,
  read-only, and returns them in the standard `{success, data, error}` envelope.

## Fan-out

Determine the relevant personas: both shipped advisors
(`consulting-partner`, `project-manager`) plus any persona whose `context`
touches the deliverable's topic. Dispatch the read-only
`consult-persona-challenger` agent **once per relevant persona** (the fan-out),
passing `engagement_dir`, `field_slug`, `deliverable_slug`, `persona_slug`, and
`plugin_root`. Each dispatch speaks for exactly one persona so voices stay
distinct.

## Envelope + merge

Each dispatch returns the standard envelope with `data.missing[]`,
`data.pushbacks[]`, and `data.acceptance_bar[]` for its persona. Merge only the
`success: true` envelopes: a `success: false` envelope is surfaced to the
consultant as a dispatch error and its persona is excluded from every write,
and a no-draft envelope (`success: true` with empty arrays) produces no writes
at all — nothing was challenged. Merge the surviving
per-persona envelopes into one consolidated result: a single
`## Persona Challenges` section (one block per persona) and one `work_log` append
per persona. This per-persona-dispatch → envelope → merge convention is the one
later per-persona fan-outs (e.g. Empathize per-persona empathy mapping) reuse.

## The write contract (owned by consult-personas step 5)

After the merge, `consult-personas` applies exactly these writes:

- Append one `work_log` entry per persona challenged to that persona's
  `personas/<slug>.json` `work_log` array via `Edit`
  (`{"action_field", "deliverable", "action": "challenged", "date"}`).
- Append (or update) a consolidated `## Persona Challenges` section in the
  deliverable artifact summarizing each persona's challenge and the consultant's
  disposition (accepted / revised / rejected with reason).
- When the field's manifest entry carries a `persona_review` field, advance it
  (`pending` → `in-progress` when challenges start, → `complete` only once every
  challenge is dispositioned); when it doesn't, the `work_log` entries and the
  artifact section are the record — never create the field on an entry lacking
  it.

## Idempotency (the loop may re-enter Test)

- **`work_log`:** before appending, scan the persona's `work_log` for a
  `challenged` entry matching these `(action_field, deliverable)` coordinates;
  append only when none exists, so a re-entry does not double-record.
- **`## Persona Challenges`:** append-or-update the section rather than stacking
  duplicate sections.
- **`persona_review`:** advance via idempotent read-modify-write; a same-state
  re-set is a no-op.

## Advisory + consultant-interactive

The challenge informs — it never blocks completion. In auto-walk mode, run the
fan-out, apply the writes, and surface the merged challenges without pausing. In
interactive mode, the Test stage surfaces the persona dispositions before the
challenge runs (its interactive gate), and the consultant steers before and
disposition-decides after; electing to complete is always available. The
consultant decides what to revise — revision belongs to the deliverable's
producing route.

## Zero personas on disk

When no persona files exist at all (the shipped-advisor seeding normally prevents
this), skip the fan-out and challenge the consultant directly ("what would your
engagement partner push back on?"), noting the acting-persona pass deepens once
personas exist.
