---
reference: phase-3-search-execution
version: 5.1.0
checksum: phase-3-search-execution-v5.1.0-advanced-dedup
dependencies: [WebSearch tool]
phase: 3
architecture: llm-control
changelog: |
  v5.1.0: ADVANCED DEDUP - Add BM25 snippet scoring (#4), semantic deduplication (#2), MinHash near-duplicate (#7), RRF cross-profile ranking (#3) per LLM web search research
  v5.0.0: ENHANCED COT - Added structured reasoning templates, completion checklist, complete example, self-verification questions, portable bash patterns
  v4.1.0: FILE CONTRACT - Read batch reference file from Phase 2 with fail-fast gate
  v4.0.0: LLM-control architecture - removed all bash loops
---

# Phase 3: Search Execution Workflow

**Checksum:** `phase-3-search-execution-v5.1.0-advanced-dedup`

Output this checksum after reading to confirm reference loading.

---

## Purpose

Execute WebSearch for each search configuration from the batch entity:

1. **Load batch entity** - Read search_configs from Phase 2 batch
2. **Invoke WebSearch** with profile-specific parameters (query, location, domains)
3. **Evaluate results** per profile against quality thresholds
4. **Aggregate and deduplicate** results with source profile tracking
5. **Export SEARCH_RESULTS** for Phase 4 consumption

---

## Chain-of-Thought Protocol

This phase requires explicit reasoning before search decisions. Use the **PLAN → EXECUTE → EVALUATE** pattern:

| Step | Action | Output |
|------|--------|--------|
| **PLAN** | Analyze batch config, plan search parameters | Reasoning block |
| **EXECUTE** | Invoke WebSearch with exact parameters | Search results |
| **EVALUATE** | Assess result quality per profile | Quality metrics |

**Search Planning Reasoning Block Format:**

```markdown
<reasoning>
**Analyzing:** Search config for profile "{profile}"
**Config Details:**
- Config ID: {config_id}
- Query: "{query_text}"
- Domain filter: {allowed_domains OR blocked_domains}
**Parameter Decisions:**
- Using {allowed|blocked}_domains because {reason}
- Query includes temporal modifiers: {year keywords}
**Conclusion:** Ready to execute WebSearch with {profile} parameters
</reasoning>
```

**Result Evaluation Reasoning Block Format:**

```markdown
<quality-reasoning>
**Profile:** {profile}
**Results Returned:** {count}
**Quality Assessment:**
- Usable results: {N} (after filtering low-quality snippets)
- Success level: {1|3|5} because {threshold comparison}
- Domain distribution: {list unique domains}
**Conclusion:** {PASS|PARTIAL|WARNING} - {brief rationale}
</quality-reasoning>
```

⚠️ **CRITICAL:** Output reasoning blocks before WebSearch calls (Step 3.2) and after evaluating results (Step 3.3). Silent execution leads to misconfigured searches and missed quality issues.

---

## Prohibited Patterns

**Execution - NEVER use:**

| Anti-Pattern | Why Prohibited | Correct Approach |
|--------------|----------------|------------------|
| Bash loops for iterating search_configs | LLM iterates naturally in context | Process configs sequentially in LLM memory |
| jq/yq for extracting YAML fields | LLM reads YAML directly | Parse YAML from Read tool output |
| Bash arrays for result storage | LLM tracks in memory | Store results in structured reasoning |
| Script delegation for deduplication | LLM reasoning is superior | Deduplicate with explicit URL comparison |

**WebSearch - NEVER combine:**

| Anti-Pattern | Example | Result |
|--------------|---------|--------|
| `allowed_domains` AND `blocked_domains` | `{allowed_domains: [...], blocked_domains: [...]}` | API error - mutually exclusive |
| HTTP scheme in domains | `["https://reuters.com"]` | API error - use `["reuters.com"]` |
| Query exceeding ~2000 chars | Long query with multiple modifiers | `query_too_long` error |

**Domain Specification - CORRECT vs WRONG:**

```json
// ✅ CORRECT - domain names only
"allowed_domains": ["reuters.com", "bloomberg.com"]

// ❌ WRONG - includes HTTP scheme
"allowed_domains": ["https://reuters.com", "https://bloomberg.com"]

// ✅ CORRECT - use ONE of these, never both
"allowed_domains": ["reuters.com"]
// OR
"blocked_domains": ["pinterest.com"]

// ❌ WRONG - both specified (API will fail)
"allowed_domains": ["reuters.com"], "blocked_domains": ["pinterest.com"]
```

---

## Step 0.5: Initialize Phase 3 TodoWrite

Expand phase-level todo into step-level todos:

```text
- Phase 3, Step 3.0: Read batch reference file (fail-fast gate) [in_progress]
- Phase 3, Step 3.1: Load batch entity and extract search_configs [pending]
- Phase 3, Step 3.2: Execute WebSearch for each config [pending]
- Phase 3, Step 3.3: Evaluate result quality per profile [pending]
- Phase 3, Step 3.4: Aggregate and deduplicate results [pending]
- Phase 3, Step 3.5: Build and export SEARCH_RESULTS [pending]
```

---

## Step 3.0: Verify Batch Reference Variables (Fail-Fast Gate)

**⛔ MANDATORY GATE:** Phase 3 MUST verify the batch reference variables exported by Phase 2. If these variables are not set, Phase 3 MUST NOT proceed.

> **⚠️ IMPORTANT - Race Condition Prevention:**
> Previous versions read from `.metadata/current-batch.json`, which caused race conditions when multiple `findings-creator` instances ran in parallel. The in-memory variable approach eliminates this issue since each agent invocation has its own environment.

### Verify Batch Reference Variables

Check that Phase 2 exported the required variables:

```bash
# Verify batch reference variables from Phase 2
if [ -z "${BATCH_ID:-}" ]; then
  log_error "FATAL: BATCH_ID not set - Phase 2 did not complete"
  exit 121
fi

if [ -z "${BATCH_FILE:-}" ]; then
  log_error "FATAL: BATCH_FILE not set - Phase 2 did not complete"
  exit 122
fi

log_conditional INFO "Batch reference verified: BATCH_ID=${BATCH_ID}"
```

### Gate Decision

| Variable Status | Action |
|-----------------|--------|
| BATCH_ID and BATCH_FILE set | Continue to Step 3.1 |
| BATCH_ID not set | **STOP** - Exit with code 121 |
| BATCH_FILE not set | **STOP** - Exit with code 122 |

### Available Variables from Phase 2

| Variable | Usage |
|----------|-------|
| `BATCH_ID` | Batch identifier for this phase |
| `BATCH_FILE` | Path to batch entity to load in Step 3.1 |
| `BATCH_CONFIG_COUNT` | Expected number of search configs |
| `BATCH_QUESTION_REF` | Wikilink to refined question |

**Why This Gate Exists:**

This variable-based contract ensures Phase 2 completed successfully before Phase 3 begins. Without this gate, Phase 3 might attempt to read a batch entity that doesn't exist or is incomplete, causing cryptic failures downstream.

**On Success:**

- Verify `BATCH_ID` is set
- Verify `BATCH_FILE` is set
- Mark Step 3.0 completed
- Log: "Batch reference verified: BATCH_ID=${BATCH_ID}"

**On Failure:**

- Log: "ERROR: Batch reference variables not set. Phase 2 must complete before Phase 3."
- Exit with appropriate code (121/122)
- Do NOT proceed to Step 3.1

Mark Step 3.0 completed before proceeding.

---

## Step 3.1: Load Batch Entity

Read the batch entity using the path from Step 3.0.

**Input:** `${PROJECT_PATH}/${BATCH_FILE}` (from Step 3.0, e.g., `03-query-batches/data/{batch_id}.md`)

### Step 3.1.1: Read Batch File

Use the Read tool to load the batch entity:

```text
Read: ${PROJECT_PATH}/${BATCH_FILE}
```

**If the file does not exist or is empty:** STOP. Do not proceed. Exit with code 122.

### Step 3.1.2: Extract from YAML Frontmatter

| Field | Purpose |
|-------|---------|
| `query_text` | Verbatim question for logging |
| `search_configs[]` | Array of search configurations |
| `config_count` | Number of configs to execute |
| `content_language` | Language for localized searches |
| `temporal_constraints` | For query temporal modifiers |

### Step 3.1.3: Extract from Each search_config

| Field | WebSearch Mapping |
|-------|-------------------|
| `config_id` | For result tracking |
| `profile` | general, localized, industry, academic |
| `websearch_params.query` | WebSearch `query` parameter |
| `websearch_params.allowed_domains` | WebSearch `allowed_domains` (optional) |
| `websearch_params.blocked_domains` | WebSearch `blocked_domains` (optional) |

### Step 3.1.4: Validate Config Count

```bash
# Portable file size check (macOS + Linux compatible)
BATCH_SIZE=$(wc -c < "$BATCH_FILE" | tr -d ' ')
if [ "$BATCH_SIZE" -lt 500 ]; then
  echo "ERROR: Batch file too small ($BATCH_SIZE bytes)" >&2
  exit 122
fi

CONFIG_COUNT=$(grep -c 'config_id:' "$BATCH_FILE" || echo 0)
if [ "$CONFIG_COUNT" -lt 4 ]; then
  echo "ERROR: Insufficient configs: $CONFIG_COUNT (minimum 4)" >&2
  exit 122
fi
```

Mark Step 3.1 completed before proceeding.

---

## Step 3.2: Execute WebSearch for Each Config

**⚠️ COT REQUIRED:** Output reasoning block before each WebSearch call.

For each search_config, invoke WebSearch tool with **exact API parameter structure**.

**WebSearch API Reference:** `https://platform.claude.com/docs/en/agents-and-tools/tool-use/web-search-tool`

### 3.2.0 Pre-Search Reasoning (MANDATORY)

**Before EACH WebSearch call, output this reasoning block:**

```markdown
<reasoning>
**Analyzing:** Search config {N} of {total}
**Config ID:** {config_id}
**Profile:** {profile}
**Query:** "{websearch_params.query}"

**Parameter Validation:**
- Query length: {char_count} chars (max ~2000) ✅
- Domain filter type: {allowed_domains|blocked_domains|none}
- Domains: {list or "none"}
- Temporal modifiers present: {yes/no - which years, e.g., 2025, 2026}

**WebSearch Call Plan:**
- query: "{exact query string}"
- {allowed_domains|blocked_domains}: {list or omit}

**Conclusion:** Ready to execute WebSearch for {profile} profile
</reasoning>
```

### Parameter Mapping by Profile

| Profile | Parameters Used | Example |
|---------|-----------------|---------|
| General | query + blocked_domains | Block social media |
| Localized | query (native language + location keywords) + blocked_domains | German query with "Deutschland" keyword |
| Industry | query + allowed_domains | `["reuters.com", "bloomberg.com"]` |
| Academic | query + allowed_domains | `["scholar.google.com", "arxiv.org"]` |

### Exact WebSearch Tool Invocation

**General Profile (with blocked_domains):**

```yaml
WebSearch tool call:
  query: "Stellplatz market competitors Germany 2025 2026"
  blocked_domains: ["pinterest.com", "facebook.com", "instagram.com", "tiktok.com", "reddit.com"]
```

**Localized Profile (native language + location keywords + blocked_domains):**

```yaml
WebSearch tool call:
  query: "Stellplatz Vermittlung Wettbewerber Deutschland 2025 2026"
  blocked_domains: ["pinterest.com", "facebook.com", "instagram.com", "tiktok.com", "reddit.com"]
```

**Note:** Localization is achieved through native-language query terms and location keywords (e.g., "Deutschland"), not through API parameters.

**Industry Profile (with allowed_domains):**

```yaml
WebSearch tool call:
  query: "Stellplatz market competitors Germany 2025 2026"
  allowed_domains: ["reuters.com", "bloomberg.com", "handelsblatt.com", "ft.com"]
```

**Academic Profile (with allowed_domains):**

```yaml
WebSearch tool call:
  query: "motorhome pitch booking platform market share research 2025 2026"
  allowed_domains: ["scholar.google.com", "arxiv.org", "researchgate.net", "jstor.org"]
```

### Critical API Constraints

1. **Domains have NO HTTP/HTTPS scheme**:

   ```json
   // ✅ CORRECT
   "allowed_domains": ["reuters.com"]

   // ❌ WRONG
   "allowed_domains": ["https://reuters.com"]
   ```

2. **Never combine allowed_domains AND blocked_domains** - mutually exclusive

3. **Query max length ~2000 chars** - exceeding triggers `query_too_long` error

### Track for each config

- config_id
- profile
- results returned (array of {title, url, snippet})
- result_count
- any errors (rate_limit, query_too_long, no_results)

Mark Step 3.2 completed before proceeding.

---

## Step 3.3: Evaluate Result Quality Per Profile

**⚠️ COT REQUIRED:** Output quality reasoning block for each profile's results.

For each config's results, evaluate quality.

### 3.3.0 Post-Search Evaluation (MANDATORY)

**After receiving results for EACH config, output this reasoning block:**

```markdown
<quality-reasoning>
**Profile:** {profile}
**Config ID:** {config_id}
**Results Returned:** {total_count}

**Result Analysis:**
- Usable results (snippet ≥50 chars): {usable_count}
- Empty/thin results filtered: {filtered_count}
- Unique domains: [{list domains}]

**Quality Scoring:**
- Threshold: ≥3 usable = Success, 1-2 = Partial, 0 = Warning
- Usable count: {N}
- Success level: {1|3|5}

**Profile-Specific Assessment:**
- Expected range: {expected for this profile}
- Actual: {usable_count}
- Status: {within range|below range|above range}

**Conclusion:** Profile {profile} returned {usable_count} usable results → Success Level {level}
</quality-reasoning>
```

### Quality Thresholds

| Usable Results | Success Level | Status |
|----------------|---------------|--------|
| ≥3 | 5 | Success |
| 1-2 | 3 | Partial |
| 0 | 1 | Warning |

### Profile-Specific Expectations

| Profile | Expected Results | Notes |
|---------|------------------|-------|
| General | 5-10 | Broadest, should always return results |
| Localized | 3-8 | Region-specific, varies by topic |
| Industry | 2-5 | News domains, depends on recency |
| Academic | 1-3 | Fewer but higher quality |

### Track per config

- `results_count`: Number of usable results
- `success_level`: 1, 3, or 5

### 3.3.5 BM25 Relevance Pre-Scoring

> **Research Basis:** BM25 with k1=1.2, b=0.75 provides optimal first-stage relevance filtering before aggregation.

**Purpose:** Filter low-relevance results before aggregation to improve final result quality.

**BM25 Scoring (LLM Estimation):**

For each result, estimate relevance to the original query:

```markdown
<bm25-reasoning>
**Scoring:** "{result_title}"
**Original Query:** "{batch_query_text}"
**Query Terms:** [{list key terms from query}]

**Term Analysis in Snippet:**
| Term | Present? | Approx Frequency | Significance |
|------|----------|------------------|--------------|
| {term1} | yes/no | {count or N/A} | high/medium/low |
| {term2} | yes/no | {count or N/A} | high/medium/low |
| {term3} | yes/no | {count or N/A} | high/medium/low |

**Scoring Factors:**
- Term coverage: {matched}/{total} query terms = {percentage}%
- Snippet length: {approximate chars} (avg ~150)
- Key term presence: {assessment}

**BM25 Score Estimate:** {0.0-1.0}
- 0.7-1.0: High relevance (all key terms, good coverage)
- 0.4-0.6: Moderate relevance (some terms, partial coverage)
- 0.0-0.3: Low relevance (few terms, poor match)

**Threshold:** 0.3 (minimum to include)

**Decision:** {INCLUDE / FILTER_OUT}
</bm25-reasoning>
```

**Apply before Step 3.4:**
- Filter results with BM25 < 0.3 before aggregation
- Track `bm25_filtered_count` in metrics
- Log filtered results for debugging

Mark Step 3.3 completed before proceeding.

---

## Step 3.4: Aggregate and Deduplicate Results

Combine results from all profiles, removing duplicates.

### Deduplication Process

**Three-Layer Deduplication Pipeline:**

| Layer | Method | Threshold | Purpose |
|-------|--------|-----------|---------|
| 1 | Exact URL match | Identical | Obvious duplicates |
| 2 | MinHash/shingle similarity | Jaccard ≥ 0.8 | Near-identical content |
| 3 | Semantic similarity | Cosine > 0.92 | Paraphrased content |

**Layer 1: URL Deduplication (existing)**

1. Collect all results from all configs into single list
2. Group by URL (unique key)
3. For duplicates, track which profiles returned the URL
4. Keep single entry per URL with `source_profiles` array

**Layer 2: MinHash Near-Duplicate Detection**

> **Research Basis:** MinHash with 128 permutations and Jaccard threshold 0.8 catches near-identical content that URL matching misses.

For results with different URLs, check content similarity using shingles:

```markdown
<near-duplicate-reasoning>
**Comparing:** Result A (URL: {url_a}) vs Result B (URL: {url_b})

**Shingle Analysis (5-word sequences):**
- Snippet A shingles: ["{first 5 words}", "{words 2-6}", "{words 3-7}", ...]
- Snippet B shingles: ["{first 5 words}", "{words 2-6}", "{words 3-7}", ...]

**Jaccard Similarity:**
- Matching shingles: {count}
- Total unique shingles: {count}
- Jaccard = matching / total = {value}

**Threshold:** 0.8

**Decision:**
- If Jaccard ≥ 0.8: NEAR-DUPLICATE → Keep result with better source tier
- If Jaccard < 0.8: Proceed to Layer 3 (semantic check)

**Result:** {NEAR_DUPLICATE / PROCEED_TO_SEMANTIC}
</near-duplicate-reasoning>
```

**Layer 3: Semantic Deduplication**

> **Research Basis:** Cosine similarity threshold of 0.92 catches paraphrased duplicates.

For results passing Layer 2, check semantic similarity:

```markdown
<semantic-dedup-reasoning>
**Comparing:** Result A vs Result B

**Content Analysis:**
- Snippet A key claims: [{list 3-5 main points}]
- Snippet B key claims: [{list 3-5 main points}]

**Semantic Overlap:**
- Shared claims/concepts: {count}/{total}
- Same core message? {yes/no}
- Different perspective/angle? {yes/no}

**Estimated Cosine Similarity:** {0.0-1.0}
- 0.92-1.0: Near-identical meaning
- 0.7-0.91: Related but distinct
- <0.7: Different content

**Threshold:** 0.92

**Decision:**
- If similarity ≥ 0.92: SEMANTIC DUPLICATE → Keep better source
- If similarity < 0.92: UNIQUE → Keep both

**Priority for keeping (when deduplicating):**
1. Higher source tier (academic > industry > general)
2. Longer snippet (more content)
3. From more profiles (higher cross-profile validation)

**Result:** {DEDUPLICATE / KEEP_BOTH}
</semantic-dedup-reasoning>
```

### Deduplication Reasoning Block

```markdown
<reasoning>
**Analyzing:** Aggregating results from {N} profiles
**Raw Result Counts:**
- general: {count}
- localized: {count}
- industry: {count}
- academic: {count}
- **Total raw:** {sum}

**Deduplication Analysis:**
- Unique URLs found: {unique_count}
- Duplicate URLs: {list URLs appearing in multiple profiles}
- Cross-profile overlap: {percentage}

**Result Structure:**
Each deduplicated result includes:
- title, url, snippet from first occurrence
- source_profiles: [{list all profiles that returned this URL}]

**Conclusion:** {raw_total} raw results → {unique_count} unique after deduplication ({dedup_rate}% overlap)
</reasoning>
```

### Result Structure After Deduplication

```json
{
  "title": "Article Title",
  "url": "https://example.com/article",
  "snippet": "Article excerpt...",
  "source_profiles": ["general", "industry"]
}
```

### Calculate Metrics

- `total_raw_results`: Sum of all config result counts
- `unique_results`: Count after deduplication
- `deduplication_rate`: (total - unique) / total × 100
- `bm25_filtered_count`: Results removed by BM25 pre-scoring
- `near_duplicate_count`: Results merged by MinHash/semantic checks

### 3.4.5 RRF Cross-Profile Ranking

> **Research Basis:** Reciprocal Rank Fusion (RRF) with k=60 outperforms linear score combination for merging ranked lists from multiple sources.

**RRF Formula:** `RRF_score(d) = Σ 1/(k + rank_r(d))` where k=60

**Profile Reliability Weights:**

| Profile | Weight | Rationale |
|---------|--------|-----------|
| academic | 0.8 | Highest authority |
| industry | 0.7 | Professional sources |
| localized | 0.6 | Region-specific |
| general | 0.6 | Broad coverage |

**RRF Calculation for Each Result:**

```markdown
<rrf-reasoning>
**Calculating RRF for:** "{result_title}"
**URL:** {url}

**Profile Rankings:**
| Profile | Rank in Profile | Weight | RRF Contribution |
|---------|-----------------|--------|------------------|
| general | {rank or N/A} | 0.6 | {1/(60+rank) × 0.6 or 0} |
| localized | {rank or N/A} | 0.6 | {1/(60+rank) × 0.6 or 0} |
| industry | {rank or N/A} | 0.7 | {1/(60+rank) × 0.7 or 0} |
| academic | {rank or N/A} | 0.8 | {1/(60+rank) × 0.8 or 0} |

**Calculation:**
- Profiles returning this result: [{list}]
- Sum of weighted contributions: {total}

**RRF Score:** {final_score}
</rrf-reasoning>
```

**Apply RRF Ranking:**

1. Calculate RRF score for each deduplicated result
2. Sort results by RRF score descending
3. Store `rrf_score` with each result for Phase 4 prioritization
4. Top-ranked results appear first in SEARCH_RESULTS

**Updated Result Structure:**

```json
{
  "title": "Article Title",
  "url": "https://example.com/article",
  "snippet": "Article excerpt...",
  "source_profiles": ["general", "industry"],
  "rrf_score": 0.0234,
  "bm25_score": 0.72
}
```

Mark Step 3.4 completed before proceeding.

---

## Step 3.5: Build and Export SEARCH_RESULTS

Construct final JSON structure for Phase 4.

### SEARCH_RESULTS Structure

```json
{
  "batch_id": "{BATCH_ID}",
  "query_text": "{verbatim question}",
  "configs_executed": 4,
  "unique_results_count": 15,
  "results": [
    {
      "title": "...",
      "url": "...",
      "snippet": "...",
      "source_profiles": ["general"]
    }
  ],
  "profile_statistics": {
    "general": {"results_count": 8, "success_level": 5},
    "localized": {"results_count": 5, "success_level": 5},
    "industry": {"results_count": 3, "success_level": 3},
    "academic": {"results_count": 2, "success_level": 3}
  },
  "execution_metadata": {
    "total_raw_results": 18,
    "deduplication_rate": 16.7,
    "profiles_with_results": 4,
    "profiles_empty": 0
  }
}
```

### Export for Phase 4

Set `SEARCH_RESULTS` as environment variable or pass to Phase 4.

### Log Completion Metrics

```bash
# Log completion metrics
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 3 complete" >> "$LOG_FILE"
echo "  Configs executed: ${configs_executed}" >> "$LOG_FILE"
echo "  Total raw results: ${total_raw_results}" >> "$LOG_FILE"
echo "  Unique results: ${unique_results}" >> "$LOG_FILE"
echo "  Deduplication rate: ${deduplication_rate}%" >> "$LOG_FILE"
echo "  Profiles with results: ${profiles_with_results}" >> "$LOG_FILE"
```

Mark Step 3.5 completed and Phase 3 phase-level todo completed before proceeding to Phase 4.

---

## Self-Verification Questions

### Before Completing Phase 3 (Answer YES to all)

1. Did I read the batch entity file and extract all search_configs? YES/NO
2. Did I execute WebSearch for EACH config (minimum 4)? YES/NO
3. Did I use the correct domain filter type per profile (allowed vs blocked)? YES/NO
4. Did I NEVER combine allowed_domains AND blocked_domains in same call? YES/NO
5. Did I track results_count and success_level for each profile? YES/NO
6. Did I deduplicate results by URL before building SEARCH_RESULTS? YES/NO
7. Is unique_results_count > 0 (at least some results obtained)? YES/NO

**If ANY NO:** Fix issue before marking Phase 3 complete.

---

## Fallback Strategy

With profile-based diversity, fallback is minimal:

**If unique_results < 3 across all profiles:**

- Log warning: "Low result count - proceeding with available results"
- Continue to Phase 4 (finding extraction handles sparse data)

**Why no query transformation:**

- Verbatim question already optimized in Phase 1
- Profile diversity covers search space
- Transformation would degrade natural language quality

---

## Phase 3 Completion Checklist

### ⛔ MANDATORY: All items MUST be checked before proceeding to Phase 4

**Core Requirements:**

- [ ] Batch reference variables verified (BATCH_ID, BATCH_FILE set)
- [ ] Batch entity loaded successfully (≥500 bytes)
- [ ] search_configs extracted (minimum 4 configs)
- [ ] WebSearch executed for ALL configs
- [ ] No API errors (query_too_long, domain format, mutual exclusivity)

**Quality Tracking:**

- [ ] results_count tracked per profile
- [ ] success_level assigned per profile (1, 3, or 5)
- [ ] Quality reasoning blocks output for each profile

**Aggregation:**

- [ ] Results deduplicated by URL
- [ ] source_profiles array populated for each result
- [ ] Deduplication metrics calculated

**Export:**

- [ ] SEARCH_RESULTS structure built with all required fields
- [ ] unique_results_count > 0 (or fallback strategy applied)
- [ ] Completion metrics logged
- [ ] Step 3.5 todo marked completed
- [ ] Phase 3 phase-level todo marked completed

---

## Expected Outputs

| Output | Format | Validation |
|--------|--------|------------|
| SEARCH_RESULTS | JSON object | Contains results[] array |
| unique_results_count | Number | ≥0, typically 5-20 |
| results[].source_profiles | Array | Tracks profile provenance |
| profile_statistics | Object | Per-profile counts and levels |
| execution_metadata | Object | Raw counts, dedup rate, profile coverage |

---

## Complete Example

**Scenario:** Executing searches for question "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?"

### Step 3.0: Verify Variables

```bash
BATCH_ID="question-ki-anwendungen-produktion-v5w6x7y8-batch"
BATCH_FILE="03-query-batches/data/question-ki-anwendungen-produktion-v5w6x7y8-batch.md"
# Both set → Continue to Step 3.1
```

### Step 3.1: Load Batch Entity

**Read batch file, extract:**

```yaml
query_text: "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?"
config_count: 4
search_configs:
  - config_id: "config-a1b2c3d4..."
    profile: "general"
    websearch_params:
      query: "KI-Anwendungen Produktion Maschinenbau 2025 2026"
      blocked_domains: ["pinterest.com", "facebook.com"]
  # ... 3 more configs
```

### Step 3.2: Execute WebSearch (with reasoning)

**Config 1 Pre-Search Reasoning:**

```markdown
<reasoning>
**Analyzing:** Search config 1 of 4
**Config ID:** config-a1b2c3d4...
**Profile:** general
**Query:** "KI-Anwendungen Produktion Maschinenbau 2025 2026"

**Parameter Validation:**
- Query length: 52 chars (max ~2000) ✅
- Domain filter type: blocked_domains
- Domains: ["pinterest.com", "facebook.com"]
- Temporal modifiers present: yes - 2025, 2026

**WebSearch Call Plan:**
- query: "KI-Anwendungen Produktion Maschinenbau 2025 2026"
- blocked_domains: ["pinterest.com", "facebook.com"]

**Conclusion:** Ready to execute WebSearch for general profile
</reasoning>
```

**WebSearch call:**

```yaml
WebSearch:
  query: "KI-Anwendungen Produktion Maschinenbau 2025 2026"
  blocked_domains: ["pinterest.com", "facebook.com"]
```

**Returns:** 8 results

### Step 3.3: Evaluate Quality

**Post-Search Evaluation:**

```markdown
<quality-reasoning>
**Profile:** general
**Config ID:** config-a1b2c3d4...
**Results Returned:** 8

**Result Analysis:**
- Usable results (snippet ≥50 chars): 7
- Empty/thin results filtered: 1
- Unique domains: [vdi.de, handelsblatt.com, fraunhofer.de, iwkoeln.de, bmwi.de, industrie.de, vdma.org]

**Quality Scoring:**
- Threshold: ≥3 usable = Success, 1-2 = Partial, 0 = Warning
- Usable count: 7
- Success level: 5

**Profile-Specific Assessment:**
- Expected range: 5-10 for general profile
- Actual: 7
- Status: within range ✅

**Conclusion:** Profile general returned 7 usable results → Success Level 5
</quality-reasoning>
```

### Step 3.4: Aggregate Results

```markdown
<reasoning>
**Analyzing:** Aggregating results from 4 profiles
**Raw Result Counts:**
- general: 7
- localized: 5
- industry: 3
- academic: 2
- **Total raw:** 17

**Deduplication Analysis:**
- Unique URLs found: 14
- Duplicate URLs: [vdma.org/ki-studie, fraunhofer.de/maschinenbau-ki]
- Cross-profile overlap: 17.6%

**Conclusion:** 17 raw results → 14 unique after deduplication (17.6% overlap)
</reasoning>
```

### Step 3.5: Export SEARCH_RESULTS

```json
{
  "batch_id": "question-ki-anwendungen-produktion-v5w6x7y8-batch",
  "query_text": "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?",
  "configs_executed": 4,
  "unique_results_count": 14,
  "results": [
    {
      "title": "KI-Anwendungen im Maschinenbau: Studie 2025",
      "url": "https://vdma.org/ki-studie-2025",
      "snippet": "67% der befragten Maschinenbauer setzen bereits KI-Anwendungen ein...",
      "source_profiles": ["general", "industry"]
    }
    // ... 13 more results
  ],
  "profile_statistics": {
    "general": {"results_count": 7, "success_level": 5},
    "localized": {"results_count": 5, "success_level": 5},
    "industry": {"results_count": 3, "success_level": 3},
    "academic": {"results_count": 2, "success_level": 3}
  },
  "execution_metadata": {
    "total_raw_results": 17,
    "deduplication_rate": 17.6,
    "profiles_with_results": 4,
    "profiles_empty": 0
  }
}
```

---

## Anti-Pattern Examples (DO NOT CREATE)

**❌ Combining allowed_domains AND blocked_domains:**

```yaml
# WRONG - mutually exclusive parameters
WebSearch:
  query: "KI Maschinenbau"
  allowed_domains: ["reuters.com"]
  blocked_domains: ["pinterest.com"]
```

**❌ Including HTTP scheme in domains:**

```yaml
# WRONG - no scheme allowed
allowed_domains: ["https://reuters.com"]

# CORRECT
allowed_domains: ["reuters.com"]
```

**❌ Using bash loops for iteration:**

```bash
# WRONG - LLM handles iteration
for config in ${search_configs[@]}; do
  websearch "$config"
done
```

**❌ Skipping reasoning blocks:**

```markdown
# WRONG - no reasoning before search
WebSearch:
  query: "..."

# CORRECT - reasoning first
<reasoning>
**Analyzing:** Search config 1 of 4
...
</reasoning>

WebSearch:
  query: "..."
```

**❌ Not tracking source_profiles:**

```json
// WRONG - missing provenance
{"title": "...", "url": "...", "snippet": "..."}

// CORRECT - includes source tracking
{"title": "...", "url": "...", "snippet": "...", "source_profiles": ["general", "industry"]}
```

---

## See Also

- [phase-2-batch-creation.md](phase-2-batch-creation.md) - Previous phase (creates batch entity)
- [phase-4-finding-extraction.md](phase-4-finding-extraction.md) - Next phase (extracts findings from results)
- [../patterns/anti-hallucination.md](../patterns/anti-hallucination.md) - Fabrication prevention patterns
- [../SKILL.md](../SKILL.md) - Return to main skill documentation
