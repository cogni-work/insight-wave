# Polishable Files Reference

Files eligible for copywriting orchestration after deeper-research-3 completes.

## File Inventory

| File | Location | Copywriter | Reader | Scope Filter | Notes |
|------|----------|-----------|--------|-------------|-------|
| Executive summary | `12-synthesis/synthesis-cross-dimensional.md` | Yes | Yes | `all`, `synthesis` | Cross-dimensional patterns and tensions. Reader runs AFTER copywriter. |
| Dimension syntheses | `12-synthesis/synthesis-{dim}.md` | Yes | No | `all`, `synthesis` | 2-10 files depending on dimension count. One per research dimension. |
| Insight summary | `insight-summary.md` (project root) | Yes | No | `all`, `synthesis`, `insight` | Arc-aware narrative. ALWAYS include when file exists AND has `arc_id`. Highest-priority polish target after executive summary. |
| Megatrend narrative | `06-megatrends/README.md` | Yes | No | `all`, `megatrends` | Megatrend landscape overview with cross-references. |
| Megatrend entities | `06-megatrends/data/*.md` | Yes | No | `all`, `megatrends` | Individual megatrend narratives with cross-references to domain concepts. |
| Trend landscape | `11-trends/README.md` | Yes | No | `all`, `trends` | Trend kanban table and landscape narrative. Copywriter auto-preserves table structure. |
| Trend dimension READMEs | `11-trends/README-{dim}.md` | Yes | No | `all`, `trends` | Per-dimension trend navigation with mermaid mindmaps. Copywriter preserves mermaid blocks. |
| Trend entities | `11-trends/data/trend-*.md` | Yes | No | `all`, `trends` | Individual trend narratives (1,050-1,300 words). Context, evidence, implications, tensions. |

## Files NOT Polished

These project files are intentionally excluded from copywriting:

| File | Reason |
|------|--------|
| `research-hub.md` | Navigation hub with wikilink tables — polishing would break structure |
| `00-research-scope.md` | Methodology description — factual/technical, not narrative |
| `00-pipeline-metrics.md` | Auto-generated metrics — no prose to polish |
| `README.md` | Project navigation — structural, not narrative |
| Upstream entity data (`04-findings/data/*.md`, `05-domain-concepts/data/*.md`) | Raw research entities — polishing would alter evidence |
| `09-citations/README.md` | Evidence catalog — structured reference, not narrative |

## File Characteristics

### Executive Summary (`synthesis-cross-dimensional.md`)

- **Word count**: 1,500-3,000 words
- **Structure**: Cross-dimensional patterns, strategic tensions, convergence analysis
- **Why polish**: Highest-visibility deliverable, read by executives
- **Why reader review**: Multi-persona analysis catches blind spots in messaging
- **Reader runs after copywriter**: Ensures reader evaluates polished content, not raw synthesis

### Dimension Syntheses (`synthesis-{dim}.md`)

- **Word count**: 800-2,000 words per dimension
- **Count**: 2-10 files (matches dimension count from deeper-research-0)
- **Structure**: Dimension-specific analysis with trend integration and evidence backing
- **Why polish**: Each dimension is a standalone analytical narrative

### Insight Summary (`insight-summary.md`)

- **Word count**: 1,450-1,900 words
- **Structure**: Arc-specific narrative (e.g., Why Change / Why Now / Why You / Why Pay)
- **Prerequisite**: Must have `arc_id` in frontmatter (set during deeper-research-3 Phase 0.5)
- **Why polish**: Journalistic narrative style benefits most from copywriting refinement
- **Skip condition**: File missing OR no arc_id — this is normal for projects without arc detection

### Megatrend Narrative (`06-megatrends/README.md`)

- **Word count**: 500-1,500 words
- **Structure**: Megatrend landscape with cross-references to domain concepts
- **Why polish**: Narrative framing of macro-level forces benefits from readability improvements

### Megatrend Entities (`06-megatrends/data/*.md`)

- **Word count**: 300-800 words per entity
- **Count**: Variable (typically 3-8 megatrends per project)
- **Structure**: Dublin Core frontmatter + narrative body with impact analysis and cross-references
- **Why polish**: Each megatrend entity is a self-contained analytical narrative
- **Note**: Copywriter must preserve Dublin Core YAML frontmatter and wikilinks

### Trend Landscape (`11-trends/README.md`)

- **Word count**: 500-2,000 words
- **Structure**: Trend overview with kanban-style markdown table
- **Why polish**: Narrative sections benefit from polishing; table structure is auto-preserved by copywriter
- **Note**: The kanban table uses markdown pipe syntax — cogni-copywriting:copywriter preserves table formatting

### Trend Dimension READMEs (`11-trends/README-{dim}.md`)

- **Word count**: 200-500 words per file
- **Count**: One per research dimension (matches dimension count)
- **Structure**: Dimension-scoped trend navigation with mermaid mindmap
- **Why polish**: Introductory narrative benefits from readability improvements
- **Note**: Copywriter must preserve mermaid code blocks verbatim

### Trend Entities (`11-trends/data/trend-*.md`)

- **Word count**: 1,050-1,300 words per entity
- **Count**: Variable (typically 8-15 per dimension, can be 30-60+ total)
- **Structure**: Dublin Core frontmatter + Context, Evidence, Tensions & Limitations, Implications (Strategic/Operational/Technical), References
- **Why polish**: Each trend entity is a substantial narrative document — the largest per-entity content in the pipeline
- **Note**: Copywriter must preserve Dublin Core YAML frontmatter, wikilinks, and reference sections
