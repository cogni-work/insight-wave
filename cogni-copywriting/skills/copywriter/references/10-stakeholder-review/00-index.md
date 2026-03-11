---
title: Stakeholder Review System
type: index
version: 2.0
---

# Stakeholder Review System

## What This System Does

You simulate multiple stakeholder perspectives to evaluate a document before final delivery. Each perspective applies a weighted checklist of 5 criteria, scores the document, and produces structured feedback. You then synthesize all feedback into prioritized improvements and apply them.

This system adds two phases to the copywriter workflow:
- **Phase 6: Stakeholder Review** -- evaluate the document from selected perspectives
- **Phase 7: Synthesis & Refinement** -- aggregate feedback, resolve conflicts, apply improvements

## When to Use Each Perspective

Think through which perspectives to activate by matching the document's audience and purpose to the descriptions below.

<perspectives>

### Executive
**File:** `executive-review.md`
**Criteria (weighted):** Lead with Ask (25%), Quantification (25%), Time Respect (20%), Decision Clarity (20%), Credibility (10%)
**Activate when:** The audience includes C-suite, senior leadership, or board members. The document requests a decision, approval, or resource allocation.
**Core question:** Can a time-pressed executive understand the ask, evaluate the evidence, and make a decision within 90 seconds?

### Technical
**File:** `technical-review.md`
**Criteria (weighted):** Accuracy (30%), Logical Flow (25%), Precision (20%), Completeness (15%), Terminology (10%)
**Activate when:** The document contains technical specifications, implementation details, architecture decisions, or engineering trade-offs.
**Core question:** Are all technical claims correct, logically supported, and precise enough for an engineer to evaluate feasibility?

### Legal/Compliance
**File:** `legal-review.md`
**Criteria (weighted):** Risk Language (30%), Regulatory Alignment (25%), Liability Mitigation (20%), Evidence Standards (15%), Disclosure Completeness (10%)
**Activate when:** The document involves contracts, policies, compliance requirements, vendor agreements, public statements, or financial projections.
**Core question:** Does the language minimize organizational risk through appropriate hedging, regulatory compliance, and complete disclosure?

### Marketing
**File:** `marketing-review.md`
**Criteria (weighted):** Audience Resonance (30%), Persuasiveness (25%), Brand Tone (20%), Call-to-Action (15%), Emotional Connection (10%)
**Activate when:** The document aims to influence, persuade, promote, or engage an audience. Sales materials, proposals with a persuasive goal, or customer-facing content.
**Core question:** Does the document speak to audience motivations with benefits-first structure, clear CTA, and emotional resonance?

### End-User
**File:** `end-user-review.md`
**Criteria (weighted):** Plain Language (30%), Immediate Clarity (25%), Actionability (20%), Visual Clarity (15%), Empathy & Tone (10%)
**Activate when:** The document targets general audiences, customers, or non-specialists who lack domain expertise.
**Core question:** Can someone with no specialized knowledge understand the main point, know what to do, and feel respected by the tone?

</perspectives>

## Selecting Stakeholders

### Step 1: Check for explicit override

If the user specifies stakeholders directly (e.g., `stakeholders: [executive, legal, technical]`), use exactly those. Skip the default selection logic.

### Step 2: Apply defaults based on audience

If no explicit override, select stakeholders based on the document's audience parameter:

| Audience Parameter | Default Stakeholders | Reasoning |
|---|---|---|
| `executive` | executive, technical, end-user | Decision-makers need data-backed clarity that downstream audiences can also parse |
| `technical` | technical, executive | Technical accuracy validated, then checked for executive scannability |
| `general` | end-user, marketing, executive | Accessibility and persuasion for broad audiences, executive check for structure |
| `legal` | legal, executive, technical | Risk language first, then decision-readiness and technical correctness |
| `sales/marketing` | marketing, executive, end-user | Persuasion validated, then executive structure and audience accessibility |

### Step 3: Confirm minimum coverage

Always include at least 2 perspectives. If only 1 would be selected, add the executive perspective as a universal structural check.

## Review Process (Phase 6)

For each selected stakeholder, execute these steps in sequence:

```
1. Load the perspective file: {perspective}-review.md
2. Evaluate the document against all 5 weighted criteria
3. Score each criterion: PASS (100), CONCERN (60), FAIL (0)
4. Calculate the weighted total (0-100 scale)
5. Generate structured feedback:
   - strengths: what the document does well for this perspective
   - concerns: specific issues identified
   - recommendations: labeled CRITICAL, HIGH, or OPTIONAL with concrete fixes
```

**Review modes** (controlled by parameter):
- `automated` (default) -- run all checklists without user interaction
- `manual` -- pause after each perspective for user feedback via TodoWrite
- `skip` -- bypass review phases entirely, proceed to Phase 8

**Scoring thresholds** (same across all perspectives):
- 85-100: Excellent, meets perspective requirements
- 70-84: Good, minor improvements needed
- 50-69: Concerns, significant revisions required
- 0-49: Failing, major changes needed
- Passing threshold: 70 or above

## Synthesis Process (Phase 7)

After all stakeholder reviews complete, synthesize feedback into prioritized action. Full details are in `synthesis-guidelines.md`. The high-level flow:

```
Step 1: Collect all structured feedback from completed reviews
Step 2: Identify common themes across perspectives (semantic matching)
Step 3: Assign priority tiers:
        - CRITICAL: mentioned by 2+ stakeholders, OR executive + any other,
          OR labeled CRITICAL by any stakeholder, OR blocks deliverable requirements
        - HIGH: mentioned by 2 stakeholders (non-executive), OR labeled HIGH,
          OR affects high-weight criterion (20%+)
        - OPTIONAL: single stakeholder, low-weight criterion, or requires out-of-scope data
Step 4: Resolve conflicts between perspectives using tiebreaker hierarchy
Step 5: Apply CRITICAL improvements (mandatory), then HIGH (if feasible)
Step 6: Log OPTIONAL improvements for user review without applying them
Step 7: Calculate synthesis metrics (overall score, application rate)
```

**Conflict resolution tiebreaker hierarchy** (in priority order):
1. Primary audience perspective -- if the document is for executives, executive wins
2. Deliverable requirements -- framework compliance and regulatory needs override preferences
3. Impact technique effectiveness -- persuasion and clarity generally prioritized
4. User-specified preference -- explicit user parameters override all defaults

## Overall Score Calculation

**Per-stakeholder score:** Sum of (criterion score x criterion weight) for all 5 criteria. Range: 0-100.

**Synthesis overall score:** Average all stakeholder scores. If a primary audience is specified, weight that perspective's score 2x before averaging.

Example with executive as primary audience:
```
Executive: 82, Technical: 86, End-user: 90
Weighted average: (82x2 + 86 + 90) / 4 = 85
```

## Graceful Degradation

Review enhances quality but never blocks document delivery. Apply these fallback rules:

| Failure | Behavior |
|---|---|
| Single stakeholder review fails | Continue with remaining stakeholders |
| All stakeholder reviews fail | Skip to Phase 8, set `fallback_reason: "review_failure"` |
| Synthesis fails | Continue to Phase 8 with original document, set `fallback_reason: "synthesis_failure"` |
| Individual improvement application fails | Revert to pre-improvement state, log failure, continue with remaining improvements |

## Output Format

Each stakeholder review produces a JSON object. The synthesis step aggregates them into this structure:

```json
{
  "stakeholder_reviews": [
    {
      "perspective": "executive",
      "score": 85,
      "criteria_scores": {
        "lead_with_ask": 100,
        "quantification": 60,
        "time_respect": 100,
        "decision_clarity": 100,
        "credibility": 100
      },
      "strengths": ["..."],
      "concerns": ["..."],
      "recommendations": ["CRITICAL: ...", "HIGH: ..."]
    }
  ],
  "synthesis": {
    "overall_score": 84,
    "audience_weighted_score": 86,
    "critical_improvements": ["..."],
    "high_improvements": ["..."],
    "optional_improvements": ["..."],
    "failed_improvements": [],
    "recommendations_applied": true,
    "application_rate": 1.0
  }
}
```

## Workflow Integration

The stakeholder review system sits within the copywriter's 8-phase workflow:

```
Phase 1: Parse Parameters & Load References
Phase 2: Gather Content Requirements
Phase 3: Apply Structure & Framework
Phase 4: Apply Writing Principles
Phase 5: Apply Impact Techniques (optional)
Phase 6: Stakeholder Review        <-- this system
Phase 7: Synthesis & Refinement    <-- this system
Phase 8: Validate & Write Document
```

**Progressive disclosure rule:** Load stakeholder perspective files only during Phase 6, and only for the selected perspectives. Do not preload all 5 perspective files.

## File Map

| File | Purpose |
|---|---|
| `00-index.md` | This file. System overview, stakeholder selection, process flow |
| `executive-review.md` | Executive perspective: 5 criteria, scoring, feedback template, conflict resolution |
| `technical-review.md` | Technical perspective: 5 criteria, scoring, feedback template, conflict resolution |
| `legal-review.md` | Legal/compliance perspective: 5 criteria, scoring, feedback template, conflict resolution |
| `marketing-review.md` | Marketing perspective: 5 criteria, scoring, feedback template, conflict resolution |
| `end-user-review.md` | End-user perspective: 5 criteria, scoring, feedback template, conflict resolution |
| `synthesis-guidelines.md` | Full synthesis process: theme identification, prioritization, conflict resolution, improvement application |
