# _cycle_guard_lib.sh - shared fixture builder for the cycle-guard tests.
# Source from each test_cycle_guard_*.sh; do not execute directly.
#
# Provides:
#   mk_knowledge_base <KB> <wiki_slug>            - .cogni-wiki + binding skeleton
#   mk_research_project <PROJ> <slug>             - .metadata/project-config + dirs
#   set_report_source <PROJ> <source>             - rewrite report_source in config
#   mk_wiki_page <KB> <type> <slug> <derived_from> - wiki page with frontmatter
#   add_wiki_citation <PROJ> <src-id> <wiki-slug> <page-slug>
#                                                  - add 02-sources entry citing
#                                                    wiki://<wiki-slug>/<page-slug>
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
