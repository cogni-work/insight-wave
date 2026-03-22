---
title: Deliver Phase Stakeholder Review Protocol
version: 1.0
---

# Deliver Review Protocol

## Purpose

Stress-test the Deliver phase outputs (option scoring, claims verification, business case, roadmap, executive summary) through multi-persona review before transitioning to Export. A weak recommendation, indefensible numbers, or infeasible roadmap discovered during client presentation destroys the entire engagement's credibility — this review catches those failures before they reach the board.

This is a closed-loop quality gate — CRITICAL issues trigger revision before the engagement produces final deliverables.

## Weighted Scoring

Each persona produces PASS/WARN/FAIL verdicts with weighted criteria. Calculate a weighted score per persona:

| Verdict | Score |
|---------|-------|
| PASS | 1.0 |
| WARN | 0.5 |
| FAIL | 0.0 |

**Formula**: Sum of (criterion weight x verdict score) across all 5 criteria.

Example: Implementation Lead gives PASS (30%), WARN (25%), PASS (20%), FAIL (15%), WARN (10%):
Score = (0.30x1.0) + (0.25x0.5) + (0.20x1.0) + (0.15x0.0) + (0.10x0.5) = 0.675

Include the per-persona weighted score in the Per-Persona Scores table.

## Theme Identification Rules

### Priority Escalation

| Pattern | Priority |
|---------|----------|
| 3+ personas flag same issue | CRITICAL |
| 2 personas flag same issue | HIGH |
| CFO/Risk Officer + Board Sponsor on same issue | CRITICAL (financial credibility = board failure) |
| Implementation Lead + End-User Proxy on same issue | CRITICAL (infeasible + undesirable = shelf-ware) |
| Any persona labels FAIL on >=25% criterion | CRITICAL |
| Single persona, high-weight criterion (>=25%) | HIGH |
| Single persona, low-weight criterion (<=15%) | OPTIONAL |

### Theme Caps

Keep the report scannable:
- **CRITICAL**: up to 3 (if more exist, merge the most related ones)
- **HIGH**: up to 3
- **OPTIONAL**: up to 3

Themes that don't make the cut still appear in per-persona sections.

### Semantic Matching

Group concerns that target the same underlying Deliver weakness:

- "Numbers don't add up" = "Assumptions unverified" = "Where's the source for €X?" → Deliver Artifact: Business Case (Financial Model)
- "No sensitivity analysis" = "Only the happy path" = "What if assumptions are wrong?" → Deliver Artifact: Business Case (Sensitivity)
- "Can't execute this" = "Timeline unrealistic" = "Who does this work?" → Deliver Artifact: Roadmap (Feasibility)
- "No decision gates" = "Straight line to completion" = "What if Phase 1 fails?" → Deliver Artifact: Roadmap (Gates)
- "Which option and why?" = "Scoring criteria unclear" = "Bias in scoring" → Deliver Artifact: Option Scoring
- "Claims not verified" = "Deviated claims in exec summary" = "Wrong number on slide 3" → Deliver Artifact: Claims Verification
- "User value lost" = "Board language only" = "Who benefits?" → Deliver Artifact: Executive Summary (User Thread)
- "Recommendation unclear" = "Go or no-go?" = "What do we actually do?" → Deliver Artifact: Executive Summary (Recommendation)
- "No change management" = "Users are last" = "Who trained the staff?" → Deliver Artifact: Roadmap (Adoption)
- "Risks not quantified" = "Medium impact means what?" = "What's the downside in euros?" → Deliver Artifact: Business Case (Risk)

### Artifact Routing

Every synthesized theme must map to one or more Deliver artifacts:

| Theme Category | Primary Artifact | Also Check |
|---|---|---|
| Financial/business case issues | `deliver/business-case.md` | `deliver/claims-verification.md` |
| Claims/evidence issues | `deliver/claims-verification.md` | All deliver artifacts containing factual claims |
| Execution/feasibility issues | `deliver/roadmap.md` | `deliver/business-case.md` (investment section) |
| Scoring/option selection issues | `deliver/option-scoring.md` | `develop/options/option-synthesis.md` |
| Recommendation clarity issues | `deliver/executive-summary.md` | `deliver/business-case.md` (recommendation) |
| User/adoption issues | `deliver/executive-summary.md` | `deliver/roadmap.md` (sequencing) |
| Risk assessment issues | `deliver/business-case.md` (risk section) | `deliver/roadmap.md` (mitigations) |
| Positioning issues | `deliver/positioning-validation.md` | `deliver/option-scoring.md` |
| Narrative/traceability issues | `deliver/executive-summary.md` | `define/problem-statement.md` |

## Conflict Resolution

### Common Deliver Conflicts

| Conflict | Resolution |
|----------|------------|
| Board Sponsor wants bold recommendation vs. CFO wants conservative numbers | CFO wins on numbers — present the conservative case with an upside scenario; bold narrative is fine, but with honest math |
| Implementation Lead says timeline infeasible vs. Board Sponsor says "make it work" | Implementation Lead wins on timeline — adding buffer is cheaper than missing milestones publicly; adjust scope to fit time, not time to fit scope |
| CFO flags business case weakness vs. End-User Proxy flags missing user value | Both: these are independent issues requiring separate fixes; a financially sound business case that ignores users is as dangerous as a user-centered recommendation with bad numbers |
| Board Sponsor wants one clear option vs. Implementation Lead wants phased options | Structure solves this: clear single recommendation in the executive summary, phased delivery detail in the roadmap; both perspectives are met |
| CFO says "numbers work" vs. End-User Proxy says "wrong metric" | Escalate: if the business case measures the wrong outcome, correct numbers don't help; revisit scoring criteria to include the dimension End-User Proxy is flagging |

### Tiebreaker Hierarchy

When personas disagree and no resolution is obvious:

1. **CFO / Risk Officer** — financial credibility is non-negotiable; a recommendation with wrong numbers destroys trust with the board and cannot be recovered
2. **Board Sponsor** — they define what success looks like; a technically perfect recommendation the board rejects is worthless
3. **Implementation Lead** — if it cannot be built, nothing else matters; infeasible plans fail visibly
4. **End-User Proxy** — user value matters but can sometimes be addressed during implementation; it is the most recoverable dimension

## Closed-Loop Decision Logic

After synthesizing persona results, apply this decision framework:

### CRITICAL themes found
1. Identify specific revisions needed for each affected artifact
2. Apply revisions to the artifact(s)
3. Re-run only the persona(s) that flagged CRITICAL issues — don't repeat the full review
4. Maximum 2 iteration rounds — prevents infinite loops
5. After round 2, present any remaining issues to the consultant for decision regardless of severity

### Only HIGH themes
1. Present findings to the consultant with recommended revisions
2. Consultant decides: revise now, accept with noted limitations, or override
3. If consultant accepts, log the decision with rationale in the review summary

### Only OPTIONAL themes
1. Log findings in the review summary as observations
2. Proceed to phase transition (step 10)
3. Include observations in the Deliver summary

## Recommendation Merging

1. Group recommendations by Deliver artifact (use artifact routing table)
2. Within each artifact, assign merged priority (highest from any contributing persona)
3. Combine specific actions into a single actionable recommendation per artifact
4. Track which personas contributed to each recommendation
5. Distinguish between:
   - **Fix in artifact** — the Deliver output needs revision (e.g., "business case missing sensitivity analysis for downside scenario")
   - **Fix in process** — a Deliver method needs improvement (e.g., "scoring criteria should include user impact dimension")
   - **Flag for Export** — cannot be fixed in Deliver but should be noted when generating the final deliverable package (e.g., "executive summary needs visual emphasis on risk conditions")

## Output Structure

```markdown
## Deliver Review Summary

**Personas**: [list of personas used]
**Engagement**: [name] ([vision class])
**Overall assessment**: [1-2 sentence verdict]
**Iteration**: [round N of max 2 / final]

### Per-Persona Scores

| Persona | Verdicts | Weighted Score | Strongest | Weakest |
|---|---|---|---|---|
| Board Sponsor | PASS: N, WARN: N, FAIL: N | 0.XX | [criterion] | [criterion] |
| CFO / Risk Officer | ... | ... | ... | ... |
| Implementation Lead | ... | ... | ... | ... |
| End-User Proxy | ... | ... | ... | ... |

### Cross-Cutting Themes

#### CRITICAL
- **[Theme name]** (Personas: [list]) → Artifact: [X]
  - [Specific finding and recommended action]
  - Fix type: artifact / process / flag-for-export

#### HIGH
- ...

#### OPTIONAL
- ...

### Prioritized Questions

Questions the Deliver outputs should answer but currently don't:
1. [Question] — raised by [persona(s)]
2. ...

### Iteration Decision

- [ ] CRITICAL issues require revision before proceeding
- [ ] HIGH issues presented for consultant decision
- [ ] OPTIONAL issues logged as observations
- [ ] Review outcome: [PASSED / PASSED with observations / PASSED after N rounds]

### Revision History (if iterated)

#### Round 1
- **Issue**: [what was flagged]
- **Revision**: [what was changed]
- **Re-evaluated by**: [persona(s)]
- **Result**: [resolved / escalated]

### Suggested Next Steps

Based on review results:
- [Ordered list of recommended actions before generating deliverables via consulting-export]
```
