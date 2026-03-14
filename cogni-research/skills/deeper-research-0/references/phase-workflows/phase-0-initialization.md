# Phase 0: Project Initialization

<objective>
Initialize research project: normalize names, prevent duplicates, select research type, create project structure. Research-type-specific inputs (dimensions, portfolio, DOK) are collected in Phase 1.
</objective>

<constraints>
- MUST normalize via generate-semantic-slug.sh
- MUST check existing/similar projects pre-creation
- MUST detect user-specified research_type before prompting
- MUST persist research_type to sprint-log.json
- MUST use AskUserQuestion (never assume defaults)
- Research-type-specific inputs (dimensions, portfolio, DOK) are collected in Phase 1
</constraints>

---

## CRITICAL: Script Path Variables

**ALL scripts are in the PLUGIN directory, NOT the research workspace:**

- **CORRECT:** `${CLAUDE_PLUGIN_ROOT}/scripts/` - Plugin code directory (contains all bash scripts)
- **WRONG:** `${COGNI_RESEARCH_ROOT}/...` - This is the research WORKSPACE (project data only, NO scripts)

**The research workspace (`COGNI_RESEARCH_ROOT`) contains NO scripts.** Scripts live exclusively in `${CLAUDE_PLUGIN_ROOT}/scripts/`.

---

## Step 0.1: Initialize TodoWrite

```markdown
USE: TodoWrite
ADD todos:
- Phase 0, Step 1: Parse question, extract topic [in_progress]
- Phase 0, Step 2: Normalize project name [pending]
- Phase 0, Step 3: Check existing/similar projects [pending]
- Phase 0, Step 4: Detect/select research type [pending]
- Phase 0, Step 5: Persist research type [pending]
- Phase 0, Step 6: Initialize project [pending]
```

---

## Step 1: Parse Question & Extract Topic

Extract primary keywords/topic for project naming.

**Examples:**
| Question | Topic |
|----------|-------|
| "Innovation trends German machinery 2026-2031?" | "Innovationstrends Deutscher Maschinenbau 2026-2031" |
| "AI applications healthcare" | "AI Applications Healthcare" |

Mark Step 1 complete.

---

## Step 2: Normalize Project Name

Convert to filesystem-safe kebab-case.

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" \
  --title "{topic}" --content-key "{topic}" --max-length 60 --json > /tmp/slug.json

normalized_project_name=$(jq -r '.data.slug' /tmp/slug.json)
if [ -z "$normalized_project_name" ] || [ "$normalized_project_name" = "null" ]; then exit 1; fi
```

**Rules:** lowercase, spaces→hyphens, umlaut transliteration, 60 char limit

Mark Step 2 complete.

---

## Step 3: Check Existing/Similar Projects

```bash
# Define deeper-research-0 project root
# Priority: COGNI_RESEARCH_ROOT > CLAUDE_PROJECT_DIR > ~/research-projects
if [ -n "${COGNI_RESEARCH_ROOT:-}" ]; then
    DEEPER_ROOT="${COGNI_RESEARCH_ROOT}/deeper"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    DEEPER_ROOT="${CLAUDE_PROJECT_DIR}/deeper"
else
    DEEPER_ROOT="${HOME}/research-projects/deeper"
fi
mkdir -p "$DEEPER_ROOT"

bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-project-existence.sh" \
  --project-name "{topic}" --base-dir "$DEEPER_ROOT" --json > /tmp/check.json

exists=$(jq -r '.data.exists' /tmp/check.json)
existing_path=$(jq -r '.data.existing_path' /tmp/check.json)
similar_projects=$(jq -r '.data.similar_projects[]' /tmp/check.json 2>/dev/null)
```

### Decision Tree

**A) Exact Match** (`exists == true`)
<user_interaction>
ASK: "Project exists at {path}. Options: 1) Resume (continue from last phase), 2) Choose different name"
USE: AskUserQuestion
</user_interaction>

**Resume:** Load state, exit Phase 0, proceed to last_phase
**Different name:** Return to Step 1

**B) Similar Projects** (`exists == false`, `similar_projects.length > 0`)
<user_interaction>
WARN: "Similar projects: {list}. Options: 1) Continue, 2) Resume similar, 3) Different name"
USE: AskUserQuestion
</user_interaction>

**C) No Conflicts**
Proceed to Step 4.

Mark Step 3 complete.

---

## Step 4: Detect/Select Research Type

### 4.1: Detect User-Specified Type

```bash
USER_SPECIFIED_TYPE=""
case "$USER_QUESTION" in
  *smarter-service*) USER_SPECIFIED_TYPE="smarter-service" ;;
  *lean-canvas*) USER_SPECIFIED_TYPE="lean-canvas" ;;
  *customer-value-mapping*|*value*mapping*) USER_SPECIFIED_TYPE="customer-value-mapping" ;;
esac
```

If detected: `SELECTED_TYPE="$USER_SPECIFIED_TYPE"`, skip to Step 5

### 4.2: Ask User (if not auto-detected)

<condition>ONLY if no user-specified type detected</condition>

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/discover-research-templates.sh" \
  --json > /tmp/templates.json
TEMPLATE_LIST=$(jq -r '.templates[] | "- " + .name + ": " + .description' /tmp/templates.json)
```

<user_interaction>
MESSAGE: "Available templates:\n${TEMPLATE_LIST}\n\nWhich template? (If uncertain, use 'generic')"
USE: AskUserQuestion
</user_interaction>

```bash
SELECTED_TYPE="${USER_RESPONSE}"
# Validate against discovered templates
jq -e --arg type "$SELECTED_TYPE" '.templates[] | select(.name == $type)' /tmp/templates.json || exit 1
```

### 4.3: Detect/Set Project Language

```bash
# Detect project language from question text
if [ -z "${PROJECT_LANGUAGE:-}" ] || [ "$PROJECT_LANGUAGE" = "en" ]; then
  # Detect German indicators: umlauts, common German words
  if echo "$USER_QUESTION" | grep -qiE '(ä|ö|ü|ß|welche|welcher|wie|werden|für|und|oder|nicht|sind|wird|kann|können|sollen|haben|Deutschland|deutschen|deutsche)'; then
    PROJECT_LANGUAGE="de"
    log_conditional "INFO" "Detected German language from question text"
  else
    PROJECT_LANGUAGE="en"
  fi
fi
```

Mark Step 4 complete.

---

## Step 5: Confirm Research Type Selection

Research type has been selected (either detected or asked). Proceed to project initialization.

**Note:** The research type will be persisted during project initialization in Step 6 via the `--research-type` parameter. Frontmatter is updated when entity is created in Phase 1.

Mark Step 5 complete.

---

## Step 6: Initialize Project and Persist Research Type

```bash
# Use same deeper-research-0 project root as Step 3
# Priority: COGNI_RESEARCH_ROOT > CLAUDE_PROJECT_DIR > ~/research-projects
if [ -n "${COGNI_RESEARCH_ROOT:-}" ]; then
    DEEPER_ROOT="${COGNI_RESEARCH_ROOT}/deeper"
elif [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    DEEPER_ROOT="${CLAUDE_PROJECT_DIR}/deeper"
else
    DEEPER_ROOT="${HOME}/research-projects/deeper"
fi
mkdir -p "$DEEPER_ROOT"

# Initialize project with research type (persists to sprint-log.json automatically)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/initialize-research-project.sh" \
  --project-name "$normalized_project_name" \
  --projects-root "$DEEPER_ROOT" \
  --research-type "$SELECTED_TYPE" \
  --language "${PROJECT_LANGUAGE:-en}" \
  --json > /tmp/init.json

project_path=$(jq -r '.project_path' /tmp/init.json)
if [ -z "$project_path" ] || [ "$project_path" = "null" ]; then exit 1; fi

# Log the initialization event (now that project exists)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/log-sprint-event.sh" \
  --project-name "$normalized_project_name" \
  --projects-root "$DEEPER_ROOT" \
  --phase "0" \
  --event "research_type_selected" --details "type=$SELECTED_TYPE" --json

echo "✓ Phase 0: Initialized '$project_name' at $project_path (research_type=$SELECTED_TYPE)"

```

Mark Step 6 complete.

---

## Self-Verification

Before Phase 0 complete, ALL must be ✅:

1. Parsed question, extracted topic? ✅/❌
2. Normalized via generate-semantic-slug.sh? ✅/❌
3. Checked existing/similar via check-project-existence.sh? ✅/❌
4. Detected OR asked for research type? ✅/❌
5. Persisted research_type to sprint-log.json? ✅/❌
6. Initialized project, received project_path? ✅/❌
7. Marked all todos complete? ✅/❌

**ANY ❌: STOP. Return to incomplete step.**

---

## Completion Summary

### Required Artifacts

```text
{project-name}/
├── .metadata/sprint-log.json  # research_type, project_language
├── 00-initial-question/       # Empty, populated in Phase 1
└── README.md
```

### Metadata Validation

```json
{
  "project_name": "{name}",
  "research_type": "{type}",
  "project_language": "{en|de}",
  "current_phase": "0"
}
```

### Report

```text
✓ Phase 0 Complete: Project Initialized
Project: {name}
Location: {path}
Research Type: {type}

Ready for Phase 1: Research-Type-Specific Input Collection
```

---

## Reference

**Normalization:**
| Input | Output | Transform |
|-------|--------|-----------|
| "Innovationstrends Deutscher 2026-2031" | `innovationstrends-deutscher-2026-203` | lowercase, spaces→hyphens, truncate@60 |
| "Künstliche Intelligenz" | `kuenstliche-intelligenz` | umlaut→ue |

**Duplicate Prevention:**
| Input | Normalized | Existing | Action |
|-------|-----------|----------|--------|
| "mittelständischer Maschinenbau" | `mittelstaendischer-m` | `mittelstaendlicher-m` | Warn similar |
| "AI trends 2025" (exact) | `ai-trends-2025` | `ai-trends-2025` | Offer resume |
| "quantum computing" | `quantum-computing` | (none) | Create |
