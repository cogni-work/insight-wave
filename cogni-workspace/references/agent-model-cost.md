# Agent Model Cost Reference

The single canonical source of truth for **which model tier each agent role uses** and **how to turn an agent's word counts into a USD `cost_estimate`**. Research agents emit `cost_estimate` in their output JSON; orchestrators accumulate these into a per-run total. Cite this file by its repo-relative path (`cogni-workspace/references/agent-model-cost.md`) rather than duplicating the coefficients inline, so a rate change lands in exactly one place.

## Role → model strategy

Mirrors the root `CLAUDE.md` § "Agent Model Strategy" (the authority). Keep the two in lockstep.

| Role | Model | Rationale |
|------|-------|-----------|
| Orchestration | sonnet (skill context) | Phase dispatch, sub-question generation |
| Research | sonnet | Web research, section researchers, deep researchers |
| Heavy synthesis | opus | Demanding rewrites (cogni-copywriting), 60-candidate scoring (cogni-trends) |
| Quality assessment | haiku | High-volume rubric evaluation (3-5 dimensions per entity) |
| Content generation | sonnet | Narrative writers, report writers, content writers |

**How to pick when building a new agent:** default to sonnet; promote to opus only if a sonnet test fails on quality (tone-critical rewrites, multi-axis scoring across many candidates); demote to haiku only when sonnet's output never differs meaningfully from haiku's at the agent's volume (high-volume rubric scoring).

## Per-word → USD cost formula

Research agents report input/output **word** counts; convert to tokens, then to USD.

**1. Words → tokens**

```
tokens ≈ words × 0.75          # ≈ 1.33 words per token
```

**2. Tokens → USD**

```
USD = (input_tokens  / 1_000_000) × input_rate
    + (output_tokens / 1_000_000) × output_rate
```

`input_rate` / `output_rate` are the per-million-token rates for the agent's model tier (below).

## Per-model rates (USD per million tokens)

| Model | Input $/MTok | Output $/MTok |
|-------|-------------:|--------------:|
| Sonnet (Claude Sonnet) | 3.00 | 15.00 |
| Opus (Claude Opus 4.x) | 15.00 | 75.00 |
| Haiku (Claude Haiku 4.5) | 1.00 | 5.00 |

These are published **list prices**. Verify the current figures against <https://www.anthropic.com/pricing> before relying on them for billing — the coefficients here are for producing an *estimate*, not an invoice. Prompt caching and batch discounts are out of scope for the `cost_estimate` figure (it models the un-cached, non-batched cost).

## Worked example

A research agent (sonnet) consumes **2,000 input words** and emits **800 output words**:

```
input_tokens  = 2000 × 0.75 = 1500
output_tokens =  800 × 0.75 =  600
USD = (1500 / 1e6) × 3.00 + (600 / 1e6) × 15.00
    = 0.0045 + 0.0090
    = $0.0135
```

So the agent reports `cost_estimate ≈ $0.014`. An orchestrator running twenty such agents accumulates `≈ $0.27` for the research phase.

## Consumers

Any agent or skill that computes a `cost_estimate`, or that documents a role → model choice, should cite this file rather than restating the table or the coefficients. Inline duplications drift; a single canonical reference does not.
