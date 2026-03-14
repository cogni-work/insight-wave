# Enhancing LLM Web Search: A Technical Improvement Guide

The most impactful improvements to your LLM-driven research workflow come from **adaptive query generation** (reducing rewrites by 40% while improving performance), **cross-encoder reranking** (boosting NDCG@10 by 10-15%), and **semantic deduplication** (cosine threshold 0.92). Current research reveals that the PICOT framework should prioritize only Population + Intervention elements—including Outcomes in search queries actually **reduces recall** according to Cochrane Handbook studies. Your current 5-7 search configuration approach aligns well with DMQR-RAG findings showing diminishing returns after 4-6 variants.

---

## Query formulation should adapt to search intent

Recent SIGIR research establishes a **cross-over point at approximately 3 words** where queries shift from broad to narrow. Your current length guidelines (20-50 chars for keyword, 50-100 for focused, 100-200 for natural language) align with academic findings, but should be applied dynamically based on initial result quality.

**BM25 remains the optimal first-stage scorer** with parameters k1=1.2 and b=0.75 as defaults. For snippet-based relevance scoring, apply this formula against search result snippets treating each as a mini-document. The algorithm's term frequency saturation and length normalization properties make it superior to simple TF-IDF for ranking tasks.

Query expansion should use **weighted term injection**: original terms receive weight 1.0, direct synonyms 0.5, and hypernym/hyponym expansions 0.25. The Rocchio algorithm's pseudo-relevance feedback approach (assuming top-k results are relevant, extracting top 20 terms for expansion) demonstrates **up to 20% retrieval improvement** in TREC evaluations. However, limit expansion to 3-5 terms per original term to avoid query drift.

Temporal modifiers present a nuanced tradeoff. LLM reranking studies from Waseda University (Fang et al., 2025) reveal **strong recency bias**—top-10 results can shift 1-5 years newer, with 25% probability of the system preferring newer, lower-quality content. For time-sensitive topics (technology, policy), explicit year addition improves relevance. For evergreen topics (history, foundational concepts), **avoid year modifiers entirely** as they inappropriately deprioritize authoritative older sources.

---

## Domain filtering strategies require hybrid approaches

The blocklist versus allowlist decision should follow a clear heuristic: use **blocklists for general exploration** where diversity matters, and **allowlists for high-stakes domains** (healthcare, finance, legal) where accuracy is paramount and source credibility must be auditable.

For healthcare queries, the optimal allowlist includes: nih.gov, cdc.gov, fda.gov, pubmed.ncbi.nlm.nih.gov, cochranelibrary.com, nejm.org, jamanetwork.com, bmj.com, thelancet.com, mayoclinic.org. For finance: sec.gov, federalreserve.gov, treasury.gov, nber.org, ssrn.com, bloomberg.com, reuters.com. For technology research: arxiv.org, acm.org, ieee.org, semanticscholar.org.

Domain authority metrics (Moz DA, Ahrefs DR, SEMrush Authority Score) should be used **as screening signals, not definitive judgments**. Google officially denies using domain authority as a ranking factor, though John Mueller confirms a similar internal "sitewide score." A soft threshold of **DA > 50** provides reasonable quality filtering without excessive restriction.

Localization without API parameters works best through **query-based geographic injection** combined with TLD filtering. Adding country names to queries provides the highest specificity, followed by city/region names for local topics, then country-specific terminology. The bilingual strategy should prioritize English first for global research coverage, then native language for local regulations and cultural context. Technical/scientific topics typically need only English; legal/regulatory topics require native language as essential.

---

## Result quality improves through multi-stage processing

The optimal quality pipeline follows five stages: **bi-encoder retrieval → URL deduplication → cross-encoder reranking → near-duplicate detection → semantic deduplication**.

For cross-encoder reranking, the top performers include BAAI/bge-reranker-large for accuracy and cross-encoder/ms-marco-MiniLM-L6-v2 for speed. Cross-encoders process query-document pairs together, capturing interactions that bi-encoders miss, but require O(n) forward passes—apply them to the **top 50-100 results only**.

**Reciprocal Rank Fusion (RRF)** provides the best cross-profile result merging with the formula: `RRF_score(d) = Σ 1/(k + rank_r(d))` where k=60 as the smoothing constant. RRF requires no tuning, works across different score scales, and outperforms linear score combination in practice. For profile-weighted fusion, multiply each contribution by a profile reliability weight (e.g., academic profile at 0.8, general at 0.6).

Near-duplicate detection should use a three-layer approach:

1. **Exact URL hash** (normalized for protocol, www, trailing slashes)
2. **SimHash or MinHash** for near-identical content (threshold: 3 bits Hamming distance or 0.8 Jaccard similarity)
3. **Semantic embedding similarity** for paraphrased content (cosine > 0.92)

For MinHash implementation, use 128-256 permutations with k=5 shingles. Google's production SimHash uses 64-bit fingerprints with k=3 bit difference threshold for their 8B web page corpus. The datasketch Python library provides efficient LSH-based MinHash indexing.

Your current quality threshold (≥3 usable results = success) needs refinement. Define "usable" through multiple criteria: cross-encoder score > 0.5, snippet length > 50 characters, not a deduplicated group member, and domain passes authority threshold.

---

## Multi-query strategies should embrace adaptive selection

The DMQR-RAG framework (2024) provides the most rigorous analysis: testing four rewriting strategies—General Query Rewriting, Keyword Rewriting, Pseudo-Answer Rewriting, and Core Content Extraction—reveals that **adaptive selection reduces rewrites by ~40%** (from 4 to average 2.45) while improving performance. The optimal rewrite count follows a Gaussian distribution where both too few and too many queries harm results.

For query diversity, maintain **< 30% lexical term overlap** between query pairs and **> 0.3 cosine distance** in embedding space. Use Maximal Marginal Relevance (MMR) scoring: `MMR(q) = λ × Relevance(q) - (1-λ) × max_sim(q, selected_queries)` with λ=0.7 for relevance-diversity balance.

The PICOT decomposition should be reconsidered based on systematic review research (PMC6148624). Cochrane Handbook recommends **P+I+S/T only**—including Outcomes in search reduces recall because outcomes often don't appear in abstracts. More search blocks inversely correlate with results. Structure facet-based queries as: primary (F1 AND F2 AND F3), relaxed variants (F1 AND F2, F1 AND F3, F2 AND F3), and expanded variants with synonyms.

Iterative refinement should follow a gap analysis pattern: execute initial queries, analyze retrieved document distribution via topic modeling, identify underrepresented facets, generate targeted queries, and continue until marginal recall gain drops below 5%. For query relaxation when results are sparse (< 5 documents or top-5 similarity < 0.3), follow: exact phrase → near phrase → AND combination → OR accumulation, removing most specific terms first while preserving core entities.

---

## LLM-specific patterns unlock significant optimization potential

Chain-of-thought query construction should decompose research questions into intermediate reasoning steps before generating search terms. The effective pattern: identify key concepts, determine most specific search terms, identify related context concepts, and establish relevant timeframe/filters—then generate 2-3 focused queries. Zero-shot CoT (adding "Let's think step by step") provides baseline improvement; few-shot CoT with example decompositions performs better for complex queries.

Self-critique loops follow the Self-Refine framework (Madaan et al., 2023): generate initial query, have the same LLM critique its output, then refine based on feedback. Effective critique requires **localization of problems, specific improvement instructions, and multi-dimensional evaluation**. The Reverse Chain of Thought pattern—generating an answer then reconstructing the query from it—identifies missed conditions and potential hallucinations.

For Anthropic's Claude web search specifically, several parameters optimize performance:

```python
tools=[{
    "type": "web_search_20250305",
    "name": "web_search",
    "max_uses": 5,  # Control search budget
    "allowed_domains": ["authoritative-source.com"],
    "blocked_domains": ["spam.com"],
    "user_location": {
        "type": "approximate",
        "city": "San Francisco",
        "region": "California", 
        "country": "US"
    }
}]
```

Claude's web search is powered by **Brave Search** (not Google/Bing), so content must be indexed there. The system supports agentic multi-search patterns where Claude conducts progressive searches autonomously. The November 2025 beta features—Tool Search Tool (85% token reduction, accuracy improvement from 49% to 74%) and Programmatic Tool Calling (37% token reduction)—provide significant efficiency gains for large tool libraries.

RAG best practices emphasize **HyDE (Hypothetical Document Embeddings)**: generate a hypothetical answer to the query, embed it, then retrieve documents similar to that embedding. This bridges the semantic gap between question-style queries and document-style answers. Apply hybrid search (keyword + semantic) with RRF fusion, then cross-encoder reranking on merged results.

---

## Implementation roadmap prioritizes high-impact changes

The highest ROI improvements based on this research:

**Immediate implementation** (high impact, low effort): Add BM25 snippet scoring with k1=1.2, b=0.75 as first-pass relevance filter. Implement RRF with k=60 for cross-profile fusion. Add cosine similarity threshold of 0.92 for semantic deduplication. Remove Outcome (O) from PICOT query generation.

**Short-term implementation** (high impact, medium effort): Deploy cross-encoder reranking (bge-reranker-large) on top-50 results. Implement adaptive query count selection starting at 4, reducing based on retrieval quality metrics. Add MinHash-based near-duplicate detection with 128 permutations, threshold 0.8.

**Medium-term implementation** (medium impact, higher effort): Build self-critique loops for query refinement with localized feedback patterns. Implement iterative refinement with gap analysis and topic modeling. Develop domain-specific allowlists with quarterly review cycles. Add chain-of-thought decomposition prompting for complex multi-facet queries.

**Quality metrics to track**: Query overlap should stay below 30% lexical, above 0.3 cosine distance. Result quality requires cross-encoder scores above 0.5 for "usable" classification. Intra-list diversity (ILD) should exceed 0.3 to ensure result heterogeneity. Coverage assessment should track unique domains and entity/topic coverage across result sets.

---

## Conclusion

The research reveals that your current workflow architecture is fundamentally sound, but several specific optimizations can significantly improve relevance. The most counterintuitive finding is that **reducing query complexity often improves results**—fewer PICOT elements, adaptive query count reduction, and focused rather than exhaustive search configurations. Cross-encoder reranking and semantic deduplication represent the highest-value additions to the execution phase. For LLM-specific optimization, the combination of chain-of-thought decomposition and self-critique loops provides systematic query improvement without requiring architectural changes. The Anthropic-specific parameters (max_uses, domain filtering, user_location) offer granular control that your current implementation can leverage immediately.