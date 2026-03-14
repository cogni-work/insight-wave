---
name: deeper-research-1
description: Run parallel web search and findings extraction (Phase 2 of 4). Requires deeper-research-0 completion.
---

# Deeper Research 1 - Discovery

Execute parallel findings creation by invoking findings-creator agents in dimension-based batches. This skill requires deeper-research-0 to have completed first (phases 0-2.5 must be done).

---

## Project Selection

**MANDATORY:** Resolve `project_path` before proceeding to the entry gate.

Follow the shared project picker pattern in [../../references/project-picker.md](../../references/project-picker.md) with:
- `prerequisite_flag` = `planning_complete`
- `prerequisite_skill` = `deeper-research-0`

This handles `--project-path` argument passthrough, multi-project discovery, prerequisite filtering, and interactive selection via `AskUserQuestion` when multiple eligible projects exist.

---

## ENTRY GATE: Planning Must Be Complete

**MANDATORY:** Before starting, verify deeper-research-0 has completed:

```bash
# Validate project_path is set
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set. Provide --project-path argument." >&2
  exit 1
fi

# Verify query batches exist (from deeper-research-0)
if [ -z "$(find "${project_path}/03-query-batches/data" -maxdepth 1 -name "*.md" -type f 2>/dev/null)" ]; then
  echo "ERROR: No query batches found. Run deeper-research-0 first." >&2
  exit 1
fi

# Verify sprint-log has planning_complete flag
planning_complete=$(jq -r '.planning_complete // false' "${project_path}/.metadata/sprint-log.json")
if [ "$planning_complete" != "true" ]; then
  echo "ERROR: Planning not complete. Run deeper-research-0 first." >&2
  exit 1
fi
```

**IF MISSING: STOP. Instruct user to run `deeper-research-0` first.**

---

## Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite immediately with Phase 3 steps:

1. Verify deeper-research-0 completion [in_progress]
2. Discover questions by dimension [pending]
3. Execute batch loop (sequential batches, parallel agents within) [pending]
4. Aggregate results [pending]
5. Run dedicated reconciliation batch [pending]
6. Validate findings and update sprint-log [pending]

Update todo status as you progress through each step.

---

## Required Input

**project_path:** Path to research project (from deeper-research-0 completion)

Example invocation:
```
deeper-research-1 --project-path "/path/to/project"
```

**If project_path not provided**, the Project Selection section above resolves it via `discover-projects.sh` with interactive picker.

---

## Output Structure

```
project-name/
├── .metadata/              # Sprint log with discovery_complete marker
├── 04-findings/data/       # 100+ finding entities (LLM + web)
└── 06-megatrends/data/     # Megatrend clusters (preliminary)
```

---

## Phase 3: Parallel Findings Creation (LLM + Web)

**GATE CHECK:** Before starting, verify these Phase 2.5 artifacts exist:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set." >&2; exit 1; fi
find "${project_path}/03-query-batches/data" -maxdepth 1 -name "*.md" -type f -exec ls -la {} +
```

**IF MISSING: STOP. Instruct user to run deeper-research-0 first.**

Read [references/phase-workflows/phase-3-parallel-findings-creation.md](references/phase-workflows/phase-3-parallel-findings-creation.md), then:

1. **Output the checksum verification** (required before execution):
   ```
   Reference Loaded: phase-3-parallel-findings-creation.md | Checksum: p3-v2.7-no-preflight
   ```
2. Execute the steps from the reference

**Phase 3 steps:**

1. Invoke `discover-questions-by-dimension.sh` -> returns pre-calculated `execution_batches`
1.8. **Resumption gate:** Run `scan-resumption-state.sh --phase 3` to detect prior partial completion. If `RESUME`, filter batches to only pending questions. If `COMPLETE`, skip to reconciliation.
2. Execute ALL batches SEQUENTIALLY (no reconciliation during batch loop)
3. Aggregate results from both LLM and web sources across all batches
4. **Step 3.5 - Dedicated Reconciliation Batch (MANDATORY):**
   - Run `reconcile-question-batches.sh` for ALL questions (not per-batch)
   - If `missing_questions` non-empty: Retry ALL missing in a SINGLE parallel batch
   - Re-validate after retry batch
   - Update `sprint-log.json` with `phase_3_coverage` metrics
5. Validate batch entities and findings (LLM + web combined: 100+ findings)

**Required outputs:** `04-findings/data/` (LLM + web findings), `06-megatrends/data/`

**MANDATORY: DEDICATED RECONCILIATION BATCH (Step 3.5)**

After ALL batches complete, run reconciliation as a distinct phase (NOT per-batch):

```bash
# Run full validation mode (checks ALL questions in project automatically)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/reconcile-question-batches.sh" \
  --project-path "${PROJECT_PATH}"
```

**Note:** Omitting `--batch-questions` triggers full validation mode which automatically discovers and validates all questions in `02-refined-questions/data/`.

- If `missing_questions` is non-empty: Retry ALL missing questions in a SINGLE parallel batch
- Update `sprint-log.json` with `phase_3_coverage` metrics
- **deeper-research-2 will validate coverage before proceeding**

**ANTI-BYPASS CONSTRAINT - MANDATORY:**

- **DO NOT** use WebSearch directly in this skill - delegate to findings-creator agents via Task tool
- **DO NOT** create findings directly - findings-creator agents create them with proper `batch_ref` links
- **VERIFY** before Phase 3: `03-query-batches/data/` must contain one batch per refined question (from deeper-research-0)
- **VIOLATION CHECK:** If `03-query-batches/data/` is empty at Phase 3 start, deeper-research-0 was not run - HALT and instruct user

**Parallel Execution Pattern:** Invoke findings-creator-llm (conceptual knowledge) AND all findings-creator agents (empirical web research) in a single message for maximum efficiency. This provides comprehensive coverage combining model knowledge with real-time sources.

**Note:** LLM findings creator may reject 10-30% of findings below quality threshold (0.50 score). This is expected behavior - web findings provide comprehensive coverage.

**Naming Convention:**

- LLM findings: `finding-llm-{semantic-slug}-{8-char-hash}.md`
- Web findings: `finding-{semantic-slug}-{8-char-hash}.md`

---

## Parallel Execution

Invoke ALL instances in single message for:

- Phase 3: findings-creator (one per refined question, 8-50 agents)

## Language Propagation

Read `project_language` from `.metadata/sprint-log.json` (default: "en"). Pass to all collection agents via `LANGUAGE` or `CONTENT_LANGUAGE` parameter.

## Discovery Completion

**PRE-COMPLETION VALIDATION (MANDATORY):**

Before declaring discovery complete, verify findings were created:

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set." >&2; exit 1; fi

# Verify Phase 3 outputs exist
ls -la "${project_path}/04-findings/data/"*.md              # 100+ findings
```

**If directory is empty, Phase 3 failed. Check agent responses and retry.**

After Phase 3 validation passes:

1. Update sprint log: `discovery_complete = true`
2. Report entity counts to user (findings count, megatrends count)
3. Instruct user to run `deeper-research-2 --project-path "{project_path}"`

**HANDOFF MESSAGE:**

```
Discovery phase complete.

Entity Summary:
- Findings: {count} (LLM: {llm_count}, Web: {web_count})
- Megatrends (preliminary): {count if applicable}

Next Step: Run deeper-research-2 for enrichment (sources, knowledge extraction, citations, claims):

deeper-research-2 --project-path "{project_path}"
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
| 3 | Any | HALT |

## Debugging

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 3 for enhanced logging initialization pattern.

Enable verbose stderr output: `export DEBUG_MODE=true`

Log file: `${PROJECT_PATH}/.logs/deeper-research-1-execution-log.txt`

## Bundled Resources

### References

- `references/phase-workflows/phase-3-parallel-findings-creation.md` - Phase 3 implementation details
- `references/question-analysis-methodology.md` - Question analysis framework
- `references/quality-gates.md` - Quality thresholds
- `references/validation-protocols.md` - JSON validation and agent response standards
- `references/parallelization-strategies.md` - Parallel execution patterns
- `references/entity-tagging-taxonomy.md` - Obsidian tag taxonomy for entities
- `../../references/dok-classification.md` - Webb's DOK framework (shared)

### Agents (via Task tool)

- **Research:** findings-creator (parallel, one per refined question), findings-creator-llm, findings-creator-file (for smarter-service research type)
