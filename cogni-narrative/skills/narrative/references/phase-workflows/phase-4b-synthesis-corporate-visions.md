# Phase 4b: Arc-Specific Insight Summary (corporate-visions)

**Arc Framework:** Why Change -> Why Now -> Why You -> Why Pay
**Arc:** `corporate-visions` (Tier 2) | **Output:** `insight-summary.md` at project root (1,450-1,900 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Why Change: Unconsidered Needs`
- `## Why Now: Forcing Functions`
- `## Why You: Unique Positioning`
- `## Why Pay: ROI Justification`

**German (if `language: de`):**
- `## Warum Wandel: Unerkannte Handlungsbedarfe`
- `## Warum Jetzt: Handlungsdruck`
- `## Warum Sie: Einzigartige Positionierung`
- `## Warum Investieren: ROI-Begründung`

---

## Step 4.1.1: Load Evidence Entities (Context Tier 2)

Before loading, understand what each entity type contributes to this arc:

- **Findings** ground the narrative in verified evidence. They answer "what did we discover?"
- **Sources** provide attribution credibility. They answer "who says so?"

**Load:**
- Top 20 findings from `04-findings/data/` (quality_score >= 0.65)
- Top 15 sources from `07-sources/data/` (reliability_score >= 0.8)

**After loading, categorize each entity by which arc element it serves:**
1. Which findings reveal an *unconsidered need* (something counterintuitive or overlooked)? These feed **Why Change**.
2. Which findings contain *timelines, deadlines, or urgency indicators*? These feed **Why Now**.
3. Which findings suggest *strategic capabilities or competitive advantages*? These feed **Why You**.
4. Which findings contain *cost data, risk quantification, or financial impact*? These feed **Why Pay**.
5. Which sources are most authoritative (highest reliability_score)? Prioritize these for high-impact citations.

---

## Step 4.1.4: Extended Thinking Sub-steps

This is the most cognitively demanding step. You are transforming a 400-600 word analytical synthesis into a 1,450-1,900 word executive narrative. This is not simply adding words -- it is a rhetorical transformation that reframes evidence through the Corporate Visions persuasion framework.

---

### Sub-step A: Internalize the Source Material

Read `synthesis-cross-dimensional.md` carefully. Before writing anything:

1. What is the single most surprising or counterintuitive finding? (This becomes your narrative hook.)
2. What are the 2-3 cross-dimensional patterns or tensions? (These become structural threads across arc elements.)
3. What is the core research question or problem space? (This becomes your subtitle.)
4. What does the source material say explicitly, and what does it *imply* but not state? (You may develop implications, but not fabricate claims beyond what the evidence supports.)

---

### Sub-step B: Plan the Arc Element Mapping

Before writing any element, decide which evidence goes where. Each piece of evidence should be used exactly once (do not repeat the same finding across multiple elements).

**Why Change** (400-500 words) -- needs evidence of an unconsidered need:
- Which 2-3 findings reveal something executives likely overlook or underestimate?
- What is the "status quo assumption" you can challenge? Frame it as: "Most organizations think X. But research shows Y."

**Why Now** (300-400 words) -- needs forcing functions with timelines:
- Which 2-3 findings or trends contain specific deadlines, regulatory dates, or market tipping points?
- If no explicit timelines exist, which findings imply accelerating change or narrowing windows?

**Why You** (400-500 words) -- needs strategic capabilities:
- Which 2-3 findings suggest actionable strategic positions or capabilities?
- Can you frame these as Power Positions using IS-DOES-MEANS?

**Why Pay** (200-300 words) -- needs cost quantification:
- Which findings contain financial data, risk metrics, or cost implications?
- Can you stack 3-4 cost dimensions into a compound impact calculation?

**Wikilink allocation:** Target 40-50 total, roughly 10-13 per element.

---

### Sub-step C: Craft the Title and Hook

The title must be arc-specific and compelling -- never "Insight Summary" or anything generic. It should capture the unconsidered need in provocative language (6-12 words).

The hook paragraph (150-200 words) opens with the most surprising quantified finding:
- Sentence 1: Surprising data point with citation
- Sentence 2-3: Challenge the conventional wisdom this finding overturns
- Remaining sentences: Preview the arc's rhetorical progression without revealing all details
- Final sentence: Transition into Why Change

---

### Sub-step D: Write Each Arc Element

**Element 1 -- Why Change: Unconsidered Needs (400-500 words)**

Write using PSB (Problem-Solution-Benefit) structure:
- **Problem (~150 words):** State the current assumption and why it is incomplete. Use contrast structure: "Most organizations think X. But research shows Y." Ground with 2-3 citations.
- **Solution (~150 words):** Present the unconsidered reality the research reveals. This is not a product pitch -- it is a reframing of the problem space.
- **Benefit (~100-200 words):** Articulate the competitive advantage for early recognizers. End with a forward-looking implication that transitions toward urgency.

Does this section make the reader uncomfortable about their current assumptions? If it merely confirms what they already believe, the unconsidered need is not strong enough.

**Element 2 -- Why Now: Forcing Functions (300-400 words)**

Stack 2-3 forcing functions:
- **Forcing function 1 (~100 words):** External pressure + specific deadline from evidence. Use exact dates/quarters, not "soon" or "rapidly."
- **Forcing function 2 (~100 words):** Second converging pressure + quantified consequence. Use specific costs/penalties, not "financial risk."
- **Window of opportunity (~100-150 words):** Contrast early movers vs. late starters. Show the window closing.

Does every forcing function have a specific date AND a quantified consequence? Vague urgency ("the market is changing") fails this quality test.

**Element 3 -- Why You: Unique Positioning (400-500 words)**

Write 2-3 Power Positions using IS-DOES-MEANS for each:
- **IS (1-2 sentences):** What this capability is -- concrete, specific, not a buzzword. Give it a name.
- **DOES (3-5 sentences):** What it does for the reader. Use You-Phrasing throughout ("You reduce...", "Your teams..."). Quantify outcomes where evidence supports it.
- **MEANS (2-3 sentences):** Why competitors struggle to replicate this. Explain the moat: time investment, tacit knowledge, integration complexity.

If any Power Position reads like generic advice ("invest in training"), it is not a true Power Position.

**Element 4 -- Why Pay: ROI Justification (200-300 words)**

Write a compound impact calculation:
- **Cost dimension stacking (~150-200 words):** Present 3-4 cost dimensions, each with a specific number and a citation. Use a 3-year horizon.
- **Simple ratio conclusion (~50-100 words):** Reduce the entire business case to one undeniable comparison: "Action costs less than inaction by N-Mx."

Would an executive nod at the final sentence and say "that is clear"? If the comparison requires explanation, simplify further.

---

### Sub-step E: Review Narrative Coherence

Read through the full narrative from hook to closing and verify the rhetorical chain:

1. **Hook -> Why Change:** Does the hook's surprising finding naturally set up the unconsidered need?
2. **Why Change -> Why Now:** Does the unconsidered need make the forcing functions feel inevitable?
3. **Why Now -> Why You:** Does the urgency make the reader *want* the strategic capabilities?
4. **Why You -> Why Pay:** Do the Power Positions make the cost comparison feel like a natural conclusion?

Use the transition patterns:
- "This gap between X and Y defines the challenge."
- "Three converging forces make action urgent."
- "Organizations that thrive don't just react -- they build capabilities."
- "The cost of delay compounds."

If any transition feels forced, the rhetorical chain is broken -- revise.

---

### Sub-step F: Verify Quantitative Requirements

Before moving to validation, quick count:
- **Word count:** 1,450-1,900 total? If under, add evidence grounding. If over, trim least essential sentences.
- **Wikilinks:** 40-50 total? If under, add entity references. If over, consolidate.
- **Citations:** >= 8 finding citations? If under, identify unsupported claims.
- **Element word counts:** Why Change 400-500, Why Now 300-400, Why You 400-500, Why Pay 200-300.

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
