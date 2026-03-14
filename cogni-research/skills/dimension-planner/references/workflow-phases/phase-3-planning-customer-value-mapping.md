# Phase 3: Planning (customer-value-mapping)

<!-- COMPILATION METADATA -->
<!-- Source: research-types/customer-value-mapping.md v1.0 -->
<!-- Compiled: 2025-12-07 | Sprint 440 - Customer Value Mapping Implementation -->
<!-- Propagation: Regenerate via PROPAGATION-PROTOCOL.md when sources change -->

**Research Type:** `customer-value-mapping` | **Framework:** Corporate Visions Value Story

**Checksum:** `sha256:3-cvm-v1-valuestory`

**Verification:** After reading, confirm:

```text
Reference Loaded: phase-3-planning-customer-value-mapping.md | Checksum: 3-cvm-v1-valuestory
```

---

## Variables Reference

| Variable | Source | Purpose |
|----------|--------|---------|
| DIMENSION_COUNT | Phase 2 | Fixed count (4) |
| DIMENSION_SLUGS | Phase 2 | Dimension identifiers (why-change, why-now, why-you, why-pay) |
| DIMENSION_VALUE_STORY_MAP | Phase 2 | Value Story stage per dimension |
| DIMENSION_TIPS_SOURCE_MAP | Phase 2 | Source TIPS dimensions per Value Story dimension |
| DIMENSION_MIN_ENTITIES | Phase 2 | Minimum entity counts (3, 2, 3, 2) |
| CUSTOMER_NAME | Phase 2 | Target customer |
| CUSTOMER_INDUSTRY | Phase 2 | Customer's industry |
| CUSTOMER_FACTS | Phase 2 | Verified customer context (5+) |
| SOURCE_SMARTER_SERVICE_PATH | Phase 2 | Path to TIPS source project |
| SOURCE_PORTFOLIO_PATH | Phase 2 | Path to portfolio source project |
| TIPS_SELECTION_FILTERS | Phase 2 | Filters for TIPS selection |
| PORTFOLIO_SELECTION_FILTERS | Phase 2 | Filters for portfolio selection |
| QUESTION_TEXT | Phase 0 | Original question |
| PROJECT_LANGUAGE | Phase 0 | Output language |

---

## Phase Entry Gate

**Before proceeding, verify:**

1. Phase 2 todos marked complete
2. DIMENSION_COUNT = 4 with DIMENSION_SLUGS populated
3. CUSTOMER_NAME and CUSTOMER_INDUSTRY set
4. CUSTOMER_FACTS contains ≥5 verified facts
5. SOURCE_SMARTER_SERVICE_PATH and SOURCE_PORTFOLIO_PATH discovered
6. TIPS_SELECTION_FILTERS and PORTFOLIO_SELECTION_FILTERS defined

**If any missing:** STOP → Return to Phase 2.

---

## Objective

Execute Value Story-enhanced PICOT planning with cross-project source loading:

| Requirement | Solution |
|-------------|----------|
| Customer context preservation | All questions include customer name and context |
| Source entity selection | TIPS and portfolio entities selected based on filters |
| Value Story alignment | Questions mapped to persuasion stages |
| Minimum coverage | Distribution ensures minimum entities per dimension |
| Cross-project traceability | References to source entities maintained |

---

## Value Story Dimension Requirements

| Dimension | Persuasion Goal | Min Entities | Source Priority | Slide Coverage |
|-----------|-----------------|--------------|-----------------|----------------|
| **Why Change** | Disrupt Status Quo | 3 | TIPS (externe-effekte, digitale-wertetreiber) | Slides 2-5 |
| **Why Now** | Create Urgency | 2 | TIPS (Act horizon), timing research | Slides 6-9 |
| **Why You** | Differentiate | 3 | TIPS (digitales-fundament) + portfolio_refs | Slides 10-13 |
| **Why Pay** | Justify Economics | 2 | TIPS (quantified) + portfolio pricing | Slides 14-16 |

---

## PICOT Pattern Templates per Value Story Dimension

### Why Change PICOT

| Component | Template | Example |
|-----------|----------|---------|
| **P** (Population) | {CUSTOMER_NAME} and similar {CUSTOMER_INDUSTRY} organizations | "Deutsche Telekom and similar telecommunications providers" |
| **I** (Intervention) | Unconsidered needs and external forces driving change | "Hidden operational risks from legacy infrastructure" |
| **C** (Comparison) | Status quo vs. changed state | "Current manual processes vs. automated workflows" |
| **O** (Outcome) | Business impact metrics showing need for change | "20% higher operational costs without intervention" |
| **T** (Timeframe) | Near-term impact window | "Within next 12-24 months" |

### Why Now PICOT

| Component | Template | Example |
|-----------|----------|---------|
| **P** (Population) | {CUSTOMER_NAME} decision-makers and stakeholders | "CIO and digital transformation team" |
| **I** (Intervention) | Timing factors and urgency drivers | "Q2 2025 regulatory compliance deadline" |
| **C** (Comparison) | Acting now vs. delayed action | "Implementation before deadline vs. post-deadline penalties" |
| **O** (Outcome) | Cost of delay or benefit of early action | "€2M penalty avoidance, 6-month competitive advantage" |
| **T** (Timeframe) | Specific deadlines or windows | "Before March 2025 fiscal year end" |

### Why You PICOT

| Component | Template | Example |
|-----------|----------|---------|
| **P** (Population) | {CUSTOMER_NAME}'s specific capability gaps | "Lack of in-house cloud migration expertise" |
| **I** (Intervention) | Our unique solution capabilities | "Managed migration service with proven methodology" |
| **C** (Comparison) | Our approach vs. alternatives | "End-to-end managed vs. DIY or competitor offerings" |
| **O** (Outcome) | Differentiated business outcomes | "40% faster migration with 99.9% availability" |
| **T** (Timeframe) | Solution delivery timeline | "Full migration within 6 months" |

### Why Pay PICOT

| Component | Template | Example |
|-----------|----------|---------|
| **P** (Population) | {CUSTOMER_NAME} budget holders and finance | "CFO and procurement team" |
| **I** (Intervention) | Investment proposition and pricing model | "Subscription model with predictable monthly costs" |
| **C** (Comparison) | Investment vs. alternatives or do-nothing | "Our solution vs. in-house build vs. status quo" |
| **O** (Outcome) | ROI, TCO, and value metrics | "18-month payback, 35% TCO reduction over 5 years" |
| **T** (Timeframe) | ROI realization timeline | "Break-even at month 18, positive ROI by year 2" |

---

## Step 1: Initialize Phase 3 TodoWrite

Add step-level todos:

```text
- Phase 3, Step 1: Initialize [in_progress]
- Phase 3, Step 2: Preserve customer context [pending]
- Phase 3, Step 3: Load and select source TIPS [pending]
- Phase 3, Step 4: Load and select source portfolio entities [pending]
- Phase 3, Step 5: Per-dimension PICOT reasoning [pending]
- Phase 3, Step 6: Generate customer-specific research questions [pending]
- Phase 3, Step 7: Ask DOK level and calculate question distribution [pending]
- Phase 3, Step 8: Validate completeness [pending]
```

Mark Step 1 completed, Step 2 in_progress.

---

## Step 2: Preserve Customer Context

<thinking>
## Customer Context Preservation

Customer: "{CUSTOMER_NAME}"
Industry: "{CUSTOMER_INDUSTRY}"

**Context Integration Requirements:**

1. Customer name appears in ALL PICOT Population components
2. Industry context informs ALL research questions
3. Verified facts from Phase 2 anchor each dimension:

**Fact-to-Dimension Mapping:**

- Fact 1 (Industry Position): [FILL IN] → Primary: why-change
- Fact 2 (Strategic Priorities): [FILL IN] → Primary: why-now, why-you
- Fact 3 (Technology Landscape): [FILL IN] → Primary: why-you
- Fact 4 (Competitive Pressure): [FILL IN] → Primary: why-change, why-now
- Fact 5 (Financial Context): [FILL IN] → Primary: why-pay

**Context Variables:**

- Solution provider: [FILL IN from input or portfolio project]
- Budget cycle: [FILL IN from customer facts]
- Key competitors: [FILL IN from customer facts]
- Strategic initiatives: [FILL IN from customer facts]
</thinking>

**Store Customer Context:**

```bash
# Customer context for PICOT integration
CUSTOMER_CONTEXT[name] = "$CUSTOMER_NAME"
CUSTOMER_CONTEXT[industry] = "$CUSTOMER_INDUSTRY"
CUSTOMER_CONTEXT[solution_provider] = "$SOLUTION_PROVIDER"
CUSTOMER_CONTEXT[budget_cycle] = "$extracted_budget_cycle"
CUSTOMER_CONTEXT[competitors] = "$extracted_competitors"
CUSTOMER_CONTEXT[strategic_initiatives] = "$extracted_initiatives"

# Fact-to-dimension mapping
FACT_DIMENSION_MAP[fact_1] = "why-change"
FACT_DIMENSION_MAP[fact_2] = "why-now,why-you"
FACT_DIMENSION_MAP[fact_3] = "why-you"
FACT_DIMENSION_MAP[fact_4] = "why-change,why-now"
FACT_DIMENSION_MAP[fact_5] = "why-pay"

log_conditional INFO "[customer-value-mapping] Customer context preserved for $CUSTOMER_NAME"
```

Mark Step 2 completed, Step 3 in_progress.

---

## Step 3: Load and Select Source TIPS

### TIPS Selection Process

<thinking>
## TIPS Selection Analysis

Source Project: {SOURCE_SMARTER_SERVICE_PATH}
Available TIPS: {TIPS_COUNT} trends

**Filter Application:**

1. Horizon Filter:
   - Include: Act, Plan
   - Exclude: Observe
   - Result: ~24 trends (assuming 8 per horizon)

2. Dimension Priority Filter:
   - Priority 1: externe-effekte (for why-change)
   - Priority 2: digitale-wertetreiber (for why-change, why-pay)
   - Priority 3: digitales-fundament (for why-you)
   - Priority 4: neue-horizonte (for why-now, why-you)

3. Portfolio Reference Filter:
   - Prefer TIPS with populated portfolio_refs[]
   - Count with refs: [COUNT]
   - Count without refs: [COUNT]

4. Keyword Match Filter:
   - Customer pain points: [LIST from customer facts]
   - Matching TIPS: [COUNT]

**Selection Summary:**

- Total after filters: [COUNT]
- Selected for loading: [10-15]
- By dimension mapping:
  - why-change sources: [COUNT]
  - why-now sources: [COUNT]
  - why-you sources: [COUNT]
  - why-pay sources: [COUNT]
</thinking>

### Variable Assignment

```bash
# Load TIPS from source project
TIPS_SOURCE_DIR="$SOURCE_SMARTER_SERVICE_PATH/11-trends"
TIPS_LOADED=()
TIPS_SELECTED=()

# Apply filters
for tips_file in "$TIPS_SOURCE_DIR"/trend-*.md; do
  horizon=$(extract_frontmatter "$tips_file" "planning_horizon")
  dimension=$(extract_frontmatter "$tips_file" "dimension")
  has_portfolio_refs=$(check_portfolio_refs "$tips_file")

  # Filter by horizon
  if [ "$horizon" == "observe" ]; then
    continue
  fi

  # Prioritize by dimension
  priority=$(get_dimension_priority "$dimension")

  # Prioritize by portfolio refs
  if [ "$has_portfolio_refs" = "true" ]; then
    ((priority += 10))
  fi

  TIPS_LOADED+=("$tips_file:$priority")
done

# Sort by priority and select top 10-15
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
TIPS_SELECTED=()
while IFS= read -r item; do
    TIPS_SELECTED+=("$item")
done < <(sort_by_priority "${TIPS_LOADED[@]}" | head -15)

log_conditional INFO "[customer-value-mapping] TIPS loaded: ${#TIPS_LOADED[@]}, selected: ${#TIPS_SELECTED[@]}"

# Map selected TIPS to Value Story dimensions
for tips in "${TIPS_SELECTED[@]}"; do
  source_dim=$(extract_frontmatter "$tips" "dimension")
  case "$source_dim" in
    "externe-effekte"|"digitale-wertetreiber")
      TIPS_BY_VALUE_STORY["why-change"]+="$tips "
      ;;
    "neue-horizonte")
      TIPS_BY_VALUE_STORY["why-now"]+="$tips "
      TIPS_BY_VALUE_STORY["why-you"]+="$tips "
      ;;
    "digitales-fundament")
      TIPS_BY_VALUE_STORY["why-you"]+="$tips "
      ;;
  esac

  # Why Pay gets quantified TIPS from any dimension
  if has_quantified_metrics "$tips"; then
    TIPS_BY_VALUE_STORY["why-pay"]+="$tips "
  fi
done
```

Mark Step 3 completed, Step 4 in_progress.

---

## Step 4: Load and Select Source Portfolio Entities

### Portfolio Selection Process

<thinking>
## Portfolio Selection Analysis

Source Project: {SOURCE_PORTFOLIO_PATH}
Available Entities: {PORTFOLIO_COUNT} entities

**Filter Application:**

1. Service Horizon Filter:
   - Include: Current Offerings, Emerging Services
   - Exclude: Future Roadmap
   - Result: ~35-40 entities (70-80%)

2. Industry Vertical Filter:
   - Customer industry: {CUSTOMER_INDUSTRY}
   - Matching entities: [COUNT]

3. Referenced by TIPS Filter:
   - Portfolio IDs in selected TIPS portfolio_refs[]: [LIST]
   - Matching entities: [COUNT]

**Selection Summary:**

- Total after filters: [COUNT]
- Selected for loading: [5-10]
- By relevance:
  - Referenced by TIPS: [COUNT] (highest priority)
  - Industry match: [COUNT]
  - Service domain match: [COUNT]
</thinking>

### Variable Assignment

```bash
# Load portfolio from source project
PORTFOLIO_SOURCE_DIR="$SOURCE_PORTFOLIO_PATH/11-trends"
PORTFOLIO_LOADED=()
PORTFOLIO_SELECTED=()

# Extract portfolio IDs referenced by selected TIPS
TIPS_PORTFOLIO_REFS=()
for tips in "${TIPS_SELECTED[@]}"; do
  refs=$(extract_frontmatter "$tips" "portfolio_refs")
  TIPS_PORTFOLIO_REFS+=($refs)
done
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
unique_refs=()
while IFS= read -r ref; do
    unique_refs+=("$ref")
done < <(echo "${TIPS_PORTFOLIO_REFS[@]}" | tr ' ' '\n' | sort -u)
TIPS_PORTFOLIO_REFS=("${unique_refs[@]}")

cat > /tmp/dp-p3-filter-portfolio.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Apply filters
for portfolio_file in "$PORTFOLIO_SOURCE_DIR"/portfolio-*.md; do
  service_horizon=$(extract_frontmatter "$portfolio_file" "service_horizon")
  industry_verticals=$(extract_frontmatter "$portfolio_file" "industry_verticals")
  portfolio_id=$(extract_frontmatter "$portfolio_file" "dc:identifier")

  # Filter by service horizon
  if [ "$service_horizon" = "future-roadmap" ]; then
    continue
  fi

  priority=0

  # Priority boost if referenced by TIPS
  if [[ " ${TIPS_PORTFOLIO_REFS[@]} " =~ " $portfolio_id " ]]; then
    ((priority += 20))
  fi

  # Priority boost if industry matches
  if [[ "$industry_verticals" == *"$CUSTOMER_INDUSTRY"* ]]; then
    ((priority += 10))
  fi

  PORTFOLIO_LOADED+=("$portfolio_file:$priority")
done
SCRIPT_EOF
chmod +x /tmp/dp-p3-filter-portfolio.sh && bash /tmp/dp-p3-filter-portfolio.sh

# Sort by priority and select top 5-10
# Bash 3.2 compatible (mapfile requires Bash 4.0+)
PORTFOLIO_SELECTED=()
while IFS= read -r item; do
    PORTFOLIO_SELECTED+=("$item")
done < <(sort_by_priority "${PORTFOLIO_LOADED[@]}" | head -10)

log_conditional INFO "[customer-value-mapping] Portfolio loaded: ${#PORTFOLIO_LOADED[@]}, selected: ${#PORTFOLIO_SELECTED[@]}"

# Map to Value Story dimensions (portfolio primarily for Why You and Why Pay)
for portfolio in "${PORTFOLIO_SELECTED[@]}"; do
  PORTFOLIO_BY_VALUE_STORY["why-you"]+="$portfolio "
  PORTFOLIO_BY_VALUE_STORY["why-pay"]+="$portfolio "
done
```

Mark Step 4 completed, Step 5 in_progress.

---

## Step 5: Per-Dimension PICOT Reasoning

For each of the 4 Value Story dimensions, apply this COT template:

<thinking>
## PICOT Reasoning: {DIMENSION_NAME}

**Value Story Stage:** {stage}
**Persuasion Goal:** {goal}
**Minimum Entities:** {min_count}
**Slide Coverage:** {slides}

**Source Inputs:**

- Selected TIPS: {count} trends
- Selected Portfolio: {count} entities (if applicable)
- Customer Facts: {relevant facts}

**P (Population):**
- Base: "{CUSTOMER_NAME} and similar {CUSTOMER_INDUSTRY} organizations"
- Refinement based on dimension: ____________

**I (Intervention):**
- Value Story focus: {disrupt/urgency/differentiate/justify}
- Key themes from sources: ____________

**C (Comparison):**
- Value Story contrast: {status quo vs change / now vs later / us vs them / invest vs not}
- Specific comparison: ____________

**O (Outcome):**
- Persuasion metric: {pain point / cost of delay / capability gap / ROI}
- Quantification from sources: ____________

**T (Timeframe):**
- Value Story timing: {impact window / deadline / delivery / payback}
- Specific timeframe: ____________

**Source Citations:**

- TIPS to cite: [LIST trend IDs]
- Portfolio to cite: [LIST portfolio IDs if applicable]
- Customer facts to include: [LIST]
</thinking>

### PICOT Storage

```bash
# Store PICOT patterns per dimension
for slug in $DIMENSION_SLUGS; do
  DIMENSION_PICOT[$slug]="$P|$I|$C|$O|$T"
  DIMENSION_SOURCE_TIPS[$slug]="${TIPS_BY_VALUE_STORY[$slug]}"
  DIMENSION_SOURCE_PORTFOLIO[$slug]="${PORTFOLIO_BY_VALUE_STORY[$slug]}"
  DIMENSION_CUSTOMER_FACTS[$slug]="${relevant_facts}"
done

log_conditional INFO "[customer-value-mapping] PICOT patterns generated for all 4 dimensions"
```

Mark Step 5 completed, Step 6 in_progress.

---

## Step 6: Generate Customer-Specific Research Questions

### Question Generation Strategy

For each dimension, generate research questions that will:

1. Fill gaps not covered by loaded TIPS/portfolio
2. Gather customer-specific context
3. Find quantifiable evidence for the Value Story stage

### Question Types per Dimension

| Dimension | Question Types | Target Count (DOK-3 default) |
|-----------|---------------|------------------------------|
| **Why Change** | Industry disruption, hidden risks, competitive gaps | 8 |
| **Why Now** | Regulatory deadlines, budget cycles, competitive moves | 8 |
| **Why You** | Capability assessment, vendor comparison, proof points | 8 |
| **Why Pay** | ROI benchmarks, TCO analysis, budget allocation | 8 |

*Note: Target count = DOK base × 2 multiplier. With DOK-3 (default): 4 × 2 = 8 per dimension.*

### Variable Assignment

```bash
# Generate research questions per dimension
RESEARCH_QUESTIONS=()

# Why Change questions
add_question "why-change" "What unconsidered operational risks does $CUSTOMER_NAME face from legacy infrastructure?"
add_question "why-change" "Which industry trends are creating competitive pressure for $CUSTOMER_INDUSTRY companies?"
add_question "why-change" "What hidden costs is $CUSTOMER_NAME incurring from current approaches?"

# Why Now questions
add_question "why-now" "What regulatory deadlines affect $CUSTOMER_NAME in $CUSTOMER_INDUSTRY?"
add_question "why-now" "When is $CUSTOMER_NAME's next budget cycle for technology investments?"
add_question "why-now" "What competitive moves by $CUSTOMER_COMPETITORS create urgency?"

# Why You questions
add_question "why-you" "What capability gaps does $CUSTOMER_NAME have for digital transformation?"
add_question "why-you" "How does $SOLUTION_PROVIDER's approach differ from alternatives?"
add_question "why-you" "What proof points exist for similar $CUSTOMER_INDUSTRY implementations?"

# Why Pay questions
add_question "why-pay" "What ROI have similar $CUSTOMER_INDUSTRY companies achieved?"
add_question "why-pay" "What is $CUSTOMER_NAME's typical technology investment payback expectation?"
add_question "why-pay" "How does TCO compare to in-house or alternative approaches?"

TOTAL_RESEARCH_QUESTIONS=${#RESEARCH_QUESTIONS[@]}
log_conditional INFO "[customer-value-mapping] Generated $TOTAL_RESEARCH_QUESTIONS research questions"
```

Mark Step 6 completed, Step 7 in_progress.

---

## Step 7: Calculate Question Distribution (DOK-Based)

### DOK Level Selection

Customer-value-mapping uses **DOK-based question distribution with 2× multiplier**.

**⚠️ ASK USER for DOK level:**

```text
What research depth is needed for this customer value mapping?

DOK-1 (Recall): Basic fact-gathering → 4 questions/dimension (16 total)
DOK-2 (Skills): Framework application → 6 questions/dimension (24 total)
DOK-3 (Strategic): Multi-source synthesis → 8 questions/dimension (32 total) [DEFAULT]
DOK-4 (Extended): Complex investigation → 10 questions/dimension (40 total)

Enter DOK level (1-4) [default: 3]:
```

### DOK Formula with 2× Multiplier

| DOK Level | Base Q/Dim | × Multiplier | Q/Dim | Total (4 dims) |
|-----------|------------|--------------|-------|----------------|
| DOK-1     | 2          | 2×           | 4     | 16             |
| DOK-2     | 3          | 2×           | 6     | 24             |
| DOK-3     | 4          | 2×           | **8** | **32**         |
| DOK-4     | 5          | 2×           | 10    | 40             |

**Rationale for 2× Multiplier:**
Customer value mapping requires deeper research per dimension because:
- Cross-project source integration (TIPS + portfolio)
- Customer-specific context requirements
- Value Story persuasion evidence needs
- Multi-stakeholder consideration (buyer, user, finance)

### Variable Assignment

```bash
# Ask user for DOK level (default: 3)
DOK_LEVEL=${USER_DOK_SELECTION:-3}
DOK_MULTIPLIER=2

# DOK base questions per dimension
case "$DOK_LEVEL" in
  1) DOK_BASE_Q_PER_DIM=2 ;;
  2) DOK_BASE_Q_PER_DIM=3 ;;
  3) DOK_BASE_Q_PER_DIM=4 ;;
  4) DOK_BASE_Q_PER_DIM=5 ;;
  *) log_conditional ERROR "Invalid DOK level: $DOK_LEVEL"; exit 1 ;;
esac

# Apply 2× multiplier
QUESTIONS_PER_DIMENSION=$((DOK_BASE_Q_PER_DIM * DOK_MULTIPLIER))
DIMENSION_COUNT=4
TOTAL_QUESTION_TARGET=$((DIMENSION_COUNT * QUESTIONS_PER_DIMENSION))

# Equal distribution across all 4 dimensions
DIMENSION_QUESTION_TARGETS["why-change"]=$QUESTIONS_PER_DIMENSION
DIMENSION_QUESTION_TARGETS["why-now"]=$QUESTIONS_PER_DIMENSION
DIMENSION_QUESTION_TARGETS["why-you"]=$QUESTIONS_PER_DIMENSION
DIMENSION_QUESTION_TARGETS["why-pay"]=$QUESTIONS_PER_DIMENSION

log_conditional INFO "[customer-value-mapping] DOK-$DOK_LEVEL with 2× multiplier: $QUESTIONS_PER_DIMENSION q/dim, $TOTAL_QUESTION_TARGET total"
```

Mark Step 7 completed, Step 8 in_progress.

---

## Step 8: Validate Completeness

### Validation Checklist

**Core Requirements (all must pass):**

- [ ] All 4 dimensions have PICOT patterns (5 components each)
- [ ] Customer context preserved (name, industry in all PILOTs)
- [ ] Source TIPS loaded and mapped to dimensions
- [ ] Source portfolio loaded and mapped to dimensions
- [ ] Research questions generated for all dimensions
- [ ] DOK level selected (user asked, default=3)
- [ ] Question distribution follows DOK × 2 formula (16-40 total)

**Source Coverage Validation:**

- [ ] TIPS selected: 10-15 trends
- [ ] Portfolio selected: 5-10 entities
- [ ] All 4 dimensions have source coverage

**Customer Context Validation:**

- [ ] CUSTOMER_NAME appears in all Population components
- [ ] At least 1 customer fact anchors each dimension
- [ ] Research questions reference customer-specific context

**If any check fails:** Return to relevant step.

Mark Step 8 completed, Phase 3 todos completed.

---

## Phase Completion

**All must be YES before Phase 4:**

- [ ] Value Story stage mapped per dimension
- [ ] All 4 PICOT patterns COT-reasoned with customer context
- [ ] Source TIPS selected and mapped (10-15)
- [ ] Source portfolio selected and mapped (5-10)
- [ ] Customer-specific research questions generated
- [ ] DOK level asked from user (default=3)
- [ ] Question distribution follows DOK × 2 formula
- [ ] All validation checks passed

---

## Integration Points

**Phase 4 (trends-creator) reads:**

- `DIMENSION_PICOT` → Base patterns
- `DIMENSION_SOURCE_TIPS` → TIPS to load for entity creation
- `DIMENSION_SOURCE_PORTFOLIO` → Portfolio to reference
- `DIMENSION_CUSTOMER_FACTS` → Context for COT reasoning
- `RESEARCH_QUESTIONS` → Questions for web research

**Phase 4 (synthesis-hub) reads:**

- `CUSTOMER_CONTEXT` → Report personalization
- `DIMENSION_VALUE_STORY_MAP` → Report structure (slides)
- All source references for citation

### Entity Schema (Phase 4)

customer-need-mapping entities include:

```json
{
  "dimension": "why-change|why-now|why-you|why-pay",
  "value_story_stage": "disrupt-status-quo|create-urgency|differentiate|justify-economics",
  "customer_name": "{CUSTOMER_NAME}",
  "customer_context": "{specific relevance}",
  "cot_reasoning": "{2-step: Need → TIPS → Portfolio}",
  "tips_trend_ref": "[[source-project/11-trends/data/trend-xxx]]",
  "portfolio_refs": ["[[portfolio-project/11-trends/data/portfolio-xxx]]"],
  "slide_coverage": "Slides X-Y",
  "source_customer_facts": ["fact_1", "fact_2"]
}
```

---

## Next Phase

Proceed to Phase 4 (trends-creator) [phase-4-synthesis-customer-value-mapping.md](../../trends-creator/references/phase-workflows/phase-4-synthesis-customer-value-mapping.md) when all criteria met.

**Phase 4 will:**

1. Load selected TIPS and portfolio entities
2. Execute web research for generated questions
3. Create customer-need-mapping entities with COT reasoning
4. Link to source TIPS and portfolio via wikilinks

---

## Error Handling

| Scenario | Response |
|----------|----------|
| TIPS selection < 10 | Log warning, proceed with available |
| Portfolio selection < 5 | Log warning, proceed with available |
| Customer context incomplete | Exit 1, return to Phase 2 |
| PICOT missing customer name | Exit 1, regenerate with context |
| Dimension has no source coverage | Generate additional research questions |
| Minimum entity target not achievable | Adjust question distribution |

---

**Size: ~9.5KB** | Self-contained (no runtime file loading) | Value Story Framework
