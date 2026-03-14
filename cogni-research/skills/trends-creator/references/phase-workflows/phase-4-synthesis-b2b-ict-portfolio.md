---
source_what: research-types/b2b-ict-portfolio.md
source_version: v2.0
last_propagated: 2024-12-07
propagated_by: Sprint 440
---

# Phase 4: Portfolio Entity Synthesis (b2b-ict-portfolio)

<!-- COMPILED FROM: research-types/b2b-ict-portfolio.md -->
<!-- VERSION: 2024-12-07 -->
<!-- PROPAGATE: When b2b-ict-portfolio.md changes, regenerate this file -->

**Research Type:** `b2b-ict-portfolio` | **Framework:** Portfolio Entity Discovery with Service Horizons

**Objective:** Generate portfolio entities by extracting and classifying ICT solutions from findings across 8 dimensions (0-7, including provider profile) and 3 service horizons.

Transform findings, concepts, megatrends, and **claims** into individual portfolio entity files. Each portfolio represents a discovered ICT solution/service with evidence-based attributes. **NO FIXED LIMIT** on portfolio count - discover ALL portfolios with sufficient evidence.

---

## Key Differences from Other Synthesis Workflows

| Aspect | TIPS (smarter-service) | Standard | **b2b-ict-portfolio** |
|--------|----------------------|----------|----------------------|
| Entity type | trend | trend | **portfolio** |
| Fixed count | 52 (exactly) | 5-8 | **Variable (no limit)** |
| Dimensions | 4 | N/A | **8 (fixed, 0-7)** |
| Horizons | ACT/PLAN/OBSERVE | N/A | **Current/Emerging/Future** |
| Output format | TIPS sections | Context/Evidence/Implications | **Portfolio schema** |

---

## The 8 Dimensions (0-7) (MECE)

| # | Dimension Slug | Domain | Core Question |
|---|----------------|--------|---------------|
| 0 | `provider-profile-metrics` | Provider data | What are the provider's revenue, employees, locations, certifications? |
| 1 | `connectivity-services` | Network infrastructure | What network, connectivity, and communication infrastructure services are available? |
| 2 | `security-services` | Cybersecurity & compliance | What cybersecurity, identity management, and compliance services are provided? |
| 3 | `digital-workplace-services` | End-user computing | What workplace, collaboration, and end-user computing services are offered? |
| 4 | `cloud-services` | Cloud computing & platforms | What cloud-based services, platforms, and managed offerings are provided? |
| 5 | `managed-infrastructure-services` | IT operations | What data center, hosting, and IT operations services are provided? |
| 6 | `application-services` | Software development | What application development, modernization, and integration services are available? |
| 7 | `consulting-services` | Advisory & transformation | What strategic, transformation, and implementation consulting capabilities are offered? |

---

## Service Horizons

| Horizon | Slug | Timeframe | Evidence Indicators |
|---------|------|-----------|---------------------|
| **Current Offerings** | `current` | 0-1 years | Published pricing, GA status, case studies, proven SLAs |
| **Emerging Services** | `emerging` | 1-3 years | Beta programs, early adopter references, limited GA |
| **Future Roadmap** | `future` | 3+ years | Press releases, roadmap documents, announced capabilities |

---

## Critical: Claim Integration Requirement

**Every portfolio entity MUST reference minimum 3 claims.**

Claims provide verified factual assertions with confidence scores. Without claim integration:
- Portfolios lack verifiable evidence anchors
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
| `research_type` | Phase 2 analysis | `b2b-ict-portfolio` |
| `project_language` | Project config | `en` / `de` |
| `generation_mode` | Phase 2 | `dimension-scoped` (always for this type) |
| `dimension_list` | Phase 2 | 8 fixed dimensions (0-7) |

---

## Error Handling

| Scenario | Response |
|----------|----------|
| claim_count < 30 | Log warning, proceed with available claims |
| dimension has 0 portfolios | Log info, skip dimension in output |
| finding lacks portfolio evidence | Skip finding, log as non-portfolio finding |
| claim confidence < 0.75 | Exclude from synthesis, use higher-confidence claims |
| entity file not found | Skip citation, log missing entity |

---

## Phase Entry Verification

**STOP - verify before proceeding:**

1. Phase 3 complete (`phase_3_complete: true` in sprint-log.json)
2. Entities loaded: Findings (50+), Concepts (10+), Megatrends (5+), **Claims (30+)**
3. `research_type` = "b2b-ict-portfolio"
4. `generation_mode` = "dimension-scoped"
5. Dimension list available (8 dimensions 0-7)

**Verification command:**

```bash
# Check Phase 3 completion
grep -q '"phase_3_complete":\s*true' sprint-log.json && echo "Phase 3 complete" || echo "Phase 3 NOT complete"

# Count loaded entities
echo "Findings: $(find 04-findings -name '*.md' 2>/dev/null | wc -l)"
echo "Concepts: $(find 05-domain-concepts/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
echo "Megatrends: $(find 06-megatrends/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
echo "Claims: $(find 10-claims/data -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l)"
```

**Expected output:**

- Phase 3 complete
- Findings: 50+ (typically 100-200 for comprehensive portfolio research)
- Concepts: 10+
- Megatrends: 5+
- **Claims: 30+ (minimum required for claim integration)**

**Fail any?** Return to Phase 3.

---

## Step 0.5: Initialize TodoWrite

```text
- Phase 4, Step 1.1: Load research context [in_progress]
- Phase 4, Step 1.2: Dimension-finding mapping [pending]
- Phase 4, Step 1.3: Claim-to-finding mapping [pending]
- Phase 4, Step 1.4: Category-to-finding mapping [pending]
- Phase 4, Step 2.1: Portfolio candidate extraction (per dimension) [pending]
- Phase 4, Step 2.2: Horizon classification [pending]
- Phase 4, Step 2.3: Claim allocation per portfolio [pending]
- Phase 4, Step 2.4: Quality verification [pending]
- Phase 4, Step 3: Generate portfolio entity files [pending]
- Phase 4, Step 4: Apply portfolio schema [pending]
- Phase 4, Step 5.1: Add inline citations [pending]
- Phase 4, Step 5.2: Citation validation [pending]
- Phase 4, Step 5.3: Claim coverage validation [pending]
- Phase 4, Step 6: Create References sections [pending]
```

---

## Step 1: Analyze Through Research Lens

### Step 1.1: Load Research Context

1. Read `initial_question` and `refined_questions` from sprint-log.json
2. Note `research_type` = "b2b-ict-portfolio" for portfolio entity synthesis
3. List all loaded entity counts (findings, concepts, megatrends, claims)
4. Note the target provider/market (e.g., "Deutsche Telekom", "T-Systems")

### Step 1.2: Dimension-Finding Mapping

Map findings to the 8 dimensions (0-7):

```xml
<thinking>

**1.2.1 - Finding Classification:**

FOR EACH finding in 04-findings/data/:
- finding_id: {identifier}
- title: {dc:title}
- Which dimension(s) does this finding relate to?
- Does this finding describe a specific portfolio/solution/service?
- Portfolio candidate: YES/NO

**1.2.2 - Dimension Coverage Matrix:**

| Dimension | Finding Count | Portfolio Candidates |
|-----------|--------------|---------------------|
| provider-profile-metrics | {N} | {N} |
| connectivity-services | {N} | {N} |
| security-services | {N} | {N} |
| digital-workplace-services | {N} | {N} |
| cloud-services | {N} | {N} |
| managed-infrastructure-services | {N} | {N} |
| application-services | {N} | {N} |
| consulting-services | {N} | {N} |

**1.2.3 - Gap Analysis:**

- Dimensions with strong coverage (10+ findings): [list]
- Dimensions with weak coverage (<5 findings): [list]
- Findings that span multiple dimensions: [list]

</thinking>
```

**Mark Step 1.2 completed, Step 1.3 in_progress**

---

### Step 1.3: Claim-to-Finding Mapping

**MANDATORY:** Map claims to their source findings for evidence chain construction.

```xml
<thinking>

**1.3.1 - Claim Inventory:**

FOR EACH claim in 10-claims/data/:
- claim_id: {identifier}
- claim_text: {verbatim assertion}
- confidence_score: {0.0-1.0}
- finding_refs: {source finding IDs}
- Contains quantitative data? YES/NO (e.g., "99.9% SLA", "240+ professionals")

Filter: Keep only claims with confidence_score >= 0.75 AND flagged_for_review = false

**1.3.2 - Portfolio-Relevant Claims:**

Claims that describe:
- Service capabilities ("provides managed detection and response")
- Performance metrics ("99.9% uptime SLA")
- Scale indicators ("240+ security professionals")
- Certifications ("ISO 27001 certified")
- Pricing models ("subscription-based pricing")
- Partner relationships ("AWS Advanced Partner")

**1.3.3 - Claim Quality Distribution:**

- High confidence (>=0.85): {count} claims
- Medium-high (0.75-0.84): {count} claims
- Below threshold (<0.75): {count} claims (exclude from synthesis)

</thinking>
```

**Output:** Claim allocation matrix showing which claims support which findings.

**Mark Step 1.3 completed, Step 1.4 in_progress**

---

### Step 1.4: Category-to-Finding Mapping

**MANDATORY for Standard Portfolio Taxonomy compliance.**

Map findings to the 57 predefined categories (8 dimensions 0-7) using `portfolio_category` from refined questions.

```xml
<thinking>

**1.4.1 - Category Inheritance from Questions:**

FOR EACH finding in 04-findings/data/:
- finding_id: {identifier}
- question_ref: {linked refined question ID from frontmatter}
- Load question entity from 02-refined-questions/data/
- Extract portfolio_category from question frontmatter:
  - category_id: {X.Y} (e.g., "4.3")
  - category_name: {name} (e.g., "Zero Trust Architecture")
  - dimension_slug: {slug} (e.g., "security-services")

Result: Each finding inherits its category from its source question.

**1.4.2 - Category Coverage Matrix:**

Build coverage matrix across all 57 categories:

| Dimension | Category ID | Category Name | Finding Count | Discovery Status |
|-----------|-------------|---------------|---------------|------------------|
| connectivity-services | 1.1 | WAN Services | {N} | {status} |
| connectivity-services | 1.2 | SASE | {N} | {status} |
| connectivity-services | 1.3 | Internet & Cloud Connect | {N} | {status} |
| ... | ... | ... | ... | ... |
| security-services | 2.1 | Security Operations (SOC/SIEM) | {N} | {status} |
| security-services | 2.2 | Identity & Access Management | {N} | {status} |
| security-services | 2.3 | Zero Trust Architecture | {N} | {status} |
| ... | ... | ... | ... | ... |

**1.4.3 - Discovery Status Assignment:**

Assign status per category based on finding count:

| Finding Count | Discovery Status | Meaning |
|---------------|------------------|---------|
| 3+ findings | **Confirmed** | Provider offers this service (strong evidence) |
| 1-2 findings | **Emerging** | Service exists but limited evidence |
| 0 findings | **Not Offered** | No evidence for this category |

**1.4.4 - Extended Discoveries:**

Identify findings that don't map to standard 57 categories:
- Count of unmapped findings: {N}
- Potential "Extended" categories: {list}
- Note: Extended discoveries should not exceed 10-15 beyond taxonomy

</thinking>
```

**Category Coverage Summary:**

| Status | Category Count | Percentage |
|--------|----------------|------------|
| Confirmed | {N} | {%} |
| Emerging | {N} | {%} |
| Not Offered | {N} | {%} |
| Extended | {N} | (max 10-15) |

**Mark Step 1.4 completed, Step 2.1 in_progress**

---

## GATE CHECK #1: Research Lens Analysis

**STOP. Verify analysis before proceeding to portfolio discovery.**

Self-verification questions:
- [ ] Did I map all findings to dimensions?
- [ ] Did I identify portfolio candidate findings?
- [ ] Did I create claim-to-finding matrix with claim counts?
- [ ] Did I map findings to Standard Portfolio Taxonomy categories?
- [ ] Did I build category coverage matrix with discovery status?
- [ ] Are Steps 1.1-1.4 all marked `completed` in TodoWrite?

**IF ANY ANSWER IS NO:** Return to incomplete step. DO NOT proceed.

**IF ALL YES:** Continue to Step 2.

---

## Step 2: Portfolio Discovery Per Dimension

### Step 2.1: Portfolio Candidate Extraction

**CRITICAL: NO FIXED LIMIT - Extract ALL portfolio candidates with evidence.**

```xml
<thinking>

**2.1.0 - Dimension Iteration:**

FOR EACH dimension in [provider-profile-metrics, connectivity-services, security-services, digital-workplace-services, cloud-services, managed-infrastructure-services, application-services, consulting-services]:
  Execute Steps 2.1.1-2.1.4 for this dimension
  Target: ALL portfolios with sufficient evidence (minimum 1 finding, ideally 3+ claims)

**2.1.1 - Portfolio Identification (Per Dimension):**

FOR EACH finding tagged to current dimension:
- Does this finding describe a named service/product/platform/solution?
- Extract portfolio_name (exact name from finding)
- Extract portfolio_type: product | service | platform | solution | suite
- Extract key attributes mentioned:
  - USP / differentiators
  - Pricing model (if mentioned)
  - Delivery model (if mentioned)
  - Technology partners (if mentioned)
  - Industry verticals (if mentioned)

**2.1.2 - Portfolio Deduplication:**

- Group findings that describe the SAME portfolio
- Merge attributes from multiple findings
- Keep distinct portfolio_name as primary identifier
- Example: "Open Telekom Cloud" mentioned in 5 findings = 1 portfolio entity

**2.1.3 - Evidence Strength Assessment:**

FOR EACH unique portfolio:
- finding_count: {N} findings mentioning this portfolio
- claim_count: {N} claims supporting this portfolio
- evidence_strength: Strong (3+ findings, 3+ claims) | Moderate (1-2 findings, 1-2 claims) | Weak (<1 finding)

**2.1.4 - Minimum Evidence Filter:**

- Include: Portfolios with 1+ findings AND 1+ claims (confidence >= 0.75)
- Exclude: Portfolios with 0 claims or only weak evidence
- Log excluded portfolios for transparency

</thinking>
```

**Mark Step 2.1 completed, Step 2.2 in_progress**

---

### Step 2.2: Horizon Classification

Classify each portfolio by service horizon based on evidence:

```xml
<thinking>

**2.2.1 - Horizon Evidence Mapping:**

FOR EACH portfolio candidate:
- portfolio_name: {name}
- horizon_evidence:
  - CURRENT indicators: GA status, published pricing, customer references, case studies
  - EMERGING indicators: Beta/pilot status, limited availability, early adopter program
  - FUTURE indicators: Announced capability, roadmap mention, no pricing yet

**2.2.2 - Classification Rules:**

| Evidence Type | Horizon Assignment |
|--------------|-------------------|
| "generally available", "production", pricing published | CURRENT |
| "beta", "pilot", "preview", "early access" | EMERGING |
| "announced", "planned", "roadmap", "coming soon" | FUTURE |
| No explicit indicator | Default to CURRENT (assume GA if actively marketed) |

**2.2.3 - Horizon Distribution:**

| Dimension | Current | Emerging | Future | Total |
|-----------|---------|----------|--------|-------|
| provider-profile-metrics | {N} | {N} | {N} | {N} |
| connectivity-services | {N} | {N} | {N} | {N} |
| security-services | {N} | {N} | {N} | {N} |
| digital-workplace-services | {N} | {N} | {N} | {N} |
| cloud-services | {N} | {N} | {N} | {N} |
| managed-infrastructure-services | {N} | {N} | {N} | {N} |
| application-services | {N} | {N} | {N} | {N} |
| consulting-services | {N} | {N} | {N} | {N} |

</thinking>
```

**Mark Step 2.2 completed, Step 2.3 in_progress**

---

### Step 2.3: Claim Allocation Per Portfolio

**MANDATORY:** Allocate minimum 3 claims to each portfolio for evidence grounding.

```xml
<thinking>

**2.3.1 - Portfolio-Claim Assignment:**

FOR EACH portfolio candidate:
- portfolio_name: {name}
- supporting_findings: [finding IDs]
- available_claims: [claims from those findings]
- selected_claims: [top 3+ by confidence_score]

**2.3.2 - Selection Algorithm:**

1. List all claims from portfolio's supporting findings
2. Filter: confidence_score >= 0.75, flagged_for_review = false
3. Sort by confidence_score (descending)
4. Select 3+ claims per portfolio (prefer diversity)
5. Prioritize claims with quantitative data

**2.3.3 - Gap Identification:**

- Portfolios with 3+ high-confidence claims: {count} (ready)
- Portfolios with 1-2 claims: {count} (may include with flag)
- Portfolios with 0 claims: {count} (exclude or flag as evidence-limited)

**2.3.4 - Supplementation Strategy:**

IF portfolio has <3 claims:
- Option A: Include medium-confidence claims (0.65-0.74)
- Option B: Flag as "evidence-limited" in frontmatter
- Option C: Exclude if no claims available

</thinking>
```

**Output:** Portfolio-claim allocation table:

| Portfolio | Dimension | Horizon | Finding Count | Claim Count | Selected Claims |
|-----------|-----------|---------|--------------|-------------|-----------------|
| {name} | {dim} | {horizon} | {N} | {M} | claim-id-1, claim-id-2, claim-id-3 |

**Mark Step 2.3 completed, Step 2.4 in_progress**

---

### Step 2.4: Quality Verification

Before proceeding, verify:
- [ ] All 8 dimensions (0-7) processed
- [ ] Each portfolio has horizon assigned
- [ ] **Each portfolio has 3+ allocated claims (or is flagged)**
- [ ] Portfolio names are unique (no duplicates)
- [ ] Evidence chain traceable (portfolio → findings → claims)

**Any unchecked?** Return to Step 2.1-2.3 and refine.

**Mark Step 2.4 completed, Step 3 in_progress**

---

## GATE CHECK #2: Portfolio Discovery Completeness

**STOP. Verify portfolios before proceeding to entity generation.**

Self-verification questions:
- [ ] Did I extract portfolios from ALL 8 dimensions (0-7)?
- [ ] Does each portfolio have at least 1 finding reference?
- [ ] Does each portfolio have 3+ claims allocated (or flagged)?
- [ ] Did I classify all portfolios by horizon?
- [ ] Are Steps 2.1-2.4 all marked `completed` in TodoWrite?

**Portfolio Count Summary:**

| Metric | Count |
|--------|-------|
| Total portfolios discovered | {N} |
| Portfolios with strong evidence (3+ claims) | {N} |
| Portfolios with limited evidence (flagged) | {N} |
| Portfolios excluded (insufficient evidence) | {N} |

**IF ANY ANSWER IS NO:** Return to incomplete step. DO NOT proceed.

**IF ALL YES:** Continue to Step 3.

---

## Step 3: Generate Portfolio Entity Files

**Filename:** `portfolio-{name-slug}-{hash6}.md`
**Location:** `{research_output_dir}/11-trends/data/`

### Portfolio Entity Schema (Frontmatter)

```yaml
---
entity_type: portfolio
dc:identifier: portfolio-{name-slug}-{hash6}
dc:title: "{Portfolio Name}"
dc:type: portfolio
dc:creator: trends-creator
dc:date: {ISO-8601}
dc:description: "{1-2 sentence description}"

# Portfolio-specific fields
portfolio_name: "{Exact Name}"
portfolio_type: product|service|platform|solution|suite
dimension: "{dimension-slug}"
service_horizon: current|emerging|future

# Standard Portfolio Taxonomy category (from refined question)
portfolio_category:
  category_id: "{X.Y}"           # e.g., "4.3"
  category_name: "{Category}"     # e.g., "Zero Trust Architecture"
  discovery_status: confirmed|emerging|not_offered|extended

# Attributes (from findings)
usp: "{Unique Selling Proposition / Differentiators}"
pricing_model: subscription|usage-based|project-based|hybrid|unknown
delivery_model: onshore|nearshore|offshore|hybrid|global|unknown
technology_partners: []
industry_verticals: []
certifications: []

# Evidence chain
research_type: b2b-ict-portfolio
finding_refs: []
concept_refs: []
claim_refs: []
citation_count: 0
word_count: 0

# Quality flags
evidence_strength: strong|moderate|limited
---
```

### Portfolio Entity Body Structure

```markdown
# {Portfolio Name}

## Overview

{2-3 sentences describing what this portfolio/service does, based on findings.}

## Key Capabilities

{Bullet list of key features/capabilities extracted from findings.}

- {Capability 1}<sup>[1](../04-findings/data/finding-id.md)</sup>
- {Capability 2}<sup>[2](../04-findings/data/finding-id.md)</sup>
- {Capability 3}

## Market Position

{1-2 paragraphs on target market, competitive positioning, unique value.}

## Evidence Summary

| Attribute | Value | Source |
|-----------|-------|--------|
| Pricing Model | {value} | <sup>[N](path)</sup> |
| Delivery Model | {value} | <sup>[N](path)</sup> |
| Key Partners | {list} | <sup>[N](path)</sup> |
| Certifications | {list} | <sup>[N](path)</sup> |

## Claim Evidence

**Key claims supporting this portfolio (minimum 3):**

1. "{claim_text_1}" (confidence: {score}) [[10-claims/data/claim-id-1|C1]]
2. "{claim_text_2}" (confidence: {score}) [[10-claims/data/claim-id-2|C2]]
3. "{claim_text_3}" (confidence: {score}) [[10-claims/data/claim-id-3|C3]]

## References

{Added in Step 6}
```

**Expected output:** Variable number of portfolio entity files based on evidence (target: 40+ for comprehensive providers)

**Mark Step 3 completed, Step 4 in_progress**

---

## GATE CHECK #3: Entity Files Created

**STOP. Verify entity files before proceeding to content writing.**

Self-verification questions:
- [ ] Did I create all portfolio entity files with frontmatter?
- [ ] Does each file have correct dimension and service_horizon?
- [ ] Are entity filenames following convention (portfolio-{slug}-{hash6}.md)?
- [ ] Is Step 3 marked `completed` in TodoWrite?

**IF ANY ANSWER IS NO:** Return to Step 3. DO NOT proceed.

**IF ALL YES:** Continue to Step 4.

---

## Step 4: Apply Portfolio Schema

### Step 4.1: Content Requirements

**Word target:** 300-500 words per portfolio entity

| Section | Word Target | Content |
|---------|-------------|---------|
| Overview | 50-100 | What it does, core value proposition |
| Key Capabilities | 50-100 | Bullet list of features with citations |
| Market Position | 100-150 | Target market, competitive differentiation |
| Evidence Summary | Table | Structured attributes with citations |
| Claim Evidence | 50-100 | Consolidated claims with confidence scores |

### Step 4.2: Write Portfolio Content

**ANTI-FABRICATION WARNING:**

**CRITICAL:** Every attribute MUST trace to loaded entities.

**FORBIDDEN:**
- Inventing portfolio features not present in findings
- Adding statistics not present in claim entities
- Guessing pricing/delivery models without evidence
- Fabricating partner relationships

**REQUIRED:**
- Draft content based ONLY on loaded entities (findings + claims)
- Use "unknown" for attributes without evidence
- Note citation placeholders for Step 5
- Track which entities support each attribute

**Mark Step 4 completed, Step 5 in_progress**

---

## Step 5: Add Inline Citations

### Step 5.1: Citation Formats

**Finding/Concept/Megatrend Citations:** `<sup>[[entity-dir/data/entity-id|N]]</sup>`

**Claim Citations:** `<sup>[[10-claims/data/claim-{slug}|CN]]</sup>`

**Rules:**
1. Every factual statement requires finding citation
2. Every claim quote requires claim citation (separate numbering: C1, C2, C3...)
3. Paths: `04-findings/data/`, `05-domain-concepts/data/`, `06-megatrends/data/`, `10-claims/data/` (vault-relative, no `../`, no `.md`)
4. Sequential numbering [1], [2]... for findings; [C1], [C2]... for claims
5. Minimum 3 entity citations + 3 claim citations per portfolio

**Update frontmatter:** `citation_count`, `finding_refs`, `concept_refs`, `megatrend_refs`, `claim_refs`

---

### Step 5.2: Citation Validation

Before proceeding to References, verify citation quality:

- [ ] Every capability/attribute has inline citation
- [ ] Citation paths use wikilink format with vault-relative paths (no `../`, no `.md`)
- [ ] Sequential numbering is consistent (no gaps, no duplicates)
- [ ] Minimum 3 entity citations per portfolio achieved
- [ ] `citation_count` in frontmatter matches actual count
- [ ] `finding_refs`, `concept_refs`, `claim_refs` arrays populated

**Mark Step 5.2 completed, Step 5.3 in_progress**

---

### Step 5.3: Claim Coverage Validation

**MANDATORY:** Verify minimum 3 claims per portfolio before proceeding.

**Validation Checklist:**

- [ ] Each portfolio has minimum 3 claim citations ([C1], [C2], [C3]...)
- [ ] All claim citations reference existing files in `10-claims/data/`
- [ ] `claim_refs` array in frontmatter contains all cited claim IDs
- [ ] "Claim Evidence" section present with 3+ claims consolidated
- [ ] Claims have confidence_score >= 0.75 (or flagged as evidence-limited)

**Claim Coverage Report:**

```text
Portfolio: {portfolio-name}
- Entity citations: {count} (target: 3+)
- Claim citations: {count} (target: 3+)
- Claims used: [claim-id-1, claim-id-2, claim-id-3]
- Avg claim confidence: {score}
- Status: PASS / FAIL / FLAGGED (evidence-limited)
```

**If any portfolio fails claim coverage:**
1. Return to Step 2.3
2. Add missing claim allocations
3. Re-run Step 5.3 validation

**Mark Step 5 completed, Step 6 in_progress**

---

## GATE CHECK #5: Citation & Claim Validation

**STOP. Verify all citations before proceeding to references.**

Self-verification questions:
- [ ] Does each portfolio have 3+ entity citations?
- [ ] Does each portfolio have 3+ claim citations?
- [ ] Are citation paths using wikilink format with vault-relative paths?
- [ ] Are citation numbers sequential with no gaps?
- [ ] Did I generate claim coverage report for all portfolios?
- [ ] Did all portfolios PASS or get FLAGGED (no failures)?
- [ ] Are Steps 5.1-5.3 all marked `completed` in TodoWrite?

**IF ANY PORTFOLIO FAILED CLAIM VALIDATION:** Return to Step 2.3 and add claims. DO NOT proceed.

**IF ALL VALIDATIONS PASS:** Continue to Step 6.

---

## Step 6: Create References Section

**Format:**

```markdown
## References

### Entity Citations
1. [[04-findings/data/{dimension}/{filename}|Finding: {title}]]
2. [[05-domain-concepts/data/{filename}|Concept: {title}]]

### Claim Citations
C1. [[10-claims/data/{filename}|Claim: {brief summary}]] (confidence: {score})
C2. [[10-claims/data/{filename}|Claim: {brief summary}]] (confidence: {score})
C3. [[10-claims/data/{filename}|Claim: {brief summary}]] (confidence: {score})
```

**Rules:**
- Place at end after all content
- **Separate Entity Citations and Claim Citations sections**
- Entity format: `{N}. [[entity-dir/data/entity-id|{Type}: {dc:title}]]`
- Claim format: `C{N}. [[10-claims/data/claim-id|Claim: {brief_summary}]] (confidence: {score})`
- Numbers match inline citations exactly

**Mark Step 6 completed**

---

## Quality Targets

### Quantitative

| Metric | Target | Notes |
|--------|--------|-------|
| **Total portfolios** | 40+ | For comprehensive providers; no upper limit |
| **Portfolios per dimension** | 3-10 avg | Varies by provider strength |
| **Words per portfolio** | 300-500 | Concise but complete |
| **Entity citations** | 3+ per portfolio | Traceable evidence |
| **Claim citations** | 3+ per portfolio | MANDATORY |
| **Finding coverage** | 70%+ | Most findings mapped to portfolios |
| **Claim coverage** | 60%+ | Most high-confidence claims used |

### Portfolio Distribution Target

| Dimension | Expected Range | Notes |
|-----------|---------------|-------|
| Cloud Services | 4-8 | IaaS, PaaS, SaaS, managed services |
| Consulting Services | 3-6 | Strategy, transformation, implementation |
| Connectivity Services | 4-8 | WAN, SD-WAN, 5G, IoT |
| Security Services | 4-8 | SOC, IAM, compliance, MDR |
| Digital Workplace | 3-6 | UC, device mgmt, VDI |
| Application Services | 4-8 | Dev, modernization, integration |
| Managed Infrastructure | 4-8 | DC, hosting, DR, operations |
| **Total** | **30-60** | Varies by provider portfolio depth |

### Qualitative

- Correct language (match project_language)
- Portfolio schema applied consistently
- Clear evidence chain (portfolio → finding → claim)
- All factual statements cited
- All claim quotes properly attributed
- "Claim Evidence" section present in each portfolio
- evidence_strength flag accurate

---

## Phase Completion Checklist

### Core Requirements

- [ ] All 8 dimensions (0-7) processed
- [ ] Portfolio candidates extracted from findings
- [ ] Horizons classified (Current/Emerging/Future)
- [ ] Portfolio schema applied to all entities

### Evidence Requirements (MANDATORY)

- [ ] Each portfolio has 3+ finding citations
- [ ] Each portfolio has 3+ claim citations
- [ ] "Claim Evidence" section present in each portfolio
- [ ] Claim coverage report generated
- [ ] No portfolio failed validation (PASS or FLAGGED)

### Output Metrics

Complete this summary before proceeding:

| Metric | Value |
|--------|-------|
| Total portfolios created | {N} |
| Portfolios by dimension | cloud:{N}, consulting:{N}, connectivity:{N}, security:{N}, workplace:{N}, application:{N}, infrastructure:{N} |
| Portfolios by horizon | current:{N}, emerging:{N}, future:{N} |
| Strong evidence (3+ claims) | {N} |
| Limited evidence (flagged) | {N} |
| Total claims integrated | {N} |
| Average claims per portfolio | {N} |

### Workflow Completion

- [ ] All TodoWrite steps completed
- [ ] Quality targets verified
- [ ] Portfolio-claim allocation table complete

**All checked?**

1. Set `phase_4_complete: true` in sprint-log.json
2. Mark Phase 4 todo completed
3. Proceed to Phase 5

**Any unchecked?** Return to relevant step.

---

## Example: Portfolio Entity

```markdown
---
entity_type: portfolio
dc:identifier: portfolio-open-telekom-cloud-a1b2c3
dc:title: "Open Telekom Cloud"
dc:type: portfolio
dc:creator: trends-creator
dc:date: 2024-12-07T10:30:00Z
dc:description: "GDPR-compliant public cloud platform with BSI C5 certification"

portfolio_name: "Open Telekom Cloud"
portfolio_type: platform
dimension: "cloud-services"
service_horizon: current

portfolio_category:
  category_id: "4.3"
  category_name: "Private Cloud"
  discovery_status: confirmed

usp: "European data sovereignty with GDPR compliance and BSI C5 certification"
pricing_model: usage-based
delivery_model: european
technology_partners: ["VMware", "Kubernetes"]
industry_verticals: ["Public Sector", "Healthcare", "Financial Services"]
certifications: ["BSI C5", "ISO 27001", "GDPR compliant"]

research_type: b2b-ict-portfolio
finding_refs: ["finding-otc-overview-abc123", "finding-otc-pricing-def456"]
concept_refs: ["concept-sovereign-cloud-g7h8i9"]
claim_refs: ["claim-otc-gdpr-x1y2z3", "claim-otc-bsi-c5-a4b5c6", "claim-otc-uptime-d7e8f9"]
citation_count: 8
word_count: 420
evidence_strength: strong
---

# Open Telekom Cloud

## Overview

Open Telekom Cloud is Deutsche Telekom's public cloud platform, providing GDPR-compliant infrastructure services with data centers exclusively in Germany<sup>[[04-findings/data/cloud-services/finding-otc-overview-abc123|1]]</sup>. The platform holds BSI C5 certification, meeting the highest German government security standards<sup>[[04-findings/data/cloud-services/finding-otc-compliance-def456|2]]</sup>.

## Key Capabilities

- IaaS services including compute, storage, and networking<sup>[[04-findings/data/cloud-services/finding-otc-overview-abc123|1]]</sup>
- Kubernetes-based container orchestration<sup>[[04-findings/data/cloud-services/finding-otc-container-g7h8i9|3]]</sup>
- Managed databases (PostgreSQL, MySQL, MongoDB)<sup>[[04-findings/data/cloud-services/finding-otc-overview-abc123|1]]</sup>
- AI/ML services and data analytics<sup>[[04-findings/data/cloud-services/finding-otc-ai-j1k2l3|4]]</sup>

## Market Position

Open Telekom Cloud targets enterprises requiring European data sovereignty, particularly in regulated industries. "The platform provides GDPR-compliant cloud services with all data stored exclusively in German data centers"<sup>[[10-claims/data/claim-otc-gdpr-x1y2z3|C1]]</sup>.

The BSI C5 certification positions it as the preferred choice for German public sector organizations, with "over 200 public sector customers using the platform"<sup>[[10-claims/data/claim-otc-public-sector-m4n5o6|C2]]</sup>.

## Evidence Summary

| Attribute | Value | Source |
|-----------|-------|--------|
| Pricing Model | Usage-based | <sup>[[04-findings/data/cloud-services/finding-otc-pricing-p7q8r9\|5]]</sup> |
| Delivery Model | European (DE data centers) | <sup>[[04-findings/data/cloud-services/finding-otc-overview-abc123\|1]]</sup> |
| Key Partners | VMware, Kubernetes | <sup>[[04-findings/data/cloud-services/finding-otc-container-g7h8i9\|3]]</sup> |
| Certifications | BSI C5, ISO 27001 | <sup>[[04-findings/data/cloud-services/finding-otc-compliance-def456\|2]]</sup> |

## Claim Evidence

**Key claims supporting this portfolio:**

1. "Open Telekom Cloud provides GDPR-compliant services with data exclusively in German data centers" (confidence: 0.92) [[10-claims/data/claim-otc-gdpr-x1y2z3|C1]]
2. "BSI C5 certification achieved, meeting German federal security requirements" (confidence: 0.89) [[10-claims/data/claim-otc-bsi-c5-a4b5c6|C2]]
3. "99.95% platform availability SLA with 24/7 support" (confidence: 0.87) [[10-claims/data/claim-otc-uptime-d7e8f9|C3]]

## References

### Entity Citations
1. [[04-findings/data/cloud-services/finding-otc-overview-abc123|Finding: OTC Platform Overview]]
2. [[04-findings/data/cloud-services/finding-otc-compliance-def456|Finding: OTC Compliance Certifications]]
3. [[04-findings/data/cloud-services/finding-otc-container-g7h8i9|Finding: OTC Container Services]]
4. [[04-findings/data/cloud-services/finding-otc-ai-j1k2l3|Finding: OTC AI/ML Capabilities]]
5. [[04-findings/data/cloud-services/finding-otc-pricing-p7q8r9|Finding: OTC Pricing Model]]

### Claim Citations
C1. [[10-claims/data/claim-otc-gdpr-x1y2z3|Claim: GDPR-compliant German data centers]] (confidence: 0.92)
C2. [[10-claims/data/claim-otc-public-sector-m4n5o6|Claim: 200+ public sector customers]] (confidence: 0.85)
C3. [[10-claims/data/claim-otc-uptime-d7e8f9|Claim: 99.95% availability SLA]] (confidence: 0.87)
```

---

*End of Phase 4: Portfolio Entity Synthesis (b2b-ict-portfolio)*
