---
name: research-resume
description: |
  Resume, continue, or check status of a cogni-research project.
  Use whenever the user mentions "continue research", "resume research",
  "research status", "where was I with the report", "research progress",
  "what's next for research", "pick up where I left off", "show research project",
  "how far is the research", "check research", "open research session",
  or opens a session involving an existing cogni-research project —
  even if they don't say "resume" explicitly.
allowed-tools: Read, Glob, Grep, Bash, Skill
---

# Research Resume

Session entry point for returning to research work. This skill orients the user by showing where they left off and what to do next — the dashboard view that keeps multi-session research projects on track.

## Core Concept

Research projects span multiple sessions. Web research, writing, structural review, and claims verification each consume significant context. Without a clear re-entry point, users lose track of what phase they reached and what to do next. This skill bridges that gap: it reads project state from `execution-log.json`, entity directories, and output files, then surfaces progress at a glance and recommends the most valuable next step.

This skill is read-only — it never creates or modifies project files.

## Workflow

### 1. Find Research Projects

Search for cogni-research projects in the workspace:

```
Glob pattern: **/.metadata/project-config.json
```

For each match, read the file and keep only those where the `plugin` field equals `"cogni-research"` (other plugins also use `.metadata/project-config.json`).

If no projects are found, tell the user no research project was found in this workspace and dispatch `Skill("research-setup")` to start one. Do not ask the user to re-issue a command — the handoff should be seamless.

### 2. Select Project

- **One project found** — use it automatically.
- **Multiple projects found** — present them with topic, report type, source mode, and creation date. Ask which one to continue.

### 3. Read Status Data

Since cogni-research has no `project-status.sh`, read the project state directly from files. Gracefully skip any file that does not exist — the project may be in an early phase.

**A. Read `.metadata/project-config.json`:**
- `topic`, `report_type`, `output_language` (fall back to `language`), `market`, `tone`, `citation_format`, `report_source`, `researcher_role`, `created_at`

**B. Read `.metadata/execution-log.json`** (may not exist for freshly initialized projects):
- `phases` object — check each phase key for its `status` field:
  - `phase_0_init`
  - `phase_0.5_preliminary_search`
  - `phase_1_sub_questions`
  - `phase_2_research`
  - `phase_3_aggregation`
  - `phase_4_writing`
  - `phase_5_review` (includes `iterations`, `final_score`, `final_verdict`)
  - `phase_6_finalization`
- `summary` — `word_count`, `sections`, `sources_cited`, `final_review_score`, `claims_verified`
- `cost_summary` — `total_estimated_usd` and `breakdown`
- `enrich_report_applied`, `enrich_report_path`

**C. Count entity files via Glob:**
- Sub-questions: `{project_path}/00-sub-questions/data/*.md`
- Contexts: `{project_path}/01-contexts/data/*.md`
- Sources: `{project_path}/02-sources/data/*.md`
- Report claims: `{project_path}/03-report-claims/data/*.md`

**D. Check output files:**
- Glob `{project_path}/output/draft-v*.md` — find the highest version number
- Check `{project_path}/output/report.md` — finalized report exists?

**E. Check claims verification state:**
- Read `.metadata/user-claims-review.json` if it exists — contains user decisions on deviations
- Check whether `execution-log.json` has `phase_5_review.claims_verification` set (it reads `"deferred to verify-report"` when research-report finishes without verification)

**F. Detect downstream actions already performed:**

Downstream plugins leave filesystem traces when they process research output. Check these signals so the dashboard and next-steps can reflect what the user has already done — even across sessions:

- `copywrite_applied`: `{project_path}/output/.report.md` exists (cogni-copywriting creates this hidden backup before overwriting the report in-place)
- `narrative_applied`: `{project_path}/output/insight-summary.md` exists AND its YAML frontmatter contains an `arc_id` field (the `arc_id` distinguishes a genuine narrative output from a user-created file with the same name)
- `enrich_report_standalone`: `{project_path}/output/report-enriched.html` exists (standalone enrich-report run after Phase 6; Phase 5.5 enrichment is already covered by `enrich_report_applied` in execution-log)
- `narrative_enriched`: `{project_path}/output/insight-summary-enriched.html` exists
- `narrative_polished`: `{project_path}/output/.insight-summary.md` exists (copywriter backup for narrative)

### 4. Present Dashboard

Show a concise, scannable summary. Keep the tone warm and oriented toward action — this is a welcome-back moment, not a status report.

**Project Header:**

```
Research Project: {topic}
Type: {report_type} | Source: {report_source} | Tone: {tone}
Market: {market} | Language: {output_language} | Citations: {citation_format}
Created: {created_at}
```

**Phase Progress Table:**

| Phase | Status | Details |
|-------|--------|---------|
| Setup | Done / Pending | {report_type}, {tone}, {citation_format} |
| Preliminary Search | Done / Pending / Skipped | grounding context |
| Sub-Questions | Done / Pending | {N} generated (target: {expected for report_type}) |
| Research | Done / Partial / Pending | {contexts_count}/{sub_questions_count} contexts, {sources_count} sources |
| Source Curation | Done / Skipped | auto for detailed/deep with 8+ sources |
| Aggregation | Done / Pending | merged context |
| Writing | Done / Pending | draft-v{N}, {word_count} words |
| Structural Review | Done / Pending | score: {final_score}, {iterations} iteration(s) |
| Finalization | Done / Pending | output/report.md |
| Claims Verification | Done / Deferred / Pending | {claims_count} claims |
| Visual Enrichment | Done / Skipped | themed HTML |

Status values: `Done`, `Partial` (some sub-tasks failed or incomplete), `Pending` (not yet started), `Skipped` (not applicable for this config), `Deferred` (intentionally postponed).

Derive status from execution-log phase entries and entity file counts. When execution-log is missing, reconstruct from file system: sub-questions exist means Phase 1 done, contexts exist means Phase 2 at least partial, etc.

**Entity Counts** (compact, below the table):
```
Entities: {N} sub-questions | {N} contexts | {N} sources | {N} claims
```

**Review Score** (if structural review data exists):
```
Review: structural {final_score} ({iterations} iteration) | claims: {deferred/done/pending}
```

**Cost Tracking** (if cost_summary exists in execution-log):
```
Cost: ${total_estimated_usd} (researchers ${N}, writer ${N}, reviewer ${N})
```

**Downstream Actions** (only show when the project is fully complete — condition 10 in the decision tree):
```
Downstream: Copywrite {Done/—} | Narrative {Done/—} | Enrich-report {Done/—}
```
Use "Done" when the Step 3F detection signal is positive, "—" when absent. This gives the user an instant read on what's left to do.

### 5. Health Checks

Apply these checks after the dashboard and surface warnings before recommending next actions:

1. **Partial research**: If sub-questions exist but contexts count is less than sub-questions count, warn: "Research partially complete — {N} of {M} sub-questions have contexts. Some researchers may have failed or timed out."

2. **Stale verification**: If `output/report.md` exists and claims verification data exists, compare the report file modification time against the verification timestamp. If the report is newer, warn: "Report was modified after claims verification — verified claims may no longer match the current draft. Consider re-running `/verify-report`."

3. **Review oscillation**: If `execution-log.json` shows `phase_5_review.iterations` >= 3 and the final verdict is still `"revise"`, warn: "Structural review reached maximum iterations without acceptance. The report may need manual attention or a topic refinement."

4. **Missing verification**: If Phase 6 is complete (report finalized) but no claims data exists in `03-report-claims/data/`, flag: "Report finalized but claims never verified. Run `/verify-report` for source fact-checking."

5. **Aged project**: If `created_at` is more than 30 days ago and the project is not finalized, flag: "Project is {N} days old. Web sources may have changed — consider re-running research if source currency matters."

### 6. Recommend Next Action

Evaluate the decision tree in priority order (first match wins). Offer to proceed with the recommendation immediately via `Skill(...)`. Do not ask the user to re-type a command — the dispatch should be seamless.

| # | Condition | Action | Dispatch |
|---|-----------|--------|----------|
| 1 | No `project-config.json` found | Start a new project | `Skill("research-setup")` |
| 2 | Config exists, no execution-log and no entity files | Research not started yet | `Skill("research-report")` |
| 3 | Sub-questions exist but contexts partial (count mismatch or failed status) | Resume research — some sub-questions still need contexts | `Skill("research-report")` |
| 4 | Sub-questions exist but zero contexts | Research generated questions but hasn't run yet | `Skill("research-report")` |
| 5 | Contexts complete but no draft in `output/` | Research done, ready to write the report | `Skill("research-report")` |
| 6 | Draft exists but no structural review data | Draft written, structural review pending | `Skill("research-report")` |
| 7 | Review verdict is `"revise"` and iterations < max | Continue the review cycle | `Skill("research-report")` |
| 8 | Report finalized, no claims verification | Verify claims against cited sources | `Skill("verify-report")` |
| 9 | Claims verified with unresolved deviations | Continue claims review | `Skill("verify-report")` |
| 10 | All complete | Present downstream options (see below) | User choice |

For conditions 2-7, research-report has built-in resumption logic — it reads `execution-log.json` and resumes from the first incomplete phase. The dispatch is seamless.

**Dependency guidance** to include when explaining the recommendation:
- Verify before polish: running copywrite on unverified claims wastes effort if claims get revised
- Verify before narrative: narrative transformation should use the verified draft
- Polish before visual enrichment: enrich-report should use the polished prose
- Infographic before enrichment: running story-to-infographic first gives enrich-report a Pencil-rendered header (10-step validation, reviewer agent) instead of its simplified inline distillation
- Narrative is NOT a precondition for enrich-report — they are independent paths

### Downstream Options for Completed Reports

When the project is fully complete (report finalized + claims verified or user chose to skip verification), present downstream options. Use the detection data from Step 3F to determine which actions have already been performed.

For each downstream action below, check its Step 3F signal. Already-completed actions: acknowledge briefly (e.g., "Report already polished") but do not offer to re-run. Available actions: present as actionable next steps with dispatch offer.

**Path A — Polish & Visualize** (keeps the research report format):
1. `cogni-copywriting:copywrite` — Polish report for executive readability (BLUF, tighter prose, consistent tone)
   - If `copywrite_applied` is true: show "Report already polished" instead of offering this step
2. `cogni-visual:story-to-infographic` + `/render-infographic` — Create an editorial infographic from the report (optional, for premium Pencil-rendered visual header with 10-step validation)
3. `cogni-visual:enrich-report` — Themed HTML with interactive charts and concept diagrams (detects and reuses existing infographic if step 2 was done; otherwise generates a simplified infographic inline)
   - If `enrich_report_applied` (from execution-log) or `enrich_report_standalone` is true: show "Enriched HTML already generated" instead

**Path B — Narrative transformation** (converts to story-arc document):
- `cogni-narrative:narrative` — Transform into executive narrative with story arc framework
  - If `narrative_applied` is true: show "Narrative already generated (output/insight-summary.md)" instead
- After narrative: optionally polish with `cogni-copywriting:copywrite`, then visualize with `cogni-visual:enrich-report`
  - Post-narrative polish: detected via `narrative_polished` (`output/.insight-summary.md` exists)
  - Post-narrative enrichment: detected via `narrative_enriched` (`output/insight-summary-enriched.html` exists)

**Other:**
- `verify-report` — Verify claims against cited sources (if not yet done)
- `research-setup` — Start a new research project

If all downstream actions have been completed, say so explicitly: "All downstream processing complete — report polished, narrative generated, enriched HTML produced." Offer only `research-setup` as the next action.

Highlight the top 2-3 most impactful *available* (not-yet-done) actions. Offer to proceed with the user's choice immediately.

## Phase Reference

| Phase Key | Plain Language | Skill |
|-----------|---------------|-------|
| `phase_0_init` | Project initialized | research-setup |
| `phase_0.5_preliminary_search` | Grounding search complete | research-report |
| `phase_1_sub_questions` | Research questions generated | research-report |
| `phase_2_research` | Parallel research complete | research-report |
| `phase_3_aggregation` | Context merged | research-report |
| `phase_4_writing` | Report drafted | research-report |
| `phase_5_review` | Structural review complete | research-report |
| `phase_6_finalization` | Report finalized | research-report |
| claims verification | Claims fact-checked | verify-report |
| visual enrichment | Themed HTML generated | cogni-visual:enrich-report |

## Multi-Session Design

This skill is the recommended re-entry point after research sessions. Research work naturally spans multiple sessions — web research and writing saturate context, and claims verification runs in a separate context window by design.

When presenting the status summary, acknowledge what the user accomplished in previous sessions if recent timestamps suggest productive recent work. This continuity helps users feel their work persists and builds confidence in the multi-session workflow.

Other research skills should recommend `/research-resume` when they detect a heavy session is complete (Phase 6 finalization, or verify-report completion).

## Language Support

Read `output_language` from `project-config.json`. If not set, fall back to `language` field, then to English.

Communicate with the user in this language for status messages, instructions, and recommendations. Technical terms, skill names, and CLI commands remain in English.
