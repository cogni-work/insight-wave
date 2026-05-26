---
name: knowledge-finalize
description: "Phase 7 of the v0.1.0 inverted pipeline. Reads <project>/output/draft-vN.md (the latest verified draft) + <project>/.metadata/verify-vN.json + <project>/.metadata/citation-manifest.json, runs cycle-guard.py to refuse self-citing loops, atomically writes the verified draft to <wiki>/syntheses/<slug>.md with type: synthesis frontmatter (incl. derived_from_research: <project-slug>), updates wiki/index.md under the Syntheses category, bumps entries_count, rebuilds context_brief.md, appends a research_projects[] entry to binding.json, appends one '## [YYYY-MM-DD] finalize | …' line to wiki/log.md, and runs a conformance gate (wiki-lint --fix=all + wiki-health) so the deposited base passes cogni-wiki's own checks — reference backlinks are bare [[slug]] so the synthesis de-orphans its cited sources. Closes the inverted-pipeline loop — the synthesis is now visible to future knowledge-compose runs as cross-source framing. Use this skill whenever the user says 'finalize the draft', 'deposit the synthesis', 'phase 7 of the knowledge pipeline', 'knowledge finalize', or 'land the verified draft'. After finalize, M10 will rebuild query/dashboard/resume/refresh on the new manifests."
allowed-tools: Read, Write, Bash
---

# Knowledge Finalize

Phase 7 of the v0.1.0 inverted pipeline. Reads `<project>/output/draft-vN.md` + `<project>/.metadata/verify-vN.json` + `<project>/.metadata/citation-manifest.json`, runs `cycle-guard.py` to refuse self-citing loops, deposits the verified draft as `<WIKI_ROOT>/wiki/syntheses/<synthesis-slug>.md`, runs three cogni-wiki helpers (`wiki_index_update.py`, `config_bump.py`, `rebuild_context_brief.py`) directly at script level, appends a `research_projects[]` entry to `binding.json`, writes one `## [YYYY-MM-DD] finalize | …` line to `wiki/log.md`, and runs a Step 10.5 conformance gate (`lint_wiki.py --fix=all` + `health.py`) so the deposited base passes cogni-wiki's own structural checks.

This is the **inverted-pipeline closing step**. Without it, every verified draft from M8 lives forever in `<project>/output/` and the wiki cannot accumulate cross-source framing — the compounding property that differentiates cogni-knowledge from one-shot deep-research tools requires future `knowledge-compose` runs to read `wiki/syntheses/*.md` as prior context. M9 is what makes that read non-empty.

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

**Resolve the cogni-wiki script dirs.** Same probe shape, parameterised by the
skill subdir, so Steps 7/8/10 can call `wiki_index_update.py` / `config_bump.py` /
`rebuild_context_brief.py` (wiki-ingest) and Step 10.5's conformance gate can call
`lint_wiki.py` (wiki-lint) + `health.py` (wiki-health). Each script imports
`_wikilib` relatively from `wiki-ingest/scripts`, so resolving the real installed
dir keeps those imports intact:

```
resolve_wiki_scripts() {  # $1 = skill name, e.g. wiki-ingest / wiki-lint / wiki-health
  local skill="$1"
  local sib="${CLAUDE_PLUGIN_ROOT}/../cogni-wiki/skills/${skill}/scripts"
  test -d "$sib" && { echo "$sib"; return 0; }
  # F26: pick the NEWEST cached version, not the lexically-first. Consider ONLY
  # numeric version dirs — sort -V ranks a non-numeric name (main/latest/a
  # branch checkout) ABOVE every real version, so a stray dir would otherwise
  # win. sort -V handles multi-digit segments (0.0.9 < 0.0.16 < 0.0.46).
  local newest ver
  newest=$(for d in "${CLAUDE_PLUGIN_ROOT}/../../cogni-wiki/"*/skills/"${skill}"/scripts; do
    [ -d "$d" ] || continue
    ver=${d%/skills/${skill}/scripts}; ver=${ver##*/}
    case "$ver" in ''|*[!0-9.]*) continue ;; esac
    printf '%s\n' "$d"
  done | sort -V | tail -1)
  [ -n "$newest" ] && { echo "$newest"; return 0; }
  return 1
}
WIKI_INGEST_SCRIPTS=$(resolve_wiki_scripts wiki-ingest) || abort "cogni-wiki wiki-ingest scripts not found"
WIKI_LINT_SCRIPTS=$(resolve_wiki_scripts wiki-lint)   || abort "cogni-wiki wiki-lint scripts not found"
WIKI_HEALTH_SCRIPTS=$(resolve_wiki_scripts wiki-health) || abort "cogni-wiki wiki-health scripts not found"
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

`<project-slug>` is the slug field from `<project_path>/.metadata/project-config.json::slug` (the cogni-research project slug recorded at compose time). `--report-source wiki` is hard-coded — the v0.1.0 inverted pipeline only ever produces wiki-mode deposits, so the legacy `_read_report_source` fallback isn't relevant here.

The script's manifest-shape fallback (added in v0.0.24) walks `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty. Confirm `data.input_shape == "citation-manifest"` in the JSON envelope as a positive signal the adapter ran (informational; not a gate).

Interpret return:

- **Exit 0, `status: clear`** — proceed. `cross_lineage_overlap[]` may be non-empty; surface count in Step 11.
- **Exit 0, `status: not_applicable`** — should not happen (`--report-source wiki` is explicit). Treat as defence-in-depth; proceed.
- **Exit 1, `status: cycle_detected`** — abort. Print `direct_self_cycles[]` + remediation: "The synthesis would cite a wiki page derived from this same project — that's a self-citing loop. Rename the synthesis (`--synthesis-slug <other>`), narrow the topic, or hand-edit the draft to drop the self-referential citations."
- **Exit 1, `status: manifest_unreadable`** — added v0.0.24. The citation manifest at `.metadata/citation-manifest.json` cannot be parsed (corrupt JSON, I/O error). Abort with the script's `error` field verbatim; remediate by re-running `knowledge-compose` to regenerate the manifest. **Do not proceed** — depositing a synthesis whose lineage cannot be checked is the exact failure mode the guard exists to prevent.

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
import json, os, re, sys
from pathlib import Path
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import (
    atomic_write_text, ref_heading, first_url, md_link_dest,
    strip_reference_section, renumber_inline_citations,
)

wiki_root = Path(os.environ["WIKI_ROOT"])
project = Path(os.environ["PROJECT_PATH"])
project_slug = os.environ["PROJECT_SLUG"]
synthesis_slug = os.environ["SYNTHESIS_SLUG"]
n = int(os.environ["DRAFT_VERSION"])
revision_round = int(os.environ["REVISION_ROUND"])

draft = (project / "output" / ("draft-v" + str(n) + ".md")).read_text(encoding="utf-8")
manifest = json.loads((project / ".metadata" / "citation-manifest.json").read_text(encoding="utf-8"))
plan = json.loads((project / ".metadata" / "plan.json").read_text(encoding="utf-8"))

topic = plan.get("topic", "").strip() or synthesis_slug
# Reference-section heading localizes off the projects output_language (the
# same value knowledge-compose threads to wiki-composer). Default en. Used for
# BOTH the language-independent strip of the composers tail and the heading we
# re-emit, so the deposited page never carries two reference sections.
output_language = (plan.get("output_language") or "en")
heading = ref_heading(output_language)
# UTC date so frontmatter created/updated align with Step 10s `date -u +%F` log
# stamp. Mixed local/UTC across midnight produced cross-artifact date skew.
today = _dt.datetime.now(_dt.timezone.utc).date().isoformat()

# Dedupe cited page slugs preserving first-seen order. claim_id is allowed to
# be null (synthesis-page citations per agents/wiki-composer.md), so we key
# only on wiki_slug.
cited_slugs = []
seen = set()
for c in manifest.get("citations", []) or []:
    s = (c or {}).get("wiki_slug")
    if isinstance(s, str) and s and s not in seen:
        seen.add(s)
        cited_slugs.append(s)

# Lookup each cited pages kind + title + publisher. Try wiki/sources/ first
# (the common case — Phase-4 source ingest); fall back to wiki/syntheses/
# (wiki-composer cites prior syntheses with claim_id: null). page_kind gates
# whether the reference row gets a bare [[<slug>]] backlink below: a page that
# exists (source OR synthesis) does; a missing page (page_kind None) does not.
def _parse_top_level_kv(fm_block):
    out = {}
    for line in fm_block.splitlines():
        # Skip indented lines so nested keys under pre_extracted_claims: dont
        # overwrite top-level title/publisher.
        if not line or line[0] in (" ", "\t") or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        k = key.strip()
        # Strip surrounding quote pair (ASCII single/double + curly variants).
        v = val.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in ("\"", "'", "“", "‘"):
            v = v[1:-1]
        # Also strip a paired curly closing if it sneaked through.
        v = v.strip("“”‘’")
        out[k] = v
    return out

# Reference list, numbered in citation-manifest first-appearance order so the
# deposited [N] match the composers inline [N] markers (which finalize leaves
# in the body verbatim — see the strip note below). N = index + 1. The URL
# extraction, link-destination escaping, reference-section strip, and inline
# renumber all live in _knowledge_lib (unit-tested) — see first_url /
# md_link_dest / strip_reference_section / renumber_inline_citations.
refs = []
page_kind_by_slug = {}
for idx, slug in enumerate(cited_slugs):
    n = idx + 1
    page_path = None
    page_kind = None
    for kind, dirname in (("source", "sources"), ("synthesis", "syntheses")):
        candidate = wiki_root / "wiki" / dirname / (slug + ".md")
        if candidate.is_file():
            page_path = candidate
            page_kind = kind
            break
    page_kind_by_slug[slug] = page_kind  # None if cited page is missing on disk
    title = slug
    publisher = ""
    url = ""
    if page_path is not None:
        text = page_path.read_text(encoding="utf-8")
        if text.startswith("---"):
            # Tolerant frontmatter close: optional trailing newline.
            m = re.match(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", text, re.DOTALL)
            if m:
                fm = _parse_top_level_kv(m.group(1))
                if fm.get("title"):
                    title = fm["title"]
                if fm.get("publisher"):
                    publisher = fm["publisher"]
                if page_kind == "source":
                    url = first_url(fm.get("sources", ""))
    # Bare `[[<slug>]]` backlink so the synthesis->source forward edge actually
    # registers in cogni-wiki's link graph. WIKILINK_RE only matches a BARE slug
    # (cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py), so a path-prefixed
    # `[[sources/<slug>]]` matches the slash-free grammar nowhere — it is
    # invisible: neither an inbound link (every cited source counts as an orphan
    # -> the literal 100% orphan rate) nor a broken link. Slugs are globally
    # unique across the per-type dirs, so the bare slug addresses the page with
    # no path. The reverse (source->synthesis) edge is backfilled by the Step
    # 10.5 `lint_wiki.py --fix=reverse_link_missing` gate, de-orphaning both ends.
    #
    # Emit the backlink ONLY when the cited page exists on disk (page_kind is not
    # None). A missing page would make bare `[[<slug>]]` a broken_wikilink that
    # health.py flags as an error and fails the Step 10.5 gate — so a missing
    # cited page gets a reference row with NO wikilink (the graceful-degradation
    # edge that the old invisible `[[sources/<slug>]]` form silently tolerated).
    backlink = ("[[" + slug + "]]") if page_kind is not None else ""
    bib = (publisher + ', "' + title + '"') if publisher else ('"' + title + '"')
    # IEEE-style numbered entry. Clickable [URL](URL) when the source page
    # carries an http(s) URL (angle-bracketed via md_link_dest when it contains
    # parens). The trailing " — [[<slug>]]" backlink is appended only for a cited
    # page that exists on disk.
    entry = "**[" + str(n) + "]** " + bib
    if url:
        entry += ". [" + url + "](" + md_link_dest(url) + ")"
    if backlink:
        entry += " — " + backlink
    refs.append(entry)

# `wiki://<slug>` is the bare-slug shape cogni-wiki health.py expects
# (cogni-wiki/skills/wiki-health/scripts/health.py:206 splits on the prefix
# and looks the bare slug up in slug_index). A `wiki://<wiki_slug>/<slug>`
# composite would trip `broken_wiki_source` on every cited entry.
#
# Emit a `wiki://` source ONLY for a cited page that exists on disk — the same
# page_kind gate the body backlink uses. health.py's `broken_wiki_source` flags
# any `wiki://<slug>` whose target is not in the slug index as an ERROR, so a
# cited page that went missing between ingest and finalize would otherwise fail
# the Step 10.5 health gate even though its body backlink was suppressed. The
# missing slug is still surfaced via the Step 11 "Missing pages" warning.
sourced_slugs = [s for s in cited_slugs if page_kind_by_slug.get(s) is not None]
if sourced_slugs:
    sources_block = "sources:\n" + "\n".join("  - wiki://" + slug for slug in sourced_slugs)
else:
    # Empty list emits inline (matches `tags: []` shape) instead of the
    # block-style `sources:\n  []` continuation, which strict YAML parsers
    # mis-read as the literal string "[]".
    sources_block = "sources: []"

frontmatter = (
    "---\n"
    "id: " + synthesis_slug + "\n"
    "title: " + topic + "\n"
    "type: synthesis\n"
    "tags: [synthesis]\n"
    "created: " + today + "\n"
    "updated: " + today + "\n"
    + sources_block + "\n"
    "derived_from_research: " + project_slug + "\n"
    "draft_revision_round: " + str(revision_round) + "\n"
    "---\n"
)

# Strip a leading H1 from the draft body (we set our own title via frontmatter).
body = draft.lstrip()
if body.startswith("# "):
    nl = body.find("\n")
    body = body[nl + 1 :].lstrip() if nl >= 0 else ""

# Strip the composer's own reference section (it re-emits below) so the page
# never carries two; LANGUAGE-INDEPENDENT (localized heading + English, anchored
# so a heading on the first/last body line still matches — the #301 fix) with a
# content-preserving safety net. Then renumber the body's inline `<sup>[N]`
# markers to a contiguous 1..K matching the re-derived reference list (closes a
# gap left by a revisor full-source-drop). Both transforms are unit-tested in
# _knowledge_lib (strip_reference_section / renumber_inline_citations).
body = strip_reference_section(body, heading)
body = renumber_inline_citations(body)

page_text = (
    frontmatter
    + "\n"
    + "# " + topic + "\n\n"
    + body.rstrip() + "\n\n"
    + "## " + heading + "\n\n"
    + ("\n".join(refs) if refs else "_No external citations recorded in citation-manifest.json._")
    + "\n"
)

out_path = wiki_root / "wiki" / "syntheses" / (synthesis_slug + ".md")
out_path.parent.mkdir(parents=True, exist_ok=True)
atomic_write_text(out_path, page_text)

# Surface counts the orchestrator needs for Steps 7-11.
n_missing = sum(1 for k in page_kind_by_slug.values() if k is None)
print(json.dumps({
    "synthesis_path": str(out_path.relative_to(wiki_root).as_posix()),
    "n_sources": len(cited_slugs),
    "n_synthesis_citations": sum(1 for k in page_kind_by_slug.values() if k == "synthesis"),
    "n_missing_pages": n_missing,
    "topic": topic,
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

Same call shape as `knowledge-ingest/SKILL.md` Step 4.2, with `--category "Syntheses"` instead of `"Sources"`. The helper is lock-wrapped (`_wiki_lock` at `<WIKI_ROOT>/.cogni-wiki/.lock`).

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

`--report-source wiki` is hard-coded — the v0.1.0 inverted pipeline only ever produces wiki-mode deposits (the legacy archived `report_source` shellout is not used). Without `--allow-update`, a duplicate `research_slug` aborts the script — surface a **loud** warning so the operator can't miss the binding/wiki desync:

```
⚠ Binding append SKIPPED: project '<project-slug>' already bound; re-run with --overwrite to refresh the binding entry, or accept that this finalize landed the synthesis page on the wiki without updating binding.json::research_projects[]. The synthesis page IS on disk — re-running finalize without --overwrite will refuse on the existing page; re-run with --overwrite + --allow-update to reconcile both.
```

Do not abort the SKILL — Steps 6–8 already landed the page, and refusing now would leave wiki state on disk that's not reflected in the binding (the same desync the warning is alerting the operator to). The operator decides whether to reconcile via `--overwrite` re-run or accept the asymmetric state.

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
printf '## [%s] finalize | project=%s slug=%s draft=v%s round=%s sources=%s\n' \
    "$DATE_STAMP" "$TOPIC" "$SYNTHESIS_SLUG" "$DRAFT_VERSION" "$REVISION_ROUND" "$N_SOURCES" \
    >> "${WIKI_ROOT}/wiki/log.md"
```

`finalize` is a new operation prefix. Same additive-prefix posture as M7's `compose` and M8's `verify` — pre-v0.0.35 cogni-wiki readers count unknown prefixes in their catch-all bucket without crashing (`cogni-wiki/CLAUDE.md` §"Key Conventions"). Formalising the prefix into the enum lands in M10 when query / dashboard rebuild on the new manifests.

### 10.5 Conformance gate (run cogni-wiki's own gates)

The inverted pipeline writes the wiki via forked agents + direct script calls, so cogni-wiki's `wiki-health` / `wiki-lint` never run as a gate. This step closes that: it backfills the deterministic link/frontmatter fixes, asserts the base is structurally clean, and rebuilds `context_brief.md` last so it reflects the post-gate state. It runs after the deposit + index are on disk, so the gate sees the final page set.

1. **Deterministic lint fixes — de-orphan + reconcile.**
   ```
   python3 "$WIKI_LINT_SCRIPTS/lint_wiki.py" \
       --wiki-root "$WIKI_ROOT" \
       --fix=all
   ```
   `--fix=all` applies the five safe classes (`lint_wiki.py` `FIX_CLASSES`). The load-bearing one is **`reverse_link_missing`**: the bare `[[<slug>]]` references this finalize just wrote are forward edges synthesis→source, so lint backfills the reverse source→synthesis `[[<synthesis-slug>]]` (a `## See also` append on each cited source) — de-orphaning the synthesis. The others are housekeeping: `frontmatter_defaults`, `entries_count_drift` (reconciles `entries_count` to the on-disk truth — supersedes Step 8's conditional bump on any drift), `alphabetisation`, and `synthesis_no_wiki_source` (a no-op — Step 5 already wrote `wiki://<slug>` sources). Capture the envelope; surface `data.fixed[]` / `data.failed[]` counts in the Step 11 summary. **Non-fatal per item** — a per-page fix failure lands in `data.failed[]` and does not block finalize. (`orphan_page` is NOT a `--fix` class — it is suggest-only; 0 orphans comes from the inbound links the bare refs + this reverse-link backfill create, never from `--fix`.)

2. **Health + orphan assertions (the actual gate).**
   ```
   python3 "$WIKI_HEALTH_SCRIPTS/health.py"   --wiki-root "$WIKI_ROOT"
   python3 "$WIKI_LINT_SCRIPTS/lint_wiki.py"  --wiki-root "$WIKI_ROOT"
   ```
   The second call has **no `--fix`** — it reads the post-fix state. Assert two things and surface both **loudly** (and **non-fatally** — the synthesis already landed; the operator reconciles via `wiki-update` / a re-run, never a rollback):
   - `health.py` `data.errors == []` → on any error: `⚠ wiki-health: <N> error(s) after finalize: <class> on <page>, …`.
   - `lint_wiki.py` `data.warnings` has **no `orphan_page`** entry → on any: `⚠ wiki-lint: <N> orphan page(s) after finalize: <page>, …`.

   The orphan assertion is what actually covers the slice's stated metric — `orphan_page` is a **lint warning, not a health error**, and is **not** a `--fix` class, so the `--fix=all` in sub-step 1 de-orphans by *writing inbound links* (bare refs + the `reverse_link_missing` backfill), and this read-only re-lint verifies it worked. Without this check the gate could report "health clean" while a synthesis was left orphaned (e.g. if the de-orphaning was undone). Residual orphans are expected and acceptable in two documented cases (surface, don't fail): an ingested source no synthesis ever cited and no sibling backlinks (cold-start), and a synthesis that cites zero existing pages (empty/all-missing manifest → it has no outbound links for `reverse_link_missing` to mirror). The live `0 errors` + `0 orphan_page` proof on a fresh German base is #311's job.

   **Caveat — foundation pages.** `reverse_link_missing` has no `foundation: true` exemption, so if this synthesis cites a prefilled foundation concept, the fixer appends a `## See also` backlink onto that curated page (bypassing `wiki-update`'s `--force` guard). In the inverted pipeline the composer cites `wiki/sources/*` + prior `wiki/syntheses/*`, not `wiki/concepts/`, so this is not expected; noted so a future foundation-citing path is aware.

3. **Refresh `wiki/overview.md`.** Keep the "state of the wiki" page from going stale (#308). Deterministic, no extra LLM pass — ensure a `## Recent syntheses` heading exists and refresh a single bullet for this synthesis (idempotent on the slug). The dedup removes only this slug's prior **bullet** (a `- … [[slug]] …` list item), never prose that merely mentions `[[slug]]`; the heading is matched by exact line, never substring. `overview.md` is not graph-scanned, so this is purely freshness:
   ```
   WIKI_ROOT="<wiki_root>" SYNTHESIS_SLUG="<slug>" TOPIC_RAW="<topic>" DATE_STAMP="$(date -u +%F)" \
   python3 -c '
   import os
   from pathlib import Path
   p = Path(os.environ["WIKI_ROOT"]) / "wiki" / "overview.md"
   slug = os.environ["SYNTHESIS_SLUG"]
   marker = "[[" + slug + "]]"
   topic = " ".join(os.environ["TOPIC_RAW"].split())
   bullet = "- [" + os.environ["DATE_STAMP"] + "] " + marker + " — " + topic
   heading = "## Recent syntheses"
   text = p.read_text(encoding="utf-8") if p.is_file() else "# Overview\n"
   # Drop ONLY a prior Recent-syntheses bullet for this slug (a list item),
   # never a prose line that happens to reference [[slug]].
   lines = [ln for ln in text.splitlines()
            if not (ln.lstrip().startswith("- ") and marker in ln)]
   if heading in lines:                      # exact line match, not substring
       lines.insert(lines.index(heading) + 1, bullet)
   else:
       if lines and lines[-1].strip():
           lines.append("")
       lines += [heading, "", bullet]
   p.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
   '
   ```
   Non-fatal — `overview.md` is a derived narrative artefact; a failure here never blocks finalize.

4. **Rebuild `context_brief.md` (last).**
   ```
   python3 "$WIKI_INGEST_SCRIPTS/rebuild_context_brief.py" --wiki-root "$WIKI_ROOT"
   ```
   Same call shape as cogni-wiki's `wiki-ingest` Step 8.5. Runs **after** sub-steps 1–3 so the brief's top-entities-by-inbound-backlinks + health snapshot reflect the gate's writes (the reverse links de-orphan the cited sources). Non-fatal — `context_brief.md` is a derived artefact, regenerated next dispatch.

### 11. Final summary

Print ≤ 10 lines:

- Project: `<topic>` at `<project_path>`
- Wiki: `<WIKI_ROOT>`
- Synthesis page: `wiki/syntheses/<slug>.md` (sources cited: `<N_SOURCES>`)
- Cycle-guard: `input_shape=citation-manifest`, `direct_self_cycles=0`, `cross_lineage_overlap=<N>`
- Verify lineage: `verify-v<N>.json` — verbatim=`<N>` paraphrase=`<N>` synthesis=`<N>` unsupported=`<N>` (round `<R>` of 2)
- Binding: total deposited projects now `<count>`
- Wiki updates (conditional on Step 7 + Step 8 outcomes):
  - On `INDEX_OK=yes` + new deposit: `index.md (Syntheses), entries_count +1, context_brief.md refreshed`
  - On `INDEX_OK=yes` + `--overwrite` re-deposit: `index.md (Syntheses) updated, entries_count unchanged (overwrite), context_brief.md refreshed`
  - On `INDEX_OK=no`: `⚠ index.md FAILED — synthesis on disk but NOT yet indexed; run wiki-lint --fix=entries_count_drift (and re-run finalize against the existing page if you also want the index entry); context_brief.md refreshed`
- Conformance gate (Step 10.5): `wiki-lint --fix=all → <F> fixed, <X> failed; wiki-health → <E> errors`. On `<E> == 0`: `✓ wiki-health clean`. On `<E> > 0`: `⚠ wiki-health: <E> error(s) after finalize: <class> on <page>, …` (loud, non-fatal). Plus `overview.md refreshed`.
- Next: M10 will rebuild `knowledge-query` / `knowledge-dashboard` / `knowledge-resume` / `knowledge-refresh` on the new manifests. Today, `cogni-wiki:wiki-query --wiki-root <WIKI_ROOT>` already reads the new synthesis as part of the corpus.

If Step 2 surfaced `unsupported > 0`, repeat the `⚠ Finalized with <N> unsupported citations` warning so the audit trail is on-screen.

## Edge cases

- **Re-run on an already-finalized project.** `<WIKI_ROOT>/wiki/syntheses/<slug>.md` exists — abort with the `--overwrite` nudge. If `--overwrite`, the synthesis page is rewritten but `config_bump.py --delta 1` would over-count; pass `--overwrite` only when the previous synthesis page is being replaced after a hand-edit, and reconcile entries_count via `wiki-lint --fix=entries_count_drift` afterward.
- **No citations in the manifest.** Steps 5–6 still produce a synthesis page; the `## References` block becomes `_No external citations recorded in citation-manifest.json._`. cycle-guard's `wiki_pages_cited` will be `[]` and `status: clear` — surface in Step 11.
- **Plan.json missing topic.** Step 3 falls back to `--synthesis-slug` if passed, else aborts cleanly.
- **Cited source page missing on disk.** Step 5's reference-row falls back to the slug as the title AND emits **no** `[[<slug>]]` backlink (a bare link to a missing page would be a `broken_wikilink` error that fails the Step 10.5 health gate). cycle-guard's `wiki_pages_cited_missing` will list the slug; surface in Step 11 as `⚠ Missing pages: <slug1>, <slug2>` so the operator knows the wiki was modified between ingest and finalize.
- **Duplicate binding entry without `--overwrite`.** Step 9's `append-project` returns `existing_slug` (the SKILL did NOT pass `--allow-update` because `--overwrite` was off). Steps 6–8 already landed the synthesis page → the wiki has the new page but `binding.json::research_projects[]` still records the prior deposit's `report_path` / `deposited_at`. Step 11 surfaces the loud `⚠ Binding append SKIPPED` warning verbatim from Step 9. Reconcile via `--overwrite` re-run (which passes `--allow-update` per Step 9's contract), or accept the asymmetric state — both are valid operator decisions.

## Out of scope

- Does NOT re-run the verifier, the composer, or the ingester. M9 reads the latest verified draft + manifest as-is.
- Renders an IEEE-style numbered reference list (`**[N]** Publisher, "Title". [URL](URL) — [[<slug>]]`, first-appearance order matching the composer's inline `[N]`; #300/#301, v0.1.4). The reference backlink is a **bare** `[[<slug>]]` (not path-prefixed `[[sources/<slug>]]`) so the synthesis→source edge registers in cogni-wiki's link graph (#308, Slice 16). Does NOT support APA / MLA / Chicago rendering — those can be derived from the same citation-manifest if a bibliography skill ships.
- Does NOT update `topic_lineage.covered_themes[]` in the binding — that field is reserved for M10's manifest-aware dashboard rebuild.
- Does NOT support cross-page substitute-citation search or transitive cycle detection on the new manifest shape (the adapter handles direct cycles only — same posture as M9's "smallest necessary change" framing).
- **Localizes the reference-section heading** per `plan.json::output_language` via `_knowledge_lib.ref_heading` (`de→Referenzen`, default→English; #301, v0.1.4), and strips the composer's heading language-independently. Does NOT itself translate body content — the draft body language is the composer's responsibility (it honours `OUTPUT_LANGUAGE`); finalize deposits the verified body verbatim.
- Does NOT dispatch the `lineage-stamp.py` helper — v0.1.0 projects do not write `raw/research-<slug>/`, so the stamp helper has no work to do; the `derived_from_research` field is set inline in Step 5's frontmatter.

## Output

- `<WIKI_ROOT>/wiki/syntheses/<synthesis-slug>.md` — the deposited synthesis page (frontmatter + verified draft body + `## References` list).
- `<WIKI_ROOT>/wiki/index.md` — updated with a new entry under `## Syntheses` (or the category created on first finalize).
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by 1.
- `<WIKI_ROOT>/wiki/context_brief.md` — refreshed.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] finalize | …` line.
- `<knowledge-root>/.cogni-knowledge/binding.json` — one new entry in `research_projects[]` with `report_source: "wiki"`.
- `<WIKI_ROOT>/wiki/<type>/<cited-slug>.md` — each cited page gains a reverse `[[<synthesis-slug>]]` backlink (Step 10.5 `lint --fix=reverse_link_missing`), de-orphaning the synthesis.
- `<WIKI_ROOT>/wiki/overview.md` — refreshed with a `## Recent syntheses` bullet for this synthesis (Step 10.5).

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
- `cogni-wiki/skills/wiki-lint/scripts/lint_wiki.py --help` — Step 10.5 conformance gate (`--fix=all`)
- `cogni-wiki/skills/wiki-health/scripts/health.py --help` — Step 10.5 structural assertion
