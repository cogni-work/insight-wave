---
name: polish-research
description: Orchestrate parallel copywriting across all narrative outputs from a completed research project — synthesis documents, megatrend entities, trend entities, and insight summary. Use when the user wants to polish research output, improve research writing quality, copywrite research deliverables, or review the executive summary with stakeholder personas. Requires synthesis_complete=true in sprint-log.json (set after deeper-research-3 completes). Dispatches cogni-copywriting:copywriter agents in parallel for each polishable file, then optionally runs a 5-persona stakeholder review on the executive summary.
---

# Polish Research

Orchestrate post-pipeline copywriting across all synthesis outputs from a completed deeper-research project. Dispatches `cogni-copywriting:copywriter` agents in parallel, then optionally runs a `cogni-copywriting:reader` stakeholder review on the executive summary.

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `--project` | No | Auto-detected | Path to research project root |
| `--scope` | No | `all` | Scope filter: `all`, `synthesis`, `insight`, `megatrends`, `trends` |
| `--skip-review` | No | `false` | Skip the stakeholder reader review on executive summary |

## Phase 0: Project Discovery & Validation

When invoked without a `--project` argument:

1. **Check environment variable:**

   ```bash
   echo "${COGNI_RESEARCH_ROOT:-}"
   ```

   If set, list research projects under `$COGNI_RESEARCH_ROOT/deeper/` to find available projects.

2. **If not set, ask the user:**
   Use AskUserQuestion to request the full path to the research project.

3. **Validate project state:**

   ```bash
   sprint_log="${project_path}/.metadata/sprint-log.json"
   synthesis_complete=$(jq -r '.synthesis_complete // false' "$sprint_log")
   ```

   **IF synthesis_complete != true:** HALT. User must run `deeper-research-3` first.

4. **Read sprint-log metadata** for arc_id (used to determine insight-summary eligibility):

   ```bash
   arc_id=$(jq -r '.arc_id // ""' "$sprint_log")
   ```

## Phase 1: File Discovery

Scan the project for polishable files. See [references/polishable-files.md](references/polishable-files.md) for the complete file list with characteristics.

**Discovery steps:**

1. **Check each candidate file exists** using `ls` or `test -f`:

   ```bash
   # Core narrative files (project root)
   test -f "${project_path}/insight-summary.md" && echo "found: insight-summary.md"

   # Synthesis files
   test -f "${project_path}/12-synthesis/synthesis-cross-dimensional.md" && echo "found"
   ls "${project_path}/12-synthesis/synthesis-"*.md 2>/dev/null | grep -v cross-dimensional

   # Megatrend files
   test -f "${project_path}/06-megatrends/README.md" && echo "found"
   ls "${project_path}/06-megatrends/data/"*.md 2>/dev/null

   # Trend files
   test -f "${project_path}/11-trends/README.md" && echo "found"
   ls "${project_path}/11-trends/README-"*.md 2>/dev/null
   ls "${project_path}/11-trends/data/trend-"*.md 2>/dev/null
   ```

2. **Include insight-summary.md** (MANDATORY when it qualifies):
   - If `insight-summary.md` exists AND has `arc_id` in frontmatter: **ALWAYS include it** in the file list. This file is the highest-value polishing target after the executive summary.
   - If missing or no `arc_id`: Skip with WARNING (normal for projects without arc detection).

3. **Apply --scope filter** if provided:

   | Scope | Files included |
   |-------|---------------|
   | `all` | All polishable files including insight-summary.md (default) |
   | `synthesis` | `synthesis-cross-dimensional.md` + per-dimension `synthesis-*.md` + `insight-summary.md` |
   | `insight` | `insight-summary.md` only |
   | `megatrends` | `06-megatrends/README.md` + `06-megatrends/data/*.md` |
   | `trends` | `11-trends/README.md` + `11-trends/README-*.md` + `11-trends/data/trend-*.md` |

4. **Build numbered file list** for user selection. `insight-summary.md` appears FIRST (highest priority). Group remaining files by directory:

   ```
   Discovered N polishable files:

   insight-summary.md (arc: corporate-visions)
   [1] insight-summary.md

   12-synthesis/ (synthesis)
   [2] 12-synthesis/synthesis-cross-dimensional.md (executive summary)
   [3] 12-synthesis/synthesis-digital-foundation.md
   [4] 12-synthesis/synthesis-market-dynamics.md

   06-megatrends/ (megatrends)
   [5] 06-megatrends/README.md
   [6] 06-megatrends/data/megatrend-ai-transformation.md
   [7] 06-megatrends/data/megatrend-sustainability.md

   11-trends/ (trends)
   [8] 11-trends/README.md
   [9] 11-trends/README-digital-foundation.md
   [10] 11-trends/data/trend-cloud-native-adoption.md
   [11] 11-trends/data/trend-zero-trust-security.md
   ...
   ```

5. **Validation gate**: Before presenting the list, verify `insight-summary.md` is included if it exists with a valid `arc_id`. If it was accidentally omitted, add it now.

## Phase 1.5: User Selection

Present the numbered file list and ask the user which files to polish using AskUserQuestion:

```
Which files do you want to polish? Enter numbers separated by commas, a range (e.g. 1-4), or "all" for everything:
```

**Parse the response:**

| Input | Result |
|-------|--------|
| `all` or `*` | Select all discovered files |
| `1,3,5` | Select files 1, 3, and 5 |
| `1-4` | Select files 1 through 4 |
| `1-3,5` | Select files 1, 2, 3, and 5 (mixed ranges and individual) |

**Validation:** If any number is out of range or input is unparseable, re-ask with a clarifying message. Do NOT proceed until a valid selection is confirmed.

**After valid selection, confirm to user:**

```
Polishing N of M files:
- 12-synthesis/synthesis-cross-dimensional.md
- 06-megatrends/README.md
- ...
```

Only the selected files proceed to Phase A.

## Phase A: Parallel Copywriter Dispatch

Dispatch one `cogni-copywriting:copywriter` agent per discovered file. ALL Task calls MUST be in a single message for maximum parallelism.

**Invocation contract per file:**

```python
Task(
  subagent_type="cogni-copywriting:copywriter",
  prompt="FILE_PATH: {abs_path}\nSCOPE: full\nREVIEW_MODE: skip",
  description="Polish {filename}"
)
```

**Dispatch ALL files in ONE message.** Example with 6 files:

```python
# All 6 Task calls in a single response message
Task(subagent_type="cogni-copywriting:copywriter",
     prompt="FILE_PATH: /path/to/12-synthesis/synthesis-cross-dimensional.md\nSCOPE: full\nREVIEW_MODE: skip",
     description="Polish synthesis-cross-dimensional.md")

Task(subagent_type="cogni-copywriting:copywriter",
     prompt="FILE_PATH: /path/to/12-synthesis/synthesis-digital-foundation.md\nSCOPE: full\nREVIEW_MODE: skip",
     description="Polish synthesis-digital-foundation.md")

# ... one per file
```

**Wait for all agents to complete.** Collect JSON results from each.

**Result handling:**

- On success: Record filename, flesch_score, improvement count
- On failure: Record filename and error — do NOT halt, continue with remaining files

## Phase B: Reader Review (Sequential)

After Phase A completes, run a 5-persona stakeholder review on the executive summary.

**Gate conditions — ALL must be true:**
- `synthesis-cross-dimensional.md` was selected by the user in Phase 1.5 AND polished successfully in Phase A
- `--skip-review` flag is NOT set

**IF gate fails:** Skip Phase B with informational message.

**Invocation contract:**

```python
Task(
  subagent_type="cogni-copywriting:reader",
  prompt="FILE_PATH: {abs_path_to_synthesis_cross_dimensional}\nPERSONAS: executive,technical,legal,marketing,end-user\nAUTO_IMPROVE: true",
  description="Stakeholder review of executive summary"
)
```

**Wait for completion.** Collect reader results (overall_score, persona_scores, improvements_applied).

## Phase C: Summary Report

Present a consolidated report to the user:

```
## Polish Research Complete

### Copywriter Results (Phase A)
| File | Flesch Score | Improvements |
|------|-------------|-------------|
| insight-summary.md | 45.7 | 6 |
| 12-synthesis/synthesis-cross-dimensional.md | 42.3 | 12 |
| 12-synthesis/synthesis-digital-foundation.md | 38.1 | 8 |
| 06-megatrends/README.md | 41.2 | 9 |
| 06-megatrends/data/megatrend-ai-transformation.md | 40.5 | 5 |
| 11-trends/README.md | 39.8 | 7 |
| 11-trends/README-digital-foundation.md | 43.1 | 4 |
| 11-trends/data/trend-cloud-native-adoption.md | 37.9 | 8 |
| ... | ... | ... |

### Stakeholder Review (Phase B)
| Persona | Score | Key Feedback |
|---------|-------|-------------|
| Executive | 8.5 | ... |
| Technical | 7.2 | ... |
| Legal | 8.0 | ... |
| Marketing | 7.8 | ... |
| End-user | 8.3 | ... |

Overall score: 7.96
Improvements applied: 4

### Summary
- Files polished: 7/7
- Files failed: 0
- Reader review: completed (score: 7.96)
```

## Error Handling

| Scenario | Response |
|----------|----------|
| `synthesis_complete != true` | HALT — run deeper-research-3 first |
| `cogni-copywriting` not installed | HALT — warn user to install cogni-copywriting plugin |
| No polishable files found | HALT — verify project structure |
| Individual copywriter agent fails | WARNING — log error, continue with remaining files |
| Reader agent fails | WARNING — report failure, do not block summary |
| insight-summary.md missing or no arc_id | SKIP — not an error, file is optional |
| 06-megatrends/README.md missing | SKIP — some projects may not have megatrend narratives |
| 06-megatrends/data/ empty | SKIP — some projects may not have megatrend entity files |
| 11-trends/README.md missing | SKIP — some projects may not have trend landscape |
| 11-trends/data/ empty | SKIP — some projects may not have trend entity files |

## Constraints

- DO NOT modify source files directly — all modifications happen via cogni-copywriting agents
- DO NOT invoke agents sequentially — all copywriter agents MUST launch in parallel (single message)
- DO NOT run reader review before copywriter completes — reader must review polished content
- DO NOT halt on individual file failures — collect all results and report at end

## Dependencies

- **Required**: `cogni-copywriting` plugin (provides `copywriter` and `reader` agents)
- **Required**: Completed deeper-research-3 project (`synthesis_complete = true`)
