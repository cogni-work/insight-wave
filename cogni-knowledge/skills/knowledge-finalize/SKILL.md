---
name: knowledge-finalize
description: "Phase 7 of the v0.1.0 inverted pipeline. Reads <project>/output/draft-vN.md (the latest verified draft) + <project>/.metadata/verify-vN.json + <project>/.metadata/citation-manifest.json, runs cycle-guard.py to refuse self-citing loops, atomically writes the verified draft to <wiki>/syntheses/<slug>.md with type: synthesis frontmatter (incl. derived_from_research: <project-slug>), updates wiki/index.md under the Syntheses category, bumps entries_count, rebuilds context_brief.md, appends a research_projects[] entry to binding.json, and appends one '## [YYYY-MM-DD] finalize | …' line to wiki/log.md. Closes the inverted-pipeline loop — the synthesis is now visible to future knowledge-compose runs as cross-source framing. Use this skill whenever the user says 'finalize the draft', 'deposit the synthesis', 'phase 7 of the knowledge pipeline', 'knowledge finalize', or 'land the verified draft'. After finalize, M10 will rebuild query/dashboard/resume/refresh on the new manifests."
allowed-tools: Read, Write, Bash
---

# Knowledge Finalize

Phase 7 of the v0.1.0 inverted pipeline. Reads `<project>/output/draft-vN.md` + `<project>/.metadata/verify-vN.json` + `<project>/.metadata/citation-manifest.json`, runs `cycle-guard.py` to refuse self-citing loops, deposits the verified draft as `<WIKI_ROOT>/wiki/syntheses/<synthesis-slug>.md`, runs three cogni-wiki helpers (`wiki_index_update.py`, `config_bump.py`, `rebuild_context_brief.py`) directly at script level, appends a `research_projects[]` entry to `binding.json`, and writes one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md`.

This is the **inverted-pipeline closing step**. Without it, every verified draft from M8 lives forever in `<project>/output/` and the wiki cannot accumulate cross-source framing — the compounding property that differentiates cogni-knowledge from one-shot deep-research tools requires future `knowledge-compose` runs to read `wiki/syntheses/*.md` as prior context. M9 is what makes that read non-empty.

Synthesis-page frontmatter shape (matches cogni-wiki SCHEMA for `type: synthesis` per `cogni-wiki/CLAUDE.md` §"Page Frontmatter"):

```yaml
---
id: <synthesis-slug>
title: <plan.topic verbatim>
type: synthesis
tags: []
created: <today ISO>
updated: <today ISO>
sources:
  - wiki://<wiki_slug>/<cited-slug-1>
  - wiki://<wiki_slug>/<cited-slug-2>
derived_from_research: <project-slug>
draft_revision_round: <verify.revision_round>
---
```

`derived_from_research` is stamped inline (no `lineage-stamp.py` dispatch — that helper walks `raw/research-<slug>/`, which v0.1.0 projects don't write to). `draft_revision_round` is informational; cogni-wiki's lint allows arbitrary additive frontmatter keys.

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

**Resolve `WIKI_INGEST_SCRIPTS`.** Same probe shape — find `cogni-wiki/skills/wiki-ingest/scripts/` so Steps 7, 8, and 10 can call `wiki_index_update.py`, `config_bump.py`, and `rebuild_context_brief.py` directly:

```
resolve_wiki_ingest_scripts() {
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-wiki/skills/wiki-ingest/scripts"
  test -d "$sib" && { echo "$sib"; return 0; }
  for d in "${CLAUDE_PLUGIN_ROOT}/../../cogni-wiki/"*/skills/wiki-ingest/scripts; do
    [ -d "$d" ] && { echo "$d"; return 0; }
  done
  return 1
}
WIKI_INGEST_SCRIPTS=$(resolve_wiki_ingest_scripts) || abort "cogni-wiki wiki-ingest scripts not found"
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

Capture `UNSUPPORTED_COUNT`, `REVISION_ROUND`, and the four counts for the Step 11 summary. If `UNSUPPORTED_COUNT > 0`, surface a `⚠ Finalizing with <N> unsupported citations remaining (verify-v<N>.json::counts.unsupported)` — do **not** block. The operator decided to ship the partial draft (same posture as `knowledge-verify` Step 6's "Loop exhausted" warning).

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

Confirm `<WIKI_ROOT>/wiki/syntheses/<SYNTHESIS_SLUG>.md` does not already exist. If it does and `--overwrite` was not passed, abort with: "synthesis page wiki/syntheses/<slug>.md already exists; pass --overwrite or --synthesis-slug <other> to proceed".

If `--dry-run`, print:

```
WIKI_ROOT=<wiki_root>
PROJECT_PATH=<project_path>
DRAFT_VERSION=<N>
SYNTHESIS_SLUG=<slug>
CITATION_COUNT=<count from citation-manifest.json>
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

`<project-slug>` is the slug field from `<project_path>/.metadata/project-config.json::slug` (the cogni-research project slug recorded at compose time). `--report-source wiki` is hard-coded — the v0.1.0 inverted pipeline only ever produces wiki-mode deposits, so the legacy `_read_report_source` fallback isn't relevant here.

The script's manifest-shape fallback (added in v0.0.24) walks `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty. Confirm `data.input_shape == "citation-manifest"` in the JSON envelope as a positive signal the adapter ran (informational; not a gate).

Interpret return:

- **Exit 0, `status: clear`** — proceed. `cross_lineage_overlap[]` may be non-empty; surface count in Step 11.
- **Exit 0, `status: not_applicable`** — should not happen (`--report-source wiki` is explicit). Treat as defence-in-depth; proceed.
- **Exit 1, `status: cycle_detected`** — abort. Print `direct_self_cycles[]` + remediation: "The synthesis would cite a wiki page derived from this same project — that's a self-citing loop. Rename the synthesis (`--synthesis-slug <other>`), narrow the topic, or hand-edit the draft to drop the self-referential citations."

### 5. Compose + 6. Atomic write

One Python subprocess composes the synthesis page in memory and writes it atomically via `_knowledge_lib.atomic_write_text` (same helper `source-ingester` uses for `wiki/sources/<slug>.md`):

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<wiki_root>" \
PROJECT_PATH="<project_path>" \
PROJECT_SLUG="<project-slug>" \
SYNTHESIS_SLUG="<synthesis-slug>" \
DRAFT_VERSION=<N> \
REVISION_ROUND=<round> \
python3 -c '
import datetime as _dt
import json, os, sys
from pathlib import Path
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import atomic_write_text

wiki_root = Path(os.environ["WIKI_ROOT"])
project = Path(os.environ["PROJECT_PATH"])
project_slug = os.environ["PROJECT_SLUG"]
synthesis_slug = os.environ["SYNTHESIS_SLUG"]
n = int(os.environ["DRAFT_VERSION"])
revision_round = int(os.environ["REVISION_ROUND"])

draft = (project / "output" / ("draft-v" + str(n) + ".md")).read_text(encoding="utf-8")
manifest = json.loads((project / ".metadata" / "citation-manifest.json").read_text(encoding="utf-8"))
plan = json.loads((project / ".metadata" / "plan.json").read_text(encoding="utf-8"))
wiki_cfg = json.loads((wiki_root / ".cogni-wiki" / "config.json").read_text(encoding="utf-8"))

topic = plan.get("topic", "").strip() or synthesis_slug
wiki_slug = wiki_cfg.get("slug", "")
today = _dt.date.today().isoformat()

# Dedupe cited page slugs preserving first-seen order.
cited_slugs = []
seen = set()
for c in manifest.get("citations", []) or []:
    s = (c or {}).get("wiki_slug")
    if isinstance(s, str) and s and s not in seen:
        seen.add(s)
        cited_slugs.append(s)

# Lookup title + publisher per cited page for the References list.
refs = []
for slug in cited_slugs:
    page = wiki_root / "wiki" / "sources" / (slug + ".md")
    title = slug
    publisher = ""
    if page.is_file():
        text = page.read_text(encoding="utf-8")
        if text.startswith("---"):
            end = text.find("\n---", 4)
            if end > 0:
                fm_block = text[4:end]
                for line in fm_block.splitlines():
                    key, _, val = line.partition(":")
                    k = key.strip()
                    v = val.strip().strip("\"“”‘’")
                    if k == "title" and v:
                        title = v
                    elif k == "publisher" and v:
                        publisher = v
    if publisher:
        refs.append("- [[sources/" + slug + "]] — " + title + " (" + publisher + ")")
    else:
        refs.append("- [[sources/" + slug + "]] — " + title)

sources_lines = ["  - wiki://" + wiki_slug + "/" + slug for slug in cited_slugs]
sources_block = "\n".join(sources_lines) if sources_lines else "  []"

frontmatter = (
    "---\n"
    "id: " + synthesis_slug + "\n"
    "title: " + topic + "\n"
    "type: synthesis\n"
    "tags: []\n"
    "created: " + today + "\n"
    "updated: " + today + "\n"
    "sources:\n" + sources_block + "\n"
    "derived_from_research: " + project_slug + "\n"
    "draft_revision_round: " + str(revision_round) + "\n"
    "---\n"
)

# Strip a leading H1 from the draft body (we set our own title via frontmatter).
body = draft.lstrip()
if body.startswith("# "):
    nl = body.find("\n")
    body = body[nl + 1 :].lstrip() if nl >= 0 else ""

page_text = (
    frontmatter
    + "\n"
    + "# " + topic + "\n\n"
    + body.rstrip() + "\n\n"
    + "## References\n\n"
    + ("\n".join(refs) if refs else "_No external citations recorded in citation-manifest.json._")
    + "\n"
)

out_path = wiki_root / "wiki" / "syntheses" / (synthesis_slug + ".md")
out_path.parent.mkdir(parents=True, exist_ok=True)
atomic_write_text(out_path, page_text)

# Surface counts the orchestrator needs for Steps 7-11.
print(json.dumps({
    "synthesis_path": str(out_path.relative_to(wiki_root).as_posix()),
    "n_sources": len(cited_slugs),
    "topic": topic,
    "wiki_slug": wiki_slug,
}))
'
```

The trailing JSON line is captured for the final summary. Steps 5 and 6 are bundled into this single subprocess to keep the compose + write atomic relative to retry — a re-run sees the same wiki state.

### 7. Update wiki/index.md (cogni-wiki helper)

```
python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
    --wiki-root "$WIKI_ROOT" \
    --slug <synthesis-slug> \
    --summary "<topic, truncated to 180 chars>" \
    --category "Syntheses"
```

Same call shape as `knowledge-ingest/SKILL.md` Step 4.2, with `--category "Syntheses"` instead of `"Sources"`. The helper is lock-wrapped (`_wiki_lock` at `<WIKI_ROOT>/.cogni-wiki/.lock`). On non-zero exit, surface the error but do not abort — the page itself is on disk; only discoverability is degraded.

### 8. Bump entries_count (cogni-wiki helper)

```
python3 "$WIKI_INGEST_SCRIPTS/config_bump.py" \
    --wiki-root "$WIKI_ROOT" \
    --key entries_count \
    --delta 1
```

Same call shape as `wiki-query --file-back` (`cogni-wiki/skills/wiki-query/SKILL.md:91`). Lock-wrapped. Non-fatal on failure (operator can reconcile via `wiki-lint --fix=entries_count_drift`).

### 9. Append the project to the binding

```
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py append-project \
    --knowledge-root <knowledge_root> \
    --knowledge-slug <knowledge_slug> \
    --research-slug <project-slug> \
    --report-path <project_path>/output/draft-v<N>.md \
    --project-path <project_path> \
    --report-source wiki
```

`--report-source wiki` is hard-coded — the v0.1.0 inverted pipeline only ever produces wiki-mode deposits (the legacy `read-project-config.py --field report_source` shellout from `knowledge-report` Step 5 is not used). On `research_slug already recorded` duplicate-slug error, surface a warning but do not abort — Steps 6–8 already landed the page.

### 10. Rebuild context_brief.md + append wiki/log.md

```
python3 "$WIKI_INGEST_SCRIPTS/rebuild_context_brief.py" \
    --wiki-root "$WIKI_ROOT"
```

Same call shape as cogni-wiki's `wiki-ingest` Step 8.5. Non-fatal — `context_brief.md` is a derived artefact, regenerated next dispatch.

Append one log line (Bash `>>`; `wiki/log.md` is append-only by cogni-wiki convention):

```
DATE_STAMP=$(date -u +%F)
TOPIC=<topic from Step 5 subprocess output>
echo "## [${DATE_STAMP}] finalize | project=${TOPIC} slug=${SYNTHESIS_SLUG} draft=v${DRAFT_VERSION} round=${REVISION_ROUND} sources=${N_SOURCES}" >> "${WIKI_ROOT}/wiki/log.md"
```

`finalize` is a new operation prefix. Same additive-prefix posture as M7's `compose` and M8's `verify` — pre-v0.0.35 cogni-wiki readers count unknown prefixes in their catch-all bucket without crashing (`cogni-wiki/CLAUDE.md` §"Key Conventions"). Formalising the prefix into the enum lands in M10 when query / dashboard rebuild on the new manifests.

### 11. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Synthesis page: `wiki/syntheses/<slug>.md` (sources cited: `<N_SOURCES>`)
- Cycle-guard: `input_shape=citation-manifest`, `direct_self_cycles=0`, `cross_lineage_overlap=<N>`
- Verify lineage: `verify-v<N>.json` — verbatim=`<N>` paraphrase=`<N>` synthesis=`<N>` unsupported=`<N>` (round `<R>` of 2)
- Binding: total deposited projects now `<count>`
- Wiki updates: index.md (Syntheses), entries_count +1, context_brief.md refreshed
- Next: M10 will rebuild `knowledge-query` / `knowledge-dashboard` / `knowledge-resume` / `knowledge-refresh` on the new manifests. Today, `cogni-wiki:wiki-query --wiki-root <WIKI_ROOT>` already reads the new synthesis as part of the corpus.

If Step 2 surfaced `unsupported > 0`, repeat the `⚠ Finalized with <N> unsupported citations` warning so the audit trail is on-screen.

## Edge cases

- **Re-run on an already-finalized project.** `<WIKI_ROOT>/wiki/syntheses/<slug>.md` exists — abort with the `--overwrite` nudge. If `--overwrite`, the synthesis page is rewritten but `config_bump.py --delta 1` would over-count; pass `--overwrite` only when the previous synthesis page is being replaced after a hand-edit, and reconcile entries_count via `wiki-lint --fix=entries_count_drift` afterward.
- **No citations in the manifest.** Steps 5–6 still produce a synthesis page; the `## References` block becomes `_No external citations recorded in citation-manifest.json._`. cycle-guard's `wiki_pages_cited` will be `[]` and `status: clear` — surface in Step 11.
- **Plan.json missing topic.** Step 3 falls back to `--synthesis-slug` if passed, else aborts cleanly.
- **Cited source page missing on disk.** Step 5's reference-row falls back to the slug as the title. cycle-guard's `wiki_pages_cited_missing` will list the slug; surface in Step 11 as `⚠ Missing pages: <slug1>, <slug2>` so the operator knows the wiki was modified between ingest and finalize.

## Out of scope

- Does NOT re-run the verifier, the composer, or the ingester. M9 reads the latest verified draft + manifest as-is.
- Does NOT support APA / MLA / IEEE citation rendering. Wikilink + title/publisher list is enough for v0.0.24; M10 / M11 can render APA from the same citation-manifest if a bibliography skill ships.
- Does NOT update `topic_lineage.covered_themes[]` in the binding — that field is reserved for M10's manifest-aware dashboard rebuild.
- Does NOT support cross-page substitute-citation search or transitive cycle detection on the new manifest shape (the adapter handles direct cycles only — same posture as M9's "smallest necessary change" framing).
- Does NOT support multilingual finalization. English-only at v0.0.24 (matches M7/M8 Slice 3/4 deferrals).
- Does NOT dispatch the `lineage-stamp.py` helper — v0.1.0 projects do not write `raw/research-<slug>/`, so the stamp helper has no work to do; the `derived_from_research` field is set inline in Step 5's frontmatter.

## Output

- `<WIKI_ROOT>/wiki/syntheses/<synthesis-slug>.md` — the deposited synthesis page (frontmatter + verified draft body + `## References` list).
- `<WIKI_ROOT>/wiki/index.md` — updated with a new entry under `## Syntheses` (or the category created on first finalize).
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by 1.
- `<WIKI_ROOT>/wiki/context_brief.md` — refreshed.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] finalize | …` line.
- `<knowledge-root>/.cogni-knowledge/binding.json` — one new entry in `research_projects[]` with `report_source: "wiki"`.

No files are written outside the workspace root or the bound knowledge base.

## References

- `${CLAUDE_PLUGIN_ROOT}/references/inverted-pipeline.md` — Phase 7 contract
- `${CLAUDE_PLUGIN_ROOT}/references/absorption-roadmap.md` — Slice 5 / M9 deliverable list
- `${CLAUDE_PLUGIN_ROOT}/scripts/cycle-guard.py --help` — citation-manifest fallback documented in the docstring
- `${CLAUDE_PLUGIN_ROOT}/scripts/knowledge-binding.py --help`
- `${CLAUDE_PLUGIN_ROOT}/scripts/_knowledge_lib.py` — `slugify` + `atomic_write_text` reused
- `cogni-wiki/skills/wiki-ingest/scripts/wiki_index_update.py --help`
- `cogni-wiki/skills/wiki-ingest/scripts/config_bump.py --help`
- `cogni-wiki/skills/wiki-ingest/scripts/rebuild_context_brief.py --help`
