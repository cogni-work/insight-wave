# Phase 2: Concept Deduplication

Merge duplicate concepts created across parallel dimension extractions using robust Python-based deduplication.

---

## ⛔ Entry Gate

```bash
if [ ! -f "${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt" ]; then
  echo "Phase 1 incomplete" >&2
  exit 1
fi
```

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 2.1: Run concept deduplication script [in_progress]
- Phase 2.2: Verify deduplication results [pending]
```

---

## Step 1: Run Deduplication Script

Execute the Python deduplication script which handles:

1. Scanning all `concept-*.md` files
2. Normalizing concept names for comparison
3. Grouping duplicates by normalized name
4. Merging `finding_refs` from all duplicates into keeper
5. Deleting non-keeper files

```bash
# Log phase start
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 2: Concept Deduplication: start" >> "$LOG_FILE"

# Find plugin scripts directory
PLUGIN_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts"

# Run deduplication
DEDUPE_RESULT=$(python3 "${PLUGIN_SCRIPTS}/deduplicate-concepts.py" \
  --project-path "${PROJECT_PATH}" \
  --json 2>&1)

# Parse result
DEDUPE_SUCCESS=$(echo "$DEDUPE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success', False))")

if [ "$DEDUPE_SUCCESS" != "True" ]; then
  DEDUPE_ERROR=$(echo "$DEDUPE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error', 'Unknown error'))")
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [ERROR] Deduplication failed: $DEDUPE_ERROR" >> "$LOG_FILE"
  echo "ERROR: $DEDUPE_ERROR" >&2
  exit 1
fi

# Extract metrics
concepts_before=$(echo "$DEDUPE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('concepts_before', 0))")
concepts_after=$(echo "$DEDUPE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('concepts_after', 0))")
duplicate_groups=$(echo "$DEDUPE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('duplicate_groups', 0))")
deleted_count=$(echo "$DEDUPE_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('deleted_files', [])))")

# Log results
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Found $concepts_before concepts" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Found $duplicate_groups duplicate groups" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Deleted $deleted_count duplicate files" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Deduplication complete: $concepts_before → $concepts_after concepts" >> "$LOG_FILE"
```

**Mark 2.1 complete.**

---

## Step 2: Verify Results

Verify the deduplication completed successfully:

```bash
# Verify concepts directory exists and has files
concepts_dir="${PROJECT_PATH}/05-domain-concepts/data"
if [ ! -d "$concepts_dir" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [ERROR] Concepts directory not found" >> "$LOG_FILE"
  exit 1
fi

# Count remaining concepts
final_count=$(find "$concepts_dir" -maxdepth 1 -name "concept-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Verified $final_count concepts after deduplication" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 2: Concept Deduplication: complete" >> "$LOG_FILE"

echo "concepts_after=${final_count}"
echo "duplicate_groups=${duplicate_groups}"
```

**Mark 2.2 complete.**

---

## Phase 2 Verification

| Check | Status |
|-------|--------|
| Deduplication script ran successfully | |
| No error messages in output | |
| Concept count reduced (if duplicates existed) | |
| All step todos completed | |

⛔ **All checks must pass before Phase 3.**

---

## Phase 2 Output

```text
✅ Phase 2 Complete

Concepts before: {concepts_before}
Concepts after: {concepts_after}
Duplicate groups: {duplicate_groups}
Files deleted: {deleted_count}

→ Phase 3: Megatrend Clustering
```

**Mark Phase 2 complete in TodoWrite.**
