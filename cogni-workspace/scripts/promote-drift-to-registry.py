#!/usr/bin/env python3
"""promote-drift-to-registry.py — apply registry_additions[] from a drift audit envelope.

Consumes a `check-region-catalogs.sh --fix-suggestions` envelope and applies
ONLY the `registry_additions[]` block to the canonical
`cogni-workspace/references/supported-markets-registry.json`. The two other
blocks the audit emits (`research_additions`, `trends_additions`) are
deliberately ignored — they would inject orchestration metadata
(`category="unknown"`, `authority=3`, `dimension="digitales-fundament"`) into
plugin files where a maintainer must place real values.

Bucket A `domain_in_research_and_trends_but_not_upstream` and Bucket B
`r∩t` agreement are the only safe automatic promotions: a domain that
both per-plugin files reference is by definition agreed-intentional, and
adding it to the canonical registry shrinks the agreed-drift baseline by
exactly that one domain.

Modes:
  default            — print unified diff; never writes.
  --write            — apply changes to the registry.

Inputs:
  --envelope <path>  — path to the JSON envelope from
                       `check-region-catalogs.sh --fix-suggestions`. Required.

Output: single-line JSON envelope `{success, data, error}` on the final line.

This script is git/gh-agnostic. The skill (or the scheduled agent) drives
branching and PR creation around it.
"""
import argparse
import difflib
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
REGISTRY = REPO_ROOT / "cogni-workspace/references/supported-markets-registry.json"


def load_json(path):
    with open(path) as f:
        return json.load(f)


def dump_json(obj, path):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2, ensure_ascii=False)
        f.write("\n")


def derive_name(domain):
    return domain.split(".")[0].upper()


def render_diff(old_text, new_text, path):
    return "\n".join(difflib.unified_diff(
        old_text.splitlines(),
        new_text.splitlines(),
        fromfile=str(path),
        tofile=str(path),
        lineterm="",
    ))


def collect_promotions(fix_suggestions):
    """Walk fix_suggestions[<market>] entries and pull only registry_additions[].

    Returns {market_code: [{"domain": str, "name": str}, ...]}.
    Bucket A and Bucket B both emit `registry_additions[]` so a single pass
    handles both.
    """
    out = {}
    for market_code, addition_blocks in (fix_suggestions or {}).items():
        domains = []
        for block in addition_blocks:
            for entry in block.get("registry_additions") or []:
                if entry.get("domain"):
                    domains.append({
                        "domain": entry["domain"],
                        "name": entry.get("name") or derive_name(entry["domain"]),
                    })
        if domains:
            out[market_code] = domains
    return out


def apply_promotions(registry_doc, promotions):
    """Add domains to each market's authority_sources[]; never duplicate.

    Returns (new_doc, applied_per_market) — applied counts the actually-added
    domains (excludes ones already present in registry).
    """
    applied = {}
    markets = registry_doc.get("markets") or {}
    for code, domains in sorted(promotions.items()):
        if code not in markets:
            # Don't auto-create market entries — a missing market means the
            # registry maintainer hasn't decided whether to support it yet.
            applied[code] = {"skipped_reason": "market not in registry", "domains": []}
            continue
        existing = {a.get("domain") for a in (markets[code].get("authority_sources") or [])}
        added = []
        for entry in domains:
            if entry["domain"] in existing:
                continue
            markets[code].setdefault("authority_sources", []).append({
                "name": entry["name"],
                "domain": entry["domain"],
            })
            added.append(entry["domain"])
            existing.add(entry["domain"])
        # Sort authority_sources alphabetically by domain for stable diffs.
        markets[code]["authority_sources"] = sorted(
            markets[code]["authority_sources"], key=lambda a: a.get("domain", ""))
        applied[code] = {"domains": added}
    return registry_doc, applied


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument("--envelope", required=True,
                        help="path to check-region-catalogs.sh --fix-suggestions envelope")
    parser.add_argument("--write", action="store_true",
                        help="apply changes (default: preview)")
    parser.add_argument("--quiet", action="store_true",
                        help="suppress diff body (JSON envelope still emitted)")
    args = parser.parse_args()

    try:
        with open(args.envelope) as f:
            audit_env = json.load(f)
    except Exception as e:
        print(json.dumps({"success": False, "data": {},
                          "error": f"could not load envelope: {e}"}))
        return 2

    fix_suggestions = (audit_env.get("data") or {}).get("info_findings", {}).get("fix_suggestions") or {}
    promotions = collect_promotions(fix_suggestions)

    if not promotions:
        envelope = {
            "success": True,
            "data": {"applied": {}, "summary": "no registry_additions in envelope — nothing to promote"},
            "error": "",
        }
        print(envelope["data"]["summary"])
        print(json.dumps(envelope))
        return 0

    try:
        registry_doc = load_json(REGISTRY)
    except Exception as e:
        print(json.dumps({"success": False, "data": {}, "error": f"load registry failed: {e}"}))
        return 2

    old_text = json.dumps(registry_doc, indent=2, ensure_ascii=False) + "\n"
    new_doc, applied = apply_promotions(registry_doc, promotions)
    new_text = json.dumps(new_doc, indent=2, ensure_ascii=False) + "\n"

    if not args.quiet:
        print(render_diff(old_text, new_text, REGISTRY.relative_to(REPO_ROOT)))
        print()

    total_applied = sum(len(v.get("domains", [])) for v in applied.values())
    skipped = {k: v for k, v in applied.items() if v.get("skipped_reason")}

    if args.write and total_applied:
        # Bump last_updated if present.
        if "last_updated" in new_doc:
            from datetime import date
            new_doc["last_updated"] = date.today().isoformat()
        dump_json(new_doc, REGISTRY)
        action = f"applied: {total_applied} domain(s) across {len([a for a in applied.values() if a.get('domains')])} market(s)"
    elif args.write and not total_applied:
        action = "no changes to write (all promotions were already present or skipped)"
    else:
        action = f"preview only — use --write to apply ({total_applied} domain(s) pending)"

    envelope = {
        "success": True,
        "data": {
            "applied": applied,
            "skipped": skipped,
            "total_domains_promoted": total_applied,
            "markets_touched": [k for k, v in applied.items() if v.get("domains")],
            "summary": action,
        },
        "error": "",
    }
    print(action)
    print(json.dumps(envelope))
    return 0


if __name__ == "__main__":
    sys.exit(main())
