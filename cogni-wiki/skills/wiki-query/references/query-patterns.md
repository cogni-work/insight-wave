# Query Patterns

Read-before-answer discipline, worked examples, and a short catalog of query shapes the skill should handle cleanly.

## The golden discipline: read before you answer

Claude's default instinct is to answer from internal knowledge. This skill must override that instinct on every invocation. The rule:

1. Read `wiki/index.md` first — **always**, even for questions you're certain you know the answer to.
2. Read at least one page if the question has any overlap with a page summary — **always**.
3. Only when both the index and the selected pages are silent on a topic is it acceptable to report that the wiki does not contain the answer.
4. Never supplement a wiki-sourced answer with memory-sourced claims. If the wiki has 70% of the answer, report that 70% and stop — do not "fill in" the other 30% from training data.

The user's trust in the wiki depends on this discipline. One memory-sourced claim breaks the contract and the wiki becomes untrustworthy.

## Query shapes

### Shape 1: direct lookup

> "What does the wiki say about Constitutional AI?"

Workflow: read index → match `[[constitutional-ai]]` → read that page → summarize its body with `[[citations]]`.

Output structure: one paragraph synthesis, then a "Sources in the wiki" section listing the pages read.

### Shape 2: synthesis across pages

> "How does the wiki's view of RLHF compare with its view of CAI?"

Workflow: read index → identify `[[rlhf-limitations]]`, `[[constitutional-ai]]`, `[[rlhf-overview]]` → read all three → write a structured comparison (two-column prose or table) → cite each claim.

Output structure: comparison table or prose, with `[[links]]` on every row or sentence.

### Shape 3: "what do I know about X"

> "What do I know about jailbreaking?"

Workflow: read index → `grep` `wiki/pages/` for "jailbreak" → read all matching pages → summarize the wiki's overall position, noting gaps.

Output structure: 3-5 bullet claims with `[[citations]]`, then an explicit "Gaps" section naming what the wiki does not cover.

### Shape 4: "does the wiki have anything on Y"

> "Does my wiki have anything on many-shot jailbreaking?"

Workflow: read index → `grep` for "many-shot" in pages → if hits, read and summarize; if none, say so without hallucinating.

Output structure: one sentence ("Yes — one page" / "No — nothing") followed by the summary or a suggestion to ingest a source.

### Shape 5: decision recall

> "Why did we decide to use Pinecone?"

Workflow: read index → look for `type: decision` pages → find the matching decision → read it in full → report the reasoning and the alternatives considered, exactly as the page records them.

Output structure: "**Decision:** ... **Reasoning:** ... **Alternatives considered:** ..." — preserving the decision-page structure.

### Shape 6: contradiction detection

> "Is X true?"

Workflow: read index → read all pages that mention X → if they agree, cite and answer; if they disagree, surface the disagreement and stop.

Output structure:
> The wiki contains two conflicting claims:
> - `[[page-a]]` says X is true because ...
> - `[[page-b]]` says X is false because ...
> These should be reconciled via `wiki-update` or flagged in the next `wiki-lint` run.

## File-back heuristics

File the answer back as a new `type: synthesis` page when:

- The synthesis combined ≥2 pages into a novel claim
- The user is likely to ask this question again
- The answer introduces a generalization or takeaway not captured on any single page

Do NOT file back when:

- The answer is a direct restatement of a single page (already in the wiki)
- The answer is a one-off navigation question ("which page mentions X?")
- The answer explicitly reports an absence ("the wiki is silent on Y")

## Worked example: filing a Shape-2 synthesis back

**User:** `/cogni-wiki:wiki-query --question "how do RLHF and Constitutional AI differ?" --file-back yes`

**Step 1–4** — Claude reads `wiki/index.md`, picks `[[rlhf-overview]]`, `[[rlhf-limitations]]`, and `[[constitutional-ai]]`, reads them, and writes the synthesis with `[[citations]]` on every claim.

**Step 6 file-back** — because `--file-back yes` is set, Claude derives the slug `rlhf-vs-cai-comparison` from the question and writes:

```yaml
---
id: rlhf-vs-cai-comparison
title: RLHF vs Constitutional AI — wiki view
type: synthesis
tags: [llms, alignment, comparison]
created: 2026-05-05
updated: 2026-05-05
sources:
  - wiki://rlhf-overview
  - wiki://rlhf-limitations
  - wiki://constitutional-ai
---

## Headline

RLHF uses human-labelled harm preferences as the supervision signal; Constitutional AI replaces those labels with AI-generated critiques against a written constitution [[constitutional-ai]] [[rlhf-overview]].

## Comparison

| Dimension | RLHF | Constitutional AI |
|-----------|------|-------------------|
| Supervision source | Human raters [[rlhf-overview]] | Written constitution + critic LLM [[constitutional-ai]] |
| Scaling pressure | Hires/throughput of human labellers [[rlhf-limitations]] | Critic-model capability [[constitutional-ai]] |

## Sources in the wiki

- [[rlhf-overview]]
- [[rlhf-limitations]]
- [[constitutional-ai]]
```

**Steps 5–7** — the page is added to `wiki/index.md` under a Syntheses section, two log lines are appended (`synthesis | rlhf-vs-cai-comparison — ...` and `query | "how do RLHF and CAI differ?" → read 3 pages`), and `entries_count` is bumped via `config_bump.py`.

Next time the user asks the same question, `wiki-query` will hit `[[rlhf-vs-cai-comparison]]` directly via the index instead of re-reading the three source pages — the exploration has compounded.

## What the answer must always contain

- A one-sentence headline conclusion
- A short body with `[[citations]]` on every claim
- A "Sources in the wiki" footer listing the page slugs read
- An explicit "Gaps" note if coverage is thin or contradictory
