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
  "portfolio narrative", "make this customer-ready", "portfolio website",
  "website content", "landing page", "home page", "about us page", "how we work page",
  "capability page", "for [persona] page", "web content from portfolio", "pitch", "portfolio pitch",
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

**Plugin root resolution.** Bash invocations below resolve the plugin root inline as `${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}` — the first call works whether or not the harness injects `$CLAUDE_PLUGIN_ROOT`. Keep the inline form in every call; do not strip it.

Internal portfolio data (slugs, TAM/SAM/SOM, relevance tiers, quality scores) is never what an audience sees. What they need depends on who they are and how they'll consume it:

| Use Case | Audience | Output | Format |
|----------|----------|--------|--------|
| `customer-narrative` | Buyers navigating a portfolio-driven website | Home / About / Capability / Persona / Approach pages, each arc-structured | Markdown with `arc_id` (per-scope) |
| `repo-documentation` | Developers, OSS community | Technical clarity: what, how, getting started | Markdown |
| `pitch` | Executives, conference, board | Arc-structured presentation narrative (cogni-narrative compatible) | Markdown with `arc_id` |
| `proposal` | Sales teams, prospects | Per-proposition sales proposal | Markdown |
| `market-brief` | Marketing teams | Market content package with sizing, buyer profile, messaging | Markdown |
| `workbook` | Leadership, analysts | Structured spreadsheet with all portfolio data | XLSX |
| Custom/ad-hoc | Any audience | User-defined voice, sections, review | Markdown |

Each use case defines its own voice, output templates, and review criteria. Both the `pitch` and `customer-narrative` use cases emit output with `arc_id` in frontmatter, making them directly consumable by story-to-slides, story-to-web, and story-to-storyboard — **no intermediate `/narrative` step needed.** `customer-narrative` is unique in that its arc varies per scope: `home` and `persona` use `jtbd-portfolio`, `about` uses `company-credo`, `capability` uses `corporate-visions`, `approach` uses `engagement-model`. See `references/templates-customer-narrative.md` for the full scope → arc mapping.

## Prerequisites

Verify the portfolio is sufficiently complete before generating:

```bash
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/validate-entities.sh" "<project-dir>"
bash "${CLAUDE_PLUGIN_ROOT:-$(ls -td "$HOME"/.claude/plugins/cache/insight-wave/cogni-portfolio/*/ | head -1)}/scripts/project-status.sh" "<project-dir>"
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
> - **Customer narratives (portfolio-driven website)** — Home, About, Capability, Persona, How-We-Work pages, each arc-structured and ready for `/story-to-web` (company speaks to buyer via web)
> - **Proposals** — per-proposition sales proposals for specific Feature × Market pairs
> - **Marketing briefs** — market content packages with sizing, buyer profile, messaging themes
> - **Portfolio workbook** — XLSX spreadsheet with all portfolio data for analysis
> - **Repository documentation** — README enrichment, plugin overviews, getting-started guides (project speaks to developer)
> - {any custom use cases from communicate-use-cases.json}
> - **Something else** — describe your purpose and I'll help shape the output

**If the user selects "something else"**, follow the ad-hoc flow (see [Ad-Hoc Use Cases](#ad-hoc-use-cases) below).

### Step 1: Determine Scope

Load the scope options from the selected use case (see registry). Only ask for clarification if genuinely ambiguous.

For **`customer-narrative`**: `home`, `about`, `capability` (which feature, or all customer-facing features?), `persona` (which market and persona?), `approach`, or `all`. **The legacy `overview` / `market` / `customer` scopes from v1 are deprecated** — map old requests forward: `overview` → `home`, `customer` → `persona`, and `market` is dropped (its content lives in `home.md`'s Who-We-Serve section and in persona pages).
For **`pitch`**: market (which one?), overview (portfolio-wide), or all.
For **`proposal`**: single (which proposition?), market (all propositions in a market), or all.
For **`market-brief`**: single (which market?), or all.
For **`workbook`**: full (all sheets), or matrix (proposition matrix only).
For **`repo-documentation`**: readme-enrichment, plugin-overview, use-case-gallery, or all.
For **custom/ad-hoc use cases**: use the scopes defined in the use case configuration.

If the request is vague, present the scope options from the selected use case.

### Step 1b: Arc Selection (pitch and customer-narrative use cases)

#### Customer-narrative: arcs are hardcoded per scope (no picker)

For `customer-narrative`, the arc is **an implementation detail of the scope** — it is not a user-facing choice. Do not present a picker. The mapping is:

| Scope | Arc | Rationale |
|---|---|---|
| `home` | `jtbd-portfolio` | Jobs → Friction → Portfolio → Invitation mirrors how buyers enter a website |
| `about` | `company-credo` | Mission → Conviction → Credibility → Promise answers "why should I trust this company" |
| `capability` | `corporate-visions` | Why Change → Why Now → Why You → Why Pay is the canonical capability-page arc |
| `persona` | `jtbd-portfolio` | Same shape as home, narrowed to one persona's jobs and friction |
| `approach` | `engagement-model` | Principles → Process → Partnership → Outcomes answers "how does this land in my organization" |

Load each scope's arc definition in Step 2 so the templates render with the correct element headers, word proportions, and phase-4b synthesis guidance. If the user tries to override with `--arc-id` for a customer-narrative scope, reject the override and explain the scope → arc mapping — these arcs are load-bearing for the website information architecture and the deduplication discipline that keeps pages from overlapping. (The `capability` scope is the one exception: `--arc-id corporate-visions` is the only valid override and is also the default, so effectively a no-op.)

#### Pitch: user picker

For the `pitch` use case (below) the arc is genuinely a user choice — present the picker.
### Step 1b (pitch use case only)

For the `pitch` use case, the output's `arc_id` controls which story structure cogni-narrative downstream tools render. The `templates-pitch.md` reference defines `jtbd-portfolio` as the standard default — its 1:1 job-to-solution mapping mirrors the portfolio's Feature × Market structure, and its verb-phrase jobs surface the buyer language that IS/DOES/MEANS already encodes. The user can still override.

**Always present this picker via AskUserQuestion before moving to Step 2** — do not silently apply a default, and do not improvise a different list. The picker must list `jtbd-portfolio` first so the documented default stays visible:

> "Welchen Story Arc soll der Pitch verwenden?" / "Which story arc should the pitch use?"
>
> - **JTBD Portfolio** (`jtbd-portfolio`) — *recommended default.* Jobs → Friction → Portfolio → Invitation. Best for portfolio introductions, capability overviews, and pre-sales positioning where buyers think in outcomes.
> - **Corporate Visions** (`corporate-visions`) — Why Change → Why Now → Why You → Why Pay. Best for B2B sales pitches, market-specific pitches, and executive briefings.
> - **Competitive Intelligence** (`competitive-intelligence`) — Landscape → Shifts → Positioning → Implications. Best for competitive positioning presentations.
> - **Industry Transformation** (`industry-transformation`) — Forces → Friction → Evolution → Leadership. Best for industry conferences and thought leadership.

If the user explicitly passed `--arc-id` on invocation, skip the picker and use that value. Still validate it against the four supported arcs above — reject unsupported arcs (`technology-futures`, `strategic-foresight`, `trend-panorama`, `theme-thesis`) with the explanation from `templates-pitch.md` that those arcs need cogni-trends or cogni-research input and portfolio data alone is usually insufficient.

Pass the chosen `arc_id` into Step 2 so `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md` is read for the right arc, and into Step 3 so the frontmatter and evidence mapping use the right arc elements.

Skip the pitch picker for non-pitch use cases (`proposal`, `market-brief`, `workbook`, `repo-documentation`, and ad-hoc/custom use cases) — they do not carry `arc_id`. `customer-narrative` is now arc-driven per scope as described above; its arcs are hardcoded and do not need a picker.

### Step 2: Load Entities

Read entity files from the project directory. Which entities to load depends on the use case and scope:

**All use cases:**
- `portfolio.json` for company context and language
- All `products/*.json`, `features/*.json`

**Customer-narrative (all scopes):**
- All `propositions/*.json` (filter by market or persona as the scope requires)
- All `solutions/*.json` and `packages/*.json` (if available)
- `markets/*.json` and `customers/*.json`
- `competitors/*.json` (for differentiation, reverse-engineered into convictions on `about.md`)
- `cogni-claims/claims.json` — verified facts for the `about.md` Credibility element
- Read the arc definition for the target scope from `cogni-narrative/skills/narrative/references/story-arc/{arc-id}/arc-definition.md` (use the scope → arc mapping from Step 1b)
- Read the matching phase-4b synthesis file from `cogni-narrative/skills/narrative/references/phase-workflows/phase-4b-synthesis-{arc-id}.md` for element-specific writing rules

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

**Customer-narrative: roadmap is exclusive to `home.md`.** Under the v2 customer-narrative model, the "On the roadmap" subsection appears in exactly one file — `home.md`. Persona pages, capability pages, the About page, and the Approach page do not emit roadmap content; instead they link to the Home page's roadmap section where relevant. This is deliberate: repeating the roadmap across 7+ files was the single biggest redundancy in the v1 output and the reason market-level pages read as redundant with persona pages. The templates-customer-narrative.md file enforces this discipline. Additionally, commitments in `home.md`'s Invitation and `about.md`'s Promise must not depend on `announce`-mode products — if they would, the commitment belongs on the Roadmap, not the invitation.

**Carrying the mode into the review loop.** Step 4 passes the mode (or the effective mode per section) to `communicate-review-assessor` so it can flag overclaims — present-tense language describing a concept-stage offering, or proposals generated against announce-mode propositions — as review failures instead of letting them slip through.

### Step 3: Generate Markdown

**Common rules (all use cases)**

**Messaging mode rule**: Every template consults the `messaging_mode` attached to each product/feature in Step 2 to decide voice, tense, section visibility and labels. See [Maturity-Aware Messaging](#maturity-aware-messaging) for the authoritative mapping and each template's "Handling messaging mode" block for how that template applies it. If any product in the loaded set is missing `maturity`, prepend the generated file (under the YAML frontmatter, above the first heading) with a single HTML comment of the form `<!-- notice: products without maturity fell back to standard mode: {slug1}, {slug2} -->` so the fallback is auditable without being visible to the end reader.

**Citation rule**: All templates require citations to link to **external source URLs** from entity `evidence[].source_url` fields. Never generate citations that link to internal JSON file paths (e.g., `propositions/x.json`). When an evidence claim has no external URL, present it as an inline estimate without a citation. See each template's Citations section for format details.

**Blueprint metadata is internal.** Solutions may carry `blueprint_ref` and `blueprint_version` fields — these track delivery pattern consistency and are used by the solutions skill for drift detection. Never expose blueprint metadata in customer-facing output (proposals, pitches, customer narratives). It is acceptable to reference the delivery structure itself (phases, timelines) since that comes from the solution content, but not the blueprint versioning mechanism.

**Output path:** Write to `output/communicate/{use-case-id}/` followed by the scope-specific filename from the template.

**Backward compatibility:** If old-format files exist at `output/communicate/portfolio-overview.md` (without use-case subdirectory), mention that the output structure has changed and that new files will be in `output/communicate/customer-narrative/`. Do not automatically migrate or delete old files.

#### Step 3 — customer-narrative (parallel agent dispatch)

Customer-narrative generation is delegated to the `customer-narrative-writer` agent. Each scope produces one or more files; each file is generated by one agent instance. The parent skill's job here is to build the dispatch list, launch all agents in parallel, and collect the results — not to generate content itself.

**Step 3a — Build the dispatch list.** Enumerate the files from the requested scope:

- `home` → 1 dispatch (arc: `jtbd-portfolio`)
- `about` → 1 dispatch (arc: `company-credo`)
- `approach` → 1 dispatch (arc: `engagement-model`)
- `capability` → N dispatches, one per customer-facing feature (arc: `corporate-visions`). Skip features with no propositions or empty `purpose` field. If a specific feature was requested, dispatch only that one.
- `persona` → M dispatches, one per `{market × persona}` pair where `customers/{market}.json` defines the persona (arc: `jtbd-portfolio`). If a specific market/persona was requested, dispatch only that one.
- `all` → union of the above (typically 14+ dispatches)

For each dispatch, prepare the agent payload:

| Field | Source |
|---|---|
| `project_dir` | Absolute path to the portfolio project root |
| `scope` | One of `home`, `about`, `capability`, `persona`, `approach` |
| `arc_id` | From the scope → arc map in Step 1b |
| `language` | From `portfolio.json` `language` field |
| `output_path` | Per the filename rules in `references/templates-customer-narrative.md` (e.g. `output/communicate/customer-narrative/capabilities/{feature-slug}.md`) |
| `entity_refs` | Object with paths/globs filtered to just what this scope needs — use the scope-specific data source rules from Step 2. For `capability`: just the one feature, its parent product, propositions targeting it, its competitors. For `persona`: just the one market+persona, propositions filtered by persona buying criteria, parent features and products. For `home` and `about`: broader entity sets as Step 2 specifies. |
| `messaging_modes` | Subset of the modes map computed in Step 2, filtered to the products and features relevant to this scope |
| `template_ref` | Absolute path to `references/templates-customer-narrative.md` plus the scope heading (e.g. `"Scope 3: \`capability\`"`) |
| `arc_definition_ref` | Absolute path to `cogni-narrative/skills/narrative/references/story-arc/{arc_id}/arc-definition.md` |
| `phase_4b_synthesis_ref` | Absolute path to `cogni-narrative/skills/narrative/references/phase-workflows/phase-4b-synthesis-{arc_id}.md` |
| `feature_slug` | Required iff `scope == capability` |
| `market_slug`, `persona_id` | Required iff `scope == persona` |

**Step 3b — Parallel dispatch.** Send ONE message containing all N `Agent` tool calls, each with `subagent_type: customer-narrative-writer`. All dispatches for a given invocation MUST be in a single message with parallel tool calls — serial dispatch defeats the purpose of the agent pattern. For single-scope requests (e.g. just `home`), this is still one dispatch via the agent for context hygiene.

**Step 3c — Collect and validate.** As each agent returns its JSON summary:

1. Parse `success`, `output_path`, `scope`, `word_count`, `dedup_flags`, and `messaging_modes_applied`.
2. If any dispatch returns `{ "success": false }`, log the error with its `phase` field. Do not abort other dispatches — partial success is valid and the review step handles it.
3. After all dispatches complete, write a dispatch manifest to `output/communicate/customer-narrative/_dispatch.json`:

```json
{
  "timestamp": "ISO 8601",
  "language": "en",
  "total_dispatched": 14,
  "total_succeeded": 14,
  "total_failed": 0,
  "files": [
    { "scope": "home", "arc_id": "jtbd-portfolio", "output_path": "…/home.md", "word_count": 1672, "success": true },
    { "scope": "capability", "arc_id": "corporate-visions", "output_path": "…/capabilities/feature-a.md", "word_count": 1650, "success": true }
  ],
  "failures": []
}
```

4. If `total_failed > 0`, surface the failures to the user before proceeding to Step 4. Let them decide whether to retry the failed scopes or continue with the successful files.

#### Step 3 — all other use cases (inline generation)

For non-customer-narrative use cases, generate content inline (no agent dispatch):

- `pitch` -> read `references/templates-pitch.md`
- `proposal` -> read `references/templates-proposal.md`
- `market-brief` -> read `references/templates-market-brief.md`
- `workbook` -> no template; prepare structured data and delegate to `document-skills:xlsx` skill (fallback to CSV)
- `repo-documentation` -> read `references/templates-repo-documentation.md`

For custom use cases, generate section structure based on the use case's `voice`, `scopes`, and `audience` fields — no separate template file is needed.

For ad-hoc use cases, use the parameters collected during the ad-hoc flow.

### Step 4: Stakeholder Review (Closed Loop)

After generating output, delegate to the `communicate-review-assessor` agent for quality assessment. The assessor adapts its perspectives based on the use case.

**Customer-narrative batch mode:** When Step 3 dispatched via `customer-narrative-writer` agents, read `output/communicate/customer-narrative/_dispatch.json` to determine which files were produced. Run the review loop per file — only review files with `success: true` in the manifest. Failed files were already surfaced to the user in Step 3c.

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
- **Score quality**: "Run `/narrative-review` on any generated file to score against its arc's quality gates (each file already carries `arc_id` in frontmatter)"
- **Polish prose**: "Run `/copywrite` on any generated file to polish for executive readability while preserving arc structure"
- **Visual formats** (direct — no intermediate `/narrative` step needed, because each file already carries `arc_id`):
  - `/story-to-web` → scrollable web page (one per file, or an indexed multi-page site)
  - `/story-to-slides` → PowerPoint version of any page
  - `/enrich-report` → themed HTML with concept diagrams (value flows, relationship maps) and interactive charts
- **Marketing content** (if cogni-marketing installed): "These customer narratives are automatically discovered by `/marketing-setup` and used as voice/messaging enrichment when generating marketing content — ensuring consistency between how the website speaks to buyers and how your marketing speaks to the same audience"

For **pitch**:
- **Score quality**: "Run `/narrative-review` to score against the arc's quality gates"
- **Polish prose**: "Run `/copywrite` to polish for executive readability while preserving arc structure"
- **Visual formats** (direct — no intermediate step needed):
  - `/story-to-slides` → PowerPoint presentation
  - `/story-to-web` → scrollable landing page
  - `/story-to-storyboard` → multi-poster print storyboard
  - `/enrich-report` → themed HTML with concept diagrams and data charts
- **Deepen**: "Run `/why-change` to add web research, customer-specific context, and TIPS enrichment for a deal-ready version"

For **proposal**:
- **Polish prose**: "Run `/copywrite` to polish for buyer readability"
- **Visual enrichment**: "Run `/enrich-report` on the proposal to add themed concept diagrams (value-flow diagrams, process-flow for implementation approach, relationship maps for solution dependencies) and interactive charts"
- **Share**: "Customize per prospect and share with sales team"

For **market-brief**:
- **Polish prose**: "Run `/copywrite` to polish"
- **Visual enrichment**: "Run `/enrich-report` to generate themed HTML with concept diagrams and market data charts"
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
- **`references/templates-customer-narrative.md`** — Templates for portfolio-driven website components (home, about, capability, persona, approach) — each with arc mapping and deduplication discipline
- **`references/templates-pitch.md`** — Templates for arc-structured pitch narratives (cogni-narrative compatible)
- **`references/templates-proposal.md`** — Templates for per-proposition sales proposals
- **`references/templates-market-brief.md`** — Templates for per-market marketing briefs
- **`references/templates-repo-documentation.md`** — Templates for developer-facing content (readme-enrichment, plugin-overview, use-case-gallery)

### Agents

- **`customer-narrative-writer`** — Generates a single customer-narrative markdown file for one scope (home, about, capability, persona, or approach). Reads arc definitions and portfolio entities, applies messaging-mode voice rules and dedup discipline, writes one arc-structured file. The parent dispatches N instances in parallel for fan-out. Model: sonnet.
- **`communicate-review-assessor`** — Use-case-aware stakeholder review for output quality. Adapts perspectives based on the use case: buyer/marketing/sales for customer narratives, developer/maintainer/writer for repo documentation, custom perspectives for ad-hoc use cases.
