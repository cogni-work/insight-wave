# Phase 4a: Hub Ecosystem Generation (Cross-Dimensional)

**Execution:** ALWAYS (not conditional) | **Framework:** Hub-and-Spoke Progressive Disclosure + Pyramid Principle

**Objective:** Generate hub ecosystem with lightweight navigation hub (600-900 words) plus supporting analysis files, structured using McKinsey Pyramid Principle (Answer First → Context → Evidence).

**Critical:** Hub adds unique value through navigation and cross-dimensional patterns. Detailed analysis is in separate files for progressive disclosure.

**Inputs:** Dimension syntheses (Phase 3), initial question, DIMENSION_REGISTRY, entity counts

**Outputs (v3.0 Hub Ecosystem - 6 files):**
1. `research-hub.md` - Research content catalog (300-450 words)
2. `00-research-scope.md` - Methodology and evidence scale (400-600 words)
3. `00-pipeline-metrics.md` - Entity statistics and metrics (300-400 words)
4. `12-synthesis/synthesis-cross-dimensional.md` - Pattern analysis (400-600 words)
5. `06-megatrends/README.md` - Enhanced with narrative (adds 500-700 words)
6. `11-trends/README.md` - Enhanced with landscape (adds 300-500 words)

---

## Hub-and-Spoke + Pyramid Principle (v3.0 Research Catalog)

The hub report is a **research content catalog** focused on navigation and inventory with **progressive disclosure through separate files**:

**HUB FILE (research-hub.md - 300-450 words):**

**RESEARCH OVERVIEW (80-120 words):**
1. **Research Overview** - What was researched (scope, dimensions, entity counts)

**NAVIGATION STRUCTURE (150-250 words):**
2. **Navigation Map** - Links to detailed analysis files organized by purpose

**TECHNICAL METADATA (50-100 words):**
3. **Appendix** - Report generation info

**SUPPORTING FILES (separate files for analysis):**

- `12-synthesis/synthesis-cross-dimensional.md` - Executive summary + findings (400-600 words)
- `00-research-scope.md` - Methodology (400-600 words)
- `06-megatrends/README.md` - Megatrend narrative (adds 500-700 words)
- `11-trends/README.md` - Trend landscape (adds 300-500 words)
- `00-pipeline-metrics.md` - Pipeline metrics (300-400 words)
- Dimension syntheses - Already exist from Phase 3

**The hub v3.0 IS:**

- Research artifact catalog (trends, concepts, findings, sources)
- Navigation dashboard (where to find what)
- Metadata overview (counts, dates, scope)

**The hub v3.0 is NOT:**

- Synthesis document (findings/recommendations moved to synthesis files)
- Executive summary (that's synthesis-cross-dimensional.md)
- Detailed analysis (moved to separate files)

---

## Variables Reference

| Variable | Source | Example |
|----------|--------|---------|
| `${PROJECT_PATH}` | Phase 1 config | `/research/project-xyz` |
| `research_type` | Phase 2 analysis | `generic` |
| `project_language` | Project config | `en` / `de` |
| `DIMENSION_REGISTRY` | Phase 3 extraction | Array of dimension metadata |

---

## Word Count Targets (v3.0 Hub Ecosystem)

### Hub File (research-hub.md)

| Section | Target | Citations | Purpose |
|---------|--------|-----------|---------|
| Research Overview | 80-120 | 0 | Scope + Metadata |
| Navigation Map | 150-250 | 0 | Navigation Structure |
| Appendix | 50-100 | 0 | Technical Metadata |
| **Hub Total** | **300-450** | **0** | Pure Catalog |

### Supporting Files

| File | Target | Purpose |
|------|--------|---------|
| 00-research-scope.md | 400-600 | Methodology, evidence scale |
| 00-pipeline-metrics.md | 300-400 | Entity statistics, metrics |
| synthesis-cross-dimensional.md | 400-600 | Cross-dimensional patterns |
| 06-megatrends/README.md (enhancement) | +500-700 | Megatrend narrative |
| 11-trends/README.md (enhancement) | +300-500 | Trend landscape |
| **Supporting Total** | **~2,500** | |

**Hub v3.0 Benefits:**
- Pure navigation hub: 300-450 words (85% reduction from v2.x)
- Clear separation: catalog vs. synthesis
- Better RAG performance: hub embeddings = navigation, synthesis embeddings = findings
- Scalable: hub size constant regardless of research depth
- Executive answers in synthesis-cross-dimensional.md (400-600 words)

---

## Error Handling

**Insufficient dimension syntheses:**

- IF synthesis_count < 2 → Log warning, reduce cross-dimensional analysis scope
- IF synthesis_count == 1 → Skip Cross-Dimensional Patterns section entirely

**Missing executive summary in spoke:**

- IF no Executive Summary section found → Use first 150 words of spoke content
- Log: "Executive Summary not found in synthesis-{dim}.md, using content excerpt"

---

## Step 0.5: Initialize Phase 4 TodoWrite

Add step-level todos in **hub ecosystem generation order**:

```markdown
USE: TodoWrite tool

ADD (step-level todos in execution order):
1. Step 1: Load report template [pending]
2. Step 1.5: Generate 00-research-scope.md [pending]
3. Step 2: Generate Research Overview Section [pending]
4. Step 4.7: Generate 12-synthesis/synthesis-cross-dimensional.md (with Executive Summary + Strategic Recommendations) [pending]
5. Step 5.5: Enhance 06-megatrends/README.md [pending]
6. Step 5.7: Enhance 11-trends/README.md [pending]
7. Step 6: Write research-hub.md (research catalog hub) [pending]
8. Step 7: Generate 00-pipeline-metrics.md [pending]
9. Step 8: Mark Phase 4 Complete [pending]
```

**Note:** This version generates 6 files total: lightweight hub + 5 supporting files for progressive disclosure.

---

## Step 0.7: Language Enforcement Check

⚠️ **BEFORE GENERATING ANY CONTENT:**

IF `project_language == "de"`:

```
╔═══════════════════════════════════════════════════════════════════╗
║  GERMAN TEXT REQUIREMENT - READ BEFORE WRITING                    ║
╠═══════════════════════════════════════════════════════════════════╣
║  ALL body text and headings MUST use proper umlauts:              ║
║    ä (not ae)  ö (not oe)  ü (not ue)  ß (not ss)                ║
║                                                                   ║
║  ✓ Correct: "grundsätzlich", "für", "übergreifend"               ║
║  ✗ Wrong:   "grundsaetzlich", "fuer", "uebergreifend"            ║
║                                                                   ║
║  ASCII only for: file names, slugs, YAML identifiers              ║
╚═══════════════════════════════════════════════════════════════════╝
```

**Self-check before each section:** Am I using proper umlauts (ä, ö, ü, ß)?

---

## Step 0.8: Heading Language Selection

IF `project_language == "de"`, use German headings from this translation table:

| English (default) | German (de) |
|-------------------|-------------|
| Executive Summary | Zusammenfassung |
| Strategic Recommendations | Strategische Empfehlungen |
| Research Question | Forschungsfrage |
| Cross-Dimensional Patterns | Dimensionsübergreifende Muster |
| Reinforcing Findings | Verstärkende Erkenntnisse |
| Tensions and Trade-offs | Spannungen und Zielkonflikte |
| Emergent Implications | Emergente Implikationen |
| Dimensional Analysis | Dimensionale Analyse |
| Trend Landscape | Trendlandschaft |
| Appendix: Technical Details | Anhang: Technische Details |
| Report Generation | Berichterstellung |
| For Detailed Methodology | Zur detaillierten Methodik |

**Usage:** Apply German headings consistently throughout the entire report when `project_language == "de"`.

---

## Step 1: Load Report Template

**Confirm research_type = "generic"**

**Template Path:** `references/templates/generic-report.md`

**Pyramid Principle Structure Overview:**

| Section | Word Target | Pyramid Level | Content Source |
|---------|-------------|---------------|----------------|
| Executive Summary | 200-300 | LEVEL 1 (Answer) | Synthesize from dimension summaries |
| Strategic Recommendations | 200-400 | LEVEL 1 (Action) | Cross-dimensional implications |
| Research Question | 50-150 | LEVEL 2 (Context) | Initial question entity |
| Cross-Dimensional Patterns | 300-500 | LEVEL 3 (Mechanisms) | NEW hub synthesis |
| Dimensional Analysis | 150-200 × N | LEVEL 3 (Detailed evidence) | Dimension syntheses (IS-DOES-MEANS) |
| Trend Landscape | - | LEVEL 3 (Reference) | Kanban table only |
| Appendix | - | LEVEL 4 (Technical) | Metrics placeholder |

**TodoWrite:** Mark Step 1 as completed, Step 1.5 as in_progress.

---

## Step 1.5: Generate 00-research-scope.md

**NEW:** Extract Research Scope & Methodology into separate file for progressive disclosure.

**Location:** `${PROJECT_PATH}/00-research-scope.md`

**Goal:** 400-600 words documenting research methodology and evidence scale.

**Content to Include:**

1. **Research Approach:** Framework used (Hub-and-Spoke + Pyramid Principle)
2. **Evidence Scale Metrics:**
   - Dimension count
   - Total trends identified
   - Total findings analyzed
   - Evidence chain depth
3. **Quality Standards:**
   - PICOT/FINER validation
   - Dual-layer scoring (evidence reliability + claim quality)
   - Cross-dimensional verification
4. **Research Boundaries:** What was included/excluded in scope

**Template Structure:**

```markdown
---
title: "Research Scope & Methodology"
doc_type: "methodology"
related_report: "[[research-hub]]"
date_created: "{ISO 8601}"
---

# Research Scope & Methodology

## Research Approach

{150-200 words on framework: Hub-and-Spoke, Pyramid Principle, dimension-based structure}

## Evidence Scale

{100-150 words with metrics from DIMENSION_REGISTRY and entity counts}

**Research Dimensions:** {N} strategic dimensions
**Trends Analyzed:** {N} trends across {N} dimensions
**Findings Base:** {N} findings from web research
**Evidence Chain Depth:** Findings → Claims → Concepts → Megatrends → Trends

## Quality Standards

{150-200 words on PICOT/FINER, dual-layer scoring, verification methods}

## Research Boundaries

{100-150 words on what was included/excluded, time horizon, geographic scope}

*For full research report: [[research-hub]]*
```

**Data Sources:**
- Load from DIMENSION_REGISTRY (dimension count)
- Count trend files: `${PROJECT_PATH}/11-trends/data/trend-*.md`
- Count finding files: `${PROJECT_PATH}/02-findings/data/finding-*.md`
- Extract from project config: date_created, research_type

**TodoWrite:** Mark Step 1.5 as completed, Step 2 as in_progress.

---

## Step 2: Generate Research Overview Section

**PURPOSE:** Provide research scope, context, and metadata inventory.

**Goal:** 80-120 words documenting what was researched and what entities exist.

<research_overview_thinking>

Before writing:

1. Extract research question from initial question entity
2. Count dimensions from DIMENSION_REGISTRY
3. Count entity files:
   - Trends: `${PROJECT_PATH}/11-trends/data/trend-*.md`
   - Concepts: `${PROJECT_PATH}/08-concepts/data/concept-*.md`
   - Findings: `${PROJECT_PATH}/04-findings/data/finding-*.md`
   - Sources: `${PROJECT_PATH}/09-citations/data/source-*.md`
4. Calculate average confidence if available
5. Extract date range or timeframe if applicable

</research_overview_thinking>

**Structure:**

```markdown
## Research Overview

This research analyzes **{research question}** across **{N} dimensions**: {dimension names}.

**Research Scope:**
- **Period:** {date range or "See Research Scope"}
- **Dimensions:** {N} analytical perspectives
- **Entity Counts:** {N} trends, {N} concepts, {N} findings, {N} sources
- **Evidence Quality:** {average confidence score or "See Research Scope"}

For methodology and research design, see [Research Scope](00-research-scope.md).
```

**Writing Standards:**

- Language consistency (project_language from config)
- **German (de): Use proper umlauts (ä, ö, ü, ß) in all body text**
- Factual, inventory-focused tone
- No analysis or findings (that's in synthesis files)
- NO citations (pure metadata)

**TodoWrite:** Mark Step 2 as completed, Step 4.7 as in_progress.


---

## Step 4.7: Generate 12-synthesis/synthesis-cross-dimensional.md

**UPDATED:** This file now contains Executive Summary + Strategic Recommendations + Cross-Dimensional Patterns (replaces hub's removed sections).

**Location:** `${PROJECT_PATH}/12-synthesis/synthesis-cross-dimensional.md`

**Goal:** 800-1,200 words with complete cross-dimensional analysis (REPLACES hub's Executive Summary).

**Content Structure:**

```markdown
---
title: "Cross-Dimensional Synthesis"
doc_type: "cross_dimensional_synthesis"
related_report: "[[research-hub]]"
date_created: "{ISO 8601}"
dimensions_analyzed: {N}
# Arc metadata — ONLY when ARC_ID is set in sprint-log.json (delete these 3 lines if no arc)
arc_id: "{ARC_ID}"
arc_display_name: "{ARC_DISPLAY_NAME}"
arc_elements: ["{Element 1 name}", "{Element 2 name}", "{Element 3 name}", "{Element 4 name}"]
---

# Cross-Dimensional Synthesis

> **Executive Summary:** This synthesis provides the strategic answer to the research question by analyzing patterns across all {N} dimensions. For dimension-specific details, see individual dimension syntheses.

---

## Executive Summary

{200-300 words directly answering the research question}

**Structure:**
- **P1:** Direct answer to research question + primary cross-dimensional finding
- **P2:** Key findings across dimensions (2-3 bullet points)
- **P3:** Strategic implications and call to action

**Writing Standards:**
- Language consistency (project_language from config)
- **German (de): Use proper umlauts (ä, ö, ü, ß) in all body text**
- Evidence-based tone
- Active voice, concrete specificity
- Citations to dimension syntheses (not raw entities): `<sup>[N](synthesis-{dim-slug}.md)</sup>`
- **Wikilinks:** When mentioning concepts, trends, or claims, wikilink on first mention: `[[entity-path|Display Title]]`

---

## Strategic Recommendations

**These findings demand strategic action.** The following recommendations leverage cross-dimensional insights to address the research question with maximum impact.

{200-400 words with 3-5 prioritized recommendations}

**Structure:**

### 1. {High-Priority Cross-Dimensional Action}

**Priority:** High
**Dimensions Addressed:** {Dim 1}, {Dim 2}

{80-100 words following IS→DOES→MEANS implicit flow}<sup>[N](synthesis-{dim}.md)</sup>

### 2. {Medium-Priority Action}

**Priority:** Medium
**Dimensions Addressed:** {Dim 2}, {Dim 3}

{60-80 words following IS→DOES→MEANS implicit flow}

**IS-DOES-MEANS Implicit Structure (No Labels):**
- First sentence: what (IS)
- Middle content: how/actions (DOES)
- Final content: why/impact (MEANS)

---

## Cross-Dimensional Patterns

**To understand these recommendations, we examine how strategic dimensions interact.** The following patterns show how dimensions reinforce, conflict, and create emergent dynamics.

### Reinforcing Findings

{150-200 words on how dimensions support each other}

### Tensions and Trade-offs

{100-150 words on conflicts or trade-offs between dimensions}

### Emergent Implications

{100-150 words on what only becomes visible cross-dimensionally}

### Dimension Relationship Diagram

```mermaid
flowchart TB
    {DIM1}[Dimension 1]
    {DIM2}[Dimension 2]
    {DIM1} -->|relationship| {DIM2}
```

*Figure: Cross-dimensional relationships and dependencies*

---

*For full research catalog: [[research-hub]]*
*For dimension-specific analysis: See [[synthesis-{dim}]] files*
```

**Content Sources:**
1. **Executive Summary:** Synthesize from dimension summaries (was Step 2)
2. **Strategic Recommendations:** Cross-dimensional implications (was Step 2.5)
3. **Cross-Dimensional Patterns:** Pattern analysis (was Step 4)

**TodoWrite:** Mark Step 4.7 as completed, Step 5.5 as in_progress.


**Template:**

```markdown
| {TH_DIMENSION} | {TH_ACT_HORIZON} | {TH_PLAN_HORIZON} | {TH_OBSERVE_HORIZON} |
|----------------|------------------|-------------------|----------------------|
| **{Dimension 1}** | **M:** [[06-megatrends/data/megatrend-{slug}\|{title}]]<br>**T:** [[11-trends/data/trend-{slug}\|{title}]] | ... | ... |
| **{Dimension 2}** | ... | ... | ... |
| **{LABEL_GENERAL}** | ... | ... | ... |

{LEGEND_KANBAN_TABLE}

<!-- kanban-board -->
```

**Note:** The markdown table provides a static fallback for readers viewing the markdown directly (Obsidian, GitHub). The `<!-- kanban-board -->` placeholder will be replaced with an interactive kanban board when exported to HTML via export-html-report.

#### Kanban Table Generation

**⚠️ CRITICAL:** The kanban table MUST include BOTH Megatrends (M:) AND Trends (T:), distributed across Act/Plan/Observe columns based on their `planning_horizon` field.

```text
╔═══════════════════════════════════════════════════════════════════════════════╗
║  ⛔ WIKILINK REQUIREMENT - NEVER USE PLAIN TEXT                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║  EVERY entry in the kanban table MUST include a wikilink to the entity file:  ║
║                                                                               ║
║  ✅ Correct: **M:** [[06-megatrends/data/megatrend-{slug}|{title}]]           ║
║  ✅ Correct: **T:** [[11-trends/data/trend-{slug}|{title}]]                   ║
║                                                                               ║
║  ❌ WRONG:   **T:** Predictive Maintenance  (plain text without wikilink)     ║
║  ❌ WRONG:   **M:** Industrial Digitalization  (missing wikilink)             ║
║                                                                               ║
║  The {slug} comes from dc:identifier in YAML frontmatter.                     ║
║  The {title} comes from dc:title in YAML frontmatter.                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

**Load entity metadata** from megatrend and trend files (YAML frontmatter only):

- **Megatrends:** `${PROJECT_PATH}/06-megatrends/data/megatrend-*.md`
  - Fields: `dc:title`, `planning_horizon`, `dimension_affinity`
- **Trends:** `${PROJECT_PATH}/11-trends/data/trend-*.md`
  - Fields: `dc:title`, `planning_horizon`, `dimension`

**Step-by-Step Algorithm:**

1. **Initialize data structures:**
   ```
   dimensions = [list from DIMENSION_REGISTRY] + ["General"]
   columns = ["act", "plan", "observe"]
   table_cells = {dim: {col: [] for col in columns} for dim in dimensions}
   ```

2. **Process ALL megatrend files (from MEGATREND_REGISTRY):**
   ```
   FOR each megatrend in MEGATREND_REGISTRY:
     - Extract: title = dc:title, horizon = planning_horizon, dim = dimension_affinity
     - IF horizon is missing:
       - Log WARNING: "Megatrend {megatrend_id} missing planning_horizon, defaulting to 'plan'"
       - horizon = "plan"
     - IF dim is missing: dim = "General"
     - Normalize horizon: "act" | "plan" | "observe"
     - ADD to table_cells[dim][horizon]: "**M:** [[06-megatrends/data/megatrend-{slug}\|{title}]]"
   ```

   **CRITICAL:** ALL megatrends from MEGATREND_REGISTRY MUST be included. Never skip a megatrend.

3. **Process ALL trend files:**
   ```
   FOR each file in ${PROJECT_PATH}/11-trends/data/trend-*.md:
     - Read YAML frontmatter
     - Extract: title = dc:title, horizon = planning_horizon, dim = dimension
     - IF horizon is missing:
       - Log WARNING: "Trend {dc:identifier} missing planning_horizon, defaulting to 'plan'"
       - horizon = "plan"
     - IF dim is missing: dim = "General"
     - Normalize horizon: "act" | "plan" | "observe"
     - ADD to table_cells[dim][horizon]: "**T:** [[11-trends/data/trend-{slug}\|{title}]]"
   ```

4. **Render table:**
   ```
   FOR each dimension row:
     FOR each column (act, plan, observe):
       IF table_cells[dim][col] is empty: cell = "—"
       ELSE: cell = join entries with "<br>"
   ```

**Cell Format Rules:**

- List megatrend names with wikilinks: `[[06-megatrends/data/megatrend-{slug}\|{display_name}]]`
- List trend names with wikilinks: `[[11-trends/data/trend-{slug}\|{display_name}]]`
- Prefix with **M:** for megatrends, **T:** for trends
- Multiple entries in same cell: separate with `<br>`
- If cell is empty: show "—" (em dash)
- Entities without dimension_affinity/dimension go to **{LABEL_GENERAL}** row
- **Megatrends:** If planning_horizon is missing, default to "plan" with warning (never skip megatrends)
- **Trends:** If planning_horizon is missing, default to "plan" with warning (never skip trends)

**CRITICAL: Pipe Escaping in Markdown Tables**

When generating wikilinks for markdown table cells, pipes MUST be escaped with backslash:
- ✅ Correct: `[[path/to/entity\|Display Text]]`
- ❌ Wrong: `[[path/to/entity|Display Text]]`

Unescaped pipes break table rendering in Obsidian and other markdown viewers.

**Language Variables:**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `BRIDGE_TREND_TABLE` | The following table shows the trends and megatrends by dimension and planning horizon: | Die folgende Tabelle zeigt die Trends und Megatrends nach Dimension und Zeithorizont: |
| `TH_DIMENSION` | Dimension | Dimension |
| `TH_ACT_HORIZON` | Act (0-6 months) | Act (0-6 Mon.) |
| `TH_PLAN_HORIZON` | Plan (6-18 months) | Plan (6-18 Mon.) |
| `TH_OBSERVE_HORIZON` | Observe (18+ months) | Observe (18+ Mon.) |
| `LEGEND_KANBAN_TABLE` | Legend: **M** = Megatrend, **T** = Trend | Legende: **M** = Megatrend, **T** = Trend |
| `LABEL_GENERAL` | General | Allgemein |

**TodoWrite:** Mark Step 5 as completed, Step 5.5 as in_progress.

---

## Step 5.5: Enhance 06-megatrends/README.md

**NEW:** Add megatrends narrative and hierarchy diagram to README.

**Location:** `${PROJECT_PATH}/06-megatrends/README.md`

**Goal:** 500-700 words with megatrend synthesis and visual hierarchy.

**Content to ADD (append to existing README):**

```markdown
---

## Megatrends Narrative

{Opening paragraph: 100-150 words on what megatrends reveal about the research question}

### Hierarchy and Relationships

{150-200 words describing megatrend clusters and their relationships}

**Megatrend Clusters:**
- **Cluster 1:** {2-3 megatrends with brief descriptions}
- **Cluster 2:** {2-3 megatrends with brief descriptions}

### Strategic Synthesis

{200-300 words on strategic implications of megatrends}

**Key Insights:**
- {Insight 1 with wikilinks to megatrends}
- {Insight 2 with wikilinks to megatrends}

### Hierarchy Mindmap

```mermaid
mindmap
  root((Research Question))
    {Megatrend 1}
      {Trend 1}
      {Trend 2}
    {Megatrend 2}
      {Trend 3}
      {Trend 4}
```

*Figure: Megatrend hierarchy showing relationships to trends*

*For full research report: [[research-hub]]*
```

**Data Sources:**
- Load MEGATREND_REGISTRY for megatrend metadata
- Analyze dimension_affinity patterns for clustering
- Link trends to megatrends via relationship data

**TodoWrite:** Mark Step 5.5 as completed, Step 5.7 as in_progress.

---

## Step 5.7: Enhance 11-trends/README.md

**NEW:** Add kanban table and dimension briefs to trends README.

**Location:** `${PROJECT_PATH}/11-trends/README.md`

**Goal:** 300-500 words with trend landscape overview.

**Content to ADD (append to existing README):**

```markdown
---

## Trend Landscape

{Opening paragraph: 50-100 words on trend distribution across dimensions}

### Trends by Dimension and Horizon

{Use same kanban table generation logic from Step 5.2}

| Dimension | Act (0-6 months) | Plan (6-18 months) | Observe (18+ months) |
|-----------|------------------|-------------------|----------------------|
| **{Dimension 1}** | **M:** [[06-megatrends/data/megatrend-{slug}\|{title}]]<br>**T:** [[11-trends/data/trend-{slug}\|{title}]] | ... | ... |

Legend: **M** = Megatrend, **T** = Trend

### Dimension Briefs

{50-100 words per dimension, 2-3 dimensions}

**{Dimension 1}:** {Brief 2-3 sentence overview of trends in this dimension}

**{Dimension 2}:** {Brief 2-3 sentence overview of trends in this dimension}

*For full dimensional analysis: [[research-hub#dimensional-analysis]]*
*For full research report: [[research-hub]]*
```

**Data Sources:**
- Reuse kanban table logic from Step 5.2
- Extract dimension briefs from DIMENSION_REGISTRY or synthesis files

**TodoWrite:** Mark Step 5.7 as completed, Step 6 as in_progress.

---

## Step 6: Create research-hub.md (Research Catalog Hub)

**Location:** `${PROJECT_PATH}/research-hub.md`

**CHANGED:** Hub version is now 300-450 words - pure research catalog. NO Executive Summary or Recommendations (moved to synthesis-cross-dimensional.md).

### Complete Structure (Research Catalog Version)

**Note:** Headings shown below are English defaults. For German projects (`project_language == "de"`), use German headings from Step 0.8 translation table.

```markdown
---
title: "Research Hub"
type: "hub-catalog"
hub_version: "3.0"
research_type: "generic"
synthesis_framework: "Hub-and-Spoke Progressive Disclosure"
date_created: "{ISO 8601}"
project_language: "{code}"
dimension_count: {N}
total_trends: {N}
total_citations: {N}
confidence_level: "{level}"
---

# {Research Question Title}

## Research Overview                    <!-- de: Forschungsübersicht -->

{Step 2 content - 80-120 words}

---

## Navigation Map                       <!-- de: Navigationsübersicht -->

**Use this navigation map to explore detailed analyses.** Each resource provides deeper context and evidence.

### Research Foundation

| Resource | Description | Word Count |
|----------|-------------|------------|
| **[[00-research-scope\|Research Scope & Methodology]]** | Framework, evidence scale, quality standards | 400-600 |
| **[[00-initial-question/data/question-{slug}\|Research Question]]** | Refined research question and scope boundaries | 50-150 |

### Cross-Dimensional Analysis

| Resource | Description | Word Count |
|----------|-------------|------------|
| **[[12-synthesis/synthesis-cross-dimensional\|Cross-Dimensional Synthesis]]** | Executive summary, recommendations, patterns | 800-1,200 |

### Dimension Deep-Dives

| Dimension | Key Focus | Full Analysis |
|-----------|-----------|---------------|
| **{Dimension 1}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug1}]] |
| **{Dimension 2}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug2}]] |
| **{Dimension 3}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug3}]] |
| **{Dimension 4}** | {1-sentence focus} | [[12-synthesis/synthesis-{slug4}]] |

### Trend Intelligence

| Resource | Description | Entity Count |
|----------|-------------|--------------|
| **[[06-megatrends/README\|Megatrends Overview]]** | Hierarchy, clusters, strategic synthesis | {N} megatrends |
| **[[11-trends/README\|Trends Landscape]]** | Kanban view, dimension briefs | {N} trends |

### Technical Details

| Resource | Description |
|----------|-------------|
| **[[00-pipeline-metrics\|Pipeline Metrics]]** | Entity statistics, wikilink density |

---

## Appendix: Report Generation         <!-- de: Anhang: Berichterstellung -->

**Framework:** Hub-and-Spoke Progressive Disclosure v3.0
**Generated:** {ISO 8601}
**Hub Skill:** synthesis-hub
**Spoke Skill:** synthesis-dimension
**Architecture:** Research Catalog + Independent Files

[[research-methodology]]
```

**Language Variables:**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_RESEARCH_OVERVIEW` | Research Overview | Forschungsübersicht |
| `HEADER_NAVIGATION_MAP` | Navigation Map | Navigationsübersicht |
| `HEADER_APPENDIX_GENERATION` | Appendix: Report Generation | Anhang: Berichterstellung |

### Quality Checks Before Writing

- [ ] YAML frontmatter includes `hub_type: "catalog"`
- [ ] Research Overview: 80-120 words, NO citations
- [ ] NO Executive Summary (moved to synthesis-cross-dimensional.md)
- [ ] NO Strategic Recommendations (moved to synthesis-cross-dimensional.md)
- [ ] Navigation Map: Clear table with all hub files listed
- [ ] **ALL navigation links point to files that will be generated**
- [ ] Dimension table: 1-sentence focus per dimension
- [ ] Total word count: 300-450 (pure catalog)
- [ ] NO analytical content (all moved to synthesis files)

**TodoWrite:** Mark Step 6 as completed, Step 7 as in_progress.

---

## Step 7: Generate 00-pipeline-metrics.md

**NEW:** Extract technical metrics into separate file.

**Location:** `${PROJECT_PATH}/00-pipeline-metrics.md`

**Goal:** 300-400 words with entity statistics and pipeline metrics.

**Content Structure:**

```markdown
---
title: "Research Pipeline Metrics"
doc_type: "technical_metrics"
related_report: "[[research-hub]]"
date_created: "{ISO 8601}"
---

# Research Pipeline Metrics

## Entity Statistics

{Table of entity counts by type}

| Entity Type | Count | Average per Dimension |
|-------------|-------|----------------------|
| Dimensions | {N} | - |
| Refined Questions | {N} | {N/dims} |
| Findings | {N} | {N/dims} |
| Claims | {N} | {N/dims} |
| Concepts | {N} | {N/dims} |
| Megatrends | {N} | - |
| Trends | {N} | {N/dims} |

## Evidence Chain Depth

{100-150 words explaining the entity hierarchy}

**Pipeline Flow:**
```
Initial Question
  └─> Refined Questions (per dimension)
       └─> Findings (web research)
            └─> Claims (fact-checked)
                 └─> Concepts (knowledge extraction)
                      └─> Megatrends (cross-dimensional clustering)
                           └─> Trends (final synthesis)
```

## Wikilink Density

{50-100 words on interconnectedness}

**Network Metrics:**
- Total wikilinks: {N}
- Average links per entity: {N}
- Most connected entities: {top 3}

## Quality Indicators

{50-100 words on evidence reliability scores, claim quality}

*For full research report: [[research-hub]]*
```

**Data Sources:**
- Count entities by globbing each directory
- Calculate averages from DIMENSION_REGISTRY
- Extract from existing STATISTICS_PLACEHOLDER logic

**TodoWrite:** Mark Step 7 as completed, Step 8 as in_progress.

---

## Step 8: Mark Phase 4 Complete

1. Verify hub ecosystem files exist:
   - `ls -lh "${PROJECT_PATH}/research-hub.md"` (hub - 600-900 words)
   - `ls -lh "${PROJECT_PATH}/00-research-scope.md"` (400-600 words)
   - `ls -lh "${PROJECT_PATH}/00-pipeline-metrics.md"` (300-400 words)
   - `ls -lh "${PROJECT_PATH}/12-synthesis/synthesis-cross-dimensional.md"` (400-600 words)
   - `ls -lh "${PROJECT_PATH}/06-megatrends/README.md"` (enhanced with 500-700 word narrative)
   - `ls -lh "${PROJECT_PATH}/11-trends/README.md"` (enhanced with 300-500 word landscape)
2. Log completion with metrics (6 files generated)
3. Update TodoWrite: All steps complete, Phase 4 complete, Phase 5 in_progress

---

## Phase Completion Checklist

| Step | Verification |
|------|--------------|
| 1 | Template loaded (Research catalog structure) |
| 1.5 | 00-research-scope.md generated (400-600 words) |
| 2 | Research Overview: 80-120 words, scope + entity counts |
| 4.7 | synthesis-cross-dimensional.md generated (800-1,200 words with Exec Summary + Recommendations + Patterns) |
| 5.5 | 06-megatrends/README.md enhanced (500-700 word narrative added) |
| 5.7 | 11-trends/README.md enhanced (300-500 word landscape added) |
| 6 | research-hub.md written (300-450 word catalog hub) |
| 7 | 00-pipeline-metrics.md generated (300-400 words) |
| 8 | All todos completed, Phase 5 ready |

**Output:** Hub ecosystem with 6 files:
1. `research-hub.md` (300-450 word catalog hub, `hub_type: "catalog"`)
2. `00-research-scope.md` (400-600 word methodology)
3. `00-pipeline-metrics.md` (300-400 word metrics)
4. `12-synthesis/synthesis-cross-dimensional.md` (800-1,200 words: Exec Summary + Recommendations + Patterns)
5. `06-megatrends/README.md` (enhanced with 500-700 word narrative)
6. `11-trends/README.md` (enhanced with 300-500 word landscape)

---

## What Changed from v2.4.0

| Previous (v2.4.0) | Current (v3.0) | Rationale |
|-------------------|----------------|-----------|
| Single 1,900-2,850 word file | **Hub ecosystem: 6 files** | Progressive disclosure, clear separation of concerns |
| Executive Summary in hub | **Moved to synthesis-cross-dimensional.md** | Synthesis belongs in synthesis files, not catalog |
| Strategic Recommendations in hub | **Moved to synthesis-cross-dimensional.md** | Recommendations are analysis, not navigation |
| Research Scope in report | **00-research-scope.md** | Separate methodology file (400-600 words) |
| Cross-Dimensional Patterns in report | **synthesis-cross-dimensional.md** | Executive summary + recommendations + patterns (800-1,200 words) |
| Megatrends section in report | **Enhanced 06-megatrends/README.md** | Narrative in megatrends directory (adds 500-700 words) |
| Trend Landscape in report | **Enhanced 11-trends/README.md** | Landscape in trends directory (adds 300-500 words) |
| Pipeline metrics in appendix | **00-pipeline-metrics.md** | Separate technical metrics file (300-400 words) |
| Dimensional Analysis section | **Navigation Map with dimension table** | Links to existing synthesis files |
| No hub_type indicator | **hub_type: "catalog" in frontmatter** | Version detection for tools |

**Architecture Changes:**
```
v2.4.0: Single monolithic report (1,900-2,850 words)
        Exec → Recs → Question → Patterns → Dimensions → Landscape → Appendix

v3.0:   Research catalog hub (300-450 words) + 5 supporting files
        Hub: Research Overview → Navigation Map → Appendix
        Supporting: research-scope, cross-dimensional (with Exec+Recs), megatrends, trends, pipeline-metrics
```

**Three-Tier Information Architecture:**
```
Tier 1 (Executive): 12-synthesis/synthesis-cross-dimensional.md
├─ Executive Summary (200-300 words)
├─ Strategic Recommendations (200-400 words)
└─ Cross-Dimensional Patterns (400-600 words)
└─ Total: 800-1,200 words

Tier 2 (Hub): research-hub.md
├─ Research catalog (300-450 words)
├─ Research Overview (scope, dimensions, entity counts)
└─ Navigation Map (links to all analysis files)

Tier 3 (Deep-Dive): Supporting files
├─ 00-research-scope.md (methodology)
├─ 06-megatrends/README.md (narrative)
├─ 11-trends/README.md (landscape)
├─ 00-pipeline-metrics.md (metrics)
└─ 12-synthesis/synthesis-*.md (dimension spokes)
```

**Key Benefits:**
- **85% reading reduction:** 300-450 words vs. 1,900-2,850 for hub
- **Clear separation:** Hub = catalog, synthesis files = findings
- **Better RAG:** Hub embeddings = navigation, synthesis embeddings = findings
- **Scalable hub:** Size constant regardless of research depth
- **Executive answers:** synthesis-cross-dimensional.md is the executive summary
- **No content duplication:** Single source of truth for each content type
- **Backward compatible:** Export tools detect v2.x vs v3.x via frontmatter

---

**Next:** Phase 5 - Validation & Output
