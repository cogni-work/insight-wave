# Phase 3: Planning (b2b-ict-portfolio)

<!-- COMPILATION METADATA -->
<!-- Source: research-types/b2b-ict-portfolio.md v3.7 -->
<!-- Compiled: 2025-12-15 | Sprint 443 - Dimension 0 Provider Profile Metrics -->
<!-- Propagation: Regenerate via PROPAGATION-PROTOCOL.md when sources change -->
<!-- Changelog: v3 - Added Dimension 0 (Provider Profile Metrics) with 6 categories, 57 total categories -->

**Research Type:** `b2b-ict-portfolio` | **Framework:** Solution Discovery with Service Horizons

**Checksum:** `sha256:3-b2b-ict-v3`

**Verification:** After reading, confirm:

```text
Reference Loaded: phase-3-planning-b2b-ict-portfolio.md | Checksum: 3-b2b-ict-v3
```

---

## ⛔ CRITICAL: Question Count Requirements

**DO NOT use generic 4-questions-per-dimension logic. Generate exactly 1 question per taxonomy category.**

| Dimension | Categories | Question Count |
|-----------|------------|----------------|
| provider-profile-metrics | 0.1-0.6 | **6** |
| connectivity-services | 1.1-1.7 | **7** |
| security-services | 2.1-2.10 | **10** |
| digital-workplace-services | 3.1-3.7 | **7** |
| cloud-services | 4.1-4.8 | **8** |
| managed-infrastructure-services | 5.1-5.7 | **7** |
| application-services | 6.1-6.7 | **7** |
| consulting-services | 7.1-7.5 | **5** |
| **TOTAL** | **57 categories** | **57 questions** |

**Validation:** If `total_questions != 57`, the schema validation will FAIL.

---

## Variables Reference

| Variable | Source | Purpose |
|----------|--------|---------|
| DIMENSION_COUNT | Phase 2 | Fixed count (8, dimensions 0-7) |
| DIMENSION_SLUGS | Phase 2 | Dimension identifiers |
| DIMENSION_DOMAIN_MAP | Phase 2 | Service domain per dimension |
| SOLUTION_EVIDENCE_MATRIX | Phase 2 | Evidence requirements per dimension |
| SERVICE_MATURITY | Phase 2 | Detected maturity (production/pilot/planned/mixed) |
| PROVIDER_SCOPE | Phase 2 | Search scope (single/segment/market) |
| CROSS_CUTTING_ATTRIBUTES | Phase 2 | Verticals, locations, partners |
| QUESTION_TEXT | Phase 0 | Original question |
| PROJECT_LANGUAGE | Phase 0 | Output language |

---

## Phase Entry Gate

**Before proceeding, verify:**

1. Phase 2 todos marked complete
2. DIMENSION_COUNT = 8 with DIMENSION_SLUGS populated (dimensions 0-7)
3. DIMENSION_DOMAIN_MAP populated (all 8 → service domains)
4. SERVICE_MATURITY and PROVIDER_SCOPE detected
5. CROSS_CUTTING_ATTRIBUTES mapped

**If any missing:** STOP → Return to Phase 2.

**⛔ Pre-Generation Assertion (log this before generating questions):**

```bash
log_conditional INFO "[b2b-ict-portfolio] Target: 57 questions (1 per taxonomy category)"
log_conditional INFO "[b2b-ict-portfolio] Distribution: provider=6, connectivity=7, security=10, workplace=7, cloud=8, infrastructure=7, application=7, consulting=5"
```

---

## Objective

Execute solution-discovery PICOT planning addressing five quality requirements:

| Requirement | Solution |
|-------------|----------|
| Solution attributes | Questions target all 8 schema attributes |
| Horizon coverage | Questions span Current/Emerging/Future |
| Cross-cutting integration | Questions include vertical/location/partner filters |
| FINER diversification | Realistic score distribution (not all 14-15/15) |
| Provider scope alignment | Search breadth matches detected scope |

---

## Evidence Matrix (Single Source of Truth)

Reference this matrix for horizon classification in Steps 3 and 5:

| Dimension | Current Offerings | Emerging Services | Future Roadmap |
|-----------|-------------------|-------------------|----------------|
| **provider-profile-metrics** | Published financials, verified employee counts, active certifications | Announced expansions, new markets, pending certifications | Strategic growth plans, M&A activity, expansion targets |
| **connectivity-services** | Production networks, carrier partnerships | 5G campus, edge connectivity pilots | 6G preparation, quantum networking |
| **security-services** | Operational SOC, certified frameworks | AI-powered detection, zero trust pilots | Quantum-safe crypto, autonomous SOC |
| **digital-workplace-services** | Managed services, proven platforms | AI-assisted workplace, advanced DEX | AR/VR workplace, autonomous IT |
| **cloud-services** | GA services, established SLAs, published pricing | Beta programs, preview features, limited GA | Announced capabilities, roadmap items |
| **managed-infrastructure-services** | Production data centers, proven DR | AIOps operations, sustainable DC | Autonomous infra, carbon-neutral ops |
| **application-services** | Established frameworks, certified teams | AI-assisted development, platform engineering | Autonomous coding, quantum algorithms |
| **consulting-services** | Established practices, certified consultants | New advisory domains, pilot methodologies | Future-of-work advisory, emerging tech |

---

## Solution Attribute Patterns

| Dimension | Primary Attributes to Extract | Secondary Attributes |
|-----------|------------------------------|---------------------|
| provider-profile-metrics | Annual Revenue, Employee Count, Geographic Presence | Certifications, Partnership Tiers, Market Rankings |
| connectivity-services | Delivery Model, Technology Partners | Coverage, Latency |
| security-services | USP, Pricing Model | Certifications, Response Times |
| digital-workplace-services | Pricing Model, Industry Verticals | Platforms, User Scale |
| cloud-services | Pricing Model, Delivery Model, Technology Partners | SLA, Certifications |
| managed-infrastructure-services | Delivery Model, USP | Tiers, Uptime, Green Certs |
| application-services | Technology Partners, Delivery Model | Frameworks, Team Size |
| consulting-services | USP, Provider Unit, Industry Verticals | Methodologies, References |

---

## Outcome Patterns (Discovery vs Vague)

**Purpose:** Ensure outcomes are specific and actionable, not generic summaries.

| Dimension | WRONG (vague) | CORRECT (discovery-focused) |
|-----------|---------------|------------------------------|
| **provider-profile-metrics** | "Unternehmensprofil" | "Dokumentierte Provider-Kennzahlen mit Umsatz, Mitarbeiteranzahl, Standorten und Zertifizierungen" |
| **connectivity-services** | "Netzwerk-Optionen" | "Erfasste Konnektivitätslösungen mit SLA-Levels, Reichweite und Technologie-Partnern" |
| **security-services** | "Security-Portfolio" | "Katalogisierte Security-Services mit Zertifizierungen, SOC-Kapazitäten und Compliance-Abdeckung" |
| **digital-workplace-services** | "Arbeitsplatz-Angebote" | "Inventarisierte Workplace-Lösungen mit Nutzer-Skalierung, Plattform-Integration und Preisstruktur" |
| **cloud-services** | "Cloud-Portfolio-Übersicht" | "Identifizierte Cloud-Lösungen mit Preismodell, Delivery-Optionen und Partner-Ökosystem je Service-Horizont" |
| **managed-infrastructure-services** | "Infrastruktur-Services" | "Dokumentierte Managed Services mit Tier-Levels, Verfügbarkeits-SLAs und Green-IT-Zertifizierungen" |
| **application-services** | "Entwicklungsangebote" | "Erfasste Entwicklungs-Services mit Framework-Expertise, Team-Modellen und Partner-Zertifizierungen" |
| **consulting-services** | "Beratungskompetenz" | "Dokumentierte Beratungsangebote mit USP, Branchenfokus und Referenz-Projekten" |

**Key Pattern:** Outcomes MUST include:

- **Discovery verb**: Identifiziert, Dokumentiert, Katalogisiert, Erfasst, Inventarisiert
- **Target attributes**: 2-4 from Solution Attribute Patterns table
- **Granularity indicator**: je Service-Horizont, pro Provider-Unit, nach Branche

**Anti-Patterns (NEVER use):**

- Generic nouns: "Übersicht", "Klarheit", "Portfolio", "Kompetenz"
- Vague outcomes: "Wettbewerbsfähigkeit", "Marktpositionierung", "Strukturelle Klarheit"
- Missing attributes: Outcomes without specific schema attributes

---

## Step 1: Initialize Phase 3 TodoWrite

Add step-level todos:

```text
- Phase 3, Step 1: Initialize [in_progress]
- Phase 3, Step 2: Context extraction [pending]
- Phase 3, Step 3: Per-dimension PICOT reasoning [pending]
- Phase 3, Step 3.5: Category-level question generation [pending]
- Phase 3, Step 4: Cross-cutting integration [SKIP - disabled for b2b-ict-portfolio]
- Phase 3, Step 5: Horizon distribution [pending]
- Phase 3, Step 6: Question distribution [pending]
- Phase 3, Step 7: Validate completeness [pending]
```

Mark Step 1 completed, Step 2 in_progress.

---

## Step 2: Extract Question Context

<thinking>
## Question Context Extraction

Question: "{QUESTION_TEXT}"

**1. Provider Scope** → Calibrates search breadth

- Single provider signals ("our portfolio", company name): → Provider-specific
- Segment signals ("enterprise", "mid-market"): → Segment-filtered
- Market signals ("landscape", "competitors"): → Market-wide
- Scope: {single | segment | market}

**2. Solution Focus** → Guides attribute extraction

- Capability signals ("what services", "offerings"): → Feature focus
- Commercial signals ("pricing", "delivery"): → Commercial focus
- Partnership signals ("partners", "ecosystem"): → Partnership focus
- Focus: {capability | commercial | partnership | comprehensive}

**3. Horizon Emphasis** → Weights question distribution

- Current signals ("available", "current", "production"): → Current heavy
- Emerging signals ("new", "emerging", "pilot"): → Emerging heavy
- Future signals ("roadmap", "planned", "future"): → Future heavy
- Mixed signals ("portfolio", "complete"): → Balanced
- Emphasis: {current | emerging | future | balanced}

**4. Vertical Specificity** → Enables filtering

- Industry mentioned: ____________
- Specificity: {generic | industry-specific | multi-vertical}
</thinking>

**Store Context:**

```bash
DIMENSION_CONTEXT[provider_scope] = $extracted_scope
DIMENSION_CONTEXT[solution_focus] = {capability|commercial|partnership|comprehensive}
DIMENSION_CONTEXT[horizon_emphasis] = {current|emerging|future|balanced}
DIMENSION_CONTEXT[vertical_specificity] = {generic|industry-specific|multi-vertical}
PICOT_OVERRIDES[search_breadth] = $provider_scope
PICOT_OVERRIDES[attribute_priority] = $solution_focus
```

Mark Step 2 completed, Step 3 in_progress.

---

## Step 3: Per-Dimension PICOT Reasoning

For each of the 8 dimensions (0-7), apply this COT template:

<thinking>
## PICOT Reasoning: {DIMENSION_NAME}

**Domain:** {service_domain}
**Primary Attributes:** {from Solution Attribute Patterns}

**P (Population):** Refine "{base_population}" with provider scope → ____________

**I (Intervention):** Apply solution discovery framing:

- capability: "Available solutions for..."
- commercial: "Pricing and delivery models for..."
- partnership: "Partner ecosystem for..."
- comprehensive: "Complete portfolio of..."

→ ____________

**C (Comparison):** Select based on provider scope:

- single: "vs. previous offerings / vs. market alternatives"
- segment: "vs. competitor segment offerings"
- market: "across providers in the market"

→ ____________

**O (Outcome):** MUST use discovery verb pattern (see Outcome Patterns table):

- Format: "{Discovery verb} {solution type} mit {attribute 1}, {attribute 2} und {attribute 3}"
- Discovery verbs: identifiziert, dokumentiert, katalogisiert, erfasst, inventarisiert
- Include 2-4 primary attributes from Solution Attribute Patterns
- Add granularity: je Service-Horizont, pro Provider-Unit, nach Branche

⛔ **FORBIDDEN patterns:**
- Generic nouns: "Übersicht", "Klarheit", "Portfolio", "Kompetenz"
- Vague outcomes: "Wettbewerbsfähigkeit", "Marktpositionierung"

→ ____________

**Outcome Specificity Check:**
- [ ] Contains discovery verb (identifiziert/dokumentiert/katalogisiert/erfasst/inventarisiert)
- [ ] Lists 2+ specific schema attributes
- [ ] Includes granularity indicator (je Horizont, pro Unit, nach Branche)

**T (Timeframe):** Apply horizon from Evidence Matrix:

- Horizon criteria: ____________
- Justified horizon: {current|emerging|future}

→ ____________

**Cross-Cutting Filter:** Based on CROSS_CUTTING_ATTRIBUTES:

- Vertical filter: ____________
- Location filter: ____________
- Partner filter: ____________

→ ____________
</thinking>

### Dimension Specifications

| Dimension | Domain | Base Population | Primary Attributes |
|-----------|--------|-----------------|-------------------|
| provider-profile-metrics | Provider context | Enterprise buyers, analysts | Revenue, Employees, Locations, Certifications |
| connectivity-services | Network | Network architects, IT operations | Delivery Model, Partners, Coverage |
| security-services | Cybersecurity | CISOs, security teams | USP, Pricing Model, Certifications |
| digital-workplace-services | End-user | CIOs, workplace teams | Pricing Model, Verticals, Platforms |
| cloud-services | Cloud computing | Cloud service buyers, IT architects | Pricing Model, Delivery Model, Partners |
| managed-infrastructure-services | Operations | IT operations, data center teams | Delivery Model, USP, Certifications |
| application-services | Development | Development leads, IT directors | Partners, Delivery Model, Frameworks |
| consulting-services | Advisory | Business leaders, transformation teams | USP, Provider Unit, Verticals |

**Store PICOT Results:**

```bash
For each dimension in DIMENSION_SLUGS:
  DIMENSION_PICOT[slug] = "$P|$I|$C|$O|$T"
  DIMENSION_HORIZON_TARGETS[slug] = $horizon_distribution
  DIMENSION_ATTRIBUTE_FOCUS[slug] = $primary_attributes
  DIMENSION_CROSS_CUTTING[slug] = $filters
```

Mark Step 3 completed, Step 3.5 in_progress.

---

## Step 3.5: Category-Level Question Generation

### Standard Portfolio Taxonomy Integration

Generate refined questions for each category within active dimensions using the Category Question Templates from `b2b-ict-portfolio.md`.

**Input:** Active dimensions from Phase 2 Step 1.5 (ACTIVE_DIMENSIONS, ACTIVE_CATEGORY_COUNT)

### Category Template Reference

Each category has a predefined question template. Load templates from `b2b-ict-portfolio.md` Section "Category Question Templates".

### Thinking Block Template

<thinking>
**Step 3.5 Execution: Category-Level Question Generation**

**3.5.1 - Active Categories Inventory:**

FOR EACH active dimension, list categories to generate questions for:

| Dimension | Active | Categories |
|-----------|--------|------------|
| provider-profile-metrics | [YES/NO] | 0.1-0.6 (6 categories) |
| connectivity-services | [YES/NO] | 1.1-1.7 (7 categories) |
| security-services | [YES/NO] | 2.1-2.10 (10 categories) |
| digital-workplace-services | [YES/NO] | 3.1-3.7 (7 categories) |
| cloud-services | [YES/NO] | 4.1-4.8 (8 categories) |
| managed-infrastructure-services | [YES/NO] | 5.1-5.7 (7 categories) |
| application-services | [YES/NO] | 6.1-6.7 (7 categories) |
| consulting-services | [YES/NO] | 7.1-7.5 (5 categories) |

Total active categories: [COUNT]

**3.5.2 - Question Generation per Category:**

FOR EACH active category:
- category_id: [e.g., 4.3]
- category_name: [e.g., Zero Trust Architecture]
- dimension_slug: [e.g., security-services]
- template_question: [from b2b-ict-portfolio.md]
- adapted_question: [contextualized for provider/market scope]

**3.5.3 - PICOT Enhancement per Category:**

FOR EACH category question:
- P: Enterprise ICT buyers evaluating {dimension_name}
- I: {category_name} offerings from {provider_scope}
- C: Market alternatives / prior solutions
- O: Documented {category_name} with pricing, delivery, partners
- T: {service_horizon} timeframe

**3.5.4 - Portfolio Category Assignment:**

Each question entity MUST include:
```yaml
portfolio_category:
  category_id: "{X.Y}"
  category_name: "{Category Name}"
  dimension_slug: "{dimension-slug}"
```

Verification:
- All active categories have questions: [YES/NO]
- Portfolio category assigned to each question: [YES/NO]
- PICOT structure complete for each: [YES/NO]
</thinking>

### Question Count by DOK Level

⛔ **MANDATORY CONSTRAINT:** Generate **exactly 1 question per active taxonomy category**. This ensures complete coverage of all 57 standard portfolio categories.

| DOK Level | Base Questions | Cross-Cutting | Total |
|-----------|----------------|---------------|-------|
| DOK-1 | **57** (1 per category) | 0 | **57** |
| DOK-2 | **57** (1 per category) | 0 | **57** |
| DOK-3 | **57** (1 per category) | 0 | **57** |
| DOK-4 | **57** (1 per category) | 0 | **57** |

**Rationale:** Cross-cutting attributes (verticals, partners, SLAs) are already captured in each category's discovery question through the portfolio schema attributes (`industry_verticals`, `technology_partners`, `pricing_model`, `delivery_model`). Separate cross-cutting questions create redundant findings with synthetic category IDs (X.1, X.2) that break portfolio entity linkage.

**Critical Requirements:**

1. **ALL 57 taxonomy categories MUST have exactly 1 question** - no category may be skipped
2. Each question MUST include `portfolio_category` with valid `category_id` (0.1-7.5) and `category_name`
3. For filtered dimensions: Generate questions only for active categories (proportionally fewer)

**Validation Gate (Step 3.5):**

```bash
# MANDATORY: Verify all 57 categories have questions
if [ "$CATEGORY_QUESTION_COUNT" -ne "$ACTIVE_CATEGORY_COUNT" ]; then
  log_conditional ERROR "Category coverage incomplete: $CATEGORY_QUESTION_COUNT / $ACTIVE_CATEGORY_COUNT"
  exit 1
fi
```

**For filtered dimensions:** Scale proportionally to active category count.

### Category Question Entity Schema

Each generated question includes portfolio_category metadata:

```json
{
  "title": "{Category Name} Discovery",
  "entity_id": "question-{category-slug}-{hash8}",
  "question_text": "{Adapted template question}",
  "rationale": "Standard Portfolio Taxonomy category {category_id} requires discovery of {category_name} offerings...",
  "picot_structure": {
    "population": "Enterprise ICT buyers evaluating {dimension_name}",
    "intervention": "{category_name} service offerings ({category_id})",
    "comparison": "Market alternatives and prior solutions",
    "outcome": "Documented {category_name} capabilities with pricing, delivery model, and technology partners",
    "timeframe": "{service_horizon} (based on DOK level)"
  },
  "finer_scores": {
    "feasible": 3,
    "interesting": 3,
    "novel": 2,
    "ethical": 3,
    "relevant": 3,
    "total": 14
  },
  "portfolio_category": {
    "category_id": "{X.Y}",
    "category_name": "{Category Name}",
    "dimension_slug": "{dimension-slug}"
  }
}
```

### Variable Assignment

```bash
# Category question generation
CATEGORY_QUESTIONS=()
CATEGORY_QUESTION_COUNT=0

# Process each active dimension
for dim in $ACTIVE_DIMENSIONS; do
  # Get categories for this dimension
  case $dim in
    provider-profile-metrics)
      CATEGORIES="0.1:Financial Scale 0.2:Workforce Capacity 0.3:Geographic Presence 0.4:Market Position 0.5:Certifications & Accreditations 0.6:Partnership Ecosystem"
      ;;
    connectivity-services)
      CATEGORIES="1.1:WAN Services 1.2:SASE 1.3:Internet & Cloud Connect 1.4:5G & IoT Connectivity 1.5:Voice Services 1.6:LAN/WLAN Services 1.7:Network-as-a-Service"
      ;;
    security-services)
      CATEGORIES="2.1:Security Operations (SOC/SIEM) 2.2:Identity & Access Management 2.3:Zero Trust Architecture 2.4:Cloud Security 2.5:Endpoint Security 2.6:Network Security 2.7:Vulnerability Management 2.8:Security Awareness 2.9:Compliance & GRC 2.10:Data Protection & Privacy"
      ;;
    digital-workplace-services)
      CATEGORIES="3.1:Unified Communications 3.2:Modern Workplace / M365 3.3:Device Management 3.4:Virtual Desktop & DaaS 3.5:IT Support Services 3.6:Digital Employee Experience 3.7:IT Asset Management"
      ;;
    cloud-services)
      CATEGORIES="4.1:Managed Hyperscaler Services 4.2:Multi-Cloud Management 4.3:Private Cloud 4.4:Hybrid Cloud 4.5:Cloud Migration Services 4.6:Cloud-Native Platform 4.7:Sovereign Cloud 4.8:Enterprise Platforms on Cloud"
      ;;
    managed-infrastructure-services)
      CATEGORIES="5.1:Data Center Services 5.2:Managed Compute & Storage 5.3:Backup & Disaster Recovery 5.4:Infrastructure Monitoring 5.5:IT Outsourcing (ITO) 5.6:Database Administration 5.7:Infrastructure Automation"
      ;;
    application-services)
      CATEGORIES="6.1:Custom Application Development 6.2:Application Modernization 6.3:Enterprise Platform Services 6.4:System Integration & API 6.5:Low-Code/No-Code Platforms 6.6:AI, Data & Analytics 6.7:DevOps & Platform Engineering"
      ;;
    consulting-services)
      CATEGORIES="7.1:IT Strategy & Architecture 7.2:Digital Transformation 7.3:Business & Industry Consulting 7.4:Program & Project Management 7.5:Vendor & Contract Management"
      ;;
  esac

  # Generate question for each category
  for cat in $CATEGORIES; do
    cat_id=$(echo "$cat" | cut -d: -f1)
    cat_name=$(echo "$cat" | cut -d: -f2-)
    CATEGORY_QUESTIONS+=("${dim}:${cat_id}:${cat_name}")
    CATEGORY_QUESTION_COUNT=$((CATEGORY_QUESTION_COUNT + 1))
  done
done

log_conditional INFO "[b2b-ict-portfolio] Category questions generated: $CATEGORY_QUESTION_COUNT"
log_conditional INFO "[b2b-ict-portfolio] Questions span ${#ACTIVE_DIMENSIONS[@]} dimensions"

# ⛔ MANDATORY VALIDATION GATE
if [ "$CATEGORY_QUESTION_COUNT" -ne "$ACTIVE_CATEGORY_COUNT" ]; then
  log_conditional ERROR "VALIDATION FAILED: Category coverage incomplete"
  log_conditional ERROR "Generated: $CATEGORY_QUESTION_COUNT | Required: $ACTIVE_CATEGORY_COUNT"
  log_conditional ERROR "ALL taxonomy categories MUST have exactly 1 question"
  exit 1
fi

# Verify portfolio_category assignment for each question
MISSING_CATEGORIES=0
for q in "${CATEGORY_QUESTIONS[@]}"; do
  if [ -z "${q##*portfolio_category*}" ]; then
    MISSING_CATEGORIES=$((MISSING_CATEGORIES + 1))
  fi
done

if [ "$MISSING_CATEGORIES" -gt 0 ]; then
  log_conditional ERROR "VALIDATION FAILED: $MISSING_CATEGORIES questions missing portfolio_category"
  exit 1
fi

log_conditional INFO "[b2b-ict-portfolio] ✓ All $CATEGORY_QUESTION_COUNT taxonomy categories covered"
```

Mark Step 3.5 completed, Step 4 in_progress.

---

## Step 4: Cross-Cutting Integration

**⛔ DISABLED for b2b-ict-portfolio**

Cross-cutting questions are NOT generated for this research type because:

1. **Schema coverage**: Each category question already extracts `industry_verticals`, `technology_partners`, `pricing_model`, and `delivery_model` as standard attributes
2. **Linkage integrity**: Synthetic category IDs (X.1, X.2) break the category→finding→portfolio entity mapping
3. **MECE principle**: The 57-category taxonomy is designed to be mutually exclusive and collectively exhaustive

**Action:** Skip this step entirely. Mark Step 4 as completed and proceed directly to Step 5.

```bash
log_conditional INFO "[b2b-ict-portfolio] Cross-cutting questions: SKIPPED (attributes captured in category schema)"
CROSS_CUTTING_TOTAL=0
```

Mark Step 4 completed (skipped), Step 5 in_progress.

---

## Step 5: Horizon Distribution

### Distribution by Horizon Emphasis

| Emphasis | Current % | Emerging % | Future % |
|----------|-----------|------------|----------|
| current | 60 | 30 | 10 |
| emerging | 25 | 50 | 25 |
| future | 10 | 30 | 60 |
| balanced | 40 | 35 | 25 |

### Per-Dimension Horizon Targets

Based on DIMENSION_CONTEXT[horizon_emphasis], calculate per-dimension targets:

```bash
# Example for "balanced" emphasis with 5 questions/dimension
# cloud-services: 2 Current, 2 Emerging, 1 Future
# consulting-services: 2 Current, 2 Emerging, 1 Future
# ... etc.
```

**Store Horizon Distribution:**

```bash
HORIZON_EMPHASIS=${DIMENSION_CONTEXT[horizon_emphasis]}

case $HORIZON_EMPHASIS in
  current)  HORIZON_DIST="60:30:10" ;;
  emerging) HORIZON_DIST="25:50:25" ;;
  future)   HORIZON_DIST="10:30:60" ;;
  balanced) HORIZON_DIST="40:35:25" ;;
esac

for slug in $DIMENSION_SLUGS; do
  DIMENSION_HORIZON_TARGETS[$slug]=$HORIZON_DIST
done

log_conditional INFO "[b2b-ict-portfolio] Horizon distribution: ${HORIZON_DIST}"
```

Mark Step 5 completed, Step 6 in_progress.

---

## Step 6: Question Distribution & Quality Controls

### 6.1 Distribution Calculation

**Fixed Question Count:**

For `b2b-ict-portfolio`, the question count is determined by the taxonomy structure:

```bash
# b2b-ict-portfolio: exactly 1 question per taxonomy category
# Total = sum of categories across all 8 dimensions (0-7)
TOTAL_QUESTIONS=57  # Fixed: 6+7+10+7+8+7+7+5 categories
CROSS_CUTTING_QUESTIONS=0  # Disabled - attributes captured in category schema
```

**Per-Dimension Distribution (by category count):**

| Dimension | Categories | Count |
|-----------|------------|-------|
| Provider Profile Metrics | 0.1-0.6 | 6 |
| Connectivity Services | 1.1-1.7 | 7 |
| Security Services | 2.1-2.10 | 10 |
| Digital Workplace | 3.1-3.7 | 7 |
| Cloud Services | 4.1-4.8 | 8 |
| Managed Infrastructure | 5.1-5.7 | 7 |
| Application Services | 6.1-6.7 | 7 |
| Consulting Services | 7.1-7.5 | 5 |
| **Total** | | **57** |

### 6.2 FINER Diversification Targets

For question sets >15, enforce realistic distribution:

| Score | Target % | Criteria |
|-------|----------|----------|
| 15/15 | 5-15% | Novel solutions, unexplored verticals, clear differentiation |
| 14/15 | 35-55% | Standard discovery, significant trend, minor gaps |
| 13/15 | 25-40% | Achievable with effort, useful catalog |
| 12/15 | 5-15% | Challenging but strategic value |

### 6.3 Solution Attribute Coverage

**Per-Dimension Attribute Checklist:**

Each dimension's questions should collectively target:

- [ ] Name (always implicit)
- [ ] Description (always implicit)
- [ ] USP (at least 1 question per dimension)
- [ ] Provider Unit (if single provider scope)
- [ ] Pricing Model (at least 1 question per dimension)
- [ ] Delivery Model (at least 1 question per dimension)
- [ ] Technology Partners (at least 1 question per dimension)
- [ ] Industry Verticals (captured in category discovery)
- [ ] Service Horizon (implicit in horizon-targeted questions)

**Store Distribution:**

```bash
DIMENSION_QUESTION_TARGETS[slug] = $count
HORIZON_DISTRIBUTION[slug] = "current:$c|emerging:$e|future:$f"
PICOT_OVERRIDES[finer_diversification_enabled] = true
ATTRIBUTE_COVERAGE[slug] = "usp,pricing,delivery,partners"
```

Mark Step 6 completed, Step 7 in_progress.

---

## Step 7: Validate Completeness

### Validation Checklist

**Core Requirements (all must pass):**

- [ ] All 8 dimensions (0-7) have PICOT patterns (5 components each)
- [ ] All 8 dimensions have horizon distribution targets
- [ ] All 8 dimensions have attribute focus defined
- [ ] Total question count = 57 (exactly 1 per taxonomy category)
- [ ] FINER diversification enabled

**Quality Controls:**

- [ ] Horizon distribution stored per dimension
- [ ] Attribute coverage checklist verified
- [ ] Provider scope alignment confirmed

**Outcome Specificity Checks (MANDATORY):**

- [ ] All outcomes use discovery verbs (identifiziert/dokumentiert/katalogisiert/erfasst/inventarisiert)
- [ ] All outcomes reference 2+ solution attributes from schema
- [ ] All outcomes include granularity indicators (je Horizont, pro Unit, nach Branche)
- [ ] NO generic outcomes ("Übersicht", "Klarheit", "Portfolio", "Kompetenz")
- [ ] NO vague outcomes ("Wettbewerbsfähigkeit", "Marktpositionierung", "Strukturelle Klarheit")

**If any check fails:** Return to relevant step.

Mark Step 7 completed, Phase 3 todos completed.

---

## Phase Completion

**All must be YES before Phase 4:**

- [ ] Solution focus detected per dimension
- [ ] All 8 PICOT patterns COT-reasoned (dimensions 0-7)
- [ ] All 57 taxonomy categories have questions
- [ ] Horizon distribution calculated
- [ ] Question distribution with attribute coverage
- [ ] Quality controls configured (FINER, coverage)
- [ ] All validation checks passed

---

## Integration Points

**Phase 4 reads:**

- `DIMENSION_PICOT` → Base patterns
- `PICOT_OVERRIDES` → Scope, focus, FINER config
- `DIMENSION_QUESTION_TARGETS` → Counts per dimension
- `HORIZON_DISTRIBUTION` → Current/Emerging/Future targets
- `ATTRIBUTE_COVERAGE` → Schema attribute targeting

**Phase 5 reads:**

- `DIMENSION_CONTEXT` → Entity metadata
- `CROSS_CUTTING_QUESTIONS` → Additional discovery questions
- `SOLUTION_SCHEMA` → Entity creation template

### Entity Schema (Phase 5)

Questions include:

```json
{
  "service_horizon": {
    "horizon": "current|emerging|future",
    "justification": "Evidence-based reason",
    "maturity_indicators": ["GA", "pilot", "roadmap"]
  },
  "target_attributes": {
    "primary": ["pricing_model", "delivery_model"],
    "secondary": ["technology_partners", "usp"]
  },
  "cross_cutting_filters": {
    "industry_verticals": ["Healthcare", "Automotive"],
    "delivery_locations": ["European", "Global"],
    "partner_ecosystem": ["AWS", "SAP"]
  },
  "provider_scope": "single|segment|market"
}
```

---

## Next Phase

Proceed to [phase-4-validation.md](phase-4-validation.md) when all criteria met.

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Dimension count ≠ 8 | Exit 1, return to Phase 2 |
| PICOT incomplete | Exit 1, complete missing dimensions |
| Cross-cutting generation failed | Log warning, proceed with base questions only |
| Horizon distribution invalid | Log warning, default to balanced |
| Attribute coverage incomplete | Log warning, add targeting questions |
| Question count out of range | Adjust scope, recalculate distribution |

---

**Size:** ~9KB | Self-contained | Solution Discovery Focus | 8 Dimensions (0-7) | 57 Categories
