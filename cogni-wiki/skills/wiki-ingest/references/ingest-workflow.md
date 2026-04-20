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

Decide the category heading (here: `Safety`) and hand the write to the helper script so placement and ordering stay deterministic:

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/wiki_index_update.py \
    --wiki-root cogni-wiki/ai-research \
    --slug many-shot-jailbreaking \
    --summary "Exploiting long context by stuffing fake dialogue turns to prime harmful completions." \
    --category "Safety"
```

The script inserts `- [[many-shot-jailbreaking]] — Exploiting long context by stuffing fake dialogue turns to prime harmful completions.` under the `## Safety` heading (creating the heading if needed), keeps the section alphabetised, and returns:

```json
{
  "success": true,
  "data": {
    "action": "inserted",
    "category": "Safety",
    "category_created": false,
    "line": "- [[many-shot-jailbreaking]] — Exploiting long context by stuffing fake dialogue turns to prime harmful completions."
  }
}
```

On re-ingest the same invocation returns `action: "updated"` instead of appending a duplicate. If the script exits non-zero or returns malformed JSON, report the error and stop — the page from Step 4 is already on disk and the index is known-good because of the atomic `tempfile + os.replace`.

### Step 6: Backlink audit + atomic apply

**Audit.** Run `backlink_audit.py --wiki-root cogni-wiki/ai-research --new-page many-shot-jailbreaking`. The script returns:

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

**Curate.** For `long-context-vulnerabilities`, decide a `[[many-shot-jailbreaking]]` link belongs in the attack-classes paragraph — not in a dangling "See also" list. For `rlhf-limitations`, skip — the match is shallow and forcing a backlink would be noise. The orchestrator is the curator; the script never auto-selects targets.

**Apply atomically.** Re-invoke the script with a plan piped on stdin. This writes the backlink sentence and bumps the target page's `updated:` field in a single atomic write, so there is no way to forget the timestamp bump:

```sh
cat <<'PLAN' | backlink_audit.py --wiki-root cogni-wiki/ai-research --new-page many-shot-jailbreaking --apply-plan -
{
  "targets": [
    {
      "slug": "long-context-vulnerabilities",
      "sentence": "The canonical instantiation of this class of attack is [[many-shot-jailbreaking]], which exploits the same long-context-window expansion to prime harmful completions via hundreds of fake dialogue turns.",
      "insert_after_heading": "## Attack classes"
    }
  ]
}
PLAN
```

Output extends the audit JSON with `data.applied[]`, `data.skipped_existing_backlink[]`, and `data.failed[]` so you can confirm exactly which pages the apply pass changed before reporting to the user.

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

## Batch mode: one dispatch, N sources

`wiki-ingest` also accepts `--batch-file <path>` pointing at a JSON list of per-source entries. In that mode the skill instructions and references load once, Steps 1–8 run per entry, and Step 9 emits one aggregated report. Use it for bulk rebuilds (the canonical case: the 164-page pilot Phase 2) where re-dispatching the skill per source would burn tokens on repeated instruction loads.

### Scenario

The user has three new AI-safety papers staged in `raw/` and wants them all ingested in one go. They write `batch.json`:

```json
{
  "sources": [
    { "source": "raw/bai-et-al-2022.pdf", "title": "Constitutional AI", "type": "summary", "tags": ["llms", "safety"] },
    { "source": "raw/bai-et-al-2024.pdf", "title": "Many-Shot Jailbreaking", "type": "summary", "tags": ["safety", "long-context"] },
    { "source": "raw/wei-et-al-2022.pdf", "title": "Chain-of-Thought Prompting", "type": "concept", "tags": ["reasoning"] }
  ]
}
```

Assume the wiki already has a stub at `wiki/pages/constitutional-ai.md`; the other two slugs don't exist yet. They invoke `wiki-ingest --batch-file batch.json`.

### Step 0: dispatch

The skill reads `batch.json`, validates the schema (top-level `sources[]`, per-entry `source` required), confirms all three source paths exist, and enters batch mode. Instructions + `karpathy-pattern.md` + `page-frontmatter.md` load **once**.

### Per-source iteration (Steps 1–8)

**Source 1 — `bai-et-al-2022.pdf`.**

- Step 1 derives slug `constitutional-ai`, detects the existing page, sets `mode: re-ingest`, and emits the verbatim re-ingest warning.
- Step 3 surfaces takeaways (three-phase critique, scaling behaviour, constitutional principles list).
- Step 4 overwrites the existing `constitutional-ai.md` with the re-synthesised content.
- Step 5 calls `wiki_index_update.py`; the script returns `action: "updated"` (not `inserted`) because the index line already exists.
- Step 6 finds two backlink candidates; orchestrator curates one; `backlink_audit.py --apply-plan` writes the target atomically.
- Step 7 appends `## [2026-04-19] re-ingest | constitutional-ai — Constitutional AI`.
- Step 8 leaves `entries_count` unchanged (re-ingest).

**Source 2 — `bai-et-al-2024.pdf`.**

- Step 1 derives slug `many-shot-jailbreaking`, detects no existing page, sets `mode: fresh`.
- Steps 2–8 proceed as in the single-source example earlier in this document: new page written, index line inserted, one backlink applied to `long-context-vulnerabilities`, log line appended, `entries_count` incremented.

**Source 3 — `wei-et-al-2022.pdf`.**

- Step 1 derives slug `chain-of-thought-prompting`, fresh.
- Steps 2–8 complete; no backlinks curated this time (the target pages exist but the matches are too shallow to force).
- `entries_count` incremented.

### Step 9: aggregated report

```
Batch complete: 3/3 sources
- constitutional-ai           (re-ingest)  — 1 backlink applied
- many-shot-jailbreaking      (fresh)      — 1 backlink applied
- chain-of-thought-prompting  (fresh)      — 0 backlinks applied

entries_count: 42 → 44 (2 fresh, 1 re-ingest unchanged)
```

### What batch mode does NOT change

- Every per-source step is identical to single-source mode. Step 3's takeaway synthesis still fires; Step 5's `wiki_index_update.py` still runs atomically; Step 6's audit/curate/apply discipline is preserved; Step 8 still distinguishes fresh from re-ingest for `entries_count`.
- On error, the fail-fast policy halts the loop and reports partial progress. Every completed source is already safely in the wiki because all per-source writes are atomic — see `./batch-mode.md` §"Error policy" for the full resume procedure.

For the full schema, error policy, and the Phase 2 follow-ups deferred from this iteration (continue-on-error, parallel dispatch), read `./batch-mode.md`.
