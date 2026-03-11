# Course 5: Trend Reporting (TIPS Part 2)

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 4
**Plugin**: cogni-tips (continued)
**Audience**: Consultants producing strategic trend reports

---

## Module 1: From Selection to Report

### Theory (3 min)

After TIPS selection (Course 4), you have ~52 agreed trend candidates. The
**trend-report** skill transforms these into a narrative report.

**Report structure** follows the Trendradar dimensions:
1. External Forces section (~13 trends)
2. Strategic New Horizons section (~13 trends)
3. Digital Value Drivers section (~13 trends)
4. Digital Foundation section (~13 trends)

Each section is written as a narrative with:
- TIPS expansion for each trend (Trend → Implications → Possibilities → Solutions)
- Inline citations from research sources
- Quantitative evidence from web-sourced data

**Parallel generation**: Four `trend-report-writer` sub-agents work simultaneously,
one per dimension. This dramatically reduces total generation time.

### Demo

Walk through starting a trend report:
1. Show the agreed candidates from selection
2. Explain the report generation command
3. Show sample output for one dimension section
4. Point out inline citations and evidence integration

### Exercise

If the user completed selection in Course 4:
1. Generate the trend report from agreed candidates
2. While it runs, review the first completed dimension section
3. Note the inline citations — how many sources per trend?

If no selection data available:
1. Review a sample dimension section
2. Identify: trend statements, implications, evidence, citations

### Quiz

1. **Multiple choice**: How many sub-agents write the report in parallel?
   - a) 1
   - b) 2
   - c) 4
   - d) 8
   **Answer**: c

2. **Multiple choice**: Each dimension section covers approximately how many trends?
   - a) 5
   - b) 13
   - c) 20
   - d) 52
   **Answer**: b

### Recap

- Trend report transforms agreed candidates into narrative sections
- 4 parallel sub-agents, one per Trendradar dimension
- Each trend gets full TIPS expansion with evidence
- Inline citations link back to research sources

---

## Module 2: Evidence Enrichment

### Theory (3 min)

During report generation, each trend gets **evidence enrichment**:

1. **Bilingual web search** — Additional searches in EN and DE for each trend
2. **Quantitative data** — Statistics, market sizes, growth rates, adoption figures
3. **Source verification** — Cross-checking claims across multiple sources
4. **Temporal context** — When data was published, how recent it is

**What enrichment adds to the report**:
- "According to [Source], the market grew 23% in 2025" (concrete data)
- "A [Institution] study of 500 companies found..." (credible evidence)
- "Industry analysts project..." (forward-looking context)

**Quality indicators in enriched trends**:
- Number of independent sources cited
- Recency of data (prefer last 12 months)
- Source diversity (not all from same publisher)
- Quantitative vs. qualitative balance

### Demo

Walk through enrichment in a completed section:
1. Show a trend before enrichment (from selection phase)
2. Show the same trend after enrichment (in report)
3. Highlight added data points, citations, and evidence
4. Point out source quality indicators

### Exercise

Ask the user to:
1. Pick one trend from their report (or sample report)
2. Count the evidence points: How many statistics? How many sources?
3. Evaluate source quality: Are sources diverse? Recent? Credible?
4. Identify one area where additional evidence would strengthen the trend

### Quiz

1. **Multiple choice**: Why are searches done in both English and German?
   - a) To double the word count
   - b) To capture DACH market insights that English sources miss
   - c) Because the tool only works in two languages
   - d) For translation purposes
   **Answer**: b

2. **Hands-on**: Find one trend in your report with strong quantitative evidence. What makes it strong?

### Recap

- Evidence enrichment adds quantitative data and citations
- Bilingual search captures EN + DE market insights
- Quality = diverse sources, recent data, quantitative evidence
- Enrichment transforms opinions into substantiated analysis

---

## Module 3: Claims Extraction & Verification

### Theory (3 min)

Every trend report contains verifiable claims — statements tied to sources.
The trend-report skill automatically **extracts claims** during generation.

**Integration with cogni-claims** (from Course 3):
1. Claims are extracted from the report and saved to a claims JSON file
2. Each claim links to its source URL
3. Run `/claims verify` to check all claims against their sources
4. Review deviations on the dashboard
5. Resolve: accept, revise, or reject

**Why this matters**: A trend report with 52 trends might contain 150+ sourced
claims. Manual verification is impractical. Automated verification catches:
- Statistics that don't match the source
- Conclusions the source doesn't support
- Data that has been updated since the research phase

**Workflow**:
```
Report generated → Claims extracted → /claims verify →
Dashboard review → Resolve deviations → Report updated
```

### Demo

Walk through claims verification on a report:
1. Show the extracted claims file
2. Run `/claims verify`
3. Show the dashboard with claim statuses
4. Walk through resolving one deviation
5. Show the corrected report

### Exercise

Ask the user to:
1. If report is available: Run `/claims dashboard` to see extracted claims
2. Run `/claims verify` on the report claims
3. Review any deviations found
4. Discuss: How would you handle a "data staleness" deviation?

If no report available:
1. Discuss the claims verification workflow conceptually
2. Ask: In your consulting work, how do you currently verify sourced claims?

### Quiz

1. **Multiple choice**: How are claims extracted from trend reports?
   - a) Manually by the user
   - b) Automatically during report generation
   - c) By a separate scanning tool
   - d) They're not — you have to submit them
   **Answer**: b

2. **Open-ended**: Why is automated claim verification especially important for reports with 50+ trends?

### Recap

- Claims automatically extracted during report generation
- Integration with cogni-claims for verification
- Catches misquotations, stale data, unsupported conclusions
- Essential quality gate before delivering to clients

---

## Module 4: Report Polishing & Adaptation

### Theory (3 min)

After verification, the trend report goes through final polishing using
other cogni-works plugins:

**Cross-plugin finishing pipeline**:

1. **cogni-narrative review** (`/narrative-review`) — Score the report against
   quality gates. Each dimension section is a narrative and gets graded.

2. **cogni-copywriting** (`/copywrite`) — Polish the final report for
   executive readability. The copywriter is "arc-aware" — it understands
   the narrative structure and preserves it while polishing language.

3. **cogni-narrative adapt** (`/narrative-adapt`) — Create derivative formats:
   - Executive brief (300-500 words per dimension)
   - Talking points for presenting findings
   - One-pager summary of the full report

4. **cogni-visual** (Course 7) — Transform into presentations, posters,
   or other visual deliverables.

**The full chain**:
```
Raw Report → Claims Verified → Narrative Reviewed →
Copywritten → Adapted → Visual Deliverables
```

### Demo

Walk through the finishing pipeline:
1. Run `/narrative-review` on a report section — show the scorecard
2. Run `/copywrite` on the section — show before/after
3. Run `/narrative-adapt --format=brief` — show the executive brief
4. Explain how the visual course (Course 7) completes the chain

### Exercise

Ask the user to:
1. Pick one dimension section from their report
2. Run `/narrative-review` on it — what score did it get?
3. Run `/copywrite` to polish it
4. Compare: how did the quality score change?

### Quiz

1. **Multiple choice**: What does "arc-aware" copywriting mean?
   - a) The copywriter knows about narrative arcs and preserves them
   - b) The copywriter only works on arc-shaped documents
   - c) The copywriter adds new story arcs
   - d) The copywriter removes the arc structure
   **Answer**: a

2. **Hands-on**: What was the quality score before and after copywriting?

### Recap

- Post-verification pipeline: review → polish → adapt
- Copywriting is arc-aware — preserves narrative structure
- Derivatives: briefs, talking points, one-pagers
- Full chain produces client-ready deliverables

---

## Module 5: Delivering Trend Reports

### Theory (3 min)

Putting it all together — the consultant's workflow for delivering trend reports:

**Phase 1: Research** (Course 4, Modules 1-3)
- Define industry and scope with client
- Launch trend scout (runs autonomously)
- Review 60 generated candidates

**Phase 2: Curation** (Course 4, Modules 4-5)
- Select ~52 trends using TIPS framework
- Apply your industry expertise for relevance
- Ensure balanced Trendradar coverage

**Phase 3: Reporting** (Course 5, Modules 1-2)
- Generate report with evidence enrichment
- 4 parallel writers produce dimension sections

**Phase 4: Quality** (Course 5, Modules 3-4)
- Verify claims against sources
- Review and polish narratives
- Create derivative formats

**Phase 5: Delivery** (This module)
- Final review with client context in mind
- Create presentations (Course 7: cogni-visual)
- Deliver and discuss findings

**Time estimate for a full cycle**:
- Research: 30-60 min (mostly autonomous)
- Curation: 30 min (requires your focus)
- Reporting: 20-30 min (mostly autonomous)
- Quality: 20 min (review + verification)
- Total: ~2-3 hours vs. days of manual research

### Demo

Walk through the complete pipeline recap:
1. Show the progression from raw research to finished deliverables
2. Highlight where AI runs autonomously vs. where you need to engage
3. Show a final polished report with all quality checks passed
4. Discuss how to present findings to clients

### Exercise

Ask the user to:
1. Review their complete trend report (or sample)
2. Identify the strongest section — why is it strong?
3. Identify one area for improvement
4. Draft a 2-sentence executive summary of the report's key finding

### Quiz

1. **Multiple choice**: Which phase requires the most consultant expertise?
   - a) Research (web searches)
   - b) Curation (selecting trends)
   - c) Report generation
   - d) Claim verification
   **Answer**: b

2. **Open-ended**: How would you use a trend report in a client engagement?

### Recap

- 5-phase pipeline: Research → Curate → Report → Quality → Deliver
- Autonomous phases save days of manual work
- Your expertise is most critical during curation
- Full cycle: ~2-3 hours for client-ready deliverables

---

## Course Completion

Congratulations! You've mastered the complete cogni-tips pipeline:
- TIPS framework and Trendradar structure (Course 4)
- Trend scouting and candidate selection (Course 4)
- Report generation with evidence enrichment (Course 5)
- Claims verification and quality pipeline (Course 5)
- Cross-plugin finishing and delivery (Course 5)

**Next recommended course**: Course 6 — Portfolio Messaging
