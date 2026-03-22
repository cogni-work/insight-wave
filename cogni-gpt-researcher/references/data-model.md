# cogni-gpt-researcher Data Model Reference

## Project Structure

```
cogni-gpt-researcher/{project-slug}/
├── project-config.json                    # Research configuration
├── 00-sub-questions/
│   └── data/
│       └── sq-{topic}-{hash}.md           # Decomposed research questions
├── 01-contexts/
│   └── data/
│       └── ctx-{topic}-{hash}.md          # Per-sub-question research results
├── 02-sources/
│   └── data/
│       └── src-{domain}-{hash}.md         # Deduplicated source registry
├── 03-report-claims/
│   └── data/
│       └── rc-{topic}-{hash}.md           # Claims extracted from draft
├── report.md                              # Final report output
└── .metadata/
    └── execution-log.json                 # Phase state and cost tracking
```

## Entity Schemas

All entities are markdown files with YAML frontmatter, Obsidian-browsable. They use Dublin Core metadata (`dc:identifier`, `dc:created`, `dc:creator`), wikilinks for cross-references, and ISO 8601 timestamps. Entities are created exclusively via `scripts/create-entity.sh`.

### SubQuestion (`00-sub-questions/`)

Decomposed research queries derived from the user's topic. Each sub-question maps to one report section.

```json
{
  "schema_version": "1.0",
  "entity_type": "sub-question",
  "dc:identifier": "sq-llm-hallucination-a1b2c3d4",
  "dc:created": "2026-03-15T14:30:00Z",
  "dc:creator": "research-report",
  "query": "What are the primary causes of citation hallucination in large language models?",
  "parent_topic": "LLM citation reliability",
  "section_index": 0,
  "report_type": "detailed",
  "status": "researched"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `dc:identifier` | Yes | Unique ID: `sq-{topic-slug}-{8-char-hex}` |
| `query` | Yes | The decomposed sub-question text (min 10 chars) |
| `parent_topic` | Yes | Original user research topic |
| `section_index` | Yes | Position in report outline (0-based) |
| `report_type` | Yes | `basic`, `detailed`, `deep`, `outline`, or `resource` |
| `status` | Yes | `pending` → `researched` / `failed` |
| `search_guidance` | No | Focus hints for the section-researcher |
| `tree_path` | No | Deep mode: path in research tree (e.g., `1.2.1`) |
| `parent_ref` | No | Deep mode: wikilink to parent sub-question |

### Context (`01-contexts/`)

Per-sub-question research results with source references and key findings.

```json
{
  "schema_version": "1.0",
  "entity_type": "context",
  "dc:identifier": "ctx-llm-hallucination-e5f6a7b8",
  "dc:created": "2026-03-15T14:35:00Z",
  "dc:creator": "section-researcher",
  "sub_question_ref": "[[00-sub-questions/data/sq-llm-hallucination-a1b2c3d4]]",
  "source_refs": [
    "[[02-sources/data/src-arxiv-c9d0e1f2]]",
    "[[02-sources/data/src-nature-3a4b5c6d]]"
  ],
  "key_findings": [
    {
      "finding": "14-95% of LLM citations are hallucinated depending on domain",
      "source_ref": "[[02-sources/data/src-arxiv-c9d0e1f2]]",
      "confidence": 0.92
    }
  ],
  "search_queries_used": ["LLM citation hallucination rate study 2025"],
  "word_count": 1250
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `dc:identifier` | Yes | Unique ID: `ctx-{topic-slug}-{8-char-hex}` |
| `sub_question_ref` | Yes | Wikilink to the sub-question this answers |
| `source_refs` | Yes | Wikilinks to cited source entities (min 1) |
| `key_findings` | No | Structured findings with source attribution and confidence |
| `search_queries_used` | Yes | WebSearch queries executed |
| `word_count` | No | Word count of the context body |
| `follow_up_questions` | No | Deep mode: questions for recursive exploration |

### Source (`02-sources/`)

Deduplicated URL-level records of web pages cited across contexts.

```json
{
  "schema_version": "1.0",
  "entity_type": "source",
  "dc:identifier": "src-arxiv-c9d0e1f2",
  "dc:created": "2026-03-15T14:32:00Z",
  "dc:creator": "section-researcher",
  "url": "https://arxiv.org/html/2602.06718",
  "title": "GhostCite: A Large-Scale Study on Citation Hallucination",
  "publisher": "arXiv",
  "fetch_method": "WebFetch",
  "fetched_at": "2026-03-15T14:32:00Z",
  "content_hash": "a1b2c3d4",
  "cited_by": [
    "[[01-contexts/data/ctx-llm-hallucination-e5f6a7b8]]"
  ]
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `dc:identifier` | Yes | Unique ID: `src-{domain-slug}-{8-char-hex}` |
| `url` | Yes | Source URL |
| `title` | Yes | Page or article title |
| `publisher` | No | Publisher or domain name |
| `fetch_method` | Yes | `WebFetch` or `WebSearch-snippet` |
| `fetched_at` | Yes | ISO 8601 fetch timestamp |
| `content_hash` | No | SHA-256 prefix (8 chars) for deduplication |
| `cited_by` | No | Wikilinks to context entities citing this source |

### ReportClaim (`03-report-claims/`)

Verifiable assertions extracted from the draft report, bridging to cogni-claims for source verification.

```json
{
  "schema_version": "1.0",
  "entity_type": "report-claim",
  "dc:identifier": "rc-citation-rates-7e8f9a0b",
  "dc:created": "2026-03-15T16:00:00Z",
  "dc:creator": "claim-extractor",
  "statement": "14-95% of LLM citations are hallucinated depending on domain",
  "source_ref": "[[02-sources/data/src-arxiv-c9d0e1f2]]",
  "source_url": "https://arxiv.org/html/2602.06718",
  "source_title": "GhostCite: A Large-Scale Study on Citation Hallucination",
  "draft_version": 1,
  "section": "Key Findings",
  "verification_status": "verified"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `dc:identifier` | Yes | Unique ID: `rc-{topic-slug}-{8-char-hex}` |
| `statement` | Yes | The verifiable claim text (min 10 chars) |
| `source_ref` | Yes | Wikilink to the source entity |
| `source_url` | Yes | Direct URL for cogni-claims submission |
| `source_title` | Yes | Source title for cogni-claims submission |
| `draft_version` | Yes | Which draft version this was extracted from |
| `section` | Yes | Report section containing this claim |
| `claims_submission_id` | No | ID in cogni-claims after submission |
| `verification_status` | No | `pending` → `verified` / `deviated` / `source_unavailable` |
| `deviation_type` | No | If deviated: misquotation, unsupported_conclusion, selective_omission, data_staleness, source_contradiction |
| `deviation_severity` | No | If deviated: low, medium, high, critical |

## Entity Relationships

```
SubQuestion ──1:1──▶ Context ──N:M──▶ Source
     │                                    ▲
     │ (deep mode)                        │
     └──▶ SubQuestion (child)    ReportClaim ──1:1──┘
```

- Each SubQuestion produces exactly one Context
- Each Context references one or more Sources
- Sources are deduplicated by URL — multiple Contexts can cite the same Source
- ReportClaims are extracted from the draft and link back to Sources for verification
- In deep mode, SubQuestions can have parent-child relationships via `tree_path` and `parent_ref`

## Cross-Plugin Integration

| Target Plugin | Direction | Contract |
|---------------|-----------|----------|
| cogni-claims | Export | ReportClaims are submitted as ClaimRecords for source verification |
| cogni-narrative | Export | Report output serves as source for story arc transformation |
| cogni-copywriting | Export | Narrative output receives arc-aware executive polish |
| cogni-visual | Export | Report content feeds presentation generation |
