---
name: wiki-query
description: "Answer a question by reading the Karpathy-style wiki — never from memory. Claude consults wiki/index.md first, then reads the relevant wiki/pages/*.md files, synthesizes an answer with [[wikilink]] citations, and optionally files the answer back as a new wiki page so the knowledge compounds. Use this skill whenever the user says 'query the wiki', 'ask the wiki', 'what do I know about X', 'what does my wiki say about Y', 'wiki query', 'search the wiki for Z', or asks any question after setting up a wiki and expects Claude to reason from it. Also trigger when the user asks a question that clearly lives inside their wiki's domain (e.g. they have an AI-safety wiki and ask about CAI) — offer the wiki as the source of truth."
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# Wiki Query

Answer a question using only what is written in the wiki. Never draw on model memory. Every claim in the answer must trace to a specific wiki page, which in turn traces to a raw source. After answering, optionally persist the synthesis as a new wiki page so the next query benefits.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start of the session to re-anchor on the compounding principle.

## When to run

- User asks a question and references "the wiki" or "my notes"
- User asks a question that clearly lives in a wiki's domain (after checking `.cogni-wiki/config.json` describes that domain)
- User says "wiki query", "ask the wiki", "what do I know about X"
- User is in the middle of another skill and needs to consult existing knowledge

## Never run when

- No wiki exists in the current directory or any ancestor — offer `wiki-setup`
- The question is about a topic the wiki has never ingested a source for — report honestly that the wiki is silent, do NOT fabricate an answer

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

If `--file-back auto`, ask the user: "File this answer as a new wiki page?" If yes, pass control to the file-back step below. If `--file-back yes`, do it without asking. If `no`, stop here after step 4.

### 6. File-back (optional)

If filing the answer back:

1. Choose a slug derived from the question or the synthesized claim
2. Write a new page at `wiki/pages/{slug}.md` with `type: learning` (or `summary` if the answer is mostly one source)
3. Frontmatter `sources:` field lists the wiki pages used, prefixed with `wiki://` to distinguish from raw sources:
   ```yaml
   sources:
     - wiki://constitutional-ai
     - wiki://anthropic-safety-team
   ```
   This is explicit: the learning is a derived synthesis, not a direct restatement of a raw source.
4. Body is the synthesized answer with the `[[citations]]` preserved
5. Update `wiki/index.md` under an appropriate category
6. Append to `wiki/log.md`:
   ```
   ## [YYYY-MM-DD] query | {slug} — {short question}
   ```
7. Increment `entries_count` in `.cogni-wiki/config.json`
8. (Optional) Run `backlink_audit.py` from wiki-ingest on the new page to add bidirectional links

### 7. Always append to the log (even without filing back)

Regardless of file-back decision, append a query log line:

```
## [YYYY-MM-DD] query | "{short question}" → read {N} pages
```

The log records every query so the user can see what the wiki has been asked.

## Output

- An answer with inline `[[citations]]`
- Optionally: a new `wiki/pages/{slug}.md` learning page
- An appended line in `wiki/log.md` (always)
- Optionally: updated index, config, and backlinks (if file-back was yes)

## Golden rules

1. **Never answer from memory.** If the wiki does not contain a claim, the answer does not contain that claim.
2. **Every factual sentence is `[[cited]]`.** Rhetoric and connective text can go uncited; claims cannot.
3. **Contradictions are surfaced, not reconciled.** Only `wiki-update` resolves contradictions; `wiki-query` reports them.
4. **Thin coverage is declared.** If the wiki has one page on a topic, say so — don't pretend to a consensus.
5. **Always log.** Every query leaves a trail, filed-back or not.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the pattern
- `./references/query-patterns.md` — read-before-answer worked example
