---
name: findings-creator
description: Process a single refined research question to create findings through web search and finding extraction. Consumes pre-created query batch from 03-query-batches/data/ (created by batch-creator). Use when creating findings for one refined question entity (not for batch processing multiple questions - use deeper-research-1 skill instead).
allowed-tools: Read, Bash, WebSearch, WebFetch, TodoWrite
---

# Findings Creator

Transform a single refined research question into actionable findings through 7-phase sequential execution. Consumes existing query batch created by batch-creator (Phase 2.5 of deeper-research-1).

## Core Capabilities

- **Batch consumption**: Load pre-created query batch with optimized search configs
- **Web search**: Profile-based source diversification (general, localized, industry, academic)
- **Finding extraction**: 5-section structure (schema v3.0) with WebFetch enhancement
- **Quality assessment**: 4-dimension scoring (≥0.50 threshold)
- **Review validation**: Contradiction detection for volatile topics

## Output Language

**Reference:** See [../../references/language-templates.md](../../references/language-templates.md) for complete language template definitions.

### Language-Aware Section Headers

Section headers MUST match the project `language` (from batch `content_language`):

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Content | Content | Inhalt |
| Key Trends | Key Trends | Kernerkenntnisse |
| Methodology & Data Points | Methodology & Data Points | Methodik & Datenpunkte |
| Relevance Assessment | Relevance Assessment | Relevanzbeurteilung |
| Source | Source | Quelle |

### German Text Formatting

When `content_language: "de"`:

| Element | Format | Example |
|---------|--------|---------|
| Body text | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| Section headings | Proper umlauts | "Kernerkenntnisse" NOT "Kernerkenntnisse" |
| File names/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| YAML identifiers | ASCII only | dc:identifier, entity IDs |

## Prerequisites

- Deeper-research workspace initialized
- Refined question entity in `02-refined-questions/data/`
- Query batch entity in `03-query-batches/data/` (created by batch-creator)
- CLAUDE_PLUGIN_ROOT, PROJECT_PATH environment variables

## Critical Constraints

### No Fabrication Rule

**Every finding MUST originate from actual WebSearch result.**

| Prohibited | Consequence |
|------------|-------------|
| Inventing URLs (example.com, beispiel.de) | Exit 124 |
| Fabricating statistics without source | Exit 124 |
| Creating fake methodology | Exit 124 |
| Generating content when no results | Create "no-results" finding |

### Write Tool Prohibition

**NEVER use Write tool for entity files.** Use `create-entity.sh` exclusively.

| Directory | Required Tool | Write Tool = |
|-----------|---------------|--------------|
| `03-query-batches/data/` | `create-entity.sh` | **VIOLATION** |
| `04-findings/data/` | `create-entity.sh` | **VIOLATION** |
| `07-sources/data/` | `create-entity.sh` | **VIOLATION** |

### create-entity.sh Parameter Contract

> **Shared reference:** See [references/findings-creator-shared/entity-creation-contract.md](../../references/findings-creator-shared/entity-creation-contract.md) for full parameter contract, heredoc pattern, dc:identifier prefix conventions, and variant-specific frontmatter fields.

**NEVER use Write tool for entity files.** Use heredocs ONLY to pipe JSON to `create-entity.sh --data -`.

**Reference:** See [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md) Pattern 12.

### Bash Variable Definition Rule

**ALWAYS define variables before use.** Each Bash tool invocation is a fresh shell.

| Anti-Pattern | Error |
|--------------|-------|
| `echo "msg" >> "$LOG_FILE"` without defining LOG_FILE | `no such file or directory:` |
| Referencing `$BATCH_ID` without assignment | Empty string expansion |
| Assuming variables persist between Bash calls | Silent failures |

**Reference:** See [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md) Pattern 11.

### WebSearch API Constraints

| Parameter | Type | Constraints |
|-----------|------|-------------|
| `query` | string | Max ~2000 chars |
| `allowed_domains` | string[] | No HTTP scheme, XOR with blocked_domains |
| `blocked_domains` | string[] | No HTTP scheme, XOR with allowed_domains |

**Domain format**: `["reuters.com"]` NOT `["https://reuters.com"]`

**Localization strategy**: Use native-language query terms + location keywords (e.g., "Deutschland") instead of API-level location parameters.

### Bash One-Liner Syntax (CRITICAL)

When generating bash commands on a single line, ALWAYS separate statements with semicolons:

| WRONG | CORRECT |
|-------|---------|
| `VAR="x" if [...]` | `VAR="x"; if [...]` |
| `cd /path if [...]` | `cd /path; if [...]` |

**Multi-statement one-liners MUST use semicolons:**

```bash
SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT}/scripts"; if [ -f "$SCRIPT_DIR/create-entity.sh" ]; then echo "found"; fi
```

**Script path**: `${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh` (NOT `lib/create-entity.sh`)

### Zsh Command Substitution (CRITICAL)

NEVER combine `$()` command substitution with `;` on the same line:

| WRONG - causes zsh parse error | CORRECT - separate Bash calls |
|--------------------------------|-------------------------------|
| `VAR=$(find ...); echo $VAR` | `VAR=$(find ...)` then `echo $VAR` |
| `A=$(cmd1); B=$(cmd2)` | Separate Bash tool invocations |
| `COUNT=$(wc -l); echo "Total: $COUNT"` | Two sequential Bash calls |

**Reason:** Claude Code executes via zsh, which fails to parse `$()` followed by `;` in eval contexts with error: `parse error near '('`

### Zsh Array Syntax (CRITICAL)

NEVER use bash-specific array syntax in generated commands:

| WRONG - bash only | CORRECT - zsh compatible |
|-------------------|--------------------------|
| `ARRAY+=("value")` | `COUNT=$((COUNT + 1))` |
| `ARRAY=(a b c)` | `ITEM_1="a"; ITEM_2="b"` |
| `${ARRAY[@]}` | Counter loop: `i=1; while [ $i -le $COUNT ]` |
| `${#ARRAY[@]}` | Use a counter variable |
| `declare -a ARRAY` | Not needed |

**Reason:** Claude Code executes via zsh, which doesn't support bash array syntax in eval contexts. Error: `parse error near '('`

### Shell Quoting Safety for Entity Creation (CRITICAL)

**NEVER pass JSON directly to `--data` with single quotes** when the content may contain apostrophes.

| WRONG - breaks on apostrophes                  | Error                    |
|------------------------------------------------|--------------------------|
| `--data '{"content": "niche's capacity"}'`     | `(eval):1: unmatched "`  |
| `--data '{"content": "cell's behavior"}'`      | Shell parsing fails      |

**CORRECT - Use heredoc with stdin (`--data -`):**

```bash
cat << 'ENTITY_JSON' | bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "04-findings" \
  --entity-id "finding-my-megatrend-a1b2c3d4" \
  --data - \
  --json
{"frontmatter": {"dc:title": "Finding Title", "batch_ref": "[[03-query-batches/data/batch-xyz]]"}, "content": "# Finding body with apostrophe's content"}
ENTITY_JSON
```

**Why this works:**

- Single-quoted heredoc delimiter (`'ENTITY_JSON'`) prevents variable expansion
- Apostrophes inside heredoc are passed literally to stdin
- The Python script reads JSON from stdin with `--data -`

**Heredoc Format Requirements (CRITICAL):**

The heredoc MUST follow this exact structure:

1. JSON ends with closing brace `}`
2. Newline immediately after `}` (NO trailing characters)
3. `ENTITY_JSON` delimiter alone on its own line
4. NO characters between `}` and newline (no backticks, spaces, quotes)

```text
WRONG: {"frontmatter":..."}` ENTITY_JSON   ← backtick corrupts input
WRONG: {"frontmatter":..."} ENTITY_JSON    ← delimiter on same line
RIGHT: {"frontmatter":..."}
       ENTITY_JSON                          ← delimiter on own line
```

**Reference:** See [references/patterns/anti-hallucination.md](references/patterns/anti-hallucination.md) Pattern 13.

## Progress Tracking

**Context-Dependent:** Progress tracking varies by execution context:

- **Direct skill invocation:** Use TodoWrite tool if available
- **Agent context (subagent via Task tool):** TodoWrite is NOT available; use log-based tracking instead

**If TodoWrite is available**, initialize with these phases:

```text
1. Phase 0: Environment Validation & Logging [in_progress]
2. Phase 1: Load & Validate Existing Batch [pending]
3. Phase 2: Search Execution [pending]
4. Phase 3: Finding Extraction [pending]
5. Phase 4: Review [pending]
6. Phase 5: Statistics Return [pending]
7. Phase 6: LLM Execution Report [pending]
```

**In agent context**, progress is tracked via log files (initialized in Phase 0):

- Execution log: `${PROJECT_PATH}/.logs/findings-creator/findings-creator-${QUESTION_ID}-execution-log.txt`
- LLM report: `${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl`

Phase 6 ALWAYS executes. Update status as you progress (via TodoWrite or logs).

## Chain-of-Thought (COT) Protocol

This skill requires explicit reasoning before key decisions. **Do not skip reasoning blocks** - they prevent hallucination and context contamination.

### When COT is Required

| Phase | Step | Reasoning Type | Purpose |
|-------|------|---------------|---------|
| Phase 1 | 1.2 | Facet Extraction | Ensure facets derive from CURRENT question |
| Phase 1 | 1.4 | Query Construction | Plan query coverage before building |
| Phase 1 | 1.5 | Alignment Verification | Detect context contamination |
| Phase 3 | 4.3 | Quality Assessment | Justify dimension scores |
| Phase 3 | 4.5.4 | Content Fidelity | Prevent snippet elaboration |
| Phase 3 | 4.5.5 | Coherence Validation | Prevent attribution errors |

### Reasoning Block Formats

**General Decision Reasoning:**

```markdown
<reasoning>
**Analyzing:** [What am I evaluating?]
**Observations:** [What do I see in the data?]
**Considerations:** [What factors influence my decision?]
**Conclusion:** [What decision follows from this reasoning?]
</reasoning>
```

**Quality Assessment Reasoning:**

```markdown
<quality-reasoning>
**Source:** {url}
**Dimension Analysis:**
1. Topical Relevance (35%): [score] - [evidence]
2. Content Completeness (25%): [score] - [evidence]
3. Source Reliability (15%): [score] - [evidence]
4. Evidentiary Value (10%): [score] - [evidence]
5. Source Freshness (15%): [score] - [evidence]
**Composite:** [calculation] = [score]
**Gate Decision:** [PASS/FAIL] because [reason]
</quality-reasoning>
```

**Anti-Hallucination Reasoning:**

```markdown
<hallucination-check>
**Check Type:** [Fidelity/Coherence]
**Source URL:** {url}
**Content Mode:** [webfetch/snippet]
**Evidence Inventory:**
- From source: [facts from original]
- In content: [facts in generated]
**Mismatch Detection:**
- Novel entities: [list or "none"]
- Publisher contradictions: [yes/no]
**Gate Decision:** [PASS/WARN/FAIL] because [reason]
</hallucination-check>
```

### Why COT Matters

Without explicit reasoning:
- **Context contamination**: Queries may address a PRIOR question cached in context
- **Fabrication**: Statistics and claims may be invented from training data
- **Misattribution**: Content may be attributed to wrong URL sources
- **Score inflation**: Quality scores may be assigned without justification

**Reference:** See workflow files for complete COT templates per phase.

## Core Workflow

### Phase 0: Environment Validation & Logging

> **Shared pattern:** See [references/findings-creator-shared/environment-resolution.md](../../references/findings-creator-shared/environment-resolution.md) for the canonical environment resolution steps shared across all findings-creator variants.

**CRITICAL:** Run this SINGLE Bash block to initialize ALL environment variables.

**⚠️ FRESH SHELL WARNING:** Each Bash tool invocation is a fresh shell. Environment variables do NOT persist between Bash calls. You MUST replace the `{{...}}` placeholders below with actual values in THIS Bash block.

| Parameter | Source | Required |
|-----------|--------|----------|
| REFINED_QUESTION_PATH | Replace `{{REFINED_QUESTION_PATH}}` with value from prompt | **YES** |
| PROJECT_PATH | Replace `{{PROJECT_PATH}}` with value from prompt | **YES** |
| CONTENT_LANGUAGE | Replace `{{CONTENT_LANGUAGE}}` or leave default "en" | No |

```bash
# === CONSOLIDATED ENVIRONMENT SETUP (Phase 0) ===
# ⚠️ CALLER: Replace {{...}} placeholders with actual values from your prompt
# These MUST be set in THIS Bash block - they cannot persist from prior Bash calls

REFINED_QUESTION_PATH="{{REFINED_QUESTION_PATH}}"  # ← Replace with actual path
PROJECT_PATH="{{PROJECT_PATH}}"                    # ← Replace with actual path
CONTENT_LANGUAGE="${CONTENT_LANGUAGE:-en}"         # ← Replace or use default

# Validate required parameters (checks for empty AND unreplaced placeholders)
if [ -z "${REFINED_QUESTION_PATH:-}" ] || [ -z "${PROJECT_PATH:-}" ] || \
   [ "$REFINED_QUESTION_PATH" = "{{REFINED_QUESTION_PATH}}" ] || \
   [ "$PROJECT_PATH" = "{{PROJECT_PATH}}" ]; then
  echo '{"ok":false,"e":"param-missing","detail":"Replace {{REFINED_QUESTION_PATH}} and {{PROJECT_PATH}} with actual values"}' >&2
  exit 112
fi

# Validate CLAUDE_PLUGIN_ROOT has expected structure
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo "[ERROR] CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: ${CLAUDE_PLUGIN_ROOT}" >&2
  exit 1
fi

# Resolve plugin root
RESOLVER_PATH=""
if [ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/resolve-plugin-root.sh" ]; then
  RESOLVER_PATH="${CLAUDE_PLUGIN_ROOT}/scripts/utils/resolve-plugin-root.sh"
fi

if [ -n "$RESOLVER_PATH" ]; then
  source "$RESOLVER_PATH"
  CLAUDE_PLUGIN_ROOT=$(resolve_plugin_root)
else
  # Fallback: inline resolution
  PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"

  # Validate plugin root has expected structure
  if [ -n "$PLUGIN_ROOT" ] && [ ! -d "${PLUGIN_ROOT}/scripts" ]; then
    echo "[ERROR] CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: ${PLUGIN_ROOT}" >&2
    exit 1
  fi

  # Final validation
  if [ -z "$PLUGIN_ROOT" ]; then
    echo '{"ok":false,"e":"env-plugin-root","detail":"CLAUDE_PLUGIN_ROOT not set and cannot be derived"}' >&2
    exit 111
  fi

  if [ ! -d "${PLUGIN_ROOT}/scripts" ]; then
    echo '{"ok":false,"e":"env-plugin-root","detail":"Plugin scripts directory not found"}' >&2
    exit 111
  fi

  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT"
fi

# Validate plugin root resolved
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo '{"ok":false,"e":"env-plugin-root","detail":"CLAUDE_PLUGIN_ROOT could not be resolved"}' >&2
  exit 111
fi

# Resolve entity directory names
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi

if [ -n "$ENTITY_CONFIG" ]; then
  source "$ENTITY_CONFIG"
  REFINED_QUESTIONS_DIR=$(get_directory_by_key "refined-questions")
  QUERY_BATCHES_DIR=$(get_directory_by_key "query-batches")
  FINDINGS_DIR=$(get_directory_by_key "findings")
else
  REFINED_QUESTIONS_DIR="02-refined-questions"
  QUERY_BATCHES_DIR="03-query-batches"
  FINDINGS_DIR="04-findings"
fi

# Initialize logging
QUESTION_ID=$(basename "${REFINED_QUESTION_PATH}" .md)
LOG_FILE="${PROJECT_PATH}/.logs/findings-creator/findings-creator-${QUESTION_ID}-execution-log.txt"
mkdir -p "$(dirname "$LOG_FILE")"

# Source enhanced logging if available
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
  log_phase "findings-creator" "start"
else
  echo "[PHASE] ========== findings-creator [start] ==========" >> "$LOG_FILE"
fi

# Resolve workspace root
WORKSPACE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "${PROJECT_PATH}")

# Clear context (anti-contamination) - expanded list for parallel execution safety
unset PREV_QUESTION_ID PREV_PICOT CACHED_INTERVENTION_TERMS \
      BATCH_ID BATCH_FILE CONFIG_COUNT BATCH_REF \
      FINDING_COUNT WEB_FINDINGS LLM_FINDINGS \
      PREV_BATCH_ID PREV_CONFIG_COUNT \
      2>/dev/null || true

# Export all variables for subsequent phases
export CLAUDE_PLUGIN_ROOT PROJECT_PATH REFINED_QUESTION_PATH CONTENT_LANGUAGE
export REFINED_QUESTIONS_DIR QUERY_BATCHES_DIR FINDINGS_DIR
export QUESTION_ID LOG_FILE WORKSPACE_ROOT
export CURRENT_QUESTION_ID="${QUESTION_ID}"
export CURRENT_QUESTION_PATH="${REFINED_QUESTION_PATH}"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 0 complete - QUESTION_ID=${QUESTION_ID}" >> "$LOG_FILE"
echo "Environment validated: QUESTION_ID=${QUESTION_ID}"
```

**Required outputs:** All environment variables exported, LOG_FILE created.

---

### Phase 1: Load & Validate Existing Batch

**GATE CHECK**: Verify Phase 0 outputs (logging initialized, parameters extracted).

**Read**: [references/workflows/phase-2-batch-creation.md](references/workflows/phase-2-batch-creation.md) for batch structure details.

1. Derive batch path: `${PROJECT_PATH}/${QUERY_BATCHES_DIR}/data/${QUESTION_ID}-batch.md`
2. Validate batch exists (≥500 bytes)
3. Verify required fields: `question_ref`, `search_configs`
4. Verify ≥4 search configs
5. Extract `content_language` from batch

```bash
# Re-initialize variables (each Bash invocation is a fresh shell)
QUESTION_ID="${QUESTION_ID:-$(basename "${REFINED_QUESTION_PATH:?Required}" .md)}"
PROJECT_PATH="${PROJECT_PATH:?PROJECT_PATH required}"
QUERY_BATCHES_DIR="${QUERY_BATCHES_DIR:-03-query-batches}"
LOG_FILE="${LOG_FILE:-${PROJECT_PATH}/.logs/findings-creator/findings-creator-${QUESTION_ID}-execution-log.txt}"

BATCH_ID="${QUESTION_ID}-batch"
BATCH_FILE="${PROJECT_PATH}/${QUERY_BATCHES_DIR}/data/${BATCH_ID}.md"

if [ ! -f "$BATCH_FILE" ]; then
  echo '{"ok":false,"e":"batch-not-found","detail":"Run batch-creator first"}' >&2
  exit 122
fi

CONFIG_COUNT=$(grep -c 'config_id:' "$BATCH_FILE" || echo 0)
if [ "$CONFIG_COUNT" -lt 4 ]; then
  echo '{"ok":false,"e":"insufficient-configs","count":'$CONFIG_COUNT'}' >&2
  exit 122
fi

export BATCH_ID BATCH_FILE CONFIG_COUNT
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 1 complete - ${CONFIG_COUNT} configs" >> "$LOG_FILE"
```

**Required outputs**: BATCH_ID, BATCH_FILE, CONFIG_COUNT ≥ 4

---

### Phase 2: Search Execution

**GATE CHECK**: Verify Phase 1 outputs (BATCH_ID, BATCH_FILE validated).

**Read**: [references/workflows/phase-3-search-execution.md](references/workflows/phase-3-search-execution.md) for complete workflow.

1. Load queries from batch entity
2. Execute WebSearch for each query (exact API parameters)
3. Evaluate result quality (threshold: 3+ usable results)
4. Aggregate and deduplicate results
5. Track success level per profile

**Profile Parameter Mapping**:

| Profile | Parameters |
|---------|------------|
| General | query + blocked_domains |
| Localized | query + user_location (object) |
| Industry | query + allowed_domains |
| Academic | query + allowed_domains |

**Required outputs**: SEARCH_RESULTS with deduplicated results, QUERIES_PROCESSED count

---

### Phase 3: Finding Extraction (Schema v3.0)

**GATE CHECK**: Verify Phase 2 outputs (search results, QUERIES_PROCESSED).

**Read**: [references/workflows/phase-4-finding-extraction.md](references/workflows/phase-4-finding-extraction.md) for complete workflow.

1. Validate batch entity exists (mandatory gate)
2. Extract findings from search results with URL validation
3. **Quality Assessment** (4-dimension scoring, web variant weights):
   - Topical Relevance (35%), Content Completeness (25%), Source Reliability (15%), Evidentiary Value (10%), Source Freshness (15%)
   - Composite >=0.50 = PASS, <0.50 = reject to `.rejected-findings.json`
   - See [references/findings-creator-shared/quality-assessment.md](../../references/findings-creator-shared/quality-assessment.md) for full framework
4. Generate semantic filenames
5. **WebFetch Enhancement**: Retrieve full content, fall back to snippet on failure
6. Validate wikilinks against entity-index.json
7. **5-Section Content Generation**:
   - Content (150-300 words)
   - Key Trends (3-6 bullets)
   - Methodology & Data Points
   - Relevance Assessment (auto-generated from scores)
   - Source (URL, placeholders)
8. Create finding entities with schema v3.0 frontmatter

**Required outputs**: FINDINGS_CREATED > 0, all findings with valid wikilinks

---

### Phase 4: Review

**GATE CHECK**: Verify Phase 3 outputs (FINDINGS_CREATED > 0).

**Read**: [references/workflows/phase-5-review.md](references/workflows/phase-5-review.md) for complete workflow.

1. Detect volatile topics (regulations, politics, markets, technology, geopolitics)
2. Execute validation searches with news domain profiles
3. Analyze contradictions (policy reversals, amendments, conflicting data)
4. Generate alerts in `.metadata/contradiction-alerts.json`
5. Update finding metadata with freshness validation

**Contradiction Severity**:

| Severity | Action |
|----------|--------|
| critical | Warning banner, flag for review |
| high | Freshness warning, suggest update |
| medium | "May be outdated" note |
| low | Log for awareness |

---

### Phase 5: Statistics Return

**GATE CHECK**: Verify Phase 4 outputs (review validation complete).

**SHELL SAFETY (CRITICAL)**: See [Pattern 15](references/patterns/anti-hallucination.md#pattern-15-phase-5-statistics-safe-output) - NEVER combine `$()` command substitution with `;` on the same line. Use separate Bash tool calls or Python heredoc.

Return JSON summary:

```json
{
  "success": true,
  "question_id": "{QUESTION_ID}",
  "batch_id": "{BATCH_ID}",
  "configs_executed": 4,
  "findings_created": 12,
  "profile_distribution": {"general": 1, "localized": 1, "industry": 1, "academic": 1},
  "language_detected": "de",
  "schema_version": "3.0",
  "webfetch_success_rate": 0.75,
  "quality_filter_pass_rate": 0.67,
  "review_validation": {
    "volatile_findings_detected": 3,
    "contradictions_found": 1
  }
}
```

---

### Phase 6: LLM Execution Report

**MANDATORY PHASE - ALWAYS EXECUTES**

**Read**: [references/workflows/phase-7-llm-execution-report.md](references/workflows/phase-7-llm-execution-report.md)

1. Reflect on execution (Phases 0-5)
2. Collect issues with type, severity, expected/actual/resolution
3. Append to `${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl`

**Issue Types**: script_path, tool_failure, schema_mismatch, file_not_found, parameter_mismatch, silent_adaptation, context_contamination

```bash
trap - EXIT
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [COMPLETE] findings-creator finished" >> "$LOG_FILE"
```

---

## Finding Schema v3.0 (Required Fields)

| Field | Value | Source |
|-------|-------|--------|
| `schema_version` | `"3.0"` | Static |
| `entity_type` | `"finding"` | Static |
| `tags` | `["finding", megatrend-tag]` | Generated |
| `dc:creator` | `"Claude (findings-creator)"` | Static |
| `dc:title` | `"Finding: {summary}"` | From result |
| `dc:identifier` | `finding-{slug}-{8-char-hash}` | Generated |
| `dc:created` | ISO8601 timestamp | Current time |
| `batch_ref` | `"[[03-query-batches/data/{batch_id}]]"` | From batch |
| `question_ref` | `"[[02-refined-questions/data/{question_id}]]"` | From batch |
| `source_url` | `"{url}"` | From WebSearch |
| `content_source` | `"webfetch"` or `"snippet"` | From WebFetch |
| `quality_score` | 0.00-1.00 | From assessment |
| `quality_dimensions` | nested object | From assessment |

---

## Anti-Hallucination Patterns

| # | Pattern | Application |
|---|---------|-------------|
| 1 | Complete Entity Loading | Load refined question and batch completely |
| 2 | Verification Checkpoints | Phase gates and UUID validation |
| 3 | Evidence-Based Processing | All content from search results only |
| 4 | No Fabrication Rule | Explicit "No results" when searches fail |
| 5 | Provenance Integrity | Validate wikilinks against entity-index.json |
| 6 | WebFetch Validation | Only invoke with validated URLs from WebSearch |
| 7 | Fake URL Detection | Reject placeholder domains |
| 8 | Content Sufficiency Gate | Skip findings when snippet < 100 chars |
| 9 | Write Tool Prohibition | NEVER use Write tool for entity creation |
| 10 | Context Contamination Prevention | Clear cached context in Phase 0 |
| 11 | Batch Validation | Verify batch has ≥4 configs before search |
| 16 | Content-URL Coherence | Validate content matches attributed source URL |
| 17 | Content Fidelity | Verify snippet-only content doesn't exceed snippet scope |

---

## Error Handling

| Exit Code | Category | Meaning |
|-----------|----------|---------|
| 0 | Success | All phases completed |
| 111 | Validation | Environment validation failed |
| 112 | Validation | Parameter validation error |
| 113 | Validation | Refined question entity not found |
| 122 | Execution | Batch creation/validation failed |
| 123 | Execution | Search execution failed |
| 124 | Execution | No search results after fallback |
| 131 | Entity Creation | Finding extraction failed |
| 132 | Entity Creation | No findings created |

---

## Success Criteria

- [ ] Environment validated and logging initialized (Phase 0)
- [ ] Existing batch loaded and validated (Phase 1)
- [ ] Batch has ≥4 search configs (Phase 1)
- [ ] Web searches executed for all queries (Phase 2)
- [ ] ≥1 finding entity created with schema v3.0 (Phase 3)
- [ ] All findings have complete 5-section structure (Phase 3)
- [ ] All findings linked to batch_ref AND question_ref (Phase 3)
- [ ] Review validation completed (Phase 4)
- [ ] JSON statistics returned (Phase 5)
- [ ] LLM execution report created (Phase 6)

---

## Debugging

Enable verbose output: `export DEBUG_MODE=true`

Log locations:
- Execution logs: `${PROJECT_PATH}/.logs/findings-creator/findings-creator-{question-id}-execution-log.txt`
- LLM reports: `${PROJECT_PATH}/.logs/findings-creator-llm-report.jsonl`
- Rejected findings: `${PROJECT_PATH}/.logs/.rejected-findings.json`

Analysis commands:

```bash
# Count issues by type
jq -r '.issues[].type' findings-creator-llm-report.jsonl | sort | uniq -c

# View recent errors
jq -r 'select(.issues[].severity == "error")' findings-creator-llm-report.jsonl | tail -5
```

---

## References Index

| Reference | Purpose |
|-----------|---------|
| [phase-2-batch-creation.md](references/workflows/phase-2-batch-creation.md) | Batch entity structure |
| [phase-3-search-execution.md](references/workflows/phase-3-search-execution.md) | WebSearch execution |
| [phase-4-finding-extraction.md](references/workflows/phase-4-finding-extraction.md) | Finding extraction |
| [phase-5-review.md](references/workflows/phase-5-review.md) | Review validation |
| [phase-7-llm-execution-report.md](references/workflows/phase-7-llm-execution-report.md) | LLM execution report |
| [anti-hallucination.md](references/patterns/anti-hallucination.md) | Anti-hallucination patterns |
