# Phase 0: Initialize Project + Industry Selection

**Reference Checksum:** `sha256:trend-scout-p0-init-v1`

**Verification Protocol:** After reading, confirm complete load:

```text
Reference Loaded: phase-0-initialize.md | Checksum: trend-scout-p0-init-v1
```

---

## Objective

Initialize the trend-scout workflow by detecting language, collecting industry selection, capturing research topic, and creating the project structure.

**Expected Duration:** 60-120 seconds (interactive)

---

## Step 0.1: Detect Interaction Language

Read the workspace language from `.workspace-config.json` to determine how to communicate with the user. This is the **interaction language** — separate from the output/project language (asked in Step 0.1b).

See `$CLAUDE_PLUGIN_ROOT/references/language-resolution.md` for the full pattern.

```bash
# Read workspace language setting
WORKSPACE_DIR="${PROJECT_AGENTS_OPS_ROOT:-$(pwd)}"
if [[ -f "${WORKSPACE_DIR}/.workspace-config.json" ]]; then
  INTERACTION_LANGUAGE=$(jq -r '.language // "en"' "${WORKSPACE_DIR}/.workspace-config.json")
else
  INTERACTION_LANGUAGE="en"
fi

# Load the matching message catalog for user-facing messages
if [[ "$INTERACTION_LANGUAGE" == "de" ]]; then
  MESSAGES_FILE="references/i18n/messages-de.md"
else
  MESSAGES_FILE="references/i18n/messages-en.md"
fi

log_conditional INFO "Interaction language: $INTERACTION_LANGUAGE (from workspace config)"
```

All user-facing messages from this point on — AskUserQuestion prompts, status messages, instructions — use `INTERACTION_LANGUAGE`.

## Step 0.1b: Ask User for Output Language

Present the output language question in the interaction language. The workspace language is the pre-selected default:

**If INTERACTION_LANGUAGE == "de":**
```yaml
AskUserQuestion:
  question: "In welcher Sprache sollen die Ergebnisse erstellt werden?"
  header: "Ausgabesprache"
  options:
    - label: "Deutsch (DE) ← Workspace-Standard"
    - label: "English (EN)"
```

**If INTERACTION_LANGUAGE == "en":**
```yaml
AskUserQuestion:
  question: "What language should the deliverables be written in?"
  header: "Output language"
  options:
    - label: "English (EN) ← Workspace default"
    - label: "Deutsch (DE)"
```

```bash
# Set from explicit user choice
PROJECT_LANGUAGE="${USER_CHOICE}"

log_conditional INFO "Output language: $PROJECT_LANGUAGE (user choice)"
```

---

## Step 0.1c: Portfolio Project Discovery (Optional)

Scan the workspace for existing cogni-portfolio projects. If found, offer the user
the option to start trend-scouting for one of their portfolio markets, pre-populating
industry, subsector, and optionally research topic.

This connects TIPS scouting to the user's existing product portfolio from the start,
establishing an early link that the tips-bridge can leverage later.

### Discovery

```bash
WORKSPACE_DIR="${COGNI_WORKSPACE_ROOT:-$(pwd)}"
DISCOVERY_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/discover-portfolio-markets.sh"

PORTFOLIO_FOUND=false
PORTFOLIO_SOURCE_SLUG=""
PORTFOLIO_MARKET_SLUG=""

if [[ -f "$DISCOVERY_SCRIPT" ]]; then
  DISCOVERY_OUTPUT=$(bash "$DISCOVERY_SCRIPT" --workspace "$WORKSPACE_DIR" --json)
  PORTFOLIO_FOUND=$(echo "$DISCOVERY_OUTPUT" | jq -r '.found')
else
  log_conditional INFO "Portfolio discovery script not found — skipping"
fi
```

### If no portfolio projects found

```bash
if [[ "$PORTFOLIO_FOUND" != "true" ]]; then
  log_conditional INFO "{PORTFOLIO_DISCOVERY_NONE}"
  # Fall through to Step 0.2
fi
```

### If portfolio projects found

Build the selection list from discovered markets. Only include markets with
`tips_alignment.level` of `exact` or `vertical`. Markets with `broad` alignment
are shown with a note. Markets with `none` alignment are hidden.

```yaml
AskUserQuestion:
  question: |
    {PORTFOLIO_DISCOVERY_HEADER}

    {PORTFOLIO_DISCOVERY_INTRO}

    {FOR_EACH_PROJECT}
    **{PORTFOLIO_DISCOVERY_PROJECT}**
    {FOR_EACH_MARKET where tips_alignment.level != "none"}
      {N}) {PORTFOLIO_DISCOVERY_MARKET}
    {END_FOR}
    {END_FOR}

    {PORTFOLIO_DISCOVERY_SELECT}
  options:
    - label: "1) {market_1_name} ({region}) [{alignment}]"
    - label: "2) {market_2_name} ({region}) [{alignment}]"
    - label: "..."
    - label: "{PORTFOLIO_DISCOVERY_MANUAL}"
```

### Parse Selection

**Outcome A — User selects a portfolio market:**

```bash
# Extract selected market from discovery output
SELECTED_PROJECT=$(echo "$DISCOVERY_OUTPUT" | jq -r ".projects[$PROJECT_INDEX]")
SELECTED_MARKET=$(echo "$SELECTED_PROJECT" | jq -r ".markets[$MARKET_INDEX]")

# Pre-populate industry variables from tips_alignment
INDUSTRY_EN=$(echo "$SELECTED_MARKET" | jq -r '.tips_alignment.matched_industry_en')
INDUSTRY_DE=$(echo "$SELECTED_MARKET" | jq -r '.tips_alignment.matched_industry_de')
INDUSTRY_SLUG=$(echo "$SELECTED_MARKET" | jq -r '.tips_alignment.matched_industry')
SUBSECTOR_EN=$(echo "$SELECTED_MARKET" | jq -r '.tips_alignment.matched_subsector_en')
SUBSECTOR_DE=$(echo "$SELECTED_MARKET" | jq -r '.tips_alignment.matched_subsector_de')
SUBSECTOR_SLUG=$(echo "$SELECTED_MARKET" | jq -r '.tips_alignment.matched_subsector')

PORTFOLIO_SOURCE_SLUG=$(echo "$SELECTED_PROJECT" | jq -r '.slug')
PORTFOLIO_MARKET_SLUG=$(echo "$SELECTED_MARKET" | jq -r '.slug')

log_conditional INFO "{PORTFOLIO_DISCOVERY_SELECTED}"
log_conditional INFO "Industry pre-populated: $INDUSTRY_EN / $INDUSTRY_DE"
log_conditional INFO "Subsector pre-populated: $SUBSECTOR_EN / $SUBSECTOR_DE"

# SKIP Step 0.2 and Step 0.3 — industry is already resolved
```

**Outcome B — User selects "Manual selection":**

```bash
PORTFOLIO_SOURCE_SLUG=""
PORTFOLIO_MARKET_SLUG=""
# Fall through to Step 0.2
```

---

## Step 0.2: Present Industry Taxonomy

**Skip condition:** If `PORTFOLIO_SOURCE_SLUG` is set (user selected a portfolio market
in Step 0.1c), skip this step entirely. Industry and subsector are already populated.

Load and present the industry taxonomy to the user:

1. Read [../industry-taxonomy.md](../industry-taxonomy.md)
2. Display bilingual industry list (see Presentation Templates section)
3. Use AskUserQuestion to capture selection

### Presentation Format

Use the appropriate template from industry-taxonomy.md based on PROJECT_LANGUAGE:

- English: Use "English Presentation" template
- German: Use "German Presentation" template

### AskUserQuestion Parameters

```yaml
AskUserQuestion:
  question: |
    {INDUSTRY_SELECTION_TITLE}

    {TAXONOMY_PRESENTATION}

    {INDUSTRY_SELECTION_PROMPT}
```

---

## Step 0.3: Parse Industry Selection

**Skip condition:** If `PORTFOLIO_SOURCE_SLUG` is set (user selected a portfolio market
in Step 0.1c), skip this step entirely. Industry and subsector are already populated.

Parse the user's industry selection:

### MANDATORY: Thinking Block for Selection Parsing

<thinking>
**Industry Selection Parsing**

User input: "[USER_RESPONSE]"

Attempting parse methods:
1. Number+Letter pattern (e.g., "1a"):
   - Match: [YES/NO]
   - Industry number: [N]
   - Subsector letter: [x]

2. Full name match:
   - Match: [YES/NO]
   - Matched entry: [ENTRY]

3. Natural language inference:
   - Keywords: [LIST]
   - Best match: [ENTRY]
   - Confidence: [HIGH/MEDIUM/LOW]

Parsed result:
- Industry (EN): [VALUE]
- Industry (DE): [VALUE]
- Industry slug: [VALUE]
- Subsector (EN): [VALUE]
- Subsector (DE): [VALUE]
- Subsector slug: [VALUE]
</thinking>

```bash
# Set parsed values
INDUSTRY_EN="Manufacturing"
INDUSTRY_DE="Fertigung"
INDUSTRY_SLUG="manufacturing"
SUBSECTOR_EN="Automotive"
SUBSECTOR_DE="Automobil"
SUBSECTOR_SLUG="automotive"

log_conditional INFO "Selected industry: $INDUSTRY_EN / $INDUSTRY_DE"
log_conditional INFO "Selected subsector: $SUBSECTOR_EN / $SUBSECTOR_DE"
```

**If parsing fails:** Re-prompt user with clarification.

---

## Step 0.4: Capture Research Topic

Prompt user for their specific research focus.

### Topic Suggestion from Portfolio (when applicable)

If `PORTFOLIO_MARKET_SLUG` is set, read the market's `name` and `description` to
suggest a research topic. The market context provides a natural starting point —
e.g., a market named "Mid-Market SaaS (DACH)" with vertical "saas" might suggest
"Digital transformation trends for SaaS companies in DACH". Present the suggestion
but always allow the user to override:

```yaml
# When portfolio market was selected:
AskUserQuestion:
  question: |
    {TOPIC_PROMPT_TITLE}

    {PORTFOLIO_DISCOVERY_TOPIC_SUGGEST}

    {TOPIC_PROMPT_INTRO}

    {TOPIC_PROMPT_EXAMPLE}
  options:
    - label: "Use suggested topic: '{SUGGESTED_TOPIC}'"
    - label: "Enter my own topic"
```

### Standard Topic Prompt (no portfolio or user chose "Enter my own")

```yaml
AskUserQuestion:
  question: |
    {TOPIC_PROMPT_TITLE}

    {TOPIC_PROMPT_INTRO}

    {TOPIC_PROMPT_EXAMPLE}

    {TOPIC_PROMPT_ENTER}
```

### Parse Topic Response

```bash
RESEARCH_TOPIC="$USER_RESPONSE"
RESEARCH_TOPIC_NORMALIZED=$(echo "$RESEARCH_TOPIC" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

log_conditional INFO "Research topic: $RESEARCH_TOPIC"
log_conditional INFO "Normalized topic: $RESEARCH_TOPIC_NORMALIZED"
```

---

## Step 0.5: Generate Project Slug

Create a semantic project slug combining industry and topic:

```bash
# Use generate-project-slug.sh script
# CRITICAL: Use CLAUDE_PLUGIN_ROOT for scripts, NOT COGNI_WORKSPACE_ROOT
SCRIPT_PATH="${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/generate-project-slug.sh"

# Validate script exists - do NOT improvise if missing
if [[ ! -f "$SCRIPT_PATH" ]]; then
  log_conditional ERROR "Script not found: $SCRIPT_PATH"
  log_conditional ERROR "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"
  log_conditional ERROR "Please verify plugin installation"
  exit 1
fi

SLUG_OUTPUT=$(bash "$SCRIPT_PATH" \
  --industry "$SUBSECTOR_SLUG" \
  --topic "$RESEARCH_TOPIC_NORMALIZED" \
  --json)

PROJECT_SLUG=$(echo "$SLUG_OUTPUT" | jq -r '.data.semantic_uuid')

log_conditional INFO "Generated project slug: $PROJECT_SLUG"
```

### Slug Pattern

`{subsector}-{topic}-{hash}`

Examples:
- `automotive-ai-predictive-maintenance-a1b2c3d4`
- `pharmaceuticals-drug-discovery-automation-e5f6g7h8`
- `banking-digital-customer-onboarding-i9j0k1l2`

---

## Step 0.6: Check for Existing Project

```bash
# Get projects root (defaults to current working directory)
PROJECTS_ROOT="${COGNI_WORKSPACE_ROOT:-$(pwd)}"
PROJECT_PATH="${PROJECTS_ROOT}/cogni-tips/${PROJECT_SLUG}"

if [[ -d "$PROJECT_PATH" ]]; then
  # Check if it's a trend-scout project
  if [[ -f "${PROJECT_PATH}/.metadata/trend-scout-output.json" ]]; then
    log_conditional WARN "Project already exists with trend-scout output"

    # Check status from consolidated output
    EXISTING_STATUS=$(jq -r '.execution.workflow_state // empty' "${PROJECT_PATH}/.metadata/trend-scout-output.json" 2>/dev/null)

    if [[ "$EXISTING_STATUS" == "agreed" ]]; then
      log_conditional INFO "Existing project is finalized - nothing to do"
      exit 0
    elif [[ -n "$EXISTING_STATUS" ]]; then
      log_conditional INFO "Existing project with status: $EXISTING_STATUS - resuming"
      SKIP_TO_PHASE=4  # Resume at selection processing
    fi
  else
    log_conditional ERROR "Directory exists but is not a trend-scout project"
    # Prompt user to choose different topic or delete existing
    exit 1
  fi
fi
```

---

## Step 0.7: Initialize Project Structure

Use trend-scout initialization script (simplified structure):

```bash
# Initialize trend-scout project
# CRITICAL: Use CLAUDE_PLUGIN_ROOT for scripts, NOT COGNI_WORKSPACE_ROOT
INIT_SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/initialize-trend-project.sh"

# Validate script exists - do NOT improvise if missing
if [[ ! -f "$INIT_SCRIPT" ]]; then
  log_conditional ERROR "Script not found: $INIT_SCRIPT"
  log_conditional ERROR "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"
  log_conditional ERROR "Please verify plugin installation"
  exit 1
fi

INIT_OUTPUT=$(bash "$INIT_SCRIPT" \
  --project-name "$PROJECT_SLUG" \
  --skill-dir "cogni-tips" \
  --industry "$SUBSECTOR_SLUG" \
  --language "$PROJECT_LANGUAGE" \
  --json)

if [[ ! $(echo "$INIT_OUTPUT" | jq -r '.success') == "true" ]]; then
  log_conditional ERROR "Project initialization failed"
  log_conditional ERROR "$(echo "$INIT_OUTPUT" | jq -r '.error')"
  exit 1
fi

PROJECT_PATH=$(echo "$INIT_OUTPUT" | jq -r '.project_path')
OUTPUT_FILE=$(echo "$INIT_OUTPUT" | jq -r '.output_file')

log_conditional INFO "Project initialized at: $PROJECT_PATH"
log_conditional INFO "Output file: $OUTPUT_FILE"
```

---

## Step 0.8: Write Industry Metadata

Update consolidated trend-scout-output.json with industry metadata:

```bash
# Use update-industry-metadata.sh script
# CRITICAL: Use CLAUDE_PLUGIN_ROOT for scripts, NOT COGNI_WORKSPACE_ROOT
METADATA_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/trend-scout/scripts/update-industry-metadata.sh"

# Validate script exists - do NOT improvise if missing
if [[ ! -f "$METADATA_SCRIPT" ]]; then
  log_conditional ERROR "Script not found: $METADATA_SCRIPT"
  log_conditional ERROR "CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}"
  log_conditional ERROR "Please verify plugin installation"
  exit 1
fi

# Build metadata update command — portfolio args are optional
METADATA_ARGS=(
  --output-file "${PROJECT_PATH}/.metadata/trend-scout-output.json"
  --industry "$INDUSTRY_SLUG"
  --industry-en "$INDUSTRY_EN"
  --industry-de "$INDUSTRY_DE"
  --subsector "$SUBSECTOR_SLUG"
  --subsector-en "$SUBSECTOR_EN"
  --subsector-de "$SUBSECTOR_DE"
  --topic "$RESEARCH_TOPIC"
  --topic-normalized "$RESEARCH_TOPIC_NORMALIZED"
)

# Append portfolio source if this init was portfolio-sourced
if [[ -n "$PORTFOLIO_SOURCE_SLUG" && -n "$PORTFOLIO_MARKET_SLUG" ]]; then
  METADATA_ARGS+=(--portfolio-slug "$PORTFOLIO_SOURCE_SLUG" --portfolio-market "$PORTFOLIO_MARKET_SLUG")
fi

METADATA_ARGS+=(--json)

METADATA_OUTPUT=$(bash "$METADATA_SCRIPT" "${METADATA_ARGS[@]}")

if [[ ! $(echo "$METADATA_OUTPUT" | jq -r '.success') == "true" ]]; then
  log_conditional ERROR "Failed to update industry metadata"
  log_conditional ERROR "$(echo "$METADATA_OUTPUT" | jq -r '.error')"
  exit 1
fi

log_conditional INFO "Updated trend-scout-output.json with industry metadata"
```

---

## Step 0.9: Initialize Logging

```bash
# Create logs directory
mkdir -p "${PROJECT_PATH}/.logs"

# Initialize skill-specific log file
SKILL_NAME="trend-scout"
LOG_FILE="${PROJECT_PATH}/.logs/${SKILL_NAME}-execution-log.txt"

# Log initialization
log_phase "Phase 0: Initialize Project + Industry Selection" "start"
log_conditional INFO "Skill: trend-scout"
log_conditional INFO "Project: ${PROJECT_PATH}"
log_conditional INFO "Language: ${PROJECT_LANGUAGE}"
log_conditional INFO "Industry: ${INDUSTRY_EN} / ${INDUSTRY_DE}"
log_conditional INFO "Subsector: ${SUBSECTOR_EN} / ${SUBSECTOR_DE}"
log_conditional INFO "Topic: ${RESEARCH_TOPIC}"
```

---

## Step 0.10: Configure Web Research

```bash
# Web research is enabled by default for trend-scout
WEB_RESEARCH_ENABLED=true

log_conditional INFO "Web research: ENABLED (bilingual search)"
```

---

## Step 0.11: Mark Phase 0 Complete

```bash
log_phase "Phase 0: Initialize Project + Industry Selection" "complete"

# Set next phase
SKIP_TO_PHASE=1  # Proceed to web research
```

---

## Success Criteria

- [ ] INTERACTION_LANGUAGE detected from workspace config (de/en)
- [ ] PROJECT_LANGUAGE confirmed by user (de/en)
- [ ] Portfolio discovery attempted (scan result logged)
- [ ] If portfolio selected: PORTFOLIO_SOURCE_SLUG and PORTFOLIO_MARKET_SLUG set
- [ ] Industry and subsector selected and validated (from portfolio or manual taxonomy)
- [ ] RESEARCH_TOPIC captured
- [ ] PROJECT_SLUG generated
- [ ] Project structure initialized in current working directory (or `COGNI_WORKSPACE_ROOT` if set)
- [ ] trend-scout-output.json updated with industry metadata (and portfolio_source if applicable)
- [ ] Logging initialized
- [ ] WEB_RESEARCH_ENABLED set

---

## Variables Set

| Variable | Description | Example |
|----------|-------------|---------|
| INTERACTION_LANGUAGE | Workspace language for user communication | `de` or `en` |
| PROJECT_LANGUAGE | User-confirmed output language | `de` or `en` |
| INDUSTRY_EN | English industry name | `Manufacturing` |
| INDUSTRY_DE | German industry name | `Fertigung` |
| INDUSTRY_SLUG | Industry slug | `manufacturing` |
| SUBSECTOR_EN | English subsector name | `Automotive` |
| SUBSECTOR_DE | German subsector name | `Automobil` |
| SUBSECTOR_SLUG | Subsector slug | `automotive` |
| RESEARCH_TOPIC | User's research topic | `AI-driven predictive maintenance` |
| PROJECT_SLUG | Full project slug | `automotive-ai-predictive-maintenance-a1b2c3d4` |
| PROJECT_PATH | Absolute project path | `/path/to/project` |
| LOG_FILE | Path to execution log | `/path/to/.logs/trend-scout-execution-log.txt` |
| WEB_RESEARCH_ENABLED | Whether to run web research | `true` |
| PORTFOLIO_SOURCE_SLUG | Portfolio project slug (empty if manual) | `acme-corp` |
| PORTFOLIO_MARKET_SLUG | Selected market slug (empty if manual) | `mid-market-saas-dach` |
| SKIP_TO_PHASE | Next phase to execute | `1` |

---

## Next Phase

Phase 1 (web research) is delegated to the `web-researcher` agent. Proceed to [phase-2-generate.md](phase-2-generate.md) after receiving the agent's compact JSON response.

---

## Error Handling

| Scenario | Response |
|----------|----------|
| Language detection unclear | Default to English, continue |
| Industry selection invalid | Re-prompt with clarification |
| Topic empty | Re-prompt, require input |
| Project exists (finalized) | Exit 0, nothing to do |
| Project exists (in progress) | Resume at Phase 4 |
| Project init fails | Exit 1 with error |
