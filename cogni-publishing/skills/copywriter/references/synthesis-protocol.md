---
title: Multi-Persona Synthesis Protocol
version: 1.0
---

# Synthesis Protocol

## Purpose

Transform diverse persona feedback into a prioritized, actionable improvement plan. Identify cross-cutting themes, resolve conflicts, and produce a single set of ranked recommendations.

## Theme Identification Rules

### Priority Escalation

Apply these in order and stop at the first match.

| Pattern | Priority |
|---------|----------|
| Any persona labels CRITICAL | CRITICAL |
| 3+ personas raise same issue | CRITICAL |
| Executive + 1 other on same issue | CRITICAL |
| Blocks a deliverable requirement (framework compliance, regulatory, contractual) | CRITICAL |
| 2 personas raise same issue (neither executive) | HIGH |
| Single persona, high-weight criterion (>=20%) | HIGH |
| Single persona, mid-weight criterion (15-19%) | HIGH -- round up when in doubt |
| Single persona, low-weight criterion (<15%) | OPTIONAL |

### Semantic Matching

Group similar concerns regardless of exact wording:
- "Add timeline" = "Include deadline" = "Specify decision date"
- "Missing quantification" = "No ROI data" = "Lacks numbers"
- "Dense paragraphs" = "Wall of text" = "Hard to scan"

## Conflict Resolution

Two recommendations conflict only if applying both is impossible. If they are merely different, apply both.

### Common Conflicts

Try a structural resolution first. Most apparent conflicts dissolve with a change to document structure rather than a content trade-off, and a structural fix satisfies both sides instead of overriding one.

| Conflict | Resolution |
|----------|------------|
| Brevity vs. Detail | Executive summary + detailed appendix |
| Emotion vs. Data | Lead with data, use power words for emphasis |
| Simplicity vs. Precision | Plain language with technical glossary |
| Bold claims vs. Hedging | Strong but hedged: "designed to deliver" |
| Clarity vs. Disclosure | Clear main message + separate brief disclaimer section |

### Tiebreaker Hierarchy

Only when no structural resolution exists. Apply in order; the first rank that settles the conflict wins.

1. Primary audience perspective (infer from document context)
2. Safety/compliance and deliverable requirements (legal, regulatory, contractual and framework-compliance concerns override style)
3. Clarity (accessibility concerns override sophistication)
4. Impact (persuasiveness and executive appeal)
5. User-specified parameters (explicit instructions on tone, length or style settle what ranks 1-4 left open)

## Recommendation Merging

1. Group recommendations by theme (semantic matching)
2. Assign merged priority (highest from any contributing persona)
3. Combine specific actions into single actionable recommendation
4. Track source personas for attribution

## Auto-Improvement Validation

After applying improvements, verify:

1. **German characters preserved** - All umlauts and eszett unchanged
2. **Citations preserved** - Count in output >= count in backup
3. **Protected content unchanged** - Diagram placeholders, figure refs, embeds
4. **No new issues introduced** - Quick re-evaluation of modified sections
5. **Readability maintained** - Flesch score within acceptable range

If ANY validation fails: revert to backup, report failure reason.
