# Evidence Enrichment Strategy

Reference for configuring evidence collection in the trend-report-writer agent.

---

## Signal-First Approach

The trend-report-writer uses a **signal-first** strategy: reuse evidence already collected by trend-scout's web research phase before executing new searches. This avoids redundant web traffic and produces faster reports.

### Evidence Source Priority

| Priority | Source | When Used |
|----------|--------|-----------|
| 1 | Raw signals from `web-research-raw.json` | Always checked first (if available) |
| 2 | Targeted WebSearch (1 query) | Trend has partial signal match (qualitative only) |
| 3 | Full WebSearch (2-3 queries) | No matching signals found for trend |

### Signal Matching

For each trend candidate, match against raw signals by:
- Trend `name` appears in signal `signal` text (case-insensitive)
- Any trend `keyword` appears in signal `keywords` array
- Trend `research_hint` terms overlap with signal `signal` text

### Evidence Classification

| Status | Criteria | Action |
|--------|----------|--------|
| `signal_sufficient` | 1+ matched signal with quantitative data and source URL | Skip WebSearch |
| `signal_partial` | Matched signals but no quantitative specifics | 1 targeted WebSearch |
| `signal_none` | No matching signals | 2-3 full WebSearches |

---

## WebSearch Query Templates (Gap-Fill Only)

Only executed for trends classified as `signal_partial` or `signal_none`.

### Partial Gap (1 query)

```
"{trend_name}" market size OR growth rate {CURRENT_YEAR} {SUBSECTOR_EN}
```

### Full Gap (2-3 queries)

**Query 1 — Market Size / Adoption:**
```
"{trend_name}" market size {CURRENT_YEAR} {SUBSECTOR_EN}
```

**Query 2 — Growth / Statistics:**
```
"{trend_name}" growth rate statistics {SUBSECTOR_EN} {CURRENT_YEAR}
```

**Query 3 (conditional) — DACH-specific:**
Only if language is `de` or trend has DACH relevance:
```
"{trend_name_de}" Marktgröße Studie Deutschland {CURRENT_YEAR}
```

### Blocked Domains

Always block low-quality sources:

```yaml
blocked_domains:
  - pinterest.com
  - facebook.com
  - instagram.com
  - tiktok.com
  - reddit.com
```

### Preferred Sources

Prioritize results from high-authority sources:

| Authority | Source Types | Score |
|-----------|-------------|-------|
| 5 | Government, regulatory bodies, peer-reviewed research | Highest |
| 4 | Industry associations (VDMA, BITKOM), consulting firms (McKinsey, BCG, Gartner) | High |
| 3 | Quality media (Handelsblatt, Reuters, Financial Times), market research firms | Medium |
| 2 | Trade publications, industry blogs, company reports | Lower |

---

## Evidence Types to Extract

When processing search results OR raw signals, look for:

| Type | Examples | Claim Format |
|------|----------|-------------|
| `currency` | Market sizes, revenue, investment | "$6.9B", "EUR 2.3 Mrd." |
| `percentage` | Growth rates, adoption rates, market share | "34% CAGR", "78% adoption" |
| `count` | Users, deployments, patents, companies | "1,200 companies", "45 patents" |
| `timeframe` | Deadlines, milestones, forecasts | "by 2027", "within 18 months" |
| `ratio` | Efficiency gains, cost reductions | "3x improvement", "40% cost reduction" |

---

## Fallback Handling

| Scenario | Action |
|----------|--------|
| No quantitative results for a trend | Write qualitative analysis, add `[No quantitative data available]` marker |
| Search returns irrelevant results | Skip, do not force-fit evidence |
| Conflicting numbers from sources | Use the most authoritative source, note conflict in prose |
| Only German-language evidence found | Use it, cite in original language |
| Only English-language evidence found | Use it regardless of report language |
| Raw signals file missing | Orchestrator tries fallback (`phase1-research-summary.json` with field expansion — see below). If both unavailable, agent receives "none" and uses full WebSearch for all trends |

---

## Abbreviated Field Expansion

The fallback source `phase1-research-summary.json` uses abbreviated field names to save space. The orchestrator expands these before passing to agents:

| Abbreviated | Full Field |
|-------------|-----------|
| `d` | `dimension` |
| `n` | `signal` |
| `k` | `keywords` |
| `u` | `source` |
| `f` | `freshness` |
| `a` | `authority` |
| `t` | `source_type` |
| `i` | `indicator_type` |
| `lt` | `lead_time` |

---

## Anti-Hallucination Rules

**STRICT — These rules are non-negotiable:**

1. NEVER fabricate URLs — every `[Source Title](url)` must come from actual WebSearch results or raw signal `source` fields
2. NEVER invent statistics — if no number was found, say so explicitly
3. NEVER round or adjust numbers to seem more impressive
4. ALWAYS include the exact URL from the search result or raw signal
5. If a source title is unclear, use the domain name as title (e.g., `[gartner.com](url)`)
6. Raw signal URLs are trustworthy — they originated from real WebSearch results during trend-scout Phase 1

---

## Search Budget

Per dimension (~13 trends), budget depends on signal coverage:

| Signal Coverage | Expected Searches | Savings vs Full Search |
|-----------------|-------------------|----------------------|
| High (8+ trends with signals) | 10-15 | ~50-60% |
| Medium (4-7 trends with signals) | 15-25 | ~20-40% |
| Low (0-3 trends with signals) | 25-35 | ~0-15% |
| No raw signals file | 26-39 (full) | 0% |

Worst case (no signals): same as before (~30 searches per dimension, ~120 total).
Best case (all signals match): ~20 searches per dimension, ~80 total (~33% reduction).
