# Evidence Confidence Framework

5-factor evidence reliability methodology for claim verification. Weighted composite score assesses source quality, evidence volume, cross-validation, recency, and expertise alignment.

## Overview

**Purpose:** Assess reliability of evidence supporting factual claims

**Output:** evidence_confidence score (0.0-1.0)

**Weighting:** 5 factors with differential importance based on epistemic value

**Application:** Used in fact-checker workflow to determine claim verification confidence

## Factor 1: Source Quality (35% weight)

### Tier Classification

Source quality receives the highest weight (35%) as it fundamentally determines evidence reliability. Higher-tier sources have rigorous editorial processes, peer review, and reputation at stake.

| Tier | Source Types | Score | Examples |
|------|--------------|-------|----------|
| **Tier 1** | Academic journals, peer-reviewed publications | 1.0 | Nature, Science, JAMA, IEEE Transactions |
| **Tier 2** | Industry reports, white papers, government data | 0.8 | McKinsey, BCG, World Bank, OECD, SEC filings |
| **Tier 3** | Professional publications, trade journals | 0.6 | Harvard Business Review, IEEE Spectrum, MIT Tech Review |
| **Tier 4** | Community content, blogs, news articles | 0.4 | Medium, personal blogs, general news sites |

### Scoring Guidance

**Peer Review Advantage:**
- Peer-reviewed content adds 20-40% credibility vs non-peer-reviewed
- Academic journals with high impact factors score highest
- Conference proceedings (peer-reviewed) typically score 0.9

**Editorial Standards:**
- Professional editorial oversight improves reliability
- Journalistic standards (fact-checking, corrections) add value
- Self-published content without editorial review scores lowest

**Publication Reputation:**
- Consider publication's domain reputation
- Niche authority can elevate tier (e.g., climate journals for climate claims)
- Generalist publications score lower for specialized claims

**Special Cases:**
- Primary source documents (legal filings, patents): Tier 1-2
- Corporate earnings reports: Tier 2 (regulated disclosure)
- Wikipedia: Tier 3-4 (depends on citation quality)
- Social media: Tier 4 (unless official source account)

**Survey Research Tier Assignment:**
- Academic peer-reviewed surveys: Tier 1 (same as academic journals)
- Professional/commercial surveys (Gartner, IDC, McKinsey): Tier 2 (industry reports)
- Industry association surveys with methodology: Tier 3 (professional publications)
- Informal online surveys, self-selected samples: Tier 4 (community content)

## Factor 2: Evidence Count (25% weight)

### Scoring Rubric

Multiple independent findings provide corroboration and reduce single-source bias. This factor carries 25% weight as evidence volume directly impacts claim confidence.

| Finding Count | Score | Interpretation |
|---------------|-------|----------------|
| **3+ findings** | 1.0 | Strong corroboration across multiple sources |
| **2 findings** | 0.7 | Moderate support, limited triangulation possible |
| **1 finding** | 0.5 | Single source, requires additional verification |

### Counting Rules

**What Counts as a Finding:**
- Each distinct piece of evidence supporting the claim
- Must come from identifiable source
- Must independently assert the claim (not cite another source)

**What Does NOT Count:**
- Multiple mentions of same claim in same source = 1 finding
- Derivative content (article citing another article) = 1 finding
- Different pages of same report = 1 finding
- Same data republished elsewhere = 1 finding

**Example:**
- Claim: "Solar capacity grew 30% in 2023"
- Finding 1: IEA Solar Report 2024 states "30% growth"
- Finding 2: Solar Energy Industries Association reports "30% increase"
- Finding 3: News article citing IEA report (DOES NOT COUNT - derivative)
- **Total Count:** 2 findings → Score = 0.7

### Diminishing Returns

The rubric caps at 3+ findings (score 1.0) because:
- 3 independent sources provide sufficient triangulation
- Additional sources add marginal confidence value
- Prevents score inflation from redundant evidence

## Factor 3: Cross-Validation (20% weight)

### Validation Levels

Cross-validation assesses whether multiple independent sources agree on the claim. Worth 20% of total score as independent confirmation is a strong reliability signal.

| Level | Description | Score | Indicator |
|-------|-------------|-------|-----------|
| **Multiple independent confirmed** | Different authors, orgs, methodologies agree | 1.0 | Best validation |
| **Single source, internally consistent** | One source, no contradictions within | 0.7 | Moderate validation |
| **Single source, no corroboration** | One source, no independent verification | 0.5 | Minimal validation |
| **Conflicting sources detected** | Sources disagree on claim details | 0.3 | Validation failed |

### Independence Criteria

**What Makes Sources Independent:**
- Different authors or organizations
- Different underlying data sources
- Different methodologies or approaches
- Temporal separation (not all citing same event)
- No direct citation relationship

**What Does NOT Count as Independent:**
- Same author in different publications
- Same data repackaged by different publisher
- Articles citing each other
- Press releases and news articles repeating them
- Reports from subsidiary organizations

**Example:**
- Claim: "Global EV sales reached 14 million in 2023"
- Source A: BloombergNEF analysis (proprietary data)
- Source B: IEA Global EV Outlook (government data compilation)
- Source C: Automotive News article citing BloombergNEF (NOT independent)
- **Assessment:** 2 independent sources → Score = 1.0

### Conflict Resolution

When sources conflict:
- Assign 0.3 score if material disagreement exists
- Document the conflict in finding notes
- If possible, determine which source is more authoritative
- Consider temporal differences (both could be correct for different periods)

### Cross-Validation for Individual Claims

**Context:** When extracting claims in Phase 5, each claim is derived from ONE finding. The cross-validation score must be calculated based on how many source documents support that specific claim.

**Algorithm:**

1. **Identify the finding** containing the claim
2. **Extract source_ids** from the finding's frontmatter (Algorithm 4 from wikilink-extraction.md)
3. **Count unique sources**: `source_count = length(source_ids array)`
4. **Check for conflicts**: Search other findings with same topic/dimension for contradictions
5. **Apply scoring table** based on count and conflicts

**Scoring Rules:**

| Source Count | Has Conflicts? | Cross-Validation Score |
|--------------|----------------|------------------------|
| 3+ unique sources | No | 1.0 (Multiple independent confirmed) |
| 2 unique sources | No | 1.0 (Multiple independent confirmed) |
| 1 source | No | 0.7 (Single source, internally consistent) |
| 1 source, no other findings | No | 0.5 (Single source, no corroboration) |
| Any count | Yes | 0.3 (Conflicting sources detected) |

**Examples:**

**Example A: High Cross-Validation (Score 1.0)**
- Finding: "finding-green-bond-market-abc123.md"
- source_ids: [[07-sources/data/source-climate-bonds-2024]], [[07-sources/data/source-ifc-green-bonds]]
- Source count: 2 independent sources
- Conflicts: None found
- **Cross-validation = 1.0**

**Example B: Moderate Cross-Validation (Score 0.7)**
- Finding: "finding-prisma-checklist-def456.md"
- source_ids: [[07-sources/data/source-prisma-2020-statement]]
- Source count: 1 source
- Finding text is internally consistent, no contradictions
- **Cross-validation = 0.7**

**Example C: Minimal Cross-Validation (Score 0.5)**
- Finding: "finding-new-methodology-xyz789.md"
- source_ids: [[07-sources/data/source-blog-post-2024]]
- Source count: 1 source
- No other findings on this topic (can't verify elsewhere)
- **Cross-validation = 0.5**

**Example D: Conflicting Cross-Validation (Score 0.3)**
- Finding A: "Green bonds issued $500B in 2023"
- Finding B: "Green bonds issued $485B in 2023"
- Source count: 2 sources but they disagree on specific value
- **Cross-validation = 0.3**

**Integration Point:** This calculation happens in Phase 5, Step D (Calculate Evidence Confidence) immediately after extracting source IDs via Algorithm 4.

## Factor 4: Recency (10% weight)

### Time-Based Scoring

Recency receives 10% weight as older evidence may be outdated, especially in fast-moving domains. Age calculated from publication date to current date.

**Future Publication Dates:** If `publication_date > today`, treat as unpublished/pre-print data and assign recency = 0.0. Log warning: "Future publication date detected - treating as unpublished".

| Age | Score | Rationale |
|-----|-------|-----------|
| **< 1 year** | 1.0 | Current, reflects latest knowledge and data |
| **1-3 years** | 0.8 | Recent, likely still valid in most contexts |
| **3-5 years** | 0.6 | Moderate age, may need verification for fast-changing fields |
| **> 5 years** | 0.4 | Older, context may have changed significantly |

### Domain Considerations

**Fast-Moving Fields (favor recency heavily):**
- Technology (AI, software, semiconductors)
- Financial markets and economic data
- Scientific research with rapid advancement
- Regulatory environments
- **Adjustment:** Consider penalizing older sources more aggressively

**Stable Fields (age less critical):**
- Historical facts and events
- Established scientific principles
- Geographical data
- Foundational research
- **Adjustment:** Older sources remain highly reliable

**Example Adjustments:**
- AI/ML claim from 2020 paper: Use 0.4 (5+ years in fast field)
- Historical event claim from 2015 source: Use 0.8 (age irrelevant)
- Economic data from 2022: Use 0.8 (1-3 years acceptable)

### Publication vs. Data Date

Use whichever is more recent:
- Publication date: When source was published
- Data date: When underlying data was collected
- **Rule:** If data date is specified and more recent than publication, use data date

## Factor 5: Expertise Match (10% weight)

### Scoring Rubric

Expertise match assesses whether the source author has relevant credentials for the claim topic. Weighted at 10% as domain expertise improves reliability but isn't determinative alone.

| Match Quality | Score | Description |
|---------------|-------|-------------|
| **Perfect match** | 1.0 | Author's expertise directly aligned with claim topic |
| **Good overlap** | 0.7 | Relevant expertise in adjacent or related domain |
| **Partial match** | 0.5 | Some relevant background or transferable knowledge |
| **No match** | 0.3 | Outside author's documented expertise area |
| **Unknown author** | 0.5 | Cannot assess expertise (default to moderate) |

### Assessment Process

**Step 1: Identify Claim Domain**
- Determine the topic area of the claim
- Examples: climate science, financial markets, software engineering, public health

**Step 2: Research Author Credentials**
- Check author bio, affiliations, education
- Review publication history in domain
- Verify institutional affiliations (university, research lab, company)
- Check if author is recognized authority

**Step 3: Map Expertise to Topic**
- Direct match: Author's primary research/work area
- Adjacent match: Related field with transferable knowledge
- Partial match: General expertise with some relevance
- No match: Unrelated field

**Step 4: Score Alignment Quality**
- Use rubric above
- Document reasoning in notes

### Examples

**Perfect Match (1.0):**
- Claim: "CRISPR gene editing success rate 85%"
- Author: Jennifer Doudna (CRISPR pioneer, Nobel laureate)
- **Assessment:** Direct expertise in exact claim domain

**Good Overlap (0.7):**
- Claim: "Quantum computing error rates improving"
- Author: Computer scientist specializing in algorithms (not quantum hardware)
- **Assessment:** Adjacent domain, relevant technical background

**Partial Match (0.5):**
- Claim: "AI regulation landscape changing rapidly"
- Author: Technology policy researcher (not AI specialist)
- **Assessment:** Relevant policy expertise, limited technical depth

**No Match (0.3):**
- Claim: "Carbon capture technology costs declining"
- Author: Marketing professional writing blog post
- **Assessment:** No documented expertise in climate tech or engineering

**Unknown Author (0.5):**
- Claim: "Supply chain disruptions cost X billion"
- Author: Industry report, no individual author listed
- **Assessment:** Cannot verify credentials, default to moderate

### Organizational Authority

When author is an organization rather than individual:
- **Perfect match (1.0):** Organization's core mission area
  - Example: World Bank report on poverty statistics
- **Good overlap (0.7):** Organization's adjacent area
  - Example: IMF report on climate finance (finance core, climate adjacent)
- **Partial match (0.5):** Organization's peripheral area
  - Example: Tech company report on education trends

## Composite Calculation

### Formula

```
evidence_confidence = (factor1 × 0.35) + (factor2 × 0.25) + (factor3 × 0.20) + (factor4 × 0.10) + (factor5 × 0.10)
```

### Weight Rationale

- **Factor 1 (35%):** Source quality is foundational - unreliable sources invalidate evidence
- **Factor 2 (25%):** Multiple findings provide crucial corroboration
- **Factor 3 (20%):** Independent validation confirms accuracy
- **Factor 4 (10%):** Recency matters but older sources can still be reliable
- **Factor 5 (10%):** Expertise improves reliability but isn't definitive alone

### Interpretation Guidelines

| Score Range | Confidence Level | Action | Typical Use |
|-------------|------------------|--------|-------------|
| **0.80-1.00** | Very High | Accept claim with high confidence | Primary sources, peer-reviewed, multiple findings |
| **0.60-0.79** | High | Accept claim, note any limitations | Industry reports, good corroboration |
| **0.40-0.59** | Moderate | Flag for review if claim is critical | Single sources, mixed quality |
| **0.00-0.39** | Low | Reject or require additional evidence | Poor sources, conflicts, outdated |

### Calculation Best Practices

**Precision:**
- Calculate to 3 decimal places (0.825)
- Round final result to 2 decimal places (0.83)
- Never round intermediate factor scores

**Documentation:**
- Record all 5 factor scores in structured notes
- Document reasoning for non-obvious scores
- Note any domain-specific adjustments made

**Validation:**
- Verify sum of weights equals 1.0
- Check factor scores are within 0.0-1.0 range
- Ensure final score is 0.0-1.0

## Worked Examples

### Example 1: Very High Confidence (0.82)

**Claim:** "Green bonds issued totaled $500 billion globally in 2023"

**Factor Analysis:**

**Factor 1: Source Quality = 1.0**
- Source: Climate Bonds Initiative Annual Report 2024
- Tier: Tier 1 (authoritative industry data aggregator, peer-reviewed methodology)
- Reasoning: CBI is the recognized global authority for green bond data

**Factor 2: Evidence Count = 0.5**
- Findings: 1 finding (CBI report)
- Reasoning: Single comprehensive source

**Factor 3: Cross-Validation = 0.7**
- Level: Single source, internally consistent
- Reasoning: CBI methodology documented, no internal contradictions, but no independent verification found

**Factor 4: Recency = 1.0**
- Age: Published January 2024 (< 1 year)
- Reasoning: Current data, highly recent

**Factor 5: Expertise Match = 1.0**
- Match: Perfect match
- Reasoning: Climate Bonds Initiative's core domain is green bond market analysis

**Calculation:**
```
(1.0 × 0.35) + (0.5 × 0.25) + (0.7 × 0.20) + (1.0 × 0.10) + (1.0 × 0.10)
= 0.35 + 0.125 + 0.14 + 0.10 + 0.10
= 0.815
```

**Final Score:** 0.82 (rounded from 0.815)

**Tier:** Very High Confidence (0.80-1.00)

**Interpretation:** Accept claim with high confidence. Note: Single finding (Factor 2 = 0.5) reduces score from potential 0.94 to 0.82. Exceptional source quality (Tier 1) and perfect recency/expertise compensate for limited evidence count.

---

### Example 2: Very High Confidence (0.84)

**Claim:** "Renewable energy capacity increased 12% globally in 2022"

**Factor Analysis:**

**Factor 1: Source Quality = 0.8**
- Source 1: IEA Renewables 2023 report
- Source 2: IRENA Global Capacity Statistics 2023
- Tier: Tier 2 (authoritative industry/government reports)
- Reasoning: Both are leading energy agencies with strong methodologies

**Factor 2: Evidence Count = 0.7**
- Findings: 2 findings (IEA and IRENA reports)
- Reasoning: Two independent sources confirm the figure

**Factor 3: Cross-Validation = 1.0**
- Level: Multiple independent sources confirmed
- Reasoning: IEA and IRENA use different data collection methods, both arrive at ~12% figure

**Factor 4: Recency = 0.8**
- Age: Published 2023 for 2022 data (1-3 years old)
- Reasoning: Recent data, still highly relevant

**Factor 5: Expertise Match = 1.0**
- Match: Perfect match
- Reasoning: Both IEA and IRENA specialize in global energy statistics

**Calculation:**
```
(0.8 × 0.35) + (0.7 × 0.25) + (1.0 × 0.20) + (0.8 × 0.10) + (1.0 × 0.10)
= 0.28 + 0.175 + 0.20 + 0.08 + 0.10
= 0.835
```

**Final Score:** 0.84 (rounded from 0.835)

**Tier:** Very High Confidence (0.80-1.00)

**Interpretation:** Accept claim with very high confidence. Two independent authoritative sources (IEA, IRENA) with perfect cross-validation achieve highest possible corroboration. Tier 2 sources with perfect expertise match and good recency produce excellent confidence score.

---

### Example 3: Moderate Confidence (0.50)

**Claim:** "AI code review tools reduce bugs by 40%"

**Factor Analysis:**

**Factor 1: Source Quality = 0.4**
- Source: Medium blog post by software engineer
- Tier: Tier 4 (community content, no editorial oversight)
- Reasoning: Personal blog, no peer review or formal publication process

**Factor 2: Evidence Count = 0.5**
- Findings: 1 finding (blog post case study)
- Reasoning: Single anecdotal case, no broader research cited

**Factor 3: Cross-Validation = 0.5**
- Level: Single source, no corroboration
- Reasoning: No independent studies or reports found to confirm the 40% figure

**Factor 4: Recency = 0.8**
- Age: Published 2 years ago (1-3 years old)
- Reasoning: Reasonably recent for software tooling claims

**Factor 5: Expertise Match = 0.5**
- Match: Unknown author expertise
- Reasoning: Blog bio lists "software engineer" but no specific credentials in code review or quality assurance

**Calculation:**
```
(0.4 × 0.35) + (0.5 × 0.25) + (0.5 × 0.20) + (0.8 × 0.10) + (0.5 × 0.10)
= 0.14 + 0.125 + 0.10 + 0.08 + 0.05
= 0.495
```

**Final Score:** 0.50 (rounded from 0.495)

**Interpretation:** Moderate confidence - Flag for review if critical. Acceptable for general reference but requires stronger evidence for important decisions.

---

### Example 4: Low Confidence (0.35)

**Claim:** "Blockchain will increase supply chain efficiency by 60%"

**Factor Analysis:**

**Factor 1: Source Quality = 0.4**
- Source: Vendor white paper (blockchain company)
- Tier: Tier 4 (marketing content, potential bias)
- Reasoning: Commercial source with clear incentive to promote technology

**Factor 2: Evidence Count = 0.5**
- Findings: 1 finding (vendor case study)
- Reasoning: Single promotional case study, no independent research

**Factor 3: Cross-Validation = 0.3**
- Level: Conflicting sources detected
- Reasoning: Academic research found shows mixed results (10-30% efficiency gains), contradicts 60% claim

**Factor 4: Recency = 0.6**
- Age: Published 4 years ago (3-5 years old)
- Reasoning: Moderately old in fast-moving technology field

**Factor 5: Expertise Match = 0.3**
- Match: No match
- Reasoning: Marketing department authored, not supply chain or technology researchers

**Calculation:**
```
(0.4 × 0.35) + (0.5 × 0.25) + (0.3 × 0.20) + (0.6 × 0.10) + (0.3 × 0.10)
= 0.14 + 0.125 + 0.06 + 0.06 + 0.03
= 0.415
```

**Final Score:** 0.42 (rounded from 0.415)

**Note:** Corrected calculation shows Moderate confidence (0.40-0.59 range), but the conflicting sources and vendor bias suggest treating this toward the lower end.

**Interpretation:** Moderate-Low confidence - Reject or require additional evidence. Vendor bias, conflicting sources, and age all reduce reliability. Recommend finding independent academic or industry research to verify.

## Usage Notes

### Mandatory Requirements

- **Calculate all 5 factors:** Never skip factors or use subset
- **Document factor scores:** Record in claim frontmatter or structured notes
- **Use decimal precision:** 2 decimal places (0.82, not 0.8)
- **Show calculation:** For transparency, document formula application

### Integration with Fact-Checker

The evidence_confidence score is one component of the overall claim confidence calculation. The fact-checker agent combines:

1. **evidence_confidence** (this framework) - reliability of supporting evidence
2. **claim_quality** - specificity and verifiability of the claim itself

Both factors together determine whether a claim is verified or flagged.

### Common Pitfalls

**Pitfall 1: Conflating evidence count with source count**
- WRONG: 5 news articles citing same study = 5 findings
- RIGHT: 5 articles citing same study = 1 finding

**Pitfall 2: Ignoring conflicts**
- WRONG: Average conflicting source scores
- RIGHT: Assign 0.3 to Factor 3 if material conflict exists

**Pitfall 3: Over-weighting recency in stable fields**
- WRONG: Penalize 10-year-old historical fact heavily
- RIGHT: Consider domain - historical facts don't decay with age

**Pitfall 4: Assuming organizational sources have expertise**
- WRONG: Tech company report on education automatically gets high expertise score
- RIGHT: Assess whether organization has relevant domain expertise

**Pitfall 5: Rounding intermediate calculations**
- WRONG: Round Factor 1 to 0.8, then calculate composite
- RIGHT: Use full precision (0.825) until final result

### When to Adjust Framework

**Rare Adjustment Scenarios:**
- Highly specialized domains with unique source hierarchies
- Time-sensitive claims where recency is critical (adjust Factor 4 weight)
- Fields with limited peer-reviewed literature (adjust Factor 1 tiers)

**How to Document Adjustments:**
```yaml
evidence_confidence: 0.75
confidence_calculation:
  factor1_source_quality: 0.8
  factor2_evidence_count: 0.7
  factor3_cross_validation: 0.7
  factor4_recency: 0.9
  factor5_expertise: 0.8
  adjustments: "Increased Factor 4 weight to 15% (reduced Factor 1 to 30%) for time-sensitive market data claim"
  formula: "(0.8 × 0.30) + (0.7 × 0.25) + (0.7 × 0.20) + (0.9 × 0.15) + (0.8 × 0.10)"
```

### Quality Assurance

**Before Finalizing Score:**
1. Verify all factors calculated
2. Check factor scores are 0.0-1.0
3. Confirm weights sum to 1.0
4. Validate final score is 0.0-1.0
5. Document any unusual scoring decisions

**Spot Check Questions:**
- Did I count findings correctly (not just sources)?
- Are sources truly independent for cross-validation?
- Did I assess author expertise objectively?
- Is recency scoring appropriate for this domain?
- Does final confidence level match intuitive assessment?

## References

**Source Document:**
- cogni-research/agents/fact-checker.md (lines 486-519)
- Extracted and expanded with operational guidance

**Related Frameworks:**
- Claim Quality Scoring (cogni-research/skills/fact-checker/references/claim-quality.md)
- Fact-Checker Agent Workflow (cogni-research/agents/fact-checker.md)

**Last Updated:** 2025-11-11
