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
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Skill, Task
---

# Diamond Deliver — Converge on Outcomes

Evaluate options, verify claims, build the business case, and prepare actionable outcomes. This is the convergence half of Diamond 2 — the goal is to move from a rich option space to validated, decision-ready deliverables.

## Diamond Coach Protocol

Read `$CLAUDE_PLUGIN_ROOT/references/diamond-coach.md` and adopt the Diamond Coach persona.

**Deliver opening**: "We're entering Deliver — the convergent half of Diamond 2. We have options on the table; now we need to evaluate them rigorously, verify our claims, and build the business case. This is where creative ideas become executive-ready recommendations. The goal is actionable outcomes the client can act on Monday morning."

**Prerequisite gate**: Verify that `develop/options/option-synthesis.md` exists and contains at least one named option, OR that `develop/ideation/` contains solution design content (for HMW engagements). If missing:
- Block and redirect: "We need options to evaluate before we can deliver. The Develop phase should produce an option synthesis or solution design. Let's complete that first."
- The consultant can override by explicitly saying "proceed anyway."

**Iteration check**: If `phase_state.deliver.status` is `complete`, this is a re-entry. Read existing artifacts in `deliver/` (solution-brief.md, action-plan.md, business-case.md, etc.). Say: "The Deliver phase was completed previously. Let's refine what we have — what would you like to improve? The business case, the roadmap, the solution brief?" Focus on the specific area.

**Task list**: After loading context, create a task list scaled to engagement weight:

Standard engagement:
1. Load context (options + problem statement)
2. Propose and confirm deliver methods
3. Score and rank options
4. Verify claims (cogni-claims)
5. Validate positioning (cogni-portfolio)
6. Build business case
7. Create action roadmap
8. Write executive summary
9. Stakeholder review
10. Log and transition

Lightweight HMW: Deliver is typically collapsed into Develop — if this skill is invoked separately for a lightweight HMW, use the simplified workflow (see "Lightweight Deliver" section below).

## Core Concept

Deliver transforms creative options into executive-ready outputs. It applies rigor — feasibility scoring, risk assessment, claims verification — to the options generated in Develop, then packages the survivors into the deliverables promised in the engagement vision.

This phase balances two tensions: thoroughness (every claim verified, every risk assessed) and pragmatism (the engagement needs to conclude with actionable recommendations). The consultant manages this tension; cogni-consulting provides the tools. The Diamond Coach actively maintains convergent mode — see "Phase-Mode Coaching" in diamond-coach.md.

## Research Routing Rule

When evidence gaps surface during Deliver — a high claim deviation rate, missing competitive data for the business case, or the consultant asking to research something — **always dispatch cogni-research:research-report** rather than using raw WebSearch. Frame the research as a targeted sprint (mode `basic`) scoped to the specific gap. Store in `deliver/research/` so the outputs feed directly into the business case or roadmap. The only exception is a single-query fact-check during conversation.

## Workflow

### 1. Load Context

Read consulting-project.json, `define/problem-statement.md`, `develop/options/option-synthesis.md`, the vision deliverables list, and all persona files in `personas/`.

**Persona context**: If personas exist, present them as the traceability anchors: "As we evaluate options and build the business case, we need to ensure the recommendation serves the people we identified — [persona names]. The thread from their tensions through HMW questions through options should remain visible in the final deliverables."

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
| Lean canvas stress-test | Multi-persona pressure test of Lean Canvas | `references/methods/lean-canvas-stress-test.md` |

**Note**: For `business-model-hypothesis` vision class, replace opportunity scoring and business case canvas with the lean canvas stress-test as the primary Deliver method. The stress-test runs 4 parallel persona agents (Investor, Customer, Technical, Operations) against the canvas from Develop, then synthesizes findings into a prioritized improvement plan. Read `$CLAUDE_PLUGIN_ROOT/references/methods/lean-canvas-stress-test.md` for the full workflow.

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
5. **Persona-specific adoption paths** (when personas exist): Different personas may need different sequencing. A Schichtleiter might need early quick wins to build trust after a failed tablet initiative, while the IT team needs training before they can support the platform. For each phase, note which personas see value and what changes for them. Sequence user-visible value early — roadmaps that put all technical infrastructure before any persona-facing change create a credibility gap where affected people hear about transformation but see nothing change for months.

Save to `deliver/roadmap.md`. Roadmaps should be realistic — better to under-promise than create shelf-ware.

### 8. Executive Summary

Draft a one-page executive summary synthesizing:
- The engagement vision and problem statement
- Key discovery insights
- **Who this serves** (when personas exist): Trace the recommendation back through specific persona needs. For each key persona: "[Persona] had [tension] — we framed HMW [question] — Option [N] addresses this by [specific mechanism]." This makes the human impact of the recommendation visible alongside the business impact. When no personas exist, describe concretely who benefits and how.
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
10. Design-for personas: {project-dir}/personas/ (all JSON files — the people we design for)

INSTRUCTIONS:
1. Read all files, including any persona files in the personas/ directory
2. Adopt the tone described in your persona profile
3. Evaluate each of your 5 criteria, assigning PASS / WARN / FAIL
4. For each criterion, provide specific evidence from the Deliver artifacts
5. When personas/ files exist, cross-reference them: Does the recommendation address each persona's core tension? Does the "Who this serves" section in the executive summary trace persona needs through HMW questions to the final recommendation? Does the roadmap include persona-specific adoption paths? The traceability thread — persona (Setup) to enrichment (Discover) to HMW (Define) to option (Develop) to recommendation (Deliver) — should be unbroken.
6. Calculate your weighted score: PASS=1.0, WARN=0.5, FAIL=0.0
7. Generate 3-5 questions your stakeholder would ask
8. Identify the single most important issue from your perspective
9. List 2-3 concerns that could block successful delivery or Export

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

Apply the Diamond Coach closing protocol: summarize the full engagement arc (from vision through discovery, problem framing, option generation, to this final evaluation), highlight the key recommendation, and note the strength of the evidence base.

Present the Deliver summary:

> **Deliver phase complete.**
> - Options scored: N (top recommendation: [name])
> - Claims verified: N/N (N deviations resolved)
> - Business case: [go/conditional/no-go]
> - Roadmap: N phases, target completion [date]
> - Review: [PASSED / PASSED with observations / PASSED after N revision rounds]
>
> All four diamond phases are complete. Run `consulting-export` to generate the deliverable package in your chosen formats (PPTX, DOCX, XLSX, Excalidraw).
>
> For visual enrichment of individual deliverables (business case, roadmap, solution brief), run `/enrich-report` on any markdown file to generate themed HTML with concept diagrams and interactive charts.

Mark Deliver complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" deliver complete
```

## Lightweight Deliver (how-might-we)

For `how-might-we` engagements, Deliver produces two focused outputs instead of the full business case pipeline.

**Simplified workflow:**

1. **Load context** — Read the option synthesis from Develop and the original HMW question
2. **Quick scoring** (if multiple options exist) — Use a simplified opportunity scoring: rank each option on impact (1-5), feasibility (1-5), and time-to-start (1-5). No weighted criteria matrix — just a quick comparison to confirm the preferred option. If the consultant already has a clear preference from Develop, skip scoring entirely.
3. **Solution brief** — Write a concise document for the selected solution:
   - The HMW question that framed the challenge
   - What was designed and why (referencing discovery context and design decisions from ideation)
   - How it works — key activities, structure, or process
   - Who is involved and their roles
   - What success looks like — 2-3 observable outcomes
   Save to `deliver/solution-brief.md`
4. **Action plan** — Concrete next steps to make it happen:
   - Phased steps (preparation → execution → follow-up)
   - Owner for each step
   - Timeline with dates
   - Dependencies and prerequisites
   - First action: what happens Monday morning?
   Save to `deliver/action-plan.md`
5. **Skip claims verification** — No cogni-claims dispatch for lightweight engagements unless the consultant requests it
6. **Skip the full persona review** — Confirm deliverables directly with the consultant
7. **Skip business case canvas** — Not needed for bounded challenges

The deliverable package is just two files: the solution brief and the action plan. If the consultant wants a polished version, they can dispatch `consulting-export` to render them as DOCX.

**For collapsed lightweight HMWs**: This phase runs as a continuation of Develop — no phase transition prompt. After the consultant selects their preferred solution from ideation, go directly into the solution brief and action plan. The whole Develop+Deliver sequence should feel like one fluid design session.

## Method Adaptation

For vision-class-specific method recommendations, read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md`.

## When Things Go Thin

- **High claim deviation rate** (>40% of claims): This signals a systemic evidence problem rather than individual errors. Recommend dispatching `cogni-research:research-report` (mode `basic`, tightly scoped to the affected area) rather than patching claims one by one — a structured research sprint is more efficient and produces citable results.
- **Scoring produces a tie or no clear winner**: This usually means the criteria don't capture the real differentiators. Revisit the criteria with the consultant — often one unstated factor (political feasibility, personal conviction) is doing the real work. Surface it and make it explicit.
- **Business case numbers don't work**: This is a finding, not a failure. Present it honestly. The consultant may pivot to a different option, adjust scope, or reframe the investment thesis. Forcing optimistic numbers destroys credibility.

## Important Notes

- Record the reasoning behind the final recommendation in the decision log — "we chose Option 2 because..." is essential for the executive summary and for defending the recommendation
- If the consultant wants to revisit options from Develop, that's healthy — the diamond process is iterative within phases
- **Communication Language**: Use the engagement's language setting for all interactions
