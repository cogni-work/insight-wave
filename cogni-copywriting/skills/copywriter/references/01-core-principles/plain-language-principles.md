---
title: Plain Language Principles
type: writing-principle
category: core-principles
tags: [plain-language, accessibility, clarity, universal-comprehension]
audience: [all]
related:
  - clarity-principles
  - conciseness-principles
  - readability-principles
version: 2.0
last_updated: 2026-02-25
---

# Plain Language Principles

## Purpose

This reference teaches you how to apply plain language when writing or polishing business documents. Plain language means the reader understands the text on first reading without re-reading any sentence.

**Apply these principles to every deliverable.** They are mandatory for customer-facing, cross-functional, and broad-audience documents.

## Decision Framework

When you encounter any sentence during writing or editing, run through these checks in order. Stop at the first check that fails, fix it, then continue.

```
Step 1: Can the reader identify WHO does WHAT within 3 seconds?
        -> If no: Rewrite in active voice with a clear subject.

Step 2: Would a non-specialist understand every word?
        -> If no: Replace jargon with common words, or define the term inline.

Step 3: Is the sentence under 20 words?
        -> If no: Split into two sentences at the natural break point.

Step 4: Does the sentence start with the main point?
        -> If no: Move the conclusion or action to the front.

Step 5: Can any word be removed without changing meaning?
        -> If yes: Remove it.
```

## Core Principles

### 1. Use Common Words

Replace formal, Latinate, or bureaucratic vocabulary with everyday equivalents. The test: would you use this word in a conversation with a colleague?

**Word replacement table -- apply these substitutions systematically:**

| Replace this | With this |
|---|---|
| ascertain | find out |
| commence | start, begin |
| endeavor | try |
| facilitate | help, make easier |
| implement | start, carry out, set up |
| leverage | use |
| necessitate | require, need |
| obtain | get |
| optimum | best |
| prioritize | rank, put first |
| purchase | buy |
| terminate | end, stop |
| utilize | use |
| subsequent | next, later |
| aforementioned | this, that, the |
| herein | here, in this document |
| notwithstanding | despite, even though |
| pertaining to | about, related to |

<example>
<input>We will utilize the new platform to optimize operational efficiencies across all business units.</input>
<output>We will use the new platform to improve how every team works.</output>
<reasoning>
- "utilize" -> "use" (common word)
- "optimize operational efficiencies" -> "improve how every team works" (concrete, human-readable)
- "across all business units" -> "every team" (shorter, same meaning)
</reasoning>
</example>

<example>
<input>Pursuant to our recent communication regarding the aforementioned matter, we wish to ascertain whether you have obtained the requisite documentation.</input>
<output>Following up on our last conversation: do you have the documents we need?</output>
<reasoning>
- "Pursuant to" -> "Following up on" (natural phrasing)
- "recent communication" -> "last conversation" (specific)
- "aforementioned matter" -> removed (adds nothing)
- "ascertain whether you have obtained" -> "do you have" (direct question)
- "requisite documentation" -> "documents we need" (plain)
</reasoning>
</example>

### 2. Write Short Sentences

Target 15-20 words per sentence on average. Never exceed 30 words in a single sentence. When a sentence crosses 20 words, find the natural split point -- usually at a conjunction, comma before a new clause, or shift in topic.

**Splitting technique:** Look for "and", "but", "which", "because", "while", or any comma followed by a new subject. Break there. Make each resulting sentence carry one idea.

<example>
<input>To improve customer satisfaction scores, which have declined 12% over the past quarter due to longer wait times and inconsistent service quality, we will implement a new training program for all customer service representatives that focuses on both technical knowledge and communication skills.</input>
<output>Customer satisfaction scores dropped 12% last quarter. Wait times increased and service quality became inconsistent. To fix this, we will launch a new training program for all service representatives. The program covers technical knowledge and communication skills.</output>
<reasoning>
Original: 1 sentence, 47 words. Rewrite: 4 sentences averaging 11 words each. Each sentence carries one idea. The reader never needs to hold multiple concepts in memory simultaneously.
</reasoning>
</example>

**Paragraph length:** 3-5 sentences maximum. One main idea per paragraph. If a paragraph exceeds 5 sentences, split it at the point where the topic shifts.

### 3. Use Active Voice

Active voice follows the pattern: Subject (who) -> Verb (does what) -> Object (to what/whom). This structure makes responsibility and action immediately clear.

**Conversion pattern:**

```
Passive: [Object] was [verb]ed by [subject].
Active:  [Subject] [verb]ed [object].
```

<example>
<input>The decision was made by the executive committee to postpone the product launch, and all stakeholders will be notified by the communications team by end of day.</input>
<output>The executive committee decided to postpone the product launch. The communications team will notify all stakeholders by end of day.</output>
<reasoning>
- "The decision was made by the executive committee" -> "The executive committee decided" (actor first, action second)
- "all stakeholders will be notified by the communications team" -> "The communications team will notify all stakeholders" (same pattern)
- Split into two sentences because there are two actors performing two actions.
</reasoning>
</example>

**When passive voice is acceptable** (these are the only three cases):

1. The actor is genuinely unknown: "The server was compromised overnight."
2. The actor is irrelevant and naming them would distract: "The building was constructed in 1924."
3. The audience cares more about the receiver: "Your application has been approved." (reader cares about their application, not who approved it)

If none of these three conditions apply, use active voice.

### 4. Address the Reader Directly

Use "you" and "your" for the reader. Use "we" and "our" for the organization. Never refer to the reader in the third person.

<example>
<input>Employees are required to submit their timesheets by 5 PM on Friday. Failure to comply will result in delayed payroll processing for the affected individuals.</input>
<output>Submit your timesheet by 5 PM on Friday. If you miss this deadline, your pay may be delayed.</output>
<reasoning>
- "Employees are required to submit" -> "Submit" (direct command to "you")
- "their timesheets" -> "your timesheet" (second person)
- "Failure to comply will result in delayed payroll processing for the affected individuals" -> "If you miss this deadline, your pay may be delayed" (consequence stated in terms the reader cares about)
</reasoning>
</example>

### 5. Use Strong Verbs Instead of Nominalizations

Nominalizations are verbs that have been converted into nouns (usually ending in -tion, -ment, -ance, -ence). They make writing abstract and wordy. Convert them back to verbs.

**Detection pattern:** Look for "make a", "conduct a", "perform a", "give", "provide", "reach a" followed by a noun. These almost always hide a stronger verb.

| Nominalization | Strong verb |
|---|---|
| make a decision | decide |
| conduct an investigation | investigate |
| provide assistance | help |
| give consideration to | consider |
| reach a conclusion | conclude |
| make an improvement | improve |
| perform an analysis | analyze |
| take into account | consider |
| make a recommendation | recommend |
| have a discussion | discuss |

<example>
<input>The committee will give consideration to your proposal and make a determination regarding the allocation of resources prior to the commencement of the next fiscal quarter.</input>
<output>The committee will consider your proposal and decide how to allocate resources before next quarter starts.</output>
<reasoning>
- "give consideration to" -> "consider"
- "make a determination regarding" -> "decide"
- "allocation of resources" -> "allocate resources" (verb form)
- "prior to the commencement of" -> "before ... starts"
- Result: 17 words vs. 27 words. Same meaning, no information lost.
</reasoning>
</example>

### 6. Remove Redundancies and Filler

Two categories to eliminate:

**Redundant modifiers** (the modifier restates what the noun already means):

| Redundant phrase | Replacement |
|---|---|
| advance planning | planning |
| end result | result |
| final outcome | outcome |
| past experience | experience |
| completely eliminate | eliminate |
| close proximity | near |
| basic fundamentals | basics, fundamentals |
| future plans | plans |
| brief summary | summary |
| consensus of opinion | consensus |

**Wordy phrases** (multi-word phrases replaceable by one or two words):

| Wordy | Concise |
|---|---|
| at this point in time | now |
| due to the fact that | because |
| in order to | to |
| with regard to | about |
| in the event that | if |
| for the purpose of | to, for |
| a number of | some, several |
| in the near future | soon |
| on a daily basis | daily |
| is able to | can |
| has the ability to | can |
| in spite of the fact that | although, despite |
| it is important to note that | (delete entirely -- just state the point) |
| it should be noted that | (delete entirely) |

### 7. Put the Main Point First

Use the inverted pyramid: conclusion first, then supporting details, then background. The reader should get the essential message from the first sentence of any section or paragraph.

<example>
<input>After extensive analysis of market trends, competitive positioning, customer feedback gathered through multiple channels over the past six months, and internal capability assessments, we have concluded that expanding into the European market represents our strongest growth opportunity for the coming fiscal year.</input>
<output>We should expand into the European market next year -- it is our strongest growth opportunity. This conclusion is based on six months of market analysis, competitive research, customer feedback, and internal capability reviews.</output>
<reasoning>
The original buries the conclusion ("expand into the European market") after 30 words of setup. The rewrite leads with the recommendation so a reader scanning the document gets the point immediately. Supporting details follow for those who want them.
</reasoning>
</example>

**For headers:** Use descriptive headers that communicate the content, not generic labels.

| Generic header | Descriptive header |
|---|---|
| Background | Why customer churn increased 40% |
| Discussion | Three options to reduce costs |
| Analysis | The new pricing model saves $2M annually |
| Recommendations | Switch to vendor B by March 15 |

### 8. Define Technical Terms When Required

When a technical term, acronym, or domain-specific word is necessary, define it on first use. After the first definition, use the term freely.

**Three patterns for defining terms, in order of preference:**

1. **Parenthetical definition** (best for terms the reader will see again):
   "We track NPS (Net Promoter Score), which measures how likely customers are to recommend us."

2. **Inline plain-language equivalent** (best for one-time technical references):
   "The API -- the connection point between our system and theirs -- went down at 3 AM."

3. **Glossary** (only for documents with 10+ technical terms):
   Add a glossary section. Still define the most critical 3-5 terms inline on first use.

<example>
<input>We need to improve our CSAT and NPS scores. The current SLA doesn't meet our KPIs for CX.</input>
<output>We need to improve two key customer metrics: customer satisfaction (CSAT) and Net Promoter Score (NPS). Our current service agreement doesn't meet our targets for customer experience.</output>
<reasoning>
- "CSAT" and "NPS" are defined inline because the reader will encounter them again.
- "SLA" is replaced entirely with "service agreement" because it only appears once.
- "KPIs" is replaced with "targets" (plain equivalent).
- "CX" is replaced with "customer experience" (spelled out).
</reasoning>
</example>

## Quality Targets

When you finish writing or editing a document, verify it meets these thresholds:

| Metric | Target | How to check |
|---|---|---|
| Reading level | 8th-10th grade (Flesch-Kincaid) | Count average syllables per word and words per sentence |
| Average sentence length | 15-20 words | Total words / total sentences |
| Maximum sentence length | 30 words | Flag and split any sentence exceeding this |
| Paragraph length | 3-5 sentences | One idea per paragraph |
| Active voice ratio | 80%+ | Count passive constructions, divide by total sentences |
| Direct address | "You"/"we" present | Scan for third-person references to the reader |
| Jargon | All terms defined or replaced | Search for acronyms and domain-specific vocabulary |
| First-reading comprehension | Pass | A person unfamiliar with the topic understands the main point without re-reading |

## Full Before/After: Business Letter

This example shows all eight principles applied together.

<example>
<input>
Dear Valued Customer,

Pursuant to our recent communication, we regret to inform you that we are unable to acquiesce to your request for a refund. This determination was reached due to the fact that the product in question was utilized beyond the applicable warranty period, which, as stipulated in our terms and conditions documentation, constitutes a disqualifying factor for the purposes of reimbursement consideration.

Should you wish to pursue an alternative resolution, we would encourage you to reach out to our customer service department at your earliest convenience so that a representative can provide assistance with regard to exploring other available options.
</input>
<output>
Dear [Customer Name],

We cannot refund your purchase because the warranty has expired. Our terms require that refund requests fall within the warranty period.

You have other options. Call our customer service team at [phone] and they will help you find a solution.
</output>
<reasoning>
Principles applied:
1. Common words: "acquiesce" -> removed, "utilized" -> removed (sentence restructured), "stipulated" -> removed
2. Short sentences: From 2 sentences averaging 45 words to 4 sentences averaging 13 words
3. Active voice: "This determination was reached" -> "We cannot refund" / "a representative can provide assistance" -> "they will help you"
4. Direct address: "the product in question" -> "your purchase", added "You have other options"
5. Strong verbs: "provide assistance with regard to exploring" -> "help you find"
6. No redundancy: "for the purposes of reimbursement consideration" -> "refund requests"
7. Main point first: The refusal and reason are in the first sentence, not buried
8. No jargon: All legal/formal phrasing replaced with plain equivalents
</reasoning>
</example>

## Edge Cases and Judgment Calls

**When the audience is technical:** You can use domain terms without defining them if the document is exclusively for specialists (e.g., an API changelog for developers). Still apply all other principles -- short sentences, active voice, main point first.

**When formality is required:** Legal contracts, regulatory filings, and formal correspondence may require specific phrasing. In those cases, prioritize principles 2, 3, and 7 (short sentences, active voice, main point first) while accepting that principle 1 (common words) may need to yield to precision.

**When the original author's voice matters:** For ghostwriting or executive communications, preserve the author's characteristic phrases and tone. Apply plain language principles to structure and flow rather than replacing every word.

**When translating from another language:** Plain language becomes even more important. Non-native English speakers benefit most from short sentences, common words, and direct structure. Avoid idioms, phrasal verbs with non-obvious meanings ("get around to"), and culturally specific references.
