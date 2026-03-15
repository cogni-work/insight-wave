# Phase 4b: Arc-Specific Insight Summary (strategic-foresight)

**Arc Framework:** Signals -> Scenarios -> Strategies -> Decisions
**Arc:** `strategic-foresight` (Tier 3) | **Output:** `insight-summary.md` at project root (target range from `--target-length`, default ~1,675 words)

**Shared steps:** Read [shared-steps.md](shared-steps.md) for entity counting, output template, validation gates, and write instructions.

---

## Arc-Specific Headers

**English:**
- `## Signals: Early Indicators`
- `## Scenarios: Future States`
- `## Strategies: Adaptive Approaches`
- `## Decisions: Action Framework`

**German (if `language: de`):**
- `## Signale: Frühindikatoren`
- `## Szenarien: Zukunftsbilder`
- `## Strategien: Adaptive Ansätze`
- `## Entscheidungen: Handlungsrahmen`

---

## Step 4.1.1: Load Evidence Entities (Context Tier 3)

Each entity type contributes differently to this arc:

- **Findings** serve as the evidence backbone. Categorize by element: anomalies/patterns -> Signals, structural drivers -> Scenarios (as axes), capabilities/actions -> Strategies, timing/urgency -> Decisions.
- **Sources** establish credibility for forward-looking assertions, not just retrospective analysis.
- **Trends across all planning horizons** are the primary differentiator for Tier 3. Group by `planning_horizon`: "Watch" trends feed Signals, "Act" trends feed Decisions, all trends inform Scenarios. Identify contradictory trend pairs -- these become scenario axes.
- **Megatrends** (if present in `06-megatrends/data/`) generate scenario axes. Think: "Which 2-3 megatrends create the most divergent futures when their extremes are combined?"

**Load:**
- Top 20 findings from `04-findings/data/` (quality_score >= 0.65)
- Top 15 sources from `07-sources/data/` (reliability_score >= 0.8)
- Dimension-scoped trends from `11-trends/data/` (all planning horizons)
- Megatrends from `06-megatrends/data/` (if present)

**Verify sufficient material:**
- At least 3-4 "Watch" trends for Signals
- At least 2 megatrends or macro-level trends for scenario axes
- At least 8 findings with quality_score >= 0.65
- If any category is thin, lean more on synthesis content for that element

---

## Step 4.1.4: Extended Thinking Sub-steps

---

### Sub-step A: Internalize the Source Material

Read `synthesis-cross-dimensional.md`. Before writing:

1. **Core thesis?** One sentence -- this anchors all 4 elements.
2. **Research question?** Becomes subtitle and frames the hook.
3. **2-3 most surprising findings?** Candidates for Signals and the opening hook.
4. **Tensions or contradictions?** These become scenario axes.
5. **Practical implications?** Feed Strategies and Decisions.

---

### Sub-step B: Map Evidence to Arc Elements

**Signals (Weak Signals and Early Indicators):**
- Which findings describe *emerging* patterns (not established ones)?
- Which trends have "Watch" or distant planning horizon?
- Which data points are counterintuitive? Weak signals often appear as anomalies.
- Target: 3-5 distinct signals, each grounded in at least one entity.

**Scenarios (Alternative Future States):**
- Select 2 megatrends (or major macro-trends) as scenario axes. Their cross-product yields 2-3 distinct scenarios.
- A scenario is credible when short-term "Act" trends and long-term "Watch" trends both point toward it.
- Scenarios must be genuinely divergent (incompatible futures), not variations on the same theme.

**Strategies (Robust Actions):**
- Which actions work across *all* scenarios? These are "no-regret moves."
- Which actions increase flexibility without committing to one scenario? These are "option-creating moves."
- Strategies must reference scenarios by name to demonstrate robustness analysis.

**Decisions (Near-Term Choices):**
- What must be decided *now* (before uncertainty resolves)?
- For each decision: what trigger signal would indicate it's time to escalate?
- Assess reversibility: easily reversible = low risk to act now; irreversible = worth waiting for more signal clarity.
- Decisions connect back to Strategies as concrete "first moves."

---

### Sub-step C: Construct the Narrative Hook

The hook (~10% of target length) establishes *genuine uncertainty*:

- Pattern: "[Signal 1] suggests [future A]. [Signal 2] suggests [future B]. [Signal 3] makes both plausible."
- The reader should feel that *not thinking about multiple futures* is a strategic risk.
- Ground with 1-2 citations from strongest findings.

---

### Sub-step D: Draft Each Arc Element

**Signals: Early Indicators (~21% of target length)**
- Present each signal as an observed data point, not an opinion
- Quantify directional change where possible
- Frame signals as "stress fractures" or "early indicators," not established trends
- Show at least one pair of contradictory signals to establish genuine uncertainty
- 8-12 wikilinks to trend and finding entities

*Transition:* "These signals combine into [N] plausible scenarios."

**Scenarios: Future States (~27% of target length)**
- Name each scenario distinctively (e.g., "Platform Capitalism," not "Scenario 1")
- Build each from signal combinations established in Signals
- Use megatrends as structural axes -- state explicitly (e.g., "Axis: Data Sovereignty Stringency -- Low vs. High")
- Show how trends from different planning horizons converge in each scenario
- For each scenario, state one concrete organizational implication
- 8-12 wikilinks

*Transition:* "Robust strategies create value regardless of which scenario unfolds."

**Strategies: Adaptive Approaches (~24% of target length)**
- Categorize: no-regret moves, option-creating moves, scenario-specific hedges
- For each strategy, state which scenarios it serves
- Ground in findings that demonstrate feasibility or precedent
- 8-12 wikilinks

*Transition:* "Executing robust strategies requires near-term decisions about [areas]."

**Decisions: Action Framework (~18% of target length)**
- Frame as time-bound choices with decision triggers
- For each: what to decide, when, what trigger, is it reversible?
- Connect each decision to the strategies it enables
- Close with: "The goal isn't predicting which future arrives -- it's building capability to thrive in any of them."
- 8-12 wikilinks

---

### Sub-step E: Generate the Title

The title should reference the *domain* of uncertainty, not just the topic:
- Imply multiple futures (foresight framing), not a single prediction
- Test: does it make a reader curious about *which* future will unfold?

---

### Sub-step F: Self-Review

1. **Narrative coherence:** Would someone skipping to Strategies understand which scenarios they reference?
2. **Foresight integrity:** Are scenarios genuinely divergent? Can you merge two without contradiction? If so, they're not divergent enough.
3. **Evidence density:** Can you point to a specific entity for every major claim?
4. **Wikilinks:** 40-50 total, distributed across elements?
5. **Word count:** Within target length range? Hook ~10%, Signals ~21%, Scenarios ~27%, Strategies ~24%, Decisions ~18%?

**Common failure mode:** Scenarios not divergent is the most frequent issue. Revisit megatrend axis selection if scenarios feel like variations on the same theme.

Now proceed to validation and write steps in [shared-steps.md](shared-steps.md).
