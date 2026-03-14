# Deeper Research Plugin - Debugging Guide

**Version:** 1.0.0
**Last Updated:** 2025-11-08
**Plugin:** cogni-research

---

## Table of Contents

1. [Overview](#1-overview)
2. [Quick Start](#2-quick-start)
3. [Logging Utilities Reference](#3-logging-utilities-reference)
4. [Migration Guide for Agents](#4-migration-guide-for-agents)
5. [Troubleshooting](#5-troubleshooting)
6. [Examples](#6-examples)
7. [Best Practices](#7-best-practices)

---

## 1. Overview

### Purpose of DEBUG_MODE

The `DEBUG_MODE` feature provides conditional logging control for the deeper-research plugin, allowing developers to:

- **Enable verbose logging** during development and troubleshooting
- **Reduce stderr noise** in production environments
- **Maintain comprehensive file logs** regardless of console output settings
- **Track execution context** across distributed agent workflows

DEBUG_MODE controls **stderr verbosity** while preserving complete execution history in log files.

### When to Enable Debugging

Enable DEBUG_MODE when you need to:

- **Troubleshoot agent execution failures** (metadata validation, entity creation)
- **Analyze performance bottlenecks** (processing times, partition statistics)
- **Verify workflow transitions** (phase boundaries, data flow between agents)
- **Diagnose missing or incomplete data** (entity counts, backlink updates)
- **Audit script path resolution** (CLAUDE_PLUGIN_ROOT validation)
- **Track down silent failures** (skipped sources, validation errors)

### Impact on Performance and Output

| Aspect | DEBUG_MODE=false | DEBUG_MODE=true |
|--------|------------------|-----------------|
| **Stderr Output** | ERROR, WARN only | All levels (ERROR, WARN, INFO, DEBUG, TRACE) |
| **Log File** | All levels written | All levels written (no change) |
| **Performance** | Minimal overhead | ~5-10% overhead (I/O for stderr) |
| **Disk Usage** | Full logs always written | Full logs always written (no change) |
| **Phase Logs** | Always visible | Always visible (high importance) |
| **Metrics** | Always visible | Always visible (high importance) |

**Key Takeaway:** Log files always contain complete execution history. DEBUG_MODE only affects what you see in the terminal.

---

## 2. Quick Start

### Setting DEBUG_MODE in .claude/settings.local.json

**Step 1: Locate or Create Settings File**

The settings file should be at: `~/.claude/settings.local.json`

If it doesn't exist, create it:

```bash
mkdir -p ~/.claude
cat > ~/.claude/settings.local.json <<'EOF'
{
  "DEBUG_MODE": "true",
  "CLAUDE_PLUGIN_ROOT": "/Users/YOUR_USERNAME/.claude/plugins/marketplaces/cogni-research"
}
EOF
```

**Step 2: Enable DEBUG_MODE**

Edit `~/.claude/settings.local.json` and set:

```json
{
  "DEBUG_MODE": "true",
  "CLAUDE_PLUGIN_ROOT": "/Users/stephandehaas/.claude/plugins/marketplaces/cogni-research"
}
```

**Step 3: Verify Configuration**

```bash
# Test environment variable loading
source ~/.claude/settings.local.json 2>/dev/null || echo "Settings file loaded"
echo "DEBUG_MODE=${DEBUG_MODE:-false}"
```

### Running Research with Debug Enabled

**Option A: Global DEBUG_MODE (via settings.local.json)**

```bash
# DEBUG_MODE is automatically loaded from settings.local.json
# Run any deeper-research workflow normally
```

**Option B: Per-Execution Override**

```bash
# Override for single execution
DEBUG_MODE=true bash your-agent-script.sh --project-path /path/to/project
```

**Option C: Disable for Production**

```bash
# Temporarily disable debug output
DEBUG_MODE=false bash your-agent-script.sh --project-path /path/to/project
```

### Viewing Logs

**View Execution Logs with Color:**

```bash
bash /path/to/cogni-research/scripts/view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt
```

**View Specific Phase:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --phase 3
```

**Filter by Error Level:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --level ERROR
```

**Search for Pattern:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --search "validation failed"
```

---

## 3. Logging Utilities Reference

### 3.1 enhanced-logging.sh

**Location:** `/scripts/utils/enhanced-logging.sh`

**Purpose:** Core logging functions with DEBUG_MODE-aware conditional output

#### Functions

##### log_conditional

**Signature:**
```bash
log_conditional <level> <message>
```

**Description:** Logs messages with conditional stderr output based on DEBUG_MODE and log level.

**Levels:**
- `ERROR` - Critical failures (always to stderr)
- `WARN` - Warnings and skipped operations (always to stderr)
- `INFO` - High-level workflow information (DEBUG_MODE only)
- `DEBUG` - Detailed diagnostic information (DEBUG_MODE only)
- `TRACE` - Granular execution traces (DEBUG_MODE only)

**Always Written To:**
- Log file (if `LOG_FILE` is set)

**Conditionally Written To:**
- Stderr (based on `DEBUG_MODE` and level)

**Usage Examples:**

```bash
# Source the utility
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Log at different levels
log_conditional INFO "Processing started for 23 findings"
log_conditional DEBUG "Extracted URL: https://example.com/article"
log_conditional TRACE "Calling generate-semantic-slug.sh with title='Example Article'"
log_conditional ERROR "Entity creation failed: missing required field 'url'"
log_conditional WARN "Skipping source due to invalid domain format"
```

**Output Format:**

```
[2025-11-08T14:32:15Z] [INFO] source-creator: Processing started for 23 findings
[2025-11-08T14:32:16Z] [DEBUG] source-creator: Extracted URL: https://example.com/article
[2025-11-08T14:32:17Z] [ERROR] source-creator: Entity creation failed: missing required field 'url'
```

##### log_phase

**Signature:**
```bash
log_phase <phase_name> <status>
```

**Description:** Logs phase transitions with special formatting. **Always outputs to stderr** regardless of DEBUG_MODE (high importance).

**Parameters:**
- `phase_name` - Human-readable phase name (e.g., "Entity Creation")
- `status` - Either "start" or "complete"

**Usage Examples:**

```bash
log_phase "Metadata Extraction & Validation" "start"
# ... perform work ...
log_phase "Metadata Extraction & Validation" "complete"
```

**Output Format:**

```
[2025-11-08T14:32:15Z] [PHASE] ========== Metadata Extraction & Validation [start] ==========
[2025-11-08T14:32:45Z] [PHASE] ========== Metadata Extraction & Validation [complete] ==========
```

##### log_metric

**Signature:**
```bash
log_metric <metric_name> <value> <unit>
```

**Description:** Logs performance metrics in structured format. **Always outputs to stderr** (high importance).

**Parameters:**
- `metric_name` - Metric identifier (e.g., "entities_created")
- `value` - Numeric value
- `unit` - Unit of measurement (e.g., "count", "seconds", "MB")

**Usage Examples:**

```bash
log_metric "entities_created" 42 "count"
log_metric "processing_time" 1.5 "seconds"
log_metric "memory_used" 256 "MB"
log_metric "avg_confidence" 0.87 "score"
```

**Output Format:**

```
[2025-11-08T14:32:45Z] [METRIC] entities_created=42 unit=count
[2025-11-08T14:32:45Z] [METRIC] processing_time=1.5 unit=seconds
```

#### Environment Variables

**DEBUG_MODE**
- Type: Boolean string (`"true"` or `"false"`)
- Default: `"false"`
- Source: `~/.claude/settings.local.json`
- Controls: Stderr verbosity for INFO, DEBUG, TRACE levels

**LOG_FILE**
- Type: Absolute file path
- Default: Unset (skips file writes if not provided)
- Typically set to: `${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt`
- Controls: Where log entries are written

#### Integration Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

# Initialize agent context
AGENT_NAME="source-creator"
PROJECT_PATH="$1"
LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"

# Ensure reports directory exists
mkdir -p "${PROJECT_PATH}/.metadata"

# Source enhanced logging
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize log file
echo "========================================" >> "$LOG_FILE"
echo "Execution Log: $AGENT_NAME" >> "$LOG_FILE"
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# Use logging functions
log_phase "Input Validation" "start"
log_conditional INFO "Validating project path: $PROJECT_PATH"
log_conditional DEBUG "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT}"
log_phase "Input Validation" "complete"
```

---

### 3.2 log-execution-context.sh

**Location:** `/scripts/utils/log-execution-context.sh`

**Purpose:** Captures complete execution environment for debugging and reproducibility

#### How It Captures Environment

The script collects:

1. **Timestamp** - ISO 8601 UTC timestamp
2. **Environment Variables**
   - `CLAUDE_PLUGIN_ROOT` - Plugin installation path
   - `DEBUG_MODE` - Current debug mode setting
   - `BASH_VERSION` - Bash interpreter version
3. **System Information**
   - Hostname
   - Current working directory
4. **Git Context** (if available)
   - Current commit hash
   - Current branch name
   - Git availability status
5. **Execution Parameters**
   - Project path
   - Agent name

#### Usage in Agents

**Standalone Mode (JSON to stdout):**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh" \
  --project-path /path/to/project \
  --agent-name source-creator \
  --json
```

**Sourceable Mode (sets EXECUTION_CONTEXT_JSON variable):**

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh"

log_execution_context \
  --project-path "$PROJECT_PATH" \
  --agent-name "$AGENT_NAME"

# Use the context
echo "$EXECUTION_CONTEXT_JSON" > "${PROJECT_PATH}/.metadata/execution-context.json"
```

#### Output Format

```json
{
  "success": true,
  "timestamp": "2025-11-08T14:32:15Z",
  "environment": {
    "claude_plugin_root": "/Users/stephandehaas/.claude/plugins/marketplaces/cogni-research",
    "debug_mode": "true",
    "hostname": "MacBook-Pro.local",
    "bash_version": "3.2.57(1)-release",
    "working_directory": "/Users/stephandehaas/research-project"
  },
  "execution": {
    "project_path": "/Users/stephandehaas/research-project",
    "agent_name": "source-creator"
  },
  "git": {
    "commit": "09f3ae1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q",
    "branch": "main",
    "available": true
  }
}
```

---

### 3.3 aggregate-execution-logs.sh

**Location:** `/scripts/aggregate-execution-logs.sh`

**Purpose:** Aggregates partition statistics and execution logs from completed research projects

#### Aggregating Partition Stats

**Command:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/aggregate-execution-logs.sh" \
  --project-path /path/to/research-project \
  --output-format markdown
```

**What It Aggregates:**

1. **Partition Statistics** (from `partition-*-stats.json` files):
   - Total partitions vs partitions found
   - Findings processed across all partitions
   - Claims created (with weighted averages)
   - Confidence metrics (confidence, evidence confidence, claim quality)
   - Quality dimensions (atomicity, fluency, decontextualization, faithfulness)
   - Flagged items and error counts

2. **Execution Logs** (from `*-execution-log.txt` files):
   - List of agents executed
   - Total ERROR occurrences
   - Total WARN occurrences

#### JSON vs Markdown Output

**JSON Output (--json or --output-format json):**

```bash
bash aggregate-execution-logs.sh \
  --project-path /path/to/project \
  --json
```

**Output Structure:**

```json
{
  "success": true,
  "data": {
    "project_path": "/path/to/project",
    "aggregated_at": "2025-11-08T14:45:00Z",
    "partition_stats": {
      "total_partitions": 4,
      "partitions_found": 4,
      "findings_processed": 156,
      "claims_created": 312,
      "avg_confidence": 0.867,
      "avg_evidence_confidence": 0.823,
      "avg_claim_quality": 0.891,
      "total_flagged": 12,
      "total_errors": 3,
      "quality_averages": {
        "atomicity": 0.901,
        "fluency": 0.945,
        "decontextualization": 0.812,
        "faithfulness": 0.878
      }
    },
    "execution_summary": {
      "agents_executed": ["source-creator", "fact-checker", "citation-generator"],
      "total_errors": 5,
      "total_warnings": 18
    }
  }
}
```

**Markdown Output (--output-format markdown):**

```bash
bash aggregate-execution-logs.sh \
  --project-path /path/to/project \
  --output-format markdown
```

**Output:**

```markdown
# Deeper Research Execution Summary

**Project:** /path/to/project
**Generated:** 2025-11-08T14:45:00Z

## Partition Statistics

- **Total Partitions:** 4
- **Partitions Found:** 4
- **Findings Processed:** 156
- **Claims Created:** 312
- **Total Flagged for Review:** 12
- **Total Errors:** 3

### Confidence Metrics

- **Average Confidence:** 0.867
- **Average Evidence Confidence:** 0.823
- **Average Claim Quality:** 0.891

### Quality Dimensions

- **Atomicity:** 0.901
- **Fluency:** 0.945
- **Decontextualization:** 0.812
- **Faithfulness:** 0.878

## Execution Summary

- **Agents Executed:** source-creator, fact-checker, citation-generator
- **Total Errors in Logs:** 5
- **Total Warnings in Logs:** 18

**WARNING:** 5 error(s) found in execution logs. Review logs for details.
**NOTE:** 18 warning(s) found in execution logs.
```

#### Example Commands

**Quick JSON Summary:**

```bash
bash aggregate-execution-logs.sh --project-path ~/research/my-project --json
```

**Human-Readable Report:**

```bash
bash aggregate-execution-logs.sh \
  --project-path ~/research/my-project \
  --output-format markdown > summary.md
```

**Pipe to jq for Analysis:**

```bash
bash aggregate-execution-logs.sh \
  --project-path ~/research/my-project \
  --json | jq '.data.partition_stats.avg_confidence'
```

---

### 3.4 view-execution-log.sh

**Location:** `/scripts/view-execution-log.sh`

**Purpose:** Interactive CLI tool for navigating execution logs with filtering and search

#### Navigating Logs by Phase

**View Specific Phase:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --phase 3
```

**Output:** Shows only log entries from Phase 3 with line numbers and color coding.

**How Phase Detection Works:**
- Looks for `Phase N:` markers in log file
- Extracts content between phase boundaries
- Preserves all entries within that phase

#### Filtering by Level

**Show Only Errors:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --level ERROR
```

**Show Only Warnings:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --level WARN
```

**Show Debug Information:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --level DEBUG
```

**Combine Phase + Level:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --phase 2 \
  --level ERROR
```

**Supported Levels:** ERROR, WARN, INFO, DEBUG, TRACE

#### Searching Patterns

**Search with Context (2 lines before/after):**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --search "validation failed"
```

**Search for URL Patterns:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --search "https://"
```

**Search for Specific Entity IDs:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --search "source-.*-uuid"
```

#### Color Output

**Color-Coded Levels:**

- **RED** - [ERROR] entries
- **YELLOW** - [WARN] entries
- **GREEN** - [INFO] entries
- **CYAN** - [DEBUG] entries
- **GRAY** - [TRACE] entries
- **BOLD** - Phase markers

**Disable Color:**

```bash
bash view-execution-log.sh \
  --log-file .logs/source-creator-execution-log.txt \
  --no-color
```

**Color Support:**
- Automatically detects terminal capabilities
- Disables color for pipes and non-TTY outputs
- Uses ANSI escape sequences (compatible with most terminals)

**Pagination:**
- Automatically uses `less -R` (preserves colors) if available
- Falls back to `more` or `cat` if `less` not found
- Only paginates if output exceeds terminal height

---

## 4. Migration Guide for Agents

### Step-by-Step Process to Update an Agent

**Phase 1: Add Enhanced Logging**

1. **Source the enhanced logging utility** at the top of your agent script:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Set agent name
AGENT_NAME="your-agent-name"

# Source enhanced logging
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
```

2. **Initialize log file** in Phase 1 (Input Validation):

```bash
# Initialize logging
LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.metadata"

echo "========================================" >> "$LOG_FILE"
echo "Execution Log: $AGENT_NAME" >> "$LOG_FILE"
echo "Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
```

**Phase 2: Replace Existing Logging**

Replace all existing logging patterns with enhanced logging functions:

**Old Pattern:**

```bash
echo "Processing started" >&2
echo "[$(date)] Processing finding: $FINDING_FILE" >&2
echo "ERROR: Validation failed" >&2
```

**New Pattern:**

```bash
log_conditional INFO "Processing started"
log_conditional DEBUG "Processing finding: $FINDING_FILE"
log_conditional ERROR "Validation failed"
```

**Phase 3: Add Phase Markers**

Add phase transition markers at major workflow boundaries:

```bash
log_phase "Input Validation & Logging Initialization" "start"
# ... validation logic ...
log_phase "Input Validation & Logging Initialization" "complete"

log_phase "Metadata Extraction & Validation" "start"
# ... extraction logic ...
log_phase "Metadata Extraction & Validation" "complete"

log_phase "Entity Creation" "start"
# ... creation logic ...
log_phase "Entity Creation" "complete"
```

**Phase 4: Add Metrics**

Add metric logging for key performance indicators:

```bash
log_metric "entities_created" $sources_created "count"
log_metric "entities_reused" $sources_reused "count"
log_metric "processing_time" $elapsed_seconds "seconds"
```

**Phase 5: Add Execution Context**

Add execution context capture at agent start:

```bash
# Capture execution context
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh"
log_execution_context --project-path "$PROJECT_PATH" --agent-name "$AGENT_NAME"
echo "$EXECUTION_CONTEXT_JSON" > "${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-context.json"
```

### Reference: source-creator Agent as Example

**File:** `agents/source-creator.md`

**Key Migration Points:**

1. **Phase 0: Environment Validation** (Lines 117-150)
   - Validates CLAUDE_PLUGIN_ROOT
   - Changes working directory to PROJECT_PATH
   - Sets default language

2. **Phase 1: Input Validation & Logging Initialization** (Lines 157-215)
   - Sources enhanced-logging.sh
   - Initializes LOG_FILE
   - Defines logging utility wrapper (compatibility)
   - Sets script paths using CLAUDE_PLUGIN_ROOT

3. **Phase 2: Metadata Extraction** (Lines 221-498)
   - Uses log_conditional for all diagnostic output
   - TRACE level for script invocations
   - DEBUG level for extracted values
   - ERROR level for validation failures

4. **Phase 3: Entity Creation** (Lines 500-683)
   - Phase markers for workflow boundaries
   - TRACE level for create-entity.sh calls
   - INFO level for creation/reuse results

5. **Phase 4: Report Generation** (Lines 685-806)
   - Comprehensive logging of statistics
   - DEBUG level for completeness validation

6. **Phase 5: Final Response** (Lines 808-839)
   - Summary metrics logged at INFO level
   - Execution completion marker

### Before/After Comparison

**Before (Basic Logging):**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Processing findings..." >&2

for finding in $FINDING_FILES; do
  echo "Processing $finding" >&2

  # Extract metadata
  URL=$(grep "source_url:" "$finding" | cut -d':' -f2-)

  if [ -z "$URL" ]; then
    echo "ERROR: Missing URL in $finding" >&2
    continue
  fi

  echo "Creating entity..." >&2
  # ... entity creation ...
done

echo "Done" >&2
```

**After (Enhanced Logging):**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Initialize
AGENT_NAME="example-agent"
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.metadata"

log_phase "Finding Processing" "start"
log_conditional INFO "Processing findings: total count=$(echo $FINDING_FILES | wc -w)"

for finding in $FINDING_FILES; do
  log_conditional DEBUG "Processing finding: $finding"

  # Extract metadata
  URL=$(grep "source_url:" "$finding" | cut -d':' -f2-)
  log_conditional TRACE "Extracted URL: $URL"

  if [ -z "$URL" ]; then
    log_conditional ERROR "Missing URL in $finding"
    continue
  fi

  log_conditional INFO "Creating entity for $finding"
  # ... entity creation ...
done

log_phase "Finding Processing" "complete"
log_metric "findings_processed" $(echo $FINDING_FILES | wc -w) "count"
```

**Key Improvements:**

1. **Conditional Verbosity:** DEBUG/TRACE only shown when DEBUG_MODE=true
2. **Structured Phases:** Clear workflow boundaries
3. **Performance Metrics:** Quantifiable execution statistics
4. **Complete Audit Trail:** All logs persisted to file
5. **Context Preservation:** Execution environment captured

### Testing Checklist

After migrating an agent, verify:

- [ ] Agent sources `enhanced-logging.sh` successfully
- [ ] LOG_FILE is created in `.logs/` directory
- [ ] Phase markers appear in log (use `view-execution-log.sh --phase 1`)
- [ ] ERROR/WARN messages always appear on stderr
- [ ] INFO/DEBUG/TRACE messages only appear when DEBUG_MODE=true
- [ ] Metrics are logged for key operations
- [ ] Execution context JSON is written
- [ ] No duplicate log entries (check for double-logging)
- [ ] Log file is valid UTF-8 and properly formatted
- [ ] Agent still returns correct JSON output (not polluted with logs)

---

## 5. Troubleshooting

### Common Issues

#### DEBUG_MODE Not Working

**Symptom:** Setting DEBUG_MODE=true doesn't show DEBUG/TRACE logs in terminal

**Possible Causes & Solutions:**

1. **Settings file not loaded**
   ```bash
   # Verify settings file exists
   ls -la ~/.claude/settings.local.json

   # Check content
   cat ~/.claude/settings.local.json | jq '.DEBUG_MODE'
   ```

2. **Environment variable not exported**
   ```bash
   # Verify DEBUG_MODE is set in shell
   echo "DEBUG_MODE=${DEBUG_MODE:-not-set}"

   # Manually export for testing
   export DEBUG_MODE=true
   ```

3. **Agent not sourcing enhanced-logging.sh**
   ```bash
   # Check agent sources logging utility
   grep "enhanced-logging.sh" your-agent-script.sh

   # Verify CLAUDE_PLUGIN_ROOT is set
   echo "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT:-not-set}"
   ```

4. **Using old logging functions**
   ```bash
   # Agent might still use direct echo commands
   # Replace with log_conditional calls

   # Old: echo "Debug info" >&2
   # New: log_conditional DEBUG "Debug info"
   ```

**Verification Test:**

```bash
# Create test script
cat > test-debug.sh <<'EOF'
#!/usr/bin/env bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
log_conditional INFO "This is INFO (DEBUG_MODE only)"
log_conditional ERROR "This is ERROR (always shown)"
EOF

# Test with DEBUG_MODE=false
DEBUG_MODE=false bash test-debug.sh
# Expected: Only ERROR line appears

# Test with DEBUG_MODE=true
DEBUG_MODE=true bash test-debug.sh
# Expected: Both INFO and ERROR appear
```

---

#### Logs Not Appearing

**Symptom:** No log file created or log file is empty

**Possible Causes & Solutions:**

1. **LOG_FILE not set**
   ```bash
   # Check if LOG_FILE variable is defined
   grep "LOG_FILE=" your-agent-script.sh

   # Should see:
   # LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
   ```

2. **Reports directory doesn't exist**
   ```bash
   # Verify reports directory creation
   ls -ld "${PROJECT_PATH}/reports"

   # Add directory creation if missing:
   mkdir -p "${PROJECT_PATH}/.metadata"
   ```

3. **No write permissions**
   ```bash
   # Check directory permissions
   ls -ld "${PROJECT_PATH}/reports"

   # Fix permissions if needed
   chmod 755 "${PROJECT_PATH}/reports"
   ```

4. **Agent crashes before logging initialization**
   ```bash
   # Check for early failures
   bash -x your-agent-script.sh --project-path /path 2>&1 | head -20

   # Look for errors before LOG_FILE initialization
   ```

5. **LOG_FILE path contains invalid characters**
   ```bash
   # Verify LOG_FILE path is valid
   echo "LOG_FILE would be: ${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"

   # Test write
   echo "test" > "${PROJECT_PATH}/.metadata/test.txt"
   ```

**Verification Test:**

```bash
# Minimal logging test
PROJECT_PATH="/tmp/test-project"
AGENT_NAME="test-agent"
mkdir -p "${PROJECT_PATH}/.metadata"

source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"

log_conditional INFO "Test log entry"

# Verify log file created
ls -l "$LOG_FILE"
cat "$LOG_FILE"
```

---

#### Missing Execution Context

**Symptom:** Execution context JSON not created or incomplete

**Possible Causes & Solutions:**

1. **log-execution-context.sh not sourced**
   ```bash
   # Check agent sources context script
   grep "log-execution-context.sh" your-agent-script.sh

   # Should see:
   # source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh"
   ```

2. **Function not called**
   ```bash
   # Check function invocation
   grep "log_execution_context" your-agent-script.sh

   # Should see:
   # log_execution_context --project-path "$PROJECT_PATH" --agent-name "$AGENT_NAME"
   ```

3. **Missing required parameters**
   ```bash
   # Verify both parameters provided
   # Required: --project-path AND --agent-name

   log_execution_context \
     --project-path "$PROJECT_PATH" \
     --agent-name "$AGENT_NAME"
   ```

4. **JSON output not written to file**
   ```bash
   # After calling log_execution_context, write JSON:
   echo "$EXECUTION_CONTEXT_JSON" > "${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-context.json"
   ```

5. **EXECUTION_CONTEXT_JSON variable not exported**
   ```bash
   # Verify variable is set after function call
   log_execution_context --project-path "$PROJECT_PATH" --agent-name "$AGENT_NAME"
   echo "$EXECUTION_CONTEXT_JSON" | jq '.'
   ```

**Verification Test:**

```bash
# Test context capture
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/log-execution-context.sh"

log_execution_context \
  --project-path "/tmp/test-project" \
  --agent-name "test-agent"

# Verify JSON structure
echo "$EXECUTION_CONTEXT_JSON" | jq '.environment.debug_mode'
echo "$EXECUTION_CONTEXT_JSON" | jq '.execution.agent_name'
```

---

#### Aggregation Failures

**Symptom:** aggregate-execution-logs.sh fails or returns empty data

**Possible Causes & Solutions:**

1. **No partition stats files found**
   ```bash
   # Check for partition stats
   ls -l "${PROJECT_PATH}/.metadata/partition-*-stats.json"

   # Should see files like:
   # partition-0-stats.json
   # partition-1-stats.json
   ```

2. **Malformed JSON in stats files**
   ```bash
   # Validate JSON structure
   for file in "${PROJECT_PATH}/.metadata/partition-*-stats.json"; do
     echo "Validating: $file"
     jq '.' "$file" >/dev/null || echo "INVALID JSON: $file"
   done
   ```

3. **Missing required fields in stats**
   ```bash
   # Check for required fields
   jq '.findings_processed, .claims_created' "${PROJECT_PATH}/.metadata/partition-0-stats.json"

   # Should return numbers, not null
   ```

4. **No execution logs found**
   ```bash
   # Check for execution logs
   ls -l "${PROJECT_PATH}/.metadata/*-execution-log.txt"

   # Should see files like:
   # source-creator-execution-log.txt
   # fact-checker-execution-log.txt
   ```

5. **Project path doesn't exist**
   ```bash
   # Verify project directory exists
   ls -ld "${PROJECT_PATH}"
   ls -ld "${PROJECT_PATH}/reports"
   ```

6. **bc command not available** (for weighted average calculations)
   ```bash
   # Check if bc is installed
   which bc

   # Install if missing (macOS):
   # bc is pre-installed on macOS

   # Install if missing (Linux):
   # sudo apt-get install bc
   ```

**Verification Test:**

```bash
# Create minimal test data
PROJECT_PATH="/tmp/test-project"
mkdir -p "${PROJECT_PATH}/.metadata"

# Create fake partition stats
cat > "${PROJECT_PATH}/.metadata/partition-0-stats.json" <<'EOF'
{
  "partition_info": {"total_partitions": 2, "partition_number": 0},
  "findings_processed": 50,
  "claims_created": 100,
  "avg_confidence": 0.85,
  "avg_evidence_confidence": 0.80,
  "avg_claim_quality": 0.90,
  "flagged_for_review": 5,
  "error_count": 2,
  "quality_dimension_averages": {
    "atomicity": 0.88,
    "fluency": 0.92,
    "decontextualization": 0.78,
    "faithfulness": 0.85
  }
}
EOF

# Test aggregation
bash "${CLAUDE_PLUGIN_ROOT}/scripts/aggregate-execution-logs.sh" \
  --project-path "$PROJECT_PATH" \
  --json
```

---

## 6. Examples

### Example 1: Full Workflow - Enable Debug → Run Research → View Logs → Aggregate Results

**Step 1: Enable DEBUG_MODE**

```bash
# Edit settings
cat > ~/.claude/settings.local.json <<'EOF'
{
  "DEBUG_MODE": "true",
  "CLAUDE_PLUGIN_ROOT": "/Users/stephandehaas/.claude/plugins/marketplaces/cogni-research"
}
EOF

# Verify
echo "DEBUG_MODE=${DEBUG_MODE:-false}"
```

**Step 2: Run Research (Example: Source Creator)**

```bash
# Set up test project
PROJECT_PATH="/tmp/research-test"
mkdir -p "${PROJECT_PATH}/01-findings"

# Create test finding
cat > "${PROJECT_PATH}/01-findings/test-finding-001.md" <<'EOF'
---
entity_type: finding
source_url: "https://example.com/article"
access_date: "2025-11-08"
---

# Test Finding

This is a test finding about example topic.
EOF

# Run source-creator agent (example - actual invocation varies)
# First write findings to file
find "${PROJECT_PATH}/04-findings" -name '*.md' -type f > "${PROJECT_PATH}/.metadata/finding-list.txt"
bash your-source-creator-script.sh \
  --project-path "$PROJECT_PATH" \
  --finding-list-file "${PROJECT_PATH}/.metadata/finding-list.txt"
```

**Step 3: View Logs**

```bash
# View full execution log with colors
bash "${CLAUDE_PLUGIN_ROOT}/scripts/view-execution-log.sh" \
  --log-file "${PROJECT_PATH}/.metadata/source-creator-execution-log.txt"

# View only errors
bash view-execution-log.sh \
  --log-file "${PROJECT_PATH}/.metadata/source-creator-execution-log.txt" \
  --level ERROR

# View Phase 2 (Metadata Extraction)
bash view-execution-log.sh \
  --log-file "${PROJECT_PATH}/.metadata/source-creator-execution-log.txt" \
  --phase 2

# Search for specific URL
bash view-execution-log.sh \
  --log-file "${PROJECT_PATH}/.metadata/source-creator-execution-log.txt" \
  --search "example.com"
```

**Step 4: Aggregate Results**

```bash
# Generate markdown summary
bash "${CLAUDE_PLUGIN_ROOT}/scripts/aggregate-execution-logs.sh" \
  --project-path "$PROJECT_PATH" \
  --output-format markdown

# Generate JSON for programmatic access
bash aggregate-execution-logs.sh \
  --project-path "$PROJECT_PATH" \
  --json | jq '.data.partition_stats'
```

**Expected Output (Markdown):**

```markdown
# Deeper Research Execution Summary

**Project:** /tmp/research-test
**Generated:** 2025-11-08T15:30:00Z

## Partition Statistics

- **Total Partitions:** 1
- **Partitions Found:** 1
- **Findings Processed:** 1
- **Claims Created:** 0
- **Total Flagged for Review:** 0
- **Total Errors:** 0

## Execution Summary

- **Agents Executed:** source-creator
- **Total Errors in Logs:** 0
- **Total Warnings in Logs:** 0
```

---

### Example 2: Debugging a Failed Execution

**Scenario:** Source creation fails with "missing required field" error

**Step 1: Enable DEBUG_MODE**

```bash
export DEBUG_MODE=true
```

**Step 2: Run Agent and Capture Full Output**

```bash
find /path/to/findings -name '*.md' -type f > /path/to/project/.metadata/finding-list.txt
bash your-agent-script.sh \
  --project-path /path/to/project \
  --finding-list-file /path/to/project/.metadata/finding-list.txt \
  2>&1 | tee debug-output.txt
```

**Step 3: Check Execution Log for Error Context**

```bash
# Find all errors
bash view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt \
  --level ERROR

# Example error found:
# [2025-11-08T15:45:23Z] [ERROR] Entity creation failed: missing required field 'url'
```

**Step 4: Search for Context Around Error**

```bash
# Search for the specific error with context
bash view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt \
  --search "missing required field"

# Output shows 2 lines before and after:
#  123  [2025-11-08T15:45:22Z] [DEBUG] Extracted URL: source_url: "https://example.com"
#  124  [2025-11-08T15:45:22Z] [WARN] URL validation failed: contains field name
#  125  [2025-11-08T15:45:23Z] [ERROR] Entity creation failed: missing required field 'url'
#  126  [2025-11-08T15:45:23Z] [DEBUG] Finding file: /path/to/findings/bad-finding.md
#  127  [2025-11-08T15:45:23Z] [INFO] Skipping source due to validation failure
```

**Step 5: Identify Root Cause**

From the log context:
- Line 123: URL extracted with field name prefix (`source_url:`)
- Line 124: Validation caught the issue
- Line 126: Identifies the problematic finding file

**Step 6: Fix the Issue**

```bash
# Inspect the problematic finding
cat /path/to/findings/bad-finding.md

# Find the malformed YAML
# Bad:  source_url: source_url: "https://example.com"
# Good: source_url: "https://example.com"
```

**Step 7: Verify Fix**

```bash
# Fix the YAML
sed -i.bak 's/source_url: source_url:/source_url:/' /path/to/findings/bad-finding.md

# Re-run with DEBUG_MODE
echo "/path/to/findings/bad-finding.md" > /path/to/project/.metadata/finding-list.txt
DEBUG_MODE=true bash your-agent-script.sh \
  --project-path /path/to/project \
  --finding-list-file /path/to/project/.metadata/finding-list.txt

# Check for success
bash view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt \
  --level ERROR
# Expected: No new errors
```

---

### Example 3: Finding Specific Errors in Logs

**Scenario:** Research completed but some sources were skipped - need to find why

**Step 1: Check Skipped Sources Report**

```bash
# View skipped sources JSON
cat /path/to/project/.logs/source-creator-skipped-sources.json | jq '.'

# Example output:
# {
#   "success": true,
#   "sources_created": 45,
#   "sources_reused": 12,
#   "citations_created": 0,
#   "skipped_sources": [
#     {
#       "finding_id": "finding-123",
#       "skip_reason": "domain_extraction_failed",
#       "error": "Domain contains invalid characters: example.com:443"
#     }
#   ],
#   "skip_reasons_summary": {
#     "domain_extraction_failed": 1
#   }
# }
```

**Step 2: Search Logs for Specific Finding**

```bash
# Search for the problematic finding
bash view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt \
  --search "finding-123"

# Output shows all log entries mentioning that finding
```

**Step 3: Filter by Skip Reason**

```bash
# Search for all domain extraction failures
bash view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt \
  --search "domain_extraction_failed"
```

**Step 4: Analyze Pattern**

```bash
# Extract all URLs that failed domain extraction
grep "Domain contains invalid characters" \
  /path/to/project/.logs/source-creator-execution-log.txt | \
  sed 's/.*Domain contains invalid characters: //' | \
  sort | uniq -c

# Example output:
# 3 example.com:443
# 2 test.org:8080
# 1 demo.net:3000
```

**Step 5: Fix Data Source**

The pattern shows URLs with port numbers - update extraction logic or clean source data.

---

### Example 4: Analyzing Performance Metrics

**Scenario:** Research took longer than expected - identify bottlenecks

**Step 1: Extract All Metrics**

```bash
# Filter log for METRIC entries
grep "\[METRIC\]" /path/to/project/.logs/source-creator-execution-log.txt

# Example output:
# [2025-11-08T14:32:45Z] [METRIC] entities_created=42 unit=count
# [2025-11-08T14:32:45Z] [METRIC] processing_time=125.3 unit=seconds
# [2025-11-08T14:32:45Z] [METRIC] avg_processing_per_finding=2.98 unit=seconds
```

**Step 2: Calculate Phase Durations**

```bash
# Extract phase markers
grep "\[PHASE\]" /path/to/project/.logs/source-creator-execution-log.txt

# Example output:
# [2025-11-08T14:30:00Z] [PHASE] ========== Phase 1: Input Validation [start] ==========
# [2025-11-08T14:30:02Z] [PHASE] ========== Phase 1: Input Validation [complete] ==========
# [2025-11-08T14:30:02Z] [PHASE] ========== Phase 2: Metadata Extraction [start] ==========
# [2025-11-08T14:32:30Z] [PHASE] ========== Phase 2: Metadata Extraction [complete] ==========
```

**Step 3: Identify Slow Phase**

From timestamps:
- Phase 1: 2 seconds (fast)
- Phase 2: 148 seconds (slow - bottleneck identified)

**Step 4: Drill into Slow Phase**

```bash
# View only Phase 2
bash view-execution-log.sh \
  --log-file /path/to/project/.logs/source-creator-execution-log.txt \
  --phase 2 \
  --level DEBUG

# Look for repeated slow operations
```

**Step 5: Aggregate Across Partitions**

```bash
# Get aggregated metrics
bash aggregate-execution-logs.sh \
  --project-path /path/to/project \
  --json | jq '.data.partition_stats'

# Compare processing rates across partitions
```

---

## 7. Best Practices

### When to Use DEBUG vs TRACE Levels

**Use DEBUG for:**

- **Extracted values** (URLs, titles, IDs)
- **Validation results** (pass/fail with reason)
- **Processing decisions** (skip, reuse, create)
- **Script path verification** (CLAUDE_PLUGIN_ROOT, utility paths)
- **Intermediate calculations** (confidence scores, averages)

**Example:**

```bash
log_conditional DEBUG "Extracted URL: $SOURCE_URL"
log_conditional DEBUG "Domain validation passed: $DOMAIN"
log_conditional DEBUG "Source ID generated: $SOURCE_ID"
log_conditional DEBUG "Reusing existing entity (deduplication match)"
```

**Use TRACE for:**

- **Function call parameters** (before invoking utilities)
- **Script invocation details** (full command with args)
- **Raw output from utilities** (first 200 chars)
- **Loop iterations** (detailed per-item processing)
- **Variable state dumps** (for complex debugging)

**Example:**

```bash
log_conditional TRACE "Calling extract-finding-title.sh"
log_conditional TRACE "  Script path: $SCRIPT_EXTRACT_TITLE"
log_conditional TRACE "  Finding file: $FINDING_FILE"
log_conditional TRACE "  Expected output: JSON with normalized_title field"

# After call
log_conditional TRACE "Script output (first 200 chars): ${title_result:0:200}"
```

**Use INFO for:**

- **Phase completion summaries**
- **Entity creation confirmations**
- **High-level workflow progress**
- **Final statistics**

**Use WARN for:**

- **Skipped operations** (with reason)
- **Data quality issues** (missing optional fields)
- **Unexpected but recoverable states**

**Use ERROR for:**

- **Critical failures** (validation failed, script crashed)
- **Missing required data**
- **Unrecoverable errors**

### Log File Organization

**Standard Structure:**

```
project-path/
└── .logs/
    ├── source-creator-execution-log.txt
    ├── source-creator-execution-context.json
    ├── source-creator-skipped-sources.json
    ├── fact-checker-execution-log.txt
    ├── fact-checker-execution-context.json
    ├── partition-0-stats.json
    ├── partition-1-stats.json
    └── aggregated-summary.md
```

**Naming Convention:**

- Execution logs: `{agent-name}-execution-log.txt`
- Context files: `{agent-name}-execution-context.json`
- Agent-specific reports: `{agent-name}-{report-type}.json`
- Partition stats: `partition-{N}-stats.json`
- Aggregated reports: `aggregated-{type}.{format}`

**Retention Policy:**

- **Keep execution logs** for debugging (can be large)
- **Keep context JSON** for reproducibility
- **Archive old reports** after aggregation
- **Delete temp files** (*.bak, *.tmp) after successful runs

**Log Rotation:**

For long-running or repeated executions:

```bash
# Timestamp log files
LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-$(date +%Y%m%d-%H%M%S).log"

# Or append to existing
LOG_FILE="${PROJECT_PATH}/.metadata/${AGENT_NAME}-execution-log.txt"
echo "" >> "$LOG_FILE"
echo "========== NEW EXECUTION: $(date) ==========" >> "$LOG_FILE"
```

### Performance Considerations

**DEBUG_MODE Impact:**

| Operation | DEBUG_MODE=false | DEBUG_MODE=true | Overhead |
|-----------|------------------|-----------------|----------|
| File writes | Always performed | Always performed | 0% |
| Stderr output | ERROR/WARN only | All levels | +5-10% |
| String formatting | Minimal | All log calls | +2-3% |
| Overall | Baseline | +7-13% | Acceptable for debugging |

**Optimization Tips:**

1. **Use DEBUG_MODE=false in production**
   ```bash
   # Production runs
   DEBUG_MODE=false bash research-workflow.sh
   ```

2. **Avoid excessive TRACE logging in loops**
   ```bash
   # Bad (logs every iteration):
   for i in $(seq 1 1000); do
     log_conditional TRACE "Processing item $i"
   done

   # Good (log summary):
   log_conditional DEBUG "Processing 1000 items"
   # ... loop ...
   log_conditional DEBUG "Completed 1000 items"
   ```

3. **Lazy string evaluation** (bash doesn't support this natively, but be mindful):
   ```bash
   # Only construct expensive debug strings if DEBUG_MODE=true
   if [ "$DEBUG_MODE" = "true" ]; then
     EXPENSIVE_DEBUG_INFO=$(complex_calculation)
     log_conditional TRACE "Complex data: $EXPENSIVE_DEBUG_INFO"
   fi
   ```

4. **Batch log writes** (already handled by log file buffering)
   - Log file writes are buffered by OS
   - No need for manual batching

5. **Monitor log file size**
   ```bash
   # Check log file size
   ls -lh "${PROJECT_PATH}/.metadata/*.txt"

   # Compress old logs
   gzip "${PROJECT_PATH}/.metadata/old-execution-log.txt"
   ```

### Production vs Development Logging

**Development (DEBUG_MODE=true):**

- **Enable:** Full visibility into execution
- **Use cases:** Feature development, debugging, testing
- **Overhead:** Acceptable (7-13%)
- **Disk usage:** Higher (all logs to stderr and file)

**Production (DEBUG_MODE=false):**

- **Enable:** Minimal stderr noise
- **Use cases:** Automated workflows, CI/CD, scheduled research
- **Overhead:** Minimal (file writes only)
- **Disk usage:** Same (file logs identical)
- **Monitoring:** Still capture ERROR/WARN to stderr for alerting

**Hybrid Approach:**

```bash
# CI/CD pipeline
if [ -n "${CI:-}" ]; then
  # CI environment - enable debug for better failure diagnostics
  export DEBUG_MODE=true
else
  # Production - quiet stderr
  export DEBUG_MODE=false
fi

# Run workflow
bash research-workflow.sh --project-path "$PROJECT_PATH"

# Always check exit code
if [ $? -ne 0 ]; then
  # On failure, dump recent errors from log
  echo "=== RECENT ERRORS ===" >&2
  grep "\[ERROR\]" "${PROJECT_PATH}/.metadata/execution-log.txt" | tail -20 >&2
fi
```

**Alerting Integration:**

```bash
# Production monitoring
bash research-workflow.sh 2>&1 | while read line; do
  echo "$line"

  # Alert on errors (stderr contains ERROR when DEBUG_MODE=false)
  if echo "$line" | grep -q "\[ERROR\]"; then
    # Send to monitoring system
    curl -X POST https://monitoring.example.com/alert \
      -d "message=$line" \
      -d "severity=error"
  fi
done
```

---

## Appendix: Quick Reference

### Environment Variables

| Variable | Type | Default | Source | Purpose |
|----------|------|---------|--------|---------|
| `DEBUG_MODE` | Boolean string | `"false"` | `~/.claude/settings.local.json` | Controls stderr verbosity |
| `LOG_FILE` | File path | Unset | Agent script | Log file destination |
| `CLAUDE_PLUGIN_ROOT` | Directory path | Required | `~/.claude/settings.local.json` | Plugin root directory |

### Log Levels

| Level | Stderr (DEBUG=false) | Stderr (DEBUG=true) | Log File | Use Case |
|-------|---------------------|---------------------|----------|----------|
| ERROR | Yes | Yes | Yes | Critical failures |
| WARN | Yes | Yes | Yes | Recoverable issues |
| INFO | No | Yes | Yes | Workflow progress |
| DEBUG | No | Yes | Yes | Diagnostic details |
| TRACE | No | Yes | Yes | Granular execution |
| PHASE | Yes (always) | Yes (always) | Yes | Phase boundaries |
| METRIC | Yes (always) | Yes (always) | Yes | Performance metrics |

### Common Commands

```bash
# Enable debug mode globally
cat > ~/.claude/settings.local.json <<'EOF'
{"DEBUG_MODE": "true", "CLAUDE_PLUGIN_ROOT": "/path/to/plugins"}
EOF

# View execution log
bash view-execution-log.sh --log-file .logs/agent-log.txt

# View specific phase
bash view-execution-log.sh --log-file .logs/agent-log.txt --phase 2

# Filter errors
bash view-execution-log.sh --log-file .logs/agent-log.txt --level ERROR

# Search pattern
bash view-execution-log.sh --log-file .logs/agent-log.txt --search "keyword"

# Aggregate results (JSON)
bash aggregate-execution-logs.sh --project-path /path/to/project --json

# Aggregate results (Markdown)
bash aggregate-execution-logs.sh --project-path /path/to/project --output-format markdown
```

### File Locations

| Component | Path |
|-----------|------|
| Enhanced Logging | `/scripts/utils/enhanced-logging.sh` |
| Execution Context | `/scripts/utils/log-execution-context.sh` |
| Log Viewer | `/scripts/view-execution-log.sh` |
| Aggregator | `/scripts/aggregate-execution-logs.sh` |
| Settings File | `~/.claude/settings.local.json` |
| Execution Logs | `{project}/.logs/{agent}-execution-log.txt` |
| Context JSON | `{project}/.logs/{agent}-execution-context.json` |
| Partition Stats | `{project}/.logs/partition-{N}-stats.json` |

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-08
**Maintainer:** deeper-research plugin team
**Feedback:** File issues at plugin repository
