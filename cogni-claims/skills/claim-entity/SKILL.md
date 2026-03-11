---
name: claim-entity
description: |
  Cross-plugin data model for claim verification — defines ClaimRecord, DeviationRecord,
  and ResolutionRecord schemas, status transitions, deviation types, severity levels, and
  workspace layout. Use this skill whenever you need to understand claim data structures,
  create or validate claim records, check what fields a ClaimRecord has, understand deviation
  types or severity levels, or work with the cogni-claims directory layout. Any plugin that submits
  or consumes claims should consult this skill for the contract.
---

# ClaimEntity Contract

This skill defines the shared data model that all plugins use when working with claims. Think of it as the API contract — any plugin submitting claims for verification or reading verification results needs to follow these structures so the system works consistently.

## Core Data Model

Three record types compose the claim lifecycle. For complete field definitions, JSON examples, and batch submission format, see `references/schema.md`.

### ClaimRecord

A single verifiable claim with its current state. Key fields: `id`, `statement`, `source_url`, `source_title`, `submitted_by`, `status`, `deviations[]`, `resolution`.

### DeviationRecord

A specific discrepancy between claim and source. Key fields: `type`, `severity`, `source_excerpt`, `explanation`.

**Deviation types:** `misquotation`, `unsupported_conclusion`, `selective_omission`, `data_staleness`, `source_contradiction`

**Severity levels:** `low`, `medium`, `high`, `critical`

**Language in `explanation` fields:** Because deviation detection is LLM-based and can be wrong, explanations must use hedged language — "the claim appears to overstate", "the source suggests a different figure", "this may indicate a discrepancy" — rather than definitive assertions like "the claim is wrong" or "significantly overstating". This epistemic humility signals to the user that the finding is an assessment to review, not a verdict.

### ResolutionRecord

The user's decision on a deviated claim. Key fields: `action`, `corrected_statement`, `rationale`.

**Resolution actions:** `corrected`, `disputed`, `alternative_source`, `discarded`, `accepted_override`

## Status Lifecycle

```
unverified ──> verified           (no deviations)
unverified ──> deviated           (deviations detected)
unverified ──> source_unavailable (source unreachable)
deviated   ──> resolved           (user resolves all deviations)
any status ──> re-verify          (returns to verified/deviated/source_unavailable)
```

## Workspace Layout

Claim state persists in the calling project's `cogni-claims/` directory:

```
{working_dir}/cogni-claims/
├── claims.json          # Registry of all ClaimRecords
├── sources/{hash}.json  # Cached source content per URL
└── history/{id}.json    # Audit trail per claim
```

## Cross-Plugin Integration

This skill defines the data structures; the `cogni-claims:claims` skill handles submission, verification, and query execution. To submit or query claims from another plugin, invoke `cogni-claims:claims` skill. See `references/schema.md` for batch submission format and query interfaces.

## Design principles

These constraints exist because claim verification involves LLM-based judgment, which means the system can be wrong:

- **User confirmation for all resolutions** — auto-resolving would risk silently accepting bad corrections or dismissing valid deviations. The user is the only authority on whether a deviation matters and what to do about it.

- **Findings are assessments, not facts** — deviation detection compares text using an LLM, which can miss context, misinterpret nuance, or over-flag. Communicating findings as "the source appears to say X" rather than "the claim is wrong" keeps the user appropriately skeptical.

- **Conservative over aggressive** — a false positive (flagging something that's actually fine) wastes the user's time and erodes trust in the system. When a comparison is genuinely ambiguous, not flagging is the safer choice.

- **Always include the source excerpt** — without evidence, the user can't evaluate whether a finding is legitimate. The excerpt is what makes the system useful rather than just noisy.

- **Unverifiable is not verified** — if a source can't be fetched, the claim's accuracy is unknown. Marking it as verified would be dishonest; `source_unavailable` correctly communicates the gap.

## Additional Resources

- **`references/schema.md`** — Full JSON schema, field tables, deviation type definitions, severity criteria, batch submission format, query interfaces
- **`references/workspace-conventions.md`** — Directory structure, file formats, initialization, caching rules
- **`examples/claim-lifecycle.json`** — End-to-end example showing a claim progressing through unverified, deviated, and resolved states with all three record types populated
