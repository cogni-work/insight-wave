# Metrics Validation Logic

This reference provides detailed guidance for validating metrics consistency before returning results to the orchestrator.

## Overview

The publisher-generator skill tracks multiple metrics counters during processing. Before returning results, it validates a critical invariant to ensure metrics accuracy and detect processing bugs.

## Critical Invariant

**Rule:** The length of `failed_items` array MUST equal the sum of failure counters.

**Formula:**
```
length(failed_items) = creation_failed + enrichment_failed
```

**Rationale:** Every failure should be tracked in both:
1. **Failure counters**: Numeric counters for aggregation
2. **Failed items array**: Detailed failure records for debugging

If these don't match, it indicates a bug in processing logic (forgotten counter increment, duplicate entry, or wrong counter).

## Validation Implementation

### Step 1: Calculate Expected Failures

```bash
# Sum of all failure counters
expected_failures=$((creation_failed + enrichment_failed))
```

**Example:**
- `creation_failed = 2` (2 sources failed to create publishers)
- `enrichment_failed = 3` (3 publishers failed to enrich)
- `expected_failures = 5`

### Step 2: Count Actual Failures

```bash
# Count entries in failed_items array
actual_failures=$(echo "$failed_items" | jq 'length')
```

**Example:**
```json
{
  "failed_items": [
    {"source": "source-abc", "stage": "creation", "reason": "Missing domain"},
    {"source": "source-def", "stage": "creation", "reason": "File not found"},
    {"publisher": "publisher-xyz", "stage": "enrichment", "reason": "Web search failed"},
    {"publisher": "publisher-uvw", "stage": "enrichment", "reason": "Context too short"},
    {"publisher": "publisher-rst", "stage": "enrichment", "reason": "No results"}
  ]
}
```
- `actual_failures = 5` (length of array)

### Step 3: Compare and Validate

```bash
if [ "$expected_failures" -ne "$actual_failures" ]; then
  # Invariant violated - log critical error
  echo "CRITICAL: METRICS INVARIANT VIOLATED" >&2
  echo "Expected $expected_failures failures (creation=$creation_failed + enrichment=$enrichment_failed)" >&2
  echo "Found $actual_failures entries in failed_items array" >&2
  echo "This indicates a bug in processing logic" >&2

  # Add warning to response
  metrics_warning="Metrics invariant violated: expected $expected_failures failures, found $actual_failures in failed_items"
else
  # Invariant satisfied - no warning
  metrics_warning=""
fi
```

## Failure Record Format

**Creation failures:**
```json
{
  "source": "<source_id>",
  "stage": "creation",
  "reason": "<error_message>"
}
```

**Enrichment failures:**
```json
{
  "publisher": "<publisher_id>",
  "stage": "enrichment",
  "reason": "<error_message>"
}
```

**Key differences:**
- Creation failures reference `source` (source file that failed)
- Enrichment failures reference `publisher` (publisher entity that failed)
- Both include `stage` and `reason` for debugging

## Common Violation Scenarios

### Scenario 1: Forgotten Counter Increment

**Bug:**
```
Source fails validation
Add to failed_items: ✓
Increment creation_failed: ✗ (forgotten)
```

**Result:**
- `creation_failed = 0`
- `failed_items.length = 1`
- **Invariant violated:** Expected 0, found 1

### Scenario 2: Duplicate Entry

**Bug:**
```
Publisher enrichment fails
Add to failed_items: ✓
Add to failed_items again (duplicate): ✓
Increment enrichment_failed once: ✓
```

**Result:**
- `enrichment_failed = 1`
- `failed_items.length = 2`
- **Invariant violated:** Expected 1, found 2

### Scenario 3: Wrong Counter

**Bug:**
```
Source validation fails (creation stage)
Add to failed_items with stage="creation": ✓
Increment enrichment_failed (wrong counter): ✗
```

**Result:**
- `creation_failed = 0`, `enrichment_failed = 1`
- `failed_items.length = 1` (correct)
- **Invariant violated:** Expected 1 (0+1), found 1 (matches but for wrong reason)
- **Additional check needed:** Verify failure stages match counters

## Extended Validation (Optional)

**Validate stage distribution:**

```bash
# Count creation failures in failed_items
creation_count=$(echo "$failed_items" | jq '[.[] | select(.stage == "creation")] | length')

# Count enrichment failures in failed_items
enrichment_count=$(echo "$failed_items" | jq '[.[] | select(.stage == "enrichment")] | length')

# Compare with counters
if [ "$creation_count" -ne "$creation_failed" ]; then
  echo "WARNING: Creation stage mismatch: counter=$creation_failed, array=$creation_count" >&2
fi

if [ "$enrichment_count" -ne "$enrichment_failed" ]; then
  echo "WARNING: Enrichment stage mismatch: counter=$enrichment_failed, array=$enrichment_count" >&2
fi
```

**This catches Scenario 3 (wrong counter incremented).**

## Response Handling

### If Invariant Satisfied

**Response (no metrics_warning field):**
```json
{
  "success": true,
  "sources_processed": 20,
  "publishers_created": 18,
  "publishers_reused": 4,
  "publishers_enriched": 20,
  "creation_failed": 2,
  "enrichment_failed": 3,
  "by_type": {
    "individual": 12,
    "organization": 10
  },
  "failed_items": [
    {"source": "source-abc", "stage": "creation", "reason": "Missing domain"},
    {"source": "source-def", "stage": "creation", "reason": "File not found"},
    {"publisher": "publisher-xyz", "stage": "enrichment", "reason": "Web search failed"},
    {"publisher": "publisher-uvw", "stage": "enrichment", "reason": "Context too short"},
    {"publisher": "publisher-rst", "stage": "enrichment", "reason": "No results"}
  ]
}
```

### If Invariant Violated

**Response (includes metrics_warning field):**
```json
{
  "success": true,
  "sources_processed": 20,
  "publishers_created": 18,
  "publishers_reused": 4,
  "publishers_enriched": 20,
  "creation_failed": 2,
  "enrichment_failed": 2,
  "by_type": {
    "individual": 12,
    "organization": 10
  },
  "failed_items": [
    {"source": "source-abc", "stage": "creation", "reason": "Missing domain"},
    {"source": "source-def", "stage": "creation", "reason": "File not found"},
    {"publisher": "publisher-xyz", "stage": "enrichment", "reason": "Web search failed"},
    {"publisher": "publisher-uvw", "stage": "enrichment", "reason": "Context too short"},
    {"publisher": "publisher-rst", "stage": "enrichment", "reason": "No results"}
  ],
  "metrics_warning": "Metrics invariant violated: expected 4 failures (2+2), found 5 in failed_items"
}
```

**Orchestrator should:**
1. Log warning prominently
2. Potentially fail the workflow (indicates skill bug)
3. Use `failed_items` array as source of truth (more detailed)

## Debugging with Metrics Warning

**When metrics_warning is present:**

1. **Check skill execution logs** for counter increment statements
2. **Review failed_items array** for duplicates or unexpected entries
3. **Trace processing flow** for each failure type
4. **Verify error handling** follows pattern: Add to failed_items → Increment counter → Skip

**Common fixes:**
- Add missing counter increment
- Remove duplicate failed_items entry
- Correct counter type (creation vs enrichment)

## Best Practices

### During Processing

**Always follow this pattern for failures:**

```
Step 1: Add detailed record to failed_items array
Step 2: Increment appropriate counter (creation_failed OR enrichment_failed)
Step 3: Skip to next item (continue-on-error)
```

**Example (source validation failure):**
```bash
if [ -z "$domain" ]; then
  # Step 1: Add to failed_items
  failed_items+=('{"source": "'$source_id'", "stage": "creation", "reason": "Missing domain field"}')

  # Step 2: Increment counter
  ((creation_failed++))

  # Step 3: Skip to next source
  continue
fi
```

### Before Returning

**Always validate before constructing final response:**

```bash
# 1. Calculate expected
expected=$((creation_failed + enrichment_failed))

# 2. Count actual
actual=${#failed_items[@]}  # or jq 'length' if using JSON

# 3. Compare
if [ "$expected" -ne "$actual" ]; then
  # Log and add warning
  metrics_warning="Metrics invariant violated: expected $expected, found $actual"
else
  metrics_warning=""  # or omit field
fi

# 4. Construct response with metrics_warning if present
```

## Performance Impact

**Validation overhead:**
- Arithmetic comparison: < 1ms
- Array length check: < 1ms
- Optional stage validation: < 10ms (jq filtering)
- **Total: Negligible** (< 0.1% of total execution time)

**Always enable validation** - the performance cost is trivial compared to the debugging value.

## Integration with Orchestrator

**Orchestrator responsibilities:**

1. **Check metrics_warning field** in each skill response
2. **If present:**
   - Log critical warning with skill instance ID
   - Flag workflow as potentially unreliable
   - Use failed_items array as source of truth
   - Consider failing workflow or alerting developer
3. **If absent:**
   - Trust metrics counters for aggregation
   - Use failed_items for detailed failure reporting

**Aggregation strategy:**
```python
# Orchestrator aggregates results from all skill instances
total_creation_failed = sum(result['creation_failed'] for result in results)
total_enrichment_failed = sum(result['enrichment_failed'] for result in results)
all_failed_items = [item for result in results for item in result['failed_items']]

# Validate aggregated metrics
if len(all_failed_items) != (total_creation_failed + total_enrichment_failed):
  print("CRITICAL: Aggregated metrics invariant violated")
  # Handle error
```

## Summary Checklist

**For skill implementation:**

- [ ] Add to failed_items before incrementing counter
- [ ] Increment exactly one counter per failure (creation_failed OR enrichment_failed)
- [ ] Skip to next item after recording failure
- [ ] Never modify counters or failed_items retroactively
- [ ] Validate invariant before returning response
- [ ] Add metrics_warning field if violation detected
- [ ] Preserve actual data (don't fabricate entries to fix mismatch)

**For orchestrator implementation:**

- [ ] Check for metrics_warning field in all responses
- [ ] Log warnings prominently if present
- [ ] Use failed_items as source of truth when warning present
- [ ] Validate aggregated metrics across all instances
- [ ] Alert developers if metrics violations detected
