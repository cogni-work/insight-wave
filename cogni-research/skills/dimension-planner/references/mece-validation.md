# MECE Validation Protocol

Execute systematic validation ensuring research dimensions are Mutually Exclusive (non-overlapping) and Collectively Exhaustive (complete coverage).

---

## Validation Protocol

Execute three phases sequentially. Flag violations when thresholds exceeded.

### Phase 1: Mutual Exclusivity (ME)

**Objective:** Verify dimensions have clear, non-overlapping boundaries.

**For each dimension pair (A, B), run three tests:**

#### Test 1.1: Question Overlap (<20% threshold)

Generate 5-10 hypothetical research questions per dimension. Count ambiguous questions fitting both.

```xml
<overlap_test dimension_a="Customer Needs" dimension_b="Competitive Landscape">
  <dimension_a_questions>
    1. What problems do users face?
    2. What features do customers prioritize?
    3. What price points are acceptable?
  </dimension_a_questions>
  <dimension_b_questions>
    1. Who are main competitors?
    2. What features do competitor products offer?
    3. How do competitors price products?
  </dimension_b_questions>
  <ambiguous_questions>
    - "What features do competitor products offer?" (fits both)
    - "How do competitors price products?" (fits both)
  </ambiguous_questions>
  <calculation>
    Total questions: 6 | Ambiguous: 2 | Overlap: 33%
    Threshold: <20% | Verdict: FAIL
  </calculation>
</overlap_test>
```

**Checklist:**

- [ ] Generated 5-10 questions per dimension
- [ ] Calculated overlap percentage: ____%
- [ ] Result: PASS (<20%) / FAIL (≥20%)

#### Test 1.2: Keyword Overlap (<30% threshold)

Extract 5-8 core focus keywords per dimension. Count shared keywords.

```xml
<keyword_test dimension_a="Customer Needs" dimension_b="Competitive Landscape">
  <dimension_a_keywords>user problems, customer priorities, pain points, requirements, preferences</dimension_a_keywords>
  <dimension_b_keywords>competitors, market players, positioning, differentiation, competitor features</dimension_b_keywords>
  <shared_keywords>features, pricing</shared_keywords>
  <calculation>
    A keywords: 5 | B keywords: 5 | Shared: 2 | Overlap: 40%
    Threshold: <30% | Verdict: FAIL
  </calculation>
</keyword_test>
```

**Checklist:**

- [ ] Extracted 5-8 keywords per dimension
- [ ] Calculated overlap percentage: ____%
- [ ] Result: PASS (<30%) / FAIL (≥30%)

#### Test 1.3: Scope Ambiguity (Low threshold)

Describe 2-3 concrete research examples per dimension. Assess boundary clarity.

```xml
<scope_test dimension_a="Technical Architecture" dimension_b="Implementation Process">
  <dimension_a_examples>
    1. Evaluate microservices vs monolithic
    2. Assess database scaling strategies
    3. Design API authentication
  </dimension_a_examples>
  <dimension_b_examples>
    1. Define deployment pipeline stages
    2. Plan team structure and roles
    3. Schedule feature rollout timeline
  </dimension_b_examples>
  <boundary_clarity>
    Clear: Architecture = design decisions, Implementation = execution process
    No overlapping examples | Verdict: PASS
  </boundary_clarity>
</scope_test>
```

**Checklist:**

- [ ] Described 2-3 examples per dimension
- [ ] Assessed boundary clarity: Low / Medium / High
- [ ] Result: PASS (Low) / FAIL (Medium/High)

**Phase 1 Verdict:**
- **PASS:** All three tests pass for all pairs
- **FAIL:** Any pair exceeds thresholds → Record violations, apply remediation

---

### Phase 2: Collective Exhaustiveness (CE)

**Objective:** Verify dimensions cover entire question space (100% coverage required).

#### Step 2.1: Extract Question Elements

Parse research question for ALL elements requiring coverage:

```xml
<element_extraction>
  <research_question>
    "What are key factors for launching a SaaS product in European market for SMBs,
    considering regulatory compliance, competitive positioning, and GTM strategy?"
  </research_question>
  <extracted_elements>
    1. SaaS product launch factors
    2. European market specifics
    3. SMB target audience
    4. Regulatory compliance requirements
    5. Competitive positioning strategies
    6. Go-to-market strategy components
  </extracted_elements>
  <context_elements>Geographic: European | Segment: SMBs | Type: SaaS</context_elements>
  <output_requirements>Success factors, multi-dimensional analysis</output_requirements>
</element_extraction>
```

**Checklist:**

- [ ] Extracted main question elements
- [ ] Extracted context constraints (geographic, segment, type)
- [ ] Extracted output requirements

#### Step 2.2: Map Elements to Dimensions

Assign each element to one or more dimensions:

```xml
<coverage_mapping>
  <dimensions>1. Regulatory Compliance | 2. Competitive Landscape | 3. Go-to-Market Strategy | 4. Target Market Analysis</dimensions>
  <element_assignments>
    Element 1 (SaaS launch): D3 (GTM), D4 (Market)
    Element 2 (European market): D1 (Regulatory), D4 (Market)
    Element 3 (SMB audience): D4 (Market)
    Element 4 (Regulatory): D1 (Regulatory)
    Element 5 (Competitive): D2 (Competitive)
    Element 6 (GTM strategy): D3 (GTM)
  </element_assignments>
  <unmapped_elements>None</unmapped_elements>
  <calculation>Total: 6 | Mapped: 6 | Coverage: 100% | Verdict: PASS</calculation>
</coverage_mapping>
```

**Checklist:**

- [ ] Mapped each element to ≥1 dimension
- [ ] Identified unmapped elements (target: 0)
- [ ] Calculated coverage: ____% (threshold: 100%)
- [ ] Result: PASS (100%) / FAIL (<100%)

**Phase 2 Verdict:**
- **PASS:** All elements mapped (100% coverage)
- **FAIL:** Unmapped elements exist → Record gaps, apply remediation

---

### Phase 3: Independence

**Objective:** Verify dimensions can be researched in parallel (no circular dependencies).

**For each dimension, check:**

```xml
<independence_check>
  <dimension name="Customer Needs">
    <can_research_independently>YES - Survey users, analyze pain points independently</can_research_independently>
    <requires_input_from>None</requires_input_from>
  </dimension>
  <dimension name="Competitive Analysis">
    <can_research_independently>YES - Analyze competitors, features, pricing independently</can_research_independently>
    <requires_input_from>None</requires_input_from>
  </dimension>
  <dimension name="Differentiation Strategy">
    <can_research_independently>NO - Requires customer needs AND competitive analysis</can_research_independently>
    <requires_input_from>Customer Needs, Competitive Analysis</requires_input_from>
    <violation>CIRCULAR DEPENDENCY detected</violation>
  </dimension>
  <verdict>FAIL - Dimension 3 requires Dimensions 1+2 (not parallel researchable)</verdict>
</independence_check>
```

**Checklist:**

- [ ] Checked each dimension for dependencies
- [ ] Identified circular dependencies (target: 0)
- [ ] Result: PASS (all independent) / FAIL (dependencies exist)

**Phase 3 Verdict:**
- **PASS:** No dependencies, all dimensions researchable in parallel
- **FAIL:** Dependencies detected → Apply remediation

---

## Validation Report Template

```markdown
## MECE Validation Results

### Phase 1: Mutual Exclusivity [PASS/FAIL]
**Pairs Tested:** [N]
**Violations:**
- Pair (A, B): Question [X]%, Keyword [Y]%, Scope [Low/Med/High] - [PASS/FAIL]

[If none: "All pairs <20% question overlap, <30% keyword overlap, low ambiguity"]

### Phase 2: Collective Exhaustiveness [PASS/FAIL]
**Elements:** [N] | **Unmapped:** [N]
**Coverage:** [X]% | [If 100%: "Complete coverage achieved"]

### Phase 3: Independence [PASS/FAIL]
**Dependencies:** [Dimension X requires Y, Z]
[If none: "All dimensions researchable in parallel"]

### Overall Verdict: [MECE COMPLIANT / REQUIRES REMEDIATION]

[If remediation needed, list specific actions]
```

---

## Remediation Protocol

Apply when validation fails. Match violation to strategy.

### Violation 1: Overlapping Dimensions (ME Failure)

**Detection:** Question overlap >20% OR Keyword overlap >30% OR High scope ambiguity

**Remediation:**

1. **Redefine Boundaries** - Sharpen focus to eliminate overlap
   - Problem: "Customer Experience" (usability, interface, workflows) + "User Interface Design" (interface, visual, interactions) → "interface" overlaps
   - Solution: "End-to-End Customer Journey" (onboarding, support, retention) + "Product Interface Design" (visual, interaction patterns, accessibility) → Clear boundaries

2. **Merge Overlapping** - Combine if inseparable
   - Problem: "Pricing Strategy" + "Revenue Model" → 60% overlap (inseparable)
   - Solution: "Business Model & Pricing" → Single dimension, no redundancy

3. **Split Broader Dimension** - If one subsumes another
   - Problem: "Technical Feasibility" (architecture, security, scalability, data) + "Security Requirements" → Security covered in both
   - Solution: "Technical Architecture" (design, scalability, data) + "Security & Compliance" (security, regulatory, protection) → Clear separation

### Violation 2: Coverage Gaps (CE Failure)

**Detection:** Unmapped elements exist (coverage <100%)

**Remediation:**

1. **Add Missing Dimension**
   - Gap: Question mentions "timeline and milestones" but no dimension covers scheduling
   - Solution: Add "Implementation Timeline" (phases, milestones, resource allocation)

2. **Expand Existing Dimension**
   - Gap: Context specifies "budget constraints" but no dimension addresses cost
   - Solution: Expand "Business Model" → "Business Model & Economics" (pricing, costs, budget)

### Violation 3: Dependencies (Independence Failure)

**Detection:** Circular dependencies OR sequential requirements

**Remediation:**

1. **Restructure as Independent**
   - Problem: "Customer Needs" (independent) + "Competitive Analysis" (independent) + "Differentiation Strategy" (requires both)
   - Solution: "Customer Needs" (what users want) + "Competitive Landscape" (what competitors offer) + "Product Positioning" (market position - independent analysis) → All parallel researchable

2. **Eliminate Synthetic Dimension**
   - Problem: "Gap Analysis" requires "Needs" and "Competitive" dimensions first
   - Solution: Remove "Gap Analysis" - this is synthesis work, not research dimension

---

## Domain Templates

**Use as starting points. Validate MECE compliance for your specific question.**

### Business/Market Research (8 dimensions)

1. Customer/User - Needs, behaviors, segments, personas
2. Competitive - Competitor analysis, positioning, differentiation
3. Economic - Market size, pricing, costs, ROI
4. Technical - Feasibility, architecture, capabilities
5. Regulatory - Compliance, legal, policy frameworks
6. Strategic - Vision, goals, positioning, partnerships
7. Operational - Processes, resources, implementation
8. Social - Cultural trends, societal impacts, stakeholder concerns

### Academic/Scientific Research (5 dimensions)

1. Theoretical - Frameworks, models, conceptual foundations
2. Methodological - Research methods, data collection, analysis techniques
3. Empirical - Evidence, findings, experimental results
4. Historical - Timeline, evolution, precedents
5. Comparative - Cross-domain, cross-cultural, cross-temporal comparisons

### Product/Solution Research (6 dimensions)

1. User Experience - Usability, interface, workflows
2. Features - Functionality, capabilities, specifications
3. Market Context - Competition, positioning, differentiation
4. Technical Architecture - Design, infrastructure, scalability
5. Business Model - Pricing, monetization, value proposition
6. Implementation - Deployment, adoption, change management

---

## Dimension Count Guidelines

**Primary Constraint:** MECE validation determines count, not arbitrary limits.

**Typical Ranges by Complexity:**

- **Low (DOK-1):** 2-4 dimensions (factual retrieval)
- **Medium (DOK-2):** 3-5 dimensions (comparative analysis)
- **High (DOK-3):** 4-7 dimensions (multi-factor synthesis)
- **Very High (DOK-4):** 5-8 dimensions (complex investigation)

**Decision Logic:**
- If 8 dimensions are truly non-overlapping AND collectively cover question → Use all 8
- If only 3 dimensions provide complete MECE coverage → Use only 3
- MECE compliance trumps range guidelines

**Validation:** If count outside expected range, verify MECE violations not missed.
