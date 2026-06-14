---
name: deliverable-types
description: Catalog of deliverable types with field-type affinity — the reference for which deliverable types belong in which kind of action field.
---

# Deliverable Types

Action fields are the WBS containers of an engagement; each field holds the
deliverables that answer its framing. This catalog lists the deliverable types
available when planning a field's deliverable set, with the **field-type
affinity** that suggests where each type naturally belongs. It adapts
a deliverable-type catalog: where a Double Diamond model keys deliverables to
phases, cogni-consult keys them to the *kind of action field*
they serve — there are no phases here.

## Field Types

Action fields tend to cluster into four kinds. The affinity column below uses
these labels; a field can match more than one kind, and the consultant always
decides.

| Field type | The field asks... | Example fields |
|---|---|---|
| `evidence` | What is true out there? | market-evidence, customer-insight, regulatory-landscape |
| `analysis` | What does it mean for us? | portfolio-fit, capability-gap, risk-exposure |
| `strategy` | What should we do? | strategic-options, business-model, positioning |
| `execution` | How do we make it happen? | go-to-market, transformation-plan, operating-model |

## Deliverable Catalog

| Deliverable | Description | Formats | Field-type affinity |
|---|---|---|---|
| Market Assessment | Market size, dynamics, and entry barriers | DOCX, PPTX | evidence |
| TIPS Landscape | Trend/implication/possibility map | MD, Excalidraw | evidence |
| Claim Verification Log | Audit trail of verified/flagged assertions | MD, XLSX | evidence |
| Portfolio Snapshot | Competitive positioning and value wedge | XLSX, PPTX | analysis |
| Scenario Matrix | 2×2 scenario analysis with implications | PPTX, Excalidraw | analysis |
| Canvas Stress-Test Report | Multi-persona evaluation with synthesis | MD | analysis |
| Strategic Options Brief | Ranked alternatives with evaluation criteria | PPTX, DOCX | strategy |
| Decision Board | Visual option map with recommendation | Excalidraw, SVG | strategy |
| Lean Canvas | Research-backed business model hypothesis | MD | strategy |
| Solution Brief | Designed solution with rationale and design decisions | MD, DOCX | strategy |
| Business Case | Financials, assumptions, sensitivity analysis | XLSX + DOCX | strategy |
| Executive Summary | One-pager for leadership alignment | PPTX, PDF | strategy, execution |
| Action Roadmap | Phased implementation plan with milestones | PPTX, XLSX | execution |
| Action Plan | Phased steps with owners, timeline, and success criteria | MD, XLSX | execution |
| Cost Reduction Playbook | Prioritized savings opportunities with implementation | XLSX, DOCX | execution |
| Transformation Roadmap | Current→target state with transition phases | PPTX, Excalidraw | execution |

## Using the Catalog

When planning a field's deliverable set with `consult-action-fields`:

1. Read the field's `framing` line and judge which field type(s) it matches.
2. Propose 1-3 deliverables whose affinity matches, naming each with a
   kebab-case slug derived from the deliverable title.
3. Let the consultant add, rename, or drop freely — affinity is a starting
   recommendation, not a constraint. Engagement-specific deliverables outside
   this catalog are normal; give them a clear title and slug like any other.
4. Record the chosen format preference in the deliverable's markdown artifact
   when it is produced, not in `field.json` — the manifest tracks state, not
   formats.

Every deliverable runs its own design-thinking loop regardless of type
(`dt_stage` in `field.json`); the catalog only helps choose *what* to produce
per field, never *how*.
