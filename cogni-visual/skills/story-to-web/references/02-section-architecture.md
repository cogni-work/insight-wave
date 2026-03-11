# Section Architecture

## Purpose

Define how narratives decompose into web sections, map arc roles to section types, and enforce structural rules for visual rhythm and reader flow.

**How this reference is used:** This file is loaded at Step 2 (arc analysis) and Step 4 (section decomposition) of the story-to-web skill. At Step 2, use the Arc-to-Section Mapping to understand the target section sequence for the detected arc type. At Step 4, follow the Decomposition Process step by step to produce the ordered section list.

---

## Narrative Arc ID to Visual Arc Type Mapping

**Arc mapping:** See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for the complete arc_id → arc_type mapping table, arc element names with EN/DE translations, and the element-to-role assignment heuristic. The shared library is the single source of truth for all three visual skills.

### Arc Element Names as Section Labels

When `arc_definition_path` is provided and the arc definition file is loaded, use the element names as `section_label` values instead of generic role-based labels. This creates a stronger connection between the narrative structure and the visual output.

**Mapping logic:** Labels are assigned **content-source-first, role-based as fallback**. During decomposition, track which narrative H2 chapter each section's content originates from. If the chapter matches an arc element name, use that element as the label. Otherwise, fall back to role-based mapping. See `$CLAUDE_PLUGIN_ROOT/libraries/arc-taxonomy.md` for the full heuristic including chapter detection pseudocode.

**Example — `industry-transformation` arc (German narrative, 9 sections including bookends):**

Narrative chapters: `## Kräfte`, `## Reibung`, `## Evolution`, `## Führung`

| Section | Arc Role | Source Chapter | Method | Arc Element Label |
|---------|----------|---------------|--------|-------------------|
| S1 (hero) | hook | — | — | — |
| S2 | problem | Kräfte | content-source | "Kräfte" |
| S3 | urgency | (intro stats) | role-based fallback | "Kräfte" |
| S4 | solution | Evolution | content-source | "Evolution" |
| S5 | solution | Evolution | content-source | "Evolution" |
| S6 | proof | Evolution | content-source | "Evolution" |
| S7 | roadmap | Führung | content-source | "Führung" |
| S8 (cta) | call-to-action | — | — | — |

Note: S6 contains proof content (EBIT comparison) but that material was drawn from the "Evolution" chapter, so it gets label "Evolution" — not "Reibung" which pure role-based mapping would assign.

**Assignment priority:**
1. **Content-source:** Section content from chapter "X" → label = element matching "X"
2. **Role-based fallback:** No chapter match (intro content, synthesized) → map arc role to element by narrative function
3. **Generic fallback:** No `arc_elements` at all → use generic labels ("Das Problem", "Die Lösung", etc.)

---

## Arc-to-Section Mapping

Each story arc type produces a different section sequence. The section types map to arc roles:

| Arc Role | Primary Section Type | Alternate Section Types |
|----------|---------------------|----------------------|
| hook | `hero` | — |
| problem | `problem-statement` | `text-block` |
| urgency | `stat-row` | `comparison` |
| evidence | `stat-row`, `comparison` | `feature-grid` |
| solution | `feature-alternating` | `feature-grid` |
| proof | `comparison`, `testimonial` | `stat-row` |
| roadmap | `timeline` | `feature-grid` |
| call-to-action | `cta` | — |

### Arc Type Templates

**why-change (most common):**
```
hero (hook) → problem-statement → stat-row (urgency) → feature-alternating (solution) →
feature-alternating (solution) → comparison (proof) → timeline (roadmap) → cta
```

**problem-solution:**
```
hero (hook) → stat-row (problem) → problem-statement (urgency) →
feature-alternating (solution) → feature-grid (capabilities) → testimonial (proof) → cta
```

**journey:**
```
hero (hook) → text-block (context) → feature-alternating (stage 1) →
feature-alternating (stage 2) → feature-alternating (stage 3) → timeline (roadmap) → cta
```

**argument:**
```
hero (hook) → stat-row (evidence) → feature-grid (points) →
comparison (analysis) → text-block (synthesis) → cta
```

**report:**
```
hero (hook) → stat-row (key findings) → feature-grid (details) →
feature-alternating (insight 1) → feature-alternating (insight 2) → cta
```

---

## Decomposition Process

Decomposition is the core intelligence of this reference. Follow these steps sequentially, reasoning through each decision before committing. Do not skip steps or make assignments mechanically.

### Step 1: Identify Narrative Sections

Scan the narrative for section boundaries (H1, H2, H3 headers). For each section, build an evidence inventory:

```
FOR each narrative section:
  1. Identify the primary argument or claim
  2. Count statistics (numbers, percentages, ratios) — record each one
  3. Determine arc role by asking: "What is this section DOING for the argument?"
     → Establishing pain? → problem
     → Creating time pressure? → urgency
     → Quantifying the situation? → evidence
     → Proposing an approach? → solution
     → Demonstrating credibility? → proof
     → Showing implementation path? → roadmap
     → Driving toward action? → call-to-action
  4. Flag if section contains comparison data (before/after, old/new, versus)
  5. Flag if section contains a testimonial, quote, or attributed claim
  6. Record word count for merge decisions later
  7. Track source_chapter: which narrative H2 chapter this content was drawn from
     → If arc_elements are loaded, check if the H2 header matches an element name
     → Record: source_chapter = matched element name, or "none" if no match
```

<reasoning>
Before proceeding to Step 2, think through the full narrative:
- How many distinct arguments or claims does the narrative make?
- Which sections carry the most data (statistics, evidence)?
- Which sections are thin (under 50 words, few claims)?
- Does the narrative's structure match one of the five arc templates above?
- Are there any sections that serve dual roles (e.g., evidence + urgency)?

Write down your section inventory as a numbered list with arc role, word count, and stat count for each before mapping to section types.
</reasoning>

**Validation checkpoint:** Verify that every narrative section has exactly one primary arc role assigned. If a section serves dual roles (e.g., a data section that both quantifies and creates urgency), assign the PRIMARY role and note the secondary. Sections with no clear role are candidates for merging in Step 3.

### Step 2: Map Sections to Section Types

This is the most consequential step. Each arc role could map to multiple section types. Use the decision tree below to select the right type for each section.

#### Section Type Decision Tree

For each section, walk through these branches in order. Take the FIRST branch that matches:

```
START with the section's arc role and content characteristics:

IF arc_role is "hook":
  → ALWAYS use "hero"
  → STOP

IF arc_role is "call-to-action":
  → ALWAYS use "cta"
  → STOP

IF section contains 3+ statistics with distinct metrics:
  → Use "stat-row"
  → REASON: Multiple metrics are best displayed as a card row
  → STOP

IF section contains before/after data OR explicit comparison:
  → Use "comparison"
  → REASON: Columnar layout makes contrast visceral
  → STOP

IF section contains a direct quote with attribution:
  → Use "testimonial"
  → REASON: Quotes deserve visual prominence on dark background
  → STOP

IF section describes 4+ capabilities, features, or items in parallel:
  → Use "feature-grid"
  → REASON: Grid layout handles parallel items better than alternating
  → STOP

IF section describes a process with 3-5 sequential steps:
  → Use "timeline"
  → REASON: Steps need visual sequence, not prose
  → STOP

IF section has a single main argument with supporting image opportunity:
  → Use "feature-alternating"
  → REASON: Image+text side-by-side is the web narrative workhorse
  → STOP

DEFAULT:
  → Use "text-block" (bridge section) or "feature-alternating" (if image possible)
  → REASON: text-block for transitions, feature-alternating for content
```

<reasoning>
For each section, before committing to a section type, answer these three questions:
1. What content characteristics drive this choice? (stats count, comparison data, quote, feature list, process steps)
2. Does the arc template for this arc_type suggest a different type? If so, why am I deviating?
3. Would an alternate section type serve this content better? Why or why not?
</reasoning>

#### When to Override the Arc Template

The arc templates (above) are starting points, not mandates. Override the template when:

| Situation | Template Says | Override To | Reason |
|-----------|--------------|-------------|--------|
| Problem section has 4+ stats | `problem-statement` | `stat-row` | Statistics-heavy content reads better as metric cards |
| Solution section has 5+ parallel features | `feature-alternating` | `feature-grid` | Grid handles parallel items; alternating handles single arguments |
| Proof section has a direct quote | `comparison` | `testimonial` | Quotes deserve their own visual treatment |
| Urgency section has before/after data | `stat-row` | `comparison` | Contrast is more persuasive than raw numbers |
| Roadmap has only 2 steps | `timeline` | `feature-alternating` (x2) | Timeline needs 3+ steps to look right |

**Validation checkpoint:** Verify that every section has a section type assigned. Check that bookend sections are correct: first = `hero`, last = `cta`. Count the total sections and verify you are within the 6-10 range (you will enforce this in Step 4).

### Step 3: Merge Minor Sections

Thin sections harm visual rhythm. Merge or absorb them:

```
MERGE RULE 1 — Same-role adjacency:
  IF two adjacent sections have the same arc role AND combined content < 100 words:
    → Merge into a single section
    → Use the section type that best fits the combined content
    → Re-evaluate using the decision tree above

MERGE RULE 2 — Thin section absorption:
  IF a section has fewer than 30 words:
    → FIRST: Can it be absorbed into an adjacent section without changing that section's type?
      YES → Absorb (add content as bullets or body text)
      NO  → Promote to text-block (bridge section)

MERGE RULE 3 — Redundant stat sections:
  IF two stat-row sections are adjacent:
    → Merge into one stat-row with combined metrics (max 4 stat cards)
    → If combined metrics exceed 4, keep the most impactful 4
```

<reasoning>
After merging, ask:
- Did any merge change the arc role assignment? If so, re-evaluate.
- Are there still any sections under 40 words? These may need further absorption.
- Did merging create an imbalance (e.g., 4 feature-alternating in a row)?
</reasoning>

**Validation checkpoint:** Verify that no section is under 30 words. Verify that no two adjacent sections have the same arc role (unless intentional for solution detail).

### Step 4: Enforce Section Count

Target: 6-10 sections (including hero and CTA bookends). This range ensures enough visual variety without overwhelming the reader.

#### Too Few Sections (< 6)

```
IF section_count < 6:
  1. Identify the richest content section (highest word count + stat count)
  2. Ask: "Does this section make TWO distinct arguments?"
     YES → Split into two sections, each with its own headline and type
     NO  → Ask: "Can I extract a stat-row from the data in this section?"
       YES → Extract statistics into a new stat-row, keep remainder as original type
       NO  → Ask: "Does the narrative have implicit content I can surface?"
         YES → Create a text-block bridge section for the implicit transition
         NO  → Accept 5 sections (minimum viable narrative)
```

#### Too Many Sections (> 10)

```
IF section_count > max_sections (default 10):
  1. Rank all sections by arc role importance:
     KEEP (highest priority): hero, cta, problem, solution
     MERGE candidates (lower priority): urgency, evidence, proof, roadmap
  2. Starting from the lowest-priority sections:
     → Can two adjacent merge candidates combine?
       YES → Merge them (use the more visually rich section type)
       NO  → Can a lower-priority section be absorbed into an adjacent higher-priority one?
         YES → Absorb
         NO  → Demote to text-block (minimal visual footprint)
  3. Repeat until section_count <= max_sections
```

<reasoning>
After enforcing section count, verify:
- Is the narrative's core argument still intact? (All major claims represented?)
- Did I lose any critical statistics in the merging process?
- Does the section sequence still follow a logical emotional arc?
  (tension builds through problem/urgency, releases through solution/proof, resolves at CTA)
</reasoning>

**Validation checkpoint:** Count sections. Verify 6 <= count <= max_sections. Verify first section is `hero` and last is `cta`. Verify no arc role was eliminated entirely that the narrative depends on.

---

## Section Theme Alternation

Assign `section_theme` to create visual rhythm:

```
1. hero → dark (always)
2. FOR each content section (in order):
     IF role is urgency OR evidence → dark
     IF role is proof AND type is testimonial → dark
     ELSE → alternate between light and light-alt
     RULE: never two adjacent dark sections
       → IF a dark section would be adjacent to another dark section,
         demote it to light-alt
3. cta → accent (always)
```

### Alternation Example (why-change arc):

| Section | Type | section_theme | Reasoning |
|---------|------|---------------|-----------|
| 1 | hero | dark | Bookend rule: hero is always dark |
| 2 | problem-statement | light | Content section, starts light alternation |
| 3 | stat-row | dark | Urgency role forces dark |
| 4 | feature-alternating | light | Solution, back to light after dark |
| 5 | feature-alternating | light-alt | Solution, alternates from light |
| 6 | comparison | light | Proof, back to light |
| 7 | timeline | light-alt | Roadmap, alternates from light |
| 8 | cta | accent | Bookend rule: CTA is always accent |

### Adjacent Dark Section Prevention

```
IF assigning dark to section N:
  CHECK: Is section N-1 also dark?
    YES → Demote section N to light-alt
    → REASON: Two adjacent dark sections create a visual wall that breaks rhythm
  CHECK: Is section N+1 also dark?
    YES → Insert the current section as light-alt, let N+1 keep dark
    → REASON: Urgency/evidence sections benefit more from dark than content sections
```

**Validation checkpoint:** Walk through the section list and verify: no two adjacent dark sections, hero is dark, CTA is accent, light and light-alt alternate in the content sections.

---

## Bookend Rules

These are mandatory:

1. **First section is always `hero`** — maps to the `hook` arc role
2. **Last content section is always `cta`** — maps to `call-to-action`
3. Hero headline is the narrative's transformation promise
4. CTA headline is an action-oriented imperative
5. CTA copy matches the `conversion_goal` parameter

---

## Feature-Alternating Position Rules

When multiple `feature-alternating` sections appear in sequence:

- First instance: `position: odd` (image left, text right)
- Second instance: `position: even` (text left, image right)
- Continue alternating for additional instances

This creates visual variety and keeps the eye moving.

**Note:** Position alternation is based on the ORDER of feature-alternating sections, not their absolute position in the section list. If sections 4 and 6 are both feature-alternating (with section 5 being a different type between them), section 4 is still `odd` and section 6 is `even`.

---

## Worked Example: Full Decomposition

This example shows the complete decomposition process applied to a narrative about predictive maintenance in German manufacturing.

### Input Narrative Summary

A 1700-word narrative about predictive maintenance for the German Mittelstand. Arc type: why-change. Contains 8 data points, 3 major arguments, and a before/after case study. Sections:

1. Opening: "Ungeplante Stillstande bedrohen den Maschinenbau" (problem framing, 23 days stat, EUR 38k/day)
2. "Drei Krisen gleichzeitig" (skills shortage 64k, quality drift 1:5, maintenance costs 41%)
3. "Sensorik und Edge-KI" (solution: real-time condition monitoring, 500 readings/sec, 14-day prediction window)
4. "KI-Training auf historischen Daten" (approach: custom ML models, not generic)
5. "Pilotlinie Ergebnisse" (before/after: 23 days → 6 days, -73%, cost reduction 41%)
6. "Implementierungsfahrplan" (3-phase rollout: sensor pilot, AI training, full rollout, 12 weeks)

### Step 1: Section Inventory

```
Section 1: "Ungeplante Stillstande..."
  Arc role: problem
  Word count: ~180
  Stats: 2 (23 days, EUR 38k)
  Comparison data: no
  Quote: no

Section 2: "Drei Krisen..."
  Arc role: urgency
  Word count: ~120
  Stats: 3 (64k skills gap, 1:5 quality, 41% costs)
  Comparison data: no
  Quote: no

Section 3: "Sensorik und Edge-KI"
  Arc role: solution
  Word count: ~150
  Stats: 2 (500/sec, 14 days)
  Comparison data: no
  Quote: no

Section 4: "KI-Training..."
  Arc role: solution
  Word count: ~100
  Stats: 0
  Comparison data: no
  Quote: no

Section 5: "Pilotlinie Ergebnisse"
  Arc role: proof
  Word count: ~130
  Stats: 3 (23→6 days, -73%, -41% costs)
  Comparison data: YES (before/after)
  Quote: no

Section 6: "Implementierungsfahrplan"
  Arc role: roadmap
  Word count: ~90
  Stats: 1 (12 weeks)
  Comparison data: no
  Quote: no
  Process steps: 3 (pilot, training, rollout)
```

### Step 2: Section Type Mapping (with reasoning)

```
Section 1 → problem-statement
  REASONING: 2 stats but primary function is pain framing, not metric display.
  The stat (23 days) works as a stat card within problem-statement layout.
  Arc template says: problem-statement. Content confirms. No override needed.

Section 2 → stat-row
  REASONING: 3 distinct metrics (64k, 1:5, 41%) — hits the "3+ statistics"
  branch in the decision tree. Arc template says stat-row for urgency. Confirmed.

Section 3 → feature-alternating
  REASONING: Single main argument (sensor-based monitoring) with strong image
  opportunity (CNC machine sensors). Arc template says feature-alternating for
  solution. Content confirms.

Section 4 → feature-alternating
  REASONING: Single argument (custom ML models). Fewer stats but strong
  conceptual image opportunity (data flow visualization). Second solution
  section, will use position: even.

Section 5 → comparison
  REASONING: Contains explicit before/after data (23→6 days). Hits the
  "before/after data" branch in decision tree. Arc template also suggests
  comparison for proof. Confirmed.

Section 6 → timeline
  REASONING: 3 sequential process steps (pilot → training → rollout).
  Hits the "process with 3-5 steps" branch. Arc template confirms.
```

### Step 3: Merge Check

```
Section 4 has ~100 words — above 30 threshold, no merge needed.
No two adjacent sections share the same arc role (solution appears twice
  but that is intentional for feature-alternating variety).
No redundant stat-rows adjacent.
All sections above word minimums.
→ No merges required.
```

### Step 4: Section Count Check

```
Current count: 8 total (hero + 6 interior content + CTA).
8 is within 6-10 range. No splitting or merging needed.
```

### Final Section Plan

| # | Type | section_theme | Arc Role | Position | Headline |
|---|------|---------------|----------|----------|----------|
| 1 | hero | dark | hook | — | "Predictive Maintenance macht Ihre Fertigung unaufhaltsam" |
| 2 | problem-statement | light | problem | — | "23 Tage Stillstand kosten Ihre Wettbewerbsfahigkeit" |
| 3 | stat-row | dark | urgency | — | "Drei Krisen treffen den Maschinenbau gleichzeitig" |
| 4 | feature-alternating | light | solution | odd | "Sensoren lesen den Maschinenzustand in Echtzeit" |
| 5 | feature-alternating | light-alt | solution | even | "KI-Training auf Ihren historischen Daten beschleunigt den ROI" |
| 6 | comparison | light | proof | — | "73% weniger Stillstand in der Pilotlinie bewiesen" |
| 7 | timeline | light-alt | roadmap | — | "In 12 Wochen zur intelligenten Fertigung" |
| 8 | cta | accent | call-to-action | — | "Starten Sie Ihren Predictive-Maintenance-Piloten" |

### Theme Alternation Verification

```
dark → light → dark → light → light-alt → light → light-alt → accent
  ✓ No adjacent darks (dark at 1, light at 2, dark at 3)
  ✓ Light/light-alt alternate in content sections (4=light, 5=light-alt, 6=light, 7=light-alt)
  ✓ Hero=dark, CTA=accent
```

---

## Edge Cases

### Narrative Does Not Fit Standard Arc Types

When the narrative's structure does not clearly match any of the five arc templates:

```
1. Check if it is a HYBRID of two arcs:
   → e.g., starts as problem-solution but has a journey middle section
   → APPROACH: Use the dominant arc as the template, insert the foreign
     section type where it naturally fits

2. Check if it is a FLAT narrative (all sections at same level, no arc):
   → e.g., a feature overview with no problem/urgency framing
   → APPROACH: Impose a why-change arc by:
     a. Reframe the opening as a hook (what is the reader missing today?)
     b. Treat the first content section as a problem-statement
     c. Map remaining sections as solution/feature-alternating
     d. Close with CTA

3. Check if it is EXTREMELY SHORT (< 300 words):
   → APPROACH: Target 6 sections (minimum). Some sections will have minimal
     content. Use text-block for thin sections. Prioritize: hero, 2 content
     sections, CTA. Fill with stat-row or feature-grid if data is available.

4. Check if it is EXTREMELY LONG (> 3000 words):
   → APPROACH: Identify the 5-7 strongest arguments/claims. Map each to a
     section. Treat remaining content as supporting detail within those sections.
     Do not exceed max_sections (default 10). Merging aggressively is better
     than creating a 15-section web page.
```

### Sections with Mixed Roles

When a single narrative section serves two arc roles simultaneously:

```
EXAMPLE: A section that presents market data (evidence) while also creating
competitive urgency (urgency). "78% of competitors have already adopted..."

RESOLUTION:
1. Assign the PRIMARY role — the one that determines the section's position
   in the emotional arc. (In this example: urgency, because the competitive
   framing is the dominant rhetorical strategy.)
2. Note the SECONDARY role for content decisions. (The evidence data still
   appears in the section's body text or stat cards.)
3. Choose the section type based on the PRIMARY role using the decision tree.
4. If the secondary role would benefit from its own section AND the section
   count is below 8, consider splitting into two sections.
```

### No Statistics in the Narrative

When the narrative contains no quantitative data:

```
1. Skip stat-row sections entirely — they require 3+ metrics
2. Use problem-statement instead of stat-row for urgency (body text + bullets)
3. Use text-block or feature-alternating where stat-row would normally appear
4. Focus on comparison and testimonial for proof (qualitative evidence)
5. Check if any implicit numbers can be surfaced:
   → "Several years" → "3+ years"
   → "Many customers" → verify and quantify, or omit
```

### All Content is Solution-Focused

When the narrative is purely about capabilities with no problem/urgency:

```
1. The hero still needs a transformation promise — frame it as aspiration
   rather than pain avoidance: "Unlock X" rather than "Stop losing Y"
2. Use feature-grid for parallel capabilities (4-6 cards)
3. Use feature-alternating for deep-dive capabilities (1 per section)
4. Inject a comparison section to show differentiation (us vs. alternatives)
5. The CTA should focus on exploration rather than urgency:
   → "Explore the platform" rather than "Act before it is too late"
```

---

## Final Validation Checklist

Run this checklist after completing all decomposition steps, before proceeding to Step 5 (copywriting):

```
STRUCTURAL CHECKS:
  [ ] Section count is 6-10 (inclusive of hero and CTA)
  [ ] First section is hero with section_theme: dark
  [ ] Last section is cta with section_theme: accent
  [ ] Every section has: type, section_theme, arc_role
  [ ] No section type appears more than 3 times (variety check)

ARC INTEGRITY CHECKS:
  [ ] Every major narrative argument has a corresponding section
  [ ] The emotional arc progresses: tension (problem/urgency) → release (solution/proof) → action (CTA)
  [ ] The governing thought is supported by the section sequence

THEME ALTERNATION CHECKS:
  [ ] No two adjacent dark sections
  [ ] Hero = dark, CTA = accent
  [ ] Content sections alternate between light and light-alt
  [ ] Stat-row and testimonial are dark

FEATURE-ALTERNATING CHECKS:
  [ ] Position alternates: first = odd, second = even, etc.
  [ ] Position is based on feature-alternating ORDER, not absolute section position

MERGE/SPLIT CHECKS:
  [ ] No section is under 30 words
  [ ] No two adjacent sections have the same arc role (unless intentional)
  [ ] If sections were split to meet minimum count, each split has its own distinct argument
```
