---
title: Pipeline Configuration
type: reference
category: pipeline
tags: [config, thresholds, defaults, research-story]
---

# Pipeline Configuration

Default settings and thresholds for the research-story pipeline.

## Default Parameters

| Parameter | Default | Range | Notes |
|-----------|---------|-------|-------|
| `type` | `basic` | basic, detailed, deep | Report depth |
| `arc-id` | auto-detect | 6 arcs | Falls back to `corporate-visions` |
| `language` | `en` | en, de | Flows through all phases |
| `target-length` | `1675` | 800-4,000 | Narrative word count; outside range breaks arc structure |
| `gates` | `auto` | auto, interactive, skip | Quality gate behavior |
| `derivatives` | `none` | executive-brief, talking-points, one-pager, all | Optional output formats |

## Quality Gate Thresholds

### Narrative Review (Phase 5)

| Mode | Threshold | Behavior on Failure |
|------|-----------|-------------------|
| `auto` | Score ≥ 70 (grade C) | One retry with adjusted parameters; if still < 70, proceed with warning |
| `interactive` | User decision | Present scorecard; user chooses proceed/retry/change-arc |
| `skip` | — | Skip review entirely |

### Copy-Reader Personas (Phase 6)

Default persona set for research narratives: `executive, technical, marketing`

These three perspectives cover the typical audience for research-backed executive narratives:
- **Executive**: Strategic alignment, actionability, clarity
- **Technical**: Accuracy, evidence quality, methodology soundness
- **Marketing**: Messaging coherence, story arc effectiveness, audience engagement

## Phase State Schema

`output/pipeline-state.json` tracks resumability:

```json
{
  "topic": "string",
  "type": "basic|detailed|deep",
  "language": "en|de",
  "arc_id": "string|null",
  "created_at": "ISO 8601",
  "phases": {
    "research":         {"status": "pending|in_progress|complete|failed", "completed_at": "ISO 8601|null"},
    "citation_bridge":  {"status": "pending|in_progress|complete|failed", "completed_at": "ISO 8601|null"},
    "arc_selection":    {"status": "pending|in_progress|complete|failed", "arc_id": "string|null"},
    "narrative":        {"status": "pending|in_progress|complete|failed", "completed_at": "ISO 8601|null"},
    "narrative_review": {"status": "pending|in_progress|complete|skipped", "score": "number|null"},
    "copywriter":       {"status": "pending|in_progress|complete|failed", "completed_at": "ISO 8601|null"},
    "derivatives":      {"status": "pending|in_progress|complete|skipped", "formats": ["string"]}
  }
}
```
