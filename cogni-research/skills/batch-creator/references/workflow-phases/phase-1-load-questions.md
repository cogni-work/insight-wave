---
reference: phase-1-load-questions
version: 1.0.0
checksum: phase-1-load-questions-v1.0.0-batch-creator
dependencies: [phase-0-environment]
phase: 1
---

# Phase 1: Load Refined Questions

**Checksum:** `phase-1-load-questions-v1.0.0-batch-creator`

---

## Purpose

Load all refined question entities from `02-refined-questions/data/` and extract PICOT metadata for query optimization.

---

## Step 1.1: Glob Question Files

**⚠️ TEMP SCRIPT REQUIRED**: The code below uses bash arrays which are PROHIBITED for inline execution. Write this to a temp script file and execute with `bash script.sh`.

```bash
# Find all question files
# NOTE: Questions are stored in 02-refined-questions/data/ subdirectory
QUESTIONS_DIR="${PROJECT_PATH}/02-refined-questions/data"
QUESTION_FILES=($(find "${QUESTIONS_DIR}" -maxdepth 1 -name "question-*.md" -type f | sort))

QUESTION_COUNT=${#QUESTION_FILES[@]}
log_conditional INFO "Found ${QUESTION_COUNT} question files"

if [ ${QUESTION_COUNT} -eq 0 ]; then
  log_conditional ERROR "No question files found"
  exit 113
fi
```

**Inline alternative** (for simple count without array):

```bash
QUESTIONS_DIR="${PROJECT_PATH}/02-refined-questions/data" && find "${QUESTIONS_DIR}" -maxdepth 1 -name "question-*.md" -type f | wc -l | tr -d ' '
```

---

## Step 1.2: Extract PICOT Metadata

For each question file, extract frontmatter using yq:

**⚠️ IMPORTANT**: Extract frontmatter ONLY (between `---` delimiters) before parsing with yq. Parsing the entire markdown file causes YAML errors when the body contains markdown syntax like `**bold**` that resembles YAML anchor references.

```bash
for QUESTION_FILE in "${QUESTION_FILES[@]}"; do
  QUESTION_ID=$(basename "${QUESTION_FILE}" .md)

  # Extract ONLY frontmatter (between --- delimiters) to avoid parsing markdown body
  # The markdown body may contain **bold** text that yq misinterprets as YAML anchors
  FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "${QUESTION_FILE}" | sed '1d;$d')

  # Extract PICOT from frontmatter
  PICOT_POPULATION=$(echo "$FRONTMATTER" | yq -r '.picot_structure.population // .picot.population // ""')
  PICOT_INTERVENTION=$(echo "$FRONTMATTER" | yq -r '.picot_structure.intervention // .picot.intervention // ""')
  PICOT_COMPARISON=$(echo "$FRONTMATTER" | yq -r '.picot_structure.comparison // .picot.comparison // ""')
  PICOT_OUTCOME=$(echo "$FRONTMATTER" | yq -r '.picot_structure.outcome // .picot.outcome // ""')
  PICOT_TIMEFRAME=$(echo "$FRONTMATTER" | yq -r '.picot_structure.timeframe // .picot.timeframe // ""')

  # Extract question text
  QUESTION_TEXT=$(echo "$FRONTMATTER" | yq -r '.question.text // .question_text // ""')

  # Extract dimension reference
  DIMENSION_REF=$(echo "$FRONTMATTER" | yq -r '.dimension_ref // ""')

  log_conditional DEBUG "Loaded: ${QUESTION_ID}"
done
```

---

## Step 1.3: Build Questions Array

Store question data for Phase 2 processing:

**⚠️ TEMP SCRIPT REQUIRED**: The code below uses `declare -a` which is PROHIBITED for inline execution. Include this in your temp script file.

```bash
# Initialize tracking arrays
declare -a QUESTIONS_TO_PROCESS
QUESTIONS_PROCESSED=0
QUESTIONS_FAILED=0

for i in "${!QUESTION_FILES[@]}"; do
  QUESTIONS_TO_PROCESS+=("${QUESTION_FILES[$i]}")
done

log_metric "questions_loaded" "${QUESTION_COUNT}"
log_phase "Phase 1: Load Refined Questions" "complete"
```

---

## Expected Outputs

| Output | Type | Description |
|--------|------|-------------|
| QUESTION_FILES | Array | Paths to all question files |
| QUESTION_COUNT | Integer | Total questions to process |
| QUESTIONS_TO_PROCESS | Array | Queue for Phase 2 processing |

---

## Shell Compatibility Requirements

Claude Code executes bash via the user's default shell (often zsh). To avoid parse errors:

**PROHIBITED in inline bash:**

- Multi-line if/then/else/fi blocks
- Bash array assignments: `ARRAY=($(...))`
- Newlines between statements
- `declare -a` syntax
- Multiple variable assignments without separators: `A=$(cmd) B=$(cmd) echo`

**REQUIRED patterns:**

- Single-line conditionals: `[ -d "$DIR" ] && echo "exists" || echo "missing"`
- Chain with &&: `mkdir -p "$DIR" && cd "$DIR" && pwd`
- Separate assignments with && or ;: `A=$(cmd) && B=$(cmd) && echo "$A $B"`
- For loops: Use `find ... | while read -r file; do ...; done`
- For complex logic: Write to temp script file, then execute with `bash script.sh`

**NOTE**: The bash code blocks in this reference file show the LOGIC to implement, not copy-paste commands. When executing inline, convert multi-line blocks to single-line equivalents or write to a temp script.

### Temp Script Creation Pattern

To create temporary bash scripts, use the Bash tool with heredoc (NOT Write tool):

```bash
cat > /tmp/load-questions.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
export PROJECT_PATH="${PROJECT_PATH}"

# Questions are in data/ subdirectory
QUESTIONS_DIR="${PROJECT_PATH}/02-refined-questions/data"
QUESTION_FILES=($(find "${QUESTIONS_DIR}" -maxdepth 1 -name "question-*.md" -type f | sort))
QUESTION_COUNT=${#QUESTION_FILES[@]}

echo "Found ${QUESTION_COUNT} questions"
# ... rest of processing logic ...
SCRIPT_EOF
chmod +x /tmp/load-questions.sh
```

Then execute: `bash /tmp/load-questions.sh`

**⚠️ Write Tool Limitation**: The Write tool requires reading a file first. For new temp scripts, ALWAYS use `cat > file << 'EOF'` via Bash tool.

---

## Iteration Counter Initialization (MANDATORY)

After loading all questions, initialize the iteration counters for Phase 2+3 loop:

```bash
# Initialize iteration tracking (REQUIRED before Phase 2+3 loop)
QUESTION_INDEX=0
QUESTIONS_TOTAL=${#QUESTION_FILES[@]}
BATCHES_CREATED=0
BATCHES_FAILED=0
TOTAL_CONFIGS=0

log_conditional INFO "Iteration setup complete: ${QUESTIONS_TOTAL} questions to process"
```

**CRITICAL:** These counters MUST be initialized before entering the Phase 2+3 loop. The loop will NOT function correctly without them.

---

## Next Phase

Proceed to the **Phase 2+3 iteration loop** (see SKILL.md) to process ALL questions sequentially.
