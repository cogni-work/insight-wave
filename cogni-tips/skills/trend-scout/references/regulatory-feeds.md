# Regulatory Pipeline Tracking

**Reference Checksum:** `sha256:trend-scout-regulatory-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: regulatory-feeds.md | Checksum: trend-scout-regulatory-v1
```

---

## Overview

This reference provides query templates for free regulatory APIs to track compliance-driving legislation. Regulatory signals are **leading indicators** for mandatory business changes and provide high-authority sources.

**Strategic Value:** Regulations create non-negotiable deadlines that drive industry transformation.

---

## 1. EUR-Lex (Primary - EU Law Database)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | eur-lex.europa.eu |
| **Cost** | Free |
| **Rate Limit** | Reasonable use policy |
| **Coverage** | Complete EU law (1952-present) |
| **Documentation** | eur-lex.europa.eu/content/help |

### Authentication

No authentication required for public API.

### Key Regulations to Track

| Regulation | CELEX ID | Status | Impact Sectors | Deadline |
|------------|----------|--------|----------------|----------|
| **AI Act** | 32024R1689 | In force | All (AI systems) | Aug 2025 (partial), Aug 2026 (full) |
| **Cyber Resilience Act** | 32024R2847 | In force | IoT, software | Dec 2027 |
| **CSRD** | 32022L2464 | In force | Large companies | 2024-2026 (phased) |
| **Digital Markets Act** | 32022R1925 | In force | Tech platforms | Ongoing |
| **Digital Services Act** | 32022R2065 | In force | Online services | Feb 2024 |
| **NIS2 Directive** | 32022L2555 | Implementation | Critical infrastructure | Oct 2024 |
| **Data Act** | 32023R2854 | In force | Data-heavy businesses | Sep 2025 |
| **DORA** | 32022R2554 | In force | Financial sector | Jan 2025 |
| **Ecodesign Regulation** | 32024R1781 | In force | Manufacturing | 2025+ |
| **Corporate Sustainability DD** | 32024L1760 | In force | Large companies | 2026-2029 |

### Query Templates

#### CELEX ID Lookup

```text
https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:{CELEX_ID}
```

#### Search API

```text
https://eur-lex.europa.eu/search.html?SUBDOM_INIT=ALL_ALL&DTS_SUBDOM=ALL_ALL&DTS_DOM=ALL&lang=en&type=advanced&qid={TIMESTAMP}&CASE_LAW_SUMMARY=false&FM_CODED=REG,DIR,DEC&DD_YEAR={YEAR}
```

#### WebFetch Query for Recent Regulations

```text
WebFetch URL: https://eur-lex.europa.eu/search.html?type=named&name=new-legislation&SUBDOM_INIT=ALL_ALL

Prompt: Extract titles and CELEX IDs of regulations from the past 6 months affecting {SUBSECTOR}. Note implementation deadlines.
```

### Subsector Regulation Mapping

| Subsector | Key Regulations | Query Terms |
|-----------|-----------------|-------------|
| automotive | AI Act, Cyber Resilience, Type Approval | `automotive OR vehicle OR motor` |
| machinery | Machinery Regulation, AI Act, CRA | `machinery OR industrial equipment` |
| pharmaceuticals | MDR, IVDR, GMP, Clinical Trials | `pharmaceutical OR medicinal OR clinical` |
| banking | DORA, PSD3, MiCA, AML | `payment OR banking OR financial` |
| energy-utilities | Renewable Energy Directive, EED | `energy OR electricity OR gas` |
| it-services | AI Act, DSA, DMA, Data Act | `digital OR data OR software` |
| healthcare | MDR, EHDS, AI Act (medical) | `medical device OR health data` |

### Response Parsing

EUR-Lex HTML pages require extraction of:

```yaml
regulation_signal:
  title: "{regulation_title}"
  celex_id: "{CELEX_NUMBER}"
  source_url: "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:{CELEX_ID}"
  status: "in_force|proposed|adopted"
  entry_into_force: "{date}"
  implementation_deadline: "{date}"
  affected_sectors: ["{sector1}", "{sector2}"]
```

### Authority Scoring

| Document Type | Authority Score |
|---------------|-----------------|
| Regulation (directly applicable) | 5 |
| Directive (requires transposition) | 5 |
| Implementing/Delegated acts | 4 |
| Commission guidance/FAQ | 3 |
| European Parliament resolution | 2 |

---

## 2. EUR-Lex RSS Feeds

### Available Feeds

| Feed | URL | Update Frequency |
|------|-----|------------------|
| New legislation | `https://eur-lex.europa.eu/EN/display-feed.rss?cellarOJ=true` | Daily |
| Court decisions | `https://eur-lex.europa.eu/search.html?...&RSS_FEED=true` | Daily |
| Commission proposals | Custom search with RSS | Weekly |

### Automated Monitoring

```text
# RSS feed for AI-related legislation
https://eur-lex.europa.eu/search.html?qid={ID}&FM_CODED=REG,DIR&DTS_SUBDOM=LEGISLATION&DB_TYPE_OF_ACT=regulation,directive&text=artificial%20intelligence&RSS_FEED=true
```

---

## 3. EU Law Tracker

### Overview

| Property | Value |
|----------|-------|
| **URL** | law-tracker.europa.eu |
| **Cost** | Free |
| **Coverage** | Legislative pipeline monitoring |
| **Value** | Track proposals before adoption |

### Query Templates

```text
WebFetch URL: https://law-tracker.europa.eu/

Prompt: Extract pending legislative proposals affecting {SUBSECTOR}. Note current stage (proposal, first reading, trilogue, adoption).
```

### Pipeline Stages

| Stage | Horizon Impact |
|-------|----------------|
| Commission proposal | OBSERVE (3-5 years to impact) |
| Parliament first reading | PLAN (2-3 years) |
| Council position | PLAN (1-2 years) |
| Trilogue | ACT (< 1 year to adoption) |
| Published in OJ | ACT (implementation begins) |

---

## 4. SEC EDGAR (US Public Filings)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | sec.gov/cgi-bin/browse-edgar |
| **Cost** | Free |
| **Rate Limit** | 10 requests/second |
| **Coverage** | US public company filings |
| **Documentation** | sec.gov/developer |

### Authentication

No authentication. Provide User-Agent header:

```text
User-Agent: YourName your-email@domain.com
```

### Key Filing Types

| Filing | Code | Value for Trend Detection |
|--------|------|---------------------------|
| Annual Report | 10-K | Strategy, risk factors |
| Quarterly Report | 10-Q | Recent developments |
| Current Report | 8-K | Material events |
| Proxy Statement | DEF 14A | Executive compensation, ESG |

### Query Templates

#### Company Search

```text
https://efts.sec.gov/LATEST/search-index?q={COMPANY_NAME}&dateRange=custom&startdt={START}&enddt={END}&forms=10-K,10-Q,8-K
```

#### Full-Text Search API

```text
https://efts.sec.gov/LATEST/search-index?q="{SEARCH_TERM}"&forms={FORM_TYPE}&dateRange=custom&startdt=2024-01-01
```

### Trend Detection Queries

| Topic | Query | Filing Types |
|-------|-------|--------------|
| AI investment | `"artificial intelligence" AND ("investment" OR "capital expenditure")` | 10-K, 10-Q |
| Cybersecurity risk | `"cybersecurity" AND "material risk"` | 10-K, 8-K |
| Sustainability | `"sustainability" OR "ESG" OR "climate"` | 10-K, DEF 14A |
| Digital transformation | `"digital transformation" AND "strategic initiative"` | 10-K |

### Response Parsing

```json
{
  "hits": {
    "hits": [
      {
        "_source": {
          "cik": "0000789019",
          "company": "Microsoft Corporation",
          "form": "10-K",
          "filed": "2024-06-27",
          "accession": "0001564590-24-123456"
        }
      }
    ]
  }
}
```

### Authority Scoring

| Filing Source | Authority Score |
|---------------|-----------------|
| 10-K (audited annual) | 5 |
| 10-Q (quarterly) | 4 |
| 8-K (material events) | 4 |
| DEF 14A (proxy) | 3 |

---

## 5. FDA Open Data (Healthcare/Pharma)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | open.fda.gov |
| **Cost** | Free |
| **Rate Limit** | 240 requests/minute (no key) |
| **Coverage** | Drugs, devices, food, tobacco |
| **Documentation** | open.fda.gov/apis |

### Key Endpoints

| Endpoint | Path | Use Case |
|----------|------|----------|
| Drug approvals | `/drug/drugsfda.json` | New drug trends |
| Device recalls | `/device/recall.json` | Safety signals |
| Device 510(k) | `/device/510k.json` | New device clearances |
| Adverse events | `/drug/event.json` | Safety signals |

### Query Templates

#### Recent Drug Approvals

```text
https://api.fda.gov/drug/drugsfda.json?search=submissions.submission_type:"ORIG"&limit=25&sort=submissions.submission_status_date:desc
```

#### Device Clearances

```text
https://api.fda.gov/device/510k.json?search=decision_date:[2024-01-01+TO+2024-12-31]&limit=25
```

#### Adverse Events (Signal Detection)

```text
https://api.fda.gov/drug/event.json?search=patient.drug.medicinalproduct:"{DRUG_NAME}"&limit=100
```

### Response Parsing

```json
{
  "results": [
    {
      "application_number": "NDA123456",
      "sponsor_name": "Pfizer Inc",
      "products": [
        {"brand_name": "Drug Name", "active_ingredients": [...]}
      ],
      "submissions": [
        {"submission_type": "ORIG", "submission_status_date": "2024-06-15"}
      ]
    }
  ]
}
```

### Authority Scoring

| FDA Decision | Authority Score |
|--------------|-----------------|
| NDA/BLA approval | 5 |
| 510(k) clearance | 4 |
| Breakthrough designation | 5 |
| Guidance document | 3 |

---

## 6. Regulations.gov (US Federal Rulemaking)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | api.regulations.gov |
| **Cost** | Free with API key |
| **Rate Limit** | 1000 requests/hour |
| **Coverage** | Federal Register rules |
| **Documentation** | regulations.gov/developers |

### Authentication

```bash
REGULATIONS_GOV_API_KEY=your-key-here

# Query parameter
?api_key=${REGULATIONS_GOV_API_KEY}
```

**Get Key:** https://api.data.gov/signup/ (free)

### Query Templates

#### Search Documents

```text
https://api.regulations.gov/v4/documents?filter[searchTerm]={SEARCH}&filter[postedDate][ge]=2024-01-01&api_key={KEY}
```

#### By Agency

```text
https://api.regulations.gov/v4/documents?filter[agencyId]={AGENCY}&filter[documentType]=Rule&api_key={KEY}
```

### Key Agencies by Subsector

| Subsector | Primary Agency | Secondary |
|-----------|----------------|-----------|
| automotive | NHTSA, EPA | DOT |
| pharmaceuticals | FDA | HHS |
| banking | SEC, CFPB | FDIC, OCC |
| energy-utilities | DOE, FERC | EPA |
| healthcare | FDA, CMS | HHS |
| it-services | FTC, FCC | NIST |

---

## 7. Integration with Phase 1

### Regulatory Search Phase (Phase 1.6)

Add after Patent API queries (Step 1.5):

```text
Step 1.6: Regulatory Pipeline Queries

For externe-effekte dimension, execute regulatory searches:

| Region | Primary API | Query Focus |
|--------|-------------|-------------|
| EU/DACH | EUR-Lex | Active regulations, upcoming deadlines |
| US | SEC EDGAR | Industry risk disclosures |
| Healthcare | FDA Open | Drug/device approvals |

Target: 2-4 regulatory signals per subsector
```

### Search Budget

| Search Type | Count | Total |
|-------------|-------|-------|
| Standard web (EN/DE) | 16 | 16 |
| DACH-specific | 4 | 20 |
| Academic API | 4 | 24 |
| Patent API | 4 | 28 |
| **Regulatory API** | **2-4** | **30-32** |

### Signal Extraction

From regulatory sources, extract:

```yaml
regulatory_signal:
  title: "{regulation_title}"
  source_url: "{official_url}"
  freshness_date: "{publication_or_update_date}"
  source_type: "regulatory"
  authority_score: 5  # Official government source
  status: "proposed|adopted|in_force"
  deadline: "{implementation_deadline}"
  affected_sectors: ["{sector1}", "{sector2}"]
  jurisdiction: "EU|US|DACH"
```

### Mapping to Horizons

| Regulatory Status | Recommended Horizon |
|-------------------|---------------------|
| Proposal/Draft | OBSERVE |
| Adopted (2+ years to deadline) | PLAN |
| Adopted (< 2 years to deadline) | ACT |
| In force (active enforcement) | ACT |

---

## 8. DACH-Specific Regulatory Sources

### German Federal Sources

| Source | URL | Focus |
|--------|-----|-------|
| BMWi | bmwk.de | Economic policy, digitalization |
| BSI | bsi.bund.de | Cybersecurity requirements |
| BaFin | bafin.de | Financial regulation |
| BfArM | bfarm.de | Drug/device approvals |

### Austrian Sources

| Source | URL | Focus |
|--------|-----|-------|
| FMA | fma.gv.at | Financial market authority |
| BASG | basg.gv.at | Medicines/devices |

### Swiss Sources

| Source | URL | Focus |
|--------|-----|-------|
| FINMA | finma.ch | Financial regulation |
| Swissmedic | swissmedic.ch | Pharma/devices |

### WebFetch Queries

```text
WebFetch URL: https://www.bsi.bund.de/EN/Topics/topics_node.html

Prompt: Extract recent cybersecurity requirements and guidelines affecting {SUBSECTOR} in Germany.
```

---

## 9. Regulatory Timeline Tracking

### Key 2025-2027 Deadlines

| Regulation | Milestone | Date | Impact |
|------------|-----------|------|--------|
| AI Act | Prohibited practices | Feb 2025 | All AI systems |
| AI Act | High-risk requirements | Aug 2026 | Automotive, medical, etc. |
| NIS2 | Member state transposition | Oct 2024 | Critical infrastructure |
| DORA | Application date | Jan 2025 | Financial sector |
| Cyber Resilience Act | Essential requirements | Dec 2027 | IoT, software |
| CSRD | First reports (large) | 2025 | Sustainability reporting |
| Data Act | Application | Sep 2025 | IoT data access |

### Calendar Alert Generation

For ACT horizon candidates, generate compliance calendar:

```yaml
compliance_alert:
  regulation: "EU AI Act"
  milestone: "High-risk system requirements apply"
  deadline: "2026-08-02"
  affected_systems: ["Automotive AI", "Medical devices", "HR screening"]
  action_required: "Complete conformity assessment, technical documentation"
```

---

## 10. Environment Variables

```bash
# Optional API keys
REGULATIONS_GOV_API_KEY=    # Free from api.data.gov
FDA_API_KEY=                # Optional, increases rate limit
SEC_USER_AGENT="YourCompany your-email@domain.com"
```

---

## 11. Error Handling

### API Failure Fallback

```text
If EUR-Lex unavailable:
  → Use cached regulation list
  → Flag as "regulatory_data_stale"

If FDA API fails:
  → Skip FDA signals
  → Log warning for pharma/healthcare subsectors

If SEC EDGAR fails:
  → Skip company filing analysis
  → Focus on EU regulatory sources
```

### Timeout Configuration

| API | Timeout | Retry |
|-----|---------|-------|
| EUR-Lex | 15s | 2x |
| SEC EDGAR | 10s | 2x |
| FDA Open | 10s | 2x |
| Regulations.gov | 10s | 2x |

