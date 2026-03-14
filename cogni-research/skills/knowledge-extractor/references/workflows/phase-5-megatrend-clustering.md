# Phase 5: Megatrend Clustering

Generate megatrend clusters from research findings using bottom-up semantic analysis.

---

## ⚠️ Seed Megatrend Processing Delegation

**IMPORTANT:** Seed megatrend processing (for TIPS research type) has been consolidated in `knowledge-merger` Phase 3.

This workflow now handles:

- **Generic research types**: Full bottom-up megatrend clustering (Steps 1-4a)
- **TIPS research type**: Bottom-up clustering only; seed processing happens in knowledge-merger

**Rationale:** Centralizing seed processing in knowledge-merger ensures:

1. All seeds result in megatrends (no gaps)
2. Proper deduplication between seeds and bottom-up clusters
3. Single source of truth for megatrend creation

---

## Entry Gate

Verify Phase 4 artifacts exist before proceeding:

```bash
# Phase 4 must provide these data structures
test ${#findings_list[@]} -ge 2
test ${#FINDING_TO_DIMENSION[@]} -gt 0
test ${#FINDING_UUIDS[@]} -gt 0
test ${#CONCEPTS_BY_DIMENSION[@]} -ge 0  # May be 0 (valid)
```

**IF tests fail:** Return to Phase 4.

---

## Step 0.1: Research Type Detection

Determine megatrend structure based on project research type.

```bash
SPRINT_LOG="${PROJECT_PATH}/.metadata/sprint-log.json"
RESEARCH_TYPE=$(jq -r '.research_type // "generic"' "$SPRINT_LOG")

case "$RESEARCH_TYPE" in
  smarter-service)
    MEGATREND_STRUCTURE="tips"
    WORD_COUNT_TARGET="600-900"
    log_conditional INFO "Megatrend structure: TIPS (seed processing delegated to knowledge-merger)"
    ;;
  *)
    MEGATREND_STRUCTURE="generic"
    WORD_COUNT_TARGET="400-600"
    log_conditional INFO "Megatrend structure: Generic (What it is/does/means)"
    ;;
esac
```

**Routing Logic:**

| Research Type | Megatrend Structure | Seed Handling | Word Target |
|---------------|-----------------|---------------|-------------|
| `smarter-service` | TIPS | Delegated to knowledge-merger | 600-900 |
| `generic` | Generic | N/A (no seeds) | 400-600 |
| `b2b-ict-portfolio` | Generic | N/A (no seeds) | 400-600 |
| `customer-value-mapping` | Generic | N/A (no seeds) | 400-600 |
| `lean-canvas` | Generic | N/A (no seeds) | 400-600 |

**Branch Point:**

- **IF `MEGATREND_STRUCTURE="tips"`:** Perform bottom-up clustering only (seed processing in knowledge-merger)
- **IF `MEGATREND_STRUCTURE="generic"`:** Skip to [Step 3.2a: Generate Generic Megatrend Content](#step-32a-generate-generic-megatrend-content-if-megatrend_structuregeneric)

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 5.1: Analyze findings and identify megatrend clusters [in_progress]
- Phase 5.2: Generate megatrend content [pending]
- Phase 5.3: Create megatrend entities [pending]
```

**Note:** Seed-related steps (load seeds, match seeds, validate gaps) are now handled by knowledge-merger.

---

## Step 1: Initialize (Script-Delegated)

```bash
log_phase "Phase 5: Megatrend Clustering" "start"

megatrends_created=0
seeds_validated=0
seeds_unmatched=0
hypothesis_megatrends=0

# Bash 3.2 compatible - use parallel indexed arrays
MEGATRENDS_DIM_KEYS=()
MEGATRENDS_DIM_VALUES=()
SEED_MATCH_STATUS=()  # Track which seeds were matched
```

---

## Step 2: Semantic Megatrend Discovery (LLM Reasoning)

Analyze all finding summaries to identify thematic clusters, then match against seed megatrends.

### 2.1 Load Finding Summaries

For each finding in `findings_list`, extract:

- Title (from H1 or frontmatter)
- Summary/abstract (first paragraph or `dc:description`)
- Tags (from frontmatter)
- UUID (from `FINDING_UUIDS`)

### 2.2 Bottom-Up Clustering

**Reasoning Task:** Group findings by thematic similarity, not keyword matching.

| Criterion | Description |
|-----------|-------------|
| **Semantic Relatedness** | Findings discuss the same concept, even with different terminology |
| **Minimum Cluster Size** | 3+ findings for strong evidence, 1-2 for weak evidence |
| **Distinct Themes** | Each cluster represents a coherent, non-overlapping theme |
| **Cross-Terminology** | Group "ML", "machine learning", "AI algorithms" together |

**Output Format (Bottom-Up Clusters):**

```yaml
bottom_up_clusters:
  - cluster_name: "Descriptive Cluster Name"
    member_findings:
      - uuid: "{finding-uuid-1}"
        relevance: "Brief explanation"
    finding_count: 5
    evidence_strength: "strong"  # strong (3+), moderate (2), weak (1)
```

### 2.3 Seed Megatrend Matching (Tier 1 Only)

For each **Tier 1** seed megatrend from Step 0, check if any bottom-up cluster covers this theme.

**Note:** Tier 2 industry trends are NOT matched here. They are only used for strategic narrative enrichment in Step 3.2.

**Matching Logic:**

```text
FOR each seed_megatrend:
  1. Semantic match: Does any cluster's theme align with seed name/keywords?
  2. Keyword match: Do cluster member findings contain seed keywords?

  IF strong match found:
    → Mark cluster as seed_validated: true
    → Use seed name as canonical megatrend name (merge)
    → source_type: "hybrid"

  ELIF partial match (1-2 findings contain keywords):
    → Create megatrend with evidence_strength: "weak"
    → source_type: "hybrid"
    → Log: "Seed '{name}' has weak evidence ({count} findings)"

  ELIF no match AND validation_mode == "ensure_covered":
    → Create hypothesis megatrend (no finding support)
    → source_type: "seeded"
    → evidence_strength: "hypothesis"
    → Log WARNING: "Seed '{name}' not covered by findings - creating hypothesis"

  ELIF no match AND validation_mode == "must_match":
    → Log ERROR: "Required seed '{name}' not found in findings"
    → Add to gap_report
```

### 2.4 Evidence Strength Classification

| Finding Count | Evidence Strength | Confidence Range |
|---------------|-------------------|------------------|
| 5+ findings | strong | 0.80-0.95 |
| 3-4 findings | moderate | 0.65-0.79 |
| 1-2 findings | weak | 0.40-0.64 |
| 0 findings (seed only) | hypothesis | 0.20-0.39 |

### 2.5 Consolidate Megatrend List

Merge bottom-up clusters and seed-derived megatrends:

```yaml
megatrend_list:
  - megatrend_name: "Shopfloor Digitalization"  # Canonical from seed
    source_type: "hybrid"
    seed_validated: true
    seed_name: "Shopfloor Digitalization"
    member_findings: [...]
    finding_count: 7
    evidence_strength: "strong"
    dimension_affinity: "digitale-wertetreiber"

  - megatrend_name: "Predictive Maintenance Excellence"  # Emergent cluster
    source_type: "clustered"
    seed_validated: false
    member_findings: [...]
    finding_count: 4
    evidence_strength: "moderate"
    dimension_affinity: "digitale-wertetreiber"
```

**Mark 5.1 and 5.2 complete.** Proceed to Step 3.

---

## Step 3: Generate Strategic Narrative (LLM Reasoning) (NEW)

For each megatrend, generate TIPS-style strategic content (600-900 words total).

### 3.1 Determine Planning Horizon

Classify each megatrend by urgency:

| Horizon | Criteria |
|---------|----------|
| **act** (0-6 months) | Published regulations, proven implementations, mature products, competitive pressure |
| **plan** (6-18 months) | Draft regulations, early adopter validation, second-gen products, 5-15% adoption |
| **observe** (18+ months) | Early policy debate, academic/research, prototype/POC stage, experimentation |

### 3.2 Generate Strategic Narrative

For each megatrend, synthesize from member findings:

```yaml
strategic_narrative:
  trend: |
    [150-200 words - Observable pattern description:
    - What is happening (evidence-based from findings)
    - Scale and velocity of change
    - Key drivers and catalysts
    - Geographic/industry scope]

  implication: |
    [150-200 words - Strategic significance:
    - Impact on industry/organization
    - Stakeholder effects (customers, employees, partners)
    - Competitive dynamics
    - Risk/opportunity landscape]

  possibility:
    overview: |
      [50-75 words - General opportunity framing]
    chance: |
      [25-50 words - Value gained by acting (for ACT horizon)]
    risk: |
      [25-50 words - Cost of not acting (for ACT horizon)]

  solution: |
    [100-150 words - Recommended action:
    - Concrete next steps
    - Resource considerations
    - Success indicators
    - Quick wins vs. strategic investments]
```

**Word Count Target:** 550-700 words for strategic narrative sections.

### 3.3 Calculate Quality Scores

```yaml
quality_scores:
  evidence_strength: 0.82  # Based on finding count and claim coverage
  strategic_relevance: 0.78  # Alignment with research question
  actionability: 0.75  # Concreteness of solution recommendations
```

**Scoring Logic:**

```text
evidence_strength = min(1.0, 0.5 + (finding_count * 0.1) + (claim_count * 0.05))
strategic_relevance = LLM assessment (0.0-1.0) based on research question alignment
actionability = LLM assessment (0.0-1.0) based on solution specificity
```

### 3.4 Optional: Claim Integration

If claims are available in `10-claims/data/`:

1. Search claims for keywords matching this megatrend
2. Select 2-5 high-confidence claims (confidence_score >= 0.75)
3. Add to `claim_refs` array in frontmatter
4. Include claim quotes in Evidence Base section

**Graceful degradation:** If no claims available, proceed without claim_refs.

**Mark 5.3 complete.** Proceed to Step 4.

---

## Step 3.2a: Generate Generic Megatrend Content (IF megatrend_structure="generic")

**Entry Condition:** `MEGATREND_STRUCTURE="generic"` (from Step 0.1)

For generic research types, skip seed megatrend matching (Steps 0-3) and generate domain-based megatrend content instead of TIPS strategic narrative.

### 3.2a.1 Bottom-Up Clustering (Same as Step 2.2)

Group findings by thematic similarity using the same clustering logic as Step 2.2, but without seed matching.

```yaml
generic_clusters:
  - cluster_name: "Descriptive Megatrend Name"
    member_findings:
      - uuid: "{finding-uuid-1}"
        relevance: "Brief explanation"
    finding_count: 5
    evidence_strength: "strong"
    dimension_affinity: "{dimension-slug}"
```

### 3.2a.2 Generate Generic Megatrend Content (400-600 words)

For each megatrend cluster, synthesize from member findings using the 3-part structure:

```yaml
generic_content:
  what_it_is: |
    [150-200 words - Primer on the subject:
    - Definition of what this megatrend encompasses
    - Core concepts and terminology
    - Scope and boundaries within the research context
    - Key characteristics synthesized from findings

    Synthesize ONLY from member finding content. No external knowledge.]

  what_it_does: |
    [100-150 words - Use Cases:
    - Practical applications relevant to research stakeholders
    - How this megatrend manifests in the research domain
    - Key activities or processes involved
    - Real-world examples derived from findings]

  what_it_means:
    qualitative: |
      [100-150 words - Strategic significance:
      - Impact on research subject/stakeholders
      - Broader implications for the domain
      - Quality considerations and trade-offs]
    metrics:
      - metric: "{Metric name}"
        value: "{Value or range from findings}"
        source: "[[04-findings/data/finding-ref]]"
```

**Word Count Target:** 400-600 words total.

### 3.2a.3 Calculate Quality Scores

```yaml
quality_scores:
  evidence_strength: 0.82  # Based on finding count
  relevance: 0.78  # Alignment with research question
```

**Scoring Logic (same as TIPS):**

```text
evidence_strength = min(1.0, 0.5 + (finding_count * 0.1))
```

**Mark 5.3 complete.** Proceed to Step 4a (Generic Entity Creation).

---

## Step 4a: Create Generic Megatrend Entities (IF megatrend_structure="generic")

**Entry Condition:** `MEGATREND_STRUCTURE="generic"` (from Step 0.1)

### 4a.1 Generate Filename (Same as Step 4.3)

```bash
slug=$(echo "$megatrend_name" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | \
  sed 's/^-//' | sed 's/-$//' | cut -c1-50)
hash=$(echo -n "$megatrend_name" | shasum -a 256 | cut -c1-8)
filename="megatrend-${slug}-${hash}.md"
```

### 4a.2 Write Generic Megatrend Entity File (400-600 words)

Write to `${PROJECT_PATH}/${MEGATRENDS_DIR}/data/${filename}`:

```yaml
---
tags: [megatrend, dimension/{dimension-slug}, evidence/{evidence_strength}]
dc:creator: knowledge-extractor
dc:title: "{2-4 word heading}"
dc:identifier: "megatrend-{slug}-{hash}"
dc:created: "{ISO 8601 UTC}"
dc:type: megatrend
entity_type: megatrend
megatrend_name: "{Full Megatrend Name}"
megatrend_structure: "generic"
finding_count: {N}
finding_refs:
  # ⛔ Populate with ALL member finding wikilinks (one per line)
  - "[[04-findings/data/{finding-basename}]]"
# ⛔ YAML CRITICAL: Ensure blank line above. The language field MUST start on its own line.
language: "{content_language}"

# Generic megatrend fields (simplified)
source_type: "clustered"
evidence_strength: "{strong|moderate|weak}"
confidence_score: {0.0-1.0}
dimension_affinity: "{dimension-slug}"
---

# {Megatrend Name}

## {HEADER_WHAT_IT_IS}

{150-200 words - Primer on the subject:
- Definition of what this megatrend encompasses
- Core concepts and terminology
- Scope and boundaries within the research context
- Key characteristics synthesized from findings}

## {HEADER_WHAT_IT_DOES}

{100-150 words - Use Cases:
- Practical applications relevant to research stakeholders
- How this megatrend manifests in the research domain
- Key activities or processes involved
- Real-world examples derived from findings}

## {HEADER_WHAT_IT_MEANS}

{150-200 words - Implications:

**{HEADER_QUALITATIVE_IMPACT}:**

[Narrative describing strategic significance, stakeholder effects,
and broader implications for the research context]

**{HEADER_QUANTITATIVE_INDICATORS}:**

| {TH_METRIC} | {TH_VALUE_RANGE} | {TH_SOURCE} |
|-------------|------------------|-------------|
| {Metric 1} | {Value} | [[04-findings/data/finding-ref]] |
| {Metric 2} | {Value} | [[04-findings/data/finding-ref]] |

{MSG_METRICS_NOTE}}

## {HEADER_RELATED_FINDINGS}

{MSG_FINDING_REFS_NOTE}

<!-- See finding_refs in frontmatter for complete list -->
```

**Language Template Variables:** See [language-templates.md](../../../../references/language-templates.md#06-megatrends-generic-structure)

**Word Count Target:** 400-600 words total

**Template Reference:** [entity-templates.md](../domain/entity-templates.md#generic-megatrend-entity-template)

### 4a.3 Track for Backlinks

```bash
if [ -n "$best_dimension" ]; then
  dim_file=$(basename "$best_dimension")
  MEGATRENDS_BY_DIMENSION["$dim_file"]+="[[${MEGATRENDS_DIR}/data/${filename%.md}]] "
fi
megatrends_created=$((megatrends_created+1))
```

**Mark 5.4 complete.** Skip Step 5 (no seed validation needed for generic). Proceed to Step 6.

---

## Step 4: Create Megatrend Entities

For each megatrend, create entity file with enhanced content.

### 4.1 Check Existing Megatrends (Script-Delegated)

```bash
megatrend_exists=false
for existing in "${PROJECT_PATH}"/${MEGATRENDS_DIR}/data/megatrend-*.md; do
  [ -f "$existing" ] || continue
  existing_name=$(grep "^megatrend_name:" "$existing" | head -1 | cut -d'"' -f2)
  # Semantic check: is this megatrend's theme already covered?
done
```

### 4.2 Determine Dimension (Script-Delegated)

```bash
# Use seed dimension_affinity if available, else majority vote from findings
if [ -n "$seed_dimension_affinity" ]; then
  best_dimension="$seed_dimension_affinity"
else
  # Majority vote logic (existing code)
  ...
fi
```

### 4.3 Generate Filename (Script-Delegated)

```bash
slug=$(echo "$megatrend_name" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | \
  sed 's/^-//' | sed 's/-$//' | cut -c1-50)
hash=$(echo -n "$megatrend_name" | shasum -a 256 | cut -c1-8)
filename="megatrend-${slug}-${hash}.md"
```

### 4.4 Write Enhanced Entity File (700-1100 words)

Write to `${PROJECT_PATH}/${MEGATRENDS_DIR}/data/${filename}`:

```yaml
---
tags: [megatrend, dimension/{dimension-slug}, evidence/{evidence_strength}]
dc:creator: knowledge-extractor
dc:title: "{2-4 word heading}"
dc:identifier: "megatrend-{slug}-{hash}"
dc:created: "{ISO 8601 UTC}"
dc:type: megatrend
entity_type: megatrend
megatrend_name: "{Full Megatrend Name}"
megatrend_structure: "tips"
finding_count: {N}
finding_refs:
  # ⛔ Populate with ALL member finding wikilinks (one per line)
  - "[[04-findings/data/{finding-basename}]]"
# ⛔ YAML CRITICAL: Ensure blank line above. The language field MUST start on its own line.
language: "{content_language}"

# Megatrend enrichment fields
source_type: "{clustered|seeded|hybrid}"
tier: 1  # Always 1 for seed-derived megatrends (Tier 2 trends not used for seeding)
seed_validated: {true|false}
seed_name: "{original seed name if applicable}"
evidence_strength: "{strong|moderate|weak|hypothesis}"
confidence_score: {0.0-1.0}
planning_horizon: "{act|plan|observe}"
dimension_affinity: "{dimension-slug}"
claim_refs:
  - "[[10-claims/data/{claim-basename}]]"
strategic_narrative:
  trend: "{Observable pattern summary}"
  implication: "{Strategic significance}"
  possibility:
    overview: "{Opportunity framing}"
    chance: "{Value of acting}"
    risk: "{Cost of not acting}"
  solution: "{Recommended action}"
quality_scores:
  evidence_strength: {0.0-1.0}
  strategic_relevance: {0.0-1.0}
  actionability: {0.0-1.0}

# Content quality metrics (NEW - populate after generating content)
citation_count: {N}  # Count of inline citations in content
content_metrics:
  total_word_count: {N}
  section_word_counts:
    trend: {N}
    implication: {N}
    possibility: {N}
    solution: {N}
    key_findings: {N}

# Top findings for Key Findings section (NEW - sort by quality, take top 5)
key_findings_summary:
  - finding_ref: "[[04-findings/data/{finding-basename}]]"
    title: "{Finding title or key insight}"
    quality_score: {0.0-1.0}
    summary: "{2-3 sentence summary connecting to megatrend thesis}"

# Cross-references (NEW - populate during content generation)
related_concepts: []
related_trends: []
related_megatrends: []
---

# {Megatrend Name}

> **Zusammenfassung auf einen Blick** / **Summary at a Glance**
>
> **Was/What:** {One sentence describing the megatrend}
> **Warum wichtig/Why Important:** {One sentence on strategic significance}
> **Handlungshorizont/Action Horizon:** {🔴 ACT | 🟡 PLAN | 🟢 OBSERVE}
> **Evidenzstärke/Evidence Strength:** {████████░░ strong | ██████░░░░ moderate | ████░░░░░░ weak | ██░░░░░░░░ hypothesis}
> **Top-Empfehlung/Top Recommendation:** {Single most important action}

## Trend

{150-200 words - Observable pattern description:
- What is happening (evidence-based from findings)
- Scale and velocity of change
- Key drivers and catalysts

⛔ INLINE CITATIONS: Include 2-3 inline citations connecting claims to findings:
"According to industry analysis<sup>[[04-findings/data/finding-xyz|1]]</sup>, adoption increased 35%."}

## Implication

{150-200 words - Strategic significance:
- Impact on industry/organization
- Stakeholder effects
- Competitive dynamics

⛔ INLINE CITATIONS: Include 2-3 inline citations connecting claims to findings.}

## Possibility

{100-150 words - Opportunity framing:
- **Chance:** Value gained by acting
- **Risk:** Cost of not acting}

## Solution

{HORIZON-SPECIFIC STRUCTURE - Select based on planning_horizon:}

### ACT Horizon (0-6 months):

### Immediate Actions (0-3 Months)
1. **{Action Name}**: {Description 25-30 words}
   - **Success Indicators:** {Measurable KPI}
   - **Resources:** {Effort/cost level}

### Strategic Initiatives (3-6 Months)
1. **{Action Name}**: {Description}
   - **Success Indicators:** {KPI}
   - **Dependencies:** {Prerequisites}

### PLAN Horizon (6-18 months):

### Preparation Phase (Months 1-3)
{Capability building actions}

### Implementation Phase (Months 4-12)
{Rollout actions with milestones}

### Scaling Phase (Months 13-18)
{Expansion actions}

### OBSERVE Horizon (18+ months):

### Monitoring Activities
{What to monitor, signals to watch}

### Piloting Criteria
{When to move to PLAN horizon}

### Option Securing
{Actions to maintain flexibility}

## Evidence Base

**Evidenzstärke/Evidence Strength:** {████████░░ strong (8/10) | ██████░░░░ moderate (6/10) | etc.}

| Dimension | Score | Description |
|-----------|-------|-------------|
| Source Count | {0.0-1.0} | {N} independent sources |
| Recency | {0.0-1.0} | {X}% of sources < 12 months |
| Consistency | {0.0-1.0} | {High|Medium|Low} agreement |

**Source:** {clustered | seeded | hybrid}
**Confidence Score:** {score} ({HIGH ≥0.8 | MEDIUM 0.6-0.79 | LOW <0.6})
**Planning Horizon:** {act | plan | observe}
**Finding Coverage:** {N} findings

### Supporting Claims

{If claims available:}
1. "{claim_text}" (confidence: 0.85) [[10-claims/data/claim-id|C1]]
2. "{claim_text}" (confidence: 0.82) [[10-claims/data/claim-id|C2]]

{If no claims:}
*No verified claims available for this megatrend.*

### Key Findings

**Top 5 Supporting Findings:**

1. **{Finding Title}** (Quality: {score}): {2-3 sentence summary connecting finding to megatrend thesis. Explain how this evidence supports the trend narrative.}
   - Source: [[04-findings/data/finding-xyz]]

2. **{Finding Title}** (Quality: {score}): {Summary connecting to thesis.}
   - Source: [[04-findings/data/finding-abc]]

3. **{Finding Title}** (Quality: {score}): {Summary connecting to thesis.}
   - Source: [[04-findings/data/finding-def]]

{⛔ REQUIREMENT: Generate summaries for top 3-5 findings sorted by quality_score.
Each summary must be 2-3 sentences explaining how the finding supports this megatrend.}

## Related Entities

### Related Concepts
{List 2-5 relevant domain concepts with relationship descriptions:}
- [[05-domain-concepts/data/concept-xyz|Concept Name]] - {How this concept relates}

### Related Megatrends
{List 1-3 megatrends with synergy/tension relationships:}
- [[06-megatrends/data/megatrend-abc|Name]] - {Synergy|Tension: description}

### Related Trends
{List 2-4 trends that manifest this megatrend:}
- [[11-trends/data/trend-def|Trend Name]] - {How trend operationalizes megatrend}
```

### 4.4.1 Word Count Verification (NEW)

After generating content, verify word counts meet minimums:

```bash
# Self-verification checklist
TREND_WORDS=$(count_words "$trend_section")
IMPLICATION_WORDS=$(count_words "$implication_section")
POSSIBILITY_WORDS=$(count_words "$possibility_section")
SOLUTION_WORDS=$(count_words "$solution_section")
KEY_FINDINGS_WORDS=$(count_words "$key_findings_section")

# Verify minimums
[ $TREND_WORDS -ge 150 ] || log_conditional WARN "Trend section below 150 words"
[ $IMPLICATION_WORDS -ge 150 ] || log_conditional WARN "Implication section below 150 words"
[ $POSSIBILITY_WORDS -ge 100 ] || log_conditional WARN "Possibility section below 100 words"
[ $SOLUTION_WORDS -ge 100 ] || log_conditional WARN "Solution section below 100 words"
[ $KEY_FINDINGS_WORDS -ge 100 ] || log_conditional WARN "Key Findings section below 100 words"
```

**LLM Self-Check Questions:**

- [ ] Does Trend section have 150+ words with 2-3 inline citations?
- [ ] Does Implication section have 150+ words with 2-3 inline citations?
- [ ] Does Possibility section have 100+ words with Chance/Risk?
- [ ] Does Solution section have 100+ words using horizon-specific template?
- [ ] Does Key Findings section contain 3-5 finding summaries?
- [ ] Is executive summary populated at top?
- [ ] Are Related Entities populated (if entities exist)?

**Word Count Target:** 700-1100 words total

**Template Reference:** [../domain/entity-templates.md](../domain/entity-templates.md)

### 4.5 Track for Backlinks (Script-Delegated)

```bash
if [ -n "$best_dimension" ]; then
  dim_file=$(basename "$best_dimension")
  MEGATRENDS_BY_DIMENSION["$dim_file"]+="[[${MEGATRENDS_DIR}/data/${filename%.md}]] "
fi
megatrends_created=$((megatrends_created+1))

# Track seed validation status
if [ "$seed_validated" = "true" ]; then
  seeds_validated=$((seeds_validated+1))
elif [ "$source_type" = "seeded" ] && [ "$evidence_strength" = "hypothesis" ]; then
  hypothesis_megatrends=$((hypothesis_megatrends+1))
fi
```

**Mark 5.4 complete.** Proceed to Step 5.

---

## Step 5: Validate Seed Coverage and Log Gaps (NEW)

### 5.1 Check Unmatched Seeds

```bash
for seed in "${SEED_MEGATRENDS[@]}"; do
  seed_name=$(echo "$seed" | yq '.name')
  validation_mode=$(echo "$seed" | yq '.validation_mode')

  if ! seed_was_matched "$seed_name"; then
    seeds_unmatched=$((seeds_unmatched+1))

    if [ "$validation_mode" = "must_match" ]; then
      log_conditional ERROR "Required seed '$seed_name' not found"
      # Add to error report
    elif [ "$validation_mode" = "ensure_covered" ]; then
      log_conditional WARN "Seed '$seed_name' not covered by findings"
    fi
  fi
done
```

### 5.2 Generate Gap Report

If any seeds unmatched, write gap report:

```bash
GAP_REPORT="${PROJECT_PATH}/.metadata/megatrend-gap-report.md"
```

Use language template variables from [language-templates.md](../../../../references/language-templates.md#06-megatrends-ui-strings-phase-5-gap-report).

```markdown
# {HEADER_GAP_REPORT}

**Generated:** {timestamp}
**Research Question:** {initial question}

## {HEADER_SEED_STATUS}

| {LABEL_SEED_NAME} | {LABEL_STATUS} | {LABEL_EVIDENCE} | {LABEL_NOTES} |
|-----------|--------|----------|-------|
| Shopfloor Digitalization | {VALUE_VALIDATED} | 7 findings | {VALUE_MERGED} |
| Supply Chain Resilience | {VALUE_HYPOTHESIS} | 0 findings | {VALUE_CREATED_HYPOTHESIS} |
| Workforce Transformation | {VALUE_WEAK} | 2 findings | {MSG_NEEDS_MORE_RESEARCH} |

## {HEADER_GAPS_IDENTIFIED}

### {LABEL_CRITICAL}
- {MSG_NO_GAPS}

### {LABEL_WARNINGS}
- Supply Chain Resilience: No findings cover this expected megatrend

## {HEADER_RECOMMENDATIONS}

1. Consider additional research queries for unmatched seeds
2. Review hypothesis megatrends for strategic relevance
3. Validate seed megatrend list against research scope
```

**Mark 5.5 complete.** Proceed to completion.

---

## Step 6: Completion

```bash
log_conditional INFO "Megatrends created: $megatrends_created"
log_conditional INFO "Seeds validated: $seeds_validated"
log_conditional INFO "Hypothesis megatrends: $hypothesis_megatrends"
log_conditional INFO "Seeds unmatched: $seeds_unmatched"
log_phase "Phase 5: Megatrend Clustering" "complete"
```

---

## Anti-Hallucination Protocol

| Rule | Enforcement |
|------|-------------|
| No external knowledge for clusters | Cluster themes derived from finding content ONLY |
| Seed knowledge is explicit | Seeds come from user-validated configuration, not LLM invention |
| No fabrication | All member UUIDs must exist in `findings_list` |
| Source attribution | Strategic narrative paraphrases actual finding content |
| Verifiable clustering | Each finding's cluster assignment has explicit `relevance` justification |
| Hypothesis transparency | Megatrends with no evidence clearly marked as `hypothesis` |

**Reference:** [../patterns/anti-hallucination.md](../patterns/anti-hallucination.md)

---

## Phase Completion

**Verification (12 checks):**

- [ ] Seed megatrends loaded (if configured)
- [ ] All findings analyzed for thematic clustering
- [ ] Seeds matched against clusters
- [ ] Strategic narrative generated for each megatrend (700-1100 words)
- [ ] Executive summary populated for each megatrend
- [ ] Key Findings section contains 3-5 finding summaries (not placeholder)
- [ ] Inline citations present in Trend and Implication sections (3+ per megatrend)
- [ ] Solution section uses horizon-specific template (ACT/PLAN/OBSERVE)
- [ ] Word count verification passed for all sections
- [ ] Megatrend entities written to `${MEGATRENDS_DIR}/data/`
- [ ] Evidence strength and confidence scores calculated
- [ ] `MEGATRENDS_BY_DIMENSION` populated for backlinks
- [ ] Gap report generated (if gaps exist)

**Output:**

```text
Phase 5 Complete: Megatrend Clustering

Megatrends Created: {megatrends_created}
  - Hybrid (seed-validated): {seeds_validated}
  - Clustered (emergent): {clustered_count}
  - Hypothesis (seed-only): {hypothesis_megatrends}
Seeds Unmatched: {seeds_unmatched}
Backlinks: {dimension count} dimensions

-> Phase 6: Backlink Update & Response
```

**Mark Phase 5 complete.** Proceed to [phase-6-backlinks.md](phase-6-backlinks.md).
