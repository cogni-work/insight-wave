---
title: Example Memo - BLUF Framework
type: example
category: deliverable-example
deliverable: memo
framework: bluf
tags: [example, memo, bluf, internal-communication, policy-update]
quality-metrics:
  flesch-score: 55
  avg-paragraph-length: 4
  formality: medium
  active-voice-ratio: 85
  word-count: 280
version: 2.0
last_updated: 2026-02-25
---

# Example Memo - BLUF Framework

## Purpose

This reference teaches Claude to write professional memos using the BLUF (Bottom Line Up Front) framework. Study the annotated example below to internalize the structural pattern, then apply it when generating BLUF memos.

## When to Use This Example

Load this reference when:
- The user requests a memo with BLUF framework
- The user requests a memo without specifying a framework (BLUF is the default for memos)
- You need to demonstrate BLUF memo structure to calibrate your output

## Annotated Example

Below is a complete BLUF memo with inline annotations explaining why each section works. The annotations appear in blockquotes. Do not include annotations in your generated output.

---

> **ANNOTATION -- Header Block:** Standard memo header establishes authority, context, and urgency before the reader reaches the body. The SUBJECT line functions as a compressed BLUF: it names the action ("Code Review Policy Update"), signals the timeline ("Effective November 1"), and tells the reader exactly what the memo is about. A vague subject like "Policy Changes" would fail here.

TO: Engineering Team
FROM: Alex Chen, VP Engineering
DATE: October 29, 2025
SUBJECT: Code Review Policy Update - Effective November 1

> **ANNOTATION -- BLUF Statement:** This single paragraph delivers the complete message. A busy executive could read only this paragraph and know: (1) what is changing (mandatory two-reviewer approval), (2) when (November 1), (3) why (reduce critical bugs by 40%), and (4) the specific requirement (two approvals before merging to main). The BLUF answers all five Ws in two sentences. Notice the active voice ("We're implementing") and concrete quantification ("40%").

BLUF: We're implementing mandatory two-reviewer approval for all production deployments starting November 1 to reduce critical bugs by 40%. All pull requests must have two approvals before merging to main.

> **ANNOTATION -- Context Section:** This section exists for readers who want to understand the rationale. It provides evidence-based justification using three specific data points (73%, 40%, 25%) rather than vague claims like "data shows improvement." The numbers build credibility and pre-empt the question "Why are we doing this?" Notice this section is only two sentences. BLUF memos keep context minimal because the decision has already been stated.

**Context:** Our Q3 incident report showed 73% of production issues stemmed from single-reviewer approvals missing edge cases. Teams with dual-review processes had 40% fewer critical bugs and 25% faster resolution times.

> **ANNOTATION -- Policy Changes (Details Section):** Bullet format enables rapid scanning. Each bullet follows a consistent pattern: scope + new requirement + parenthetical comparison to old policy. This structure lets the reader instantly identify what changed and what stayed the same. The "no change" notes for feature branches and documentation updates prevent unnecessary concern.

**Policy Changes:**

- **Production deployments:** Two approvals required (previously one)
- **Feature branches:** One approval sufficient (no change)
- **Hotfixes:** Two approvals required, but expedited review SLA (2 hours vs 24 hours)
- **Documentation updates:** No approval required (no change)

> **ANNOTATION -- Implementation Details:** This paragraph removes friction by telling readers they do not need to take action ("no action needed from team leads") and setting expectations for turnaround times. Proactively addressing logistics prevents a flood of follow-up questions. The paragraph stays short (three sentences) to maintain scannability.

**Implementation Details:**

The new policy applies to all repositories marked "production" in our GitHub organization. We've updated branch protection rules automatically - no action needed from team leads. Engineers should expect review turnaround within 24 hours for standard PRs and 2 hours for hotfixes.

> **ANNOTATION -- Expected Impact:** This section balances honesty about costs (4 hours additional per PR) with benefits (fewer bugs, better knowledge sharing, improved onboarding). Leading with the trade-off builds trust. The projected metric ("12 to 7 incidents per quarter") gives the team a measurable benchmark to evaluate the policy later.

**Expected Impact:**

- Review time increases by average 4 hours per PR
- Critical bug rate projected to drop from 12 to 7 incidents per quarter
- Knowledge sharing improves across team boundaries
- Onboarding effectiveness increases (junior devs learn from dual reviews)

> **ANNOTATION -- Next Steps:** Three concrete action items with specific dates create a clear timeline. The progression (Today, October 30, November 1) gives readers a sense of momentum. "Takes effect automatically" reinforces that no manual action is required on November 1.

**Next Steps:**

- **Today:** Review updated policies at wiki.company.com/code-review
- **October 30:** Attend optional Q&A session (3pm, Zoom link in calendar)
- **November 1:** New policy takes effect automatically

> **ANNOTATION -- Closing:** The closing serves two functions: (1) it provides a channel for objections ("Questions or concerns? Contact me directly"), and (2) it ends on a confident, forward-looking note. The tone is assertive but not dismissive. The phrase "maintaining development velocity" directly addresses the most likely objection (that reviews will slow us down).

Questions or concerns? Contact me directly or raise them in tomorrow's Q&A session. I'm confident this change will strengthen our code quality while maintaining development velocity.

---

## Analysis: Why This Memo Works

Use this analysis to understand the principles behind the example. When generating BLUF memos, reproduce these structural patterns while adapting content to the user's specific situation.

### Framework Compliance

| BLUF Element | How This Example Implements It |
|---|---|
| **BLUF statement** | First paragraph delivers complete message (what + when + why + specific requirement) |
| **5 Ws answered** | Who: Engineering Team. What: Two-reviewer approval. When: November 1. Where: Production repos. Why: Reduce critical bugs 40% |
| **Context section** | Two sentences of evidence-based rationale with three quantified data points |
| **Details section** | Bullet-formatted policy changes with consistent structure |
| **Action items** | Three dated next steps with clear ownership |

### Deliverable Compliance

| Memo Requirement | This Example |
|---|---|
| **Header block** | Complete (TO/FROM/DATE/SUBJECT) |
| **Length** | ~280 words, fits 1 page |
| **Formality** | Medium -- professional but conversational ("We're implementing," not "It is hereby mandated") |
| **Structure** | BLUF after header, context, details in bullets, next steps with dates |
| **Tone** | Confident, direct, action-oriented with empathy in closing |

### Quality Metrics

| Metric | Target | This Example |
|---|---|---|
| Flesch Reading Ease | 50-60 | ~55 |
| Avg paragraph length | 3-5 sentences | 4 sentences |
| Active voice ratio | 80%+ | ~85% |
| Visual density | ~1 element per 2 paragraphs | Headers + bullets throughout |

### Techniques That Strengthen This Memo

1. **Immediate clarity.** The reader knows the decision, timeline, and reason in the first two sentences. No preamble, no throat-clearing, no "I'm writing to inform you about..."
2. **Evidence-based credibility.** Three specific data points (73%, 40%, 25%) replace vague claims. "Our Q3 incident report showed" cites a concrete source.
3. **Actionable next steps.** Each item has a specific date and a clear action. "Today: Review updated policies" is stronger than "Please review the policies at your convenience."
4. **Empathetic closing.** "Questions or concerns?" and "optional Q&A session" acknowledge that the team may have objections. This prevents the memo from feeling dictatorial.
5. **Scannable structure.** Bold headers and bullet lists allow a busy reader to extract key information in under 30 seconds without reading every word.
6. **Trade-off transparency.** The Expected Impact section leads with the cost ("4 hours additional per PR") before listing benefits. This builds trust by showing the author has considered downsides.

### Common Mistakes This Example Avoids

| Mistake | What Would Go Wrong | What This Example Does Instead |
|---|---|---|
| Fake BLUF (burying the lead) | "I'm writing to discuss our code review process..." wastes the reader's time | Opens with the decision and deadline in sentence one |
| Missing deadline | "We're changing the policy soon" creates ambiguity | States "November 1" in both the BLUF and the subject line |
| Vague quantification | "Significant improvement in bug rates" lacks credibility | Uses "40% fewer critical bugs" and "73% of production issues" |
| No next steps | Reader finishes the memo unsure what to do | Three dated action items with clear expectations |
| Overly formal tone | "It is hereby mandated that all personnel shall comply" alienates the audience | Uses "We're implementing" and "Questions or concerns?" |

### Framework Selection Rationale

This memo uses BLUF instead of SCQA or Pyramid because:

- **The decision is already made.** BLUF announces decisions. SCQA builds a case toward a recommendation. This memo is not asking for input on whether to change the policy.
- **The audience values speed.** Engineers are busy. They need to know what changed, when, and what to do. BLUF delivers that in under 10 seconds of reading.
- **The topic is straightforward.** A code review policy update does not require narrative persuasion. If the change were controversial (such as a layoff or a major reorg), SCQA's gradual context-building would be more appropriate.

## Generation Checklist

When generating a BLUF memo, verify your output against this checklist before delivering it to the user:

- [ ] Header block is complete (TO/FROM/DATE/SUBJECT)
- [ ] SUBJECT line previews the BLUF content with action and timeline
- [ ] BLUF paragraph appears immediately after the header
- [ ] BLUF answers at least 4 of the 5 Ws (Who, What, When, Where, Why)
- [ ] BLUF contains a specific deadline or timeline (if applicable)
- [ ] Context section provides evidence, not just assertions
- [ ] Details use bullets or tables for scannability
- [ ] Next steps include specific dates and clear actions
- [ ] Closing provides a channel for questions or feedback
- [ ] Total length stays within 1 page (~300-500 words)
- [ ] Active voice used in 80%+ of sentences
- [ ] No throat-clearing or preamble before the BLUF
