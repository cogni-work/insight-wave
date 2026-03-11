---
title: Copywriting Skills Master Index
type: index
version: 8.0
last_updated: 2026-02-25
---

# Reference Loading Index

<purpose>
You are the copywriter skill's reference router. This file tells you exactly which reference files to load for any given task. You will read this file at the start of every copywriting task. Your job: parse the user's request, then load ONLY the references needed. Never load everything. Never guess -- follow the decision tree below.
</purpose>

## Step 1: Detect Operating Mode

Before loading any deliverable or framework references, check for these special modes. They override normal loading.

<mode_detection>
Think through these checks in order. Stop at the FIRST match.

CHECK 1 -- ARC PRESERVATION MODE
Trigger conditions (any one is sufficient):
- Document YAML frontmatter contains `arc_id`
- User says "polish this arc" or "arc preservation" or similar
- Document H2 headings match a known arc pattern (corporate-visions, technology-futures, competitive-intelligence, strategic-foresight, industry-transformation)

If triggered, set `mode = arc` and go to the Arc Loading Block below.

CHECK 2 -- SALES MODE
Trigger conditions:
- User specifies `MODE: sales`
- Content contains Power Position markers (`**IS**:`, `**DOES**:`, `**MEANS**:`)

If triggered, set `mode = sales` and go to the Sales Loading Block below.

CHECK 3 -- STANDARD MODE (default)
No special mode detected. Set `mode = standard` and go to the Standard Loading Block below.
</mode_detection>

---

## Step 2: Load References by Mode

### Arc Loading Block

When `mode = arc`, the arc IS the document structure. Do NOT load messaging frameworks or deliverable types.

```
LOAD: 09-preservation-modes/arc-preservation.md
LOAD: 09-preservation-modes/arc-technique-map.md
LOAD: 01-core-principles/clarity-principles.md
LOAD: 01-core-principles/conciseness-principles.md
LOAD: 01-core-principles/active-voice-principles.md
LOAD: 07-impact-techniques/number-plays.md
LOAD: 07-impact-techniques/power-words.md

IF document language is German:
  LOAD: 01-core-principles/german-style-principles.md
  LOAD: 01-core-principles/german-hook-principles.md
```

After loading, SKIP Steps 3-4 below. Proceed directly to skill workflow Step 3 (structure comes from the arc, not from a framework).

---

### Sales Loading Block

When `mode = sales`, load Power Positions plus supporting impact techniques. Sales mode still uses a deliverable type and framework, so continue to Standard Loading Block after loading these.

```
LOAD: 08-sales-techniques/power-positions.md
LOAD: 07-impact-techniques/number-plays.md
LOAD: 07-impact-techniques/power-words.md
```

Then continue to the Standard Loading Block for deliverable + framework selection.

---

### Standard Loading Block

This is the normal path for all non-arc tasks (including sales mode, which adds to this).

#### 2a. Core Principles (always load these three)

```
LOAD: 01-core-principles/clarity-principles.md
LOAD: 01-core-principles/conciseness-principles.md
LOAD: 01-core-principles/active-voice-principles.md
```

#### 2b. Language-Conditional Principles

```
IF document language is German:
  LOAD: 01-core-principles/german-style-principles.md
  LOAD: 01-core-principles/german-hook-principles.md
```

#### 2c. Optional Core Principles (load only when relevant)

```
IF content is technical and needs accessibility:
  LOAD: 01-core-principles/plain-language-principles.md

IF visual hierarchy and scannability are priorities:
  LOAD: 01-core-principles/readability-principles.md
```

---

## Step 3: Select and Load Deliverable Type

Identify which deliverable the user wants. This is REQUIRED for standard mode.

<deliverable_selection>
Map the user's request to exactly one deliverable type. Use this lookup table:

| User says                                      | deliverable_type     | File to load                              |
|------------------------------------------------|----------------------|-------------------------------------------|
| memo, memorandum, internal communication       | memo                 | 04-deliverable-types/memos.md             |
| email, message, correspondence                 | email                | 04-deliverable-types/emails.md            |
| brief, briefing, briefing document             | brief                | 04-deliverable-types/briefs.md            |
| report, analysis, findings                     | report               | 04-deliverable-types/reports.md           |
| proposal, pitch, business case                 | proposal             | 04-deliverable-types/proposals.md         |
| one-pager, one pager, summary sheet            | one-pager            | 04-deliverable-types/one-pagers.md        |
| executive summary, exec summary                | executive-summary    | 04-deliverable-types/executive-summaries.md |
| letter, business letter, formal letter         | business-letter      | 04-deliverable-types/business-letters.md  |
| blog, blog post, article, thought leadership   | blog                 | 04-deliverable-types/blogs.md             |

If the user's request does not clearly map to one of these, ask them to clarify before proceeding.
</deliverable_selection>

```
LOAD: 04-deliverable-types/{deliverable_type}.md
```

---

## Step 4: Select and Load Messaging Framework

<framework_selection>
Apply this logic in order:

1. If the user explicitly names a framework, load that framework.
2. If the user does not name a framework, read the `recommended-frameworks` field from the deliverable file you loaded in Step 3. Use the FIRST listed framework as the default.
3. If multiple frameworks seem equally suitable and the user has not chosen, pick the first recommended one -- do not ask unless genuinely ambiguous.

Available frameworks:

| Framework         | File                                                | Best for                                              |
|-------------------|-----------------------------------------------------|-------------------------------------------------------|
| BLUF              | 02-messaging-frameworks/bluf-framework.md           | Action-required, time-sensitive, executive audience    |
| Pyramid           | 02-messaging-frameworks/pyramid-framework.md        | Complex recommendations, structured analysis           |
| SCQA              | 02-messaging-frameworks/scqa-framework.md           | Narrative flow, problem-solving, building urgency      |
| Inverted Pyramid  | 02-messaging-frameworks/inverted-pyramid-framework.md | Web content, press releases, scannable documents     |
| STAR              | 02-messaging-frameworks/star-framework.md           | Case studies, examples, behavioral contexts            |
| PSB               | 02-messaging-frameworks/psb-framework.md            | Marketing, sales, customer-facing content              |
| FAB               | 02-messaging-frameworks/fab-framework.md            | Product focus, feature-heavy content                   |
</framework_selection>

```
LOAD: 02-messaging-frameworks/{framework}-framework.md
```

---

## Step 5: Load Conditional References

These references load only when specific conditions are met. Check each independently.

### Impact Techniques

```
IF impact_level = high OR audience is executive/C-suite OR deliverable is executive-summary:
  LOAD: 07-impact-techniques/number-plays.md
  LOAD: 07-impact-techniques/power-words.md
  LOAD: 07-impact-techniques/rhetorical-devices.md
  LOAD: 07-impact-techniques/executive-impact.md
```

### Formatting Standards

```
IF deliverable needs visual elements (one-pager, report, blog, proposal):
  LOAD: 03-formatting-standards/visual-elements.md

IF document has multi-section structure:
  LOAD: 03-formatting-standards/heading-hierarchy.md

IF document contains inline citations:
  LOAD: 03-formatting-standards/citation-formatting.md

IF user asks about markdown syntax:
  LOAD: 03-formatting-standards/markdown-basics.md
```

### Stakeholder Review

```
IF review_mode = reader:
  Delegate to cogni-copywriting:reader skill (handles its own reference loading)

IF review_mode = automated OR review not explicitly skipped:
  LOAD: 10-stakeholder-review/{perspective}-review.md (for each selected stakeholder)
  LOAD: 10-stakeholder-review/synthesis-guidelines.md (after reviews complete)
```

Stakeholder defaults by audience:

| Audience          | Default stakeholders              |
|-------------------|-----------------------------------|
| executive         | executive, technical, end-user    |
| technical         | technical, executive              |
| general           | end-user, marketing, executive    |
| legal             | legal, executive, technical       |
| sales / marketing | marketing, executive, end-user    |

### Examples and Templates

```
IF user requests an example OR this is a new framework combination:
  LOAD: 05-examples/example-{deliverable}-{framework}.md

IF user requests a template OR wants a fillable structure:
  LOAD: 06-templates/template-{deliverable}.md
```

### Workflow Guide

```
IF task is complex (multi-step, dependencies, first-time user):
  LOAD: workflow/step-by-step-guide.md
```

---

## Quick Lookup: Deliverable to Default Load Set

Use this table to confirm you have the right references for common tasks. Each row shows the minimum set of files to load.

| Deliverable        | Default Framework | Core Principles | Conditional Loads                         |
|--------------------|-------------------|-----------------|-------------------------------------------|
| memo               | BLUF              | clarity, conciseness, active-voice | --                             |
| email              | BLUF              | clarity, conciseness, active-voice | --                             |
| brief              | BLUF              | clarity, conciseness, active-voice | --                             |
| report             | Pyramid           | clarity, conciseness, active-voice | visual-elements, heading-hierarchy |
| proposal           | FAB               | clarity, conciseness, active-voice | visual-elements, heading-hierarchy |
| one-pager          | PSB               | clarity, conciseness, active-voice | visual-elements                |
| executive-summary  | BLUF              | clarity, conciseness, active-voice | executive-impact               |
| business-letter    | (Direct/Indirect) | clarity, conciseness, active-voice | --                             |
| blog               | Inverted Pyramid  | clarity, readability, active-voice | visual-elements                |

---

## File Inventory

All reference files in this system, organized by directory. Use this as the source of truth for valid file paths.

### 01-core-principles/
- `clarity-principles.md` -- 15-20 word sentences, concrete language, simple words
- `conciseness-principles.md` -- 3-5 sentence paragraphs, eliminate filler, strong verbs
- `active-voice-principles.md` -- 80%+ active voice, clear subjects, transformation patterns
- `german-style-principles.md` -- Wolf Schneider rules: 12-word clauses, Satzklammer, Mittelfeld, Floskeln
- `german-hook-principles.md` -- Wolf Schneider / Reiners / Nannen: 12 opening-sentence rules, Kuechenzuruf test, arc hook strategies
- `plain-language-principles.md` -- Technical content accessibility
- `readability-principles.md` -- Visual hierarchy and scannability

### 02-messaging-frameworks/
- `bluf-framework.md` -- Bottom Line Up Front
- `pyramid-framework.md` -- McKinsey Pyramid Principle (MECE)
- `scqa-framework.md` -- Situation-Complication-Question-Answer
- `inverted-pyramid-framework.md` -- Key info first, details second, background last
- `star-framework.md` -- Situation-Task-Action-Result
- `psb-framework.md` -- Problem-Solution-Benefit
- `fab-framework.md` -- Feature-Advantage-Benefit

### 03-formatting-standards/
- `visual-elements.md` -- Tables, callouts, lists, emphasis (~1 visual per 2 paragraphs)
- `heading-hierarchy.md` -- Max 3 levels, front-loaded keywords, parallel structure
- `citation-formatting.md` -- Citation placement, superscript commas, preservation rules
- `markdown-basics.md` -- Standard markdown syntax reference

### 04-deliverable-types/
- `memos.md` -- 1 page, medium formality, BLUF/Pyramid/SCQA
- `emails.md` -- 200-300 words, medium formality, BLUF/SCQA
- `briefs.md` -- 1-3 pages, medium-high formality, BLUF/Pyramid/SCQA
- `reports.md` -- Variable length, high formality, Pyramid/SCQA/Inverted Pyramid
- `proposals.md` -- Variable length, high formality, FAB/PSB/Pyramid
- `one-pagers.md` -- Exactly 1 page, medium formality, PSB/FAB
- `executive-summaries.md` -- 1-2 pages, high formality, BLUF/Pyramid
- `business-letters.md` -- 1 page, very high formality, Direct/Indirect
- `blogs.md` -- 800-1500 words, medium formality, Inverted Pyramid/SCQA

### 05-examples/
- `example-memo-bluf.md`
- `example-email-scqa.md`
- `example-brief-pyramid.md`
- `example-proposal-fab.md`

### 06-templates/
- `template-memo.md`
- `template-email.md`
- `template-brief.md`
- `template-proposal.md`

### 07-impact-techniques/
- `number-plays.md` -- Ratio framing, specific quantification, comparative anchoring, before/after
- `power-words.md` -- Emotional triggers by category (urgency, exclusivity, trust, achievement)
- `rhetorical-devices.md` -- Rule of Three, anaphora, antithesis, cadence
- `executive-impact.md` -- C-suite optimization, lead with ask, quantify everything

### 08-sales-techniques/
- `power-positions.md` -- IS-DOES-MEANS structure, enhancement by layer, Value Wedge

### 09-preservation-modes/
- `arc-preservation.md` -- Arc detection, structure preservation, forbidden vs allowed modifications
- `arc-technique-map.md` -- Per-arc per-element technique rules, Number Play variants, validation checklist

### 10-stakeholder-review/
- `00-index.md` -- Stakeholder review system overview
- `executive-review.md` -- Decision-readiness, clarity, ROI
- `technical-review.md` -- Accuracy, precision, logical consistency
- `legal-review.md` -- Risk language, regulatory alignment
- `marketing-review.md` -- Persuasiveness, audience resonance
- `end-user-review.md` -- Accessibility, plain language, actionability
- `synthesis-guidelines.md` -- Multi-stakeholder feedback aggregation and conflict resolution

### workflow/
- `step-by-step-guide.md` -- Complete sub-steps, gate checks, validation procedures

---

## Fallback Behavior

When the user's request is ambiguous or does not specify a deliverable type:

1. Load the three core principles (clarity, conciseness, active-voice). These are always safe to load.
2. Ask the user to specify their deliverable type. Present the nine options from the deliverable selection table above.
3. Do NOT guess a deliverable type. Do NOT load all deliverable references. Wait for clarification.

When a reference file does not exist at the expected path (e.g., an example for a deliverable-framework combination that has not been written yet):

1. Log a note that the reference was not found.
2. Continue without it. The reference system is designed so that no single file is a hard dependency -- the deliverable and framework files together contain enough information to produce quality output.
