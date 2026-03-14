# Phase 1: Research-Type Input Collection & Question Refinement

<objective>
Load research-type WHAT file, collect all research-type-specific user inputs (including DOK), analyze research question clarity, and create structured entity file with proper frontmatter.
</objective>

<constraints>
- MUST verify Phase 0 artifacts exist before starting
- MUST load research-type WHAT file from `references/research-types/{type}.md`
- MUST collect ALL research-type-specific inputs in Step 1
- MUST use AskUserQuestion (never assume defaults)
- MUST create entity file with all collected metadata in frontmatter
</constraints>

---

## Step 0: Derive project_path (MANDATORY)

**⛔ CRITICAL:** Before any Phase 1 work, derive and validate `project_path`:

```bash
# Derive project_path from sprint-log.json location
sprint_log="$(find . -path "*/.metadata/sprint-log.json" -type f 2>/dev/null | head -1)"
if [ -z "$sprint_log" ]; then echo "ERROR: No sprint-log.json found. Ensure Phase 0 completed." >&2; exit 1; fi
project_path="$(cd "$(dirname "$sprint_log")/.." && pwd)"

# Validate
if [ ! -d "${project_path}/.metadata" ]; then echo "ERROR: Invalid project_path: ${project_path}" >&2; exit 1; fi
echo "project_path: ${project_path}"
```

**Use this `project_path` value in ALL subsequent commands in this phase.**

---

## Phase Entry Verification (MANDATORY)

**Verify Phase 0 artifacts:**

```bash
# Validate project_path is set (prevents empty variable bug)
if [ -z "${project_path:-}" ]; then echo "ERROR: project_path not set. Run Step 0 first." >&2; exit 1; fi
ls -la "${project_path}/.metadata/sprint-log.json"
```

**IF missing:** STOP, return to Phase 0, create artifacts, then resume Phase 1.

---

## Step 0.5: Initialize Phase 1 TodoWrite

```markdown
USE: TodoWrite
ADD todos:
- Phase 1, Step 1: Load WHAT file + collect research-type inputs [in_progress]
- Phase 1, Step 2: Load question analysis methodology [pending]
- Phase 1, Step 3: Perform systematic analysis [pending]
- Phase 1, Step 4: Interactive clarification (if blocking) [pending]
- Phase 1, Step 5: Generate semantic filename [pending]
- Phase 1, Step 6: Create entity file [pending]
- Phase 1, Step 7: Verify file creation [pending]
```

---

## Step 1: Load WHAT File + Collect Research-Type-Specific Inputs

### 1.1: Load Research Type and WHAT File

**⚠️ ZSH COMPATIBILITY:** Execute as **separate Bash tool calls** - never combine multiple `$()` in one call.

```bash
# Bash call 1: Get research type
RESEARCH_TYPE=$(jq -r '.research_type // "generic"' "${project_path}/.metadata/sprint-log.json") && echo "RESEARCH_TYPE=${RESEARCH_TYPE}"
```

```bash
# Bash call 2: Get project language
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${project_path}/.metadata/sprint-log.json") && echo "PROJECT_LANGUAGE=${PROJECT_LANGUAGE}"
```

```bash
# Bash call 3: Load WHAT file (use Read tool instead for file content)
RESEARCH_TYPE_FILE="${CLAUDE_PLUGIN_ROOT}/references/research-types/${RESEARCH_TYPE}.md" && \
  [ -f "$RESEARCH_TYPE_FILE" ] && echo "WHAT file exists: $RESEARCH_TYPE_FILE" || echo "WHAT file not found"
```

**Note:** Use the Read tool to load the WHAT file content, not bash `cat`.

### 1.2: Collect Research-Type-Specific Inputs

Execute the appropriate input collection based on `RESEARCH_TYPE`:

---

#### For b2b-ict-portfolio

> **DEPRECATED:** The b2b-ict-portfolio research type has been migrated to `cogni-portfolio:portfolio-mapping`. Use that skill directly for B2B ICT portfolio analysis.

---

#### For smarter-service

**Read "## Portfolio Integration" section from WHAT file, then ask user:**

**Q1: B2B Research Foundation**

<user_interaction>
MESSAGE: "Build upon existing B2B research project?

Benefits: context-aware trends, reuse trends, continuity

Options:
1. Yes - have relevant B2B research
2. No - start fresh
3. Not sure - show available projects"
USE: AskUserQuestion
</user_interaction>

**If Yes/Not sure:**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/discover-projects.sh" \
  --research-type "b2b-ict-portfolio" --json > /tmp/b2b-projects.json

# Let user select, store in LINKED_B2B_RESEARCH
```

**Q2: Portfolio File Linking**

<user_interaction>
MESSAGE: "Portfolio mapping file path?
Enables linking TIPS trends to B2B ICT solutions.
Enter: absolute path or 'none'"
USE: AskUserQuestion
</user_interaction>

**Persist:**

```bash
if [ "$USER_PORTFOLIO_INPUT" == "none" ]; then
  PORTFOLIO_FILE_PATH=""
  PORTFOLIO_INTEGRATION_ENABLED="false"
else
  PORTFOLIO_FILE_PATH="$USER_PORTFOLIO_INPUT"
  [ ! -f "$PORTFOLIO_FILE_PATH" ] && echo "Warning: File not found (create later)"
  PORTFOLIO_INTEGRATION_ENABLED="true"
fi

jq --arg linked "$LINKED_B2B_RESEARCH" \
   --arg path "$PORTFOLIO_FILE_PATH" \
   --arg enabled "$PORTFOLIO_INTEGRATION_ENABLED" \
   '.linked_b2b_research = $linked | .portfolio_file_path = $path | .portfolio_integration_enabled = ($enabled = "true")' \
   "${project_path}/.metadata/sprint-log.json" > /tmp/updated.json
mv /tmp/updated.json "${project_path}/.metadata/sprint-log.json"
```

**DOK:** Auto-determined as DOK-4 (52 TIPS = extended complexity)

```bash
DOK_LEVEL=4
DOK_RATIONALE="smarter-service: 52 TIPS across 4 dimensions × (5 ACT + 5 PLAN + 3 OBSERVE) (extended complexity)"
```

<user_interaction>
INFORM: "DOK level auto-set to DOK-4 (extended complexity) for smarter-service research type."
</user_interaction>

---

#### For customer-value-mapping

**Read "## Prerequisites" section from WHAT file, then ask user:**

**Q1: Customer Context**

<user_interaction>
MESSAGE: "Customer value mapping requires:

1. **Customer name:** [e.g., Siemens, BMW, Deutsche Telekom]
2. **Customer industry:** [e.g., manufacturing, automotive, telecommunications]"
USE: AskUserQuestion
</user_interaction>

**Q2: Portfolio File**

<user_interaction>
MESSAGE: "Portfolio mapping file path for solution references?
Enter: absolute path or 'none'"
USE: AskUserQuestion
</user_interaction>

**Persist:**

```bash
jq --arg name "$CUSTOMER_NAME" \
   --arg industry "$CUSTOMER_INDUSTRY" \
   --arg path "$PORTFOLIO_FILE_PATH" \
   '.customer_name = $name | .customer_industry = $industry | .portfolio_file_path = $path' \
   "${project_path}/.metadata/sprint-log.json" > /tmp/updated.json
mv /tmp/updated.json "${project_path}/.metadata/sprint-log.json"
```

**DOK:** Auto-determined as DOK-3 (value mapping synthesis = strategic complexity)

```bash
DOK_LEVEL=3
DOK_RATIONALE="customer-value-mapping: 4-dimension value story synthesis (strategic complexity)"
```

<user_interaction>
INFORM: "DOK level auto-set to DOK-3 (strategic complexity) for customer-value-mapping research type."
</user_interaction>

---

#### For lean-canvas

**Read "## Block Definitions" section from WHAT file (9 blocks), then ask user:**

<user_interaction>
MESSAGE: "Business model research context:

1. **Business stage:** Idea / Early-stage / Growth / Mature
2. **Business model:** B2B / B2C / B2B2C
3. **Primary customer segment:** [brief description]"
USE: AskUserQuestion
</user_interaction>

**Persist:**

```bash
jq --arg stage "$BUSINESS_STAGE" \
   --arg model "$BUSINESS_MODEL" \
   --arg segment "$CUSTOMER_SEGMENT" \
   '.business_stage = $stage | .business_model = $model | .customer_segment = $segment' \
   "${project_path}/.metadata/sprint-log.json" > /tmp/updated.json
mv /tmp/updated.json "${project_path}/.metadata/sprint-log.json"
```

**DOK:** Auto-determined as DOK-3 (9 canvas blocks = skills/application level)

```bash
DOK_LEVEL=3
DOK_RATIONALE="lean-canvas: 9 canvas blocks (skills/application level)"
```

<user_interaction>
INFORM: "DOK level auto-set to DOK-3 (strategic complexity) for lean-canvas research type."
</user_interaction>

---

#### For generic

**No dimension/portfolio inputs required.**

**DOK: Must ask user (no auto-determination)**

<user_interaction>
MESSAGE: "What depth of knowledge for this research?

**DOK-1 (Recall):** Facts, definitions, statistics
- 2-3 dimensions, 8-12 questions

**DOK-2 (Skills):** Compare, classify, apply frameworks
- 3-4 dimensions, 15-20 questions

**DOK-3 (Strategic):** Synthesize, analyze patterns
- 5-7 dimensions, 25-35 questions

**DOK-4 (Extended):** Complex synthesis, interdisciplinary
- 8-10 dimensions, 40-50 questions

Enter DOK level (1-4):"
USE: AskUserQuestion
</user_interaction>

**Persist:**

```bash
DOK_LEVEL="${USER_RESPONSE}"
DOK_RATIONALE="User selected DOK-$DOK_LEVEL for generic research"
```

---

### 1.3: Persist DOK Level

```bash
jq --arg dok "$DOK_LEVEL" --arg rationale "$DOK_RATIONALE" \
   '.dok_level = ($dok | tonumber) | .dok_rationale = $rationale' \
   "${project_path}/.metadata/sprint-log.json" > /tmp/sprint-log-updated.json
mv /tmp/sprint-log-updated.json "${project_path}/.metadata/sprint-log.json"
```

Mark Step 1 complete.

---

## Step 2: Load Question Analysis Methodology

Read `references/question-analysis-methodology.md` for systematic analysis framework.

Mark Step 2 complete.

---

## Step 3: Systematic Question Analysis

**In thinking block using `<question_analysis>` tags:**

- **Subject & Terminology:** Primary research area, main terms, ambiguous terminology
- **Explicit Scope:** User-specified boundaries (temporal, geographic, domain)
- **Ambiguity Assessment:** Blocking (≥2 core dimensions vague) vs non-blocking (≤1 dimension unclear)
- **Implicit Assumptions:** What question assumes
- **Refinement Strategy:** Plan clarification without scope expansion

Mark Step 3 complete.

---

## Step 4: Interactive Clarification

<condition>ONLY if blocking ambiguities detected in Step 3</condition>

- Use AskUserQuestion with 1-4 focused questions
- Apply clarification patterns from reference file
- Construct refined question combining original + clarifications
- Preserve user intent, don't expand scope

Mark Step 4 complete.

---

## Step 5: Generate Semantic Filename

```bash
if [ -z "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  echo '{"success": false, "error": "CLAUDE_PLUGIN_ROOT not set"}' >&2
  exit 1
fi

temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-semantic-slug.sh" \
  --title "$refined_question_text" \
  --content-key "$refined_question_text" \
  --max-length 80 \
  --json > "$temp_file"

semantic_uuid=$(jq -r '.data.semantic_uuid' "$temp_file")
filename="question-${semantic_uuid}.md"
```

Mark Step 5 complete.

---

## Step 6: Create Entity File

```bash
mkdir -p "${PROJECT_PATH}/$DIR_INITIAL_QUESTION/$DATA_SUBDIR"

created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Derive semantic title
clean_question=$(echo "$refined_question" | sed 's/[?!.,:;]*$//')
first_clause=$(echo "$clean_question" | sed 's/[,;].*//')
truncated=$(echo "$first_clause" | cut -c1-80 | sed 's/ [^ ]*$//')
question_title=$(echo "$truncated" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')

if [ -z "$question_title" ]; then
  question_title="Research Question"
fi
```

**Write entity file with REQUIRED frontmatter:**

```yaml
---
tags: [question]
dc:creator: "deeper-research-skill"
dc:title: "{brief summary}"
question_title: "{question_title}"
dc:date: "{created_at}"
entity_type: "00-initial-question"
entity_id: "question-{semantic_uuid}"
created_at: "{created_at}"
status: "refined"
research_type: "{RESEARCH_TYPE}"
dok_level: {DOK_LEVEL}
# Research-type-specific fields (include only applicable ones):
linked_b2b_research: "{path}"   # smarter-service only
portfolio_file: "{path}"        # smarter-service/customer-value-mapping
customer_name: "{name}"         # customer-value-mapping only
customer_industry: "{industry}" # customer-value-mapping only
business_stage: "{stage}"       # lean-canvas only
business_model: "{model}"       # lean-canvas only
customer_segment: "{segment}"   # lean-canvas only
dimension_ids: []               # Populated by dimension-planner
---
```

**Content sections:**

- Original question
- Refined question
- Scope boundaries (included/excluded)
- Implicit assumptions
- Dimensional hints
- Open questions for research
- Metadata (refinement method, clarification count, confidence)

Mark Step 6 complete.

---

## Step 7: Verify File Creation

```bash
test -f "${project_path}/00-initial-question/data/$filename" && echo "✓ Entity file created: $filename" || echo "✗ Failed"
```

Mark Step 7 complete.

---

## Self-Verification

Before Phase 1 complete, ALL must be ✅:

1. Phase entry verification gate passed (ls command)? ✅/❌
2. Loaded research-type WHAT file? ✅/❌
3. Collected research-type-specific inputs? ✅/N/A
   - smarter-service: B2B research + portfolio questions? ✅/❌
   - customer-value-mapping: Customer name/industry + portfolio? ✅/❌
   - lean-canvas: Business stage/model/segment? ✅/❌
   - generic: (N/A)
4. Determined DOK level (auto or asked)? ✅/❌
5. DOK level persisted to sprint-log.json? ✅/❌
6. Read question-analysis-methodology.md? ✅/❌
7. Performed systematic analysis with `<question_analysis>`? ✅/❌
8. Interactive clarification if blocking ambiguities? ✅/N/A
9. Generated semantic filename via script? ✅/❌
10. Created entity file with ALL frontmatter fields? ✅/❌
11. Verified file creation? ✅/❌
12. All step-level todos completed? ✅/❌

**ANY ❌ (excluding N/A): STOP. Return to incomplete step.**

---

## Phase 1 Completion

Report: `✓ Phase 1: Question refined at 00-initial-question/data/{filename}`

Update TodoWrite: Phase 1 → completed, Phase 2 → in_progress

---

## Phase Completion Checklist

### MANDATORY before Phase 2

- [ ] Phase entry gate passed (ls command)
- [ ] Research-type WHAT file loaded
- [ ] Research-type-specific inputs collected (Step 1)
- [ ] DOK level determined and persisted
- [ ] question-analysis-methodology.md read
- [ ] Systematic analysis with `<question_analysis>`
- [ ] Interactive clarification (if blocking ambiguities)
- [ ] Semantic filename via script
- [ ] Entity file with REQUIRED frontmatter
- [ ] File creation verified
- [ ] All step-level todos completed
- [ ] Phase 1 todo marked completed in TodoWrite
