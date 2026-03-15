# Model Strategy Reference

## 3-Tier LLM Mapping: GPT-Researcher → Claude Code

GPT-Researcher uses a 3-tier LLM strategy optimized for speed, reasoning depth, and cost.
This plugin maps those tiers to Claude models:

| GPT-R Tier | GPT-R Default | Purpose | Claude Model | Rationale |
|------------|--------------|---------|--------------|-----------|
| **FAST_LLM** | gpt-4o-mini | Parallel search + summarize | **sonnet** | Sonnet produces richer context, more diverse sources, and better findings extraction. The quality gap vs haiku is significant — haiku researchers produced 40% fewer sources in testing. |
| **SMART_LLM** | gpt-4.1 | Report synthesis, review, revision | **sonnet** | Best quality/cost ratio. Handles synthesis, analytical review, and evidence-based revision. |
| **STRATEGIC_LLM** | o4-mini | Deep reasoning, planning | **sonnet** (skill context) | Orchestration runs in the main conversation context (already sonnet/opus). No separate agent needed. |

## Why Sonnet for Everything

All agents use sonnet. Earlier versions used haiku for parallel researchers to save cost, but testing showed haiku researchers produced 40% fewer unique sources, thinner context, and shorter reports. The quality improvement from sonnet researchers more than justifies the additional cost:

1. Sonnet researchers generate better search queries, fetch more diverse sources, and extract richer findings
2. Richer research context enables the writer to produce more substantive reports
3. The cost increase is modest (~3x per researcher) but the quality difference is dramatic

## Cost Estimation

| Report Type | Agents | Researcher Agents | Pipeline Agents | Estimated Cost |
|-------------|--------|-------------------|-----------------|----------------|
| Basic | ~7 | 3-5 (sonnet) | 2-3 (writer, reviewer, revisor) | ~$0.15-0.40 |
| Detailed | ~15 | 5-10 (sonnet) | 4-6 (writer, extractor, reviewer, revisor) | ~$0.40-0.80 |
| Deep | ~25 | 10-20 (sonnet) | 4-6 (writer, extractor, reviewer, revisor) | ~$0.80-1.50 |
| Outline | ~6 | 3-5 (sonnet) | 1-2 (writer, reviewer) | ~$0.10-0.30 |
| Resource | ~6 | 3-5 (sonnet) | 1-2 (writer, reviewer) | ~$0.10-0.30 |
| Basic (hybrid) | ~12 | 5-10 (sonnet, web+local) | 2-3 (writer, reviewer, revisor) | ~$0.30-0.70 |

## Design Divergences from GPT-Researcher

### Claims-Verified Review Loop (cogni-works Original)

GPT-Researcher uses a human-in-the-loop LangGraph workflow where a human reviews the research plan and can request revisions. This plugin replaces that with an automated claims-verified review loop:

1. A claim-extractor agent identifies verifiable factual assertions in the draft
2. cogni-claims fetches original source URLs and compares claims against source content
3. A reviewer agent evaluates both structural quality and factual accuracy
4. A revisor agent incorporates feedback, with WebSearch access to find replacement evidence

This design trades human judgment for automated source verification, enabling fully autonomous report generation while maintaining factual accuracy through evidence-based quality gates.
