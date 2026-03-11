# Phase 0.5: Web Research

Gather current trend signals through web searches before generating candidates. This enriches Phase 1 with fresh, real-world data beyond training knowledge — candidates sourced from recent web results tend to be more specific and timely.

## Search Strategy

Run 8 searches: 4 dimensions x 2 regions (global + DACH). The bilingual approach captures both international trends and Germany/Austria/Switzerland-specific developments, which matters because many research projects target the DACH market.

### Search Queries

Build queries by combining the industry sector with dimension-specific terms:

| Dimension | Global Query | DACH Query |
|-----------|-------------|------------|
| externe-effekte | `"{INDUSTRY} external trends regulations market forces 2026"` | `"{INDUSTRY_DE} externe Trends Regulierung Markt Deutschland 2026"` |
| neue-horizonte | `"{INDUSTRY} business model innovation strategic trends 2026"` | `"{INDUSTRY_DE} Geschäftsmodell Innovation strategische Trends 2026"` |
| digitale-wertetreiber | `"{INDUSTRY} digital value creation customer experience ROI 2026"` | `"{INDUSTRY_DE} digitale Wertschöpfung Kundenerfahrung 2026"` |
| digitales-fundament | `"{INDUSTRY} digital infrastructure technology foundation 2026"` | `"{INDUSTRY_DE} digitales Fundament Infrastruktur Technologie 2026"` |

Use German industry translations: manufacturing → Maschinenbau/Fertigung, healthcare → Gesundheitswesen, financial services → Finanzdienstleistungen, retail → Einzelhandel, logistics → Logistik.

### WebSearch Configuration

Block low-quality domains: pinterest.com, facebook.com, instagram.com, tiktok.com, reddit.com.

### Preferred Source Types

Each dimension benefits from different source types:

| Dimension | Best Sources |
|-----------|-------------|
| externe-effekte | Regulatory bodies, industry associations, news (EU Commission, VDMA, BITKOM) |
| neue-horizonte | Consulting firms, analysts (McKinsey, BCG, Roland Berger, Gartner) |
| digitale-wertetreiber | Tech providers, case studies (SAP, Siemens, business publications) |
| digitales-fundament | Research institutes, tech vendors (Fraunhofer, MIT, DIN/ISO) |

## Signal Extraction

For each search result, extract:
- **signal_name** — trend name from title/snippet
- **keywords** — 3 relevant keywords
- **source_url** — for provenance tracking
- **freshness** — date from URL/snippet, or "recent"
- **region** — global or dach

Only extract signals that actually appear in search results. Do not invent signals or fabricate URLs — training knowledge belongs in Phase 1, not here. This separation keeps the source tracking honest.

## Aggregation

1. Group signals by dimension
2. Merge global and DACH signals
3. Deduplicate by similar trend names or overlapping keywords
4. Keep 5-10 strongest signals per dimension
5. Store as WEB_RESEARCH_CONTEXT for Phase 1

## Failure Handling

Web searches can fail due to rate limits, timeouts, or empty results. Handle gracefully:

- **Some searches fail:** Continue with available signals. Partial data is still valuable.
- **All 8 fail:** Set WEB_RESEARCH_AVAILABLE=false and proceed to Phase 1 with training-only generation. Log a warning so the user knows candidates may lack freshness indicators.

## Variables to Carry Forward

| Variable | Purpose |
|----------|---------|
| WEB_RESEARCH_AVAILABLE | Whether any signals were gathered |
| WEB_RESEARCH_CONTEXT | Structured signals by dimension for Phase 1 |

## Next Phase

Proceed to [phase-1-generate.md](phase-1-generate.md) with web research context.
