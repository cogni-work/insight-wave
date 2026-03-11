# Phase 1: Build Relationship Networks & Strategic Themes

## Objective

Two-pass architecture: First, build granular T→I→P value chains via semantic affinity
analysis (bottom-up). Then consolidate chains into 3-7 MECE Strategic Themes — the
distinct investment domains where this customer should allocate budget and executive
attention (top-down).

## Why Two Passes?

Building fine-grained causal chains is analytically rigorous — you need T→I→P reasoning
to ensure connections are real, not thematic hand-waving. But presenting 8-15 granular
chains to a CxO produces a flat, overwhelming list where overlapping chains generate
redundant solutions.

The consolidation pass solves this: chains that answer the same strategic question get
grouped into a single theme. The customer sees 5 investment areas, not 11 threads. Each
theme is a distinct budget decision with a clear executive owner.

## Dimension-to-TIPS Role Mapping

| Dimension | Primary TIPS Role | Contains |
|-----------|------------------|----------|
| `externe-effekte` | **T** (Trends) | External forces: market, regulatory, societal |
| `digitale-wertetreiber` | **I** (Implications) | Value impact: CX, products, processes |
| `neue-horizonte` | **P** (Possibilities) | Strategic opportunities: strategy, leadership, governance |
| `digitales-fundament` | **Foundation** | Enabling capabilities: culture, people, technology |

Note: `digitales-fundament` candidates are enablers, not Solutions in the patent sense.
They serve as constraints or prerequisites that inform Solution Templates but don't map
directly to TIPS value chains. They will be used in Phase 2 as "foundation requirements."

---

## PASS 1: Bottom-Up Value Chain Construction

### Step 1: Candidate Analysis

For each of the 60 candidates, extract:
- Its dimension (determines TIPS role)
- Its subcategory and horizon
- Its trend statement and keywords
- Its score and confidence tier

**candidate_ref format:** Use the format from the trend-scout output as-is. This is
typically `{dimension}/{horizon}/{number}` (e.g., `externe-effekte/act/1`) but may vary
by project. Preserve whatever format the source data uses — don't normalize.

Group candidates by dimension:
- T-pool: all `externe-effekte` candidates (typically 13)
- I-pool: all `digitale-wertetreiber` candidates (typically 13)
- P-pool: all `neue-horizonte` candidates (typically 13)
- Foundation-pool: all `digitales-fundament` candidates (typically 13)

### Step 2: Semantic Affinity Analysis

Use extended thinking to analyze semantic connections between candidates across dimensions.
For each T candidate, identify which I candidates it logically drives, and which P candidates
those implications enable.

**Connection criteria (ALL must hold for a link to be valid):**
- **Causal link**: The Trend *directly* creates or amplifies the Implication — you should be
  able to explain the mechanism in one sentence ("Because X regulation tightens, companies
  must invest in Y capability"). If you need a paragraph to justify the connection, it's too weak.
- **Operational coherence**: The I candidate must describe an operational impact that a company
  *in this specific industry* would face as a direct consequence of the T candidate. Generic
  business connections (e.g., "regulation → M&A activity") are too loose.
- **Possibility as response**: The P candidate must be a strategic response that *addresses*
  the implication — not just a thematically related market development. Test: would a company
  experiencing the I problem plausibly pursue P as their response?
- **Keyword overlap**: Shared keywords or themes reinforce the link, but are not sufficient alone.
- **Horizon alignment**: Prefer progressive horizons (act→act, act→plan, plan→plan, plan→observe).
  Never link observe→act. Same-horizon links are strongest.

**Anti-patterns to avoid:**
- **Forced connections**: If you can't explain T→I causality in one sentence, don't link them.
  It's better to leave a candidate orphaned than to create a weak chain. Orphans are honest;
  weak chains are misleading.
- **Thematic-only grouping**: "Both are about food" or "both mention AI" is not a causal link.
  The T must *cause* the I, and the I must *motivate* the P.
- **M&A as possibility**: Large corporate deals (acquisitions, mergers) are market events, not
  strategic possibilities a customer can pursue. Use them as Trends, not Possibilities.
- Creating circular paths (T→I→P where P causes T)
- Connecting every candidate to every other (chains should be selective)
- Ignoring horizon progression (an "observe" Trend shouldn't drive an "act" Implication)

### Step 3: Build Value Chains

Construct all valid T→I→P value chains. Each chain:

1. **Starts with a Trend** (from `externe-effekte`)
2. **Flows through 1-3 Implications** (from `digitale-wertetreiber`)
3. **Arrives at 1-2 Possibilities** (from `neue-horizonte`)
4. Has a **human-readable narrative** explaining the causal chain in 2-3 sentences

**Aim for rich chains.** A chain with T=1 I=1 P=1 is the minimum — it works but produces
weak F1 differentiation because there are only 3 data points. Prefer chains with 2+ Implications
where a Trend has multiple operational impacts, or 2 Possibilities where an Implication opens
different strategic responses. The richer the chain, the more nuanced the ranking becomes.
A good target is an average of 4-5 TIPs per chain (T=1 I=2 P=1 or T=1 I=1 P=2).

**Chain naming:** Give each chain a descriptive name (3-5 words) that captures the causal story.

**Coverage targets:**
- Each T candidate should appear in at least 1 chain (ideally 1-2)
- Each I candidate should appear in at least 1 chain
- Each P candidate should appear in at least 1 chain
- Some candidates may appear in multiple chains — this is expected and desirable
- Not every candidate needs to be in a chain — orphans are noted but acceptable

**Foundation tagging:** For each chain, identify which `digitales-fundament` candidates
are prerequisites. Tag them as `foundation_requirements` on the chain:

```json
{
  "chain_id": "vc-001",
  "foundation_requirements": [
    {
      "candidate_ref": "digitales-fundament/act/2",
      "name": "Data Infrastructure Maturity",
      "relationship": "prerequisite"
    }
  ]
}
```

At this point you'll typically have 8-15 value chains. That's expected — don't reduce yet.

### Step 3.5: Coverage Recovery

Before moving to consolidation, check candidate coverage. Count how many of the 45
T/I/P candidates (excluding Foundation) appear in at least one chain.

**If coverage is below 80%**, review the orphaned candidates — especially act and plan
horizon ones. For each orphan:

1. **Act-horizon orphans**: These represent current forces or capabilities. Try harder
   to find causal connections. If an act-horizon trend can't connect to any implication,
   that's suspicious — reconsider whether you were too strict on a borderline connection.
2. **Plan-horizon orphans**: These represent emerging developments. Look for chains where
   they could serve as a second Implication or second Possibility. A plan-horizon candidate
   that enriches an existing chain is valuable even if it wouldn't justify its own chain.
3. **Observe-horizon orphans**: These are speculative and pre-commercial. Leaving them
   orphaned is usually honest and correct — don't force connections just to hit a number.

If after this review coverage is still below 80%, that's acceptable — document why in
the orphan list. The goal is ≥80% with honest connections, not 80% with forced ones.

---

## PASS 2: Top-Down Strategic Theme Consolidation

This is where the MECE discipline turns a list of chains into a structured investment strategy.

### Step 4: Identify Natural Clusters

Analyze the value chains from Step 3 and look for chains that converge:

**Clustering signals — chains should merge when they share:**
1. **Same "so what?"** — If two chains lead to the same executive decision ("we need to invest
   in X"), they belong in one theme. Test: would you present these to the same CxO in the same
   meeting agenda item?
2. **Solution overlap** — If the chains would naturally produce overlapping Solution Templates
   (same platforms, same capabilities), they belong together.
3. **Candidate overlap** — If chains share >40% of their T/I/P candidates, they're telling
   variants of the same story.
4. **Same buyer** — If a CxO would own both chains with one budget, merge them.

**Splitting signals — a cluster should split when:**
1. **Competing solutions** — If the cluster produces STs that are alternatives (not complements),
   they represent different strategic bets and need separate themes.
2. **Different time horizons** — If one half is "act now" and the other is "observe," consider
   splitting so urgency is clear.
3. **Different value propositions** — If you'd pitch them to fundamentally different buyers
   (CFO vs CTO vs CPO), they're separate themes.

### Step 5: Form Strategic Themes

Create 3-7 themes. Each theme:

1. **Groups 1-4 value chains** that share the same strategic direction
2. Has a **name** (3-5 words): the investment area, not the megatrend.
   Good: "Smart Manufacturing & Supply Chain Resilience"
   Bad: "Digitalization" (too broad — that's the megatrend, not the investment)
3. Has a **strategic question** it answers for the customer — the decision this theme forces.
   Example: "How do we modernize production while de-risking our supply chain?"
4. Has an **executive sponsor type** — who would own this in the customer's org.
   Example: "COO / VP Operations"
5. Has a **theme narrative** (2-3 sentences) explaining why these chains belong together
   and what the unified investment thesis is.

**The 3-5-7 target:**
- **3 themes**: Minimum viable strategy. Use for focused engagements, narrow candidate pools
  (<40 candidates), or when the industry is highly concentrated.
- **5 themes**: Sweet spot. Cognitively manageable, enough breadth for enterprise accounts.
  Each theme is like a finger — you can hold the whole strategy in one hand.
- **7 themes**: Hard maximum (Miller's law: 7±2 chunks). Only for large, complex enterprises
  with diverse business units spanning multiple subsectors.

Choose the target based on:
- Number of distinct industry subsectors in the candidate pool
- Breadth and diversity of the T/I/P candidates
- Customer organizational complexity (more BUs → more themes)
- Default to 5 unless there's a clear reason to deviate.

**Quality over count.** 4 strong themes with solid causal chains beats 5 themes where
one has forced connections. If you find yourself stretching chains to fill a theme — using
a regulatory trend as a production driver, or a pricing trend as a workforce trigger — that's
a signal the theme isn't warranted. Drop it and redistribute any legitimate chains to
neighboring themes. The customer is better served by 4 sharp themes than 5 blurry ones.

### Step 6: MECE Validation

Before presenting, verify the themes satisfy MECE:

**Mutual Exclusivity check:**
- For each pair of themes, ask: "Would a CxO confuse these? Would they fund both from the
  same budget line?" If yes → merge.
- Each Solution Template (mentally anticipated, not yet generated) should clearly belong to
  one primary theme. If an ST would naturally serve two themes equally, the themes may need merging.

**Collective Exhaustiveness check:**
- Count how many of the 45 T/I/P candidates (excluding Foundation) appear in at least one
  chain within a theme. Target ≥80% coverage.
- If major candidate clusters are orphaned (not covered by any theme), consider whether a
  theme is missing or whether those candidates are genuinely low-relevance outliers.

**Balance check:**
- No single theme should contain >50% of all chains (probably too broad — split it).
- No theme should have 0 chains (empty themes aren't themes).
- Aim for roughly even distribution, but don't force symmetry — some themes naturally have
  more chains than others.

---

## Step 7: Present to User

Present the Strategic Themes as the primary output, with chains nested beneath:

```markdown
## Strategic Themes (TIPS Value Model)

### Theme 1: Health & Nutrition Transformation
**Strategic Question:** How do we reformulate our portfolio for the health-conscious, GLP-1-era consumer?
**Executive Sponsor:** CPO / Head of Product Development

GLP-1 medications and functional food demand are fundamentally reshaping what consumers want.
This theme covers reformulation, personalization, and nutritional innovation.

**Value Chains:**

#### VC-1: GLP-1 Portfolio Reformulation
T: GLP-1 Market Impact (act, 0.85) → I: Personalized Digital Experiences (act, 0.78),
AI Recommendation Engines (act, 0.75) → P: GLP-1 Portfolio Reformulation (act, 0.72)
Foundation: AI/ML Engineer Demand

#### VC-2: Functional Ingredients Innovation
T: Functional Food Demand Growth (act, 0.80) → I: Consumer Health Profiling (plan, 0.68)
→ P: Functional Product Line Extension (plan, 0.65)
Foundation: Food Scientist Shortage

---

### Theme 2: Regulatory Compliance & Sustainable Packaging
...
```

Also report:
- Total themes formed and total value chains
- Coverage: how many candidates are linked vs orphaned
- MECE validation result (pass/issues)
- Any candidates that couldn't be meaningfully connected (orphans)

Ask the user: "Do these Strategic Themes make sense for your customer? Each theme represents
a distinct investment area. Want to adjust, merge, or split any themes before I generate
Solution Templates?"

## Output

Save to `tips-value-model.json` (create or update):

```json
{
  "version": "2.0.0",
  "project_id": "{project-slug}",
  "themes": [
    {
      "theme_id": "theme-001",
      "name": "Health & Nutrition Transformation",
      "strategic_question": "How do we reformulate our portfolio for the health-conscious, GLP-1-era consumer?",
      "executive_sponsor_type": "CPO / Head of Product Development",
      "narrative": "GLP-1 medications and functional food demand are fundamentally reshaping consumer expectations...",
      "value_chains": ["vc-001", "vc-002"],
      "solution_templates": [],
      "business_relevance_avg": null,
      "ranking_value": null
    }
  ],
  "value_chains": [
    {
      "chain_id": "vc-001",
      "name": "GLP-1 Portfolio Reformulation",
      "theme_ref": "theme-001",
      "narrative": "...",
      "trend": { "candidate_ref": "...", "name": "...", "business_relevance": null },
      "implications": [
        { "candidate_ref": "...", "name": "...", "business_relevance": null }
      ],
      "possibilities": [
        { "candidate_ref": "...", "name": "...", "business_relevance": null }
      ],
      "foundation_requirements": [
        { "candidate_ref": "...", "name": "...", "relationship": "prerequisite" }
      ],
      "solution_templates": []
    }
  ],
  "orphan_candidates": ["digitale-wertetreiber/observe/3"],
  "coverage": {
    "linked": 48,
    "orphaned": 4,
    "total": 60,
    "coverage_pct": 0.923
  },
  "mece_validation": {
    "theme_count": 5,
    "mutual_exclusivity": "pass",
    "collective_exhaustiveness_pct": 0.87,
    "balance": "pass"
  }
}
```

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"themes-built"`
- Add `"phase-1"` to `phases_completed`
- Record `theme_count`, `chain_count`, and `coverage_pct`
