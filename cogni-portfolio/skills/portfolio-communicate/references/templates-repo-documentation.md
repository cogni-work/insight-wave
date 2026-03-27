# Templates: Repository Documentation

Output templates for the `repo-documentation` use case. Transforms portfolio entities into developer-facing content suitable for README enrichment, plugin documentation, and use-case galleries.

**Use case**: `repo-documentation`
**Audience**: Developers, technical evaluators, open-source community, potential contributors
**Voice**: Third-person project voice. Technical but accessible. No marketing superlatives.

---

## YAML Frontmatter

```yaml
---
title: "{Descriptive title}"
type: portfolio-communicate
use_case: repo-documentation
scope: readme-enrichment | plugin-overview | use-case-gallery
language: "{en|de}"
date_created: "{ISO 8601}"
source_entities:
  products: {count}
  features: {count}
  propositions: {count}
---
```

---

## Scope 1: README Enrichment

**Output**: `output/communicate/repo-docs/readme-sections.md`

**Data sources**: portfolio.json, products/*.json, features/*.json, propositions/*.json (for value framing), markets/*.json (for audience descriptions)

Produces self-contained markdown sections that can be merged into an existing README or used as a standalone project overview. Each section is separated by a horizontal rule and includes a comment marker (`<!-- section: {name} -->`) so users can identify which sections to copy.

```markdown
<!-- section: project-overview -->
# {Project/Company Name}

{2-3 sentences explaining what this project does and who it helps. Derive from
portfolio.json company_description and positioning, but rewrite for a developer
audience. Focus on the problem being solved and the approach taken.

Example: Instead of "We help consulting firms grow revenue" write
"insight-wave is an open-source plugin ecosystem for Claude Code that helps
consulting firms, technology partners, and AI-ambitious SMEs structure their
go-to-market strategy using AI-assisted workflows."}

<!-- section: products -->
## Products

{For each product, a subsection. These are the top-level offerings.
Describe what each product is and what it contains — think of this as
the "architecture overview" a developer needs to understand the project structure.}

### {Product Name}

{Product description rewritten for developers. What does this product contain?
How is it organized? What problem space does it address?

Include the product's key capabilities (features) as a structured list.
For each feature, explain what it does technically — not what value it delivers
to a buyer. Developers want to understand functionality, not ROI.}

**Capabilities:**

- **{Feature name}** — {1-2 sentence technical description derived from IS statement.
  Keep the technical substance, remove the marketing framing.}

{If the product has many features (>8), group them by functional area
rather than listing them flat.}

<!-- section: use-cases -->
## Use Cases

{Derive from markets and customer profiles. Each target market represents
a use-case category. Describe who uses this project and for what purpose.

Frame as concrete scenarios, not market segments:
- Instead of "Mid-sized consulting firms in DACH" write
  "A 200-person consulting firm wants to systematize their go-to-market
  messaging across 4 practice areas and 3 target markets."

Include 2-4 use cases, ordered by market priority (beachhead first).
Each use case should be 3-5 sentences covering the situation, what they
use from the project, and what outcome they achieve.}

### {Use Case Title}

{Scenario description. Who is doing what, and why do they reach for this project?
What specific products/features do they use? What does the result look like?}

<!-- section: how-it-works -->
## How It Works

{High-level architecture or workflow description. Draw from the product
structure and feature relationships to explain how the pieces fit together.

If the project has a clear workflow (e.g., setup -> define features ->
generate propositions -> synthesize -> export), describe it as numbered steps.

If the project is more modular (pick the plugins you need), describe
the module structure and how modules interact.

Include a simple flow or dependency description — no need for diagram syntax,
just a clear textual explanation of how data flows through the system.}

<!-- section: getting-started -->
## Getting Started

{Quick-start instructions. Derive from the product structure and any
setup skills or initialization workflows that exist in the portfolio.

Be concrete: mention actual skill names, command patterns, or entry points.
If the project has a setup skill, reference it by name.

Keep this to 5-10 lines. Link to more detailed documentation if available.}
```

**Content guidelines for README enrichment:**
- Target length: 600-1,200 words (concise enough for a README, complete enough to orient a developer)
- Use concrete examples — mention actual skill names, entity types, file patterns
- Code examples in fenced blocks where they clarify usage
- No marketing language: "enables" not "empowers", "provides" not "delivers breakthrough"
- No pricing, investment framing, or engagement models — this is project documentation
- If propositions have evidence with metrics, include them as technical benchmarks, not sales claims
- Features with no propositions can still appear — they're part of the project's capabilities
- Link to actual file paths in the repo where relevant (e.g., `see cogni-portfolio/skills/` for the full skill list)

---

## Scope 2: Plugin Overview

**Output**: `output/communicate/repo-docs/plugin-overview.md`

**Data sources**: portfolio.json, products/*.json, features/*.json

Produces a structured summary of each plugin (product) with its capabilities (features), key skills, and how it connects to other plugins. Useful for ecosystem documentation, plugin catalogs, or developer onboarding.

```markdown
# Plugin Ecosystem Overview

{1-2 sentences describing the overall ecosystem and how plugins relate to each other.}

## {Product/Plugin Name}

**Purpose**: {One-line description of what this plugin does — derived from product description,
rewritten for developer clarity.}

**Capabilities:**

| Capability | Description |
|-----------|-------------|
| {Feature name} | {Technical one-liner from IS statement} |

{If the feature has propositions across multiple markets, note the breadth:
"Used across {N} target markets" — this signals maturity without exposing
internal market definitions.}

**Key workflows**: {List the primary workflows or skills this plugin supports.
Derive from feature descriptions and any solution types that exist.}

**Integrates with**: {List other products/plugins this one connects to.
Derive from cross-product proposition patterns or solution dependencies.}

---
```

**Content guidelines for plugin overview:**
- Target length: 300-800 words (depends on number of products)
- One product = one section, keep them parallel in structure
- Table format for capabilities — scannable, not prose-heavy
- Integration notes are valuable — developers want to understand the dependency graph
- No market-specific tailoring — this is a product/technical view

---

## Scope 3: Use-Case Gallery

**Output**: `output/communicate/repo-docs/use-case-gallery.md`

**Data sources**: portfolio.json, markets/*.json, customers/*.json, propositions/*.json, solutions/*.json (for engagement patterns)

Produces a gallery of concrete scenarios showing how the portfolio solves real problems. Each scenario is a self-contained vignette that a developer or evaluator can relate to. More detailed than the README use-cases section — each scenario gets a full treatment.

```markdown
# Use-Case Gallery

{1-2 sentences introducing the gallery. Frame as "here are concrete ways
people use [project name]" — practical, not promotional.}

---

## {Scenario Title — action-oriented, specific}

**Persona**: {Role and context — e.g., "Head of Consulting at a 200-person DACH firm"}
**Challenge**: {The specific problem they face — derived from customer pain_points}
**Approach**: {What they do with the project — which products/features they use, in what sequence}
**Result**: {What they achieve — derived from proposition MEANS statements and evidence}

{2-3 paragraphs telling the scenario as a mini-story. Walk through the workflow:
what the persona does first, what happens next, what the output looks like.
Be concrete — mention actual skill names, entity types, output formats.

Include a "before/after" contrast if the propositions support it:
"Before: manually writing 40 proposition statements across 8 features and 5 markets.
After: generating and reviewing propositions in batch, with quality assessment and
stakeholder review built into the workflow."}

---
```

**Content guidelines for use-case gallery:**
- Target length: 800-1,500 words (2-4 scenarios at 200-400 words each)
- One scenario per target market (use beachhead and expansion markets, skip aspirational)
- Persona comes from customer profiles — use role and context, not proper names
- The "Approach" section should read like a walkthrough, not a feature list
- Evidence and metrics from propositions can appear as results, framed as outcomes not sales claims
- Solutions data informs the "Approach" section — describe the workflow, not the pricing

---

## Tone Transformation Examples

These examples show how to transform internal portfolio language into developer-facing prose.

### Feature Description (IS)

**Internal**: "AI-gestützte Trend-Analyse-Plattform mit TIPS-Framework (Technologie, Innovation, People, Strategy) für systematische Identifikation und Bewertung von Branchentrends."

**Developer-facing**: "A trend analysis framework that structures industry signals across four dimensions — Technology, Innovation, People, and Strategy (TIPS). Scouts trends via bilingual web research, generates scored candidates, and feeds them into value modeling for solution prioritization."

### Market Description

**Internal**: "Mittelständische Beratungen DACH — Mid-sized consulting firms (50-500 employees). TAM: 1.2B EUR. Key dynamics: talent shortage, AI adoption pressure, methodology differentiation."

**Developer-facing**: "Mid-sized consulting firms (50-500 people) looking to systematize their go-to-market strategy. Typical scenario: 4-6 practice areas, 3-5 target markets, need to generate consistent messaging across all combinations without manual effort."

### Proposition (DOES/MEANS)

**Internal DOES**: "Reduziert den Aufwand für die Erstellung marktspezifischer Wertversprechen um 80% durch automatisierte IS/DOES/MEANS-Generierung mit Qualitätssicherung."

**Developer-facing**: "Generates IS/DOES/MEANS value propositions for each feature-market combination automatically, with built-in quality assessment (description quality, stakeholder review) catching weak messaging before it ships."

### Differentiation

**Internal**: "Einziger Anbieter mit vollständiger TIPS-zu-Portfolio-Bridge — Trend-Insights werden direkt in Produkt-Features und Markt-Propositions überführt."

**Developer-facing**: "The `trends-bridge` skill connects cogni-trends TIPS output directly to cogni-portfolio entities — solution templates from value modeling map to features, and trend evidence enriches proposition messaging. No manual re-entry between trend analysis and portfolio planning."
