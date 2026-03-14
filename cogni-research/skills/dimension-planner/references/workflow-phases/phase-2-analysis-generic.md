# Phase 2: Analysis (generic)

**Research Type:** `generic` | **Framework:** Domain-Based (DOK-Adaptive)

**Reference Checksum:** `sha256:2a-generic`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-2-analysis-generic.md | Checksum: 2a-generic
```

---

## ⛔ Phase Entry Verification

**Before proceeding:**

1. Verify Phase 1 todos marked complete in TodoWrite
2. Verify Phase 1 outputs exist:
   - RESEARCH_TYPE variable set to `generic` (or omitted)
   - DIMENSIONS_MODE variable set to `domain-based`
   - Mode detection logged

**If any output missing:** STOP. Return to Phase 1. Complete missing steps.

---

## Step 0.5: Initialize Phase 2 TodoWrite

Add step-level todos for Phase 2:

```markdown
TodoWrite - Add these step-level todos:
- Phase 2, Step 1: Read DOK classification reference [in_progress]
- Phase 2, Step 2: Classify question complexity using Webb's DOK [pending]
- Phase 2, Step 3: Assign dimension and question targets [pending]
- Phase 2, Step 4: Validate outputs and mark complete [pending]
```

---

## Objective

Analyze question complexity using Webb's Depth of Knowledge (DOK) framework with extended thinking to determine planning parameters for domain-based dimension generation.

## Prerequisites

- Question loaded (Phase 1)
- DIMENSIONS_MODE = `domain-based` (Phase 1)
- RESEARCH_TYPE = `generic` or omitted (Phase 1)

---

## DOK Classification Framework

### Purpose

Assess question complexity using Webb's Depth of Knowledge framework with extended thinking for accurate dimension/question planning.

### DOK Levels & Parameters

| Level | Name | Dimensions | Q/Dim | Total Q |
|-------|------|------------|-------|---------|
| 1 | Recall | 2-3 | 4 | 8-12 |
| 2 | Skills/Concepts | 3-4 | 5 | 15-20 |
| 3 | Strategic Thinking | 5-7 | 5 | 25-35 |
| 4 | Extended Investigation | 8-10 | 5 | 40-50 |

### Classification Indicators

**DOK-1 (Recall):** "What are...", "List...", "Define..." - Single source, straightforward facts

**DOK-2 (Skills/Concepts):** "How does...", "Compare...", "Apply..." - Multiple related sources, simple procedural reasoning

**DOK-3 (Strategic Thinking):** "Why is...", "Analyze impact...", "Develop strategy..." - Multiple sources, cross-domain synthesis, complex reasoning

**DOK-4 (Extended Investigation):** "Design solution...", "Evaluate alternatives...", "Create model..." - Novel trends, integration across multiple domains

---

## Step 1: Read DOK Classification Reference

**Before proceeding:** Review the complete DOK classification framework.

**Reference:** [../../../../references/dok-classification.md](../../../../references/dok-classification.md)

**Key concepts to understand:**
- Webb's DOK levels (1-4)
- Verb complexity mapping
- Source material requirements
- Cognitive depth assessment
- Time investment patterns

---

## Step 2: Classify Question Complexity

### Extended Thinking Template

When classifying question complexity, use this structured reasoning:

```
<thinking>
Analyzing question complexity via Webb's Depth of Knowledge framework:

**Question Text:**
[full question text]

**Verb Analysis:**
Present verbs: [list action verbs from question]
DOK mapping:
- Recall verbs (define, list, identify, name, state): DOK-1
- Skills verbs (analyze, compare, categorize, explain, infer): DOK-2
- Strategic verbs (evaluate, synthesize, formulate, create, design): DOK-3
- Extended verbs (design system, prove theory, critique framework, develop model): DOK-4
Observed verb complexity: DOK-[level] indicators present

**Source Material Assessment:**
Sources needed: [single source / multiple related sources / multiple diverse sources / cross-domain synthesis]
Integration complexity: [simple lookup / basic synthesis / strategic integration / extended investigation]
Evidence: DOK-[level] source requirements

**Cognitive Depth:**
Thinking required: [recall facts / apply skills / strategic reasoning / extended investigation]
Time investment: [brief / moderate / significant / extensive]
Reasoning complexity: [single-step / multi-step / cross-domain / novel synthesis]
Evidence: DOK-[level] cognitive demands

**Final Classification:**
Based on verb analysis (DOK-[level]), source assessment (DOK-[level]), and cognitive depth (DOK-[level]):
Classified as: DOK-[1/2/3/4]

**Dimension Planning:**
DOK-[level] → [X-Y] dimensions, [N] questions per dimension, [total range] total questions
Dimension range: MIN_DIMS=[X], MAX_DIMS=[Y]
Questions per dimension: MIN_Q_PER_DIM=[N]
Total question target: TOTAL_Q_MIN=[min], TOTAL_Q_MAX=[max]
</thinking>

Result: DOK-[level] classification with dimension parameters set
```

### Classification Steps

1. Read QUESTION_TEXT carefully - Identify verbs, scope, complexity indicators
2. Analyze verbs with extended thinking - Map to DOK levels
3. Count information sources required - Recall: 1, Skills: 2-3, Strategic: 3-5, Extended: 5+
4. Assess reasoning depth - Single-step, multi-step, cross-domain synthesis
5. Determine DOK level - Match to indicators with explicit reasoning
6. Select dimension range - Use DOK to dimension mapping

---

## Step 3: Assign Dimension and Question Targets

### Variable Assignment

```bash
# Phase start logging - clearly indicates research type
log_phase "Phase 2: Analysis (generic)" "start"
log_conditional INFO "[generic] Applying DOK classification framework"

# Classify with extended thinking reasoning
DOK_LEVEL=$(evaluate_question_complexity_with_thinking "$QUESTION_TEXT")  # Returns 1, 2, 3, or 4
log_conditional INFO "[generic] DOK_LEVEL=$DOK_LEVEL"

# Dimension count and question targets by DOK
case "$DOK_LEVEL" in
  1) MIN_DIMS=2; MAX_DIMS=3; MIN_Q_PER_DIM=4; TOTAL_Q_MIN=8; TOTAL_Q_MAX=12 ;;
  2) MIN_DIMS=3; MAX_DIMS=4; MIN_Q_PER_DIM=5; TOTAL_Q_MIN=15; TOTAL_Q_MAX=20 ;;
  3) MIN_DIMS=5; MAX_DIMS=7; MIN_Q_PER_DIM=5; TOTAL_Q_MIN=25; TOTAL_Q_MAX=35 ;;
  4) MIN_DIMS=8; MAX_DIMS=10; MIN_Q_PER_DIM=5; TOTAL_Q_MIN=40; TOTAL_Q_MAX=50 ;;
esac

log_conditional INFO "[generic] Dimension range: $MIN_DIMS-$MAX_DIMS, Questions/dim: $MIN_Q_PER_DIM, Total target: $TOTAL_Q_MIN-$TOTAL_Q_MAX"
```

### Variables Set

| Variable | Purpose | Example Values |
|----------|---------|----------------|
| DOK_LEVEL | Complexity assessment | 1, 2, 3, or 4 |
| MIN_DIMS | Minimum dimension count | 2, 3, 5, or 8 |
| MAX_DIMS | Maximum dimension count | 3, 4, 7, or 10 |
| MIN_Q_PER_DIM | Questions per dimension | 4 or 5 |
| TOTAL_Q_MIN | Minimum total questions | 8, 15, 25, or 40 |
| TOTAL_Q_MAX | Maximum total questions | 12, 20, 35, or 50 |

---

## Step 4: Validate and Complete

### Success Criteria (Domain-Based)

- [ ] DOK_LEVEL determined (1-4) using extended thinking
- [ ] Extended thinking template applied with explicit verb/source/depth analysis
- [ ] MIN_DIMS and MAX_DIMS set based on DOK
- [ ] MIN_Q_PER_DIM, TOTAL_Q_MIN, TOTAL_Q_MAX set
- [ ] Classification logged with rationale
- [ ] All variables documented for Phase 3

### Logging

```bash
log_conditional INFO "[generic] Phase 2 Complete: DOK-${DOK_LEVEL} classification"
log_conditional INFO "[generic] Dimension range: ${MIN_DIMS}-${MAX_DIMS}"
log_conditional INFO "[generic] Questions per dimension: ${MIN_Q_PER_DIM}"
log_conditional INFO "[generic] Total question target: ${TOTAL_Q_MIN}-${TOTAL_Q_MAX}"
log_phase "Phase 2: Analysis (generic)" "complete"
```

---

## Self-Verification Before Completion

**Verify all steps completed:**

1. Did you run the phase entry verification gate? ✅ YES / ❌ NO
2. Did you initialize Phase 2 TodoWrite with step-level tasks? ✅ YES / ❌ NO
3. Did you read the DOK classification reference? ✅ YES / ❌ NO
4. Did you apply the extended thinking template? ✅ YES / ❌ NO
5. Did you classify the question using Webb's DOK framework (1-4)? ✅ YES / ❌ NO
6. Did you perform explicit verb/source/depth analysis? ✅ YES / ❌ NO
7. Did you set dimension ranges (MIN_DIMS, MAX_DIMS)? ✅ YES / ❌ NO
8. Did you set question targets (MIN_Q_PER_DIM, TOTAL_Q_MIN, TOTAL_Q_MAX)? ✅ YES / ❌ NO
9. Did you log the classification results? ✅ YES / ❌ NO
10. Did you mark all Phase 2 step-level todos as completed? ✅ YES / ❌ NO

⛔ **IF ANY NO:** STOP. Return to incomplete step.

---

## Phase Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 3

- [ ] Phase entry verification gate passed
- [ ] DOK classification reference read
- [ ] Extended thinking analysis performed
- [ ] DOK level determined (1-4) with explicit reasoning
- [ ] Dimension ranges set (MIN_DIMS, MAX_DIMS)
- [ ] Question targets set (MIN_Q_PER_DIM, TOTAL_Q_MIN, TOTAL_Q_MAX)
- [ ] All success criteria met
- [ ] All required variables set and logged
- [ ] All step-level todos marked completed
- [ ] All self-verification questions answered YES
- [ ] Phase 2 todo marked completed in TodoWrite

**Mark Phase 2 todo as completed before proceeding to Phase 3.**

---

## Next Phase

Proceed to [phase-3-planning-generic.md](phase-3-planning-generic.md) when all criteria met.

**Next step:** Phase 3 - Domain Template Selection and Dimension Generation

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Question text missing or empty | Exit 1, log error |
| DOK classification ambiguous | Use conservative lower level, log warning |
| Extended thinking incomplete | Retry classification with full template |
| Variable assignment failed | Exit 1, log missing variable name |

---

**Size: ~5.2KB** | Dependencies: Phase 1 mode determination, dok-classification.md reference
