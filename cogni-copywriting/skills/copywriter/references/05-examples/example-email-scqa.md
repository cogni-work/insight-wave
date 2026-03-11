---
title: Example Email - SCQA Framework
type: example
category: deliverable-example
deliverable: email
framework: scqa
tags: [example, email, scqa, business-communication, persuasive-narrative]
quality-metrics:
  flesch-score: 58
  avg-paragraph-length: 3
  formality: medium
  word-count: 245
  active-voice-ratio: 0.87
version: 2.0
last_updated: 2026-02-25
---

# Example Email - SCQA Framework

<purpose>
This reference teaches Claude how to write a business email using the SCQA (Situation-Complication-Question-Answer) framework. Study the annotated example below to understand both the structural pattern and the reasoning behind each writing decision.
</purpose>

## When to Use This Example

Apply this pattern when the email meets ALL of these conditions:

1. The reader needs context before they can evaluate your recommendation
2. The recommendation may face resistance or skepticism
3. You are proposing a change, not announcing a decision
4. A narrative arc (tension then resolution) will be more persuasive than leading with the answer

If the reader already has context or the message is a directive, use BLUF instead. See `example-memo-bluf.md` for that pattern.

---

## Annotated Example

<!-- ANNOTATION FORMAT: Each section of the email is followed by an [ANNOTATION] block
explaining WHY it works and WHAT PATTERN it demonstrates. Claude should internalize
these patterns for generating new SCQA emails, not reproduce the annotations in output. -->

**Subject:** Solution for Q4 Budget Shortfall - Marketing Reallocation Proposal

<!-- [ANNOTATION: SUBJECT LINE]
Structure: [Benefit keyword] + [Problem context] + [Action type]
- "Solution" front-loaded = positive framing, reader opens expecting a resolution
- "Q4 Budget Shortfall" = specific topic, no ambiguity about what this concerns
- "Marketing Reallocation Proposal" = sets expectation that a decision is requested
- 9 words = optimal length for mobile preview (50 chars visible on most devices)
- Avoids vague subjects like "Budget Update" or "Marketing Question"
-->

Hi Sarah,

**Situation:** We're tracking toward our Q4 revenue target of $2.4M with strong performance in enterprise accounts (110% of plan). Our SMB segment is running at 78% of plan due to competitive pressure from two new entrants.

<!-- [ANNOTATION: SITUATION SECTION]
Pattern: Establish shared reality with verifiable facts before introducing the problem.

Techniques used:
- ANCHORING with a positive fact first ("110% of plan") = builds credibility before
  delivering bad news. The reader trusts the analysis because it acknowledges what
  IS working, not just what is broken.
- SPECIFIC METRICS ("$2.4M", "110%", "78%") = demonstrates command of the data.
  Vague language like "mostly on track" would undermine authority.
- CAUSAL ATTRIBUTION ("due to competitive pressure from two new entrants") =
  signals the shortfall has an external cause, not internal incompetence.
  This protects the reader from feeling blamed.
- LENGTH DISCIPLINE: 2 sentences. The Situation should be the shortest SCQA
  section in emails. Over-explaining context signals insecurity about the
  recommendation. Provide just enough for the reader to orient.

Common mistake to avoid: Writing 5+ sentences of background. If the reader
already knows Q4 targets, even this much context may be excessive. Calibrate
to the reader's existing knowledge.
-->

**Complication:** Marketing allocated 60% of Q4 budget to SMB campaigns, but ROI is now 3.2:1 versus enterprise ROI of 8.5:1. If we maintain current allocation, we'll miss Q4 target by approximately $180K despite having high-performing channels available.

<!-- [ANNOTATION: COMPLICATION SECTION]
Pattern: Create tension by showing the GAP between current state and desired outcome.
The Complication must make the reader feel the cost of inaction.

Techniques used:
- CONTRAST PAIR ("3.2:1 versus enterprise ROI of 8.5:1") = makes the
  misallocation self-evident through direct comparison. The reader draws the
  conclusion themselves rather than being told what to think.
- QUANTIFIED CONSEQUENCE ("miss Q4 target by approximately $180K") = converts
  an abstract problem into a dollar figure the reader can feel. "We might
  underperform" is forgettable; "$180K shortfall" triggers loss aversion.
- CONDITIONAL FRAMING ("If we maintain current allocation") = implies the
  problem is solvable. This is the hinge of SCQA: the Complication must
  simultaneously create urgency AND signal that an answer exists.
- IRONY HOOK ("despite having high-performing channels available") = the best
  complications contain an irony or contradiction. Here: we have the solution
  already but are not using it. This creates cognitive tension the reader
  wants resolved.

Common mistake to avoid: Weak complications that don't quantify stakes.
"SMB isn't performing well" lacks the urgency of "$180K shortfall."
-->

**Question:** Should we reallocate underperforming SMB budget to double down on enterprise momentum?

<!-- [ANNOTATION: QUESTION SECTION]
Pattern: Frame the decision as a clear choice that flows inevitably from the
Complication. The Question should feel like the only logical thing to ask.

Techniques used:
- BINARY FRAMING ("Should we reallocate...") = presents one clear decision
  rather than an open-ended "What should we do?" Open questions create
  decision fatigue. Binary questions invite a yes/no plus discussion.
- EMBEDDED JUDGMENT ("underperforming SMB", "double down on enterprise
  momentum") = the word choices subtly advocate for the answer. "Underperforming"
  presupposes the reallocation is warranted. "Double down on momentum"
  frames the shift as accelerating success, not abandoning a segment.
- SINGLE SENTENCE = the Question must be brief. It is a pivot point, not
  an argument. Extended questions dilute the tension built in the Complication.

Common mistake to avoid: Questions that don't connect to the Complication.
If the Complication is about ROI mismatch, the Question must be about
reallocation, not about "how to improve SMB performance."
-->

**Answer:** I recommend shifting $75K from SMB digital ads to enterprise account-based marketing and field events. This reallocation would:

- Increase projected enterprise revenue by $240K (based on current 8.5:1 ROI)
- Accelerate three pipeline opportunities currently at 85% close probability
- Maintain minimum viable SMB presence ($50K budget remaining)
- Close revenue gap and potentially exceed Q4 target by 2-3%

<!-- [ANNOTATION: ANSWER SECTION]
Pattern: Deliver a specific, actionable recommendation with quantified outcomes.
The Answer must DIRECTLY resolve the Question and the Complication.

Techniques used:
- CONFIDENT STANCE ("I recommend") = active voice, first person, declarative.
  Not "We could consider" or "One option might be." The reader wants a
  recommendation, not a menu of options.
- SPECIFIC ACTION ("shifting $75K from SMB digital ads to enterprise ABM
  and field events") = names the exact amount, source, and destination.
  The reader can evaluate and approve without asking follow-up questions.
- BULLET LIST for benefits = scannable on mobile, each benefit is self-
  contained. Ordered from highest impact ($240K revenue) to strategic
  outcome (exceed target).
- EVIDENCE CALLBACK ("based on current 8.5:1 ROI") = ties the projection
  back to the data established in the Complication. The math is verifiable.
- OBJECTION PREEMPTION ("Maintain minimum viable SMB presence") = the third
  bullet anticipates the reader's concern about abandoning SMB entirely.
  Including this INSIDE the answer (not as a separate caveat) signals
  that the recommendation already accounts for the tradeoff.

Common mistake to avoid: Answers that introduce new information not
grounded in the Situation/Complication. Every claim in the Answer should
trace back to evidence already presented.
-->

**Trade-offs:** We'd reduce SMB lead volume by ~200 leads, but our current conversion rate suggests only 6-8 would close this quarter anyway (~$24K revenue). The enterprise opportunity is substantially higher.

<!-- [ANNOTATION: TRADE-OFFS SECTION]
Pattern: Acknowledge the cost of the recommendation honestly, then show
it is acceptable. This section is optional but significantly increases
persuasiveness for recommendations involving resource shifts.

Techniques used:
- HONEST CONCESSION ("reduce SMB lead volume by ~200 leads") = naming
  the downside first builds trust. Readers distrust proposals that
  present only upside.
- CONTEXTUALIZING THE COST ("only 6-8 would close... ~$24K revenue") =
  translates the abstract loss (200 leads) into its actual business
  impact ($24K). The small dollar figure makes the tradeoff self-evidently
  worthwhile when compared to the $240K enterprise upside.
- IMPLICIT COMPARISON = the reader does the math themselves: $24K risk
  versus $240K gain. Letting the reader reach this conclusion independently
  is more persuasive than stating "the enterprise opportunity is 10x larger."
  The final sentence ("substantially higher") merely confirms what the
  reader already calculated.
-->

**Next Steps:** Can we discuss this Wednesday? I've prepared detailed analysis with account-specific projections and timeline for budget transfer. We'd need to move by Friday to capture the field event opportunity.

<!-- [ANNOTATION: NEXT STEPS / CLOSE]
Pattern: Convert the recommendation into a specific, time-bound action
request. Every persuasive email must end with a clear ask.

Techniques used:
- SPECIFIC MEETING REQUEST ("this Wednesday") = not "sometime this week"
  or "when you're free." Specific proposals are easier to accept or
  counter-propose than open-ended requests.
- PREPARED EVIDENCE ("I've prepared detailed analysis") = signals
  thoroughness and reduces the reader's perceived effort. They don't
  need to request more information; it already exists.
- URGENCY WITH JUSTIFICATION ("move by Friday to capture the field event
  opportunity") = the deadline is tied to a real business reason, not
  artificial pressure. Readers respect justified urgency and resent
  manufactured urgency.
- COLLABORATIVE TONE ("Can we discuss") = frames the next step as dialogue,
  not a demand. This is appropriate for SCQA emails because the framework
  inherently invites the reader into the decision process.

Common mistake to avoid: Closing with "Let me know what you think" without
a specific action or timeline. This creates ambiguity about what happens next.
-->

Let me know your availability. Happy to share the detailed analysis beforehand if helpful.

Best,
Marcus

---

## Structural Pattern Summary

Use this pattern when generating new SCQA emails:

```
SUBJECT LINE: [Benefit/Solution keyword] + [Problem context] + [Action type]

GREETING

SITUATION (2-3 sentences max):
  - Establish shared context with verifiable facts
  - Lead with what IS working before introducing the gap
  - Include specific metrics to establish credibility

COMPLICATION (2-3 sentences max):
  - Show the gap between current state and goal
  - Quantify the cost of inaction in dollars or measurable impact
  - Include a contrast or irony that creates cognitive tension
  - Use conditional framing ("If we maintain...") to imply solvability

QUESTION (1 sentence):
  - Frame as a binary or focused decision, not open-ended
  - Word choice should subtly favor the recommended answer
  - Must flow inevitably from the Complication

ANSWER (1 sentence + 3-5 bullets):
  - Lead with "I recommend" + specific action
  - Bullet benefits from highest to lowest impact
  - Reference evidence from earlier sections
  - Preempt the most likely objection within the benefits

TRADE-OFFS (optional, 1-2 sentences):
  - Name the downside honestly
  - Contextualize the cost to show it is acceptable
  - Let the reader do the comparison math

NEXT STEPS (2-3 sentences):
  - Propose a specific time for discussion or decision
  - Reference prepared supporting materials
  - Justify any deadline with a real business reason

SIGN-OFF
```

## Quality Benchmarks

When generating an SCQA email, verify the output meets these thresholds:

| Metric | Target | Rationale |
|--------|--------|-----------|
| Total word count | 200-300 | Email best practice; respects reader time |
| Flesch Reading Ease | 50-65 | Business-professional register |
| Active voice ratio | > 80% | Conveys confidence and clarity |
| Paragraphs | 5-7 | Scannable on mobile without excessive scrolling |
| Sentences per paragraph | 2-4 | Short paragraphs improve mobile readability |
| Specific metrics | 4+ | Quantified claims build credibility |
| Subject line length | 6-10 words | Optimal for mobile preview |
| Bullets in Answer | 3-5 | Enough to be comprehensive, few enough to scan |

## SCQA vs BLUF: Decision Logic

Choose the framework BEFORE writing. Apply this decision tree:

```
Does the reader need context to evaluate the recommendation?
  YES --> Does the recommendation face potential resistance?
    YES --> Use SCQA (this pattern)
    NO  --> Use BLUF with brief context paragraph
  NO  --> Is this a decision announcement or directive?
    YES --> Use BLUF (see example-memo-bluf.md)
    NO  --> Use BLUF for speed; SCQA only if narrative adds value
```

Key signals for SCQA over BLUF:
- The recommendation involves reallocating resources from one area to another
- Multiple stakeholders have competing interests
- The data requires interpretation, not just reporting
- The reader's instinct might oppose the recommendation without context

Key signals for BLUF over SCQA:
- The reader expects and wants the answer immediately (executives, urgent situations)
- The recommendation is non-controversial
- The email announces a decision already made
- Time sensitivity is high (the reader has 30 seconds)

## Common Generation Errors

When producing SCQA emails, watch for these failure modes:

1. **Bloated Situation** -- Writing 5+ sentences of background. The Situation is context, not a history lesson. If the reader knows the context, compress or skip.

2. **Weak Complication** -- Failing to quantify the stakes. "Performance could be better" does not create tension. "$180K shortfall" does.

3. **Open-ended Question** -- Asking "What should we do?" instead of framing a specific decision. Open questions create decision fatigue; focused questions invite action.

4. **Hedged Answer** -- Writing "We could consider shifting..." instead of "I recommend shifting $75K..." Tentative language undermines the entire SCQA arc.

5. **Missing Tradeoff Acknowledgment** -- Presenting only upside. Readers distrust one-sided proposals. Name the cost, then contextualize it.

6. **Vague Next Steps** -- Closing with "Let me know your thoughts" without proposing a specific time, action, or deadline.

7. **Label Leakage** -- Including the literal labels "Situation:", "Complication:", etc. in the final output when the brief does not request them. SCQA labels are a writing tool; the reader may or may not need to see them depending on formality and audience expectations.
