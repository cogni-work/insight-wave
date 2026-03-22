---
title: Develop Phase Stakeholder Review Protocol
version: 1.0
---

# Develop Review Protocol

## Purpose

Stress-test the Develop phase outputs (option synthesis, TIPS solutions, portfolio propositions, scenario matrix) through multi-persona review before transitioning to Deliver. Identify cross-cutting concerns about the option space, resolve conflicts, and either iterate on artifacts or proceed with documented observations.

This is a closed-loop quality gate — CRITICAL issues trigger revision before the engagement moves to Deliver's convergent evaluation.

## Weighted Scoring

Each persona produces PASS/WARN/FAIL verdicts with weighted criteria. Calculate a weighted score per persona:

| Verdict | Score |
|---------|-------|
| PASS | 1.0 |
| WARN | 0.5 |
| FAIL | 0.0 |

**Formula**: Sum of (criterion weight x verdict score) across all 5 criteria.

Example: Solution Architect gives PASS (30%), WARN (25%), PASS (20%), PASS (15%), FAIL (10%):
Score = (0.30x1.0) + (0.25x0.5) + (0.20x1.0) + (0.15x1.0) + (0.10x0.0) = 0.775

Include the per-persona weighted score in the Per-Persona Scores table.

## Theme Identification Rules

### Priority Escalation

| Pattern | Priority |
|---------|----------|
| 3+ personas flag same issue | CRITICAL |
| 2 personas flag same issue | HIGH |
| Engagement Sponsor + Solution Architect on same issue | CRITICAL (strategic + feasibility = non-viable option space) |
| Innovation Strategist + End-User Advocate on same issue | CRITICAL (creative ambition + user grounding = options are clever but unwanted, or bland but user-grounded) |
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

Group concerns that target the same underlying Develop weakness:

- "All options look the same" = "No real choice" = "Variations of one idea" → Develop Artifact: Option Synthesis (distinctness)
- "Options don't address the HMW" = "Where's the problem connection?" = "Creative but irrelevant" → Develop Artifact: Option Synthesis (alignment)
- "Can't build this" = "Fantasy architecture" = "Ignores constraints" → Develop Artifact: Options (feasibility)
- "No user value" = "Who wants this?" = "Solutions looking for a problem" → Develop Artifact: Options (user grounding)
- "Only obvious ideas" = "Any consultant would say this" = "No creativity" → Develop Artifact: Option Space (breadth)
- "TIPS and portfolio disconnected" = "Methods produced isolated outputs" = "No synthesis" → Develop Artifact: Option Synthesis (cross-pollination)
- "Scenarios are decorative" = "2×2 matrix didn't generate options" = "Academic exercise" → Develop Artifact: Scenario Matrix
- "Hidden assumptions" = "Presented as risk-free" = "What could go wrong?" → Develop Artifact: Options (risk transparency)
- "Users will comply" = "No adoption plan" = "Change management missing" → Develop Artifact: Options (adoption realism)

### Artifact Routing

Every synthesized theme must map to one or more Develop artifacts:

| Theme Category | Primary Artifact | Also Check |
|---|---|---|
| Option distinctness issues | `develop/options/option-synthesis.md` | Individual option descriptions |
| HMW alignment issues | `develop/options/option-synthesis.md` (Alignment field) | `define/hmw-questions.md` |
| Feasibility/constraint issues | `develop/options/option-synthesis.md` (Assumptions field) | `define/problem-statement.md` (Constraints) |
| User value issues | `develop/options/option-synthesis.md` | Discovery stakeholder/journey data |
| Creative breadth issues | Option space overall | `develop/scenarios/scenario-matrix.md`, `develop/options/tips-solutions.md` |
| Source traceability issues | `develop/options/option-synthesis.md` (Source field) | `develop/options/tips-solutions.md`, `develop/propositions/` |
| Scenario quality issues | `develop/scenarios/scenario-matrix.md` | Option synthesis |
| Risk transparency issues | `develop/options/option-synthesis.md` (Key assumptions) | Per-option assumptions |
| Adoption/user-facing risk issues | `develop/options/option-synthesis.md` | Stakeholder map, discovery journey data |

## Conflict Resolution

### Common Develop Conflicts

| Conflict | Resolution |
|----------|------------|
| Sponsor wants safe bets vs. Innovation Strategist wants bold options | Both: include 2-3 de-risked options AND 1 stretch option; label risk profiles clearly so the sponsor can make an informed choice in Deliver |
| Solution Architect says "can't build" vs. Innovation Strategist says "think bigger" | Solution Architect wins on feasibility within stated constraints; Innovation Strategist can challenge whether the constraint itself should be questioned (but the challenge must be explicit, not smuggled in) |
| End-User Advocate says "users won't adopt" vs. Sponsor says "users will comply" | End-User Advocate wins — adoption failure kills even well-funded options; flag as CRITICAL if unresolved |
| Innovation Strategist says "too obvious" vs. Solution Architect says "proven approach" | Both valid — label the option as "low-risk/incremental" but don't remove it; push for at least one additional non-obvious option to expand the space |
| Sponsor wants fewer options vs. Innovation Strategist wants more | Minimum viable option space is 3 genuinely distinct options; fewer than 3 means insufficient divergence; more than 7 means insufficient synthesis |

### Tiebreaker Hierarchy

When personas disagree and no resolution is obvious:

1. **Engagement Sponsor** — their priorities define which options are worth pursuing; misaligned options waste the entire Deliver phase
2. **End-User Advocate** — if users won't adopt, the option fails regardless of strategic alignment or technical elegance
3. **Solution Architect** — if it can't be built, it's fiction; feasibility is a hard constraint
4. **Innovation Strategist** — creative ambition matters but doesn't override viability; their input shapes the space but doesn't veto pragmatic options

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
2. Proceed to phase transition (step 8)
3. Include observations in the Develop summary

## Recommendation Merging

1. Group recommendations by Develop artifact (use artifact routing table)
2. Within each artifact, assign merged priority (highest from any contributing persona)
3. Combine specific actions into a single actionable recommendation per artifact
4. Track which personas contributed to each recommendation
5. Distinguish between:
   - **Fix in artifact** — the Develop output needs revision (e.g., "option synthesis lacks source traceability")
   - **Fix in method** — the generation method needs re-running or adjustment (e.g., "scenario analysis was superficial, re-run with different uncertainties")
   - **Flag for Deliver** — the issue can't be resolved in Develop but should inform evaluation (e.g., "Option 3's key assumption is unvalidated, Deliver should include a validation step")

## Output Structure

```markdown
## Develop Review Summary

**Personas**: [list of personas used]
**Engagement**: [name] ([vision class])
**Overall assessment**: [1-2 sentence verdict on option space quality]
**Iteration**: [round N of max 2 / final]

### Per-Persona Scores

| Persona | Verdicts | Weighted Score | Strongest | Weakest |
|---|---|---|---|---|
| Engagement Sponsor | PASS: N, WARN: N, FAIL: N | 0.XX | [criterion] | [criterion] |
| Solution Architect | ... | ... | ... | ... |
| Innovation Strategist | ... | ... | ... | ... |
| End-User Advocate | ... | ... | ... | ... |

### Cross-Cutting Themes

#### CRITICAL
- **[Theme name]** (Personas: [list]) → Artifact: [X]
  - [Specific finding and recommended action]
  - Fix type: artifact / method / flag-for-deliver

#### HIGH
- ...

#### OPTIONAL
- ...

### Prioritized Questions

Questions the Develop outputs should answer but currently don't:
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

### Flags for Deliver

Issues that can't be resolved in Develop but should inform the Deliver phase:
- [Issue] — raised by [persona(s)], recommended Deliver action: [action]
```
