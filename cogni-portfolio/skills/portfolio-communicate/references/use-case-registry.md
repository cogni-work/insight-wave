# Use Case Registry

Available communication use cases for portfolio content. Each use case defines a distinct audience, voice, and output structure. The skill reads this registry to route the user's request to the right template and review configuration.

---

## Built-In Use Cases

### `customer-narrative`

| Field | Value |
|-------|-------|
| **Name** | Customer Narrative (Portfolio-Driven Website) |
| **Audience** | Buyers, executives, decision-makers navigating a portfolio-driven website |
| **Voice** | Company speaks to buyer ("we"/"you"). Professional but conversational — each page feels authored, not generated. |
| **Trigger phrases** | "customer-facing", "sales materials", "present to buyers", "what do we offer", "capability overview", "service catalog", "external portfolio", "portfolio for customers", "customer documentation", "make this customer-ready", "portfolio website", "website content", "landing page", "home page", "about us page", "how we work page", "capability page", "for {persona} page", "web content from portfolio" |
| **Template** | `references/templates-customer-narrative.md` |
| **Review** | Full 3-perspective: Target Buyer, Marketing Director, Sales Director |
| **Output path** | `output/communicate/customer-narrative/` |
| **Maturity handling** | All modes allowed. `announce`/`preview` routed to an "On the roadmap" subsection in `home.md` **only** (other files do not carry roadmap content — they link to home). `sunset` omitted from `home.md` and `capabilities/*.md` by default. Promise/Invitation commitments must not depend on `announce`-mode products. See SKILL.md → Maturity-Aware Messaging. |

**Scopes:**

Each scope produces a main component of a portfolio-driven website, driven by a specific `text-to-narrative` arc contract. Each output file includes `arc_id` in frontmatter, the value to pass as `--arc-id` so `text-to-narrative` builds the Claude Design brief under the same arc.

| Scope | Output file | Component | Arc |
|-------|------------|-----------|-----|
| `home` | `home.md` | Home page — what we do, for whom, why it matters | `jtbd-portfolio` |
| `about` | `about.md` | About Us — who we are, why we exist, what we believe | `company-credo` |
| `capability` | `capabilities/{feature-slug}.md` | One page per customer-facing feature | `corporate-visions` |
| `persona` | `for/{market-slug}--{persona}.md` | Persona landing page ("For CROs", "For Plant Managers") | `jtbd-portfolio` |
| `approach` | `approach.md` | How We Work / Our Approach | `engagement-model` |
| `all` | All of the above | Full website regeneration from current portfolio state | — |

**Deduplication discipline:**
- The Roadmap subsection appears in `home.md` only; other files link to it.
- "Why us" differentiators appear in `about.md` only; other files refer to them.
- Persona pages ROUTE to capability pages; they do not restate the capability story.
- Capability pages are the single source of truth for a feature's Why Change → Why Pay.

**Deprecated scopes (v1):** The `overview` / `market` / `customer` scopes from the previous version are replaced by `home` / (dropped) / `persona`. The old `market/*.md` files are no longer generated — their content was redundant with persona pages and had no role in a standard website IA. Existing market files from past runs are left on disk and not automatically migrated; regenerating with scope=`all` simply stops producing them.

**Downstream pipeline:** Each output file carries `arc_id` in frontmatter; pass it as `--arc-id` so `text-to-narrative` builds the Claude Design brief under the same arc — `--target web` for pages, `--target slides` for deck versions. Optionally run `/copywrite` on any file first for extra prose polish.

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
| **Maturity handling** | All modes allowed. Rendered as `Status: new/beta/planned/deprecated` badges rather than marketing labels. `announce`/`deprecated` items skip setup and code examples. |

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
| **Maturity handling** | `standard`/`launch`/`preview` populate Power Positions (preview qualified as beta). `announce` routed to the Why Now / future-outlook beat, never Why You. `sunset` omitted. |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `market` | `pitch/{market-slug}.md` | Arc-structured narrative for a specific market's buyers |
| `overview` | `pitch/portfolio-overview.md` | Portfolio-wide narrative for investors, board, or keynotes |
| `all` | All of the above | Overview + one narrative per market (ordered by priority) |

**Key differentiator**: Pitch output includes `arc_id` in frontmatter — so `text-to-narrative` builds a Claude Design brief (slides, document, infographic or web) from it directly. Default arc: `jtbd-portfolio`.

**Downstream pipeline:** `/review-doc` → `/copywrite` → `/text-to-narrative` (slides, document, infographic or web brief for Claude Design)

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
| **Maturity handling** | **Blocks `announce` and `sunset` modes** — a proposal commits to delivering something, so concept-stage and declining products cannot be proposed. `preview` mode requires an Early Access banner, introductory-pricing labels, and a softer CTA. `standard`/`launch` unrestricted. |

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
| **Maturity handling** | All modes included but split into distinct tables: "Available now" (standard/launch/preview) and "On the roadmap" (announce). `sunset` goes into a short "Legacy — maintenance only" subsection so marketing can stop active campaigns on it. |

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
| **Maturity handling** | The Products sheet already carries `maturity`. Add a derived `messaging_mode` column next to it for auditability. All products included regardless of mode — this is a full data export, not a curated view. |

**Scopes:**

| Scope | Output file | Description |
|-------|------------|-------------|
| `full` | `workbook/portfolio.xlsx` | All sheets: Products, Features, Markets, Proposition Matrix, Packages, Solutions, Cost Analysis (internal), Competitors, Customers, Summary |
| `matrix` | `workbook/proposition-matrix.xlsx` | Proposition Matrix sheet only (Feature × Market with IS/DOES/MEANS) |

**Sheets** (for `full` scope):
1. **Products**: name, positioning, pricing tier, maturity, messaging_mode (derived from maturity + feature readiness — see SKILL.md → Maturity-Aware Messaging)
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
      "downstream": "Polish with /copywrite, then /text-to-narrative --target slides for the pitch deck brief"
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
