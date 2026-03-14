# Phase 3: Planning (smarter-service)

<!-- COMPILATION METADATA -->
<!-- Source: research-types/smarter-service.md v3.0, tips-framework.md v3.0 -->
<!-- Compiled: 2025-12-29 | Sprint 444 - 52 Questions (4×13) -->
<!-- Propagation: Regenerate via PROPAGATION-PROTOCOL.md when sources change -->

**Research Type:** `smarter-service` | **Framework:** TIPS with Action Horizons | **Coverage:** 52 (1:1 TIPS)

**Checksum:** `sha256:3-smarter-v12-52q-1to1`

**Verification:** After reading, confirm:

```text
Reference Loaded: phase-3-planning-smarter-service.md | Checksum: 3-smarter-v12-52q-1to1
```

---

## Variables Reference

| Variable | Source | Purpose |
|----------|--------|---------|
| DIMENSION_COUNT | Phase 2 | Fixed count (4) |
| DIMENSION_SLUGS | Phase 2 | Dimension identifiers |
| DIMENSION_TIPS_MAP | Phase 2 | Primary TIPS component per dimension |
| TIPS_EVIDENCE_MATRIX | Phase 2 | Evidence requirements per dimension |
| TREND_VELOCITY | Phase 2 | Adoption speed (accelerating/emerging/static) |
| CASE_STUDY_REQ | Phase 2 | Evidence specificity (required/recommended/none) |
| **TREND_CANDIDATES** | Phase 2 | **52 trend candidates (horizon-specific: 5+5+3 per dimension) for coverage validation** |
| **TREND_CANDIDATE_HINTS** | Phase 2 | **research_hint field per candidate for question formulation** |
| QUESTION_TEXT | Phase 0 | Original question |
| PROJECT_LANGUAGE | Phase 0 | Output language |
---

## Phase Entry Gate

**Before proceeding, verify:**

1. Phase 2 todos marked complete
2. DIMENSION_COUNT = 4 with DIMENSION_SLUGS populated
3. DIMENSION_TIPS_MAP populated (all 4 → T/I/P/S)
4. TREND_VELOCITY and CASE_STUDY_REQ detected
5. **TREND_CANDIDATES array has 52 entries (horizon-specific: 5+5+3 per dimension)**

**If any missing:** STOP → Return to Phase 2.

---

## Objective

Execute TIPS-enhanced PICOT planning addressing five quality requirements:

| Requirement | Solution |
|-------------|----------|
| Momentum indicators | Questions contain measurable trend velocity metrics |
| Measurable outcomes | Frame as change indicators, not static states |
| Action horizon justifications | Evidence-based rationale for act/plan/observe |
| FINER diversification | Realistic score distribution (not all 14-15/15) |
| TIPS-role consistency | Case studies aligned with dimension's TIPS component |

---

## Evidence Matrix (Single Source of Truth)

Reference this matrix for action horizon classification in Steps 3 and 5:

| Dimension | Act (0-2y) | Plan (2-5y) | Observe (5+y) |
|-----------|------------|-------------|---------------|
| **externe-effekte** | Published regulation, >70% adoption, mature compliance | Draft regulation, 30-70% adoption, 2-3 vendors | Early discussion, <30% awareness, no standards |
| **neue-horizonte** | ≥5 cases, ROI <24mo, published methods, commercial support | 2-4 cases, ROI 24-36mo, emerging practices | 0-1 conceptual cases, theoretical ROI, no vendors |
| **digitale-wertetreiber** | ≥3y market, ROI <18mo, >15% adoption, 3-6mo skills | 1-3y market, ROI 18-36mo, 5-15% adoption | <1y POC, speculative ROI, <5% pilots |
| **digitales-fundament** | Published standards, >80% training, certifications | 2-3 org cases, 60-80% training, TRL 6-7 | 0-1 research cases, no training, TRL <6 |

---

## Outcome Patterns (Momentum vs Static)

| Dimension | WRONG (static) | CORRECT (momentum-based) |
|-----------|----------------|--------------------------|
| externe-effekte | "Compliance rate" | "Compliance-Rate-Entwicklung YoY" |
| neue-horizonte | "Market relevance" | "Marktrelevanz-Entwicklung über 3 Jahre" |
| digitale-wertetreiber | "Customer value" | "Customer-Value-Steigerung X% YoY" |
| digitales-fundament | "Digital maturity" | "Digitale Reife: Level X→Y in Z Monaten" |

---

## Step 1: Initialize Phase 3 TodoWrite

Add step-level todos:

```
- Phase 3, Step 1: Initialize [in_progress]
- Phase 3, Step 2: Context extraction [pending]
- Phase 3, Step 3: Per-dimension PICOT reasoning [pending]
- Phase 3, Step 4: Confidence calibration [pending]
- Phase 3, Step 5: Cross-dimensional linkage mapping [pending]
- Phase 3, Step 6: Question distribution [pending]
- Phase 3, Step 7: Validate completeness [pending]
```

Mark Step 1 completed, Step 2 in_progress.

---

## Step 2: Extract Question Context

<thinking>
## Question Context Extraction

Question: "{QUESTION_TEXT}"

**1. Target Audience** → Sharpens P (Population)

- Explicit audience: ____________
- Specificity: {generic | industry-vertical | role-specific | company-size}
- Qualifiers to preserve: ____________

**2. Evidence Expectations** → Grounds T (Trend)

- Quantitative signals ("how much", "%"): → Require metrics
- Qualitative signals ("what kind"): → Allow descriptive
- Evidence type: {quantitative | qualitative | hybrid}

**3. Impact Scope** → Calibrates I (Implications)

- Strategic signals ("business model", "competitive"): → Broad
- Operational signals ("process", "efficiency"): → Focused
- Scope: {strategic | operational | both}

**4. Action Urgency** → Informs S (Solutions)

- Urgent ("immediately", "critical"): → Strong recommendations
- Planning ("should consider"): → Preparatory guidance
- Exploratory ("might", "emerging"): → Monitoring suggestions
- Urgency: {urgent | planning | exploratory}
</thinking>

**Store Context:**

```
DIMENSION_CONTEXT[target_audience] = $extracted_audience
DIMENSION_CONTEXT[evidence_type] = {quantitative|qualitative|hybrid}
DIMENSION_CONTEXT[impact_scope] = {strategic|operational|both}
DIMENSION_CONTEXT[action_urgency] = {urgent|planning|exploratory}
PICOT_OVERRIDES[population] = $extracted_audience
PICOT_OVERRIDES[trend_velocity] = $TREND_VELOCITY
```

Mark Step 2 completed, Step 3 in_progress.

---

## Step 3: Per-Dimension PICOT Reasoning

For each of the 4 dimensions, apply this COT template:

<thinking>
## PICOT Reasoning: {DIMENSION_NAME}

**Role:** {role_description}
**Primary TIPS:** {T|I|P|S}

**P (Population):** Refine "{base_population}" with context → ____________

**I (Intervention):** Apply TREND_VELOCITY framing:

- accelerating: "Beschleunigte Auswirkungen von..."
- emerging: "Aufkommende Disruption..."
- static: "Bestehende externe Kräfte..."

→ ____________

**C (Comparison):** Select based on evidence maturity:

- High: "{dimension-specific high-evidence comparison}"
- Medium: "Early Adopters vs Mainstream"
- Low: "{dimension-specific low-evidence comparison}"

→ ____________

**O (Outcome):** MUST include change indicator (see Outcome Patterns):

- Format: "X% YoY", "Entwicklung von X zu Y"

→ ____________

**T (Timeframe):** Justify from Evidence Matrix:

- Evidence criteria met: ____________
- Justified horizon: {act|plan|observe}

→ ____________

**Momentum Indicator:** Based on TREND_VELOCITY:

- accelerating: "X% YoY Beschleunigung"
- emerging: "X-Y% Marktdurchdringung in 12 Monaten"
- static: "Stabilisierte Adoptionsrate bei X%"

→ ____________
</thinking>

### Dimension Specifications

| Dimension | Role | Primary TIPS | Base Population | High-Evidence Comparison | Low-Evidence Comparison |
|-----------|------|--------------|-----------------|-------------------------|------------------------|
| externe-effekte | External forces ON organization | T (Trend) | organizations, industries | Proaktiv vs reaktiv | Vor vs nach Änderung |
| neue-horizonte | Strategic responses BY organization | P (Possibilities) | leadership teams, SBUs | Vorreiter vs Nachzügler | Neue vs traditionelle Modelle |
| digitale-wertetreiber | Value creation THROUGH digital | I (Implications) | customer segments, processes | Digital-first vs traditionell | Konzeptuelle vs manuelle |
| digitales-fundament | Capabilities SUPPORTING transformation | S (Solutions) | workforce, IT departments | Digital-native vs legacy | Neue vs bestehende Infrastruktur |

**Store PICOT Results:**

```
For each dimension in DIMENSION_SLUGS:
  DIMENSION_PICOT[slug] = "$P|$I|$C|$O|$T"
  DIMENSION_ACTION_HORIZON_JUSTIFICATION[slug] = $evidence_justification
  DIMENSION_MOMENTUM_INDICATOR[slug] = $momentum_indicator
  DIMENSION_LINKS[slug] = $cascade_target
```

**Cascade Pattern:**

- externe-effekte → drives → neue-horizonte
- neue-horizonte → prioritizes → digitale-wertetreiber
- digitale-wertetreiber → requires → digitales-fundament
- digitales-fundament → accelerated by → externe-effekte

Mark Step 3 completed, Step 4 in_progress.

---

## Step 4: Confidence Calibration

Apply calibration based on TREND_VELOCITY:

| Velocity | Signal Strength | Implication Language | Solution Directive |
|----------|-----------------|---------------------|-------------------|
| accelerating | High | "will", "werden" | "implement", "umsetzen" |
| emerging | Medium | "likely", "wahrscheinlich" | "evaluate", "prüfen" |
| static | Low | "may", "könnte" | "monitor", "beobachten" |

**TIPS Component Calibration:**

- **T (Trend):** accelerating → specific %, emerging → ranges, static → "early indicators"
- **I (Implications):** ≥0.75 confidence → definitive, 0.5-0.74 → qualified, <0.5 → speculative
- **P (Possibilities):** high velocity → grounded scenarios, low → exploratory
- **S (Solutions):** ≥0.75 → recommend, lower → "evaluate/pilot/monitor"

**Store Calibration:**

```
PICOT_OVERRIDES[confidence_tier] = {high|medium|low}
PICOT_OVERRIDES[implication_language] = {definitive|qualified|speculative}
PICOT_OVERRIDES[solution_directive] = {implement|evaluate|monitor}
```

Mark Step 4 completed, Step 5 in_progress.

---

## Step 5: Cross-Dimensional Linkage Mapping

<thinking>
## Cross-Dimensional Pattern Synthesis

**Cascade Pattern:**

```
Externe Effekte (pressure) → Neue Horizonte (response)
→ Digitale Wertetreiber (mechanism) → Digitales Fundament (capability)
→ Externe Effekte (feedback loop)
```

**Linkage Evidence:**

1. External → Strategic:
   - Force: ____________ → Drives: ____________

2. Strategic → Value:
   - Choice: ____________ → Prioritizes: ____________

3. Value → Foundation:
   - Driver: ____________ → Requires: ____________

4. Foundation → External (feedback):
   - Gap: ____________ → Amplified by: ____________

**Synthesis Opportunity:** ____________
</thinking>

**Store Linkages:**

```
CROSS_DIMENSIONAL_LINKS[externe→horizonte] = $evidence_1
CROSS_DIMENSIONAL_LINKS[horizonte→wertetreiber] = $evidence_2
CROSS_DIMENSIONAL_LINKS[wertetreiber→fundament] = $evidence_3
CROSS_DIMENSIONAL_LINKS[fundament→externe] = $evidence_4
```

Mark Step 5 completed, Step 6 in_progress.

---

## Step 6: Question Distribution & Quality Controls

### 6.1 Distribution Calculation (Fixed: 52 Questions)

**Smarter-Service Fixed Distribution:**

The smarter-service research type requires exactly **52 refined questions** — one question per selected trend candidate from Phase 2. This ensures 1:1 mapping to 52 TIPS.

**Per-Dimension Allocation (Fixed: Horizon-Specific):**

| Dimension | Questions | Per Horizon | Rationale |
|-----------|-----------|-------------|-----------|
| externe-effekte | 13 | 5 act, 5 plan, 3 observe | 1:1 trend candidate mapping |
| neue-horizonte | 13 | 5 act, 5 plan, 3 observe | 1:1 trend candidate mapping |
| digitale-wertetreiber | 13 | 5 act, 5 plan, 3 observe | 1:1 trend candidate mapping |
| digitales-fundament | 13 | 5 act, 5 plan, 3 observe | 1:1 trend candidate mapping |
| **TOTAL** | **52** | **20 ACT, 20 PLAN, 12 OBSERVE** | 1:1 mapping to 52 TIPS |

**Action Horizon Distribution (Horizon-Specific):**

Each dimension receives 13 questions (5 ACT + 5 PLAN + 3 OBSERVE), matching the selected trend candidates from Phase 2. ACT and PLAN horizons have higher representation for actionability.

### 6.2 FINER Diversification Targets

For question sets >15, enforce realistic distribution:

| Score | Target % | Criteria |
|-------|----------|----------|
| 15/15 | 5-15% | Validated methods, unexplored angles, clear benefit |
| 14/15 | 35-55% | Feasible, significant trend, minor trade-offs |
| 13/15 | 25-40% | Achievable with resources, useful trends |
| 12/15 | 5-15% | Pushes limits but strategic value |

### 6.3 Case Study Integration

**Detection from QUESTION_TEXT:**

- Explicit ("Praxisbeispiele", "case studies") → required
- Implicit ("wie können", "Implementierung") → recommended
- None → none

**Per-Dimension TIPS-Aligned Clauses:**

| Dimension | Primary TIPS | Case Study Focus |
|-----------|--------------|------------------|
| externe-effekte | T | Trend validation with adoption rates |
| neue-horizonte | P | Strategic transformation cases |
| digitale-wertetreiber | I | ROI cases with value metrics |
| digitales-fundament | S | Implementation cases with methods |

**Store Distribution:**

```
DIMENSION_QUESTION_TARGETS[slug] = $count
HORIZON_DISTRIBUTION[slug] = "act:$a|plan:$p|observe:$o"
PICOT_OVERRIDES[finer_diversification_enabled] = true
PICOT_OVERRIDES[case_study_clause_{slug}] = $clause
```

### 6.4 Question-to-Trend-Candidate 1:1 Mapping (52 Questions)

Each refined question maps to **exactly one** trend candidate from Phase 2's TREND_CANDIDATES array. This 1:1 mapping ensures complete coverage with 52 TIPS.

**Coverage Requirements:**

- [ ] Exactly 52 refined questions generated (1 per selected trend candidate)
- [ ] Each question maps to exactly 1 trend candidate (no sharing)
- [ ] Each trend candidate has exactly 1 corresponding question
- [ ] Each dimension has 13 questions (5 ACT + 5 PLAN + 3 OBSERVE)

### 6.5 Research Hint Integration (v2.0+)

When trend candidates include the `research_hint` field (schema version 2.0+), use it to guide TIPS-aware question formulation:

**research_hint Usage:**

The `research_hint` field provides investigation guidance (20-30 words) that steers downstream research:

```
trend_statement: "EU AI Act mandates conformity assessments for high-risk AI systems..."
research_hint: "Investigate compliance pathways, implementation costs, and how leading manufacturers are preparing."
```

**Question Generation Flow:**

1. **Read research_hint** from TREND_CANDIDATES for each candidate
2. **Extract searchable terms** from research_hint for query generation
3. **Map hint aspects** to TIPS components:
   - "what is happening" → **T** (Trend) focus
   - "what does it mean" → **I** (Implications) focus
   - "what could we do" → **P** (Possibilities) focus
   - "what should we do" → **S** (Solutions) focus
4. **Formulate PICOT question** that addresses the research_hint guidance

**Fallback for v1 Schema:**

If `research_hint` is not present (legacy schema), fall back to:

- Use `summary` or `rationale` field content
- Generate generic TIPS question based on `trend_name` and `keywords`

**Store Hint Integration:**

```
RESEARCH_HINT_AVAILABLE = true  # If v2.0+ schema with research_hint
for each candidate:
  CANDIDATE_RESEARCH_HINT[dim:horizon:seq] = research_hint || ""
```

**Question-Candidate 1:1 Mapping Template:**

For each refined question, assign exactly one trend candidate:

```
QUESTION_CANDIDATE_MAP=(
  "Q01:externe-effekte:act:1"      # Question 1 → Candidate 1
  "Q02:externe-effekte:act:2"      # Question 2 → Candidate 2
  "Q03:externe-effekte:act:3"      # Question 3 → Candidate 3
  "Q04:externe-effekte:plan:1"     # Question 4 → Candidate 4
  # ... continue for all 52 questions
)
```

**1:1 Coverage Validation COT:**

<thinking>
**Question-to-Candidate 1:1 Verification**

For each dimension, verify horizon-specific question distribution (5 ACT + 5 PLAN + 3 OBSERVE = 13):

| Cell | Q→C1 | Q→C2 | Q→C3 | Q→C4 | Q→C5 | Count |
|------|------|------|------|------|------|-------|
| externe-effekte:act | Q01 | Q02 | Q03 | Q04 | Q05 | 5 ✓ |
| externe-effekte:plan | Q06 | Q07 | Q08 | Q09 | Q10 | 5 ✓ |
| externe-effekte:observe | Q11 | Q12 | Q13 | - | - | 3 ✓ |
| neue-horizonte:act | Q14 | Q15 | Q16 | Q17 | Q18 | 5 ✓ |
| neue-horizonte:plan | Q19 | Q20 | Q21 | Q22 | Q23 | 5 ✓ |
| neue-horizonte:observe | Q24 | Q25 | Q26 | - | - | 3 ✓ |
| digitale-wertetreiber:act | Q27 | Q28 | Q29 | Q30 | Q31 | 5 ✓ |
| digitale-wertetreiber:plan | Q32 | Q33 | Q34 | Q35 | Q36 | 5 ✓ |
| digitale-wertetreiber:observe | Q37 | Q38 | Q39 | - | - | 3 ✓ |
| digitales-fundament:act | Q40 | Q41 | Q42 | Q43 | Q44 | 5 ✓ |
| digitales-fundament:plan | Q45 | Q46 | Q47 | Q48 | Q49 | 5 ✓ |
| digitales-fundament:observe | Q50 | Q51 | Q52 | - | - | 3 ✓ |
| **TOTAL** | | | | | | **52** |

**Verification:** All 52 candidates mapped 1:1 to questions
</thinking>

**Store Coverage:**

```
CANDIDATE_COVERAGE_VALIDATED=true
TOTAL_QUESTIONS=52
QUESTIONS_PER_DIMENSION=13
QUESTIONS_PER_HORIZON_ACT=5
QUESTIONS_PER_HORIZON_PLAN=5
QUESTIONS_PER_HORIZON_OBSERVE=3
```

Mark Step 6 completed, Step 7 in_progress.

---

## Step 7: Validate Completeness

### Validation Checklist

**Core Requirements (all must pass):**

- [ ] All 4 dimensions have PICOT patterns (5 components each)
- [ ] All 4 dimensions have action horizon justifications
- [ ] All 4 dimensions have momentum indicators
- [ ] Cross-dimensional links populated (4 links)
- [ ] Confidence calibration set
- [ ] Question distribution calculated

**Quality Controls:**

- [ ] Horizon distribution stored per dimension
- [ ] FINER diversification enabled
- [ ] Case study clauses generated (if required)

**52 Question 1:1 Mapping (52 TIPS):**

- [ ] CANDIDATE_COVERAGE_VALIDATED = true
- [ ] TOTAL_QUESTIONS = 52 (exactly)
- [ ] QUESTIONS_PER_DIMENSION = 13 (exactly)
- [ ] QUESTIONS_PER_HORIZON = 5 ACT, 5 PLAN, 3 OBSERVE (per dimension)
- [ ] Each question maps to exactly 1 trend candidate (1:1 mapping)

**If any check fails:** Return to relevant step.

Mark Step 7 completed, Phase 3 todos completed.

---

## Phase Completion

**All must be YES before Phase 4:**

- [ ] TIPS focus detected per dimension
- [ ] All 4 PICOT patterns COT-reasoned
- [ ] Confidence calibration applied
- [ ] Cross-dimensional linkages mapped
- [ ] Question distribution: exactly 52 questions (13 per dimension: 5 ACT + 5 PLAN + 3 OBSERVE)
- [ ] Quality controls configured (FINER, case studies)
- [ ] **1:1 question-to-candidate mapping validated (52 questions ↔ 52 candidates)**
- [ ] All validation checks passed

---

## Integration Points

**Phase 4 reads:**

- `DIMENSION_PICOT` → Base patterns
- `PICOT_OVERRIDES` → Velocity, momentum, FINER, case study config
- `DIMENSION_QUESTION_TARGETS` → Counts per dimension
- `HORIZON_DISTRIBUTION` → Act/plan/observe targets
- `DIMENSION_ACTION_HORIZON_JUSTIFICATION` → Evidence per dimension
- **`TREND_CANDIDATES` → 52 trend candidates with keywords for question generation**
- **`QUESTION_CANDIDATE_MAP` → Question-to-candidate coverage assignments**

**Phase 5 reads:**

- `DIMENSION_CONTEXT` → Entity metadata
- `CROSS_DIMENSIONAL_LINKS` → Synthesis linkages
- **`TREND_CANDIDATES` → For entity metadata (trend candidate references)**

**tips-generator (downstream) reads:**

- **`TREND_CANDIDATES` → 52 candidates mapping 1:1 to 52 TIPS**

### Entity Schema (Phase 5)

Questions include:

```json
{
  "action_horizon": {
    "horizon": "act|plan|observe",
    "justification": "Evidence-based reason",
    "evidence_maturity": "high|medium|low"
  },
  "trend_velocity": {
    "velocity": "accelerating|emerging|static",
    "momentum_indicator": "X% YoY"
  },
  "cross_dimensional_links": [{
    "target_dimension": "...",
    "link_type": "causal|dependency|enablement|feedback",
    "tips_flow": "T→P|P→I|I→S|S→T"
  }],
  "case_study_requirement": {
    "level": "required|recommended|none",
    "count": "3-5",
    "tips_role": "T|I|P|S"
  },
  "trend_candidate_ref": "externe-effekte:act:1"
}

---

## Next Phase

Proceed to [phase-4-validation.md](phase-4-validation.md) when all criteria met.
