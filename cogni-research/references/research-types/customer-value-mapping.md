# Customer Value Mapping Framework Definition

## Purpose

The Customer Value Mapping framework provides a 4-dimension structure aligned to Corporate Visions' Value Story methodology. It synthesizes existing industry research (TIPS) and portfolio offerings into customer-specific value propositions that directly feed the `value-story-creator` skill.

**Framework Source:** Corporate Visions Value Story Methodology (Why Change → Why Now → Why You → Why Pay)

**Architecture:** Customer contextualization layer on top of smarter-service TIPS linked to a portfolio mapping file

---

## Dimension Definitions

The framework uses exactly 4 dimensions aligned to Value Story stages:

### 1. Why Change Inputs

**Stage Alignment:** Disrupt Status Quo

**Core Question:** *"What unconsidered needs, hidden risks, and industry forces should compel this customer to change?"*

**Focus:** Unconsidered needs, hidden costs, industry pressures, competitive gaps

**Input Sources:**

- TIPS Trends (T) from smarter-service `externe-effekte` dimension
- TIPS Implications (I) showing business impact
- Customer-specific context (web research)

**MECE Role:** External and internal factors that CREATE the need for change

---

### 2. Why Now Inputs

**Stage Alignment:** Create Timing Urgency

**Core Question:** *"What timing pressures, costs of delay, and forcing functions make immediate action critical for this customer?"*

**Focus:** Cost of inaction, regulatory deadlines, competitive windows, compounding benefits

**Input Sources:**

- TIPS Implications (I) with quantified impacts
- TIPS Possibilities (P) showing time-sensitive opportunities
- Customer-specific deadlines and budget cycles

**MECE Role:** Temporal factors that CREATE urgency for action

---

### 3. Why You Inputs

**Stage Alignment:** Differentiate Solution

**Core Question:** *"How do our portfolio solutions uniquely address this customer's unconsidered needs better than alternatives?"*

**Focus:** Need-solution mappings, capability differentiation, proof points, methodology advantages

**Input Sources:**

- TIPS Solutions (S) from smarter-service
- Portfolio offerings from portfolio mapping file
- Case studies and proof points

**MECE Role:** Solution factors that CREATE differentiation

---

### 4. Why Pay Inputs

**Stage Alignment:** Justify Economics

**Core Question:** *"What ROI evidence, value metrics, and economic comparisons justify the investment for this customer?"*

**Focus:** ROI projections, TCO comparisons, value exchange framing, payback timelines

**Input Sources:**

- TIPS quantified benefits from smarter-service
- Portfolio offerings from portfolio mapping file
- Industry benchmark data

**MECE Role:** Economic factors that CREATE investment justification

---

## MECE Validation

**Mutually Exclusive:**

- Each dimension covers a distinct persuasion goal (change, urgency, differentiation, economics)
- No overlap between why change is needed, why now, why us, and why pay

**Collectively Exhaustive:**

- Together the 4 dimensions cover the complete Value Story research needs
- All inputs required by `value-story-creator` are produced

---

## Source Integration

This research type **discovers and selectively loads** from existing research projects:

### From smarter-service (52 TIPS per project)

| Selection Filter | Criteria |
|------------------|----------|
| **Horizon** | Act (primary), Plan (secondary), exclude Observe |
| **Dimension Priority** | externe-effekte, digitale-wertetreiber first |
| **Keyword Match** | Content matches customer pain points |
| **Portfolio Links** | Prefer TIPS with populated `portfolio_refs[]` |
| **Load Target** | 10-15 trends (~30-40%) |

### From Portfolio Mapping File

| Selection Filter | Criteria |
|------------------|----------|
| **Source** | `portfolio_file_path` from sprint-log.json |
| **Format** | Markdown tables per 8 dimensions (0-7), 57 categories |
| **Industry Vertical** | Matches customer industry |
| **Service Domain** | Matches solution category from customer needs |
| **Load Target** | 5-10 offerings matching customer needs |

**File Format:** See [portfolio-template.md](../../skills/portfolio-mapping/references/portfolio-template.md)

---

## Dimension-to-Source Mapping

| Value Story Dimension | Primary TIPS Source | Secondary Sources |
|-----------------------|---------------------|-------------------|
| Why Change | externe-effekte (T), digitale-wertetreiber (I) | Customer web research |
| Why Now | All dimensions (Act horizon) | Regulatory calendars, market timing |
| Why You | digitales-fundament (S), neue-horizonte (P) | Portfolio mapping file offerings |
| Why Pay | digitale-wertetreiber (I quantified) | Portfolio pricing, ROI benchmarks |

---

## Entity Type: Customer Need Mapping

**Location:** `{project}/11-trends/data/`

**Entity Type:** `customer-need-mapping`

**Purpose:** Captures chain-of-thought reasoning from customer pain → TIPS trend → Portfolio solution

Each entity contains:

- **Customer Context:** Why this need is relevant to this specific customer
- **COT Reasoning:** 2-step mapping (Need → TIPS+Portfolio)
- **Dimension:** Which Value Story stage (why-change, why-now, why-you, why-pay)
- **References:** `tips_trend_ref` and portfolio offerings from mapping file

---

## Minimum Entity Counts

| Dimension | Minimum Entities | Slide Coverage |
|-----------|------------------|----------------|
| Why Change | 3 | Slides 2-5 |
| Why Now | 2 | Slides 6-9 |
| Why You | 3 | Slides 10-13 |
| Why Pay | 2 | Slides 14-16 |
| **Total** | **10** | 13-17 slides |

---

## Quality Gates

### Discovery Gates

- Minimum 1 matching smarter-service project found
- Minimum 5 verifiable customer facts from web research

### Entity Quality Gates

- Each need-mapping entity must reference at least 1 TIPS trend
- Each Why You/Why Pay entity must have portfolio linkage
- Confidence score ≥ 0.70 for all mappings
- COT reasoning must be explicit and traceable

### Coverage Gates

- All 4 dimensions have minimum entity counts
- At least 1 quantified metric per dimension
- Customer name appears in all entity contexts

---

## Language Support

**Slugs:** Lowercase with hyphens (why-change, why-now, why-you, why-pay)

**Display Names:** English primary (German translation optional)

**Body Text:** Language parameter from user input (default: "en")

---

## Prerequisites

This research type requires:

1. **Existing smarter-service project** matching customer industry
2. **Portfolio mapping file** for the solution provider (created by `portfolio-mapping` skill)

### Integration Flow

```text
portfolio-mapping skill → <company>-portfolio.md → human review → customer-value-mapping research
```

1. **Pre-requisite:** Run `portfolio-mapping` skill to create `<company>-portfolio.md`
2. **Human Review:** Verify and refine the portfolio mapping
3. **Research Init:** Provide portfolio file path during initialization
4. **Trend Synthesis:** trends-creator links customer needs to portfolio offerings

### Configuration

| Field | Location | Description |
|-------|----------|-------------|
| `portfolio_file` | Initial question frontmatter | Absolute path to portfolio mapping file |
| `portfolio_file_path` | `.metadata/sprint-log.json` | Same path, stored for workflow access |

---

## Version History

- **v2.0 (Sprint 441):** Replaced b2b-ict-portfolio project with portfolio mapping file integration
- **v1.0 (Sprint 440):** Initial customer-value-mapping definition
