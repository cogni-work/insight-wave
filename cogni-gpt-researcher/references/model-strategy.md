# Model Strategy Reference

## 3-Tier LLM Mapping: GPT-Researcher → Claude Code

GPT-Researcher uses a 3-tier LLM strategy optimized for speed, reasoning depth, and cost.
This plugin maps those tiers to Claude models:

| GPT-R Tier | GPT-R Default | Purpose | Claude Model | Rationale |
|------------|--------------|---------|--------------|-----------|
| **FAST_LLM** | gpt-4o-mini | Quick parallel search + summarize | **haiku** | Cheapest, fastest. Perfect for parallel web research where 5-15 instances run simultaneously. |
| **SMART_LLM** | gpt-4.1 | Report synthesis, review, revision | **sonnet** | Best quality/cost ratio. Handles synthesis, analytical review, and evidence-based revision. |
| **STRATEGIC_LLM** | o4-mini | Deep reasoning, planning | **sonnet** (skill context) | Orchestration runs in the main conversation context (already sonnet/opus). No separate agent needed. |

## Why No Opus

GPT-Researcher's STRATEGIC tier uses o4-mini (a reasoning model) for sub-question generation.
In Claude Code, this planning step runs in the skill's main conversation context, which is already
the user's configured model (typically sonnet or opus). No dedicated opus agent is needed because:

1. Sub-question generation doesn't require opus-level reasoning — sonnet handles it well
2. The cost savings are significant when generating 15-20 agent spawns per report
3. The review loop provides quality assurance that compensates for any reasoning gap

## Cost Estimation

| Report Type | Agents | Haiku Agents | Sonnet Agents | Estimated Cost |
|-------------|--------|-------------|---------------|----------------|
| Basic | ~7 | 3-5 researchers | 2-3 (writer, reviewer, revisor) | ~$0.05-0.15 |
| Detailed | ~15 | 5-10 researchers | 4-6 (writer, extractor, reviewer, revisor) | ~$0.15-0.40 |
| Deep | ~25 | 10-20 deep-researchers | 4-6 (writer, extractor, reviewer, revisor) | ~$0.30-0.80 |

Note: Deep-researchers use sonnet (not haiku) because they perform internal recursion.
