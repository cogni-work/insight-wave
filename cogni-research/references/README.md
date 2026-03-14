# Plugin-Level Shared References

This directory contains reference documentation shared across **all skills** within the `cogni-research` plugin.

## Purpose

Plugin-level references avoid duplication and ensure consistency when multiple skills need access to the same documentation. Files here are distributed with the plugin and available to all skills.

## Current References

### Foundational Frameworks

**anti-hallucination-foundations.md** (26.8KB) ⭐⭐⭐ **Critical**
- 5 core patterns for evidence-based processing
- Verification checkpoint pattern
- No fabrication enforcement
- Provenance integrity requirements
- Used by: source-creator, fact-checker, synthesis-dimension, executive-synthesizer

### Bash Scaffolding

**shared-bash-patterns.md** (15KB) ⭐⭐⭐ **Critical**
- Parameter parsing patterns (while loop + case)
- Working directory validation
- Logging initialization
- JSON response construction
- Used by: All processing skills (source-creator, citation-generator, dimension-planner, synthesis-dimension, executive-synthesizer, fact-checker)

### Entity Architecture

**entity-structure-guide.md** (12KB) ⭐⭐ **Important**
- Common YAML frontmatter patterns
- UUID generation and deduplication
- Wikilink conventions
- Entity lifecycle patterns
- Used by: source-creator, citation-generator, publisher-generator, dimension-planner, research-executor

**wikilink-architecture.md** (22KB) ⭐⭐⭐ **Critical**
- Target entity relationship architecture with Mermaid diagrams
- Forward links specification (18 relationships)
- Backlinks specification with implementation status (12 relationships)
- Path pattern decision tree (single vs multi-project modes)
- External link integration (Source as bridge entity)
- User journey traces (researcher, reviewer, QA)
- Implementation issues tracker (17 actionable issues)
- Used by: source-creator, fact-checker, publisher-generator, citation-generator, synthesis-dimension, executive-synthesizer, deeper-research orchestrator

### Contract Standards

**script-contract-usage.md** (8KB) ⭐⭐ **Important**
- Contract location and discovery (cogni-research/contracts/)
- Reading contract specifications
- Calling scripts with contracts
- Handling missing contracts
- Used by: All skills calling scripts

## Path Convention

Skills reference these files using relative paths:

```markdown
[../../references/shared-bash-patterns.md](../../references/shared-bash-patterns.md)
```

This resolves from `skills/{skill-name}/` to `references/` at the plugin level.

## Reference Selection Strategy

### By Task Type

| Skill Task Type | Primary References | Secondary References |
|-----------------|--------------------|-----------------------|
| **Entity creation** (source-creator, publisher-generator) | shared-bash-patterns.md, entity-structure-guide.md, wikilink-architecture.md | anti-hallucination-foundations.md, script-contract-usage.md |
| **Synthesis** (synthesis-dimension, executive-synthesizer) | shared-bash-patterns.md, anti-hallucination-foundations.md, wikilink-architecture.md | entity-structure-guide.md, script-contract-usage.md |
| **Validation** (fact-checker) | shared-bash-patterns.md, anti-hallucination-foundations.md, wikilink-architecture.md | entity-structure-guide.md, script-contract-usage.md |
| **Planning** (dimension-planner) | shared-bash-patterns.md, entity-structure-guide.md, wikilink-architecture.md | script-contract-usage.md |
| **Search execution** (research-executor) | shared-bash-patterns.md, anti-hallucination-foundations.md, wikilink-architecture.md | entity-structure-guide.md |
| **Citation generation** (citation-generator) | shared-bash-patterns.md, entity-structure-guide.md, wikilink-architecture.md | script-contract-usage.md |

### Progressive Disclosure Pattern

Load references **only as needed** during skill execution:

**Phase 0 (Parameter Validation):**
```markdown
**Read:** `../../references/shared-bash-patterns.md` for:
- Parameter parsing pattern (Section 1)
```

**Phase 1 (Environment Setup):**
```markdown
**Read:** `../../references/shared-bash-patterns.md` for:
- Working directory validation (Section 2)
- Logging initialization (Section 3)
```

**Phase 2+ (Entity Processing):**
```markdown
**Read:** `../../references/entity-structure-guide.md` for:
- Entity frontmatter structure
**Read:** `../../references/anti-hallucination-foundations.md` for:
- Verification checkpoint pattern
```

**Phase N (JSON Response):**
```markdown
**Read:** `../../references/shared-bash-patterns.md` for:
- JSON response construction (Section 4)
```

## When to Add References Here

Add documentation to plugin-level references when:

1. **Multiple skills need the same reference** - Avoid duplication (e.g., shared-bash-patterns.md used by all 7 skills)
2. **Cross-skill patterns** - Shared scaffolding, architecture, standards
3. **Plugin-wide guidance** - Applies to all components in the plugin (e.g., anti-hallucination-foundations.md)
4. **Universal best practices** - Foundational techniques applicable across domains
5. **Maintenance benefit** - Update once, benefits all skills

Keep skill-specific references in `skills/{skill-name}/references/` when:
- Tightly coupled to that skill's unique workflow (e.g., APA formatting for citation-generator)
- Contains skill-specific implementation details not applicable elsewhere (e.g., PICOT framework for dimension-planner)
- Low reuse potential outside the skill (single consumer only)
- Domain-specific patterns (e.g., claim quality scoring for fact-checker)

## Maintenance

When updating references here:

1. Update the single source file in this directory
2. All skills referencing it automatically benefit
3. No manual sync required across skills
4. Changes propagate on next skill invocation

## Architecture Benefits

✅ **Single source of truth** - One file to maintain
✅ **Consistency** - All skills reference identical content
✅ **Token efficiency** - 82% reduction in bash scaffolding duplication (1,700 → 300 lines)
✅ **Update propagation** - Fix once, benefits everywhere
✅ **Progressive disclosure** - Skills load only needed sections

## Comparison: Skill-Specific vs Plugin-Level

### Plugin-Level (This Directory)

**Size:** 4 files, ~60KB total
**Content:** Universal patterns used by 2+ skills
**Examples:** Bash scaffolding, anti-hallucination, entity structure
**Updates:** Rare (established patterns)

### Skill-Specific (`skills/{skill-name}/references/`)

**Size per skill:** 4-11 files, 50-400KB
**Content:** Unique domain patterns
**Examples:** PICOT framework, APA formatting, claim quality scoring
**Updates:** Frequent (skill evolution)

## Token Efficiency Analysis

### Before Consolidation

| Pattern | Duplicated Across | Total Lines |
|---------|-------------------|-------------|
| Parameter parsing | 7 skills | ~350 lines |
| Working directory validation | 7 skills | ~280 lines |
| Logging initialization | 7 skills | ~210 lines |
| JSON response construction | 7 skills | ~175 lines |
| Anti-hallucination patterns | 5 skills | ~500 lines |
| Entity structure patterns | 5 skills | ~400 lines |
| **TOTAL** | | **~1,915 lines** |

### After Consolidation

| Reference | Lines | Reduction |
|-----------|-------|-----------|
| shared-bash-patterns.md | ~150 | 1,015 → 150 (85%) |
| anti-hallucination-foundations.md | ~200 | 500 → 200 (60%) |
| entity-structure-guide.md | ~150 | 400 → 150 (63%) |
| **TOTAL** | **~500 lines** | **~1,915 → 500 (74%)** |

**Net Savings:** ~1,400 lines across all skills

## Distribution Model

**Development:**
- Source: `references/` (plugin root)
- Skills reference via `../../references/`

**Marketplace:**
- Deployed to: `~/.claude/plugins/marketplaces/cogni-research/references/`
- Skills resolve references correctly via relative paths
- No symlinks needed (files are copied during distribution)

## Version History

**v3.0.0 (Sprint 295)** - Wikilink Architecture Reference
- Added wikilink-architecture.md (target entity relationship architecture)
- 6 Mermaid diagrams for visual clarity
- Complete forward/backlink specifications
- User journey traces for all user types
- Implementation issues tracker (17 actionable issues)
- Updated reference selection strategy to include wikilink-architecture.md

**v2.0.0 (Sprint 001)** - Comprehensive shared reference architecture
- Added shared-bash-patterns.md (4 universal patterns)
- Added entity-structure-guide.md (common entity patterns)
- Added script-contract-usage.md (contract usage guidance)
- Created README.md catalog with metadata
- Established reference selection strategy
- 74% token reduction for shared patterns

**v1.0.0** - Initial plugin-level references
- Added anti-hallucination-foundations.md

## Synthesis Templates

### templates/

Synthesis report templates implementing McKinsey Pyramid Principle (6 files, ~950 lines). Used by synthesis skills to generate consistent, evidence-based research outputs.

**📊 Synthesis Documents**

**[templates/template-executive.md](templates/template-executive.md)** (95 lines) ⭐⭐⭐ **Critical for Executive Synthesis**
- Executive summary with McKinsey Pyramid structure (answer first, supporting evidence)
- Key trends, strategic recommendations, confidence assessment
- Domain concepts glossary, research scope & methodology
- Used by: executive-synthesizer, research-types (trend-radar, lean-canvas)

**[templates/template-dimensions.md](templates/template-dimensions.md)** (153 lines) ⭐⭐⭐ **Critical for Dimensional Analysis**
- Dimensional analysis structure with MECE coverage validation
- Cross-cutting themes, dimension comparison tables, dimensional trends
- Used by: executive-synthesizer, research-types

**[templates/template-findings.md](templates/template-findings.md)** (183 lines) ⭐⭐⭐ **Critical for Detailed Findings**
- Detailed findings organized by megatrend clusters with evidence chains
- Megatrend cluster analysis, contradictions & tensions, research gaps
- Used by: synthesis-dimension, executive-synthesizer, research-types

**[templates/template-evidence.md](templates/template-evidence.md)** (314 lines) ⭐⭐ **Important for Evidence Tracking**
- Complete evidence chain: claims catalog, source catalog, author expertise
- Citation provenance, methodological notes, research limitations
- Used by: executive-synthesizer, research-types

**[templates/template-readme.md](templates/template-readme.md)** (140 lines) ⭐⭐ **Important for Navigation**
- 4-level progressive disclosure navigation guide
- Obsidian usage patterns (graph view, search, backlinks)
- Used by: executive-synthesizer, research-types

**[templates/README.md](templates/README.md)** (~950 lines) ⭐⭐ **Important for Template Usage**
- Complete template catalog with usage patterns
- Direct usage (generic research) vs composition usage (research types)
- Obsidian optimization, evidence-based architecture, McKinsey Pyramid Principle
- Maintenance guidelines and composition pattern examples
- Used by: All synthesis skills, research-types developers

**Features:**
- **Progressive Disclosure:** 4 levels (Executive 2-3 pages → Dimensions 4-6 pages → Findings 10-15 pages → Evidence 15-20 pages)
- **Obsidian Optimization:** Wikilinks, tags, graph view, backlinks
- **Evidence-Based:** Numbered citations (≥20 per document), complete provenance, confidence scoring
- **McKinsey Pyramid:** Answer first (L1), supporting arguments (L2), detailed evidence (L3), complete provenance (L4)

**Path Convention:**

From skill directory (skills/{skill-name}/):
```markdown
[../../references/templates/template-executive.md](../../references/templates/template-executive.md)
```
