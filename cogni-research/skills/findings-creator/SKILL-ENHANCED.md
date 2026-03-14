---
name: findings-creator
description: Process a single refined research question to create findings through query optimization, batch creation, web search, and finding extraction. Combines research-query-optimizer and research-executor logic into a streamlined single-question workflow. Use when creating findings for one refined question entity from 02-refined-questions/data/ directory (not for batch processing multiple questions - use deeper-research-1 skill instead).
---

# Findings Creator

Transform a single refined research question into actionable findings through 7-phase sequential execution with comprehensive reference adherence enforcement.

## Core Capabilities

- **Query optimization**: Generate 2-4 optimized search queries with 5-dimension scoring
- **Batch creation**: Create query-batch entity with UUID-based query IDs
- **Web search execution**: Execute searches with 3-level progressive fallback
- **Finding extraction**: Create structured finding entities with provenance tracking

## Prerequisites

- Deeper-research workspace initialized
- Refined question entity exists in `02-refined-questions/data/`
- Entity-index.json exists for wikilink validation
- CLAUDE_PLUGIN_ROOT and PROJECT_PATH environment variables set

## Logging Infrastructure

This skill implements the three-layer debugging architecture (debugging-guide.md Layer 2: Enhanced Logging).

**Log File Location:**
- Execution logs: `${PROJECT_PATH}/.logs/findings-creator-execution-log.txt`
- Single log file per execution (sequential processing, no parallel batches)

**Log Content:**
- Phase markers with timestamps (navigable with view-execution-log.sh)
- Execution context (environment variables, parameters, workspace state)
- Performance metrics (queries generated, findings created, success rates)
- DEBUG_MODE-aware verbosity (INFO/DEBUG/WARN/ERROR levels)
- Error details with context
- Final execution summary with comprehensive statistics

**DEBUG_MODE Configuration:**
- `DEBUG_MODE=true`: Verbose output to stderr + complete log files
- `DEBUG_MODE=false`: Clean output (ERROR/WARN only to stderr) + complete log files
- Set in `.claude/settings.local.json` or environment

**Utilities Used:**
- enhanced-logging.sh: log_conditional(), log_phase(), log_metric()
- Phase 0 initializes these utilities with fallback for standalone usage

**Reference:** See [Debugging Guide](https://github.com/cogni-work/dev-work/blob/main/references/debugging-guide.md) for three-layer architecture details.

## ⛔ Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite IMMEDIATELY with phase-level todos. Do not proceed with any execution until this is complete.

```markdown
USE: TodoWrite tool

INITIAL TODOS (7 phase-level):
1. Phase 0: Environment Validation & Logging Initialization [in_progress]
2. Phase 1: Parameter Validation [pending]
3. Phase 2: Query Optimization [pending]
4. Phase 3: Batch Creation [pending]
5. Phase 4: Search Execution [pending]
6. Phase 5: Finding Extraction [pending]
7. Phase 6: Statistics Return [pending]
```

**Important:** These phase-level todos will progressively expand to ~22-25 step-level todos as you execute each phase. See "Progressive TodoWrite Expansion" section below.

## Progressive TodoWrite Expansion

This skill uses **progressive todo expansion** to prevent context overload while maintaining execution discipline:

**Expansion Pattern:**

- **Initial state**: 7 phase-level todos (one per phase, as initialized above)
- **Progressive expansion**: Each phase workflow file contains a "Step 0.5" section with a TodoWrite template
- **When starting a phase**: Expand that phase's todo into 4-6 step-level todos
- **Final state**: ~22-25 step-level todos total across all phases

**Example Expansion (Phase 2):**

```
Before Phase 2:
- Phase 2: Query Optimization [in_progress]

After reading phase-1-query-optimization.md Step 0.5:
- Phase 2, Step 2.1: Load refined question entity [in_progress]
- Phase 2, Step 2.2: Extract metadata and detect language [pending]
- Phase 2, Step 2.3: Select variant types [pending]
- Phase 2, Step 2.4: Generate optimized queries [pending]
- Phase 2, Step 2.5: Calculate optimization scores [pending]
- Phase 2, Step 2.6: Log statistics [pending]
```

**Why Progressive Expansion?**
- Prevents overwhelming todo list at start (7 vs 25 items)
- Maintains detailed tracking as you progress
- Forces reading phase references to discover step-level structure
- Ensures todo discipline throughout execution

## References Index

This skill uses **progressive disclosure**. Read references **only when needed** for the specific phase:

| Reference | Read when... | Contains |
|-----------|--------------|----------|
| [references/workflows/phase-1-query-optimization.md](references/workflows/phase-1-query-optimization.md) | Starting Phase 2 | Query generation, variant selection, optimization scoring |
| [references/workflows/phase-2-batch-creation.md](references/workflows/phase-2-batch-creation.md) | Starting Phase 3 | UUID generation, batch entity creation, metadata construction |
| [references/workflows/phase-3-search-execution.md](references/workflows/phase-3-search-execution.md) | Starting Phase 4 | WebSearch execution, progressive fallback, quality evaluation |
| [references/workflows/phase-4-finding-extraction.md](references/workflows/phase-4-finding-extraction.md) | Starting Phase 5 | Finding entity creation, URL validation, wikilink generation |
| [references/patterns/query-variant-strategies.md](references/patterns/query-variant-strategies.md) | Phase 2 variant selection | Variant decision tree, selection rules |
| [references/patterns/optimization-patterns.md](references/patterns/optimization-patterns.md) | Phase 2 scoring | 5-dimension scoring methodology |
| [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md) | Any verification needed | 5 anti-hallucination patterns |

## ⛔ Execution Protocol

**CRITICAL WORKFLOW DISCIPLINE:**

This skill contains implementation details in **phase workflow reference files**, not in this SKILL.md. You MUST follow this protocol for each phase:

### Before Starting Any Phase:

1. **⛔ MANDATORY: Read the phase workflow reference file COMPLETELY**
   - Do NOT proceed with execution until you have read the entire reference
   - Do NOT attempt to infer steps from gate checks or output requirements
   - Do NOT skip to execution based on phase name alone

2. **Verify Phase Reference Loading**
   - Each phase workflow file contains a checksum in its header
   - Output the checksum after reading to confirm loading
   - This proves you've read the complete reference

3. **Execute Step 0.5: Initialize Phase TodoWrite**
   - Each phase workflow file contains a "Step 0.5" section
   - This section provides a TodoWrite template with step-level todos
   - Expand the phase-level todo using this template BEFORE starting phase execution

4. **Follow Phase Workflow Steps Sequentially**
   - Execute steps in the order specified in the phase workflow reference
   - Mark each step-level todo as completed after execution
   - Do NOT skip steps or combine them

5. **Complete Verification Checkpoints**
   - Answer Self-Verification Questions (YES/NO format)
   - Provide Content-Based Checkpoint data (Phases 2-5 only)
   - Complete Phase Completion Checklist before proceeding

### ⛔ STOP: Do Not Proceed Without Reading

If you find yourself executing a phase without having read its workflow reference file:
- **STOP immediately**
- Go back and read the complete workflow reference
- Output the checksum to prove loading
- Re-execute Step 0.5 to expand todos
- Then proceed with phase execution

**Why This Matters:**
- Workflow references contain critical procedural details not in SKILL.md
- Skipping references leads to incomplete execution and missing steps
- Verification checkpoints catch reference-skipping attempts
- Progressive todo expansion forces reference loading discipline

## Core Workflow

Execute these 7 phases sequentially with strict adherence to the Execution Protocol above.

### Phase 0: Environment Validation & Logging Initialization

**⛔ GATE CHECK:** N/A (first phase)

**Purpose:** Initialize logging infrastructure and validate environment variables.

**Implementation:**

Initialize enhanced logging utilities and validate CLAUDE_PLUGIN_ROOT, PROJECT_PATH, WORKSPACE_ROOT. Create log directory and begin execution logging.

**No workflow reference file for this phase** - implementation details are inline in this SKILL.md (lines 101-151 of original).

**Step 0.1: Initialize Enhanced Logging**

Source enhanced-logging.sh utilities with fallback:

```bash
# Source enhanced logging utilities (with fallback)
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  # Fallback: basic logging for standalone usage
  log_conditional() { [ "${DEBUG_MODE:-false}" = "true" ] && echo "[$1] $2" >&2 || true; }
  log_phase() { [ "${DEBUG_MODE:-false}" = "true" ] && echo "[PHASE] ========== $1 [$2] ==========" >&2 || true; }
  log_metric() { [ "${DEBUG_MODE:-false}" = "true" ] && echo "[METRIC] $1=$2 unit=$3" >&2 || true; }
fi

# Initialize execution log
LOG_FILE="${PROJECT_PATH}/.logs/findings-creator-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.logs"
log_phase "findings-creator" "start"
```

**Step 0.2: Validate Environment Variables**

Verify required environment context:

```bash
# Validate CLAUDE_PLUGIN_ROOT
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set", "error_code": 111}' >&2
  exit 111
fi

# Validate PROJECT_PATH (will be set from --project-path parameter)
if [ -z "${PROJECT_PATH:-}" ]; then
  echo '{"success": false, "error": "PROJECT_PATH not set", "error_code": 111}' >&2
  exit 111
fi

# Detect WORKSPACE_ROOT
WORKSPACE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "${PROJECT_PATH}")
export WORKSPACE_ROOT

log_conditional INFO "CLAUDE_PLUGIN_ROOT: ${CLAUDE_PLUGIN_ROOT}"
log_conditional INFO "PROJECT_PATH: ${PROJECT_PATH}"
log_conditional INFO "WORKSPACE_ROOT: ${WORKSPACE_ROOT}"
```

**Required Outputs:**
- Enhanced logging initialized with fallback
- Environment variables validated (CLAUDE_PLUGIN_ROOT, PROJECT_PATH, WORKSPACE_ROOT)
- Log directory created
- Execution start logged

**⛔ Phase 0 Completion Checklist:**

Before proceeding to Phase 1:
- [ ] Enhanced logging initialized (log_conditional, log_phase, log_metric available)
- [ ] CLAUDE_PLUGIN_ROOT validated and exported
- [ ] PROJECT_PATH validated and exported
- [ ] WORKSPACE_ROOT detected and exported
- [ ] Log file created at ${PROJECT_PATH}/.logs/findings-creator-execution-log.txt
- [ ] Phase 0 todo marked as completed

---

### Phase 1: Parameter Validation

**⛔ GATE CHECK:** Before starting, verify Phase 0 outputs exist:

```bash
# Verify logging initialized
if [ ! -f "${PROJECT_PATH}/.logs/findings-creator-execution-log.txt" ]; then
  echo "ERROR: Phase 0 incomplete - log file missing" >&2
  exit 111
fi

# Verify environment variables set
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || [ -z "${PROJECT_PATH:-}" ]; then
  echo "ERROR: Phase 0 incomplete - environment variables not set" >&2
  exit 111
fi
```

**Purpose:** Validate required parameters and verify refined question entity exists.

**Implementation:**

Validate `--refined-question-path` and `--project-path` parameters. Verify refined question entity file exists and is readable. Export validated paths.

**No workflow reference file for this phase** - implementation details are inline in this SKILL.md (lines 153-169 of original).

**Required Outputs:**
- REFINED_QUESTION_PATH exported and validated
- PROJECT_PATH exported and validated
- WORKSPACE_ROOT detected and exported
- Refined question entity file verified to exist

**⛔ Phase 1 Completion Checklist:**

Before proceeding to Phase 2:
- [ ] --refined-question-path parameter validated
- [ ] --project-path parameter validated
- [ ] Refined question entity file exists and is readable
- [ ] REFINED_QUESTION_PATH exported
- [ ] Phase 1 todo marked as completed

---

### Phase 2: Query Optimization

**⛔ GATE CHECK:** Before starting, verify Phase 1 outputs exist:

```bash
# Verify parameters validated
if [ -z "${REFINED_QUESTION_PATH:-}" ] || [ -z "${PROJECT_PATH:-}" ]; then
  echo "ERROR: Phase 1 incomplete - parameters not validated" >&2
  exit 112
fi

# Verify refined question entity exists
if [ ! -f "${REFINED_QUESTION_PATH}" ]; then
  echo "ERROR: Phase 1 incomplete - refined question entity not found: ${REFINED_QUESTION_PATH}" >&2
  exit 113
fi
```

**⛔ MANDATORY: Read Workflow Reference BEFORE Execution**

**STOP:** Do not proceed until you have read [references/workflows/phase-1-query-optimization.md](references/workflows/phase-1-query-optimization.md) **completely**.

After reading, output the checksum from the reference file header to prove loading.

**Purpose:** Generate 2-4 optimized search query variants from the refined question.

**Workflow Overview:**

The phase workflow reference contains complete implementation details including:
- Step 0.5: TodoWrite template for step-level expansion
- Step 1.1: Load refined question entity
- Step 1.2: Extract metadata and detect language
- Step 1.3: Select variant types (2-4 variants)
- Step 1.4: Generate optimized queries
- Step 1.5: Calculate optimization scores (5-dimension)
- Step 1.6: Log query generation statistics
- Self-Verification Questions (3 questions)
- Content-Based Checkpoint (prove comprehension)
- Phase Completion Checklist

**Required Outputs:**
- QUERY_COUNT with 2-4 optimized queries (stored as QUERY_1, QUERY_2, etc.)
- DIMENSION_ID extracted from refined question
- LANGUAGE detected (en, de, fr, es, etc.)
- Optimization scores calculated for all queries
- REFINED_QUESTION_ID extracted (used in Phase 3 for batch_id)

---

### Phase 3: Batch Creation

**⛔ GATE CHECK:** Before starting, verify Phase 2 outputs exist:

```bash
# Verify queries generated
if [ -z "${QUERY_COUNT:-}" ] || [ "$QUERY_COUNT" -eq 0 ]; then
  echo "ERROR: Phase 2 incomplete - no queries generated" >&2
  exit 121
fi

# Verify metadata extracted
if [ -z "${DIMENSION_ID:-}" ] || [ -z "${REFINED_QUESTION_ID:-}" ]; then
  echo "ERROR: Phase 2 incomplete - metadata not extracted" >&2
  exit 121
fi
```

**⛔ MANDATORY: Read Workflow Reference BEFORE Execution**

**STOP:** Do not proceed until you have read [references/workflows/phase-2-batch-creation.md](references/workflows/phase-2-batch-creation.md) **completely**.

After reading, output the checksum from the reference file header to prove loading.

**Purpose:** Create query-batch entity with UUID-based query IDs.

**Workflow Overview:**

The phase workflow reference contains complete implementation details including:
- Step 0.5: TodoWrite template for step-level expansion
- Step 2.1: Generate UUID-based query IDs
- Step 2.2: Construct queries[] frontmatter array
- Step 2.3: Build markdown body with per-query details
- Step 2.4: Create query-batch entity using create-entity.sh
- Step 2.5: Verify entity creation and UUID format
- Self-Verification Questions (3 questions)
- Content-Based Checkpoint (prove comprehension)
- Phase Completion Checklist

**Critical Naming Convention:**
- Batch ID derives from refined question ID with "-b" suffix
- Example: `wettbewerber-q1` → batch ID `wettbewerber-q1-b`
- This ensures one-to-one mapping: batch count = refined question count

**Required Outputs:**
- Query batch entity created in `03-query-batches/data/` with "-b" suffix
- BATCH_ID exported (equals REFINED_QUESTION_ID + "-b")
- All query_id values use UUID format

---

### Phase 4: Search Execution

**⛔ GATE CHECK:** Before starting, verify Phase 3 outputs exist:

```bash
# Verify batch created
if [ -z "${BATCH_ID:-}" ]; then
  echo "ERROR: Phase 3 incomplete - BATCH_ID not set" >&2
  exit 122
fi

# Verify batch entity exists
batch_file="${PROJECT_PATH}/03-query-batches/data/${BATCH_ID}.md"
if [ ! -f "$batch_file" ]; then
  echo "ERROR: Phase 3 incomplete - batch entity not found: $batch_file" >&2
  exit 122
fi
```

**⛔ MANDATORY: Read Workflow Reference BEFORE Execution**

**STOP:** Do not proceed until you have read [references/workflows/phase-3-search-execution.md](references/workflows/phase-3-search-execution.md) **completely**.

After reading, output the checksum from the reference file header to prove loading.

**Purpose:** Execute WebSearch for all queries with 3-level progressive fallback.

**Workflow Overview:**

The phase workflow reference contains complete implementation details including:
- Step 0.5: TodoWrite template for step-level expansion
- Step 3.1: Load queries from batch entity
- Step 3.2: Execute WebSearch for each query
- Step 3.3: Evaluate result quality (threshold: 3+ usable results)
- Step 3.4: Apply progressive fallback if needed (Levels 1-3)
- Step 3.5: Store results with metadata
- Step 3.6: Track success level and refinement attempts
- Self-Verification Questions (3 questions)
- Content-Based Checkpoint (prove comprehension)
- Phase Completion Checklist

**Required Outputs:**
- Search results collected for all queries
- QUERIES_PROCESSED count available
- Fallback metadata tracked (success level per query)
- Search results stored in data structure for Phase 5

---

### Phase 5: Finding Extraction

**⛔ GATE CHECK:** Before starting, verify Phase 4 outputs exist:

```bash
# Verify search results collected
if [ -z "${QUERIES_PROCESSED:-}" ] || [ "${QUERIES_PROCESSED}" -eq 0 ]; then
  echo "ERROR: Phase 4 incomplete - no queries processed" >&2
  exit 123
fi

# Verify search results data structure exists
if [ -z "${search_results_map:-}" ]; then
  echo "ERROR: Phase 4 incomplete - search results not stored" >&2
  exit 123
fi
```

**⛔ MANDATORY: Read Workflow Reference BEFORE Execution**

**STOP:** Do not proceed until you have read [references/workflows/phase-4-finding-extraction.md](references/workflows/phase-4-finding-extraction.md) **completely**.

After reading, output the checksum from the reference file header to prove loading.

**Purpose:** Extract findings from search results and create finding entities.

**Workflow Overview:**

The phase workflow reference contains complete implementation details including:
- Step 0.5: TodoWrite template for step-level expansion
- Step 4.1: Load finding template
- Step 4.2: Extract findings from search results
- Step 4.2.5: Pre-entity URL validation (verify non-empty, well-formed URLs)
- Step 4.3: Quality Assessment Checkpoint (4-dimension scoring, ≥0.50 threshold)
- Step 4.4: Generate semantic filenames
- Step 4.5: Create wikilinks (validate against entity-index.json)
- Step 4.6: Create finding entities in 04-findings/data/
- Step 4.7: Link findings to refined_question_id
- Step 4.8: Verify at least 1 finding created
- Self-Verification Questions (3 questions)
- Content-Based Checkpoint (prove comprehension)
- Phase Completion Checklist

**Critical Quality Control:**
- **URL Validation**: All findings must have non-empty, well-formed source URLs (http:// or https://)
- **Quality Assessment**: Findings scored on 4 dimensions (Topical Relevance 40%, Content Completeness 30%, Source Reliability 20%, Evidentiary Value 10%)
- **Quality Threshold**: Only findings with composite score ≥0.50 are created
- **Rejection Tracking**: Low-quality findings logged to .rejected-findings.json

**Source_id Documentation:**
- source_id field starts empty ("") in created findings
- Will be populated by source-creator skill (Phase 3.6 of deeper-research-1)
- This is intentional, not a bug
- Establishes complete provenance chain after source entity creation

**Required Outputs:**
- FINDINGS_CREATED > 0
- Finding entities created in `04-findings/data/`
- All findings have valid wikilinks and refined_question_id
- All findings have validated source_url (non-empty, well-formed)
- All findings passed quality threshold (≥0.50 composite score)
- source_id="" documented as intentional (awaiting source-creator)

---

### Phase 6: Statistics Return

**⛔ GATE CHECK:** Before starting, verify Phase 5 outputs exist:

**⚠️ ZSH COMPATIBILITY:** Use temp script pattern for if/then blocks with command substitution.

```bash
cat > /tmp/phase6-gate-check.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
FINDINGS_CREATED="${2:-0}"

# Verify findings created
if [ -z "${FINDINGS_CREATED}" ] || [ "${FINDINGS_CREATED}" -eq 0 ]; then
  echo "ERROR: Phase 5 incomplete - no findings created" >&2
  exit 131
fi

# Verify finding entities exist
finding_count=$(find "${PROJECT_PATH}/04-findings/data/" -name "*.md" -type f 2>/dev/null | wc -l)
if [ "$finding_count" -eq 0 ]; then
  echo "ERROR: Phase 5 incomplete - no finding entities in 04-findings/data/" >&2
  exit 131
fi

echo "Gate check passed: $finding_count findings exist"
SCRIPT_EOF
chmod +x /tmp/phase6-gate-check.sh && bash /tmp/phase6-gate-check.sh "${PROJECT_PATH}" "${FINDINGS_CREATED}"
```

**Purpose:** Return JSON summary with comprehensive execution statistics.

**Implementation:**

Construct JSON response with all key metrics from execution:

```json
{
  "success": true,
  "refined_question_id": "question-nachhaltige-geschaeftsmodelle-g9h0i1j2",
  "dimension_id": "dimension-neue-horizonte-b2c3d4e5",
  "batch_id": "question-nachhaltige-geschaeftsmodelle-g9h0i1j2-b",
  "queries_generated": 4,
  "queries_processed": 4,
  "findings_created": 12,
  "variant_distribution": {"primary": 1, "bilingual": 1, "synonym_enriched": 1, "decomposed": 1},
  "avg_optimization_score": 82.5,
  "language_detected": "de",
  "execution_time_seconds": 45.3
}
```

**Required Fields:**
- success: true/false
- refined_question_id: ID from refined question entity
- dimension_id: Dimension wikilink target
- batch_id: Created batch ID (should equal refined_question_id + "-b")
- queries_generated: Count of queries created in Phase 2
- queries_processed: Count of queries executed in Phase 4
- findings_created: Count of finding entities created in Phase 5
- variant_distribution: Breakdown by variant type
- avg_optimization_score: Mean of all query optimization scores
- language_detected: Primary language from Phase 2
- execution_time_seconds: Total execution time

**⛔ Phase 6 Completion Checklist:**

Before completing skill execution:
- [ ] JSON response constructed with all required fields
- [ ] success field set to true
- [ ] All counts match actual entities created
- [ ] Statistics logged to execution log
- [ ] Phase 6 todo marked as completed
- [ ] All 7 phase-level todos marked as completed

---

## Quick Example

**Input:** Refined question entity `02-refined-questions/data/wettbewerber-q1.md`

**Question:** "Wer sind die Top 3-5 Wettbewerber für Stellplatz-Vermittlung in Deutschland?"

**Execution Flow:**

1. **Phase 0**: Initialize logging, validate environment → Log file created
2. **Phase 1**: Validate parameters → REFINED_QUESTION_PATH exported
3. **Phase 2**: Generate queries → 2 optimized queries (Primary 85/100, Bilingual 78/100)
4. **Phase 3**: Create batch → `03-query-batches/data/wettbewerber-q1-batch.md` with UUID config IDs
5. **Phase 4**: Execute searches → Search results from WebSearch tool (with fallback if needed)
6. **Phase 5**: Extract findings → 12 finding entities in `04-findings/data/` with semantic filenames
7. **Phase 6**: Return JSON → Statistics with execution summary

**Result:** 12 findings created, linked to refined question, ready for synthesis.

---

## Success Criteria

- ✅ Environment validated and logging initialized (Phase 0)
- ✅ Parameters validated (Phase 1)
- ✅ 2-4 optimized queries generated (Phase 2)
- ✅ Query batch entity created with UUID-based query IDs and "-b" suffix (Phase 3)
- ✅ Web searches executed for all queries (Phase 4)
- ✅ At least 1 finding entity created (Phase 5)
- ✅ All findings passed quality threshold (≥0.50 composite score) (Phase 5)
- ✅ All findings linked to refined_question_id (Phase 5)
- ✅ JSON statistics returned (Phase 6)
- ✅ All 7 phase-level todos marked completed
- ✅ All ~22-25 step-level todos marked completed

---

## Anti-Hallucination Patterns

| Pattern | Application |
|---------|-------------|
| Pattern 1: Complete Entity Loading | Load refined question and templates completely before processing |
| Pattern 2: Verification Checkpoints | Phase gates, TodoWrite discipline, checksum verification |
| Pattern 3: Evidence-Based Processing | All content derived from search results only, no fabrication |
| Pattern 4: No Fabrication Rule | Explicit "No results" when searches fail, never invent findings |
| Pattern 5: Provenance Integrity | Validate wikilinks against entity-index.json, verify URLs |

**Reference:** [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md)

---

## Error Handling

| Exit Code | Category | Meaning |
|-----------|----------|---------|
| 0 | Success | All phases completed successfully |
| 111 | Validation | Environment validation failed (CLAUDE_PLUGIN_ROOT or PROJECT_PATH missing) |
| 112 | Validation | Parameter validation error (refined-question-path or project-path missing) |
| 113 | Validation | Refined question entity not found |
| 114 | Validation | Missing template file |
| 121 | Execution | Query optimization failed (Phase 2) |
| 122 | Execution | Batch creation failed (Phase 3) |
| 123 | Execution | Search execution failed (Phase 4) |
| 124 | Execution | No search results after fallback (graceful failure) |
| 131 | Entity Creation | Finding extraction failed (Phase 5) |
| 132 | Entity Creation | No findings created (Phase 5 incomplete) |

---

## Debugging

Enhanced logging utilities are initialized in Phase 0 with fallback for standalone usage:
- `log_phase "{phase_name}" "start|complete"` - Mark phase transitions
- `log_metric "{metric_name}" "{value}" "{unit}"` - Track performance metrics
- `log_conditional {LEVEL} "{message}"` - DEBUG_MODE-aware logging (INFO/DEBUG/WARN/ERROR)

**Enable verbose stderr output:**
```bash
export DEBUG_MODE=true
```

**Log locations:**
- Execution logs: `${PROJECT_PATH}/.logs/findings-creator-execution-log.txt`
- Rejected findings: `${PROJECT_PATH}/.logs/.rejected-findings.json` (Phase 5 quality filtering)

**View execution trace:**
```bash
# View complete execution log
cat ${PROJECT_PATH}/.logs/findings-creator-execution-log.txt

# View phase markers only
grep "\[PHASE\]" ${PROJECT_PATH}/.logs/findings-creator-execution-log.txt

# View metrics only
grep "\[METRIC\]" ${PROJECT_PATH}/.logs/findings-creator-execution-log.txt
```
