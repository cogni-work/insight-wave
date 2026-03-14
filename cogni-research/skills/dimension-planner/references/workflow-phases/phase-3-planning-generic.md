# Phase 3: Planning (generic)

**Research Type:** `generic` | **Framework:** Domain-Based (DOK-Adaptive)

**Reference Checksum:** `sha256:3-generic`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-3-planning-generic.md | Checksum: 3-generic
```

---

## Variables Reference

| Variable | Source | Purpose | Example Values |
|----------|--------|---------|----------------|
| DOK_LEVEL | Phase 2 | Complexity classification | 1, 2, 3, 4 |
| MIN_DIMS | Phase 2 | Minimum dimension count | 2, 3, 4, 5 |
| MAX_DIMS | Phase 2 | Maximum dimension count | 3, 4, 6, 9 |
| MIN_Q_PER_DIM | Phase 2 | Questions per dimension | 3, 3, 4, 5 |
| QUESTION_TEXT | Phase 0 | Original question | User's research question |
| PROJECT_LANGUAGE | Phase 0 | Output language | en, de |
| DIMENSION_CONTEXT | This phase | Preserved question context | Organizing concept, audience, etc. |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| DOK_LEVEL missing | Exit 1, return to Phase 2 |
| Domain selection ambiguous | Use business domain as default, log warning |
| DIMENSION_COUNT < MIN_DIMS | Exit 1, invalid configuration |
| Empty organizing concept | Use template dimension names as-is (not an error) |
| DIMENSION_CONTEXT variables empty | Use fallback defaults, log INFO level |

---

## ⛔ Phase Entry Verification

**Before proceeding:**

1. Verify Phase 2 todos marked complete in TodoWrite
2. Verify Phase 2 outputs exist:
   - DOK_LEVEL determined (1-4)
   - MIN_DIMS and MAX_DIMS set
   - MIN_Q_PER_DIM set
   - TOTAL_Q_MIN and TOTAL_Q_MAX set
   - Classification logged with rationale

**If any output missing:** STOP. Return to Phase 2. Complete missing steps.

---

## Step 0.5: Initialize Phase 3 TodoWrite

Add step-level todos for Phase 3:

```markdown
TodoWrite - Add these step-level todos:
- Phase 3, Step 0: Preserve original question context [in_progress]
- Phase 3, Step 1: Analyze question domain [pending]
- Phase 3, Step 2: Determine dimension count [pending]
- Phase 3, Step 3: Blend template with original context [pending]
- Phase 3, Step 4: Log and validate outputs [pending]
```

---

## Objective

Execute domain-based planning: select domain framework, determine dimension count, and **preserve original question context** to prevent template overlay from replacing user's organizing concepts, keywords, and target audience.

## Prerequisites

- DOK_LEVEL determined from Phase 2
- PROJECT_LANGUAGE loaded from Phase 0
- QUESTION_TEXT and QUESTION_CONTEXT available
- Familiarity with PICOT and MECE frameworks

---

## Step 3.0: Preserve Original Question Context

```bash
# Phase start logging - clearly indicates research type
log_phase "Phase 3: Planning (generic)" "start"
log_conditional INFO "[generic] Preserving original question context"
```

<thinking>
Before applying dimension templates, analyze the original question to preserve the user's intent:

1. **Organizing concept**: Identify the core framing noun phrase (e.g., "Trends", "Barriers", "Use Cases", "Challenges", "Opportunities")
   - Look in question title and opening sentence
   - Preserve the exact term the user chose - it reflects their mental model

2. **Target audience specificity**: Note who this is for
   - Generic: "organizations", "companies"
   - Specific: "business leaders (C-level)", "Geschäftsführer mittelständischer Unternehmen"
   - Preserve full qualifiers - they indicate the user's target reader

3. **Action orientation**: Determine question type
   - Actionable: "how to leverage", "what should", "wie können...nutzen"
   - Descriptive: "what are", "which trends", "welche"
   - Analytical: "why", "what explains", "warum"

4. **Impact language**: Note prioritization words
   - "significantly influence", "critically affect", "maßgeblich beeinflussen"
   - Preserve this intensity language - generic "affect" loses meaning

5. **Scope type**: Strategic vs operational focus
   - Strategic: "business model", "strategic innovations", "market positioning"
   - Operational: "process improvements", "efficiency", "implementation"
   - Count indicators to determine dominant scope

6. **Concrete examples required**: Check for explicit asks
   - "concrete use cases", "specific examples", "named companies"
   - "Anwendungsfälle", "konkrete Beispiele"
   - Flag as boolean for Phase 5

7. **Key phrases**: Extract 5-10 significant terms that should appear in dimensions
   - Filter out stop words
   - These become dimension description keywords

This context will blend with template structure rather than being replaced by it.
</thinking>

Store extracted context for downstream phases:

```bash
# Context for Phase 5 entity generation
DIMENSION_CONTEXT["organizing_concept"]="$extracted_concept"
DIMENSION_CONTEXT["target_audience"]="$extracted_audience"
DIMENSION_CONTEXT["impact_keywords"]="$extracted_impact"
DIMENSION_CONTEXT["scope_type"]="strategic|operational|mixed"
DIMENSION_CONTEXT["action_type"]="actionable|descriptive|analytical"
DIMENSION_CONTEXT["requires_case_studies"]="true|false"
DIMENSION_CONTEXT["question_keywords"]="$key_phrases"

# Context for Phase 4 PICOT customization
PICOT_OVERRIDES["population"]="$extracted_audience"
PICOT_OVERRIDES["impact_language"]="$extracted_impact"
PICOT_OVERRIDES["action_type"]="$action_orientation"
```

**Fallbacks:**
- Empty organizing concept → Use template dimension names as-is
- No specific audience → Default to "organizations"
- No impact keywords → Use language-appropriate default ("affect", "beeinflussen", "influencer")

---

## Step 3.1: Analyze Question Domain

<thinking>
Map question to primary domain:
- **Business/Market**: Customer segments, competition, economics, regulations, strategy
- **Academic/Scientific**: Theory, methodology, evidence, history, comparison
- **Product/Solution**: UX, features, market, technical, business model

Select domain based on question indicators.
</thinking>

```bash
case "$DOMAIN" in
  business)
    SELECTED_DOMAINS=("customer" "competitive" "economic" "technical" "regulatory" "strategic" "operational" "social")
    ;;
  academic)
    SELECTED_DOMAINS=("theoretical" "methodological" "empirical" "historical" "comparative")
    ;;
  product)
    SELECTED_DOMAINS=("ux" "features" "market" "technical" "business" "implementation")
    ;;
esac
```

### Domain Selection Logic

Analyze question text for domain indicators:

**Business Domain Indicators:**
- Keywords: market, customer, competition, revenue, strategy, business model, ROI, growth
- Use cases: market analysis, competitive intelligence, business strategy
- Question patterns: "How can businesses...", "What market trends...", "Which companies..."

**Academic Domain Indicators:**
- Keywords: theory, research, methodology, evidence, study, framework, analysis, comparison
- Use cases: literature review, theoretical analysis, empirical research
- Question patterns: "What research shows...", "How do theories explain...", "Compare approaches..."

**Product Domain Indicators:**
- Keywords: features, UX, functionality, design, implementation, technical, user experience
- Use cases: product design, feature prioritization, technical architecture
- Question patterns: "What features...", "How should the product...", "Which capabilities..."

**Default:** If ambiguous, select **business** domain as most common use case.

---

## Step 3.2: Determine Dimension Count

```bash
# Analyze question scope complexity
QUESTION_SCOPE=$(assess_scope_complexity "$QUESTION_TEXT")

case "$QUESTION_SCOPE" in
  compact)       DIMENSION_COUNT=$MIN_DIMS ;;
  standard)      DIMENSION_COUNT=$(( (MIN_DIMS + MAX_DIMS) / 2 )) ;;
  comprehensive) DIMENSION_COUNT=$MAX_DIMS ;;
esac

SELECTED_DIMENSIONS=("${SELECTED_DOMAINS[@]:0:$DIMENSION_COUNT}")
```

### Scope Complexity Assessment

**Compact (MIN_DIMS):**
- Question has narrow, focused scope
- Asks about single aspect or domain
- Example: "What are the key features of X?"

**Standard (Mid-point):**
- Question has moderate breadth
- Explores multiple related aspects
- Example: "How can organizations adopt X effectively?"

**Comprehensive (MAX_DIMS):**
- Question has broad, multi-faceted scope
- Requires extensive cross-domain analysis
- Example: "What are the strategic implications, market dynamics, technical requirements, and organizational challenges of X?"

### DOK-Based Dimension Targets

| DOK Level | MIN_DIMS | MAX_DIMS | Typical Count |
|-----------|----------|----------|---------------|
| DOK-1 | 2 | 3 | 2-3 |
| DOK-2 | 3 | 4 | 3-4 |
| DOK-3 | 5 | 7 | 5-6 |
| DOK-4 | 8 | 10 | 8-10 |

---

## Step 3.3: Blend Template with Original Context

<thinking>
Inject preserved context into dimension structure:

**For first dimension:**
- If organizing concept exists: Blend it with first dimension name
- Example: "Strategic" + "Trends" → "Strategic Trends" (not generic "Strategic Considerations")

**For all dimensions:**
- Reference target audience in rationales (not generic "organizations")
- Use impact keywords in descriptions (not generic "affect")
- Apply scope type to dimension selection
</thinking>

```bash
# Customize first dimension if organizing concept exists
if [ -n "$ORGANIZING_CONCEPT" ]; then
  FIRST_DIM_CAPITALIZED="$(echo "${SELECTED_DOMAINS[0]}" | sed 's/^./\U&/')"
  DIMENSION_CONTEXT["first_dimension_title"]="$FIRST_DIM_CAPITALIZED $ORGANIZING_CONCEPT"
fi
```

**Example:** Generic "Strategic Considerations" → Context-aware "Strategic Trends that significantly influence business leaders (C-level)"

### Context Integration Pattern

For each selected dimension, integrate preserved context:

1. **Dimension Title:**
   - Template: "{Domain} Dimension"
   - Context-Enhanced: "{Domain} {Organizing Concept}" (if organizing concept exists)
   - Example: "Strategic Trends", "Customer Barriers", "Technical Opportunities"

2. **Dimension Rationale:**
   - Template: "Analyze {domain} aspects"
   - Context-Enhanced: "Analyze {domain} aspects relevant to {target_audience}"
   - Example: "Analyze strategic aspects relevant to business leaders (C-level)"

3. **Dimension Purpose:**
   - Template: "Understand how {domain} factors affect outcomes"
   - Context-Enhanced: "Understand how {domain} factors {impact_language} {target_audience}"
   - Example: "Understand how economic factors significantly influence mittelständische Unternehmen"

4. **Question Verbs:**
   - Actionable questions: Use "how to", "what should", "which approaches"
   - Descriptive questions: Use "what are", "which factors", "what characterizes"
   - Analytical questions: Use "why do", "what explains", "what drives"

---

## Step 3.4: Generate MECE Dimension Structure

### MECE Framework Application

For each selected dimension, ensure Mutually Exclusive and Collectively Exhaustive (MECE) coverage:

**Mutually Exclusive:**
- Each dimension covers distinct conceptual territory
- No overlap in core questions or focus areas
- Clear boundaries between dimensions

**Collectively Exhaustive:**
- All dimensions together cover the complete question scope
- No gaps in coverage areas
- Comprehensive view of the research domain

### Standard PICOT Pattern Generation

For each dimension, generate PICOT patterns using context overrides:

```bash
# Apply PICOT overrides from Step 3.0
PICOT_POPULATION="${PICOT_OVERRIDES[population]:-Organizations}"
PICOT_INTERVENTION="{dimension-specific intervention}"
PICOT_COMPARISON="{dimension-specific comparison}"
PICOT_OUTCOME="${PICOT_OVERRIDES[impact_language]:-affect} {business outcomes}"
PICOT_TIMEFRAME="{relevant time horizon}"

# Store dimension PICOT pattern
DIMENSION_PICOT["${dimension_slug}"]="${PICOT_POPULATION}|${PICOT_INTERVENTION}|${PICOT_COMPARISON}|${PICOT_OUTCOME}|${PICOT_TIMEFRAME}"
```

### Domain-Specific PICOT Examples

**Business Domain - Customer Dimension:**
- **P:** Target customer segment (from context)
- **I:** Customer engagement strategy/approach
- **C:** Alternative customer approaches
- **O:** Customer satisfaction, retention, loyalty (with impact language from context)
- **T:** Implementation timeframe

**Business Domain - Competitive Dimension:**
- **P:** Industry/market segment (from context)
- **I:** Competitive strategy/positioning
- **C:** Competitor approaches/strategies
- **O:** Market share, competitive advantage (with impact language from context)
- **T:** Competitive analysis timeframe

**Academic Domain - Theoretical Dimension:**
- **P:** Research domain/field
- **I:** Theoretical framework/model
- **C:** Alternative theoretical perspectives
- **O:** Explanatory power, predictive validity
- **T:** Theory development timeframe

---

## Step 3.5: Calculate Question Targets

```bash
# Questions per dimension (from Phase 2)
QUESTIONS_PER_DIMENSION=$MIN_Q_PER_DIM

# Total questions target
TOTAL_QUESTIONS=$((DIMENSION_COUNT * QUESTIONS_PER_DIMENSION))

log_conditional INFO "[generic] Dimension count: $DIMENSION_COUNT"
log_conditional INFO "[generic] Questions per dimension: $QUESTIONS_PER_DIMENSION"
log_conditional INFO "[generic] Total questions target: $TOTAL_QUESTIONS (range: $TOTAL_Q_MIN-$TOTAL_Q_MAX)"
```

### Question Distribution by DOK Level

| DOK Level | Questions/Dim | Total Range | Question Depth |
|-----------|---------------|-------------|----------------|
| DOK-1 | 4 | 8-12 | Factual recall, basic definitions |
| DOK-2 | 5 | 15-20 | Conceptual understanding, application |
| DOK-3 | 5 | 25-35 | Analysis, synthesis, evaluation |
| DOK-4 | 5 | 40-50 | Strategic investigation, novel trends |

---

## Step 3.6: Log and Proceed

```bash
log_conditional INFO "[generic] Phase 3 Complete: Domain-based planning"
log_conditional INFO "[generic] Domain template: $DOMAIN"
log_conditional INFO "[generic] Dimension count: $DIMENSION_COUNT"
log_conditional INFO "[generic] Organizing concept: $ORGANIZING_CONCEPT"
log_conditional INFO "[generic] Target audience: ${DIMENSION_CONTEXT[target_audience]}"
log_conditional INFO "[generic] Scope type: ${DIMENSION_CONTEXT[scope_type]}"
log_conditional INFO "[generic] Total questions target: $TOTAL_QUESTIONS"
log_metric "domain_template" "$DOMAIN"
log_metric "dimension_count" "$DIMENSION_COUNT"
log_metric "total_questions_target" "$TOTAL_QUESTIONS"
log_phase "Phase 3: Planning (generic)" "complete"
```

**Output Variables:**
- DOMAIN
- DIMENSION_COUNT
- SELECTED_DIMENSIONS
- DIMENSION_CONTEXT (organizing_concept, target_audience, impact_keywords, scope_type, action_type, requires_case_studies, question_keywords)
- PICOT_OVERRIDES (population, impact_language, action_type)
- TOTAL_QUESTIONS

---

## Self-Verification Before Completion

**Verify all steps completed:**

1. Did you run the phase entry verification gate? ✅ YES / ❌ NO
2. Did you initialize Phase 3 TodoWrite with step-level tasks? ✅ YES / ❌ NO
3. Did you execute Step 3.0 (Preserve Original Question Context)? ✅ YES / ❌ NO
4. Did you extract organizing concept, target audience, and impact language? ✅ YES / ❌ NO
5. Did you analyze and select the question domain? ✅ YES / ❌ NO
6. Did you determine dimension count based on scope complexity? ✅ YES / ❌ NO
7. Did you blend template with original context? ✅ YES / ❌ NO
8. Did you generate MECE dimension structure? ✅ YES / ❌ NO
9. Did you create PICOT patterns with context overrides? ✅ YES / ❌ NO
10. Did you calculate question targets? ✅ YES / ❌ NO
11. Did you log all outputs? ✅ YES / ❌ NO
12. Did you mark all Phase 3 step-level todos as completed? ✅ YES / ❌ NO

⛔ **IF ANY NO:** STOP. Return to incomplete step.

---

## Success Criteria

**Context Preservation:**
- [ ] Original question context analyzed with extended thinking
- [ ] Organizing concept identified (or intentionally empty for templates)
- [ ] Target audience extracted or defaulted
- [ ] Impact language, action type, scope type determined
- [ ] Context stored in DIMENSION_CONTEXT for Phase 5
- [ ] PICOT_OVERRIDES populated for Phase 4

**Domain Planning:**
- [ ] DOMAIN assigned (business/academic/product)
- [ ] DIMENSION_COUNT within DOK range (MIN_DIMS to MAX_DIMS)
- [ ] SELECTED_DIMENSIONS array populated
- [ ] First dimension blended with organizing concept (if exists)
- [ ] MECE structure ensured (mutually exclusive, collectively exhaustive)

**PICOT Configuration:**
- [ ] PICOT patterns generated for all dimensions
- [ ] Context overrides applied (population, impact_language, action_type)
- [ ] PICOT patterns stored in DIMENSION_PICOT array

**Question Targets:**
- [ ] QUESTIONS_PER_DIMENSION calculated
- [ ] TOTAL_QUESTIONS within expected range
- [ ] Distribution aligns with DOK level requirements

---

## Phase Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 4

- [ ] Phase entry verification gate passed
- [ ] Step 3.0 executed (Original Question Context preserved)
- [ ] Organizing concept, target audience, impact language extracted
- [ ] DIMENSION_CONTEXT populated with all required fields
- [ ] Domain selected (business/academic/product)
- [ ] Dimension count determined within DOK constraints
- [ ] SELECTED_DIMENSIONS array populated
- [ ] Template blended with original context
- [ ] MECE dimension structure verified
- [ ] PICOT patterns generated with context overrides
- [ ] Question targets calculated
- [ ] All success criteria met
- [ ] All required variables set and logged
- [ ] All step-level todos marked completed
- [ ] All self-verification questions answered YES
- [ ] Phase 3 todo marked completed in TodoWrite

**Mark Phase 3 todo as completed before proceeding to Phase 4.**

---

## Next Phase

Proceed to [phase-4-mece-planning.md](phase-4-mece-planning.md) when all criteria met.

**Next step:** Phase 4.1 - MECE Dimension Planning with Context-Enhanced Questions

---

## Integration Points

**Phase 5 (Entity Generation) reads:**
- DIMENSION_CONTEXT → Populates preservation fields in dimension entities
- Schema fields: original_organizing_concept, question_keywords, impact_prioritization, target_audience, scope_type

**Phase 4 (PICOT Generation) reads:**
- PICOT_OVERRIDES → Customizes question patterns instead of using generic templates
- Overrides: population, impact_language, action_type, intervention_verbs, comparison_focus

**Backward Compatibility:**
- Empty context → Falls back to template defaults
- No breaking changes to existing workflows
- Preservation is enhancement layer, not requirement

---

**Size: ~10.5KB** | Dependencies: Phase 2 DOK classification, domain templates, PICOT framework, MECE principles
