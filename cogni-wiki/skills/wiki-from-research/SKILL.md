---
name: wiki-from-research
description: "Cold-start a Karpathy-style wiki from a cogni-research project — orchestrates research-setup → research-report → wiki-setup → wiki-ingest in one call. Use when the user says 'build a wiki from research on X', 'research X and put it in a wiki', 'cold-start a wiki about X', 'wiki-ify the quantum-cryptography research', 'turn my <slug> research project into a wiki', 'deep research a topic into a fresh wiki'. Two modes: Mode A (--topic) runs cogni-research first; Mode B (--research-slug) deposits an already-completed project. Defaults to detailed report depth; passes through to research-setup's interactive menu so the user still picks market, language, tone."
allowed-tools: Read, Bash, Glob, AskUserQuestion, Skill
---

# Wiki From Research

Turn a research topic (Mode A) or an already-completed cogni-research project (Mode B) into a populated cogni-wiki — one prompt instead of four. This is the cold-start primitive: from "I want a wiki about quantum cryptography" to a queryable wiki with one command.

This skill **orchestrates only**. It writes nothing directly. Every page comes from `wiki-ingest`'s lock-protected pipeline; every config comes from `wiki-setup`'s detection logic; every research artefact comes from `cogni-research`'s STORM pipeline. The value here is sequencing, fail-fast pre-flight, and slug coordination — not new mechanics.

Read `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` once at the start to re-anchor on the three-layer model (raw / wiki / schema) before dispatching any sub-skill.

## When to run

- User asks to bootstrap a wiki from a research topic ("build a wiki on AI safety", "deep-research X into a wiki")
- User has a finished cogni-research project and wants it deposited into a fresh wiki ("wiki-ify my <slug> project", "turn the quantum research into a wiki")
- User wants the cold-start convenience of one command instead of running `research-setup`, `research-report`, `wiki-setup`, and `wiki-ingest` manually

## Never run when

- The user already has both a populated wiki *and* a finished research project and only wants to deposit — that's `wiki-ingest --discover research:<slug>` directly. This skill is for the cold-start case.
- The cogni-research project to be deposited has `report_source ∈ {wiki, hybrid}` — see Step 0 (5).

## Parameters

Exactly one of `--topic` or `--research-slug` must be present.

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--topic` | Mode A | Free-text research topic. Triggers Mode A — runs cogni-research first. Mutually exclusive with `--research-slug`. |
| `--research-slug` | Mode B | Slug of an existing `cogni-research-<slug>/` project. Triggers Mode B — skip research, just bootstrap and deposit. Mutually exclusive with `--topic`. |
| `--name` | No | Wiki display name. Defaults to `--topic` (Mode A) or the research project's `topic` field (Mode B). |
| `--wiki-slug` | No | Wiki slug override. Default: equals research slug (see §Slug coordination). |
| `--wiki-root` | No | Pass-through to `wiki-setup`. Default `cogni-wiki/{wiki-slug}/`. |
| `--description` | No | Pass-through to `wiki-setup`. |
| `--publisher-base-url` | No | Pass-through to `wiki-setup`. |
| `--research-overrides` | No | Mode A only. Comma-separated `key=value` hints forwarded to `research-setup` (e.g. `report_type=detailed,market=dach,target_words=5000`). Default: `report_type=detailed`. The user can still override every value in `research-setup`'s interactive menu — overrides are pre-fills, not pins. |
| `--skip-verify` | No | Mode B only. Skip the warning when zero report-claims have `verification_status: verified`. |
| `--dry-run` | No | Run all pre-flight checks and print the resolved plan (slugs, paths, dispatch order). Do not invoke any sub-skill. |

If neither `--topic` nor `--research-slug` is present, abort with a clear message — never guess. Disambiguation is via flag, not heuristic, because both forms can look alike (e.g. `agent-economy` is a valid topic *and* a valid slug).

## Workflow

### 0. Pre-flight (always; fail-fast)

The order matters: in Mode A, the **wiki-target check runs before any research dispatch** so an unusable wiki target never burns money on cogni-research.

1. **Resolve mode & slugs.**
   - If `--topic` set: mode = A. The cogni-research slug is unknown until Step 1 returns; pin a *tentative* slug from `kebab-case(--topic)` for path planning, but use the actual slug from Step 1's return.
   - If `--research-slug` set: mode = B. `research_slug = --research-slug`.
   - `wiki_slug = --wiki-slug` if set, else `research_slug`.
   - `wiki_root = --wiki-root` if set, else `cogni-wiki/{wiki_slug}/` resolved against the current workspace.

2. **Wiki-target collision check.**
   - If `<wiki_root>/.cogni-wiki/config.json` exists: AskUserQuestion with options `resume` (skip Step 2; ingest into the existing wiki), `overwrite` (re-run wiki-setup over it), `abort`. Default surfaced: `resume`. Record the choice as `wiki_action ∈ {resume, overwrite}`.
   - If `<wiki_root>` exists but contains foreign files (no `.cogni-wiki/`, but a non-empty `raw/` or `wiki/`): abort with the same error `wiki-setup` would emit ("path exists but is not a wiki"). Record `wiki_action = create`.
   - Otherwise: `wiki_action = create`.

3. **Mode B: research project sanity.**
   - Look for `cogni-research-<research_slug>/` at `<workspace>/` (workspace = wiki_root's parent) or `<wiki_root>/`. If neither: abort.
   - If `<project>/output/report.md` is missing: abort with "research project found but not yet completed — run `cogni-research:research-resume` first".
   - Read `<project>/project-config.json`. If `report_source ∈ {wiki, hybrid}`: abort with "this skill cannot deposit a wiki/hybrid-mode research project into a wiki — circular reads not yet handled in v1".

4. **Mode B: verify-report nudge.**
   - Glob `<project>/03-report-claims/data/rc-*.md`. Count entities whose frontmatter has `verification_status: verified`.
   - If count is zero AND `--skip-verify` is not set: emit a one-paragraph warning ("`verify-report` has not run; the wiki will receive findings but no verified claims, since `wiki-ingest --discover research:` filters claims to verified-only by design"). AskUserQuestion: `proceed` (continue without verified claims), `run-verify-first` (dispatch `Skill("cogni-research:verify-report", args="--project-slug <research_slug>")` then re-run this step), `abort`.

5. **Dry-run gate.**
   - If `--dry-run`: emit the resolved plan as plain text — `mode`, `research_slug`, `wiki_slug`, `wiki_root`, `wiki_action`, dispatch sequence — and stop. No sub-skill dispatch.

### 1. Run cogni-research (Mode A only)

Compose the prompt for `research-setup`. The skill is interactive and parses intents from the user prompt; we feed it the topic plus our overrides as natural language so its menu pre-fills correctly.

```
Skill("cogni-research:research-setup",
      prompt="Research the following topic and produce a <report_type> report. Topic: <topic>. <overrides as 'Use market <X>. Output language <Y>. Tone <Z>.' phrasing>")
```

Forward `--research-overrides` as a sentence per pair. Default override added if absent: `report_type=detailed`. Do NOT pre-pass a slug — `cogni-research:initialize-project.sh` derives the slug from the topic and handles collisions (resume / new / different). Capturing that resolved slug after return is what step 1c is for.

1a. The user proceeds through `research-setup`'s interactive menu (market, language, tone, citations, source mode, location). Confirms.

1b. `research-setup` auto-chains to `research-report`. The full pipeline runs to completion: `cogni-research-<resolved_slug>/output/report.md` is written.

1c. Capture `resolved_slug` from the `research-setup` output (it prints the project path; parse `cogni-research-<slug>/` from it). Set `research_slug = resolved_slug`. If `--wiki-slug` was not set, also update `wiki_slug = resolved_slug` (and recompute `wiki_root` if `--wiki-root` was not set).

1d. **Re-run Step 0 (3) and (4) against `resolved_slug`.** The user may have routed cogni-research to a different location, or the topic may have collided with an existing project. Fail-fast if `output/report.md` is absent or `report_source ∈ {wiki, hybrid}`. Run the verify-report nudge — Mode A produces a fresh report whose claims are all `pending` by default, so the nudge genuinely applies (most users will pick `run-verify-first` here).

### 2. Run wiki-setup

Skipped iff Step 0 (2) returned `wiki_action = resume`.

```
Skill("cogni-wiki:wiki-setup",
      args="--name \"<name>\" --wiki-root <wiki_root> --skip-prefill-prompt [--description \"...\"] [--publisher-base-url ...]")
```

Pass `--description` and `--publisher-base-url` only if the user provided them. The wiki slug is implicitly `wiki_slug` because `wiki-setup` derives it from `--name` (kebab-case); ensure `kebab-case(name) == wiki_slug` to keep the slugs aligned, or the resolved `cogni-wiki/{slug}/` will not match `wiki_root`. If the user-provided `--name` would derive a different slug, override `--wiki-root` explicitly so `wiki-setup` uses our path verbatim.

`--skip-prefill-prompt` is required (not optional) on this dispatch: cold-start from a research project is itself a domain-specific seeding path via Step 3's `wiki-ingest --discover research:<slug>`, so layering the foundations prefill on top would clutter the user's wiki with canonical concepts they did not ask for. The flag is the deterministic deferral; the user can still run `cogni-wiki:wiki-prefill` on the resulting wiki later if they decide they want the foundations after all. See `wiki-setup/SKILL.md` Step 6 for the contract.

### 3. Run wiki-ingest --discover research:<slug>

Dispatch from `<wiki_root>` as cwd so `wiki-ingest`'s wiki-root auto-detection lands on our wiki.

```
cd <wiki_root>
Skill("cogni-wiki:wiki-ingest", args="--discover research:<research_slug>")
```

`wiki-ingest`'s Step 0 will:
- Materialise per-sub-question synthesis files at `<wiki_root>/raw/research-<research_slug>/sq-NN-<short>.md`
- Print the resolved batch (count, sub-questions, contexts, sources, verified-claims)
- Ask "Ingest these N sources?" — **do not suppress this confirmation.** The per-sub-question listing is genuinely useful review and the user has only consented to the cold-start as a whole, not to skipping the ingest gate.

If `wiki_action = resume`, the ingest may produce per-sub-question slug collisions if a previous cold-start already populated those pages. `wiki-ingest`'s `mode: re-ingest` branch handles this atomically — pages are updated in place, `entries_count` stays correct.

### 4. Final summary

Print plain prose, ≤8 lines:

- Wiki path (absolute) and `wiki_slug`
- `research_slug` and project path
- Pages ingested (from `wiki-ingest` Step 9 aggregated report — count of successful sources)
- Verified vs pending claim count (from the research deposit's `data.research` block)
- Cost (Mode A only — sum from `research-report` Phase 6 summary)
- Suggested next actions: `wiki-query "..."`, `wiki-dashboard`. If verified claim count is low, suggest `cogni-research:verify-report` then re-run this skill in Mode B (Step 0 (2) `resume` + Step 3 will refresh pages with newly-verified claims).

## Slug coordination

**Default: `wiki_slug = research_slug`.** Both derive from the same source string (the topic in Mode A, the existing project name in Mode B), and matching them is the principle of least surprise. It also keeps `wiki-ingest --discover research:<slug>`'s auto-locate logic unambiguous — the script looks for `cogni-research-<slug>/` at the workspace root or under `<wiki-root>/`, and a matched pair satisfies either path.

If the user passes `--wiki-slug`, the layout becomes asymmetric (e.g., wiki at `cogni-wiki/my-wiki/`, research at `cogni-research-quantum/`). `wiki-ingest --discover research:quantum` still works because the auto-locate examines both `<workspace>/cogni-research-quantum/` and `<wiki-root>/cogni-research-quantum/`. The asymmetry is surfaced in Step 4.

In Mode A we let `cogni-research` derive the slug from the topic. If the topic collides (`research-setup`'s "resume / new / different" prompt resolves to e.g. `quantum-2`), we accept the resolved slug and pass it through. **Do not fight the upstream slug logic** — research-setup's collision handling is canonical.

## Edge cases

- **Mode A research crash partway.** Pre-Step-2; no wiki has been created. Surface the cogni-research error verbatim and exit non-zero. Research artifacts persist on disk; the user can run `cogni-research:research-resume` and then re-invoke this skill in Mode B against the same slug.
- **Mode B without verify-report.** Step 0 (4) handled — warn, offer to run verify first, or proceed with `--skip-verify`.
- **Wiki already populated (re-run cold-start).** Step 0 (2) handled. `resume` skips wiki-setup; `wiki-ingest`'s `mode: re-ingest` branch updates pages in place; `entries_count` is preserved.
- **Topic that resolves to an existing cogni-research project.** `research-setup`'s own prompt (resume / new / different) handles it. Whatever the user picks, capture the resolved slug in Step 1c and continue. Step 1d's re-validation catches a "different location" outcome that lands the project outside the workspace.
- **`--wiki-slug` mismatches `kebab-case(--name)`.** `wiki-setup` derives its target path from `--name`; we pass `--wiki-root` explicitly to override. The wiki's internal `slug` field in `.cogni-wiki/config.json` will reflect `kebab-case(--name)`, not our `wiki_slug`. This is a known asymmetry — flag it in Step 4 if the user asked for it.

## Out of scope

- **Does not auto-run `verify-report`.** Only nudges. Verification has cost; users may want to inspect claims first.
- **Does not duplicate `research-setup`'s configuration menu.** Market, language, tone, citations, source mode are all decided in `research-setup` — this skill only forwards hints.
- **Does not write wiki pages directly.** Every page passes through `wiki-ingest`'s lock-protected per-source worker, with the page-frontmatter contract and atomic index/config writes.
- **Does not integrate with cogni-narrative or cogni-copywriting.** Those are downstream of the wiki, not part of cold-start.
- **Does not deposit `report_source ∈ {wiki, hybrid}` projects in v1.** Reading from a wiki and writing back to the same wiki creates circular-evidence risk that needs its own design cycle.

## Output

The skill produces:
- (Mode A) A `cogni-research-<slug>/` project with output/report.md and entity directories
- A populated wiki at `<wiki_root>/` with one page per sub-question, plus the standard wiki-setup top-level files
- Materialised raw files under `<wiki_root>/raw/research-<slug>/sq-NN-<short>.md`
- An append-only `wiki/log.md` with one `setup` line and N `ingest` lines

No file is created outside `<wiki_root>/` or `<workspace>/cogni-research-<slug>/`.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/karpathy-pattern.md` — the three-layer model
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-setup/SKILL.md` — Step 2 contract
- `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/SKILL.md` and `${CLAUDE_PLUGIN_ROOT}/skills/wiki-ingest/references/batch-mode.md` — Step 3 contract (`--discover research:<slug>` lives there)
- cogni-research's `research-setup` and `research-report` skills — Step 1 contract (research-setup auto-chains to research-report)
