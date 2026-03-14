# Phase 3: Return Metrics

Finalize logging and return JSON metrics to the caller.

---

## Step 3.1: Final Log Entry

**⛔ MANDATORY TOOL CALL** - Use Bash tool:

```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [PHASE] ========== publisher-generator Completed ==========" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [METRIC] sources_processed={SOURCES_PROCESSED}" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [METRIC] publishers_created={PUBLISHERS_CREATED}" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [METRIC] publishers_reused={PUBLISHERS_REUSED}" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

---

## Step 3.2: Validate Metrics Consistency

Before returning, verify these invariants:

```text
SOURCES_PROCESSED == PUBLISHERS_CREATED + PUBLISHERS_REUSED + CREATION_FAILED
```

If this doesn't hold, there's a counting bug. Log a warning but still return metrics.

---

## Step 3.3: Return JSON Response

Return this exact JSON structure (substitute your actual values):

```json
{
  "success": true,
  "sources_processed": {SOURCES_PROCESSED},
  "publishers_created": {PUBLISHERS_CREATED},
  "publishers_reused": {PUBLISHERS_REUSED},
  "publishers_enriched": {PUBLISHERS_ENRICHED},
  "creation_failed": {CREATION_FAILED},
  "enrichment_failed": {ENRICHMENT_FAILED},
  "resolution_mode": "all-sources",
  "failed_items": {FAILED_ITEMS_ARRAY}
}
```

**Example with actual values:**

```json
{
  "success": true,
  "sources_processed": 268,
  "publishers_created": 195,
  "publishers_reused": 65,
  "publishers_enriched": 260,
  "creation_failed": 8,
  "enrichment_failed": 5,
  "resolution_mode": "all-sources",
  "failed_items": [
    {"source": "source-broken-abc123", "stage": "extraction", "reason": "Missing domain field"},
    {"source": "source-failed-def456", "stage": "creation", "reason": "File not created"}
  ]
}
```

---

## Success Criteria

The skill succeeded if:

- `sources_processed` > 0
- `publishers_created` + `publishers_reused` > 0
- Log file contains entries for each processed source

Set `"success": false` only if:

- No sources were found (sources_processed = 0)
- Critical environment error prevented any processing

---

## Anti-Hallucination Final Check

Before returning, answer these questions:

1. Did I actually use Glob to enumerate sources? (Check your tool call history)
2. Did I actually use Read on each source file? (Should have N Read calls for N sources)
3. Did I actually use Bash with create-entity.sh? (Should have M Bash calls for M new publishers)
4. Did I actually use WebSearch for enrichment? (Should have P WebSearch calls for P publishers)
5. Does my log file have real entries? (Use Read tool to verify if uncertain)

**IF ANY ANSWER IS "NO"**: You have NOT completed the skill. Go back and execute the missing steps.

**IF ALL ANSWERS ARE "YES"**: Return the JSON metrics.
