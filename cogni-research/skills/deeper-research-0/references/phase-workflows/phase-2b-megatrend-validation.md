# Phase 2b: Megatrend Seed Validation

**Verification Checksum:** `MEGATREND-VALIDATION-V1`

Validate seed megatrends proposed by dimension-planner with user before proceeding to findings creation.

---

## When to Execute

Execute Phase 2b when **ALL conditions** are met:

1. Phase 2 (dimension-planner) completed successfully
2. Research type is `generic` or `smarter-service`
3. `.metadata/seed-megatrends.yaml` exists with `user_validated: false`

**Skip conditions:**

- `lean-canvas` research type (uses fixed canvas blocks)
- `seed-megatrends.yaml` already has `user_validated: true`

---

## Step 1: Load Proposed Seeds

Read the seed megatrends file created by dimension-planner:

```bash
# Re-derive project_path from sprint-log.json location (fresh shell has no variables)
sprint_log="$(find . -path "*/.metadata/sprint-log.json" -type f 2>/dev/null | head -1)"
if [ -z "$sprint_log" ]; then
  echo "ERROR: No sprint-log.json found - cannot determine project path" >&2
  exit 1
fi
project_path="$(cd "$(dirname "$sprint_log")/.." && pwd)"

# Validate the derived path
if [ ! -d "${project_path}/.metadata" ]; then
  echo "ERROR: Invalid project_path: ${project_path}" >&2
  exit 1
fi

SEED_FILE="${project_path}/.metadata/seed-megatrends.yaml"

if [ ! -f "$SEED_FILE" ]; then
  log_conditional WARN "No seed-megatrends.yaml found at: ${SEED_FILE} - skipping Phase 2b"
  # Proceed to Phase 2.5
fi
```

Parse the proposed seeds:

```yaml
# Expected structure from dimension-planner
metadata:
  user_validated: false  # PENDING validation

seed_megatrends:
  - name: "Megatrend Name"
    keywords: [...]
    dimension_affinity: "dimension-slug"
    rationale: "Why this megatrend is relevant"
    planning_horizon_hint: "act|plan|observe"
```

---

## Step 2: Present Seeds to User via AskUserQuestion

Use AskUserQuestion to get user validation:

```json
{
  "questions": [{
    "question": "I've identified {count} seed megatrends for your research based on your question and dimensions. How would you like to proceed?",
    "header": "Megatrends",
    "options": [
      {"label": "Accept all", "description": "Use all {count} proposed seed megatrends as-is"},
      {"label": "Review list", "description": "See the megatrends and decide which to keep"},
      {"label": "Skip seeding", "description": "Proceed without seed megatrends (pure bottom-up clustering)"}
    ],
    "multiSelect": false
  }]
}
```

### Response Handling

**"Accept all":**
1. Update `seed-megatrends.yaml`: Set `user_validated: true` for all seeds
2. Update metadata: Set `user_validated: true`
3. Log: `[INFO] User accepted all {count} seed megatrends`
4. Proceed to Phase 2.5

**"Review list":**
1. Display the seed megatrends table (see Step 3)
2. Enter interactive modification loop

**"Skip seeding":**
1. Update `seed-megatrends.yaml`:
   ```yaml
   metadata:
     user_validated: true
     skip_megatrend_seeding: true
   seed_megatrends: []
   ```
2. Log: `[INFO] User skipped megatrend seeding - bottom-up clustering only`
3. Proceed to Phase 2.5

---

## Step 3: Interactive Review (if "Review list" selected)

Display the proposed megatrends:

```markdown
## Proposed Seed Megatrends

These megatrends will guide megatrend clustering after findings are collected:

| # | Megatrend | Dimension | Horizon | Rationale |
|---|-----------|-----------|---------|-----------|
| 1 | {name} | {dimension_affinity} | {planning_horizon_hint} | {rationale} |
| 2 | ... | ... | ... | ... |

**Planning Horizons:**
- **act** (0-6 months): Immediate action required
- **plan** (6-18 months): Strategic planning phase
- **observe** (18+ months): Monitor and evaluate
```

Then use AskUserQuestion for modifications:

```json
{
  "questions": [{
    "question": "Would you like to modify this list?",
    "header": "Modify",
    "options": [
      {"label": "Keep all", "description": "Accept all megatrends as shown"},
      {"label": "Remove some", "description": "Remove specific megatrends from the list"},
      {"label": "Add custom", "description": "Add your own megatrend to the list"}
    ],
    "multiSelect": false
  }]
}
```

### Modification Loop

**"Remove some":**
- Ask which megatrend(s) to remove by number
- Remove from list, update file

**"Add custom":**
- Ask for megatrend name
- Ask for keywords (comma-separated)
- Ask for dimension affinity (select from existing dimensions)
- Add to list with `proposed_by: "user"`

Continue loop until user selects "Keep all".

---

## Step 4: Write Validated Seeds

Update the seed megatrends file with user validation:

```yaml
# .metadata/seed-megatrends.yaml (after validation)
metadata:
  generated_at: "2025-01-15T14:30:00Z"
  validated_at: "2025-01-15T14:35:00Z"  # Add validation timestamp
  research_question: "{initial question summary}"
  user_validated: true  # NOW VALIDATED
  generator: "dimension-planner:phase-4b"
  validator: "deeper-research-0:phase-2b"

seed_megatrends:
  - name: "Shopfloor Digitalization"
    keywords: [...]
    dimension_affinity: "digitale-wertetreiber"
    validation_mode: "ensure_covered"
    proposed_by: "llm"
    user_validated: true  # User confirmed
    rationale: "..."
    planning_horizon_hint: "act"

  - name: "AI in Manufacturing"
    keywords: [...]
    dimension_affinity: "digitale-wertetreiber"
    validation_mode: "ensure_covered"
    proposed_by: "user"  # User-added
    user_validated: true
    rationale: "User-identified key megatrend"
    planning_horizon_hint: "plan"
```

---

## Step 5: Log Completion

```bash
log_phase "Phase 2b: Megatrend Seed Validation" "complete"
log_conditional INFO "Validated seeds: ${validated_count}"
log_conditional INFO "User additions: ${user_added_count}"
log_conditional INFO "Removed seeds: ${removed_count}"
```

---

## Phase Completion

**Verification checklist:**

- [ ] Seed megatrends file loaded
- [ ] User presented with validation options
- [ ] User validated/modified seed list
- [ ] `seed-megatrends.yaml` updated with `user_validated: true`
- [ ] Validation timestamp added

**Output:**

```text
Phase 2b Complete: Megatrend Seed Validation

Seeds Proposed: {original_count}
Seeds Validated: {final_count}
User Additions: {user_added}
Seeds Removed: {removed}
Output: .metadata/seed-megatrends.yaml (user_validated: true)

-> Phase 2.5: Batch Creation
```

Proceed to Phase 2.5.

---

## Integration with Knowledge-Extractor

The validated `seed-megatrends.yaml` is consumed by `knowledge-extractor` in deeper-research-2:

1. **Phase 5 (Megatrend Clustering):** Load validated seeds
2. **Dual-source synthesis:** Match finding clusters against seeds
3. **Gap detection:** Report unmatched `ensure_covered` seeds
4. **Output:** Megatrends with `source_type` (clustered/seeded/hybrid)

---

**Document Size:** ~3.5KB | **Type:** Execution Instruction | **Complexity:** Medium
**Dependencies:** seed-megatrends.yaml from dimension-planner Phase 4b
