# Course 11: Consulting Orchestration (Double Diamond)

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Courses 1-10 (capstone)
**Plugin**: cogni-consulting (v0.1.0, 7 skills, 1 agent, 1 hook)
**Audience**: Consultants running structured engagements across the insight-wave ecosystem

---

## Module 1: The Double Diamond & Vision Framing

### Theory (3 min)

**cogni-consulting** is the orchestrator that ties the entire insight-wave ecosystem together.
Instead of producing content itself, it manages engagement state and dispatches to the
right plugin at the right moment.

**The Double Diamond framework** structures every engagement into two diamonds:

```
Diamond 1 (Problem Space)          Diamond 2 (Solution Space)
    Discover → Define                  Develop → Deliver
    (diverge)  (converge)              (diverge)  (converge)
```

- **Discover** (D1 diverge): Build rich understanding — research, trends, competitive baseline
- **Define** (D1 converge): Synthesize into a problem statement — verify assumptions, frame "How Might We"
- **Develop** (D2 diverge): Generate solution options — value modeling, proposition design
- **Deliver** (D2 converge): Evaluate, verify claims, build the business case

**Vision classes** drive the entire engagement. The vision class you choose at setup
determines which methods are proposed, which plugins are dispatched, and what
deliverables are produced:

| Vision Class | Outcome | Typical Duration |
|---|---|---|
| `strategic-options` | Ranked strategic alternatives | 4-8 weeks |
| `business-case` | Investment justification with financials | 3-6 weeks |
| `gtm-roadmap` | Go-to-market plan with timeline | 4-6 weeks |
| `cost-optimization` | Prioritized cost reduction opportunities | 3-5 weeks |
| `digital-transformation` | Current→target state with transition roadmap | 6-12 weeks |
| `innovation-portfolio` | Prioritized innovation bets across horizons | 4-8 weeks |
| `market-entry` | Market feasibility and entry strategy | 4-8 weeks |

**Getting started**: The `consulting-setup` skill launches the engagement. It asks for the
client, context, and desired outcome — then recommends a vision class and scaffolds the
project directory.

### Demo

Walk through engagement setup:
1. Run `consulting-setup` for a sample client engagement
2. Show how the vision class selection works — describe the outcome, get a recommendation
3. Walk through the project directory structure created by `engagement-init.sh`:
   - `consulting-project.json` — engagement config, vision, phase state
   - `.metadata/` — execution-log, method-log, decision-log
   - `discover/`, `define/`, `develop/`, `deliver/` — phase output directories
   - `output/` — final deliverable package
4. Show the `consulting-project.json` file — vision class, phase states, plugin references
5. Note: if an engagement already exists, `consulting-resume` is used instead

### Exercise

Ask the user to:
1. Think of a real or realistic consulting engagement
2. Identify the client, context, and desired outcome
3. Which vision class fits? Match the outcome to the table above
4. Run `consulting-setup` and complete the engagement scaffolding

### Quiz

1. **Multiple choice**: What is the purpose of the vision class?
   - a) It determines the project budget
   - b) It drives which methods, plugins, and deliverables are used throughout the engagement
   - c) It replaces the need for client input
   - d) It only affects the final deliverable format
   **Answer**: b

2. **Multiple choice**: What are the four phases of the Double Diamond?
   - a) Plan, Build, Test, Ship
   - b) Research, Write, Review, Publish
   - c) Discover, Define, Develop, Deliver
   - d) Analyze, Design, Implement, Monitor
   **Answer**: c

### Recap

- cogni-consulting orchestrates — it manages state, not content
- Two diamonds: problem space (Discover → Define) and solution space (Develop → Deliver)
- 7 vision classes map engagement types to methods and deliverables
- `consulting-setup` is the entry point: client + context + outcome → vision class → project scaffold

---

## Module 2: Discover & Define (Diamond 1)

### Theory (3 min)

**Diamond 1** moves from broad understanding to a precise problem statement.

**Discover (D1 diverge)** builds the evidence base by dispatching to three plugins:

| Plugin | What It Does in Discover | Skill Invoked |
|--------|--------------------------|---------------|
| cogni-research | Web research on the client's domain, competitive landscape | research-report |
| cogni-trends | Industry trend analysis, strategic foresight | trend-scout |
| cogni-portfolio | Existing portfolio scan, competitive positioning | portfolio-scan, compete |

The vision class determines which research methods are recommended. For example,
a `market-entry` engagement emphasizes competitive baseline and market sizing,
while an `innovation-portfolio` engagement emphasizes trend landscape and horizon scanning.

**10 guided methods** are available in the method library:
- desk-research-framing, stakeholder-mapping, data-audit, customer-journey-analysis, affinity-clustering
- assumption-mapping, hmw-synthesis, scenario-planning, opportunity-scoring, business-case-canvas

**Define (D1 converge)** synthesizes findings into a problem statement:
1. **Affinity clustering** — group discovery themes into clusters
2. **Assumption mapping** — identify and prioritize assumptions to verify
3. **Claims verification** — dispatch to cogni-claims to test key assumptions
4. **HMW synthesis** — reframe clusters as "How Might We" questions
5. **Problem statement** — crisp framing of the challenge to solve

### Demo

Walk through Diamond 1:
1. Run `consulting-discover` and observe which plugins are dispatched
2. Show how the method library recommends methods based on vision class
3. Review discovery outputs in the `discover/` directory
4. Run `consulting-define` — show assumption mapping and verification
5. Show the synthesized problem statement in `define/`

### Exercise

Ask the user to:
1. For their engagement from Module 1, list 3 things they'd want to discover
2. Which insight-wave plugin would handle each? (researcher, tips, or portfolio?)
3. What are the top 2 assumptions that must be true for this engagement to succeed?
4. Frame one "How Might We" question from their engagement context

### Quiz

1. **Multiple choice**: Which plugin handles competitive landscape research in the Discover phase?
   - a) cogni-claims
   - b) cogni-research
   - c) cogni-visual
   - d) cogni-narrative
   **Answer**: b

2. **Multiple choice**: What is the purpose of the Define phase?
   - a) Generate solution options
   - b) Build the business case
   - c) Synthesize findings into a problem statement through assumption verification and HMW framing
   - d) Create the final deliverables
   **Answer**: c

### Recap

- Discover dispatches to cogni-research, cogni-trends, and cogni-portfolio
- The vision class determines which methods are recommended
- Define synthesizes: cluster → verify assumptions → HMW questions → problem statement
- Key output: a crisp problem statement that focuses Diamond 2

---

## Module 3: Develop & Deliver (Diamond 2)

### Theory (3 min)

**Diamond 2** moves from the problem statement to a validated solution.

**Develop (D2 diverge)** generates solution options by dispatching to:

| Plugin | What It Does in Develop | Skill Invoked |
|--------|-------------------------|---------------|
| cogni-trends | Value modeling — solution templates, TIPS paths, investment themes | value-modeler |
| cogni-portfolio | Proposition design, market-specific messaging, packaging | propositions, solutions |

Methods commonly used in Develop:
- **Scenario planning** — build 2x2 scenario matrices to stress-test options
- **Opportunity scoring** — score options with weighted criteria
- The vision class may recommend additional methods (e.g., business-case-canvas for `business-case`)

**Deliver (D2 converge)** evaluates options and builds the business case:

1. **Option evaluation** — compare scenarios with decision criteria
2. **Claims verification** — dispatch to cogni-claims to validate key claims
3. **Portfolio validation** — dispatch to cogni-portfolio for positioning check
4. **Business case** — financial projections, ROI, risk analysis
5. **Roadmap** — phased implementation plan with milestones

The output of Deliver is a recommendation backed by evidence, not just an opinion.

### Demo

Walk through Diamond 2:
1. Run `consulting-develop` — observe value-modeler and proposition dispatch
2. Show solution options generated in `develop/`
3. Walk through scenario planning or opportunity scoring for the engagement
4. Run `consulting-deliver` — show claims verification and business case assembly
5. Review the recommendation and roadmap in `deliver/`

### Exercise

Ask the user to:
1. For their engagement, brainstorm 3 possible solution directions
2. Define 3 evaluation criteria (e.g., feasibility, impact, time-to-value)
3. Score each option against the criteria (simple 1-5 scale)
4. Which option would they recommend? Why?

### Quiz

1. **Multiple choice**: Which plugin handles value modeling in the Develop phase?
   - a) cogni-portfolio
   - b) cogni-claims
   - c) cogni-trends
   - d) cogni-research
   **Answer**: c

2. **Multiple choice**: What distinguishes Deliver from Develop?
   - a) Deliver generates more options
   - b) Deliver evaluates and converges — turning options into a validated recommendation with a business case
   - c) Deliver only creates slides
   - d) There is no difference
   **Answer**: b

### Recap

- Develop dispatches to cogni-trends (value-modeler) and cogni-portfolio (propositions)
- Methods: scenario planning, opportunity scoring, business-case-canvas
- Deliver converges: evaluate → verify → build business case → roadmap
- Output: an evidence-backed recommendation, not just an opinion

---

## Module 4: Multi-Session Management & Phase Gates

### Theory (3 min)

Real engagements span days or weeks. cogni-consulting is built for multi-session work.

**consulting-resume** is your re-entry point. It reads `consulting-project.json` and shows:
- Current phase and phase status (pending → in-progress → complete)
- Which plugins have been dispatched and what they produced
- Methods used and decisions logged
- Recommended next action

**Phase gates** are advisory checkpoints between phases:
- The `phase-gate-guard` hook (PreToolUse) warns if prerequisites are incomplete
- **Warn, not block** — the consultant can always override and proceed
- Phase gate criteria come from the vision class: a `business-case` engagement
  requires financial data before Deliver; a `strategic-options` engagement
  requires at least 3 evaluated options

**Engagement state tracking**:
- `.metadata/execution-log.json` — what was done, when, by which plugin
- `.metadata/method-log.json` — which methods were used in each phase
- `.metadata/decision-log.json` — key decisions and their rationale

**The `engagement-status.sh` script** provides a quick JSON status check
without loading the full skill — useful for scripting or quick progress reviews.

### Demo

Walk through multi-session management:
1. Run `consulting-resume` on the engagement from earlier modules
2. Show the status dashboard — phase state, plugin refs, methods used
3. Demonstrate a phase gate warning: try to advance past an incomplete phase
4. Show the `.metadata/` logs — execution, method, and decision history
5. Run `engagement-status.sh` for the JSON status view

### Exercise

Ask the user to:
1. Review their engagement's current status via `consulting-resume`
2. Identify: what's the next action the system recommends?
3. Check the decision log — are all key decisions captured?
4. Scenario: a client meeting moved up by a week. Which phase could you skip to?
   What would the phase gate warn about?

### Quiz

1. **Multiple choice**: What does consulting-resume show?
   - a) Only the final deliverables
   - b) Phase state, plugin dispatches, methods used, decisions logged, and recommended next action
   - c) Only the engagement name
   - d) A list of all insight-wave plugins
   **Answer**: b

2. **Multiple choice**: Why are phase gates advisory rather than blocking?
   - a) Because the system doesn't have enough data to block
   - b) Because the consultant's judgment may override — sometimes you need to skip ahead for good reasons
   - c) Because blocking would cause errors
   - d) Phase gates don't exist
   **Answer**: b

### Recap

- `consulting-resume` is the re-entry point for multi-session engagements
- Phase gates warn but don't block — consultant judgment takes precedence
- Three logs track what happened: execution, methods, decisions
- `engagement-status.sh` provides quick JSON status without loading the skill

---

## Module 5: Export & Full Pipeline Integration

### Theory (3 min)

**consulting-export** generates the final deliverable package by dispatching to:

| Plugin | What It Produces | Formats |
|--------|-----------------|---------|
| cogni-visual | Slide decks, big-picture journey maps, solution architectures | PPTX, Excalidraw |
| document-skills | Reports, proposals, spreadsheets | DOCX, XLSX, PDF |

The **deliverable map** links each vision class to its recommended deliverable package:
- `strategic-options` → Options deck (PPTX) + evaluation matrix (XLSX) + recommendation report (DOCX)
- `business-case` → Business case document (DOCX) + financial model (XLSX) + executive summary deck (PPTX)
- `gtm-roadmap` → GTM plan (DOCX) + timeline (Excalidraw) + channel strategy deck (PPTX)
- And so on for all 7 vision classes

**The full pipeline** — how cogni-consulting orchestrates the entire ecosystem:

```
consulting-setup (vision framing)
    │
    ├── Discover: cogni-research + cogni-trends + cogni-portfolio
    │
    ├── Define: cogni-claims (verify assumptions)
    │
    ├── Develop: cogni-trends (value-modeler) + cogni-portfolio (propositions)
    │
    ├── Deliver: cogni-claims (verify claims) + cogni-portfolio (validate)
    │
    └── Export: cogni-visual + document-skills → final deliverable package
```

Every plugin you learned in Courses 1-10 has a role in this pipeline. cogni-consulting
doesn't replace them — it sequences their work and maintains the thread across sessions.

### Demo

Walk through export and the full pipeline:
1. Run `consulting-export` and observe the deliverable generation
2. Show the deliverable map for the engagement's vision class
3. Review the `output/` directory — all deliverables in one place
4. Trace the full pipeline: from vision framing through all four phases to final deliverables
5. Show how each plugin's output feeds into the next phase

### Exercise

Ask the user to:
1. Map their engagement end-to-end through all four phases:
   - **Discover**: What would cogni-research research? What trends would cogni-trends scout?
   - **Define**: What assumptions need verification via cogni-claims?
   - **Develop**: What value models (cogni-trends) and propositions (cogni-portfolio) would emerge?
   - **Deliver**: What claims need final verification? What does the business case include?
   - **Export**: What deliverables does their vision class require?
2. Which phase would take the longest for their engagement? Why?
3. Where would they override a phase gate if pressed for time?

### Quiz

1. **Hands-on**: Describe the full pipeline for your engagement from setup to export.
   Name each plugin and what it produces at each phase.

2. **Multiple choice**: What determines which deliverables are produced in the export phase?
   - a) The client's preference
   - b) The vision class selected during setup
   - c) The number of phases completed
   - d) The export skill always produces the same outputs
   **Answer**: b

### Recap

- `consulting-export` generates deliverables by dispatching to cogni-visual and document-skills
- The deliverable map links vision classes to recommended output formats
- The full pipeline: setup → discover → define → develop → deliver → export
- Every insight-wave plugin has a role; cogni-consulting sequences their work

---

## Course Completion

Congratulations — you have completed all 11 courses in the cogni-help curriculum!

**Your complete insight-wave toolkit (13 plugins)**:
1. **Claude Cowork** — Your agentic AI platform (Course 1)
2. **cogni-workspace** — Shared project foundation (Course 2)
3. **cogni-obsidian** — Knowledge management dashboard (Course 2)
4. **cogni-copywriting** — Document polishing & stakeholder review (Course 3)
5. **cogni-narrative** — Executive narrative transformation (Course 3)
6. **cogni-claims** — Citation verification (Course 3)
7. **cogni-trends** — Strategic trend research pipeline (Courses 4-5)
8. **cogni-portfolio** — Product/service messaging (Course 6)
9. **cogni-visual** — Presentations & visual deliverables (Course 7)
10. **cogni-research** — Multi-agent research reports (Course 8)
11. **cogni-marketing** — B2B content engine (Course 9)
12. **cogni-sales** — Sales pitch generation (Course 10)
13. **cogni-consulting** — Double Diamond consulting orchestrator incl. Lean Canvas (Courses 6, 11)

**The consulting meta-workflow**:
```
Lean Canvas (hypothesis, via cogni-consulting) → Portfolio (messaging) → Research → Analyze → Write → Verify → Polish → Market → Sell → Present
                                              └─── cogni-consulting orchestrates all of this ───┘
```

Every step has a insight-wave plugin. cogni-consulting ties them together into structured
engagements with phase-gated delivery and multi-session state management.
Your expertise drives the strategy; the tools execute the heavy lifting.

**Something unclear or broken?** Tell Claude what happened — cogni-issues will help you file it.
