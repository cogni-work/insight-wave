# Implementation Patterns

Bash code patterns and snippets for fact-checking workflow execution.

---

## ⚠️ Bash Syntax Requirements (MANDATORY)

**Before generating any bash code, you MUST follow these rules:**

1. **Command separation:** Every command on its own line (or separated by `;`)
2. **Integer arithmetic:** Use `$(( ))` not `| bc` for partition calculations
3. **Variable names:** Use EXACT names from patterns below (e.g., `FINDINGS_TOTAL`, `START_INDEX`, `END_INDEX`)

**Full rules:** `../../references/shared-bash-patterns.md` Section 5

---

## Parameter Parsing

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 1

## Working Directory Validation

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 2

## Logging Initialization

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 3

## Processing Range Determination

Calculate partition slice for parallel processing.

```bash
log_phase "Phase 3: Determine Processing Range" "start"

# List findings (check for resumption pending-findings file first)
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
PENDING_FILE="${PROJECT_PATH}/.metadata/phase-7-pending-findings.txt"
FINDINGS_LIST=()
if [ -f "$PENDING_FILE" ]; then
    # Resumption mode: only process pending findings
    log_conditional INFO "Resumption mode: loading pending findings from ${PENDING_FILE}"
    while IFS= read -r f; do
        [ -n "$f" ] && [ -f "$f" ] && FINDINGS_LIST+=("$f")
    done < "$PENDING_FILE"
else
    # Full mode: process all findings
    while IFS= read -r f; do
        FINDINGS_LIST+=("$f")
    done < <(find "${PROJECT_PATH}/${FINDINGS_DIR}/data" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort)
fi
FINDINGS_TOTAL=${#FINDINGS_LIST[@]}

# Early exit if no findings
if [ $FINDINGS_TOTAL -eq 0 ]; then
  log_conditional INFO "No findings found in ${PROJECT_PATH}/${FINDINGS_DIR}/data/ - exiting successfully"
  echo '{"success": true, "findings_processed": 0, "claims_created": 0, "message": "No findings to process"}' > ".logs/fact-checker-stats.json"
  exit 0
fi

log_conditional INFO "Total findings available: $FINDINGS_TOTAL"

# Determine processing mode
if [ -n "$PARTITION_INDEX" ] && [ -n "$TOTAL_PARTITIONS" ]; then
  log_conditional INFO "Self-partitioning mode: partition $PARTITION_INDEX of $TOTAL_PARTITIONS"

  # Calculate partition size (ceiling division)
  PARTITION_SIZE=$(( (FINDINGS_TOTAL + TOTAL_PARTITIONS - 1) / TOTAL_PARTITIONS ))

  # Calculate start and end indices
  START_INDEX=$(( PARTITION_INDEX * PARTITION_SIZE ))
  END_INDEX=$(( START_INDEX + PARTITION_SIZE ))

  # Clamp end index
  if [ $END_INDEX -gt $FINDINGS_TOTAL ]; then
    END_INDEX=$FINDINGS_TOTAL
  fi

  log_conditional INFO "Processing range: [$START_INDEX, $END_INDEX) (size: $PARTITION_SIZE)"

  # Extract assigned findings (use actual count, not partition size)
  ACTUAL_COUNT=$(( END_INDEX - START_INDEX ))
  FINDINGS_TO_PROCESS=("${FINDINGS_LIST[@]:$START_INDEX:$ACTUAL_COUNT}")

  # Recalculate actual count after slicing (handles edge case where slice has fewer elements)
  ACTUAL_COUNT=${#FINDINGS_TO_PROCESS[@]}

  log_conditional INFO "Partition slice: START=$START_INDEX, END=$END_INDEX, COUNT=$ACTUAL_COUNT"
else
  log_conditional INFO "Sequential mode: processing all findings"
  FINDINGS_TO_PROCESS=("${FINDINGS_LIST[@]}")
  START_INDEX=0
  END_INDEX=$FINDINGS_TOTAL
fi

ASSIGNED_COUNT=${#FINDINGS_TO_PROCESS[@]}
log_conditional INFO "Assigned findings count: $ASSIGNED_COUNT"

# Early return if partition is empty (optimization)
if [ $ASSIGNED_COUNT -eq 0 ]; then
  log_conditional WARN "Empty partition - no findings to process"

  # Determine stats file path
  if [ -n "$PARTITION_INDEX" ]; then
    STATS_FILE="${PROJECT_PATH}/.logs/partition-${PARTITION_INDEX}-stats.json"
  else
    STATS_FILE="${PROJECT_PATH}/.logs/fact-checker-stats.json"
  fi

  # Write success JSON with zero counts
  echo '{"success": true, "findings_processed": 0, "claims_created": 0, "message": "Empty partition"}' > "$STATS_FILE"
  exit 0
fi

log_phase "Phase 3: Determine Processing Range" "complete"
```

## Counter Aggregation

Aggregate statistics with floating-point precision using bc.

```bash
# Initialize counters
findings_processed=0
claims_created=0
flagged_for_review=0
flagged_by_evidence=0
flagged_by_quality=0
critical_low_confidence=0

# Track aggregates for averages (use bc with proper precision)
total_evidence_confidence=0
total_claim_quality=0
total_confidence=0

# Track quality dimensions
total_atomicity=0
total_fluency=0
total_decontextualization=0
total_faithfulness=0

# Track quality flags
atomicity_issues=0
decontextualization_issues=0
faithfulness_issues=0
fluency_issues=0

# Update counters during processing (example)
claims_created=$((claims_created + 1))

# Update aggregates with proper floating-point precision (scale=4)
total_evidence_confidence=$(echo "scale=4; $total_evidence_confidence + 0.82" | bc)
total_claim_quality=$(echo "scale=4; $total_claim_quality + 0.75" | bc)
total_confidence=$(echo "scale=4; $total_confidence + 0.79" | bc)

# Update quality dimensions with proper precision
total_atomicity=$(echo "scale=4; $total_atomicity + 1.0" | bc)
total_fluency=$(echo "scale=4; $total_fluency + 0.92" | bc)
total_decontextualization=$(echo "scale=4; $total_decontextualization + 0.78" | bc)
total_faithfulness=$(echo "scale=4; $total_faithfulness + 0.88" | bc)
```

## Average Calculation

Calculate averages from aggregated totals.

```bash
# Calculate averages
if [ $claims_created -gt 0 ]; then
  avg_evidence_confidence=$(echo "scale=2; $total_evidence_confidence / $claims_created" | bc)
  avg_claim_quality=$(echo "scale=2; $total_claim_quality / $claims_created" | bc)
  avg_confidence=$(echo "scale=2; $total_confidence / $claims_created" | bc)

  avg_atomicity=$(echo "scale=2; $total_atomicity / $claims_created" | bc)
  avg_fluency=$(echo "scale=2; $total_fluency / $claims_created" | bc)
  avg_decontextualization=$(echo "scale=2; $total_decontextualization / $claims_created" | bc)
  avg_faithfulness=$(echo "scale=2; $total_faithfulness / $claims_created" | bc)
else
  avg_evidence_confidence=0
  avg_claim_quality=0
  avg_confidence=0
  avg_atomicity=0
  avg_fluency=0
  avg_decontextualization=0
  avg_faithfulness=0
fi
```

## JSON Statistics Generation

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 4

**Skill-Specific Response Fields:**

The fact-checker skill requires these specific JSON fields in the statistics response:

```json
{
  "success": true,
  "findings_processed": 0,
  "claims_created": 0,
  "avg_evidence_confidence": 0.0,
  "avg_claim_quality": 0.0,
  "avg_confidence": 0.0,
  "flagged_for_review": 0,
  "flagged_by_evidence": 0,
  "flagged_by_quality": 0,
  "critical_low_confidence": 0,
  "quality_dimension_averages": {
    "atomicity": 0.0,
    "fluency": 0.0,
    "decontextualization": 0.0,
    "faithfulness": 0.0
  },
  "quality_flags_breakdown": {
    "atomicity_issues": 0,
    "decontextualization_issues": 0,
    "faithfulness_issues": 0,
    "fluency_issues": 0
  },
  "error_count": 0,
  "partition_info": {
    "mode": "sequential",
    "partition_index": 0,
    "total_partitions": 1,
    "findings_start": 0,
    "findings_end": 0,
    "findings_total": 0
  }
}
```

## Wikilink Extraction from Findings

Extract source IDs from finding frontmatter to build provenance chain.

```bash
# Source entity configuration for directory resolution (monorepo-aware)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi
source "$ENTITY_CONFIG"

DIR_SOURCES="$(get_directory_by_key "sources")"
DATA_SUBDIR="$(get_data_subdir)"

# Initialize array
source_ids=()

# Process each finding
for finding_file in "${FINDING_IDS[@]}"; do
  # Extract source_id field from YAML frontmatter
  # Note: || true prevents script exit if grep finds no match (when using set -e)
  RAW_SOURCE_ID=$(grep "^source_id:" "$finding_file" 2>/dev/null | head -1 | sed 's/^source_id:[[:space:]]*//' || true)

  # Remove surrounding quotes if present
  RAW_SOURCE_ID="${RAW_SOURCE_ID%\"}"
  RAW_SOURCE_ID="${RAW_SOURCE_ID#\"}"

  # Skip if empty
  if [ -z "$RAW_SOURCE_ID" ]; then
    continue
  fi

  # Check if already a wikilink (source_id stored as [[07-sources/data/source-xxx]])
  if [[ "$RAW_SOURCE_ID" =~ ^\[\[.*\]\]$ ]]; then
    # Already a wikilink - use directly
    source_ids+=("$RAW_SOURCE_ID")
  else
    # Plain ID - wrap in wikilink format (legacy support)
    source_ids+=("[[$DIR_SOURCES/$DATA_SUBDIR/$RAW_SOURCE_ID]]")
  fi
done

# Deduplicate
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
unique_source_ids=()
while IFS= read -r id; do
    unique_source_ids+=("$id")
done < <(printf '%s\n' "${source_ids[@]}" | sort -u)
source_ids=("${unique_source_ids[@]}")
```

## Query Batch Extraction

Extract refined questions from query batch files.

```bash
# Read batch file
BATCH_CONTENT="$(cat "$BATCH_FILE")"

# Extract wikilinks from "Source Questions" section
# Pattern: Match lines starting with "- [[" and extract the wikilink
REFINED_QUESTIONS="$(echo "$BATCH_CONTENT" | \
  awk '/## Source Questions/,/^## [^S]/ {print}' | \
  grep -oE '\[\[[^]]+\]\]' | \
  sort -u)"

# Convert to array
REFINED_QUESTION_IDS=()
while IFS= read -r question; do
  if [ -n "$question" ]; then
    REFINED_QUESTION_IDS+=("$question")
  fi
done <<< "$REFINED_QUESTIONS"
```

## Error Handling Patterns

**Moved to shared reference:** `../../references/shared-bash-patterns.md` Section 5

**Skill-Specific Error Handling:**

```bash
# Evidence confidence calculation error
if ! evidence_confidence=$(calculate_evidence_confidence); then
  log_conditional "ERROR" "Evidence confidence calculation failed - using default 0.0"
  evidence_confidence=0
  # Flag claim for review due to calculation failure
  claim_flagged=true
fi

# Claim quality calculation error
if ! claim_quality=$(calculate_claim_quality); then
  log_conditional "ERROR" "Claim quality calculation failed - using default 0.0"
  claim_quality=0
  # Flag claim for review due to calculation failure
  claim_flagged=true
fi
```

## Loop Processing Pattern

Standard pattern for processing entities in parallel-safe manner.

```bash
# Process each assigned finding
for finding_file in "${FINDINGS_TO_PROCESS[@]}"; do
  log_conditional INFO "Processing finding: $(basename "$finding_file")"
  findings_processed=$((findings_processed + 1))

  # Read finding content
  FINDING_CONTENT=$(cat "$finding_file")

  # ===== AGENT IMPLEMENTATION REQUIRED =====
  # You (the AI agent) must implement claim extraction logic here.
  # Do NOT write bash code - execute this logic directly in your reasoning.
  #
  # For each claim you identify in FINDING_CONTENT:
  #   1. Extract atomic claim text (preserve hedge words like "may", "suggests")
  #   2. Calculate evidence_confidence using 5-factor formula
  #   3. Calculate claim_quality using 4-dimension framework
  #   4. Calculate final confidence_score = (evidence × 0.6) + (quality × 0.4)
  #   5. Determine flagging based on rules
  #   6. Extract wikilinks using Algorithms 1-5
  #   7. Generate claim entity markdown file in ${CLAIMS_DIR}/data/ directory
  #   8. Update counters and aggregates (below)
  # ===== END AGENT IMPLEMENTATION =====

  # Update counters (bash template continues here)
  claims_created=$((claims_created + 1))

  # Update aggregates with proper floating-point precision (scale=4)
  total_evidence_confidence=$(echo "scale=4; $total_evidence_confidence + 0.82" | bc)
  total_claim_quality=$(echo "scale=4; $total_claim_quality + 0.75" | bc)
  total_confidence=$(echo "scale=4; $total_confidence + 0.79" | bc)

  # Update quality dimensions with proper precision
  total_atomicity=$(echo "scale=4; $total_atomicity + 1.0" | bc)
  total_fluency=$(echo "scale=4; $total_fluency + 0.92" | bc)
  total_decontextualization=$(echo "scale=4; $total_decontextualization + 0.78" | bc)
  total_faithfulness=$(echo "scale=4; $total_faithfulness + 0.88" | bc)
done

log_conditional INFO "Processing complete: $findings_processed findings, $claims_created claims"
```

## Notes

- Always use `scale=4` for bc arithmetic during aggregation
- Use `scale=2` for final averages in JSON output
- **Rounding Strategy:** bc uses standard rounding (round half up): 0.825 → 0.83, 0.824 → 0.82
- Partition-aware log naming enables parallel execution
- Empty array handling: Use `[]` not placeholder `["uuid"]`
- Exit codes: 0 (success), 1 (environment error), 2 (parameter error)
- ISO 8601 timestamps: `$(date -u +"%Y-%m-%dT%H:%M:%SZ")`
- Working directory: Always validated before relative paths used
- Agent threads reset cwd between bash calls - use absolute paths
