# Report Types Reference

## Basic Report

**When**: User asks for a "research report", "overview", or doesn't specify type.

**Structure**:
- 3-5 sub-questions, single-pass parallel research
- 3000-5000 words final report
- Simple structure: intro → sections → conclusion → references
- 1 review iteration typical

**Agent cost**: ~5-7 agent spawns (3-5 researchers + 1 writer + 1-2 review cycle)

## Detailed Report

**When**: User asks for "detailed", "comprehensive", "in-depth", or "thorough" report.

**Structure**:
- 5-10 section outline, parallel research per section
- 5000-10000 words final report
- Rich structure: executive summary → intro → multi-section analysis → cross-cutting themes → recommendations → references
- 2-3 review iterations typical

**Agent cost**: ~12-18 agent spawns (5-10 researchers + 1 writer + claim-extractor + reviewer + revisor × iterations)

## Deep Report

**When**: User asks for "deep research", "deep dive", or "exhaustive" analysis.

**Structure**:
- Research tree: 3-5 top-level branches × 2-3 sub-branches = 10-20 leaf nodes
- 8000-15000 words final report
- Hierarchical structure reflecting tree depth
- 2-3 review iterations typical

**Agent cost**: ~20-30 agent spawns (10-20 deep-researchers in batches + writer + review cycle)

**Batching**: Max 4-5 deep-researchers per batch. With 15 leaves: 3 batches × 5 agents.

## Report Type Detection

Parse user request for keywords:

| Keywords | Type |
|----------|------|
| "quick", "brief", "overview", "report on" | basic |
| "detailed", "comprehensive", "thorough", "in-depth" | detailed |
| "deep research", "deep dive", "exhaustive", "recursive" | deep |

Default to **basic** if ambiguous.
