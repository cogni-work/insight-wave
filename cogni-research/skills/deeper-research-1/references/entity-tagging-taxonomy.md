# Entity Tagging Taxonomy v2.0

## Overview

This document defines the simplified Obsidian tag taxonomy for all entities in the deeper-research knowledge pipeline. Tags enable intuitive filtering in Obsidian's graph view by mapping entities to their **use-case role** in the research workflow.

**Version 2.0 Changes:**
- **Simplified primary tags**: 4 use-case tags (`question`, `finding`, `source`, `answer`) replace 12 nested entity types
- **Flatter hierarchy**: Removed `entity/` prefix for cleaner graph queries
- **Preserved refinement**: Useful secondary tags retained for sub-filtering
- **Breaking change**: Existing projects require tag migration (see Migration section)

## Design Philosophy

### Use-Case Driven Architecture

Each entity is tagged based on its **role in the research workflow**, not its technical type:

| Primary Tag | Research Role | Entity Types Included |
|-------------|---------------|----------------------|
| **`question`** | Formulating research questions | Initial Question, Dimension, Refined Question, Query Batch |
| **`finding`** | Evidence supporting answers | Finding, Megatrend, Domain Concept, Claim |
| **`source`** | Provenance and attribution | Source, Publisher, Citation |
| **`answer`** | Synthesized research output | Synthesis (all levels) |

### Tag Principles

1. **One Primary Tag Per Entity**: Each entity has exactly ONE primary tag for clean filtering
2. **Additive Secondary Tags**: Multiple secondary tags provide refinement filtering
3. **Flat Hierarchy**: Simple tags (`finding`) instead of nested (`entity/finding`)
4. **Obsidian Native**: YAML list format compatible with graph view and Dataview

## Tag Syntax

**Format**: YAML list in frontmatter without hashtags
```yaml
tags: [primary-tag, secondary-tag-1, secondary-tag-2]
```

**Obsidian Compatibility**:
- Tags in frontmatter work with graph view filtering: `tag:#finding`
- Tags can be queried using Dataview plugin: `FROM #finding`
- Secondary tags refine filtering: `tag:#finding AND tag:#confidence/high`

## Primary Tags

### `question` - Research Questions

**Purpose**: Entities that formulate, decompose, or refine research questions.

**Applies To**:
- **Initial Question** (`00-initial-question/`) - Root research question
- **Dimension** (`01-research-dimensions/data/`) - MECE dimensional decomposition
- **Refined Question** (`02-refined-questions/data/`) - PICOT-structured sub-questions
- **Query Batch** (`03-query-batches/data/`) - Executable search queries

**Example Tag Combinations**:
```yaml
# Initial question
tags: [question]

# Dimension with type
tags: [question, dimension-type/technical]

# Refined question with priority
tags: [question, dimension-type/economic, priority/high]

# Query batch
tags: [question, dimension-type/regulatory]
```

**Graph Filtering**:
```
tag:#question
```

### `finding` - Evidence & Trends

**Purpose**: Entities that provide evidence, trends, or verified claims supporting research answers.

**Applies To**:
- **Finding** (`04-findings/data/`) - Research evidence from sources
- **Megatrend** (`06-megatrends/data/`) - Megatrend clusters organizing findings
- **Domain Concept** (`05-domain-concepts/data/`) - Key terminology and frameworks
- **Claim** (`10-claims/data/`) - Verified factual assertions

**Example Tag Combinations**:
```yaml
# Finding from academic source
tags: [finding, source-type/academic]

# Topic cluster with high relevance
tags: [finding, relevance/high]

# Domain concept
tags: [finding, concept-category/framework, confidence/very-high]

# Verified claim
tags: [finding, confidence/high, verification/verified]

# Finding with no results
tags: [finding, no-results]
```

**Graph Filtering**:
```
tag:#finding
tag:#finding AND tag:#source-type/academic
tag:#finding AND tag:#confidence/high
```

### `source` - Provenance & Attribution

**Purpose**: Entities that document where information comes from and who published it.

**Applies To**:
- **Source** (`07-sources/data/`) - Source documents (URLs, titles, metadata)
- **Publisher** (`08-publishers/data/`) - Authors (individuals) and organizations
- **Citation** (`09-citations/data/`) - APA-formatted citations with provenance

**Example Tag Combinations**:
```yaml
# Source document
tags: [source, source-type/academic]

# Individual author
tags: [source, publisher-type/individual]

# Organization publisher
tags: [source, publisher-type/organization, organization-type/research-institution]

# Citation with reliability tier
tags: [source, citation-format/apa, reliability/tier-1]
```

**Graph Filtering**:
```
tag:#source
tag:#source AND tag:#publisher-type/individual
tag:#source AND tag:#reliability/tier-1
```

### `answer` - Synthesized Output

**Purpose**: Entities that synthesize research findings into coherent answers and narratives.

**Applies To**:
- **Citations** (`09-citations/`) - Evidence catalog:
  - `README.md` - Complete evidence catalog (sources, citations, bibliography)
- **Research Report** (project root):
  - `research-hub.md` - Comprehensive synthesis with executive summary, dimensional analysis, and findings

**Example Tag Combinations**:
```yaml
# Executive summary
tags: [answer, synthesis-level/executive]

# Dimensional analysis
tags: [answer, synthesis-level/dimensions]

# Detailed findings
tags: [answer, synthesis-level/findings]

# Evidence catalog
tags: [answer, synthesis-level/evidence]

# Navigation guide
tags: [answer, synthesis-level/readme]
```

**Graph Filtering**:
```
tag:#answer
tag:#answer AND tag:#synthesis-level/executive
```

## Secondary Tags

Secondary tags provide refinement filtering within primary tag categories. Entities can have multiple secondary tags.

### Dimension & Question Type Tags

**Purpose**: Classify questions by research dimension type.

**Values**:
- `dimension-type/technical`
- `dimension-type/economic`
- `dimension-type/social`
- `dimension-type/competitive`
- `dimension-type/historical`
- `dimension-type/regulatory`
- `dimension-type/operational`
- `dimension-type/strategic`

**Applies To**: `question` entities (Dimensions, Refined Questions, Query Batches)

**Example**:
```yaml
tags: [question, dimension-type/technical, priority/high]
```

### Source Type Tags

**Purpose**: Classify findings and sources by publication type.

**Values**:
- `source-type/academic` - Peer-reviewed journals, conferences
- `source-type/industry` - Whitepapers, technical reports
- `source-type/news` - News articles, press releases
- `source-type/technical` - Documentation, technical blogs
- `source-type/professional` - Expert opinions, professional publications

**Applies To**: `finding` entities (Findings), `source` entities (Sources)

**Example**:
```yaml
tags: [finding, source-type/academic]
tags: [source, source-type/industry]
```

### Confidence Level Tags

**Purpose**: Indicate confidence or certainty in findings, concepts, and claims.

**Values**:
- `confidence/very-high` - Confidence ≥ 0.95 (concepts), ≥ 0.85 (claims)
- `confidence/high` - Confidence 0.90-0.94 (concepts), 0.75-0.84 (claims)
- `confidence/moderate` - Confidence 0.80-0.89 (concepts), 0.60-0.74 (claims)
- `confidence/low` - Confidence < 0.80 (concepts), < 0.60 (claims, rejected)

**Applies To**: `finding` entities (Domain Concepts, Claims)

**Example**:
```yaml
tags: [finding, concept-category/methodology, confidence/very-high]
tags: [finding, confidence/high, verification/verified]
```

### Priority Level Tags

**Purpose**: Indicate research priority for questions.

**Values**:
- `priority/high`
- `priority/medium`
- `priority/low`

**Applies To**: `question` entities (Refined Questions)

**Example**:
```yaml
tags: [question, dimension-type/competitive, priority/high]
```

### Relevance Level Tags

**Purpose**: Indicate megatrend cluster relevance to research question.

**Values**:
- `relevance/high` - Relevance score ≥ 0.80
- `relevance/medium` - Relevance score 0.60-0.79
- `relevance/low` - Relevance score < 0.60

**Applies To**: `finding` entities (Megatrends)

**Example**:
```yaml
tags: [finding, relevance/high]
```

### Concept Category Tags

**Purpose**: Classify domain concepts by type.

**Values**:
- `concept-category/framework`
- `concept-category/methodology`
- `concept-category/technique`
- `concept-category/metric`
- `concept-category/architecture`
- `concept-category/theory`

**Applies To**: `finding` entities (Domain Concepts)

**Example**:
```yaml
tags: [finding, concept-category/framework, confidence/very-high]
```

### Reliability Tier Tags

**Purpose**: Indicate source reliability and quality.

**Values**:
- `reliability/tier-1` - Academic (peer-reviewed journals, conferences)
- `reliability/tier-2` - Industry (whitepapers, technical reports)
- `reliability/tier-3` - Professional (established publishers, experts)
- `reliability/tier-4` - Community (documentation, blog posts)
- `reliability/tier-5` - Unverified (social media, forums)

**Applies To**: `source` entities (Sources, Citations)

**Example**:
```yaml
tags: [source, source-type/academic, reliability/tier-1]
tags: [source, citation-format/apa, reliability/tier-2]
```

### Publisher Type Tags

**Purpose**: Discriminate between individual authors and organizational publishers.

**Values**:
- `publisher-type/individual` - Individual authors, researchers
- `publisher-type/organization` - Institutions, companies, organizations

**Applies To**: `source` entities (Publishers)

**Example**:
```yaml
tags: [source, publisher-type/individual]
tags: [source, publisher-type/organization, organization-type/research-institution]
```

### Organization Type Tags

**Purpose**: Classify organizational publishers by category.

**Values**: Domain-specific (e.g., `organization-type/research-institution`, `organization-type/tech-company`)

**Applies To**: `source` entities (Publishers with `publisher-type/organization`)

**Example**:
```yaml
tags: [source, publisher-type/organization, organization-type/university]
```

### Verification Status Tags

**Purpose**: Indicate claim verification status.

**Values**:
- `verification/verified` - Successfully verified with confidence ≥ 0.60
- `verification/pending` - Under verification
- `verification/rejected` - Confidence < 0.60

**Applies To**: `finding` entities (Claims)

**Example**:
```yaml
tags: [finding, confidence/high, verification/verified]
```

### Synthesis Level Tags

**Purpose**: Indicate synthesis document type and depth.

**Values**:
- `synthesis-level/readme` - Navigation and overview
- `synthesis-level/executive` - Executive summary
- `synthesis-level/dimensions` - Dimensional analysis
- `synthesis-level/findings` - Detailed findings
- `synthesis-level/evidence` - Complete evidence catalog

**Applies To**: `answer` entities (Synthesis)

**Example**:
```yaml
tags: [answer, synthesis-level/executive]
```

### Citation Format Tags

**Purpose**: Indicate citation style.

**Values**:
- `citation-format/apa` - APA style (default)
- `citation-format/mla` - MLA style
- `citation-format/chicago` - Chicago style
- `citation-format/ieee` - IEEE style

**Applies To**: `source` entities (Citations)

**Example**:
```yaml
tags: [source, citation-format/apa, reliability/tier-1]
```

### Special Tags

#### `no-results`
**Purpose**: Flag findings from searches with no results.

**Applies To**: `finding` entities (Findings)

**Example**:
```yaml
tags: [finding, no-results]
```

## Entity Type Reference

Complete mapping of entity types to tag combinations:

| Entity Type | Directory | Primary Tag | Common Secondary Tags | Example |
|-------------|-----------|-------------|----------------------|---------|
| Initial Question | `00-initial-question/` | `question` | (none) | `[question]` |
| Dimension | `01-research-dimensions/data/` | `question` | `dimension-type/{type}` | `[question, dimension-type/technical]` |
| Refined Question | `02-refined-questions/data/` | `question` | `dimension-type/{type}`, `priority/{level}` | `[question, dimension-type/economic, priority/high]` |
| Query Batch | `03-query-batches/data/` | `question` | `dimension-type/{type}` | `[question, dimension-type/regulatory]` |
| Finding | `04-findings/data/` | `finding` | `source-type/{type}` | `[finding, source-type/academic]` |
| Megatrend | `06-megatrends/data/` | `megatrend` | `megatrend-type/{type}` | `[megatrend, megatrend-type/technology]` |
| Domain Concept | `05-domain-concepts/data/` | `finding` | `concept-category/{type}`, `confidence/{level}` | `[finding, concept-category/framework, confidence/very-high]` |
| Source | `07-sources/data/` | `source` | `source-type/{type}` | `[source, source-type/academic]` |
| Publisher (Individual) | `08-publishers/data/` | `source` | `publisher-type/individual` | `[source, publisher-type/individual]` |
| Publisher (Organization) | `08-publishers/data/` | `source` | `publisher-type/organization`, `organization-type/{type}` | `[source, publisher-type/organization, organization-type/university]` |
| Citation | `09-citations/data/` | `source` | `citation-format/apa`, `reliability/tier-{N}` | `[source, citation-format/apa, reliability/tier-1]` |
| Claim | `10-claims/data/` | `finding` | `confidence/{level}`, `verification/{status}` | `[finding, confidence/high, verification/verified]` |
| Research Report | `research-hub.md` | `answer` | `synthesis-level/report` | `[answer, synthesis-level/report]` |

## Graph View Filtering

### Basic Filtering

**Show all questions:**
```
tag:#question
```

**Show all findings (evidence):**
```
tag:#finding
```

**Show all sources (provenance):**
```
tag:#source
```

**Show all answers (synthesis):**
```
tag:#answer
```

### Refined Filtering

**High-priority technical questions:**
```
tag:#question AND tag:#dimension-type/technical AND tag:#priority/high
```

**Academic findings with high confidence:**
```
tag:#finding AND tag:#source-type/academic AND tag:#confidence/high
```

**Tier-1 sources only:**
```
tag:#source AND tag:#reliability/tier-1
```

**Executive-level synthesis:**
```
tag:#answer AND tag:#synthesis-level/executive
```

**Verified claims:**
```
tag:#finding AND tag:#verification/verified
```

### Combined Filtering

**All evidence for technical dimension:**
```
tag:#finding AND tag:#dimension-type/technical
```

**High-quality provenance chain:**
```
tag:#source AND (tag:#reliability/tier-1 OR tag:#reliability/tier-2)
```

**Research workflow overview:**
```
tag:#question OR tag:#finding OR tag:#source OR tag:#answer
```

## Dataview Query Examples

### List All Verified Claims by Confidence

```dataview
TABLE confidence, verification_status
FROM #finding
WHERE contains(tags, "verification/verified")
SORT confidence DESC
```

### List Academic Sources by Reliability Tier

```dataview
TABLE source_type, reliability_tier, publication_year
FROM #source
WHERE contains(tags, "source-type/academic")
SORT reliability_tier ASC, publication_year DESC
```

### Count Entities by Primary Tag

```dataview
TABLE length(rows) as Count
FROM ""
WHERE contains(tags, "question") OR contains(tags, "finding") OR contains(tags, "source") OR contains(tags, "answer")
GROUP BY tags[0]
```

### List High-Priority Questions by Dimension

```dataview
TABLE dimension_type, priority
FROM #question
WHERE contains(tags, "priority/high")
SORT dimension_type ASC
```

### List Synthesis Documents by Level

```dataview
TABLE file.name, synthesis_level
FROM #answer
SORT synthesis_level ASC
```

## Implementation Guidelines

### For Agent Developers

When creating entity files in agents:

1. **Always include exactly ONE primary tag**: `question`, `finding`, `source`, or `answer`
2. **Add relevant secondary tags**: Based on entity metadata and type
3. **Use exact tag names**: Match taxonomy exactly (no typos or variations)
4. **Preserve frontmatter fields**: Keep `publisher_type`, `organization_type` fields alongside tags
5. **Update validation**: Ensure entity creation validates tag format

**Example Agent Tag Specification**:
```yaml
# Finding from academic source
tags: [finding, source-type/academic]

# Publisher organization
tags: [source, publisher-type/organization, organization-type/research-institution]
publisher_type: "organization"
organization_type: "research-institution"
```

### For Knowledge Base Users

When exploring the knowledge graph:

1. **Start with primary tag filters**: `tag:#question`, `tag:#finding`, `tag:#source`, `tag:#answer`
2. **Refine with secondary tags**: Combine filters for precision
3. **Use Dataview for analytics**: Generate dynamic reports from tagged entities
4. **Create saved searches**: Save frequently used tag combinations in Obsidian
5. **Visualize workflows**: Filter to see question→finding→source→answer chains

## Migration from v1.0 to v2.0

### Breaking Changes

**v1.0 (Old Format)**:
```yaml
tags: [entity/finding, research, source-type/academic]
```

**v2.0 (New Format)**:
```yaml
tags: [finding, source-type/academic]
```

### Tag Mapping Table

| Old v1.0 Tag | New v2.0 Tag | Notes |
|--------------|--------------|-------|
| `entity/initial-question` | `question` | Removed `entity/` prefix |
| `entity/dimension` | `question` | Removed `entity/` prefix, removed `dimension` secondary tag |
| `entity/refined-question` | `question` | Removed `entity/` prefix |
| `entity/query-batch` | `question` | Removed `entity/` prefix, removed `queries` secondary tag |
| `entity/finding` | `finding` | Removed `entity/` prefix, removed `research` secondary tag |
| `entity/megatrend` | `finding` | Removed `entity/` prefix, removed `cluster` secondary tag |
| `entity/domain-concept` | `finding` | Removed `entity/` prefix, removed `concept` secondary tag |
| `entity/source` | `source` | Removed `entity/` prefix, removed `citation` secondary tag |
| `entity/author` | `source` + `publisher-type/individual` | Changed to `source` primary, added type discriminator |
| `entity/publisher` | `source` + `publisher-type/{type}` | Changed to `source` primary, added type discriminator |
| `entity/citation` | `source` | Removed `entity/` prefix, removed `bibliography` secondary tag |
| `entity/claim` | `finding` | Removed `entity/` prefix, removed `verification` generic tag |
| `entity/synthesis` | `answer` | Removed `entity/` prefix |
| `status/{value}` | (removed) | No longer used in v2.0 |
| `dok-{1-4}` | (removed) | No longer used in v2.0 |
| `domain-{template}` | (removed) | No longer used in v2.0 |

### Graph Query Migration

**Old v1.0 Query**:
```
tag:#entity/finding
```

**New v2.0 Query**:
```
tag:#finding
```

### Automated Migration

Use the migration script to convert existing projects:

```bash
cd cogni-research/scripts
./migrate-tags-v2.sh --project-path /path/to/research-project --backup
```

**Script Features**:
- Rewrites all entity frontmatter tags from v1.0 to v2.0
- Creates backup before migration
- Validates tag format after conversion
- Generates migration report

**Manual Migration** (if script unavailable):
1. Search for `tags:` in all entity files
2. Replace `entity/` prefix with nothing
3. Remove obsolete secondary tags (`research`, `queries`, `cluster`, `concept`, `citation`, `bibliography`)
4. Add discriminator tags (`publisher-type/{type}`) where needed
5. Validate with `tag:#question` graph query

## Validation

### Tag Completeness Check

All entities must have:
- ✅ Exactly ONE primary tag: `question`, `finding`, `source`, or `answer`
- ✅ At least zero secondary tags (primary tag alone is valid)
- ✅ Secondary tags from approved taxonomy list only
- ✅ No `entity/` prefixes
- ✅ No obsolete tags (`research`, `queries`, `cluster`, `concept`, `citation`, `bibliography`, `status/*`, `dok-*`, `domain-*`)

### Tag Format Check

- ✅ Tags in YAML list format: `tags: [tag1, tag2]`
- ✅ No hashtags in frontmatter tags
- ✅ Nested tags use forward slash: `dimension-type/technical`
- ✅ Lowercase with hyphens: `source-type/academic`

### Special Validation Rules

- ✅ **Synthesis entities** must include `synthesis-level/{type}` secondary tag
- ✅ **Publisher entities** must include `publisher-type/{individual|organization}` secondary tag
- ✅ **Organization publishers** must include `organization-type/{category}` secondary tag
- ✅ **Claims** must include `confidence/{level}` and `verification/{status}` secondary tags

## References

- Obsidian Tags Documentation: https://help.obsidian.md/Editing+and+formatting/Tags
- Dataview Plugin: https://blacksmithgu.github.io/obsidian-dataview/
- Graph View Filtering: https://help.obsidian.md/Plugins/Graph+view

---

**Version**: 2.0.0
**Last Updated**: 2025-10-31
**Maintained By**: cogni-research
**Breaking Changes**: Yes - requires migration from v1.0 (see Migration section)
