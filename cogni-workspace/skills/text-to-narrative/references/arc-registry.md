# Story Arc Registry

The selection contract for the `text-to-narrative` skill: which arc a run should follow, and how that is decided. Each arc's structure — headings, composition, elements, validation — lives in its own contract at `arc-{arc-id}.md`; this file carries only what selection needs, as one declarative block per arc, and the algorithm that reads those blocks.

## Contents

- [Quick Reference](#quick-reference)
- [Arc Selection Logic](#arc-selection-logic)
- [Arc Blocks](#arc-blocks)
  - [corporate-visions](#corporate-visions)
  - [technology-futures](#technology-futures)
  - [competitive-intelligence](#competitive-intelligence)
  - [strategic-foresight](#strategic-foresight)
  - [industry-transformation](#industry-transformation)
  - [trend-panorama](#trend-panorama)
  - [smarter-service](#smarter-service)
  - [theme-thesis](#theme-thesis)
  - [jtbd-portfolio](#jtbd-portfolio)
  - [company-credo](#company-credo)
  - [engagement-model](#engagement-model)
  - [consulting-problem-solving](#consulting-problem-solving)
  - [strategic-choice](#strategic-choice)
  - [customer-transformation](#customer-transformation)
  - [category-creation](#category-creation)
- [Arc Detection Algorithm](#arc-detection-algorithm)
  - [Step 1: Explicit selection](#step-1-explicit-selection)
  - [Step 2: Structural detection (trend-panorama / smarter-service)](#step-2-structural-detection-trend-panorama-smarter-service)
  - [Step 3: Content-type mapping](#step-3-content-type-mapping)
  - [Step 4: Execution-fit ranking](#step-4-execution-fit-ranking)
  - [Step 5: Target-fit ranking](#step-5-target-fit-ranking)
  - [Step 6: Content analysis](#step-6-content-analysis)
  - [Step 7: Fallback](#step-7-fallback)
- [Arc Directory Structure](#arc-directory-structure)
- [Interactive Selection Format](#interactive-selection-format)
- [Extension Guidelines](#extension-guidelines)
  - [Adding an arc](#adding-an-arc)
  - [Quality standards](#quality-standards)


## Quick Reference

| Arc ID | Elements | Governing question (short) | Primary signal |
|--------|----------|----------------------------|----------------|
| `corporate-visions` | Why Change → Why Now → Why You → Why Pay | Why change, why now, why us, why pay? | default candidate |
| `technology-futures` | What's Emerging → What's Converging → What's Possible → What's Required | What matures, combines, unlocks, requires? | `content_type: technology` |
| `competitive-intelligence` | Landscape → Shifts → Positioning → Implications | Where do competitors stand, how is that moving, where are the gaps, by when? | `content_type: competitive` |
| `strategic-foresight` | Signals → Scenarios → Strategies → Decisions | Which futures are plausible, what holds across them, what must be decided now? | `content_type: foresight` |
| `industry-transformation` | Forces → Friction → Evolution → Leadership | What restructures the industry, what resists, what emerges, who leads? | `content_type: industry` |
| `trend-panorama` | Forces → Impact → Horizons → Foundations | What is the whole TIPS landscape and what does it demand? | structural: trend-scout output, no value model |
| `smarter-service` | Forces → Impact → Horizons → Foundations | Where do the investment themes anchor in the TIPS landscape? | structural: `tips-value-model.json` |
| `theme-thesis` | Why Change → Why Now → Why You → Why Pay | Why invest in this one theme, now? | `content_type: theme` |
| `jtbd-portfolio` | Job Landscape → Friction Map → Portfolio Map → Invitation | Which jobs, which friction, which solution per job, where to start? | `content_type: jtbd` |
| `company-credo` | Mission → Conviction → Credibility → Promise | Why do we exist, what do we believe, why trust us, what can you expect? | `content_type: company-credo` |
| `engagement-model` | Principles → Process → Partnership → Outcomes | How do we work, step by step, and what will you point to? | `content_type: engagement-model` |
| `consulting-problem-solving` | Situation → Complication → Resolution → Implications | What is happening, why is the status quo insufficient, what is the answer, what follows? | `content_type: consulting` |
| `strategic-choice` | Context → Tension → Options → Choice | Which option, and why is it superior given the trade-offs? | `content_type: strategic-choice` |
| `customer-transformation` | Before → Struggle → Change → Outcome | What changed for the customer, and what verified outcome proves it? | `content_type: case-study` |
| `category-creation` | Status Quo → Shift → New Frame → Leadership | Why does the old category no longer fit, and what does leading the new one require? | `content_type: category-creation` |

## Arc Selection Logic

1. **Explicit selection** — `--arc-id` on the invocation, or an arc inherited from the source project's metadata (SKILL.md Phase 1 step 8). Highest priority; no detection runs.
2. **Structural detection** — arc-specific file signatures (the TIPS pair).
3. **Content-type mapping** — `content_type` or `research_type` metadata.
4. **Execution-fit ranking** — compare the strongest registered candidates against the Phase 0 brief: audience, decision purpose, perspective, geography and each arc's governing question. The decision purpose takes precedence over keyword density: a diagnostic purpose ranks a diagnostic arc above a persuasion arc even when the persuasion keywords are denser.
5. **Target-fit ranking** — when evidence and execution fit leave two or more defensible candidates, the requested `--target` breaks the tie: the arc whose chain reads best in that format ranks higher. Never overrides an explicit or inherited arc.
6. **Content analysis** — keyword density against each block's `signals`, discounted by its `anti_signals`.
7. **Fallback** — `corporate-visions` as a candidate for the shortlist, never an automatic winner.

The output of steps 2-7 is a ranked candidate set. Phase 2 presents the top two or three as a shortlist (see Interactive Selection Format); under `--interactive false` the top-ranked candidate is taken and the run summary retains the top two alternatives alongside it.

## Arc Blocks

One block per arc directory. Every block carries the same six fields; a block whose `distinguish_from` is empty is a registry defect, because it leaves the shortlist with nothing to weigh the arc against. Adding an arc means adding a block here and a contract in its directory — the guards enumerate both at run time.

### corporate-visions

- **question:** Why should the reader change, why now, why with this capability, and why does it pay?
- **best_for:** market research syntheses, competitive positioning, sales enablement, B2B value propositions, executive decision support.
- **signals:** `content_type: generic` or `market`; a problem executives underestimate; deadlines, regulatory dates, tipping points; recommended capabilities; quantified costs, risks or penalties.
- **anti_signals:** a documented customer journey with verified outcomes; named alternatives weighed against criteria; a solution portfolio for buyers who already want it; a company self-description; TIPS value chains.
- **distinguish_from:** `consulting-problem-solving` (diagnose an open problem and derive the answer — a diagnostic memo on Corporate Visions ends up with a Why Pay section); `strategic-choice` (choose among already-credible alternatives); `customer-transformation` (prove observed value through one customer's journey rather than persuade prospectively); `theme-thesis` (the same persuasion for one investment theme inside a TIPS report); `jtbd-portfolio` (buyers who already accept the need and want the portfolio explained); `industry-transformation` (structural change of a sector rather than one reader's decision); `competitive-intelligence` (positioning within a category rather than a case for change); `technology-futures` (a capability roadmap rather than persuasion); `strategic-foresight` (divergent futures rather than a present decision); `company-credo` (the company's identity rather than the reader's change); `category-creation` (reframes what the market buys rather than persuading one buyer inside the existing frame). Corporate Visions persuades a reader to change, act now, prefer a position and justify investment — it is not the arc for diagnosing, choosing or proving.
- **fallback_priority:** the default *candidate* when no specialized content type is detected — always on the shortlist in that case, never the automatic winner; the execution-fit step and the alternatives' governing questions decide.

### technology-futures

- **question:** Which capabilities are reaching practical maturity, how do they combine, what do the combinations make possible, and what must be in place to capture it?
- **best_for:** innovation and R&D syntheses, technology-trend research, capability roadmapping, technology scouting.
- **signals:** `content_type: technology`; keywords "emerging", "innovation", "capability", "technology", "R&D", "breakthrough", maturity markers, convergence, prerequisites.
- **anti_signals:** competitor positions and shares; a purchase or investment case; multiple divergent scenarios.
- **distinguish_from:** `competitive-intelligence` (competitors, not capabilities); `strategic-foresight` (uncertainty across futures rather than one capability path); `corporate-visions` (persuasion rather than a roadmap).
- **fallback_priority:** never a fallback.

### competitive-intelligence

- **question:** Where do the competitors stand, how is that changing, where are the gaps, and by when must we move?
- **best_for:** competitive analysis, threat assessment, positioning studies, market-structure research.
- **signals:** `content_type: competitive`; keywords "competitor", "market share", "positioning", "differentiation", "threat", "rivalry"; strategic moves with dates; white spaces.
- **anti_signals:** the source argues the category itself is wrong; the forces are regulatory or structural rather than competitive; a capability roadmap.
- **distinguish_from:** `category-creation` (change the buyer's frame of reference rather than position within a stable category); `industry-transformation` (macro forces on a sector rather than competitors' moves); `technology-futures` (capabilities rather than positions); `corporate-visions` (a case for change rather than a position within a stable category).
- **fallback_priority:** never a fallback.

### strategic-foresight

- **question:** What weak signals point to divergent futures, what plausible scenarios follow, which strategies hold across them, and what must be decided now?
- **best_for:** long-range planning, scenario analysis, foresight studies, strategy under regulatory or technological uncertainty.
- **signals:** `content_type: foresight` or `scenarios`; keywords "scenario", "future", "signal", "uncertainty", "planning", "foresight"; contradictory indicators; robust versus bet.
- **anti_signals:** evidence converging on one future; options already named and awaiting a choice; pressure to act now on a known need.
- **distinguish_from:** `technology-futures` (one capability path); `corporate-visions` (a known need and a present decision); `trend-panorama` (a landscape summary rather than divergent futures); `strategic-choice` (a present choice among credible options rather than divergent futures).
- **fallback_priority:** never a fallback.

### industry-transformation

- **question:** Which macro forces are restructuring the industry, what resists them, what does the industry become, and how does one lead in that new structure?
- **best_for:** industry analysis, regulatory-impact studies, sector-transformation research, thought leadership on structural change.
- **signals:** `content_type: industry`; keywords "regulatory", "sector", "structural", "industry", "transformation", "policy"; incumbents and barriers; a future industry structure.
- **anti_signals:** competitors' moves rather than macro forces; a single company's investment case; a new-category argument.
- **distinguish_from:** `category-creation` (proposes a new frame for what the market buys, rather than describing the sector's structural change); `competitive-intelligence` (positions within a stable category); `corporate-visions` (one reader's decision rather than a sector's transition); `trend-panorama` (a TIPS landscape rather than one industry's structural change).
- **fallback_priority:** never a fallback.

### trend-panorama

- **question:** Which external forces are reshaping the landscape, how do they disrupt value creation, what strategic possibilities open, and what capabilities are required?
- **best_for:** trend-scout output summaries, TIPS trend-report narratives without themes, multi-horizon trend landscapes, industry trend panoramas.
- **signals:** structural — `trend-scout-output.json` (in the source or `.metadata/`), trend entities with `planning_horizon` and `dimension` frontmatter, `tips-trend-report.md` — with **no** `tips-value-model.json`; `content_type: trend`, `trends` or `tips`; `research_type: smarter-service`; keywords "trend", "horizon", "act", "plan", "observe", "TIPS", "signal intensity", "dimension".
- **anti_signals:** `tips-value-model.json` present; a single theme with value chains; no horizon or dimension structure.
- **distinguish_from:** `smarter-service` (the same four elements with investment themes anchored — the value model decides); `theme-thesis` (one theme's thesis rather than the landscape); `strategic-foresight` (divergent futures rather than a horizon cascade); `industry-transformation` (one industry's structural change rather than a TIPS landscape).
- **fallback_priority:** never a fallback; the structural signal decides between this arc and `smarter-service` before keyword analysis.

### smarter-service

- **question:** Which external forces reshape the landscape, how do they disrupt value creation, where do the investment themes position, and what shared foundations must be built first?
- **best_for:** CxO-level TIPS trend reports with investment themes, board-level foresight briefings, multi-theme transformation roadmaps.
- **signals:** structural, highest confidence — `tips-value-model.json` (in the source or `.metadata/`), `tips-trend-report.md` with investment-theme sections; `content_type: smarter-service` or `investment-theme-report`; `research_type: smarter-service-themed`; keywords "investment theme", "Handlungsfeld", "value chain", "solution template", "Smarter Service", "Trendradar", "Externe Effekte", "Digitale Wertetreiber", "Neue Horizonte", "Digitales Fundament".
- **anti_signals:** trend-scout output with no value model; a single theme's value chains.
- **distinguish_from:** `trend-panorama` (theme-less sibling — fall back to it when the value model is absent); `theme-thesis` (the arc for one theme section inside a report built on this one).
- **fallback_priority:** never a fallback.

### theme-thesis

- **question:** Why must this theme change how the reader thinks, why is the window closing now, which portfolio capabilities answer it, and what does inaction cost?
- **best_for:** individual theme sections within TIPS trend reports, investment-thesis narratives for strategic themes, CxO-level theme justification.
- **signals:** `content_type: theme` or `investment-theme`; input carrying `theme_id`, `strategic_question`, `value_chains[]` with `candidate_ref`, `solution_templates[]`; keywords "theme", "investment thesis", "value chain", "solution template", "strategic question", "candidate_ref", "chain_score".
- **anti_signals:** a whole landscape with no theme boundary; persuasion with no TIPS value chains.
- **distinguish_from:** `corporate-visions` (the whole-report persuasion arc this one adapts); `smarter-service` (the report spine a theme sits inside); `trend-panorama` (the landscape, not one bet).
- **fallback_priority:** never a fallback.

### jtbd-portfolio

- **question:** What jobs does the buyer hire for, what stands in the way of each, which solution does each job, and where does the buyer start?
- **best_for:** portfolio introductions, capability overviews, pre-sales positioning, the `home` and `persona` scopes of cogni-portfolio's customer narrative.
- **signals:** `content_type: jtbd`; portfolio entities as the source (propositions, customers, markets, solutions, competitors); keywords "jobs-to-be-done", "functional job", "jtbd", "job landscape", "hire", "portfolio map", "capability overview", "pre-sales positioning".
- **anti_signals:** a single named prospect with deal-specific research; research syntheses with no propositions; a company self-description.
- **distinguish_from:** `customer-transformation` (prove one customer's observed value rather than explain the portfolio); `corporate-visions` (persuading a buyer who has not accepted the need — JTBD explains a portfolio to one who has); `company-credo` and `engagement-model` (the company rather than its solutions).
- **fallback_priority:** never a fallback.

### company-credo

- **question:** Why does this company exist, what does it believe that others do not, why should the reader trust that, and what can the reader expect?
- **best_for:** About-Us pages, company introductions, brand-identity narratives, the `about` scope of cogni-portfolio's customer narrative.
- **signals:** `content_type: company-credo` or `about-us`; a company description, positioning or mission, recurring MEANS themes; keywords "about us", "our mission", "why we exist", "what we believe", "our story", "company values", "our credo", "who we are", "why us".
- **anti_signals:** a delivery process; solutions mapped to buyer jobs; market research about someone else.
- **distinguish_from:** `engagement-model` (how the company works rather than why it exists); `jtbd-portfolio` (what it sells rather than what it believes); `corporate-visions` (a case for the reader's change rather than the company's identity); `customer-transformation` (a customer's observed outcome rather than the company's identity).
- **fallback_priority:** never a fallback.

### engagement-model

- **question:** How does this company work, what does an engagement look like step by step, what must the buyer bring, and what will they be able to point to at the end?
- **best_for:** How-We-Work pages, engagement sections of proposals, partner onboarding, the `approach` scope of cogni-portfolio's customer narrative.
- **signals:** `content_type: engagement-model` or `how-we-work`; delivery phases, cadences, artifacts, buyer inputs; keywords "how we work", "engagement model", "working with us", "our process", "delivery model", "partnership", "our approach", "principles", "ways of working".
- **anti_signals:** one solution's scope; why the company exists; pricing tiers or ROI models.
- **distinguish_from:** `company-credo` (why we exist rather than how we work); `jtbd-portfolio` (the solutions rather than the way of working); a capability page or proposal (where pricing and per-solution scope belong).
- **fallback_priority:** never a fallback.

### consulting-problem-solving

- **question:** What is happening, why is the status quo no longer sufficient, what is the best-supported answer, and what follows from it?
- **best_for:** diagnostic memos, problem-solving reports, consulting deliverables that derive an answer from evidence, executive briefings on an open question.
- **signals:** `content_type: consulting`, `problem-solving`, `diagnostic` or `recommendation-case`; a stated baseline disturbed by a named complication; one best-supported answer; evidence separated from interpretation; keywords "situation", "complication", "root cause", "hypothesis", "recommendation", "so what".
- **anti_signals:** named alternatives awaiting a choice; an investment case addressed to a buyer; a documented customer outcome.
- **distinguish_from:** `strategic-choice` (the options are already credible and the job is to choose, not to derive); `corporate-visions` (persuade to change and invest rather than diagnose — the arc a diagnostic request collapses onto when this one is absent); `category-creation` (reframe a market rather than answer a problem).
- **fallback_priority:** never a fallback; when the decision purpose is to understand a problem and derive the answer, it outranks `corporate-visions` in execution-fit ranking regardless of keyword density.

### strategic-choice

- **question:** Which option should we choose, and why is that choice superior given the evidence and the trade-offs?
- **best_for:** make/buy/partner decisions, market-entry choices, sequencing and prioritization, option papers for a board or steering committee.
- **signals:** `content_type: strategic-choice`, `options`, `decision` or `trade-off`; two or more named alternatives; stated or implied criteria; weighed trade-offs; keywords "options", "alternatives", "criteria", "trade-off", "make or buy", "recommend", "versus".
- **anti_signals:** no alternative named; one course argued as the only one; uncertainty about the future rather than about the option.
- **distinguish_from:** `consulting-problem-solving` (the answer is still to be derived; here it is to be chosen); `corporate-visions` (the reader has not accepted that a decision is due); `strategic-foresight` (divergent futures rather than a present choice).
- **fallback_priority:** never a fallback; when the decision purpose is to choose between named alternatives, it outranks `corporate-visions` in execution-fit ranking regardless of keyword density.

### customer-transformation

- **question:** What changed for the customer, what made it difficult, what intervention created the shift, and what verified outcome proves it mattered?
- **best_for:** case studies, reference stories, customer-success narratives, proof-of-value write-ups, measured before/after accounts.
- **signals:** `content_type: customer-story`, `case-study`, `customer-success`, `customer-transformation` or `reference-story`; one customer followed over time; a before state, an intervention and measured results; keywords "case study", "customer", "before", "after", "results", "implementation", "outcome".
- **anti_signals:** no single customer; projected rather than observed results; a pitch or proposal addressed to the customer.
- **distinguish_from:** `corporate-visions` (prospective persuasion — a case study on that arc sells instead of proving); `jtbd-portfolio` (explains a portfolio rather than one customer's journey); `company-credo` (the company's identity rather than a customer's outcome).
- **fallback_priority:** never a fallback; when the decision purpose is to prove observed value, it outranks `corporate-visions` in execution-fit ranking regardless of keyword density.

### category-creation

- **question:** Why does the old category no longer fit, what shift makes a new frame necessary, what is the new category, and what does leadership in it require?
- **best_for:** market-reframe narratives, category-design papers, thought leadership that names a new category, positioning for a company the existing frame does not fit.
- **signals:** `content_type: category-creation`, `category-design`, `market-reframe` or `new-category`; the source argues the existing category mis-describes the buyer's problem; an evidenced shift; a proposed new frame or name; keywords "category", "reframe", "the old model", "a new class of", "redefine".
- **anti_signals:** competitors and shares within an accepted category; structural forces with no new frame proposed; a diagnostic memo.
- **distinguish_from:** `competitive-intelligence` (position within a stable category rather than change the frame); `industry-transformation` (describe structural industry change rather than propose a new frame for what is bought); `corporate-visions` (persuade one buyer inside the existing frame); `consulting-problem-solving` (answer a stated problem rather than reframe a market).
- **fallback_priority:** never a fallback.

## Arc Detection Algorithm

SKILL.md Phase 2 fixes only the override order (explicit `--arc-id` → inherited `story_arc_id` → this algorithm); every detection step and every `detection_reason` string lives here, and downstream consumers read the string verbatim, so the vocabulary is closed:

| Decided by | `detection_reason` |
|---|---|
| `--arc-id` | `explicit --arc-id parameter` |
| Phase 1 inheritance | `inherited from source research/knowledge project: <PROJECT_ROOT>` |
| Step 2 structural signal | `structural: <file> detected (<variant>)` — the three literal strings in Step 2 |
| Step 3 `research_type` | `research_type="<value>"` (with the `(theme-less)` suffix where Step 3 shows it) |
| Step 3 `content_type` | `content_type="<value>"` |
| Step 6 keyword density | `keyword density analysis` |
| Step 7 fallback | `default candidate (no specific signals detected)` |

### Step 1: Explicit selection

If the caller provides `arc_id` directly, or Phase 1 inherited one from the source project's metadata, use it without detection.

### Step 2: Structural detection (trend-panorama / smarter-service)

Before content-type mapping, check for structural signals that uniquely identify TIPS reports. The presence of `tips-value-model.json` is the deciding signal between the theme-less and theme-aware variants.

```javascript
if (fileExists("tips-value-model.json") || fileExists(".metadata/tips-value-model.json")) {
  detected_arc = "smarter-service"
  detection_reason = "structural: tips-value-model.json detected (theme-aware TIPS report)"
}
else if (fileExists(".metadata/trend-scout-output.json") || fileExists("trend-scout-output.json")) {
  detected_arc = "trend-panorama"
  detection_reason = "structural: trend-scout-output.json detected (theme-less TIPS panorama)"
}
else if (fileExists("tips-trend-report.md")) {
  detected_arc = "trend-panorama"
  detection_reason = "structural: tips-trend-report.md detected (no value model — fallback)"
}
```

### Step 3: Content-type mapping

```javascript
const arcMap = {
  "trend": "trend-panorama", "trends": "trend-panorama", "tips": "trend-panorama",
  "smarter-service": "smarter-service", "investment-theme-report": "smarter-service",
  "theme": "theme-thesis", "investment-theme": "theme-thesis",
  "technology": "technology-futures",
  "competitive": "competitive-intelligence",
  "foresight": "strategic-foresight", "scenarios": "strategic-foresight",
  "industry": "industry-transformation",
  "jtbd": "jtbd-portfolio",
  "company-credo": "company-credo", "about-us": "company-credo",
  "engagement-model": "engagement-model", "how-we-work": "engagement-model",
  "consulting": "consulting-problem-solving", "problem-solving": "consulting-problem-solving", "diagnostic": "consulting-problem-solving", "recommendation-case": "consulting-problem-solving",
  "strategic-choice": "strategic-choice", "options": "strategic-choice", "decision": "strategic-choice", "trade-off": "strategic-choice",
  "customer-story": "customer-transformation", "case-study": "customer-transformation", "customer-success": "customer-transformation", "customer-transformation": "customer-transformation", "reference-story": "customer-transformation",
  "category-creation": "category-creation", "category-design": "category-creation", "market-reframe": "category-creation", "new-category": "category-creation",
  "market": "corporate-visions", "generic": "corporate-visions"
}

if (research_type === "smarter-service-themed") { detected_arc = "smarter-service"; detection_reason = 'research_type="smarter-service-themed"' }
else if (research_type === "smarter-service") { detected_arc = "trend-panorama"; detection_reason = 'research_type="smarter-service" (theme-less)' }

if (content_type in arcMap) { detected_arc = arcMap[content_type]; detection_reason = `content_type="${content_type}"` }
```

### Step 4: Execution-fit ranking

Take the arcs whose `signals` the source matches and rank them against the Phase 0 brief. For each candidate ask whether its governing question is the question the brief's decision purpose needs answered, whether its `best_for` fits the audience and perspective, and whether its `anti_signals` are present. The decision purpose outranks keyword density: when the purpose is "decide between make, buy and partner", an arc whose question is a choice ranks above one whose question is persuasion, whatever the keyword counts say. The `distinguish_from` field names the neighbours to weigh each candidate against, so a shortlist always carries the arcs that would make something materially different of the evidence.

### Step 5: Target-fit ranking

Apply this step only once evidence and execution fit have left two or more defensible candidates; with a single candidate standing there is no tie to break. It reads the already-resolved `--target` — no new parameter is introduced.

For `slides`, rank higher the candidate whose four-element chain reads as an answer-first management story and whose final element naturally carries the decision or the ask. For `document`, `web` and `infographic`, apply the same legibility principle to the format at hand, without the answer-first slide bias.

Two hard limits. Target fit **never overrides an explicit `--arc-id` or an arc inherited from the source project** — Step 1 has already decided those and no detection runs. And it **never rescues an arc whose evidence contract is unmet**: an arc the evidence cannot support does not become defensible because it would present well.

Record a short `target_fit` sentence for every shortlisted arc, so the trade-off survives into the run summary and not only into the prompt. This step emits no `detection_reason` of its own — it reorders candidates the earlier steps produced, and the deciding step's string stands.

### Step 6: Content analysis

When no content type matched, score keyword density per arc against its `signals`, discounted by `anti_signals`. Thresholds: `theme-thesis`, `technology-futures` and `category-creation` 15% (their terms are distinctive); `strategic-foresight` 10%; every other arc 12%. For the four decision arcs the execution-fit step is the decisive one — their keywords overlap with `corporate-visions`, and the decision purpose separates them.

### Step 7: Fallback

```javascript
if (!ranked_candidates.length) { ranked_candidates = ["corporate-visions"]; detection_reason = "default candidate (no specific signals detected)" }
```

## Arc Directory Structure

Each arc is one contract file, flat beside this registry:

```
references/
├── arc-registry.md            # this file
└── arc-{arc-id}.md            # v2 contract: Intent, Selection, Headings, Composition, Elements, Validation, See Also
```

A contract carries `contract: 2` in its frontmatter and the seven `##` sections in that order; `## Elements` holds exactly four `### N.` sections, each with Purpose, Evidence sought, Argument move, Techniques, Hard rules and Failure modes. The tree is flat on purpose: a directory nested under `references/` is a skill-spec finding, and the retired narrative skill's nested tree is what this copy flattened. These files are now the only copies; `cogni-workspace/tests/test-arc-contract-shape.sh` keeps every contract on this shape and fails when a nested layer grows back.

## Interactive Selection Format

The confirmation is a **shortlist, not a menu**. The user has no basis to ratify a single detected arc, and the full registry is a catalogue rather than a recommendation, so Phase 2 presents the 2-3 arcs that would produce materially different but defensible narratives from this evidence and this decision purpose. Every candidate carries the same five facts, and exactly one is marked Recommended:

```
Detected: {arc_display_name} ({detection_reason})

Which arc should this narrative follow?

1. {Recommended arc} — Recommended: {one sentence keyed to the decision purpose}
   Elements: {element1} → {element2} → {element3} → {element4}
   Governing question: {from the arc's block above}
   Evidence fit: {one reason this evidence suits this arc}
   Target fit: {how this arc reads in the requested --target}

2. {Alternative arc}
   Elements: {element1} → {element2} → {element3} → {element4}
   Governing question: {…}
   Evidence fit: {one reason — and what it would make of this evidence that the Recommended arc would not}
   Target fit: {how this arc reads in the requested --target, against the Recommended arc}

[3. {second alternative, only when defensible}]
```

Rules: 2-3 candidates, never padded to three when only two fit; when only one arc is defensible, say so and ask for confirmation of that one; the full arc list appears only when the user asks for it. Under `--interactive false` the top-ranked candidate is taken with its `detection_reason` recorded and no prompt is shown; the run summary retains the top two alternatives alongside it, each with its `target_fit` sentence.

## Extension Guidelines

### Adding an arc

1. Choose a unique `arc_id` (lowercase, hyphens, descriptive).
2. Create `arc-{arc-id}.md` on the v2 contract shape — copy a contract such as `arc-corporate-visions.md` and replace every section. This directory is the arc's only home, so the contract is authored here directly. Headings carry real characters per language, never ASCII substitutes.
3. Add the arc's block under Arc Blocks above with all six fields, a `distinguish_from` naming at least one existing arc, and the reciprocal mention in each neighbour's block; add a Quick Reference row; add its `content_type` mapping to Step 3 and its threshold to Step 6, and a structural signal to Step 2 if the arc has a unique file signature.
4. Add a column to the application matrix in `techniques-overview.md`.
5. Add a mapping row and an element block to `cogni-workspace/libraries/arc-taxonomy.md` — short names are the pre-colon segments of the contract's headings.
6. Update the arc list in `SKILL.md`'s frontmatter description, its Bundled arcs table and every prose surface that states an arc count.
7. Run `bash cogni-workspace/tests/test-text-to-narrative-brief.sh` — its identity and path cases enumerate the arc files at run time, so the new arc is checked with no test edit.

### Quality standards

- Exactly four elements, each with a distinct purpose; proportions sum to 100%.
- `## Elements` carries, per element, Purpose, Evidence sought (content-map keys, never a fixed directory layout), Argument move, Techniques (names linked to `techniques-overview.md`, never re-taught), Hard rules and Failure modes.
- `## Validation` carries only assertions specific to the arc; every universal gate lives in `validation.md`.
- German headings for all four elements with real umlauts.
