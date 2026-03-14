---
name: export-pdf-report
description: Transform deeper-research-3 output into a formal themed PDF report. Converts research-hub.md and entity files (synthesis, megatrends, trends, domain concepts, sources, citations) into a structured A4 document with cover page, table of contents, numbered sections, and source index. Use when user wants to export research as PDF, generate PDF report from research project, create formal research document, or convert research-hub.md to print format.
---

# Export PDF Report

Generate a formal A4 PDF report from deeper-research-3 output. Converts `research-hub.md` plus selected entity files into a structured print document with cover page, table of contents, dimension chapters, trend landscape, and source index.

## Quick Start

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-pdf-report/scripts/export_pdf_report.py" \
  --project /path/to/research-project \
  --theme digital-x \
  --output research-report.pdf
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project` | Yes | - | Path to research project root |
| `--theme` | No | `digital-x` | Theme ID from `$COGNI_WORKPLACE_ROOT/themes/` |
| `--output` | No | `{project}/research-report.pdf` | Output PDF file path |
| `--theme-root` | No | Auto-detected | Custom theme root directory |
| `--language` | No | Auto-detected | ISO 639-1 code (en/de) |
| `--dry-run` | No | `false` | Write manifest without generating PDF |
| `--list-themes` | No | - | List available themes as JSON and exit |

## Project Discovery

When invoked without a `--project` argument:

1. **Check environment variable first:**

   ```bash
   echo "${COGNI_RESEARCH_ROOT:-}"
   ```

   If set, list research projects under `$COGNI_RESEARCH_ROOT/deeper/` to find available projects.

2. **If not set, ask the user:**
   Use AskUserQuestion to request the full path to the research project containing `research-hub.md`.

3. **Validate project path:**
   - Must contain `research-hub.md` at root
   - Should have entity directories (e.g., `11-trends/data/`, `12-synthesis/`)

## Theme Selection

Before running the export script, discover available themes:

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-pdf-report/scripts/export_pdf_report.py" --list-themes
```

Present theme options via AskUserQuestion and pass the selected theme ID.

## Workflow

```text
1. Discover Project
   ├── Resolve project path (env var or user input)
   └── Validate research-hub.md exists

2. Select Theme
   ├── List available themes
   ├── User selects theme
   └── Extract theme colors and fonts

3. Run Export Script
   ├── Load entities and metadata
   ├── Assemble structured content JSON
   └── Write content to temp file

4. Generate PDF via Agent
   ├── Delegate to pdf-report-writer agent
   ├── Agent invokes document-skills:pdf
   └── ReportLab generates formal A4 PDF

5. Verify Output
   ├── Check PDF file exists
   ├── Report page count and file size
   └── Return result to user
```

## Step-by-Step Instructions

### Step 1: Discover Project

Follow the Project Discovery section above. Validate that `research-hub.md` exists at the project root.

### Step 2: Select Theme

List themes and let the user pick one. Extract theme metadata:

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-pdf-report/scripts/export_pdf_report.py" \
  --project "${PROJECT_PATH}" \
  --theme "${THEME_ID}" \
  --dry-run
```

The `--dry-run` flag outputs a JSON content manifest without generating the PDF. This validates the project and theme are loadable.

### Step 3: Run the Export Script

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-pdf-report/scripts/export_pdf_report.py" \
  --project "${PROJECT_PATH}" \
  --theme "${THEME_ID}" \
  --output "${OUTPUT_PATH}"
```

The script:
1. Loads `research-hub.md` frontmatter and body
2. Loads `sprint-log.json` for project metadata
3. Loads all synthesis, megatrend, trend, concept, source, publisher, and citation entities
4. Resolves wikilinks to source index references (e.g., `[7]`)
5. Assembles a structured content JSON file at `{project}/.metadata/pdf-content.json`

### Step 4: Delegate PDF Generation

After the script produces the content JSON, delegate to the `pdf-report-writer` agent:

```
Task(subagent_type="cogni-research:pdf-report-writer", prompt="
  Generate a formal A4 PDF report from the content manifest.
  CONTENT_FILE={project}/.metadata/pdf-content.json
  OUTPUT_PATH={output_path}
  THEME_ID={theme_id}
")
```

The agent uses `document-skills:pdf` skill with ReportLab to produce the final PDF.

### Step 5: Verify and Report

After the agent returns, verify the output:

```bash
ls -la "${OUTPUT_PATH}"
python3 -c "
import json
with open('${PROJECT_PATH}/.metadata/pdf-content.json') as f:
    data = json.load(f)
print(json.dumps({
    'output': '${OUTPUT_PATH}',
    'sections': len(data.get('sections', [])),
    'sources': len(data.get('source_index', []))
}, indent=2))
"
```

Report result to user with file path, page count estimate, and source count.

## Entity Format Reference

For detailed frontmatter specs of all entity types, see [references/entity-formats.md](references/entity-formats.md).

## Report Structure

The PDF follows a formal report layout. See [references/report-structure.md](references/report-structure.md) for the full specification.

| Section | Source | Description |
|---------|--------|-------------|
| Cover Page | `research-hub.md` frontmatter | Title, date, research type, theme branding |
| Table of Contents | Auto-generated | Section titles with page numbers |
| Executive Summary | `insight-summary.md` | 1-2 page narrative overview (if present) |
| Dimension Chapters | `12-synthesis/synthesis-*.md` | One chapter per dimension with full synthesis |
| Megatrends | `06-megatrends/data/megatrend-*.md` | Cross-cutting patterns with TIPS narratives |
| Trend Landscape | `11-trends/data/trend-*.md` | Overview table with dimension/horizon/confidence |
| Domain Concepts | `05-domain-concepts/data/concept-*.md` | Glossary of key terms |
| Appendix: Research Scope | `00-research-scope.md` | Methodology, dimensions, evidence scale |
| Source Index | `07-sources/` + `09-citations/` | Numbered bibliography with publisher info |

## Entities Included vs Excluded

| Included | Excluded | Reason for Exclusion |
|----------|----------|---------------------|
| Synthesis (12) | Findings (04) | Raw data, subsumed by synthesis |
| Megatrends (06) | Claims (10) | Verification metadata, not narrative |
| Trends (11) | Query Batches (03) | Operational artifact |
| Domain Concepts (05) | Refined Questions (02) | Operational artifact |
| Sources (07) | Initial Question (00) | Operational artifact |
| Publishers (08) | Cross-dimensional synthesis | Duplicates dimension chapter content |
| Citations (09) | Pipeline metrics (`00-pipeline-metrics.md`) | Operational metadata, not for report reader |

## Theme-to-PDF Style Mapping

See [references/theme-to-pdf-mapping.md](references/theme-to-pdf-mapping.md) for how CSS variables translate to ReportLab styles.

Key mappings:

| CSS Variable | ReportLab Usage |
|-------------|-----------------|
| `--color-primary` | Chapter headings, cover page title, horizontal rules |
| `--color-accent` | Section numbers, trend horizon badges, highlight boxes |
| `--color-bg-secondary` | Sidebar boxes, callout backgrounds |
| `--color-text-primary` | Body text |
| `--color-text-muted` | Captions, footnotes, page headers |
| `--font-primary` | Body paragraphs (mapped to closest system font) |
| `--font-heading` | Chapter titles, section headings |
| `--color-dim-*` | Dimension chapter accent colors |

## Wikilink Resolution

Wikilinks in entity body text are resolved as follows:

- `[[07-sources/data/source-xyz]]` → `[N]` (numbered source reference from source index)
- `[[05-domain-concepts/data/concept-abc]]` → plain text (concept name, title-cased)
- `[[06-megatrends/data/megatrend-xyz]]` → plain text (megatrend name, title-cased)
- `[[11-trends/data/trend-xyz]]` → plain text (trend title, title-cased)
- Unresolvable wikilinks → plain text (entity ID with hyphens replaced by spaces, title-cased)

## Constraints

- Never invoke ReportLab directly — always delegate to `pdf-report-writer` agent
- Always validate `research-hub.md` exists before running the export script
- Never fabricate entity IDs — only reference entities loaded from disk
- Content manifest must be valid JSON before delegation to the agent
- Cross-dimensional synthesis (`synthesis-cross-dimensional.md`) is explicitly excluded — it duplicates dimension chapter content and is not suited for a sequential formal PDF

## Error Handling

| Scenario | Action |
|----------|--------|
| Missing `research-hub.md` | Error: project path invalid |
| No synthesis entities | Warning: report will lack dimension chapters |
| No trends | Warning: trend landscape section empty |
| Theme not found | Fall back to default color scheme |
| Agent PDF generation fails | Return error with details |
| Missing `insight-summary.md` | Falls back to `executive-summary.md`; skips section if both missing |

## Success Criteria

- PDF file exists at the specified output path
- File size > 10KB (a valid multi-section PDF is always larger)
- Section count in manifest matches expected sections (at minimum: `source_index` is always present)
- Agent returns `{"success": true}` JSON response
