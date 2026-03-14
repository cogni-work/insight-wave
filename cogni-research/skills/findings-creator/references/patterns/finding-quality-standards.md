# Finding Quality Standards

**Purpose**: Define comprehensive quality standards and relevance assessment methodology for research findings to ensure every finding meets minimum thresholds for topical relevance, content depth, source reliability, evidentiary value, and **source freshness**.

**Version**: 2.1
**Last Updated**: 2025-12-12

**Changelog v2.1**: Added Entity Relevance sub-dimension to Topical Relevance for entity-specific questions. Prevents generic findings when research targets a specific named entity (company, product, organization).

**Changelog v2.0**: Added Source Freshness as 5th dimension (15% weight) to prevent outdated sources based on PICOT Timeframe constraints.

---

## Table of Contents

1. [Quality Philosophy](#quality-philosophy)
2. [5-Dimension Scoring Framework](#5-dimension-scoring-framework)
3. [Scoring Methodology](#scoring-methodology)
4. [Quality Thresholds](#quality-thresholds)
5. [Comprehensive Finding Template](#comprehensive-finding-template)
6. [Validation Checkpoints](#validation-checkpoints)
7. [Examples](#examples)
8. [Metadata Schema](#metadata-schema)

---

## Quality Philosophy

### Research-Based Best Practices

A high-quality research finding is characterized by:

1. **Relevance**: Direct alignment with the research question being investigated
2. **Substance**: Sufficient depth to support synthesis and analysis
3. **Credibility**: Sourced from reliable, authoritative publications
4. **Evidence**: Contains specific data points, methodology notes, or citeable trends

### Why Quality Matters

**Upstream Impact**:
- Findings feed into source creation, claim extraction, and narrative synthesis
- Low-quality findings create noise in the research corpus
- Filtering at creation is more efficient than post-hoc cleanup

**Downstream Benefits**:
- Higher synthesis quality (fact-checker and evidence-synthesizer rely on finding quality)
- Reduced manual review burden
- More focused research corpus

### Quality vs Quantity Trade-off

The 0.50 minimum threshold balances precision and recall:
- **Too restrictive** (>0.70): Misses valid findings, creates research gaps
- **Too permissive** (<0.40): Admits low-value noise, dilutes corpus quality
- **Optimal** (0.50): Filters bottom 20-40% while preserving useful findings

**Note**: Threshold is tunable based on rejection rate monitoring (see Validation Checkpoints section).

---

## 5-Dimension Scoring Framework

### Dimension 1: Topical Relevance (Weight: 35%)

**Definition**: Semantic alignment between finding content and the refined research question.

**Scoring Criteria**:

| Score Range | Description | Indicators |
|-------------|-------------|------------|
| 0.90-1.00 | Direct Answer | Finding directly addresses core question; primary topic match; explicit keyword overlap |
| 0.70-0.89 | High Relevance | Strong conceptual alignment; addresses key aspects; substantial keyword overlap |
| 0.50-0.69 | Moderate Relevance | Related to question; peripheral aspects covered; some keyword overlap |
| 0.30-0.49 | Tangential | Weak connection; mentioned in passing; minimal keyword overlap |
| 0.00-0.29 | Off-Topic | No clear connection; different domain; no keyword overlap |

**Assessment Method**:
1. Load refined_question text from wikilink
2. Identify core concepts and keywords in question
3. Analyze finding content for keyword presence (exact + semantic matches)
4. Assess relationship strength: direct/core (high) vs tangential/peripheral (low)
5. Assign score based on alignment strength

**Examples**:
- **Refined Question**: "How are mid-sized German machinery manufacturers improving customer retention through digital customer experience strategies?"
- **High Score (0.85)**: Finding about B2B self-service portals for German manufacturing SMEs with customer retention data
- **Moderate Score (0.55)**: Finding about general digital transformation in German industry mentioning customer platforms
- **Low Score (0.25)**: Finding about manufacturing automation without customer experience focus

### Entity Relevance Sub-Dimension (v2.1)

**Applies only when**: `ENTITY_SPECIFIC == true` (question targets a specific named entity)

For entity-specific questions, Topical Relevance is split into two sub-dimensions:

| Sub-Dimension | Weight | Assessment Method |
|---------------|--------|-------------------|
| Question Alignment | 60% | Semantic match to question keywords and concepts |
| Entity Relevance | 40% | Does content specifically address the named entity? |

**Entity Relevance Scoring**:

| Score | Criteria | Example |
|-------|----------|---------|
| 1.00 | Entity named + specific offerings/capabilities described | "DB Systel offers Zero Trust services including..." |
| 0.75 | Entity named + general category statements | "DB Systel is among providers offering security solutions" |
| 0.50 | Entity implied via context (parent company, subsidiary) | "Deutsche Bahn's IT subsidiary provides..." |
| 0.25 | Industry mentioned but entity absent | "German IT service providers typically offer..." |
| 0.00 | No entity connection - generic content only | "Zero Trust architecture compares to perimeter..." |

**Combined Topical Relevance Calculation** (for entity-specific questions):

```text
topical_relevance = (question_alignment × 0.60) + (entity_relevance × 0.40)
```

**Example - Generic Finding for Entity-Specific Question**:

- **Question**: "Welche Zero-Trust-Architektur-Services bietet DB Systel?"
- **Finding Content**: Generic "Zero Trust vs Perimeter Security" comparison (no DB Systel mention)
- **Scores**:
  - question_alignment: 0.72 (Zero Trust keywords match)
  - entity_relevance: 0.00 (no DB Systel mentioned)
  - **Combined topical_relevance**: (0.72 × 0.60) + (0.00 × 0.40) = **0.43**
- **Result**: Finding likely fails quality gate despite strong keyword alignment

**Entity Knowledge Gap Flag**:

When `entity_relevance < 0.50` but composite score still passes (≥0.50):

- Set `entity_knowledge_gap: true` in finding metadata
- Prepend disclaimer to Content section:

```markdown
> ⚠️ **Entity Coverage Gap**: This finding provides general context for {topic}
> but does not contain specific information about {PRIMARY_ENTITY}'s
> offerings or capabilities.
```

**Rationale**: Entity-specific questions ask "What does [Entity] offer?" Generic industry content doesn't answer this question, even if topically aligned.

---

### Dimension 2: Content Completeness (Weight: 25%)

**Definition**: Substantive information depth measured by word count, section presence, trend richness, and methodology documentation.

**Scoring Criteria**:

| Score Range | Description | Requirements |
|-------------|-------------|--------------|
| 0.90-1.00 | Comprehensive | 250+ words, 4+ trends, methodology detailed, data points rich |
| 0.70-0.89 | Substantive | 200-249 words, 3-4 trends, methodology present, some data points |
| 0.50-0.69 | Adequate | 150-199 words, 3 trends, methodology mentioned, minimal data |
| 0.30-0.49 | Sparse | 75-149 words, 1-2 trends, no methodology, vague content |
| 0.00-0.29 | Minimal | <75 words, 0-1 trends, no methodology, generic summary |

**Assessment Components** (additive scoring):

**Content Word Count** (40% of dimension score):
- 250+ words: 1.0
- 200-249 words: 0.85
- 150-199 words: 0.70
- 100-149 words: 0.50
- 75-99 words: 0.30
- <75 words: 0.10

**Key Trends Count** (30% of dimension score):
- 5+ bullets: 1.0
- 4 bullets: 0.85
- 3 bullets: 0.70
- 2 bullets: 0.40
- 1 bullet: 0.20
- 0 bullets: 0.0

**Methodology Presence** (20% of dimension score):
- Detailed methodology (methods + sample + timeframe): 1.0
- Basic methodology (2 of 3 elements): 0.70
- Mentioned (1 of 3 elements): 0.40
- Absent: 0.0

**Data Points Richness** (10% of dimension score):
- 5+ specific data points: 1.0
- 3-4 data points: 0.75
- 1-2 data points: 0.50
- No specific data: 0.0

**Calculation Example**:
```
Content: 185 words → 0.70
Trends: 3 bullets → 0.70
Methodology: Basic (2/3) → 0.70
Data Points: 2 specific → 0.50

Dimension Score = (0.70 × 0.40) + (0.70 × 0.30) + (0.70 × 0.20) + (0.50 × 0.10)
                = 0.28 + 0.21 + 0.14 + 0.05
                = 0.68 (Adequate)
```

---

### Dimension 3: Source Reliability (Weight: 15%)

**Definition**: Authority and credibility of the source publication, aligned with source-creator's 4-tier reliability system.

**Scoring Criteria** (4-Tier System):

| Tier | Score | Source Types | Examples |
|------|-------|-------------|----------|
| Tier 1 (Authoritative) | 1.00 | Academic journals, peer-reviewed publications, official government reports, established research institutions | Nature, Science, Fraunhofer Institute reports, government statistical offices |
| Tier 2 (Established) | 0.75 | Major industry publications, professional associations, reputable consultancies, quality news outlets | McKinsey, Harvard Business Review, VDMA publications, Financial Times |
| Tier 3 (General) | 0.50 | Standard news sites, corporate blogs with editorial standards, trade publications | Industry news sites, company research blogs, trade magazines |
| Tier 4 (Uncertain) | 0.25 | Personal blogs, uncited sources, marketing content, unclear authorship | Individual blogs, promotional content, anonymous sources |

**Assessment Method**:
1. Extract domain from source_url
2. Identify publication type (academic, industry, news, blog)
3. Check for authority signals:
   - Institutional affiliation (.edu, .gov, research institute)
   - Editorial standards (peer review, fact-checking)
   - Author credentials (expertise, reputation)
   - Publication reputation (established vs unknown)
4. Map to tier based on publication type + authority signals
5. Assign tier score

**Domain Analysis Heuristics**:
- `.edu`, `.gov`, `fraunhofer.de`, `mpg.de` → Likely Tier 1
- `mckinsey.com`, `harvard.edu`, `vdma.org` → Likely Tier 2
- `*.com` news sites, trade publications → Likely Tier 3
- Personal domains, promotional content → Likely Tier 4

**Note**: This scoring aligns with source-creator's reliability tier system for consistency across the research workflow.

---

### Dimension 4: Evidentiary Value (Weight: 10%)

**Definition**: Research utility measured by specific data points, methodology notes, and citeable trends.

**Scoring Criteria**:

| Score Range | Description | Indicators |
|-------------|-------------|------------|
| 0.90-1.00 | High Evidence | 5+ data points, detailed methodology, multiple citeable trends, statistical measures |
| 0.70-0.89 | Good Evidence | 3-4 data points, basic methodology, some citeable trends, specific claims |
| 0.50-0.69 | Moderate Evidence | 1-2 data points, methodology mentioned, few citeable trends |
| 0.30-0.49 | Weak Evidence | Vague claims, no specific data, generic statements |
| 0.00-0.29 | No Evidence | Purely descriptive, no data, no methodology, unciteable |

**Evidence Types** (cumulative assessment):

**Specific Data Points**:
- Statistics: "73% of German SMEs", "€2.4 billion investment"
- Dates/Timeframes: "2023-2024 study", "Q4 2024 data"
- Measurements: "ROI of 233%", "15-month implementation timeline"
- Quantities: "1,247 companies surveyed", "85% adoption rate"

**Methodology Notes**:
- Research methods: "Quantitative survey", "Qualitative interviews", "Case study analysis"
- Sample characteristics: "N=1,247 German manufacturing SMEs"
- Geographic/temporal scope: "Germany 2023-2024", "Longitudinal 5-year study"

**Citeable Trends**:
- Specific findings: "Self-service portals reduce support costs by 40%"
- Expert quotes: "According to Dr. Schmidt, '...'"
- Comparative analysis: "Companies with digital twins show 25% higher productivity"

**Assessment Method**:
1. Count specific data points (statistics, dates, measurements)
2. Check for methodology documentation (methods, sample, scope)
3. Identify citeable trends (specific claims vs generic statements)
4. Assign score based on evidence richness

---

### Dimension 5: Source Freshness (Weight: 15%) - NEW in v2.0

**Definition**: Recency of the source relative to the PICOT Timeframe requirements. Prevents outdated sources from contaminating research on current trends.

**Rationale**: A 2021 blog post about "employer branding" or "Gen Z expectations" is useless for 2025-2027 trend research. WebSearch ranks by relevance, not recency - this dimension compensates.

**Scoring Criteria**:

| Score Range | Source Age | Planning Horizon | Description |
|-------------|------------|------------------|-------------|
| 1.00 | < 12 months | Any | Very recent - ideal for volatile topics |
| 0.85 | 12-18 months | Any | Recent - acceptable for most research |
| 0.70 | 18-24 months | Act/Plan | Acceptable for Act (0-2yr) and Plan (2-5yr) horizons |
| 0.50 | 24-36 months | Plan/Observe | Marginal - only acceptable for Plan/Observe horizons |
| 0.25 | 36-48 months | Observe only | Old - only for foundational/Observe research |
| 0.00 | > 48 months | None | Too old - automatically rejected in Phase 4.2.5 |

**Volatile Topic Adjustment**:

For volatile topics (employer branding, Gen Z, social media, AI, regulations), apply stricter thresholds:

| Topic Category | Max Age for Score 0.70+ | Max Age for Score 0.50+ |
|----------------|-------------------------|-------------------------|
| Employer Branding, Gen Z | 12 months | 18 months |
| AI, Machine Learning | 12 months | 18 months |
| Regulations (CSRD, LkSG, AI Act) | 6 months | 12 months |
| Market Trends | 18 months | 24 months |
| Strategy, Best Practices | 24 months | 36 months |
| Foundational Research | No limit | No limit |

**Assessment Method**:

1. Extract source date from URL pattern (e.g., `/2021/12/01/`) or snippet metadata
2. Calculate source age in months: `(current_date - source_date)`
3. Load PICOT Timeframe from query batch to determine planning horizon
4. Check if topic is volatile (keyword detection)
5. Apply scoring based on age + horizon + volatility

**Date Extraction Sources** (priority order):

1. URL date pattern: `/YYYY/MM/DD/`, `/YYYY-MM-DD/`, `/YYYYMMDD`
2. Snippet metadata: "Published:", "Updated:", "Veröffentlicht:"
3. Snippet year reference: Month + Year patterns
4. Unknown: Assign score 0.50 with `unknown_date_flag=true`

**Integration with Phase 4.2.5**:

This dimension uses data already extracted in Phase 4.2.5 (Source Date Extraction and Freshness Gate). Sources exceeding `max_source_age_months` are rejected BEFORE quality scoring. This dimension scores sources that passed the gate but may still be older than ideal.

**Example Calculations**:

| Source Date | Current Date | Age | Horizon | Volatile | Score |
|-------------|--------------|-----|---------|----------|-------|
| 2024-06-15 | 2025-12-01 | 18mo | Act | No | 0.70 |
| 2024-06-15 | 2025-12-01 | 18mo | Act | Yes (Gen Z) | 0.50 |
| 2023-01-01 | 2025-12-01 | 35mo | Plan | No | 0.50 |
| 2021-12-01 | 2025-12-01 | 48mo | Act | Yes | **REJECTED** |

---

## Scoring Methodology

### Composite Score Calculation

**Formula (v2.0)**:

```text
composite_score = (topical_relevance × 0.35) +
                  (content_completeness × 0.25) +
                  (source_reliability × 0.15) +
                  (evidentiary_value × 0.10) +
                  (source_freshness × 0.15)
```

**Weights Rationale (v2.0)**:

- **Topical Relevance (35%)**: Most critical - irrelevant findings have no research value regardless of other qualities
- **Content Completeness (25%)**: Substantive depth required for synthesis
- **Source Freshness (15%)**: NEW - ensures sources match PICOT Timeframe requirements
- **Source Reliability (15%)**: Important but findings from Tier 3 sources can still be valuable if highly relevant
- **Evidentiary Value (10%)**: Bonus for evidence-rich findings, but not all findings require heavy data

**v1.0 → v2.0 Weight Changes**:

| Dimension | v1.0 Weight | v2.0 Weight | Change |
|-----------|-------------|-------------|--------|
| Topical Relevance | 40% | 35% | -5% |
| Content Completeness | 30% | 25% | -5% |
| Source Reliability | 20% | 15% | -5% |
| Evidentiary Value | 10% | 10% | 0% |
| **Source Freshness** | N/A | **15%** | **NEW** |

### Calculation Example

**Finding**: "B2B Self-Service Portals for Manufacturing in Germany"

**Source Context**: Published June 2024, PICOT Timeframe "Act (2025-2027)", non-volatile topic

**Dimension Scores (v2.0)**:

1. Topical Relevance: 0.85 (high alignment with research question)
2. Content Completeness: 0.68 (185 words, 3 trends, basic methodology, 2 data points)
3. Source Reliability: 0.75 (Tier 2 - industry publication)
4. Evidentiary Value: 0.60 (2 data points, methodology mentioned, moderate citeability)
5. **Source Freshness: 0.85** (18 months old, Act horizon, non-volatile)

**Composite Calculation (v2.0)**:

```text
composite_score = (0.85 × 0.35) + (0.68 × 0.25) + (0.75 × 0.15) + (0.60 × 0.10) + (0.85 × 0.15)
                = 0.2975 + 0.17 + 0.1125 + 0.06 + 0.1275
                = 0.7675
                = 0.77 (rounded)
```

**Result**: PASS (0.77 ≥ 0.50 threshold)

---

## Quality Thresholds

### Minimum Composite Score: 0.50

**Rationale**:
- Filters bottom 20-40% of findings based on pilot testing
- Balances precision (avoiding false positives) with recall (capturing useful findings)
- Tunable based on rejection rate monitoring

**Threshold Decision Logic**:

```
IF composite_score >= 0.50:
  quality_status = "PASS"
  → Create finding with quality metadata
  → Proceed to entity creation
ELSE:
  quality_status = "FAIL"
  → Skip finding creation
  → Log rejection to .rejected-findings.json
  → Continue to next search result
```

### Dimension-Specific Minimums (Recommended)

While the composite score is the primary filter, these dimension minimums ensure balanced quality:

- **Topical Relevance**: Minimum 0.30 (even if composite ≥ 0.50, findings with relevance < 0.30 should be reviewed)
- **Content Completeness**: Minimum 0.40 (avoid creating findings with <100 words even if highly relevant)
- **Source Reliability**: No strict minimum (Tier 4 sources acceptable if content excellent)
- **Evidentiary Value**: No strict minimum (not all findings require heavy data)

**Enhanced Decision Logic** (optional):
```
IF composite_score >= 0.50 AND topical_relevance >= 0.30 AND content_completeness >= 0.40:
  quality_status = "PASS"
ELSE:
  quality_status = "FAIL"
```

### Threshold Tuning

**Monitoring Metrics**:
1. **Rejection Rate**: Percentage of findings scoring < 0.50
2. **Average Quality Score**: Mean composite score for created findings
3. **Dimension Distribution**: Which dimensions most often cause rejection

**Tuning Guidelines**:
- **If rejection rate > 40%**: Consider lowering threshold to 0.45 or adjusting dimension weights
- **If rejection rate < 10%**: Consider raising threshold to 0.55 for higher quality bar
- **If specific dimension consistently low**: Adjust weight or scoring rubric for that dimension

**Recommendation**: Monitor for 2-3 research projects before tuning threshold.

---

## Comprehensive Finding Template

### Required 5-Section Structure

Every finding MUST include all 5 sections in this order.

**Language Template Reference:** Use section headers from `references/language-templates.md` section `04-findings` based on CONTENT_LANGUAGE.

```markdown
## {HEADER_CONTENT}
{Substantive paragraph - minimum 150 words}
{Include: specific trends, contextual information, key takeaways}
{Avoid: generic summaries, vague statements, unsupported claims}

## {HEADER_KEY_TRENDS}
- {Specific trend 1 with concrete details}
- {Specific trend 2 with measurable aspects}
- {Specific trend 3 with actionable information}
{Minimum 3 bullets, maximum 8 bullets}
{Each bullet must be specific and substantive (not generic)}

## {HEADER_METHODOLOGY}
{Research methodology if available: survey/interview/analysis/case study}
{Data points: sample sizes, timeframes, geographic scope, statistical measures}
{If no explicit methodology: describe information source type and context}
{Minimum 2-3 sentences}

## {HEADER_RELEVANCE_ASSESSMENT}
**Composite Score**: {0.00-1.00} | **Threshold**: 0.50 | **Status**: {PASS/FAIL}

**Dimension Scores:**
- Topical Relevance (40%): {score} - {brief rationale}
- Content Completeness (30%): {score} - {brief rationale}
- Source Reliability (20%): {score} - {brief rationale}
- Evidentiary Value (10%): {score} - {brief rationale}

**Overall Rationale**: {2-3 sentences explaining why this finding matters for the research question}

## {HEADER_SOURCE}
**URL**: {source_url}
**Source Entity**: Will be created in 07-sources/data/ by source-creator
**Backlink**: source_id will be populated after source creation
```

**Header Variable Mapping (04-findings):**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_CONTENT` | Content | Inhalt |
| `HEADER_KEY_TRENDS` | Key Trends | Kernerkenntnisse |
| `HEADER_METHODOLOGY` | Methodology & Data Points | Methodik & Datenpunkte |
| `HEADER_RELEVANCE_ASSESSMENT` | Relevance Assessment | Relevanz-Bewertung |
| `HEADER_SOURCE` | Source | Quelle |

### Section Requirements

**Content Section**:
- Minimum: 150 words
- Recommended: 200-300 words
- Must be substantive (not just URL description or title repetition)
- Should include context, trends, and key information from the source

**Key Trends Section**:
- Minimum: 3 bullet points
- Recommended: 4-6 bullet points
- Each bullet must be specific (avoid "The article discusses...")
- Focus on actionable takeaways, measurable findings, or novel information

**Methodology & Data Points Section**:
- Document research methods when available (survey, study, analysis)
- Include specific data points (sample sizes, dates, measurements)
- If no formal methodology: describe source type and information context
- Minimum 2-3 sentences

**Relevance Assessment Section**:
- Auto-generated from quality scoring
- Shows all 4 dimension scores with brief rationales
- Provides overall rationale for finding's research value

**Source Section**:
- Standard metadata (unchanged from existing pattern)
- Links to source entity (populated by source-creator)

---

## Validation Checkpoints

### Pre-Creation Validation (Phase 4.5)

Perform these checks BEFORE creating finding entity:

**Checkpoint 1: Calculate Quality Scores**
1. Topical Relevance: Load refined_question, analyze alignment → score 0.0-1.0
2. Content Completeness: Count words, trends, check methodology → score 0.0-1.0
3. Source Reliability: Analyze domain, map to tier → score 0.25/0.50/0.75/1.00
4. Evidentiary Value: Count data points, assess citeability → score 0.0-1.0

**Checkpoint 2: Compute Composite Score**
- Apply formula: `(rel × 0.40) + (comp × 0.30) + (reliability × 0.20) + (evidence × 0.10)`
- Result: 0.00-1.00

**Checkpoint 3: Apply Threshold Decision**
```
IF composite_score < 0.50:
  → FAIL: Skip creation, log rejection
ELSE:
  → PASS: Add quality metadata, proceed to entity creation
```

**Checkpoint 4: Validate Template Compliance**
- All 5 sections present
- Content ≥ 150 words
- Trends ≥ 3 bullets
- Methodology section non-empty
- Relevance Assessment auto-generated

**Checkpoint 5: Extend Metadata**
- Add quality_score, quality_dimensions, quality_status
- Add content_word_count, trends_count, has_methodology
- Preserve all existing metadata fields

### Rejection Logging

**Log Format** (.rejected-findings.json):
```json
{
  "rejected_findings": [
    {
      "timestamp": "2025-11-25T07:30:00Z",
      "source_url": "https://example.com/article",
      "refined_question_id": "[[02-refined-questions/data/question-digitale-wertetreiber-q4]]",
      "composite_score": 0.35,
      "quality_status": "FAIL",
      "dimension_scores": {
        "topical_relevance": 0.25,
        "content_completeness": 0.40,
        "source_reliability": 0.50,
        "evidentiary_value": 0.30
      },
      "rejection_reason": "Composite score 0.35 below 0.50 threshold",
      "content_preview": "First 200 characters of content..."
    }
  ]
}
```

**Purpose**:
- Track rejection patterns
- Identify systematic issues (e.g., specific query types produce low-quality results)
- Support threshold tuning decisions
- Provide rejection rate metrics

---

## Examples

### Example 1: Excellent Finding (Score: 0.87, PASS)

**Title**: "B2B Self-Service Portals for Manufacturing in Germany: Adoption Study 2024"

**Content** (312 words):
Self-Service-Portale in B2B enable German mid-sized manufacturing companies (Mittelstand) to provide 24/7 customer service access while significantly reducing operational costs. A 2024 study by the German Mechanical Engineering Industry Association (VDMA) surveyed 1,247 manufacturing SMEs and found that companies implementing B2B self-service portals achieved an average 40% reduction in customer support costs within 18 months of deployment. These portals are particularly relevant for machinery manufacturers and industrial equipment companies looking to improve customer satisfaction while managing service expenses.

The study reveals that successful implementations share common characteristics: seamless integration with existing ERP and CRM systems (cited by 87% of high-performing adopters), intuitive user experience design reducing training requirements (92% adoption rate among customer bases), and comprehensive change management programs addressing both customer and internal stakeholder concerns. German Mittelstand companies report that self-service portals not only reduce costs but also improve customer retention rates by an average of 15% due to improved accessibility and faster issue resolution.

Implementation challenges include initial integration complexity (reported by 68% of companies), customer adoption resistance among traditional manufacturing clients (42%), and ongoing content maintenance requirements (71%). However, companies that invested in robust change management and user experience design saw significantly better outcomes, with 89% reporting positive ROI within the first two years.

**Key Trends**:
- 40% average reduction in customer support costs within 18 months of portal deployment
- 1,247 German manufacturing SMEs surveyed in 2024 VDMA study
- 87% of successful adopters cite ERP/CRM integration as critical success factor
- 15% improvement in customer retention rates due to improved accessibility
- 89% of companies with strong change management report positive ROI within 2 years
- Traditional manufacturing clients show 42% adoption resistance requiring targeted change management

**Methodology & Data Points**:
- Research Method: Quantitative survey by German Mechanical Engineering Industry Association (VDMA)
- Sample: N=1,247 German manufacturing SMEs
- Timeframe: 2024 study covering implementation periods from 2022-2024
- Key Metrics: Cost reduction %, customer retention %, ROI timeline, adoption rates

**Relevance Assessment**:
**Composite Score**: 0.87 | **Threshold**: 0.50 | **Status**: PASS

**Dimension Scores**:
- Topical Relevance (40%): 0.95 - Direct answer to research question on German machinery manufacturer digital customer experience strategies
- Content Completeness (30%): 0.90 - Comprehensive content (312 words), 6 specific trends, detailed methodology, rich data points
- Source Reliability (20%): 0.75 - Tier 2 source (VDMA industry association publication)
- Evidentiary Value (10%): 0.85 - Multiple specific data points (40% cost reduction, 1,247 sample size, 15% retention improvement), detailed methodology

**Overall Rationale**: This finding directly addresses the research question about German machinery manufacturers improving customer retention through digital customer experience strategies. It provides specific, data-driven trends from a credible industry source with comprehensive methodology documentation, making it highly valuable for synthesis and analysis.

---

### Example 2: Acceptable Finding (Score: 0.63, PASS)

**Title**: "Digital Transformation in German Manufacturing Industry"

**Content** (178 words):
German manufacturing companies are increasingly adopting digital technologies to improve operational efficiency and customer engagement. Industry 4.0 initiatives have expanded beyond production automation to include customer-facing digital services, with many mid-sized companies (Mittelstand) investing in online platforms and self-service tools.

Recent trends show that digital customer experience has become a competitive differentiator in the machinery manufacturing sector. Companies are implementing various solutions including customer portals, remote monitoring systems, and digital service platforms. These investments aim to improve customer satisfaction while managing operational costs in an increasingly competitive global market.

The transformation requires significant change management efforts, as traditional manufacturing companies must adapt both their technical infrastructure and organizational culture to support digital customer interactions. Success depends on executive commitment, employee training, and careful selection of digital tools that align with customer needs and company capabilities.

**Key Trends**:
- German Mittelstand companies expanding Industry 4.0 from production to customer-facing services
- Digital customer experience becoming competitive differentiator in machinery sector
- Implementation requires change management across technical infrastructure and organizational culture

**Methodology & Data Points**:
- Information Type: Industry analysis article
- Geographic Scope: Germany, focus on machinery manufacturing sector
- Timeframe: Recent trends (no specific date range provided)

**Relevance Assessment**:
**Composite Score**: 0.63 | **Threshold**: 0.50 | **Status**: PASS

**Dimension Scores**:
- Topical Relevance (40%): 0.75 - Addresses digital customer experience in German manufacturing, though less specific than ideal
- Content Completeness (30%): 0.60 - Adequate content (178 words), minimum 3 trends, basic methodology, limited data points
- Source Reliability (20%): 0.50 - Tier 3 source (industry news publication with editorial standards)
- Evidentiary Value (10%): 0.40 - General claims, no specific statistics or sample sizes, limited citeability

**Overall Rationale**: This finding provides relevant context about digital transformation trends in German manufacturing with a focus on customer experience strategies. While less data-rich than ideal, it offers useful background on industry trends and implementation challenges that inform the research question.

---

### Example 3: Poor Finding (Score: 0.38, FAIL)

**Title**: "B2B Platform Innovation Success Factors"

**Content** (42 words):
Research study on B2B platform innovation success factors and strategies for German manufacturing SMEs.

**Key Trends**:
{Section missing}

**Methodology & Data Points**:
{Section missing}

**Relevance Assessment**:
**Composite Score**: 0.38 | **Threshold**: 0.50 | **Status**: FAIL

**Dimension Scores**:
- Topical Relevance (40%): 0.55 - Title suggests relevance to German manufacturing, but content too sparse to assess alignment
- Content Completeness (30%): 0.15 - Minimal content (42 words), no trends section, no methodology, essentially just title repetition
- Source Reliability (20%): 0.50 - Tier 3 source (general publication)
- Evidentiary Value (10%): 0.10 - No data points, no methodology, no specific claims, unciteable

**Overall Rationale**: This finding fails quality standards due to extremely sparse content (42 words vs 150 minimum), missing required sections (Key Trends, Methodology), and lack of substantive information. The composite score of 0.38 falls below the 0.50 threshold. This finding will not be created; instead, it will be logged to .rejected-findings.json for analysis.

**Rejection Reason**: "Content completeness critically low (0.15) with only 42 words and missing required sections. Composite score 0.38 below 0.50 threshold."

---

## Metadata Schema

### Extended Finding Frontmatter

Add these quality fields to existing finding metadata:

```yaml
---
# Existing fields (preserved)
dc:title: "Finding Title"
dc:date: "2025-11-25T07:30:00Z"
dc:type: "finding"
dc:source: "https://example.com/article"
tags: ["finding", "dimension/digitale-wertetreiber"]
batch_id: "[[03-query-batches/data/batch-digitale-wertetreiber-q4-b]]"
dimension_id: "[[01-research-dimensions/data/dimension-digitale-wertetreiber]]"
finding_uuid: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
source_url: "https://example.com/article"
refined_question_id: "[[02-refined-questions/data/question-digitale-wertetreiber-q4]]"
source_id: ""
search_success_level: 5
created_at: "2025-11-25T07:30:00Z"

# NEW: Quality assessment fields (v2.0)
quality_score: 0.77
quality_dimensions:
  topical_relevance: 0.85
  content_completeness: 0.68
  source_reliability: 0.75
  evidentiary_value: 0.60
  source_freshness: 0.85
quality_status: "PASS"
quality_assessed_at: "2025-12-01T07:30:00Z"
schema_version: "3.0"
quality_framework_version: "2.0"

# NEW: Freshness metadata (v2.0)
source_date: "2024-06-15"
source_age_months: 18
freshness_status: "PASS"
freshness_cutoff_months: 24
planning_horizon: "act"
is_volatile_topic: false

# Content metrics
content_word_count: 285
trends_count: 4
has_methodology: true
has_data_points: true
---
```

### Field Definitions

**quality_score** (float, 0.00-1.00):

- Composite quality score calculated from 5 dimensions (v2.0)
- Determines PASS (≥0.50) or FAIL (<0.50) status

**quality_dimensions** (object):

- topical_relevance (float, 0.00-1.00): Alignment with refined_question
- content_completeness (float, 0.00-1.00): Substantive depth score
- source_reliability (float, 0.25/0.50/0.75/1.00): Tier-based reliability
- evidentiary_value (float, 0.00-1.00): Research utility score
- source_freshness (float, 0.00-1.00): Recency relative to PICOT Timeframe (NEW in v2.0)
- entity_relevance (float, 0.00-1.00 or null): Entity mention score for entity-specific questions (NEW in v2.1)

**entity_specific** (boolean or null):
- True if question targets a specific named entity (company, product, organization)
- Null for non-entity-specific questions or legacy findings
- NEW in v2.1

**entity_knowledge_gap** (boolean or null):
- True if entity_relevance < 0.50 for entity-specific questions
- Indicates finding provides general context but lacks entity-specific information
- NEW in v2.1

**quality_status** (enum):
- "PASS": Composite score ≥ 0.50, finding created
- "FAIL": Composite score < 0.50, finding rejected (not created)

**quality_assessed_at** (timestamp):
- ISO 8601 timestamp of quality assessment

**schema_version** (string):
- "2.0" for findings with quality assessment
- "1.0" for legacy findings (backward compatibility)

**quality_framework_version** (string):
- Version of quality scoring methodology
- Enables future framework evolution

**content_word_count** (integer):
- Word count of Content section (excluding metadata and section headers)

**trends_count** (integer):
- Number of bullet points in Key Trends section

**has_methodology** (boolean):
- True if Methodology & Data Points section contains substantive content
- False if section missing or minimal

**has_data_points** (boolean):

- True if finding contains specific data (statistics, dates, measurements)
- False if purely descriptive without data

### Freshness Fields (NEW in v2.0)

**source_date** (string, ISO date or "unknown"):

- Extracted publication date from URL or snippet
- Format: "YYYY-MM-DD" or "unknown" if not extractable

**source_age_months** (integer or null):

- Calculated age of source in months
- null if source_date is "unknown"

**freshness_status** (enum):

- "PASS": Source within acceptable age threshold
- "WARN": Source date unknown for volatile topic
- "REJECT": Source too old (rejected in Phase 4.2.5, finding not created)

**freshness_cutoff_months** (integer):

- Maximum allowed source age derived from PICOT Timeframe
- Used for freshness gate decision

**planning_horizon** (enum):

- "act": Act horizon (0-2 years) - strictest freshness requirements
- "plan": Plan horizon (2-5 years) - moderate freshness
- "observe": Observe horizon (5+ years) - relaxed freshness

**is_volatile_topic** (boolean):

- True if topic detected as volatile (employer branding, Gen Z, AI, regulations)
- Triggers stricter freshness thresholds (halved max age)

### Backward Compatibility

**Handling Legacy Findings** (schema_version "1.0" or missing):

Downstream skills (fact-checker, synthesis) should treat missing quality fields as:
```yaml
quality_score: null
quality_status: "LEGACY"
quality_assessed_at: null
```

**Graceful Degradation Pattern**:
```
IF quality_score exists:
  USE quality_score for synthesis weighting
ELSE:
  TREAT as moderate quality (assume 0.60 score)
```

**Optional Migration**:
Users can re-assess legacy findings by:
1. Reading existing finding content
2. Applying quality assessment methodology
3. Adding quality metadata fields
4. Updating schema_version to "2.0"

**Note**: Migration is optional. Legacy findings remain valid without quality metadata.

---

## Appendix: Threshold Tuning Guide

### Monitoring Dashboard (Recommended Metrics)

Track these metrics after initial deployment:

1. **Rejection Rate**: `rejected_findings / (created_findings + rejected_findings)`
2. **Average Quality Score**: `mean(quality_score)` for created findings
3. **Dimension Distribution**: Percentage of findings failing each dimension minimum

### Tuning Decision Tree

```
IF rejection_rate > 50%:
  → Threshold too restrictive
  → RECOMMEND: Lower to 0.45 OR adjust dimension weights
  → INVESTIGATE: Which dimensions causing most rejections?

ELSE IF rejection_rate < 5%:
  → Threshold too permissive
  → RECOMMEND: Raise to 0.55 OR tighten dimension rubrics
  → INVESTIGATE: Are low-quality findings still being created?

ELSE IF 5% <= rejection_rate <= 50%:
  → Threshold appropriate
  → MONITOR: Track for 2-3 more projects before tuning
  → INVESTIGATE: Dimension-specific patterns

IF topical_relevance consistently < 0.30:
  → Query optimization issue (upstream problem)
  → RECOMMEND: Review Phase 1 query generation

IF content_completeness consistently < 0.40:
  → Source material quality issue
  → RECOMMEND: Review search result sources, adjust search strategies

IF source_reliability consistently Tier 4:
  → Source diversity issue
  → RECOMMEND: Broaden search to include more authoritative sources
```

### Example Threshold Adjustment

**Scenario**: After 3 research projects, rejection rate = 55%

**Analysis**:
- Average quality_score for PASS findings: 0.61
- 42% of rejections due to content_completeness < 0.40
- 28% due to topical_relevance < 0.50
- 30% due to composite score close to threshold (0.45-0.49)

**Recommendation**:
1. **Lower threshold to 0.45** (captures 30% near-threshold findings)
2. **Keep content_completeness minimum at 0.40** (maintains substantive depth requirement)
3. **Monitor for 2 more projects** to assess impact

**Expected Impact**:
- Rejection rate: 55% → 25-30%
- Average quality score for created findings: 0.61 → 0.57 (acceptable trade-off)

---

**End of Finding Quality Standards**

For implementation details, see:
- SKILL.md Phase 4.5 (quality checkpoint overview)
- references/workflows/phase-4-finding-extraction.md Step 4.5 (detailed validation workflow)
