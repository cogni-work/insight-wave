# Test Evidence-Provenance Gate

The completion-time provenance contract for the design-thinking Test stage.
When the draft survives (consultant accepts), this contract runs **before**
the `state` → `"complete"` write in the design-thinking loop; no deliverable
completes without a provenance record in the decision-log. The design-thinking
loop points here; the contract below is authoritative.

**Record the provenance before the completion write.** Check
`.metadata/decision-log.json` for an entry whose
`(action_field, deliverable)` coordinates match this deliverable and whose
`kind` is `"gap-check"` (the Empathize stage records one per the Research
Routing Gap-Check Recording contract). If one exists, the provenance record is
already present — set `evidence_class` on the `field.json` deliverable entry to
the class that evidence represents (e.g. `"desk-research"`,
`"primary-research"`, `"expert-interview"`) in the same `state` → `"complete"`
`Edit`. If none exists, append an `evidence-provenance-waiver` entry to
`decisions[]` naming the class and the consultant's rationale —
`{"id": "d-NNN", "kind": "evidence-provenance-waiver", "action_field": ...,
"deliverable": ..., "evidence_class": "<class>", "rationale": "<why complete
without a gap-check>", "timestamp": ...}` — and set the matching
`evidence_class` on the deliverable entry. The `evidence_class` vocabulary and
the `evidence-provenance-waiver` entry shape are defined in
`$CLAUDE_PLUGIN_ROOT/references/data-model.md`.
