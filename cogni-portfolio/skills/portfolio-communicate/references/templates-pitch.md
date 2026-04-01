# Templates: Pitch Narrative

Output templates for the `pitch` use case. Transforms portfolio entities into arc-structured presentation narratives that cogni-narrative downstream tools (story-to-slides, story-to-web, story-to-big-picture, story-to-storyboard) can consume directly.

**Use case**: `pitch`
**Audience**: Executives, decision-makers, conference audiences, board members
**Voice**: Company presents to audience. Persuasive, evidence-backed, arc-driven. Not documentation — a presentation narrative designed to be spoken, not read at a desk.

**What makes this different from customer-narrative**: Customer narratives are documentation — structured for self-paced reading. Pitch narratives are arc-driven stories — structured for presentation delivery with a governing thought, rhetorical progression, and a call to action. The key technical difference: pitch output includes `arc_id` in frontmatter, making it directly consumable by the cogni-visual pipeline without an intermediate `/narrative` transformation.

**What makes this different from why-change (cogni-sales)**: Why-change does extensive web research per customer or segment and produces deal-specific sales pitches. Pitch narratives use only existing portfolio data — no web research, no deal context. They are reusable presentation foundations that can be refined later with why-change's research depth.

---

## Arc Selection

**Default**: `corporate-visions` — the portfolio's IS/DOES/MEANS framework maps directly to the Why You element's Power Positions, making this the most natural fit for B2B portfolio presentations.

**Override**: Accept `--arc-id` parameter for alternative arcs. When a non-default arc is selected, read the arc definition from `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md` to get element names, proportions, and quality gates. Adapt the evidence mapping accordingly.

**Supported arcs and their portfolio data mapping**:

| Arc | When to use | Primary portfolio data |
|-----|------------|----------------------|
| `corporate-visions` (default) | B2B sales, market pitch, executive briefing | Customers → Why Change, Markets → Why Now, Propositions → Why You, Solutions → Why Pay |
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
arc_id: corporate-visions
arc_display_name: Corporate Visions
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

**Example**: "Organizations investing 40% more in cloud monitoring achieve 60% fewer actionable alerts — spending more on visibility while seeing less.<sup>[1](propositions/cloud-monitoring--mid-market-saas-dach.json)</sup>"

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

---

## Citations

**Format**: `<sup>[N](entity-file-path)</sup>` — sequential numbering from 1

**Source**: Citations point to portfolio entity files (the internal source of truth), not external URLs. This keeps the narrative self-contained and verifiable against the portfolio.

**Examples**:
- `<sup>[1](propositions/cloud-monitoring--mid-market-saas-dach.json)</sup>` — citing a proposition's evidence
- `<sup>[2](customers/mid-market-saas-dach.json)</sup>` — citing a customer pain point
- `<sup>[3](markets/mid-market-saas-dach.json)</sup>` — citing market sizing data

**Density target**: 15-25 total citations across the narrative:
- Why Change (data-heavy): 5-8 citations
- Why Now (forcing functions): 4-6 citations
- Why You (strategic): 4-6 citations
- Why Pay (cost calculations): 3-5 citations

**Claim verification**: If `cogni-claims/claims.json` exists, cross-reference evidence statements. Mark unverified or deviated claims with `[unverified]`. Include a brief "Data Quality" note in the frontmatter when unverified claims are present.

---

## Portfolio-Wide Scope: Overview Narrative

**Output**: `output/communicate/pitch/portfolio-overview.md`

**Audience**: Investors, board members, conference keynotes — contexts where the full portfolio is the subject, not a single market.

**Data sources**: `portfolio.json`, all `products/*.json`, all `features/*.json`, all `markets/*.json` (for breadth), top propositions across markets (high-tier only), packages (for commercial maturity signal)

**Adaptation**: The same corporate-visions arc applies, but the evidence mapping shifts:

| Element | Market scope | Overview scope |
|---------|-------------|----------------|
| **Why Change** | Single market's buyer pain points | Cross-market pattern — the industry-wide unconsidered need |
| **Why Now** | Market-specific forcing functions | Macro forces affecting all target markets |
| **Why You** | 2-3 propositions for one market | 2-3 products with cross-market differentiation |
| **Why Pay** | Market-specific pricing/ROI | Portfolio-level investment thesis — total addressable value |

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
