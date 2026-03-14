---
name: claims
description: |
  Extract verified claims from research findings with three-layer confidence scoring.
  Use after findings-sources completes — when findings exist in 04-findings/ and sources in 05-sources/.
  Trigger when user says "extract claims", "verify findings", "fact-check", "create claims",
  "run claim extraction", "verify the research", or wants to move from raw findings to verified assertions.
  Produces claims (06) with evidence confidence, claim quality, and optional source verification.
  After completion, run synthesis for narrative generation.
---

# Claims

Extract atomic, verifiable claims from research findings. Score each claim on evidence confidence and claim quality. Optionally submit to cogni-claims for source URL verification (three-layer assurance).

## Prerequisites

- findings-sources completed: `discovery_complete = true` in sprint-log.json
- Findings exist in 04-findings/data/
- Sources exist in 05-sources/data/

Check via: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-phase-state.sh --project-path <path> --phase discovery`

## Workflow

### Phase 1: Claim Extraction (Parallel)

1. **Load findings**: Count and partition findings for parallel processing
   - Use `partition-entities.sh` to split findings across claim-extractor agents
   - Target: 1 agent per 15 sources (3-20 agents typical)

2. **Check resumption state**: Run `scan-resumption-state.sh --phase claims`

3. **Invoke claim-extractor agents** in parallel via Task tool:
   - Each agent processes a partition of findings
   - For each finding, extract atomic claims with:
     - **claim_text**: Self-contained factual assertion
     - **finding_refs**: Wikilinks to source findings
     - **source_refs**: Wikilinks to source entities (05-sources)
     - **evidence_confidence**: Score 0.0-1.0 (source quality, cross-validation, recency, expertise)
     - **claim_quality**: Score 0.0-1.0 (atomicity, fluency, decontextualization, faithfulness)
     - **confidence_score**: Composite = evidence_confidence × 0.6 + claim_quality × 0.4
   - Claims created in 06-claims/data/ via create-entity.sh

4. **Verify claims**: Minimum 5 claims with valid confidence scores

### Phase 2: Source Verification (Optional)

If cogni-claims plugin is available:

1. **Identify verifiable claims**: Claims with source_refs linking to sources with HTTP/HTTPS URLs
2. **Submit to cogni-claims**: Batch submit claims with their source URLs
3. **Record submission**: Save reference in `.metadata/claim-submission.json`
4. **Update claim entities** with verification results:
   - `source_verification`: verified | deviated | source_unavailable | skipped
   - `deviation_count`, `deviation_max_severity`
   - `final_confidence`: confidence_score × verification_modifier

   Verification modifiers:
   | Status | Modifier |
   |---|---|
   | verified | 1.0 |
   | deviated (low) | 0.9 |
   | deviated (medium) | 0.7 |
   | deviated (high) | 0.4 |
   | deviated (critical) | 0.1 |
   | source_unavailable | 0.8 |

5. If cogni-claims is not available, set `source_verification: skipped` for all claims

### Phase 3: Finalization

1. **Generate claims README**: Run `generate-claims-readme.sh` for claim inventory
2. **Aggregate metrics**: Average confidence, verification coverage, claim count
3. **Update sprint-log**: Set `claims_complete = true`, record metrics
4. **Report completion**: Claim count, average confidence, verification status

---

## Three-Layer Claim Assurance

Read `${CLAUDE_PLUGIN_ROOT}/references/claim-assurance.md` for full documentation.

1. **Evidence confidence** (0.0-1.0): How well-supported is the claim by evidence?
2. **Claim quality** (0.0-1.0): How well-formed is the claim as an assertion?
3. **Source verification** (via cogni-claims): Does the original source actually support this claim?

## Agents Used

| Agent | Purpose | Parallelism |
|---|---|---|
| `claim-extractor` | Extract claims + score confidence | Parallel per partition |

## State Management

- `claims_complete: true` — signals readiness for synthesis skill
- Resumption: `scan-resumption-state.sh --phase claims`

## Next Step

After claims completes, run `synthesis` to generate narrative summaries via cogni-narrative.
