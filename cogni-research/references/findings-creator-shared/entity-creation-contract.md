# Shared Entity Creation Contract

All findings-creator variants create `04-findings` entities via `create-entity.sh`. This reference defines the shared invocation pattern and variant-specific metadata.

## Script

`${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh`

## Parameter Contract

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--project-path` | YES | Full path to project directory |
| `--entity-type` | YES | Always `04-findings` |
| `--entity-id` | NO | Custom entity ID (format: `finding-{prefix}-{slug}-{8-char-hash}`) |
| `--data` | YES | JSON with `frontmatter` and `content` nested objects |
| `--json` | NO | Output JSON format for parsing |

## Invocation Pattern (Heredoc)

```bash
cat << 'ENTITY_JSON' | bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "04-findings" \
  --entity-id "{finding_id}" \
  --data - \
  --json
{"frontmatter": {...}, "content": "# Finding body\n\n..."}
ENTITY_JSON
```

## Write Tool Prohibition

**NEVER use Write tool for entity files.** `create-entity.sh` provides:
- YAML frontmatter validation
- Entity index updates
- File-level locking
- Deduplication checks
- Atomic writes

## dc:identifier Prefix Convention

| Variant | Prefix | Example |
|---------|--------|---------|
| findings-creator (web) | `finding-` | `finding-market-trends-a1b2c3d4` |
| findings-creator-llm | `finding-llm-` | `finding-llm-digital-shift-e5f6g7h8` |
| findings-creator-file | `finding-file-` | `finding-file-revenue-model-i9j0k1l2` |

Pattern: `^finding(-llm|-file)?-[a-z0-9-]+-[a-f0-9]{8}$`

## dc:creator Values

| Variant | dc:creator |
|---------|-----------|
| findings-creator (web) | `findings-creator` |
| findings-creator-llm | `findings-creator-llm` |
| findings-creator-file | `findings-creator-file` |

## Shared Frontmatter Fields

All variants include these fields:

```yaml
dc:title: "Finding: {semantic-title}"
dc:identifier: "{prefix}{slug}-{8-char-hash}"
dc:created: "{ISO 8601 timestamp}"
dc:type: "finding"
dc:creator: "{variant}"
entity_type: "finding"
finding_text: "{1-2 sentence summary}"
schema_version: "3.0"
quality_score: {0.00-1.00}
quality_status: "{PASS|FAIL}"
confidence_level: "{high|medium|low}"
quality_dimensions:
  topical_relevance: {0.00-1.00}
  content_completeness: {0.00-1.00}
  source_reliability: {0.00-1.00}
  evidentiary_value: {0.00-1.00}
source_id: ""
```

## Variant-Specific Frontmatter

### Web (findings-creator)

```yaml
tags: [finding, source/web, dimension/{slug}]
source_url: "{actual_website_URL}"
source_type: "web_search"
content_source: "{webfetch|snippet}"
webfetch_success: {true|false}
enhanced_content_retrieved: {true|false}
batch_ref: "[[03-query-batches/data/{batch-id}]]"
question_ref: "[[02-refined-questions/data/{question-id}]]"
```

### LLM (findings-creator-llm)

```yaml
tags: [finding, source/llm, dimension/{slug}]
source_type: "llm_internal_knowledge"
source_url: "{system_card_PDF_URL}"
llm_model: "{LLM_MODEL_ID}"
llm_knowledge_cutoff: "{YYYY-MM}"
content_source: "llm_internal"
webfetch_success: false
enhanced_content_retrieved: false
finding_type: "qualitative"
question_ref: "[[02-refined-questions/data/{question-id}]]"
```

### File (findings-creator-file)

```yaml
tags: [finding, source/file, dimension/{slug}]
source_type: "local_file"
source_url: "{website_url from config.yaml}"
file_store: "{store-slug}"
source_document: "{document_filename}"
content_source: "file_store"
coherence_validated: true
question_ref: "[[02-refined-questions/data/{question-id}]]"
```

## 5-Section Markdown Body

All variants produce the same 5-section structure (language-aware headers from `references/language-templates.md`):

1. **Content** (150-300 words)
2. **Key Trends** (3-6 bullets)
3. **Methodology & Data Points** (variant-specific disclaimer for LLM/file)
4. **Relevance Assessment** (auto-generated from quality scores)
5. **Source** (URL, entity placeholders)

See `references/templates/finding-template.md` for complete template with examples.
