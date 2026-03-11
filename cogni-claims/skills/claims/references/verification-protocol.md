# Verification Protocol

## Overview

This document defines the methodology for verifying claims against their cited sources. Verification is LLM-based and must be presented as an assessment, not as a definitive judgment.

## Verification Pipeline

### Phase 1: Source Grouping

Before verification, group all unverified claims by `source_url`. This ensures each unique URL is fetched exactly once, regardless of how many claims reference it.

```
Input:  N unverified claims referencing K unique URLs
Output: K groups, each containing 1+ claims
Fetches: Exactly K (not N)
```

### Phase 2: Source Fetching

For each unique URL, attempt to retrieve the source content:

1. **Primary method**: Use WebFetch to retrieve and extract text content
2. **Fallback method**: If WebFetch fails (403, timeout, JS-rendered content), use browser automation to load the page and extract text
3. **Failure handling**: If both methods fail, record the failure reason and mark all claims referencing this URL as `source_unavailable`

Cache the fetched content in `cogni-claims/sources/{url-hash}.json` for subsequent queries.

### Phase 3: Claim-Source Comparison

For each claim against its fetched source content, perform a structured comparison:

#### Step 1: Locate Relevant Passage

Search the source content for passages relevant to the claim. The source may be lengthy — focus on the specific section that relates to the claim's subject matter.

If no relevant passage is found, this is itself a deviation (the source is silent on the claim's assertion). Record as `unsupported_conclusion` with an explanation that the source does not address this topic.

#### Step 2: Compare Claim Against Passage

Evaluate the claim statement against the identified passage along these dimensions:

| Check | Question | Deviation Type |
|-------|----------|----------------|
| Accuracy | Does the claim accurately represent the source's words? | `misquotation` |
| Inference | Does the claim draw conclusions the source supports? | `unsupported_conclusion` |
| Completeness | Does the claim include all meaning-relevant context? | `selective_omission` |
| Currency | Is the source data current for the claim's context? | `data_staleness` |
| Agreement | Does the source agree with the claim's assertion? | `source_contradiction` |

#### Step 3: Assess Severity

For each detected deviation, assign severity based on impact:

| Severity | Criteria |
|----------|----------|
| `low` | Minor imprecision (rounding, paraphrasing) — meaning preserved |
| `medium` | Noticeable difference that could mislead a careful reader |
| `high` | Significant misrepresentation — reader would form wrong conclusion |
| `critical` | Complete contradiction, fabrication, or reversal of source meaning |

#### Step 4: Extract Evidence

For every comparison (whether deviation found or not), extract a verbatim excerpt from the source that is most relevant to the claim. This excerpt serves as evidence:

- **For verified claims**: The excerpt shows what supports the claim
- **For deviated claims**: The excerpt shows what contradicts or diverges from the claim

Keep excerpts concise (1-3 sentences) but sufficient to understand the context.

#### Step 5: Formulate Explanation

For each deviation, write a plain-language explanation that:
1. States what the claim says
2. States what the source says
3. Explains the specific discrepancy
4. Avoids definitive language — use "appears to", "the source suggests", "this may indicate"

### Phase 4: Result Recording

Update the claim registry with verification results:

- **No deviations**: Set status to `verified`, record supporting excerpt
- **Deviations found**: Set status to `deviated`, attach DeviationRecord(s)
- **Source unavailable**: Set status to `source_unavailable`, record failure reason
- **Ambiguous**: If the comparison is genuinely unclear, set status to `deviated` with severity `low` and add a `verification_notes` field explaining the ambiguity

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

## Re-Verification

When a user requests re-verification of previously verified claims:
1. Re-fetch the source content (do not rely on cache)
2. Run the full comparison pipeline again
3. Update the claim status based on new results
4. Append a re-verification event to the claim's history
5. If the result changes, note this in `verification_notes`
