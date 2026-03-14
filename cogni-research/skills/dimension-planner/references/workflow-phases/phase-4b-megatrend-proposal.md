# Phase 4b: Megatrend Proposal (Optional)

**Verification Checksum:** `MEGATREND-PROPOSAL-V2`

Generate expected seed megatrends based on the research question and dimensions. User validates and can add custom seeds before research begins.

---

## When to Execute

Execute Phase 4b when **ALL conditions** are met:

1. Phase 4 (MECE/FINER validation) completed successfully
2. Research type is `generic` or `smarter-service`
3. User has not disabled megatrend seeding (`--skip-megatrend-proposal` not set)

**Skip conditions:**

- `lean-canvas` research type (uses fixed canvas blocks)
- `b2b-ict-portfolio` research type (uses fixed portfolio dimensions)
- User explicitly disabled via flag

---

## Step 0: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 4b.1: Analyze research context for megatrend proposal [in_progress]
- Phase 4b.2: Generate seed megatrend candidates [pending]
- Phase 4b.3: Present proposals for user validation [pending]
- Phase 4b.4: Save validated seeds to project metadata [pending]
```

---

## Step 1: Analyze Research Context

Extract key information for megatrend proposal:

```yaml
research_context:
  initial_question: "{from Phase 1}"
  research_type: "{generic|smarter-service}"
  dimensions:
    - name: "{dimension 1 name}"
      description: "{dimension 1 description}"
    - name: "{dimension 2 name}"
      description: "{dimension 2 description}"
  industry_keywords: ["{extracted from question}"]
  scope_indicators: ["{temporal, geographic, domain}"]
```

**Mark 4b.1 complete.**

---

## Step 2: Generate Seed Megatrend Candidates

Using the research context, propose 5-10 expected **canonical megatrends**.

### 2.1 Generation Criteria

For each proposed megatrend, ALL criteria must be satisfied:

| Criterion | Requirement | Validation Question |
|-----------|-------------|---------------------|
| **Cross-Industry Relevance** | Applies to 3+ distinct industries | "Would this affect automotive, healthcare, AND retail?" |
| **Canonical Recognition** | Documented in 2+ independent futures sources (Gartner, McKinsey, WEF, Zukunftsinstitut) | "Can I cite multiple analyst reports on this exact trend?" |
| **Multi-Dimensional Impact** | Affects strategy, operations, technology, AND organization | "Does this change how companies compete, operate, build, AND organize?" |
| **Long-Duration** | Transformation timeframe 36+ months | "Is this a fundamental shift, not an implementation decision?" |
| **Trend Framing** | Describes market transformation (WHAT is changing), not tactical response (HOW to respond) | "Is this about WHAT is changing in markets, not HOW organizations respond?" |
| **Canonical Framing** | Named at cross-industry level, not research-specific | "Is this the name recognized in analyst reports, not a domain-specific variant?" |
| **Dimension Affinity** | Maps to at least one research dimension | "Which dimension does this primarily inform?" |
| **Keyword Coverage** | 3-15 searchable keywords applicable across industries | "Are keywords generic enough to find cross-industry sources?" |
| **Distinctness** | Non-overlapping with other proposed seeds | "Does this cover unique ground from other seeds?" |

### 2.1a Abstraction Level Validation (Three-Tier Taxonomy)

Before including any seed, classify it using this decision tree:

```text
START: Is this a trend or a response?
  │
  ├─► TREND (describes external market change)
  │     │
  │     ├─► Cross-industry? (affects 3+ sectors)
  │     │     │
  │     │     ├─► YES: Duration 36+ months?
  │     │     │     │
  │     │     │     ├─► YES: ✅ TIER 1 MEGATREND → Propose as seed
  │     │     │     └─► NO: Tier 2 Industry Trend → Capture separately
  │     │     │
  │     │     └─► NO: ⚠️ TIER 2 Industry Vertical Trend → Capture separately, not as seed
  │     │
  │     └─► (Single industry only)
  │
  └─► RESPONSE (describes organizational action)
        │
        └─► ❌ TIER 3 Implementation Topic → Do NOT propose
            Instead: Ask "What market shift drives this?" and propose THAT
```

**Tier Classification Table:**

| Tier | Name | Who Affected | What Changes | Duration | Example |
|------|------|--------------|--------------|----------|---------|
| **Tier 1** | Canonical Megatrend | All industries | Market structure | 36+ months | "AI-Driven Automation" |
| **Tier 2** | Industry Vertical Trend | Specific sector | Industry practices | 12-36 months | "Rail Digitalization" |
| **Tier 3** | Implementation Topic | Single organization | Company operations | 0-18 months | "Cloud Migration Project" |

**Only Tier 1 megatrends are proposed as seeds.** Tier 2 trends may be captured in a separate `industry_trends` section for context enrichment.

### 2.1b Trend vs. Response Framing

**Critical distinction:** Seeds must describe WHAT is changing in markets (trend), not HOW organizations respond (implementation).

| Response-Framing (WRONG) | Trend-Framing (CORRECT) | Why |
|--------------------------|-------------------------|-----|
| "Cloud Migration Strategy" | "Cloud-First Infrastructure" | Migration is an action; cloud-first is the market shift |
| "IT Reskilling Program" | "Digital Skills Gap" | Reskilling is a response; skills gap is the market problem |
| "Outsourcing Decision" | "Platform Economy / As-a-Service Models" | Outsourcing is a tactic; platform economy is the shift |
| "Dezentralisierung von IT" | "Edge Computing & Distributed Systems" | Decentralization is a choice; edge computing is the technology shift |
| "Vendor Lock-in Mitigation" | (Not a trend - risk management concern) | Risk concerns are not market trends |

**Reframing Rule:** If the seed describes an organizational action, ask:
> "What external market shift is driving this action?"

Name THAT shift instead of the response.

### 2.1c Cross-Industry Framing Guidance

Valid megatrends must be framed at the canonical level, with the research context as ONE application:

| Narrow Framing (WRONG) | Canonical Framing (CORRECT) | Research Application |
|------------------------|----------------------------|---------------------|
| "Eisenbahn-Digitalisierung" | "Industrial Digitalization" | Rail = one sector |
| "Rail Cybersecurity" | "Critical Infrastructure Cybersecurity" | Rail = one KRITIS sector |
| "Bahnbranche IT/OT" | "IT/OT Convergence" | Rail = one application |
| "Manufacturing 4.0" | "Industrial Digitalization" | Manufacturing = one sector |

**Framing Rule:** Name the megatrend at the level where it's canonically recognized in analyst reports, then note the research-specific application in the `research_application` field.

### 2.1d Counter-Examples

**REJECT these patterns:**

| Bad Proposal | Why It Fails | Classification |
|--------------|--------------|----------------|
| "Digitale Eisenbahn-Infrastruktur (ETCS, Rail 4.0)" | Domain-specific infrastructure project | Tier 2 → Capture separately |
| "ICT Outsourcing und Cloud-Migration" | Response-framing (HOW, not WHAT) | Tier 3 → Reframe to "Cloud-First Infrastructure" |
| "IT Reskilling und Workforce Transformation" | Response-framing (organizational program) | Tier 3 → Reframe to "Digital Skills Gap" |
| "Vendor Lock-in und Strategische Abhängigkeiten" | Risk concern, not a market trend | Reject → Not a trend |
| "Bahnbranche Digital Transformation Benchmarks" | Research classification, not a trend | Reject → Not a trend |

**ACCEPT these patterns:**

| Good Proposal | Why It Passes | Canonical Sources |
|---------------|---------------|-------------------|
| "AI-Driven Automation" | Cross-industry, 36+ months, trend-framing | Gartner, McKinsey, WEF |
| "Digital Skills Gap" | Universal workforce challenge, trend-framing | OECD, WEF Future of Jobs |
| "IT/OT Convergence" | Cross-industry (mfg, utilities, healthcare, rail), canonical | Gartner OT Security, ARC Advisory |
| "Critical Infrastructure Cybersecurity" | All KRITIS sectors, regulatory-driven | NIS2, ENISA, Gartner |
| "Cloud-First Infrastructure" | Universal technology shift, trend-framing | Gartner, Forrester, IDC |
| "Edge Computing & Distributed Systems" | Cross-industry architecture shift | Gartner, McKinsey |

### 2.1e Pre-Proposal Checklist (MANDATORY)

Before including ANY megatrend in the proposal list, answer ALL questions with YES:

**Cross-Industry Test:**
- [ ] Would this trend affect financial services?
- [ ] Would this trend affect healthcare?
- [ ] Would this trend affect manufacturing?
- [ ] Would this trend affect retail?
→ **Minimum 3 YES required.** If fewer: Downgrade to Tier 2 or reject.

**Canonical Recognition Test:**
- [ ] Can I cite a Gartner/Forrester/IDC report on this trend?
- [ ] Can I cite a McKinsey/BCG/Deloitte report on this trend?
- [ ] Can I cite a WEF/OECD/government futures report?
→ **Minimum 2 YES required.** If fewer: Reject as not canonically recognized.

**Trend vs. Response Test:**
- [ ] Does this describe WHAT is changing in markets? (vs. HOW organizations respond)
- [ ] Does this describe an external force? (vs. internal capability/project)
- [ ] Would a CEO discuss this at a board meeting? (vs. IT steering committee)
→ **ALL must be YES.** If ANY NO: Reframe or reject.

**Framing Test:**
- [ ] Is this the name used in analyst reports? (vs. domain-specific variant)
- [ ] Could this name apply to multiple industries? (vs. sector-specific)
→ **ALL must be YES.** If ANY NO: Reframe to canonical name.

**Duration Test:**
- [ ] Will this trend still be relevant in 3 years?
- [ ] Is this a fundamental shift, not a current initiative?
→ **ALL must be YES.** If ANY NO: Classify as Tier 2 or Tier 3.

### 2.2 Output Format

Generate candidates in structured format with **enhanced fields for validation evidence**:

```yaml
proposed_seed_megatrends:
  - name: "IT/OT Convergence"  # Canonical name (cross-industry)
    tier: 1  # REQUIRED: 1 = canonical megatrend
    rationale: "Integration of information and operational technology systems across industries"
    research_application: "Rail signaling and operations integration"  # Context-specific
    canonical_sources:  # REQUIRED: minimum 2 sources
      - "Gartner OT Security Hype Cycle"
      - "ARC Advisory Group Industrial IoT"
    cross_industry_validation:  # REQUIRED: minimum 3 industries
      - "Manufacturing: MES/ERP integration, predictive maintenance"
      - "Utilities: SCADA/IT convergence, smart grid"
      - "Healthcare: medical device integration, clinical systems"
      - "Transportation: rail signaling, fleet management"
    keywords:
      - "IT/OT convergence"
      - "operational technology"
      - "industrial IoT"
      - "OT security"
      - "SCADA integration"
      - "cyber-physical systems"
    dimension_affinity: "digitale-wertetreiber"
    validation_mode: "ensure_covered"
    planning_horizon_hint: "act"

  - name: "Critical Infrastructure Cybersecurity"
    tier: 1
    rationale: "Regulatory-driven security requirements for essential services across sectors"
    research_application: "Rail network protection, NIS2 compliance"
    canonical_sources:
      - "ENISA Threat Landscape for Critical Infrastructure"
      - "Gartner OT Security Market Guide"
      - "NIS2 Directive"
    cross_industry_validation:
      - "Energy: grid security, smart meter protection"
      - "Healthcare: medical device security, patient data"
      - "Transportation: rail signaling, aviation systems"
      - "Finance: payment infrastructure, trading systems"
    keywords:
      - "critical infrastructure"
      - "KRITIS"
      - "NIS2"
      - "OT security"
      - "industrial cybersecurity"
      - "ICS security"
    dimension_affinity: "digitales-fundament"
    validation_mode: "ensure_covered"
    planning_horizon_hint: "act"

  - name: "Digital Skills Gap"
    tier: 1
    rationale: "Workforce capability mismatch as technology adoption accelerates"
    research_application: "IT-to-OT reskilling, digital literacy programs"
    canonical_sources:
      - "WEF Future of Jobs Report"
      - "OECD Skills Outlook"
      - "McKinsey Reskilling Revolution"
    cross_industry_validation:
      - "Manufacturing: automation skills, data literacy"
      - "Healthcare: digital health competencies"
      - "Finance: fintech capabilities, AI/ML skills"
      - "Retail: e-commerce, analytics skills"
    keywords:
      - "digital skills"
      - "skills gap"
      - "reskilling"
      - "upskilling"
      - "digital literacy"
      - "workforce transformation"
    dimension_affinity: "digitales-fundament"
    validation_mode: "ensure_covered"
    planning_horizon_hint: "plan"
```

### 2.3 Optional: Tier 2 Industry Trends (Separate Section)

If the research context surfaces important industry-specific trends that don't qualify as Tier 1 megatrends, capture them separately:

```yaml
# Optional: Industry-specific trends for context enrichment
# NOT used for megatrend seeding, but available for strategic narrative
industry_trends:
  - name: "Rail Digitalization (ETCS, Rail 4.0)"
    tier: 2
    industry: "rail"
    parent_megatrend: "Industrial Digitalization"  # Links to Tier 1
    rationale: "Rail-specific manifestation of industrial digitalization"
    keywords:
      - "ETCS"
      - "Rail 4.0"
      - "digital signaling"
      - "rail automation"
```

**Usage:** Tier 2 trends are NOT proposed as seeds. They are available for:
- Strategic narrative enrichment in reports
- Context linking between canonical megatrends and domain findings
- Gap analysis when Tier 1 megatrends don't fully explain domain-specific observations

### 2.4 Proposal Count Targets

| Dimension Count | Seed Target |
|-----------------|-------------|
| 2-3 dimensions | 3-5 seeds |
| 4-5 dimensions | 5-8 seeds |
| 6+ dimensions | 7-10 seeds |

### 2.5 Planning Horizon Selection

Set `planning_horizon_hint` based on the megatrend's maturity and urgency indicators:

| Horizon | Timeframe | Selection Criteria |
| ------- | --------- | ------------------ |
| **act** | 0-6 months | Published regulations affecting this trend; Proven implementations with measurable ROI; Direct competitive pressure requiring response; >15% industry adoption |
| **plan** | 6-18 months | Draft regulations or industry standards in progress; Early adopter validation with case studies; 5-15% industry adoption; Emerging competitive differentiation |
| **observe** | 18+ months | Early policy debate or research stage; Academic/POC stage implementations; <5% industry adoption; Experimentation phase |

**Examples:**

- "GDPR Compliance" → `act` (published regulation, immediate requirement)
- "AI in Manufacturing" → `plan` (growing adoption, early case studies)
- "Quantum Computing for Supply Chain" → `observe` (research stage, no production use)

**Reference:** See [entity-templates.md](../../knowledge-extractor/references/domain/entity-templates.md#planning-horizon-classification) for detailed classification criteria.

**Mark 4b.2 complete.**

---

## Step 3: Generate Seed Megatrends File (No User Interaction)

⚠️ **IMPORTANT:** dimension-planner runs as a sub-agent and CANNOT use AskUserQuestion. User validation happens in the orchestrating skill (deeper-research-0) AFTER dimension-planner completes.

### 3.1 Write Proposed Seeds with `user_validated: false`

Generate the seed megatrends file with proposals marked as pending user validation:

```yaml
# .metadata/seed-megatrends.yaml
metadata:
  generated_at: "{ISO 8601}"
  research_question: "{initial question summary}"
  user_validated: false  # PENDING - deeper-research-1 will validate with user
  generator: "dimension-planner:phase-4b"

seed_megatrends:
  - name: "Shopfloor Digitalization"
    keywords: [...]
    dimension_affinity: "digitale-wertetreiber"
    validation_mode: "ensure_covered"
    proposed_by: "llm"
    user_validated: false  # Pending user confirmation
    rationale: "..."
    planning_horizon_hint: "act"
```

### 3.2 Return Seeds in Agent Response

Include proposed seeds in the agent's JSON response so deeper-research-0 can present them to the user:

```json
{
  "success": true,
  "dimensions": 4,
  "questions": 16,
  "seed_megatrends": {
    "count": 5,
    "file": ".metadata/seed-megatrends.yaml",
    "pending_validation": true
  }
}
```

**Mark 4b.3 complete.** Proceed to Step 4.

---

## Step 4: Orchestrator Handles User Validation

**deeper-research-0** (the orchestrating skill) will:

1. Receive the seed megatrends in the agent response
2. Use AskUserQuestion to validate with user
3. Update `.metadata/seed-megatrends.yaml` with user's choices
4. Set `user_validated: true` after confirmation

See [deeper-research-0 Phase 2b](../../../../deeper-research-0/references/phase-workflows/phase-2b-megatrend-validation.md) for orchestrator-side implementation.

---

## Reference: Presentation Format (for orchestrator)

Use language template variables from [language-templates.md](../../../../references/language-templates.md#06-megatrends-ui-strings-phase-4b-proposal).

```markdown
## {HEADER_PROPOSED_MEGATRENDS}

{MSG_MEGATREND_PROPOSAL_INTRO}

| {LABEL_NUMBER} | {LABEL_MEGATREND} | {LABEL_DIMENSION} | {LABEL_RATIONALE} |
|---|-----------|-----------|-----------|
| 1 | Shopfloor Digitalization | digitale-wertetreiber | Core digital transformation theme |
| 2 | Supply Chain Resilience | externe-effekte | Critical post-pandemic concern |
| 3 | Workforce Digital Skills | digitales-fundament | Enabler for transformation |

### {HEADER_WHAT_ARE_SEEDS}

{MSG_SEED_DEFINITION}
{MSG_SEED_PURPOSE}

### {HEADER_YOUR_OPTIONS}

1. {OPT_ACCEPT_ALL}
2. {OPT_MODIFY}
3. {OPT_REMOVE}
4. {OPT_ADD_CUSTOM}
5. {OPT_SKIP_SEEDING}
```

### 3.2 User Response Handling

| User Response | Action |
|---------------|--------|
| "Accept all" / "yes" / "1" | Mark all as `user_validated: true` |
| "Remove X" / "delete X" | Remove specified seed from list |
| "Add [name]" | Prompt for keywords and dimension, add to list |
| "Modify X" | Prompt for changes to specified seed |
| "Skip" / "no seeding" | Set `skip_megatrend_seeding: true`, proceed |

### 3.3 Interactive Loop

Continue until user confirms final list:

```markdown
## {HEADER_FINAL_SEED_LIST}

| {LABEL_NUMBER} | {LABEL_MEGATREND} | {LABEL_SOURCE} | {LABEL_STATUS} |
|---|-----------|--------|--------|
| 1 | Shopfloor Digitalization | {VALUE_LLM_PROPOSED} | {VALUE_VALIDATED} |
| 2 | Supply Chain Resilience | {VALUE_LLM_PROPOSED} | {VALUE_VALIDATED} |
| 3 | Workforce Digital Skills | {VALUE_LLM_PROPOSED} | {VALUE_REMOVED} |
| 4 | AI in Manufacturing | {VALUE_USER_ADDED} | {VALUE_VALIDATED} |

{MSG_TOTAL_SEEDS}

{PROMPT_CONFIRM_SEEDS}
```

**Mark 4b.3 complete.**

---

## Step 4: Save Validated Seeds

Write validated seed megatrends to project metadata.

### 4.1 Output Location

```bash
# Validate PROJECT_PATH to prevent empty path errors
if [[ -z "${PROJECT_PATH:-}" ]]; then
  echo "ERROR: PROJECT_PATH is not set - cannot save seed megatrends" >&2
  exit 1
fi

SEED_FILE="${PROJECT_PATH}/.metadata/seed-megatrends.yaml"
```

### 4.2 Output Format

```yaml
# Auto-generated by dimension-planner Phase 4b
# Proposed seed megatrends for user validation in deeper-research-1

metadata:
  generated_at: "2025-01-15T14:30:00Z"
  research_question: "{initial question summary}"
  user_validated: false  # PENDING - deeper-research-1 validates via AskUserQuestion
  generator: "dimension-planner:phase-4b"

seed_megatrends:
  - name: "Shopfloor Digitalization"
    keywords:
      - "shopfloor"
      - "digitalization"
      - "digital factory"
      - "smart factory"
      - "MES"
      - "digital twin"
    dimension_affinity: "digitale-wertetreiber"
    validation_mode: "ensure_covered"
    proposed_by: "llm"
    user_validated: false  # Pending user confirmation
    rationale: "Core digital transformation theme for manufacturing research"
    planning_horizon_hint: "act"

  - name: "AI in Manufacturing"
    keywords:
      - "artificial intelligence"
      - "machine learning"
      - "predictive analytics"
      - "computer vision"
      - "AI-driven automation"
    dimension_affinity: "digitale-wertetreiber"
    validation_mode: "ensure_covered"
    proposed_by: "llm"  # LLM-proposed, not user-added yet
    user_validated: false  # Pending user confirmation
    rationale: "User-identified key megatrend"
    planning_horizon_hint: "plan"
```

### 4.3 Verification

```bash
# Verify file was created
if [ -f "$SEED_FILE" ]; then
  log_conditional INFO "Seed megatrends saved: $SEED_FILE"
  seed_count=$(grep -c "^  - name:" "$SEED_FILE" || echo 0)
  log_conditional INFO "Total seeds: $seed_count"
else
  log_conditional ERROR "Failed to save seed megatrends"
fi
```

**Mark 4b.4 complete.**

---

## Phase Completion

**Verification checklist:**

- [ ] Research context analyzed
- [ ] 5-10 seed megatrends proposed
- [ ] User validated/modified seed list
- [ ] `seed-megatrends.yaml` written to `.metadata/`

**Output:**

```text
Phase 4b Complete: Megatrend Proposal

Seeds Proposed: {count}
Seeds Validated: {count}
User Additions: {count}
Seeds Removed: {count}
Output: .metadata/seed-megatrends.yaml

-> Phase 5: Create Entities
```

**Mark Phase 4b complete.** Proceed to Phase 5.

---

## Integration with Knowledge-Extractor

The `seed-megatrends.yaml` file is consumed by `knowledge-extractor` Phase 5 (Megatrend Clustering):

1. **Load seeds:** Read `.metadata/seed-megatrends.yaml`
2. **Bottom-up clustering:** Identify megatrend clusters from findings
3. **Seed matching:** Match clusters against seeds
4. **Gap detection:** Flag unmatched seeds with `ensure_covered` mode
5. **Output:** Megatrends with `source_type` (clustered/seeded/hybrid)

See [../../../../skills/knowledge-extractor/references/workflows/phase-5-megatrend-clustering.md](../../../../skills/knowledge-extractor/references/workflows/phase-5-megatrend-clustering.md) for details.

---

## Skip Behavior

If user chooses to skip megatrend seeding:

```yaml
# .metadata/seed-megatrends.yaml
metadata:
  generated_at: "2025-01-15T14:30:00Z"
  research_question: "{initial question summary}"
  user_validated: true
  skip_megatrend_seeding: true

seed_megatrends: []
```

Knowledge-extractor will detect `skip_megatrend_seeding: true` and proceed with bottom-up clustering only.
