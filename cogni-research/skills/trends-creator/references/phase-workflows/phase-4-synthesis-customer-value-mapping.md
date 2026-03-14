---
source_what: research-types/customer-value-mapping.md
source_version: v1.0
last_propagated: 2025-12-07
propagated_by: Sprint 440
---

# Phase 4: Trend Synthesis (Customer Value Mapping)

<!-- COMPILED FROM: research-types/customer-value-mapping.md -->
<!-- VERSION: 2025-12-07 -->
<!-- PROPAGATE: When customer-value-mapping.md changes, regenerate this file -->

**Research Type:** `customer-value-mapping` | **Framework:** Corporate Visions Value Story

**Objective:** Generate customer-need-mapping entities with COT reasoning chains linking customer needs to source TIPS trends and portfolio solutions

Transform customer context, loaded TIPS trends, and portfolio entities into synthesized need-mappings for each Value Story dimension. Each entity represents a customer-specific need with explicit traceability to source evidence.

---

## ⛔ CRITICAL: COT Reasoning Requirement

**Every customer-need-mapping MUST include explicit 2-step COT reasoning:**

```text
Customer Need → TIPS Trend(s) → Portfolio Solution(s)
```

This reasoning chain provides:

- Verifiable link from customer pain point to industry trend
- Explicit connection from trend to solution capability
- Traceable evidence for value-story-creator

**Without COT reasoning:**

- Entity lacks justification for the mapping
- Quality scores will be penalized
- Synthesis fails validation

---

## Variables Reference

| Variable | Source | Example |
|----------|--------|---------|
| `${PROJECT_PATH}` | Phase 1 config | `/research/customer-xyz-value-mapping` |
| `research_type` | Phase 2 analysis | `customer-value-mapping` |
| `project_language` | Project config | `en` / `de` |
| `CUSTOMER_NAME` | Phase 2 | "Deutsche Telekom" |
| `CUSTOMER_INDUSTRY` | Phase 2 | "telecommunications" |
| `SOURCE_SMARTER_SERVICE_PATH` | Phase 2 | `/research/smarter-service-telco` |
| `PORTFOLIO_FILE_PATH` | sprint-log.json | Provider-specific portfolio-mapping file (e.g., `/path/to/deutsche-telekom-portfolio.md`) |
| `B2B_ICT_TAXONOMY_PATH` | Fixed reference | `cogni-research/references/research-types/b2b-ict-portfolio.md` (for COT reasoning) |
| `TIPS_SELECTED` | Phase 3 | Array of 10-15 trend paths |
| `DIMENSION_MIN_ENTITIES` | Phase 2 | `[3, 2, 3, 2]` (why-change, why-now, why-you, why-pay) |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| TIPS_SELECTED < 10 | Log warning, proceed with available |
| PORTFOLIO_OFFERINGS < 5 | Log warning, proceed with available for Why You/Why Pay |
| Dimension entity count < minimum | Generate additional entities from web research |
| COT reasoning incomplete | Block entity creation, require full chain |
| Portfolio linkage missing for Why You/Why Pay | Log warning, flag entity for review |
| Customer name missing in context | Exit 1, return to Phase 2 |

---

## Phase Entry Verification

**STOP - verify before proceeding:**

1. Phase 3 complete (`phase_3_complete: true` in sprint-log.json)
2. Source entities available:
   - TIPS_SELECTED: 10-15 trends loaded
   - PORTFOLIO_OFFERINGS: 5-10 portfolio offerings loaded from portfolio file
   - Customer research findings: Variable (from web search)
3. `research_type` = "customer-value-mapping"
4. `CUSTOMER_NAME` and `CUSTOMER_INDUSTRY` set
5. Dimension targets: 3+2+3+2 = 10 minimum

**Verification command:**

```bash
# Check Phase 3 completion
grep -q '"phase_3_complete":\s*true' sprint-log.json && echo "✓ Phase 3 complete" || echo "✗ Phase 3 NOT complete"

# Count source entities
echo "Selected TIPS: ${#TIPS_SELECTED[@]}"
echo "Portfolio Offerings: ${#PORTFOLIO_OFFERINGS[@]}"
echo "Customer findings: $(find 04-findings/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
```

**Expected output:**

- Phase 3 complete: ✓
- Selected TIPS: 10-15
- Portfolio Offerings: 5-10
- Customer findings: Variable (new from web research)

**Fail any?** Return to Phase 3.

---

## Step 0.5: Initialize TodoWrite

```text
- Phase 4, Step 1.1: Load source TIPS entities [in_progress]
- Phase 4, Step 1.2: Load source portfolio entities [pending]
- Phase 4, Step 1.3: Load/create customer research findings [pending]
- Phase 4, Step 1.4: Map sources to Value Story dimensions [pending]
- Phase 4, Step 2.1: COT reasoning for Why Change [pending]
- Phase 4, Step 2.2: COT reasoning for Why Now [pending]
- Phase 4, Step 2.3: COT reasoning for Why You [pending]
- Phase 4, Step 2.4: COT reasoning for Why Pay [pending]
- Phase 4, Step 3: Generate customer-need-mapping entities [pending]
- Phase 4, Step 4: Add inline citations [pending]
- Phase 4, Step 5: Validate coverage [pending]
- Phase 4, Step 6: Create References sections [pending]
```

---

## Step 1: Load Source Entities

### Step 1.1: Load Source TIPS Entities

Load the selected TIPS trends from the source smarter-service project:

```bash
TIPS_ENTITIES=()

for tips_path in "${TIPS_SELECTED[@]}"; do
  # Read complete entity (no truncation)
  tips_content=$(cat "$tips_path")
  tips_id=$(extract_frontmatter "$tips_path" "dc:identifier")
  tips_dimension=$(extract_frontmatter "$tips_path" "dimension")
  tips_horizon=$(extract_frontmatter "$tips_path" "planning_horizon")
  tips_portfolio_refs=$(extract_frontmatter "$tips_path" "portfolio_refs")

  TIPS_ENTITIES+=("$tips_id:$tips_dimension:$tips_horizon:$tips_portfolio_refs")

  log_conditional INFO "[customer-value-mapping] Loaded TIPS: $tips_id ($tips_dimension/$tips_horizon)"
done

log_conditional INFO "[customer-value-mapping] Total TIPS loaded: ${#TIPS_ENTITIES[@]}"
```

**Mark Step 1.1 completed, Step 1.2 in_progress**

### Step 1.2: Load Portfolio-Mapping File

Load the provider-specific portfolio-mapping file (markdown with offering tables):

```bash
# Get portfolio-mapping file path from sprint-log.json
PORTFOLIO_FILE_PATH=$(jq -r '.portfolio_file_path // ""' .metadata/sprint-log.json)

if [ -z "$PORTFOLIO_FILE_PATH" || ! -f "$PORTFOLIO_FILE_PATH" ]; then
  log_conditional WARN "[customer-value-mapping] Portfolio-mapping file not found or not configured"
  PORTFOLIO_INTEGRATION_ENABLED=false
else
  # Read portfolio-mapping file content directly
  # File structure: markdown tables with columns: Name | Description | Domain | Link
  PORTFOLIO_FILE_CONTENT=$(cat "$PORTFOLIO_FILE_PATH")

  log_conditional INFO "[customer-value-mapping] Loaded portfolio-mapping file: $PORTFOLIO_FILE_PATH"
  PORTFOLIO_INTEGRATION_ENABLED=true
fi
```

**Portfolio-Mapping File Structure:**

The file contains markdown tables organized by B2B ICT Portfolio dimensions (8 dimensions 0-7, 57 categories). Each offering row has:

| Column | Purpose |
|--------|---------|
| Name | Provider's offering name |
| Description | What the offering provides |
| Domain | Source domain (e.g., t-systems.com) |
| **Link** | Direct URL to offering page - **use this for entity portfolio_offerings.link** |

**COT Reasoning Reference:**

For thinking about relevant portfolio categories, use the B2B ICT Portfolio taxonomy at:
`cogni-research/references/research-types/b2b-ict-portfolio.md`

This provides the 8 dimensions (0-7) and 57 standard categories for structured reasoning.

**Mark Step 1.2 completed, Step 1.3 in_progress**

### Step 1.3: Load/Create Customer Research Findings

Either load existing findings from web research or execute additional research:

```bash
CUSTOMER_FINDINGS=()

# Check for existing findings
existing_findings=$(find 04-findings/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)

if [ "$existing_findings" -ge 5 ]; then
  # Load existing findings
  for finding_path in 04-findings/data/*.md; do
    finding_id=$(extract_frontmatter "$finding_path" "dc:identifier")
    CUSTOMER_FINDINGS+=("$finding_id")
  done
  log_conditional INFO "[customer-value-mapping] Loaded $existing_findings existing customer findings"
else
  # Execute web research for customer-specific findings
  log_conditional INFO "[customer-value-mapping] Insufficient findings, executing web research"

  # Use research questions from Phase 3
  for question in "${RESEARCH_QUESTIONS[@]}"; do
    # Web search and finding creation
    # (Actual web search logic handled by skill runtime)
  done
fi
```

**Mark Step 1.3 completed, Step 1.4 in_progress**

### Step 1.4: Map Sources to Value Story Dimensions

<thinking>
## Source-to-Dimension Mapping Analysis

**TIPS by Source Dimension → Value Story Dimension:**

| Source smarter-service Dimension | Maps to Value Story |
|----------------------------------|---------------------|
| externe-effekte (T) | Why Change (primary) |
| digitale-wertetreiber (I) | Why Change, Why Pay |
| neue-horizonte (P) | Why Now, Why You |
| digitales-fundament (S) | Why You (primary) |

**Portfolio-Mapping → B2B ICT Taxonomy Reasoning:**

Use the B2B ICT Portfolio taxonomy (from `b2b-ict-portfolio.md`) to think about which portfolio categories are relevant:

| B2B ICT Dimension | Relevant Value Story Stages |
|-------------------|----------------------------|
| 1. Connectivity Services | Why You (infrastructure differentiation) |
| 2. Security Services | Why Change (risk), Why You (protection) |
| 3. Digital Workplace Services | Why Change (productivity), Why Pay (efficiency) |
| 4. Cloud Services | Why You (capabilities), Why Pay (ROI) |
| 5. Managed Infrastructure Services | Why You (reliability), Why Pay (TCO) |
| 6. Application Services | Why You (modernization), Why Pay (value) |
| 7. Consulting Services | Why Change (transformation need), Why Now (urgency) |

**Mapping Process:**

FOR EACH TIPS in TIPS_ENTITIES:
- TIPS ID: ____________
- Source dimension: ____________
- Target Value Story dimension(s): ____________
- Relevant B2B ICT categories (from taxonomy): ____________

FOR EACH B2B ICT Category needed:
- Category: ____________ (e.g., "1.1 Managed Hyperscaler Services")
- Find matching offering in portfolio-mapping file
- Extract: Name, Link (URL for entity portfolio_offerings)
</thinking>

```bash
# Map TIPS to Value Story dimensions
TIPS_BY_VALUE_STORY=(
  ["why-change"]=""
  ["why-now"]=""
  ["why-you"]=""
  ["why-pay"]=""
)

for tips_entry in "${TIPS_ENTITIES[@]}"; do
  tips_id="${tips_entry%%:*}"
  source_dim=$(echo "$tips_entry" | cut -d: -f2)

  case "$source_dim" in
    "externe-effekte")
      TIPS_BY_VALUE_STORY["why-change"]+="$tips_id "
      ;;
    "digitale-wertetreiber")
      TIPS_BY_VALUE_STORY["why-change"]+="$tips_id "
      TIPS_BY_VALUE_STORY["why-pay"]+="$tips_id "
      ;;
    "neue-horizonte")
      TIPS_BY_VALUE_STORY["why-now"]+="$tips_id "
      TIPS_BY_VALUE_STORY["why-you"]+="$tips_id "
      ;;
    "digitales-fundament")
      TIPS_BY_VALUE_STORY["why-you"]+="$tips_id "
      ;;
  esac
done

# Portfolio offerings are loaded from portfolio-mapping file in Step 1.2
# Use B2B ICT taxonomy categories to reason about relevant offerings
# Then map to specific provider offerings via Name/Link columns

log_conditional INFO "[customer-value-mapping] Source mapping complete"
```

**Mark Step 1.4 completed, Step 2.1 in_progress**

---

## Step 2: COT Reasoning per Value Story Dimension

For each dimension, generate customer-need-mappings with explicit COT reasoning chains.

### Step 2.1: COT Reasoning for Why Change (Minimum 3 entities)

<thinking>
## Why Change COT Reasoning

**Value Story Goal:** Disrupt Status Quo - expose unconsidered needs

**Customer:** {CUSTOMER_NAME}
**Industry:** {CUSTOMER_INDUSTRY}

**Available Sources:**
- TIPS (externe-effekte): [LIST IDs]
- TIPS (digitale-wertetreiber): [LIST IDs]
- Customer findings: [LIST IDs]

**Relevant B2B ICT Portfolio Categories (from taxonomy):**
Think about which categories relate to "Why Change" needs:
- 7. Consulting Services (transformation triggers)
- 2. Security Services (risk exposure)
- 3. Digital Workplace Services (productivity gaps)

**Entity 1: [Need Title]**

Customer Need:
- What unconsidered need affects {CUSTOMER_NAME}?
- Evidence from customer facts: ____________

COT Step 1 (Need → TIPS):
- Which TIPS trend explains this need?
- TIPS ID: ____________
- TIPS content summary: ____________
- Connection rationale: ____________

COT Step 2 (TIPS → Portfolio via B2B ICT Category):
- Relevant B2B ICT category: ____________ (e.g., "4.1 Security Operations")
- Find matching offering in portfolio-mapping file
- Offering Name: ____________
- Offering Link: ____________ (URL from Link column)
- If no direct match, note for Why You linkage later

Confidence Score: [0.70-1.0 based on evidence strength]
Slide Coverage: Slides 2-5

**Entity 2: [Need Title]**
[Repeat structure]

**Entity 3: [Need Title]**
[Repeat structure]

**Verification:**
- Entity count: [3+]
- All have TIPS linkage: [YES/NO]
- Customer name in context: [YES/NO]
</thinking>

**Mark Step 2.1 completed, Step 2.2 in_progress**

### Step 2.2: COT Reasoning for Why Now (Minimum 2 entities)

<thinking>
## Why Now COT Reasoning

**Value Story Goal:** Create Timing Urgency - quantify cost of delay

**Customer:** {CUSTOMER_NAME}
**Industry:** {CUSTOMER_INDUSTRY}

**Available Sources:**
- TIPS (Act horizon from any dimension): [LIST IDs]
- TIPS (neue-horizonte): [LIST IDs]
- Customer findings (timing): [LIST IDs]

**Relevant B2B ICT Portfolio Categories (from taxonomy):**
Think about which categories relate to "Why Now" urgency:
- 7.2 Digital Transformation (market timing)
- 2. Security Services (compliance deadlines)
- 6.2 Application Modernization (technical debt)

**Entity 1: [Urgency Factor Title]**

Customer Need:
- What timing pressure affects {CUSTOMER_NAME}?
- Evidence from customer facts: ____________

COT Step 1 (Urgency → TIPS):
- Which TIPS trend quantifies this urgency?
- TIPS ID: ____________
- Quantified impact: ____________
- Connection rationale: ____________

COT Step 2 (TIPS → Cost/Window):
- Cost of delay calculation: ____________
- Competitive window: ____________
- Regulatory deadline: ____________
- Relevant B2B ICT category (optional): ____________

Confidence Score: [0.70-1.0]
Slide Coverage: Slides 6-9

**Entity 2: [Urgency Factor Title]**
[Repeat structure]

**Verification:**
- Entity count: [2+]
- All have timing quantification: [YES/NO]
- Customer name in context: [YES/NO]
</thinking>

**Mark Step 2.2 completed, Step 2.3 in_progress**

### Step 2.3: COT Reasoning for Why You (Minimum 3 entities)

<thinking>
## Why You COT Reasoning

**Value Story Goal:** Differentiate Solution - connect needs to unique capabilities

**Customer:** {CUSTOMER_NAME}
**Industry:** {CUSTOMER_INDUSTRY}

**Available Sources:**
- TIPS (digitales-fundament): [LIST IDs]
- TIPS (neue-horizonte): [LIST IDs]
- Portfolio-mapping file: {PORTFOLIO_FILE_PATH}
- Customer findings (capability gaps): [LIST IDs]

**Relevant B2B ICT Portfolio Categories (from taxonomy):**
Think about which categories relate to "Why You" differentiation:
- 4. Cloud Services (infrastructure capabilities)
- 1. Connectivity Services (network differentiation)
- 6. Application Services (development/modernization)
- 5. Managed Infrastructure Services (operations excellence)

**Entity 1: [Capability Differentiation Title]**

Customer Need:
- What capability gap does {CUSTOMER_NAME} have?
- Evidence from customer facts: ____________

COT Step 1 (Gap → TIPS):
- Which TIPS trend addresses this capability?
- TIPS ID: ____________
- Solution approach summary: ____________
- Connection rationale: ____________

COT Step 2 (TIPS → Portfolio via B2B ICT Category):
- Relevant B2B ICT category: ____________ (e.g., "1.1 Managed Hyperscaler Services")
- Find matching offering in portfolio-mapping file
- Offering Name: ____________ (from Name column)
- Offering Link: ____________ (URL from Link column) ⛔ REQUIRED
- Differentiation vs. alternatives: ____________
- Business value statement: ____________

Confidence Score: [0.70-1.0]
Slide Coverage: Slides 10-13

**⛔ MANDATORY:** Why You entities MUST have portfolio linkage from portfolio-mapping file

**Entity 2: [Capability Differentiation Title]**
[Repeat structure]

**Entity 3: [Capability Differentiation Title]**
[Repeat structure]

**Verification:**
- Entity count: [3+]
- All have TIPS linkage: [YES/NO]
- All have portfolio linkage with Link URL: [YES/NO] ⛔
- Customer name in context: [YES/NO]
</thinking>

**Mark Step 2.3 completed, Step 2.4 in_progress**

### Step 2.4: COT Reasoning for Why Pay (Minimum 2 entities)

<thinking>
## Why Pay COT Reasoning

**Value Story Goal:** Justify Economics - prove ROI and value exchange

**Customer:** {CUSTOMER_NAME}
**Industry:** {CUSTOMER_INDUSTRY}

**Available Sources:**
- TIPS (digitale-wertetreiber with quantified benefits): [LIST IDs]
- Portfolio-mapping file: {PORTFOLIO_FILE_PATH}
- Customer findings (budget/ROI): [LIST IDs]
- Industry benchmarks: [from web research]

**Relevant B2B ICT Portfolio Categories (from taxonomy):**
Think about which categories relate to "Why Pay" ROI justification:
- 4. Cloud Services (cost optimization, pay-per-use)
- 3. Digital Workplace Services (productivity ROI)
- 6.6 AI, Data & Analytics (efficiency gains)
- 5. Managed Infrastructure Services (TCO reduction)

**Entity 1: [ROI Justification Title]**

Customer Need:
- What investment justification does {CUSTOMER_NAME} require?
- Evidence from customer facts: ____________

COT Step 1 (Investment → TIPS):
- Which TIPS trend provides quantified value?
- TIPS ID: ____________
- Quantified benefit: ____________
- Connection rationale: ____________

COT Step 2 (TIPS → Portfolio ROI via B2B ICT Category):
- Relevant B2B ICT category: ____________ (e.g., "1.2 Multi-Cloud Management")
- Find matching offering in portfolio-mapping file
- Offering Name: ____________ (from Name column)
- Offering Link: ____________ (URL from Link column) ⛔ REQUIRED
- Pricing model: ____________
- ROI calculation: ____________
- Payback timeline: ____________

Confidence Score: [0.70-1.0]
Slide Coverage: Slides 14-16

**⛔ MANDATORY:** Why Pay entities MUST have portfolio linkage from portfolio-mapping file and quantified metrics

**Entity 2: [ROI Justification Title]**
[Repeat structure]

**Verification:**
- Entity count: [2+]
- All have TIPS linkage: [YES/NO]
- All have portfolio linkage with Link URL: [YES/NO] ⛔
- All have quantified ROI: [YES/NO] ⛔
- Customer name in context: [YES/NO]
</thinking>

**Mark Step 2.4 completed, Step 3 in_progress**

---

## Step 3: Generate customer-need-mapping Entities

### Entity File Structure

**Filename:** `need-mapping-{dimension}-{theme-slug}-{hash6}.md`
**Location:** `{PROJECT_PATH}/11-trends/data/`

### Dublin Core Frontmatter

```yaml
---
dc:identifier: need-mapping-{theme-slug}-{hash6}
dc:title: "{Customer-Specific Need Title}"
dc:type: customer-need-mapping
dc:creator: trends-creator
dc:date: "{ISO-8601}"
dc:description: "{1-2 sentence summary}"
research_type: customer-value-mapping
dimension: "{why-change|why-now|why-you|why-pay}"
value_story_stage: "{disrupt-status-quo|create-urgency|differentiate|justify-economics}"
customer_name: "{CUSTOMER_NAME}"
customer_context: "{Why this need matters for this specific customer}"
cot_reasoning: |
  Step 1: {Customer need} connects to TIPS trend {trend-[a-z]d} because {rationale}
  Step 2: TIPS trend maps to portfolio offering {offering-name} via B2B ICT category {category-id}
confidence_score: "{0.70-1.0}"
tips_trend_ref: "[[{SOURCE_SMARTER_SERVICE_PATH}/11-trends/data/{trend-[a-z]d}]]"
portfolio_offerings:
  - name: "{Offering Name}"              # From portfolio-mapping file Name column
    link: "{URL}"                        # From portfolio-mapping file Link column
    b2b_ict_category: "{category-id}"    # e.g., "1.1 Managed Hyperscaler Services"
slide_coverage: "{Slides X-Y}"
tags: [customer-need-mapping, "{dimension-slug}", "{value-story-stage}"]
finding_refs: []
claim_refs: []
---
```

### Entity Body Structure

```markdown
# {Title}

## Customer Context

{CUSTOMER_NAME} faces {specific need description} due to {evidence from customer facts}.

## Need Analysis

### The Unconsidered Need / Urgency Factor / Capability Gap / Investment Justification

{2-3 paragraphs describing the need from the customer's perspective}

- Key evidence point 1 with citation<sup>[[04-findings/data/finding-xxx|1]]</sup>
- Key evidence point 2 with citation<sup>[2](source-tips-path)</sup>
- Quantified impact: {metric}

## Chain-of-Thought Reasoning

### Step 1: Need → Industry Trend

{CUSTOMER_NAME}'s need for {need summary} is substantiated by industry research showing {TIPS trend summary}<sup>[T1](source-tips-path)</sup>.

Key trend: "{Quote from TIPS}"

### Step 2: Trend → Solution Capability

This industry pattern is addressed by [{portfolio offering name}]({link-from-portfolio-mapping-file}), which provides {capability description}.

B2B ICT Category: {category-id} (e.g., "1.1 Managed Hyperscaler Services")

Differentiation: {How this solution uniquely addresses the need}

## Business Value

{Quantified value statement for this specific need-solution mapping}

- Metric 1: {value}
- Metric 2: {value}

## References

### TIPS Sources
T1. [{TIPS Title}]({source-tips-path})

### Portfolio Offerings (from portfolio-mapping file)
P1. [{Offering Name}]({URL-from-Link-column}) - {B2B ICT category}

### Customer Findings
1. [[04-findings/data/finding-xxx|{Finding Title}]]
```

**Mark Step 3 completed, Step 4 in_progress**

---

## Step 4: Add Inline Citations

### Citation Formats

**TIPS Citation:** `<sup>[T{N}]({source-tips-path})</sup>`

**Portfolio Citation:** `[{Offering Name}]({offering-link})` (direct markdown link)

**Finding Citation:** `<sup>[[04-findings/data/finding-{id}|{N}]]</sup>`

### Citation Rules

1. Every factual claim requires a citation
2. TIPS citations use T-prefix numbering
3. Portfolio offerings use direct markdown links (not wikilinks)
4. Customer finding citations use numeric numbering
5. TIPS paths must be relative wikilinks; portfolio uses external URLs

### Minimum Citations per Entity

| Entity Type | TIPS | Portfolio | Findings |
|-------------|------|-----------|----------|
| Why Change | 1+ | 0+ | 1+ |
| Why Now | 1+ | 0+ | 1+ |
| Why You | 1+ | 1+ ⛔ | 1+ |
| Why Pay | 1+ | 1+ ⛔ | 1+ |

**Mark Step 4 completed, Step 5 in_progress**

---

## Step 5: Validate Coverage

### Coverage Validation Checklist

**Dimension Entity Counts:**

| Dimension | Minimum | Actual | Status |
|-----------|---------|--------|--------|
| Why Change | 3 | [COUNT] | ✓/✗ |
| Why Now | 2 | [COUNT] | ✓/✗ |
| Why You | 3 | [COUNT] | ✓/✗ |
| Why Pay | 2 | [COUNT] | ✓/✗ |
| **Total** | 10 | [SUM] | ✓/✗ |

**Quality Validation:**

- [ ] All entities have COT reasoning (2 steps)
- [ ] All entities have TIPS citation
- [ ] Why You entities have portfolio linkage
- [ ] Why Pay entities have portfolio linkage
- [ ] Why Pay entities have quantified ROI
- [ ] Customer name appears in all customer_context fields
- [ ] Confidence scores ≥ 0.70

**If any check fails:** Return to Step 2 and generate additional entities.

**Mark Step 5 completed, Step 6 in_progress**

---

## Step 6: Create References Sections

For each entity, ensure References section contains:

```markdown
## References

### TIPS Sources
T1. [{TIPS Title}]({path}) - {dimension}, {horizon}
T2. [{TIPS Title}]({path}) - {dimension}, {horizon}

### Portfolio Offerings
P1. [{Offering Name}]({offering-link}) - {category}

### Customer Findings
1. [[04-findings/data/{id}|{Finding Title}]]
2. [[04-findings/data/{id}|{Finding Title}]]
```

**Mark Step 6 completed**

---

## Quality Targets

### Quantitative

| Metric | Target |
|--------|--------|
| Total entities | 10+ (3+2+3+2) |
| TIPS citations | 1+ per entity |
| Portfolio citations | 1+ for Why You/Why Pay |
| Confidence score | ≥ 0.70 all entities |
| COT reasoning | 2 steps per entity |

### Qualitative

- Clear customer context with {CUSTOMER_NAME} in all entities
- Explicit reasoning chains (not just assertions)
- Quantified business value where possible
- Proper wikilink format for TIPS references; direct links for portfolio offerings

---

## Phase Completion Checklist

### Core Requirements

- [ ] All 4 dimensions have minimum entity counts met
- [ ] Source TIPS loaded and mapped
- [ ] Source portfolio loaded and mapped
- [ ] COT reasoning complete for all entities
- [ ] Customer context preserved

### Citation Requirements

- [ ] TIPS citations present in all entities
- [ ] Portfolio citations present in Why You/Why Pay
- [ ] Cross-project wikilinks use correct format
- [ ] References sections complete

### Entity Quality

- [ ] All entities have confidence ≥ 0.70
- [ ] All entities have 2-step COT reasoning
- [ ] Customer name in all customer_context fields
- [ ] Slide coverage assigned to all entities

**All checked?**

1. Set `phase_4_complete: true` in sprint-log.json
2. Mark Phase 4 todo completed
3. Proceed to Phase 5 (synthesis-hub)

**Any unchecked?** Return to relevant step.

---

## Next Phase

Proceed to synthesis-hub [phase-4a-synthesis-hub-cross.md](../../synthesis-hub/references/phase-workflows/phase-4a-synthesis-hub-cross.md) (generic). Arc-specific narratives are delegated to `cogni-narrative:narrative-writer` via Task tool when arc_id is set.

**Synthesis-creator will:**

1. Generate research-hub.md from need-mapping entities
2. Create research-mapping.md for value-story-creator
3. Structure output by Value Story stages (slides)

---

**Size: ~10KB** | Self-contained | Value Story Framework with COT Reasoning
