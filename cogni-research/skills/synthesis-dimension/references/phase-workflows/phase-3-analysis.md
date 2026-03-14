# Phase 3: Pattern Analysis

## Objective

Extract patterns, identify cross-trend connections, and assess evidence quality to inform synthesis structure.

## Prerequisites (Gate Check)

Before starting Phase 3, verify:

- Phase 2 completed successfully
- All trends loaded into TRENDS registry
- All claims loaded into CLAIMS registry
- Dimension context understood
- Verification checkpoint passed

**IF MISSING: STOP. Return to Phase 2.**

---

## TodoWrite Expansion

When entering Phase 3, expand to these step-level todos:

```text
3.1 Identify thematic clusters [in_progress]
3.1b Group trends by planning horizon [pending]
3.2 Map cross-trend connections [pending]
3.3 Calculate evidence quality metrics [pending]
3.4 Extract strategic implications [pending]
3.5 Detect tensions and contradictions [pending]
3.6 Rank trends by importance [pending]
3.7 Arc element evidence classification (if ARC_ID set) [pending]
```

---

## Step 3.1: Identify Thematic Clusters

**Action:** Group trends by common themes.

**Analysis approach:**

1. Review each trend's title and key content
2. Identify shared vocabulary and concepts
3. Group trends that address related topics

---

## Step 3.1b: Planning Horizon Grouping (NEW)

**Action:** Group trends by planning_horizon field for structured synthesis.

**Process:**

1. Iterate through TRENDS registry
2. Group by planning_horizon:
   - `act_trends` - planning_horizon="act" (0-6 months, immediate action)
   - `plan_trends` - planning_horizon="plan" (6-18 months, capability building)
   - `observe_trends` - planning_horizon="observe" (18+ months, emerging trends)
3. Within each group, maintain TREND_RANKING order (highest scored first)

**Output:**

```text
PLANNING_HORIZON_GROUPS = {
  act: [trend1, trend2],
  plan: [trend3, trend4],
  observe: [trend5]
}
```

**Purpose:** Enable Key Trends section to be structured as Act/Plan/Observe subsections.

**Verification:** All trends assigned to a planning horizon group.

**Example clusters for governance dimension:**

```text
THEMATIC_CLUSTERS = {
  "governance_structure": [
    "trend-transformation-office-governance",
    "trend-stakeholder-management"
  ],
  "execution_framework": [
    "trend-phasenmodell-meilensteine",
    "trend-quick-wins-momentum"
  ],
  "measurement": [
    "trend-kpi-erfolgsmessung"
  ]
}
```

**Output:** Thematic cluster mapping with trend IDs.

**Verification:** Each trend assigned to at least one cluster.

---

## Step 3.2: Map Cross-Trend Connections

**Action:** Identify relationships between trends.

**Connection types:**

| Type | Description | Example |
| ---- | ----------- | ------- |
| `shared_claims` | Trends reference same claim | Trend A and B both cite claim-123 |
| `causal` | One trend enables/requires another | Governance enables KPI measurement |
| `complementary` | Trends address different aspects of same topic | Structure + Process |
| `sequential` | Time-based relationship | Quick wins before scale |
| `tension` | Trends present different perspectives | Speed vs. quality |

**Build connection map:**

```text
CONNECTIONS = [
  {
    trend_a: "trend-transformation-office-governance",
    trend_b: "trend-stakeholder-management",
    type: "complementary",
    strength: "strong",
    description: "Governance structure enables stakeholder orchestration"
  },
  {
    trend_a: "trend-quick-wins-momentum",
    trend_b: "trend-phasenmodell-meilensteine",
    type: "sequential",
    strength: "strong",
    description: "Quick wins in Phase 1 build momentum for Phase 2"
  },
  ...
]
```

**Metrics:**

- Total connections identified
- Strong connections: connections with strength="strong"

**Verification:** At least N-1 connections for N trends (connected graph).

---

## Step 3.3: Calculate Evidence Quality Metrics

**Action:** Aggregate quality metrics across dimension.

**Metrics to calculate:**

| Metric | Calculation | Purpose |
| ------ | ----------- | ------- |
| `avg_trend_confidence` | Mean of trend_confidence values | Overall reliability |
| `avg_quality_score` | Mean of quality_scores.composite | Evidence strength |
| `total_claims` | Count of unique claims | Evidence depth |
| `avg_claim_confidence` | Mean of claim confidence_scores | Claim reliability |
| `evidence_freshness` | Check oldest_evidence_date values | Timeliness |

**Example output:**

```text
QUALITY_METRICS = {
  avg_trend_confidence: 0.81,
  avg_quality_score: 0.80,
  total_claims: 14,
  avg_claim_confidence: 0.82,
  evidence_freshness: "current",
  oldest_evidence: "2026-01-09",

  // Component quality scores (NEW)
  avg_evidence_strength: 0.82,
  avg_strategic_relevance: 0.85,
  avg_actionability: 0.78,
  avg_novelty: 0.75,

  // Verification status breakdown (NEW)
  verification_rate: 0.82,  // percentage of verified claims
  verification_breakdown: {
    verified: 11,
    partially_verified: 2,
    unverified: 1,
    contradicted: 0
  },

  // Source reliability distribution (NEW)
  source_tier_distribution: {
    tier_1: 8,
    tier_2: 5,
    tier_3: 2,
    tier_4: 0,
    unknown: 1
  }
}
```

**Calculation notes:**

- **Component quality scores:** Calculate mean of quality_scores.evidence_strength, strategic_relevance, actionability, novelty across all trends
- **Verification rate:** Count claims where verification_status="verified", divide by total claims
- **Verification breakdown:** Count claims by verification_status category
- **Source tier distribution:** Count sources by reliability_tier from SOURCE_RELIABILITY_MAP

**Verification:** All metrics calculated with valid values.

---

## Step 3.4: Extract Strategic Implications

**Action:** Identify patterns in implications across trends.

**Review each trend's Implications section:**

- Strategic implications (decision-makers)
- Operational implications (practitioners)
- Technical implications (if applicable)

**Identify common themes:**

```text
STRATEGIC_PATTERNS = {
  resource_allocation: [
    "Dedicated Transformation Office required",
    "Investment in change management capabilities"
  ],
  risk_mitigation: [
    "Phased approach reduces implementation risk",
    "Quick wins build organizational confidence"
  ],
  capability_building: [
    "Multi-level stakeholder engagement",
    "OKR competency as foundation"
  ]
}
```

**Calculate strategic_score (0.0-1.0) for each trend:**

Based on implications section content, assign numeric score:

| Implications Assessment | strategic_score |
| ----------------------- | --------------- |
| High strategic relevance (C-level decisions, resource allocation) | 0.85-1.0 |
| Medium strategic relevance (operational changes, process updates) | 0.55-0.84 |
| Low strategic relevance (tactical adjustments, documentation) | 0.25-0.54 |
| Minimal strategic relevance (informational only) | 0.0-0.24 |

**Store for each trend:**

```text
TRENDS[i].strategic_score = 0.XX  # Based on implications assessment
```

**Verification:** Strategic patterns extracted from all trends, strategic_score assigned to each trend.

---

## Step 3.5: Detect Tensions and Contradictions

**Action:** Identify any conflicts or tensions between trends.

**Check for:**

1. **Contradictory claims** - Claims that present opposing views
2. **Resource tensions** - Competing priorities for limited resources
3. **Timeline conflicts** - Incompatible scheduling recommendations
4. **Methodology disputes** - Different approaches to same problem

**Document tensions:**

```text
TENSIONS = [
  {
    description: "Speed vs. thoroughness in stakeholder engagement",
    trend_a: "trend-quick-wins-momentum",
    trend_b: "trend-stakeholder-management",
    resolution: "Phased approach addresses both - quick wins maintain speed while building comprehensive engagement"
  }
]
```

**If no tensions found:**

```text
TENSIONS = []
TENSION_STATUS = "No material contradictions identified"
```

**Verification:** Tensions documented or explicitly noted as absent.

---

## Step 3.6: Rank Trends by Importance

**Action:** Prioritize trends for synthesis emphasis.

**Ranking criteria:**

| Criterion | Weight | Description |
| --------- | ------ | ----------- |
| Confidence | 0.3 | Higher confidence = more emphasis |
| Connection count | 0.25 | More connections = central to dimension |
| Claim count | 0.2 | More evidence = stronger foundation |
| Strategic relevance | 0.25 | Based on implications section |

**Calculate composite score:**

```text
For each trend:
  score = (confidence * 0.3) + (connections/max_connections * 0.25) +
          (claims/max_claims * 0.2) + (strategic_score * 0.25)
```

**Rank trends:**

```text
TREND_RANKING = [
  { id: "trend-transformation-office-governance", score: 0.87, rank: 1 },
  { id: "trend-kpi-erfolgsmessung", score: 0.84, rank: 2 },
  { id: "trend-phasenmodell-meilensteine", score: 0.82, rank: 3 },
  { id: "trend-stakeholder-management", score: 0.79, rank: 4 },
  { id: "trend-quick-wins-momentum", score: 0.77, rank: 5 }
]
```

**Verification:** All trends ranked with composite scores.

---

## Step 3.7: Arc Element Evidence Classification (Conditional)

**Condition:** Only execute when `ARC_ID` is non-empty (set in Phase 1 Step 1.5b). If ARC_ID is empty, skip this step entirely.

**Action:** Classify each trend and claim into the arc element it best serves, using the loaded arc template's signal words and planning horizon affinities.

**Prerequisites:**

- ARC_ID set and arc template loaded (from Phase 1 Step 1.5b)
- TRENDS registry populated (from Phase 2)
- PLANNING_HORIZON_GROUPS established (from Step 3.1b)
- TREND_RANKING calculated (from Step 3.6)

**Classification Algorithm:**

For each trend, calculate an affinity score against each of the 4 arc elements:

```text
For each trend T:
  For each arc element E (1-4):
    signal_score = count_signal_word_matches(T.title + T.description + T.key_claims, E.signal_words) / max_possible_matches
    horizon_score = 1.0 if T.planning_horizon in E.primary_horizon else
                    0.5 if T.planning_horizon in E.secondary_horizon else 0.0
    semantic_score = assess_conceptual_alignment(T.content, E.purpose)  # 0.0-1.0

    affinity = (signal_score * 0.4) + (horizon_score * 0.35) + (semantic_score * 0.25)

  Assign T to element with highest affinity score
  Break ties by: element with fewer assigned trends (balance preference)
```

**Claim classification:**

- Claims inherit their parent trend's arc element assignment
- Multi-parent claims: classify by claim content against element signal words

**Balance check:**

After initial classification, verify each element has at least one trend:

```text
For each arc element E:
  if count(E.trends) == 0:
    log WARNING "Arc element '{E.name}' has zero trends — redistributing"
    # Move lowest-scoring trend from element with most trends
    source_element = element with max(count(trends))
    moved_trend = source_element.trends.pop(lowest_affinity_score)
    E.trends.append(moved_trend)
```

**Output:**

```text
ARC_ELEMENT_MAP = {
  element_1: {
    name: "Why Change",
    trend_ids: ["trend-abc", "trend-def"],
    claim_ids: ["claim-123", "claim-456"],
    total_trends: 2,
    total_claims: 4
  },
  element_2: {
    name: "Why Now",
    trend_ids: ["trend-ghi"],
    claim_ids: ["claim-789"],
    total_trends: 1,
    total_claims: 2
  },
  element_3: {
    name: "Why You",
    trend_ids: ["trend-jkl", "trend-mno"],
    claim_ids: ["claim-012", "claim-345"],
    total_trends: 2,
    total_claims: 3
  },
  element_4: {
    name: "Why Pay",
    trend_ids: ["trend-pqr"],
    claim_ids: ["claim-678"],
    total_trends: 1,
    total_claims: 2
  }
}
```

**Verification:** All trends assigned to exactly one arc element. No element has zero trends (after rebalancing). ARC_ELEMENT_MAP contains 4 elements with trend-ids and claim-ids.

---

## Phase 3 Outputs

- `THEMATIC_CLUSTERS` - Trend groupings by theme
- `PLANNING_HORIZON_GROUPS` - Trends grouped by act/plan/observe
- `CONNECTIONS` - Cross-trend relationship map
- `QUALITY_METRICS` - Aggregated evidence quality (including component scores, verification breakdown, source tier distribution)
- `STRATEGIC_PATTERNS` - Common strategic themes
- `TENSIONS` - Identified conflicts (or explicit absence)
- `TREND_RANKING` - Priority-ordered trend list
- `ARC_ELEMENT_MAP` - Arc element classification (only when ARC_ID is set)

---

## Analysis Summary Template

Generate analysis summary for Phase 4:

```text
## Dimension Analysis: {DIMENSION}

### Thematic Structure
- {N} thematic clusters identified
- Primary themes: {list top 3}

### Cross-Trend Connections
- {N} total connections mapped
- {M} strong connections
- Connection types: {breakdown}

### Evidence Quality
- Average trend confidence: {0.XX}
- Total claims referenced: {N}
- Evidence freshness: {status}

### Strategic Patterns
- {N} strategic patterns identified
- Key themes: {list}

### Tensions
- {N} tensions identified OR "No material contradictions"

### Synthesis Priority
- Top-ranked trend: {title} (score: {X.XX})
- Synthesis sequence: {ordered list}
```

---

## Error Responses

### Insufficient Connections

```json
{
  "success": false,
  "phase": 3,
  "step": "3.2",
  "error": "Disconnected trends",
  "isolated_trends": ["trend-id-1"],
  "remediation": "Review trend content for missed connections"
}
```

### Quality Below Threshold

```json
{
  "success": false,
  "phase": 3,
  "step": "3.3",
  "error": "Evidence quality below threshold",
  "avg_confidence": 0.65,
  "minimum_required": 0.70,
  "remediation": "Review source trends for quality issues"
}
```

---

## Transition to Phase 4

**Gate:** All steps completed (6 steps + conditional Step 3.7 if ARC_ID set), analysis outputs generated.

**Mark Phase 3 todo as completed.**

**Proceed to:** [phase-4-synthesis.md](phase-4-synthesis.md)
