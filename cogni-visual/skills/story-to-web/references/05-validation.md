# Web Brief Validation

## Purpose

Define the four-layer validation framework for web-brief.md files. Every brief must pass all four layers before being written to output.

**Validation philosophy:** Do not mechanically tick boxes. For each layer, first reason about what is most likely to go wrong given this specific brief, then check systematically. A passing validation means the renderer will produce a visually coherent, on-message web page without manual correction.

---

## Severity Levels

Every check has a severity classification that determines how to handle failures:

| Severity | Symbol | Meaning | Action Required |
|----------|--------|---------|-----------------|
| **CRITICAL** | `[C]` | Brief will fail to render, produce broken layout, or display wrong content | Must fix before writing. Stop and repair immediately. |
| **WARNING** | `[W]` | Brief will render but with degraded quality, inconsistent visuals, or weak messaging | Should fix. Only skip if there is a clear justification for the deviation. |
| **INFO** | `[I]` | Opportunity to improve. Brief is functional without the fix. | Fix if time allows. Note in validation report for future improvement. |

---

## Validation Protocol

For each layer, follow this three-phase process:

### Phase A: Anticipate (think before checking)

Before running any checks, reason about the brief you are validating:
- What is unusual about this brief (arc type, language, section count, content domain)?
- Given those characteristics, which checks are most likely to fail?
- Are there edge cases the standard checklist might miss?

### Phase B: Check (systematic verification)

Run every check in the layer. For each check that fails:
1. Record the severity level
2. Record what was expected vs. what was found
3. Record the specific fix needed

### Phase C: Repair (fix before proceeding)

- Fix all CRITICAL failures immediately
- Fix all WARNING failures unless you document a justification
- Note all INFO items in the validation report
- Re-run Phase B on any repaired items to confirm the fix

---

## Layer 1: Schema Compliance

**Goal:** Verify the brief structure matches the expected format so the renderer can parse it without errors.

**Think first:** Schema failures are the most common cause of renderer crashes. Before checking, consider: Does this brief have unusual section types? Are there optional fields that might be missing? Is the frontmatter complete?

### Frontmatter Checks

- `[C]` `type` field is `"web-brief"`
  - If this fails, the renderer will not recognize the file. Fix: set `type: web-brief`
- `[C]` `version` field is `"1.0"`
  - If this fails, the renderer may apply wrong parsing rules. Fix: set `version: "1.0"`
- `[W]` `theme` field references a valid theme ID
  - If this fails, the renderer will use fallback colors (generic blue). Fix: verify theme ID exists in `/cogni-workplace/themes/{id}/`
- `[C]` `theme_path` points to an existing theme.md
  - If this fails, the renderer cannot extract design tokens and all colors resolve to black. Fix: set path to `/cogni-workplace/themes/{theme_id}/theme.md` and verify the file exists
- `[W]` `language` is `"en"` or `"de"`
  - If this fails, number formatting and CTA copy may be wrong. Fix: set to the language matching the narrative content
- `[W]` `governing_thought` is a single sentence
  - If this fails, the generation metadata will be incomplete. Fix: distill to one sentence with a verb
- `[W]` `arc_type` is a valid arc type (`why-change`, `problem-solution`, `journey`, `argument`, `report`)
  - If this fails, the metadata is inaccurate. Fix: re-analyze the narrative and assign the correct arc type
- `[W]` `style_guide` is a non-empty string
  - If this fails, the renderer cannot load visual direction. Fix: set to the style guide name selected in Step 3
- `[W]` `conversion_goal` is a valid goal (`consultation`, `demo`, `download`, `trial`, `contact`, `calculate`)
  - If this fails, CTA copy will not match the goal. Fix: set to one of the six valid values
- `[C]` `sections` count matches actual section count
  - If this fails, the renderer may skip or duplicate sections. Fix: count the `## Section N:` headings and update the frontmatter
- `[I]` `confidence_score` is 0.0-1.0
  - If this fails, the metadata is inaccurate but rendering is unaffected. Fix: estimate confidence as a float

### Section Checks

For each section, verify:

- `[C]` Has `type` (one of: `hero`, `problem-statement`, `stat-row`, `feature-alternating`, `feature-grid`, `testimonial`, `comparison`, `timeline`, `cta`, `text-block`)
  - If this fails, the renderer does not know which layout template to use. Fix: assign the correct type based on arc role and content
- `[C]` Has `section_theme` (one of: `dark`, `light`, `light-alt`, `accent`)
  - If this fails, the renderer cannot determine background/text colors. Fix: assign based on the theme alternation rules in `02-section-architecture.md`
- `[W]` Has `arc_role` (valid role: `hook`, `problem`, `urgency`, `evidence`, `solution`, `proof`, `roadmap`, `call-to-action`)
  - If this fails, the generation metadata is incomplete. Fix: assign the role that matches this section's narrative function
- `[C]` Has `headline` (string, non-empty)
  - If this fails, the section will render with a blank headline. Fix: write an assertion headline for the section
- `[C]` Type-specific required fields present (see table below)
  - If this fails, the renderer will produce an incomplete section layout. Fix: add the missing fields per the table
- `[C]` No color fields present (`fill`, `color`, `background`, `textColor`)
  - If this fails, hardcoded colors will conflict with theme tokens. Fix: remove all color fields; the renderer decides colors from theme + style guide

### Header/Footer Checks

- `[C]` Header has `logo_text`
  - If this fails, the header renders with blank space. Fix: set to the provider name
- `[W]` Header has `cta_text`
  - If this fails, the header CTA button is blank. Fix: set to the conversion goal CTA text
- `[C]` Footer has `company_name`
  - If this fails, the footer renders with blank space. Fix: set to the provider name

### Section Type-Specific Required Fields

| Type | Required Fields | Optional Fields | Common Failure |
|------|----------------|----------------|----------------|
| `hero` | `headline`, `subline` | `section_label`, `cta_text`, `cta_url`, `image_prompt` | Missing `subline` (just a headline is not enough for hero). Note: `cta_text` is strongly recommended — without it the hero has no call-to-action button. |
| `problem-statement` | `headline`, (`body` OR `bullets`) | `section_label`, `stat_number`, `stat_label`, `stat_context`, `image_prompt`, `source` | Having neither `body` nor `bullets` |
| `stat-row` | `headline`, `stats` (3-4 items with `number` + `label`) | `section_label`, stats[].`icon` | Fewer than 3 stats, or units in the `number` field |
| `feature-alternating` | `headline`, `body`, `image_prompt` | `section_label`, `source` | Missing `image_prompt` (renderer needs it for G() call) |
| `feature-grid` | `headline`, `cards` (4-6 items with `card_headline` + `card_body`) | `section_label`, `subline`, cards[].`icon` | Fewer than 4 cards, or missing `card_body` on a card |
| `testimonial` | `quote`, `author_name` | `author_title`, `author_company` | Missing `author_name` (anonymous quotes lack credibility) |
| `comparison` | `headline`, `left_label`, `left_headline`, `left_bullets`, `right_label`, `right_headline`, `right_bullets` | `section_label` | Missing one side of the comparison (left or right incomplete) |
| `timeline` | `headline`, `steps` (3-5 items with `label` + `description`) | `section_label`, steps[].`duration` | Fewer than 3 steps, or steps missing `description` |
| `cta` | `headline`, `cta_text` | `subline` | Missing `cta_text` (button has no label) |
| `text-block` | `headline` | `section_label`, `body` | (rarely fails) |

---

## Layer 2: Message Quality

**Goal:** Verify that section content communicates effectively and the reader receives a clear, compelling message at every scroll position.

**Think first:** Message quality failures are subtle. The brief may be structurally valid but the messaging weak. Before checking, consider: Are the headlines actually saying something (assertion) or just labeling topics? Do the number plays create emotional impact? Is the body text supporting or just restating the headline?

### Headline Quality

- `[C]` Every headline is an assertion (contains a verb)
  - **How to detect:** Read the headline. If you can put "About:" in front of it and it still makes sense, it is a topic label, not an assertion.
  - If this fails, the section has no clear message. Fix: rewrite as `{subject} + {verb} + {object/benefit}`. Example: "Overview of Predictive Maintenance" becomes "Predictive Maintenance eliminates unplanned downtime".
- `[C]` No topic labels ("Overview", "Summary", "Uberblick", "Zusammenfassung", "Introduction", "Einleitung", "Fazit")
  - If this fails, the reader sees a chapter title instead of a message. Fix: replace with the section's core assertion.
- `[W]` Headlines are unique (no duplicates or near-duplicates)
  - **How to detect:** Compare all headlines. Two headlines making the same claim in different words are near-duplicates.
  - If this fails, the narrative feels repetitive. Fix: differentiate by emphasizing different aspects of the argument.
- `[C]` Hero headline is transformation-first (max 10 words)
  - **How to detect:** Does the headline describe what changes for the reader? Count words.
  - If this fails, the hero lacks impact. Fix: lead with the transformation verb. Example: "Our Platform for Manufacturing" becomes "Transform Your Factory Floor into a Smart Production Line".
- `[W]` Section headlines are under 70 characters
  - If this fails, headlines will wrap awkwardly on screen. Fix: tighten by removing unnecessary words.
- `[W]` CTA headline is imperative (starts with an action verb: "Start", "Discover", "Starten", "Entdecken")
  - If this fails, the CTA feels passive. Fix: rewrite as a direct command to the reader.

### Body Text Quality

- `[W]` Body text supports the headline's claim (not just restates it)
  - **How to detect:** Read the headline, then the body. Does the body add evidence, detail, or context the headline does not contain? If the body says the same thing as the headline in more words, it fails.
  - If this fails, the section feels thin. Fix: add a specific fact, statistic, or mechanism that supports the headline's assertion.
- `[C]` No placeholder text ("Lorem ipsum", "TODO", "TBD", "[insert here]", "xxx")
  - If this fails, placeholder text will render on screen. Fix: write actual copy or remove the field.
- `[W]` Bullet items are parallel in structure (all start with the same part of speech)
  - **How to detect:** Read the first word of each bullet. Are they all nouns, all verbs, or mixed?
  - If this fails, the bullets feel disorganized. Fix: rewrite so all bullets start with the same pattern (e.g., all noun phrases or all verb phrases).
- `[W]` No bullet exceeds 8 words
  - If this fails, bullets lose scannability. Fix: split long bullets into two or tighten the wording.

### Number Play Quality (where present)

- `[C]` Stat numbers are isolated (no units in the `number` field)
  - **How to detect:** The `number` field should contain only digits, commas/dots, `%`, or ratio notation like `1:5`. No words like "days", "Tage", "EUR".
  - If this fails, the stat card renders with units inside the large number, breaking the visual hierarchy. Fix: move units to the `label` field. Example: `number: "23 Tage"` becomes `number: "23"`, `label: "Tage Stillstand/Jahr"`.
- `[W]` Labels provide unit context (the label field is not empty or generic)
  - If this fails, the number has no meaning. Fix: write a label that gives the number unit and scope context.
- `[I]` Numbers use the most emotionally impactful framing
  - **How to detect:** Consider alternative framings. Would a ratio be more visceral than a percentage? Would a total be more shocking than a per-unit number?
  - If this fails, the number play is functional but not optimal. Fix: try ratio framing, hero number isolation, or multiplier techniques from `03-section-copywriting.md`.

---

## Layer 3: Visual Coherence

**Goal:** Verify that the brief will produce a visually coherent web page with proper rhythm, contrast, and image consistency.

**Think first:** Visual coherence failures produce pages that look amateurish or confusing. Before checking, consider: Does the section theme alternation create a clear light-dark rhythm? Are there too many consecutive feature-alternating sections? Do the image prompts describe a consistent visual world?

### Section Count and Balance

- `[W]` 6-10 sections (including hero and CTA)
  - If this fails with fewer than 6, the page feels too thin. Fix: split the richest content section into two, or add a section for an arc role that is underrepresented.
  - If this fails with more than 10, the page is too long. Fix: merge the least important sections by arc role priority (keep: hero > cta > problem > solution > proof > urgency > roadmap).
- `[C]` First section is `hero` with `section_theme: dark`
  - If this fails, the page has no visual entry point. Fix: move or create the hero section as section 1 with dark theme.
- `[C]` Last content section is `cta` with `section_theme: accent`
  - If this fails, the page has no call to action. Fix: move or create the CTA section as the final content section with accent theme.
- `[W]` Section types have variety (no three consecutive sections of the same type)
  - **How to detect:** List the section types in order. Look for runs of 3+ identical types.
  - If this fails, the page feels monotonous. Fix: replace the middle section in a run with an alternate type (e.g., swap a third feature-alternating for a stat-row or comparison).

### Theme Alternation

- `[C]` No two adjacent non-dark sections have the same `section_theme`
  - **How to detect:** List section themes in order. Adjacent `light, light` or `light-alt, light-alt` is a failure. Adjacent `dark, light, dark` is acceptable because the dark sections separate them.
  - If this fails, adjacent sections will merge visually with no contrast boundary. Fix: alternate between `light` and `light-alt` for non-dark sections.
- `[W]` Dark sections are used for hero, stat-row, testimonial
  - If this fails, dark sections appear in unexpected places. Fix: assign `dark` only to hero, stat-row, and testimonial. Use `light`/`light-alt` for all other content sections.
- `[W]` Light and light-alt alternate for remaining sections
  - If this fails, the visual rhythm is uneven. Fix: walk through the non-dark, non-accent sections and alternate `light` / `light-alt`.

### Image Consistency

- `[W]` All image prompts share a consistent style suffix
  - **How to detect:** Extract the `Style:` line from each image prompt. They should all match.
  - If this fails, images will have inconsistent aesthetics. Fix: standardize the `Style:` suffix across all prompts to match the style guide.
- `[C]` All image prompts include "No text, no people"
  - If this fails, AI may generate text overlays or human figures that conflict with the layout. Fix: append "No text, no people." to every image prompt.
- `[W]` Image dimensions match section type requirements
  - Hero: wide panoramic (16:9 minimum). Feature-alternating: square or 16:10 (560x400). Refer to `04-image-prompts.md`.
  - If this fails, images will be cropped or stretched. Fix: add dimension guidance to the prompt.
- `[I]` Hero has a wide-format image prompt (if `image_prompt` present)
  - If this fails, the hero background may not fill the full width. Fix: add "wide panoramic shot" and "16:9 aspect ratio" to the prompt.
- `[W]` Feature images match their section's subject matter
  - **How to detect:** Read the section headline and body, then the image prompt. Does the image illustrate the section's topic?
  - If this fails, there is a content-image mismatch. Fix: rewrite the image prompt to focus on the section's specific subject.

### Feature-Alternating Position

- `[C]` Odd-positioned feature-alternating sections (1st, 3rd, etc. among feature-alternating instances) have `position: odd`
- `[C]` Even-positioned feature-alternating sections (2nd, 4th, etc.) have `position: even`
  - **How to detect:** Number the feature-alternating sections by their order among their type only (not overall section number). The first feature-alternating is odd, second is even, and so on.
  - If this fails, all feature images appear on the same side, creating visual monotony. Fix: assign `position: odd` to 1st, 3rd instances and `position: even` to 2nd, 4th instances.

---

## Layer 4: Content Integrity

**Goal:** Verify that the brief faithfully represents the source narrative without inventing facts, losing important arguments, or mixing languages.

**Think first:** Content integrity failures are the hardest to detect because they require comparing the brief against the original narrative. Before checking, consider: Did the transformation drop any major argument from the narrative? Are all statistics actually present in the source? Is the language consistent throughout?

### Completeness

- `[W]` Every major narrative argument has a corresponding section
  - **How to detect:** List the narrative's 3-5 main arguments. For each, identify which section addresses it. If any argument has no section, it fails.
  - If this fails, the web page omits an important part of the story. Fix: add a section for the missing argument, or integrate it into an existing section's body text.
- `[W]` No important evidence or statistics are missing
  - **How to detect:** List the narrative's key statistics. For each, check if it appears in a section (as a stat, in body text, or in bullets).
  - If this fails, the proof is weaker than the narrative warrants. Fix: add the missing statistic to the most relevant section.
- `[W]` Governing thought is supported by the section content
  - **How to detect:** Read the governing thought. Then read all section headlines in order. Do they build a logical argument that leads to the governing thought's conclusion?
  - If this fails, the page's narrative arc is broken. Fix: adjust section order or headlines so the argument builds toward the governing thought.
- `[I]` Arc type is correctly identified
  - If this fails, the section sequence template may be suboptimal but rendering is unaffected. Fix: re-assess the arc type against the patterns in `02-section-architecture.md`.

### Language Consistency

- `[C]` All text is in the specified language (en or de)
  - **How to detect:** Scan all headlines, body text, bullets, labels, and CTA text. Any text in the wrong language fails.
  - If this fails, the page mixes languages, confusing the reader. Fix: translate the offending text to match the `language` field.
- `[W]` German umlauts preserved where possible (a/o/u not ae/oe/ue)
  - If this fails, the text looks informal or machine-generated. Fix: replace ae/oe/ue with proper umlauts where the brief system supports them.
- `[W]` Number formatting matches language (EN: `2,661` / DE: `2.661`)
  - **How to detect:** Check stat numbers and any numbers in body text. English uses commas for thousands; German uses dots.
  - If this fails, numbers look foreign to the target audience. Fix: reformat numbers to match the language convention.
- `[C]` No mixed-language content within a section
  - **How to detect:** Read each section fully. English CTA text in an otherwise German brief is a common failure.
  - If this fails, the section feels broken. Fix: translate all text within the section to the specified language.

### Source Preservation

- `[I]` Citations with URLs preserved in section `source` fields
  - If this fails, the brief loses provenance but renders fine. Fix: add `source:` fields with markdown links where the narrative cites external sources.
- `[C]` No URLs invented or fabricated
  - **How to detect:** For each URL in a `source` field, verify it matches a URL from the original narrative. If a URL appears that was not in the source, it fails.
  - If this fails, the brief contains fabricated references, which is a credibility risk. Fix: remove the fabricated URL or replace with the actual source URL from the narrative.
- `[W]` Key statistics traceable to source material
  - **How to detect:** For each major statistic (stat-row numbers, problem-statement numbers), verify it appears in the original narrative.
  - If this fails, the brief may contain invented data. Fix: correct the statistic to match the source, or remove it if no source exists.

---

## Worked Example: Detecting and Fixing Failures

The following example demonstrates the validation process on a brief excerpt with intentional errors. Each failure is detected, classified, and fixed.

### Example Brief Excerpt (with errors)

```yaml
---
type: web-brief
version: "1.0"
theme: smarter-service
theme_path: "/cogni-workplace/themes/smarter-service/theme.md"
language: "de"
governing_thought: "Predictive Maintenance revolutioniert die Fertigung."
arc_type: "why-change"
style_guide: "Corporate Tech"
conversion_goal: "consultation"
sections: 5
confidence_score: 0.85
---
```

**Section 1:**
```yaml
type: hero
section_theme: dark
arc_role: hook
headline: "Predictive Maintenance"
subline: "Die Zukunft der Fertigung beginnt jetzt."
cta_text: "Get Started"
```

**Section 2:**
```yaml
type: problem-statement
section_theme: light
arc_role: problem
headline: "Das Problem mit Stillstand"
body: "Fabriken verlieren viel Geld durch ungeplante Ausfalle."
stat_number: "23 Tage"
stat_label: ""
```

**Section 3:**
```yaml
type: feature-alternating
section_theme: light
arc_role: solution
position: odd
headline: "Sensoren erkennen Verschleiss fruhzeitig"
body: "Unsere Sensoren messen den Maschinenzustand in Echtzeit."
```

**Section 4:**
```yaml
type: feature-alternating
section_theme: light-alt
arc_role: solution
position: odd
headline: "KI lernt aus Ihren Daten"
body: "Machine Learning models train on your historical data for maximum accuracy."
image_prompt: "Abstract data flow visualization, neural networks"
```

**Section 5:**
```yaml
type: cta
section_theme: accent
arc_role: call-to-action
headline: "Kontaktieren Sie uns"
cta_text: "Beratung anfragen"
```

### Validation Walkthrough

#### Layer 1: Schema Compliance

**Think first:** This brief has 5 sections, which is below the 6-section minimum. The frontmatter says `sections: 5` — that matches the actual count, so the count field is consistent. But the missing section will surface in Layer 3.

| # | Check | Severity | Result | Finding | Fix |
|---|-------|----------|--------|---------|-----|
| 1 | Section 1 hero required fields | `[C]` | PASS | `headline` and `subline` present | -- |
| 2 | Section 3 feature-alternating required fields | `[C]` | **FAIL** | Missing `image_prompt` | Add an image prompt describing sensor hardware on CNC machinery, matching the style suffix |
| 3 | No color fields | `[C]` | PASS | No color fields found | -- |
| 4 | Header/footer present | `[C]` | **FAIL** | No header or footer blocks | Add header with `logo_text` and `cta_text`, footer with `company_name` and `copyright` |

#### Layer 2: Message Quality

**Think first:** The hero headline "Predictive Maintenance" has no verb — it is a topic label. The problem-statement headline also looks like a topic label. The stat number has units embedded.

| # | Check | Severity | Result | Finding | Fix |
|---|-------|----------|--------|---------|-----|
| 1 | Hero headline is assertion | `[C]` | **FAIL** | "Predictive Maintenance" is a topic label, not an assertion. No verb. | Rewrite: "Predictive Maintenance macht Ihre Fertigung unaufhaltsam" |
| 2 | Hero headline max 10 words | `[C]` | PASS | 2 words (after fix: 7 words) | -- |
| 3 | Section 2 headline is assertion | `[C]` | **FAIL** | "Das Problem mit Stillstand" is a topic label. You can say "About: Das Problem mit Stillstand" and it still works. | Rewrite: "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit" |
| 4 | Stat number isolated | `[C]` | **FAIL** | `stat_number: "23 Tage"` — units embedded in number | Change to `stat_number: "23"`, `stat_label: "Tage Stillstand/Jahr"` |
| 5 | Stat label not empty | `[W]` | **FAIL** | `stat_label: ""` | Set to "Tage Stillstand pro Anlage/Jahr" |
| 6 | CTA headline imperative | `[W]` | **FAIL** | "Kontaktieren Sie uns" is generic. | Rewrite: "Starten Sie Ihren Predictive-Maintenance-Piloten" |

#### Layer 3: Visual Coherence

**Think first:** With only 5 sections, the page will feel short. The two feature-alternating sections both have `position: odd`, which means both images will appear on the left.

| # | Check | Severity | Result | Finding | Fix |
|---|-------|----------|--------|---------|-----|
| 1 | 6-10 sections | `[W]` | **FAIL** | Only 5 sections. Page lacks urgency/proof. | Add a stat-row (urgency) after problem-statement and a comparison (proof) before CTA. Update `sections:` to 7. |
| 2 | Feature-alternating positions | `[C]` | **FAIL** | Both feature-alternating sections have `position: odd` | Section 4 (2nd feature-alternating instance) should be `position: even` |
| 3 | Image prompt consistency | `[W]` | **FAIL** | Section 4's image prompt lacks "No text, no people" and has no `Style:` suffix | Add ". No text, no people. Style: professional stock photography, corporate technology." |

#### Layer 4: Content Integrity

**Think first:** Section 4 has English body text in an otherwise German brief. The CTA text mixes languages ("Get Started" in Section 1 is English).

| # | Check | Severity | Result | Finding | Fix |
|---|-------|----------|--------|---------|-----|
| 1 | All text in specified language | `[C]` | **FAIL** | Section 1 `cta_text: "Get Started"` is English in a `de` brief | Change to "Jetzt Potenzial berechnen" |
| 2 | No mixed language in section | `[C]` | **FAIL** | Section 4 body is entirely English: "Machine Learning models train on..." | Translate to German: "Unsere Modelle lernen aus Ihren eigenen Maschinen- und Wartungsdaten." |
| 3 | No fabricated URLs | `[C]` | PASS | No source URLs present | -- |

### Summary of Fixes Required

**CRITICAL (must fix):** 8 issues
- Hero headline is a topic label (rewrite as assertion)
- Problem-statement headline is a topic label (rewrite as assertion)
- Stat number has embedded units (separate number and label)
- Feature-alternating Section 3 missing image_prompt (add prompt)
- Feature-alternating positions both `odd` (fix Section 4 to `even`)
- English CTA text in German brief (translate)
- English body text in Section 4 (translate)
- Missing header and footer (add both)

**WARNING (should fix):** 4 issues
- Empty stat label (add descriptive label)
- CTA headline is generic (rewrite as specific imperative)
- Only 5 sections (add urgency + proof sections)
- Image prompt missing consistency elements (add suffix)

After applying all CRITICAL and WARNING fixes, re-run the full validation to confirm all layers pass.

---

## Validation Report Format

After completing all four layers, produce the validation report in this exact format:

```
## Validation Report

**Result:** {PASS | FAIL}

### Layer Summary

| Layer | Result | Critical | Warning | Info |
|-------|--------|----------|---------|------|
| 1. Schema Compliance | {PASS/FAIL} | {count} | {count} | {count} |
| 2. Message Quality | {PASS/FAIL} | {count} | {count} | {count} |
| 3. Visual Coherence | {PASS/FAIL} | {count} | {count} | {count} |
| 4. Content Integrity | {PASS/FAIL} | {count} | {count} | {count} |
| **Total** | | **{total_C}** | **{total_W}** | **{total_I}** |

### Issues Found

[Only include this section if there are failures]

| # | Layer | Severity | Check | Expected | Actual | Fix Applied |
|---|-------|----------|-------|----------|--------|-------------|
| 1 | Schema | [C] | ... | ... | ... | ... |

### Validation Line

Validation: Schema {pass/fail} | Messages {pass/fail} | Visual {pass/fail} | Integrity {pass/fail}
```

**Pass criteria:**
- A layer PASSES if it has zero CRITICAL failures after repair
- The overall validation PASSES if all four layers pass
- WARNING items that were not fixed must be documented with justification
- INFO items are noted but do not affect pass/fail

**Validation line** is the single-line summary used in the brief's generation metadata section:
```
**Validation:** Schema: pass | Messages: pass | Visual coherence: pass | Integrity: pass
```

---

## Validation Execution

Run validation after Step 7 (section copy complete) before writing the brief:

```
FOR each layer (1 through 4):
  Phase A: Reason about what is likely to fail for this specific brief
  Phase B: Run all checks systematically, recording severity and findings
  Phase C: Fix all CRITICAL issues, fix WARNING issues where possible

  IF any CRITICAL check still fails after repair:
    STOP — return to the responsible step and resolve before continuing

AFTER all four layers:
  Produce the validation report
  IF all layers PASS:
    Proceed to Step 8 (write brief)
  ELSE:
    Return to the earliest failing step and repair
```

If any layer fails after repair attempts, return to the responsible step and fix before writing the brief. Never write a brief with unresolved CRITICAL failures.
