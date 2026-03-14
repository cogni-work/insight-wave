---
name: deeper-research-2
description: Orchestrate research enrichment (Phase 3 of 4). Use when user requests to continue research after deeper-research-0 and deeper-research-1 completion. Requires discovery_complete=true. Executes phases 4-7 to create sources, extract knowledge, generate citations, and verify claims. After completion, run deeper-research-3 for synthesis.
---

# Deeper Research 2 - Enrichment

Orchestrate research enrichment by transforming findings into structured, validated entities. Execute phases 4-7: source creation, knowledge extraction, publisher/citation generation, and claims creation.

> **Shell Compatibility:** All bash code blocks use the temp script pattern for zsh compatibility.
> See [references/shell-compatibility.md](../../references/shell-compatibility.md) for details.

---

## Project Selection

**MANDATORY:** Resolve `project_path` before proceeding to the entry gate.

Follow the shared project picker pattern in [../../references/project-picker.md](../../references/project-picker.md) with:
- `prerequisite_flag` = `discovery_complete`
- `prerequisite_skill` = `deeper-research-1`

This handles `--project-path` argument passthrough, multi-project discovery, prerequisite filtering, and interactive selection via `AskUserQuestion` when multiple eligible projects exist.

---

## ENTRY GATE: Discovery Must Be Complete

**MANDATORY:** Before starting, verify deeper-research-0 and deeper-research-1 have completed:

```bash
# project_path is already set by Project Selection above
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set. Provide --project-path argument." >&2
  exit 1
fi

# Verify discovery_complete flag
discovery_complete=$(jq -r '.discovery_complete // false' "${project_path}/.metadata/sprint-log.json")
if [ "$discovery_complete" != "true" ]; then
  echo "ERROR: Discovery not complete. Run deeper-research-0 and deeper-research-1 first."
  echo "Current state: discovery_complete=$discovery_complete"
  exit 1
fi
echo "Discovery complete. Ready for enrichment."
echo "project_path: ${project_path}"
```

**IF discovery_complete != true:** STOP. Instruct user to run `deeper-research-0` and then `deeper-research-1 --project-path "{path}"` first.

---

## Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 4: Source creation + validation [in_progress]
2. Phase 5: Knowledge extraction [pending]
3. Phase 6: Publisher/citation generation [pending]
4. Phase 7: Claims creation [pending]

Update todo status as you progress through each phase.

**Note:** Each phase will add step-level todos when started (progressive expansion from 4 phase-level to ~20-25 step-level).

---

## Progressive TodoWrite Expansion

The deeper-research-2 workflow uses **progressive disclosure** for TodoWrite tracking:

- **Initial state:** 4 phase-level todos (shown above)
- **Progressive expansion:** Each phase adds its step-level todos when started
- **Final state:** ~20-25 step-level todos across all phases

**Pattern:** As you enter each phase, the phase workflow file provides TodoWrite templates to expand phase-level todos into granular step-level tasks. This prevents overwhelming initial context while maintaining detailed tracking.

---

## Output Structure

Building on deeper-research-0 and deeper-research-1 outputs, this skill creates:

```
project-name/
├── .metadata/              # Sprint log with enrichment_complete marker
├── ... (00-04 from deeper-research-0, 04-findings from deeper-research-1)
├── 05-domain-concepts/data/     # 20+ concept entities
├── 06-megatrends/data/              # 30+ megatrend clusters (expanded)
├── 07-sources/data/             # 50+ source entities
├── 08-publishers/data/          # 40+ publisher entities
├── 09-citations/data/           # 50+ citation entities
└── 10-claims/data/              # 200+ claim entities with confidence scores
```

## Workflow Phases

```text
Phase 4 -> Phase 5 -> Phase 6 -> Phase 7
```

**MANDATORY PHASE GATES:** Each phase has required artifacts and self-verification questions. You MUST:

1. Answer verification questions before proceeding to next phase
2. Verify previous phase artifacts exist BEFORE starting next phase
3. Update step-level todos as you complete each verification step
4. Read the phase reference file BEFORE executing that phase

**Verification Pattern:** Each phase workflow file contains self-verification questions that validate completion before proceeding. Failure to complete verification invalidates the research collection.

**CRITICAL**: This skill uses progressive disclosure. Each phase reference contains essential procedural details NOT duplicated here.

### Execution Protocol

1. **First**: Read the phase reference file BEFORE executing that phase
2. **Per-phase**: The reference contains the actual implementation steps and TodoWrite templates
3. **Validation**: Each phase has verification checkpoints in its reference

**MANDATORY: Read the phase reference file BEFORE executing that phase.**

- SKILL.md provides only navigation
- Phase workflow files provide execution details, TodoWrite templates, and verification gates
- **Deeper-research lesson learned:** Phase execution failures occur when phase workflow files are not read before execution, causing critical steps to be skipped

**Do NOT skip reference reads** - they contain the three-layer enforcement architecture (self-verification, step-level todos, automated gates).

---

### Phase 4: Source Creation & Validation (SEQUENTIAL)

**GATE CHECK:** Before starting, verify these Phase 3 artifacts exist (from deeper-research-0 and deeper-research-1):

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set." >&2
  exit 1
fi

find "${project_path}/03-query-batches/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +
find "${project_path}/04-findings/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +
```

**IF MISSING: STOP. Run deeper-research-0 and deeper-research-1 first.**

Read [references/phase-workflows/phase-4-source-creation.md](references/phase-workflows/phase-4-source-creation.md), then execute its steps:

1. **Step 0:** Phase 3 coverage gate (strict 100% blocking)
2. **Phase 4.1:** Invoke source-creator agent -> creates `07-sources/data/`
3. **Phase 4.2:** Validate sources and repair issues

**Required outputs:** `07-sources/data/`, completion markers `.metadata/phase-4.1-complete` and `.metadata/phase-4.2-complete`

**NEXT STEP:** Immediately proceed to Phase 5. DO NOT declare completion.

### Phase 5: Knowledge Extraction (PARALLEL BY DIMENSION)

**GATE CHECK:** Before starting, verify Phase 4 completion markers:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set." >&2
  exit 1
fi

# Verify Phase 4 completion markers exist (bash 3.2 + ZSH compatible)
if [ -f "${project_path}/.metadata/phase-4.1-complete" ] && \
   [ -f "${project_path}/.metadata/phase-4.2-complete" ]; then
  echo "Phase 4 completion markers verified"
else
  echo "ERROR: Phase 4 incomplete - missing completion markers" >&2
  [ ! -f "${project_path}/.metadata/phase-4.1-complete" ] && echo "  Missing: phase-4.1-complete" >&2
  [ ! -f "${project_path}/.metadata/phase-4.2-complete" ] && echo "  Missing: phase-4.2-complete" >&2
  exit 1
fi

# Verify source files exist (suppress glob error if no matches)
if ls "${project_path}/07-sources/data/"*.md >/dev/null 2>&1; then
  echo "Source files verified in 07-sources/data/"
else
  echo "ERROR: No source files found in 07-sources/data/" >&2
  exit 1
fi
```

**IF gate check fails: STOP. Return to Phase 4 and complete source creation.**

Read [references/phase-workflows/phase-5-knowledge-extraction.md](references/phase-workflows/phase-5-knowledge-extraction.md), then execute its steps:

1. **Phase 5.1:** Parallel concept extraction (one knowledge-extractor per dimension) -> creates `05-domain-concepts/data/`
2. **Phase 5.2:** Sequential merge + cross-dimension megatrend clustering -> creates `06-megatrends/data/`

After both sub-phases complete:

1. Validate concept entities (20+ concepts)
2. Validate megatrend entities (30+ megatrends)

**Required outputs:** `05-domain-concepts/data/`, `06-megatrends/data/`

**NEXT STEP:** Immediately proceed to Phase 6. DO NOT declare completion.

### Phase 6: Publisher/Citation Generation

**GATE CHECK:** Before starting, verify these Phase 5 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set." >&2
  exit 1
fi

ls -la "${project_path}/05-domain-concepts/data/"*.md "${project_path}/07-sources/data/"*.md
```

**IF MISSING: STOP. Return to Phase 5 and create required artifacts.**

Read [references/phase-workflows/phase-6-publisher-citation.md](references/phase-workflows/phase-6-publisher-citation.md), then execute its steps:

1. Invoke single publisher-generator with --all flag (sequential - parallel deprecated)
2. Invoke citation-generator agent
3. Validate publisher entities (40+ publishers)
4. Validate citation entities (50+ citations)

**Note:** Parallel execution is deprecated for Phase 6 due to entity-index.json race conditions.

**⛔ CRITICAL:** Do NOT use `run_in_background=true` for Phase 6 Task or Bash calls.

**Required outputs:** `08-publishers/data/`, `09-citations/data/`

**NEXT STEP:** Immediately proceed to Phase 7. DO NOT declare completion.

### Phase 7: Claims Creation

**GATE CHECK:** Before starting, verify these Phase 6 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set." >&2
  exit 1
fi

ls -la "${project_path}/08-publishers/data/"*.md "${project_path}/09-citations/data/"*.md
```

**IF MISSING: STOP. Return to Phase 6 and create required artifacts.**

Read [references/phase-workflows/phase-7-claims-creation.md](references/phase-workflows/phase-7-claims-creation.md), then execute its steps:

1. **Resumption gate:** Run `scan-resumption-state.sh --phase 7` to detect prior partial completion. If `RESUME`, write pending findings list and adjust agent count. If `COMPLETE`, skip to reporting.
2. Count sources and calculate agent count (1 agent per 15 sources)
3. Partition findings across fact-checker agents
4. Invoke ALL fact-checker agents in parallel (single message, multiple Task calls)
5. Aggregate verification metrics
6. Report completion with claim counts and confidence scores
7. Mark enrichment_complete = true in sprint-log.json

**Required outputs:** `10-claims/data/` directory with 200+ claim entities, updated sprint-log.json

---

## Critical Phase Gates

### Phase 5 to 6 Transition

After Phase 5.1 and 5.2 complete, MUST execute Phase 6 (Publisher Generation) before Phase 6.1. Verify publishers exist before proceeding to citations.

## Parallel Execution

Invoke ALL instances in single message for:

- Phase 4: source-creator (sequential processing with pre-filtering)
- Phase 5.1: knowledge-extractor (one per dimension, parallel)
- Phase 6: publisher-generator (sequential with --all flag - parallel DEPRECATED)
- Phase 7: fact-checker (1 per 15 sources, 3-20 typical)

## Language Propagation

Read `project_language` from `.metadata/sprint-log.json` (default: "en"). Pass to all collection agents via `LANGUAGE` or `CONTENT_LANGUAGE` parameter.

## Enrichment Completion

**PRE-COMPLETION VALIDATION (MANDATORY):**

Before declaring enrichment complete, verify ALL directories contain entities:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set." >&2
  exit 1
fi

# Verify all Phase 4-7 outputs exist
ls -la "${project_path}/05-domain-concepts/data/"*.md  # 20+ concepts
ls -la "${project_path}/07-sources/data/"*.md          # 50+ sources
ls -la "${project_path}/08-publishers/data/"*.md       # 40+ publishers
ls -la "${project_path}/09-citations/data/"*.md        # 50+ citations
ls -la "${project_path}/10-claims/data/"*.md           # 200+ claims
```

**If ANY directory is empty, you skipped a phase. Return to the missing phase.**

After Phase 7 validation passes:

1. Update sprint log: `enrichment_complete = true`
2. Report entity counts to user (including claim counts and confidence scores)
3. Instruct user to run `deeper-research-3 --project-path "{project_path}"`

**HANDOFF MESSAGE:**

```
Enrichment phase complete.

Entity Summary:
- Sources: {count}
- Concepts: {count}
- Megatrends: {count}
- Publishers: {count}
- Citations: {count}
- Claims: {count} (high confidence: {high_count}, medium: {medium_count}, low: {low_count})

Next Step: Run deeper-research-3 for synthesis (trends, evidence catalog, report):

deeper-research-3 --project-path "{project_path}"
```

## Constraints

- DO NOT perform research directly (delegate to agents via Task tool)
- DO NOT modify agent-created entity files
- ALWAYS validate agent responses
- ALWAYS report phase completion with metrics

### Bash One-Liner Syntax (CRITICAL)

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 5 for mandatory semicolon rules and script path conventions.

**Script path**: `${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh` (NOT `lib/create-entity.sh`)

## Error Handling

| Phase | Failure | Action |
|-------|---------|--------|
| 4-6 | Single batch/pipeline | CONTINUE |
| 7 | Partial | CONTINUE |
| 7 | Validation | HALT |

## Debugging

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 3 for enhanced logging initialization pattern.

Enable verbose stderr output: `export DEBUG_MODE=true`

Log file: `${PROJECT_PATH}/.logs/deeper-research-2-execution-log.txt`

## Bundled Resources

### References

- `references/phase-workflows/` - Phase 4-7 implementation details
- `references/quality-gates.md` - Quality thresholds
- `references/validation-protocols.md` - JSON validation and agent response standards
- `references/parallelization-strategies.md` - Parallel execution patterns
- `references/entity-tagging-taxonomy.md` - Obsidian tag taxonomy for entities

### Agents (via Task tool)

- **Source Creation:** source-creator (Phase 4, sequential with pre-filtering)
- **Knowledge Extraction:** knowledge-extractor (Phase 5, parallel per dimension), knowledge-merger
- **Citation:** publisher-generator (parallel), citation-generator
- **Verification:** fact-checker (parallel, 1 per 15 sources)
