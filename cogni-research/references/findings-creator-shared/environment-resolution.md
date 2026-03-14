# Shared Environment Resolution Pattern

Common Phase 0 logic for all findings-creator variants. Each variant sources this pattern with minor adaptations noted below.

## Step 1: Plugin Root Validation

```bash
# Validate CLAUDE_PLUGIN_ROOT points to correct plugin directory
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo "[ERROR] CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: ${CLAUDE_PLUGIN_ROOT}" >&2
  exit 1
fi
```

## Step 2: Plugin Root Resolver

```bash
RESOLVER_PATH=""
if [ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/resolve-plugin-root.sh" ]; then
  RESOLVER_PATH="${CLAUDE_PLUGIN_ROOT}/scripts/utils/resolve-plugin-root.sh"
fi

if [ -n "$RESOLVER_PATH" ]; then
  source "$RESOLVER_PATH"
  CLAUDE_PLUGIN_ROOT=$(resolve_plugin_root)
  export CLAUDE_PLUGIN_ROOT
fi

# Final validation
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ] || [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo '{"ok":false,"e":"env-plugin-root","detail":"CLAUDE_PLUGIN_ROOT not set and cannot be derived"}' >&2
  exit 111
fi
```

## Step 3: Entity Directory Resolution

```bash
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi

if [ -n "$ENTITY_CONFIG" ]; then
  source "$ENTITY_CONFIG"
  REFINED_QUESTIONS_DIR=$(get_directory_by_key "refined-questions")
  FINDINGS_DIR=$(get_directory_by_key "findings")
else
  REFINED_QUESTIONS_DIR="02-refined-questions"
  FINDINGS_DIR="04-findings"
fi
export REFINED_QUESTIONS_DIR FINDINGS_DIR
```

**Variant note (findings-creator web):** Also resolves `QUERY_BATCHES_DIR` via `get_directory_by_key "query-batches"` (default: `03-query-batches`).

## Step 4: Logging Initialization

```bash
# Source enhanced logging utilities (with fallback)
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  log_conditional() { echo "[$1] $2" >&2; }
  log_phase() { echo "[PHASE] ========== $1 [$2] ==========" >&2; }
  log_metric() { echo "[METRIC] $1=$2 unit=$3" >&2; }
fi

LOG_FILE="${PROJECT_PATH:-.}/.logs/{variant}/execution-log.txt"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
log_phase "{variant}" "start"
```

**Variant substitutions:**
| Variant | `{variant}` | Additional exports |
|---------|-------------|-------------------|
| findings-creator | `findings-creator` | `QUERY_BATCHES_DIR`, `CURRENT_QUESTION_ID`, `CURRENT_QUESTION_PATH` |
| findings-creator-llm | `findings-creator-llm` | EXIT trap for crash logging |
| findings-creator-file | `findings-creator-file` | `STORE_PATH` |

## Step 5: Context Clearing (Anti-Contamination)

```bash
unset PREV_QUESTION_ID PREV_PICOT CACHED_INTERVENTION_TERMS \
      BATCH_ID BATCH_FILE CONFIG_COUNT BATCH_REF \
      FINDING_COUNT WEB_FINDINGS LLM_FINDINGS \
      PREV_BATCH_ID PREV_CONFIG_COUNT \
      2>/dev/null || true
```

Required for parallel execution safety across concurrent agent invocations.
