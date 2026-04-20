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
| Basic (hybrid) | ~9-12 | 5-9 (sonnet — N web + 1-4 wiki + 1-4 local under asymmetric allocation) | 2-3 (writer, reviewer, revisor) | ~$0.22-0.55 |
| Detailed | ~15 | 5-10 (sonnet) | 4-6 (writer, extractor, reviewer, revisor) | ~$0.40-0.80 |
| Detailed (hybrid) | ~14-20 | 8-14 (sonnet — N web + 1-4 wiki + 1-4 local) | 4-6 (writer, extractor, reviewer, revisor) | ~$0.50-1.10 |
| Deep | ~25 | 10-20 (sonnet) | 4-6 (writer, extractor, reviewer, revisor) | ~$0.80-1.50 |
| Deep (hybrid) | ~22-32 | 16-28 (sonnet — N web + 1-4 wiki + 1-4 local; bigger N dominates, wiki/local capped at 4 each) | 4-6 (writer, extractor, reviewer, revisor) | ~$1.10-2.00 |
| Outline | ~6 | 3-5 (sonnet) | 1-2 (writer, reviewer) | ~$0.10-0.30 |
| Resource | ~6 | 3-5 (sonnet) | 1-2 (writer, reviewer) | ~$0.10-0.30 |

### Why the hybrid rows are lower than you'd expect

Before v0.7.14, hybrid mode dispatched `N × number_of_channels` researchers: 8 sub-questions × 3 channels = 24 researcher agents, each re-reading the same wiki index and same local documents. That symmetry made sense for web (where every sub-question needs its own queries and source discovery) but not for wiki and local, which operate over bounded, shared corpora.

Since v0.7.14, `research-report` Phase 1.5a computes `channel_agents` asymmetrically:

- **Web**: always `N` agents, one per sub-question (unchanged).
- **Wiki**: `clamp(ceil(wiki_page_count / 40), 1, min(N, 4))` agents. Each agent reads the wiki index once and extracts findings for **all** sub-questions in a single pass.
- **Local**: `clamp(ceil(document_count / 25), 1, min(N, 4))` agents. Each agent runs one Document Relevance Assessment pass over its document slice and emits per-sub-question findings.

The cap at 4 agents per bounded channel is deliberate: beyond 4 agents the corpus sweep is already paralellized enough, and the incremental cost of one more index read rarely pays for itself. For small runs (`N < 4`) the symmetric allocation is preserved — savings are marginal there and the simpler code path is worth keeping.

Ranges in the hybrid rows above assume typical corpus sizes (10–60 docs, 30–200 wiki pages). A power-user project with 500+ wiki pages or 200+ documents will land near the upper bound of its row because the heuristic saturates at the 4-agent cap; a light project with a handful of files lands near the lower bound.

## Runtime Cost Tracking

Each agent reports a `cost_estimate` field in its output JSON, enabling the orchestrator to accumulate total research cost. The estimate is word-count-based — imprecise but directionally correct and zero-dependency.

### Estimation Formula

```
tokens ≈ words × 0.75
input_cost  = input_tokens × (input_price_per_mtok / 1_000_000)
output_cost = output_tokens × (output_price_per_mtok / 1_000_000)
cost_estimate = input_cost + output_cost
```

### Sonnet Pricing (as of 2026-03)

| Direction | Price per MTok |
|-----------|---------------|
| Input     | $3.00          |
| Output    | $15.00         |

### How Agents Report Cost

Every agent's compact JSON output includes:

```json
{
  "ok": true,
  "cost_estimate": {
    "input_words": 12000,
    "output_words": 3000,
    "estimated_usd": 0.061
  },
  ...
}
```

- `input_words`: approximate word count of all content read/received by the agent (sub-question + fetched pages + context)
- `output_words`: approximate word count of all content produced (entities + synthesis)
- `estimated_usd`: computed via the formula above

### Orchestrator Accumulation

In Phase 6, the orchestrator sums `estimated_usd` from all agent outputs and writes to `execution-log.json`:

```json
{
  "cost_summary": {
    "total_estimated_usd": 0.42,
    "breakdown": {
      "researchers": 0.28,
      "writer": 0.08,
      "reviewer": 0.03,
      "revisor": 0.02,
      "claim_extractor": 0.01
    }
  }
}
```

This is reported to the user in the Phase 6 summary alongside word count and source stats.

## Design Divergences from GPT-Researcher

### Claims-Verified Review Loop (insight-wave Original)

GPT-Researcher uses a human-in-the-loop LangGraph workflow where a human reviews the research plan and can request revisions. This plugin replaces that with an automated claims-verified review loop:

1. A claim-extractor agent identifies verifiable factual assertions in the draft
2. cogni-claims fetches original source URLs and compares claims against source content
3. A reviewer agent evaluates both structural quality and factual accuracy
4. A revisor agent incorporates feedback, with WebSearch access to find replacement evidence

This design trades human judgment for automated source verification, enabling fully autonomous report generation while maintaining factual accuracy through evidence-based quality gates.
