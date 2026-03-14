# Phase 8: Parallel Trend Generation

Generate trends from research findings using parallel agent invocation (one agent per dimension).

**Strategy:** Always invoke parallel trends-creator agents (one per dimension from `01-research-dimensions/data/`).

---

## ⛔ PHASE ENTRY VERIFICATION (MANDATORY)

**Self-Verification:** Before running bash verification, check TodoWrite to verify Phase 7 is marked complete. Phase 8 cannot begin until Phase 7 todos are completed.

**THEN verify Phase 7 artifacts exist:**

```bash
ls -la 10-claims/data/ | head -20
test -d 10-claims/data/ && [ "$(ls -A 10-claims/data/)" ]
```

**IF 10-claims/data/ directory is missing OR empty:**

1. STOP immediately
2. Return to Phase 7
3. Create the required claim entities
4. Only then return to Phase 8

**This is not optional.** Skipping Phase 7 artifacts means the synthesis lacks verified claims.

---

## ⛔ Anti-Pattern: DO NOT Load Entities

**PROHIBITED at Phase 8 level:**

- ❌ Reading findings with Read tool
- ❌ Reading claims with Read tool
- ❌ Reading questions with Read tool
- ❌ Loading "representative samples" of any entity type
- ❌ Pre-loading context before invoking agents

**WHY:** Each trends-creator agent loads its OWN dimension-scoped entities in Phase 3. Loading here wastes tokens and breaks dimension filtering.

**Anti-Hallucination Note:** The anti-hallucination protocol ("complete loading required") applies INSIDE each agent, not here. Agents handle their own Phase 3 loading with dimension filtering and count verification.

**CORRECT:** Only use `ls` commands to extract dimension slugs from filenames.

---

## Step 0.5: Initialize Phase 8 TodoWrite

Add step-level todos for Phase 8:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 8, Step 0.6: Extract dimensions from 01-research-dimensions/data/ [in_progress]
- Phase 8, Step 0.7.0: Check research type supports portfolio [pending]
- Phase 8, Step 0.7.1: Validate existing portfolio connection [pending]
- Phase 8, Step 0.7.2: Prompt for portfolio connection (if missing) [pending]
- Phase 8, Step 0.7.3: Validate user-provided path [pending]
- Phase 8, Step 0.7.4: Persist portfolio connection [pending]
- Phase 8, Step 1: Invoke trends-creator agents (PARALLEL) [pending]
- Phase 8, Step 2: Validate trend files exist in 11-trends/data/ [pending]
- Phase 8, Step 3: Report completion and mark phase complete [pending]

As you complete each step, mark the corresponding todo as completed.
```

---

## Step 0.6: Extract Dimensions

**Goal:** Extract dimension list for parallel agent invocation.

**Actions:**

1. **List dimension files:**

   ```bash
   ls 01-research-dimensions/data/dimension-*.md
   ```

2. **Extract dimension slugs from filenames:**

   ```text
   Pattern: dimension-{slug}-{entity-id}.md
   Example: dimension-externe-effekte-abc123.md → "externe-effekte"
   ```

3. **Store dimension list for Step 1:**

   ```text
   dimension_list = [
     "dimension-slug-1",
     "dimension-slug-2",
     "dimension-slug-3",
     ...
   ]
   ```

**Mark Step 0.6 todo as completed** before proceeding to Step 0.7.

---

## Step 0.7: Portfolio Connection & Validation

**Goal:** Validate existing portfolio connection OR prompt user to connect a portfolio if not already connected.

**Portfolio Integration Benefit:** When enabled, trends include B2B ICT dimension bridges, Technology Enablement tables, and portfolio-linked solution references.

---

### Step 0.7.0: Check Research Type Support

**Only `smarter-service` and `customer-value-mapping` support portfolio integration.**

```bash
# Read research_type from sprint-log.json
RESEARCH_TYPE=$(jq -r '.research_type // "generic"' "${project_path}/.metadata/sprint-log.json")

case "$RESEARCH_TYPE" in
  smarter-service|customer-value-mapping)
    echo "INFO: Research type '$RESEARCH_TYPE' supports portfolio integration"
    PORTFOLIO_SUPPORTED=true
    ;;
  *)
    echo "INFO: Research type '$RESEARCH_TYPE' does not support portfolio integration - skipping"
    PORTFOLIO_SUPPORTED=false
    PORTFOLIO_PROJECT_PATH=""
    PORTFOLIO_PROJECT_SLUG=""
    PORTFOLIO_INTEGRATION_ENABLED=false
    # Skip to Step 1
    ;;
esac
```

**IF `PORTFOLIO_SUPPORTED=false`:** Mark Step 0.7.0-0.7.4 as N/A and proceed directly to Step 1.

**Mark Step 0.7.0 todo as completed** before proceeding to Step 0.7.1.

---

### Step 0.7.1: Extract & Validate Existing Portfolio

**Goal:** Check if a portfolio was connected during deeper-research-1 and validate it still exists with correct structure.

**Portfolio Structure Requirements:**

For a portfolio PROJECT (directory):

- MUST have `11-trends/` directory
- MUST have at least 1 `portfolio-*.md` file in `11-trends/`
- SHOULD have `.metadata/sprint-log.json` with `research_type: "b2b-ict-portfolio"`

For a portfolio MAPPING FILE:

- MUST be a `.md` file
- MUST contain content (non-empty)

**Actions:**

1. **Extract `linked_portfolio` from question entity frontmatter:**

   ```bash
   # Find the question entity file
   QUESTION_FILE=$(ls "${project_path}/00-initial-question/data/question-*.md" 2>/dev/null | head -1)

   if [ -n "$QUESTION_FILE" ]; then
     # Extract linked_portfolio field (wikilink format: [[project-name]] or absolute path)
     LINKED_PORTFOLIO=$(grep "^linked_portfolio:" "$QUESTION_FILE" | sed 's/linked_portfolio: *//' | tr -d '"' | tr -d "'" || echo "")
   else
     LINKED_PORTFOLIO=""
   fi

   # Also check sprint-log.json for portfolio_file_path (alternative storage)
   if [ -z "$LINKED_PORTFOLIO" ] || [ "$LINKED_PORTFOLIO" = "null" ]; then
     LINKED_PORTFOLIO=$(jq -r '.portfolio_file_path // ""' "${project_path}/.metadata/sprint-log.json")
   fi
   ```

2. **Resolve portfolio path (supports both wikilinks and absolute paths):**

   ```bash
   if [ -n "$LINKED_PORTFOLIO" ] && [ "$LINKED_PORTFOLIO" != "null" ] && [ "$LINKED_PORTFOLIO" != "" ]; then
     # Check if it's an absolute path (starts with /)
     if [[ "$LINKED_PORTFOLIO" == /* ]]; then
       PORTFOLIO_PATH="$LINKED_PORTFOLIO"
     else
       # Extract project name from wikilink [[project-name]]
       PORTFOLIO_PROJECT_NAME=$(echo "$LINKED_PORTFOLIO" | sed 's/\[\[//' | sed 's/\]\]//')
       # Resolve to absolute path (assumes sibling directory structure)
       PORTFOLIO_PATH="${COGNI_RESEARCH_ROOT}/${PORTFOLIO_PROJECT_NAME}"
     fi
     echo "INFO: Found portfolio reference: $PORTFOLIO_PATH"
   else
     PORTFOLIO_PATH=""
     echo "INFO: No portfolio reference found in project metadata"
   fi
   ```

3. **Validate portfolio structure (if path exists):**

   ```bash
   validate_portfolio_structure() {
     local path="$1"

     # Check existence
     if [ ! -e "$path" ]; then
       echo '{"valid": false, "error": "Path does not exist: '"$path"'"}'
       return 1
     fi

     # FILE validation (portfolio mapping file)
     if [ -f "$path" ]; then
       if [[ ! "$path" =~ \.md$ ]]; then
         echo '{"valid": false, "error": "Portfolio file must be markdown (.md)"}'
         return 1
       fi
       if [ ! -s "$path" ]; then
         echo '{"valid": false, "error": "Portfolio file is empty"}'
         return 1
       fi
       echo '{"valid": true, "type": "file", "path": "'"$path"'"}'
       return 0
     fi

     # DIRECTORY validation (portfolio project)
     if [ -d "$path" ]; then
       # REQUIRED: 11-trends directory
       if [ ! -d "$path/11-trends" ]; then
         echo '{"valid": false, "error": "Missing required directory: 11-trends/"}'
         return 1
       fi

       # REQUIRED: At least one portfolio-*.md entity
       local entity_count=$(find "$path/11-trends" -maxdepth 1 -name "portfolio-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
       if [ "$entity_count" -eq 0 ]; then
         echo '{"valid": false, "error": "No portfolio entities found in 11-trends/ (expected portfolio-*.md files)"}'
         return 1
       fi

       # OPTIONAL: Check research_type in sprint-log (warn if wrong type)
       local sprint_log="$path/.metadata/sprint-log.json"
       if [ -f "$sprint_log" ]; then
         local research_type=$(jq -r '.research_type // ""' "$sprint_log" 2>/dev/null)
         if [ "$research_type" != "b2b-ict-portfolio" ]; then
           echo '{"valid": true, "type": "project", "path": "'"$path"'", "entity_count": '"$entity_count"', "warning": "Project research_type is '"$research_type"', expected b2b-ict-portfolio"}'
           return 0
         fi
       fi

       echo '{"valid": true, "type": "project", "path": "'"$path"'", "entity_count": '"$entity_count"'}'
       return 0
     fi

     echo '{"valid": false, "error": "Path is neither file nor directory"}'
     return 1
   }

   # Run validation if portfolio path was found
   if [ -n "$PORTFOLIO_PATH" ]; then
     VALIDATION_RESULT=$(validate_portfolio_structure "$PORTFOLIO_PATH")
     VALIDATION_VALID=$(echo "$VALIDATION_RESULT" | jq -r '.valid')

     if [ "$VALIDATION_VALID" = "true" ]; then
       PORTFOLIO_TYPE=$(echo "$VALIDATION_RESULT" | jq -r '.type')
       PORTFOLIO_ENTITY_COUNT=$(echo "$VALIDATION_RESULT" | jq -r '.entity_count // 0')
       VALIDATION_WARNING=$(echo "$VALIDATION_RESULT" | jq -r '.warning // ""')

       echo "✓ Portfolio validated: $PORTFOLIO_TYPE with $PORTFOLIO_ENTITY_COUNT entities"
       if [ -n "$VALIDATION_WARNING" ]; then
         echo "⚠️ Warning: $VALIDATION_WARNING"
       fi

       PORTFOLIO_PROJECT_PATH="$PORTFOLIO_PATH"
       PORTFOLIO_PROJECT_SLUG=$(basename "$PORTFOLIO_PATH")
       PORTFOLIO_INTEGRATION_ENABLED=true
       PORTFOLIO_NEEDS_PROMPT=false
     else
       VALIDATION_ERROR=$(echo "$VALIDATION_RESULT" | jq -r '.error')
       echo "✗ Portfolio validation failed: $VALIDATION_ERROR"
       PORTFOLIO_NEEDS_PROMPT=true
       PORTFOLIO_VALIDATION_FAILED=true
       PORTFOLIO_FAILED_PATH="$PORTFOLIO_PATH"
       PORTFOLIO_FAILED_ERROR="$VALIDATION_ERROR"
     fi
   else
     PORTFOLIO_NEEDS_PROMPT=true
     PORTFOLIO_VALIDATION_FAILED=false
   fi
   ```

**Mark Step 0.7.1 todo as completed** before proceeding to Step 0.7.2.

---

### Step 0.7.2: Prompt for Portfolio Connection (if missing or invalid)

**⛔ CONDITIONAL:** Only execute if `PORTFOLIO_NEEDS_PROMPT=true` from Step 0.7.1.

**IF `PORTFOLIO_NEEDS_PROMPT=false`:** Skip to Step 1 (portfolio already validated).

**Scenario A: No portfolio was connected during deeper-research-1**

<user_interaction>
MESSAGE: "No portfolio connected for this research project.

Portfolio integration enables:
- B2B ICT dimension bridge in trends
- Technology Enablement tables with specific offerings
- Portfolio-linked solution references

Would you like to connect a portfolio now?

Options:
1. Yes - provide portfolio path
2. No - continue without portfolio integration
3. Discover available portfolio projects"
USE: AskUserQuestion
</user_interaction>

**Scenario B: Portfolio was connected but validation failed**

<user_interaction>
MESSAGE: "Portfolio validation failed: {PORTFOLIO_FAILED_ERROR}

The portfolio path '{PORTFOLIO_FAILED_PATH}' from deeper-research-1 is no longer valid.

Options:
1. Provide updated portfolio path
2. Continue without portfolio integration
3. Discover available portfolio projects"
USE: AskUserQuestion
</user_interaction>

**Handle user response:**

- **Option 1 (Yes / Provide path):** Proceed to path collection below
- **Option 2 (No / Continue without):** Set `PORTFOLIO_INTEGRATION_ENABLED=false`, skip to Step 1
- **Option 3 (Discover):** Run discovery, show available projects, re-prompt

**Path collection (if Option 1):**

<user_interaction>
MESSAGE: "Enter the portfolio path:

- For portfolio project: /path/to/portfolio-project-name
  (must contain 11-trends/ with portfolio-*.md files)
- For portfolio mapping file: /path/to/company-portfolio.md

Enter path or 'cancel' to continue without portfolio:"
USE: AskUserQuestion
</user_interaction>

**Discovery (if Option 3):**

```bash
# Discover available portfolio projects
if [ -n "${COGNI_RESEARCH_ROOT:-}" ]; then
  SEARCH_ROOT="${COGNI_RESEARCH_ROOT}"
elif [ -n "${project_path:-}" ]; then
  SEARCH_ROOT="$(dirname "$project_path")"
else
  SEARCH_ROOT="${HOME}"
fi

echo "Searching for b2b-ict-portfolio projects in: $SEARCH_ROOT"

# Find b2b-ict-portfolio projects with completed trends
find "$SEARCH_ROOT" -maxdepth 3 -path "*/.metadata/sprint-log.json" -type f 2>/dev/null | while read sprint_log; do
  research_type=$(jq -r '.research_type // ""' "$sprint_log" 2>/dev/null)
  if [ "$research_type" = "b2b-ict-portfolio" ]; then
    proj_path=$(dirname "$(dirname "$sprint_log")")
    proj_name=$(basename "$proj_path")
    trend_count=$(find "$proj_path/11-trends" -maxdepth 1 -name "portfolio-*.md" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$trend_count" -gt 0 ]; then
      echo "- $proj_name ($trend_count portfolio entities)"
      echo "  Path: $proj_path"
    fi
  fi
done
```

<user_interaction>
MESSAGE: "Available portfolio projects:

{discovered_projects_list}

Enter project path, or:
- 'none' to continue without portfolio
- 'refresh' to search again"
USE: AskUserQuestion
</user_interaction>

**Store user input:**

```bash
USER_PORTFOLIO_INPUT="{response from AskUserQuestion}"

if [ "$USER_PORTFOLIO_INPUT" = "none" ] || [ "$USER_PORTFOLIO_INPUT" = "cancel" ]; then
  PORTFOLIO_PROJECT_PATH=""
  PORTFOLIO_PROJECT_SLUG=""
  PORTFOLIO_INTEGRATION_ENABLED=false
  echo "INFO: Proceeding without portfolio integration"
  # Skip to Step 1
else
  PORTFOLIO_PATH="$USER_PORTFOLIO_INPUT"
  # Proceed to Step 0.7.3 for validation
fi
```

**Mark Step 0.7.2 todo as completed** before proceeding to Step 0.7.3.

---

### Step 0.7.3: Validate User-Provided Path

**⛔ CONDITIONAL:** Only execute if user provided a path in Step 0.7.2.

**Re-use validation function from Step 0.7.1:**

```bash
VALIDATION_RESULT=$(validate_portfolio_structure "$PORTFOLIO_PATH")
VALIDATION_VALID=$(echo "$VALIDATION_RESULT" | jq -r '.valid')

if [ "$VALIDATION_VALID" = "true" ]; then
  PORTFOLIO_TYPE=$(echo "$VALIDATION_RESULT" | jq -r '.type')
  PORTFOLIO_ENTITY_COUNT=$(echo "$VALIDATION_RESULT" | jq -r '.entity_count // 0')

  echo "✓ Portfolio validated: $PORTFOLIO_TYPE"
  if [ "$PORTFOLIO_TYPE" = "project" ]; then
    echo "  Found $PORTFOLIO_ENTITY_COUNT portfolio entities"
  fi

  PORTFOLIO_PROJECT_PATH="$PORTFOLIO_PATH"
  PORTFOLIO_PROJECT_SLUG=$(basename "$PORTFOLIO_PATH")
  PORTFOLIO_INTEGRATION_ENABLED=true
  # Proceed to Step 0.7.4
else
  VALIDATION_ERROR=$(echo "$VALIDATION_RESULT" | jq -r '.error')
  echo "✗ Validation failed: $VALIDATION_ERROR"
  # Return to Step 0.7.2 with error message
fi
```

**IF validation fails:** Return to Step 0.7.2 and re-prompt with error message.

**Mark Step 0.7.3 todo as completed** before proceeding to Step 0.7.4.

---

### Step 0.7.4: Persist Portfolio Connection

**⛔ CONDITIONAL:** Only execute if `PORTFOLIO_INTEGRATION_ENABLED=true` from Step 0.7.3.

**Update both metadata stores for consistency with deeper-research-1:**

```bash
# 1. Update sprint-log.json
jq --arg path "$PORTFOLIO_PROJECT_PATH" \
   '.portfolio_file_path = $path | .portfolio_integration_enabled = true' \
   "${project_path}/.metadata/sprint-log.json" > /tmp/sprint-updated.json
mv /tmp/sprint-updated.json "${project_path}/.metadata/sprint-log.json"
echo "✓ Updated sprint-log.json with portfolio_file_path"

# 2. Update question entity frontmatter
QUESTION_FILE=$(ls "${project_path}/00-initial-question/data/question-*.md" 2>/dev/null | head -1)

if [ -n "$QUESTION_FILE" ]; then
  # Determine linked_portfolio value format
  if [ -d "$PORTFOLIO_PROJECT_PATH" ]; then
    # Directory: use wikilink format
    LINKED_VALUE="[[$(basename "$PORTFOLIO_PROJECT_PATH")]]"
  else
    # File: use absolute path
    LINKED_VALUE="$PORTFOLIO_PROJECT_PATH"
  fi

  # Check if linked_portfolio field already exists in frontmatter
  if grep -q "^linked_portfolio:" "$QUESTION_FILE"; then
    # Update existing field (macOS sed syntax)
    sed -i '' "s|^linked_portfolio:.*|linked_portfolio: \"${LINKED_VALUE}\"|" "$QUESTION_FILE"
    echo "✓ Updated existing linked_portfolio in question entity"
  else
    # Add new field after research_type line
    sed -i '' "/^research_type:/a\\
linked_portfolio: \"${LINKED_VALUE}\"
" "$QUESTION_FILE"
    echo "✓ Added linked_portfolio to question entity frontmatter"
  fi
fi
```

**Store variables for Step 1:**

```text
PORTFOLIO_PROJECT_PATH = "{absolute path}"
PORTFOLIO_PROJECT_SLUG = "{directory name or filename}"
PORTFOLIO_INTEGRATION_ENABLED = true
PORTFOLIO_ENTITIES_COUNT = {count} (for project type)
```

**Mark Step 0.7.4 todo as completed** before proceeding to Step 1.

---

### Step 0.7 Summary

**Output variables for Step 1:**

| Variable | Description | Example |
|----------|-------------|---------|
| `PORTFOLIO_PROJECT_PATH` | Absolute path to portfolio | `/research/telekom-portfolio` or `""` |
| `PORTFOLIO_PROJECT_SLUG` | Directory/file name for wikilinks | `telekom-portfolio` or `""` |
| `PORTFOLIO_INTEGRATION_ENABLED` | Whether to include portfolio in agent prompts | `true` or `false` |
| `PORTFOLIO_ENTITIES_COUNT` | Number of portfolio entities (project type only) | `8` or `0` |

**Impact on Step 1:** If `PORTFOLIO_INTEGRATION_ENABLED=true`, include BOTH `portfolio_project_path` (for file reading) AND `portfolio_project_slug` (for wikilinks) in the agent prompt.

---

## Step 1: Invoke Trends-Creator Agents (PARALLEL)

**⚠️ CRITICAL:** Invoke one trends-creator agent per dimension. ALL Task invocations MUST be in a SINGLE message for parallel execution.

**Agent Configuration:**

- Agent: trends-creator
- Input per agent: `{"PROJECT_PATH": "{project_path}", "DIMENSION": "{dimension_slug}", "PORTFOLIO_PROJECT_PATH": "{portfolio_path or empty}", "PORTFOLIO_PROJECT_SLUG": "{portfolio_slug or empty}"}`
- Expected output per agent: JSON with dimension-specific metrics

**Parallel Invocation Pattern (SINGLE MESSAGE with ALL Task calls):**

```python
# For N dimensions, invoke ALL in single message:
# Include PORTFOLIO_PROJECT_PATH and PORTFOLIO_PROJECT_SLUG if set in Step 0.7

# Without portfolio:
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at {project_path} for dimension: {dimension_slug_1}. Language: {project_language}",
  description="Creating trends for {dimension_slug_1}"
)

# With portfolio (when PORTFOLIO_PROJECT_PATH is set):
# IMPORTANT: Pass both path (for file reading) AND slug (for wikilinks)
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at {project_path} for dimension: {dimension_slug_1}. Language: {project_language}. Portfolio project path: {portfolio_project_path}. Portfolio project slug: {portfolio_project_slug}",
  description="Creating trends for {dimension_slug_1}"
)
# ... one Task per dimension
```

**Example with 4 dimensions (with portfolio linked):**

```python
# If PORTFOLIO_PROJECT_PATH="/research/telekom-portfolio" and PORTFOLIO_PROJECT_SLUG="telekom-portfolio" from Step 0.7:
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at /path/to/project for dimension: externe-effekte. Language: de. Portfolio project path: /research/telekom-portfolio. Portfolio project slug: telekom-portfolio",
  description="Creating trends for externe-effekte"
)
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at /path/to/project for dimension: neue-horizonte. Language: de. Portfolio project path: /research/telekom-portfolio. Portfolio project slug: telekom-portfolio",
  description="Creating trends for neue-horizonte"
)
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at /path/to/project for dimension: digitale-wertetreiber. Language: de. Portfolio project path: /research/telekom-portfolio. Portfolio project slug: telekom-portfolio",
  description="Creating trends for digitale-wertetreiber"
)
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at /path/to/project for dimension: digitales-fundament. Language: de. Portfolio project path: /research/telekom-portfolio. Portfolio project slug: telekom-portfolio",
  description="Creating trends for digitales-fundament"
)
```

**Example without portfolio (standalone research):**

```python
# If PORTFOLIO_PROJECT_PATH="" from Step 0.7:
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at /path/to/project for dimension: externe-effekte. Language: de",
  description="Creating trends for externe-effekte"
)
# ... etc
```

**Performance:** N× faster than sequential (limited by slowest dimension).

### Response Aggregation

After all agents complete, aggregate metrics:

```text
total_trends = sum(agent.trends_created for each agent)
total_citations = sum(agent.total_citations for each agent)
findings_coverage = "{total_referenced}/{total_findings}"
```

### Validate Response

- Expect JSON response with `success: true` from each agent
- Trends directory exists: `test -d {project_path}/11-trends/data/`
- Trend files created: `find {project_path}/11-trends/data -maxdepth 1 -type f -name "*.md" 2>/dev/null | xargs -I {} basename {} 2>/dev/null | grep -E "^(trend|portfolio)-.*\.md$" | wc -l` returns > 0
- IF any agent fails: Abort Phase 8 with error

**Mark Step 1 todo as completed** before proceeding to Step 2.

---

## Step 2: Validate Trend Files Exist

**⚠️ CRITICAL: Validate Trends Directory Contains Files**

After trends-creator agents complete, validate that trend files were created:

```bash
# Check trends directory exists
if [ ! -d "11-trends" ]; then
  echo "ERROR: 11-trends/data/ directory not created" >&2
  echo "  trends-creator agent may have failed" >&2
  exit 1
fi

# Count trend/portfolio entity files (type depends on research_type)
trend_count=$(find 11-trends/data -maxdepth 1 -type f -name "*.md" 2>/dev/null | xargs -I {} basename {} 2>/dev/null | grep -E "^(trend|portfolio)-.*\.md$" | wc -l)

if [ "$trend_count" -eq 0 ]; then
  echo "ERROR: No trend files found in 11-trends/data/" >&2
  echo "  trends-creator agent may have failed or found no trends" >&2
  exit 1
fi

echo "Found $trend_count trend files in 11-trends/data/"
```

This validation prevents silent failures where trend files are not created.

**Mark Step 2 todo as completed** before proceeding to Step 3.

---

## Step 3: Report Completion and Mark Phase Complete

### Report Completion

```text
✓ Phase 8: Generated {trends_created} trends with {total_citations} citations (coverage: {findings_coverage})

Trends created in 11-trends/data/:
{for each trend file:}
- trend-{theme-slug}.md
{end for}
```

**Example output:**

```text
✓ Phase 8: Generated 52 trends with 260 citations (coverage: 52/52 findings)

Trends created in 11-trends/data/:
- trend-externe-effekte-*.md (13 files: 5 ACT + 5 PLAN + 3 OBSERVE)
- trend-neue-horizonte-*.md (13 files: 5 ACT + 5 PLAN + 3 OBSERVE)
- trend-digitale-wertetreiber-*.md (13 files: 5 ACT + 5 PLAN + 3 OBSERVE)
- trend-digitales-fundament-*.md (13 files: 5 ACT + 5 PLAN + 3 OBSERVE)
```

### Self-Verification Before Completion

**Verify all steps completed:**

1. Did you run the phase entry verification gate (ls command)? ✅ YES / ❌ NO
2. Did you extract dimension list from 01-research-dimensions/data/? ✅ YES / ❌ NO
3. Did you check if research type supports portfolio (Step 0.7.0)? ✅ YES / ❌ NO
4. If portfolio was already connected, did you validate its structure (Step 0.7.1)? ✅ YES / ❌ NO / N/A
5. If validation failed or portfolio missing, did you prompt user (Step 0.7.2)? ✅ YES / ❌ NO / N/A
6. If user provided path, did you validate it (Step 0.7.3)? ✅ YES / ❌ NO / N/A
7. If user connected portfolio, did you persist to sprint-log AND question entity (Step 0.7.4)? ✅ YES / ❌ NO / N/A
8. Did you invoke trends-creator agents? ✅ YES / ❌ NO
9. Did you invoke ALL agents in a SINGLE message? ✅ YES / ❌ NO
10. Did you include portfolio path in agent prompts (if connected)? ✅ YES / ❌ NO / N/A
11. Did you validate trend files exist in 11-trends/data/? ✅ YES / ❌ NO
12. Did you aggregate metrics from all agent responses? ✅ YES / ❌ NO
13. Did you report completion with trends count and coverage? ✅ YES / ❌ NO
14. Do trend files exist in 11-trends/data/? ✅ YES / ❌ NO

⛔ **IF ANY NO: STOP.** Return to incomplete step before proceeding.

### Mark Phase 8 Complete

- Update TodoWrite: Phase 8 → completed, Phase 9 → in_progress
- Update sprint metadata: `current_phase → "phase-9"`

**Mark Step 3 todo as completed** before proceeding to Phase 9.

---

## Phase 8 Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 9

Before marking Phase 8 complete in TodoWrite, verify:

- [ ] Phase entry verification gate passed (TodoWrite check + ls command)
- [ ] Dimension list extracted from 01-research-dimensions/data/
- [ ] Research type checked for portfolio support (Step 0.7.0)
- [ ] Existing portfolio validated for correct structure (Step 0.7.1) OR N/A
- [ ] User prompted if portfolio missing/invalid (Step 0.7.2) OR N/A
- [ ] User-provided path validated (Step 0.7.3) OR N/A
- [ ] Portfolio connection persisted to sprint-log.json AND question entity (Step 0.7.4) OR N/A
- [ ] Trends-creator agents invoked successfully (one per dimension)
- [ ] ALL agents invoked in SINGLE message for parallel execution
- [ ] Portfolio path included in agent prompts (if connected)
- [ ] Trend files validated to exist in 11-trends/data/
- [ ] Metrics aggregated from all agent responses
- [ ] Completion report generated with trends count and coverage
- [ ] All step-level todos marked as completed
- [ ] All self-verification questions answered YES
- [ ] Phase 8 todo marked completed in TodoWrite
