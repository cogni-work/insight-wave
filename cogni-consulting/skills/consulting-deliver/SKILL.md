---
name: consulting-deliver
description: |
  Execute the Deliver phase of a Double Diamond engagement — converge on validated, actionable
  outcomes. Runs final claim verification via cogni-claims, guides business case modeling and
  roadmap construction. Use whenever the user wants to evaluate options, build a business case,
  validate findings, or prepare final recommendations within a diamond engagement.
  Trigger on: "deliver phase", "build the business case", "evaluate options", "score the options",
  "which option is best", "create the roadmap", "finalize", "make a recommendation",
  "validate our claims", "prepare the final output", "wrap up the engagement",
  "what should we recommend", "D2 converge", "convergence", "decision time",
  "let's pick the winner", "finalize options", "validate and deliver",
  or any request to move from options to decisions. Also trigger when the user says
  "I need to present this to the board" or similar — Deliver produces the executive-ready artifacts.
---

# Diamond Deliver — Converge on Outcomes

Evaluate options, verify claims, build the business case, and prepare actionable outcomes. This is the convergence half of Diamond 2 — the goal is to move from a rich option space to validated, decision-ready deliverables.

## Core Concept

Deliver transforms creative options into executive-ready outputs. It applies rigor — feasibility scoring, risk assessment, claims verification — to the options generated in Develop, then packages the survivors into the deliverables promised in the engagement vision.

This phase balances two tensions: thoroughness (every claim verified, every risk assessed) and pragmatism (the engagement needs to conclude with actionable recommendations). The consultant manages this tension; cogni-consulting provides the tools.

## Prerequisites

- Develop phase should be complete (options synthesized in `develop/options/`)
- Read the option synthesis and problem statement as inputs

## Workflow

### 1. Load Context

Read consulting-project.json, `define/problem-statement.md`, `develop/options/option-synthesis.md`, and the vision deliverables list.

Update phase state:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" deliver in-progress
```

### 2. Propose Deliver Methods

**Plugin-powered methods**:

| Method | Plugin | Purpose |
|---|---|---|
| Claims verification | cogni-claims | Final quality gate on all factual assertions |
| Positioning validation | cogni-portfolio | Value Wedge and competitive positioning check |

**Guided methods**:

| Method | Purpose | Reference |
|---|---|---|
| Opportunity scoring | Score options against weighted criteria | `references/methods/opportunity-scoring.md` |
| Business case canvas | Structure financials and assumptions | `references/methods/business-case-canvas.md` |

Ask: "Deliver plan: I recommend scoring options first, then verifying claims, then building the business case. Adjust?"

### 3. Opportunity Scoring (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/opportunity-scoring.md` and guide the consultant:

1. Define 4-6 evaluation criteria (e.g., strategic fit, feasibility, time to value, risk, investment required)
2. Weight the criteria based on engagement constraints
3. Score each option from Develop against the criteria (1-5 scale)
4. Calculate weighted scores and rank options
5. Present the scoring matrix for consultant review

Save to `deliver/option-scoring.md`.

The top 2-3 options advance to business case development. Lower-ranked options are documented as alternatives.

### 4. Claims Verification (cogni-claims)

Collect all factual claims across the engagement:
- From discovery research (`discover/research/`)
- From trend analysis (`discover/trends/`)
- From proposition modeling (`develop/propositions/`)
- From the option synthesis (`develop/options/`)

Submit to cogni-claims for verification. Unverified claims in client deliverables damage credibility — a single wrong number in a board presentation can undermine the entire engagement. This step exists as a quality gate, not bureaucracy.

Present results:

> **Claims verification:**
> - N claims submitted
> - N verified (source confirmed)
> - N deviated (needs correction)
> - N source unavailable (needs alternative source or removal)
>
> Deviated claims require attention before finalizing deliverables.

For each deviated claim, guide the consultant through resolution (correct, replace source, remove, or accept with caveat).

Save the verification log to `deliver/claims-verification.md`.

### 5. Positioning Validation (cogni-portfolio)

If a portfolio project exists:

1. Dispatch `cogni-portfolio:portfolio-verify` on the portfolio data
2. Check Value Wedge sharpness — do propositions create clear differentiation?
3. Review competitive positioning — are claims defensible against identified competitors?
4. Note any positioning weaknesses

Store validation summary in `deliver/positioning-validation.md`.

### 6. Business Case Canvas (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/business-case-canvas.md` and guide the consultant through building a business case for the top-ranked option(s):

1. **Investment required**: What resources, budget, and timeline are needed?
2. **Expected returns**: Revenue, cost savings, or strategic value created
3. **Key assumptions**: What must be true? (cross-reference with verified claims)
4. **Risk factors**: What could go wrong? Mitigation strategies?
5. **Sensitivity analysis**: How do outcomes change if assumptions shift?
6. **Recommendation**: Go/no-go with rationale

**Example** (cost-optimization engagement for service delivery savings):
> **Investment**: €350K implementation over 6 months (process redesign + tooling)
> **Expected returns**: €1.2M annual savings from 3 consolidated service tiers
> **Key assumption**: 80% of Tier-1 tickets can be automated (verified via cogni-claims against industry benchmark)
> **Risk**: Union pushback on role changes (medium probability, high impact) — mitigated by retraining program
> **Recommendation**: Conditional go — proceed with Tier-1 automation pilot, gate full rollout on pilot KPIs

Save to `deliver/business-case.md`. The business case should be honest — if the numbers don't work, say so. A credible "conditional go" is worth more than an optimistic "go" that falls apart in execution.

### 7. Action Roadmap

Build a phased implementation roadmap for the recommended option(s):

1. Define phases (e.g., Quick wins → Foundation → Scale → Optimize)
2. Assign milestones and target dates
3. Identify owners and dependencies
4. Note decision points and go/no-go gates

Save to `deliver/roadmap.md`. Roadmaps should be realistic — better to under-promise than create shelf-ware.

### 8. Executive Summary

Draft a one-page executive summary synthesizing:
- The engagement vision and problem statement
- Key discovery insights
- Recommended option(s) with rationale
- Business case highlights
- Immediate next steps

Save to `deliver/executive-summary.md`. This becomes the anchor document for the deliverable package.

### 9. Stakeholder Review

Before transitioning to Export, stress-test the Deliver outputs against four stakeholder perspectives. A weak recommendation, indefensible numbers, or infeasible roadmap discovered during client presentation — or worse, during board review — wastes the entire engagement's credibility. This review catches those failures while they are still fixable.

#### 9a. Launch Parallel Persona Review

Launch one Task agent per persona. Each reads the Deliver artifacts and evaluates from their perspective.

| Persona | Focus | Reference |
|---|---|---|
| Board Sponsor | Board-readiness, recommendation clarity, number defensibility | `references/personas/board-sponsor.md` |
| CFO / Risk Officer | Business case soundness, claims verification, risk quantification | `references/personas/cfo-risk-officer.md` |
| Implementation Lead | Roadmap feasibility, resource realism, dependency mapping | `references/personas/implementation-lead.md` |
| End-User Proxy | User value preservation, adoption feasibility, scoring user dimension | `references/personas/end-user-proxy.md` |

**For each persona, launch a Task with this prompt:**

```
You are a {PERSONA_NAME} reviewing the Deliver phase outputs of a Double Diamond engagement.

FILES TO READ (use Read tool):
1. Option scoring: {project-dir}/deliver/option-scoring.md
2. Claims verification: {project-dir}/deliver/claims-verification.md
3. Business case: {project-dir}/deliver/business-case.md
4. Roadmap: {project-dir}/deliver/roadmap.md
5. Executive summary: {project-dir}/deliver/executive-summary.md
6. Positioning validation: {project-dir}/deliver/positioning-validation.md (if exists)
7. Problem statement: {project-dir}/define/problem-statement.md (for traceability)
8. Diamond project: {project-dir}/consulting-project.json (for engagement context)
9. Your persona profile: {absolute path to references/personas/{persona}.md}

INSTRUCTIONS:
1. Read all files
2. Adopt the tone described in your persona profile
3. Evaluate each of your 5 criteria, assigning PASS / WARN / FAIL
4. For each criterion, provide specific evidence from the Deliver artifacts
5. Calculate your weighted score: PASS=1.0, WARN=0.5, FAIL=0.0
6. Generate 3-5 questions your stakeholder would ask
7. Identify the single most important issue from your perspective
8. List 2-3 concerns that could block successful delivery or Export

OUTPUT FORMAT (Markdown):

## {PERSONA_NAME} Evaluation

### Criteria Assessment

| Criterion | Weight | Verdict | Evidence |
|---|---|---|---|
| {criterion 1} | {weight}% | {PASS/WARN/FAIL} | {specific evidence from Deliver artifacts} |
| ... | ... | ... | ... |

**Score**: {weighted score}/1.0 — {count PASS} pass, {count WARN} warn, {count FAIL} fail

### Top Questions
1. {Question a real stakeholder would ask}
2. ...

### Critical Issue
{The single most important concern, with specific suggestion}

### Export Blockers
- {Concern that could block deliverable quality or board presentation} — {one-line rationale}
- ...
```

**Agent configuration**: Use a fast model (haiku or sonnet), Read tool only. Launch all 4 persona agents in the same turn for parallel execution.

#### 9b. Synthesize and Decide

Read `references/review-protocol.md` and apply it to the persona results:

1. Calculate per-persona weighted scores
2. Identify cross-cutting themes using semantic matching
3. Apply priority escalation rules
4. Route themes to Deliver artifacts
5. Resolve conflicts using the tiebreaker hierarchy

**Decision logic**:
- **CRITICAL themes**: Revise affected artifact(s), then re-run only the persona(s) that flagged CRITICAL (max 2 rounds)
- **HIGH themes**: Present to consultant — they decide whether to revise or accept with noted limitations
- **OPTIONAL only**: Log findings as observations, proceed to step 10

Save the full review results to `deliver/review-summary.md`.

#### 9c. Iterate (if needed)

If CRITICAL issues triggered revision:

1. Apply specific revisions to the affected artifacts (business-case.md, roadmap.md, executive-summary.md, etc.)
2. Re-run only the persona(s) that flagged CRITICAL — don't repeat the full review
3. After round 2, present any remaining issues to the consultant regardless of severity — they get final say
4. Log iteration history in the review summary (what was flagged, what was revised, what was the re-evaluation result)

This keeps the "warn, not block" principle intact — the review enforces a quality bar but the consultant always has the last word.

### 10. Log and Transition

Update method log and decision log.

Present the Deliver summary:

> **Deliver phase complete.**
> - Options scored: N (top recommendation: [name])
> - Claims verified: N/N (N deviations resolved)
> - Business case: [go/conditional/no-go]
> - Roadmap: N phases, target completion [date]
> - Review: [PASSED / PASSED with observations / PASSED after N revision rounds]
>
> All four diamond phases are complete. Run `consulting-export` to generate the deliverable package in your chosen formats (PPTX, DOCX, XLSX, Excalidraw).

Mark Deliver complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" deliver complete
```

## Method Adaptation

For vision-class-specific method recommendations, read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md`.

## When Things Go Thin

- **High claim deviation rate** (>40% of claims): This signals a systemic evidence problem rather than individual errors. Recommend the consultant revisit Discovery for the affected area — patching 15 claims one by one is less efficient than a targeted research sprint.
- **Scoring produces a tie or no clear winner**: This usually means the criteria don't capture the real differentiators. Revisit the criteria with the consultant — often one unstated factor (political feasibility, personal conviction) is doing the real work. Surface it and make it explicit.
- **Business case numbers don't work**: This is a finding, not a failure. Present it honestly. The consultant may pivot to a different option, adjust scope, or reframe the investment thesis. Forcing optimistic numbers destroys credibility.

## Important Notes

- Record the reasoning behind the final recommendation in the decision log — "we chose Option 2 because..." is essential for the executive summary and for defending the recommendation
- If the consultant wants to revisit options from Develop, that's healthy — the diamond process is iterative within phases
- **Communication Language**: Use the engagement's language setting for all interactions
