# FINER Criteria - Implementation Reference

## Purpose

Apply FINER quality assessment to research questions during dimension-planner Phase 4 validation. Score each question on 5 criteria (Feasible, Interesting, Novel, Ethical, Relevant) to ensure research plan quality.

**When to use:** After generating refined research questions, before proceeding to question entity creation.

---

## Scoring Workflow

For each refined research question:

1. Score each criterion using rubrics below (1-3 points each)
2. Calculate total (sum of 5 scores, range: 5-15)
3. Determine priority: ≥13 (high), 10-12 (medium), <10 (reformulate)
4. Document scores in question entity frontmatter
5. Calculate average across all questions as quality metric

---

## Criterion 1: Feasible (F)

Can this question be answered with available resources, tools, and time constraints?

### Scoring Rubric

**Score 3 (Strong):** Answerable via systematic web search with multiple authoritative sources (3+), standard tools, no proprietary data, reasonable time (hours-days), clear success criteria

**Score 2 (Moderate):** Limited sources (1-2), may require specialized databases, some uncertainty about data availability, moderate time (days), somewhat ambiguous success criteria

**Score 1 (Weak):** Requires proprietary/restricted data, expert interviews needed, highly specialized knowledge, unclear if answerable, excessive time (weeks+), no clear path

### Examples

**Example 1 (Score 3):** "What are the top 5 enterprise CRM platforms by market share in 2024?" - Multiple industry reports (Gartner, IDC), standard web search, clear criteria (5 platforms with percentages), hours to answer

**Example 2 (Score 1):** "What is Salesforce's exact R&D budget allocation across product lines for 2024?" - Proprietary internal data, not publicly disclosed, insider access required

---

## Criterion 2: Interesting (I)

Does this question engage stakeholders and address real needs?

### Scoring Rubric

**Score 3 (Strong):** Directly addresses stakeholder pain points, high practical value (results inform decisions), answers actively used, timely and relevant, broad appeal

**Score 2 (Moderate):** Moderately interesting, some practical value (nice to know), may inform secondary decisions, limited audience appeal, somewhat tangential

**Score 1 (Weak):** Low stakeholder interest, purely academic with no practical application, answers obvious or already known, disconnected from real needs, trivial inquiry

### Examples

**Example 1 (Score 3):** "What are the key drivers of residential solar adoption in Germany (2020-2024)?" - Addresses adoption barriers/enablers, high practical value for policy planning, timely with EU climate goals

**Example 2 (Score 1):** "What was the exact date of the first commercial solar panel installation in Germany?" - Historical trivia, no practical application, no decision-making value

---

## Criterion 3: Novel (N)

Does this question add new knowledge or trends?

### Scoring Rubric

**Score 3 (Strong):** Explores new territory or emerging trends, unique perspective, non-redundant with other questions, fills identified knowledge gap, contributes unique value

**Score 2 (Moderate):** Some originality (new angle on known topic), updates existing knowledge with current data, minor overlap, incremental knowledge gain

**Score 1 (Weak):** Highly redundant with other questions, well-known answer, no new trends expected, duplicates existing research, trivial variation

### Examples

**Example 1 (Score 3):** "How do behavioral nudges impact residential renewable energy adoption compared to financial incentives?" - Unique angle (behavioral vs financial), explores emerging research area, fills gap in adoption psychology understanding

**Example 2 (Score 1):** "What are the costs for residential solar panels in Germany?" (when another question asks "What are installation costs...") - Highly redundant, no new angle

---

## Criterion 4: Ethical (E)

Does this research comply with ethical standards and avoid harm?

### Scoring Rubric

**Score 3 (Strong):** No ethical concerns, respects privacy/confidentiality, uses only publicly available data, no potential for harm or misuse, complies with research ethics

**Score 2 (Moderate):** Minor ethical considerations, requires careful data handling, potential for misuse if not contextualized, some privacy considerations (anonymized data)

**Score 1 (Weak):** Significant ethical concerns, privacy violations, potential for harm (misinformation, discrimination), requires restricted/sensitive data

**Note:** For web-based research using publicly available data, most questions score 3. This criterion is more critical for primary research involving human subjects or sensitive topics.

### Examples

**Example 1 (Score 3):** "What are the economic benefits of renewable energy adoption in residential markets?" - Public market data, no privacy concerns, standard ethics

**Example 2 (Score 1):** "What are the addresses and income levels of all solar panel installations in Berlin?" - Privacy violation, potential for targeting/harassment, GDPR non-compliant

---

## Criterion 5: Relevant (R)

Does this question address significant aspects of the core research question?

### Scoring Rubric

**Score 3 (Strong):** Directly answers core research question elements, critical for complete understanding, addresses primary stakeholder needs, core component of expected output, high impact on synthesis

**Score 2 (Moderate):** Moderately relevant, provides supporting information or context, adds value but not essential, secondary priority, moderate impact on synthesis

**Score 1 (Weak):** Tangentially related, doesn't advance core question, scope creep (interesting but off-topic), low priority (removable without loss), minimal impact

### Examples

**Example 1 (Score 3):** Core question: "Is residential renewable energy adoption viable in Germany?" / Refined: "What are installation costs, payback periods, and subsidies for residential solar in Germany (2024)?" - Directly answers viability (economic dimension), critical for decisions, core business canvas component

**Example 2 (Score 1):** Core question: "Is residential renewable energy adoption viable in Germany?" / Refined: "What are renewable energy policies in Denmark and Sweden?" - Off-topic (focus is Germany), scope creep, doesn't advance core question

---

## Priority Thresholds & Reformulation

### High Priority (≥13/15)

**Action:** Proceed with confidence. Question meets quality standards.

### Medium Priority (10-12/15)

**Action:** Acceptable, document limitations. Include for completeness, supporting questions, or when necessary despite feasibility constraints.

### Low Priority (<10/15)

**Action:** Reformulate before proceeding. Major issues with feasibility, stakeholder value, relevance, or redundancy.

**Reformulation strategies:**
- **Feasibility issues:** Narrow scope, reduce time horizon, focus on public data
- **Relevance issues:** Reconnect to core question, eliminate scope creep
- **Novelty issues:** Merge redundant questions, find unique angle
- **Interest issues:** Focus on actionable trends, connect to stakeholder pain points

**Reformulation example:**

Before (9/15): "What renewable energy technologies exist globally?" - Too broad, obvious, off-topic for Germany focus

After (15/15): "How do residential solar installations in Germany compare to other European markets in adoption rates and policy support (2024)?" - Unique comparative angle, competitive context, benchmarking value

---

## Implementation Examples

### Example 1: High Priority Question (14/15)

**Question:** "What are the key economic drivers and barriers for residential solar adoption in Germany (2024)?"

| Criterion | Score | Justification |
|-----------|-------|---------------|
| Feasible | 3 | Multiple sources (industry reports, government data), standard web search, 1-2 days |
| Interesting | 3 | Addresses adoption decision factors, high practical value for policy/business planning |
| Novel | 2 | Updates existing knowledge with 2024 context, combines drivers + barriers |
| Ethical | 3 | Public market data, no privacy concerns, no harm potential |
| Relevant | 3 | Core viability component, critical for business canvas (key partners, cost structure) |
| **Total** | **14/15** | **High priority - proceed** |

---

### Example 2: Medium Priority Question (11/15)

**Question:** "What are the environmental impacts of solar panel manufacturing and disposal?"

| Criterion | Score | Justification |
|-----------|-------|---------------|
| Feasible | 2 | Limited comprehensive data, may require specialized environmental reports, assumptions needed |
| Interesting | 3 | Addresses sustainability concerns, relevant for stakeholder decisions |
| Novel | 2 | Known topic but updates with current manufacturing processes |
| Ethical | 3 | Public environmental data, no concerns |
| Relevant | 1 | Tangential to adoption viability (not core economic/policy question) |
| **Total** | **11/15** | **Medium priority - acceptable for completeness** |

**Limitation:** Context for sustainability-minded stakeholders but not critical for core viability analysis.

---

### Example 3: Borderline Decision (12/15)

**Question:** "What are the technical specifications of top-rated residential solar panel models (2024)?"

| Criterion | Score | Justification |
|-----------|-------|---------------|
| Feasible | 3 | Manufacturer specs publicly available, answerable in hours |
| Interesting | 2 | Some practical value for technical stakeholders, limited broad appeal |
| Novel | 2 | Updates known specs with 2024 models |
| Ethical | 3 | Public product data |
| Relevant | 2 | Supporting detail for technology dimension but not critical for viability |
| **Total** | **12/15** | **Medium priority - include for technical completeness** |

**Rationale:** Not highest priority but provides necessary technical context for stakeholders evaluating specific systems.

---

## Quality Metrics

### Average FINER Score

Calculate average across all questions as overall research plan quality metric:

**Example:** 16 questions, scores: 14, 14, 13, 13, 13, 12, 12, 12, 12, 11, 11, 11, 14, 13, 12, 13 → Sum: 204 → Average: **12.75/15**

**Interpretation:**
- **≥13.0:** Excellent research plan quality
- **12.0-12.9:** Strong research plan quality
- **11.0-11.9:** Acceptable research plan quality
- **<11.0:** Needs improvement (add higher-quality questions or reformulate low scorers)

### Score Distribution

Track distribution to identify patterns:

| Priority | Count | Percentage |
|----------|-------|------------|
| High (≥13) | 9 | 56% |
| Medium (10-12) | 6 | 38% |
| Low (<10) | 1 | 6% |

**Ideal distribution:** 60-70% high priority, 30-40% medium priority, 0% low priority

---

## Integration with Dimension Planner

### When FINER Validation Occurs

**Phase 4: FINER Validation & Prioritization** in dimension-planner workflow

**Inputs:** Refined research questions from Phase 3, core research question context, research dimension structure

**Process:**
1. Load this reference (finer-criteria.md)
2. Apply scoring rubrics to each refined question
3. Document scores in structured format
4. Reformulate any questions scoring <10
5. Calculate average FINER score
6. Proceed to Phase 5 (entity creation) with validated questions

**Outputs:** FINER scores for each question (frontmatter ready), priority classifications, reformulation recommendations (if needed), average quality metric

### Frontmatter Format

Document FINER scores in question entity frontmatter:

```yaml
finer_scores:
  feasible: 3
  interesting: 3
  novel: 2
  ethical: 3
  relevant: 3
  total: 14
  priority: high
```

---

## References

- Hulley, S. B., et al. (2013). *Designing Clinical Research* (4th ed.). Philadelphia: Lippincott Williams & Wilkins.
- Farrugia, P., et al. (2010). "Research questions, hypotheses and objectives." *Canadian Journal of Surgery*.
