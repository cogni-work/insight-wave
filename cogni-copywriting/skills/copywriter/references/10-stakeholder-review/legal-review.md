---
title: Legal/Compliance Review
type: stakeholder-review
perspective: legal
version: 2.0
---

# Legal/Compliance Review Criteria

## Quick Reference

- **Use when:** Document involves contracts, policies, compliance requirements, vendor agreements, public statements, regulated industries, or any content with external legal consequences
- **Core principle:** Minimize organizational risk through precise language, appropriate hedging, and complete disclosure -- without neutering the document's effectiveness
- **Evaluation focus:** Risk language, regulatory alignment, liability mitigation, evidence standards, disclosure completeness

## Perspective Philosophy

You are evaluating this document as a legal/compliance stakeholder. Your goal is to identify language, omissions, and structural choices that create unnecessary legal exposure.

Think through each evaluation criterion by asking yourself:

1. Could this language be interpreted as a binding commitment or guarantee?
2. Does this document touch regulated domains, and if so, does it acknowledge the relevant frameworks?
3. Are appropriate disclaimers present for the document's context and audience?
4. Are claims defensible with cited evidence, or are they exposed assertions?
5. Are material risks and limitations visible, or buried and minimized?

**What legal stakeholders need from a document:**

- **Risk-appropriate language** -- Claims hedged proportionally to their certainty. Strong claims supported by strong evidence. Uncertain projections framed as projections.
- **Regulatory compliance** -- Specific citations to applicable laws and standards, not vague compliance gestures.
- **Liability protection** -- Disclaimers, limitations, and proper attribution that match the document's scope and audience.
- **Evidence standards** -- Every material claim traceable to a verifiable source with date, methodology, or authority.
- **Complete disclosure** -- All material risks surfaced. Omission of known risks is worse than acknowledging them.

**Anti-patterns to flag immediately:**

- Absolute guarantees: "will", "guarantee", "always", "ensure", "eliminate"
- Unfounded claims presented as facts without evidence or attribution
- Missing required disclosures or disclaimers for the document type
- Commitments that depend on factors outside organizational control, stated as certainties
- Non-compliant language in regulated contexts (health claims without FDA disclaimer, financial projections without forward-looking statement disclaimer)
- Vague compliance gestures that name no specific regulation ("we comply with all applicable laws")

## Evaluation Checklist

For each criterion below, evaluate the document step by step. First identify the relevant passages, then assess them against the PASS/CONCERN/FAIL rubric, then formulate specific feedback.

### 1. Risk Language (Weight: 30%)

**Question:** Are claims appropriately hedged to avoid over-commitment or false guarantees?

**How to evaluate:** Scan the document for every statement that makes a claim about outcomes, performance, timelines, or capabilities. For each claim, determine whether the language creates a binding commitment or leaves appropriate room for variance.

- **PASS (100):** Claims consistently use appropriate hedging language. Definitive language reserved for established facts. Projections and forecasts framed with qualifiers.
  - Example: "Based on pilot data (Q4 2024, n=500), we expect to reduce churn by approximately 15% within 6 months"
  - Example: "The system is designed to achieve 99.9% uptime, subject to third-party service availability"
  - Markers: conditional language (expect, anticipate, designed to), qualifiers (approximately, estimated), scope limitations (based on, subject to), temporal anchors (as of January 2025)
- **CONCERN (60):** Some hedging present but the document contains occasional absolute claims or over-commitments that create risk.
  - Example: "This will reduce churn by 15%" -- too definitive for a projection
  - Example: "We guarantee 99.9% uptime" -- guarantee without conditions or exceptions
  - Example: "Our solution ensures full compliance" -- absolute assurance about compliance state
- **FAIL (0):** Frequent absolute guarantees or over-commitments throughout the document.
  - Example: "This solution will always work perfectly"
  - Example: "We will eliminate all security vulnerabilities"
  - Example: "Guaranteed ROI within 6 months"

**Why this matters:** Absolute claims can create contractual obligations, trigger warranty liability, and expose the organization to breach-of-contract or false advertising claims. The cost of hedging is minimal; the cost of over-commitment can be substantial.

**Approved hedging vocabulary:**

| Strength | Terms |
|----------|-------|
| Strong (high confidence) | expect, designed to, target, intend, plan |
| Moderate | anticipate, believe, estimate, project, seek |
| Cautious (low confidence) | may, could, explore, consider, potentially |

**Decision rule:** Match hedging strength to evidence strength. Claims backed by internal data can use "expect." Claims based on industry benchmarks should use "anticipate." Claims without direct evidence should use "may" or "could."

---

### 2. Regulatory Alignment (Weight: 25%)

**Question:** Does the document comply with relevant regulatory requirements and industry standards?

**How to evaluate:** First, identify every regulated domain the document touches (data handling, financial projections, health claims, employment, advertising). Then check whether the document acknowledges the specific applicable regulations by name and demonstrates compliance.

- **PASS (100):** Document identifies and complies with applicable regulations by specific citation.
  - Example: "Personal data processing complies with GDPR Article 6(1)(b) (contractual necessity) and CCPA Section 1798.100 (right to know)"
  - Example: "Financial projections prepared in accordance with GAAP standards and include forward-looking statement disclaimer per SEC Rule 175"
  - Markers: specific regulation names, article/section numbers, compliance methodology described
- **CONCERN (60):** Document acknowledges compliance in general terms but lacks specific regulatory references.
  - Example: "We comply with data protection laws" -- which laws? Which provisions?
  - Example: "Financials follow standard accounting practices" -- which standards? Self-assessed or audited?
  - Example: "HIPAA compliant" -- stated without specifying which HIPAA rules apply or how compliance is maintained
- **FAIL (0):** No compliance discussion when the document clearly touches regulated domains, or language that contradicts regulatory requirements.
  - Example: A document handling PII with no mention of data protection frameworks
  - Example: Health outcome claims without FDA disclaimer
  - Example: Financial projections presented as guarantees without forward-looking statement disclaimer

**Why this matters:** Non-compliance exposes the organization to regulatory penalties, enforcement actions, and private lawsuits. Vague compliance language provides no legal protection and may suggest the author is unaware of specific obligations.

**Common regulatory domains to check:**

| Domain | Key Regulations | Trigger |
|--------|----------------|---------|
| Data protection | GDPR, CCPA/CPRA, HIPAA, FERPA | Document mentions personal data, customer data, health records, student records |
| Financial | GAAP, SOX, SEC regulations, FINRA | Document contains financial projections, investment claims, accounting data |
| Healthcare | FDA regulations, HIPAA, state health laws | Document makes health claims, references medical outcomes, handles health data |
| Advertising | FTC Act Section 5, CAN-SPAM, TCPA | Document makes product claims, uses testimonials, involves email/phone outreach |
| Employment | EEOC, ADA, FMLA, state labor laws | Document involves hiring, HR policies, workplace accommodations |
| Industry-specific | PCI DSS (payments), SOC 2 (SaaS), FCC (telecom) | Document operates in a regulated industry vertical |

---

### 3. Liability Mitigation (Weight: 20%)

**Question:** Are appropriate disclaimers, limitations, and liability protections present?

**How to evaluate:** Determine the document type and audience, then check whether the necessary disclaimers are present and complete. A complete disclaimer addresses: temporal scope, subject-matter scope, dependency disclosures, and professional advice limitations.

- **PASS (100):** Document includes all contextually required disclaimers with sufficient specificity.
  - Example: "Recommendations based on information available as of January 2025. Market conditions may change materially. This analysis does not constitute financial advice. Consult qualified advisors before making investment decisions."
  - Example: "System availability subject to third-party service dependencies (AWS us-east-1, Stripe API). Uptime commitments exclude planned maintenance windows and force majeure events."
  - Markers: temporal limitations (as of [date]), scope limitations (does not constitute [type] advice), dependency disclosures (subject to [dependency]), exclusion clauses (excludes [condition])
- **CONCERN (60):** Some disclaimers present but incomplete or missing key elements.
  - Example: "Not financial advice" -- correct intent but missing temporal limitation, advisor referral, and scope
  - Example: "System depends on AWS" -- names dependency but omits liability limitation for outages
  - Example: Disclaimer present but buried in footnotes where it may not satisfy legal notice requirements
- **FAIL (0):** Missing critical disclaimers or liability protections for the document context.
  - Example: Specific investment guidance with no disclaimer
  - Example: Performance commitments dependent on third parties with no dependency disclosure
  - Example: Forward-looking projections with no temporal scope or variance disclaimer

**Why this matters:** Missing disclaimers create direct liability exposure. A properly worded disclaimer does not weaken a document's persuasiveness -- it demonstrates professional rigor.

**Required disclaimers by document context:**

| Context | Required Disclaimer Elements |
|---------|----------------------------|
| Financial analysis/projections | "Not financial/investment advice. Projections based on [assumptions]. Actual results may vary. Consult qualified advisors." |
| Legal analysis | "Not legal advice. Does not create attorney-client relationship. Consult qualified counsel for specific legal questions." |
| Health/medical claims | "Not medical advice. Consult qualified healthcare providers. [FDA disclaimer if applicable]." |
| Forward-looking statements | "Based on information available as of [date]. Forward-looking statements involve risks and uncertainties. Actual results may differ materially." |
| Third-party dependencies | "Performance subject to [named third-party] availability. [Organization] not liable for third-party service disruptions." |
| Vendor recommendations | "Based on evaluation criteria as of [date]. Does not constitute endorsement. Organization should conduct independent due diligence." |

---

### 4. Evidence Standards (Weight: 15%)

**Question:** Are all material claims supported by adequate evidence and properly attributed?

**How to evaluate:** Identify every material claim in the document -- any assertion that influences a decision, commitment, or perception. For each claim, check whether it has a verifiable source, date, and methodology indicator. Rank the evidence quality.

- **PASS (100):** All material claims backed by verifiable evidence with complete attribution.
  - Example: "According to Gartner's 2024 CRM Magic Quadrant (published September 2024), CRM adoption among enterprises increased 40% year-over-year"
  - Example: "Internal pilot (Q4 2024, 500 customers, controlled A/B test) demonstrated 15% churn reduction (p<0.05)"
  - Markers: named source, publication date, sample size or methodology where relevant, specificity of findings
- **CONCERN (60):** Most claims supported but some have vague or missing attributions.
  - Example: "Industry research shows CRM adoption is growing" -- which research? What growth rate?
  - Example: "Experts agree this approach is effective" -- which experts? What qualifications? What is the basis for agreement?
  - Example: Internal data cited without methodology: "Our data shows improvement" -- what data? Measured how? Over what period?
- **FAIL (0):** Material claims lack evidence or rely on unverifiable assertions.
  - Example: "This is the best solution on the market" -- superlative with no comparative evidence
  - Example: "ROI guaranteed" -- no methodology, no assumptions, no source
  - Example: "Proven to work" -- proven by whom? Under what conditions?

**Why this matters:** Unsubstantiated claims expose the organization to false advertising liability (FTC Act Section 5), misrepresentation claims, and credibility damage. The standard is: could this claim survive a challenge in a regulatory or legal proceeding?

**Evidence hierarchy (strongest to weakest):**

1. **Primary data** -- Internal measurements, controlled studies, audited results. Strongest because methodology is known and controlled.
2. **Peer-reviewed research** -- Published academic studies. Strong because independently validated.
3. **Reputable industry research** -- Gartner, Forrester, McKinsey reports. Credible but methodology may be opaque.
4. **Expert opinion** -- Named qualified professionals with stated credentials. Acceptable for qualitative assessments.
5. **Anecdotal evidence** -- Testimonials, case studies, individual examples. Weakest; should not be sole support for material claims.

**Decision rule:** Material claims (those that influence decisions or commitments) require evidence at level 1-3. Supporting claims can use level 4-5. No material claim should rest solely on anecdotal evidence.

---

### 5. Disclosure Completeness (Weight: 10%)

**Question:** Are all material risks, limitations, and conflicts of interest disclosed?

**How to evaluate:** Think through the full risk landscape for the document's subject matter. Consider financial, operational, technical, legal, and strategic risks. Then check whether the document acknowledges each material risk category. A risk is "material" if a reasonable decision-maker would want to know about it.

- **PASS (100):** Document discloses all material risks with appropriate context and, where applicable, mitigation strategies.
  - Example: "Key risks: (1) vendor lock-in due to proprietary data format, mitigated by annual contract renewal and data export clause; (2) data migration estimated at 40 engineering hours, based on comparable past migrations; (3) dependency on vendor roadmap for feature X, with fallback to manual process if delayed"
  - Example: "Limitations: Projections assume stable macroeconomic conditions and current competitive landscape. A recession or major competitor entry would materially affect projections."
  - Markers: named risks with estimated impact, mitigation strategies, stated assumptions, conflict of interest disclosures
- **CONCERN (60):** Some risks disclosed but material categories missing.
  - Example: Document discloses technical risks but omits financial risks (cost overruns, budget uncertainty)
  - Example: Vendor dependency acknowledged but migration cost and complexity not quantified
  - Example: Assumptions stated but not the conditions under which they would fail
- **FAIL (0):** Material risks not disclosed, actively minimized, or absent.
  - Example: Vendor proposal that omits vendor lock-in risk entirely
  - Example: Financial projections that list no assumptions or conditions
  - Example: Document recommending a solution without disclosing the author's financial interest in that solution

**Why this matters:** Material omissions can constitute fraud, misrepresentation, or breach of fiduciary duty depending on context. Disclosing risks does not weaken a document -- it builds credibility and protects the organization.

**Material risk categories to verify:**

| Category | What to check | Red flag if missing |
|----------|--------------|-------------------|
| Financial | Cost overruns, ROI uncertainty, budget assumptions | Document quotes financial figures as certain |
| Operational | Resource requirements, timeline risks, capacity constraints | Document promises delivery without resource caveats |
| Technical | Dependencies, compatibility, scalability limits, single points of failure | Document claims reliability without dependency disclosure |
| Legal | Regulatory changes, contractual obligations, IP risks | Document operates in regulated domain without legal risk acknowledgment |
| Strategic | Market shifts, competitive response, technology obsolescence | Document makes long-term projections without strategic risk factors |
| Conflicts of interest | Author affiliations, financial interests, vendor relationships | Author recommends solution they have a financial stake in, undisclosed |

---

## Scoring Guidelines

**Calculation procedure:**

1. Evaluate each criterion against the rubric above: PASS = 100, CONCERN = 60, FAIL = 0
2. Multiply each score by its weight:
   - Risk Language: score x 0.30
   - Regulatory Alignment: score x 0.25
   - Liability Mitigation: score x 0.20
   - Evidence Standards: score x 0.15
   - Disclosure Completeness: score x 0.10
3. Sum the weighted scores for a total between 0 and 100

**Score interpretation:**

| Range | Rating | Meaning |
|-------|--------|---------|
| 85-100 | Excellent | Legally sound. Minor stylistic suggestions only. |
| 70-84 | Good | Acceptable with targeted fixes. No blocking legal issues but risk exposure should be reduced. |
| 50-69 | Concerns | Significant risk exposure. Document should not be finalized without addressing identified issues. |
| 0-49 | Failing | Major legal/compliance gaps. Document requires substantial revision before external use. |

**Worked example:**

| Criterion | Rating | Score | Weight | Weighted |
|-----------|--------|-------|--------|----------|
| Risk Language | CONCERN | 60 | 0.30 | 18 |
| Regulatory Alignment | PASS | 100 | 0.25 | 25 |
| Liability Mitigation | PASS | 100 | 0.20 | 20 |
| Evidence Standards | CONCERN | 60 | 0.15 | 9 |
| Disclosure Completeness | PASS | 100 | 0.10 | 10 |
| **Total** | | | | **82 (Good)** |

---

## Feedback Output Format

Generate structured JSON feedback following this exact schema:

```json
{
  "perspective": "legal",
  "score": 82,
  "criteria_scores": {
    "risk_language": 60,
    "regulatory_alignment": 100,
    "liability_mitigation": 100,
    "evidence_standards": 60,
    "disclosure_completeness": 100
  },
  "strengths": [
    "Strong GDPR compliance language with specific Article references (Art. 6(1)(b), Art. 32)",
    "Appropriate disclaimers for forward-looking statements with temporal scope (as of January 2025)",
    "Material risks disclosed with mitigation strategies (vendor lock-in, migration complexity)"
  ],
  "concerns": [
    "Absolute guarantee language: 'will reduce churn by 15%' creates binding commitment without qualification",
    "ROI claim ($340K) unsupported by cited methodology, source, or assumptions",
    "Missing temporal limitation on recommendations -- no 'as of [date]' anchor"
  ],
  "recommendations": [
    "CRITICAL: Replace 'will reduce churn by 15%' with 'is expected to reduce churn by approximately 15%, based on Q4 2024 pilot data (n=500)'",
    "CRITICAL: Add evidence attribution for ROI claim: source data, methodology, assumptions, and timeframe",
    "HIGH: Add temporal disclaimer: 'Recommendations based on information available as of [date]. Conditions may change materially.'",
    "OPTIONAL: Add limitation of liability clause for third-party service dependencies (AWS, Stripe)"
  ]
}
```

**Feedback writing rules:**

- **Strengths:** State what the document does well and why it matters legally. Be specific -- name the regulation, the hedging technique, or the disclosure.
- **Concerns:** Quote the problematic language directly, then explain the legal exposure it creates. Always cite the specific passage.
- **Recommendations:** Prefix with priority level (CRITICAL/HIGH/OPTIONAL). For CRITICAL and HIGH items, provide the exact replacement language. Do not give abstract advice like "improve hedging" -- give the rewritten sentence.

**Priority classification:**

| Priority | Criteria |
|----------|----------|
| CRITICAL | Creates direct legal liability, regulatory non-compliance, or material misrepresentation. Must be fixed before document is finalized. |
| HIGH | Creates meaningful risk exposure or is flagged by multiple evaluation criteria. Should be fixed. |
| OPTIONAL | Improves legal posture but absence does not create immediate risk. Nice to have. |

---

## Common Improvement Patterns

Use these before/after patterns when generating recommendations. Always provide the specific rewritten text, not abstract advice.

### Pattern 1: Replace absolute claims with evidence-anchored hedging

**Before:** "This solution will eliminate security vulnerabilities."
**After:** "This solution is designed to address the 12 known vulnerability categories identified in our Q4 2024 security audit. Effectiveness depends on proper implementation and ongoing maintenance."
**Why:** Removes absolute guarantee, anchors to specific evidence, adds dependency disclosure.

### Pattern 2: Replace vague compliance with specific regulatory citations

**Before:** "We handle customer data securely."
**After:** "Customer data handling complies with GDPR Article 32 (security of processing), including encryption in transit (TLS 1.3) and at rest (AES-256), with annual penetration testing per ISO 27001."
**Why:** Transforms unverifiable assertion into auditable compliance statement.

### Pattern 3: Add complete disclaimers where fragments exist

**Before:** "Expected ROI: $500K over 3 years."
**After:** "Projected ROI: approximately $500K over 3 years, based on current cost structure, projected growth rate of 12% annually, and stable market conditions as of January 2025. Actual results may vary materially. This projection does not constitute financial advice."
**Why:** Adds temporal anchor, names assumptions, includes variance disclaimer and professional advice limitation.

### Pattern 4: Replace unattributed claims with sourced evidence

**Before:** "Industry experts agree this is the best approach."
**After:** "Gartner's 2024 CRM Magic Quadrant identifies this approach as a Leader quadrant practice, adopted by 60% of surveyed enterprise clients (n=1,200, published September 2024)."
**Why:** Replaces unverifiable appeal to authority with specific, dated, named source.

### Pattern 5: Add risk disclosure where none exists

**Before:** "We recommend Vendor A for the CRM implementation."
**After:** "We recommend Vendor A based on our evaluation of 4 vendors against 15 criteria (detailed in Appendix B). Key risks: proprietary data format creates vendor lock-in (mitigated by annual contract with data export clause), implementation timeline depends on vendor resource availability (estimated 6 months, +/- 2 months based on comparable deployments)."
**Why:** Adds evaluation basis, discloses material risks, provides mitigation context.

---

## Conflict Resolution

When the legal perspective conflicts with other stakeholder perspectives, use these resolution strategies:

| Conflict | Resolution | Example |
|----------|------------|---------|
| **Executive wants bold claims; Legal wants hedging** | Use strong hedging (expect, designed to) rather than weak hedging (may, could). Preserve confidence while removing binding commitment. | "We will achieve 15%" becomes "We expect to achieve approximately 15%, based on pilot data" -- still confident, not a guarantee. |
| **Marketing wants guarantees; Legal wants disclaimers** | Use aspirational framing with qualification. The aspiration sells; the qualification protects. | "Guaranteed results" becomes "Designed to deliver measurable results, with performance benchmarks established during onboarding" |
| **Technical wants definitive statements; Legal wants conditional** | Keep established technical facts definitive. Hedge only projections, forecasts, and outcome claims. | "The system uses AES-256 encryption" (fact, keep definitive) vs. "The system will prevent all breaches" (projection, hedge it) |
| **End-user wants simplicity; Legal wants disclosure** | Write the core message in plain language. Add a brief, clearly labeled disclosure section rather than embedding legal language throughout. | Main text stays clean and readable. "Important disclosures" section at end covers legal requirements without cluttering the narrative. |

**Escalation rule:** When a document has external legal consequences -- contracts, public statements, regulatory filings, binding proposals -- the legal perspective takes priority over all other stakeholder perspectives on risk language, disclaimers, and disclosure completeness. Other stakeholders retain priority on their own domains (executives on structure, marketing on tone, etc.).

---

## Related Resources

- **Hedging Language:** `references/02-principles/word-choice.md`
- **Risk Documentation:** `references/04-deliverables/proposal.md`
- **Evidence Standards:** `references/02-principles/clarity-rules.md`
