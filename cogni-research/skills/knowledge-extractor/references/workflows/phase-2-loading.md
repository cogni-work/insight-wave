# Phase 2: Finding Loading

Load findings, build dimension mappings, and extract finding UUIDs.

---

## ⛔ Entry Gate

```bash
# Verify Phase 1 completed and directory variables are set
if [ ! -f "${PROJECT_PATH}/.logs/knowledge-extractor-execution-log.txt" ]; then
  echo "Phase 1 incomplete" >&2
  exit 1
fi

if [ -z "${FINDINGS_DIR:-}" ]; then
  echo "FINDINGS_DIR not set - run Phase 1 directory resolution" >&2
  exit 1
fi

# === MANDATORY: Verify directories exist (prevents path hallucination) ===
for dir_var in DIMENSIONS_DIR FINDINGS_DIR DOMAIN_CONCEPTS_DIR MEGATRENDS_DIR; do
    eval "dir_value=\${${dir_var}:-}"
    if [ -z "$dir_value" ]; then
        echo "ERROR: ${dir_var} not set - run Phase 1 directory resolution" >&2
        exit 1
    fi
    if [ ! -d "${PROJECT_PATH}/${dir_value}" ]; then
        echo "ERROR: Directory not found: ${PROJECT_PATH}/${dir_value}" >&2
        echo "Resolved from ${dir_var}=${dir_value}" >&2
        echo "Run 'ls -d ${PROJECT_PATH}/[0-9][0-9]-*/' to see actual directories" >&2
        exit 1
    fi
done
log_conditional INFO "Directory existence verified for all entity types"
```

**CRITICAL:** If any directory check fails, the path may be hallucinated. Return to Phase 1 Step 4 to see actual directory names.

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 2.1: List findings [in_progress]
- Phase 2.2: Early exit check [pending]
- Phase 2.3: Build dimension mapping [pending]
- Phase 2.3.5: Dimension filtering (if --dimension set) [pending]
- Phase 2.4: Extract UUIDs [pending]
```

---

## Step 1: List Findings

```bash
log_phase "Phase 2: Finding Loading" "start"

findings_list=()
for f in "${PROJECT_PATH}"/${FINDINGS_DIR}/data/*.md; do
  [ -f "$f" ] && findings_list+=("$f")
done
findings_count=${#findings_list[@]}

log_conditional INFO "Found $findings_count findings"
```

**Mark 2.1 complete.**

---

## Step 2: Early Exit

```bash
if [ $findings_count -lt 2 ]; then
  log_conditional INFO "Fewer than 2 findings - exiting"
  echo '{"success": true, "concepts_created": 0, "megatrends_created": 0, "message": "Insufficient findings"}'
  exit 0
fi
```

**Mark 2.2 complete.**

---

## Step 3: Dimension Mapping

Build `FINDING_TO_DIMENSION` mapping by traversing wikilink references.

**Chain:** finding → batch_ref → question_ref → dimension_ref

**LLM Execution:** For each finding file:

1. Read finding, extract `batch_ref: [[path/batch-file]]` from frontmatter
2. Read batch file at `${QUERY_BATCHES_DIR}/data/{batch-file}.md`, extract `question_ref`
3. Read question file at `${REFINED_QUESTIONS_DIR}/data/{question-file}.md`, extract `dimension_ref`
4. Store mapping: `finding_file → dimension_wikilink`

**Cache:** Store `batch → dimension` mappings to avoid re-reading batch/question files.

**Output structure:**

```json
FINDING_TO_DIMENSION = {
  "/path/finding-1.md": "[[${DIMENSIONS_DIR}/data/dimension-a]]",
  "/path/finding-2.md": "[[${DIMENSIONS_DIR}/data/dimension-b]]",
  ...
}
```

**Log:**
```bash
log_conditional INFO "Mapped ${mapped_count} findings to dimensions"
```

**Mark 2.3 complete.**

---

## Step 3.5: Dimension Filtering (Conditional)

**Condition:** If `--dimension` parameter is provided, filter findings to only those belonging to the specified dimension.

**When to use:** During parallel dimension-based extraction, each agent processes only its assigned dimension's findings.

```bash
if [ -n "$DIMENSION_FILTER" ]; then
  log_conditional INFO "Applying dimension filter: $DIMENSION_FILTER"

  # Build filtered findings list
  filtered_findings=()
  filtered_count=0

  for finding_file in "${findings_list[@]}"; do
    dim_ref="${FINDING_TO_DIMENSION[$finding_file]}"
    # Extract dimension slug from wikilink: [[${DIMENSIONS_DIR}/data/dimension-xyz-abc123]]
    dim_slug=$(echo "$dim_ref" | sed "s/.*\[\[${DIMENSIONS_DIR}\///" | sed 's/\]\]$//')

    if [ "$dim_slug" = "$DIMENSION_FILTER" ]; then
      filtered_findings+=("$finding_file")
      filtered_count=$((filtered_count + 1))
    fi
  done

  # Replace findings_list with filtered version
  findings_list=("${filtered_findings[@]}")
  findings_count=${#findings_list[@]}

  log_conditional INFO "Filtered to $findings_count findings for dimension: $DIMENSION_FILTER"

  # Early exit if no findings for this dimension
  if [ $findings_count -eq 0 ]; then
    log_conditional INFO "No findings for dimension $DIMENSION_FILTER - returning empty result"
    echo "{\"success\": true, \"mode\": \"concepts-only\", \"dimension\": \"$DIMENSION_FILTER\", \"concepts_created\": 0, \"message\": \"No findings for dimension\"}"
    exit 0
  fi
fi
```

**Note:** This step is skipped if `--dimension` is not provided (full corpus processing mode).

**Mark 2.3.5 complete (if applicable).**

---

## Step 4: Extract UUIDs

Extract 8-character hash from finding filenames.

**Pattern:** `finding-{slug}-{hash}.md` → extract `{hash}`

```bash
# Example: finding-market-trends-a1b2c3d4.md → a1b2c3d4
for finding_file in "${findings_list[@]}"; do
  filename=$(basename "$finding_file" .md)
  uuid="${filename##*-}"  # Last segment after final hyphen
  FINDING_UUIDS["$finding_file"]="$uuid"
done

log_phase "Phase 2: Finding Loading" "complete"
```

**Mark 2.4 complete.**

---

## Phase 2 Verification

| Check | Status |
|-------|--------|
| findings_list populated (≥2) | |
| FINDING_TO_DIMENSION built | |
| Dimension filtering applied (if `--dimension` set) | |
| FINDING_UUIDS extracted | |
| All step todos completed | |

⛔ **All checks must pass before Phase 3.**

---

## Phase 2 Output

```text
✅ Phase 2 Complete

Findings: {findings_count}
Mapped: {FINDING_TO_DIMENSION count}
UUIDs: {FINDING_UUIDS count}
Dimension Filter: {DIMENSION_FILTER or "none (full corpus)"}

Data structures ready:
- findings_list[]
- FINDING_TO_DIMENSION{}
- FINDING_UUIDS{}

→ Phase 3: Term Analysis
```

**Mark Phase 2 complete in TodoWrite.**
