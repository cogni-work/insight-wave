#!/usr/bin/env python3
"""check-market-orphans.py — compute the market registry's one real drift signal.

The canonical market taxonomy lives in
`cogni-workspace/references/supported-markets-registry.json`; each consuming
plugin layers only its own operational metadata on top through an overlay.
Because the overlays carry no copy of the shared fields, drift on the shared
market set is structurally impossible — there is nothing to fall out of sync.

The single soft check that remains is the ORPHAN: an overlay carrying metadata
keyed against a domain the canonical registry does not hold for that market.
An orphan means either the registry is missing a domain (add it) or the overlay
entry is stale (delete it). It was described in prose for a long time and
computed nowhere, so nothing ever proved it could fire. This script is that
computation, and `tests/test-check-market-orphans.sh` is the proof.

Two overlay shapes carry domains, and each needs its own reader:
  - research: `authority_metadata{}` is keyed BY domain, so the keys are the
    claim set directly.
  - trends:   `site_searches[]` carries domains inside a query string as a
    `site:DOMAIN` token, so the domain has to be lifted out of the query.

A market present in an overlay but absent from the registry has an empty
canonical domain set, so every domain it curates reads as an orphan. That is
the honest verdict rather than a special case: the registry is the taxonomy, so
an overlay market it does not carry is entirely uncanonical.

Overlay resolution is NOT reimplemented here. `get-market-config.py` owns the
`_SIBLINGS` mapping and the three-layer sibling cascade (env var, plugin cache,
monorepo sibling); this script imports that module and calls it, so the two read
sites can never disagree about where an overlay lives. A plugin whose overlay
does not resolve — the ordinary state for an out-of-monorepo install of a
dormant plugin — is reported as uncurated rather than treated as an error.

Usage:
  check-market-orphans.py                              # all plugins, live tree
  check-market-orphans.py --plugin research            # one plugin
  check-market-orphans.py --registry PATH \\
      --overlay research=PATH --overlay trends=PATH    # explicit, for fixtures

Two absences are reported differently, and the difference is the point. A
sibling plugin that is not installed is legitimate degradation: its overlay is
reported uncurated, success stays true, exit 0. `get-market-config.py` itself
failing to import is a failure of the subject — nothing read an overlay, so
"0 orphans" would be a clean audit over nothing — and exits 1 with an error.
The import is lazy, so a run naming every overlay explicitly never needs the
cascade and is unaffected by either.

Output: JSON envelope on stdout — {"success": bool, "data": {...}, "error": str|null}
Stdlib only: no pip dependency, no network.
"""
import argparse
import importlib.util
import json
import re
import sys
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PLUGIN_ROOT = SCRIPT_DIR.parent
REGISTRY_PATH = PLUGIN_ROOT / "references" / "supported-markets-registry.json"
MERGE_UTILITY = SCRIPT_DIR / "get-market-config.py"

# Plugins that carry a domain-bearing overlay, and the overlay field each one
# keys its domains through. `portfolio` is deliberately absent: it reads the
# registry directly and curates no overlay, so it has no way to orphan.
OVERLAY_READERS = ("research", "trends")

# `site:` token inside a trends query. The domain runs to the first whitespace;
# a trailing dot or comma is punctuation, not part of the domain.
_SITE_TOKEN = re.compile(r"\bsite:([A-Za-z0-9._-]+)")


def _envelope(success, data, error=None):
    return {"success": success, "data": data, "error": error}


def _load(path):
    with open(path, encoding="utf-8") as fh:
        return json.load(fh)


def _load_merge_utility():
    """Import get-market-config.py so overlay resolution has ONE owner.

    Returns `(module, error)` — exactly one of the two is set. The filename is
    not an importable module name (hyphens), so it is loaded by path rather
    than by `import`.

    The error is returned rather than swallowed because of what this import
    IS. A sibling plugin that is not installed is legitimate degradation, and
    the caller reports it as an uncurated overlay. Our own merge utility
    failing to load is not degradation — it is a failure of the subject, and
    reporting it as "no overlay resolved" would render a clean audit over a
    registry nothing actually read. The caller decides which of the two it is
    holding, because only the caller knows whether the cascade was needed at
    all; the fixture path supplies every overlay explicitly and never is.
    """
    try:
        spec = importlib.util.spec_from_file_location("_get_market_config", MERGE_UTILITY)
        if spec is None or spec.loader is None:
            return None, f"no import spec for {MERGE_UTILITY}"
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module, None
    except Exception as exc:
        return None, f"{type(exc).__name__}: {exc}"


def _is_meta_key(key):
    return key.startswith("_")


def registry_domains(registry, code):
    """Canonical domain set the registry holds for one market."""
    market = (registry.get("markets") or {}).get(code) or {}
    return {
        entry.get("domain")
        for entry in (market.get("authority_sources") or [])
        if entry.get("domain")
    }


def overlay_domains(plugin, overlay_market):
    """Domains one overlay market entry claims, with the field that carried each.

    Returns a list of (domain, field) pairs rather than a set, so a domain
    claimed through two different fields is reported once per carrier and the
    finding names where to go and fix it.
    """
    claims = []
    if not isinstance(overlay_market, dict):
        return claims

    if plugin == "research":
        metadata = overlay_market.get("authority_metadata")
        if isinstance(metadata, dict):
            for domain in metadata:
                claims.append((domain, "authority_metadata"))

    if plugin == "trends":
        for search in overlay_market.get("site_searches") or []:
            query = (search or {}).get("query") if isinstance(search, dict) else None
            if not isinstance(query, str):
                continue
            for domain in _SITE_TOKEN.findall(query):
                claims.append((domain, "site_searches"))

    # De-duplicate while preserving first-seen order: one overlay commonly
    # queries the same domain across several dimensions, and reporting that
    # domain N times would inflate the orphan count without adding a finding.
    seen = set()
    unique = []
    for domain, field in claims:
        key = (domain, field)
        if key in seen:
            continue
        seen.add(key)
        unique.append((domain, field))
    return unique


def find_orphans(registry, plugin, overlay):
    """Orphan findings for one plugin overlay, sorted for stable output."""
    if not overlay:
        return []

    found = []
    for code in sorted(k for k in overlay.keys() if not _is_meta_key(k)):
        canonical = registry_domains(registry, code)
        in_registry = code in (registry.get("markets") or {})
        for domain, field in overlay_domains(plugin, overlay[code]):
            if domain in canonical:
                continue
            found.append({
                "plugin": plugin,
                "market": code,
                "domain": domain,
                "field": field,
                "market_in_registry": in_registry,
            })
    found.sort(key=lambda f: (f["market"], f["domain"], f["field"]))
    return found


def curated_count(plugin, overlay_market):
    """How many entries this plugin curates for one market — the matrix cell."""
    if not isinstance(overlay_market, dict):
        return None
    if plugin == "research":
        metadata = overlay_market.get("authority_metadata")
        return len(metadata) if isinstance(metadata, dict) else None
    if plugin == "trends":
        searches = overlay_market.get("site_searches")
        return len(searches) if isinstance(searches, list) else None
    return None


# Matrix cell for a plugin this run never scanned (`--plugin` narrowed it out).
# Distinct from null on purpose: null means "scanned, curates nothing here",
# and rendering an unscanned plugin the same way would state a fact about a
# file that was never opened.
NOT_SCANNED = "not-scanned"


def build_matrix(registry, overlays, scanned):
    """One row per registry market, with a cell for each of the three plugins.

    cogni-portfolio has no overlay — it reads the registry directly — so its
    cell is the canonical domain count rather than a curated count. It is a
    column all the same: dropping it would misreport a plugin that consumes the
    registry as one that does not consume markets at all. Portfolio needs no
    scan to be reported, so it is never NOT_SCANNED.
    """
    rows = []
    for code in sorted((registry.get("markets") or {}).keys()):
        market = registry["markets"][code]
        canonical = len(registry_domains(registry, code))
        row = {
            "market": code,
            "name": market.get("name"),
            "tier": market.get("tier"),
            "registry_domains": canonical,
            "portfolio": canonical,
            "output_language": market.get("default_output_language"),
        }
        for plugin in OVERLAY_READERS:
            if plugin not in scanned:
                row[plugin] = NOT_SCANNED
                continue
            overlay = overlays.get(plugin)
            entry = (overlay or {}).get(code)
            row[plugin] = curated_count(plugin, entry)
        rows.append(row)
    return rows


def resolve_overlay_paths(plugins, explicit):
    """Explicit --overlay wins; otherwise defer to the merge utility's cascade.

    Returns `(paths, import_error)`. `import_error` is non-None only when the
    cascade was actually NEEDED — at least one scanned plugin supplied no
    explicit overlay — and the merge utility could not be loaded. A run that
    names every overlay explicitly never imports it, so a broken merge utility
    cannot fail the fixture path, and the import stays lazy for that reason.
    """
    paths = {}
    merge_utility = None
    import_error = None
    cascade_needed = False

    for plugin in plugins:
        if plugin in explicit:
            paths[plugin] = Path(explicit[plugin])
            continue
        cascade_needed = True
        if merge_utility is None and import_error is None:
            merge_utility, import_error = _load_merge_utility()
        if merge_utility is None:
            paths[plugin] = None
            continue
        paths[plugin] = merge_utility._overlay_path(plugin)

    return paths, (import_error if cascade_needed else None)


def parse_overlay_arg(value):
    if "=" not in value:
        raise argparse.ArgumentTypeError(
            f"--overlay expects <plugin>=<path>, got {value!r}")
    plugin, path = value.split("=", 1)
    plugin = plugin.strip()
    if plugin not in OVERLAY_READERS:
        raise argparse.ArgumentTypeError(
            f"unknown overlay plugin {plugin!r}; expected one of {', '.join(OVERLAY_READERS)}")
    return plugin, path


def main():
    parser = argparse.ArgumentParser(
        description="Report overlay domains the canonical market registry does not carry.")
    parser.add_argument("--plugin", choices=list(OVERLAY_READERS),
                        help="Limit the orphan scan to one plugin overlay (default: all).")
    parser.add_argument("--registry", help="Registry path (default: the plugin's own).")
    parser.add_argument("--overlay", action="append", default=[], type=parse_overlay_arg,
                        metavar="PLUGIN=PATH",
                        help="Explicit overlay path, bypassing sibling resolution. Repeatable.")
    args = parser.parse_args()

    registry_path = Path(args.registry) if args.registry else REGISTRY_PATH
    try:
        registry = _load(registry_path)
    except Exception as exc:
        print(json.dumps(_envelope(False, None, f"failed to load registry: {exc}"),
                         ensure_ascii=False))
        sys.exit(1)

    plugins = [args.plugin] if args.plugin else list(OVERLAY_READERS)
    explicit = dict(args.overlay)
    overlay_paths, import_error = resolve_overlay_paths(plugins, explicit)
    if import_error is not None:
        # Not degradation — the overlay cascade this script defers to could not
        # be loaded, so no overlay was read and "0 orphans" would be a clean
        # audit over nothing. Fail loudly instead.
        print(json.dumps(_envelope(
            False, None,
            f"failed to load {MERGE_UTILITY.name}: {import_error}"), ensure_ascii=False))
        sys.exit(1)

    overlays = {}
    per_plugin = {}
    orphans = []
    for plugin in plugins:
        path = overlay_paths.get(plugin)
        overlay = None
        error = None
        if path is None:
            error = "overlay not resolvable"
        else:
            try:
                overlay = _load(path)
            except FileNotFoundError:
                error = "overlay not found"
            except Exception as exc:
                print(json.dumps(_envelope(False, None,
                                           f"failed to load {plugin} overlay: {exc}"),
                                 ensure_ascii=False))
                sys.exit(1)
        overlays[plugin] = overlay
        plugin_orphans = find_orphans(registry, plugin, overlay)
        orphans.extend(plugin_orphans)
        per_plugin[plugin] = {
            "overlay_path": str(path) if path else None,
            "curated": overlay is not None,
            "curated_markets": sorted(
                k for k in (overlay or {}).keys() if not _is_meta_key(k)),
            "orphans": plugin_orphans,
            "orphan_count": len(plugin_orphans),
            "note": error,
        }

    orphans.sort(key=lambda f: (f["plugin"], f["market"], f["domain"], f["field"]))
    data = {
        "registry_path": str(registry_path),
        "markets_canonical": len((registry.get("markets") or {}).keys()),
        "plugins": per_plugin,
        "orphans": orphans,
        "orphan_count": len(orphans),
        "scanned_plugins": list(plugins),
        "matrix": build_matrix(registry, overlays, set(plugins)),
    }
    print(json.dumps(_envelope(True, data, None), ensure_ascii=False))


if __name__ == "__main__":
    main()
