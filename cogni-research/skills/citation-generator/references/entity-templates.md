# Citation Entity Templates

**Reference:** See [../../../references/language-templates.md](../../../references/language-templates.md) for complete language template definitions.

## Language-Aware Section Headers

Section headers MUST match the project `language` field:

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Citation | Citation | Zitat |
| Components | Components | Komponenten |

### Language-Specific Date Formatting

| Language | Format | Example |
|----------|--------|---------|
| English | Retrieved {Month} {Day}, {Year} | Retrieved February 15, 2024 |
| German | Abgerufen am {Day}. {Month} {Year} | Abgerufen am 15. Februar 2024 |

---

## Purpose

This document defines the standard structure for citation entities in deeper-research projects. Citation entities connect sources to publishers through formal APA 7th edition citations with multi-strategy publisher resolution tracking.

## Filename Format

### Pattern

```
citation-{slug}-{hash}.md
```

### Slug Generation

Reuse slug from source entity ID to maintain semantic consistency:
- Source: `source-climate-ipcc-report-2024.md`
- Citation slug: `climate-ipcc-report-2024`

### Hash Generation

Generate 8-character hash from source URL for uniqueness:
```bash
CITATION_HASH=$(echo -n "$URL" | shasum -a 256 | cut -c1-8)
```

### Examples

```
citation-climate-ipcc-report-2024-a3f5b2c1.md
citation-bundesliga-digitalization-7e8d9a12.md
citation-covid-vaccine-efficacy-4b3c2a18.md
citation-machine-learning-survey-9f1e7d5b.md
citation-quantum-computing-review-2c8a6f4e.md
```

## Frontmatter Structure

### Obsidian Tags

Tags array for graph view filtering and entity classification:
```yaml
tags: [source, citation-format/apa, reliability/tier-1]
title: "{Citation text or ID}"
```

- `source`: Entity type identifier
- `citation-format/apa`: Citation format standard
- `reliability/tier-{N}`: Inherited from source entity (1-4)

### Dublin Core Metadata

FAIR Principles compliance fields:
```yaml
dc:creator: "citation-generator"
dc:title: "Citation: {citation_id}"
dc:date: "2024-01-15T10:30:00Z"
dc:identifier: "{citation_id}"
dc:type: "citation"
dc:source: "{url}"
dc:relation: ["{source_id}", "{publisher_id}"]
dc:format: "application/x-bibtex"
```

**Field Descriptions:**
- `dc:creator`: Agent that generated entity
- `dc:title`: Human-readable citation identifier
- `dc:date`: ISO 8601 creation timestamp (UTC)
- `dc:identifier`: Unique citation ID
- `dc:type`: Entity type (always "citation")
- `dc:source`: Original source URL
- `dc:relation`: Array of related entity IDs (source + publisher)
- `dc:format`: Citation format MIME type

### Legacy Fields

Maintained for backward compatibility with existing tooling:
```yaml
entity_type: "citation"
source_ref: "[[07-sources/data/{source_id}]]"
publisher_ref: "[[08-publishers/data/{publisher_id}]]"
citation_format: "APA"
match_strategy: "{strategy}"
created_at: "2024-01-15T10:30:00Z"
language: "en"
```

**Field Descriptions:**
- `entity_type`: Legacy entity classification
- `source_ref`: Wikilink to source entity (required)
- `publisher_ref`: Wikilink to publisher entity (required - both sources AND publishers are immediate upstreams)
- `citation_format`: Always "APA"
- `match_strategy`: Publisher resolution strategy used
- `created_at`: ISO 8601 timestamp
- `language`: Language code (en, de)

### Language Field

Supported values:
- `en`: English (default)
- `de`: German

Determines date formatting and citation text language:
- English: "Retrieved February 15, 2024"
- German: "Abgerufen am 15. Februar 2024"

### Match Strategy

Documents which publisher resolution strategy succeeded:

- `domain_exact`: Source domain matched publisher domain directly
- `name_exact`: Source publisher field matched publisher name
- `reverse_index`: Publisher entity links to this source
- `domain_fallback`: No publisher entity found (uses domain only)

### Complete Example

```yaml
---
# Obsidian Tags (for graph view filtering)
tags: [source, citation-format/apa, reliability/tier-1]
title: "{Citation text or ID}"

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "citation-generator"
dc:title: "Citation: citation-climate-ipcc-report-2024-a3f5b2c1"
dc:date: "2024-01-15T10:30:00Z"
dc:identifier: "citation-climate-ipcc-report-2024-a3f5b2c1"
dc:type: "citation"
dc:source: "https://www.ipcc.ch/report/ar6/wg1/"
dc:relation: ["source-climate-ipcc-report-2024", "ipcc-climate-science"]
dc:format: "application/x-bibtex"

# Legacy Fields (maintained for compatibility)
entity_type: "citation"
source_ref: "[[07-sources/data/source-climate-ipcc-report-2024]]"
publisher_ref: "[[08-publishers/data/publisher-ipcc-climate-science]]"
citation_format: "APA"
match_strategy: "domain_exact"
created_at: "2024-01-15T10:30:00Z"
language: "en"
---
```

## Content Sections

### ## Citation

Formatted APA 7th edition citation text with proper grammar and punctuation:

```markdown
## Citation

Intergovernmental Panel on Climate Change. (2024). Climate Change 2024: The Physical Science Basis.
Retrieved February 15, 2024, from https://www.ipcc.ch/report/ar6/wg1/
```

**Requirements:**
- APA 7th edition compliant
- No YAML artifacts (domain:, title:, url:)
- Proper date formatting for language
- DOI/PMID when available

### ### Components

Structured breakdown with wikilinks to related entities:

```markdown
### Components

- **Source**: [[07-sources/data/source-climate-ipcc-report-2024]]
- **Publisher**: [[08-publishers/data/publisher-ipcc-climate-science]]
- **Reliability**: Tier 1
- **Match Strategy**: domain_exact
```

**Field Descriptions:**
- **Source**: Wikilink to source entity (always present)
- **Publisher**: Wikilink to publisher entity (conditional)
- **Reliability**: Tier from source entity (1-4)
- **Match Strategy**: Resolution strategy used

### Conditional Sections

Publisher wikilink only included when publisher matched:

```markdown
# If publisher matched:
- **Publisher**: [[08-publishers/data/{publisher_id}]]

# If domain_fallback (no publisher):
# Publisher line omitted entirely
```

### Complete Example

```markdown
## Citation

Müller, T. (2024). Digitalisierung im deutschen Profifußball.
Deutscher Fußball-Bund. Abgerufen am 15. Januar 2024, von https://www.dfb.de/news/detail/digitalisierung

### Components

- **Source**: [[07-sources/data/source-bundesliga-digitalization]]
- **Publisher**: [[08-publishers/data/publisher-dfb-football]]
- **Reliability**: Tier 2
- **Match Strategy**: domain_exact
```

## Wikilink Patterns

### Source Links

Always use full path with directory prefix:
```markdown
[[07-sources/data/{source_id}]]
```

**Examples:**
```markdown
[[07-sources/data/source-climate-ipcc-report-2024]]
[[07-sources/data/source-bundesliga-digitalization]]
[[07-sources/data/source-covid-vaccine-efficacy]]
```

### Publisher Links

Conditional - only when publisher matched (not domain_fallback):
```markdown
[[08-publishers/data/{publisher_id}]]
```

**Examples:**
```markdown
[[08-publishers/data/publisher-ipcc-climate-science]]
[[08-publishers/data/publisher-dfb-football]]
[[08-publishers/data/publisher-nature-publishing]]
```

### Why Prefixes Matter

Directory prefixes enable:
- **Obsidian graph view filtering**: Filter by entity type
- **Namespace disambiguation**: Prevent ID conflicts across types
- **Clear entity relationships**: Explicit source/publisher/citation separation
- **Cross-directory linking**: Links work across project structure

## Validation Checklist

### APA Compliance

- ✅ Author/institution name first
- ✅ Year in parentheses after name
- ✅ Title in sentence case
- ✅ Publisher name (if institutional)
- ✅ Retrieved date + URL for web sources
- ✅ DOI/PMID when available
- ✅ Proper punctuation (periods, commas)

### YAML Artifact Prevention

Check citation text does NOT contain:
- ❌ "domain:"
- ❌ "title:"
- ❌ "url:"
- ❌ "Udomain:"
- ❌ Any other YAML field names

**Detection Method:**
```bash
if [ "$CITATION_TEXT" == *"domain:"* ]] || \
   [ "$CITATION_TEXT" == *"title:"* ]] || \
   [ "$CITATION_TEXT" == *"url:"* ]; then
  echo "ERROR: YAML artifacts detected"
fi
```

### Language Validation

**English Citations:**
- ✅ Contains "Retrieved {Month} {Day}, {Year}"
- ✅ Month spelled out (February, not Feb)
- ✅ American date format

**German Citations:**
- ✅ Contains "Abgerufen am {Day}. {Monat} {Jahr}"
- ✅ Month in German (Januar, Februar, etc.)
- ✅ German date format (15. Januar 2024)

### Entity Linking

- ✅ Source wikilink points to existing entity in 07-sources/data/
- ✅ Publisher wikilink points to existing entity in 08-publishers/data/ (if matched)
- ✅ Publisher wikilink omitted if match_strategy is domain_fallback
- ✅ Directory prefixes included (07-sources/data/, 08-publishers/data/)
- ✅ No fabricated entity links

### Match Strategy

- ✅ Match strategy logged in frontmatter
- ✅ Strategy value is one of: domain_exact, name_exact, reverse_index, domain_fallback
- ✅ Strategy matches actual resolution method used
- ✅ Components section shows same strategy

## Complete Entity Examples

### Example 1: English Citation with Publisher Match

**Filename:** `citation-climate-ipcc-report-2024-a3f5b2c1.md`

```markdown
---
# Obsidian Tags (for graph view filtering)
tags: [source, citation-format/apa, reliability/tier-1]
title: "{Citation text or ID}"

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "citation-generator"
dc:title: "Citation: citation-climate-ipcc-report-2024-a3f5b2c1"
dc:date: "2024-01-15T10:30:00Z"
dc:identifier: "citation-climate-ipcc-report-2024-a3f5b2c1"
dc:type: "citation"
dc:source: "https://www.ipcc.ch/report/ar6/wg1/"
dc:relation: ["source-climate-ipcc-report-2024", "ipcc-climate-science"]
dc:format: "application/x-bibtex"

# Legacy Fields (maintained for compatibility)
entity_type: "citation"
source_ref: "[[07-sources/data/source-climate-ipcc-report-2024]]"
publisher_ref: "[[08-publishers/data/publisher-ipcc-climate-science]]"
citation_format: "APA"
match_strategy: "domain_exact"
created_at: "2024-01-15T10:30:00Z"
language: "en"
---

## Citation

Intergovernmental Panel on Climate Change. (2024). Climate Change 2024: The Physical Science Basis.
Retrieved February 15, 2024, from https://www.ipcc.ch/report/ar6/wg1/

### Components

- **Source**: [[07-sources/data/source-climate-ipcc-report-2024]]
- **Publisher**: [[08-publishers/data/publisher-ipcc-climate-science]]
- **Reliability**: Tier 1
- **Match Strategy**: domain_exact
```

### Example 2: German Citation with Domain Fallback

**Filename:** `citation-bundesliga-blog-post-7e8d9a12.md`

```markdown
---
# Obsidian Tags (for graph view filtering)
tags: [source, citation-format/apa, reliability/tier-3]
title: "{Citation text or ID}"

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "citation-generator"
dc:title: "Citation: citation-bundesliga-blog-post-7e8d9a12"
dc:date: "2024-01-15T10:35:00Z"
dc:identifier: "citation-bundesliga-blog-post-7e8d9a12"
dc:type: "citation"
dc:source: "https://www.fussballblog.de/artikel/taktikanalyse"
dc:relation: ["source-bundesliga-blog-post"]
dc:format: "application/x-bibtex"

# Legacy Fields (maintained for compatibility)
entity_type: "citation"
source_ref: "[[07-sources/data/source-bundesliga-blog-post]]"
citation_format: "APA"
match_strategy: "domain_fallback"
created_at: "2024-01-15T10:35:00Z"
language: "de"
---

## Citation

Taktikanalyse: Gegenpressing im modernen Fußball. (2024).
fussballblog.de. Abgerufen am 15. Januar 2024, von https://www.fussballblog.de/artikel/taktikanalyse

### Components

- **Source**: [[07-sources/data/source-bundesliga-blog-post]]
- **Reliability**: Tier 3
- **Match Strategy**: domain_fallback
```

**Note:** No publisher wikilink included because match_strategy is domain_fallback.

### Example 3: Citation with DOI

**Filename:** `citation-covid-vaccine-efficacy-4b3c2a18.md`

```markdown
---
# Obsidian Tags (for graph view filtering)
tags: [source, citation-format/apa, reliability/tier-1]
title: "{Citation text or ID}"

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "citation-generator"
dc:title: "Citation: citation-covid-vaccine-efficacy-4b3c2a18"
dc:date: "2024-01-15T10:40:00Z"
dc:identifier: "citation-covid-vaccine-efficacy-4b3c2a18"
dc:type: "citation"
dc:source: "https://www.nature.com/articles/s41586-021-03777-9"
dc:relation: ["source-covid-vaccine-efficacy", "nature-publishing"]
dc:format: "application/x-bibtex"

# Legacy Fields (maintained for compatibility)
entity_type: "citation"
source_ref: "[[07-sources/data/source-covid-vaccine-efficacy]]"
publisher_ref: "[[08-publishers/data/publisher-nature-publishing]]"
citation_format: "APA"
match_strategy: "name_exact"
created_at: "2024-01-15T10:40:00Z"
language: "en"
---

## Citation

Polack, F. P., Thomas, S. J., Kitchin, N., et al. (2021). Safety and Efficacy of the BNT162b2 mRNA Covid-19 Vaccine.
Nature, 592(7854), 603-607. https://doi.org/10.1038/s41586-021-03777-9

### Components

- **Source**: [[07-sources/data/source-covid-vaccine-efficacy]]
- **Publisher**: [[08-publishers/data/publisher-nature-publishing]]
- **Reliability**: Tier 1
- **Match Strategy**: name_exact
```

**Note:** DOI included instead of "Retrieved" date for academic publications.

### Example 4: Citation with Reverse Index Match

**Filename:** `citation-machine-learning-survey-9f1e7d5b.md`

```markdown
---
# Obsidian Tags (for graph view filtering)
tags: [source, citation-format/apa, reliability/tier-2]
title: "{Citation text or ID}"

# Dublin Core Metadata (FAIR Principles Compliance)
dc:creator: "citation-generator"
dc:title: "Citation: citation-machine-learning-survey-9f1e7d5b"
dc:date: "2024-01-15T10:45:00Z"
dc:identifier: "citation-machine-learning-survey-9f1e7d5b"
dc:type: "citation"
dc:source: "https://arxiv.org/abs/2301.12345"
dc:relation: ["source-machine-learning-survey", "arxiv-preprints"]
dc:format: "application/x-bibtex"

# Legacy Fields (maintained for compatibility)
entity_type: "citation"
source_ref: "[[07-sources/data/source-machine-learning-survey]]"
publisher_ref: "[[08-publishers/data/publisher-arxiv-preprints]]"
citation_format: "APA"
match_strategy: "reverse_index"
created_at: "2024-01-15T10:45:00Z"
language: "en"
---

## Citation

Smith, J., & Jones, M. (2023). A Comprehensive Survey of Deep Learning Architectures.
arXiv. Retrieved January 15, 2024, from https://arxiv.org/abs/2301.12345

### Components

- **Source**: [[07-sources/data/source-machine-learning-survey]]
- **Publisher**: [[08-publishers/data/publisher-arxiv-preprints]]
- **Reliability**: Tier 2
- **Match Strategy**: reverse_index
```

**Note:** Publisher matched via reverse index (publisher entity links to this source).

## Common Errors

### YAML Artifacts in Citation Text

**Problem:** Citation text contains YAML field names instead of values.

**Bad Example:**
```
domain: nature.com. (2021). title: Safety and Efficacy. url: https://www.nature.com/...
```

**Good Example:**
```
Nature. (2021). Safety and Efficacy of the BNT162b2 mRNA Covid-19 Vaccine. https://doi.org/10.1038/...
```

**Detection:**
```bash
# Check for YAML artifacts
if [ "$CITATION_TEXT" == *"domain:"* ]; then
  echo "ERROR: YAML artifact detected"
fi
```

**Root Cause:** Using grep alone instead of grep+sed for YAML parsing.

**Fix:** Use proper extraction:
```bash
# Wrong
DOMAIN=$(grep "^domain:" "$file")

# Correct
DOMAIN=$(grep "^domain:" "$file" | sed 's/^domain:[[:space:]]*//' | sed 's/"//g')
```

### Missing Publisher Wikilink

**When to Include:**
- Match strategy: `domain_exact`
- Match strategy: `name_exact`
- Match strategy: `reverse_index`

**When to Omit:**
- Match strategy: `domain_fallback` (no publisher entity exists)

**Bad Example (domain_fallback with publisher link):**
```markdown
- **Publisher**: [[08-publishers/data/]]
```

**Good Example (domain_fallback without publisher link):**
```markdown
- **Source**: [[07-sources/data/source-blog-post]]
- **Reliability**: Tier 3
- **Match Strategy**: domain_fallback
```

### Incorrect Filename Format

**Common Mistakes:**

❌ `citation-climate-report.md` (missing hash)
❌ `climate-ipcc-report-2024-a3f5b2c1.md` (missing citation- prefix)
❌ `citation-climate-ipcc-report-2024.md` (missing hash)
❌ `source-climate-ipcc-report-2024-a3f5b2c1.md` (wrong prefix)

✅ `citation-climate-ipcc-report-2024-a3f5b2c1.md` (correct)

**Pattern:** `citation-{slug}-{hash}.md`
- `citation-` prefix (always)
- `{slug}` from source ID (reuse for consistency)
- `{hash}` 8-char from URL (for uniqueness)
- `.md` extension
