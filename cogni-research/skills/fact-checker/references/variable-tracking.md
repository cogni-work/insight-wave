# Variable Tracking Patterns

Complete patterns for counter initialization, increment, and logging integration in the fact-checker workflow.

## Purpose

These variables track execution state and feed into Phase 6 statistics JSON. The orchestrator consumes these metrics to monitor progress and quality across parallel partitions.

## Counter Categories

### Processing Counters

Track overall workflow progression:

```bash
# Initialize at start of Phase 5
findings_processed=0
claims_created=0
```

### Flagging Counters

Track claims requiring review:

```bash
# Initialize at start of Phase 5
flagged_for_review=0
flagged_by_evidence=0
flagged_by_quality=0
critical_low_confidence=0
```

**Derived Counter:** Non-flagged claims count = `claims_created - flagged_for_review` (calculated in Phase 6)

### Scoring Aggregates

Accumulate scores for average calculations (use integers with bc for decimal precision):

```bash
# Initialize at start of Phase 5 (use bc for decimal operations)
total_evidence_confidence=0
total_claim_quality=0
total_confidence=0
```

### Quality Dimension Aggregates

Track individual quality dimensions:

```bash
# Initialize at start of Phase 5
total_atomicity=0
total_fluency=0
total_decontextualization=0
total_faithfulness=0
```

### Quality Flag Counters

Count specific quality issues:

```bash
# Initialize at start of Phase 5
atomicity_issues=0
decontextualization_issues=0
faithfulness_issues=0
fluency_issues=0
```

## Complete Initialization Pattern

All counters must be initialized at the start of Phase 5. Use this complete pattern for consistency and to prevent unset variable errors in bash arithmetic operations.

```bash
log_phase "Phase 5: Claim Extraction & Verification" "start"

# Processing counters
findings_processed=0
claims_created=0

# Flagging counters
flagged_for_review=0
flagged_by_evidence=0
flagged_by_quality=0
critical_low_confidence=0

# Scoring aggregates
total_evidence_confidence=0
total_claim_quality=0
total_confidence=0

# Quality dimension aggregates
total_atomicity=0
total_fluency=0
total_decontextualization=0
total_faithfulness=0

# Quality flag counters
atomicity_issues=0
decontextualization_issues=0
faithfulness_issues=0
fluency_issues=0

log_conditional "DEBUG" "Counters initialized"
```

## Increment Patterns

### Processing Counter Increments

Update after successful operations:

```bash
# After successfully reading a finding
findings_processed=$((findings_processed + 1))
log_conditional "INFO" "Processing finding ${findings_processed}/${ASSIGNED_COUNT}"
log_metric "findings_processed" "${findings_processed}" "count"

# After successfully creating a claim entity
claims_created=$((claims_created + 1))
log_conditional "INFO" "Claim created: ${claims_created}"
log_metric "claims_created" "${claims_created}" "count"
```

### Scoring Aggregate Increments

Use `bc` for decimal precision:

```bash
# After calculating evidence_confidence for a claim
total_evidence_confidence=$(echo "scale=4; $total_evidence_confidence + $evidence_confidence" | bc)
log_metric "total_evidence_confidence" "${total_evidence_confidence}" "sum"

# After calculating claim_quality for a claim
total_claim_quality=$(echo "scale=4; $total_claim_quality + $claim_quality" | bc)
log_metric "total_claim_quality" "${total_claim_quality}" "sum"

# After calculating final confidence_score for a claim
total_confidence=$(echo "scale=4; $total_confidence + $confidence_score" | bc)
log_metric "total_confidence" "${total_confidence}" "sum"

# Quality dimensions
total_atomicity=$(echo "scale=4; $total_atomicity + $atomicity_score" | bc)
total_fluency=$(echo "scale=4; $total_fluency + $fluency_score" | bc)
total_decontextualization=$(echo "scale=4; $total_decontextualization + $decontextualization_score" | bc)
total_faithfulness=$(echo "scale=4; $total_faithfulness + $faithfulness_score" | bc)
```

### Flagging Counter Increments

Update based on flagging rules:

```bash
# After determining if claim flagged
if [ "$claim_flagged" = "true" ]; then
  flagged_for_review=$((flagged_for_review + 1))
  log_conditional "WARN" "Claim flagged for review (total: ${flagged_for_review})"
  log_metric "flagged_for_review" "${flagged_for_review}" "count"
  
  # Track which layer triggered flag
  if [ "$evidence_layer_flag" = "true" ]; then
    flagged_by_evidence=$((flagged_by_evidence + 1))
    log_metric "flagged_by_evidence" "${flagged_by_evidence}" "count"
  fi
  
  if [ "$quality_layer_flag" = "true" ]; then
    flagged_by_quality=$((flagged_by_quality + 1))
    log_metric "flagged_by_quality" "${flagged_by_quality}" "count"
  fi
fi

# Track critical low confidence
if (( $(echo "$confidence_score < 0.60" | bc -l) )); then
  critical_low_confidence=$((critical_low_confidence + 1))
  log_conditional "ERROR" "Critical low confidence: ${confidence_score}"
  log_metric "critical_low_confidence" "${critical_low_confidence}" "count"
fi
```

### Quality Flag Increments

Track dimension-specific issues:

```bash
# Increment based on quality threshold breaches
# Atomicity and decontextualization are binary (0.0 or 1.0), use equality checks
if (( $(echo "$atomicity_score == 0.0" | bc -l) )); then
  atomicity_issues=$((atomicity_issues + 1))
  log_metric "atomicity_issues" "${atomicity_issues}" "count"
fi

if (( $(echo "$decontextualization_score == 0.0" | bc -l) )); then
  decontextualization_issues=$((decontextualization_issues + 1))
  log_metric "decontextualization_issues" "${decontextualization_issues}" "count"
fi

if (( $(echo "$faithfulness_score < 0.7" | bc -l) )); then
  faithfulness_issues=$((faithfulness_issues + 1))
  log_metric "faithfulness_issues" "${faithfulness_issues}" "count"
fi

if (( $(echo "$fluency_score < 0.5" | bc -l) )); then
  fluency_issues=$((fluency_issues + 1))
  log_metric "fluency_issues" "${fluency_issues}" "count"
fi
```

## Average Calculation Pattern (Phase 6)

Calculate averages with division-by-zero protection:

```bash
log_phase "Phase 6: Statistics Generation" "start"

# Calculate averages using bc for precision
if [ $claims_created -gt 0 ]; then
  avg_evidence_confidence=$(echo "scale=2; $total_evidence_confidence / $claims_created" | bc)
  avg_claim_quality=$(echo "scale=2; $total_claim_quality / $claims_created" | bc)
  avg_confidence=$(echo "scale=2; $total_confidence / $claims_created" | bc)
  
  avg_atomicity=$(echo "scale=2; $total_atomicity / $claims_created" | bc)
  avg_fluency=$(echo "scale=2; $total_fluency / $claims_created" | bc)
  avg_decontextualization=$(echo "scale=2; $total_decontextualization / $claims_created" | bc)
  avg_faithfulness=$(echo "scale=2; $total_faithfulness / $claims_created" | bc)
  
  log_conditional "INFO" "Average evidence confidence: ${avg_evidence_confidence}"
  log_conditional "INFO" "Average claim quality: ${avg_claim_quality}"
  log_conditional "INFO" "Average confidence: ${avg_confidence}"
else
  # Handle division by zero
  avg_evidence_confidence=0
  avg_claim_quality=0
  avg_confidence=0
  avg_atomicity=0
  avg_fluency=0
  avg_decontextualization=0
  avg_faithfulness=0
  
  log_conditional "WARN" "No claims created - averages set to 0"
fi

log_metric "avg_evidence_confidence" "${avg_evidence_confidence}" "average"
log_metric "avg_claim_quality" "${avg_claim_quality}" "average"
log_metric "avg_confidence" "${avg_confidence}" "average"
```

## Variable Summary Table

| Variable | Type | Initialize | Increment When | Used In |
|----------|------|------------|----------------|---------|
| `findings_processed` | int | 0 | After reading finding | Phase 6 stats |
| `claims_created` | int | 0 | After creating claim entity | Phase 6 stats, averages |
| `flagged_for_review` | int | 0 | Claim flagged by any rule | Phase 6 stats |
| `flagged_by_evidence` | int | 0 | Evidence layer flag | Phase 6 stats |
| `flagged_by_quality` | int | 0 | Quality layer flag | Phase 6 stats |
| `critical_low_confidence` | int | 0 | confidence_score < 0.60 | Phase 6 stats |
| `total_evidence_confidence` | decimal | 0 | After scoring claim | Average calculation |
| `total_claim_quality` | decimal | 0 | After scoring claim | Average calculation |
| `total_confidence` | decimal | 0 | After scoring claim | Average calculation |
| `total_atomicity` | decimal | 0 | After dimension eval | Dimension averages |
| `total_fluency` | decimal | 0 | After dimension eval | Dimension averages |
| `total_decontextualization` | decimal | 0 | After dimension eval | Dimension averages |
| `total_faithfulness` | decimal | 0 | After dimension eval | Dimension averages |
| `atomicity_issues` | int | 0 | atomicity_score < 1.0 | Quality breakdown |
| `decontextualization_issues` | int | 0 | decontextualization < 1.0 | Quality breakdown |
| `faithfulness_issues` | int | 0 | faithfulness_score < 0.7 | Quality breakdown |
| `fluency_issues` | int | 0 | fluency_score < 1.0 | Quality breakdown |
| `citations_updated` | int | 0 | After updating citation with claim_ids | Phase 6 stats |
| `citation_backlinks_added` | int | 0 | Total backlinks added to citations | Phase 6 stats |
| `citations_skipped` | int | 0 | Citation not found or already updated | Phase 6 stats |

## Citation Backlink Counters (Phase 5.4)

Track citation backlink update progress (initialized in Phase 5.4, not Phase 5.1):

```bash
# Initialize at start of Phase 5.4
citations_updated=0
citation_backlinks_added=0
citations_skipped=0
```

**Note:** These counters are parallel to megatrend backlink counters in Phase 5.3. Initialize them at the start of Phase 5.4, not with other counters in Phase 5.1.

### Citation Counter Increments

```bash
# After successfully updating citation frontmatter
if grep -q "^claim_ids:" "$citation_path"; then
    citations_updated=$((citations_updated + 1))
    citation_backlinks_added=$((citation_backlinks_added + claim_count))
    log_metric "citations_updated" "$citations_updated" "count"
    log_metric "citation_backlinks_added" "$citation_backlinks_added" "count"
else
    citations_skipped=$((citations_skipped + 1))
    log_metric "citations_skipped" "$citations_skipped" "count"
fi
```

## Common Pitfalls

### Pitfall 1: Integer Arithmetic for Decimals

❌ **Wrong:**
```bash
total_confidence=$(( total_confidence + confidence_score ))  # Truncates to integer
```

✅ **Correct:**
```bash
total_confidence=$(echo "scale=4; $total_confidence + $confidence_score" | bc)
```

### Pitfall 2: Forgetting to Initialize

❌ **Wrong:**
```bash
# No initialization
claims_created=$((claims_created + 1))  # Fails if variable unset
```

✅ **Correct:**
```bash
claims_created=0  # Initialize at Phase 5 start
# ... later
claims_created=$((claims_created + 1))
```

### Pitfall 3: Not Handling Zero Claims

❌ **Wrong:**
```bash
avg_confidence=$(echo "scale=2; $total_confidence / $claims_created" | bc)
# Division by zero if claims_created = 0
```

✅ **Correct:**
```bash
if [ $claims_created -gt 0 ]; then
  avg_confidence=$(echo "scale=2; $total_confidence / $claims_created" | bc)
else
  avg_confidence=0
fi
```

### Pitfall 4: Missing Logging

❌ **Wrong:**
```bash
claims_created=$((claims_created + 1))  # No logging
```

✅ **Correct:**
```bash
claims_created=$((claims_created + 1))
log_conditional "INFO" "Claim created: ${claims_created}"
log_metric "claims_created" "${claims_created}" "count"
```
