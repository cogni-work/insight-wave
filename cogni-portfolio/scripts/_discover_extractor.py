"""Per-project field extractor for cogni-portfolio discover-projects.sh.

Loaded by cogni-workspace/scripts/discover-plugin-projects.sh. Must define
``extract(project_dir: str) -> dict`` returning the per-project JSON envelope.
"""

import json
import os


def extract(d: str) -> dict:
    project = {"path": d, "slug": os.path.basename(d)}

    pf = os.path.join(d, "portfolio.json")
    if os.path.exists(pf):
        try:
            data = json.load(open(pf))
            project["slug"] = data.get("slug", project["slug"])
            project["language"] = data.get("language", "en")
            company = data.get("company", {}) or {}
            project["company_name"] = company.get("name", "")
            project["company_industry"] = company.get("industry", "")
            project["updated"] = data.get("updated", data.get("created", ""))
        except Exception:
            pass

    project["has_products"] = os.path.isdir(os.path.join(d, "products"))
    project["has_features"] = os.path.isdir(os.path.join(d, "features"))
    project["has_markets"] = os.path.isdir(os.path.join(d, "markets"))
    project["has_propositions"] = os.path.isdir(os.path.join(d, "propositions"))
    project["has_solutions"] = os.path.isdir(os.path.join(d, "solutions"))
    project["has_dashboard"] = os.path.exists(os.path.join(d, "output", "dashboard.html"))

    return project
