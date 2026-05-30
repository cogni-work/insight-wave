# _cycle_guard_lib.sh - shared fixture builder for the cycle-guard tests.
# Source from each test_cycle_guard_*.sh; do not execute directly.
#
# TODO (post-M9 follow-up sweep, not blocking): the existing five
# test_cycle_guard_*.sh tests still inline their own fixture code (which is
# what this lib was extracted from at v0.0.24). Migrate them to source this
# lib so it becomes the single source of truth for cycle-guard fixtures.
# Deferred from M9 (PR #282) to keep slice scope tight; test_finalize_contract.sh
# already sources this lib and exercises both legacy + v0.1.0 helper paths.
#
# Provides:
#   mk_knowledge_base <KB> <wiki_slug>            - .cogni-wiki + binding skeleton
#   mk_research_project <PROJ> <slug>             - .metadata/project-config + dirs
#                                                   (legacy v0.0.x cogni-research layout)
#   mk_v01_project <PROJ> <slug>                  - v0.1.0 inverted-pipeline layout
#                                                   (.metadata/citation-manifest.json +
#                                                   plan.json + output/draft-v1.md)
#   set_report_source <PROJ> <source>             - rewrite report_source in config
#   mk_wiki_page <KB> <type> <slug> <derived_from> - wiki page with frontmatter
#   mk_distilled_page <KB> <dir> <type> <slug> <distilled_from> <backing>...
#                                                  - real Phase-4.5 distilled page
#                                                    (distilled_claims: + sources:,
#                                                    no derived_from_research; #344)
#   add_wiki_citation <PROJ> <src-id> <wiki-slug> <page-slug>
#                                                  - add 02-sources entry citing
#                                                    wiki://<wiki-slug>/<page-slug> (legacy)
#   add_manifest_citation <PROJ> <wiki-slug> <claim-id>
#                                                  - append a citation entry to
#                                                    .metadata/citation-manifest.json (v0.1.0)
#   append_binding_entry <KB> <slug> <project_path> <report_path>
#                                                  - append a deposited project

mk_knowledge_base() {
  local kb="$1" wiki_slug="$2"
  mkdir -p "$kb/.cogni-wiki" "$kb/.cogni-knowledge" "$kb/wiki/concepts" "$kb/wiki/syntheses"
  cat > "$kb/.cogni-wiki/config.json" <<EOF
{"name": "Test", "slug": "$wiki_slug", "schema_version": "0.0.5"}
EOF
  cat > "$kb/.cogni-knowledge/binding.json" <<EOF
{
  "knowledge_slug": "test-kb",
  "knowledge_title": "Test KB",
  "wiki_path": "$kb",
  "research_projects": [],
  "topic_lineage": {"covered_themes": [], "open_themes": []},
  "created": "2026-05-20",
  "schema_version": "0.0.2"
}
EOF
}

mk_research_project() {
  local proj="$1" slug="$2"
  mkdir -p "$proj/.metadata" \
           "$proj/00-sub-questions/data" \
           "$proj/01-contexts/data" \
           "$proj/02-sources/data" \
           "$proj/03-report-claims/data" \
           "$proj/output"
  cat > "$proj/.metadata/project-config.json" <<EOF
{"slug": "$slug", "topic": "test", "report_source": "wiki"}
EOF
  touch "$proj/output/report.md"
}

set_report_source() {
  local proj="$1" src="$2"
  python3 - "$proj" "$src" <<'PY'
import json, sys
proj, src = sys.argv[1], sys.argv[2]
p = f"{proj}/.metadata/project-config.json"
with open(p) as fh: d = json.load(fh)
d["report_source"] = src
with open(p, "w") as fh: json.dump(d, fh, indent=2)
PY
}

mk_wiki_page() {
  local kb="$1" type="$2" slug="$3" derived_from="$4"
  mkdir -p "$kb/wiki/$type"
  local stamp=""
  if [ -n "$derived_from" ]; then
    stamp=$'\nderived_from_research: '"$derived_from"
  fi
  cat > "$kb/wiki/$type/$slug.md" <<EOF
---
id: $slug
title: $slug
type: ${type%s}
tags: []
created: 2026-05-20
updated: 2026-05-20
sources: []$stamp
---
Body.
EOF
}

mk_distilled_page() {
  # mk_distilled_page <KB> <dir> <type> <slug> <distilled_from_project> <backing_slug>...
  # A real Phase-4.5 distilled page (#336/#342): carries `distilled_claims:` +
  # `distilled_from_research:` and a page-level `sources:` block of
  # `wiki://<backing-slug>` lines (the union of its claims' backlinks).
  # Crucially it has NO `derived_from_research:` of its own — that is what marks
  # it for cycle-guard's #344 see-through trace. Mirrors
  # scripts/concept-store.py::_render_page closely enough for cycle-guard's
  # frontmatter parser (which reads the page-level `sources:` block).
  local kb="$1" dir="$2" type="$3" slug="$4" dfr="$5"; shift 5
  mkdir -p "$kb/wiki/$dir"
  local sources_block="sources:"
  local refs="" backlinks="" first=1
  for b in "$@"; do
    sources_block="$sources_block"$'\n'"  - wiki://$b"
    if [ "$first" -eq 1 ]; then
      refs="\"$b#clm-001\""; backlinks="\"$b\""; first=0
    else
      refs="$refs, \"$b#clm-001\""; backlinks="$backlinks, \"$b\""
    fi
  done
  cat > "$kb/wiki/$dir/$slug.md" <<EOF
---
id: $slug
title: $slug
type: $type
tags: [$type]
created: 2026-05-20
updated: 2026-05-20
$sources_block
related: []
status: distilled
distilled_from_research:
  - $dfr
distilled_claims:
  - claim_id: dcl-001
    text: "A cross-source distilled fact about $slug."
    norm_key: "distilled fact $slug"
    backlinks: [$backlinks]
    source_claim_refs: [$refs]
    created: 2026-05-20
    updated: 2026-05-20
---
<!-- MACHINE-OWNED:SUMMARY:START -->
Summary.
<!-- MACHINE-OWNED:SUMMARY:END -->
EOF
}

add_wiki_citation() {
  local proj="$1" src_id="$2" wiki_slug="$3" page_slug="$4"
  cat > "$proj/02-sources/data/$src_id.md" <<EOF
---
dc:identifier: $src_id
url: wiki://$wiki_slug/$page_slug
title: cited page
publisher: cogni-wiki:$wiki_slug
---
EOF
}

append_binding_entry() {
  local kb="$1" slug="$2" project_path="$3" report_path="$4"
  python3 - "$kb" "$slug" "$project_path" "$report_path" <<'PY'
import json, sys
kb, slug, project_path, report_path = sys.argv[1:5]
p = f"{kb}/.cogni-knowledge/binding.json"
with open(p) as fh: d = json.load(fh)
d["research_projects"].append({
    "slug": slug,
    "deposited_at": "2026-05-20",
    "report_path": report_path,
    "report_source": "wiki",
    "project_path": project_path,
})
with open(p, "w") as fh: json.dump(d, fh, indent=2)
PY
}

# v0.1.0 inverted-pipeline project layout: .metadata/ holds plan, citation
# manifest, and project-config; no 02-sources/data/ dir. Used by the M9
# finalize contract test to exercise cycle-guard's citation-manifest
# fallback path. Citation entries are appended one at a time via
# add_manifest_citation below.
mk_v01_project() {
  local proj="$1" slug="$2"
  mkdir -p "$proj/.metadata" "$proj/output"
  cat > "$proj/.metadata/project-config.json" <<EOF
{"slug": "$slug", "topic": "test", "report_source": "wiki"}
EOF
  cat > "$proj/.metadata/citation-manifest.json" <<EOF
{
  "schema_version": "0.1.0",
  "draft_version": 1,
  "citations": []
}
EOF
  cat > "$proj/.metadata/plan.json" <<EOF
{"schema_version": "0.1.0", "topic": "$slug topic"}
EOF
  : > "$proj/output/draft-v1.md"
}

add_manifest_citation() {
  local proj="$1" wiki_slug="$2" claim_id="$3"
  python3 - "$proj" "$wiki_slug" "$claim_id" <<'PY'
import json, sys
proj, wiki_slug, claim_id = sys.argv[1:4]
p = f"{proj}/.metadata/citation-manifest.json"
with open(p) as fh: d = json.load(fh)
position = f"01:{len(d.get('citations', [])) + 1:02d}"
d.setdefault("citations", []).append({
    "draft_position": position,
    "wiki_slug": wiki_slug,
    "claim_id": claim_id or None,
})
with open(p, "w") as fh: json.dump(d, fh, indent=2)
PY
}
