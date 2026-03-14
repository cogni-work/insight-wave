---
name: synthesis
description: |
  Synthesize research findings into executive narratives using cogni-narrative's story arc frameworks.
  Use this skill after the claims skill has completed — it produces per-dimension insight summaries
  and a cross-dimensional research hub narrative. Trigger when the user says "synthesize",
  "create synthesis", "generate narratives from research", "tell the story", "write up the findings",
  "create the research report", or wants to move from raw findings/claims to publishable narratives.
---

# Synthesis

Transform research findings and claims into executive narratives by delegating to cogni-narrative's story arc frameworks. Produces one narrative per research dimension plus a cross-dimensional research hub.

## Prerequisites

Before running synthesis, verify:
- `research-plan` completed: dimensions exist in 01-research-dimensions/data/
- `findings-sources` completed: findings in 04-findings/data/, sources in 05-sources/data/
- `claims` completed: claims in 06-claims/data/ with confidence scores

Check via: `bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-phase-state.sh --project-path <path> --phase claims`

---

## Workflow

### Phase 1: Preparation

1. **Locate project**: Use project-picker if not specified
2. **Load dimensions**: Read all dimension entities from 01-research-dimensions/data/
3. **Load research metadata**: Read sprint-log.json for research_type, research_question, language
4. **Determine arc**: Auto-detect from research_type or ask user
   - `generic` → `corporate-visions` (default) or user-selected
   - `lean-canvas` → `corporate-visions`
   - `b2b-ict-portfolio` → `technology-futures` or `competitive-intelligence`
5. **Confirm arc with user** via AskUserQuestion: "Which narrative arc should we use for synthesis?"

### Phase 2: Per-Dimension Narratives

For each dimension (parallel execution):

1. **Gather dimension content**: Collect all findings and claims that belong to this dimension
   - Read findings from 04-findings/data/ where dimension_ref matches
   - Read claims from 06-claims/data/ where finding_refs link to dimension findings
   - Read sources from 05-sources/data/ where finding_refs link to dimension findings

2. **Prepare content directory**: Write a temporary summary markdown file per dimension at:
   `<project>/synthesis/<dimension-slug>/content.md`

   Include:
   - Dimension name and description
   - Key findings (titles + summaries)
   - Top claims (sorted by confidence_score, top 10-15)
   - Source attribution (publisher_name, reliability_tier)

3. **Invoke cogni-narrative**: Delegate to `cogni-narrative:narrative-writer` agent:
   ```
   --source-path <project>/synthesis/<dimension-slug>/
   --arc-id <selected-arc>
   --language <project-language>
   --output-path <project>/synthesis/<dimension-slug>/insight-summary.md
   --research-question "<dimension description>"
   ```

4. **Validate output**: Check that insight-summary.md was created with valid frontmatter

### Phase 3: Cross-Dimensional Narrative

After all dimension narratives complete:

1. **Gather all dimension narratives**: Read each `synthesis/<dimension-slug>/insight-summary.md`

2. **Prepare cross-dimensional content**: Write summary at `<project>/synthesis/cross-dimensional/content.md`
   Include:
   - Research question (from sprint-log)
   - All dimension narrative summaries (opening paragraphs)
   - Cross-cutting themes (claims that appear across multiple dimensions)
   - Overall confidence statistics

3. **Invoke cogni-narrative**: Delegate to `cogni-narrative:narrative-writer` agent:
   ```
   --source-path <project>/synthesis/cross-dimensional/
   --arc-id <selected-arc>
   --language <project-language>
   --output-path <project>/research-hub.md
   --research-question "<original research question>"
   ```

4. **Optional quality review**: Invoke `cogni-narrative:narrative-reviewer` on research-hub.md

### Phase 4: Finalization

1. **Update sprint-log**: Set `synthesis_complete = true`, record arc_id, dimension_count
2. **Generate sources README**: Run `generate-sources-readme.sh` for provenance overview
3. **Generate claims README**: Run `generate-claims-readme.sh` for claim inventory
4. **Report completion**: Summary with word counts, arc used, dimension count

---

## Output Structure

```
<project>/
├── synthesis/
│   ├── <dimension-1-slug>/
│   │   ├── content.md          # Prepared input for cogni-narrative
│   │   └── insight-summary.md  # Dimension narrative (1,450-1,900 words)
│   ├── <dimension-2-slug>/
│   │   ├── content.md
│   │   └── insight-summary.md
│   └── cross-dimensional/
│       ├── content.md
│       └── insight-summary.md
├── research-hub.md             # Cross-dimensional narrative (copy of cross-dimensional/insight-summary.md)
├── 05-sources/README.md        # Source inventory
└── 06-claims/README.md         # Claim inventory
```

---

## Arc Selection Guide

| Research Type | Recommended Arc | Why |
|---|---|---|
| generic | corporate-visions | Versatile Why Change → Why Now → Why You → Why Pay progression |
| generic (tech-focused) | technology-futures | Emerging → Converging → Possible → Required for innovation topics |
| generic (competitive) | competitive-intelligence | Landscape → Shifts → Positioning → Implications |
| lean-canvas | corporate-visions | Maps well to business model validation narrative |
| b2b-ict-portfolio | technology-futures | Maps ICT portfolio dimensions to technology evolution |
| b2b-ict-portfolio (market) | competitive-intelligence | Market positioning and competitive analysis |

When in doubt, ask the user. The arc determines the narrative structure but all arcs produce the same quality output.

---

## Derivative Formats (Optional)

After synthesis, the user can request derivative formats via cogni-narrative:

- **Executive Brief** (300-500 words): `cogni-narrative:narrative-adapt --format executive-brief`
- **Talking Points** (bullets): `cogni-narrative:narrative-adapt --format talking-points`
- **One-Pager** (400-600 words): `cogni-narrative:narrative-adapt --format one-pager`

These work on any insight-summary.md produced by this skill.
