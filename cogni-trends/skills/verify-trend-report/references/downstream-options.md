# Downstream Options Menu

Phase 5 of `verify-trend-report` ends with a menu that surfaces the most-common next steps: cogni-trends dispatches the polish skill directly, and hands back to `/trends-resume` for every remaining path.

---

## Menu options

```yaml
AskUserQuestion:
  question: "Verification done. What's next?"
  header: "Next step"
  options:
    - label: "Polish prose for executive tone"
      description: "Run cogni-workspace:copywriter (preserves citations and structure)"
    - label: "Done — return to trends-resume"
      description: "See the full option set (Claude Design brief, catalog, dashboard)"
```

If the `copywriter` skill is not installed, skip the menu entirely and direct the user to `/trends-resume` — the visual path is the Claude Design brief `/trends-resume` offers.

## Option 1 — Polish

```
Skill(cogni-workspace:copywriter,
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

If any check fails, revert from the backup the copywriter created (`.tips-trend-report.md` in the same directory) and log the reason. Polish failure does not block the menu — the user can still exit to `/trends-resume`.

After successful polish, set `metadata.copywriter_applied = true` and `metadata.copywriter_scope = "tone"` in `{PROJECT_PATH}/.metadata/trend-scout-output.json` so `trends-resume` can render the Executive Polish stage as Done.

## Option 2 — Done

Exit cleanly. Display:

> **Done.** Run `/trends-resume` to see the full option set: a Claude Design brief (slides, document, infographic or web) via `cogni-workspace:text-to-narrative`, industry catalog import, interactive dashboard.

The user can re-enter `/verify-trend-report` later to pick a different menu option — downstream skills do not block each other, and Phase 0.5's resumability check will detect that verification has already completed and offer to jump straight to Phase 5.

## Why no narrative path?

cogni-trends reports are already arc-framed (Phase 0.4b of `trend-report` selects a narrative arc and Phase 2 builds the report around it), so a separate narrative-transform pass is rarely valuable and a narrative path is deliberately not surfaced. Users who want a different arc should re-run `/trend-report` with the new arc rather than transforming the existing output.
