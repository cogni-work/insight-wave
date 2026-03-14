# Question Analysis Methodology

Systematic framework for analyzing research questions, identifying ambiguities, and creating structured question entities.

---

## Quick Reference: Decision Framework

| Category | Criteria | Action |
|----------|----------|--------|
| **Blocking** | ≥2 vague core dimensions (subject + aspect undefined) | MUST CLARIFY with 2-4 questions |
| **Quality Improvement** | 1 vague dimension OR missing criteria | SHOULD CLARIFY with 1-2 questions |
| **Excellent** | 0 vague dimensions, clear criteria, explicit scope | PROCEED DIRECTLY |

**Philosophy:** Create the best possible refined question. Even "acceptable" questions benefit from 1-2 clarifying questions.

---

## Ambiguity Types

### Blocking Ambiguities

Prevent research from starting. Require clarification:

- Undefined core subject (e.g., "technology" without domain)
- Vague research objectives (e.g., "affecting" without specifying impacts)
- Unresearchable scope (e.g., "society" without boundaries)
- Multiple (≥2) vague core dimensions

### Quality Improvement Opportunities

Research could start, but quality would be poor:

- Single vague dimension
- Comparison without criteria ("A vs B" - on what basis?)
- Evaluation without dimensions ("better" - by what measure?)
- Missing user context
- Undefined scope boundaries

### Non-Blocking Ambiguities

Can be explored during research:

- Specific methodologies
- Detailed sub-aspects
- Temporal boundaries (assume recent if unspecified)

---

## Analysis Framework

```xml
<question_analysis>

**Subject & Terminology:**
- Primary area: {domain}
- Key terms: {concepts}
- Ambiguous terms: {list}

**Explicit Scope:**
- Boundaries: {constraints}
- Temporal: {time periods}
- Geographic: {locations}
- Domain: {industries/groups}

**Ambiguity Assessment:**
Blocking (if any):
- {Dimension}: {Why blocks research}

Quality improvements (if any):
- {Missing criteria}: {How clarification helps}

Non-blocking (explorable):
- {Aspect}: {Why research can proceed}

**Refinement Strategy:**
- Approach: {How to narrow without expansion}
- Scope preservation: {Maintain original intent}

</question_analysis>
```

---

## Clarification Patterns

| Pattern | Use When | Key Options |
|---------|----------|-------------|
| **Technology Domain** | Subject is "technology" without specification | AI/ML, Biotech, Quantum, Blockchain |
| **Impact/Aspect** | Vague objective ("affecting", "changing") | Economic, Social, Environmental, Healthcare |
| **Industry/Sector** | Application domain undefined | Healthcare, Finance, Manufacturing, Retail |
| **Temporal Scope** | Time period unclear | Recent (2020+), Decade (2015+), Historical (2000+) |
| **Geographic Scope** | Location matters but unspecified | North America, Europe, Asia-Pacific, Global |
| **Comparison Criteria** | "X vs Y" without dimensions | Cost, Performance, Features, Ease of Use |
| **Evaluation Criteria** | Subjective assessment ("better", "worth it") | Business Value, Technical Quality, User Impact |
| **User Context** | Recommendations without target audience | Technical, Business, Research, General |

**Example JSON:**

```javascript
{
  question: "Which aspect should the research focus on?",
  header: "Focus Area",
  options: [
    {label: "Economic Impact", description: "Jobs, productivity, markets"},
    {label: "Social Dynamics", description: "Relationships, culture, behavior"},
    {label: "Environmental", description: "Climate, sustainability, resources"}
  ],
  multiSelect: false  // Use true for criteria where multiple apply
}
```

---

## Research-Type-Specific Clarification Patterns

These patterns are applied in Phase 1 Step 3.5 based on the `research_type` selected in Phase 0.

| Research Type | Pattern | Key Questions | Storage Fields |
|---------------|---------|---------------|----------------|
| **smarter-service** | Portfolio Linking | "Link to existing b2b-ict-portfolio?" | `linked_portfolio` |
| **customer-value-mapping** | Source Validation | "Customer name? Customer industry?" | `customer_name`, `customer_industry` |
| **lean-canvas** | Business Context | "Business stage? B2B/B2C? Customer segment?" | `business_stage`, `business_model`, `customer_segment` |
| **b2b-ict-portfolio** | Dimension Selection | (handled in Phase 0 Step 0.4.5) | `selected_dimensions` |
| **generic** | Standard Patterns | Use generic clarification patterns above | N/A |

### smarter-service: Portfolio Linking

**Purpose:** Enable `portfolio_refs[]` suggestions during TIPS creation in Phase 2.

**Example:**

```javascript
{
  question: "Would you like to link to an existing portfolio project?",
  header: "Portfolio Linking",
  options: [
    {label: "Yes", description: "Link to b2b-ict-portfolio for cross-referencing"},
    {label: "No", description: "Create standalone trend research"},
    {label: "Not sure", description: "Show available portfolio projects"}
  ],
  multiSelect: false
}
```

**If "Yes" or "Not sure":** Discover available b2b-ict-portfolio projects and let user select.

**Storage:** `linked_portfolio` field in question entity frontmatter (wikilink format: `[[project-name]]`)

### customer-value-mapping: Source Validation

**Purpose:** Validate required context for Value Story research that requires existing smarter-service and b2b-ict-portfolio projects.

**Example:**

```javascript
{
  question: "Please confirm customer context:",
  header: "Customer Context",
  fields: [
    {label: "Customer name", placeholder: "e.g., Siemens, BMW, Deutsche Telekom"},
    {label: "Customer industry", placeholder: "e.g., manufacturing, automotive, telecommunications"}
  ]
}
```

**Storage:** `customer_name`, `customer_industry` fields in question entity frontmatter

### lean-canvas: Business Context

**Purpose:** Gather business model context for Lean Canvas analysis.

**Example:**

```javascript
{
  question: "Please describe your business context:",
  header: "Business Context",
  fields: [
    {label: "Business stage", options: ["Idea", "Early-stage", "Growth", "Mature"]},
    {label: "Business model", options: ["B2B", "B2C", "B2B2C"]},
    {label: "Primary customer segment", placeholder: "Brief description"}
  ]
}
```

**Storage:** `business_stage`, `business_model`, `customer_segment` fields in question entity frontmatter

---

## Entity File Template

```markdown
---
# Obsidian Tags
tags: [question]

# Dublin Core Metadata
dc:creator: "deeper-research-skill"
dc:title: "{brief summary, max 100 chars}"
question_title: "{Semantic title derived from refined question}"  # Display title for entity header
dc:date: "{ISO8601 timestamp}"
dc:identifier: "question-{slug}-{hash}"
dc:type: "initial-question"
dc:subject: ["{primary-domain}"]

# Legacy Fields
entity_type: "00-initial-question"
entity_id: "question-{slug}-{hash}"
created_at: "{ISO8601}"
status: "refined"
dimension_ids: []  # Populated by dimension-planner skill with wikilinks to created dimensions
---

# ${question_title}

## Original Question
{exact user question}

## Refined Question
{clarified version with explicit scope}

## Scope Boundaries

### Included
- {explicit scope from question and clarifications}
- {temporal/geographic/domain boundaries}

### Excluded
- {what user is NOT asking - prevent scope creep}

## Implicit Assumptions
- {assumptions needing validation during research}

## Dimensional Hints
{ONLY if explicitly mentioned}
- Temporal: {time period}
- Geographic: {location}
- Industry: {sector}

## Open Questions
{Non-blocking ambiguities for exploration}
- {aspects needing definition}
- {comparative dimensions to explore}

## Metadata
- Refinement method: {interactive | direct}
- Questions asked: {0-4}
- Blocking ambiguities resolved: {list}
- Confidence: {HIGH|MEDIUM|LOW}
```

---

## Semantic Filename Generation

```bash
# Algorithm
question_text="What are best practices for fact-checking in LLM research"
slug=$(echo "$question_text" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | \
  cut -c1-80)
hash=$(echo -n "$question_text" | shasum -a 256 | cut -c1-8)
filename="question-${slug}-${hash}.md"
```

**Examples:**

- `question-best-practices-fact-checking-llm-research-a3f5b294.md`
- `question-ai-workforce-impact-business-transformation-7c2d8e1f.md`

---

## Examples

### Example 1: Excellent Question (No Clarification)

**Input:** "What are the environmental impacts of lithium mining in South America between 2010-2023?"

**Analysis:**

- Subject: Environmental impacts of lithium mining - CLEAR
- Scope: South America, 2010-2023 - EXPLICIT
- Blocking: None
- Non-blocking: Specific metrics, countries, mining methods (explorable)

**Action:** Skip clarification, proceed to entity creation.

---

### Example 2: Multiple Blocking Ambiguities

**Input:** "How is technology affecting society?"

**Analysis:**

- Subject: "Technology" - TOO VAGUE
- Aspect: "Affecting" - UNDEFINED
- Scope: "Society" - TOO BROAD
- **3 blocking ambiguities** - UNRESEARCHABLE

**Action:** Ask 2-3 questions (technology domain + societal aspect minimum)

**After selections:** AI + Economic Impact

**Refined:** "How is artificial intelligence affecting economic systems, including employment, productivity, market dynamics, and economic inequality?"

---

### Example 3: Quality Improvement (Comparison)

**Input:** "Python vs JavaScript - which is better?"

**Analysis:**

- Subject: Python and JavaScript - CLEAR
- Pattern: Comparison without criteria
- Issue: "Better" is subjective
- Blocking: None
- Quality: Missing comparison criteria and user context

**Action:** Ask 1-2 questions (comparison criteria, use case)

**After selections:** Web Development + Ease of Learning

**Refined:** "For web development beginners, which language (Python or JavaScript) offers easier learning curves, better documentation, and more accessible entry points?"

---

### Example 4: Evaluation Without Criteria

**Input:** "Does microservices architecture make sense for my project?"

**Analysis:**

- Subject: Microservices - CLEAR
- Pattern: Evaluation ("make sense")
- Issues: Undefined project context, missing evaluation criteria
- Blocking: None
- Quality: Poor without context

**Action:** Ask 2 questions (project context + evaluation criteria)

**After:** Small team (5 devs), new SaaS + Focus: development speed, maintenance

**Refined:** "For a small team of 5 developers building a new SaaS product, what are the tradeoffs of microservices vs monolithic architecture in terms of development speed, maintenance burden, and operational complexity?"

---

## Scope Preservation Guidelines

**DO:**

- Clarify vague terms while maintaining intent
- Ask minimal questions (1-4 max)
- Combine original phrasing with clarification details
- Document excluded scope to prevent creep

**DON'T:**

- Expand beyond explicit request
- Infer unstated research goals
- Add dimensions user didn't mention
- Over-specify researchable questions

**Examples:**

| User Question | ❌ Over-Expansion | ✅ Scope-Preserving |
|---------------|-------------------|---------------------|
| "AI in healthcare" | "AI's impact on delivery, outcomes, costs, compliance, workforce" | Ask: "Which aspect interests you?" |
| "Climate change effects" | "Effects on agriculture, water, biodiversity, migration, economics" | Ask: "Which effects or domains?" |

---

## Utilities

### Timestamp Generation

```bash
created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Output: 2025-10-24T14:30:00Z
```

### Validation Checklist

Before completing Phase 1:

- [ ] Entity file at: `00-initial-question/data/question-{slug}-{hash}.md`
- [ ] Semantic filename (human-readable key terms)
- [ ] YAML frontmatter complete
- [ ] Refined question incorporates clarifications
- [ ] Scope boundaries documented (included AND excluded)
- [ ] Non-blocking ambiguities listed
- [ ] ISO8601 timestamp

### Edge Cases

**Empty/invalid questions:** Return error: "No research question provided"

**Directory creation fails:** Report error with specifics from tool

**Domain context searches (0-2 optional):** Use WebSearch for highly specialized terminology; skip for well-known domains

### Common Commands

```bash
# Create directory
mkdir -p "$PROJECT_PATH/$DIR_INITIAL_QUESTION/$DATA_SUBDIR"

# Verify file
test -f "$PROJECT_PATH/$DIR_INITIAL_QUESTION/$DATA_SUBDIR/{filename}" && echo "✓ Created"

# Count questions
find "$PROJECT_PATH/$DIR_INITIAL_QUESTION/$DATA_SUBDIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l
```
