---
title: Discovery Stress-Test Review Protocol
version: 1.0
---

# Discovery Review Protocol

## Purpose

Transform multi-persona discovery feedback into a prioritized improvement plan. Identify cross-cutting themes across personas, resolve conflicts, and route findings to either skill improvements or engagement-level actions.

## Weighted Scoring

Each persona produces PASS/WARN/FAIL verdicts with weighted criteria. Calculate a weighted score per persona:

| Verdict | Score |
|---------|-------|
| PASS | 1.0 |
| WARN | 0.5 |
| FAIL | 0.0 |

**Formula**: Sum of (criterion weight x verdict score) across all 5 criteria.

Example: Delivery Lead gives PASS (25%), WARN (25%), PASS (20%), PASS (15%), FAIL (15%):
Score = (0.25x1.0) + (0.25x0.5) + (0.20x1.0) + (0.15x1.0) + (0.15x0.0) = 0.725

Include the per-persona weighted score in the Per-Persona Scores table.

## Theme Identification Rules

### Priority Escalation

| Pattern | Priority |
|---------|----------|
| 3+ personas flag same issue | CRITICAL |
| 2 personas flag same issue | HIGH |
| Delivery Lead + any other on same issue | CRITICAL (process quality is foundational) |
| Engagement Sponsor + Domain Expert on same issue | CRITICAL (credibility + accuracy = trust failure) |
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

Group concerns that target the same underlying discovery weakness:
- "Findings are generic" = "Nothing I didn't know" = "Could apply to any company" -> Discovery Artifact: Synthesis Themes
- "Can't trace where this came from" = "No source links" = "Which method produced this?" -> Discovery Artifact: Source Traceability
- "Missing [stakeholder/factor]" = "Didn't talk to the right people" = "Blind spot on [area]" -> Discovery Artifact: Stakeholder Map / Method Coverage
- "Thin evidence" = "Only one source" = "Not triangulated" -> Discovery Artifact: Evidence Base
- "Too vague to use in Define" = "Can't cluster these" = "Themes are categories not insights" -> Discovery Artifact: Synthesis Specificity
- "Gaps not acknowledged" = "False confidence" = "Looks complete but isn't" -> Discovery Artifact: Gap Transparency

### Artifact Routing

Every synthesized theme must map to one or more discovery artifacts:

| Theme Category | Primary Artifact | Also Check |
|---|---|---|
| Relevance/specificity issues | Synthesis Themes | Method selection |
| Accuracy/factual issues | Source Data (research, competitive, trends) | Domain terminology |
| Process/rigor issues | Method Selection & Execution | Guided method depth |
| Usability issues | Synthesis Structure | File organization, naming |
| Evidence depth issues | Evidence Base | Triangulation, gap transparency |
| Transition readiness issues | Phase Transition Assessment | Assumption register |

## Conflict Resolution

### Common Discovery Conflicts

| Conflict | Resolution |
|----------|------------|
| Sponsor wants "so what" vs. Analyst wants raw material | Both: synthesis leads with implications, but links back to granular evidence for the analyst |
| Domain Expert says "wrong terminology" vs. Delivery Lead says "good synthesis" | Domain Expert wins on terminology — correct terms don't reduce synthesis quality |
| Sponsor wants brevity vs. Analyst wants completeness | Structure solves this: executive summary for sponsor, detailed sections for analyst |
| Delivery Lead says "ready for Define" vs. Analyst says "can't cluster these themes" | Analyst wins — they're the consumer; if themes don't cluster, Define will struggle regardless of evidence volume |

### Tiebreaker Hierarchy

When personas disagree and no resolution is obvious:

1. **Engagement Sponsor** — their priorities define what success looks like; misaligned discovery is wasted work
2. **Client Domain Expert** — factual accuracy is non-negotiable; wrong facts undermine everything built on them
3. **Delivery Lead** — process rigor ensures repeatable quality across engagements
4. **Downstream Analyst** — usability shapes the next phase but can be addressed with restructuring

## Recommendation Merging

1. Group recommendations by discovery artifact (use artifact routing table)
2. Within each artifact, assign merged priority (highest from any contributing persona)
3. Combine specific actions into a single actionable recommendation per artifact
4. Track which personas contributed to each recommendation
5. Distinguish between:
   - **Fix in skill** — the skill's instructions should produce better output (e.g., "synthesis should always include source references")
   - **Fix in method** — a specific method reference file needs improvement (e.g., "stakeholder mapping should prompt for external stakeholders more aggressively")
   - **Fix in engagement** — this specific engagement's discovery needs more work (e.g., "re-run desk research with narrower scope")

## Output Structure

```markdown
## Discovery Review Summary

**Personas**: [list of personas used]
**Engagement**: [name] ([vision class])
**Overall assessment**: [1-2 sentence verdict]

### Per-Persona Scores

| Persona | Verdicts | Weighted Score | Strongest | Weakest |
|---|---|---|---|---|
| Engagement Sponsor | PASS: 2, WARN: 2, FAIL: 1 | 0.63 | Actionability | Surprise Value |
| ... | ... | ... | ... | ... |

### Cross-Cutting Themes

#### CRITICAL
- **[Theme name]** (Personas: sponsor, delivery-lead) -> Artifact: [X]
  - [Specific finding and recommended action]
  - Fix type: skill / method / engagement

#### HIGH
- ...

#### OPTIONAL
- ...

### Prioritized Questions

The top questions the discovery should answer but currently doesn't:
1. [Question] — raised by [persona(s)]
2. ...

### Skill Improvement Candidates

Issues that indicate the skill's instructions need refinement (not engagement-specific):
1. [Improvement] — evidence: [what triggered this across evals]
2. ...

### Suggested Next Steps

Based on review results:
- [Ordered list of recommended actions]
```
