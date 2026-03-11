---
title: Multi-Persona Synthesis Protocol
version: 1.0
---

# Synthesis Protocol

## Purpose

Transform diverse persona feedback into a prioritized, actionable improvement plan. Identify cross-cutting themes, resolve conflicts, and produce a single set of ranked recommendations.

## Theme Identification Rules

### Priority Escalation

| Pattern | Priority |
|---------|----------|
| 3+ personas raise same issue | CRITICAL |
| 2 personas raise same issue | HIGH |
| Executive + 1 other on same issue | CRITICAL |
| Any persona labels CRITICAL | CRITICAL |
| Single persona, high-weight criterion (>=20%) | HIGH |
| Single persona, low-weight criterion (<15%) | OPTIONAL |

### Semantic Matching

Group similar concerns regardless of exact wording:
- "Add timeline" = "Include deadline" = "Specify decision date"
- "Missing quantification" = "No ROI data" = "Lacks numbers"
- "Dense paragraphs" = "Wall of text" = "Hard to scan"

## Conflict Resolution

### Common Conflicts

| Conflict | Resolution |
|----------|------------|
| Brevity vs. Detail | Executive summary + detailed appendix |
| Emotion vs. Data | Lead with data, use power words for emphasis |
| Simplicity vs. Precision | Plain language with technical glossary |
| Bold claims vs. Hedging | Strong but hedged: "designed to deliver" |
| Clarity vs. Disclosure | Clear main message + separate brief disclaimer section |

### Tiebreaker Hierarchy

1. Primary audience perspective (infer from document context)
2. Safety/compliance (legal concerns override style)
3. Clarity (accessibility concerns override sophistication)
4. Impact (persuasiveness and executive appeal)

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
