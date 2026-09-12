---
title: Copywriting Skills Master Index
type: index
version: 8.5
last_updated: 2026-05-27
---

# Reference Loading Index

<purpose>
You are the copywriter skill's reference router. This file tells you exactly which reference files to load for any given task. You will read this file at the start of every copywriting task. Your job: parse the user's request, then load ONLY the references needed. Never load everything. Never guess -- follow the decision tree below.
</purpose>

## Contents

- [Step 1: Detect Operating Mode](#step-1-detect-operating-mode)
- [Step 2: Load References by Mode](#step-2-load-references-by-mode)
  - [Arc Loading Block](#arc-loading-block)
  - [Sales Loading Block](#sales-loading-block)
  - [Standard Loading Block](#standard-loading-block)
- [Step 3: Select Deliverable Type](#step-3-select-deliverable-type)
- [Step 4: Select Messaging Framework](#step-4-select-messaging-framework)
- [Step 5: Load Conditional References](#step-5-load-conditional-references)
  - [Impact Techniques](#impact-techniques)
  - [Formatting Standards](#formatting-standards)
  - [Stakeholder Review](#stakeholder-review)
  - [Examples and Templates](#examples-and-templates)
  - [Workflow Guide](#workflow-guide)
- [Quick Lookup: Deliverable to Default Load Set](#quick-lookup-deliverable-to-default-load-set)
- [File Inventory](#file-inventory)
  - [Core principles and translation](#core-principles-and-translation)
  - [Formatting standards](#formatting-standards)
  - [Sales techniques](#sales-techniques)
  - [Arc preservation](#arc-preservation)
  - [Workflow](#workflow)
  - [Outside this tree](#outside-this-tree)
- [Fallback Behavior](#fallback-behavior)


## Step 1: Detect Operating Mode

Before loading any deliverable or framework references, check for these special modes. They override normal loading.

<mode_detection>
Think through these checks in order. Stop at the FIRST match.

CHECK 0 -- TRANSLATION MODE (orthogonal to mode below)
If `TARGET_LANG` is set and resolves to a different value from the detected source language, **additionally** load the translation references on top of whatever mode CHECK 1/2/3 selects:

```
LOAD: translation-principles.md
LOAD: translation-{source_lang}-to-{TARGET_LANG}.md
```

Construct the direction filename deterministically from the resolved `source_lang` and `TARGET_LANG` (e.g. `en`→`fr` → `translation-en-to-fr.md`; `pl`→`de` → `translation-pl-to-de.md`). The Step 1 pre-checks (accept-set + pivot guard) guarantee a valid pair, so the file always exists. The 22 supported directions are the 7×7 validity matrix in `translation-principles.md` (any pair with EN or DE on one end; diagonal is a no-op; direct non-EN/DE pairs are rejected upstream).

When `TARGET_LANG` is set **and** the document has `arc_id` **and** the pair pivots on EN/DE (one end ∈ {en,de}) **and** `arc_id` is in scope (`corporate-visions`, `jtbd-portfolio`), CHECK 1 (Arc) **does** trigger: load **both** the translation references above **and** the Arc Loading Block references (`arc-preservation.md` plus the upstream narrative files it names). The arc contract's `## Headings` table supplies the canonical target-language headings the skill substitutes in Step 2.5; an arc whose contract has no column for `TARGET_LANG` is aborted upstream in SKILL.md Step 1 pre-check #3. Out-of-scope arcs (any language) and direct non-EN/DE-pivot arc pairs are aborted upstream in SKILL.md Step 1 pre-check #3, so they never reach mode detection. When `TARGET_LANG` is unset, the arc references load exactly as before.

After loading the translation references, continue with normal mode detection below.

CHECK 0.5 -- COMPRESS SCOPE (orthogonal to mode below)
If `--scope=compress` is set, **additionally** load the compression reference on top of whatever mode CHECK 1/2/3 selects:

```
LOAD: compression-principles.md
```

Compress is a scope override, not a mode: Step 2 (Structure) is skipped, Step 3 runs as a compression pass (word-count minimization, decorative formatting relaxed), and Step 5 adds the precision-preservation gate. Compress is incompatible with `arc_mode` (abort) and must not be fused with `TARGET_LANG` (reject — translate first, then compress). After loading the compression reference, continue with normal mode detection below.

CHECK 1 -- ARC PRESERVATION MODE
Trigger conditions (any one is sufficient):
- Document YAML frontmatter contains `arc_id`
- User says "polish this arc" or "arc preservation" or similar
- Document H2 headings match a registered arc's element headings — `arc-preservation.md` § "Arc Detection Reference", Step 2 is the authority for the registry read and the match threshold

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

When `mode = arc`, the arc IS the document structure. Do NOT apply a messaging framework or a deliverable-type convention.

```
LOAD: arc-preservation.md
LOAD: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/arc-{arc_id}.md
LOAD: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
LOAD: clarity-principles.md
LOAD: conciseness-principles.md
LOAD: active-voice-principles.md
LOAD: acronym-handling-principles.md

IF document language is German:
  LOAD: german-style-principles.md
  LOAD: german-hook-principles.md
```

Impact techniques for arc mode come from `techniques-overview.md`, already loaded above: `## 4. Number Plays (6 Techniques)` for quantification, and `## 5. Forcing Functions` through `## 8. Compound Impact Calculation` for urgency, contrast framing, you-phrasing and compound-impact arithmetic. Apply them per-element via that file's application matrix, not generically across the document. Power words and rhetorical devices are NOT in that file, and no reference arc mode loads carries them -- apply them from your own knowledge, at the densities Step 5 states.

After loading, SKIP Steps 3-4 below. Proceed directly to skill workflow Step 3 (structure comes from the arc, not from a framework).

---

### Sales Loading Block

When `mode = sales`, load Power Positions plus supporting impact techniques. Sales mode still uses a deliverable type and framework, so continue to Standard Loading Block after loading these.

```
LOAD: power-positions.md
LOAD: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
```

In `techniques-overview.md`, sales mode uses `## 4. Number Plays (6 Techniques)` for the DOES layer and `## 5. Forcing Functions` through `## 8. Compound Impact Calculation` for the urgency and framing behind the MEANS layer. Power words are NOT in that file: the MEANS-layer vocabulary sales mode uses is the `MEANS layer Power Word categories` table inside `power-positions.md`, already loaded above.

Then continue to the Standard Loading Block for deliverable + framework selection.

---

### Standard Loading Block

This is the normal path for all non-arc tasks (including sales mode, which adds to this).

#### 2a. Core Principles (always load these four)

```
LOAD: clarity-principles.md
LOAD: conciseness-principles.md
LOAD: active-voice-principles.md
LOAD: acronym-handling-principles.md
```

#### 2b. Language-Conditional Principles

```
IF document language is German:
  LOAD: german-style-principles.md
  LOAD: german-hook-principles.md
```

#### 2c. Optional Core Principles (load only when relevant)

```
IF content is technical and needs accessibility:
  LOAD: plain-language-principles.md

IF visual hierarchy and scannability are priorities:
  LOAD: readability-principles.md
```

---

## Step 3: Select Deliverable Type

Identify which deliverable the user wants. This is REQUIRED for standard mode.

<deliverable_selection>
Map the user's request to exactly one deliverable type. Use this lookup table:

| User says                                      | deliverable_type     | House conventions                         |
|------------------------------------------------|----------------------|-------------------------------------------|
| memo, memorandum, internal communication       | memo                 | 1 page, medium formality                  |
| email, message, correspondence                 | email                | 200-300 words, medium formality           |
| brief, briefing, briefing document             | brief                | 1-3 pages, medium-high formality          |
| report, analysis, findings                     | report               | variable length, high formality           |
| proposal, pitch, business case                 | proposal             | variable length, high formality           |
| one-pager, one pager, summary sheet            | one-pager            | exactly 1 page, medium formality          |
| executive summary, exec summary                | executive-summary    | 1-2 pages, high formality                 |
| letter, business letter, formal letter         | business-letter      | 1 page, very high formality               |
| blog, blog post, article, thought leadership   | blog                 | 800-1500 words, medium formality          |

If the user's request does not clearly map to one of these, ask them to clarify before proceeding.

The length and formality conventions above are the house-specific part. Produce the deliverable's conventional structure from your own knowledge of the form — this reference system does not restate it.
</deliverable_selection>

---

## Step 4: Select Messaging Framework

<framework_selection>
Apply this logic in order:

1. If the user explicitly names a framework, apply that framework.
2. If the user does not name a framework, take the default from the `Default Framework` column of the `## Quick Lookup: Deliverable to Default Load Set` table below, keyed on the `deliverable_type` resolved in Step 3.
3. If multiple frameworks seem equally suitable and the user has not chosen, use the Quick Lookup default -- do not ask unless genuinely ambiguous.

Available frameworks. There is no reference file per framework: apply each from your own knowledge of it. This table pins the vocabulary and the house selection criterion, which is what the skill actually supplies.

| Framework         | Best for                                              |
|-------------------|-------------------------------------------------------|
| BLUF              | Action-required, time-sensitive, executive audience    |
| Pyramid           | Complex recommendations, structured analysis           |
| SCQA              | Narrative flow, problem-solving, building urgency      |
| Inverted Pyramid  | Web content, press releases, scannable documents       |
| STAR              | Case studies, examples, behavioral contexts            |
| PSB               | Marketing, sales, customer-facing content              |
| FAB               | Product focus, feature-heavy content                   |
</framework_selection>

---

## Step 5: Load Conditional References

These references load only when specific conditions are met. Check each independently.

### Impact Techniques

```
IF impact_level = high OR audience is executive/C-suite OR deliverable is executive-summary:
  LOAD: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
```

What that file carries: `## 4. Number Plays (6 Techniques)` for quantification, `## 5. Forcing Functions` for urgency stacking, `## 6. Contrast Structure` for cognitive-dissonance framing, `## 7. You-Phrasing` for reader-centred phrasing, and `## 8. Compound Impact Calculation` for the compound-impact arithmetic.

What it does NOT carry. No reference file carries these either, except sales mode's `power-positions.md`, which has its own MEANS-layer power-word categories. Apply each from your own knowledge of the craft, at the house densities below:

```
Power words        -- 3-5 per page, in headlines and CTAs; match category to context
Rhetorical devices -- 2-3 per document, at opening and closing (Rule of Three, antithesis)
Executive framing  -- lead with the ask, quantify everything, one page max, decision clarity
```

### Formatting Standards

```
IF deliverable needs visual elements (one-pager, report, blog, proposal):
  LOAD: visual-elements.md

IF document has multi-section structure:
  LOAD: heading-hierarchy.md

IF document contains inline citations:
  LOAD: citation-formatting.md

IF user asks about markdown syntax:
  LOAD: markdown-basics.md
```

### Stakeholder Review

```
IF review not explicitly skipped:
  Delegate to cogni-workspace:copy-reader skill (handles its own reference loading)
```

`review_mode` accepts `reader` (the default) and `skip`. `automated` is a deprecated alias for `reader` -- it no longer selects an inline review path.

Stakeholder defaults by audience:

| Audience          | Default stakeholders              |
|-------------------|-----------------------------------|
| executive         | executive, technical, end-user    |
| technical         | technical, executive              |
| general           | end-user, marketing, executive    |
| legal             | legal, executive, technical       |
| sales / marketing | marketing, executive, end-user    |

### Examples and Templates

There are no example or template reference files. When the user asks for a worked example or a fillable scaffold, produce one for the resolved deliverable type and framework, honouring the length and formality conventions in Step 3 and the core principles already loaded.

### Workflow Guide

```
IF task is complex (multi-step, dependencies, first-time user):
  LOAD: step-by-step-guide.md
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
| executive-summary  | BLUF              | clarity, conciseness, active-voice | techniques-overview (impact)   |
| business-letter    | (Direct/Indirect) | clarity, conciseness, active-voice | --                             |
| blog               | Inverted Pyramid  | clarity, readability, active-voice | visual-elements                |

---

## File Inventory

All reference files in this system, grouped by topic. Every basename below is also its path relative
to `references/` — the groups are a reading aid, not directories. Use this as the source of truth for
valid file paths.

### Core principles and translation
- `clarity-principles.md` -- 15-20 word sentences, concrete language, simple words
- `conciseness-principles.md` -- 3-5 sentence paragraphs, eliminate filler, strong verbs
- `compression-principles.md` -- `--scope=compress`: word-count minimization as the primary objective, zero precision loss, the Step 5 precision-preservation gate
- `active-voice-principles.md` -- 80%+ active voice, clear subjects, transformation patterns
- `acronym-handling-principles.md` -- First-mention acronym expansion, audience-tuned (expert/mixed/lay); proper-noun and structure-marker exclusions
- `german-style-principles.md` -- Wolf Schneider rules: 12-word clauses, Satzklammer, Mittelfeld, Floskeln
- `german-hook-principles.md` -- Wolf Schneider / Reiners / Nannen: 12 opening-sentence rules, Küchenzuruf test, arc hook strategies
- `plain-language-principles.md` -- Technical content accessibility
- `readability-principles.md` -- Visual hierarchy and scannability
- `translation-principles.md` -- Two-pass translate-then-polish philosophy; what to translate vs preserve; citation-anchored translation; per-language charset table; deterministic dispatch + 7×7 validity matrix
- `translation-en-to-de.md` -- EN→DE: Satzklammer formation, compound nouns, gender resolution, Sie-form, umlaut correctness
- `translation-de-to-en.md` -- DE→EN: compound decomposition, sentence splitting, nominal→verbal style, number/date formatting
- `translation-en-to-fr.md` -- EN→FR: vouvoiement, accent correctness, de-phrases, number/date conventions
- `translation-en-to-it.md` -- EN→IT: Lei courtesy form, accents (è vs e), di-phrases, number/date conventions
- `translation-en-to-es.md` -- EN→ES: usted, accents + ñ, inverted ¿¡, number/date conventions
- `translation-en-to-nl.md` -- EN→NL: u-vorm, ASCII charset, closed compounds, V2/clause-final verbs
- `translation-en-to-pl.md` -- EN→PL: Pan/Pani, ą/ć/ę/ł/ń/ó/ś/ź/ż, seven-case inflection, generic-Flesch note
- `translation-de-to-fr.md` -- DE→FR: Sie→vous, compound decomposition, Satzklammer flattening (target rules → en-to-fr)
- `translation-de-to-it.md` -- DE→IT: Sie→Lei, compound decomposition (target rules → en-to-it)
- `translation-de-to-es.md` -- DE→ES: Sie→usted, compound decomposition (target rules → en-to-es)
- `translation-de-to-nl.md` -- DE→NL: Sie→u, morpheme re-spelling, cognate false friends (target rules → en-to-nl)
- `translation-de-to-pl.md` -- DE→PL: Sie→Pan/Pani, compound decomposition, case-driven order (target rules → en-to-pl)
- `translation-fr-to-en.md` -- FR→EN: false friends, sentence splitting, no-accent charset, number conversion
- `translation-it-to-en.md` -- IT→EN: false friends, sentence splitting, no-accent charset, number conversion
- `translation-es-to-en.md` -- ES→EN: false friends, drop inverted punctuation, no-accent charset, number conversion
- `translation-nl-to-en.md` -- NL→EN: compound decomposition, clause-final verb reordering, false friends
- `translation-pl-to-en.md` -- PL→EN: restore articles, fix case-driven order, false friends, no-diacritic charset
- `translation-fr-to-de.md` -- FR→DE: vous→Sie, recompose compounds, false friends (German production → en-to-de)
- `translation-it-to-de.md` -- IT→DE: Lei→Sie, recompose compounds, false friends (German production → en-to-de)
- `translation-es-to-de.md` -- ES→DE: usted→Sie, drop ¿¡, recompose compounds (German production → en-to-de)
- `translation-nl-to-de.md` -- NL→DE: u→Sie, re-spell compounds + add umlauts, cognate false friends (German production → en-to-de)
- `translation-pl-to-de.md` -- PL→DE: Pan/Pani→Sie, add articles, recompose compounds (German production → en-to-de)

### Formatting standards
- `visual-elements.md` -- Tables, callouts, lists, emphasis (~1 visual per 2 paragraphs)
- `heading-hierarchy.md` -- Max 3 levels, front-loaded keywords, parallel structure
- `citation-formatting.md` -- Citation placement, superscript commas, preservation rules
- `markdown-basics.md` -- Standard markdown syntax reference

### Sales techniques
- `power-positions.md` -- IS-DOES-MEANS structure, enhancement by layer, Value Wedge

### Arc preservation
- `arc-preservation.md` -- Arc detection, structure preservation, forbidden vs allowed modifications, translation-mode word band, validation checklist. Per-arc per-element technique rules are read at runtime from the `text-to-narrative` skill's arc contract (`references/arc-{arc_id}.md` `## Elements`) and `techniques-overview.md`

### Workflow
- `step-by-step-guide.md` -- Complete sub-steps, gate checks, validation procedures

### Outside this tree
- `${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md` -- the ecosystem's single copy of the impact techniques: Number Plays (6), Forcing Functions, Contrast Structure, You-Phrasing, Compound Impact Calculation, plus the per-arc-element application matrix. Loaded by the Arc and Sales blocks and by Step 5.
- The `copy-reader` skill's own `references/persona-*.md` profiles and `references/synthesis-protocol.md` -- the ecosystem's single copy of the stakeholder personas and the synthesis protocol. Not loaded from here: Step 5 delegates the whole review to that skill, which loads them itself.

---

## Fallback Behavior

When the user's request is ambiguous or does not specify a deliverable type:

1. Load the three core principles (clarity, conciseness, active-voice). These are always safe to load.
2. Ask the user to specify their deliverable type. Present the nine options from the deliverable selection table above.
3. Do NOT guess a deliverable type. Wait for clarification.

When a reference file does not exist at the expected path:

1. Log a note that the reference was not found.
2. Continue without it. No single file is a hard dependency -- the deliverable conventions and framework selection in Steps 3 and 4 of this index are enough to produce quality output.
