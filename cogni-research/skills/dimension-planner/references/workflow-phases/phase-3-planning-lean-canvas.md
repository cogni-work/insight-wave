# Phase 3: Planning (lean-canvas)

<!-- COMPILATION METADATA -->
<!-- Source WHAT: research-types/lean-canvas.md v3.0 -->
<!-- Compiled Date: 2025-12-04 -->
<!-- Compiled By: Sprint 438 -->
<!-- Propagation: When source WHAT files change, regenerate this file using PROPAGATION-PROTOCOL.md -->

**Research Type:** `lean-canvas` | **Framework:** Ash Maurya's Lean Canvas (9 Blocks)

**Reference Checksum:** `sha256:3-lean-canvas-v3`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-3-planning-lean-canvas.md | Checksum: 3-lean-canvas
```

---

## Variables Reference

| Variable | Source | Purpose | Example Values |
|----------|--------|---------|----------------|
| DIMENSION_COUNT | Phase 2 | Fixed dimension count | 9 (always) |
| DIMENSION_SLUGS | Phase 2 | Canvas block identifiers | problem customer-segments value-proposition solution channels revenue-streams cost-structure key-metrics unfair-advantage |
| DIMENSION_SPECS | Phase 2 | Dimension metadata | Array of slug:Canvas Block Name tuples |
| BUSINESS_STAGE | Phase 2 | Company maturity | pre-launch, pmf, scaling |
| BUSINESS_TYPE | Phase 2 | Business model type | b2b-saas, marketplace, hardware, etc. |
| QUESTION_TEXT | Phase 0 | Original question | User's research question |
| PROJECT_LANGUAGE | Phase 0 | Output language | en, de |
| DIMENSION_CONTEXT | This phase | Preserved question context | Organizing concept, audience, etc. |
| PICOT_OVERRIDES | This phase | Context customization | population, comparison_focus, etc. |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| DIMENSION_COUNT ≠ 9 | Exit 1, return to Phase 2 |
| DIMENSION_SPECS empty | Exit 1, return to Phase 2 |
| BUSINESS_STAGE invalid | Default to "pmf", log warning |
| Empty organizing concept | Use canvas block names as-is (not an error) |
| BUSINESS_TYPE missing | Default to "generic", log INFO |
| PICOT pattern missing for dimension | Exit 1, invalid template |

---

## ⛔ Phase Entry Verification

**Before proceeding:**

1. Verify Phase 2 todos marked complete in TodoWrite
2. Verify Phase 2 outputs exist:
   - DIMENSION_COUNT = 9
   - DIMENSION_SLUGS populated (9 slugs)
   - DIMENSION_SPECS populated
   - Business context extracted (BUSINESS_STAGE, BUSINESS_TYPE)
   - Lean Canvas framework context available (embedded in Phase 2)

**If any output missing:** STOP. Return to Phase 2. Complete missing steps.

---

## Step 0.5: Initialize Phase 3 TodoWrite

Add step-level todos for Phase 3:

```markdown
TodoWrite - Add these step-level todos:
- Phase 3, Step 0: Preserve original question context [in_progress]
- Phase 3, Step 1: Apply embedded canvas-specific PICOT patterns [pending]
- Phase 3, Step 2: Apply DOK-2 question distribution (3 per block) [pending]
- Phase 3, Step 3: Customize PICOT with business context [pending]
- Phase 3, Step 4: Map evidence patterns per canvas block [pending]
- Phase 3, Step 5: Calculate question targets [pending]
- Phase 3, Step 6: Validate PICOT completeness [pending]
```

---

## Objective

Execute Lean Canvas planning with DOK-2 based question distribution (3 questions per block, 27 total). Customize canvas-specific PICOT patterns with business model context, competitive intelligence requirements, and evidence pattern mapping.

## Prerequisites

- DIMENSION_COUNT = 9 (Phase 2)
- DIMENSION_SPECS loaded (Phase 2)
- Business context extracted (Phase 2)
- Lean Canvas framework context available (Phase 2)
- PROJECT_LANGUAGE loaded from Phase 0

---

## Step 3.0: Preserve Original Question Context

```bash
# Phase start logging - clearly indicates research type
log_phase "Phase 3: Planning (lean-canvas)" "start"
log_conditional INFO "[lean-canvas] Preserving original question context"
```

<thinking>
Before applying canvas templates, analyze the original question to preserve the user's intent:

1. **Organizing concept**: Identify the core framing noun phrase (e.g., "Risks", "Opportunities", "Validation priorities", "Assumptions")
   - Look in question title and opening sentence
   - Preserve the exact term the user chose - it reflects their mental model

2. **Target audience specificity**: Note who this is for
   - Generic: "target customer segment"
   - Specific: "B2B SaaS startup", "marketplace platform", "hardware product"
   - Preserve full qualifiers - they indicate the business model context

3. **Action orientation**: Determine question type
   - Actionable: "how should we validate", "what steps to test"
   - Descriptive: "what are the key assumptions", "which risks"
   - Analytical: "why do similar products fail", "what explains"

4. **Stage-specific focus**: Note explicit or implicit stage mentions
   - Pre-launch: "before launch", "initial validation", "MVP testing"
   - Product-Market Fit: "seeking PMF", "finding market", "early customers"
   - Scaling: "scaling up", "growth stage", "market expansion"
   - Use BUSINESS_STAGE from Phase 2 as reference

5. **Concrete examples required**: Check for competitor/comparable asks
   - "comparable company examples", "competitive benchmarks", "case studies"
   - "similar products", "competitor analysis", "market comparisons"
   - Flag for Unfair Advantage and Value Proposition dimensions

6. **Validation emphasis**: Check for evidence/validation language
   - "validate", "test", "prove", "verify", "evidence"
   - "customer feedback", "market data", "metrics", "KPIs"
   - Indicates need for evidence-based research questions

7. **Key phrases**: Extract 5-10 significant terms that should appear in dimensions
   - Filter out stop words
   - These become dimension description keywords

This context blends with the 9-block canvas structure.
</thinking>

Store extracted context for downstream phases:

```bash
# Context for Phase 5 entity generation
DIMENSION_CONTEXT["organizing_concept"]="$extracted_concept"
DIMENSION_CONTEXT["target_audience"]="$extracted_audience"
DIMENSION_CONTEXT["business_type"]="$BUSINESS_TYPE"
DIMENSION_CONTEXT["business_stage"]="$BUSINESS_STAGE"
DIMENSION_CONTEXT["action_type"]="actionable|descriptive|analytical"
DIMENSION_CONTEXT["requires_competitors"]="true|false"
DIMENSION_CONTEXT["validation_emphasis"]="true|false"
DIMENSION_CONTEXT["question_keywords"]="$key_phrases"

# Context for Phase 4 PICOT customization
PICOT_OVERRIDES["population"]="$extracted_audience"
PICOT_OVERRIDES["business_type"]="$BUSINESS_TYPE"
PICOT_OVERRIDES["business_stage"]="$BUSINESS_STAGE"
PICOT_OVERRIDES["action_type"]="$action_orientation"
PICOT_OVERRIDES["requires_competitors"]="$requires_competitors"
```

**Fallbacks:**
- Empty organizing concept → Use canvas block names as-is
- No specific audience → Default to "target customer segment"
- BUSINESS_TYPE not set → Default to "generic"
- BUSINESS_STAGE not set → Default to "pmf" (most common)

---

## Step 3.1: Load Canvas-Specific PICOT Patterns

### Base PICOT Patterns by Canvas Block

From Phase 2 analysis and lean-canvas dimensions.md, extract PICOT patterns:

**1. Problem:**
- **P:** Target customer segment
- **I:** Problem identification/validation methods
- **C:** Current alternatives/workarounds
- **O:** Problem severity metrics, frequency indicators
- **T:** Validation timeframe

**2. Customer Segments:**
- **P:** Potential customer segments (broad categories)
- **I:** Segmentation criteria (demographics, behavior, needs)
- **C:** Alternative segment definitions
- **O:** Segment attractiveness (size, growth, accessibility)
- **T:** Market analysis timeframe

**3. Value Proposition:**
- **P:** Target customer segment
- **I:** Value proposition/unique benefit
- **C:** Competitor value propositions
- **O:** Customer perception/preference
- **T:** Market assessment timeframe

**4. Solution:**
- **P:** Target customer segment
- **I:** Proposed solution features/capabilities
- **C:** Competitor solutions/alternatives
- **O:** Problem resolution effectiveness, user satisfaction
- **T:** Solution validation timeframe

**5. Channels:**
- **P:** Target customer segment
- **I:** Acquisition channel/distribution method
- **C:** Alternative channels/traditional approaches
- **O:** Acquisition metrics (CAC, conversion rates, reach)
- **T:** Channel performance evaluation period

**6. Revenue Streams:**
- **P:** Target customer segment
- **I:** Pricing model/revenue approach
- **C:** Competitor pricing/alternative models
- **O:** Revenue metrics (ARPU, LTV, payment conversion)
- **T:** Pricing analysis timeframe

**7. Cost Structure:**
- **P:** Business model/company stage
- **I:** Cost category/optimization approach
- **C:** Industry benchmarks/alternative cost structures
- **O:** Economic metrics (gross margin, burn rate, cost per unit)
- **T:** Financial analysis timeframe

**8. Key Metrics:**
- **P:** Business model/industry segment
- **I:** Key metric/KPI category
- **C:** Alternative metrics/measurement approaches
- **O:** Business outcomes (growth, retention, profitability)
- **T:** Metric tracking timeframe

**9. Unfair Advantage:**
- **P:** Company/business model type
- **I:** Competitive advantage/moat type OR Competitor analysis approach
- **C:** Competitors/market entrants
- **O:** Defensibility metrics (barriers, switching costs, network effects) OR Competitive positioning
- **T:** Competitive analysis timeframe

```bash
# Store base PICOT patterns (Bash 3.2 compatible - use lookup function)
get_dimension_picot() {
  case "$1" in
    "problem") echo "Target customer segment|Problem identification/validation|Current alternatives/workarounds|Problem severity, frequency|Validation timeframe" ;;
    "customer-segments") echo "Potential customer segments|Segmentation criteria|Alternative segment definitions|Segment attractiveness (size, growth, accessibility)|Market analysis timeframe" ;;
    "value-proposition") echo "Target customer segment|Value proposition/unique benefit|Competitor value propositions|Customer perception/preference|Market assessment timeframe" ;;
    "solution") echo "Target customer segment|Solution features/capabilities|Competitor solutions/alternatives|Problem resolution effectiveness, user satisfaction|Solution validation timeframe" ;;
    "channels") echo "Target customer segment|Acquisition channel/distribution|Alternative channels|Acquisition metrics (CAC, conversion, reach)|Channel performance period" ;;
    "revenue-streams") echo "Target customer segment|Pricing model/revenue approach|Competitor pricing/alternative models|Revenue metrics (ARPU, LTV, conversion)|Pricing analysis timeframe" ;;
    "cost-structure") echo "Business model/company stage|Cost category/optimization|Industry benchmarks/alternative structures|Economic metrics (margin, burn rate, cost per unit)|Financial analysis timeframe" ;;
    "key-metrics") echo "Business model/industry segment|Key metric/KPI category|Alternative metrics/measurement|Business outcomes (growth, retention, profitability)|Metric tracking timeframe" ;;
    "unfair-advantage") echo "Company/business model type|Competitive advantage/moat OR Competitor analysis|Competitors/market entrants|Defensibility metrics OR Competitive positioning|Competitive analysis timeframe" ;;
    *) echo "" ;;
  esac
}

log_conditional INFO "[lean-canvas] Base PICOT patterns extracted for 9 canvas blocks"
```

---

## Step 3.2: Apply DOK-Based Question Distribution

### DOK-2 Question Count (Lean Canvas)

Lean Canvas uses **DOK-2 (Skills & Concepts)** classification, which assigns **3 questions per dimension**:

**DOK Formula:**
| DOK Level | Questions/Dimension |
|-----------|---------------------|
| DOK-1     | 2                   |
| DOK-2     | **3** ← lean-canvas |
| DOK-3     | 4                   |
| DOK-4     | 5                   |

**Lean Canvas Distribution:**
- **All 9 canvas blocks:** 3 questions each
- **Total:** 27 questions (9 blocks × 3 questions)

```bash
# Apply DOK-2 based distribution (3 questions per dimension)
DOK_LEVEL=2
QUESTIONS_PER_DIMENSION=3
DIMENSION_COUNT=9
TOTAL_QUESTIONS=$((DIMENSION_COUNT * QUESTIONS_PER_DIMENSION))  # 27

# All blocks get equal distribution based on DOK level
QUESTIONS_PROBLEM=$QUESTIONS_PER_DIMENSION
QUESTIONS_CUSTOMER_SEGMENTS=$QUESTIONS_PER_DIMENSION
QUESTIONS_VALUE_PROPOSITION=$QUESTIONS_PER_DIMENSION
QUESTIONS_SOLUTION=$QUESTIONS_PER_DIMENSION
QUESTIONS_CHANNELS=$QUESTIONS_PER_DIMENSION
QUESTIONS_REVENUE=$QUESTIONS_PER_DIMENSION
QUESTIONS_COST=$QUESTIONS_PER_DIMENSION
QUESTIONS_METRICS=$QUESTIONS_PER_DIMENSION
QUESTIONS_ADVANTAGE=$QUESTIONS_PER_DIMENSION

# Store question targets
DIMENSION_QUESTION_TARGETS["problem"]=$QUESTIONS_PROBLEM
DIMENSION_QUESTION_TARGETS["customer-segments"]=$QUESTIONS_CUSTOMER_SEGMENTS
DIMENSION_QUESTION_TARGETS["value-proposition"]=$QUESTIONS_VALUE_PROPOSITION
DIMENSION_QUESTION_TARGETS["solution"]=$QUESTIONS_SOLUTION
DIMENSION_QUESTION_TARGETS["channels"]=$QUESTIONS_CHANNELS
DIMENSION_QUESTION_TARGETS["revenue-streams"]=$QUESTIONS_REVENUE
DIMENSION_QUESTION_TARGETS["cost-structure"]=$QUESTIONS_COST
DIMENSION_QUESTION_TARGETS["key-metrics"]=$QUESTIONS_METRICS
DIMENSION_QUESTION_TARGETS["unfair-advantage"]=$QUESTIONS_ADVANTAGE

log_conditional INFO "[lean-canvas] DOK-2 distribution: $QUESTIONS_PER_DIMENSION questions per block, $TOTAL_QUESTIONS total"
```

### Rationale for DOK-2 Classification

Lean Canvas research operates at **DOK-2 (Skills & Concepts)** level:
- Applies the Lean Canvas framework to business model analysis
- Requires classification and comparison of business elements
- Uses standard methodology (Ash Maurya's 9-block framework)
- Produces structured canvas blocks at skills/application level

Business stage context (pre-launch/pmf/scaling) is preserved in BUSINESS_STAGE variable and used for PICOT customization, but does not affect question count distribution.

---

## Step 3.3: Customize PICOT with Business Context

### Population (P) Customization

Replace generic "target customer segment" with specific business type context:

```bash
# Customize population based on business type
if [ -n "$BUSINESS_TYPE" ] && [ "$BUSINESS_TYPE" != "generic" ]; then
  case "$BUSINESS_TYPE" in
    b2b-saas)
      PICOT_OVERRIDES["population_context"]="B2B software buyers, decision-makers, IT departments"
      ;;
    marketplace)
      PICOT_OVERRIDES["population_context"]="Supply-side participants, demand-side users, platform stakeholders"
      ;;
    hardware)
      PICOT_OVERRIDES["population_context"]="Hardware product users, distribution channels, OEM partners"
      ;;
    consumer-app)
      PICOT_OVERRIDES["population_context"]="Consumer app users, target demographics, early adopters"
      ;;
    *)
      PICOT_OVERRIDES["population_context"]="Target customer segment"
      ;;
  esac

  log_conditional INFO "[lean-canvas] Population context customized for business type: $BUSINESS_TYPE"
else
  PICOT_OVERRIDES["population_context"]="Target customer segment"
fi
```

### Comparison (C) Enhancement

For canvas blocks requiring competitive context:

**Value Proposition, Solution, Unfair Advantage:**

```bash
# Enhance comparison for competitive blocks
COMPETITIVE_BLOCKS=("value-proposition" "solution" "unfair-advantage")

for block in "${COMPETITIVE_BLOCKS[@]}"; do
  if [ "${PICOT_OVERRIDES[requires_competitors]}" = "true" ]; then
    PICOT_OVERRIDES["comparison_${block}"]="Named competitors, comparable products, market alternatives"
  else
    PICOT_OVERRIDES["comparison_${block}"]="Generic alternatives, traditional approaches"
  fi
done

log_conditional INFO "[lean-canvas] Comparison patterns enhanced for competitive intelligence"
```

### Outcome (O) Customization

Apply stage-appropriate outcome metrics:

```bash
# Customize outcomes by stage
case "$BUSINESS_STAGE" in
  pre-launch)
    PICOT_OVERRIDES["outcome_emphasis"]="Validation metrics, assumption testing, qualitative feedback"
    ;;
  pmf)
    PICOT_OVERRIDES["outcome_emphasis"]="Product-market fit indicators, retention metrics, customer satisfaction"
    ;;
  scaling)
    PICOT_OVERRIDES["outcome_emphasis"]="Growth metrics, unit economics, competitive positioning"
    ;;
esac

log_conditional INFO "[lean-canvas] Outcome emphasis set for stage: $BUSINESS_STAGE"
```

---

## Step 3.4: Map Evidence Patterns per Canvas Block

### Evidence Type Mapping

Each canvas block requires specific evidence types for validation:

**Problem, Solution, Value Proposition:**
```bash
EVIDENCE_PATTERNS["problem"]="Customer interviews, problem validation research, user behavior data"
EVIDENCE_PATTERNS["solution"]="Product comparisons, feature effectiveness studies, user testing"
EVIDENCE_PATTERNS["value-proposition"]="Value proposition case studies, positioning analysis, concept testing"
```

**Customer Segments, Channels:**
```bash
EVIDENCE_PATTERNS["customer-segments"]="Market segmentation studies, TAM/SAM/SOM analysis, demographic data"
EVIDENCE_PATTERNS["channels"]="Channel performance benchmarks, CAC analysis, customer journey mapping, early adopter research"
```

**Revenue Streams, Cost Structure:**
```bash
EVIDENCE_PATTERNS["revenue-streams"]="Pricing strategy research, willingness-to-pay studies, SaaS metrics (ARPU, LTV)"
EVIDENCE_PATTERNS["cost-structure"]="Cost structure analysis, gross margin benchmarks, operational cost studies, financial reports"
```

**Key Metrics, Unfair Advantage:**
```bash
EVIDENCE_PATTERNS["key-metrics"]="KPI framework research, industry benchmark reports, metric correlation studies"
EVIDENCE_PATTERNS["unfair-advantage"]="Competitive strategy research, moat analysis, barriers to entry studies, market share analysis, competitive intensity research, analyst coverage"
```

### Search Pattern Mapping

Dimension-appropriate search strategies:

**Problem & Solution:**
```bash
SEARCH_KEYWORDS["problem"]="customer problems, pain points, unmet needs, {segment} challenges, existing alternatives"
SEARCH_KEYWORDS["solution"]="solution features, MVP, product validation, feature prioritization, user testing"
```

**Customer Segments & Channels:**
```bash
SEARCH_KEYWORDS["customer-segments"]="market segmentation, customer segments, early adopters, TAM SAM SOM"
SEARCH_KEYWORDS["channels"]="customer acquisition, distribution channels, CAC benchmarks, go-to-market, GTM strategy"
```

**Revenue & Cost:**
```bash
SEARCH_KEYWORDS["revenue-streams"]="pricing strategy, revenue model, willingness to pay, monetization, subscription pricing"
SEARCH_KEYWORDS["cost-structure"]="cost structure, fixed costs, variable costs, gross margin, unit economics"
```

**Metrics & Competitive:**
```bash
SEARCH_KEYWORDS["key-metrics"]="key metrics, KPI benchmarks, {industry} metrics, performance indicators, OKRs"
SEARCH_KEYWORDS["unfair-advantage"]="unfair advantage, competitive moat, barriers to entry, market share {industry}, competitive landscape, G2, Capterra, TrustRadius"
```

---

## Step 3.5: Calculate Question Targets

### Validate Stage Distribution

```bash
# Calculate total from stage weighting
CALCULATED_TOTAL=$((
  QUESTIONS_PROBLEM +
  QUESTIONS_CUSTOMER_SEGMENTS +
  QUESTIONS_VALUE_PROPOSITION +
  QUESTIONS_SOLUTION +
  QUESTIONS_CHANNELS +
  QUESTIONS_REVENUE +
  QUESTIONS_COST +
  QUESTIONS_METRICS +
  QUESTIONS_ADVANTAGE
))

if [ "$CALCULATED_TOTAL" -ne "$TOTAL_QUESTIONS" ]; then
  log_conditional ERROR "Question distribution mismatch: Sum ($CALCULATED_TOTAL) != Target ($TOTAL_QUESTIONS)"
  exit 1
fi

log_conditional INFO "[lean-canvas] Question targets validated: $TOTAL_QUESTIONS total questions across 9 canvas blocks"
log_phase "Phase 3: Planning (lean-canvas)" "complete"
```

### Question Depth by Block

Ensure each canvas block has the DOK-2 required depth:

**DOK-2 Requirements:**
- All blocks: exactly 3 questions (DOK-2 standard)
- Total: 27 questions (9 blocks × 3)

```bash
# Validate DOK-2 requirements
for slug in $DIMENSION_SLUGS; do
  QUESTION_COUNT="${DIMENSION_QUESTION_TARGETS[$slug]}"

  if [ "$QUESTION_COUNT" -ne "$QUESTIONS_PER_DIMENSION" ]; then
    log_conditional ERROR "Canvas block $slug has incorrect questions: $QUESTION_COUNT (expected: $QUESTIONS_PER_DIMENSION)"
    exit 1
  fi
done

log_conditional INFO "[lean-canvas] All canvas blocks meet DOK-2 question requirements (3 questions each)"
```

---

## Step 3.6: Validate PICOT Completeness

### Validation Checks

1. **All 9 canvas blocks have PICOT patterns:**
   ```bash
   for slug in $DIMENSION_SLUGS; do
     if [ -z "${DIMENSION_PICOT[$slug]}" ]; then
       log_conditional ERROR "PICOT pattern missing for canvas block: $slug"
       exit 1
     fi
   done
   ```

2. **PICOT patterns contain all 5 components:**
   ```bash
   for slug in $DIMENSION_SLUGS; do
     PATTERN="${DIMENSION_PICOT[$slug]}"
     COMPONENT_COUNT=$(echo "$PATTERN" | tr '|' '\n' | wc -l)

     if [ "$COMPONENT_COUNT" -ne 5 ]; then
       log_conditional ERROR "PICOT pattern for $slug incomplete: Expected 5 components, found $COMPONENT_COUNT"
       exit 1
     fi
   done
   ```

3. **Business context applied to PICOT:**
   ```bash
   if [ -z "${PICOT_OVERRIDES[population_context]}" ]; then
     log_conditional WARNING "Population context not customized, using generic defaults"
   fi

   if [ -z "${PICOT_OVERRIDES[outcome_emphasis]}" ]; then
     log_conditional WARNING "Outcome emphasis not set for business stage"
   fi
   ```

4. **Evidence patterns mapped:**
   ```bash
   for slug in $DIMENSION_SLUGS; do
     if [ -z "${EVIDENCE_PATTERNS[$slug]}" ]; then
       log_conditional ERROR "Evidence pattern missing for canvas block: $slug"
       exit 1
     fi
   done
   ```

5. **Search keywords defined:**
   ```bash
   for slug in $DIMENSION_SLUGS; do
     if [ -z "${SEARCH_KEYWORDS[$slug]}" ]; then
       log_conditional ERROR "Search keywords missing for canvas block: $slug"
       exit 1
     fi
   done
   ```

6. **Competitive intelligence for Unfair Advantage:**
   ```bash
   UNFAIR_ADV_QUESTIONS="${DIMENSION_QUESTION_TARGETS[unfair-advantage]}"

   if [ "$UNFAIR_ADV_QUESTIONS" -lt 5 ]; then
     log_conditional WARNING "Unfair Advantage block has only $UNFAIR_ADV_QUESTIONS questions, may lack comprehensive competitive coverage (recommended: ≥5)"
   fi
   ```

---

## Self-Verification Before Completion

**Verify all steps completed:**

1. Did you run the phase entry verification gate? ✅ YES / ❌ NO
2. Did you initialize Phase 3 TodoWrite with step-level tasks? ✅ YES / ❌ NO
3. Did you execute Step 3.0 (Preserve Original Question Context)? ✅ YES / ❌ NO
4. Did you extract organizing concept, business type, and business stage? ✅ YES / ❌ NO
5. Did you load base PICOT patterns for all 9 canvas blocks? ✅ YES / ❌ NO
6. Did you apply DOK-2 question distribution (3 per block)? ✅ YES / ❌ NO
7. Did you customize PICOT with business context (population, comparison, outcome)? ✅ YES / ❌ NO
8. Did you map evidence patterns for all 9 canvas blocks? ✅ YES / ❌ NO
9. Did you map search keywords for all 9 canvas blocks? ✅ YES / ❌ NO
10. Did you calculate and validate question targets? ✅ YES / ❌ NO
11. Did you validate PICOT completeness (all checks passed)? ✅ YES / ❌ NO
12. Did you log all outputs? ✅ YES / ❌ NO
13. Did you mark all Phase 3 step-level todos as completed? ✅ YES / ❌ NO

⛔ **IF ANY NO:** STOP. Return to incomplete step.

---

## Success Criteria

**Context Preservation:**
- [ ] Original question context analyzed with extended thinking
- [ ] Organizing concept identified (or intentionally empty)
- [ ] Business type and stage validated
- [ ] Action orientation and validation emphasis determined
- [ ] Context stored in DIMENSION_CONTEXT for Phase 5
- [ ] PICOT_OVERRIDES populated for Phase 4

**PICOT Configuration:**
- [ ] Base PICOT patterns loaded for all 9 canvas blocks
- [ ] Population customized with business type context
- [ ] Comparison enhanced for competitive blocks
- [ ] Outcome emphasis set for business stage
- [ ] All PICOT patterns contain 5 components (P/I/C/O/T)

**DOK-Based Distribution:**
- [ ] DOK level set to 2 (Skills & Concepts)
- [ ] Questions per dimension set to 3
- [ ] Question targets calculated for all 9 blocks (3 each)
- [ ] Total questions = 27 (9 × 3)
- [ ] Business stage preserved for PICOT customization

**Evidence & Search Patterns:**
- [ ] Evidence patterns mapped for all 9 canvas blocks
- [ ] Search keywords defined for all 9 canvas blocks
- [ ] Competitive intelligence requirements flagged
- [ ] Evidence types support validation methodology

**Validation:**
- [ ] All canvas blocks have complete PICOT patterns
- [ ] Business context applied to PICOT customization
- [ ] Evidence and search patterns complete
- [ ] Question distribution validated (sum = 27)
- [ ] DOK-2 question requirements met (3 per block)

---

## Phase Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 4

- [ ] Phase entry verification gate passed
- [ ] Step 3.0 executed (Original Question Context preserved)
- [ ] Organizing concept, business context extracted
- [ ] DIMENSION_CONTEXT populated with all required fields
- [ ] Base PICOT patterns loaded for all 9 canvas blocks
- [ ] DOK-2 question distribution applied (3 per block, 27 total)
- [ ] PICOT customized with business context
- [ ] Evidence patterns mapped for all blocks
- [ ] Search keywords defined for all blocks
- [ ] Question targets calculated and validated
- [ ] All PICOT validation checks passed
- [ ] All success criteria met
- [ ] All required variables set and logged
- [ ] All step-level todos marked completed
- [ ] All self-verification questions answered YES
- [ ] Phase 3 todo marked completed in TodoWrite

**Mark Phase 3 todo as completed before proceeding to Phase 4.**

---

## Next Phase

Proceed to [phase-4-picot-generation.md](phase-4-picot-generation.md) when all criteria met.

**Next step:** Phase 4.2 - PICOT Question Generation with Canvas-Specific Patterns

---

## Integration Points

**Phase 5 (Entity Generation) reads:**
- DIMENSION_CONTEXT → Populates preservation fields in dimension entities
- Schema fields: original_organizing_concept, question_keywords, business_type, business_stage, requires_competitors, validation_emphasis

**Phase 4 (PICOT Generation) reads:**
- PICOT_OVERRIDES → Customizes question patterns with business context
- Overrides: population_context, comparison_value-proposition, comparison_solution, comparison_unfair-advantage, outcome_emphasis

**Phase 6 (Research Execution) reads:**
- EVIDENCE_PATTERNS → Guides evidence collection strategies per canvas block
- SEARCH_KEYWORDS → Optimizes search queries for canvas-specific validation

**Backward Compatibility:**
- Empty context → Falls back to generic canvas defaults
- BUSINESS_STAGE not set → Defaults to PMF weighting
- No breaking changes to existing workflows

---

**Size: ~13.8KB** | Self-contained (no runtime file loading, consumes Phase 2 embedded context)
