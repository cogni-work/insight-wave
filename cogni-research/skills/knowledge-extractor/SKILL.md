---
name: knowledge-extractor
description: "[Internal] Extract concepts and megatrends from research findings. Invoked by deeper-research-2."
---

# Knowledge Extractor

Extract recurring technical terms from findings, synthesize definitions, create concept entities with provenance chains, and cluster related findings into megatrend entities.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--project-path` | Yes | Research project directory |
| `--content-language` | No | Output language ISO 639-1 code (default: en) |
| `--dimension` | No | Dimension slug to filter findings (enables parallel extraction) |
| `--concepts-only` | No | Skip megatrend clustering phases 5-7 (for parallel execution) |

## Critical: Path Construction Rule

**NEVER construct entity directory paths from memory.** Always use the resolved variables from Phase 1:

| Wrong (hallucinated) | Correct (use variable) |
|---------------------|------------------------|
| `03-dimensions/` | `${DIMENSIONS_DIR}/` |
| `research-dimensions/` | `${DIMENSIONS_DIR}/` |
| `dimensions/` | `${DIMENSIONS_DIR}/` |
| `findings/` | `${FINDINGS_DIR}/` |
| `concepts/` | `${DOMAIN_CONCEPTS_DIR}/` |

The actual directory names (e.g., `01-research-dimensions`, `04-findings`) are resolved dynamically by Phase 1 and stored in environment variables. Using any other path names will cause failures.

**Phase 1 outputs a directory listing** - use ONLY those exact names.

## References Index

Read references **only when needed** for the specific task:

| Reference | Read when... |
|-----------|--------------|
| [references/workflows/phase-1-setup.md](references/workflows/phase-1-setup.md) | Starting execution (Phase 1) |
| [references/workflows/phase-2-loading.md](references/workflows/phase-2-loading.md) | Loading findings (Phase 2) |
| [references/workflows/phase-3-term-analysis.md](references/workflows/phase-3-term-analysis.md) | Analyzing terms (Phase 3) |
| [references/workflows/phase-4-concept-creation.md](references/workflows/phase-4-concept-creation.md) | Creating concepts (Phase 4) |
| [references/workflows/phase-5-megatrend-clustering.md](references/workflows/phase-5-megatrend-clustering.md) | Clustering megatrends (Phase 5) |
| [references/workflows/phase-6-backlinks.md](references/workflows/phase-6-backlinks.md) | Updating backlinks (Phase 6) |
| [references/workflows/phase-7-readme-generation.md](references/workflows/phase-7-readme-generation.md) | Generating README mindmaps (Phase 7) |
| [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md) | Verification needed |
| [references/domain/entity-templates.md](references/domain/entity-templates.md) | Creating entities |

## Immediate Action: Initialize TodoWrite

**⛔ MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 1: Setup & Validation [in_progress]
2. Phase 2: Finding Loading [pending]
3. Phase 3: Term Analysis [pending]
4. Phase 4: Concept Creation [pending]
5. Phase 4.5: Concepts-Only Exit (if `--concepts-only`) [pending]
6. Phase 5: Megatrend Clustering (skip if `--concepts-only`) [pending]
7. Phase 6: Backlink Update (skip if `--concepts-only`) [pending]
8. Phase 7: README Generation (skip if `--concepts-only`) [pending]

Update todo status as you progress through each phase.

**Note:** Each phase will add step-level todos when started (progressive expansion from 8 phase-level to ~25-35 step-level). Phases 5-7 are skipped when `--concepts-only` flag is set.

---

## Progressive TodoWrite Expansion

The knowledge-extractor workflow uses **progressive disclosure** for TodoWrite tracking:

- **Initial state:** 7 phase-level todos (shown above)
- **Progressive expansion:** Each phase adds its step-level todos when started
- **Final state:** ~25-35 step-level todos across all phases

**Pattern:** As you enter each phase, the phase workflow file provides TodoWrite templates to expand phase-level todos into granular step-level tasks. This prevents overwhelming initial context while maintaining detailed tracking.

---

## Core Workflow

**CRITICAL**: This skill uses progressive disclosure. Each phase reference contains essential procedural details NOT duplicated here.

### Execution Protocol

1. **First**: Read the phase reference file BEFORE executing that phase
2. **Per-phase**: The reference contains the actual implementation steps
3. **Validation**: Each phase has verification checkpoints in its reference

**⛔ MANDATORY: Read the phase reference file BEFORE executing that phase.**

- SKILL.md provides only navigation
- Phase workflow files provide execution details, TodoWrite templates, and verification gates
- **Do NOT skip reference reads** - they contain the three-layer enforcement architecture (self-verification, step-level todos, automated gates)

### Phase 1: Setup & Validation

Read [references/workflows/phase-1-setup.md](references/workflows/phase-1-setup.md), then execute its steps:

1. Parse parameters
2. Validate PROJECT_PATH with validate-working-directory.sh
3. Initialize logging
4. **Resolve entity directory names** (exports `FINDINGS_DIR`, `DOMAIN_CONCEPTS_DIR`, `MEGATRENDS_DIR`, etc.)

### Phase 2: Finding Loading

Read [references/workflows/phase-2-loading.md](references/workflows/phase-2-loading.md), then execute its steps:

1. List findings: `${PROJECT_PATH}/${FINDINGS_DIR}/data/*.md`
2. Early exit if <2 findings (return success JSON)
3. Build finding-to-dimension mapping
4. Extract and store finding UUIDs

### Phase 3: Term Analysis

Read [references/workflows/phase-3-term-analysis.md](references/workflows/phase-3-term-analysis.md), then execute its steps:

1. Build term frequency map across all findings
2. Filter to terms appearing in 2+ findings
3. Prioritize: Frameworks, metrics, techniques, methodologies, tools, standards
4. Exclude: Proper nouns, generic terms, opinions

### Phase 4: Concept Creation

Read [references/workflows/phase-4-concept-creation.md](references/workflows/phase-4-concept-creation.md), then execute its steps:

1. For each candidate term, locate all findings
2. Synthesize definition from findings only
3. Check duplicates, calculate confidence
4. Write entity file to `${DOMAIN_CONCEPTS_DIR}/data/`

### Phase 4.5: Concepts-Only Exit (Conditional)

**Condition:** If `--concepts-only` flag is set, skip Phases 5-7 and return intermediate results.

**When to use:** During parallel dimension-based extraction, where megatrend clustering is deferred to the merge phase.

**Exit Response:**

```json
{
  "success": true,
  "mode": "concepts-only",
  "dimension": "{DIMENSION_FILTER or null}",
  "concepts_created": 12,
  "recurring_terms_analyzed": 25
}
```

**Implementation:**

```bash
if [ "$CONCEPTS_ONLY" = true ]; then log_phase "Phase 4.5: Concepts-Only Exit" "complete" ; echo "{\"success\": true, \"mode\": \"concepts-only\", \"dimension\": \"$DIMENSION_FILTER\", \"concepts_created\": $concepts_created}" ; exit 0 ; fi
```

### Phase 5: Megatrend Clustering (Dual-Source)

Read [references/workflows/phase-5-megatrend-clustering.md](references/workflows/phase-5-megatrend-clustering.md), then execute its steps:

1. Load seed megatrends from `.metadata/seed-megatrends.yaml` (if exists, from dimension-planner Phase 4b)
2. Perform bottom-up semantic clustering of findings by thematic similarity
3. Match clusters against seed megatrends (hybrid/seeded/clustered source types)
4. Generate TIPS-style strategic narrative for each megatrend (600-900 words)
5. Calculate evidence strength and confidence scores
6. Create megatrend entities in `${MEGATRENDS_DIR}/data/`
7. Generate gap report for unmatched seeds (`.metadata/megatrend-gap-report.md`)

### Phase 6: Backlink Update

Read [references/workflows/phase-6-backlinks.md](references/workflows/phase-6-backlinks.md), then execute its steps:

1. Update dimension frontmatter with `concept_ids` and `megatrend_ids`
2. Track backlink counts

### Phase 7: README Generation

Read [references/workflows/phase-7-readme-generation.md](references/workflows/phase-7-readme-generation.md), then execute its steps:

1. Collect all concepts and their finding references
2. Collect all megatrends and their finding references
3. Generate `${DOMAIN_CONCEPTS_DIR}/README.md` with mermaid mindmap: `concepts (root) -> concept -> findings`
4. Generate `${MEGATRENDS_DIR}/README.md` with mermaid mindmap: `megatrends (root) -> megatrend -> findings`

**NOTE:** README files are placed in entity root directories, while entity files remain in `/data/` subdirectories.
5. Include Entity Index tables with wikilinks
6. Return JSON response

```json
{"success": true, "concepts_created": 12, "megatrends_created": 5, "dimensions_updated": 4, "backlinks_added": 17, "readme_generation": {"concepts_readme": true, "megatrends_readme": true}}
```

## Critical Requirements

### Anti-Hallucination Rules

- NEVER define terms not in findings
- NEVER add external knowledge
- ALWAYS quote/paraphrase finding content only

**Read:** [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md)

### Output Language

- **Target language:** Definitions, characteristics, category names, megatrend descriptions
- **English always:** Filenames, YAML keys, technical tags

## Error Handling

| Scenario | Exit | Response |
|----------|------|----------|
| Missing PROJECT_PATH | 1 | Error JSON |
| <2 findings | 0 | Success, 0 concepts, 0 megatrends |
| No recurring terms | 0 | Success, 0 concepts (continue to megatrends) |
| No keyword clusters (3+) | 0 | Success, 0 megatrends |
| Confidence <0.90 | 0 | Skip concept/megatrend |
| Duplicate exists | 0 | Skip concept/megatrend |

## Debugging

Enable verbose output: `export DEBUG_MODE=true`

Log file: `${PROJECT_PATH}/.metadata/knowledge-extractor-execution-log.txt`
