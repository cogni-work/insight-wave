# Downstream Options Menu

Phase 5 of `verify-trend-report` ends with a menu that surfaces the most-common next steps. This is the user-facing equivalent of `cogni-research:verify-report`'s "Next steps" recommendation block, except cogni-trends actively dispatches the chosen skill rather than only listing them.

---

## Menu options

```yaml
AskUserQuestion:
  question: "Verification done. What's next?"
  header: "Next step"
  options:
    - label: "Polish prose for executive tone"
      description: "Run cogni-copywriting:copywriter (preserves citations and structure)"
    - label: "Generate themed HTML with charts"
      description: "Run cogni-visual:enrich-report (Chart.js + concept diagrams)"
    - label: "Done — return to trends-resume"
      description: "See the full option set (slides, web, storyboard, catalog, dashboard)"
```

If `cogni-copywriting` is not installed, omit the polish option silently. If `cogni-visual` is not installed, omit the visualize option. If both are missing, skip the menu entirely and direct the user to `/trends-resume`.

## Option 1 — Polish

```
Skill(cogni-copywriting:copywriter,
  args: "FILE_PATH={PROJECT_PATH}/tips-trend-report.md SCOPE=tone STAKEHOLDERS=executive REVIEW_MODE=automated")
```

Parameters mirror the legacy `trend-report` Phase 3.5 (preserved verbatim):

- `SCOPE=tone` — the report structure is already locked by theme assembly. Polish prose clarity, paragraph flow, bold anchoring, sentence rhythm. Do not restructure sections or reorder themes.
- `STAKEHOLDERS=executive` — primary audience is CxO-level decision makers.
- `REVIEW_MODE=automated` — lightweight review pass without interactive feedback.

After the copywriter returns, validate:

| Check | Condition | On Failure |
|-------|-----------|------------|
| Citation count | polished `>=` original | REVERT from `.tips-trend-report.md` backup |
| Frontmatter intact | YAML frontmatter unchanged | REVERT |
| Theme structure | Same H2/H3 heading count and text | REVERT |
| Claims registry | Claims-table rows unchanged | REVERT |

If any check fails, revert from the backup the copywriter created (`.tips-trend-report.md` in the same directory) and log the reason. Polish failure does not block the menu — the user can still pick visualize.

After successful polish, set `metadata.copywriter_applied = true` and `metadata.copywriter_scope = "tone"` in `{PROJECT_PATH}/.metadata/trend-scout-output.json` so `trends-resume` can render the Executive Polish stage as Done.

## Option 2 — Visualize

```
Skill(cogni-visual:enrich-report,
  args: "--source {PROJECT_PATH}/tips-trend-report.md")
```

`cogni-visual:enrich-report` produces a themed HTML deliverable with Chart.js data visualizations and Excalidraw concept diagrams. It writes `{PROJECT_PATH}/output/tips-trend-report-enriched.html` (path detected by `project-status.sh` HAS_ENRICHED_REPORT check).

The enrich-report skill handles theme selection, infographic injection, and content validation internally — no parameters need to be threaded through this menu.

## Option 3 — Done

Exit cleanly. Display:

> **Done.** Run `/trends-resume` to see the full option set: slides, scrollable web landing, print storyboard, industry catalog import, interactive dashboard.

The user can re-enter `/verify-trend-report` later to pick a different menu option — downstream skills do not block each other, and Phase 0.5's resumability check will detect that verification has already completed and offer to jump straight to Phase 5.

## Why no narrative path?

cogni-research surfaces a "Narrative path" alongside the polish path because research reports often serve as input to `cogni-narrative`. cogni-trends reports are already arc-framed (Phase 0.4b of `trend-report` selects a narrative arc and Phase 2 builds the report around it), so a separate narrative-transform pass is rarely valuable. Users who want a different arc should re-run `/trend-report` with the new arc rather than transforming the existing output.
