---
name: portfolio-communicate
description: |
  Generate portfolio documentation for any audience — customer-facing narratives,
  repository documentation, developer guides, or custom use cases. Routes through
  a use-case registry that matches the audience and purpose to the right voice,
  templates, and review perspectives. Use whenever the user mentions
  "communicate portfolio", "portfolio documentation", "customer-facing documentation",
  "present portfolio", "portfolio overview", "capability overview", "service catalog",
  "enrich README", "repo documentation", "developer documentation", "update README
  with portfolio", "document the project", "open-source documentation", "GitHub README",
  "project overview for developers", "technical documentation from portfolio",
  "what do we offer", "external portfolio", "portfolio narrative", "make this
  customer-ready", or wants to turn internal portfolio data into something any
  audience can read — even if they don't say "communicate" explicitly. Also trigger
  when the user has completed synthesize or export and asks "how do I present this"
  or "how do I document this".
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# Portfolio Communicate

Generate documentation from portfolio entities for any audience and purpose. Where `synthesize` produces an internal messaging repository (tables, matrices, gap flags) and `portfolio-export` produces per-proposition proposals and per-market briefs, this skill produces **audience-tailored narratives** that present the company's offerings through the reader's lens — whether that reader is a buyer, a developer, an investor, or someone else entirely.

## Core Concept

Internal portfolio documentation serves internal teams — it exposes gaps, uses slugs, shows TAM/SAM/SOM numbers, and organizes by entity type. External audiences never see that. What they need depends on who they are:

| Audience | What they need |
|----------|---------------|
| Buyers/executives | Value-led stories: what you do for people like them, why it matters, what engaging looks like |
| Developers/community | Technical clarity: what the project does, how it works, how to get started |
| Investors | Business potential: problem, solution, market, traction, differentiation |
| Partners | Integration points: what capabilities exist, how to build on them |

This skill reads the same entity files as synthesize and export, but transforms them through a **use-case lens** that matches the audience and purpose. Each use case defines its own voice, output templates, and review criteria.

## Prerequisites

Verify the portfolio is sufficiently complete before generating:

```bash
bash $CLAUDE_PLUGIN_ROOT/scripts/validate-entities.sh "<project-dir>"
bash $CLAUDE_PLUGIN_ROOT/scripts/project-status.sh "<project-dir>"
```

Minimum requirements:
- At least 1 product, 1 feature (with valid product_slug), 1 market, and 1 proposition
- `portfolio.json` has company context filled in

Running `synthesize` first is recommended as a quality gate — if the internal messaging repository reads well, output will be strong. Not strictly required.

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
> - **Customer narratives** — website content, sales materials, executive briefings (company speaks to buyer)
> - **Repository documentation** — README enrichment, plugin overviews, getting-started guides (project speaks to developer)
> - {any custom use cases from communicate-use-cases.json}
> - **Something else** — describe your purpose and I'll help shape the output

**If the user selects "something else"**, follow the ad-hoc flow (see [Ad-Hoc Use Cases](#ad-hoc-use-cases) below).

### Step 1: Determine Scope

Load the scope options from the selected use case (see registry). Only ask for clarification if genuinely ambiguous.

For **`customer-narrative`**: overview, market (which one?), customer (which market and persona?), or all.
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

**Repo-documentation:**
- All `propositions/*.json` (for value framing and breadth indicators)
- `markets/*.json` (for use-case derivation)
- `customers/*.json` (for persona-based scenario descriptions)
- Solutions and competitors are optional — include if they enrich technical descriptions

**Ad-hoc/custom:** Load all entities by default, let the generation step filter what's relevant.

**Internal context (optional):** If `context/context-index.json` exists, read relevant entries. Strategic context enriches company positioning. Competitive context sharpens differentiation.

### Step 3: Generate Markdown

Load the template file for the selected use case from the registry's `template` reference. For built-in use cases:
- `customer-narrative` -> read `references/templates-customer-narrative.md`
- `repo-documentation` -> read `references/templates-repo-documentation.md`

For custom use cases, generate section structure based on the use case's `voice`, `scopes`, and `audience` fields — no separate template file is needed.

For ad-hoc use cases, use the parameters collected during the ad-hoc flow.

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

- Output goes to `output/communicate/{use-case-id}/` — separate from synthesize (`output/README.md`) and export (`output/proposals/`, `output/briefs/`)
- Re-running overwrites previous output for that scope within the use case
- Each generated file includes YAML frontmatter with `use_case` field
- **Content Language**: Read `portfolio.json` `language` field. Generate content in that language if present, default to English
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with the user in that language. Technical terms, skill names, and CLI commands remain in English
- **Proper character encoding**: Always use proper Unicode characters — German umlauts (ä, ö, ü, ß), em dashes (—), curly quotes where appropriate. Never substitute ASCII approximations.

## Additional Resources

### Reference Files

- **`references/use-case-registry.md`** — Registry of available use cases with trigger phrases, voice profiles, scope options, and review configuration
- **`references/templates-customer-narrative.md`** — Complete markdown templates for customer-facing narratives (overview, market, customer)
- **`references/templates-repo-documentation.md`** — Templates for developer-facing content (readme-enrichment, plugin-overview, use-case-gallery)

### Agents

- **`communicate-review-assessor`** — Use-case-aware stakeholder review for output quality. Adapts perspectives based on the use case: buyer/marketing/sales for customer narratives, developer/maintainer/writer for repo documentation, custom perspectives for ad-hoc use cases.
