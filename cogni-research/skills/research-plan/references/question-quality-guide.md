# Question Quality Guide

How to refine a research question so it produces sharp dimensions, focused queries, and high-signal findings.

## Four Properties of a Good Research Question

1. **Specific** — Names the domain, population, or technology. Not "How does AI affect business?" but "How are pharma companies using AI/ML for drug target identification?"
2. **Scoped** — Has clear boundaries (temporal, geographic, or domain). Not "everything about renewable energy" but "wind energy cost trends in European markets since 2020."
3. **Decomposable** — Can be broken into 2-10 independent dimensions. If you cannot imagine at least 2 distinct angles, the question is too narrow. If it spans more than 10, it is too broad.
4. **Answerable** — Evidence exists or can be gathered via web search. Purely speculative questions ("What will happen in 2050?") produce low-quality findings.

## Good vs. Bad Questions

**Bad:** "What is AI?"
**Good:** "How are large language models changing customer service automation in European banking, and what ROI evidence exists?"
**Why:** Specific domain (banking), specific technology (LLMs), specific application (customer service), measurable outcome (ROI).

**Bad:** "Tell me about electric vehicles."
**Good:** "What factors are driving or hindering EV adoption among commercial fleet operators in Germany, and how do TCO comparisons with diesel vary by vehicle class?"
**Why:** Scoped population (fleet operators), scoped geography (Germany), decomposable (drivers, barriers, TCO by class).

**Bad:** "Is quantum computing useful?"
**Good:** "Which near-term quantum computing applications (2024-2028) show credible advantage over classical approaches in drug discovery, materials science, and financial modeling?"
**Why:** Time-bounded, specific domains listed, answerable criterion (credible advantage = evidence-based).

## DOK Level Selection

DOK (Depth of Knowledge) controls how many dimensions and questions the dimension-planner creates. For the full framework with examples, see `${CLAUDE_PLUGIN_ROOT}/references/dok-classification.md`.

**Quick decision tree:**
- **DOK-1 (Recall):** User wants facts, definitions, or market sizing. 2-3 dimensions, 8-12 questions.
- **DOK-2 (Skills):** User wants comparisons, framework application, or classification. 3-4 dimensions, 15-20 questions.
- **DOK-3 (Strategic):** User wants multi-source synthesis, pattern identification, or strategic analysis. 5-7 dimensions, 25-35 questions. *Most common for business research.*
- **DOK-4 (Extended):** User wants cross-disciplinary investigation, scenario modeling, or theoretical framework development. 8-10 dimensions, 40-50 questions.

**Key distinction:** DOK measures complexity, not difficulty. Finding an obscure statistic is difficult but DOK-1 (retrieval). Synthesizing regulatory, economic, and cultural factors is DOK-3+ (requires judgment across sources).

## Research Type Selection

| Choose this type | When the user wants... |
|------------------|------------------------|
| `generic` | Flexible research on any topic — DOK is variable |
| `lean-canvas` | Business model analysis using the 9-block canvas framework |
| `b2b-ict-portfolio` | ICT provider analysis using the 8-dimension portfolio taxonomy |

If the user mentions "business model", "startup", "value proposition", or "canvas" — suggest `lean-canvas`.
If the user mentions a specific B2B ICT provider, portfolio, or technology stack — suggest `b2b-ict-portfolio`.
Otherwise, default to `generic` and ask about DOK level.
