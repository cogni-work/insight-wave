# Claim Entity Templates

Markdown file structure with YAML frontmatter for claim entities in `${CLAIMS_DIR}/data/` directory.

**Note:** Variables like `${CLAIMS_DIR}` and `${FINDINGS_DIR}` are resolved in Phase 2 Step 4. Examples use `{{placeholder}}` syntax for conceptual clarity.

## Filename Format

**Pattern:** `claim-{semantic-description}-{6-char-hash}.md`

**Examples:**
- `claim-green-bond-market-size-a3f5b2.md`
- `claim-pico-framework-usage-xyz789.md`
- `claim-ev-charging-infrastructure-abc123.md`

**Generation Rules:**
- Semantic description: 3-5 words describing claim content, kebab-case
- **Hash Algorithm:** MD5 hash of full claim text, take first 6 hexadecimal characters
  - Example: `echo -n "Green bonds issued $500B in 2023" | md5sum` → `a3f5b2...`
  - Use first 6 chars: `a3f5b2`
- Total length: Keep under 80 characters for filesystem compatibility
- **Collision Risk:** With 6-char hex (16^6 = 16.7M combinations), collision probability low for typical research projects (<10K claims)

## Bold Title Format

Each claim MUST include a **bold title** with 3-5 descriptive words placed between the `## Claim` header and the claim text.

**Rules:**

- **Word Count:** 3-5 descriptive words (no less, no more)
- **Format:** Title case, wrapped in double asterisks (`**Title Here**`)
- **Content:** Summarizes the claim's key subject/topic
- **Placement:** Immediately after `## Claim` header, before the claim text

**Examples:**

- `**Global Green Bond Issuance**` (4 words)
- `**PICO Framework Clinical Adoption**` (4 words)
- `**EV Charging Infrastructure Growth**` (4 words)
- `**European Carbon Market Trends**` (4 words)
- `**Healthcare AI Implementation Barriers**` (4 words)

## YAML Frontmatter

Complete frontmatter structure with all required fields:

```yaml
---
# Obsidian Tags (v2.0 format - use-case driven)
tags: [finding, confidence/{very-high|high|moderate|low}, verification/{verified|pending|rejected}]
title: "{Brief claim summary}"

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "fact-checker"
dc:title: "Claim: {brief claim summary, max 100 chars}"
dc:date: "2025-01-01T12:00:00Z"
dc:identifier: "claim-{semantic-description}-{hash}"
dc:type: "claim"
dc:subject: ["{megatrend-tags}"]
dc:description: "The exact factual assertion extracted from finding"
dc:relation: ["finding-{ids}", "source-{ids}", "question-{ids}", "dimension-{id}"]

# Legacy Fields (maintained for compatibility)
entity_type: "claim"
claim_text: "The exact factual assertion extracted from finding"
language: "{lang}"  # Language code when --language provided

# Upstream Wikilinks (required by schema)
finding_refs: ["[[04-findings/data/finding-{id}]]"]  # Claims reference findings only (upstream-only pattern)

# LAYER 1: Evidence Reliability (5 factors)
evidence_confidence: 0.82
source_quality_tier: 2
evidence_count: 2
cross_validation_score: 0.7
recency_score: 1.0
expertise_match_score: 1.0

# LAYER 2: Claim Quality (4 dimensions)
claim_quality: 0.68
quality_dimensions:
  atomicity: 1.0
  fluency: 0.7
  decontextualization: 1.0
  faithfulness: 0.7

# Composite final score
confidence_score: 0.77

# Quality flags
quality_flags: []

# Research attribution
quality_framework:
  dimensions_source: "Wright et al. (2022)"
  operationalization_source: "Agh et al. (2025)"
  arxiv: "https://arxiv.org/html/2502.04955v1"

# Review flags
is_critical: false
flagged_for_review: false
created_at: "2025-01-01T12:00:00Z"

provenance:
  # AUDIT METADATA (technical provenance, not wikilinks)
  query_batch: "query-batch-economic"
  verification_agent: "fact-checker"
  verification_timestamp: "2025-01-01T12:00:00Z"
---
```

### Field Descriptions

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `tags` | array | Obsidian classification | `[finding, confidence/high, verification/verified]` |
| `dc:creator` | string | Entity creator | `"fact-checker"` |
| `dc:title` | string | Brief title (max 100 chars) | `"Claim: Green bond market size in 2023"` |
| `dc:date` | ISO 8601 | Creation timestamp | `"2025-01-01T12:00:00Z"` |
| `dc:identifier` | string | Unique claim ID | `"claim-green-bond-market-a3f5b2"` |
| `entity_type` | string | Legacy type field | `"claim"` |
| `claim_text` | string | Exact factual assertion | Verbatim claim text |
| `language` | string | ISO 639-1 code | `"en"`, `"de"`, `"fr"` |
| `finding_refs` | array | Wikilinks to supporting findings | `["[[04-findings/data/finding-xyz]]"]` |
| `evidence_confidence` | float | 5-factor score (0-1) | `0.82` |
| `source_quality_tier` | int | Tier 1-4 | `2` |
| `evidence_count` | int | Number of findings | `2` |
| `cross_validation_score` | float | Validation score (0-1) | `0.7` |
| `recency_score` | float | Time-based score (0-1) | `1.0` |
| `expertise_match_score` | float | Author expertise (0-1) | `1.0` |
| `claim_quality` | float | 4-dimension avg (0-1) | `0.68` |
| `quality_dimensions.atomicity` | float | Binary 0/1 | `1.0` |
| `quality_dimensions.fluency` | float | Continuous 0-1 | `0.7` |
| `quality_dimensions.decontextualization` | float | Binary 0/1 | `1.0` |
| `quality_dimensions.faithfulness` | float | Continuous 0-1 | `0.7` |
| `confidence_score` | float | Final composite (0-1) | `0.77` |
| `quality_flags` | array | Quality issue messages | `[]` or `["atomicity: Contains multiple relations (0.0)"]` |
| `is_critical` | boolean | Contains quantitative/safety data | `true`/`false` |
| `flagged_for_review` | boolean | Needs human review | `true`/`false` |
| `provenance.query_batch` | string | Query batch name (not wikilink) | `"query-batch-economic"` |
| `provenance.verification_agent` | string | Agent that verified claim | `"fact-checker"` |
| `provenance.verification_timestamp` | ISO 8601 | Verification timestamp | `"2025-01-15T14:32:00Z"` |

## Required Content Structure

**Language-Aware Section Headers:**

Section headers MUST match the `language` of the claim. Use the appropriate header set:

| Section | English (en) | German (de) |
|---------|-------------|-------------|
| Claim | Claim | Behauptung |
| Justification | Justification | Begründung |
| Evidence | Evidence | Beweise |
| Confidence | Confidence Breakdown | Konfidenz-Aufschlüsselung |
| Provenance | Provenance (Audit Trail) | Provenienz (Audit-Pfad) |

**Default behavior:** If `language` is not in the table, use English headers.

**German Body Text Formatting (when language=de):**

When creating claim content in German, use proper Unicode characters:

| Element | Format | Example |
|---------|--------|---------|
| Body text | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| Explanations | Proper umlauts | "für" NOT "fuer", "müssen" NOT "muessen" |
| Section headers | German headers from table above | "Begründung" NOT "Begrundung" |
| Filenames/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| YAML identifiers | ASCII only | dc:identifier, entity IDs |

**Correct German claim text:**
> "Das Jahr 2026 bringt wichtige arbeitsrechtliche Änderungen, die für Personalstrategien beachtet werden müssen"

**Incorrect (ASCII fallback):**
> "Das Jahr 2026 bringt wichtige arbeitsrechtliche Aenderungen, die fuer Personalstrategien beachtet werden muessen"

Markdown content below frontmatter:

```markdown
## Claim

**{Bold Title: 3-5 Descriptive Words}**

{claim_text}

## Relevance

Explain why this claim was selected for fact-checking (2-3 sentences covering centrality, impact, and verifiability).

## Evidence

Supporting findings:
- [[finding-{actual-uuid-1}]]
- [[finding-{actual-uuid-2}]]

## Confidence Breakdown

- **Source Quality (35%)**: {score} (Tier {number})
- **Evidence Count (25%)**: {score} ({count} findings)
- **Cross-Validation (20%)**: {score} ({description})
- **Recency (10%)**: {score} ({age} old)
- **Expertise Match (10%)**: {score} ({match_description})

**Total Confidence**: {final_score}

## Provenance (Audit Trail)

**Research Path**: Dimension → Question → Finding → Claim → Verification

- **Answers Questions**:
  - [[tech-q1|What technical specifications are required?]]
  - [[econ-q2|What is the market size and growth trajectory?]]

- **Research Dimension**: [[technical-feasibility|Technical Feasibility]]

- **Thematic Topics** (optional):
  - [[megatrend-safety-features-a3f5|Safety Features]]
  - [[megatrend-market-growth-b7c9|Market Growth]]

- **Supporting Findings** ({count} total):
  - [[finding-{actual-uuid}|Finding Title]]

- **Original Sources**:
  - [[07-sources/data/source-{actual-uuid}|Source Title]]

- **Technical Audit**: Query batch {batch-name}, verified {timestamp} by fact-checker
```

## Complete Example

File: `${CLAIMS_DIR}/data/claim-green-bond-market-size-a3f5b2.md`

```markdown
---
tags: [finding, confidence/very-high, verification/verified]
title: "{Brief claim summary}"
dc:creator: "fact-checker"
dc:title: "Claim: Green bond issuance reached $500 billion in 2023"
dc:date: "2025-01-15T14:32:00Z"
dc:identifier: "claim-green-bond-market-size-a3f5b2"
dc:type: "claim"
dc:subject: ["green-bonds", "market-size", "2023"]
dc:description: "Green bonds issued $500 billion globally in 2023"
dc:relation: ["finding-green-bond-market-size-xyz789", "source-climate-bonds-initiative-abc", "econ-q1", "econ-q2", "economic-analysis"]
entity_type: "claim"
claim_text: "Green bonds issued $500 billion globally in 2023"
language: "en"
finding_refs: ["[[04-findings/data/finding-green-bond-market-size-xyz789]]"]
evidence_confidence: 0.74
source_quality_tier: 1
evidence_count: 1
cross_validation_score: 0.7
recency_score: 1.0
expertise_match_score: 1.0
claim_quality: 1.0
quality_dimensions:
  atomicity: 1.0
  fluency: 1.0
  decontextualization: 1.0
  faithfulness: 1.0
confidence_score: 0.84
quality_flags: []
quality_framework:
  dimensions_source: "Wright et al. (2022)"
  operationalization_source: "Agh et al. (2025)"
  arxiv: "https://arxiv.org/html/2502.04955v1"
is_critical: true
flagged_for_review: false
created_at: "2025-01-15T14:32:00Z"
provenance:
  query_batch: "query-batch-economic"
  verification_agent: "fact-checker"
  verification_timestamp: "2025-01-15T14:32:00Z"
---

## Claim

**Global Green Bond Issuance**

Green bonds issued $500 billion globally in 2023

## Relevance

This claim quantifies the global green bond market size for 2023, providing a critical baseline for understanding market growth and institutional adoption trends. The specific dollar figure enables comparison across time periods and validates market expansion hypotheses.

## Evidence

Supporting findings:
- [[finding-green-bond-market-size-xyz789]]

## Confidence Breakdown

- **Source Quality (35%)**: 1.0 (Tier 1 - Climate Bonds Initiative, authoritative industry organization)
- **Evidence Count (25%)**: 0.5 (Single finding)
- **Cross-Validation (20%)**: 0.7 (Single source, internally consistent)
- **Recency (10%)**: 1.0 (Published 2024, <1 year old)
- **Expertise Match (10%)**: 1.0 (Climate Bonds Initiative's core domain)

**Total Confidence**: 0.84

## Provenance (Audit Trail)

**Research Path**: Dimension → Question → Finding → Claim → Verification

- **Answers Questions**:
  - [[econ-q1|What is the global green bond market size?]]
  - [[econ-q2|What is the market growth trajectory?]]

- **Research Dimension**: [[economic-analysis|Economic Analysis]]

- **Thematic Topics**:
  - [[megatrend-market-growth-b7c9|Market Growth Trends]]

- **Supporting Findings** (1 total):
  - [[finding-green-bond-market-size-xyz789|Global green bond issuance in 2023]]

- **Original Sources**:
  - [[07-sources/data/source-climate-bonds-initiative-abc|Climate Bonds Initiative Annual Report 2024]]

- **Technical Audit**: Query batch query-batch-economic, verified 2025-01-15T14:32:00Z by fact-checker
```

## Validation Checklist

Before writing claim entity file, verify:

- [ ] Filename follows pattern: `claim-{semantic}-{hash}.md`
- [ ] All required YAML fields present
- [ ] Confidence scores are decimal (2 places: 0.82)
- [ ] Quality dimensions are 0.0 or 1.0 (binary) or 0.0-1.0 (continuous)
- [ ] quality_flags array populated if dimensions fail thresholds
- [ ] Provenance wikilinks use English slugs
- [ ] source_ids use empty array `[]` if no sources (NOT placeholder)
- [ ] All markdown sections present (Claim, Relevance, Evidence, Confidence Breakdown, Provenance)
- [ ] Wikilinks resolve correctly
- [ ] Research attribution included in frontmatter

## Usage in Workflow

1. Extract atomic claim from finding (Phase 2)
2. Calculate dual-layer scores (Phases 3-4)
3. Extract provenance wikilinks (Phase 5)
4. **Generate claim entity file (Phase 6)** ← Use this template
5. Write to `${PROJECT_PATH}/${CLAIMS_DIR}/data/` directory
6. Return claim metadata JSON to agent

## Notes

- Use ISO 8601 timestamps (UTC): `2025-01-15T14:32:00Z`
- Quality flags array is additive (include ALL failing dimensions)
- Empty arrays are valid (don't use placeholder wikilinks)
- Research attribution is mandatory (Wright et al. 2022, Agh et al. 2025)
