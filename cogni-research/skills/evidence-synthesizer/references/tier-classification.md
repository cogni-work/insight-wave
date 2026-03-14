# Tier Classification Methodology

## Overview

Evidence sources are classified into three reliability tiers based on publication type, peer review status, and institutional authority. This classification enables quality assessment of the research evidence base.

## Tier Definitions

### Tier 1: Academic & Peer-Reviewed Sources

**Characteristics:**
- Peer-reviewed journal articles
- Academic institution publications
- Systematic reviews and meta-analyses
- Conference proceedings (peer-reviewed)

**Examples:**
- Nature, Science, IEEE journals
- University research reports
- Cochrane reviews
- ACM/IEEE conference papers

**Reliability Score:** Highest (used for primary evidence)

### Tier 2: Industry Reports & Government Publications

**Characteristics:**
- Industry research reports
- Government agency publications
- Regulatory body documents
- Standards organizations

**Examples:**
- McKinsey, BCG, Gartner reports
- EPA, DOE, FDA publications
- ISO standards documents
- World Bank reports

**Reliability Score:** High (established institutional authority)

### Tier 3: Trade Publications & Professional Sources

**Characteristics:**
- Trade magazines and journals
- Professional association content
- Expert blogs and white papers
- News analysis (not primary reporting)

**Examples:**
- Forbes, Harvard Business Review
- Professional association newsletters
- Expert technical blogs
- Industry white papers

**Reliability Score:** Medium (valuable for context, verify with higher tiers)

## Tier Assignment Logic

### From Source Entity Frontmatter

```yaml
# Example source entity
---
url: "https://example.org/article"
tier: 2  # Extracted from here
access_date: "2025-01-15"
title: "Example Research Report"
---
```

**Extraction Pattern:**
```bash
# Extract tier from YAML frontmatter
tier=$(grep "^tier:" "$source_file" | sed 's/tier: *//' | tr -d '"')
```

**Validation:**
- tier must be 1, 2, or 3 (integer)
- Missing tier → Log warning, skip source
- Invalid tier → Log error, skip source

## Tier Distribution Analysis

### Calculation Formula

```bash
# Count sources per tier
tier1_count=$(count_sources_with_tier 1)
tier2_count=$(count_sources_with_tier 2)
tier3_count=$(count_sources_with_tier 3)

total_sources=$((tier1_count + tier2_count + tier3_count))

# Calculate percentages (round to whole numbers)
if [ $total_sources -gt 0 ]; then
  tier1_pct=$(echo "scale=0; ($tier1_count * 100) / $total_sources" | bc)
  tier2_pct=$(echo "scale=0; ($tier2_count * 100) / $total_sources" | bc)
  tier3_pct=$(echo "scale=0; ($tier3_count * 100) / $total_sources" | bc)
fi
```

### Distribution Quality Indicators

| Distribution Pattern | Interpretation |
|---------------------|----------------|
| >50% Tier 1 | Strong academic foundation |
| >60% Tier 2 | Industry/policy focus |
| >40% Tier 3 | May need additional validation |
| Balanced (30-40% each) | Comprehensive coverage |

### Quality Thresholds

**Recommended minimums:**
- At least 20% Tier 1 sources (academic credibility)
- No more than 50% Tier 3 sources (risk of bias)
- Distribution should reflect research question scope

## Markdown Table Output

Generate distribution table for catalog:

```markdown
## Source Reliability Distribution

| Tier | Description | Count | Percentage |
|------|-------------|-------|------------|
| Tier 1 | Academic, peer-reviewed | {tier1_count} | {tier1_pct}% |
| Tier 2 | Industry reports, government | {tier2_count} | {tier2_pct}% |
| Tier 3 | Trade publications, professional | {tier3_count} | {tier3_pct}% |
| **Total** | | **{total}** | **100%** |
```

## Anti-Hallucination Requirements

**CRITICAL: Extract tiers only from loaded entity files**

- Tier value must be present in source frontmatter
- Do NOT infer tier from URL domain
- Do NOT assume tier based on publisher name
- Do NOT fabricate tier classifications

**Verification Checkpoint:**
Before reporting tier distribution, verify:
- All tier values extracted from actual source entities
- No sources counted without explicit tier field
- Distribution percentages sum to ~100% (rounding)

## Error Handling

| Scenario | Recovery |
|----------|----------|
| Missing tier field | Skip source, log warning |
| Invalid tier value (not 1/2/3) | Skip source, log error |
| Zero sources | Return empty distribution table |
| Tier not numeric | Skip source, log error |

## Example: Complete Tier Analysis

**Input:** 138 loaded source entities

**Processing:**
1. Extract tier from each source frontmatter
2. Count: Tier 1 = 54, Tier 2 = 62, Tier 3 = 22
3. Calculate: 39%, 45%, 16%
4. Generate distribution table

**Output:**
```markdown
## Source Reliability Distribution

| Tier | Description | Count | Percentage |
|------|-------------|-------|------------|
| Tier 1 | Academic, peer-reviewed | 54 | 39% |
| Tier 2 | Industry reports, government | 62 | 45% |
| Tier 3 | Trade publications, professional | 22 | 16% |
| **Total** | | **138** | **100%** |

**Analysis:** Strong industry/government focus (45%) with solid academic foundation (39%). Low trade source percentage indicates well-vetted evidence base.
```
