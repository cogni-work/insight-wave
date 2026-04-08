---
name: portfolio-communicate
description: |
  Generate portfolio documentation, pitch narratives, proposals, briefs, and
  workbooks for any audience. Routes through a use-case registry that matches
  the audience and purpose to the right voice, templates, and review perspectives.
  Use whenever the user mentions "communicate portfolio", "portfolio documentation",
  "customer-facing documentation", "present portfolio", "portfolio overview",
  "capability overview", "service catalog", "enrich README", "repo documentation",
  "developer documentation", "update README with portfolio", "document the project",
  "open-source documentation", "GitHub README", "project overview for developers",
  "technical documentation from portfolio", "what do we offer", "external portfolio",
  "portfolio narrative", "make this customer-ready", "pitch", "portfolio pitch",
  "presentation narrative", "pitch deck from portfolio", "slides from portfolio",
  "portfolio story", "pitch for [market]", "proposal", "create a proposal",
  "sales proposal", "marketing brief", "market brief", "export to Excel",
  "spreadsheet", "XLSX", "workbook", "portfolio workbook", "send to Excel",
  "download portfolio", "collateral", "deliverable", or wants to turn internal
  portfolio data into something any audience can read, present, or analyze — even
  if they don't say "communicate" explicitly. Also trigger when the user asks
  "how do I present this", "how do I document this", or "how do I export this".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
---

# Portfolio Communicate

The single output skill for the portfolio pipeline. Transforms portfolio entities into **anything an audience needs** — documentation, pitch narratives, proposals, marketing briefs, or data workbooks. It routes through a use-case registry that matches the audience and purpose to the right voice, templates, and review perspectives.

## Core Concept

Internal portfolio data (slugs, TAM/SAM/SOM, relevance tiers, quality scores) is never what an audience sees. What they need depends on who they are and how they'll consume it:

| Use Case | Audience | Output | Format |
|----------|----------|--------|--------|
| `customer-narrative` | Buyers, executives | Value-led documentation for self-paced reading | Markdown |
| `repo-documentation` | Developers, OSS community | Technical clarity: what, how, getting started | Markdown |
| `pitch` | Executives, conference, board | Arc-structured presentation narrative (cogni-narrative compatible) | Markdown with `arc_id` |
| `proposal` | Sales teams, prospects | Per-proposition sales proposal | Markdown |
| `market-brief` | Marketing teams | Market content package with sizing, buyer profile, messaging | Markdown |
| `workbook` | Leadership, analysts | Structured spreadsheet with all portfolio data | XLSX |
| Custom/ad-hoc | Any audience | User-defined voice, sections, review | Markdown |

Each use case defines its own voice, output templates, and review criteria. The `pitch` use case is unique: its output includes `arc_id` in frontmatter, making it directly consumable by story-to-slides, story-to-web, story-to-big-picture, and story-to-storyboard — no intermediate `/narrative` step needed.

## Prerequisites

Verify the portfolio is sufficiently complete before generating:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/validate-entities.sh "<project-dir>"
bash $CLAUDE_PLUGIN_ROOT/scripts/project-status.sh "<project-dir>"
```

Minimum requirements:
- At least 1 product, 1 feature (with valid product_slug), 1 market, and 1 proposition
- `portfolio.json` has company context filled in

If `cogni-claims/claims.json` exists, check claim verification status. Warn about unverified claims and recommend running the `verify` skill first. Allow the user to proceed — handle unverified claims according to the use case (customer-narrative: omit silently; repo-documentation: include with `[unverified]` marker; ad-hoc: ask the user).

## Workflow

### Step 0: Determine Use Case

Read `references/use-case-registry.md` for the full registry of available use cases. Also check for `communicate-use-cases.json` in the project root for user-defined custom use cases.

**Infer the use case from the user's request.** Match against trigger phrases and context from the registry. Inference priority:

1. **Explicit match** — user mentions a use case by name or a clear trigger phrase
2. **Context match** — the request context implies a use case (e.g., mentioning "README" implies `repo-documentation`)
3. **Custom match** — check `communicate-use-cases.json` for custom use cases whose audience/name matches
4. **Ambiguous** — present the use case menu

If the request is ambiguous, present options:

> "What do you want to use the portfolio content for?"
> - **Pitch narrative** — arc-structured presentation narrative, ready for story-to-slides (company presents to audience)
> - **Customer narratives** — website content, sales materials, executive briefings (company speaks to buyer)
> - **Proposals** — per-proposition sales proposals for specific Feature × Market pairs
> - **Marketing briefs** — market content packages with sizing, buyer profile, messaging themes
> - **Portfolio workbook** — XLSX spreadsheet with all portfolio data for analysis
> - **Repository documentation** — README enrichment, plugin overviews, getting-started guides (project speaks to developer)
> - {any custom use cases from communicate-use-cases.json}
> - **Something else** — describe your purpose and I'll help shape the output

**If the user selects "something else"**, follow the ad-hoc flow (see [Ad-Hoc Use Cases](#ad-hoc-use-cases) below).

### Step 1: Determine Scope

Load the scope options from the selected use case (see registry). Only ask for clarification if genuinely ambiguous.

For **`customer-narrative`**: overview, market (which one?), customer (which market and persona?), or all.
For **`pitch`**: market (which one?), overview (portfolio-wide), or all.
For **`proposal`**: single (which proposition?), market (all propositions in a market), or all.
For **`market-brief`**: single (which market?), or all.
For **`workbook`**: full (all sheets), or matrix (proposition matrix only).
For **`repo-documentation`**: readme-enrichment, plugin-overview, use-case-gallery, or all.
For **custom/ad-hoc use cases**: use the scopes defined in the use case configuration.

If the request is vague, present the scope options from the selected use case.

### Step 2: Load Entities

Read entity files from the project directory. Which entities to load depends on the use case and scope:

**All use cases:**
- `portfolio.json` for company context and language
- All `products/*.json`, `features/*.json`

**Customer-narrative (all scopes):**
- All `propositions/*.json` (filter by market for tailored views)
- All `solutions/*.json` and `packages/*.json` (if available)
- `markets/*.json` and `customers/*.json` (for tailored views)
- `competitors/*.json` (for differentiation, woven into narrative)

**Pitch:**
- `markets/{market-slug}.json` (or all markets for overview/all scopes)
- All `propositions/{feature}--{market-slug}.json` for the target market(s)
- `customers/{market-slug}.json` for pain points (Why Change)
- `competitors/{feature}--{market-slug}.json` for differentiation (Why You)
- `solutions/{feature}--{market-slug}.json` and `packages/{product}--{market-slug}.json` for pricing (Why Pay)
- Run `$CLAUDE_PLUGIN_ROOT/scripts/project-status.sh` for relevance tiers
- Read arc definition from `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md`
- Optional: check for TIPS bridge data (trend entities with `urgency: "Act"` for Why Now)

**Proposal:**
- The specific proposition, its feature, product, market, customer profile, competitor analysis
- Solution and package for this proposition (if available)
- Run `$CLAUDE_PLUGIN_ROOT/scripts/project-status.sh` for relevance tiers (when batch generating)

**Market-brief:**
- The market, all propositions targeting it, customer profile, all competitor analyses
- Solutions and packages for propositions in this market

**Workbook:**
- Everything: products, features, markets, propositions, solutions, packages, competitors, customers

**Repo-documentation:**
- All `propositions/*.json` (for value framing and breadth indicators)
- `markets/*.json` (for use-case derivation)
- `customers/*.json` (for persona-based scenario descriptions)
- Solutions and competitors are optional — include if they enrich technical descriptions

**Ad-hoc/custom:** Load all entities by default, let the generation step filter what's relevant.

**Internal context (optional):** If `context/context-index.json` exists, read relevant entries. Strategic context enriches company positioning. Competitive context sharpens differentiation.

**Derive a messaging mode for every product and feature.** Before moving on, walk the loaded products and features and attach a `messaging_mode` to each in memory. No new files are read — the signal comes from the `maturity` field already present on products (schema in `cogni-portfolio/references/data-model.md`) and the `readiness` field already present on features. The mapping is defined in [Maturity-Aware Messaging](#maturity-aware-messaging) below. This is the single place where messaging mode is derived; Step 3 and the templates consume it but do not re-derive it.

### Maturity-Aware Messaging

Portfolios are living things. At any moment they contain products at very different stages of real availability: a flagship offering that has been shipping for years, a new service that just launched, a beta that a handful of design partners are piloting, and a concept that is still a roadmap item. **If the generated output describes all of these in the same confident present tense, it overclaims.** A buyer reading "we deliver X" about a concept-stage product will ask for it next week — and every answer from that point forward damages trust.

The fix is not to hide early-stage offerings. The user usually *wants* them in the output — buyers and investors care about what's coming, not just what's shipping today. The fix is to **frame them correctly**: announce what's coming, qualify what's in preview, confidently present what's live, and gracefully handle what's winding down.

#### Messaging modes

Collapse the raw `maturity` × `readiness` signal into **five messaging modes**. Templates branch on the mode, not on the underlying values, so adding a new maturity value later only requires extending this table.

| Product `maturity` | Feature `readiness` (dominant) | Mode | Voice rule |
|---|---|---|---|
| `concept` | any | **announce** | Future tense. "We are building…", "Expected availability: …". No delivered-outcome proof points. Pricing hidden or explicitly "indicative". Use labels like *(Coming soon)*. |
| `development` | `planned` / mixed | **announce** | Same as concept. May reference design-partner or early-access programs when evidence supports it. |
| `development` | mostly `beta` | **preview** | Present tense, qualified with "in beta" / "early access". Proof points allowed if labelled as pilots. Pricing allowed only as "introductory" or "early-access". Label: *(Beta)*. |
| `launch` | mostly `ga` | **launch** | Present tense, "newly available" framing. Proof points allowed. Standard pricing. Label: *(Newly launched)*. |
| `growth` / `mature` | `ga` | **standard** | The existing default voice — confident present tense, full proof points, full pricing. This is the baseline the skill already produces today. |
| `decline` | any | **sunset** | Neutral tone. "We continue to support existing customers; not accepting new engagements." No CTAs. Omitted from overview listings by default; included only when the scope explicitly asks. Label: *(Legacy — existing customers only)*. |
| Missing `maturity` | — | **standard** | Fall back to today's behaviour so older projects keep working. Surface a single soft warning at the top of the generated file listing the product slugs that had no maturity set. |

**Product-level vs feature-level resolution.** At the product or portfolio level the product's mode wins. At the sentence level, where a *specific feature* is being described, the effective mode is the stricter of the two (product mode and feature mode) — so a `beta` feature inside a `growth` product is described as "in beta" even though the surrounding product prose is confident. Strictness order, most lenient to most restrictive: `standard` → `launch` → `preview` → `announce` → `sunset`.

**Why a derived mode and not raw maturity.** Templates need a small number of voice choices. Six maturity values times three readiness values times five templates would drift in five different directions. One mode, defined in one place, keeps voice rules consistent across customer narratives, pitches, proposals, briefs and repo documentation.

**Why keep early-stage products visible.** Hiding concept products defeats the reason portfolio-communicate exists — to tell the full story of what the company is doing. The announce mode is specifically designed so that concept material can appear in the output *as an announcement* rather than as an offering. The one exception is the `proposal` use case: generating a sales proposal for something that does not exist yet is the exact failure mode this section exists to prevent, and `templates-proposal.md` blocks it explicitly.

**Carrying the mode into the review loop.** Step 4 passes the mode (or the effective mode per section) to `communicate-review-assessor` so it can flag overclaims — present-tense language describing a concept-stage offering, or proposals generated against announce-mode propositions — as review failures instead of letting them slip through.

### Step 3: Generate Markdown

Load the template file for the selected use case from the registry's `template` reference. For built-in use cases:
- `customer-narrative` -> read `references/templates-customer-narrative.md`
- `pitch` -> read `references/templates-pitch.md`
- `proposal` -> read `references/templates-proposal.md`
- `market-brief` -> read `references/templates-market-brief.md`
- `workbook` -> no template; prepare structured data and delegate to `document-skills:xlsx` skill (fallback to CSV)
- `repo-documentation` -> read `references/templates-repo-documentation.md`

For custom use cases, generate section structure based on the use case's `voice`, `scopes`, and `audience` fields — no separate template file is needed.

For ad-hoc use cases, use the parameters collected during the ad-hoc flow.

**Messaging mode rule**: Every template consults the `messaging_mode` attached to each product/feature in Step 2 to decide voice, tense, section visibility and labels. See [Maturity-Aware Messaging](#maturity-aware-messaging) for the authoritative mapping and each template's "Handling messaging mode" block for how that template applies it. If any product in the loaded set is missing `maturity`, prepend the generated file (under the YAML frontmatter, above the first heading) with a single HTML comment of the form `<!-- notice: products without maturity fell back to standard mode: {slug1}, {slug2} -->` so the fallback is auditable without being visible to the end reader.

**Citation rule**: All templates require citations to link to **external source URLs** from entity `evidence[].source_url` fields. Never generate citations that link to internal JSON file paths (e.g., `propositions/x.json`). When an evidence claim has no external URL, present it as an inline estimate without a citation. See each template's Citations section for format details.

**Blueprint metadata is internal.** Solutions may carry `blueprint_ref` and `blueprint_version` fields — these track delivery pattern consistency and are used by the solutions skill for drift detection. Never expose blueprint metadata in customer-facing output (proposals, pitches, customer narratives). It is acceptable to reference the delivery structure itself (phases, timelines) since that comes from the solution content, but not the blueprint versioning mechanism.

**Output path:** Write to `output/communicate/{use-case-id}/` followed by the scope-specific filename from the template.

**Backward compatibility:** If old-format files exist at `output/communicate/portfolio-overview.md` (without use-case subdirectory), mention that the output structure has changed and that new files will be in `output/communicate/customer-narrative/`. Do not automatically migrate or delete old files.

### Step 4: Stakeholder Review (Closed Loop)

After generating output, delegate to the `communicate-review-assessor` agent for quality assessment. The assessor adapts its perspectives based on the use case.

**Spawn the agent** with:
- Project directory path
- The generated output file path
- The use case ID (`customer-narrative`, `repo-documentation`, or custom ID)
- The scope (`overview`, `readme-enrichment`, etc.)
- The market slug (for market and customer scopes)
- The persona identifier (for customer scope)
- A `messaging_modes` map of product slug → derived mode (from Step 2), so the assessor can flag any present-tense claim made about an announce-mode product or any proposal generated against an announce-mode proposition

For **ad-hoc and custom use cases**, also pass the review perspectives defined during the ad-hoc flow or in the custom use case's `review.perspectives` array.

**Processing the verdict:**

**accept** (all perspectives score 85+): The document is ready. Store the review JSON and proceed to step 5. Surface any `optional_improvements` from the synthesis to the user.

**revise** (all perspectives score 70+ but not all 85+):
1. Parse `revision_guidance` and `critical_improvements` from the review JSON
2. Re-read the generated markdown
3. Apply CRITICAL improvements first, then HIGH. For each improvement:
   - Cross-reference source entities to ensure accuracy
   - Preserve: YAML frontmatter, evidence citations, proper character encoding, narrative structure
4. Write the revised markdown (overwrite the same output file)
5. Re-run the assessor (round 2)
6. Maximum 2 revision rounds. After round 2, present remaining issues to the user

**reject** (any perspective below 50): Surface the full assessment to the user. Do not auto-retry. Ask whether to regenerate from scratch or address specific issues manually.

**Interactive vs batch mode:**
- **Single file**: Present assessment summary after round 1. Let the user decide whether to auto-revise or adjust manually.
- **Batch ("All" scope)**: Run the loop automatically. Files that accept after round 1 skip round 2. Files that fail after round 2 are flagged in the batch summary.

**Skipping review:** Some ad-hoc use cases may not need formal review. If the user indicated review is not needed during the ad-hoc flow, skip this step and go directly to step 5.

**Store review results** alongside each generated file:
- `output/communicate/{use-case-id}/{filename}.review.json`

The review JSON contains all rounds with timestamps and final verdict:
```json
{
  "skill": "portfolio-communicate",
  "use_case": "customer-narrative",
  "assessor": "communicate-review-assessor",
  "rounds": [
    { "round": 1, "verdict": "revise", "overall_score": 74, "timestamp": "...", "full_assessment": { "..." } },
    { "round": 2, "verdict": "accept", "overall_score": 87, "timestamp": "...", "full_assessment": { "..." } }
  ],
  "final_verdict": "accept",
  "final_score": 87
}
```

### Step 5: Present Results and Suggest Next Steps

List generated files with paths AND their review status.

**If all files accepted**, show per-file review scores, then suggest the downstream pipeline appropriate for the use case:

For **customer-narrative**:
- **Polish prose**: "Run `/copywrite` on any generated file to polish for executive readability"
- **Arc narrative**: "Run `/narrative --source-path output/communicate/customer-narrative/...` to transform into an arc-driven executive narrative"
- **Visual formats** (after narrative): `/story-to-web` for landing pages, `/story-to-slides` for presentations, `/story-to-big-picture` for visual journey maps
- **Marketing content** (if cogni-marketing installed): "These customer narratives are automatically discovered by `/marketing-setup` and used as voice/messaging enrichment when generating marketing content — ensuring consistency between how you present your portfolio and how your marketing speaks to the same audience"

For **pitch**:
- **Score quality**: "Run `/narrative-review` to score against the arc's quality gates"
- **Polish prose**: "Run `/copywrite` to polish for executive readability while preserving arc structure"
- **Visual formats** (direct — no intermediate step needed):
  - `/story-to-slides` → PowerPoint presentation
  - `/story-to-web` → scrollable landing page
  - `/story-to-big-picture` → illustrated visual journey map
  - `/story-to-storyboard` → multi-poster print storyboard
- **Deepen**: "Run `/why-change` to add web research, customer-specific context, and TIPS enrichment for a deal-ready version"

For **proposal**:
- **Polish prose**: "Run `/copywrite` to polish for buyer readability"
- **Share**: "Customize per prospect and share with sales team"

For **market-brief**:
- **Polish prose**: "Run `/copywrite` to polish"
- **Campaign planning**: "Distribute to marketing for campaign planning, or feed into `/content-strategy`"

For **workbook**:
- **Share**: "Share with leadership for portfolio review and analysis"

For **repo-documentation**:
- **Polish prose**: "Run `/copywrite` to polish for readability"
- **Merge into README**: "Copy the sections you need from `output/communicate/repo-docs/readme-sections.md` into your project's README"
- No narrative arc transformation — developer docs don't need story arcs

For **custom/ad-hoc use cases**: suggest downstream steps from the use case's `downstream` field, or recommend `/copywrite` as a safe default.

**If any files in revise after max rounds:** Show remaining issues per file. Suggest targeted manual edits before downstream pipeline.

**If any files rejected:** Block downstream suggestions for those files. Show diagnosis with specific failure points. Suggest regeneration or manual intervention.

**Save as custom use case (ad-hoc only):** If this was an ad-hoc run, offer: "Would you like to save this configuration as a reusable use case? Next time you can just reference it by name." If yes, write to `communicate-use-cases.json` in the project root (create the file if it doesn't exist; append to the `use_cases` array if it does).

## Ad-Hoc Use Cases

When the user selects "something else" or describes a purpose that doesn't match any registered use case, guide them through defining the parameters:

**1. Audience**: "Who will read this?" Suggest common options based on what the portfolio contains:
- Developers / technical evaluators
- Investors / board members
- Partners / channel partners
- Internal team / new hires
- Regulators / compliance reviewers
- Let the user describe their own audience

**2. Voice/Tone**: "How should it sound?" Suggest based on the audience:
- Technical but accessible (developers)
- Confident, data-backed (investors)
- Collaborative, integration-focused (partners)
- Clear, structured (internal)
- Or let the user describe their preferred tone

**3. Sections**: "What sections do you need?" Suggest a structure based on the audience:
- For developers: overview, capabilities, architecture, getting started
- For investors: problem, solution, market, traction, differentiation, team
- For partners: capabilities, integration points, joint value, engagement model
- For internal: what we sell, who we sell to, how we position, competitive landscape
- Let the user adjust — add, remove, or rename sections

**4. Review**: "Should we review the output quality?" Suggest appropriate perspectives based on the audience. If the user wants review, ask from whose perspective (or suggest based on audience). If the user skips review, generation still runs but step 4 is skipped.

**5. Generate** using the collected parameters. The voice, sections, and entity selection follow from the audience definition. Write output to `output/communicate/ad-hoc/` (or a user-chosen directory name).

**6. Persist (optional)**: After generation, offer to save as a reusable custom use case.

## Important Notes

- Output goes to `output/communicate/{use-case-id}/`
- Re-running overwrites previous output for that scope within the use case
- Each generated file includes YAML frontmatter with `use_case` field
- **Content Language**: Read `portfolio.json` `language` field. Generate content in that language if present, default to English
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with the user in that language. Technical terms, skill names, and CLI commands remain in English
- **Proper character encoding**: Always use proper Unicode characters — German umlauts (ä, ö, ü, ß), em dashes (—), curly quotes where appropriate. Never substitute ASCII approximations.

## Additional Resources

### Reference Files

- **`references/use-case-registry.md`** — Registry of available use cases with trigger phrases, voice profiles, scope options, and review configuration
- **`references/templates-customer-narrative.md`** — Templates for customer-facing narratives (overview, market, customer)
- **`references/templates-pitch.md`** — Templates for arc-structured pitch narratives (cogni-narrative compatible)
- **`references/templates-proposal.md`** — Templates for per-proposition sales proposals
- **`references/templates-market-brief.md`** — Templates for per-market marketing briefs
- **`references/templates-repo-documentation.md`** — Templates for developer-facing content (readme-enrichment, plugin-overview, use-case-gallery)

### Agents

- **`communicate-review-assessor`** — Use-case-aware stakeholder review for output quality. Adapts perspectives based on the use case: buyer/marketing/sales for customer narratives, developer/maintainer/writer for repo documentation, custom perspectives for ad-hoc use cases.
