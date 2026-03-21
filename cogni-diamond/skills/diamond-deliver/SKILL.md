---
name: diamond-deliver
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

This phase balances two tensions: thoroughness (every claim verified, every risk assessed) and pragmatism (the engagement needs to conclude with actionable recommendations). The consultant manages this tension; cogni-diamond provides the tools.

## Prerequisites

- Develop phase should be complete (options synthesized in `develop/options/`)
- Read the option synthesis and problem statement as inputs

## Workflow

### 1. Load Context

Read diamond-project.json, `define/problem-statement.md`, `develop/options/option-synthesis.md`, and the vision deliverables list.

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

### 9. Log and Transition

Update method log and decision log.

Present the Deliver summary:

> **Deliver phase complete.**
> - Options scored: N (top recommendation: [name])
> - Claims verified: N/N (N deviations resolved)
> - Business case: [go/conditional/no-go]
> - Roadmap: N phases, target completion [date]
>
> All four diamond phases are complete. Run `diamond-export` to generate the deliverable package in your chosen formats (PPTX, DOCX, XLSX, Excalidraw).

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
