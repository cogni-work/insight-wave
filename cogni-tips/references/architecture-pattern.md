# Bilingual Search Architecture Pattern

This document describes the generalizable bilingual search pattern used by cogni-tips. The current implementation is specialized for DACH (Germany, Austria, Switzerland) with English/German search pairs. The same architecture applies to any market where combining international English sources with local-language institutional sources yields better trend intelligence than either alone.

## Why bilingual beats monolingual

English-only research misses local market signals. Local-language-only research misses global context. The combination surfaces trends that appear in both (validated), trends visible only locally (early regional signals), and trends visible only globally (import opportunities).

For the German Mittelstand specifically: EU regulations, Fraunhofer studies, and industry association position papers often appear in German months before English coverage catches up. Conversely, Silicon Valley venture signals and global consulting research appear in English first.

## Architecture: three search tiers

```
Tier 1: International (English)
├── Global web searches (no region filter)
├── Region-qualified searches (English + market region keywords)
├── Academic APIs (OpenAlex, Google Scholar)
└── Patent databases (Google Patents, EPO)

Tier 2: Local language
├── Local web searches (native language queries)
├── Region-qualified searches (native language + local region names)
└── Local business media

Tier 3: Curated institutional sources
├── Industry associations (site-specific searches)
├── Research institutes (site-specific searches)
├── Regulatory databases
└── Local consulting/advisory firms
```

### How cogni-tips implements this for DACH

| Tier | Searches | Examples |
|------|----------|----------|
| International EN | 8 | `{subsector} trends regulations {year}`, `{subsector} trends Germany Austria Switzerland {year}` |
| Local DE | 8 | `{subsector_de} Trends Regulierung {year}`, `{subsector_de} Trends Deutschland Österreich Schweiz {year}` |
| DACH institutional | 8 | `site:vdma.org`, `site:fraunhofer.de`, `site:bitkom.org`, `site:zukunftsinstitut.de` |
| Funding signals | 4 | VC, M&A, Series funding (bilingual) |
| Job market signals | 4 | Skills, hiring, demand (bilingual) |
| **Total** | **32** | Plus API queries (OpenAlex, Google Patents, EUR-Lex) |

## Adapting for another market

To adapt this pattern for a different market, you need to provide four things:

### 1. Language pair

The primary local language paired with English. Some markets need more than one local language (e.g., Switzerland: DE/FR/IT, Belgium: NL/FR).

| Market | Language pair | Notes |
|--------|-------------|-------|
| DACH (current) | EN + DE | Single local language |
| Japan | EN + JA | Single local language |
| France | EN + FR | Single local language |
| Brazil | EN + PT-BR | Single local language |
| Nordics | EN + local (SE/NO/FI/DK) | Per-country variant |
| India | EN + HI (or regional) | English often sufficient for business sources |

### 2. Industry taxonomy translations

Each subsector needs a native-language name for local searches. cogni-tips stores these as `subsector_en` / `subsector_de` pairs. A new market adds `subsector_{locale}`.

Example for Japan:
```json
{
  "subsector": "automotive",
  "subsector_en": "Automotive",
  "subsector_ja": "自動車"
}
```

### 3. Curated institutional source catalog

This is the highest-effort component and the highest-value one. Each market has its own landscape of industry associations, research institutes, regulatory bodies, and quality business media.

**Template for a market source catalog:**

| Category | What to map | DACH example | Japan example |
|----------|-------------|--------------|---------------|
| Industry associations | Sector-specific bodies | VDMA, VDA, BITKOM, ZVEI | JAMA, JEITA, JMIA |
| Research institutes | Applied research, innovation | Fraunhofer, Max Planck | AIST, NEDO, RIKEN |
| Futures/foresight | Trend think tanks | Zukunftsinstitut | NRI, Nomura Research |
| Regulatory | Law databases, policy | EUR-Lex, BaFin | e-Gov, FSA Japan |
| Business media (Tier 1) | Daily quality outlets | Handelsblatt, FAZ | Nikkei, Toyo Keizai |
| Business media (Tier 2) | Weekly/monthly | WirtschaftsWoche, t3n | Diamond, Economist JP |
| Consulting (local) | Regional strategy firms | Roland Berger, Staufen | NRI, Yano Research |
| Startup ecosystem | Funding/innovation signals | Deutsche Startups | TechCrunch JP, Bridge |
| Chambers/federations | Cross-sector bodies | DIHK, BDI | Keidanren, JCCI |

Each source gets an authority score (1-5) and a search query template.

### 4. i18n message catalog

User-facing text (prompts, labels, section headers) in the local language. cogni-tips uses `messages-{locale}.md` and `labels-{locale}.md` files.

## What stays the same across markets

These components are market-independent:

- **TIPS content framework** (Trend, Implications, Possibilities, Solutions)
- **Scoring frameworks** (Ansoff signal intensity, Rogers diffusion, CRAAP source quality)
- **Search execution architecture** (parallel bilingual queries, deduplication, authority weighting)
- **Candidate generation pipeline** (60 candidates → user selection → 52 agreed)
- **Report generation pipeline** (4 parallel dimension writers, evidence enrichment, claims extraction)
- **Cross-language deduplication logic** (name matching, keyword overlap, URL dedup)

## What changes per market

- Dimension names (currently German — could be localized or kept as canonical identifiers)
- Subcategory names (currently German: `wirtschaft`, `regulierung`, etc.)
- Industry taxonomy translations
- Institutional source catalog (highest effort)
- i18n message/label catalogs
- Search query templates (site-specific patterns)
- Regional regulatory databases (EUR-Lex → e-Gov Japan, Légifrance, etc.)
- API sources (OpenAlex is global; patent databases vary by jurisdiction)

## Effort estimate per new market

| Component | Effort | Notes |
|-----------|--------|-------|
| Language pair config | Low | Schema change, add locale enum value |
| Industry taxonomy translations | Medium | ~50 subsector names need native translation |
| Institutional source catalog | **High** | Deep domain knowledge of local market required |
| i18n catalogs | Medium | ~100 strings per language |
| Search query templates | Medium | ~8-12 site-specific templates |
| Testing and tuning | Medium | Search quality varies by language/market |
| **Total per market** | **2-4 weeks** | Assuming domain expertise available |

## Design decision: fork vs. generalize

cogni-tips chose specialization over generalization. The DACH source catalog alone is 250+ lines of curated institutional intelligence. Building equivalent depth for another market is a substantial investment that should be driven by actual demand, not speculative architecture.

If you're adapting this for a new market, we recommend forking cogni-tips and replacing the DACH-specific content rather than trying to build a multi-market abstraction layer. The search architecture pattern is the reusable part; the institutional knowledge is the valuable part that must be built per market.
