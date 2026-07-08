# Close Knowledge-Base Deposit Contract

The elected, default-on deposit of a completed deliverable into the
engagement's bound knowledge base at the Close stage, plus the recorded
opt-out (`kb-deposit-waiver`) and re-entry idempotency. The design-thinking
loop points here; the contract below is authoritative.

**Knowledge-base deposit is elected, not automatic.** When this session moved
the deliverable to `complete`, the completed artifact can compound the
engagement's bound knowledge base so future engagements' gap-checks and research
reuse its distilled findings. Offer to deposit it — default-on, the same
elected-not-automatic posture as the Close-stage publishing mention in the
design-thinking loop: in auto-walk mode deposit without
pausing; in interactive mode confirm first; never auto-fire without offering.
Deposit reuses `cogni-knowledge:knowledge-ingest-source` verbatim (no
cogni-knowledge change — the raw deliverable markdown is the source body, claims
are auto-extracted, and a `type: source` page lands in the bound base):

```
Skill(cogni-knowledge:knowledge-ingest-source,
      --file <engagement-dir>/action-fields/<field-slug>/<deliverable-slug>.md,
      --knowledge-slug <plugin_refs.knowledge_base>,
      --title "<deliverable title>",
      --theme "Consulting Deliverables")
```

`<plugin_refs.knowledge_base>` is the bound-base slug already read at the Step 1
Prerequisite Gate (the same slug every research run passes as `--knowledge-slug`);
the artifact path is the one written at the Prototype stage (SKILL.md Step 6)
and revised through Test. Carry the deliverable's
provenance into the deposit context — its `field.json` `evidence_class` and the
`(action_field, deliverable)` `gap-check` / `evidence-provenance-waiver` record
already in `.metadata/decision-log.json` (from the Step 7 completion gate) —
so the deposited finding stays traceable to the evidence class behind it.

**Opt-out with a recorded reason.** The consultant may decline the deposit, but
only on the record — append a `kb-deposit-waiver` to `.metadata/decision-log.json`
`decisions[]`, discriminated by `"kind": "kb-deposit-waiver"`, carrying the
deliverable's `(action_field, deliverable)` coordinates, its `evidence_class`,
the consultant's `rationale`, and a `timestamp` (decision-log only — no new state
file, no duplicated state on `field.json`). The waiver shape is defined in
`$CLAUDE_PLUGIN_ROOT/references/data-model.md`. **Idempotency (the loop re-runs
Step 8 on resume):** the deposit itself is safe to re-offer because
`knowledge-ingest-source` runs its own diff-before-write dedup gate (a covering
page is detected, not re-created); for the opt-out, before appending a
`kb-deposit-waiver` first scan `decisions[]` for an existing `kb-deposit-waiver`
with the same `(action_field, deliverable)` coordinates and append only when none
exists — the same "if none exists, append" check the Step 7
`evidence-provenance-waiver` uses, so a re-run neither double-deposits nor
double-logs.
