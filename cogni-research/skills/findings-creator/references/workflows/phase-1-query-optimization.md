---
reference: phase-1-query-optimization
version: 8.2.0
checksum: phase-1-query-optimization-v8.2.0-adaptive-diversity
dependencies: []
phase: 1
architecture: llm-control
changelog: |
  v8.2.0: ADAPTIVE DIVERSITY - Add adaptive query count (#5), query diversity enforcement (#6), conditional year modifiers (#8) per LLM web search research
  v8.1.0: OUTCOME EXCLUSION - Remove Outcome (O) from query generation per Cochrane Handbook research (PMC6148624); O remains in metadata for Phase 4 quality scoring
  v8.0.0: ENHANCED COT - Added structured reasoning templates, think-before-act prompts, and explicit reasoning chains
  v7.0.0: Streamlined workflow with query-based localization
---

# Phase 1: Query Optimization Workflow

**Checksum:** `phase-1-query-optimization-v8.2.0-adaptive-diversity`

Output this checksum after reading to confirm reference loading.

---

## Purpose

Generate 4-7 optimized WebSearch configurations from a refined research question using facet-based decomposition and bilingual search strategies.

**Architecture:** Scripts handle I/O; LLM makes all semantic decisions including facet extraction and query optimization.

---

## Chain-of-Thought Protocol

This phase requires explicit reasoning before decisions. Use the **REASON → DECIDE → VERIFY** pattern:

| Step | Action | Output |
|------|--------|--------|
| **REASON** | Think through the problem space before acting | Internal reasoning block |
| **DECIDE** | Make explicit decision with rationale | Decision statement |
| **VERIFY** | Check decision against constraints | Verification assertion |

**Reasoning Block Format:**

```markdown
<reasoning>
**Analyzing:** [What am I evaluating?]
**Observations:** [What do I see in the data?]
**Considerations:** [What factors influence my decision?]
**Conclusion:** [What decision follows from this reasoning?]
</reasoning>
```

⚠️ **CRITICAL:** You MUST output reasoning blocks before making decisions in Steps 1.2, 1.3, and 1.4. Skipping reasoning leads to misaligned queries and context contamination.

---

## Phase Entry Verification

```bash
# Verify parameters
if [ -z "${REFINED_QUESTION_PATH:-}" ] || [ -z "${PROJECT_PATH:-}" ]; then
  exit 112
fi

# Verify entity exists
if [ ! -f "${REFINED_QUESTION_PATH}" ]; then
  exit 113
fi
```

---

## Step 0.5: Initialize Phase 1 TodoWrite

```text
- Phase 1, Step 1.1: Read refined question [in_progress]
- Phase 1, Step 1.2: Analyze facets, complexity, and entities [pending]
- Phase 1, Step 1.3: Determine constraints and select profiles [pending]
- Phase 1, Step 1.4: Build search configurations [pending]
- Phase 1, Step 1.5: Verify alignment and coverage [pending]
- Phase 1, Step 1.6: Validate config completeness [pending]
```

---

## Step 1.1: Read Refined Question

Read `${REFINED_QUESTION_PATH}` completely.

**Extract:**

| Element | Source | Usage |
|---------|--------|-------|
| Question ID | Filename (without .md) | Config ID prefix |
| Question text | H1 heading | Tier 1 queries |
| PICOT Framework | P+I+C (query), O+T (metadata) | Query keywords from P+I+C; O stored for Phase 4 quality scoring |
| Search Strategy | Expected source types | Profile selection |

Mark Step 1.1 completed.

---

## Step 1.2: Analyze Facets, Complexity, and Entities

**⚠️ COT REQUIRED:** This step requires explicit reasoning. Do not skip to outputs.

### 1.2.1 Facet Extraction with Reasoning

**Before extracting facets, output a reasoning block:**

```markdown
<reasoning>
**Analyzing:** The PICOT dimensions in question "{QUESTION_TEXT}"

**Observations:**
- Population dimension contains: [list specific terms found]
- Intervention dimension contains: [list specific terms found]
- Comparison dimension contains: [list specific terms found, or "none explicit"]
- (Outcome stored for Phase 4 quality scoring, not used in queries per PMC6148624)

**Considerations:**
- Which terms are distinct enough to warrant separate searches?
- Which terms are synonymous and should be grouped?
- Are there implicit facets not explicitly stated?

**Conclusion:** I identify [N] distinct searchable facets: [list them]
</reasoning>
```

**Facet Mapping Reference:**

| PICOT Dimension | Facet Types | Examples |
|-----------------|-------------|----------|
| Population | Audience, geography, company size | "IT-Leitung", "mittelständische Maschinenbauer" |
| Intervention | Technology, constraint | "Cloud-Strategien", "Datensouveränität" |
| Comparison | Alternatives being compared | "Public vs. Private vs. Hybrid" |

> **Note:** Outcome (O) is intentionally excluded from query generation. Cochrane Handbook research (PMC6148624) shows including Outcomes reduces recall because they often don't appear in abstracts. Outcome is stored in batch metadata for Phase 4 quality scoring.

### 1.2.2 Complexity Classification with Reasoning

**After facet extraction, reason about complexity:**

```markdown
<reasoning>
**Analyzing:** Complexity level for {FACET_COUNT} facets

**Observations:**
- Facet count: {N}
- Facet independence: [Are facets orthogonal or overlapping?]
- Search coverage risk: [Can fewer queries cover the space?]

**Considerations:**
- Simple (1-2 facets): Verbatim question may suffice
- Moderate (3-4 facets): Need keyword optimization
- Complex (5+ facets): Must decompose to avoid query dilution

**Conclusion:** Complexity is {LEVEL} because [specific reason]
</reasoning>
```

| Facet Count | Complexity | Query Strategy |
|-------------|------------|----------------|
| 1-2 | Simple | Verbatim question approach |
| 3-4 | Moderate | Keyword-optimized + 2-3 sub-queries |
| 5+ | Complex | Full facet decomposition (5-7 sub-queries) |

**Output:** `FACET_COUNT`, `COMPLEXITY_LEVEL`, `DECOMPOSITION_ENABLED` (true if ≥3 facets)

### 1.2.3 Entity Extraction with Reasoning

**Before classifying entity-specificity, reason through the question:**

```markdown
<reasoning>
**Analyzing:** Does "{QUESTION_TEXT}" target a specific named entity?

**Observations:**
- Named entities found: [list any proper nouns, company names, product names]
- Question structure: [Is it "What does X offer?" or "What are best practices?"]
- Research subject: [Is the entity the SUBJECT or just CONTEXT?]

**Considerations:**
- Entity-specific: The entity's offerings/capabilities ARE the research goal
- NOT entity-specific: The entity is context, but topic is general

**Entity-Specific Indicators Present:**
- [ ] "What does [Entity] offer/provide?"
- [ ] "What are [Entity]'s capabilities?"
- [ ] "[Entity] services/products/solutions"

**NOT Entity-Specific Indicators Present:**
- [ ] "Best practices for X"
- [ ] "How do [category] companies approach X?"
- [ ] General topic with entity as example

**Conclusion:** ENTITY_SPECIFIC = {true/false} because [specific reason]
</reasoning>
```

**Output:**

| Variable | Type | Description |
|----------|------|-------------|
| `ENTITY_SPECIFIC` | boolean | Does question target a named entity? |
| `PRIMARY_ENTITY` | string/null | Main entity name (e.g., "DB Systel") |
| `ENTITY_VARIANTS` | array | Name variants for search (e.g., ["DB Systel", "DB Systel GmbH"]) |

Mark Step 1.2 completed.

---

## Step 1.3: Determine Constraints and Select Profiles

### 1.3.1 Temporal Constraints

| Horizon | max_source_age_months | Notes |
|---------|----------------------|-------|
| Act (0-2 years) | 24 | Current + previous year |
| Plan (2-5 years) | 36 | 3 years coverage |
| Observe (5+ years) | 60 | Long-term trends |

Volatile topics (AI, regulations, markets): halve max_source_age_months.

**Conditional Year Modifier Strategy:**

> **Research Note:** Waseda University (Fang et al., 2025) found LLM reranking has strong recency bias—top-10 results can shift 1-5 years newer. For evergreen topics, year modifiers inappropriately deprioritize authoritative older sources.

| Topic Type | Year Modifier | Rationale |
|------------|---------------|-----------|
| Volatile (technology, regulations, markets) | ADD year keywords | Recency critical |
| Evergreen (history, foundational concepts) | OMIT year keywords | Preserve authoritative older sources |
| Mixed/Unclear | ADD year keywords | Default to recency |

**Topic Classification Reasoning (MANDATORY):**

```markdown
<temporal-reasoning>
**Analyzing:** Is "{QUESTION_TEXT}" volatile or evergreen?

**Volatile Indicators:**
- [ ] Technology trend (AI, cloud, cybersecurity)
- [ ] Regulatory/policy topic
- [ ] Market/competitive analysis
- [ ] Current events dependency

**Evergreen Indicators:**
- [ ] Historical analysis
- [ ] Foundational concepts/theory
- [ ] Established methodology
- [ ] Reference/educational content

**Conclusion:** Topic is {VOLATILE/EVERGREEN} → {ADD/OMIT} year modifiers in queries
</temporal-reasoning>
```

### 1.3.2 Language/Region

- `language`: Primary language (en/de/fr/es)
- `region_keywords`: Location terms (e.g., "Deutschland", "DACH")

**Localization Strategy:** Use native language queries + location keywords (WebSearch has no user_location parameter).

### 1.3.3 Profile Selection

**Tier 1 (Standard):**

| Profile | Purpose | Domain Parameter |
|---------|---------|------------------|
| `general` | Broad web | `blocked_domains` |
| `localized` | Region-specific | `blocked_domains` + native query |
| `industry` | News/business | `allowed_domains` |
| `academic` | Research | `allowed_domains` |

**Tier 2 (PICOT-Derived):**

| Profile      | When to Add                                     |
|--------------|------------------------------------------------|
| `population` | Distinct professional roles in PICOT.Population |
| `comparison` | Contrast elements in PICOT.Comparison           |

> **Note:** The `outcome` profile has been removed from query generation. Outcome-focused queries reduce recall per Cochrane Handbook research (PMC6148624). Outcome data remains in batch metadata for Phase 4 topical relevance scoring.

**Always include:** `general` + `localized` (if non-English) + at least 2 specialized profiles.

### 1.3.4 Query Length Guidelines

| Query Type | Target Length | Use Case |
|------------|---------------|----------|
| Keyword-optimized | 20-50 chars | Facet-specific queries |
| Short natural language | 50-100 chars | Focused topic queries |
| Full natural language | 100-200 chars | Core question (Tier 1 only) |

**Best practices:**

- 3-7 keywords per facet-specific query
- Preserve domain-specific terms verbatim (e.g., "Datensouveränität")
- Add temporal modifiers (years) at end (unless evergreen topic per 1.3.1)

### 1.3.5 Adaptive Query Count Strategy

> **Research Basis:** DMQR-RAG (2024) shows adaptive selection reduces rewrites by ~40% (from 4 to average 2.45) while improving performance. Both too few and too many queries harm results.

**Decision Matrix:**

| Condition | Query Count | Rationale |
|-----------|-------------|-----------|
| Simple (1-2 facets) | 4 | Minimum coverage sufficient |
| Moderate (3-4 facets), good diversity | 4-5 | Avoid query dilution |
| Complex (5+ facets) | 5-6 | Full decomposition needed |
| Diminishing returns detected | Stop early | Quality plateau reached |

**Quality Plateau Detection:**

- If 3+ candidate configs have >50% lexical overlap → reduce count
- If diversity score <0.3 for new query candidate → skip it
- Target: Average 4-5 configs (not maximum 7)

**Adaptive Count Reasoning:**

```markdown
<adaptive-count-reasoning>
**Analyzing:** Optimal query count for "{QUESTION_TEXT}"

**Inputs:**
- Facet count: {N}
- Complexity: {simple/moderate/complex}
- Topic type: {volatile/evergreen}

**Coverage Assessment:**
- Minimum configs for P+I coverage: {N}
- Additional for C coverage (if present): {0-1}
- Bilingual requirement: {+1 if non-English}

**Diversity Check (preliminary):**
- Can 4 queries cover all facets? {yes/no}
- Would 5th query add distinct coverage? {yes/no}
- Diminishing returns risk: {low/medium/high}

**Conclusion:** Generate {N} configs (not maximum 7)
</adaptive-count-reasoning>
```

Mark Step 1.3 completed.

---

## Step 1.4: Build Search Configurations

**⚠️ COT REQUIRED:** Each configuration requires explicit reasoning about query construction.

### 1.4.0 Pre-Construction Reasoning (MANDATORY)

**Before building ANY configuration, output this planning block:**

```markdown
<reasoning>
**Analyzing:** Query construction strategy for "{QUESTION_TEXT}"

**Key Variables:**
- Language: {LANGUAGE}
- Complexity: {COMPLEXITY_LEVEL}
- Entity-specific: {ENTITY_SPECIFIC}
- Facet count: {FACET_COUNT}

**Query Distribution Plan:**
| Profile | Language | Primary Focus | Facets Covered |
|---------|----------|---------------|----------------|
| general | {lang} | [focus] | [which facets] |
| localized | {lang} | [focus] | [which facets] |
| industry | {lang} | [focus] | [which facets] |
| academic | en | [focus] | [which facets] |

**Coverage Analysis:**
- PICOT Population coverage: [which configs address this?]
- PICOT Intervention coverage: [which configs address this?]
- Entity preservation (if applicable): [which configs include PRIMARY_ENTITY?]

**Risk Assessment:**
- Query too broad? [yes/no - if yes, how to narrow?]
- Query too narrow? [yes/no - if yes, how to broaden?]
- Missing facets? [list any uncovered facets]

**Conclusion:** Building {N} configs with strategy: [brief description]
</reasoning>
```

### 1.4.1 Bilingual Strategy (Non-English Questions)

| Query Set | Language | Profiles |
|-----------|----------|----------|
| Set A (2-3) | Original | `localized`, `trade`, `general` |
| Set B (2-4) | English | `academic`, `industry`, `outcome` |

**Translation rules:**

- Keep domain-specific terms verbatim ("Datensouveränität", "Mittelstand")
- Translate generic terms ("Cloud-Strategien" → "cloud strategies")

### 1.4.2 Entity Preservation (Entity-Specific Questions)

**⛔ CRITICAL:** For entity-specific questions, PRIMARY_ENTITY MUST appear in ALL queries regardless of language.

Entity names are proper nouns - they do NOT get translated.

| ❌ Bad (entity dropped) | ✅ Good (entity preserved) |
|------------------------|---------------------------|
| "low-code platforms enterprise 2024" | "DB Systel low-code platforms 2024" |
| "cloud strategy manufacturing SMB" | "DB Systel cloud strategy manufacturing" |

### 1.4.3 Config JSON Structure

```json
{
  "config_id": "{question_id}-{profile}",
  "profile": "{profile_name}",
  "tier": 1,
  "query_text": "{original_or_variant}",
  "websearch_params": {
    "query": "{query_with_temporal}",
    "allowed_domains": ["domain.com"],
    "blocked_domains": ["social.com"]
  },
  "picot_source": "{dimension_or_null}",
  "temporal_constraint": {
    "max_source_age_months": 24,
    "required_years": ["2024", "2025"],
    "planning_horizon": "act",
    "is_volatile": false
  }
}
```

**WebSearch Parameter Rules:**

| Rule | Requirement |
|------|-------------|
| Domain format | No HTTP scheme (`example.com` not `https://example.com`) |
| Mutual exclusivity | Use `allowed_domains` OR `blocked_domains`, never both |
| Query length | Max ~2000 chars |

**Blocked domains (general profile):** pinterest.com, facebook.com, instagram.com, tiktok.com, reddit.com, quora.com, medium.com

### 1.4.4 Facet Decomposition (Complex Questions Only)

**Prerequisite:** `DECOMPOSITION_ENABLED == true` (3+ facets)

For each major facet:

1. Extract 2-5 facet keywords
2. Add 1-2 context keywords
3. Add temporal modifier
4. Assign appropriate profile

**Facet-to-Profile Mapping:**

| Facet Type | Recommended Profile |
|------------|---------------------|
| Technical constraint | `academic`, `trade` |
| Business outcome | `industry`, `outcome` |
| Technology comparison | `academic`, `comparison` |
| Audience-specific | `population`, `trade` |

**Decomposition Quality Gates:**

- Maximum 7 configs total
- Each config has distinct query_text
- At least 1 config in original language (if non-English)
- At least 1 config in English
- Query length 30-100 chars for facet-specific queries

Mark Step 1.4 completed.

---

## Step 1.5: Verify Alignment and Coverage

**⚠️ COT REQUIRED:** This is the critical anti-contamination checkpoint. Explicit reasoning prevents query drift.

### 1.5.0 Pre-Verification Reasoning (MANDATORY)

**Before running ANY verification, output this contamination check:**

```markdown
<reasoning>
**Analyzing:** Contamination risk for question "{REFINED_QUESTION_ID}"

**Context Contamination Signals:**
- Am I carrying context from a previous question? [yes/no]
- Do I remember processing a different question recently? [yes/no]
- Are any config_ids using a different question prefix? [yes/no]

**Current Question Identity:**
- REFINED_QUESTION_ID: {exact value}
- Expected config_id prefix: {REFINED_QUESTION_ID}-
- PICOT.Intervention keywords: [list from CURRENT question]
- PICOT.Population keywords: [list from CURRENT question]

**Query-to-PICOT Mapping:**
| Config | Query Keywords | Matches Intervention? | Matches Population? |
|--------|---------------|----------------------|---------------------|
| config-1 | [keywords] | [yes/no - which?] | [yes/no - which?] |
| config-2 | [keywords] | [yes/no - which?] | [yes/no - which?] |
| ... | ... | ... | ... |

**Contamination Assessment:**
- Config ID prefix violations: [count] of [total]
- Queries missing Intervention coverage: [count]
- Queries missing Population coverage: [count]
- Overall contamination risk: [NONE/LOW/HIGH]

**Conclusion:** Alignment status is [PASS/FAIL] because [specific reason]
</reasoning>
```

### 1.5.1 PICOT-Query Alignment (Anti-Contamination)

**Purpose:** Ensure queries address the CURRENT question's PICOT, not a prior cached question.

**Extract PICOT keywords:**

| Dimension | Extraction |
|-----------|------------|
| Intervention (required) | 2-5 core topic terms |
| Population (required) | 2-5 audience terms |

**Verification checks:**

| Check | Requirement | Failure Action |
|-------|-------------|----------------|
| Intervention coverage | ≥1 query contains ≥2 Intervention keywords | FAIL - regenerate |
| Population coverage | ≥1 query contains ≥1 Population keyword | FAIL - regenerate |
| Config ID prefix | ALL config_ids start with `{REFINED_QUESTION_ID}-` | FAIL - context contamination |

### 1.5.1.1 Query Diversity Validation

> **Research Basis:** Queries should have <30% lexical term overlap and >0.3 semantic distance to avoid redundant searches.

**For each query pair, verify diversity:**

```markdown
<diversity-reasoning>
**Comparing:** Config A "{config_id_a}" vs Config B "{config_id_b}"

**Lexical Overlap Analysis:**
- Query A terms: [{term list}]
- Query B terms: [{term list}]
- Shared terms: [{shared}]
- Overlap: {shared_count / total_unique × 100}%
- Threshold: <30%
- Status: {PASS/FAIL}

**Semantic Distance Estimate:**
- Core focus A: [{main concepts}]
- Core focus B: [{main concepts}]
- Are these targeting different aspects? {yes/no}
- Estimated distance: {high/medium/low}
- Threshold: >0.3 (medium or high)
- Status: {PASS/FAIL}

**Conclusion:** Diversity {PASS/FAIL}
</diversity-reasoning>
```

**If diversity FAIL (>30% overlap or low semantic distance):**

1. Merge similar queries into one (combine best keywords)
2. OR differentiate by adding distinct facet focus
3. OR remove redundant query (reduce count per 1.3.5)

**Minimum diversity requirements:**

- No two queries should share >50% of terms
- Each query should target a distinct facet or profile purpose
- Bilingual pairs (same content, different language) are exempt

### 1.5.2 Entity Coverage with Reasoning (Entity-Specific Questions Only)

**⛔ GATE CHECK (if ENTITY_SPECIFIC == true):**

**Before checking entity coverage, reason through the requirement:**

```markdown
<reasoning>
**Analyzing:** Entity preservation for PRIMARY_ENTITY = "{PRIMARY_ENTITY}"

**Entity Presence Audit:**
| Config | Query Text | Entity Present? | Entity Variant Used |
|--------|-----------|-----------------|---------------------|
| config-1 | "{query}" | [yes/no] | [which variant] |
| config-2 | "{query}" | [yes/no] | [which variant] |
| ... | ... | ... | ... |

**Tier Analysis:**
- Tier 1 queries: [list config_ids]
- Tier 1 with entity: [count]/[total] = [X]%
- Tier 2 queries: [list config_ids]
- Tier 2 with entity: [count]/[total] = [X]% (MUST be 100%)

**Coverage Gaps:**
- Configs missing entity: [list]
- Can these be fixed? [yes - how / no - why]

**Conclusion:** Entity coverage is [PASS/FAIL] because [specific reason]
</reasoning>
```

| Check | Requirement | Failure |
|-------|-------------|---------|
| Tier 1 coverage | ≥1 Tier 1 query contains PRIMARY_ENTITY | FAIL |
| Tier 2 coverage | **100%** of Tier 2 queries contain PRIMARY_ENTITY | FAIL |

### 1.5.3 Anti-Contamination Assertion (MANDATORY OUTPUT)

**After reasoning, output this structured assertion:**

```markdown
**PICOT Alignment Verification:**
- Question ID: {REFINED_QUESTION_ID}
- Intervention keywords found: [list]
- Population keywords found: [list]
- Config ID prefix check: PASS/FAIL
- Alignment status: PASS/FAIL

**Entity Coverage Verification:** (if ENTITY_SPECIFIC)
- PRIMARY_ENTITY: {entity_name}
- Tier 1 coverage: PASS/FAIL
- Tier 2 coverage: {X}% ({count}/{total}) - MUST be 100%
- Status: PASS/FAIL

**Contamination Check:**
- Context drift detected: YES/NO
- Prior question artifacts: NONE/[list if found]
- Verification confidence: HIGH/MEDIUM/LOW
```

Mark Step 1.5 completed.

---

## Step 1.6: Validate Config Completeness

**⛔ GATE CHECK:** Verify SEARCH_CONFIGS meets minimum requirements.

```bash
# Minimum 4 configs required
if [ "$CONFIG_COUNT" -lt 4 ]; then
  echo "FATAL: SEARCH_CONFIGS incomplete: $CONFIG_COUNT (minimum 4)" >&2
  exit 121
fi

# Verify each config has required fields
for config in SEARCH_CONFIGS; do
  # Check: config_id, profile, websearch_params.query
  if [ -z "$config.config_id" ] || [ -z "$config.profile" ] || [ -z "$config.websearch_params.query" ]; then
    echo "ERROR: Config missing required fields" >&2
    exit 121
  fi
done
```

**Minimum configs by complexity:**

| Complexity | Min | Required Profiles |
|------------|-----|-------------------|
| Simple | 4 | general, localized, industry, academic |
| Moderate | 4-5 | + 1-2 PICOT-derived |
| Complex | 5-7 | Full facet decomposition |

### Log Statistics

```bash
log_phase "Phase 1: Query Optimization" "complete"
log_metric "configs_generated" "$CONFIG_COUNT" "count"
log_metric "facet_count" "$FACET_COUNT" "count"
log_metric "complexity_level" "$COMPLEXITY_LEVEL" "level"
log_metric "entity_specific" "$ENTITY_SPECIFIC" "boolean"
log_metric "bilingual_queries" "$BILINGUAL_COUNT" "count"
```

Mark Step 1.6 completed. Mark Phase 1 phase-level todo completed.

---

## Phase 1 Completion Checklist

**Core Requirements:**

- [ ] Refined question loaded completely
- [ ] Facets analyzed and complexity determined
- [ ] 4-7 search configs generated (minimum 4)
- [ ] Query lengths optimized (30-100 chars for facet-specific)

**Alignment Verification:**

- [ ] Config ID prefix matches REFINED_QUESTION_ID
- [ ] Intervention keywords present in ≥1 query
- [ ] Population keywords present in ≥1 query

**Entity Requirements (if ENTITY_SPECIFIC):**

- [ ] Entity extraction completed
- [ ] Tier 1 query contains PRIMARY_ENTITY
- [ ] ALL Tier 2 queries contain PRIMARY_ENTITY (100% coverage)

**Bilingual Requirements (if non-English):**

- [ ] At least 1 query in original language
- [ ] At least 1 query in English

**Structure Validation:**

- [ ] Each config has config_id, profile, and query
- [ ] No duplicate queries across configs
- [ ] Statistics logged

---

## Expected Outputs

| Output | Format | Description |
|--------|--------|-------------|
| SEARCH_CONFIGS | JSON array | 4-7 search configurations |
| REFINED_QUESTION_ID | String | From filename |
| LANGUAGE | String | en/de/fr/es |
| FACET_COUNT | Integer | Number of facets (1-10) |
| COMPLEXITY_LEVEL | String | simple/moderate/complex |
| ENTITY_SPECIFIC | Boolean | Targets named entity? |
| PRIMARY_ENTITY | String/null | Entity name if applicable |
| ALIGNMENT_STATUS | Boolean | PICOT-query alignment passed |
| ENTITY_COVERAGE_STATUS | String | PASS/FAIL/N/A |

---

## Validation Gates

| Gate | Condition | Exit Code |
|------|-----------|-----------|
| Question loaded | Entity exists | 113 |
| Query extracted | Non-empty text | 121 |
| Config count | 4-7 items (min 4) | 121 |
| Config ID prefix | Matches REFINED_QUESTION_ID | 121 |
| Intervention coverage | ≥1 query has ≥2 keywords | 121 |
| Population coverage | ≥1 query has ≥1 keyword | 121 |
| Entity Tier 1 (if applicable) | ≥1 Tier 1 query has entity | 121 |
| Entity Tier 2 (if applicable) | 100% Tier 2 queries have entity | 121 |

---

## See Also

- [phase-2-batch-creation.md](phase-2-batch-creation.md) - Stores configurations
- [phase-3-search-execution.md](phase-3-search-execution.md) - Executes WebSearch
- [phase-4-finding-extraction.md](phase-4-finding-extraction.md) - Uses temporal constraints
