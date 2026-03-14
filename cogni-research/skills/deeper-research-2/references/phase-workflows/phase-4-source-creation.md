# Phase 4: Source Creation & Validation

**Objective:** Create source entities from findings and validate completeness BEFORE knowledge extraction begins.

Phase 4 consists of two sequential sub-phases:

- **Phase 4.1:** Source Creation → `$DIR_SOURCES/data/`
- **Phase 4.2:** Source Validation & Repair → validates and repairs source entities

**BLOCKING:** Phase 5 (Knowledge Extraction) cannot start until Phase 4.2 completes with success.

---

## Step 0: Derive project_path (MANDATORY)

**⛔ CRITICAL:** Before any Phase 4 work, derive and validate `project_path`:

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

# Set PROJECT_PATH for consistency with existing code
PROJECT_PATH="${project_path}"
```

**Use this `project_path` / `PROJECT_PATH` value in ALL subsequent commands in this phase.**

**⚠️ FRESH SHELL WARNING:** Each Bash tool invocation is a fresh shell. You MUST re-derive or set `PROJECT_PATH` at the TOP of each bash block that uses it.

---

## Step 0.5: Phase 3 Coverage Gate (STRICT 100% BLOCKING)

**MANDATORY:** Before starting ANY Phase 4 work, verify Phase 3 achieved 100% question-to-batch coverage.

This gate enforces strict data completeness - Phase 4 MUST NOT proceed with incomplete research data.

### Shell Compatibility Note

> **zsh Warning:** The bash code below uses the temp script pattern to avoid zsh parsing errors.
> See `references/shell-compatibility.md` for patterns that work across bash and zsh.

### Verification Logic

```bash
# Use temp script pattern for zsh compatibility (see shell-compatibility.md)
cat > /tmp/phase3-coverage-gate.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PLUGIN_ROOT="$1"
PROJECT_PATH="$2"

# Check Phase 3 completion quality - STRICT 100% BLOCKING
PHASE3_STATUS=$(bash "${PLUGIN_ROOT}/scripts/validate-phase3-completion.sh" \
  --project-path "${PROJECT_PATH}")

# Parse validation results
COVERAGE=$(echo "$PHASE3_STATUS" | jq -r '.coverage_percent')
MISSING_COUNT=$(echo "$PHASE3_STATUS" | jq -r '.missing_questions | length')
MALFORMED_COUNT=$(echo "$PHASE3_STATUS" | jq -r '.malformed_batches | length')

# STRICT: ANY missing questions blocks Phase 4
if [ "$MISSING_COUNT" -gt 0 ]; then
  echo "=======================================================" >&2
  echo "FATAL: Phase 3 incomplete. ${MISSING_COUNT} questions missing batches." >&2
  echo "=======================================================" >&2
  echo "" >&2
  echo "Missing questions:" >&2
  echo "$PHASE3_STATUS" | jq -r '.missing_questions[]' >&2
  echo "" >&2
  echo "Coverage: ${COVERAGE}% (required: 100%)" >&2
  echo "" >&2
  echo "RESOLUTION: Manual retry required before proceeding to Phase 4." >&2
  echo "Re-run findings-creator for each missing question listed above." >&2
  echo "=======================================================" >&2
  exit 1
fi

# Check for malformed batches (warning, not blocking if content exists)
if [ "$MALFORMED_COUNT" -gt 0 ]; then
  echo "WARNING: ${MALFORMED_COUNT} batches have content issues" >&2
  echo "$PHASE3_STATUS" | jq -r '.malformed_batches[]' >&2
  echo "Proceeding with Phase 4 - malformed batches may affect finding quality" >&2
fi

echo "Phase 3 Coverage Gate PASSED: ${COVERAGE}% coverage (${MISSING_COUNT} missing)" >&2
SCRIPT_EOF
chmod +x /tmp/phase3-coverage-gate.sh && bash /tmp/phase3-coverage-gate.sh "${CLAUDE_PLUGIN_ROOT}" "${PROJECT_PATH}"
```

### On Failure

- **HALT workflow** - do NOT proceed to Phase 4.1
- Display specific missing question IDs
- Instruct user to retry missing questions manually
- Log failure in sprint-log.json

### On Success

- Proceed to Phase 4.1 (Source Creation)
- Log: "Phase 3 Coverage Gate PASSED: 100% coverage"

---

## Phase 4.1: Source Creation

Create source entities from findings using source-creator agent.

**Strategy:** Sequential processing with pre-filtering optimization for stability.

### 4.1.1 Pre-Filter Substantive Findings

Filter no-results findings to avoid processing findings with no extractable citations:

> **zsh Compatibility:** Use temp script pattern to avoid parse errors. See `references/shell-compatibility.md`.

```bash
# Use temp script pattern for zsh compatibility (see shell-compatibility.md)
cat > /tmp/phase41-prefilter.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PLUGIN_ROOT="$1"
PROJECT_PATH="$2"

# Source entity configuration for directory resolution
ENTITY_CONFIG=""
[ -f "${PLUGIN_ROOT}/scripts/lib/entity-config.sh" ] && ENTITY_CONFIG="${PLUGIN_ROOT}/scripts/lib/entity-config.sh"
source "$ENTITY_CONFIG"

DIR_FINDINGS="$(get_directory_by_key "findings")"
DIR_SOURCES="$(get_directory_by_key "sources")"
DATA_SUBDIR="$(get_data_subdir)"

# Identify failed findings using existing metadata
echo "Filtering findings for Phase 4.1..." >&2
all_findings="$(find "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}/" -name 'finding-*.md' -type f 2>/dev/null | sort)"
failed_findings="$(grep -l 'query_success_level: "failed"' "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}"/finding-*.md 2>/dev/null || true)"

# Build substantive findings list (all findings except failed)
if [ -z "$failed_findings" ]; then
  substantive_findings="$all_findings"
else
  failed_pattern="$(echo "$failed_findings" | tr '\n' '|' | sed 's/|$//')"
  substantive_findings="$(echo "$all_findings" | grep -v -E "$failed_pattern" 2>/dev/null || echo "$all_findings")"
fi

substantive_count="$(echo "$substantive_findings" | grep -c "^" 2>/dev/null || echo 0)"
total_count="$(find "${PROJECT_PATH}/${DIR_FINDINGS}/${DATA_SUBDIR}/" -name 'finding-*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"

# Validation gates - verify count arithmetic is correct
failed_count="$(echo "$failed_findings" | grep -c "^" 2>/dev/null || echo 0)"
if [ -z "$failed_findings" ]; then failed_count=0; fi
expected_substantive=$((total_count - failed_count))

if [ "$substantive_count" -ne "$expected_substantive" ]; then
  echo "ERROR: Count mismatch - expected $expected_substantive substantive findings, got $substantive_count" >&2
  echo "  total: $total_count, failed: $failed_count" >&2
  exit 1
fi

if [ "$substantive_count" -eq 0 ] && [ "$total_count" -gt 0 ]; then
  echo "INFO: All $total_count findings marked as failed - no substantive findings to process" >&2
  echo "SKIP_PHASE_4_1=true"
  exit 0
fi

# Handle zero findings case
if [ "$substantive_count" -eq 0 ]; then
  echo "INFO: No substantive findings to process in Phase 4.1 - all no-results" >&2
  echo "SKIP_PHASE_4_1=true"
  exit 0
fi

# Log filtering statistics
filtered_count=$((total_count - substantive_count))
echo "Phase 4.1 Pre-filtering: $substantive_count substantive / $total_count total, filtered: $filtered_count" >&2

# Archive filtering results for observability
mkdir -p "${PROJECT_PATH}/.metadata"
echo "$substantive_findings" > "${PROJECT_PATH}/.metadata/phase4-substantive-findings.txt"
echo "$failed_findings" > "${PROJECT_PATH}/.metadata/phase4-filtered-findings.txt" 2>/dev/null || true

# Export for subsequent steps
echo "DIR_FINDINGS=${DIR_FINDINGS}"
echo "DIR_SOURCES=${DIR_SOURCES}"
echo "DATA_SUBDIR=${DATA_SUBDIR}"
echo "substantive_count=${substantive_count}"
echo "filtered_count=${filtered_count}"
SCRIPT_EOF
chmod +x /tmp/phase41-prefilter.sh && bash /tmp/phase41-prefilter.sh "${CLAUDE_PLUGIN_ROOT}" "${PROJECT_PATH}"
```

**Design Rationale:**

*Why Filter?* Source-creator processing wastes 20-30% of time on no-results findings that contain no extractable citations. Pre-filtering improves efficiency.

*How It Works:*

1. Use existing `query_success_level: "failed"` metadata (set by research-executor)
2. Grep findings for failed status, exclude from processing
3. Pass only substantive findings to source-creator agent

*Validation Gates:*

- Sanity checks prevent logic errors (substantive > total)
- Complete filtering detection (0 findings likely indicates error)
- Archive filtered findings for observability and recovery

*Recovery:* If filtering behaves unexpectedly:

1. Review archived findings: `cat .metadata/phase4-filtered-findings.txt`
2. Verify metadata: `grep 'query_success_level:' {finding}`
3. Reprocess if needed: Manual source-creator invocation with custom list

### 4.1.2 Invoke Source-Creator Agent

**Performance Expectations:**

| Approach | Typical Runtime (100 findings) | Stability | Complexity |
|----------|-------------------------------|-----------|------------|
| Sequential (current) | ~30 min | High | Low |
| Parallel 4 workers (previous) | ~7-8 min | Medium | High |

**Why Sequential:**

- **Stability:** Eliminates lock contention and race conditions on entity-index.json
- **Simplicity:** Single agent invocation, no distribution/aggregation logic
- **Debuggability:** Easier to trace issues with single execution path
- **Reliability:** No parallel write conflicts or timing dependencies
- **Trade-off:** Accepts longer runtime for improved stability

The source-creator skill handles batch processing internally with enhanced logging, providing visibility into progress during sequential execution.

### 4.1.3 Implementation

**Complete workflow for Phase 4.1:**

**⚠️ ZSH COMPATIBILITY:** Execute as **separate Bash tool calls** or use temp script pattern.

```bash
# Bash call 1: Write findings to file
finding_list_file="{project-path}/.metadata/phase4-finding-list.txt" && \
  echo "$substantive_findings" > "$finding_list_file"
```

```bash
# Bash call 2: Count for logging (SEPARATE call - never combine $() with previous)
finding_list_file="{project-path}/.metadata/phase4-finding-list.txt" && \
  finding_count=$(wc -l < "$finding_list_file" | tr -d ' ') && \
  echo "Phase 4.1: Passing $finding_count findings via file-based contract" >&2
```

```bash
# Bash call 3: Invoke source-creator agent (via Task tool, not Bash)
```

**Task invocation:**

```python
Task(
  subagent_type="cogni-research:source-creator",
  prompt="Create sources at {project-path} --finding-list-file {finding_list_file}",
  description="Creating sources from findings"
)
```

**Validation and reporting:**

1. **Invoke source-creator agent:**
   - Provide finding list file path via `--finding-list-file` parameter
   - Agent: `cogni-research:source-creator`
2. Validate response (expect: `{"success": true, "sources_created": 18, "sources_reused": 5}`)
3. **Report counts:**

   > **zsh Compatibility:** Use temp script pattern to avoid parse errors with `$()` and literal parentheses. See `references/shell-compatibility.md`.

   ```bash
   # Use temp script pattern for zsh compatibility (see shell-compatibility.md)
   cat > /tmp/phase41-report.sh << 'SCRIPT_EOF'
   #!/usr/bin/env bash
   set -eo pipefail
   PROJECT_PATH="$1"
   DIR_SOURCES="$2"
   DATA_SUBDIR="$3"
   SOURCES_CREATED="$4"
   SOURCES_REUSED="$5"
   FINDINGS_UPDATED="$6"
   FILTERED_COUNT="$7"

   actual_sources=$(find "${PROJECT_PATH}/${DIR_SOURCES}/${DATA_SUBDIR}" -maxdepth 1 -name "source-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

   echo "Phase 4.1 Complete:"
   echo "- Sources created: ${SOURCES_CREATED}"
   echo "- Sources reused: ${SOURCES_REUSED}"
   echo "- Findings updated: ${FINDINGS_UPDATED}"
   echo "- Filesystem sources: ${actual_sources}"
   echo "- Filtered no-results: ${FILTERED_COUNT}"
   SCRIPT_EOF
   chmod +x /tmp/phase41-report.sh && bash /tmp/phase41-report.sh "${PROJECT_PATH}" "${DIR_SOURCES}" "${DATA_SUBDIR}" "${sources_created}" "${sources_reused}" "${findings_updated}" "${filtered_count}"
   ```

4. Mark complete in TodoWrite

### 4.1.4 Phase 4.1 Completion Checkpoint

```bash
# Write Phase 4.1 completion marker
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${PROJECT_PATH}/.metadata/phase-4.1-complete"

# Verify completion
if [ ! -f "${PROJECT_PATH}/.metadata/phase-4.1-complete" ]; then
  echo "ERROR: Phase 4.1 incomplete - source creation did not complete" >&2
  exit 1
fi

echo "Phase 4.1 complete: Source creation finished" >&2
```

---

## Phase 4.2: Source Validation & Repair

**Objective:** Validate source entities created in Phase 4.1 and repair any issues before proceeding to Phase 5.

### 4.2.1 Source Entity Validation Checks

Run comprehensive validation on all source entities in `$DIR_SOURCES/$DATA_SUBDIR/`:

> **zsh Compatibility:** Use temp script pattern to avoid parse errors. See `references/shell-compatibility.md`.

```bash
# Use temp script pattern for zsh compatibility (see shell-compatibility.md)
cat > /tmp/phase42-validate.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PLUGIN_ROOT="$1"
PROJECT_PATH="$2"

# Validation script invocation
VALIDATION_RESULT=$(bash "${PLUGIN_ROOT}/scripts/validate-sources.sh" \
  --project-path "${PROJECT_PATH}" \
  --json)

# Parse validation results
SUCCESS=$(echo "$VALIDATION_RESULT" | jq -r '.success')
TOTAL_SOURCES=$(echo "$VALIDATION_RESULT" | jq -r '.total_sources')
VALID_SOURCES=$(echo "$VALIDATION_RESULT" | jq -r '.valid_sources')
INVALID_COUNT=$(echo "$VALIDATION_RESULT" | jq -r '.invalid_sources | length')

# Export for subsequent steps
echo "SUCCESS=${SUCCESS}"
echo "TOTAL_SOURCES=${TOTAL_SOURCES}"
echo "VALID_SOURCES=${VALID_SOURCES}"
echo "INVALID_COUNT=${INVALID_COUNT}"
SCRIPT_EOF
chmod +x /tmp/phase42-validate.sh && bash /tmp/phase42-validate.sh "${CLAUDE_PLUGIN_ROOT}" "${PROJECT_PATH}"
```

**Validation Checks:**

| Check | Description | Repair Action |
|-------|-------------|---------------|
| URL Format | Valid http(s):// URL | Mark invalid, skip |
| Domain Consistency | Domain matches URL | Re-extract domain |
| Title Present | Non-empty title field | Re-extract from finding |
| Finding Backlinks | source_id populated in findings | Re-run backlink update |
| Entity Index Sync | Source in entity-index.json | Run repair-entity-index.sh |
| Duplicate Detection | No URL/ID collisions | Merge duplicates |
| Metadata Completeness | Required fields present | Fill from finding |

### 4.2.2 Repair Operations

For identified issues, invoke repair scripts:

```bash
# Repair entity index synchronization
if [ "$INDEX_DESYNC_COUNT" -gt 0 ]; then
  echo "Repairing entity index for $INDEX_DESYNC_COUNT sources..." >&2
  bash "${CLAUDE_PLUGIN_ROOT}/scripts/repair-entity-index.sh" \
    --project-path "${PROJECT_PATH}" \
    --entity-type "$DIR_SOURCES" \
    --json
fi

# Note: Finding backlink repairs require source-creator re-invocation
# or manual update of finding frontmatter with correct source_id wikilinks
```

**Repair Protocol:**

1. **Entity Index Desync:** Run `repair-entity-index.sh --entity-type $DIR_SOURCES`
2. **Missing Backlinks:** Re-invoke source-creator for affected findings
3. **Duplicate Collision:** Manual merge required (log for user intervention)
4. **Invalid Metadata:** Log and skip (non-blocking for other sources)

### 4.2.3 Retry Logic

**Maximum retries:** 2 rounds of repair

> **zsh Compatibility:** Use temp script pattern to avoid parse errors. See `references/shell-compatibility.md`.

```bash
# Use temp script pattern for zsh compatibility (see shell-compatibility.md)
cat > /tmp/phase42-retry.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PLUGIN_ROOT="$1"
PROJECT_PATH="$2"
INVALID_COUNT="$3"

RETRY_COUNT=0
MAX_RETRIES=2

while [ "$INVALID_COUNT" -gt 0 ] && [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  echo "Repair attempt $RETRY_COUNT of $MAX_RETRIES..." >&2

  # Run repairs based on error types
  # ... repair operations from 4.2.2 ...

  # Re-validate
  VALIDATION_RESULT=$(bash "${PLUGIN_ROOT}/scripts/validate-sources.sh" \
    --project-path "${PROJECT_PATH}" --json)
  INVALID_COUNT=$(echo "$VALIDATION_RESULT" | jq -r '.invalid_sources | length')
done

# Handle permanent failures
if [ "$INVALID_COUNT" -gt 0 ]; then
  echo "WARNING: $INVALID_COUNT sources remain invalid after $MAX_RETRIES repair attempts" >&2
  PERMANENT_FAILURES=$(echo "$VALIDATION_RESULT" | jq -c '.invalid_sources')

  # Record in sprint-log
  jq --argjson failures "$PERMANENT_FAILURES" \
    '.phase_4_validation.permanent_failures = $failures' \
    "${PROJECT_PATH}/.metadata/sprint-log.json" > tmp.json && mv tmp.json "${PROJECT_PATH}/.metadata/sprint-log.json"
fi

echo "INVALID_COUNT=${INVALID_COUNT}"
SCRIPT_EOF
chmod +x /tmp/phase42-retry.sh && bash /tmp/phase42-retry.sh "${CLAUDE_PLUGIN_ROOT}" "${PROJECT_PATH}" "${INVALID_COUNT}"
```

### 4.2.4 Manual Intervention Handling

If repair attempts exceed threshold:

1. Log detailed error report to `.logs/phase4-validation-errors.json`
2. Record permanent failures in sprint-log.json
3. Continue with degraded data if failure rate is acceptable

> **zsh Compatibility:** Use temp script pattern to avoid parse errors. See `references/shell-compatibility.md`.

```bash
# Use temp script pattern for zsh compatibility (see shell-compatibility.md)
cat > /tmp/phase42-threshold.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
INVALID_COUNT="$1"
TOTAL_SOURCES="$2"

# Threshold check - 10% failure rate tolerance
FAILURE_THRESHOLD=0.10
FAILURE_RATE=$(awk "BEGIN {printf \"%.2f\", $INVALID_COUNT / $TOTAL_SOURCES}")

if (( $(echo "$FAILURE_RATE > $FAILURE_THRESHOLD" | bc -l) )); then
  echo "WARNING: Failure rate $FAILURE_RATE exceeds threshold $FAILURE_THRESHOLD" >&2
  echo "Manual intervention recommended before Phase 5" >&2
  # Log but continue - non-blocking
fi
SCRIPT_EOF
chmod +x /tmp/phase42-threshold.sh && bash /tmp/phase42-threshold.sh "${INVALID_COUNT}" "${TOTAL_SOURCES}"
```

### 4.2.5 Phase 4.2 Completion Checkpoint

> **zsh Compatibility:** Use temp script pattern to avoid parse errors. See `references/shell-compatibility.md`.

```bash
# Use temp script pattern for zsh compatibility (see shell-compatibility.md)
cat > /tmp/phase42-complete.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
VALID_SOURCES="$2"
INVALID_COUNT="$3"
TOTAL_SOURCES="$4"

# Write completion marker
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${PROJECT_PATH}/.metadata/phase-4.2-complete"

# Update sprint-log with validation statistics
jq --argjson valid "$VALID_SOURCES" \
   --argjson invalid "$INVALID_COUNT" \
   --argjson total "$TOTAL_SOURCES" \
  '.phase_4_validation = {
    "valid_sources": $valid,
    "invalid_sources": $invalid,
    "total_sources": $total,
    "validation_passed": ($invalid == 0),
    "timestamp": (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
  }' \
  "${PROJECT_PATH}/.metadata/sprint-log.json" > tmp.json && mv tmp.json "${PROJECT_PATH}/.metadata/sprint-log.json"

echo "Phase 4.2 complete: ${VALID_SOURCES}/${TOTAL_SOURCES} sources validated" >&2
SCRIPT_EOF
chmod +x /tmp/phase42-complete.sh && bash /tmp/phase42-complete.sh "${PROJECT_PATH}" "${VALID_SOURCES}" "${INVALID_COUNT}" "${TOTAL_SOURCES}"
```

### 4.2.6 Generate Sources README

Generate the sources directory README with provenance chain and entity index:

```bash
# Get project language from sprint-log
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${PROJECT_PATH}/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Resolve script path
SOURCES_README_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/generate-sources-readme.sh"

# Generate sources README
bash "$SOURCES_README_SCRIPT" \
  --project-path "${PROJECT_PATH}" \
  --language "${PROJECT_LANGUAGE}" \
  --json
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "readme_path": "{project-path}/07-sources/README.md",
    "readme_created": true
  },
  "stats": {
    "source_count": 48,
    "domain_count": 23,
    "finding_refs_total": 156
  }
}
```

**Note:** Exit code 3 (no source files) is non-blocking - continue to Phase 5 if no sources exist.

---

## Phase 4 Completion Gate

**BLOCKING:** Phase 5 cannot start until BOTH 4.1 and 4.2 complete:

```bash
# Verify Phase 4 completion before Phase 5
if [ ! -f "${PROJECT_PATH}/.metadata/phase-4.1-complete" ]; then
  echo "ERROR: Phase 4.1 incomplete - cannot proceed to Phase 5" >&2
  exit 1
fi

if [ ! -f "${PROJECT_PATH}/.metadata/phase-4.2-complete" ]; then
  echo "ERROR: Phase 4.2 incomplete - cannot proceed to Phase 5" >&2
  exit 1
fi

echo "Phase 4 complete: Sources created and validated" >&2
```

---

## Self-Verification Questions

1. Did you run the Phase 3 Coverage Gate (Step 0)? YES/NO
2. Did you invoke source-creator agent for all substantive findings? YES/NO
3. Did source-creator return success with validation_passed=true? YES/NO
4. Did you run Phase 4.2 validation checks? YES/NO
5. Are all sources validated (0 invalid_sources) or permanent failures logged? YES/NO
6. Are both phase-4.1-complete and phase-4.2-complete markers present? YES/NO

If ANY NO: STOP and complete missing steps.

---

## Outputs

- Sources: `{project_path}/$DIR_SOURCES/data/` (deduplicated source entities)
- Filtered findings list: `{project_path}/.metadata/phase4-substantive-findings.txt`
- Validation log: `{project_path}/.logs/phase4-validation-log.json` (if errors)
- Completion markers: `{project_path}/.metadata/phase-4.1-complete`, `phase-4.2-complete`
- Updated sprint-log with phase_4_validation metrics

---

## Version History

**v1.3.0** (2026-01-07)

- **Comprehensive zsh compatibility fix:** Converted all complex bash blocks to temp script pattern
- **Sections fixed:**
  - 4.1.1 Pre-Filter Substantive Findings → `/tmp/phase41-prefilter.sh`
  - 4.1.3 Validation and reporting → `/tmp/phase41-report.sh`
  - 4.2.1 Source Entity Validation → `/tmp/phase42-validate.sh`
  - 4.2.3 Retry Logic → `/tmp/phase42-retry.sh`
  - 4.2.4 Manual Intervention Handling → `/tmp/phase42-threshold.sh`
  - 4.2.5 Completion Checkpoint → `/tmp/phase42-complete.sh`
- **Problem:** Multiple `$()` substitutions and `echo` with literal parentheses caused `(eval):1: parse error near '('` in zsh
- **Solution:** All complex bash logic wrapped in temp scripts following patterns in `shell-compatibility.md`

**v1.1.0** (2026-01-02)

- **Fixed zsh parse error:** Step 0 Coverage Gate now uses temp script pattern for zsh compatibility
- **Problem:** Inline bash combining `export PROJECT_PATH=...` with `PHASE3_STATUS=$(bash ...)` caused `(eval):1: parse error near '('` in zsh
- **Solution:** Wrap complex bash logic in temp script (`/tmp/phase3-coverage-gate.sh`) following patterns in `shell-compatibility.md`
- **Added Shell Compatibility Note** referencing `references/shell-compatibility.md`

**v1.0.0** (Initial)

- Initial implementation of Phase 4 workflow
- Sequential source creation with pre-filtering
- Two-phase validation and repair
