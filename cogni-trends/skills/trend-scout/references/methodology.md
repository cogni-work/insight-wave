# Trend-Scout Methodology Reference

**Reference Checksum:** `sha256:trend-scout-methodology-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: methodology.md | Checksum: trend-scout-methodology-v1
```

---

## Overview

This methodology reference documents the academic foundations and systematic approaches underlying the trend-scout skill. Our methodology synthesizes best practices from corporate foresight leaders (Shell, BMW, Siemens), academic foundations (Ansoff, Rohrbeck, Rogers), and practical implementation patterns for TIPS-based trend detection across the German Mittelstand and DACH market.

**Core Achievement:** Firms with mature foresight capabilities demonstrate **33% higher profitability** and **200% higher market capitalization growth** (Rohrbeck, 2010).

---

## 1. Academic Foundations

### 1.1 Ansoff's Weak Signal Theory (1975)

**Igor Ansoff's weak signal theory remains the cornerstone framework**, defining weak signals as "advanced and imprecise symptoms of impending future problems."

#### Five-Level Signal Intensity Model

| Level | Name | Description | TIPS Horizon |
|-------|------|-------------|--------------|
| **1** | Turbulence | Sense of environmental turbulence, vague unease | OBSERVE (5+ years) |
| **2** | Source ID | Source of threat/opportunity identified | OBSERVE (5+ years) |
| **3** | Concrete | Concrete definition emerges, trend articulated | PLAN (2-5 years) |
| **4** | Response | Response capability develops, pilots begin | PLAN/ACT transition |
| **5** | Foreseeable | Outcomes become foreseeable, mainstream adoption | ACT (0-2 years) |

**Application:** We classify each trend candidate by signal intensity level and validate against assigned horizon. Mismatches (e.g., Level 5 in OBSERVE) trigger review.

### 1.2 Rohrbeck's Corporate Foresight Maturity Model

**René Rohrbeck's research** (based on 107 interviews across 19 multinationals) identifies three core foresight processes:

| Process | Description | Our Implementation |
|---------|-------------|-------------------|
| **Perceiving** | Environmental scanning | Phase 1: Web research + API queries |
| **Prospecting** | Sensemaking and interpretation | Phase 2: Candidate generation + scoring |
| **Probing** | Strategic action | Phase 4+: Finalization + value-modeler (relationship networks, solution templates) |

### 1.3 Day & Schoemaker's Peripheral Vision

Less than **20% of firms** have developed sufficient capability to detect weak signals competitively. Key filtering criteria for distinguishing noise from signals:

| Criterion | Assessment |
|-----------|------------|
| **Credibility** | Source reputation and authority |
| **Novelty** | New information vs. already known |
| **Likelihood** | Probability of occurrence |
| **Impact** | Significance of potential change |
| **Relevance** | Direct effect on target domain |
| **Time to Awareness** | When it becomes widely known |

---

## 2. Trend Lifecycle Classification

### 2.1 Rogers' Diffusion of Innovations (1962)

**Everett Rogers' model** provides quantifiable adoption thresholds with the critical "chasm" at 16% adoption:

| Stage | Adoption % | Cumulative | Characteristics |
|-------|------------|------------|-----------------|
| **Innovators** | 2.5% | 0-2.5% | Risk-tolerant, technology enthusiasts |
| **Early Adopters** | 13.5% | 2.5-16% | Opinion leaders, visionaries |
| **Early Majority** | 34% | 16-50% | Pragmatists, wait for proof |
| **Late Majority** | 34% | 50-84% | Skeptics, pressure-driven |
| **Laggards** | 16% | 84-100% | Traditionalists, last adopters |

#### The Chasm (16% Threshold)

Geoffrey Moore's "Crossing the Chasm" identifies the critical failure point between Early Adopters and Early Majority. Trends at **<16% adoption** require different strategic treatment:

| Evidence | Pre-Chasm (<16%) | Post-Chasm (>16%) |
|----------|------------------|-------------------|
| Adoption | Pilots, limited | Widespread production |
| Customers | Visionaries | Mainstream enterprises |
| Competition | Fragmented | Consolidating |
| Standards | Emerging | Established |
| Pricing | Premium | Standardizing |

**Application:** Each candidate receives diffusion stage classification with chasm status, enabling horizon-appropriate strategic response.

### 2.2 NASA Technology Readiness Levels (Adapted)

The 9-point TRL scale adapted for trend maturity:

| TRL Range | Phase | TIPS Horizon | Evidence |
|-----------|-------|--------------|----------|
| 1-3 | Research | OBSERVE | Basic principles, concept formulation |
| 4-6 | Development | PLAN | Component validation, prototype demo |
| 7-9 | Deployment | ACT | Operational demonstration, mission proven |

### 2.3 Gartner Hype Cycle (Optional)

Complementary view focusing on expectations rather than adoption:

| Phase | Description | Strategic Response |
|-------|-------------|-------------------|
| Innovation Trigger | Technology breakthrough | Monitor, experiment |
| Peak of Inflated Expectations | Media frenzy | Cautious pilots only |
| Trough of Disillusionment | Reality sets in | Assess survivors |
| Slope of Enlightenment | Practical applications | Serious pilots |
| Plateau of Productivity | Mainstream adoption | Scale deployment |

---

## 3. Leading vs. Lagging Indicators

### 3.1 Classification Framework

| Indicator Type | Examples | Lead Time | Strategic Use |
|----------------|----------|-----------|---------------|
| **Leading** | VC investment, patent filings, academic pubs, job postings, regulatory proposals | 6-72 months | Early detection, OBSERVE/PLAN |
| **Lagging** | Market penetration, revenue data, mainstream media, employment figures | 0-6 months | Confirmation, ACT validation |

### 3.2 Source Type to Lead Time Mapping

| Source Type | Indicator | Lead Time | Confidence |
|-------------|-----------|-----------|------------|
| Patent filings | leading | 36-72 months | high |
| Academic papers | leading | 24-36 months | high |
| Seed/Series A funding | leading | 18-24 months | medium |
| Job posting surges | leading | 6-18 months | medium-high |
| Regulatory proposals | leading | 12-24 months | high |
| Series B+ funding | leading | 12-18 months | medium |
| Industry reports | mixed | 3-12 months | medium |
| Trade media | lagging | 0-6 months | medium |
| Mainstream news | lagging | 0-3 months | low-medium |
| Market share data | lagging | 0 months | high |

### 3.3 Portfolio Balance Target

| Metric | Target | Rationale |
|--------|--------|-----------|
| Leading indicators | ≥40% | Proactive trend detection |
| Patent/academic signals | ≥15% | Long-horizon visibility |
| Funding signals | ≥10% | Commercial validation |
| Job market signals | ≥8% | Skills demand visibility |

---

## 4. Multi-Criteria Scoring System

### 4.1 Composite Score Formula

```text
Trend Score = Σ(wi × Si) / Σwi - uncertainty_penalty

Where:
  wi = weight for criterion i
  Si = score for criterion i (0.0-1.0)
```

### 4.2 Scoring Weights

| Criterion | Weight | Assessment |
|-----------|--------|------------|
| **Impact** | 25% | Strategic/business significance for subsector |
| **Probability** | 20% | Likelihood of materialization within horizon |
| **Strategic Fit** | 20% | Alignment with research topic and subsector |
| **Source Quality** | 15% | CRAAP authority score (1-5 scale) |
| **Signal Strength** | 15% | Frequency, recency, source convergence |
| **Uncertainty Penalty** | -5% max | Reduction for contradictory signals |

### 4.3 CRAAP Framework for Source Authority

| Criterion | What to Assess |
|-----------|----------------|
| **C**urrency | Publication date, update frequency |
| **R**elevance | Fit to research question and subsector |
| **A**uthority | Author credentials, institutional affiliation |
| **A**ccuracy | Evidence quality, citations, methodology |
| **P**urpose | Objectivity, bias indicators, commercial interest |

### 4.4 Authority Score Rubric

| Score | Criteria | Examples |
|-------|----------|----------|
| **5** | Peer-reviewed, leading expert, major institution | Nature, Science, EU Commission, Fraunhofer |
| **4** | Established professional, reputable organization | McKinsey, Gartner, VDMA, BITKOM |
| **3** | Industry professional, recognized publication | Handelsblatt, trade magazines |
| **2** | Non-expert author, commercial source | Vendor whitepapers |
| **1** | Anonymous, unknown credentials | Blogs, forums |

### 4.5 Recency Weighting

Exponential decay formula distributes **67% weight to recent 5 years**:

```python
recency_weight = 0.714 ** (current_year - publication_year)

# Weight distribution:
# 0-1 years: 100% (67% of total weight)
# 2-5 years: 71-36% (28% of total weight)
# 6-10 years: 26-13% (5% of total weight)
```

---

## 5. Signal Triangulation

### 5.1 Denzin Triangulation Framework

| Type | Description | Our Implementation |
|------|-------------|-------------------|
| Data triangulation | Across time, space, sources | Multi-source validation |
| Investigator triangulation | Multiple analysts | Human-AI collaboration |
| Theory triangulation | Multiple interpretive schemes | Multi-framework scoring |
| Methodological triangulation | Multiple methods | Web + API + training |

### 5.2 Confidence Tiers

```text
Signal Confidence = Σ(Source Weight × Signal Agreement) / Total Sources
```

| Tier | Range | Criteria | Required Sources |
|------|-------|----------|------------------|
| **HIGH** | 0.80-1.0 | 3+ independent sources confirm, same direction | 3+ |
| **MEDIUM** | 0.50-0.79 | 2+ sources confirm with minor variations | 2+ |
| **LOW** | 0.30-0.49 | Conflicting signals or single source | 1 |
| **UNCERTAIN** | <0.30 | Contradictory signals, insufficient data | - |

### 5.3 Source Weighting Factors

| Source Type | Weight | Examples |
|-------------|--------|----------|
| Primary/Original | 1.0x | EU Commission, patent filings, peer-reviewed |
| Industry Analyst | 0.9x | Gartner, Forrester, Roland Berger |
| Academic Research | 0.85x | Fraunhofer, university publications |
| Industry Association | 0.8x | VDMA, BITKOM, VDA, ZVEI |
| News Sources | 0.6x | Reuters, Handelsblatt |
| Trade Publications | 0.5x | Industry magazines |
| Social/Informal | 0.3x | LinkedIn, blogs |

### 5.4 TALKS Framework for Contradictory Signals

When signals conflict (>30% disagreement):

| Step | Action |
|------|--------|
| **T**rigger | Identify when mismatch exceeds threshold |
| **A**rticulate | Document specific discrepancy |
| **L**ist | Enumerate possible explanations |
| **K**nowledge | Engage domain context and expert perspective |
| **S**olve | Weighted reconciliation or note uncertainty |

---

## 6. Alternative Data Sources

### 6.1 Source Categories by Lead Time

| Category | Lead Time | Sources |
|----------|-----------|---------|
| **Patent Data** | 36-72 months | USPTO PatentsView, Lens.org, EPO OPS |
| **Academic Publications** | 24-36 months | OpenAlex, Semantic Scholar, arXiv, PubMed |
| **Funding/Investment** | 12-24 months | Crunchbase, PitchBook (web search fallback) |
| **Job Postings** | 6-18 months | Lightcast (web search fallback) |
| **Regulatory Pipeline** | 12-24 months | EUR-Lex, SEC EDGAR, FDA Open Data |
| **Industry Associations** | 12-24 months | VDMA, BITKOM, ZVEI, VDA |
| **Research Institutes** | 24-36 months | Fraunhofer, Max-Planck, Zukunftsinstitut |

### 6.2 Free APIs Used

| API | Cost | Authentication | Best For |
|-----|------|----------------|----------|
| OpenAlex | FREE | Optional email | 209M+ academic works |
| USPTO PatentsView | FREE | None | US technology trends |
| Lens.org | FREE | Free token | Patent-publication links |
| arXiv | FREE | None | Cutting-edge research |
| EUR-Lex | FREE | None | EU regulatory pipeline |
| Semantic Scholar | FREE | Optional key | 200M+ papers, AI features |

### 6.3 Search Budget

| Search Set | Count | Focus |
|------------|-------|-------|
| Standard bilingual | 16 | 4 dimensions × 2 languages × 2 regions |
| DACH site-specific | 8 | Associations, research, consulting |
| Funding signals | 4 | VC, M&A, Series funding |
| Job market signals | 4 | Skills, hiring, demand |
| **Total** | **32** | Web searches per execution |

---

## 7. DACH-Specific Intelligence

### 7.1 German Industry Associations

| Association | Sector | Authority | Key Outputs |
|-------------|--------|-----------|-------------|
| **VDMA** | Mechanical Engineering | 4 | Statistics, Regulatory Cockpit, Industry 4.0 |
| **BITKOM** | Digital/IT | 4 | AI position papers, digital transformation |
| **VDA** | Automotive | 4 | Standards, electromobility papers |
| **ZVEI** | Electrical Industry | 4 | Digital Product Pass, Asset Administration Shell |
| **BDEW** | Energy & Water | 4 | Market data, e-mobility standards |
| **BDI** | All Industry | 4 | Economic outlook, policy recommendations |

### 7.2 German Research Institutes

| Institute | Authority | Value |
|-----------|-----------|-------|
| **Fraunhofer Society** | 5 | Applied research via Publica (100,000+ titles) |
| **Max-Planck Society** | 5 | Basic research, #2 in EU for deep tech spin-offs |
| **Zukunftsinstitut** | 4 | German futures think tank, Megatrend Map |

### 7.3 EU Regulatory Tracking

Key regulations with approaching deadlines:

| Regulation | Status | Deadline | Impact |
|------------|--------|----------|--------|
| AI Act | In force | Aug 2025/2026 | AI systems classification |
| Cyber Resilience Act | In force | Dec 2027 | Product security |
| DORA | In force | Jan 2025 | Financial sector |
| NIS2 | Implementation | Oct 2024 | Critical infrastructure |
| Data Act | In force | Sep 2025 | Data access rights |
| CSRD | In force | 2024-2026 | Sustainability reporting |

---

## 8. BMW Group Model: Technology Trend Radar

**Exemplary implementation reference** from BMW Group:

| Element | Description |
|---------|-------------|
| **Global Network** | Scouts in USA, Germany, Israel, Japan, Korea, Singapore, China |
| **Maturity Mapping** | Watch → Assess → Understand → Strategic Impact |
| **Public Access** | Transparent to attract startup/university partnerships |
| **Update Cycle** | Continuous with quarterly strategic reviews |

### Horizon Mapping

| BMW Stage | Description | TIPS Equivalent |
|-----------|-------------|-----------------|
| Watch | Early signals, monitoring | OBSERVE |
| Assess | Detailed evaluation | PLAN |
| Understand | Deep dive, pilots | PLAN/ACT |
| Strategic Impact | Active implementation | ACT |

---

## 9. Implementation in Trend-Scout

### 9.1 Phase-to-Methodology Mapping

| Phase | Methodology Applied |
|-------|---------------------|
| Phase 0 | Industry taxonomy, project initialization |
| Phase 1 | Multi-source data collection (Rohrbeck: Perceiving) |
| Phase 2 | Ansoff intensity, Rogers diffusion, CRAAP scoring, triangulation |
| Phase 3 | Confidence tiers, score display |
| Phase 4 | Human-in-the-loop validation |
| Phase 5 | Integration with value-modeler (Rohrbeck: Probing) |

### 9.2 Output Classifications

Each trend candidate includes:

| Field | Methodology Source |
|-------|-------------------|
| `signal_intensity` | Ansoff 5-level |
| `diffusion_stage` | Rogers Diffusion |
| `crossed_chasm` | Moore's Chasm Theory |
| `indicator_type` | Leading/Lagging classification |
| `lead_time` | Source-based lead time |
| `confidence_tier` | Triangulation |
| `score` | Multi-criteria weighted formula |
| `authority_score` | CRAAP framework |

### 9.3 Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Source diversity | 7+ types | web, academic, patent, regulatory, funding, jobs, DACH |
| Leading indicators | ≥40% | Percentage of candidates from leading sources |
| Triangulation | 3+ sources for HIGH | Source count for high-confidence signals |
| DACH coverage | 8+ queries | Site-specific German association queries |
| Signal quality | >0.6 average | Mean composite score |

---

## 10. References

### Academic Sources

1. **Ansoff, H.I.** (1975). "Managing Strategic Surprise by Response to Weak Signals." *California Management Review*, 18(2), 21-33.

2. **Rohrbeck, R.** (2010). "Corporate Foresight: Towards a Maturity Model for the Future Orientation of a Firm." *Physica-Verlag HD*.

3. **Day, G.S. & Schoemaker, P.J.H.** (2006). *Peripheral Vision: Detecting the Weak Signals That Will Make or Break Your Company*. Harvard Business School Press.

4. **Rogers, E.M.** (1962). *Diffusion of Innovations*. Free Press.

5. **Moore, G.A.** (1991). *Crossing the Chasm*. HarperBusiness.

6. **Saaty, T.L.** (1980). *The Analytic Hierarchy Process*. McGraw-Hill.

7. **Denzin, N.K.** (1978). *The Research Act: A Theoretical Introduction to Sociological Methods*. McGraw-Hill.

### Industry Sources

8. **BMW Group Technology Trend Radar** - technology-trend-radar.com

9. **Zukunftsinstitut Megatrend Map** - zukunftsinstitut.de/megatrends

10. **EC Strategic Foresight Reports** (2020-2025) - commission.europa.eu

11. **VDMA Industry 4.0 Publications** - vdma.org

12. **BITKOM Digital Transformation Studies** - bitkom.org

---

## Appendix: Scoring Examples

### Example 1: EU AI Act Compliance

```yaml
trend_name: "EU AI Act Compliance"
subsector: "Automotive"

# Ansoff Classification
signal_intensity: 5  # Outcomes foreseeable, law passed
intensity_evidence: "Regulation in force, deadlines set"

# Rogers Classification
diffusion_stage: "early_majority"
estimated_adoption: 0.25  # 25%
crossed_chasm: true
diffusion_evidence: "Gartner MQ established, enterprise adoption accelerating"

# Indicator Classification
indicator_type: "leading"
lead_time: "12-24 months"
source_type: "regulatory"

# Multi-Criteria Scoring
component_scores:
  impact: 0.85  # Mandatory compliance for all OEMs
  probability: 0.95  # Law already passed
  strategic_fit: 0.80  # Direct relevance to automotive AI
  source_quality: 0.90  # EU Commission primary source
  signal_strength: 0.90  # Multiple sources, recent
  uncertainty_penalty: 0.05

composite_score: 0.82
confidence_tier: "high"
```

### Example 2: Emerging Technology Signal

```yaml
trend_name: "Solid-State Battery Technology"
subsector: "Automotive"

# Ansoff Classification
signal_intensity: 3  # Concrete definition emerging
intensity_evidence: "Pilot projects at Toyota, QuantumScape funding"

# Rogers Classification
diffusion_stage: "early_adopters"
estimated_adoption: 0.08  # 8%
crossed_chasm: false
diffusion_evidence: "Series C funding, limited production announced"

# Indicator Classification
indicator_type: "leading"
lead_time: "24-36 months"
source_type: "funding"

# Multi-Criteria Scoring
component_scores:
  impact: 0.90  # Transformational for EV range
  probability: 0.65  # Technical challenges remain
  strategic_fit: 0.85  # Core to automotive electrification
  source_quality: 0.80  # Mix of patent + funding sources
  signal_strength: 0.70  # Growing but not converged
  uncertainty_penalty: 0.10

composite_score: 0.72
confidence_tier: "medium"
```
