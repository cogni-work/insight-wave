# Phase 3: Entity Loading

**Objective:** Load dimension-scoped research entities into LLM context using Read tool. Each trends-creator agent loads ONLY entities for its assigned dimension.

**Critical Success Factor:** Every entity file MUST be loaded via Claude Code Read tool. Bash `cat` does NOT populate the LLM context window.

---

## CRITICAL: Anti-Hallucination Protocol

This phase exists to prevent the most common failure mode in AI-driven synthesis: hallucinating trends based on incomplete or missing data.

**Non-Negotiable Requirements:**

1. **MUST use Claude Code Read tool** for ALL entity loading
   - Read tool populates LLM context window
   - Bash `cat` streams to stdout but does NOT populate context
   - Each Read tool call makes content available for synthesis

2. **Complete loading required** - NO truncation allowed
   - Load entire files, not summaries
   - Batch multiple files per Read call for efficiency (5-10 files)
   - If file is too large, load in segments with offset/limit

3. **Blocking verification checkpoint** before synthesis
   - Count expected entities BEFORE loading
   - Verify loaded count matches expected count
   - STOP if mismatch detected

**Why This Matters:**

Without complete entity loading, the synthesis phase will:
- Generate plausible-sounding but factually incorrect trends
- Reference findings that don't exist
- Miss critical patterns visible only across all entities
- Produce output that fails user validation

---

## Phase Entry Verification (MANDATORY)

Before beginning Step 1, verify Phase 2 completion and MANDATORY dimension parameter:

```bash
# MANDATORY: Dimension filter validation (trends-creator only supports dimension-scoped mode)
if [ -z "${DIMENSION}" ]; then
  echo "ERROR: DIMENSION not set. trends-creator requires --dimension parameter."
  echo "ERROR: trends-creator only supports dimension-scoped execution."
  exit 1
fi
DIMENSION_FILTER_ENABLED=true  # Always true - only mode supported

# Verify research_type detected in Phase 2
if [ -z "${research_type}" ]; then
  echo "ERROR: research_type not set. Phase 2 incomplete."
  exit 1
fi

# Verify synthesis_format determined in Phase 2
if [ -z "${synthesis_format}" ]; then
  echo "ERROR: synthesis_format not set. Phase 2 incomplete."
  exit 1
fi

# Verify generation_mode detected in Phase 2
if [ -z "${generation_mode}" ]; then
  echo "ERROR: generation_mode not set. Phase 2 incomplete."
  exit 1
fi

# Log phase entry
echo "=== PHASE 3: ENTITY LOADING (DIMENSION-SCOPED) ==="
echo "Research Type: ${research_type}"
echo "Synthesis Format: ${synthesis_format}"
echo "Generation Mode: ${generation_mode}"
echo "Target Dimension: ${DIMENSION}"
echo "Project Path: ${PROJECT_PATH}"
```

**If verification fails:** Return to Phase 2 to complete format detection.

**If verification passes:** Proceed to Step 0.5.

---

## Dimension Filtering Mode

**When DIMENSION_FILTER_ENABLED is true:**

Entity loading is scoped to only entities relevant to the specified dimension. This enables parallel execution where each trends-creator agent processes one dimension independently.

**Filtering Logic Summary:**

| Entity Type | Filter Method |
|-------------|---------------|
| Findings | Via query_batch → dimension chain (see Step 2) |
| Domain-Concepts | By dimension tags in frontmatter |
| Megatrends | By dimension tags in frontmatter |
| Dimensions | Load only the target dimension |
| Refined Questions | By dimension field in frontmatter |

**Expected Count Adjustment:**

When dimension filter is enabled, expected counts should be adjusted to match filtered scope, not total counts. The verification checkpoint (Step 7) must compare against filtered counts, not directory totals.

**Note:** Cross-dimensional mode is NOT supported. trends-creator always operates in dimension-scoped mode.

---

## Step 0.5: Initialize Phase 3 TodoWrite

**Action:** Create step-level todos for entity loading workflow.

```markdown
USE: TodoWrite tool

ADD (step-level todos):
- Phase 3, Step 1: Count entities in each directory [in_progress]
- Phase 3, Step 2: Load findings from 04-findings/data/ [pending]
- Phase 3, Step 2.5: Load claims from 10-claims/data/ [pending]
- Phase 3, Step 3: Load domain-concepts from 05-domain-concepts/data/ [pending]
- Phase 3, Step 4: Load megatrends from 06-megatrends/data/ [pending]
- Phase 3, Step 5: Load dimensions from 01-research-dimensions/data/ [pending]
- Phase 3, Step 6: Load refined questions from 02-refined-questions/data/ [pending]
- Phase 3, Step 7: Verification checkpoint [pending]
```

**Purpose:** Track progress through multi-step loading process and provide clear status to user.

---

## Step 1: Count Entities

**Objective:** Establish expected entity counts BEFORE loading to enable verification.

### Dimension-Scoped Mode (Skip Total Counts)

**When DIMENSION_FILTER_ENABLED is true:**

Skip total directory counts - they are irrelevant for dimension-scoped loading. Filtered counts will be established during Steps 2-6 as each entity type is filtered to the target dimension.

```bash
if [ "${DIMENSION_FILTER_ENABLED}" = "true" ]; then
  echo "=== DIMENSION-SCOPED MODE: Skipping total directory counts ==="
  echo "Target dimension: ${DIMENSION}"
  echo "Filtered counts will be established during Steps 2-6"
  echo ""
  # Proceed directly to Step 2 - no directory counting needed
fi
```

**Rationale:** In dimension-scoped mode, total counts are misleading. For example, if there are 100 findings but only 25 match the target dimension, counting 100 and then loading 25 creates confusion in verification. Instead, we establish the filtered count during the loading step itself.

**TodoWrite:** Mark Step 1 as completed (skipped in dimension-scoped mode), Step 2 as in_progress.

**Note:** Cross-dimensional counting is NOT applicable. trends-creator always operates in dimension-scoped mode.

**TodoWrite:** Mark Step 1 as completed (skipped - dimension-scoped mode), Step 2 as in_progress.

---

## Step 2: Load Findings

**Objective:** Load finding files into LLM context using Read tool.

**Critical:** Findings are the atomic units of research. Load only findings relevant to the target dimension (dimension-scoped mode only).

### Dimension Filtering for Findings

**When DIMENSION_FILTER_ENABLED is true:**

Findings connect to dimensions through query_batch metadata, not directly. Use this filtering chain:

```bash
# 1. Find query batches for the target dimension
batch_files=$(grep -l "dimension: \"${DIMENSION}\"" "${PROJECT_PATH}/03-query-batches/data/"*.md 2>/dev/null)

# 2. Extract query IDs from matching batches
query_ids=()
for batch in ${batch_files}; do
  ids=$(grep "query_id:" "$batch" | sed 's/.*"\([^"]*\)".*/\1/')
  query_ids+=($ids)
done

# 3. Find findings that reference these query IDs
filtered_findings=()
for finding_file in "${PROJECT_PATH}/04-findings/data/"*.md; do
  for qid in "${query_ids[@]}"; do
    if grep -q "\"${qid}\"" "$finding_file"; then
      filtered_findings+=("$finding_file")
      break
    fi
  done
done

echo "Dimension filter: ${#filtered_findings[@]} findings match dimension ${DIMENSION}"
```

**Pattern Reference:** See `scripts/map-findings-to-dimensions.sh` for complete implementation.

### Implementation Pattern

```markdown
# Dimension-scoped mode ONLY (cross-dimensional not supported)
FOR each finding file in filtered_findings:
  [Load finding...]

FOR each finding file:

  1. Log: "Loading finding N of M: {filename}"

  2. USE Read tool to load complete file:
     - file_path: absolute path to finding file
     - No offset/limit (load complete file)

  3. Extract and store in memory:
     - finding_id (from filename or frontmatter)
     - summary (from frontmatter or first section)
     - key_points (bulleted content)
     - source_url (from frontmatter)
     - TIPS tags (if present)

  4. Increment findings_loaded counter

BATCH EFFICIENCY:
  - Load 5-10 findings per Read tool call when possible
  - Use parallel Read calls for independent files
  - For very large finding files (>50KB), load in segments
```

**Example Execution:**

```markdown
USE: Read tool
file_path: /absolute/path/to/04-findings/data/finding-001.md

USE: Read tool
file_path: /absolute/path/to/04-findings/data/finding-002.md

[Continue for all findings...]

LOG: "Loaded findings: 47 of 47"
```

**Data Extraction Focus:**

For each finding, extract:

- **finding_id:** Unique identifier (e.g., "finding-001")
- **summary:** 1-2 sentence overview
- **key_points:** Main trends (bulleted list)
- **source_url:** Original source for citation
- **TIPS tags:** Technology, Institution, Process, Social dimensions
- **dimension_refs:** Which research dimensions this finding addresses

**Common Pitfalls:**

- WRONG: `cat 04-findings/data/*.md` - Does NOT populate LLM context
- WRONG: Reading only first 10 findings - Incomplete context causes hallucination
- WRONG: Summarizing findings during load - Loses critical details
- RIGHT: Use Read tool for each file, extract full content

**TodoWrite:** Mark Step 2 as completed, Step 2.5 as in_progress.

---

## Step 2.5: Load Claims

**Objective:** Load claim entities from 10-claims/data/ into LLM context for quote integration.

**Critical:** Claims are verified factual assertions with confidence scores. They provide compelling quotes for TIPS sections.

### Dimension Filtering for Claims

**When DIMENSION_FILTER_ENABLED is true:**

Filter claims by checking if their source findings match the dimension's findings:

```bash
# Claims link to findings via finding_refs - filter by loaded findings
filtered_claims=()
for claim_file in "${PROJECT_PATH}/10-claims/data/"*.md; do
  # Check if claim's finding_refs intersect with filtered_findings
  for finding in "${filtered_findings[@]}"; do
    finding_id=$(basename "$finding" .md)
    if grep -q "$finding_id" "$claim_file"; then
      filtered_claims+=("$claim_file")
      break
    fi
  done
done

echo "Dimension filter: ${#filtered_claims[@]} claims match dimension ${DIMENSION}"

# LAYER 2: Build claim registry for Phase 4 validation
declare -a CLAIM_REGISTRY=()
for claim_file in "${filtered_claims[@]}"; do
  claim_id=$(basename "$claim_file" .md)
  CLAIM_REGISTRY+=("$claim_id")
  echo "Registered claim: $claim_id"
done

export CLAIM_REGISTRY
log_conditional INFO "Claim registry built: ${#CLAIM_REGISTRY[@]} claims available for Phase 4"
```

### Implementation Pattern

```markdown
IF DIMENSION_FILTER_ENABLED = "true":
  FOR each claim file in filtered_claims:
    [Load as normal...]
ELSE:
  FOR each claim file in 10-claims/data/*.md:
    [Load as normal...]

FOR each claim file:
  1. Log: "Loading claim N of M: {filename}"
  2. USE Read tool to load complete file
  3. Extract: claim_text, confidence_score, claim_quality, finding_refs
  4. Increment claims_loaded counter

LOG: "Loaded claims: {claims_loaded}"
```

**Selection for Synthesis:** During Phase 4, prioritize claims with:

- `confidence_score >= 0.75`
- `flagged_for_review = false`
- `claim_quality >= 0.70`

**TodoWrite:** Mark Step 2.5 as completed, Step 3 as in_progress.

---

## Step 3: Load Domain-Concepts

**Objective:** Load domain-concept files into LLM context using Read tool.

**Context:** Domain-concepts may be 0 for small projects. This is valid and should not trigger errors.

### Dimension Filtering for Concepts

**When DIMENSION_FILTER_ENABLED is true:**

Filter concepts by checking for dimension slug in tags frontmatter:

```bash
# Find concepts with dimension tag
filtered_concepts=()
for concept_file in "${PROJECT_PATH}/05-domain-concepts/data/"*.md; do
  if grep -q "tags:.*${DIMENSION}" "$concept_file"; then
    filtered_concepts+=("$concept_file")
  fi
done

echo "Dimension filter: ${#filtered_concepts[@]} concepts match dimension ${DIMENSION}"
```

### Implementation Pattern

```markdown
# Dimension-scoped mode ONLY (cross-dimensional not supported)
IF filtered_concepts count > 0:
  FOR each concept file in filtered_concepts:
    [Load concept...]
ELSE:
  LOG: "No concepts match dimension ${DIMENSION} (valid)"
  concepts_loaded = 0

FOR each concept file:

  1. Log: "Loading domain-concept N of M: {filename}"

  2. USE Read tool to load complete file:
     - file_path: absolute path to concept file
     - No offset/limit (load complete file)

  3. Extract and store in memory:
     - concept_id (from filename)
     - term (concept name)
     - definition (detailed explanation)
     - category (e.g., technical, business, process)
     - related_findings (cross-references)

  4. Increment concepts_loaded counter

LOG: "Loaded domain-concepts: {concepts_loaded}"
```

**Data Extraction Focus:**

For each domain-concept, extract:

- **concept_id:** Unique identifier (e.g., "concept-api-gateway")
- **term:** Concept name (e.g., "API Gateway")
- **definition:** Detailed explanation of concept
- **category:** Classification (technical, business, process, social)
- **related_findings:** Which findings reference this concept
- **TIPS alignment:** How concept maps to TIPS dimensions

**Validation:**

- If CONCEPTS_COUNT = 0: This is VALID (not an error)
- If CONCEPTS_COUNT > 0 but concepts_loaded = 0: ERROR - loading failed
- If concepts_loaded < CONCEPTS_COUNT: ERROR - incomplete loading

**TodoWrite:** Mark Step 3 as completed, Step 4 as in_progress.

---

## Step 4: Load Megatrends

**Objective:** Load megatrend files into LLM context using Read tool.

**Context:** Megatrends may be 0 for small projects. This is valid and should not trigger errors.

### Dimension Filtering for Megatrends

**When DIMENSION_FILTER_ENABLED is true:**

Filter megatrends by checking for dimension slug in tags frontmatter:

```bash
# Find megatrends with dimension tag
filtered_megatrends=()
for megatrend_file in "${PROJECT_PATH}/06-megatrends/data/"*.md; do
  if grep -q "tags:.*${DIMENSION}" "$megatrend_file"; then
    filtered_megatrends+=("$megatrend_file")
  fi
done

echo "Dimension filter: ${#filtered_megatrends[@]} megatrends match dimension ${DIMENSION}"
```

### Megatrends Loading Pattern

```markdown
# Dimension-scoped mode ONLY (cross-dimensional not supported)
IF filtered_megatrends count > 0:
  FOR each megatrend file in filtered_megatrends:
    [Load megatrend...]
ELSE:
  LOG: "No megatrends match dimension ${DIMENSION} (valid)"
  megatrends_loaded = 0

FOR each megatrend file:

  1. Log: "Loading megatrend N of M: {filename}"

  2. USE Read tool to load complete file:
     - file_path: absolute path to megatrend file
     - No offset/limit (load complete file)

  3. Extract and store in memory:
     - megatrend_id (from filename)
     - megatrend_name (e.g., "Cloud Migration Strategy")
     - keywords (associated terms)
     - finding_refs (which findings contribute to this megatrend)
     - TIPS dimensions (which dimensions this megatrend spans)

  4. Increment megatrends_loaded counter

LOG: "Loaded megatrends: {megatrends_loaded}"
```

**Data Extraction Focus:**

For each megatrend, extract:

- **megatrend_id:** Unique identifier (e.g., "megatrend-cloud-migration")
- **megatrend_name:** Human-readable megatrend name
- **keywords:** Associated search terms and phrases
- **finding_refs:** List of finding IDs that contribute to this megatrend
- **TIPS_dimensions:** Which TIPS dimensions this megatrend addresses
- **emergence_pattern:** How this megatrend emerged from findings

**Validation:**

- If MEGATRENDS_COUNT = 0: This is VALID (not an error)
- If MEGATRENDS_COUNT > 0 but megatrends_loaded = 0: ERROR - loading failed
- If megatrends_loaded < MEGATRENDS_COUNT: ERROR - incomplete loading

**TodoWrite:** Mark Step 4 as completed, Step 5 as in_progress.

---

## Step 5: Load Dimensions

**Objective:** Load dimension files from 01-research-dimensions/data/ into LLM context.

**Critical:** Load only the target dimension (dimension-scoped mode only).

### Dimension Filtering for Dimensions

**When DIMENSION_FILTER_ENABLED is true:**

Load only the target dimension file:

```bash
# Find the specific dimension file
target_dimension_file=$(find "${PROJECT_PATH}/01-research-dimensions" -name "dimension-${DIMENSION}-*.md" | head -1)

if [ -z "$target_dimension_file" ]; then
  echo "ERROR: Target dimension file not found: ${DIMENSION}"
  exit 1
fi

echo "Dimension filter: Loading single dimension ${DIMENSION}"
```

### Dimensions Loading Pattern

```markdown
# Dimension-scoped mode ONLY (cross-dimensional not supported)
# Load only the target dimension (exactly 1)

1. Log: "Loading target dimension: ${DIMENSION}"

2. USE Read tool to load complete file:
   - file_path: ${target_dimension_file}
   - No offset/limit (load complete file)

3. Extract and store in memory:
   - dimension_id (from filename)
   - dimension_name (e.g., "Technology Stack Evolution")
   - description (detailed scope)
   - TIPS_alignment (which TIPS dimension this belongs to)
   - research_questions (associated questions)

4. dimensions_loaded = 1

LOG: "Loaded target dimension: ${DIMENSION}"
```

**Data Extraction Focus:**

For each dimension, extract:

- **dimension_id:** Unique identifier (e.g., "dim-tech-stack")
- **dimension_name:** Human-readable dimension name
- **description:** Detailed scope and boundaries
- **TIPS_alignment:** Which TIPS dimension(s) this belongs to
- **research_questions:** Associated question IDs from Phase 1
- **expected_trends:** What types of trends to synthesize

**Validation:**

- If DIMENSIONS_COUNT = 0: ERROR - dimensions are mandatory
- If dimensions_loaded < DIMENSIONS_COUNT: ERROR - incomplete loading
- If dimensions_loaded = DIMENSIONS_COUNT: SUCCESS

**TodoWrite:** Mark Step 5 as completed, Step 6 as in_progress.

---

## Step 6: Load Refined Questions

**Objective:** Load refined question files from 02-refined-questions/data/ into LLM context.

**Context:** Refined questions guide synthesis focus and structure.

### Dimension Filtering for Questions

**When DIMENSION_FILTER_ENABLED is true:**

Filter questions by checking the dimension field in frontmatter:

```bash
# Find questions for the target dimension
filtered_questions=()
for question_file in "${PROJECT_PATH}/02-refined-questions/data/"*.md; do
  dimension_value=$(grep "^dimension:" "$question_file" | sed 's/dimension: "\(.*\)"/\1/' | tr -d ' ')
  if [ "$dimension_value" == "${DIMENSION}" ]; then
    filtered_questions+=("$question_file")
  fi
done

echo "Dimension filter: ${#filtered_questions[@]} questions match dimension ${DIMENSION}"
```

### Questions Loading Pattern

```markdown
# Dimension-scoped mode ONLY (cross-dimensional not supported)
IF filtered_questions count > 0:
  FOR each question file in filtered_questions:
    [Load question...]
ELSE:
  LOG: "No questions match dimension ${DIMENSION} (valid for some research types)"
  questions_loaded = 0

FOR each question file:

  1. Log: "Loading refined question N of M: {filename}"

  2. USE Read tool to load complete file:
     - file_path: absolute path to question file
     - No offset/limit (load complete file)

  3. Extract and store in memory:
     - question_id (from filename)
     - question_text (refined research question)
     - PICOT_structure (if applicable)
     - dimension_ref (which dimension this question belongs to)
     - scope (boundaries and focus)

  4. Increment questions_loaded counter

LOG: "Loaded refined questions: {questions_loaded}"
```

**Data Extraction Focus:**

For each refined question, extract:

- **question_id:** Unique identifier (e.g., "question-001")
- **question_text:** Refined research question
- **PICOT_structure:** Population, Intervention, Comparison, Outcome, Time (if applicable)
- **dimension_ref:** Parent dimension ID
- **scope:** Question boundaries and focus areas
- **expected_answer_type:** Descriptive, comparative, causal, etc.

**Validation:**

- If QUESTIONS_COUNT = 0: WARNING - unusual but potentially valid
- If questions_loaded < QUESTIONS_COUNT: ERROR - incomplete loading
- If questions_loaded = QUESTIONS_COUNT: SUCCESS

**TodoWrite:** Mark Step 6 as completed, Step 7 as in_progress.

---

## Step 7: Verification Checkpoint (BLOCKING)

**Objective:** Verify entities loaded match expected counts before proceeding to synthesis. This is a BLOCKING checkpoint.

### Dimension-Aware Verification

**When DIMENSION_FILTER_ENABLED is true:**

Verification uses filtered counts, not directory totals. The verification must confirm:

- All filtered findings were loaded (findings matching dimension's query batches)
- Target dimension was loaded (exactly 1)
- Filtered questions, concepts, and megatrends were loaded (counts may be 0)

### Verification Checklist

```markdown
# Dimension-scoped verification ONLY (cross-dimensional not supported)

VERIFICATION CHECKLIST:

1. Findings Verification:
   - Expected: filtered_findings_count (from Step 2 filter)
   - Loaded: findings_loaded
   - Status: [PASS if match, FAIL if > 0 expected but 0 loaded]

2. Dimensions Verification:
   - Expected: 1 (target dimension only)
   - Loaded: dimensions_loaded
   - Status: [PASS/FAIL]

3. Refined Questions Verification:
   - Expected: filtered_questions_count (from Step 6 filter)
   - Loaded: questions_loaded
   - Status: [PASS if match, N/A if expected=0]

4. Domain-Concepts Verification:
   - Expected: filtered_concepts_count (from Step 3 filter)
   - Loaded: concepts_loaded
   - Status: [PASS if match, N/A if expected=0]

5. Megatrends Verification:
   - Expected: filtered_megatrends_count (from Step 4 filter)
   - Loaded: megatrends_loaded
   - Status: [PASS if match, N/A if expected=0]

Dimension Filter Summary:
  - Target dimension: ${DIMENSION}
  - Total entities loaded: {sum of all loaded counts}
```

### Decision Logic

```bash
# Dimension-scoped verification ONLY (cross-dimensional not supported)
verification_passed=true

echo "=== DIMENSION-SCOPED VERIFICATION ==="
echo "Target dimension: ${DIMENSION}"

# Check findings (must have at least 1 for valid dimension)
if [ ${findings_loaded} -eq 0 ]; then
  echo "FAIL: No findings loaded for dimension ${DIMENSION}"
  echo "This may indicate an invalid dimension or missing query batch mapping"
  verification_passed=false
else
  echo "PASS: Loaded ${findings_loaded} findings for dimension ${DIMENSION}"
fi

# Check dimension (must be exactly 1)
if [ ${dimensions_loaded} -ne 1 ]; then
  echo "FAIL: Expected 1 dimension, loaded ${dimensions_loaded}"
  verification_passed=false
else
  echo "PASS: Loaded target dimension ${DIMENSION}"
fi

# Questions, concepts, megatrends - 0 is valid for some dimensions
echo "INFO: Loaded ${questions_loaded} questions, ${concepts_loaded} concepts, ${megatrends_loaded} megatrends"

# Check claims (MANDATORY for 3-claim minimum per trend)
# Each trend requires minimum 3 claims, so need sufficient claims for all planned trends
MIN_CLAIMS_PER_TREND=3
EXPECTED_TRENDS=13  # 5 ACT + 5 PLAN + 3 OBSERVE per dimension
MIN_TOTAL_CLAIMS=$((MIN_CLAIMS_PER_TREND * EXPECTED_TRENDS / 2))  # Some claims may be reused

if [ ${claims_loaded} -lt ${MIN_TOTAL_CLAIMS} ]; then
  echo "WARN: Low claim count for dimension ${DIMENSION} (${claims_loaded} < ${MIN_TOTAL_CLAIMS} recommended)"
  echo "WARN: Each trend requires minimum 3 claims - synthesis may fail validation"
fi

if [ ${claims_loaded} -eq 0 ]; then
  echo "FAIL: No claims loaded for dimension ${DIMENSION}"
  echo "FAIL: Cannot proceed - each trend requires minimum 3 claims"
  verification_passed=false
else
  echo "PASS: Loaded ${claims_loaded} claims for dimension ${DIMENSION}"
fi

# Verify claim registry was built (LAYER 2 validation)
if [ ${#CLAIM_REGISTRY[@]} -ne ${claims_loaded} ]; then
  echo "FAIL: Claim registry size mismatch (registry: ${#CLAIM_REGISTRY[@]}, loaded: ${claims_loaded})"
  verification_passed=false
else
  echo "PASS: Claim registry built with ${#CLAIM_REGISTRY[@]} entries"
fi

if [ "${verification_passed}" = "true" ]; then
  echo "=== VERIFICATION PASSED ==="
  echo "All entities loaded successfully. Ready for Phase 4."
  echo "Mode: Dimension-scoped (${DIMENSION})"
else
  echo "=== VERIFICATION FAILED ==="
  echo "Re-load missing entities before proceeding."
  exit 1
fi
```

**If Verification Fails:**

1. Log which entity type(s) failed
2. Use Glob tool to list missing files
3. Re-run loading steps for failed entity types
4. Re-run verification checkpoint
5. DO NOT proceed to Phase 4 until all verifications pass

**If Verification Passes:**

1. Log success message
2. Log total entities loaded
3. Mark Phase 3 as completed in phase-level todos
4. Proceed to Phase 4 (Synthesis)

**TodoWrite:** Mark Step 7 as completed.

---

## Before Marking Phase 3 Complete

**Self-Verification Questions:**

Answer YES/NO to each question. ALL must be YES before proceeding.

1. **Did you count entities in all directories?**
   - [ ] Counted findings in 04-findings/data/
   - [ ] Counted concepts in 05-domain-concepts/data/
   - [ ] Counted megatrends in 06-megatrends/data/
   - [ ] Counted dimensions in 01-research-dimensions/data/
   - [ ] Counted questions in 02-refined-questions/data/

2. **Did you use Read tool (not bash cat) for ALL entities?**
   - [ ] Used Read tool for every finding file
   - [ ] Used Read tool for every concept file (if any)
   - [ ] Used Read tool for every megatrend file (if any)
   - [ ] Used Read tool for every dimension file
   - [ ] Used Read tool for every question file

3. **Did you load findings completely (no truncation)?**
   - [ ] All findings loaded without offset/limit
   - [ ] No summarization during loading
   - [ ] Full content available in LLM context

4. **Did you load concepts, megatrends, dimensions, questions?**
   - [ ] All dimensions loaded (mandatory)
   - [ ] All questions loaded (mandatory)
   - [ ] All concepts loaded (or confirmed 0)
   - [ ] All megatrends loaded (or confirmed 0)

5. **Did you pass verification checkpoint (all counts match)?**
   - [ ] findings_loaded == FINDINGS_COUNT
   - [ ] concepts_loaded == CONCEPTS_COUNT (or 0)
   - [ ] megatrends_loaded == MEGATRENDS_COUNT (or 0)
   - [ ] dimensions_loaded == DIMENSIONS_COUNT
   - [ ] questions_loaded == QUESTIONS_COUNT

6. **Are all entities now in LLM context window?**
   - [ ] Can reference any finding by ID without re-reading
   - [ ] Can reference any dimension by name without re-reading
   - [ ] Can reference any concept/megatrend without re-reading
   - [ ] Ready for cross-entity synthesis in Phase 4

**If ANY answer is NO:** Return to failed step and complete properly.

**If ALL answers are YES:** Mark Phase 3 as completed and proceed to Phase 4.

---

## Phase Completion Checklist

**Mandatory Completion Criteria:**

- [ ] **Entity counts logged**
  - Findings, concepts, megatrends, dimensions, questions counted
  - Expected counts logged for verification

- [ ] **ALL findings loaded via Read tool**
  - Each finding file loaded completely
  - No truncation or summarization
  - finding_loaded count matches FINDINGS_COUNT

- [ ] **ALL concepts loaded (or 0 confirmed)**
  - If CONCEPTS_COUNT > 0: all loaded via Read tool
  - If CONCEPTS_COUNT = 0: confirmed as valid state

- [ ] **ALL megatrends loaded (or 0 confirmed)**
  - If MEGATRENDS_COUNT > 0: all loaded via Read tool
  - If MEGATRENDS_COUNT = 0: confirmed as valid state

- [ ] **ALL dimensions loaded**
  - Each dimension file loaded completely
  - dimensions_loaded count matches DIMENSIONS_COUNT

- [ ] **ALL refined questions loaded**
  - Each question file loaded completely
  - questions_loaded count matches QUESTIONS_COUNT

- [ ] **Verification checkpoint PASSED**
  - All mandatory counts match (findings, dimensions, questions)
  - Optional counts match or confirmed as 0 (concepts, megatrends)
  - verification_passed = true

- [ ] **All step-level todos completed**
  - Step 1: Count entities [completed]
  - Step 2: Load findings [completed]
  - Step 3: Load domain-concepts [completed]
  - Step 4: Load megatrends [completed]
  - Step 5: Load dimensions [completed]
  - Step 6: Load refined questions [completed]
  - Step 7: Verification checkpoint [completed]

**Phase 3 Output:**

- Complete LLM context populated with all research entities
- Entity counts verified and logged
- Ready for Phase 4 synthesis

**Next Phase:** Phase 4 - Synthesis (format-specific trend generation)

---

## Anti-Pattern Warning

**WRONG APPROACH:**

```bash
# This does NOT populate LLM context window
cat "${PROJECT_PATH}/04-findings/data/"*.md > /tmp/all_findings.txt

# This does NOT make content available for synthesis
for file in 04-findings/data/*.md; do
  cat "$file"
done

# This does NOT enable cross-entity pattern recognition
grep -r "api gateway" 04-findings/data/
```

**RIGHT APPROACH:**

```markdown
# This DOES populate LLM context window
USE: Read tool
file_path: /absolute/path/to/04-findings/data/finding-001.md

USE: Read tool
file_path: /absolute/path/to/04-findings/data/finding-002.md

# Continue for ALL entities...
# Now LLM can synthesize patterns across all findings
```

**Key Distinction:**

- **Bash tools** (cat, grep, ls): Output to stdout, NOT to LLM context
- **Read tool**: Loads content into LLM context window for synthesis
- **Synthesis requires**: All entities in context, not in stdout logs

---

## Estimated Metrics

**Time Investment:**
- Step 1 (Counting): 30 seconds
- Step 2 (Load findings): 2-5 minutes (depends on finding count)
- Step 3 (Load concepts): 1-3 minutes (if any)
- Step 4 (Load megatrends): 1-3 minutes (if any)
- Step 5 (Load dimensions): 1-2 minutes
- Step 6 (Load questions): 1-2 minutes
- Step 7 (Verification): 30 seconds

**Total Phase 3 Duration:** 6-15 minutes (varies by entity count)

**File Size:** ~7KB (this reference file)

**Success Rate Impact:**
- With proper Phase 3: 95%+ synthesis accuracy
- Without proper Phase 3: <50% synthesis accuracy (hallucination)

**Critical Success Factor:**
The 6-15 minutes invested in complete entity loading prevents hours of rework due to hallucinated trends. This phase is the foundation of trustworthy synthesis.

---

**End of Phase 3 Workflow**
