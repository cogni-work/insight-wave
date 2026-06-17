---
name: knowledge-finalize
description: "Phase 7 of the inverted pipeline — deposits the verified draft as a wiki synthesis page, closing the compounding loop. Reads the latest verified draft + its verify manifest + citation manifest, runs cycle-guard.py to refuse self-citing loops, atomically writes the draft to <wiki>/syntheses/<slug>.md with type: synthesis frontmatter (incl. derived_from_research), updates wiki/index.md, bumps entries_count, rebuilds context_brief.md, appends a research_projects[] entry to binding.json and a finalize line to wiki/log.md, and runs a conformance gate (wiki-lint --fix=all + wiki-health) with bare [[slug]] backlinks that de-orphan the cited sources. Then dispatches the wiki-contradictor agent for a zero-network contradiction tripwire and the wiki-reviewer agent for an advisory structural-quality score — both fail-soft, non-blocking observability. The deposited synthesis becomes visible to future knowledge-compose runs as cross-source framing. Use this skill whenever the user says 'finalize the draft', 'deposit the synthesis', 'phase 7 of the knowledge pipeline', 'knowledge finalize', or 'land the verified draft'."
allowed-tools: Read, Write, Bash, Task, AskUserQuestion
---

# Knowledge Finalize

Phase 7 of the inverted pipeline. Reads `<project>/output/draft-vN.md` + `<project>/.metadata/verify-vN.json` + `<project>/.metadata/citation-manifest.json`, runs `cycle-guard.py` to refuse self-citing loops, deposits the verified draft as `<WIKI_ROOT>/wiki/syntheses/<synthesis-slug>.md`, runs three cogni-wiki helpers (`wiki_index_update.py`, `config_bump.py`, `rebuild_context_brief.py`) directly at script level, appends a `research_projects[]` entry to `binding.json`, writes one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md`, and runs a Step 10.5 conformance gate (`lint_wiki.py --fix=all` + `health.py`) so the deposited base passes cogni-wiki's own structural checks.

This is the **inverted-pipeline closing step**. Without it, every verified draft lives forever in `<project>/output/` and the wiki cannot accumulate cross-source framing — the compounding property that differentiates cogni-knowledge from one-shot deep-research tools requires future `knowledge-compose` runs to read `wiki/syntheses/*.md` as prior context. Finalize is what makes that read non-empty.

Synthesis-page frontmatter shape (matches cogni-wiki SCHEMA for `type: synthesis` per `cogni-wiki/CLAUDE.md` §"Page Frontmatter"):

```yaml
---
id: <synthesis-slug>
title: <plan.topic verbatim>
type: synthesis
tags: [synthesis]
created: <today ISO>
updated: <today ISO>
sources:
  - wiki://<cited-slug-1>
  - wiki://<cited-slug-2>
derived_from_research: <project-slug>
draft_revision_round: <verify.revision_round>
---
```

`derived_from_research` is stamped inline (no `lineage-stamp.py` dispatch — that helper walks `raw/research-<slug>/`, which inverted-pipeline projects don't write to). `draft_revision_round` is informational; cogni-wiki's lint allows arbitrary additive frontmatter keys.

Read `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` §"Phase 7 — `knowledge-finalize`" once to anchor on the contract.

## When to run

- `<project>/.metadata/verify-vN.json` exists for the latest `output/draft-vN.md` (Phase 6 / `knowledge-verify` has run).
- User explicitly invokes `/cogni-knowledge:knowledge-finalize`.

## Never run when

- No `<project>/.metadata/citation-manifest.json` — offer `knowledge-compose` first.
- No matching `<project>/.metadata/verify-v<N>.json` for the latest `draft-v<N>.md` — offer `knowledge-verify` first.
- No `binding.json` at the resolved knowledge root — offer `knowledge-setup` first.
- `binding.wiki_path` does not resolve to a directory containing `.cogni-wiki/config.json` — the binding is stale.
- `<WIKI_ROOT>/wiki/syntheses/<slug>.md` already exists and `--overwrite` was not passed.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `--knowledge-slug` | Yes | Slug of the bound knowledge base. |
| `--project-path` | Yes | Absolute path to the project directory. |
| `--knowledge-root` | No | Override the default knowledge-base directory. |
| `--synthesis-slug` | No | Override the auto-derived synthesis slug (default: `_knowledge_lib.slugify(plan.topic)`). |
| `--overwrite` | No | Replace an existing `wiki/syntheses/<slug>.md`. Default: refuse. |
| `--dry-run` | No | Print the resolved inputs (WIKI_ROOT, DRAFT_VERSION, SYNTHESIS_SLUG, citation count) without writing anything or dispatching cycle-guard. |
| `--no-contradictor` | No | Skip the Step 10.6 contradiction tripwire **entirely** (both the synthesis-vs-cited comparison and the synthesis-vs-prior-syntheses comparison). Default: OFF (tripwire runs). Pass this as cheap insurance against false-positive flooding when sustained `medium`/`low` noise is dominant in real runs; the synthesis is still deposited and the Step 10.5 conformance gate still runs. |
| `--no-prior-syntheses` | No | Narrow the Step 10.6 tripwire to the cited-evidence comparison only — pass an empty `PRIOR_SYNTHESIS_SLUGS` so the synthesis-vs-cited comparison still runs while the synthesis-vs-prior-syntheses comparison is suppressed. Default: OFF (prior syntheses are compared). Unlike `--no-contradictor` this does not skip the agent; the cited-evidence findings still flow. Useful when a base has many prior syntheses and the prior-comparison noise dominates. |
| `--no-reviewer` | No | Skip the Step 10.7 structural-quality review. Default: OFF (reviewer runs). Pass to suppress the advisory structural score on a run where you only want the deposit + conformance gate; the synthesis is still deposited and every other step still runs. Mirrors `--no-contradictor`. |
| `--no-open-questions` | No | Skip the Step 10.5 sub-step 5 `rebuild_open_questions.py` refresh. Default: OFF (rebuild runs). Pass when investigating a rebuild bug or running a no-side-effect finalize; the synthesis still lands and the rest of the Step 10.5 gate still runs. Mirrors `--no-contradictor`. |
| `--no-research-gaps` | No | Narrow the Step 10.5 sub-step 5 rebuild to lint findings only — skip streaming this project's research-time gaps (`research_uncovered` / `research_partial`) into `open_questions.md`. Default: OFF (gaps stream). Unlike `--no-open-questions` this does **not** skip the sub-step; the seven existing lint classes still reconcile. Also skips the sub-step 5 post-ingest coverage re-score (the gap stream is dropped, so the re-score would be wasted work). The Step 10 `sqs=` log-line suffix is unaffected. Useful for debugging the payload-builder path. |
| `--no-question-links` | No | Skip the Step 4.7 `synthesis→question` forward links (and therefore the Step 10.5 reverse backfill into each question page's `## See also`). Default: OFF (links emitted). Pass to deposit a synthesis with no `## Research questions` section — e.g. against a base whose question nodes are mid-refactor. The synthesis still deposits and every other step still runs. Mirrors `--no-contradictor`. |
| `--apply-portal` | No | **Apply** the Step 10.5 sub-step 3.5 curated-portal refresh (auto-refresh, option 4b) instead of staging it: write the engine-owned per-theme lead-ins to `wiki/index.md` (via `wiki_index_update.py --set-leadin`) and splice the overview narrative into the `wiki/index.md` intro (via `overview_update.py narrative-splice --target-file index.md`; the curated-root layout retired `wiki/overview.md` as the narrative home). Alias: `--refresh-portal`. Default: OFF — finalize **stages** a proposed diff to `<wiki>/.cogni-wiki/portal-proposed.md` and leaves the live portal untouched. Human (non-sentineled) lead-ins are never touched in either mode. See `references/portal-shape-decision.md`. |
| `--no-portal` | No | Skip the Step 10.5 sub-step 3.5 curated-portal refresh **entirely** — no portal-narrator dispatch, no staging, no apply. Default: OFF (the refresh runs, staging by default). The synthesis still deposits and every other step still runs. Mirrors `--no-contradictor`. |
| `--no-portal-prompt` | No | Suppress the Step 10.5 sub-step 3.5 **interactive apply-portal confirm** so finalize stages the proposed diff silently instead of asking. Default: OFF — a human-direct run with a non-empty refresh set is asked whether to apply now. The autonomous `knowledge-refresh --mode push` loop passes this flag (the `--no-cobrowse` parallel) so it never blocks on the prompt. No effect under `--apply-portal` (applies regardless) or `--no-portal`/`--dry-run` (no refresh runs). |
| `--apply-concepts` | No | **Apply** the Step 10.5 sub-step 3.6 concepts-outline refresh instead of staging it: splice the engine-owned per-theme lead-ins into `wiki/concepts/index.md` (via `concepts_index.py render` + a locked `CONCEPTS-LEADIN:<theme>` span splice). Alias: `--refresh-concepts`. Default: OFF — finalize **stages** a proposed diff to `<wiki>/.cogni-wiki/concepts-index-proposed.md` and leaves the live concepts outline untouched. Human (non-sentineled) `wiki/concepts/index.md` pages are never touched in either mode. |
| `--no-concepts` | No | Skip the Step 10.5 sub-step 3.6 concepts-outline refresh **entirely** — no concepts-outliner dispatch, no staging, no apply. Default: OFF (the refresh runs, staging by default). The synthesis still deposits and every other step still runs. Mirrors `--no-portal`. |
| `--no-concepts-prompt` | No | Suppress the Step 10.5 sub-step 3.6 **interactive apply-concepts confirm** so finalize stages the proposed diff silently instead of asking. Default: OFF — a human-direct run with a non-empty refresh set is asked whether to apply now. The autonomous `knowledge-refresh --mode push` loop passes this flag (the `--no-portal-prompt` parallel) so it never blocks on the prompt. No effect under `--apply-concepts` (applies regardless) or `--no-concepts`/`--dry-run` (no refresh runs). |

## Workflow

### 0. Pre-flight

**Required plugins.** Probe only `cogni-wiki` (clean-break — no cogni-research, no cogni-claims):

```
probe_plugin() {
  local plugin="$1" skill="$2"
  test -f "${CLAUDE_PLUGIN_ROOT}/../${plugin}/skills/${skill}/SKILL.md" && return 0
  for d in "${CLAUDE_PLUGIN_ROOT}/../../${plugin}/"*/skills/"${skill}"/SKILL.md; do
    [ -f "$d" ] && return 0
  done
  return 1
}
probe_plugin cogni-wiki wiki-setup && WIKI_OK=yes || WIKI_OK=no
```

If `WIKI_OK=no`, abort with the standard missing-plugin message.

**Resolve the cogni-wiki script dirs.** Same probe shape, parameterised by the
skill subdir, so Steps 7/8/10 can call `wiki_index_update.py` / `config_bump.py` /
`rebuild_context_brief.py` (wiki-ingest) and Step 10.5's conformance gate can call
`lint_wiki.py` (wiki-lint) + `health.py` (wiki-health). Each script imports
`_wikilib` relatively from `wiki-ingest/scripts`, so resolving the real installed
dir keeps those imports intact:

```
. "${CLAUDE_PLUGIN_ROOT}/scripts/resolve-wiki-scripts.sh"
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest backlink_audit.py) || abort "cogni-wiki wiki-ingest scripts not found"
WIKI_LINT_SCRIPTS=$(resolve_wiki_scripts wiki-lint lint_wiki.py)   || abort "cogni-wiki wiki-lint scripts not found"
WIKI_HEALTH_SCRIPTS=$(resolve_wiki_scripts wiki-health health.py) || abort "cogni-wiki wiki-health scripts not found"
```

**Binding + wiki root.** Resolve `knowledge_root` (same logic as `knowledge-verify`). Read the binding:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py read \
    --knowledge-root <knowledge_root>
```

On `success: false` → abort, offer `knowledge-setup`.

Parse `data.binding.wiki_path` as `WIKI_ROOT`. Confirm `<WIKI_ROOT>/.cogni-wiki/config.json` exists; abort otherwise. Confirm `<WIKI_ROOT>/wiki/` exists.

**Project manifests.** Confirm `<project_path>/.metadata/citation-manifest.json` exists; abort with "no citation manifest — run knowledge-compose then knowledge-verify first" otherwise. Confirm at least one `<project_path>/output/draft-v*.md` exists; abort with "no draft on disk — run knowledge-compose first" otherwise.

### 1. Resolve current draft version N

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PROJECT_PATH="<project_path>" \
python3 -c '
import os, re
from pathlib import Path
out = Path(os.environ["PROJECT_PATH"]) / "output"
existing = sorted(int(m.group(1)) for p in out.glob("draft-v*.md")
                  for m in [re.match(r"draft-v(\d+)\.md$", p.name)] if m)
print(existing[-1] if existing else 0)
'
```

N is the highest existing `draft-v*.md` integer. If `0`, abort.

### 2. Confirm verify-vN.json matches and surface unsupported count

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PROJECT_PATH="<project_path>" \
DRAFT_VERSION=<N> \
python3 -c '
import json, os, sys
from pathlib import Path
project = Path(os.environ["PROJECT_PATH"])
n = int(os.environ["DRAFT_VERSION"])
verify = project / ".metadata" / ("verify-v" + str(n) + ".json")
assert verify.exists() and verify.stat().st_size > 0, "missing verify-v" + str(n) + ".json — run knowledge-verify"
v = json.loads(verify.read_text(encoding="utf-8"))
assert v.get("schema_version") == "0.1.0", "bad verify schema: " + repr(v.get("schema_version"))
assert v.get("draft_version") == n, "verify draft_version=" + repr(v.get("draft_version")) + " != " + str(n)
counts = v.get("counts", {})
print(json.dumps({
    "unsupported": counts.get("unsupported", 0),
    "verbatim": counts.get("verbatim", 0),
    "paraphrase": counts.get("paraphrase", 0),
    "synthesis": counts.get("synthesis", 0),
    "total": counts.get("total", 0),
    "revision_round": v.get("revision_round", 0),
}))
'
```

Capture `UNSUPPORTED_COUNT`, `REVISION_ROUND`, and the four counts (`verbatim` / `paraphrase` / `synthesis` / `unsupported`) — they feed both the Step 5 compose subprocess (threaded as `VERIFY_VERBATIM` / `VERIFY_PARAPHRASE` / `VERIFY_SYNTHESIS` / `VERIFY_UNSUPPORTED` for the `verification_ratio:` frontmatter key) and the Step 11 summary's verbatim/paraphrase ratio line. If `UNSUPPORTED_COUNT > 0`, surface a `⚠ Finalizing with <N> unsupported citations remaining (verify-v<N>.json::counts.unsupported)` — do **not** block. The operator decided to ship the partial draft (same posture as `knowledge-verify` Step 6's "Loop exhausted" warning).

### 3. Resolve synthesis slug + abort on collision

Default slug: derive from `plan.json::topic` via the shared `_knowledge_lib.slugify` helper (single source of truth — also used by `knowledge-ingest` Step 1.2):

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
PROJECT_PATH="<project_path>" \
python3 -c '
import json, os, sys
from pathlib import Path
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import slugify
plan = json.loads((Path(os.environ["PROJECT_PATH"]) / ".metadata" / "plan.json").read_text(encoding="utf-8"))
print(slugify(plan.get("topic") or "") or "")
'
```

If `--synthesis-slug <slug>` was passed, use it; otherwise use the derived value. Abort if the derived value is empty (no usable topic) and no override was passed.

Confirm `<WIKI_ROOT>/wiki/syntheses/<SYNTHESIS_SLUG>.md` does not already exist. Capture `SYNTHESIS_EXISTED_PRE=yes|no` — Step 8's overwrite-skip decision depends on whether the page existed before this run. If `SYNTHESIS_EXISTED_PRE=yes` and `--overwrite` was not passed, abort with: "synthesis page wiki/syntheses/<slug>.md already exists; pass --overwrite or --synthesis-slug <other> to proceed".

Compute `CITATION_COUNT` for the dry-run printout (and the final summary's audit line):

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
MANIFEST_PATH="<project_path>/.metadata/citation-manifest.json" \
python3 -c '
import json, os
from pathlib import Path
m = json.loads(Path(os.environ["MANIFEST_PATH"]).read_text(encoding="utf-8"))
print(len(m.get("citations", []) or []))
'
```

If `--dry-run`, print:

```
WIKI_ROOT=<wiki_root>
PROJECT_PATH=<project_path>
DRAFT_VERSION=<N>
SYNTHESIS_SLUG=<slug>
SYNTHESIS_EXISTED_PRE=<yes|no>
CITATION_COUNT=<count>
UNSUPPORTED_COUNT=<count>
REVISION_ROUND=<round>
```

and stop.

### 4. Run cycle-guard (with the adapter active)

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/cycle-guard.py \
    --knowledge-root <knowledge_root> \
    --research-slug <project-slug> \
    --research-project-path <project_path> \
    --report-source wiki
```

`<project-slug>` is the **project directory basename** (`$(basename <project_path>)`) — already `slugify(<topic>)-<YYYY-MM-DD>` and globally unique within the base, an artifact the inverted pipeline actually produces. The inverted pipeline does **not** write the legacy cogni-research `.metadata/project-config.json`, so do not look for a `slug` field there. `--report-source wiki` is hard-coded — the inverted pipeline only ever produces wiki-mode deposits, so the legacy `_read_report_source` fallback isn't relevant here.

The script's manifest-shape fallback walks `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty. Confirm `data.input_shape == "citation-manifest"` in the JSON envelope as a positive signal the adapter ran (informational; not a gate).

Interpret return:

- **Exit 0, `status: clear`** — proceed. `cross_lineage_overlap[]` may be non-empty; surface count in Step 11.
- **Exit 0, `status: not_applicable`** — should not happen (`--report-source wiki` is explicit). Treat as defence-in-depth; proceed.
- **Exit 1, `status: cycle_detected`** — abort. Print `direct_self_cycles[]` + remediation: "The synthesis would cite a wiki page derived from this same project — that's a self-citing loop. Rename the synthesis (`--synthesis-slug <other>`), narrow the topic, or hand-edit the draft to drop the self-referential citations."
- **Exit 1, `status: manifest_unreadable`** — the citation manifest at `.metadata/citation-manifest.json` cannot be parsed (corrupt JSON, I/O error). Abort with the script's `error` field verbatim; remediate by re-running `knowledge-compose` to regenerate the manifest. **Do not proceed** — depositing a synthesis whose lineage cannot be checked is the exact failure mode the guard exists to prevent.

### 4.7 Resolve answered research-question nodes

`knowledge-ingest` Step 4.5 promotes each sub-question into a `type: question` node at `wiki/questions/<slug>.md` and persists the exact sub-question→node mapping to `<project_path>/.metadata/question-manifest.json` (`[{slug, sub_question_id, query, sources_answering[], action}]`). This step reads that manifest so Step 5/6 can forward-link the deposited synthesis to the question nodes it answers — closing the `question → findings → synthesis` loop (a reader on a question page can reach the verified synthesis, not just the sources).

Build `QUESTION_SLUGS_CSV` from the manifest's `questions[].slug`:

```
QUESTION_SLUGS_CSV=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
MANIFEST_PATH="<project_path>/.metadata/question-manifest.json" \
python3 -c '
import json, os
from pathlib import Path
p = Path(os.environ["MANIFEST_PATH"])
try:
    qs = json.loads(p.read_text(encoding="utf-8"))
except Exception:
    qs = []
slugs = [q["slug"] for q in (qs or [])
         if isinstance(q, dict) and isinstance(q.get("slug"), str) and q["slug"]]
print(",".join(slugs))
' 2>/dev/null || true)
```

The slugs are kebab-case-only by `_knowledge_lib.slugify` (transliterated, NFKD-folded, `[a-z0-9-]+` only — the same `slugify` that derived them at ingest time), so the CSV is safe against embedded commas, backslashes, or quotes (the same structural guarantee Step 10.6's `CITED_SOURCE_SLUGS_CSV` relies on).

**Fail-soft / empty CSV** when any of these hold — the variable is left empty and Step 5/6 appends no section (byte-identical to the pre-this-change deposit):

- The manifest file is missing — a **legacy project** finalized before its base grew question nodes (pre-`knowledge-ingest` Step 4.5), or a project whose every sub-question had zero findings.
- The manifest is empty or unparseable (the `python3 -c` above degrades to an empty list).
- **`--no-question-links`** was passed — force `QUESTION_SLUGS_CSV=` regardless of the manifest.

The per-slug *page-existence* gate is NOT applied here — it lives in the Step 5/6 subprocess (which already has `wiki_root` in hand and already runs the identical `is_file()` check for the reference-row backlinks), so a question page deleted between ingest and finalize is skipped at write time rather than emitted as a `broken_wikilink`.

### 5. Compose + 6. Atomic write

One Python subprocess composes the synthesis page in memory and writes it
atomically via `_knowledge_lib.atomic_write_text` (the same helper `source-ingester`
uses for `wiki/sources/<slug>.md`). The verbatim `python3 -c` block is offloaded for
progressive disclosure — **run it exactly as written** in
[`references/finalize-compose-subprocess.md`](../../references/finalize-compose-subprocess.md)
§"Subprocess (run verbatim)". Set these env inputs on the invocation line:

- `KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts"` — prepended to `sys.path`
- `WIKI_ROOT` / `PROJECT_PATH` / `PROJECT_SLUG` / `SYNTHESIS_SLUG` — resolved wiki root, project path, project + synthesis slugs
- `DRAFT_VERSION=<N>` / `REVISION_ROUND=<round>`
- `VERIFY_VERBATIM` / `VERIFY_PARAPHRASE` / `VERIFY_SYNTHESIS` / `VERIFY_UNSUPPORTED` — the Step 2 verify counts (written into the synthesis `verification_ratio:` frontmatter)
- `QUESTION_SLUGS_CSV="$QUESTION_SLUGS_CSV"` — the Step 4.7 forward-link slugs (empty when none)

The subprocess emits **one trailing JSON line** on stdout carrying
`{output_language, cited_source_slugs}`.

The trailing JSON line is captured for the final summary. Steps 5 and 6 are bundled into this single subprocess to keep the compose + write atomic relative to retry — a re-run sees the same wiki state.

**Capture the trailing JSON once, here.** The Step 5/6 subprocess emits its trailing JSON line (carrying `output_language` + `cited_source_slugs`) to stdout. Capture it into `COMPOSE_JSON` immediately — a **heredoc-quoted assignment** so a `topic` with apostrophes (`L'avenir`), backticks, or `$` is not interpreted by the shell — and derive the **full, untruncated** cited-source CSV that Step 9's refresh-candidate clear needs. The same `COMPOSE_JSON` is reused by the Step 10.6 contradictor block (which adds its own 30-capped CSV for the agent); capturing it once here is what makes the deposited synthesis's cited slugs available at Step 9, which runs *before* Step 10.6:

```
# Heredoc with quoted 'EOF' disables ALL shell expansion (no $, no backtick,
# no quote handling) so a topic like "L'avenir de l'AI Act" or a wiki slug
# with shell metacharacters never trips the assignment.
COMPOSE_JSON=$(cat <<'EOF'
<verbatim Step 5/6 trailing JSON line>
EOF
)
# Full (untruncated) cited-source slug CSV — Step 9 clears refresh candidates by
# citation overlap, so it must see every cited slug (the Step 10.6 contradictor's
# own derivation caps at 30, which is fine for that surface but not for this one).
CITED_SOURCE_SLUGS_FULL_CSV=$(printf '%s' "$COMPOSE_JSON" | python3 -c '
import json, sys
print(",".join(json.loads(sys.stdin.read()).get("cited_source_slugs") or []))
' 2>/dev/null || true)
```

### 7. Update wiki/index.md (cogni-wiki helper)

First **sanitize the authored summary** so a stray typographic substitute (U+2020 DAGGER, U+2021, or an exotic space U+00A0/U+202F/U+2009) never reaches the reader-facing `wiki/index.md` one-liner — same guard `knowledge-ingest` Step 4.2 applies, pass the raw value via an env var:

```
CLEAN_SUMMARY=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
RAW_SUMMARY="<a crisp one-line description of the synthesis topic>" \
python3 -c '
import os, sys
sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import sanitize_summary
print(sanitize_summary(os.environ["RAW_SUMMARY"]))
')
```

Then pass `$CLEAN_SUMMARY` to `--summary`:

```
python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
    --wiki-root "$WIKI_ROOT" \
    --slug <synthesis-slug> \
    --summary "$CLEAN_SUMMARY" \
    --category "Syntheses" \
    --max-summary 240
```

Same call shape as `knowledge-ingest/SKILL.md` Step 4.2, with `--category "Syntheses"` instead of `"Sources"`. Write the summary as one crisp, complete sentence (no character count); `sanitize_summary` (the typographic-substitute guard) normalizes stray glyphs to regular spaces, and the `--max-summary 240` defensive backstop clamps on a word boundary with `…` only if it runs long, guarding `wiki/index.md` against a mid-word artifact. The helper is lock-wrapped (`_wiki_lock` at `<WIKI_ROOT>/.cogni-wiki/.lock`).

Capture the JSON envelope. On `success: true`, set `INDEX_OK=yes` and continue to Step 8. On `success: false` OR a non-zero exit, set `INDEX_OK=no`, surface the error in the final summary, and **skip Step 8** (do not bump `entries_count` when the index didn't actually get a new row — keeping the counter and the filesystem in lockstep is the structural invariant `wiki-lint --fix=entries_count_drift` is supposed to reconcile, not a hazard for finalize to create).

### 8. Bump entries_count (cogni-wiki helper) — conditional

Two conditions gate Step 8:

1. `INDEX_OK=yes` (Step 7 succeeded) — required.
2. The page was newly created at Step 6, not overwritten. Specifically: if `--overwrite` was passed AND the synthesis page already existed before Step 6 (the precondition check at Step 3), the counter was bumped on the original finalize. Re-bumping here would permanently drift `entries_count` by +1 per overwrite.

When both conditions hold, run:

```
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" \
    --wiki-root "$WIKI_ROOT" \
    --key entries_count \
    --delta 1
```

Same call shape as `wiki-query --file-back` (`cogni-wiki/skills/wiki-query/SKILL.md:91`). Lock-wrapped. Non-fatal on failure (operator can reconcile via `wiki-lint --fix=entries_count_drift`).

When skipped (either condition fails), surface the reason in the final summary: `"entries_count not bumped (Step 7 failed | overwrite re-deposit)"`.

### 9. Append the project to the binding

When `--overwrite` was NOT passed (first deposit):

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py append-project \
    --knowledge-root <knowledge_root> \
    --knowledge-slug <knowledge_slug> \
    --research-slug <project-slug> \
    --report-path <project_path>/output/draft-v<N>.md \
    --project-path <project_path> \
    --report-source wiki
```

When `--overwrite` WAS passed (re-deposit), add `--allow-update` so the existing binding entry is updated in place (refresh `report_path` to the new draft version, `deposited_at` to today):

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py append-project \
    --knowledge-root <knowledge_root> \
    --knowledge-slug <knowledge_slug> \
    --research-slug <project-slug> \
    --report-path <project_path>/output/draft-v<N>.md \
    --project-path <project_path> \
    --report-source wiki \
    --allow-update
```

`--report-source wiki` is hard-coded — the inverted pipeline only ever produces wiki-mode deposits (the legacy archived `report_source` shellout is not used). Without `--allow-update`, a duplicate `research_slug` aborts the script — surface a **loud** warning so the operator can't miss the binding/wiki desync:

```
⚠ Binding append SKIPPED: project '<project-slug>' already bound; re-run with --overwrite to refresh the binding entry, or accept that this finalize landed the synthesis page on the wiki without updating binding.json::research_projects[]. The synthesis page IS on disk — re-running finalize without --overwrite will refuse on the existing page; re-run with --overwrite + --allow-update to reconcile both.
```

Do not abort the SKILL — Steps 6–8 already landed the page, and refusing now would leave wiki state on disk that's not reflected in the binding (the same desync the warning is alerting the operator to). The operator decides whether to reconcile via `--overwrite` re-run or accept the asymmetric state.

**Clear any evidence-aware refresh candidate for this synthesis.** When a prior
`knowledge-ingest-source` run flagged this synthesis as outdated by a newer
source, it recorded a `refresh_candidates[]` entry in the binding (schema 0.1.5).
This finalize deposits the refreshed synthesis, so clear that flag:

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py resolve-refresh-candidate \
    --knowledge-root <knowledge_root> \
    --synthesis-slug <SYNTHESIS_SLUG> \
    $([ -n "$CITED_SOURCE_SLUGS_FULL_CSV" ] && printf -- '--cites %s' "$CITED_SOURCE_SLUGS_FULL_CSV") \
    || true
```

The `--cites` pass (using the full cited-source CSV captured after Step 5/6) also
clears any candidate whose `via_pages[]` overlap this synthesis's cited evidence —
so a refresh that landed under a slug **diverging** from the originally-flagged
synthesis (the user re-phrased the refresh topic, so `slugify(title)` no longer
matches the stored `synthesis_slug`) still resolves the stale candidate instead of
re-surfacing it on every later related ingest. The guard omits `--cites` entirely
when the CSV is empty, and the trailing `|| true` keeps the whole clear fail-soft.

**Fail-soft** — a no-op success when neither the slug nor any cited-overlap entry
was flagged (the common case) or on a pre-0.1.5 binding; never block finalize on it.
This closes the evidence-aware refresh loop so a flagged candidate doesn't rot after
the refresh that resolves it lands.

### 9.5 Sweep verify-shards intermediates

Best-effort cleanup of the Phase 6 fan-out scratch — `<project_path>/.metadata/verify-shards/` holds per-round `shard-NN-vN.json` inputs + `verify-shard-NN-vN.json` fragments that `knowledge-verify` produced, but the canonical `verify-vN.json` is already merged and the synthesis is now deposited (Step 6). Finalize never reads `verify-shards/`, and a later `knowledge-verify` re-shards from scratch (idempotent re-shard, `verify-store.py` `cmd_shard`), so the directory is safe to remove:

```
rm -rf "<project_path>/.metadata/verify-shards"
```

Non-critical: a failure here (e.g. permissions) **never blocks finalize** — the deliverable already landed at Steps 6–10. Skip silently if the directory does not exist.

### 10. Append wiki/log.md

`context_brief.md` is rebuilt at the **end** of the Step 10.5 gate (not here), so it reflects the gate's reverse-link / `entries_count` / `overview.md` writes rather than a pre-gate snapshot.

Append one log line (Bash `>>`; `wiki/log.md` is append-only by cogni-wiki convention).

The topic is operator-supplied free text. Replace any embedded CR/LF with a space first so a multi-line topic cannot break `wiki/log.md`'s one-line-per-event invariant — the cogni-wiki log-format enum is line-oriented. Use `printf` (not `echo`) so backslash-escape interpretation across `bash`/`sh`/`dash` does not vary:

```
DATE_STAMP=$(date -u +%F)
TOPIC_RAW=<topic from Step 5 subprocess output>
TOPIC=$(printf '%s' "$TOPIC_RAW" | tr '\r\n' '  ')

# sqs= suffix: the bare sq_id list (no `sq:` prefix) of the
# sub-questions scored uncovered/partial in this project's pre-finalize
# wiki-coverage.json — the research-time gaps this synthesis presumably now
# covers. Empty (suffix omitted) when no coverage manifest exists.
GAP_SQS=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" PROJECT_PATH="$PROJECT_PATH" python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import gap_sq_ids_from_coverage
print(",".join(gap_sq_ids_from_coverage(os.environ["PROJECT_PATH"])))
' 2>/dev/null || true)

LOG_PATH=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/control-path.py" log --wiki-root "${WIKI_ROOT}")
if [ -n "$GAP_SQS" ]; then
    printf '## [%s] finalize | project=%s slug=%s draft=v%s round=%s sources=%s sqs=%s\n' \
        "$DATE_STAMP" "$TOPIC" "$SYNTHESIS_SLUG" "$DRAFT_VERSION" "$REVISION_ROUND" "$N_SOURCES" "$GAP_SQS" \
        >> "${LOG_PATH}"
else
    printf '## [%s] finalize | project=%s slug=%s draft=v%s round=%s sources=%s\n' \
        "$DATE_STAMP" "$TOPIC" "$SYNTHESIS_SLUG" "$DRAFT_VERSION" "$REVISION_ROUND" "$N_SOURCES" \
        >> "${LOG_PATH}"
fi
```

`control-path.py log` resolves the canonical `log.md` location (legacy `wiki/log.md` today, `wiki/meta/log.md` once the layout flip lands) so the finalize log append does not hardcode the path — see `scripts/control-path.py`.

`KNOWLEDGE_SCRIPTS` is `${CLAUDE_PLUGIN_ROOT}/scripts` (the cogni-knowledge scripts dir holding `_knowledge_lib.py`). The `sqs=` suffix is additive: cogni-wiki's `LOG_LINE_RE` parses `## [date] op | rest` and treats `rest` as opaque, so pre-existing readers ignore it. It is what cogni-wiki's `rebuild_open_questions.py::attribute_close` substring-scans (after stripping the `sq:` prefix from the checklist id) to credit-close a research-time gap `closed … by finalize`.

`finalize` is a new operation prefix. Same additive-prefix posture as `compose` and `verify` — cogni-wiki readers count unknown prefixes in their catch-all bucket without crashing (`cogni-wiki/CLAUDE.md` §"Key Conventions").

### 10.5 Conformance gate (run cogni-wiki's own gates)

The inverted pipeline writes the wiki via forked agents + direct script calls, so cogni-wiki's `wiki-health` / `wiki-lint` never run as a gate. This step closes that: it backfills the deterministic link/frontmatter fixes, asserts the base is structurally clean, and rebuilds `context_brief.md` last so it reflects the post-gate state. It runs after the deposit + index are on disk, so the gate sees the final page set.

1. **Deterministic lint fixes — de-orphan + reconcile.**
   ```
   python3 "$WIKI_LINT_SCRIPTS/lint_wiki.py" \
       --wiki-root "$WIKI_ROOT" \
       --fix=all
   ```
   `--fix=all` applies the five safe classes (`lint_wiki.py` `FIX_CLASSES`). The load-bearing one is **`reverse_link_missing`**: the bare `[[<slug>]]` references this finalize just wrote are forward edges synthesis→source (and, since Step 4.7, synthesis→question), so lint backfills the reverse `[[<synthesis-slug>]]` (a `## See also` append on each cited source **and on each linked `wiki/questions/<slug>.md` node**) — de-orphaning the synthesis and giving each question page a forward link to the verified synthesis that answered it. (The question-page `## See also` append lands after the human `## Notes` tail; `question-store.py` preserves everything from the `## Notes` marker onward, so the reverse link survives subsequent ingest re-merges, and lint is idempotent on the existing `## See also`.) The others are housekeeping: `frontmatter_defaults`, `entries_count_drift` (reconciles `entries_count` to the on-disk truth — supersedes Step 8's conditional bump on any drift), `alphabetisation`, and `synthesis_no_wiki_source` (a no-op — Step 5 already wrote `wiki://<slug>` sources). Capture the envelope; surface `data.fixed[]` / `data.failed[]` counts in the Step 11 summary. **Non-fatal per item** — a per-page fix failure lands in `data.failed[]` and does not block finalize. (`orphan_page` is NOT a `--fix` class — it is suggest-only; 0 orphans comes from the inbound links the bare refs + this reverse-link backfill create, never from `--fix`.)

2. **Health + orphan assertions (the actual gate).**
   ```
   python3 "$WIKI_HEALTH_SCRIPTS/health.py"   --wiki-root "$WIKI_ROOT"
   python3 "$WIKI_LINT_SCRIPTS/lint_wiki.py"  --wiki-root "$WIKI_ROOT"
   ```
   The second call has **no `--fix`** — it reads the post-fix state. Assert two things and surface both **loudly** (and **non-fatally** — the synthesis already landed; the operator reconciles via `wiki-update` / a re-run, never a rollback):
   - `health.py` `data.errors == []` → on any error: `⚠ wiki-health: <N> error(s) after finalize: <class> on <page>, …`.
   - `lint_wiki.py` `data.warnings` has **no `orphan_page`** entry → on any: `⚠ wiki-lint: <N> orphan page(s) after finalize: <page>, …`.

   The orphan assertion is what actually covers the slice's stated metric — `orphan_page` is a **lint warning, not a health error**, and is **not** a `--fix` class, so the `--fix=all` in sub-step 1 de-orphans by *writing inbound links* (bare refs + the `reverse_link_missing` backfill), and this read-only re-lint verifies it worked. Without this check the gate could report "health clean" while a synthesis was left orphaned (e.g. if the de-orphaning was undone). Residual orphans are expected and acceptable in two documented cases (surface, don't fail): an ingested source no synthesis ever cited and no sibling backlinks (cold-start), and a synthesis that cites zero existing pages (empty/all-missing manifest → it has no outbound links for `reverse_link_missing` to mirror).

   **Caveat — foundation pages.** `reverse_link_missing` has no `foundation: true` exemption, so if this synthesis cites a prefilled foundation concept, the fixer appends a `## See also` backlink onto that curated page (bypassing `wiki-update`'s `--force` guard). In the inverted pipeline the composer cites `wiki/sources/*` + prior `wiki/syntheses/*`, not `wiki/concepts/`, so this is not expected; noted so a future foundation-citing path is aware.

3. **Refresh `wiki/overview.md`.** Keep the "state of the wiki" page from going stale. Deterministic, no extra LLM pass — ensure a `## Recent syntheses` heading exists and refresh a single bullet for this synthesis (idempotent on the slug). The dedup removes only this slug's prior **bullet** (a `- … [[slug]] …` list item), never prose that merely mentions `[[slug]]`; the heading is matched by exact line, never substring. The write is **lock-wrapped + atomic**: `overview_update.py recent-bullet` acquires cogni-wiki's `_wiki_lock` (the shared `<WIKI_ROOT>/.cogni-wiki/.lock`) and writes via `_knowledge_lib.atomic_write_text`, so a concurrent finalize from another session serialises and a crash mid-write leaves `overview.md` intact (temp-file + `os.replace`). `overview.md` is not graph-scanned, so this is purely freshness:
   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/overview_update.py" recent-bullet \
       --wiki-root "$WIKI_ROOT" \
       --slug "<slug>" \
       --topic "<topic>" \
       --date "$(date -u +%F)" \
       --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
   ```
   Non-fatal — `overview.md` is a derived narrative artefact; a non-success envelope (lock-acquire / `_wikilib` import / write failure) is logged loudly in Step 11 but never blocks finalize or rolls back the synthesis (nothing partial is written on a failure).

3.5. **Refresh the curated portal (auto-refresh, option 4b).** Make the curated portal — the engine-owned per-`## <theme>` lead-in paragraphs in `wiki/index.md` and the "state of the wiki" overview narrative folded into the `wiki/index.md` intro (the `MACHINE-OWNED:OVERVIEW-NARRATIVE` block; the curated-root layout retired `wiki/overview.md` as the narrative home — see sub-step 3.5.1) — compound narratively as the base grows, the Phase-7 analog of the Phase-4.5 `concept-summary-narrator` → `concept-store.py renarrate` rails. The **ownership boundary** is the `MACHINE-OWNED:PORTAL-LEADIN` sentinel: a human (non-sentineled) lead-in is never touched; the engine authors a machine span only where none exists and refreshes only a span it previously authored (`wiki_index_update.py --set-leadin` enforces this on the write side). The full rationale is in `references/portal-shape-decision.md`.

   **Choice-point:** DEFAULT (no flag) **stages** a proposed diff and leaves the live portal untouched; `--apply-portal` (alias `--refresh-portal`) **applies** it. `--no-portal` skips the whole sub-step.

   **Skip conditions (evaluated in order):**

   1. `--dry-run` was passed — silent skip (defence-in-depth; finalize already exits at Step 3 on `--dry-run`).
   2. `--no-portal` was passed — log `Portal refresh skipped: --no-portal` and continue to sub-step 4.

   **(a) Build the refresh set** — the themes that grew this run. Read `plan.json::sub_questions[].theme_label`, dedupe, add `"Syntheses"` (the category the synthesis just deposited into), and keep only those that exist as a `## <theme>` section in `wiki/index.md`. Empty → log `Portal refresh skipped: nothing grew` and continue to sub-step 4.

   ```
   REFRESH_THEMES_JSON=$(KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
   PLAN_PATH="$PROJECT_PATH/.metadata/plan.json" \
   INDEX_PATH="$WIKI_ROOT/wiki/index.md" \
   python3 -c '
   import json, os, re
   from pathlib import Path
   try:
       plan = json.loads(Path(os.environ["PLAN_PATH"]).read_text(encoding="utf-8"))
   except Exception:
       plan = {}
   themes = []
   seen = set()
   for sq in (plan.get("sub_questions") or []):
       t = (sq or {}).get("theme_label") or ""
       t = " ".join(t.split())
       if t and t.lower() not in seen:
           seen.add(t.lower()); themes.append(t)
   if "syntheses" not in seen:
       themes.append("Syntheses")
   # keep only themes that actually exist as a ## heading on the index
   try:
       idx = Path(os.environ["INDEX_PATH"]).read_text(encoding="utf-8")
   except Exception:
       idx = ""
   heads = {m.group(1).strip().lower() for m in re.finditer(r"^#{2,3}\s+(.*?)\s*$", idx, re.M)}
   kept = [t for t in themes if t.lower() in heads]
   print(json.dumps(kept))
   ')
   ```

   **(b) Build the bundle** at `<project_path>/.metadata/portal-bundle.txt`. Per theme: a `## theme: <heading>` line, a `### current-leadin` section from `wiki_index_update.py --get-leadin --category "<theme>"` (`data.leadin`, the engine's existing machine lead-in or empty), and a `### bullets` section (that theme's `- [[slug]] — …` lines, read from `wiki/index.md`, for context). Then one `## overview` block: `### current-narrative` (the existing `MACHINE-OWNED:OVERVIEW-NARRATIVE` span of `wiki/index.md` via `_knowledge_lib.extract_machine_block` — the block now lives in the root index intro, not `wiki/overview.md`; or empty) + `### recent-syntheses` (the `## Recent syntheses` bullets sub-step 3 just refreshed). The `--get-leadin` call is read-only:

   ```
   python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
       --wiki-root "$WIKI_ROOT" --get-leadin --category "<theme>"
   ```

   **(c) Dispatch the portal-narrator** (fail-soft — on any agent error or no envelope, log `⚠ portal refresh: portal-narrator did not return; skipping (synthesis on disk)` and continue to sub-step 4):

   ```
   Task(portal-narrator,
        BUNDLE_PATH=$PROJECT_PATH/.metadata/portal-bundle.txt,
        RECORDS_OUTPUT_PATH=$PROJECT_PATH/.metadata/portal-records.txt,
        OUTPUT_LANGUAGE=$OUTPUT_LANGUAGE)
   ```

   `OUTPUT_LANGUAGE` is the same value Step 5/6 threaded from `plan.json::output_language` (re-read it from `plan.json` if not still in hand). The agent writes raw-text records parsed by `_knowledge_lib.parse_portal_records` → `{theme_leadins: {theme: prose}, overview: prose|None}`.

   **(d) STAGE (default) or APPLY (`--apply-portal`), with an interactive confirm on human-direct runs.**

   **First-authoring carve-out (the overview narrative only).** Before deciding the path, compute
   `overview_first_authoring` = the live `OVERVIEW-NARRATIVE` block has **never been authored** — i.e.
   the bundle's `### current-narrative` (sub-step (b), `_knowledge_lib.extract_machine_block(index_text,
   "OVERVIEW-NARRATIVE")`, which returns `None` when the block is absent — coerce `None` → `""` first)
   is empty (after `.strip()`) OR is whitespace-stripped-equal to the `knowledge-setup` bootstrap
   placeholder `_Overview pending — authored on the first knowledge-finalize run._` (this literal MUST
   stay byte-identical to the seed's single source of truth in
   `references/curated-layout-seed.md` §"Seed payload" — if the seed text ever changes, update both
   together, else the never-authored detection silently stops firing). When `overview_first_authoring`
   is true AND the records carry an `overview`, **splice the overview narrative live regardless of the
   STAGE/APPLY decision below** (run the APPLY path's `overview_update.py narrative-splice` call). This
   fulfils the seed's literal promise ("authored on the first knowledge-finalize run") so a default
   (STAGE) first finalize no longer leaves `_Overview pending…_` at the top of the front door while the
   authored narrative sits unread in `portal-proposed.md`. It is **safe by construction** — it fires only
   on the never-authored state, so it can never clobber a human-edited or a prior-machine-authored
   overview, and a base whose overview is already real falls straight through to the normal STAGE/APPLY
   behavior. The carve-out covers the **overview narrative only**; the per-theme lead-ins still follow the
   STAGE/APPLY/prompt decision below (they carry no "first run" promise, so a default STAGE keeps the
   human review gate for theme prose). Skip the carve-out under `--apply-portal` (the APPLY path already
   splices the overview) and under `--no-portal` (the whole sub-step is skipped). When the carve-out
   fires on an otherwise-STAGE run, the STAGE path below still writes `portal-proposed.md` for the
   lead-ins (the overview is already live) and Step 11 notes the auto-applied overview.

   Decide the path before writing anything:

   1. `--apply-portal` was passed → **APPLY** (explicit intent wins; never prompt).
   2. Otherwise the default is STAGE. Decide whether to *ask first*:
      - If `--no-portal-prompt` was passed (the autonomous `knowledge-refresh --mode push` loop sets it) — **STAGE silently**, today's behavior. (An empty refresh set never reaches here; (a) already skipped it.)
      - Otherwise this is a **human-direct** run with themes that grew, so surface the proposed diff and `AskUserQuestion` (single-select):

        > **Apply the proposed portal refresh to the live portal?** `<N>` engine-owned theme lead-in(s) in `wiki/index.md` plus the `wiki/index.md` intro narrative will be (re)written from the portal-narrator's records. Human (non-sentineled) lead-ins are never touched.

        Options: **Apply** → run the APPLY path below; **Stage only** → run the STAGE path below (write `portal-proposed.md`, live portal untouched). This is the only `AskUserQuestion` in finalize; it fires solely on the human-direct, non-empty-refresh-set path, so the autonomous loop and every flagged run stay non-interactive.

   The two paths themselves are unchanged:

   - **STAGE** — write a human-readable `<WIKI_ROOT>/.cogni-wiki/portal-proposed.md`: for each proposed theme, the heading + a `current:` block (from the bundle's `--get-leadin`) and a `proposed:` block (from the records), then the proposed overview narrative. Do **not** write the live portal — **except** the first-authoring overview carve-out above: when `overview_first_authoring` is true, the overview narrative was already spliced live (run the APPLY path's `narrative-splice` call once), so `portal-proposed.md` still stages the lead-ins but the overview is on the front door, not pending. (Inline `python3` reading `portal-records.txt` via `parse_portal_records` + the per-theme `--get-leadin` already captured in the bundle.)

   - **APPLY** — per proposed theme, write the lead-in prose to a temp file and call cogni-wiki's locked helper (empty prose ⇒ the helper removes the span):

     ```
     printf '%s' "<proposed lead-in prose>" > "$TMP_LEADIN"
     python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
         --wiki-root "$WIKI_ROOT" \
         --set-leadin --category "<theme>" \
         --leadin-file "$TMP_LEADIN" \
         --refreshed-date "$(date -u +%F)"
     ```

     Then splice the overview narrative (when the records carried an `overview`) into the `wiki/index.md` intro by writing the prose to a temp file and calling `overview_update.py narrative-splice --target-file index.md` — which wraps `_knowledge_lib.upsert_machine_block(text, "OVERVIEW-NARRATIVE", prose)` in the **same** `_wiki_lock` + `_knowledge_lib.atomic_write_text` body sub-step 3 uses (so the splice serialises on the shared `<WIKI_ROOT>/.cogni-wiki/.lock` and a crash mid-write leaves `index.md` intact). First finalize inserts the block right after the index H1 (the knowledge title), later finalizes replace only its inner; the curated root MAP (rendered next, sub-step 3.5.1, which carries this block forward verbatim) and all other prose are preserved byte-for-byte. The `--target-file` defaults to `overview.md` for back-compat, so the curated-root path must pass it explicitly:

     ```
     printf '%s' "<overview narrative prose>" > "$TMP_OVERVIEW"
     python3 "${CLAUDE_PLUGIN_ROOT}/scripts/overview_update.py" narrative-splice \
         --wiki-root "$WIKI_ROOT" \
         --prose-file "$TMP_OVERVIEW" \
         --target-file index.md \
         --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
     ```

     The portal-narrator emits an unchanged lead-in/overview verbatim, so a re-apply with no new bullets no-ops the splice (no stamp/date churn — `--set-leadin` returns `action: noop`, `narrative-splice` reports `changed: false` and writes nothing because `upsert_machine_block` returns identical text), matching `renarrate` semantics.

   **Fail-soft posture (explicit).** Sub-step 3.5 is a portal refresh. A narrator failure, a parse error, or a `--set-leadin` per-theme failure **never rolls back the synthesis** — the synthesis page, index entry, `entries_count` bump, `binding.json` append, `wiki/log.md` line, and sub-steps 1–3 are all already on disk. Surface failures loudly in Step 11 and continue. The `--set-leadin` index write and the `index.md` intro narrative splice are **both** locked + atomic (`_wiki_lock` + `atomic_write` / `atomic_write_text` via `overview_update.py narrative-splice --target-file index.md`), so a forced failure leaves no partial write on either page.

   **Step 11** surfaces, on STAGE: `Portal: <N> lead-ins + overview proposed — review <WIKI_ROOT>/.cogni-wiki/portal-proposed.md, apply with --apply-portal`; on STAGE **with the first-authoring carve-out fired**: `✓ Portal: overview narrative authored (first finalize); <N> lead-in(s) proposed — review <WIKI_ROOT>/.cogni-wiki/portal-proposed.md, apply with --apply-portal`; on APPLY: `✓ Portal: <N> lead-ins refreshed + overview spliced`; on either skip, the corresponding skip message; on a fail-soft error, `⚠ portal refresh FAILED — <reason>; synthesis on disk`.

3.5.1. **Render the curated root MAP (`wiki/index.md`).** Re-render the root portal as a curated progressive-disclosure MAP via `root_index.py render` — an overview-narrative intro plus one `## <theme>` section per real theme, each carrying its `PORTAL-LEADIN`/human lead-in forward verbatim and a single count-link line to the per-type sub-indexes (`Sources (40) · Concepts (12) · …`), with the per-page `- [[slug]]` bullets **dropped** (they live in the sub-indexes now). This is the **structural** curation of the root, distinct from sub-step 3.5's lead-in *narration*: it runs **unconditionally** (gated only by `--dry-run`, like the rest of finalize — **not** by `--no-portal`, which governs narration), so a default (STAGE) finalize still curates the root while the lead-in prose stays staged.

   Run it **after** sub-step 3.5 (so a just-applied `PORTAL-LEADIN` span / `OVERVIEW-NARRATIVE` fold is carried into the MAP) and after Step 7's `wiki_index_update.py` (whose freshly-filed bullets this render drops). The renderer keeps the vendored `wiki_index_update.py` byte-identical (Option A) and is **idempotent + byte-stable** under the Step 10.5 sub-step-1 `lint --fix=all` reflow/collapse passes — the curated MAP carries no `- [[slug]]` bullets to re-sort and unique `##` headings to merge, so it is a fixpoint (a resume re-render is a no-op). Per-theme counts come from `sub_index.py`'s shared theme assignment, so they can never drift from the sub-indexes they link to. **Fail-soft** — a render error never rolls back the synthesis (already on disk from Steps 6–8); surface it in Step 11 and continue.

   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/root_index.py" render \
       --wiki-root "$WIKI_ROOT" \
       --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
   ```

   **Step 11** surfaces, on a change: `✓ Root index: curated MAP rendered (<N> themes)`; on a no-op: `Root index: already curated (no change)`; on a fail-soft error: `⚠ root index render FAILED — <reason>; synthesis on disk`.

3.6. **Refresh the concepts outline (auto-refresh).** Make the curated **concepts outline** — the engine-owned per-`## <theme>` lead-in paragraphs in `wiki/concepts/index.md` — compound narratively as the concept base grows, the concepts-page sibling of sub-step 3.5's curated-portal refresh. The **ownership boundary** is the `MACHINE-OWNED:CONCEPTS-INDEX` page marker plus the per-theme `MACHINE-OWNED:CONCEPTS-LEADIN:<theme-slug>` lead-in sentinel: a hand-authored `wiki/concepts/index.md` carrying no `CONCEPTS-INDEX` marker is never touched, and within a machine-owned page the engine authors a lead-in span only where the renderer seeded one and refreshes only a span it previously authored (`concepts_index.py render` carries an existing lead-in forward verbatim on every re-render). The deterministic renderer + per-theme lead-in model live in the `concepts_index.py` docstring; the full shape rationale (standalone page, grouped-by-theme, narrated lead-ins under MACHINE-OWNED sentinels, stage-by-default auto-refresh) is in `references/concepts-shape-decision.md`.

   **Choice-point:** DEFAULT (no flag) **stages** a proposed diff and leaves the live concepts outline untouched; `--apply-concepts` (alias `--refresh-concepts`) **applies** it. `--no-concepts` skips the whole sub-step.

   **Skip conditions (evaluated in order):**

   1. `--dry-run` was passed — silent skip (defence-in-depth; finalize already exits at Step 3 on `--dry-run`).
   2. `--no-concepts` was passed — log `Concepts refresh skipped: --no-concepts` and continue to sub-step 4.

   **(a) Build the refresh set** — the themes whose concept membership changed this run. Read `plan.json::sub_questions[].theme_label`, dedupe, and keep only those that exist as a `## <theme>` section in `wiki/concepts/index.md` (the deterministic outline `concepts_index.py` renders; a theme with no distilled concepts has no section). Empty → log `Concepts refresh skipped: nothing changed` and continue to sub-step 4. (This is the concepts-page parallel of sub-step 3.5(a); the concepts outline has no `Syntheses` catch-all category, so it is not added here.)

   **(b) Build the bundle** at `<project_path>/.metadata/concepts-bundle.txt`. Per theme in the refresh set, in `wiki/concepts/index.md` section order: a `## theme: <heading>` line, a `### current-leadin` section (the engine's existing machine lead-in for that theme — `_knowledge_lib.extract_machine_block(index_text, "CONCEPTS-LEADIN:<slugify(theme)>")`, or empty when only the placeholder is present), and a `### concepts` section (that theme's `- <summary> [[slug]]` bullets, read from the same `wiki/concepts/index.md` section, for context). The concepts outline carries no overview block (unlike the portal), so the bundle is theme-only. Build it with an inline `python3` snippet reading `wiki/concepts/index.md` (the live, deterministic page — run `concepts_index.py render` is NOT required to read it; the page already exists from prior runs, and an empty/absent page yields an empty refresh set at (a)).

   **(c) Dispatch the concepts-outliner** (fail-soft — on any agent error or no envelope, log `⚠ concepts refresh: concepts-outliner did not return; skipping (synthesis on disk)` and continue to sub-step 4):

   ```
   Task(concepts-outliner,
        BUNDLE_PATH=$PROJECT_PATH/.metadata/concepts-bundle.txt,
        RECORDS_OUTPUT_PATH=$PROJECT_PATH/.metadata/concepts-records.txt,
        OUTPUT_LANGUAGE=$OUTPUT_LANGUAGE)
   ```

   `OUTPUT_LANGUAGE` is the same value sub-step 3.5 threaded from `plan.json::output_language` (re-read it from `plan.json` if not still in hand). The agent writes raw-text records — one `- theme: <heading>` block per theme with the lead-in prose fenced between `<<<LEADIN` and a line that is exactly `LEADIN`. Parse them with an **inline** loop (NOT `_knowledge_lib.parse_portal_records` — the concepts records are theme-only, with no `- overview:` block) into `{theme: prose}`.

   **(d) STAGE (default) or APPLY (`--apply-concepts`), with an interactive confirm on human-direct runs.**

   Decide the path before writing anything:

   1. `--apply-concepts` was passed → **APPLY** (explicit intent wins; never prompt).
   2. Otherwise the default is STAGE. Decide whether to *ask first*:
      - If `--no-concepts-prompt` was passed (the autonomous `knowledge-refresh --mode push` loop sets it) — **STAGE silently**. (An empty refresh set never reaches here; (a) already skipped it.)
      - Otherwise this is a **human-direct** run with themes that changed, so surface the proposed diff and `AskUserQuestion` (single-select):

        > **Apply the proposed concepts-outline refresh to the live outline?** `<N>` engine-owned theme lead-in(s) in `wiki/concepts/index.md` will be (re)written from the concepts-outliner's records. Human (non-sentineled) concepts pages are never touched.

        Options: **Apply** → run the APPLY path below; **Stage only** → run the STAGE path below (write `concepts-index-proposed.md`, live outline untouched). This fires only on the human-direct, non-empty-refresh-set path, so the autonomous loop and every flagged run stay non-interactive. (Sub-step 3.5's portal confirm is the only other `AskUserQuestion` in finalize.)

   The two paths:

   - **STAGE** — write a human-readable `<WIKI_ROOT>/.cogni-wiki/concepts-index-proposed.md`: for each proposed theme, the heading + a `current:` block (the bundle's `### current-leadin`) and a `proposed:` block (the records prose). Do **not** write the live outline. (Inline `python3` reading `concepts-records.txt` via the (c) parse + the per-theme `current-leadin` already captured in the bundle — the concepts-page parallel of sub-step 3.5's `portal-proposed.md` write.)

   - **APPLY** — first materialise the page structure + lead-in spans under the lock, then splice each narrated lead-in into its span:

     ```
     python3 "${CLAUDE_PLUGIN_ROOT}/scripts/concepts_index.py" render \
         --wiki-root "$WIKI_ROOT" \
         --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
     ```

     `render` (re)assembles `wiki/concepts/index.md` under cogni-wiki's `_wiki_lock` + `_knowledge_lib.atomic_write_text`, carrying every existing lead-in forward and seeding a `MACHINE-OWNED:CONCEPTS-LEADIN:<theme-slug>` placeholder span for any theme that lacks one — so after this call every refresh-set theme has a span to splice into. Then, in an inline `python3` that imports `_wiki_lock` from `_wikilib` (resolved via `$WIKI_INGEST_SCRIPTS`, the `concept-store.py` posture) and acquires it, read the rendered page and for each narrated theme replace its span inner via `_knowledge_lib.upsert_machine_block(text, "CONCEPTS-LEADIN:<slugify(theme)>", prose)`, then `_knowledge_lib.atomic_write_text` the result. A theme whose prose is unchanged upserts identical text → no write churn (the renarrate no-op contract). The next finalize's `render` carries the spliced prose forward verbatim.

   **Fail-soft posture (explicit).** Sub-step 3.6 is a concepts-outline refresh. A renderer failure, a narrator no-show, a parse error, or a per-theme splice failure **never rolls back the synthesis** — the synthesis page, index entry, `entries_count` bump, `binding.json` append, `wiki/log.md` line, and sub-steps 1–3.5 are all already on disk. Surface failures loudly in Step 11 and continue. The `render` re-assembly and the span splice are **both** locked + atomic (`_wiki_lock` + `atomic_write_text`), so a forced failure leaves no partial write on the concepts page.

   **Step 11** surfaces, on STAGE: `Concepts: <N> lead-ins proposed — review <WIKI_ROOT>/.cogni-wiki/concepts-index-proposed.md, apply with --apply-concepts`; on APPLY: `✓ Concepts: <N> lead-ins refreshed`; on either skip, the corresponding skip message; on a fail-soft error, `⚠ concepts refresh FAILED — <reason>; synthesis on disk`.

3.7. **Render the syntheses sub-index (`wiki/syntheses/index.md`).** Re-render the machine-owned `wiki/syntheses/index.md` so the curated syntheses sub-index reflects the synthesis just deposited this run. This is the syntheses sibling of the `knowledge-ingest` Step 4 sources render and Step 4.5.6 questions render — the same generic deterministic renderer `knowledge-setup` seeds at bootstrap, distinct from sub-step 3.6's dedicated `concepts_index.py` lead-in refresh. The generic renderer groups each synthesis under the theme of its cited sources (`theme_via_backing_sources`, with an `Uncategorized` fallback) and reads section order from `wiki/index.md`'s `## <theme>` headings; it carries any narrator-authored `MACHINE-OWNED:SYNTHESES-LEADIN:<theme>` lead-in forward verbatim (no clobber). Run it **after** Step 7's `wiki_index_update.py` (which filed the synthesis under `## Syntheses`) — guaranteed here, since Step 10.5 runs after Steps 6/7/8.

   **Gate on `INDEX_OK=yes`** (Step 7 succeeded). On `INDEX_OK=no` the synthesis was not filed, so its sub-index is already current → skip. (Gating on `INDEX_OK` alone, not additionally on the Step 8 `--overwrite` skip: `sub_index.py` is idempotent — it writes only on a byte diff — and an `--overwrite` re-deposit can legitimately change the synthesis one-liner, so re-rendering then is correct, not churn.)

   ```
   # Only when INDEX_OK=yes — the synthesis was filed this run; the renderer is
   # idempotent (an unchanged wiki is a no-op).
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/sub_index.py" render \
       --type syntheses \
       --wiki-root "$WIKI_ROOT" \
       --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
   ```

   **Fail-soft posture (explicit).** Sub-step 3.7 is a sub-index render. A renderer failure **never rolls back the synthesis** — the synthesis page, index entry, `entries_count` bump, `binding.json` append, `wiki/log.md` line, and sub-steps 1–3.6 are all already on disk. The render is lock-wrapped (`_wiki_lock`) + atomic (`atomic_write_text`) at its own write site and writes only when the proposed text differs byte-for-byte, so a forced failure leaves no partial page. `sub_index.py` is itself fail-soft (a missing wiki-scripts dir, a `_wikilib` import failure, or a non-wiki `--wiki-root` returns an error envelope rather than raising), so treat a non-zero result as a surfaced warning, never an abort. Surface the outcome in Step 11 and continue to sub-step 3.8.

3.8. **Render the 5W1H perspectives overlay (`wiki/perspectives.md`).** Re-render the machine-owned `wiki/perspectives.md` — the derived overlay that re-projects the canonical type-first layout by perspective (Who/What/Why backed by the surviving types; When/Where/How render honestly empty) WITHOUT changing the canonical layout. It is the cross-type sibling of the per-type sub-index renders above; its counts come from the same `sub_index.theme_counts` assignment, so the overlay can never drift from the sub-indexes. Run it **after** the per-type renders (sub-step 3.7 and the `knowledge-ingest`/distill renders that filed this run's pages) so the counts it reads are current.

   Unlike sub-step 3.7 this render is **not gated on `INDEX_OK`** — the overlay re-projects whatever is on disk at finalize time (its facet counts read the per-type membership directly), so it renders every finalize run, gated only by `--dry-run`. The renderer is idempotent (an unchanged wiki is a byte-identical no-op).

   ```
   python3 "${CLAUDE_PLUGIN_ROOT}/scripts/perspectives_index.py" render \
       --wiki-root "$WIKI_ROOT" \
       --wiki-scripts-dir "$WIKI_INGEST_SCRIPTS"
   ```

   **Fail-soft posture (explicit).** Same posture as sub-step 3.7: a renderer failure **never rolls back the synthesis** (every prior write is already on disk). The render is lock-wrapped (`_wiki_lock`) + atomic (`atomic_write_text`) and writes only on a byte diff; `perspectives_index.py` returns an error envelope rather than raising on a missing wiki-scripts dir / `_wikilib` import failure / non-wiki `--wiki-root`, so treat a non-zero result as a surfaced warning, never an abort. A non-empty hand-authored `wiki/perspectives.md` (no `MACHINE-OWNED:PERSPECTIVES-INDEX` marker) is skipped (`skipped_human_page`), never clobbered. Surface the outcome in Step 11 and continue to sub-step 4.

   **Step 11** surfaces, on a change: `✓ Perspectives overlay rendered (wiki/perspectives.md)`; on a no-op: `Perspectives overlay: already current (no change)`; on a skipped human page: `Perspectives overlay: skipped (hand-authored page)`; on a fail-soft error: `⚠ perspectives overlay render FAILED — <reason>; synthesis on disk`.

4. **Rebuild `context_brief.md` (last).**
   ```
   python3 "$WIKI_INGEST_SCRIPTS/rebuild_context_brief.py" --wiki-root "$WIKI_ROOT"
   ```
   Same call shape as cogni-wiki's `wiki-ingest` Step 8.5. Runs **after** sub-steps 1–3.8 so the brief's top-entities-by-inbound-backlinks + health snapshot reflect the gate's writes (the reverse links de-orphan the cited sources; an *applied* portal or concepts-outline refresh is on disk, a *staged* one leaves the brief unchanged). Non-fatal — `context_brief.md` is a derived artefact, regenerated next dispatch.

5. **Refresh `wiki/open_questions.md`.** The persistent, cross-session data-gap backlog. cogni-wiki maintains this file as part of `wiki-lint` Step 8.5 — every lint dispatch reconciles the checklist (items that disappear from the current lint output flip to `- [x]` with today's date; closed items > 90 days old are trimmed; new findings append as `- [ ]`). The inverted pipeline writes the wiki via forked agents + direct script calls, so cogni-wiki's `wiki-lint` never runs as a gate here — sub-step 5 backfills the rebuild on the finalize path so the backlog tracks finalize-time state instead of going stale until the next interactive `wiki-lint`. It is the tail of the conformance gate: it reads the *post-fix*, *post-overview-refresh* on-disk state (the same state sub-step 2's read-only re-lint asserted), so it belongs after sub-step 4.

   Skip conditions (evaluated in order):

   1. `--dry-run` was passed — silent skip (same posture as Step 10.6; finalize already exits at Step 3 on `--dry-run`, so reaching sub-step 5 under `--dry-run` should never happen — this guard is defence-in-depth).
   2. `--no-open-questions` was passed — log `Open questions rebuild skipped: --no-open-questions` and continue.

   `--no-research-gaps` does **not** skip the sub-step — it narrows the payload. Set `NO_RESEARCH_GAPS=1` when the flag is present (else leave it unset) so the invocation below appends `--no-research-gaps` to the payload builder and only the lint findings stream.

   The rebuild consumes a **merged** findings payload: cogni-wiki's `lint_wiki.py` output (the seven existing classes about *existing* pages) **plus** this project's research-time gaps (`research_uncovered` / `research_partial`) read from the **post-ingest** coverage re-score (`<project>/.metadata/wiki-coverage-finalize.json`, produced just below; falls back to the curate-time `wiki-coverage.json` on a re-score failure). `build_open_questions_payload.py` (cogni-knowledge) does the merge in one process and emits a `{success, data: {errors, warnings, info}, meta}` envelope; `rebuild_open_questions.py --findings -` unwraps `data` and reconciles. The research gaps render as two new tail sections (`## Research-time gaps — uncovered` / `## Research-time gaps — partial`).

   **Post-ingest coverage re-score (false-gap timing fix).** The research-gap
   stream must read coverage measured **after** this run ingested its sources,
   not the curate-time `wiki-coverage.json` (written at `knowledge-curate`
   Step 0.5, *before* any source landed — so on a first run against a fresh base
   every sub-question scores `uncovered` and would deposit as a false gap even
   though the synthesis covers it). Re-run the **same** scorer against the
   now-populated wiki and write the result to a **separate**
   `wiki-coverage-finalize.json` (the curate-time file is **never overwritten** —
   `source-curator` reads it via `WIKI_COVERAGE_PATH` at its own pre-research
   meaning). Fail-soft: on any re-score failure, `COVERAGE_JSON` falls back to
   the curate-time basename so behaviour is exactly the pre-fix path.

   ```
   # Re-score coverage POST-ingest (covered sub-questions now read `covered`, so
   # they no longer stream as false uncovered gaps). Fail-soft → fall back to the
   # curate-time file on any error. Skipped under --no-research-gaps (the gap
   # stream is dropped anyway, so the re-score would be wasted work).
   COVERAGE_JSON="wiki-coverage.json"
   if [ -z "$NO_RESEARCH_GAPS" ]; then
       COVERAGE_FINALIZE_RESCORE=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/wiki-coverage.py" score \
           --wiki-root "$WIKI_ROOT" \
           --plan "$PROJECT_PATH/.metadata/plan.json" 2>/dev/null) || true
       if printf '%s' "$COVERAGE_FINALIZE_RESCORE" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("success") else 1)' 2>/dev/null; then
           printf '%s' "$COVERAGE_FINALIZE_RESCORE" > "$PROJECT_PATH/.metadata/wiki-coverage-finalize.json"
           COVERAGE_JSON="wiki-coverage-finalize.json"
       fi
   fi

   # Run ONLY after the two skip conditions above are evaluated (--dry-run,
   # then --no-open-questions). When --no-research-gaps is set, append it to the
   # payload-builder args so only the lint findings stream (the research gaps
   # are dropped, the seven existing classes still flow). --coverage-json selects
   # the POST-ingest re-score when it succeeded (else the curate-time fallback).
   #
   # Capture stdout ONLY — no 2>&1: stderr flows to the operator's terminal so a
   # crash traceback stays visible and can never contaminate the single-line
   # JSON envelope on stdout. Mirrors cogni-wiki wiki-lint Step 8.5's
   # `OQ_JSON=$(…) || true` capture exactly.
   OPEN_Q_PAYLOAD=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/build_open_questions_payload.py" \
       --wiki-root "$WIKI_ROOT" \
       --project   "$PROJECT_PATH" \
       --wiki-lint "$WIKI_LINT_SCRIPTS/lint_wiki.py" \
       --coverage-json "$COVERAGE_JSON" \
       ${NO_RESEARCH_GAPS:+--no-research-gaps})

   OPEN_Q_JSON=$(printf '%s' "$OPEN_Q_PAYLOAD" \
       | python3 "$WIKI_LINT_SCRIPTS/rebuild_open_questions.py" \
           --wiki-root "$WIKI_ROOT" \
           --findings  -) || OPEN_Q_EXIT=$?
   OPEN_Q_EXIT=${OPEN_Q_EXIT:-0}
   ```

   `build_open_questions_payload.py` is **fail-soft**: a `lint_wiki.py` crash degrades to a research-only payload (recorded in `meta.degraded`) rather than blocking the gap stream, and the envelope is always valid JSON. `rebuild_open_questions.py` then emits a single-line `{success, data, error}` envelope on stdout (stdlib-only, `_wikilib.atomic_write`-backed). On a fresh wiki where `wiki/open_questions.md` does not yet exist, the script creates it (the reconcile starts from an empty checklist). Parse and surface in Step 11:

   - `success: true` — capture `data.opened` / `data.closed` / `data.trimmed`, plus `data.opened_by_class` (the per-class split) so Step 11 can break opens into lint vs research. Step 11 surfaces `✓ Open questions: opened=<n> closed=<n> trimmed=<n>` (the `✓` matches the `✓ wiki-health clean` marker on the adjacent conformance-gate line so an operator scanning the summary need not grep for the absence of `⚠`).
   - `success: false` — surface `⚠ open_questions rebuild FAILED — <error>; synthesis on disk; re-run cogni-wiki:wiki-lint manually` and continue.
   - `OPEN_Q_EXIT != 0` or malformed JSON — same template, `<error>` substituted by `script exit <code>` / `malformed JSON envelope`.

   **Close-attribution.** `finalize` is one of `rebuild_open_questions.py`'s `CLOSING_OPS` (`update`, `ingest`, `re-ingest`, `synthesis`, `finalize`). Since the post-ingest re-score (above), a sub-question this run **actually covered** scores `covered` and so is **absent** from the incoming stream — it is never deposited as a `- [ ] \`sq:<sq_id>\`` gap in the first place (the prior design opened then credit-closed it across two dispatches, surfacing every covered sub-question as a transient open gap and polluting the closed list with never-genuine items). Only a sub-question the pipeline **genuinely failed to cover** post-ingest streams as an open gap. The credit-close mechanism still attributes correctly for any genuine gap that a *later* run covers: `reconcile` closes an old open item the moment it leaves the incoming stream (`old` − `incoming`), and `attribute_close` scans `wiki/log.md` for the bare `<sq_id>` inside a finalize line's `sqs=` suffix to render `- [x] ~~\`sq:<sq_id>\` — …~~ — closed <date> by finalize`. The Step 10 `sqs=` suffix therefore deliberately keeps reading the **curate-time** `wiki-coverage.json` (via `gap_sq_ids_from_coverage`'s default) — it must name the curate-gaps that flipped to covered so their eventual close is attributed to finalize; pointing it at the post-ingest file would name still-uncovered sub-questions (which never close) and miss the covered ones. No second `wiki/log.md` line is written here (the Step 10 line is already on disk). A revisor pass that drops a sub-question's coverage is self-correcting — a later curate/finalize re-opens the gap per `reconcile`'s re-appearing-key semantics.

   **Fail-soft posture (explicit).** Sub-step 5 is a backlog refresh. A non-zero exit, malformed envelope, or `_wiki_lock` contention **never rolls back the synthesis** — the synthesis page, index entry, `entries_count` bump, `binding.json` append, `wiki/log.md` line, and sub-steps 1–4 are all already on disk. The summary surfaces the failure loudly so the operator can run `cogni-wiki:wiki-lint` manually; the next finalize dispatch reconciles. (Verbatim mirror of cogni-wiki Step 8.5's failure-isolation contract; matches Step 10.6's posture.)

   **Concurrency note.** `rebuild_open_questions.py` wraps the parse + reconcile + render + atomic write in `_wikilib._wiki_lock(wiki_root)`, so a concurrent `cogni-wiki:wiki-lint` dispatch from another session serialises rather than corrupts — the two dispatches converge on the on-disk lint findings only (which is the contract).

### 10.6 Contradiction tripwire

Observability-only. Dispatches the `wiki-contradictor` agent, which runs TWO comparison passes off one sentence-split of the just-deposited synthesis body and emits a single per-finalize `<project_path>/.metadata/contradictor-v<N>.json` envelope (schema `0.1.0`) with `kind ∈ {contradiction, unknown}` and `severity ∈ {high, medium, low}`:

- **Pass A (synthesis-vs-cited)** — the synthesis sentence-by-sentence against each cited *source / distilled / question* page's claim frontmatter (`pre_extracted_claims:` on `wiki/sources/<slug>.md`; `distilled_claims:` on the two distilled dirs `wiki/{concepts,entities}/<slug>.md`; `answer_claims:` on `wiki/questions/<slug>.md`). A distilled/answer finding carries a `dcl-NNN`/`acl-NNN` `conflicting_claim_id`. Driven by `CITED_SOURCE_SLUGS`.
- **Pass B (synthesis-vs-prior-syntheses)** — the same synthesis sentences against the assertive sentences of each prior `wiki/syntheses/<slug>.md` page (its own page excluded). Syntheses carry no claim block, so a Pass B finding carries `conflicting_claim_id: null` and a synthesis-slug `conflicting_page`. Driven by `PRIOR_SYNTHESIS_SLUGS`.

**Partially defends `references/differentiation-thesis.md` Pillar 2 at synthesis-write time.**

**Fail-soft posture (explicit).** Step 10.6 is observability-only. A Task failure, schema mismatch, or malformed envelope **never rolls back the synthesis** — surfaces in Step 11 as `⚠ contradiction tripwire FAILED — synthesis on disk; re-run interactive cogni-wiki:wiki-lint for forensic detail`. The synthesis already landed at Steps 6–10; the contradictor is a read-only observation layer.

**Skip conditions (evaluated in order).** The orchestrator skips dispatch (and writes no JSON) when any of these hold:

1. `--dry-run` was passed — same posture as Step 4's cycle-guard dry-run skip. Silent.
2. `--no-contradictor` was passed — log `Contradiction tripwire skipped: --no-contradictor` and continue. (Kills BOTH passes; `--no-prior-syntheses` is the narrower opt-out that suppresses only Pass B.)
3. **BOTH** `len(cited_source_slugs) == 0` **AND** `len(prior_synthesis_slugs) == 0` — there is nothing to compare on either pass (`cited_source_slugs` is the Step 5/6 filtered claim-bearing list where `page_kind_by_slug[slug] ∈ {source, concept, entity, question}`; `prior_synthesis_slugs` is the Step 10.6 enumeration below, empty under `--no-prior-syntheses` or on the first synthesis in a base — **compute that enumeration block first, then evaluate this skip against its result**; do NOT short-circuit to a skip on an empty `cited_source_slugs` alone, or a 2nd+ synthesis with no claim-bearing cited peers would wrongly skip Pass B). Log `Contradiction tripwire skipped: no claim-bearing cited peers and no prior syntheses to compare` and continue. A non-empty *either* list dispatches the agent — a synthesis that cites zero claim-bearing pages but is the 2nd+ synthesis in a base now runs Pass B alone (the agent tolerates an empty `CITED_SOURCE_SLUGS`).

**Convert the captured Step 5/6 output into dispatch inputs.** `COMPOSE_JSON` was already captured (heredoc-quoted) right after the Step 5/6 subprocess — reuse it here; do not re-capture. Extract the contradictor inputs by piping it through `python3` (mirror the Step 2 pattern). `cited_source_slugs` is a JSON array — join to a comma-separated string for the agent's CSV input. Truncate at 30 entries (manifest first-appearance order is preserved by the Step 5/6 builder), surfacing the original size as `N_CITED_PRE_TRUNCATION` for Step 11 (the Step 9 refresh-candidate clear uses the **untruncated** `CITED_SOURCE_SLUGS_FULL_CSV` from that same capture — this 30-cap is the contradictor surface only):

```
OUTPUT_LANGUAGE=$(printf '%s' "$COMPOSE_JSON" | python3 -c '
import json, sys
print((json.loads(sys.stdin.read()).get("output_language") or "en"))
')
N_CITED_PRE_TRUNCATION=$(printf '%s' "$COMPOSE_JSON" | python3 -c '
import json, sys
print(len(json.loads(sys.stdin.read()).get("cited_source_slugs") or []))
')
CONTRADICTOR_MAX_SOURCES=30
CITED_SOURCE_SLUGS_CSV=$(printf '%s' "$COMPOSE_JSON" | CAP="$CONTRADICTOR_MAX_SOURCES" python3 -c '
import json, os, sys
slugs = (json.loads(sys.stdin.read()).get("cited_source_slugs") or [])[: int(os.environ["CAP"])]
print(",".join(slugs))
')
```

Slugs are kebab-case-only by `_knowledge_lib.slugify` (transliterated, NFKD-folded, `[a-z0-9-]+` only) so the CSV is safe against embedded commas, backslashes, or quotes — `_knowledge_lib.slugify` is the structural guarantor.

`N_CITED_PRE_TRUNCATION` is the pre-truncation count Step 11 needs to render `truncated at 30/<N>`; `CITED_SOURCE_SLUGS_CSV` is the post-truncation CSV the agent receives. Both stay shell variables for the dispatch + summary.

**Input cap surface.** If `N_CITED_PRE_TRUNCATION > 30`, the CSV above is already truncated; Step 11 surfaces `⚠ contradiction tripwire truncated at 30/$N_CITED_PRE_TRUNCATION pages`. The cap counts source + distilled + question slugs combined. The agent never sees the dropped slugs and does NOT emit a `truncated_at` field — truncation is observable only via the Step 11 line (envelope `compared_against.sources[]` records exactly what was scored — source + distilled + question slugs, key name retained for schema stability).

**Enumerate the prior syntheses (Pass B corpus).** The synthesis was deposited at Step 6, so it is already on disk under `wiki/syntheses/`; glob that dir, exclude the just-deposited page by slug, sort most-recent-first by mtime, and cap at `PRIOR_SYNTHESIS_MAX=20`. The slugs are filename stems (kebab-safe by construction), so the CSV is shell-safe like `CITED_SOURCE_SLUGS_CSV`. Under `--no-prior-syntheses`, force both vars empty/zero (Pass B suppressed; the agent runs Pass A only):

```
PRIOR_SYNTHESIS_MAX=20
if [ -n "$NO_PRIOR_SYNTHESES" ]; then
    PRIOR_SYNTHESIS_SLUGS_CSV=
    N_PRIOR_PRE_TRUNCATION=0
else
    PRIOR_ENUM_JSON=$(WIKI_ROOT="$WIKI_ROOT" SELF_SLUG="$SYNTHESIS_SLUG" CAP="$PRIOR_SYNTHESIS_MAX" python3 -c '
import json, os
from pathlib import Path
syn_dir = Path(os.environ["WIKI_ROOT"]) / "wiki" / "syntheses"
self_slug = os.environ["SELF_SLUG"]
cap = int(os.environ["CAP"])
pages = []
if syn_dir.is_dir():
    for p in syn_dir.glob("*.md"):
        if p.stem == self_slug:
            continue
        try:
            mtime = p.stat().st_mtime
        except OSError:
            continue
        pages.append((mtime, p.stem))
# most-recent-first; tie-break on slug for determinism
pages.sort(key=lambda t: (-t[0], t[1]))
slugs = [stem for _, stem in pages]
print(json.dumps({"n_total": len(slugs), "slugs": slugs[:cap]}))
')
    N_PRIOR_PRE_TRUNCATION=$(printf '%s' "$PRIOR_ENUM_JSON" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["n_total"])')
    PRIOR_SYNTHESIS_SLUGS_CSV=$(printf '%s' "$PRIOR_ENUM_JSON" | python3 -c 'import json,sys; print(",".join(json.loads(sys.stdin.read())["slugs"]))')
fi
```

`NO_PRIOR_SYNTHESES` is set (to `1`) when `--no-prior-syntheses` was passed, else unset. `N_PRIOR_PRE_TRUNCATION` is the pre-cap count Step 11 needs to render `truncated at 20/<N>`; `PRIOR_SYNTHESIS_SLUGS_CSV` is the post-cap CSV the agent receives. If `N_PRIOR_PRE_TRUNCATION > 20`, Step 11 surfaces `⚠ prior-synthesis comparison truncated at 20/$N_PRIOR_PRE_TRUNCATION` (its own independent line, mirroring the cited-cap line).

**Dispatch.** A single `Task` call — the agent runs both passes in one dispatch off one body-split.

```
Task(wiki-contradictor,
     WIKI_ROOT=$WIKI_ROOT,
     PROJECT_PATH=$PROJECT_PATH,
     SYNTHESIS_PAGE_PATH=$WIKI_ROOT/wiki/syntheses/$SYNTHESIS_SLUG.md,
     CITED_SOURCE_SLUGS=$CITED_SOURCE_SLUGS_CSV,
     PRIOR_SYNTHESIS_SLUGS=$PRIOR_SYNTHESIS_SLUGS_CSV,
     OUTPUT_LANGUAGE=$OUTPUT_LANGUAGE,
     DRAFT_VERSION=$DRAFT_VERSION,
     CONTRADICTOR_OUT_PATH=$PROJECT_PATH/.metadata/contradictor-v$DRAFT_VERSION.json)
```

`OUTPUT_LANGUAGE` is the same value Step 5/6 already threaded from `plan.json::output_language` via the subprocess JSON line (so the agent operates in the synthesis's language and never translates — bilingual coverage is out of scope). `CITED_SOURCE_SLUGS` may be empty (Pass A skipped) when the manifest had no claim-bearing peers but prior syntheses exist; `PRIOR_SYNTHESIS_SLUGS` may be empty (Pass B skipped) on the first synthesis in a base or under `--no-prior-syntheses`. The skip-condition-3 guarantee is that at least one of the two is non-empty whenever the agent is dispatched.

**Interpret return.**

- **`ok: true`** — capture `counts.high`, `counts.medium`, `counts.low`, `counts.unknown`, `counts.total`, the top-3 `high`-severity findings (or all of them if `counts.high <= 3`), `compared_against.missing_pages[]` (for the optional Step 11 TOCTOU note), `compared_against.prior_synthesis_count` (for the Step 11 split), and the full `cost_estimate` object (`input_words`, `output_words`, `estimated_usd`) — Step 11's cost template needs all three. **Cited-vs-prior split for the Step 11 header:** read the written `contradictor-v<N>.json::findings[]` and partition each finding by **`conflicting_page` membership** — a finding is Pass B (prior-synthesis) iff its `conflicting_page` is in `compared_against.prior_syntheses[]`, otherwise Pass A (cited, i.e. `conflicting_page ∈ compared_against.sources[]`). The two slug sets are disjoint by page kind (cited = source/distilled/question pages; prior = synthesis pages), so the partition is exact. (Page membership is the robust discriminator — a Pass A `unknown` finding can legitimately carry `conflicting_claim_id: null`, so claim-id null-ness alone would misroute it; null-ness only happens to coincide with Pass B for well-formed findings.) Derive `n_cited`/`h_cited` (Pass A total / Pass A `severity == high`) and `n_prior`/`h_prior` (Pass B total / Pass B high). This reads the same envelope Step 11 already opens for the top-3 `high` detail bullets — no schema change to `counts`.
- **`ok: false, error: synthesis_unreadable`** — surface `⚠ contradiction tripwire FAILED — synthesis_unreadable: <reason>; synthesis on disk; re-run cogni-wiki:wiki-lint manually` in Step 11. Never block.
- **`ok: false, error: write_failed`** — surface `⚠ contradiction tripwire FAILED — write_failed (output token budget likely exhausted); synthesis on disk; re-run cogni-wiki:wiki-lint manually` in Step 11. Never block.
- **Task dispatch error / no envelope returned** — same fail-soft posture: surface `⚠ contradiction tripwire FAILED — Task dispatch did not return; synthesis on disk` and continue to Step 11.

**Idempotency.** Re-finalize on the same `draft_version` overwrites `contradictor-v<N>.json` — see `## Edge cases` for the full rule (`Re-finalize on the same draft (contradictor idempotency)`).

### 10.7 Structural-quality review

The structural-quality half of the cogni-research feature-parity gate. Step 10.6 (and Phase 6) check **citation-claim alignment** — does each cited sentence match the cited page's claims. This step checks **structural quality** — does the draft address every sub-question, flow coherently, draw on diverse publishers, go deep, and read cleanly in its output language. A synthesis can pass verify (every citation aligned) and still fail structural review (a sub-question treated in one shallow paragraph). Dispatches the `wiki-reviewer` agent to score the draft on the same 5 weighted dimensions cogni-research's reviewer scores (Completeness 0.25, Coherence 0.20, Source-Diversity 0.20, Depth 0.20, Clarity 0.15, with an inline citation-density gate that caps Depth and — #309 P2 — an advisory Word Count Gate that caps Completeness on a `standard`-density deficit / `executive`-density excess) and emit `<project_path>/.metadata/structural-review-v<N>.json` (schema `0.1.1`).

**Advisory-only, fail-soft posture (explicit).** Step 10.7 is observability-only. The reviewer's verdict is **advisory** — a `revise` verdict here drives **no** content-expansion fix loop *from finalize* and **never rolls back the synthesis**. The bounded zero-network floor-expansion runs **earlier, in `knowledge-compose` Step 5.5** (before verify), so under `standard` density a real word-floor deficit has typically already been closed by deposit time; this reviewer is the advisory **backstop** that records whether the draft cleared the floor, not the actuator. A Task failure, schema mismatch, or malformed envelope surfaces in Step 11 as `⚠ structural review FAILED — synthesis on disk; advisory only` and never blocks. The synthesis already landed at Steps 6–10; the reviewer is a read-only scoring layer (same posture as Step 10.6).

**Skip conditions (evaluated in order).** The orchestrator skips dispatch (and writes no JSON) when any of these hold:

1. `--dry-run` was passed — finalize already exits at Step 3 on `--dry-run`, so this is defence-in-depth. Silent.
2. `--no-reviewer` was passed — log `Structural review skipped: --no-reviewer` and continue.

(There is no empty-manifest skip — the reviewer scores the draft prose, which exists even when the citation manifest is empty.)

**Resolve `OUTPUT_LANGUAGE` + the Word-Count-gate inputs (self-contained, independent of Step 10.6).** Read them directly from `plan.json` so this step does not depend on whether the contradictor ran. `TARGET_WORDS` + `PROSE_DENSITY` feed the reviewer's advisory Word Count Gate (#309 P2):

```
REVIEW_PLAN_JSON=$(PLAN_PATH="$PROJECT_PATH/.metadata/plan.json" python3 -c '
import json, os
from pathlib import Path
try:
    p = json.loads(Path(os.environ["PLAN_PATH"]).read_text(encoding="utf-8"))
except Exception:
    p = {}
# target_words coercion is guarded separately so a hand-edited non-numeric value
# falls back to 2000 instead of crashing this resolution subprocess (the reviewer
# also defaults it, but a crash here would blank all three shell vars).
try:
    tw = int(p.get("target_words") or 2000)
    if tw <= 0:
        tw = 2000
except (TypeError, ValueError):
    tw = 2000
print(json.dumps({
    "output_language": (p.get("output_language") or "en"),
    "target_words": tw,
    "prose_density": (p.get("prose_density") or "standard"),
}))
')
OUTPUT_LANGUAGE=$(printf '%s' "$REVIEW_PLAN_JSON" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["output_language"])')
TARGET_WORDS=$(printf '%s' "$REVIEW_PLAN_JSON" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["target_words"])')
PROSE_DENSITY=$(printf '%s' "$REVIEW_PLAN_JSON" | python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["prose_density"])')
```

**Dispatch.**

```
Task(wiki-reviewer,
     PROJECT_PATH=$PROJECT_PATH,
     DRAFT_PATH=$PROJECT_PATH/output/draft-v$DRAFT_VERSION.md,
     PLAN_PATH=$PROJECT_PATH/.metadata/plan.json,
     INGEST_MANIFEST_PATH=$PROJECT_PATH/.metadata/ingest-manifest.json,
     OUTPUT_LANGUAGE=$OUTPUT_LANGUAGE,
     TARGET_WORDS=$TARGET_WORDS,
     PROSE_DENSITY=$PROSE_DENSITY,
     REVIEW_ITERATION=1,
     DRAFT_VERSION=$DRAFT_VERSION,
     REVIEW_OUT_PATH=$PROJECT_PATH/.metadata/structural-review-v$DRAFT_VERSION.json)
```

The reviewer scores `output/draft-v<N>.md` (the project draft) — the deposited synthesis differs only by frontmatter + reference renumber, and the structural dimensions are draft-level. `OUTPUT_LANGUAGE` makes the agent score Clarity natively and exclude the right reference heading from the density gate (never translates — bilingual scoring is out of scope here, same posture as Step 10.6). `TARGET_WORDS` + `PROSE_DENSITY` drive the **advisory** Word Count Gate (deficit under standard / excess under executive) — which caps Completeness and emits a `Word deficit`/`Word excess` issue but never blocks. There is no expansion loop *from finalize*; under `standard` density the bounded floor-expansion already ran earlier, in `knowledge-compose` Step 5.5, so this gate is the advisory backstop.

**Interpret return.**

- **`ok: true`** — capture `verdict`, `score`, `issue_count`, `high_severity_count`, the per-dimension `structural_scores`, and the full `cost_estimate` object (`input_words`, `output_words`, `estimated_usd`) for Step 11.
- **`ok: false, error: synthesis_unreadable`** — surface `⚠ structural review FAILED — synthesis_unreadable: <reason>; synthesis on disk; advisory only` in Step 11. Never block. (Most common cause: a draft below the 200-word floor.)
- **`ok: false, error: write_failed`** — surface `⚠ structural review FAILED — write_failed (output token budget likely exhausted); synthesis on disk; advisory only` in Step 11. Never block.
- **Task dispatch error / no envelope returned** — same fail-soft posture: surface `⚠ structural review FAILED — Task dispatch did not return; synthesis on disk` and continue to Step 11.

**Idempotency.** Re-finalize on the same `draft_version` overwrites `structural-review-v<N>.json` (same convention as `verify-v<N>.json` / `contradictor-v<N>.json`). The reviewer's scores may vary slightly across re-runs (LLM judgement); the verdict is advisory, so cross-run variance carries no downstream consequence.

### 11. Final summary

Print ≤ 13 lines (the verbatim/paraphrase ratio, the contradiction-tripwire block, and the structural-review block are all conditional — the common-case base summary is ~10 lines, both verification lines included; the open-questions line adds one; a clean-`accept` structural review is silent):

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Synthesis page: `wiki/syntheses/<slug>.md` (sources cited: `<N_SOURCES>`)
- Research questions (Step 4.7): on `n_question_links > 0`, `✓ Research questions linked: <n>` (the synthesis body gained a `## Research questions` section; each linked question page gains a `[[<synthesis-slug>]]` reverse link via the Step 10.5 gate). On an empty manifest / legacy project / `--no-question-links`, `Research questions: none (legacy project / no manifest / opted out)`.
- Cycle-guard: `input_shape=citation-manifest`, `direct_self_cycles=0`, `cross_lineage_overlap=<N>`
- Verify lineage: `verify-v<N>.json` — verbatim=`<N>` paraphrase=`<N>` synthesis=`<N>` unsupported=`<N>` (round `<R>` of 2)
- Verification: citation-consistent (zero-network, no live-source re-check). The synthesis-page frontmatter carries `verification: citation_consistent_zero_network` + `verification_ratio:`. For live-source ground-truth, run `/cogni-knowledge:knowledge-refresh --resweep` (opt-in).
- Verbatim/paraphrase ratio (print this line **only when `verbatim + paraphrase > 0`** — no divide-by-zero on a deviation-only run): `<V>/<P> = <pct>% verbatim`, where `pct = round(100 * V / (V + P), 1)`. Append ` (high copy-paste — consider revising for synthesis density)` **only when `V / (V + P) > 0.5`** — i.e. a *majority* of scored citations are verbatim, the point at which copy-paste outweighs synthesis (informational nudge, no gate; tune the 0.5 majority threshold here if real runs prove it noisy). When `verbatim + paraphrase == 0`, print `Verbatim/paraphrase ratio: (no scored verdicts)` instead.
- Binding: total deposited projects now `<count>`
- Wiki updates (conditional on Step 7 + Step 8 outcomes):
  - On `INDEX_OK=yes` + new deposit: `index.md (Syntheses), entries_count +1, context_brief.md refreshed`
  - On `INDEX_OK=yes` + `--overwrite` re-deposit: `index.md (Syntheses) updated, entries_count unchanged (overwrite), context_brief.md refreshed`
  - On `INDEX_OK=no`: `⚠ index.md FAILED — synthesis on disk but NOT yet indexed; run wiki-lint --fix=entries_count_drift (and re-run finalize against the existing page if you also want the index entry); context_brief.md refreshed`
- Conformance gate (Step 10.5): `wiki-lint --fix=all → <F> fixed, <X> failed; wiki-health → <E> errors`. On `<E> == 0`: `✓ wiki-health clean`. On `<E> > 0`: `⚠ wiki-health: <E> error(s) after finalize: <class> on <page>, …` (loud, non-fatal). Plus `overview.md refreshed`.
- Portal (Step 10.5 sub-step 3.5): on STAGE (default), `Portal: <N> lead-ins + overview proposed — review <WIKI_ROOT>/.cogni-wiki/portal-proposed.md, apply with --apply-portal`; on STAGE **with the first-authoring carve-out fired** (the overview narrative was auto-spliced live this run — same line on the silent `--no-portal-prompt` autonomous path, the lead-ins genuinely remain staged), `✓ Portal: overview narrative authored (first finalize); <N> lead-in(s) proposed — review <WIKI_ROOT>/.cogni-wiki/portal-proposed.md, apply with --apply-portal`; on APPLY (`--apply-portal`), `✓ Portal: <N> lead-ins refreshed + overview spliced`; on `--no-portal` / nothing-grew / `--dry-run`, the corresponding skip message; on a fail-soft error, `⚠ portal refresh FAILED — <reason>; synthesis on disk` (loud, non-fatal).
- Concepts (Step 10.5 sub-step 3.6): on STAGE (default), `Concepts: <N> lead-ins proposed — review <WIKI_ROOT>/.cogni-wiki/concepts-index-proposed.md, apply with --apply-concepts`; on APPLY (`--apply-concepts`), `✓ Concepts: <N> lead-ins refreshed`; on `--no-concepts` / nothing-changed / `--dry-run`, the corresponding skip message; on a fail-soft error, `⚠ concepts refresh FAILED — <reason>; synthesis on disk` (loud, non-fatal).
- Syntheses sub-index (Step 10.5 sub-step 3.7): on `INDEX_OK=yes`, `✓ Syntheses sub-index re-rendered (wiki/syntheses/index.md)`; on `INDEX_OK=no`, `Syntheses sub-index skipped (no new synthesis row)`; on a fail-soft error, `⚠ syntheses sub-index render FAILED — <reason>; synthesis on disk` (loud, non-fatal).
- Perspectives overlay (Step 10.5 sub-step 3.8): on a change, `✓ Perspectives overlay rendered (wiki/perspectives.md)`; on a no-op, `Perspectives overlay: already current (no change)`; on a skipped hand-authored page, `Perspectives overlay: skipped (hand-authored page)`; on a fail-soft error, `⚠ perspectives overlay render FAILED — <reason>; synthesis on disk` (loud, non-fatal).
- Open questions (Step 10.5 sub-step 5): on `success: true`, `✓ Open questions: opened=<n> closed=<n> trimmed=<n>` (the `✓` mirrors the `✓ wiki-health clean` marker above). **When research-time gaps were in play this dispatch** (sum of `data.opened_by_class["research_uncovered"]` + `data.opened_by_class["research_partial"]` > 0), append the split: `✓ Open questions: opened=<n> closed=<n> trimmed=<n> (lint=<L>, research=<R>)`, where `R` is that research sum and `L` is `opened - R`. Omit the parenthetical when `R == 0`. On `success: false` / non-zero exit / malformed JSON, `⚠ open_questions rebuild FAILED — <error>; synthesis on disk; re-run cogni-wiki:wiki-lint manually` (loud, non-fatal). On `--no-open-questions` skip, print the corresponding skip message (per Step 10.5 sub-step 5).
- Contradiction tripwire (Step 10.6): print this block **only on `ok: true` AND (`counts.high > 0` OR `counts.unknown > 0`)** — clean successful runs are silent (no false-alarm noise). On `ok: false` use the FAILED branch below; on skip use the skip-message branch below. Each branch is its own independent surface — gating is per-branch, not joint:
  ```
  ⚠ Contradiction tripwire: <n_cited> vs cited evidence (<h_cited> high), <n_prior> vs prior syntheses (<h_prior> high), <U> unknown — observability-only
    - <sanitized_synthesis_excerpt[:80]>...
      ~ <conflicting_page> (high) — <sanitized_note[:60]>
    - <sanitized_synthesis_excerpt[:80]>...
      ~ <conflicting_page> (high) — <sanitized_note[:60]>
  Detail in <project_path>/.metadata/contradictor-v<N>.json.
  Reconcile via cogni-wiki:wiki-update --page <synthesis-slug> --reason contradiction.
  Cost: $<estimated_usd> (<input_words>w in / <output_words>w out).
  ```
  The header splits the findings into the two families using the cited-vs-prior partition captured at Step 10.6 (a finding is prior-synthesis iff its `conflicting_page ∈ compared_against.prior_syntheses[]`): `n_cited`/`h_cited` are the Pass A total / high counts, `n_prior`/`h_prior` the Pass B total / high counts, and `U` is the single envelope-wide `counts.unknown` (already counted inside the `n_cited`/`n_prior` family totals — `n_cited + n_prior == counts.total` and includes every unknown, so `U` is surfaced separately only as an at-a-glance signal, never a disjoint bucket to add on top). (When `n_prior == 0` — no prior syntheses compared — the `vs prior syntheses` segment still prints `0 (0 high)`, which an operator reads as "no prior-synthesis conflicts," not as a missing surface.) Surface only the top 3 `high`-severity findings by name (across both families, most-severe-first), each labelled by its `conflicting_page` so a prior-synthesis slug is self-evident; `medium`/`low` are **not** broken out on the header line — the per-family `n_cited`/`n_prior` totals fold them in (each is a family total of `contradiction` + `unknown`), so the operator reads `contradictor-v<N>.json` for the per-severity breakdown. `<sanitized_synthesis_excerpt>` / `<sanitized_note>` are the agent's verbatim strings with **backtick / pipe / CR / LF** all replaced by a single space — pass each through `tr '\r\n`|' '    '` (four-character set, four spaces — preserves column width) so a sentence containing inline code, a literal pipe (e.g. in a markdown-table fragment), or an embedded newline does not break the bullet structure. Same discipline-shape as the `TOPIC` `tr '\r\n' '  '` already used at Step 10 for the log line — extended to the two additional markdown-break risk characters that Step 11's bullets carry. `<input_words>` / `<output_words>` come from `cost_estimate.input_words` / `cost_estimate.output_words` captured at Step 10.6.

  Independent branches (not gated on `high`/`unknown`):
  - On `ok: true` AND `compared_against.missing_pages` is non-empty, append one extra line: `⚠ contradiction tripwire: <K> page(s) missing on disk at compare time (TOCTOU vs Step 6 deposit): <slug1>, <slug2>, …` — the agent best-effort scored the survivors (a missing page may be a cited page or a prior synthesis); the operator may want to investigate concurrent wiki maintenance.
  - On `N_CITED_PRE_TRUNCATION > 30`, append: `⚠ contradiction tripwire truncated at 30/$N_CITED_PRE_TRUNCATION pages (hard cap)`.
  - On `N_PRIOR_PRE_TRUNCATION > 20`, append: `⚠ prior-synthesis comparison truncated at 20/$N_PRIOR_PRE_TRUNCATION (hard cap)` — independent of the cited-cap line above; both can fire on a large base.
  - On `--no-contradictor` / both-empty skip (skip-condition 3), print the corresponding skip message verbatim (per Step 10.6). One skip message per run; if multiple skip conditions hold, the SKILL evaluates them in order and the first-matching message wins (early-exit posture). `--no-prior-syntheses` is NOT a skip — the agent still runs Pass A; it simply produces no `vs prior syntheses` findings (the header segment reads `0 (0 high)`).
  - On `ok: false`, print `⚠ contradiction tripwire FAILED — <reason>; synthesis on disk` (loud, non-fatal — same posture as the wiki-health failure path).
- Structural review (Step 10.7): print this block **only on `ok: true` AND (`verdict == "revise"` OR `high_severity_count > 0`)** — a clean `accept` with no high-severity issues is silent (no noise). On `ok: false` use the FAILED branch below; on skip use the skip-message branch:
  ```
  ⚠ Structural review: score=<score> (verdict=<verdict>) — <high_severity_count> high-severity of <issue_count> issue(s); advisory only
    completeness=<c> coherence=<co> source_diversity=<sd> depth=<d> clarity=<cl>
  Detail in <project_path>/.metadata/structural-review-v<N>.json. Advisory — finalize did not block; re-run cogni-knowledge:knowledge-compose to address, or accept as-is.
  Cost: $<estimated_usd> (<input_words>w in / <output_words>w out).
  ```
  The per-dimension line reads the five `structural_scores` values. `<estimated_usd>` / `<input_words>` / `<output_words>` come from the `cost_estimate` captured at Step 10.7.

  Independent branches:
  - On `--no-reviewer` skip, print the corresponding skip message verbatim (per Step 10.7).
  - On `ok: false`, print `⚠ structural review FAILED — <reason>; synthesis on disk; advisory only` (loud, non-fatal — same posture as the contradiction-tripwire failure path).
- Next: `cogni-wiki:wiki-query --wiki-root <WIKI_ROOT>` already reads the new synthesis as part of the corpus.

If Step 2 surfaced `unsupported > 0`, repeat the `⚠ Finalized with <N> unsupported citations` warning so the audit trail is on-screen.

### 12. Record run metrics (phase-exit ledger)

Persist this phase's timing + cost to `<project_path>/.metadata/run-metrics.json` so the run leaves a durable per-phase ledger (read by `knowledge-resume` / `knowledge-dashboard` / a perf study). Capture `PHASE_START=$(date -u +%FT%TZ)` at the top of this skill's run (Step 0); then at exit:

```
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/run-metrics.py" record \
    --project-path "<project_path>" --phase finalize \
    --started-at "$PHASE_START" --ended-at "$(date -u +%FT%TZ)" \
    --agent-count <optional agents dispatched: contradictor + reviewer + portal/concepts narrators> \
    --cost-usd <summed cost_estimate.estimated_usd across those agents, default 0>
```

This row closes the per-project ledger; `run-metrics.py report --project-path <project_path>` then renders the full plan→finalize timeline. Fail-soft — a record failure never blocks the deposit. Full contract: `${CLAUDE_PLUGIN_ROOT}/references/run-metrics-wiring.md`.

## Edge cases

- **Re-run on an already-finalized project.** `<WIKI_ROOT>/wiki/syntheses/<slug>.md` exists — abort with the `--overwrite` nudge. If `--overwrite`, the synthesis page is rewritten but `config_bump.py --delta 1` would over-count; pass `--overwrite` only when the previous synthesis page is being replaced after a hand-edit, and reconcile entries_count via `wiki-lint --fix=entries_count_drift` afterward.
- **No citations in the manifest.** Steps 5–6 still produce a synthesis page; the `## References` block becomes `_No external citations recorded in citation-manifest.json._`. cycle-guard's `wiki_pages_cited` will be `[]` and `status: clear` — surface in Step 11.
- **Plan.json missing topic.** Step 3 falls back to `--synthesis-slug` if passed, else aborts cleanly.
- **Cited source page missing on disk.** Step 5's reference-row falls back to the slug as the title AND emits **no** `[[<slug>]]` backlink (a bare link to a missing page would be a `broken_wikilink` error that fails the Step 10.5 health gate). cycle-guard's `wiki_pages_cited_missing` will list the slug; surface in Step 11 as `⚠ Missing pages: <slug1>, <slug2>` so the operator knows the wiki was modified between ingest and finalize.
- **Duplicate binding entry without `--overwrite`.** Step 9's `append-project` returns `existing_slug` (the SKILL did NOT pass `--allow-update` because `--overwrite` was off). Steps 6–8 already landed the synthesis page → the wiki has the new page but `binding.json::research_projects[]` still records the prior deposit's `report_path` / `deposited_at`. Step 11 surfaces the loud `⚠ Binding append SKIPPED` warning verbatim from Step 9. Reconcile via `--overwrite` re-run (which passes `--allow-update` per Step 9's contract), or accept the asymmetric state — both are valid operator decisions.
- **Re-finalize on the same draft (contradictor idempotency).** Re-running finalize with `--overwrite` against the same `draft_version` overwrites `<project_path>/.metadata/contradictor-v<N>.json` (same convention as `verify-v<N>.json`). The agent is non-deterministic across runs at two distinct layers: (1) `findings[].id` (`ctr-NNN`) is stable WITHIN one envelope but may renumber across re-runs (emission order ≠ index order); (2) the **finding set itself may differ** — a re-run can legitimately surface a contradiction the prior run missed, or drop one the prior run flagged as `low` on doubt. The "same contradictions re-surface on each re-run" guidance applies to clear-cut `high` flips; `medium`/`low`/`unknown` carry expected cross-run variance.
- **Re-finalize on the same draft (open-questions idempotency).** `rebuild_open_questions.py` is a locked read-modify-write that reconciles against the existing checklist — a re-finalize produces a delta but is never net-destructive. Items closed by a prior dispatch keep their original `closed_on` date; only items closed > 90 days ago are trimmed. The lock at `<WIKI_ROOT>/.cogni-wiki/.lock` is the same one cogni-wiki's `wiki-lint` Step 8.5 acquires.

## Out of scope

- Does NOT re-run the verifier, the composer, or the ingester. Finalize reads the latest verified draft + manifest as-is.
- Renders a **numbered** reference list keyed off `plan.json::citation_format` — `ieee` (`**[N]** Publisher, "Title". [URL](URL) — [[<slug>]]`) and `chicago` (`**[N]** Publisher. "Title." …`, period-separated) both render end-to-end, first-appearance order matching the composer's inline `[N]`. The reference backlink is a **bare** `[[<slug>]]` (not path-prefixed `[[sources/<slug>]]`) so the synthesis→source edge registers in cogni-wiki's link graph. Does NOT yet render **author-date** `apa`/`mla`/`harvard` — those are accepted + persisted but fall through to the numbered IEEE string until the format-aware finalize follow-up makes the renumber pass + verify/reviewer/revisor scans citation-family-aware (named in `references/absorption-roadmap.md`).
- Does NOT update `topic_lineage.covered_themes[]` in the binding.
- Does NOT support cross-page substitute-citation search or transitive cycle detection on the new manifest shape (the adapter handles direct cycles only).
- **Localizes the reference-section heading** per `plan.json::output_language` via `_knowledge_lib.ref_heading` (`de→Referenzen`, default→English), and strips the composer's heading language-independently. Does NOT itself translate body content — the draft body language is the composer's responsibility (it honours `OUTPUT_LANGUAGE`); finalize deposits the verified body verbatim.
- Does NOT dispatch the `lineage-stamp.py` helper — inverted-pipeline projects do not write `raw/research-<slug>/`, so the stamp helper has no work to do; the `derived_from_research` field is set inline in Step 5's frontmatter.
- Does NOT re-fetch any source URL. The `verification:` semantics stamped here are **citation-consistent (zero-network)** per the Phase 6 contract — the verifier scored each `draft_sentence` against the cited page's ingest-time `pre_extracted_claims:`, not against the live source. For live-source re-verification (the long-tail drift problem), run `/cogni-knowledge:knowledge-refresh --resweep` (opt-in; dispatches `cogni-wiki:wiki-claims-resweep`).

## Output

- `<WIKI_ROOT>/wiki/syntheses/<synthesis-slug>.md` — the deposited synthesis page (frontmatter + verified draft body + `## References` list). Frontmatter carries the two additive `verification:` + `verification_ratio:` keys — a durable, machine-readable record that the citations were scored citation-consistent (zero-network) plus the verbatim/paraphrase/synthesis/unsupported counts.
- `<WIKI_ROOT>/wiki/index.md` — the synthesis is filed under `## Syntheses` by Step 7's `wiki_index_update.py`, then the whole root is re-rendered as the curated MAP by Step 10.5 sub-step 3.5.1 (`root_index.py render`): the OVERVIEW-NARRATIVE intro + one `## <theme>` section per theme, each a count-link to the per-type sub-indexes (the synthesis shows as `Syntheses (n)` within its backing-source theme). Per-page bullets are dropped — they live in the sub-indexes.
- `<WIKI_ROOT>/wiki/syntheses/index.md` — re-rendered (Step 10.5 sub-step 3.7, when `INDEX_OK=yes`) — the machine-owned syntheses sub-index, grouped by the theme of each synthesis's cited sources (`theme_via_backing_sources`, `Uncategorized` fallback) via `sub_index.py render --type syntheses`; narrator-authored `SYNTHESES-LEADIN` spans are carried forward verbatim.
- `<WIKI_ROOT>/wiki/perspectives.md` — re-rendered (Step 10.5 sub-step 3.8, every run) — the machine-owned 5W1H derived overlay re-projecting the type-first layout by perspective (Who/What/Why backed by the surviving types; When/Where/How honest-empty) via `perspectives_index.py render`; per-facet `PERSPECTIVES-FACET:<slug>` lead-in spans are carried forward verbatim, and a hand-authored page (no `PERSPECTIVES-INDEX` marker) is never clobbered.
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by 1.
- `<WIKI_ROOT>/wiki/context_brief.md` — refreshed.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] finalize | …` line.
- `<knowledge-root>/.cogni-knowledge/binding.json` — one new entry in `research_projects[]` with `report_source: "wiki"`.
- `<WIKI_ROOT>/wiki/<type>/<cited-slug>.md` — each cited page gains a reverse `[[<synthesis-slug>]]` backlink (Step 10.5 `lint --fix=reverse_link_missing`), de-orphaning the synthesis.
- `<WIKI_ROOT>/wiki/syntheses/<slug>.md` carries a trailing `## Research questions` section of bare `[[<question-slug>]]` forward links (Step 4.7 + Step 6), and each linked `<WIKI_ROOT>/wiki/questions/<question-slug>.md` gains a reverse `[[<synthesis-slug>]]` in its `## See also` (Step 10.5). Absent on `--no-question-links` / an empty-or-missing `question-manifest.json` (legacy project).
- `<WIKI_ROOT>/wiki/overview.md` — refreshed with a `## Recent syntheses` bullet for this synthesis (Step 10.5 sub-step 3, `overview_update.py recent-bullet`). This is now overview.md's **only** role — the curated-root layout moved the `MACHINE-OWNED:OVERVIEW-NARRATIVE` narrative to the `wiki/index.md` intro (spliced on `--apply-portal`, see the `wiki/index.md` row above).
- `<WIKI_ROOT>/.cogni-wiki/portal-proposed.md` — the **staged** curated-portal diff (per-theme current-vs-proposed lead-in + proposed overview narrative). Written by default (no `--apply-portal`); the live portal is untouched. Absent under `--apply-portal` (the proposals are applied instead) and `--no-portal` / nothing-grew / `--dry-run`.
- `<WIKI_ROOT>/wiki/index.md` — on `--apply-portal`, each grown `## <theme>` section gains/refreshes an engine-owned `MACHINE-OWNED:PORTAL-LEADIN` lead-in span (carried into the curated MAP above the section's count-link line by sub-step 3.5.1), and the `MACHINE-OWNED:OVERVIEW-NARRATIVE` intro block is spliced (Step 10.5 sub-step 3.5). Human (non-sentineled) lead-ins are never touched.
- `<WIKI_ROOT>/.cogni-wiki/concepts-index-proposed.md` — the **staged** concepts-outline diff (per-theme current-vs-proposed lead-in). Written by default (no `--apply-concepts`); the live `wiki/concepts/index.md` is untouched. Absent under `--apply-concepts` (the proposals are applied instead) and `--no-concepts` / nothing-changed / `--dry-run`.
- `<WIKI_ROOT>/wiki/concepts/index.md` — on `--apply-concepts`, each changed `## <theme>` section gains/refreshes an engine-owned `MACHINE-OWNED:CONCEPTS-LEADIN:<theme>` lead-in span above its bullets (Step 10.5 sub-step 3.6). Human (non-sentineled) concepts pages are never touched.
- `<project_path>/.metadata/wiki-coverage-finalize.json` — the POST-ingest coverage re-score (Step 10.5 sub-step 5), the research-gap stream's basis. Written when the re-score succeeds; the curate-time `wiki-coverage.json` is **never** overwritten (it is `source-curator`'s pre-research read via `WIKI_COVERAGE_PATH`). Absent on `--no-research-gaps` / `--dry-run` / a re-score failure (the curate-time file is the fail-soft fallback).
- `<WIKI_ROOT>/wiki/open_questions.md` — refreshed (Step 10.5 sub-step 5). Skipped on `--dry-run` / `--no-open-questions`.
- `<project_path>/.metadata/contradictor-v<N>.json` — Step 10.6 contradiction tripwire findings (schema `0.1.0`). Carries Pass A (synthesis-vs-cited) findings (`conflicting_claim_id` `clm`/`dcl`/`acl`-NNN) and Pass B (synthesis-vs-prior-syntheses) findings (`conflicting_claim_id: null`, `conflicting_page` a synthesis slug) merged in one `findings[]`; `compared_against` additionally carries `prior_syntheses[]` + `prior_synthesis_count`. Written when the contradictor agent returns `ok: true` and at least one cited peer OR one prior synthesis was compared; absent on skip paths (`--dry-run`, `--no-contradictor`, the both-empty skip) and on `ok: false` failure paths. `--no-prior-syntheses` still writes the file (Pass A only).
- `<project_path>/.metadata/structural-review-v<N>.json` — Step 10.7 structural-quality verdict (schema `0.1.1`): per-dimension `structural_scores`, `citation_density`, `word_count` (the advisory Word Count Gate, #309 P2), `source_diversity`, `issues[]`, `strengths[]`, `verdict`, `score`. Written when the reviewer returns `ok: true`; absent on skip paths (`--dry-run`, `--no-reviewer`) and on `ok: false` failure paths.

No files are written outside the workspace root or the bound knowledge base.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 7 contract
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — finalize deliverable list
- `${CLAUDE_PLUGIN_ROOT}/scripts/cycle-guard.py --help` — citation-manifest fallback documented in the docstring
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/_knowledge_lib.py` — `slugify` + `atomic_write_text` reused
- `cogni-wiki/skills/wiki-ingest/scripts/wiki_index_update.py --help`
- `cogni-wiki/skills/wiki-ingest/scripts/config_bump.py --help`
- `cogni-wiki/skills/wiki-ingest/scripts/rebuild_context_brief.py --help`
- `cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py --help` — Step 10.5 conformance gate (`--fix=all`)
- `cogni-wiki/skills/wiki-health/scripts/health.py --help` — Step 10.5 structural assertion
- `${CLAUDE_PLUGIN_ROOT}/agents/wiki-contradictor.md` — Step 10.6 contradiction tripwire
- `${CLAUDE_PLUGIN_ROOT}/agents/wiki-reviewer.md` — Step 10.7 structural-quality review
- `${CLAUDE_PLUGIN_ROOT}/agents/portal-narrator.md` — Step 10.5 sub-step 3.5 curated-portal refresh
- `${CLAUDE_PLUGIN_ROOT}/references/portal-shape-decision.md` — the 4b auto-refresh decision + ownership/sentinel/staging/staleness contract
- `${CLAUDE_PLUGIN_ROOT}/agents/concepts-outliner.md` — Step 10.5 sub-step 3.6 concepts-outline lead-in refresh
- `${CLAUDE_PLUGIN_ROOT}/scripts/concepts_index.py --help` — deterministic `wiki/concepts/index.md` renderer; `render` applies + carries lead-in spans forward under `_wiki_lock`
- `${CLAUDE_PLUGIN_ROOT}/references/concepts-shape-decision.md` — the concepts-outline shape decision (standalone page, grouped-by-theme, narrated lead-ins under MACHINE-OWNED sentinels, stage-by-default auto-refresh)
- `cogni-wiki/skills/wiki-ingest/scripts/wiki_index_update.py --help` — `--get-leadin`/`--set-leadin` (the machine portal lead-in primitive)
