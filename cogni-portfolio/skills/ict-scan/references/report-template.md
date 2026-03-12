# ICT Scan Report Template

Instructions for generating `<company-slug>-portfolio.md` in Phase 6.

## Report Structure

Generate the report dynamically from the taxonomy in [ict-taxonomy.md](ict-taxonomy.md). Do NOT hardcode 57 empty table sections — iterate over the taxonomy dimensions and categories to produce each section.

```markdown
# <Company Name> ICT Portfolio

> ICT scan generated on <YYYY-MM-DD>
> Analyzed domains: domain1.com, domain2.com, domain3.com
```

### Legends (include at top)

**Service Horizons:**

| Horizon | Timeframe | Characteristics |
|---------|-----------|-----------------|
| **Current** | 0-1 years | Generally available, proven deployments, established pricing |
| **Emerging** | 1-3 years | Pilot/beta, limited availability, early adopter pricing |
| **Future** | 3+ years | Announced, conceptual, R&D phase, no fixed pricing |

**Discovery Status:**

| Status | Meaning |
|--------|---------|
| **Confirmed** | Provider offers this service (evidence found) |
| **Not Offered** | No evidence found for this category |
| **Emerging** | Announced or pilot status (not yet GA) |
| **Extended** | Provider-specific variant beyond standard taxonomy |

### Per-Category Section Format

For each of the 57 categories (from [ict-taxonomy.md](ict-taxonomy.md)), generate:

```markdown
### <ID> <Category Name> [Status: <status>]

| Name | Description | Domain | Link | USP | Provider Unit | Pricing Model | Delivery Model | Partners | Verticals | Horizon |
|------|-------------|--------|------|-----|---------------|---------------|----------------|----------|-----------|---------|
| <offerings...> |
```

Group categories under their dimension headers (`## 1. Connectivity Services`, etc.).

### Empty Categories

When no offerings are found:

```markdown
| *No offerings found* | | | | | | | | | | |
```

Set status to `[Status: Not Offered]`.

### Cross-Cutting Attributes (include at end)

```markdown
## Cross-Cutting Attributes

### Industry Verticals
Healthcare, Automotive, Public Sector, Financial Services, Retail, Manufacturing, Energy, Telecommunications, Media

### Delivery Locations
Domestic, European, Nearshore, Offshore, Global

### Partner Ecosystem
- **Hyperscalers:** AWS, Azure, GCP
- **Enterprise Software:** SAP, ServiceNow, Salesforce
- **Technology Vendors:** (provider-specific)
```

## Column Reference

See [entity-schema.md](entity-schema.md) for the full 11-field offering schema.
