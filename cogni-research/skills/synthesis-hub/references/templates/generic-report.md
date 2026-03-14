# Generic Research Report Template (Hub v3.0 Catalog)

This template provides structure for the hub report when research_type = "generic". Uses hub-and-spoke progressive disclosure pattern where the research catalog hub (300-450 words) provides scope overview and navigation to detailed analysis files.

**VERSION 3.0 ARCHITECTURE:** Hub ecosystem with 6 files for progressive disclosure. Hub is pure catalog/navigation. Executive summary and recommendations moved to synthesis-cross-dimensional.md.

---

## Language Template Reference

**MANDATORY:** Use section headers from `references/language-templates.md` section `12-synthesis (Hub Report)` based on project_language.

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `{HEADER_RESEARCH_OVERVIEW}` | Research Overview | Forschungsübersicht |
| `{HEADER_NAVIGATION_MAP}` | Navigation Map | Navigationsübersicht |
| `{HEADER_APPENDIX_GENERATION}` | Appendix: Report Generation | Anhang: Berichterstellung |
| `{HEADER_RESEARCH_FOUNDATION}` | Research Foundation | Forschungsgrundlage |
| `{HEADER_CROSS_DIMENSIONAL_ANALYSIS}` | Cross-Dimensional Analysis | Dimensionsübergreifende Analyse |
| `{HEADER_DIMENSION_DEEP_DIVES}` | Dimension Deep-Dives | Dimensions-Tiefenanalysen |
| `{HEADER_TREND_INTELLIGENCE}` | Trend Intelligence | Trendintelligenz |
| `{HEADER_TECHNICAL_DETAILS}` | Technical Details | Technische Details |

---

## Hub-and-Spoke Architecture v3.0

```text
research-hub.md (HUB - 300-450 words, catalog focus)
├── 00-research-scope.md (Methodology - 400-600 words)
├── 00-pipeline-metrics.md (Metrics - 300-400 words)
├── 12-synthesis/synthesis-cross-dimensional.md (Executive Summary + Recommendations + Patterns - 800-1,200 words)
├── 06-megatrends/README.md (Enhanced with narrative - adds 500-700 words)
├── 11-trends/README.md (Enhanced with landscape - adds 300-500 words)
└── 12-synthesis/synthesis-dim*.md (SPOKES - existing from Phase 3)
```

**Hub v3.0 provides:**

- Research Overview (80-120 words) - Scope, dimensions, entity counts
- Navigation Map (150-250 words) - Links to all analysis files
- Appendix (50-100 words) - Generation metadata

**Supporting files provide:**

- `12-synthesis/synthesis-cross-dimensional.md` - **Executive summary, strategic recommendations, cross-dimensional patterns**
- `00-research-scope.md` - Methodology, evidence scale, quality standards
- `06-megatrends/README.md` - Megatrend hierarchy, clusters, strategic synthesis
- `11-trends/README.md` - Kanban view, dimension briefs
- `00-pipeline-metrics.md` - Entity statistics, wikilink density

**Spokes provide (existing from Phase 3):**

- Detailed trend analysis (800-1,200 words per dimension)
- Per-dimension evidence with full citations
- Cross-trend connections within dimension
- Dimension-specific recommendations

---

## Report Structure (v3.0 Hub Navigation)

### YAML Frontmatter

```yaml
---
title: "[Research Question Title]"
research_type: "generic"
hub_type: "catalog"
tags: [catalog, navigation]
synthesis_framework: "Hub-and-Spoke Progressive Disclosure"
date_created: "[ISO 8601 timestamp]"
project_language: "[en|de]"
dimension_count: [number]
total_trends: [number]
total_concepts: [number]
total_findings: [number]
total_sources: [number]
confidence_level: "[High|Medium-High|Medium|Low]"
# Aggregated quality metrics (v2.0 - computed from dimension syntheses)
avg_evidence_strength: [0.0-1.0]
avg_strategic_relevance: [0.0-1.0]
avg_actionability: [0.0-1.0]
avg_novelty: [0.0-1.0]
verification_rate: [0.0-1.0]
source_tier_1_percentage: [0.0-1.0]
---
```

**NEW in v3.0:** `hub_type: "catalog"` field enables export tools to detect hub version and load supporting files. Entity counts added to frontmatter for easy access.

---

### Section 1: Research Overview (80-120 words)

**PURPOSE:** Provide research scope, context, and metadata inventory.

**Requirements:**

- State research question and dimension count
- List dimensions analyzed
- Provide entity counts (trends, concepts, findings, sources)
- Reference methodology file for details
- NO analysis or findings (pure catalog)
- NO citations (metadata only)

**Example:**

```markdown
## {HEADER_RESEARCH_OVERVIEW}

This research analyzes **[research question]** across **[N] dimensions**: [Dimension 1], [Dimension 2], [Dimension 3], [Dimension 4].

**Research Scope:**
- **Period:** [date range] or "See Research Scope"
- **Dimensions:** [N] analytical perspectives
- **Entity Counts:** [N] trends, [N] concepts, [N] findings, [N] sources
- **Evidence Quality:** [average confidence score] or "See Research Scope"

For methodology and research design, see [Research Scope](00-research-scope.md).
```

---

### Section 2: Navigation Map (150-250 words)

**PURPOSE:** Clear links to all detailed analysis files organized by purpose.

**Bridge from Research Overview:**

```markdown
---

## {HEADER_NAVIGATION_MAP}

**Use this navigation map to explore detailed analyses.** Each resource provides deeper context and evidence.
```

**Structure:**

```markdown
### {HEADER_RESEARCH_FOUNDATION}

| Resource | Description | Word Count |
|----------|-------------|------------|
| **[[00-research-scope\|Research Scope & Methodology]]** | Framework, evidence scale, quality standards | 400-600 |
| **[[00-initial-question/data/question-{slug}\|Research Question]]** | Refined research question and scope boundaries | 50-150 |

### {HEADER_CROSS_DIMENSIONAL_ANALYSIS}

| Resource | Description | Word Count |
|----------|-------------|------------|
| **[[12-synthesis/synthesis-cross-dimensional\|Cross-Dimensional Synthesis]]** | Executive summary, strategic recommendations, patterns | 800-1,200 |

### {HEADER_DIMENSION_DEEP_DIVES}

| Dimension | Key Focus | Full Analysis |
|-----------|-----------|---------------|
| **{Dimension 1}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug1}]] |
| **{Dimension 2}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug2}]] |
| **{Dimension 3}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug3}]] |
| **{Dimension 4}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug4}]] |

### {HEADER_TREND_INTELLIGENCE}

| Resource | Description | Entity Count |
|----------|-------------|--------------|
| **[[06-megatrends/README\|Megatrends Overview]]** | Hierarchy, clusters, strategic synthesis | {N} megatrends |
| **[[11-trends/README\|Trends Landscape]]** | Kanban view, dimension briefs | {N} trends |

### {HEADER_TECHNICAL_DETAILS}

| Resource | Description |
|----------|-------------|
| **[[00-pipeline-metrics\|Pipeline Metrics]]** | Entity statistics, wikilink density |
```

**What to include:**

- Clear table structure for easy scanning
- 1-sentence descriptions of each resource
- Word counts or entity counts where relevant
- Wikilinks to all supporting files

**What NOT to include:**

- Detailed analysis (moved to separate files)
- Full dimension summaries (use 1-sentence focus)
- Content that duplicates supporting files

---

### Section 3: Appendix - Report Generation

**PURPOSE:** Technical metadata about report generation.

**Bridge from Navigation Map:**

```markdown
---

## {HEADER_APPENDIX_GENERATION}
```

**Structure:**

```markdown
**Framework:** Hub-and-Spoke Progressive Disclosure v3.0
**Generated:** [ISO 8601]
**Hub Skill:** synthesis-hub
**Spoke Skill:** synthesis-dimension
**Architecture:** Research Catalog + Independent Files

[[research-methodology]]
```

**What to include:**

- Framework version
- Generation timestamp
- Skill information
- Architecture type
- Link to methodology

**What NOT to include:**

- Detailed pipeline metrics (moved to 00-pipeline-metrics.md)
- Entity statistics (moved to 00-pipeline-metrics.md)
- Quality metrics (moved to 00-research-scope.md)
- Executive summary (moved to synthesis-cross-dimensional.md)

---

## Citation Requirements

| Section | Citations | Citation Target |
|---------|-----------|-----------------|
| Research Overview | 0 | N/A (metadata only) |
| Navigation Map | 0 | Wikilinks to files |
| Appendix | 0 | N/A |
| **Total** | **0** | **Pure catalog** |

**Note:** Hub v3.0 catalog has NO citations because it contains no analysis. All analytical content (with citations) moved to synthesis-cross-dimensional.md and dimension syntheses.

---

## Quality Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Word count | 300-450 | Hub only (85% reduction from v2.4) |
| Citation density | 0 | Pure catalog (no analysis) |
| Navigation clarity | 100% | All supporting files linked |
| Catalog focus | High | Scope + inventory only |
| Progressive disclosure | 6 files | Hub + 5 supporting files |

---

## Progressive Disclosure Flow (v3.0 Catalog Ecosystem)

```text
Reader opens research-hub.md (catalog hub - 300-450 words)
         ↓
CATALOG LAYER (Scope + Navigation - 300-450 words)
├─ Reads Research Overview (80-120 words) - "What was researched"
└─ Scans Navigation Map (150-250 words) - "Where to find analysis"
         ↓
CHOICE POINT: What do I need?
         ↓
TIER 1 OPTIONS (Executive):
└─ [[synthesis-cross-dimensional]] - Exec Summary + Recommendations + Patterns (800-1,200 words)
         ↓
TIER 2 OPTIONS (Deep-Dive):
├─ [[00-research-scope]] - Methodology (400-600 words)
├─ [[06-megatrends/README]] - Megatrend narrative (500-700 words)
├─ [[11-trends/README]] - Trend landscape (300-500 words)
├─ [[00-pipeline-metrics]] - Technical metrics (300-400 words)
└─ [[12-synthesis/synthesis-{dim}]] - Dimension analysis (800-1,200 words)
         ↓
Reader explores only what they need
         ↓
Returns to catalog for different angle
```

**v3.0 Catalog Benefits:**

- **85% reading reduction:** 300-450 words vs. 1,900-2,850 for hub
- **Clear separation:** Catalog = navigation, synthesis = findings
- **Better RAG:** Hub embeddings = structure, synthesis embeddings = content
- **Scalable:** Hub size constant regardless of research depth
- **User control:** Readers choose their depth
- **Single source of truth:** No content duplication

---

## Backward Compatibility

Export tools detect hub version via `hub_type` in frontmatter:

- **v3.0 projects:** `hub_type: "catalog"` → Load hub ecosystem (6 files), executive summary in synthesis-cross-dimensional.md
- **v2.x projects:** No hub_type field → Load single research-hub.md with embedded executive summary
- **Graceful degradation:** No breaking changes

---

## Version History

| Version | Structure | Word Count | Key Change |
|---------|-----------|------------|------------|
| v2.4.0 | Single file, Pyramid Principle | 1,900-2,850 | IS-DOES-MEANS, removed meta-analysis |
| v3.0.0 | Hub ecosystem, 6 files | 300-450 (hub) | Research catalog, exec summary moved to synthesis file |
