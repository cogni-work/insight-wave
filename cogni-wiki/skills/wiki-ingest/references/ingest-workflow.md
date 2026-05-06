# Ingest Workflow — Worked Example

A concrete walkthrough of the ingest workflow using a realistic source. Read this when the abstract steps in `SKILL.md` are not enough — it shows exactly what "surface key takeaways before writing" looks like in practice.

## Scenario

The user has a fresh wiki at `cogni-wiki/ai-research/` with three pages already:

- `wiki/<type>/rlhf-limitations.md`
- `wiki/<type>/anthropic-safety-team.md`
- `wiki/<type>/constitutional-ai.md`

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

Path: `<wiki-root>/wiki/<type>/many-shot-jailbreaking.md`

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

Assume the wiki already has a stub at `wiki/<type>/constitutional-ai.md`; the other two slugs don't exist yet. They invoke `wiki-ingest --batch-file batch.json`.

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

## Worked examples by template

The two preceding examples (`many-shot-jailbreaking.md`, `constitutional-ai.md`) illustrate the `default.md` scaffold — `type: summary`, generic key-takeaways/details/sources shape. The remaining body templates each cover a domain-specific shape; one short example per template follows so Step 4a's selection rules can be checked against a concrete page.

Each example assumes Step 1 found the wiki and Step 3's takeaway synthesis cleared duplication risk; we focus on Step 4 (template pick + frontmatter + body shape) and call out the per-template required `[[wikilinks]]`.

### `interview.md` — captured conversation

Source: `raw/interview-pm-onboarding-2026-04-22.md` (a 40-minute call with the PM of a customer-success org about onboarding pain).

Invocation: `wiki-ingest --source raw/interview-pm-onboarding-2026-04-22.md --type interview --title "Interview: PM onboarding pain (Acme CS)"`

Step 4a resolves: `type=interview`, no `customer-call` tag → `template=interview.md`. Required links: an interviewee entity page, at least one topic concept page.

```markdown
---
id: interview-pm-onboarding-acme
title: "Interview: PM onboarding pain (Acme CS)"
type: interview
tags: [onboarding, customer-success, acme]
created: 2026-04-22
updated: 2026-04-22
sources:
  - ../raw/interview-pm-onboarding-2026-04-22.md
---

40-minute interview with `[[priya-rao]]` on `[[customer-onboarding]]` friction in Acme's CS org; surfaced three repeatable failure modes.

## Key takeaways

- Day-1 setup time is the single biggest predictor of 90-day retention, not feature depth `[[customer-onboarding]]`.
- Self-serve flows hide the moments where humans should intervene — three of the lost accounts had a clear "stuck" signal in week 2 that nobody saw.
- Re-onboarding (after a champion leaves) is treated as a special case but happens for ~30% of accounts annually.

## Details

### Interviewee

- **Name / role**: `[[priya-rao]]` — PM of Onboarding, Acme CS
- **Affiliation**: Acme Inc.
- **Date interviewed**: 2026-04-22
- **Format**: recorded call, transcript in `raw/`

### Context

Follow-up to the Q1 churn analysis. We picked Priya because her team owns the day-1 → day-30 window and she had visibility into the three accounts that churned in March.

### Topics covered

#### Day-1 setup time
…

#### Stuck-signal detection
…

#### Re-onboarding mechanics
…

### Notable quotes

> The accounts that survived the first 14 days at all weren't the ones who used more features — they were the ones who got the first integration live before the kickoff call ended.
>
> — Priya Rao, on what predicts retention

### Open questions raised

- Could the stuck-signal detection generalise across CS orgs, or is it Acme-specific?
- What does "first integration live" mean operationally for a non-API product?

## Sources

- [Interview transcript — Acme PM onboarding](../raw/interview-pm-onboarding-2026-04-22.md)
```

The interviewee link to `[[priya-rao]]` is required per the template; if the page doesn't exist, Step 4a's stub-first rule files `wiki/<type>/priya-rao.md` (frontmatter only, one-line summary) before writing this page.

### `customer-call.md` — sales / CS variant

Source: `raw/call-acme-q2-renewal.md`. Invocation: `wiki-ingest --source raw/call-acme-q2-renewal.md --type interview --tags customer-call,renewal --title "Acme Q2 renewal call"`.

Step 4a sees `type: interview` + tag `customer-call` → `template=customer-call.md`. Required links: customer entity, engagement / opportunity. The body uses the customer-call scaffold (call meta / pains / signals / objections / asks-and-commitments / next steps) instead of the generic interview shape — the table-driven asks-and-commitments structure is the load-bearing difference.

### `meeting.md` — meeting notes

Source: `raw/q2-planning-2026-04-15.md`. Invocation: `wiki-ingest --source raw/q2-planning-2026-04-15.md --type meeting --title "Q2 planning — leadership"`.

Step 4a resolves: `type=meeting` → `template=meeting.md`. Required links: at least one attendee or team, plus the project/topic the meeting concerns. Body shape: meeting meta → goal → key discussions → decisions made → action items table → parking lot.

If a decision recorded in the meeting deserves an ADR, file a separate `type: decision` page and link to it from the meeting's "Decisions made" section. The meeting page records that the decision happened; the decision page records the rationale.

### `decision.md` — ADR-shaped record

Source: `raw/decision-replatform-2026-03-10.md`. Invocation: `wiki-ingest --source raw/decision-replatform-2026-03-10.md --type decision --title "Decision: replatform onto stack X"`.

Step 4a resolves: `type=decision` → `template=decision.md`. Required links: the engagement / project / scope; any prior decision this one supersedes. Body shape: context → options considered (table) → decision → rationale → consequences (positive / negative / open risks) → revisit conditions.

The `revisit conditions` section is the highest-leverage discipline for `decision` pages — without it, decisions ossify silently. A page that lacks them should be flagged in lint once the per-type required-section rule lands (deferred to issue #210's lint contract).

### `retro.md` — retrospective variant

Source: `raw/retro-engagement-acme-q1-2026.md`. Invocation: `wiki-ingest --source raw/retro-engagement-acme-q1-2026.md --type learning --tags retro --title "Retro: Acme Q1 engagement"`.

Step 4a sees `type: learning` + tag `retro` → `template=retro.md`. Required links: the engagement / sprint / initiative; the team / participants. Body shape: retro meta → what worked → what didn't → what we'll change (table with owner + checkpoint) → patterns worth promoting.

The "patterns worth promoting" section is what turns retros from journaling into anti-repetition memory: when a learning recurs across two retros, promote it to a `type: learning` page in its own right and link both retros to it.

### `learning.md` — generalised lesson

Invocation: `wiki-ingest --source raw/learning-three-engagement-shape.md --type learning --title "Learning: three-engagement-shape pattern"`.

Step 4a resolves: `type=learning`, no `retro` tag → `template=learning.md`. Required links: at least one source page or entity the learning generalises from. Body shape: where this came from (cited sources with `[[wikilinks]]`) → when it applies → when it doesn't → implications → open questions.

A learning anchored to zero `[[wikilink]]` source pages is a hunch, not a learning — the template's "Where this came from" section is mandatory to keep this distinction visible.

## Template-selection edge cases

- **Mixed-shape source.** A meeting that contains a major decision: file the meeting under `meeting.md`, then file the decision separately under `decision.md` and cross-link. Do not stretch one template to cover both — `wiki-query` reliability comes from uniform per-type structure.
- **Source doesn't fit any template.** Fall back to `default.md`. The scaffolds are guidance, not a gate; an honest freeform page is better than a forced ADR.
- **`--type note`.** No template; pastes are typically too short to benefit from a scaffold. Promote to a typed page later via `wiki-update` if it crystallises.
- **`--type synthesis`.** No template; `wiki-query --file-back yes` writes the body directly per its own discipline (see `wiki-query/references/query-patterns.md`).

## Worked example: `.docx` ingest end-to-end (Step 2a auto-conversion)

The preceding examples all assumed a markdown or PDF source — those bypass Step 2a entirely. This section shows the full path for a non-markdown source so the auto-conversion branch is concrete.

### Scenario

A consulting team has a discovery call recording transcribed by their notetaker into Word format and dropped at `raw/discovery-acme-q2-2026-04-22.docx`. They invoke:

```
wiki-ingest --source raw/discovery-acme-q2-2026-04-22.docx \
            --type interview --tags customer-call,acme,q2 \
            --title "Discovery call: Acme CS pain (Q2 2026)"
```

### Step 1: locate the wiki, detect mode

`config.json` is found three levels up. Slug `discovery-acme-cs-pain-q2-2026` is derived from the title; no page at that slug yet, so `mode: fresh`.

### Step 2: read the source

Extension is `.docx` — neither `.md` nor `.pdf`, so the Step 2a auto-conversion sub-step fires.

### Step 2a: auto-convert

```
${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/scripts/convert_to_md.py \
    --source raw/discovery-acme-q2-2026-04-22.docx
```

`markitdown` is on `$PATH`; the script shells out and writes the converted markdown to `raw/discovery-acme-q2-2026-04-22.docx.converted.md`. Output:

```json
{
  "success": true,
  "data": {
    "source_path": "raw/discovery-acme-q2-2026-04-22.docx",
    "converted_path": "raw/discovery-acme-q2-2026-04-22.docx.converted.md",
    "backend": "markitdown",
    "cached": false
  },
  "error": ""
}
```

Surface the backend in the response transcript:

```
Source: raw/discovery-acme-q2-2026-04-22.docx [backend: markitdown]
        → raw/discovery-acme-q2-2026-04-22.docx.converted.md
```

The orchestrator now reads the converted markdown for the rest of Steps 3 and 4. The original `.docx` is untouched and remains the citation anchor.

### Step 2a fallback paths (one of these is what you hit, not all of them)

- **`markitdown` not installed but the source is `.html` / `.txt`.** Backend is `stdlib-html` or `stdlib-passthrough`; no install needed; surface the backend tag and proceed.
- **`markitdown` not installed and the source is a binary office format.** Script returns `success: false`, `backend: unsupported`. Stop and tell the user: "`.docx` requires markitdown — `pip install markitdown` (see `README.md` §Optional dependencies) or convert the file to `.md` manually and re-invoke. Aborting before any wiki write." No partial state to clean up — Step 2a runs before Step 4.
- **`markitdown` installed but errors on this file.** Script returns `success: false`, `backend: markitdown-error`, with stderr in `error`. Surface verbatim and offer two paths: re-invoke with `--no-convert` (the orchestrator reads the binary path directly — useful for inspecting metadata when the file is text-shaped despite the extension) or hand-convert. Do not invent a fallback that silently half-extracts.
- **Re-ingest of the same `.docx`.** Backend returns `cache-hit` because `<source>.converted.md` is newer than the source; the conversion is skipped, the cached markdown is read, and Step 2a finishes in milliseconds. To force re-conversion (e.g., after a markitdown upgrade), pass `--force` to `convert_to_md.py` directly or delete the cache file before invoking.

### Step 3: takeaways before writing

Surface in plain prose, e.g.:

> **Source**: 38-minute discovery call with Priya Rao (PM Onboarding, Acme CS), 2026-04-22. Converted from `.docx` via markitdown; original retained at `raw/discovery-acme-q2-2026-04-22.docx`.
>
> **Key takeaways:**
> 1. Day-1 setup time predicts 90-day retention more than feature depth — three of last quarter's churned accounts had multi-day setup gaps.
> 2. Acme has no signal-detection on stuck onboarding flows; "stuck" only surfaces when the AE notices low usage on a check-in.
> 3. Re-onboarding (champion turnover) hits ~30% of accounts annually and is treated as ad-hoc rather than a flow.
>
> **Existing pages this touches:**
> - `[[priya-rao]]` — does not yet exist; will file a stub per the `interview.md` template's required-link rule.
> - `[[customer-onboarding]]` — exists; will gain a backlink.
> - `[[acme-engagement-q2-2026]]` — does not yet exist; will file a stub for the engagement.
>
> **Proposed**: type=interview, template=customer-call.md (because of the `customer-call` tag), title=Discovery call: Acme CS pain (Q2 2026).

### Step 4: write the page

Step 4a resolves to `customer-call.md` (type `interview` + tag `customer-call`). Stubs are filed for `priya-rao` and `acme-engagement-q2-2026` first per the "never invent backlinks" rule. Then the page itself:

```markdown
---
id: discovery-acme-cs-pain-q2-2026
title: "Discovery call: Acme CS pain (Q2 2026)"
type: interview
tags: [customer-call, acme, q2]
created: 2026-04-22
updated: 2026-04-22
sources:
  - ../raw/discovery-acme-q2-2026-04-22.docx
---

…body filled per customer-call.md scaffold…
```

The `sources:` line points at the **`.docx` original**, not the `.converted.md` cache — see `SKILL.md` §"Failure modes" ("Original source is the citation, not the cache"). A future re-ingest can rebuild the cache from the original if a markitdown release improves extraction; nothing in the wiki should depend on the cache path.

### Steps 5–9

Identical to the markdown / PDF examples earlier in this document. The auto-conversion sub-step is invisible to everything downstream of Step 2; the `.converted.md` cache file lives quietly next to the original under `raw/` and is only re-touched on a deliberate `--force` or cache-mtime-older-than-source.

### Anti-patterns specific to multi-format ingest

- **Pointing `sources:` at the `.converted.md` file.** The cache is derived; the citation chain must trace to the original artefact the user actually has on disk. A page citing a `.converted.md` will silently rot the next time markitdown improves and the cache is regenerated with different formatting.
- **Deleting the original `.docx` after conversion succeeded.** The wiki's portability promise rests on every page tracing to a `raw/` artefact. The cache is **not** a substitute — it's a derived view.
- **Using `--no-convert` to silence a `markitdown-error`.** That just kicks the problem downstream — the orchestrator will read a binary blob and write a noise-filled page. Either fix the markitdown failure (or upgrade) or hand-convert the source to `.md`.
