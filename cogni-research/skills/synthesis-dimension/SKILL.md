---
name: synthesis-dimension
description: "[Internal] Generate dimension synthesis documents from trends for research reports. Invoked by deeper-research-3."
---

# Synthesis Dimension

---

## Invocation Guard - READ BEFORE PROCEEDING

**This is an EXECUTOR skill. It should NOT be invoked directly.**

### Correct Invocation Path

```text
User → deeper-research-3 skill (ORCHESTRATOR)
       └→ Phase 8.5: Task tool → synthesis-dimension AGENT → this skill
```

### If You Are Reading This Directly

**STOP.** You likely invoked this skill directly via `Skill(skill="cogni-research:synthesis-dimension")`.

**What to do instead:**

1. Use the `deeper-research-3` skill instead:

   ```text
   Skill(skill="cogni-research:deeper-research-3")
   ```

2. `deeper-research-3` will orchestrate the full workflow and invoke this skill correctly via wrapper agents (one per dimension, in parallel).

### Exception: Agent Wrapper Invocation

If you are the `synthesis-dimension` agent (invoked via Task tool from deeper-research-3 Phase 8.5), proceed to Phase 1 below.

---

## Purpose

Transform dimension-scoped trend collections into comprehensive synthesis documents ready for integration into the final research report. Creates evidence-based narratives with cross-trend connections, strategic implications, and complete citation provenance.

**Key Differentiator:** While `trends-creator` generates individual trend entities and basic READMEs (~90 lines), this skill produces rich synthesis documents (1,000-1,500 words) that bridge the gap between raw trends and final report synthesis. Enhanced v2.0+ features: planning horizon structure, component quality scoring, evidence quality analysis, megatrend integration, and enhanced metrics for synthesis-hub aggregation.

## When to Use

- After `trends-creator` has populated `11-trends/data/` with trend entities
- When `11-trends/README-{dimension}.md` exists for the target dimension
- To create integration-ready content for `synthesis-hub`
- When synthesizing cross-trend patterns within a single dimension

**Not for:**

- Creating trend entities (use trends-creator)
- Cross-dimensional synthesis (use synthesis-hub)
- Final research report generation (use synthesis-hub)

---

## Immediate Action: Initialize TodoWrite

**MANDATORY:** Initialize TodoWrite immediately with all workflow phases:

1. Phase 1: Setup & Validation [in_progress]
2. Phase 2: Entity Loading [pending]
3. Phase 3: Pattern Analysis [pending]
4. Phase 4: Synthesis Generation [pending]
5. Phase 5: Validation & Output [pending]

Update todo status as you progress through each phase.

**Note:** Each phase will add step-level todos when started (progressive expansion from 5 phase-level to ~15-20 step-level).

---

## Output Language

**Language Parameter:** Detected from `.metadata/sprint-log.json` field `project_language`

**Reference:** See [references/language-templates.md](references/language-templates.md) for complete language template definitions.

**Supported Languages:**

| Code | Language | Status    |
|------|----------|-----------|
| en   | English  | Supported |
| de   | German   | Supported |

**Language Detection Order:**

1. Read `project_language` field from `.metadata/sprint-log.json`
2. Validate against supported languages (en, de)
3. Default to `en` if unsupported or missing

**Language Impact:**

- **Section headers:** Translated per language (e.g., "Executive Summary" vs "Zusammenfassung")
- **Navigation labels:** Localized breadcrumb text
- **Evidence assessment table:** Localized metric names
- **Body text:** Written in project language with proper formatting

**German (de):** Use proper umlauts (ä, ö, ü, ß) in body text and headings. Use ASCII transliterations in file names, slugs, frontmatter identifiers. Use comma as decimal separator in prose.

**English (en):** Professional business English. Use period as decimal separator.

---

## Arc-Aware Synthesis

When a story arc (`arc_id`) is detected in `.metadata/sprint-log.json`, synthesis-dimension replaces the generic main body structure with 4 arc element sections. The appendix (evidence tables, references) remains unchanged.

**Key principle:** Organize evidence by arc **purpose** (which question it answers), not arc **rhetoric** (PSB structure, IS-DOES-MEANS). Rhetoric stays in cogni-narrative (Phase 10.5).

**Template routing:**

| arc_id | Arc Display Name | Elements |
|--------|-----------------|----------|
| `corporate-visions` | Corporate Visions | Why Change / Why Now / Why You / Why Pay |
| `technology-futures` | Technology Futures | What's Emerging / Converging / Possible / Required |
| `competitive-intelligence` | Competitive Intelligence | Landscape / Shifts / Positioning / Implications |
| `strategic-foresight` | Strategic Foresight | Signals / Scenarios / Strategies / Decisions |
| `industry-transformation` | Industry Transformation | Forces / Friction / Evolution / Leadership |
| *(empty/unrecognized)* | *(generic)* | Executive Summary / Strategic Context / Key Trends / Cross-Connections / Implications |

**Propagation chain:** Arc-framed dimensions (this skill) → synthesis-hub absorbs arc structure (Phase 10) → cogni-narrative gets pre-organized input (Phase 10.5). This is progressive refinement at different scopes: per-dimension → cross-dimensional → rhetorical transformation.

**Backward compatibility:** Entire arc path is conditional on non-empty `arc_id`. Empty or unrecognized → generic path, completely unchanged behavior.

---

## Core Workflow

```text
Setup → Loading → Analysis → Synthesis → Validation
```

**MANDATORY PHASE GATES:** Each phase has required artifacts and self-verification questions. You MUST:

1. Answer verification questions before proceeding to next phase
2. Verify previous phase artifacts exist BEFORE starting next phase
3. Update step-level todos as you complete each verification step

### Execution Protocol

1. **First**: Read the phase reference file BEFORE executing that phase
2. **Per-phase**: The reference contains the actual implementation steps
3. **Validation**: Each phase has verification checkpoints in its reference

**MANDATORY: Read the phase reference file BEFORE executing that phase.**

| Phase | Objective | Reference |
| ----- | --------- | --------- |
| 1. Setup | Validate parameters, check prerequisites | [phase-1-setup.md](references/phase-workflows/phase-1-setup.md) |
| 2. Loading | Load dimension trends and related entities | [phase-2-loading.md](references/phase-workflows/phase-2-loading.md) |
| 3. Analysis | Extract patterns, connections, evidence quality | [phase-3-analysis.md](references/phase-workflows/phase-3-analysis.md) |
| 4. Synthesis | Generate narrative with citations | [phase-4-synthesis.md](references/phase-workflows/phase-4-synthesis.md) |
| 5. Validation | Verify citations, write output | [phase-5-validation.md](references/phase-workflows/phase-5-validation.md) |

---

### Phase 1: Setup & Validation

**GATE CHECK:** N/A (first phase)

Read [references/phase-workflows/phase-1-setup.md](references/phase-workflows/phase-1-setup.md) for complete setup protocol.

**Objective:** Validate parameters and verify prerequisites exist.
**Critical:** All prerequisites verified before proceeding to loading phase.

**Parameters:**

- `--project-path`: Research project directory (REQUIRED)
- `--dimension`: Dimension slug to synthesize (REQUIRED)

**Core steps:**

1. Validate project-path parameter exists
2. Validate dimension parameter exists
3. Verify `11-trends/README-{dimension}.md` exists
4. Verify `11-trends/data/` contains trends for this dimension
5. Read `.metadata/sprint-log.json` for research_type and language
5b. Read `arc_id` and `arc_display_name` from sprint-log.json; validate against recognized arcs; load arc template if recognized
6. Initialize logging

**Required outputs:** Parameters validated, prerequisites confirmed, research_type detected, arc configuration resolved (ARC_ID + template or empty for generic)

---

### Phase 2: Entity Loading [BLOCKING]

**GATE CHECK:** Before starting, verify Phase 1 completion:

- Parameters validated
- README-{dimension}.md exists
- Research type detected

**IF MISSING: STOP. Return to Phase 1.**

Read [references/phase-workflows/phase-2-loading.md](references/phase-workflows/phase-2-loading.md) for complete loading protocol.

**Objective:** Load all dimension-scoped entities for synthesis.
**Critical:** Complete loading required (anti-hallucination safeguard).

**CRITICAL:** Use Claude Code Read tool for ALL entity loading. Bash cat alone does NOT populate LLM context.

**Core steps:**

1. Read `11-trends/README-{dimension}.md` to get trend list
2. Read ALL trend files for this dimension from `11-trends/data/`
3. Extract claim_refs from each trend, read referenced claims from `10-claims/data/`
4. Extract finding_refs from each trend, read referenced findings from `04-findings/data/`
5. Read dimension entity from `01-research-dimensions/data/`
6. Read related domain concepts from `05-domain-concepts/data/` (if applicable)

#### Verification Checkpoint (BLOCKING)

**Self-test before proceeding:**

1. "What trends exist for this dimension?"
2. "What is the average confidence score across trends?"
3. "What claims support these trends?"
4. "What thematic patterns appear across trends?"
5. "What is the dimension's strategic context?"

**If unable to answer → STOP and re-invoke Read tools.**

**Required outputs:** All dimension entities loaded into context, `DIMENSION_CORE_QUESTION` extracted, verification questions answered

---

### Phase 3: Pattern Analysis

**GATE CHECK:** Before starting, verify Phase 2 completion:

- All trends loaded for dimension
- Claims and findings loaded
- Dimension context understood

**IF MISSING: STOP. Return to Phase 2.**

Read [references/phase-workflows/phase-3-analysis.md](references/phase-workflows/phase-3-analysis.md) for complete analysis protocol.

**Objective:** Extract patterns, connections, and evidence quality metrics.
**Critical:** Analysis drives synthesis structure and content.

**Core steps:**

1. Identify thematic clusters across trends
2. Map cross-trend connections (shared claims, related findings)
3. Calculate evidence quality metrics (avg confidence, freshness)
4. Identify strategic implications patterns
5. Detect tensions or contradictions between trends
6. Rank trends by strategic importance
7. *(If ARC_ID set)* Classify trends and claims into arc elements using signal words, planning horizon affinity, and semantic matching

**Required outputs:** Pattern analysis complete, connection map built, quality metrics calculated, arc element map built (if ARC_ID set)

---

### Phase 4: Synthesis Generation

**GATE CHECK:** Before starting, verify Phase 3 completion:

- Thematic clusters identified
- Cross-trend connections mapped
- Evidence quality assessed

**IF MISSING: STOP. Return to Phase 3.**

Read [references/phase-workflows/phase-4-synthesis.md](references/phase-workflows/phase-4-synthesis.md) for complete synthesis protocol.

**Objective:** Generate comprehensive synthesis document with evidence-based narrative.
**Critical:** All claims must trace to loaded entities (no fabrication).

**Core steps (generic path — ARC_ID empty):**

1. Generate YAML frontmatter (title, dimension, research_type, metrics, enhanced quality scores)
2. Add Navigation Header
3. Write Executive Summary (200-300 words, 3-5 citations)
4. Write Strategic Context (150-200 words, 2-3 citations)
5. Write Key Trends section with planning horizon structure (450-650 words, Act/Plan/Observe subsections)
6. Write Cross-Trend Connections (150-200 words)
7. Add Related Dimensions section (50-100 words, if applicable)
8. Add Related Megatrends section (100-150 words, if applicable)
9. Write Implications & Recommendations with role-based framing (280-400 words)
10. Generate Evidence Assessment tables (4 tables: Quality Overview, Quality Distribution, Verification Status, Source Reliability)
11. Write Evidence Quality Analysis section (250-300 words, 4 subsections)
12. Include Domain Concepts (if applicable)
13. Generate References section with both formats

**Core steps (arc path — ARC_ID set):**

1. Generate YAML frontmatter (standard + arc_id, arc_display_name, arc_elements)
2. Add Navigation Header
3. Write Overview paragraph (100-150 words, 1-2 citations)
4. Write Arc Element 1 section (250-400 words, 3-5 citations)
5. Write Arc Element 2 section (200-350 words, 2-4 citations)
6. Write Arc Element 3 section (250-400 words, 3-5 citations)
7. Write Arc Element 4 section (150-250 words, 2-3 citations)
8. Add Related Dimensions section (50-100 words, if applicable)
9. Add Related Megatrends section (100-250 words, if applicable)
10-13. Appendix (unchanged from generic path)

**Wikilink Requirement:**
When mentioning concepts, trends, or claims in narrative text (Executive Summary, Strategic Context, Key Trends, etc.), wikilink to the entity file on first mention per section using format: `[[entity-path|Display Title]]`. Example: `Digital Twins [[08-concepts/data/concept-digital-twins|Digital Twins]] enable...`

**Citation Format (MANDATORY - Both Formats):**

```markdown
Evidence text<sup>[1](11-trends/data/trend-id.md)</sup> [[11-trends/data/trend-id|Trend Title]].
```

**Required outputs:** Complete synthesis document in memory, ready for validation

---

### Phase 5: Validation & Output

**GATE CHECK:** Before starting, verify Phase 4 completion:

- Synthesis document generated
- All sections present
- Citations use correct dual format

**IF MISSING: STOP. Return to Phase 4.**

Read [references/phase-workflows/phase-5-validation.md](references/phase-workflows/phase-5-validation.md) for complete validation protocol.

**Objective:** Verify citation provenance and write validated output.
**Critical:** All entity IDs must exist in filesystem.

**Core steps:**

1. Extract all entity IDs from citations
2. Verify each exists in filesystem
3. If ANY invalid → ABORT with error JSON
4. Calculate word count (target: 1,000-1,500 words)
5. Write synthesis document to `12-synthesis/synthesis-{dimension}.md`
6. Generate execution summary JSON

**Output Path:** `12-synthesis/synthesis-{dimension}.md`

**Success Response:**

```json
{
  "success": true,
  "dimension": "governance-transformationssteuerung",
  "file": "12-synthesis/synthesis-governance-transformationssteuerung.md",
  "trends_synthesized": 5,
  "citations_created": 24,
  "word_count": 1247,
  "cross_connections_identified": 4
}
```

**Concise Summary (5 lines max):**

```text
✅ Dimension synthesis complete.
- Dimension: {dimension}
- Trends synthesized: {count}
- Citations created: {count}
- Output: 12-synthesis/synthesis-{dimension}.md
```

---

## Output Format

**File:** `12-synthesis/synthesis-{dimension-slug}.md`

**Structure:**

```markdown
---
title: "Dimension Synthesis: {Display Name}"
dimension: "{slug}"
research_type: "{type}"
tags: [answer, synthesis-level/dimensions]
synthesis_date: "{ISO 8601}"
word_count: {N}
citation_count: {N}
trend_count: {N}
cross_connections: {N}
avg_confidence: {0.XX}
thematic_clusters: {N}
evidence_freshness: "{status}"
# Enhanced metrics for synthesis-hub aggregation
avg_evidence_strength: {0.XX}
avg_strategic_relevance: {0.XX}
avg_actionability: {0.XX}
avg_novelty: {0.XX}
verification_rate: {0.XX}
source_tier_1_percentage: {0.XX}
---

> **Navigation:** [Back to Research Report Overview](../research-hub.md) | **Current:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

## {HEADER_EXECUTIVE_SUMMARY}

[200-300 words, 3-5 citations]

## {HEADER_STRATEGIC_CONTEXT}

[150-200 words, 2-3 citations]

## {HEADER_KEY_TRENDS}

### Act Now (0-6 Months)
Trends requiring immediate action with mature evidence.

#### {Trend Title} (Confidence: 0.85, Quality: 0.82)

[80-120 words per trend with inline citations]

### Plan Ahead (6-18 Months)
Trends requiring capability building with strong signals.

#### {Trend Title} (Confidence: 0.78, Quality: 0.76)

[80-120 words per trend]

### Observe & Monitor (18+ Months)
Emerging trends with early-stage evidence.

#### {Trend Title} (Confidence: 0.72, Quality: 0.68)

[80-120 words per trend]

## {HEADER_CROSS_CONNECTIONS}

[150-200 words describing relationships between trends]

## {HEADER_RELATED_DIMENSIONS}

[50-100 words, optional if cross-dimension connections exist]

## {HEADER_RELATED_MEGATRENDS}

- [[06-megatrends/data/megatrend-{slug}|{title}]] ({horizon}, {0.XX}) - {connection description}
...

[100-150 words, optional if megatrend references exist]

## {HEADER_IMPLICATIONS}

### Strategic Implications

**For Technology Leaders:**
- Implication with planning horizon reference

**For Operations:**
- Implication with citation

**For Workforce Planning:**
- Implication with quality insights

### Tactical Recommendations
1. Priority recommendation with citation
2. ...

[280-400 words total]

## {HEADER_EVIDENCE_ASSESSMENT}

### Quality Overview
| {TH_METRIC} | {TH_VALUE} | {TH_INTERPRETATION} |
| ------ | ----- | ------------ |
| {ROW_TOTAL_TRENDS} | {N} | {X act, Y plan, Z observe} |
...

### Quality Distribution
| {TH_QUALITY_DIMENSION} | {TH_AVERAGE} | {TH_RANGE} | {TH_NOTES} |
| ----------------- | ------- | ----- | ----- |
| {ROW_EVIDENCE_STRENGTH} | {0.XX} | {min}-{max} | Strong citation base |
...

### Verification Status
| {TH_STATUS} | {TH_CLAIMS} | {TH_PERCENTAGE} |
| ------ | ----- | ---------- |
| {ROW_VERIFIED} | {N} | {XX%} |
...

### Source Reliability
| {TH_TIER} | {TH_SOURCES} | {TH_EXAMPLES} |
| ---- | ------- | -------- |
| {ROW_TIER_1} | {N} | Nature, Science... |
...

## {HEADER_EVIDENCE_QUALITY_ANALYSIS}

### Verification Robustness
[Analysis of verification rate and unverified claims]

### Source Authority
[Analysis of tier distribution with examples]

### Evidence Freshness
[Analysis of recency]

### Quality Dimension Insights
**Evidence Strength**: [Interpretation]
**Strategic Relevance**: [Interpretation]
**Actionability**: [Interpretation]
**Novelty**: [Interpretation]

[250-300 words total]

## Domain Concepts

[5-10 key terms if applicable]

## References

[1] [Trend Title](11-trends/data/trend-slug.md) [[11-trends/data/trend-slug|Trend Title]]
[2] [Claim Title](10-claims/data/claim-slug.md) [[10-claims/data/claim-slug|Claim Title]]
...
```

### Arc-Aware Output Format (when arc_id is set)

When `arc_id` is present in sprint-log.json, the main body sections are replaced by arc element sections. Frontmatter and appendix remain unchanged.

```markdown
---
{standard frontmatter as above}
arc_id: "{arc_id}"
arc_display_name: "{Arc Display Name}"
arc_elements: ["{Element 1}", "{Element 2}", "{Element 3}", "{Element 4}"]
---

> **Navigation:** [Back to Research Report Overview](../research-hub.md) | **Current:** {Dimension Display Name}

# {Dimension Display Name}

*{DIMENSION_CORE_QUESTION}*

{Overview paragraph: 100-150 words with 1-2 citations}

## {Arc Element 1 Header}

[250-400 words with 3-5 citations — trends classified to this element]

## {Arc Element 2 Header}

[200-350 words with 2-4 citations]

## {Arc Element 3 Header}

[250-400 words with 3-5 citations]

## {Arc Element 4 Header}

[150-250 words with 2-3 citations]

## {HEADER_RELATED_DIMENSIONS}

[50-100 words, optional]

## {HEADER_RELATED_MEGATRENDS}

[100-250 words, optional]

## {HEADER_APPENDIX}

{Unchanged: Evidence Assessment, Evidence Quality Analysis, Domain Concepts, References}
```

---

## Input Requirements

- Research project path with completed trends generation
- `.metadata/sprint-log.json` with research_type field
- `11-trends/README-{dimension}.md` must exist
- `11-trends/data/` must contain trend files for the dimension
- Minimum: 3 trends per dimension for meaningful synthesis

---

## Anti-Hallucination Principles

1. **Complete loading** - Read ALL dimension entities with Read tool (never truncation)
2. **Blocking verification** - Checkpoint validates completeness before synthesis
3. **Entity validation** - Pre-write check ensures all cited IDs exist in filesystem
4. **Citation provenance** - All citations trace to actual loaded entities
5. **No fabrication** - Never invent entity IDs, statistics, or claims

---

## Constraints

- DO NOT modify source entity files (read-only access)
- DO NOT create new trends (synthesize existing only)
- ALWAYS use dual citation format (numbered + wikilinks)
- ALWAYS validate entity IDs before writing
- ALWAYS stay within 1,000-1,500 word target

---

## Error Handling

| Phase | Failure | Action |
| ----- | ------- | ------ |
| 1 | Setup validation | HALT with error JSON |
| 2 | Entity loading | HALT and re-invoke Read tools |
| 3 | Pattern analysis | HALT with error JSON |
| 4 | Synthesis | HALT with error JSON |
| 5 | Validation | HALT with fabricated entity report |

---

## Success Criteria

- Project path validated and dimension confirmed (Phase 1)
- Arc configuration resolved: ARC_ID set (recognized) or empty (generic) (Phase 1)
- All dimension trends loaded and verified (Phase 2)
- Enhanced entity loading complete:
  - Trend quality_scores components extracted (evidence_strength, strategic_relevance, actionability, novelty)
  - Claim verification_status loaded
  - Finding quality_dimensions loaded
  - Source reliability_tier mapped (tier-1/2/3/4)
  - Megatrend metadata loaded (if applicable)
- Pattern analysis complete with connection map (Phase 3)
- Planning horizon groups established (act/plan/observe)
- Enhanced quality metrics calculated (component scores, verification breakdown, source tier distribution)
- *(If ARC_ID set)* Arc element evidence classification complete — all trends assigned to exactly one element, no empty elements
- Synthesis document generated with dual citations (Phase 4)
- **Generic path checks:**
  - Planning horizon structure present in Key Trends section (Act/Plan/Observe subsections)
  - Implications & Recommendations includes role-based framing
- **Arc path checks:**
  - Overview paragraph present (100-150 words)
  - 4 arc element H2 sections present with correct headers per arc_id and PROJECT_LANGUAGE
  - Arc frontmatter fields present (arc_id, arc_display_name, arc_elements)
  - Each element contains only trends/claims classified to it (from ARC_ELEMENT_MAP)
- Evidence Assessment includes 4 tables (Quality Overview, Quality Distribution, Verification Status, Source Reliability)
- Evidence Quality Analysis section present with 4 subsections
- Related Megatrends section included (if applicable)
- Citations validated and output written (Phase 5)
- Word count within 1,000-1,500 target
- Enhanced frontmatter metrics present (avg_evidence_strength, verification_rate, etc.)
- All phases marked completed in TodoWrite

---

## Token Budget

Estimated: ~18,900 tokens (9.5% of 200K budget)

| Phase | Est. Tokens | Notes |
| ----- | ----------- | ----- |
| 1 | 1,500 | Unchanged |
| 2 | 7,100 | +1,100 for enhanced metadata loading (quality components, verification status, source reliability, megatrend metadata) |
| 3 | 3,000 | Unchanged (planning horizon grouping is calculation, not loading) |
| 4 | 5,300 | -200 for tighter prose offsetting enhanced structure |
| 5 | 2,000 | Unchanged |

**Enhancement cost:** +900 tokens (5% increase)
**Arc-aware cost:** +800 tokens (+4.2%) for arc detection, template loading, and evidence classification (Phase 1 Step 1.5b + Phase 3 Step 3.7)
**Headroom:** ~86% context window still available

Phase 2 scales with trend count (10+ trends may require 9,000+ tokens).

---

## Related Skills

- **trends-creator** - Creates trend entities (prerequisite)
- **synthesis-hub** - Final report synthesis (consumer of this output)
- **deeper-research-3** - Orchestrator that invokes this skill

---

## Debugging

### Enhanced Logging Initialization

```bash
# Source enhanced logging utility
source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"

# Initialize skill-specific log file
SKILL_NAME="synthesis-dimension"
LOG_FILE="${PROJECT_PATH}/.metadata/${SKILL_NAME}-execution-log.txt"
mkdir -p "${PROJECT_PATH}/.metadata"

# Log phase transitions
log_phase "Phase 2: Entity Loading" "start"
# ... phase work ...
log_phase "Phase 2: Entity Loading" "complete"

# Log metrics at completion
log_metric "trends_synthesized" "$trends_count" "count"
log_metric "citations_created" "$citations_count" "count"
```

Enable verbose stderr output: `export DEBUG_MODE=true`

Log locations:

- Execution logs: `${PROJECT_PATH}/.metadata/synthesis-dimension-execution-log.txt`
