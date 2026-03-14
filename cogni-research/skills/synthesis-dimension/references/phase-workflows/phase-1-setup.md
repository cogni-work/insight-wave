# Phase 1: Setup & Validation

## Objective

Validate parameters and verify all prerequisites exist before attempting synthesis.

## Prerequisites

- None (first phase)

## TodoWrite Expansion

When entering Phase 1, expand to these step-level todos:

```text
1.1 Validate project-path parameter [in_progress]
1.2 Validate dimension parameter [pending]
1.3 Verify README-{dimension}.md exists [pending]
1.4 Verify trend files exist for dimension [pending]
1.5 Read sprint-log.json for research_type and language [pending]
1.5b Read arc configuration from sprint-log.json [pending]
1.6 Initialize logging [pending]
```

---

## Step 1.1: Validate Project Path

**Action:** Verify `--project-path` parameter is provided and directory exists.

```bash
# Check parameter exists
if [[ -z "${PROJECT_PATH}" ]]; then
  echo '{"success": false, "error": "Missing required parameter: --project-path"}'
  exit 1
fi

# Check directory exists
if [[ ! -d "${PROJECT_PATH}" ]]; then
  echo '{"success": false, "error": "Project path does not exist: ${PROJECT_PATH}"}'
  exit 1
fi
```

**Verification:** Project path is valid directory.

---

## Step 1.2: Validate Dimension Parameter

**Action:** Verify `--dimension` parameter is provided.

```bash
# Check parameter exists
if [[ -z "${DIMENSION}" ]]; then
  echo '{"success": false, "error": "Missing required parameter: --dimension"}'
  exit 1
fi
```

**Verification:** Dimension slug is provided.

---

## Step 1.3: Verify README Exists

**Action:** Check that `11-trends/README-{dimension}.md` exists.

**Primary check (Bash):**

```bash
README_PATH="${PROJECT_PATH}/11-trends/README-${DIMENSION}.md"
if [[ ! -f "${README_PATH}" ]]; then
  echo '{"success": false, "error": "README not found for dimension", "expected_path": "11-trends/README-'${DIMENSION}'.md", "remediation": "Run trends-creator for this dimension first"}'
  exit 1
fi
```

**Secondary validation (Read tool):**

```text
Read: ${PROJECT_PATH}/11-trends/README-${DIMENSION}.md
```

Confirm file is readable and contains expected structure (trend table).

**If file does not exist or is unreadable:**

```json
{
  "success": false,
  "error": "README not found for dimension",
  "expected_path": "11-trends/README-{dimension}.md",
  "remediation": "Run trends-creator for this dimension first"
}
```

**Verification:** README file exists (test -f) AND is readable (Read tool).

---

## Step 1.4: Verify Trend Files Exist

**Action:** Check that trend files exist for this dimension in `11-trends/data/`.

**Use Glob tool:**

```text
Glob: ${PROJECT_PATH}/11-trends/data/trend-*.md
```

**Parse README to extract trend file paths:**

Look for table rows linking to `data/trend-*.md` files.

**Minimum requirement:** At least 3 trends for the dimension.

**If insufficient trends:**

```json
{
  "success": false,
  "error": "Insufficient trends for synthesis",
  "trends_found": 2,
  "minimum_required": 3,
  "remediation": "Ensure trends-creator completed successfully for this dimension"
}
```

**Verification:** 3+ trend files exist for dimension.

---

## Step 1.5: Read Sprint Log for Research Type and Language

**Action:** Read `.metadata/sprint-log.json` to determine research_type and project language.

**Reference:** See [../language-templates.md](../language-templates.md) for complete language template definitions.

**Use Read tool:**

```text
Read: ${PROJECT_PATH}/.metadata/sprint-log.json
```

**Extract:**

- `research_type` - Determines synthesis structure (generic, smarter-service, lean-canvas)
- `project_language` - Determines output language and section headers (de, en)

**Language Loading Protocol:**

```bash
# Phase 1.5: Load Project Language
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "$PROJECT_PATH/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Validate against supported languages
case "$PROJECT_LANGUAGE" in
  en|de)
    log_conditional INFO "PROJECT_LANGUAGE=$PROJECT_LANGUAGE"
    ;;
  *)
    log_conditional WARNING "Unsupported language: $PROJECT_LANGUAGE, defaulting to en"
    PROJECT_LANGUAGE="en"
    ;;
esac
```

**Store variables:**

```text
RESEARCH_TYPE="generic"  # or smarter-service, lean-canvas
PROJECT_LANGUAGE="de"    # or en (validated, supported languages only)
```

**Language impact:** PROJECT_LANGUAGE determines:

- Section headers (see language-templates.md for translations)
- Navigation labels
- Evidence assessment table headers
- Formatting conventions (umlauts for German)

**Verification:** Research type detected, language validated against supported list (en, de).

---

## Step 1.5b: Read Arc Configuration

**Action:** Read `arc_id` and `arc_display_name` from `.metadata/sprint-log.json` to determine if arc-aware synthesis should be used.

**Use Read tool (same file as Step 1.5):**

```text
Read: ${PROJECT_PATH}/.metadata/sprint-log.json
```

**Extract:**

- `arc_id` - Determines synthesis document structure (e.g., "corporate-visions", "technology-futures")
- `arc_display_name` - Human-readable arc name for frontmatter

**Arc Configuration Protocol:**

```bash
# Phase 1.5b: Load Arc Configuration
ARC_ID=$(jq -r '.arc_id // ""' "$PROJECT_PATH/.metadata/sprint-log.json" 2>/dev/null || echo "")
ARC_DISPLAY_NAME=$(jq -r '.arc_display_name // ""' "$PROJECT_PATH/.metadata/sprint-log.json" 2>/dev/null || echo "")

# Validate against recognized arcs
if [ -n "$ARC_ID" ]; then
  case "$ARC_ID" in
    corporate-visions|technology-futures|competitive-intelligence|strategic-foresight|industry-transformation)
      log_conditional INFO "ARC_ID=$ARC_ID (recognized)"
      ARC_TEMPLATE="synthesis-template-${ARC_ID}.md"
      ;;
    *)
      log_conditional WARNING "Unrecognized arc_id: $ARC_ID, using generic template"
      ARC_ID=""
      ARC_DISPLAY_NAME=""
      ARC_TEMPLATE=""
      ;;
  esac
else
  log_conditional INFO "No arc_id set, using generic template"
  ARC_TEMPLATE=""
fi
```

**If ARC_ID is recognized:** Read the corresponding arc template from `references/templates/synthesis-template-{arc_id}.md` to load arc element definitions, signal words, and section header translations.

**Arc template routing:**

| arc_id | Template File |
|--------|--------------|
| `corporate-visions` | `synthesis-template-corporate-visions.md` |
| `technology-futures` | `synthesis-template-technology-futures.md` |
| `competitive-intelligence` | `synthesis-template-competitive-intelligence.md` |
| `strategic-foresight` | `synthesis-template-strategic-foresight.md` |
| `industry-transformation` | `synthesis-template-industry-transformation.md` |
| (empty or unrecognized) | `synthesis-template-generic.md` (default) |

**Store variables:**

```text
ARC_ID="corporate-visions"     # or "" if not set/unrecognized
ARC_DISPLAY_NAME="Corporate Visions"  # or "" if not set
ARC_TEMPLATE="synthesis-template-corporate-visions.md"  # or "" for generic
```

**Verification:** Arc configuration read; if present, validated against recognized arc IDs.

---

## Step 1.6: Initialize Logging

**Action:** Set up logging infrastructure.

```bash
# Initialize skill-specific log file
SKILL_NAME="synthesis-dimension"
LOG_FILE="${PROJECT_PATH}/.metadata/${SKILL_NAME}-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.metadata"

# Log phase start
echo "[$(date -Iseconds)] Phase 1: Setup - START" >> "${LOG_FILE}"
echo "[$(date -Iseconds)] Dimension: ${DIMENSION}" >> "${LOG_FILE}"
echo "[$(date -Iseconds)] Research Type: ${RESEARCH_TYPE}" >> "${LOG_FILE}"
```

**Verification:** Log file created and writable.

---

## Verification Checkpoint

Before proceeding to Phase 2, answer these questions:

1. "What is the project path?" → Must be valid directory
2. "What dimension am I synthesizing?" → Must be non-empty slug
3. "Does the README exist for this dimension?" → Must be readable
4. "How many trends exist for this dimension?" → Must be 3+
5. "What is the research type?" → Must be detected from sprint-log
6. "What language should the output use?" → Must be detected
7. "Is an arc configured?" → ARC_ID is set (recognized) or empty (generic path)

**If ANY question cannot be answered → STOP and resolve the issue.**

---

## Phase 1 Outputs

- `PROJECT_PATH` validated
- `DIMENSION` validated
- `README-{dimension}.md` confirmed to exist
- Trend count confirmed (minimum 3)
- `RESEARCH_TYPE` extracted
- `PROJECT_LANGUAGE` extracted
- `ARC_ID` extracted (may be empty for generic path)
- `ARC_DISPLAY_NAME` extracted (may be empty)
- `ARC_TEMPLATE` resolved (template filename or empty)
- Logging initialized

---

## Error Responses

### Missing Project Path

```json
{
  "success": false,
  "phase": 1,
  "step": "1.1",
  "error": "Missing required parameter: --project-path"
}
```

### Missing Dimension

```json
{
  "success": false,
  "phase": 1,
  "step": "1.2",
  "error": "Missing required parameter: --dimension"
}
```

### README Not Found

```json
{
  "success": false,
  "phase": 1,
  "step": "1.3",
  "error": "README not found for dimension",
  "dimension": "{dimension}",
  "remediation": "Run trends-creator for this dimension first"
}
```

### Insufficient Trends

```json
{
  "success": false,
  "phase": 1,
  "step": "1.4",
  "error": "Insufficient trends for synthesis",
  "trends_found": 2,
  "minimum_required": 3
}
```

---

## Transition to Phase 2

**Gate:** All 7 steps (1.1-1.6 including 1.5b) completed successfully.

**Mark Phase 1 todo as completed.**

**Proceed to:** [phase-2-loading.md](phase-2-loading.md)
