# Phase 3: Load Dimension Syntheses [BLOCKING]

**Objective:** Load pre-synthesized dimension documents using Read tool for cross-dimensional synthesis.

**CRITICAL:** Dimension synthesis documents are REQUIRED. Hub consumes spokes, not raw entities.

---

## Hub-and-Spoke Architecture

This phase implements the hub-and-spoke progressive disclosure pattern:

```text
┌─────────────────────────────────────────────────────┐
│  HUB (this skill: synthesis-hub)                │
│  Loads: dimension syntheses + initial question ONLY │
│  Creates: Cross-dimensional synthesis               │
│  Output: research-hub.md (1,500-2,500 words)     │
└─────────────────────────────────────────────────────┘
                         ↑
                    consumes
                         ↑
┌─────────────────────────────────────────────────────┐
│  SPOKES (synthesis-dimension)               │
│  Already synthesized: trends + claims + concepts  │
│  Output: 12-synthesis/synthesis-{dim}.md            │
│          (800-1,200 words per dimension)            │
└─────────────────────────────────────────────────────┘
```

**Benefits:**

- 70-80% reduction in context window usage vs. loading all raw entities
- No redundant synthesis work - spokes have already synthesized
- Hub focuses on cross-dimensional patterns (what spokes can't provide)
- True progressive disclosure for readers

---

## ⛔ SPOKE REQUIREMENT (CRITICAL)

**Dimension synthesis documents MUST exist before running synthesis-hub.**

If `12-synthesis/synthesis-*.md` files don't exist, this phase fails with clear error directing user to run synthesis-dimension first.

**Error when spokes missing:**

```text
ERROR: No dimension synthesis documents found in 12-synthesis/
Required: At least one synthesis-*.md file from synthesis-dimension

To fix: Run synthesis-dimension for each dimension before synthesis-hub.
Example: synthesis-dimension --project-path {path} --dimension {dim-slug}
```

---

## ⛔ DIRECTORY READ PROHIBITION (CRITICAL)

**NEVER invoke the Read tool with `PROJECT_PATH` or any directory path.**

| Prohibited | Allowed |
|------------|---------|
| `Read: ${PROJECT_PATH}` | `Read: ${PROJECT_PATH}/12-synthesis/synthesis-dim.md` |
| `Read: ${PROJECT_PATH}/12-synthesis` | `Read: ${PROJECT_PATH}/00-initial-question/data/question.md` |

**The Read tool ONLY accepts file paths, not directories.**

Use `ls` via Bash or Glob tool to discover files first.

---

## Phase Entry Verification (MANDATORY)

Before beginning Step 1, verify Phase 2 completion:

**Required from Phase 2:**

- `research_type` variable set (e.g., "generic", "tips", "lean-canvas")
- Template selected based on research_type

**Verification:**

```bash
# Verify research_type detected in Phase 2
if [ -z "${research_type}" ]; then
  echo "ERROR: research_type not set. Phase 2 incomplete."
  exit 1
fi

# Log phase entry
echo "=== PHASE 3: LOAD DIMENSION SYNTHESES ==="
echo "Research Type: ${research_type}"
echo "Project Path: ${PROJECT_PATH}"
```

**If verification fails:** Return to Phase 2 to complete research_type detection.

**If verification passes:** Proceed to Step 0.5.

---

## Step 0.5: Initialize Phase 3 TodoWrite

**Action:** Create step-level todos for streamlined loading workflow.

```markdown
USE: TodoWrite tool

ADD (step-level todos):
- Phase 3, Step 1: Load initial question [in_progress]
- Phase 3, Step 2: Verify dimension syntheses exist (BLOCKING) [pending]
- Phase 3, Step 3: Load dimension syntheses [pending]
- Phase 3, Step 4: Extract dimension metadata [pending]
- Phase 3, Step 0.9: Load all megatrend entities [pending]
- Phase 3, Step 5: Verification checkpoint [pending]
- Phase 3, Step 6: Mark Phase 3 complete [pending]
```

**Purpose:** Track progress through streamlined loading process.

**Mark Step 0.5 complete** after TodoWrite initialization.

---

## Step 1: Load Initial Question

**Objective:** Load the primary research question for context.

**Implementation:**

```bash
# List files in initial question directory
ls "${PROJECT_PATH}/00-initial-question/data/"

# Expected: One markdown file with the research question
```

**Load with Read tool:**

```markdown
USE: Read tool
file_path: ${PROJECT_PATH}/00-initial-question/data/[question-file].md
```

**Data Extraction Focus:**

- **Primary research question:** The core question driving the research
- **research_type confirmation:** Verify matches Phase 2 detection
- **Context:** Background and motivation

**Validation:**

- If no file found: ERROR - initial question is mandatory
- If research_type doesn't match Phase 2: WARNING - investigate mismatch
- If file loaded successfully: SUCCESS

**TodoWrite:** Mark Step 1 as completed, Step 2 as in_progress.

---

## Step 2: Verify Dimension Syntheses Exist [BLOCKING]

**Objective:** Confirm dimension synthesis documents exist before proceeding.

**CRITICAL:** This is a BLOCKING check. If no syntheses exist, STOP and instruct user to run synthesis-dimension.

**Implementation:**

```bash
# Check for dimension synthesis files
synthesis_count=$(ls "${PROJECT_PATH}/12-synthesis/synthesis-"*.md 2>/dev/null | wc -l)

echo "Found ${synthesis_count} dimension synthesis files"

if [ "${synthesis_count}" -eq 0 ]; then
  echo ""
  echo "ERROR: No dimension synthesis documents found in 12-synthesis/"
  echo "Required: At least one synthesis-*.md file from synthesis-dimension"
  echo ""
  echo "To fix: Run synthesis-dimension for each dimension before synthesis-hub."
  echo "Example: synthesis-dimension --project-path ${PROJECT_PATH} --dimension {dim-slug}"
  echo ""
  echo "Available dimensions:"
  ls "${PROJECT_PATH}/01-research-dimensions/data/"
  exit 1
fi
```

**Expected Files:**

```text
12-synthesis/
├── synthesis-dimension-1-slug.md
├── synthesis-dimension-2-slug.md
├── synthesis-dimension-3-slug.md
└── ...
```

**Validation:**

- If 0 synthesis files: **ABORT** - spokes required
- If 1+ synthesis files: PROCEED

**TodoWrite:** Mark Step 2 as completed, Step 3 as in_progress.

---

## Step 3: Load Dimension Syntheses

**Objective:** Load ALL dimension synthesis documents into LLM context.

**Implementation:**

```bash
# List all synthesis files
ls "${PROJECT_PATH}/12-synthesis/synthesis-"*.md
```

**Load with Read tool:**

```markdown
USE: Read tool (batch all synthesis files)
file_path: ${PROJECT_PATH}/12-synthesis/synthesis-dimension-1.md
file_path: ${PROJECT_PATH}/12-synthesis/synthesis-dimension-2.md
file_path: ${PROJECT_PATH}/12-synthesis/synthesis-dimension-3.md
[Continue for all synthesis files found...]
```

**Data Extraction Focus:**

For each synthesis document, extract from frontmatter:

- **dimension:** Dimension slug
- **title:** Display name for dimension
- **trend_count:** Number of trends synthesized
- **avg_confidence:** Average confidence score
- **citation_count:** Number of citations
- **cross_connections:** Identified relationships between trends

Extract from content:

- **Executive Summary:** First 200-300 words (use for hub dimension brief)
- **Key Trends section:** Pre-synthesized trend narratives
- **Implications & Recommendations:** Dimension-specific recommendations
- **Evidence Assessment:** Per-dimension metrics

**Typical Count:** 3-7 synthesis files (one per dimension)

**TodoWrite:** Mark Step 3 as completed, Step 4 as in_progress.

---

## Step 4: Extract Dimension Metadata

**Objective:** Build dimension registry from loaded synthesis frontmatter.

**Create DIMENSION_REGISTRY:**

For each loaded synthesis, record:

```markdown
DIMENSION_REGISTRY:
- dimension_slug: "governance-transformationssteuerung"
  display_name: "Governance & Transformationssteuerung"
  trend_count: 5
  avg_confidence: 0.81
  citation_count: 24
  synthesis_file: "12-synthesis/synthesis-governance-transformationssteuerung.md"
  executive_summary: "[First 100-150 words from Executive Summary section]"

- dimension_slug: "wirtschaftlichkeit-business-case"
  display_name: "Wirtschaftlichkeit & Business Case"
  trend_count: 4
  avg_confidence: 0.78
  citation_count: 18
  synthesis_file: "12-synthesis/synthesis-wirtschaftlichkeit-business-case.md"
  executive_summary: "[First 100-150 words from Executive Summary section]"
```

**Purpose:**

- Navigation table in hub report
- Dimension briefs extracted from executive summaries
- Aggregate metrics for confidence assessment

**TodoWrite:** Mark Step 4 as completed, Step 0.9 as in_progress.

---

## Step 0.9: Load All Megatrend Entities [ENHANCED]

**Objective:** Load FULL megatrend content (not just YAML metadata) to enable substantive cross-dimensional megatrend narrative synthesis.

**CRITICAL:** This step loads megatrend CONTENT sections, not just frontmatter. Hub generates 300-500 word megatrend narrative synthesizing ALL megatrends, so it needs access to:
- "Trend" section - Observable pattern description
- "Implication" section - Strategic significance
- "Possibility" section - Opportunity framing
- "Solution" section - Recommended actions
- "Evidence Base" section - Supporting claims and confidence assessment

**Implementation:**

```bash
# List all megatrend files
ls "${PROJECT_PATH}/06-megatrends/data/megatrend-"*.md
```

**Load with Read tool (batch all megatrend files):**

```markdown
USE: Read tool
file_path: ${PROJECT_PATH}/06-megatrends/data/megatrend-1.md
file_path: ${PROJECT_PATH}/06-megatrends/data/megatrend-2.md
file_path: ${PROJECT_PATH}/06-megatrends/data/megatrend-3.md
[Continue for all megatrend files found...]
```

**Data Extraction Focus:**

For each megatrend, extract from YAML frontmatter:

- **dc:identifier:** Unique megatrend ID
- **dc:title:** Megatrend display name
- **megatrend_structure:** Content structure type ("tips" or "generic")
- **planning_horizon:** Urgency classification (act/plan/observe)
- **dimension_affinity:** Primary dimension this megatrend relates to
- **confidence_score:** Composite confidence (0.0-1.0)
- **evidence_strength:** Strength classification (strong/moderate/weak/hypothesis)

Extract from CONTENT sections:

- **Trend section:** 150-200 words - What is happening
- **Implication section:** 150-200 words - Strategic significance
- **Possibility section:** 100-150 words - Opportunity/risk framing
- **Solution section:** 100-150 words - Recommended actions
- **Evidence Base section:** Supporting claims, confidence scores

**Create MEGATREND_REGISTRY:**

For each loaded megatrend, record:

```markdown
MEGATREND_REGISTRY:
- megatrend_id: "megatrend-digitalization-a1b2c3d4"
  title: "Industrielle Digitalisierung"
  planning_horizon: "act"
  dimension_affinity: "technologie-innovation"
  confidence_score: 0.85
  evidence_strength: "strong"
  trend_summary: "[First 50 words from Trend section]"
  implication_summary: "[First 50 words from Implication section]"
  possibility_summary: "[First 30 words from Possibility section]"
  solution_summary: "[First 30 words from Solution section]"
  full_content: "[Complete content for synthesis reference]"

- megatrend_id: "megatrend-cybersecurity-e5f6g7h8"
  title: "Cybersecurity Transformation"
  ...
```

**Purpose:**

- Enable evidence-grounded megatrend narrative synthesis (not just title listing)
- Provide access to strategic narratives, implications, and recommendations
- Support cross-megatrend pattern identification
- Ensure hub synthesis respects evidence base

**Typical Count:** 20-40 megatrends (depending on research scope)

**Token Impact:** +3,000-6,000 tokens (30 megatrends × 100-200 words each)

**Quality Impact:** HIGH - Transforms megatrend narrative from title list to substantive synthesis

**TodoWrite:** Mark Step 0.9 as completed, Step 0.95 as in_progress.

---

## Step 0.95: Arc-Aware Entity Loading [CONDITIONAL]

**Objective:** Load additional research entities based on arc context tier for evidence-grounded arc synthesis.

**Gate Clause:**

```bash
arc_id=$(jq -r '.arc_id // ""' "${PROJECT_PATH}/.metadata/sprint-log.json")

if [ -z "${arc_id}" ]; then
  echo "No arc specified - skipping arc-aware loading"
  # Standard hub mode (current behavior)
  # Skip to Step 5
  continue
fi

echo "Arc detected: ${arc_id}"
echo "Loading arc-tier entities..."
```

**Arc Tier Detection:**

```bash
case "${arc_id}" in
  "competitive-intelligence")
    arc_tier=1
    ;;
  "corporate-visions")
    arc_tier=2
    ;;
  "strategic-foresight"|"industry-transformation")
    arc_tier=3
    ;;
  "technology-futures")
    arc_tier=4
    ;;
  *)
    arc_tier=0  # Fallback: no additional loading
    ;;
esac

echo "Arc Tier: ${arc_tier}"
```

### Tier 1-4: Load Findings (MANDATORY for all arcs)

```bash
# List finding files
finding_files=$(ls "${PROJECT_PATH}/04-findings/data/finding-"*.md 2>/dev/null || echo "")

if [ -z "${finding_files}" ]; then
  echo "WARNING: No findings found in 04-findings/data/"
else
  finding_count=$(echo "${finding_files}" | wc -l | tr -d ' ')
  echo "Found ${finding_count} finding files"
fi
```

**Load with Read tool (batch all finding files):**

```markdown
USE: Read tool
Load ALL finding files in parallel
```

**Parse YAML frontmatter from each finding:**

- `finding_uuid` (from dc:identifier)
- `title` (from dc:title)
- `quality_status` (PASS/FAIL)
- `quality_score` (0.0-1.0)
- `confidence_level` (low/medium/high)
- `finding_type` (fact/trend/insight/question)
- `file_path` (for wikilink generation)

**Filter: quality_status == "PASS"**

```bash
# Keep only findings with PASS status
```

**Sort by quality_score DESC, take top 20:**

```bash
# Build FINDINGS_REGISTRY with top 20 PASS findings
```

**Build FINDINGS_REGISTRY:**

```markdown
FINDINGS_REGISTRY:
- finding_uuid: "finding-{slug}-{hash}"
  title: "{finding title}"
  quality_score: 0.85
  confidence_level: "high"
  finding_type: "fact"
  body_preview: "{first 50 words}"
  file_path: "04-findings/data/finding-{slug}-{hash}.md"

[... continue for top 20 findings ...]
```

**Token Impact:** ~2-3K tokens (20 findings × 100-150 words each)

### Tier 1-4: Load Sources (MANDATORY for all arcs)

```bash
# List source files
source_files=$(ls "${PROJECT_PATH}/07-sources/data/source-"*.md 2>/dev/null || echo "")

if [ -z "${source_files}" ]; then
  echo "WARNING: No sources found in 07-sources/data/"
else
  source_count=$(echo "${source_files}" | wc -l | tr -d ' ')
  echo "Found ${source_count} source files"
fi
```

**Load with Read tool (batch all source files):**

```markdown
USE: Read tool
Load ALL source files in parallel
```

**Parse YAML frontmatter from each source:**

- `source_uuid` (from dc:identifier)
- `publisher.name`
- `publisher.reliability` (0.0-1.0)
- `publisher.domain`
- `url`
- `source_type` (article/report/whitepaper/blog)
- `publication_date`
- `file_path` (for wikilink generation)

**Sort by publisher.reliability DESC, take top 15:**

```bash
# Build SOURCES_REGISTRY with top 15 reliable sources
```

**Build SOURCES_REGISTRY:**

```markdown
SOURCES_REGISTRY:
- source_uuid: "source-{slug}-{hash}"
  publisher:
    name: "McKinsey & Company"
    reliability: 0.92
    domain: "mckinsey.com"
  url: "https://..."
  source_type: "report"
  publication_date: "2025-06-15"
  file_path: "07-sources/data/source-{slug}-{hash}.md"

[... continue for top 15 sources ...]
```

**Token Impact:** ~1.5-2.5K tokens (15 sources × 100-150 words each)

### Tier 2-4: Load Trends (Conditional by planning_horizon)

**Only if arc_tier >= 2:**

```bash
if [[ "${arc_tier}" -ge 2 ]]; then
  echo "Loading trends for Tier ${arc_tier}..."

  # Determine horizon filter
  if [[ "${arc_tier}" == "2" ]]; then
    # Corporate Visions: Act horizon only
    horizon_filter="act"
  elif [[ "${arc_tier}" == "3" ]]; then
    # Strategic Foresight / Industry Transformation: All horizons
    horizon_filter="all"
  elif [[ "${arc_tier}" == "4" ]]; then
    # Technology Futures: Watch + Act
    horizon_filter="watch,act"
  fi

  echo "Trend horizon filter: ${horizon_filter}"

  # List trend files
  trend_files=$(ls "${PROJECT_PATH}/11-trends/data/trend-"*.md 2>/dev/null || echo "")

  if [ -z "${trend_files}" ]; then
    echo "WARNING: No trends found in 11-trends/data/"
  else
    trend_count=$(echo "${trend_files}" | wc -l | tr -d ' ')
    echo "Found ${trend_count} trend files"
  fi
fi
```

**Load with Read tool (batch trend files):**

```markdown
USE: Read tool
Load ALL trend files in parallel
```

**Parse YAML frontmatter from each trend:**

- `trend_uuid` (from dc:identifier)
- `title` (from dc:title)
- `planning_horizon` (act/plan/observe)
- `dimension` (dimension slug)
- `confidence` (0.0-1.0)
- `quality_scores` (object with sub-scores)
- `megatrend_refs` (array of megatrend UUIDs)
- `file_path` (for wikilink generation)

**Filter by planning_horizon:**

```bash
# Filter trends based on horizon_filter
# "act" → keep only planning_horizon == "act"
# "watch,act" → keep planning_horizon IN ("watch", "act")
# "all" → keep all trends
```

**Build TRENDS_REGISTRY:**

```markdown
TRENDS_REGISTRY:
- trend_uuid: "trend-{slug}-{hash}"
  title: "{trend title}"
  planning_horizon: "act"
  dimension: "technology"
  confidence: 0.78
  quality_scores: {...}
  megatrend_refs: ["megatrend-{uuid}", ...]
  file_path: "11-trends/data/trend-{slug}-{hash}.md"

[... continue for all filtered trends ...]
```

**Token Impact:**
- Tier 2 (Act only): ~2.6K tokens (~10 trends)
- Tier 3 (All horizons): ~8.2K tokens (~30 trends)
- Tier 4 (Watch+Act): ~5.4K tokens (~20 trends)

### Tier 4: Load Concepts (Technology Futures only)

**Only if arc_tier == 4:**

```bash
if [[ "${arc_tier}" == "4" ]]; then
  echo "Loading concepts for Technology Futures arc..."

  # List concept files
  concept_files=$(ls "${PROJECT_PATH}/05-domain-concepts/data/concept-"*.md 2>/dev/null || echo "")

  if [ -z "${concept_files}" ]; then
    echo "WARNING: No concepts found in 05-domain-concepts/data/"
  else
    concept_count=$(echo "${concept_files}" | wc -l | tr -d ' ')
    echo "Found ${concept_count} concept files"
  fi
fi
```

**Load with Read tool (batch all concept files):**

```markdown
USE: Read tool
Load ALL concept files in parallel
```

**Parse YAML frontmatter from each concept:**

- `concept_uuid` (from dc:identifier)
- `title` (from dc:title)
- `maturity_level` (emerging/growth/mature/deprecated)
- `category` (concept category)
- `related_trends` (array of trend UUIDs)
- `file_path` (for wikilink generation)

**Build CONCEPTS_REGISTRY:**

```markdown
CONCEPTS_REGISTRY:
- concept_uuid: "concept-{slug}-{hash}"
  title: "{concept title}"
  maturity_level: "emerging"
  category: "{category}"
  related_trends: ["trend-{uuid}", ...]
  file_path: "05-domain-concepts/data/concept-{slug}-{hash}.md"

[... continue for all concepts ...]
```

**Token Impact:** ~4K tokens (~20 concepts × 200 words each)

### Update Verification Questions

Add arc-aware verification to Step 5:

**Question 6: Arc Entity Verification (if arc_id set)**

**Q: "What findings support the key claims in this research?"**

Expected: List 3-5 findings with quality_scores >= 0.65

**If unable to answer AND arc_id set:** STOP. Return to Step 0.95.

**Q: "What is the source reliability for the top publishers?"**

Expected: List 3-5 sources with reliability >= 0.70

**If unable to answer AND arc_id set:** STOP. Return to Step 0.95.

**TodoWrite:** Mark Step 0.95 as completed, Step 5 as in_progress.

---

## Step 5: Verification Checkpoint [BLOCKING]

**Objective:** Verify synthesis documents loaded before proceeding to Phase 4.

**Self-test questions (MUST answer before proceeding):**

Answer each question WITHOUT re-reading files. If you cannot answer, loading failed.

### Question 1: Research Question Verification

**Q: "What is the primary research question?"**

Expected answer format:

- Verbatim research question text
- Research context

**If unable to answer:** STOP. Return to Step 1.

---

### Question 2: Dimension Count Verification

**Q: "How many dimensions are being synthesized?"**

Expected answer format:

- Exact count of synthesis files loaded
- List of dimension display names

**If unable to answer:** STOP. Return to Step 3.

---

### Question 3: Dimension Content Verification

**Q: "What is the executive summary for Dimension 1?"**

Expected answer format:

- First 100-150 words from that dimension's synthesis
- Key finding highlighted

**If unable to answer:** STOP. Return to Step 3.

---

### Question 4: Metrics Verification

**Q: "What is the average confidence across all dimensions?"**

Expected answer format:

- Aggregate avg_confidence from all loaded syntheses
- Total trend count across dimensions

**If unable to answer:** STOP. Return to Step 4.

---

### Question 5: Megatrend Content Verification

**Q: "What is the strategic implication described in one of the megatrends?"**

Expected answer format:

- Quote from the Implication section of a loaded megatrend
- Megatrend title and planning horizon

**If unable to answer:** STOP. Return to Step 0.9.

---

### Verification Decision Logic

```bash
verification_passed=true

# Check if all questions answered successfully
if [ unable_to_answer_any_question == true ]; then
  echo "FAIL: Verification checkpoint failed"
  echo "Re-load syntheses for failed questions"
  verification_passed=false
fi

if [ "${verification_passed}" = "true" ]; then
  echo "=== VERIFICATION PASSED ==="
  echo "Dimension syntheses loaded successfully. Ready for Phase 4."
else
  echo "=== VERIFICATION FAILED ==="
  echo "Re-load missing syntheses before proceeding."
  exit 1
fi
```

**TodoWrite:** Mark Step 5 as completed, Step 6 as in_progress.

---

## Step 6: Mark Phase 3 Complete

**Action:** Update phase-level todos and document loading completion.

**TodoWrite Update:**

```markdown
USE: TodoWrite tool

UPDATE phase-level todos:
- Phase 1: Project setup [completed]
- Phase 2: Research type detection [completed]
- Phase 3: Load dimension syntheses [completed]
- Phase 4: Cross-dimensional synthesis [in_progress]
- Phase 5: Validation & output [pending]
```

**Document Loading Summary:**

```bash
echo "=== PHASE 3 COMPLETION SUMMARY ==="
echo "Initial Question: Loaded"
echo "Dimension Syntheses: [count] loaded"
echo "Megatrend Entities: [count] loaded (FULL CONTENT)"
echo "Total Trends (aggregate): [sum of trend_count]"
echo "Total Citations (aggregate): [sum of citation_count]"
echo "Average Confidence: [weighted avg]"
echo ""
echo "Verification Checkpoint: PASSED"
echo "Ready for Phase 4: Cross-Dimensional Synthesis"
```

**TodoWrite:** Mark Step 6 as completed before proceeding to Phase 4.

---

## Phase Completion Checklist

**Mandatory Completion Criteria:**

- [ ] **Phase entry verification passed**
  - research_type confirmed from Phase 2
  - PROJECT_PATH validated

- [ ] **Initial question loaded**
  - Primary research question in LLM context
  - research_type confirmation matches Phase 2

- [ ] **Dimension syntheses verified**
  - At least 1 synthesis file exists in 12-synthesis/
  - All synthesis files loaded via Read tool

- [ ] **Dimension metadata extracted**
  - DIMENSION_REGISTRY built with all dimensions
  - Executive summaries extracted for hub briefs

- [ ] **Megatrend entities loaded**
  - All megatrend content sections loaded (not just YAML)
  - MEGATREND_REGISTRY built with full content access
  - Can reference megatrend implications and solutions

- [ ] **Verification checkpoint PASSED**
  - All 5 self-test questions answered successfully
  - Can reference syntheses and megatrends without re-reading

- [ ] **All step-level todos completed**
  - Step 1: Load initial question [completed]
  - Step 2: Verify dimension syntheses exist [completed]
  - Step 3: Load dimension syntheses [completed]
  - Step 4: Extract dimension metadata [completed]
  - Step 0.9: Load all megatrend entities [completed]
  - Step 5: Verification checkpoint [completed]
  - Step 6: Mark Phase 3 complete [completed]

**Phase 3 Output:**

- Initial question in LLM context
- All dimension syntheses in LLM context
- All megatrend entities in LLM context (FULL CONTENT)
- DIMENSION_REGISTRY with metadata for each dimension
- MEGATREND_REGISTRY with full content for synthesis
- Ready for Phase 4 cross-dimensional synthesis

**Next Phase:** Phase 4 - Cross-Dimensional Synthesis (hub report generation)

---

## What We DON'T Load (by design)

The following entities are NOT loaded in this phase because spokes have already synthesized them:

| Entity Type | Location | Loaded By | Hub Loads? |
|-------------|----------|-----------|------------|
| Refined Questions | 02-refined-questions/ | synthesis-dimension | ❌ NO |
| Domain Concepts | 05-domain-concepts/ | synthesis-dimension | ❌ NO |
| **Megatrends** | **06-megatrends/** | **synthesis-dimension** | **✅ YES** |
| Raw Trends | 11-trends/data/ | synthesis-dimension | ❌ NO |
| Claims | 10-claims/ | synthesis-dimension | ❌ NO |
| Findings | 04-findings/ | synthesis-dimension | ❌ NO |

**Why megatrends are loaded:**

Megatrends are cross-dimensional entities that NO single spoke synthesizes completely. Each spoke sees only the megatrends relevant to its dimension. The hub generates a 300-500 word cross-dimensional megatrend narrative, so it MUST load megatrend content (Trend, Implication, Possibility, Solution sections) to synthesize meaningfully.

**Why trends are NOT loaded:**

Trends are dimension-scoped. Each spoke already synthesized its dimension's trends. The hub extracts trend insights from spoke Executive Summaries and doesn't re-synthesize individual trends (that would violate the hub-spoke boundary).

**Why this loading strategy matters:**

- Still reduces context window usage by 65-75% (vs. loading all raw entities)
- Eliminates redundant synthesis for dimension-scoped entities
- Hub focuses on cross-dimensional patterns and megatrend synthesis
- Acceptable token cost increase (+3K-6K) for quality gains

---

## Comparison: Old vs. New Loading

| Aspect | Old Phase 3 | New Phase 3 (v2.1) |
|--------|-------------|---------------------|
| **Files loaded** | 50-100+ | ~10-15 (syntheses) + ~30 (megatrends) |
| **Entity types** | 6-7 types | 3 types (syntheses, megatrends, initial question) |
| **Time estimate** | 8-17 minutes | 3-5 minutes |
| **Token usage** | ~15,000 | ~7,000-10,000 |
| **Prerequisite** | None | Spokes completed |
| **Synthesis burden** | Heavy | Light |
| **Megatrend synthesis** | Generic title list | Evidence-grounded narrative |

---

## Estimated Metrics

**Time Investment:**

- Step 1 (Load initial question): 30 seconds
- Step 2 (Verify syntheses exist): 30 seconds
- Step 3 (Load syntheses): 1-2 minutes
- Step 4 (Extract metadata): 30 seconds
- Step 0.9 (Load megatrends): 1-2 minutes
- Step 5 (Verification): 1 minute
- Step 6 (Mark complete): 30 seconds

**Total Phase 3 Duration:** 3-5 minutes (vs. 8-17 minutes previously)

**Token Usage:** ~7,000-10,000 tokens (vs. ~15,000 previously)
- Dimension syntheses: ~4,000 tokens
- Megatrend content: ~3,000-6,000 tokens
- Initial question: ~500 tokens

**Success Rate Impact:**

- With spokes completed: 95%+ synthesis accuracy
- Without spokes: Phase 3 fails with clear error (by design)

---

**End of Phase 3 Workflow**
