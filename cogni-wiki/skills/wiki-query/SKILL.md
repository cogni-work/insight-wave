---
name: wiki-query
description: "Answer a question by reading the Karpathy-style wiki — never from memory. Claude consults wiki/index.md first, then reads the relevant wiki/pages/*.md files, synthesizes an answer with [[wikilink]] citations, and optionally files the answer back as a `type: synthesis` page so the knowledge compounds. Use this skill whenever the user says 'query the wiki', 'ask the wiki', 'what do I know about X', 'what does my wiki say about Y', 'wiki query', 'search the wiki for Z', or asks any question after setting up a wiki and expects Claude to reason from it. Also trigger when the user asks 'look up X in the wiki', 'check the wiki for X', or asks a question that clearly lives inside their wiki's domain (e.g. they have an AI-safety wiki and ask about CAI) — offer the wiki as the source of truth."
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# Wiki Query

Answer a question using only what is written in the wiki. Never draw on model memory. Every claim in the answer must trace to a specific wiki page, which in turn traces to a raw source. After answering, optionally persist the synthesis as a new `type: synthesis` wiki page so the next query benefits.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start of the session to re-anchor on the compounding principle.

## When to run

- User asks a question and references "the wiki" or "my notes"
- User asks a question that clearly lives in a wiki's domain (after checking `.cogni-wiki/config.json` describes that domain)
- User says "wiki query", "ask the wiki", "what do I know about X"
- User is in the middle of another skill and needs to consult existing knowledge

## Never run when

- No wiki exists in the current directory or any ancestor — offer `wiki-setup`
- The question is about a topic the wiki has never ingested a source for — report honestly that the wiki is silent; the user's trust depends on answers being grounded exclusively in wiki content

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--question` | Yes | The user's question, as a plain string |
| `--file-back` | No | `auto` (default — ask the user) / `yes` / `no` — whether to save the answer as a new wiki page |
| `--max-pages` | No | Cap on how many pages to read (default 12). Prevents runaway reads on large wikis. |

## Workflow

### 1. Locate the wiki and read the index

Walk upward to find `.cogni-wiki/config.json`. Read `wiki/index.md` top to bottom. The index is the map — do not skip it.

### 2. Select candidate pages

From the index, select pages whose one-line summary is relevant to the question. If fewer than 2 clear matches, also:

- Run `grep -l -i` over `wiki/pages/` for the question's key nouns
- Cap the total set at `--max-pages`

If zero candidate pages emerge after both passes, stop and report: "The wiki has no pages on this topic. Run `wiki-ingest` on a source first, or rephrase the question." Do not answer from memory.

### 3. Read the selected pages

Read each candidate page fully. Note:
- The claims that directly answer the question
- The sources each claim traces to
- Any contradictions between pages (flag for `wiki-lint` if you find one)

### 4. Synthesize the answer

Write a plain-prose answer, inline-citing every factual claim with a `[[page-slug]]` link. Example:

> Constitutional AI replaces human harm labels with AI-generated critiques against a written constitution [[constitutional-ai]]. The method scales with critic-model size [[constitutional-ai]] and was introduced by Bai et al. in 2022 [[anthropic-safety-team]].

Rules:
- Every non-trivial claim links to at least one `[[page]]`
- If two pages contradict each other, surface the contradiction explicitly ("`[[page-a]]` claims X, but `[[page-b]]` claims Y — these should be reconciled via `wiki-update` or flagged via `wiki-lint`")
- If the wiki's coverage is thin, say so: "Based on two pages, both summarizing one 2022 paper, the wiki's view is..."

### 5. Offer to file the answer back

If `--file-back auto`, ask the user: "File this answer as a new `type: synthesis` page?" If yes, pass control to the file-back step below. If `--file-back yes`, do it without asking. If `no`, stop here after step 4.

### 6. File-back (optional)

If filing the answer back:

1. Choose a slug derived from the question or the synthesized claim
2. Write a new page at `wiki/pages/{slug}.md` with `type: synthesis` — the page type for LLM-derived answers built from other wiki pages, introduced in cogni-wiki v0.0.23. (Use `--type learning` only if the user explicitly asks to file the answer as a human-curated takeaway, or `--type summary` if the result is essentially a near-restatement of one source-derived page.)
3. Frontmatter `sources:` field lists the wiki pages used, prefixed with `wiki://` to distinguish from raw sources:
   ```yaml
   sources:
     - wiki://constitutional-ai
     - wiki://anthropic-safety-team
   ```
   This is explicit: the synthesis is a derived wiki→wiki claim, not a new raw assertion. `wiki-lint` validates that each `wiki://<slug>` target exists (broken_wiki_source error) and warns if a `type: synthesis` page has no `wiki://` source (synthesis_no_wiki_source warn).
4. Body is the synthesized answer with the `[[citations]]` preserved
5. Update `wiki/index.md` under an appropriate category (typically a new "Syntheses" section, or under the topic the synthesis covers)
6. Append to `wiki/log.md`:
   ```
   ## [YYYY-MM-DD] synthesis | {slug} — {short question}
   ```
   The `synthesis` operation prefix (introduced in v0.0.23) distinguishes filed-back query answers from un-filed queries — Step 7 still uses `query` for the always-on log line. `wiki-resume` and `wiki-dashboard` count the two distinctly via `synthesis_count_30d` and `query_count_30d`.
7. Increment `entries_count` in `.cogni-wiki/config.json` via `cogni-wiki/skills/wiki-ingest/scripts/config_bump.py --key entries_count --delta 1` (the locked, atomic helper used by `wiki-ingest`)
8. (Optional) Run `backlink_audit.py` from wiki-ingest on the new page to add bidirectional links

### 7. Always append to the log (even without filing back)

Regardless of file-back decision, append a query log line:

```
## [YYYY-MM-DD] query | "{short question}" → read {N} pages
```

The log records every query so the user can see what the wiki has been asked. When the answer was also filed back, both the `query` line (Step 7) and the `synthesis` line (Step 6.6) are present — the first is the question, the second is the page that captures the answer.

## Output

- An answer with inline `[[citations]]`
- Optionally: a new `wiki/pages/{slug}.md` with `type: synthesis`
- An appended `query` line in `wiki/log.md` (always)
- Optionally: a `synthesis` line in `wiki/log.md`, updated index, bumped config, and applied backlinks (if file-back was yes)

## Golden rules

1. **Answer only from wiki content.** The user chose a wiki precisely because they want answers grounded in curated sources, not in training data that may be stale or wrong. If the wiki does not contain a claim, the answer does not contain that claim.
2. **Every factual sentence is `[[cited]]`.** Rhetoric and connective text can go uncited; claims cannot.
3. **Contradictions are surfaced, not reconciled.** Only `wiki-update` resolves contradictions; `wiki-query` reports them.
4. **Thin coverage is declared.** If the wiki has one page on a topic, say so — don't pretend to a consensus.
5. **Always log.** Every query leaves a trail, filed-back or not.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/query-patterns.md` — read-before-answer worked example, including a synthesis file-back walkthrough
