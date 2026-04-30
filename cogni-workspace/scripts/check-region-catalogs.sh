#!/usr/bin/env bash
# check-region-catalogs.sh — Cross-plugin drift checker for the region catalogs.
#
# Verifies that the region/market keys are consistent across:
#   - cogni-portfolio/skills/portfolio-setup/references/regions.json     (broadest catalog)
#   - cogni-trends/skills/trend-report/references/region-authority-sources.json
#   - cogni-research/references/market-sources.json
#
# Also verifies that cogni-trends DACH region references all CLAUDE.md-curated
# DACH authority sources. The curated list is loaded from
# cogni-workspace/references/curated-region-sources.json — the single source of
# truth synced with CLAUDE.md's "Multilingual European Support" section.
#
# Drift classes:
#   1. extra_keys      — region keys in trends/research not in portfolio (HARD-FAIL)
#   2. trends_only / research_only — region-key parity mismatch (HARD-FAIL)
#   3. dach_sources    — cogni-trends DACH must reference all curated DACH authorities (HARD-FAIL)
#   4. authority_domain_drift — per-market authority-domain set drift between the canonical
#                                cogni-workspace/references/supported-markets-registry.json
#                                and each plugin's authority listing (INFORMATIONAL by default;
#                                escalates to violation only with --strict).
#
# Exits non-zero on Class 1–3 drift (or on Class 4 drift when --strict is set).
# Prints a single-line JSON envelope `{success, data, error}` on the final line
# so callers (CI, hooks, other scripts) can parse the verdict deterministically.
#
# When --baseline <path> is supplied, the script also computes per-market
# additions/removals vs the baseline file and attaches them under
# data.info_findings.deltas_vs_baseline. The baseline NEVER changes the exit
# code — it is informational. Enforcement of "no new drift" is the hook layer's
# job (cogni-workspace/scripts/check-region-catalogs-hook.sh).
#
# Usage:
#   bash cogni-workspace/scripts/check-region-catalogs.sh
#   bash cogni-workspace/scripts/check-region-catalogs.sh --fix-suggestions
#   bash cogni-workspace/scripts/check-region-catalogs.sh --strict
#   bash cogni-workspace/scripts/check-region-catalogs.sh --market dach
#   bash cogni-workspace/scripts/check-region-catalogs.sh --baseline scripts/baselines/region-catalog-drift-baseline.json

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PORTFOLIO="${REPO_ROOT}/cogni-portfolio/skills/portfolio-setup/references/regions.json"
TRENDS="${REPO_ROOT}/cogni-trends/skills/trend-report/references/region-authority-sources.json"
RESEARCH="${REPO_ROOT}/cogni-research/references/market-sources.json"
CURATED="${REPO_ROOT}/cogni-workspace/references/curated-region-sources.json"
REGISTRY="${REPO_ROOT}/cogni-workspace/references/supported-markets-registry.json"

# Flag defaults (passed into python as additional argv).
FIX_SUGGESTIONS="false"
STRICT="false"
MARKET_FILTER=""
BASELINE_PATH=""

# Bash 3.2 compatible flag parsing — manual loop, no getopts long-option extension.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --fix-suggestions)
      FIX_SUGGESTIONS="true"
      shift
      ;;
    --strict)
      STRICT="true"
      shift
      ;;
    --market)
      MARKET_FILTER="${2:-}"
      if [ -z "$MARKET_FILTER" ]; then
        echo "ERROR: --market requires a market code (e.g., --market dach)" >&2
        exit 2
      fi
      shift 2
      ;;
    --market=*)
      MARKET_FILTER="${1#--market=}"
      shift
      ;;
    --baseline)
      BASELINE_PATH="${2:-}"
      if [ -z "$BASELINE_PATH" ]; then
        echo "ERROR: --baseline requires a path (e.g., --baseline scripts/baselines/region-catalog-drift-baseline.json)" >&2
        exit 2
      fi
      shift 2
      ;;
    --baseline=*)
      BASELINE_PATH="${1#--baseline=}"
      shift
      ;;
    -h|--help)
      sed -n '2,38p' "$0"
      exit 0
      ;;
    *)
      echo "ERROR: unknown flag: $1" >&2
      echo "Usage: $0 [--fix-suggestions] [--strict] [--market <code>] [--baseline <path>]" >&2
      exit 2
      ;;
  esac
done

# Verify all catalog files exist before doing anything else.
for f in "$PORTFOLIO" "$TRENDS" "$RESEARCH" "$CURATED" "$REGISTRY"; do
  if [ ! -f "$f" ]; then
    rel="${f#"$REPO_ROOT/"}"
    echo "ERROR: catalog file not found: $rel" >&2
    printf '{"success":false,"data":{},"error":"missing catalog: %s"}\n' "$rel"
    exit 2
  fi
done

# Validate the baseline path only when supplied — empty string means "no baseline".
if [ -n "$BASELINE_PATH" ] && [ ! -f "$BASELINE_PATH" ]; then
  rel="${BASELINE_PATH#"$REPO_ROOT/"}"
  echo "ERROR: baseline file not found: $rel" >&2
  printf '{"success":false,"data":{},"error":"missing baseline: %s"}\n' "$rel"
  exit 2
fi

# All comparison logic lives in python so the set arithmetic and JSON parsing
# stay readable. The script body is just orchestration.
python3 - "$PORTFOLIO" "$TRENDS" "$RESEARCH" "$CURATED" "$REGISTRY" \
            "$FIX_SUGGESTIONS" "$STRICT" "$MARKET_FILTER" "$BASELINE_PATH" <<'PY'
import json
import re
import sys

(portfolio_path, trends_path, research_path, curated_path, registry_path,
 fix_suggestions_arg, strict_arg, market_filter, baseline_path) = sys.argv[1:10]

FIX_SUGGESTIONS = fix_suggestions_arg == "true"
STRICT = strict_arg == "true"
MARKET_FILTER = market_filter or None
BASELINE_PATH = baseline_path or None


def load(path):
    with open(path) as f:
        return json.load(f)


def real_keys(d):
    """Top-level keys that aren't metadata (anything starting with _)."""
    return {k for k in d.keys() if not k.startswith("_")}


def extract_site_domains(site_searches):
    """Pull domain strings out of cogni-trends site_searches[].query templates."""
    out = set()
    pat = re.compile(r"site:([^\s]+)")
    for entry in site_searches or []:
        m = pat.search(entry.get("query", ""))
        if m:
            out.add(m.group(1))
    return out


def trends_dimensions_for_domain(site_searches, domain):
    """Return the set of TIPS dimensions a domain appears under in trends queries."""
    dims = set()
    pat = re.compile(r"site:" + re.escape(domain) + r"(?:\s|$)")
    for entry in site_searches or []:
        if pat.search(entry.get("query", "")):
            dim = entry.get("dimension")
            if dim:
                dims.add(dim)
    return dims


# Bucket-A list keys diffed against the baseline. authority_disagreement is
# diffed by domain only — the prose hint string is intentionally excluded so
# wording tweaks don't churn the delta surface.
BUCKET_A_LIST_KEYS = (
    "domain_only_in_upstream",
    "domain_only_in_research",
    "domain_only_in_trends",
    "domain_in_research_and_trends_but_not_upstream",
)
BUCKET_B_LIST_KEYS = (
    "domain_only_in_research",
    "domain_only_in_trends",
)


def _disagreement_domains(per_market_entry):
    """Reduce authority_disagreement[] to a sortable list of domain strings."""
    return sorted({d.get("domain") for d in (per_market_entry.get("authority_disagreement") or [])
                   if d.get("domain")})


def _diff_market_lists(current_market, baseline_market, list_keys):
    """Per-market additions/removals for each list-typed finding key."""
    added = {}
    removed = {}
    cur = current_market or {}
    base = baseline_market or {}
    for key in list_keys:
        cur_set = set(cur.get(key) or [])
        base_set = set(base.get(key) or [])
        a = sorted(cur_set - base_set)
        r = sorted(base_set - cur_set)
        if a:
            added[key] = a
        if r:
            removed[key] = r
    return added, removed


def diff_baseline(current_a_per_market, current_b_per_market, baseline):
    """Compare current bucket A/B per-market findings against a baseline file.

    Returns {bucket_a, bucket_b, summary}. Markets with zero added and zero
    removed are omitted from the per-bucket dicts. Symmetric: a domain present
    in baseline but absent now appears under "removed".
    """
    base_a = ((baseline.get("bucket_a_findings") or {}).get("per_market")) or {}
    base_b = ((baseline.get("bucket_b_findings") or {}).get("per_market")) or {}

    bucket_a_deltas = {}
    bucket_b_deltas = {}
    total_added = 0
    total_removed = 0

    for code in sorted(set(current_a_per_market) | set(base_a)):
        added, removed = _diff_market_lists(
            current_a_per_market.get(code), base_a.get(code), BUCKET_A_LIST_KEYS)
        # authority_disagreement diffed by domain only.
        cur_dis = set(_disagreement_domains(current_a_per_market.get(code) or {}))
        base_dis = set(_disagreement_domains(base_a.get(code) or {}))
        ad = sorted(cur_dis - base_dis)
        rd = sorted(base_dis - cur_dis)
        if ad:
            added["authority_disagreement"] = ad
        if rd:
            removed["authority_disagreement"] = rd
        if added or removed:
            bucket_a_deltas[code] = {"added": added, "removed": removed}
            total_added += sum(len(v) for v in added.values())
            total_removed += sum(len(v) for v in removed.values())

    for code in sorted(set(current_b_per_market) | set(base_b)):
        added, removed = _diff_market_lists(
            current_b_per_market.get(code), base_b.get(code), BUCKET_B_LIST_KEYS)
        if added or removed:
            bucket_b_deltas[code] = {"added": added, "removed": removed}
            total_added += sum(len(v) for v in added.values())
            total_removed += sum(len(v) for v in removed.values())

    return {
        "bucket_a": bucket_a_deltas,
        "bucket_b": bucket_b_deltas,
        "summary": {
            "markets_with_added_drift": sum(
                1 for v in list(bucket_a_deltas.values()) + list(bucket_b_deltas.values())
                if v["added"]),
            "markets_with_removed_drift": sum(
                1 for v in list(bucket_a_deltas.values()) + list(bucket_b_deltas.values())
                if v["removed"]),
            "total_domains_added": total_added,
            "total_domains_removed": total_removed,
        },
    }


portfolio_raw = load(portfolio_path)
trends = load(trends_path)
research = load(research_path)
registry = load(registry_path).get("markets", {})

# CLAUDE.md DACH authority sources — loaded from curated-region-sources.json
# (single source of truth synced with CLAUDE.md 'Multilingual European Support').
EXPECTED_DACH_SOURCES = set(load(curated_path)["dach"])

# cogni-portfolio nests regions under a "regions" key; the other two don't.
portfolio_regions = portfolio_raw.get("regions", portfolio_raw)
portfolio_keys = real_keys(portfolio_regions)
trends_keys = real_keys(trends)
research_keys = real_keys(research)

violations = []

# ---------------------------------------------------------------------------
# Drift class 1: regions in trends or research that aren't in portfolio.
# Portfolio is the union-of-markets source of truth (per the issue #46
# Stage 1 option (b) recommendation), so the other two catalogs should be
# subsets of portfolio.
for plugin, keys in (("cogni-trends", trends_keys), ("cogni-research", research_keys)):
    extra = sorted(keys - portfolio_keys)
    if extra:
        violations.append({
            "class": "extra_keys",
            "plugin": plugin,
            "detail": extra,
            "hint": f"{plugin} has region keys not in cogni-portfolio: {extra}. "
                    "Either add them to cogni-portfolio/skills/portfolio-setup/"
                    "references/regions.json or remove from this plugin.",
        })

# Drift class 2: regions in trends and research must agree on their intersection
# with portfolio. Any key that's in one and not the other is drift.
trends_minus_research = sorted(trends_keys - research_keys)
research_minus_trends = sorted(research_keys - trends_keys)
if trends_minus_research:
    violations.append({
        "class": "trends_only",
        "detail": trends_minus_research,
        "hint": f"cogni-trends has region keys missing from cogni-research: "
                f"{trends_minus_research}. Add stub entries to cogni-research/"
                "references/market-sources.json so the two web-search catalogs "
                "stay in sync.",
    })
if research_minus_trends:
    violations.append({
        "class": "research_only",
        "detail": research_minus_trends,
        "hint": f"cogni-research has region keys missing from cogni-trends: "
                f"{research_minus_trends}. Add stub entries to cogni-trends/"
                "skills/trend-report/references/region-authority-sources.json "
                "so the two web-search catalogs stay in sync.",
    })

# Drift class 3: cogni-trends DACH must reference all CLAUDE.md-curated sources.
dach_entry = trends.get("dach", {})
dach_text_blob = json.dumps(dach_entry)
missing_dach = sorted(s for s in EXPECTED_DACH_SOURCES if s not in dach_text_blob)
if missing_dach:
    violations.append({
        "class": "dach_sources",
        "detail": missing_dach,
        "hint": f"cogni-trends DACH entry is missing CLAUDE.md-curated authority "
                f"sources: {missing_dach}. Add them as site_searches under the "
                "appropriate dimension in cogni-trends/skills/trend-report/"
                "references/region-authority-sources.json.",
    })

# ---------------------------------------------------------------------------
# Drift class 4: per-market authority-domain set drift, audited against the
# canonical cogni-workspace/references/supported-markets-registry.json.
# Three-bucket market triage:
#   A. Curated upstream  — registry has authority_sources[] AND market in r+t
#   B. Downstream-only   — market in r+t but registry authority_sources[] empty
#   C. Registry-only     — registry has market but it's absent from r+t
# Bucket A: three-way diff. Bucket B: peer diff + registry_unpopulated advisory.
# Bucket C: skip (composites/aggregates that no per-plugin file uses).
all_market_codes = sorted(set(registry) | research_keys | trends_keys)
if MARKET_FILTER:
    all_market_codes = [c for c in all_market_codes if c == MARKET_FILTER]

bucket_a = {}  # code -> findings dict
bucket_b = {}  # code -> findings dict
bucket_c_skipped = []
fix_suggestions = {}

for code in all_market_codes:
    in_research = code in research_keys
    in_trends = code in trends_keys
    in_registry = code in registry
    upstream_entries = registry.get(code, {}).get("authority_sources", []) if in_registry else []
    upstream_doms = {a["domain"] for a in upstream_entries if a.get("domain")}

    if in_registry and not in_research and not in_trends:
        bucket_c_skipped.append(code)
        continue

    research_entries = research.get(code, {}).get("authority_sources", []) if in_research else []
    research_doms = {a["domain"] for a in research_entries if a.get("domain")}
    research_meta = {a["domain"]: a for a in research_entries if a.get("domain")}
    trends_searches = trends.get(code, {}).get("site_searches", []) if in_trends else []
    trends_doms = extract_site_domains(trends_searches)

    if in_registry and upstream_doms:
        # Bucket A: three-way diff.
        findings = {
            "domain_only_in_upstream": sorted(upstream_doms - research_doms - trends_doms),
            "domain_only_in_research": sorted(research_doms - upstream_doms - trends_doms),
            "domain_only_in_trends":   sorted(trends_doms - upstream_doms - research_doms),
            "domain_in_research_and_trends_but_not_upstream":
                sorted((research_doms & trends_doms) - upstream_doms),
            "authority_disagreement": [],
        }
        # Best-effort authority disagreement heuristic — only domains in BOTH
        # downstream files where research categorises as a "regulatory tier"
        # (research/government/statistics) but trends only references the
        # domain under digitales-fundament (consulting tier), or vice versa.
        for dom in sorted(research_doms & trends_doms):
            r_cat = (research_meta.get(dom) or {}).get("category")
            t_dims = trends_dimensions_for_domain(trends_searches, dom)
            if r_cat in {"research", "government", "statistics"} and t_dims == {"digitales-fundament"}:
                findings["authority_disagreement"].append({
                    "domain": dom,
                    "research_category": r_cat,
                    "trends_dimensions": sorted(t_dims),
                    "hint": "research treats as regulatory-tier; trends uses only digitales-fundament (consulting-tier)",
                })
            elif r_cat in {"consulting", "media"} and t_dims and "digitales-fundament" not in t_dims:
                findings["authority_disagreement"].append({
                    "domain": dom,
                    "research_category": r_cat,
                    "trends_dimensions": sorted(t_dims),
                    "hint": "research treats as consulting/media; trends uses only regulatory dimensions",
                })
        if any(findings.values()):
            bucket_a[code] = findings
        if FIX_SUGGESTIONS:
            promote = (research_doms & trends_doms) - upstream_doms
            additions = []
            if promote:
                additions.append({"registry_additions": [
                    {"name": dom.split(".")[0].upper(), "domain": dom} for dom in sorted(promote)
                ]})
            r_extra = sorted(upstream_doms - research_doms)
            t_extra = sorted(upstream_doms - trends_doms)
            if r_extra:
                additions.append({"research_additions": [
                    {"domain": dom, "category": "unknown", "authority": 3,
                     "search_pattern": f"site:{dom} {{TOPIC_LOCAL}} {{YEAR}}"}
                    for dom in r_extra
                ]})
            if t_extra:
                additions.append({"trends_additions": [
                    {"dimension": "digitales-fundament",
                     "query": f"site:{dom} {{SUBSECTOR_LOCAL}} {{CURRENT_YEAR}}"}
                    for dom in t_extra
                ]})
            if additions:
                fix_suggestions[code] = additions

    elif in_research and in_trends:
        # Bucket B: peer diff + registry_unpopulated advisory.
        findings = {
            "registry_unpopulated": (
                f"{code}: registry has no authority_sources[]; downstream files are "
                "de-facto source of truth for this market — consider backfilling the "
                "registry from the intersection of research_domains and trends_domains."
            ),
            "domain_only_in_research": sorted(research_doms - trends_doms),
            "domain_only_in_trends":   sorted(trends_doms - research_doms),
        }
        bucket_b[code] = findings
        if FIX_SUGGESTIONS:
            backfill = research_doms & trends_doms
            if backfill:
                fix_suggestions[code] = [{"registry_additions": [
                    {"name": dom.split(".")[0].upper(), "domain": dom} for dom in sorted(backfill)
                ]}]
    # If in registry-only with empty authority_sources, fall through silently;
    # caught by bucket_c_skipped above only when also absent from r+t.

bucket_a_summary = {
    "markets_with_drift": len(bucket_a),
    "markets_examined": sum(1 for c in all_market_codes
                             if c in registry and registry[c].get("authority_sources")
                             and c in research_keys and c in trends_keys),
}
bucket_b_summary = {
    "markets_with_drift": len(bucket_b),
    "markets_examined": sum(1 for c in all_market_codes
                             if c in research_keys and c in trends_keys
                             and (c not in registry or not registry[c].get("authority_sources"))),
}

info_findings = {
    "bucket_a_findings": {"per_market": bucket_a, "summary": bucket_a_summary},
    "bucket_b_findings": {"per_market": bucket_b, "summary": bucket_b_summary},
    "bucket_c_skipped":  bucket_c_skipped,
    "summary": {
        "registry_markets_total": len(registry),
        "registry_markets_with_authority_sources": sum(
            1 for v in registry.values() if v.get("authority_sources")),
        "bucket_a_markets_with_drift": len(bucket_a),
        "bucket_b_markets_with_drift": len(bucket_b),
        "bucket_c_markets_skipped": len(bucket_c_skipped),
    },
}
if FIX_SUGGESTIONS:
    info_findings["fix_suggestions"] = fix_suggestions

if BASELINE_PATH:
    baseline_data = load(BASELINE_PATH)
    info_findings["deltas_vs_baseline"] = diff_baseline(bucket_a, bucket_b, baseline_data)

if STRICT and (bucket_a or bucket_b):
    violations.append({
        "class": "authority_domain_drift",
        "detail": {
            "bucket_a_markets": sorted(bucket_a),
            "bucket_b_markets": sorted(bucket_b),
        },
        "hint": "Per-market authority-domain drift detected (--strict). "
                "Inspect data.info_findings.bucket_a_findings / bucket_b_findings "
                "and reconcile each plugin's authority listing with the canonical "
                "cogni-workspace/references/supported-markets-registry.json.",
    })

# ---------------------------------------------------------------------------
# Print human-readable summary first.
print(f"cogni-portfolio: {len(portfolio_keys)} region keys")
print(f"cogni-trends:    {len(trends_keys)} region keys")
print(f"cogni-research:  {len(research_keys)} region keys")
print(f"registry:        {len(registry)} markets "
      f"({info_findings['summary']['registry_markets_with_authority_sources']} with authority_sources)")
print()
print(f"Class 4 (informational): "
      f"bucket A drift {bucket_a_summary['markets_with_drift']}/{bucket_a_summary['markets_examined']}, "
      f"bucket B drift {bucket_b_summary['markets_with_drift']}/{bucket_b_summary['markets_examined']}, "
      f"bucket C skipped {len(bucket_c_skipped)}")
if BASELINE_PATH:
    delta_summary = info_findings["deltas_vs_baseline"]["summary"]
    n_added = delta_summary["total_domains_added"]
    n_removed = delta_summary["total_domains_removed"]
    n_markets = len(info_findings["deltas_vs_baseline"]["bucket_a"]) + \
                len(info_findings["deltas_vs_baseline"]["bucket_b"])
    if n_added == 0 and n_removed == 0:
        print("Deltas vs baseline: 0")
    else:
        print(f"Deltas vs baseline: +{n_added} / -{n_removed} across {n_markets} market(s).")
print()

data = {
    "portfolio_keys": sorted(portfolio_keys),
    "trends_keys": sorted(trends_keys),
    "research_keys": sorted(research_keys),
    "violations": violations,
    "info_findings": info_findings,
}

if not violations:
    print("OK: all region catalogs agree and cogni-trends DACH references all "
          "CLAUDE.md-curated sources.")
    if bucket_a or bucket_b:
        print("(Class 4 informational findings present — see data.info_findings.)")
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)

print(f"FAIL: {len(violations)} drift class(es) detected.")
print()
for v in violations:
    print(f"  [{v['class']}]")
    print(f"    {v['hint']}")
    print()

print(json.dumps({"success": False, "data": data,
                  "error": f"{len(violations)} drift class(es) detected"}))
sys.exit(1)
PY
