---
title: Professional Memos
type: deliverable
category: deliverable-type
tags: [memo, internal-communication, business-writing]
formality: medium
audience: [internal]
typical-length: 1-page
recommended-frameworks: [bluf, pyramid, scqa]
recommended-principles: [clarity, conciseness, active-voice]
related:
  - emails
  - briefs
  - reports
version: 2.0
last_updated: 2026-02-25
---

# Professional Memos

<purpose>
This reference teaches you how to produce effective business memos. A memo is a short, structured internal document that communicates a decision, directive, status update, or request to a defined audience within an organization. Use this reference whenever the requested deliverable type is "memo."
</purpose>

## Quick Reference

| Attribute | Value |
|-----------|-------|
| Purpose | Brief internal communication: decisions, directives, updates, requests |
| Length | 400-600 words (1 page) |
| Formality | Medium -- professional but direct, uses "we" and "you" |
| Audience | Internal colleagues, teams, leadership |
| Best frameworks | BLUF (default), Pyramid Principle, SCQA |
| Key principles | Clarity, conciseness, active voice |

## Decision Logic: Choosing the Right Framework

Think step by step when selecting a framework for the memo:

1. **Is the memo announcing a decision, policy, or directive?** Use BLUF. The reader needs the conclusion first, details second.
2. **Is the memo presenting an argument with supporting reasons?** Use Pyramid Principle. Lead with the answer, then group supporting points.
3. **Is the memo raising a problem that requires a decision from someone else?** Use SCQA. Walk the reader from shared context into the question and your recommended answer.

When in doubt, default to BLUF. It is the most universally effective memo framework.

## Mandatory Structure

Every memo MUST contain these four sections in this order.

### 1. Header Block

```
TO: [Recipient name, title, or department]
FROM: [Author name, title]
DATE: [Full date, e.g., February 25, 2026]
SUBJECT: [Specific, action-oriented subject line]
```

The SUBJECT line is the most important line in the memo. It must tell the reader exactly what the memo is about and, when applicable, what action is needed. Think of it as a newspaper headline.

**Before (vague):** "Update on Q4"
**After (specific):** "Q4 Campaign Launch Delayed to November 15 -- No Budget Impact"

**Before (passive):** "Regarding the New Policy"
**After (action-oriented):** "New Code Review Policy: Two Approvals Required Starting November 1"

### 2. Opening Paragraph (The BLUF)

State the purpose of the memo in the first 1-3 sentences. The reader should understand the core message without reading further. Answer: What happened or what needs to happen? Why does it matter? What do you need from the reader?

**Before (buries the lead):**
> As many of you are aware, our vendor relationships have been under review for the past several months. After extensive analysis and multiple rounds of negotiation, we have arrived at a conclusion regarding the Q4 campaign timeline that I would like to share with the team.

**After (BLUF):**
> We are delaying the Q4 campaign launch from November 1 to November 15 due to vendor delivery delays. All other timelines and budgets remain unchanged. No action is required from the team at this time.

### 3. Body (Context, Evidence, Details)

Provide the supporting information the reader needs. Follow these rules:

- **Paragraphs:** 2-4 paragraphs maximum, each 3-4 lines
- **Bullet points:** Use for lists of 3+ items, options, or impacts
- **Tables:** Use for comparisons (keep to 3-5 rows)
- **Data over adjectives:** Write "grew 40%" not "grew significantly"
- **Only essential information:** If a detail does not help the reader understand the BLUF or take the requested action, cut it

### 4. Closing (Action Items and Next Steps)

End with concrete, time-bound action items. Each action item must answer: Who does what by when?

**Before (vague):**
> Please review and let me know your thoughts when you get a chance.

**After (specific):**
> - Engineering: Update GitHub branch protection rules by October 30
> - Team leads: Brief your teams on the new policy by November 1
> - Questions: Post in #eng-code-review by October 29

## Framework Application: Full Examples

### BLUF Memo (Default -- Use for Announcements, Directives, Updates)

```markdown
TO: Marketing Team
FROM: Sarah Johnson, Marketing Director
DATE: February 25, 2026
SUBJECT: Q4 Campaign Launch Delayed to November 15 -- No Budget Impact

We are delaying the Q4 campaign launch from November 1 to November 15 due to
vendor delays on creative assets. All budgets and other timelines remain unchanged.

Context: Our primary vendor experienced supply chain issues affecting creative
asset delivery. They have committed to delivery by November 8, giving us one week
for final review before launch.

Impact:
- Holiday shopping season coverage reduced by 2 weeks
- Budget allocation remains the same ($150K)
- Team bandwidth freed for year-end planning through November 14

Next Steps:
- Vendor delivers assets: November 8
- Final review meeting: November 10 at 2 PM (calendar invite sent)
- Campaign launch: November 15
- Questions: Contact me directly or post in #q4-campaign

Please adjust your calendars accordingly.
```

**Why this works:** The subject line tells you the decision and its impact. The first sentence states the delay, cause, and reassurance. The body provides only what the reader needs: timeline, budget confirmation, and exact next steps with dates.

### SCQA Memo (Use When Requesting a Decision)

```markdown
TO: Executive Leadership
FROM: Maria Chen, Operations Director
DATE: February 25, 2026
SUBJECT: Decision Required: Warehouse Expansion Approach by March 1

Situation: Our warehouse operates at 95% capacity. Order volume grew 40% this year,
and fulfillment delays have increased from 2 days to 5 days average.

Complication: We are turning away $2M in new business annually because we cannot
guarantee delivery times. Two competitors added capacity last quarter and are
winning accounts we previously held. The upcoming holiday season will push us past
100% capacity.

Question: Should we expand our current facility or lease additional space?

Recommendation: Lease 50,000 sq ft of additional space within 30 days while
planning permanent expansion for next year.

| Option | Cost | Timeline | Risk |
|--------|------|----------|------|
| Lease additional space | $30K/month | 30 days | Low -- reversible |
| Expand current facility | $2M capital | 8 months | Medium -- construction |
| Do nothing | $0 | N/A | High -- lose $2M+ revenue |

The lease provides immediate relief while we design the optimal long-term solution.
Permanent expansion planning can proceed in parallel.

Action Required: Approve lease authority by March 1 for April 1 occupancy.
```

**Why this works:** SCQA walks leadership from a shared understanding of the situation through the complication, makes the decision question explicit, then provides a clear recommendation with a comparison table. The action item is specific and time-bound.

### Pyramid Principle Memo (Use for Policy Changes with Supporting Rationale)

```markdown
TO: Engineering Team
FROM: James Park, VP Engineering
DATE: February 25, 2026
SUBJECT: New Code Review Policy: Two Approvals Required Starting March 1

Starting March 1, all pull requests require two approvals before merging. This
replaces our current single-approval process.

Three Key Changes:
1. Minimum approvals increased from 1 to 2
2. PR turnaround may increase by 24-48 hours
3. Production emergencies: Engineering manager can grant single-approval override

Why This Change: Our Q3 incident review found that 60% of production bugs came
from PRs with only one reviewer. Two-reviewer PRs had a 40% lower defect rate.
This aligns with industry best practice (Google, Stripe, and Datadog all require
2+ reviewers).

Benefits:
- Projected 40% reduction in production bugs
- Better knowledge sharing across the team
- Improved code documentation as a side effect
- Alignment with SOC 2 compliance requirements

Implementation:
- GitHub branch protection updated: February 28
- New policy active: March 1
- Review guidelines: [link to internal wiki]
- Questions: #eng-code-review Slack channel
```

**Why this works:** The answer comes first (Pyramid Principle). Supporting points are grouped into three clear categories: what changes, why, and how it gets implemented. Each section earns its place by answering a question the reader would naturally ask.

## Common Memo Variations

Apply these adjustments based on memo subtype:

| Variation | Key Adjustments |
|-----------|----------------|
| **Policy memo** | More formal tone. Include effective date, definition of terms, and consequences of non-compliance. |
| **Status update memo** | Include current state vs. target, key metrics with numbers, challenges, and next milestones. |
| **Decision memo** | Use SCQA. Include options analyzed, recommendation with rationale, and approval request with deadline. |
| **Directive memo** | Authoritative tone. State what must happen, by when, and who is responsible. Include contact for questions. |

## Writing Quality Rules

Apply these rules during drafting. They are listed in priority order.

### Rule 1: Lead with the Point (Non-Negotiable)

The first paragraph must contain the core message. If a reader stops after the first paragraph, they must still understand the memo's purpose.

**Test:** Cover everything below the first paragraph. Does the reader know what the memo is about and what (if anything) they need to do? If not, rewrite the opening.

### Rule 2: Use Concrete Data Instead of Qualitative Language

| Write This | Not This |
|------------|----------|
| Orders grew 40% this year | Orders grew significantly |
| Fulfillment delays increased from 2 to 5 days | Fulfillment delays have worsened |
| We will save $30K per quarter | We will achieve meaningful cost savings |
| 3 of 5 team leads approved | Most team leads approved |

### Rule 3: Use Active Voice

| Write This | Not This |
|------------|----------|
| We will launch the campaign November 15 | The campaign will be launched November 15 |
| Engineering must update the settings by Friday | The settings should be updated by Friday |
| I recommend leasing additional space | It is recommended that additional space be leased |

### Rule 4: Eliminate Filler Words and Phrases

| Write This | Not This |
|------------|----------|
| To meet the deadline | In order to meet the deadline |
| Now | At this point in time |
| Because | Due to the fact that |
| Can | Is able to |
| If | In the event that |

### Rule 5: Keep Sentences Short

Target 15-20 words per sentence. If a sentence exceeds 25 words, split it. Long sentences in memos signal that the writer has not done the work of clarifying their thinking.

### Rule 6: Hit the Right Tone

Memos use a professional-but-direct tone. Use "we" and "you." Avoid both stiff formality and casual slack-speak.

**Too formal:** "It is hereby requested that approval be granted by the end of business on Friday."
**Too casual:** "Hey, can you approve this by Friday?"
**Right tone:** "We need your approval by Friday to meet the vendor deadline."

## Length Enforcement

**Target:** 400-600 words (1 page).

If your draft exceeds 600 words, apply these compression techniques in order:

1. **Cut background.** Assume the reader has context unless they clearly do not.
2. **Convert prose to bullets.** Three sentences about impacts become three bullet points.
3. **Use a table.** A paragraph comparing options becomes a 3-column table.
4. **Remove examples.** Keep the data point, cut the illustration.
5. **Reconsider the format.** If the memo still exceeds 1 page after compression, it may need to be a brief or report instead.

## Pre-Delivery Validation Checklist

Before delivering the memo, verify each item. Every item must pass.

- [ ] Header block is complete: TO, FROM, DATE, SUBJECT all present
- [ ] SUBJECT line is specific and action-oriented (not vague like "Update" or "FYI")
- [ ] First paragraph states the core message (passes the "cover test" from Rule 1)
- [ ] Every action item specifies who, what, and by when
- [ ] All claims use concrete data, not qualitative language (Rule 2)
- [ ] Active voice used throughout (Rule 3)
- [ ] No filler phrases remain (Rule 4)
- [ ] No sentence exceeds 25 words (Rule 5)
- [ ] Tone is professional-but-direct (Rule 6)
- [ ] Total length is 400-600 words
- [ ] Framework applied correctly (BLUF/Pyramid/SCQA structure is intact)
- [ ] All citations from source material are preserved per skill constraints

## See Also

- **Similar formats:** `emails.md`, `briefs.md`
- **Frameworks:** `../02-messaging-frameworks/bluf-framework.md`, `../02-messaging-frameworks/pyramid-framework.md`, `../02-messaging-frameworks/scqa-framework.md`
- **Principles:** `../01-core-principles/clarity-principles.md`, `../01-core-principles/conciseness-principles.md`
- **Examples:** `../05-examples/example-memo-bluf.md`, `../05-examples/example-memo-pyramid.md`
- **Template:** `../06-templates/template-memo.md`
