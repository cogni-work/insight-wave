---
tags: [finding, source/web, dimension/{dimension-slug}]
title: "{title}"
dc:creator: "findings-creator"
dc:title: "{title}"
dc:date: "{ISO 8601 timestamp}"
dc:type: "finding"
dc:source: "{source_url}"

# ========================================
# SCHEMA VERSION (backward compatibility tracking)
# ========================================

# Schema version 3.0 introduced comprehensive 5-section structure
# Version 2.0 added quality assessment checkpoint
# Version 1.0 basic finding structure
schema_version: "3.0"

# ========================================
# MANDATORY FIELDS (validation enforced)
# ========================================

# REQUIRED: Link to parent query batch
# Format: [[03-query-batches/data/{question-id}-batch]]
# Populated by: findings-creator during finding creation
batch_id: "[[03-query-batches/data/{question-id}-batch]]"

# REQUIRED: Dimension identifier (e.g., "market-size", "competition")
# Derivation: Extracted from batch_id wikilink if not explicitly provided
# Populated by: findings-creator during finding creation
dimension_id: "[[01-research-dimensions/data/{dimension-slug}]]"

# REQUIRED: Unique identifier for this finding
# Format: UUID v4 (e.g., "a1b2c3d4-e5f6-7890-abcd-ef1234567890")
# Populated by: findings-creator during finding creation
finding_uuid: "{UUID v4}"

# REQUIRED: Original source URL where finding was discovered
# Format: Valid HTTP/HTTPS URL
# Populated by: findings-creator during finding creation
source_url: "{URL}"

# ========================================
# CONTENT RETRIEVAL METADATA (schema v3.0)
# ========================================

# Content source indicator: "webfetch" (enhanced) or "snippet" (fallback)
# Populated by: findings-creator Step 4.3.5 (WebFetch Enhanced Content Retrieval)
content_source: "{webfetch|snippet}"

# WebFetch success flag
# Populated by: findings-creator Step 4.3.5
webfetch_success: {true|false}

# Enhanced content retrieved flag
# Populated by: findings-creator Step 4.3.5
enhanced_content_retrieved: {true|false}

# ========================================
# QUALITY ASSESSMENT METADATA (schema v2.0+)
# ========================================

# Composite quality score (0.00-1.00)
# Populated by: findings-creator Step 4.25 (Quality Assessment Checkpoint)
quality_score: {0.00-1.00}

# Dimension scores (4-dimension framework)
quality_dimensions:
  topical_relevance: {0.00-1.00}      # Weight: 40%
  content_completeness: {0.00-1.00}   # Weight: 30%
  source_reliability: {0.00-1.00}     # Weight: 20%
  evidentiary_value: {0.00-1.00}      # Weight: 10%

# Quality status (PASS if ≥0.50, FAIL if <0.50)
quality_status: "{PASS|FAIL}"

# Quality assessment timestamp
quality_assessed_at: "{ISO 8601 timestamp}"

# Quality framework version
quality_framework_version: "1.0"

# Content word count (completeness metric)
content_word_count: {integer}

# ========================================
# SOURCE LINKAGE (populated by source-creator)
# ========================================

# REQUIRED: Link to source entity (initially empty, populated after source creation)
# Format: [[07-sources/data/source-{uuid}]] or empty string ""
# Populated by: source-creator during Phase 3.6 source entity creation
source_id: ""

# ========================================
# METADATA FIELDS (optional)
# ========================================

# Publisher information (hints for source-creator)
# Used by source-creator to match/create publisher entities
publisher_hint: "{publisher}"
publisher_type_hint: "{type}"

# Search execution metadata
# Success level scale: 0 (failed) to 5 (highly relevant)
search_success_level: {0-5}
created_at: "{ISO 8601 timestamp}"
---

# {Title}

## Content

{Substantive paragraph summarizing the finding - minimum 150 words, maximum 300 words}

{Include: specific trends, contextual information, key takeaways, nuanced understanding}
{Avoid: generic summaries, vague statements, unsupported claims, repetition of title}

**Requirements:**
- **Word count**: 150-300 words
- **Depth**: Provide substantive analysis, not just surface-level summary
- **Trends**: Include specific details, statistics, or contextual information
- **Clarity**: Use clear, direct language appropriate for research corpus
- **Source alignment**: All content must derive from retrieved source (WebFetch or snippet)

**Good Content Example:**
"The German motorhome pitch booking market is experiencing consolidation, with three major platforms controlling approximately 75% of market share as of 2024. Market leader PitchFinder operates over 3,500 partner sites across Germany, followed by CampConnect (2,100 sites) and StellplatzHub (1,800 sites). Industry analysts attribute this concentration to network effects, where platforms with more listings attract more users, creating self-reinforcing growth. Recent market entrants face significant barriers due to the established platforms' exclusive agreements with popular campsite operators. The market grew 22% year-over-year in 2023, driven by increased domestic tourism and the growing popularity of van life culture among millennials."

**Poor Content Example:**
"This article discusses competitors in the motorhome pitch booking market. There are several companies competing in this space. The market is growing and there is competition."

## Key Trends

- {Specific trend 1 with concrete details, statistics, or measurable aspects}
- {Specific trend 2 with actionable information or contextual nuance}
- {Specific trend 3 with evidence-based claims or comparative analysis}
- {Additional trends as needed, minimum 3, maximum 6}

**Requirements:**
- **Count**: Minimum 3 bullet points, maximum 6 bullet points
- **Specificity**: Each bullet must contain concrete, actionable information
- **Substance**: Avoid generic statements like "The article discusses..." or "The source mentions..."
- **Evidence**: Include specific data points, statistics, or measurements where available
- **Relevance**: Each trend must directly relate to the research question

**Good Trends Example:**
- Market leader PitchFinder controls 42% market share with 3,500+ partner sites (2024 data)
- Industry consolidation driven by network effects and exclusive campsite operator agreements
- Market grew 22% YoY in 2023, driven by domestic tourism and millennial van life adoption
- New entrants face high barriers due to incumbent exclusive partnerships and user lock-in

**Poor Trends Example:**
- The article discusses market competitors
- There are several companies in this space
- Competition is increasing

## Methodology & Data Points

{Research methodology description if available: survey, interview, analysis, case study, etc.}
{Data points: sample sizes, timeframes, geographic scope, statistical measures, data sources}
{If no explicit methodology: describe information source type, publication context, and state that no formal methodology was disclosed}

**Requirements:**
- **Minimum length**: 2-3 sentences
- **Methodology**: Describe research approach if disclosed (e.g., "Survey of 500 German campsite operators conducted Q3 2023")
- **Data points**: Include specific metrics like sample sizes, timeframes, geographic coverage, confidence intervals
- **Transparency**: If methodology is not explicitly stated, acknowledge this: "Information source type: Industry publication. No formal research methodology disclosed."
- **Context**: Explain data collection approach and any limitations

**Good Methodology Example:**
"Study conducted by German Tourism Association (DTV) based on Q4 2023 survey of 500 German campsite operators and analysis of booking platform transaction data spanning 18 months (June 2022 - December 2023). Market share estimates derived from aggregated booking volumes across participating sites. Geographic scope limited to Germany; excludes cross-border bookings. Margin of error ±3.5% at 95% confidence level."

**Poor Methodology Example:**
"The data comes from various sources."

**Disclaimer Example (when methodology unavailable):**
"Information source type: Industry news article published in Camping & Caravaning Trade Journal (March 2024). No formal research methodology disclosed. Statistics cited without source attribution. Consider as directional market intelligence rather than validated research data."

## Relevance Assessment

**Composite Score**: {0.00-1.00} | **Threshold**: 0.50 | **Status**: {PASS|FAIL}

**Dimension Scores:**
- Topical Relevance (40%): {0.00-1.00} - {Brief rationale explaining alignment with refined question}
- Content Completeness (30%): {0.00-1.00} - {Brief rationale explaining substantive depth and data richness}
- Source Reliability (20%): {0.00-1.00} - {Brief rationale explaining source tier and credibility}
- Evidentiary Value (10%): {0.00-1.00} - {Brief rationale explaining research utility and citeability}

**Overall Rationale**: {2-3 sentences explaining why this finding matters for the research question, what specific value it provides, and how it contributes to answering the dimension inquiry}

**Requirements:**
- **Auto-generated**: This section is automatically generated from Step 4.25 quality checkpoint scores
- **Transparency**: Shows complete scoring breakdown with rationales
- **Research value**: Overall rationale explains contribution to research corpus

**Example:**
```
**Composite Score**: 0.78 | **Threshold**: 0.50 | **Status**: PASS

**Dimension Scores:**
- Topical Relevance (40%): 0.85 - Directly answers refined question about top competitors with specific company names and market positioning
- Content Completeness (30%): 0.75 - Contains 287 words with multiple data points, specific statistics, and contextual market analysis
- Source Reliability (20%): 0.80 - Published by German Tourism Association (DTV), industry authority with research credentials
- Evidentiary Value (10%): 0.90 - Includes survey methodology, sample size (n=500), timeframe, and specific market share percentages

**Overall Rationale**: This finding provides concrete competitor identification with quantitative market share data, addressing the core research question. The DTV source adds credibility, and the disclosed methodology allows for evidence quality assessment. Highly citeable for competitive landscape analysis.
```

## Source

**URL**: {source_url}
**Source Entity**: {Will be created in 07-sources/data/ by source-creator OR [[07-sources/data/source-{uuid}]] if already created}
**Backlink**: {source_id will be populated after source creation OR [[07-sources/data/source-{uuid}]]}
**Publisher**: {publisher_hint} ({publisher_type_hint})

---

# Template Usage Notes

## Backward Compatibility

**Schema Version 3.0** (current):
- Comprehensive 5-section structure (Content, Key Trends, Methodology & Data Points, Relevance Assessment, Source)
- Enhanced content retrieval metadata (content_source, webfetch_success, enhanced_content_retrieved)
- All quality assessment fields from v2.0

**Schema Version 2.0**:
- Quality assessment checkpoint (4-dimension scoring)
- Basic 2-section structure (Source, Content)

**Schema Version 1.0**:
- Basic finding structure (Source, Content)
- No quality assessment

**Migration**: Findings with schema_version 1.0 or 2.0 remain valid. Updated findings-creator workflow (Phase 4, Steps 4.3.5, 4.4.5, 4.5.5) generates v3.0 findings automatically.

## Section Requirements Summary

| Section | Word Count | Bullet Count | Source |
|---------|------------|--------------|--------|
| Content | 150-300 words | N/A | WebFetch or snippet |
| Key Trends | Variable | 3-6 bullets | Extracted from content |
| Methodology & Data Points | 2-3 sentences minimum | N/A | Source or disclaimer |
| Relevance Assessment | Auto-generated | N/A | Step 4.25 scores |
| Source | Standard metadata | N/A | WebSearch + entity creation |

## Validation Checkpoints

**Step 4.5.5: Section Validation Checkpoint** verifies:
- All 5 sections present
- Content: 150-300 words
- Key Trends: 3-6 bullet points
- Methodology: 2+ sentences or explicit disclaimer
- Relevance Assessment: contains composite score and dimension scores

**Failure handling**: If validation fails, finding is NOT created (anti-hallucination safeguard).

## Anti-Hallucination Safeguards

1. **Content source validation**: All content from WebFetch (enhanced) or snippet (fallback) - no fabrication
2. **URL validation**: Source URLs validated from WebSearch results before WebFetch invocation
3. **Quality auto-generation**: Relevance Assessment auto-generated from calculated scores only
4. **Explicit disclaimers**: Methodology section requires explicit disclaimer if no formal methodology available
5. **Section validation**: Complete 5-section structure enforced before entity creation
