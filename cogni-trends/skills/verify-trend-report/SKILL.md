---
name: verify-trend-report
description: |
  Run the extended quality pipeline on a generated cogni-trends report — verify
  claims against their cited sources via cogni-claims, run cross-theme structural
  review, apply corrections through the revisor, and surface downstream polish
  and visualization options to the user. Use whenever the user says "verify
  trend report", "verify claims", "fact-check the trend report", "improve the
  trend report", "enrich the trend report", "review the trend report", "extend
  the trend report", "trend report verification", or runs `/trends-resume` after
  trend-synthesis finished and picks the verify path. Also trigger when a
  trend-synthesis Phase 3 summary recommends it. Mirror of cogni-research:verify-report,
  scoped to the cogni-trends data model (`tips-trend-report.md` and
  `tips-trend-report-claims.json`).
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task, Skill, AskUserQuestion
---

# Verify Trend Report Skill

Quality gate for a generated trend report. Verifies every quantitative claim against its cited source via `cogni-claims`, runs a cross-theme structural review, applies corrections through the revisor when deviations or structural issues are found, and surfaces downstream polish and visualization options at the end. Runs in a **fresh context window** — separate from the trend-synthesis pipeline — so claims verification, the review loop, and revision get the full attention they deserve without competing for context with research data.

## Purpose

`trend-synthesis` produces a draft (`tips-trend-report.md`) plus a claims registry (`tips-trend-report-claims.json`). This skill is the dedicated re-entry point that lifts that draft to a deliverable:

1. Verifies claims against source URLs via `cogni-claims:claims`
2. Lets the user steer corrections (proceed / fix specific deviations / drop claims / accept)
3. Runs `trend-report-reviewer` for cross-theme structural quality
4. Dispatches `trend-report-revisor` to apply corrections, remove unverifiable claims, and find replacement evidence
5. Surfaces downstream options: executive polish (`cogni-copywriting:copywriter`) and visual enrichment (`cogni-visual:enrich-report`)

## Prerequisites

- `trend-synthesis` has produced both `{PROJECT_PATH}/tips-trend-report.md` and `{PROJECT_PATH}/tips-trend-report-claims.json`
- `cogni-claims` plugin installed (recommended — graceful degradation when absent: structural review only, see Error Handling)
- Optional: `cogni-copywriting` and `cogni-visual` plugins for downstream menu options

## Path Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `CLAUDE_PLUGIN_ROOT` | Plugin installation (skills, references) | `~/.claude/plugins/marketplaces/cogni-trends` |
| `PROJECT_AGENTS_OPS_ROOT` | Workspace root where projects live (set by cogni-workspace) | User's workspace directory |

`CLAUDE_PLUGIN_ROOT` is injected automatically. `PROJECT_AGENTS_OPS_ROOT` is set by cogni-workspace — if not present, scripts fall back to `$PWD`.

## References Index

Read references **only when needed** for the specific phase:

| Reference | Read when... |
|-----------|--------------|
| [references/claims-integration.md](references/claims-integration.md) | Phase 2 — cogni-claims submission and verification protocol |
| [references/structural-review.md](references/structural-review.md) | Phase 4 — review/revisor loop, validation rules, version output |
| [references/downstream-options.md](references/downstream-options.md) | Phase 5 — final menu (copywriter, enrich-report, narrative path) |

## Workflow Overview

```text
Phase 0 → Phase 0.5 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
   │          │           │          │          │          │          │
   │          │           │          │          │          │          └─ Finalize + downstream menu
   │          │           │          │          │          └─ Structural review + revisor loop (max 2 iterations)
   │          │           │          │          └─ Interactive claims review
   │          │           │          └─ Submit + verify claims via cogni-claims
   │          │           └─ Surface claims registry (no re-extraction)
   │          └─ Resumability check (re-verify / inspect / continue)
   └─ Locate project, draft, claims registry; load language and market
```

---

### Phase 0: Locate Report and Claims Registry

#### Step 0.0: Detect Interaction Language

Read [`$CLAUDE_PLUGIN_ROOT/references/language-resolution.md`]($CLAUDE_PLUGIN_ROOT/references/language-resolution.md). Detect workspace language from `.workspace-config.json`. Set `INTERACTION_LANGUAGE` — use this for all user-facing prompts and status messages.

#### Step 0.1: Project Discovery

1. If `--project-path` was provided as an argument, use it directly.
2. Otherwise, run the trend-scout discovery script:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-trends/*/ | head -1)}/scripts/discover-projects.sh" --json
```

3. Filter the returned `projects[]` to those where `has_report == true` (i.e. `tips-trend-report.md` exists).
4. Branch on the result:
   - 0 eligible: HALT — "No cogni-trends project with a generated report found. Run `/trend-synthesis` first."
   - 1 eligible: auto-select.
   - 2+ eligible: present via `AskUserQuestion` and ask the user to choose.

#### Step 0.2: Validate Inputs

| Check | Condition | On Failure |
|-------|-----------|------------|
| Report exists | `{PROJECT_PATH}/tips-trend-report.md` | HALT: Run `/trend-synthesis` first |
| Claims registry exists | `{PROJECT_PATH}/tips-trend-report-claims.json` | HALT: Claims registry missing — re-run `/trend-synthesis` |
| Project config exists | `{PROJECT_PATH}/tips-project.json` | HALT: Not a valid cogni-trends project |

Read `tips-project.json` for `language` (set as `OUTPUT_LANGUAGE`) and `market_region` (set as `MARKET`, default `dach` for legacy projects).

Resolve the **prose word target** the reviewer needs for tier-aware Completeness scoring. Try in order:

1. `.metadata/trend-scout-output.json → report_target_words` (mirrored there by `trend-synthesis` Phase 3.1).
2. `tips-project.json → report_target_words` (the source of truth, written by `trend-synthesis` Phase 1).
3. Default `4000` (standard tier) — apply when both fields are absent on legacy projects that pre-date the length-tier feature.

Set `REPORT_TARGET_WORDS` for downstream use in Phase 4.

---

### Phase 0.5: Resumability Check

If verification artifacts already exist, present options rather than silently re-running.

**No prior verification** (no `.metadata/trend-report-verification.json` and no `cogni-claims/claims.json`):
→ Proceed to Phase 1.

**Verification ran but no revision** (`.metadata/trend-report-verification.json` exists, no `tips-trend-report-v2.md`):

> **Previous verification found**
> - Verdict: {verdict} | Passed: {N} | Review: {N} | Failed: {N}
> - Verified at: {timestamp}
>
> Options:
> - **re-verify** — clear previous results, re-submit claims, full verification
> - **inspect** — open cogni-claims dashboard for the previous results
> - **continue** — keep results, proceed to Phase 3 (interactive review)

**Revision already applied** (`tips-trend-report-v{N}.md` is the current canonical output):

> **Previous revision found**
> - Revised version: v{N} | Claims removed: {N} | Claims corrected: {N}
> - Revised at: {timestamp}
>
> Options:
> - **accept** — verification cycle complete, jump to Phase 5 downstream menu
> - **re-verify** — re-run verification against the revised report (`tips-trend-report-v{N}.md`)
> - **diff** — show diff between v1 and v{N}, then re-prompt

Handle the user's choice accordingly.

---

### Phase 1: Surface Claims Registry

`trend-synthesis` Step 2.7 already merged claims into `{PROJECT_PATH}/tips-trend-report-claims.json` during report assembly (the per-dimension `claims-{dimension}.json` files were extracted upstream by `trend-research` Phase 1 agents). The registry is canonical — this skill does not re-extract. (If the user manually edited `tips-trend-report.md` after generation, claims may be stale; a future `--re-extract` flag can rebuild the registry. Out of scope for v1.)

1. Read `{PROJECT_PATH}/tips-trend-report-claims.json`.
2. Summarize to the user:

> **Claims registry loaded**
> - Total claims: N
> - By dimension: externe-effekte ({N}), neue-horizonte ({N}), digitale-wertetreiber ({N}), digitales-fundament ({N})
> - Sources cited: {unique URL count}

3. If `total_claims == 0`: HALT — "No claims to verify. The report has no quantitative claims with source URLs. Re-run `/trend-research` with web access enabled, then `/trend-synthesis`."

---

### Phase 2: Submit + Verify via cogni-claims

Read [references/claims-integration.md](references/claims-integration.md) for the full submission protocol.

#### Step 2.1: Check cogni-claims availability

If the `cogni-claims:claims` skill is not installed, log a warning and skip Phases 2 and 3 entirely. Continue with Phase 4 in **structural-review-only** mode (reduced iteration cap of 1).

#### Step 2.2: Run verification

```yaml
Skill:
  skill: "cogni-claims:claims"
  args: "--file-path {PROJECT_PATH}/tips-trend-report.md --claims-file {PROJECT_PATH}/tips-trend-report-claims.json --verdict-mode --language {OUTPUT_LANGUAGE}"
```

This is the same invocation the legacy single-skill `trend-report` Phase 3 used — preserved verbatim for compatibility.

#### Step 2.3: Persist results

Parse the QualityGateResult and write `.metadata/trend-report-verification.json`:

```json
{
  "verified_at": "ISO-8601",
  "verdict": "PASS|REVIEW|FAIL",
  "total_claims": N,
  "verified": N,
  "passed": N,
  "failed": N,
  "review": N,
  "verified_by": "verify-trend-report"
}
```

---

### Phase 3: Interactive Claims Review

Show the user verification results and let them steer corrections before automated review.

#### Step 3.1: Read verification state

1. Read `{PROJECT_PATH}/cogni-claims/claims.json` for per-claim verification details.
2. Compute summary counts: confirmed / deviated / source_unavailable.

#### Step 3.2: Present results

> **Claims Verification Results**
>
> Total: N | Confirmed: N | Deviations: N | Sources unavailable: N
>
> **Deviations found:**
> 1. [claim statement] — *[deviation_type]* ([severity]): [explanation]
> 2. ...

#### Step 3.3: Ask the user how to proceed

`AskUserQuestion` options:

- **proceed** — pass all deviations to reviewer + revisor for automated correction
- **fix: 1, 3** — flag specific claims as mandatory fixes
- **drop: 2** — remove specific claims from the report entirely
- **accept** — finalize without revision (skip Phase 4, jump to Phase 5)
- **inspect: 2** — open cogni-claims inspect mode for claim 2 (browser source comparison), then re-present options

#### Step 3.4: Persist user decisions

Write `.metadata/user-claims-review.json` (mirror cogni-research schema):

```json
{
  "reviewed_at": "ISO-8601",
  "total_claims": N,
  "confirmed": N,
  "deviated": N,
  "source_unavailable": N,
  "user_action": "proceed|fix|drop|accept",
  "fix_claims": ["claim-id-1", "claim-id-3"],
  "drop_claims": ["claim-id-2"]
}
```

If the user chose **accept**, jump to Phase 5.

---

### Phase 4: Structural Review + Revisor Loop

Read [references/structural-review.md](references/structural-review.md) for the full reviewer/revisor protocol, validation rules, and version-bumping logic.

Maximum **2 iterations** (matches the existing cogni-trends cap). When `cogni-claims` is unavailable, the cap is reduced to **1**.

Each iteration:

#### 4a: Review

```yaml
Task:
  subagent_type: "cogni-trends:trend-report-reviewer"
  description: "Structural review iteration {N}"
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    REPORT_PATH: {current_report_path}
    REVIEW_ITERATION: {N}
    OUTPUT_LANGUAGE: {OUTPUT_LANGUAGE}
    REPORT_TARGET_WORDS: {REPORT_TARGET_WORDS}
```

`REPORT_TARGET_WORDS` is the **prose** target (executive summary + macro sections + synthesis — claims registry excluded). It anchors the reviewer's tier-aware Completeness scoring. Reviews of legacy reports without a recorded target fall back to `4000` (standard tier).

The reviewer scores 5 dimensions (completeness, evidence density, source diversity, narrative coherence, actionability) and returns a verdict:

- `accept` (composite ≥ 0.80) — proceed to Phase 5.
- `revise` — proceed to 4b with `revision_priorities[]`.

#### 4b: Revise (if verdict = revise AND iteration < cap)

Skip 4b if no claims were flagged for fix/drop AND the reviewer's only issues are stylistic (revision_priorities empty). Otherwise, dispatch the revisor:

```yaml
Task:
  subagent_type: "cogni-trends:trend-report-revisor"
  description: "Apply revision iteration {N}"
  prompt: |
    PROJECT_PATH: {PROJECT_PATH}
    REPORT_PATH: {current_report_path}
    CLAIMS_PATH: {PROJECT_PATH}/cogni-claims/claims.json
    NEW_VERSION: {N+1}
    OUTPUT_LANGUAGE: {OUTPUT_LANGUAGE}
    MARKET: {MARKET}
```

Before dispatch, create a backup:

```bash
cp "{PROJECT_PATH}/tips-trend-report.md" "{PROJECT_PATH}/.tips-trend-report-pre-revision-v{N}.md"
```

After the revisor returns, validate the output (heading preservation, claims-table integrity, no `~~` strikethrough markers, no dead references, YAML frontmatter intact, citation count). On validation failure, surface the specific failure to the user — do not auto-rerun.

The revisor writes `tips-trend-report-v{N+1}.md`. Set `current_report_path` to the new versioned file before the next iteration.

#### 4c: Accept

When verdict = `accept` OR iteration reaches cap → proceed to Phase 5 with `current_report_path` as the final canonical version.

---

### Phase 5: Finalize + Downstream Options Menu

Read [references/downstream-options.md](references/downstream-options.md) for the menu structure and option-specific arguments.

#### Step 5.1: Promote final version

If a revision was produced, copy the latest versioned file to the canonical filename (preserving the versioned file alongside it for audit):

```bash
cp "{PROJECT_PATH}/tips-trend-report-v{N}.md" "{PROJECT_PATH}/tips-trend-report.md"
```

#### Step 5.2: Update metadata

Update `{PROJECT_PATH}/.metadata/trend-scout-output.json`:

```json
{
  "trend_report_revised": true,
  "trend_report_revision_version": N,
  "trend_report_revision_at": "ISO-8601",
  "trend_report_claims_removed": N,
  "trend_report_claims_corrected": N,
  "verify_trend_report_complete": true,
  "verify_trend_report_at": "ISO-8601"
}
```

If `tips-trend-report-claims.json` no longer matches the revised registry (revisor renumbers rows), regenerate it from the revised report's claims table.

#### Step 5.3: Display verification summary

```
Verification Complete
─────────────────────
Report:          {PROJECT_PATH}/tips-trend-report.md
Verdict:         {PASS|REVIEW|FAIL}
Claims:          {N} extracted, {N} confirmed, {N} deviated ({N} fixed, {N} dropped)
Review:          {N} iterations, final score {X.XX}
Final version:   {v1|vN}
```

#### Step 5.4: Downstream options menu

Ask the user via `AskUserQuestion` which downstream step they want next. Default selection should be the most common path (polish + visualize); the user can also exit cleanly.

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

Handle the choice:
- **Polish** → invoke `Skill(cogni-copywriting:copywriter, args="FILE_PATH={PROJECT_PATH}/tips-trend-report.md SCOPE=tone STAKEHOLDERS=executive REVIEW_MODE=automated")`. Validate citation count after polish; revert from backup on failure (rules in [references/downstream-options.md](references/downstream-options.md)).
- **Visualize** → invoke `Skill(cogni-visual:enrich-report, args="--source {PROJECT_PATH}/tips-trend-report.md")`.
- **Done** → exit cleanly. Recommend the user run `/trends-resume` to see the full option set (slides, web, storyboard, catalog, dashboard).

The user can re-enter this skill later to pick a different path; downstream skills do not block each other.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| `tips-trend-report.md` missing | HALT: Run `/trend-synthesis` first |
| `tips-trend-report-claims.json` missing | HALT: Re-run `/trend-synthesis` to regenerate claims registry |
| `tips-project.json` missing | HALT: Not a valid cogni-trends project |
| `cogni-claims` not installed | WARNING: Skip Phase 2 + 3, run Phase 4 in structural-review-only mode (max 1 iteration), skip Phase 3 of `references/claims-integration.md` |
| Verification returns FAIL | Present failed claims interactively in Phase 3. Do not auto-correct. |
| Reviewer returns `revise` but no priorities | Treat as `accept` (defensive — cogni-trends reviewer rarely emits this state) |
| Revisor validation fails | Surface specific failure to the user; do not auto-rerun. Backup at `.tips-trend-report-pre-revision-v{N}.md` is canonical. |
| `cogni-copywriting` not installed | Phase 5 menu skips the polish option silently |
| `cogni-visual` not installed | Phase 5 menu skips the visualize option silently |

## Integration

**Upstream:**
- `trend-research` produces the per-dimension enriched evidence and the research manifest
- `trend-synthesis` produces `tips-trend-report.md` and `tips-trend-report-claims.json` (required)

**Pipeline:** `trend-scout → value-modeler → trend-research → trend-synthesis → verify-trend-report`

**Plugin dependencies:**
- `cogni-claims:claims` (recommended) — claim verification
- `cogni-copywriting:copywriter` (optional) — Phase 5 menu option
- `cogni-visual:enrich-report` (optional) — Phase 5 menu option

**Downstream (via `/trends-resume`):** `cogni-visual:story-to-slides`, `cogni-visual:story-to-web`, `cogni-visual:story-to-storyboard`, `trends-catalog import`, `trends-dashboard`

## Debugging

Log files in `{PROJECT_PATH}/.metadata/`:
- `trend-report-verification.json` — verdict and counts
- `user-claims-review.json` — interactive Phase 3 decisions
- `review-verdicts/v{N}.json` — per-iteration reviewer verdicts (existing format from prior trend-report pipeline)

Output files in `{PROJECT_PATH}/`:
- `tips-trend-report.md` — final canonical report (post-revision when revisions ran)
- `tips-trend-report-v{N}.md` — versioned revisions, preserved for audit
- `.tips-trend-report-pre-revision-v{N}.md` — backups created before each revisor pass
