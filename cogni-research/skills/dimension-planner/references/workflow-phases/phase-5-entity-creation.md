# Phase 5: Entity Creation

**Reference Checksum:** `sha256:v3.0`

**Verification Protocol:** After reading, confirm: `Reference Loaded: phase-5-entity-creation.md | Checksum: v3.0`

---

## Objective

Generate ALL dimensions and questions in a single JSON structure with extended thinking, then unpack to markdown files via batch script.

| Workload | Dimensions | Questions | Time | Tool Calls |
|----------|------------|-----------|------|------------|
| DOK-1 (generic) | 2-3 | 8-12 | 10-12s | 3 |
| DOK-2 (generic) | 3-4 | 15-20 | 12-15s | 3 |
| DOK-3 (generic) | 5-7 | 25-35 | 18-22s | 3 |
| DOK-4 (generic) | 8-10 | 40-50 | 30-40s | 3 |
| **smarter-service** | **4** | **52** | 30-40s | 3 |
| **b2b-ict-portfolio** | **8** | **57-71** | 35-45s | 3 |
| **Max** | ≤9 | ≤71 | - | - |

⛔ **b2b-ict-portfolio Note:** This research type requires **minimum 57 questions** (one per taxonomy category, 8 dimensions 0-7). The schema enforces this via conditional validation.

⛔ **b2b-ict-portfolio Dimension Numbering:** For this research type, `dimension_number` MUST start at **0** (not 1):
- Dimension 0: `provider-profile-metrics` (6 categories: 0.1-0.6)
- Dimensions 1-7: Service dimensions (connectivity, security, workplace, cloud, infrastructure, application, consulting)

⛔ **smarter-service Note:** This research type requires **exactly 52 questions** (4 dimensions × (5 ACT + 5 PLAN + 3 OBSERVE) = 13 questions per dimension). With this question count, single-batch generation is possible.

---

## Prerequisites

**From Phase 4:** SELECTED_DIMENSIONS, PICOT_QUESTIONS, FINER_SCORES, QUALITY_PLAN, INITIAL_QUESTION entity ID

**Environment:** PROJECT_LANGUAGE from `.metadata/sprint-log.json`, directories (`dimensions/`, `questions/`, `.metadata/`), scripts (`scripts/unpack-dimension-plan-batch.sh`, `scripts/verify-phase5-completion.sh`), `jq` installed

---

## Workflow Overview

```
Phase 5.0: Pre-Flight Validation (BLOCKING)
Phase 5.0.5: Research Type Routing
  ├─ generic/b2b-ict-portfolio → Phase 5.1 (single batch)
  └─ smarter-service → Phase 5.1-B (dimension batching)
Phase 5.1: Generate Batched JSON (Extended Thinking) [≤40 questions]
Phase 5.1-B: Batched Generation - smarter-service [52 questions]
Phase 5.1.5: Merge Dimension Batches (smarter-service only)
Phase 5.2: Unpack Batch to Markdown Files
Phase 5.2.5: Generate Provenance READMEs (automatic in script)
Phase 5.3: Final Completion Verification (BLOCKING)
Phase 5.4: Return Success JSON
```

**Universal Error Rule:** IF any validation fails in any phase → STOP immediately, output error JSON, exit with appropriate code.

---

## Phase 5.0: Pre-Flight Validation

⛔ **BLOCKING:** Verify environment and Phase 4b completion before entity creation.

### 5.0.1: Environment Checks

```bash
if [ ! -f "scripts/unpack-dimension-plan-batch.sh" ]; then exit 2; fi
if [ ! -f "scripts/verify-phase5-completion.sh" ]; then exit 2; fi
if [ -z "$PROJECT_PATH" ] || [ ! -d "$PROJECT_PATH" ]; then exit 2; fi
mkdir -p "${PROJECT_PATH}/.metadata"
command -v jq >/dev/null 2>&1 || exit 2
```

### 5.0.2: Phase 4b Verification (generic/smarter-service only)

⛔ **GATE CHECK:** For `generic` and `smarter-service` research types, Phase 4b MUST have been executed.

```bash
# Validate PROJECT_PATH to prevent empty path errors
if [[ -z "${PROJECT_PATH:-}" ]]; then
  echo "ERROR: PROJECT_PATH is not set - cannot verify Phase 4b" >&2
  exit 1
fi

# Phase 4b gate check - only for research types that require megatrend seeding
case "$RESEARCH_TYPE" in
  generic|smarter-service)
    SEED_FILE="${PROJECT_PATH}/.metadata/seed-megatrends.yaml"
    if [ ! -f "$SEED_FILE" ]; then
      log_conditional ERROR "Phase 4b was not executed: seed-megatrends.yaml missing"
      log_conditional ERROR "Return to Phase 4 and execute Phase 4b before proceeding"
      exit 1
    fi
    log_conditional INFO "Phase 4b verified: seed-megatrends.yaml exists"
    ;;
  lean-canvas|b2b-ict-portfolio)
    log_conditional INFO "Phase 4b verification skipped (not applicable for ${RESEARCH_TYPE})"
    ;;
esac
```

**Why this gate exists:** Phase 4b generates `seed-megatrends.yaml` which is consumed by `knowledge-extractor` Phase 5 for dual-source megatrend clustering.

**Note:** The seeds file may have `user_validated: false` at this point - user validation happens later in deeper-research-0 Phase 2b (the orchestrating skill can use AskUserQuestion, dimension-planner as a sub-agent cannot).

---

## Phase 5.0.5: Research Type Routing

Detect research type and route to appropriate generation strategy based on output token constraints.

```bash
# Get research type from Phase 4 context
RESEARCH_TYPE="${RESEARCH_TYPE:-generic}"

if [ "$RESEARCH_TYPE" == "smarter-service" ]; then
  log_conditional INFO "Phase 5.0.5: Routing to Phase 5.1-B (generation for 52 questions)"
  # Continue to Phase 5.1-B
else
  log_conditional INFO "Phase 5.0.5: Routing to Phase 5.1 (single batch generation)"
  # Continue to Phase 5.1
fi
```

| Research Type | Questions | Strategy | Reason |
|---------------|-----------|----------|--------|
| generic | ≤40 | Phase 5.1 (single) | Within token limits |
| b2b-ict-portfolio | 51-65 | Phase 5.1 (single) | Optimized fields, within limits |
| **smarter-service** | **52** | **Phase 5.1-B** | **Rich TIPS fields, within token limits** |

---

## Phase 5.1: Generate Batched JSON

### Step 1: Extended Thinking

Load context: `total_dimensions`, `total_questions`, `project_language`, `initial_question_entity_id` (from YAML frontmatter `dc:identifier`).

Use extended thinking to validate schema structure BEFORE generating JSON. Focus on checklist verification, not verbose templates.

### Step 2: Generate JSON

⛔ **CRITICAL SCHEMA RULES:**

| Rule | ✅ Correct | ❌ Wrong |
|------|-----------|----------|
| Dimension key | `"dimension": {...}` | `"dimension_entity": {...}` |
| Question fields | Direct in array: `questions[i].title` | Wrapped: `questions[i].question_entity.title` |
| FINER keys | `"feasible", "interesting", "novel", "ethical", "relevant"` | `"F", "I", "N", "E", "R"` |
| Source | `dimension-plan-batch.schema.json` | `dimensions.md` (planning template only) |

**Canonical JSON Structure:**

```json
{
  "metadata": {
    "project_language": "en",
    "initial_question_entity_id": "question-{slug}-{hash8}",
    "total_dimensions": 4,
    "total_questions": 16,
    "research_type": "smarter-service"
  },
  "dimensions": [
    {
      "dimension_number": 1,
      "dimension_slug": "customer-analysis",
      "dimension": {
        "title": "Customer Analysis",
        "entity_id": "dimension-customer-analysis-{hash8}",
        "description": "...",
        "scope": "...",
        "rationale": "...",
        "question_count": 4
      },
      "questions": [
        {
          "title": "Retention Strategies",
          "entity_id": "question-retention-strategies-{hash8}",
          "question_text": "...",
          "rationale": "...",
          "picot_structure": {
            "population": "...",
            "intervention": "...",
            "comparison": "...",
            "outcome": "...",
            "timeframe": "..."
          },
          "finer_scores": {
            "feasible": 3,
            "interesting": 3,
            "novel": 2,
            "ethical": 3,
            "relevant": 3,
            "total": 14
          },
          "action_horizon": {
            "horizon": "act",
            "justification": "Regulation deadline 2024-08, immediate compliance required",
            "timeframe": "0-2 years"
          },
          "trend_velocity": {
            "velocity": "accelerating",
            "momentum_indicator": "67% YoY adoption increase",
            "evidence_type": "quantitative"
          },
          "cross_dimensional_links": [
            {
              "target_dimension": "neue-horizonte",
              "link_type": "causal",
              "tips_flow": "T→P",
              "evidence": "External regulation drives strategic response"
            }
          ],
          "case_study_requirement": {
            "requirement_level": "required",
            "count": "3-5",
            "tips_role": "S"
          }
        }
      ]
    }
  ]
}
```

⛔ **Note:** The `action_horizon`, `trend_velocity`, `cross_dimensional_links`, and `case_study_requirement` fields are **optional** but **mandatory for smarter-service research type**. They enable high-quality TIPS output.

### Step 3: Validate JSON

```bash
echo '{json}' | jq -e '.' > /dev/null || exit 1
# Verify structure: dimension key exists, question fields direct, FINER lowercase
planned_dims=$(echo '{json}' | jq -r '.metadata.total_dimensions')
actual_dims=$(echo '{json}' | jq -r '.dimensions | length')
if [ "$planned_dims" -ne "$actual_dims" ]; then exit 1; fi

# ⛔ B2B-ICT-PORTFOLIO SPECIFIC VALIDATION
research_type=$(echo '{json}' | jq -r '.metadata.research_type')
if [ "$research_type" == "b2b-ict-portfolio" ]; then
  total_questions=$(echo '{json}' | jq -r '.metadata.total_questions')

  # Verify minimum 57 questions (all taxonomy categories, 8 dimensions 0-7)
  if [ "$total_questions" -lt 57 ]; then
    log_conditional ERROR "b2b-ict-portfolio requires minimum 57 questions (one per taxonomy category, 8 dimensions 0-7)"
    log_conditional ERROR "Generated: $total_questions | Required: ≥57"
    exit 1
  fi

  # Verify ALL questions have portfolio_category
  missing_categories=$(echo '{json}' | jq '[.dimensions[].questions[] | select(.portfolio_category == null)] | length')
  if [ "$missing_categories" -gt 0 ]; then
    log_conditional ERROR "$missing_categories questions missing required portfolio_category field"
    exit 1
  fi

  # Verify all 57 category IDs are present (no duplicates, no gaps)
  unique_categories=$(echo '{json}' | jq '[.dimensions[].questions[].portfolio_category.category_id] | unique | length')
  if [ "$unique_categories" -lt 57 ]; then
    log_conditional ERROR "Not all 57 taxonomy categories covered: only $unique_categories unique categories found"
    exit 1
  fi

  log_conditional INFO "✓ b2b-ict-portfolio validation passed: $total_questions questions covering $unique_categories categories"
fi
```

### Step 4: Write JSON

**Tool:** Write → `${PROJECT_PATH}/.metadata/dimension-plan-batch.json`

Verify file exists and valid JSON after write.

**After Phase 5.1 completes:** Skip to Phase 5.2.

---

## Phase 5.1-B: Batched Generation (smarter-service)

⛔ **SMARTER-SERVICE ONLY:** This phase replaces Phase 5.1 for smarter-service research type to avoid output token limits.

**Token Budget:** 52 questions × ~660 tokens/question = ~34K tokens (within limit)

**Note:** With 52 questions, single-batch generation is possible. Dimension batching (4 batches of 13 questions) is optional but available if needed.

### Step 1: Initialize Batch Loop

```bash
SMARTER_SERVICE_DIMENSIONS=(
  "externe-effekte"
  "neue-horizonte"
  "digitale-wertetreiber"
  "digitales-fundament"
)
BATCH_FILES=()
```

### Step 2: Generate Dimension Batches (Loop 4×)

For each dimension in SMARTER_SERVICE_DIMENSIONS:

#### 2.1: Extended Thinking (Per Dimension)

<thinking>
**Dimension Batch {N}/4: {dimension_slug}**

Generating 13 questions for this dimension:
- Action horizons: 5 act, 5 plan, 3 observe
- All TIPS fields required: action_horizon, trend_velocity, cross_dimensional_links, case_study_requirement

Schema checklist:
- [ ] dimension key (not dimension_entity)
- [ ] questions array direct (not wrapped)
- [ ] FINER keys lowercase
- [ ] All smarter-service fields present
</thinking>

#### 2.2: Generate Partial JSON

Generate JSON with single dimension (13 questions):

```json
{
  "metadata": {
    "project_language": "de",
    "initial_question_entity_id": "question-{slug}-{hash8}",
    "total_dimensions": 1,
    "total_questions": 13,
    "research_type": "smarter-service",
    "batch_number": 1,
    "batch_dimension": "externe-effekte"
  },
  "dimensions": [
    {
      "dimension_number": 1,
      "dimension_slug": "externe-effekte",
      "dimension": { ... },
      "questions": [ /* 13 questions with all TIPS fields */ ]
    }
  ]
}
```

#### 2.3: Validate & Write Batch

```bash
# Validate JSON syntax
echo '{json}' | jq -e '.' > /dev/null || exit 1

# Verify 13 questions
question_count=$(echo '{json}' | jq '[.dimensions[].questions[]] | length')
if [ "$question_count" -ne 13 ]; then exit 1; fi

# Verify all TIPS fields present
missing_fields=$(echo '{json}' | jq '[.dimensions[].questions[] | select(.action_horizon == null or .trend_velocity == null)] | length')
if [ "$missing_fields" -gt 0 ]; then exit 1; fi

# Write batch file
BATCH_FILE="${PROJECT_PATH}/.metadata/dimension-batch-${batch_number}.json"
# Tool: Write → $BATCH_FILE
BATCH_FILES+=("$BATCH_FILE")

log_conditional INFO "Phase 5.1-B: Batch ${batch_number}/4 complete: ${dimension_slug} (13 questions)"
```

### Step 3: Verify All Batches

```bash
if [ ${#BATCH_FILES[@]} -ne 4 ]; then exit 1; fi
for batch_file in "${BATCH_FILES[@]}"; do
  if [ ! -f "$batch_file" ]; then exit 1; fi
done
log_conditional INFO "Phase 5.1-B: All 4 dimension batches generated"
```

**After Phase 5.1-B completes:** Continue to Phase 5.1.5.

---

## Phase 5.1.5: Merge Dimension Batches

⛔ **SMARTER-SERVICE ONLY:** Merge 4 dimension batch files into single `dimension-plan-batch.json`.

### Step 1: Merge Batches with jq

```bash
jq -s '{
  metadata: {
    project_language: .[0].metadata.project_language,
    initial_question_entity_id: .[0].metadata.initial_question_entity_id,
    total_dimensions: 4,
    total_questions: 52,
    research_type: "smarter-service"
  },
  dimensions: [.[].dimensions[]] | sort_by(.dimension_number)
}' \
  "${PROJECT_PATH}/.metadata/dimension-batch-1.json" \
  "${PROJECT_PATH}/.metadata/dimension-batch-2.json" \
  "${PROJECT_PATH}/.metadata/dimension-batch-3.json" \
  "${PROJECT_PATH}/.metadata/dimension-batch-4.json" \
  > "${PROJECT_PATH}/.metadata/dimension-plan-batch.json"
```

### Step 2: Validate Merged JSON

```bash
merged_file="${PROJECT_PATH}/.metadata/dimension-plan-batch.json"

# Verify valid JSON
jq -e '.' "$merged_file" > /dev/null || exit 1

# Verify counts
dims=$(jq '.dimensions | length' "$merged_file")
questions=$(jq '[.dimensions[].questions[]] | length' "$merged_file")

if [ "$dims" -ne 4 ]; then exit 1; fi
if [ "$questions" -ne 52 ]; then exit 1; fi

log_conditional INFO "Phase 5.1.5: Merged JSON validated (4 dimensions, 52 questions)"
```

### Step 3: Cleanup Batch Files

```bash
rm -f "${PROJECT_PATH}/.metadata/dimension-batch-"*.json
log_conditional INFO "Phase 5.1.5: Temporary batch files cleaned up"
```

**After Phase 5.1.5 completes:** Continue to Phase 5.2.

---

## Phase 5.2: Unpack Batch to Markdown

### Step 1: Call Script

```bash
bash scripts/unpack-dimension-plan-batch.sh \
  --json-file "$json_file" \
  --project-path "$PROJECT_PATH" \
  --validate-schema true \
  --json
```

**Exit Codes:** 0=Success | 1=Schema failure | 2=Invalid params | 3=Write failure | 4=Count mismatch

### Step 2: Verify & Parse Results

```bash
dimensions_created=$(echo "$unpack_result" | jq -r '.data.dimensions_created')
questions_created=$(echo "$unpack_result" | jq -r '.data.questions_created')
dimensions_readme=$(echo "$unpack_result" | jq -r '.data.readmes_created.dimensions_readme')
questions_readme=$(echo "$unpack_result" | jq -r '.data.readmes_created.refined_questions_readme')
if [ $dimensions_created -ne ${#SELECTED_DIMENSIONS[@]} ]; then exit 4; fi
if [ $questions_created -ne ${#PICOT_QUESTIONS[@]} ]; then exit 4; fi
```

---

## Phase 5.2.5: Generate Provenance READMEs (Automatic)

The unpack script automatically generates two provenance chain READMEs after creating entity files. **No LLM action required** - the script handles README generation automatically.

### 5.2.5.1 Dimensions README

**Path:** `${PROJECT_PATH}/01-research-dimensions/README.md` (entity root, NOT in /data/)

**Contents:**

- YAML frontmatter with generation metadata
- Mermaid mindmap: `initial_question → dimensions`
- Statistics table
- Entity index with wikilinks

### 5.2.5.2 Refined-Questions README

**Path:** `${PROJECT_PATH}/02-refined-questions/README.md` (entity root, NOT in /data/)

**Contents:**

- YAML frontmatter with generation metadata
- Mermaid mindmap: `initial_question → dimensions → questions`
- Statistics table
- Entity index with wikilinks

**⛔ VERIFICATION:** Check script output JSON for `readmes_created` status:

```json
"readmes_created": {
  "dimensions_readme": true,
  "refined_questions_readme": true
}
```

If either is `false`, the script failed to create READMEs - re-run the script.

---

## Phase 5.3: Final Completion Verification

⛔ **BLOCKING:** Verify ALL entity files AND README files were created.

### Step 1: Verify Entity Files

```bash
bash scripts/verify-phase5-completion.sh \
  --project-path "$PROJECT_PATH" \
  --dimensions-count "${#SELECTED_DIMENSIONS[@]}" \
  --questions-count "${#PICOT_QUESTIONS[@]}" \
  --json
```

IF `verify_exit != 0` → DO NOT report success. Output error JSON and exit.

### Step 2: Verify README Files Exist (MANDATORY)

⛔ **CRITICAL:** READMEs are ONLY created by the unpack script. This verification confirms the script was actually called.

```bash
ls -la "${PROJECT_PATH}/01-research-dimensions/README.md" "${PROJECT_PATH}/02-refined-questions/README.md"
```

**Both files MUST exist.** If either is missing:

1. Log error: `[ERROR] README files not created - script may not have executed`
2. Re-run the unpack script from Phase 5.2
3. If still missing, STOP and report critical error

⛔ **NEVER create README files manually with Write tool. Only the script creates valid READMEs with provenance chains.**

### Verification Checklist

- [ ] Entity file counts match expected dimensions and questions
- [ ] `${PROJECT_PATH}/01-research-dimensions/README.md` exists
- [ ] `${PROJECT_PATH}/02-refined-questions/README.md` exists
- [ ] Script output shows `readmes_created.dimensions_readme: true`
- [ ] Script output shows `readmes_created.refined_questions_readme: true`

---

## Phase 5.4: Return Success JSON

⛔ Only reachable after Phase 5.3 passes. Use VERIFIED counts from Phase 5.3.

### Standard Response (All Research Types)

```json
{
  "success": true,
  "dimensions": 4,
  "questions": 16,
  "data": {
    "phase": "5.4",
    "status": "complete",
    "dimensions_created": 4,
    "questions_created": 16,
    "readmes_created": {
      "dimensions_readme": true,
      "refined_questions_readme": true
    },
    "dimension_files": ["dimensions/customer-analysis.md", "..."],
    "metadata_file": ".metadata/dimension-plan-batch.json",
    "approach": "batched"
  }
}
```

### Extended Response (generic/smarter-service with Phase 4b)

If Phase 4b was executed, include `seed_megatrends` in the response:

```json
{
  "success": true,
  "dimensions": 4,
  "questions": 16,
  "seed_megatrends": {
    "count": 5,
    "file": ".metadata/seed-megatrends.yaml",
    "pending_validation": true
  },
  "data": {
    "phase": "5.4",
    "status": "complete",
    "dimensions_created": 4,
    "questions_created": 16,
    "readmes_created": {
      "dimensions_readme": true,
      "refined_questions_readme": true
    },
    "dimension_files": ["dimensions/customer-analysis.md", "..."],
    "metadata_file": ".metadata/dimension-plan-batch.json",
    "approach": "batched"
  }
}
```

**Response Fields:**

| Field | Type | When Present | Description |
|-------|------|--------------|-------------|
| `success` | boolean | Always | true if dimension-planner completed successfully |
| `dimensions` | integer | Always | Number of research dimensions created (2-10) |
| `questions` | integer | Always | Number of refined questions created |
| `seed_megatrends` | object | generic/smarter-service only | Seed megatrends from Phase 4b |
| `seed_megatrends.count` | integer | With seed_megatrends | Number of proposed seeds |
| `seed_megatrends.file` | string | With seed_megatrends | Path to seed-megatrends.yaml |
| `seed_megatrends.pending_validation` | boolean | With seed_megatrends | true if user validation required |
| `data` | object | Always | Detailed execution data |

**Integration with deeper-research-1:**

The orchestrator (deeper-research-0) checks for `seed_megatrends.pending_validation == true` to trigger Phase 2b (user validation of seed megatrends via AskUserQuestion).

---

## Semantic Quality Checks (Trends Questions)

**IF organizing_concept contains trend-related terms:**

| Check | Threshold | Metric |
|-------|-----------|--------|
| Momentum language | ≥50% | Questions with acceleration/emerging keywords |
| Adoption curve framing | ≥30% | Questions using adoption curve patterns |
| Case study (if required) | 100% | "validated by N named company case studies" |
| Case study (if recommended) | ≥60% | References to examples/use cases |
| Descriptive verbs | ≥70% | "Which/What/How evolving" vs imperative |
| Momentum metrics in outcomes | ≥40% | Adoption rates, time metrics, comparisons |

---

## Error Handling

| Code | Phase | Meaning | Recovery |
|------|-------|---------|----------|
| 0 | - | Success | Continue |
| 1 | 5.1 | JSON syntax/schema error | Fix generation |
| 2 | 5.0 | Pre-flight failure | Check environment |
| 3 | 5.2 | Unpack failure | Check script logs |
| 4 | 5.2/5.3 | Verification failure | Check file counts |

---

## Quality Guarantees

- Schema validation enforces required fields, types, patterns
- Extended thinking prevents freeform errors
- Verification gates ensure ALL files created
- Same YAML/markdown format (backward compatible)

---

## References

**Schemas:** `schemas/dimension-plan-batch.schema.json`, `../../schemas/dimension-entity.schema.json`, `../../schemas/refined-question-entity.schema.json`

**Scripts:** `scripts/unpack-dimension-plan-batch.sh`, `scripts/verify-phase5-completion.sh`

---

**Document Size:** ~12KB (includes smarter-service batching)
