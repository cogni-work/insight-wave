---
name: diamond-develop
description: |
  Execute the Develop phase of a Double Diamond engagement — diverge to generate and explore solution
  options. Dispatches to cogni-tips value-modeler and cogni-portfolio for proposition modeling.
  Use whenever the user wants to brainstorm solutions, generate options, or explore alternatives
  within a diamond engagement. Trigger on: "generate options", "what could we do", "solution ideas",
  "brainstorm solutions", "develop phase", "explore alternatives", "scenario planning",
  "model the propositions", "what are our options", "create strategic choices",
  "develop solutions", "D2 diverge", "option generation", "how could we solve this",
  "let's get creative", "value modeling", "solution space", or any request to generate solution
  options after a problem has been defined. Also trigger when the user proposes a specific solution —
  this skill ensures it's evaluated alongside alternatives rather than adopted uncritically.
---

# Diamond Develop — Diverge to Create Options

Generate and explore solution options that address the problem statement from Define. This is the first phase of Diamond 2 — the goal is to create a rich option space before converging on the best path in Deliver.

## Core Concept

Develop is the creative engine of the engagement. With a clear problem statement and HMW questions from Define, this phase generates multiple possible solutions — not just the obvious one. Good consulting surfaces options the client hadn't considered, challenges "we've always done it this way" thinking, and creates genuine strategic choices.

The key principle: **generate before evaluating**. Evaluating during generation kills options prematurely — an idea that sounds weak in isolation may become the strongest when combined with another. Develop creates the option space; Deliver evaluates it.

## Prerequisites

- Define phase should be complete (problem statement and HMW questions exist)
- Read `define/problem-statement.md` and `define/hmw-questions.md` as the brief for this phase

## Workflow

### 1. Load Context

Read diamond-project.json, `define/problem-statement.md`, and `define/hmw-questions.md`.

Update phase state:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" develop in-progress
```

### 2. Propose Develop Methods

Read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md` for the vision class's recommended Develop methods.

**Plugin-powered methods**:

| Method | Plugin | What It Produces |
|---|---|---|
| Value modeling | cogni-tips | TIPS paths from trends to solutions, ranked by business relevance |
| Proposition modeling | cogni-portfolio | IS/DOES/MEANS messaging for Feature × Market pairs |
| Solution design | cogni-portfolio | Implementation phases and pricing tiers |

**Guided methods**:

| Method | What It Produces | Reference |
|---|---|---|
| Scenario planning | 2-4 future scenarios with implications | `references/methods/scenario-planning.md` |
| Opportunity scoring | Scored option matrix with criteria | `references/methods/opportunity-scoring.md` |

Ask: "Which methods do you want for option generation? I recommend [2-3 based on vision class]. You can adjust."

### 3. Value Modeling (cogni-tips)

If the engagement has a tips project from Discovery (check `plugin_refs.tips_project`):

1. Dispatch `cogni-tips:value-modeler` on the existing trend candidates
2. The value modeler translates trend candidates into TIPS paths (Trend → Implication → Possibility → Solution)
3. Solutions are ranked by business relevance score
4. Store value model outputs in `develop/options/tips-solutions.md`

If no tips project exists, offer to run `trend-scout` first or skip this method.

### 4. Proposition Modeling (cogni-portfolio)

If the engagement has a portfolio project (check `plugin_refs.portfolio_project`):

1. Ensure features and markets are defined (from Discovery competitive baseline)
2. Dispatch `cogni-portfolio:propositions` for Feature × Market pairs
3. Each proposition generates IS (what it is), DOES (what advantage it creates), MEANS (what benefit the buyer gets)
4. Optionally dispatch `cogni-portfolio:solutions` for implementation phasing
5. Store proposition summaries in `develop/propositions/`

If no portfolio exists, offer to set one up or skip.

### 5. Scenario Planning (Guided)

Read `$CLAUDE_PLUGIN_ROOT/references/methods/scenario-planning.md` and guide the consultant:

1. Identify 2 critical uncertainties from the problem statement
2. Create a 2×2 matrix using these uncertainties as axes
3. Name and describe 4 resulting scenarios
4. For each scenario, assess: implications for the client, required capabilities, risk profile
5. Map existing options from value modeling against scenarios

Save to `develop/scenarios/scenario-matrix.md`.

### 6. Option Synthesis

After all methods complete, synthesize the options:

1. Consolidate solutions from TIPS value modeling, portfolio propositions, and scenario analysis
2. Group into 3-7 distinct strategic options
3. For each option, capture:
   - **Name**: Short, descriptive label
   - **Description**: What this option entails
   - **Source**: Which method surfaced it (TIPS, portfolio, scenario)
   - **Alignment**: Which HMW question(s) it addresses
   - **Key assumptions**: What must be true for this to work
4. Present the option space to the consultant for review

Save to `develop/options/option-synthesis.md`.

**Example option entry** (digital-transformation engagement for field service):
> **Option 3: "Mobile-First Field Platform"**
> Build a unified mobile app replacing 4 legacy field tools. Technicians get real-time job scheduling, parts inventory, and customer history in one interface.
> *Source*: TIPS value modeling (mobile workforce trend) + portfolio proposition (field service × mid-market)
> *Alignment*: HMW #1 (reduce time-to-resolution) and HMW #3 (improve first-visit fix rate)
> *Key assumptions*: Field technicians have reliable mobile connectivity; legacy systems expose APIs for integration.

Present options as equals — ranking happens in Deliver with structured criteria and consultant judgment.

### 7. Log and Transition

Update method log and decision log.

Present the Develop summary:

> **Develop phase complete.**
> - TIPS solutions generated: N (top 3: ...)
> - Propositions modeled: N Feature × Market pairs
> - Scenarios mapped: 4 (2×2 matrix)
> - Strategic options synthesized: N
>
> Ready to move to Deliver? The final phase will evaluate options, verify claims, build the business case, and generate deliverables.

Mark Develop complete:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/update-phase.sh "<project-dir>" develop complete
```

## Method Adaptation

For vision-class-specific method recommendations, read `$CLAUDE_PLUGIN_ROOT/references/vision-classes.md`.

## When Things Go Thin

- **Only 1-2 options emerge**: The divergence was too narrow. Before accepting a thin option space, try these prompts with the consultant: "What would a competitor do?", "What if budget were unlimited?", "What's the opposite of our first option?", "What would we recommend if the constraint on [X] didn't exist?" These reframing questions often unlock options that were implicitly excluded.
- **Plugin returns no usable solutions**: If value modeling or proposition modeling produces generic or irrelevant output, the input framing may need adjustment. Re-read the problem statement — is it specific enough to generate differentiated solutions? Sometimes the best response is to refine the HMW questions rather than forcing the plugin.
- **Consultant fixates on one option early**: This is natural but undermines the divergent purpose of this phase. Acknowledge the preferred option explicitly, then say: "Let's develop 2-3 more alternatives so we can compare properly in Deliver. Even if this option wins, the comparison strengthens the recommendation."

## Important Notes

- Record why certain options were generated (the reasoning, not just the option) — this traceability matters in Deliver when building the business case
- Cross-reference: if a TIPS solution and a portfolio proposition point to the same thing, note the convergence — it's a signal of robustness
- Scenario planning is particularly valuable for high-uncertainty vision classes where the future state is contested
- If the consultant wants to revisit the problem statement based on what options emerge, that's healthy — the diamond process supports iteration within phases
