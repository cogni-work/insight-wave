# Phase 2: Analysis (b2b-ict-portfolio)

<!-- COMPILATION METADATA -->
<!-- Source WHAT: research-types/b2b-ict-portfolio.md v3.7 -->
<!-- Compiled Date: 2025-12-15 -->
<!-- Compiled By: Sprint 443 - Dimension 0 Provider Profile Metrics -->
<!-- Propagation: When source WHAT files change, regenerate this file using PROPAGATION-PROTOCOL.md -->

**Research Type:** `b2b-ict-portfolio` | **Framework:** Portfolio Entity Discovery with Service Horizons

**Reference Checksum:** `sha256:2a-b2b-ict-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-2-analysis-b2b-ict-portfolio.md | Checksum: 2a-b2b-ict-v1
```

---

## Objective

Apply the embedded B2B ICT Portfolio framework (8 fixed dimensions, 0-7) with **portfolio entity-focused analysis** to:

1. Map each dimension to its service domain focus
2. Define evidence requirements for solution discovery (attributes, pricing, delivery)
3. Detect service maturity with horizon classification
4. Prepare cross-cutting attribute analysis for Phase 3 question generation

**Expected Duration:** 60-90 seconds of actual work.

---

## Service Horizons Quick Reference

| Horizon | Timeframe | Characteristics | Evidence Indicators |
|---------|-----------|-----------------|---------------------|
| **Current Offerings** | 0-1 years | Generally available, proven deployments | Published pricing, case studies, GA status |
| **Emerging Services** | 1-3 years | Pilot/beta, limited availability | Beta programs, early adopter references |
| **Future Roadmap** | 3+ years | Announced, conceptual, R&D phase | Press releases, roadmap documents, patents |

---

## Phase Entry Verification

**Before proceeding:**

1. Verify Phase 1 todos marked complete in TodoWrite
2. Verify Phase 1 outputs exist:
   - RESEARCH_TYPE variable set to `b2b-ict-portfolio`
   - DIMENSIONS_MODE variable set to `research-type-specific`
   - Mode detection logged

**If any output missing:** STOP. Return to Phase 1. Complete missing steps.

---

## Step 0.5: Initialize Phase 2 TodoWrite

Add step-level todos for Phase 2. Update TodoWrite to add 7 todos: Steps 1-7 with Step 1 marked as `in_progress` and Steps 2-7 as `pending`.

---

## Embedded Framework Definition

**Source:** B2B ICT Portfolio Analysis Definition v3.7

This phase file contains all framework content pre-compiled. No runtime loading of external files required.

---

## Step 1: Apply Dimensions with Service Domain Mapping

> ⛔ **CRITICAL - READ THIS BEFORE PROCEEDING:**
>
> **DO NOT use prior knowledge about this framework. USE ONLY VALUES FROM THIS FILE.**
>
> - **DIMENSION_COUNT = 8** (NOT 7)
> - **Dimension range = 0-7** (NOT 1-7)
> - **First dimension = provider-profile-metrics** (NOT connectivity-services)
> - **Total categories = 57** (NOT 51)
>
> If you output DIMENSION_COUNT=7, you are WRONG. Re-read this block.

### Eight Fixed Dimensions (0-7) by Service Domain

Each dimension maps to a distinct ICT service domain. Dimension 0 covers provider context (who they are), while Dimensions 1-7 cover service offerings (what they deliver):

### Dimension 0: Provider Profile Metrics

**Slug:** `provider-profile-metrics` | **Domain:** Organizational business KPIs and market presence

**Core Question:** *"What are the provider's key business indicators, scale, and market positioning?"*

**Focus:** Annual turnover/revenue, employee count, delivery locations, geographic presence, market rankings, certifications, partnership tiers

**MECE Role:** Covers foundational provider context (who they are) — orthogonal to service dimensions 1-7 (what they offer)

**Search Keywords:** annual revenue, employee count, workforce, headquarters, delivery centers, data center locations, market share, analyst ratings, ISO certification, partnership tier, AWS partner, Azure partner, GCP partner

**Horizon Classification:**

- **Current Offerings:** Published financials, verified employee counts, active certifications
- **Emerging Services:** Announced expansions, new geographic markets, pending certifications
- **Future Roadmap:** Strategic growth plans, M&A activity, market expansion targets

---

### Dimension 1: Connectivity Services

**Slug:** `connectivity-services` | **Domain:** Network and communication infrastructure

**Core Question:** *"What network, connectivity, and communication infrastructure services are available?"*

**Focus:** WAN/MPLS, SD-WAN, 5G private networks, IoT connectivity, global network services, voice services

**MECE Role:** Covers all network and connectivity infrastructure

**Search Keywords:** SD-WAN, MPLS, 5G private network, IoT connectivity, global WAN, network services, voice services, unified communications network, SASE, network security

**Horizon Classification:**

- **Current Offerings:** Production network services, established carrier partnerships, proven SLAs
- **Emerging Services:** 5G campus networks, edge connectivity, IoT platforms in pilot
- **Future Roadmap:** 6G preparation, satellite connectivity, quantum networking

---

### Dimension 2: Security Services

**Slug:** `security-services` | **Domain:** Cybersecurity and compliance

**Core Question:** *"What cybersecurity, identity management, and compliance services are provided?"*

**Focus:** SOC/SIEM, identity & access management, zero trust architecture, managed detection & response, compliance services

**MECE Role:** Covers all security and compliance capabilities

**Search Keywords:** SOC, SIEM, MDR, managed security, identity management, IAM, zero trust, compliance services, security assessment, penetration testing, threat intelligence, XDR

**Horizon Classification:**

- **Current Offerings:** Operational SOC, certified security services, compliance frameworks
- **Emerging Services:** AI-powered threat detection, zero trust implementations, SASE offerings
- **Future Roadmap:** Quantum-safe cryptography, autonomous security operations

---

### Dimension 3: Digital Workplace Services

**Slug:** `digital-workplace-services` | **Domain:** End-user computing and collaboration

**Core Question:** *"What workplace, collaboration, and end-user computing services are offered?"*

**Focus:** Unified communications, device management, productivity suites, virtual desktop infrastructure, collaboration platforms

**MECE Role:** Covers all end-user facing IT services

**Search Keywords:** digital workplace, unified communications, Microsoft 365 managed, device management, VDI, virtual desktop, collaboration platform, Teams services, endpoint management, DEX

**Horizon Classification:**

- **Current Offerings:** Managed workplace services, established UC platforms, proven VDI
- **Emerging Services:** AI-assisted workplace, advanced DEX, hybrid work platforms
- **Future Roadmap:** Immersive collaboration, AR/VR workplace, autonomous IT support

---

### Dimension 4: Cloud Services

**Slug:** `cloud-services` | **Domain:** Cloud computing and platform services

**Core Question:** *"What cloud-based services, platforms, and managed cloud offerings are provided?"*

**Focus:** Infrastructure-as-a-Service, Platform-as-a-Service, Software-as-a-Service, managed hyperscaler services, private and hybrid cloud solutions

**MECE Role:** Covers all cloud-based delivery models and platform services

**Search Keywords:** IaaS, PaaS, SaaS, managed cloud, hyperscaler, AWS managed services, Azure services, GCP partner, private cloud, hybrid cloud, cloud migration, cloud native, containerization, Kubernetes managed

**Horizon Classification:**

- **Current Offerings:** GA cloud services, established hyperscaler partnerships, documented SLAs
- **Emerging Services:** New cloud-native offerings, beta managed services, pilot programs
- **Future Roadmap:** Announced cloud capabilities, sovereign cloud initiatives, quantum-ready services

---

### Dimension 5: Managed Infrastructure Services

**Slug:** `managed-infrastructure-services` | **Domain:** IT operations and infrastructure management

**Core Question:** *"What data center, hosting, and IT operations services are provided?"*

**Focus:** Data center services, hosting, IT operations, backup & recovery, infrastructure monitoring

**MECE Role:** Covers all infrastructure operations and management

**Search Keywords:** managed infrastructure, data center services, hosting, IT operations, backup recovery, disaster recovery, infrastructure monitoring, AIOps, ITIL services, colocation

**Horizon Classification:**

- **Current Offerings:** Production data centers, established hosting, proven DR capabilities
- **Emerging Services:** AIOps-driven operations, sustainable data centers, edge infrastructure
- **Future Roadmap:** Autonomous infrastructure, carbon-neutral operations, distributed computing

---

### Dimension 6: Application Services

**Slug:** `application-services` | **Domain:** Software development and integration

**Core Question:** *"What application development, modernization, and integration services are available?"*

**Focus:** Custom development, application modernization, system integration, API management, low-code/no-code platforms

**MECE Role:** Covers all application lifecycle services

**Search Keywords:** custom development, application modernization, system integration, API management, low-code, no-code, DevOps, agile development, cloud-native development, SAP services, Salesforce integration

**Horizon Classification:**

- **Current Offerings:** Established development practices, proven integration capabilities, certified partnerships
- **Emerging Services:** AI-assisted development, composable architectures, platform engineering
- **Future Roadmap:** Autonomous coding, intent-based development, quantum algorithms

---

### Dimension 7: Consulting Services

**Slug:** `consulting-services` | **Domain:** Advisory and transformation services

**Core Question:** *"What strategic, transformation, and implementation consulting capabilities are offered?"*

**Focus:** Strategy consulting, digital transformation, change management, implementation services, program management

**MECE Role:** Covers advisory and transformation guidance (distinct from technical delivery)

**Search Keywords:** digital transformation consulting, IT strategy, change management, implementation partner, program management, advisory services, business consulting, technology roadmap, maturity assessment

**Horizon Classification:**

- **Current Offerings:** Established consulting practices, certified methodologies, proven frameworks
- **Emerging Services:** New advisory domains, AI/ML consulting, sustainability consulting
- **Future Roadmap:** Future-of-work advisory, emerging technology consulting

---

### MANDATORY: Thinking Block Template

You MUST fill out this thinking block with actual analysis:

<thinking>
**Step 1 Execution: Apply Dimensions with Service Domain Mapping**

Analyzing the 8 fixed dimensions (0-7):

0. Dimension: provider-profile-metrics
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key metrics expected: [FILL IN]

1. Dimension: connectivity-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

2. Dimension: security-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

3. Dimension: digital-workplace-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

4. Dimension: cloud-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

5. Dimension: managed-infrastructure-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

6. Dimension: application-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

7. Dimension: consulting-services
   - Domain focus: [FILL IN]
   - Core question essence: [FILL IN]
   - Key solution types expected: [FILL IN]

Verification:
- Total dimensions: [COUNT]
- Dimension 0 (provider profile) distinct from 1-7 (services): [YES/NO]
- All 8 domains distinct: [YES/NO]
- MECE coverage validated: [YES/NO]
</thinking>

### Variable Assignment

```bash
# Phase start logging
log_phase "Phase 2: Analysis (b2b-ict-portfolio)" "start"
log_conditional INFO "[b2b-ict-portfolio] Applying solution-focused dimension definitions"

# Fixed dimension structure (8 dimensions: 0-7)
DIMENSION_COUNT=8
DIMENSION_SLUGS="provider-profile-metrics connectivity-services security-services digital-workplace-services cloud-services managed-infrastructure-services application-services consulting-services"

# Service domain mapping (dimension:domain)
DIMENSION_DOMAIN_MAP=(
  "provider-profile-metrics:provider-context"
  "connectivity-services:network"
  "security-services:cybersecurity"
  "digital-workplace-services:end-user"
  "cloud-services:cloud-computing"
  "managed-infrastructure-services:operations"
  "application-services:development"
  "consulting-services:advisory"
)

# Store dimension metadata
DIMENSION_SPECS=(
  "provider-profile-metrics:Provider Profile Metrics:provider-context"
  "connectivity-services:Connectivity Services:network"
  "security-services:Security Services:cybersecurity"
  "digital-workplace-services:Digital Workplace Services:end-user"
  "cloud-services:Cloud Services:cloud-computing"
  "managed-infrastructure-services:Managed Infrastructure Services:operations"
  "application-services:Application Services:development"
  "consulting-services:Consulting Services:advisory"
)

log_conditional INFO "[b2b-ict-portfolio] DIMENSION_COUNT=8 (fixed, embedded, 0-7)"
log_conditional INFO "[b2b-ict-portfolio] Domains: provider-context, network, security, end-user, cloud, operations, development, advisory"
```

Update TodoWrite: Mark Step 1 completed, mark Step 1.5 as in_progress.

---

## Step 1.5: Apply Dimension Selection Filter

### Dimension Selection Processing

If the user selected specific dimensions during Phase 0 (Step 0.4.5), apply the selection filter to reduce scope.

**Input Source:** `selected_dimensions` from sprint-log.json or question frontmatter

### Thinking Block Template

<thinking>
**Step 1.5 Execution: Apply Dimension Selection Filter**

1. Check for dimension selection:
   - selected_dimensions present in sprint-log.json: [YES/NO]
   - selected_dimensions value: [LIST OR "all"]

2. If selection exists and != ["all"]:
   - ACTIVE_DIMENSIONS: [LIST SLUGS]
   - ACTIVE_DIMENSION_COUNT: [COUNT]
   - FILTERED_CATEGORIES: [COUNT of 57 that apply]
   - EXCLUDED_DIMENSIONS: [LIST SLUGS]

3. If selection is "all" or not present:
   - Use all 8 dimensions (0-7)
   - All 57 categories active

4. Category count by active dimension:
   | Dimension | Category Count |
   |-----------|---------------|
   | provider-profile-metrics | 6 |
   | connectivity-services | 7 |
   | security-services | 10 |
   | digital-workplace-services | 7 |
   | cloud-services | 8 |
   | managed-infrastructure-services | 7 |
   | application-services | 7 |
   | consulting-services | 5 |

Verification:
- Dimension selection applied: [YES/NO/NOT_APPLICABLE]
- Active dimensions valid: [YES/NO]
- Category count matches selection: [YES/NO]
</thinking>

### Category Counts by Dimension

| Dimension | Categories | IDs |
|-----------|------------|-----|
| provider-profile-metrics | 6 | 0.1-0.6 |
| connectivity-services | 7 | 1.1-1.7 |
| security-services | 10 | 2.1-2.10 |
| digital-workplace-services | 7 | 3.1-3.7 |
| cloud-services | 8 | 4.1-4.8 |
| managed-infrastructure-services | 7 | 5.1-5.7 |
| application-services | 7 | 6.1-6.7 |
| consulting-services | 5 | 7.1-7.5 |
| **Total** | **57** | |

### Variable Assignment

```bash
# Read dimension selection from sprint-log.json
SELECTED_DIMS_JSON=$(jq -r '.selected_dimensions // "null"' "${PROJECT_PATH}/.metadata/sprint-log.json" 2>/dev/null)

if [ "$SELECTED_DIMS_JSON" == "null" || "$SELECTED_DIMS_JSON" == '["provider-profile-metrics","connectivity-services","security-services","digital-workplace-services","cloud-services","managed-infrastructure-services","application-services","consulting-services"]' ]; then
  # All dimensions selected or no selection made
  ACTIVE_DIMENSIONS="$DIMENSION_SLUGS"
  ACTIVE_DIMENSION_COUNT=8
  DIMENSION_SELECTION_MODE="all"
  ACTIVE_CATEGORY_COUNT=57
  log_conditional INFO "[b2b-ict-portfolio] Dimension selection: ALL (8 dimensions, 57 categories)"
else
  # Parse selected dimensions
  ACTIVE_DIMENSIONS=$(echo "$SELECTED_DIMS_JSON" | jq -r '.[]' | tr '\n' ' ')
  ACTIVE_DIMENSION_COUNT=$(echo "$SELECTED_DIMS_JSON" | jq -r '. | length')
  DIMENSION_SELECTION_MODE="filtered"

  # Calculate active category count (Bash 3.2 compatible - use case statement)
  get_category_count() {
    case "$1" in
      "provider-profile-metrics") echo 6 ;;
      "connectivity-services") echo 7 ;;
      "security-services") echo 10 ;;
      "digital-workplace-services") echo 7 ;;
      "cloud-services") echo 8 ;;
      "managed-infrastructure-services") echo 7 ;;
      "application-services") echo 7 ;;
      "consulting-services") echo 5 ;;
      *) echo 0 ;;
    esac
  }

  ACTIVE_CATEGORY_COUNT=0
  for dim in $ACTIVE_DIMENSIONS; do
    count=$(get_category_count "$dim")
    ACTIVE_CATEGORY_COUNT=$((ACTIVE_CATEGORY_COUNT + count))
  done

  log_conditional INFO "[b2b-ict-portfolio] Dimension selection: FILTERED"
  log_conditional INFO "[b2b-ict-portfolio] Active dimensions: $ACTIVE_DIMENSION_COUNT of 8"
  log_conditional INFO "[b2b-ict-portfolio] Active categories: $ACTIVE_CATEGORY_COUNT of 57"
  log_conditional INFO "[b2b-ict-portfolio] Selected: $ACTIVE_DIMENSIONS"
fi

# Update dimension variables for downstream phases
DIMENSION_COUNT=$ACTIVE_DIMENSION_COUNT
DIMENSION_SLUGS="$ACTIVE_DIMENSIONS"
```

### Filtered Dimension Specs

```bash
cat > /tmp/dp-p2-filter-dims.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Filter DIMENSION_SPECS and DIMENSION_DOMAIN_MAP to active dimensions only
FILTERED_DIMENSION_SPECS=()
FILTERED_DOMAIN_MAP=()

for spec in "${DIMENSION_SPECS[@]}"; do
  slug=$(echo "$spec" | cut -d: -f1)
  if [[ " $ACTIVE_DIMENSIONS " =~ " $slug " ]]; then
    FILTERED_DIMENSION_SPECS+=("$spec")
  fi
done

for mapping in "${DIMENSION_DOMAIN_MAP[@]}"; do
  slug=$(echo "$mapping" | cut -d: -f1)
  if [[ " $ACTIVE_DIMENSIONS " =~ " $slug " ]]; then
    FILTERED_DOMAIN_MAP+=("$mapping")
  fi
done

DIMENSION_SPECS=("${FILTERED_DIMENSION_SPECS[@]}")
DIMENSION_DOMAIN_MAP=("${FILTERED_DOMAIN_MAP[@]}")

log_conditional INFO "[b2b-ict-portfolio] Dimension specs filtered: ${#DIMENSION_SPECS[@]} active"
SCRIPT_EOF
chmod +x /tmp/dp-p2-filter-dims.sh && bash /tmp/dp-p2-filter-dims.sh
```

Update TodoWrite: Mark Step 1.5 completed, mark Step 2 as in_progress.

---

## Step 2: Define Evidence Requirements per Dimension

### Solution Attribute Evidence Standards

Each dimension requires specific evidence types for solution discovery:

| Dimension | Primary Evidence | Secondary Evidence | Example |
|-----------|-----------------|-------------------|---------|
| **Provider Profile Metrics** | Annual reports, company filings, press releases | Analyst reports, industry rankings | "€5.2B revenue, 15,000 employees, ISO 27001 certified" |
| **Cloud Services** | Service catalogs, pricing tiers, SLAs | Partner certifications, case studies | "AWS Advanced Partner, 99.9% SLA, pay-per-use" |
| **Consulting Services** | Practice descriptions, methodologies, certifications | Client references, thought leadership | "SAP S/4HANA certified, 50+ implementations" |
| **Connectivity Services** | Network coverage, bandwidth specs, latency SLAs | PoP locations, carrier partnerships | "Global MPLS, 200+ PoPs, <50ms latency" |
| **Security Services** | SOC certifications, compliance frameworks, response times | Threat intel sources, analyst coverage | "ISO 27001, 24/7 SOC, 15-min response SLA" |
| **Digital Workplace** | Supported platforms, user counts, DEX metrics | Endpoint types, integration depth | "Microsoft 365 managed, 100K+ seats, 98% satisfaction" |
| **Application Services** | Development frameworks, integration patterns, delivery models | Technology stack, team certifications | "Cloud-native, SAP BTP certified, agile delivery" |
| **Managed Infrastructure** | Data center tiers, uptime SLAs, capacity | Green certifications, geographic coverage | "Tier IV, 99.999% uptime, carbon-neutral" |

### MANDATORY: Thinking Block Template

You MUST fill out this thinking block with actual analysis:

<thinking>
**Step 2 Execution: Define Evidence Requirements**

For each dimension, analyzing solution attribute evidence needs:

0. provider-profile-metrics:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

1. connectivity-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

2. security-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

3. digital-workplace-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

4. cloud-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

5. managed-infrastructure-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

6. application-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

7. consulting-services:
   - Primary evidence needed: [SPECIFY]
   - Example attribute to extract: [PROVIDE EXAMPLE]
   - Why this evidence: [EXPLAIN]

Verification:
- All 8 dimensions have evidence standards: [YES/NO]
- Evidence types support Portfolio Entity Schema: [YES/NO]
- Examples are concrete and measurable: [YES/NO]
</thinking>

### Variable Assignment

```bash
# Evidence requirements set
EVIDENCE_REQUIREMENTS_SET=true
SOLUTION_EVIDENCE_MATRIX=(
  "provider-profile-metrics:annual_revenue,employee_count,locations,certifications,partnerships"
  "connectivity-services:network_coverage,bandwidth,latency,PoPs"
  "security-services:SOC_certs,compliance,response_times,coverage"
  "digital-workplace-services:platforms,user_counts,DEX_metrics,integrations"
  "cloud-services:service_catalogs,pricing_tiers,SLAs,certifications"
  "managed-infrastructure-services:tiers,uptime,capacity,certifications"
  "application-services:frameworks,patterns,delivery_models,stack"
  "consulting-services:practice_descriptions,methodologies,certifications,references"
)

log_conditional INFO "[b2b-ict-portfolio] Evidence requirements defined for all 8 dimensions"
```

Update TodoWrite: Mark Step 2 completed, mark Step 3 as in_progress.

---

## Step 3: Detect Service Maturity with Horizon Classification

### Maturity Signal Detection

<thinking>
Analyze the original research question for service maturity indicators.
For each detected indicator:
1. CLASSIFY horizon (Current/Emerging/Future)
2. IDENTIFY provider scope (single provider vs. market-wide)
3. FLAG cross-cutting attributes mentioned
</thinking>

### Maturity Language Detection

| Maturity | Indicator Terms | Horizon |
|----------|----------------|---------|
| **Production** | "current", "available", "deployed", "GA", "production" | Current Offerings |
| **Pilot** | "emerging", "beta", "pilot", "preview", "early access" | Emerging Services |
| **Planned** | "roadmap", "announced", "future", "planned", "upcoming" | Future Roadmap |
| **Mixed** | "portfolio", "complete", "all offerings" | All horizons |

### Provider Scope Detection

| Scope | Indicators | Search Approach |
|-------|-----------|-----------------|
| **Single Provider** | Company name, "our", specific brand | Provider-specific search |
| **Market Segment** | "enterprise", "mid-market", "SMB" | Segment-filtered search |
| **Market-Wide** | "market", "landscape", "competitors" | Comparative search |

### Variable Assignment

```bash
# Maturity detection
ORGANIZING_CONCEPT=$(extract_organizing_concept "$QUESTION_TEXT")
SERVICE_MATURITY=$(detect_maturity_language "$QUESTION_TEXT")  # production | pilot | planned | mixed
PRIMARY_HORIZON=$(map_maturity_to_horizon "$SERVICE_MATURITY")
PROVIDER_SCOPE=$(detect_provider_scope "$QUESTION_TEXT")  # single | segment | market

log_conditional INFO "[b2b-ict-portfolio] Organizing concept: ${ORGANIZING_CONCEPT}"
log_conditional INFO "[b2b-ict-portfolio] Service maturity: ${SERVICE_MATURITY} → ${PRIMARY_HORIZON}"
log_conditional INFO "[b2b-ict-portfolio] Provider scope: ${PROVIDER_SCOPE}"
```

Update TodoWrite: Mark Step 3 completed, mark Step 4 as in_progress.

---

## Step 4: Map Cross-Cutting Attributes

### Cross-Cutting Attribute Analysis

<thinking>
Analyze question for cross-cutting attribute requirements.
Map each attribute to analysis dimensions.
</thinking>

| Attribute | Values | Analysis Dimension |
|-----------|--------|-------------------|
| **Industry Verticals** | Healthcare, Automotive, Public Sector, Financial Services, Retail, Manufacturing, Energy, Telecommunications, Media | Filter/group solutions |
| **Delivery Locations** | Domestic, European, Nearshore, Offshore, Global | Geographic coverage |
| **Partner Ecosystem** | Hyperscalers (AWS, Azure, GCP), Enterprise Software (SAP, ServiceNow, Salesforce), Technology Vendors | Partnership depth |

### Detection Patterns

| Attribute | Detection Triggers |
|-----------|-------------------|
| Industry Verticals | Industry names, "sector", "vertical", regulatory terms |
| Delivery Locations | Geographic terms, "nearshore", "offshore", "global" |
| Partner Ecosystem | Vendor names, "partnership", "certified", "integration" |

### Variable Assignment

```bash
# Cross-cutting attribute requirements
CROSS_CUTTING_ATTRIBUTES=(
  "industry_verticals:$(detect_verticals "$QUESTION_TEXT")"
  "delivery_locations:$(detect_locations "$QUESTION_TEXT")"
  "partner_ecosystem:$(detect_partners "$QUESTION_TEXT")"
)

# Flag for Phase 3 cross-cutting integration
CROSS_CUTTING_ANALYSIS_ENABLED=true

log_conditional INFO "[b2b-ict-portfolio] Cross-cutting attributes detected"
log_conditional INFO "[b2b-ict-portfolio] Analysis dimensions: verticals, locations, partners"
```

Update TodoWrite: Mark Step 4 completed, mark Step 5 as in_progress.

---

## Step 5: Prepare Portfolio Entity Schema

### Portfolio Entity Schema (for Phase 5 entity creation)

Each discovered solution will be captured with:

```yaml
entity_type: "portfolio-entity"
portfolio_entity:
  name: "{Solution Name}"
  description: "{What the solution does}"
  usp: "{Unique selling proposition}"
  provider_unit: "{Business unit}"
  pricing_model: "{subscription|usage-based|project-based|hybrid}"
  delivery_model: "{onshore|nearshore|offshore|hybrid|global}"
  technology_partners: ["{Partner 1}", "{Partner 2}"]
  industry_verticals: ["{Vertical 1}", "{Vertical 2}"]
  service_horizon: "{current|emerging|future}"
dimension: "{dimension-slug}"
```

### Variable Assignment

```bash
# Portfolio entity schema prepared
SOLUTION_SCHEMA_READY=true
SOLUTION_ATTRIBUTES="name,description,usp,provider_unit,pricing_model,delivery_model,technology_partners,industry_verticals,service_horizon"

log_conditional INFO "[b2b-ict-portfolio] Portfolio entity schema prepared for Phase 5"
```

Update TodoWrite: Mark Step 5 completed, mark Step 6 as in_progress.

---

## Step 6: Validate Completeness

### Validation Checks

1. **Dimension count valid:** Must be exactly 8 (0-7)

   ```bash
   if [ "$DIMENSION_COUNT" -ne 8 ]; then
     return_error "B2B ICT Portfolio must have exactly 8 dimensions (found: $DIMENSION_COUNT)"
   fi
   ```

2. **Service domain mapping complete:** All 8 dimensions mapped

   ```bash
   if [ "${#DIMENSION_DOMAIN_MAP[@]}" -ne 8 ]; then
     return_error "Service domain mapping incomplete"
   fi
   ```

3. **Evidence requirements set:**

   ```bash
   if [ "$EVIDENCE_REQUIREMENTS_SET" != "true" ]; then
     return_error "Evidence requirements not defined"
   fi
   ```

4. **All required variables set:**

   ```bash
   for var in DIMENSION_COUNT DIMENSION_SLUGS SERVICE_MATURITY PROVIDER_SCOPE CROSS_CUTTING_ANALYSIS_ENABLED SOLUTION_SCHEMA_READY; do
     if [ -z "${!var}" ]; then
       return_error "Required variable not set: $var"
     fi
   done
   ```

Update TodoWrite: Mark Step 6 completed, mark Step 7 as in_progress.

---

## Step 7: Mark Phase 2 Complete

### Success Criteria (B2B ICT Portfolio Solution-Focused)

- [ ] DIMENSION_COUNT = 8 (from embedded definitions, 0-7)
- [ ] All 8 dimension slugs set (unique, no duplicates)
- [ ] Service domain mapping complete (each dimension → service domain)
- [ ] Evidence requirements defined per dimension
- [ ] Core questions available for all 8 dimensions (embedded)
- [ ] Search keywords available for all 8 dimensions (embedded)
- [ ] Horizon classification available for all 8 dimensions (embedded)
- [ ] Service maturity detected with horizon classification
- [ ] Cross-cutting attributes detected and mapped
- [ ] Portfolio entity schema prepared
- [ ] All variables logged

### Logging

```bash
log_conditional INFO "[b2b-ict-portfolio] Phase 2 Complete: Solution-Focused Analysis"
log_conditional INFO "[b2b-ict-portfolio] 8 dimensions (0-7) with service domain mapping"
log_conditional INFO "[b2b-ict-portfolio] Evidence requirements: solution attributes per dimension"
log_conditional INFO "[b2b-ict-portfolio] Service horizons: Current (0-1y), Emerging (1-3y), Future (3+y)"
log_conditional INFO "[b2b-ict-portfolio] Maturity: ${SERVICE_MATURITY} → ${PRIMARY_HORIZON}"
log_conditional INFO "[b2b-ict-portfolio] Cross-cutting analysis: ENABLED"
log_conditional INFO "[b2b-ict-portfolio] Solution schema: READY"
log_phase "Phase 2: Analysis (b2b-ict-portfolio)" "complete"
```

---

## Final Verification Gate

Before marking Phase 2 complete, verify execution evidence:

### Execution Evidence Checklist

1. **Thinking blocks:** Did you fill out both thinking blocks (Steps 1-2) with all placeholders replaced? YES / NO
2. **TodoWrite calls:** Did you call TodoWrite 7 times (Step 0.5 + Steps 1-6)? YES / NO
3. **Variable assignments:** Are all code blocks present with variables set? YES / NO
4. **Dimension mapping:** All 8 dimensions (0-7) mapped to service domains? YES / NO
5. **Evidence requirements:** Solution attribute standards defined for all 8 dimensions? YES / NO
6. **Maturity detection:** Service maturity and horizon classified? YES / NO
7. **Cross-cutting mapping:** Attributes detected and analysis enabled? YES / NO
8. **Schema preparation:** Portfolio entity schema ready for Phase 5? YES / NO

**IF ANY NO:** STOP. Return to incomplete step. Provide execution evidence.

**IF ALL YES:** Mark Phase 2 todo as completed in TodoWrite. Proceed to Phase 3.

---

## Next Phase

Proceed to [phase-3-planning-b2b-ict-portfolio.md](phase-3-planning-b2b-ict-portfolio.md) when all criteria met.

**Next step:** Phase 3 - Solution Discovery PICOT Generation with Cross-Cutting Attributes

Phase 3 will use:

- DIMENSION_DOMAIN_MAP for focused question generation
- SOLUTION_EVIDENCE_MATRIX for attribute-specific search queries
- CROSS_CUTTING_ATTRIBUTES for vertical/location/partner filtering
- PROVIDER_SCOPE for search breadth calibration

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Dimension count ≠ 8 | Exit 1, embedded definitions corrupted |
| Service domain mapping incomplete | Exit 1, regenerate from template |
| Variable not set | Exit 1, log missing variable |
| Maturity detection failed | Log warning, default to "mixed" with all horizons |
| Cross-cutting detection failed | Log warning, default to all attributes enabled |
| Schema preparation failed | Exit 1, critical for Phase 5 |

---

**Size:** ~10KB | Self-contained (no runtime file loading) | Solution-Focused | 8 Dimensions (0-7)
