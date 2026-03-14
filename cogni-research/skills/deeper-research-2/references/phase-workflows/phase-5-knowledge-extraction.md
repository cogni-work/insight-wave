# Phase 5: Knowledge Extraction (Parallelized)

**Objective:** Extract domain concepts and megatrends from findings after Phase 4 (Source Creation & Validation) completes.

Phase 5 extracts knowledge entities using **parallel dimension-based execution**:

- **Phase 5.1:** Parallel concept extraction (one agent per dimension)
- **Phase 5.2:** Sequential merge + cross-dimension megatrend clustering

**Outputs:**

- **Domain Concepts** → `05-domain-concepts/data/`
- **Megatrends** → `06-megatrends/data/`

**SEQUENTIAL DEPENDENCY:** Phase 5 runs AFTER Phase 4 completes. Source entities must be created and validated before knowledge extraction begins.

---

## Step 0: Derive project_path (MANDATORY)

**⛔ CRITICAL:** Before any Phase 5 work, derive and validate `project_path`:

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

---

## Step 0.5: Phase 4 Completion Gate (BLOCKING)

**MANDATORY:** Before starting Phase 5, verify Phase 4 completed successfully.

### Verification Logic

```bash
# Validate PROJECT_PATH is set (prevents empty variable bug)
if [ -z "${PROJECT_PATH:-}" ]; then
  echo "ERROR: PROJECT_PATH not set. Run Step 0 first." >&2
  exit 1
fi

# Verify Phase 4.1 (Source Creation) completed
if [ ! -f "${PROJECT_PATH}/.metadata/phase-4.1-complete" ]; then
  echo "ERROR: Phase 4.1 incomplete - source creation did not complete" >&2
  echo "Run Phase 4.1 (source-creator) before proceeding to Phase 5" >&2
  exit 1
fi

# Verify Phase 4.2 (Validation & Repair) completed
if [ ! -f "${PROJECT_PATH}/.metadata/phase-4.2-complete" ]; then
  echo "ERROR: Phase 4.2 incomplete - source validation did not complete" >&2
  echo "Run Phase 4.2 (validate-sources) before proceeding to Phase 5" >&2
  exit 1
fi

# Check validation quality (informational, non-blocking)
VALIDATION_STATUS=$(jq -r '.phase_4_validation // empty' "${PROJECT_PATH}/.metadata/sprint-log.json")
if [ -n "$VALIDATION_STATUS" ]; then
  VALID_SOURCES=$(echo "$VALIDATION_STATUS" | jq -r '.valid_sources // 0')
  INVALID_SOURCES=$(echo "$VALIDATION_STATUS" | jq -r '.invalid_sources // 0')

  if [ "$VALID_SOURCES" -eq 0 ]; then
    echo "WARNING: No validated sources - knowledge extraction may be limited" >&2
  fi

  if [ "$INVALID_SOURCES" -gt 0 ]; then
    echo "INFO: Phase 4 reported $INVALID_SOURCES invalid sources (logged in sprint-log.json)" >&2
  fi
fi

echo "Phase 4 Completion Gate PASSED: Sources created and validated" >&2
```

### On Failure

- **HALT workflow** - do NOT proceed to Phase 5.1
- Display which Phase 4 sub-phase is incomplete
- Instruct user to complete Phase 4 first
- Log failure in sprint-log.json

### On Success

- Proceed to Phase 5.1 (Parallel Concept Extraction)
- Log: "Phase 4 Completion Gate PASSED"

---

## Phase 5.1: Parallel Concept Extraction

Extract concepts in parallel, with one knowledge-extractor agent per dimension.

### 5.1.1 Discover Dimensions

```bash
# List all dimensions
dimensions=()
for dim_file in "${PROJECT_PATH}"/01-research-dimensions/data/dimension-*.md; do
  [ -f "$dim_file" ] || continue
  dim_slug=$(basename "$dim_file" .md)
  dimensions+=("$dim_slug")
done
dimension_count=${#dimensions[@]}

echo "Phase 5.1: Discovered $dimension_count dimensions for parallel extraction"
```

### 5.1.2 Invoke Parallel Knowledge-Extractors

**Single message, multiple Task calls** (following Phase 3 pattern):

Invoke ALL knowledge-extractor agents in parallel. Repeat the following block for EACH dimension in a single message:

```xml
<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="description">Extract concepts for {{dimension}}</parameter>
  <parameter name="prompt">
Extract concepts from research project.

PROJECT_PATH={{project_path}}
DIMENSION={{dimension}}
CONCEPTS_ONLY=true

Extract domain concepts from findings belonging to dimension: {{dimension}}
Return JSON with concepts_created count.
  </parameter>
</invoke>
```

**Example with 3 dimensions (all in single message):**

```xml
<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="description">Extract concepts for dimension-market-dynamics</parameter>
  <parameter name="prompt">
Extract concepts from research project.

PROJECT_PATH=/path/to/project
DIMENSION=dimension-market-dynamics
CONCEPTS_ONLY=true

Extract domain concepts from findings belonging to dimension: dimension-market-dynamics
Return JSON with concepts_created count.
  </parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="description">Extract concepts for dimension-technology-trends</parameter>
  <parameter name="prompt">
Extract concepts from research project.

PROJECT_PATH=/path/to/project
DIMENSION=dimension-technology-trends
CONCEPTS_ONLY=true

Extract domain concepts from findings belonging to dimension: dimension-technology-trends
Return JSON with concepts_created count.
  </parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="description">Extract concepts for dimension-competitive-landscape</parameter>
  <parameter name="prompt">
Extract concepts from research project.

PROJECT_PATH=/path/to/project
DIMENSION=dimension-competitive-landscape
CONCEPTS_ONLY=true

Extract domain concepts from findings belonging to dimension: dimension-competitive-landscape
Return JSON with concepts_created count.
  </parameter>
</invoke>
```

**IMPORTANT:** All Task calls must be in a single message for parallel execution.

⛔ **CRITICAL: NO BACKGROUND EXECUTION**

- **NEVER** use `run_in_background` parameter for Task tool invocations
- Parallel execution is achieved by invoking multiple Task tools in a **single message** (Claude Code handles parallelization automatically)
- Background execution breaks phase sequencing because "Launched" returns immediately without waiting

**Forbidden Pattern (causes context exhaustion):**

```xml
<!-- ⛔ FORBIDDEN - do NOT use run_in_background -->
<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="run_in_background">true</parameter>  <!-- ⛔ FORBIDDEN -->
  <parameter name="description">Extract concepts for dimension-1</parameter>
  <parameter name="prompt">...</parameter>
</invoke>
<!-- Returns "Launched" immediately, Phase 5.2 starts prematurely -->
```

**Correct Pattern (invoke ALL in single message):**

```xml
<!-- ✅ CORRECT - multiple Task calls in single message, NO run_in_background -->
<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="description">Extract concepts for dimension-1</parameter>
  <parameter name="prompt">PROJECT_PATH=... DIMENSION=dimension-1 CONCEPTS_ONLY=true ...</parameter>
</invoke>

<invoke name="Task">
  <parameter name="subagent_type">cogni-research:knowledge-extractor</parameter>
  <parameter name="description">Extract concepts for dimension-2</parameter>
  <parameter name="prompt">PROJECT_PATH=... DIMENSION=dimension-2 CONCEPTS_ONLY=true ...</parameter>
</invoke>

<!-- ... repeat for all dimensions ... -->
<!-- Claude Code runs ALL tasks in parallel, WAITS for all to complete, then returns all results -->
```

### 5.1.3 Collect and Validate Responses

Wait for all agent responses and track results:

```bash
# Response collection
successful_dimensions=()
failed_dimensions=()
total_concepts=0

for response in responses:
    if response.success:
        successful_dimensions+=("$response.dimension")
        total_concepts+=$response.concepts_created
    else:
        failed_dimensions+=("$response.dimension")
        log_conditional WARN "Dimension failed: $response.dimension - $response.error"
```

### 5.1.4 Retry Failed Dimensions (Once)

If any dimensions failed, retry them once:

```python
if len(failed_dimensions) > 0:
    echo "Retrying ${#failed_dimensions[@]} failed dimensions..."

    for dimension in failed_dimensions:
        Task(
            subagent_type="cogni-research:knowledge-extractor",
            prompt=f"""RETRY: Extract concepts from research project.

PROJECT_PATH={project_path}
DIMENSION={dimension}
CONCEPTS_ONLY=true

Extract domain concepts from findings belonging to dimension: {dimension}""",
            description=f"Retry: Extracting concepts for {dimension}"
        )

    # Collect retry responses
    for retry_response in retry_responses:
        if retry_response.success:
            successful_dimensions+=("$retry_response.dimension")
            total_concepts+=$retry_response.concepts_created
        else:
            echo "WARNING: Dimension {dimension} failed after retry - continuing without it"
```

### 5.1.5 Report Phase 5.1 Completion

```bash
echo "Phase 5.1 Complete: Extracted concepts from ${#successful_dimensions[@]}/${dimension_count} dimensions"
echo "  - Total concepts created: $total_concepts"

if [ ${#failed_dimensions[@]} -gt 0 ]; then
  echo "  - WARNING: ${#failed_dimensions[@]} dimensions failed: ${failed_dimensions[*]}"
fi
```

---

## Phase 5.2: Sequential Merge + Megatrend Clustering

After parallel extraction, invoke knowledge-merger to deduplicate concepts and create cross-dimension megatrends.

### 5.2.1 Invoke Knowledge-Merger Agent

```python
Task(
    subagent_type="cogni-research:knowledge-merger",
    prompt=f"""Merge concepts and cluster megatrends.

PROJECT_PATH={project_path}

1. Deduplicate concepts created by parallel extraction
2. Perform cross-dimension megatrend clustering
3. Update dimension backlinks
4. Generate README mindmaps

Return JSON with final counts.""",
    description="Merging concepts and creating megatrends"
)
```

### 5.2.2 Validate Merge Response

```bash
if [ "$merge_response.success" = true ]; then
  echo "Phase 5.2 Complete: Merged ${merge_response.concepts_deduplicated} duplicates"
  echo "  - Final concepts: ${merge_response.concepts_final}"
  echo "  - Megatrends created: ${merge_response.megatrends_created}"
  echo "  - Dimensions updated: ${merge_response.dimensions_updated}"
else
  echo "ERROR: Knowledge merge failed: ${merge_response.error}"
  exit 1
fi
```

### 5.2.3 Phase 5 Completion Checkpoint

```bash
# Write Phase 5.1 completion marker
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${PROJECT_PATH}/.metadata/phase-5.1-complete"

# Write parallel execution stats
cat > "${PROJECT_PATH}/.metadata/phase-5-parallel-stats.json" <<EOF
{
  "dimensions_total": ${dimension_count},
  "dimensions_successful": ${#successful_dimensions[@]},
  "dimensions_failed": ${#failed_dimensions[@]},
  "concepts_extracted": ${total_concepts},
  "concepts_final": ${merge_response.concepts_final},
  "concepts_deduplicated": ${merge_response.concepts_deduplicated},
  "megatrends_created": ${merge_response.megatrends_created}
}
EOF

# Verify completion
if [ ! -f "${PROJECT_PATH}/.metadata/phase-5.1-complete" ]; then
  echo "ERROR: Phase 5.1 incomplete - knowledge extraction did not complete" >&2
  exit 1
fi

echo "Phase 5 complete: Knowledge extraction finished" >&2
```

---

## Phase 5 Completion Gate

**BLOCKING:** Phase 6 cannot start until Phase 5.1 completes:

```bash
# Verify Phase 5.1 completed before Phase 6
if [ ! -f "${PROJECT_PATH}/.metadata/phase-5.1-complete" ]; then
  echo "ERROR: Phase 5.1 incomplete - cannot proceed to Phase 6" >&2
  exit 1
fi

echo "Phase 5 complete: Concepts and megatrends extracted" >&2
```

---

## Performance Comparison

| Scenario | Old (Sequential) | New (Parallel) | Speedup |
|----------|------------------|----------------|---------|
| 5 dimensions, 200 findings | ~15 minutes | ~4 minutes | ~3.75× |
| 8 dimensions, 400 findings | ~30 minutes | ~6 minutes | ~5× |

**Note:** Speedup depends on dimension distribution. More dimensions = better parallelization.

---

## Self-Verification Questions

1. Did Phase 4 Completion Gate pass? YES/NO
2. Did you discover all dimensions? YES/NO
3. Did you invoke ALL knowledge-extractors in parallel (single message)? YES/NO
4. **⛔ NO BACKGROUND EXECUTION:** Did you invoke Task tools WITHOUT `run_in_background: true`? YES/NO
5. Did you retry failed dimensions once? YES/NO
6. Did you invoke knowledge-merger? YES/NO
7. Are concepts created in 05-domain-concepts/data/? YES/NO
8. Are megatrends created in 06-megatrends/data/? YES/NO
9. Is phase-5.1-complete marker present? YES/NO

If ANY NO: STOP and complete missing steps.

---

## Outputs

- Domain Concepts: `{project_path}/05-domain-concepts/data/` (deduplicated)
- Megatrends: `{project_path}/06-megatrends/data/` (cross-dimension clustered)
- Completion marker: `{project_path}/.metadata/phase-5.1-complete`
- Parallel execution stats: `{project_path}/.metadata/phase-5-parallel-stats.json`
