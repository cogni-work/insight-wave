# Research Types Catalog

Plugin-level research type definitions for deeper-research workflows. Research types provide pre-validated dimension frameworks aligned with established business methodologies.

---

## Architecture: WHAT vs HOW Separation

This directory contains **WHAT** definitions only — pure framework structures without operational guidance.

| Layer | Location | Content |
|-------|----------|---------|
| **WHAT** (Master) | `research-types/*.md` | Definitions, structures, MECE validation |
| **HOW** (Skills) | `skills/*/references/phase-workflows/` | Operational guidance, PICOT patterns, synthesis workflows |

**Design Documents:**

- [DESIGN-PRINCIPLES.md](DESIGN-PRINCIPLES.md) — WHAT/HOW separation guidelines
- [PROPAGATION-PROTOCOL.md](PROPAGATION-PROTOCOL.md) — Change management workflow

---

## Directory Structure

```text
research-types/
├── README.md                    # This file
├── DESIGN-PRINCIPLES.md         # Architecture guidelines
├── PROPAGATION-PROTOCOL.md      # Change management
├── tips-framework.md            # WHAT: TIPS structure (T→I→P→S)
├── smarter-service.md           # WHAT: 4 dimensions + action horizons
├── lean-canvas.md               # WHAT: 9 canvas blocks
├── b2b-ict-portfolio.md         # WHAT: 8 dimensions (0-7) + service horizons
├── customer-value-mapping.md    # WHAT: 4 Value Story dimensions
└── archived/                    # Old subdirectory structure
    ├── smarter-service/
    └── lean-canvas/
```

---

## Available Research Types

### tips-framework

**Purpose:** Shared synthesis structure for trend-based research

**Structure:** 4 progressive components

| Component | Question |
|-----------|----------|
| **T**rend | "What is happening?" |
| **I**mplications | "What does it mean?" |
| **P**ossibilities | "What could we do?" |
| **S**olutions | "What should we do?" |

**Used by:** `smarter-service` (trend entity format)

**Reference:** [tips-framework.md](tips-framework.md)

---

### smarter-service

**Framework:** Trendbook Kompass für die Multikrise (2023)

**Structure:** 4 dimensions (MECE pre-validated)

| Dimension | German | Focus |
|-----------|--------|-------|
| External Effects | Externe Effekte | External forces acting ON organization |
| New Horizons | Neue Horizonte | Strategic responses BY organization |
| Digital Value Drivers | Digitale Wertetreiber | Value creation THROUGH digital means |
| Digital Foundation | Digitales Fundament | Capabilities SUPPORTING transformation |

**Action Horizons:** Act (0-2y), Plan (2-5y), Observe (5+y)

**Trend Format:** Uses TIPS structure (see [tips-framework.md](tips-framework.md))

**Reference:** [smarter-service.md](smarter-service.md)

---

### lean-canvas

**Framework:** Ash Maurya's Lean Canvas

**Structure:** 9 blocks (MECE pre-validated)

| Block | Focus |
|-------|-------|
| Problem | Top customer pain points |
| Customer Segments | Target markets, early adopters |
| Unique Value Proposition | Compelling differentiation |
| Solution | Top features addressing problems |
| Channels | Paths to customers |
| Revenue Streams | Monetization approach |
| Cost Structure | Fixed and variable costs |
| Key Metrics | Success indicators |
| Unfair Advantage | Sustainable competitive moats |

**Output:** Generic synthesis (no TIPS dependency)

**Reference:** [lean-canvas.md](lean-canvas.md)

---

### b2b-ict-portfolio

**Framework:** B2B ICT Portfolio Analysis

**Purpose:** Systematic discovery of enterprise ICT service provider offerings across service domains

**Structure:** 8 dimensions (0-7, MECE pre-validated)

| Dimension | Domain | Focus |
|-----------|--------|-------|
| Provider Profile Metrics | Business Context | Revenue, employees, locations, certifications, market presence |
| Cloud Services | Cloud computing | IaaS, PaaS, SaaS, managed hyperscaler services |
| Consulting Services | Advisory | Strategy, transformation, implementation consulting |
| Connectivity Services | Network | WAN, SD-WAN, 5G, IoT connectivity |
| Security Services | Cybersecurity | SOC/SIEM, IAM, zero trust, compliance |
| Digital Workplace Services | End-user | UC, device management, VDI, collaboration |
| Application Services | Development | Custom dev, modernization, integration, API |
| Managed Infrastructure Services | Operations | Data center, hosting, IT ops, DR |

**Service Horizons:** Current Offerings (0-1y), Emerging Services (1-3y), Future Roadmap (3+y)

**Entity Type:** Portfolio Entity (with 9-attribute schema: Name, Description, USP, Provider Unit, Pricing Model, Delivery Model, Technology Partners, Industry Verticals, Service Horizon)

**Cross-Cutting Attributes:** Industry Verticals, Delivery Locations, Partner Ecosystem

**Output:** Hybrid portfolio catalog + strategic analysis (variable solution count per dimension)

**Reference:** [b2b-ict-portfolio.md](b2b-ict-portfolio.md)

---

### customer-value-mapping

**Framework:** Corporate Visions Value Story Methodology

**Purpose:** Customer contextualization layer that synthesizes existing TIPS research and portfolio offerings into customer-specific value propositions for sales enablement

**Structure:** 4 dimensions (MECE pre-validated)

| Dimension | Value Story Stage | Focus |
|-----------|-------------------|-------|
| Why Change | Disrupt Status Quo | Unconsidered needs, hidden risks, industry forces |
| Why Now | Create Urgency | Cost of inaction, deadlines, competitive windows |
| Why You | Differentiate | Capability gaps, unique approaches, proof points |
| Why Pay | Justify Economics | ROI, TCO, value metrics |

**Source Integration:** Loads from existing smarter-service TIPS (with `portfolio_refs[]`) and b2b-ict-portfolio entities, plus customer-specific web research

**Entity Type:** Customer Need Mapping (with COT reasoning chain: Need → TIPS → Portfolio)

**Output:** Feeds `value-story-creator` skill for 13-17 slide PPTX generation

**Reference:** [customer-value-mapping.md](customer-value-mapping.md)

---

### generic

**Framework:** None (flexible, domain-based)

**Structure:** Variable (2-10 dimensions generated from question)

**Template Files:** None (dimensions generated dynamically using Webb's DOK)

**Usage:** Default when `research_type` omitted or set to `generic`

**Reference:** [generic.md](generic.md)

---

## Skill Integration

### Which skills use which files?

| Skill | Phase | File Used |
|-------|-------|-----------|
| `dimension-planner` | Phase 2 | `{research-type}.md` (WHAT) + skill phase files (HOW) |
| `trends-creator` | Phase 4 | `tips-framework.md` (WHAT) + skill phase files (HOW) |
| `synthesis-hub` | Phase 4 | `{research-type}.md` (WHAT) + skill phase files (HOW) |
| `executive-synthesizer` | Phase 4 | `smarter-service.md` (WHAT) + skill phase files (HOW) |

### Path Convention

From skills directory, reference using relative paths:

```markdown
[../../references/research-types/smarter-service.md](../../references/research-types/smarter-service.md)
```

---

## Adding New Research Types

### Step 1: Create WHAT Definition

Create `research-types/{type-name}.md` with:

- Framework source and purpose
- Dimension/block definitions
- MECE validation
- Cross-references to shared frameworks (if applicable)

### Step 2: Update This README

Add entry to "Available Research Types" section.

### Step 3: Create Skill HOW Files

For each consuming skill, create phase-specific files in:

```
skills/{skill-name}/references/phase-workflows/
├── phase-2-analysis-{type-name}.md
├── phase-3-planning-{type-name}.md
└── phase-4a-synthesis-hub-cross.md (arc-specific: delegated to cogni-narrative:narrative-writer)
```

### Step 4: Test Integration

- Verify dimension-planner loads new type correctly
- Verify synthesis skills process new type correctly
- Validate output quality

---

## Maintenance

### Updating WHAT Definitions

1. Edit the master WHAT file
2. Follow [PROPAGATION-PROTOCOL.md](PROPAGATION-PROTOCOL.md)
3. Update affected skill HOW files
4. Update version markers

### Deprecation

1. Add deprecation notice to WHAT file
2. Update this README
3. Set sunset date (minimum 3 months)
4. Archive after sunset (don't delete immediately)

---

## Related References

**Plugin-Level:**

- [../templates/README.md](../templates/README.md) — Synthesis report templates
- [../anti-hallucination-foundations.md](../anti-hallucination-foundations.md) — Evidence-based processing
- [../entity-structure-guide.md](../entity-structure-guide.md) — Entity frontmatter patterns

---

## Version History

- **v2.2 (Sprint 440):** Added customer-value-mapping research type with 4 Value Story dimensions for sales enablement
- **v2.1 (Sprint 439):** Added b2b-ict-portfolio research type with 8 dimensions (0-7), service horizons, portfolio entity schema
- **v2.0 (Sprint 438):** Refactored to WHAT-only definitions, flat structure
- **v1.1 (Sprint 277):** Split templates into dimensions + synthesis
- **v1.0:** Initial research-types catalog
