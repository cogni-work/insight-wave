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
  - trends:    overlays cogni-trends/skills/trend-research/references/region-authority-sources.json
  - portfolio: no overlay — returns registry data as-is

Output: JSON envelope on stdout — {"success": bool, "data": {...}, "error": str|null}
"""
import argparse
import json
import os
import sys
from collections import namedtuple
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PLUGIN_ROOT = SCRIPT_DIR.parent
REGISTRY_PATH = PLUGIN_ROOT / "references" / "supported-markets-registry.json"

_SiblingPlugin = namedtuple("_SiblingPlugin", ("dir_name", "env_var", "overlay_relpath"))

_SIBLINGS = {
    "portfolio": _SiblingPlugin("cogni-portfolio", "PORTFOLIO_PLUGIN_ROOT", None),
    "research":  _SiblingPlugin("cogni-research",  "RESEARCH_PLUGIN_ROOT",
                                Path("references/market-sources.json")),
    "trends":    _SiblingPlugin("cogni-trends",    "TRENDS_PLUGIN_ROOT",
                                Path("skills/trend-research/references/region-authority-sources.json")),
}
SUPPORTED_PLUGINS = tuple(sorted(_SIBLINGS.keys()))


def _resolve_sibling_plugin(meta):
    """Return sibling plugin root, or None if unresolvable.

    Three-layer fallback, mirrors cogni-research/scripts/market-summary.py:
      1. {NAME}_PLUGIN_ROOT env var (e.g. RESEARCH_PLUGIN_ROOT)
      2. Latest version dir under ~/.claude/plugins/cache/insight-wave/<name>/
      3. Monorepo sibling: PLUGIN_ROOT.parent / <name>
    A candidate wins only if the overlay file exists under it — that way
    half-installed or empty dirs don't win. Caller is responsible for
    ensuring meta.overlay_relpath is non-None (see _overlay_path).
    """
    sentinel = meta.overlay_relpath

    explicit = os.environ.get(meta.env_var)
    if explicit:
        cand = Path(explicit)
        if (cand / sentinel).exists():
            return cand

    cache = Path.home() / ".claude/plugins/cache/insight-wave" / meta.dir_name
    try:
        for cand in sorted(cache.iterdir(), reverse=True):
            if cand.is_dir() and (cand / sentinel).exists():
                return cand
    except FileNotFoundError:
        pass

    monorepo = PLUGIN_ROOT.parent / meta.dir_name
    if (monorepo / sentinel).exists():
        return monorepo

    return None


def _overlay_path(plugin):
    meta = _SIBLINGS.get(plugin)
    if meta is None or meta.overlay_relpath is None:
        return None
    root = _resolve_sibling_plugin(meta)
    if root is None:
        return None
    return root / meta.overlay_relpath

# Registry's `regional_qualifiers` (narrative format, e.g. "in DACH region")
# is intentionally distinct from plugins' `region_qualifiers` (search-query
# format, e.g. "Germany Austria Switzerland"). They share a similar name for
# historical reasons but carry different content. The merge utility does NOT
# rename or substitute — read sites that want search-query qualifiers must
# get them from the overlay.


def _load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _envelope(success, data, error=None):
    return {"success": success, "data": data, "error": error}


def _registry_market(registry, code):
    """Return a registry market entry as-is (no field renaming)."""
    markets = registry.get("markets") or {}
    raw = markets.get(code)
    if not raw:
        return None
    return dict(raw)


_OMIT = object()  # sentinel: caller should omit the key entirely


def _join_authorities(registry_entry, overlay_entry):
    """Compute merge output for authority_sources.

    Three cases:
      1. Overlay has authority_sources[] (pre-migration shape) — return it
         unchanged. Overlay wins.
      2. Overlay has authority_metadata{} (post-migration slim shape) —
         join with registry's authority_sources[] by domain. Output one
         entry per curated domain (metadata-bearing); domains in the
         registry without overlay metadata are omitted (overlay is the
         "curated by this plugin" filter).
      3. Overlay has neither — the plugin doesn't curate authorities at
         all. Return _OMIT so the caller drops authority_sources from the
         merged output entirely. This preserves today's behavior where
         e.g. cogni-trends and cogni-portfolio overlays don't expose an
         authority_sources field.
    """
    overlay_sources = (overlay_entry or {}).get("authority_sources")
    if overlay_sources is not None:
        return overlay_sources

    metadata = (overlay_entry or {}).get("authority_metadata")
    if metadata is None:
        return _OMIT

    registry_sources = (registry_entry or {}).get("authority_sources") or []
    by_domain = {entry.get("domain"): entry for entry in registry_sources if entry.get("domain")}

    joined = []
    for domain, plugin_meta in metadata.items():
        base = dict(by_domain.get(domain, {"domain": domain}))
        base.update(plugin_meta)
        if "domain" not in base:
            base["domain"] = domain
        joined.append(base)
    return joined


def _merge_market(registry_entry, overlay_entry):
    """Merge registry base + overlay. Overlay wins on field conflicts.

    authority_sources is special-cased via _join_authorities to handle the
    three plugin shapes (legacy passthrough, post-migration join, opt-out).
    """
    if registry_entry is None and overlay_entry is None:
        return None
    if registry_entry is None:
        return dict(overlay_entry)
    if overlay_entry is None:
        merged = dict(registry_entry)
    else:
        merged = dict(registry_entry)
        for key, value in overlay_entry.items():
            if key in ("authority_metadata", "authority_sources"):
                continue
            merged[key] = value

    joined = _join_authorities(registry_entry, overlay_entry)
    if joined is _OMIT:
        merged.pop("authority_sources", None)
    else:
        merged["authority_sources"] = joined
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
    parser.add_argument("--plugin", required=True, choices=list(SUPPORTED_PLUGINS),
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
    overlay_path = _overlay_path(args.plugin)
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
