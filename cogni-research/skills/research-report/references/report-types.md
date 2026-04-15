# Report Types Reference

## Length and depth are independent

**Depth** (`report_type`) controls the research tree shape and sub-question count. **Length** (`target_words`) controls the writer word-count floor. Set them independently in `project-config.json`.

The word counts listed under each type below are **defaults for `target_words` when the user does not set it explicitly** — not hard coupling between depth and length. Override via the `target_words` field or the `--target-words <N>` flag on `initialize-project.sh`.

In v0.7.7 (issue #35) the deep-mode default was reduced from 8000 to 5000 words to align with professional deep-research norms and the single-voice writer's sweet spot. Set `target_words: 8000` explicitly to restore the old floor. `allow_short: true` semantics are unchanged — still the escape hatch that disables all expansion gates.

Default-by-depth table:

| Depth (`report_type`) | Default `target_words` |
|---|---|
| basic     | 3000 |
| detailed  | 5000 |
| **deep**  | **5000** (reduced from 8000 in v0.7.7) |
| outline   | 1000 |
| resource  | 1500 |

## Basic Report

**When**: User asks for a "research report", "overview", or doesn't specify type.

**Structure**:
- Default 5 sub-questions (override with `max_subtopics`), single-pass parallel research
- Default `target_words: 3000` (override via `target_words` in project-config)
- Simple structure: intro → sections → conclusion → references
- 1-2 review iterations typical

**Agent cost**: ~7-9 agent spawns (5 researchers + 1 writer + 1-3 review cycle)

## Detailed Report

**When**: User asks for "detailed", "comprehensive", "in-depth", or "thorough" report.

**Structure**:
- Default 5-10 section outline (override with `max_subtopics`), parallel research per section
- Default `target_words: 5000` (override via `target_words` in project-config)
- Rich structure: executive summary → intro → multi-section analysis → cross-cutting themes → recommendations → references
- 2-3 review iterations typical

**Agent cost**: ~12-18 agent spawns (5-10 researchers + 1 writer + claim-extractor + reviewer + revisor × iterations)

## Deep Report

**When**: User asks for "deep research", "deep dive", or "exhaustive" analysis.

**Structure**:
- Research tree: 3-5 top-level branches × 2-3 sub-branches = 10-20 leaf nodes (override leaf count with `max_subtopics`)
- Default `target_words: 5000` (reduced from 8000 in v0.7.7 — override via `target_words` in project-config; set `target_words: 8000` or higher for long-form / whitepaper deliverables)
- Hierarchical structure reflecting tree depth
- 2-3 review iterations typical

**Agent cost**: ~20-30 agent spawns (10-20 deep-researchers in batches + writer + review cycle)

**Batching**: Max 4-5 deep-researchers per batch. With 15 leaves: 3 batches × 5 agents.

## Outline Report

**When**: User asks for an "outline", "structure", "framework", "skeleton", or wants a quick structured overview before committing to a full report.

**Structure**:
- Default 5 sub-questions (override with `max_subtopics`), single-pass parallel research
- Default `target_words: 1000` — NOT a full prose report
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
- Default `target_words: 1500` (override via `target_words` in project-config)
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
