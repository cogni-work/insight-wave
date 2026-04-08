# Templates: Pitch Narrative

Output templates for the `pitch` use case. Transforms portfolio entities into arc-structured presentation narratives that cogni-narrative downstream tools (story-to-slides, story-to-web, story-to-big-picture, story-to-storyboard) can consume directly.

**Use case**: `pitch`
**Audience**: Executives, decision-makers, conference audiences, board members
**Voice**: Company presents to audience. Persuasive, evidence-backed, arc-driven. Not documentation — a presentation narrative designed to be spoken, not read at a desk.

**What makes this different from customer-narrative**: Customer narratives are documentation — structured for self-paced reading. Pitch narratives are arc-driven stories — structured for presentation delivery with a governing thought, rhetorical progression, and a call to action. The key technical difference: pitch output includes `arc_id` in frontmatter, making it directly consumable by the cogni-visual pipeline without an intermediate `/narrative` transformation.

**What makes this different from why-change (cogni-sales)**: Why-change does extensive web research per customer or segment and produces deal-specific sales pitches. Pitch narratives use only existing portfolio data — no web research, no deal context. They are reusable presentation foundations that can be refined later with why-change's research depth.

---

## Handling messaging mode

Pitches are spoken aloud to an audience, usually in a room where someone can immediately ask "so can I buy this today?". If the narrative features a `concept` capability in the "Why You" beats as if it were delivered, the answer has to be "no, not yet" and the whole pitch loses altitude. The messaging mode (derived in SKILL.md → Maturity-Aware Messaging) prevents that by steering each mode into the arc beat where it actually belongs.

| Mode | Role in the pitch |
|---|---|
| **standard** | Baseline. Populates Why You / Portfolio Map / Power Positions with confident IS/DOES/MEANS and full evidence. This is what the template already describes below. |
| **launch** | Same placement as standard, but the narrator may lead with recency as a "Why Now" reinforcer ("Just released for this market, and already in use by…"). Proof points allowed. |
| **preview** | Allowed in Power Positions / Portfolio Map, but the DOES layer must be qualified ("rolling out in beta to a set of design partners"). Evidence items are reframed as early pilot outcomes, not delivered results. Never present a preview capability as the main Power Position unless there is literally nothing stronger to lead with. |
| **announce** | **Does not appear in Why You / Portfolio Map / Power Positions.** Concept material instead feeds the **Why Now** beat (corporate-visions) or **Friction Map → Invitation** transition (jtbd-portfolio) as a future-outlook signal: "The window is also changing because we are building X, expected in [timeframe]." This keeps the roadmap visible without pretending it's deliverable. |
| **sunset** | Omit from the pitch. Sunset offerings are not what an audience is in the room to hear about. |

**Per-product and per-feature resolution.** Apply the stricter of product and feature modes at the sentence where a specific capability is described. A `growth` product with a `beta` feature should present that feature with "in beta" qualification even inside an otherwise standard Power Position.

**Invitation handling.** The Invitation / Why Pay beat must reference only live engagement options. Do not build an "entry point" around a solution whose parent product is in announce mode — for that case, signal a waitlist or design-partner program instead.

---

## Arc Selection

**Default**: `jtbd-portfolio` — portfolio pitches present capabilities to buyers who think in outcomes, not features. The JTBD arc's 1:1 job-to-solution mapping mirrors the portfolio's Feature x Market structure, and its verb-phrase jobs surface the buyer language that IS/DOES/MEANS already encodes.

**Override**: Accept `--arc-id` parameter for alternative arcs. When a non-default arc is selected, read the arc definition from `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md` to get element names, proportions, and quality gates. Adapt the evidence mapping accordingly.

**Supported arcs and their portfolio data mapping**:

| Arc | When to use | Primary portfolio data |
|-----|------------|----------------------|
| `jtbd-portfolio` (default) | Portfolio introduction, capability overview, pre-sales positioning | Customers → Job Landscape, Customers+Competitors → Friction Map, Propositions → Portfolio Map, Solutions → Invitation |
| `corporate-visions` | B2B sales, market pitch, executive briefing | Customers → Why Change, Markets → Why Now, Propositions → Why You, Solutions → Why Pay |
| `competitive-intelligence` | Competitive positioning presentation | Competitors → Landscape/Shifts, Propositions → Positioning, Markets → Implications |
| `industry-transformation` | Industry conference, thought leadership | Markets → Forces, Competitors → Friction, Features → Evolution, Products → Leadership |

Other arcs (`technology-futures`, `strategic-foresight`, `trend-panorama`, `theme-thesis`) are better served by cogni-trends or cogni-research input — portfolio data alone is usually insufficient for these arcs.

---

## YAML Frontmatter

The frontmatter must match cogni-narrative's output format exactly so downstream tools auto-discover it.

```yaml
---
title: "{Compelling market-specific title — assertion, not label}"
subtitle: "{Company Name} — {Market descriptor in buyer language}"
arc_id: jtbd-portfolio
arc_display_name: JTBD Portfolio
target_length: 1675
word_count: {actual word count after generation}
language: "{en|de from portfolio.json}"
date_created: "{ISO 8601 timestamp}"
source_file_count: {count of portfolio entity files referenced}
type: portfolio-pitch
market: "{market-slug}"
provider: "{company_name from portfolio.json}"
---
```

**Title rules**:
- Must be an assertion, not a topic label: "European Utilities Lose €2.3B Annually to Preventable Infrastructure Failures" not "Portfolio Overview for Energy Utilities"
- Draw the title from the most compelling data point in the portfolio — evidence arrays, market sizing gaps, or competitive differentiation
- Match the language from `portfolio.json`

**Critical fields for downstream compatibility**:
- `arc_id` — story-to-slides uses this to map to visual `arc_type` via `arc-taxonomy.md`
- `title` + `subtitle` — extracted for the title slide
- `language` — controls localized headers and IS/DOES/MEANS labels
- `word_count` + `target_length` — used for slide count estimation

---

## Market Scope: Per-Market Narrative

**Output**: `output/communicate/pitch/{market-slug}.md`

**Data sources**: `portfolio.json`, `markets/{market-slug}.json`, all `propositions/{feature}--{market-slug}.json`, their parent `features/*.json` and `products/*.json`, `solutions/{feature}--{market-slug}.json` (if available), `packages/{product}--{market-slug}.json` (if available), `competitors/{feature}--{market-slug}.json` (if available), `customers/{market-slug}.json` (if available)

### Evidence Mapping: Portfolio Entities → Corporate Visions Elements

Before writing, assemble evidence by mapping portfolio data to arc elements:

#### Hook (10% of target length)

**Source**: Scan all loaded entities for the single most surprising, quantified data point. Priority order:
1. Proposition evidence arrays — look for counterintuitive metrics or large impact numbers
2. Market TAM/SAM/SOM — significant market size or growth rate
3. Competitor gaps — a differentiation angle that challenges conventional thinking
4. Customer pain points — a pain point with quantified business impact

**Pattern**: `[Quantified surprise] + [Challenge to conventional wisdom]`

**Example**: "Organizations investing 40% more in cloud monitoring achieve 60% fewer actionable alerts — spending more on visibility while seeing less.<sup>[1]</sup>"

#### Why Change: The Unconsidered Need (27% of target length)

**Source**: `customers/{market}.json` pain_points + `markets/{market}.json` description + competitor landscape gaps

**Structure**: PSB (Problem-Solution-Benefit)
- **Problem (~33%)**: Frame the buyer's current assumption or status quo. Draw from customer pain points — these are real buyer challenges, not invented ones. Use contrast structure: "Most organizations in {market} think X. But the data reveals Y."
- **Solution (~33%)**: Reframe using evidence from propositions. The unconsidered need is the gap between what buyers think they need and what the portfolio reveals they actually need.
- **Benefit (~33%)**: Competitive advantage for early recognizers. Draw from competitor differentiation — what happens to organizations that see this gap first?

**Data mapping**:
- `customers/{market}.json` → `profiles[].pain_points` for the Problem
- `propositions/*.json` → DOES statements reveal the unconsidered outcome
- `competitors/*.json` → competitive gaps reveal why the status quo is risky

#### Why Now: The Closing Window (21% of target length)

**Source**: `markets/{market}.json` dynamics + forcing functions from market/customer data

**Structure**: Stack 2-3 forcing functions
- **Forcing function (~33%)**: External pressure with specific deadline. Look for regulatory drivers, technology shifts, or competitive dynamics in the market description.
- **Quantified urgency (~33%)**: Cost of delay. Derive from market sizing (SAM erosion over time) or proposition evidence (time-bound outcomes).
- **Window of opportunity (~33%)**: Early mover advantage. Contrast from competitor analysis — what's the gap between leaders and laggards?

**TIPS enrichment** (optional): If `trends-bridge` data exists for this market, check for trend entities with `urgency: "Act"` — these provide specific timelines and regulatory deadlines that strengthen forcing functions significantly. Read bridge entities from the project's trends-bridge integration if available.

**Data mapping**:
- `markets/{market}.json` → description, dynamics for regulatory/competitive drivers
- `propositions/*.json` → evidence arrays with time-bound claims
- `competitors/*.json` → competitive dynamics showing window closing
- TIPS trends (optional) → `urgency: "Act"` trends with specific timelines

#### Why You: Strategic Positioning (27% of target length)

**Source**: `propositions/{feature}--{market}.json` IS/DOES/MEANS + `competitors/{feature}--{market}.json`

**Structure**: 2-3 Power Positions using IS-DOES-MEANS

For each Power Position, select a high-tier proposition (use relevance tiers from `project-status.sh`):

- **IS** (1-2 sentences): What the capability is. Draw from the proposition's `is_statement`. Be specific and concrete — name the capability.
- **DOES** (2-3 sentences): What it does for the buyer. Draw from `does_statement`. Apply You-Phrasing throughout ("You reduce...", "Your team gains..."). Include quantified outcomes from the evidence array.
- **MEANS** (1-2 sentences): Why competitors struggle to replicate. Draw from `means_statement` and `competitors/` analysis. Explain the moat — time advantage, tacit knowledge, structural differentiation.

**Selection rules**:
- Choose propositions by relevance tier: high-tier first, then medium-tier
- Maximum 3 Power Positions — depth over breadth
- If a package exists for this product × market, frame capabilities as bundled rather than isolated
- Skip low-tier and skip-tier propositions

**Data mapping**:
- `propositions/*.json` → `is_statement`, `does_statement`, `means_statement` for Power Position structure
- `propositions/*.json` → `evidence[]` for quantified claims
- `competitors/*.json` → differentiation angles for MEANS layer
- `packages/*.json` → bundled framing when packages exist

#### Why Pay: The Business Case (15% of target length)

**Source**: `solutions/{feature}--{market}.json` pricing + `packages/{product}--{market}.json` tiers

**Structure**: Compound cost of inaction
- **Cost dimensions** (~60%): Stack 3-4 cost components of NOT acting. Derive from:
  - Customer pain points with business impact → operational cost
  - Market dynamics with competitive pressure → market position loss
  - Proposition evidence with time-bound outcomes → opportunity cost
  - Use 3-year horizon (standard executive planning cycle)
- **Investment framing** (~40%): Present solution/package pricing as investment, not cost. Prefer package tiers over individual solution pricing when packages exist. End with a simple ratio: "Action costs less than inaction by N×."

**Confidentiality**: Never include `cost_model` data (internal margins, effort days, role rates, CAC/LTV, unit economics). Only external pricing (package tiers, project tiers, subscription tiers, partnership terms).

**Data mapping**:
- `solutions/*.json` → `pricing` tiers for investment framing
- `packages/*.json` → bundled tier pricing (preferred over individual solutions)
- `customers/*.json` → pain point business impact for cost of inaction
- `propositions/*.json` → evidence with financial/operational metrics

### Evidence Mapping: Portfolio Entities → JTBD Portfolio Elements

The default evidence mapping follows a Jobs-to-be-Done structure. Read the arc definition from `cogni-narrative/skills/narrative/references/story-arc/jtbd-portfolio/arc-definition.md` for element names, proportions, and quality gates.

#### Hook / Context Setter (10% of target length)

**Source**: `markets/{market}.json` description + `portfolio.json` industry context

**Pattern**: One sharp industry observation that creates inevitability — the buyer's world is changing in a way that makes the jobs in this portfolio urgent.

**Example**: "European utilities manage 4,200 discrete operational processes. They buy solutions for 12 of them.<sup>[1]</sup>"

#### Job Landscape: Functional Jobs (24% of target length)

**Source**: `customers/{market}.json` pain_points + `propositions/{feature}--{market}.json` DOES statements

**Structure**: 3-4 functional jobs as verb phrases in buyer language
- Extract jobs from customer pain points (each pain point implies a job)
- Cross-reference with proposition DOES statements (each DOES reveals the underlying job)
- Phrase as verb phrases: "Reduce unplanned downtime below 2%", not "Predictive Maintenance"

**Constraints**:
- Jobs MUST be verb phrases (start with a verb, describe a measurable outcome)
- Jobs MUST NOT be product category names or internal feature labels
- 3-4 jobs total

**Data mapping**:
- `customers/{market}.json` → `profiles[].pain_points` reversed to job verb phrases
- `propositions/*.json` → `does_statement` abstracted to underlying buyer job
- `markets/{market}.json` → industry vocabulary for buyer-language validation

#### Friction Map: Obstacles and Cost of Inaction (21% of target length)

**Source**: `customers/{market}.json` pain_points (detail) + `competitors/{feature}--{market}.json` + `propositions/{feature}--{market}.json` evidence

**Structure**: Per-job friction with quantified cost of inaction
- For each job from Job Landscape: identify primary obstacle + cost of not solving it
- Use Forcing Functions where external pressures apply
- Apply Compound Impact to stack costs across all jobs

**Data mapping**:
- `customers/{market}.json` → pain point details for per-job obstacles
- `competitors/*.json` → current approach weaknesses showing why existing solutions fail
- `propositions/*.json` → `evidence[]` for cost quantification per job

#### Portfolio Map: Solutions by Job (27% of target length)

**Source**: `propositions/{feature}--{market}.json` IS/DOES/MEANS + `features/{feature}.json`

**Structure**: 1:1 job-to-solution using IS/DOES/MEANS per entry
- For each job from Job Landscape: present the matching solution
- IS from proposition `is_statement` + feature description
- DOES from `does_statement` with You-Phrasing and quantified outcomes
- MEANS from `means_statement` + competitive differentiation

**Constraints**:
- STRICT 1:1 mapping: each job gets exactly one solution
- If a proposition has no matching job, flag as orphaned
- NO feature lists — IS/DOES/MEANS only per solution
- Count(jobs) == Count(solutions mapped)

**Data mapping**:
- `propositions/*.json` → `is_statement`, `does_statement`, `means_statement` for IS/DOES/MEANS
- `features/*.json` → `description` for the IS layer
- `propositions/*.json` → `evidence[]` for DOES quantification
- `competitors/*.json` → differentiation for MEANS moat

#### Invitation: Next Step (18% of target length)

**Source**: `solutions/{feature}--{market}.json` entry tiers + `packages/{product}--{market}.json` starter tier

**Structure**: One low-commitment entry point + cogni-sales handoff
- Identify the lowest-commitment entry option (PoV, pilot, starter, assessment)
- Present as a single next step with investment and deliverable
- Explicitly signal cogni-sales `/why-change` for deal-specific tailoring

**Constraints**:
- ONE entry point only — not a pricing menu
- Must include explicit cogni-sales handoff: reference `/why-change`
- Frame as invitation, not hard sell

**Data mapping**:
- `solutions/*.json` → entry-level implementation phase or pricing tier
- `packages/*.json` → starter/entry-level bundle tier
- Portfolio context → company engagement model

**Localized headers** (jtbd-portfolio):
- EN: `Job Landscape: Functional Jobs` / `Friction Map: Obstacles and Cost of Inaction` / `Portfolio Map: Solutions by Job` / `Invitation: Next Step`
- DE: `Job-Landschaft: Funktionale Aufgaben` / `Reibungskarte: Hindernisse und Handlungsdruck` / `Portfolio-Zuordnung: Lösungen je Aufgabe` / `Einladung: Nächster Schritt`

---

## Citations

Citations link to **external source URLs** so readers can verify claims. Never link to internal JSON entity file paths (`propositions/x.json`, `markets/y.json`) — these are meaningless to readers and break outside the project directory.

**Inline format**: `<sup>[N]</sup>` in the body text — the number references the Sources footer.

**Source priority** (use the first available for each cited claim):
1. `evidence[].source_url` from the proposition — the original external source
2. `evidence[].source_url` from competitor or customer entities
3. No citation — use descriptive inline text instead (e.g., "~EUR 25B segment revenue (internal estimate)")

**Claims without external sources**: Market sizing derived from LLM estimates, internal calculations, or portfolio entity fields (TAM/SAM/SOM `source` strings) get no superscript citation. State the figure with a parenthetical qualifier like "(internal estimate)" or "(bottom-up calculation)".

**References footer**: End the document with a numbered sources section:

```markdown
---
## Sources

[1] [Source Title](https://source-url) — brief context of what the source establishes
[2] [Source Title](https://source-url) — brief context
```

**Density target**: 15-25 total citations across the narrative:
- Why Change (data-heavy): 5-8 citations
- Why Now (forcing functions): 4-6 citations
- Why You (strategic): 4-6 citations
- Why Pay (cost calculations): 3-5 citations

Only count citations that have external URLs. Internal estimates don't count toward the density target.

**Claim verification**: If `cogni-claims/claims.json` exists, cross-reference evidence statements. Mark unverified or deviated claims with `[unverified]`. Include a brief "Data Quality" note in the frontmatter when unverified claims are present.

---

## Portfolio-Wide Scope: Overview Narrative

**Output**: `output/communicate/pitch/portfolio-overview.md`

**Audience**: Investors, board members, conference keynotes — contexts where the full portfolio is the subject, not a single market.

**Data sources**: `portfolio.json`, all `products/*.json`, all `features/*.json`, all `markets/*.json` (for breadth), top propositions across markets (high-tier only), packages (for commercial maturity signal)

**Adaptation**: The same default arc applies, but the evidence mapping shifts:

| Element | Market scope | Overview scope |
|---------|-------------|----------------|
| **Job Landscape** | Single market's buyer jobs | Cross-market jobs — the functional outcomes buyers share across segments |
| **Friction Map** | Market-specific obstacles and cost of inaction | Systemic friction patterns affecting all target markets |
| **Portfolio Map** | 1:1 job-to-solution mapping for one market | 2-3 products with cross-market job coverage |
| **Invitation** | Market-specific entry point | Portfolio-level engagement path — total addressable value |

**Title**: Portfolio-wide, not market-specific. "How {Company} Addresses the {Cross-Market Theme}" or "{Company}: {Portfolio-Level Value Statement}"

---

## Tone and Language

**Voice**: Persuasive but credible. This is a presentation narrative — it should sound like something a confident executive would present, not something a copywriter would publish on a website. Avoid:
- Marketing superlatives ("revolutionary", "best-in-class", "unparalleled")
- Academic hedging ("it appears that", "research suggests")
- Internal jargon (slugs, entity types, taxonomy dimensions, relevance tiers)

**Language**: Read `portfolio.json` `language` field. Generate all content in that language. If `de`, use proper Unicode (ä, ö, ü, ß) and localized arc element headers from the arc definition's German elements.

**Localized headers** (corporate-visions):
- EN: `Why Change: The Unconsidered Need` / `Why Now: The Closing Window` / `Why You: Strategic Positioning` / `Why Pay: The Business Case`
- DE: `Warum Veränderung: Der unberücksichtigte Bedarf` / `Warum jetzt: Das sich schließende Zeitfenster` / `Warum Sie: Strategische Positionierung` / `Geschäftliche Auswirkungen: Der Business Case`

---

## Relevance Tiers

Run `$CLAUDE_PLUGIN_ROOT/scripts/project-status.sh <project-dir>` to get the `relevance_matrix`. Use tiers to prioritize which propositions appear in the narrative:

- **High-tier**: Primary Power Positions in Why You. Featured evidence throughout.
- **Medium-tier**: Supporting evidence, mentioned but not featured.
- **Low/Skip/Excluded**: Omit from the narrative entirely. A pitch is about focus, not completeness.

When generating for `all` markets: order by market priority (beachhead → expansion → aspirational). Skip aspirational markets unless the portfolio has fewer than 3 markets total.

---

## Handling Incomplete Data

Portfolio data may be incomplete. Handle gaps gracefully:

| Missing entity | Impact | Action |
|---------------|--------|--------|
| No customer profiles | Why Change is weaker | Derive pain points from market description and proposition DOES statements. Flag: "Customer profiles would strengthen this section." |
| No competitor data | Why You lacks moat | Focus IS/DOES/MEANS on capability strength without competitive contrast. Omit MEANS moat claims. |
| No solutions/packages | Why Pay is thinner | Focus on cost of inaction only. Omit investment framing. Note: "Solution pricing would complete the business case." |
| No evidence arrays | Citations are sparse | Use market sizing and customer pain points as primary evidence. Narrative will be less data-dense. |
| No TIPS bridge | Why Now has no trends | Use market dynamics only. Forcing functions will be less specific. |

---

## Downstream Pipeline

After generating a pitch narrative, suggest:

1. **Score quality**: `/narrative-review` — scores against the arc's quality gates (structural compliance, evidence density, technique application)
2. **Polish prose**: `/copywrite` — applies executive readability standards while preserving arc structure
3. **Visualize**:
   - `/story-to-slides` → PowerPoint presentation via PPTX skill
   - `/story-to-web` → scrollable landing page via Pencil MCP
   - `/story-to-big-picture` → illustrated visual journey map via Excalidraw
   - `/story-to-storyboard` → multi-poster print storyboard via Pencil MCP
4. **Deepen** (if needed): `/why-change` — adds web research, customer-specific context, and TIPS enrichment for a deal-ready version
