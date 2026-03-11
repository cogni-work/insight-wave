---
title: SCQA Framework (Situation-Complication-Question-Answer)
type: messaging-framework
category: communication-framework
tags: [scqa, minto, problem-solving, narrative, storytelling]
audience: [all]
best-for: [memos, briefs, proposals, reports]
origin: barbara-minto
formality: medium-high
related:
  - pyramid-framework
  - bluf-framework
  - psb-framework
version: 2.0
last_updated: 2026-02-25
---

# SCQA Framework (Situation-Complication-Question-Answer)

## Quick Reference

**Best for:** Memos, briefs, proposals, reports
**Structure:** Situation -> Complication -> Question -> Answer
**When to use:** Audience needs persuading, problem requires context, narrative arc aids understanding
**Formality:** Medium-high
**Key principle:** Build tension before revealing the solution -- the reader should feel the problem before you offer the answer

## Core Mechanism

SCQA is a narrative persuasion structure. Unlike answer-first frameworks (BLUF, Pyramid), SCQA earns the reader's attention by walking them through the problem before presenting a solution. This makes the answer land harder because the reader already feels the urgency.

Think of it as a four-beat rhythm:

1. **Situation** -- Establish shared reality. What does the reader already know or accept as true? This is the stable ground you both stand on.
2. **Complication** -- Introduce instability. What has changed, gone wrong, or is at risk? This is where tension enters. The reader should think: "That is a problem."
3. **Question** -- Crystallize what must be resolved. This can be stated explicitly or left implicit when the complication makes the question obvious. The reader should think: "So what do we do?"
4. **Answer** -- Deliver your recommendation, solution, or conclusion. This is the payoff. It must directly resolve the question raised by the complication.

### Why This Order Matters

The S-C-Q sequence creates psychological tension. The Answer releases it. Skipping straight to the answer (as BLUF does) works when the audience trusts you. SCQA works when you need to build the case -- when the audience is skeptical, unfamiliar with the problem, or needs to feel urgency before they will act.

## Decision Logic: When to Use SCQA

Use SCQA when ANY of these conditions apply:

- The audience is skeptical or needs convincing before they will accept your recommendation
- The problem is complex enough that jumping to the answer would confuse readers
- You need to create urgency or emotional engagement to drive action
- The reader does not yet understand why the status quo is unacceptable
- A narrative arc will make a dense topic more accessible

Do NOT use SCQA when:

- The audience wants the answer immediately (use BLUF or Pyramid instead)
- The recommendation is straightforward and uncontroversial
- Time pressure demands maximum compression (use BLUF)
- The reader already understands the problem deeply

**Hybrid approach:** Use SCQA for the executive summary to build the case, then switch to Pyramid structure for the body sections. This combines narrative persuasion with structured analysis.

## How to Write Each Component

### Situation: Set the Shared Ground

<purpose>
Establish context the reader already knows or accepts. This is NOT your argument -- it is the baseline reality from which the complication departs.
</purpose>

<rules>
- Keep it brief: 1-3 sentences for memos, 1-2 short paragraphs for reports
- State only facts the reader would nod along to
- Do NOT introduce the problem here -- save that for Complication
- Do NOT include your opinion or recommendation
- Anchor in concrete specifics: revenue figures, market position, team size, timeline
</rules>

<reasoning>
The Situation exists to create agreement. Once the reader is nodding ("yes, that is true"), the Complication hits harder because it disrupts something they just accepted as stable.
</reasoning>

**Strong Situation signals:**
- "Our company currently..."
- "The market for X is..."
- "Over the past [timeframe], we have..."
- "As of [date], the team operates..."

### Complication: Introduce the Problem

<purpose>
Create tension by showing what has changed, what is broken, or what is at stake. This is the engine of the SCQA framework -- a weak Complication produces a weak document.
</purpose>

<rules>
- Make it specific and quantified: dollar amounts, percentages, deadlines, competitive threats
- Show consequences: what happens if nothing changes?
- Create a gap between the Situation (stable) and the Complication (unstable)
- Use concrete evidence, not vague warnings
- The reader should finish this section thinking "we need to do something"
</rules>

<reasoning>
The Complication does the persuasive work. It transforms a comfortable status quo (Situation) into an urgent problem. Without a strong Complication, the Answer feels unnecessary. With a strong Complication, the Answer feels inevitable.
</reasoning>

**Weak vs. Strong Complications:**

| Weak (vague, no stakes) | Strong (specific, consequential) |
|---|---|
| "This might cause some issues." | "This is costing us $5M annually in lost contracts." |
| "Competitors are doing better." | "Three enterprise prospects chose CompetitorX last quarter, citing features we lack." |
| "We should probably look into this." | "At current trajectory, we exceed capacity by December and begin turning away orders." |
| "There are some concerns about quality." | "Defect rates have doubled since Q2, triggering two customer escalations." |

### Question: Frame What Must Be Resolved

<purpose>
Make the central question explicit (or let it emerge naturally from a strong Complication). The Question bridges the problem and the solution.
</purpose>

<rules>
- The Question must follow logically from the Complication -- if the Complication is strong, the Question writes itself
- Frame it as a decision, a "how," or a "what should we do"
- For memos and briefs, the Question can be implicit (embedded in a subject line or left unwritten when obvious)
- For reports and proposals, state the Question explicitly as a clear sentence
- Never introduce new information in the Question
</rules>

**When to make the Question explicit vs. implicit:**

| Explicit (state it) | Implicit (omit it) |
|---|---|
| Reports and formal proposals | Short memos and emails |
| When multiple possible questions exist | When the Complication makes only one question possible |
| When the audience includes mixed stakeholders | When the audience is a single decision-maker |

### Answer: Deliver the Payoff

<purpose>
Present your recommendation, solution, or conclusion. The Answer must directly resolve the Question and address the Complication.
</purpose>

<rules>
- Open with a clear, direct statement of the recommendation
- Follow with 2-4 supporting points that show why this answer works
- Include concrete specifics: cost, timeline, expected outcome, responsible parties
- Use active voice and confident language -- "We recommend..." not "It might be worth considering..."
- End with clear next steps or a call to action
- The reader should be able to trace a straight line from Complication -> Question -> Answer
</rules>

<reasoning>
After building tension through S-C-Q, the Answer provides release. A vague or hedging Answer wastes all the persuasive energy you built. Be direct and specific.
</reasoning>

## Before/After Transformation

### BEFORE: Weak SCQA (common failure modes)

```markdown
## Background

Our company has been in the enterprise software market for over fifteen years.
We have a strong reputation and loyal customer base. The industry has seen many
changes over the years, and we have adapted to most of them successfully.

## Some Challenges

Recently, we have noticed some competitive pressure. There are concerns about
our market position. Some customers have expressed interest in newer solutions.
We might want to think about this going forward.

## Thoughts

Perhaps we should consider updating our product strategy. There are several
options we could explore. It would be good to discuss this further at the
next leadership meeting.
```

**What went wrong:**
- Situation is too long and says nothing specific (no numbers, no anchors)
- Complication is vague -- "some competitive pressure" and "concerns" create no urgency
- Question is missing entirely
- Answer hedges with "perhaps" and "could explore" -- no actual recommendation
- No concrete data anywhere in the document

### AFTER: Strong SCQA (correctly applied)

```markdown
## Situation

Acme serves 340 enterprise customers in North America with $50M annual
recurring revenue. Our net retention rate has held above 110% for three
consecutive years.

## Complication

In Q3, we lost three enterprise renewals worth $2.4M combined to CloudFirst,
a competitor that launched a native AI integration suite in June. Pipeline
analysis shows 12 additional accounts flagged as at-risk for the same reason.
If this trend continues, we project a $8M revenue shortfall by end of FY26.

## Question

How do we close the AI capability gap before the Q1 renewal cycle begins?

## Recommendation

Acquire DataMind for $15M to add their AI integration platform to our
product suite. This closes the gap in 90 days rather than the 18 months
an internal build would require.

Three factors support this:

1. **Speed to market**: DataMind's platform is production-ready with 50+
   enterprise deployments. We ship AI features in Q1 instead of Q3 next year.
2. **Financial fit**: At $15M, the acquisition pays back within two renewal
   cycles. The 12 at-risk accounts alone represent $9.6M in ARR.
3. **Talent acquisition**: DataMind's 25-person engineering team fills our
   ML hiring gap, which has been open for 8 months.

**Next step**: Approve due diligence engagement with DataMind by November 15
to complete acquisition before the Q1 renewal window opens.
```

**What makes this work:**
- Situation is two sentences with concrete numbers ($50M ARR, 340 customers, 110% NRR)
- Complication is specific and alarming ($2.4M lost, 12 at-risk accounts, $8M projected shortfall)
- Question follows directly from the Complication -- it writes itself
- Answer is direct, supported by three concrete arguments, and ends with a clear next step

## Deliverable-Specific Calibration

### Memos (1 page)

- Situation: 1-2 sentences
- Complication: 1-2 sentences with key metric
- Question: Implicit (in subject line or omitted)
- Answer: 1-2 paragraphs with action items
- Total: Fits on one page

**Memo-specific rule:** The subject line should encode the Complication or Question. Example: "Q3 Renewal Losses Require Acquisition Strategy"

### Briefs (1-3 pages)

- Situation: 1 short paragraph
- Complication: 1-2 paragraphs with supporting data
- Question: Explicit, one sentence
- Answer: 2-3 paragraphs with evidence and next steps
- Use bold labels (Situation:, Challenge:, Recommendation:) for scannability

### Proposals

- Situation = market context and client's current state
- Complication = client's pain points with quantified impact
- Question = how to solve their specific problem
- Answer = your solution with evidence, ROI projection, and implementation plan
- Follow the Answer with detailed scope, timeline, and pricing sections

**Proposal-specific rule:** Mirror the client's own language from the RFP or briefing when writing the Situation and Complication. This signals that you understand their world.

### Reports

- Situation = background, literature review, or environmental scan
- Complication = research gap, emerging risk, or performance problem
- Question = explicit research question or decision to be made
- Answer = findings, analysis, and recommendations with supporting evidence
- Extended format: each component can span multiple paragraphs with subheadings

## Compression Scales

Adjust the SCQA density to match the format:

### Ultra-Compressed (Email / Slack)

```markdown
Context: We serve 340 enterprise accounts with $50M ARR.
Problem: Lost $2.4M in Q3 renewals to AI-native competitors; 12 more at risk.
Recommendation: Acquire DataMind ($15M) to close the AI gap before Q1 renewals.
Next step: Approve due diligence by Nov 15.
```

### Standard (Memo)

```markdown
**Situation**: Acme serves 340 enterprise customers with $50M ARR and 110%+
net retention over three years.

**Challenge**: Q3 renewals lost $2.4M to CloudFirst's AI suite. Pipeline
shows 12 additional at-risk accounts. Projected $8M shortfall by FY26 end.

**Recommendation**: Acquire DataMind for $15M to add AI integration in 90
days. Payback within two renewal cycles. Approve due diligence by November 15.
```

### Extended (Report)

Use full section headings (## Situation, ## Complication, ## Question, ## Findings & Recommendations) with multiple paragraphs per section and supporting data tables, charts, or appendix references.

## Framework Variations

### SCR (Situation-Complication-Resolution)

Omit the explicit Question when the Complication makes only one question possible. Go directly from Complication to Resolution. Use this for shorter documents where the Question would feel redundant.

### SCQAI (Add Implications)

Add an "Implications" section after the Answer to spell out broader consequences: what changes across the organization, what second-order effects to expect, what risks remain. Use this for strategic documents where the Answer has wide-ranging impact.

### Multiple Complications

For complex problems with interconnected issues, present 2-3 Complications before the Question. Each Complication should add a new dimension to the problem rather than restating the same issue. Use this when a single Complication undersells the urgency.

## SCQA vs. Related Frameworks

| Dimension | SCQA | Pyramid | BLUF |
|---|---|---|---|
| Opens with | Context (Situation) | Conclusion (Answer) | Action required |
| Persuasion model | Build the case, then reveal answer | Assert answer, then prove it | State the bottom line, explain later |
| Best audience | Skeptical, unfamiliar, needs convincing | Trusting, wants structure | Time-pressed, wants speed |
| Tension arc | High (S-C-Q builds, A releases) | Low (answer given immediately) | None (answer is first sentence) |
| Ideal length | Medium to long | Medium to long | Short |

## Quality Checklist

Before finalizing any SCQA document, verify each item:

- [ ] Situation states only facts the reader already accepts (no argument, no opinion)
- [ ] Situation includes concrete anchors (numbers, dates, names)
- [ ] Complication introduces a specific, quantified problem with real consequences
- [ ] Clear tension exists between the stable Situation and the disruptive Complication
- [ ] Question follows logically from the Complication (explicit or implicit as appropriate)
- [ ] Answer directly resolves the Question with a specific recommendation
- [ ] Answer uses active voice and confident language (no hedging)
- [ ] Answer includes concrete details: cost, timeline, expected outcome, next steps
- [ ] Length is calibrated to the deliverable type
- [ ] A reader could trace the logic from S -> C -> Q -> A without gaps

## Common Mistakes and Fixes

### Mistake 1: Bloated Situation

The Situation section becomes a history lesson instead of a brief anchor.

**Symptom:** More than 3-4 sentences of background before any problem appears.
**Fix:** Cut to only the facts needed to make the Complication meaningful. Ask: "Would the Complication make sense without this sentence?" If yes, delete it.

### Mistake 2: Vague Complication

The Complication describes a mood ("things are challenging") instead of a problem with stakes.

**Symptom:** No numbers, no deadlines, no named consequences.
**Fix:** Add at least one quantified impact (dollars lost, percentage decline, customers at risk, deadline missed). If you cannot quantify the Complication, you do not yet understand the problem well enough to write the document.

### Mistake 3: Disconnected Question

The Question does not follow from the Complication, or introduces a new topic entirely.

**Symptom:** The reader would not naturally ask this Question after reading the Complication.
**Fix:** Read the Complication aloud and ask yourself "So what do we do about that?" -- the answer to that meta-question is your Question.

### Mistake 4: Hedging Answer

The Answer uses weak language that undercuts the persuasive tension built by S-C-Q.

**Symptom:** "We might consider..." / "One option could be..." / "It may be worth exploring..."
**Fix:** Replace with direct recommendations: "We recommend..." / "The solution is..." / "Acquire X for $Y by [date]."

## See Also

- `pyramid-framework.md` (Answer-first alternative when audience trusts you)
- `bluf-framework.md` (Ultra-compressed answer-first for time-pressed audiences)
- `psb-framework.md` (Similar problem-solution structure, lighter weight)
- `../01-core-principles/clarity-principles.md` (Clear language requirements)
