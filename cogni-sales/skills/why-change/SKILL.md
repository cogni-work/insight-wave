---
name: why-change
description: "Create a Why Change sales pitch for a named customer. Produces sales-presentation.md and sales-proposal.md using the Corporate Visions methodology (Why Change, Why Now, Why You, Why Pay). Builds on cogni-portfolio propositions and solutions with customer-specific web research. Use when the user mentions 'sales pitch', 'why change', 'acquisition pitch', 'create a pitch for [customer]', 'sales presentation', 'proposal for [customer]', 'pitch for [company]', 'new customer pitch', or wants to create B2B sales materials for a named prospect — even if they don't say 'why change' explicitly."
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch
---

# Why Change Pitch

Create a "Why Change" sales pitch for a named customer using the Corporate Visions methodology. Produces two deliverables: `sales-presentation.md` (narrative arc) and `sales-proposal.md` (formal proposal with pricing).

## Prerequisites

- At least one cogni-portfolio project with products, features, propositions, and solutions
- A named customer to pitch to (company name + industry)
- Optional: cogni-tips project with value-modeler completed (enriches with trend evidence)

## Arc Methodology

This skill applies the Corporate Visions story arc defined in cogni-narrative:
- `cogni-narrative/skills/narrative/references/story-arc/corporate-visions/arc-definition.md`

The arc has four elements, each with detailed patterns the researcher agent reads and applies:
1. **Why Change** — Disrupt status quo with unconsidered needs (PSB structure)
2. **Why Now** — Create urgency with forcing functions and cost of inaction
3. **Why You** — Differentiate with Power Positions (IS/DOES/MEANS)
4. **Why Pay** — Build business case with compound cost calculation

## Workflow

### Phase 0: Setup

#### Step 0.1: Portfolio Discovery

Run the discovery script to find available portfolios:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/discover-portfolio.sh" --workspace "$(pwd)"
```

Present discovered portfolios to the user:
```
Portfolio projects found:
  1. acme-cloud (4 products, 12 features, 3 markets, 8 propositions)
```

If only one portfolio: confirm automatically. If multiple: ask user to select.

#### Step 0.2: Customer Details

Collect customer information via AskUserQuestion:

1. **Customer name** (required): "Which customer are you pitching to?"
2. **Customer industry** (required): "What industry is {customer} in?"
3. **Customer domain** (optional): "Do you have their website domain? (helps with research)"

#### Step 0.3: Market Matching

Read all markets from the selected portfolio (`markets/*.json`). Match `customer_industry` to market segments by vertical/industry alignment.

- If a single market matches: auto-select
- If multiple match: present options and ask user
- If none match: warn user that propositions may be generic, proceed with best-fit

Set `market_slug` in pitch-log.json.

#### Step 0.4: TIPS Discovery (Optional)

Glob for `**/tips-value-model.json` in the workspace. If found:
- Check if the TIPS industry aligns with the customer's industry
- If aligned: set `tips_path` in pitch-log.json (enables enriched evidence in all phases)
- If not aligned or not found: proceed in portfolio-only mode (`tips_path: null`)

Inform the user: "Found TIPS project for {industry} — will enrich with strategic trend evidence" or "No TIPS data found — proceeding with portfolio data only."

#### Step 0.5: Solution Focus

Read products and features from the portfolio. Ask the user:

"Would you like to pitch the full portfolio or focus on specific products/features?"

- **Full portfolio**: leave `solution_focus` empty
- **Specific features**: user selects from list, store slugs in `solution_focus`

#### Step 0.6: Buyer Roles (Lightweight)

Ask the user for key buyer roles:
- "Who is the economic buyer? (title)" — e.g., CIO, CFO, VP Operations
- "Who evaluates technically? (title)" — e.g., Cloud Architect, Head of IT

Store titles in `buying_center` in pitch-log.json. If the matched market has buyer personas (`customers/{market}.json`), load their priorities as defaults.

#### Step 0.7: Language

Check for `.workspace-config.json` in the working directory. If it has a `language` field, use it. Otherwise ask:

"Should the pitch be in English or German?"

#### Step 0.8: Initialize Project

Run the initialization script:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/init-pitch-project.sh" \
  --customer-name "{customer_name}" \
  --language "{language}" \
  --workspace "$(pwd)"
```

Then update `pitch-log.json` with all collected context (customer_domain, customer_industry, market_slug, portfolio_path, tips_path, company_name, solution_focus, buying_center).

**-> Proceed immediately to Phase 1.**

---

### Phase 1: Why Change

Delegate to the why-change-researcher agent:

```
Agent tool:
  agent: why-change-researcher
  prompt: |
    project_path: {project_path}
    phase: why-change
```

The agent will:
- Read `why-change-patterns.md` from cogni-narrative (PSB structure, contrast patterns)
- Load portfolio propositions (IS/DOES/MEANS for matched market)
- "Work backwards" from portfolio capabilities to customer problems
- Perform web research on {customer_name} challenges and industry blind spots
- Write `01-why-change/research.json` and `01-why-change/narrative.md`

**Quality Gate:** Present the key findings to the user:

```
Phase 1: Why Change — Key Findings for {customer_name}

Unconsidered needs identified:
1. [headline] — [one-line summary with key evidence]
2. [headline] — [one-line summary]
3. [headline] — [one-line summary]

Claims registered: N (for verification)

Approve to continue, or provide feedback to revise.
```

Use AskUserQuestion with options: "Approve and continue", "Revise with feedback".

If revise: re-invoke the researcher with user feedback appended to the prompt.
If approve: update pitch-log.json (`phases_completed += ["why-change"]`, `current_phase = "why-now"`).

**-> Proceed immediately to Phase 2.**

---

### Phase 2: Why Now

Delegate to the why-change-researcher agent:

```
Agent tool:
  agent: why-change-researcher
  prompt: |
    project_path: {project_path}
    phase: why-now
```

The agent will:
- Read `why-now-patterns.md` from cogni-narrative (forcing functions, urgency quantification)
- Load Phase 1 bridge file for context
- Research regulatory deadlines, competitive pressure, market timing for {customer_name}
- Write `02-why-now/research.json` and `02-why-now/narrative.md`

**Quality Gate:** Present timing triggers and cost of inaction summary. Same approve/revise pattern.

Update pitch-log.json. **-> Proceed to Phase 3.**

---

### Phase 3: Why You

Delegate to the why-change-researcher agent:

```
Agent tool:
  agent: why-change-researcher
  prompt: |
    project_path: {project_path}
    phase: why-you
```

The agent will:
- Read `why-you-patterns.md` from cogni-narrative (Power Positions, IS-DOES-MEANS)
- Load portfolio propositions, solutions, and competitor data
- Create 2-3 Power Positions mapped to buyer needs from Phase 1
- Write `03-why-you/research.json` and `03-why-you/narrative.md`

**Quality Gate:** Present Power Positions table with IS/DOES/MEANS. Same approve/revise pattern.

Update pitch-log.json. **-> Proceed to Phase 4.**

---

### Phase 4: Why Pay

Delegate to the why-change-researcher agent:

```
Agent tool:
  agent: why-change-researcher
  prompt: |
    project_path: {project_path}
    phase: why-pay
```

The agent will:
- Read `why-pay-patterns.md` from cogni-narrative (compound cost calculation)
- Load Phase 2 cost-of-inaction data + Phase 3 capability outcomes
- Load solution pricing tiers from portfolio
- Build ROI model: cost of inaction vs investment
- Write `04-why-pay/research.json` and `04-why-pay/narrative.md`

**Quality Gate:** Present business case summary with investment vs inaction ratio. Same approve/revise pattern.

Update pitch-log.json. **-> Proceed to Phase 5.**

---

### Phase 5: Synthesize

Delegate to the pitch-synthesizer agent:

```
Agent tool:
  agent: pitch-synthesizer
  prompt: |
    project_path: {project_path}
```

The agent will:
- Read all 4 phase bridge files and narratives
- Read output-specs.md templates
- Assemble `output/sales-presentation.md` and `output/sales-proposal.md`
- Renumber citations sequentially

Update pitch-log.json (`phases_completed += ["synthesize"]`, `current_phase = "done"`).

### Completion

Present the deliverables to the user:

```
Pitch complete for {customer_name}!

Deliverables:
  - {project_path}/output/sales-presentation.md (Why Change narrative)
  - {project_path}/output/sales-proposal.md (formal proposal with pricing)

Claims registered: {N} — run `/claims verify` to validate sources.

Optional next steps:
  - `/copywrite sales-presentation.md` — polish with cogni-copywriting
  - `/pptx create sales-presentation.md` — generate slide deck via cogni-visual
```

---

## Resuming an Interrupted Pitch

If the user wants to continue a pitch that was interrupted:

1. Run `pitch-status.sh` on the project path
2. Read `workflow_state.current_phase` and `phases_completed`
3. Resume from the incomplete phase

## Error Handling

- If portfolio has no propositions for the matched market: warn user, suggest running cogni-portfolio propositions skill first
- If web research returns thin results for named customer: degrade gracefully to industry-level research
- If cogni-narrative arc files not found: error — cogni-narrative plugin must be installed
