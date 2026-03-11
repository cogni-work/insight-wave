# Scoring Framework Reference

**Reference Checksum:** `sha256:trend-scout-scoring-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: scoring-framework.md | Checksum: trend-scout-scoring-v1
```

---

## Overview

This framework provides systematic scoring for trend candidates using academic foundations from:

- **Ansoff (1975)** - Weak signal intensity (5-level)
- **Rohrbeck (2010)** - Corporate Foresight Maturity Model
- **CRAAP Framework** - Source authority assessment

---

## 1. Multi-Criteria Scoring System

### Composite Score Formula

```text
Trend Score = Σ(wi × Si) / Σwi

Where:
  wi = weight for criterion i
  Si = score for criterion i (0.0-1.0)
```

### Scoring Weights

| Criterion | Weight | Description |
|-----------|--------|-------------|
| **Impact** | 25% | Strategic/business significance for the subsector |
| **Probability** | 20% | Likelihood of materialization within horizon |
| **Strategic Fit** | 20% | Alignment with subsector focus and research topic |
| **Source Quality** | 15% | Credibility and authority of source |
| **Signal Strength** | 15% | Frequency, recency, source convergence |
| **Uncertainty Penalty** | -5% | Confidence reduction for contradictory signals |

### Individual Criterion Scoring (0.0-1.0)

#### Impact Score

| Score | Criteria |
|-------|----------|
| 0.9-1.0 | Transformational - reshapes entire industry structure |
| 0.7-0.8 | High - significant competitive advantage/disadvantage |
| 0.5-0.6 | Medium - notable operational or strategic effect |
| 0.3-0.4 | Low - minor incremental effect |
| 0.0-0.2 | Minimal - negligible effect on subsector |

#### Probability Score

| Score | Criteria |
|-------|----------|
| 0.9-1.0 | Near certain - already occurring, evidence clear |
| 0.7-0.8 | Highly likely - strong signals, clear trajectory |
| 0.5-0.6 | Probable - emerging evidence, plausible path |
| 0.3-0.4 | Possible - weak signals, uncertain conditions |
| 0.0-0.2 | Speculative - minimal evidence, high uncertainty |

#### Strategic Fit Score

| Score | Criteria |
|-------|----------|
| 0.9-1.0 | Direct alignment - core to research topic |
| 0.7-0.8 | Strong alignment - clearly relevant to subsector |
| 0.5-0.6 | Moderate alignment - tangentially relevant |
| 0.3-0.4 | Weak alignment - indirect connection |
| 0.0-0.2 | Minimal alignment - peripheral to focus |

#### Source Quality Score

See Section 3 (CRAAP Framework) below.

#### Signal Strength Score

| Score | Criteria |
|-------|----------|
| 0.9-1.0 | Strong - 5+ independent sources, recent (< 6 months) |
| 0.7-0.8 | Good - 3-4 sources, reasonably recent (< 12 months) |
| 0.5-0.6 | Moderate - 2 sources, within 18 months |
| 0.3-0.4 | Weak - single source, older than 18 months |
| 0.0-0.2 | Very weak - unverified, no clear provenance |

### Composite Score Calculation Example

```text
Example: "EU AI Act Compliance" for Automotive subsector

Scores:
- Impact: 0.85 (regulatory mandate affects all OEMs)
- Probability: 0.95 (law already passed, deadline set)
- Strategic Fit: 0.80 (directly relevant to automotive AI)
- Source Quality: 0.90 (EU Commission primary source)
- Signal Strength: 0.90 (multiple sources, recent)
- Uncertainty: 0.05 penalty (low uncertainty)

Composite = (0.25×0.85 + 0.20×0.95 + 0.20×0.80 + 0.15×0.90 + 0.15×0.90) - 0.05
         = (0.2125 + 0.19 + 0.16 + 0.135 + 0.135) - 0.05
         = 0.8325 - 0.05
         = 0.78 (rounded)
```

---

## 2. Signal Confidence Tiers (Triangulation)

### Confidence Scoring

```text
Signal Confidence = Σ(Source Weight × Signal Agreement) / Total Sources
```

### Confidence Tiers

| Tier | Range | Criteria | Display |
|------|-------|----------|---------|
| **HIGH** | 0.80-1.0 | 3+ independent sources confirm, same direction | ●●●● |
| **MEDIUM** | 0.50-0.79 | 2+ sources confirm with minor variations | ●●●○ |
| **LOW** | 0.30-0.49 | Conflicting signals or single source | ●●○○ |
| **UNCERTAIN** | < 0.30 | Contradictory signals, insufficient data | ●○○○ |

### Source Weights for Triangulation

| Source Type | Weight | Examples |
|-------------|--------|----------|
| Primary/Original | 1.0x | EU Commission, patent filings, peer-reviewed |
| Industry Analyst | 0.9x | Gartner, Forrester, Roland Berger, McKinsey |
| Academic Research | 0.85x | Fraunhofer, university publications |
| Industry Association | 0.8x | VDMA, BITKOM, VDA, ZVEI |
| News Sources | 0.6x | Reuters, Handelsblatt, FAZ |
| Trade Publications | 0.5x | Industry magazines, blogs |
| Social/Informal | 0.3x | LinkedIn, Twitter, forums |

### Triangulation Process

1. **Collect sources** - gather all sources mentioning the signal
2. **Classify sources** - assign weight based on type
3. **Assess agreement** - do sources agree on direction/timing?
4. **Calculate confidence** - weighted average of agreements
5. **Assign tier** - map to HIGH/MEDIUM/LOW/UNCERTAIN

### TALKS Framework for Contradictory Signals

When signals conflict:

| Step | Action |
|------|--------|
| **T**rigger | Identify when mismatch exceeds threshold (>30% disagreement) |
| **A**rticulate | Document specific discrepancy |
| **L**ist | Enumerate possible explanations (timing, scope, definition) |
| **K**nowledge | Consider domain context and expert perspective |
| **S**olve | Weighted reconciliation or note uncertainty |

---

## 3. Source Authority Scoring (CRAAP Framework)

### CRAAP Criteria

| Criterion | What to Assess |
|-----------|----------------|
| **C**urrency | Publication date, update frequency |
| **R**elevance | Fit to research question and subsector |
| **A**uthority | Author credentials, institutional affiliation |
| **A**ccuracy | Evidence quality, citations, methodology |
| **P**urpose | Objectivity, bias indicators, commercial interest |

### Authority Score Rubric

| Score | Criteria | Examples |
|-------|----------|----------|
| **5** | Peer-reviewed, leading expert, major institution | Nature, Science, EU official docs, Fraunhofer |
| **4** | Established professional, reputable organization | McKinsey, Gartner, major consulting firms |
| **3** | Industry professional, recognized trade publication | VDMA reports, Handelsblatt, industry magazines |
| **2** | Non-expert author, commercial source with potential bias | Vendor whitepapers, promotional content |
| **1** | Anonymous, unknown credentials, unverified | Blog posts, social media, forums |

### Source Quality Score Derivation

```text
Source Quality Score = Authority Score / 5

Examples:
- Authority 5 → Source Quality 1.0
- Authority 4 → Source Quality 0.8
- Authority 3 → Source Quality 0.6
- Authority 2 → Source Quality 0.4
- Authority 1 → Source Quality 0.2
```

---

## 4. Weak Signal Intensity (Ansoff 5-Level)

### Signal Intensity Classification

Based on Igor Ansoff's 1975 weak signal theory:

| Level | Name | Description | Horizon Mapping |
|-------|------|-------------|-----------------|
| **1** | Turbulence | Sense of environmental turbulence, vague unease | OBSERVE |
| **2** | Source ID | Source of threat/opportunity identified | OBSERVE |
| **3** | Concrete | Concrete definition emerges, trend articulated | PLAN |
| **4** | Response | Response capability develops, pilots begin | PLAN/ACT |
| **5** | Foreseeable | Outcomes become foreseeable, mainstream adoption | ACT |

### Signal Intensity Indicators

| Level | Key Indicators |
|-------|----------------|
| **1** | Expert speculation, scenario planning, futures reports |
| **2** | Early research papers, patent filings, VC seed investments |
| **3** | Pilot projects, industry reports, regulatory proposals |
| **4** | Scale deployments, standards development, training programs |
| **5** | Market penetration data, revenue figures, mainstream coverage |

### Horizon-Intensity Validation

Use signal intensity to validate horizon assignment:

| Assigned Horizon | Valid Intensity Levels |
|------------------|------------------------|
| OBSERVE (5+ years) | 1, 2 |
| PLAN (2-5 years) | 2, 3, 4 |
| ACT (0-2 years) | 4, 5 |

**Validation Rule:** If intensity doesn't match horizon, flag for review:

- Intensity 5 in OBSERVE → Consider moving to ACT
- Intensity 1 in ACT → Consider moving to OBSERVE
- Intensity 3 can span PLAN/OBSERVE boundary

---

## 5. Recency Weighting

### Exponential Decay Formula

```text
w(y) = a^(Y-y)

Where:
  a = 0.714 (decay constant)
  Y = current year
  y = source publication year
```

### Weight Distribution

| Age | Weight | Cumulative |
|-----|--------|------------|
| 0-1 years | 100% | 67% of total |
| 2-5 years | 71-36% | 28% of total |
| 6-10 years | 26-13% | 5% of total |
| 10+ years | <13% | Minimal |

### Application

Apply recency weight to signal strength scoring:

```text
Recency-Adjusted Signal = Base Signal × Recency Weight
```

---

## 6. Scoring Output Structure

### Per-Candidate Scoring

```yaml
candidate_scoring:
  composite_score: 0.78  # Weighted average (0.0-1.0)
  confidence_tier: "high"  # HIGH/MEDIUM/LOW/UNCERTAIN
  signal_intensity: 4  # 1-5 (Ansoff level)

  # Component scores (for transparency)
  component_scores:
    impact: 0.85
    probability: 0.95
    strategic_fit: 0.80
    source_quality: 0.90
    signal_strength: 0.90
    uncertainty_penalty: 0.05

  # Triangulation details
  triangulation:
    source_count: 4
    source_agreement: 0.92
    source_types: ["primary", "analyst", "news"]
```

### Score Display Formatting

For `trend-candidates.md` presentation:

| Score Range | Display | Color Hint |
|-------------|---------|------------|
| 0.80-1.0 | ★★★★★ | Green |
| 0.60-0.79 | ★★★★☆ | Light green |
| 0.40-0.59 | ★★★☆☆ | Yellow |
| 0.20-0.39 | ★★☆☆☆ | Orange |
| 0.00-0.19 | ★☆☆☆☆ | Red |

### Confidence Tier Display

| Tier | Icon | Description |
|------|------|-------------|
| HIGH | ✓✓✓ | Multiple sources confirm |
| MEDIUM | ✓✓○ | Some confirmation |
| LOW | ✓○○ | Limited confirmation |
| UNCERTAIN | ?○○ | Conflicting data |

---

## 7. Integration Notes

### Phase 2 Integration

In `phase-2-generate.md`, apply scoring during candidate generation:

1. Calculate component scores for each candidate
2. Compute composite score
3. Determine confidence tier via triangulation
4. Classify signal intensity (Ansoff level)
5. Validate horizon-intensity alignment

### Phase 3 Integration

In `phase-3-present.md`, display scores in markdown tables:

- Add Score column with star rating
- Add Confidence column with tier icon
- Add Intensity column with level number
- Sort candidates within cell by score (descending)

### Schema Integration

Add to `trend-scout-config.schema.json`:

```json
"score": { "type": "number", "minimum": 0, "maximum": 1 },
"confidence_tier": { "enum": ["high", "medium", "low", "uncertain"] },
"signal_intensity": { "type": "integer", "minimum": 1, "maximum": 5 },
"indicator_type": { "enum": ["leading", "lagging"] },
"indicator_lead_time": { "type": "string" },
"diffusion_stage": { "enum": ["innovators", "early_adopters", "early_majority", "late_majority", "laggards"] }
```

---

## 8. Leading vs Lagging Indicator Classification

### Overview

Leading indicators provide advance warning of trends (12-36+ months ahead), while lagging indicators confirm trends already in motion. Proper classification enables horizon-appropriate strategic response.

**Strategic Value:** Portfolio should contain 40%+ leading indicators for proactive positioning.

### Classification Rules

| Indicator Type | Examples | Signal Value | Strategic Use |
|----------------|----------|--------------|---------------|
| **Leading** | VC investment, patent filings, academic pubs, job postings, regulatory proposals, seed funding | Early detection, OBSERVE/PLAN horizons | Identify emerging opportunities |
| **Lagging** | Market penetration, revenue data, mainstream media, employment figures, IPOs | Confirmation, ACT horizon validation | Validate trend maturation |

### Source Type to Indicator Mapping

| Source Type | Indicator Type | Lead Time | Confidence |
|-------------|----------------|-----------|------------|
| Patent filings | leading | 36-72 months | high |
| Academic papers | leading | 24-36 months | high |
| Seed/Series A funding | leading | 18-24 months | medium |
| Job posting surges | leading | 6-18 months | medium-high |
| Regulatory proposals | leading | 12-24 months | high |
| Series B+ funding | leading | 12-18 months | medium |
| Pilot announcements | mixed | 6-12 months | medium |
| Industry reports | mixed | 3-12 months | medium |
| Trade media | lagging | 0-6 months | medium |
| Mainstream news | lagging | 0-3 months | low-medium |
| Market share data | lagging | 0 months | high |
| Revenue figures | lagging | 0 months | high |

### Per-Candidate Classification

```yaml
indicator_classification:
  type: "leading" | "lagging"
  lead_time: "6-18 months" | "12-24 months" | "24-36 months" | "36+ months" | "N/A"
  source_type: "funding" | "jobs" | "academic" | "patent" | "regulatory" | "news" | "market"
  confidence: "high" | "medium" | "low"
```

### Portfolio Balance Target

| Portfolio Metric | Target | Rationale |
|------------------|--------|-----------|
| Leading indicators | ≥40% | Proactive trend detection |
| Lagging indicators | ≤60% | Confirmation without bias |
| Patent/academic signals | ≥15% | Long-horizon visibility |
| Funding signals | ≥10% | Commercial validation |
| Job market signals | ≥8% | Skills demand visibility |

---

## 9. Rogers' Diffusion Stage Classification

### Overview

Based on Everett Rogers' *Diffusion of Innovations* (1962), this classification maps trends to adoption stages. The critical "chasm" between Early Adopters (16%) and Early Majority requires different strategic responses.

### Adoption Stage Thresholds

| Stage | Adoption % | Cumulative % | Characteristics |
|-------|------------|--------------|-----------------|
| **Innovators** | 2.5% | 0-2.5% | Risk-tolerant, technology enthusiasts, experimenters |
| **Early Adopters** | 13.5% | 2.5-16% | Opinion leaders, visionaries, strategic investors |
| **Early Majority** | 34% | 16-50% | Pragmatists, wait for proof, follow leaders |
| **Late Majority** | 34% | 50-84% | Skeptics, pressure-driven, cost-sensitive |
| **Laggards** | 16% | 84-100% | Traditionalists, last adopters, resistance |

### The Chasm (16% Threshold)

**Critical Trend:** The transition from Early Adopters (16%) to Early Majority requires:

- Mainstream proof points (not just visionary success)
- Complete product solutions (not technology demos)
- Reference customers in target segment
- Pragmatist-friendly value propositions

**Chasm Detection:**

| Metric | Pre-Chasm (<16%) | Post-Chasm (>16%) |
|--------|------------------|-------------------|
| Adoption evidence | Pilots, limited deployments | Widespread production use |
| Customer type | Innovators, visionaries | Mainstream enterprises |
| Competition | Limited, fragmented | Consolidating, maturing |
| Standards | Emerging, competing | Converging, established |
| Pricing | Premium, customized | Standardizing, commoditizing |

### Per-Candidate Classification

```yaml
diffusion_stage:
  stage: "innovators" | "early_adopters" | "early_majority" | "late_majority" | "laggards"
  estimated_adoption: 0.05  # 5% adoption estimate
  crossed_chasm: false  # Has it passed 16% threshold?
  evidence: "Pilot deployments at 3 major OEMs"
```

### Horizon-Diffusion Alignment

| Horizon | Typical Diffusion Stages | Strategic Implication |
|---------|--------------------------|----------------------|
| OBSERVE | Innovators, Early Adopters (pre-chasm) | Monitor, experiment, learn |
| PLAN | Early Adopters, Early Majority (crossing chasm) | Prepare capabilities, pilot |
| ACT | Early Majority, Late Majority | Deploy, scale, optimize |

**Validation Rule:** Flag misalignment for review:

- Innovators stage in ACT horizon → Move to OBSERVE
- Late Majority in OBSERVE → Move to ACT
- Early Majority typically spans PLAN/ACT boundary

### Diffusion Stage Indicators

| Stage | Key Indicators | Evidence Examples |
|-------|----------------|-------------------|
| Innovators | Academic papers, seed funding, patents | "First research paper published 2024" |
| Early Adopters | Series A/B, pilot programs, early vendors | "5 startups raised Series A in 2024" |
| Early Majority | Enterprise adoption, standards, M&A | "Gartner MQ established, 3 acquisitions" |
| Late Majority | Mainstream media, commodity pricing | "Feature in SAP/Oracle, price decline 40%" |
| Laggards | Regulatory mandates, legacy replacement | "Required by EU regulation, replacing X" |

---

## 10. Hype Cycle Position (Optional)

### Overview

Gartner's Hype Cycle provides a complementary view to Rogers' diffusion, focusing on expectations rather than adoption. Use when available data supports classification.

**Note:** This is subjective and should be used with caution. When uncertain, omit or mark as "unknown".

### Hype Cycle Phases

| Phase | Description | Strategic Response |
|-------|-------------|-------------------|
| **Innovation Trigger** | Technology breakthrough, early publicity | Monitor, experiment |
| **Peak of Inflated Expectations** | Media frenzy, unrealistic expectations | Cautious pilots only |
| **Trough of Disillusionment** | Reality sets in, failures publicized | Assess survivors, evaluate |
| **Slope of Enlightenment** | Practical applications emerge | Serious pilots, early deployment |
| **Plateau of Productivity** | Mainstream adoption, clear ROI | Scale deployment |

### Hype Cycle Indicators

| Phase | Typical Indicators |
|-------|-------------------|
| Trigger | First demos, breakthrough announcements, seed funding |
| Peak | Media hype, vendor proliferation, inflated claims |
| Trough | Vendor consolidation, project failures, skepticism |
| Slope | Success stories, best practices, standards |
| Plateau | Market penetration >20%, commoditization |

### Per-Candidate Classification (Optional)

```yaml
hype_cycle:
  position: "trigger" | "peak" | "trough" | "slope" | "plateau" | "unknown"
  confidence: "low" | "medium"  # Always lower than diffusion stage
  evidence: "Multiple vendor failures in 2024, media skepticism increasing"
```

### Cross-Validation with Diffusion Stage

| Hype Cycle | Typical Diffusion Stage | Notes |
|------------|-------------------------|-------|
| Trigger | Innovators | New technology, limited adoption |
| Peak | Innovators/Early Adopters | Expectations outpace reality |
| Trough | Early Adopters (stalled) | Chasm risk high |
| Slope | Early Majority | Crossing chasm successfully |
| Plateau | Late Majority | Mainstream adoption |

---

## 11. Extended Scoring Output Structure

### Complete Per-Candidate Scoring

```yaml
candidate_scoring:
  # Core scoring (Section 6)
  composite_score: 0.78
  confidence_tier: "high"
  signal_intensity: 4
  component_scores:
    impact: 0.85
    probability: 0.95
    strategic_fit: 0.80
    source_quality: 0.90
    signal_strength: 0.90
    uncertainty_penalty: 0.05

  # Triangulation (Section 2)
  triangulation:
    source_count: 4
    source_agreement: 0.92
    source_types: ["primary", "analyst", "news", "funding"]

  # Leading/Lagging Classification (Section 8)
  indicator_classification:
    type: "leading"
    lead_time: "12-24 months"
    source_type: "funding"
    confidence: "medium"

  # Diffusion Stage (Section 9)
  diffusion_stage:
    stage: "early_adopters"
    estimated_adoption: 0.08  # 8%
    crossed_chasm: false
    evidence: "Series B funding for 5+ startups in 2024"

  # Hype Cycle (Section 10 - Optional)
  hype_cycle:
    position: "slope"
    confidence: "low"
    evidence: "Post-trough recovery, practical applications emerging"
```

### Portfolio-Level Metrics

```yaml
portfolio_metrics:
  total_candidates: 20

  # Indicator balance
  leading_indicator_count: 9
  leading_indicator_pct: 0.45
  lagging_indicator_count: 11
  lagging_indicator_pct: 0.55

  # Diffusion distribution
  diffusion_distribution:
    innovators: 3
    early_adopters: 6
    early_majority: 8
    late_majority: 3
    laggards: 0

  # Chasm analysis
  pre_chasm_count: 9  # Innovators + Early Adopters
  post_chasm_count: 11  # Early Majority + Late Majority + Laggards

  # Source diversity
  source_type_distribution:
    funding: 4
    jobs: 3
    academic: 2
    patent: 2
    regulatory: 3
    news: 6
```
