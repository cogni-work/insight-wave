---
name: knowledge-merger
description: "[Internal] Merge concepts from parallel extraction and cluster megatrends across dimensions. Invoked by deeper-research-2."
---

# Knowledge Merger

---

## ⛔ INVOCATION GUARD - READ BEFORE PROCEEDING

**This is an EXECUTOR skill. It should NOT be invoked directly.**

### Correct Invocation Path

```text
User → deeper-research-2 skill (ORCHESTRATOR)
       └→ Phase 5.2: Task tool → knowledge-merger AGENT → this skill
```

### If You Are Reading This Directly

**STOP.** You likely invoked this skill directly via `Skill(skill="cogni-research:knowledge-merger")`.

**What to do instead:**

1. Use the `deeper-research-2` skill instead:

   ```text
   Skill(skill="cogni-research:deeper-research-2")
   ```

2. The orchestrator will invoke this skill at the correct phase with proper context.

**Why this matters:** Direct invocation bypasses phase gates and knowledge-extractor prerequisites. Merging requires parallel concept extraction (Phase 5.1) to have completed first.

---

Merge concept entities from parallel dimension-based extraction, deduplicate across dimensions, perform cross-dimension megatrend clustering, update dimension backlinks, and generate README mindmaps for findings (per-dimension), concepts, and megatrends.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--project-path` | Yes | Research project directory |
| `--content-language` | No | Output language ISO 639-1 code (default: en) |

### Bash One-Liner Syntax (CRITICAL)

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 5 for mandatory semicolon rules and script path conventions.

## References Index

Read references **only when needed** for the specific task:

| Reference | Read when... |
|-----------|--------------|
| [references/workflows/phase-1-setup.md](references/workflows/phase-1-setup.md) | Starting execution (Phase 1) |
| [references/workflows/phase-2-concept-deduplication.md](references/workflows/phase-2-concept-deduplication.md) | Deduplicating concepts (Phase 2) |
| [references/workflows/phase-3-megatrend-clustering.md](references/workflows/phase-3-megatrend-clustering.md) | Clustering megatrends (Phase 3) |
| [references/workflows/phase-4-backlinks.md](references/workflows/phase-4-backlinks.md) | Updating backlinks (Phase 4) |
| [references/workflows/phase-5-readme-generation.md](references/workflows/phase-5-readme-generation.md) | Generating READMEs (Phase 5) |

## Immediate Action: Initialize TodoWrite

**⛔ MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 1: Setup & Validation [in_progress]
2. Phase 2: Concept Deduplication [pending]
3. Phase 3: Megatrend Clustering [pending]
4. Phase 4: Backlink Update [pending]
5. Phase 5: README Generation [pending]

Update todo status as you progress through each phase.

---

## Core Workflow

**CRITICAL**: This skill uses progressive disclosure. Each phase reference contains essential procedural details NOT duplicated here.

### Execution Protocol

1. **First**: Read the phase reference file BEFORE executing that phase
2. **Per-phase**: The reference contains the actual implementation steps
3. **Validation**: Each phase has verification checkpoints in its reference

**⛔ MANDATORY: Read the phase reference file BEFORE executing that phase.**

### Phase 1: Setup & Validation

Read [references/workflows/phase-1-setup.md](references/workflows/phase-1-setup.md), then execute its steps:

1. Parse parameters (PROJECT_PATH, CONTENT_LANGUAGE)
2. Validate PROJECT_PATH with validate-working-directory.sh
3. Initialize logging to `.metadata/knowledge-merger-execution-log.txt`
4. Verify concept directory exists: `05-domain-concepts/data/`

### Phase 2: Concept Deduplication

Read [references/workflows/phase-2-concept-deduplication.md](references/workflows/phase-2-concept-deduplication.md), then execute its steps:

1. List all concepts from `05-domain-concepts/data/`
2. Build normalization map (lowercase, alphanumeric-only)
3. Identify duplicate groups (same normalized name)
4. Merge duplicates: keep highest confidence, merge finding_refs
5. Delete merged duplicate files

**Output:** Deduplicated concept count, merged pairs logged

### Phase 3: Megatrend Clustering

Read [references/workflows/phase-3-megatrend-clustering.md](references/workflows/phase-3-megatrend-clustering.md), then execute its steps:

1. Load ALL concepts and findings (full corpus)
2. Extract keywords from each finding
3. Identify semantic clusters (3+ findings)
4. Create megatrend entities in `06-megatrends/data/`

**Note:** This is cross-dimension clustering - analyzes all findings regardless of dimension.

### Phase 4: Backlink Update

Read [references/workflows/phase-4-backlinks.md](references/workflows/phase-4-backlinks.md), then execute its steps:

1. Build CONCEPTS_BY_DIMENSION by reading concept files
2. Build MEGATRENDS_BY_DIMENSION by reading megatrend files
3. Update each dimension's frontmatter with `concept_ids` and `megatrend_ids` arrays

### Phase 5: README Generation

Read [references/workflows/phase-5-readme-generation.md](references/workflows/phase-5-readme-generation.md), then execute its steps:

1. Generate per-dimension findings READMEs: `04-findings/README-{dimension-slug}.md`
2. Generate `05-domain-concepts/README.md` with mermaid mindmap
3. Generate `06-megatrends/README.md` with mermaid mindmap
4. Return JSON response

**NOTE:** README files are placed in entity root directories, while entity files remain in `/data/` subdirectories.

**Final Response:**

```json
{
  "success": true,
  "phase": "merge",
  "concepts_final": 38,
  "concepts_deduplicated": 7,
  "megatrends_created": 12,
  "dimensions_updated": 5,
  "backlinks_added": 50,
  "readme_generation": {
    "findings_readmes": true,
    "findings_readmes_count": 5,
    "concepts_readme": true,
    "megatrends_readme": true
  }
}
```

## Critical Requirements

### Anti-Hallucination Rules

- NEVER create megatrends without finding evidence
- NEVER merge concepts without checking finding_refs overlap
- ALWAYS verify wikilink targets exist before adding backlinks

### Output Language

- **Target language:** Topic descriptions, cluster summaries
- **English always:** Filenames, YAML keys, technical tags

## Error Handling

| Scenario | Exit | Response |
|----------|------|----------|
| Missing PROJECT_PATH | 1 | Error JSON |
| No concepts found | 0 | Success, 0 megatrends |
| Deduplication conflict | 0 | Keep highest confidence, log warning |
| No clusters (3+) | 0 | Success, 0 megatrends |
| Backlink failure | 0 | Partial success, continue |

## Debugging

Enable verbose output: `export DEBUG_MODE=true`

Log file: `${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt`
