# Phase 6: Backlink Update & Response

Update dimension entities with concept and megatrend backlinks, then return JSON execution results.

---

## Entry Gate

Verify Phase 5 artifacts before proceeding:

```bash
# Phase 5 must provide these data structures
test ${#CONCEPTS_BY_DIMENSION[@]} -ge 0  # May be 0 (valid)
test ${#MEGATRENDS_BY_DIMENSION[@]} -ge 0    # May be 0 (valid)
```

**IF tests fail:** Return to Phase 5.

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 6.1: Initialize backlink tracking counters [in_progress]
- Phase 6.2: Update concept backlinks in dimensions [pending]
- Phase 6.3: Update megatrend backlinks in dimensions [pending]
- Phase 6.4: Build and return JSON response [pending]
```

---

## Step 1: Initialize Counters (Script)

```bash
log_phase "Phase 6: Backlink Update" "start"

dimensions_updated=0
backlinks_added=0
```

**Mark 6.1 complete.**

---

## Step 2: Update Concept Backlinks (LLM Reasoning)

For each dimension in `CONCEPTS_BY_DIMENSION`, update frontmatter with concept references.

### 2.1 Iterate Dimensions

```bash
for dimension_file in "${!CONCEPTS_BY_DIMENSION[@]}"; do
  dimension_path="${PROJECT_PATH}/${DIMENSIONS_DIR}/data/${dimension_file}.md"
  concepts_list="${CONCEPTS_BY_DIMENSION[$dimension_file]}"
done
```

### 2.2 Read and Parse (LLM Task)

For each dimension:

1. **Read dimension file** using Read tool
2. **Parse existing frontmatter** - identify current YAML block between `---` markers
3. **Check for existing `concept_ids`** field

### 2.3 Construct Backlink Array (LLM Reasoning)

Build the `concept_ids` YAML array from concepts list:

**Input:** Space-separated concept references (e.g., `"[[${DOMAIN_CONCEPTS_DIR}/data/concept-a]] [[${DOMAIN_CONCEPTS_DIR}/data/concept-b]]"`)

**Output:** YAML array format:

```yaml
concept_ids:
  - "[[${DOMAIN_CONCEPTS_DIR}/data/concept-a]]"
  - "[[${DOMAIN_CONCEPTS_DIR}/data/concept-b]]"
```

**Rules:**

- Preserve existing entries if updating
- Remove duplicates
- Maintain alphabetical order

### 2.4 Edit Frontmatter Safely (LLM Task)

Use **Edit tool** to update dimension file:

1. **If `concept_ids:` exists:** Replace the entire field (line + following array items)
2. **If `concept_ids:` missing:** Insert before closing `---` of frontmatter

**Critical:** Preserve all other frontmatter fields. Do NOT modify content outside frontmatter.

**Example Edit:**

```markdown
# Before
---
dimension_id: dimension-technical
dimension_name: "Technical Architecture"
created_at: "2025-01-15T14:32:00Z"
---

# After
---
dimension_id: dimension-technical
dimension_name: "Technical Architecture"
created_at: "2025-01-15T14:32:00Z"
concept_ids:
  - "[[${DOMAIN_CONCEPTS_DIR}/data/concept-microservices-abc123]]"
  - "[[${DOMAIN_CONCEPTS_DIR}/data/concept-api-design-def456]]"
---
```

### 2.5 Update Counters

```bash
concept_count=$(echo "$concepts_list" | wc -w | tr -d ' ')
backlinks_added=$((backlinks_added + concept_count))
```

**Mark 6.2 complete.**

---

## Step 3: Update Megatrend Backlinks (LLM Reasoning)

For each dimension in `MEGATRENDS_BY_DIMENSION`, update frontmatter with megatrend references.

### 3.1 Iterate Dimensions

```bash
for dimension_file in "${!MEGATRENDS_BY_DIMENSION[@]}"; do
  dimension_path="${PROJECT_PATH}/${DIMENSIONS_DIR}/data/${dimension_file}.md"
  megatrends_list="${MEGATRENDS_BY_DIMENSION[$dimension_file]}"
done
```

### 3.2 Read, Parse, Construct (LLM Tasks)

Apply same pattern as Step 2:

1. Read dimension file
2. Parse frontmatter
3. Construct `megatrend_ids` YAML array
4. Edit safely using Edit tool

**Output format:**

```yaml
megatrend_ids:
  - "[[${MEGATRENDS_DIR}/data/megatrend-performance-abc123]]"
  - "[[${MEGATRENDS_DIR}/data/megatrend-security-def456]]"
```

### 3.3 Update Counters

```bash
megatrend_count=$(echo "$megatrends_list" | wc -w | tr -d ' ')
backlinks_added=$((backlinks_added + megatrend_count))
dimensions_updated=$((dimensions_updated + 1))

log_conditional INFO "Dimensions updated: $dimensions_updated"
log_conditional INFO "Backlinks added: $backlinks_added"
```

**Mark 6.3 complete.**

---

## Step 4: Build JSON Response (LLM Reasoning)

Construct the final response JSON with all execution metrics.

### 4.1 Calculate Timing

```bash
end_time=$(date +%s)
elapsed_seconds=$((end_time - start_time))
```

### 4.2 Assemble Response

Build JSON response with collected metrics:

```json
{
  "success": true,
  "concepts_created": <concepts_created from Phase 4>,
  "megatrends_created": <megatrends_created from Phase 5>,
  "dimensions_updated": <dimensions_updated>,
  "backlinks_added": <backlinks_added>,
  "timing": {
    "elapsed_seconds": <elapsed_seconds>
  }
}
```

### 4.3 Return and Exit

```bash
log_phase "Phase 6: Backlink Update" "complete"
# Output JSON response
exit 0
```

**Mark 6.4 complete.**

---

## Error Response Format

If errors occur during backlink updates:

```json
{
  "success": false,
  "error": "Description of what failed",
  "concepts_created": <count>,
  "megatrends_created": <count>,
  "dimensions_updated": <partial count>,
  "backlinks_added": <partial count>,
  "partial": true
}
```

---

## Self-Verification

Before confirming Phase 6 complete, verify:

1. ✅ Concept backlinks added to relevant dimensions?
2. ✅ Megatrend backlinks added to relevant dimensions?
3. ✅ Frontmatter structure preserved (no YAML corruption)?
4. ✅ JSON response includes all required fields?
5. ✅ Exit code 0 for success?

**⛔ IF ANY NO:** Return to incomplete step.

---

## Phase Completion

**Verification Checklist (5 checks):**

- [ ] `concept_ids` arrays added to dimensions via Edit tool
- [ ] `megatrend_ids` arrays added to dimensions via Edit tool
- [ ] No frontmatter corruption (YAML valid)
- [ ] JSON response complete with all metrics
- [ ] All step-level todos marked complete

**Output:**

```text
Phase 6 Complete: Backlink Update & Response

Backlinks Updated:
- Dimensions updated: {dimensions_updated}
- Concept backlinks: {concept count}
- Megatrend backlinks: {megatrend count}
- Total backlinks: {backlinks_added}

Frontmatter Integrity: ✅ Preserved

Final Response:
{JSON response}

-> Workflow complete. Return response to caller.
```

**Mark Phase 6 complete.** Return JSON response.

---

## Anti-Hallucination Protocol

| Rule | Enforcement |
|------|-------------|
| No fabricated backlinks | Only reference entities created in Phases 4-5 |
| Preserve existing data | Edit tool for safe frontmatter updates |
| Accurate counts | Counters track actual operations |
| Valid JSON | All fields from execution metrics |

**Reference:** [../patterns/anti-hallucination.md](../patterns/anti-hallucination.md)
