# Phase 1: Initialization

Validate environment, enumerate source files, and initialize metrics.

---

## Step 1.1: Validate PROJECT_PATH

**⛔ MANDATORY TOOL CALL** - Use Bash tool:

```bash
ls -d "$PROJECT_PATH" && ls -d "$PROJECT_PATH/07-sources/data" && ls -d "$PROJECT_PATH/08-publishers"
```

**If command fails**, return immediately:

```json
{"success": false, "error": "Invalid PROJECT_PATH or missing required directories"}
```

---

## Step 1.2: Create Log Directory

**⛔ MANDATORY TOOL CALL** - Use Bash tool:

```bash
mkdir -p "$PROJECT_PATH/.logs"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [PHASE] ========== publisher-generator Started ==========" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

---

## Step 1.3: Enumerate Source Files

**⛔ MANDATORY TOOL CALL** - Use Glob tool:

```text
Glob: pattern="07-sources/data/source-*.md" path="$PROJECT_PATH"
```

**Store the result** as SOURCE_FILES list (array of file paths).

**Count the files**. If count is 0:

```json
{"success": false, "error": "No source files found", "sources_processed": 0}
```

**Log the count** using Bash tool:

```bash
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Found {COUNT} source files to process" >> "$PROJECT_PATH/.logs/publisher-generator-execution-log.txt"
```

---

## Step 1.4: Initialize Metrics

Set these counters in your working memory:

```text
SOURCES_PROCESSED = 0
PUBLISHERS_CREATED = 0
PUBLISHERS_REUSED = 0
PUBLISHERS_ENRICHED = 0
CREATION_FAILED = 0
ENRICHMENT_FAILED = 0
FAILED_ITEMS = []
TOTAL_SOURCES = {count from Step 1.3}
```

---

## Phase 1 Completion Checklist

Before proceeding to Phase 2, verify:

- [ ] PROJECT_PATH validated (Bash tool executed successfully)
- [ ] Log directory created and initial entry written
- [ ] SOURCE_FILES list populated via Glob tool
- [ ] SOURCE_FILES count > 0
- [ ] All metrics initialized to 0

**IF ANY UNCHECKED**: Stop and fix before continuing.

---

## Proceed to Phase 2

After completing this checklist, proceed to Phase 2: Process Each Source.
