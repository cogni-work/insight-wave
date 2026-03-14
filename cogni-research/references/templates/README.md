# Synthesis Templates

## Overview

This directory contains 5 synthesis report templates implementing the McKinsey Pyramid Principle with 4-level progressive disclosure architecture. These templates enable research synthesis skills to generate consistent, evidence-based outputs optimized for Obsidian.

**Core Principle:** Answer first (executive summary), then supporting arguments (dimensional analysis), then detailed evidence (findings), then complete provenance (evidence chains).

## Template Inventory

| Template | Lines | Level | Purpose |
|----------|-------|-------|---------|
| [template-executive.md](template-executive.md) | 95 | 1 | Executive summary with key trends, strategic recommendations |
| [template-dimensions.md](template-dimensions.md) | 153 | 2 | Dimensional analysis with cross-cutting themes |
| [template-findings.md](template-findings.md) | 183 | 3 | Detailed findings organized by megatrend clusters |
| [template-evidence.md](template-evidence.md) | 314 | 4 | Complete evidence chain with claims catalog, source provenance |
| [template-readme.md](template-readme.md) | 140 | - | Navigation guide for 4-level structure |
| **TOTAL** | **885** | | |

### Progressive Disclosure Architecture

**Level 1: Executive Summary** (2-3 pages)
- Direct answer to research question
- 3-5 key trends with confidence scores
- Strategic recommendations
- Domain concepts glossary
- Overall confidence assessment

**Level 2: Key Dimensions** (4-6 pages)
- Analysis organized by research dimensions
- Dimension summaries with key findings
- Cross-cutting themes across dimensions
- Confidence by dimension
- Source coverage by dimension

**Level 3: Detailed Findings** (10-15 pages)
- Complete findings organized by megatrend clusters
- Evidence summaries with wikilinks
- Source quality indicators
- Contradictions and tensions
- Research gaps identified

**Level 4: Supporting Evidence** (15-20 pages)
- Complete claims catalog (high/moderate confidence)
- Source catalog with reliability tiers
- Author expertise summaries
- Citation provenance with APA format
- Methodological notes and limitations

## Usage Patterns

### Pattern 1: Direct Usage (Generic Research)

Skills generating standard research synthesis reference templates directly for structure and content guidance.

**Who Uses:**
- `executive-synthesizer` - Generates all 4 synthesis documents
- `synthesis-dimension` - Generates dimension-scoped synthesis documents
- `dimension synthesis` - Generates question-level dimensional analysis

**How to Reference:**

From skill SKILL.md or references/*.md:

```markdown
## Template References

**Base Synthesis Templates (Plugin-Level):**

- [../../references/templates/template-executive.md](../../references/templates/template-executive.md) - Executive summary structure
- [../../references/templates/template-dimensions.md](../../references/templates/template-dimensions.md) - Dimensional analysis
- [../../references/templates/template-findings.md](../../references/templates/template-findings.md) - Detailed findings
- [../../references/templates/template-evidence.md](../../references/templates/template-evidence.md) - Evidence catalog
- [../../references/templates/template-readme.md](../../references/templates/template-readme.md) - Navigation guide

**Usage:** Load templates for complete structure, content examples, and formatting patterns.
```

**Example (executive-synthesizer SKILL.md):**

```markdown
### Phase 3: Document Generation

**Template Loading:**

1. Load [../../references/templates/template-executive.md](../../references/templates/template-executive.md) for executive summary structure
2. Load [../../references/templates/template-dimensions.md](../../references/templates/template-dimensions.md) for dimensional analysis
3. Load [../../references/templates/template-findings.md](../../references/templates/template-findings.md) for findings organization
4. Load [../../references/templates/template-readme.md](../../references/templates/template-readme.md) for navigation guide

Generate synthesis documents following template structures with:
- Complete frontmatter (Dublin Core metadata)
- Numbered citations (minimum 20 per document)
- Cross-dimensional pattern detection
- Wikilinks to entities
```

### Pattern 2: Composition Usage (Specialized Research Types)

Skills creating domain-specific research outputs load base templates and overlay specialized sections while preserving core structure.

**Who Uses:**
- Research types system (`references/research-types/`)
  - trend-radar (Gartner Hype Cycle framework)
  - lean-canvas (Lean Canvas 9-block model)

**Composition Strategy:**

1. **Load base template** for foundational structure
2. **Identify overlay sections** (domain-specific content)
3. **Preserve core elements** (provenance, confidence, navigation)
4. **Generate specialized output** combining base + overlay

**Example: Trend Radar Research Type**

```markdown
## Trend Radar Executive Summary Template

**Base Template:** template-executive.md (McKinsey Pyramid structure)

**Trend Radar Overlays:**

1. Replace "Key Trends" section with "Trends by Stage":
   - Innovation Trigger (0-2 years to adoption)
   - Peak of Inflated Expectations (2-5 years)
   - Trough of Disillusionment (5-10 years)
   - Slope of Enlightenment (2-5 years to plateau)
   - Plateau of Productivity (mainstream)

2. Add "Trend Timeline" visualization section:
   - Timeline projections with acceleration/deceleration factors
   - Trend interdependencies (enabling, competing, converging)

3. Extend "Strategic Recommendations" with adoption horizon guidance:
   - Short-term (0-2 years): Experiments and pilots
   - Medium-term (2-5 years): Strategic investments
   - Long-term (5-10 years): Watch and prepare

**Preserved Elements:**
- Direct answer section (research question response)
- Confidence assessment (overall and by dimension)
- Domain concepts glossary
- Research scope & methodology
- Navigation links to other synthesis levels

**Result:** Trend-specific executive summary with Gartner Hype Cycle framework, grounded in same evidence foundation as generic synthesis.
```

**Implementation Pattern (from research-types/INTEGRATION-GUIDE.md):**

```bash
# Load base template for structure
EXEC_TEMPLATE="../../../references/templates/template-executive.md"

# Load research-type specific overlay
TREND_OVERLAY="trend-radar/template-trend-radar-executive.md"

# Generate synthesis combining both
# - Base structure from EXEC_TEMPLATE
# - Specialized sections from TREND_OVERLAY
# - Preserved: provenance, confidence, navigation
```

**See:** [../research-types/INTEGRATION-GUIDE.md](../research-types/INTEGRATION-GUIDE.md) for detailed composition examples and patterns.

## Template Features

### Obsidian Optimization

All templates designed for Obsidian markdown with:

**Wikilinks:** Connect synthesis documents to entity files
```markdown
[[finding-uuid|Finding Title]] - Links to finding entity
[[source-uuid|Source Title]] - Links to source entity
[[concept-name|Concept Display Name]] - Links to domain concept
```

**Tags:** Enable filtering and search
```yaml
tags: [synthesis, executive-summary, dimensions, findings, evidence]
```

**Graph View:** Visualize entity relationships
- Synthesis documents appear as hubs in graph
- Wikilinks create edges to entities
- Navigate visually through evidence chains

**Backlinks:** Track provenance
- See which syntheses reference each entity
- Verify evidence sourcing
- Audit citation completeness

### Evidence-Based Architecture

All templates enforce rigorous sourcing and confidence scoring:

**Numbered Citations:** Minimum citation requirements
- research-hub.md: ≥50 numbered citations
- 09-citations/README.md: All sources documented

**Citation Format:**
```markdown
Cost reduction emerged across dimensions<sup>[1](../10-claims/data/claim-id.md)</sup>.
Operational analysis confirms 30-40% gains<sup>[2](../10-claims/data/claim-id-2.md)</sup>.

---

## References

<a id="ref-1"></a>[1] [Cost reduction claim text](../10-claims/data/claim-id.md) [[claim-id]] - Confidence: 0.87

<a id="ref-2"></a>[2] [Operational efficiency claim](../10-claims/data/claim-id-2.md) [[claim-id-2]] - Confidence: 0.82
```

**Provenance Chains:** Complete traceability
```
Query → Finding → Claim → Source → Author → Publisher → Citation
```

**Confidence Scoring:** Multi-factor assessment
- Evidence reliability (5 factors)
- Claim quality (4 dimensions: atomicity, fluency, decontextualization, faithfulness)
- Source reliability (tier 1-4 classification)
- Confidence thresholds: High (>0.75), Moderate (0.60-0.75), Low (<0.60, excluded)

**Source Reliability Tiers:**
- Tier 1 (Academic): Peer-reviewed journals, conferences
- Tier 2 (Industry): Whitepapers, authoritative reports
- Tier 3 (Professional): Expert articles, analysis
- Tier 4 (Community): Documentation, blog posts

### McKinsey Pyramid Principle

Templates implement structured communication framework:

**Level 1 (Executive):** Answer first
- Lead with direct answer to research question
- 2-3 paragraphs: What, Why it matters, Implications
- Key trends with confidence scores
- Strategic recommendations

**Level 2 (Dimensions):** Supporting arguments
- Break answer into MECE dimensions
- Each dimension answers specific sub-question
- Cross-cutting themes connect dimensions
- Evidence organized by analytical perspective

**Level 3 (Findings):** Detailed evidence
- Megatrend clusters with complete findings
- Evidence summaries with source attribution
- Patterns, contradictions, gaps identified
- Domain concepts integrated

**Level 4 (Evidence):** Complete provenance
- All claims cataloged with confidence scores
- All sources documented with reliability tiers
- All authors profiled with expertise
- All citations formatted in APA style
- Methodological notes and limitations

## Path Convention

Skills reference templates using relative paths from their location:

**From skill directory (skills/{skill-name}/):**

```markdown
[../../references/templates/template-executive.md](../../references/templates/template-executive.md)
```

**From skill references (skills/{skill-name}/references/):**

```markdown
[../../../references/templates/template-executive.md](../../../references/templates/template-executive.md)
```

**From research-types (references/research-types/):**

```markdown
[../../../references/templates/template-executive.md](../../../references/templates/template-executive.md)
```

**Path Resolution:**
```
skills/{skill-name}/               ← Start here
../../references/templates/        ← Go up 2 levels, into references/templates/
```

## Composition Pattern Details

### When to Use Composition

Use composition pattern when:
- Generating domain-specific research outputs (trend radar, lean canvas, competitive analysis, etc.)
- Need specialized structure beyond generic synthesis
- Want to maintain evidence foundation and provenance
- Require consistent navigation and cross-referencing

### Composition Steps

**Step 1: Identify Base Template**

Choose template matching synthesis level:
- Executive summary → template-executive.md
- Dimensional analysis → template-dimensions.md
- Detailed findings → template-findings.md
- Evidence documentation → template-evidence.md

**Step 2: Define Overlay Sections**

Identify domain-specific sections to add or replace:
- Frameworks (Gartner Hype Cycle, Lean Canvas, Porter's Five Forces, etc.)
- Specialized visualizations (timelines, canvases, matrices, etc.)
- Domain-specific metrics (stage placement, validation status, competitive positioning, etc.)

**Step 3: Preserve Core Elements**

Always maintain:
- Direct answer section (research question response)
- Confidence assessment (overall and dimensional)
- Domain concepts glossary (key terminology)
- Research methodology (evidence gathering approach)
- Navigation links (progressive disclosure structure)
- Provenance chains (complete sourcing)
- Citation format (numbered references)

**Step 4: Generate Specialized Output**

Combine base structure + overlay sections:
- Load base template for foundational structure
- Insert overlay sections at appropriate points
- Integrate domain-specific content with evidence chains
- Preserve wikilinks, tags, confidence scoring
- Maintain numbered citation format

### Composition Example: Lean Canvas Research Type

**Base:** template-executive.md (McKinsey Pyramid structure)

**Overlay:** Lean Canvas 9-Block Model

```markdown
## Lean Canvas Analysis

### Problem Block
{Evidence from research mapped to top 3 problems}
**Validation Status**: ✅ Validated / ⚠️ Hypothesis / ❌ Unknown
**Confidence**: 0.XX (based on N sources)
**Sources**: [1](claim-link), [2](claim-link)

### Customer Segments Block
{Evidence identifying target users and early adopters}
**Validation Status**: ✅ Validated
**Confidence**: 0.XX
**Sources**: [3](claim-link), [4](claim-link)

[... 7 more blocks ...]

### Unit Economics Summary
- LTV (Lifetime Value): ${amount} (Confidence: 0.XX) [Source](claim-link)
- CAC (Customer Acquisition Cost): ${amount} (Confidence: 0.XX) [Source](claim-link)
- LTV:CAC Ratio: X:1 (Target: 3:1)
- Gross Margin: XX% (Confidence: 0.XX) [Source](claim-link)

**Preserved from Base Template:**
- Direct answer section introduces business model
- Confidence assessment for overall canvas
- Domain concepts glossary (defines LTV, CAC, etc.)
- Research methodology documents evidence gathering
- Navigation links to detailed findings
- Complete citations with provenance
```

**Result:** Lean Canvas structured output grounded in researched evidence with full confidence scoring and provenance tracking.

## Maintenance Guidelines

### When to Update Templates

Update templates when:
1. **Structural improvements** - Add new sections, reorganize content, improve clarity
2. **Format changes** - Update Obsidian features, citation styles, metadata standards
3. **Quality enhancements** - Better examples, clearer instructions, improved prompts
4. **Framework updates** - McKinsey Pyramid Principle refinements, evidence standards

### Impact of Changes

**Single source of truth:** Updates automatically benefit all users
- `executive-synthesizer` - Generates 4 synthesis documents
- `synthesis-dimension` - Generates dimension-scoped synthesis documents
- `dimension synthesis` - Generates question-level analysis
- `research-types` - Trend radar, lean canvas, future types

**Composition users:** May need overlay adjustments
- If base template structure changes significantly, research-type overlays may need updates
- Preserved elements (provenance, confidence, navigation) should remain stable
- Test research-types after template changes

### Testing After Updates

**Validation checklist:**
1. ✅ Verify all skills can load templates (path resolution)
2. ✅ Test executive-synthesizer generates all 4 documents
3. ✅ Test synthesis-dimension document structure
4. ✅ Test dimension synthesis analysis format
5. ✅ Test research-types composition (trend-radar, lean-canvas)
6. ✅ Validate citation format and numbering
7. ✅ Verify Obsidian features (wikilinks, tags, graph view)
8. ✅ Check progressive disclosure navigation

### Version Control

**Track template changes:**
- Use git commit messages describing template updates
- Reference Sprint numbers for major refactorings
- Document breaking changes in CHANGELOG.md
- Tag stable versions for rollback if needed

## Related Documentation

**Plugin-Level References:**
- [../README.md](../README.md) - Complete plugin references catalog
- [../anti-hallucination-foundations.md](../anti-hallucination-foundations.md) - Evidence-based sourcing patterns
- [../entity-structure-guide.md](../entity-structure-guide.md) - Entity file format standards

**Research Types:**
- [../research-types/README.md](../research-types/README.md) - Research types system overview
- [../research-types/INTEGRATION-GUIDE.md](../research-types/INTEGRATION-GUIDE.md) - Composition implementation patterns

**Synthesis Skills:**
- [../skills/executive-synthesizer/SKILL.md](../skills/executive-synthesizer/SKILL.md) - Cross-dimensional synthesis
- [../skills/synthesis-dimension/SKILL.md](../skills/synthesis-dimension/SKILL.md) - Dimension-scoped synthesis documents
- [../skills/dimension synthesis/SKILL.md](../skills/dimension synthesis/SKILL.md) - Question-level analysis

## Quick Start Guide

### For Generic Research Synthesis

1. **Reference templates in your skill SKILL.md:**
   ```markdown
   Load [../../references/templates/template-executive.md](../../references/templates/template-executive.md)
   ```

2. **Follow template structure** for content organization

3. **Use numbered citations** (minimum 20 per document)

4. **Integrate Obsidian features** (wikilinks, tags)

5. **Validate confidence scores** and source reliability

### For Specialized Research Types

1. **Choose base template** matching your synthesis level

2. **Design overlay sections** with domain-specific structure

3. **Preserve core elements** (provenance, confidence, navigation)

4. **Create research-type template** combining base + overlay

5. **Document composition pattern** in INTEGRATION-GUIDE.md

6. **Test with evidence** to validate structure

### For Template Maintenance

1. **Read template file** to understand current structure

2. **Make improvements** following McKinsey Pyramid Principle

3. **Test with all synthesis skills** to verify no breakage

4. **Update this README** if usage patterns change

5. **Commit with clear message** describing changes

---

**Template Architecture:** McKinsey Pyramid Principle + Progressive Disclosure + Obsidian Optimization + Evidence-Based Sourcing

**Maintained by:** deeper-research plugin developers
**Used by:** 4 synthesis skills + research-types system
**Pattern Origin:** Sprint 262 template sharing architecture migration
