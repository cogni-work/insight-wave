---
name: research-plan
description: |
  Plan and structure a research project — from initial question to query batches ready for parallel execution.
  Use when the user says "research [topic]", "investigate [subject]", "start research on [topic]",
  "plan research", "create a research plan", or wants to do market analysis, competitive analysis,
  or business canvas creation. Supports generic, lean-canvas, and b2b-ict-portfolio research types.
  After completion, run findings-sources for parallel findings creation.
---

# Research Plan

Transform a research question into a structured plan: initialize project, refine question, create MECE dimensions, generate refined questions, and build query batches for parallel execution.

## Prerequisites

- A research question or topic from the user
- A workspace directory (detected automatically or specified)

## Workflow

### Phase 0: Project Initialization

1. **Detect research type** from user's request or ask via AskUserQuestion:

   | Research Type | DOK Level | Dimensions | Use Case |
   |---|---|---|---|
   | `generic` | ASK USER (1-4) | Dynamic (2-10) | Flexible research on any topic |
   | `lean-canvas` | 2 (auto) | 9-block canvas | Business model analysis |
   | `b2b-ict-portfolio` | 3 (auto) | 8 ICT dimensions | B2B provider analysis |

2. **Determine output language**: Ask user (en/de) or detect from workspace config
3. **Initialize project**: Run `${CLAUDE_PLUGIN_ROOT}/scripts/initialize-research-project.sh`
   - Creates 7 entity directories (00-06) + .metadata/
   - Generates sprint-log.json with research_type, language, timestamps
4. **Verify**: Project directory exists with all entity subdirectories

### Phase 1: Question Refinement

1. **Refine the research question**: Work with user to sharpen the question
   - Apply DOK classification (auto-determined for lean-canvas/b2b-ict-portfolio, asked for generic)
   - Ensure question is specific, measurable, and researchable
2. **Create initial question entity**: Via `create-entity.sh --entity-type 00-initial-question`
   - Frontmatter: research_type, dok_level, language, research_question
3. **Confirm with user** before proceeding

### Phase 2: Dimensional Planning

1. **Invoke dimension-planner agent** via Task tool:
   - Pass: project path, research_type, DOK level, initial question
   - Agent creates 2-10 MECE dimensions in 01-research-dimensions/data/
   - Agent generates 8-50 refined questions in 02-refined-questions/data/

2. **Verify dimension output**:
   - Minimum 2 dimensions created
   - Each dimension has at least 2 refined questions
   - Questions are MECE (mutually exclusive, collectively exhaustive)

3. **Present dimensions to user** for review and confirmation

### Phase 3: Batch Creation

1. **Invoke batch-creator agent** via Task tool:
   - Pass: project path, list of refined questions
   - Agent creates one query batch per refined question in 03-query-batches/data/
   - Each batch contains optimized search queries

2. **Verify batch output**:
   - One batch per refined question
   - Each batch has valid query strings

3. **Update sprint-log**: Set `planning_complete = true`

4. **Report completion**: Summary with dimension count, question count, batch count

---

## State Management

Phase state tracked in `.metadata/sprint-log.json`:
- `planning_complete: true` — signals readiness for findings-sources
- Resumption: check via `scan-resumption-state.sh --phase planning`

## Agents Used

| Agent | Purpose | Invocation |
|---|---|---|
| `dimension-planner` | Create MECE dimensions + refined questions | Task tool, Phase 2 |
| `batch-creator` | Create query batches from refined questions | Task tool, Phase 3 |

## Next Step

After research-plan completes, run `findings-sources` to execute parallel web search and source extraction.
