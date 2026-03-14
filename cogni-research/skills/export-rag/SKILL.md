---
name: export-rag
description: Export deeper-research project entities to flat markdown files optimized for RAG in Claude Projects. Use when users want to export research findings, trends, claims, or sources for use as project knowledge in claude.ai. Triggers on requests like "export for RAG", "prepare for Claude Projects", "export research for project knowledge", or "create RAG export".
---

# Export RAG

Export research project entities to a flat file structure optimized for Retrieval-Augmented Generation (RAG) in [Claude Projects](https://support.claude.com/en/articles/11473015-retrieval-augmented-generation-rag-for-projects).

## When to Use

- Export deeper-research project for use as Claude Projects knowledge
- Create RAG-optimized versions of research entities
- Prepare research findings for upload to claude.ai Projects

## Quick Start

```bash
# Export all entity types to <project>/export-rag/
python scripts/export_rag.py <project_path>

# Export to a specific directory
python scripts/export_rag.py <project_path> <output_dir>

# Include the research report
python scripts/export_rag.py <project_path> --include-report

# Export specific entity types
python scripts/export_rag.py <project_path> --entity-types trends,findings
```

## RAG Optimization Features

The export script applies these optimizations for Claude Projects RAG:

1. **Flat file structure**: All files in single directory (no nesting)
2. **Descriptive filenames**: `trend-agile-strategy.md` instead of `abc123.md`
3. **Metadata headers**: Type, project, canonical ID, confidence, tags inline
4. **Entity relationships**: Bidirectional references preserved for RAG retrieval
5. **Resolved wikilinks**: `[[path/entity]]` converted to text with preserved entity IDs
6. **Clean markdown**: Removes HTML, excessive whitespace, comments

## Entity Relationships

The export maintains relationships between entities for improved RAG retrieval:

- **Canonical IDs**: Each entity has a unique searchable ID (e.g., `finding-market-growth-a7f3b2c1`)
- **Bidirectional references**: If entity A references B, entity B knows it's referenced by A
- **Inline ID preservation**: Wikilinks converted to "Title (ID: `entity-id`)" format
- **Relationship section**: Each file includes "Related Entities" with References and Referenced By

This enables Claude to follow relationships across documents during RAG retrieval.

## Entity Types

Both short aliases and canonical schema keys are accepted in `--entity-types`:

| Short Alias | Canonical Key | Directory | Priority | Content |
|-------------|---------------|-----------|----------|---------|
| trends | trends | 11-trends | Highest | TIPS format strategic trends |
| — | synthesis | 12-synthesis | Very High | Cross-dimensional research syntheses |
| findings | findings | 04-findings | High | Research findings with sources |
| dimensions | research-dimensions | 01-research-dimensions | Medium | Research dimension definitions |
| questions | refined-questions | 02-refined-questions | Medium | Refined research questions |
| claims | claims | 10-claims | Medium | Fact-checked claims with confidence |
| sources | sources | 07-sources | Lower | Source metadata and backlinks |
| — | megatrends | 06-megatrends | Lower | Megatrend categorizations |
| concepts | domain-concepts | 05-domain-concepts | Lower | Domain concept definitions |
| — | initial-question | 00-initial-question | Lower | Original research question |
| batches | query-batches | 03-query-batches | Lower | Search query batches |
| — | publishers | 08-publishers | Lower | Publisher metadata |
| — | citations | 09-citations | Lower | Formal APA citations |

Default export: all 13 entity types

Short aliases (e.g., `dimensions`) are resolved to canonical keys (e.g., `research-dimensions`) before lookup. Both forms work interchangeably in `--entity-types`.

## Output Format

Each exported file follows this structure:

```markdown
# Descriptive Title

**Type**: Trend
**ID**: `trend-strategic-growth-a7f3b2c1`
**Project**: trend-radar-1
**Confidence**: 0.85
**Dimension**: digital-foundation
**Tags**: ai, automation, manufacturing

---

[Clean content with resolved references including entity IDs]

Referenced entities: Market Analysis Report (ID: `source-market-report-b2c3d4e5`)...

---

## Related Entities

**ID**: `trend-strategic-growth-a7f3b2c1`

### References
- **Sources** (2):
  - `source-market-report-b2c3d4e5`: "Market Analysis Report"
  - `source-gartner-2024-c3d4e5f6`: "Gartner 2024 Report"
- **Claims** (1):
  - `claim-growth-rate-d4e5f6a7`: "Market grew 22% YoY"

### Referenced By
- **Cited By** (1):
  - `trend-market-entry-e5f6a7b8`: "Market Entry Analysis"

---
**Keywords**: trends, trend, sources:2, claims:1, has-cited_by:1
```

## Workflow

1. **Identify project**: Locate deeper-research project (contains `04-findings/data/`, `10-claims/data/`, etc.)

2. **Choose entity types** (optional): By default all 13 types are exported. Use `--entity-types` to restrict:
   - Research knowledge base: `--entity-types trends,findings,claims`
   - Full evidence trail: `--entity-types trends,findings,claims,sources,citations`
   - Quick overview: `--entity-types trends`

3. **Run export**:

   ```bash
   python scripts/export_rag.py /path/to/project --include-report
   ```

4. **Review output**: Check `00-index.md` for export summary

5. **Upload to Claude Projects**: Add exported files to Project Knowledge

## File Size Guidance

Claude Projects RAG works best with:

- Individual files under 200KB (default max)
- Well-named files (used for retrieval)
- Related content grouped logically

Use `--max-file-size` to adjust the warning threshold.

## Example

```bash
# Export all entity types (default)
python scripts/export_rag.py ~/workplace/cogni-research/trend-radar-1 --include-report

# Export only specific types
python scripts/export_rag.py ~/workplace/cogni-research/trend-radar-1 \
  --entity-types trends,findings,claims \
  --include-report
```

Output:

```text
Exporting project: trend-radar-1
Entity types: trends, findings, claims

  trends: 30 files exported
  findings: 184 files exported
  claims: 309 files exported
  research report: exported

Export complete: 525 files written to /path/to/trend-radar-1/export-rag
```

## Script Reference

```text
scripts/export_rag.py <project_path> [output_dir] [options]

Arguments:
  project_path          Path to deeper-research project
  output_dir            Destination for exported files (default: <project>/export-rag)

Options:
  --entity-types        Comma-separated types (default: all)
  --include-report      Include research-hub.md
  --max-file-size       Warning threshold in KB (default: 200)
  --relationship-format Relationship section format (default: full)
                        - full: Detailed references with titles
                        - compact: IDs only, space-efficient
                        - none: Disable relationships (backward compatible)
```

## Relationship Format Options

| Format | Use Case | Size Impact |
|--------|----------|-------------|
| `full` | Maximum context for RAG | +20-40% per file |
| `compact` | Balance context/size | +5-10% per file |
| `none` | Legacy mode, no relationships | No increase |

Example with compact format:

```bash
python scripts/export_rag.py <project> --relationship-format compact
```
