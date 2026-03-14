---
name: evidence-synthesizer
description: "[Internal] Build navigable evidence catalogs from sources, citations, and institutions. Invoked by deeper-research-3."
---

# Evidence Synthesizer

---

## ⛔ INVOCATION GUARD - READ BEFORE PROCEEDING

**This is an EXECUTOR skill. It should NOT be invoked directly.**

### Correct Invocation Path

```text
User → deeper-research-3 skill (ORCHESTRATOR)
       └→ Phase 9: Task tool → evidence-synthesizer AGENT → this skill
```

### If You Are Reading This Directly

**STOP.** You likely invoked this skill directly via `Skill(skill="cogni-research:evidence-synthesizer")`.

**What to do instead:**

1. Use the `deeper-research-3` skill instead:

   ```text
   Skill(skill="cogni-research:deeper-research-3")
   ```

2. The orchestrator will invoke this skill at the correct phase with proper context.

**Why this matters:** Direct invocation bypasses phase gates and trend generation prerequisites. Evidence synthesis requires trends (Phase 8) and dimension syntheses (Phase 8.5) to exist first.

---

Transform research sources, citations, and institutions into comprehensive navigable catalogs with tier distribution analysis and institutional authority mapping.

## Prerequisites

**Required entities (Phases 1-7 complete):**
- Sources in `07-sources/data/`
- Publishers in `08-publishers/data/`
- Citations in `09-citations/data/`
- Institutions in `12-institutions/` (optional)

**Outputs:**
- `09-citations/README.md`
- Tier distribution analysis (T1/T2/T3 percentages)
- Institutional authority mapping (Academic/Multilateral/Government/Industry)

## Core Workflow

Execute phases sequentially using TodoWrite to track progress.

### Phase 1: Parameter Validation

**Step 1.0: Initialize Phase TodoWrite**

Add phase-level todos:

```markdown
USE: TodoWrite tool
ADD todos:
- Phase 1: Parameter Validation [in_progress]
- Phase 2: Environment Validation [pending]
- Phase 3: Template Loading [pending]
- Phase 4: Complete Entity Loading [pending]
- Phase 5: Catalog Generation [pending]
- Phase 6: Output & Return [pending]
```

**Step 1.1: Parse Parameters**

**Required Parameters:**
- `--project-path`: Research project directory (required)
- `--language`: Output language, ISO 639-1 code (default: en)

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 1 for parameter parsing.

**Mark Phase 1 todo as completed** before proceeding to Phase 2.

---

### Phase 2: Environment Validation

**Step 2.0: Update TodoWrite**

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 1: Parameter Validation [completed]
- Phase 2: Environment Validation [in_progress]
```

**Step 2.1: Validate Working Directory**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-working-directory.sh" \
    --project-path "$PROJECT_PATH" --json
```

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Sections 2-3 for validation and logging.

**Mark Phase 2 todo as completed** before proceeding to Phase 3.

---

### Phase 3: Template Loading

**Step 3.0: Update TodoWrite**

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 2: Environment Validation [completed]
- Phase 3: Template Loading [in_progress]
```

**Step 3.1: Initialize Step-Level TodoWrite**

Add step-level todos for Phase 3:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 3, Step 3.2: Read template-loading reference [pending]
- Phase 3, Step 3.3: Load sprint-log.json metadata [pending]
- Phase 3, Step 3.4: Extract research_type [pending]
- Phase 3, Step 3.5: Load template structure [pending]
```

**Step 3.2: Read Template Loading Reference**

⛔ **MANDATORY:** Read the template loading reference to understand template discovery logic:

```markdown
USE: Read tool
FILE: references/template-loading.md
```

**Mark Step 3.2 todo as completed** before proceeding to Step 3.3.

**Step 3.3: Load Sprint Log Metadata**

1. Read `{{PROJECT_PATH}}/.metadata/sprint-log.json`
2. Extract `research_type` (default: "generic")
3. Load template structure for catalog organization

**Mark Phase 3 todo as completed** before proceeding to Phase 4.

---

### Phase 4: Complete Entity Loading

**Step 4.0: Update TodoWrite**

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 3: Template Loading [completed]
- Phase 4: Complete Entity Loading [in_progress]
```

**Step 4.1: Initialize Step-Level TodoWrite**

Add step-level todos for Phase 4:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 4, Step 4.2: Read entity-processing reference [pending]
- Phase 4, Step 4.3: Count entity files [pending]
- Phase 4, Step 4.4: Load all source entities [pending]
- Phase 4, Step 4.5: Load all citation entities [pending]
- Phase 4, Step 4.6: Load all institution entities [pending]
```

**Step 4.2: Read Entity Processing Reference**

⛔ **MANDATORY:** Read the entity processing reference to understand complete loading patterns:

```markdown
USE: Read tool
FILE: references/entity-processing.md
```

Also read anti-hallucination foundations:

```markdown
USE: Read tool
FILE: ../../references/anti-hallucination-foundations.md
```

**Mark Step 4.2 todo as completed** before proceeding to Step 4.3.

**Step 4.3: Count Entity Files**

**CRITICAL: Complete reading prevents hallucination. No truncation allowed.**

```bash
SOURCE_COUNT=$(find "${PROJECT_PATH}/07-sources" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
CITATION_COUNT=$(find "${PROJECT_PATH}/09-citations" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
INST_COUNT=$(find "${PROJECT_PATH}/12-institutions" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
```

**Step 4.4: Load Entity Files Completely**

Use Read tool for EACH entity file completely (no line limits):

- Read all files in `07-sources/data/` (no truncation)
- Read all files in `09-citations/data/` (no truncation)
- Read all files in `12-institutions/` (no truncation)

**Mark Phase 4 todo as completed** before proceeding to Phase 5.

---

### Phase 5: Catalog Generation

**Step 5.0: Update TodoWrite**

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 4: Complete Entity Loading [completed]
- Phase 5: Catalog Generation [in_progress]
```

**Step 5.1: Initialize Step-Level TodoWrite**

Add step-level todos for Phase 5:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 5, Step 5.2: Read tier-classification reference [pending]
- Phase 5, Step 5.3: Calculate tier distribution [pending]
- Phase 5, Step 5.4: Read institutional-authority reference [pending]
- Phase 5, Step 5.5: Map institutional authority [pending]
- Phase 5, Step 5.6: Read catalog-structure reference [pending]
- Phase 5, Step 5.7: Assemble catalog [pending]
- Phase 5, Step 5.8: Anti-hallucination verification [pending]
```

**Step 5.2: Read Tier Classification Reference**

⛔ **MANDATORY:** Read the tier classification reference to understand tier scoring:

```markdown
USE: Read tool
FILE: references/tier-classification.md
```

**Mark Step 5.2 todo as completed** before proceeding to Step 5.3.

**Step 5.3: Calculate Tier Distribution**

Count sources per tier, calculate percentages.

**Mark Step 5.3 todo as completed** before proceeding to Step 5.4.

**Step 5.4: Read Institutional Authority Reference**

⛔ **MANDATORY:** Read the institutional authority reference to understand classification:

```markdown
USE: Read tool
FILE: references/institutional-authority.md
```

**Mark Step 5.4 todo as completed** before proceeding to Step 5.5.

**Step 5.5: Map Institutional Authority**

Classify into: Academic, Multilateral, Government, Industry.

**Mark Step 5.5 todo as completed** before proceeding to Step 5.6.

**Step 5.6: Read Catalog Structure Reference**

⛔ **MANDATORY:** Read the catalog structure reference to understand output format:

```markdown
USE: Read tool
FILE: references/catalog-structure.md
```

**Mark Step 5.6 todo as completed** before proceeding to Step 5.7.

**Step 5.7: Assemble Catalog**

1. YAML frontmatter with Dublin Core metadata:
   - `schema_version`: "3.0"
   - `entity_type`: "evidence-synthesis"
   - `tags`: `[evidence-synthesis, synthesis-level/evidence, {{LANGUAGE}}]`
   - `dc:creator`: "Claude (evidence-synthesizer)"
   - `dc:title`: "Evidence Catalog: Sources and Citations"
   - `dc:created`: ISO-8601 timestamp
   - `dc:identifier`: "synthesis-evidence"
   - All counts (sources, citations, institutions, tiers, word_count)
2. Executive summary
3. Source reliability distribution table
4. Sources grouped by domain
5. Institutional authority mapping
6. Complete source catalog (alphabetical)
7. Citation index (APA bibliography)

**Mark Step 5.7 todo as completed** before proceeding to Step 5.8.

**Step 5.8: Anti-Hallucination Verification**

Before writing, verify all URLs, titles, institution names, and citations match loaded entity content exactly.

**Mark Phase 5 todo as completed** before proceeding to Phase 6.

---

### Phase 6: Output & Return

**Step 6.0: Update TodoWrite**

```markdown
USE: TodoWrite tool
UPDATE:
- Phase 5: Catalog Generation [completed]
- Phase 6: Output & Return [in_progress]
```

**Step 6.1: Initialize Step-Level TodoWrite**

Add step-level todos for Phase 6:

```markdown
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 6, Step 6.2: Write catalog file [pending]
- Phase 6, Step 6.3: Template validation (optional) [pending]
- Phase 6, Step 6.4: Return JSON summary [pending]
- Phase 6, Step 6.5: Return concise summary [pending]
```

**Step 6.2: Write Catalog**

```bash
mkdir -p "${PROJECT_PATH}/09-citations"
OUTPUT_FILE="${PROJECT_PATH}/09-citations/README.md"
```

**Mark Step 6.2 todo as completed** before proceeding to Step 6.3.

**Step 6.3: Template Validation (Optional)**

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/evidence-synthesizer/scripts/validate-template-adherence.sh" \
    --project-path "${PROJECT_PATH}" --research-type "${research_type}" \
    --document-type "evidence" --json
```

**Mark Step 6.3 todo as completed** before proceeding to Step 6.4.

**Step 6.4: Return JSON Summary**

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 4 for JSON construction.

**Mark Step 6.4 todo as completed** before proceeding to Step 6.5.

**Step 6.5: Concise Summary**

Return ONLY (5 lines max, start with ✅):

```
✅ Evidence catalog generation complete.
- Sources cataloged: {count} (T1: {tier1}, T2: {tier2}, T3: {tier3})
- Citations formatted: {count}
- Institutions mapped: {count} ({academic} academic, {multilateral} multilateral, {government} government, {industry} industry)
- Output: 09-citations/README.md ({validation_status})
```

**Mark Phase 6 todo as completed** to finish the workflow.

## Output Language

Generate ALL user-facing content in {{LANGUAGE}} language.

**Localized:** Section headings, tier descriptions, institutional labels, explanatory text.

**English only:** Entity IDs, wikilinks, YAML keys, APA format, URLs, JSON keys.

## Error Handling

| Scenario | Recovery |
|----------|----------|
| PROJECT_PATH missing | Exit 2 |
| Working directory validation fails | Exit 1 |
| No sources/citations directory | Skip, continue with empty list |
| Entity metadata incomplete | Skip entity, log warning |
| Catalog write fails | Exit 1 |
| Template not found | Fall back to generic |

See [references/error-handling.md](references/error-handling.md) for recovery patterns.

## Quality Checklist

- [ ] All entities loaded completely (no truncation)
- [ ] All metadata extracted from frontmatter (no fabrication)
- [ ] Tier distribution calculated with valid percentages
- [ ] All wikilinks reference real entity IDs
- [ ] File written to correct location
- [ ] JSON response contains all required fields

## Debugging

### Enhanced Logging Initialization

```bash
# Source enhanced logging utility
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize skill-specific log file
SKILL_NAME="evidence-synthesizer"
LOG_FILE="${PROJECT_PATH}/.metadata/${SKILL_NAME}-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.metadata"

# Log phase transitions
log_phase "Phase 4: Complete Entity Loading" "start"
# ... phase work ...
log_phase "Phase 4: Complete Entity Loading" "complete"

# Log metrics at completion
log_metric "sources_cataloged" "$source_count" "count"
log_metric "citations_formatted" "$citation_count" "count"
log_metric "institutions_mapped" "$inst_count" "count"
```

Enable verbose stderr output: `export DEBUG_MODE=true`

Log locations:

- Execution logs: `${PROJECT_PATH}/.metadata/evidence-synthesizer-execution-log.txt`
- View logs: `bash scripts/view-execution-log.sh --log-file .metadata/evidence-synthesizer-execution-log.txt`

## Reference Index

| Reference | Load When |
|-----------|-----------|
| [tier-classification.md](references/tier-classification.md) | Phase 5.1: Tier scoring |
| [institutional-authority.md](references/institutional-authority.md) | Phase 5.2: Authority mapping |
| [catalog-structure.md](references/catalog-structure.md) | Phase 5.3: Output structure |
| [template-loading.md](references/template-loading.md) | Phase 3: Template discovery |
| [entity-processing.md](references/entity-processing.md) | Phase 4: Entity extraction |
| [examples.md](references/examples.md) | Complete examples |
| [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) | Bash patterns |
| [../../references/anti-hallucination-foundations.md](../../references/anti-hallucination-foundations.md) | Verification |
