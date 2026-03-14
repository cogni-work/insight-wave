# Phase 6: Output & Validation

## Phase Objective

Write trend files to 11-trends/data/, validate all citations reference existing entities, generate index file with summary metrics, and return JSON summary to caller. Abort if validation fails.

---

## ⛔ PHASE ENTRY VERIFICATION (MANDATORY)

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 5 is marked complete. Phase 6 cannot begin until Phase 5 todos are completed.

**THEN verify Phase 5 completion:**

- README files generated in 11-trends/ (entity root directory)
- Phase 5 README generation completed
- Trend entities created with frontmatter (from Phase 4)

**IF MISSING: STOP. Return to Phase 5.**

---

## Step 0.5: Initialize Phase 6 TodoWrite

Add step-level todos for Phase 6:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 6, Step 1: Write trend files to 11-trends/data/ [in_progress]
- Phase 6, Step 2: Validate all citations reference existing entities [pending]
- Phase 6, Step 2.5: Validate quality metadata completeness [pending]
- Phase 6, Step 3: Validate dimension README exists [pending]
- Phase 6, Step 4: Calculate summary metrics [pending]
- Phase 6, Step 5: Return JSON summary to caller [pending]

As you complete each step, mark the corresponding todo as completed.
```

---

## Phase Start

```bash
log_phase "Phase 6: Output & Validation" "start"
```

## Why Validation Matters

**The Problem:**
- LLMs can generate plausible-sounding entity IDs that don't exist
- Trends may reference findings/concepts/megatrends not in the dataset
- Invalid citations break Obsidian graph connectivity
- Fabricated references undermine research integrity
- Shallow trends with low citation counts fail to leverage available evidence

**The Solution:**
- Phase 3: Build complete entity map during loading
- Phase 4: Create trends with citations from loaded entities
- Phase 5: Generate README files with mermaid mindmaps
- Phase 6: Pre-write validation before writing trend files
- Abort if any fabricated entity IDs detected
- Abort if citation coverage too low

---

## Step 1: Write Trend Files

For each trend entity created in Phase 4, write to file system:

```bash
log_conditional INFO "Writing trend files to 11-trends/data/..."

# Iterate through trend entities array
for trend in "${trends[@]}"; do
  # Extract trend metadata
  TITLE=$(echo "$trend" | jq -r '.title')
  SLUG=$(echo "$trend" | jq -r '.slug')
  HASH=$(echo "$trend" | jq -r '.hash')
  CONTENT=$(echo "$trend" | jq -r '.content')

  # Generate filename: trend-{theme-slug}-{6-char-hash}.md
  FILENAME="trend-${SLUG}-${HASH}.md"
  FILEPATH="${PROJECT_PATH}/11-trends/data/${FILENAME}"

  # Use Write tool to create file
  log_conditional INFO "Writing: $FILENAME"

  cat > "$FILEPATH" << EOF
$CONTENT
EOF

  # Track created files
  created_files+=("$FILENAME")
done

log_conditional INFO "Created ${#created_files[@]} trend files"
```

### Filename Pattern

Format: `trend-{theme-slug}-{6-char-hash}.md`

Examples:
- `trend-[a-z]arket-trends-abc123.md`
- `trend-[a-z]echnology-adoption-def456.md`
- `trend-[a-z]egulatory-changes-ghi789.md`

**Hash Generation:**
- Use first 6 characters of SHA-256 hash of title
- Ensures unique filenames for similar titles
- Prevents filename collisions

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate Citations and Claims

For each citation and claim in each trend, validate entity exists and claim minimums are met:

```bash
log_conditional INFO "Validating citations reference existing entities..."

# Extract all citations from trend files
all_citations=""
invalid_citations=""
invalid_citation_details=""

for trend_file in "${created_files[@]}"; do
  FILEPATH="${PROJECT_PATH}/11-trends/data/${trend_file}"

  # Extract citations (wikilinks format: [[entity-id]])
  citations=$(grep -oE '\[\[([^\]]+)\]\]' "$FILEPATH" | sed 's/\[\[\(.*\)\]\]/\1/g')

  # Validate each citation
  for citation in $citations; do
    all_citations="$all_citations $citation"

    # Resolve relative path to full path
    if [ "$citation" == ../04-findings/data/* ]; then
      # Finding citation
      ENTITY_PATH="${PROJECT_PATH}/${citation#../}"
    elif [ "$citation" == ../05-domain-concepts/data/* ]; then
      # Concept citation
      ENTITY_PATH="${PROJECT_PATH}/${citation#../}"
    elif [ "$citation" == ../06-megatrends/data/* ]; then
      # Megatrend citation
      ENTITY_PATH="${PROJECT_PATH}/${citation#../}"
    elif [ "$citation" == ../01-research-dimensions/data/* ]; then
      # Dimension citation
      ENTITY_PATH="${PROJECT_PATH}/${citation#../}"
    else
      # Entity ID format (finding-xyz, concept-abc, etc.)
      # Check entity manifest for existence
      if echo "$entity_manifest" | grep -q "\b$citation\b"; then
        : # Citation found in manifest, continue
      else
        invalid_citations="$invalid_citations $citation"
        invalid_citation_details="$invalid_citation_details\n- $citation (in $trend_file)"
      fi
      continue
    fi

    # Check file exists
    if [ ! -f "$ENTITY_PATH" ]; then
      invalid_citations="$invalid_citations $citation"
      invalid_citation_details="$invalid_citation_details\n- $citation (in $trend_file) → $ENTITY_PATH"
      log_conditional ERROR "Invalid citation: $citation (file not found: $ENTITY_PATH)"
    fi
  done
done

# Count total and invalid citations
total_citations=$(echo "$all_citations" | wc -w | tr -d ' ')
invalid_count=$(echo "$invalid_citations" | wc -w | tr -d ' ')

log_conditional INFO "Total citations: $total_citations"

if [ "$invalid_count" -gt 0 ]; then
  log_conditional ERROR "Invalid citations detected: $invalid_count"
  log_conditional ERROR "Invalid citations:$invalid_citation_details"
  validation_passed=false
else
  log_conditional INFO "All citations valid"
  validation_passed=true
fi
```

### Citation Validation Rules

All citations must reference entities that were loaded in Phase 3:

- **Findings:** `04-findings/data/finding-{slug}-{hash}` (vault-relative, no `../`, no `.md`)
- **Concepts:** `05-domain-concepts/data/concept-{slug}-{hash}`
- **Megatrends:** `06-megatrends/data/megatrend-{slug}-{hash}`
- **Dimensions:** `01-research-dimensions/data/dimension-{slug}`
- **Claims:** `10-claims/data/claim-{slug}-{hash}`

**Entity ID Validation:**
- Extract all `[[entity-id]]` wikilinks from trend content
- Check each entity exists in entity manifest (built in Phase 1.2)
- If entity not found → ABORT with error listing invalid citations

### ⛔ Claim Count Validation (MANDATORY)

**Every trend MUST reference minimum 3 claims.**

```bash
log_conditional INFO "Validating claim count per trend..."

claim_validation_passed=true
trends_below_minimum=()

for trend_file in "${created_files[@]}"; do
  FILEPATH="${PROJECT_PATH}/11-trends/data/${trend_file}"

  # Count claim references (wikilink format without .md extension)
  claim_count_wikilink=$(grep -oE '\[\[10-claims/data/claim-[^\]|]+\|C[0-9]+\]\]' "$FILEPATH" | wc -l | tr -d ' ')
  total_claims=$claim_count_wikilink

  # LAYER 3: File existence validation for claim wikilinks
  claim_ids=$(grep -oE '\[\[10-claims/data/claim-[^]|]+\|C[0-9]+\]\]' "$FILEPATH" | sed -E 's/\[\[10-claims\/data\/([^]|]+)\|.*/\1/')

  for claim_id in $claim_ids; do
    CLAIM_FILE="${PROJECT_PATH}/10-claims/data/${claim_id}.md"
    if [ ! -f "$CLAIM_FILE" ]; then
      log_conditional ERROR "FAKE claim detected in ${trend_file}: ${claim_id}"
      log_conditional ERROR "  File does NOT exist: ${CLAIM_FILE}"
      claim_validation_passed=false
      trends_below_minimum+=("${trend_file}:fake:${claim_id}")
    fi
  done

  if [ $total_claims -lt 3 ]; then
    log_conditional ERROR "Trend ${trend_file} has only ${total_claims} claims (minimum 3 required)"
    claim_validation_passed=false
    trends_below_minimum+=("${trend_file}:${total_claims}")
  else
    log_conditional INFO "Trend ${trend_file}: ${total_claims} claims ✓"
  fi
done

if [ "$claim_validation_passed" = "false" ]; then
  log_conditional ERROR "Claim validation FAILED - trends below 3-claim minimum"
  validation_passed=false
fi
```

**Claim Validation Rules:**

- Minimum 3 claims per trend (MANDATORY)
- Claims must use correct format: `[[10-claims/data/claim-id|CN]]` (wikilink without .md)
- **Claims must exist in 10-claims/data/ directory (verified via file existence check)**
- If <3 claims → ABORT with remediation guidance
- If any claim file does NOT exist → ABORT with fake claim list

**Mark Step 2 todo as completed** before proceeding to Step 2.5.

---

## Step 2.5: Calculate Verification Rate (Optional QA Metric)

**Purpose:** Report verification_rate for quality assurance, mirroring the metric computed by synthesis-dimension.

**Logic:**
1. Count claims by verification_status (derived from flagged_for_review field)
2. verified_count = count(claims where flagged_for_review = false)
3. total_count = all claims referenced by trends
4. verification_rate = verified_count / total_count

**Implementation:**

```bash
log_conditional INFO "Calculating verification rate for QA reporting..."

# Aggregate all unique claim_refs across trends
# Bash 3.2 compatible - indexed array with dedup helper (declare -A requires Bash 4.0+)
UNIQUE_CLAIM_REFS=()

_claim_already_seen() {
  local target="$1"
  for existing in "${UNIQUE_CLAIM_REFS[@]}"; do
    [ "$existing" = "$target" ] && return 0
  done
  return 1
}

for trend_file in "${created_files[@]}"; do
  FILEPATH="${PROJECT_PATH}/11-trends/data/${trend_file}"
  claim_refs=$(grep -A 20 "^claim_refs:" "$FILEPATH" | grep "  - " | sed 's/.*- //' | tr -d '"')
  for claim_ref in $claim_refs; do
    if ! _claim_already_seen "$claim_ref"; then
      UNIQUE_CLAIM_REFS+=("$claim_ref")
    fi
  done
done

total_claims=${#UNIQUE_CLAIM_REFS[@]}
verified_count=0
flagged_count=0

# Check verification status for each unique claim
for claim_id in "${UNIQUE_CLAIM_REFS[@]}"; do
  claim_file="${PROJECT_PATH}/10-claims/data/${claim_id}.md"
  if [ -f "$claim_file" ]; then
    flagged=$(grep 'flagged_for_review:' "$claim_file" | cut -d':' -f2 | tr -d ' ')
    if [ "$flagged" = "false" ] || [ "$flagged" = "False" ]; then
      ((verified_count++))
    else
      ((flagged_count++))
    fi
  fi
done

if [ $total_claims -gt 0 ]; then
  verification_rate=$(echo "scale=2; $verified_count / $total_claims" | bc)
  log_conditional INFO "Verification rate: ${verification_rate} (${verified_count} verified / ${total_claims} total)"
  log_conditional INFO "Flagged claims: ${flagged_count}"
else
  log_conditional WARN "No claims found for verification rate calculation"
  verification_rate="N/A"
fi
```

**Output:** Log verification metrics:
- "Verification rate: 0.82 (45 verified / 55 total)"
- "Flagged claims: 10"

**Note:** This is for QA reporting only. synthesis-dimension computes this independently from claim data during Phase 3 Step 3.3.

**Mark Step 2.5 todo as completed** before proceeding to Step 2.6.

---

## Step 2.6: Validate Quality Metadata Completeness (NEW)

Validate that all quality-related frontmatter fields are populated:

```bash
log_conditional INFO "Validating quality metadata completeness..."

quality_validation_passed=true
incomplete_trends=()

for trend_file in "${created_files[@]}"; do
  FILEPATH="${PROJECT_PATH}/11-trends/data/${trend_file}"

  # Extract frontmatter fields
  planning_horizon=$(grep 'planning_horizon:' "$FILEPATH" | cut -d':' -f2 | tr -d ' "')
  quality_scores=$(grep -A5 'quality_scores:' "$FILEPATH" | head -6)
  quality_rating=$(grep 'quality_rating:' "$FILEPATH" | cut -d':' -f2 | tr -d ' "')
  trend_confidence=$(grep 'trend_confidence:' "$FILEPATH" | cut -d':' -f2 | tr -d ' ')
  confidence_calibration=$(grep 'confidence_calibration:' "$FILEPATH" | cut -d':' -f2 | tr -d ' "')
  evidence_freshness=$(grep 'evidence_freshness:' "$FILEPATH" | cut -d':' -f2 | tr -d ' "')
  oldest_evidence_date=$(grep 'oldest_evidence_date:' "$FILEPATH" | cut -d':' -f2 | tr -d ' "')
  addresses_questions=$(grep 'addresses_questions:' "$FILEPATH" | cut -d':' -f2)

  # Validate planning_horizon
  if [ -z "$planning_horizon" ] || [ "$planning_horizon" = '""' ]; then
    log_conditional ERROR "Trend ${trend_file}: planning_horizon not set (Step 2.5)"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:planning_horizon")
  elif [[ ! "$planning_horizon" =~ ^(act|plan|observe)$ ]]; then
    log_conditional ERROR "Trend ${trend_file}: planning_horizon invalid value '${planning_horizon}' (must be act|plan|observe)"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:planning_horizon_invalid")
  fi

  # Validate quality_scores object has composite > 0
  composite_score=$(echo "$quality_scores" | grep 'composite:' | cut -d':' -f2 | tr -d ' ')
  if [ -z "$composite_score" ] || [ "$composite_score" = "0.0" ]; then
    log_conditional ERROR "Trend ${trend_file}: quality_scores.composite not computed"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:quality_scores")
  fi

  # Validate quality_rating
  if [ -z "$quality_rating" ] || [ "$quality_rating" = '""' ]; then
    log_conditional ERROR "Trend ${trend_file}: quality_rating not set"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:quality_rating")
  fi

  # Validate trend_confidence
  if [ -z "$trend_confidence" ] || [ "$trend_confidence" = "0.0" ]; then
    log_conditional ERROR "Trend ${trend_file}: trend_confidence not computed (Step 5.4)"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:trend_confidence")
  fi

  # Validate confidence_calibration
  if [ -z "$confidence_calibration" ] || [ "$confidence_calibration" = '""' ]; then
    log_conditional ERROR "Trend ${trend_file}: confidence_calibration not set (Step 5.4)"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:confidence_calibration")
  fi

  # Validate evidence_freshness
  if [ -z "$evidence_freshness" ] || [ "$evidence_freshness" = '""' ]; then
    log_conditional ERROR "Trend ${trend_file}: evidence_freshness not assessed (Step 5.5)"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:evidence_freshness")
  fi

  # Validate addresses_questions is not empty
  if [ -z "$addresses_questions" ] || [ "$addresses_questions" = " []" ]; then
    log_conditional ERROR "Trend ${trend_file}: addresses_questions not populated"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:addresses_questions")
  fi

  # Validate Planning Horizon section exists in content
  if ! grep -q "^## Planning Horizon:" "$FILEPATH"; then
    log_conditional ERROR "Trend ${trend_file}: Missing '## Planning Horizon' section in content"
    quality_validation_passed=false
    incomplete_trends+=("${trend_file}:planning_horizon_section")
  fi

  # Log freshness warnings
  if [ "$evidence_freshness" = "dated" ]; then
    log_conditional WARN "Trend ${trend_file}: evidence older than 24 months (evidence_freshness=dated)"
  fi
done

if [ "$quality_validation_passed" = "false" ]; then
  log_conditional ERROR "Quality metadata validation FAILED"
  validation_passed=false
else
  log_conditional INFO "Quality metadata validation PASSED ✓"
fi
```

### Quality Metadata Validation Rules

**Required Fields (MANDATORY):**

| Field | Source Step | Valid Values |
|-------|-------------|--------------|
| `planning_horizon` | Step 2.5 | act, plan, observe |
| `quality_scores.composite` | Step 2.6 | 0.0-1.0 (must be computed) |
| `quality_rating` | Step 2.6 | high, medium, low |
| `trend_confidence` | Step 5.4 | 0.0-1.0 (must be computed) |
| `confidence_calibration` | Step 5.4 | high, moderate, low |
| `evidence_freshness` | Step 5.5 | current, aging, dated |
| `oldest_evidence_date` | Step 5.5 | ISO-8601 date |
| `addresses_questions` | Step 1.2 | Non-empty array of question IDs |

**Freshness Warnings:**

- `evidence_freshness = "dated"` → Log warning (evidence >24 months old)
- `evidence_freshness = "aging"` → No warning, but flag for attention

**Mark Step 2.5 todo as completed** before proceeding to Step 3.

---

## Step 3: Validate Dimension README (BLOCKING)

⛔ **PARALLEL EXECUTION FIX:** Do NOT generate `11-trends/README.md` in individual agents.

Each trends-creator agent validates only its assigned dimension's README with comprehensive checks:

```bash
log_conditional INFO "Validating dimension README..."

# PARALLEL-SAFE: Validate ONLY this agent's assigned dimension README
README_PATH="${PROJECT_PATH}/11-trends/README-${DIMENSION}.md"

# Check 1: File exists
if [ ! -f "${README_PATH}" ]; then
  log_conditional ERROR "BLOCKING: Dimension README not created: ${README_PATH}"
  log_conditional ERROR "Phase 5 Step 0.5.4 failed to generate README-${DIMENSION}.md"
  exit 1
fi

# Check 2: File size > 300 bytes (not empty/stub)
FILE_SIZE=$(wc -c < "${README_PATH}" | tr -d ' ')
if [ "$FILE_SIZE" -lt 300 ]; then
  log_conditional ERROR "BLOCKING: README-${DIMENSION}.md is too small (${FILE_SIZE} bytes, minimum 300)"
  log_conditional ERROR "Return to Phase 5 Step 0.5.4 and regenerate"
  exit 1
fi

# Check 3: Contains mermaid mindmap
if grep -q '```mermaid' "${README_PATH}"; then
  : # Mermaid mindmap found, continue
else
  log_conditional ERROR "BLOCKING: README-${DIMENSION}.md missing mermaid mindmap"
  log_conditional ERROR "Return to Phase 5 Step 0.5.1 and regenerate"
  exit 1
fi

log_conditional INFO "Dimension README validated: README-${DIMENSION}.md ✓"
log_conditional INFO "  - File exists: ✓"
log_conditional INFO "  - File size: ${FILE_SIZE} bytes ✓"
log_conditional INFO "  - Mermaid block: ✓"
log_conditional INFO "Skipping main README.md generation (handled by orchestrator Phase 8.5)"
```

**Validation Checks (BLOCKING):**

| Check | Requirement | Failure Action |
|-------|-------------|----------------|
| File exists | `README-{DIMENSION}.md` present | **STOP. Return to Phase 5 Step 0.5.4.** |
| File size | >300 bytes | **STOP. Return to Phase 5 Step 0.5.4.** |
| Mermaid block | Contains ` ```mermaid ` | **STOP. Return to Phase 5 Step 0.5.1.** |

**Why this change:**

- Main `11-trends/README.md` is generated by orchestrator in Phase 8.5
- Each agent validates only its dimension's README exists AND has valid content
- Prevents N parallel agents from overwriting same file
- Catches empty/incomplete README files before Phase 6 completes

**Mark Step 3 todo as completed** before proceeding to Step 4.

---

## Step 4: Calculate Summary Metrics

Aggregate metrics for JSON response:

```bash
log_conditional INFO "Calculating summary metrics..."

# Calculate metrics object
metrics="{
  \"trends_generated\": ${total_trends},
  \"total_citations\": ${total_citations},
  \"total_words\": ${total_words},
  \"average_citations_per_trend\": $((total_citations / total_trends)),
  \"average_words_per_trend\": $((total_words / total_trends)),
  \"findings_referenced\": ${unique_findings},
  \"findings_total\": ${total_findings},
  \"findings_coverage_percent\": ${findings_coverage_percent},
  \"concepts_referenced\": ${unique_concepts},
  \"megatrends_referenced\": ${unique_megatrends},
  \"validation_passed\": ${validation_passed}
}"

# Log metrics
log_metric "trends_generated" "$total_trends" "count"
log_metric "total_citations" "$total_citations" "count"
log_metric "total_words" "$total_words" "count"
log_metric "findings_coverage" "$findings_coverage_percent" "percent"
log_metric "validation_passed" "$validation_passed" "boolean"
```

### Metrics Tracked

**Core Metrics:**
- `trends_generated`: Count of trend files created
- `total_citations`: Sum of all citations across trends
- `total_words`: Sum of word counts across trends

**Derived Metrics:**
- `average_citations_per_trend`: Total citations / trends
- `average_words_per_trend`: Total words / trends

**Coverage Metrics:**
- `findings_referenced`: Unique findings cited
- `findings_total`: Total findings available
- `findings_coverage_percent`: (Referenced / Total) * 100
- `concepts_referenced`: Unique concepts cited
- `megatrends_referenced`: Unique megatrends cited

**Validation:**
- `validation_passed`: true/false (all citations valid)

**Mark Step 4 todo as completed** before proceeding to Step 5.

---

## Step 5: Return JSON Summary

Return comprehensive summary to caller (wrapper agent):

```bash
log_conditional INFO "Generating JSON summary..."

# Generate JSON response
if [ "$validation_passed" = true ]; then
  cat << EOF
{
  "success": true,
  "trends_directory": "11-trends/data/",
  "trends_generated": ${total_trends},
  "total_citations": ${total_citations},
  "total_words": ${total_words},
  "average_citations_per_trend": $((total_citations / total_trends)),
  "average_words_per_trend": $((total_words / total_trends)),
  "findings_coverage": "${unique_findings}/${total_findings}",
  "findings_coverage_percent": ${findings_coverage_percent},
  "concepts_referenced": ${unique_concepts},
  "megatrends_referenced": ${unique_megatrends},
  "validation_passed": true,
  "files_created": $(printf '%s\n' "${created_files[@]}" | jq -R . | jq -s .),
  "dimension_readme": "11-trends/README-${DIMENSION}.md",
  "timestamp": "${timestamp}"
}
EOF
else
  # Validation failed - return error
  cat << EOF
{
  "success": false,
  "error": "Citation validation failed",
  "invalid_citations": $(echo -e "$invalid_citation_details" | sed '/^$/d' | jq -R . | jq -s .),
  "invalid_count": ${invalid_count},
  "partial_output": "11-trends/data/",
  "files_created": $(printf '%s\n' "${created_files[@]}" | jq -R . | jq -s .),
  "remediation": "Review invalid citations and ensure all referenced entities exist in project directories (04-findings/data/, 05-domain-concepts/data/, 06-megatrends/data/, 01-research-dimensions/data/)"
}
EOF
  exit 1
fi

log_phase "Phase 6: Output & Validation" "complete"
```

### Success Response Format

```json
{
  "success": true,
  "trends_directory": "11-trends/data/",
  "trends_generated": 6,
  "total_citations": 45,
  "total_words": 7200,
  "average_citations_per_trend": 7,
  "average_words_per_trend": 1200,
  "findings_coverage": "38/42",
  "findings_coverage_percent": 90,
  "concepts_referenced": 12,
  "megatrends_referenced": 8,
  "claims_integrated": 24,
  "avg_claims_per_trend": 4,
  "validation_passed": true,
  "quality_validation_passed": true,
  "quality_metrics": {
    "avg_composite_score": 0.78,
    "trends_high_quality": 4,
    "trends_medium_quality": 2,
    "trends_low_quality": 0
  },
  "confidence_metrics": {
    "avg_trend_confidence": 0.82,
    "trends_high_confidence": 3,
    "trends_moderate_confidence": 3,
    "trends_low_confidence": 0
  },
  "freshness_metrics": {
    "trends_current": 5,
    "trends_aging": 1,
    "trends_dated": 0
  },
  "question_traceability": {
    "questions_addressed": 12,
    "questions_total": 15,
    "coverage_percent": 80
  },
  "files_created": [
    "trend-market-trends-abc123.md",
    "trend-technology-adoption-def456.md",
    "trend-regulatory-changes-ghi789.md",
    "trend-competitive-landscape-jkl012.md",
    "trend-innovation-drivers-mno345.md",
    "trend-future-scenarios-pqr678.md"
  ],
  "dimension_readme": "11-trends/README-{dimension}.md",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

**Mark Step 5 todo as completed** after phase completion is logged.

---

## Error Handling

### Validation Failed (Invalid Citations)

**Scenario:** Phase 6 validation detects invalid entity citations

- **Detection:** Citation references entity not in manifest
- **Recovery:** Abort after writing files (partial output)
- **Action:** Return error JSON with list of invalid citations
- **Exit:** 1

**Error JSON Format:**

```json
{
  "success": false,
  "error": "Citation validation failed",
  "invalid_citations": [
    "finding-nonexistent-abc123 (in trend-[a-z]arket-trends-abc123.md) → /path/to/04-findings/data/finding-nonexistent-abc123.md",
    "concept-invalid-def456 (in trend-[a-z]echnology-adoption-def456.md)"
  ],
  "invalid_count": 2,
  "partial_output": "11-trends/data/",
  "files_created": [
    "trend-market-trends-abc123.md",
    "trend-technology-adoption-def456.md"
  ],
  "remediation": "Review invalid citations and ensure all referenced entities exist in project directories (04-findings/data/, 05-domain-concepts/data/, 06-megatrends/data/, 01-research-dimensions/data/)"
}
```

### Insufficient Claim Integration

**Scenario:** Phase 6 validation detects trends with <3 claims

- **Detection:** Claim count per trend < 3 (minimum required)
- **Recovery:** Abort after validation (partial output)
- **Action:** Return error JSON with list of non-compliant trends
- **Exit:** 1

**Error JSON Format:**

```json
{
  "success": false,
  "error": "Insufficient claim integration",
  "trends_below_minimum": [
    "trend-market-trends-abc123.md:2",
    "trend-technology-adoption-def456.md:1"
  ],
  "minimum_required": 3,
  "partial_output": "11-trends/data/",
  "remediation": "Return to Phase 4, Step 2.3 (Claim Allocation) and integrate additional claims. Each trend requires minimum 3 claims with confidence_score >= 0.75."
}
```

### Low Citation Coverage

**Scenario:** Trends created but citation counts too low

- **Detection:** Average citations per trend < 5
- **Recovery:** Proceed with warnings
- **Action:** Include warning in JSON response
- **Exit:** 0 (successful with warnings)

**Success JSON with Warnings:**

```json
{
  "success": true,
  "trends_directory": "11-trends/data/",
  "trends_generated": 6,
  "total_citations": 18,
  "average_citations_per_trend": 3,
  "validation_passed": true,
  "warnings": [
    "Average citations per trend (3) below recommended minimum (5)",
    "Consider increasing evidence integration in trends"
  ]
}
```

---

## Self-Verification Before Completion

**Verify all steps completed:**

1. Did you write all trend files to 11-trends/data/? ✅ YES / ❌ NO
2. Did you validate all citations exist? ✅ YES / ❌ NO
3. Did you validate your dimension's README-{DIMENSION}.md exists? ✅ YES / ❌ NO
4. Did you calculate summary metrics? ✅ YES / ❌ NO
5. Did you return JSON summary? ✅ YES / ❌ NO
6. Does validation_passed == true? ✅ YES / ❌ NO

⛔ **IF ANY NO: STOP.** Return to incomplete step before proceeding.

---

## Phase 6 Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before marking phase complete

Before marking Phase 6 complete in TodoWrite, verify:

- [ ] All trend files written to 11-trends/data/
- [ ] All citations validated against entity manifest
- [ ] Citation validation PASSED (no invalid citations)
- [ ] Claim validation PASSED (3+ claims per trend)
- [ ] Quality metadata validation PASSED (Step 2.5)
- [ ] All quality_scores computed and quality_rating set
- [ ] All trend_confidence computed and confidence_calibration set
- [ ] All evidence_freshness assessed and oldest_evidence_date populated
- [ ] All addresses_questions arrays populated (non-empty)
- [ ] Warnings logged for any trends with evidence_freshness = "dated"
- [ ] Dimension README-{DIMENSION}.md validated (Phase 5 output)
- [ ] Main README.md NOT generated (orchestrator Phase 8.5 responsibility)
- [ ] Summary metrics calculated (including new quality/confidence/freshness metrics)
- [ ] JSON summary returned with all new metric objects
- [ ] All step-level todos marked as completed (including Step 2.5)
- [ ] All self-verification questions answered YES
- [ ] Phase 6 todo marked completed in TodoWrite

---

## Quality Standards

**Anti-Hallucination Verification Checklist:**

Before completing Phase 6, verify:

- [ ] All trend entities created in Phase 4
- [ ] All citations use wikilink format: `[[entity-id]]`
- [ ] All citations validated against entity manifest
- [ ] No fabricated entity IDs detected
- [ ] All trend files have complete frontmatter
- [ ] Index file includes all created trends
- [ ] Metrics accurately reflect trend content
- [ ] JSON summary matches actual output

**If ANY verification fails:** Report error, mark validation_passed = false.

---

## Success Criteria Summary

**Minimum Requirements:**

- [ ] 5-8 trend files created (1050-1300 words each)
- [ ] 30+ total citations across all trends
- [ ] **Minimum 3 claims per trend (MANDATORY)**
- [ ] All citations valid (validation_passed = true)
- [ ] All claim references valid (claim_validation_passed = true)
- [ ] Index file generated with complete metadata
- [ ] JSON summary returned with success: true
- [ ] Average citations per trend ≥ 5 (recommended)
- [ ] Findings coverage ≥ 70% (recommended)

**Quality Metadata Requirements (NEW):**

- [ ] `quality_scores.composite` computed for all trends (≥0.60)
- [ ] `quality_rating` set (high/medium/low)
- [ ] `trend_confidence` computed (Step 5.4)
- [ ] `confidence_calibration` set (high/moderate/low)
- [ ] `evidence_freshness` assessed (Step 5.5)
- [ ] `addresses_questions` populated (non-empty array)
- [ ] All trends passed "So What?" validation (Step 4.3)

**Structural Requirements (NEW):**

- [ ] Tensions & Limitations section present in all trends
- [ ] Implications section has Strategic + Operational subsections
- [ ] Claim quotes include temporal markers (year)

---

## Why This Validation Matters

Trends without evidence grounding = speculation, not analysis.

**The integrity chain:**

1. **Entity manifest** (Phase 1.2): Single source of truth for available entities
2. **Complete loading** (Phase 3): All evidence loaded fully
3. **Evidence-based synthesis** (Phase 4): Grounds all trends in loaded content
4. **README generation** (Phase 5): Creates navigable mindmaps for trends
5. **Citation validation** (Phase 6.2): Catches fabricated references before completion
6. **Coverage analysis** (Phase 6.3-6.4): Ensures comprehensive evidence use
7. **Result:** Trustworthy trends traceable to source material

Trends drive decision-making - hallucinated patterns or invalid citations undermine research integrity.

---

## Recommended Next Steps

After validation passes (`validation_passed = true`):

1. **Proceed to deeper-research-3** for synthesis phases (evidence catalog, dimension synthesis, research hub)
2. **Polish for executives** on individual trend files if needed

---

*End of Phase 6: Output & Validation*
