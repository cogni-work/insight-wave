# Phase 7: LLM Execution Report

**Reference Checksum:** `sha256:v1.0`

**Verification Protocol:** After reading, confirm: `Reference Loaded: phase-7-llm-execution-report.md | Checksum: v1.0`

---

## Objective

Capture silent adaptations and workarounds that occurred during skill execution - issues NOT captured by structured logging (Layer 4 of debugging architecture).

---

## Execution Start

DEBUG_MODE was already verified at SKILL.md level before reading this reference. Begin execution:

```bash
log_phase "Phase 7: LLM Execution Report" "start"
```

---

## Step 7.0: Initialize Phase TodoWrite

Expand phase-level todo to step-level:

```
Phase 7: LLM Execution Report [in_progress]
  └─ Step 7.1: Reflect on execution [pending]
  └─ Step 7.2: Collect issues [pending]
  └─ Step 7.3: Create JSON report [pending]
  └─ Step 7.4: Append to JSONL log [pending]
```

---

## Step 7.1: Reflect on Execution

Review your execution of Phases 0-6. Document any of the following:

| Category | What to Look For |
|----------|------------------|
| **Scripts** | Scripts not at expected location (create-entity.sh, enhanced-logging.sh) |
| **Tool Calls** | Tool calls that failed or returned errors (WebSearch, WebFetch, Read, Bash) |
| **Files** | Files you couldn't find (refined question entity, template files, entity-index.json) |
| **Schemas** | Schema/format mismatches you had to work around (finding-entity.schema.json v3.0 structure) |
| **Parameters** | Parameters that didn't match the specification (REFINED_QUESTION_PATH, PROJECT_PATH, CONTENT_LANGUAGE) |
| **Adaptations** | Any improvisation or fallback logic you applied (WebFetch failures, quality filter edge cases) |

**Self-Verification Questions:**

1. Did any script call fail or return unexpected output? YES/NO
2. Did you find all expected files on first attempt? YES/NO
3. Did JSON/YAML structures match expected schemas exactly? YES/NO
4. Did you apply any undocumented workarounds? YES/NO

---

## Step 7.2: Collect Issues

For each issue encountered, note:

1. **What you expected** - The documented behavior or path
2. **What actually happened** - The actual behavior or error
3. **How you resolved it** - The workaround applied

### Issue Types (findings-creator specific)

| Type | Description | Example |
|------|-------------|---------|
| `script_path` | Script not at expected location | create-entity.sh moved to different directory |
| `script_error` | Script returned non-zero exit code | create-entity.sh exit 122 |
| `schema_mismatch` | JSON structure differs from spec | finding-entity frontmatter missing required fields |
| `file_not_found` | Expected file doesn't exist | Refined question file, entity-index.json, template |
| `parameter_mismatch` | Parameters differ from spec | REFINED_QUESTION_PATH path mismatch |
| `tool_failure` | Claude tool returned error | WebSearch timeout, WebFetch failed, Read failed |
| `parse_error` | Could not parse expected format | Invalid YAML frontmatter in refined question |
| `silent_adaptation` | Undocumented adjustment made | Fallback to snippet when WebFetch fails, quality filter adjustments |
| `context_contamination` | Cross-question leakage detected | Config IDs referencing wrong question, cached PICOT keywords from prior execution |

### Severity Levels

| Severity | Criteria |
|----------|----------|
| **error** | Required manual intervention OR degraded output quality |
| **warning** | Recovered automatically but indicates fragility |
| **info** | Minor adaptation, no impact on results |

---

## Step 7.3: Create JSON Report

Generate a JSON object following this schema:

```json
{
  "timestamp": "2025-01-15T10:30:45Z",
  "skill": "findings-creator",
  "session_id": "unique-execution-id",
  "question_id": "question-nachhaltige-geschaeftsmodelle-g9h0i1j2",
  "phases_executed": ["0", "1", "2", "3", "4", "5", "5.7", "6"],
  "issues": [
    {
      "type": "script_path|schema_mismatch|file_not_found|...",
      "severity": "error|warning|info",
      "phase": "0-6",
      "expected": "what was expected",
      "actual": "what happened",
      "resolution": "how it was resolved"
    }
  ],
  "success": true,
  "notes": "optional observations about execution"
}
```

### Field Specifications

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `timestamp` | string | ✅ | ISO-8601 format |
| `skill` | string | ✅ | Always "findings-creator" |
| `session_id` | string | ✅ | Unique identifier for this execution (fc-{timestamp_suffix}) |
| `question_id` | string | ✅ | The refined question ID processed |
| `phases_executed` | array | ✅ | List of phase numbers completed |
| `issues` | array | ✅ | List of issues (empty if none) |
| `success` | boolean | ✅ | false only if issues degraded output quality |
| `notes` | string | ❌ | Optional observations |

### If No Issues Occurred

```json
{"timestamp":"2025-01-15T10:30:45Z","skill":"findings-creator","session_id":"fc-abc123","question_id":"question-nachhaltige-geschaeftsmodelle-g9h0i1j2","phases_executed":["0","1","2","3","4","5","6","7"],"issues":[],"success":true,"notes":null}
```

---

## Step 7.4: Append to JSONL Log

```bash
# Ensure log directory exists
mkdir -p "${PROJECT_PATH}/.logs"

# Generate session ID (fc- prefix for findings-creator)
SESSION_ID="fc-$(date +%s | tail -c 9)"

# Append report as single JSON line (JSONL format)
echo '{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","skill":"findings-creator","session_id":"'"$SESSION_ID"'","question_id":"'"$REFINED_QUESTION_ID"'",...}' >> "${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl"

log_phase "Phase 7: LLM Execution Report" "complete"
log_metric "llm_issues_count" "${issue_count}" "count"
```

**Report Location:** `${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl`

**Format:** JSONL (one JSON object per line) - enables pattern analysis across executions

---

## Phase Completion Checklist

⛔ **GATE CHECK:** Before marking Phase 7 complete, verify:

- [ ] DEBUG_MODE was checked at phase start
- [ ] All phases 0-6 were reviewed for issues
- [ ] Each issue has type, severity, expected, actual, resolution
- [ ] JSON report follows schema exactly
- [ ] Report appended to `${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl`
- [ ] `success` field reflects actual outcome quality
- [ ] `question_id` field contains the REFINED_QUESTION_ID

---

## Analysis Examples

After multiple executions, analyze accumulated reports:

```bash
# Count issues by type for findings-creator
cat "${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl" | \
  jq -r '.issues[].type' | sort | uniq -c | sort -rn

# View recent errors
cat "${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl" | \
  jq -r 'select(.issues[].severity == "error") | "\(.timestamp) \(.issues[] | select(.severity == "error") | .resolution)"' | \
  tail -5

# Find recurring script path issues
cat "${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl" | \
  jq -r 'select(.issues[].type == "script_path") | .issues[] | select(.type == "script_path") | "\(.expected) → \(.actual)"' | \
  sort | uniq -c | sort -rn

# Find context contamination patterns
cat "${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl" | \
  jq -r 'select(.issues[].type == "context_contamination") | "\(.question_id): \(.issues[] | select(.type == "context_contamination") | .resolution)"' | \
  tail -10
```

---

## Benefits for findings-creator

1. **Surface hidden script path issues** - Detect when create-entity.sh moves but skill doesn't update
2. **Track schema drift** - Identify when finding-entity.schema.json structure changes
3. **Monitor WebFetch reliability** - Know when WebFetch fails and fallback to snippet is used
4. **Debug quality filter edge cases** - Understand when 4-dimension scoring behaves unexpectedly
5. **Detect context contamination** - Track cross-question leakage from prior executions
6. **Correlate with other layers** - Combine with Layer 1-3 logs for full visibility

---

## Navigation

- **Previous:** [phase-5-review.md](phase-5-review.md)
- **Parent:** [workflow-overview.md](workflow-overview.md)
