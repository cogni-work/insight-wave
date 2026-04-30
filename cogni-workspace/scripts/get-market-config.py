#!/usr/bin/env python3
"""get-market-config.py — single read entry point for plugin market configs.

Joins the canonical market registry (`cogni-workspace/references/supported-markets-registry.json`)
with a plugin-specific overlay and returns the merged config for one market — or
all markets — in the shape each plugin expects today.

Layered-read model: shared market fields (codes, names, currencies, locales,
languages, regional qualifiers, canonical authority domain set, regulatory
bodies) live in the registry only. Each plugin's overlay carries only its
plugin-specific fields (research: per-domain authority metadata + vocabulary
hints; trends: dimension-keyed site_searches + query templates).

Backwards compatible during migration: if the overlay still carries shared
fields (the pre-migration file shape), overlay values win on conflicts —
output is byte-identical to a direct read of the pre-migration file. Once
the overlay is slimmed, the same read site keeps working because the
merge utility fills shared fields from the registry.

Usage:
  get-market-config.py --plugin <name> --market <code>
  get-market-config.py --plugin <name> --all-markets

Plugins: research | trends | portfolio
  - research:  overlays cogni-research/references/market-sources.json
  - trends:    overlays cogni-trends/skills/trend-report/references/region-authority-sources.json
  - portfolio: no overlay — returns registry data as-is

Output: JSON envelope on stdout — {"success": bool, "data": {...}, "error": str|null}
"""
import argparse
import json
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
REGISTRY_PATH = REPO_ROOT / "cogni-workspace/references/supported-markets-registry.json"

OVERLAY_PATHS = {
    "research": REPO_ROOT / "cogni-research/references/market-sources.json",
    "trends":   REPO_ROOT / "cogni-trends/skills/trend-report/references/region-authority-sources.json",
    "portfolio": None,
}

# Registry uses `regional_qualifiers`; plugins read `region_qualifiers`. The
# merge output uses the plugin-side name so existing read sites keep working.
QUALIFIERS_REGISTRY_KEY = "regional_qualifiers"
QUALIFIERS_PLUGIN_KEY = "region_qualifiers"

# Keys treated as overlay metadata only — never expected in registry.
OVERLAY_ONLY_KEYS_RESEARCH = {
    "local_query_tips", "vocabulary_hints", "authority_metadata",
    "default_output_language", "local_language",
}
OVERLAY_ONLY_KEYS_TRENDS = {
    "site_searches", "regulatory_search", "org_size_reference", "local_language",
}


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _envelope(success, data, error=None):
    return {"success": success, "data": data, "error": error}


def _registry_market(registry, code):
    """Return a registry market entry remapped to plugin field names."""
    markets = registry.get("markets") or {}
    raw = markets.get(code)
    if not raw:
        return None
    out = dict(raw)
    if QUALIFIERS_REGISTRY_KEY in out:
        out[QUALIFIERS_PLUGIN_KEY] = out.pop(QUALIFIERS_REGISTRY_KEY)
    return out


def _merge_market(registry_entry, overlay_entry):
    """Merge registry base + overlay. Overlay wins on field conflicts."""
    if registry_entry is None and overlay_entry is None:
        return None
    if registry_entry is None:
        return dict(overlay_entry)
    if overlay_entry is None:
        return dict(registry_entry)
    merged = dict(registry_entry)
    for key, value in overlay_entry.items():
        merged[key] = value
    return merged


def _is_meta_key(key):
    return key.startswith("_")


def _overlay_market_keys(overlay):
    return [k for k in overlay.keys() if not _is_meta_key(k)]


def _registry_market_keys(registry):
    return list((registry.get("markets") or {}).keys())


def get_market(plugin, code, registry, overlay):
    base = _registry_market(registry, code)
    over = (overlay or {}).get(code) if overlay else None
    if base is None and over is None:
        # Fall back to overlay's _default if present (legacy behaviour for
        # cogni-research's _default sentinel).
        fallback = (overlay or {}).get("_default") if overlay else None
        if fallback is None:
            return None
        return dict(fallback)
    return _merge_market(base, over)


def get_all_markets(plugin, registry, overlay):
    keys = set(_registry_market_keys(registry))
    if overlay:
        keys.update(_overlay_market_keys(overlay))
    return {code: get_market(plugin, code, registry, overlay) for code in sorted(keys)}


def main():
    parser = argparse.ArgumentParser(description="Merge canonical market registry with a plugin overlay.")
    parser.add_argument("--plugin", required=True, choices=sorted(OVERLAY_PATHS.keys()),
                        help="Plugin whose overlay to apply.")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--market", help="Market code (e.g. dach, fr).")
    group.add_argument("--all-markets", action="store_true",
                       help="Return merged config for every market.")
    args = parser.parse_args()

    try:
        registry = _load(REGISTRY_PATH)
    except Exception as exc:
        print(json.dumps(_envelope(False, None, f"failed to load registry: {exc}"),
                         ensure_ascii=False))
        sys.exit(1)

    overlay = None
    overlay_path = OVERLAY_PATHS[args.plugin]
    if overlay_path is not None:
        try:
            overlay = _load(overlay_path)
        except FileNotFoundError:
            overlay = None
        except Exception as exc:
            print(json.dumps(_envelope(False, None,
                                       f"failed to load {args.plugin} overlay: {exc}"),
                             ensure_ascii=False))
            sys.exit(1)

    if args.all_markets:
        data = get_all_markets(args.plugin, registry, overlay)
        print(json.dumps(_envelope(True, data, None), ensure_ascii=False))
        return

    data = get_market(args.plugin, args.market, registry, overlay)
    if data is None:
        print(json.dumps(_envelope(False, None,
                                   f"unknown market '{args.market}' for plugin '{args.plugin}'"),
                         ensure_ascii=False))
        sys.exit(1)
    print(json.dumps(_envelope(True, data, None), ensure_ascii=False))


if __name__ == "__main__":
    main()
