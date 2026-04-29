---
name: portfolio-canvas
description: |
  Bootstrap a cogni-portfolio project from a Lean Canvas or Business Model Canvas.
  Use whenever the user mentions a lean canvas, business model canvas, startup portfolio,
  founding-stage business, "I have a canvas", "bootstrap from canvas", MVP planning,
  or wants to populate their portfolio from a structured business hypothesis document —
  even if they don't say "canvas" explicitly. Also trigger when the user has a markdown
  file with numbered sections like Problem, Customer Segments, Solution, Revenue Streams.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# Canvas-to-Portfolio Bootstrap

Seed a cogni-portfolio project from a Lean Canvas (or Business Model Canvas). This skill bridges the gap between a founding-stage hypothesis document and the structured entity model that the rest of the portfolio pipeline expects.

## Why This Exists

**Plugin root resolution.** Bash invocations below resolve the plugin root inline as `${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}` — the first call works whether or not the harness injects `$CLAUDE_PLUGIN_ROOT`. Keep the inline form in every call; do not strip it.

A lean canvas is a hypothesis document — it captures what you *think* the business is. The portfolio pipeline is a messaging system — it captures what you *sell*. For a founding-stage company these are the same thing, but the data shapes are different. This skill does the translation so that downstream skills (propositions, solutions, packages, export) work without modification.

The key insight: a canvas already contains products, markets, and pricing buried in its sections — they just need to be extracted, properly typed, and marked as early-stage (`maturity: "concept"`, `readiness: "planned"`, `priority: "beachhead"`).

## Prerequisites

- A lean canvas file (markdown, typically with numbered sections: Problem, Customer Segments, UVP, Solution, Channels, Revenue Streams, Cost Structure, Key Metrics, Unfair Advantage)
- No existing portfolio project required — this skill can create one via `portfolio-setup` if needed, or enrich an existing project

## Canvas Section → Portfolio Entity Mapping

| Canvas Section | Portfolio Entity | How It Maps |
|---|---|---|
| **Customer Segments** | Markets | Each segment becomes a market. Primary → `priority: "beachhead"`, Secondary → `"expansion"`, Tertiary → `"aspirational"`. Pain points feed downstream proposition DOES/MEANS. |
| **Solution** (layers/components) | Products | Each distinct solution layer or component becomes a product with `maturity: "concept"` and inferred `revenue_model`. |
| **Solution** (capabilities within layers) | Features | Specific capabilities mentioned within solution layers become features with `readiness: "planned"`. |
| **Revenue Streams** | Solution pricing templates | Pricing assumptions seed solution `pricing` or `subscription` fields. The revenue type (license, subscription, consulting, maintenance) determines `solution_type`. |
| **Problem** | *Context* | Pain points inform proposition DOES statements downstream — stored as `canvas_context.problems` in `portfolio.json` for reference. |
| **UVP** | *Context* | The overarching value proposition informs product `positioning` — stored as `canvas_context.uvp` in `portfolio.json`. |
| **Channels** | *Context* | Distribution channels are not portfolio entities but inform market descriptions — stored as `canvas_context.channels` in `portfolio.json`. |
| **Cost Structure** | *Context* | Cost categories inform solution `cost_model` downstream — stored as `canvas_context.cost_structure` in `portfolio.json`. |
| **Key Metrics** | *Context* | Stored as `canvas_context.key_metrics` in `portfolio.json` for reference. |
| **Unfair Advantage** | *Context* | Feeds differentiators in portfolio-context export — stored as `canvas_context.unfair_advantage` in `portfolio.json`. |
| **Assumptions to Validate** | *Context* | Stored as `canvas_context.assumptions` in `portfolio.json`. Referenced during proposition and solution creation so hypotheses stay visible. |

Sections that don't map directly to entities are preserved as `canvas_context` in `portfolio.json`. This matters because downstream skills (especially propositions and solutions) can read this context to stay grounded in the founding-stage reality rather than generating messaging as if the company were established.

## Workflow

### 1. Locate and Parse the Canvas

Read the canvas file provided by the user. Support common lean canvas formats:
- Numbered sections (## 1. Problem, ## 2. Customer Segments, etc.)
- Named sections (## Problem, ## Customer Segments, etc.)
- Bullet-point or prose within sections

Extract content from each section into a structured intermediate representation. If a section is empty or marked with "?" (common for early drafts), note it as unfilled.

### 2. Check for Existing Portfolio Project

Search for `portfolio.json` under a `cogni-portfolio/` path in the workspace. Two paths:

- **No project exists**: Proceed to Step 3 to create one.
- **Project exists**: Ask the user whether to enrich the existing project with canvas data or start fresh. If enriching, cross-reference extracted entities against existing `products/`, `features/`, and `markets/` directories to avoid duplicates.

### 3. Bootstrap Project (if needed)

If no portfolio project exists, extract setup fields from the canvas:

- **Company name**: May need to ask the user (canvases rarely include this)
- **Description**: Derive from the UVP section
- **Industry**: Infer from the solution domain, confirm with user
- **Products**: Extract from the Solution section

Run the setup scaffold (same as `portfolio-setup`):

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/project-init.sh" "<workspace-dir>" "<project-slug>"
```

Write `portfolio.json` with company context plus the `canvas_context` object.

### 4. Present Extraction Plan

Before creating any entities, present the full extraction plan as a table:

**Products (from Solution section)**

| Slug | Name | Revenue Model | Maturity | Source |
|---|---|---|---|---|
| `iwae-platform` | IWAE Platform | subscription | concept | Solution Layer 1 |
| `plugin-marketplace` | Plugin Marketplace | hybrid | concept | Solution Layer 2 |
| `consulting-services` | Implementation Consulting | project | concept | Solution Layer 3 |

**Features (from Solution capabilities)**

| Slug | Product | Name | Readiness | Source |
|---|---|---|---|---|
| `claude-obsidian-integration` | iwae-platform | Claude + Obsidian Integration | planned | Solution 1, bullet 1 |
| `gdpr-deployment` | iwae-platform | GDPR-Compliant EU Deployment | planned | Solution 1, bullet 3 |

**Markets (from Customer Segments)**

| Slug | Name | Priority | Region | Source |
|---|---|---|---|---|
| `boutique-consultants-dach` | Capacity-Constrained Consulting Boutiques | beachhead | dach | Segment: Primary |
| `ai-partners-dach` | AI Portfolio-Expanding Consultancies | expansion | dach | Segment: Secondary |
| `sme-sales-dach` | AI-Ambitious SME Sales Functions | aspirational | dach | Segment: Tertiary |

**Canvas Context (preserved in portfolio.json)**

| Section | Status | Content Summary |
|---|---|---|
| Problem | filled | 10h/week automation potential... |
| UVP | filled | World's first open-source IWAE... |
| Channels | filled | 4 channels identified |
| Revenue Streams | filled | 5 streams with pricing assumptions |
| Cost Structure | filled | 5 cost categories |
| Key Metrics | unfilled | — |
| Unfair Advantage | unfilled | — |
| Assumptions | filled | 5 assumptions to validate |

Allow the user to:
- **Approve all** — create everything as proposed
- **Edit** — modify slugs, names, assignments, or skip individual entities
- **Adjust region** — the default region is `dach`; the user may want `eu`, `global`, or another region

### 5. Infer Revenue Models and Solution Types

Map canvas revenue streams to portfolio solution types. This inference drives how downstream solutions are structured:

| Revenue Stream Pattern | `revenue_model` | `solution_type` |
|---|---|---|
| License, SaaS, subscription, per-seat, per-month | `subscription` | `subscription` |
| Consulting, implementation, project-based | `project` | `project` |
| Certification, training, onboarding | `project` | `project` |
| Maintenance, support, retainer | `subscription` | `subscription` |
| Partnership, revenue-share, referral | `partnership` | `partnership` |
| Mixed (e.g., SaaS + consulting) | `hybrid` | `hybrid` |

When pricing assumptions exist in the canvas (e.g., "€15k/year", "€3k/participant"), preserve them as `canvas_pricing` annotations on the relevant product. These become seed values when the user later runs the `solutions` skill.

### 6. Write Entity Files

For each confirmed entity, write JSON following the schemas in `$CLAUDE_PLUGIN_ROOT/references/data-model.md`.

**Products** — write to `products/{slug}.json`:
- Set `maturity: "concept"` (founding stage)
- Set `revenue_model` based on Step 5 inference
- Set `positioning` from the UVP section if applicable to this product
- Include `"source_file": "<canvas-filename>"` for traceability

**Features** — write to `features/{slug}.json`:
- Set `readiness: "planned"` (not yet built) unless the canvas indicates otherwise
- Set `product_slug` to the parent product
- Draft a `purpose` field (5-12 words): a customer-readable statement answering "what is this feature FOR?" — the problem it solves or the capability it provides. Purpose sits between name (label) and description (mechanism). Example: name "Cloud Monitoring", purpose "Real-time visibility into cloud health and incidents".
- Write market-independent IS-layer descriptions (what it IS, not what it does for a specific segment)
- Assign `sort_order` following the value-to-utility spectrum: customer-facing value features get low numbers (10, 20, 30...), infrastructure/utility features get high numbers (70+). Use increments of 10.

**Markets** — write to `markets/{slug}.json`:
- Set `priority` based on segment tier (primary/secondary/tertiary)
- Include pain points from the canvas in `description`
- Leave `tam`/`sam`/`som` empty with a note — founding-stage businesses typically have hypotheses, not validated sizing. The `markets` skill can add sizing later.
- Set `segmentation` fields where the canvas provides enough detail (employee range, vertical, etc.)

### 7. Write Canvas Context to portfolio.json

Add or update the `canvas_context` object in `portfolio.json`:

```json
{
  "canvas_context": {
    "canvas_version": "1.0",
    "canvas_date": "2025-01-16",
    "source_file": "current-canvas.md",
    "problems": ["Primary: ...", "Secondary: ..."],
    "uvp": "World's first open-source...",
    "channels": ["Partner Network", "Open Source", "Digital Marketing", "Direct SME Sales"],
    "cost_structure": ["Platform Development", "Partner Program", ...],
    "key_metrics": null,
    "unfair_advantage": null,
    "assumptions": [
      "SMEs will pay €25-40k for partner-led transformation",
      "Consultants will join and actively participate in collective",
      ...
    ],
    "revenue_seeds": {
      "builder-license": { "type": "subscription", "assumption": "€15k/year" },
      "certifications": { "type": "project", "assumption": "€3k/participant" },
      "consulting": { "type": "project", "assumption": "€15-45k/project" },
      "maintenance": { "type": "subscription", "assumption": "€2k/year for 1-5 workplaces" }
    }
  }
}
```

### 8. Sync and Summarize

Run the portfolio sync script if products were created:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/sync-portfolio.sh" <project-dir>
```

Present a summary:

| Entity Type | Created | From Canvas Section |
|---|---|---|
| Products | 3 | Solution (3 layers) |
| Features | 6 | Solution (capabilities) |
| Markets | 3 | Customer Segments (3 tiers) |
| Canvas Context | saved | Problem, UVP, Channels, Revenue, Costs, Assumptions |

### 9. Recommend Next Steps

The founding-stage portfolio is now seeded. Suggest the natural next steps, calibrated to the company's stage:

1. **Visualize the structure** with the `portfolio-architecture` skill — see the product-feature hierarchy at a glance, spot empty products or unbalanced feature distribution before diving into refinements
2. **Refine products** with the `products` skill — challenge positioning, check boundaries between layers
3. **Refine features** with the `features` skill — ensure IS-layer descriptions are market-independent
4. **Size markets** with the `markets` skill — even rough TAM/SAM/SOM estimates help prioritize
5. **Generate propositions** with the `propositions` skill — this is where canvas pain points become DOES/MEANS messaging
6. **Define solutions** with the `solutions` skill — canvas pricing assumptions become seed values
7. **Validate assumptions** — the assumptions from the canvas are preserved in `portfolio.json`; revisit them as the business evolves

If sections were unfilled (Key Metrics, Unfair Advantage), note that these can inform the portfolio later as the business matures.

## Handling Canvas Variants

### Business Model Canvas (BMC)
If the user provides a full BMC instead of a lean canvas, the mapping adjusts:
- **Key Partners** → stored in canvas_context (informs partnership solutions)
- **Key Activities** → may inform features
- **Key Resources** → stored in canvas_context
- **Value Propositions** → same as UVP
- **Customer Relationships** → stored in canvas_context
- **Customer Segments** → same mapping as lean canvas
- **Channels** → same mapping as lean canvas
- **Cost Structure** → same mapping as lean canvas
- **Revenue Streams** → same mapping as lean canvas

### Incomplete Canvases
Early drafts often have empty sections or "?" placeholders. Handle gracefully:
- Create entities only from sections with actual content
- Note unfilled sections in the summary
- Suggest the user fill gaps before running downstream skills (especially propositions, which need both features AND markets)

## Important Notes

- Always confirm entities with the user before writing — never auto-create
- All products get `maturity: "concept"` unless the user says otherwise
- All features get `readiness: "planned"` unless the user indicates something is already built
- Markets default to `dach` region — ask the user to confirm the operating region
- Revenue stream pricing is stored as context, not committed to solution files (the `solutions` skill handles proper pricing)
- Canvas assumptions are preserved, not discarded — they're the founding team's hypotheses and should stay visible throughout the portfolio lifecycle
- **Communication Language**: Read `portfolio.json` in the project root. If a `language` field is present, communicate with the user in that language. If no `language` field is present, default to English.
- Refer to `$CLAUDE_PLUGIN_ROOT/references/data-model.md` for complete entity schemas
