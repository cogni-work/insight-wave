# Search Patterns

## Phase 1: Company Discovery

Search for the target company and its affiliated entities:

```text
WebSearch: "{company name}" subsidiaries affiliates brands "ICT services" OR "IT services" OR "digital services"
WebSearch: "{company name}" group companies divisions business units
WebSearch: "{company name}" consulting advisory strategy "IT consulting"
WebSearch: "{company name}" "managed services" OR "onsite services" OR "field services" OR "IT outsourcing" subsidiary
```

**Extract:**

- Parent company name and primary web domain
- Subsidiary/affiliate companies with their web domains
- Business units that offer B2B ICT services
- Consulting/advisory subsidiaries (often have IT Strategy, Architecture services)
- On-site/field services subsidiaries (often have IT Support, IT Outsourcing services)
- Industry-vertical subsidiaries (e.g., healthcare IT, automotive IT)

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce Capacity searches.

```text
WebSearch: site:{domain} "annual revenue" OR "turnover" OR "financial results" {current year}
WebSearch: site:{domain} "employees" OR "workforce" OR "team size" {current year}
WebSearch: site:{domain} "headquarters" OR "locations" OR "offices" OR "data centers"
WebSearch: site:{domain} "market share" OR "ranking" OR "analyst" OR "Gartner" OR "Forrester"
WebSearch: site:{domain} "ISO" OR "certifications" OR "accreditations" OR "compliance"
WebSearch: site:{domain} "partner" OR "AWS" OR "Azure" OR "GCP" OR "SAP" OR "Microsoft"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | Revenue, turnover, market cap, growth trends |
| 0.2 Workforce Capacity | Employee count, IT specialists, regional distribution |
| 0.3 Geographic Presence | HQ, delivery centers, service countries, data centers |
| 0.4 Market Position | Rankings, analyst ratings, reference clients |
| 0.5 Certifications & Accreditations | ISO certs, industry accreditations, compliance |
| 0.6 Partnership Ecosystem | Hyperscaler tiers, strategic alliances |
