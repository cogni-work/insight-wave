# Academic Publication API Queries

**Reference Checksum:** `sha256:trend-scout-academic-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: academic-api-queries.md | Checksum: trend-scout-academic-v1
```

---

## Overview

This reference provides query templates for free academic publication APIs to enhance trend detection with research-backed signals. Academic sources excel for OBSERVE horizon (5+ years) predictions and provide high authority scores.

**Lead Time Advantage:** Academic papers typically precede mainstream adoption by 3-7 years.

---

## 1. OpenAlex (Primary Source)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | api.openalex.org |
| **Cost** | Free, unlimited |
| **Rate Limit** | None (polite pool: add email) |
| **Coverage** | 250M+ works, 100K+ journals |
| **Documentation** | docs.openalex.org |

### Authentication

No API key required. Add email for polite pool access:

```text
?mailto=your-email@domain.com
```

### Query Templates

#### Basic Concept Search

```text
https://api.openalex.org/works?filter=concepts.display_name.search:{CONCEPT}&filter=publication_year:{YEAR}&per-page=25&sort=cited_by_count:desc
```

#### Subsector-Specific Queries

| Subsector | Query Filter | Example Concepts |
|-----------|--------------|------------------|
| automotive | `concepts.display_name.search:electric vehicle OR autonomous driving` | Electric vehicle, Autonomous systems |
| machinery | `concepts.display_name.search:industrial automation OR smart manufacturing` | Industry 4.0, Robotics |
| pharmaceuticals | `concepts.display_name.search:drug discovery OR precision medicine` | Machine learning drug discovery |
| banking | `concepts.display_name.search:fintech OR digital banking` | Blockchain, Decentralized finance |
| renewable-energy | `concepts.display_name.search:solar energy OR battery storage` | Energy storage, Green hydrogen |
| it-services | `concepts.display_name.search:cloud computing OR cybersecurity` | AI operations, Zero trust |

#### Dimension-Specific Queries

| Dimension | Focus Concepts | Query Modifier |
|-----------|----------------|----------------|
| externe-effekte | Policy, Regulation, Market analysis | `concepts.display_name.search:policy OR regulation` |
| neue-horizonte | Business model, Innovation, Market opportunity | `concepts.display_name.search:business model innovation` |
| digitale-wertetreiber | Customer experience, Operational excellence | `concepts.display_name.search:digital transformation` |
| digitales-fundament | Infrastructure, Security, Data management | `concepts.display_name.search:cybersecurity OR data infrastructure` |

#### High-Cited Recent Works

```text
https://api.openalex.org/works?filter=concepts.display_name.search:{SUBSECTOR}&filter=publication_year:{PREVIOUS_YEAR}-{CURRENT_YEAR}&filter=cited_by_count:>10&per-page=25&sort=publication_date:desc
```

### Response Parsing

Extract these fields for signal creation:

```json
{
  "title": "...",
  "publication_date": "2024-06-15",
  "doi": "10.1234/...",
  "cited_by_count": 42,
  "concepts": [
    {"display_name": "Artificial Intelligence", "score": 0.92}
  ],
  "authorships": [
    {"author": {"display_name": "..."}, "institutions": [...]}
  ]
}
```

### Authority Scoring

| Indicator | Authority Score |
|-----------|-----------------|
| cited_by_count > 50 | 5 |
| cited_by_count 20-50 | 4 |
| cited_by_count 5-20 | 3 |
| cited_by_count < 5 | 2 |
| Preprint (no DOI) | 2 |

---

## 2. Semantic Scholar

### API Overview

| Property | Value |
|----------|-------|
| **URL** | api.semanticscholar.org |
| **Cost** | Free with API key |
| **Rate Limit** | 100 requests / 5 minutes |
| **Coverage** | 200M+ papers |
| **Documentation** | api.semanticscholar.org/api-docs |

### Authentication

```bash
# Environment variable
SEMANTIC_SCHOLAR_API_KEY=your-key-here

# Request header
x-api-key: ${SEMANTIC_SCHOLAR_API_KEY}
```

**Get API Key:** https://www.semanticscholar.org/product/api (free registration)

### Query Templates

#### Paper Search

```text
GET https://api.semanticscholar.org/graph/v1/paper/search?query={QUERY}&fields=title,year,citationCount,abstract,fieldsOfStudy&limit=25
```

#### Bulk Paper Lookup

```text
POST https://api.semanticscholar.org/graph/v1/paper/batch
{
  "ids": ["DOI:10.1234/...", "DOI:10.5678/..."],
  "fields": "title,year,citationCount,abstract"
}
```

#### Subsector Query Examples

| Subsector | Query String |
|-----------|--------------|
| automotive | `electric vehicle battery management OR autonomous driving safety` |
| machinery | `smart factory predictive maintenance OR industrial IoT` |
| pharmaceuticals | `AI drug discovery OR computational biology` |
| banking | `blockchain financial services OR digital payment systems` |
| healthcare | `AI medical diagnosis OR telemedicine platform` |

### Response Parsing

```json
{
  "data": [
    {
      "paperId": "...",
      "title": "...",
      "year": 2024,
      "citationCount": 35,
      "abstract": "...",
      "fieldsOfStudy": ["Computer Science", "Engineering"]
    }
  ]
}
```

### Rate Limit Handling

```text
If 429 Too Many Requests:
  - Wait 60 seconds
  - Reduce batch size
  - Fall back to OpenAlex
```

---

## 3. arXiv (Preprints)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | export.arxiv.org/api |
| **Cost** | Free |
| **Rate Limit** | ~3 req/sec (be polite) |
| **Coverage** | 2.4M+ papers |
| **Best For** | CS, Physics, Math, Economics preprints |

### Query Templates

#### Basic Search

```text
http://export.arxiv.org/api/query?search_query=all:{QUERY}&start=0&max_results=25&sortBy=submittedDate&sortOrder=descending
```

#### Category-Specific Searches

| Category | arXiv Code | Focus |
|----------|------------|-------|
| AI/ML | cs.AI, cs.LG | Machine learning, neural networks |
| Robotics | cs.RO | Autonomous systems, manipulation |
| Systems | cs.DC | Distributed computing, cloud |
| Crypto | cs.CR | Security, cryptography |
| Economics | econ.GN | Economic modeling |
| Quantitative Finance | q-fin.* | Financial markets |

#### Category Filter

```text
http://export.arxiv.org/api/query?search_query=cat:cs.AI+AND+all:{SUBSECTOR_TERM}&max_results=25
```

### Response Parsing (XML)

```xml
<entry>
  <title>Paper Title</title>
  <published>2024-12-10T00:00:00Z</published>
  <summary>Abstract text...</summary>
  <author><name>Author Name</name></author>
  <link href="http://arxiv.org/abs/2412.12345"/>
  <category term="cs.AI"/>
</entry>
```

### Authority Scoring

| Indicator | Authority Score |
|-----------|-----------------|
| Published in top venue after arXiv | 5 |
| High download count (visible on page) | 4 |
| Multiple revisions | 3 |
| Initial submission | 2 |

---

## 4. PubMed E-utilities

### API Overview

| Property | Value |
|----------|-------|
| **URL** | eutils.ncbi.nlm.nih.gov |
| **Cost** | Free with API key |
| **Rate Limit** | 10 req/sec with key, 3/sec without |
| **Coverage** | 35M+ biomedical articles |
| **Best For** | Pharma, Healthcare, Biotech subsectors |

### Authentication

```bash
# Environment variable
PUBMED_API_KEY=your-key-here

# Query parameter
&api_key=${PUBMED_API_KEY}
```

**Get API Key:** https://www.ncbi.nlm.nih.gov/account/ (free registration)

### Query Templates

#### ESearch (Get IDs)

```text
https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term={QUERY}&retmax=25&sort=date&retmode=json&api_key={KEY}
```

#### EFetch (Get Details)

```text
https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id={IDS}&retmode=xml&api_key={KEY}
```

#### Healthcare/Pharma Query Examples

| Topic | Query String |
|-------|--------------|
| Drug discovery | `("artificial intelligence"[Title/Abstract]) AND ("drug discovery"[Title/Abstract])` |
| Medical devices | `("digital health"[MeSH Terms]) AND ("medical device"[Title/Abstract])` |
| Telemedicine | `("telemedicine"[MeSH Terms]) AND ("clinical trial"[Publication Type])` |
| Personalized medicine | `("precision medicine"[MeSH Terms]) AND ("biomarker"[Title/Abstract])` |

### Response Parsing

```json
{
  "esearchresult": {
    "count": "150",
    "idlist": ["39123456", "39123457", "..."]
  }
}
```

### Authority Scoring

| Indicator | Authority Score |
|-----------|-----------------|
| Systematic review / Meta-analysis | 5 |
| Clinical trial | 5 |
| Peer-reviewed journal article | 4 |
| Case study | 3 |
| Commentary / Letter | 2 |

---

## 5. Integration with Phase 1

### Academic Search Phase (Phase 1.4)

Add after DACH-specific searches (Step 1.2b):

```text
Step 1.4: Academic API Queries

For each dimension, execute 1-2 academic searches:

| Dimension | Primary API | Query Focus |
|-----------|-------------|-------------|
| externe-effekte | OpenAlex | Policy, regulatory impact studies |
| neue-horizonte | OpenAlex + arXiv | Innovation, emerging technology |
| digitale-wertetreiber | OpenAlex | Digital transformation ROI |
| digitales-fundament | arXiv | Infrastructure, security research |

Healthcare/Pharma subsectors: Add PubMed queries
```

### Search Budget

| Search Type | Count | Total |
|-------------|-------|-------|
| Standard web (EN/DE) | 16 | 16 |
| DACH-specific | 4 | 20 |
| **Academic API** | **4** | **24** |

### Signal Extraction

From academic sources, extract:

```yaml
academic_signal:
  title: "{paper_title}"
  source_url: "{doi_or_arxiv_url}"
  freshness_date: "{publication_year}-{month}"
  source_type: "academic"
  authority_score: 5  # Peer-reviewed default
  citation_count: {count}
  concepts: ["{concept1}", "{concept2}"]
```

### Mapping to Horizons

| Publication Age | Recommended Horizon |
|-----------------|---------------------|
| {PREVIOUS_YEAR}-{CURRENT_YEAR} (0-1 year) | PLAN |
| 2022-2023 (2-3 years) | PLAN/ACT (if citations high) |
| 2020-2021 (4-5 years) | ACT (if mainstream now) |
| < 2020 | Usually too old, skip |

**Exception:** Highly-cited seminal papers remain relevant regardless of age.

---

## 6. Environment Variables

```bash
# Optional API keys for enhanced access
SEMANTIC_SCHOLAR_API_KEY=   # Free from semanticscholar.org
PUBMED_API_KEY=             # Free from NCBI

# Contact email for polite pool (OpenAlex)
OPENALEX_EMAIL=your-email@domain.com
```

---

## 7. Error Handling

### API Failure Fallback

```text
If OpenAlex fails:
  → Try Semantic Scholar
  → If both fail, skip academic search (log warning)

If Semantic Scholar rate limited:
  → Wait 60 seconds
  → Fall back to OpenAlex only

If PubMed fails (pharma/healthcare):
  → Log warning
  → Continue with web-only signals
```

### Timeout Configuration

| API | Timeout | Retry |
|-----|---------|-------|
| OpenAlex | 10s | 2x |
| Semantic Scholar | 15s | 1x |
| arXiv | 10s | 2x |
| PubMed | 10s | 2x |

---

## 8. Sample WebFetch Queries

### OpenAlex Example

```text
WebFetch URL: https://api.openalex.org/works?filter=concepts.display_name.search:electric vehicle battery&filter=publication_year:{PREVIOUS_YEAR}-{CURRENT_YEAR}&per-page=10&sort=cited_by_count:desc

Prompt: Extract the top 5 paper titles, publication dates, and citation counts. Format as a list of trend signals.
```

### Semantic Scholar Example

```text
WebFetch URL: https://api.semanticscholar.org/graph/v1/paper/search?query=industrial automation predictive maintenance&fields=title,year,citationCount&limit=10

Header: x-api-key: ${SEMANTIC_SCHOLAR_API_KEY}

Prompt: Extract paper titles and years. Identify emerging research themes.
```

### arXiv Example

```text
WebFetch URL: http://export.arxiv.org/api/query?search_query=cat:cs.AI+AND+all:autonomous+driving&max_results=10&sortBy=submittedDate&sortOrder=descending

Prompt: Parse the XML response. Extract titles and submission dates for the 5 most recent papers.
```

