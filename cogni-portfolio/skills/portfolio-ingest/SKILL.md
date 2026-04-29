---
name: portfolio-ingest
description: |
  Extract portfolio entities and structured context from uploaded documents (uploads/ folder).
  Use whenever the user mentions uploading files, importing documents, ingesting data,
  "I have some files", "parse these docs", "use these docs as input", "internal documents",
  "background material", "here's our strategy deck", processing uploads, or wants to
  populate their portfolio from existing material — even if they don't say "ingest".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# Upload Ingestion

Extract portfolio entities and institutional context from user-provided documents in the project's `uploads/` folder. Supported file types: `.md`, `.docx`, `.pptx`, `.xlsx`, `.pdf`.

## Core Concept

**Plugin root resolution.** Bash invocations below resolve the plugin root inline as `${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}` — the first call works whether or not the harness injects `$CLAUDE_PLUGIN_ROOT`. Keep the inline form in every call; do not strip it.

Most users already have product information scattered across decks, spreadsheets, and documents. Ingestion bridges the gap between existing material and a structured portfolio in two ways:

1. **Entity extraction** — turns unstructured documents into typed entities (products, features, markets) that the rest of the pipeline builds on.
2. **Context extraction** — captures institutional knowledge (competitive intelligence, pricing benchmarks, strategic positioning, customer insights) as structured context entries that downstream skills use to generate sharper, company-specific output.

Entity extraction gives the user a head start on portfolio structure. Context extraction ensures the intelligence buried in strategy decks, pricing models, and win/loss reports doesn't get lost — it flows into propositions, solutions, competitor analysis, and every other downstream skill automatically.

## Prerequisites

- An active cogni-portfolio project (`portfolio.json` must exist)
- One or more supported files in the project's `uploads/` directory
- The `document-skills` plugin for non-markdown file extraction (docx, pptx, xlsx, pdf)

## Workflow

### 1. Locate Project and Scan Uploads

Find the active portfolio project by searching for `portfolio.json` under a `cogni-portfolio/` path (same approach as the `portfolio-resume` skill). If multiple projects exist, ask which one to use.

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

Read `portfolio.json` to understand the company context.

#### Re-Upload Detection

Before classifying content, check if any of the current upload files match previously ingested sources. If `source-registry.json` exists, run:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/source-registry.sh" "<project-dir>" check-docs
```

If the result shows **changed** documents (same filename, different hash), alert the user:

> "This file was previously ingested and created N features and M context entries. The content has changed since last ingestion. Would you like to:
> 1. **Re-ingest and refresh** — extract new entities/context, mark old linked entities as stale for downstream refresh
> 2. **Re-ingest fresh** — extract without linking to previous entities (treat as new source)
> 3. **Skip** — leave this file for later"

If the user chooses option 1, note the previously linked entities for staleness flagging in Step 8b.

Then analyze extracted content for both entities and context.

#### Entity Classification

Identify potential entities:

| Entity Type | What to Look For |
|---|---|
| Products | Named offerings, product lines, service packages |
| Features | Capabilities, specifications, functions, technical components |
| Markets | Target segments, customer groups, geographic regions, verticals |

Competitive intelligence or buyer persona data found in documents is worth noting, but don't create competitor or customer entities during ingestion. These types require propositions or markets as parents and are handled by the `compete` and `customers` skills after prerequisite entities exist.

Cross-reference with existing entities in `products/`, `features/`, and `markets/` directories to avoid duplicates.

#### Context Classification

In the same pass, identify intelligence snippets — self-contained insights that provide institutional knowledge for downstream skills. Classify each snippet into one of six categories:

| Category | What to Look For | Primary Downstream Skills |
|---|---|---|
| `competitive` | Win/loss reports, competitor mentions, battlecards, RFP outcomes | compete, propositions |
| `market` | Market research, TAM analyses, customer segmentation, industry reports | markets, propositions |
| `pricing` | Pricing models, rate cards, discount structures, margin targets, cost benchmarks | solutions, packages |
| `customer` | Interview transcripts, CRM summaries, buyer persona research, NPS data | customers, propositions |
| `technical` | Architecture docs, technical specs, product roadmaps, integration guides | features |
| `strategic` | Strategy decks, positioning documents, differentiation analyses, board presentations | propositions, solutions |

Each snippet should be a self-contained insight (one fact, one benchmark, one positioning statement) with enough surrounding context to be useful. Aim for 3-10 context entries per document, depending on richness. Do not extract trivially obvious information — focus on intelligence that would be hard to re-derive from scratch (specific numbers, internal decisions, competitive observations, customer quotes).

When a snippet relates to specific portfolio entities (a pricing benchmark for a particular product, a competitive insight about a specific market), note those entity slugs for linking.

### 5. Present Extracted Items for Confirmation

Group by source file. Present entities first, then context entries.

**From: `product-overview.pdf`**

**Entities:**

| Type | Slug | Name | Key Fields |
|---|---|---|---|
| Product | cloud-platform | Cloud Platform | description, positioning |
| Feature | auto-scaling | Auto-Scaling | product: cloud-platform, category: infrastructure |

**Context:**

| # | Category | Summary | Linked Entities | Confidence |
|---|---|---|---|---|
| 1 | strategic | Company positions as "sovereign cloud" differentiator in DACH region | products/cloud-platform | high |
| 2 | competitive | Main competitor Datadog weak in mid-market due to per-host pricing | compete | medium |
| 3 | pricing | Target margin 35% with blended rate 1,400 EUR/day for DACH | solutions, packages | high |

Show enough detail for the user to judge accuracy. Mark entities that may overlap with existing ones.

Allow the user to:
- **Approve all** -- create all proposed entities and context
- **Select individually** -- approve, edit, or skip each item
- **Edit before creating** -- modify fields before writing JSON
- **Re-categorize context** -- change category or relevance mapping

Not every document will produce both entities and context. A strategy deck might yield mostly context with no new entities. A product spec might yield mostly entities with little context. Present only what was found.

### 6. Write Entity JSON Files

For each confirmed entity, write a JSON file following the schemas in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`:

- Products to `products/{slug}.json`
- Features to `features/{slug}.json`
- Markets to `markets/{slug}.json`

Set `created` to today's date. Include `"source_file": "<filename>"` in each entity to enable tracing origins back to the uploaded document.

For features, ensure `product_slug` references a valid product. If a referenced product doesn't exist yet, propose creating it first or ask the user to assign a different product.

For each feature, draft a `purpose` field (5-12 words): a customer-readable statement answering "what is this feature FOR?" — the problem it solves or capability it provides. Derive purpose from the source document's context (e.g., section headings, executive summaries, or capability descriptions that frame the feature's value).

Assign `sort_order` to each feature following the value-to-utility spectrum: customer-facing value features get low numbers (10, 20, 30...), infrastructure/utility features get high numbers (70+). Use increments of 10 to leave room for insertions. This controls display ordering in the dashboard and reports.

### 7. Write Context Entry Files

For each confirmed context entry, write a JSON file to `context/{source-slug}--{seq}.json` following the context entry schema in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.

The slug is derived from the source filename (kebab-case, without extension) plus a zero-padded sequence number: e.g., `pricing-strategy-2025--001`, `pricing-strategy-2025--002`.

Set `created` to today's date. Set `confidence` based on how directly the insight comes from the document:
- `high` — verbatim fact or number from the document
- `medium` — reasonable inference from document content
- `low` — interpretation that would benefit from user validation

Create `context/` directory if it doesn't exist.

After writing all context entries, rebuild `context/context-index.json` by scanning all `.json` files in `context/` (excluding `context-index.json` itself). The index has three lookup maps:

- `by_category` — category string -> array of context slugs
- `by_relevance` — skill name -> array of context slugs
- `by_entity` — entity path (e.g., `products/cloud-platform`) -> array of context slugs

Include `version`, `entry_count`, and `updated` fields. See `$CLAUDE_PLUGIN_ROOT/references/data-model.md` for the full index schema.

### 8. Move Processed Files

After all confirmed items are written, move processed files to `uploads/processed/`. Create the directory if it doesn't exist. Only move files that were successfully processed. If a file yielded no usable entities or context (user skipped everything), still move it to avoid re-processing on the next run.

### 8b. Update Source Registry

After moving files, update the source lineage registry for each processed file:

1. If `source-registry.json` does not exist, initialize it:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/source-registry.sh" "<project-dir>" init
   ```

2. For each processed file, register it with its fingerprint:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/source-registry.sh" "<project-dir>" register-doc "<project-dir>/uploads/processed/<filename>"
   ```

3. After registration, update the registry entry's `entities` and `context_entries` arrays to include all entities and context entries created from this file. Read `source-registry.json`, find the entry by `source_id`, and add:
   - Entity paths (e.g., `"features/cloud-monitoring"`, `"products/cloud-platform"`) to `entities`
   - Context entry slugs (e.g., `"pricing-strategy-2025--001"`) to `context_entries`

4. Write `source_refs` on each created entity, pointing to the registry `source_id`. This supplements the existing `source_file` field for richer lineage tracking:
   ```json
   {
     "source_file": "pricing-strategy-2025.pdf",
     "source_refs": ["doc--pricing-strategy-2025"]
   }
   ```

5. If this is a **re-upload** (detected in Step 4 as a changed document) and the user chose "Re-ingest and refresh":
   - Set the old registry entry's `status` to `"superseded"`
   - Set the new entry's `supersedes` field to the old `source_id`
   - For all entities linked to the old source that were NOT re-created in this batch, write a `lineage_status` field:
     ```json
     { "lineage_status": { "status": "stale", "flagged_at": "2026-04-03", "reasons": ["source doc--pricing-strategy-2025 re-uploaded with changes"] } }
     ```
   - This ensures `portfolio-resume` and `portfolio-lineage` will surface these stale entities

### 9. Sync portfolio.json

If any products were created during ingestion, run the centralized sync script:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/sync-portfolio.sh" <project-dir>
```

Skip this step if no products were created.

### 10. Present Summary and Next Steps

Show a summary of what was created:

| Type | Created | Skipped |
|---|---|---|
| Products | 2 | 0 |
| Features | 5 | 1 |
| Markets | 3 | 0 |
| Context | 8 | 2 |

Suggest the logical next step based on what was ingested:
- Products and features created -> suggest the `markets` skill
- Markets created -> suggest the `propositions` skill
- Partial data -> suggest completing the entity type manually
- Competitive or buyer persona data observed but not yet entityable -> mention it and suggest `compete` or `customers` after prerequisite entities are in place
- Markets created without TAM/SAM/SOM -> list them explicitly and suggest the `markets` skill to add sizing estimates
- Context entries created -> mention which downstream skills will benefit. For example: "8 context entries extracted (3 pricing, 2 competitive, 2 strategic, 1 customer). These will automatically inform the `solutions`, `compete`, `propositions`, and `customers` skills when you run them."

## Important Notes

- Always confirm entities and context with the user before writing -- never auto-create
- Respect existing entities; do not overwrite unless the user explicitly requests it
- One document may contain data for multiple entity types and context categories
- If a document is ambiguous, ask the user which entity types to extract
- Feature extraction should produce market-independent statements (IS layer only)
- Market data from documents may lack TAM/SAM/SOM; create with available fields and note sizing can be added later
- The `uploads/processed/` subdirectory is not scanned by project-status.sh
- Context entries supplement entity data — they don't replace it. A pricing benchmark in context doesn't remove the need for the `solutions` skill to design pricing tiers; it gives that skill better inputs to work from.
- When re-running ingest on new documents, existing context entries are preserved. The index is rebuilt from all files in `context/`, not just the current batch.
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language (status messages, instructions, recommendations, questions). Technical terms, skill names, and CLI commands remain in English. If no `language` field is present, default to English.
- Refer to `$CLAUDE_PLUGIN_ROOT/references/data-model.md` for complete entity and context schemas
