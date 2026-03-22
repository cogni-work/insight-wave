---
title: Proposition Quality Gate Protocol (Develop Phase)
version: 1.0
---

# Proposition Quality Gate Protocol

## Purpose

Evaluate Feature x Market propositions for messaging quality, market grounding, and competitive defensibility before they enter Option Synthesis. Unlike the option-level stakeholder review (step 7), this is a **mandatory quality gate** — propositions that fail on high-weight criteria are excluded from Option Synthesis unless the consultant explicitly reinstates them.

The rationale: bad propositions are cheaper to catch here than after they've been synthesized into strategic options. A vague IS statement or an unsupported market claim that survives into Option Synthesis contaminates the option space and is harder to trace back to its source.

## Gate Behavior

This gate blocks by default. The option-level review (step 7) warns. The difference is deliberate — propositions are atomic building blocks that must each stand on their own, while the option space is a creative synthesis where imperfection in one element can be compensated by strength in another.

### Verdict Definitions

| Verdict | Per-Proposition Status |
|---------|----------------------|
| All criteria PASS or WARN | **APPROVED** — enters Option Synthesis |
| Any criterion WARN on >= 25% weight | **CONDITIONAL** — enters Option Synthesis with noted improvements |
| Any criterion FAIL on >= 25% weight | **BLOCKED** — excluded from Option Synthesis unless consultant overrides |

A proposition needs zero FAILs on high-weight criteria (>= 25%) to pass. FAILs on low-weight criteria (< 25%) result in CONDITIONAL status.

## Weighted Scoring

Same formula as the option-level review:

| Verdict | Score |
|---------|-------|
| PASS | 1.0 |
| WARN | 0.5 |
| FAIL | 0.0 |

**Formula**: Sum of (criterion weight x verdict score) across all 5 criteria.

Per-persona scores are calculated and included in the review summary, but the blocking decision is based on individual criterion verdicts, not aggregate scores. A proposition can have a decent aggregate score (0.65) while still being BLOCKED if a single high-weight criterion gets FAIL.

## Theme Identification

### Semantic Matching

Group concerns that target the same underlying proposition weakness:

| Surface Concern | Underlying Issue | Routes To |
|---|---|---|
| "IS too vague" = "Could be any product" = "Feature undefined" | Feature definition lacks specificity | Proposition IS statement |
| "DOES not differentiating" = "Any competitor says this" = "Generic advantage" | Advantage lacks competitive separation | Proposition DOES statement |
| "MEANS disconnected" = "Supplier benefit" = "So what?" | Benefit doesn't map to buyer pain | Proposition MEANS statement |
| "Who is this for?" = "Market too broad" = "Everyone is no one" | Segment not actionable | Market definition |
| "No evidence" = "Where's the data?" = "Speculative market" | Discovery findings not referenced | Evidence base |
| "Same market twice" = "Overlap" = "Internal cannibalization" | Segment cannibalization across propositions | Cross-proposition coverage |
| "Broken chain" = "IS doesn't lead to DOES" = "Logic gap" | IS-DOES-MEANS coherence failure | Full proposition chain |
| "Competitor owns this" = "No entry wedge" = "Red ocean" | Competitive position indefensible | Competitive baseline |
| "Jargon leakage" = "Methodology terms" = "Internal language" | Non-buyer-facing terminology | Terminology across propositions |

### Cross-Proposition Themes

When both personas flag the same proposition, or when the same weakness appears across multiple propositions:

| Pattern | Priority |
|---------|----------|
| Both personas FAIL same proposition on >= 25% criteria | CRITICAL — proposition is structurally unsound |
| Same weakness across 3+ propositions | CRITICAL — systematic issue, not isolated |
| Both personas flag same issue on different propositions | HIGH — pattern suggests method-level problem |
| Single persona flags isolated issue | Per criterion weight: >= 25% = HIGH, < 25% = OPTIONAL |

### Theme Caps

- **CRITICAL**: up to 2 (this is a narrower scope than the option-level review)
- **HIGH**: up to 3
- **OPTIONAL**: up to 3

## Conflict Resolution

With only two personas, conflicts are simpler than the 4-persona option review:

| Conflict | Resolution |
|----------|------------|
| Proposition Analyst says messaging is strong but Market Validator says market is wrong | **Market Validator wins** — well-crafted messaging for the wrong market wastes effort; re-target or re-evidence before passing |
| Market Validator says market is solid but Proposition Analyst says messaging is weak | **Proposition Analyst wins** — a real market opportunity with vague messaging is fixable but shouldn't enter Option Synthesis unfixed |
| Both flag different issues on same proposition | Both apply — proposition must address both before advancing |
| Proposition Analyst flags terminology inconsistency across propositions | Always applies — consistency is objective, not a matter of perspective |

**General principle**: Proposition Analyst wins on messaging quality (IS/DOES/MEANS), Market Validator wins on market fit (segment, evidence, competition). When in doubt, the more conservative verdict applies — this is a blocking gate.

## Closed-Loop Decision Logic

### BLOCKED propositions found (round 1)

1. Identify the specific FAIL verdicts and which persona flagged them
2. Apply targeted revisions to the affected propositions:
   - IS clarity failures: rewrite the IS statement with concrete scope definition
   - DOES differentiation failures: add mechanism-level specificity, reference competitive baseline
   - MEANS relevance failures: trace back to problem statement pain points
   - Market precision failures: narrow segment with qualifying characteristics
   - Evidence grounding failures: cite specific discovery findings or flag gap
3. Re-run only the persona(s) that flagged FAIL — don't repeat the full review
4. Re-evaluate the revised proposition against the same criteria

### After round 2

If a proposition is still BLOCKED after 2 rounds:

1. **Exclude** the proposition from Option Synthesis — this is the default
2. Document the exclusion with: which proposition, which criteria failed, what was attempted, why it didn't resolve
3. Present the exclusion list to the consultant
4. **Consultant override**: The consultant may reinstate a BLOCKED proposition with an explicit rationale. The rationale is logged in the decision log. This preserves the "consultant has final say" principle while making the default conservative

### Only CONDITIONAL and APPROVED propositions

1. Log the noted improvements for CONDITIONAL propositions as observations
2. Proceed to step 5 (Scenario Planning)
3. CONDITIONAL improvements may be addressed during Option Synthesis or flagged for Deliver

## Output Structure

```markdown
## Proposition Quality Review

**Personas**: Proposition Analyst, Market Validator
**Engagement**: [name] ([vision class])
**Propositions reviewed**: [N]
**Iteration**: [round N of max 2 / final]

### Per-Proposition Verdicts

| Proposition (Feature x Market) | Analyst Score | Validator Score | Status | Blocking Criteria |
|---|---|---|---|---|
| [Feature] x [Market] | 0.XX | 0.XX | APPROVED / CONDITIONAL / BLOCKED | [criteria that failed, or "—"] |
| ... | ... | ... | ... | ... |

### Summary
- **APPROVED**: N propositions — enter Option Synthesis
- **CONDITIONAL**: N propositions — enter with noted improvements
- **BLOCKED**: N propositions — excluded (consultant may override)

### Detailed Reviews

#### [Feature] x [Market] — [STATUS]

**Proposition Analyst**:

| Criterion | Weight | Verdict | Evidence |
|---|---|---|---|
| IS Clarity | 25% | PASS/WARN/FAIL | [specific evidence] |
| DOES Differentiation | 25% | PASS/WARN/FAIL | [specific evidence] |
| MEANS Buyer Relevance | 25% | PASS/WARN/FAIL | [specific evidence] |
| Feature x Market Coherence | 15% | PASS/WARN/FAIL | [specific evidence] |
| Terminology Consistency | 10% | PASS/WARN/FAIL | [specific evidence] |

**Market Validator**:

| Criterion | Weight | Verdict | Evidence |
|---|---|---|---|
| Market Segment Precision | 30% | PASS/WARN/FAIL | [specific evidence] |
| Buyer Journey Alignment | 25% | PASS/WARN/FAIL | [specific evidence] |
| Competitive Distinctness | 20% | PASS/WARN/FAIL | [specific evidence] |
| Evidence Grounding | 15% | PASS/WARN/FAIL | [specific evidence] |
| Cross-Proposition Coverage | 10% | PASS/WARN/FAIL | [specific evidence] |

[repeat for each proposition]

### Cross-Proposition Themes

#### CRITICAL
- **[Theme]** (Propositions: [list]) — [finding and recommended action]

#### HIGH
- ...

#### OPTIONAL
- ...

### Exclusions (if any)

| Proposition | Blocking Criteria | Attempted Fix | Exclusion Rationale |
|---|---|---|---|
| [Feature x Market] | [criteria] | [what was revised] | [why it still fails] |

**Consultant override**: [none / overridden propositions with documented rationale]

### Revision History (if iterated)

#### Round 1
- **Proposition**: [Feature x Market]
- **Issue**: [what was flagged]
- **Revision**: [what was changed]
- **Re-evaluated by**: [persona(s)]
- **Result**: [resolved / still blocked]
```
