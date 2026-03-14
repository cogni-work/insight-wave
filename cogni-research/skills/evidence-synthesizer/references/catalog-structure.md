# Catalog Structure Patterns

## Overview

The evidence catalog organizes sources, citations, and institutions into a navigable structure with tier distribution analysis, domain groupings, and complete bibliographic references. Structure follows McKinsey Pyramid Principle: summary first, supporting details below.

## Complete Catalog Structure

### 1. YAML Frontmatter

```yaml
---
schema_version: "3.0"
entity_type: evidence-synthesis
tags: [evidence-synthesis, synthesis-level/evidence, {{LANGUAGE}}]
dc:creator: Claude (evidence-synthesizer)
dc:title: "Evidence Catalog: Sources and Citations"
dc:created: {{ISO-8601_TIMESTAMP}}
dc:identifier: synthesis-evidence
title: "Evidence Base: Sources and Citations"
source_count: {{total_sources_loaded}}
citation_count: {{total_citations_loaded}}
institution_count: {{total_institutions_loaded}}
tier1_count: {{tier1_sources}}
tier2_count: {{tier2_sources}}
tier3_count: {{tier3_sources}}
research_type: "{{research_type}}"
language: "{{language_code}}"
word_count: {{count}}
---
```

**Field Descriptions:**

- `schema_version`: Always "3.0" for current schema
- `entity_type`: Always "evidence-synthesis" for evidence catalog documents
- `tags`: Standard format `[evidence-synthesis, synthesis-level/evidence, {language}]`
- `dc:creator`: Dublin Core creator (always "Claude (evidence-synthesizer)")
- `dc:title`: Dublin Core title for provenance
- `dc:created`: Dublin Core timestamp in ISO-8601 format (UTC)
- `dc:identifier`: Dublin Core identifier (always "synthesis-evidence")
- `title`: Human-readable document title
- `*_count`: Integer counts for sources, citations, institutions, tiers
- `research_type`: From metadata or "generic"
- `language`: Two-letter ISO 639-1 code (de/en)
- `word_count`: Total word count of document body

**Required Fields:**
- All counts must be integers
- Timestamp in ISO-8601 format (UTC)
- Tags must include evidence-synthesis and synthesis-level/evidence
- research_type from metadata or "generic"

### 2. Executive Summary Section

```markdown
# Evidence Base: Sources and Citations

## Summary

This catalog organizes {source_count} sources, {citation_count} citations, and {institution_count} institutions supporting the research synthesis. Sources are classified by reliability tier and grouped by domain for navigable exploration.

**Tier Distribution:**
- Tier 1 (Academic): {tier1_pct}% ({tier1_count} sources)
- Tier 2 (Industry/Government): {tier2_pct}% ({tier2_count} sources)
- Tier 3 (Professional): {tier3_pct}% ({tier3_count} sources)

**Authority Coverage:** {academic_count} academic, {multilateral_count} multilateral, {government_count} government, {industry_count} industry institutions
```

### 3. Source Reliability Distribution Table

```markdown
## Source Reliability Distribution

| Tier | Description | Count | Percentage |
|------|-------------|-------|------------|
| Tier 1 | Academic, peer-reviewed | {tier1_count} | {tier1_pct}% |
| Tier 2 | Industry reports, government | {tier2_count} | {tier2_pct}% |
| Tier 3 | Trade publications, professional | {tier3_count} | {tier3_pct}% |
| **Total** | | **{total}** | **100%** |
```

### 4. Sources by Domain Section

Group sources by their domain/organization. Each domain section:

```markdown
## Sources by Domain

### {domain_name} ({organization_name})

**Reliability:** Tier {tier} ({tier_description})
**Citations:** {citation_count} referenced
**Institution:** [[12-institutions/{institution-entity-id}]]

1. [[07-sources/data/{source-entity-id-1}]]
   - **Title:** {title_from_frontmatter}
   - **URL:** {url_from_frontmatter}
   - **Access Date:** {access_date_from_frontmatter}

2. [[07-sources/data/{source-entity-id-2}]]
   - **Title:** {title_from_frontmatter}
   - **URL:** {url_from_frontmatter}
   - **Access Date:** {access_date_from_frontmatter}

---
```

**Domain Extraction:**

```bash
# Extract domain from URL
domain=$(echo "$url" | sed 's|https\?://||' | sed 's|www\.||' | cut -d'/' -f1)
```

**Organization Name Mapping:**
1. If institution entity exists for domain → Use institution name
2. Otherwise → Use domain name as organization
3. Clean domain (remove TLD for display if needed)

### 5. Institutional Authority Section

```markdown
## Institutional Authority

### Academic Institutions ({count} institutions)

{institution_name_1}, {institution_name_2}, {institution_name_3}...

**Contribution:** Foundational research methodology and peer-reviewed evidence

### Multilateral Organizations ({count} institutions)

{institution_name_1}, {institution_name_2}...

**Contribution:** Global policy perspective and cross-border data

### Government Agencies ({count} institutions)

{institution_name_1}, {institution_name_2}...

**Contribution:** Regulatory compliance and official statistics

### Industry Associations ({count} institutions)

{institution_name_1}, {institution_name_2}...

**Contribution:** Practitioner expertise and market standards
```

### 6. Complete Source Catalog

Alphabetical listing with wikilinks for navigation:

```markdown
## Complete Source Catalog

| Source ID | Title | Organization | Tier |
|-----------|-------|--------------|------|
| [[07-sources/data/{source-id-1}]] | {title} | {org} | {tier} |
| [[07-sources/data/{source-id-2}]] | {title} | {org} | {tier} |
| [[07-sources/data/{source-id-3}]] | {title} | {org} | {tier} |
```

**Sorting:** Alphabetical by source entity ID (consistent ordering)

### 7. Bibliography (APA Citation Index)

```markdown
## Bibliography

1. {Full APA citation verbatim from entity}
   → [[09-citations/data/{citation-entity-id}]]

2. {Full APA citation verbatim from entity}
   → [[09-citations/data/{citation-entity-id}]]

3. {Full APA citation verbatim from entity}
   → [[09-citations/data/{citation-entity-id}]]
```

**Multi-Language Headers:**
- English: "## Bibliography"
- German: "## Literaturverzeichnis"

**Sorting Requirements:**
- Alphabetical by author sort key (case-insensitive)
- Numbered entries (1, 2, 3...)
- One citation per numbered entry

**Author Extraction Pattern:**

```bash
# Extract author from citation entity frontmatter
author=$(echo "$content" | grep "^author:" | sed 's/author: *//' | tr -d '"')

# Extract sort key (first author's last name)
author_sort_key=$(echo "$author" | cut -d',' -f1 | tr '[:upper:]' '[:lower:]')

# Fallback: Use publisher/domain if author field is empty
if [ -z "$author_sort_key" ]; then
    # Try publisher field
    publisher=$(echo "$content" | grep "^publisher:" | sed 's/publisher: *//' | tr -d '"')
    author_sort_key=$(echo "$publisher" | tr '[:upper:]' '[:lower:]')

    # Ultimate fallback: extract domain from URL
    if [ -z "$author_sort_key" ]; then
        url=$(echo "$content" | grep "^url:" | sed 's/url: *//' | tr -d '"')
        domain=$(echo "$url" | sed 's|https\?://||' | sed 's|www\.||' | cut -d'/' -f1)
        author_sort_key=$(echo "$domain" | tr '[:upper:]' '[:lower:]')
    fi
fi
```

**Citation Extraction Pattern:**

```bash
# Method 1: Extract from ## Citation section (preferred)
apa_citation=$(echo "$content" | grep -A2 "^## Citation$" | tail -1 | sed 's/^ *//')

# Method 2: Extract from frontmatter (fallback)
if [ -z "$apa_citation" ]; then
    apa_citation=$(echo "$content" | grep "^apa_citation:" | sed 's/apa_citation: *//' | tr -d '"')
fi
```

**Bibliography Entry Assembly:**

```bash
# Build numbered bibliography entry
entry_number=1
for citation_id in "${sorted_citation_ids[@]}"; do
    # Load citation entity
    citation_file="${PROJECT_PATH}/09-citations/data/${citation_id}.md"
    content=$(cat "$citation_file")

    # Extract APA citation verbatim
    apa_citation=$(echo "$content" | grep -A2 "^## Citation$" | tail -1 | sed 's/^ *//')

    # Append to bibliography
    echo "${entry_number}. ${apa_citation}" >> "$output_file"
    echo "   → [[09-citations/data/${citation_id}]]" >> "$output_file"
    echo "" >> "$output_file"

    ((entry_number++))
done
```

**Anti-Hallucination Requirements:**
- VERBATIM COPY: All citation text must be copied exactly from citation entity content
- NO INFERENCE: Do not infer or correct citation formatting
- NO FABRICATION: Only output citations that exist as loaded entities
- EXACT MATCH: Citation text in bibliography must match citation entity content byte-for-byte

**Example Output:**

```markdown
## Bibliography

1. Acatech. (2024). *Industrie 4.0 Umsetzungsstrategie*. Deutsche Akademie der Technikwissenschaften. https://acatech.de/publikation/industrie-4-0
   → [[09-citations/data/citation-source-acatech-abc123]]

2. Anthropic. (2024). *Claude Model Card and Evaluations*. Anthropic. https://anthropic.com/claude
   → [[09-citations/data/citation-source-anthropic-def456]]

3. Bitkom e.V. (2025). *Digitalisierung der deutschen Industrie*. Bitkom. https://bitkom.org/studie/digitalisierung
   → [[09-citations/data/citation-source-bitkom-ghi789]]

4. Smith, J., & Johnson, M. (2024). *Machine learning approaches to industrial automation*. Journal of Manufacturing Systems, 45(2), 123-145. https://doi.org/10.1016/j.jmsy.2024.01.001
   → [[09-citations/data/citation-journal-smith-johnson-2024-xyz789]]
```

**German Example:**

```markdown
## Literaturverzeichnis

1. Acatech. (2024). *Industrie 4.0 Umsetzungsstrategie*. Deutsche Akademie der Technikwissenschaften. https://acatech.de/publikation/industrie-4-0
   → [[09-citations/data/citation-source-acatech-abc123]]

2. Bitkom e.V. (2025). *Digitalisierung der deutschen Industrie*. Bitkom. https://bitkom.org/studie/digitalisierung
   → [[09-citations/data/citation-source-bitkom-ghi789]]
```

## Wikilink Conventions

### Standard Format

- Sources: `[[07-sources/data/{source-entity-id}]]`
- Citations: `[[09-citations/data/{citation-entity-id}]]`
- Institutions: `[[12-institutions/{institution-entity-id}]]`

**Always include directory prefix** for Obsidian navigation.

### Building Wikilink Arrays

```bash
# Build wikilink string for YAML frontmatter
wikilinks=""
for id in "${entity_ids[@]}"; do
    if [ -n "$wikilinks" ]; then
        wikilinks="${wikilinks}, "
    fi
    wikilinks="${wikilinks}\"[[07-sources/data/${id}]]\""
done
# Result: "[[07-sources/data/id1]]", "[[07-sources/data/id2]]"
```

## Template-Specific Variations

### For action-oriented-radar Research Type

Add horizon-based source grouping:

```markdown
## Sources by Action Horizon

### Act (0-2 years) Sources
{sources with immediate applicability}

### Plan (2-5 years) Sources
{sources for medium-term planning}

### Observe (5+ years) Sources
{sources for long-term monitoring}
```

### For trend-radar Research Type

Add lifecycle stage grouping:

```markdown
## Sources by Technology Lifecycle

### Innovation Trigger Sources
### Peak of Inflated Expectations Sources
### Trough of Disillusionment Sources
### Slope of Enlightenment Sources
### Plateau of Productivity Sources
```

### For Generic Research Type

Use standard tier-based organization (default structure above).

## Anti-Hallucination Requirements

**Every catalog entry must trace to loaded entity:**

- Source titles → Extracted from source entity frontmatter
- URLs → Copied verbatim from source entity
- Institution names → Extracted from institution entity name field
- Citations → Copied from citation entity content
- Wikilinks → Reference actual entity file IDs

**Verification Checklist:**
- [ ] All source titles match loaded entity data
- [ ] All URLs are verbatim (no corrections/assumptions)
- [ ] All institution names from actual entities
- [ ] All citations copied exactly
- [ ] All wikilinks reference existing entity files

## Output File Location

```bash
OUTPUT_FILE="${PROJECT_PATH}/09-citations/README.md"
mkdir -p "${PROJECT_PATH}/09-citations"
```

**File naming:** Always `09-citations/README.md` (evidence catalog serves as the citations directory README)

## Example: Assembled Catalog Section

```markdown
### climatebonds.net (Climate Bonds Initiative)

**Reliability:** Tier 2 (Industry report)
**Citations:** 3 referenced
**Institution:** [[12-institutions/institution-climate-bonds-initiative-abc123]]

1. [[07-sources/data/source-cbi-2024-report-def456]]
   - **Title:** Global Green Bond Market Report 2024
   - **URL:** https://climatebonds.net/reports/2024
   - **Access Date:** 2025-01-15

2. [[07-sources/data/source-cbi-taxonomy-ghi789]]
   - **Title:** Climate Bonds Taxonomy
   - **URL:** https://climatebonds.net/standard/taxonomy
   - **Access Date:** 2025-01-14

---
```
