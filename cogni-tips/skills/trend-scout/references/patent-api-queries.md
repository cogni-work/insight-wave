# Patent Data API Queries

**Reference Checksum:** `sha256:trend-scout-patent-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: patent-api-queries.md | Checksum: trend-scout-patent-v1
```

---

## Overview

This reference provides query templates for free patent APIs to enhance trend detection with R&D-backed signals. Patent filings provide **6+ year lead time** over mainstream news and market reports.

**Strategic Value:** Patents reveal where companies are investing R&D resources before products reach market.

---

## 1. USPTO PatentsView (DEPRECATED)

> **DEPRECATED (May 2025):** The PatentsView Legacy API at `api.patentsview.org` has been discontinued and returns HTTP 410 (Gone). Use Google Patents web search (recommended) or the new PatentSearch API at `search.patentsview.org` (requires API key).

### Google Patents Web Search (Recommended - No API Key)

Use site-specific web search for patent discovery:

```text
WebSearch: site:patents.google.com "{SUBSECTOR_EN}" {TECHNOLOGY_TERMS} {PREVIOUS_YEAR} {CURRENT_YEAR}
```

This provides:
- Global patent coverage (US, EP, WO, CN, etc.)
- No authentication required
- Recent filing focus via year filter

### Legacy API Overview (No Longer Functional)

| Property | Value |
|----------|-------|
| **URL** | api.patentsview.org (DEPRECATED) |
| **New URL** | search.patentsview.org (requires API key) |
| **Cost** | Free (new API requires registration) |
| **Rate Limit** | 10 requests/second |
| **Coverage** | 12M+ US patents and applications |
| **Documentation** | search.patentsview.org/docs |

### Authentication (New API)

The new PatentSearch API requires an API key. Request one via the PatentsView service desk.

### Query Templates

#### Basic Patent Search

```text
https://api.patentsview.org/patents/query?q={"_and":[{"_text_any":{"patent_title":"{SEARCH_TERMS}"}},{"patent_date":"{YEAR}-01-01"}]}&f=["patent_number","patent_title","patent_date","patent_abstract","assignee_organization"]&o={"page":1,"per_page":25}
```

#### CPC Class Search (Technology Categories)

```text
https://api.patentsview.org/patents/query?q={"_and":[{"cpc_group_id":"{CPC_CODE}"},{"patent_date":"{YEAR}-01-01"}]}&f=["patent_number","patent_title","patent_date","assignee_organization"]&o={"page":1,"per_page":25}
```

### CPC Classification Codes by Subsector

| Subsector | Primary CPC | Secondary CPC | Description |
|-----------|-------------|---------------|-------------|
| automotive | B60L, B60W | G05D | Electric vehicles, autonomous driving |
| machinery | B25J, G05B | B23P | Robotics, manufacturing automation |
| pharmaceuticals | A61K, A61P | G01N | Drug compositions, therapeutic activity |
| banking | G06Q20, G06Q40 | H04L9 | Payment systems, financial transactions |
| renewable-energy | H02J, H01M | F03D | Energy storage, solar, wind |
| it-services | G06F, G06N | H04L | Computing, AI/ML, networking |
| healthcare | A61B, G16H | A61N | Medical devices, health informatics |

### Subsector Query Examples

| Subsector | Query JSON |
|-----------|------------|
| automotive | `{"_text_any":{"patent_abstract":"electric vehicle battery management"}}` |
| machinery | `{"_text_any":{"patent_abstract":"industrial robot predictive maintenance"}}` |
| pharmaceuticals | `{"_text_any":{"patent_abstract":"artificial intelligence drug discovery"}}` |
| banking | `{"_text_any":{"patent_abstract":"blockchain payment authentication"}}` |
| renewable-energy | `{"_text_any":{"patent_abstract":"lithium battery energy density"}}` |

### Response Parsing

```json
{
  "patents": [
    {
      "patent_number": "US12345678",
      "patent_title": "System for autonomous vehicle navigation",
      "patent_date": "2024-06-15",
      "patent_abstract": "A method for...",
      "assignees": [
        {"assignee_organization": "Tesla Inc"}
      ]
    }
  ],
  "count": 1234,
  "total_patent_count": 1234
}
```

### Authority Scoring

| Indicator | Authority Score |
|-----------|-----------------|
| Granted patent (US) | 4 |
| Application (published) | 3 |
| Major tech company assignee | +1 bonus |
| Multiple related patents (family) | +1 bonus |

---

## 2. Lens.org (Global Patents + Publications)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | api.lens.org |
| **Cost** | Free for research/non-commercial |
| **Rate Limit** | Generous (requires token) |
| **Coverage** | 127M+ patent records globally |
| **Documentation** | docs.api.lens.org |

### Authentication

```bash
# Environment variable
LENS_API_TOKEN=your-token-here

# Request header
Authorization: Bearer ${LENS_API_TOKEN}
```

**Get Token:** https://www.lens.org/lens/user/subscriptions (free academic/research)

### Query Templates

#### Patent Search

```text
POST https://api.lens.org/patent/search
Content-Type: application/json
Authorization: Bearer ${LENS_API_TOKEN}

{
  "query": {
    "bool": {
      "must": [
        {"match": {"title": "{SEARCH_TERMS}"}},
        {"range": {"date_published": {"gte": "2023-01-01"}}}
      ]
    }
  },
  "size": 25,
  "sort": [{"date_published": "desc"}]
}
```

#### Assignee Search (Company Focus)

```text
{
  "query": {
    "bool": {
      "must": [
        {"match": {"applicant.name": "{COMPANY_NAME}"}},
        {"match": {"classification_cpc.symbol": "{CPC_CODE}"}}
      ]
    }
  },
  "size": 25
}
```

#### Jurisdiction Filter (DACH Focus)

```text
{
  "query": {
    "bool": {
      "must": [
        {"match": {"title": "{SEARCH_TERMS}"}},
        {"terms": {"jurisdiction": ["DE", "AT", "CH", "EP"]}}
      ]
    }
  }
}
```

### Response Parsing

```json
{
  "data": [
    {
      "lens_id": "123-456-789",
      "title": "Patent Title",
      "date_published": "2024-06-15",
      "abstract": "...",
      "applicants": [{"name": "Siemens AG"}],
      "classification_cpc": [{"symbol": "G06N"}]
    }
  ],
  "total": 456,
  "results": 25
}
```

### Unique Value: Patent-Publication Links

Lens.org links patents to citing/cited academic papers:

```text
{
  "query": {"match": {"lens_id": "{PATENT_LENS_ID}"}},
  "include": ["scholarly_citations", "npl_citations"]
}
```

---

## 3. EPO Open Patent Services (European Patents)

### API Overview

| Property | Value |
|----------|-------|
| **URL** | ops.epo.org |
| **Cost** | Free (registration required) |
| **Rate Limit** | 4 requests/second (weekly quota) |
| **Coverage** | 120M+ patent documents |
| **Documentation** | developers.epo.org |

### Authentication

```bash
# OAuth2 credentials
EPO_CONSUMER_KEY=your-key
EPO_CONSUMER_SECRET=your-secret

# Get access token
curl -X POST "https://ops.epo.org/3.2/auth/accesstoken" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -u "${EPO_CONSUMER_KEY}:${EPO_CONSUMER_SECRET}"
```

**Get Credentials:** https://developers.epo.org/ (free registration)

### Query Templates

#### Biblio Search

```text
GET https://ops.epo.org/3.2/rest-services/published-data/search/biblio?q=ta%3D{SEARCH_TERMS}%20and%20pd%3D{YEAR}
Authorization: Bearer ${EPO_ACCESS_TOKEN}
Accept: application/json
```

#### CPC Classification Search

```text
GET https://ops.epo.org/3.2/rest-services/published-data/search/biblio?q=cpc%3D{CPC_CODE}%20and%20pd%3D{YEAR}
```

### Query Syntax

| Operator | Meaning | Example |
|----------|---------|---------|
| `ta=` | Title/Abstract | `ta=electric vehicle` |
| `ti=` | Title only | `ti=autonomous driving` |
| `pa=` | Applicant | `pa=Siemens` |
| `cpc=` | CPC class | `cpc=G06N` |
| `pd=` | Publication date | `pd=2024` |
| `AND` | Boolean AND | `ta=battery AND pa=BMW` |

### Response Parsing (XML/JSON)

```json
{
  "ops:biblio-search": {
    "ops:search-result": {
      "@total-result-count": "1234",
      "exchange-documents": [
        {
          "bibliographic-data": {
            "publication-reference": {"document-id": {"country": "EP", "doc-number": "1234567"}},
            "invention-title": [{"$": "Patent Title"}],
            "abstract": {"p": {"$": "Abstract text..."}}
          }
        }
      ]
    }
  }
}
```

### DACH-Specific Queries

| Country | Query Modifier | Example |
|---------|----------------|---------|
| Germany | `pn=DE` | `ta=Industrie 4.0 AND pn=DE` |
| Austria | `pn=AT` | `ta=Maschinenbau AND pn=AT` |
| Switzerland | `pn=CH` | `ta=Pharma AND pn=CH` |
| European | `pn=EP` | `ta=automotive AND pn=EP` |

---

## 4. Integration with Phase 1

### Patent Search Phase (Phase 1.5)

Add after Academic API queries (Step 1.4):

```text
Step 1.5: Patent API Queries

For each dimension, execute 1-2 patent searches:

| Dimension | Primary API | Query Focus |
|-----------|-------------|-------------|
| externe-effekte | EPO OPS | Regulatory-driven patents (safety, compliance) |
| neue-horizonte | USPTO + Lens | Disruptive technology patents |
| digitale-wertetreiber | USPTO | Digital product/service patents |
| digitales-fundament | USPTO + EPO | Infrastructure, security patents |

DACH focus: Prioritize EPO for European coverage
```

### Search Budget

| Search Type | Count | Total |
|-------------|-------|-------|
| Standard web (EN/DE) | 16 | 16 |
| DACH-specific | 4 | 20 |
| Academic API | 4 | 24 |
| **Patent API** | **4** | **28** |

### Signal Extraction

From patent sources, extract:

```yaml
patent_signal:
  title: "{patent_title}"
  source_url: "https://patents.google.com/patent/{patent_number}"
  freshness_date: "{filing_or_publication_date}"
  source_type: "patent"
  authority_score: 4  # Granted patent default
  assignee: "{company_name}"
  cpc_codes: ["{cpc1}", "{cpc2}"]
```

### Mapping to Horizons

| Patent Status | Recommended Horizon |
|---------------|---------------------|
| Application (< 2 years old) | OBSERVE |
| Application (2-4 years old) | PLAN |
| Granted (recent) | PLAN/ACT |
| Multiple assignees filing similar | ACT (competitive) |

**Key Trend:** Heavy patent activity in a domain = high strategic priority for major players.

---

## 5. Major Assignee Tracking

### DACH Technology Leaders

| Company | Subsectors | Watch For |
|---------|------------|-----------|
| Siemens AG | machinery, energy, it-services | Industrial automation, smart grid |
| Bosch | automotive, machinery | Sensors, autonomous systems |
| SAP | it-services, banking | Enterprise AI, blockchain |
| BASF | chemicals-pharma | Materials, sustainability |
| BMW/VW/Daimler | automotive | EV, autonomous, connected |
| Novartis/Roche | pharmaceuticals | Drug discovery, diagnostics |

### Tracking Query

```text
USPTO: {"_and":[{"assignee_organization":"{COMPANY}"},{"patent_date":"{YEAR}-01-01"}]}

Lens: {"query":{"bool":{"must":[{"match":{"applicant.name":"{COMPANY}"}},{"range":{"date_published":{"gte":"2024-01-01"}}}]}}}
```

---

## 6. Environment Variables

```bash
# Optional API tokens for enhanced access
LENS_API_TOKEN=          # Free from lens.org (research use)
EPO_CONSUMER_KEY=        # Free from developers.epo.org
EPO_CONSUMER_SECRET=     # Free from developers.epo.org

# USPTO PatentsView needs no authentication
```

---

## 7. Error Handling

### API Failure Fallback

```text
If USPTO fails:
  → Try Lens.org
  → If both fail, skip patent search (log warning)

If EPO rate limited:
  → Wait until quota resets (weekly)
  → Use Lens.org for European patents

If Lens.org token expired:
  → Log warning
  → Fall back to USPTO (US-only)
```

### Timeout Configuration

| API | Timeout | Retry |
|-----|---------|-------|
| USPTO PatentsView | 15s | 2x |
| Lens.org | 20s | 1x |
| EPO OPS | 15s | 2x |

---

## 8. Sample WebFetch Queries

### USPTO Example

```text
WebFetch URL: https://api.patentsview.org/patents/query?q={"_text_any":{"patent_abstract":"autonomous vehicle lidar"}}&f=["patent_number","patent_title","patent_date","assignee_organization"]&o={"per_page":10}

Prompt: Extract patent titles, filing dates, and assignee companies. Identify dominant players and emerging technologies.
```

### Lens.org Example (requires token)

```text
WebFetch URL: https://api.lens.org/patent/search
Method: POST
Headers: Authorization: Bearer ${LENS_API_TOKEN}, Content-Type: application/json
Body: {"query":{"bool":{"must":[{"match":{"title":"electric vehicle battery"}},{"terms":{"jurisdiction":["DE","EP"]}}]}},"size":10}

Prompt: Extract patent titles and applicant companies. Focus on German/European filings.
```

### EPO Example (requires OAuth)

```text
WebFetch URL: https://ops.epo.org/3.2/rest-services/published-data/search/biblio?q=ta%3Dindustrie%204.0%20and%20pd%3D2024
Headers: Authorization: Bearer ${EPO_ACCESS_TOKEN}

Prompt: Parse the response. Extract patent numbers, titles, and applicants for Industry 4.0 patents.
```

---

## 9. Patent Citation Networks

### Forward Citations (Who's Building on This?)

Patents citing a key patent indicate:
- Technology validation
- Active R&D in the space
- Potential competitors/collaborators

### Backward Citations (What's the Foundation?)

Patents cited by new applications indicate:
- Foundational technology
- Prior art landscape
- Technology maturity

### Lens.org Citation Query

```text
{
  "query": {"match": {"lens_id": "{BASE_PATENT_ID}"}},
  "include": ["cited_by", "references"]
}
```

Use citation networks to identify technology clusters and competitive dynamics.

