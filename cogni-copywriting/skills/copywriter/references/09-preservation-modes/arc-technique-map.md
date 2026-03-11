---
title: Arc Technique Map
type: reference
category: preservation-modes
tags: [arc, polish, techniques, number-plays, element-strengthening]
version: 2.0
last_updated: 2026-02-25
---

# Arc Technique Map

<purpose>
This reference is loaded when a document with `arc_id` frontmatter is being polished. It tells you exactly which narrative technique to strengthen inside each arc element and which Number Play variant to apply. You do NOT create or restructure arcs. You strengthen what is already there.
</purpose>

## Activation Check

Look for `arc_id` in the document's YAML frontmatter:

```yaml
---
arc_id: corporate-visions
---
```

If `arc_id` is present, use the matching section below to polish each element.

## How to Read Each Arc Section

Every arc section contains:
1. A lookup table mapping each element to its techniques, Number Play variant, and word target.
2. Detailed per-element instructions with before/after examples showing exactly how to strengthen.
3. Critical constraints on what NOT to do for that element.

When polishing, process one element at a time, top to bottom. For each element:
- Identify the primary technique from the table.
- Apply the Number Play variant from the table.
- Follow the element-specific rules.
- Verify the element still serves its distinct purpose (no blending).

---

## Arc: corporate-visions

**Elements:** Hook, Why Change, Why Now, Why You, Why Pay

| Element | Heading | Primary Technique | Number Play Variant | Word Target |
|---------|---------|-------------------|---------------------|-------------|
| Hook | (opening paragraphs) | Pyramid Principle (answer-first) | Hero number isolation | 150-200 |
| Why Change | Why Change | PSB + Contrast Structure | Ratio framing, specific quantification | 400-500 |
| Why Now | Why Now | Forcing Functions (2-3 stacked) + timelines | Before/after contrast | 300-400 |
| Why You | Why You | IS-DOES-MEANS + You-Phrasing | Comparative anchoring | 400-500 |
| Why Pay | Why Pay | Compound Impact Calculation | Compound impact (3-4 cost dimensions, 3-year horizon) | 200-300 |

### Why Change -- Element Rules

**Primary technique: PSB (Problem-Solution-Benefit) with Contrast Structure**

Verify the PSB pattern is intact. The element must flow: Problem statement, then Solution framing, then Benefit. Strengthen contrast structures that reframe assumptions.

<before_after>
BEFORE (weak contrast):
"Many organizations struggle with manual processes. Better tools can help improve outcomes."

AFTER (strong contrast):
"Most teams assume 15% rework rates are normal. Research from McKinsey shows that automated validation reduces rework to under 2% -- freeing 340 hours per quarter for strategic work."
</before_after>

**Strengthen:**
- Contrast openers: "Most think X. Research shows Y." or "The assumption is X. The reality is Y."
- Evidence-based reframing with citations.
- Ratio framing for key statistics (convert "25% failure rate" to "1 in 4 projects fail").
- Specific quantification for every vague claim ("significant savings" becomes "$127,000 annually").

**Do NOT:**
- Flatten the PSB into a generic problem statement without solution/benefit layers.
- Remove or weaken contrast structures.
- Strip citations.

---

### Why Now -- Element Rules

**Primary technique: Forcing Functions (2-3 stacked) with timelines**

Verify that 2-3 distinct forcing functions are present, each with a specific timeline or deadline. Forcing functions are external pressures that create urgency (regulatory deadlines, market shifts, technology deprecation).

<before_after>
BEFORE (vague urgency):
"Organizations need to act soon because the market is changing quickly and competitors are moving fast."

AFTER (stacked forcing functions with timelines):
"Three converging deadlines make Q3 2026 the decision point. First, DORA compliance takes effect January 2027 -- organizations need 6 months for implementation. Second, SAP ends ECC support in December 2027, forcing migration decisions by mid-2026. Third, early adopters who moved in 2025 already report 40% lower integration costs versus those starting after regulatory pressure peaks."
</before_after>

**Strengthen:**
- Replace vague urgency words ("soon", "quickly", "rapidly") with specific dates and deadlines.
- Stack 2-3 forcing functions, each with its own timeline.
- Add before/after contrast for early movers versus late movers.
- Quantify the cost of delay where possible.

**Do NOT:**
- Reduce to a single urgency statement.
- Remove specific dates or deadlines.
- Blend urgency arguments into "Why Change" problem framing.

---

### Why You -- Element Rules

**Primary technique: IS-DOES-MEANS with You-Phrasing**

Verify the IS-DOES-MEANS layers are present and distinct. The IS layer states the capability, the DOES layer states what the customer can achieve, the MEANS layer states the strategic outcome. Apply You-Phrasing specifically in the DOES layer.

<before_after>
BEFORE (third-person, merged layers):
"Our platform provides advanced analytics capabilities that help organizations improve their decision-making and achieve better business outcomes."

AFTER (distinct layers, You-Phrasing in DOES):
"IS: AI-powered risk scoring engine trained on 10 years of manufacturing data, processing 50,000 supplier signals daily.
DOES: You identify supply chain disruptions 3 weeks before impact -- reducing your emergency response costs by 60%.
MEANS: Never be caught off-guard by supplier failures again. Protect revenue and customer commitments with confidence."
</before_after>

Note: The element may not use explicit IS/DOES/MEANS markers. The layers may be expressed as paragraphs. Verify the three layers are conceptually distinct regardless of formatting.

**Strengthen:**
- IS layer: Add specifics (data volumes, certifications, timeframes). Remove generic buzzwords.
- DOES layer: Apply You-Phrasing ("You reduce..." not "Organizations can reduce..."). Add Number Plays with comparative anchoring.
- MEANS layer: Strengthen emotional resonance. Connect to executive concerns (revenue, risk, reputation).

**Do NOT:**
- Merge the three layers into a single paragraph.
- Apply You-Phrasing in the IS layer (IS describes the capability, not the customer).
- Remove quantification from the DOES layer.

---

### Why Pay -- Element Rules

**Primary technique: Compound Impact Calculation**

This element is the punchline of the arc. It must stack 3-4 cost dimensions and project them over a 3-year horizon to show compound impact. Keep it concise.

<before_after>
BEFORE (single dimension, no horizon):
"The solution saves approximately $200,000 per year in operational costs."

AFTER (compound impact, 3-year horizon):
"Year 1 alone stacks four cost dimensions: $127,000 in reduced manual processing, $89,000 in error remediation avoided, $34,000 in compliance penalty prevention, and $52,000 in recovered staff capacity. Over 3 years at conservative 5% growth, the compound impact reaches $968,000 -- a 4.2:1 return on a $230,000 investment."
</before_after>

**Strengthen:**
- Stack 3-4 distinct cost dimensions (do not lump into one figure).
- Make the 3-year horizon explicit with year-over-year progression.
- Close with a ratio comparison (X:1 return, or "for every $1 invested...").
- Keep concise -- this element should be the shortest of the four.

**Do NOT:**
- Expand beyond 300 words. This element is the punchline, not the argument.
- Collapse cost dimensions into a single total without showing the components.
- Omit the closing ratio or comparison.

---

## Arc: technology-futures

**Elements:** Hook, What's Emerging, What's Converging, What's Possible, What's Required

| Element | Heading | Primary Technique | Number Play Variant | Word Target |
|---------|---------|-------------------|---------------------|-------------|
| Hook | (opening paragraphs) | Pyramid Principle | Hero number isolation | 150-200 |
| What's Emerging | What's Emerging | Maturity signals + capability quantification | Specific quantification, before/after | 350-450 |
| What's Converging | What's Converging | Multiplicative framing (not additive) | Compound impact | 350-450 |
| What's Possible | What's Possible | Concrete scenarios + opportunity windows | Comparative anchoring, ratio framing | 350-450 |
| What's Required | What's Required | Prerequisites + sequencing logic | Before/after contrast | 200-350 |

### What's Emerging -- Element Rules

**Primary technique: Maturity signals with capability quantification**

Track technology readiness through maturity stages: lab, pilot, production. Replace hype language with evidence from early adopters.

<before_after>
BEFORE (hype):
"Revolutionary AI capabilities are transforming the industry with unprecedented potential."

AFTER (maturity signals):
"Three production deployments in 2025 confirmed what lab results suggested: on-device LLMs now process 40 tokens/second on standard edge hardware -- up from 3 tokens/second two years ago. Siemens and Bosch both moved from pilot to production in Q4 2025, reporting 94% accuracy on industrial inspection tasks."
</before_after>

**Strengthen:**
- Maturity signals: Specify the stage (lab/pilot/production) with named early adopters where available.
- Quantify capability improvements with specific numbers.
- Replace hype words ("revolutionary", "unprecedented", "game-changing") with measured evidence.

**Do NOT:**
- Upgrade weak signals to trends. If something is still in lab stage, say so.
- Remove named early adopters or replace with vague "leading companies."

---

### What's Converging -- Element Rules

**Primary technique: Multiplicative framing**

The core idea of this element is that technologies combine to enable something none achieves alone. Frame the convergence as multiplicative, not additive.

<before_after>
BEFORE (additive list):
"Several technologies are advancing: AI is improving, cloud costs are dropping, and edge computing is maturing."

AFTER (multiplicative framing):
"On-device inference (40 tokens/second), sub-$200 edge hardware, and 5G latency under 10ms converge to enable real-time quality inspection at the production line -- a capability that requires all three and that none delivers independently. Together they eliminate the 2-3 second cloud round-trip that made real-time industrial AI impractical until now."
</before_after>

**Strengthen:**
- Explain why these technologies converge NOW (what changed to make the combination viable).
- Use compound impact Number Plays to show combined effect.
- Frame explicitly: "together they enable X, which neither achieves alone."

**Do NOT:**
- Reduce to a bulleted list of separate technologies.
- Present convergence as mere coincidence rather than causal enablement.

---

### What's Possible -- Element Rules

**Primary technique: Concrete scenarios with opportunity windows**

Make scenarios specific: name use cases, quantify value potential, and bound opportunity windows with timelines.

<before_after>
BEFORE (abstract):
"There are many exciting opportunities for organizations to leverage these technologies."

AFTER (concrete scenario):
"A mid-sized manufacturer (500-2,000 employees) deploying edge-AI inspection in Q3 2026 captures a 12-18 month advantage before commodity solutions arrive. At $340 per inspection-hour saved across 3 production lines, the annual value reaches $890,000 -- with payback in 7 months. By 2028, this capability becomes table stakes; the competitive advantage shifts from having it to having optimized it."
</before_after>

**Strengthen:**
- Name specific use cases, not abstract "opportunities."
- Quantify value potential with comparative anchoring ("$340 per inspection-hour saved").
- Include opportunity window timelines ("12-18 month advantage before commodity solutions arrive").
- Connect to competitive positioning.

**Do NOT:**
- Leave scenarios at the abstract level.
- Omit timelines for opportunity windows.

---

### What's Required -- Element Rules

**Primary technique: Prerequisites with sequencing logic**

List specific prerequisites and the order in which they must be addressed. Include build timelines and make/buy/partner decisions explicit.

**Strengthen:**
- Specificity of prerequisites (name technologies, skills, integrations needed).
- Sequencing logic: what must happen first, second, third and why.
- Build timelines for each phase.
- Make/buy/partner decision points.

**Do NOT:**
- Turn into a vague "next steps" section.
- Omit sequencing dependencies.

---

## Arc: competitive-intelligence

**Elements:** Hook, Landscape, Shifts, Positioning, Implications

| Element | Heading | Primary Technique | Number Play Variant | Word Target |
|---------|---------|-------------------|---------------------|-------------|
| Hook | (opening paragraphs) | Pyramid Principle | Hero number isolation | 150-200 |
| Landscape | Landscape | PSB + segment decomposition | Specific quantification (market share, revenue) | 350-450 |
| Shifts | Shifts | Contrast Structure + momentum analysis | Before/after contrast, ratio framing | 300-400 |
| Positioning | Positioning | IS-DOES-MEANS for gap identification | Comparative anchoring | 400-500 |
| Implications | Implications | Time-bound actions + competitive response | Before/after contrast | 250-350 |

### Landscape -- Element Rules

**Primary technique: PSB with segment decomposition**

This element is analytical, not narrative. Strengthen market structure quantification: share percentages, revenue figures, capability scores.

**Strengthen:**
- Market share figures with specific percentages and revenue numbers.
- Competitive basis mapping (cost leadership / differentiation / focus).
- Segment decomposition with quantified sizes.

**Do NOT:**
- Turn analytical structure into flowing narrative prose.
- Remove specific market data or replace with qualitative assessments.

---

### Shifts -- Element Rules

**Primary technique: Contrast Structure with momentum analysis**

Contrast static market positions against dynamic momentum. Show who is gaining, who is losing, and at what rate.

<before_after>
BEFORE (static):
"Several competitors are making moves in the market."

AFTER (momentum analysis):
"Competitor A grew market share from 12% to 19% in 18 months, investing $45M in R&D (3x their 2023 level). Meanwhile, the incumbent leader's share dropped from 31% to 26% -- the first decline in 8 years. The shift accelerated after Q2 2025, when Competitor A's new platform reached feature parity."
</before_after>

**Strengthen:**
- Velocity indicators: share trends over time, investment rates, growth rates.
- Before/after contrast for market positions.
- Specific timelines for strategic moves.

**Do NOT:**
- Describe market shifts without quantifying direction and speed.

---

### Positioning -- Element Rules

**Primary technique: IS-DOES-MEANS for gap identification**

Use the IS-DOES-MEANS framework to identify uncontested spaces and capability gaps.

**Strengthen:**
- Clearly identify uncontested market spaces.
- Quantify capability gaps with specific metrics.
- Use comparative anchoring: "Competitor A covers 80% of the use case; the remaining 20% -- the customization layer -- is uncontested."

**Do NOT:**
- Present positioning without identifying specific gaps.

---

### Implications -- Element Rules

**Primary technique: Time-bound actions with competitive response scenarios**

Structure implications across three time horizons and consider competitive responses.

**Strengthen:**
- Three explicit time horizons: 0-6 months, 6-18 months, 18-36 months.
- Competitive response scenarios: "If we do X, competitor likely responds with Y."
- Specific, measurable actions for each horizon.

**Do NOT:**
- Collapse all implications into a single timeframe.
- Ignore likely competitive responses.

---

## Arc: strategic-foresight

**Elements:** Hook, Signals, Scenarios, Strategies, Decisions

| Element | Heading | Primary Technique | Number Play Variant | Word Target |
|---------|---------|-------------------|---------------------|-------------|
| Hook | (opening paragraphs) | Pyramid Principle | Hero number isolation | 150-200 |
| Signals | Signals | Weak signal identification + forcing functions | Specific quantification | 300-400 |
| Scenarios | Scenarios | Contrast Structure (2-3 distinct futures) | Comparative anchoring | 400-500 |
| Strategies | Strategies | IS-DOES-MEANS for robust actions | Before/after contrast | 350-450 |
| Decisions | Decisions | You-Phrasing + decision triggers | Ratio framing | 250-350 |

### Signals -- Element Rules

**Primary technique: Weak signal identification with forcing functions**

Signals must be weak (emerging, not mainstream). Acknowledge contradictory signals and make uncertainty dimensions explicit.

<before_after>
BEFORE (signal presented as certainty):
"The market is clearly moving toward decentralized manufacturing."

AFTER (weak signal with uncertainty):
"Three early indicators suggest decentralized manufacturing may accelerate: 2 Fortune 500 firms piloted micro-factories in 2025 (both reported 30% logistics cost reduction), 3D printing throughput crossed the 100-units/hour threshold in Q4, and reshoring incentives increased 40% in the latest policy cycle. Contradicting signal: centralized players like Foxconn are doubling capacity investments, suggesting the shift is not yet consensus."
</before_after>

**Strengthen:**
- Qualify signal strength: early indicator, emerging pattern, or isolated datapoint.
- Include contradictory signals explicitly.
- Make uncertainty dimensions visible (what could make this signal wrong?).

**Do NOT:**
- Upgrade weak signals to confirmed trends.
- Remove contradictory evidence.
- Present signals with false certainty.

---

### Scenarios -- Element Rules

**Primary technique: Contrast Structure for 2-3 distinct futures**

Verify that scenarios are genuinely distinct, not variations of the same outcome.

**Strengthen:**
- Plausibility grounding: explain what conditions would lead to each scenario.
- Distinct implications per scenario.
- Comparative anchoring between scenarios ("In Scenario A, market size reaches $12B; in Scenario B, it fragments to $4B across 6 niches").

**Do NOT:**
- Allow scenarios to collapse into minor variations of the same future.
- Present scenarios without exploring their distinct implications.

---

### Strategies -- Element Rules

**Primary technique: IS-DOES-MEANS for robust actions**

Strategies must be robust across multiple scenarios, not optimized for a single one.

**Strengthen:**
- Identify no-regret moves (actions that pay off regardless of which scenario materializes).
- Enhance flexibility and optionality language.
- Before/after contrast: "If we invest now, we gain X optionality; if we wait, options narrow to Y."

**Do NOT:**
- Present strategies that only work under one scenario.
- Omit no-regret move identification.

---

### Decisions -- Element Rules

**Primary technique: You-Phrasing with specific decision triggers**

Address the reader directly. Make decision triggers concrete and include reversibility assessment.

<before_after>
BEFORE (third-person, vague):
"Organizations should consider making a decision about platform investment when market conditions change."

AFTER (You-Phrasing, specific trigger):
"You face a decision point when any two of these three triggers fire: (1) your largest competitor announces a platform migration, (2) the regulatory draft enters public comment period, or (3) your legacy vendor's renewal terms exceed 15% increase. This decision is partially reversible -- you can pilot for 6 months before full commitment, limiting downside to $180,000."
</before_after>

**Strengthen:**
- You-Phrasing throughout ("You decide...", "Your trigger is...", not "The organization should...").
- Specific, observable decision triggers (not "when conditions are right").
- Reversibility assessment for each major decision.

**Do NOT:**
- Use third-person framing.
- Leave decision triggers vague.

---

## Arc: industry-transformation

**Elements:** Hook, Forces, Friction, Evolution, Leadership

| Element | Heading | Primary Technique | Number Play Variant | Word Target |
|---------|---------|-------------------|---------------------|-------------|
| Hook | (opening paragraphs) | Pyramid Principle | Hero number isolation | 150-200 |
| Forces | Forces | PSB + force quantification | Specific quantification, ratio framing | 350-450 |
| Friction | Friction | Forcing Functions + barrier identification | Before/after contrast | 300-400 |
| Evolution | Evolution | Contrast Structure (current vs. future) | Comparative anchoring | 400-500 |
| Leadership | Leadership | IS-DOES-MEANS + You-Phrasing | Compound impact | 250-350 |

### Forces -- Element Rules

**Primary technique: PSB with force quantification**

Quantify the magnitude of each force. Cover multiple force categories (regulatory, technology, social, economic). Frame forces as irreversible.

**Strengthen:**
- Force magnitude quantification: "$4.2B in regulatory compliance costs by 2028" not "increasing regulatory pressure."
- Multiple force categories present.
- Force interaction analysis: how forces amplify each other.
- Frame forces as irreversible (this is not a cycle, it is a structural shift).

**Do NOT:**
- Present forces without quantifying their magnitude.
- List forces without analyzing their interactions.

---

### Friction -- Element Rules

**Primary technique: Forcing Functions with barrier identification**

Friction is the analytical point of this element. Preserve and strengthen friction language -- do not smooth it away.

<before_after>
BEFORE (friction minimized):
"There are some challenges to overcome, but the industry is adapting."

AFTER (friction quantified):
"Three barriers slow the transformation. First, workforce retraining: 68% of current operators lack the digital skills the new model requires, and retraining takes 12-18 months at $15,000 per employee. Second, capital lock-in: $2.3B in legacy equipment has 5-8 years remaining on depreciation schedules. Third, regulatory lag: current frameworks were designed for the old model, and revised standards are 2-3 years from finalization."
</before_after>

**Strengthen:**
- Barrier specificity with quantified impact (cost, time, scale).
- Timing mismatches between forces and friction.
- Each barrier should have a specific metric attached.

**Do NOT:**
- Eliminate or soften friction language. Friction is the insight, not a problem to gloss over.
- Merge friction into the Forces element.

---

### Evolution -- Element Rules

**Primary technique: Contrast Structure (current vs. future)**

Contrast the current industry structure against the future equilibrium. Describe the new equilibrium, not just "change."

**Strengthen:**
- Current vs. future contrast with specific structural differences.
- Power shift quantification: who gains, who loses, by how much.
- Timeline to new equilibrium.
- Describe the new equilibrium state (not just "things will change").

**Do NOT:**
- Describe only the change process without defining the destination.
- Omit the timeline.

---

### Leadership -- Element Rules

**Primary technique: IS-DOES-MEANS with You-Phrasing**

Position for the new structure, not defense of the old. Apply You-Phrasing.

**Strengthen:**
- You-Phrasing: "You position..." not "Organizations should position..."
- Differentiation sources specific to the transformed industry.
- Compound impact Number Plays for the value of early positioning.

**Do NOT:**
- Frame leadership as defending the current position.
- Use third-person framing.

---

## Cross-Arc Techniques

These techniques apply to ALL arcs, every element. Strengthen them regardless of arc_id.

### Hook -- First-Sentence Rules (all arcs)

The hook is the reader's entry point. Every arc has a Hook element (the opening paragraphs before the first H2 arc element). The technique table assigns "Pyramid Principle + Hero number isolation" to every Hook. These rules specify HOW to strengthen the hook's first 1-2 sentences.

**First-sentence strategy (choose one based on arc and content):**
- **Surprise/Paradox:** A counterintuitive true statement from the research (e.g., "Success caused the crisis")
- **Main conclusion first:** The single most important finding, stated boldly
- **Provocative thesis:** A sharp claim that demands engagement

**First-sentence constraints:**
- Max 12 words (German) / 15 words (English)
- Main clause only -- no subordinate clauses, no appositional phrases
- No raw statistics as opener (transform into vivid statement first)
- Must pass the Kuechenzuruf test (German) or Kitchen Call-Out test (English): can the reader shout the gist to someone in the next room?
- Must not be a Binsenweisheit (platitude) or self-evident context

**Hero number isolation:**
- The hero number appears in sentence 2-3, not necessarily sentence 1
- It anchors the hook's credibility AFTER the opening creates interest
- The number grounds the surprising claim with evidence

**Hook quality tests (run all five):**

| Test | Pass Criterion | Fail Action |
|------|---------------|-------------|
| 12-word Hauptsatz | First sentence is max 12 words, main clause only | Shorten and simplify |
| Surprise or Hauptsache | Contains surprising truth or main conclusion | Find strongest sentence in paragraph, promote it (Schneider Regel 7) |
| No Binsenweisheit | Reader would NOT respond "Ja, und?" | Replace with concrete finding |
| Kuechenzuruf | Gist survives being shouted across a room | Sharpen core message |
| No raw statistics | Does not lead with unframed number | Transform number into vivid statement, move raw number to sentence 2-3 |

If the first sentence fails 3+ tests: restructure the opening 1-2 sentences (permitted under arc-preservation.md Section 7).
If the first sentence fails 1-2 tests: attempt revision within current structure.
If the first sentence passes all 5: strengthen language only (Power Words, rhythm).

For German documents, load `01-core-principles/german-hook-principles.md` for the full 12-rule system with before/after examples.

---

### Number Plays (all elements with quantitative claims)

- Replace every vague quantity ("many", "most", "significant", "substantial") with a specific number.
- Apply the arc-appropriate variant from the element's row in the technique table.
- When converting percentages, use ratio framing only when the ratio is more intuitive (e.g., "1 in 4" is better than "25%", but "87%" is better than "roughly 7 in 8").

### Power Words (headlines, opening sentences, CTAs)

- Strengthen verbs: helps -> enables, provides -> delivers, allows -> empowers, improves -> accelerates.
- Apply sparingly: 3-5 replacements per element maximum. Overuse dilutes impact.
- Never change heading text. Power words apply to body text only.

### Sentence Rhythm (transitions, element openings and closings)

- Vary sentence length within each paragraph.
- Pattern: After a long setup sentence (20-25 words), follow with a short punch (4-8 words). Example: "After eighteen months of pilot testing across four manufacturing sites, the results were conclusive. Defect rates dropped 94%."

### You-Phrasing (only elements marked in technique table)

- Convert third-person to direct address ONLY in elements whose technique table row includes "You-Phrasing."
- Pattern: "Organizations can reduce..." becomes "You reduce..."
- Do NOT apply You-Phrasing to analytical elements (Landscape, Signals) unless the technique table explicitly includes it.

### Citation Density (all elements)

- Target: 15-25 total citations across the full narrative.
- Never remove a citation. You may add citations if you have sourced evidence.
- Verify citation count is greater than or equal to the original after polishing.

---

## Post-Polish Validation

After polishing all elements, verify each one passes these checks. Process them in order. If any check fails, revert that element to its original text.

```
FOR EACH element IN arc:
  1. Heading text unchanged?                              [MANDATORY - revert if violated]
  2. Primary technique intact?                            [Check against technique table]
     - e.g., PSB pattern in Why Change, Forcing Functions in Why Now
  3. Number Play variant applied?                         [Check against technique table]
  4. Word count within target range?                      [Tolerance: +/- 50 words]
  5. Citation count >= original?                          [Count <sup> tags]
  6. Element serves its distinct purpose?                 [No blending between elements]
  7. You-Phrasing applied only where technique table specifies? [Check table]
```

If any check fails for an element, revert that element to its original text and log:
`fallback_reason="technique_check_failed" element="{element_name}" check="{check_number}"`
