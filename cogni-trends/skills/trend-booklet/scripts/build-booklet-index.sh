#!/usr/bin/env bash
set -euo pipefail
# build-booklet-index.sh
# Version: 1.0.0
# Purpose: Build the per-candidate index for trend-booklet by joining
#          trend-scout output, the value model, and the 4 enriched-trends
#          dimension files. Emits .logs/booklet-index.json with one entry
#          per candidate plus theme back-references.
# Category: utilities
#
# Usage: build-booklet-index.sh <PROJECT_PATH>
#
# Inputs:
#   ${PROJECT_PATH}/.metadata/trend-scout-output.json
#   ${PROJECT_PATH}/tips-value-model.json
#   ${PROJECT_PATH}/.logs/enriched-trends-{externe-effekte,digitale-wertetreiber,neue-horizonte,digitales-fundament}.json
#
# Output:
#   ${PROJECT_PATH}/.logs/booklet-index.json (array of per-candidate entries)
#
# Stdout (envelope):
#   {"success":true,"data":{"index_path":"...","candidates_total":N,"orphans_total":M,"by_dimension":{...}},"error":null}
#   {"success":false,"data":null,"error":"..."}
#
# Exit codes:
#   0 = success
#   1 = missing PROJECT_PATH or required input file
#   2 = JSON parse failure

if [[ -z "${1:-}" ]]; then
    echo '{"success":false,"data":null,"error":"missing_project_path"}'
    exit 1
fi

PROJECT_PATH="$1"

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "{\"success\":false,\"data\":null,\"error\":\"project_path_not_found:${PROJECT_PATH}\"}"
    exit 1
fi

python3 - "$PROJECT_PATH" <<'PY'
import json, os, sys

project_path = sys.argv[1]
logs_dir = os.path.join(project_path, ".logs")
meta_dir = os.path.join(project_path, ".metadata")

scout_path = os.path.join(meta_dir, "trend-scout-output.json")
vm_path = os.path.join(project_path, "tips-value-model.json")

DIMENSIONS = [
    "externe-effekte",
    "digitale-wertetreiber",
    "neue-horizonte",
    "digitales-fundament",
]

def fail(error):
    print(json.dumps({"success": False, "data": None, "error": error}))
    sys.exit(2 if "parse" in error else 1)

for required in (scout_path, vm_path):
    if not os.path.isfile(required):
        fail(f"missing_input:{required}")

try:
    scout = json.load(open(scout_path, encoding="utf-8"))
except Exception as e:
    fail(f"parse_failure:trend-scout-output.json:{e}")

try:
    vm = json.load(open(vm_path, encoding="utf-8"))
except Exception as e:
    fail(f"parse_failure:tips-value-model.json:{e}")

# Load enriched-trends per dimension; tolerate missing files but record gaps.
enriched = {}
missing_enriched = []
for dim in DIMENSIONS:
    p = os.path.join(logs_dir, f"enriched-trends-{dim}.json")
    if not os.path.isfile(p):
        missing_enriched.append(p)
        enriched[dim] = {"trends": []}
        continue
    try:
        enriched[dim] = json.load(open(p, encoding="utf-8"))
    except Exception as e:
        fail(f"parse_failure:enriched-trends-{dim}.json:{e}")

# Build candidate_ref -> [{theme_id, theme_name, role}] map by walking
# investment_themes -> value_chains -> chain.{trend, implications, possibilities, foundation_requirements}.
# A candidate may appear under multiple themes / roles; preserve all.
theme_map = {}
themes = vm.get("investment_themes") or []
chains = vm.get("value_chains") or []

themes_by_id = {t.get("theme_id") or t.get("investment_theme_id"): t for t in themes if isinstance(t, dict)}

def _add_backref(cref, theme_id, role):
    if not cref:
        return
    t = themes_by_id.get(theme_id)
    name = (t.get("name") if isinstance(t, dict) else None) or theme_id
    theme_map.setdefault(cref, []).append({
        "theme_id": theme_id,
        "theme_name": name,
        "role": role,
    })

for chain in chains:
    if not isinstance(chain, dict):
        continue
    theme_id = chain.get("investment_theme_ref") or chain.get("theme_id")
    trend = chain.get("trend") or {}
    if isinstance(trend, dict):
        _add_backref(trend.get("candidate_ref"), theme_id, "trend")
    for role_key, role_label in (
        ("implications", "implication"),
        ("possibilities", "possibility"),
        ("foundation_requirements", "foundation"),
    ):
        for entry in chain.get(role_key) or []:
            if isinstance(entry, dict):
                _add_backref(entry.get("candidate_ref"), theme_id, role_label)

# Pull subcategory + keywords + horizon from the scout output candidate items;
# fall back to enriched-trends entries when absent.
items = (scout.get("tips_candidates") or {}).get("items") or []

def _candidate_ref(item):
    return item.get("candidate_ref") or item.get("id") or item.get("ref")

scout_by_ref = {_candidate_ref(it): it for it in items if _candidate_ref(it)}

entries = []
orphans_total = 0
by_dim_counts = {dim: {"candidates": 0, "orphans": 0} for dim in DIMENSIONS}

# Iterate enriched-trends so we always emit per-dimension coverage even when
# the scout-output item is malformed; merge scout fields opportunistically.
for dim in DIMENSIONS:
    for trend in enriched[dim].get("trends") or []:
        cref = trend.get("candidate_ref")
        if not cref:
            continue
        scout_item = scout_by_ref.get(cref) or {}
        backrefs = theme_map.get(cref, [])
        is_orphan = len(backrefs) == 0
        entry = {
            "candidate_ref": cref,
            "name": trend.get("name") or scout_item.get("name") or scout_item.get("title") or cref,
            "dimension": dim,
            "subcategory": scout_item.get("subcategory") or scout_item.get("sub_category") or "",
            "horizon": trend.get("horizon") or scout_item.get("horizon") or "",
            "keywords": scout_item.get("keywords") or [],
            "claims_refs": trend.get("claims_refs") or [],
            "theme_backrefs": backrefs,
        }
        entries.append(entry)
        by_dim_counts[dim]["candidates"] += 1
        if is_orphan:
            by_dim_counts[dim]["orphans"] += 1
            orphans_total += 1

# Also emit explicit value_model.orphan_candidates entries that may not have
# made it into the enriched-trends pass (rare but possible if value-modeler
# tracks them separately).
for orphan in vm.get("orphan_candidates") or []:
    if not isinstance(orphan, dict):
        continue
    cref = orphan.get("candidate_ref") or orphan.get("id")
    if not cref:
        continue
    if any(e["candidate_ref"] == cref for e in entries):
        continue
    dim = orphan.get("dimension") or ""
    entries.append({
        "candidate_ref": cref,
        "name": orphan.get("name") or cref,
        "dimension": dim,
        "subcategory": orphan.get("subcategory") or "",
        "horizon": orphan.get("horizon") or "",
        "keywords": orphan.get("keywords") or [],
        "claims_refs": [],
        "theme_backrefs": [],
    })
    if dim in by_dim_counts:
        by_dim_counts[dim]["candidates"] += 1
        by_dim_counts[dim]["orphans"] += 1
    orphans_total += 1

# Persist the index.
os.makedirs(logs_dir, exist_ok=True)
index_path = os.path.join(logs_dir, "booklet-index.json")
with open(index_path, "w", encoding="utf-8") as f:
    json.dump(entries, f, ensure_ascii=False, indent=2)

print(json.dumps({
    "success": True,
    "data": {
        "index_path": index_path,
        "candidates_total": len(entries),
        "orphans_total": orphans_total,
        "by_dimension": by_dim_counts,
        "missing_enriched_files": missing_enriched,
    },
    "error": None,
}, ensure_ascii=False))
PY
