# Phase 2: Entity Loading

## Objective

Load all dimension-scoped entities required for synthesis. This is a BLOCKING phase - synthesis cannot proceed without complete entity loading.

## Prerequisites (Gate Check)

Before starting Phase 2, verify:

- Phase 1 completed successfully
- PROJECT_PATH validated
- DIMENSION validated
- README-{dimension}.md exists
- RESEARCH_TYPE detected
- ARC_ID resolved (empty for generic, or recognized arc)

**IF MISSING: STOP. Return to Phase 1.**

---

## TodoWrite Expansion

When entering Phase 2, expand to these step-level todos:

```text
2.1 Read dimension README [in_progress]
2.2 Load all dimension trends [pending]
2.3 Extract and load referenced claims [pending]
2.4 Extract and load referenced findings [pending]
2.5 Load dimension entity [pending]
2.5b Load dimension core question [pending]
2.6 Load related domain concepts [pending]
2.6b Load source reliability [pending]
2.7 Load megatrend metadata [pending]
2.8 Verification checkpoint [pending]
```

---

## Step 2.1: Read Dimension README

**Action:** Read the dimension README to understand trend structure.

**Use Read tool:**

```text
Read: ${PROJECT_PATH}/11-trends/README-${DIMENSION}.md
```

**Extract from README:**

- Trend count
- Trend file paths (from table)
- Question coverage mapping
- Key findings summary
- Metrics (findings referenced, claims used, avg confidence)

**Store:**

```text
TREND_PATHS = [list of trend file paths]
TREND_COUNT = N
AVG_CONFIDENCE = 0.XX
```

**Verification:** README parsed, trend paths extracted.

---

## Step 2.2: Load All Dimension Trends

**Action:** Read ALL trend files for this dimension.

**CRITICAL:** Use Claude Code Read tool for each trend. Batch 3-5 per message for efficiency.

**For each trend in TREND_PATHS:**

```text
Read: ${PROJECT_PATH}/11-trends/data/${trend_filename}
```

**Extract from each trend:**

- `dc:title` - Trend title
- `dc:identifier` - Trend ID
- `dimension` - Confirm matches target dimension
- `claim_refs` - Array of claim IDs
- `finding_refs` - Array of finding references
- `concept_refs` - Array of concept references
- `quality_scores.composite` - Quality score
- `quality_scores.evidence_strength` (0.0-1.0) - Citation strength
- `quality_scores.strategic_relevance` (0.0-1.0) - Alignment to research questions
- `quality_scores.actionability` (0.0-1.0) - Clarity of recommendations
- `quality_scores.novelty` (0.0-1.0) - Degree of new insights
- `trend_confidence` - Confidence level
- `planning_horizon` - act/plan/observe classification
- `evidence_freshness` - current/aging/dated status
- `oldest_evidence_date` - YYYY-MM-DD format
- `megatrend_refs` - Array of megatrend wikilinks (metadata only)
- Content sections (Context, Evidence, Implications)

**Build trend registry:**

```text
TRENDS = [
  {
    id: "trend-governance-struktur-a1b2c3",
    title: "Governance-Struktur",
    confidence: 0.85,
    quality: 0.80,
    quality_scores: {
      composite: 0.80,
      evidence_strength: 0.82,
      strategic_relevance: 0.85,
      actionability: 0.78,
      novelty: 0.75
    },
    planning_horizon: "act",
    evidence_freshness: "current",
    oldest_evidence_date: "2026-01-09",
    claim_refs: ["claim-1", "claim-2", "claim-3"],
    finding_refs: ["finding-1", "finding-2"],
    megatrend_refs: ["megatrend-digitalization-a1b2"],
    key_points: [extracted from content]
  },
  ...
]
```

**Verification:** All trends loaded, frontmatter parsed.

---

## Step 2.3: Extract and Load Referenced Claims

**Action:** Collect all claim_refs from loaded trends and read each claim file.

**Aggregate claim IDs:**

```text
ALL_CLAIM_REFS = union of all trend.claim_refs
```

**IMPORTANT:** Load ALL claim_refs referenced by this dimension's trends, not a subset. Phase 4 synthesis may cite any claim from any dimension trend, so incomplete loading will cause citation validation failures in Phase 5.

**Scope:** Only claims referenced by trends belonging to THIS dimension need to be loaded - not all claims in the project.

**Claim loading is BLOCKING:** If any referenced claim file is missing, return error and halt execution.

**For each claim ID:**

```text
Read: ${PROJECT_PATH}/10-claims/data/${claim_id}.md
```

**Extract from each claim:**

- `claim_text` - The verified assertion
- `confidence_score` - Claim confidence
- `verification_status` - verified/partially-verified/unverified/contradicted
- `finding_refs` - Source findings
- `claim_quality` - Quality score

**Build claim registry:**

```text
CLAIMS = [
  {
    id: "claim-transformation-office-a1b2",
    text: "Ein Transformation Office mit fünf Kernkompetenzen ist erforderlich",
    confidence: 0.85,
    verification_status: "verified",
    quality: 0.82
  },
  ...
]
```

**Verification:** All referenced claims loaded.

---

## Step 2.4: Extract and Load Referenced Findings

**Action:** Collect key finding references and load for context.

**Note:** Not all findings need full loading - focus on findings directly referenced by trends.

**For high-priority findings (directly referenced in trend text):**

```text
Read: ${PROJECT_PATH}/04-findings/data/${finding_id}.md
```

**Extract:**

- `dc:title` - Finding title
- `source_url` - Original source
- `quality_dimensions.topical_relevance` (0.0-1.0) - Relevance to research questions
- `quality_dimensions.completeness` (0.0-1.0) - Coverage of topic
- `quality_dimensions.source_reliability` (0.0-1.0) - Source trustworthiness
- `quality_dimensions.evidentiary_value` (0.0-1.0) - Strength of evidence
- Key content snippets

**Build finding registry:**

```text
FINDINGS = [
  {
    id: "finding-dcc6c56c",
    title: "Transformation Office Best Practices",
    source: "https://...",
    quality_dimensions: {
      topical_relevance: 0.85,
      completeness: 0.78,
      source_reliability: 0.82,
      evidentiary_value: 0.80
    },
    summary: "..."
  },
  ...
]
```

**Verification:** Key findings loaded for context.

---

## Step 2.5: Load Dimension Entity

**Action:** Read the dimension definition for strategic context.

**Find dimension file:**

```text
Glob: ${PROJECT_PATH}/01-research-dimensions/data/dimension-${DIMENSION}*.md
```

**Read dimension file:**

```text
Read: ${PROJECT_PATH}/01-research-dimensions/data/dimension-${DIMENSION}-{id}.md
```

**Extract:**

- `display_name` - Human-readable dimension name
- `description` - Dimension scope and boundaries
- `research_focus` - Key research areas
- `related_questions` - Linked refined questions

**Store:**

```text
DIMENSION_CONTEXT = {
  display_name: "Governance & Transformationssteuerung",
  description: "...",
  research_focus: "...",
  strategic_importance: "..."
}
```

**Verification:** Dimension context understood.

---

## Step 2.5b: Load Dimension Core Question

**Action:** Extract the core question for this dimension from the research-type reference file.

**Purpose:** Provide a 1-sentence italic intro between the H1 heading and Executive Summary in the synthesis document.

**Process by RESEARCH_TYPE:**

| Research Type | Source File | Field to Extract |
|---|---|---|
| `smarter-service` | `${CLAUDE_PLUGIN_ROOT}/references/research-types/smarter-service.md` | `**Core Question:**` under H3 matching `DIMENSION_CONTEXT.display_name` |
| `customer-value-mapping` | `${CLAUDE_PLUGIN_ROOT}/references/research-types/customer-value-mapping.md` | `**Core Question:**` under H3 matching dimension |
| `b2b-ict-portfolio` | `${CLAUDE_PLUGIN_ROOT}/references/research-types/b2b-ict-portfolio.md` | `**Core Question:**` under H3 matching dimension |
| `lean-canvas` | `${CLAUDE_PLUGIN_ROOT}/references/research-types/lean-canvas.md` | `**Focus:**` under H3 matching dimension |
| `generic` | Dimension entity (already loaded in Step 2.5) | First sentence of `DIMENSION_CONTEXT.description` |

**Steps:**

1. **Read research-type reference file** (skip for `generic`):
   ```text
   Read: ${CLAUDE_PLUGIN_ROOT}/references/research-types/${RESEARCH_TYPE}.md
   ```

2. **Find the H3 section** matching `DIMENSION_CONTEXT.display_name` (match by German name or English name in parentheses)

3. **Extract the question text in PROJECT_LANGUAGE only:**
   - For `smarter-service` with `PROJECT_LANGUAGE=de`: Extract the German text inside `*"..."*`
   - For `smarter-service` with `PROJECT_LANGUAGE=en`: Extract the English translation inside `*(...)*`
   - For `customer-value-mapping` / `b2b-ict-portfolio`: Extract the text inside `*"..."*`
   - For `lean-canvas`: Extract the text after `**Focus:**`
   - For `generic`: Take the first sentence of `DIMENSION_CONTEXT.description`

4. **Store extracted value:**

```text
DIMENSION_CORE_QUESTION = "Wo und wie schaffen wir mit digitalen Mitteln Wert für Kunden und Geschäft?"
```

**Graceful degradation:** If the dimension H3 section cannot be found or the core question cannot be extracted, set `DIMENSION_CORE_QUESTION = ""` and log a warning. The synthesis will omit the intro sentence.

**Verification:** Core question extracted (or documented as unavailable).

---

## Step 2.6: Load Related Domain Concepts

**Action:** Load domain concepts related to this dimension.

**Find related concepts:**

```text
Grep: dimension.*${DIMENSION} in ${PROJECT_PATH}/05-domain-concepts/data/*.md
```

**Or extract from trend concept_refs.**

**For each related concept:**

```text
Read: ${PROJECT_PATH}/05-domain-concepts/data/${concept_id}.md
```

**Extract:**

- `term` - Concept name
- `definition` - Concept definition
- `relevance` - Why it matters

**Build concept registry:**

```text
CONCEPTS = [
  {
    id: "concept-transformation-office",
    term: "Transformation Office",
    definition: "Zentrale Steuerungseinheit für unternehmensweite Transformationen..."
  },
  ...
]
```

**Verification:** Domain concepts loaded (if applicable).

---

## Step 2.6b: Load Source Reliability (NEW)

**Action:** For findings with source_url, load source entity metadata to extract reliability_tier.

**Process:**

1. Extract unique source domains from finding source_urls
2. For each source domain, find matching source entity:
   ```text
   Glob: ${PROJECT_PATH}/07-sources/data/source-*.md matching domain
   ```
3. Read source entity YAML frontmatter
4. Extract:
   - `reliability_tier` (tier-1/tier-2/tier-3/tier-4)
   - `publisher_id` (wikilink)

**Build source reliability map:**

```text
SOURCE_RELIABILITY_MAP = {
  "source-nature-12345": {
    tier: "tier-1",
    publisher: "publisher-nature"
  },
  "source-mckinsey-67890": {
    tier: "tier-2",
    publisher: "publisher-mckinsey"
  },
  ...
}
```

**Handling missing tier data:**

If a source entity exists but has no reliability_tier field, assign "unknown" category:

```text
SOURCE_RELIABILITY_MAP["source-id"].tier = "unknown"
```

**Purpose:** Enable Evidence Quality Analysis section to report source authority distribution.

**Verification:** Source reliability map built for all findings with source_url.

---

## Step 2.7: Load Megatrend Metadata (NEW)

**Action:** For each trend.megatrend_refs, load megatrend YAML metadata (NOT full content).

**Process:**

1. Extract all megatrend_refs from loaded trends
2. For each megatrend reference:
   ```text
   Read: ${PROJECT_PATH}/06-megatrends/data/${megatrend_id}.md
   ```
3. Extract YAML frontmatter only:
   - `dc:identifier` - Megatrend ID
   - `dc:title` - Megatrend title
   - `planning_horizon` - act/plan/observe
   - `confidence_score` - Confidence level
   - `dimension_affinity` - Primary dimension

**Build megatrend metadata registry:**

```text
MEGATREND_METADATA = {
  "megatrend-digitalization-a1b2": {
    title: "Industrial Digitalization",
    planning_horizon: "act",
    confidence: 0.85,
    dimension_affinity: "technology-infrastructure"
  },
  ...
}
```

**Purpose:** Enable synthesis to mention megatrends with context, linking to full megatrend entities for reader deep-dive.

**Skip if:** No megatrend_refs in any trend (log: "No megatrend connections found for dimension {slug}").

**Verification:** Megatrend metadata loaded for all referenced megatrends.

---

## Step 2.8: Verification Checkpoint (BLOCKING)

**Self-test before proceeding to Phase 3:**

Answer these questions from loaded data (no re-reading allowed):

1. **"What trends exist for this dimension?"**

   → List all trend titles and IDs

2. **"What is the average confidence score across trends?"**

   → Calculate from loaded trend data

3. **"What claims support these trends?"**

   → List key claims with confidence scores

4. **"What thematic patterns appear across trends?"**

   → Identify common themes from trend content

5. **"What is the dimension's strategic context?"**

   → Summarize from dimension entity

**IF UNABLE TO ANSWER ANY QUESTION:**

→ STOP and re-invoke Read tools for missing data

→ Do NOT proceed to Phase 3 with incomplete data

---

## Phase 2 Outputs

- `TRENDS` registry with all dimension trends (including quality_scores components, planning_horizon, evidence_freshness, megatrend_refs)
- `CLAIMS` registry with all referenced claims (including verification_status)
- `FINDINGS` registry with key findings (including quality_dimensions components)
- `DIMENSION_CONTEXT` with strategic context
- `DIMENSION_CORE_QUESTION` with dimension intro sentence in PROJECT_LANGUAGE (empty string if unavailable)
- `CONCEPTS` registry with domain terminology
- `SOURCE_RELIABILITY_MAP` with tier-1/2/3/4 classifications
- `MEGATREND_METADATA` with related megatrends (if applicable)
- `ARC_ID`, `ARC_DISPLAY_NAME`, `ARC_TEMPLATE` propagated from Phase 1
- All verification questions answerable

---

## Error Responses

### Trend Loading Failed

```json
{
  "success": false,
  "phase": 2,
  "step": "2.2",
  "error": "Failed to load trend file",
  "file": "trend-governance-struktur-a1b2c3.md",
  "remediation": "Verify trend file exists and is readable"
}
```

### Missing Claims

```json
{
  "success": false,
  "phase": 2,
  "step": "2.3",
  "error": "Referenced claim not found",
  "claim_id": "claim-missing-id",
  "remediation": "Verify claim file exists in 10-claims/data/"
}
```

### Verification Failed

```json
{
  "success": false,
  "phase": 2,
  "step": "2.7",
  "error": "Verification checkpoint failed",
  "failed_questions": ["What claims support these trends?"],
  "remediation": "Re-invoke Read tools for missing entities"
}
```

---

## Transition to Phase 3

**Gate:** All 7 steps completed, verification checkpoint passed.

**Mark Phase 2 todo as completed.**

**Proceed to:** [phase-3-analysis.md](phase-3-analysis.md)
