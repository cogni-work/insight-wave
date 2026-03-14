# Phase 4: Trend Synthesis (TIPS Format)

**Research Type:** `smarter-service` | **Framework:** TIPS (Trend, Implications, Possibilities, Solutions)

**Scope:** Single dimension (parallel agents handle other dimensions)

**Input:** 52 refined questions from dimension planner (13 per dimension: 5 ACT + 5 PLAN + 3 OBSERVE)

**Objective:** Generate 13 claim-grounded trends for the assigned `${DIMENSION}` using TIPS framework — 5 ACT, 5 PLAN, 3 OBSERVE. Each trend synthesizes findings from the refined questions in that dimension-horizon cell (1:1 mapping).

---

## Critical Requirements

- **Minimum 3 claims per trend** (confidence ≥0.75, not flagged, quality ≥0.70)
- **13 trends total:** 5 ACT (0-6mo), 5 PLAN (6-18mo), 3 OBSERVE (18+mo)
- Without claim integration, trends fail Phase 5 validation

---

## Variables

| Variable | Source | Example |
|----------|--------|---------|
| `${PROJECT_PATH}` | Agent prompt | `/research/project-xyz` |
| `${DIMENSION}` | Agent prompt | `externe-effekte` |
| `research_type` | sprint-log.json | `smarter-service` |
| `portfolio_file_path` | sprint-log.json OR initial question `portfolio_file` | `/path/to/deutsche-telekom-portfolio.md` |

**Note:** Portfolio file is a markdown file created by `portfolio-mapping` skill containing B2B ICT service offerings in table format.

---

## Phase Entry

**Verify before proceeding:**

```bash
grep -q '"phase_3_complete":\s*true' sprint-log.json && echo "✓ Ready" || echo "✗ Return to Phase 3"
finding_count=$(find 04-findings/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ') && \
claim_count=$(find 10-claims/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ') && \
echo "Findings: $finding_count | Claims: $claim_count"
```

**Required:** Phase 3 complete, 15-30 findings, 30+ claims, research_type = "smarter-service"

---

## TodoWrite Initialization

```text
- Phase 4, Step 1: Research lens analysis [in_progress]
- Phase 4, Step 2: Pattern discovery [pending]
- Phase 4, Step 3: Generate trend entities [pending]
- Phase 4, Step 4: Apply TIPS format [pending]
- Phase 4, Step 4.6: Pre-write claim validation (LAYER 1) [pending]
- Phase 4, Step 5: Add citations [pending]
- Phase 4, Step 6: Create references [pending]
```

---

## Step 1: Research Lens Analysis

### 1.1: Load Context

Read `initial_question`, `refined_questions`, and `research_type` from sprint-log.json. Count loaded entities.

### 1.2: Question-Entity Mapping

```xml
<thinking>
**Question Analysis:** Core question type → entity types answering it
**Refined Question Mapping:** FOR EACH → finding IDs, coverage (full/partial/none)
**Coverage Assessment:** Strong (3+) vs weak (<3) vs unaddressed
</thinking>
```

### 1.3: Claim-to-Finding Mapping

Map claims (confidence ≥0.75) to source findings. Note findings with 3+, 1-2, or 0 claims.

### 1.4: Set Trend Targets

**TIPS Research Type Planning Horizon Distribution:**

The TIPS research type uses a refined question allocation that pre-determines planning horizon distribution:
- 5 ACT-focused refined questions per dimension
- 5 PLAN-focused refined questions per dimension
- 3 OBSERVE-focused refined questions per dimension
- Total: 13 refined questions × 4 dimensions = 52 trends

Each refined question maps 1:1 to a trend, inheriting its planning horizon from the question's design.

**HOWEVER:** Step 2.5 validates this horizon assignment against evidence and can override if evidence strongly conflicts.

| Horizon | Trends | Evidence Threshold |
|---------|----------|-------------------|
| ACT (0-6mo) | 5 | confidence ≥0.80, 3+ claims |
| PLAN (6-18mo) | 5 | confidence ≥0.75, 3+ claims |
| OBSERVE (18+mo) | 3 | confidence ≥0.65, 2+ claims |

### 1.5: Load Portfolio File (Optional)

**Determine portfolio file path (check in order):**

1. Check sprint-log.json for `portfolio_file_path`
2. Check initial question frontmatter for `portfolio_file`
3. If both empty → `PORTFOLIO_INTEGRATION_ENABLED = false`, skip to Gate Check #1

**If portfolio file path found:**

1. Validate portfolio file exists at path:

   ```bash
   PORTFOLIO_FILE_PATH=$(jq -r '.portfolio_file_path // ""' ${PROJECT_PATH}/.metadata/sprint-log.json)

   if [ -z "$PORTFOLIO_FILE_PATH" ]; then
     # Fallback: check initial question frontmatter
     PORTFOLIO_FILE_PATH=$(grep -m1 "^portfolio_file:" ${PROJECT_PATH}/00-initial-question/data/*.md | sed 's/portfolio_file:[[:space:]]*//' | tr -d '"')
   fi

   if [ -z "$PORTFOLIO_FILE_PATH" || ! -f "$PORTFOLIO_FILE_PATH" ]; then
     PORTFOLIO_INTEGRATION_ENABLED=false
     echo "Portfolio integration disabled (file not found or not configured)"
   else
     PORTFOLIO_INTEGRATION_ENABLED=true
     echo "Portfolio file found: $PORTFOLIO_FILE_PATH"
   fi
   ```

2. **Parse portfolio file to extract offerings:**

   The portfolio file is a markdown file with this structure:
   - `## N. Dimension Name` sections (1-7)
   - `### N.N Category Name` subsections
   - Tables with columns: Name | Description | Domain | Link

   ```bash
   # Use parse-portfolio-file.sh to extract structured data
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/parse-portfolio-file.sh" \
     --file "$PORTFOLIO_FILE_PATH" \
     --json > /tmp/portfolio-parsed.json

   # The script outputs:
   # {
   #   "dimensions": {
   #     "cloud-services": {
   #       "categories": {
   #         "1.1": {
   #           "name": "Managed Hyperscaler Services",
   #           "offerings": [
   #             {"name": "Service X", "description": "...", "domain": "example.com", "link": "https://..."}
   #           ]
   #         }
   #       }
   #     }
   #   }
   # }
   ```

3. **Build keyword index for theme matching:**

   Extract offering names and descriptions for keyword matching against trend themes.

4. Set `PORTFOLIO_INTEGRATION_ENABLED = true` if offerings found
5. Store parsed portfolio data for use in Step 4.5

**Anti-Skip:** If you skipped reading the portfolio file, STOP and go back.

---

## Gate Check #1

- [ ] All refined questions mapped to entities?
- [ ] Claim-to-finding matrix created?
- [ ] Trend count targets set (15 total)?

**IF ANY NO:** Return to incomplete step.

---

## Step 2: Pattern Discovery (52 Questions → 52 Themes)

**Token Efficiency:** Use compact tabular format. Do NOT repeat full question text - questions were loaded in Phase 3. Use Q-IDs and numeric scores only.

### 2.1: Theme Extraction from 52 Refined Questions

**Input:** 52 refined questions (horizon-specific: 5 ACT + 5 PLAN + 3 OBSERVE per dimension, 1:1 mapped to trend candidates from Phase 2)

**1:1 Mapping:** Each refined question maps directly to one theme - no down-selection needed.

FOR EACH horizon (ACT, PLAN, OBSERVE) in the assigned `${DIMENSION}`:

1. Load the refined questions for this dimension-horizon cell (5 for ACT/PLAN, 3 for OBSERVE)
2. Map each question 1:1 to a theme
3. Verify evidence quality for each theme

```xml
<thinking>
**${DIMENSION} Theme Mapping:**

| Horizon | Q-ID | Claims | Conf | Theme |
|---------|------|--------|------|-------|
| ACT | Q-1 | N | 0.XX | Theme 1 |
| ACT | Q-2 | N | 0.XX | Theme 2 |
| ACT | Q-3 | N | 0.XX | Theme 3 |
| ACT | Q-4 | N | 0.XX | Theme 4 |
| ACT | Q-5 | N | 0.XX | Theme 5 |
| PLAN | Q-6 | N | 0.XX | Theme 6 |
| PLAN | Q-7 | N | 0.XX | Theme 7 |
| PLAN | Q-8 | N | 0.XX | Theme 8 |
| PLAN | Q-9 | N | 0.XX | Theme 9 |
| PLAN | Q-10 | N | 0.XX | Theme 10 |
| OBSERVE | Q-11 | N | 0.XX | Theme 11 |
| OBSERVE | Q-12 | N | 0.XX | Theme 12 |
| OBSERVE | Q-13 | N | 0.XX | Theme 13 |
| OBSERVE | Q-14 | N | 0.XX | Theme 14 |
| OBSERVE | Q-15 | N | 0.XX | Theme 15 |

**Total themes (15):** [list Q-IDs]
**ACT Requirement:** Chance + Risk sections mandatory
</thinking>
```

**Quality verification per theme:**

1. **claim evidence × avg_confidence** (quality indicator)
2. **finding coverage** (how many findings support the question)
3. **evidence diversity** (claims from different sources)
4. **research question alignment** (answers the refined question directly)

### 2.2: Claim Allocation

Minimum 3 claims per theme. If <3 available: include medium-confidence (0.65-0.74), merge themes, or flag as evidence-limited.

### 2.3: Portfolio Mapping (Optional)

**Conditional:** Only if `PORTFOLIO_INTEGRATION_ENABLED = true`.

Match themes to portfolio entities using keyword overlap and business value alignment:

| Alignment | Criteria |
|-----------|----------|
| full | 3+ keyword matches AND same business domain |
| partial | 1-2 keyword matches OR related domain |
| emerging | conceptually related, no direct match |
| none | no meaningful connection |

Output: Theme-portfolio allocation table with `portfolio_refs[]` values.

### 2.3.5: Validate Refined Question Horizon Alignment

**Purpose:** Verify themes align with their question's planning_horizon. Override if evidence strongly conflicts.

Use structured reasoning to validate horizon assignments:

```xml
<thinking>

**2.3.5.1 - Horizon Alignment Check:**

FOR EACH theme (inherited from refined question's horizon):
- theme_name: {label}
- inherited_horizon: {act|plan|observe} (from refined question)
- avg_claim_confidence: {computed in Step 2.2}
- has_proven_implementations: {yes|no} (check findings for case studies, deployments)
- timeframe_signals: {immediate|emerging|experimental} (scan findings/claims for temporal markers)

**2.3.5.2 - Conflict Detection:**

Apply decision tree from standard.md Step 2.5:
  IF avg_claim_confidence >= 0.85 AND has_proven_implementations:
    evidence_suggests = "act"
  ELSE IF avg_claim_confidence >= 0.75:
    evidence_suggests = "plan"
  ELSE:
    evidence_suggests = "observe"

**2.3.5.3 - Override Decision:**

FOR EACH theme where evidence_suggests != inherited_horizon:
- Calculate confidence_delta = |avg_claim_confidence - horizon_threshold|
- IF confidence_delta >= 0.15 AND evidence contradicts question's horizon:
  - Log conflict: "Theme X inherited '{inherited_horizon}' but evidence suggests '{evidence_suggests}' (conf: {score}, proven implementations: {yes/no})"
  - DECISION: Override to evidence_suggests OR keep inherited_horizon to maintain 5-5-3 distribution
  - Document rationale in horizon_override_rationale field
- ELSE:
  - Keep inherited_horizon (trust refined question's design)

**2.3.5.4 - Distribution Preservation:**

AFTER overrides:
- Verify distribution still approximates 5 ACT + 5 PLAN + 3 OBSERVE per dimension
- IF distribution skewed (e.g., 8 ACT, 3 PLAN, 2 OBSERVE):
  - Re-evaluate borderline overrides to restore balance
  - Prefer keeping original question horizon for borderline cases (confidence_delta < 0.20)

</thinking>
```

**Output:** Horizon validation table:

| Theme | Inherited Horizon | Evidence Suggests | Confidence Delta | Final Horizon | Override? | Rationale |
|-------|------------------|-------------------|------------------|---------------|-----------|-----------|
| {name} | act | act | 0.00 | act | No | Alignment confirmed |
| {name} | plan | act | 0.18 | act | Yes | High confidence (0.88) + proven implementations override |
| {name} | observe | observe | 0.05 | observe | No | Alignment confirmed |

**Default:** Trust refined question's horizon unless evidence is contradictory (delta ≥ 0.15).

### 2.4: Compute Trend Quality Scores

**Purpose:** Calculate multi-dimensional quality scores for each theme to enable prioritization and identify weak themes requiring strengthening.

Use structured reasoning to compute quality metrics:

```xml
<thinking>

**2.4.1 - Evidence Strength Score (0.0-1.0):**

FOR EACH theme:
- avg_claim_confidence = mean(allocated claim confidence_scores)
- unique_findings_count = count(distinct source findings for claims)
- claim_diversity = unique_findings_count / total_claims_in_theme
- evidence_strength = avg_claim_confidence × (0.7 + 0.3 × claim_diversity)

**2.4.2 - Strategic Relevance Score (0.0-1.0):**

FOR EACH theme:
- horizon_weight = 1.0 (ACT) | 0.85 (PLAN) | 0.70 (OBSERVE)
- questions_addressed = count(refined_questions mapped to theme)
- direct_answer_ratio = findings_with_direct_answers / total_theme_findings
- strategic_relevance = horizon_weight × ((questions_addressed / 5 × 0.6) + (direct_answer_ratio × 0.4))

**2.4.3 - Actionability Score (0.0-1.0):**

FOR EACH theme:
- has_quantification = 1 if theme contains numeric claims (%, $, dates), else 0
- has_implementation_path = 1 if Solutions section can include concrete steps, else 0
- has_specificity = 1 if named entities/timeframes/technologies present, else 0
- actionability = (has_quantification + has_implementation_path + has_specificity) / 3

**2.4.4 - Novelty Score (0.0-1.0):**

FOR EACH theme:
- Extract top 5 keywords from theme
- FOR EACH other_theme: calculate jaccard_similarity(keywords, other_keywords)
- max_overlap = max(all jaccard_similarities)
- novelty = 1 - max_overlap

**2.4.5 - Composite Quality Score:**

composite = (evidence_strength × 0.35) + (strategic_relevance × 0.30) + (actionability × 0.20) + (novelty × 0.15)

Thresholds:
- High quality: composite ≥ 0.75
- Medium quality: 0.60 ≤ composite < 0.75
- Low quality: composite < 0.60 (flag for review/strengthening)

</thinking>
```

**Output:** Quality score table per theme:

| Theme | Horizon | Evidence | Relevance | Actionability | Novelty | Composite | Rating |
|-------|---------|----------|-----------|---------------|---------|-----------|--------|
| {name} | ACT | 0.82 | 0.78 | 0.85 | 0.71 | 0.79 | High |

**Low quality themes (composite < 0.60):** Either strengthen with additional claims or merge with related theme.

---

## Gate Check #2

- [ ] 13 themes total for this dimension (5 ACT + 5 PLAN + 3 OBSERVE)?
- [ ] Each theme mapped 1:1 to a refined question?
- [ ] Each theme has 3+ findings AND 3+ claims?
- [ ] Horizon validation complete (Step 2.3.5)?
- [ ] Horizon distribution approximately maintained (5-5-3)?
- [ ] Quality scores computed for all themes (Step 2.4)?
- [ ] No themes rated "Low quality" without remediation plan?

**IF ANY NO:** Return to Step 2.1.

---

## Step 3: Generate Trend Entities

**Filename:** `trend-${DIMENSION}-{horizon}-{theme-slug}-{hash6}.md`
**Location:** `${PROJECT_PATH}/11-trends/data/`

Create 15 files with Dublin Core frontmatter:

```yaml
---
dc:identifier: trend-{theme-slug}-{hash6}
dc:title: "{Two-Word Title}"
dc:type: trend
dc:creator: trends-creator
dc:date: {ISO-8601}
dc:description: "{1-2 sentence summary}"
research_type: smarter-service
synthesis_format: TIPS
dimension: "{dimension-slug}"
planning_horizon: "{act|plan|observe}"
tags: [trend, {dimension-slug}, {planning_horizon}]
finding_refs: []
concept_refs: []
megatrend_refs: []
claim_refs: []
portfolio_refs: []
addresses_questions: []                 # refined question IDs this trend answers
citation_count: 0
word_count: 0
# Quality metrics (computed in Step 2.4)
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

---

## Gate Check #3

- [ ] All 13 entity files created for this dimension?
- [ ] Each trend has valid `planning_horizon` (act|plan|observe)?
- [ ] Horizon distribution matches TIPS allocation (5 ACT + 5 PLAN + 3 OBSERVE)?
- [ ] Filenames follow convention (trend-{slug}-{hash6}.md)?

**IF ANY NO:** Return to Step 3.

---

## Step 4: Apply TIPS Format

**Word target:** 950-1250 (1050-1450 with portfolio)

### 4.1: TIPS Structure

```markdown
# {Title}

## Trend
{Observable pattern, 200-250 words, 1+ claim quote}

**Tensions:** {Optional, 1-2 sentences if contradicting trend evidence exists. Cite both claims with confidence scores. Omit if no tensions.}

## Implications
{Why it matters, 200-250 words, 1+ claim quote}

**For decision-makers:** {1 sentence on strategic impact - resource allocation, investment priorities}
**For practitioners:** {1 sentence on operational impact - implementation considerations, process changes}

**Tensions:** {Optional, 1-2 sentences on impact uncertainty or dependency assumptions. Omit if no tensions.}

## Possibilities
{What could happen, 200-250 words, 1+ claim quote}

### Chance (ACT: REQUIRED)
{Quantified benefit, 50-100 words}

### Risk (ACT: REQUIRED)
{Cost of inaction, 50-100 words}

**Tensions:** {Optional, 1-2 sentences on feasibility constraints or resource debates. Omit if no tensions.}

## Planning Horizon: {act|plan|observe}
{One sentence explaining why this trend is classified in this horizon based on evidence maturity, implementation readiness, and timeframe signals from Step 2.3.5 analysis. If horizon was inherited from refined question without override, state that explicitly.}

**Examples:**
- ACT (no override): "Classified as 'act' per refined question design, confirmed by high claim confidence (0.87) and proven implementations in production."
- PLAN (override): "Originally inherited 'observe' from refined question, but upgraded to 'plan' due to moderate confidence (0.78) and emerging consensus signals exceeding experimental-stage threshold."
- OBSERVE (no override): "Classified as 'observe' per refined question design, confirmed by experimental stage signals (0.71 confidence) and 24+ month deployment timeframes."

## Solutions
{What to do, 150-200 words - strategic overview}

**Tensions:** {Optional, 1-2 sentences on competing approaches or implementation tradeoffs. Omit if no tensions.}

### Implementation Steps
1. **Assessment Phase:** {What to evaluate}
2. **Planning Phase:** {Key decisions}
3. **Execution Phase:** {Core activities}
4. **Validation Phase:** {How to verify}

### Technology Enablement

| Critical Category | Why Critical | Portfolio |
|-------------------|--------------|-----------|
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link})<br>• [{Offering Name 2}]({link2}) |
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link}) |
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link})<br>• [{Offering Name 2}]({link2}) |
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link}) |
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link}) |
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link}) |
| {category_name} ({N.N}) | {1 sentence why this category enables implementation} | • [{Offering Name}]({link}) |

### T-Systems Portfolio (if portfolio enabled)
{For each offering linked in the Technology Enablement table above, write one sentence explaining how that T-Systems offering specifically supports the implementation. Use the offering's description from the portfolio file to craft a contextual sentence that connects the offering to this trend's solution.}

## Claim Evidence
1. "{claim_text}" (confidence: {score}) [[10-claims/data/{id}|C1]]
2. ...
3. ...

## References
{Added in Step 6}
```

### 4.2: Write Content

**Claim Quote Format:** `"Claim text"<sup>[[10-claims/data/claim-id|C1]]</sup>`

**Anti-Fabrication:** Draft ONLY from loaded entities. Never invent statistics or solutions.

**Language-Aware Section Headers (when project_language=de):**

Section headers MUST match the project language. Reference: [../../../../references/language-templates.md](../../../../references/language-templates.md)

**Note:** TIPS framework section names (Trend, Implications, Possibilities, Solutions) remain in **English** regardless of project language - these are methodology terms.

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Trend | Trend | Trend |
| Implications | Implications | Implications |
| Possibilities | Possibilities | Possibilities |
| Solutions | Solutions | Solutions |
| Chance | Chance | Chance |
| Risk | Risk | Risk |
| Planning Horizon | Planning Horizon | Planungshorizont |
| Implementation Steps | Implementation Steps | Umsetzungsschritte |
| Technology Enablement | Technology Enablement | Technologie-Enablement |
| Claim Evidence | Claim Evidence | Beleglage |
| References | References | Referenzen |
| For decision-makers | For decision-makers | Für Entscheidungsträger |
| For practitioners | For practitioners | Für Praktiker |

**German Body Text Formatting (when project_language=de):**

| Element | Format | Example |
|---------|--------|---------|
| Body text | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| Section content | Proper umlauts | "für" NOT "fuer", "müssen" NOT "muessen" |
| Claim quotes | Proper umlauts | Preserve original German characters |
| Filenames/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| YAML identifiers | ASCII only | dc:identifier, entity IDs |

### 4.3: Strategic Value Validation ("So What?" Test)

**Purpose:** Ensure trends deliver genuine strategic value, not truistic or obvious conclusions.

Use structured reasoning to validate each drafted trend:

```xml
<thinking>

**4.3.1 - "So What?" Test (TIPS-Adapted):**

FOR EACH drafted trend:
- Is the Trend non-obvious to industry experts? (yes/no/partial)
- Are Implications specific enough to drive decisions? (yes/no)
- Does Solutions provide concrete next steps (not vague "consider" language)? (yes/no)
- Score: count(yes) / 3

Threshold: Score must be ≥ 2/3 (at least 2 "yes" answers)

**4.3.2 - Truism Detection:**

Scan each TIPS section for:
- Vague qualifiers: "should consider", "may benefit", "could potentially"
- Obvious conclusions: "innovation is important", "technology evolves"
- Lack of specificity: no percentages, no timeframes, no named technologies

Flagged trends: [list trend titles with specific issues]

**4.3.3 - Remediation Actions:**

FOR EACH flagged trend:
- Replace vague Trend statements with specific market signals (cite claims with data)
- Add quantification to Implications from claims (percentages, dates, figures)
- Make Solutions concrete: specific technologies, timeframes, stakeholder actions
  - ❌ "Organizations should consider AI adoption"
  - ✅ "Deploy ML-based demand forecasting in supply chain by Q3 2025"
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
| Actionability | Clear next steps in Solutions | No concrete guidance |

### 4.4: B2B ICT Dimension Bridge (MANDATORY)

For each trend, map ALL 8 B2B ICT dimensions (0-7) to the most critical category within each:

1. **Analyze implementation steps** → identify requirements across all service domains
2. **For EACH of the 8 dimensions**, select the single most critical category:
   - Provider Profile (0): 6 categories (0.1-0.6)
   - Connectivity (1): 7 categories (1.1-1.7)
   - Security (2): 10 categories (2.1-2.10)
   - Digital Workplace (3): 7 categories (3.1-3.7)
   - Cloud (4): 8 categories (4.1-4.8)
   - Managed Infrastructure (5): 7 categories (5.1-5.7)
   - Applications (6): 7 categories (6.1-6.7)
   - Consulting (7): 5 categories (7.1-7.5)
3. **Write 1-sentence justification** per dimension explaining WHY that category is critical
4. **Populate Portfolio column** from `${PORTFOLIO_FILE_PATH}`:
   - Match the category ID (e.g., "3.1") to the portfolio file section (e.g., "### 3.1 WAN Services")
   - List ALL offerings from that category as bullet points: `• [Offering Name](link)`
   - Use the Name and Link columns from the portfolio file's offering tables
   - If no offerings exist for a category, leave Portfolio cell empty

**Example row:**

| SD-WAN (3.1) | Secure branch connectivity required for distributed data collection endpoints | • [IntraSelect MPLS](https://www.t-systems.com/at/de/connectivity/future-networks-und-sip/wan-services)<br>• [Managed SD-WAN](https://business.telekom.com/global/products-and-solutions/next-level-networking/sd-wan/) |

**Reference:** See `cogni-research/references/research-types/b2b-ict-portfolio.md` for full taxonomy (8 dimensions 0-7, 57 categories).

### 4.5: T-Systems Portfolio Section (Optional)

**Conditional:** Only if `PORTFOLIO_INTEGRATION_ENABLED = true`.

After completing the Technology Enablement table (4.4), write the T-Systems Portfolio section:

**Instructions:**

1. **For EACH offering linked in the Portfolio column** of the Technology Enablement table:
   - Read the offering's description from the portfolio file
   - Write ONE sentence explaining how this T-Systems offering specifically supports the trend's implementation
   - Connect the offering's capabilities to the trend's solution context

2. **Sentence format:** `[{Offering Name}]({link}) {contextual description connecting offering to this trend's solution}.`

**Example output:**

```markdown
### Portfolio

[Open Telekom Cloud](https://www.open-telekom-cloud.com/en) provides GDPR-compliant sovereign cloud infrastructure for hosting sensitive analytics workloads within EU data boundaries. [Managed SD-WAN](https://business.telekom.com/global/products-and-solutions/next-level-networking/sd-wan/) enables secure, software-defined connectivity between distributed data collection points and central processing. [Zero Trust Security](https://www.t-systems.com/us/en/security/topics/zero-trust) ensures continuous verification of all users and devices accessing the analytics platform.
```

**Note:** Use the Description column from the portfolio file to understand each offering's capabilities, then craft a sentence that connects those capabilities to this specific trend's implementation needs.

---

### Step 4.6: Pre-Write Claim Validation (LAYER 1)

**Purpose:** Validate claim_refs in frontmatter against CLAIM_REGISTRY before finalizing trends to prevent fake claim IDs.

**⛔ BLOCKING:** This validation MUST pass before Gate Check #4. If any trend contains fake claim IDs, synthesis STOPS.

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
4. If all pass → Continue to Gate Check #4

**Why This Matters:**

- CLAIM_REGISTRY is built from actual files loaded in Phase 3
- LLM may invent plausible-looking claim IDs during synthesis
- This layer catches fabrication BEFORE trends are finalized
- Earlier detection = easier remediation (regenerate synthesis vs file cleanup)

---

## Gate Check #4

- [ ] All 4 TIPS sections written (Trend, Implications, Possibilities, Solutions)?
- [ ] 950-1250 words (1050-1450 with portfolio)?
- [ ] 1+ claim in Trend, Implications, Possibilities?
- [ ] Planning Horizon section with explanation sentence?
- [ ] Implementation Steps (4 phases)?
- [ ] B2B ICT dimension bridge with 8 rows (one per dimension 0-7)?
- [ ] Portfolio column populated from `${PORTFOLIO_FILE_PATH}` (if enabled)?
- [ ] Claim Evidence section with 3+ claims?
- [ ] ACT trends have Chance/Risk?
- [ ] All trends passed "So What?" validation (Step 4.3)?
- [ ] Tensions documented where contradicting claims exist?
- [ ] Implications include stakeholder tags (For decision-makers, For practitioners)?
- [ ] **Pre-write claim validation PASSED (Step 4.6)?**

**IF ANY NO:** Return to Step 4.

---

## Step 5: Add Citations

**Entity:** `<sup>[[04-findings/data/id|N]]</sup>`
**Claim:** `<sup>[[10-claims/data/id|CN]]</sup>`

**Rules:**

- Every factual statement: entity citation
- Every claim quote: claim citation (C1, C2...)
- Minimum: 5 entity + 3 claim citations per trend
- Paths: `04-findings/data/`, `05-domain-concepts/data/`, `06-megatrends/data/`, `10-claims/data/` (vault-relative, no `../`, no `.md`)

**Validation:**

- [ ] Every factual statement cited
- [ ] Paths resolve correctly
- [ ] Sequential numbering
- [ ] Frontmatter refs populated

---

## Gate Check #5

- [ ] 5+ entity citations per trend?
- [ ] 3+ claim citations per trend?
- [ ] All citations resolve?

**IF ANY NO:** Return to Step 5.

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

**Output:** Confidence summary per trend:

| Trend | Claims | Avg Confidence | Calibration |
|---------|--------|----------------|-------------|
| {title} | 4 | 0.82 | moderate |

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

---

## Gate Check #6

- [ ] `trend_confidence` computed for all trends (Step 5.4)?
- [ ] `confidence_calibration` set (high/moderate/low)?
- [ ] `evidence_freshness` assessed for all trends (Step 5.5)?
- [ ] `oldest_evidence_date` populated?
- [ ] Warnings logged for any trends with evidence_freshness = "dated"?

**IF ANY NO:** Return to Step 5.4/5.5.

---

## Step 6: Create References

```markdown
## References

### Entity Citations
1. [[04-findings/data/{id}|Finding: {title}]]
2. [[05-domain-concepts/data/{id}|Concept: {title}]]

### Claim Citations
C1. [[10-claims/data/{id}|Claim: {summary}]] (confidence: 0.87)
C2. ...
```

---

## Quality Targets

| Metric | Per Trend | Total (13) |
|--------|-------------|-----------|
| Words | 950-1250 | — |
| Entity citations | 5+ | 65+ |
| Claim citations | 3+ | 39+ |
| B2B ICT dimension bridge | 8 (all dimensions 0-7) | 104 |
| Finding coverage | — | 70%+ |
| Claim coverage | — | 60%+ |

**Horizon Distribution (MANDATORY):**

| Horizon | Count | Requirement |
|---------|-------|-------------|
| ACT | 5 | All must have Chance/Risk with quantified metrics + Planning Horizon explanation |
| PLAN | 5 | Chance/Risk recommended + Planning Horizon explanation |
| OBSERVE | 3 | Chance/Risk optional + Planning Horizon explanation |

---

## Phase Completion

### Core Checklist

- [ ] Research lens analysis complete for `${DIMENSION}`
- [ ] 13 trends created (5 ACT + 5 PLAN + 3 OBSERVE)
- [ ] TIPS format applied with claim integration
- [ ] All ACT trends have Chance/Risk
- [ ] All trends have Planning Horizon explanation section
- [ ] Entity citations: 5+ per trend
- [ ] Claim citations: 3+ per trend
- [ ] All citations resolve
- [ ] Portfolio integration complete (if enabled)
- [ ] TodoWrite steps completed

### Quality Validation (NEW)

- [ ] Quality scores computed for all themes (Step 2.4)
- [ ] Horizon validation complete (Step 2.3.5)
- [ ] All trends passed "So What?" validation (Step 4.3)
- [ ] Planning Horizon section present with rationale sentence
- [ ] Tensions documented where contradicting claims exist (section-specific)
- [ ] Stakeholder tags present in Implications (For decision-makers, For practitioners)

### Traceability & Confidence (NEW)

- [ ] `addresses_questions` populated in all trend frontmatter
- [ ] `trend_confidence` computed for all trends (Step 5.4)
- [ ] `confidence_calibration` set (high/moderate/low)
- [ ] `evidence_freshness` assessed for all trends (Step 5.5)
- [ ] `oldest_evidence_date` populated
- [ ] Warnings logged for any trends with evidence_freshness = "dated"

**All checked?**
1. Set `phase_4_complete: true` in sprint-log.json
2. Mark Phase 4 todo completed
3. Proceed to Phase 5

### Blocking Conditions

- Total trends < 13
- Horizon distribution not 5 ACT + 5 PLAN + 3 OBSERVE
- Any trend fails claim coverage
- Missing Planning Horizon explanation section
- Missing portfolio linkage when enabled
- Any trend fails "So What?" validation without remediation
- Missing `addresses_questions` traceability

---

## Error Handling

| Scenario | Response |
|----------|----------|
| claim_count < 30 | Log warning, proceed with available |
| trend_count < 15 | Log warning, reduce horizon targets |
| dimension filter invalid | Fall back to cross-dimensional |
| claim confidence < threshold | Exclude, use higher-confidence |
| entity file not found | Skip citation, log missing |
