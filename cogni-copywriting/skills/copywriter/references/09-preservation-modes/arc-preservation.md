---
title: Arc-Aware Preservation Mode
type: preservation-mode
category: preservation-modes
tags: [arc-preservation, story-arc, narrative-structure, polish, cogni-narrative]
audience: [copywriter-skill]
related:
  - arc-technique-map
version: 2.0
last_updated: 2026-02-25
---

# Arc-Aware Preservation Mode

<context>
You are polishing a narrative that uses a story arc structure created by cogni-narrative. The arc defines the document's skeleton: a title, subtitle, four arc elements in a fixed sequence, and a bridge section. Your job is to strengthen the writing within each element without altering the skeleton.

Think of it this way: the arc is a building's load-bearing frame. You are repainting walls and upgrading fixtures. You never move a wall, remove a beam, or change the floor plan.
</context>

## Activation Decision Tree

Use this tree at the start of every polish task to determine whether arc-aware mode applies:

```
Does the document YAML frontmatter contain an `arc_id` field?
  YES --> Activate arc-aware mode. Use the frontmatter arc_id.
  NO  --> Does the task prompt contain explicit arc preservation constraints?
            YES --> Activate arc-aware mode. Extract arc_id from the constraints.
            NO  --> Do the document's H2 headings match a known arc pattern? (see detection table below)
                      3+ of 4 element headings match --> Activate arc-aware mode with the matched arc_id.
                      Fewer than 3 match --> Do NOT activate. Polish normally.
```

When arc-aware mode is active, load the technique map before doing any work:

```
READ: references/09-preservation-modes/arc-technique-map.md
```

## Arc Detection Reference

**Step 1: Check frontmatter for arc_id.**

```yaml
---
arc_id: corporate-visions  # <-- This field triggers arc-aware mode
title: "..."
subtitle: "..."
---
```

**Step 2: If no frontmatter arc_id, match H2 headings against known arc patterns.**

| Arc ID | Element 1 | Element 2 | Element 3 | Element 4 |
|--------|-----------|-----------|-----------|-----------|
| corporate-visions | Why Change | Why Now | Why You | Why Pay |
| technology-futures | What's Emerging | What's Converging | What's Possible | What's Required |
| competitive-intelligence | Landscape | Shifts | Positioning | Implications |
| strategic-foresight | Signals | Scenarios | Strategies | Decisions |
| industry-transformation | Forces | Friction | Evolution | Leadership |

Match rule: Compare the document's H2 headings against the element columns above. A partial match on the first word is sufficient (e.g., "Why" matches "Why Change"). If 3 or more of the 4 elements match a single arc row, activate arc-aware mode with that arc_id.

**Localized headings are also valid.** Arc element headings may appear in German:

| Arc | EN | DE |
|-----|----|----|
| corporate-visions | Why Change | Warum Aendern |
| corporate-visions | Why Now | Warum Jetzt |
| corporate-visions | Why You | Warum Wir |
| corporate-visions | Why Pay | Warum Investieren |

Bridge section heading by language:
- EN: "Further Reading"
- DE: "Weiterfuehrende Lektuere"

Both language variants are preserved exactly as they appear.

## Structure Preservation Rules

### What You Must Never Modify

These elements are frozen. Any change to them constitutes a structural violation that will reject your output:

1. **H1 title text** -- exact character match required
2. **H2 subtitle text** -- exact character match required
3. **All 4 arc element heading texts** -- exact character match required
4. **Bridge section heading text** -- exact character match required (e.g., "Further Reading")
5. **Heading hierarchy** -- H1 and H2 levels stay as they are
6. **Heading order and count** -- the sequence and number of headings never change
7. **Content placement** -- no content moves between elements; each element is self-contained

### What You Must Never Apply in Arc-Aware Mode

The arc IS the document's organizing structure. Do not impose a competing one:

- Do NOT apply messaging frameworks (BLUF, Pyramid, SCQA) -- they would conflict with the arc's own logic
- Do NOT restructure element content into a different pattern
- Do NOT merge or split elements
- Do NOT add new sections or headings
- Do NOT change an element's purpose (e.g., converting "Why Now" urgency framing into "Why Change" problem framing)

### What You May Strengthen

Within each element, you may apply these six types of polish. Think through each one before making changes:

**1. Strengthen the element's primary technique.**
Consult arc-technique-map.md for which technique each element uses. Enhance that technique without replacing it.

Before (Why Change element, PSB pattern weak):
> Healthcare organizations face challenges with workflow efficiency. New approaches can help address these issues and improve outcomes.

Think: The PSB pattern requires a specific Problem, then Solution, then Benefit. This text is vague on all three. Strengthen each layer with concrete details from the existing content.

After (PSB pattern sharpened):
> Manual triage adds 23 minutes per patient encounter. AI-assisted routing eliminates the bottleneck. The result: 340 additional patients processed per month without added headcount.

**2. Apply the element's Number Play variant.**
Each element has a specific Number Play type assigned in the technique map. Use it.

Before (Why Pay element, compound impact missing):
> The costs of inaction are significant and compound over time across multiple dimensions.

Think: The technique map assigns compound impact calculation to Why Pay, requiring 3-4 cost dimensions and a 3-year horizon. Replace the vague claim with stacked specifics.

After (compound impact with 4 dimensions):
> Year one: $1.2M in excess staffing, $340K in error remediation, $180K in compliance penalties, $95K in overtime. By year three, the compounded cost of inaction exceeds $5.8M.

**3. Enhance Power Words.**
Strengthen verbs in body text. Apply sparingly -- 3 to 5 replacements per element maximum. Never change verbs in headings.

Before: "The platform helps teams manage their workload and provides better visibility."
After: "The platform enables teams to control their workload and delivers real-time visibility."

**4. Improve sentence rhythm.**
Vary sentence length. Place a short punch sentence (under 10 words) after a longer setup sentence (15-25 words).

Before: "The implementation reduced processing time from four hours to forty-five minutes, which meant that the backlog that had accumulated over three months was cleared within two weeks of deployment."

After: "The implementation cut processing time from four hours to forty-five minutes. The three-month backlog cleared in two weeks."

**5. Strengthen You-Phrasing.**
Convert third-person references to direct address, but only where the technique map marks You-Phrasing for that element.

Before (Why You element, marked for You-Phrasing): "Organizations that adopt early gain a 14-month head start."
After: "You gain a 14-month head start by adopting early."

Before (Why Change element, NOT marked for You-Phrasing): Leave third-person phrasing intact. Why Change uses PSB and contrast structure, not direct address.

**6. Improve within-element transitions.**
Sharpen paragraph transitions within a single element. Do NOT modify cross-element transitions (the bridging sentence between one H2 section and the next).

**7. Restructure weak hook openings.**
The hook is the exception to structural preservation. If the hook's first sentence fails ANY of these tests, you must restructure it:

- **Kuechenzuruf test:** Can the reader shout the gist to someone in the next room?
- **Surprise test:** Does it contain a surprising truth or the main conclusion?
- **Platitude test:** Is it a self-evident statement or generic context?
- **Raw statistics test:** Does it lead with an unframed number?
- **12-word test:** Is it a single Hauptsatz of max 12 words?

If the first sentence fails 3 or more of these tests, the opening MUST be restructured. Failing 1-2 tests warrants attempted revision within the current structure.

When restructuring a hook opening:
- Preserve ALL citations, facts, and data from the original
- Preserve the hook's overall purpose and message
- Apply german-hook-principles.md rules (if German) or equivalent English hook principles
- The restructured hook must still serve the arc's Pyramid Principle
- Only the first 1-2 sentences may be restructured; the rest of the hook is structure-protected
- Apply Regel 7 (Schneider): Find the strongest sentence in the hook paragraph and promote it
- Apply Regel 9 (Schneider): Move raw statistics to sentence 2-3 as the evidence anchor

This rule overrides the general prohibition on restructuring (item "What You Must Never Apply") specifically and only for the hook's first 1-2 sentences. The rationale: preservation must not mean starting with a weak first sentence. The very first sentence must be surprising and immediately hook the reader to continue.

## Step-by-Step Polish Process

Follow this sequence for every arc-aware polish task:

```
1. DETECT: Run the activation decision tree. Identify the arc_id.
2. LOAD: Read arc-technique-map.md. Note each element's primary technique,
   Number Play variant, and word target.
3. SNAPSHOT: Record the original document's heading texts, heading count,
   citation count, and per-element word counts.
4. POLISH: For each element (in order), apply the seven allowed modifications:
   a. Check the technique map for this element's assigned techniques.
   b. Strengthen the primary technique (e.g., sharpen PSB in Why Change).
   c. Apply the correct Number Play variant.
   d. Enhance 3-5 Power Words.
   e. Improve sentence rhythm.
   f. Apply You-Phrasing only if the technique map marks it for this element.
   g. Sharpen within-element transitions.
   h. FOR HOOK ONLY: Run the 5 hook quality tests. If 3+ fail, restructure
      the first 1-2 sentences per german-hook-principles.md / technique map.
5. VALIDATE: Run the validation checklist (below) against the polished output.
6. OUTPUT: If validation passes, return the polished document.
   If validation fails, revert the failing element(s) to original text.
```

## Validation Checklist

Run every check after polishing. Each is a binary pass/fail.

### Structure Checks (any failure rejects the entire output)

```
[ ] H1 title text -- exact character match to original
[ ] H2 subtitle text -- exact character match to original
[ ] 4 arc element headings -- exact character match to original arc pattern
[ ] H2 count -- exactly 6 total (subtitle + 4 elements + bridge)
[ ] Bridge heading -- exact match to "Further Reading" or localized equivalent
[ ] Heading order -- unchanged from original
[ ] No content moved between elements
```

### Technique Checks (failure reverts the individual element)

```
FOR EACH element:
  [ ] Primary technique still present and identifiable
      (e.g., PSB for Why Change, Forcing Functions for Why Now)
  [ ] Number Play variant matches the technique map assignment
  [ ] Word count within target range (original +/- 50 words)
```

### Content Integrity Checks (any failure rejects the entire output)

```
[ ] Citation count >= original citation count (no citations removed)
[ ] Citation format preserved: <sup>[N](source.md)</sup>
[ ] German characters preserved exactly: ae, oe, ue, ss
[ ] Protected content unchanged: diagram placeholders, figure references
```

### On Validation Failure

- If a structure check fails: reject the entire polished output. Return the original unpolished document. Log `fallback_reason="arc_structure_violation"`.
- If a technique check fails for one element: revert only that element to its original text. Keep the rest of the polished output. Log `fallback_reason="arc_technique_violation"`.
- If a content integrity check fails: reject the entire polished output. Return the original unpolished document. Log `fallback_reason="arc_content_violation"`.

## Common Mistakes to Avoid

These are the most frequent errors when polishing arc narratives. Check for each one:

**Mistake 1: Applying BLUF to the opening.**
The arc's hook section already uses Pyramid Principle (answer-first). BLUF restructuring would duplicate or conflict with this. However, if the hook's first sentence fails the hook quality tests (see "7. Restructure weak hook openings" above), you must restructure the first 1-2 sentences. This is not BLUF -- it is hook strengthening. The distinction: BLUF imposes a competing framework; hook strengthening applies the arc's own Pyramid Principle more effectively by promoting the strongest statement to position 1.

**Mistake 2: Blending element purposes.**
Each element serves one function. "Why Now" creates urgency through forcing functions and timelines. "Why Change" establishes the problem through PSB and contrast. If your polish makes "Why Now" read like a problem statement instead of an urgency driver, you have crossed element boundaries. Revert.

**Mistake 3: Removing or relocating citations.**
Citations are structural elements, not stylistic ones. They anchor claims to sources. Never remove a citation to improve sentence flow. Rewrite around the citation instead.

Before: "Response times improved significantly <sup>[4](source.md)</sup>, leading to better outcomes <sup>[5](source.md)</sup>."
Wrong: "Response times improved significantly, leading to better outcomes." (citations deleted for flow)
Right: "Response times dropped by 40% <sup>[4](source.md)</sup>. Patient outcomes improved within the first quarter <sup>[5](source.md)</sup>."

**Mistake 4: Applying You-Phrasing where the technique map does not call for it.**
You-Phrasing is assigned to specific elements (e.g., Why You, Decisions, Leadership). In elements like Why Change or Landscape, the analytical framing requires third-person distance. Do not force direct address everywhere.

**Mistake 5: Exceeding word targets.**
Each element has a word target range in the technique map. Polishing should not inflate word counts. If you add specificity in one sentence, cut filler from another. Stay within the +/- 50 word tolerance.

## Integration Pattern

When cogni-narrative or cogni-research invokes the copywriter with arc preservation, the task prompt will contain a constraints block like this:

```text
CRITICAL PRESERVATION REQUIREMENTS:
1. Citations: <sup>[N](source.md)</sup> -- PRESERVE EXACTLY
2. German characters: ae, oe, ue, ss -- PRESERVE EXACTLY (if present)
3. STORY ARC STRUCTURE -- PRESERVE EXACTLY:
   - arc_id: corporate-visions
   - H1 Title: "The Case for Workflow Redesign" -- DO NOT MODIFY
   - H2 Subtitle: "Healthcare AI Adoption Barriers" -- DO NOT MODIFY
   - Element headings: Why Change, Why Now, Why You, Why Pay -- DO NOT MODIFY
   - Bridge: "Further Reading" -- DO NOT MODIFY

ARC-AWARE POLISH: Strengthen techniques per arc-technique-map.md
FORBIDDEN: Change headings, move content between elements, apply messaging frameworks
```

When you see this pattern, activate arc-aware mode immediately. Do not re-run the detection decision tree -- the constraints block provides all the information you need.

## Related Documentation

- Arc technique map: `references/09-preservation-modes/arc-technique-map.md`
- cogni-narrative: Creates the story arc narratives that this mode polishes
- cogni-research create-insight: May invoke copywriter with arc preservation constraints
