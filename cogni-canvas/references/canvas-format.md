# Lean Canvas File Format

## File Structure

A lean canvas is a markdown file with YAML frontmatter for metadata and numbered markdown sections for content.

### YAML Frontmatter

```yaml
---
canvas: lean
version: 1
created: 2025-01-16
updated: 2025-01-16
status:
  problem: filled | unfilled | draft
  customer_segments: filled | unfilled | draft
  uvp: filled | unfilled | draft
  solution: filled | unfilled | draft
  channels: filled | unfilled | draft
  revenue_streams: filled | unfilled | draft
  cost_structure: filled | unfilled | draft
  key_metrics: filled | unfilled | draft
  unfair_advantage: filled | unfilled | draft
---
```

**Field definitions**:
- `canvas`: Always `lean` (reserved for future BMC support)
- `version`: Integer, incremented on each significant revision
- `created`: ISO date of first version
- `updated`: ISO date of last modification
- `status`: Per-section status tracking
  - `filled` — section has substantive content
  - `draft` — section has initial content that needs refinement
  - `unfilled` — section is empty or contains only "?"

### Section Headings

Use numbered H2 headings for the 9 sections, always in this order:

```markdown
## 1. Problem
## 2. Customer Segments
## 3. Unique Value Proposition
## 4. Solution
## 5. Channels
## 6. Revenue Streams
## 7. Cost Structure
## 8. Key Metrics
## 9. Unfair Advantage
```

### Evolution Log

Append an evolution log after the 9 sections:

```markdown
---

## Canvas Evolution

### Version N — Title
**Date**: YYYY-MM-DD
**Key Insight**: What prompted this revision
**Changes**: What changed and why

### Key Assumptions to Validate
1. Assumption with testable criteria
2. ...

### Next Iterations
- What to test or refine next
```

## Status Inference Rules

When reading an existing canvas without frontmatter, infer section status:
- Section contains only "?" or is missing → `unfilled`
- Section has content but is vague or incomplete → `draft`
- Section has specific, substantive content → `filled`

## Version Bump Rules

Increment `version` when:
- Any section content changes substantively (not just typos)
- A previously unfilled section gets content
- The evolution log records a new insight

Do NOT bump version for:
- Formatting-only changes
- Adding frontmatter to an existing canvas
- Updating the evolution log without content changes

## Example: Minimal Canvas

```markdown
---
canvas: lean
version: 1
created: 2025-03-21
updated: 2025-03-21
status:
  problem: draft
  customer_segments: unfilled
  uvp: unfilled
  solution: unfilled
  channels: unfilled
  revenue_streams: unfilled
  cost_structure: unfilled
  key_metrics: unfilled
  unfair_advantage: unfilled
---
# LEAN Canvas v1 - [Project Name]

## 1. Problem
- Initial problem hypothesis here

## 2. Customer Segments
- ?

## 3. Unique Value Proposition
- ?

## 4. Solution
- ?

## 5. Channels
- ?

## 6. Revenue Streams
- ?

## 7. Cost Structure
- ?

## 8. Key Metrics
- ?

## 9. Unfair Advantage
- ?

---

## Canvas Evolution

### Version 1 — Initial Draft
**Date**: 2025-03-21
**Key Insight**: Starting hypothesis
**Changes**: Initial canvas creation
```
