# Phase 1: Build Relationship Networks

## Objective

Analyze the 52 agreed candidates across all 4 dimensions and build TIPS paths — coherent
Trend → Implication → Possibility chains that form "value stories."

## Why Relationships Matter

The patent's core insight: trends alone don't tell you what to do. A Trend becomes actionable
only when you trace its Implications (what it means for your business) and connect those to
Possibilities (how you can capitalize). This chain is the relationship network — the reasoning
backbone that makes solution selection systematic rather than ad-hoc.

## Dimension-to-TIPS Role Mapping

| Dimension | Primary TIPS Role | Contains |
|-----------|------------------|----------|
| `externe-effekte` | **T** (Trends) | External forces: market, regulatory, societal |
| `digitale-wertetreiber` | **I** (Implications) | Value impact: CX, products, processes |
| `neue-horizonte` | **P** (Possibilities) | Strategic opportunities: strategy, leadership, governance |
| `digitales-fundament` | **Foundation** | Enabling capabilities: culture, people, technology |

Note: `digitales-fundament` candidates are enablers, not Solutions in the patent sense.
They serve as constraints or prerequisites that inform Solution Templates but don't map
directly to TIPS paths. They will be used in Phase 2 as "foundation requirements."

## Step 1: Candidate Analysis

For each of the 52 candidates, extract:
- Its dimension (determines TIPS role)
- Its subcategory and horizon
- Its trend statement and keywords
- Its score and confidence tier

Group candidates by dimension:
- T-pool: all `externe-effekte` candidates (typically 13)
- I-pool: all `digitale-wertetreiber` candidates (typically 13)
- P-pool: all `neue-horizonte` candidates (typically 13)
- Foundation-pool: all `digitales-fundament` candidates (typically 13)

## Step 2: Semantic Affinity Analysis

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
  It's better to leave a candidate orphaned than to create a weak path. Orphans are honest;
  weak paths are misleading.
- **Thematic-only grouping**: "Both are about food" or "both mention AI" is not a causal link.
  The T must *cause* the I, and the I must *motivate* the P.
- **M&A as possibility**: Large corporate deals (acquisitions, mergers) are market events, not
  strategic possibilities a customer can pursue. Use them as Trends, not Possibilities.
- Creating circular paths (T→I→P where P causes T)
- Connecting every candidate to every other (paths should be selective)
- Ignoring horizon progression (an "observe" Trend shouldn't drive an "act" Implication)

## Step 3: Build TIPS Paths

Construct 8-15 TIPS paths. Each path:

1. **Starts with a Trend** (from `externe-effekte`)
2. **Flows through 1-3 Implications** (from `digitale-wertetreiber`)
3. **Arrives at 1-2 Possibilities** (from `neue-horizonte`)
4. Has a **human-readable narrative** explaining the chain in 2-3 sentences

**Aim for rich paths.** A path with T=1 I=1 P=1 is the minimum — it works but produces
weak F1 differentiation because there are only 3 data points. Prefer paths with 2+ Implications
where a Trend has multiple operational impacts, or 2 Possibilities where an Implication opens
different strategic responses. The richer the path, the more nuanced the ranking becomes.
A good target is an average of 4-5 TIPs per path (T=1 I=2 P=1 or T=1 I=1 P=2).

**Path naming:** Give each path a descriptive name (3-5 words) that captures the value story.

**Coverage targets:**
- Each T candidate should appear in at least 1 path (ideally 1-2)
- Each I candidate should appear in at least 1 path
- Each P candidate should appear in at least 1 path
- Some candidates may appear in multiple paths — this is expected and desirable
- Not every candidate needs to be in a path — orphans are noted but acceptable

**Foundation tagging:** For each path, identify which `digitales-fundament` candidates
are prerequisites. Tag them as `foundation_requirements` on the path:

```json
{
  "path_id": "path-001",
  "foundation_requirements": [
    {
      "candidate_ref": "digitales-fundament/act/2",
      "name": "Data Infrastructure Maturity",
      "relationship": "prerequisite"
    }
  ]
}
```

## Step 4: Validate & Present

Present the paths to the user in a readable format:

```markdown
## TIPS Relationship Networks

### Path 1: AI-Driven Quality Optimization
**Narrative:** Tightening EU quality standards (T) expose gaps in real-time defect
detection capabilities (I), creating opportunity for predictive quality management (P).

| Role | Candidate | Horizon | Score |
|------|-----------|---------|-------|
| T | EU Quality Standards Tightening | act | 0.85 |
| I | Real-time Defect Detection Gap | act | 0.78 |
| P | Predictive Quality Management | plan | 0.72 |

**Foundation requires:** Data Infrastructure Maturity, ML Engineering Talent
```

Also report:
- Total paths built
- Coverage: how many candidates are linked vs orphaned
- Any candidates that couldn't be meaningfully connected (orphans)

Ask the user: "Do these relationship networks make sense? Want to adjust any paths
before I generate Solution Templates?"

## Output

Save to `tips-value-model.json` (create or update):

```json
{
  "version": "1.0.0",
  "project_id": "{project-slug}",
  "paths": [
    {
      "path_id": "path-001",
      "name": "AI-Driven Quality Optimization",
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
    "total": 52,
    "coverage_pct": 0.923
  }
}
```

Update `.metadata/value-modeler-output.json`:
- Set `workflow_state` to `"paths-built"`
- Add `"phase-1"` to `phases_completed`
- Record `path_count` and `coverage_pct`
