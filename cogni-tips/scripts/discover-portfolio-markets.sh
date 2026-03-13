#!/usr/bin/env bash
set -euo pipefail
# discover-portfolio-markets.sh
# Version: 1.0.0
# Purpose: Scan workspace for cogni-portfolio projects and extract markets
#          with vertical codes mapped to the TIPS industry taxonomy.
#          Used by trend-scout Phase 0 to offer portfolio-aware initialization.
# Category: utilities
#
# Usage:
#   discover-portfolio-markets.sh --workspace <dir> [--json]
#
# Arguments:
#   --workspace <dir>    Workspace root to scan (default: current directory)
#   --json               Output results in JSON format (default)
#
# Output (JSON):
#   {
#     "found": true|false,
#     "projects": [
#       {
#         "slug": "acme-corp",
#         "path": "/abs/path/cogni-portfolio/acme-corp",
#         "company_name": "ACME Corp",
#         "company_industry": "IT Services",
#         "markets": [
#           {
#             "slug": "mid-market-saas-dach",
#             "name": "Mid-Market SaaS (DACH)",
#             "region": "dach",
#             "priority": "beachhead",
#             "vertical_codes": ["saas"],
#             "tips_alignment": {
#               "level": "vertical",
#               "matched_industry": "technology",
#               "matched_subsector": "software",
#               "matched_industry_en": "Technology",
#               "matched_industry_de": "Technologie",
#               "matched_subsector_en": "Software",
#               "matched_subsector_de": "Software"
#             }
#           }
#         ]
#       }
#     ]
#   }
#
# Exit codes:
#   0 - Success (even if 0 projects found)
#   1 - Invalid arguments
#   2 - Missing dependencies

# Dependency checks
if ! command -v python3 &>/dev/null; then
    echo '{"found": false, "error": "python3 is required but not installed"}' >&2
    exit 2
fi

# Parse arguments
WORKSPACE="$(pwd)"
JSON_OUTPUT=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace)
            WORKSPACE="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 1
            ;;
    esac
done

# Resolve to absolute path
WORKSPACE="$(cd "$WORKSPACE" 2>/dev/null && pwd || echo "$WORKSPACE")"

# Find all portfolio.json files
PORTFOLIO_FILES=()
while IFS= read -r f; do
    PORTFOLIO_FILES+=("$f")
done < <(find "$WORKSPACE" -maxdepth 3 -name "portfolio.json" -path "*/cogni-portfolio/*" -type f 2>/dev/null || true)

if [[ ${#PORTFOLIO_FILES[@]} -eq 0 ]]; then
    echo '{"found": false, "projects": []}'
    exit 0
fi

# Use Python for JSON processing and taxonomy alignment
python3 - "${PORTFOLIO_FILES[@]}" << 'PYEOF'
import json
import os
import sys
import glob

# TIPS Industry Taxonomy — mirrors industry-taxonomy.md
# Maps industry_slug -> { "en": name_en, "de": name_de, "subsectors": { slug: { "en", "de" } } }
TAXONOMY = {
    "manufacturing": {
        "en": "Manufacturing", "de": "Fertigung",
        "subsectors": {
            "automotive": {"en": "Automotive", "de": "Automobil"},
            "machinery": {"en": "Machinery", "de": "Maschinenbau"},
            "electronics": {"en": "Electronics", "de": "Elektronik"},
            "chemicals": {"en": "Chemicals", "de": "Chemie"},
            "aerospace": {"en": "Aerospace", "de": "Luft- und Raumfahrt"},
            "industrial-equipment": {"en": "Industrial Equipment", "de": "Industrieausruestung"},
        }
    },
    "healthcare": {
        "en": "Healthcare", "de": "Gesundheitswesen",
        "subsectors": {
            "pharmaceuticals": {"en": "Pharmaceuticals", "de": "Pharma"},
            "medical-devices": {"en": "Medical Devices", "de": "Medizintechnik"},
            "hospital-services": {"en": "Hospital Services", "de": "Krankenhausdienste"},
            "diagnostics": {"en": "Diagnostics", "de": "Diagnostik"},
            "digital-health": {"en": "Digital Health", "de": "Digitale Gesundheit"},
        }
    },
    "financial-services": {
        "en": "Financial Services", "de": "Finanzdienstleistungen",
        "subsectors": {
            "banking": {"en": "Banking", "de": "Bankwesen"},
            "insurance": {"en": "Insurance", "de": "Versicherung"},
            "asset-management": {"en": "Asset Management", "de": "Vermoegensverwaltung"},
            "fintech": {"en": "FinTech", "de": "FinTech"},
            "payments": {"en": "Payments", "de": "Zahlungsverkehr"},
        }
    },
    "retail-consumer": {
        "en": "Retail & Consumer", "de": "Einzelhandel & Konsumgueter",
        "subsectors": {
            "ecommerce": {"en": "E-Commerce", "de": "E-Commerce"},
            "food-beverage": {"en": "Food & Beverage", "de": "Lebensmittel & Getraenke"},
            "fashion-apparel": {"en": "Fashion & Apparel", "de": "Mode & Bekleidung"},
            "consumer-electronics": {"en": "Consumer Electronics", "de": "Unterhaltungselektronik"},
            "home-garden": {"en": "Home & Garden", "de": "Haus & Garten"},
        }
    },
    "energy-utilities": {
        "en": "Energy & Utilities", "de": "Energie & Versorgung",
        "subsectors": {
            "renewable-energy": {"en": "Renewable Energy", "de": "Erneuerbare Energien"},
            "oil-gas": {"en": "Oil & Gas", "de": "Oel & Gas"},
            "utilities": {"en": "Utilities", "de": "Versorgungsunternehmen"},
            "energy-storage": {"en": "Energy Storage", "de": "Energiespeicherung"},
            "grid-infrastructure": {"en": "Grid Infrastructure", "de": "Netzinfrastruktur"},
        }
    },
    "technology": {
        "en": "Technology", "de": "Technologie",
        "subsectors": {
            "software": {"en": "Software", "de": "Software"},
            "cloud-services": {"en": "Cloud Services", "de": "Cloud-Dienste"},
            "semiconductors": {"en": "Semiconductors", "de": "Halbleiter"},
            "it-services": {"en": "IT Services", "de": "IT-Dienstleistungen"},
            "cybersecurity": {"en": "Cybersecurity", "de": "Cybersicherheit"},
            "ai-data": {"en": "AI & Data", "de": "KI & Daten"},
        }
    },
    "logistics-transport": {
        "en": "Logistics & Transportation", "de": "Logistik & Transport",
        "subsectors": {
            "freight-shipping": {"en": "Freight & Shipping", "de": "Fracht & Versand"},
            "warehousing": {"en": "Warehousing", "de": "Lagerhaltung"},
            "last-mile": {"en": "Last Mile Delivery", "de": "Letzte-Meile-Zustellung"},
            "public-transport": {"en": "Public Transport", "de": "Oeffentlicher Verkehr"},
            "aviation": {"en": "Aviation", "de": "Luftfahrt"},
        }
    },
    "professional-services": {
        "en": "Professional Services", "de": "Professionelle Dienstleistungen",
        "subsectors": {
            "consulting": {"en": "Consulting", "de": "Beratung"},
            "legal": {"en": "Legal", "de": "Recht"},
            "accounting": {"en": "Accounting", "de": "Buchhaltung"},
            "engineering": {"en": "Engineering", "de": "Ingenieurwesen"},
            "marketing-media": {"en": "Marketing & Media", "de": "Marketing & Medien"},
        }
    },
    "telecommunications": {
        "en": "Telecommunications", "de": "Telekommunikation",
        "subsectors": {
            "mobile-operators": {"en": "Mobile Operators", "de": "Mobilfunkanbieter"},
            "fixed-line": {"en": "Fixed-Line", "de": "Festnetz"},
            "network-infrastructure": {"en": "Network Infrastructure", "de": "Netzinfrastruktur"},
            "satellite-space": {"en": "Satellite & Space", "de": "Satellit & Raumfahrt"},
        }
    },
    "public-sector": {
        "en": "Public Sector", "de": "Oeffentlicher Sektor",
        "subsectors": {
            "government": {"en": "Government", "de": "Regierung"},
            "education": {"en": "Education", "de": "Bildung"},
            "defense": {"en": "Defense", "de": "Verteidigung"},
            "municipal-services": {"en": "Municipal Services", "de": "Kommunale Dienste"},
            "healthcare-public": {"en": "Healthcare (Public)", "de": "Gesundheitswesen (Oeffentlich)"},
        }
    },
}

# Build reverse lookup: subsector_slug -> (industry_slug, subsector_info)
SUBSECTOR_LOOKUP = {}
for ind_slug, ind_data in TAXONOMY.items():
    for sub_slug, sub_data in ind_data["subsectors"].items():
        SUBSECTOR_LOOKUP[sub_slug] = (ind_slug, sub_data)

# Build flat list of all slugs (industries + subsectors) for fuzzy matching
ALL_SLUGS = set(TAXONOMY.keys())
for ind_data in TAXONOMY.values():
    ALL_SLUGS.update(ind_data["subsectors"].keys())


def slugify(text):
    """Convert text to slug for matching."""
    import re
    text = text.lower().strip()
    text = re.sub(r'[^a-z0-9]+', '-', text)
    text = text.strip('-')
    return text


def align_vertical(vertical_code):
    """
    Map a portfolio vertical_code to TIPS taxonomy using 4-tier alignment.
    Returns: { level, matched_industry, matched_subsector, ..._en, ..._de }
    """
    vc = slugify(vertical_code)

    # Tier 1: Exact match on subsector slug
    if vc in SUBSECTOR_LOOKUP:
        ind_slug, sub_data = SUBSECTOR_LOOKUP[vc]
        ind_data = TAXONOMY[ind_slug]
        return {
            "level": "exact",
            "matched_industry": ind_slug,
            "matched_subsector": vc,
            "matched_industry_en": ind_data["en"],
            "matched_industry_de": ind_data["de"],
            "matched_subsector_en": sub_data["en"],
            "matched_subsector_de": sub_data["de"],
        }

    # Tier 2: Exact match on industry slug
    if vc in TAXONOMY:
        ind_data = TAXONOMY[vc]
        # Pick first subsector as default
        first_sub_slug = next(iter(ind_data["subsectors"]))
        first_sub = ind_data["subsectors"][first_sub_slug]
        return {
            "level": "exact",
            "matched_industry": vc,
            "matched_subsector": first_sub_slug,
            "matched_industry_en": ind_data["en"],
            "matched_industry_de": ind_data["de"],
            "matched_subsector_en": first_sub["en"],
            "matched_subsector_de": first_sub["de"],
        }

    # Tier 3: Substring/containment match (vertical)
    for sub_slug, (ind_slug, sub_data) in SUBSECTOR_LOOKUP.items():
        if vc in sub_slug or sub_slug in vc:
            ind_data = TAXONOMY[ind_slug]
            return {
                "level": "vertical",
                "matched_industry": ind_slug,
                "matched_subsector": sub_slug,
                "matched_industry_en": ind_data["en"],
                "matched_industry_de": ind_data["de"],
                "matched_subsector_en": sub_data["en"],
                "matched_subsector_de": sub_data["de"],
            }

    # Tier 3b: Substring match on industry
    for ind_slug, ind_data in TAXONOMY.items():
        if vc in ind_slug or ind_slug in vc:
            first_sub_slug = next(iter(ind_data["subsectors"]))
            first_sub = ind_data["subsectors"][first_sub_slug]
            return {
                "level": "broad",
                "matched_industry": ind_slug,
                "matched_subsector": first_sub_slug,
                "matched_industry_en": ind_data["en"],
                "matched_industry_de": ind_data["de"],
                "matched_subsector_en": first_sub["en"],
                "matched_subsector_de": first_sub["de"],
            }

    # Tier 4: No match
    return {"level": "none"}


def best_alignment(vertical_codes):
    """Find the best alignment across all vertical codes for a market."""
    tier_order = {"exact": 0, "vertical": 1, "broad": 2, "none": 3}
    best = {"level": "none"}
    for vc in vertical_codes:
        alignment = align_vertical(vc)
        if tier_order.get(alignment["level"], 3) < tier_order.get(best["level"], 3):
            best = alignment
    return best


# Process portfolio files
portfolio_files = sys.argv[1:]
projects = []

for pf in portfolio_files:
    try:
        with open(pf) as f:
            portfolio = json.load(f)
    except (json.JSONDecodeError, IOError):
        continue

    project_dir = os.path.dirname(pf)
    project_slug = os.path.basename(project_dir)
    company = portfolio.get("company", {})

    project_entry = {
        "slug": portfolio.get("slug", project_slug),
        "path": project_dir,
        "company_name": company.get("name", project_slug),
        "company_industry": company.get("industry", ""),
        "markets": [],
    }

    # Read market files
    markets_dir = os.path.join(project_dir, "markets")
    if os.path.isdir(markets_dir):
        for mf in sorted(glob.glob(os.path.join(markets_dir, "*.json"))):
            try:
                with open(mf) as f:
                    market = json.load(f)
            except (json.JSONDecodeError, IOError):
                continue

            vertical_codes = market.get("segmentation", {}).get("vertical_codes", [])
            if not vertical_codes:
                # Try to derive from company industry as fallback
                ci = company.get("industry", "")
                if ci:
                    vertical_codes = [slugify(ci)]

            alignment = best_alignment(vertical_codes) if vertical_codes else {"level": "none"}

            market_entry = {
                "slug": market.get("slug", os.path.splitext(os.path.basename(mf))[0]),
                "name": market.get("name", ""),
                "region": market.get("region", ""),
                "priority": market.get("priority", ""),
                "vertical_codes": vertical_codes,
                "description": market.get("description", ""),
                "tips_alignment": alignment,
            }
            project_entry["markets"].append(market_entry)

    # Only include projects that have at least one market
    if project_entry["markets"]:
        projects.append(project_entry)

result = {
    "found": len(projects) > 0,
    "projects": projects,
}

print(json.dumps(result, indent=2, ensure_ascii=False))
PYEOF

exit 0
