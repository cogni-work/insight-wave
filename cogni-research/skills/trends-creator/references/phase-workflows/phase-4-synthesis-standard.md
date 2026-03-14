# Phase 4: Trend Synthesis (Standard Format)

**Research Type:** `strategic-intelligence`, `tactical-action`, and other types | **Framework:** Context, Evidence, Implications

**Objective:** Generate claim-grounded trends with inline citations from loaded entities using standard format

Transform findings, concepts, megatrends, and **claims** into synthesized trends answering research questions. Each trend represents a thematic pattern across entities, with inline citations and **minimum 3 claims per trend**.

---

## ⛔ CRITICAL: Claim Integration Requirement

**Every trend MUST reference minimum 3 claims.**

Claims provide verified factual assertions with confidence scores. Without claim integration:
- Trends lack verifiable evidence anchors
- Quality scores will be penalized
- Synthesis fails validation in Phase 5

**Claim Selection Criteria:**
- `confidence_score >= 0.75` (high confidence)
- `flagged_for_review = false` (verified)
- `claim_quality >= 0.70` (high quality)

---

## Variables Reference

| Variable | Source | Example |
|----------|--------|---------|
| `${PROJECT_PATH}` | Phase 1 config | `/research/project-xyz` |
| `research_type` | Phase 2 analysis | `strategic-intelligence` |
| `project_language` | Project config | `en` / `de` |
| `generation_mode` | Phase 2 | `dimension-scoped` / `cross-dimensional` |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| claim_count < 30 | Log warning, proceed with available claims |
| trend_count < 5 | Log warning, reduce citation targets |
| dimension filter invalid | Fall back to cross-dimensional mode |
| claim confidence < 0.75 | Exclude from synthesis, use higher-confidence claims |
| entity file not found | Skip citation, log missing entity |

---

## Phase Entry Verification

**STOP - verify before proceeding:**

1. Phase 3 complete (`phase_3_complete: true` in sprint-log.json)
2. Entities loaded: Findings (15-30), Concepts (8-15), Megatrends (5-10), **Claims (30+)**
3. `research_type` confirmed (NOT "smarter-service")
4. `generation_mode` identified

**Verification command:**

```bash
# Check Phase 3 completion
grep -q '"phase_3_complete":\s*true' sprint-log.json && echo "✓ Phase 3 complete" || echo "✗ Phase 3 NOT complete"

# Count loaded entities
echo "Findings: $(find 04-findings/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
echo "Concepts: $(find 05-domain-concepts/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
echo "Megatrends: $(find 06-megatrends/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
echo "Claims: $(find 10-claims/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
```

**Expected output:**

- Phase 3 complete: ✓
- Findings: 15-30
- Concepts: 8-15
- Megatrends: 5-10
- **Claims: 30+ (minimum required for claim integration)**

**Fail any?** Return to Phase 3.

---

## Step 0.5: Initialize TodoWrite

```text
- Phase 4, Step 1.1: Load research context [in_progress]
- Phase 4, Step 1.2: Question-entity mapping (CoT) [pending]
- Phase 4, Step 1.3: Verify mapping quality [pending]
- Phase 4, Step 1.4: Claim-to-finding mapping [pending]
- Phase 4, Step 1.5: Set trend count targets [pending]
- Phase 4, Step 2.1: Pattern discovery (CoT) [pending]
- Phase 4, Step 2.2: Execute pattern discovery [pending]
- Phase 4, Step 2.3: Claim allocation per theme [pending]
- Phase 4, Step 2.4: Quality verification [pending]
- Phase 4, Step 2.5: Compute planning horizon classification [pending]
- Phase 4, Step 2.6: Compute trend quality scores [pending]
- Phase 4, Step 3: Generate trend entities [pending]
- Phase 4, Step 4.1: Apply STANDARD format [pending]
- Phase 4, Step 4.2: Write trend content with claims [pending]
- Phase 4, Step 4.2.5: Pre-write claim validation (LAYER 1) [pending]
- Phase 4, Step 4.3: Strategic value validation [pending]
- Phase 4, Step 5.1: Add inline citations [pending]
- Phase 4, Step 5.2: Citation validation [pending]
- Phase 4, Step 5.3: Claim coverage validation [pending]
- Phase 4, Step 5.4: Confidence aggregation [pending]
- Phase 4, Step 5.5: Evidence freshness assessment [pending]
- Phase 4, Step 6: Create References sections [pending]
```

---

## Step 1: Analyze Through Research Lens

### Step 1.1: Load Research Context

1. Read `initial_question` and `refined_questions` from sprint-log.json
2. Note `research_type` for STANDARD format
3. List all loaded entity counts (findings, concepts, megatrends, claims)

### Step 1.2: Question-Entity Mapping with Chain-of-Thought

Use structured reasoning to systematically connect questions to evidence:

```xml
<thinking>

**1.2.1 - Initial Question Analysis:**

- What is the core research question asking?
- What type of answer is expected (trends, recommendations, analysis)?
- Which entity types most directly answer this?

**1.2.2 - Refined Question Mapping:**

FOR EACH refined_question:
- List finding IDs that provide direct answers
- List concept IDs that clarify terminology/frameworks
- List megatrend IDs that organize the domain
- Note: partial answer / full answer / no answer

**1.2.3 - Coverage Assessment:**

- Questions with strong coverage (3+ entities): [list]
- Questions with weak coverage (<3 entities): [list]
- Unaddressed questions: [list]

**1.2.4 - Synthesis Framing:**

- What answers emerged clearly?
- What remains ambiguous or contested?
- How do concepts clarify the findings?
- How do megatrends organize the knowledge?

</thinking>
```

### Step 1.3: Verify Mapping Quality

Before proceeding, confirm:

- [ ] Every refined question mapped to ≥1 entity
- [ ] No orphan entities (unused findings/concepts/megatrends)
- [ ] Research type confirmed for format selection

**Any unchecked?** Return to Step 1.2 reasoning.

**Mark Step 1.3 completed, Step 1.4 in_progress**

---

### Step 1.4: Claim-to-Finding Mapping

**⛔ MANDATORY:** Map claims to their source findings for evidence chain construction.

Use structured reasoning to create claim allocation matrix:

```xml
<thinking>

**1.4.1 - Claim Inventory:**

FOR EACH claim in 10-claims/data/:
- claim_id: {identifier}
- claim_text: {verbatim assertion}
- confidence_score: {0.0-1.0}
- finding_refs: {source finding IDs}
- quality_flags: {any warnings}

Filter: Keep only claims with confidence_score >= 0.75 AND flagged_for_review = false

**1.4.2 - Finding-Claim Relationship:**

FOR EACH finding:
- finding_id: {identifier}
- claims_derived: [list claim IDs extracted from this finding]
- claim_count: {number}

**1.4.3 - Claim Quality Distribution:**

- High confidence (≥0.85): {count} claims
- Medium-high (0.75-0.84): {count} claims
- Below threshold (<0.75): {count} claims (exclude from synthesis)

**1.4.4 - Coverage Assessment:**

- Findings with 3+ claims: {count} (strong evidence)
- Findings with 1-2 claims: {count} (moderate evidence)
- Findings with 0 claims: {count} (weak evidence - note for synthesis)

</thinking>
```

**Output:** Claim allocation matrix showing which claims support which findings.

**Mark Step 1.4 completed, Step 1.5 in_progress**

---

## Step 1.5: Set Trend Count Targets

**Count by mode:**

| Mode | Research Type | Total |
|------|---------------|-------|
| dimension-scoped | any | 3-15 per dimension |
| cross-dimensional | any | 5-8 |

**Mark Step 1.5 completed, Step 2 in_progress**

---

## 🚦 GATE CHECK #1: Research Lens Analysis

**STOP. Verify analysis before proceeding to pattern discovery.**

Self-verification questions:
- [ ] Did I map all refined questions to entities?
- [ ] Did I create claim-to-finding matrix with claim counts?
- [ ] Did I set trend count targets based on generation mode?
- [ ] Are Steps 1.1-1.5 all marked `completed` in TodoWrite?

**IF ANY ANSWER IS NO:** Return to incomplete step. DO NOT proceed.

**IF ALL YES:** Continue to Step 2.

---

## Step 2: Identify Cross-Finding Patterns

**By generation mode:**
- **dimension-scoped:** FOR EACH dimension → identify 3-15 themes
- **cross-dimensional:** Identify 5-8 themes total

### Step 2.1: Pattern Discovery with Chain-of-Thought

Before identifying patterns, use structured reasoning integrating findings AND claims to ensure evidence-grounded themes:

```xml
<thinking>

**2.1.1 - Theme Extraction (Finding + Claim Driven):**

- Scan all findings sequentially
- FOR EACH finding, list its derived claims (from Step 1.4 matrix)
- Note recurring keywords across findings AND claim_texts
- Identify quantitative anchors from high-confidence claims (e.g., "72% adoption", "$500B market")
- List candidate themes (aim for 2x target count initially)

**2.1.2 - Claim-Anchored Cluster Formation:**

- For each candidate theme:
  - List supporting findings by ID
  - List available claims from those findings (from Step 1.4)
  - Note claim confidence scores
- Prioritize themes with 3+ high-confidence claims (≥0.75)
- Merge overlapping themes (>50% finding overlap)
- **Eliminate themes with <3 findings OR <3 available claims**

**2.1.3 - Claim-Informed Relationship Mapping:**

- Mark contradictions: Which claims disagree? (different confidence levels?)
- Mark confirmations: Which claims reinforce each other? (cross-validation)
- Mark cause-effect: Do claims suggest causal links?
- Mark temporal patterns: Do claims show evolution over time?
- Note claim confidence distribution per relationship type

**2.1.4 - Evidence Assessment (Claim Quality):**

- Count supporting findings per theme
- **Count high-confidence claims (≥0.75) per theme**
- Rate evidence strength:
  - Strong: 3+ findings AND 3+ high-confidence claims
  - Moderate: 3+ findings BUT <3 high-confidence claims
  - Weak: <3 findings OR 0 high-confidence claims (flag for supplementation)
- Calculate coverage: findings used / total findings
- **Calculate claim coverage: claims used / total high-confidence claims**

**2.1.5 - Gap Analysis (Claim-Aware):**

- Which research questions lack themes?
- Which findings remain unassigned?
- **Which high-confidence claims remain unused?** (opportunity for additional themes)
- Do themes answer the initial_question?
- **Are quantitative claims (statistics, metrics) distributed across themes?**

</thinking>
```

**Key principle:** Themes should emerge from BOTH finding patterns AND claim evidence. A theme without claim support is speculation, not trend.

### Step 2.2: Execute Pattern Discovery

Using the reasoning above, produce:

1. **Themes:** Recurring concepts across findings AND claims (with explicit finding IDs and claim IDs)
2. **Clusters:** Group findings by shared themes (distinct labels, 3+ findings AND 3+ claims each)
3. **Relationships:** Contradictions, confirmations, cause-effect, temporal patterns (claim-informed)
4. **Evidence strength:** Count supporting findings + high-confidence claims per theme

**Output format per theme:**

| Theme | Findings | Claims (≥0.75) | Avg Confidence | Strength |
|-------|----------|----------------|----------------|----------|
| {name} | finding-1, finding-2, finding-3 | claim-a, claim-b, claim-c | 0.82 | Strong |

---

### Step 2.3: Claim Allocation Per Theme

**⛔ MANDATORY:** Allocate minimum 3 claims to each theme for evidence grounding.

```xml
<thinking>

**2.3.1 - Theme-Claim Assignment:**

FOR EACH identified theme:
- theme_name: {label}
- supporting_findings: [finding IDs]
- available_claims: [claims from those findings]
- selected_claims: [top 3-5 by confidence_score]

**2.3.2 - Selection Algorithm:**

1. List all claims from theme's supporting findings
2. Filter: confidence_score >= 0.75, flagged_for_review = false
3. Sort by confidence_score (descending)
4. Select top 3-5 claims per theme
5. Verify diversity (claims from different findings preferred)

**2.3.3 - Gap Identification:**

- Themes with 3+ high-confidence claims: {count} ✓
- Themes with <3 claims: {list} ⚠️ (require claim supplementation)

**2.3.4 - Supplementation Strategy:**

IF theme has <3 claims:
- Option A: Include medium-confidence claims (0.65-0.74)
- Option B: Merge with related theme
- Option C: Flag as "evidence-limited" in trend

</thinking>
```

**Output:** Theme-claim allocation table:

| Theme | Finding Count | Claim Count | Selected Claims |
|-------|---------------|-------------|-----------------|
| {name} | {N} | {M} | claim-id-1, claim-id-2, claim-id-3 |

**Mark Step 2.3 completed, Step 2.4 in_progress**

---

### Step 2.4: Quality Verification

Before proceeding, verify:
- [ ] Each theme spans 3+ findings
- [ ] **Each theme has 3+ allocated claims**
- [ ] Themes are distinct (no >50% overlap)
- [ ] Themes answer research questions
- [ ] Coverage ≥70% of loaded findings
- [ ] Coverage ≥60% of high-confidence claims

**Any unchecked?** Return to Step 2.1/2.3 reasoning and refine.

**Mark Step 2.4 completed, Step 2.5 in_progress**

---

### Step 2.5: Compute Planning Horizon Classification

**Purpose:** Assign planning_horizon (act/plan/observe) based on evidence maturity and timeframe signals.

Use structured reasoning to classify each theme by actionability timeline:

```xml
<thinking>

**2.5.1 - Evidence Maturity Assessment:**

FOR EACH theme:
- avg_claim_confidence = mean(allocated claim confidence_scores)
- has_proven_implementations = any(findings mention successful deployments, case studies, production use)
- has_quantified_outcomes = any(claims contain metrics, percentages, dollar amounts, specific numbers)

**2.5.2 - Initial Classification Decision Tree:**

FOR EACH theme:
  IF avg_claim_confidence >= 0.85 AND has_proven_implementations:
    initial_horizon = "act"
  ELSE IF avg_claim_confidence >= 0.75:
    initial_horizon = "plan"
  ELSE:
    initial_horizon = "observe"

**2.5.3 - Timeframe Override Analysis:**

FOR EACH theme:
- Scan findings and claims for temporal markers
- Immediate signals: "immediate", "now", "currently", "Q1 2025", "available today", "ready to deploy"
- Emerging signals: "experimental", "pilot", "prototype", "research stage", "2027+", "long-term", "future"

Override logic:
  IF strong immediate signals AND initial_horizon != "act":
    final_horizon = "act"
    rationale = "Strong immediate deployment signals override classification"
  ELSE IF strong emerging signals AND initial_horizon != "observe":
    final_horizon = "observe"
    rationale = "Experimental/future signals override classification"
  ELSE:
    final_horizon = initial_horizon
    rationale = "Evidence maturity classification holds"

**2.5.4 - Planning Horizon Classification Table:**

| Theme | Avg Claim Confidence | Proven Implementations | Immediate Signals | Emerging Signals | Final Horizon | Rationale |
|-------|---------------------|----------------------|-------------------|------------------|---------------|-----------|
| {name} | 0.85 | Yes | Yes | No | act | High confidence + proven + immediate signals |
| {name} | 0.78 | No | No | No | plan | Medium confidence, capability building phase |
| {name} | 0.72 | No | No | Yes | observe | Lower confidence + experimental stage |

</thinking>
```

**Classification Criteria Reference:**

| Horizon | Time Range | Evidence Characteristics |
|---------|-----------|--------------------------|
| **act** | 0-6 months | High confidence claims (≥0.85), proven implementations cited, quantified outcomes present, ready-to-use solutions, immediate deployment signals |
| **plan** | 6-18 months | Medium confidence claims (0.75-0.84), capability building mentioned, emerging consensus, second-gen products, roadmap items |
| **observe** | 18+ months | Lower confidence claims (<0.75), experimental stage, weak signals, research/prototype phase, emerging technologies |

**Output:** Planning horizon classification table with rationale per theme.

**Mark Step 2.5 completed, Step 2.6 in_progress**

---

### Planning Horizon Independence Note

**Trend planning_horizon is determined SOLELY by Step 2.5 analysis** (evidence maturity + timeframe signals), NOT by megatrend references.

**Rationale:**
- **Megatrends:** Cross-dimensional, broad patterns, industry-wide maturity
- **Trends:** Dimension-specific, focused patterns, context-specific maturity

**Example:** A trend may reference a mature megatrend ("act" horizon) but require 12-18 months capability building within its dimension ("plan" horizon).

**Validation:** Trend horizon calculated independently; synthesis-dimension may note horizon differences in Related Megatrends section.

---

### Step 2.6: Compute Trend Quality Scores

**Purpose:** Calculate multi-dimensional quality scores to enable prioritization of high-value trends.

Use structured reasoning to compute quality metrics for each theme:

```xml
<thinking>

**2.6.1 - Evidence Strength Score (0.0-1.0):**

FOR EACH theme:
- avg_claim_confidence = mean(claim_confidence_scores)
- unique_findings_count = count(distinct source findings for claims)
- claim_diversity = unique_findings_count / total_claims_in_theme
- evidence_strength = avg_claim_confidence × (0.7 + 0.3 × claim_diversity)

Example: Theme with 4 claims (conf: 0.85, 0.82, 0.78, 0.80) from 3 findings
- avg_claim_confidence = 0.8125
- claim_diversity = 3/4 = 0.75
- evidence_strength = 0.8125 × (0.7 + 0.3 × 0.75) = 0.8125 × 0.925 = 0.752

**2.6.2 - Strategic Relevance Score (0.0-1.0):**

FOR EACH theme:
- questions_addressed = count(refined_questions mapped to theme)
- total_questions = count(all refined_questions)
- direct_answer_ratio = findings_with_direct_answers / total_theme_findings
- strategic_relevance = (questions_addressed / total_questions × 0.6) + (direct_answer_ratio × 0.4)

**2.6.3 - Actionability Score (0.0-1.0):**

FOR EACH theme:
- has_quantification = 1 if theme contains numeric claims (%, $, dates), else 0
- has_recommendation = 1 if implications can be drafted with concrete actions, else 0
- has_specificity = 1 if named entities/timeframes/technologies present, else 0
- actionability = (has_quantification + has_recommendation + has_specificity) / 3

**2.6.4 - Novelty Score (0.0-1.0):**

FOR EACH theme:
- Extract top 5 keywords from theme
- FOR EACH other_theme: calculate jaccard_similarity(keywords, other_keywords)
- max_overlap = max(all jaccard_similarities)
- novelty = 1 - max_overlap

**2.6.5 - Composite Quality Score:**

composite = (evidence_strength × 0.35) + (strategic_relevance × 0.30) + (actionability × 0.20) + (novelty × 0.15)

Thresholds:
- High quality: composite ≥ 0.75
- Medium quality: 0.60 ≤ composite < 0.75
- Low quality: composite < 0.60 (flag for review)

</thinking>
```

**Output:** Quality score table per theme:

| Theme | Evidence | Relevance | Actionability | Novelty | Composite | Rating |
|-------|----------|-----------|---------------|---------|-----------|--------|
| {name} | 0.82 | 0.78 | 0.85 | 0.71 | 0.79 | High |

**Mark Step 2.6 completed, Step 3 in_progress**

---

## 🚦 GATE CHECK #2: Pattern Discovery Completeness

**STOP. Verify patterns before proceeding to entity generation.**

Self-verification questions:

- [ ] Did I identify 5-8 themes (cross-dimensional) or 3-15 per dimension?
- [ ] Does each theme have 3+ findings AND 3+ claims allocated?
- [ ] Did I create theme-claim allocation table?
- [ ] Did I compute planning horizon classification for all themes (Step 2.5)?
- [ ] Did I compute quality scores for all themes (Step 2.6)?
- [ ] Are any themes rated "Low quality" (composite < 0.60)? If yes, review and strengthen.
- [ ] Are Steps 2.1-2.6 all marked `completed` in TodoWrite?

**IF ANY ANSWER IS NO:** Return to incomplete step. DO NOT proceed.

**IF ALL YES:** Continue to Step 3.

---

## Step 3: Generate Trend Entities

**Filename:** `trend-{theme-slug}-{hash6}.md`
**Location:** `{research_output_dir}/11-trends/data/`

### Dublin Core Frontmatter

```yaml
---
dc:identifier: trend-{theme-slug}-{hash6}
dc:title: "{Two-Word Title}"
dc:type: trend
dc:creator: trends-creator
dc:date: {ISO-8601}
dc:description: "{1-2 sentence summary}"
research_type: {strategic-intelligence|tactical-action}
synthesis_format: STANDARD
dimension: "{dimension-slug}"           # dimension-scoped only
planning_horizon: "{act|plan|observe}"  # MANDATORY: computed in Step 2.5
tags: [trend, {dimension-slug}]
finding_refs: []
concept_refs: []
megatrend_refs: []
claim_refs: []
addresses_questions: []                 # refined question IDs this trend answers
citation_count: 0
word_count: 0
# Quality metrics (computed in Step 2.6)
quality_scores:
  evidence_strength: 0.0
  strategic_relevance: 0.0
  actionability: 0.0
  novelty: 0.0
  composite: 0.0
quality_rating: ""                      # high | medium | low
# Confidence metrics (computed in Step 5.4)
trend_confidence: 0.0
confidence_calibration: ""              # high | moderate | low
# Evidence freshness (computed in Step 5.5)
evidence_freshness: ""                  # current | aging | dated
oldest_evidence_date: ""                # ISO date of oldest cited claim
---
```

**Conditional fields:**
- `dimension`: Only if `generation_mode == "dimension-scoped"`

Create all entity files before writing content.

**Mark Step 3 completed, Step 4 in_progress**

---

## 🚦 GATE CHECK #3: Entity Files Created

**STOP. Verify entity files before proceeding to content writing.**

Self-verification questions:
- [ ] Did I create all trend entity files with frontmatter?
- [ ] Are entity filenames following convention (trend-{slug}-{hash6}.md)?
- [ ] Does each trend have valid `planning_horizon` (act|plan|observe)?
- [ ] Is the planning_horizon distribution reasonable (not 100% in one category)?
- [ ] Is Step 3 marked `completed` in TodoWrite?

**IF ANY ANSWER IS NO:** Return to Step 3. DO NOT proceed.

**IF ALL YES:** Continue to Step 4.

---

## Step 4: Apply STANDARD Format

### Step 4.1: STANDARD Format Structure

**Word target:** 1100-1350 per trend

```markdown
# {Title}

## Context
{Background, 250-300 words}
- Scene setting, why theme emerged
- Connection to research questions
- **Include 1+ claim quote establishing context**

## Evidence
{Key findings, 350-450 words}
- Strongest findings first
- Diverse sources, address tensions
- **Include 2+ claim quotes as evidence anchors**

## Tensions & Limitations
{100-150 words}
- Contradicting evidence (cite both claim sides with confidence scores)
- Evidence gaps or low-confidence areas
- Contested interpretations or unresolved questions
- Note: If no significant tensions exist, state "No material contradictions identified" and note any evidence gaps

## Implications
{Total: 300-400 words}

### Strategic (Decision-makers)
{100-150 words}
- Resource allocation guidance
- Investment priorities
- Risk/opportunity assessment

### Operational (Practitioners)
{100-150 words}
- Implementation considerations
- Process changes required
- Capability gaps to address

### Technical (if applicable)
{50-100 words - OPTIONAL, include only if technically relevant}
- Architecture implications
- Technology stack considerations
- Integration requirements

## Planning Horizon: {act|plan|observe}
{One sentence explaining why this trend is classified in this horizon based on evidence maturity, implementation readiness, and timeframe signals from Step 2.5 analysis.}

**Examples:**
- ACT: "Classified as 'act' due to high claim confidence (0.87), proven implementations in production, and immediate deployment signals from enterprise case studies."
- PLAN: "Classified as 'plan' given moderate confidence (0.78) and capability-building phase with second-generation products expected in 12-18 months."
- OBSERVE: "Classified as 'observe' based on experimental stage signals (0.71 confidence), prototype-phase evidence, and 24+ month deployment timeframes."

## Claim Evidence
**Key claims supporting this trend:**
1. "{claim_text_1}" (confidence: {score}) [[10-claims/data/{claim-id-1}|C1]]
2. "{claim_text_2}" (confidence: {score}) [[10-claims/data/{claim-id-2}|C2]]
3. "{claim_text_3}" (confidence: {score}) [[10-claims/data/{claim-id-3}|C3]]

## References
{Added in Step 6}
```

### Step 4.2: Write Trend Content with Claims

**⛔ MANDATORY Claim Integration (minimum 3 per STANDARD trend):**

| Section | Claim Usage | Purpose |
|---------|-------------|---------|
| Context | 1+ inline quote | Establish factual baseline |
| Evidence | 2+ inline quotes | Anchor key findings with verified data |
| Tensions & Limitations | Cite contradicting claims | Intellectual honesty, confidence calibration |
| Implications (Strategic) | Reference supporting claims | Executive-level decision support |
| Implications (Operational) | Reference supporting claims | Practitioner guidance |
| Claim Evidence | 3+ consolidated | Explicit evidence chain |

**Claim Quote Format:**
```markdown
"99% of surveyed C-Level managers see supply chain resilience as strategic priority"<sup>[[10-claims/data/claim-supply-chain-99-a1b2|C1]]</sup> (2024).
```

**Selection Criteria:**
- `confidence_score >= 0.75` (high confidence)
- `flagged_for_review = false` (verified)
- `claim_quality >= 0.70` (high quality)
- Prefer claims from different source findings (diversity)

**Total: 1050-1300 words per trend, minimum 3 claims**

**Stakeholder Guidance:**
- Draft implications with explicit stakeholder lens
- Include at least Strategic and Operational subsections
- Technical subsection optional (skip if not applicable to theme)

### ⚠️ ANTI-FABRICATION WARNING

**CRITICAL:** Every claim in STANDARD sections MUST trace to loaded entities.

**FORBIDDEN:**
- ❌ Inventing context not present in loaded findings
- ❌ Adding statistics not present in claim entities
- ❌ Creating implications without supporting evidence
- ❌ Describing evidence without claim-backed data

**REQUIRED:**
- ✅ Draft content based ONLY on loaded entities (findings + claims)
- ✅ Note citation placeholders for Step 5
- ✅ Track which entities support each section
- ✅ If insufficient evidence, log warning and note limitation

### Writing Guidelines

- Match `project_language`
- Professional, analytical, active voice
- Clear sentences, concrete examples
- **Integrate claim quotes naturally into narrative**
- **DO NOT add finding/concept citations yet (Step 5)**

**Language-Aware Section Headers (when project_language=de):**

Section headers MUST match the project language. Reference: [../../../../references/language-templates.md](../../../../references/language-templates.md)

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Context | Context | Kontext |
| Evidence | Evidence | Beweise |
| Tensions & Limitations | Tensions & Limitations | Spannungen & Einschränkungen |
| Implications | Implications | Implikationen |
| Strategic | Strategic | Strategisch |
| Operational | Operational | Operativ |
| Technical | Technical | Technisch |
| Planning Horizon | Planning Horizon | Planungshorizont |
| Claim Evidence | Claim Evidence | Beleglage |
| References | References | Referenzen |

**German Body Text Formatting (when project_language=de):**

| Element | Format | Example |
|---------|--------|---------|
| Body text | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| Section content | Proper umlauts | "für" NOT "fuer", "müssen" NOT "muessen" |
| Claim quotes | Proper umlauts | Preserve original German characters |
| Filenames/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| YAML identifiers | ASCII only | dc:identifier, entity IDs |

**Correct Germa trend:**

```markdown
## Kontext
Die erfolgreiche Transformation von IT- zu OT-Fachkräften erfordert strukturierte Lernprogramme.
```

**Incorrect (ASCII fallback + English header):**

```markdown
## Context
Die erfolgreiche Transformation von IT- zu OT-Fachkraeften erfordert strukturierte Lernprogramme.
```

**Mark Step 4.2 completed, Step 4.2.5 in_progress**

---

### Step 4.2.5: Pre-Write Claim Validation (LAYER 1)

**Purpose:** Validate claim_refs in frontmatter against CLAIM_REGISTRY before finalizing trends to prevent fake claim IDs.

**⛔ BLOCKING:** This validation MUST pass before Step 4.3. If any trend contains fake claim IDs, synthesis STOPS.

```bash
log_conditional INFO "Validating claim_refs against Phase 3 registry..."

validation_passed=true
invalid_trends=()

for trend_file in "${created_files[@]}"; do
  FILEPATH="${PROJECT_PATH}/11-trends/data/${trend_file}"

  # Extract claim_refs from frontmatter
  claim_refs=$(grep -A 20 "^claim_refs:" "$FILEPATH" | grep "  - " | sed 's/.*- //' | tr -d '"')

  # Validate each claim_ref exists in CLAIM_REGISTRY
  for claim_ref in $claim_refs; do
    if ! printf '%s\n' "${CLAIM_REGISTRY[@]}" | grep -q "^${claim_ref}$"; then
      log_conditional ERROR "FAKE claim detected in ${trend_file}: ${claim_ref}"
      log_conditional ERROR "  Claim NOT in Phase 3 registry (loaded from 10-claims/data/)"
      validation_passed=false
      invalid_trends+=("${trend_file}:${claim_ref}")
    fi
  done
done

if [ "$validation_passed" = "false" ]; then
  log_conditional ERROR "⛔ BLOCKING: Fake claim IDs detected in frontmatter"
  log_conditional ERROR "Fabricated claims: ${invalid_trends[*]}"
  log_conditional ERROR "REMEDIATION: LLM invented claim IDs not loaded in Phase 3"
  log_conditional ERROR "  1. Review Phase 3 Step 2.5 claim loading"
  log_conditional ERROR "  2. Verify CLAIM_REGISTRY contains all valid claims"
  log_conditional ERROR "  3. Regenerate trends using only registry claims"
  exit 1
fi

log_conditional INFO "Claim validation PASSED - all claim_refs exist in registry ✓"
```

**Validation Logic:**

1. Extract `claim_refs` array from each trend's frontmatter
2. For each claim_ref, check if exists in `CLAIM_REGISTRY` (built in Phase 3 Step 2.5)
3. If ANY claim_ref NOT in registry → ABORT with error listing fake claims
4. If all pass → Continue to Step 4.3

**Why This Matters:**

- CLAIM_REGISTRY is built from actual files loaded in Phase 3
- LLM may invent plausible-looking claim IDs during synthesis
- This layer catches fabrication BEFORE trends are written to disk
- Earlier detection = easier remediation (regenerate synthesis vs file cleanup)

**Mark Step 4.2.5 completed, Step 4.3 in_progress**

---

### Step 4.3: Strategic Value Validation ("So What?" Test)

**Purpose:** Ensure trends deliver genuine strategic value, not truistic or obvious conclusions.

Use structured reasoning to validate each drafted trend:

```xml
<thinking>

**4.3.1 - "So What?" Test:**

FOR EACH drafted trend:
- Would an industry expert find this surprising? (yes/no/partial)
- Does this tell the reader something non-obvious? (yes/no)
- Is there a concrete decision this trend enables? (yes/no)
- Score: count(yes) / 3

Threshold: Score must be ≥ 2/3 (at least 2 "yes" answers)

**4.3.2 - Truism Detection:**

Scan each trend for:
- Vague qualifiers: "should consider", "may benefit", "could potentially", "might explore"
- Obvious conclusions: "innovation is important", "technology evolves", "markets change"
- Lack of specificity: no percentages, no timeframes, no named entities/technologies

Flagged trends: [list trend titles with specific issues]

**4.3.3 - Remediation Actions:**

FOR EACH flagged trend:
- Replace vague qualifiers with specific recommendations
  - ❌ "Organizations should consider AI adoption"
  - ✅ "Organizations with >500 employees should pilot AI in customer service by Q3 2025"
- Add quantification from claims (percentages, dates, figures)
- Connect to specific business outcomes (cost reduction %, time savings, risk mitigation)
- If unfixable due to insufficient evidence, merge with stronger related trend

**4.3.4 - Final Validation:**

- Trends passing "So What?" (≥2/3): {count} ✓
- Trends remediated: {count}
- Trends merged: {count}
- Trends remaining flagged: {count} ⚠️ (require further work)

</thinking>
```

**Validation Criteria:**

| Criterion | Pass | Fail |
|-----------|------|------|
| "So What?" score | ≥ 2/3 | < 2/3 |
| Vague qualifiers | 0-1 instances | 2+ instances |
| Specificity | Has numbers/names/dates | Generic statements only |
| Actionability | Clear next steps | No concrete guidance |

**Mark Step 4.3 completed, Step 5 in_progress**

---

## 🚦 GATE CHECK #4: Content Writing Completeness

**STOP. Verify content before proceeding to citations.**

Self-verification questions:

- [ ] Did I write all STANDARD sections (Context, Evidence, Tensions & Limitations, Implications, Planning Horizon)?
- [ ] Does Implications section have Strategic and Operational subsections?
- [ ] Does each trend have 1100-1350 words?
- [ ] Did I include 1+ claim quote in Context section?
- [ ] Did I include 2+ claim quotes in Evidence section?
- [ ] Did I address contradictions or gaps in Tensions & Limitations section?
- [ ] Did I add Planning Horizon section with explanation sentence?
- [ ] Did I add Claim Evidence section with 3+ claims?
- [ ] Did all trends pass "So What?" validation (Step 4.3)?
- [ ] Are Steps 4.1-4.3 all marked `completed` in TodoWrite?

**IF ANY ANSWER IS NO:** Return to incomplete step. DO NOT proceed.

**IF ALL YES:** Continue to Step 5.

---

## Step 5: Add Inline Citations

### Step 5.1: Citation Formats

**Finding/Concept/Megatrend Citations:** `<sup>[[entity-dir/data/entity-id|N]]</sup>`

**Claim Citations:** `<sup>[[10-claims/data/claim-{slug}|CN]]</sup>`

**Rules:**
1. Every factual statement requires finding/concept/megatrend citation
2. Every claim quote requires claim citation (separate numbering: C1, C2, C3...)
3. Paths: `04-findings/data/`, `05-domain-concepts/data/`, `06-megatrends/data/`, `10-claims/data/` (vault-relative, no `../`, no `.md`)
4. Sequential numbering [1], [2]... for findings; [C1], [C2]... for claims
5. Minimum 5 entity citations + 3 claim citations per trend

**Examples:**
```markdown
Organizations adopt AI rapidly<sup>[[04-findings/data/finding-ai-adoption-a1b2|1]]</sup>.

"72% of enterprises report AI adoption challenges"<sup>[[10-claims/data/claim-ai-adoption-challenges-x7y8|C1]]</sup> indicates systemic barriers<sup>[[04-findings/data/finding-barriers-c4d5|2]]</sup>.

Cloud transforms infrastructure<sup>[[04-findings/data/finding-cloud-d4e5|3]]</sup>, as evidenced by the claim that "89% of Fortune 500 companies use multi-cloud strategies"<sup>[[10-claims/data/claim-multicloud-fortune500-z9w0|C2]]</sup>.
```

**Update frontmatter:** `citation_count`, `finding_refs`, `concept_refs`, `megatrend_refs`, `claim_refs`

---

### Step 5.2: Citation Validation

Before proceeding to References, verify citation quality:

- [ ] Every factual statement has inline citation (finding/concept/megatrend)
- [ ] Citation paths use wikilink format with vault-relative paths (no `../`, no `.md`)
- [ ] Sequential numbering is consistent (no gaps, no duplicates)
- [ ] Minimum 5 entity citations per trend achieved
- [ ] `citation_count` in frontmatter matches actual count
- [ ] `finding_refs`, `concept_refs`, `megatrend_refs` arrays populated

**Common errors to check:**

| Error | Fix |
|-------|-----|
| Broken path | Verify entity file exists at path |
| Duplicate numbers | Re-sequence citations |
| Missing citation | Add `<sup>[[path\|N]]</sup>` to claim |
| Frontmatter mismatch | Recount and update `citation_count` |

**Mark Step 5.2 completed, Step 5.3 in_progress**

---

### Step 5.3: Claim Coverage Validation

**⛔ MANDATORY:** Verify minimum 3 claims per trend before proceeding.

**Validation Checklist:**

- [ ] Each trend has minimum 3 claim citations ([C1], [C2], [C3]...)
- [ ] All claim citations reference existing files in `10-claims/data/`
- [ ] `claim_refs` array in frontmatter contains all cited claim IDs
- [ ] Claim quotes appear naturally in narrative (not just listed)
- [ ] "Claim Evidence" section present with 3+ claims consolidated
- [ ] Claims have confidence_score >= 0.75

**Claim Coverage Report:**

Generate coverage summary for each trend:

```text
Trend: {trend-[a-z]itle}
- Entity citations: {count} (target: 5+)
- Claim citations: {count} (target: 3+) ✓/✗
- Claims used: [claim-id-1, claim-id-2, claim-id-3]
- Avg claim confidence: {score}
- Status: PASS / FAIL (requires remediation)
```

**If any trend fails claim coverage:**

1. Return to Step 4.2
2. Add missing claim quotes from allocated claims (Step 2.3)
3. Re-run Step 5.3 validation

**Mark Step 5.3 completed, Step 5.4 in_progress**

---

### Step 5.4: Confidence Aggregation

**Purpose:** Compute trend-[a-z]evel confidence from underlying claim confidence scores.

Use structured reasoning to aggregate confidence:

```xml
<thinking>

**5.4.1 - Extract Claim Confidences:**

FOR EACH trend:
- List all claim_refs from frontmatter
- FOR EACH claim: read confidence_score from claim entity
- confidence_scores = [0.85, 0.82, 0.78, ...]

**5.4.2 - Compute Trend Confidence:**

- trend_confidence = weighted_mean(confidence_scores)
  - Weight by claim_quality if available, else equal weights
- Round to 2 decimal places

**5.4.3 - Calibration Classification:**

- confidence_calibration =
    "high" if trend_confidence >= 0.85
    "moderate" if 0.75 <= trend_confidence < 0.85
    "low" if trend_confidence < 0.75

**5.4.4 - Update Frontmatter:**

FOR EACH trend:
- Set trend_confidence: {computed_value}
- Set confidence_calibration: "{classification}"

</thinking>
```

**Output:** Updated Claim Coverage Report:

```text
Trend: {trend-[a-z]itle}
- Entity citations: {count} (target: 5+)
- Claim citations: {count} (target: 3+) ✓/✗
- Claims used: [claim-id-1, claim-id-2, claim-id-3]
- Avg claim confidence: {score}
- Trend confidence: {computed} ({calibration})
- Status: PASS / FAIL
```

**Mark Step 5.4 completed, Step 5.5 in_progress**

---

### Step 5.5: Evidence Freshness Assessment

**Purpose:** Assess temporal validity of evidence to signal when trends may need refresh.

Use structured reasoning to assess evidence age:

```xml
<thinking>

**5.5.1 - Extract Evidence Dates:**

FOR EACH trend:
- FOR EACH cited claim:
  - Read dc:date from claim entity frontmatter
  - Store as claim_date
- claim_dates = [2024-03-15, 2023-11-20, 2024-01-08, ...]

**5.5.2 - Compute Evidence Age:**

- oldest_evidence_date = min(claim_dates)
- current_date = {today's date}
- evidence_age_months = months_since(oldest_evidence_date)

**5.5.3 - Freshness Classification:**

- evidence_freshness =
    "current" if evidence_age_months <= 12
    "aging" if 12 < evidence_age_months <= 24
    "dated" if evidence_age_months > 24

**5.5.4 - Update Frontmatter:**

FOR EACH trend:
- Set evidence_freshness: "{classification}"
- Set oldest_evidence_date: "{ISO-date}"

**5.5.5 - Freshness Warnings:**

IF any trend has evidence_freshness = "dated":
- Log warning: "Trend '{title}' contains evidence older than 24 months"
- Flag for review in execution summary

</thinking>
```

**Freshness Thresholds:**

| Classification | Age | Interpretation |
|----------------|-----|----------------|
| current | ≤12 months | Evidence is recent and reliable |
| aging | 13-24 months | Evidence may need verification |
| dated | >24 months | Evidence requires refresh |

**Mark Step 5.5 completed, Step 6 in_progress**

---

## 🚦 GATE CHECK #5: Citation & Claim Validation

**STOP. Verify all citations before proceeding to references.**

Self-verification questions:

- [ ] Does each trend have 5+ entity citations?
- [ ] Does each trend have 3+ claim citations?
- [ ] Are citation paths using wikilink format with vault-relative paths?
- [ ] Are citation numbers sequential with no gaps?
- [ ] Did I generate claim coverage report for all trends?
- [ ] Did all trends PASS claim coverage validation?
- [ ] Did I compute trend_confidence and confidence_calibration for all trends (Step 5.4)?
- [ ] Did I assess evidence_freshness and oldest_evidence_date for all trends (Step 5.5)?
- [ ] Are any trends flagged with evidence_freshness = "dated"? If yes, log warning.
- [ ] Are Steps 5.1-5.5 all marked `completed` in TodoWrite?

**IF ANY TREND FAILED CLAIM VALIDATION:** Return to Step 4.2 and add claims. DO NOT proceed.

**IF ALL VALIDATIONS PASS:** Continue to Step 6.

---

## Step 6: Create References Section

**Format:**
```markdown
## References

### Entity Citations
1. [[04-findings/data/finding-market-growth-abc123|Finding: Market Growth]]
2. [[05-domain-concepts/data/concept-digital-trans-def456|Concept: Digital Transformation]]
3. [[06-megatrends/data/megatrend-cloud-migration-g7h8i9|Megatrend: Cloud Migration]]

### Claim Citations
C1. [[10-claims/data/claim-ai-adoption-challenges-x7y8|Claim: 72% AI adoption challenges]] (confidence: 0.87)
C2. [[10-claims/data/claim-multicloud-fortune500-z9w0|Claim: Fortune 500 multi-cloud]] (confidence: 0.82)
C3. [[10-claims/data/claim-supply-chain-99-a1b2|Claim: Supply chain resilience]] (confidence: 0.91)
```

**Rules:**
- Place at end after all content
- **Separate Entity Citations and Claim Citations sections**
- Entity format: `{N}. [[entity-dir/data/entity-id|{Type}: {dc:title}]]`
- Claim format: `C{N}. [[10-claims/data/claim-id|Claim: {brief_summary}]] (confidence: {score})`
- Numbers match inline citations exactly
- Read `dc:title` from each entity
- Read `confidence_score` from each claim

**Mark Step 6 completed**

---

## Quality Targets

### Quantitative

- **Words:** 1100-1350 per trend
- **Entity Citations:** 5+ per trend, 30+ total
- **⛔ Claim Citations:** 3+ per trend (MANDATORY), 24+ total
- **Finding Coverage:** 70%+ of loaded findings
- **Claim Coverage:** 60%+ of high-confidence claims (≥0.75)
- **Trend Count:** 5-8 (cross-dimensional) or 3-15 per dimension
- **Quality Score:** composite ≥0.60 for all trends (Step 2.6)

### Claim Quality Requirements

- **Minimum per trend:** 3 claims
- **Confidence threshold:** ≥0.75
- **Quality threshold:** claim_quality ≥0.70
- **Diversity:** Claims from ≥2 different source findings preferred
- **Integration:** Claims integrated naturally in narrative (not just listed)

### Structural Requirements

- **Sections:** Context, Evidence, Tensions & Limitations, Implications (Strategic + Operational), Planning Horizon, Claim Evidence, References
- **Implications:** Must include Strategic and Operational subsections (Technical optional)
- **Tensions:** Must address contradictions or explicitly state "No material contradictions identified"
- **Planning Horizon:** Must include one sentence explaining horizon classification rationale

### Quality Metadata Requirements

- **quality_scores:** All 5 sub-scores computed and populated
- **trend_confidence:** Computed from claim confidences (Step 5.4)
- **confidence_calibration:** Set to high/moderate/low
- **evidence_freshness:** Assessed for all trends (Step 5.5)
- **addresses_questions:** Refined question IDs populated

### Qualitative

- Correct language, STANDARD structure with all required sections
- Clear narrative, all factual statements cited
- **All claim quotes properly attributed with temporal markers**
- Answers research questions (tracked via addresses_questions)
- Themes distinct and complete frontmatter
- **"Claim Evidence" section present in each trend**
- **"Tensions & Limitations" section present in each trend**
- **"Planning Horizon" section present with rationale sentence**
- **Passed "So What?" validation (Step 4.3)**

---

## Phase Completion Checklist

### Core Requirements

- [ ] Research lens analysis complete
- [ ] Claim-to-finding mapping complete (Step 1.4)
- [ ] Quality scores computed for all themes (Step 2.5)
- [ ] Trend count targets met (5-8 cross-dimensional or 3-15 per dimension)
- [ ] STANDARD format applied to all trends (including Tensions & Limitations)

### Tagging & Metadata

- [ ] Dimension tagging (if dimension-scoped)
- [ ] Tags array populated for filtering
- [ ] `claim_refs` array populated in all trend frontmatter
- [ ] `addresses_questions` array populated in all trend frontmatter
- [ ] `quality_scores` object populated with all 5 sub-scores
- [ ] `quality_rating` set (high/medium/low)

### ⛔ Citation Requirements (MANDATORY)

- [ ] Entity citations: 5+ per trend, 30+ total
- [ ] **Claim citations: 3+ per trend, 24+ total**
- [ ] All inline citations resolve to existing files
- [ ] References sections match inline citations (Entity + Claim)
- [ ] Claim quotes include temporal markers (year)

### ⛔ Claim Coverage Validation (MANDATORY)

- [ ] Each trend has minimum 3 claim citations
- [ ] All cited claims have confidence_score ≥0.75
- [ ] "Claim Evidence" section present in each trend
- [ ] Claim coverage report generated (Step 5.3)
- [ ] No trend failed claim coverage validation

### ⛔ Quality Validation (NEW)

- [ ] All trends passed "So What?" test (Step 4.3, score ≥2/3)
- [ ] No truistic content flagged without remediation
- [ ] Tensions & Limitations section present in each trend
- [ ] Implications section has Strategic and Operational subsections

### ⛔ Confidence & Freshness Validation (NEW)

- [ ] `trend_confidence` computed for all trends (Step 5.4)
- [ ] `confidence_calibration` set (high/moderate/low)
- [ ] `evidence_freshness` assessed for all trends (Step 5.5)
- [ ] `oldest_evidence_date` populated
- [ ] Warnings logged for any trends with evidence_freshness = "dated"

### Question Traceability (NEW)

- [ ] Every refined question mapped to at least 1 trend
- [ ] `addresses_questions` array populated in all trend frontmatter
- [ ] No orphan questions (questions with 0 trends)

### Workflow Completion

- [ ] All TodoWrite steps completed (Steps 1.1-6)
- [ ] Quality targets verified
- [ ] Claim allocation table complete (Step 2.3)
- [ ] Quality score table complete (Step 2.5)

**All checked?**

1. Set `phase_4_complete: true` in sprint-log.json
2. Mark Phase 4 todo completed
3. Proceed to Phase 5

**Any unchecked?** Return to relevant step.

**⚠️ BLOCKING:** Trends failing claim coverage validation (Step 5.3) or "So What?" validation (Step 4.3) MUST be remediated before Phase 5.
