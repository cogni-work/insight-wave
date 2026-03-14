# Publisher Enrichment Strategies

## Overview

Enrich publisher entities with contextual information through targeted web research, including professional background, expertise assessment, credibility evaluation, and organizational profiles.

## Input Requirements

**Publisher Entities (`08-publishers/data/`):**
- Created by publisher creation logic
- Valid YAML frontmatter with `publisher_type` field
- Must have `enriched != true` (only process unenriched)

**Environment:**
- WebSearch tool available
- Internet connectivity for web research

## Language Support

**Supported Languages:**
- English (en) - Default
- German (de)

**Language Parameter:**
The skill accepts a `--language` parameter that determines:
1. Section header language (e.g., "Mission & Mandate" vs "Mission & Mandat")
2. WebSearch query language hints (e.g., "(in German)" suffix)
3. Output content language preference

**WebSearch Language Hints:**
For non-English languages, queries include language context:
```
English: "ADAC" mission mandate headquarters expertise
German:  "ADAC" mission mandate headquarters expertise (in German)
```

**Note**: WebSearch may still return English results if limited content available in target language. Extract available content regardless of source language.

**Localized Headers:**

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Context | Context | Kontext |
| Type | Type | Typ |
| Related Sources | Related Sources | Zugehörige Quellen |
| Mission & Mandate | Mission & Mandate | Mission & Mandat |
| Establishment & HQ | Establishment & Headquarters | Gründung & Hauptsitz |
| Domain Expertise | Domain Expertise | Domänenexpertise |
| Credibility | Credibility Assessment | Glaubwürdigkeitsbewertung |
| Professional Background | Professional Background | Beruflicher Hintergrund |
| Expertise & Role | Expertise & Role | Expertise & Rolle |
| Key Positions | Key Positions | Schlüsselpositionen |
| Not documented | Not publicly documented | Nicht öffentlich dokumentiert |

## Type-Conditional Enrichment

### Individual Publishers

**Target Information:**
1. Professional Background
2. Expertise & Role
3. Key Positions
4. Credibility Assessment

**Web Search Strategy:**

**Query Templates:**
```
Primary:   "{name}" {affiliation} expertise background role
Fallback1: "{name}" about profile biography
Fallback 2: "{name}" publications research
```

**Example Queries:**
```
"Dr. Jane Smith" Oxford climate policy expertise background role
"John Doe" MIT artificial intelligence research about profile
"Sarah Johnson" about profile biography
```

**Search Execution:**
1. Try primary query
2. If insufficient results → Fallback 1
3. If still insufficient → Fallback 2
4. If all fail → Minimal context

**Information Extraction:**

**Note**: Section headers shown in English. Use localized headers based on `--language` parameter.

#### 1. Professional Background (1-2 sentences)

**Extract:**
- Current position and institution
- Education (highest degree, institution, year)
- Career progression (previous roles)

**Example:**
```markdown
**Professional Background**: Associate Professor of Climate Policy at Oxford since 2015. PhD Climate Policy, LSE (2010). Previously Research Fellow at Grantham Research Institute (2010-2015).
```

**Evidence Required:**
- Title verification from institutional pages
- Education confirmation from CV or profiles
- Position dates from bio pages

#### 2. Expertise & Role (2-3 sentences)

**Extract:**
- Research specializations
- Publication metrics (h-index, citation count if available)
- Advisory roles and influence
- Field contributions

**Example:**
```markdown
**Expertise & Role**: Focuses on green finance and sustainable bond markets. Published 25+ peer-reviewed papers with h-index of 22 (Google Scholar). Serves as advisor to EU Commission TEG on Sustainable Finance and OECD Working Party on Climate Finance.
```

**Evidence Required:**
- Research areas from publications
- Metrics from Google Scholar/similar
- Advisory roles from official announcements

#### 3. Key Positions (1-2 sentences OR "Not publicly documented")

**Extract:**
- Stated positions on relevant issues
- Policy stances
- Notable advocacy or contributions
- Public perspectives

**Example:**
```markdown
**Key Positions**: Advocates for mandatory climate-related financial disclosure. Critical of greenwashing in ESG markets. Co-authored green bond standards adopted by ICMA.
```

**Evidence Required:**
- Quotes from interviews/articles
- Published opinion pieces
- Official policy documents

**Fallback if unavailable:**
```markdown
**Key Positions**: Not publicly documented.
```

#### 4. Credibility Assessment (1-2 sentences)

**Extract:**
- Institutional affiliations (quality indicators)
- Track record (publication record, policy impact)
- Potential conflicts of interest
- Overall assessment

**Rating Scale:**
- **Very High**: Top-tier academic + policy advisor + extensive publications
- **High**: Established researcher/expert with peer-reviewed work
- **Medium**: Credible but limited track record
- **Low**: Minimal verification or significant conflicts

**Example:**
```markdown
**Credibility Assessment**: Very High - Oxford/LSE credentials, extensive publications in top-tier journals (Nature Climate Change, Climate Policy), EU/OECD advisory roles. No disclosed conflicts of interest.
```

**Complete Context Example:**
```markdown
### Context

**Professional Background**: Associate Professor of Climate Policy at Oxford since 2015. PhD Climate Policy, LSE (2010). Previously Research Fellow at Grantham Research Institute (2010-2015).

**Expertise & Role**: Focuses on green finance and sustainable bond markets. Published 25+ peer-reviewed papers with h-index of 22. Serves as advisor to EU Commission TEG on Sustainable Finance and OECD Working Party.

**Key Positions**: Advocates for mandatory climate-related financial disclosure. Critical of greenwashing in ESG markets. Co-authored green bond standards adopted by ICMA.

**Credibility Assessment**: Very High - Oxford/LSE credentials, extensive publications in top-tier journals, EU/OECD advisory roles. No disclosed conflicts of interest.
```

**Target Length**: 100-350 words

---

### Organization Publishers

**Target Information:**
1. Mission & Mandate
2. Establishment & Headquarters
3. Domain Expertise
4. Credibility Assessment

**Web Search Strategy:**

**Query Templates:**
```
Primary:   "{name}" mission mandate headquarters expertise
Fallback 1: "{name}" about organization established
Fallback 2: "{name}" official website history
```

**Example Queries:**
```
"European Securities and Markets Authority" mission mandate headquarters expertise
"MIT Media Lab" about organization established
"Climate Bonds Initiative" official website history
```

**Information Extraction:**

**Note**: Section headers shown in English. Use localized headers based on `--language` parameter.

#### 1. Mission & Mandate (2-3 sentences)

**Extract:**
- Official purpose/mission statement
- Organizational mandate and authority
- Scope of operations

**Example:**
```markdown
**Mission & Mandate**: ESMA is an independent EU Authority that contributes to safeguarding the stability of the European Union's financial system by enhancing the protection of investors and promoting stable and orderly financial markets. Holds regulatory authority over securities markets across all EU member states.
```

**Evidence Required:**
- Official mission from organization website
- Legal mandate from founding documents
- Authority scope from regulatory texts

#### 2. Establishment & Headquarters (1-2 sentences)

**Extract:**
- Founded date
- Headquarters location
- Geographic scope

**Example:**
```markdown
**Establishment & Headquarters**: Established in 2011 following the financial crisis. Headquartered in Paris, France. Operates across all 27 EU member states.
```

**Evidence Required:**
- Founding date from official history
- HQ location from contact/about pages
- Geographic scope from mission statements

#### 3. Domain Expertise (2-3 sentences)

**Extract:**
- Core specializations
- Focus areas and sectors
- Key activities and outputs

**Example:**
```markdown
**Domain Expertise**: Specializes in securities regulation, market supervision, credit rating agencies, and sustainable finance standards. Central authority for ESG disclosure frameworks and green bond standards in the European Union. Develops technical standards adopted EU-wide.
```

**Evidence Required:**
- Specializations from official scope
- Activities from annual reports
- Standards from publications

#### 4. Credibility Assessment (1-2 sentences)

**Extract:**
- Official status (government, regulatory, NGO)
- Track record and longevity
- Authoritative role in field
- Potential biases or conflicts

**Rating Scale:**
- **Very High**: Official regulatory body / top-tier academic institution
- **High**: Established NGO / reputable think tank / recognized media
- **Medium**: Private company / newer organization
- **Low**: Unknown entity / conflicts of interest

**Example:**
```markdown
**Credibility Assessment**: Very High - Official EU regulatory body with legal authority. Established track record in financial regulation since 2011. Develops binding technical standards adopted EU-wide. No disclosed conflicts of interest.
```

**Complete Context Example:**
```markdown
### Context

**Mission & Mandate**: ESMA is an independent EU Authority that contributes to safeguarding the stability of the European Union's financial system by enhancing the protection of investors and promoting stable and orderly financial markets. Holds regulatory authority over securities markets across all EU member states.

**Establishment & Headquarters**: Established in 2011 following the financial crisis. Headquartered in Paris, France. Operates across all 27 EU member states with cross-border regulatory authority.

**Domain Expertise**: Specializes in securities regulation, market supervision, credit rating agencies, and sustainable finance standards. Central authority for ESG disclosure frameworks and green bond standards in the European Union.

**Credibility Assessment**: Very High - Official EU regulatory body with legal authority, established track record in financial regulation, develops binding technical standards adopted EU-wide. No disclosed conflicts of interest.
```

**Target Length**: 120-400 words

---

## Anti-Hallucination Protocols

**Critical Requirements:**

1. **Evidence-Only Rule**
   - Extract ONLY what search results explicitly state
   - Never extrapolate or infer beyond evidence
   - Preserve uncertainty ("Reportedly...", "According to...")

2. **Verification Required**
   - Re-read search excerpt before writing each statement
   - Verify dates, titles, affiliations against sources
   - Cross-check claims across multiple results

3. **Missing Info Protocol**
   - Use "Not publicly available" or "Not publicly documented" for gaps
   - NEVER guess or fabricate to fill missing information
   - Better to have incomplete context than fabricated data

4. **Source Citation**
   - Store ALL search URLs in `enrichment_sources` frontmatter
   - Enable post-hoc verification of all claims
   - Minimum 2-3 sources per publisher

**Prohibited Actions:**
- ❌ NEVER fabricate credentials, positions, dates, or organizational details
- ❌ NEVER extrapolate expertise beyond what results state
- ❌ NEVER assume affiliations or mandates not explicitly mentioned
- ❌ NEVER invent credibility metrics without explicit evidence
- ❌ NEVER use marketing language or speculation

**Verification Checklist:**
- [ ] All statements traceable to enrichment_sources URLs
- [ ] Dates verified (founding, degrees, positions)
- [ ] Affiliations confirmed from official sources
- [ ] Metrics verified (citations, publications)
- [ ] Uncertainty preserved where appropriate
- [ ] Professional tone, no promotional language

---

## Frontmatter Updates

**Required Fields After Enrichment:**
```yaml
enriched: true
enrichment_date: 2025-11-07T09:30:00Z
enrichment_sources:
  - https://profiles.stanford.edu/jane-smith
  - https://scholar.google.com/citations?user=abc123
  - https://www.climatechange.org/about/team
```

**Update Process:**
1. Read existing entity file
2. Extract frontmatter
3. Add enrichment fields
4. Append Context section to body
5. Write updated entity atomically

---

## Error Handling

### Search Failures

**Issue:** All web searches fail (no results, timeouts, irrelevant)

**Response:**
- Add minimal context:
  ```markdown
  ### Context

  Limited public information available. Publisher details not documented in accessible sources.
  ```
- Set `enriched: true` (mark as processed)
- Track in `enrichment_failed` counter
- Include in `failed_items` with reason

**Example JSON:**
```json
{
  "failed_items": [{
    "source": "source-456.md",
    "publisher": "publisher-private-firm-abc",
    "stage": "enrichment",
    "reason": "No search results found"
  }]
}
```

### Empty Search Results

**Issue:** Search returns no useful information

**Response:**
1. Try fallback query 1
2. If still empty → Try fallback query 2
3. If all fail → Use minimal context
4. Document as `enrichment_failed`
5. Still mark `enriched: true` (prevent infinite retries)

### Parse/Write Errors

**Issue:** Cannot read or write publisher entity

**Response:**
- Skip publisher
- Log error to stderr
- Add to `failed_items` with technical reason
- Continue with remaining publishers

---

## Validation

**Pre-Execution:**
- [ ] Publisher entity exists and readable
- [ ] Valid YAML frontmatter
- [ ] `enriched != true` (not already processed)
- [ ] WebSearch tool available

**Post-Execution:**
- [ ] Context section added (100-400 words)
- [ ] Frontmatter updated (`enriched`, `enrichment_date`, `enrichment_sources`)
- [ ] Type-appropriate structure (4 sections)
- [ ] All statements verifiable from sources
- [ ] Professional, objective tone

**Quality Checks:**
- [ ] No fabricated information
- [ ] enrichment_sources URLs valid and accessible
- [ ] Credibility assessments evidence-based
- [ ] Type-conditional logic applied correctly
- [ ] Length within target range

---

## Expected Output

**Typical Distribution (24 publishers):**
- Publishers enriched: 22-23 (90-95% success)
- Publishers failed: 1-2 (private entities, minimal presence)
- Average context length: 200-250 words
- Enrichment sources per publisher: 2-4 URLs

**Per-Agent Response:**
```json
{
  "publishers_enriched": 17,
  "enrichment_failed": 1,
  "by_type": {
    "individual": 10,
    "organization": 7
  },
  "failed_items": [{
    "publisher": "publisher-private-firm-xyz",
    "stage": "enrichment",
    "reason": "No search results found"
  }]
}
```

---

## Performance

**Timing:**
- Web search (primary): 2-4 seconds
- Fallback attempts: +2-4 seconds if needed
- Content extraction: 1-2 seconds
- File update: <1 second
- **Total per publisher: 5-10 seconds**

**Optimization:**
- Cache search results during session
- Early exit on successful primary search
- Parallel agent execution
- Idempotent: Skip already-enriched publishers

---

## Credibility Rating Scale

### Very High
- Official government/regulatory bodies
- Top-tier academic institutions (Ivy League, Russell Group, etc.)
- Established international organizations (UN, OECD, etc.)
- Verified experts with policy advisor roles

### High
- Reputable think tanks (Brookings, RAND, etc.)
- Industry associations with track record
- Published researchers with peer-reviewed work
- Recognized media organizations

### Medium
- Private companies with public information
- NGOs with limited transparency
- Independent researchers with some credentials
- Regional organizations

### Low
- Unknown or unverified entities
- Minimal public information
- Potential conflicts of interest
- Self-published only credentials

---

## Integration

**Inputs:**
- Unenriched publisher entities (08-publishers/data/)
- WebSearch tool

**Outputs:**
- Enriched publisher entities with Context sections
- Updated frontmatter (enriched: true, etc.)
- Enrichment statistics (JSON)

**Executed Immediately After:**
- Publisher creation (in same pipeline agent)
- No separate phase; continuous flow
