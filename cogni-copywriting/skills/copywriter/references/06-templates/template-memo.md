---
title: Memo Template
type: template
category: deliverable-template
deliverable: memo
tags: [template, memo, internal-communication]
instructions: This is an LLM instruction reference. Use this template to generate memo documents by following the section-by-section generation guide below.
version: 2.0
last_updated: 2026-02-25
---

# Memo Template

## How to Use This Template

This template defines the structure and generation logic for professional memos. When generating a memo, work through the sections sequentially from Header Block through Closing. Each section contains:

- **Purpose:** Why this section exists and what it accomplishes for the reader.
- **Generation instructions:** Specific rules for producing the content.
- **Constraints:** Hard limits on length, style, or format.

Think step by step: First determine the memo's primary purpose and audience. Then select the appropriate framework (BLUF, Pyramid, or SCQA). Finally, generate each section in order, checking constraints as you go.

---

## Framework Selection (Decide First)

Before generating any content, determine which framework fits the memo's purpose:

| If the memo needs to... | Use | Opening pattern |
|---|---|---|
| Communicate a decision or directive | **BLUF** | State the bottom line in sentence one |
| Build a structured case with evidence | **Pyramid** | State the answer, then layer supporting arguments |
| Persuade by establishing urgency | **SCQA** | Situation, Complication, Question, then Answer |

Default to **BLUF** when uncertain. Most memos are action-oriented and benefit from leading with the conclusion.

---

## Output Structure

Generate the memo in this exact order. Do not rearrange sections. Do not add sections beyond what is specified here.

### 1. Header Block

**Purpose:** Establish routing, authorship, date, and topic at a glance.

```
TO: [Recipient name, title, and/or department]
FROM: [Author name and title]
DATE: [Month DD, YYYY format -- use the current date unless the user specifies otherwise]
SUBJECT: [Subject line]
```

**Subject line rules:**
- Lead with the most important noun or action verb.
- Be specific enough that the reader knows the topic without opening the memo. "Q4 Campaign Launch Delayed to November 15" is correct. "Update" is not.
- Keep under 60 characters.
- If the memo requests action, signal it: "Action Required: ..." or "Decision Needed: ..."

---

### 2. Opening Paragraph

**Purpose:** Deliver the main message so a reader who stops here still gets the essential information.

**Generation instructions:**
1. Write the single most important statement first. This is the bottom line: the decision, the announcement, the request, or the recommendation.
2. In the same paragraph, answer as many of these as are relevant: What is happening? When does it take effect? Why does it matter? What action is needed?
3. Do not provide background or justification yet. That comes in the next section.

**Constraints:**
- 2-4 sentences maximum.
- Use active voice. Write "We are delaying the launch" not "The launch has been delayed."
- If using SCQA framework, this section contains the Situation and Complication instead. The Question and Answer then open the body.

---

### 3. Context Section

**Purpose:** Give the reader just enough background to understand why the opening statement matters.

**Generation instructions:**
1. Answer: What led to this? Why now? What is the relevant history?
2. Include only information the reader needs to evaluate or act on the main message. Cut everything else.
3. If using SCQA, this is where the Question and Answer land.

**Constraints:**
- 1-2 short paragraphs (3-5 sentences total).
- Do not repeat information from the opening paragraph.
- Use concrete language: "Orders grew 40% this year" not "There has been significant growth."
- Define acronyms on first use if the audience is cross-functional.

---

### 4. Details Section

**Purpose:** Provide the supporting facts, data, implications, or options that substantiate the main message.

**Generation instructions:**
1. Choose the format that best serves the content:
   - **Bullet list:** When presenting 3-7 discrete points (impacts, changes, options).
   - **Short paragraphs:** When points require 2-3 sentences of explanation each.
   - **Table:** When comparing options, metrics, or before/after states.
2. Each item should carry its own weight. If a bullet point does not add information the reader needs, remove it.
3. Bold key terms, numbers, and names that the reader's eye should catch while scanning.

**Constraints:**
- 3-7 items if using bullets. Fewer than 3 suggests this section can merge into Context. More than 7 suggests the document should be a brief instead.
- If using paragraphs, limit to 2-3 paragraphs of 3-5 sentences each.
- Total details section should not exceed roughly 40% of the memo's word count.

---

### 5. Next Steps / Action Items

**Purpose:** Make it unambiguous what happens after the reader finishes the memo.

**Generation instructions:**
1. List each action item as a bullet with three components: **what** needs to happen, **who** owns it, and **when** it is due.
2. Order items chronologically or by priority.
3. If there is a single decision required rather than multiple action items, state it as a direct request with a deadline: "Please approve the lease by November 1."

**Format:**
```
- [Action]: [Owner] by [Date]
```

**Constraints:**
- 2-5 action items. If more are needed, the document may need to be a project plan instead.
- Every item must have an owner and a deadline. Items without both are incomplete.
- Use imperative or direct language: "Submit the report" not "The report should be submitted."

---

### 6. Closing Line

**Purpose:** End with a single courteous sentence that opens a channel for follow-up.

**Generation instructions:**
1. Choose one of these patterns based on the memo's tone:
   - Inviting questions: "Contact me with any questions."
   - Confirming next engagement: "I look forward to discussing this at the November 10 meeting."
   - Expressing appreciation: "Thank you for your attention to this."
2. Do not introduce new information in the closing.

**Constraints:**
- Exactly 1 sentence.
- Do not use both a question-invitation and an appreciation statement. Pick one.

---

## Quality Standards

After generating the complete memo, verify against these criteria before outputting:

### Hard Requirements (must all pass)

- [ ] Header block is complete with all four fields (TO, FROM, DATE, SUBJECT).
- [ ] Main message appears in the first paragraph, not buried later.
- [ ] Every action item has an owner and a deadline.
- [ ] Active voice used in 80%+ of sentences.
- [ ] Total length is 300-500 words (approximately 1 page).

### Style Targets

- [ ] Paragraphs are 3-5 sentences. No paragraph exceeds 5 sentences.
- [ ] Sentences average 15-20 words. No sentence exceeds 25 words.
- [ ] Tone is professional but direct -- uses "we" and "you," avoids third-person passive constructions.
- [ ] No jargon or acronyms appear without definition (unless audience is explicitly single-department).
- [ ] Key terms and numbers are bolded for scannability.
- [ ] Flesch readability score target: 50-60.

### Common Failures to Watch For

When reviewing your output, check specifically for these patterns and fix them before returning the memo:

| Failure | How to detect | How to fix |
|---|---|---|
| Buried lead | The first sentence is background, not the main point | Move the main message to sentence one; push background to Context section |
| Passive voice overuse | Sentences use "was decided," "has been approved," "will be launched" | Rewrite with the actor as subject: "We decided," "The board approved," "We launch" |
| Missing deadlines | Action items say "soon," "ASAP," or have no date | Replace with a specific date. If the user did not provide one, flag it explicitly |
| Excessive length | Word count exceeds 500 | Cut the Details section first. Convert prose to bullets. Remove any background the audience already knows |
| Vague subject line | Subject line is generic ("Update," "FYI," "Important") | Rewrite to include the specific topic and action if applicable |

---

## Length Escalation Rule

If the content genuinely cannot fit in 300-500 words after applying compression techniques (bullets instead of prose, cutting known context, using tables), recommend to the user that the document be reformatted as a **brief** (700-1500 words) or **report** (1500+ words) instead. Do not stretch a memo beyond 600 words.
