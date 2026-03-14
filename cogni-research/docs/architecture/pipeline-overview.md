# Pipeline Architecture

## Four-Stage Pipeline

```
research-plan → findings-sources → claims → synthesis
    (00-03)         (04-05)          (06)     (cogni-narrative)
```

### Stage 1: research-plan
**Input:** Research question from user
**Output:** Entities 00-03 (question, dimensions, refined questions, query batches)

Phases:
- Phase 0: Project initialization, research_type detection
- Phase 1: Question refinement, DOK classification
- Phase 2: Dimension planning (MECE via dimension-planner agent)
- Phase 3: Batch creation (batch-creator agent)

State flag: `planning_complete = true`

### Stage 2: findings-sources
**Input:** Query batches from Stage 1
**Output:** Entities 04-05 (findings, enriched sources)

Phases:
- Phase 4: Parallel findings creation (findings-creator agents, one per question)
- Phase 5: Source extraction with publisher profiling + APA citation (source-creator agent)

State flag: `discovery_complete = true`

### Stage 3: claims
**Input:** Findings from Stage 2
**Output:** Entity 06 (claims with three-layer confidence)

Phases:
- Phase 6: Claim extraction with evidence confidence + claim quality (claim-extractor agents)
- Phase 7: Source verification via cogni-claims (optional)

State flag: `claims_complete = true`

### Stage 4: synthesis
**Input:** All entities (findings, sources, claims) grouped by dimension
**Output:** Per-dimension narratives + cross-dimensional research-hub.md

Phases:
- Phase 8: Per-dimension narrative (cogni-narrative:narrative-writer per dimension)
- Phase 9: Cross-dimensional narrative (cogni-narrative:narrative-writer)
- Phase 10: Quality review (cogni-narrative:narrative-reviewer, optional)

State flag: `synthesis_complete = true`

---

## Entity Flow

```
00-initial-question
  └→ 01-research-dimensions (2-10 MECE dimensions)
       └→ 02-refined-questions (8-50 atomic questions)
            └→ 03-query-batches (1 per question)
                 └→ 04-findings (web + LLM results)
                      ├→ 05-sources (enriched: URL + publisher + citation)
                      └→ 06-claims (three-layer confidence scoring)
                           └→ synthesis/ (cogni-narrative output)
```

## Agent Delegation

| Skill | Agents Used | Parallelism |
|---|---|---|
| research-plan | dimension-planner, batch-creator | Sequential |
| findings-sources | findings-creator (×N), source-creator | Parallel findings, sequential sources |
| claims | claim-extractor (×N) | Parallel per partition |
| synthesis | cogni-narrative:narrative-writer (×D+1) | Parallel per dimension |

## Anti-Hallucination Hooks

| Hook | Event | Purpose |
|---|---|---|
| block-entity-writes | PreToolUse | Force create-entity.sh usage |
| validate-workspace-wikilinks | PreToolUse | Require workspace-relative paths |
| post-entity-creation | PostToolUse | Validate frontmatter + UUID |
| post-write-validate-wikilinks | PostToolUse | Detect broken wikilinks |
| pre-synthesis-validation | PostToolUse | Gate synthesis on claim availability |
| verify-source-creator-output | SubagentStop | Anti-hallucination with auto-recovery |
| repair-missing-batches | SubagentStop | Create missing batch entities |
| verify-batch-creator-output | SubagentStop | Detect fabricated results |

## Cross-Plugin Integration

- **cogni-narrative**: synthesis skill delegates storytelling (6 arc frameworks)
- **cogni-claims**: claims skill submits for source URL verification (optional)
- **cogni-workspace**: export skills use themes for styling
