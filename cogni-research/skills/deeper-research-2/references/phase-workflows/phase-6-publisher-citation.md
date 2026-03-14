## Phase 6: Publisher Generation

<planning>
Create and enrich publisher entities from sources. Two strategies available:

1. **Batch Mode (Recommended for 100+ sources):** Two-phase architecture using `--batch-mode` flag.
   - Phase A: `create-publishers-batch.py` creates all publisher skeletons atomically
   - Phase B: Parallel enrichment agents add WebSearch context
   - Eliminates timeouts on large projects (7x speedup vs sequential)

2. **Legacy Mode (Small projects):** Single sequential invocation with `--all` flag.
   - Simpler but can timeout on 200+ sources
   - Use for projects under 100 sources
</planning>

**Strategy:** Batch mode for large projects (100+ sources), legacy mode for small projects

**Note:** The two-phase batch mode (v4.0) re-enables parallel enrichment by separating entity creation from enrichment. Entity-index.json writes happen only in Phase A (single process), so Phase B enrichment agents can run in parallel without race conditions.

**Runs after Phase 5.1 completes** (depends on source entities from Phase 4 and concepts/megatrends from Phase 5).

---

### Step 0: Derive project_path (MANDATORY)

**⛔ CRITICAL:** Before any Phase 6 work, derive and validate `project_path`:

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

### Step 1: Validate Sources Exist

**Objective:** Count sources for reporting and validation.

```bash
# Source entity configuration for directory resolution
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"

DIR_SOURCES="$(get_directory_by_key "sources")"
DIR_PUBLISHERS="$(get_directory_by_key "publishers")"
DATA_SUBDIR="$(get_data_subdir)"

# Count sources for reporting
source_count=$(find "{project-path}/$DIR_SOURCES" -name "source-*.md" -type f | wc -l | tr -d ' ') && echo "Sources: $source_count"

if [ "$source_count" -eq 0 ]; then
  echo "WARNING: No sources found in $DIR_SOURCES/$DATA_SUBDIR/" >&2
  # Skip Phase 6 - no sources to process
  SKIP_PHASE_6=true
else
  echo "Phase 6: Processing $source_count sources sequentially..." >&2
fi
```

### Step 2: Invoke Publisher-Generator

**Objective:** Process all sources using the appropriate mode based on project size.

**Choose mode based on source count from Step 1:**
- **100+ sources:** Use `--batch-mode` (two-phase architecture)
- **Under 100 sources:** Use `--all` (legacy sequential)

#### Option A: Batch Mode (Recommended for 100+ sources)

```bash
# Invoke publisher-generator with --batch-mode for two-phase processing
Task(
  subagent_type="cogni-research:publisher-generator",
  prompt="Process publishers at {project-path} --batch-mode",
  description="Generate publishers using batch mode"
)
```

**Two-Phase Execution:**
1. Phase A: `create-publishers-batch.py` creates all publisher skeletons atomically (~15 sec)
2. Phase B: Parallel enrichment agents process ~25 publishers each (~3-4 min total)

**Expected Response:**
```json
{
  "success": true,
  "mode": "batch",
  "sources_processed": 474,
  "publishers_created": 185,
  "publishers_reused": 26,
  "publishers_enriched": 208,
  "enrichment_failed": 3,
  "phase_a_time_seconds": 12.5,
  "failed_items": []
}
```

#### Option B: Legacy Mode (Small projects under 100 sources)

```bash
# Invoke single publisher-generator with --all flag
Task(
  subagent_type="cogni-research:publisher-generator",
  prompt="Process publishers at {project-path} --all",
  description="Generate publishers for all sources"
)
```

**Expected Response:**
```json
{
  "success": true,
  "sources_processed": 48,
  "publishers_created": 42,
  "publishers_reused": 8,
  "publishers_enriched": 48,
  "creation_failed": 0,
  "enrichment_failed": 2,
  "sources_without_domain": 0,
  "batch_id": null,
  "resolution_mode": "all",
  "by_type": {"individual": 25, "organization": 25},
  "failed_items": []
}
```

### Step 3: Process Response

**Objective:** Extract metrics from single agent response (no aggregation needed).

```bash
# Parse JSON response directly (single invocation, no aggregation)
response="${agent_response}"

success=$(echo "$response" | jq -r '.success')
sources_processed=$(echo "$response" | jq -r '.sources_processed')
publishers_created=$(echo "$response" | jq -r '.publishers_created')
publishers_reused=$(echo "$response" | jq -r '.publishers_reused')
publishers_enriched=$(echo "$response" | jq -r '.publishers_enriched')
creation_failed=$(echo "$response" | jq -r '.creation_failed')
enrichment_failed=$(echo "$response" | jq -r '.enrichment_failed')
individuals=$(echo "$response" | jq -r '.by_type.individual')
organizations=$(echo "$response" | jq -r '.by_type.organization')

# Calculate derived metrics
total_publishers=$((publishers_created + publishers_reused))
```

### Step 4: Report Phase Completion

**Objective:** Report metrics and mark phase complete.

```bash
# Report completion
if [ "$success" = "true" ]; then
  echo "✓ Phase 6: Generated $total_publishers publishers ($publishers_created created, $publishers_reused reused, $publishers_enriched enriched)" >&2
else
  echo "✗ Phase 6: Publisher generation failed" >&2
  error=$(echo "$response" | jq -r '.error // "Unknown error"')
  echo "  Error: $error" >&2
fi

# Mark complete in TodoWrite
```

### Step 5: Validation (FAILURE GATE)

**Objective:** Verify publisher entities created correctly. **HALT pipeline if 0 files created when expecting more.**

```bash
# Count publishers in filesystem
actual_publishers=$(find {project-path}/$DIR_PUBLISHERS -name "publisher-*.md" -type f | wc -l | tr -d ' ')

# CRITICAL: Halt if 0 files when expecting more (indicates Write tool failure)
if [ "$actual_publishers" -eq 0 ] && [ "$total_publishers" -gt 0 ]; then
  echo "CRITICAL: Publisher generation produced 0 files (expected: $total_publishers)" >&2
  echo "HALTING PIPELINE: Phase 7 cannot proceed without publishers" >&2
  echo "Root cause: Write tool was likely not invoked during Phase 2 processing" >&2
  # DO NOT continue to Phase 6.1 - return error response
  exit 1
fi

# WARNING: Continue if some files exist but count mismatches
if [ "$actual_publishers" -ne "$total_publishers" ]; then
  echo "WARNING: Publisher count mismatch (expected: $total_publishers, actual: $actual_publishers)" >&2
  echo "Continuing with $actual_publishers publishers available" >&2
fi
```

**Error Handling:**

- **CRITICAL (0 files):** If publisher generation produces 0 files when expecting >0, HALT pipeline immediately
  - This indicates a skill execution failure (Write tool not invoked)
  - Phase 7 (claims) cannot proceed without publishers
  - Return error response, do not continue to Phase 6.1

- **WARNING (partial):** If some files exist but count mismatches, log warning and continue to Phase 6.1
  - Citations will use available publishers with domain-based fallback for missing ones

**Performance:**

- **Batch mode (100+ sources):** ~4 minutes for 200+ publishers (7x faster than sequential)
  - Phase A: ~15 seconds (atomic batch creation)
  - Phase B: ~3-4 minutes (parallel enrichment)
- **Legacy mode (under 100 sources):** ~8 seconds per publisher (acceptable for small projects)
- Both modes avoid entity-index.json race conditions

### Step 6: Generate Publishers README

Generate the publishers directory README with provenance chain and entity index:

```bash
# Get project language from sprint-log
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${project_path}/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Resolve script path
PUBLISHERS_README_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/generate-publishers-readme.sh"

# Generate publishers README
bash "$PUBLISHERS_README_SCRIPT" \
  --project-path "${project_path}" \
  --language "${PROJECT_LANGUAGE}" \
  --json
```

**Expected Response:**

```json
{
  "success": true,
  "data": {
    "readme_path": "{project-path}/08-publishers/README.md",
    "readme_created": true
  },
  "stats": {
    "publisher_count": 42,
    "individual_count": 18,
    "organization_count": 24,
    "source_refs_total": 156
  }
}
```

**Note:** Exit code 3 (no publisher files) is non-blocking - continue to Phase 6.1 if no publishers exist.

---

## Phase 6.1-6.5: Citation Management

**Objective:** Clean data quality, enforce quality gates, and generate citations linking sources to publishers.

Phase 6.1-6.5 runs sequentially after Phase 6 completes:

- **Phase 6.1:** Data Quality Management
- **Phase 6.5:** Data Quality Gate (NEW)
- **Phase 6.2:** Citation Generation

---

## Phase 6.2: Citation Generation

<planning>
Generate citations by linking sources to publishers (if available from publisher-generator skill). citation-generator reads existing source and publisher entities using complete data loading and multi-strategy publisher resolution (domain_exact, name_exact, reverse_index, domain_fallback). If publishers don't exist, falls back to domain-based attribution.
</planning>

**Strategy:** Single agent with complete data loading

**Runs after Phase 6.5 completes** (depends on quality gate passing and source entities being validated).

1. Invoke citation-generator:
   - Agent: `cogni-research:citation-generator`
   - Parameters: `--project-path {project-path}`
   - Expected JSON: `{"success": true, "citations_created": 23, "publisher_matches": {"domain_exact": 15, "name_exact": 5, "reverse_index": 2, "domain_fallback": 1}}`

2. Validate response (expect JSON-only)
3. Extract citations_created count and match statistics
4. Report: `✓ Phase 6.2: Generated {citations_created} citations linking sources to publishers (strategies: {domain_exact} domain, {name_exact} name, {reverse_index} reverse, {domain_fallback} fallback)`
5. Mark complete in TodoWrite

**Note:** Parallel execution support removed in Sprint 060. Citation-generator now uses complete data loading with multi-strategy publisher resolution for improved accuracy. Focus on correctness first; parallelization can be re-added later if performance becomes an issue.

---
