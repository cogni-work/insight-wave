---
name: export-rag
description: |
  Export research project as flat markdown optimized for RAG pipelines and Claude Projects.
  Produces a single concatenated markdown file with all findings, sources, and claims formatted
  for retrieval-augmented generation. Use when user wants to feed research into a RAG system,
  add research to Claude Projects, create a knowledge base export, or needs flat markdown output.
---

# Export RAG

Generate a flat markdown file optimized for RAG (Retrieval-Augmented Generation) pipelines and Claude Projects.

## Quick Start

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/export-rag/scripts/export_rag.py" \
  --project /path/to/research-project \
  --output research-export.md
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project` | Yes | - | Path to research project root |
| `--output` | No | `{project}/research-rag-export.md` | Output markdown file path |

## Prerequisites

- At minimum, findings-sources completed (findings + sources exist)
- Ideally, full pipeline completed through synthesis

## Output Format

Single markdown file with sections:
1. Research question and dimensions
2. All findings (with source attribution)
3. All claims (with confidence scores)
4. Source inventory (URLs, publisher info, citations)
5. Synthesis narrative (if available)
