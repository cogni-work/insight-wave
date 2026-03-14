---
name: findings-creator-file
description: >
  Create research findings from a local PDF-based document store using file-based semantic search.
  Converts PDFs to searchable Markdown, uses Grep/Glob for discovery, and creates standardized finding entities.
  Use when: (1) querying a local rag-store/{store-slug} document store, (2) user wants to search PDF documents semantically,
  (3) creating findings from curated document collections, (4) user mentions "document store", "file store", or references
  a rag-store/ path. Supports both indexing (PDF→Markdown) and querying (search→findings) workflows.
---

# Local File-Based Findings Creator

Create research findings by semantically searching a local PDF document store.

## Environment Variables

When invoked via the findings-creator-file agent, these environment variables are passed:

| Variable | Required | Description |
|----------|----------|-------------|
| `REFINED_QUESTION_PATH` | No | Absolute path to refined question entity (enables question linking) |
| `PROJECT_PATH` | No | Absolute path to research project directory |
| `STORE_PATH` | No | Absolute path to document store (alternative to explicit path in prompt) |
| `CONTENT_LANGUAGE` | No | Target language for generated content (default: "en") |

**Agent Invocation Mode:** When `REFINED_QUESTION_PATH` is set, the skill operates in "agent mode":
- Search terms are extracted from the question entity's `dc:title` field
- Created findings include `question_ref` backlink to the source question
- Output is written to `${PROJECT_PATH}/04-findings/data/`

**Direct Invocation Mode:** When `REFINED_QUESTION_PATH` is not set, the skill operates in "direct mode":
- Search terms are extracted from the user's natural language query
- No question backlink is added to findings
- Output directory must be specified or defaults to current project

## Store Structure

```
{workspace}/rag-store/{store-slug}/
├── config.yaml         # Store configuration (required)
├── sources/            # Original PDF files
│   └── *.pdf
└── documents/          # Indexed markdown (generated)
    └── *.md
```

**config.yaml format:**

```yaml
name: "Store Display Name"
website_url: "https://example.com/publications"  # For citations
source_reliability: 0.65                          # Quality score (0.50-0.80)
description: "Description of this document collection"
```

## Critical Constraints

### No Fabrication Rule

**Every finding MUST originate from actual document text.**

| Prohibited | Consequence |
|------------|-------------|
| Inventing content not in documents | Exit with error |
| Fabricating statistics without source text | Reject finding |
| Creating metadata from inference | Use explicit fallback |
| Generating content when no matches | Create "no-results" response |

### Content-Source Coherence

**All extracted content must trace directly to source document passages.**

| Validation | Check |
|------------|-------|
| Document title | Must match YAML frontmatter `title` field |
| Quoted passages | Must exist verbatim in source document |
| Data points | Must appear in source document text |
| Statistics | Must be copied exactly, not rounded or paraphrased |

### Grep Result Fidelity

**Search results define the boundary of available content.**

- Only extract content from documents returned by Grep
- Never supplement Grep results with assumed knowledge
- If Grep returns no matches, report explicitly (do not synthesize)
- Match count from Grep must equal documents analyzed

## Two Operational Modes

### Mode 1: Index Store

Convert PDFs to searchable Markdown documents.

**Trigger:** User asks to "index", "set up", or "initialize" a document store.

**Execute:**

```bash
python "${CLAUDE_PLUGIN_ROOT}/skills/findings-creator-file/scripts/index-pdfs.py" "{store-path}"
```

**Options:**
- `--init`: Create new store with default config
- `--force`: Re-index existing documents

**Output:** Markdown files in `documents/` with YAML frontmatter containing title, keywords, page count.

### Mode 2: Query Store (Create Findings)

Search documents and create finding entities. This is the primary workflow.

## Query Workflow

### Phase 0: Environment Resolution (Agent Mode Only)

> **Shared pattern:** See [references/findings-creator-shared/environment-resolution.md](../../references/findings-creator-shared/environment-resolution.md) for the canonical environment resolution steps shared across all findings-creator variants. This variant uses a minimal agent-mode resolution (question loading + store path).

When `REFINED_QUESTION_PATH` environment variable is set:

1. **Load refined question entity:**

   ```bash
   # Read question file
   cat "${REFINED_QUESTION_PATH}"
   ```

   Extract from YAML frontmatter:
   - `dc:title` - primary search terms
   - `dc:identifier` - for question_ref backlink
   - `content_language` - if CONTENT_LANGUAGE not explicitly set
   - `dimension_ref` - for dimension tag (extract slug from wikilink path, e.g., `[[01-research-dimensions/data/dimension-digitale-wertetreiber-i9j0k1l2]]` → `digitale-wertetreiber`)

2. **Extract search terms from question:**

   Parse the `dc:title` field to extract key search terms:
   - Remove question words (what, how, which, etc.)
   - Extract noun phrases and key concepts
   - Use these as primary Grep search patterns

3. **Set output directory:**

   ```bash
   FINDINGS_DIR="${PROJECT_PATH}/04-findings"
   ```

4. **Store question reference for backlinks:**

   ```bash
   QUESTION_ID=$(basename "${REFINED_QUESTION_PATH}" .md)
   QUESTION_REF="[[02-refined-questions/data/${QUESTION_ID}]]"
   ```

**Skip Phase 0** when `REFINED_QUESTION_PATH` is not set (direct invocation mode).

### Phase 1: Resolve Store and Load Config

1. **Identify store path** from environment or user input:
   - Environment: `${STORE_PATH}` (if set by agent)
   - Explicit: `rag-store/smarter-service`
   - From project: `${PROJECT_PATH}/rag-store/{store-slug}`

2. **Load config.yaml:**

   ```bash
   # Read store configuration
   config_path="{store-path}/config.yaml"
   ```

   Extract:
   - `website_url` - for citations
   - `source_reliability` - for quality scoring (default: 0.65)
   - `name` - for finding metadata

3. **Verify documents exist:**

   ```bash
   ls "{store-path}/documents/"*.md
   ```

   If empty: prompt user to run indexing first.

4. **Verification Checkpoint (P1 Gate):**
   - Confirm config.yaml parsed successfully
   - Confirm `website_url` and `source_reliability` extracted
   - Confirm `documents/` contains ≥1 `.md` file
   - Log: `"CHECKPOINT P1: Store validated - {N} documents available"`
   - If any check fails: Return error with specific failure reason

### Phase 2: Search Documents

Use Grep to find relevant content across all indexed documents.

1. **Extract search terms** from user query or refined question
2. **Search with Grep:**

   ```
   Grep pattern="{search-terms}" path="{store-path}/documents/" output_mode="content" -C=3
   ```

3. **Identify top candidate documents** based on match density and relevance

4. **Verification Checkpoint (P2 Gate):**
   - Count Grep matches: `MATCH_COUNT`
   - If `MATCH_COUNT == 0`: Report "No documents match query" (explicit no-results)
   - If `MATCH_COUNT > 0`: Log `"CHECKPOINT P2: {MATCH_COUNT} documents match search"`
   - Store match count for verification in Phase 3

### Phase 3: Load and Analyze Documents

1. **Read full content** of top 2-3 matching documents (no truncation)

2. **Verification Checkpoint (P3 Gate):**
   - Verify: Loaded document count matches expected from Phase 2
   - Verify: Each document has valid YAML frontmatter with `title` field
   - Log: `"CHECKPOINT P3: {N} documents loaded completely"`

3. **Apply Extended Thinking for Document Analysis:**

   Use extended thinking to evaluate each document's relevance:

   ```
   <thinking>
   **Document Analysis for: {document_title}**

   1. **Query Alignment Assessment:**
      - Core query terms identified: {list}
      - Terms found in document: {list}
      - Coverage: {high/medium/low}

   2. **Content Relevance:**
      - Relevant passages identified: {count}
      - Direct answer to query: {yes/partially/no}
      - Evidence quality: {specific data/general claims/none}

   3. **Extraction Decision:**
      - Recommend for finding extraction: {yes/no}
      - Rationale: {brief explanation}
   </thinking>
   ```

4. **Extract key passages** that address the research question
   - Only extract content that exists verbatim or closely paraphrased in document
   - Never synthesize content from training knowledge
   - Flag any gaps: "Source does not address {aspect}"

### Phase 4: Create Finding Entities

> **Shared references:**
> - Quality framework: [references/findings-creator-shared/quality-assessment.md](../../references/findings-creator-shared/quality-assessment.md) (file variant uses 40/30/20/10 weights with config-based reliability)
> - Entity creation: [references/findings-creator-shared/entity-creation-contract.md](../../references/findings-creator-shared/entity-creation-contract.md) (`finding-file-` prefix, coherence validation gate)

For each relevant extraction that meets quality threshold:

1. **Generate identifiers:**

   ```
   semantic_slug = slugify(finding_title)[:40]
   hash = random_hex(8)
   finding_id = "finding-file-{semantic_slug}-{hash}"
   ```

2. **Calculate quality scores with Extended Thinking:**

   Apply extended thinking to justify each dimension score:

   ```
   <quality-assessment>
   **Finding:** {finding_title}
   **Source Document:** {document_filename}

   **Dimension Analysis:**

   1. **Topical Relevance (40%):** {score}
      - Query terms: {list}
      - Document coverage: {high/medium/low}
      - Evidence: "{quoted passage demonstrating relevance}"
      - Rationale: {why this score}

   2. **Content Completeness (30%):** {score}
      - Word count: {N} words
      - Specific data points: {count}
      - Rationale: {why this score}

   3. **Source Reliability (20%):** {score from config.yaml}
      - Config value: {source_reliability}
      - Store type: {description}

   4. **Evidentiary Value (10%):** {score}
      - Statistics present: {yes/no}
      - Methodology described: {yes/no}
      - Rationale: {why this score}

   **Composite Calculation:**
   ({rel} × 0.40) + ({comp} × 0.30) + ({reliability} × 0.20) + ({evid} × 0.10) = {composite}

   **Threshold Decision:** {composite} {>=/<} 0.50 → {PASS/FAIL}
   </quality-assessment>
   ```

   See [references/finding-output-format.md](references/finding-output-format.md) for dimension definitions.

3. **Apply threshold:** composite >= 0.50 -> PASS

4. **Content-Source Coherence Validation (P4 Gate):**

   Before creating finding entity, verify content traces to source:

   ```
   <coherence-check>
   **Source Document:** {source_document}

   **Content Verification:**
   - [ ] Finding title derives from document content (not invented)
   - [ ] All statistics appear in source document
   - [ ] All quoted passages exist verbatim in document
   - [ ] Document title matches frontmatter exactly

   **Evidence Inventory:**
   | Claim in Finding | Location in Source |
   |------------------|-------------------|
   | {claim_1} | {section/paragraph reference} |
   | {claim_2} | {section/paragraph reference} |

   **Coherence Status:** {PASS/FAIL}
   </coherence-check>
   ```

   If coherence fails: Log rejection, skip finding creation, continue to next candidate.

5. **Write finding entity** to `${PROJECT_PATH}/${FINDINGS_DIR}/data/{finding_id}.md`

   See [references/finding-output-format.md](references/finding-output-format.md) for complete entity structure.

### Phase 5: Report Results

Return summary:

```json
{
  "success": true,
  "store": "{store-slug}",
  "documents_searched": N,
  "findings_created": N,
  "findings_rejected": N,
  "output_directory": "{FINDINGS_DIR}/data/"
}
```

## Quick Reference

### Initialize New Store

```bash
python scripts/index-pdfs.py /path/to/rag-store/my-store --init
```

Then edit `config.yaml` and add PDFs to `sources/`.

### Index PDFs

```bash
python scripts/index-pdfs.py /path/to/rag-store/my-store
```

### Query Pattern

1. Grep for keywords in `{store}/documents/*.md`
2. Read top matches fully
3. Extract findings with citations
4. Write finding entities

## Chain-of-Thought (COT) Protocol

This skill requires explicit reasoning before key decisions. **Do not skip reasoning blocks** - they prevent hallucination and ensure findings derive from source content.

### When COT is Required

| Phase | Step | Reasoning Type | Purpose |
|-------|------|----------------|---------|
| Phase 2 | Search | Query Formulation | Ensure search terms derive from user query |
| Phase 3 | Analysis | Document Evaluation | Justify document relevance assessment |
| Phase 3 | Extraction | Content Selection | Verify passages exist in source |
| Phase 4 | Quality | Score Justification | Prevent arbitrary scoring |
| Phase 4 | Coherence | Source Verification | Confirm content traces to document |

### Reasoning Block Formats

**Document Analysis Reasoning** (Phase 3):

```
<thinking>
**Document:** {filename}
**Query:** {user_query}

**Alignment Assessment:**
- Key terms in query: {list}
- Terms found in document: {list}
- Relevance: {high/medium/low/none}

**Content Extraction:**
- Relevant sections: {list with locations}
- Gaps: {what query asks for but document lacks}

**Decision:** {include/exclude} because {reason}
</thinking>
```

**Quality Assessment Reasoning** (Phase 4): See `<quality-assessment>` block in Phase 4.

**Coherence Validation** (Phase 4): See `<coherence-check>` block in Phase 4.

### Why COT Matters

Without explicit reasoning:
- **Content fabrication**: Findings may include claims not in source documents
- **Score inflation**: Quality scores assigned without justification
- **Missing attribution**: Source passages not traced to specific locations
- **False completeness**: Gaps in source content filled with training knowledge

## Finding Entity Key Fields

| Field | Source | Example |
|-------|--------|---------|
| `dc:creator` | Fixed | `"findings-creator-file"` |
| `source_type` | Fixed | `"local_file"` |
| `file_store` | Store slug | `"smarter-service"` |
| `source_document` | Document filename | `"trendbook-2024.md"` |
| `source_url` | config.yaml | `"https://example.com/publications"` |
| `source_reliability` | config.yaml | `0.65` |
| `coherence_validated` | P4 Gate | `true` |
| `quality_reasoning` | Extended thinking | `"PASS: 0.62 composite"` |
| `question_ref` | Phase 0 (agent mode) | `"[[02-refined-questions/data/digitalisierung-q1]]"` |

**Agent Mode Fields:** When `REFINED_QUESTION_PATH` is set, findings include:
- `question_ref`: Wikilink to source refined question (enables bidirectional navigation)
- `content_language`: From question frontmatter or CONTENT_LANGUAGE env var
- `tags`: Must include `dimension/{dimension-slug}` extracted from question's `dimension_ref` field

## Anti-Hallucination Safeguards

This skill implements all 5 anti-hallucination patterns from [anti-hallucination-foundations.md](../../references/anti-hallucination-foundations.md):

### Pattern 1: Complete Entity Loading

- Load ALL matching documents before processing (no truncation)
- Verify count matching: Grep results == documents analyzed
- Halt on mismatch (never proceed with incomplete data)

**Implementation:**
- Phase 2: Count Grep matches before proceeding
- Phase 3: Verify loaded document count matches expected
- Log: `"VERIFICATION: All {N} matching documents loaded"`

### Pattern 2: Verification Checkpoints

- Mandatory checkpoint at each of 4 phase boundaries
- Validate outputs before proceeding to next phase
- Log verification status at every checkpoint

**Phase Gates:**

| Gate | Location | Validation |
|------|----------|------------|
| P1→P2 | After config load | config.yaml exists, required fields present |
| P2→P3 | After search | Grep returned ≥1 result OR explicit "no results" |
| P3→P4 | After document load | Document content loaded completely |
| P4→P5 | After extraction | Quality score calculated, coherence validated |

### Pattern 3: Evidence-Based Processing

- All findings grounded exclusively in loaded document text
- Validate document existence before extracting content
- Use explicit fallback when no relevant content found

**Content Constraint:** Only use text that appears in the indexed Markdown documents. When a document doesn't contain requested information, state this explicitly. Never synthesize content from training knowledge.

### Pattern 4: No Fabrication Rule

- Never invent statistics, data, or methodology claims
- Preserve exact phrasing from source documents
- Apply lower quality scores for sparse content (honest assessment)
- Flag limitations transparently in finding content

**Anti-Patterns to Avoid:**

| Anti-Pattern | Wrong Approach | Correct Approach |
|--------------|----------------|------------------|
| Fabricated stats | Invent "67% adoption rate" | Use only stats from document text |
| Strengthened language | "may improve" → "improves" | Preserve original: "may improve" |
| Synthesized methodology | Create fake study details | State: "Methodology not specified in source" |
| Gap filling | Invent content for missing info | State: "Source does not address {aspect}" |

### Pattern 5: Provenance Integrity

- Document references from actual frontmatter metadata
- Complete audit trail with quality metadata
- All source references trace to indexed documents

**Audit Fields:**
- `source_document`: Exact filename from `documents/` directory
- `source_document_title`: From document YAML frontmatter
- `file_store`: Store slug from path
- `source_url`: From config.yaml `website_url`
- `coherence_validated`: Boolean confirming content-source check passed

## Error Handling

| Condition | Action |
|-----------|--------|
| Store not found | Return error with path guidance |
| No documents indexed | Prompt to run indexing |
| No matches found | Report "no relevant content found" |
| Quality below threshold | Log rejection, continue |

## Dependencies

**For indexing script:**

```bash
pip install pdfplumber pyyaml
```

**For querying:** Uses Claude Code's built-in Grep, Glob, and Read tools.
