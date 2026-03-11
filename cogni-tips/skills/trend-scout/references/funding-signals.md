# Funding & Investment Signal Queries

**Reference Checksum:** `sha256:trend-scout-funding-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: funding-signals.md | Checksum: trend-scout-funding-v1
```

---

## Overview

Funding signals (VC investments, M&A activity, Series rounds) provide **12-24 month lead time** over mainstream adoption signals. Investment concentration in specific technologies indicates commercial validation and future market growth.

**Strategic Value:** Where smart money flows today predicts market trends tomorrow.

---

## 1. Web Search Queries (No API Required)

Since Crunchbase and PitchBook require paid API access, use web search to extract funding signals from public sources.

### Query Templates

| Query # | Focus | Language | Template |
|---------|-------|----------|----------|
| F1 | VC funding (EN) | EN | `"{SUBSECTOR_EN}" startup funding investment 2025` |
| F2 | German startups | DE | `"{SUBSECTOR_DE}" Startup Finanzierung DACH 2025` |
| F3 | M&A activity | EN | `"{SUBSECTOR_EN}" acquisition merger 2025` |
| F4 | Growth signals | EN | `"{SUBSECTOR_EN}" Series A B funding announcement 2025` |

### DACH-Specific Funding Queries

| Query # | Focus | Template |
|---------|-------|----------|
| F5 | German VC | `"{SUBSECTOR_DE}" Venture Capital Deutschland 2025` |
| F6 | Austrian startups | `"{SUBSECTOR_DE}" Startup Österreich Finanzierung 2025` |
| F7 | Swiss innovation | `"{SUBSECTOR_EN}" Switzerland startup investment 2025` |

### Preferred Source Domains

Include these domains in search results for higher authority:

| Domain | Focus | Authority |
|--------|-------|-----------|
| techcrunch.com | Global tech funding | 3 |
| crunchbase.com/news | Funding announcements | 4 |
| deutsche-startups.de | German startup ecosystem | 3 |
| gruenderszene.de | DACH startups | 3 |
| venturebeat.com | Enterprise tech | 3 |
| eu-startups.com | European ecosystem | 3 |
| sifted.eu | European tech funding | 3 |
| handelsblatt.com | German business | 3 |

---

## 2. Signal Extraction

### What to Extract from Search Results

From each funding-related result, extract:

```yaml
funding_signal:
  signal_name: "{Company} raises {Amount} for {Technology}"
  keywords:
    - "{technology_focus}"
    - "{funding_stage}"  # seed, series-a, series-b, growth
    - "{investor_type}"  # vc, corporate, government
  source_url: "{article_url}"
  source_type: "funding"
  freshness_date: "{announcement_date}"
  authority_score: 3-4  # Based on source domain

  # Funding-specific metadata
  funding_details:
    company: "{company_name}"
    amount: "{funding_amount}"  # If available
    stage: "seed|series-a|series-b|series-c|growth|acquisition"
    lead_investor: "{investor_name}"  # If available
    technology_focus: "{technology_keywords}"
```

### Funding Stage to Horizon Mapping

| Funding Stage | Maturity | Horizon Mapping |
|---------------|----------|-----------------|
| Seed | Very early | OBSERVE (5+ years to mainstream) |
| Series A | Early | OBSERVE/PLAN (3-5 years) |
| Series B | Growth | PLAN (2-4 years) |
| Series C+ | Scale | PLAN/ACT (1-3 years) |
| Acquisition | Mature | ACT (validation of trend) |
| IPO | Mainstream | ACT (trend established) |

### Concentration Analysis

Look for patterns indicating trend strength:

| Pattern | Signal Strength | Interpretation |
|---------|-----------------|----------------|
| 5+ deals in same technology | HIGH | Strong VC consensus |
| 3-4 deals | MEDIUM | Emerging interest |
| 1-2 deals | LOW | Early exploration |
| Major corporate acquirer | HIGH | Strategic validation |
| Government funding | MEDIUM | Policy priority |

---

## 3. Authority Scoring

### Source Authority Matrix

| Source Type | Authority Score | Examples |
|-------------|-----------------|----------|
| Company press release | 4 | Official announcements |
| Crunchbase/PitchBook news | 4 | Funding databases |
| Major tech media | 3 | TechCrunch, VentureBeat, Sifted |
| Regional startup media | 3 | Deutsche-Startups, Gruenderszene |
| General business media | 3 | Handelsblatt, FAZ, Reuters |
| Blog posts | 2 | Individual analysis |
| Social media | 1 | LinkedIn, Twitter |

### Freshness Weighting

Funding signals lose relevance faster than other signals:

| Age | Weight | Rationale |
|-----|--------|-----------|
| 0-3 months | 1.0 | Current investment thesis |
| 3-6 months | 0.8 | Recent validation |
| 6-12 months | 0.5 | Still relevant |
| 12-18 months | 0.3 | Context only |
| 18+ months | 0.1 | Historical reference |

---

## 4. Leading Indicator Value

Funding signals are **leading indicators** with specific lead times:

| Signal Type | Lead Time | Use Case |
|-------------|-----------|----------|
| Seed concentration | 24-36 months | OBSERVE horizon |
| Series A surge | 18-24 months | OBSERVE/PLAN transition |
| Series B/C activity | 12-18 months | PLAN horizon |
| M&A activity | 6-12 months | ACT horizon validation |
| IPO filings | 3-6 months | Mainstream confirmation |

### Indicator Classification

```yaml
indicator_type: "leading"
indicator_lead_time: "12-24 months"
indicator_confidence: "medium"  # Funding is probabilistic
```

---

## 5. Subsector-Specific Queries

### Manufacturing / Industry 4.0

```text
"industrial automation" OR "smart factory" startup funding 2025
"manufacturing AI" OR "predictive maintenance" Series investment 2025
"Industrie 4.0" Startup Finanzierung Deutschland 2025
```

### Automotive

```text
"electric vehicle" OR "EV" startup funding 2025
"autonomous driving" OR "ADAS" Series A B investment 2025
"Elektromobilität" Startup Finanzierung Deutschland 2025
```

### Healthcare / Pharma

```text
"digital health" OR "healthtech" startup funding 2025
"AI drug discovery" OR "biotech AI" Series investment 2025
"Medizintechnik" OR "Digital Health" Startup DACH 2025
```

### Financial Services

```text
"fintech" OR "insurtech" startup funding 2025
"embedded finance" OR "open banking" Series investment 2025
"FinTech" Startup Finanzierung Deutschland 2025
```

### Energy / Utilities

```text
"cleantech" OR "energy storage" startup funding 2025
"renewable energy" OR "green hydrogen" Series investment 2025
"Energiewende" Startup Finanzierung Deutschland 2025
```

---

## 6. Integration with Phase 1

### Execution Timing

Execute funding queries after standard web searches:

```text
Phase 1 Search Sequence:
├── Steps 1-16: Standard bilingual web searches
├── Steps 17-20: DACH-specific searches (original)
├── Steps 21-24: DACH site-specific searches (expanded)
├── Steps 25-28: Funding signal queries (NEW)
├── Steps 29-32: Job market signal queries (NEW)
└── API queries: Academic, Patent, Regulatory
```

### Search Budget Impact

| Search Set | Original Count | New Count |
|------------|----------------|-----------|
| Standard web | 16 | 16 |
| DACH-specific | 4 | 8 |
| **Funding signals** | 0 | **4** |
| Job market | 0 | 4 |
| **Total** | 20 | **32** |

---

## 7. Error Handling

### Search Failure Fallback

```text
If funding search returns no results:
  → Log warning: "No funding signals found for {SUBSECTOR}"
  → Continue with other searches
  → Note in metadata: funding_signals_available = false

If all funding searches fail:
  → Log error: "Funding signal collection failed"
  → Proceed without funding signals
  → Reduces leading indicator coverage
```

### Quality Thresholds

| Metric | Minimum | Action if Below |
|--------|---------|-----------------|
| Funding signals extracted | 2 | Log warning |
| Authority score average | 2.5 | Flag low confidence |
| Freshness (avg age) | < 6 months | Weight reduction |

---

## 8. Sample Output

### Extracted Funding Signal

```yaml
funding_signal:
  signal_name: "Celonis raises $1B Series D for Process Mining AI"
  keywords: ["process-mining", "enterprise-ai", "automation"]
  source_url: "https://techcrunch.com/2024/06/15/celonis-series-d"
  source_type: "funding"
  freshness_date: "2024-06"
  authority_score: 3
  dimension: "digitale-wertetreiber"

  funding_details:
    company: "Celonis"
    amount: "$1,000,000,000"
    stage: "series-d"
    lead_investor: "Sequoia Capital"
    technology_focus: "process mining, enterprise AI, automation"

  indicator_classification:
    type: "leading"
    lead_time: "12-18 months"
    signal_strength: "high"  # Major round, established company
```

### Aggregated Funding Context

```json
{
  "funding_signals": {
    "total": 8,
    "by_stage": {
      "seed": 2,
      "series_a": 3,
      "series_b": 2,
      "acquisition": 1
    },
    "by_technology": {
      "ai-automation": 4,
      "iot-connectivity": 2,
      "sustainability": 2
    },
    "avg_authority": 3.2,
    "avg_freshness_months": 4.5
  }
}
```
