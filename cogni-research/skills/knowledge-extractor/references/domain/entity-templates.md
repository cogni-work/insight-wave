# Entity Templates

**Reference:** See [../../../../references/language-templates.md](../../../../references/language-templates.md) for complete language template definitions.

## Language-Aware Section Headers

Section headers MUST match the project `language` field. Use the appropriate header set:

### Domain Concepts (05-domain-concepts)

Domain concepts use IS/DOES/MEANS structure (same as generic megatrends).

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| What it is | What it is | Was es ist |
| What it does | What it does | Was es tut |
| What it means | What it means | Was es bedeutet |
| Qualitative Impact | Qualitative Impact | Qualitative Auswirkungen |
| Quantitative Indicators | Quantitative Indicators | Quantitative Indikatoren |
| Related Findings | Related Findings | Zugehörige Ergebnisse |

### Megatrends (06-megatrends)

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Trend | Trend | Trend |
| Implication | Implication | Implikation |
| Possibility | Possibility | Möglichkeit |
| Solution | Solution | Lösung |
| Immediate Actions | Immediate Actions | Sofortmaßnahmen |
| Strategic Initiatives | Strategic Initiatives | Strategische Initiativen |
| Preparation Phase | Preparation Phase | Vorbereitungsphase |
| Implementation Phase | Implementation Phase | Implementierungsphase |
| Scaling Phase | Scaling Phase | Skalierungsphase |
| Monitoring Activities | Monitoring Activities | Beobachtungsaktivitäten |
| Piloting Criteria | Piloting Criteria | Pilotierungskriterien |
| Option Securing | Option Securing | Optionssicherung |
| Evidence Base | Evidence Base | Evidenzbasis |
| Supporting Claims | Supporting Claims | Unterstützende Belege |
| Key Findings | Key Findings | Kernerkenntnisse |
| Related Entities | Related Entities | Verknüpfungen |
| Related Concepts | Related Concepts | Verwandte Konzepte |
| Related Megatrends | Related Megatrends | Verwandte Megatrends |
| Related Trends | Related Trends | Zugehörige Trends |
| Summary at a Glance | Summary at a Glance | Zusammenfassung auf einen Blick |
| What | What | Was |
| Why Important | Why Important | Warum wichtig |
| Action Horizon | Action Horizon | Handlungshorizont |
| Top Recommendation | Top Recommendation | Top-Empfehlung |
| Success Indicators | Success Indicators | Erfolgsindikatoren |
| Resources | Resources | Ressourcen |
| Dependencies | Dependencies | Abhängigkeiten |

### German Text Formatting

When `language: "de"`:

| Element | Format | Example |
|---------|--------|---------|
| Body text | Proper umlauts (ä, ö, ü, ß) | "Änderungen" NOT "Aenderungen" |
| Section headings | Proper umlauts | "Schlüsselmerkmale" NOT "Schluesselmerkmale" |
| File names/slugs | ASCII transliterations | ü→ue, ä→ae, ö→oe, ß→ss |
| YAML identifiers | ASCII only | dc:identifier, entity IDs |

---

## Concept Entity Template

Domain concepts use IS/DOES/MEANS structure for consistency with generic megatrends.

### YAML Frontmatter

```yaml
---
tags: [finding, concept-category/{category}, confidence/{level}]
entity_type: domain-concept
dc:creator: knowledge-extractor
dc:title: "Brief Concept Heading"
concept: "Concept Name (ABBREV)"
category: "Framework"
confidence: 0.95
finding_refs:
  - "[[${FINDINGS_DIR}/data/finding-{slug}-{hash}]]"
  - "[[${FINDINGS_DIR}/data/finding-{slug}-{hash}]]"
# ⛔ YAML CRITICAL: Ensure newline after last finding_refs entry
created_at: "2025-01-15T14:30:00Z"
language: "en"
---
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| tags | array | Yes | Obsidian tags for filtering |
| entity_type | string | Yes | Always `domain-concept` |
| dc:creator | string | Yes | Always `knowledge-extractor` |
| dc:title | string | Yes | 2-4 word heading for the concept |
| concept | string | Yes | Full name with abbreviation |
| category | string | Yes | Framework, Metric, Technique, Tool, Method, Standard |
| confidence | float | Yes | 0.90-0.99 range |
| finding_refs | array | Yes | Wikilinks to source findings containing this concept |
| created_at | ISO 8601 | Yes | UTC timestamp |
| language | string | Yes | ISO 639-1 code |

### Content Structure (400-600 words total)

```markdown
# {Concept Name}

## What it is

{150-200 words - Primer on the concept:
- Definition of what this concept encompasses
- Core terminology and scope
- Key characteristics synthesized from findings

Synthesize ONLY from member finding content. No external knowledge.}

## What it does

{100-150 words - Use Cases:
- Practical applications relevant to research stakeholders
- How this concept manifests in the research domain
- Key activities or processes involved
- Real-world examples derived from findings}

## What it means

{150-200 words - Implications:

**Qualitative Impact:**

[Narrative describing strategic significance, stakeholder effects,
and broader implications for the research context]

**Quantitative Indicators:**

| Metric | Value/Range | Source |
|--------|-------------|--------|
| {Metric 1} | {Value} | [[04-findings/data/finding-ref]] |
| {Metric 2} | {Value} | [[04-findings/data/finding-ref]] |

Note: Metrics extracted from member findings where available.
If no quantitative data available in findings, omit the table.}

## Related Findings

For complete finding references, see the `finding_refs` array in the YAML frontmatter above.

<!-- See finding_refs in frontmatter for complete list -->
```

### Word Count Requirements

| Section | Target | Content Source |
|---------|--------|----------------|
| What it is | 150-200 words | Synthesized from member findings |
| What it does | 100-150 words | Use cases from findings |
| What it means | 150-200 words | Implications + optional metrics table |
| **Total** | **400-600 words** | Member findings only |

### German Language Example

When `language: "de"`, use proper German umlauts in all content:

```markdown
# Agility Master

## Was es ist

Der Agility Master ist eine der drei verteilten Führungsrollen im agilen
Organisationsmodell. Diese Rolle ist Teil des Drei-Rollen-Modells, bei dem
die Führungsverantwortung im Team auf Product Owner, Agility Master und
Implementation Team verteilt ist. Die Rolle fokussiert auf Selbstführung
und partizipativ gestaltete agile Unternehmensführung.

## Was es tut

Der Agility Master unterstützt das Team bei der Selbstorganisation und
fördert die kontinuierliche Verbesserung der Arbeitsprozesse. Er moderiert
Retrospektiven, räumt Hindernisse aus dem Weg und schützt das Team vor
äußeren Störungen.

## Was es bedeutet

**Qualitative Auswirkungen:**

Die Einführung des Agility Masters ermöglicht eine stärkere
Eigenverantwortung der Teams und reduziert hierarchische Abhängigkeiten.

**Quantitative Indikatoren:**

| Kennzahl | Wert/Bereich | Quelle |
|----------|--------------|--------|
| Teams mit AM-Rolle | 500+ | [[04-findings/data/finding-ref]] |

## Zugehörige Ergebnisse

<!-- See finding_refs in frontmatter -->
```

**CRITICAL:** When `language: "de"`, body text and section headings MUST use proper German umlauts (ä, ö, ü, ß). Never use ASCII transliterations (ae, oe, ue, ss) in content. Only filenames/slugs use ASCII.

## Megatrend Entity Template (Enhanced)

Megatrends use TIPS-style strategic narrative (Trend-Implication-Possibility-Solution).

### YAML Frontmatter

```yaml
---
tags: [megatrend, {dimension-slug}, evidence/{evidence_strength}]
dc:creator: knowledge-extractor
dc:title: "{2-4 word heading}"
dc:identifier: "megatrend-{slug}-{hash}"
dc:created: "{ISO 8601 UTC}"
dc:type: megatrend
entity_type: megatrend
megatrend_name: "{Full Megatrend Name}"
megatrend_structure: "tips"  # ⛔ REQUIRED - "tips" for TIPS megatrend narrative
finding_count: {N}
finding_refs:
  # ⛔ Populate with ALL member finding wikilinks (one per line)
  - "[[04-findings/data/finding-{slug}-{hash}]]"
# ⛔ YAML CRITICAL: Ensure newline after last finding_refs entry
language: "{en|de}"

# Megatrend enrichment fields
source_type: "{clustered|seeded|hybrid}"
tier: 1  # Abstraction level: 1 = canonical megatrend (Tier 2 industry trends are not seeded)
seed_validated: {true|false}
seed_name: "{original seed name if applicable}"
evidence_strength: "{strong|moderate|weak|hypothesis}"
confidence_score: {0.0-1.0}
planning_horizon: "{act|plan|observe}"
dimension_affinity: "{dimension-slug}"
claim_refs:
  - "[[10-claims/data/claim-{slug}-{hash}]]"
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

# Content quality metrics (NEW)
citation_count: {N}  # Number of inline citations in content
content_metrics:
  total_word_count: {N}
  section_word_counts:
    trend: {N}
    implication: {N}
    possibility: {N}
    solution: {N}
    key_findings: {N}

# Top findings for Key Findings section (NEW)
key_findings_summary:
  - finding_ref: "[[04-findings/data/finding-{slug}-{hash}]]"
    title: "{Finding title/key insight}"
    quality_score: {0.0-1.0}
    summary: "{2-3 sentence summary connecting to megatrend thesis}"

# Cross-reference fields (NEW)
related_concepts:
  - "[[05-domain-concepts/data/concept-{slug}-{hash}]]"
related_trends:
  - "[[11-trends/data/trend-{slug}-{hash}]]"
related_megatrends:
  - "[[06-megatrends/data/megatrend-{slug}-{hash}]]"
---
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| tags | array | Yes | Includes `megatrend`, dimension, evidence level |
| dc:creator | string | Yes | Always `knowledge-extractor` |
| dc:title | string | Yes | 2-4 word heading |
| dc:identifier | string | Yes | Unique identifier `megatrend-{slug}-{hash}` |
| dc:created | string | Yes | ISO 8601 UTC timestamp |
| dc:type | string | Yes | Always `megatrend` |
| dc:subject | string | No | Topic subject (optional metadata) |
| entity_type | string | Yes | Always `megatrend` |
| megatrend_name | string | Yes | Full megatrend name |
| megatrend_structure | enum | **⛔ Yes** | `tips` or `generic` - determines content structure |
| finding_count | integer | Yes | Number of supporting findings |
| finding_refs | array | **⛔ Yes** | Wikilinks to member findings. **MUST be populated when finding_count > 0** |
| language | string | Yes | ISO 639-1 code (`en` or `de`) |
| source_type | enum | Yes | `clustered`, `seeded`, or `hybrid` |
| tier | integer | Yes | Abstraction level: 1 = canonical cross-industry megatrend |
| seed_validated | boolean | No | True if seed was validated by findings |
| seed_name | string | No | Original seed megatrend name (for seeded/hybrid) |
| evidence_strength | enum | Yes | `strong`, `moderate`, `weak`, `hypothesis` |
| confidence_score | float | Yes | 0.0-1.0 composite score |
| planning_horizon | enum | Yes | `act`, `plan`, or `observe` |
| dimension_affinity | string | No | Primary dimension slug |
| claim_refs | array | No | Wikilinks to supporting claims |
| strategic_narrative | object | Yes | TIPS narrative components |
| quality_scores | object | No | Quality assessment metrics |
| parent_megatrend_ref | string | No | Wikilink to parent megatrend (hierarchical) |
| submegatrend_refs | array | No | Wikilinks to child megatrends (hierarchical) |
| description | string | No | **Deprecated** - use strategic_narrative instead |
| citation_count | integer | No | Number of inline citations in megatrend content |
| content_metrics | object | No | Word count metrics for content quality verification |
| key_findings_summary | array | No | Top 3-5 findings with summaries for Key Findings section |
| related_concepts | array | No | Wikilinks to related domain concepts |
| related_trends | array | No | Wikilinks to related trends |
| related_megatrends | array | No | Wikilinks to related megatrends |

### Conditional Requirements

**⛔ Finding References Constraint:** When `finding_count > 0`, the `finding_refs` array MUST be populated with wikilinks to ALL member findings:

```yaml
# CORRECT: finding_refs matches finding_count
finding_count: 5
finding_refs:
  - "[[04-findings/data/finding-example-a1b2c3d4]]"
  - "[[04-findings/data/finding-example-e5f6g7h8]]"
  - "[[04-findings/data/finding-example-i9j0k1l2]]"
  - "[[04-findings/data/finding-example-m3n4o5p6]]"
  - "[[04-findings/data/finding-example-q7r8s9t0]]"

# INVALID: finding_count > 0 but finding_refs missing/empty
finding_count: 5
# finding_refs: []  <-- INVALID - megatrends without finding_refs are rejected
```

**Planning Horizon Constraint:** When `planning_horizon: "act"`, the `strategic_narrative.possibility` field MUST be an object with required properties:

| Horizon | Possibility Type | Required Properties |
| ------- | ---------------- | ------------------- |
| `act` | object | `overview`, `chance`, `risk` |
| `plan` | string OR object | `overview` (if object) |
| `observe` | string OR object | `overview` (if object) |

**Example for ACT horizon:**

```yaml
planning_horizon: "act"
strategic_narrative:
  possibility:
    overview: "Opportunity framing"
    chance: "Value of acting"      # REQUIRED for act
    risk: "Cost of not acting"     # REQUIRED for act
```

### Seed-to-Megatrend Field Mapping

When megatrends originate from seed megatrends (Phase 4b), fields map as follows:

| Seed Field | Megatrend Field | Notes |
| ---------- | ----------- | ----- |
| `name` | `seed_name` | Original seed name preserved |
| `planning_horizon_hint` | `planning_horizon` | May be refined during clustering |
| `validation_mode` | - | Affects clustering behavior, not stored |
| `keywords` | - | Used for matching, not stored in megatrend |
| - | `source_type` | Set to `seeded` (no findings) or `hybrid` (validated) |
| - | `seed_validated` | True if findings matched seed keywords |

**Source Type Decision:**

- `clustered`: Topic emerged from bottom-up finding clustering only
- `seeded`: Seed megatrend with no matching findings (hypothesis)
- `hybrid`: Seed megatrend validated by discovered findings

### Content Structure (600-900 words total)

```markdown
# {Megatrend Name}

> **Zusammenfassung auf einen Blick** / **Summary at a Glance**
>
> **Was/What:** {One sentence describing the megatrend}
> **Warum wichtig/Why Important:** {One sentence on strategic significance}
> **Handlungshorizont/Action Horizon:** 🔴 ACT (0-6 Monate) | 🟡 PLAN (6-18 Monate) | 🟢 OBSERVE (18+ Monate)
> **Evidenzstärke/Evidence Strength:** ████████░░ {strong|moderate|weak|hypothesis}
> **Top-Empfehlung/Top Recommendation:** {Single most important action}

## Trend

{150-200 words - Observable pattern description:
- What is happening (evidence-based from findings)
- Scale and velocity of change
- Key drivers and catalysts
- Geographic/industry scope

Include inline citations<sup>[[04-findings/data/finding-xyz|1]]</sup> connecting claims to findings.
Synthesize ONLY from member finding content. No external knowledge.}

## Implication

{150-200 words - Strategic significance:
- Impact on industry/organization
- Stakeholder effects (customers, employees, partners)
- Competitive dynamics
- Risk/opportunity landscape

Include inline citations connecting key claims to supporting findings.}

## Possibility

{100-150 words - Opportunity framing:
- **Chance:** Value gained by acting on this megatrend
- **Risk:** Cost of not acting on this megatrend

Note: Chance/Risk required for ACT horizon, optional for PLAN/OBSERVE.}

## Solution

{HORIZON-SPECIFIC STRUCTURE - Select based on planning_horizon:}

### ACT Horizon (0-6 months) Template:

### Immediate Actions (0-3 Months)
1. **{Action Name}**: {Description 25-30 words}
   - **Success Indicators:** {Measurable KPI}
   - **Resources:** {Effort/cost level}

### Strategic Initiatives (3-6 Months)
1. **{Action Name}**: {Description}
   - **Success Indicators:** {KPI}
   - **Dependencies:** {Prerequisites}

### PLAN Horizon (6-18 months) Template:

### Preparation Phase (Months 1-3)
{Capability building actions with clear deliverables}

### Implementation Phase (Months 4-12)
{Rollout actions with milestones}

### Scaling Phase (Months 13-18)
{Expansion actions with success criteria}

### OBSERVE Horizon (18+ months) Template:

### Monitoring Activities
{What to monitor, signals to watch for, key indicators}

### Piloting Criteria
{Conditions that would trigger move to PLAN horizon}

### Option Securing
{Actions to maintain flexibility and readiness}

## Evidence Base

**Evidenzstärke/Evidence Strength:** ████████░░ ({strong|moderate|weak|hypothesis} - {N}/10)

| Dimension | Score | Description |
|-----------|-------|-------------|
| Source Count | {0.0-1.0} | {N} independent sources |
| Recency | {0.0-1.0} | {X}% of sources < 12 months old |
| Consistency | {0.0-1.0} | {High|Medium|Low} agreement across sources |

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

2. **{Finding Title}** (Quality: {score}): {Summary}
   - Source: [[04-findings/data/finding-abc]]

3. **{Finding Title}** (Quality: {score}): {Summary}
   - Source: [[04-findings/data/finding-def]]

{Generate summaries for top 3-5 findings sorted by quality_score descending.
Each summary should be 2-3 sentences explaining how the finding supports this megatrend.}

## Related Entities

### Related Concepts
{List 2-5 relevant domain concepts with relationship descriptions:}
- [[05-domain-concepts/data/concept-xyz|Concept Name]] - {How this concept relates to the megatrend}

### Related Megatrends
{List 1-3 megatrends with synergy/tension relationships:}
- [[06-megatrends/data/megatrend-abc|Megatrend Name]] - {Synergy: complementary forces | Tension: competing forces}

### Related Trends
{List 2-4 trends that manifest this megatrend:}
- [[11-trends/data/trend-def|Trend Name]] - {How this trend operationalizes the megatrend}
```

### Word Count Requirements

| Section | Target | Content Source |
|---------|--------|----------------|
| Executive Summary | 50-75 words | Condensed from all sections |
| Trend | 150-200 words | Synthesized from member findings |
| Implication | 150-200 words | Strategic analysis of findings |
| Possibility | 100-150 words | Opportunity/risk framing |
| Solution | 100-150 words | Actionable recommendations (horizon-specific) |
| Evidence Base | 75-125 words | Metadata, strength visualization, claims |
| Key Findings | 100-200 words | Top 3-5 finding summaries |
| Related Entities | 50-100 words | Cross-references to concepts/trends |
| **Total** | **700-1100 words** | Member findings + claims + cross-refs |

### Word Count Verification Checklist

Before finalizing megatrend content, verify:

- [ ] Trend section ≥ 150 words
- [ ] Implication section ≥ 150 words
- [ ] Possibility section ≥ 100 words
- [ ] Solution section ≥ 100 words
- [ ] Key Findings section contains 3-5 finding summaries
- [ ] At least 3 inline citations in narrative sections
- [ ] Related Entities section populated (if entities exist)

### Source Type Classification

| Source Type | Description | Evidence Strength |
|-------------|-------------|-------------------|
| `clustered` | Emerged from bottom-up finding analysis | strong/moderate |
| `seeded` | Top-down from expert knowledge (no findings) | hypothesis |
| `hybrid` | Seed validated by discovered findings | strong/moderate/weak |

### Evidence Strength Classification

| Finding Count | Evidence Strength | Confidence Range |
|---------------|-------------------|------------------|
| 5+ findings | strong | 0.80-0.95 |
| 3-4 findings | moderate | 0.65-0.79 |
| 1-2 findings | weak | 0.40-0.64 |
| 0 findings (seed only) | hypothesis | 0.20-0.39 |

### Planning Horizon Classification

| Horizon | Timeframe | Indicators |
|---------|-----------|------------|
| **act** | 0-6 months | Published regulations, proven implementations, competitive pressure |
| **plan** | 6-18 months | Draft regulations, early adopter validation, 5-15% adoption |
| **observe** | 18+ months | Early debate, research/POC stage, experimentation |

---

## Generic Megatrend Entity Template

Megatrends for **generic research type** use a domain-based structure instead of TIPS. This structure focuses on explaining the megatrend itself rather than framing it as a strategic initiative.

**When to use:** `research_type = "generic"` (or any type except `smarter-service`)

### YAML Frontmatter

```yaml
---
tags: [megatrend, {dimension-slug}, evidence/{evidence_strength}]
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
  - "[[04-findings/data/finding-{slug}-{hash}]]"
# ⛔ YAML CRITICAL: Ensure newline after last finding_refs entry
language: "{en|de}"

# Generic megatrend fields (simplified from TIPS megatrend)
source_type: "clustered"
evidence_strength: "{strong|moderate|weak}"
confidence_score: {0.0-1.0}
dimension_affinity: "{dimension-slug}"
---
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| tags | array | Yes | Includes `megatrend`, dimension slug, evidence level |
| dc:creator | string | Yes | Always `knowledge-extractor` |
| dc:title | string | Yes | 2-4 word heading |
| dc:identifier | string | Yes | Unique identifier `megatrend-{slug}-{hash}` |
| dc:created | string | Yes | ISO 8601 UTC timestamp |
| dc:type | string | Yes | Always `megatrend` |
| entity_type | string | Yes | Always `megatrend` |
| megatrend_name | string | Yes | Full megatrend name |
| megatrend_structure | string | Yes | Always `generic` for this template |
| finding_count | integer | Yes | Number of supporting findings |
| finding_refs | array | **⛔ Yes** | Wikilinks to member findings. **MUST be populated when finding_count > 0** |
| language | string | Yes | ISO 639-1 code (`en` or `de`) |
| source_type | enum | Yes | Always `clustered` (generic megatrends emerge from findings) |
| evidence_strength | enum | Yes | `strong`, `moderate`, `weak` |
| confidence_score | float | Yes | 0.0-1.0 composite score |
| dimension_affinity | string | No | Primary dimension slug |

**Fields NOT used in generic megatrends (TIPS-specific):**

- `tier` - canonical megatrend tier
- `planning_horizon` - action timeline
- `seed_validated` - seed matching
- `seed_name` - original seed name
- `strategic_narrative` - TIPS YAML object
- `claim_refs` - claim linkages (optional, rarely used in generic)

### Content Structure (400-600 words total)

```markdown
# {Megatrend Name}

## What it is

{150-200 words - Primer on the subject:
- Definition of what this megatrend encompasses
- Core concepts and terminology
- Scope and boundaries within the research context
- Key characteristics synthesized from findings

Synthesize ONLY from member finding content. No external knowledge.}

## What it does

{100-150 words - Use Cases:
- Practical applications relevant to research stakeholders
- How this megatrend manifests in the research domain
- Key activities or processes involved
- Real-world examples derived from findings}

## What it means

{150-200 words - Implications:

**Qualitative Impact:**

[Narrative describing strategic significance, stakeholder effects,
and broader implications for the research context]

**Quantitative Indicators:**

| Metric | Value/Range | Source |
|--------|-------------|--------|
| {Metric 1} | {Value} | [[04-findings/data/finding-ref]] |
| {Metric 2} | {Value} | [[04-findings/data/finding-ref]] |
| {Metric 3} | {Value} | [[04-findings/data/finding-ref]] |

Note: Metrics extracted from member findings where available.
If no quantitative data available in findings, omit the table.}

## Related Findings

For complete finding references, see the `finding_refs` array in the YAML frontmatter above.

<!-- See finding_refs in frontmatter for complete list -->
```

### Word Count Requirements

| Section | Target | Content Source |
|---------|--------|----------------|
| What it is | 150-200 words | Synthesized from member findings |
| What it does | 100-150 words | Use cases from findings |
| What it means | 150-200 words | Implications + optional metrics table |
| **Total** | **400-600 words** | Member findings only |

### Language-Aware Section Headers

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| What it is | What it is | Was es ist |
| What it does | What it does | Was es tut |
| What it means | What it means | Was es bedeutet |
| Qualitative Impact | Qualitative Impact | Qualitative Auswirkungen |
| Quantitative Indicators | Quantitative Indicators | Quantitative Indikatoren |
| Related Findings | Related Findings | Zugehörige Ergebnisse |

### Metrics Table Guidelines

The **Quantitative Indicators** table captures measurable data from findings:

**Include when findings contain:**
- Numerical values (percentages, counts, monetary amounts)
- Time-based metrics (duration, frequency, deadlines)
- Scale indicators (adoption rates, market share, growth rates)

**Omit table when:**
- No quantitative data available in member findings
- Metrics would require external knowledge/estimation

**Format:**
- `Metric`: Descriptive name of what's measured
- `Value/Range`: Exact value or range from findings
- `Source`: Wikilink to the finding containing the data

### Research Type Routing

| Research Type | Topic Structure | Uses Seeds | Word Target |
|---------------|-----------------|------------|-------------|
| `smarter-service` | TIPS (megatrend) | Yes | 600-900 |
| `generic` | Generic | No | 400-600 |
| `b2b-ict-portfolio` | Generic | No | 400-600 |
| `customer-value-mapping` | Generic | No | 400-600 |
| `lean-canvas` | Generic | No | 400-600 |

---

## Confidence Scoring

### Megatrend Confidence Score (quality_scores.evidence_strength)

```text
confidence_score = min(1.0, 0.5 + (finding_count * 0.1) + (claim_count * 0.05))
```

**Examples:**

| Findings | Claims | Score | Classification |
| -------- | ------ | ----- | -------------- |
| 5 | 2 | 0.5 + 0.5 + 0.1 = **1.0** (capped) | strong |
| 3 | 1 | 0.5 + 0.3 + 0.05 = **0.85** | moderate |
| 1 | 0 | 0.5 + 0.1 + 0 = **0.60** | weak |
| 0 | 0 | 0.5 + 0 + 0 = **0.50** | hypothesis |

**Additional Quality Scores (LLM-assessed):**

- `strategic_relevance`: 0.0-1.0 based on research question alignment
- `actionability`: 0.0-1.0 based on solution specificity

### Concept Confidence Score (for domain-concepts)

```text
Base: 0.90

+ Finding count bonus: min(0.05, mentions/2 * 0.01)
  - 2 mentions: +0.01
  - 5 mentions: +0.025
  - 10+ mentions: +0.05 (capped)

+ Definition clarity: +0.02 if clear

+ Consistency: +0.03 if aligned across findings

Maximum: 0.99 (never claim certainty)
Threshold: Skip if < 0.90
```

## Filename Generation

```bash
# Concept: concept-{slug}-{hash}.md
slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | \
  sed 's/^-//' | sed 's/-$//' | cut -c1-50)
hash=$(echo -n "$name" | shasum -a 256 | cut -c1-8)

# Megatrend: megatrend-{slug}-{hash}.md
# Same pattern
```

## Confidence Tags

| Score | Tag |
|-------|-----|
| 0.95-0.99 | confidence/very-high |
| 0.90-0.94 | confidence/high |
| 0.85-0.89 | confidence/moderate (skip) |
| <0.85 | confidence/low (skip) |
