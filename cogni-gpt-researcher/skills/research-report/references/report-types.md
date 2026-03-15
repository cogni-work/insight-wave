# Report Types Reference

## Basic Report

**When**: User asks for a "research report", "overview", or doesn't specify type.

**Structure**:
- Default 5 sub-questions (override with `max_subtopics`), single-pass parallel research
- 3000-5000 words final report
- Simple structure: intro → sections → conclusion → references
- 1-2 review iterations typical

**Agent cost**: ~7-9 agent spawns (5 researchers + 1 writer + 1-3 review cycle)

## Detailed Report

**When**: User asks for "detailed", "comprehensive", "in-depth", or "thorough" report.

**Structure**:
- Default 5-10 section outline (override with `max_subtopics`), parallel research per section
- 5000-10000 words final report
- Rich structure: executive summary → intro → multi-section analysis → cross-cutting themes → recommendations → references
- 2-3 review iterations typical

**Agent cost**: ~12-18 agent spawns (5-10 researchers + 1 writer + claim-extractor + reviewer + revisor × iterations)

## Deep Report

**When**: User asks for "deep research", "deep dive", or "exhaustive" analysis.

**Structure**:
- Research tree: 3-5 top-level branches × 2-3 sub-branches = 10-20 leaf nodes (override leaf count with `max_subtopics`)
- 8000-15000 words final report
- Hierarchical structure reflecting tree depth
- 2-3 review iterations typical

**Agent cost**: ~20-30 agent spawns (10-20 deep-researchers in batches + writer + review cycle)

**Batching**: Max 4-5 deep-researchers per batch. With 15 leaves: 3 batches × 5 agents.

## Outline Report

**When**: User asks for an "outline", "structure", "framework", "skeleton", or wants a quick structured overview before committing to a full report.

**Structure**:
- Default 5 sub-questions (override with `max_subtopics`), single-pass parallel research
- 1000-2000 words output — NOT a full prose report
- Hierarchical outline: H2 main sections → H3 sub-sections → bullet-point key findings
- Each section includes 2-3 key findings with source citations
- No narrative flow, no transitions — pure structured information

**Agent cost**: ~6-8 agent spawns (5 researchers + 1 writer + 0-1 review)

**Pipeline difference**: Skips the full review loop (Phase 5). A single structural review pass is sufficient for an outline. No claims extraction.

**Use case**: Quick research planning, pre-research scoping, presentation prep, deciding whether a full report is worth pursuing.

## Resource Report

**When**: User asks for a "resource list", "source compilation", "annotated bibliography", "reading list", or wants curated sources rather than narrative analysis.

**Structure**:
- Default 5 sub-questions (override with `max_subtopics`), single-pass parallel research
- 1500-3000 words output
- Organized by sub-topic: each section lists 3-5 curated sources with annotations
- Per-source annotation: title, publisher, relevance summary (2-3 sentences), quality score, key takeaway
- Summary section at the end: overall source landscape, coverage gaps, recommended starting points

**Agent cost**: ~6-8 agent spawns (5 researchers + 1 writer + 0-1 review)

**Pipeline difference**: Writer focuses on source annotation rather than narrative synthesis. Skips claims extraction (no factual claims to verify — it's a bibliography). Single structural review pass.

**Use case**: Literature review prep, due diligence source collection, research planning, building a reading list on a topic.

## Configurable Sub-Question Count

When `max_subtopics` is set in project config, it overrides the default sub-question/section count:
- **basic**: Replaces the fixed 5 (valid range: 3-8)
- **detailed**: Replaces the 5-10 range (valid range: 3-15)
- **deep**: Controls target leaf node count (valid range: 5-25)

## Report Type Detection

Parse user request for keywords:

| Keywords | Type |
|----------|------|
| "quick", "brief", "overview", "report on" | basic |
| "detailed", "comprehensive", "thorough", "in-depth" | detailed |
| "deep research", "deep dive", "exhaustive", "recursive" | deep |
| "outline", "structure", "framework", "skeleton" | outline |
| "resources", "sources", "bibliography", "reading list", "source list" | resource |

Default to **basic** if ambiguous.
