---
name: research-plan
description: |
  Plan and structure a research project — from initial question to query batches ready for parallel execution.
  This is the FIRST skill in the 4-stage pipeline (research-plan > findings-sources > claims > synthesis).
  Use when the user says "research [topic]", "investigate [subject]", "start research on [topic]",
  "plan research", "create a research plan", "deep dive into [topic]", "analyze [industry/market]",
  "understand [market/technology]", "explore [subject]", "I want to learn about [topic]",
  "what do we know about [topic]", "research strategy for [topic]", "help me research [topic]",
  or wants to do market analysis, competitive analysis, business model validation, industry analysis,
  technology assessment, or portfolio analysis. Also trigger when the user has a broad question they
  want broken into structured research dimensions, or when they want to prepare a systematic
  investigation before gathering evidence. Supports generic, lean-canvas, and b2b-ict-portfolio
  research types.
---

# Research Plan

Transform a research question into a structured, executable plan. Everything downstream — findings, claims, synthesis — depends on the quality of what this skill produces. A well-planned project produces focused dimensions, sharp questions, and optimized search queries that minimize noise and maximize insight coverage.

## Quick Example

**User says:** "Research the impact of AI on pharmaceutical drug discovery"

**Phase 0:** Generic research type, DOK-3 (strategic thinking — requires multi-source synthesis)

**Phase 1 — refined question:** "How are AI/ML techniques (molecular simulation, target identification, clinical trial optimization) changing drug discovery timelines, costs, and success rates for pharmaceutical companies, and what organizational capabilities are needed to capture this value?"

**Phase 2 — 5 MECE dimensions:**
1. AI/ML Techniques & Maturity
2. Drug Discovery Pipeline Impact
3. Organizational & Talent Requirements
4. Regulatory & Ethical Landscape
5. Competitive Dynamics & Market Structure

28 refined PICOT questions across dimensions

**Phase 3:** 28 query batches, ~140 total search configurations ready for parallel execution

## Prerequisites

- A research question or topic from the user
- A workspace directory (detected automatically or specified)

If the workspace is missing, ask the user where to create the project or default to `~/research-projects`.

## Resumption

If a previous run was interrupted, check state before re-executing phases:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/scan-resumption-state.sh --phase planning --project-path <path>
```

The script returns a JSON recommendation:
- **FULL_RUN** — no prior progress. Start from Phase 0.
- **RESUME** — some phases completed. Skip them, resume from the first incomplete one.
- **COMPLETE** — planning already finished. Proceed to findings-sources.

## Workflow

### Phase 0: Project Initialization

Research type determines the entire downstream dimension strategy — getting it wrong means the wrong framework for the whole project.

1. **Detect research type** from user's request. If ambiguous, ask via AskUserQuestion.
   For routing details see `${CLAUDE_PLUGIN_ROOT}/references/research-type-routing.md`.

2. **Determine output language** (en/de): ask user or detect from workspace config.

3. **Initialize project** via `initialize-research-project.sh`.
   For script arguments and output format see [references/script-reference.md](references/script-reference.md).

4. **Verify** the project directory exists with all entity subdirectories before proceeding.

### Phase 1: Question Refinement

This is the highest-leverage phase. A vague question cascades into vague dimensions, noisy findings, and weak claims. Investing time here pays compound dividends through every downstream phase.

1. **Refine the research question** with the user. A good question is:
   - **Specific** — names the domain, population, or technology
   - **Scoped** — has clear temporal, geographic, or domain boundaries
   - **Decomposable** — can break into 2-10 independent dimensions
   - **Answerable** — evidence exists or can be gathered via web search

   For examples and the DOK classification framework see [references/question-quality-guide.md](references/question-quality-guide.md).

2. **Classify DOK level.** Auto-determined for lean-canvas (DOK-2) and b2b-ict-portfolio (DOK-3). Ask the user for generic type. DOK controls dimension count and question depth downstream.

3. **Create initial question entity** via `create-entity.sh --entity-type 00-initial-question`.
   For frontmatter fields see [references/script-reference.md](references/script-reference.md).

4. **Confirm with user** before proceeding. Present: refined question, DOK level, research type.

### Phase 2: Dimensional Planning

Dimensions partition the research topic into independent, non-overlapping areas. MECE (Mutually Exclusive, Collectively Exhaustive) dimensions ensure complete coverage without redundant search work — overlapping dimensions waste agent time searching for the same information twice, while gaps create blind spots in the final synthesis.

1. **Invoke dimension-planner agent** via Task tool with: project path, research_type, DOK level, initial question path.
   The agent creates 2-10 dimensions in `01-research-dimensions/data/` and generates 8-50 refined questions in `02-refined-questions/data/`.

2. **Verify output:** minimum 2 dimensions, each with at least 2 refined questions.

3. **Present dimensions to user** for review. If the user rejects them:
   - Ask which dimensions to add, remove, or rename
   - Explain your rationale for proposed dimensions (coverage argument)
   - Re-run dimension-planner with adjusted guidance if needed

### Phase 3: Batch Creation

Each refined question becomes one self-contained query batch, enabling findings-sources to execute them in parallel across independent agents.

1. **Invoke batch-creator agent** via Task tool with: project path, list of refined questions.
   The agent creates one query batch per refined question in `03-query-batches/data/`, each containing optimized search configurations.

2. **Verify output:** one batch per refined question, each with valid query strings.

3. **Mark planning complete:** update sprint-log `planning_complete = true`.

4. **Report to user:** dimension count, question count, batch count, and that the next step is running `findings-sources`.

## Error Recovery

| Scenario | What to Do |
|----------|------------|
| dimension-planner returns < 2 dimensions | Re-examine the question — consider broadening scope or raising DOK level. Re-run dimension-planner. |
| User rejects dimensions | Ask which to add/remove/rename. Provide coverage rationale. Re-run with adjusted guidance. |
| batch-creator fails for some questions | Check `.logs/batch-creator/` for details. Re-run for failed questions only. |
| Project init script fails | Verify `CLAUDE_PLUGIN_ROOT` is set and directory is writable. |
| Resumption detected | Run `scan-resumption-state.sh --phase planning` to identify completed phases. Skip them. |

## Completion

Planning is complete when:
- Sprint-log shows `planning_complete: true`
- All refined questions have corresponding query batches in `03-query-batches/data/`

After research-plan completes, run the `findings-sources` skill to execute parallel web search and source extraction.
