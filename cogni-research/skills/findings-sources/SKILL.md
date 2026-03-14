---
name: findings-sources
description: |
  Execute parallel web research and extract enriched sources from findings.
  Use after research-plan completes — when query batches are ready in 03-query-batches/.
  Trigger when user says "run research", "gather findings", "search for evidence",
  "execute the research plan", "find sources", "start web research", or wants to move
  from planning to actual research execution. Produces findings (04) and enriched sources (05).
  After completion, run claims for claim extraction and verification.
---

# Findings & Sources

Execute parallel web research across query batches and extract enriched source entities with publisher profiles and APA citations.

## Prerequisites

- research-plan completed: `planning_complete = true` in sprint-log.json
- Query batches exist in 03-query-batches/data/
- Dimensions exist in 01-research-dimensions/data/

Check via: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-phase-state.sh --project-path <path> --phase planning`

## Workflow

### Phase 1: Findings Creation (Parallel)

1. **Load dimensions and questions**: Read dimensions from 01-research-dimensions/data/, discover questions per dimension via `discover-questions-by-dimension.sh`

2. **Check resumption state**: Run `scan-resumption-state.sh --phase findings` to detect prior partial completion

3. **Execute batch loop** (sequential batches, parallel agents within):
   For each batch of questions (grouped by dimension):
   - Invoke `findings-creator` agents in parallel (one per question)
   - Each agent executes web search + LLM knowledge extraction
   - Findings created in 04-findings/data/ via create-entity.sh

4. **Reconciliation**: After all batches complete:
   - Count findings per dimension
   - Identify any questions with zero findings
   - Retry missing questions in a single reconciliation batch

5. **Verify findings**: Minimum coverage check — every refined question should have at least 1 finding

### Phase 2: Source Extraction (Sequential)

1. **Invoke source-creator agent** via Task tool:
   - Pass: project path, findings directory
   - Agent scans all findings for URLs and source references
   - Creates enriched source entities in 05-sources/data/ with:
     - URL, domain, title, access_date
     - Publisher profile: publisher_name, publisher_type, publisher_reliability
     - APA citation: apa_citation field
     - Reliability tier classification
     - Finding refs (wikilinks back to findings)
   - Deduplication: sources with same URL are merged (dedupe=true)

2. **Verify source output**:
   - Run verify-source-creator-output hook (anti-hallucination check)
   - Sources link back to findings via wikilinks
   - No orphaned sources without finding_refs

3. **Generate sources README**: Run `generate-sources-readme.sh` for inventory

4. **Update sprint-log**: Set `discovery_complete = true`

5. **Report completion**: Finding count, source count, coverage stats

---

## Anti-Hallucination Controls

- **findings-creator**: Hook `repair-missing-batches` fires after each findings-creator agent completes
- **source-creator**: Hook `verify-source-creator-output` fires after source-creator completes, with AUTO-RECOVERY
- **Entity creation**: All entities created via create-entity.sh (hooks block direct Write/Edit)

## Agents Used

| Agent | Purpose | Parallelism |
|---|---|---|
| `findings-creator` | Orchestrate web + LLM findings per question | Parallel per question within batch |
| `findings-creator-file` | Create findings from local files/PDFs | Invoked by findings-creator |
| `findings-creator-llm` | Create findings from LLM knowledge | Invoked by findings-creator |
| `source-creator` | Extract enriched sources from findings | Sequential (entity-index race protection) |

## State Management

- `discovery_complete: true` — signals readiness for claims skill
- Resumption: `scan-resumption-state.sh --phase findings`
- Coverage tracked in sprint-log: `phase_findings_coverage`

## Next Step

After findings-sources completes, run `claims` for claim extraction and three-layer verification.
