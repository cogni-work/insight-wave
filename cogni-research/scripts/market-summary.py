#!/usr/bin/env python3
"""market-summary.py — compact per-market display for cogni-research surfaces.

Reads references/market-sources.json and emits compact summaries in JSON or
plain text. Single source of truth for what the user sees about market curation
in the setup menu, the execution plan, the final report footer, and the resume
dashboard. If the JSON changes, every surface changes with it — no drift.

Formats:
  json      — structured record for programmatic callers
  headline  — one-line summary for the setup table and resume dashboard
  block     — multi-line block for the execution plan and report footer
  table     — headlines for every canonical user-selectable market (--all)

Stdlib only (python3).
"""

import argparse
import json
import sys
from pathlib import Path


# Display names per market code. The JSON has no display-name field today,
# so these live here. Keeps the JSON schema unchanged for this UX pass.
DISPLAY_NAMES = {
    "dach": "DACH (DE/AT/CH)",
    "de": "Germany",
    "fr": "France",
    "it": "Italy",
    "pl": "Poland",
    "nl": "Netherlands",
    "es": "Spain",
    "us": "United States",
    "uk": "United Kingdom",
    "eu": "EU composite",
    "at": "Austria",
    "cz": "Czechia",
    "sk": "Slovakia",
    "hu": "Hungary",
    "ro": "Romania",
    "hr": "Croatia",
    "gr": "Greece",
    "mk": "North Macedonia",
    "mx": "Mexico",
    "br": "Brazil",
}

# Canonical user-selectable markets — mirror of the research-setup Step 2 list.
CANONICAL = ["dach", "de", "fr", "it", "pl", "nl", "es", "cz", "sk", "hu", "hr", "gr", "mx", "br", "us", "uk", "eu"]

# ISO code → short label used in the bilingual query echo.
LANG_LABEL = {
    "de": "DE", "fr": "FR", "it": "IT", "pl": "PL",
    "nl": "NL", "es": "ES", "en": "EN", "cs": "CS",
    "sk": "SK", "hu": "HU", "ro": "RO", "hr": "HR",
    "el": "EL", "mk": "MK", "pt": "PT",
}

CATEGORY_LABEL = {
    "research": "research",
    "association": "associations",
    "consulting": "consulting",
    "media": "media",
    "government": "government",
    "statistics": "statistics",
}


def load_market_sources():
    script_dir = Path(__file__).resolve().parent
    data_path = script_dir.parent / "references" / "market-sources.json"
    with data_path.open(encoding="utf-8") as f:
        return json.load(f)


def summarize(code, data):
    entry = data.get(code) or data.get("_default", {})
    sources = entry.get("authority_sources", []) or []

    categories = {}
    for src in sources:
        cat = src.get("category", "other")
        categories[cat] = categories.get(cat, 0) + 1

    local_lang = entry.get("local_language", "en")
    bilingual = local_lang != "en"
    local_short = LANG_LABEL.get(local_lang, local_lang.upper())
    if bilingual:
        query_langs_short = f"{local_short}/EN"
        query_langs_phrase = f"bilingual {query_langs_short} search"
    else:
        query_langs_short = "EN"
        query_langs_phrase = "English-only search"

    return {
        "code": code,
        "name": DISPLAY_NAMES.get(code, code.upper()),
        "local_language": local_lang,
        "authority_count": len(sources),
        "top_domains": [s.get("domain", "") for s in sources[:4]],
        "categories": categories,
        "query_languages_short": query_langs_short,
        "query_languages_phrase": query_langs_phrase,
        "regulatory_bodies": entry.get("regulatory_bodies", []) or [],
        "currency": entry.get("currency", ""),
        "composite_markets": entry.get("composite_markets", []) or [],
    }


def render_headline(s):
    name = s["name"]
    count = s["authority_count"]
    composite_tail = (
        f"; fans out per-country ({', '.join(s['composite_markets'])})"
        if s["composite_markets"] else ""
    )
    if count == 0:
        return f"{name} — {s['query_languages_phrase']}{composite_tail}"
    top = s["top_domains"][:3]
    extras = count - len(top)
    extras_tail = f" +{extras} more" if extras > 0 else ""
    return (
        f"{name} — {count} authority domains "
        f"({', '.join(top)}{extras_tail}); {s['query_languages_phrase']}"
        f"{composite_tail}"
    )


def render_block(s):
    lines = []
    if s["authority_count"] > 0:
        cats_sorted = sorted(s["categories"].items(), key=lambda kv: (-kv[1], kv[0]))
        cats_str = ", ".join(
            f"{CATEGORY_LABEL.get(k, k)}: {v}" for k, v in cats_sorted
        )
        lines.append(
            f"Market: {s['name']} — {s['authority_count']} authority domains "
            f"boosted ({cats_str})"
        )
        top = s["top_domains"][:4]
        extras = s["authority_count"] - len(top)
        extras_tail = f" (+{extras} more)" if extras > 0 else ""
        lines.append(f"Top domains: {', '.join(top)}{extras_tail}")
    else:
        lines.append(f"Market: {s['name']} — no curated authority sources (fallback)")

    lines.append(f"Query languages: {s['query_languages_phrase']}")

    regs = s["regulatory_bodies"]
    if regs:
        shown = regs[:4]
        reg_tail = f" (+{len(regs) - len(shown)} more)" if len(regs) > len(shown) else ""
        lines.append(f"Regulatory bodies tracked: {', '.join(shown)}{reg_tail}")

    if s["composite_markets"]:
        lines.append(
            "Composite — fans out per-country researchers for: "
            + ", ".join(s["composite_markets"])
        )
    return "\n".join(lines)


def render_table(data):
    lines = []
    for code in CANONICAL:
        s = summarize(code, data)
        lines.append(f"  {code:<5} {render_headline(s)}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Compact market summary for cogni-research surfaces."
    )
    parser.add_argument(
        "market", nargs="?",
        help="Market code (dach, de, fr, ...). Required unless --format table --all.",
    )
    parser.add_argument(
        "--format", choices=["json", "headline", "block", "table"],
        default="headline",
    )
    parser.add_argument("--all", action="store_true",
                        help="Table mode: render all canonical markets.")
    args = parser.parse_args()

    try:
        data = load_market_sources()
    except Exception as e:
        print(json.dumps({
            "success": False,
            "data": None,
            "error": f"failed to load market-sources.json: {e}",
        }))
        sys.exit(1)

    if args.format == "table":
        if not args.all:
            print("--format table requires --all", file=sys.stderr)
            sys.exit(2)
        print(render_table(data))
        return

    if not args.market:
        print("market code required (or use --format table --all)", file=sys.stderr)
        sys.exit(2)

    summary = summarize(args.market.lower(), data)

    if args.format == "json":
        print(json.dumps(
            {"success": True, "data": summary, "error": None},
            ensure_ascii=False,
        ))
    elif args.format == "headline":
        print(render_headline(summary))
    elif args.format == "block":
        print(render_block(summary))


if __name__ == "__main__":
    main()
