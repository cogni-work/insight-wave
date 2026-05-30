---
name: knowledge-finalize
description: "Phase 7 of the inverted pipeline — deposits the verified draft as a wiki synthesis page, closing the compounding loop. Reads the latest verified draft + its verify manifest + citation manifest, runs cycle-guard.py to refuse self-citing loops, atomically writes the draft to <wiki>/syntheses/<slug>.md with type: synthesis frontmatter (incl. derived_from_research), updates wiki/index.md, bumps entries_count, rebuilds context_brief.md, appends a research_projects[] entry to binding.json and a finalize line to wiki/log.md, and runs a conformance gate (wiki-lint --fix=all + wiki-health) with bare [[slug]] backlinks that de-orphan the cited sources. Then dispatches the wiki-contradictor agent for a zero-network contradiction tripwire and the wiki-reviewer agent for an advisory structural-quality score — both fail-soft, non-blocking observability. The deposited synthesis becomes visible to future knowledge-compose runs as cross-source framing. Use this skill whenever the user says 'finalize the draft', 'deposit the synthesis', 'phase 7 of the knowledge pipeline', 'knowledge finalize', or 'land the verified draft'."
allowed-tools: Read, Write, Bash, Task
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
| `--no-contradictor` | No | Skip the Step 10.6 contradiction tripwire. Default: OFF (tripwire runs). Pass this as cheap insurance against false-positive flooding when sustained `medium`/`low` noise is dominant in real runs; the synthesis is still deposited and the Step 10.5 conformance gate still runs. |
| `--no-reviewer` | No | Skip the Step 10.7 structural-quality review. Default: OFF (reviewer runs). Pass to suppress the advisory structural score on a run where you only want the deposit + conformance gate; the synthesis is still deposited and every other step still runs. Mirrors `--no-contradictor`. |
| `--no-open-questions` | No | Skip the Step 10.5 sub-step 5 `rebuild_open_questions.py` refresh. Default: OFF (rebuild runs). Pass when investigating a rebuild bug or running a no-side-effect finalize; the synthesis still lands and the rest of the Step 10.5 gate still runs. Mirrors `--no-contradictor`. |
| `--no-research-gaps` | No | Narrow the Step 10.5 sub-step 5 rebuild to lint findings only — skip streaming this project's `wiki-coverage.json` research-time gaps (`research_uncovered` / `research_partial`) into `open_questions.md`. Default: OFF (gaps stream). Unlike `--no-open-questions` this does **not** skip the sub-step; the seven existing lint classes still reconcile. The Step 10 `sqs=` log-line suffix is unaffected. Useful for debugging the payload-builder path. |

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
  # pick the NEWEST cached version, not the lexically-first. Consider ONLY
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

`<project-slug>` is the slug field from `<project_path>/.metadata/project-config.json::slug` (the cogni-research project slug recorded at compose time). `--report-source wiki` is hard-coded — the inverted pipeline only ever produces wiki-mode deposits, so the legacy `_read_report_source` fallback isn't relevant here.

The script's manifest-shape fallback walks `<project>/.metadata/citation-manifest.json` when the legacy `02-sources/data/src-*.md` glob is empty. Confirm `data.input_shape == "citation-manifest"` in the JSON envelope as a positive signal the adapter ran (informational; not a gate).

Interpret return:

- **Exit 0, `status: clear`** — proceed. `cross_lineage_overlap[]` may be non-empty; surface count in Step 11.
- **Exit 0, `status: not_applicable`** — should not happen (`--report-source wiki` is explicit). Treat as defence-in-depth; proceed.
- **Exit 1, `status: cycle_detected`** — abort. Print `direct_self_cycles[]` + remediation: "The synthesis would cite a wiki page derived from this same project — that's a self-citing loop. Rename the synthesis (`--synthesis-slug <other>`), narrow the topic, or hand-edit the draft to drop the self-referential citations."
- **Exit 1, `status: manifest_unreadable`** — the citation manifest at `.metadata/citation-manifest.json` cannot be parsed (corrupt JSON, I/O error). Abort with the script's `error` field verbatim; remediate by re-running `knowledge-compose` to regenerate the manifest. **Do not proceed** — depositing a synthesis whose lineage cannot be checked is the exact failure mode the guard exists to prevent.

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
VERIFY_VERBATIM=<verbatim count from Step 2> \
VERIFY_PARAPHRASE=<paraphrase count from Step 2> \
VERIFY_SYNTHESIS=<synthesis count from Step 2> \
VERIFY_UNSUPPORTED=<unsupported count from Step 2> \
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
# the four verdict counts already captured at Step 2
# (verify-vN.json::counts) are threaded in so the synthesis-page frontmatter
# carries a machine-readable record of WHAT verification ran. These describe a
# citation-consistent (zero-network) check — see verification: key below.
v_verbatim = int(os.environ.get("VERIFY_VERBATIM", "0"))
v_paraphrase = int(os.environ.get("VERIFY_PARAPHRASE", "0"))
v_synthesis = int(os.environ.get("VERIFY_SYNTHESIS", "0"))
v_unsupported = int(os.environ.get("VERIFY_UNSUPPORTED", "0"))
verification_ratio = f"verbatim={v_verbatim} paraphrase={v_paraphrase} synthesis={v_synthesis} unsupported={v_unsupported}"

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
# Citation-format reference-string selection (#309 P2). ieee + chicago BOTH render
# the numbered <sup>[N]</sup> inline shape, so the renumber pass + scans below are
# unchanged across them — only the bibliography STRING differs (ieee:
# `Publisher, "Title"`; chicago: `Publisher. "Title."`). apa/mla/harvard are the
# staged author-date follow-up: the composer renders them as numbered, so they
# fall through to the ieee string here too (no author-date reference rows until
# the format-aware finalize rework lands). wikilink aliases to ieee.
citation_format = (plan.get("citation_format") or "ieee").strip().lower()
if citation_format == "wikilink":
    citation_format = "ieee"
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
# (wiki-composer cites prior syntheses with claim_id: null), then the four
# distilled dirs (concepts/entities/summaries/learnings — the composer cites
# them with a dcl-NNN claim_id, no external URL). page_kind
# gates whether the reference row gets a bare [[<slug>]] backlink below: a page
# that exists (source / synthesis / distilled) does; a missing page (page_kind
# None) does not.
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
    for kind, dirname in (
        ("source", "sources"),
        ("synthesis", "syntheses"),
        ("concept", "concepts"),
        ("entity", "entities"),
        ("summary", "summaries"),
        ("learning", "learnings"),
    ):
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
    if citation_format == "chicago":
        # Chicago bibliography string: publisher/author-first, period-separated.
        bib = (publisher + '. "' + title + '."') if publisher else ('"' + title + '."')
    else:
        # IEEE (default; also the staged apa/mla/harvard numbered fallback).
        bib = (publisher + ', "' + title + '"') if publisher else ('"' + title + '"')
    # Numbered entry (ieee/chicago). Clickable [URL](URL) when the source page
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
    # declare WHAT "verified" means on the durable artefact. verification
    # is a fixed enum — the Phase 6 verifier scored each citation's draft_sentence
    # against the cited page's ingest-time pre_extracted_claims:, zero-network, no
    # live-source re-fetch. verification_ratio is the same verify-vN.json::counts
    # the dashboard surfaces, kept as ONE double-quoted flat string scalar (NOT a
    # nested `verification_counts: {verbatim: 4, ...}` map) on purpose: it matches
    # cogni-wiki's existing flat-frontmatter convention (same shape as
    # draft_revision_round) so _wikilib.parse_frontmatter reads it without YAML-map
    # support, and it stays an additive, tolerated key. If a future consumer needs
    # structured access, switching to a nested map is the right moment to do it
    # (a breaking frontmatter change). For live-source re-verification: knowledge-refresh --resweep.
    "verification: citation_consistent_zero_network\n"
    'verification_ratio: "' + verification_ratio + '"\n'
    "---\n"
)

# Strip a leading H1 from the draft body (we set our own title via frontmatter).
body = draft.lstrip()
if body.startswith("# "):
    nl = body.find("\n")
    body = body[nl + 1 :].lstrip() if nl >= 0 else ""

# Strip the composer's own reference section (it re-emits below) so the page
# never carries two; LANGUAGE-INDEPENDENT (localized heading + English, anchored
# so a heading on the first/last body line still matches) with a
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
# Step 10.6 (contradiction tripwire) reuses the page_kind resolution
# this subprocess already did — passing the filtered claim-bearing slug
# list through avoids a second pass over the citation manifest in the
# orchestrator and keeps the page-kind decision in one place. The
# contradictor compares against any page with a claim block:
# pre_extracted_claims: (sources) or distilled_claims: (the four distilled
# kinds — concept/entity/summary/learning). Synthesis-page citations are
# excluded (synthesis pages carry no claim block); missing pages
# (page_kind None) are excluded here and reported via missing_pages[].
# Var name kept (CITED_SOURCE_SLUGS) for input-contract stability; the
# semantics cover source + distilled slugs.
_CLAIM_BEARING_KINDS = {"source", "concept", "entity", "summary", "learning"}
cited_source_slugs = [s for s in cited_slugs if page_kind_by_slug.get(s) in _CLAIM_BEARING_KINDS]
print(json.dumps({
    "synthesis_path": str(out_path.relative_to(wiki_root).as_posix()),
    "n_sources": len(cited_slugs),
    "n_synthesis_citations": sum(1 for k in page_kind_by_slug.values() if k == "synthesis"),
    "n_missing_pages": n_missing,
    "topic": topic,
    "output_language": output_language,
    "cited_source_slugs": cited_source_slugs,
}))
'
```

The trailing JSON line is captured for the final summary. Steps 5 and 6 are bundled into this single subprocess to keep the compose + write atomic relative to retry — a re-run sees the same wiki state.

### 7. Update wiki/index.md (cogni-wiki helper)

```
python3 "$WIKI_INGEST_SCRIPTS/wiki_index_update.py" \
    --wiki-root "$WIKI_ROOT" \
    --slug <synthesis-slug> \
    --summary "<a crisp one-line description of the synthesis topic>" \
    --category "Syntheses" \
    --max-summary 240
```

Same call shape as `knowledge-ingest/SKILL.md` Step 4.2, with `--category "Syntheses"` instead of `"Sources"`. Write the summary as one crisp, complete sentence (no character count); the `--max-summary 240` defensive backstop clamps on a word boundary with `…` only if it runs long, guarding `wiki/index.md` against a mid-word artifact. The helper is lock-wrapped (`_wiki_lock` at `<WIKI_ROOT>/.cogni-wiki/.lock`).

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

if [ -n "$GAP_SQS" ]; then
    printf '## [%s] finalize | project=%s slug=%s draft=v%s round=%s sources=%s sqs=%s\n' \
        "$DATE_STAMP" "$TOPIC" "$SYNTHESIS_SLUG" "$DRAFT_VERSION" "$REVISION_ROUND" "$N_SOURCES" "$GAP_SQS" \
        >> "${WIKI_ROOT}/wiki/log.md"
else
    printf '## [%s] finalize | project=%s slug=%s draft=v%s round=%s sources=%s\n' \
        "$DATE_STAMP" "$TOPIC" "$SYNTHESIS_SLUG" "$DRAFT_VERSION" "$REVISION_ROUND" "$N_SOURCES" \
        >> "${WIKI_ROOT}/wiki/log.md"
fi
```

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
   `--fix=all` applies the five safe classes (`lint_wiki.py` `FIX_CLASSES`). The load-bearing one is **`reverse_link_missing`**: the bare `[[<slug>]]` references this finalize just wrote are forward edges synthesis→source, so lint backfills the reverse source→synthesis `[[<synthesis-slug>]]` (a `## See also` append on each cited source) — de-orphaning the synthesis. The others are housekeeping: `frontmatter_defaults`, `entries_count_drift` (reconciles `entries_count` to the on-disk truth — supersedes Step 8's conditional bump on any drift), `alphabetisation`, and `synthesis_no_wiki_source` (a no-op — Step 5 already wrote `wiki://<slug>` sources). Capture the envelope; surface `data.fixed[]` / `data.failed[]` counts in the Step 11 summary. **Non-fatal per item** — a per-page fix failure lands in `data.failed[]` and does not block finalize. (`orphan_page` is NOT a `--fix` class — it is suggest-only; 0 orphans comes from the inbound links the bare refs + this reverse-link backfill create, never from `--fix`.)

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

3. **Refresh `wiki/overview.md`.** Keep the "state of the wiki" page from going stale. Deterministic, no extra LLM pass — ensure a `## Recent syntheses` heading exists and refresh a single bullet for this synthesis (idempotent on the slug). The dedup removes only this slug's prior **bullet** (a `- … [[slug]] …` list item), never prose that merely mentions `[[slug]]`; the heading is matched by exact line, never substring. `overview.md` is not graph-scanned, so this is purely freshness:
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

5. **Refresh `wiki/open_questions.md`.** The persistent, cross-session data-gap backlog. cogni-wiki maintains this file as part of `wiki-lint` Step 8.5 — every lint dispatch reconciles the checklist (items that disappear from the current lint output flip to `- [x]` with today's date; closed items > 90 days old are trimmed; new findings append as `- [ ]`). The inverted pipeline writes the wiki via forked agents + direct script calls, so cogni-wiki's `wiki-lint` never runs as a gate here — sub-step 5 backfills the rebuild on the finalize path so the backlog tracks finalize-time state instead of going stale until the next interactive `wiki-lint`. It is the tail of the conformance gate: it reads the *post-fix*, *post-overview-refresh* on-disk state (the same state sub-step 2's read-only re-lint asserted), so it belongs after sub-step 4.

   Skip conditions (evaluated in order):

   1. `--dry-run` was passed — silent skip (same posture as Step 10.6; finalize already exits at Step 3 on `--dry-run`, so reaching sub-step 5 under `--dry-run` should never happen — this guard is defence-in-depth).
   2. `--no-open-questions` was passed — log `Open questions rebuild skipped: --no-open-questions` and continue.

   `--no-research-gaps` does **not** skip the sub-step — it narrows the payload. Set `NO_RESEARCH_GAPS=1` when the flag is present (else leave it unset) so the invocation below appends `--no-research-gaps` to the payload builder and only the lint findings stream.

   The rebuild consumes a **merged** findings payload: cogni-wiki's `lint_wiki.py` output (the seven existing classes about *existing* pages) **plus** this project's research-time gaps (`research_uncovered` / `research_partial`) read from `<project>/.metadata/wiki-coverage.json`. `build_open_questions_payload.py` (cogni-knowledge) does the merge in one process and emits a `{success, data: {errors, warnings, info}, meta}` envelope; `rebuild_open_questions.py --findings -` unwraps `data` and reconciles. The research gaps render as two new tail sections (`## Research-time gaps — uncovered` / `## Research-time gaps — partial`).

   ```
   # Run ONLY after the two skip conditions above are evaluated (--dry-run,
   # then --no-open-questions). When --no-research-gaps is set, append it to the
   # payload-builder args so only the lint findings stream (the research gaps
   # are dropped, the seven existing classes still flow).
   #
   # Capture stdout ONLY — no 2>&1: stderr flows to the operator's terminal so a
   # crash traceback stays visible and can never contaminate the single-line
   # JSON envelope on stdout. Mirrors cogni-wiki wiki-lint Step 8.5's
   # `OQ_JSON=$(…) || true` capture exactly.
   OPEN_Q_PAYLOAD=$(python3 "${CLAUDE_PLUGIN_ROOT}/scripts/build_open_questions_payload.py" \
       --wiki-root "$WIKI_ROOT" \
       --project   "$PROJECT_PATH" \
       --wiki-lint "$WIKI_LINT_SCRIPTS/lint_wiki.py" \
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

   **Close-attribution.** `finalize` is now one of `rebuild_open_questions.py`'s `CLOSING_OPS` (`update`, `ingest`, `re-ingest`, `synthesis`, `finalize`). The credit-close flow spans two dispatches and is self-attributing via the Step 10 `sqs=` log line: in *this* dispatch the gap sub-questions are still scored `uncovered`/`partial` in `wiki-coverage.json` (that scan predates this synthesis), so they render **open** as `- [ ] \`sq:<sq_id>\` — …` AND the Step 10 line records `sqs=<sq_id>,…`. After the next `knowledge-curate` re-scores them `covered` (the synthesis is now queryable), the *next* finalize's merged payload no longer lists them as gaps → `reconcile` closes them, and `attribute_close` finds the bare `<sq_id>` inside the earlier finalize line's `sqs=` suffix → `- [x] ~~\`sq:<sq_id>\` — …~~ — closed <date> by finalize`. No second `wiki/log.md` line is written here: the script never logs (that is the SKILL's job), and the Step 10 line is already on disk. A revisor pass that drops a sub-question's coverage is self-correcting — the next curate's `wiki-coverage.json` reopens the gap per `reconcile`'s re-appearing-key semantics.

   **Fail-soft posture (explicit).** Sub-step 5 is a backlog refresh. A non-zero exit, malformed envelope, or `_wiki_lock` contention **never rolls back the synthesis** — the synthesis page, index entry, `entries_count` bump, `binding.json` append, `wiki/log.md` line, and sub-steps 1–4 are all already on disk. The summary surfaces the failure loudly so the operator can run `cogni-wiki:wiki-lint` manually; the next finalize dispatch reconciles. (Verbatim mirror of cogni-wiki Step 8.5's failure-isolation contract; matches Step 10.6's posture.)

   **Concurrency note.** `rebuild_open_questions.py` wraps the parse + reconcile + render + atomic write in `_wikilib._wiki_lock(wiki_root)`, so a concurrent `cogni-wiki:wiki-lint` dispatch from another session serialises rather than corrupts — the two dispatches converge on the on-disk lint findings only (which is the contract).

### 10.6 Contradiction tripwire

Observability-only. Dispatches the `wiki-contradictor` agent to compare the just-deposited synthesis sentence-by-sentence against each cited *source or distilled* page's claim frontmatter (`pre_extracted_claims:` on `wiki/sources/<slug>.md`; `distilled_claims:` on the four distilled dirs `wiki/{concepts,entities,summaries,learnings}/<slug>.md`) and emit a per-finalize `<project_path>/.metadata/contradictor-v<N>.json` envelope (schema `0.1.0`; a distilled finding is shape-identical, carrying a `dcl-NNN` `conflicting_claim_id`) with `kind ∈ {contradiction, unknown}` and `severity ∈ {high, medium, low}`. **Partially defends `references/differentiation-thesis.md` Pillar 2 at synthesis-write time.**

**Fail-soft posture (explicit).** Step 10.6 is observability-only. A Task failure, schema mismatch, or malformed envelope **never rolls back the synthesis** — surfaces in Step 11 as `⚠ contradiction tripwire FAILED — synthesis on disk; re-run interactive cogni-wiki:wiki-lint for forensic detail`. The synthesis already landed at Steps 6–10; the contradictor is a read-only observation layer.

**Skip conditions (evaluated in order).** The orchestrator skips dispatch (and writes no JSON) when any of these hold:

1. `--dry-run` was passed — same posture as Step 4's cycle-guard dry-run skip. Silent.
2. `--no-contradictor` was passed — log `Contradiction tripwire skipped: --no-contradictor` and continue.
3. `len(cited_source_slugs) == 0` — the citation manifest had zero **source-or-distilled-page** citations (Step 5/6's subprocess emits `cited_source_slugs` from the filtered list where `page_kind_by_slug[slug] ∈ {source, concept, entity, summary, learning}`). Log `Contradiction tripwire skipped: empty citation manifest (no claim-bearing peers to compare)` and continue. A synthesis that cites only prior syntheses (rare) falls into this branch — synthesis pages carry no claim block.

**Capture the Step 5/6 subprocess output and convert to dispatch inputs.** The Step 5/6 subprocess emits its trailing JSON line to stdout; capture it into a **heredoc-quoted assignment** so a `topic` containing apostrophes (`L'avenir`), backticks, or `$` is not interpreted by the shell. Then extract the contradictor inputs by piping through `python3` (mirror the Step 2 pattern). `cited_source_slugs` is a JSON array — join to a comma-separated string for the agent's CSV input. Truncate at 30 entries (manifest first-appearance order is preserved by the Step 5/6 builder), surfacing the original size as `N_CITED_PRE_TRUNCATION` for Step 11:

```
# Heredoc with quoted 'EOF' disables ALL shell expansion (no $, no backtick,
# no quote handling) so a topic like "L'avenir de l'AI Act" or a wiki slug
# with shell metacharacters never trips the assignment.
COMPOSE_JSON=$(cat <<'EOF'
<verbatim Step 5/6 trailing JSON line>
EOF
)
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

**Input cap surface.** If `N_CITED_PRE_TRUNCATION > 30`, the CSV above is already truncated; Step 11 surfaces `⚠ contradiction tripwire truncated at 30/$N_CITED_PRE_TRUNCATION pages`. The cap counts source + distilled slugs combined. The agent never sees the dropped slugs and does NOT emit a `truncated_at` field — truncation is observable only via the Step 11 line (envelope `compared_against.sources[]` records exactly what was scored — now source + distilled slugs, key name retained for schema stability).

**Dispatch.**

```
Task(wiki-contradictor,
     WIKI_ROOT=$WIKI_ROOT,
     PROJECT_PATH=$PROJECT_PATH,
     SYNTHESIS_PAGE_PATH=$WIKI_ROOT/wiki/syntheses/$SYNTHESIS_SLUG.md,
     CITED_SOURCE_SLUGS=$CITED_SOURCE_SLUGS_CSV,
     OUTPUT_LANGUAGE=$OUTPUT_LANGUAGE,
     DRAFT_VERSION=$DRAFT_VERSION,
     CONTRADICTOR_OUT_PATH=$PROJECT_PATH/.metadata/contradictor-v$DRAFT_VERSION.json)
```

`OUTPUT_LANGUAGE` is the same value Step 5/6 already threaded from `plan.json::output_language` via the subprocess JSON line (so the agent operates in the synthesis's language and never translates — bilingual coverage is out of scope).

**Interpret return.**

- **`ok: true`** — capture `counts.high`, `counts.medium`, `counts.low`, `counts.unknown`, `counts.total`, the top-3 `high`-severity findings (or all of them if `counts.high <= 3`), `compared_against.missing_pages[]` (for the optional Step 11 TOCTOU note), and the full `cost_estimate` object (`input_words`, `output_words`, `estimated_usd`) — Step 11's cost template needs all three.
- **`ok: false, error: synthesis_unreadable`** — surface `⚠ contradiction tripwire FAILED — synthesis_unreadable: <reason>; synthesis on disk; re-run cogni-wiki:wiki-lint manually` in Step 11. Never block.
- **`ok: false, error: write_failed`** — surface `⚠ contradiction tripwire FAILED — write_failed (output token budget likely exhausted); synthesis on disk; re-run cogni-wiki:wiki-lint manually` in Step 11. Never block.
- **Task dispatch error / no envelope returned** — same fail-soft posture: surface `⚠ contradiction tripwire FAILED — Task dispatch did not return; synthesis on disk` and continue to Step 11.

**Idempotency.** Re-finalize on the same `draft_version` overwrites `contradictor-v<N>.json` — see `## Edge cases` for the full rule (`Re-finalize on the same draft (contradictor idempotency)`).

### 10.7 Structural-quality review

The structural-quality half of the cogni-research feature-parity gate. Step 10.6 (and Phase 6) check **citation-claim alignment** — does each cited sentence match the cited page's claims. This step checks **structural quality** — does the draft address every sub-question, flow coherently, draw on diverse publishers, go deep, and read cleanly in its output language. A synthesis can pass verify (every citation aligned) and still fail structural review (a sub-question treated in one shallow paragraph). Dispatches the `wiki-reviewer` agent to score the draft on the same 5 weighted dimensions cogni-research's reviewer scores (Completeness 0.25, Coherence 0.20, Source-Diversity 0.20, Depth 0.20, Clarity 0.15, with an inline citation-density gate that caps Depth and — #309 P2 — an advisory Word Count Gate that caps Completeness on a `standard`-density deficit / `executive`-density excess) and emit `<project_path>/.metadata/structural-review-v<N>.json` (schema `0.1.1`).

**Advisory-only, fail-soft posture (explicit).** Step 10.7 is observability-only. The reviewer's verdict is **advisory** — the composer is single-pass and the revisor is zero-network/citation-only, so a `revise` verdict drives **no** automated content-expansion fix loop and **never rolls back the synthesis**. A Task failure, schema mismatch, or malformed envelope surfaces in Step 11 as `⚠ structural review FAILED — synthesis on disk; advisory only` and never blocks. The synthesis already landed at Steps 6–10; the reviewer is a read-only scoring layer (same posture as Step 10.6).

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
# falls back to 5000 instead of crashing this resolution subprocess (the reviewer
# also defaults it, but a crash here would blank all three shell vars).
try:
    tw = int(p.get("target_words") or 5000)
    if tw <= 0:
        tw = 5000
except (TypeError, ValueError):
    tw = 5000
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

The reviewer scores `output/draft-v<N>.md` (the project draft) — the deposited synthesis differs only by frontmatter + reference renumber, and the structural dimensions are draft-level. `OUTPUT_LANGUAGE` makes the agent score Clarity natively and exclude the right reference heading from the density gate (never translates — bilingual scoring is out of scope here, same posture as Step 10.6). `TARGET_WORDS` + `PROSE_DENSITY` drive the **advisory** Word Count Gate (deficit under standard / excess under executive) — which caps Completeness and emits a `Word deficit`/`Word excess` issue but never blocks (the composer is single-pass; there is no expansion loop).

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
- Open questions (Step 10.5 sub-step 5): on `success: true`, `✓ Open questions: opened=<n> closed=<n> trimmed=<n>` (the `✓` mirrors the `✓ wiki-health clean` marker above). **When research-time gaps were in play this dispatch** (sum of `data.opened_by_class["research_uncovered"]` + `data.opened_by_class["research_partial"]` > 0), append the split: `✓ Open questions: opened=<n> closed=<n> trimmed=<n> (lint=<L>, research=<R>)`, where `R` is that research sum and `L` is `opened - R`. Omit the parenthetical when `R == 0`. On `success: false` / non-zero exit / malformed JSON, `⚠ open_questions rebuild FAILED — <error>; synthesis on disk; re-run cogni-wiki:wiki-lint manually` (loud, non-fatal). On `--no-open-questions` skip, print the corresponding skip message (per Step 10.5 sub-step 5).
- Contradiction tripwire (Step 10.6): print this block **only on `ok: true` AND (`counts.high > 0` OR `counts.unknown > 0`)** — clean successful runs are silent (no false-alarm noise). On `ok: false` use the FAILED branch below; on skip use the skip-message branch below. Each branch is its own independent surface — gating is per-branch, not joint:
  ```
  ⚠ Contradiction tripwire: <H> high, <M> medium, <L> low, <U> unknown
    - <sanitized_synthesis_excerpt[:80]>...
      ~ <conflicting_page> (high) — <sanitized_note[:60]>
    - <sanitized_synthesis_excerpt[:80]>...
      ~ <conflicting_page> (high) — <sanitized_note[:60]>
  Detail in <project_path>/.metadata/contradictor-v<N>.json.
  Reconcile via cogni-wiki:wiki-update --page <synthesis-slug> --reason contradiction.
  Cost: $<estimated_usd> (<input_words>w in / <output_words>w out).
  ```
  Surface only the top 3 `high`-severity findings by name; `medium`/`low` are count-only on the header line (operator reads the JSON for the rest). `<sanitized_synthesis_excerpt>` / `<sanitized_note>` are the agent's verbatim strings with **backtick / pipe / CR / LF** all replaced by a single space — pass each through `tr '\r\n`|' '    '` (four-character set, four spaces — preserves column width) so a sentence containing inline code, a literal pipe (e.g. in a markdown-table fragment), or an embedded newline does not break the bullet structure. Same discipline-shape as the `TOPIC` `tr '\r\n' '  '` already used at Step 10 for the log line — extended to the two additional markdown-break risk characters that Step 11's bullets carry. `<input_words>` / `<output_words>` come from `cost_estimate.input_words` / `cost_estimate.output_words` captured at Step 10.6.

  Independent branches (not gated on `high`/`unknown`):
  - On `ok: true` AND `compared_against.missing_pages` is non-empty, append one extra line: `⚠ contradiction tripwire: <K> cited page(s) missing on disk at compare time (TOCTOU vs Step 6 deposit): <slug1>, <slug2>, …` — the agent best-effort scored the survivors; the operator may want to investigate concurrent wiki maintenance.
  - On `N_CITED_PRE_TRUNCATION > 30`, append: `⚠ contradiction tripwire truncated at 30/$N_CITED_PRE_TRUNCATION pages (hard cap)`.
  - On `--no-contradictor` / empty-citation-manifest skip, print the corresponding skip message verbatim (per Step 10.6). One skip message per run; if multiple skip conditions hold, the SKILL evaluates them in order and the first-matching message wins (early-exit posture).
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
- `<WIKI_ROOT>/wiki/index.md` — updated with a new entry under `## Syntheses` (or the category created on first finalize).
- `<WIKI_ROOT>/.cogni-wiki/config.json` — `entries_count` bumped by 1.
- `<WIKI_ROOT>/wiki/context_brief.md` — refreshed.
- `<WIKI_ROOT>/wiki/log.md` — one new `## [YYYY-MM-DD] finalize | …` line.
- `<knowledge-root>/.cogni-knowledge/binding.json` — one new entry in `research_projects[]` with `report_source: "wiki"`.
- `<WIKI_ROOT>/wiki/<type>/<cited-slug>.md` — each cited page gains a reverse `[[<synthesis-slug>]]` backlink (Step 10.5 `lint --fix=reverse_link_missing`), de-orphaning the synthesis.
- `<WIKI_ROOT>/wiki/overview.md` — refreshed with a `## Recent syntheses` bullet for this synthesis (Step 10.5).
- `<WIKI_ROOT>/wiki/open_questions.md` — refreshed (Step 10.5 sub-step 5). Skipped on `--dry-run` / `--no-open-questions`.
- `<project_path>/.metadata/contradictor-v<N>.json` — Step 10.6 contradiction tripwire findings (schema `0.1.0`). Written when the contradictor agent returns `ok: true` and at least one source-page peer was compared; absent on skip paths (`--dry-run`, `--no-contradictor`, empty citation manifest) and on `ok: false` failure paths.
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
