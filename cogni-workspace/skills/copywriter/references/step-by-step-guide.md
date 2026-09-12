---
title: Step-by-Step Workflow Guide
type: process-documentation
category: workflow
version: 6.0
updated: 2026-02-25
---

# Copywriter Skill: Step-by-Step Workflow Guide

<context>
This is the detailed execution guide for the copywriter skill's 8-step workflow. It supplements SKILL.md by providing sub-step procedures, decision logic, and validation criteria for each phase. SKILL.md is the authoritative source for the workflow definition. This guide is the authoritative source for how to execute each step.
</context>

## Contents

- [Workflow Overview](#workflow-overview)
  - [Scope Handling (Polish Mode)](#scope-handling-polish-mode)
- [Step 1: Parse Parameters & Load References](#step-1-parse-parameters-load-references)
  - [1A: Extract Parameters from User Request](#1a-extract-parameters-from-user-request)
  - [1B: Detect Mode -- Arc-Aware vs. Standard](#1b-detect-mode----arc-aware-vs-standard)
  - [1C: Load References (Standard Mode)](#1c-load-references-standard-mode)
  - [Step 1 Gate](#step-1-gate)
- [Step 2: Gather Content Requirements](#step-2-gather-content-requirements)
  - [2A: Ask Clarifying Questions](#2a-ask-clarifying-questions)
  - [2B: Identify Visual Element Needs](#2b-identify-visual-element-needs)
  - [Step 2 Gate](#step-2-gate)
- [Step 3: Apply Structure & Framework](#step-3-apply-structure-framework)
  - [3A: Apply Deliverable Structure](#3a-apply-deliverable-structure)
  - [3B: Integrate Framework Pattern](#3b-integrate-framework-pattern)
  - [3C: Map Content to Structure](#3c-map-content-to-structure)
  - [Step 3 Gate](#step-3-gate)
- [Step 4: Apply Writing Principles](#step-4-apply-writing-principles)
  - [4A: Detect Document Language](#4a-detect-document-language)
  - [4B: Draft the Document](#4b-draft-the-document)
  - [4C: Apply Paragraph Separation and Bold Anchoring](#4c-apply-paragraph-separation-and-bold-anchoring)
  - [Step 4 Gate](#step-4-gate)
- [Step 5: Apply Impact Techniques (Optional)](#step-5-apply-impact-techniques-optional)
  - [Step 5 Gate](#step-5-gate)
- [Step 6: Stakeholder Review (Optional)](#step-6-stakeholder-review-optional)
  - [6A: Resolve Stakeholders](#6a-resolve-stakeholders)
  - [6B: Delegate to the copy-reader Skill](#6b-delegate-to-the-copy-reader-skill)
  - [Step 6 Gate](#step-6-gate)
- [Step 7: Synthesis & Refinement (Owned by the copy-reader skill)](#step-7-synthesis-refinement-owned-by-the-copy-reader-skill)
  - [Step 7 Gate](#step-7-gate)
- [Step 8: Validate & Write Document](#step-8-validate-write-document)
  - [8A: Run Validation Checks](#8a-run-validation-checks)
  - [8B: Run Readability Script (if available)](#8b-run-readability-script-if-available)
  - [8C: Backup Original Document](#8c-backup-original-document)
  - [8D: Apply Citation Formatting (if document contains citations)](#8d-apply-citation-formatting-if-document-contains-citations)
  - [8E: Write Final Document](#8e-write-final-document)
  - [8F: Present Summary to User](#8f-present-summary-to-user)
  - [Step 8 Gate (Final)](#step-8-gate-final)
- [Decision Trees](#decision-trees)
  - [Framework Selection (when not specified by user)](#framework-selection-when-not-specified-by-user)
  - [When to Load Additional References](#when-to-load-additional-references)
  - [Handling Insufficient Information](#handling-insufficient-information)
  - [Handling Ambiguous Deliverable Type](#handling-ambiguous-deliverable-type)


<critical_rules>
- Initialize TodoWrite at the start with all 8 workflow steps. Mark each step as you complete it.
- Load references progressively: only load what the current step requires.
- SKILL.md defines two critical preservation constraints that override all other guidance:
  1. German characters (ae, oe, ue, ss) must NEVER replace (a-umlaut, o-umlaut, u-umlaut, eszett).
  2. Citations must NEVER be removed, reformatted, relocated, or reduced in count.
- When a step fails, log the failure reason and continue to the next step. Never block document delivery.
</critical_rules>

## Workflow Overview

```text
Step 1: Parse Parameters & Load References
Step 2: Gather Content Requirements
Step 3: Apply Structure & Framework
Step 4: Apply Writing Principles
Step 5: Apply Impact Techniques (optional)
Step 6: Stakeholder Review (optional, delegated to copy-reader)
Step 7: Synthesis & Refinement (owned by copy-reader)
Step 8: Validate & Write Document
```

### Scope Handling (Polish Mode)

When the skill receives a `SCOPE` parameter (from `/copywrite --scope=`), certain steps are skipped:

| Step | full | structure | tone | formatting |
|------|------|-----------|------|------------|
| 1. Parse & load refs | YES | YES | YES | YES |
| 2. Gather content | SKIP | SKIP | SKIP | SKIP |
| 3. Structure & framework | YES | YES | SKIP | SKIP |
| 4. Writing principles | YES | SKIP | YES | YES |
| 5. Impact techniques | YES | SKIP | SKIP | YES |
| 6-7. Review & synthesis | YES | SKIP | SKIP | SKIP |
| 8. Validate & write | YES | YES | YES | YES |

**Critical exception:** Sub-step 4C (Paragraph Separation and Bold Anchoring) runs in ALL scopes. Dense paragraphs and missing bold anchors are readability defects, not style choices.

---

## Step 1: Parse Parameters & Load References

### 1A: Extract Parameters from User Request

Parse the user's request to extract these parameters. Think through what the user is asking for before proceeding.

**Required parameters:**

| Parameter | Values | Extraction Guidance |
|-----------|--------|-------------------|
| `deliverable_type` | memo, email, brief, report, proposal, one-pager, executive-summary, business-letter, blog | Infer from request context if not explicit. "Can you write me an email..." = email. |
| `topic` | Free text | The subject matter of the document. |
| `audience` | Free text | Who will read this. Default to "general business audience" if unstated. |

**Optional parameters:**

| Parameter | Values | Default |
|-----------|--------|---------|
| `framework` | bluf, pyramid, scqa, star, psb, fab, inverted-pyramid | Use deliverable's recommended framework (see Quick Reference in SKILL.md) |
| `impact_level` | standard, high | standard (set to high for executive/C-suite audiences) |
| `MODE` | standard, sales | standard |
| `output_path` | File path | Current working directory |
| `tone` | formal, semi-formal, casual | semi-formal |
| `length` | Word count or page count | Use deliverable default |
| `review_mode` | reader, skip (`automated` = deprecated alias for reader) | reader |
| `skip_review` | true, false | false |
| `stakeholders` | List of perspective names | Use audience-based defaults from SKILL.md |

### 1B: Detect Mode -- Arc-Aware vs. Standard

Before loading any framework, check whether the input document is an arc narrative.

**Arc detection criteria (if ANY are true, activate arc mode):**

1. Input document has YAML frontmatter containing `arc_id`
2. Task prompt explicitly mentions arc preservation
3. Document H2 headings match a known arc pattern (e.g., "Why Change", "Why Now", "Why Pay", "Why Us")

**If arc mode activates:**

```text
READ: references/arc-preservation.md
READ: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/arc-{arc_id}.md
READ: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
```

Set `arc_mode: true` and `arc_id: {detected_arc_id}`. Do NOT load a messaging framework or deliverable type -- the arc IS the structure.

**If arc mode does NOT activate (standard mode):**

Proceed to 1C.

### 1C: Load References (Standard Mode)

Load exactly this reference and no more:

```text
READ: references/clarity-principles.md
```

Resolve the deliverable type and the messaging framework from `references/00-index.md` Steps 3 and 4 -- the house length and formality conventions and the framework selection table live there, and neither has a per-item reference file. If framework was not specified, use the deliverable's default framework from the Quick Lookup table in `references/00-index.md`.

**Conditional additional loads:**

- If `impact_level: high` OR audience is executive/C-suite:
  ```text
  READ: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
  ```
- If `MODE: sales`:
  ```text
  READ: references/power-positions.md
  READ: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
  ```

### Step 1 Gate

Before proceeding, verify:
- All required parameters have values (extracted or defaulted)
- Mode determination is complete (arc_mode true or false)
- Correct references are loaded (and only those references)

---

## Step 2: Gather Content Requirements

### 2A: Ask Clarifying Questions

Present questions to the user to fill information gaps. Select questions based on deliverable type and framework. Do not ask questions whose answers are already evident from the user's request.

**Core questions (ask for all deliverables unless already answered):**

- What is the primary purpose of this document?
- What action should readers take after reading?
- What are the 2-3 key messages or takeaways?

**Framework-specific questions (ask only for the selected framework):**

| Framework | Key Questions |
|-----------|--------------|
| BLUF | What is the bottom line recommendation? What are the top 3 supporting facts? |
| Pyramid | What is the main argument? What MECE groups support it? |
| SCQA | What is the current Situation? What Complication has arisen? What is the Answer? |
| STAR | What was the Situation? What Task was needed? What Action was taken? What Result occurred? |
| PSB | What is the Problem? What is the proposed Solution? What are the Benefits? |
| FAB | What are the key Features? What Advantages do they provide? What Benefits result? |
| Inverted Pyramid | What is the most critical information? What details support it? |

**Deliverable-specific questions (ask only for the selected deliverable):**

| Deliverable | Additional Questions |
|-------------|---------------------|
| memo | Are there action items or decisions needed? Is there a deadline? |
| email | What is the specific call-to-action? Is this first contact or follow-up? |
| proposal | What is the problem/opportunity? What are costs and expected ROI? |
| report | What are key findings? What methodology was used? |
| one-pager | What are the 3-5 most important points? |
| blog | What is the hook? What keywords matter for SEO? |

**For high-impact documents, also ask:**

- What quantifiable data supports the message? (needed for number plays)
- What timeline or scarcity factor exists? (needed for urgency/power words)

### 2B: Identify Visual Element Needs

Based on the content gathered, determine what visual elements the document needs:

- **Tables**: Use when comparing options, showing multi-attribute data, or presenting structured metrics
- **Numbered lists**: Use for sequential steps, ranked priorities, or process flows
- **Bullet lists**: Use for unordered items, features, benefits, or key points
- **Bold/callout elements**: Use for critical facts, deadlines, or key metrics

### Step 2 Gate

Before proceeding, verify:
- All required content information has been gathered (or reasonable defaults applied)
- The user has confirmed key messages and purpose
- Visual element needs are identified

---

## Step 3: Apply Structure & Framework

**If `arc_mode: true`:** SKIP this step entirely. The arc provides all structure. Proceed directly to Step 4.

### 3A: Apply Deliverable Structure

Use the structural template from the loaded deliverable reference file. The deliverable reference contains the canonical section structure, required components, and length constraints.

Do NOT duplicate deliverable structures from memory. The loaded reference file is the authoritative source.

### 3B: Integrate Framework Pattern

Layer the selected messaging framework onto the deliverable structure. The framework determines the logical flow of content within each section.

| Framework | Integration Pattern |
|-----------|-------------------|
| BLUF | First sentence/paragraph = bottom line. Remaining content = supporting facts ordered by importance. Final section = next steps. |
| Pyramid | Opening = main argument. Body sections = MECE groupings. Each group = evidence underneath. Close = summary + CTA. |
| SCQA | Open with Situation (context). Introduce Complication (problem). Pose Question (implicit or explicit). Provide Answer (recommendation). |
| STAR | Background = Situation. Challenge = Task. Execution = Action. Impact = Result. |
| PSB | First section = Problem definition. Middle = Solution proposal. Close = Benefits and value. |
| FAB | Lead with Features. Explain Advantages. Conclude with Benefits to reader. |
| Inverted Pyramid | Lead = most critical information. Middle = important supporting details. End = background/context. |

### 3C: Map Content to Structure

Place the gathered content (from Step 2) into the structural framework. For each section:

1. Identify which content points belong in this section
2. Arrange them according to the framework's logic
3. Flag any sections that lack sufficient content (may need to ask user for more)

### Step 3 Gate

Before proceeding, verify:
- Document has a complete structural outline
- Framework pattern is correctly integrated
- All gathered content is mapped to sections

---

## Step 4: Apply Writing Principles

### 4A: Detect Document Language

Determine the language from content, user request, or `--lang` parameter.

**If German detected:**

```text
READ: references/german-style-principles.md
```

Apply Wolf Schneider rules:
- Max 12 words per clause (stricter than English)
- Max 6 words / 12 syllables before the verb (Vorfeld)
- Break open sentence brackets (Satzklammer) -- prefer single-part verbs
- Keep subject and verb within 3 words of each other
- Chain main clauses instead of nesting subordinate clauses
- Max 2 attributes before a noun; use relative clauses for more
- Eliminate all items on the Floskelliste (check against the reference)
- Vary sentence lengths for rhythm (short-long-short)

**If English detected (or default):**

Apply these principles during drafting (do not load additional references -- these rules are self-contained):

| Principle | Target | Technique |
|-----------|--------|-----------|
| Clarity | 15-20 word average sentence length | One idea per sentence. Concrete over abstract. Simple words over complex synonyms. |
| Conciseness | 3-5 sentences per paragraph | Eliminate filler phrases ("in order to" -> "to", "due to the fact that" -> "because"). Use strong verbs ("decide" not "make a decision"). |
| Active voice | 80%+ of sentences | Subject performs the action. Convert passive: "The project was completed by the team" -> "The team completed the project." |
| Plain language | No undefined jargon | Define technical terms on first use. Write as you would explain to an intelligent colleague. |

### 4B: Draft the Document

Using the structural outline from Step 3 and the writing principles from 4A, write the complete document draft. Apply all principles during drafting rather than as a separate editing pass.

**For arc-aware mode:** Apply writing principles to each arc element individually. Do NOT restructure or reorder elements. Strengthen prose within each element while preserving:
- Exact heading text
- Element boundaries (no content moves between elements)
- The distinct purpose of each element

### 4C: Apply Paragraph Separation and Bold Anchoring

After drafting or tone transformation, perform this formatting pass on every section:

**Paragraph splitting procedure:**

1. Count sentences in each paragraph
2. If a paragraph has 6+ sentences, find the topic boundary and split
3. If a paragraph covers two distinct points (even in 4-5 sentences), split at the boundary
4. Verify each resulting paragraph is 3-5 sentences, 40-70 words
5. Ensure one blank line separates consecutive paragraphs

**Bold anchoring procedure:**

1. Scan each paragraph for key data: percentages, counts, ratios, dates, metric names
2. Bold the 2-4 word phrase containing the data point (e.g., "**31% of variance**", "**2.3x more likely**")
3. Bold the topic anchor of a paragraph's lead sentence when it names a key concept (e.g., "**Organizational culture** emerges as...")
4. Verify 2-3 bold instances per paragraph, no more
5. Never bold an entire sentence or clause

This sub-step applies regardless of SCOPE.

### Step 4 Gate

Before proceeding, verify:
- Complete draft exists with all sections populated
- Writing principles are applied throughout (not just in spots)
- Language-specific rules are followed (German Schneider rules OR English clarity/conciseness)
- If arc mode: all element headings and boundaries are preserved
- No paragraph exceeds 5 sentences or 70 words
- Key data points (numbers, percentages, ratios) are bolded with 2-4 word anchors

---

## Step 5: Apply Impact Techniques (Optional)

**Skip this step if:** `impact_level: standard` AND no executive audience AND `MODE: standard`

**If `arc_mode: true`:** Apply techniques PER ELEMENT using the arc contract's `## Elements` (each `### N.` section's Techniques and Hard rules) and narrative's `techniques-overview.md` application matrix.

For each arc element:
1. Look up the element's `### N.` section in the active arc's contract
2. Apply the element's specific Number Play variant (e.g., compound impact for "Why Pay", ratio framing for "Why Change")
3. Strengthen the element's primary technique (e.g., forcing functions in "Why Now", PSB in "Why Change")
4. Apply Power Words sparingly (3-5 per element) in body text only
5. Follow element-specific polish rules from the technique map

Do NOT apply techniques generically across the whole document in arc mode.

**If `MODE: sales`:** Apply Power Positions enhancement.

Load `references/power-positions.md` (if not already loaded in Step 1).

Enhancement rules by layer:
- **IS layer**: Make specific and concrete (add numbers, specs, timeframes)
- **DOES layer**: Quantify outcomes using Number Plays
- **MEANS layer**: Strengthen resonance using Power Words

Critical: NEVER merge IS into DOES or DOES into MEANS. Preserve all structure markers exactly.

**Standard high-impact mode:** Apply the impact techniques from the upstream `narrative` reference.

Load as needed:
```text
READ: ${CLAUDE_PLUGIN_ROOT}/skills/text-to-narrative/references/techniques-overview.md
```

Application targets from that file:
- **Number Plays** (`## 4`): Transform vague claims into specific data. Apply to key metrics, comparisons, and outcomes.
- **Forcing Functions, Contrast Structure, You-Phrasing, Compound Impact Calculation** (`## 5` through `## 8`): Stack urgency with quantified consequences, frame against conventional wisdom, address the reader directly, and compound the impact arithmetic.

Application targets that file does NOT carry. No reference file carries them either, except sales mode's `references/power-positions.md` and its MEANS-layer power-word categories. Apply from your own knowledge of the craft, at these house densities:
- **Power Words**: 3-5 per page, concentrated in headlines and CTAs. Match category to context (urgency for deadlines, trust for risk reduction).
- **Rhetorical Devices**: 2-3 per document, placed at opening and closing. Rule of Three for key messages, antithesis for contrasts.
- **Executive Framing**: Lead with the ask, quantify everything, one page max, decision clarity.

### Step 5 Gate

Before proceeding, verify:
- Impact techniques are applied to appropriate locations (not sprayed everywhere)
- Power word density is within target (3-5 per page)
- Number plays use real data from the gathered content (do not fabricate numbers)
- If arc mode: techniques match the per-element technique map
- If sales mode: IS-DOES-MEANS structure markers are preserved exactly

---

## Step 6: Stakeholder Review (Optional)

**Skip this step if:** `skip_review: true` OR `review_mode: skip` OR deliverable is informal (email, casual memo).

### 6A: Resolve Stakeholders

Resolve `{{stakeholders}}` before dispatching -- it is the copy-reader skill's `PERSONAS` argument.

Use the explicit `stakeholders` parameter when one is given. Otherwise take the defaults for the audience parameter:

| Audience | Default Stakeholders |
|----------|---------------------|
| executive | executive, technical, end-user |
| technical | technical, executive |
| general | end-user, marketing, executive |
| legal | legal, executive, technical |
| sales/marketing | marketing, executive, end-user |

### 6B: Delegate to the copy-reader Skill

```text
Delegate to: cogni-workspace:copy-reader
Args: FILE_PATH={{output_path}} PERSONAS={{stakeholders}} AUTO_IMPROVE=true
```

The copy-reader skill handles parallel multi-persona Q&A, synthesis and automatic improvement against its own persona profiles and synthesis protocol. It loads each persona's criteria from its own `references/persona-*.md` profiles, scores each criterion PASS (100) / CONCERN (60) / FAIL (0), computes the weighted overall score, and returns structured feedback with priority labels.

`review_mode` accepts `reader` (the default) and `skip`; `automated` is a deprecated alias for `reader`.

**Scoring thresholds** (as returned by the copy-reader skill):

| Score | Assessment |
|-------|-----------|
| 85-100 | Excellent -- meets stakeholder expectations |
| 70-84 | Good -- minor improvements recommended |
| 50-69 | Concerns -- significant improvements needed |
| 0-49 | Failing -- major issues detected |

**Graceful degradation:**
- Single stakeholder review fails -> Log warning, continue with remaining stakeholders
- All stakeholder reviews fail -> Skip to Step 8 with `fallback_reason: "review_failure"`

### Step 6 Gate

Before proceeding, verify:
- All selected stakeholders have been reviewed (or failures logged)
- Feedback is structured with clear priority labels (CRITICAL, HIGH, OPTIONAL)

---

## Step 7: Synthesis & Refinement (Owned by the copy-reader skill)

There is no inline synthesis pass. The copy-reader skill dispatched in Step 6 aggregates and prioritizes the persona feedback, resolves conflicts and applies improvements itself, using its own `references/synthesis-protocol.md` — the single copy of the priority-escalation ladder, the conflict-resolution table and the tiebreaker hierarchy.

**Graceful degradation:**
- The copy-reader skill validates its own output and reverts to its backup on failure.
- copy-reader dispatch fails -> Continue to Step 8 with the document as written, log `fallback_reason: "review_failure"`.

### Step 7 Gate

Before proceeding, verify:
- The copy-reader skill returned, or its failure is logged with a `fallback_reason`
- Review never blocks delivery: an unavailable review means Step 8 proceeds on the unreviewed document

---

## Step 8: Validate & Write Document

### 8A: Run Validation Checks

Evaluate the final document against all applicable criteria. Think through each check carefully.

**Universal checks (always apply):**

| Check | Criterion | Action on Failure |
|-------|-----------|------------------|
| German characters | All umlauts and eszett preserved as-is | Fix: restore original characters |
| Citations | Count >= source document count, format unchanged | Fix: restore missing citations from source |
| Protected content | Diagram placeholders, figure refs, captions unchanged | Fix: restore from source |
| Readability | Flesch/Amstad score 50-60 | Fix: simplify complex sentences |
| Active voice | 80%+ usage | Fix: convert passive constructions |
| Formatting | Consistent markdown, heading hierarchy correct | Fix: standardize |

**Standard-mode checks (skip if arc_mode):**

| Check | Criterion | Action on Failure |
|-------|-----------|------------------|
| Framework compliance | Document follows selected framework pattern | Fix: restructure to match framework |
| Deliverable requirements | Length, structure, tone match deliverable type | Fix: adjust to requirements |
| Required components | All mandatory sections present (e.g., CTA for email, next steps for brief) | Fix: add missing components |

**Arc-mode checks (only if arc_mode):**

| Check | Criterion | Action on Failure |
|-------|-----------|------------------|
| Heading text | All H2 headings unchanged from source | Revert failing element to original |
| Element count | H2 count matches source exactly | Revert to original structure |
| Primary technique | Each element's technique intact per technique map | Revert failing element |
| Number Play variant | Correct variant applied per element per technique map | Revert failing element |
| Word count | Each element within +/-50 words of arc definition target | Trim or expand as needed |
| Element boundaries | No content moved between elements | Revert failing element |
| Bridge section | Unchanged from source | Restore from source |

**German-specific checks (only if detected_language is German):**

| Check | Criterion | Action on Failure |
|-------|-----------|------------------|
| Clause length | Average 10-12 words, max 12 | Break long clauses |
| Floskel count | 0 (check against Floskelliste) | Remove all Floskeln |
| Sentence variation | Standard deviation > 3 words | Vary sentence lengths |
| Attribute chains | Max 2 before a noun | Convert to relative clauses |

**Review checks (only if stakeholder review was conducted):**

| Check | Criterion | Action on Failure |
|-------|-----------|------------------|
| Critical improvements | All CRITICAL items applied | Apply missing critical improvements |

If arc validation fails for a specific element: revert that element to its original text. Log with `fallback_reason="arc_technique_violation"`. Continue with remaining elements.

### 8B: Run Readability Script (if available)

```bash
python3 scripts/calculate_readability.py "{output_path}" --lang auto
```

This script auto-detects German vs English and applies the correct formula. Target range 50-60 applies to both languages.

### 8C: Backup Original Document

Before writing, check if a file already exists at the output path and back it up:

```bash
if [[ -f "{output_path}" ]]; then
  dir=$(dirname "{output_path}")
  filename=$(basename "{output_path}")
  cp "{output_path}" "${dir}/.${filename}"
fi
```

Report backup creation if applicable.

### 8D: Apply Citation Formatting (if document contains citations)

```text
READ: references/citation-formatting.md
```

1. Move citations from "Begründung:" paragraphs to individual "Umsetzung:" list items (place at end of specific claim)
2. Add superscript commas between consecutive citations:
   ```bash
   perl -pi -e 's/<\/sup><sup>/<\/sup><sup>,<\/sup> <sup>/g' "{output_path}"
   ```

### 8E: Write Final Document

Use the Write tool to create the document file.

**File naming:** Use descriptive kebab-case names including deliverable type (e.g., `proposal-crm-implementation.md`).

**File location:** Use specified `output_path`. If none specified, use current working directory. Confirm with user if ambiguous.

**Content:** Include all validated content. Add YAML frontmatter if appropriate for the deliverable type.

### 8F: Present Summary to User

```text
Document: {deliverable_type} using {framework}
File: {output_path}
Backup: {backup_path or "None (new file)"}
Quality: Framework {pass/fail} | Structure {pass/fail} | Readability {score}
Impact Techniques: {techniques applied, or "None"}
Citation Formatting: {applied/not applicable}
Review: {review outcome summary, or "Skipped"}

Next step: Run `/review-doc {output_path}` to get multi-stakeholder feedback before distribution
```

### Step 8 Gate (Final)

Confirm all of the following:
- Document is written to the specified path
- All validation checks passed (or failures were handled with fixes/reverts)
- Backup was created if overwriting an existing file
- Summary was presented to the user
- All 8 TodoWrite steps are marked complete

---

## Decision Trees

### Framework Selection (when not specified by user)

```text
Is the audience executive/C-suite?
  YES -> Is it analytical? -> Pyramid
         Is it a recommendation? -> BLUF
         Is it a problem to solve? -> SCQA
  NO  -> Is it a sales document? -> FAB or PSB
         Is it a case study? -> STAR
         Is it news/announcement? -> Inverted Pyramid
         Default -> BLUF
```

### When to Load Additional References

```text
User mentions quantifiable data -> READ: narrative's techniques-overview.md (## 4 Number Plays)
User mentions executive audience -> no file: apply executive framing from model knowledge
User mentions persuasion/impact -> READ: narrative's techniques-overview.md (## 5 to ## 8);
                                   power words and rhetorical devices have no file -- apply
                                   from model knowledge at the Step 5 densities
Document contains German text -> READ: german-style-principles.md
Document contains citations -> READ: citation-formatting.md (at Step 8)
Document has arc_id -> READ: arc-preservation.md, the arc's arc-definition.md, narrative's techniques-overview.md
MODE is sales -> READ: power-positions.md, narrative's techniques-overview.md
```

### Handling Insufficient Information

If the user provides insufficient information to complete a step:

1. Ask targeted questions (from Step 2 question bank) for only the missing information
2. If the user declines to provide details, apply reasonable defaults:
   - Missing audience -> "general business audience"
   - Missing framework -> the deliverable's row in the Quick Lookup table in `references/00-index.md`
   - Missing tone -> semi-formal
   - Missing key messages -> extract from any source material provided
3. State which defaults you are applying so the user can correct them

### Handling Ambiguous Deliverable Type

If multiple deliverable types could work:

1. Consider the audience (executives prefer brief formats)
2. Consider the purpose (decisions need memos/briefs, information sharing needs reports)
3. Consider the length (short = memo/email/one-pager, medium = brief/proposal, long = report)
4. If still ambiguous, ask the user with a recommendation: "I recommend a {type} because {reason}. Would you prefer a different format?"
