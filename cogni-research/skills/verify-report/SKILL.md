---
name: verify-report
description: |
  Verify claims in a research report against their cited sources using cogni-claims.
  Auto-detects draft, sources, and prior claim verdicts inside a cogni-research project
  directory, or runs against any standalone markdown report with inline citations. Use
  whenever the user says "verify report", "verify claims", "check sources", "fact-check
  the report", "run claims verification", "check the citations", wants to re-verify after
  editing a report, or simply says "verify" after a research-report run finishes. Also
  trigger when a research-report Phase 6 summary recommends it.
allowed-tools: Read, Write, Edit, Glob, Grep, Task, Skill, AskUserQuestion
---

# Verify Report Skill

Claims verification is the quality gate that separates evidence-backed research from plausible-sounding prose. This skill runs in a **fresh context window** — separate from the research pipeline — so that claims extraction, source verification, and the review loop get the full attention they deserve without competing for context with research data.

When this skill loads:
1. If a cogni-research project exists in the working directory → auto-detect and proceed (Mode A)
2. If the user provides a path to a markdown file → standalone verification (Mode B)
3. If neither → ask: "Which report should I verify? Provide a project path or markdown file."

## Prerequisites

- **cogni-claims** plugin installed (required — this skill has no fallback)
- For Mode A: a cogni-research project with at least `output/draft-v1.md` or `output/report.md`
- For Mode B: a markdown file with inline citations containing source URLs

## Workflow

### Phase 0: Locate and Load Report

#### Mode A — cogni-research project

A project directory contains entity directories (`00-sub-questions/`, `01-contexts/`, etc.) and `.metadata/project-config.json`. This skill loads only the draft and source entities — not sub-questions or contexts — keeping the context window lean for verification work.

1. **Find the project directory.** Search strategy:
   - Check if cwd contains `.metadata/project-config.json`
   - Scan subdirectories one level deep for `.metadata/project-config.json`
   - If multiple found, list them and ask the user to choose
   - If none found, ask the user for the path
2. Read `.metadata/project-config.json` for report type, topic, language
3. Read `.metadata/execution-log.json` for phase completion state
4. **Locate the report to verify**, in priority order:
   - Highest `output/draft-v{N}.md` (latest draft, even if not finalized)
   - `output/report.md` (finalized report, for re-verification after user edits)
5. **Load source entities** from `02-sources/data/` to build source lookup (URL → entity). This is the only research data loaded — sub-questions and contexts are NOT loaded
6. Check for existing verification state → proceed to Phase 0.5

#### Mode B — standalone markdown file

When the user provides a path to a markdown file outside a cogni-research project:

1. Create a lightweight verification workspace: `.verify-report/{slug}/` as a sibling to the markdown file
2. Within the workspace, create: `03-report-claims/data/`, `.metadata/`, `cogni-claims/`
3. No source entities exist — claim-extractor will extract source URLs directly from inline citations
4. Set `standalone_mode = true` in `.metadata/project-config.json`

**Read**: `references/standalone-mode.md` for citation detection patterns and workspace layout.

### Phase 0.5: Resumability Check

If previous verification artifacts exist, present the user with options rather than silently re-running or silently resuming:

**No prior verification** (no `03-report-claims/data/` content, no `cogni-claims/claims.json`):
→ Proceed to Phase 1.

**Claims extracted but not submitted** (`03-report-claims/data/` has entities, `cogni-claims/claims.json` absent):
→ Resume from Phase 2 (submission).

**Verification incomplete** (`cogni-claims/claims.json` exists with `status: pending` claims):
→ Resume from Phase 2 mid-point (verification).

**Previous verification complete** (`cogni-claims/claims.json` exists with completed results):

> **Previous verification found**
> - Claims verified: N | Confirmed: N | Deviations: N
> - Verified at: {timestamp}
>
> Options:
> - **re-verify** — clear previous results, re-extract claims from current draft, full verification
> - **inspect** — show previous results without re-running (opens cogni-claims dashboard)
> - **continue** — keep existing results, proceed to review loop

Handle the user's choice:
- **re-verify**: clear `03-report-claims/data/` contents and `cogni-claims/claims.json`, proceed to Phase 1
- **inspect**: `Skill(cogni-claims:claims, mode=dashboard, working_dir=<project_path>)`, then stop
- **continue**: proceed to Phase 3 (interactive review) with existing verification data

### Phase 1: Claim Extraction

Spawn the claim-extractor agent to identify verifiable factual claims in the draft:

```
Task(claim-extractor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH=<resolved draft path>,
  DRAFT_VERSION=<N>)
```

The claim-extractor creates report-claim entities in `03-report-claims/data/`, each linking a factual statement to its cited source URL. It prioritizes statistical claims, attribution claims, causal claims, and definitional claims — in that order.

After extraction, report to the user:
> Extracted **N** verifiable claims from the draft (N skipped — unsourced or general knowledge).

### Phase 2: Claims Submission + Verification

#### 2a: Submit claims to cogni-claims

**Read**: `references/claims-integration.md` for the cogni-claims submission protocol.

Collect report-claim entities from `03-report-claims/data/` and submit as a batch:

```
Skill(cogni-claims:claims, mode=submit,
  working_dir=<project_path>,
  claims=[...extracted claims from report-claim entities...],
  submitted_by="cogni-research/verify-report")
```

#### 2b: Verify claims against sources

```
Skill(cogni-claims:claims, mode=verify,
  working_dir=<project_path>)
```

cogni-claims dispatches claim-verifier agents (one per unique source URL) that fetch each source, compare claims against actual content, and detect 5 deviation types: misquotation, unsupported_conclusion, selective_omission, data_staleness, source_contradiction.

#### 2c: Update report-claim entities

After verification, read `cogni-claims/claims.json` and update report-claim entities:
- Set `verification_status` to verified/deviated/source_unavailable
- Set `deviation_type` and `deviation_severity` if deviated
- Set `claims_submission_id` to the cogni-claims claim ID

### Phase 3: Interactive Claims Review

Present verification results to the user before proceeding to automated review. This ensures the user has visibility into what was verified and can steer corrections.

1. Read `{PROJECT_PATH}/cogni-claims/claims.json` for verification results
2. Summarize results into a compact overview
3. For each deviated claim: include the claim statement, what the source actually says, deviation type, and severity
4. Present to the user via `AskUserQuestion`:

> **Claims Verification Results**
>
> Verified: N | Confirmed: N | Deviations: N | Sources unavailable: N
>
> **Deviations found:**
> 1. [claim statement] — *[deviation_type]* ([severity]): [explanation]
> 2. ...
>
> Options:
> - **proceed** — pass deviations to reviewer + revisor for automated correction
> - **fix: 1, 3** — flag specific claims for mandatory correction
> - **drop: 2** — remove specific claims from the report entirely
> - **accept** — mark report as verified, finalize without revision
> - **inspect: 2** — open cogni-claims inspect mode for claim 2 (detailed source comparison in browser)
>
> How would you like to proceed?

5. Process user response:
   - `proceed` → continue to Phase 4 with all deviations as reviewer input
   - `fix: N, M` → add flagged claims to a mandatory-fix list passed to the reviewer
   - `drop: N` → add to a drop list; revisor will remove these claims from the report
   - `accept` → skip Phase 4, proceed directly to Phase 5 (finalization)
   - `inspect: N` → `Skill(cogni-claims:claims, mode=inspect, claim_id=<id>)`, then re-present options
6. Store user decisions in `.metadata/user-claims-review.json`:
```json
{
  "reviewed_at": "<ISO timestamp>",
  "total_claims": 25,
  "confirmed": 20,
  "deviated": 4,
  "source_unavailable": 1,
  "user_action": "proceed|fix|drop|accept",
  "fix_claims": ["claim-id-1", "claim-id-3"],
  "drop_claims": ["claim-id-2"]
}
```

### Phase 4: Review + Revision Loop

This phase runs only if the user chose **proceed** or **fix** in Phase 3. The reviewer receives the draft + claims data + user decisions — no research data, keeping context focused.

**Read**: `references/review-criteria.md` for the scoring rubric (shared with research-report).

Maximum 3 iterations — beyond this, returns diminish sharply because the reviewer and revisor start cycling on the same issues, and accumulated context from multiple draft versions saturates the window. Each iteration:

#### 4a: Review

```
Task(reviewer,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH=<current draft path>,
  CLAIMS_DASHBOARD=<project_path>/cogni-claims/claims.json,
  USER_CLAIMS_REVIEW=<project_path>/.metadata/user-claims-review.json,
  REVIEW_ITERATION=N,
  OUTPUT_LANGUAGE=<output_language>)
```

The reviewer scores the draft on 5 structural dimensions (completeness, coherence, source diversity, depth, clarity) and multiplies by the claims verification rate. It flags high/critical deviations as mandatory fixes and applies user override decisions.

#### 4b: Revise (if verdict="revise" and iteration < 3)

```
Task(revisor,
  PROJECT_PATH=<project_path>,
  DRAFT_PATH=<current draft path>,
  VERDICT_PATH=".metadata/review-verdicts/v{N}.json",
  NEW_DRAFT_VERSION=<N+1>,
  OUTPUT_LANGUAGE=<output_language>,
  MARKET=<market>)
```

After revision:
1. Clear `03-report-claims/data/` (revised claims may differ)
2. Re-run Phase 1 (claim extraction on new draft)
3. Re-run Phase 2 (re-submit and re-verify)
4. Re-run Phase 3 (present new results to user)
5. Continue to next review iteration

#### 4c: Accept

When verdict="accept" or iteration reaches 3: proceed to Phase 5.

### Phase 5: Finalization

1. Copy the accepted draft to `output/report.md` (overwrite if exists)
2. Update `.metadata/execution-log.json`:
   - `phase_5_review.claims_verification`: actual verification stats (not "deferred" or "skipped")
   - `phase_5_review.verification_rate`: N.NN
   - `phase_5_review.review_iterations`: N
   - `phase_5_review.final_score`: N.NN
   - `phase_5_review.verified_by`: "verify-report"
3. Report summary to user:

> **Verification Complete**
>
> - Claims: N extracted, N confirmed, N deviated (N fixed), N sources unavailable
> - Verification rate: X.XX
> - Review iterations: N, final score: X.XX
> - Verified report: `output/report.md`

4. **Recommend next steps** — two independent downstream paths:

> **Next steps**
> The report is now fact-checked. Two independent downstream paths:
>
> **Polish & Visualize** (most common — keeps the research report format):
> 1. `/copywrite` — Polish for executive readability (BLUF, tighter prose)
> 2. `/story-to-infographic` + `/render-infographic` — Infographic header (Pencil, 10-step validated)
> 3. `/enrich-report` — Themed HTML with charts (reuses infographic from step 2)
>
> **Narrative path** (alternative — transforms the report into a story-arc document):
> - `/cogni-narrative:narrative` — Executive narrative with story arc framework

## Error Recovery

| Scenario | Recovery |
|----------|----------|
| cogni-claims not installed | Log warning: "cogni-claims unavailable — running structural review only". Skip Phases 2a-2c and Phase 3 (claims submission, verification, interactive review). Run Phase 4 reviewer with structural criteria only (no claims data). Reduce max review iterations from 3 to 2. Recommend installing cogni-claims in Phase 5 next steps. See `references/claims-integration.md` Graceful Degradation section |
| All source URLs unreachable | Report results with source_unavailable count. Suggest user run `/claims cobrowse` for interactive recovery, or check URLs manually |
| Claim extraction produces 0 claims | The draft may lack inline citations. Suggest re-running research-report writer with citation requirements |
| Review loop reaches max (3) | Accept current draft with quality warning |
| Project directory not found | Ask user for explicit path |

## References Index

| Reference | Read When |
|-----------|-----------|
| `references/claims-integration.md` | Phase 2 — cogni-claims submission + verification protocol |
| `references/standalone-mode.md` | Phase 0 Mode B — standalone markdown verification |
| `references/review-criteria.md` | Phase 4 — understanding review scoring (shared with research-report) |

Note: `references/review-criteria.md` is a symlink to `../research-report/references/review-criteria.md` — both skills share the same scoring rubric.
