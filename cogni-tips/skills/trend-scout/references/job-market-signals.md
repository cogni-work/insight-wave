# Job Market Signal Queries

**Reference Checksum:** `sha256:trend-scout-jobs-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: job-market-signals.md | Checksum: trend-scout-jobs-v1
```

---

## Overview

Job posting data reveals emerging skills and roles **6-18 months before mainstream adoption**. New job titles, skills demand surges, and salary increases are leading indicators of technology and market trends.

**Strategic Value:** Companies hire for capabilities they need tomorrow, not yesterday.

---

## 1. Web Search Queries (No API Required)

Since Lightcast/Burning Glass require expensive enterprise subscriptions, use web search to extract job market signals from public sources.

### Query Templates

| Query # | Focus | Language | Template |
|---------|-------|----------|----------|
| J1 | Emerging skills (EN) | EN | `"{SUBSECTOR_EN}" emerging skills hiring trends 2025` |
| J2 | German jobs | DE | `"{SUBSECTOR_DE}" neue Berufsbilder Stellenangebote 2025` |
| J3 | Tech roles | EN | `"{SUBSECTOR_EN}" AI ML engineer hiring demand 2025` |
| J4 | DACH demand | DE | `"{SUBSECTOR_DE}" Fachkräfte Nachfrage Deutschland 2025` |

### DACH-Specific Job Market Queries

| Query # | Focus | Template |
|---------|-------|----------|
| J5 | Skills shortage | `"{SUBSECTOR_DE}" Fachkräftemangel neue Berufe 2025` |
| J6 | Salary trends | `"{SUBSECTOR_DE}" Gehalt Entwicklung IT 2025` |
| J7 | Remote work | `"{SUBSECTOR_EN}" remote hiring Germany Austria Switzerland 2025` |

### Preferred Source Domains

| Domain | Focus | Authority |
|--------|-------|-----------|
| linkedin.com/pulse | Professional trends | 3 |
| indeed.com/career-advice | Hiring trends | 3 |
| stepstone.de | German job market | 3 |
| hays.de | DACH recruitment | 3 |
| stackoverflow.com/jobs | Developer demand | 3 |
| glassdoor.com | Salary/demand data | 3 |
| heise.de | German tech jobs | 3 |
| computerwoche.de | IT job market | 3 |
| bitkom.org | Digital skills reports | 4 |
| ifo.de | Labor market research | 4 |

---

## 2. Signal Extraction

### What to Extract from Search Results

From each job market result, extract:

```yaml
job_signal:
  signal_name: "{Emerging Role/Skill} demand surge in {SUBSECTOR}"
  keywords:
    - "{skill_name}"
    - "{role_title}"
    - "{technology_area}"
  source_url: "{article_url}"
  source_type: "job-market"
  freshness_date: "{publication_date}"
  authority_score: 3  # Most job market sources

  # Job-specific metadata
  job_details:
    signal_type: "new_role|skill_demand|salary_surge|talent_shortage"
    role_or_skill: "{specific_role_or_skill}"
    demand_indicator: "high|medium|emerging"
    geography: "global|dach|germany|austria|switzerland"
    sector_relevance: "{how_it_applies_to_subsector}"
```

### Signal Types

| Signal Type | What It Indicates | Lead Time |
|-------------|-------------------|-----------|
| **New Role Title** | Emerging job function | 12-18 months |
| **Skills Demand Surge** | Technology adoption | 6-12 months |
| **Salary Increase** | Talent scarcity | 3-6 months |
| **Geographic Concentration** | Growth hub forming | 6-12 months |
| **Talent Shortage Report** | Market maturation | 3-6 months |

### Emerging Role Patterns to Watch

| Pattern | Example | Trend Indication |
|---------|---------|------------------|
| "AI + [Domain]" | AI Product Manager | AI integration maturing |
| "[Tech] Engineer" | MLOps Engineer | New infrastructure need |
| "[Process] Specialist" | Sustainability Specialist | Regulatory compliance |
| "Head of [New Area]" | Head of AI Ethics | Strategic priority |
| "[Tech] Architect" | Cloud Security Architect | Scaling infrastructure |

---

## 3. Authority Scoring

### Source Authority Matrix

| Source Type | Authority Score | Examples |
|-------------|-----------------|----------|
| Government labor statistics | 5 | BA (Bundesagentur), Eurostat |
| Industry associations | 4 | BITKOM, VDMA skills reports |
| Research institutes | 4 | ifo, IAB, Fraunhofer |
| Major recruitment firms | 3 | Hays, Robert Half, Korn Ferry |
| Job platforms | 3 | LinkedIn, Indeed, StepStone |
| Tech media | 3 | Heise, Computerwoche |
| Company job postings | 2 | Individual data point |
| Blog posts | 2 | Aggregated analysis |

### Freshness Weighting

Job market signals are time-sensitive:

| Age | Weight | Rationale |
|-----|--------|-----------|
| 0-3 months | 1.0 | Current hiring intent |
| 3-6 months | 0.8 | Recent market demand |
| 6-12 months | 0.5 | Trend confirmation |
| 12-18 months | 0.3 | Background context |
| 18+ months | 0.1 | Historical only |

---

## 4. Leading Indicator Value

Job market signals are **leading indicators**:

| Signal | Lead Time | Horizon Mapping |
|--------|-----------|-----------------|
| New job title appearing | 12-18 months | OBSERVE/PLAN |
| Skills demand surge (>50% YoY) | 6-12 months | PLAN |
| Salary premium (>20%) | 3-6 months | PLAN/ACT |
| Talent shortage declared | 3-6 months | ACT |
| Mass hiring announcements | 1-3 months | ACT |

### Indicator Classification

```yaml
indicator_type: "leading"
indicator_lead_time: "6-18 months"
indicator_confidence: "medium-high"  # Hiring intent is real
```

---

## 5. Subsector-Specific Queries

### Manufacturing / Industry 4.0

```text
"manufacturing" AI robotics engineer hiring 2025
"industrial IoT" skills demand Germany 2025
"Industrie 4.0" Fachkräfte Automatisierung 2025
"smart factory" new roles jobs 2025
```

### Automotive

```text
"automotive" software engineer hiring 2025
"electric vehicle" battery engineer demand 2025
"Automobil" Software Entwickler Elektromobilität 2025
"autonomous driving" ML engineer jobs 2025
```

### Healthcare / Pharma

```text
"healthcare" AI data scientist hiring 2025
"digital health" product manager demand 2025
"Medizintechnik" IT Fachkräfte Deutschland 2025
"clinical AI" specialist jobs 2025
```

### Financial Services

```text
"fintech" engineer hiring demand 2025
"banking" AI compliance officer jobs 2025
"Finanzdienstleistungen" IT Fachkräfte Deutschland 2025
"regtech" specialist demand 2025
```

### Energy / Utilities

```text
"renewable energy" engineer hiring 2025
"grid modernization" specialist demand 2025
"Energiewirtschaft" IT Fachkräfte Deutschland 2025
"hydrogen" engineer jobs 2025
```

---

## 6. Skill Taxonomy Mapping

### Technology Skills → TIPS Dimensions

| Skill Category | Dimension | Example Skills |
|----------------|-----------|----------------|
| AI/ML | digitale-wertetreiber, digitales-fundament | TensorFlow, PyTorch, MLOps |
| Cloud | digitales-fundament | AWS, Azure, GCP, Kubernetes |
| Security | digitales-fundament | Zero Trust, SIEM, SOC |
| Data | digitale-wertetreiber | Data Engineering, Analytics |
| IoT | digitale-wertetreiber | Edge Computing, MQTT |
| Sustainability | externe-effekte | ESG Reporting, LCA |
| Regulation | externe-effekte | Compliance, Audit |
| Leadership | neue-horizonte | Agile, Change Management |

### Role Titles → Signal Interpretation

| New Role Pattern | What It Signals |
|------------------|-----------------|
| "Chief [X] Officer" | Strategic priority elevation |
| "[X] Product Manager" | Productization of technology |
| "Senior [X] Engineer" | Scaling beyond pilots |
| "[X] Architect" | Infrastructure investment |
| "[X] Lead" | Team formation |
| "[X] Analyst" | Data-driven decisions |
| "[X] Specialist" | Deep expertise need |

---

## 7. Integration with Phase 1

### Execution Timing

Execute job market queries after funding signal queries:

```text
Phase 1 Search Sequence:
├── Steps 1-16: Standard bilingual web searches
├── Steps 17-20: DACH-specific searches (original)
├── Steps 21-24: DACH site-specific searches (expanded)
├── Steps 25-28: Funding signal queries
├── Steps 29-32: Job market signal queries (NEW)
└── API queries: Academic, Patent, Regulatory
```

### Search Budget Impact

| Search Set | Count |
|------------|-------|
| Standard web | 16 |
| DACH-specific | 8 |
| Funding signals | 4 |
| **Job market** | **4** |
| **Total** | **32** |

---

## 8. Error Handling

### Search Failure Fallback

```text
If job market search returns no results:
  → Log warning: "No job market signals found for {SUBSECTOR}"
  → Continue with other searches
  → Note in metadata: job_signals_available = false

If all job searches fail:
  → Log error: "Job market signal collection failed"
  → Proceed without job signals
  → Reduces leading indicator coverage
```

### Quality Thresholds

| Metric | Minimum | Action if Below |
|--------|---------|-----------------|
| Job signals extracted | 2 | Log warning |
| Authority score average | 2.5 | Flag low confidence |
| Freshness (avg age) | < 6 months | Weight reduction |

---

## 9. Sample Output

### Extracted Job Market Signal

```yaml
job_signal:
  signal_name: "MLOps Engineer demand surge in Manufacturing"
  keywords: ["mlops", "manufacturing-ai", "industrialization"]
  source_url: "https://www.linkedin.com/pulse/mlops-manufacturing-2025"
  source_type: "job-market"
  freshness_date: "2024-11"
  authority_score: 3
  dimension: "digitales-fundament"

  job_details:
    signal_type: "skill_demand"
    role_or_skill: "MLOps Engineer"
    demand_indicator: "high"
    geography: "dach"
    sector_relevance: "AI model deployment for predictive maintenance"

  indicator_classification:
    type: "leading"
    lead_time: "6-12 months"
    signal_strength: "medium"
```

### Aggregated Job Market Context

```json
{
  "job_signals": {
    "total": 6,
    "by_type": {
      "new_role": 2,
      "skill_demand": 3,
      "salary_surge": 1
    },
    "by_skill_category": {
      "ai_ml": 3,
      "cloud": 1,
      "sustainability": 2
    },
    "by_geography": {
      "dach": 4,
      "global": 2
    },
    "avg_authority": 3.0,
    "avg_freshness_months": 3.5
  }
}
```

---

## 10. Cross-Reference with Other Signals

### Triangulation Patterns

| Funding Signal | + Job Signal | = Interpretation |
|----------------|--------------|------------------|
| Series B in AI | MLOps Engineer demand | AI moving to production |
| Cleantech seed surge | Sustainability roles | Green tech maturation |
| Fintech acquisitions | Compliance hiring | Regulatory consolidation |

### Confidence Boost

When job signals align with other leading indicators:

```yaml
triangulation:
  sources: ["funding", "job-market", "patent"]
  agreement: true
  confidence_boost: +0.15
  final_confidence_tier: "high"
```
