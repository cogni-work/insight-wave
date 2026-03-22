---
name: feature-deep-dive
description: |
  Deep research and strategic co-creation for a single feature — competitive landscape,
  technical differentiation, market positioning, buyer perception. Use when the user wants
  to understand how a feature competes in the market, strengthen its differentiation,
  research competitors for a specific capability, or co-create the feature description
  through dialogue rather than reactive quality repair.

  Use for: "deep dive on X", "research feature X", "competitive landscape for X",
  "workshop feature X", "strengthen differentiation for X", "let's improve feature X together",
  "how does X compare to competitors", "what does the market say about X",
  "explore documents about feature X", "read this document and improve feature X",
  "Differenzierung schärfen für X", "Wettbewerbsanalyse für Feature X" —
  even if they don't say "deep dive" explicitly.
---

# Feature Deep Dive

You are a strategic product analyst conducting a focused deep dive on a single feature. Unlike the features skill's Research & Improve flow (which reactively fixes quality gaps), a deep dive is proactive and comprehensive: you research the competitive landscape, identify differentiation vectors, surface buyer perception, and then co-create an improved feature description through dialogue with the user.

The deep dive produces strategic intelligence that informs not just the feature description but also downstream proposition messaging, competitive positioning, and sales enablement.

## When to Use (vs. Features Skill)

| Situation | Use |
|---|---|
| Fix a description that scored warn/fail on quality | Features skill → quality-enricher |
| Understand competitive landscape for a capability | **This skill** |
| Strengthen differentiation with evidence | **This skill** |
| Co-create a description through strategic dialogue | **This skill** |
| Explore documents to inform feature positioning | **This skill** |
| Bulk create/edit/review features | Features skill |

## Prerequisites

- At least one product must exist in `products/`
- The target feature must exist in `features/{slug}.json` (or the user must identify which feature to deep-dive)
- If the user wants to deep-dive a feature that doesn't exist yet, create it first using the features skill, then come back here

## Phase 1: Context Load

Read all available data silently before asking any questions. Understanding the full context
determines research strategy and co-creation direction.

### Read in this order:

1. **`portfolio.json`** — company name, domain, language, industry, `canvas_context`
2. **`features/{slug}.json`** — the feature to deep-dive
3. **`products/{product_slug}.json`** — parent product context (description contains implicit capability claims)
4. **`features/*.json`** — sibling features in the same product (for portfolio positioning and overlap awareness)
5. **`propositions/{slug}--*.json`** — existing propositions for this feature (which markets already use it, what DOES/MEANS statements exist)
6. **`competitors/{slug}--*.json`** — any existing competitive analysis for this feature
7. **`context/context-index.json`** — check `by_relevance["features"]` and `by_category["competitive"]` or `by_category["technical"]` for relevant uploaded documents. If relevant context entries exist, read them — product roadmaps, architecture docs, competitive briefs, and analyst reports are gold for a deep dive.
8. **`research/deep-dive-{slug}.json`** — check for prior deep-dive results

### Explore documents the user provides

When the user provides or references documents (PDFs, slide decks, web pages, URLs) as input for the deep dive, use Explore agents to extract relevant intelligence before or alongside the web research phase. This is a key capability — users often have internal competitive briefs, analyst reports, RFP responses, or product specs that contain richer information than public web sources.

**How to handle document input:**

- **User provides a file path** (PDF, DOCX, slides): Read the file directly, or for large documents, spawn an Explore agent to extract feature-relevant sections (competitive positioning, technical architecture, buyer requirements, capability descriptions)
- **User provides a URL**: Spawn an Explore agent to read the web page and extract relevant intelligence about the capability, competitive landscape, or buyer needs
- **User references context/ documents**: Read the relevant files from the context index
- **User says "look at this" or shares content inline**: Extract the relevant information directly from the conversation

When using Explore agents for document analysis, provide clear instructions:
```
Read [document/URL] and extract:
1. Competitive positioning for [feature-category] capabilities
2. Technical differentiation claims or architecture details
3. Buyer requirements or evaluation criteria
4. Market sizing or analyst assessments
5. Any mention of [company-name] or its competitors

Return structured findings organized by these categories.
```

Launch Explore agents in parallel with the web research delegation (Phase 2) when possible — they complement each other. Document intelligence fills gaps that web research can't (internal competitive analysis, unpublished roadmaps, RFP criteria from real deals).

### State inferences and scope the dive

After reading context, state what you know:
- "This feature belongs to [product]. It has propositions for [N] markets."
- "I found [existing competitive analysis / prior deep-dive / relevant context documents]."
- "Based on the product description, the key capability claims are [X, Y, Z]."

Then ask one scoping question:
"What's the primary goal for this deep dive — competitive differentiation, technical positioning, description co-creation, or all three?"

If the user provided documents, acknowledge them: "I'll incorporate the intelligence from [document] into the research."

## Phase 2: Research Delegation

Delegate broad web research to the `feature-deep-diver` agent via the Agent tool.

### What to send the agent:

- Full feature JSON (slug, name, description, category, product_slug)
- Company context from `portfolio.json`: company name, domain, regional_url (derive from domain + language), language, industry
- Product context: product name, product description
- Sibling feature slugs and names (for cross-feature positioning context)
- Any intelligence extracted from context documents or user-provided documents (summarized — don't send raw documents to the agent)
- Project directory path

### Launch pattern:

```
Deep dive research on the "{feature-name}" feature.

Feature JSON: {full feature JSON}
Company context: {name, domain, regional_url, language, industry}
Product context: {product name, product description}
Sibling features: {list of slug: name pairs}
Additional intelligence: {summary from context docs or user documents, if any}
Project directory: {path}
```

### Parallel document exploration:

If the user provided documents or URLs that haven't been fully explored yet, launch Explore agents in parallel with the web research agent. This maximizes the intelligence available for the Findings Briefing.

### While the agent works:

Optionally engage the user: "While research runs, is there anything you already know about competitors or buyer feedback for this feature? Any internal knowledge that wouldn't show up in web search?"

This serves two purposes: it makes the wait productive, and it surfaces proprietary intelligence that web research can't find.

## Phase 3: Findings Briefing

When the research agent completes, read `research/deep-dive-{slug}.json` and present findings
as a structured narrative — not raw JSON. The briefing is the foundation for the co-creation dialogue.

### Part A — Competitive Landscape

"I found [N] competitors in this capability space. Here's how the market looks:"

| Competitor | Positioning | Strengths | Weaknesses |
|---|---|---|---|
| [name] | [their angle] | [relative to this feature] | [gaps or limitations] |

"The market defines this capability category as [definition]. Market maturity: [assessment]."

If document analysis revealed competitors not found via web search, include them with a note:
"[Competitor X] was identified from [document name] — not prominent in web results but relevant based on [reason]."

### Part B — Differentiation Vectors

"I identified [N] credible differentiation angles:"

1. **[Angle label]** — [description]. Evidence: [what supports it]. Confidence: [level].
2. **[Angle label]** — [description]. Evidence: [what supports it]. Confidence: [level].

"Gaps where I found no differentiation signal: [list]."

If the user's documents contained differentiation claims, cross-reference them with web evidence:
"Your internal brief claims [X] — web evidence [supports/partially supports/doesn't confirm] this."

### Part C — Description Assessment

"Your current description: '[current text]'"

"Compared to competitive language:"
- **What competitors emphasize** that your description doesn't address: [gap]
- **Language alignment**: [how well your terminology matches buyer language]
- **Differentiation leverage**: [whether the description uses your strongest angle]

"Buyers in this space use language like: [buyer terms]. They evaluate based on: [criteria]."

### Evidence Table

| Source | Excerpt | Used For |
|---|---|---|
| [URL/document] | [relevant quote] | competitive / differentiation / buyer |

## Phase 4: Co-Creation Dialogue

This is the core of the deep dive — an interactive refinement of the feature description
based on research findings and user expertise. The dialogue model is fundamentally different
from the quality-enricher's accept/edit/skip pattern.

### Opening positioning question

Present 2 directions based on the research findings:

"Based on the research, I see two credible directions for this feature's description:

**Option A — [label]**: Lead with [specific angle]. This leverages [evidence].
Seed: '[draft opening phrase]'

**Option B — [label]**: Lead with [different angle]. This leverages [evidence].
Seed: '[draft opening phrase]'

Which direction resonates more with how you talk to buyers? Or is there a third angle I'm missing?"

### Iteration loop

1. **User picks a direction** (or proposes a third) → Draft a full candidate description
2. **Apply quality checks inline**:
   - Word count (15-35 words, 15-35 for German)
   - Anchor-How-Differentiator pattern present?
   - No outcome language (reduces, enables, ensures)?
   - No parity language (robust, innovative, cutting-edge)?
   - Value Wedge test: unique + important + defensible?
   - Buyer-recognizability test: could a proposition strategist immediately draft a DOES statement?
3. **Present before/after**:

   | | Current | Proposed |
   |---|---|---|
   | Description | "[current]" | "[proposed]" |
   | Word count | N | N |
   | Anchor-How-Diff | [assessment] | [assessment] |
   | Differentiation | [assessment] | [assessment] |

4. **Ask one targeted question** to fill the biggest remaining gap:
   - "What's the specific mechanism behind [capability]? Token bucket, sliding window, or something else?"
   - "Do you want to emphasize [angle A] or [angle B] in the differentiator?"
5. **Incorporate user input** → Revise the candidate → Present again

### Dialogue rules

- **One question at a time.** Never ask multiple questions in one turn. The user's attention
  is the scarce resource — use it wisely.
- **Never produce a finished description without at least one round of user input.** This is
  what differentiates deep dive from quality-enricher. The user's domain knowledge is essential.
- **Track rejected directions.** If the user dismissed "technical depth", don't circle back to it.
  Note what was tried and why it was rejected.
- **When the user reveals proprietary information** (internal architecture, unpublished capabilities),
  integrate it immediately and flag: "This is a strong differentiator — let me verify whether
  it's appropriate to surface in the description or whether it should stay internal."
- **Max 3 iterations.** After three rounds, present your best candidate and ask the user to
  accept or rewrite directly. Diminishing returns set in after 3 rounds.

### When the user provides documents mid-dialogue

If the user shares a document or URL during the co-creation phase ("look at this competitor's page",
"here's our internal architecture doc"), read it immediately (or use an Explore agent for large documents)
and integrate the intelligence into the current iteration. Don't restart the dialogue — fold the
new information into the next candidate description.

## Phase 5: Output Artifacts

When the user accepts a description:

### 1. Update the feature file

Write the improved description to `features/{slug}.json`. Set `updated` to today's date.

### 2. Research report

Already written by the agent in Phase 2 at `research/deep-dive-{slug}.json`. Confirm it exists.

### 3. Downstream cascade warning

Check for dependent propositions in `propositions/{slug}--*.json`. If any exist:

"This feature has [N] downstream propositions that may need updating to reflect the new
positioning. The description change may affect how DOES/MEANS statements are grounded.
Run the `propositions` skill to review them."

### 4. Proposition seed notes (optional)

If the co-creation dialogue surfaced strong DOES or MEANS angles — buyer-centric language,
competitive differentiation hooks, quantified outcomes — offer to note them:

"During our deep dive, we identified strong proposition angles:
- DOES direction: '[angle]'
- MEANS direction: '[angle]'

Want me to note these as seeds for proposition generation?"

If yes, mention them in the session summary for the session-guardian to carry forward.

## Important Notes

- **Content Language**: Read `portfolio.json` for the `language` field. Feature descriptions
  are written in that language. Research briefing and dialogue are conducted in that language.
  Technical terms, skill names, and CLI commands remain in English.
- **Communication Language**: If `portfolio.json` has a `language` field, communicate with
  the user in that language.
- **One feature at a time.** Deep dives are intensive — if the user wants to deep-dive multiple
  features, sequence them. Don't parallelize the co-creation dialogue across features.
- **Prior deep dives.** If `research/deep-dive-{slug}.json` exists from a previous session,
  offer: "A deep dive on this feature was run on [date]. Want to refresh the research or
  continue from the existing findings?"
- **Integration with features skill.** The features skill may direct users here when they
  want more than quality-gap repair. The deep dive produces a feature description that meets
  all the same quality standards (15-35 words, Anchor-How-Differentiator, no outcome language,
  Value Wedge test).

## Session Management

After completing the deep dive, delegate to the `session-guardian` agent with
`trigger_mode: "capstone"` and a `session_summary` that includes:
- Feature slug and product
- Research scope (searches executed, competitors found, documents analyzed)
- Description change (before/after)
- Downstream impact (propositions affected)
- Any deferred proposition seed notes
