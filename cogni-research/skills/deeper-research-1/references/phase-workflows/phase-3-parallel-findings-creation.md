# Phase 3: Dimension-Batched Findings Creation

**Reference Checksum:** `sha256:p3-v3.1-smarter-service-file`

**Verification Protocol:** After reading this reference, confirm complete load by outputting:

```
Reference Loaded: phase-3-parallel-findings-creation.md | Checksum: p3-v3.1-smarter-service-file
```

---

**Objective:** Invoke findings-creator agents in dimension-based batches to reduce concurrent agent count, minimize context window pressure, and enable incremental progress with failure isolation.

**Best Practice:** "Execute batches sequentially by dimension, with ALL questions of that dimension in parallel within each batch" - This reduces blast radius if failures occur while maximizing parallelism within each dimension. No artificial limit on agents per batch (Claude Code supports ~50 parallel agents).

---

## ANTI-BYPASS CONSTRAINT - MANDATORY

**YOU MUST delegate to agents - DO NOT perform research directly:**

| Prohibited Action | Required Action |
|-------------------|-----------------|
| Using WebSearch tool directly | Invoke findings-creator agent via Task tool |
| Creating finding entities directly | Let findings-creator create them with `batch_ref` |
| Skipping Phase 2.5 (batch creation) | Batches MUST pre-exist from batch-creator |
| Using `question_ref` in findings | findings-creator uses `batch_ref` (evidence chain) |

**Prerequisite:** Query batches in `03-query-batches/data/` are created by batch-creator in Phase 2.5 (BEFORE Phase 3 starts). findings-creator agents CONSUME these pre-existing batches.

**Violation Detection:** If `03-query-batches/data/` is empty at Phase 3 start, you skipped Phase 2.5. HALT and return to Phase 2.5 to invoke batch-creator.

**Why This Matters:**

- Query batches (`03-query-batches/data/`) provide audit trail of search queries
- `batch_ref` links findings to queries for evidence provenance
- Direct WebSearch bypasses quality assessment and fallback logic
- findings-creator implements 9-phase workflow with anti-hallucination patterns

---

## Step 0.5: Initialize Phase 3 TodoWrite

Add step-level todos for Phase 3:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 3, Step 0: Derive project_path from sprint-log or question paths [in_progress]
- Phase 3, Step 1: Discover dimensions (verify Phase 2 artifacts exist) [pending]
- Phase 3, Step 1.5: Invoke discover-questions-by-dimension.sh script (provides batches) [pending]
- Phase 3, Step 1.7: Pre-execution batch validation (fail-fast if missing) [pending]
- Phase 3, Step 1.8: Resumption state check (skip already-covered questions) [pending]
- Phase 3, Step 1.9: Detect research_type for conditional file-based agent selection [pending]
- Phase 3, Step 2: Execute batches sequentially [pending]
- Phase 3, Step 3: Aggregate results across all batches [pending]
- Phase 3, Step 3.5: Dedicated reconciliation batch (reconcile ALL questions, retry missing) [pending]
- Phase 3, Step 4: Validate outputs (all finding types: LLM, web, file) [pending]
- Phase 3, Step 5: Mark Phase 3 complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

---

## Step 0: Derive project_path (MANDATORY)

**CRITICAL:** Before any Phase 3 work, you MUST derive `project_path` from sprint-log.json. This prevents the bug where workspace root is passed instead of project directory.

**ZSH COMPATIBILITY:** This complex bash logic uses multiple `$()` and if/then blocks. MUST use temp script pattern.

```bash
cat > /tmp/phase3-derive-project-path.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

CLAUDE_PLUGIN_ROOT="$1"

# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
[ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ] && ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
# CLAUDE_PLUGIN_ROOT points directly to plugin root in flat structure
if [ -z "$ENTITY_CONFIG" ]; then
  echo "ERROR: entity-config.sh not found in CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT}" >&2
  exit 1
fi
source "$ENTITY_CONFIG"

DIR_REFINED_QUESTIONS="$(get_directory_by_key "refined-questions")"
DATA_SUBDIR="$(get_data_subdir)"

# Find ANY refined question file using find (works from any working directory)
first_question_path="$(find . -path "*/$DIR_REFINED_QUESTIONS/$DATA_SUBDIR/*.md" -type f 2>/dev/null | head -1)"

if [ -z "$first_question_path" ]; then
  echo "ERROR: No refined question files found. Run Phase 2 first." >&2
  exit 1
fi

# Convert to absolute path to avoid relative path issues
first_question_path="$(cd "$(dirname "$first_question_path")" && pwd)/$(basename "$first_question_path")"

# Derive project_path: file → data → entity-dir → project
data_dir="$(dirname "$first_question_path")"
entity_dir="$(dirname "$data_dir")"
project_path="$(dirname "$entity_dir")"

echo "Derived project_path from question: ${project_path}" >&2

# Step 0.2: Validate project structure
if [ ! -d "${project_path}/.metadata" ]; then
  echo "ERROR: Invalid project_path: ${project_path}" >&2
  echo "       Missing .metadata directory" >&2
  exit 1
fi

if [ ! -f "${project_path}/.metadata/sprint-log.json" ]; then
  echo "ERROR: Invalid project_path: ${project_path}" >&2
  echo "       Missing .metadata/sprint-log.json" >&2
  exit 1
fi

# Step 0.3: Verify against sprint-log.json
sprint_log_project_path="$(jq -r '.project_path // empty' "${project_path}/.metadata/sprint-log.json")"
if [ -n "$sprint_log_project_path" ] && [ "$project_path" != "$sprint_log_project_path" ]; then
  echo "WARNING: Derived project_path differs from sprint-log.json" >&2
  echo "         Derived: ${project_path}" >&2
  echo "         Sprint log: ${sprint_log_project_path}" >&2
  echo "         Using sprint-log value..." >&2
  project_path="$sprint_log_project_path"
fi

echo "VALIDATED project_path: ${project_path}" >&2
# Output ONLY the path to stdout for capture
echo "$project_path"
SCRIPT_EOF
chmod +x /tmp/phase3-derive-project-path.sh && \
  project_path=$(bash /tmp/phase3-derive-project-path.sh "${CLAUDE_PLUGIN_ROOT}") && \
  PROJECT_PATH="${project_path}" && \
  echo "PROJECT_PATH=${PROJECT_PATH}"
```

**Why This Matters:**

- Phase 3 invokes findings-creator agents with `project-path: {project_path}`
- If `project_path` is workspace root instead of project directory, entities are created at wrong location
- This bug caused empty/orphaned files at workspace root `03-query-batches/data/`

**Mark Step 0 complete** before proceeding to Phase Entry Verification.

---

## DIRECTORY READ PROHIBITION (CRITICAL)

**NEVER invoke the Read tool with `project_path` or any directory path.**

| Prohibited | Allowed |
|------------|---------|
| `Read: ${project_path}` | `Read: ${project_path}/{{entity-dir}}/data/file.md` |
| `Read: ${project_path}/04-findings` | `Read: ${project_path}/04-findings/data/finding-xyz.md` |
| `Read: /path/to/project` | `Read: /path/to/project/.metadata/sprint-log.json` |

**The Read tool ONLY accepts file paths, not directories.**

If you want to explore directory contents, use:

- `ls ${project_path}` via Bash tool
- `Glob pattern: "${project_path}/**/*.md"` via Glob tool

**Violation = EISDIR error. This is unrecoverable.**

---

## PHASE ENTRY VERIFICATION (MANDATORY)

Before starting, verify Phase 2 AND Phase 2.5 artifacts exist:

```bash
# Phase 2 artifacts
ls -la ${project_path}/$DIR_RESEARCH_DIMENSIONS/$DATA_SUBDIR/*.md ${project_path}/$DIR_REFINED_QUESTIONS/$DATA_SUBDIR/*.md

# Phase 2.5 artifacts (query batches from batch-creator)
ls -la ${project_path}/$DIR_QUERY_BATCHES/$DATA_SUBDIR/*.md
```

**IF MISSING:**
- Missing dimensions/questions → Return to Phase 2
- Missing query batches → Return to Phase 2.5 (invoke batch-creator)

---

## Step 1: Discover Dimensions and Group Questions

**Objective:** Group questions by their `dimension_ref` field (written by dimension-planner in Phase 2).

### 1.1 Discover All Dimensions

Use Glob to find all dimension entities:

```bash
Glob pattern: "$DIR_RESEARCH_DIMENSIONS/$DATA_SUBDIR/*.md" in project_path
```

Extract from each dimension:

- Dimension ID (filename without .md, e.g., `dimension-external-effects-abc123`)
- Dimension number (from tags, e.g., `dimension-1`)
- Dimension title (dc:title)

### 1.2 Discover Questions and Group by dimension_ref

**DEPRECATED:** Manual Glob scanning is error-prone and caused 50/51 question failures in production.

~~Use Glob to find all refined questions...~~

**Use Step 1.5 script invocation instead for reliable discovery.**

### 1.3 Build Dimension Batches

```text
DIMENSION_BATCHES = {
  "dimension-external-effects-abc123": [question paths...],
  "dimension-new-horizons-def456": [question paths...],
  ...
}
```

### 1.4 Read Project Language

```bash
project_language="$(jq -r '.project_language // "en"' "${project_path}/.metadata/sprint-log.json")"
```

---

## Step 1.5: Discover Questions Using Script (MANDATORY)

**CRITICAL:** This step replaces manual Glob/Read operations with a single script call to ensure accurate question-to-dimension mapping. Skipping this step caused 50/51 question failures in production.

### 1.5.1 Invoke Discovery Script and Parse Results

**Note:** Uses temp script pattern for zsh compatibility (see shell-compatibility.md).

```bash
cat > /tmp/discover-and-parse.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PLUGIN_ROOT="$1"
PROJECT_PATH="$2"

DISCOVERY_RESULT="$(bash "${PLUGIN_ROOT}/scripts/discover-questions-by-dimension.sh" \
  --project-path "${PROJECT_PATH}" \
  --json)"

if echo "$DISCOVERY_RESULT" | jq -e '.success == true' > /dev/null 2>&1; then
  : # Discovery succeeded, continue
else
  error_msg="$(echo "$DISCOVERY_RESULT" | jq -r '.error // "Unknown error"')"
  echo "ERROR: Question discovery failed: $error_msg" >&2
  exit 1
fi

# Output key values for capture
echo "TOTAL_DIMENSIONS=$(echo "$DISCOVERY_RESULT" | jq -r '.data.total_dimensions')"
echo "TOTAL_QUESTIONS=$(echo "$DISCOVERY_RESULT" | jq -r '.data.total_questions')"
echo "TOTAL_BATCHES=$(echo "$DISCOVERY_RESULT" | jq -r '.data.batching.total_batches')"
echo "EXECUTION_BATCHES=$(echo "$DISCOVERY_RESULT" | jq -c '.data.execution_batches')"
SCRIPT_EOF
chmod +x /tmp/discover-and-parse.sh && bash /tmp/discover-and-parse.sh "${CLAUDE_PLUGIN_ROOT}" "${project_path}"
```

**Output Format:** Key=value pairs that can be parsed or eval'd:
- `TOTAL_DIMENSIONS=9`
- `TOTAL_QUESTIONS=46`
- `TOTAL_BATCHES=3`
- `EXECUTION_BATCHES=[{...},{...},{...}]`

**Example Output Structure (v2.3 with batching):**

```json
{
  "success": true,
  "source": "dimension-plan-batch",
  "data": {
    "total_dimensions": 9,
    "total_questions": 46,
    "dimensions": { "...": "dimension objects keyed by ID" },
    "execution_batches": [
      {
        "batch_number": 1,
        "batch_name": "Dimension A + Dimension B + Dimension C",
        "dimension_count": 3,
        "dimension_ids": ["dimension-a-...", "dimension-b-...", "dimension-c-..."],
        "question_count": 18,
        "question_paths": ["/path/to/question-1.md", "..."]
      },
      {
        "batch_number": 2,
        "batch_name": "Dimension D + Dimension E + Dimension F",
        "dimension_count": 3,
        "dimension_ids": ["dimension-d-...", "dimension-e-...", "dimension-f-..."],
        "question_count": 17,
        "question_paths": ["/path/to/question-N.md", "..."]
      },
      {
        "batch_number": 3,
        "batch_name": "Dimension G + Dimension H + Dimension I",
        "dimension_count": 3,
        "dimension_ids": ["dimension-g-...", "dimension-h-...", "dimension-i-..."],
        "question_count": 11,
        "question_paths": ["/path/to/question-M.md", "..."]
      }
    ],
    "batching": {
      "strategy": "question-count-based",
      "target_min": 15,
      "target_max": 20,
      "total_batches": 3
    }
  }
}
```

**Note:** Generic dimension names (A, B, C...) ensure this example applies to ALL research types. Actual output uses real dimension titles from your research type (e.g., "Security Services", "Customer Segments", etc.).

### 1.5.3 Validation Gate

```bash
# BLOCKING: Verify discovery returned valid data
[ "$TOTAL_DIMENSIONS" -gt 0 ] || {
  echo "ERROR: No dimensions discovered. Check Phase 2 completion." >&2
  exit 1
}

[ "$TOTAL_QUESTIONS" -gt 0 ] || {
  echo "ERROR: No questions discovered. Check Phase 2 completion." >&2
  exit 1
}

[ "$TOTAL_BATCHES" -gt 0 ] || {
  echo "ERROR: No execution batches calculated. Script error." >&2
  exit 1
}

echo "Discovery complete: $TOTAL_DIMENSIONS dimensions, $TOTAL_QUESTIONS questions → $TOTAL_BATCHES execution batches"
```

**Mark Steps 1 and 1.5 todos as completed** before proceeding to Step 1.7.

---

## Step 1.7: Pre-Execution Batch Validation (MANDATORY)

**Purpose:** Validate ALL batch files exist before invoking findings-creator agents.

### 1.7.1 Extract Question Paths

```bash
# Build flat list of all question paths across all execution batches
ALL_QUESTION_PATHS="$(echo "$EXECUTION_BATCHES" | jq -r '.[].question_paths[]')"
TOTAL_QUESTION_COUNT="$(echo "$ALL_QUESTION_PATHS" | wc -l | tr -d ' ')"

echo "Validating batches for $TOTAL_QUESTION_COUNT questions..." >&2
```

### 1.7.2 Validate Each Batch File Exists

```bash
# Source entity config for directory resolution
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
if [ -z "$ENTITY_CONFIG" ]; then
  echo "ERROR: entity-config.sh not found in CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT}" >&2
  exit 1
fi
source "$ENTITY_CONFIG"
DIR_QUERY_BATCHES="$(get_directory_by_key "query-batches")"
DATA_SUBDIR="$(get_data_subdir)"

VALIDATION_FAILURES=()

while IFS= read -r question_path; do
  question_id="$(basename "$question_path" .md)"
  batch_id="${question_id}-batch"
  batch_file="${project_path}/${DIR_QUERY_BATCHES}/${DATA_SUBDIR}/${batch_id}.md"

  if [ ! -f "$batch_file" ]; then
    VALIDATION_FAILURES+=("${question_id}:missing_file")
  else
    # Check file size (minimum 500 bytes)
    size="$(stat -f%z "$batch_file" 2>/dev/null || stat -c%s "$batch_file" 2>/dev/null || echo 0)"
    if [ "$size" -lt 500 ]; then
      VALIDATION_FAILURES+=("${question_id}:too_small")
    fi
  fi
done <<< "$ALL_QUESTION_PATHS"
```

### 1.7.3 Fail Fast if Validation Errors

```bash
if [ ${#VALIDATION_FAILURES[@]} -gt 0 ]; then
  echo "ERROR: Pre-execution validation failed. Missing or invalid batches:" >&2

  for failure in "${VALIDATION_FAILURES[@]}"; do
    question_id="${failure%%:*}"
    issue="${failure##*:}"
    echo "  - ${question_id}: ${issue}" >&2
  done

  echo "" >&2
  echo "RESOLUTION: Run batch-creator to create missing batches, then retry Phase 3." >&2
  exit 1
fi

echo "Pre-execution validation PASSED: All $TOTAL_QUESTION_COUNT batches valid" >&2
```

**Mark Step 1.7 complete** before proceeding to Step 2.

---

## ~~Step 1.6: Question-Count-Based Batch Grouping~~ (AUTOMATED)

**DEPRECATED:** As of v2.3, batch grouping is now performed automatically by `discover-questions-by-dimension.sh`. The script returns pre-calculated `execution_batches` in Step 1.5.

**Algorithm (implemented in script):**

- Target: 15-20 questions per batch
- Sort dimensions by question count (largest first)
- Pack dimensions into batches until TARGET_MAX (20) reached
- Merge small trailing batches (<15 questions) if merge stays within 22 (20 + 10% overage)

**Example outputs:**

| Input | Output |
|-------|--------|
| 51 questions / 7 dims | 3 batches (17 + 17 + 17) |
| 46 questions / 9 dims | 3 batches (15 + 16 + 15) |
| 20 questions / 4 dims | 1 batch (20) |

**No manual implementation required.** Proceed directly to Step 2 after Step 1.5.

---

## Step 1.8: Resumption State Check (Rate-Limit Recovery)

**Purpose:** Detect partially-completed findings from a prior interrupted run and skip already-covered questions. This enables seamless resumption after rate-limit interruptions.

### 1.8.1 Scan Existing Findings

```bash
RESUMPTION_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh" \
  --project-path "${project_path}" \
  --phase 3 \
  --json)"

RECOMMENDATION="$(echo "$RESUMPTION_RESULT" | jq -r '.recommendation')"
echo "Resumption scan: ${RECOMMENDATION}"
```

### 1.8.2 Branch on Recommendation

```text
COMPLETE → Skip to Step 3.5 (reconciliation). All questions already have findings.
RESUME  → Filter EXECUTION_BATCHES to only include pending questions.
FULL_RUN → Proceed normally (no changes to batches).
```

**RESUME filtering logic:**

```bash
# Extract pending question IDs
PENDING_QUESTIONS="$(echo "$RESUMPTION_RESULT" | jq -r '.pending_questions[]')"
PENDING_COUNT="$(echo "$RESUMPTION_RESULT" | jq -r '.pending_questions | length')"
COMPLETED_COUNT="$(echo "$RESUMPTION_RESULT" | jq -r '.completed_questions')"

echo "Resuming: ${PENDING_COUNT} pending, ${COMPLETED_COUNT} already completed"

# Filter EXECUTION_BATCHES to only include pending question paths
# For each batch, keep only question_paths whose basename (minus .md) is in pending list
FILTERED_BATCHES="$(echo "$EXECUTION_BATCHES" | jq --argjson pending "$(echo "$RESUMPTION_RESULT" | jq '.pending_questions')" '
  [.[] | .question_paths = [.question_paths[] | select(
    (split("/") | last | rtrimstr(".md")) as $qid | $pending | index($qid) != null
  )] | .question_count = (.question_paths | length) | select(.question_count > 0)]
')"

# Update batch variables
EXECUTION_BATCHES="$FILTERED_BATCHES"
TOTAL_BATCHES="$(echo "$EXECUTION_BATCHES" | jq 'length')"
TOTAL_QUESTIONS="$PENDING_COUNT"

echo "Filtered to ${TOTAL_BATCHES} non-empty batches with ${TOTAL_QUESTIONS} pending questions"
```

### 1.8.3 Batch Checkpoint Compatibility

The resumption gate works alongside existing batch checkpoints (Step 2). If a batch was partially completed, the resumption scan catches individual questions within that batch. Downstream batch execution works unchanged because the data structure is the same — just fewer questions per batch.

**Mark Step 1.8 complete** before proceeding to Step 1.9.

---

## Step 1.9: Detect Research Type for Conditional Agent Selection

**MANDATORY:** Read `research_type` from sprint-log.json to determine if file-based findings creator should be invoked.

```bash
research_type="$(jq -r '.research_type // "generic"' "${project_path}/.metadata/sprint-log.json")"
echo "Research type: ${research_type}"

# Determine if file-based findings creator should be invoked
USE_FILE_FINDINGS=false
rag_store_path=""

if [ "$research_type" = "smarter-service" ]; then
  USE_FILE_FINDINGS=true

  # Store path resolution priority cascade:
  # 1. Explicit rag_store_path from sprint-log.json (if configured)
  # 2. Project-level: ${project_path}/rag-store/{research_type}
  # 3. Search upward from project until finding rag-store/{research_type} or reaching filesystem root

  # Priority 1: Explicit configuration in sprint-log.json
  explicit_path="$(jq -r '.rag_store_path // ""' "${project_path}/.metadata/sprint-log.json")"
  if [ -n "$explicit_path" ] && [ -d "$explicit_path" ]; then
    rag_store_path="$explicit_path"
    echo "Using explicit store path from sprint-log.json"
  else
    # Priority 2: Project-level store
    if [ -d "${project_path}/rag-store/${research_type}" ]; then
      rag_store_path="${project_path}/rag-store/${research_type}"
    else
      # Priority 3: Search upward from project directory
      search_dir="$project_path"
      while [ "$search_dir" != "/" ]; do
        search_dir="$(dirname "$search_dir")"
        if [ -d "${search_dir}/rag-store/${research_type}" ]; then
          rag_store_path="${search_dir}/rag-store/${research_type}"
          break
        fi
      done
    fi
  fi

  if [ -z "$rag_store_path" ] || [ ! -d "$rag_store_path" ]; then
    echo "ERROR: No document store found. Searched locations:" >&2
    echo "  - Explicit (sprint-log.json): $(jq -r '.rag_store_path // "(not configured)"' "${project_path}/.metadata/sprint-log.json")" >&2
    echo "  - Project-level: ${project_path}/rag-store/${research_type}" >&2
    echo "  - Upward search from: ${project_path}" >&2
    echo "To fix: Either create rag-store/${research_type}/ directory or add 'rag_store_path' to sprint-log.json" >&2
    exit 1
  fi

  echo "smarter-service detected: File-based findings creator will be invoked per question"
  echo "Store path: ${rag_store_path}"
fi
```

**Mark Step 1.9 complete** before proceeding to Step 2.

---

## Step 2: Execute Batches Sequentially

**CRITICAL:** Execute ONE batch at a time. Wait for batch completion before starting next batch. This reduces context window pressure and isolates failures.

**Objective:** For each batch (which may contain one or multiple dimensions), invoke findings-creator-llm (for ALL questions in the batch), findings-creator agents (one per question), and optionally findings-creator-file agents (one per question, for smarter-service research type) in parallel within the batch.

### OUTPUT TOKEN CONSERVATION (MANDATORY)

**Problem:** Verbose explanatory text before Task invocations exhausts output tokens, causing the model to stop mid-response. User then has to prompt "ok" to continue.

**Required Pattern:**

```text
GOOD (minimal):
"Batch 1/4: Security + Cloud (18q)"
[IMMEDIATELY invoke Task tools - no additional text]

BAD (verbose - causes pause):
"Starting Batch 1/4: Security Services + Cloud Services (18 questions across 2 dimensions).
I'll now invoke all 19 agents in parallel for Batch 1. This is a large operation
that will take some time to complete. Given the token constraints and complexity,
I'll execute this carefully to ensure all agents complete successfully.
Let me proceed with executing the first batch..."
[Model stops here - user must say "ok"]
```

**Rules:**

1. Log ONE SHORT LINE per batch start: `"Batch N/M: {name} ({count}q)"`
2. IMMEDIATELY invoke ALL Task tools - no explanatory text between log and tools
3. NO phrases like "Let me...", "I'll now...", "This will..."
4. Save explanations for AFTER batch completion when reporting results

---

### Batch Execution Loop

**CRITICAL CONSTRAINT: SEQUENTIAL BATCH EXECUTION**

- You MUST wait for ALL agents in Batch N to complete BEFORE starting Batch N+1
- NEVER invoke Task tools for multiple batches in the same message
- Each batch = ONE message with Task invocations → ONE response with all results
- Anti-pattern: "Jetzt starte ich Batch 2 parallel während Batch 1 läuft" ← **VERBOTEN**

**Why this matters:** Invoking all batches simultaneously causes "Prompt is too long" errors when TaskOutput results accumulate beyond context limits.

**CRITICAL: NO BACKGROUND EXECUTION**

- **NEVER** use `run_in_background: true` for Task tool invocations
- Parallel execution is achieved by invoking multiple Task tools in a **single message** (Claude Code handles parallelization automatically)
- Background execution breaks sequential batch execution because "Launched" returns immediately without waiting

**Correct Pattern:**

```text
# Single message with multiple Task calls (NO run_in_background)
Task(subagent_type="findings-creator-llm", ...)
Task(subagent_type="findings-creator", ...)  # Q1
Task(subagent_type="findings-creator", ...)  # Q2
...
# Claude Code runs ALL tasks in parallel, WAITS for all to complete, then returns all results
```

**Forbidden Pattern:**

```text
Task(subagent_type="findings-creator", run_in_background=true, ...)  ← FORBIDDEN
# Returns "Launched" immediately, orchestrator proceeds to next batch prematurely
```

**Enforcement Protocol (Before Invoking Batch N+1):**

1. COUNT the Task tool responses received for Batch N
2. VERIFY: count == (1 LLM agent + N web agents where N = questions in batch)
3. IF count mismatch: DO NOT proceed, report missing agents and trigger retry (Step 2.3.6)
4. WRITE checkpoint file confirming batch complete (Step 2.5.1)
5. ONLY THEN invoke next batch in a NEW message

```text
FOR batch_number, batch IN enumerate(EXECUTION_BATCHES, 1):
  # SEQUENTIAL: Complete this ENTIRE batch before starting next batch

  ## 2.1 Log Batch Start (MINIMAL - see OUTPUT TOKEN CONSERVATION above)
  # ONE SHORT LINE ONLY - then IMMEDIATELY invoke Task tools
  Log: "Batch {batch_number}/{total_batches}: {batch.batch_name} ({batch.question_count}q)"

  ## 2.2 Invoke Agents in SINGLE Message (Parallel Within Batch)
  # NO explanatory text here - invoke Task tools IMMEDIATELY after the log line above

  ### Task 1: LLM-Findings-Creator (ALL Questions in Batch)

  Task tool parameters:
  - subagent_type: "cogni-research:findings-creator-llm"
  - description: "LLM findings for {batch.batch_name}"
  - run_in_background: false  MANDATORY - do NOT run in background
  - prompt: "Process refined questions using Claude's internal training knowledge.

  Parameters:
  - project-path: {project_path}
  - language: {project_language}
  - question-paths: [{comma-separated list of ALL question paths in this batch}]

  Execute workflow and return ONLY single-line JSON: {\"ok\":true,\"q\":N,\"f\":N,\"r\":N}
  NO PROSE. NO MARKDOWN. NO EXPLANATION. Just the JSON line."

  ### Tasks 2-N: Findings-Creator (One Per Question in Batch)

  For each question_path in batch.question_paths:
    Task tool parameters:
    - subagent_type: "cogni-research:findings-creator"
    - description: "Web findings for {question_id}"
    - run_in_background: false  MANDATORY - do NOT run in background
    - prompt: "Process refined question to create findings.

    Parameters (for Phase 0 placeholder substitution):
    - refined-question-path: {question_path}
    - project-path: {project_path}
    - language: {project_language}

    FRESH SHELL WARNING: Do NOT run separate export commands - they won't persist.
    When running the skill's Phase 0 bash block, replace the {{...}} placeholders inline:
    - {{REFINED_QUESTION_PATH}} → {question_path}
    - {{PROJECT_PATH}} → {project_path}
    - {{CONTENT_LANGUAGE}} → {project_language}

    Execute workflow and return ONLY single-line JSON: {\"ok\":true,\"q\":\"ID\",\"f\":N}
    NO PROSE. NO MARKDOWN. NO EXPLANATION. Just the JSON line."

  ### Tasks N+1 to 2N (Conditional): File-Findings-Creator (if research_type == smarter-service)

  **ONLY invoke if `research_type == "smarter-service"` (detected in Step 1.9):**

  IF USE_FILE_FINDINGS == true:
    FOR each question_path in batch.question_paths:
      question_id = basename(question_path, ".md")

      Task tool parameters:
      - subagent_type: "cogni-research:findings-creator-file"
      - description: "File findings for {question_id}"
      - run_in_background: false  MANDATORY - do NOT run in background
      - prompt: "Process refined question to create findings from document store.

      Parameters:
      - refined-question-path: {question_path}
      - project-path: {project_path}
      - store-path: {rag_store_path}
      - language: {project_language}

      Execute workflow and return ONLY single-line JSON: {\"ok\":true,\"q\":\"ID\",\"f\":N,\"r\":N}
      NO PROSE. NO MARKDOWN. NO EXPLANATION. Just the JSON line."
    END FOR
  END IF

  **Note:** findings-creator-file follows the same pattern as findings-creator (web):
  - Processes ONE question at a time (one-per-question)
  - Creates findings with `finding-file-` prefix
  - Source reliability based on document quality assessment

  ## 2.3 MANDATORY Wait for Batch Completion

  **DO NOT PROCEED** until you receive ALL Task tool responses for THIS batch.

  **Verification:**
  1. Count expected responses: 1 (LLM) + N (web) + (N file if smarter-service) = X total agents
     - Generic research: X = 1 + N
     - Smarter-service research: X = 1 + N + N = 2N + 1
  2. Wait for Claude Code to return X Task responses in this message
  3. ONLY AFTER receiving all X responses → proceed to Step 2.3.5

  **Anti-Pattern (FORBIDDEN):**
  - "Batch 1 läuft, ich starte jetzt Batch 2 parallel"
  - Starting next batch before current batch agents return
  - Invoking TaskOutput for multiple batches simultaneously
  - "Alle X Agenten laufen jetzt parallel" (across batches)

  **Correct Pattern:**
  Invoke Batch 1 agents → Receive all responses → Aggregate → THEN Batch 2

  ## 2.3.5 Post-Invocation Validation Gate (MANDATORY)

  **CRITICAL:** After receiving Task tool responses, validate agent response counts BEFORE aggregating results.

  ### Validation Steps:

  1. **Count responses received:**
     ```text
     expected_agents = 1 (LLM) + N (web, one per question in this batch)
     actual_responses = COUNT(Task tool responses in Claude's reply)
     ```

  2. **Validate counts match:**
     ```text
     IF actual_responses < expected_agents:
       missing_count = expected_agents - actual_responses
       Log: "WARNING: {missing_count} agents did not return responses"

       # Identify missing questions by comparing invoked question_paths vs responses
       FOR each question_path in batch.question_paths:
         IF no response contains question_path identifier:
           missing_questions.append(question_path)

       Log: "Missing responses for questions: {missing_questions}"

       # TRIGGER RETRY MECHANISM (Step 2.3.6)
     END IF
     ```

  3. **Validation passed:** Proceed to Step 2.3.5b (Filesystem Validation)

  **DO NOT proceed to aggregation if validation fails.** Missing agents MUST be retried first.

  ## 2.3.5b Per-Agent Filesystem Validation (MANDATORY)

  **CRITICAL:** Agent JSON responses (e.g., `{"ok":true,"f":15}`) report self-claimed counts.
  These MUST be validated against actual filesystem state. Agents may report success but create 0 files ("0 tool uses" bug).

  ### Validation Protocol:

  For each successful agent response in the current batch:

  ```bash
  # After receiving JSON from findings-creator agent
  EXPECTED_COUNT="$(echo "$AGENT_RESPONSE" | jq -r '.f')"
  question_id="$(echo "$AGENT_RESPONSE" | jq -r '.q')"

  # Count actual files with matching batch_ref
  ACTUAL_COUNT=$(grep -l "batch_ref: .*${question_id}" \
    "${project_path}/04-findings/data/"*.md 2>/dev/null | wc -l | tr -d ' ')

  # Validation
  if [ "$ACTUAL_COUNT" -eq 0 ] && [ "$EXPECTED_COUNT" -gt 0 ]; then
    echo "VALIDATION FAIL: Agent claimed ${EXPECTED_COUNT} findings but 0 exist" >&2
    RETRY_QUEUE+=("$question_id")
  elif [ "$ACTUAL_COUNT" -lt $((EXPECTED_COUNT / 2)) ]; then
    echo "VALIDATION WARN: Agent claimed ${EXPECTED_COUNT} but only ${ACTUAL_COUNT} exist" >&2
    # Add to retry queue if mismatch exceeds 50%
    RETRY_QUEUE+=("$question_id")
  else
    echo "VALIDATION OK: Agent claimed ${EXPECTED_COUNT}, filesystem has ${ACTUAL_COUNT}" >&2
  fi
  ```

  ### Batch-Level Filesystem Validation Summary:

  After validating all agents in the batch:

  ```bash
  BATCH_EXPECTED_TOTAL=$((sum of all EXPECTED_COUNT))
  BATCH_ACTUAL_TOTAL=$((sum of all ACTUAL_COUNT))

  if [ "$BATCH_ACTUAL_TOTAL" -lt $((BATCH_EXPECTED_TOTAL / 2)) ]; then
    echo "BATCH VALIDATION FAIL: Expected ${BATCH_EXPECTED_TOTAL} findings, filesystem has ${BATCH_ACTUAL_TOTAL}" >&2
    # Critical: More than 50% of claimed findings are missing
  fi

  echo "Batch filesystem validation: ${BATCH_ACTUAL_TOTAL}/${BATCH_EXPECTED_TOTAL} findings verified"
  ```

  ### Retry Queue Processing:

  If `RETRY_QUEUE` is non-empty after filesystem validation:

  1. Log the questions that need retry: `"Filesystem validation failed for: ${RETRY_QUEUE[*]}"`
  2. These questions will be added to Step 2.3.6 retry processing
  3. Filesystem-validated counts (ACTUAL_COUNT) should be used for aggregation, not self-reported counts

  **Proceed to Step 2.3.6** if retry queue is non-empty, otherwise proceed to Step 2.4.

  ## 2.3.6 Retry Missing Agents (Conditional)

  **Trigger:** Invoked when Step 2.3.5 detects missing responses OR Step 2.3.5b detects filesystem validation failures.

  ### Retry Protocol:

  1. **Single-agent retry mode:** For each missing/failed question, invoke findings-creator INDIVIDUALLY:
     ```text
     FOR each question_path in missing_questions:
       Task(
         subagent_type="findings-creator",
         description="RETRY: Web findings for {question_id}",
         prompt="Process refined question to create findings.

         Parameters:
         - refined-question-path: {question_path}
         - project-path: {project_path}
         - language: {project_language}

         Execute complete 9-phase workflow and return concise summary."
       )

       # Wait for single agent to complete before invoking next
       # This prevents overwhelming the system with parallel retries
     END FOR
     ```

  2. **Maximum retry attempts:** 2 rounds per batch (prevents infinite loops)

  3. **After retries:**
     - Re-run filesystem validation (Step 2.3.5b) for retried questions
     - If still failing after 2 retry rounds: Log ERROR and continue to next dimension batch
     - Record failed questions in sprint-log.json for manual intervention

  4. **Sprint log update for failures:**
     ```json
     {
       "phase_3_partial_failures": {
         "batch_number": N,
         "dimension_id": "dimension-xyz",
         "failed_questions": ["question-abc", "question-def"],
         "retry_attempts": 2,
         "failure_type": "filesystem_validation",
         "expected_findings": 15,
         "actual_findings": 0,
         "recommendation": "Re-run findings-creator manually for failed questions"
       }
     }
     ```

  ## ~~2.3.7 Batch Completion Gate~~ (DEPRECATED)

  **DEPRECATED (v2.5.0):** Per-batch reconciliation was unreliable - LLMs would "forget" to run it for subsequent batches. Replaced by dedicated Step 3.5 reconciliation batch that runs ONCE after ALL batches complete.

  **DO NOT** run reconciliation during the batch loop. Skip directly to Step 2.4 after agent responses.

  ## ~~2.3.8 Immediate Single-Question Retry~~ (DEPRECATED)

  **DEPRECATED (v2.5.0):** Moved to Step 3.5 (Dedicated Reconciliation Batch). Retries now happen in a single batch after all execution batches complete, not per-batch.

  ## 2.4 Aggregate Batch Results
  # Use ACTUAL filesystem counts from Step 2.3.5b, not self-reported counts
  batch_llm_findings = LLM_response.f  # LLM findings don't need filesystem validation (different pattern)
  batch_web_findings = sum(ACTUAL_COUNT for each web question)  # Use validated filesystem counts
  batch_file_findings = sum(ACTUAL_COUNT for each file question) if USE_FILE_FINDINGS else 0  # File findings (smarter-service only)

  ## 2.5 Log Batch Completion
  # Log format varies by research type
  IF USE_FILE_FINDINGS:
    Log: "Batch {batch_number} complete: {batch_llm_findings} LLM + {batch_web_findings} web + {batch_file_findings} file findings (filesystem-validated)"
  ELSE:
    Log: "Batch {batch_number} complete: {batch_llm_findings} LLM + {batch_web_findings} web findings (filesystem-validated)"
  END IF

  ## 2.5.1 Write Batch Checkpoint (MANDATORY)

  **After logging batch completion, create a durable checkpoint file:**

  ```bash
  mkdir -p "${project_path}/.checkpoints/phase-3"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${project_path}/.checkpoints/phase-3/batch-${batch_number}-complete"
  ```

  **Purpose:** Enables recovery if workflow stalls. On resume, check which batches have checkpoints to avoid reprocessing.

  **Before starting Batch N+1 (in next loop iteration), verify Batch N checkpoint:**

  ```bash
  if [ ! -f "${project_path}/.checkpoints/phase-3/batch-${batch_number}-complete" ]; then
    echo "ERROR: Batch ${batch_number} checkpoint missing. Cannot proceed to next batch." >&2
    # DO NOT proceed - investigate why checkpoint wasn't written
  fi
  ```

  ## 2.6 Accumulate Totals
  total_llm_findings += batch_llm_findings
  total_web_findings += batch_web_findings
  total_file_findings += batch_file_findings  # 0 if not smarter-service

END FOR
```

### Example Batch Execution

#### Generic Research Type (2 agent types: LLM + Web)

For a generic project with 4 dimensions and 20 questions:

```text
Batch 1/4: External Effects (5 questions)
  - Invoking 6 agents in parallel (1 LLM + 5 web)
  - Filesystem validation: 38/40 findings verified
  → Batch 1 complete: 4 LLM + 38 web findings (filesystem-validated)

Batch 2/4: New Horizons (6 questions)
  - Invoking 7 agents in parallel (1 LLM + 6 web)
  - Filesystem validation: 45/45 findings verified
  → Batch 2 complete: 5 LLM + 45 web findings (filesystem-validated)

Batch 3/4: Digital Value Drivers (5 questions)
  - Invoking 6 agents in parallel (1 LLM + 5 web)
  - Filesystem validation: 40/42 findings verified
  → Batch 3 complete: 4 LLM + 40 web findings (filesystem-validated)

Batch 4/4: Digital Foundation (4 questions)
  - Invoking 5 agents in parallel (1 LLM + 4 web)
  - Filesystem validation: 32/32 findings verified
  → Batch 4 complete: 3 LLM + 32 web findings (filesystem-validated)

Total: 16 LLM + 155 web = 171 findings (filesystem-validated)
```

#### Smarter-Service Research Type (3 agent types: LLM + Web + File)

For a smarter-service project with 4 dimensions and 52 questions (TIPS framework: 5 ACT + 5 PLAN + 3 OBSERVE per dimension):

```text
Batch 1/4: Externe Effekte (13 questions)
  - Invoking 27 agents in parallel (1 LLM + 13 web + 13 file)
  - Filesystem validation: 95/98 findings verified
  → Batch 1 complete: 10 LLM + 85 web + 12 file findings (filesystem-validated)

Batch 2/4: Neue Horizonte (13 questions)
  - Invoking 27 agents in parallel (1 LLM + 13 web + 13 file)
  - Filesystem validation: 92/95 findings verified
  → Batch 2 complete: 9 LLM + 83 web + 11 file findings (filesystem-validated)

Batch 3/4: Digitale Wertetreiber (13 questions)
  - Invoking 27 agents in parallel (1 LLM + 13 web + 13 file)
  - Filesystem validation: 98/100 findings verified
  → Batch 3 complete: 11 LLM + 87 web + 12 file findings (filesystem-validated)

Batch 4/4: Digitales Fundament (13 questions)
  - Invoking 27 agents in parallel (1 LLM + 13 web + 13 file)
  - Filesystem validation: 93/96 findings verified
  → Batch 4 complete: 10 LLM + 83 web + 11 file findings (filesystem-validated)

Total: 40 LLM + 338 web + 46 file = 424 findings (filesystem-validated)
```

**Key difference:** Smarter-service invokes N additional file agents per batch (findings-creator-file), one per question, which query the local `rag-store/smarter-service` document store.

**Larger dimension example:** If a dimension has 17 questions, all 18 agents run in parallel:

```text
Batch 2/4: Market Analysis (17 questions)
  - Invoking 18 agents in parallel (1 LLM + 17 web)
  - Filesystem validation: 127/130 findings verified
  → Batch 2 complete: 12 LLM + 127 web findings (filesystem-validated)
```

### Example: b2b-ict-portfolio (Multi-Dimension Batching)

For a b2b-ict-portfolio project with 8 dimensions (0-7) and 57 questions, grouped into 4 batches:

```text
Batch 1/4: Provider Profile (6 questions across 1 dimension: Provider Profile Metrics)
  - Invoking 7 agents in parallel (1 LLM + 6 web)
  → Batch 1 complete: 5 LLM + 45 web findings

Batch 2/4: Infrastructure & Security (24 questions across 3 dimensions: Connectivity, Security, Digital Workplace)
  - Invoking 25 agents in parallel (1 LLM + 24 web)
  → Batch 2 complete: 15 LLM + 180 web findings

Batch 3/4: Cloud & Operations (22 questions across 3 dimensions: Cloud, Managed Infrastructure, Application)
  - Invoking 23 agents in parallel (1 LLM + 22 web)
  → Batch 3 complete: 14 LLM + 165 web findings

Batch 4/4: Advisory (5 questions across 1 dimension: Consulting)
  - Invoking 6 agents in parallel (1 LLM + 5 web)
  → Batch 4 complete: 4 LLM + 38 web findings

Total: 38 LLM + 428 web = 466 findings
```

**Key difference:** Each batch has ONE findings-creator-llm that processes ALL questions from ALL dimensions in that batch (not one per dimension).

### Batching Benefits

| Metric | Old (All Parallel) | New (Dimension Batches) |
|--------|-------------------|------------------------|
| Max concurrent agents | 21 (1 + 20) | N+1 pro Batch (1 LLM + alle Fragen der Dimension) |
| Failure blast radius | All questions | Single dimension |
| Context window pressure | High | Reduced (sequential between dimensions) |
| Progress visibility | All-or-nothing | Per-dimension |

**Mark Step 2 todo as completed** after all batches complete.

---

## Step 3: Aggregate Results Across All Batches

After all dimension batches complete, aggregate the totals:

### Final Aggregation

```text
total_llm_findings = sum of batch_llm_findings from all batches
total_web_findings = sum of batch_web_findings from all batches
total_file_findings = sum of batch_file_findings from all batches  # 0 if not smarter-service
total_findings = total_llm_findings + total_web_findings + total_file_findings
```

### Log to Sprint Log

Update `{project_path}/.metadata/sprint-log.json`:

**Generic research type:**

```json
{
  "phase_3_complete": true,
  "llm_findings_count": 16,
  "web_findings_count": 155,
  "total_findings_count": 171,
  "batches_completed": 4
}
```

**Smarter-service research type:**

```json
{
  "phase_3_complete": true,
  "llm_findings_count": 16,
  "web_findings_count": 155,
  "file_findings_count": 45,
  "total_findings_count": 216,
  "batches_completed": 4
}
```

**Mark Step 3 todo as completed** before proceeding to validation.

---

## Per-Batch Log Verification

After each batch completes, verify that per-item execution logs were created:

```bash
# After batch completion
for question_id in batch_question_ids:
  log_file="${PROJECT_PATH}/.logs/findings-creator/findings-creator-${question_id}-execution-log.txt"
  if [ ! -f "$log_file" ]; then
    log_conditional WARN "Per-item log missing for question: ${question_id}"
  fi
done
```

**Non-fatal check:** Warnings only, doesn't block execution.

---

## Step 4: Validate Outputs (LLM + Web Findings)

Use the batch validation script for single-call validation:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-phase3-completion.sh" \
  --project-path "${project_path}"
```

**Returns compact JSON:**

```json
{"success":true,"batches":20,"questions":20,"llm_findings":16,"web_findings":155,"total_findings":171,"megatrends":45,"errors":[]}
```

**Error codes in response:**

- `no_batches:agents_bypassed` - CRITICAL: Restart Phase 3 with Task tool
- `batch_mismatch:Xvs Y` - Batch count doesn't match question count
- `no_findings` - CRITICAL: No findings created
- `no_web_findings` - CRITICAL: Web findings missing
- `low_findings:N` - WARNING: Below 100 threshold

**Mark Step 4 todo as completed** before proceeding to self-verification.

---

## Step 3.5: Dedicated Reconciliation Batch (MANDATORY)

**BLOCKING:** This step runs ONCE after ALL execution batches complete. This replaces the deprecated per-batch reconciliation (Steps 2.3.7/2.3.8) which was unreliable.

**Why a dedicated batch?** Per-batch reconciliation embedded in a loop was skipped by LLMs for 2/3 batches in production. A distinct step is harder to skip.

### 3.5.1 Run Full Reconciliation (Batch File Validation)

Use the reconciliation script to validate ALL questions have valid query batches:

```bash
# Run full validation mode (checks ALL questions automatically)
RECONCILE_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/reconcile-question-batches.sh" \
  --project-path "${PROJECT_PATH}")"

# Parse results
RECONCILE_SUCCESS="$(echo "$RECONCILE_RESULT" | jq -r '.success')"
MISSING_COUNT="$(echo "$RECONCILE_RESULT" | jq -r '.missing_questions | length')"
MISSING_QUESTIONS="$(echo "$RECONCILE_RESULT" | jq -r '.missing_questions[]' 2>/dev/null)"
COVERAGE_PERCENT="$(echo "$RECONCILE_RESULT" | jq -r '.coverage_percent')"

echo "Reconciliation: ${COVERAGE_PERCENT}% coverage"

if [ "$MISSING_COUNT" -gt 0 ]; then
  echo "Missing batches for ${MISSING_COUNT} questions:" >&2
  echo "$MISSING_QUESTIONS" | while read -r qid; do echo "  - $qid" >&2; done
  # PROCEED TO STEP 3.5.1b (Findings Count Validation)
fi
```

**Note:** Omitting `--batch-questions` triggers full validation mode which automatically discovers all questions in `02-refined-questions/data/`.

### 3.5.1b Findings-Per-Question Validation (MANDATORY)

**Purpose:** Detect questions where batch files exist but NO findings were actually created. This serves as a safety net for agents that pass Step 2.3.5b during batch execution but still have issues (e.g., intermittent failures, "0 tool uses" bug not caught during batching).

**CRITICAL:** This validation catches the case where:
- Query batch file exists (Step 3.5.1 passes)
- Agent reported success during batch execution
- But actual filesystem has 0 findings for that question

```bash
# After batch file validation (Step 3.5.1), also count findings per question
# Extract ALL question IDs from refined questions directory
ALL_QUESTION_IDS="$(find "${PROJECT_PATH}/02-refined-questions/data" -name "question-*.md" -type f \
  -exec basename {} .md \; 2>/dev/null)"

ZERO_FINDINGS_QUESTIONS=()
FINDINGS_PER_QUESTION=()

echo "Validating findings count per question..." >&2

while IFS= read -r question_id; do
  [ -z "$question_id" ] && continue

  # Count findings with batch_ref containing this question_id
  finding_count=$(grep -l "batch_ref: .*${question_id}" \
    "${PROJECT_PATH}/04-findings/data/"*.md 2>/dev/null | wc -l | tr -d ' ')

  FINDINGS_PER_QUESTION+=("${question_id}:${finding_count}")

  if [ "$finding_count" -eq 0 ]; then
    ZERO_FINDINGS_QUESTIONS+=("$question_id")
    echo "  Zero-findings detected: $question_id" >&2
  fi
done <<< "$ALL_QUESTION_IDS"

# Summary
TOTAL_QUESTIONS_CHECKED=$(echo "$ALL_QUESTION_IDS" | grep -c .)
ZERO_FINDINGS_COUNT=${#ZERO_FINDINGS_QUESTIONS[@]}

echo "Findings validation: ${ZERO_FINDINGS_COUNT}/${TOTAL_QUESTIONS_CHECKED} questions have zero web findings" >&2

if [ "$ZERO_FINDINGS_COUNT" -gt 0 ]; then
  echo "Questions with zero findings:" >&2
  for qid in "${ZERO_FINDINGS_QUESTIONS[@]}"; do
    echo "  - $qid" >&2
  done
fi
```

### 3.5.1c Build Combined Retry List

Combine questions with missing batches AND questions with zero findings:

```bash
# Combine retry lists (deduplicated)
# MISSING_QUESTIONS comes from Step 3.5.1 (missing batch files)
# ZERO_FINDINGS_QUESTIONS comes from Step 3.5.1b (zero findings)

# Bash 3.2 compatible - parallel arrays instead of associative array (declare -A requires Bash 4.0+)
COMBINED_RETRY_LIST=()
COMBINED_RETRY_REASONS=()

# Lookup helper: returns index if qid already in COMBINED_RETRY_LIST, or empty
_retry_index() {
  local target="$1" i=0
  for key in "${COMBINED_RETRY_LIST[@]}"; do
    if [ "$key" = "$target" ]; then echo "$i"; return 0; fi
    i=$((i + 1))
  done
  return 1
}

# Add missing batch questions
if [ -n "$MISSING_QUESTIONS" ]; then
  while IFS= read -r qid; do
    [ -z "$qid" ] && continue
    if ! _retry_index "$qid" >/dev/null 2>&1; then
      COMBINED_RETRY_LIST+=("$qid")
      COMBINED_RETRY_REASONS+=("missing_batch")
    fi
  done <<< "$MISSING_QUESTIONS"
fi

# Add zero-findings questions (may overlap with missing batches)
for qid in "${ZERO_FINDINGS_QUESTIONS[@]}"; do
  idx=$(_retry_index "$qid" 2>/dev/null) || true
  if [ -z "$idx" ]; then
    COMBINED_RETRY_LIST+=("$qid")
    COMBINED_RETRY_REASONS+=("zero_findings")
  else
    COMBINED_RETRY_REASONS[$idx]="${COMBINED_RETRY_REASONS[$idx]},zero_findings"
  fi
done

COMBINED_RETRY_COUNT=${#COMBINED_RETRY_LIST[@]}

echo "Combined retry list: ${COMBINED_RETRY_COUNT} questions" >&2
i=0
for qid in "${COMBINED_RETRY_LIST[@]}"; do
  echo "  - $qid (${COMBINED_RETRY_REASONS[$i]})" >&2
  i=$((i + 1))
done
```

### 3.5.2 Retry Missing/Zero-Findings Questions (Single Retry Batch)

**CRITICAL:** If `COMBINED_RETRY_LIST` is non-empty, invoke findings-creator for ALL retry questions **in parallel** (single message, multiple Task calls):

```text
# Invoke ALL retry questions in a SINGLE parallel batch
FOR each question_id in COMBINED_RETRY_LIST (in parallel, single message):
  Task(
    subagent_type="findings-creator",
    description="RETRY: {question_id} ({RETRY_MAP[question_id]})",
    prompt="Process refined question to create findings.

    Parameters (for Phase 0 placeholder substitution):
    - refined-question-path: {PROJECT_PATH}/02-refined-questions/data/{question_id}.md
    - project-path: {PROJECT_PATH}
    - language: {project_language}

    FRESH SHELL WARNING: Do NOT run separate export commands - they won't persist.
    When running the skill's Phase 0 bash block, replace the {{...}} placeholders inline:
    - {{REFINED_QUESTION_PATH}} → {PROJECT_PATH}/02-refined-questions/data/{question_id}.md
    - {{PROJECT_PATH}} → {PROJECT_PATH}
    - {{CONTENT_LANGUAGE}} → {project_language}

    Execute complete workflow and return concise summary."
  )
END FOR

# Wait for ALL retry agents to complete before re-validation
```

**Why parallel retries?** Unlike the deprecated sequential retry (Step 2.3.8), parallel execution is faster and the dedicated batch ensures all retries happen.

### 3.5.3 Re-Validate After Retries

```bash
# Re-run batch file reconciliation (full validation mode)
RETRY_RESULT="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/reconcile-question-batches.sh" \
  --project-path "${PROJECT_PATH}")"

STILL_MISSING_BATCHES="$(echo "$RETRY_RESULT" | jq -r '.missing_questions | length')"
FINAL_COVERAGE="$(echo "$RETRY_RESULT" | jq -r '.coverage_percent')"

# Re-run findings count validation
STILL_ZERO_FINDINGS=()
while IFS= read -r question_id; do
  [ -z "$question_id" ] && continue
  finding_count=$(grep -l "batch_ref: .*${question_id}" \
    "${PROJECT_PATH}/04-findings/data/"*.md 2>/dev/null | wc -l | tr -d ' ')
  if [ "$finding_count" -eq 0 ]; then
    STILL_ZERO_FINDINGS+=("$question_id")
  fi
done <<< "$ALL_QUESTION_IDS"

STILL_ZERO_COUNT=${#STILL_ZERO_FINDINGS[@]}

# Combine permanent failures
PERMANENT_FAILURES=()
if [ "$STILL_MISSING_BATCHES" -gt 0 ]; then
  while IFS= read -r qid; do
    [ -z "$qid" ] && continue
    PERMANENT_FAILURES+=("$qid:missing_batch")
  done <<< "$(echo "$RETRY_RESULT" | jq -r '.missing_questions[]' 2>/dev/null)"
fi
for qid in "${STILL_ZERO_FINDINGS[@]}"; do
  PERMANENT_FAILURES+=("$qid:zero_findings")
done

if [ ${#PERMANENT_FAILURES[@]} -gt 0 ]; then
  # Record permanent failures in sprint-log
  FAILURES_JSON=$(printf '%s\n' "${PERMANENT_FAILURES[@]}" | jq -R -s 'split("\n") | map(select(. != ""))')

  jq --argjson failures "$FAILURES_JSON" \
    '.phase_3_coverage.permanent_failures = $failures' \
    "${PROJECT_PATH}/.metadata/sprint-log.json" > tmp.json && \
    mv tmp.json "${PROJECT_PATH}/.metadata/sprint-log.json"

  echo "WARNING: ${#PERMANENT_FAILURES[@]} questions remain incomplete after retry batch" >&2
  echo "Permanent failures recorded. Proceeding to Phase 5 (will validate coverage)." >&2
else
  echo "Reconciliation PASSED: 100% coverage after retry batch" >&2
fi
```

### 3.5.4 Update Sprint Log

```bash
# Update sprint-log.json with final coverage metrics including findings validation
TOTAL_FINDINGS_VALIDATED=$(find "${PROJECT_PATH}/04-findings/data" -name "finding-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

# Build findings_per_question JSON object
FINDINGS_JSON=$(printf '%s\n' "${FINDINGS_PER_QUESTION[@]}" | \
  awk -F: '{print "\"" $1 "\": " $2}' | \
  paste -sd, - | \
  sed 's/^/{/;s/$/}/')

# Build zero_findings_questions JSON array
ZERO_JSON=$(printf '%s\n' "${ZERO_FINDINGS_QUESTIONS[@]}" | jq -R -s 'split("\n") | map(select(. != ""))')

jq --arg coverage "$FINAL_COVERAGE" \
   --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
   --argjson findings_per_q "$FINDINGS_JSON" \
   --argjson zero_findings "$ZERO_JSON" \
   --arg total_validated "$TOTAL_FINDINGS_VALIDATED" \
  '.phase_3_coverage.coverage_percent = ($coverage | tonumber) |
   .phase_3_coverage.validation_timestamp = $timestamp |
   .phase_3_coverage.reconciliation_type = "dedicated_batch" |
   .phase_3_coverage.findings_per_question = $findings_per_q |
   .phase_3_coverage.zero_findings_questions = $zero_findings |
   .phase_3_coverage.total_findings_validated = ($total_validated | tonumber)' \
  "${PROJECT_PATH}/.metadata/sprint-log.json" > tmp.json && \
  mv tmp.json "${PROJECT_PATH}/.metadata/sprint-log.json"

echo "Sprint log updated with findings validation metrics" >&2
```

**Mark Step 3.5 as completed** before proceeding to self-verification.

---

## Step 3.6: Batch Stall Recovery (IF NEEDED)

**Trigger:** Use this step if Phase 3 stalls mid-execution (e.g., after user says "ok" to continue due to output token limit).

### 3.6.1 Check Checkpoint Files

```bash
# List completed batch checkpoints
ls -la "${project_path}/.checkpoints/phase-3/" 2>/dev/null || echo "No checkpoints found"
```

### 3.6.2 Identify Last Completed Batch

The highest numbered `batch-N-complete` file indicates the last successfully completed batch. Example:

```text
batch-1-complete  →  Batch 1 finished
batch-2-complete  →  Batch 2 finished
(no batch-3-complete)  →  Resume from Batch 3
```

### 3.6.3 Resume from Next Batch

1. Re-run `discover-questions-by-dimension.sh` to get `EXECUTION_BATCHES`
2. Skip batches 1 through N (where N = highest checkpoint number)
3. Continue with Batch N+1 invocations

**DO NOT re-run completed batches.** Findings are already created in `04-findings/data/`.

### 3.6.4 Recovery State Check

Before resuming, verify current state:

```bash
# Count findings created so far
FINDING_COUNT=$(find "${project_path}/04-findings/data" -name "finding-*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "Current findings count: ${FINDING_COUNT}"

# Count questions total
QUESTION_COUNT=$(find "${project_path}/02-refined-questions/data" -name "question-*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "Total questions: ${QUESTION_COUNT}"

# Estimate progress (rough: expect ~5-10 findings per question)
echo "Estimated progress: $((FINDING_COUNT * 100 / (QUESTION_COUNT * 5)))% minimum"
```

### 3.6.5 Clear Stale Checkpoints (Optional)

If restarting Phase 3 from scratch (rare), clear all checkpoints:

```bash
rm -rf "${project_path}/.checkpoints/phase-3"
```

**Only do this if you intentionally want to re-run all batches.**

---

## ~~Step 4.5: Post-Execution Reconciliation~~ (SUPERSEDED)

**SUPERSEDED (v2.5.0):** Replaced by Step 3.5 (Dedicated Reconciliation Batch) which uses script-based validation with retry capability. The simple file-count comparison below is no longer sufficient.

For historical reference only - DO NOT USE:

---

## Before Marking Phase 3 Complete

**Self-Verification Questions:**

1. Did you run the phase entry verification gate (ls command)? YES / NO
2. **SCRIPT INVOCATION CHECK:** Did you invoke `discover-questions-by-dimension.sh` (Step 1.5)? YES / NO
3. Did the script return `execution_batches` with `total_batches > 0`? YES / NO
4. **PRE-EXECUTION VALIDATION:** Did you validate ALL batch files exist before parallel execution (Step 1.7)? YES / NO
5. If validation failed, did you HALT execution with clear error message? YES / N/A
6. Did you read project_language from sprint-log.json? YES / NO
6b. **RESEARCH TYPE DETECTION (Step 1.9):** Did you read `research_type` from sprint-log.json? YES / NO
7. **SEQUENTIAL BATCH CHECK:** Did you wait for ALL agents in Batch N to complete BEFORE starting Batch N+1? YES / NO
   - If you invoked Batch 2 while Batch 1 was still running → RE-RUN with proper sequencing
   - If you said "Alle X Agenten laufen parallel" (across batches) → VIOLATION
8. **NO BACKGROUND EXECUTION:** Did you invoke Task tools WITHOUT `run_in_background: true`? YES / NO
   - If any agent shows "Running in background" → VIOLATION: Results not awaited
   - If any agent shows "Launched" instead of results → VIOLATION: Background execution used
9. Did you pass `question-paths` (ALL questions in batch) to findings-creator-llm for each batch? YES / NO
9b. **SMARTER-SERVICE FILE (Conditional):** If `research_type == "smarter-service"`, did you invoke findings-creator-file for each question in each batch? YES / N/A
10. Did you invoke agents in parallel WITHIN each batch? YES / NO
11. **ANTI-BYPASS CHECK:** Are query batches present in `03-query-batches/data/`? (If empty, you bypassed agents) YES / NO
12. Did you aggregate results from ALL batches? YES / NO
13. Did you validate total findings count (LLM + web + file) >= 100? YES / NO
14. Did you update sprint-log.json with LLM, web, and file counts (if smarter-service)? YES / NO
15. **DEDICATED RECONCILIATION (Step 3.5):** Did you run reconciliation for ALL questions AFTER all batches completed? YES / NO
16. If any questions were missing batches, did you retry them in a SINGLE parallel batch (Step 3.5.2)? YES / N/A
17. Did you re-validate after the retry batch (Step 3.5.3)? YES / N/A
18. Did you update `sprint-log.json` with `phase_3_coverage` metrics (Step 3.5.4)? YES / NO
19. Is `coverage_percent` in sprint-log.json >= 95%? YES / NO
20. **FILESYSTEM VALIDATION (Step 2.3.5b):** Did you validate agent-reported finding counts against actual filesystem state for each batch? YES / NO
21. If filesystem validation detected mismatches (agent claimed N, filesystem has 0), did you add those questions to the retry queue? YES / N/A
22. Are aggregated finding counts based on filesystem-validated counts (not self-reported agent counts)? YES / NO
23. **FINDINGS-PER-QUESTION (Step 3.5.1b):** Did you count findings per question after batch reconciliation? YES / NO
24. Did you flag questions with zero web findings and add them to the combined retry list? YES / N/A
25. Did you update `sprint-log.json` with `findings_per_question` and `zero_findings_questions`? YES / NO

**IF ANY NO: STOP.** Return to incomplete step before proceeding to Phase 5.

**CRITICAL:** If question 2 is NO (script not invoked), you MUST run Step 1.5 before proceeding. Manual filename guessing caused 50/51 question failures.

**CRITICAL:** If question 10 is NO (no query batches), you MUST restart Phase 3 using Task tool invocations. DO NOT use WebSearch directly.

**CRITICAL:** If question 14 is NO (dedicated reconciliation not run), you skipped Step 3.5. This is MANDATORY - run it now before proceeding.

**CRITICAL:** If question 18 is NO (coverage < 95%), investigate permanent failures before proceeding to Phase 5.

**CRITICAL:** If question 7 is NO (batches not sequential), you caused "Prompt is too long" errors by invoking all batches simultaneously. This is the #1 cause of Phase 3 failures. RE-RUN with strict sequential execution: Batch 1 complete → THEN Batch 2 → THEN Batch 3.

**CRITICAL:** If question 20 is NO (filesystem validation skipped), agents may have reported success but created 0 findings. This is the "0 tool uses" bug. Run filesystem validation NOW before proceeding.

**CRITICAL:** If question 23 is NO (findings-per-question not counted), you skipped Step 3.5.1b. This safety net catches agents that passed Step 2.3.5b but still have issues. Run it NOW.

---

## Step 5: Mark Phase 3 Complete

- Update TodoWrite: Phase 3 → completed, Phase 5 → in_progress
- Update sprint metadata: phases_completed += ["parallel_findings_creation"], current_phase → "knowledge_extraction"

**Mark Step 5 todo as completed** before proceeding to Phase 5.

---

## Outputs

- Query batches: `{project_path}/03-query-batches/data/` (one per refined question)
- Findings: `{project_path}/04-findings/data/` (100+ findings with quality assessment)
- Updated sprint log with batch count and findings count

---

## Phase Completion Checklist

### MANDATORY: All items MUST be checked before proceeding to Phase 5

Before marking Phase 3 complete in TodoWrite, verify:

- [ ] Phase entry verification gate passed (dimensions + refined questions exist)
- [ ] **SCRIPT INVOCATION:** `discover-questions-by-dimension.sh` invoked successfully (Step 1.5)
- [ ] Script returned `execution_batches` with `total_batches > 0` (batching is automated)
- [ ] **PRE-EXECUTION VALIDATION:** All batch files exist (Step 1.7)
- [ ] Project language read from sprint-log.json
- [ ] **RESEARCH TYPE DETECTION (Step 1.9):** `research_type` read from sprint-log.json
- [ ] Batches executed SEQUENTIALLY (one batch at a time)
- [ ] **NO BACKGROUND:** All Task invocations used foreground execution (NOT `run_in_background: true`)
- [ ] `question-paths` parameter passed to findings-creator-llm for each batch (ALL questions in batch)
- [ ] **SMARTER-SERVICE FILE:** If `research_type == "smarter-service"`, findings-creator-file invoked per question per batch
- [ ] Agents invoked in parallel WITHIN each batch
- [ ] **ANTI-BYPASS:** Query batches exist in `03-query-batches/data/` (NOT empty)
- [ ] Results aggregated from ALL batches
- [ ] Total findings count validated (LLM + web + file >= 100)
- [ ] All finding types counted separately (LLM vs web vs file)
- [ ] Sprint log updated with LLM, web, and file counts (file only for smarter-service)
- [ ] **DEDICATED RECONCILIATION (Step 3.5):** Ran `reconcile-question-batches.sh` for ALL questions after all batches
- [ ] **FINDINGS-PER-QUESTION (Step 3.5.1b):** Counted findings per question after batch reconciliation
- [ ] Zero-findings questions flagged and added to combined retry list
- [ ] If missing/zero-findings questions: Retried in a SINGLE parallel batch (Step 3.5.2)
- [ ] Re-validated after retry batch (Step 3.5.3)
- [ ] Sprint log updated with `phase_3_coverage` metrics including `findings_per_question` and `zero_findings_questions` (Step 3.5.4)
- [ ] Coverage percent >= 95% (or permanent failures documented)
- [ ] **FILESYSTEM VALIDATION (Step 2.3.5b):** Validated agent-reported counts against actual filesystem state
- [ ] If filesystem mismatch detected: Added affected questions to retry queue
- [ ] Aggregated counts use filesystem-validated values (not self-reported)
- [ ] All step-level todos marked as completed
- [ ] All self-verification questions answered YES
- [ ] Phase 3 todo marked completed in TodoWrite

---

## Architecture: Question-Count-Based Batching

### Why Question-Count Batching?

| Problem | Solution |
|---------|----------|
| Inconsistent batch sizes across research types | Universal 15-20 question target |
| Context window exhaustion with 40+ agents | Batches capped at ~20 questions |
| Small batches inefficient (5 questions) | Dimensions grouped to reach minimum |
| Large batches unstable (50+ questions) | Hard limit prevents overload |

### Batch Composition

Each batch contains multiple dimensions grouped to reach 15-20 questions:

1. **1 findings-creator-llm** - Processes ALL questions in the batch (via `question-paths` parameter)
2. **m findings-creator** - One per question in the batch (web search), where m = 15-20

### Sequential vs Parallel

- **Between batches:** SEQUENTIAL (wait for completion)
- **Within batch:** PARALLEL (single message with multiple Task calls)

### Backward Compatibility

The findings-creator-llm skill supports both modes:

- **Default mode:** Process all questions (when `question-paths` not provided)
- **Filtered mode:** Process only specified questions (when `question-paths` provided)

---

## Version History

**v3.2.0** (2026-02-23)

- **Removed findings-creator-smarter-service:** Deprecated skill/agent deleted from plugin. findings-creator-file is the sole file-based findings source for `research_type == "smarter-service"`
- **Updated research-type-routing.md:** Routing table now references findings-creator-file

**v3.1.0** (2026-01-21)

- **Replaced findings-creator-smarter-service with findings-creator-file:** For `research_type == "smarter-service"`, Phase 3 now invokes findings-creator-file instead of findings-creator-smarter-service
- **Changed invocation pattern:** findings-creator-file processes ONE question at a time (like findings-creator web), not ALL questions in batch
- **Updated agent count formula:** Smarter-service now uses `1 LLM + N web + N file = 2N + 1` agents per batch (was `N + 2`)
- **Convention-based store path:** Store path derived from `${project_path}/rag-store/smarter-service` or `${WORKSPACE_ROOT}/rag-store/smarter-service`
- **New sprint-log field:** `file_findings_count` replaces `rag_findings_count`
- **Updated examples:** Smarter-service batch example now shows N file agents (27 agents for 13 questions)
- **Updated self-verification:** Question 9b now references findings-creator-file per question
- **Updated checklist:** File agent items replace RAG agent items
- **Three finding sources for smarter-service:** LLM (internal knowledge) + Web (search) + File (local document store)

**v3.0.0** (2026-01-11)

- **Added findings-creator-smarter-service integration:** For `research_type == "smarter-service"`, Phase 3 now invokes findings-creator-smarter-service in addition to findings-creator-llm and findings-creator
- **New Step 1.9:** Detect research_type from sprint-log.json to enable conditional RAG agent invocation
- **Three finding sources for smarter-service:** LLM (internal knowledge) + Web (search) + RAG (Smarter Service Custom GPT)
- **Task invocation pattern:** findings-creator-smarter-service uses same batch pattern as findings-creator-llm (ALL questions in batch)
- **Updated agent count formula:** Generic = 1 + N, Smarter-service = 1 + N + 1 = N + 2 agents per batch
- **New sprint-log field:** `rag_findings_count` added alongside `llm_findings_count` and `web_findings_count`
- **Updated examples:** Added smarter-service batch execution example with 3 agent types
- **Updated self-verification:** Questions 6b and 9b added for research type detection and RAG invocation
- **Updated checklist:** Research type detection and RAG agent items added to Phase Completion Checklist
- **TodoWrite template updated:** Step 1.9 added for research type detection

**v2.9.0** (2026-01-09)

- **Enhanced Step 3.5.1b:** Added dedicated Findings-Per-Question Validation after batch file reconciliation
- **Problem solved:** Questions where batch files exist but NO findings were created (passes Step 3.5.1 but has 0 findings)
- **New validation protocol:** Counts findings per question using `grep -l "batch_ref: .*{question_id}"` pattern
- **Combined retry list:** Step 3.5.1c now merges `MISSING_QUESTIONS` (missing batches) with `ZERO_FINDINGS_QUESTIONS`
- **Enhanced Step 3.5.4:** Sprint log now tracks `findings_per_question` object and `zero_findings_questions` array
- **Updated self-verification:** Questions 23-25 added for findings-per-question validation
- **Updated checklist:** Findings-per-question items added to Phase Completion Checklist
- **Safety net purpose:** Catches agents that pass Step 2.3.5b during batching but still have issues

**v2.8.0** (2026-01-09)

- **Added Step 2.3.5b:** Per-Agent Filesystem Validation - validates agent-reported finding counts against actual filesystem state
- **Problem solved:** Agents return `{"ok":true,"f":15}` but create 0 findings ("0 tool uses" bug)
- **Validation protocol:** After each agent response, count actual files in `04-findings/data/` matching `batch_ref`
- **Mismatch handling:** If filesystem count < 50% of claimed count, question added to retry queue
- **Aggregation update:** Step 2.4 now uses filesystem-validated counts, not self-reported counts
- **Updated self-verification:** Questions 20-22 added for filesystem validation
- **Updated checklist:** Filesystem validation items added to Phase Completion Checklist
- **Example outputs updated:** Now show "(filesystem-validated)" suffix on finding counts

**v2.7.0** (2026-01-02)

- **Removed Step 1.7 pre-flight cleanup:** The cleanup step was deleting valid batch files created by batch-creator
- **Root cause:** The `--cleanup-malformed` validation was too strict and deleted working batches
- **Step renumbering:** Old Step 1.8 (Pre-Execution Batch Validation) is now Step 1.7
- **Simplified workflow:** Phase 3 now proceeds directly from discovery (Step 1.5) to validation (Step 1.7)
- **Updated self-verification:** Removed questions about pre-flight cleanup
- **Updated checklist:** Removed pre-flight cleanup items

**v2.6.0** (2025-12-18) [SUPERSEDED]

- **Added Step 1.7:** Pre-Flight Batch Cleanup - detects and removes incomplete batch stubs before parallel execution
- **New script parameter:** `reconcile-question-batches.sh --cleanup-malformed` deletes malformed batches and moves to missing_questions
- **Problem solved:** Orphaned questions caused by incomplete stubs (~80 bytes) that exist but lack search_configs
- **Entity-index.json cleanup:** Malformed batches are also removed from entity-index.json when cleaned up
- **Updated TodoWrite template:** Step 1.7 added to Phase 3 step-level todos
- **Updated self-verification:** Questions 4-5 added for pre-flight cleanup validation
- **Updated checklist:** Pre-flight cleanup items added to Phase Completion Checklist
- **New output fields:** `cleaned_batches` array and `cleanup_enabled` flag in reconciliation output

**v2.5.1** (2025-12-16)

- **Fixed documentation example:** Corrected example JSON (lines 189-235) to use research-type-agnostic dimension names and show correct batching (3 batches of 18/17/11 instead of incorrect 2 batches of 38/8)
- **Algorithm hardening:** Added explicit handling for oversized dimensions (>22 questions) with dedicated batches and `_warning` flag
- **Post-batch validation:** Script now validates batch sizes and emits warnings for oversized batches (>22 questions)
- **Batching metadata:** Added `warnings` array to `.data.batching` when oversized batches detected

**v2.5.0** (2025-12-15)

- **Deprecated per-batch reconciliation:** Steps 2.3.7 and 2.3.8 deprecated - LLMs "forgot" to run them for subsequent batches
- **Added Step 3.5:** Dedicated Reconciliation Batch runs ONCE after ALL batches complete (harder to skip)
- **Parallel retry batch:** Missing questions retried in a single parallel batch (faster than sequential)
- **Simplified batch loop:** No reconciliation during batch execution - just execute and aggregate
- **Updated self-verification:** Removed per-batch questions, added Step 3.5 verification
- **Superseded Step 4.5:** Simple file-count reconciliation replaced by script-based Step 3.5

**v2.4.0** (2025-12-14)

- **Script-based batch validation:** Step 2.3.7 now uses `reconcile-question-batches.sh` for content validation
- **Added Step 2.3.8:** Immediate single-question retry with max 3 retries per question
- **Content validation:** Validates batch content (search_configs, question_ref) not just file existence
- **Sprint-log tracking:** Added `phase_3_coverage` object with retry_counts and permanent_failures
- **Self-verification updates:** Added questions 14-17 for reconciliation and coverage checks
- **Strict 100% enforcement:** Phase 5 entry gate will block if coverage < 100%

**v2.3.0** (2025-12-12)

- **Script-enforced batching:** `discover-questions-by-dimension.sh` now calculates and returns `execution_batches`
- **Removed Step 1.6:** Manual batch grouping algorithm deprecated (now in script)
- Script output includes `execution_batches` array with pre-calculated batches
- Reduced orchestrator complexity - no manual implementation required
- Fixed overage calculation: 10% of TARGET_MAX (4 questions) instead of absolute 10

**v2.2.0** (2025-12-12)

- **Universal question-count-based batching** replaces research-type-specific logic
- Target batch size: 15-20 questions (applies to ALL research types)
- Dimensions sorted by question count (largest first) for optimal packing
- Small trailing batches (<15 questions) merged with previous batch when possible
- Removed hardcoded b2b-ict-portfolio groupings
- Updated self-verification and checklist for universal batching

**v2.1.0** (2025-12-11)

- Added research-type-specific batch grouping (Step 1.6) [SUPERSEDED by v2.2.0]
- **b2b-ict-portfolio:** Multi-dimension batching (4 batches of 1+3+3+1 dimensions, 8 total)
  - Batch 1: Provider Profile Metrics (6 questions)
  - Batch 2: Connectivity + Security + Workplace (24 questions)
  - Batch 3: Cloud + Infrastructure + Application (22 questions)
  - Batch 4: Consulting (5 questions)
- Each batch has ONE findings-creator-llm for ALL questions in that batch
- Updated self-verification questions and checklist for research-type handling
- Backward compatible: Other research types use default 1-dimension-per-batch

**v2.0.0** (2025-12-08)

- **Breaking change:** Switched from all-parallel to dimension-batched execution
- Batches execute sequentially by dimension (reduces context window pressure)
- findings-creator-llm now invoked per dimension with `question-paths` parameter
- Added dimension discovery and question grouping (Step 1)
- Added batch execution loop with per-batch aggregation (Step 2)
- Updated validation checklist for dimension batching

**v1.0.0** (2025-11-26)

- Initial implementation: All agents in single parallel batch (N+1 agents)
- Single findings-creator-llm processing all questions
- N findings-creator agents (one per question)
