# Phase 4: Validation & Question Generation - Execution Instruction

Execute comprehensive validation, generate PICOT questions with batched operations, score with FINER criteria, and create quality plans.

---

## Prerequisites

Verify before executing:
- `SELECTED_DIMENSIONS` or `DIMENSION_SPECS` populated (Phase 3/3a)
- `PROJECT_LANGUAGE` set (Phase 0)
- Phase 4 TodoWrite initialized
- Phase 3 todo marked completed

---

## Workflow

**Domain Mode:** 4.1 (MECE) → 4.2 (PICOT) → 4.3 (FINER) → 4.6 (Final)
**Template Mode:** 4.2 (PICOT) → 4.3 (FINER) → 4.5 (Template) → 4.6 (Final)

---

## Phase 4.1: MECE Validation (Domain Only)

**Skip if template-based dimensions.**

### 4.1.1: Mutual Exclusivity (<20% Overlap)

Analyze all dimension pairs for semantic overlap:

**Process:**
1. Generate pairs: (A,B), (A,C), (B,C)...
2. Score each pair across 3 categories (0-100%):
   - Vocabulary overlap
   - Scope alignment
   - Evidence source overlap
3. Average the 3 scores
4. **Require:** <20% average for all pairs

**Example:** `Pair: (customer, competitive) → Vocabulary:10%, Scope:5%, Evidence:15% → Avg:10% ✓`

```bash
OVERLAP_MATRIX=$(calculate_pairwise_overlap "$SELECTED_DIMENSIONS")
FAILED_PAIRS=$(filter_overlaps_above_threshold "$OVERLAP_MATRIX" 20)
if [ -n "$FAILED_PAIRS" ]; then exit 1; fi
```

### 4.1.2: Coverage (100%)

Map dimensions to scope areas (market, implementation, viability, strategy). **Require:** All areas covered by ≥1 dimension.

```bash
COVERAGE_MAP=$(map_dimensions_to_scope "$SELECTED_DIMENSIONS" "$QUESTION_CONTEXT")
COVERAGE_PERCENTAGE=$(calculate_coverage_percentage "$COVERAGE_MAP")
if [ "$COVERAGE_PERCENTAGE" -lt 100 ]; then exit 1; fi
```

### 4.1.3: Independence

Identify dimension dependencies. Log results (doesn't fail, informs execution).

```bash
DEPENDENCIES=$(analyze_dimension_dependencies "$SELECTED_DIMENSIONS")
PARALLELIZABLE=$(check_parallel_feasibility "$DEPENDENCIES")
```

**Mark 4.1 complete in TodoWrite.**

---

## Phase 4.2: PICOT Question Generation (Batched)

**Objective:** Generate PICOT questions per dimension using DOK-based counts (2-5 per dimension, see research type) using batched calls.

**Context from Phase 3:** If PICOT_OVERRIDES or DIMENSION_CONTEXT exists from Phase 3, use these to customize questions with original question elements (target audience, impact language, action orientation, organizing concept) rather than using generic templates.

### PICOT Components

| Component | Meaning | Example | Context-Enhanced Example |
|-----------|---------|---------|-------------------------|
| P | Population | "B2B SaaS healthcare customers" | "Business leaders (C-level, Geschäftsführer)" |
| I | Intervention | "AI code review tool" | "Leverage Industry 4.0 technologies" |
| C | Comparison | "traditional peer review" | "Traditional manufacturing approaches" |
| O | Outcome | "code quality, review time" | "Significantly influence business performance" |
| T | Timeframe | "6-month pilot" | "2023-2030 horizon" |

**Template:** `"{I} among {P} compared to {C} impacts {O} during {T}?"`

**For research-type-specific questions (e.g., smarter-service trends):** If a research type template was loaded in Phase 2a, consult its PICOT Application Protocol section for specialized guidance including:

- Momentum framing (accelerated adoption, emerging trends)
- Case study integration requirements
- Adoption curve timeframe patterns
- Velocity-specific Intervention phrasing

The template provides conditional enhancements that activate when trend/innovation indicators are detected.

### TIPS-Enhanced PICOT for Smarter-Service (MANDATORY)

⛔ **IF RESEARCH_TYPE = smarter-service:** Apply these enhancements from Phase 3 PICOT_OVERRIDES:

**Velocity-Based Framing:**

```bash
# Use velocity templates from Phase 3
I_PREFIX="${PICOT_OVERRIDES[velocity_intervention_prefix]}"
O_SUFFIX="${PICOT_OVERRIDES[velocity_outcome_suffix]}"
C_PATTERN="${PICOT_OVERRIDES[velocity_comparison_pattern]}"
```

**Momentum Outcomes:**

```bash
# Use momentum patterns per dimension
MOMENTUM_OPTIONS="${MOMENTUM_OUTCOMES[$dimension_slug]}"
# Select one momentum indicator per question
```

**Action Horizon Assignment:**

```bash
# Use horizon distribution from Phase 3
HORIZON_DIST="${HORIZON_DISTRIBUTION[$dimension_slug]}"
# Assign horizons based on distribution: act:X|plan:Y|observe:Z
```

**Case Study Integration:**

```bash
# Append case study clause if required
if [ -n "${PICOT_OVERRIDES[case_study_clause]}" ]; then
  QUESTION_TEXT="${QUESTION_TEXT}${PICOT_OVERRIDES[case_study_clause]}"
fi
```

**FINER Diversification Enforcement:**

```bash
# Track FINER score distribution during generation
FINER_SCORE_15_COUNT=0
FINER_SCORE_14_COUNT=0
FINER_SCORE_13_COUNT=0
FINER_SCORE_12_COUNT=0

# Enforce diversification targets
MAX_15="${PICOT_OVERRIDES[finer_score_15_max]}"
MIN_12="${PICOT_OVERRIDES[finer_score_12_min]}"
```

### Batched Generation Process

For each dimension, generate ALL questions in one call:

**Language-Specific Character Requirements:**

- **German (de):** Use proper Umlaute (ä, ö, ü, Ä, Ö, Ü, ß) in ALL body text content
  - ✓ Correct: "Führungsmodelle", "Geschäftsführer", "Änderungen"
  - ✗ Wrong: "Fuehrungsmodelle", "Geschaeftsfuehrer", "Aenderungen"
- Only slugs/filenames use ASCII transliteration (ü→u, not ü→ue)

**Extended Thinking Template:**

````
<thinking>
Generating {N} PICOT questions for dimension "{dimension_name}":
LANGUAGE: {PROJECT_LANGUAGE} - Use native characters (German: ä,ö,ü,ß; French: é,è,ê; etc.)

## TIPS Context (smarter-service only)
- Velocity: {TREND_VELOCITY} → Use prefix: "{velocity_intervention_prefix}"
- Momentum outcomes available: {MOMENTUM_OUTCOMES[dimension]}
- Horizon distribution: act:{X}|plan:{Y}|observe:{Z}
- Case study clause: "{case_study_clause}"

Question 1 - [Topic Name]:
  - P (Population): [reasoning about who/what]
  - I (Intervention): [Apply velocity prefix] [reasoning about action/solution]
  - C (Comparison): [Use velocity comparison pattern] [reasoning about baseline/alternative]
  - O (Outcome): [Include momentum indicator] [reasoning about measurable results]
  - T (Timeframe): [reasoning about duration/when]
  - **Action Horizon**: [act|plan|observe] - [justification based on evidence maturity]
  - **Trend Velocity**: [accelerating|emerging|static] - [momentum indicator]
  - **Case Study**: [required|recommended|none] - [TIPS role: T/I/P/S]

  Rationale: [How this question fits the dimension and adds value]
  FINER Pre-Score: [estimated F+I+N+E+R] → Target distribution check

Question 2 - [Topic Name]:
  [Same structure...]

[Repeat for all N questions]

Verification:
- All {N} questions distinct? YES/NO
- All have complete PICOT (5 components)? YES/NO
- Coverage across dimension aspects? YES/NO
- No redundancy? YES/NO
- **Velocity framing applied?** YES/NO
- **Momentum indicators in outcomes?** YES/NO
- **Action horizons assigned?** YES/NO (distribution: act=X, plan=Y, observe=Z)
- **FINER diversification?** YES/NO (not all 14/15)
</thinking>

Output (newline-separated):
Question 1 text
Question 2 text
[...]
````

```bash
# Bash 3.2 compatible - use parallel indexed arrays
PICOT_QUESTION_IDS=()
PICOT_QUESTION_TEXTS=()
TOTAL_QUESTIONS=0

for dimension in "${SELECTED_DIMENSIONS[@]}"; do
  COUNT=$(calculate_dim_questions "$dimension" "$TOTAL_QUESTIONS_TARGET" "$MIN_QUESTIONS_PER_DIM")
  QUESTIONS=$(generate_picot_questions_batch "$dimension" "$COUNT" "$GENERATION_LANGUAGE")

  # Read questions into array (Bash 3.2 compatible)
  arr=()
  while IFS= read -r line; do
    arr+=("$line")
  done <<< "$QUESTIONS"

  for i in $(seq 1 "$COUNT"); do
    PICOT_QUESTION_IDS+=("${dimension}-q${i}")
    PICOT_QUESTION_TEXTS+=("${arr[$((i-1))]}")
    ((TOTAL_QUESTIONS++))
  done
done
```

**Success Criteria:**
- [ ] All dimensions have ≥MIN_Q_PER_DIM questions (DOK-based: 2-5)
- [ ] TOTAL_QUESTIONS within valid range per research type:
  - generic: 8-50 (DOK-based)
  - lean-canvas: 27 (DOK-2, 9×3)
  - customer-value-mapping: 16-40 (DOK×2 multiplier)
  - smarter-service: 52 (fixed: 5 ACT + 5 PLAN + 3 OBSERVE per dimension)
  - b2b-ict-portfolio: 57 (fixed, 8 dimensions 0-7)
- [ ] All questions follow PICOT structure
- [ ] PICOT_QUESTIONS populated

**Mark 4.2 complete in TodoWrite.**

---

## Phase 4.3: Comprehensive Quality Assessment (Batched)

**Objective:** Score FINER criteria AND plan quality attributes in batched calls (5-10 questions per call).

### FINER Criteria (1-3 points each, ≥10/15 required)

| Criterion | 1 Point | 2 Points | 3 Points |
|-----------|---------|----------|----------|
| **F**easible | Rare resources, long timeline | Moderate resources, 3-6mo | Available resources, <3mo |
| **I**nteresting | Limited stakeholder interest | Moderate engagement | High priority |
| **N**ovel | Replicates existing research | Some new aspects | Creates new knowledge |
| **E**thical | Questionable compliance | Minor concerns | Clear compliance |
| **R**elevant | Tangentially related | Moderately related | Directly addresses focus |

### Quality Planning Attributes

| Attribute | Values | Description |
|-----------|--------|-------------|
| Confidence | high/medium/low | Expected answer confidence |
| Triangulation | multiple_sources/single_source/cross_domain | Verification strategy |
| Gaps | [specific gaps] | Potential missing information |
| Complexity | simple/moderate/complex | Search difficulty |

### Batched Assessment Process

Process 5-10 questions per LLM call:

**Extended Thinking Template:**

````
<thinking>
Comprehensive quality assessment for questions {Q1-Q5}:

===== Question 1: {dimension-q1} =====
Text: [full question text]

FINER Scoring:
- F (Feasible): [1/2/3] - Resources: [analysis], Timeline: [analysis]
- I (Interesting): [1/2/3] - Stakeholder engagement: [analysis]
- N (Novel): [1/2/3] - Existing knowledge: [analysis], New aspects: [analysis]
- E (Ethical): [1/2/3] - Compliance concerns: [analysis]
- R (Relevant): [1/2/3] - Alignment with focus: [analysis]
Total: [F+I+N+E+R]/15 [✓ PASS ≥10 / ✗ FAIL <10]

Quality Planning:
- Confidence: [high/medium/low] - [reasoning based on question specificity]
- Triangulation: [strategy] - [reasoning about source diversity needs]
- Gaps: [specific gaps] - [reasoning about potential missing data]
- Complexity: [simple/moderate/complex] - [reasoning about search difficulty]

===== Question 2: {dimension-q2} =====
[Same structure...]

[Repeat for Q3-Q5]

Batch Validation:
- All FINER ≥10/15? YES/NO
- Batch average: [avg]/15
- Quality plans complete? YES/NO
- Questions needing reformulation: [list IDs or "none"]
</thinking>

Output (JSON):
{
  "dimension-q1": {
    "finer": {"F": 3, "I": 2, "N": 3, "E": 3, "R": 2},
    "quality": {
      "confidence": "high",
      "triangulation": "multiple_sources",
      "gaps": "need competitor financial data",
      "complexity": "moderate"
    }
  },
  [... Q2-Q5 ...]
}
````

```bash
# Bash 3.2 compatible - use parallel indexed arrays for scores/plans
FINER_SCORE_IDS=()
FINER_SCORE_VALUES=()
QUALITY_PLAN_IDS=()
QUALITY_PLAN_VALUES=()
BATCH_SIZE=5
total=${#PICOT_QUESTION_IDS[@]}

for start in $(seq 1 "$BATCH_SIZE" "$total"); do
  end=$((start + BATCH_SIZE - 1)); [ $end -gt $total ] && end=$total

  batch_qs=(); batch_ids=()
  for idx in $(seq "$start" "$end"); do
    qid="${PICOT_QUESTION_IDS[$((idx-1))]}"; batch_ids+=("$qid"); batch_qs+=("${PICOT_QUESTION_TEXTS[$((idx-1))]}")
  done

  json=$(assess_quality_batch_comprehensive "${batch_ids[@]}" "${batch_qs[@]}")

  for qid in "${batch_ids[@]}"; do
    F=$(echo "$json" | jq -r ".\"$qid\".finer.F")
    I=$(echo "$json" | jq -r ".\"$qid\".finer.I")
    N=$(echo "$json" | jq -r ".\"$qid\".finer.N")
    E=$(echo "$json" | jq -r ".\"$qid\".finer.E")
    R=$(echo "$json" | jq -r ".\"$qid\".finer.R")
    TOT=$((F+I+N+E+R)); FINER_SCORES[$qid]="$TOT"

    QUALITY_PLAN[$qid]="confidence=$(echo "$json" | jq -r ".\"$qid\".quality.confidence");triangulation=$(echo "$json" | jq -r ".\"$qid\".quality.triangulation");gaps=$(echo "$json" | jq -r ".\"$qid\".quality.gaps");complexity=$(echo "$json" | jq -r ".\"$qid\".quality.complexity")"

    [ "$TOT" -lt 10 ] && PICOT_QUESTIONS[$qid]=$(reformulate_low_finer_question "${PICOT_QUESTIONS[$qid]}")
  done
done

# Calculate and verify average
sum=0; for s in "${FINER_SCORES[@]}"; do ((sum+=s)); done
AVG_FINER_SCORE=$(echo "scale=2; $sum / $total" | bc)
if [ $(echo "$AVG_FINER_SCORE < 11.0" | bc) -eq 1 ]; then exit 1; fi
```

**Success Criteria:**
- [ ] All questions scored (FINER + Quality)
- [ ] All individual scores ≥10/15
- [ ] AVG_FINER_SCORE ≥11.0
- [ ] FINER_SCORES populated
- [ ] QUALITY_PLAN populated

**Mark 4.3 complete in TodoWrite.**

---

## Phase 4.5: Template Validation (Template Mode Only)

**Skip if domain-based dimensions.**

Verify template dimensions satisfy MECE (when using pre-defined research-type templates):

**Checks:**
1. Dimension count: 2-10 ✓
2. All template sections covered ✓
3. Dimensions semantically distinct ✓
4. Slug uniqueness ✓

Typically pre-validated in Phase 2a; re-check if custom template.

**Mark 4.5 complete in TodoWrite.**

---

## Phase 4.6: Final Validation

Execute comprehensive validation script:

**Command:**
```bash
bash scripts/validate-outputs.sh \
  --dimensions "$DIMENSION_COUNT" \
  --questions "$TOTAL_QUESTIONS" \
  --avg-finer "$AVG_FINER_SCORE" \
  --research-type "$RESEARCH_TYPE" \
  --json
```

**⛔ CRITICAL:** The `--research-type` parameter is MANDATORY. Without it, the script defaults to `generic` which expects 8-50 questions, causing validation failures for:

- `lean-canvas`: requires exactly 27 questions (9 blocks × 3, DOK-2)
- `customer-value-mapping`: requires 16-40 questions (4 dims × DOK×2 multiplier)
- `smarter-service`: requires exactly 52 questions (4 dimensions × 13)
- `b2b-ict-portfolio`: requires exactly 57 questions (1 per taxonomy category, 8 dimensions 0-7)

**Expected JSON:**
```json
{
  "valid": true,
  "dimension_count_valid": true,
  "question_count_valid": true,
  "finer_score_valid": true,
  "messages": ["All validations passed"]
}
```

**Validation Checks:**

- Dimension count: 2-10 ✓
- Question count: research-type-specific ✓
  - generic: 8-50 (DOK-based)
  - lean-canvas: 27 (DOK-2)
  - customer-value-mapping: 16-40 (DOK×2)
  - smarter-service: 52 (fixed: 5 ACT + 5 PLAN + 3 OBSERVE per dimension)
  - b2b-ict-portfolio: 57 (fixed, 8 dimensions 0-7)
- Average FINER: ≥11.0 ✓

```bash
json=$(bash scripts/validate-outputs.sh --dimensions "$DIMENSION_COUNT" --questions "$TOTAL_QUESTIONS" --avg-finer "$AVG_FINER_SCORE" --research-type "$RESEARCH_TYPE" --json)
if [ "$(echo "$json" | jq -r '.valid')" != "true" ]; then exit 1; fi
```

**Mark 4.6 complete in TodoWrite.**

---

## Self-Verification Checklist

Before marking Phase 4 complete, verify ALL items:

### Core Checks (10)

1. Phase entry gate passed (prerequisites verified)? ✅ YES / ❌ NO
2. TodoWrite initialized with Phase 4 steps? ✅ YES / ❌ NO
3. Phase 3 outputs verified (SELECTED_DIMENSIONS)? ✅ YES / ❌ NO
4. Applicable sub-phases completed (based on mode)? ✅ YES / ❌ NO
5. PICOT questions generated for ALL dimensions? ✅ YES / ❌ NO
6. ALL questions FINER scored? ✅ YES / ❌ NO
7. Average FINER ≥11.0 calculated and verified? ✅ YES / ❌ NO
8. Quality plans created for ALL questions? ✅ YES / ❌ NO
9. validate-outputs.sh executed and passed? ✅ YES / ❌ NO
10. All step todos marked completed? ✅ YES / ❌ NO

### Phase-Specific Checks

**4.1 Domain MECE (if executed):**
11. Pairwise overlap analysis completed? ✅ YES / ❌ NO / ⊘ N/A
12. All overlaps <20% verified? ✅ YES / ❌ NO / ⊘ N/A
13. Coverage mapping completed? ✅ YES / ❌ NO / ⊘ N/A
14. 100% coverage verified? ✅ YES / ❌ NO / ⊘ N/A
15. Independence checked? ✅ YES / ❌ NO / ⊘ N/A

**4.2 PICOT Generation:**
16. BATCHED generation used (per dimension)? ✅ YES / ❌ NO
17. Extended thinking with explicit PICOT reasoning? ✅ YES / ❌ NO
18. TOTAL_QUESTIONS within valid range for research type? ✅ YES / ❌ NO
19. All questions follow PICOT structure (5 components)? ✅ YES / ❌ NO
20. PICOT_QUESTIONS array populated? ✅ YES / ❌ NO

**4.3 Quality Assessment:**
21. BATCHED scoring used (5-10 per call)? ✅ YES / ❌ NO
22. Extended thinking with F/I/N/E/R reasoning? ✅ YES / ❌ NO
23. All 5 FINER criteria scored? ✅ YES / ❌ NO
24. All individual scores ≥10/15? ✅ YES / ❌ NO
25. AVG_FINER_SCORE ≥11.0 verified? ✅ YES / ❌ NO
26. Quality planning in SAME batched calls? ✅ YES / ❌ NO
27. Questions <10/15 reformulated? ✅ YES / ❌ NO / ⊘ N/A

**4.6 Final Validation:**
28. validate-outputs.sh exit code 0? ✅ YES / ❌ NO
29. Dimension count 2-10 confirmed? ✅ YES / ❌ NO
30. Question count valid for research type? ✅ YES / ❌ NO
31. Average FINER ≥11.0 confirmed? ✅ YES / ❌ NO

⛔ **IF ANY ❌ NO (excluding ⊘ N/A):** STOP. Return to incomplete step.

### Data Completeness

- ✅ Every dimension has ≥MIN_Q_PER_DIM questions
- ✅ Every question has complete PICOT structure
- ✅ Every question has FINER score ≥10/15
- ✅ Every question has quality plan entry
- ✅ All validation thresholds passed

⛔ **IF ANY INCOMPLETE:** STOP. Phase 5 requires complete data.

---

## Mark Phase 4 Complete

Update TodoWrite:
- Phase 4 → **completed**
- Phase 5 → **in_progress**

Verify:
- [ ] All success criteria checked
- [ ] All required variables set and logged
- [ ] All questions validated and quality-planned
- [ ] All self-verification items ✅ YES (or ⊘ N/A)

---

## Performance Benchmarks

**Optimization Summary:**
- Phase 4.2: Batched generation → 50-80% faster (5-9 calls vs 20-40)
- Phase 4.3: Batched scoring → 60-70% faster (2-8 calls vs 20-40)
- Phase 4.3: Merged assessment → 30-40% faster vs sequential FINER then quality
- Extended thinking: ~1-2s overhead per batch, significant quality improvement

**Expected Timing (DOK-3, 20 questions):**
- 4.1 (MECE): ~10-20s
- 4.2 (Batched PICOT): ~20-30s (was 40-80s)
- 4.3 (Comprehensive): ~25-35s (was 50-55s)
- 4.6 (Final): ~1-2s
- **Total: ~40-60s (was 90-135s, 55% improvement)**

---

## Variable Outputs Summary

| Variable | Type | Purpose | Example |
|----------|------|---------|---------|
| OVERLAP_MATRIX | String | Pairwise overlap data | "A-B:10%,A-C:12%,B-C:15%" |
| COVERAGE_PERCENTAGE | Integer | Scope coverage % | 100 |
| DEPENDENCIES | String | Dimension dependencies | "pricing→customer" |
| PICOT_QUESTIONS | Assoc Array | Questions by ID | ["dim-q1"]="question text" |
| TOTAL_QUESTIONS | Integer | Total count | 20 |
| FINER_SCORES | Assoc Array | Scores by ID | ["dim-q1"]="13" |
| AVG_FINER_SCORE | Float | Average quality | 13.2 |
| QUALITY_PLAN | Assoc Array | Quality params by ID | ["dim-q1"]="confidence=high;..." |

---

## Next Phase: Phase 4b/5 Routing

After Phase 4.6 validation passes, route based on research type:

### Route A: Execute Phase 4b (generic, smarter-service)

**IF** `RESEARCH_TYPE` is `generic` OR `smarter-service`:

1. Read [phase-4b-megatrend-proposal.md](phase-4b-megatrend-proposal.md)
2. Confirm checksum: `MEGATREND-PROPOSAL-V2`
3. Execute Phase 4b (seed megatrend proposal with user validation)
4. Verify `.metadata/seed-megatrends.yaml` was created
5. Then proceed to Phase 5

**⛔ MANDATORY:** Phase 4b is required for generic/smarter-service research types. Do NOT skip to Phase 5 without executing Phase 4b first.

### Route B: Skip Phase 4b (lean-canvas, b2b-ict-portfolio)

**IF** `RESEARCH_TYPE` is `lean-canvas` OR `b2b-ict-portfolio`:

1. Log: `[INFO] Skipping Phase 4b - not applicable for ${RESEARCH_TYPE}`
2. Proceed directly to [phase-5-entity-creation.md](phase-5-entity-creation.md)

### Routing Decision

```bash
case "$RESEARCH_TYPE" in
  generic|smarter-service)
    log_conditional INFO "Phase 4 → Phase 4b: Megatrend proposal required"
    # Execute Phase 4b before Phase 5
    ;;
  lean-canvas|b2b-ict-portfolio)
    log_conditional INFO "Phase 4 → Phase 5: Skipping Phase 4b (not applicable)"
    # Proceed directly to Phase 5
    ;;
esac
```

---

## Proceed to Phase 5

After Phase 4b completes (or is skipped for lean-canvas/b2b-ict-portfolio):

Proceed to **Phase 5: Entity Creation** ([phase-5-entity-creation.md](phase-5-entity-creation.md)) when:
- All 31 verification checks = ✅ YES (or ⊘ N/A)
- All data completeness confirmed
- Phase 4b completed (generic/smarter-service) OR skipped (lean-canvas/b2b-ict-portfolio)
- TodoWrite shows Phase 4 completed, Phase 5 in_progress

---

**Document Size:** ~9.5KB | **Type:** Execution Instruction | **Complexity:** High
**Dependencies:** MECE validation, PICOT framework, FINER criteria, validate-outputs.sh
**Performance:** ~55% faster than non-batched approach
