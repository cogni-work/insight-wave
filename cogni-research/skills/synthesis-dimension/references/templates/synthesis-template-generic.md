# Synthesis Template: Generic Research Type

> **DEFAULT TEMPLATE.** This template is used when `arc_id` is empty, unset, or unrecognized in `.metadata/sprint-log.json`. When a recognized `arc_id` is present, the corresponding arc-specific template (e.g., `synthesis-template-corporate-visions.md`) is used instead. See `references/templates/` for all available arc templates.

## Overview

This template defines the structure for dimension synthesis documents when no arc is configured or when `research_type="generic"` (standard thematic grouping).

## Language Reference

**MANDATORY:** Use language-aware section headers based on PROJECT_LANGUAGE.

See [../language-templates.md](../language-templates.md) for:

- Section header translations (English/German)
- Evidence assessment table headers
- Navigation labels
- Language-specific formatting rules

**Quick Reference - Section Header Variables:**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `{HEADER_EXECUTIVE_SUMMARY}` | Executive Summary | Zusammenfassung |
| `{HEADER_STRATEGIC_CONTEXT}` | Strategic Context | Strategischer Kontext |
| `{HEADER_KEY_TRENDS}` | Key Trends | Kernerkenntnisse |
| `{HEADER_CROSS_CONNECTIONS}` | Cross-Trend Connections | Erkenntnisverknüpfungen |
| `{HEADER_RELATED_DIMENSIONS}` | Related Dimensions | Verwandte Dimensionen |
| `{HEADER_IMPLICATIONS}` | Implications & Recommendations | Implikationen & Empfehlungen |
| `{HEADER_EVIDENCE_ASSESSMENT}` | Evidence Assessment | Evidenzbewertung |
| `{HEADER_DOMAIN_CONCEPTS}` | Domain Concepts | Fachbegriffe |
| `{HEADER_REFERENCES}` | References | Referenzen |

---

## Document Structure

```markdown
---
title: "Dimension Synthesis: {Display Name}"
dimension: "{slug}"
research_type: "generic"
tags: [answer, synthesis-level/dimensions]
synthesis_date: "{ISO 8601}"
word_count: {N}
citation_count: {N}
trend_count: {N}
cross_connections: {N}
avg_confidence: {0.XX}
thematic_clusters: {N}
evidence_freshness: "{status}"
---

> **{LABEL_NAVIGATION}:** [{LABEL_BACK_TO_OVERVIEW}](../research-hub.md) | **{LABEL_CURRENT}:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

## {HEADER_EXECUTIVE_SUMMARY}

<!-- IMPORTANT: When mentioning concepts, trends, or claims in narrative text, wikilink to the entity file on first mention per section using format: [[entity-path|Display Title]] -->

{200-300 words summarizing key findings}

{Lead with most important trend}

{Connect to strategic implications}

{State confidence level based on evidence quality}

**Example with wikilinks:**
The dimension reveals that Digital Twins [[08-concepts/data/concept-digital-twins|Digital Twins]] are revolutionizing industrial IoT [[10-claims/data/claim-iiot-definition|IIoT]] implementations...

## {HEADER_STRATEGIC_CONTEXT}

{150-200 words explaining dimension importance}

{Why this dimension matters for the research question}

{Key challenges or opportunities addressed}

## {HEADER_KEY_TRENDS}

### {Trend 1 Title - Highest Ranked}

{80-120 words synthesizing trend}

{Core assertion with evidence}

{Strategic significance}

### {Trend 2 Title}

{80-120 words synthesizing trend}

### {Trend 3 Title}

{80-120 words synthesizing trend}

### {Trend 4 Title}

{80-120 words synthesizing trend}

### {Trend 5 Title}

{80-120 words synthesizing trend}

## {HEADER_CROSS_CONNECTIONS}

{150-200 words describing relationships}

{How trends reinforce each other}

{Causal or sequential relationships}

## {HEADER_RELATED_DIMENSIONS}

Explore connected research dimensions:

- **[{Related Dimension 1}](synthesis-{dim1-slug}.md):** {Relationship description}
- **[{Related Dimension 2}](synthesis-{dim2-slug}.md):** {Relationship description}

*For cross-dimensional synthesis, see the [Research Report Overview](../research-hub.md).*

## {HEADER_IMPLICATIONS}

**{HEADER_STRATEGIC_IMPLICATIONS}:**

- {Implication 1 with citation}
- {Implication 2 with citation}
- {Implication 3 with citation}

**{HEADER_TACTICAL_RECOMMENDATIONS}:**

- {Recommendation 1 with citation}
- {Recommendation 2 with citation}
- {Recommendation 3 with citation}

## {HEADER_APPENDIX}

### A. {HEADER_EVIDENCE_ASSESSMENT}

**Quality Overview:**

| {TH_METRIC} | {TH_VALUE} |
| ------ | ----- |
| {ROW_TOTAL_TRENDS} | {N} |
| {ROW_CLAIMS_REFERENCED} | {N} |
| {ROW_AVG_TREND_CONFIDENCE} | {0.XX} |
| {ROW_AVG_CLAIM_CONFIDENCE} | {0.XX} |
| {ROW_EVIDENCE_FRESHNESS} | {status} |
| {ROW_CROSS_CONNECTIONS} | {N} |
| {ROW_THEMATIC_CLUSTERS} | {N} |

**Quality Distribution:**
{...additional tables...}

**Verification Status:**
{...table...}

**Source Reliability:**
{...table...}

### B. Evidence Quality Analysis

{250-300 word narrative with subsections}

### C. {HEADER_DOMAIN_CONCEPTS}

Key terms relevant to this dimension:

- **{Term 1}**: {Definition}
- **{Term 2}**: {Definition}
- **{Term 3}**: {Definition}
- **{Term 4}**: {Definition}
- **{Term 5}**: {Definition}

### D. {HEADER_REFERENCES}

**{HEADER_TRENDS}:**

[1] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
[2] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
[3] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
[4] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
[5] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]

**{HEADER_SUPPORTING_CLAIMS}:**

[C1] [Claim Summary](10-claims/data/claim-slug.md) [[10-claims/data/claim-slug|Claim Title]] (confidence: 0.XX)
[C2] [Claim Summary](10-claims/data/claim-slug.md) [[10-claims/data/claim-slug|Claim Title]] (confidence: 0.XX)
...

---

*[← Back to Research Report Overview](../research-hub.md)*
```

---

## Section Guidelines

### Executive Summary (200-300 words)

**Purpose:** High-level synthesis for quick comprehension.

**Content requirements:**

- Lead with most significant finding
- Reference 3-5 trends with citations
- State overall confidence level
- Connect to strategic context

**Tone:** Authoritative, evidence-based, actionable.

**Citation density:** 3-5 citations minimum.

### Strategic Context (150-200 words)

**Purpose:** Establish why this dimension matters.

**Content requirements:**

- Connect to overall research question
- Explain dimension's strategic importance
- Identify key challenges addressed
- Reference dimension entity content

**Citation density:** 2-3 citations.

### Key Trends (400-600 words total)

**Purpose:** Synthesize each trend for the dimension.

**Per-trend requirements:**

- 80-120 words per trend
- Core assertion with evidence
- Strategic significance
- 1-2 citations per trend

**Order:** Highest-ranked trend first (from Phase 3 analysis).

**Grouping:** Can use thematic clusters if trends naturally group.

### Cross-Trend Connections (150-200 words)

**Purpose:** Show how trends relate to form cohesive narrative.

**Content requirements:**

- Identify causal relationships
- Highlight synergies
- Note sequential dependencies

### Related Dimensions

**Purpose:** Enable navigation between related dimension syntheses.

**Content requirements:**

- Link 2-4 most related dimensions
- Brief relationship description (how dimensions connect)
- Include back-link to hub document

**When to include:**

- Always include if project has 2+ dimensions
- Omit section if single-dimension project

**Relationship types to describe:**

- Complementary scope (e.g., "expands on technical aspects")
- Causal connection (e.g., "addresses implications of")
- Alternative perspective (e.g., "provides market view of")

### Implications & Recommendations (200-300 words)

**Purpose:** Translate trends into actionable guidance.

**Structure:**

- **Strategic implications:** For decision-makers (resource allocation, investment)
- **Tactical recommendations:** For practitioners (implementation steps)

**Requirements:**

- Each item with citation
- Prioritized by importance
- Actionable and specific

### Evidence Assessment

**Purpose:** Quantify evidence quality.

**Metrics to include:**

| Metric | Source |
| ------ | ------ |
| Total Trends | Count from loaded data |
| Claims Referenced | Unique claim count |
| Avg Trend Confidence | Mean of trend_confidence values |
| Avg Claim Confidence | Mean of claim confidence_scores |
| Evidence Freshness | From QUALITY_METRICS |
| Cross-Connections | Strong connections count |
| Thematic Clusters | Cluster count from analysis |

### Domain Concepts

**Purpose:** Define key terminology.

**Requirements:**

- 5-10 terms
- From loaded CONCEPTS registry
- Brief definitions with wikilinks to concept entities
- Relevant to dimension scope

**Format with wikilinks:**
- **[[08-concepts/data/concept-digital-twins|Digital Twins]]**: Virtual representations of physical assets
- **[[08-concepts/data/concept-ai-act|AI Act]]**: EU regulation for AI systems

**If no concepts loaded:** Omit section.

### References

**Purpose:** Enable navigation and verification.

**Format:** Dual citation (numbered markdown link + wikilink).

**Organization:**

1. Trends (numbered 1, 2, 3...)
2. Supporting Claims (numbered C1, C2, C3...)

---

## Word Count Targets

| Section | Target | Running Total |
| ------- | ------ | ------------- |
| Executive Summary | 200-300 | ~250 |
| Strategic Context | 150-200 | ~425 |
| Key Trends (5x100) | 400-600 | ~925 |
| Cross-Trend Connections | 150-200 | ~1100 |
| Implications | 200-300 | ~1350 |
| **Total** | **1,000-1,500** | |

**Note:** Appendix sections (Evidence Assessment, Evidence Quality Analysis, Domain Concepts, and References) don't count toward word target.

---

## Citation Format

**Inline citation (both formats required):**

```markdown
Evidence text<sup>[1](11-trends/data/trend-slug.md)</sup> [[11-trends/data/trend-slug|Display Title]].
```

**Reference entry:**

```markdown
[1] [Display Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Display Title]]
```

**Rules:**

1. Sequential numbering from 1
2. Both markdown link and wikilink
3. Vault-relative paths (no `../`, no absolute paths)
4. No `.md` extension in wikilinks

---

## Language Guidelines

**Reference:** See [../language-templates.md](../language-templates.md) for complete header translations.

**German (de):**

- Proper umlauts in body text (ä, ö, ü, ß)
- Formal business German
- Section headers in German (use translations from language-templates.md)
- File names/slugs in ASCII (ä→ae, ö→oe, ü→ue, ß→ss)
- Numbers: Use comma as decimal separator in prose (0,81 not 0.81)

**English (en):**

- Professional business English
- Section headers in English (use translations from language-templates.md)
- Avoid jargon without definition
- Numbers: Use period as decimal separator (0.81)

**Section Header Mapping (Quick Reference):**

| Section                        | English (en)                   | German (de)                  |
|--------------------------------|--------------------------------|------------------------------|
| Executive Summary              | Executive Summary              | Zusammenfassung              |
| Strategic Context              | Strategic Context              | Strategischer Kontext        |
| Key Trends                   | Key Trends                   | Kernerkenntnisse             |
| Cross-Trend Connections        | Cross-Trend Connections        | Erkenntnisverknüpfungen      |
| Related Dimensions             | Related Dimensions             | Verwandte Dimensionen        |
| Implications & Recommendations | Implications & Recommendations | Implikationen & Empfehlungen |
| Evidence Assessment            | Evidence Assessment            | Evidenzbewertung             |
| Domain Concepts                | Domain Concepts                | Fachbegriffe                 |
| References                     | References                     | Referenzen                   |

---

## Quality Checklist

Before completing synthesis:

- [ ] Navigation header: Present after frontmatter
- [ ] Executive Summary: 200-300 words, 3-5 citations
- [ ] Strategic Context: 150-200 words, 2-3 citations
- [ ] Key Trends: 400-600 words, all trends covered
- [ ] Cross-Trend Connections: 150-200 words
- [ ] Related Dimensions: 2-4 linked dimensions (if multi-dimension project)
- [ ] Implications: 200-300 words, citations for each item
- [ ] Appendix structure: H2 header present after Implications
- [ ] Appendix A: Evidence Assessment with all metrics accurate
- [ ] Appendix B: Evidence Quality Analysis present
- [ ] Appendix C: Domain Concepts (5-10 terms if applicable, skip if empty)
- [ ] Appendix D: References with all citations, dual format
- [ ] Footer: Back link to research-hub.md present
- [ ] Total word count: 1,000-1,500 (excluding appendix)
- [ ] All citations verified against filesystem
