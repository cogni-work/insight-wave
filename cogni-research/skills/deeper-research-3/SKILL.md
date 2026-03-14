---
name: deeper-research-3
description: Orchestrate research synthesis (Phase 4 of 4). Use when user requests "synthesize research", "continue research", or "generate trends" from existing research project. Requires enrichment_complete=true (set after deeper-research-0, deeper-research-1, and deeper-research-2 complete). Executes phases 8-10, 12-13 to generate trends, evidence catalog, and final research report.
---

# Deeper Research 3 - Synthesis

Transform enriched research data into executive deliverables through multi-stage synthesis. Execute phases 8-10, 12-13 (continuing from deeper-research-2 phases 4-7).

---

## ⛔ CRITICAL: Orchestrator-Only Architecture

**This skill is a PURE ORCHESTRATOR. It does NOT perform synthesis work directly.**

### Your Role

1. Validate project state (directories exist, enrichment_complete)
2. Extract dimension slugs using `ls` commands ONLY
3. **Invoke agents via Task tool** to do actual work
4. Validate agent outputs
5. Report completion metrics

### Correct vs Prohibited

| ✅ CORRECT | ❌ PROHIBITED |
| ---------- | ------------- |
| `Task(subagent_type="...:trends-creator", ...)` | `Skill(skill="...:trends-creator")` |
| `ls 01-research-dimensions/data/` to extract slugs | `Read(file_path="04-findings/data/...")` |
| Validate agent JSON responses | Load entities or "representative samples" |

**Why:** Executor skills load entities when invoked by agents. Bypassing via Skill tool causes context overflow.

---

## Output Structure

```text
project-name/
├── README.md                    # Navigation hub
├── research-hub.md           # Comprehensive report (Phase 10)
├── insight-summary.md        # Arc-specific narrative (Phase 10.5, if arc_id set)
├── 10-claims/data/              # From deeper-research-2
├── 11-trends/data/            # Dimension-scoped trends (Phase 8)
├── 12-synthesis/                # Dimension synthesis documents (Phase 8.5)
└── 09-citations/README.md       # Evidence catalog (Phase 9)
```

---

## Project Selection

**MANDATORY:** Resolve `project_path` before proceeding to the entry gate.

Follow the shared project picker pattern in [../../references/project-picker.md](../../references/project-picker.md) with:
- `prerequisite_flag` = `enrichment_complete`
- `prerequisite_skill` = `deeper-research-2`

This handles `--project-path` argument passthrough, multi-project discovery, prerequisite filtering, and interactive selection via `AskUserQuestion` when multiple eligible projects exist.

---

## Entry Gate: Enrichment Must Be Complete

```bash
# project_path is already set by Project Selection above
if [ -z "${project_path:-}" ]; then
  echo "ERROR: project_path not set. Provide --project-path argument." >&2
  exit 1
fi

enrichment_complete=$(jq -r '.enrichment_complete // false' "${project_path}/.metadata/sprint-log.json")
[ "$enrichment_complete" != "true" ] && echo "ERROR: Run deeper-research-2 first." && exit 1
project_language=$(jq -r '.project_language // "en"' "${project_path}/.metadata/sprint-log.json")
echo "project_path: ${project_path}"
echo "project_language: ${project_language}"
```

**IF enrichment_complete != true:** STOP. User must run `deeper-research-2` first.

---

## Immediate Action: Initialize TodoWrite

⛔ **MANDATORY:** Initialize TodoWrite immediately:

1. Input validation: Verify Part 2 completion [in_progress]
2. Phase 0.5: Arc detection & configuration [pending]
3. Phase 8: Parallel trend generation [pending]
4. Phase 8.5: Dimension synthesis generation [pending]
5. Phase 9: Evidence synthesis [pending]
6. Phase 10: Synthesis creation [pending]
6.5. Phase 10.25: Research question sharpening [pending]
7. Phase 10.5: Insight summary generation [pending]
8. Phase 12: Wikilink validation [pending]
9. Phase 13: Finalization [pending]

**Progressive expansion:** Each phase adds step-level todos when started (~9 phase-level → ~45-55 step-level).

---

## Execution Protocol

⛔ **MANDATORY: Read phase reference file BEFORE executing each phase.**

- SKILL.md provides navigation only
- Phase workflow files contain implementation steps, TodoWrite templates, verification gates
- **Lesson learned:** Phases fail when reference files not read, causing critical steps to be skipped

---

## Core Workflow

```text
Entry Gate → Phase 0.5 → Phase 8 → Phase 8.5 → Phase 9 → Phase 10 → Phase 10.25 → Phase 10.5 → Phase 12 → Phase 13
```

---

## Phase 0.5: Arc Detection & Configuration

**Architecture:** Detect synthesis arc for downstream hub routing.

**Routing reference:** See [../../references/research-type-routing.md](../../references/research-type-routing.md) for the complete research_type → arc_id mapping.

⛔ **Read:** [references/phase-workflows/phase-0.5-arc-detection.md](references/phase-workflows/phase-0.5-arc-detection.md)

**When:** Before Phase 8 (first phase of synthesis workflow)

**Purpose:** Set `arc_id` in sprint-log.json to enable arc-specific narrative generation in Phase 10.5.

### Step-by-Step Workflow

**Step 0.5.1: Read research_type**

```bash
research_type=$(jq -r '.research_type // "generic"' "${project_path}/.metadata/sprint-log.json")
echo "Research Type: ${research_type}"
```

**Step 0.5.2: Auto-detect arc**

Map research_type to recommended arc:

| research_type | Detected arc_id | Framework Elements |
|---------------|-----------------|-------------------|
| `technology` | `technology-futures` | What's Emerging → Converging → Possible → Required |
| `competitive` | `competitive-intelligence` | Landscape → Shifts → Positioning → Implications |
| `foresight`, `scenarios` | `strategic-foresight` | Signals → Scenarios → Strategies → Decisions |
| `industry`, `transformation` | `industry-transformation` | Forces → Friction → Evolution → Leadership |
| `market`, `generic`, (default) | `corporate-visions` | Why Change → Why Now → Why You → Why Pay |

**Step 0.5.3: Interactive confirmation**

Use AskUserQuestion to present detected arc with option to select alternative.

**Step 0.5.4: Persist arc to metadata**

```bash
jq --arg arc_id "${arc_id}" --arg arc_display "${arc_display_name}" \
  '.arc_id = $arc_id | .arc_display_name = $arc_display' \
  "${project_path}/.metadata/sprint-log.json" > tmp.json
mv tmp.json "${project_path}/.metadata/sprint-log.json"
```

**Required outputs:** `arc_id` and `arc_display_name` in sprint-log.json

---

## Phase 8: Parallel Trend Generation

**Architecture:** One trends-creator agent per dimension, invoked in parallel.

**Portfolio Integration:** For `smarter-service` and `customer-value-mapping` research types, Phase 8 validates existing portfolio connections and prompts user to connect a portfolio if not already linked. Portfolio validation ensures the path exists and has correct structure (11-trends/ with portfolio-*.md files).

⛔ **Read:** [references/phase-workflows/phase-8-domain-synthesis.md](references/phase-workflows/phase-8-domain-synthesis.md)

**Gate:** Verify claims exist before starting:

```bash
ls -la 10-claims/data/ | head -5
```

**Portfolio Steps (Step 0.7):**

1. Check if research type supports portfolio (0.7.0)
2. Validate existing portfolio structure (0.7.1)
3. Prompt user if missing/invalid (0.7.2)
4. Validate user-provided path (0.7.3)
5. Persist connection to metadata (0.7.4)

**Delegate via Task tool** (ALL dimensions in SINGLE message):

```python
Task(
  subagent_type="cogni-research:trends-creator",
  prompt="Generate trends at {project_path} for dimension: {dimension_slug}. Language: {project_language}",
  description="Creating trends for {dimension_slug}"
)
# ... one Task per dimension
# Include portfolio_project_path and portfolio_project_slug if connected
```

**Required outputs:** trend files in `11-trends/data/`

---

## Phase 8.5: Dimension Synthesis Generation

Generate comprehensive dimension synthesis documents from trends for integration into final research report.

⛔ **Read:** [references/phase-workflows/phase-8.5-dimension-synthesis.md](references/phase-workflows/phase-8.5-dimension-synthesis.md)

**Delegate via Task tool** (ALL dimensions in SINGLE message):

```python
Task(
  subagent_type="cogni-research:synthesis-dimension",
  prompt="Generate dimension synthesis at {project_path} for dimension: {dimension_slug}. Language: {project_language}",
  description="Creating synthesis for {dimension_slug}"
)
# ... one Task per dimension
```

**Required outputs:** synthesis-{dimension}.md files in `12-synthesis/`

---

## Phase 9: Evidence Synthesis

Generate comprehensive source and citation catalog.

⛔ **Read:** [references/phase-workflows/phase-9-evidence-synthesis.md](references/phase-workflows/phase-9-evidence-synthesis.md)

**Delegate via Task tool:**

```python
Task(
  subagent_type="cogni-research:evidence-synthesizer",
  prompt="Generate evidence synthesis at {project_path}. Language: {project_language}",
  description="Creating evidence catalog"
)
```

**Required outputs:** `09-citations/README.md`

---

## Phase 10: Synthesis Creation

Create comprehensive research report from trends and evidence catalog.

⛔ **Read:** [references/phase-workflows/phase-10-synthesis-creation.md](references/phase-workflows/phase-10-synthesis-creation.md)

**Gate:** Verify both Phase 8.5 (dimension syntheses) AND Phase 9 (evidence catalog) artifacts exist.

**Delegate via Task tool:**

```python
Task(
  subagent_type="cogni-research:synthesis-hub",
  prompt="Create research report at {project_path}. Language: {project_language}",
  description="Creating research report"
)
```

**Required outputs:** `research-hub.md`

---

## Phase 10.25: Research Question Sharpening

Distill the original research question into a concise, dual-structure formulation (max 20 words) based on synthesis results.

⛔ **Read:** [references/phase-workflows/phase-10.25-question-sharpening.md](references/phase-workflows/phase-10.25-question-sharpening.md)

**Gate:** Verify Phase 10 completion (research-hub.md exists).

**This phase is orchestrator-inline** (no agent delegation). The orchestrator:
1. Reads original `research_question` from sprint-log.json
2. Formulates sharpened version using synthesis context already in conversation
3. Persists `sharpened_research_question` to sprint-log.json

**All failures are WARNING-only** (non-blocking). If sharpening fails, original question is used unchanged.

**Required outputs:** `sharpened_research_question` in sprint-log.json

---

## Phase 10.5: Insight Summary Generation (Conditional)

Generate arc-specific narrative by delegating to `cogni-narrative:narrative-writer`. **Skipped if no arc_id is set.**

⛔ **Read:** [references/phase-workflows/phase-10.5-insight-summary.md](references/phase-workflows/phase-10.5-insight-summary.md)

**Gate:** Verify Phase 10 completion (research-hub.md exists) AND arc_id present in sprint-log.json.

```bash
arc_id=$(jq -r '.arc_id // ""' "${project_path}/.metadata/sprint-log.json")
```

**IF arc_id is empty:** Mark Phase 10.5 as completed (skipped) and proceed to Phase 12.

**IF arc_id is present, delegate via Task tool:**

```python
Task(
  subagent_type="cogni-narrative:narrative-writer",
  prompt="source_path: {project_path}/12-synthesis/\narc_id: {arc_id}\nlanguage: {project_language}\noutput_path: {project_path}/insight-summary.md",
  description="Generating insight summary ({arc_id})"
)
```

**All failures are WARNING-only** (non-blocking). If narrative-writer fails, log warning and continue to Phase 12. Phase 13 Step 1.5 will flag the missing file for review.

**Required outputs:** `insight-summary.md` (at project root, if arc_id set)

---

## Phase 12: Wikilink Validation

⛔ **Read:** [references/phase-workflows/phase-12-wikilink-validation.md](references/phase-workflows/phase-12-wikilink-validation.md)

**Gate:** Verify Phase 10 completion (research report exists)

Execute wikilink validation and resolve any broken links.

**Required outputs:** Zero broken wikilinks

---

## Phase 13: Finalization

⛔ **Read:** [references/phase-workflows/phase-13-finalization.md](references/phase-workflows/phase-13-finalization.md)

**Gate:** Verify zero broken links from Phase 12

1. Validate README.md at project root
2. Generate compliance report
3. Update sprint log: `synthesis_complete = true`
4. Report completion summary

**Required outputs:** Completion report with entity counts

**Post-completion workflow (recommend to user after Phase 13):**

1. **Polish** (optional): `polish-research` — parallel copywriting + stakeholder review
2. **Export HTML**: `export-html-report` — interactive HTML with navigation, graph view, theme support
3. **Export PDF**: `export-pdf-report` — formal A4 PDF with cover page, TOC, source index
4. **Export RAG**: `export-rag` — flat markdown optimized for RAG in Claude Projects

---

## Parallel Execution

Invoke ALL instances in single message for maximum performance:

| Phase | Agent | Parallelization |
|-------|-------|-----------------|
| 8 | trends-creator | One per dimension (parallel) |
| 8.5 | synthesis-dimension | One per dimension (parallel) |

**Pattern:** Extract dimension list first, then invoke ALL Task calls in ONE message. Each agent runs in isolated context with its own token budget.

---

## Resumption Detection

```bash
claim_count=$(find 10-claims/data -maxdepth 1 -name "claim-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
trend_count=$(find 11-trends/data -maxdepth 1 -type f -name "*.md" 2>/dev/null | xargs -I {} basename {} 2>/dev/null | grep -E "^(trend|portfolio)-.*\.md$" | wc -l | tr -d ' ')
evidence_exists=$(test -f 09-citations/README.md && echo "yes" || echo "no")
```

| Condition | Action |
|-----------|--------|
| `claim_count == 0` | **HALT** - Run deeper-research-2 first |
| `trend_count == 0` | Start at Phase 8 (MANDATORY) |
| `evidence_exists == "no"` | Start at Phase 9 |
| `research-hub.md` missing | Start at Phase 10 |
| `research-hub.md` exists, `sharpened_research_question` missing in sprint-log | Start at Phase 10.25 |
| `research-hub.md` exists, arc_id set, `insight-summary.md` missing | Start at Phase 10.5 |
| All files present | Report completion |

---

## Constraints

- DO NOT modify deeper-research-1/2 entity files (read-only)
- DO NOT perform synthesis directly (delegate to agents)
- DO NOT load entities at this level (agents handle loading)
- ALWAYS validate agent responses
- ALWAYS report phase completion with metrics

---

## Error Handling

| Phase | Failure | Action |
|-------|---------|--------|
| 8 | trends-creator fails | HALT - review agent logs |
| 9 | evidence-synthesizer fails | HALT |
| 10 | synthesis-hub fails | HALT |
| 10.25 | sharpening fails | WARNING only - use original question |
| 10.5 | narrative-writer fails | WARNING only - continue to Phase 12 |
| 12-13 | Any | HALT |

---

## Language Propagation

Read `project_language` from `.metadata/sprint-log.json` (default: "en"). Pass to synthesis agents via `LANGUAGE` parameter.

---

## Debugging

See [../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md) Section 3 for enhanced logging initialization pattern.

Enable verbose output: `export DEBUG_MODE=true`

Log file: `${PROJECT_PATH}/.metadata/deeper-research-3-execution-log.txt`

---

## Token Budget

Estimated: ~70,000 tokens (35% of 200K budget)

| Phase | Est. Tokens |
|-------|-------------|
| 8 | 12,000 |
| 8.5 | 18,000 |
| 9 | 6,000 |
| 10 | 18,000 |
| 10.25 | 2,000 |
| 10.5 | 3,000 |
| 12-13 | 5,000 |

Phase 8.5 scales with dimension count (~2,500 tokens per dimension for 7 dimensions).
