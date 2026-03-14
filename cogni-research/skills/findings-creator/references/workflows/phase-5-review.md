---
reference: phase-5-review
version: 3.0.0
checksum: phase-5-review-v3.0.0-enhanced-cot
dependencies: [WebSearch tool, Glob tool, Read tool, Write tool]
phase: 5
changelog: |
  v3.0.0: ENHANCED COT - Added OBSERVE→ANALYZE→DECIDE reasoning blocks; quick reference table; self-verification questions; complete worked examples; gate summary blocks; reasoning audit checklist
  v2.1.0: Batched WebSearch - parallel execution by category, ~3-5x faster for multiple volatile findings
  v2.0.0: LLM-control architecture - removed all bash loops, LLM handles iteration/evaluation
  v1.0.0: Initial implementation with bash-based iteration and scoring
---

# Phase 5: Review Workflow

**Checksum:** `phase-5-review-v3.0.0-enhanced-cot`

Output this checksum after reading to confirm reference loading.

---

## Quick Reference

| Step | Gate | Pass Condition | Fail Action |
|------|------|----------------|-------------|
| 5.1 | Volatile Detection | ≥1 volatile category matched | Skip review (no volatile findings) |
| 5.2 | Search Execution | WebSearch returns results | Log empty search, continue |
| 5.3 | Contradiction | Severity < critical | Flag for review |
| 5.4 | Alert Generation | Alerts written successfully | Exit 141 |
| 5.5 | Metadata Update | Findings updated | Exit 142 |
| 5.7 | Completion | All volatile findings processed | Phase complete |

---

## Purpose

Validate finding freshness and detect contradictions from recent developments, especially for volatile topics (regulations, politics, markets). This phase prevents outdated findings from contaminating research synthesis.

---

## Performance Notes (v2.1.0)

**Batched WebSearch Execution:** This workflow uses parallel WebSearch calls to minimize I/O latency:

| Before (v2.0.0) | After (v2.1.0) |
|-----------------|----------------|
| Sequential: N findings × ~2s = N×2s | Parallel: N findings in ~2-4s total |
| 10 volatile findings: ~20s | 10 volatile findings: ~3s |

**Key optimization:** Step 5.2.3 executes ALL WebSearch calls in a single message with multiple tool invocations.

---

## When This Phase Applies

This phase is **triggered** when:

1. **Volatile Topic Detection**: Finding tags or content match volatile categories
2. **Temporal Gap**: Finding source date is >6 months old for volatile topics
3. **Explicit Timeframe**: PICOT timeframe specifies recent period (e.g., "2025")

**Volatile Topic Categories:**

| Category | Keywords/Patterns | Volatility Window |
|----------|-------------------|-------------------|
| Regulations | LkSG, CSDDD, CSRD, ESG, compliance, Gesetz, directive, regulation | 3 months |
| Politics | government, policy, coalition, election, minister, parliament | 1 month |
| Markets | market share, competitors, pricing, funding, IPO, acquisition | 6 months |
| Technology | AI, model, release, version, launch, breakthrough | 3 months |
| Geopolitics | sanctions, tariffs, trade war, embargo, conflict | 1 month |

---

## Chain-of-Thought Protocol

**OBSERVE → ANALYZE → DECIDE** pattern required before all gate decisions. This protocol ensures transparent reasoning and prevents silent failures.

### Protocol Overview

| Step | Reasoning Block | Purpose | When Required |
|------|-----------------|---------|---------------|
| 5.1 | `<volatility-reasoning>` | Classify finding volatility | Each finding |
| 5.3 | `<contradiction-reasoning>` | Detect and assess contradictions | Each validation result |
| 5.5 | `<update-reasoning>` | Justify metadata changes | Each finding update |

---

### Volatility Classification Block (Step 5.1)

**Output for EACH finding being classified:**

```markdown
<volatility-reasoning>
**Finding:** {filename}
**Title:** {dc:title}

**OBSERVE - Evidence Inventory:**
- Tags: [{tag1}, {tag2}]
- Content excerpt: "{first 100 chars}..."
- Source date: {YYYY-MM-DD or "unknown"}

**Keywords Detected:**
| Category | Keywords Found | Match Strength |
|----------|---------------|----------------|
| regulations | [{keyword1}] or "none" | {strong/weak/none} |
| politics | [{keyword1}] or "none" | {strong/weak/none} |
| markets | [{keyword1}] or "none" | {strong/weak/none} |
| technology | [{keyword1}] or "none" | {strong/weak/none} |
| geopolitics | [{keyword1}] or "none" | {strong/weak/none} |

**ANALYZE - Category Selection:**
- Strongest category: {category or "none"}
- Keywords supporting: [{keyword1}, {keyword2}]
- Source age: {N} months
- Volatility window: {1/3/6} months
- Age vs window: {within/outside/unknown}

**DECIDE - Classification:**
- **Status: {VOLATILE/NON-VOLATILE}**
- **Category: {category or "N/A"}**
- **Window: {months or "N/A"}**
- **Rationale:** {1-2 sentences explaining classification}
</volatility-reasoning>
```

---

### Contradiction Analysis Block (Step 5.3)

**Output for EACH finding with validation results:**

```markdown
<contradiction-reasoning>
**Finding:** {filename}
**Category:** {volatility category}
**Source Date:** {finding source date}

**OBSERVE - Original Claims:**
| Claim Type | Original Value | Source |
|------------|---------------|--------|
| Status claim | "{claim text}" | Finding content |
| Percentage claim | "{X%}" | Finding content |
| Date claim | "{date}" | Finding content |
| Policy claim | "{policy status}" | Finding content |

**OBSERVE - WebSearch Evidence:**
| Result # | Title | Date | Key Finding |
|----------|-------|------|-------------|
| 1 | "{title}" | {date} | "{relevant excerpt}" |
| 2 | "{title}" | {date} | "{relevant excerpt}" |
| 3 | "{title}" | {date} | "{relevant excerpt}" |

**ANALYZE - Contradiction Detection:**

| Pattern | Check | Evidence | Result |
|---------|-------|----------|--------|
| Policy reversal | abgeschafft, abolished, reversed, cancelled | "{quote or none}" | {YES/NO} |
| Significant amendment | amended, changed, modified, updated | "{quote or none}" | {YES/NO} |
| Recent development | Dates from {current_year} | "{date found or none}" | {YES/NO} |
| Conflicting statistics | Different % for same metric | "{old} vs {new}" | {YES/NO} |
| Context shift | Updated framing | "{description or none}" | {YES/NO} |

**Contradiction List:**
- [{contradiction1}] or "none"
- [{contradiction2}]

**DECIDE - Severity Assignment:**
- Contradictions found: {count}
- Most severe pattern: {pattern or "none"}
- **Severity: {critical/high/medium/low/none}**
- **Rationale:** {1-2 sentences explaining severity choice}

**Metadata to add:**

```yaml
contradiction_detected: {true/false}
contradiction_severity: "{severity or null}"
contradiction_evidence: "{brief description or null}"
contradicting_source_url: "{url or null}"
```

</contradiction-reasoning>
```

---

### Update Justification Block (Step 5.5)

**Output for EACH finding being updated:**

```markdown
<update-reasoning>
**Finding:** {filename}
**Classification:** {VOLATILE/NON-VOLATILE}
**Contradiction:** {detected/none}

**OBSERVE - Current State:**
- review_validated: {true/false/not set}
- review_status: "{current or not set}"
- contradiction_severity: "{current or not set}"

**ANALYZE - Required Updates:**
| Field | Current | New | Reason |
|-------|---------|-----|--------|
| review_validated | {value} | true | Validation complete |
| review_validated_at | {value} | {timestamp} | Record validation time |
| volatility_category | {value} | {category} | From Step 5.1 |
| contradiction_detected | {value} | {true/false} | From Step 5.3 |
| contradiction_severity | {value} | {severity} | From Step 5.3 |
| review_status | {value} | {status} | Derived from severity |

**DECIDE - Update Actions:**
- **Add warning banner:** {YES/NO}
- **Banner severity:** {critical/high or N/A}
- **Review status:** {requires_review/current}
- **Rationale:** {1-sentence justification}
</update-reasoning>
```

---

### Gate Summary Block

**Output at end of each finding's review:**

```markdown
<gate-summary finding="{filename}">
| Gate | Status | Key Metric |
|------|--------|------------|
| Volatility (5.1) | {VOLATILE/SKIP} | {category or "none"} |
| Search (5.2) | {SUCCESS/EMPTY} | {result_count} results |
| Contradiction (5.3) | {FOUND/CLEAR} | {severity or "none"} |
| Update (5.5) | {COMPLETE/SKIP} | {fields_updated} fields |

**Final Status:** {REQUIRES_REVIEW/CURRENT/SKIPPED}
**Action:** {action taken}
</gate-summary>
```

---

⚠️ **CRITICAL ENFORCEMENT:**

1. **NO silent classifications** - Every VOLATILE/NON-VOLATILE must have preceding reasoning block
2. **NO assumed severities** - Every contradiction severity must show evidence
3. **NO skipped findings** - Process ALL findings from Glob (classify as volatile or non-volatile)
4. **Output order:** volatility-reasoning → contradiction-reasoning (if volatile) → update-reasoning → gate-summary

---

## Step 0.5: Initialize Phase 5 TodoWrite

Expand phase-level todo into step-level todos:

```text
USE: TodoWrite tool
ADD (in addition to phase-level todos):
- Phase 5, Step 5.1: Detect volatile topics in findings [in_progress]
- Phase 5, Step 5.2: Execute review validation searches [pending]
- Phase 5, Step 5.3: Analyze for contradictions [pending]
- Phase 5, Step 5.4: Generate contradiction alerts [pending]
- Phase 5, Step 5.5: Update finding metadata [pending]
- Phase 5, Step 5.6: Log validation statistics [pending]
```

---

## Step 5.1: Detect Volatile Topics in Findings

### 5.1.1: List All Findings

Use Glob to discover all finding files:

```text
Glob tool:
- pattern: "finding-*.md"
- path: "${PROJECT_PATH}/04-findings/data/"
```

**Expected output:** Array of finding file paths

### 5.1.2: Read and Classify Each Finding

**⚠️ COT REQUIRED:** Output `<volatility-reasoning>` block for EACH finding.

For each finding file returned by Glob:

1. **Read the finding file** using Read tool
2. **Parse frontmatter** - LLM reads YAML directly (no yq needed)
3. **Extract classification data:**

| Field | Location | Purpose |
|-------|----------|---------|
| `dc:title` | Frontmatter | Validation search query base |
| `tags` | Frontmatter | Category detection |
| `source_date` | Frontmatter | Age calculation |
| Content body | After frontmatter | Keyword scanning |

### 5.1.3: Volatile Topic Detection (LLM Reasoning)

For each finding, apply semantic analysis to detect volatile topics.

**Detection Logic:**

| Category | Detection Patterns | Volatility Window |
|----------|-------------------|-------------------|
| **regulations** | LkSG, CSDDD, CSRD, ESG, compliance, Gesetz, directive, regulation, Lieferkette, supply chain | 3 months |
| **politics** | government, policy, coalition, election, minister, parliament, Regierung, Koalition, Bundesregierung | 1 month |
| **markets** | market share, competitors, pricing, funding, IPO, acquisition, Marktanteil, Wettbewerber | 6 months |
| **technology** | AI, artificial intelligence, model, release, version, launch, breakthrough, GPT, LLM | 3 months |
| **geopolitics** | sanctions, tariffs, trade war, embargo, conflict, Ukraine, China, Russia | 1 month |

**LLM evaluates:**

- Does finding title/content/tags contain any category patterns?
- Which category has strongest match?
- What is the corresponding volatility window?

**Track in memory:**

```text
VOLATILE_FINDINGS:
- finding_id: {filename}
  category: {regulations|politics|markets|technology|geopolitics}
  volatility_window_months: {1|3|6}
  title: {dc:title value}
  source_date: {from frontmatter or "unknown"}

NON_VOLATILE_FINDINGS:
- finding_id: {filename}
  reason: {why not volatile}
```

**Mark Step 5.1 todo as completed** before proceeding.

---

## Step 5.2: Execute Review Validation Searches (Batched)

**Performance Optimization:** Execute WebSearch calls in parallel batches by category to reduce total execution time by 3-5x.

### 5.2.1: Group Findings by Category

From VOLATILE_FINDINGS, group findings by their volatility category:

```text
CATEGORY_GROUPS:
  regulations: [finding1, finding2, ...]
  politics: [finding3, ...]
  markets: [finding4, finding5, ...]
  technology: [finding6, ...]
  geopolitics: [finding7, ...]
```

**Skip empty categories** - only process categories with ≥1 finding.

**If VOLATILE_FINDINGS is empty:** Mark Phase 5 as complete with "no volatile findings" status, proceed to Phase 6.

### 5.2.2: Build Validation Queries per Category

**Query templates by category:**

| Category | Query Template |
|----------|---------------|
| **regulations** | "{title} latest changes 2025 amendment update" |
| **politics** | "{title} latest government decision 2025" |
| **markets** | "{title} market update 2025 latest" |
| **technology** | "{title} latest version update 2025" |
| **geopolitics** | "{title} latest development sanctions policy 2025" |

**Domain lists by category:**

| Category | allowed_domains |
|----------|-----------------|
| regulations | reuters.com, bloomberg.com, lexology.com, jdsupra.com, bundestag.de |
| politics | reuters.com, politico.eu, spiegel.de, zeit.de, tagesschau.de |
| markets | reuters.com, bloomberg.com, ft.com, wsj.com, handelsblatt.com |
| technology | techcrunch.com, theverge.com, arstechnica.com, wired.com |
| geopolitics | reuters.com, bbc.com, aljazeera.com, foreignpolicy.com |

### 5.2.3: Execute Batched WebSearch (PARALLEL)

**⚡ CRITICAL: Execute ALL WebSearch calls in a SINGLE message with multiple tool calls.**

For each non-empty category group, invoke WebSearch tools in parallel:

```text
# Example: 3 volatile findings across 2 categories
# Execute ALL searches in ONE message:

WebSearch tool #1: (regulations - finding1)
- query: "LkSG supply chain law latest changes 2025 amendment update"
- allowed_domains: ["reuters.com", "bloomberg.com", "lexology.com", "jdsupra.com", "bundestag.de"]

WebSearch tool #2: (regulations - finding2)
- query: "CSDDD directive latest changes 2025 amendment update"
- allowed_domains: ["reuters.com", "bloomberg.com", "lexology.com", "jdsupra.com", "bundestag.de"]

WebSearch tool #3: (markets - finding4)
- query: "Stellplatz market competitors market update 2025 latest"
- allowed_domains: ["reuters.com", "bloomberg.com", "ft.com", "wsj.com", "handelsblatt.com"]
```

**Batching Rules:**

| Volatile Findings | Batch Strategy |
|-------------------|----------------|
| 1-5 findings | Single batch (all parallel) |
| 6-10 findings | Single batch (all parallel) |
| 11+ findings | Two batches of ~equal size |

**Why parallel:** WebSearch is I/O-bound (network latency). Parallel execution reduces N×latency to ~1×latency.

### 5.2.4: Track Validation Results

After ALL parallel WebSearch calls complete, store results:

```text
VALIDATION_RESULTS:
- finding_id: {filename}
  category: {category}
  query_used: {actual query}
  search_results: {WebSearch response}
  result_count: {number of results}
```

**Mark Step 5.2 todo as completed** before proceeding.

---

## Step 5.3: Analyze for Contradictions

**⚠️ COT REQUIRED:** Output `<contradiction-reasoning>` block for EACH finding.

For each finding with validation results, analyze for contradictions using LLM reasoning.

### 5.3.1: Load Original Finding Content

For each finding in VALIDATION_RESULTS:

1. Read finding file using Read tool
2. Extract key claims from content:

**Claim patterns to extract:**

| Pattern Type | Example | What to Track |
|-------------|---------|---------------|
| Percentage claims | "80% of companies..." | Number and context |
| Date-based claims | "since January 2024..." | Date and assertion |
| Status claims | "law is in effect..." | Current state assertion |
| Quantitative claims | "€50,000 threshold..." | Specific numbers |

### 5.3.2: Contradiction Analysis (LLM Reasoning)

Compare WebSearch results against original finding claims.

**Contradiction Detection Patterns:**

| Pattern | Indicators | Severity |
|---------|-----------|----------|
| **Policy reversal** | abgeschafft, abolished, reversed, cancelled, suspended, delayed, aufgehoben, gestrichen | **critical** |
| **Significant amendment** | amended, changed, modified, updated, neue Regeln, Änderung, geändert | **high** |
| **Recent development** | dates from current year in results | **medium** |
| **Conflicting statistics** | Different percentages/numbers for same metric | **medium** |
| **Minor context shift** | Updated context without core claim change | **low** |

**LLM evaluates for each validation result:**

1. Do any search results indicate policy reversal? → **critical**
2. Do results mention significant amendments? → **high**
3. Are there developments from the current year? → **medium**
4. Do statistics conflict with finding claims? → **medium**
5. No contradicting information found? → **no contradiction**

### 5.3.3: Track Contradictions

**Store in memory:**

```text
CONTRADICTIONS_FOUND:
- finding_id: {filename}
  category: {volatility category}
  severity: {critical|high|medium|low}
  evidence: {brief description of contradicting information}
  source_url: {URL from WebSearch result}
  source_title: {title from WebSearch result}
```

**Severity Levels:**

| Severity | Meaning | Synthesis Action |
|----------|---------|------------------|
| critical | Policy reversed, law abolished, major factual error | Flag for immediate review, add warning |
| high | Significant amendment, major change | Add freshness warning, suggest update |
| medium | Recent developments, updated statistics | Add "may be outdated" note |
| low | Minor changes, context shifts | Log for awareness |

**Mark Step 5.3 todo as completed** before proceeding.

---

## Step 5.4: Generate Contradiction Alerts

Create structured alerts file for findings with contradictions.

### 5.4.1: Initialize Alerts File

Read existing alerts or create new structure:

```text
Read tool: ${PROJECT_PATH}/.metadata/contradiction-alerts.json
If not exists, create initial structure
```

**Initial structure:**

```json
{
  "alerts": [],
  "generated_at": "",
  "findings_validated": 0,
  "contradictions_found": 0
}
```

### 5.4.2: Build Alert Objects

For each entry in CONTRADICTIONS_FOUND, construct alert:

**Alert Schema:**

| Field | Value Source |
|-------|--------------|
| `alert_id` | Generate: "alert-{8-char-uuid}" |
| `finding_id` | From contradiction entry |
| `finding_title` | From finding frontmatter |
| `finding_url` | From finding source_url |
| `finding_created` | From finding dc:created |
| `volatility_category` | From contradiction entry |
| `contradiction_severity` | From contradiction entry |
| `contradiction_evidence` | From contradiction entry |
| `contradicting_source_url` | From WebSearch result |
| `detected_at` | Current ISO8601 timestamp |
| `review_status` | "pending_review" |
| `resolution` | null |
| `resolved_at` | null |

### 5.4.3: Write Alerts File

Use Write tool to save alerts:

```text
Write tool:
- file_path: ${PROJECT_PATH}/.metadata/contradiction-alerts.json
- content: {complete alerts JSON with all alert objects}
```

**Mark Step 5.4 todo as completed** before proceeding.

---

## Step 5.5: Update Finding Metadata

**⚠️ COT REQUIRED:** Output `<update-reasoning>` block for EACH finding being updated.

Add review validation metadata to affected findings.

### 5.5.1: Update Findings with Contradictions

For each finding in CONTRADICTIONS_FOUND:

1. **Read finding file** using Read tool
2. **Parse existing frontmatter** (LLM reads YAML directly)
3. **Add review validation fields:**

   | Field | Value |
   |-------|-------|
   | `review_validated` | true |
   | `review_validated_at` | Current ISO8601 timestamp |
   | `volatility_category` | From contradiction entry |
   | `contradiction_detected` | true |
   | `contradiction_severity` | From contradiction entry |
   | `review_status` | "requires_review" |

4. **Add warning banner** for critical/high severity:

```markdown

> [!WARNING] **Review Alert ({severity})**
> This finding may contain outdated information. Recent developments detected:
> {evidence}
>
> **Validated**: {timestamp} | **Category**: {category}
>
> Review recommended before using in synthesis.

```

5. **Write updated finding** using Write tool

### 5.5.2: Mark Validated Findings Without Contradictions

For each finding in VOLATILE_FINDINGS not in CONTRADICTIONS_FOUND:

1. **Read finding file**
2. **Add review validation fields:**

   | Field | Value |
   |-------|-------|
   | `review_validated` | true |
   | `review_validated_at` | Current ISO8601 timestamp |
   | `volatility_category` | From volatile finding entry |
   | `contradiction_detected` | false |
   | `review_status` | "current" |

3. **Write updated finding** using Write tool

**Mark Step 5.5 todo as completed** before proceeding.

---

## Step 5.6: Log Validation Statistics

### 5.6.1: Calculate Metrics

From tracked data in memory:

| Metric | Calculation |
|--------|-------------|
| `findings_scanned` | Total findings from Glob |
| `volatile_topics_detected` | Count of VOLATILE_FINDINGS |
| `non_volatile_findings` | Count of NON_VOLATILE_FINDINGS |
| `validation_searches_executed` | Count of VALIDATION_RESULTS |
| `contradictions_found` | Count of CONTRADICTIONS_FOUND |
| `critical_contradictions` | Count where severity="critical" |
| `high_contradictions` | Count where severity="high" |

### 5.6.2: Output Summary

**If contradictions found:**

```text
Review validation complete:
- Findings scanned: {count}
- Volatile topics detected: {count}
- Non-volatile findings: {count}
- Validation searches: {count}
- Contradictions found: {count}
  - Critical: {count}
  - High: {count}
  - Medium: {count}
  - Low: {count}

⚠️ {count} findings require review
See: ${PROJECT_PATH}/.metadata/contradiction-alerts.json
```

**If no contradictions:**

```text
Review validation complete:
- Findings scanned: {count}
- Volatile topics detected: {count}
- Non-volatile findings: {count}
- Validation searches: {count}
- Contradictions found: 0

✅ All validated findings appear current
```

**Mark Step 5.6 todo as completed** and **mark Phase 5 phase-level todo as completed** before proceeding.

---

## Self-Verification Questions

Before marking Phase 5 complete, answer ALL questions:

### Reasoning Block Audit

| Question | YES/NO | If NO, Action |
|----------|--------|---------------|
| Did I output `<volatility-reasoning>` for EVERY finding? | | Go back and add |
| Did I output `<contradiction-reasoning>` for EVERY volatile finding? | | Go back and add |
| Did I show keyword-by-keyword evidence for volatility classification? | | Expand reasoning |
| Did I extract claims from findings BEFORE searching for contradictions? | | Re-read Step 5.3.1 |
| Did I output `<update-reasoning>` for ALL findings being updated? | | Add before updates |
| Did I output `<gate-summary>` for EVERY finding processed? | | Add summary blocks |

### Data Integrity Audit

| Question | YES/NO | If NO, Action |
|----------|--------|---------------|
| Did I process ALL findings from Glob (not just a subset)? | | Re-run Step 5.1.1 |
| Did I track both VOLATILE_FINDINGS and NON_VOLATILE_FINDINGS? | | Add missing tracking |
| Are all WebSearch queries based on actual finding titles (not invented)? | | Re-verify queries |
| Are contradiction severities supported by evidence from search results? | | Expand reasoning |
| Did I write alerts file before updating findings? | | Check Step 5.4 |

### Anti-Hallucination Audit

| Question | YES/NO | If NO, Action |
|----------|--------|---------------|
| Did I extract WebSearch results from actual tool responses (not invented)? | | Re-run searches |
| Did I use allowed_domains from the category tables (not custom domains)? | | Verify domain lists |
| Are contradiction_evidence descriptions based on actual search result excerpts? | | Verify evidence |
| Did I add warning banners ONLY for critical/high severity (not medium/low)? | | Re-check Step 5.5.1 |

**Minimum passing score:** 12/14 YES responses

**If <12 YES:** Do NOT proceed. Fix missing reasoning blocks first.

---

## Complete Worked Example

**Scenario:** Processing findings for research question about LkSG compliance trends

### Step 5.1: Volatility Classification

**Finding 1 of 4:**

```markdown
<volatility-reasoning>
**Finding:** finding-lksg-compliance-rates-a1b2c3d4.md
**Title:** "LkSG Compliance Rates Among German Enterprises"

**OBSERVE - Evidence Inventory:**
- Tags: ["finding", "lksg", "compliance", "supply-chain"]
- Content excerpt: "According to the BMAS report, 72% of affected enterprises have implemented basic LkSG compliance measures..."
- Source date: 2024-03-15

**Keywords Detected:**
| Category | Keywords Found | Match Strength |
|----------|---------------|----------------|
| regulations | ["LkSG", "compliance", "supply-chain"] | strong |
| politics | ["BMAS"] | weak |
| markets | "none" | none |
| technology | "none" | none |
| geopolitics | "none" | none |

**ANALYZE - Category Selection:**
- Strongest category: regulations
- Keywords supporting: ["LkSG", "compliance", "supply-chain"]
- Source age: 9 months
- Volatility window: 3 months
- Age vs window: outside (9 > 3)

**DECIDE - Classification:**
- **Status: VOLATILE**
- **Category: regulations**
- **Window: 3 months**
- **Rationale:** Finding directly addresses LkSG regulation compliance with source 9 months old, exceeding the 3-month volatility window for regulatory topics.
</volatility-reasoning>
```

**Finding 2 of 4:**

```markdown
<volatility-reasoning>
**Finding:** finding-methodology-qualitative-e5f6g7h8.md
**Title:** "Qualitative Research Methods in Supply Chain Analysis"

**OBSERVE - Evidence Inventory:**
- Tags: ["finding", "methodology", "research"]
- Content excerpt: "Qualitative methods including semi-structured interviews and thematic analysis provide deeper understanding..."
- Source date: 2023-06-01

**Keywords Detected:**
| Category | Keywords Found | Match Strength |
|----------|---------------|----------------|
| regulations | "none" | none |
| politics | "none" | none |
| markets | "none" | none |
| technology | "none" | none |
| geopolitics | "none" | none |

**ANALYZE - Category Selection:**
- Strongest category: none
- Keywords supporting: []
- Source age: 18 months
- Volatility window: N/A
- Age vs window: N/A (no volatile category)

**DECIDE - Classification:**
- **Status: NON-VOLATILE**
- **Category: N/A**
- **Window: N/A**
- **Rationale:** Methodological content with no volatile topic keywords. Research methods are stable knowledge not subject to rapid change.
</volatility-reasoning>
```

### Step 5.2: Batched WebSearch

```text
VOLATILE_FINDINGS after Step 5.1:
- finding-lksg-compliance-rates-a1b2c3d4.md (regulations)
- finding-csddd-eu-directive-i9j0k1l2.md (regulations)

CATEGORY_GROUPS:
  regulations: [finding-lksg-compliance-rates-a1b2c3d4.md, finding-csddd-eu-directive-i9j0k1l2.md]

Executing 2 parallel WebSearch calls:
```

### Step 5.3: Contradiction Analysis

```markdown
<contradiction-reasoning>
**Finding:** finding-lksg-compliance-rates-a1b2c3d4.md
**Category:** regulations
**Source Date:** 2024-03-15

**OBSERVE - Original Claims:**
| Claim Type | Original Value | Source |
|------------|---------------|--------|
| Percentage claim | "72% compliance rate" | Finding content |
| Status claim | "law is in full effect" | Finding content |
| Date claim | "since January 2024" | Finding content |
| Policy claim | "mandatory for enterprises >1000 employees" | Finding content |

**OBSERVE - WebSearch Evidence:**
| Result # | Title | Date | Key Finding |
|----------|-------|------|-------------|
| 1 | "LkSG: New amendments reduce scope - Reuters" | 2024-11-15 | "German government announces amendments reducing LkSG requirements for SMEs" |
| 2 | "Compliance rates increase to 85% - Handelsblatt" | 2024-12-01 | "Latest BMAS data shows 85% compliance among large enterprises" |
| 3 | "EU CSDDD delays impact LkSG timeline" | 2024-10-20 | "CSDDD postponement affects LkSG harmonization plans" |

**ANALYZE - Contradiction Detection:**

| Pattern | Check | Evidence | Result |
|---------|-------|----------|--------|
| Policy reversal | abgeschafft, abolished, reversed, cancelled | "none" | NO |
| Significant amendment | amended, changed, modified, updated | "amendments reducing LkSG requirements" | YES |
| Recent development | Dates from 2024 | "2024-11-15, 2024-12-01" | YES |
| Conflicting statistics | Different % for same metric | "72% vs 85% compliance" | YES |
| Context shift | Updated framing | "CSDDD delays impact" | YES |

**Contradiction List:**
- [Significant amendment: LkSG requirements reduced for SMEs]
- [Conflicting statistics: Finding claims 72%, recent data shows 85%]
- [Recent development: CSDDD delays affect LkSG harmonization]

**DECIDE - Severity Assignment:**
- Contradictions found: 3
- Most severe pattern: Significant amendment
- **Severity: high**
- **Rationale:** Finding's 72% compliance rate is outdated (now 85%), and regulatory amendments have changed SME requirements. Core claim about law status remains valid, but statistics and scope details need updating.

**Metadata to add:**

```yaml
contradiction_detected: true
contradiction_severity: "high"
contradiction_evidence: "Compliance rate increased from 72% to 85%; SME requirements amended"
contradicting_source_url: "https://www.reuters.com/lksg-amendments-2024"
```

</contradiction-reasoning>
```

### Step 5.5: Update Justification

```markdown
<update-reasoning>
**Finding:** finding-lksg-compliance-rates-a1b2c3d4.md
**Classification:** VOLATILE
**Contradiction:** detected (high severity)

**OBSERVE - Current State:**
- review_validated: not set
- review_status: not set
- contradiction_severity: not set

**ANALYZE - Required Updates:**
| Field | Current | New | Reason |
|-------|---------|-----|--------|
| review_validated | not set | true | Validation complete |
| review_validated_at | not set | 2025-01-09T14:30:00Z | Record validation time |
| volatility_category | not set | regulations | From Step 5.1 |
| contradiction_detected | not set | true | From Step 5.3 |
| contradiction_severity | not set | high | From Step 5.3 |
| review_status | not set | requires_review | Derived from high severity |

**DECIDE - Update Actions:**
- **Add warning banner:** YES
- **Banner severity:** high
- **Review status:** requires_review
- **Rationale:** High severity contradiction with outdated statistics (72% vs 85%) requires user review before synthesis.
</update-reasoning>
```

### Gate Summary

```markdown
<gate-summary finding="finding-lksg-compliance-rates-a1b2c3d4.md">
| Gate | Status | Key Metric |
|------|--------|------------|
| Volatility (5.1) | VOLATILE | regulations |
| Search (5.2) | SUCCESS | 3 results |
| Contradiction (5.3) | FOUND | high severity |
| Update (5.5) | COMPLETE | 6 fields |

**Final Status:** REQUIRES_REVIEW
**Action:** Warning banner added, metadata updated, alert created
</gate-summary>
```

---

## Expected Outputs

| Output | Location | Validation |
|--------|----------|------------|
| Contradiction alerts | `.metadata/contradiction-alerts.json` | Structured alerts for review |
| Updated finding metadata | `04-findings/data/*.md` | Review validation fields |
| Warning banners | Finding markdown body | For critical/high severity |
| Validation statistics | Execution output | Metrics for monitoring |
| Reasoning audit trail | Execution log | All COT blocks captured |

---

## Integration with Synthesis

The synthesis phase should:

1. **Check review_status**: Skip or flag findings with `review_status: "requires_review"`
2. **Filter critical contradictions**: Exclude findings with `contradiction_severity: "critical"` from synthesis
3. **Add caveats**: For findings with `contradiction_detected: true`, add uncertainty language
4. **Reference alerts**: Link to contradiction-alerts.json when noting limitations

---

## See Also

- [phase-4-finding-extraction.md](phase-4-finding-extraction.md) - Previous phase (Finding Extraction)
- [../SKILL.md](../SKILL.md) - Main skill documentation
- [../../deeper-synthesis/SKILL.md](../../deeper-synthesis/SKILL.md) - Synthesis integration
