# Phase 1: Generate Candidate Pool

Generate 60 trend candidates: 5 per cell across the 4x3 matrix (4 dimensions x 3 horizons). Every candidate should be specific to the project's industry sector.

## Entry Check

Verify from Phase 0:
- PROJECT_PATH and INDUSTRY_SECTOR are set
- RESEARCH_TYPE is `smarter-service`
- WEB_RESEARCH_AVAILABLE flag is set (from Phase 0.5, or false if skipped)

## Dimension Framework

### Four Dimensions

| Slug | German Name | TIPS Focus | What to generate |
|------|-------------|------------|-----------------|
| `externe-effekte` | Externe Effekte | Trend (T) | External forces: regulations, market shifts, geopolitical changes, societal trends |
| `neue-horizonte` | Neue Horizonte | Possibilities (P) | Strategic options: business model innovation, new market opportunities, partnerships |
| `digitale-wertetreiber` | Digitale Wertetreiber | Implications (I) | Value creation: how digital transforms customer experience, operations, revenue |
| `digitales-fundament` | Digitales Fundament | Solutions (S) | Enablers: infrastructure, platforms, capabilities needed to execute |

### Three Horizons

| Horizon | Timeframe | Character |
|---------|-----------|-----------|
| `act` | 0-2 years | Immediate and validated. Things you should be doing now. |
| `plan` | 2-5 years | Emerging. Requires preparation and capability building. |
| `observe` | 5+ years | Speculative. Worth monitoring but too early to commit resources. |

## Generation Approach

Use extended thinking for this — generating 60 quality candidates requires careful reasoning about industry context, dimension boundaries, and horizon appropriateness.

### Source Mix

When web research is available, aim for a mix:
- **40-60% web-signal:** Candidates derived from Phase 0.5 web search results
- **40-60% training:** Candidates from training knowledge
- At least 2 web-signal candidates per dimension (8 total minimum)

When web research is unavailable, all candidates come from training knowledge. Mark them accordingly.

### Candidate Structure

Each candidate needs:

| Field | Description |
|-------|-------------|
| trend_name | Clear, specific name (2-5 words) |
| keywords | 3 searchable keywords |
| rationale | Why this trend matters for the industry sector (1-2 sentences) |
| source | `web-signal`, `training`, or `hybrid` |
| source_url | URL from web search (web-signal only) |
| freshness_date | Date indicator from source (web-signal only, `-` for training) |

### Quality Criteria

Good candidates are:
- **Specific** to the industry sector, not generic digital transformation buzzwords
- **Distinct** from each other — minimal overlap within the same cell
- **Horizon-appropriate** — an "act" candidate should be something actionable now, not a 10-year moonshot
- **Researchable** — the trend name and keywords should return meaningful results in a web search

Avoid:
- Generic trends that apply to every industry ("digital transformation", "AI adoption")
- Duplicates across cells (the same trend appearing in multiple places)
- Trends that don't fit the horizon timeframe
- Overly broad or vague names

## Validation

After generation, verify:
- Exactly 60 candidates total
- 5 per cell across all 12 cells (4 dimensions x 3 horizons)
- Each candidate has all required fields
- Source distribution is logged

If a cell has fewer than 5, generate additional candidates for that cell.

## Next Phase

Proceed to [phase-2-present.md](phase-2-present.md) with 60 candidates in memory.
