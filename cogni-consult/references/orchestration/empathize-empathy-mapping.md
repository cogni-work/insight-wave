# Empathize-Stage Empathy Mapping — Fan-Out + Merge

The per-persona empathy-mapping contract for the design-thinking Empathize
stage. The stage fans the per-persona quadrant mapping out to a read-only agent
rather than mapping every persona inline, then merges the returned envelopes and
writes the enriched personas itself. This document is authoritative for the
*fan-out, envelope, merge, and write* mechanics; the *method substance* (the
quadrants, gap-surfacing, and need-extraction) lives in
`references/methods/empathy-mapping.md`, which the agent embodies.

Unlike the Test-stage persona challenge — which delegates its writes across a
skill boundary to `consult-personas` — Empathize is `consult-design-thinking`'s
own stage, so the merge and the persona writes stay in the Empathize section.
There is no cross-skill write owner here: the agent is read-only and the stage
owns every write.

## Who owns what

- **`consult-design-thinking` Empathize stage** runs the fan-out, merges the
  results, and performs the persona writes (the single write owner).
- **`consult-empathy-mapper` agent** builds one persona's empathy map,
  read-only, and returns it in the standard `{success, data, error}` envelope. It
  embodies `references/methods/empathy-mapping.md` Steps 2-4 and performs no Step
  5 write.

## Fan-out

Determine the personas that matter to this deliverable — every `personas/*.json`
whose reality shapes whether the deliverable lands (the shipped advisors plus any
scope-seeded stakeholder whose `context` touches the topic). Dispatch the
read-only `consult-empathy-mapper` agent **once per relevant persona** (the
fan-out), passing `engagement_dir`, `field_slug`, `deliverable_slug`,
`persona_slug`, `plugin_root`, and `evidence_refs` — the on-disk research
synthesis and prior-deliverable paths the stage's gap-check / research-routing
rung already gathered. Each dispatch maps exactly one persona so their inner
worlds stay distinct. This reuses the per-persona-dispatch → envelope → merge
convention established by the Test-stage persona challenge.

## Envelope + merge

Each dispatch returns the standard envelope with `data.empathy_map` (the four
quadrants), `data.needs[]`, `data.gaps[]`, `data.tensions[]`, and
`data.maturity_recommendation`. Merge only the `success: true` envelopes: a
`success: false` envelope is surfaced to the consultant as a dispatch error and
its persona is excluded from every write. Across the surviving envelopes, note
where personas' maps overlap or conflict — a tension between two personas' needs
is often the most important design constraint, and feeds the Define-stage spec
directly.

## The write contract (owned by the Empathize stage)

After the merge, for each `success: true` persona the Empathize stage applies
exactly these writes via `Edit` to `personas/<slug>.json` (mirroring
empathy-mapping.md Step 5 — the write the read-only agent does not perform):

- Populate `empathy_map` with the four returned quadrants and add the returned
  `needs` to the persona's `needs`.
- Promote `maturity` to `"researched"` when the envelope's
  `maturity_recommendation` is `"researched"` (at least two quadrants carry
  evidence-based entries); never advance `source`, and never downgrade a persona
  already `validated`.
- Append one `work_log` entry
  (`{"action_field", "deliverable", "action": "empathy-mapped", "date"}`).

The empathy map lives inside the persona entity — no separate artifact is written
at Empathize; the merged insight and cross-persona tensions flow into the
Define-stage spec.

## Idempotency (the loop may re-enter Empathize)

- **`work_log`:** before appending, scan the persona's `work_log` for an
  `empathy-mapped` entry matching these `(action_field, deliverable)`
  coordinates; append only when none exists, so a re-entry does not
  double-record.
- **`empathy_map` / `needs`:** a re-map refreshes the quadrants and merges needs
  rather than stacking duplicates.
- **`maturity`:** advance via idempotent read-modify-write; a same-state re-set
  is a no-op.

## Advisory + consultant-interactive

The mapping informs the Define spec — it never blocks the loop. In auto-walk
mode, run the fan-out, apply the writes, and surface the merged maps without
pausing. In interactive mode, the Empathize stage keeps its consultant seams: the
start-of-Empathize input-material intake rung runs first, and before the persona
writes the stage presents the merged maps and each persona's key insight for
confirmation; the consultant steers before the writes land. Define and Ideate
remain fully inline — only this per-persona mapping is delegated.

## Zero personas on disk

When no persona files exist at all (the shipped-advisor seeding normally prevents
this), skip the fan-out and continue with the consultant's own stakeholder
knowledge — persona files can be added later without redoing the loop. Nothing is
written and no agent is dispatched.
