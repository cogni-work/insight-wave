---
title: Email Template
type: template
category: deliverable-template
deliverable: email
tags: [template, email, business-communication]
instructions: Use this template as a structural guide when generating emails. Follow the chain-of-thought planning section first, then produce output matching the output skeleton. Do not include planning notes in the final deliverable.
version: 2.0
last_updated: 2026-02-25
---

# Email Template

## How to Use This Template

This template has two parts:

1. **Planning (think step by step)** -- Work through these decisions internally before writing. Do not include planning output in the final email.
2. **Output Skeleton** -- The structural blueprint for the finished email. Replace all `{{PLACEHOLDER}}` tokens with final content.

---

## Part 1: Planning (Chain of Thought)

Before drafting, resolve each decision below in order. These decisions shape every structural choice in the output.

### 1A. Classify the Email Type

Determine which type best matches the user's intent. This selection controls tone, structure, and closing pattern.

| Type | Signal Words / Context | Default Framework | Typical Length |
|------|----------------------|-------------------|----------------|
| Action Request | "approve", "decide", "sign off", deadline present | BLUF | 150-250 words |
| Status Update | "update", "progress", "FYI", no decision needed | Inverted Pyramid | 150-200 words |
| Meeting Request | "schedule", "meet", "discuss", agenda items | BLUF | 100-150 words |
| Information Share | "announcing", "sharing", "letting you know" | Inverted Pyramid | 150-250 words |
| Problem Escalation | "issue", "blocked", "risk", needs resolution | SCQA | 200-300 words |
| Persuasion / Pitch | "proposal", "recommend", "consider", building a case | SCQA | 200-300 words |

If the user specifies a framework explicitly, use that instead of the default.

### 1B. Determine Tone and Formality

Assess from context clues. When uncertain, default to "professional-warm."

| Register | When to Use | Greeting Style | Closing Style |
|----------|-------------|----------------|---------------|
| Formal | External senior stakeholders, first contact, legal/regulatory | "Dear {{NAME}}," | "Respectfully," / "Kind regards," |
| Professional-warm | Internal colleagues, established external relationships | "Hi {{NAME}}," | "Best," / "Thanks," |
| Direct-casual | Close teammates, fast-paced internal threads | "{{NAME}}," or "Hey {{NAME}}," | "Thanks," / "Cheers," |

### 1C. Identify Core Components

Extract these from the user's request or source material. If any are missing and cannot be inferred, ask the user before drafting.

- **Purpose**: One sentence stating why this email exists.
- **Primary recipient role**: Who reads this and what do they care about?
- **Bottom line**: The single most important thing the reader must know.
- **Action required**: Exactly what the reader should do (or "None -- FYI only").
- **Deadline**: When the action must happen (or "N/A").
- **Supporting points**: 2-4 facts, metrics, or reasons that justify the bottom line.
- **Constraints**: Word count limits, confidentiality, tone mandates from the user.

### 1D. Select Structure Pattern

Based on the framework chosen in 1A, select the matching body structure.

**BLUF pattern** (action requests, approvals, status updates):
```
Bottom line (1-2 sentences) -> Context (2-4 sentences) -> Details (bullets or short paragraph) -> Call to action (1 sentence)
```

**SCQA pattern** (persuasion, escalation, complex situations):
```
Situation (1-2 sentences) -> Complication (1-2 sentences) -> Question (1 sentence, can be implicit) -> Answer/Recommendation (2-4 sentences with supporting details)
```

**Inverted Pyramid pattern** (updates, announcements, information sharing):
```
Most critical information (1-2 sentences) -> Important details (2-4 sentences) -> Background/nice-to-know (1-2 sentences, optional)
```

### 1E. Plan the Subject Line

Apply these rules in order:

1. Lead with the action verb or status keyword (mobile screens show first 30-40 characters).
2. Include the key detail that differentiates this email from others.
3. Add deadline or urgency marker only if genuinely time-sensitive.
4. Target 6-10 words. Never exceed 50 characters.

Formula: `[Action/Status] + [Specific Topic] + [Deadline if applicable]`

---

## Part 2: Output Skeleton

Generate the final email by filling every `{{PLACEHOLDER}}` below. Remove all template annotations and comments. The output must be clean markdown ready for delivery.

```markdown
**Subject:** {{SUBJECT_LINE}}

{{GREETING}},

{{OPENING_PARAGRAPH}}
<!-- 1-2 sentences. State the bottom line or main point immediately.
     For BLUF: What you need + why it matters.
     For SCQA: The situation the reader already knows.
     For Inverted Pyramid: The most critical news.
     This paragraph must make complete sense if the reader stops here. -->

{{CONTEXT_PARAGRAPH}}
<!-- 2-4 sentences. Provide only the background the reader needs to
     understand or act on the opening.
     For BLUF: Brief rationale and essential context.
     For SCQA: The complication and implicit/explicit question.
     For Inverted Pyramid: Important supporting details.
     Omit this paragraph entirely if the opening is self-contained. -->

{{DETAILS_SECTION}}
<!-- Choose ONE format based on content type:

     FORMAT A -- Bullet list (use when presenting 3+ discrete items):
     - {{KEY_POINT_1}}
     - {{KEY_POINT_2}}
     - {{KEY_POINT_3}}

     FORMAT B -- Short paragraph (use for narrative explanation):
     {{2-4 sentences of supporting information.}}

     FORMAT C -- Mini table (use for comparisons or metrics):
     | {{Column 1}} | {{Column 2}} |
     |---|---|
     | {{Data}} | {{Data}} |

     Omit this section entirely for very short emails (meeting requests,
     simple FYIs under 100 words). -->

{{CALL_TO_ACTION}}
<!-- Exactly one sentence. Make the desired response frictionless.
     Good: "Reply 'approved' and I'll execute by Friday."
     Good: "No action needed -- sharing for awareness."
     Bad: "Let me know your thoughts when you get a chance." -->

{{SIGN_OFF}},
{{SENDER_NAME}}
```

---

## Validation Checklist

After drafting, verify every item. Fix any failures before delivering.

### Structure

- [ ] Subject line is 6-10 words, under 50 characters, starts with action verb or status keyword
- [ ] Main point appears in the first 1-2 sentences (not buried)
- [ ] Framework pattern (BLUF/SCQA/Inverted Pyramid) is correctly applied
- [ ] Email has exactly one topic (split into multiple emails if not)
- [ ] Call to action is explicit and includes deadline when applicable

### Readability

- [ ] Total length is 150-300 words (flag if outside range; escalate to memo if over 400)
- [ ] Paragraphs are 2-4 sentences each (never more than 5)
- [ ] Sentences average 12-18 words (shorter than memos)
- [ ] Active voice in 80%+ of sentences
- [ ] No filler phrases ("I hope this finds you well", "I wanted to reach out", "as per our discussion")

### Mobile Optimization

- [ ] First 2 lines make complete sense read in isolation (mobile preview test)
- [ ] No wide tables (3 columns maximum; prefer bullets over tables)
- [ ] Key information does not require scrolling to reach
- [ ] Bullet lists used instead of dense prose for 3+ items

### Tone

- [ ] Greeting and sign-off match the formality register from 1B
- [ ] Tone is consistent throughout (no abrupt shifts between formal and casual)
- [ ] Urgency language ("Urgent:", "ASAP") used only when genuinely time-sensitive

### Constraints (from SKILL.md)

- [ ] German characters preserved exactly (ae/oe/ue/ss never substituted for a/o/u/ss)
- [ ] All citation markers and URLs preserved unchanged
- [ ] Protected content (diagram placeholders, figure references) untouched

---

## Email Type Quick-Reference Patterns

Use these as structural starting points. Adapt based on planning decisions above.

### Action Request

```
Subject: [Verb] [Topic] by [Date]
Greeting,
I need [specific action] by [deadline] to [reason/consequence].
[2-3 sentences of essential context.]
Key details:
- [Detail 1]
- [Detail 2]
- [Detail 3]
Reply [specific easy response] and I'll [next step].
Sign-off,
Name
```

### Status Update

```
Subject: [Project/Topic] [Metric] -- [Action status]
Greeting,
[Project] is [status vs. target]. [No action required / Action needed].
Key metrics:
- [Metric 1]: [value] (target: [value])
- [Metric 2]: [value] (target: [value])
[1-2 sentences on what is driving the result and what comes next.]
Sign-off,
Name
```

### Problem Escalation (SCQA)

```
Subject: [Issue] -- [Action/Decision] Needed by [Date]
Greeting,
[Situation]: [1-2 sentences of shared context the reader already knows.]
[Complication]: [What changed or what is at risk. Include quantified impact.]
[Recommendation]: [Your proposed solution in 1-2 sentences.]
Next steps:
- [Step 1 with owner and date]
- [Step 2 with owner and date]
Can we [specific ask] by [date]?
Sign-off,
Name
```

### Meeting Request

```
Subject: [Meeting Purpose] -- [Proposed Date/Time]
Greeting,
I'd like to schedule [duration] to [specific purpose].
Proposed: [Day], [Date], [Time]-[Time] [Timezone].
Agenda:
- [Item 1]
- [Item 2]
[Prep needed / No prep needed]. Calendar invite [attached / to follow].
Sign-off,
Name
```

---

## Common Failure Modes

When reviewing a draft, watch for these patterns and correct them.

| Failure | What It Looks Like | Fix |
|---------|-------------------|-----|
| Buried lead | Main request appears after paragraph 2 | Move to first sentence |
| Vague subject | "Update" / "Question" / "Following up" | Rewrite with action verb + specific topic |
| Missing deadline | "When you get a chance" / "At your convenience" | Add concrete date or remove if truly open-ended |
| Multi-topic email | Budget approval AND meeting request AND status update | Split into separate emails, one topic each |
| Wall of text | Single paragraph over 5 sentences, no visual breaks | Break into short paragraphs + bullet list |
| Passive call to action | "It would be great if someone could look into this" | Rewrite as direct request to specific person |
| Over-length | 400+ words with inline explanations | Extract details to attachment or linked document |
| Filler opening | "I hope this email finds you well. I wanted to reach out to..." | Delete entirely; start with the point |
