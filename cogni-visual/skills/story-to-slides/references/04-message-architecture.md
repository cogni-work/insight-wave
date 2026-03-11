# Message Architecture for Presentations

## Purpose

Define how to transform a narrative's content into slide-level messages using the Pyramid Principle, one-message-per-slide discipline, MECE grouping, consolidation strategies, and logical sequencing. This is the bridge between understanding the story arc (Step 3) and writing slide copy (Step 5).

## Core Principle

> A presentation is a pyramid, not a stream.
> The audience should understand the full argument from the titles alone.

## Why This Matters

A narrative written for reading unfolds linearly — details accumulate, nuance builds, conclusions emerge. A presentation must do the opposite: state the conclusion first, then prove it. Message architecture is the intellectual work of restructuring a narrative's argument into a visual medium where:

1. **The governing thought** sits at the top (title slide subtitle)
2. **3-5 arguments** support it (slide groups)
3. **Evidence** proves each argument (individual slides)

Without this restructuring, slide generation becomes mechanical extraction — dumping content into layouts without understanding what the audience should take away.

---

## Step 4a: Build the Pyramid Structure

### Reasoning Approach

Building a pyramid is NOT content extraction — it is argument reconstruction. The goal is to identify the narrative's logical skeleton: what is being argued, what supports it, and what proves each support.

Before creating any slides, reason through the narrative's argument architecture:

```text
REASON through the narrative's argument structure:

  1. RECALL the governing thought from Step 3b
     → This is the pyramid's apex. Every slide must connect to it.

  2. IDENTIFY the main arguments (3-5)
     → Read the section roles from Step 3c
     → Group sections that serve the SAME argument function
     → Ask: "What are the 3-5 distinct reasons the governing thought is true?"

  3. MAP evidence to arguments
     → For each argument, list the narrative sections that provide proof
     → Ask: "What data, examples, or logic supports this argument?"

  4. TEST the pyramid
     → Read the governing thought, then each argument label, then the evidence
     → Does it flow as a coherent logical chain?
     → Could the audience understand the full case from just the governing thought
       + argument labels (without seeing any evidence)?
```

### How to Identify Arguments

Arguments are NOT topic labels — they are claims that support the governing thought. Each argument must be a complete assertion.

```text
DISTINGUISH arguments from topics:

  TOPIC (BAD):   "Security"
  ARGUMENT (GOOD): "Rail security has reached crisis levels with 688 deaths annually"

  TOPIC (BAD):   "Our Solution"
  ARGUMENT (GOOD): "AI video analytics detects 97% of incidents in real time"

  TOPIC (BAD):   "Costs"
  ARGUMENT (GOOD): "€280K investment returns 4.3x in Year One"

WHY: Topics organize information. Arguments advance the case.
     The audience must hear CLAIMS that build toward the governing thought,
     not CATEGORIES that organize content.
```

### Argument Grouping Process

```text
PHASE 1 — Collect section roles from Step 3c:

  List all sections with their assigned roles:
    Section A: "Schienensuizide" → role: problem
    Section B: "Übergriffe auf Bahnhöfen" → role: problem
    Section C: "Veraltete Infrastruktur" → role: problem
    Section D: "Regulatorischer Druck 2025" → role: urgency
    Section E: "Förderfenster schließt" → role: urgency
    Section F: "KI-Videoanalytik Lösung" → role: solution
    ...

PHASE 2 — Group into argument clusters:

  Look for sections that serve the SAME argument at the pyramid level:
    → Sections A, B, C all describe different crisis areas → ARGUMENT 1: "Crisis"
    → Sections D, E both create time pressure → ARGUMENT 2: "Urgency"
    → Section F presents the solution → ARGUMENT 3: "Solution"

  Each cluster becomes one pyramid argument.
  Each section within a cluster becomes one or more evidence slides.

PHASE 3 — Label each argument as a claim:

  Convert cluster labels to assertion statements:
    × "Crisis" → ✓ "German rail faces a security crisis: 688 deaths, 2,661 attacks annually"
    × "Urgency" → ✓ "Regulatory deadlines and closing funding windows demand action now"
    × "Solution" → ✓ "AI video analytics prevents 97% of incidents at 73% lower cost"

PHASE 4 — Verify pyramid coherence:

  Read aloud: Governing Thought → Argument 1 → Argument 2 → Argument 3
  Does it tell a complete, logical story?
    → If YES: proceed
    → If NO: adjust argument labels or regroup sections
```

### Level Mapping

| Pyramid Level | Presentation Element | Content |
|---------------|---------------------|---------|
| **Top** | Title slide subtitle | Governing thought — the one thing the audience should remember |
| **Arguments** | Section dividers (if needed) or slide groups | 3-5 MECE argument claims |
| **Evidence** | Individual slides | One message per slide, supported by data/visuals |

### Applying Pyramid to Different Arc Types

| Arc Type | Pyramid Pattern | Typical Arguments |
|----------|----------------|-------------------|
| `why-change` | GT: "[Customer] must [action] to [outcome]" | A1: Crisis/Problem → A2: Urgency → A3: Solution → A4: Investment |
| `problem-solution` | GT: "[Solution] solves [problem] with [result]" | A1: Problem scope → A2: Solution approach → A3: Proof/benefits |
| `journey` | GT: "[Achievement] in [timeframe]" | A1: Starting point → A2: Key milestones → A3: Results/lessons |
| `argument` | GT: "[Recommendation] because [reasons]" | A1: Argument 1 → A2: Argument 2 → A3: Argument 3 |
| `report` | GT: "[Key finding] with [implication]" | A1: Finding 1 → A2: Finding 2 → A3: Recommendations |

### Edge Cases

```text
PROBLEM: Narrative has only 2 clear arguments
  → Check if one argument can be split (e.g., "Solution" → "Capability" + "Proof")
  → If not, 2 arguments is acceptable for short decks (5-7 slides)

PROBLEM: Narrative has 6+ potential arguments
  → Look for arguments that can be merged (e.g., two similar evidence themes)
  → Apply MECE: are any overlapping? Merge overlaps.
  → Target 3-5 arguments for audience retention

PROBLEM: Sections don't clearly map to arguments
  → Return to Step 3c and re-examine section role assignments
  → The issue is usually at the role level, not the pyramid level
```

### Worked Example

Given a narrative about cloud migration with these sections from Step 3c:

```text
Governing Thought (from Step 3b):
  "Migrating to cloud saves €3.2M annually and reduces downtime by 73%"

Section roles from Step 3c:
  1. "Hidden Cost of Legacy" (role: problem)
  2. "Downtime Crisis" (role: problem)
  3. "Competitor Cloud Adoption" (role: urgency)
  4. "Cloud Migration Approach" (role: solution)
  5. "Architecture Overview" (role: solution)
  6. "Case Study: Deutsche Telekom" (role: proof)
  7. "Case Study: BMW" (role: proof)
  8. "ROI Calculation" (role: investment)
  9. "Implementation Roadmap" (role: roadmap)
  10. "Next Steps" (role: call-to-action)

PHASE 2 — Group into arguments:
  Sections 1-2 → ARGUMENT 1: Problem/Pain
  Section 3 → ARGUMENT 2: Urgency
  Sections 4-5 → ARGUMENT 3: Solution
  Sections 6-7 → ARGUMENT 4: Proof
  Sections 8-9 → ARGUMENT 5: Investment & Path

PHASE 3 — Label as claims:
  A1: "Legacy infrastructure costs €3.2M/year and causes 40% more downtime"
  A2: "78% of DACH competitors have already migrated"
  A3: "Managed cloud migration delivers 99.9% uptime in 14 months"
  A4: "12 enterprise migrations prove 73% downtime reduction"
  A5: "€1.4M investment returns 2.3x in Year One"

PHASE 4 — Read aloud:
  GT + A1 + A2 + A3 + A4 + A5 = coherent story ✓
  But 5 arguments may be too many for a 12-slide deck.
  → Merge A3 + A4 (solution + proof are tightly linked)
  → Final: 4 arguments
```

---

## Step 4b: Extract One Message Per Slide

### The Rule

Every slide must have exactly **ONE message** — a single sentence that captures what the audience should take away. This sentence becomes the slide title (assertion headline).

### Reasoning Approach

Message extraction is NOT summarization — it is distillation. The goal is not "what does this section say?" but "what is the ONE thing the audience must understand from this slide?"

```text
REASON through each narrative section:

  1. READ the section fully — absorb all content

  2. ASK: "What is the one thing this section is ARGUING?"
     → Not "what topics does it cover?" (that gives topic labels)
     → Not "what data does it contain?" (that gives data dumps)
     → But "what CLAIM is it making?" (that gives assertion messages)

  3. WRITE the claim as a single sentence
     → Must contain a VERB (active voice)
     → Should include a NUMBER when data exists
     → Must stand alone (understandable without other slides)

  4. TEST: Can this be split into INDEPENDENT claims?
     → If the sentence uses "and" to join two unrelated claims → SPLIT
     → If the sentence describes one thing with supporting detail → KEEP

  5. VERIFY connection to pyramid:
     → Does this message support one of the arguments from Step 4a?
     → If not, either:
       (a) the message drifted from the section's role → re-extract
       (b) the section is tangential → candidate for consolidation/cut
```

### Split vs. Combine Decision Logic

Message extraction often requires deciding whether narrative content becomes one slide or multiple. Reason through each decision:

```text
REASON through split/combine decisions:

  QUESTION 1: Does the section contain 2+ INDEPENDENT claims?
    → Independent means: each claim could stand alone as a slide
    → "Revenue grew 23% AND customer satisfaction hit 95%"
      These are independent metrics → SPLIT into two slides
    → "Revenue grew 23% driven by enterprise adoption"
      Growth and driver are one claim → KEEP as one slide

  QUESTION 2: Is the section evidence-heavy for a SINGLE claim?
    → "688 deaths + 2,661 attacks + 42% outdated systems + €2.8M costs"
      All prove ONE claim (crisis) → Evaluate:
        - Are they parallel metrics? → COMBINE into four-quadrants
        - Do they build on each other? → one stat-card, others to notes

  QUESTION 3: Is the section too thin for a standalone slide?
    → A section with one sentence and no supporting data
    → COMBINE with adjacent section that makes the same argument

  QUESTION 4: Does splitting improve the audience's understanding?
    → If the audience needs to absorb each claim separately → SPLIT
    → If claims are stronger presented together → COMBINE
    → Rule of thumb: split when claims serve different arguments,
      combine when claims reinforce the same argument
```

### Message Extraction Templates

For each section role, use these patterns to extract the message:

```text
ROLE → MESSAGE PATTERN:

  hook      → "[Shocking number/statement] — [consequence]"
  problem   → "[Metric] [problem verb] [affected entity]"
  urgency   → "Every [period], [cost/risk accumulates]" or "[Deadline] demands [action]"
  evidence  → "[Data point] proves [claim]" or "[N] of [M] [finding]"
  solution  → "[Solution] [achievement verb] [quantified result]"
  proof     → "[Customer/pilot] achieved [result] in [timeframe]"
  options   → "[N] [strategies/options] from [range]"
  roadmap   → "[Timeline] from [start] to [end] in [N] phases"
  investment → "[Investment] returns [multiplier/savings] in [timeframe]"
  call-to-action → "[Action verb] [specific next step] [this timeframe]"
```

### Worked Examples

**Example 1: Section that should SPLIT**

```text
Narrative section:
  "Our platform processes 1 million records daily, 10x faster than the industry
   average. The AI model achieves 97% accuracy. Customers report 60% cost savings."

REASONING:
  Step 2: What is this section arguing?
    → Three distinct claims: speed, accuracy, cost savings
  Step 4: Can these be split into independent claims?
    → Speed (1M records, 10x faster) — proves CAPABILITY
    → Accuracy (97%) — proves RELIABILITY
    → Cost savings (60%) — proves VALUE
    → These are independent metrics (each could stand alone) → candidate for SPLIT

  BUT WAIT — Question 2 from split/combine logic:
    → These are parallel metrics about the same solution
    → All prove one argument: "solution delivers results"
    → Better COMBINED into one four-quadrants or stat-card slide

  DECISION: COMBINE into one slide (parallel metrics reinforce same argument)
  SLIDE MESSAGE: "AI platform delivers 10x speed, 97% accuracy, and 60% cost savings"
```

**Example 2: Section that should SPLIT**

```text
Narrative section:
  "The German rail network faces a security crisis with 688 annual deaths.
   Meanwhile, EU regulation DIN-2025 mandates video surveillance by 2026,
   creating a €200M market opportunity."

REASONING:
  Step 2: Two distinct claims joined by "Meanwhile"
    → Claim A: security crisis (688 deaths) — serves role: problem
    → Claim B: regulatory deadline + market opportunity — serves role: urgency
  Step 4: Independent claims? YES — crisis and regulation are separate arguments
  Question 4: Does splitting help the audience?
    → YES: crisis creates emotional impact (best as hero stat)
    → Regulation creates time pressure (different emotional register)

  DECISION: SPLIT into two slides
  SLIDE 1 MESSAGE: "688 lives lost annually to preventable rail incidents"
  SLIDE 2 MESSAGE: "DIN-2025 mandates video surveillance by 2026 — €200M market opens"
```

**Example 3: Sections that should COMBINE**

```text
Narrative sections:
  Section A: "Response times improved from 48 hours to 15 minutes" (3 sentences)
  Section B: "Customer satisfaction increased from 62% to 94%" (2 sentences)

REASONING:
  Both sections serve role: proof
  Both prove the same argument: "solution delivers measurable results"
  Section B is too thin for a standalone slide (only 2 sentences)
  Together they form a compelling before/after comparison

  DECISION: COMBINE into one two-columns-equal slide
  SLIDE MESSAGE: "Solution cuts response time 192x and lifts satisfaction to 94%"
```

---

## Step 4c: Consolidation

### When to Consolidate

Consolidation is needed when message extraction produces more slides than `max_slides`. This is common — a 20-page narrative easily produces 18-25 potential slide messages, but a deck should rarely exceed 12-15 slides.

### Reasoning Approach

Consolidation is NOT random cutting — it is strategic compression. The goal is to reduce slide count while preserving argument strength and emotional arc.

```text
REASON through consolidation needs:

  1. COUNT extracted slide messages vs. max_slides
     → If count ≤ max_slides: no consolidation needed, proceed to Step 4d
     → If count > max_slides: calculate overage (e.g., 18 messages, max 12 = 6 over)

  2. ASSESS which arguments have the most evidence slides
     → Arguments with 4+ evidence slides are consolidation candidates
     → Arguments with only 1 evidence slide are PROTECTED

  3. PLAN consolidation by argument, not randomly across the deck
     → Keep the argument structure intact
     → Reduce evidence WITHIN arguments, not arguments themselves
```

### Consolidation Priority Order

Apply in this order (least destructive first, most aggressive last):

```text
Priority 1: MERGE parallel evidence
  WHAT: Multiple statistics about the same argument → one combined slide
  WHEN: 2+ slides present parallel data points for one argument
  HOW: Combine into four-quadrants (4 stats) or stat-card (2-3 stats)
  EXAMPLE: 4 separate crisis stats → one four-quadrants slide
  REASONING: Parallel data is STRONGER presented together. Merging
    actually IMPROVES the slide, not weakens it.

Priority 2: MERGE argument + evidence
  WHAT: An argument slide followed by its evidence slide → one slide
  WHEN: The argument claim and its proof can fit in one layout
  HOW: Use assertion headline (claim) + body (evidence)
  EXAMPLE: "Costs are rising" + "€2.8M in emergency operations" → single stat-card
  REASONING: The audience doesn't need the claim and proof on separate slides
    when the proof IS the claim.

Priority 3: PROMOTE to speaker notes
  WHAT: Detail that supports a slide but isn't essential for visual display
  WHEN: A slide has more context than fits visually
  HOW: Move supporting detail to Speaker-Notes "WHAT YOU NEED TO KNOW" section
  EXAMPLE: Methodology details, secondary citations, background context
  REASONING: The detail is preserved (presenter can reference it) but doesn't
    consume a slide. Best of both worlds.

Priority 4: CUT redundant proof
  WHAT: When multiple slides prove the same point, keep the strongest
  WHEN: Two or more slides make equivalent claims with different data
  HOW: Keep the slide with the best data (Tier 1 > Tier 2 > Tier 3)
  EXAMPLE: 3 case studies → keep the one with best numbers, note others in speaker notes
  REASONING: One strong proof point beats three moderate ones. Redundancy
    doesn't persuade — it fatigues.

Priority 5: CUT background context
  WHAT: Information the audience already knows or that sets up without advancing
  WHEN: Slides exist purely to "orient" rather than argue
  HOW: Remove entirely or merge key points into adjacent slide
  EXAMPLE: Industry overview for industry experts
  REASONING: Expert audiences resent being told what they already know.
    Background slides waste the attention budget.

Priority 6: COMPRESS closing
  WHAT: Merge multiple ending slides into fewer
  WHEN: "Next steps" + "timeline" + "call to action" are separate slides
  HOW: Combine into one closing-slide + one roadmap slide maximum
  EXAMPLE: Timeline → 4 steps instead of 6, next steps → merged into CTA
  REASONING: The ending should be sharp and actionable, not drawn out.
```

### Consolidation Decision Process

```text
REASON through each consolidation decision:

  FOR each candidate pair/group to consolidate:

    1. What ARGUMENT do these slides serve?
       → Same argument: safe to merge (evidence reinforces)
       → Different arguments: DO NOT merge (loses pyramid structure)

    2. Does merging STRENGTHEN or WEAKEN the message?
       → Parallel stats combined into quadrant: STRENGTHENS
       → Two case studies merged: WEAKENS (lose specificity)
       → Argument + proof into one slide: NEUTRAL to STRONG

    3. What does the audience LOSE if this slide disappears?
       → A unique data point not available elsewhere: HIGH LOSS → protect
       → A repetition of a point made elsewhere: LOW LOSS → cut
       → Context that helps understanding: MEDIUM LOSS → promote to notes

    4. Is this in the PROTECTED list?
       → If yes: DO NOT consolidate, find another candidate
```

### Audience-Aware Consolidation (Rich Mode)

When the Audience Model is Rich mode (from Step 2.5), consolidation decisions factor in the primary decision-maker's priorities:

```text
IF Audience Model mode == rich:
  1. IDENTIFY slides whose message aligns with primary_decision_maker.top_priority
     → These slides are added to the PROTECTED list
     → They may still be MERGED (Priority 1-2) but never CUT (Priority 4-5)

  2. WHEN choosing between two candidates to cut:
     → Prefer cutting the slide LESS aligned with primary decision-maker's priorities
     → This ensures the deck stays relevant to the person who approves the deal

IF Audience Model mode == lean:
  → Standard consolidation (no change from current behavior)
```

### What to NEVER Cut

```text
PROTECTED CONTENT (never remove during consolidation):
  - The governing thought (pyramid apex)
  - The strongest statistic in EACH argument (at least one hero number per argument)
  - The call to action (final slide)
  - Power Position slides (IS-DOES-MEANS) — these are pre-optimized
  - Solution overview slide (why-change arc — orients audience before Power Positions; uses `solution` role)
  - Any slide with confidence > 0.9 from layout mapping
  - The FIRST evidence slide for each argument (need at least 1 proof per claim)
  - Slides aligned with primary decision-maker's top priority (Rich mode only — from Audience Model)
```

### Consolidation Log

Track what was merged or cut for transparency:

```text
Consolidation Applied: Yes
  - Merged: Slides 3-4 (crisis stats) → four-quadrants layout [Priority 1]
  - Promoted to notes: Research methodology (Section 2) [Priority 3]
  - Cut: Background industry overview (redundant for audience) [Priority 5]
  - Compressed: Timeline 6→4 steps, next steps merged into CTA [Priority 6]
  - Original message count: 18 → Final slide count: 12
  - Protected: Governing thought, hero stats (688, €2.8M, 97%), CTA, 3 Power Positions
```

### Worked Example

```text
SCENARIO: max_slides = 12, extracted messages = 17

Messages:
  1. Title slide (protected — mandatory)
  2. Crisis: 688 rail deaths (problem, hero stat — protected)
  3. Crisis: 2,661 station attacks (problem)
  4. Crisis: 42% outdated systems (problem)
  5. Crisis: €2.8M emergency costs (problem, hero stat — protected)
  6. Urgency: DIN-2025 deadline (urgency)
  7. Urgency: Competitor adoption 78% (urgency)
  8. Solution: Power Position 1 (proof — protected)
  9. Solution: Power Position 2 (proof — protected)
  10. Solution: Power Position 3 (proof — protected)
  11. Investment: ROI 4.3x (investment, hero stat — protected)
  12. Investment: 3 pricing tiers (options)
  13. Roadmap: 4-phase implementation (roadmap)
  14. Roadmap: Team structure (evidence)
  15. Roadmap: Risk mitigation (evidence)
  16. References slide
  17. CTA: Next steps (protected — mandatory)

  Need to cut 5 slides (17 → 12).

REASONING:

  Priority 1 (MERGE parallel evidence):
    → Slides 2-5 are 4 parallel crisis stats for same argument
    → MERGE into one four-quadrants slide
    → SAVES 3 slides (4 → 1). Remaining overage: 2.

  Priority 3 (PROMOTE to speaker notes):
    → Slide 14 (team structure) supports roadmap but isn't essential
    → PROMOTE to speaker notes on Slide 13 (roadmap)
    → SAVES 1 slide. Remaining overage: 1.

  Priority 2 (MERGE argument + evidence):
    → Slides 6-7 (DIN deadline + competitor adoption) both create urgency
    → MERGE into one two-columns-equal (deadline left, competitors right)
    → SAVES 1 slide. Remaining overage: 0.

  Cut Slide 15 (risk mitigation) would be Priority 5 — not needed since we hit target.

RESULT: 12 slides
  1. Title slide
  2. Crisis quadrant (688 + 2,661 + 42% + €2.8M)
  3. Urgency comparison (deadline + competitors)
  4. Power Position 1
  5. Power Position 2
  6. Power Position 3
  7. ROI 4.3x
  8. 3 pricing tiers
  9. Roadmap (with team structure in notes)
  10. Risk mitigation
  11. References
  12. CTA
```

---

## Step 4d: MECE Verification and Sequencing

### What MECE Means for Slides

After extracting and consolidating slide messages, verify the final list is **Mutually Exclusive and Collectively Exhaustive** — and then sequence it for maximum impact.

### Mutual Exclusivity Check

No two slides should make the SAME claim. Overlap dilutes the argument and wastes audience attention.

```text
REASON through mutual exclusivity:

  FOR each pair of adjacent or related slides:

    1. COMPARE their message sentences
       → Do they make the SAME claim with different data?
       → Or do they make DIFFERENT claims?

    2. THE TEST: If you removed either slide, would the argument lose a UNIQUE point?
       → YES for both: they are mutually exclusive ✓
       → NO for one: that slide is redundant → merge or cut

  COMMON OVERLAPS TO CATCH:

    "Costs are rising" + "Emergency operations cost €2.8M"
      → These are the SAME point (cost problem)
      → FIX: Merge into one stat-card ("€2.8M annual emergency costs — and rising")

    "AI detects 97% of incidents" + "Response time reduced by 87%"
      → These are DIFFERENT points (detection vs. response speed)
      → KEEP as separate slides ✓

    "78% of competitors adopted cloud" + "Competitors gain 35% cost advantage"
      → SAME point (competitive pressure) with different evidence
      → FIX: Combine into one urgency slide (competition + their results)
```

### Collective Exhaustiveness Check

Together, all slides must cover the COMPLETE argument. No critical gap should remain.

```text
REASON through collective exhaustiveness:

  1. RE-READ the governing thought
     → What claims must be proven for this to be convincing?

  2. CHECK each pyramid argument has at least one slide
     → List arguments from Step 4a
     → Count slides per argument
     → If any argument has ZERO slides → gap found

  3. CHECK the emotional arc is complete
     → Is there a PROBLEM slide? (audience must feel the pain)
     → Is there a SOLUTION slide? (audience must see the answer)
     → Is there an EVIDENCE/PROOF slide? (audience must believe it works)
     → Is there a CTA slide? (audience must know what to do next)

  4. THE GAP TEST:
     → Read all slide messages in sequence
     → Does the audience have enough information to make a decision?
     → If you were the audience, what question would you still have?
     → If a question remains → there's a gap

  COMMON GAPS TO CATCH:

    Missing urgency: "Why should I care NOW?"
      → FIX: Add a deadline, trend, or competitive pressure slide

    Missing proof: "Does this actually work?"
      → FIX: Add a case study, pilot result, or testimonial slide

    Missing cost: "What does it cost?"
      → FIX: Add an investment/ROI slide

    Missing next step: "What do I do now?"
      → FIX: Ensure CTA slide has specific, actionable next step
```

### MECE Examples

**Mutually Exclusive — GOOD:**
```text
Slide 2: 688 rail deaths annually (CRISIS — safety dimension)
Slide 3: 42% of systems past end-of-life (CRISIS — infrastructure dimension)
Slide 4: DIN-2025 mandates action by 2026 (URGENCY — regulatory dimension)
→ Each addresses a DIFFERENT dimension. No overlap. ✓
```

**NOT Mutually Exclusive — BAD:**
```text
Slide 2: Rail safety crisis escalates (general crisis)
Slide 3: 688 deaths prove the crisis is real (specific crisis)
→ Slide 3 is just evidence FOR Slide 2. They overlap.
→ FIX: Merge into one stat-card (688 as hero number + crisis context)
```

**Collectively Exhaustive — GOOD:**
```text
Why Change + Why Now + Why Us + How Much = complete sales pitch
Problem → Evidence → Solution → Proof → Investment → CTA = full argument
```

**NOT Collectively Exhaustive — BAD:**
```text
Why Change + Why Us = missing urgency ("why now?") and investment ("how much?")
Problem → Solution → CTA = missing proof ("does it work?") and cost ("what's the investment?")
```

---

## Slide Sequencing

After MECE verification, arrange slides in the optimal order for the detected arc type.

### Sequencing Reasoning

```text
REASON through slide order:

  1. RECALL the arc type from Step 3a
     → This determines the default flow pattern

  2. ASSIGN each slide to a flow position
     → Use the flow template for the arc type (see below)
     → If a slide doesn't fit a position, it may be tangential

  3. CHECK emotional trajectory
     → Problem/urgency slides should BUILD tension
     → Solution/proof slides should RELEASE tension
     → CTA should CREATE momentum
     → The peak of tension should come BEFORE the solution appears

  4. VERIFY evidence proximity
     → Each claim should be followed quickly by its proof
     → Don't separate a statistic from the argument it supports
```

### Flow Templates by Arc Type

**Why Change:**
```text
Title → Problem → Urgency → Solution Overview → Power Positions (×N) → Investment → CTA
```

**Problem-Solution:**
```text
Title → Problem → Scale/Impact → Solution → Benefits → Proof → CTA
```

**Journey:**
```text
Title → Starting Point → Milestone 1 → Milestone 2 → Current State → Lessons → Next
```

**Argument:**
```text
Title → Thesis → Arg1 + Evidence → Arg2 + Evidence → Arg3 + Evidence → Conclusion → CTA
```

**Report:**
```text
Title → Executive Summary → Finding 1 → Finding 2 → Finding 3 → Recommendations → Next Steps
```

### Sequencing Rules

```text
RULE 1: Problem before solution
  → The audience must feel the pain before hearing the cure
  → WHY: A solution presented before the problem feels like a sales pitch.
    A solution presented after the problem feels like a rescue.
  → FIX if violated: Move all problem/urgency slides before the first
    solution slide.

RULE 2: Evidence close to its claim
  → Don't separate a statistic from the argument it supports
  → WHY: If 3 slides pass between a claim and its proof, the audience
    forgets the claim. Evidence is only powerful when adjacent to its claim.
  → FIX if violated: Reorder so each argument is immediately followed
    by its evidence.

RULE 3: Build tension, then release
  → Problem/urgency slides build tension
  → Solution/proof slides release it
  → WHY: The audience's emotional state must peak at the problem and
    resolve at the solution. If proof comes before solution, confidence
    is built for nothing. If urgency comes after solution, it undermines
    the answer already given.
  → FIX if violated: Reorder so tension builds (problem → urgency →
    evidence), then releases (solution → proof → CTA).

RULE 4: Strongest evidence first within each argument
  → Lead with the most impactful data point
  → WHY: Attention declines slide by slide. Put the best number first
    while attention is highest. Weaker evidence after strong evidence
    feels like a graceful wind-down, not a letdown.
  → FIX if violated: Reorder evidence slides within each argument by
    impact strength (Tier 1 before Tier 2).

RULE 5: End with action, not information
  → The last slide should drive behavior, not present data
  → WHY: The audience's final impression determines whether they act.
    Ending with data makes them think. Ending with a CTA makes them move.
  → FIX if violated: Ensure the closing-slide is ALWAYS last.
    If "next steps" precedes the CTA, merge them.
```

---

## Message Quality Checklist

Before finalizing slide messages, verify each one passes the quality gate:

```text
PER-SLIDE CHECK:
  □ Is it ONE sentence? (not two claims joined by "and" — if "and" joins
    independent claims, SPLIT the slide)
  □ Does it contain a verb? (active voice: "reduces", "enables",
    not "reduction of" — passive headlines lose 40% of impact)
  □ Does it include a number or specific claim? (where data exists —
    "23% growth" not "significant growth")
  □ Is it an assertion, not a topic? ("Revenue Grew 23%" not "Revenue Overview"
    — topic labels communicate nothing)
  □ Does it connect to the governing thought? (if removed, would the
    governing thought lose support?)
  □ Would the audience understand it without seeing the slide body?
    (the headline alone must carry the message)
  □ Is it under 60 characters? (fits on one title line without wrapping)
```

```text
FULL DECK CHECK (read ALL messages in sequence):
  □ Do the titles tell the complete story? (read only titles — is the
    argument clear without any slide body?)
  □ Are they MECE? (no two say the same thing, together they cover
    the full argument without gaps)
  □ Does the sequence follow the arc? (problem before solution,
    evidence after claim, CTA at end)
  □ Is there a clear call to action in the final message?
  □ Does the emotional arc work? (tension builds, peaks, then resolves)
```

---

## Full Pipeline Worked Example

End-to-end message architecture for a 15-slide Why Change deck:

```text
INPUT FROM STEP 3:
  Arc type: why-change
  Governing thought: "Deutsche Bahn must deploy AI video analytics to prevent
    688 annual rail deaths and save €2.8M in emergency costs."
  Sections with roles:
    S1: Value Story title (hook)
    S2: Security crisis — 688 deaths (problem)
    S3: Station attacks — 2,661 incidents (problem)
    S4: Infrastructure decay — 42% outdated (problem)
    S5: Emergency costs — €2.8M (problem)
    S6: DIN-2025 regulation (urgency)
    S7: Funding window closing (urgency)
    S8: Competitor adoption data (urgency)
    S9: 03-why-you Executive Summary (solution — overview)
    S10: PP#1 AI Video Analytics (proof)
    S11: PP#2 Predictive Maintenance (proof)
    S12: PP#3 Passenger Flow Optimization (proof)
    S13: ROI calculation (investment)
    S14: Pricing tiers (options)
    S15: Implementation roadmap (roadmap)
    S16: Next steps (call-to-action)

═══════════════════════════════════════════════
STEP 4a — BUILD PYRAMID:

  Governing Thought (apex):
    "Deutsche Bahn must deploy AI video analytics to prevent 688 annual
     rail deaths and save €2.8M in emergency costs."

  Arguments (from section grouping):
    A1: "German rail faces a multi-dimensional crisis: safety, infrastructure,
         and costs" (S2-S5)
    A2: "Regulatory deadlines and market pressure demand immediate action"
         (S6-S8)
    A3: "AI video analytics platform addresses all crisis dimensions" (S9 — solution overview)
    A4: "Three Power Positions prove each capability" (S10-S12 — proof)
    A5: "€280K investment returns 4.3x in Year One" (S13-S15)

  Test: GT → A1 → A2 → A3 → A4 → A5 flows logically ✓
  5 arguments for 16-slide deck = appropriate ✓

═══════════════════════════════════════════════
STEP 4b — EXTRACT ONE MESSAGE PER SLIDE:

  S1 → "Deutsche Bahn AI: Preventing 688 Deaths, Saving €2.8M Annually"
        (title slide — governing thought as subtitle)

  S2 → "688 Lives Lost Annually to Preventable Rail Incidents"
        (hero stat: 688, role: problem)

  S3+S4 → COMBINE decision:
    S3 (2,661 attacks) and S4 (42% outdated) are parallel crisis metrics.
    S5 (€2.8M costs) is another parallel metric.
    → All 3 remaining crisis points: four-quadrants candidate
    → But S2 already took 688 as hero stat
    → COMBINE S3+S4+S5 into one slide:
    "Four Crisis Dimensions Demand Unified Response"
    (quadrants: 688 deaths, 2,661 attacks, 42% outdated, €2.8M costs)

  Wait — S2 (688) is already a standalone hero stat.
  → S3+S4+S5 = three remaining crisis stats
  → Three stats don't fit four-quadrants perfectly
  → OPTION A: Keep S2 as hero stat + COMBINE S3+S4+S5 as second crisis slide
  → OPTION B: COMBINE all four (S2-S5) into one four-quadrants, lose hero impact
  → DECISION: OPTION A — 688 deaths deserves solo hero treatment (max emotional impact)

  S3+S4+S5 → "Attacks, Decay, and Costs Compound the Rail Crisis"
              (three remaining crisis metrics in one slide)

  S6 → "DIN-2025 Mandates Video Surveillance by 2026"
        (urgency: regulatory deadline)

  S7+S8 → COMBINE decision:
    S7 (funding window) and S8 (competitor adoption) both create urgency.
    → Same argument, different evidence → MERGE
    "Funding Closes Q2 2026 While 78% of Peers Already Act"
    (two-columns: deadline left, competition right)

  S9 → "AI Video Analytics Platform Addresses All Crisis Dimensions"
        (solution overview from 03-why-you Executive Summary, two-columns-equal layout)
        (Left: What We Propose — platform concept, architecture principles)
        (Right: How It Maps to Your Needs — connects to unconsidered needs from 01-why-change)

  S10 → "PP#1: AI Video Analytics Detects 97% of Incidents in Real Time"
         (is-does-means layout)

  S11 → "PP#2: Predictive Maintenance Cuts Downtime by 73%"
         (is-does-means layout)

  S12 → "PP#3: Passenger Flow Optimization Recovers €1.2M Annually"
         (is-does-means layout)

  S13 → "€280K Investment Returns 4.3x in Year One"
         (stat-card: hero number €280K or 4.3x)

  S14 → "Three Rollout Strategies: Pilot to National Scale"
         (three-options layout)

  S15 → "4-Phase Rollout Achieves Full Coverage in 6 Months"
         (timeline-steps layout)

  S16 → "Schedule Discovery Workshop This Quarter"
         (closing-slide)

  + References slide between S15 and S16

  MESSAGE COUNT: 14 content slides + title + references + closing = 16 ≤ max_slides ✓
  No consolidation needed.

═══════════════════════════════════════════════
STEP 4c — CONSOLIDATION CHECK:

  Count: 16 slides = max_slides + 1. Minor overage acceptable (or increase max_slides). ✓

═══════════════════════════════════════════════
STEP 4d — MECE VERIFICATION:

  Mutual Exclusivity:
    Slide 2 (688 deaths) vs Slide 3 (attacks+decay+costs):
      → Different crisis dimensions. No overlap. ✓
    Slide 4 (DIN-2025) vs Slide 5 (funding+peers):
      → Regulation vs. market pressure. No overlap. ✓
    Slide 6 (solution overview) vs Slides 7-9 (Power Positions):
      → Overview = WHAT the approach is. PPs = HOW each component delivers.
      → Different abstraction levels. No overlap. ✓
    Slide 10 (ROI) vs Slide 11 (tiers):
      → Value justification vs. pricing options. No overlap. ✓

  Collective Exhaustiveness:
    Problem covered? ✓ (Slides 2-3: crisis stats)
    Urgency covered? ✓ (Slides 4-5: deadline + competition)
    Solution overview covered? ✓ (Slide 6: platform concept)
    Proof covered? ✓ (Slides 7-9: three Power Positions)
    Investment covered? ✓ (Slides 10-11: ROI + pricing)
    CTA covered? ✓ (Slide 16: discovery workshop)

  Sequence check (Why Change flow):
    Title → Problem → Urgency → Solution Overview → Power Positions → Investment → CTA ✓
    Tension builds through crisis and urgency ✓
    Tension releases at solution overview (RELEASE point) ✓
    Proof builds confidence through Power Positions ✓
    Ends with action ✓

  RESULT: MECE verified. Sequence correct. Proceed to Step 5.
```

---
