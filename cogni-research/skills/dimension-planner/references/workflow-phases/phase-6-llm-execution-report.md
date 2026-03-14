# Phase 6: LLM Execution Report

**Reference Checksum:** `sha256:v1.0`

**Verification Protocol:** After reading, confirm: `Reference Loaded: phase-6-llm-execution-report.md | Checksum: v1.0`

---

## Objective

Capture silent adaptations and workarounds that occurred during skill execution - issues NOT captured by structured logging (Layer 4 of debugging architecture).

**Specification:** [LLM Execution Report](https://github.com/cogni-work/dev-work/blob/main/references/debugging/llm-execution-report.md)

---

## Execution Start

Begin execution:

```bash
log_phase "Phase 6: LLM Execution Report" "start"
```

---

## Step 6.0: Initialize Phase TodoWrite

Expand phase-level todo to step-level:

```
Phase 6: LLM Execution Report [in_progress]
  └─ Step 6.1: Reflect on execution [pending]
  └─ Step 6.2: Collect issues [pending]
  └─ Step 6.3: Create JSON report [pending]
  └─ Step 6.4: Append to JSONL log [pending]
```

---

## Step 6.1: Reflect on Execution

Review your execution of Phases 0-5. Document any of the following:

| Category | What to Look For |
|----------|------------------|
| **Scripts** | Scripts not at expected location (validate-environment.sh, detect-research-mode.sh, unpack-dimension-plan-batch.sh) |
| **Tool Calls** | Tool calls that failed or returned errors |
| **Files** | Files you couldn't find (question file, template files, reference files) |
| **Schemas** | Schema/format mismatches you had to work around (dimension-plan-batch.json structure) |
| **Parameters** | Parameters that didn't match the specification (DOK levels, MECE thresholds, FINER scores) |
| **Adaptations** | Any improvisation or fallback logic you applied |

**Self-Verification Questions:**

1. Did any script call fail or return unexpected output? YES/NO
2. Did you find all expected files on first attempt? YES/NO
3. Did JSON structures match expected schemas exactly? YES/NO
4. Did you apply any undocumented workarounds? YES/NO

---

## Step 6.2: Collect Issues

For each issue encountered, note:

1. **What you expected** - The documented behavior or path
2. **What actually happened** - The actual behavior or error
3. **How you resolved it** - The workaround applied

### Issue Types (dimension-planner specific)

| Type | Description | Example |
|------|-------------|---------|
| `script_path` | Script not at expected location | validate-environment.sh moved to different directory |
| `script_error` | Script returned non-zero exit code | unpack-dimension-plan-batch.sh exit 1 |
| `schema_mismatch` | JSON structure differs from spec | dimension-plan-batch.json wrong nesting |
| `file_not_found` | Expected file doesn't exist | Question file, template, reference |
| `parameter_mismatch` | Parameters differ from spec | Wrong DOK level format |
| `tool_failure` | Claude tool returned error | Grep timeout, Read failed |
| `parse_error` | Could not parse expected format | Invalid JSON in script output |
| `silent_adaptation` | Undocumented adjustment made | Fallback to default values |

### Severity Levels

| Severity | Criteria |
|----------|----------|
| **error** | Required manual intervention OR degraded output quality |
| **warning** | Recovered automatically but indicates fragility |
| **info** | Minor adaptation, no impact on results |

---

## Step 6.3: Create JSON Report

Generate a JSON object following this schema:

```json
{
  "timestamp": "2025-01-15T10:30:45Z",
  "skill": "dimension-planner",
  "session_id": "unique-execution-id",
  "research_type": "generic|smarter-service|lean-canvas",
  "phases_executed": ["0", "1", "2", "3", "4", "5"],
  "issues": [
    {
      "type": "script_path|schema_mismatch|file_not_found|...",
      "severity": "error|warning|info",
      "phase": "0-5",
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
| `skill` | string | ✅ | Always "dimension-planner" |
| `session_id` | string | ✅ | Unique identifier for this execution |
| `research_type` | string | ✅ | The detected research type |
| `phases_executed` | array | ✅ | List of phase numbers completed |
| `issues` | array | ✅ | List of issues (empty if none) |
| `success` | boolean | ✅ | false only if issues degraded output quality |
| `notes` | string | ❌ | Optional observations |

### If No Issues Occurred

```json
{"timestamp":"2025-01-15T10:30:45Z","skill":"dimension-planner","session_id":"dp-abc123","research_type":"smarter-service","phases_executed":["0","1","2","3","4","5"],"issues":[],"success":true,"notes":null}
```

---

## Step 6.4: Append to JSONL Log

```bash
# Ensure log directory exists
mkdir -p "${PROJECT_PATH}/.logs"

# Generate session ID
SESSION_ID="dp-$(date +%s | tail -c 9)"

# Append report as single JSON line (JSONL format)
echo '{"timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","skill":"dimension-planner","session_id":"'"$SESSION_ID"'",...}' >> "${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl"

log_phase "Phase 6: LLM Execution Report" "complete"
log_metric "llm_issues_count" "${issue_count}" "count"
```

**Report Location:** `${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl`

**Format:** JSONL (one JSON object per line) - enables pattern analysis across executions

---

## Phase Completion Checklist

⛔ **GATE CHECK:** Before marking Phase 6 complete, verify:

- [ ] All phases 0-5 were reviewed for issues
- [ ] Each issue has type, severity, expected, actual, resolution
- [ ] JSON report follows schema exactly
- [ ] Report appended to `${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl`
- [ ] `success` field reflects actual outcome quality

---

## Analysis Examples

After multiple executions, analyze accumulated reports:

```bash
# Count issues by type for dimension-planner
cat "${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl" | \
  jq -r '.issues[].type' | sort | uniq -c | sort -rn

# View recent errors
cat "${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl" | \
  jq -r 'select(.issues[].severity == "error") | "\(.timestamp) \(.issues[] | select(.severity == "error") | .resolution)"' | \
  tail -5

# Find recurring script path issues
cat "${PROJECT_PATH}/.logs/dimension-planner-llm-report.jsonl" | \
  jq -r 'select(.issues[].type == "script_path") | .issues[] | select(.type == "script_path") | "\(.expected) → \(.actual)"' | \
  sort | uniq -c | sort -rn
```

---

## Benefits for dimension-planner

1. **Surface hidden script path issues** - Detect when scripts move but skill doesn't update
2. **Track schema drift** - Identify when dimension-plan-batch.json structure changes
3. **Monitor template availability** - Know when research-type templates are missing
4. **Debug MECE/FINER failures** - Understand why validation thresholds weren't met
5. **Correlate with other layers** - Combine with Layer 1-3 logs for full visibility

---

## Navigation

- **Previous:** [phase-5-entity-creation.md](phase-5-entity-creation.md)
- **Parent:** [workflow-overview.md](workflow-overview.md)
- **Specification:** [LLM Execution Report](https://github.com/cogni-work/dev-work/blob/main/references/debugging/llm-execution-report.md)
