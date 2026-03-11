# Audience Model

## Purpose

Define how to build an Audience Model at pipeline start — before arc analysis, message architecture, or copywriting begins. The Audience Model answers: **WHO is this presentation for, what do they care about, and what will make them say yes?**

Without an Audience Model, every downstream decision uses generic reasoning ("the audience should..."). With an Audience Model, decisions become targeted: evidence is ranked by what the primary decision-maker values, Q&A prep uses actual objections, and the governing thought addresses the person who signs off.

---

## Two Modes

### Mode Selection

```text
IF `audience_context` parameter is provided by caller:
  → RICH MODE: Parse structured stakeholder data
  → Source: caller-provided (highest quality — caller already mapped the buying center)

ELSE IF source is a Why Change project directory:
  CHECK: {source_path}/.metadata/pitch-log.json
  IF .buying_center.roles exists AND is non-empty:
    → RICH MODE: Extract from pitch-log.json
    → Source: self-discovered (backward compatibility)

  ELSE IF file exists: {source_path}/phase-0-buyer-map.md:
    → RICH MODE: Parse markdown for stakeholder roles
    → Source: self-discovered (fallback)

ELSE:
  → LEAN MODE: Infer audience from narrative signals
  → Source: inferred (lowest confidence)
```

---

## Rich Mode

### Input: Caller-Provided `audience_context`

The caller passes a multiline string with structured stakeholder data:

```text
audience_context: |
  Economic Buyer: CFO — Priority: ROI within 12 months — Objection: Integration cost exceeds budget
  Technical Evaluator: CTO — Priority: API compatibility — Objection: Migration complexity
  End Users: Operations team — Priority: Workflow simplicity — Objection: Training burden
  Champion: VP Digital (identified) — Motivation: Board mandate for digital transformation
  Blockers: CISO (security concerns), Legal (data residency)
  Source: pitch-log.json
```

### Input: pitch-log.json (backward compatibility)

When no `audience_context` is provided but pitch-log.json has buying center data:

```text
FROM pitch-log.json .buying_center:

FOR each role in [economic_buyer, technical_evaluator, end_users]:
  Extract: title, priorities[0], objections[0]

FROM .champion:
  Extract: identified, title, motivation

FROM .blockers:
  Extract: role, objection (first 3)
```

### Parsing Rules

```text
FOR each stakeholder line in audience_context (or pitch-log.json extraction):

  1. IDENTIFY role label:
     "Economic Buyer" | "Technical Evaluator" | "End Users" | "Champion" | "Blockers"

  2. EXTRACT fields (delimiter: " — "):
     - Title/Name: text after role label colon, before first delimiter
     - Priority: text after "Priority:" marker
     - Objection: text after "Objection:" marker

  3. HANDLE missing fields:
     - Missing priority → set "Not specified"
     - Missing objection → set "Not specified"
     - Missing role entirely → skip (not all buying centers have all roles)

  4. COMPRESSION: max 50 chars per field (truncate with "...")
```

### Rich Mode Output: Audience Model Object

```text
AUDIENCE MODEL (Rich):
  mode: rich
  source: {caller-provided | pitch-log.json | phase-0-buyer-map.md}
  confidence: {1.0 for caller-provided, 0.9 for pitch-log.json, 0.7 for buyer-map.md}

  primary_decision_maker:
    role: {economic_buyer | other — whoever approves the budget}
    title: "{title}"
    top_priority: "{priority}"
    top_objection: "{objection}"

  stakeholders:
    - role: economic_buyer
      title: "{eb_title}"
      priority: "{eb_priority}"
      objection: "{eb_objection}"
    - role: technical_evaluator
      title: "{te_title}"
      priority: "{te_priority}"
      objection: "{te_objection}"
    - role: end_users
      teams: "{eu_teams}"
      priority: "{eu_priority}"
      objection: "{eu_objection}"

  champion:
    identified: {true/false}
    title: "{title}"
    motivation: "{motivation}"

  blockers:
    count: {N}
    entries:
      - role: "{blocker_role}"
        objection: "{blocker_objection}"

  assumption_based: {true if source == "industry_assumptions", false otherwise}
```

### Primary Decision-Maker Selection

```text
DETERMINE primary_decision_maker:

  DEFAULT: economic_buyer (in B2B, the person who signs the check)

  OVERRIDE IF:
    - No economic_buyer data → use technical_evaluator
    - Champion has "executive sponsor" title → use champion
    - Caller explicitly tagged a role as "primary"

  WHY this matters:
    - Governing thought must resonate with THIS person
    - Evidence selection prioritizes THIS person's concerns
    - The "uncomfortable question" in Q&A prep is THIS person's objection
```

---

## Lean Mode

### When to Use

Lean mode activates when no structured audience data is available — generic narratives, research reports, strategy documents, or any source without a buying center.

### Narrative Signal Scan

```text
SCAN the narrative for audience signals:

1. VOCABULARY ANALYSIS:
   Financial terms (ROI, revenue, budget, margin, EBITDA, TCO):
     → Audience type: executive / financial decision-maker
   Technical terms (API, architecture, integration, latency, stack):
     → Audience type: technical / engineering
   Operational terms (workflow, efficiency, training, adoption, rollout):
     → Audience type: practitioner / operations
   Mixed vocabulary → Audience type: mixed (common for board presentations)

2. CTA ANALYSIS (closing section):
   "Approve budget" / "Authorize investment" → executive audience
   "Schedule pilot" / "Begin POC" → technical audience
   "Roll out to team" / "Begin training" → operations audience
   "Review findings" / "Consider recommendations" → advisory/board audience

3. TONE ANALYSIS:
   Formal + quantified → executive or board
   Technical + detailed → engineering
   Practical + action-oriented → operations
   Academic + evidence-based → research/advisory

4. COMBINE signals:
   IF 2+ signals agree → use that audience type (confidence 0.7)
   IF signals conflict → use "mixed" (confidence 0.5)
   IF no clear signals → use "executive" as default (confidence 0.4)
```

### Lean Mode Output: Audience Model Object

```text
AUDIENCE MODEL (Lean):
  mode: lean
  source: inferred
  confidence: {0.4-0.7}

  primary_decision_maker:
    role: {inferred_type}
    title: "{inferred — e.g., 'Executive decision-maker'}"
    top_priority: "{inferred from narrative emphasis}"
    top_objection: "{inferred from counterarguments in narrative, or 'Not available'}"

  stakeholders: []  (empty — no structured data available)

  champion:
    identified: false
    title: "Not available"
    motivation: "Not available"

  blockers:
    count: 0
    entries: []

  assumption_based: true
```

---

## How Downstream Steps Use the Audience Model

| Step | Rich Mode Usage | Lean Mode Usage |
|------|----------------|-----------------|
| **3b** Governing thought | Evaluate candidates against primary decision-maker's top priority | Evaluate against inferred audience type's "so what" |
| **3c** Section roles | Weight dual-role sections by primary decision-maker's concerns | Use authorial intent (unchanged from current) |
| **4** Message architecture | Protect primary-priority slides during consolidation | Standard consolidation (unchanged) |
| **5a** Evidence selection | Rank by alignment with stakeholder priorities; use buyer role tags | Current heuristic ("for a CFO audience...") |
| **8c** Stakeholder Briefing + Speaker-Notes Q&A | Format Stakeholder Briefing from Audience Model; use actual objections for per-slide Q&A prep (3-5 items); blocker = uncomfortable question | Skip Stakeholder Briefing; generic role-based Q&A prediction (CFO/CTO/etc.) |

---

## Content Checkpoint

After building the Audience Model, state:

```text
"Audience Model: {rich/lean}, confidence {N}.
 Primary decision-maker: {role} — {title}.
 Top priority: {priority}. Top objection: {objection}.
 Stakeholders: {count}. Champion: {identified/not}. Blockers: {count}."
```

This checkpoint is consumed by Step 3 as input context.

---

## Edge Cases

```text
EDGE CASE 1: Caller provides audience_context but fields are empty
  → Treat as Lean mode (confidence 0.5)
  → Log: "Caller provided audience_context but fields were empty — falling back to Lean mode"

EDGE CASE 2: pitch-log.json has buying_center.source == "industry_assumptions"
  → Still Rich mode, but set assumption_based = true
  → Downstream: Stakeholder Briefing slide appends "(assumption-based)" to title

EDGE CASE 3: Narrative has buyer role tags but no audience_context
  → Lean mode for Audience Model
  → BUT: Steps 5a/5b can still use inline [ECONOMIC-BUYER] tags for per-section targeting
  → These tags are narrative-level, not audience-model-level

EDGE CASE 4: Multiple sources conflict (caller says EB="CFO", pitch-log says EB="VP Finance")
  → Caller-provided data wins (it is more recent and explicitly passed)
  → Do NOT merge from multiple sources — use one authoritative source
```
