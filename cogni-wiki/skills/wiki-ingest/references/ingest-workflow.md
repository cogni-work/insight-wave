# Ingest Workflow — Worked Example

A concrete walkthrough of the ingest workflow using a realistic source. Read this when the abstract steps in `SKILL.md` are not enough — it shows exactly what "surface key takeaways before writing" looks like in practice.

## Scenario

The user has a fresh wiki at `cogni-wiki/ai-research/` with three pages already:

- `wiki/pages/rlhf-limitations.md`
- `wiki/pages/anthropic-safety-team.md`
- `wiki/pages/constitutional-ai.md`

They drop a new paper at `raw/bai-et-al-2022-constitutional-ai.pdf` and ask Claude to ingest it.

## Step 1: Locate the wiki

From the current working directory, walk upward looking for `.cogni-wiki/config.json`. Found at `cogni-wiki/ai-research/`. The working wiki root is set.

## Step 2: Read the source

The Read tool is used to extract the PDF text. For long papers, read the abstract, introduction, method, and conclusion sections first — the middle is only needed if a takeaway is unclear.

## Step 3: Surface takeaways BEFORE writing

Emit, in the response to the user:

> **Source**: Bai et al. (2022), *Constitutional AI: Harmlessness from AI Feedback* — Anthropic technical paper, 34 pages.
>
> **Key takeaways:**
> 1. Constitutional AI replaces RLHF's human harm labels with AI-generated critiques against a written constitution of principles.
> 2. The method has two phases: supervised learning from self-critiques, then RL from AI-generated preference labels.
> 3. The constitution is a short list of natural-language principles the model references during critique.
> 4. CAI models are rated less harmful **and** more helpful than RLHF baselines in head-to-head evals.
> 5. The technique scales with model size — larger critics produce better training signal.
>
> **Existing pages this touches:**
> - `[[constitutional-ai]]` — currently a stub with just a definition; this source will flesh it out substantially.
> - `[[rlhf-limitations]]` — should gain a forward reference to CAI as a concrete alternative.
> - `[[anthropic-safety-team]]` — should mention Bai et al. as a flagship publication.
>
> **Proposed page**: Since `constitutional-ai.md` already exists, the right operation is actually `wiki-update` on that page, not a new ingest. Shall I proceed with an update that uses this paper as the primary source?

This is the critical moment: the takeaway synthesis caught a duplication risk. Without it, Claude would have created `bai-et-al-2022-constitutional-ai.md` next to `constitutional-ai.md` and the wiki would have fragmented.

## Step 3b: The user confirms update-not-ingest

The user says "yes, update the concept page." Control passes to `wiki-update`. `wiki-ingest` stops cleanly.

## Alternative flow: the source is genuinely new

Suppose instead the source was Bai et al. 2024 on *Many-Shot Jailbreaking* — a topic with no existing page.

### Step 4: Write the new page

Path: `<wiki-root>/wiki/pages/many-shot-jailbreaking.md`

```markdown
---
id: many-shot-jailbreaking
title: Many-Shot Jailbreaking
type: summary
tags: [llms, safety, jailbreaking, long-context]
created: 2026-04-12
updated: 2026-04-12
sources:
  - ../raw/bai-et-al-2024-many-shot-jailbreaking.pdf
---

Many-shot jailbreaking exploits long context windows by stuffing hundreds of fake dialogue turns that prime the model toward a harmful completion.

## Key takeaways

- The attack effectiveness follows a power law in the number of shots — roughly log-linear up to 256 shots [[long-context-vulnerabilities]].
- Larger models are *more* vulnerable, not less, because they generalize the fake-dialogue pattern more faithfully.
- Mitigations that work: fine-tuning against the attack, in-context classifier filtering, and prompt shields — none are complete.
- The attack generalizes across harmful task categories (violence, fraud, biological), which means per-category mitigations don't compose.

## Details

### Setup
...

### Scaling behavior
...

### Mitigations
...

## Sources

- [Bai et al. 2024 — Many-Shot Jailbreaking](../raw/bai-et-al-2024-many-shot-jailbreaking.pdf)
```

### Step 5: Update `wiki/index.md`

Under the `## Safety` category heading, insert:

```
- [[many-shot-jailbreaking]] — Exploiting long context by stuffing fake dialogue turns to prime harmful completions.
```

### Step 6: Backlink audit

Run `backlink_audit.py --wiki-root cogni-wiki/ai-research --new-page many-shot-jailbreaking`. The script returns:

```json
{
  "success": true,
  "data": {
    "candidates": [
      { "page": "rlhf-limitations", "matched_terms": ["jailbreaking"], "confidence": "medium" },
      { "page": "long-context-vulnerabilities", "matched_terms": ["long context", "context window"], "confidence": "high" }
    ]
  }
}
```

For `long-context-vulnerabilities`, add an inline `[[many-shot-jailbreaking]]` link in the body text where the page already discusses attack classes — not in a dangling "See also" list. Update that page's `updated:` field.

For `rlhf-limitations`, skip — the match was shallow and forcing a backlink would be noise.

### Step 7–9: Log, config, report

```
## [2026-04-12] ingest | many-shot-jailbreaking — Many-Shot Jailbreaking
```

Increment `entries_count` in `.cogni-wiki/config.json`. Report: "Ingested as `many-shot-jailbreaking`. Added one backlink from `long-context-vulnerabilities`. `wiki-query` can now reason over this source."

## Anti-patterns (do not do these)

- **Write the page first, then "figure out" takeaways.** Always reverse the order.
- **Create a new page for every source.** If a concept page already exists, update it instead.
- **Add backlinks to every page that matches a keyword.** Force-linking degrades the signal — only add backlinks that a reader of the target page would genuinely benefit from.
- **Rewrite the index silently.** The index is edited in-place; never regenerated from scratch (which would destroy human-added organization).
- **Summarize from memory.** If the source says "X", the page says "X". If the source is silent on Y, the page is silent on Y.

## Mode flag: fresh vs re-ingest

`wiki-ingest` exposes one conceptual parameter that does not appear on the command line: `mode`. Step 1 detects it from the filesystem — if a page already exists at the target slug, `mode` is `re-ingest`; otherwise `fresh`. The flag is internal and never surfaces in frontmatter or config.

Pick the right entry point:

- **`wiki-update`** — the page exists and you want to preserve the existing synthesis (fix a claim, add a source, tweak wording).
- **`wiki-ingest` (→ re-ingest branch)** — the page exists but the underlying source has changed substantively and the page should be re-synthesised from scratch. This is the pilot-rebuild pattern from PR #67.
- **`wiki-ingest` (→ fresh branch)** — no page at the target slug.

Step 1 emits a verbatim warning on re-ingest that points users back at `wiki-update` for content-only tweaks; the two paths stay distinct even though they share the same skill entry point.
