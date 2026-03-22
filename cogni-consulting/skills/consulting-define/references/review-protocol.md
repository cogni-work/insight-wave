---
title: Define Phase Stakeholder Review Protocol
version: 1.0
---

# Define Review Protocol

## Purpose

Stress-test the Define phase outputs (problem statement, HMW questions, assumption verification, theme clusters) through multi-persona review before transitioning to Develop. Identify cross-cutting concerns, resolve conflicts, and either iterate on artifacts or proceed with documented observations.

This is a closed-loop quality gate — CRITICAL issues trigger revision before the engagement moves to Diamond 2.

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
| Delivery Lead + Solution Architect on same issue | CRITICAL (process + feasibility = structural failure) |
| Engagement Sponsor + End-User Advocate on same issue | CRITICAL (strategic + human = misframed problem) |
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

Group concerns that target the same underlying Define weakness:

- "Problem too vague" = "Could apply to any company" = "No tension" → Define Artifact: Problem Statement (Tension element)
- "HMW too broad" = "Can't brainstorm for this" = "Implies only one solution" → Define Artifact: HMW Questions
- "Assumptions not verified" = "Claims treated as fact" = "Where's the evidence?" → Define Artifact: Assumptions Verification
- "Lost the user perspective" = "Sounds like a board memo" = "Who actually has this problem?" → Define Artifact: Problem Statement (Context element)
- "Clusters are arbitrary" = "Themes don't group naturally" = "Forced categorization" → Define Artifact: Theme Clusters
- "Can't trace to discovery" = "Where did this come from?" = "New claim not in synthesis" → Define Artifact: Evidence Traceability
- "Scope too big" = "Can't solve this in one engagement" = "Needs 10x budget" → Define Artifact: Problem Statement (Constraints element)
- "Embedded solution" = "Only one answer" = "Prescriptive question" → Define Artifact: Problem Statement (Question element)

### Artifact Routing

Every synthesized theme must map to one or more Define artifacts:

| Theme Category | Primary Artifact | Also Check |
|---|---|---|
| Framing/scope issues | `define/problem-statement.md` | HMW questions, engagement vision |
| Convergence rigor issues | `define/theme-clusters.md` | Method log, decision log |
| Evidence/traceability issues | `define/assumptions.json` | `discover/synthesis.md` |
| HMW quality issues | `define/hmw-questions.md` | Theme clusters, problem statement |
| User perspective issues | `define/problem-statement.md` (Context) | Discovery stakeholder/journey data |
| Feasibility/constraint issues | `define/problem-statement.md` (Constraints) | Engagement vision, timeline |
| Decision transparency issues | `.metadata/decision-log.json` | Method log |

## Conflict Resolution

### Common Define Conflicts

| Conflict | Resolution |
|----------|------------|
| Sponsor wants strategic framing vs. End-User Advocate wants user-grounded framing | Both: problem statement uses strategic language, but Tension element grounds it in user-experienced pain |
| Delivery Lead says "rigorous process" vs. Solution Architect says "problem is unsolvable" | Solution Architect wins on solvability — a rigorous process that produces an unsolvable problem is still wrong |
| Sponsor wants broad scope vs. Solution Architect wants tractable scope | Constrain through HMW questions — broad problem statement, focused HMW subset that scopes the Develop work |
| End-User Advocate says "wrong problem" vs. Delivery Lead says "evidence supports it" | Escalate as CRITICAL — if user perspective contradicts the framing, Discovery may have missed something; log and present to consultant |
| Delivery Lead wants more convergence iterations vs. Sponsor wants to move forward | Sponsor wins — but note the Delivery Lead's concern in the review summary as a risk for Develop |

### Tiebreaker Hierarchy

When personas disagree and no resolution is obvious:

1. **Engagement Sponsor** — their priorities define success; misaligned problem statement wastes the entire engagement
2. **End-User Advocate** — if the problem isn't real to users, solutions won't be adopted
3. **Solution Architect** — if the problem can't be solved, Develop will fail
4. **Delivery Lead** — process quality matters but doesn't override substance

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
3. Include observations in the Define summary

## Recommendation Merging

1. Group recommendations by Define artifact (use artifact routing table)
2. Within each artifact, assign merged priority (highest from any contributing persona)
3. Combine specific actions into a single actionable recommendation per artifact
4. Track which personas contributed to each recommendation
5. Distinguish between:
   - **Fix in artifact** — the Define output needs revision (e.g., "problem statement Tension is too generic")
   - **Fix in process** — the convergence method needs improvement (e.g., "affinity clustering should preserve user-facing language")
   - **Flag for Develop** — the issue can't be resolved in Define but should inform solution design (e.g., "user adoption risk acknowledged, Develop should address it")

## Output Structure

```markdown
## Define Review Summary

**Personas**: [list of personas used]
**Engagement**: [name] ([vision class])
**Overall assessment**: [1-2 sentence verdict]
**Iteration**: [round N of max 2 / final]

### Per-Persona Scores

| Persona | Verdicts | Weighted Score | Strongest | Weakest |
|---|---|---|---|---|
| Engagement Sponsor | PASS: N, WARN: N, FAIL: N | 0.XX | [criterion] | [criterion] |
| Delivery Lead | ... | ... | ... | ... |
| Solution Architect | ... | ... | ... | ... |
| End-User Advocate | ... | ... | ... | ... |

### Cross-Cutting Themes

#### CRITICAL
- **[Theme name]** (Personas: [list]) → Artifact: [X]
  - [Specific finding and recommended action]
  - Fix type: artifact / process / flag-for-develop

#### HIGH
- ...

#### OPTIONAL
- ...

### Prioritized Questions

Questions the Define outputs should answer but currently don't:
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
- [Ordered list of recommended actions before entering Develop]
```
