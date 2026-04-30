#!/usr/bin/env python3
"""sync-markets-to-plugins.py — propagate canonical registry → per-plugin scaffolding.

Reads the canonical registry at
`cogni-workspace/references/supported-markets-registry.json` and adds market
keys missing from the two per-plugin orchestration files
(`cogni-research/references/market-sources.json`,
`cogni-trends/skills/trend-report/references/region-authority-sources.json`).

Safety contract — what this script will and will NOT do:
  - WILL add a NEW market entry with explicit placeholder orchestration metadata.
  - WILL copy registry's `regional_qualifiers` into research/trends'
    `region_qualifiers` (note the field-name difference between registry and
    plugins — load-bearing).
  - WILL stub one entry per registry domain in research's `authority_sources[]`
    (`category="unknown"`, `authority=3`, generic search_pattern) and one entry
    per registry domain in trends' `site_searches[]`
    (`dimension="digitales-fundament"`, generic query template). Maintainers
    must refine these placeholders.
  - WILL NOT overwrite any existing market entry — uses `dict.setdefault`
    semantics. Existing values are byte-identical post-sync.
  - WILL NOT edit `category`, `authority`, `search_pattern` of existing
    domains; will not reshape `dimension` or query templates outside the
    placeholder stubs.

Modes:
  default   — print unified diff of pending changes; never writes.
  --write   — apply changes to the per-plugin files.

Output: single-line JSON envelope `{success, data, error}` on the final line.
"""
import argparse
import difflib
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
REGISTRY = REPO_ROOT / "cogni-workspace/references/supported-markets-registry.json"
RESEARCH = REPO_ROOT / "cogni-research/references/market-sources.json"
TRENDS = REPO_ROOT / "cogni-trends/skills/trend-report/references/region-authority-sources.json"


def load_json(path):
    with open(path) as f:
        return json.load(f)


def dump_json(obj, path):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)
        f.write("\n")


def real_keys(d):
    """Top-level keys that aren't metadata (anything starting with _)."""
    return {k for k in d.keys() if not k.startswith("_")}


def derive_name(domain):
    """Best-effort fallback display name for a domain in registry/plugin stubs."""
    return domain.split(".")[0].upper()


def build_research_entry(market_code, registry_market):
    """Build a research-side stub entry for a market that exists in the registry only.

    Maps registry's `regional_qualifiers` to research's `region_qualifiers`
    (field-name difference is load-bearing). Authority entries are stubs that
    a maintainer must refine — `category="unknown"`, `authority=3`.
    """
    registry_domains = [
        a.get("domain") for a in (registry_market.get("authority_sources") or [])
        if a.get("domain")
    ]
    return {
        "default_output_language": registry_market.get("default_output_language", "en"),
        "local_language": registry_market.get("default_output_language", "en"),
        "region_qualifiers": dict(registry_market.get("regional_qualifiers") or {}),
        "local_query_tips": {
            "compound_nouns": [],
            "keep_english": [],
            "geographic_modifiers": [],
        },
        "authority_sources": [
            {
                "domain": dom,
                "category": "unknown",
                "authority": 3,
                "search_pattern": f"site:{dom} {{TOPIC_LOCAL}} {{YEAR}}",
            }
            for dom in registry_domains
        ],
        "regulatory_bodies": [],
        "currency": registry_market.get("currency", ""),
    }


def build_trends_entry(market_code, registry_market):
    """Build a trends-side stub entry for a market missing from trends.

    Maps `regional_qualifiers` → `region_qualifiers`. Each registry domain
    becomes one site_searches[] entry under `digitales-fundament` — a
    placeholder dimension the maintainer must refine.
    """
    registry_domains = [
        a.get("domain") for a in (registry_market.get("authority_sources") or [])
        if a.get("domain")
    ]
    return {
        "region_qualifiers": dict(registry_market.get("regional_qualifiers") or {}),
        "local_language": registry_market.get("default_output_language", "en"),
        "site_searches": [
            {
                "dimension": "digitales-fundament",
                "query": f"site:{dom} {{SUBSECTOR_LOCAL}} {{CURRENT_YEAR}}",
            }
            for dom in registry_domains
        ],
        "regulatory_bodies": [],
        "regulatory_search": "\"{SUBSECTOR_EN}\" regulation compliance {CURRENT_YEAR}",
        "currency": registry_market.get("currency", ""),
        "org_size_reference": "mid-size organization",
    }


def setdefault_market_entries(plugin_data, registry, builder):
    """Add missing market entries to plugin_data using `setdefault` semantics.

    Returns the list of market codes that were added.
    """
    added = []
    plugin_keys = real_keys(plugin_data)
    for code in sorted(real_keys(registry)):
        if code in plugin_keys:
            continue  # never overwrite
        plugin_data[code] = builder(code, registry[code])
        added.append(code)
    # Re-sort by writing the dict in alphabetical order while preserving _-prefixed keys at the top.
    return added, dict_in_canonical_order(plugin_data)


def dict_in_canonical_order(d):
    """Stable order: leading `_metadata` keys first (preserved), then alpha."""
    meta = {k: v for k, v in d.items() if k.startswith("_")}
    real = {k: v for k, v in d.items() if not k.startswith("_")}
    out = dict(meta)
    for k in sorted(real):
        out[k] = real[k]
    return out


def render_diff(old_text, new_text, path):
    return "\n".join(difflib.unified_diff(
        old_text.splitlines(),
        new_text.splitlines(),
        fromfile=str(path),
        tofile=str(path),
        lineterm="",
    ))


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("--write", action="store_true",
                        help="apply changes (default: preview only)")
    parser.add_argument("--quiet", action="store_true",
                        help="suppress diff body in stdout (still emits JSON envelope)")
    args = parser.parse_args()

    try:
        registry_doc = load_json(REGISTRY)
        registry = registry_doc.get("markets") or {}
        research = load_json(RESEARCH)
        trends = load_json(TRENDS)
    except Exception as e:
        print(json.dumps({"success": False, "data": {}, "error": f"load failed: {e}"}))
        return 2

    # Compute pending additions BEFORE mutating anything.
    research_missing = sorted(real_keys(registry) - real_keys(research))
    trends_missing = sorted(real_keys(registry) - real_keys(trends))

    if not research_missing and not trends_missing:
        envelope = {
            "success": True,
            "data": {
                "research_added": [],
                "trends_added": [],
                "summary": "no missing markets — research and trends already cover the registry",
            },
            "error": "",
        }
        print(envelope["data"]["summary"])
        print(json.dumps(envelope))
        return 0

    research_old_text = json.dumps(research, indent=2, ensure_ascii=False) + "\n"
    trends_old_text = json.dumps(trends, indent=2, ensure_ascii=False) + "\n"

    research_added, research_new = setdefault_market_entries(research, registry, build_research_entry)
    trends_added, trends_new = setdefault_market_entries(trends, registry, build_trends_entry)

    research_new_text = json.dumps(research_new, indent=2, ensure_ascii=False) + "\n"
    trends_new_text = json.dumps(trends_new, indent=2, ensure_ascii=False) + "\n"

    if not args.quiet:
        if research_added:
            print(render_diff(research_old_text, research_new_text, RESEARCH.relative_to(REPO_ROOT)))
            print()
        if trends_added:
            print(render_diff(trends_old_text, trends_new_text, TRENDS.relative_to(REPO_ROOT)))
            print()

    if args.write:
        if research_added:
            dump_json(research_new, RESEARCH)
        if trends_added:
            dump_json(trends_new, TRENDS)
        action = "applied"
    else:
        action = "preview only — use --write to apply"

    envelope = {
        "success": True,
        "data": {
            "research_added": research_added,
            "trends_added": trends_added,
            "field_name_mapping": {
                "registry": "regional_qualifiers",
                "research_and_trends": "region_qualifiers",
            },
            "summary": (
                f"{action}: research +{len(research_added)} market(s), "
                f"trends +{len(trends_added)} market(s)"
            ),
        },
        "error": "",
    }
    print(envelope["data"]["summary"])
    print(json.dumps(envelope))
    return 0


if __name__ == "__main__":
    sys.exit(main())
