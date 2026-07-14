---
id: concept-agent-model-strategy
title: Agent model strategy (sonnet/opus/haiku per role)
type: concept
tags: [agents, models, sonnet, opus, haiku, cost]
created: 2026-04-17
updated: 2026-04-17
sources:
  - https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md
status: stable
---

Agents pick model tiers by role across insight-wave, with cost-per-task as the deciding factor.

## The matrix

| Role | Model | Rationale |
|------|-------|-----------|
| Orchestration | sonnet (skill context) | Phase dispatch, sub-question generation |
| Research | sonnet | Web research, section researchers, deep researchers |
| Heavy synthesis | opus | Demanding rewrites (cogni-copywriting), 60-candidate scoring (cogni-trends) |
| Quality assessment | haiku | High-volume rubric evaluation (3-5 dimensions per entity) |
| Content generation | sonnet | Narrative writers, report writers, content writers |

## Why each pick

- **sonnet** is the default for anything that needs solid reasoning at moderate volume — research, synthesis, content generation.
- **opus** comes out for the hard cases: demanding rewrites where tone subtleties matter (cogni-copywriting), or multi-axis scoring across many candidates (cogni-trends scoring 60 candidates).
- **haiku** is the workhorse for high-volume rubric evaluation. The [[concept-quality-gates]] pattern fires haiku assessors across many entities and many dimensions; sonnet would be cost-prohibitive at that scale.

## Cost telemetry

Research agents report `cost_estimate` in their output JSON — input/output words plus an estimated USD figure. Orchestrating skills accumulate these so a complete pipeline run can quote a total cost back to the user.

The canonical role→model strategy table and the per-word→USD cost formula (token conversion, per-model list rates, and a worked example) live in `cogni-workspace/references/agent-model-cost.md` — cite that reference rather than duplicating the coefficients.

## How to apply this when building a new agent

Pick the cheapest model that passes a representative test of the agent's actual work. Default to sonnet; promote to opus only if a haiku/sonnet test fails on quality, demote to haiku only if sonnet's output never differs meaningfully from haiku's at the agent's volume.

**Source**: [insight-wave/CLAUDE.md on GitHub](https://github.com/cogni-work/insight-wave/blob/main/CLAUDE.md)
