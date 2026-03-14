# References - deeper-research-1

Reference documentation for the collection phase (Phases 0-6) of the deeper-research workflow.

## Contents

### Phase Workflows

**[phase-workflows/](phase-workflows/)** - Complete implementation instructions for Phases 0-6

- [phase-0-initialization.md](phase-workflows/phase-0-initialization.md) - Project initialization, research type selection
- [phase-1-question-refinement.md](phase-workflows/phase-1-question-refinement.md) - Question analysis and clarification
- [phase-2-dimensional-planning.md](phase-workflows/phase-2-dimensional-planning.md) - Dimension and sub-question generation
- [phase-3-query-construction.md](phase-workflows/phase-3-query-construction.md) - Search query batch creation
- [phase-4-research-execution.md](phase-workflows/phase-4-research-execution.md) - Parallel research execution
- [phase-5-knowledge-extraction.md](phase-workflows/phase-5-knowledge-extraction.md) - Concept and source extraction
- [phase-6-publisher-citation.md](phase-workflows/phase-6-publisher-citation.md) - Publisher generation and citations

### Methodology & Standards

**[question-analysis-methodology.md](question-analysis-methodology.md)** - Framework for analyzing and refining research questions
- Systematic analysis dimensions
- Ambiguity detection patterns
- Clarification strategies
- Entity structure templates

**[quality-gates.md](quality-gates.md)** - Quality standards and validation workflows
- Entity validation protocols
- Metadata verification
- Data integrity checks
- Quality best practices

**[validation-protocols.md](validation-protocols.md)** - JSON validation workflows
- Entity file validation
- Metadata verification
- Wikilink validation
- Index integrity checks

### Operational Guides

**[parallelization-strategies.md](parallelization-strategies.md)** - Parallel execution patterns
- Agent count calculation (15-Sources Rule, Dimension-Based Partitioning)
- Round-robin distribution
- Entity partitioning strategies
- Concurrency management

**[entity-tagging-taxonomy.md](entity-tagging-taxonomy.md)** - Entity metadata schemas
- YAML frontmatter structure
- Dublin Core metadata
- Tag taxonomies
- Legacy field compatibility

## Usage Pattern

When implementing a phase:
1. Read the corresponding phase workflow file for step-by-step instructions
2. Reference methodology files for detailed frameworks
3. Apply validation protocols before phase completion
4. Use parallelization strategies for concurrent agent execution

## Progressive Disclosure

Load reference files progressively as needed:
- Phase workflows contain high-level orchestration steps
- Methodology files provide deep-dive frameworks
- Validation protocols ensure quality at checkpoints

## Part 1 Scope

These references support **Part 1: Collection** (Phases 0-6). For synthesis-specific references (Phases 7-10), see the `deeper-synthesis` skill.

## Related Skills

- **deeper-synthesis** - Part 2 synthesis phase (Phases 7-10)
- Agents: dimension-planner, research-query-optimizer, research-executor, concept-extractor, source-creator, publisher-generator, citation-generator
