# cogni-canvas Data Model Reference

## Canvas Structure

Canvases are single markdown files with YAML frontmatter. There is no multi-file project structure — each canvas is self-contained.

```
{project-dir}/
└── lean-canvas-{slug}.md                  # Complete canvas with metadata + content + evolution log
```

## Entity Schema

### Canvas File

A canvas file combines three layers: YAML frontmatter for metadata and status tracking, 9 numbered markdown sections for content, and an evolution log for version history.

```yaml
---
canvas: lean
version: 3
created: 2026-03-21
updated: 2026-03-21
status:
  problem: filled
  customer_segments: filled
  uvp: draft
  solution: unfilled
  channels: unfilled
  revenue_streams: unfilled
  cost_structure: unfilled
  key_metrics: unfilled
  unfair_advantage: unfilled
---
```

#### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `canvas` | Yes | Canvas type — always `lean` (reserved for future BMC support) |
| `version` | Yes | Integer, incremented on each substantive revision |
| `created` | Yes | ISO date of first version |
| `updated` | Yes | ISO date of last modification |
| `status` | Yes | Per-section status map (see below) |

#### Section Status Values

| Status | Meaning |
|--------|---------|
| `filled` | Section has specific, substantive content |
| `draft` | Section has initial content that needs refinement |
| `unfilled` | Section is empty or contains only "?" |

### Canvas Sections

The 9 standard Lean Canvas sections, always in this order:

| # | Section | Key Question |
|---|---------|-------------|
| 1 | Problem | What are the top 1-3 problems your customers face? |
| 2 | Customer Segments | Who are your target customers? |
| 3 | Unique Value Proposition | What's the single clear message that states why you're different and worth buying? |
| 4 | Solution | What are the top features or capabilities that solve the problems? |
| 5 | Channels | How do you reach your customers? |
| 6 | Revenue Streams | How do you make money? |
| 7 | Cost Structure | What are your fixed and variable costs? |
| 8 | Key Metrics | What numbers tell you the business is working? |
| 9 | Unfair Advantage | What can't be easily copied or bought? |

### Evolution Log

Appended after the 9 sections. Records what changed and why across versions.

```markdown
## Canvas Evolution

### Version N — Title
**Date**: YYYY-MM-DD
**Key Insight**: What prompted this revision
**Changes**: What changed and why

### Key Assumptions to Validate
1. Assumption with testable criteria

### Next Iterations
- What to test or refine next
```

| Field | Required | Description |
|-------|----------|-------------|
| Version title | Yes | Short label for this revision |
| Date | Yes | ISO date of this version |
| Key Insight | Yes | The insight or feedback that prompted changes |
| Changes | Yes | What changed and why |
| Key Assumptions | No | Testable hypotheses to validate |
| Next Iterations | No | Planned next steps |

## Version Bump Rules

Increment `version` when:
- Any section content changes substantively (not just typos)
- A previously unfilled section gets content
- The evolution log records a new insight

Do NOT bump version for formatting-only changes or adding frontmatter to an existing canvas.

## Cross-Plugin Integration

| Target Plugin | Direction | Contract |
|---------------|-----------|----------|
| cogni-portfolio | Export | `portfolio-canvas` skill extracts products, features, and markets from the canvas for downstream messaging workflows |
| cogni-portfolio | Validate | `markets` (TAM/SAM/SOM) and `compete` (competitive landscape) validate canvas assumptions with real data |

See [canvas-format.md](canvas-format.md) for the full file format specification and [lean-canvas-sections.md](lean-canvas-sections.md) for section quality criteria and common pitfalls.
