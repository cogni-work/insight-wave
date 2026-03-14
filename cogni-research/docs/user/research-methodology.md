# Research Methodology

cogni-research transforms research questions into traceable, source-backed insights through a 4-stage pipeline with three-layer claim assurance.

## How It Works

### 1. Plan Your Research

Tell cogni-research what you want to investigate. It will:
- Classify your question's depth (DOK level)
- Break it into 2-10 research dimensions using MECE analysis
- Generate 8-50 specific sub-questions
- Create optimized search queries for each question

### 2. Gather Evidence

The plugin searches the web and draws on LLM knowledge in parallel:
- Multiple search queries per question for comprehensive coverage
- Findings are linked to their original sources
- Sources are enriched with publisher profiles and APA citations
- Deduplication prevents counting the same source twice

### 3. Verify Claims

Every factual assertion is extracted and scored:
- **Evidence confidence**: How strong is the supporting evidence?
- **Claim quality**: Is the claim well-formed, atomic, and faithful to the source?
- **Source verification** (optional): Does the original URL actually say what we claim?

Claims with low confidence are flagged, not hidden.

### 4. Tell the Story

Research findings are synthesized into executive narratives using cogni-narrative's story arc frameworks:
- One narrative per research dimension
- One cross-dimensional narrative tying it all together
- Multiple derivative formats available (executive brief, talking points, one-pager)

## Research Types

### Generic
The default. Works for any topic. You choose the depth of knowledge level (DOK 1-4):
- DOK-1: Recall — surface-level fact gathering
- DOK-2: Concept — understanding relationships and patterns
- DOK-3: Strategic — analysis and evidence evaluation
- DOK-4: Extended — synthesis across multiple sources and timeframes

### Lean Canvas
Structured around the 9-block lean canvas model. Automatically DOK-2. Dimensions map to: Problem, Solution, Key Metrics, Unique Value Proposition, Unfair Advantage, Channels, Customer Segments, Cost Structure, Revenue Streams.

### B2B ICT Portfolio
Structured around 8 B2B ICT provider dimensions. Automatically DOK-3. Used for analyzing technology portfolios and competitive positioning in the ICT sector.

## Trust & Provenance

Every claim in the final output traces back to its source through an unbroken chain:

```
Claim → Finding → Source (URL + Publisher + Citation)
```

This chain is maintained via Obsidian-compatible wikilinks, so you can browse the full provenance graph in Obsidian.

## Output Formats

- **Markdown narratives**: Per-dimension and cross-dimensional insight summaries
- **HTML report**: Interactive web page with verification badges
- **PDF report**: Formal A4 document with cover page
- **RAG export**: Flat markdown optimized for retrieval-augmented generation
