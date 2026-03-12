# Smarter Service Framework Definition

## Purpose

The Smarter Service framework provides a 4-layer concentric structure for digital transformation research, with dual time horizons for strategic planning.

**Framework Source:** Trendbook Kompass für die Multikrise (2023), Page 14 - Trendradar

---

## Dimension Definitions

The framework uses exactly 4 dimensions organized as concentric layers (outer to inner):

### 1. Externe Effekte (External Effects)

**Layer:** Outer ring — External environment analysis

**Core Question:** *"Welche externen Kräfte wirken von außen auf das Unternehmen ein?"*
*(What external forces are impacting the organization from outside?)*

**Focus:** Forces beyond the organization's control — economic disruptions, regulatory shifts, societal changes

**MECE Role:** External forces acting ON the organization (outside-in perspective)

---

### 2. Neue Horizonte (New Horizons)

**Layer:** Strategic business model layer

**Core Question:** *"Wofür wird das Unternehmen in Zukunft bezahlt?"*
*(What will the company be paid for in the future?)*

**Focus:** Strategic reinvention — business model evolution, leadership approaches, governance structures

**MECE Role:** Strategic responses BY the organization (direction-setting)

---

### 3. Digitale Wertetreiber (Digital Value Drivers)

**Layer:** Value creation and delivery layer

**Core Question:** *"Wo und wie schaffen wir mit digitalen Mitteln Wert für Kunden und Geschäft?"*
*(Where and how do we create value for customers and business through digital means?)*

**Focus:** Value creation mechanisms — customer experience, products/services, business processes

**MECE Role:** Value creation THROUGH digital means (delivery mechanisms)

---

### 4. Digitales Fundament (Digital Foundation)

**Layer:** Foundational capabilities and enablers (inner ring)

**Core Question:** *"Welche digitalen Kompetenzen müssen vorhanden sein, um die digitale Realität der nächsten zehn Jahre zu bewältigen?"*
*(What digital competencies must exist to master the digital reality of the next ten years?)*

**Focus:** Enabling capabilities — culture, workforce, technology infrastructure

**MECE Role:** Capabilities SUPPORTING transformation (enablers)

---

## MECE Validation

The four dimensions are pre-validated for MECE compliance:

**Mutually Exclusive:**

- Each dimension covers a distinct aspect (forces, strategy, value, foundation)
- No overlap between external environment, strategic response, value delivery, and capabilities

**Collectively Exhaustive:**

- External environment analysis (Externe Effekte)
- Strategic planning and governance (Neue Horizonte)
- Value creation and delivery (Digitale Wertetreiber)
- Organizational capabilities and infrastructure (Digitales Fundament)

---

## Action Horizons

Each trend is positioned by implementation urgency:

| Horizon | Timeframe | Action Type |
|---------|-----------|-------------|
| **Act** | 0-2 years | Immediate implementation — validated readiness |
| **Plan** | 2-5 years | Strategic preparation — capability building required |
| **Observe** | 5+ years | Monitor and assess — emerging trends |

**Research Deliverable:** 60 TIPS total — (5 ACT + 5 PLAN + 5 OBSERVE) × 4 dimensions

---

## Chance/Risk Framework by Horizon

The **ACT horizon** (0-2 years) requires explicit Chance/Risk framing to drive immediate decision-making. This addresses both the opportunity cost of inaction and the value capture from action.

| Horizon | Chance/Risk Intensity | Quantification Level |
|---------|----------------------|---------------------|
| **Act** | **High** — Required, urgent | Specific metrics ($, %, timeframes) |
| **Plan** | **Moderate** — Recommended | Directional projections, ranges |
| **Observe** | **Low** — Optional | Qualitative, scenario-based |

**ACT Horizon Chance/Risk Examples:**

```yaml
possibility:
  overview: "AI-driven predictive maintenance becoming table stakes in manufacturing"
  chance: "First-mover advantage: 15-20% OEE improvement achievable within 12 months; early adopters securing preferred vendor relationships"
  risk: "Delayed adoption widens competitive gap by $2M annually in operational inefficiency; talent pool shrinking as skilled workers move to digitally mature competitors"
```

**PLAN Horizon Example (Recommended):**

```yaml
possibility:
  overview: "Quantum computing entering practical application phase for optimization problems"
  chance: "Strategic positioning in quantum-ready algorithms could yield 30-50% improvement in complex logistics optimization by 2027"
  risk: "Organizations without quantum readiness roadmap risk 2-3 year capability gap when commercial quantum becomes viable"
```

**OBSERVE Horizon Example (Optional):**

```yaml
possibility:
  overview: "Brain-computer interfaces advancing toward enterprise applications"
  # chance and risk optional for OBSERVE — emerging trends with high uncertainty
```

---

## Trend Entity Format

Trends in the Smarter Service framework use the **TIPS structure** for content organization.

**Reference:** [tips-framework.md](tips-framework.md)

**Important:** Each of the 4 dimensions is used to *scout* and identify trends. Once a trend is identified in any dimension, it is then analyzed through the complete TIPS framework (Trend → Implications → Possibilities → Solutions). Dimensions do not map 1:1 to TIPS components — rather, each dimension contains multiple trends that each receive full TIPS expansion.

Each trend entity contains:

- **Dimension:** Which of the 4 layers the trend was discovered in (segment)
- **Action Horizon:** Act, Plan, or Observe (arc position)
- **TIPS Content:** Full expansion — Trend → Implications → Possibilities → Solutions

---

## Cross-Dimensional Linkage Pattern

The 4 dimensions form a logical flow:

1. **External Forces** (Externe Effekte) drive strategic choices
2. **Strategic Choices** (Neue Horizonte) prioritize value opportunities
3. **Value Drivers** (Digitale Wertetreiber) require foundational capabilities
4. **Foundational Capabilities** (Digitales Fundament) enable value delivery

---

## Language Support

**Slugs:** German original lowercase with hyphens (externe-effekte, digitales-fundament)

**Display Names:** Bilingual — German primary with English translation

**Body Text:** Proper German umlauts (ä, ö, ü, ß) in content

---

## Portfolio Integration

Smarter-service trends link to B2B ICT portfolio offerings via a **portfolio mapping file**.

### Portfolio File

A markdown file following the B2B ICT Portfolio structure with 8 dimensions (0-7) and 57 categories. Created by the `ict-scan` skill.

**File Format:** See report-template.md in cogni-portfolio (`cogni-portfolio/skills/ict-scan/references/report-template.md`)

**Example:** `deutsche-telekom-portfolio.md`

### Configuration

During project initialization (Phase 0), the user provides the path to an existing portfolio mapping file:

| Field | Location | Description |
|-------|----------|-------------|
| `portfolio_file` | Initial question frontmatter | Absolute path to portfolio mapping file |
| `portfolio_file_path` | `.metadata/sprint-log.json` | Same path, stored for workflow access |

### Integration Flow

```text
ict-scan skill → <company>-portfolio.md → human review → smarter-service research
```

1. **Pre-requisite:** Run `ict-scan` skill to create `<company>-portfolio.md`
2. **Human Review:** Verify and refine the portfolio mapping
3. **Research Init:** Provide portfolio file path during smarter-service initialization
4. **Trend Synthesis:** trends-creator links TIPS to portfolio offerings

### Usage in Trends

Each TIPS trend includes a **B2B ICT Service Enablement** section that maps to portfolio offerings:

- **Dimension Bridge:** Maps trend implementation to 8 B2B ICT dimensions (0-7)
- **Portfolio Links:** Direct links to relevant services from the portfolio file
- **Format:** `[Service Name](service-url)` (URLs from portfolio file)

---

## Version History

- **v7.0:** Standardized to 60 TIPS (5 per cell × 12 cells), added source-type scoring caps for training candidates
- **v6.0 (Sprint 444):** Refined to 52 TIPS (5 ACT + 5 PLAN + 3 OBSERVE per dimension) for horizon-optimized selection
- **v5.0:** Expanded to 60 TIPS (5 per cell × 12 cells) with auto-selection by composite score
- **v4.0 (Sprint 441):** Added portfolio file integration (replaces b2b-ict-portfolio project references)
- **v3.0 (Sprint 438):** Refactored to WHAT-only definition (moved HOW to skill phase files)
- **v2.0 (Sprint 277):** Split into dimensions.md + synthesis-template.md
- **v1.0:** Initial smarter-service template
