# Use Case Registry

Available communication use cases for portfolio content. Each use case defines a distinct audience, voice, and output structure. The skill reads this registry to route the user's request to the right template and review configuration.

---

## Built-In Use Cases

### `customer-narrative`

| Field | Value |
|-------|-------|
| **Name** | Customer Narrative |
| **Audience** | Buyers, executives, decision-makers evaluating the company's offerings |
| **Voice** | Company speaks to buyer ("we"/"you"). Professional but conversational — not a brochure, not a contract |
| **Trigger phrases** | "customer-facing", "sales materials", "present to buyers", "what do we offer", "capability overview", "service catalog", "external portfolio", "portfolio for customers", "customer documentation", "make this customer-ready" |
| **Template** | `references/templates-customer-narrative.md` |
| **Review** | Full 3-perspective: Target Buyer, Marketing Director, Sales Director |
| **Output path** | `output/communicate/customer-narrative/` |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `overview` | `portfolio-overview.md` | General entry point — all products, key capabilities, no market tailoring |
| `market` | `market/{market-slug}.md` | Filtered for a specific target market's buyers |
| `customer` | `customer/{market-slug}--{persona}.md` | Personalized for a specific buyer persona |
| `all` | All of the above | Overview + all markets + all customer personas |

**Downstream pipeline:** `/copywrite` -> `/narrative` -> `/story-to-web`, `/story-to-slides`, `/story-to-big-picture`

---

### `repo-documentation`

| Field | Value |
|-------|-------|
| **Name** | Repository Documentation |
| **Audience** | Developers, technical evaluators, open-source community, potential contributors |
| **Voice** | Third-person project voice ("insight-wave provides...", "the platform enables..."). Technical but accessible — no marketing superlatives, no buyer-pressure language. Code examples welcome. |
| **Trigger phrases** | "enrich README", "repo documentation", "developer documentation", "update README with portfolio", "document the project", "open-source documentation", "GitHub README", "project overview for developers", "technical documentation from portfolio" |
| **Template** | `references/templates-repo-documentation.md` |
| **Review** | 3-perspective: Developer Evaluator, Open Source Maintainer, Technical Writer |
| **Output path** | `output/communicate/repo-docs/` |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `readme-enrichment` | `readme-sections.md` | Sections ready to merge into an existing README — product descriptions, use cases, capabilities |
| `plugin-overview` | `plugin-overview.md` | Per-plugin summary with capabilities, key skills, integration points |
| `use-case-gallery` | `use-case-gallery.md` | Concrete scenarios showing how the portfolio solves real problems |
| `all` | All of the above | All three scopes |

**Downstream pipeline:** Merge into target README manually or via `/copywrite` for prose polish. No narrative arc transformation (developer docs don't need story arcs).

---

### `pitch`

| Field | Value |
|-------|-------|
| **Name** | Pitch Narrative |
| **Audience** | Executives, decision-makers, conference audiences, board members |
| **Voice** | Company presents to audience. Persuasive, evidence-backed, arc-driven. Not documentation — a presentation narrative designed to be spoken, not read at a desk. |
| **Trigger phrases** | "pitch", "portfolio pitch", "presentation narrative", "pitch deck from portfolio", "slides from portfolio", "present portfolio", "portfolio story", "pitch for [market]", "create a pitch", "portfolio presentation" |
| **Template** | `references/templates-pitch.md` |
| **Review** | 3-perspective: Target Buyer, Sales Director, Narrative Coach |
| **Output path** | `output/communicate/pitch/` |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `market` | `pitch/{market-slug}.md` | Arc-structured narrative for a specific market's buyers |
| `overview` | `pitch/portfolio-overview.md` | Portfolio-wide narrative for investors, board, or keynotes |
| `all` | All of the above | Overview + one narrative per market (ordered by priority) |

**Key differentiator**: Pitch output includes `arc_id` in frontmatter — this makes it directly consumable by story-to-slides, story-to-web, story-to-big-picture, and story-to-storyboard without an intermediate `/narrative` step. Default arc: `corporate-visions`.

**Downstream pipeline:** `/narrative-review` → `/copywrite` → `/story-to-slides`, `/story-to-web`, `/story-to-big-picture`, `/story-to-storyboard`

---

### `proposal`

| Field | Value |
|-------|-------|
| **Name** | Sales Proposal |
| **Audience** | Sales teams, prospect-specific customization, buyer evaluation |
| **Voice** | Company speaks to buyer ("we"/"you"). Professional and direct — lead with value, not preamble. Avoid marketing superlatives. |
| **Trigger phrases** | "proposal", "create a proposal", "sales proposal", "proposal for [feature] in [market]", "generate proposal", "proposition proposal" |
| **Template** | `references/templates-proposal.md` |
| **Review** | 3-perspective: Target Buyer, Sales Director, Pre-Sales Consultant |
| **Output path** | `output/communicate/proposal/` |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `single` | `proposal/{feature}--{market}.md` | One proposal for a specific proposition |
| `market` | `proposal/{feature}--{market}.md` (×N) | All proposals for propositions in a specific market |
| `all` | `proposal/{feature}--{market}.md` (×N) | All proposals, ordered by relevance tier |

**Downstream pipeline:** Share with sales for customization, or `/copywrite` for prose polish

---

### `market-brief`

| Field | Value |
|-------|-------|
| **Name** | Marketing Brief |
| **Audience** | Marketing teams, campaign planning, sales enablement |
| **Voice** | Internal-facing but polished. Data-rich, structured for marketing team consumption. |
| **Trigger phrases** | "marketing brief", "market brief", "brief for [market]", "campaign brief", "marketing content package", "messaging brief" |
| **Template** | `references/templates-market-brief.md` |
| **Review** | 3-perspective: Marketing Director, Campaign Manager, Sales Director |
| **Output path** | `output/communicate/market-brief/` |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `single` | `market-brief/{market-slug}.md` | Brief for a specific target market |
| `all` | `market-brief/{market-slug}.md` (×N) | Briefs for all markets, ordered by priority |

**Downstream pipeline:** Campaign planning, `/copywrite` for polish, feed into cogni-marketing

---

### `workbook`

| Field | Value |
|-------|-------|
| **Name** | Portfolio Workbook (XLSX) |
| **Audience** | Leadership review, portfolio analysis, stakeholder sharing |
| **Voice** | Data-oriented. No narrative — structured spreadsheet with all portfolio entities. |
| **Trigger phrases** | "export to Excel", "spreadsheet", "XLSX", "workbook", "portfolio workbook", "send to Excel", "download portfolio", "portfolio data export" |
| **Template** | None — delegates to `document-skills:xlsx` |
| **Review** | None (data export) |
| **Output path** | `output/communicate/workbook/` |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `full` | `workbook/portfolio.xlsx` | All sheets: Products, Features, Markets, Proposition Matrix, Packages, Solutions, Cost Analysis (internal), Competitors, Customers, Summary |
| `matrix` | `workbook/proposition-matrix.xlsx` | Proposition Matrix sheet only (Feature × Market with IS/DOES/MEANS) |

**Sheets** (for `full` scope):
1. **Products**: name, positioning, pricing tier, maturity
2. **Features**: name, purpose, description, category, parent product — ordered by sort_order within product
3. **Markets**: name, segmentation, TAM/SAM/SOM — ordered by sort_order
4. **Proposition Matrix**: Feature × Market grid with IS/DOES/MEANS, grouped by product. Includes "Tier" column (high/medium/low/skip/N/A). Excluded pairs show "N/A — {reason}".
5. **Packages**: product, market, tier names, included solutions, pricing, bundle savings
6. **Solutions**: grouped by solution type with phases/tiers/pricing
7. **Cost Analysis** (internal/confidential): effort, margins, unit economics. Flag as CONFIDENTIAL.
8. **Competitors**: competitive analysis per proposition
9. **Customers**: buyer profiles per market
10. **Summary**: portfolio statistics, completion status, margin health (if cost models exist)

**Creation**: Use `document-skills:xlsx` skill. Fallback to CSV files in `output/communicate/workbook/csv/` if xlsx skill unavailable.

**Downstream pipeline:** Share with leadership for portfolio review

---

## Custom Use Cases

Users can define reusable custom use cases by saving them to `communicate-use-cases.json` in the project root. The skill checks this file alongside the built-in registry.

### Schema

```json
{
  "use_cases": [
    {
      "id": "investor-summary",
      "name": "Investor Summary",
      "audience": "VCs, angel investors, board members evaluating the business",
      "voice": "Founder speaks to investor. Confident, data-backed, forward-looking. Emphasize traction, market size, and differentiation.",
      "scopes": [
        {
          "id": "pitch-overview",
          "output_file": "pitch-overview.md",
          "description": "One-pager covering problem, solution, market, traction, team"
        }
      ],
      "review": {
        "enabled": true,
        "perspectives": [
          { "name": "VC Partner", "focus": "Market opportunity, defensibility, team credibility" },
          { "name": "Financial Analyst", "focus": "Unit economics, growth metrics, capital efficiency" },
          { "name": "Portfolio Founder", "focus": "Authenticity, competitive positioning, founder-market fit" }
        ]
      },
      "output_path": "output/communicate/investor/",
      "downstream": "Polish with /copywrite, then /story-to-slides for pitch deck"
    }
  ]
}
```

When a custom use case is selected, the skill uses the `voice` and `scopes` to guide generation. If `review.enabled` is true, the assessor derives its perspective criteria from the `perspectives` array. The skill generates section structure based on the scope description and audience — no separate template file is needed for custom use cases.

### Creating Custom Use Cases

Custom use cases are created through the ad-hoc flow (the "something else" path in the skill). After generating content with ad-hoc parameters, the skill offers to persist those parameters as a reusable use case. The user can also manually edit `communicate-use-cases.json`.

---

## Ad-Hoc Use Cases

When the user's purpose doesn't match any built-in or custom use case, the skill guides them through defining parameters on the fly:

1. **Audience** — Who will read this? (developers, investors, partners, internal team, regulators, ...)
2. **Voice/tone** — How should it sound? (technical, conversational, formal, persuasive, founder-voice, ...)
3. **Sections** — What structure makes sense? (skill suggests based on audience, user adjusts)
4. **Review** — Should we assess the output? If yes, from whose perspective? (skill suggests based on audience)

Ad-hoc parameters are used for a single generation run. After generation, the skill offers: "Would you like to save this as a reusable use case for future runs?" If yes, it writes to `communicate-use-cases.json`.

---

## Selecting a Use Case

The skill infers the use case from the user's request using trigger phrases and context. Inference priority:

1. **Explicit match** — user mentions a use case by name or a clear trigger phrase
2. **Context match** — the request context implies a use case (e.g., mentioning "README" implies `repo-documentation`)
3. **Custom match** — check `communicate-use-cases.json` for custom use cases whose audience/name matches
4. **Ambiguous** — present the use case menu and let the user choose, including the "something else" option

When presenting the menu, show each use case's name and a one-line description of its audience. Include custom use cases from the project file if they exist.
