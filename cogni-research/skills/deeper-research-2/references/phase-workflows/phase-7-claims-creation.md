## Phase 7: Claims Creation

---

## MANDATORY: Read This Reference First

**You MUST READ THIS ENTIRE REFERENCE FILE BEFORE EXECUTING PHASE 7.**

This reference contains:

- Required TodoWrite expansion templates (Step 0.5)
- Phase entry verification gates
- Step-by-step implementation details
- Self-verification checkpoints

**Do NOT skip to execution.** Reading this reference is mandatory for phase completion.

---

## Step 0: Derive project_path (MANDATORY)

**⛔ CRITICAL:** Before any Phase 7 work, derive and validate `project_path`:

```bash
# Derive project_path from sprint-log.json location
sprint_log="$(find . -path "*/.metadata/sprint-log.json" -type f 2>/dev/null | head -1)"

if [ -z "$sprint_log" ]; then
  echo "ERROR: No sprint-log.json found. Ensure Phase 0 completed." >&2
  exit 1
fi

project_path="$(cd "$(dirname "$sprint_log")/.." && pwd)"

# Validate
if [ ! -d "${project_path}/.metadata" ]; then
  echo "ERROR: Invalid project_path: ${project_path}" >&2
  exit 1
fi

echo "project_path: ${project_path}"
```

**Use this `project_path` value in ALL subsequent commands in this phase.**

---

## PHASE ENTRY VERIFICATION (MANDATORY)

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 6 is marked complete. Phase 7 cannot begin until citations exist.

**THEN verify Phase 6 artifacts exist:**

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set. Run Step 0 first." >&2
  exit 1
fi

# Source entity configuration for directory resolution
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"
DIR_PUBLISHERS="$(get_directory_by_key "publishers")"
DIR_CITATIONS="$(get_directory_by_key "citations")"
DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_CLAIMS="$(get_directory_by_key "claims")"
DATA_SUBDIR="$(get_data_subdir)"

ls -la "${project_path}/$DIR_PUBLISHERS/$DATA_SUBDIR/"*.md "${project_path}/$DIR_CITATIONS/$DATA_SUBDIR/"*.md
```

**IF any directory is missing or empty:**

1. STOP immediately
2. Return to Phase 6 and create required artifacts
3. Only then return to Phase 7

**This is not optional.** Skipping Phase 6 validation means claims cannot be properly linked to citations.

---

## Step 1.5: Resumption State Check (Rate-Limit Recovery)

**Purpose:** Detect partially-completed claims from a prior interrupted run and skip findings that already have claims. This enables seamless resumption after rate-limit interruptions.

### 1.5.1 Scan Existing Claims

```bash
RESUMPTION_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh" \
  --project-path "${project_path}" \
  --phase 7 \
  --json)"

RECOMMENDATION="$(echo "$RESUMPTION_RESULT" | jq -r '.recommendation')"
echo "Resumption scan: ${RECOMMENDATION}"
```

### 1.5.2 Branch on Recommendation

```text
COMPLETE → Skip to Step 5 (completion/reporting). All findings already have claims.
RESUME  → Write pending finding paths to .metadata/phase-7-pending-findings.txt
           and recalculate agent_count based on pending count (not total).
FULL_RUN → Proceed normally (no changes).
```

**RESUME handling:**

```bash
PENDING_COUNT="$(echo "$RESUMPTION_RESULT" | jq -r '.pending_finding_ids | length')"
COMPLETED_COUNT="$(echo "$RESUMPTION_RESULT" | jq -r '.completed_findings')"

echo "Resuming: ${PENDING_COUNT} pending findings, ${COMPLETED_COUNT} already have claims"

# Write pending finding paths for fact-checker agents
echo "$RESUMPTION_RESULT" | jq -r '.pending_finding_paths[]' > "${project_path}/.metadata/phase-7-pending-findings.txt"

echo "Wrote ${PENDING_COUNT} pending finding paths to .metadata/phase-7-pending-findings.txt"
```

When `RESUME` is active, Step 1 (source count and agent calculation) should use `PENDING_COUNT` instead of the total finding count for agent sizing, since only pending findings need processing.

### 1.5.3 Cleanup After Completion

In Step 5 (Report Completion), add cleanup of the resumption artifact:

```bash
rm -f "${project_path}/.metadata/phase-7-pending-findings.txt"
```

This is safe: the file only exists during resumption runs and is idempotent to remove.

---

## Step 0.5: Initialize Phase 7 TodoWrite

Add step-level todos for Phase 7:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 7, Step 1.5: Resumption state check (skip already-covered findings) [in_progress]
- Phase 7, Step 1: Count sources and calculate agent count [pending]
- Phase 7, Step 2: Partition findings across fact-checker agents [pending]
- Phase 7, Step 3: Invoke ALL fact-checker agents in parallel [pending]
- Phase 7, Step 4: Aggregate verification metrics [pending]
- Phase 7, Step 5: Report completion and mark phase complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

---

<planning>
Apply 15-Sources Rule based on source count from Phase 5/6. Calculate agent count (ceiling(sources / 15)), partition findings, and invoke fact-checker agents in parallel.
</planning>

**Strategy:** 15-Sources Rule (1 agent per 15 sources). See `references/parallelization-strategies.md` for details.

## Step 1: Count Sources and Calculate Agent Count

Count sources from Phase 5/6 to determine parallelization:

```bash
source_count=$(find "${project_path}/$DIR_SOURCES/$DATA_SUBDIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ') && echo "Sources: $source_count"
```

Apply 15-sources rule with bounds:

```bash
# Calculate raw agent count (ceiling division)
agent_count=$(( (source_count + 14) / 15 ))

# Apply bounds: minimum 1, maximum 20
[ $agent_count -lt 1 ] && agent_count=1
[ $agent_count -gt 20 ] && agent_count=20
```

**Rule of thumb**: 1 agent per 15 sources provides optimal workload distribution.

- 45 sources → 3 agents
- 90 sources → 6 agents
- 150 sources → 10 agents
- 300+ sources → 20 agents (capped)

See `references/parallelization-strategies.md` for detailed rationale.

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Confirm Partition Count

Agent count was calculated in Step 1 using the 15-sources rule. No explicit file assignment is needed - fact-checker agents perform self-partitioning using round-robin based on their partition index.

**Verification**: Confirm `agent_count` is between 1 and 20 (bounded).

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Invoke ALL Fact-Checker Agents in Parallel

**Invoke ALL fact-checker agents in parallel** (single message, multiple Task calls):

```xml
<invoke name="Task">
  <parameter name="subagent_type">cogni-research:fact-checker</parameter>
  <parameter name="description">Fact-check partition N</parameter>
  <parameter name="prompt">
Process findings partition N of M.

PROJECT_PATH={{project_path}}
PARTITION_INDEX={{N}}
TOTAL_PARTITIONS={{agent_count}}
LANGUAGE={{project_language}}

Extract atomic claims from your assigned partition (self-calculated via round-robin).
Create claim entities in $DIR_CLAIMS/data/ directory.
Report: partition number, claims created, average confidence, flagged count.
  </parameter>
</invoke>
```

- For each agent (0 to agent_count-1): provide `PARTITION_INDEX` and `TOTAL_PARTITIONS`
- Agents self-partition findings using round-robin: agent N processes findings at indices N, N+agent_count, N+2×agent_count, ...
- Invoke ALL agents in a single message for parallel execution

**Mark Step 3 todo as completed** before proceeding to Step 4.

---

## Step 4: Aggregate Verification Metrics

1. Parse text summaries from each agent (format: `Partition N fact-checking complete...`)
2. Read JSON statistics from `.logs/partition-N-stats.json` files for detailed metrics
3. Aggregate: Sum all claims_created, calculate weighted average confidence from JSON files

**Mark Step 4 todo as completed** before proceeding to Step 5.

---

## Step 5: Report Completion and Mark Phase Complete

### Clean Up Resumption Artifacts

```bash
# Remove pending-findings file if present (from resumption runs)
rm -f "${project_path}/.metadata/phase-7-pending-findings.txt"
```

### Update Sprint Log

```bash
# Update sprint-log.json with Part 1 completion
jq '.part1_complete = true | .workflow_state = "ready_for_synthesis" | .current_phase = "complete"' \
  ${project_path}/.metadata/sprint-log.json > tmp.json && mv tmp.json ${project_path}/.metadata/sprint-log.json
```

### Generate Claims README

Generate the claims directory README with provenance chain, confidence distribution, and entity index:

```bash
# Get project language from sprint-log
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${project_path}/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Resolve script path
CLAIMS_README_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/generate-claims-readme.sh"

# Generate claims README
bash "$CLAIMS_README_SCRIPT" \
  --project-path "${project_path}" \
  --language "${PROJECT_LANGUAGE}" \
  --json
```

**Expected Response:**

```json
{
  "success": true,
  "data": {
    "readme_path": "{project-path}/10-claims/README.md",
    "readme_created": true
  },
  "stats": {
    "claim_count": 156,
    "avg_confidence": 0.78,
    "high_confidence_count": 89,
    "moderate_confidence_count": 52,
    "low_confidence_count": 15,
    "flagged_count": 8
  }
}
```

**Note:** Exit code 3 (no claim files) is non-blocking - continue if no claims exist.

### Report Completion

Report: `Phase 7: Verified {total_claims} claims across {agent_count} partitions (average confidence: {avg_confidence}, {flagged_count} flagged for review)`

### Self-Verification Before Completion

**Verify all steps completed:**

1. Did you run the phase entry verification gate (ls command)? YES / NO
2. Did you count sources and calculate agent count (1 per 15 sources)? YES / NO
3. Did you partition findings across agents? YES / NO
4. Did you invoke ALL fact-checker agents in parallel? YES / NO
5. Did you aggregate verification metrics from JSON files? YES / NO
6. Did you report completion with claim counts? YES / NO
7. Do 10-claims/data/ directory artifacts exist? YES / NO
8. Did you update sprint-log.json with part1_complete = true? YES / NO

**IF ANY NO: STOP.** Return to incomplete step before proceeding.

### Mark Phase 7 Complete

- Update TodoWrite: Phase 7 → completed
- Report Part 1 completion to user
- Instruct user to run `deeper-synthesis --project-path "{project_path}"`

**Mark Step 5 todo as completed.**

---

## Phase Completion Checklist

### MANDATORY: All items MUST be checked before reporting Part 1 complete

Before marking Phase 7 complete in TodoWrite, verify:

- [ ] Phase entry verification gate passed (ls command)
- [ ] Source count retrieved and agent count calculated (1 per 15 sources)
- [ ] Findings partitioned across fact-checker agents
- [ ] ALL fact-checker agents invoked in parallel
- [ ] Verification metrics aggregated from JSON files
- [ ] Completion report generated with claim counts
- [ ] 10-claims/data/ directory exists with claim entities
- [ ] sprint-log.json updated with part1_complete = true
- [ ] All step-level todos marked as completed
- [ ] All self-verification questions answered YES
- [ ] Phase 7 todo marked completed in TodoWrite

---

## Claim Entity Schema

Claims are created by fact-checker agents following the claim-entity schema:

```yaml
---
dc:title: "Claim title"
dc:identifier: "claim-{semantic-slug}-{8-char-hash}"
dc:type: "claim"
confidence:
  evidence_score: 0.85
  claim_quality: 0.90
  composite: 0.87
verification_status: "verified" | "flagged" | "unverified"
criticality: "high" | "medium" | "low"
finding_refs:
  - "[[finding-{slug}]]"
citation_refs:
  - "[[citation-{slug}]]"
---
```

---

## Standardized Title Extraction Pattern

**Purpose:** Ensure consistent title normalization across all agents that process finding entities.

**Utility Script:** `scripts/extract-finding-title.sh` (plugin-level utility)

**When to Use:**
- Extracting titles from finding entities for ANY purpose
- Generating slugs or identifiers that must match finding patterns
- Creating wikilinks to findings based on title
- Any operation requiring finding title normalization

**Usage:**
```bash
# Validate CLAUDE_PLUGIN_ROOT
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

# Extract normalized title from finding
result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/extract-finding-title.sh" \
  --finding-file "$FINDING_FILE" \
  --json)

title=$(echo "$result" | jq -r '.data.normalized_title')
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Missing Phase 6 artifacts | HALT - return to Phase 6 |
| Partial agent failure | CONTINUE with successful partitions |
| All agents fail | HALT - investigate and retry |
| Missing sprint-log.json | HALT - project not initialized |
