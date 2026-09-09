# Verification Protocol

## Overview

This document covers the quality principles and edge-case rules for claim verification. The step-by-step verification methodology (fetching, comparison dimensions, severity criteria, evidence extraction) lives inline in the `claim-verifier` agent where it is used at runtime.

## Quality Principles

### Epistemic Humility

Deviation detection is performed by an LLM reading source text. This process is:
- **Not infallible** — LLMs can misinterpret context, miss nuance, or over-flag
- **Context-dependent** — the same statement may be accurate in one context and misleading in another
- **Assessment-based** — findings are assessments to be reviewed by the user, not verdicts

Always communicate findings with appropriate uncertainty:
- "This claim appears to diverge from the source" (not "This claim is wrong")
- "The source may not support this conclusion" (not "The source contradicts this")
- "The excerpt suggests a different figure" (not "The claim uses the wrong number")

### Unverifiable Is Not Verified

When a source cannot be fetched or inspected, record the claim as `source_unavailable`, never
`verified`. An unavailable source leaves accuracy unknown; treating absence of contrary evidence
as successful verification would overstate what the process actually checked.

### Conservative Detection

When in doubt, err toward not flagging a deviation:
- If the claim is a reasonable paraphrase, do not flag as misquotation
- If the inference is plausible given the source, do not flag as unsupported
- If the omitted context does not materially change meaning, do not flag as selective omission
- Only flag `critical` severity when the deviation is unambiguous

### Batch Consistency

When verifying multiple claims against the same source:
- Apply the same standards consistently across all claims
- Do not let a deviation in one claim bias assessment of another
- Each claim stands on its own merits

### Ambiguous Comparisons

If a claim-source comparison is genuinely unclear — the source is ambiguous, the claim could be read multiple ways, or the context is insufficient to judge — set status to `deviated` with severity `low` and explain the ambiguity in `verification_notes`. This is better than silently passing an uncertain comparison.

## Re-Verification

When a user requests re-verification of previously verified claims:
1. Re-fetch the source content (do not rely on cache — the source may have changed)
2. Run the full comparison pipeline again
3. Update the claim status based on new results
4. Append a re-verification event to the claim's history
5. If the result changes from the previous verification, note this in `verification_notes` — the user will want to know that something shifted
