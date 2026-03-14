---
reference: phase-4-finding-extraction
version: 11.0.0
checksum: phase-4-finding-extraction-v11.0.0-enhanced-cot
dependencies: [WebFetch, create-entity.sh v3.5.0+, finding-quality-standards.md, anti-hallucination.md]
phase: 4
changelog: |
  v11.0.0: ENHANCED COT v2 - Expanded reasoning templates with OBSERVE→ANALYZE→DECIDE pattern; added pre-scoring analysis; detailed evidence inventories; complete worked example; gate decision reasoning; reasoning audit checklist
  v10.0.0: STREAMLINED - Reduced from 1309 to ~600 lines; consolidated COT templates; unified gate tables; removed redundant pseudocode
  v9.0.0: ENHANCED COT - Added structured reasoning templates for quality assessment, coherence validation, and anti-hallucination gates
  v8.0.0: CONTENT FIDELITY - Add Step 4.5.4 to validate snippet-only mode doesn't exceed snippet scope (Pattern 17)
  v7.0.0: COHERENCE VALIDATION - Add Step 4.5.5 to validate content-URL semantic coherence
  v6.0.0: TWO-PHASE COMMIT - Enhanced Step 4.0 to verify batch is in PRODUCTION (not staging)
---

# Phase 4: Finding Extraction Workflow

**Checksum:** `phase-4-finding-extraction-v11.0.0-enhanced-cot`

Output this checksum after reading to confirm reference loading.

---

## Quick Reference

| Step | Gate | Pass Condition | Fail Action |
|------|------|----------------|-------------|
| 4.0 | Production | Batch in production, ≥500 bytes | Exit 122 |
| 4.2 | Freshness | Age ≤ max_source_age_months | Skip result |
| 4.3 | Quality | Composite ≥ 0.50 | Skip result |
| 4.4 | Content | WebFetch ≥200 OR snippet ≥100 chars | Skip result |
| 4.5.4 | Fidelity | Novel entities ≤5 (snippet-only) | Skip finding |
| 4.5.5 | Coherence | No semantic mismatches | Skip finding |
| 4.7 | Completion | FINDINGS_CREATED > 0 | Exit 132 |

---

## Purpose

Extract findings from SEARCH_RESULTS and create structured finding entities:

1. Verify batch is in PRODUCTION (not staging)
2. Apply freshness gate - reject sources older than PICOT threshold
3. Assess quality - score 5 dimensions, filter below 0.50
4. Enrich content - WebFetch for full content
5. Generate 5-section structure
6. Validate content fidelity (snippet-only mode)
7. Validate content-URL coherence
8. Create entities - schema v4.0 frontmatter

---

## Chain-of-Thought Protocol

**OBSERVE → ANALYZE → DECIDE** pattern required before all gate decisions. This protocol ensures transparent reasoning and prevents silent failures.

### Protocol Overview

| Step | Reasoning Block | Purpose | When Required |
|------|-----------------|---------|---------------|
| 4.2 | `<freshness-reasoning>` | Evaluate source age | Each result |
| 4.3 | `<quality-reasoning>` | Score 5 dimensions | Each result passing 4.2 |
| 4.5.4 | `<hallucination-check type="fidelity">` | Verify snippet scope | Snippet-only results |
| 4.5.5 | `<hallucination-check type="coherence">` | Verify URL alignment | All results |

---

### Pre-Scoring Analysis Block (Step 4.3 Prerequisite)

**Output BEFORE scoring each result:**

```markdown
<pre-scoring-analysis>
**Result:** {N} of {total}
**URL:** {source_url}
**Title:** {title}
**Snippet Preview:** "{first 100 chars}..."

**Content Assessment:**
- Snippet length: {char_count} chars
- WebFetch status: {success/failed/pending}
- Content source will be: {webfetch/snippet}

**Question Alignment Check:**
- Research question: "{query_text}"
- Core concepts in question: [{concept1}, {concept2}, {concept3}]
- Concepts found in snippet: [{found1}, {found2}] → {N}/{M} match

**Source Authority Signals:**
- Domain: {domain}
- Domain type: {.edu/.gov/.org/.com/other}
- Known authority: {yes/no - which tier}
- Publication signals: {journal/news/blog/corporate/unknown}

**Date Extraction Attempt:**
- URL date pattern: {found YYYY/MM/DD or "none"}
- Snippet date mention: {found "Published X" or "none"}
- Extracted date: {YYYY-MM-DD or "unknown"}

**Conclusion:** Ready to score with content_source={webfetch/snippet}, date={date}
</pre-scoring-analysis>
```

---

### Quality Reasoning Block (Step 4.3)

**Output for EACH result being scored:**

```markdown
<quality-reasoning>
**Source:** {url}
**Title:** {title}
**Content Source:** {webfetch/snippet}

**OBSERVE - Raw Evidence:**
- Word count: {N} words
- Snippet/content excerpt: "{key sentence showing relevance}"
- Data points found: [{stat1}, {stat2}] or "none"
- Methodology mentions: "{method phrase}" or "none"
- Domain: {domain} → Tier {1/2/3/4}

**ANALYZE - Dimension Scoring:**

1. **Topical Relevance (35%):**
   - Question concepts: [{concept1}, {concept2}, {concept3}]
   - Content matches: [{match1}, {match2}]
   - Match strength: {direct answer/high relevance/moderate/tangential/off-topic}
   - Entity relevance (if applicable): {score} - {entity named/implied/absent}
   - **Score: {0.XX}** - {1-sentence rationale}

2. **Content Completeness (25%):**
   - Word count score: {N} words → {0.XX}
   - Trend richness: {count} extractable trends → {0.XX}
   - Methodology presence: {detailed/basic/mentioned/absent} → {0.XX}
   - Data points: {count} specific → {0.XX}
   - **Score: {0.XX}** - weighted average

3. **Source Reliability (15%):**
   - Domain: {domain}
   - Publication type: {academic/industry/news/blog}
   - Authority signals: {institution/editorial standards/reputation}
   - Tier assignment: {1/2/3/4}
   - **Score: {1.00/0.75/0.50/0.25}**

4. **Evidentiary Value (10%):**
   - Statistics found: [{stat1}, {stat2}] or "none"
   - Dates/timeframes: [{date1}] or "none"
   - Sample sizes: {N=XXX} or "none"
   - Citeable claims: {count}
   - **Score: {0.XX}** - based on evidence density

5. **Source Freshness (15%):**
   - Source date: {YYYY-MM-DD or "unknown"}
   - Age: {N} months
   - Planning horizon: {act/plan/observe}
   - Volatile topic: {yes/no}
   - **Score: {0.XX}** - per freshness rubric

**DECIDE - Composite Calculation:**
```
composite = (0.35 × {R}) + (0.25 × {C}) + (0.15 × {S}) + (0.10 × {E}) + (0.15 × {F})
          = {0.XX} + {0.XX} + {0.XX} + {0.XX} + {0.XX}
          = **{0.XX}**
```

**Gate Decision:** {0.XX} {≥/<} 0.50 → **{PASS/FAIL}**
**Rationale:** {1-2 sentences explaining why this score is appropriate}
</quality-reasoning>
```

---

### Anti-Hallucination Reasoning Blocks (Steps 4.5.4 & 4.5.5)

#### Fidelity Check Block (Step 4.5.4 - Snippet-Only Mode)

**Output when webfetch_success=false:**

```markdown
<hallucination-check type="fidelity">
**Source URL:** {url}
**Content Mode:** snippet (WebFetch failed)

**OBSERVE - Evidence Inventory:**

**Original Snippet (verbatim):**
> "{full snippet text}"

**Generated Content Excerpt:**
> "{first 200 chars of generated content}..."

**Entity Extraction from Snippet:**
- Statistics: [{"%X of Y", "N companies"}] or "none"
- Organizations: [{org1}, {org2}] or "none"
- Timeframes: [{year1}, {date range}] or "none"
- Sample sizes: [{N=XXX}] or "none"
- Specific claims: [{claim1}] or "none"

**Entity Extraction from Generated:**
- Statistics: [{...}]
- Organizations: [{...}]
- Timeframes: [{...}]
- Sample sizes: [{...}]
- Specific claims: [{...}]

**ANALYZE - Novel Entity Detection:**

| Entity Type | In Snippet | In Generated | Novel? |
|-------------|------------|--------------|--------|
| {type1} | {value or ✗} | {value or ✗} | {yes/no} |
| {type2} | {value or ✗} | {value or ✗} | {yes/no} |
| ... | ... | ... | ... |

**Novel entities list:** [{entity1}, {entity2}] or "none"
**Novel count:** {N}

**DECIDE - Gate Decision:**
- Threshold: 0-2 = PASS, 3-5 = WARN, >5 = FAIL
- Novel count: {N}
- **Status: {PASS/WARN/FAIL}**
- **Rationale:** {explanation of what was found/not found}

**Metadata to add:**
```yaml
fidelity_validated: true
fidelity_status: "{PASS/WARN/FAIL}"
fidelity_novel_count: {N}
content_source: "snippet"
```
</hallucination-check>
```

#### Coherence Check Block (Step 4.5.5 - All Findings)

**Output for EVERY finding before entity creation:**

```markdown
<hallucination-check type="coherence">
**Source URL:** {url}
**Domain:** {extracted domain}
**Content Mode:** {webfetch/snippet}

**OBSERVE - Cross-Reference Analysis:**

**URL Authority Signals:**
- Domain: {domain}
- Path segments: [{segment1}, {segment2}]
- Expected content type: {based on URL structure}

**Content Authority Claims:**
- Named reports/studies: [{report_name}] or "none"
- Named organizations: [{org_name}] or "none"
- Named experts: [{expert_name}] or "none"
- Specific statistics: [{"X% according to Y"}] or "none"

**ANALYZE - Mismatch Detection:**

| Mismatch Type | Check | Result |
|---------------|-------|--------|
| report_name_mismatch | Does "{report_name}" match {domain}? | {PASS/FAIL: reason} |
| publisher_contradiction | Does "{org_name}" match {domain}? | {PASS/FAIL: reason} |
| topic_mismatch | Does "{content topic}" align with "{url path}"? | {PASS/WARN: reason} |
| entity_mismatch | Does "{entity focus}" connect to {domain}? | {PASS/FAIL: reason} |
| unnamed_statistic | Statistics from non-authoritative URL? | {PASS/FAIL: reason} |

**Cross-Reference Examples:**
- ✅ "McKinsey Report 2024" + mckinsey.com → COHERENT
- ❌ "IW-Report 2024" + iapm.de → INCOHERENT (IW ≠ IAPM)
- ⚠️ Generic "67% of companies" + blog.example.com → WARN

**DECIDE - Gate Decision:**
- Mismatches found: [{type1}, {type2}] or "none"
- Mismatch count: {N}
- Critical mismatches (report/publisher/entity): {N}
- **Status: {PASS/WARN/FAIL}**
- **Rationale:** {explanation}

**If FAIL:** Do NOT create finding. Log to `.metadata/coherence-rejected.json`

**Metadata to add:**
```yaml
coherence_validated: true
coherence_status: "{PASS/WARN/FAIL}"
coherence_warning: "{warning text or null}"
coherence_framework_version: "1.0"
```
</hallucination-check>
```

---

### Gate Decision Summary Block

**Output at end of each result processing:**

```markdown
<gate-summary result="{N}">
**URL:** {url}

| Gate | Status | Key Metric |
|------|--------|------------|
| Freshness (4.2) | {PASS/REJECT} | {age} months |
| Quality (4.3) | {PASS/FAIL} | {score} |
| Fidelity (4.5.4) | {PASS/WARN/FAIL/SKIP} | {novel_count or "N/A"} |
| Coherence (4.5.5) | {PASS/WARN/FAIL} | {mismatch_count} mismatches |

**Final Decision:** {CREATE/SKIP}
**Reason:** {1-sentence summary}
</gate-summary>
```

---

⚠️ **CRITICAL ENFORCEMENT:**

1. **NO silent gate decisions** - Every PASS/FAIL must have a preceding reasoning block
2. **NO assumed scores** - Every dimension score must show evidence
3. **NO skipped checks** - Fidelity check required for ALL snippet-only results
4. **Output order:** pre-scoring → quality-reasoning → hallucination-check(s) → gate-summary

---

## Step 0.5: Initialize Phase 4 TodoWrite

```text
- Phase 4, Step 4.0: Verify batch in production [in_progress]
- Phase 4, Step 4.1: Load batch and derive batch_ref [pending]
- Phase 4, Step 4.2: Apply freshness gate [pending]
- Phase 4, Step 4.3: Assess quality scores [pending]
- Phase 4, Step 4.4: Enrich via WebFetch [pending]
- Phase 4, Step 4.5: Generate 5-section content [pending]
- Phase 4, Step 4.5.4: Validate content fidelity [pending]
- Phase 4, Step 4.5.5: Validate coherence [pending]
- Phase 4, Step 4.6: Create finding entities [pending]
- Phase 4, Step 4.7: Verify findings created [pending]
```

---

## Step 4.0: Verify Batch in Production (Fail-Fast Gate)

**⛔ MANDATORY:** Verify batch reference variables AND production location.

### Validation Checks

```bash
# Check 1: Variables from Phase 2
if [ -z "${BATCH_ID:-}" ] || [ -z "${BATCH_FILE:-}" ]; then
  echo '{"ok":false,"e":"batch-vars-missing"}' >&2
  exit 121
fi

# Check 2: NOT in staging (indicates validation failed)
STAGING_FILE="${PROJECT_PATH}/${DIR_QUERY_BATCHES}/.staging/${BATCH_ID}.md"
if [ -f "$STAGING_FILE" ]; then
  echo '{"ok":false,"e":"batch-in-staging"}' >&2
  exit 122
fi

# Check 3: EXISTS in production with content ≥500 bytes
PRODUCTION_FILE="${PROJECT_PATH}/${BATCH_FILE}"
if [ ! -f "$PRODUCTION_FILE" ]; then
  echo '{"ok":false,"e":"batch-not-found"}' >&2
  exit 122
fi

PROD_SIZE=$(stat -f%z "$PRODUCTION_FILE" 2>/dev/null || stat -c%s "$PRODUCTION_FILE" 2>/dev/null || echo 0)
if [ "$PROD_SIZE" -lt 500 ]; then
  echo '{"ok":false,"e":"batch-too-small","size":'$PROD_SIZE'}' >&2
  exit 122
fi
```

**Available Variables from Phase 2:**

| Variable | Usage |
|----------|-------|
| `BATCH_ID` | Batch identifier |
| `BATCH_FILE` | Path to batch entity |
| `BATCH_QUESTION_REF` | Wikilink to refined question |

Mark Step 4.0 completed.

---

## Step 4.1: Load Batch Entity and Derive batch_ref

**⛔ CRITICAL:** Derive `batch_ref` from actual batch file's `dc:identifier`, NOT from memory.

### 4.1.1 Read Batch Entity

```text
Read: ${PROJECT_PATH}/${BATCH_FILE}
```

### 4.1.2 Extract Required Fields

| Field | Usage |
|-------|-------|
| `dc:identifier` | Build batch_ref: `[[03-query-batches/data/{dc:identifier}]]` |
| `question_ref` | Redundant safety link for finding |
| `query_text` | Relevance scoring |
| `temporal_constraints` | Freshness gate |

### 4.1.3 Store Derived Values

- `BATCH_REF` - Wikilink from batch file
- `QUESTION_REF` - Wikilink from `question_ref` field (don't construct manually)
- `TEMPORAL_CONSTRAINTS` - For Step 4.2
- `QUERY_TEXT` - For Step 4.3

**⛔ NEVER construct batch_ref or question_ref manually. Always derive from batch file.**

Mark Step 4.1 completed.

---

## Step 4.1.5: Batch Validation (Automatic Enforcement)

**Double enforcement:**
1. **Step 4.1:** Reading batch file fails if it doesn't exist
2. **create-entity.sh v3.5.0:** Validates batch_ref before creating any finding

Script checks:
- batch_ref file exists
- File has content ≥500 bytes
- File contains valid `question_ref` wikilink

Mark Step 4.1.5 completed.

---

## Step 4.2: Apply Freshness Gate

For each result in SEARCH_RESULTS, extract date and apply freshness threshold.

### Date Extraction Priority

| Source | Pattern | Example |
|--------|---------|---------|
| URL | `/YYYY/MM/DD/` | /2024/06/15/ → 2024-06-15 |
| URL | `/YYYY-MM-DD/` | /2024-06-15/ → 2024-06-15 |
| Snippet | "Published: DD.MM.YYYY" | Published: 15.06.2024 → 2024-06-15 |
| Snippet | "Month YYYY" | December 2024 → 2024-12-01 |

### Gate Decision

| Condition | Action |
|-----------|--------|
| source_age_months > max_source_age_months | **REJECT** - skip result |
| source_age_months ≤ max_source_age_months | **PASS** - continue |
| Date unknown + volatile topic | **WARN** - continue with flag |
| Date unknown + non-volatile | **PASS** - continue |

**Track:** `source_date`, `source_age_months`, `freshness_status`

**Log rejections:** `.metadata/freshness-rejected.json`

Mark Step 4.2 completed.

---

## Step 4.3: Assess Quality (5-Dimension Scoring)

**⚠️ COT REQUIRED:** Output `<quality-reasoning>` block BEFORE scoring.

### Dimension Weights

| Dimension | Weight | Assessment |
|-----------|--------|------------|
| Topical Relevance | 35% | Keyword overlap, conceptual alignment |
| Content Completeness | 25% | Word count, data points, methodology |
| Source Reliability | 15% | Domain tier: .edu=1.0, mckinsey=0.75, news=0.50, blog=0.25 |
| Evidentiary Value | 10% | Statistics, methodology keywords, citations |
| Source Freshness | 15% | Score from Step 4.2 |

### Entity Relevance Sub-Score (v5.3.0)

**Only if `ENTITY_SPECIFIC == true`:**

Split Topical Relevance: Question Alignment (60%) + Entity Relevance (40%)

| Entity Score | Criteria |
|--------------|----------|
| 1.00 | Entity named + specific offerings |
| 0.75 | Entity named + general statements |
| 0.50 | Entity implied via context |
| 0.25 | Industry mentioned, entity absent |
| 0.00 | No entity connection |

**If entity_relevance < 0.50:** Add `entity_knowledge_gap: true` flag and prepend disclaimer.

### Composite Calculation

```text
composite = (topical × 0.35) + (completeness × 0.25) + (reliability × 0.15) + (evidence × 0.10) + (freshness × 0.15)
```

### Gate Decision

| Condition | Action |
|-----------|--------|
| composite ≥ 0.50 | **PASS** - continue |
| composite < 0.50 | **FAIL** - skip, log to `.rejected-findings.json` |

Mark Step 4.3 completed.

---

## Step 4.4: Enrich Content via WebFetch

### URL Validation

**Reject immediately:**

| Pattern | Examples |
|---------|----------|
| Generic placeholders | example.com, beispiel.de |
| Test domains | test.com, localhost |
| Clean paths | /agile-fuehrung (suspiciously formatted) |

### WebFetch Invocation

```text
WebFetch:
- url: "{result.url}"
- prompt: "Extract key findings, methodology, data points. Respond in {language}."
```

### Content Source Tracking

| Result | content_source | webfetch_success |
|--------|----------------|------------------|
| Success (≥200 chars) | "webfetch" | true |
| Failure/empty | "snippet" | false |

### Content Sufficiency Gate

| Condition | Action |
|-----------|--------|
| webfetch=true, content ≥200 chars | Continue |
| webfetch=false, snippet ≥100 chars | Continue (snippet-only mode) |
| webfetch=false, snippet <100 chars | **SKIP** - log to `.metadata/skipped-findings.json` |

Mark Step 4.4 completed.

---

## Step 4.5: Generate 5-Section Finding Content

### Section Requirements

| Section | Requirements |
|---------|--------------|
| **Content** | 150-300 words; substantive summary |
| **Key Trends** | 3-6 bullets; specific and actionable |
| **Methodology** | 2+ sentences or disclaimer |
| **Relevance Assessment** | Composite + dimension scores |
| **Source** | URL + publisher |

### Language-Aware Headers

**MANDATORY:** Use template variables from `references/language-templates.md` section `04-findings` based on content_language from batch entity.

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `{HEADER_CONTENT}` | Content | Inhalt |
| `{HEADER_KEY_TRENDS}` | Key Trends | Kerntrends |
| `{HEADER_METHODOLOGY}` | Methodology & Data Points | Methodik & Datenpunkte |
| `{HEADER_RELEVANCE_ASSESSMENT}` | Relevance Assessment | Relevanz-Bewertung |
| `{HEADER_SOURCE}` | Source | Quelle |

### Snippet-Only Mode Constraints

When `webfetch_success=false`:

| Allowed | Prohibited |
|---------|------------|
| Direct paraphrase | Invented statistics |
| Explicit disclaimer | Fabricated methodology |
| Extracted claims | Made-up study details |

**Methodology MUST include:** "No methodology available - based on search snippet only."

### Section Validation

Before proceeding, verify:
- [ ] Content: 150-300 words
- [ ] Trends: 3-6 bullets
- [ ] Methodology: 2+ sentences or disclaimer
- [ ] All scores present

Mark Step 4.5 completed.

---

## Step 4.5.4: Content Fidelity Gate (Snippet-Only Mode)

**⚠️ COT REQUIRED:** Output `<hallucination-check>` block with type "Fidelity".

**Trigger:** `webfetch_success=false` ONLY. Skip if WebFetch succeeded.

### Entity Extraction Comparison

Extract from both snippet and generated content:
- Percentages with context
- Sample sizes
- Named organizations
- Timeframes
- Numeric claims

**Novel entities** = entities in content NOT in snippet

### Gate Decision

| Novel Count | Status | Action |
|-------------|--------|--------|
| 0-2 | PASS | Continue to 4.5.5 |
| 3-5 | WARN | Add `fidelity_warning: true`, continue |
| >5 | FAIL | Skip, log to `.metadata/fidelity-rejected.json` |

### Metadata Added

```yaml
fidelity_validated: true
fidelity_status: "PASS" | "WARN" | "FAIL"
fidelity_novel_count: 2
content_source: "snippet"
```

Mark Step 4.5.4 completed (or skipped if webfetch=true).

---

## Step 4.5.5: Content-URL Coherence Gate

**⚠️ COT REQUIRED:** Output `<hallucination-check>` block with type "Coherence".

**Purpose:** Detect attribution hallucinations where content is from training data but incorrectly attributed to URL.

### Mismatch Types

| Type | Detection | Example (FAIL) |
|------|-----------|----------------|
| report_name_mismatch | Report name ≠ URL publisher | "IW-Report" + iapm.de |
| publisher_contradiction | Content cites Publisher A, URL is B | "McKinsey" + bcg.com |
| topic_mismatch | Primary topic unrelated to URL path | "AI ethics" + manufacturing.com |
| entity_mismatch | Entity X focus, URL is Y's domain | "BMW" + mercedes-benz.com |

### Gate Decision

| Outcome | Condition |
|---------|-----------|
| PASS | No mismatches |
| WARN | topic_mismatch only |
| FAIL | Any report/publisher/entity mismatch OR 2+ mismatches |

### Example: IW-Report Bug

```yaml
source_url: "https://iapm.de/risikomanagement/"
content: "IW-Report 2024 shows that 67%..."
# FAIL: IW-Report ≠ IAPM domain
```

### Metadata Added

```yaml
coherence_validated: true
coherence_status: "PASS" | "WARN" | "FAIL"
coherence_warning: "string or null"
coherence_framework_version: "1.0"
```

**On FAIL:** Log to `.metadata/coherence-rejected.json`, skip finding.

Mark Step 4.5.5 completed.

---

## Step 4.6: Create Finding Entities

For each finding passing all gates, create entity using create-entity.sh.

### Filename Pattern

```text
finding-{semantic-slug}-{short-uuid}.md
```

### Frontmatter Schema v4.0

| Field | Value |
|-------|-------|
| `tags` | ["finding", megatrend-tag, language-tag] |
| `dc:creator` | "findings-creator" |
| `dc:title` | "{title}" |
| `dc:identifier` | "finding-{uuid}" |
| `dc:created` | ISO8601 timestamp |
| `entity_type` | "finding" |
| `batch_ref` | From Step 4.1 |
| `question_ref` | From Step 4.1 |
| `source_url` | From result |
| `content_source` | "webfetch" or "snippet" |
| `webfetch_success` | boolean |
| `quality_score` | 0.00-1.00 |
| `quality_dimensions` | All 5 scores |
| `coherence_validated` | true |
| `coherence_status` | "PASS" or "WARN" |
| `schema_version` | "3.0" |

### Prohibited Fields

Never include: `dimension_ref`, `language` (use `content_language`), nested `finding:` object

### Entity Creation (Heredoc Pattern)

```bash
cat << 'ENTITY_JSON' | bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-entity.sh" \
  --project-path "$PROJECT_PATH" \
  --entity-type "04-findings" \
  --entity-id "{filename}" \
  --data - \
  --json
{"frontmatter": {...}, "content": "{body}"}
ENTITY_JSON
```

**Why heredoc:** Avoids shell quoting issues with apostrophes in content.

Mark Step 4.6 completed.

---

## Step 4.7: Verify Findings Created

| Condition | Action |
|-----------|--------|
| FINDINGS_CREATED > 0 | Phase 4 complete |
| FINDINGS_CREATED = 0 | **Exit 132** |

### Completion Metrics

Log:
- Results processed
- Freshness rejections
- Quality rejections
- Fidelity rejections
- Coherence rejections
- Findings created
- Success rate (%)

Mark Step 4.7 and Phase 4 todos completed.

---

## Expected Outputs

| Output | Location |
|--------|----------|
| Finding entities | `04-findings/data/finding-*.md` |
| FINDINGS_CREATED | Counter > 0 |
| Freshness rejections | `.metadata/freshness-rejected.json` |
| Quality rejections | `.rejected-findings.json` |
| Fidelity rejections | `.metadata/fidelity-rejected.json` |
| Coherence rejections | `.metadata/coherence-rejected.json` |

---

## Self-Verification Questions

Before marking Phase 4 complete, answer ALL questions:

### Reasoning Block Audit

| Question | YES/NO | If NO, Action |
|----------|--------|---------------|
| Did I output `<pre-scoring-analysis>` for EVERY result? | | Go back and add |
| Did I output `<quality-reasoning>` for EVERY result scored? | | Go back and add |
| Did I show dimension-by-dimension evidence (not just scores)? | | Expand reasoning |
| Did I output `<hallucination-check type="fidelity">` for ALL snippet-only results? | | Check content_source |
| Did I output `<hallucination-check type="coherence">` for ALL results? | | Add before entity creation |
| Did I output `<gate-summary>` for EVERY result? | | Add summary blocks |

### Data Integrity Audit

| Question | YES/NO | If NO, Action |
|----------|--------|---------------|
| Is `batch_ref` derived from actual batch file (not constructed)? | | Re-read Step 4.1 |
| Is `question_ref` from batch entity (not memory)? | | Re-read Step 4.1 |
| Are all quality dimension scores supported by evidence? | | Expand quality-reasoning |
| Is FINDINGS_CREATED > 0? | | Check gates, may need fallback |

### Anti-Hallucination Audit

| Question | YES/NO | If NO, Action |
|----------|--------|---------------|
| Did I extract entities from BOTH snippet AND generated content? | | Redo fidelity check |
| Did I count novel entities correctly? | | Recount |
| Did I check for report_name_mismatch in coherence? | | Add mismatch analysis |
| Did I check for publisher_contradiction in coherence? | | Add mismatch analysis |

**Minimum passing score:** 10/12 YES responses

**If <10 YES:** Do NOT proceed. Fix missing reasoning blocks first.

---

## Complete Worked Example

**Scenario:** Processing result 3 of 8 for question "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?"

### Step 4.2: Freshness Gate

```markdown
<freshness-reasoning>
**Result:** 3 of 8
**URL:** https://vdma.org/ki-studie-maschinenbau-2024
**Title:** "KI-Anwendungen im Maschinenbau: Studie 2024"

**Date Extraction:**
- URL pattern: Contains "2024" in path
- Snippet mention: "Veröffentlicht: März 2024"
- Extracted date: 2024-03-15

**Age Calculation:**
- Current date: 2025-06-15
- Source age: 15 months
- max_source_age_months: 24 (from batch temporal_constraints)

**Gate Decision:**
- 15 months ≤ 24 months → **PASS**
- Freshness score for quality: 0.85 (12-18 month range)
</freshness-reasoning>
```

### Step 4.3: Quality Assessment

```markdown
<pre-scoring-analysis>
**Result:** 3 of 8
**URL:** https://vdma.org/ki-studie-maschinenbau-2024
**Title:** "KI-Anwendungen im Maschinenbau: Studie 2024"
**Snippet Preview:** "67% der befragten Maschinenbauer setzen bereits KI-Anwendungen in der Produktion ein. Die VDMA-Studie zeigt..."

**Content Assessment:**
- Snippet length: 287 chars
- WebFetch status: success
- Content source will be: webfetch

**Question Alignment Check:**
- Research question: "Welche konkreten KI-Anwendungen setzen Maschinenbauer ein?"
- Core concepts in question: [KI-Anwendungen, Maschinenbauer, konkret]
- Concepts found in snippet: [KI-Anwendungen, Maschinenbauer, Produktion] → 2/3 match

**Source Authority Signals:**
- Domain: vdma.org
- Domain type: .org (industry association)
- Known authority: yes - Tier 2 (VDMA = German Mechanical Engineering Association)
- Publication signals: industry study/report

**Date Extraction Attempt:**
- URL date pattern: "2024" in path
- Snippet date mention: "Veröffentlicht: März 2024"
- Extracted date: 2024-03-15

**Conclusion:** Ready to score with content_source=webfetch, date=2024-03-15
</pre-scoring-analysis>
```

```markdown
<quality-reasoning>
**Source:** https://vdma.org/ki-studie-maschinenbau-2024
**Title:** "KI-Anwendungen im Maschinenbau: Studie 2024"
**Content Source:** webfetch

**OBSERVE - Raw Evidence:**
- Word count: 342 words (from WebFetch content)
- Snippet/content excerpt: "67% der befragten Maschinenbauer setzen bereits KI-Anwendungen in der Produktion ein. Besonders verbreitet sind Predictive Maintenance (45%), Qualitätskontrolle (38%), und Prozessoptimierung (31%)."
- Data points found: ["67%", "45%", "38%", "31%", "1,247 Unternehmen"]
- Methodology mentions: "repräsentative Befragung von 1,247 Maschinenbauunternehmen"
- Domain: vdma.org → Tier 2

**ANALYZE - Dimension Scoring:**

1. **Topical Relevance (35%):**
   - Question concepts: [KI-Anwendungen, Maschinenbauer, konkret]
   - Content matches: [KI-Anwendungen, Maschinenbauer, Predictive Maintenance, Qualitätskontrolle, Prozessoptimierung]
   - Match strength: direct answer - lists specific applications with percentages
   - Entity relevance: N/A (not entity-specific question)
   - **Score: 0.92** - Direct answer with specific KI applications and adoption rates

2. **Content Completeness (25%):**
   - Word count score: 342 words → 0.90
   - Trend richness: 5 extractable trends → 0.85
   - Methodology presence: detailed (survey + sample size + scope) → 1.00
   - Data points: 5 specific → 0.85
   - **Score: 0.89** - weighted: (0.90×0.40)+(0.85×0.30)+(1.00×0.20)+(0.85×0.10)

3. **Source Reliability (15%):**
   - Domain: vdma.org
   - Publication type: industry association study
   - Authority signals: VDMA is the leading German machinery association, editorial standards
   - Tier assignment: 2
   - **Score: 0.75**

4. **Evidentiary Value (10%):**
   - Statistics found: ["67% adoption", "45% predictive maintenance", "38% quality control", "31% process optimization"]
   - Dates/timeframes: ["2024 study", "March 2024"]
   - Sample sizes: ["N=1,247"]
   - Citeable claims: 5
   - **Score: 0.90** - rich evidence with specific statistics and methodology

5. **Source Freshness (15%):**
   - Source date: 2024-03-15
   - Age: 15 months
   - Planning horizon: act
   - Volatile topic: yes (AI/KI)
   - **Score: 0.85** - recent for volatile topic, within ideal range

**DECIDE - Composite Calculation:**

composite = (0.35 × 0.92) + (0.25 × 0.89) + (0.15 × 0.75) + (0.10 × 0.90) + (0.15 × 0.85)
          = 0.322 + 0.223 + 0.113 + 0.090 + 0.128
          = **0.88**

**Gate Decision:** 0.88 ≥ 0.50 → **PASS**
**Rationale:** Excellent finding with direct answer to research question, rich statistics from authoritative industry source (VDMA), comprehensive methodology, and recent publication date.
</quality-reasoning>
```

### Step 4.4: WebFetch Success

WebFetch returned 342 words of content. `webfetch_success=true`, `content_source="webfetch"`.

### Step 4.5: Generate Content

*(Content generation happens here - 5-section structure)*

### Step 4.5.4: Fidelity Check - SKIPPED

`webfetch_success=true` → Fidelity check not required (only for snippet-only mode)

### Step 4.5.5: Coherence Check

```markdown
<hallucination-check type="coherence">
**Source URL:** https://vdma.org/ki-studie-maschinenbau-2024
**Domain:** vdma.org
**Content Mode:** webfetch

**OBSERVE - Cross-Reference Analysis:**

**URL Authority Signals:**
- Domain: vdma.org (VDMA = Verband Deutscher Maschinen- und Anlagenbau)
- Path segments: [ki-studie, maschinenbau, 2024]
- Expected content type: Industry study about AI in machinery manufacturing

**Content Authority Claims:**
- Named reports/studies: ["VDMA-Studie 2024"]
- Named organizations: ["VDMA", "Verband Deutscher Maschinen- und Anlagenbau"]
- Named experts: none
- Specific statistics: ["67% der Maschinenbauer", "1,247 Unternehmen befragt"]

**ANALYZE - Mismatch Detection:**

| Mismatch Type | Check | Result |
|---------------|-------|--------|
| report_name_mismatch | Does "VDMA-Studie" match vdma.org? | PASS: VDMA study on VDMA domain |
| publisher_contradiction | Does "VDMA" match vdma.org? | PASS: Perfect alignment |
| topic_mismatch | Does "KI Maschinenbau" align with "ki-studie-maschinenbau"? | PASS: Exact match |
| entity_mismatch | N/A - no third-party entity claims | PASS |
| unnamed_statistic | Statistics have named source (VDMA)? | PASS: "laut VDMA-Studie" |

**Cross-Reference Examples:**
- ✅ "VDMA-Studie 2024" + vdma.org → COHERENT
- ✅ "67% der Maschinenbauer" + VDMA industry survey → COHERENT

**DECIDE - Gate Decision:**
- Mismatches found: none
- Mismatch count: 0
- Critical mismatches: 0
- **Status: PASS**
- **Rationale:** Perfect alignment between URL authority (VDMA) and content claims (VDMA study). All statistics properly attributed to the VDMA survey methodology.

**Metadata to add:**
```yaml
coherence_validated: true
coherence_status: "PASS"
coherence_warning: null
coherence_framework_version: "1.0"
```
</hallucination-check>
```

### Gate Summary

```markdown
<gate-summary result="3">
**URL:** https://vdma.org/ki-studie-maschinenbau-2024

| Gate | Status | Key Metric |
|------|--------|------------|
| Freshness (4.2) | PASS | 15 months |
| Quality (4.3) | PASS | 0.88 |
| Fidelity (4.5.4) | SKIP | N/A (webfetch) |
| Coherence (4.5.5) | PASS | 0 mismatches |

**Final Decision:** CREATE
**Reason:** High-quality VDMA study with direct answer to KI-Anwendungen question, rich statistics, and perfect source coherence.
</gate-summary>
```

### Step 4.6: Entity Creation

Finding entity created with:
- `batch_ref`: `[[03-query-batches/data/question-ki-anwendungen-produktion-v5w6x7y8-batch]]`
- `quality_score`: 0.88
- `coherence_status`: "PASS"

---

## Complete Worked Example: Snippet-Only with Fidelity Warning

**Scenario:** Processing result 6 of 8 (WebFetch failed, snippet-only mode)

### Steps 4.2-4.3: Pass with score 0.58

*(Similar reasoning blocks as above)*

### Step 4.4: WebFetch Failed

```text
WebFetch returned error: "403 Forbidden"
content_source = "snippet"
webfetch_success = false
```

### Step 4.5.4: Fidelity Check (Required)

```markdown
<hallucination-check type="fidelity">
**Source URL:** https://industrie-magazin.de/ki-fertigung-trends
**Content Mode:** snippet (WebFetch failed)

**OBSERVE - Evidence Inventory:**

**Original Snippet (verbatim):**
> "Deutsche Fertigungsunternehmen setzen verstärkt auf KI-Lösungen. Besonders in der Qualitätskontrolle zeigen sich Effizienzsteigerungen."

**Generated Content Excerpt:**
> "Deutsche Fertigungsunternehmen setzen verstärkt auf KI-Lösungen für ihre Produktionsprozesse. Besonders in der Qualitätskontrolle zeigen sich deutliche Effizienzsteigerungen von bis zu 25%. Die Umfrage unter 500 mittelständischen Unternehmen..."

**Entity Extraction from Snippet:**
- Statistics: none
- Organizations: ["Deutsche Fertigungsunternehmen"]
- Timeframes: none
- Sample sizes: none
- Specific claims: ["Effizienzsteigerungen in Qualitätskontrolle"]

**Entity Extraction from Generated:**
- Statistics: ["25%"]
- Organizations: ["Deutsche Fertigungsunternehmen", "mittelständische Unternehmen"]
- Timeframes: none
- Sample sizes: ["500"]
- Specific claims: ["Effizienzsteigerungen von bis zu 25%", "Umfrage unter 500 Unternehmen"]

**ANALYZE - Novel Entity Detection:**

| Entity Type | In Snippet | In Generated | Novel? |
|-------------|------------|--------------|--------|
| Percentage | ✗ | "25%" | YES |
| Sample size | ✗ | "500" | YES |
| Org: mittelständisch | ✗ | "mittelständische Unternehmen" | YES |
| Claim: specific % | ✗ | "bis zu 25%" | YES |

**Novel entities list:** ["25%", "500 Unternehmen", "mittelständische", "bis zu 25%"]
**Novel count:** 4

**DECIDE - Gate Decision:**
- Threshold: 0-2 = PASS, 3-5 = WARN, >5 = FAIL
- Novel count: 4
- **Status: WARN**
- **Rationale:** Generated content introduces 4 entities not in original snippet (specific percentage, sample size). These may be from LLM training data, not from the source URL. Finding can proceed but requires fidelity_warning flag.

**Metadata to add:**
```yaml
fidelity_validated: true
fidelity_status: "WARN"
fidelity_novel_count: 4
fidelity_warning: "4 novel entities detected in snippet-only mode"
content_source: "snippet"
```
</hallucination-check>
```

### Step 4.5.5: Coherence Check

```markdown
<hallucination-check type="coherence">
**Source URL:** https://industrie-magazin.de/ki-fertigung-trends
**Domain:** industrie-magazin.de
**Content Mode:** snippet

**OBSERVE - Cross-Reference Analysis:**

**URL Authority Signals:**
- Domain: industrie-magazin.de (trade publication)
- Path segments: [ki-fertigung, trends]
- Expected content type: Industry news about AI in manufacturing

**Content Authority Claims:**
- Named reports/studies: none
- Named organizations: ["Deutsche Fertigungsunternehmen"]
- Named experts: none
- Specific statistics: ["25%" - but unnamed source]

**ANALYZE - Mismatch Detection:**

| Mismatch Type | Check | Result |
|---------------|-------|--------|
| report_name_mismatch | No named report | PASS |
| publisher_contradiction | No publisher cited | PASS |
| topic_mismatch | "KI Fertigung" vs "ki-fertigung-trends"? | PASS: aligned |
| entity_mismatch | No third-party entity | PASS |
| unnamed_statistic | "25%" from trade magazine URL? | WARN: generic URL with specific stat |

**DECIDE - Gate Decision:**
- Mismatches found: [unnamed_statistic]
- Mismatch count: 1
- Critical mismatches: 0
- **Status: WARN**
- **Rationale:** The 25% statistic lacks named source attribution and comes from a general trade publication URL. Not a critical mismatch (no wrong publisher), but warrants caution.

**Metadata to add:**
```yaml
coherence_validated: true
coherence_status: "WARN"
coherence_warning: "Unnamed statistic from trade publication"
coherence_framework_version: "1.0"
```
</hallucination-check>
```

### Gate Summary

```markdown
<gate-summary result="6">
**URL:** https://industrie-magazin.de/ki-fertigung-trends

| Gate | Status | Key Metric |
|------|--------|------------|
| Freshness (4.2) | PASS | 8 months |
| Quality (4.3) | PASS | 0.58 |
| Fidelity (4.5.4) | WARN | 4 novel entities |
| Coherence (4.5.5) | WARN | 1 mismatch |

**Final Decision:** CREATE (with warnings)
**Reason:** Passes quality threshold (0.58) but has fidelity and coherence warnings due to snippet-only mode elaboration. Creating with warning metadata.
</gate-summary>
```

---

## See Also

- [phase-3-search-execution.md](phase-3-search-execution.md) - Provides SEARCH_RESULTS
- [../patterns/finding-quality-standards.md](../patterns/finding-quality-standards.md) - Quality methodology
- [../patterns/anti-hallucination.md](../patterns/anti-hallucination.md) - Patterns 16-17
- [../SKILL.md](../SKILL.md) - Main skill documentation
