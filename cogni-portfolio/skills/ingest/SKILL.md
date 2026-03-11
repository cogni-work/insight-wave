---
name: ingest
description: |
  Extract portfolio entities from uploaded documents (uploads/ folder).
  Use whenever the user mentions uploading files, importing documents, ingesting
  data, "I have some files", "parse these docs", processing uploads, or wants to
  populate their portfolio from existing material — even if they don't say "ingest".
---

# Upload Ingestion

Extract portfolio entities from user-provided documents in the project's `uploads/` folder. Supported file types: `.md`, `.docx`, `.pptx`, `.xlsx`, `.pdf`.

## Core Concept

Most users already have product information scattered across decks, spreadsheets, and documents. Ingestion bridges the gap between existing material and a structured portfolio — it turns unstructured documents into typed entities (products, features, markets) that the rest of the pipeline builds on.

This matters because manual entity creation is tedious when the information already exists somewhere. A good ingestion pass gives the user a head start, and the confirmation step ensures nothing gets created that doesn't belong.

## Prerequisites

- An active cogni-portfolio project (`portfolio.json` must exist)
- One or more supported files in the project's `uploads/` directory
- The `document-skills` plugin for non-markdown file extraction (docx, pptx, xlsx, pdf)

## Workflow

### 1. Locate Project and Scan Uploads

Find the active portfolio project by searching for `portfolio.json` under a `cogni-portfolio/` path (same approach as the `resume-portfolio` skill). If multiple projects exist, ask which one to use.

Scan `uploads/` for supported files, excluding the `processed/` subdirectory. If no files are found, tell the user the folder is empty and list the supported file types.

### 2. Check File Type Requirements

If non-markdown files are present (.docx, .pptx, .xlsx, .pdf), verify document-skills availability. If unavailable, inform the user which files cannot be processed, process only the .md files, and leave the binary files in `uploads/` for later.

### 3. Extract Text Content

Process each file based on its type:

- **Markdown (.md)**: Read directly with the Read tool
- **Word (.docx)**: Use the `document-skills:docx` skill
- **PowerPoint (.pptx)**: Use the `document-skills:pptx` skill
- **Excel (.xlsx)**: Use the `document-skills:xlsx` skill
- **PDF (.pdf)**: Use the `document-skills:pdf` skill

For large documents (PDFs over 20 pages, Excel with many sheets), process in segments. For PDFs, use the `pages` parameter to read 10-20 pages at a time. For Excel, process one sheet at a time. Present extracted entities per segment so the user can confirm incrementally rather than reviewing dozens of entities at once.

### 4. Analyze and Classify Content

Read `portfolio.json` to understand the company context. Then analyze extracted content to identify potential entities:

| Entity Type | What to Look For |
|---|---|
| Products | Named offerings, product lines, service packages |
| Features | Capabilities, specifications, functions, technical components |
| Markets | Target segments, customer groups, geographic regions, verticals |

Competitive intelligence or buyer persona data found in documents is worth noting, but don't create competitor or customer entities during ingestion. These types require propositions or markets as parents and are handled by the `compete` and `customers` skills after prerequisite entities exist.

Cross-reference with existing entities in `products/`, `features/`, and `markets/` directories to avoid duplicates.

### 5. Present Extracted Entities for Confirmation

Group entities by source file and present them in tables:

**From: `product-overview.pdf`**

| Type | Slug | Name | Key Fields |
|---|---|---|---|
| Product | cloud-platform | Cloud Platform | description, positioning |
| Feature | auto-scaling | Auto-Scaling | product: cloud-platform, category: infrastructure |

Show enough detail for the user to judge accuracy. Mark entities that may overlap with existing ones.

Allow the user to:
- **Approve all** -- create all proposed entities
- **Select individually** -- approve, edit, or skip each entity
- **Edit before creating** -- modify fields before writing JSON

### 6. Write Entity JSON Files

For each confirmed entity, write a JSON file following the schemas in `$CLAUDE_PLUGIN_ROOT/skills/setup/references/data-model.md`:

- Products to `products/{slug}.json`
- Features to `features/{slug}.json`
- Markets to `markets/{slug}.json`

Set `created` to today's date. Include `"source_file": "<filename>"` in each entity to enable tracing origins back to the uploaded document.

For features, ensure `product_slug` references a valid product. If a referenced product doesn't exist yet, propose creating it first or ask the user to assign a different product.

### 7. Move Processed Files

After all confirmed entities are written, move processed files to `uploads/processed/`. Create the directory if it doesn't exist. Only move files that were successfully processed. If a file yielded no usable entities (user skipped everything), still move it to avoid re-processing on the next run.

### 8. Sync portfolio.json

If any products were created during ingestion, run the centralized sync script:

```bash
$CLAUDE_PLUGIN_ROOT/scripts/sync-portfolio.sh <project-dir>
```

Skip this step if no products were created.

### 9. Present Summary and Next Steps

Show a summary of what was created:

| Type | Created | Skipped |
|---|---|---|
| Products | 2 | 0 |
| Features | 5 | 1 |
| Markets | 3 | 0 |

Suggest the logical next step based on what was ingested:
- Products and features created -> suggest the `markets` skill
- Markets created -> suggest the `propositions` skill
- Partial data -> suggest completing the entity type manually
- Competitive or buyer persona data observed -> mention it and suggest `compete` or `customers` after prerequisite entities are in place
- Markets created without TAM/SAM/SOM -> list them explicitly and suggest the `markets` skill to add sizing estimates

## Important Notes

- Always confirm entities with the user before writing -- never auto-create
- Respect existing entities; do not overwrite unless the user explicitly requests it
- One document may contain data for multiple entity types
- If a document is ambiguous, ask the user which entity types to extract
- Feature extraction should produce market-independent statements (IS layer only)
- Market data from documents may lack TAM/SAM/SOM; create with available fields and note sizing can be added later
- The `uploads/processed/` subdirectory is not scanned by project-status.sh
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
- Refer to `$CLAUDE_PLUGIN_ROOT/skills/setup/references/data-model.md` for complete entity schemas
