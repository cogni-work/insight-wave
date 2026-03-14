# Webb's Depth of Knowledge (DOK) Classification

## Overview

Webb's Depth of Knowledge framework classifies cognitive complexity of research questions into four levels, guiding dimension planning by determining appropriate depth, breadth, and total question count.

## DOK Levels and Question Planning

| DOK Level | Dimensions | Min Questions/Dim | Total Questions |
|-----------|------------|-------------------|-----------------|
| DOK-1 (Recall) | 2-3 | 4 | 8-12 |
| DOK-2 (Skills) | 3-4 | 5 | 15-20 |
| DOK-3 (Strategic) | 5-7 | 5 | 25-35 |
| DOK-4 (Extended) | 8-10 | 5 | 40-50 |

**Key principle:** Total question count is the primary target. Minimum per dimension ensures coverage; distribution can be uneven based on dimension importance.

## The Four Levels

### DOK-1: Recall and Reproduction

**Characteristics:** Retrieve existing facts, definitions, or procedures. No transformation or analysis required.

**Examples:**
- "What is the current market size of X?"
- "When was technology Y introduced?"
- "Who are the top 5 competitors in market Z?"

### DOK-2: Skills and Concepts

**Characteristics:** Apply frameworks, compare options, use standard methodologies, basic classification.

**Examples:**
- "How do solar and wind energy costs compare?"
- "What are the advantages of approach X vs. Y?"
- "Which framework best fits scenario Z?"

### DOK-3: Strategic Thinking

**Characteristics:** Reasoning across sources, evidence synthesis, pattern identification, multi-factor analysis, requires judgment.

**Examples:**
- "What factors drive renewable energy adoption?"
- "How do market dynamics influence pricing strategies?"
- "What are the barriers to technology adoption?"

### DOK-4: Extended Investigation

**Characteristics:** Complex synthesis across diverse sources, multiple analytical perspectives, interdisciplinary connections, theoretical framework development, high uncertainty.

**Examples:**
- "How will climate policy, technology innovation, and market forces interact to shape energy transition by 2040?"
- "What systemic factors explain differing outcomes across regions?"

## Key Distinction: Difficulty vs. Complexity

**Important:** DOK measures complexity, not difficulty.

**DOK-1 can be difficult** (finding obscure data, hard-to-locate statistics) **but requires only retrieval, not analysis.**

**DOK-3+ requires complexity:** Synthesizing multiple sources, identifying patterns, reasoning about causation, making evidence-based judgments.

## Applying DOK to Dimension Planning

### Step 1: Classify the Question

Assess:
1. What cognitive processes are required?
2. How many perspectives/sources need integration?
3. What level of synthesis is needed?
4. Is judgment and interpretation required?

### Step 2: Apply Planning Table

Use the DOK table above to determine:
- Total question target (8-50 based on DOK level)
- Dimension count range (2-10 based on DOK level)
- Minimum questions per dimension (4-5 based on DOK level)

**Note:** MECE validation is the primary constraint. If the question truly requires more dimensions for collective exhaustiveness, adjust accordingly.

Distribute total questions across dimensions with uneven allocation based on priority:

**Example (DOK-3, 4 dimensions, 24 total):**
- Dimension A (high priority): 8 questions
- Dimension B (medium): 6 questions
- Dimension C (medium): 6 questions
- Dimension D (lower): 4 questions (meets min of 4)

## Common Misclassifications

| Misclassification | Question | Correct DOK | Reason |
|-------------------|----------|-------------|--------|
| Over-classification | "What is the total addressable market for electric vehicles in Europe?" | DOK-1 (not DOK-3) | Requires market data retrieval, not multi-source synthesis |
| Under-classification | "How do regulatory frameworks, economic incentives, and cultural factors interact to influence renewable energy adoption across European markets?" | DOK-3/DOK-4 (not DOK-2) | Requires synthesis across regulatory, economic, and cultural dimensions with pattern identification |

## Implementation

### DOK Level Determination and Planning

```bash
# After analyzing question content, determine DOK level
DOK_LEVEL=3
log_conditional INFO "Question classified as DOK-${DOK_LEVEL}"

# Map DOK level to question targets
case "$DOK_LEVEL" in
  1) MIN_DIM=2; MAX_DIM=3; MIN_Q_PER_DIM=4; TOTAL_Q_MIN=8; TOTAL_Q_MAX=12 ;;
  2) MIN_DIM=3; MAX_DIM=4; MIN_Q_PER_DIM=5; TOTAL_Q_MIN=15; TOTAL_Q_MAX=20 ;;
  3) MIN_DIM=5; MAX_DIM=7; MIN_Q_PER_DIM=5; TOTAL_Q_MIN=25; TOTAL_Q_MAX=35 ;;
  4) MIN_DIM=8; MAX_DIM=10; MIN_Q_PER_DIM=5; TOTAL_Q_MIN=40; TOTAL_Q_MAX=50 ;;
  *) log_conditional ERROR "Invalid DOK level: ${DOK_LEVEL}"; exit 1 ;;
esac

log_conditional DEBUG "DOK-${DOK_LEVEL}: ${MIN_DIM}-${MAX_DIM} dimensions, ${TOTAL_Q_MIN}-${TOTAL_Q_MAX} total questions"
```

### Validation

```bash
# Validate total question count
if [ "$QUESTION_COUNT" -lt "$TOTAL_Q_MIN" ] || [ "$QUESTION_COUNT" -gt "$TOTAL_Q_MAX" ]; then
  log_conditional WARN "Question count (${QUESTION_COUNT}) outside DOK-${DOK_LEVEL} target (${TOTAL_Q_MIN}-${TOTAL_Q_MAX})"
fi

# Validate minimum per dimension
for dim in "${DIMENSIONS[@]}"; do
  dim_q_count=$(count_questions_for_dimension "$dim")
  if [ "$dim_q_count" -lt "$MIN_Q_PER_DIM" ]; then
    log_conditional WARN "Dimension ${dim} has ${dim_q_count} questions, below minimum ${MIN_Q_PER_DIM}"
  fi
done
```

## References

- Webb, N. L. (2002). *Depth-of-Knowledge Levels for Four Content Areas*. Language Arts.
- Hess, K. K., et al. (2009). *Cognitive Rigor Matrix*. National Center for Assessment.
