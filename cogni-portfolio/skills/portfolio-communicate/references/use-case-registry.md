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
