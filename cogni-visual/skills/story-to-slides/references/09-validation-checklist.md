# Validation Checklist

## Purpose

Guide systematic reasoning through five validation layers to catch schema violations, quality gaps, and structural errors before writing the final brief. Each layer includes a reasoning approach that walks through checks step by step.

## Core Principle

> Validation is argument about correctness, not mechanical checking.
> For each slide, ASK: "Would this survive a dry run in front of the audience?"
> If the answer is no — something is wrong.

## How to Use

Reason through each layer sequentially. For each check within a layer:

1. State what you are checking
2. Examine the generated slides as evidence
3. Make a pass/fail judgment with reasoning
4. If FAIL: fix immediately before proceeding to the next layer

---

## Layer 1: Schema Compliance

Verify all slides conform to `pptx-layouts.md` specifications, YAML parses correctly, and frontmatter is complete.

### Reasoning Approach

```text
REASON through schema compliance for each slide:

  1. CHECK layout type
     → Is the layout one of: title-slide, stat-card-with-context, four-quadrants,
       two-columns-equal, is-does-means, three-options, timeline-steps,
       layered-architecture, process-flow, gantt-chart,
       closing-slide?
     → FAIL if: layout name misspelled or invented
     → FIX: Replace with exact layout name from pptx-layouts.md

  2. CHECK required fields
     → Does this slide have ALL required fields for its layout type?
     → Reference pptx-layouts.md "Required Content" section per layout
     → For diagram layouts: Diagram field is REQUIRED
     → FAIL if: any required field missing or empty
     → FIX: Add missing field with content from the relevant step's output

  3. CHECK for unknown fields
     → Does this slide contain fields NOT defined in pptx-layouts.md?
     → FAIL if: invented field names present
     → FIX: Remove or map to correct field names

  3b. CHECK Diagram field constraints (diagram layouts only)
     → IF layout is layered-architecture:
       → Diagram must contain "graph" or "flowchart" with "subgraph" blocks
       → Max 3 subgraphs, max 4 nodes per subgraph, max 10 nodes total
       → Direction must be LR (not TB/TD — pre-transposed in Step 2g)
     → IF layout is process-flow:
       → Diagram must contain "graph LR" or "flowchart LR"
       → No subgraph blocks (use layered-architecture instead)
       → Max 6 nodes, linear chain only
     → IF layout is gantt-chart:
       → Diagram must contain "gantt" with dateFormat
       → Max 8 tasks, max 4 sections (phases)
     → FAIL if: Mermaid type mismatches layout, or constraints exceeded
     → FIX: Re-simplify to meet constraints listed above (reduce nodes/lanes/tasks until within limits, move detail to Speaker-Notes)

  4. CHECK for prohibited color fields
     → Does ANY slide contain Background, Text-Color, or Icon-Color?
     → v4.0 briefs must NEVER contain color fields
     → FAIL if: any color field present (including in optional fields)
     → FIX: Delete the color field entirely

  5. CHECK YAML syntax
     → Does each slide's YAML parse without errors?
     → Common issues: unquoted colons in text, missing quotes around URLs,
       incorrect indentation, tabs instead of spaces
     → FAIL if: YAML would fail to parse
     → FIX: Quote strings with special characters, fix indentation

  6. CHECK frontmatter completeness
     → Required keys: type ("presentation-brief"), version ("4.0"), theme,
       theme_path (must end in /theme.md), customer, provider, language,
       generated, arc_type, governing_thought, confidence_score (0.0-1.0)
     → FAIL if: any key missing or value invalid
     → FIX: Add missing keys from metadata collected in Step 1

  7. CHECK PPTX Rendering Requirements section
     → Must appear AFTER governing_thought paragraph and BEFORE ## Slide 1
     → Must be localized (EN or DE based on language parameter)
     → Must contain all 4 rules: exact text, complete notes, source links, superscript hyperlinks
     → FAIL if: section missing, mispositioned, or wrong language
     → FIX: Insert the localized requirements block from SKILL.md Step 9 template
```

### Pass Criteria

All slides use valid layouts, have all required fields, contain no unknown or color fields, parse as valid YAML. Frontmatter complete with correct values. PPTX Rendering Requirements section present and localized.

---

## Layer 2: Message Quality

Verify slide messages follow pyramid communication principles. The audience spends 3 seconds scanning each slide before the presenter speaks — if the titles don't carry the argument, the body text arrives too late.

### Reasoning Approach

```text
REASON through message quality by reading ONLY the slide headings in sequence:

  1. PERFORM the "title-only test"
     → Read all slide headings (## Slide N: ...) in order, ignoring body content
     → ASK: "Do I understand the full argument from titles alone?"
     → If the titles don't tell the story, message architecture failed
     → WHY: The audience reads titles first and decides whether to engage.
       A title that requires the body to make its point has already lost.

  2. CHECK each heading is an assertion
     → Assertions make a CLAIM: "688 Lives Lost Annually" ✅
     → Topic labels name a TOPIC: "Market Overview" ❌, "Our Solution" ❌
     → ASK for each: "Does this heading have a VERB and make a CLAIM?"
     → FAIL if: any heading names a topic without asserting
     → FIX: Return to Step 5a output and re-derive the assertion headline

  2b. CHECK headline completeness (title-banner test)
     → Apply the title-banner mental method from 05a step 5: cover the slide
       body AND the Bottom-Banner. Does the headline alone tell the audience
       WHAT is happening AND WHY it matters?
     → This check exists because models consistently produce weak headlines
       and patch them with banners. The anti-pattern is subtle — output looks
       plausible until you apply this test.
     → FAIL if: the Banner contains the "so what" that the title is missing
     → FIX: Fold the banner's consequence into the title per 05a step 5

  2c. CHECK for methodology jargon in client-facing copy
     → Scan ALL slide titles, headlines, bullets, Bottom-Banner for:
       "Power Position", "Why Change", "Why Now", "Why You", "Why Pay",
       "Unconsidered Need", "PP1", "PP2", "PP3"
     → Internal prep slides (with INTERNAL banner) are exempt
     → FAIL if: any methodology term found in client-facing slide content
     → FIX: Rewrite using customer-benefit language per SKILL.md "Client-facing copy hygiene"

  3. CHECK MECE sequence
     → Mutually Exclusive: are any two slides arguing the SAME point?
       (overlap means one should be cut or merged)
     → Collectively Exhaustive: is any major argument from the governing
       thought MISSING? (gap means a slide needs to be added)
     → WHY: Overlapping slides dilute focus — the audience hears the same
       point twice and wonders if the presenter ran out of material.
       Missing arguments leave gaps that a skeptical audience will probe in Q&A.
     → FAIL if: overlapping or missing arguments
     → FIX: Merge overlapping slides, add slides for gaps

  4. CHECK hero number isolation
     → For stat-card-with-context slides: is there exactly ONE hero number?
     → Hero-Stat-Box.Number should contain a single dominant number
     → WHY: A stat-card with two competing hero numbers creates split attention —
       neither lands. The 36pt treatment works because it anchors the eye to a
       single figure. Supporting numbers belong in sublabel or context box.
     → FAIL if: multiple hero-weight numbers on one slide
     → FIX: Move secondary numbers to Sublabel, Context-Box, or a new slide

  5. CHECK pyramid structure
     → Governing thought (title slide subtitle) → arguments → evidence
     → Does each slide connect logically to the governing thought?
     → FAIL if: a slide seems disconnected from the main argument
     → FIX: Re-frame the slide's message to connect, or cut it
```

### Pass Criteria

All headings are assertions. Title sequence tells the full story. MECE verified. Hero numbers isolated. Pyramid structure visible.

---

## Layer 3: Copywriting Quality

Verify slide copy is optimized for visual presentation.

### Reasoning Approach

```text
REASON through copywriting quality for each slide:

  1. CHECK number plays
     → Were statistics reframed for visual impact?
     → Good number plays:
       ratio framing ("1 in 3 budgets"), before/after contrast
       ("48 hours → 15 minutes"), hero isolation (688 as Hero-Stat-Box.Number)
     → FAIL if: raw statistics used without reframing where a play is possible
     → FIX: Apply techniques from 05a-slide-copywriting.md

  2. CHECK bullet consolidation
     → Maximum 5 bullets per bullet field, ~8-10 words per bullet
     → WHY: At presentation distance (3-5m), the audience scans bullets in ~3 seconds.
       Beyond 8-10 words, scanning breaks down — they start reading and stop listening.
       More than 5 bullets overwhelm the visual hierarchy.
     → FAIL if: bullets >5 per field or clearly too long to scan in one glance
     → FIX: Merge similar bullets, cut weakest, tighten wording

  2b. CHECK layout-specific word density (HARD GATES — count the words)
     → is-does-means slides:
       IS-Box Text: COUNT words. FAIL if >15. Must read like a conference badge tagline (noun phrase, no period).
       DOES-Box Text: COUNT words. FAIL if >20. Must read like a McKinsey "so what" bullet (`+` notation or action phrase with metric).
       MEANS-Box Text: COUNT words. FAIL if >15. Must read like a résumé skills line (stack notation, no conjunctions).
     → stat-card-with-context slides:
       Context-Box Bullets: COUNT words per bullet. FAIL if any >10. Must read like dashboard KPI labels.
     → four-quadrants (text-card) slides:
       Bullets: COUNT words per bullet. FAIL if any >10. McKinsey slide bullet density.
     → two-columns-equal slides:
       Column Bullets: COUNT words per bullet. FAIL if any >10.
     → ALL layouts:
       Bottom-Banner Text: COUNT words. FAIL if >12. Billboard tagline brevity.
     → WHY these limits: each box/bullet has a physical size (0.9" for IDM, 4.2×1.5" for quadrants).
       At presentation font sizes, exceeding the word budget forces font shrinking to illegibility.
       The audience has ~3 seconds per slide — full sentences create a read-along competition
       where the presenter loses the room.
     → FIX: Compress using 05a-slide-copywriting.md techniques. Move overflow content to
       Speaker-Notes "WHAT YOU NEED TO KNOW" section — the detail is preserved, not deleted.

  3. CHECK for hedging language
     → Scan for: "might", "could", "potentially", "somewhat", "relatively",
       "it seems", "possibly"
     → Slides must make confident claims
     → FAIL if: hedging language in headlines or bullets
     → FIX: Replace with direct, assertive language

  4. CHECK headline length
     → A complete action title (claim + quantified consequence) naturally runs longer
       than a topic label — up to ~100 characters is acceptable when the headline
       delivers both the claim and the "so what." IS-DOES-MEANS slides may reach ~130
       characters. Only cut if the headline wraps to 3+ lines on-screen.
     → FAIL if: headline exceeds ~100 characters (~130 for IS-DOES-MEANS) without
       delivering proportionally more specificity
     → FIX: Cut redundant modifiers, replace clauses with numbers, use symbols (€ not EUR)

  5. CHECK speaker notes completeness (generated in Step 7c)
     → Every content slide needs Speaker-Notes with BOTH sections:
       EN: ">> WHAT YOU SAY" + ">> WHAT YOU NEED TO KNOW"
       DE: ">> WAS SIE SAGEN" + ">> WAS SIE WISSEN MÜSSEN"
     → Target: 200-400 words per slide.
       WHY: Notes under ~150 words lack the depth needed for confident delivery and
       Q&A handling. Above ~450, they become a teleprompter the presenter reads rather
       than internalizes. The goal is coaching, not a script.
     → CHECK [Energy] tag present as first element in "WHAT YOU SAY" on every content slide
     → CHECK Q&A depth: all relevant stakeholder objections covered per slide (Rich mode: 3-5 items)
     → FAIL if: speaker notes missing or only one section present
     → FAIL if: word count below 150 (notes are too thin for effective presenter coaching)
     → FAIL if: [Energy] tag missing on any content slide
     → FIX: Regenerate using 08c-presenter-prep.md sub-step 3 rules
```

### Pass Criteria

Number plays applied. Bullets ≤5 per field, ~8-10 words each. IS/DOES/MEANS text fits in 0.9" boxes (~15/20/15 words, phrase notation). No hedging. Headlines ≤~100 chars (~130 for IS-DOES-MEANS), with complete action titles that pass the title-banner test. Speaker notes with both sections on all content slides, 200-400 words each, with [Energy] arc-position coaching and comprehensive Q&A prep.

---

## Layer 4: Presentation Logic

Verify the deck structure follows presentation best practices.

### Reasoning Approach

```text
REASON through presentation logic for the entire deck:

  1. CHECK bookend enforcement
     → First slide MUST be title-slide
     → Last slide MUST be closing-slide
     → FAIL if: deck opens with content or ends with non-closing slide
     → FIX: Add or move bookend slides

  2. CHECK slide count
     → Minimum: 5 slides (title + 3 content + closing)
     → Maximum: max_slides parameter (default 15)
     → Count EXCLUDES internal prep slides (Slide 2/3)
     → FAIL if: outside range
     → FIX: Consolidate (too many) or expand (too few)

  3. CHECK layout variety
     → ASK: "Are all content slides the same layout?"
     → WHY: Layout repetition signals "same type of information" to the audience's
       visual system. After three identical layouts, they habituate and stop scanning.
       Varying layouts re-activates attention by signaling "this is different."
     → A good deck uses ≥3 different layout types
     → FAIL if: all content slides use two-columns-equal (common fallback overuse)
     → FIX: Re-evaluate — stat-heavy → stat-card, process → timeline-steps,
       comparison → two-columns-equal, capability → is-does-means

  4. CHECK story arc flow
     → Expected emotional trajectory:
       tension builds (problem/urgency) → release (solution/proof) → momentum (CTA)
     → FAIL if: solution appears before any problem/evidence slide
     → FAIL if: proof appears before the solution it proves
     → FIX: Reorder to follow arc flow from Step 3

  5. CHECK internal prep slides
     → Methodology slide (Slide 2) present after Slide 1? (always required)
       → Uses Layout: process-flow with Diagram (Mermaid pipeline) and Detail-Grid?
       → Detail-Grid has 3-4 key concepts per pipeline node?
       → PEAK/RELEASE pacing guide present in Speaker-Notes?
     → Buying Center slide (Slide 3) present after Slide 2? (only if Rich audience mode)
       → Uses Layout: four-quadrants (text-card mode)?
       → Each quadrant has Label (role), Sublabel (title), Bullets (lead-with + key messages)?
     → Both have Bottom-Banner with INTERNAL warning?
     → Placed AFTER Slide 1 (title) and BEFORE first content slide?
     → FAIL if: missing, mispositioned, missing INTERNAL Bottom-Banner, or wrong layout
     → FIX: Generate using 08c-presenter-prep.md rules

  6. CHECK references slide position
     → References slide present AFTER closing-slide (last slide in deck)?
     → FAIL if: references slide missing or mispositioned
     → FIX: Generate using 08b-references-slide.md rules

  7. CHECK solution overview slide (why-change arc only)
     → Solution overview slide present BEFORE the first Power Position (is-does-means) slide?
     → Uses Layout: two-columns-equal (or similar text layout)?
     → Content extracted from 03-why-you/narrative.md Executive Summary (not Power Positions)?
     → FAIL if: Power Position slides appear without a preceding solution overview
     → FIX: Extract solution concept from 03-why-you Executive Summary and generate
       overview slide with two-columns-equal layout (What We Propose | How It Maps to Needs)
```

### Pass Criteria

Bookends enforced. Slide count in range. Layout variety ≥3 types. Arc flow logical. Internal prep slides and references slide correctly positioned. Solution overview precedes Power Positions (why-change arc).

---

## Layer 5: Content Integrity

Verify source content is faithfully represented without loss.

### Reasoning Approach

```text
REASON through content integrity against the source narrative:

  1. CHECK section coverage
     → Is every major narrative section (from Step 3c role mapping)
       represented by at least one slide?
     → FAIL if: an entire narrative section has no corresponding slide
     → FIX: Add a slide or merge the section's key content into an existing slide

  2. CHECK statistics coverage
     → Are all high-confidence statistics from the source included?
     → Focus on: hero numbers, percentages, monetary values, comparisons
     → FAIL if: a prominent statistic is completely absent
     → FIX: Add to existing slide (Context-Box, Sublabel) or create a new slide

  3. CHECK Power Positions coverage (why-change arc only)
     → Are all Power Positions from power-positions.md represented?
     → Each Power Position typically maps to is-does-means or two-columns-equal
     → FAIL if: a Power Position has no slide
     → FIX: Add the missing Power Position slide

  3b. CHECK IS/DOES/MEANS semantic correctness (why-change arc only)
     → For each is-does-means slide:
       IS-Box: describes what the SOLUTION is (positioning statement)?
         FAIL if: IS-Box describes the PROBLEM or current state
       DOES-Box: states capabilities with measurable outcomes?
         FAIL if: DOES-Box restates what the solution IS without outcomes
       MEANS-Box: provides technology/methodology proof?
         FAIL if: MEANS-Box contains business impact metrics instead of technical proof
     → FAIL if: any box has wrong semantic content
     → FIX: Apply transformation table from 03-story-arc-analysis.md

  3c. CHECK IS/DOES/MEANS label localization
     → For each is-does-means slide:
       If language=de: Labels must be IST/MACHT/BEDEUTET
       If language=en: Labels must be IS/DOES/MEANS
     → FAIL if: English labels in German deck or vice versa
     → FIX: Replace labels per SKILL.md "IS/DOES/MEANS label localization" table

  4. CHECK citation preservation
     → Inline citations present in body text fields as SUPERSCRIPT?
       (Context-Box Bullets, Column Bullets, IS/DOES/MEANS Box Text, Option Features)
     → Using renumbered `<sup>[N](url)</sup>` format — NOT bare `[N](url)` or original `[P1-1]`?
     → Citation markers ABSENT from exclusion zones?
       (Headlines, Bottom-Banner, Hero-Stat-Box Number/Label/Sublabel,
        Step Labels, Step Numbers)
     → Slides with cited claims have a Source field?
     → Speaker-Notes "WHAT YOU NEED TO KNOW" section includes regular `[N](url)` links (NO superscript in notes)?
     → FAIL if: citations lost, wrong format (missing <sup>), in exclusion zones, or Source missing
     → FIX: Re-apply using renumber map from Step 2, wrapping body text citations in `<sup>...</sup>`

  5. CHECK references slide completeness
     → Does the references slide contain ALL citations from the renumber map?
     → Are citation numbers sequential and consistent with inline citations?
     → FAIL if: any reference missing or numbering inconsistent
     → FIX: Regenerate using 08b-references-slide.md

  6. CHECK character preservation
     → German characters preserved (ä, ö, ü, ß, Ä, Ö, Ü)?
     → Special characters in URLs preserved?
     → FAIL if: encoding corruption detected
     → FIX: Restore original characters from source
```

### Pass Criteria

All sections represented. Statistics preserved. Citations intact (inline + Source + References slide) in correct format and correct zones. Characters preserved.

---

## Self-Validation Checklist

Before marking Step 8 complete, verify ALL items. Mark each ✅ or ❌:

### Layer 1: Schema Compliance
- [ ] All slides use valid layout types from pptx-layouts.md
- [ ] All required fields present for each layout type
- [ ] No unknown fields present
- [ ] ZERO color fields (Background, Text-Color, Icon-Color must be absent)
- [ ] YAML parses without errors
- [ ] Frontmatter complete and valid (version "4.0", theme_path ends in /theme.md)
- [ ] PPTX Rendering Requirements section present (localized, between governing thought and Slide 1)

### Layer 2: Message Quality
- [ ] Every slide heading is an assertion (not a topic label)
- [ ] Title-banner test passed: every headline is complete without the banner (banner adds proof, not "so what")
- [ ] No methodology jargon in client-facing slide titles or body (Power Position, Why You, etc.)
- [ ] Slide titles alone tell the complete story (title-only test)
- [ ] No overlapping or missing arguments (MECE)
- [ ] Hero numbers isolated (one dominant number per stat-card)
- [ ] Pyramid structure visible: governing thought → arguments → evidence

### Layer 3: Copywriting Quality
- [ ] Number plays applied to statistics
- [ ] Bullets ≤5 per field, ≤10 words each (scannable in one glance)
- [ ] IS-Box ≤15 words (badge tagline), DOES-Box ≤20 words (McKinsey bullet + metric), MEANS-Box ≤15 words (skills stack)
- [ ] Context-Box bullets ≤10 words each (KPI label density)
- [ ] Four-quadrant text-card bullets ≤10 words each
- [ ] All column bullets ≤10 words each (two-columns-equal)
- [ ] Bottom-Banner ≤12 words on all layouts (billboard brevity)
- [ ] No hedging language in headlines or bullets
- [ ] All headlines ≤~100 chars (~130 for IS-DOES-MEANS) — specific + complete action titles
- [ ] Speaker notes present with both sections on all content slides (200-400 words each)
- [ ] [Energy] tag present as first element in "WHAT YOU SAY" on every content slide
- [ ] Q&A covers all relevant stakeholder objections per slide (Rich mode: 3-5 items)

### Layer 4: Presentation Logic
- [ ] Slide 1 is title-slide, final slide is closing-slide
- [ ] Slide count between 5 and max_slides
- [ ] Layout variety (≥3 different layout types)
- [ ] Story arc flow: tension → release → momentum
- [ ] Methodology slide (Slide 2) present after Slide 1 with process-flow layout, Diagram, Detail-Grid, and INTERNAL Bottom-Banner
- [ ] Buying Center slide (Slide 3) present if Rich audience mode, with four-quadrants text-card layout and INTERNAL Bottom-Banner
- [ ] References slide after closing-slide (last slide in deck)
- [ ] Solution overview slide present before first Power Position slide (why-change arc only)

### Layer 5: Content Integrity
- [ ] All major narrative sections represented by slides
- [ ] High-confidence statistics included
- [ ] Power Positions represented (why-change arc only)
- [ ] IS/DOES/MEANS semantic correctness: IS=positioning, DOES=capabilities+outcomes, MEANS=technical proof
- [ ] IS/DOES/MEANS labels localized (de: IST/MACHT/BEDEUTET, en: IS/DOES/MEANS)
- [ ] Solution overview slide uses content from 03-why-you Executive Summary (why-change arc only)
- [ ] Inline citations in body text using superscript `<sup>[N](url)</sup>` format (NOT bare `[N](url)`)
- [ ] Speaker-Notes citations use regular `[N](url)` format (NO superscript in notes)
- [ ] Citations ABSENT from exclusion zones (headlines, banners, hero stat fields)
- [ ] Source field present on slides with URL-bearing citations
- [ ] References slide contains all citations from renumber map
- [ ] German characters and special URL characters preserved

**ANY ❌: STOP. Fix the failing check before proceeding to Step 9.**

---

## Validation Report Format

After completing all layers, record results:

```yaml
validation_report:
  layers:
    schema_compliance: {pass/fail}
    message_quality: {pass/fail}
    copywriting_quality: {pass/fail}
    presentation_logic: {pass/fail}
    content_integrity: {pass/fail}
  slides_validated: {count}
  issues_found: {count}
  issues_fixed: {count}
```
