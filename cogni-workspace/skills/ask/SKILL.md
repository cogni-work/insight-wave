---
name: ask
description: >-
  Answer a question about the insight-wave plugin ecosystem by reading the
  bundled insight-wave wiki — never from memory. The wiki ships with cogni-workspace
  and lives at ${CLAUDE_PLUGIN_ROOT}/wiki/. Reads wiki/wiki/index.md first to
  find relevant pages, then reads only those pages, then synthesizes a grounded
  answer with [[wikilink]] citations. Use this skill whenever the user asks about
  insight-wave plugins, skills, agents, conventions, architecture, workflows, or
  cross-cutting concepts. Trigger phrases include "ask the wiki", "ask insight-wave",
  "what does cogni-X do", "how does claims propagation work", "which plugin
  generates IS/DOES/MEANS", "what is the agent model strategy", "how do plugins
  share data", "what's the difference between cogni-narrative and cogni-copywriting",
  "explain the three-layer quality gate", "how does theme inheritance work", or
  any question about how insight-wave is structured. Especially useful as a first
  lookup before grepping plugin source files. Answers are grounded — if the wiki
  has no page on the topic, the skill says so rather than guessing.
allowed-tools: Read, Glob, Grep, Bash
---

# Ask insight-wave

Answer questions about the insight-wave plugin ecosystem by reading the bundled wiki. Never answer from model memory — every claim in the answer must trace to a specific wiki page.

This skill is self-contained: it does a Karpathy-style, index-first grounded read (read the index → read the relevant pages → synthesize with citations) directly over the wiki bundled at `${CLAUDE_PLUGIN_ROOT}/wiki/`, using only `Read`/`Glob`/`Grep` — no external plugin dispatch. The wiki is **vendor-curated and read-only by intent** — it ships with this plugin and is refreshed in lockstep with cogni-workspace updates. Users who want a personal knowledge base should run `cogni-knowledge:knowledge-setup` to create their own separate, compounding knowledge base.

## When to run

- User asks any question about insight-wave plugins, skills, agents, architecture, conventions, workflows, or cross-cutting concepts
- User says "ask the wiki", "ask insight-wave", or asks how some part of the ecosystem works
- Another skill needs ecosystem context and would otherwise grep plugin source files

## Never run when

- The bundled wiki is missing — report that the cogni-workspace install may be corrupted and offer to re-install
- The user explicitly wants to query a different knowledge base (a personal one they set up themselves) — defer to `cogni-knowledge:knowledge-query` for a bound personal knowledge base instead

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--question` | Yes | The user's question, as a plain string. Can be passed positionally too. |
| `--max-pages` | No | Cap on how many pages to read (default 12). Prevents runaway reads. |

## Workflow

### 1. Locate the bundled wiki

The wiki is at `${CLAUDE_PLUGIN_ROOT}/wiki/`. Verify by checking that `${CLAUDE_PLUGIN_ROOT}/wiki/.cogni-wiki/config.json` exists. If it doesn't, stop and report: "The bundled insight-wave wiki is missing — try reinstalling cogni-workspace from the marketplace."

### 2. Read the index

Read `${CLAUDE_PLUGIN_ROOT}/wiki/wiki/index.md` top to bottom. The index is the map. Categories: Ecosystem, Architecture, Cross-cutting concepts, Plugins, Workflows.

### 3. Select candidate pages

From the index, select pages whose one-line summary is relevant to the question. If fewer than 2 clear matches, also run `grep -l -i` over `${CLAUDE_PLUGIN_ROOT}/wiki/wiki/pages/` for the question's key nouns. Cap the total set at `--max-pages` (default 12).

If zero candidate pages emerge after both passes, report honestly: "The insight-wave wiki has no page on this topic. The wiki covers plugins, workflows, architecture, and cross-cutting concepts — your question may be outside that scope. Falling back to plugin source code or asking [`cogni-help:guide`](https://github.com/cogni-work/insight-wave/blob/main/cogni-help/skills/guide/SKILL.md) may help." **Do not answer from memory.**

### 4. Read the selected pages

Read each candidate page fully. Note:
- The claims that directly answer the question
- The `**Source**` line (skill identifier + GitHub URL) at the bottom of each page
- Any contradictions between pages (rare in a vendor-curated wiki, but flag if found)

### 5. Synthesize the answer

Write a plain-prose answer, inline-citing every factual claim with a `[[page-slug]]` link. Example:

> The insight-wave ecosystem organizes into four layers — orchestration (cogni-consulting), foundation (cogni-workspace), data (cogni-portfolio, cogni-trends, cogni-research, cogni-claims), and output (cogni-narrative, cogni-copywriting, cogni-visual, cogni-sales, cogni-marketing) [[concept-four-layer-architecture]]. Plugins in higher layers depend on lower layers but never the reverse. Each plugin owns its data; cross-plugin reads happen through path references, bridge files, or YAML frontmatter contracts [[concept-data-isolation]].

Rules:
- Every non-trivial claim links to at least one `[[page-slug]]`
- Each page citation lets the reader trace to the canonical source (the page's `**Source**` line includes a skill identifier and a GitHub URL)
- If the wiki's coverage is thin on the question, say so: "Based on the [[plugin-cogni-X]] page alone, the wiki's view is..."
- After the answer, list the wiki pages consulted as a short trail so the user can read further

### 6. Do NOT file the answer back

Unlike a personal `cogni-knowledge:knowledge-query`, this skill does **not** offer to file the answer back as a new page. The bundled wiki is vendor-curated and read-only. If the user wants to capture insights, they should run `cogni-knowledge:knowledge-setup` to create their own knowledge base and ingest sources there.

## Output

A grounded answer with inline `[[page-slug]]` citations and a short trail of pages consulted. No file is created in the wiki.

## Failure modes

- **Bundled wiki missing** — report and offer reinstall
- **No relevant pages** — report honestly; do not fall back to model memory
- **Wiki disagrees with the user's prior belief** — surface the disagreement with citation rather than smoothing it over

## References

- The bundled wiki SCHEMA: `${CLAUDE_PLUGIN_ROOT}/wiki/SCHEMA.md`
- The wiki's index: `${CLAUDE_PLUGIN_ROOT}/wiki/wiki/index.md`
