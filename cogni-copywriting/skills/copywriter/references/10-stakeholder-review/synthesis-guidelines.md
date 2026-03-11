---
title: Multi-Stakeholder Feedback Synthesis
type: process-documentation
version: 2.0
---

# Synthesis Guidelines

You are synthesizing feedback from multiple stakeholder reviews into a prioritized action plan. Your goal is to transform diverse perspectives into coherent document improvements without analysis paralysis. Apply every CRITICAL improvement, apply feasible HIGH improvements, and log OPTIONAL improvements for manual review.

## Input Format

You receive structured JSON feedback from completed stakeholder reviews (Phase 6). Each review contains:

```json
{
  "perspective": "executive | technical | legal | marketing | end-user",
  "score": 0-100,
  "criteria_scores": { "criterion_name": 100 | 60 | 0 },
  "strengths": ["what works well"],
  "concerns": ["areas needing improvement"],
  "recommendations": ["PRIORITY_LABEL: specific actionable improvement"]
}
```

Priority labels in recommendations are: `CRITICAL`, `HIGH`, or `OPTIONAL`.

## Synthesis Process

Work through these six steps in order. For each step, think carefully before proceeding to the next.

### Step 1: Aggregate All Feedback

Collect every review into a single working set. Before moving on, verify:

- How many stakeholders reviewed the document?
- What is the score range across reviewers?
- How many total recommendations exist, broken down by priority label?

This inventory prevents you from losing track of any feedback during synthesis.

### Step 2: Identify Common Themes

Group recommendations that address the same underlying issue, even when stakeholders use different language. Think about semantic equivalence, not string matching.

<examples>
<example>
<description>Same theme, different wording</description>
<stakeholder_a>"Add decision deadline" (executive)</stakeholder_a>
<stakeholder_b>"Include implementation timeline" (technical)</stakeholder_b>
<stakeholder_c>"When does this need to happen?" (end-user)</stakeholder_c>
<theme>Missing temporal specificity</theme>
<reasoning>All three stakeholders are asking for time-bound commitments, despite using different terminology. This is one theme, not three separate issues.</reasoning>
</example>

<example>
<description>Different themes, similar wording</description>
<stakeholder_a>"Needs more detail" about ROI figures (executive)</stakeholder_a>
<stakeholder_b>"Needs more detail" about technical architecture (technical)</stakeholder_b>
<theme>These are two separate themes</theme>
<reasoning>Although the surface language is identical, the executive wants quantification depth while the technical reviewer wants implementation specifics. These require different fixes in different document sections.</reasoning>
</example>
</examples>

For each identified theme, record:
- Which stakeholders raised it (by perspective name)
- The highest priority label any stakeholder assigned to it
- A one-line summary of what the theme addresses

### Step 3: Assign Priority Tiers

Classify every recommendation into exactly one tier using these rules. Apply them in order; stop at the first match.

**CRITICAL (must apply before finalization):**

1. Any recommendation labeled CRITICAL by any stakeholder
2. Any theme raised by 3+ stakeholders, regardless of their labels
3. Any theme raised by the executive perspective plus at least one other perspective
4. Any recommendation that blocks core deliverable requirements (framework compliance, regulatory, contractual)

**HIGH (apply if feasible):**

1. Any recommendation labeled HIGH by any stakeholder (that did not already qualify as CRITICAL above)
2. Any theme raised by exactly 2 stakeholders (neither executive)
3. Any recommendation targeting a criterion with weight >= 20% in that stakeholder's rubric

**OPTIONAL (log for manual review, do not apply):**

1. Everything else: single-stakeholder concerns on low-weight criteria, stylistic preferences, items requiring external data you do not have

<examples>
<example>
<description>Priority classification walkthrough</description>
<input>
Executive: "CRITICAL: Add ROI with timeframe"
Technical: "HIGH: Add risk mitigation section"
End-user: "OPTIONAL: Break paragraph 3 into bullets"
Technical also mentions: "Timeline for implementation unclear"
</input>
<thinking>
- "Add ROI with timeframe": Labeled CRITICAL by executive. Rule CRITICAL-1 applies. -> CRITICAL
- "Timeline unclear": Raised by technical. Executive also raised timeline concern (decision deadline). That is executive + 1 other on same theme. Rule CRITICAL-3 applies. -> CRITICAL
- "Add risk mitigation section": Labeled HIGH by technical. Not CRITICAL by any rule. Rule HIGH-1 applies. -> HIGH
- "Break paragraph 3 into bullets": Labeled OPTIONAL by single stakeholder. Rule OPTIONAL-1 applies. -> OPTIONAL
</thinking>
</example>
</examples>

### Step 4: Resolve Conflicts

When two recommendations directly contradict each other, you must resolve the conflict rather than applying both. Think step by step through this resolution process.

**First, check if a structural solution satisfies both sides.**

Most apparent conflicts dissolve with document structure changes rather than content trade-offs:

| Apparent Conflict | Structural Resolution |
|---|---|
| Executive wants brevity, Technical wants depth | Executive summary section + detailed appendix |
| Marketing wants emotional language, Executive wants data | Lead with data, use power words for emphasis only |
| End-user wants simplicity, Technical wants precision | Plain language in body + technical glossary or definitions |
| Marketing wants bold claims, Legal wants hedging | Confident but qualified: "designed to deliver" rather than "guarantees" |
| End-user wants clarity, Legal wants disclosure | Clear main message + separate brief disclosure section |

**If no structural solution exists, apply the tiebreaker hierarchy in order:**

1. Primary audience perspective wins. If the document is an executive memo, the executive perspective takes priority. If it targets end-users, the end-user perspective takes priority.
2. Deliverable requirements override preferences. Framework compliance, regulatory requirements, and contractual obligations outrank stylistic preferences.
3. Impact technique effectiveness. When all else is equal, favor the option that strengthens persuasion and clarity.
4. User-specified parameters. Explicit user instructions (tone, length, style) override default resolutions.

<example>
<description>Conflict resolution with chain of thought</description>
<conflict>Executive wants a 1-page memo. Technical wants detailed architecture documentation.</conflict>
<thinking>
Can a structural solution satisfy both? Yes. A 1-page executive memo with a link or reference to a separate technical appendix serves both needs without compromise. The executive gets their concise document; the technical reviewer gets comprehensive detail in an appendix.
</thinking>
<resolution>1-page executive memo with technical appendix reference. Apply BLUF structure to the memo; note in the document that detailed architecture is available in a companion document.</resolution>
</example>

### Step 5: Apply Improvements

Work through improvements in priority order. For each improvement, follow the apply-validate-commit pattern.

**For each CRITICAL improvement:**

1. Identify the exact document section that needs to change
2. Draft the specific change (add content, edit wording, or restructure)
3. Apply the change to the document
4. Re-evaluate the criterion that flagged the issue: did the score improve?
5. If score improved or issue is resolved: commit the change
6. If score did not improve: revert to the pre-change state and log the failure with a reason

**For each HIGH improvement:**

Before applying, check all three feasibility conditions:
- Can you make this change without external data you do not have?
- Does it avoid conflicting with any CRITICAL improvement you already applied?
- Will it measurably improve document quality?

If all three are true: apply using the same apply-validate-commit pattern above.
If any are false: skip and log the reason (e.g., "Skipped: requires vendor pricing data not available").

**For each OPTIONAL improvement:**

Do not apply. Log it in the synthesis output for the user to consider manually.

**Rollback discipline:**

Always preserve the document state before applying each improvement. If a change does not improve the target criterion score or introduces a regression in another criterion, restore the saved state. Never accumulate failing changes.

### Step 6: Calculate Synthesis Metrics

Compute and report these metrics in the synthesis output.

**Overall score:** Average of all stakeholder scores.

**Audience-weighted score:** If a primary audience is specified, weight that perspective's score 2x and all others 1x, then compute weighted average.

Calculation: `(primary_score * 2 + sum_of_other_scores) / (number_of_stakeholders + 1)`

**Improvement counts:**
- Critical applied: N of M total CRITICAL recommendations
- High applied: N of M total HIGH recommendations
- Optional logged: count of OPTIONAL recommendations recorded for review
- Failed: count of improvements attempted but reverted, each with failure reason

**Application rate:** `(critical_applied + high_applied) / (total_critical + total_high)`. Target: >= 0.80.

## Output Format

Return synthesis results as structured JSON:

```json
{
  "overall_score": 84,
  "audience_weighted_score": 86,
  "primary_audience": "executive",
  "stakeholder_count": 3,
  "critical_improvements": [
    {
      "description": "Add decision deadline: March 15, 2025",
      "stakeholders": ["executive", "technical"],
      "status": "applied"
    }
  ],
  "high_improvements": [
    {
      "description": "Add risk mitigation section",
      "stakeholders": ["technical"],
      "status": "applied"
    }
  ],
  "optional_improvements": [
    {
      "description": "Add architecture diagram",
      "stakeholders": ["technical"],
      "status": "logged_for_review",
      "reason": "Requires external tooling, out of scope"
    }
  ],
  "failed_improvements": [],
  "application_rate": 1.0,
  "recommendations_applied": true
}
```

## Decision Reference

Use these decision trees when you are uncertain about how to handle a specific recommendation.

### Should I apply this recommendation?

```
Is it classified as CRITICAL?
  YES -> Apply immediately using apply-validate-commit pattern.
  NO  -> Is it classified as HIGH?
           YES -> Is it feasible? (no external data needed, no CRITICAL conflicts, measurable improvement)
                    YES -> Apply using apply-validate-commit pattern.
                    NO  -> Skip. Log reason.
           NO  -> It is OPTIONAL. Log for manual review. Do NOT apply.
```

### How do I resolve conflicting recommendations?

```
Do the recommendations directly contradict each other?
  NO  -> Apply both. They are compatible.
  YES -> Can a structural solution satisfy both? (e.g., summary + appendix)
           YES -> Apply the structural solution.
           NO  -> Apply tiebreaker hierarchy:
                    1. Primary audience perspective
                    2. Deliverable requirements
                    3. Impact technique effectiveness
                    4. User-specified parameters
```

### How do I classify a theme mentioned by multiple stakeholders?

```
How many stakeholders raised this theme?
  3+  -> CRITICAL (regardless of individual labels)
  2   -> Is one of them the executive perspective?
           YES -> CRITICAL
           NO  -> HIGH
  1   -> Use the stakeholder's own priority label.
         If no label: check criterion weight.
           >= 20% -> HIGH
           < 15%  -> OPTIONAL
           15-19% -> HIGH (round up when in doubt)
```

## Worked Example

**Scenario:** Executive memo recommending CRM investment. Three stakeholders reviewed the document.

### Input

```json
[
  {
    "perspective": "executive",
    "score": 78,
    "concerns": ["Missing timeline", "ROI not quantified"],
    "recommendations": [
      "CRITICAL: Add decision deadline",
      "CRITICAL: Quantify ROI with timeframe"
    ]
  },
  {
    "perspective": "technical",
    "score": 85,
    "concerns": ["Implementation details vague", "No failure handling"],
    "recommendations": [
      "HIGH: Add technical risk section",
      "OPTIONAL: Add architecture diagram"
    ]
  },
  {
    "perspective": "end-user",
    "score": 90,
    "concerns": ["Paragraph 3 too dense"],
    "recommendations": [
      "HIGH: Break paragraph 3 into bullets"
    ]
  }
]
```

### Step-by-step synthesis

**Step 1 - Aggregate:** 3 stakeholders. Scores: 78, 85, 90. Total recommendations: 5 (2 CRITICAL, 2 HIGH, 1 OPTIONAL).

**Step 2 - Themes:**
- Timeline specificity: executive (decision deadline) + technical mentions implementation timeline is vague. Two stakeholders, same underlying theme.
- ROI quantification: executive only (CRITICAL label).
- Risk documentation: technical only (HIGH label).
- Content density: end-user only (HIGH label).
- Architecture detail: technical only (OPTIONAL label).

**Step 3 - Prioritize:**
- "Add decision deadline": CRITICAL (labeled CRITICAL by executive; also theme shared with technical, satisfying rule CRITICAL-3).
- "Quantify ROI with timeframe": CRITICAL (labeled CRITICAL by executive, rule CRITICAL-1).
- "Add technical risk section": HIGH (labeled HIGH by technical, rule HIGH-1).
- "Break paragraph 3 into bullets": HIGH (labeled HIGH by end-user, rule HIGH-1).
- "Add architecture diagram": OPTIONAL (labeled OPTIONAL by technical, single stakeholder, rule OPTIONAL-1).

**Step 4 - Conflicts:** No conflicts detected. All recommendations target different document sections and are compatible.

**Step 5 - Apply improvements:**

1. **Add decision deadline (CRITICAL):**
   - Before: "Please approve this proposal"
   - After: "Decision needed by March 15, 2025"
   - Validation: Executive "Decision Clarity" criterion 60 -> 100. Committed.

2. **Quantify ROI (CRITICAL):**
   - Before: "This will provide strong ROI"
   - After: "$340K 3-year ROI with 18-month payback (based on current $120K annual support cost)"
   - Validation: Executive "Quantification" criterion 60 -> 100. Committed.

3. **Add risk section (HIGH):**
   - Feasibility check: No external data needed, no conflicts, improves completeness. All conditions met.
   - Added: "Key Risks: vendor lock-in (mitigated by annual renewal clause), data migration complexity (estimated 40 hours)"
   - Validation: Technical "Completeness" criterion 60 -> 100. Committed.

4. **Break paragraph 3 (HIGH):**
   - Feasibility check: All conditions met.
   - Changed: 8-line paragraph into 3-line intro + bullet list.
   - Validation: End-user "Visual Clarity" criterion 60 -> 100. Committed.

5. **Architecture diagram (OPTIONAL):** Logged for manual review. Not applied.

**Step 6 - Metrics:**
- Overall score: (78 + 85 + 90) / 3 = 84
- Audience-weighted (executive primary): (78 * 2 + 85 + 90) / 4 = 83
- Critical applied: 2/2
- High applied: 2/2
- Application rate: 4/4 = 1.0

### Output

```json
{
  "overall_score": 84,
  "audience_weighted_score": 83,
  "primary_audience": "executive",
  "stakeholder_count": 3,
  "critical_improvements": [
    {
      "description": "Add decision deadline: March 15, 2025",
      "stakeholders": ["executive", "technical"],
      "status": "applied"
    },
    {
      "description": "Quantify ROI: $340K 3-year ROI, 18-month payback",
      "stakeholders": ["executive"],
      "status": "applied"
    }
  ],
  "high_improvements": [
    {
      "description": "Add risk mitigation section",
      "stakeholders": ["technical"],
      "status": "applied"
    },
    {
      "description": "Break paragraph 3 into bullets",
      "stakeholders": ["end-user"],
      "status": "applied"
    }
  ],
  "optional_improvements": [
    {
      "description": "Add architecture diagram",
      "stakeholders": ["technical"],
      "status": "logged_for_review",
      "reason": "Out of scope for text-based document improvements"
    }
  ],
  "failed_improvements": [],
  "application_rate": 1.0,
  "recommendations_applied": true
}
```

## Workflow Integration

**Position:** Phase 7, between Phase 6 (Stakeholder Review) and Phase 8 (Validate & Write Document).

**Skip conditions:** Skip this phase entirely if Phase 6 used the reader skill (Option A, which handles its own synthesis) or if Phase 6 was skipped.

**TodoWrite structure:**
```
Phase 7: Synthesis & Refinement
  Sub-task 1: Aggregate stakeholder feedback
  Sub-task 2: Identify common themes and assign priorities
  Sub-task 3: Resolve conflicts (if any)
  Sub-task 4: Apply CRITICAL improvement #1
  Sub-task 5: Apply CRITICAL improvement #2
  ...
  Sub-task N-1: Apply HIGH improvements (feasible ones)
  Sub-task N: Calculate synthesis metrics
```

**Graceful degradation:**
- Individual improvement fails: revert that change, log failure reason, continue with remaining improvements
- All improvements fail: proceed to Phase 8 with original document, set `fallback_reason: "synthesis_failure"`
- Synthesis metric calculation fails: proceed to Phase 8 with original document, include partial feedback in output

The synthesis phase enhances document quality but never blocks document delivery.

## Related Resources

- **Stakeholder perspectives:** `references/10-stakeholder-review/{perspective}-review.md`
- **Framework compliance:** `references/01-core-principles/*.md`
- **Writing principles:** `references/02-messaging-frameworks/*.md`
- **Impact techniques:** `references/07-impact-techniques/*.md`
